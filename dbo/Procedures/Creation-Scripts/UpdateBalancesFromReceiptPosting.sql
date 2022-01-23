SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateBalancesFromReceiptPosting]
(
@ReceiptApplicationInfo [ReceiptApplicationInfo] READONLY,
@CurrentUserId BIGINT,
@CurrentTime DATETIMEOFFSET,
@JobStepInstanceId BIGINT
)
AS
BEGIN
SET NOCOUNT ON;

	CREATE TABLE #ReceiptApplicationInfo
	(
		ReceiptId BIGINT,
		ApplicationId BIGINT,
		ReceivedDate DATE
	);

	CREATE TABLE #AppliedReceivableDetailInfo
	(
		ReceivableId BIGINT,
		ReceivableDetailId BIGINT PRIMARY KEY CLUSTERED,
		AmountApplied DECIMAL(16,2) NOT NULL,
		TaxApplied DECIMAL(16,2) NOT NULL,
		BookAmountApplied DECIMAL(16,2) NOT NULL,
		AdjustedWithHoldingTax DECIMAL(16,2) NOT NULL,
		ReceivableInvoiceId BIGINT NULL,
		LeaseComponentAmountApplied DECIMAL(16,2) NULL,
		NonLeaseComponentAmountApplied DECIMAL(16,2) NULL,
	);

	CREATE TABLE #TaxImpositions
	(
		ReceivableTaxImpositionId BIGINT PRIMARY KEY CLUSTERED,
		ReceivableTaxDetailId BIGINT,
		ReceivableTaxId BIGINT,
		TaxApplied DECIMAL(16,2)
	);	

	INSERT INTO #ReceiptApplicationInfo(ReceiptId,ApplicationId,ReceivedDate)
	SELECT ReceiptId,ApplicationId,ReceivedDate from @ReceiptApplicationInfo;

	--980 ms
	INSERT INTO #AppliedReceivableDetailInfo(ReceivableId,ReceivableDetailId,AmountApplied,TaxApplied,BookAmountApplied,AdjustedWithHoldingTax,
	LeaseComponentAmountApplied,NonLeaseComponentAmountApplied,ReceivableInvoiceId)
	SELECT 
		ReceivableId,
		ReceivableDetailId,
		SUM(AmountApplied - PrevAmountAppliedForReApplication) AmountApplied,
		SUM(TaxApplied - PrevTaxAppliedForReApplication) TaxApplied,
		SUM(BookAmountApplied - PrevBookAmountAppliedForReApplication) BookAmountApplied,
		SUM(AdjustedWithHoldingTax - PrevAdjustedWithHoldingTaxForReApplication) AdjustedWithHoldingTax,
		SUM(LeaseComponentAmountApplied - PrevLeaseComponentAmountAppliedForReApplication) LeaseComponentAmountApplied,
		SUM(NonLeaseComponentAmountApplied - PrevNonLeaseComponentAmountAppliedForReApplication) NonLeaseComponentAmountApplied,
		InvoiceId ReceivableInvoiceId
	FROM #ReceiptApplicationInfo ReceiptApplication
	JOIN ReceiptReceivableDetails_Extract ON ReceiptApplication.ReceiptId = ReceiptReceivableDetails_Extract.ReceiptId 
		AND ReceiptReceivableDetails_Extract.JobStepInstanceId = @JobStepInstanceId 
	GROUP BY ReceivableDetailId,ReceivableId,InvoiceId;

	-- Receivable Details 
	--3578 ms	
	UPDATE ReceivableDetails 
	SET Balance_Amount = Balance_Amount - #AppliedReceivableDetailInfo.AmountApplied,
	    LeaseComponentBalance_Amount = LeaseComponentBalance_Amount - #AppliedReceivableDetailInfo.LeaseComponentAmountApplied,
		NonLeaseComponentBalance_Amount = NonLeaseComponentBalance_Amount - #AppliedReceivableDetailInfo.NonLeaseComponentAmountApplied,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM ReceivableDetails
	JOIN #AppliedReceivableDetailInfo ON ReceivableDetails.Id = #AppliedReceivableDetailInfo.ReceivableDetailId

	UPDATE ReceivableDetailsWithHoldingTaxDetails
	SET Balance_Amount = Balance_Amount - #AppliedReceivableDetailInfo.AdjustedWithHoldingTax,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM ReceivableDetailsWithHoldingTaxDetails
	JOIN #AppliedReceivableDetailInfo ON ReceivableDetailsWithHoldingTaxDetails.ReceivableDetailId = #AppliedReceivableDetailInfo.ReceivableDetailId;

	---- Receivables
	--375 ms

	SELECT 
		ReceivableId,
		SUM(AmountApplied) AmountApplied,
		SUM(BookAmountApplied) BookAmountApplied,
		SUM(AdjustedWithHoldingTax) AdjustedWithHoldingTax
	INTO #TempReceivableInfo
	FROM #AppliedReceivableDetailInfo
	GROUP BY ReceivableId

	UPDATE Receivables
	SET TotalBalance_Amount = TotalBalance_Amount - #TempReceivableInfo.AmountApplied,
		TotalBookBalance_Amount = TotalBookBalance_Amount - #TempReceivableInfo.BookAmountApplied,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM Receivables
	JOIN #TempReceivableInfo ON Receivables.Id = #TempReceivableInfo.ReceivableId;		
	
	UPDATE ReceivableWithholdingTaxDetails
	SET Balance_Amount = Balance_Amount - #TempReceivableInfo.AdjustedWithHoldingTax,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM ReceivableWithholdingTaxDetails
	JOIN #TempReceivableInfo ON ReceivableWithholdingTaxDetails.ReceivableId = #TempReceivableInfo.ReceivableId;	

	--3000ms
	INSERT INTO #TaxImpositions
	SELECT 
		RTI.Id ReceivableTaxImpositionId,
		RTD.Id ReceivableTaxDetailId,
		RTD.ReceivableTaxId,
		SUM(RARTI.AmountPosted_Amount) TaxApplied
	FROM #ReceiptApplicationInfo Receipt
	JOIN ReceiptApplicationReceivableTaxImpositions RARTI ON Receipt.ApplicationId = RARTI.ReceiptApplicationId AND RARTI.IsActive=1
	JOIN ReceivableTaxImpositions RTI ON RARTI.ReceivableTaxImpositionId = RTI.Id AND RTI.IsActive=1
	JOIN ReceivableTaxDetails RTD ON RTI.ReceivableTaxDetailId = RTD.Id AND RTD.IsActive=1
	GROUP BY RTI.Id,RTD.Id,RTD.ReceivableTaxId
	
	----Receipt Application Receivable Tax Impositions - Calculation
	
	--9578 ms
	UPDATE ReceivableTaxImpositions
	SET Balance_Amount = Balance_Amount - TaxApplied,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM ReceivableTaxImpositions
	JOIN #TaxImpositions ON ReceivableTaxImpositions.Id = #TaxImpositions.ReceivableTaxImpositionId

	----Receivable Tax Details

	;WITH CTE_TaxDetails(TaxDetailId, AmountToApply) AS 
	(
		SELECT 
			ReceivableTaxDetailId,
			SUM(TaxApplied) TaxApplied
		FROM #TaxImpositions 
		GROUP BY ReceivableTaxDetailId
	)
	UPDATE ReceivableTaxDetails
	SET Balance_Amount = Balance_Amount - AmountToApply,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM CTE_TaxDetails
	JOIN ReceivableTaxDetails ON ReceivableTaxDetails.Id = CTE_TaxDetails.TaxDetailId

	----Receivable Taxes

	;WITH CTE_TaxDetails(ReceivableTaxId, AmountToApply) AS 
	(
		SELECT 
			ReceivableTaxId,
			SUM(TaxApplied) AmountToApply
		FROM #TaxImpositions 
		GROUP BY ReceivableTaxId
	)
	UPDATE ReceivableTaxes
	SET Balance_Amount = Balance_Amount - AmountToApply,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM CTE_TaxDetails
	JOIN ReceivableTaxes ON ReceivableTaxes.Id = CTE_TaxDetails.ReceivableTaxId;	

	--4000 ms
	--Changes FOR WHT Will not be handled until Invoice Story
	;WITH CTE_InvoiceDetails(Id,AmountApplied,TaxApplied) AS
	(
		SELECT RID.Id,RD.AmountApplied,RD.TaxApplied 
		FROM #AppliedReceivableDetailInfo RD
		JOIN ReceivableInvoiceDetails RID ON RD.ReceivableDetailId = RID.ReceivableDetailId
			AND RD.ReceivableInvoiceId = RID.ReceivableInvoiceId AND RID.IsActive=1
	)
	UPDATE ReceivableInvoiceDetails 
	SET Balance_Amount = Balance_Amount - ID.AmountApplied,
		TaxBalance_Amount = TaxBalance_Amount - ID.TaxApplied,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM CTE_InvoiceDetails ID
	JOIN ReceivableInvoiceDetails  ON ReceivableInvoiceDetails.Id = ID.Id	

	----Receivable Invoices

	;WITH CTE_InvoiceInfo(ReceivableInvoiceId, AmountApplied, TaxApplied, AdjustedWithHoldingTax) AS
	(
		SELECT
			ReceivableInvoiceId,
			SUM(AmountApplied) AmountApplied, 
			SUM(TaxApplied) TaxApplied,
			SUM(AdjustedWithHoldingTax) AdjustedWithHoldingTax
		FROM #AppliedReceivableDetailInfo
		WHERE ReceivableInvoiceId IS NOT NULL
		GROUP BY ReceivableInvoiceId
	)
	UPDATE    
		ReceivableInvoices     
	SET     
		Balance_Amount = Balance_Amount - AmountApplied,    
		TaxBalance_Amount = TaxBalance_Amount - TaxApplied,    
		WithHoldingTaxBalance_Amount = WithHoldingTaxBalance_Amount - AdjustedWithHoldingTax,    
		UpdatedById = @CurrentUserId, 
		UpdatedTime = @CurrentTime     
	FROM     
		ReceivableInvoices    
		JOIN CTE_InvoiceInfo AS InvoiceInfo ON InvoiceInfo.ReceivableInvoiceId = ReceivableInvoices.Id;
	
	----Receivable Invoice Receipt Details	
	-- AmountApplied should reduce effectively for WHT Too
	SELECT Receipts.Id ReceiptId,
		Receipts.ReceivedDate,
		CAST(1 AS BIT) IsActive,
		RARD.InvoiceId ReceivableInvoiceId,
		SUM(RARD.AmountApplied) AmountApplied_Amount,
		Receipts.ReceiptAmount_Currency AmountApplied_Currency,
		SUM(RARD.TaxApplied) TaxApplied_Amount,
		Receipts.ReceiptAmount_Currency TaxApplied_Currency,
		@CurrentUserId CreatedById,
		@CurrentTime CreatedTime,
		CAST(NULL AS BIGINT) RIRDId
	INTO #ReceivableInvoiceReceiptDetails
	FROM #ReceiptApplicationInfo
	JOIN ReceiptReceivableDetails_Extract RARD ON #ReceiptApplicationInfo.ReceiptId = RARD.ReceiptId
		AND RARD.JobStepInstanceId = @JobStepInstanceId
		AND RARD.InvoiceId IS NOT NULL AND (RARD.AmountApplied != 0 OR RARD.TaxApplied != 0)
	JOIN Receipts ON RARD.ReceiptId = Receipts.Id 
	GROUP BY RARD.InvoiceId,Receipts.ReceivedDate,Receipts.ReceiptAmount_Currency,Receipts.Id;

	UPDATE #ReceivableInvoiceReceiptDetails 
	SET RIRDId = RIRD.Id
	FROM #ReceivableInvoiceReceiptDetails TempRIRD
	JOIN ReceivableInvoiceReceiptDetails RIRD ON TempRIRD.ReceiptId = RIRD.ReceiptId 
		AND TempRIRD.ReceivableInvoiceId = RIRD.ReceivableInvoiceId
		AND RIRD.IsActive = 1

	IF EXISTS( SELECT TOP 1 * FROM #ReceivableInvoiceReceiptDetails WHERE RIRDId IS NOT NULL)
		UPDATE ReceivableInvoiceReceiptDetails 
		SET ReceivedDate = TempRIRD.ReceivedDate,
			IsActive = TempRIRD.IsActive,
			AmountApplied_Amount = TempRIRD.AmountApplied_Amount,
			AmountApplied_Currency = TempRIRD.AmountApplied_Currency,
			TaxApplied_Amount = TempRIRD.TaxApplied_Amount,
			TaxApplied_Currency = TempRIRD.TaxApplied_Currency,
			CreatedById = TempRIRD.CreatedById,
			CreatedTime = TempRIRD.CreatedTime
		FROM ReceivableInvoiceReceiptDetails  
		JOIN #ReceivableInvoiceReceiptDetails TempRIRD ON TempRIRD.RIRDId = ReceivableInvoiceReceiptDetails.Id

	IF EXISTS( SELECT TOP 1* FROM #ReceivableInvoiceReceiptDetails WHERE RIRDId IS NULL)
		INSERT INTO ReceivableInvoiceReceiptDetails (ReceiptId, ReceivedDate, IsActive, ReceivableInvoiceId, AmountApplied_Amount, AmountApplied_Currency, TaxApplied_Amount, TaxApplied_Currency, CreatedById, CreatedTime) 
		SELECT TempRIRD.ReceiptId,
			TempRIRD.ReceivedDate,
			TempRIRD.IsActive,
			TempRIRD.ReceivableInvoiceId,
			TempRIRD.AmountApplied_Amount,
			TempRIRD.AmountApplied_Currency,
			TempRIRD.TaxApplied_Amount,
			TempRIRD.TaxApplied_Currency,
			TempRIRD.CreatedById,
			TempRIRD.CreatedTime
		FROM #ReceivableInvoiceReceiptDetails TempRIRD WHERE RIRDId IS NULL



	UPDATE 
		ReceivableInvoices
	SET
		LastReceivedDate = MaxReceivableDateDetails.MaxReceivedDate,
		UpdatedById = @CurrentUserId, 
		UpdatedTime = @CurrentTime 
	FROM ReceivableInvoices
	JOIN (SELECT ReceivableInvoiceReceiptDetails.ReceivableInvoiceId AS ReceivableInvoiceId,
				MAX(ReceivableInvoiceReceiptDetails.ReceivedDate) AS MaxReceivedDate
			FROM #ReceiptApplicationInfo
			JOIN ReceivableInvoiceReceiptDetails ON #ReceiptApplicationInfo.ReceiptId = ReceivableInvoiceReceiptDetails.ReceiptId
				AND ReceivableInvoiceReceiptDetails.IsActive = 1
				AND (ReceivableInvoiceReceiptDetails.AmountApplied_Amount != 0 OR ReceivableInvoiceReceiptDetails.TaxApplied_Amount != 0)
			GROUP BY ReceivableInvoiceReceiptDetails.ReceivableInvoiceId) 
	AS MaxReceivableDateDetails ON MaxReceivableDateDetails.ReceivableInvoiceId = ReceivableInvoices.Id
	WHERE ReceivableInvoices.LastReceivedDate IS NULL OR ReceivableInvoices.LastReceivedDate < MaxReceivableDateDetails.MaxReceivedDate;	


	SELECT 
		RI.StatementInvoiceId, 
		Sum(RD.AmountApplied) AmountApplied, 
		SUM(RD.TaxApplied) TaxApplied,
		SUM(AdjustedWithHoldingTax) AdjustedWithHoldingTax
	INTO #StatementInvoicesOfReceivableInvoices
	FROM #AppliedReceivableDetailInfo RD 
	INNER JOIN ReceivableInvoiceStatementAssociations RI ON RD.ReceivableInvoiceId = RI.ReceivableInvoiceId
	INNER JOIN ReceivableInvoices SI ON SI.Id = RI.StatementInvoiceId AND SI.IsActive = 1
	GROUP BY StatementInvoiceId

	IF EXISTS(SELECT TOP 1 * FROM #StatementInvoicesOfReceivableInvoices)
	BEGIN
		UPDATE RI
		SET 
		   Balance_Amount =  Balance_Amount - SRI.AmountApplied,
		   TaxBalance_Amount = TaxBalance_Amount - SRI.TaxApplied,
		   WithHoldingTaxBalance_Amount = WithHoldingTaxBalance_Amount - SRI.AdjustedWithHoldingTax,    
		   UpdatedById = @CurrentUserId, 
		   UpdatedTime = @CurrentTime
		FROM ReceivableInvoices RI
		INNER JOIN #StatementInvoicesOfReceivableInvoices SRI 
			ON RI.Id = SRI.StatementInvoiceId
	END

	DROP TABLE #ReceiptApplicationInfo
	DROP TABLE #AppliedReceivableDetailInfo
	DROP TABLE #TaxImpositions
	DROP TABLE #StatementInvoicesOfReceivableInvoices
	DROP TABLE #TempReceivableInfo
END

GO

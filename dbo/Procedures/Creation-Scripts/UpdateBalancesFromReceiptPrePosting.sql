SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateBalancesFromReceiptPrePosting]
(
@ReceiptApplicationInfo [ReceiptApplicationInfo] READONLY,
@CurrentUserId BIGINT,
@CurrentTime DATETIMEOFFSET,
@IsReceiptApplication BIT = 0,
@IsOverApplicationExist BIT OUTPUT
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
		AdjustedWithHoldingTax DECIMAL(16,2) NULL,
		ReceivableInvoiceId BIGINT NULL
	);

	CREATE NONCLUSTERED INDEX IX_ReceivableId
    ON #AppliedReceivableDetailInfo (ReceivableId);

	CREATE TABLE #ReceiptAppReceivableTaxDetails
	(
		Id BIGINT,
		ReceiptApplicationId BIGINT,
		ReceivedDate DATE,
		ReceivableDetailId BIGINT,
		TaxApplied DECIMAL(16,2),
		RunningTaxApplied DECIMAL(16,2)
	);	

	CREATE TABLE #ReceiptAppReceivableTaxImpositions
	(
		Id BIGINT,
		RARDId BIGINT,
		ReceivableDetailId BIGINT,
		ReceiptApplicationId BIGINT,
		TaxApplied DECIMAL(16,2),
		RunningTaxApplied DECIMAL(16,2),
		TaxImpositionId BIGINT,
		EffectiveTaxBalance DECIMAL(16,2),
		RunningEffectiveBalance DECIMAL(16,2),
		ImpositionTaxToApply DECIMAL(16,2),
		RunningImpositionTaxApplied DECIMAL(16,2),
		TaxDetailId BIGINT,
		ReceivableTaxId BIGINT,
		Currency NVARCHAR(6)
	);
		
	
	INSERT INTO #ReceiptApplicationInfo(ReceiptId,ApplicationId,ReceivedDate)
	SELECT ReceiptId,ApplicationId,ReceivedDate FROM @ReceiptApplicationInfo;

	INSERT INTO #AppliedReceivableDetailInfo(ReceivableId,ReceivableDetailId,AmountApplied,TaxApplied,BookAmountApplied,AdjustedWithHoldingTax)
	SELECT 
		ReceivableId,
		ReceivableDetailId,
		SUM(AmountApplied_Amount) AmountApplied,
		SUM(TaxApplied_Amount) TaxApplied,
		SUM(BookAmountApplied_Amount) BookAmountApplied,
		SUM(AdjustedWithholdingTax_Amount) AdjustedWithHoldingTax
	FROM #ReceiptApplicationInfo ReceiptApplication
	JOIN ReceiptApplicationReceivableDetails ON ReceiptApplication.ApplicationId = ReceiptApplicationReceivableDetails.ReceiptApplicationId AND ReceiptApplicationReceivableDetails.IsActive=1
	JOIN ReceivableDetails ON ReceiptApplicationReceivableDetails.ReceivableDetailId = ReceivableDetails.Id
	JOIN Receivables ON ReceivableDetails.ReceivableId = Receivables.Id
	GROUP BY ReceivableDetailId,ReceivableDetails.ReceivableId;

	-- Receivable Details 

	SET @IsOverApplicationExist = 0

	CREATE TABLE #ReceivableDetailsInfo (Amount DECIMAL, Balance DECIMAL)

	UPDATE ReceivableDetails 
	SET 
		EffectiveBalance_Amount = EffectiveBalance_Amount - #AppliedReceivableDetailInfo.AmountApplied,
		EffectiveBookBalance_Amount = EffectiveBookBalance_Amount - #AppliedReceivableDetailInfo.BookAmountApplied,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	OUTPUT INSERTED.Amount_Amount AS Amount, INSERTED.EffectiveBalance_Amount AS Balance INTO #ReceivableDetailsInfo
	FROM ReceivableDetails
	JOIN #AppliedReceivableDetailInfo ON ReceivableDetails.Id = #AppliedReceivableDetailInfo.ReceivableDetailId;

	IF EXISTS( 
		SELECT * FROM #ReceivableDetailsInfo
		WHERE (Amount > 0 AND Balance < 0) 
		OR (Amount < 0 AND Balance > 0)
	)
		SET @IsOverApplicationExist = 1	

	-- Receivables
	UPDATE ReceivableDetailsWithHoldingTaxDetails
	SET 
		EffectiveBalance_Amount = EffectiveBalance_Amount - #AppliedReceivableDetailInfo.AdjustedWithHoldingTax,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM ReceivableDetailsWithHoldingTaxDetails
	JOIN #AppliedReceivableDetailInfo ON ReceivableDetailsWithHoldingTaxDetails.ReceivableDetailId = #AppliedReceivableDetailInfo.ReceivableDetailId;


	-- Receivables
	SELECT 
		ReceivableId,
		SUM(AmountApplied) AmountApplied,
		SUM(AdjustedWithHoldingTax) AdjustedWithHoldingTax
	INTO #TempReceivableGroupedInfo
	FROM #AppliedReceivableDetailInfo
	GROUP BY ReceivableId

	UPDATE Receivables
	SET 
	    TotalEffectiveBalance_Amount = TotalEffectiveBalance_Amount - #TempReceivableGroupedInfo.AmountApplied,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM Receivables
	JOIN #TempReceivableGroupedInfo ON Receivables.Id = #TempReceivableGroupedInfo.ReceivableId;	

	UPDATE ReceivableWithholdingTaxDetails
	SET
		EffectiveBalance_Amount = EffectiveBalance_Amount - #TempReceivableGroupedInfo.AdjustedWithholdingTax,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM ReceivableWithholdingTaxDetails
	JOIN #TempReceivableGroupedInfo ON ReceivableWithholdingTaxDetails.ReceivableId = #TempReceivableGroupedInfo.ReceivableId;	
	
	--Receipt Application Receivable Tax Impositions - Calculation
	--IF (@IsReceiptApplication = 0)
	--BEGIN
	INSERT INTO #ReceiptAppReceivableTaxDetails
	SELECT 
		ReceiptApplicationReceivableDetails.Id,
		ReceiptApplicationId,
		ReceivedDate,
		ReceivableDetailId,
		TaxApplied_Amount TaxApplied,
		SUM(TaxApplied_Amount) OVER (PARTITION BY ReceivableDetailId ORDER BY ReceiptId, ReceivedDate) AS RunningTaxApplied
	FROM #ReceiptApplicationInfo
	JOIN ReceiptApplicationReceivableDetails ON #ReceiptApplicationInfo.ApplicationId = ReceiptApplicationReceivableDetails.ReceiptApplicationId
	AND (ReceiptApplicationReceivableDetails.AmountApplied_Amount != 0.00
	OR ReceiptApplicationReceivableDetails.TaxApplied_Amount != 0.00
	OR ReceiptApplicationReceivableDetails.BookAmountApplied_Amount != 0.00)
	;

	INSERT INTO #ReceiptAppReceivableTaxImpositions
	SELECT 
		ROW_NUMBER() OVER (ORDER BY ReceivableTaxImpositions.Amount_Amount,ReceivableTaxImpositions.Id) Id,
		#ReceiptAppReceivableTaxDetails.Id AS RARDId,
		#ReceiptAppReceivableTaxDetails.ReceivableDetailId,
		#ReceiptAppReceivableTaxDetails.ReceiptApplicationId,
		#ReceiptAppReceivableTaxDetails.TaxApplied,
		#ReceiptAppReceivableTaxDetails.RunningTaxApplied,
		ReceivableTaxImpositions.Id [TaxImpositionId],
		ReceivableTaxImpositions.EffectiveBalance_Amount [EffectiveTaxBalance],
		SUM(ReceivableTaxImpositions.EffectiveBalance_Amount) 
			OVER (PARTITION BY #ReceiptAppReceivableTaxDetails.ReceiptApplicationId, #ReceiptAppReceivableTaxDetails.ReceivableDetailId 
			ORDER BY ReceivableTaxImpositions.Amount_Amount,ReceivableTaxImpositions.Id) [RunningEffectiveBalance],
		0.00 [ImpositionTaxToApply],
		0.00 [RunningImpositionTaxApplied],
		ReceivableTaxDetails.Id [TaxDetailId],
		ReceivableTaxes.Id [ReceivableTaxId],
		ReceivableTaxDetails.Amount_Currency Currency
	FROM #ReceiptAppReceivableTaxDetails
	JOIN ReceivableTaxDetails ON #ReceiptAppReceivableTaxDetails.ReceivableDetailId = ReceivableTaxDetails.ReceivableDetailId AND ReceivableTaxDetails.IsActive=1
	JOIN ReceivableTaxImpositions ON ReceivableTaxDetails.Id = ReceivableTaxImpositions.ReceivableTaxDetailId AND ReceivableTaxImpositions.IsActive=1 
	JOIN ReceivableTaxes ON ReceivableTaxDetails.ReceivableTaxId = ReceivableTaxes.Id AND ReceivableTaxes.IsActive=1
	--LEFT JOIN #PrevReceiptAppReceivableTaxImpositions ON ReceivableTaxImpositions.Id = #PrevReceiptAppReceivableTaxImpositions.ReceivableTaxImpositionId
	WHERE (#ReceiptAppReceivableTaxDetails.TaxApplied != 0)
	AND ReceivableTaxImpositions.Balance_Amount <> 0 
	;

	UPDATE #ReceiptAppReceivableTaxImpositions
	SET ImpositionTaxToApply = EffectiveTaxBalance,
		RunningImpositionTaxApplied = RunningEffectiveBalance,
		EffectiveTaxBalance = 0
	WHERE (RunningTaxApplied >= 0 AND RunningEffectiveBalance <= RunningTaxApplied) 
	OR (RunningTaxApplied < 0 AND RunningEffectiveBalance >= RunningTaxApplied);

	;WITH CTE_RemainingTaxAmtToApply (Id,RemainingAmountToApply) AS
	(
		SELECT 
			TaxImpositionWithBalanceToUpdate.Id,
			RemainingTaxDetailsToApply.RemainingTaxToApply
		FROM (SELECT RARDId,RunningTaxApplied - SUM(ImpositionTaxToApply) RemainingTaxToApply 
			FROM #ReceiptAppReceivableTaxImpositions 
			GROUP BY RARDId,RunningTaxApplied
			HAVING RunningTaxApplied - SUM(ImpositionTaxToApply) != 0)  

		AS RemainingTaxDetailsToApply	
		JOIN (SELECT RARDId,MIN(Id) Id 
			FROM #ReceiptAppReceivableTaxImpositions 
			WHERE EffectiveTaxBalance <> 0 
			GROUP BY RARDId) 
		AS TaxImpositionWithBalanceToUpdate ON RemainingTaxDetailsToApply.RARDId = TaxImpositionWithBalanceToUpdate.RARDId
	)
	UPDATE #ReceiptAppReceivableTaxImpositions
	SET 
		ImpositionTaxToApply = ImpositionTaxToApply + CTE_RemainingTaxAmtToApply.RemainingAmountToApply,
		EffectiveTaxBalance = EffectiveTaxBalance - CTE_RemainingTaxAmtToApply.RemainingAmountToApply,
		RunningImpositionTaxApplied = RunningTaxApplied
	FROM #ReceiptAppReceivableTaxImpositions
	JOIN CTE_RemainingTaxAmtToApply ON #ReceiptAppReceivableTaxImpositions.Id = CTE_RemainingTaxAmtToApply.Id;
	
	UPDATE #ReceiptAppReceivableTaxImpositions
	SET ImpositionTaxToApply = 0
	WHERE RunningTaxApplied - TaxApplied != 0
	AND RunningImpositionTaxApplied <= RunningTaxApplied - TaxApplied;

	;WITH CTE_RemainingImpositionToClear (Id,TaxToClear) AS
	(
		SELECT 
			TaxImpositionWithExtractTaxAppliedToClear.Id,
			RemainingTaxDetailsToClear.TaxToClear
		FROM (SELECT RARDId,SUM(ImpositionTaxToApply) - TaxApplied TaxToClear 
			FROM #ReceiptAppReceivableTaxImpositions 
			GROUP BY RARDId,TaxApplied
			HAVING SUM(ImpositionTaxToApply) - TaxApplied != 0)  
		AS RemainingTaxDetailsToClear
		JOIN (SELECT RARDId,MIN(Id) Id 
			FROM #ReceiptAppReceivableTaxImpositions 
			WHERE ImpositionTaxToApply <> 0 
			GROUP BY RARDId) 
		AS TaxImpositionWithExtractTaxAppliedToClear ON RemainingTaxDetailsToClear.RARDId = TaxImpositionWithExtractTaxAppliedToClear.RARDId
	)
	UPDATE #ReceiptAppReceivableTaxImpositions
	SET 
		ImpositionTaxToApply = ImpositionTaxToApply - CTE_RemainingImpositionToClear.TaxToClear
	FROM #ReceiptAppReceivableTaxImpositions
	JOIN CTE_RemainingImpositionToClear ON #ReceiptAppReceivableTaxImpositions.Id = CTE_RemainingImpositionToClear.Id;

	--ReceiptApplicationReceivableTaxImpositions

	INSERT INTO ReceiptApplicationReceivableTaxImpositions
	(ReceiptApplicationId,AmountPosted_Amount, AmountPosted_Currency, IsActive, ReceivableTaxImpositionId, CreatedById,CreatedTime)
	SELECT ReceiptApplicationId, ImpositionTaxToApply, Currency, CAST(1 AS  BIT) IsActive, TaxImpositionId, @CurrentUserId, @CurrentTime
	FROM #ReceiptAppReceivableTaxImpositions r
	WHERE ImpositionTaxToApply <> 0
	GROUP BY ReceiptApplicationId, TaxImpositionId, Currency, ImpositionTaxToApply
	
	--Receivable Tax Impositions

	;WITH CTE_TaxImpositionDetails(TaxImpositionId, AmountToApply) AS 
	(
		SELECT 
			TaxImpositionId,
			SUM(ImpositionTaxToApply) AmountToApply
		FROM #ReceiptAppReceivableTaxImpositions 
		WHERE ImpositionTaxToApply <> 0.00
		GROUP BY TaxImpositionId
	)
	UPDATE ReceivableTaxImpositions
	SET 
		EffectiveBalance_Amount = EffectiveBalance_Amount - AmountToApply,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM ReceivableTaxImpositions
	JOIN CTE_TaxImpositionDetails ON ReceivableTaxImpositions.Id = CTE_TaxImpositionDetails.TaxImpositionId
	WHERE CTE_TaxImpositionDetails.AmountToApply <> 0.00

	--Receivable Tax Details

	CREATE TABLE #ReceivableTaxDetailsInfo (Amount DECIMAL, Balance DECIMAL)

	;WITH CTE_TaxDetails(TaxDetailId, AmountToApply) AS 
	(
		SELECT 
			TaxDetailId,
			SUM(ImpositionTaxToApply) AmountToApply
		FROM #ReceiptAppReceivableTaxImpositions 
		WHERE ImpositionTaxToApply <> 0.00
		GROUP BY TaxDetailId
	)
	UPDATE ReceivableTaxDetails
	SET 
		EffectiveBalance_Amount = EffectiveBalance_Amount - AmountToApply,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	OUTPUT INSERTED.Amount_Amount AS Amount, INSERTED.EffectiveBalance_Amount AS Balance INTO #ReceivableTaxDetailsInfo
	FROM ReceivableTaxDetails
	JOIN CTE_TaxDetails ON ReceivableTaxDetails.Id = CTE_TaxDetails.TaxDetailId

	IF EXISTS( 
		SELECT * FROM #ReceivableTaxDetailsInfo
		WHERE (Amount > 0 AND Balance < 0) 
		OR (Amount < 0 AND Balance > 0)
	)
		SET @IsOverApplicationExist = 1	

	--Receivable Taxes

	;WITH CTE_TaxDetails(ReceivableTaxId, AmountToApply) AS 
	(
		SELECT 
			ReceivableTaxId,
			SUM(ImpositionTaxToApply) AmountToApply
		FROM #ReceiptAppReceivableTaxImpositions 
		WHERE ImpositionTaxToApply <> 0.00
		GROUP BY ReceivableTaxId
	)
	UPDATE ReceivableTaxes
	SET 
		EffectiveBalance_Amount = EffectiveBalance_Amount - AmountToApply,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM ReceivableTaxes
	JOIN CTE_TaxDetails ON ReceivableTaxes.Id = CTE_TaxDetails.ReceivableTaxId;	


	-- Invoice Updates --For WHT, Invoice Story columns need to be taken for consideration later
	UPDATE #AppliedReceivableDetailInfo
	SET ReceivableInvoiceId = ReceivableInvoices.Id
	FROM #AppliedReceivableDetailInfo
	JOIN ReceivableInvoiceDetails ON #AppliedReceivableDetailInfo.ReceivableDetailId = ReceivableInvoiceDetails.ReceivableDetailId AND ReceivableInvoiceDetails.IsActive=1
	JOIN ReceivableInvoices ON ReceivableInvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id AND ReceivableInvoices.IsActive=1; 

	UPDATE ReceivableInvoiceDetails 
	SET 
		EffectiveBalance_Amount = EffectiveBalance_Amount - #AppliedReceivableDetailInfo.AmountApplied,
		EffectiveTaxBalance_Amount = EffectiveTaxBalance_Amount - #AppliedReceivableDetailInfo.TaxApplied,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM ReceivableInvoiceDetails
	JOIN #AppliedReceivableDetailInfo ON ReceivableInvoiceDetails.ReceivableDetailId = #AppliedReceivableDetailInfo.ReceivableDetailId
		AND ReceivableInvoiceDetails.ReceivableInvoiceId = #AppliedReceivableDetailInfo.ReceivableInvoiceId 
	WHERE ReceivableInvoiceDetails.IsActive=1

	--Receivable Invoices

	;WITH CTE_InvoiceInfo(ReceivableInvoiceId, AmountApplied, TaxApplied) AS
	(
		SELECT
			ReceivableInvoiceId,
			SUM(AmountApplied) AmountApplied, 
			SUM(TaxApplied) TaxApplied
		FROM #AppliedReceivableDetailInfo
		WHERE ReceivableInvoiceId IS NOT NULL
		GROUP BY ReceivableInvoiceId
	)
	UPDATE    
		ReceivableInvoices     
	SET     
		EffectiveBalance_Amount = EffectiveBalance_Amount - AmountApplied,   
		EffectiveTaxBalance_Amount = EffectiveTaxBalance_Amount - TaxApplied,   
		UpdatedById = @CurrentUserId, 
		UpdatedTime = @CurrentTime     
	FROM     
		ReceivableInvoices    
		JOIN CTE_InvoiceInfo AS InvoiceInfo ON InvoiceInfo.ReceivableInvoiceId = ReceivableInvoices.Id;

    SELECT 
		RI.StatementInvoiceId, 
		Sum(RD.AmountApplied) AmountApplied, 
		SUM(RD.TaxApplied) TaxApplied 
	INTO #StatementInvoicesOfReceivableInvoices
	FROM #AppliedReceivableDetailInfo RD 
	INNER JOIN ReceivableInvoiceStatementAssociations RI ON RD.ReceivableInvoiceId = RI.ReceivableInvoiceId
	INNER JOIN ReceivableInvoices SI ON SI.Id = RI.StatementInvoiceId AND SI.IsActive = 1
	GROUP BY RI.StatementInvoiceId

	IF EXISTS(SELECT TOP 1 * FROM #StatementInvoicesOfReceivableInvoices)
	BEGIN
		UPDATE RI
		SET 
		   EffectiveBalance_Amount =  EffectiveBalance_Amount - SRI.AmountApplied,
		   EffectiveTaxBalance_Amount =  EffectiveTaxBalance_Amount - SRI.TaxApplied,
		   UpdatedById = @CurrentUserId, 
		   UpdatedTime = @CurrentTime
		FROM ReceivableInvoices RI
		INNER JOIN #StatementInvoicesOfReceivableInvoices SRI 
			ON RI.Id = SRI.StatementInvoiceId
	END
	
	DROP TABLE #ReceiptApplicationInfo
	DROP TABLE #AppliedReceivableDetailInfo
	DROP TABLE #ReceiptAppReceivableTaxDetails
	DROP TABLE #ReceiptAppReceivableTaxImpositions
	DROP TABLE #StatementInvoicesOfReceivableInvoices
	DROP TABLE #TempReceivableGroupedInfo
END

GO

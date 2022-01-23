SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateBalancesFromReceiptReversal]
(
	@ReceiptId BIGINT,
	@JobStepInstanceId BIGINT,
	@CurrentUserId BIGINT,
	@CurrentTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;

	CREATE TABLE #ReversedReceivableDetailInfo
	(
		ReceivableId BIGINT,
		ReceivableDetailId BIGINT,
		AmountApplied DECIMAL(16,2),
		TaxApplied DECIMAL(16,2),
		BookAmountApplied DECIMAL(16,2),
		AdjustedWithHoldingTax DECIMAL(16,2),
		ReceivableInvoiceId BIGINT NULL,
		LeaseComponentAmountApplied DECIMAL(16,2) NULL,
		NonLeaseComponentAmountApplied DECIMAL(16,2) NULL,
	);

	CREATE NONCLUSTERED INDEX IX_ReceivableId
    ON #ReversedReceivableDetailInfo (ReceivableId);

	CREATE TABLE #ReversedReceivableTaxDetails
	(
		Id BIGINT,
		ReceiptApplicationId BIGINT,
		ReceivableDetailId BIGINT,
		TaxApplied DECIMAL(16,2),
	);	

	CREATE TABLE #ReversedReceivableTaxImpositions
	(
		ReceivableTaxImpositionId BIGINT,
		ReceivableTaxDetailId BIGINT,
		ReceivableTaxId BIGINT,
		TaxApplied DECIMAL(16,2)
	);
	
	-- Receivable and details
	INSERT INTO #ReversedReceivableDetailInfo (ReceivableId, ReceivableDetailId, AmountApplied, TaxApplied, BookAmountApplied, AdjustedWithHoldingTax,
	LeaseComponentAmountApplied,NonLeaseComponentAmountApplied,ReceivableInvoiceId)
	SELECT 
		ReceivableId,
		ReceivableDetailId,
		SUM(AmountApplied) AS AmountApplied,
		SUM(TaxApplied) AS TaxApplied,
		SUM(BookAmountApplied) AS BookAmountApplied,
		SUM(AdjustedWithHoldingTax) AS AdjustedWithHoldingTax,
		SUM(LeaseComponentAmountApplied) LeaseComponentAmountApplied,
		SUM(NonLeaseComponentAmountApplied) NonLeaseComponentAmountApplied,
		InvoiceId AS ReceivableInvoiceId
	FROM ReceiptReceivableDetails_Extract 
	WHERE ReceiptId = @ReceiptId AND JobStepInstanceId = @JobStepInstanceId
	GROUP BY ReceivableId, ReceivableDetailId, InvoiceId;	

	-- Receivable Details 
	UPDATE ReceivableDetails 
	SET Balance_Amount = Balance_Amount + AmountApplied,
		EffectiveBalance_Amount = EffectiveBalance_Amount + AmountApplied,
		EffectiveBookBalance_Amount = EffectiveBookBalance_Amount + BookAmountApplied,
		LeaseComponentBalance_Amount = LeaseComponentBalance_Amount + LeaseComponentAmountApplied,
		NonLeaseComponentBalance_Amount = NonLeaseComponentBalance_Amount + NonLeaseComponentAmountApplied,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM ReceivableDetails
	JOIN #ReversedReceivableDetailInfo ON ReceivableDetails.Id = #ReversedReceivableDetailInfo.ReceivableDetailId

	UPDATE ReceivableDetailsWithholdingTaxDetails 
	SET Balance_Amount = Balance_Amount + AdjustedWithHoldingTax,
		EffectiveBalance_Amount = EffectiveBalance_Amount + AdjustedWithHoldingTax,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM ReceivableDetailsWithholdingTaxDetails
	JOIN #ReversedReceivableDetailInfo ON ReceivableDetailsWithholdingTaxDetails.ReceivableDetailId = #ReversedReceivableDetailInfo.ReceivableDetailId
	AND ReceivableDetailsWithholdingTaxDetails.IsActive=1

	UPDATE ReceiptApplicationReceivableDetails
		SET ReceivedTowardsInterest_Amount = 0.00
	FROM ReceiptApplicationReceivableDetails RARD
	JOIN ReceiptReceivableDetails_Extract RRD ON RARD.ReceiptApplicationId = RRD.ReceiptApplicationId
		AND RARD.ReceivableDetailId = RRD.ReceivableDetailId AND ReceiptId = @ReceiptId
		AND JobStepInstanceId = @JobStepInstanceId

	---- Receivables
	;WITH CTE_ReceivableInfo (ReceivableId, AmountApplied, BookAmountApplied) AS
	(
		SELECT 
			ReceivableId,
			SUM(AmountApplied) AmountApplied,
			SUM(BookAmountApplied) BookAmountApplied
		FROM #ReversedReceivableDetailInfo
		GROUP BY ReceivableId
	)

	UPDATE Receivables
	SET TotalBalance_Amount = TotalBalance_Amount + CTE_ReceivableInfo.AmountApplied,
		TotalEffectiveBalance_Amount = TotalEffectiveBalance_Amount + CTE_ReceivableInfo.AmountApplied,
		TotalBookBalance_Amount = TotalBookBalance_Amount + CTE_ReceivableInfo.BookAmountApplied,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM Receivables
	JOIN CTE_ReceivableInfo ON Receivables.Id = CTE_ReceivableInfo.ReceivableId;	
	
	;WITH CTE_ReceivableWHTInfo (ReceivableId, AdjustedWithHoldingTax) AS
	(
		SELECT 
			ReceivableId,
			SUM(AdjustedWithHoldingTax) AdjustedWithHoldingTax
		FROM #ReversedReceivableDetailInfo
		GROUP BY ReceivableId
	)
	UPDATE ReceivableWithholdingTaxDetails
	SET Balance_Amount = Balance_Amount + CTE_ReceivableWHTInfo.AdjustedWithHoldingTax,
		EffectiveBalance_Amount = EffectiveBalance_Amount + CTE_ReceivableWHTInfo.AdjustedWithHoldingTax,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM ReceivableWithholdingTaxDetails
	JOIN CTE_ReceivableWHTInfo ON ReceivableWithholdingTaxDetails.ReceivableId = CTE_ReceivableWHTInfo.ReceivableId AND ReceivableWithholdingTaxDetails.IsActive=1	
	
	-- Receivable Taxes
	INSERT INTO #ReversedReceivableTaxImpositions
	SELECT 
		RTI.Id ReceivableTaxImpositionId,
		RTD.Id ReceivableTaxDetailId,
		RTD.ReceivableTaxId,
		SUM(RARTI.AmountPosted_Amount) TaxApplied
	FROM ReceiptApplications RA
	JOIN ReceiptApplicationReceivableTaxImpositions RARTI ON RA.Id = RARTI.ReceiptApplicationId 
		AND RARTI.AmountPosted_Amount <> 0 AND RARTI.IsActive = 1
	JOIN ReceivableTaxImpositions RTI ON RARTI.ReceivableTaxImpositionId = RTI.Id AND RTI.IsActive=1
	JOIN ReceivableTaxDetails RTD ON RTI.ReceivableTaxDetailId = RTD.Id AND RTD.IsActive=1
	WHERE RA.ReceiptId = @ReceiptId
	GROUP BY RTI.Id,RTD.Id,RTD.ReceivableTaxId

	-- Update Receivable Tax Impositions
	UPDATE ReceivableTaxImpositions
	SET Balance_Amount = Balance_Amount + TaxApplied,
		EffectiveBalance_Amount = EffectiveBalance_Amount + TaxApplied,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM ReceivableTaxImpositions
	JOIN #ReversedReceivableTaxImpositions ON ReceivableTaxImpositions.Id = #ReversedReceivableTaxImpositions.ReceivableTaxImpositionId

	-- Update Receivable Tax Details
	;WITH CTE_TaxDetails AS 
	(
		SELECT 
			ReceivableTaxDetailId,
			SUM(TaxApplied) TaxApplied
		FROM #ReversedReceivableTaxImpositions 
		GROUP BY ReceivableTaxDetailId
	)
	UPDATE ReceivableTaxDetails
	SET Balance_Amount = Balance_Amount + CTE_TaxDetails.TaxApplied,
		EffectiveBalance_Amount = EffectiveBalance_Amount + CTE_TaxDetails.TaxApplied,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM CTE_TaxDetails
	JOIN ReceivableTaxDetails ON ReceivableTaxDetails.Id = CTE_TaxDetails.ReceivableTaxDetailId

	-- Receivable Taxes
	;WITH CTE_Tax AS 
	(
		SELECT 
			ReceivableTaxId,
			SUM(TaxApplied) AS TaxApplied
		FROM #ReversedReceivableTaxImpositions 
		GROUP BY ReceivableTaxId
	)
	UPDATE ReceivableTaxes
	SET Balance_Amount = Balance_Amount + CTE_Tax.TaxApplied,
		EffectiveBalance_Amount = EffectiveBalance_Amount + CTE_Tax.TaxApplied,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM CTE_Tax
	JOIN ReceivableTaxes ON ReceivableTaxes.Id = CTE_Tax.ReceivableTaxId;	

	-- Update ReceivableInvoiceDetails
	UPDATE ReceivableInvoiceDetails 
	SET Balance_Amount = Balance_Amount + AmountApplied,
		EffectiveBalance_Amount = EffectiveBalance_Amount + AmountApplied,
		TaxBalance_Amount = TaxBalance_Amount + TaxApplied,
		EffectiveTaxBalance_Amount = TaxBalance_Amount + TaxApplied,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM ReceivableInvoiceDetails 
	JOIN #ReversedReceivableDetailInfo ON ReceivableInvoiceDetails.ReceivableDetailId = #ReversedReceivableDetailInfo.ReceivableDetailId
	WHERE ReceivableInvoiceDetails.IsActive = 1

	-- Update Receivable Invoices
	;WITH CTE_InvoiceInfo AS
	(
		SELECT
			ReceivableInvoiceId,
			SUM(AmountApplied) AmountApplied, 
			SUM(TaxApplied) TaxApplied,
			SUM(AdjustedWithHoldingTax) AdjustedWithHoldingTax
		FROM #ReversedReceivableDetailInfo 
		WHERE ReceivableInvoiceId IS NOT NULL
		GROUP BY ReceivableInvoiceId
	)
	UPDATE    
		ReceivableInvoices     
	SET     
		Balance_Amount = Balance_Amount + InvoiceInfo.AmountApplied,    
		EffectiveBalance_Amount = EffectiveBalance_Amount + InvoiceInfo.AmountApplied,    
		TaxBalance_Amount = TaxBalance_Amount + InvoiceInfo.TaxApplied,    
		EffectiveTaxBalance_Amount = EffectiveTaxBalance_Amount + InvoiceInfo.TaxApplied, 
		WithHoldingTaxBalance_Amount = WithHoldingTaxBalance_Amount + InvoiceInfo.AdjustedWithHoldingTax,   
		UpdatedById = @CurrentUserId, 
		UpdatedTime = @CurrentTime     
	FROM     
		ReceivableInvoices    
		JOIN CTE_InvoiceInfo AS InvoiceInfo ON InvoiceInfo.ReceivableInvoiceId = ReceivableInvoices.Id;
	
	----Receivable Invoice Receipt Details	
	
	UPDATE ReceivableInvoiceReceiptDetails 
	SET IsActive = 0
	WHERE ReceiptId = @ReceiptId

	-- Set ReceivableInvoice - LastReceivedDate to prev receipt 

	;WITH CTE AS
	(
		SELECT RI.Id AS ReceivableInvoiceId, MAX(RID.ReceivedDate) AS LastReceivedDate
		FROM ReceivableInvoices RI
		JOIN (SELECT ReceivableInvoiceId
			  FROM ReceivableInvoiceReceiptDetails 
			  WHERE ReceiptId = @ReceiptId) ReceiptInvoices 
			ON RI.Id = ReceiptInvoices.ReceivableInvoiceId
		LEFT JOIN ReceivableInvoiceReceiptDetails RID ON RID.ReceivableInvoiceId = RI.Id
		WHERE RI.IsDummy = 0 AND RI.IsActive = 1 AND RID.IsActive = 1
		GROUP BY RI.Id
	)
	UPDATE RI
		SET LastReceivedDate = CTE.LastReceivedDate,
			UpdatedById = @CurrentUserId, 
			UpdatedTime = @CurrentTime     
	FROM ReceivableInvoices RI
	JOIN CTE ON RI.Id = CTE.ReceivableInvoiceId

	SELECT DISTINCT StatementInvoiceId 
	INTO #StatementInvoicesOfReceivableInvoices
	FROM #ReversedReceivableDetailInfo RD 
	INNER JOIN ReceivableInvoiceStatementAssociations RI ON RD.ReceivableInvoiceId = RI.ReceivableInvoiceId

	IF EXISTS(SELECT TOP 1 * FROM #StatementInvoicesOfReceivableInvoices)
	BEGIN
	SELECT 
        SRI.StatementInvoiceId,
	    Balance_Amount = ISNULL(SUM(RI.Balance_Amount), 0),
        TaxBalance_Amount = ISNULL(SUM(TaxBalance_Amount),0),
		EffectiveBalance_Amount = ISNULL(SUM(RI.EffectiveBalance_Amount), 0),
		EffectiveTaxBalance_Amount = ISNULL(SUM(EffectiveTaxBalance_Amount),0),
		WithHoldingTaxBalance_Amount = ISNULL(SUM(WithHoldingTaxBalance_Amount),0)
	INTO #StatementInvoicesUpdateAmount
	FROM #StatementInvoicesOfReceivableInvoices SRI 
	INNER JOIN ReceivableInvoiceStatementAssociations RSI ON SRI.StatementInvoiceId = RSI.StatementInvoiceID
	INNER JOIN ReceivableInvoices RI ON RSI.ReceivableInvoiceId = RI.Id AND RI.IsActive =1
	GROUP BY SRI.StatementInvoiceId


	UPDATE RI
	SET 
	    Balance_Amount =  SRI.Balance_Amount,
        TaxBalance_Amount = SRI.TaxBalance_Amount,
		EffectiveBalance_Amount = SRI.EffectiveBalance_Amount,
		EffectiveTaxBalance_Amount = SRI.EffectiveTaxBalance_Amount,
		WithHoldingTaxBalance_Amount = SRI.WithHoldingTaxBalance_Amount,
	    UpdatedById = @CurrentUserId, 
	    UpdatedTime = @CurrentTime
    FROM ReceivableInvoices RI
    INNER JOIN #StatementInvoicesUpdateAmount SRI ON RI.Id = SRI.StatementInvoiceId AND RI.IsActive = 1
	END
	
	DROP TABLE #ReversedReceivableDetailInfo
	DROP TABLE #ReversedReceivableTaxDetails
	DROP TABLE #ReversedReceivableTaxImpositions
	DROP TABLE #StatementInvoicesOfReceivableInvoices
	IF OBJECT_ID('tempdb..#StatementInvoicesUpdateAmount') IS NOT NULL
		DROP TABLE #StatementInvoicesUpdateAmount

END

GO

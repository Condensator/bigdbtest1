SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROC [dbo].[ExtractApplicationFullPostingCashReceipts]
(
	@ReceiptBatchId									BIGINT, 
	@PostDate										DATETIME, 
	@JobStepInstanceId								BIGINT, 
	@UserId											BIGINT,
	@VATInvoiceNotFullyCleared						NVARCHAR(200),
	@VatTaxOutstandingBalanceNotCompletelyApplied	NVARCHAR(200),
	@InvoiceTaxBalanceNotClearedForReceiptBatch		NVARCHAR(500),
	@IsPostingAllowed								BIT
)
AS
BEGIN
	SET NOCOUNT OFF;
	DECLARE @RoundingValue DECIMAL(16,2) = 0.01;

CREATE TABLE #RARD_ExtractTemp  
(  
	RARD_ExtractId BIGINT,  
	ReceiptId BIGINT,
	ReceivableId BIGINT,  
	ReceivableDetailId BIGINT,
	AmountApplied DECIMAL(16,2), 
	LeaseComponentAmountApplied DECIMAL(16,2), 
	NonLeaseComponentAmountApplied DECIMAL(16,2),  
)  

CREATE TABLE #RARD_Extracts
(  
	RARD_ExtractId BIGINT,  
	ReceiptId BIGINT,
	ReceivableId BIGINT,  
	ReceivableDetailId BIGINT,
	RowNumber BIGINT,
	Amount_Amount DECIMAL(16,2), 
	ComponentType NVARCHAR(20)
)  

CREATE TABLE #UpdatedRARDTemp
(
  Id BIGINT,
)

	SELECT
		RPBF.InvoiceNumber Number, 
		RPBF.ComputedReceivableInvoiceId ReceivableInvoiceId, 
		RPBF.ReceiptAmount, 
		(RID.EffectiveBalance_Amount - ISNULL(RDWTH.EffectiveBalance_Amount, 0.00)) AS AmountApplied,
		RID.EffectiveTaxBalance_Amount AS TaxApplied, 
		BookAmountApplied = CASE WHEN ((RT.[Name] = 'LoanInterest' OR RT.[Name] = 'LoanPrincipal') 
								AND (R.IncomeType != 'InterimInterest' AND R.IncomeType != 'TakeDownInterest'))
							THEN RID.EffectiveBalance_Amount
							ELSE 0.00 END, 
		RID.ReceivableDetailId, 
		RD.IsActive AS ReceivableDetailIsActive, 
		RID.ReceivableInvoiceId AS InvoiceId, 
		ContractId = CASE WHEN (R.EntityType = 'CT') THEN R.EntityId ELSE NULL END, 
		DiscountingId = CASE WHEN (R.EntityType = 'DT') THEN R.EntityId ELSE NULL END, 
		R.Id AS ReceivableId, 
		RPBF.GroupNumber AS ReceiptId, 
		@JobStepInstanceId AS  JobStepInstanceId, 
		0 AS ReceiptApplicationReceivableDetailId, 
		RPBF.GroupNumber AS DumpId,
		@UserId AS CreatedById, 
		GETDATE() AS CreatedTime,
		0 AS IsReApplication,
		ISNULL(ROUND((((rid.EffectiveBalance_Amount - ISNULL(RDWTH.EffectiveBalance_Amount, 0.00)) * RD.LeaseComponentBalance_Amount)/NULLIF(RD.LeaseComponentBalance_Amount + RD.NonLeaseComponentBalance_Amount,0)),2),0.00) AS LeaseComponentAmountApplied,
        ISNULL(ROUND((((rid.EffectiveBalance_Amount - ISNULL(RDWTH.EffectiveBalance_Amount, 0.00)) * RD.NonLeaseComponentBalance_Amount)/NULLIF(RD.LeaseComponentBalance_Amount + RD.NonLeaseComponentBalance_Amount,0)),2),0.00) AS NonLeaseComponentAmountApplied,
		RPBF.ReceivableTaxType
	INTO #RRDTempExtract
	FROM ReceiptPostByFileExcel_Extract RPBF
	INNER JOIN ReceivableInvoiceDetails RID ON RPBF.ComputedReceivableInvoiceId = RID.ReceivableInvoiceId
	INNER JOIN ReceivableDetails RD ON RID.ReceivableDetailId = RD.Id
	INNER JOIN Receivables R ON RD.ReceivableId = R.Id
	INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
	INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
	LEFT JOIN ReceivableDetailsWithholdingTaxDetails RDWTH ON RD.Id = RDWTH.ReceivableDetailId AND RDWTH.IsActive = 1
	WHERE RPBF.JobStepInstanceId = @JobStepInstanceId
		AND RPBF.HasError = 0 AND RPBF.CreateUnallocatedReceipt=0
		AND RPBF.ComputedIsGrouped = 0 AND RPBF.IsInvoiceInMultipleReceipts = 0
		AND RPBF.ComputedIsDSL = 0 AND RPBF.NonAccrualCategory IS NULL AND RPBF.ComputedIsFullPosting = 1
		AND ((RID.EffectiveBalance_Amount + RID.EffectiveTaxBalance_Amount > 0) OR RPBF.IsApplyCredit = 1)
		AND RID.EntityId = CASE WHEN RPBF.EntityType = 'Lease' OR RPBF.EntityType = 'Loan' THEN RPBF.ComputedContractId
								WHEN RPBF.EntityType = 'Discounting' THEN RPBF.ComputedDiscountingId
								ELSE RID.EntityId END
		AND RID.EntityType = CASE WHEN RPBF.EntityType = 'Lease' OR RPBF.EntityType = 'Loan' THEN 'CT'
								  WHEN RPBF.EntityType = 'Discounting' THEN 'DT'
								  ELSE RID.EntityType END
	;

	DECLARE @ValidateVATInvoiceForPostByFileTable  ValidateVATInvoiceForPostByFileTable							  
	INSERT INTO @ValidateVATInvoiceForPostByFileTable
	SELECT Number, ReceivableInvoiceId, ReceiptAmount, ReceivableDetailId, DumpId FROM #RRDTempExtract
	WHERE ReceivableTaxType = 'VAT'
	EXEC ValidateVATInvoiceForPostByFile @ValidateVATInvoiceForPostByFileTable, @VATInvoiceNotFullyCleared, @VatTaxOutstandingBalanceNotCompletelyApplied, 
										 @InvoiceTaxBalanceNotClearedForReceiptBatch, @JobStepInstanceId, @IsPostingAllowed, @ReceiptBatchId

	INSERT INTO ReceiptApplicationReceivableDetails_Extract (
		AmountApplied, 
		TaxApplied, 
		BookAmountApplied, 
		ReceivableDetailId, 
		ReceivableDetailIsActive, 
		InvoiceId, 
		ContractId, 
		DiscountingId, 
		ReceivableId, 
		ReceiptId, 
		JobStepInstanceId, 
		ReceiptApplicationReceivableDetailId, 
		DumpId,
		CreatedById, 
		CreatedTime,
		IsReApplication,
		LeaseComponentAmountApplied,
		NonLeaseComponentAmountApplied
		)
	OUTPUT INSERTED.Id,INSERTED.ReceiptId,INSERTED.ReceivableId,INSERTED.ReceivableDetailId,INSERTED.AmountApplied,INSERTED.LeaseComponentAmountApplied,INSERTED.NonLeaseComponentAmountApplied into #RARD_ExtractTemp
	SELECT
		AmountApplied, 
		TaxApplied, 
		BookAmountApplied, 
		ReceivableDetailId, 
		ReceivableDetailIsActive, 
		InvoiceId, 
		ContractId, 
		DiscountingId, 
		ReceivableId, 
		RRDE.ReceiptId, 
		RRDE.JobStepInstanceId, 
		ReceiptApplicationReceivableDetailId, 
		DumpId,
		RRDE.CreatedById, 
		RRDE.CreatedTime,
		IsReApplication,
		LeaseComponentAmountApplied,
		NonLeaseComponentAmountApplied
	FROM #RRDTempExtract RRDE
	INNER JOIN ReceiptPostByFileExcel_Extract RPB ON RRDE.ReceivableInvoiceId = RPB.ComputedReceivableInvoiceId
	AND RPB.JobStepInstanceId = @JobStepInstanceId
	WHERE RPB.ErrorMessage IS NULL

    INSERT INTO #RARD_Extracts(RARD_ExtractId,ReceiptId,ReceivableId,ReceivableDetailId,Amount_Amount,ComponentType,RowNumber)
	SELECT RARD_ExtractId,ReceiptId,ReceivableId,ReceivableDetailId,LeaseComponentAmountApplied AS Amount_Amount,'Lease',
	CASE WHEN LeaseComponentAmountApplied >= NonLeaseComponentAmountApplied THEN 1 ELSE 2 END AS RowNumber
	FROM #RARD_ExtractTemp RE
    UNION ALL
	SELECT RARD_ExtractId,ReceiptId,ReceivableId,ReceivableDetailId,NonLeaseComponentAmountApplied AS Amount_Amount,'NonLease',
	CASE WHEN NonLeaseComponentAmountApplied > LeaseComponentAmountApplied THEN 1 ELSE 2 END AS RowNumber
	FROM #RARD_ExtractTemp RE

    UPDATE #RARD_Extracts
	SET Amount_Amount = Amount_Amount + RoundingValue
	OUTPUT INSERTED.RARD_ExtractId INTO #UpdatedRARDTemp
	FROM #RARD_Extracts
	JOIN (
	        SELECT #RARD_ExtractTemp.RARD_ExtractId,(#RARD_ExtractTemp.AmountApplied - SUM(Amount_Amount)) DifferenceAfterDistribution,
			CASE WHEN (#RARD_ExtractTemp.AmountApplied - SUM(Amount_Amount)) < 0 THEN -(@RoundingValue) ELSE @RoundingValue END AS RoundingValue
		    FROM  #RARD_ExtractTemp
			JOIN #RARD_Extracts ON #RARD_ExtractTemp.RARD_ExtractId = #RARD_Extracts.RARD_ExtractId
			GROUP BY  #RARD_ExtractTemp.ReceivableId,#RARD_ExtractTemp.ReceivableDetailId,#RARD_ExtractTemp.RARD_ExtractId,#RARD_ExtractTemp.AmountApplied
			HAVING #RARD_ExtractTemp.AmountApplied <> SUM(Amount_Amount)
         ) AS AppliedRARD_Extracts
		 ON #RARD_Extracts.RARD_ExtractId = AppliedRARD_Extracts.RARD_ExtractId
    WHERE  (#RARD_Extracts.RowNumber <= CAST(AppliedRARD_Extracts.DifferenceAfterDistribution/RoundingValue AS BIGINT)
	     AND AppliedRARD_Extracts.RARD_ExtractId = #RARD_Extracts.RARD_ExtractId)
		
	UPDATE ReceiptApplicationReceivableDetails_Extract
       SET LeaseComponentAmountApplied = CASE WHEN #RARD_Extracts.ComponentType = 'Lease' THEN #RARD_Extracts.Amount_Amount ELSE LeaseComponentAmountApplied END
           ,NonLeaseComponentAmountApplied = CASE WHEN #RARD_Extracts.ComponentType = 'NonLease' THEN #RARD_Extracts.Amount_Amount ELSE NonLeaseComponentAmountApplied END
   FROM #RARD_Extracts
       INNER JOIN ReceiptApplicationReceivableDetails_Extract RARDE ON #RARD_Extracts.RARD_ExtractId = RARDE.Id
       INNER JOIN #UpdatedRARDTemp ON RARDE.Id = #UpdatedRARDTemp.Id

DROP TABLE #RARD_ExtractTemp
DROP TABLE #RARD_Extracts
DROP TABLE #UpdatedRARDTemp

END

GO

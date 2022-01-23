SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[GetExtractDataForInvoiceInMultipleReceipts] 
(
	@JobStepInstanceId								BIGINT,
	@VATInvoiceNotFullyCleared						NVARCHAR(200),
	@VatTaxOutstandingBalanceNotCompletelyApplied	NVARCHAR(200),
	@InvoiceTaxBalanceNotClearedForReceiptBatch		NVARCHAR(500),
	@IsPostingAllowed								BIT,
	@ReceiptBatchId									BIGINT NULL
)
AS
BEGIN
	SET NOCOUNT OFF;

	SELECT 
		re.ReceiptId, 
		re.ReceiptNumber, 
		re.Currency, 
		re.ReceivedDate, 
		re.LegalEntityId, 
		re.LineOfBusinessId, 
		re.CostCenterId, 
		re.InstrumentTypeId, 
		re.ContractId ,
		re.DiscountingId, 
		re.EntityType AS ReceiptEntityType,
		re.ReceiptHierarchyTemplateId,
		rpbf.ReceiptAmount,  
		rpbf.ComputedReceivableInvoiceId AS InvoiceId,
		rpbf.IsApplyCredit,
		rpbf.IsStatementInvoice,
		re.ReceivableTaxType
	FROM Receipts_Extract re
	JOIN ReceiptPostByFileExcel_Extract rpbf ON rpbf.GroupNumber = re.DumpId AND rpbf.JobStepInstanceId = re.JobStepInstanceId 
	WHERE re.JobStepInstanceId = @JobStepInstanceId
		AND rpbf.HasError = 0
		AND rpbf.IsInvoiceInMultipleReceipts = 1
		AND rpbf.NonAccrualCategory IS NULL AND RPBF.CreateUnallocatedReceipt=0

	SELECT 
		ComputedReceivableInvoiceId AS InvoiceId, GroupNumber AS ReceiptId, 
		SUM(ReceiptAmount) ReceiptAmount, InvoiceNumber, ReceivableTaxType INTO #InvoiceIds
	FROM ReceiptPostByFileExcel_Extract 
	WHERE JobStepInstanceId = @JobStepInstanceId 
		AND HasError = 0
		AND IsInvoiceInMultipleReceipts = 1 AND CreateUnallocatedReceipt=0
	 GROUP BY ComputedReceivableInvoiceId, GroupNumber, InvoiceNumber, ReceivableTaxType

	 CREATE TABLE #RRDExtract
	 (
		ReceiptId					BIGINT,
	    InvoiceId					BIGINT,
		EffectiveBalance			DECIMAL(16, 2),
		EffectiveTaxBalance			DECIMAL(16, 2),
		ReceivableDetailId			BIGINT,
		CustomerId					BIGINT NULL,
		ContractId					BIGINT NULL,
		DiscountingId				BIGINT NULL,
		ReceivableTypeId			BIGINT,
		ReceivableType				NVARCHAR(200),
		PaymentScheduleId			BIGINT NULL,
		ReceivableId				BIGINT,
		IsReceivableDetailActive	BIT,
		ReceivableEntityType		NVARCHAR(20),
		ReceivableEntityId			BIGINT NULL,
		DueDate						DATE,
		IncomeType					NVARCHAR(100),
		ReceivableInvoiceId			BIGINT NULL,
		LeaseComponentBalance		DECIMAL(16, 2),
		NonLeaseComponentBalance	DECIMAL(16, 2),
		Currency					NVARCHAR(10),
		ReceiptAmount				DECIMAL(16, 2),
		Number						NVARCHAR(200),
		ReceivableTaxType			NVARCHAR(20)
	 )

	INSERT INTO #RRDExtract
	SELECT 
	    I.ReceiptId,
	    rid.ReceivableInvoiceId AS InvoiceId,
		(rid.EffectiveBalance_Amount - ISNULL(RDWHT.EffectiveBalance_Amount, 0.00)) AS EffectiveBalance,
		rid.EffectiveTaxBalance_Amount AS EffectiveTaxBalance,
		rid.ReceivableDetailId,
		r.CustomerId AS CustomerId,
		CASE WHEN r.EntityType = 'CT' THEN r.EntityId ELSE NULL END AS ContractId,
		CASE WHEN r.EntityType = 'DT' THEN r.EntityId ELSE NULL END AS DiscountingId,
		ReceivableTypes.Id AS ReceivableTypeId,
		ReceivableTypes.[Name] AS ReceivableType,
		r.PaymentScheduleId,
		r.Id AS ReceivableId,
		rd.IsActive AS IsReceivableDetailActive,
		r.EntityType AS ReceivableEntityType,
		r.EntityId AS ReceivableEntityId,
		r.DueDate,
		r.IncomeType,
		ReceivableInvoiceId = ri.Id,
		rd.LeaseComponentBalance_Amount AS LeaseComponentBalance,
		rd.NonLeaseComponentBalance_Amount AS NonLeaseComponentBalance,
		rd.LeaseComponentAmount_Currency AS Currency,
		I.ReceiptAmount,
		I.InvoiceNumber,
		I.ReceivableTaxType
	FROM #InvoiceIds I 
	INNER JOIN ReceivableInvoices ri ON ri.Id = I.InvoiceId and ri.IsActive = 1
	INNER JOIN ReceivableInvoiceDetails rid ON rid.ReceivableInvoiceId = ri.Id and rid.IsActive = 1
	INNER JOIN ReceivableDetails rd ON rid.ReceivableDetailId = rd.Id and rd.IsActive = 1
	INNER JOIN Receivables r ON rd.ReceivableId = r.Id and r.IsActive = 1
	INNER JOIN ReceivableCodes ON ReceivableCodes.Id = r.ReceivableCodeId and  ReceivableCodes.IsActive = 1
	INNER JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id and ReceivableTypes.IsActive = 1
	LEFT JOIN ReceivableDetailsWithholdingTaxDetails RDWHT ON RD.Id = RDWHT.ReceivableDetailId AND RDWHT.IsActive = 1

	INSERT INTO #RRDExtract
	SELECT 
		I.ReceiptId,
		SI.StatementInvoiceId AS InvoiceId,
		(rid.EffectiveBalance_Amount - ISNULL(RDWHT.EffectiveBalance_Amount, 0.00)) AS EffectiveBalance,
		rid.EffectiveTaxBalance_Amount AS EffectiveTaxBalance,
		rid.ReceivableDetailId,
		r.CustomerId AS CustomerId,
		CASE WHEN r.EntityType = 'CT' THEN r.EntityId ELSE NULL END AS ContractId,
		CASE WHEN r.EntityType = 'DT' THEN r.EntityId ELSE NULL END AS DiscountingId,
		ReceivableTypes.Id AS ReceivableTypeId,
		ReceivableTypes.[Name] AS ReceivableType,
		r.PaymentScheduleId,
		r.Id AS ReceivableId,
		rd.IsActive AS IsReceivableDetailActive,
		r.EntityType AS ReceivableEntityType,
		r.EntityId AS ReceivableEntityId,
		r.DueDate,
		r.IncomeType,
	    ReceivableInvoiceId = RID.ReceivableInvoiceId,
		rd.LeaseComponentBalance_Amount AS LeaseComponentBalance,
		rd.NonLeaseComponentBalance_Amount AS NonLeaseComponentBalance,
		rd.LeaseComponentAmount_Currency AS Currency,
		I.ReceiptAmount,
		I.InvoiceNumber,
		I.ReceivableTaxType
	FROM #InvoiceIds I 
	INNER JOIN ReceivableInvoiceStatementAssociations SI ON  I.InvoiceId = SI.StatementInvoiceId
	INNER JOIN ReceivableInvoiceDetails rid ON rid.ReceivableInvoiceId = SI.ReceivableInvoiceId and rid.IsActive = 1
	INNER JOIN ReceivableDetails rd ON rid.ReceivableDetailId = rd.Id and rd.IsActive = 1
	INNER JOIN Receivables r ON rd.ReceivableId = r.Id and r.IsActive = 1
	INNER JOIN ReceivableCodes ON ReceivableCodes.Id = r.ReceivableCodeId and  ReceivableCodes.IsActive = 1
	INNER JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id and ReceivableTypes.IsActive = 1
	LEFT JOIN ReceivableDetailsWithholdingTaxDetails RDWHT ON RD.Id = RDWHT.ReceivableDetailId AND RDWHT.IsActive = 1
	 
	DECLARE @ValidateVATInvoiceForPostByFileTable  ValidateVATInvoiceForPostByFileTable	
							  
	INSERT INTO @ValidateVATInvoiceForPostByFileTable
	SELECT DISTINCT Number, ReceivableInvoiceId, RRD.ReceiptAmount, ReceivableDetailId, RRD.ReceiptId FROM #RRDExtract RRD
	INNER JOIN ReceiptPostByFileExcel_Extract RPF ON RRD.ContractId = RPF.ComputedContractId AND RRD.ReceiptId = RPF.GroupNumber
	WHERE RPF.JobStepInstanceId = @JobStepInstanceId AND RPF.EntityType IN ('Lease', 'Loan')
	AND RRD.ReceivableTaxType = 'VAT'

	INSERT INTO @ValidateVATInvoiceForPostByFileTable
	SELECT DISTINCT Number, ReceivableInvoiceId, RRD.ReceiptAmount, ReceivableDetailId, RRD.ReceiptId FROM #RRDExtract RRD
	INNER JOIN ReceiptPostByFileExcel_Extract RPF ON RRD.CustomerId = RPF.ComputedCustomerId AND RRD.ReceiptId = RPF.GroupNumber
	WHERE RPF.JobStepInstanceId = @JobStepInstanceId AND RPF.EntityType IN ('Customer')
	AND RRD.ReceivableTaxType = 'VAT'

		EXEC ValidateVATInvoiceForPostByFile @ValidateVATInvoiceForPostByFileTable, @VATInvoiceNotFullyCleared, @VatTaxOutstandingBalanceNotCompletelyApplied, 
										 @InvoiceTaxBalanceNotClearedForReceiptBatch, @JobStepInstanceId, @IsPostingAllowed, @ReceiptBatchId

	SELECT RRD.* FROM #RRDExtract RRD
	JOIN ReceiptPostByFileExcel_Extract PBF ON RRD.InvoiceId = PBF.ComputedReceivableInvoiceId
	AND RRD.ReceiptId = PBF.GroupNumber
	WHERE PBF.JobStepInstanceId = @JobStepInstanceId AND PBF.ErrorMessage IS NULL

	IF OBJECT_ID('tempdb..#InvoiceIds') IS NOT NULL DROP TABLE #InvoiceIds
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[GetReceiptDetailsFromExtract]
(
	@JobStepInstanceId								BIGINT,
	@ReceiptIds										IdCollection READONLY
)
AS
BEGIN
	SET NOCOUNT OFF;

	--> Receipts_Extract Data
	SELECT
		 RD.Id, ReceiptId, ContractId AS ReceiptContractId, ReceiptNumber, Currency, PostDate, ReceiptClassification, LegalEntityId, LineOfBusinessId          
		,CostCenterId,InstrumentTypeId,ReceiptBatchId,IsValid,IsNewReceipt,JobStepInstanceId          
		,MaxDueDate,CashTypeId,CurrencyId,ReceiptAmount,BankAccountId,ReceiptTypeId,ReceivedDate,CheckNumber,ReceiptGLTemplateId AS GLTemplateId,EntityType
		,CustomerId,DiscountingId,DumpId,Comment,ReceiptApplicationId,ReceiptHierarchyTemplateId,Status,BankName
	FROM Receipts_Extract RD INNER JOIN @ReceiptIds R 
	ON RD.ReceiptId = R.Id AND RD.JobStepInstanceId = @JobStepInstanceId

	--> LateFeeData
	SELECT 
		RL.ReceiptId,LateFeeReceivableId,
		ReceivableId,ReceiptNumbers,InvoiceNumbers,JobStepInstanceId
	FROM ReceiptLateFeeReversalDetails_Extract  RL
	JOIN @ReceiptIds R ON RL.ReceiptId = R.Id
	AND RL.JobStepInstanceId = @JobStepInstanceId;

	SELECT	
		RA.Id AS ReceiptAllocationExtractId, ReceiptId,EntityType,AllocationAmount,
		[Description],JobStepInstanceId,LegalEntityId,ContractId, InvoiceId, IsStatementInvoiceCalculationRequired
	INTO #ReceiptAllocations
	FROM ReceiptAllocations_Extract RA INNER JOIN @ReceiptIds RD 
	ON RA.ReceiptId = RD.Id	WHERE JobStepInstanceId = @JobStepInstanceId

	--> ReceivableDetails
	;WITH StatementInvoiceMap AS(
		SELECT RA.ReceiptId, RIS.StatementInvoiceId, RIS.ReceivableInvoiceId 
		FROM #ReceiptAllocations RA 
		INNER JOIN ReceivableInvoiceStatementAssociations RIS ON RA.IsStatementInvoiceCalculationRequired=1 AND RA.InvoiceId=RIS.StatementInvoiceId
	)
	SELECT 
		RRD.Id AS ReceiptReceivableDetailsExtractId,
		RRD.ReceiptId,
		RRD.AmountApplied,
		RRD.TaxApplied,
		RRD.BookAmountApplied,
		RRD.ReceivableDetailId,
		RRD.JobStepInstanceId,
		RRD.ReceivableDetailIsActive,
		RRD.ReceivableTaxDetailIsActive,
		RRD.SequenceNumber,
		RRD.ContractId,
		RRD.DueDate,
		RRD.LegalEntityId,
		RRD.InvoiceId,
		RRD.AdjustedWithHoldingTax,
		RRD.ReceivedTowardsInterest,
		RRD.WithHoldingTaxBookAmountApplied, 
		SM.StatementInvoiceId AS StatementInvoiceId,
		RRD.LeaseComponentAmountApplied,
		RRD.NonLeaseComponentAmountApplied
	FROM ReceiptReceivableDetails_Extract RRD INNER JOIN @ReceiptIds R 
	ON RRD.ReceiptId = R.Id AND RRD.JobStepInstanceId = @JobStepInstanceId
	LEFT JOIN StatementInvoiceMap SM ON RRD.ReceiptId=SM.ReceiptId AND RRD.InvoiceId=SM.ReceivableInvoiceId

	--> StatementInvoiceAssociations
	SELECT 
		RS.Id AS ReceiptStatementInvoiceAssociationExtractId, RS.ReceiptId, RS.StatementInvoiceId, RS.JobStepInstanceId 
	FROM ReceiptStatmentInvoiceAssociations_Extract RS INNER JOIN @ReceiptIds R 
	ON RS.ReceiptId=R.Id AND RS.JobStepInstanceId=@JobStepInstanceId

	--> Allocations
	SELECT	
		ReceiptAllocationExtractId, ReceiptId,EntityType,AllocationAmount,
		[Description],JobStepInstanceId,LegalEntityId,ContractId,InvoiceId,IsStatementInvoiceCalculationRequired
	FROM #ReceiptAllocations

END

GO

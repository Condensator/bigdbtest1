SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[GetBatchReceiptsForApplyingReceiptHierarchTemplate]
(  
  @BatchCount									BIGINT  
 ,@JobStepInstanceId							BIGINT
 ,@VATInvoiceNotFullyCleared					NVARCHAR(200)
 ,@VatTaxOutstandingBalanceNotCompletelyApplied	NVARCHAR(200)
 ,@InvoiceTaxBalanceNotClearedForReceiptBatch	NVARCHAR(500)
 ,@IsPostingAllowed								BIT
 ,@ReceiptBatchId								BIGINT NULL
)  
AS  
BEGIN  

Create Table #BatchedExtract(Id BIGINT)

INSERT INTO #BatchedExtract
 SELECT TOP (@BatchCount) RE.Id  FROM
 (
	 SELECT  RE.Id
	 FROM Receipts_Extract RE
	 INNER JOIN ReceiptPostByFileExcel_Extract RPBF ON RE.ReceiptId = RPBF.GroupNumber 
	 AND RE.JobStepInstanceId = RPBF.JobStepInstanceId
	 WHERE RE.IsReceiptHierarchyProcessed is null AND RE.ReceiptHierarchyTemplateId IS NOT NULL
		AND RE.JobStepInstanceId = @JobStepInstanceId AND RPBF.CreateUnallocatedReceipt=0
		AND RPBF.HasError = 0 AND (RPBF.ComputedIsGrouped = 0 AND (RPBF.IsInvoiceInMultipleReceipts IS NULL OR RPBF.IsInvoiceInMultipleReceipts=0)
					AND RPBF.ComputedIsDSL = 0 AND RPBF.NonAccrualCategory IS NULL AND RPBF.ComputedIsFullPosting = 0)
		GROUP BY re.id 
 UNION 
	SELECT  RE.Id
	 FROM Receipts_Extract RE
	 INNER JOIN ReceiptPostByFileExcel_Extract RPBF ON RE.DumpId = RPBF.GroupNumber AND RE.ReceiptId != RPBF.GroupNumber
	 AND RE.JobStepInstanceId = RPBF.JobStepInstanceId
	 WHERE RE.IsReceiptHierarchyProcessed is null AND RE.ReceiptHierarchyTemplateId IS NOT NULL
		AND RE.JobStepInstanceId = @JobStepInstanceId AND RPBF.CreateUnallocatedReceipt=0
		AND RPBF.HasError = 0 AND (RPBF.ComputedIsGrouped = 0 AND (RPBF.IsInvoiceInMultipleReceipts IS NULL OR RPBF.IsInvoiceInMultipleReceipts=0)
		AND RPBF.ComputedIsDSL = 0 AND (RPBF.NonAccrualCategory='SingleWithRentals' AND RPBF.PayDownId IS NOT NULL) 
		AND RE.ReceiptClassification = 'Cash'
		AND RPBF.ComputedIsFullPosting = 0)
		GROUP BY re.id 
	) AS RE


 UPDATE Receipts_Extract  
 SET Receipts_Extract.IsReceiptHierarchyProcessed = 1  
 FROM #BatchedExtract INNER JOIN Receipts_Extract  
 ON #BatchedExtract.Id = Receipts_Extract.Id  
  

 SELECT re.ReceiptNumber, re.ReceiptAmount, re.Currency, re.ReceivedDate,
		re.LegalEntityId, re.LineOfBusinessId, re.CostCenterId, re.InstrumentTypeId,
		case when re.DiscountingId is null then re.ContractId
		else re.ContractId
		end as ContractId, re.DiscountingId, re.ReceiptId, re.EntityType AS ReceiptEntityType, CAST(0 AS BIT) as IsNonAccrualLoan, ReceiptHierarchyTemplateId,
	    ReceivableTaxType
 from Receipts_Extract re INNER JOIN #BatchedExtract ON re.Id = #BatchedExtract.Id 
 
SELECT ComputedReceivableInvoiceId, 
	GroupNumber, EntityType, 
	ComputedContractId, ComputedDiscountingId,
	IsApplyCredit, PayDownId,
	ReceivableTaxType  
INTO #ReceiptPostByFileExcelExtractTemp
FROM ReceiptPostByFileExcel_Extract 
WHERE JobStepInstanceId = @JobStepInstanceId 
AND ComputedIsFullPosting = 0 AND HasError = 0 
GROUP BY 
ComputedReceivableInvoiceId, GroupNumber, EntityType, ComputedContractId, 
ComputedDiscountingId,IsApplyCredit,PayDownId,ReceivableTaxType                                   
 
 SELECT re.ReceiptId as ReceiptId,
	   (rid.EffectiveBalance_Amount - ISNULL(RDWHT.EffectiveBalance_Amount, 0.00)) as EffectiveBalance,
	   rid.EffectiveTaxBalance_Amount as EffectiveTaxBalance,
	   0.00 AS EffectiveBookBalance,
       rid.ReceivableDetailId,
       rid.ReceivableInvoiceId as InvoiceId,
       r.CustomerId as CustomerId,
	   case when r.entitytype = 'CT' then r.EntityId else null end as ContractId,
	   case when r.entitytype = 'DT' then r.EntityId else null end as DiscountingId,
	   ReceivableTypes.Id as ReceivableTypeId,
	   ReceivableTypes.[Name] as ReceivableType,
		r.PaymentScheduleId,
		r.Id as ReceivableId,
		rd.IsActive as IsReceivableDetailActive,
		r.EntityType as ReceivableEntityType,
		r.EntityId as ReceivableEntityId,
		DueDate = r.DueDate,
		IncomeType = r.IncomeType,
		rid.ReceivableInvoiceId,
		rd.LeaseComponentAmount_Currency AS Currency,
		rd.LeaseComponentBalance_Amount AS LeaseComponentBalance,
		rd.NonLeaseComponentBalance_Amount AS NonLeaseComponentBalance,
		rpfe.ReceivableTaxType,
		re.ReceiptAmount,
		ri.Number,
		rpfe.GroupNumber
INTO #ReceiptReceivableDetailsExtract
FROM 
Receipts_Extract re INNER JOIN #BatchedExtract ON re.Id = #BatchedExtract.Id
INNER JOIN #ReceiptPostByFileExcelExtractTemp rpfe 
ON (rpfe.GroupNumber = re.ReceiptId OR rpfe.GroupNumber = re.DumpId)
INNER JOIN ReceivableInvoices ri ON ri.id = rpfe.ComputedReceivableInvoiceId AND ri.isactive = 1
INNER JOIN ReceivableInvoiceDetails rid ON rid.receivableInvoiceid = ri.id
INNER JOIN ReceivableDetails rd on rid.ReceivableDetailId = rd.id and rd.isactive = 1
INNER JOIN Receivables r on rd.ReceivableId = r.id and r.isactive = 1
INNER JOIN ReceivableCodes on ReceivableCodes.id = r.ReceivableCodeId and receivablecodes.isactive = 1
INNER JOIN ReceivableTypes on ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id and receivabletypes.isactive = 1
LEFT JOIN ReceivableDetailsWithholdingTaxDetails RDWHT ON RD.Id = RDWHT.ReceivableDetailId AND RDWHT.IsActive = 1
WHERE (rid.EffectiveBalance_Amount + rid.EffectiveTaxBalance_Amount > 0 OR rpfe.IsApplyCredit = 1)
AND ((rpfe.PayDownId IS NULL) OR (ReceivableTypes.[NAME]!='LoanInterest' AND ReceivableTypes.[NAME]!='LoanPrincipal'))
AND RID.EntityId = CASE WHEN rpfe.EntityType = 'Lease' OR rpfe.EntityType = 'Loan' THEN rpfe.ComputedContractId
								WHEN rpfe.EntityType = 'Discounting' THEN rpfe.ComputedDiscountingId
								ELSE RID.EntityId END
		AND RID.EntityType = CASE WHEN rpfe.EntityType = 'Lease' OR rpfe.EntityType = 'Loan' THEN 'CT'
								  WHEN rpfe.EntityType = 'Discounting' THEN 'DT'
								  ELSE RID.EntityType END


DECLARE @ValidateVATInvoiceForPostByFileTable  ValidateVATInvoiceForPostByFileTable							  
INSERT INTO @ValidateVATInvoiceForPostByFileTable
SELECT Number, ReceivableInvoiceId, ReceiptAmount, ReceivableDetailId, GroupNumber FROM #ReceiptReceivableDetailsExtract
WHERE ReceivableTaxType = 'VAT'
EXEC ValidateVATInvoiceForPostByFile @ValidateVATInvoiceForPostByFileTable, @VATInvoiceNotFullyCleared, @VatTaxOutstandingBalanceNotCompletelyApplied, 
									 @InvoiceTaxBalanceNotClearedForReceiptBatch, @JobStepInstanceId, @IsPostingAllowed, @ReceiptBatchId

SELECT RRDE.* FROM 
#ReceiptReceivableDetailsExtract RRDE
INNER JOIN #ReceiptPostByFileExcelExtractTemp RPBT ON RRDE.ReceivableInvoiceId = RPBT.ComputedReceivableInvoiceId
INNER JOIN ReceiptPostByFileExcel_Extract RPB ON RRDE.ReceivableInvoiceId = RPB.ComputedReceivableInvoiceId
AND RPB.JobStepInstanceId = @JobStepInstanceId
WHERE RPB.ErrorMessage IS NULL

DROP TABLE #BatchedExtract  
END

GO

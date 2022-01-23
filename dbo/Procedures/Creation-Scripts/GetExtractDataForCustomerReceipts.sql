SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[GetExtractDataForCustomerReceipts] 
(
	@JobStepInstanceId	BIGINT
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
		re.CustomerId,
		CEX.IsApplyCredit,
		CEX.ReceiptAmount,
		CAST(NULL AS NVARCHAR) AS ReceivableTaxType
	INTO #ReceiptExtract
	FROM Receipts_Extract re
	JOIN CommonExternalReceipt_Extract CEX ON CEX.Id = re.DumpId 
	WHERE re.JobStepInstanceId = @JobStepInstanceId
	AND CEX.CreateUnallocatedReceipt=0 AND CEX.IsValid=1

	
	SELECT  CustomerId , ReceiptId , LegalEntityId
	INTO #CustomerReceipts
	FROM #ReceiptExtract			
	WHERE ReceiptEntityType='Customer'
	 
	 
	SELECT 	
	    C.ReceiptId,
	    rid.ReceivableInvoiceId AS InvoiceId,
		(rid.EffectiveBalance_Amount - ISNULL(RDWHT.EffectiveBalance_Amount, 0.00)) AS EffectiveBalance,
		rid.EffectiveTaxBalance_Amount AS EffectiveTaxBalance,
		rid.ReceivableDetailId,
		C.CustomerId,
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
		ri.ReceivableTaxType
	INTO #CustomerReceiptDetails
	FROM #CustomerReceipts C 
	INNER JOIN ReceivableInvoices ri ON ri.CustomerId = C.CustomerId and ri.IsActive = 1
	INNER JOIN ReceivableInvoiceDetails rid ON rid.ReceivableInvoiceId = ri.Id and rid.IsActive = 1
	INNER JOIN ReceivableDetails rd ON rid.ReceivableDetailId = rd.Id and rd.IsActive = 1
	INNER JOIN Receivables r ON rd.ReceivableId = r.Id and r.IsActive = 1
	INNER JOIN ReceivableCodes ON ReceivableCodes.Id = r.ReceivableCodeId and  ReceivableCodes.IsActive = 1
	INNER JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id and ReceivableTypes.IsActive = 1
	LEFT JOIN ReceivableDetailsWithholdingTaxDetails RDWHT ON RD.Id = RDWHT.ReceivableDetailId AND RDWHT.IsActive = 1
	WHERE RI.LegalEntityId = C.LegalEntityId


	UPDATE RE
	SET RE.ReceivableTaxType = CRD.ReceivableTaxType	
	FROM #ReceiptExtract RE
	INNER JOIN #CustomerReceiptDetails CRD ON RE.ReceiptId = CRD.ReceiptId
	WHERE CRD.ReceivableTaxType = 'VAT'


	SELECT * FROM #ReceiptExtract
	SELECT * FROM #CustomerReceiptDetails

	IF OBJECT_ID('tempdb..#ReceiptExtract') IS NOT NULL DROP TABLE #ReceiptExtract
	IF OBJECT_ID('tempdb..#CustomerReceipts') IS NOT NULL DROP TABLE #CustomerReceipts
	IF OBJECT_ID('tempdb..#CustomerReceiptDetails') IS NOT NULL DROP TABLE #CustomerReceiptDetails
END

GO

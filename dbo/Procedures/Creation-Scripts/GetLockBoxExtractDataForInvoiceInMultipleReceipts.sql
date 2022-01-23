SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[GetLockBoxExtractDataForInvoiceInMultipleReceipts] 
(
	@JobStepInstanceId				BIGINT,
	@ReceivableEntityTypeValues_CT	NVARCHAR(5),
	@ReceivableEntityTypeValues_DT	NVARCHAR(5)
)
AS
BEGIN
	SET NOCOUNT OFF;

	SELECT 
		RE.ReceiptId, 
		RE.ReceiptNumber, 
		RE.Currency, 
		RE.ReceivedDate, 
		RE.LegalEntityId, 
		RE.LineOfBusinessId, 
		RE.CostCenterId, 
		RE.InstrumentTypeId, 
		RE.ContractId ,
		RE.DiscountingId, 
		RE.EntityType AS ReceiptEntityType,
		RE.ReceiptHierarchyTemplateId,
		RPBL.ReceivedAmount AS ReceiptAmount,  
		RPBL.ReceivableInvoiceId AS InvoiceId,
		RPBL.IsStatementInvoice
	FROM Receipts_Extract RE
	JOIN ReceiptPostByLockBox_Extract RPBL ON RPBL.Id = RE.DumpId AND RPBL.JobStepInstanceId = re.JobStepInstanceId AND RPBL.CreateUnallocatedReceipt=0
	WHERE re.JobStepInstanceId = @JobStepInstanceId
		AND RPBL.IsValid = 1
		AND RPBL.HasMoreInvoice = 1
		AND RPBL.IsNonAccrualLoan=0

	SELECT 
		ReceivableInvoiceId AS InvoiceId,LockBoxReceiptId
	INTO #InvoiceIds
	FROM ReceiptPostByLockBox_Extract 
	WHERE JobStepInstanceId = @JobStepInstanceId 
		AND IsValid = 1
		AND HasMoreInvoice = 1 
		AND IsNonAccrualLoan=0
		AND CreateUnallocatedReceipt=0
	 GROUP BY ReceivableInvoiceId,LockBoxReceiptId

	SELECT I.LockBoxReceiptId AS ReceiptId,
	    RID.ReceivableInvoiceId AS InvoiceId,
		RID.EffectiveBalance_Amount AS EffectiveBalance,
		RID.EffectiveTaxBalance_Amount AS EffectiveTaxBalance,
		RID.ReceivableDetailId,
		R.CustomerId AS CustomerId,
		CASE WHEN R.EntityType = @ReceivableEntityTypeValues_CT THEN R.EntityId ELSE NULL END AS ContractId,
		CASE WHEN R.EntityType = @ReceivableEntityTypeValues_DT THEN R.EntityId ELSE NULL END AS DiscountingId,
		RT.Id AS ReceivableTypeId,
		RT.Name AS ReceivableType,
		R.PaymentScheduleId,
		R.Id AS ReceivableId,
		RD.IsActive AS IsReceivableDetailActive,
		R.EntityType AS ReceivableEntityType,
		R.EntityId AS ReceivableEntityId,
		R.DueDate,
		R.IncomeType,
		RID.ReceivableInvoiceId AS ReceivableInvoiceId,
		RD.LeaseComponentBalance_Amount AS LeaseComponentBalance,
		RD.NonLeaseComponentBalance_Amount AS NonLeaseComponentBalance,
		RD.LeaseComponentAmount_Currency AS Currency
	FROM #InvoiceIds I 
	INNER JOIN ReceivableInvoices RI ON RI.Id = I.InvoiceId AND RI.IsStatementInvoice = 0
	INNER JOIN ReceivableInvoiceDetails RID ON RID.ReceivableInvoiceId = RI.Id  AND RID.IsActive =1
	INNER JOIN ReceivableDetails RD ON RID.ReceivableDetailId = RD.Id 
	INNER JOIN Receivables R ON RD.ReceivableId = R.Id 
	INNER JOIN ReceivableCodes RC ON RC.Id = R.ReceivableCodeId 
	INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id 
	UNION ALL
	SELECT I.LockBoxReceiptId AS ReceiptId,
	    SA.StatementInvoiceId AS InvoiceId,
		RID.EffectiveBalance_Amount AS EffectiveBalance,
		RID.EffectiveTaxBalance_Amount AS EffectiveTaxBalance,
		RID.ReceivableDetailId,
		R.CustomerId AS CustomerId,
		CASE WHEN R.EntityType = @ReceivableEntityTypeValues_CT THEN R.EntityId ELSE NULL END AS ContractId,
		CASE WHEN R.EntityType = @ReceivableEntityTypeValues_DT THEN R.EntityId ELSE NULL END AS DiscountingId,
		RT.Id AS ReceivableTypeId,
		RT.Name AS ReceivableType,
		R.PaymentScheduleId,
		R.Id AS ReceivableId,
		RD.IsActive AS IsReceivableDetailActive,
		R.EntityType AS ReceivableEntityType,
		R.EntityId AS ReceivableEntityId,
		R.DueDate,
		R.IncomeType,
		SA.ReceivableInvoiceId AS ReceivableInvoiceId,
		RD.LeaseComponentBalance_Amount AS LeaseComponentBalance,
		RD.NonLeaseComponentBalance_Amount AS NonLeaseComponentBalance,
		RD.LeaseComponentAmount_Currency AS Currency
	FROM #InvoiceIds I 
	INNER JOIN ReceivableInvoiceStatementAssociations SA ON I.InvoiceId = SA.StatementInvoiceId
	INNER JOIN ReceivableInvoiceDetails RID ON RID.ReceivableInvoiceId = SA.ReceivableInvoiceId  AND RID.IsActive =1
	INNER JOIN ReceivableDetails RD ON RID.ReceivableDetailId = RD.Id 
	INNER JOIN Receivables R ON RD.ReceivableId = R.Id 
	INNER JOIN ReceivableCodes RC ON RC.Id = R.ReceivableCodeId 
	INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
	
	IF OBJECT_ID('tempdb..#InvoiceIds') IS NOT NULL DROP TABLE #InvoiceIds

END

GO

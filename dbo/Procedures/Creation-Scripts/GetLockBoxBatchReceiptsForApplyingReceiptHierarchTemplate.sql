SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 
CREATE PROCEDURE [dbo].[GetLockBoxBatchReceiptsForApplyingReceiptHierarchTemplate]
(  
	@BatchCount							BIGINT,  
	@JobStepInstanceId					BIGINT,
	@ReceivableEntityTypeValues_CT		NVARCHAR(10),
	@ReceivableEntityTypeValues_DT		NVARCHAR(10)
)  
AS  
BEGIN  

	CREATE TABLE #ReceiptReceivableData(
		ReceiptId BIGINT NULL,
		EffectiveBalance DECIMAL(16,2) NULL,
		EffectiveTaxBalance DECIMAL(16,2) NULL,
		EffectiveBookBalance DECIMAL(16,2) NULL,
	    ReceivableDetailId BIGINT NULL,
	    InvoiceId BIGINT NULL,
	    CustomerId BIGINT NULL,
		ContractId BIGINT NULL,
		DiscountingId BIGINT NULL,
		ReceivableTypeId BIGINT NULL,
		ReceivableType NVARCHAR(42) NULL,
		PaymentScheduleId BIGINT NULL,
		ReceivableId BIGINT NULL,
		IsReceivableDetailActive BIT NULL,
		ReceivableEntityType NVARCHAR(4) NULL,
		ReceivableEntityId BIGINT NULL,
		DueDate DATE NULL,
		IncomeType NVARCHAR(32) NULL,
		Currency NVARCHAR(42) NULL,
		LeaseComponentBalance DECIMAL(16,2) NULL,
		NonLeaseComponentBalance DECIMAL(16,2) NULL,
	)

	SELECT 
			TOP (@BatchCount) RE.Id
	INTO #BatchedExtract
	FROM Receipts_Extract RE
	JOIN ReceiptPostByLockBox_Extract RPBL ON RPBL.Id = RE.DumpId
		AND RE.JobStepInstanceId = RPBL.JobStepInstanceId AND RPBL.CreateUnallocatedReceipt=0
	WHERE IsReceiptHierarchyProcessed IS NULL 
		AND ReceiptHierarchyTemplateId IS NOT NULL
		AND RE.JobStepInstanceId = @JobStepInstanceId 
		AND RPBL.HasMoreInvoice = 0 AND RPBL.IsValid = 1
		AND RPBL.IsNonAccrualLoan=0

	UPDATE Receipts_Extract  
		SET Receipts_Extract.IsReceiptHierarchyProcessed = 1  
	FROM #BatchedExtract 
	INNER JOIN Receipts_Extract  
	ON #BatchedExtract.Id = Receipts_Extract.Id  
	  	
	SELECT 
		RE.ReceiptId
		,RID.EffectiveBalance_Amount AS EffectiveBalance
		,RID.EffectiveTaxBalance_Amount AS EffectiveTaxBalance
		,0.00 AS EffectiveBookBalance
	    ,RID.ReceivableDetailId
	    ,RID.ReceivableInvoiceId AS InvoiceId
	    ,R.CustomerId
		,CASE WHEN R.entitytype = @ReceivableEntityTypeValues_CT THEN R.EntityId ELSE NULL END AS ContractId
		,CASE WHEN R.entitytype = @ReceivableEntityTypeValues_DT THEN R.EntityId ELSE NULL END AS DiscountingId
		,ReceivableTypes.Id AS ReceivableTypeId
		,ReceivableTypes.Name AS ReceivableType
		,R.PaymentScheduleId
		,R.Id AS ReceivableId
		,RD.IsActive AS IsReceivableDetailActive
		,R.EntityType AS ReceivableEntityType
		,R.EntityId AS ReceivableEntityId
		,R.DueDate
		,R.IncomeType
		,RPBL.ContractNumber
		,RPBL.Id ReceiptPostByLockBox_ExtractId
		,RD.LeaseComponentAmount_Currency AS Currency
		,RD.LeaseComponentBalance_Amount AS LeaseComponentBalance
		,RD.NonLeaseComponentBalance_Amount AS NonLeaseComponentBalance
	INTO #ReceiptPostByLockBox_Extract
	FROM 
	Receipts_Extract RE 
	INNER JOIN #BatchedExtract ON RE.Id = #BatchedExtract.Id
	INNER JOIN ReceiptPostByLockBox_Extract RPBL ON RPBL.LockBoxReceiptId = RE.ReceiptId and RPBL.IsValid = 1 
	INNER JOIN ReceivableInvoices RI ON RI.id = RPBL.ReceivableInvoiceId AND RI.isactive = 1
	INNER JOIN ReceivableInvoiceDetails RID ON RID.receivableInvoiceid = RI.id
	INNER JOIN ReceivableDetails RD ON RID.ReceivableDetailId = RD.id and RD.isactive = 1
	INNER JOIN Receivables R ON RD.ReceivableId = R.id and R.isactive = 1
	INNER JOIN ReceivableCodes ON ReceivableCodes.id = R.ReceivableCodeId and ReceivableCodes.isactive = 1
	INNER JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id and ReceivableTypes.isactive = 1
	WHERE RPBL.JobStepInstanceId = @JobStepInstanceId

	INSERT INTO #ReceiptReceivableData(ReceiptId, EffectiveBalance,EffectiveTaxBalance,EffectiveBookBalance,ReceivableDetailId,InvoiceId
	,CustomerId,ContractId,DiscountingId,ReceivableTypeId,ReceivableType,PaymentScheduleId,ReceivableId,IsReceivableDetailActive,ReceivableEntityType
	,ReceivableEntityId,DueDate,IncomeType,Currency,LeaseComponentBalance,NonLeaseComponentBalance)
	SELECT
		 ReceiptId
		,EffectiveBalance
		,EffectiveTaxBalance
		,EffectiveBookBalance
	    ,ReceivableDetailId
	    ,InvoiceId
	    ,CustomerId
		,ContractId
		,DiscountingId
		,ReceivableTypeId
		,ReceivableType
		,PaymentScheduleId
		,ReceivableId
		,IsReceivableDetailActive
		,ReceivableEntityType
		,ReceivableEntityId
		,DueDate
		,IncomeType
		,Currency
		,LeaseComponentBalance
		,NonLeaseComponentBalance
	FROM 
	#ReceiptPostByLockBox_Extract
	WHERE ContractNumber IS NULL OR ContractNumber = ''
	
	INSERT INTO #ReceiptReceivableData(ReceiptId, EffectiveBalance,EffectiveTaxBalance,EffectiveBookBalance,ReceivableDetailId,InvoiceId
	,CustomerId,ContractId,DiscountingId,ReceivableTypeId,ReceivableType,PaymentScheduleId,ReceivableId,IsReceivableDetailActive,ReceivableEntityType
	,ReceivableEntityId,DueDate,IncomeType,Currency,LeaseComponentBalance,NonLeaseComponentBalance)
	SELECT
		 ReceiptId
		,EffectiveBalance
		,EffectiveTaxBalance
		,EffectiveBookBalance
	    ,ReceivableDetailId
	    ,InvoiceId
	    ,RPBLT.CustomerId
		,RPBLT.ContractId
		,RPBLT.DiscountingId
		,ReceivableTypeId
		,ReceivableType
		,PaymentScheduleId
		,ReceivableId
		,IsReceivableDetailActive
		,ReceivableEntityType
		,ReceivableEntityId
		,DueDate
		,IncomeType
		,RPBLT.Currency
		,LeaseComponentBalance
		,NonLeaseComponentBalance
	FROM 
	#ReceiptPostByLockBox_Extract RPBLT
	JOIN ReceiptPostByLockBox_Extract RPBL ON RPBLT.ReceiptPostByLockBox_ExtractId = RPBL.Id
	WHERE ReceivableEntityType = @ReceivableEntityTypeValues_CT AND RPBL.ContractNumber IS NOT NULL AND RPBL.ContractNumber != '' AND 
	(RPBL.IsValidContract = 0 OR RPBL.IsInvoiceContractAssociated = 0 OR (RPBL.ContractId = RPBLT.ContractId))
	
	INSERT INTO #ReceiptReceivableData(ReceiptId, EffectiveBalance,EffectiveTaxBalance,EffectiveBookBalance,ReceivableDetailId,InvoiceId
	,CustomerId,ContractId,DiscountingId,ReceivableTypeId,ReceivableType,PaymentScheduleId,ReceivableId,IsReceivableDetailActive,ReceivableEntityType
	,ReceivableEntityId,DueDate,IncomeType,Currency,LeaseComponentBalance,NonLeaseComponentBalance)
	SELECT
		 ReceiptId
		,EffectiveBalance
		,EffectiveTaxBalance
		,EffectiveBookBalance
	    ,ReceivableDetailId
	    ,InvoiceId
	    ,RPBLT.CustomerId
		,RPBLT.ContractId
		,RPBLT.DiscountingId
		,ReceivableTypeId
		,ReceivableType
		,PaymentScheduleId
		,ReceivableId
		,IsReceivableDetailActive
		,ReceivableEntityType
		,ReceivableEntityId
		,DueDate
		,IncomeType
		,RPBLT.Currency
		,LeaseComponentBalance
		,NonLeaseComponentBalance
	FROM 
	#ReceiptPostByLockBox_Extract RPBLT
	JOIN ReceiptPostByLockBox_Extract RPBL ON RPBLT.ReceiptPostByLockBox_ExtractId = RPBL.Id
	WHERE ReceivableEntityType = @ReceivableEntityTypeValues_DT AND RPBL.ContractNumber IS NOT NULL AND RPBL.ContractNumber != '' AND 
	(RPBL.IsValidContract = 0 OR RPBL.IsInvoiceContractAssociated = 0 OR (RPBL.DiscountingId = RPBLT.DiscountingId))

	SELECT
		 RE.ReceiptNumber
		,RE.ReceiptAmount
		,RE.Currency
		,RE.ReceivedDate
		,RE.LegalEntityId
		,RE.LineOfBusinessId
		,RE.CostCenterId
		,RE.InstrumentTypeId
		,CASE WHEN RE.DiscountingId IS NULL THEN RE.ContractId ELSE RE.ContractId END AS ContractId
		,RE.DiscountingId
		,RE.ReceiptId
		,RE.EntityType
		,CAST(0 AS BIT) AS IsNonAccrualLoan
		,ReceiptHierarchyTemplateId
	FROM Receipts_Extract RE 
	INNER JOIN #BatchedExtract ON RE.Id = #BatchedExtract.Id

	SELECT ReceiptId, EffectiveBalance,EffectiveTaxBalance,EffectiveBookBalance,ReceivableDetailId,InvoiceId
	,CustomerId,ContractId,DiscountingId,ReceivableTypeId,ReceivableType,PaymentScheduleId,ReceivableId,IsReceivableDetailActive,ReceivableEntityType
	,ReceivableEntityId,DueDate,IncomeType,Currency,LeaseComponentBalance,NonLeaseComponentBalance, InvoiceId AS ReceivableInvoiceId
	FROM #ReceiptReceivableData

	DROP TABLE #BatchedExtract  
	DROP TABLE #ReceiptPostByLockBox_Extract
	DROP TABLE #ReceiptReceivableData
END  

GO

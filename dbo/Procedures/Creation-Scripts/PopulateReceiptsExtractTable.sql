SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[PopulateReceiptsExtractTable]  
(  
 @JobStepInstanceId  BIGINT,
 @CreatedById BIGINT,
 @CreatedTime DATETIMEOFFSET,
 @ContractTypeValues_Lease NVARCHAR(20),
 @ContractTypeValues_Loan NVARCHAR(20),
 @ReceivableEntityTypeValues_CT NVARCHAR(20),
 @IncomeTypeValues_None NVARCHAR(20),
 @ReceivableTypeValues_Sundry NVARCHAR(20),
 @ReceivableTypeValues_SundrySeparate NVARCHAR(20),
 @ReceivableTypeValues_SecurityDeposit NVARCHAR(20),
 @ReceivableTypeValues_InsurancePremiumAdmin NVARCHAR(20),
 @ReceivableTypeValues_InsurancePremium NVARCHAR(20),
 @ReceivableTypeValues_CPIBaseRental NVARCHAR(20),
 @ReceivableTypeValues_CPIOverage NVARCHAR(20),
 @ReceivableTypeValues_PropertyTaxEscrow NVARCHAR(20),
 @ReceivableTypeValues_PropertyTax NVARCHAR(20),
 @ReceivableTypeValues_Scrape NVARCHAR(20),
 @ReceivableTypeValues_LeasePayOff NVARCHAR(20),
 @ReceivableTypeValues_BuyOut NVARCHAR(20),
 @ReceivableTypeValues_AssetSale NVARCHAR(20),
 @ReceivableTypeValues_LeaseInterimInterest NVARCHAR(20),
 @ReceivableTypeValues_InterimRental NVARCHAR(20),
 @ReceivableTypeValues_CapitalLeaseRental NVARCHAR(20),
 @ReceivableTypeValues_OperatingLeaseRental NVARCHAR(20),
 @ReceivableTypeValues_LeaseFloatRateAdj NVARCHAR(20),
 @ReceivableTypeValues_LeveragedLeaseRental NVARCHAR(20),
 @ReceivableTypeValues_OverTermRental NVARCHAR(20),
 @ReceivableTypeValues_Supplemental NVARCHAR(20),
 @LegalEntityStatusValues_Inactive NVARCHAR(20),
 @ContractStatusValues_Commenced NVARCHAR(20),
 @ContractStatusValues_Uncommenced NVARCHAR(20),
 @ReceiptClassificationValues_Cash NVARCHAR(20),
 @AllowCashPostingAcrossCustomers	BIT,
 @ReceivableTypeValues_LoanInterest NVARCHAR(20),
 @ReceivableTypeValues_LoanPrincipal NVARCHAR(20),
 @ReceivableIncomeTypeValues_InterimInterest NVARCHAR(20),
 @ReceivableIncomeTypeValues_TakeDownInterest NVARCHAR(20)
 -- @ProcessedRecords BIGINT OUTPUT,  
-- @FailedRecords BIGINT OUTPUT   
)
AS  

BEGIN

DECLARE @RoundingValue DECIMAL(16,2) = 0.01;
DECLARE @TotalValidRecordsCount BIGINT;  
SELECT @TotalValidRecordsCount= IsNull(COUNT(Id), 0) from ReceiptMigration_Extract where IsValid=1 AND JobStepInstanceId = @JobStepInstanceId
PRINT CAST(@TotalValidRecordsCount AS NVARCHAR(10)) + ' receipts will be moved to receipts extract table'

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


IF(@TotalValidRecordsCount>0)
BEGIN
-- BEGIN Receipts_Extract 
INSERT INTO [dbo].[Receipts_Extract]
           ([ReceiptId]           
		   ,[CreatedById]           
		   ,[CreatedTime]          
		   ,[UpdatedById]           
		   ,[UpdatedTime]           
		   ,[ReceiptNumber]           
		   ,[Currency]           
		   ,[PostDate]           
		   ,[ReceivedDate]
           ,[ReceiptClassification]          
		   ,[LegalEntityId]       
		   ,[LineOfBusinessId]   
		   ,[CostCenterId]       
		   ,[InstrumentTypeId]   
		   ,[BranchId]   
		   ,[ContractId]    
		   ,[DiscountingId]
           ,[ReceiptBatchId]   
		   ,[IsValid]     
		   ,[JobStepInstanceId]   
		   ,[DumpId]      
		   ,[IsNewReceipt]      
		   ,[MaxDueDate]       
		   ,[ContractLegalEntityId]     
		   ,[AcquisitionId]   
		   ,[EntityType]
           ,[ReceiptGLTemplateId]    
		   ,[CustomerId]      
		   ,[ReceiptAmount]      
		   ,[BankAccountId]      
		   ,[ReceiptApplicationId]     
		   ,[UnallocatedDescription]     
		   ,[DealProductTypeId]
           ,[CurrencyId]      
		   ,[LegalEntityHierarchyTemplateId]      
		   ,[ContractHierarchyTemplateId]      
		   ,[CustomerHierarchyTemplateId]     
		   ,[ContractLegalEntityHierarchyTemplateId]
           ,[ReceiptHierarchyTemplateId]     
		   ,[IsReceiptHierarchyProcessed]
		   ,[CashTypeId]
		   ,[ReceiptTypeId]
		   ,[CheckNumber]
		   ,[Comment]
		   ,[BankName])
(SELECT (RME.ReceiptMigrationId * -1) AS ReceiptId
	,RME.CreatedById  AS  CreatedById
	,RME.CreatedTime AS CreatedByTime
	,RME.UpdatedById AS UpdatedById
	,RME.UpdatedTime AS UpdatedByTime
	,NULL AS ReceiptNumber
	,RME.CurrencyCode  AS Currency
	,RME.PostDate AS PostDate
	,RME.ReceivedDate AS ReceivedDate
	,@ReceiptClassificationValues_Cash AS ReceiptClassification
	,LE.Id AS LegalEntityId
	,C.LineofBusinessId  AS LineOfBusinessId
	,C.CostCenterId AS CostCenterId
	,LF.InstrumentTypeId AS InstrumentTypeId
	,NULL AS BranchId
	,C.Id AS ContractId
	,NULL AS DicoutingId
	,NULL AS [ReceiptBatchId]
	,RME.IsValid,@JobStepInstanceId AS [JobStepInstanceId]
	,RME.ReceiptMigrationId AS [DumpId]
	,1 AS [IsNewReceipt]
	,NULL AS [MaxDueDate]
	,LF.LegalEntityId AS [ContractLegalEntityId]
	,LF.AcquisitionId AS [AcquisitionId]
	,C.ContractType
	,GLT.Id AS [ReceiptGLTemplateId]
	,LF.CustomerId,RME.ReceiptAmount_Amount
	,BA.Id AS [BankAccountId]
	,NULL AS [ReceiptApplicationId]
	,NULL AS [UnallocatedDescription]
	,C.DealProductTypeId
	,CC.Id [CurrencyId]
	,NULL [LegalEntityHierarchyTemplateId]
	,NULL [ContractHierarchyTemplateId]
	,NULL [CustomerHierarchyTemplateId]
	,NULL [ContractLegalEntityHierarchyTemplateId]
	,NULL [ReceiptHierarchyTemplateId]
	,0 [IsReceiptHierarchyProcessed]
	,CT.Id
	,RCTT.Id
	,RME.CheckNumber
	,RME.Comment
	,RME.BankName AS [BankName]
FROM ReceiptMigration_Extract RME 
JOIN Contracts C ON RME.ContractSequenceNumber=C.SequenceNumber AND C.ContractType=@ContractTypeValues_Lease AND RME.JobStepInstanceId = @JobStepInstanceId
JOIN LeaseFinances LF ON C.Id=LF.ContractId  AND LF.IsCurrent=1
JOIN LegalEntities LE ON RME.LegalEntityNumber=LE.LegalEntityNumber
JOIN GLTemplates GLT ON RME.ReceiptGLTemplateName=GLT.[Name] AND LE.GLConfigurationId = GLT.GLConfigurationId
JOIN LegalEntityBankAccounts LEBA ON LE.Id=LEBA.LegalEntityId
JOIN Currencies CC ON RME.CurrencyCode=CC.[Name]
JOIN BankAccounts BA ON LEBA.BankAccountId=BA.Id AND  BA.LegalEntityAccountNumber = RME.BankAccountNumber AND BA.IsActive = 1
JOIN BankBranches BB ON BA.BankBranchId=BB.ID AND  BB.[BankName] = RME.[BankAccountBankName] AND BB.[Name]=RME.[BankAccountBranchName]
LEFT JOIN CashTypes CT ON RME.CashTypeName=CT.[Type]
LEFT JOIN ReceiptTypes RCTT ON RME.ReceiptTypeName=RCTT.ReceiptTypeName
WHERE RME.IsValid=1 AND RME.IsProcessed = 0 AND (BA.CurrencyId IS NULL OR CC.Id=BA.CurrencyId)
UNION ALL
SELECT (RME.ReceiptMigrationId * -1) AS ReceiptId
	,RME.CreatedById  AS  CreatedById
	,RME.CreatedTime AS CreatedByTime
	,RME.UpdatedById AS UpdatedById
	,RME.UpdatedTime AS UpdatedByTime
	,NULL AS ReceiptNumber
	,RME.CurrencyCode  AS Currency
	,RME.PostDate AS PostDate
	,RME.ReceivedDate AS ReceivedDate
	,@ReceiptClassificationValues_Cash AS ReceiptClassification
	,LE.Id AS LegalEntityId
	,C.LineofBusinessId  AS LineOfBusinessId
	,C.CostCenterId AS CostCenterId
	,LF.InstrumentTypeId AS InstrumentTypeId
	,NULL AS BranchId
	,C.Id AS ContractId
	,NULL AS DicoutingId
	,NULL AS [ReceiptBatchId]
	,RME.IsValid,@JobStepInstanceId AS [JobStepInstanceId]
	,RME.ReceiptMigrationId AS [DumpId]
	,1 AS [IsNewReceipt]
	,NULL AS [MaxDueDate]
	,LF.LegalEntityId AS [ContractLegalEntityId]
	,LF.AcquisitionId AS [AcquisitionId]
	,C.ContractType
	,GLT.Id AS [ReceiptGLTemplateId]
	,LF.CustomerId,RME.ReceiptAmount_Amount
	,BA.Id AS [BankAccountId]
	,NULL AS [ReceiptApplicationId]
	,NULL AS [UnallocatedDescription]
	,C.DealProductTypeId
	,CC.Id [CurrencyId]
	,NULL [LegalEntityHierarchyTemplateId]
	,NULL [ContractHierarchyTemplateId]
	,NULL [CustomerHierarchyTemplateId]
	,NULL [ContractLegalEntityHierarchyTemplateId]
	,NULL [ReceiptHierarchyTemplateId]
	,0 [IsReceiptHierarchyProcessed]
	,CT.Id
	,RCTT.Id
	,RME.CheckNumber
	,RME.Comment
	,RME.BankName AS [BankName]
FROM ReceiptMigration_Extract RME 
JOIN Contracts C ON RME.ContractSequenceNumber=C.SequenceNumber  AND C.ContractType=@ContractTypeValues_Loan AND RME.JobStepInstanceId = @JobStepInstanceId
JOIN LoanFinances LF ON C.Id=LF.ContractId AND LF.IsCurrent=1
JOIN LegalEntities LE ON RME.LegalEntityNumber=LE.LegalEntityNumber
JOIN GLTemplates GLT ON RME.ReceiptGLTemplateName=GLT.[Name] AND LE.GLConfigurationId = GLT.GLConfigurationId
JOIN LegalEntityBankAccounts LEBA ON LE.Id=LEBA.LegalEntityId
JOIN Currencies CC ON RME.CurrencyCode=CC.[Name]
JOIN BankAccounts BA ON LEBA.BankAccountId=BA.Id AND  BA.LegalEntityAccountNumber = RME.BankAccountNumber AND BA.IsActive = 1
JOIN BankBranches BB ON BA.BankBranchId=BB.ID AND  BB.[BankName] = RME.[BankAccountBankName] AND BB.[Name]=RME.[BankAccountBranchName]
LEFT JOIN CashTypes CT ON RME.CashTypeName=CT.[Type]
LEFT JOIN ReceiptTypes RCTT ON RME.ReceiptTypeName=RCTT.ReceiptTypeName
WHERE RME.IsValid=1 AND RME.IsProcessed != 1 AND (BA.CurrencyId IS NULL OR CC.Id=BA.CurrencyId))

-- END Receipts_Extract 

-- BEGIN Receivable Details Extract
INSERT INTO [dbo].[ReceiptDetailsMigration_Extract]
           ([ReceiptId]
           ,[CreatedById]
           ,[CreatedTime]
           ,[EffectiveBalance_Amount]
           ,[EffectiveTaxBalance_Amount]
           ,[ReceivableDetailId]
           ,[JobStepInstanceId]
           ,[ReceivableId]
           ,[ReceivableTaxId]
           ,[ReceivableTaxDetailId]
           ,[ReceivableDetailIsActive]
           ,[ContractId]
           ,[InvoiceId]
           ,[DiscountingId]
           ,[ReceiptApplicationReceivableDetailId]
           ,[DumpId]
           ,[PrevAmountAppliedForReApplication_Amount]
           ,[PrevBookAmountAppliedForReApplication_Amount]
           ,[PrevTaxAppliedForReApplication_Amount]
           ,[IsReApplication]
           ,[InvoiceBalance_Amount_Amount])
SELECT   
   RRDME.ReceiptMigrationId AS ReceiptId  
    ,@CreatedById AS CreatedById   
    ,@CreatedTime AS CreatedTime 
	,ISNULL(RD.EffectiveBalance_Amount,0.00) AS  ReceivableDetailEffectiveBalance
	,SUM(ISNULL(RTXD.EffectiveBalance_Amount,0.00)) AS ReceivableDetailTaxEffectiveBalance
   ,RD.Id AS ReceivableDetailId
   ,@JobStepInstanceId  AS JobStepInstanceId
   ,R.Id AS ReceivableId
   ,RTX.Id AS ReceivableTaxId
   ,RTXD.Id AS   ReceivableTaxDetailId
   ,1 AS ReceivableDetailIsActive  
   ,C.Id AS ContractId  
   ,RI.Id AS InvoiceId  
   ,NULL AS DiscountingId  
   ,0 AS ReceiptApplicationReceivableDetailId  
   ,RRDME.ReceiptMigrationId AS DumpId  
   ,0.00 AS PrevAmountAppliedForReApplication  
   ,0.00 AS PrevBookAmountAppliedForReApplication  
   ,0.00 AS PrevTaxAppliedForReApplication  
   ,0 AS IsReApplication
   ,RI.Balance_Amount AS InvoiceBalance
   FROM Receivables R  
   INNER JOIN ReceivableDetails RD ON R.Id=RD.ReceivableId  
   INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId=RC.Id
   INNER JOIN GLTemplates GLT ON RC.GLTemplateId=GLT.Id
   INNER JOIN GLTransactionTypes GLTT ON GLT.GLTransactionTypeId=GLTT.Id
   INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId=RT.Id
   INNER JOIN Contracts C ON R.EntityId = C.Id AND R.EntityType=@ReceivableEntityTypeValues_CT AND C.ContractType=@ContractTypeValues_Lease 
   AND C.SequenceNumber IS NOT NULL
   INNER JOIN ReceiptMigration_Extract RME ON C.SequenceNumber=RME.ContractSequenceNumber AND RME.JobStepInstanceId = @JobStepInstanceId
   INNER JOIN ReceiptReceivableDetailMigration_Extract RRDME ON RME.ReceiptMigrationId=RRDME.ReceiptMigrationId AND RRDME.JobStepInstanceId = @JobStepInstanceId
   AND R.DueDate = RRDME.DueDate AND RT.Name = RRDME.ReceivableType
   INNER JOIN LeaseFinances LF ON C.Id=LF.ContractId AND LF.IsCurrent=1
   LEFT JOIN ReceivableTaxes RTX ON R.Id = RTX.ReceivableId  
   LEFT JOIN ReceivableTaxDetails RTXD ON RD.Id=RTXD.ReceivableDetailId  
   LEFT JOIN ReceivableInvoiceDetails RID ON RD.Id=RID.ReceivableDetailId AND RID.IsActive = 1
   LEFT JOIN ReceivableInvoices RI ON RID.ReceivableInvoiceId=RI.Id AND RI.IsActive = 1
   INNER JOIN LeasePaymentSchedules LPS ON R.PaymentScheduleId = LPS.Id 
   AND LPS.PaymentType = RRDME.PaymentType AND LPS.PaymentNumber=RRDME.PaymentNumber

   WHERE RD.IsActive=1  AND RME.IsValid=1  AND RME.IsProcessed != 1
   AND ((RD.EffectiveBalance_Amount + ISNULL(RTXD.EffectiveBalance_Amount,0.00)) != 0.00)
   AND RT.[Name] IN (
					@ReceivableTypeValues_LeaseInterimInterest,
					@ReceivableTypeValues_InterimRental,
					@ReceivableTypeValues_CapitalLeaseRental,
					@ReceivableTypeValues_OperatingLeaseRental,
					@ReceivableTypeValues_LeaseFloatRateAdj,
					@ReceivableTypeValues_LeveragedLeaseRental,
					@ReceivableTypeValues_OverTermRental,
					@ReceivableTypeValues_Supplemental,
					@ReceivableTypeValues_CPIOverage)
   GROUP BY RRDME.ReceiptMigrationId,C.Id,R.Id,RD.Id,RD.EffectiveBalance_Amount,RD.EffectiveBookBalance_Amount,RTX.Id,RTXD.Id ,RTXD.EffectiveBalance_Amount,RI.Id,RI.Balance_Amount
UNION ALL
SELECT   
   RRDME.ReceiptMigrationId AS ReceiptId  
    ,@CreatedById AS CreatedById   
    ,@CreatedTime AS CreatedTime 
	,ISNULL(RD.EffectiveBalance_Amount,0.00) AS  ReceivableDetailEffectiveBalance
	,SUM(ISNULL(RTXD.EffectiveBalance_Amount,0.00)) AS ReceivableDetailTaxEffectiveBalance
   ,RD.Id AS ReceivableDetailId
   ,@JobStepInstanceId  AS JobStepInstanceId
   ,R.Id AS ReceivableId
   ,RTX.Id AS ReceivableTaxId
   ,RTXD.Id AS   ReceivableTaxDetailId
   ,1 AS ReceivableDetailIsActive  
   ,C.Id AS ContractId  
   ,RI.Id AS InvoiceId  
   ,NULL AS DiscountingId  
   ,0 AS ReceiptApplicationReceivableDetailId  
   ,RRDME.ReceiptMigrationId AS DumpId  
   ,0.00 AS PrevAmountAppliedForReApplication  
   ,0.00 AS PrevBookAmountAppliedForReApplication  
   ,0.00 AS PrevTaxAppliedForReApplication  
   ,0 AS IsReApplication
   ,RI.Balance_Amount AS InvoiceBalance
   FROM Receivables R  
   INNER JOIN ReceivableDetails RD ON R.Id=RD.ReceivableId  
   INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId=RC.Id
   INNER JOIN GLTemplates GLT ON RC.GLTemplateId=GLT.Id
   INNER JOIN GLTransactionTypes GLTT ON GLT.GLTransactionTypeId=GLTT.Id
   INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId=RT.Id
   INNER JOIN Contracts C ON R.EntityId = C.Id AND R.EntityType=@ReceivableEntityTypeValues_CT AND C.ContractType=@ContractTypeValues_Lease 
   AND C.SequenceNumber IS NOT NULL
   INNER JOIN ReceiptMigration_Extract RME ON C.SequenceNumber=RME.ContractSequenceNumber AND RME.JobStepInstanceId = @JobStepInstanceId
   INNER JOIN ReceiptReceivableDetailMigration_Extract RRDME ON RME.ReceiptMigrationId=RRDME.ReceiptMigrationId AND RRDME.JobStepInstanceId = @JobStepInstanceId
   AND R.DueDate = RRDME.DueDate AND RT.Name = RRDME.ReceivableType
   INNER JOIN LeaseFinances LF ON C.Id=LF.ContractId AND LF.IsCurrent=1
   LEFT JOIN ReceivableTaxes RTX ON R.Id = RTX.ReceivableId  
   LEFT JOIN ReceivableTaxDetails RTXD ON RD.Id=RTXD.ReceivableDetailId  
   LEFT JOIN ReceivableInvoiceDetails RID ON RD.Id=RID.ReceivableDetailId AND RID.IsActive = 1
   LEFT JOIN ReceivableInvoices RI ON RID.ReceivableInvoiceId=RI.Id AND RI.IsActive = 1
   INNER JOIN CPUPaymentSchedules LPS ON R.PaymentScheduleId = LPS.Id 
   AND LPS.PaymentType = RRDME.PaymentType AND LPS.PaymentNumber=RRDME.PaymentNumber

   WHERE RD.IsActive=1  AND RME.IsValid=1  AND RME.IsProcessed != 1
   AND ((RD.EffectiveBalance_Amount + ISNULL(RTXD.EffectiveBalance_Amount,0.00)) != 0.00)
   AND RT.[Name] = @ReceivableTypeValues_CPIBaseRental

   GROUP BY RRDME.ReceiptMigrationId,C.Id,R.Id,RD.Id,RD.EffectiveBalance_Amount,RD.EffectiveBookBalance_Amount,RTX.Id,RTXD.Id ,RTXD.EffectiveBalance_Amount,RI.Id,RI.Balance_Amount
UNION ALL
SELECT   
   RRDME.ReceiptMigrationId AS ReceiptId  
    ,@CreatedById AS CreatedById   
    ,@CreatedTime AS CreatedTime 
	,ISNULL(RD.EffectiveBalance_Amount,0.00) AS  ReceivableDetailEffectiveBalance
	,SUM(ISNULL(RTXD.EffectiveBalance_Amount,0.00)) AS ReceivableDetailTaxEffectiveBalance
   ,RD.Id AS ReceivableDetailId
   ,@JobStepInstanceId  AS JobStepInstanceId
   ,R.Id AS ReceivableId
   ,RTX.Id AS ReceivableTaxId
   ,RTXD.Id AS   ReceivableTaxDetailId
   ,1 AS ReceivableDetailIsActive  
   ,C.Id AS ContractId  
   ,RI.Id AS InvoiceId  
   ,NULL AS DiscountingId  
   ,0 AS ReceiptApplicationReceivableDetailId  
   ,RRDME.ReceiptMigrationId AS DumpId  
   ,0.00 AS PrevAmountAppliedForReApplication  
   ,0.00 AS PrevBookAmountAppliedForReApplication  
   ,0.00 AS PrevTaxAppliedForReApplication  
   ,0 AS IsReApplication
   ,RI.Balance_Amount AS InvoiceBalance
   FROM Receivables R  
   INNER JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId 
   INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId=RC.Id
   INNER JOIN GLTemplates GLT ON RC.GLTemplateId=GLT.Id
   INNER JOIN GLTransactionTypes GLTT ON GLT.GLTransactionTypeId=GLTT.Id
   INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId=RT.Id 
   INNER JOIN Contracts C ON R.EntityId = C.Id AND R.EntityType=@ReceivableEntityTypeValues_CT AND C.ContractType=@ContractTypeValues_Loan 
   AND C.SequenceNumber IS NOT NULL
   INNER JOIN ReceiptMigration_Extract RME ON C.SequenceNumber=RME.ContractSequenceNumber AND RME.JobStepInstanceId = @JobStepInstanceId
   INNER JOIN ReceiptReceivableDetailMigration_Extract RRDME ON RME.ReceiptMigrationId=RRDME.ReceiptMigrationId AND RRDME.JobStepInstanceId = @JobStepInstanceId
   AND R.DueDate = RRDME.DueDate AND RT.Name = RRDME.ReceivableType
   INNER JOIN LoanFinances LF ON C.Id=LF.ContractId AND LF.IsCurrent=1
   LEFT JOIN ReceivableTaxes RTX ON R.Id = RTX.ReceivableId  
   LEFT JOIN ReceivableTaxDetails RTXD ON RD.Id=RTXD.ReceivableDetailId
   LEFT JOIN ReceivableInvoiceDetails RID ON RD.Id=RID.ReceivableDetailId AND RID.IsActive = 1
   LEFT JOIN ReceivableInvoices RI ON RID.ReceivableInvoiceId=RI.Id AND RI.IsActive = 1
   INNER JOIN LoanPaymentSchedules LPS ON R.PaymentScheduleId = LPS.Id 
   AND LPS.PaymentType = RRDME.PaymentType
   AND LPS.PaymentNumber=RRDME.PaymentNumber
   WHERE RD.IsActive=1  AND RME.IsValid=1 AND RME.IsProcessed != 1
   AND ((RD.EffectiveBalance_Amount + ISNULL(RTXD.EffectiveBalance_Amount,0.00)) != 0.00)
      AND RT.[Name] IN (
					@ReceivableTypeValues_LoanInterest,
					@ReceivableTypeValues_LoanPrincipal)

    GROUP BY RRDME.ReceiptMigrationId,C.Id,R.Id,RD.Id,RD.EffectiveBalance_Amount,RD.EffectiveBookBalance_Amount,RTX.Id,RTXD.Id ,RTXD.EffectiveBalance_Amount,RI.Id,RI.Balance_Amount
   UNION ALL
   SELECT 
   RRDME.ReceiptMigrationId AS ReceiptId  
    ,@CreatedById AS CreatedById   
    ,@CreatedTime AS CreatedTime 
	,ISNULL(RD.EffectiveBalance_Amount,0.00) AS  ReceivableDetailEffectiveBalance
	,SUM(ISNULL(RTXD.EffectiveBalance_Amount,0.00)) AS ReceivableDetailTaxEffectiveBalance
   ,RD.Id AS ReceivableDetailId
   ,@JobStepInstanceId  AS JobStepInstanceId
   ,R.Id AS ReceivableId
   ,RTX.Id AS ReceivableTaxId
   ,0 AS ReceivableTaxDetailId
   ,1 AS ReceivableDetailIsActive  
   ,C.Id AS ContractId  
   ,RI.Id AS InvoiceId  
   ,NULL AS DiscountingId  
   ,0 AS ReceiptApplicationReceivableDetailId  
   ,RRDME.ReceiptMigrationId AS DumpId  
   ,0.00 AS PrevAmountAppliedForReApplication  
   ,0.00 AS PrevBookAmountAppliedForReApplication  
   ,0.00 AS PrevTaxAppliedForReApplication  
   ,0 AS IsReApplication
   ,RI.Balance_Amount AS InvoiceBalance
   FROM Receivables R  
   INNER JOIN ReceivableDetails RD ON R.Id=RD.ReceivableId  
   INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId=RC.Id
   INNER JOIN GLTemplates GLT ON RC.GLTemplateId=GLT.Id
   INNER JOIN GLTransactionTypes GLTT ON GLT.GLTransactionTypeId=GLTT.Id
   INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId=RT.Id 
   INNER JOIN Contracts C ON R.EntityId = C.Id 
   AND C.SequenceNumber IS NOT NULL
   INNER JOIN ReceiptMigration_Extract RME ON C.SequenceNumber=RME.ContractSequenceNumber AND RME.JobStepInstanceId = @JobStepInstanceId
   INNER JOIN ReceiptReceivableDetailMigration_Extract RRDME ON RME.ReceiptMigrationId=RRDME.ReceiptMigrationId 
   AND R.DueDate = RRDME.DueDate  AND RT.Name = RRDME.ReceivableType AND RRDME.JobStepInstanceId = @JobStepInstanceId
   AND RRDME.ReceivableType IN (@ReceivableTypeValues_Sundry,@ReceivableTypeValues_SecurityDeposit,@ReceivableTypeValues_InsurancePremium,@ReceivableTypeValues_InsurancePremiumAdmin
   ,@ReceivableTypeValues_SundrySeparate,@ReceivableTypeValues_CPIOverage,@ReceivableTypeValues_PropertyTaxEscrow,@ReceivableTypeValues_PropertyTax,@ReceivableTypeValues_Scrape
   ,@ReceivableTypeValues_LeasePayOff,@ReceivableTypeValues_BuyOut,@ReceivableTypeValues_AssetSale)
   LEFT JOIN ReceivableTaxes RTX ON R.Id = RTX.ReceivableId  
   LEFT JOIN ReceivableTaxDetails RTXD ON RD.Id=RTXD.ReceivableDetailId 
   LEFT JOIN ReceivableInvoiceDetails RID ON RD.Id=RID.ReceivableDetailId AND RID.IsActive = 1
   LEFT JOIN ReceivableInvoices RI ON RID.ReceivableInvoiceId=RI.Id AND RI.IsActive = 1
   WHERE RD.IsActive=1  AND R.IncomeType=@IncomeTypeValues_None
   AND RME.IsValid=1   AND RME.IsProcessed != 1 
   AND ((RD.EffectiveBalance_Amount + ISNULL(RTXD.EffectiveBalance_Amount,0.00)) != 0.00)
    GROUP BY RRDME.ReceiptMigrationId,C.Id,R.Id,RD.Id,RD.EffectiveBalance_Amount,RD.EffectiveBookBalance_Amount,RTX.Id,RI.Id,RI.Balance_Amount

	SELECT * 
	INTO #ReceivableDetailsForReceiptMigration
	FROM 
	(
	SELECT   
   RRDME.ReceiptMigrationId AS ReceiptId  
   ,ISNULL(RD.EffectiveBalance_Amount,0.00) AS EffectiveBalance  
   ,ISNULL(RTXD.EffectiveBalance_Amount,0.00) AS EffectiveTaxBalance  
   ,RD.Id AS ReceivableDetailId  
   ,@JobStepInstanceId  AS JobStepInstanceId  
   ,R.Id AS ReceivableId
   ,RTX.Id AS ReceivableTaxId
   ,RTXD.Id AS ReceivableTaxDetailId
   ,ISNULL(RD.LeaseComponentBalance_Amount,0.00) AS LeaseComponentBalance
   ,ISNULL(RD.NonLeaseComponentBalance_Amount,0.00) AS NonLeaseComponentBalance
   FROM Receivables R  
   INNER JOIN ReceivableDetails RD ON R.Id=RD.ReceivableId   
   INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId=RC.Id
   INNER JOIN GLTemplates GLT ON RC.GLTemplateId=GLT.Id
   INNER JOIN GLTransactionTypes GLTT ON GLT.GLTransactionTypeId=GLTT.Id
   INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId=RT.Id  
   INNER JOIN Contracts C ON R.EntityId = C.Id AND R.EntityType=@ReceivableEntityTypeValues_CT AND C.ContractType=@ContractTypeValues_Lease 
   AND C.SequenceNumber IS NOT NULL
   INNER JOIN ReceiptMigration_Extract RME ON C.SequenceNumber=RME.ContractSequenceNumber AND RME.JobStepInstanceId = @JobStepInstanceId
   INNER JOIN ReceiptReceivableDetailMigration_Extract RRDME ON RME.ReceiptMigrationId=RRDME.ReceiptMigrationId 
   AND R.DueDate = RRDME.DueDate AND RRDME.JobStepInstanceId = @JobStepInstanceId
   AND RT.[Name]=RRDME.ReceivableType
   INNER JOIN LeaseFinances LF ON C.Id=LF.ContractId AND LF.IsCurrent=1
   INNER JOIN LeasePaymentSchedules LPS ON R.PaymentScheduleId = LPS.Id
   AND LPS.PaymentType = RRDME.PaymentType
   AND LPS.PaymentNumber=RRDME.PaymentNumber
   LEFT JOIN ReceivableTaxes RTX ON R.Id = RTX.ReceivableId  
   LEFT JOIN ReceivableTaxDetails RTXD ON RD.Id=RTXD.ReceivableDetailId
   WHERE RD.IsActive=1  AND RME.IsValid=1  AND RME.IsProcessed != 1  
   AND ((RD.EffectiveBalance_Amount + ISNULL(RTXD.EffectiveBalance_Amount,0.00)) != 0.00)
   AND RT.[Name] IN (
					@ReceivableTypeValues_LeaseInterimInterest,
					@ReceivableTypeValues_InterimRental,
					@ReceivableTypeValues_CapitalLeaseRental,
					@ReceivableTypeValues_OperatingLeaseRental,
					@ReceivableTypeValues_LeaseFloatRateAdj,
					@ReceivableTypeValues_LeveragedLeaseRental,
					@ReceivableTypeValues_OverTermRental,
					@ReceivableTypeValues_Supplemental,
					@ReceivableTypeValues_CPIOverage)
			UNION ALL
SELECT   
   RRDME.ReceiptMigrationId AS ReceiptId  
   ,ISNULL(RD.EffectiveBalance_Amount,0.00) AS EffectiveBalance  
   ,ISNULL(RTXD.EffectiveBalance_Amount,0.00) AS EffectiveTaxBalance  
   ,RD.Id AS ReceivableDetailId  
   ,@JobStepInstanceId  AS JobStepInstanceId  
   ,R.Id AS ReceivableId
   ,RTX.Id AS ReceivableTaxId
   ,RTXD.Id AS ReceivableTaxDetailId
   ,ISNULL(RD.LeaseComponentBalance_Amount,0.00) AS LeaseComponentBalance
   ,ISNULL(RD.NonLeaseComponentBalance_Amount,0.00) AS NonLeaseComponentBalance
   FROM Receivables R  
   INNER JOIN ReceivableDetails RD ON R.Id=RD.ReceivableId 
   INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId=RC.Id
   INNER JOIN GLTemplates GLT ON RC.GLTemplateId=GLT.Id
   INNER JOIN GLTransactionTypes GLTT ON GLT.GLTransactionTypeId=GLTT.Id
   INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId=RT.Id  
   INNER JOIN Contracts C ON R.EntityId = C.Id AND R.EntityType=@ReceivableEntityTypeValues_CT AND C.ContractType=@ContractTypeValues_Loan 
   AND C.SequenceNumber IS NOT NULL
   INNER JOIN ReceiptMigration_Extract RME ON C.SequenceNumber=RME.ContractSequenceNumber AND RME.JobStepInstanceId = @JobStepInstanceId
   INNER JOIN ReceiptReceivableDetailMigration_Extract RRDME ON RME.ReceiptMigrationId=RRDME.ReceiptMigrationId 
   AND R.DueDate = RRDME.DueDate AND RRDME.JobStepInstanceId = @JobStepInstanceId
   AND RT.[Name]=RRDME.ReceivableType
   INNER JOIN LoanFinances LF ON C.Id=LF.ContractId AND LF.IsCurrent=1
   INNER JOIN LoanPaymentSchedules LPS ON R.PaymentScheduleId = LPS.Id 
   AND LPS.PaymentType = RRDME.PaymentType
   AND LPS.PaymentNumber=RRDME.PaymentNumber   
   LEFT JOIN ReceivableTaxes RTX ON R.Id = RTX.ReceivableId  
   LEFT JOIN ReceivableTaxDetails RTXD ON RD.Id=RTXD.ReceivableDetailId 
   WHERE RD.IsActive=1  AND RME.IsValid=1   AND RME.IsProcessed != 1
   AND ((RD.EffectiveBalance_Amount + ISNULL(RTXD.EffectiveBalance_Amount,0.00)) != 0.00)
   AND RT.[Name] IN (
					@ReceivableTypeValues_LoanInterest,
					@ReceivableTypeValues_LoanPrincipal)
			UNION ALL
SELECT   
   RRDME.ReceiptMigrationId AS ReceiptId  
   ,ISNULL(RD.EffectiveBalance_Amount,0.00) AS EffectiveBalance  
   ,SUM(ISNULL(RTXD.EffectiveBalance_Amount,0.00)) AS EffectiveTaxBalance 
   ,RD.Id AS ReceivableDetailId  
   ,@JobStepInstanceId  AS JobStepInstanceId  
   ,R.Id AS ReceivableId
   ,RTX.Id AS ReceivableTaxId
   ,0 AS ReceivableTaxDetailId
   ,ISNULL(RD.LeaseComponentBalance_Amount,0.00) AS LeaseComponentBalance
   ,ISNULL(RD.NonLeaseComponentBalance_Amount,0.00) AS NonLeaseComponentBalance
   FROM Receivables R  
   LEFT JOIN ReceivableDetails RD ON R.Id=RD.ReceivableId
   INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId=RC.Id
   INNER JOIN GLTemplates GLT ON RC.GLTemplateId=GLT.Id
   INNER JOIN GLTransactionTypes GLTT ON GLT.GLTransactionTypeId=GLTT.Id
   INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId=RT.Id  
   LEFT JOIN Contracts C ON R.EntityId = C.Id AND R.EntityType=@ReceivableEntityTypeValues_CT
   AND C.SequenceNumber IS NOT NULL
   INNER JOIN ReceiptMigration_Extract RME ON C.SequenceNumber=RME.ContractSequenceNumber AND RME.JobStepInstanceId = @JobStepInstanceId
   INNER JOIN ReceiptReceivableDetailMigration_Extract RRDME ON RME.ReceiptMigrationId=RRDME.ReceiptMigrationId 
   AND R.DueDate = RRDME.DueDate AND RT.[Name]=RRDME.ReceivableType  
   AND RRDME.JobStepInstanceId = @JobStepInstanceId  
   LEFT JOIN ReceivableTaxes RTX ON R.Id = RTX.ReceivableId  
   LEFT JOIN ReceivableTaxDetails RTXD ON RD.Id=RTXD.ReceivableDetailId  
   WHERE RD.IsActive=1  AND RME.IsValid=1    AND RME.IsProcessed != 1 AND R.IncomeType=@IncomeTypeValues_None
   AND ((RD.EffectiveBalance_Amount + ISNULL(RTXD.EffectiveBalance_Amount,0.00)) != 0.00)

   AND RRDME.ReceivableType IN (@ReceivableTypeValues_Sundry,@ReceivableTypeValues_SecurityDeposit,@ReceivableTypeValues_InsurancePremium,@ReceivableTypeValues_InsurancePremiumAdmin
   ,@ReceivableTypeValues_SundrySeparate,@ReceivableTypeValues_CPIOverage,@ReceivableTypeValues_PropertyTaxEscrow,@ReceivableTypeValues_PropertyTax,@ReceivableTypeValues_Scrape
   ,@ReceivableTypeValues_LeasePayOff,@ReceivableTypeValues_BuyOut,@ReceivableTypeValues_AssetSale)
   GROUP BY RRDME.ReceiptMigrationId,R.Id,RD.Id,RD.EffectiveBalance_Amount,RTX.Id,RD.LeaseComponentBalance_Amount,RD.NonLeaseComponentBalance_Amount
   )
   AS #ReceivableDetailsForReceiptMigration
   
;WITH #ReceiptAmountApplicationsForMigrationCTE 
(ReceiptId,JobStepInstanceId,ReceivableId,ReceivableDetailId,EffectiveBalance,RunningEffectiveBalance,EffectiveTaxBalance,RunningEffectiveTaxBalance
,AmountToApply_Amount,TaxAmountToApply_Amount,LeaseComponentBalance,NonLeaseComponentBalance)
AS
(
SELECT 
ReceiptId,RDRM.JobStepInstanceId,ReceivableId,ReceivableDetailId,EffectiveBalance,
SUM(EffectiveBalance) OVER(PARTITION BY ReceiptId ORDER BY ReceivableId,ReceivableDetailId) AS RunningEffectiveBalance
,EffectiveTaxBalance
,SUM(EffectiveTaxBalance) OVER(PARTITION BY ReceiptId ORDER BY ReceivableId,ReceivableDetailId) AS RunningEffectiveTaxBalance
,SUM(RRDME.AmountToApply_Amount) AS AmountToApply_Amount,SUM(RRDME.TaxAmountToApply_Amount) AS TaxAmountToApply_Amount
,LeaseComponentBalance,NonLeaseComponentBalance
FROM #ReceivableDetailsForReceiptMigration RDRM
LEFT JOIN ReceiptReceivableDetailMigration_Extract RRDME ON RDRM.ReceiptId=RRDME.ReceiptMigrationId AND RRDME.JobStepInstanceId = @JobStepInstanceId  
GROUP BY ReceiptId,RDRM.JobStepInstanceId,ReceivableId,ReceivableDetailId,EffectiveBalance,EffectiveTaxBalance,LeaseComponentBalance,NonLeaseComponentBalance
)
SELECT ReceiptId,JobStepInstanceId,ReceivableId,ReceivableDetailId,EffectiveBalance,RunningEffectiveBalance,EffectiveTaxBalance,RunningEffectiveTaxBalance
,CASE 
WHEN (RunningEffectiveBalance) <= AmountToApply_Amount
THEN ( EffectiveBalance ) 
WHEN ( AmountToApply_Amount - (RunningEffectiveBalance - EffectiveBalance ) ) < 0.00
THEN ( 0.00 )
WHEN (RunningEffectiveBalance) > AmountToApply_Amount 
THEN ( AmountToApply_Amount - (RunningEffectiveBalance - EffectiveBalance ) )
END AS AmountApplied
,CASE 
WHEN (RunningEffectiveTaxBalance <= TaxAmountToApply_Amount)
THEN ( EffectiveTaxBalance ) 
WHEN (( TaxAmountToApply_Amount - ( RunningEffectiveTaxBalance - EffectiveTaxBalance ) ) < 0.00)
THEN ( 0.00 )
WHEN (RunningEffectiveTaxBalance > TaxAmountToApply_Amount) 
THEN ( TaxAmountToApply_Amount - ( RunningEffectiveTaxBalance - EffectiveTaxBalance ) )
END AS TaxAmountApplied,
CAST(0 as Decimal(16,2)) AS BookAmountApplied
,LeaseComponentBalance,NonLeaseComponentBalance
INTO #ReceiptAmountApplicationsForMigration
FROM #ReceiptAmountApplicationsForMigrationCTE
ORDER BY ReceiptId,ReceivableId,ReceivableDetailId

UPDATE #ReceiptAmountApplicationsForMigration SET BookAmountApplied = AmountApplied
FROM #ReceiptAmountApplicationsForMigration 
INNER JOIN Receivables R ON #ReceiptAmountApplicationsForMigration.ReceivableId = R.Id AND R.IsActive=1
INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id AND RT.Name IN (@ReceivableTypeValues_LoanInterest,@ReceivableTypeValues_LoanPrincipal)
WHERE R.IncomeType != @ReceivableIncomeTypeValues_InterimInterest AND R.IncomeType != @ReceivableIncomeTypeValues_TakeDownInterest

INSERT INTO [dbo].[ReceiptApplicationReceivableDetails_Extract]
           ([ReceiptId]
           ,[AmountApplied]
           ,[TaxApplied]
           ,[ReceivableDetailId]
           ,[ReceivableDetailIsActive]
           ,[ContractId]
           ,[InvoiceId]
           ,[JobStepInstanceId]
           ,[ReceivableId]
           ,[CreatedById]
           ,[CreatedTime]
           ,[DiscountingId]
           ,[ReceiptApplicationReceivableDetailId]
           ,[BookAmountApplied]
           ,[DumpId]
           ,[PrevAmountAppliedForReApplication]
           ,[PrevBookAmountAppliedForReApplication]
           ,[PrevTaxAppliedForReApplication]
		   ,IsReApplication
		   ,[LeaseComponentAmountApplied]
		   ,[NonLeaseComponentAmountApplied]
		   )
OUTPUT INSERTED.Id,INSERTED.ReceiptId,INSERTED.ReceivableId,INSERTED.ReceivableDetailId,INSERTED.AmountApplied,INSERTED.LeaseComponentAmountApplied,INSERTED.NonLeaseComponentAmountApplied into #RARD_ExtractTemp
SELECT   
   (RDME.ReceiptId * -1) AS ReceiptId  
   ,ISNULL(RAAM.AmountApplied,0.00) AS AmountApplied   
   ,ISNULL(RAAM.TaxAmountApplied,0.00) AS TaxAmountApplied  
   ,RDME.ReceivableDetailId AS ReceivableDetailId  
   ,RDME.ReceivableDetailIsActive AS ReceivableDetailIsActive  
   ,RDME.ContractId AS ContractId  
   ,RDME.InvoiceId AS InvoiceId
   ,@JobStepInstanceId  AS JobStepInstanceId  
   ,RDME.ReceivableId AS ReceivableId  
    ,@CreatedById AS CreatedById   
    ,@CreatedTime AS CreatedTime 
   ,NULL AS DiscountingId  
   ,RDME.ReceiptApplicationReceivableDetailId AS ReceiptApplicationReceivableDetailId  
   ,ISNULL(RAAM.BookAmountApplied,0.00) AS BookAmountApplied  
   ,RDME.DumpId AS DumpId  
   ,RDME.PrevAmountAppliedForReApplication_Amount AS PrevAmountAppliedForReApplication  
   ,RDME.PrevBookAmountAppliedForReApplication_Amount AS PrevBookAmountAppliedForReApplication  
   ,RDME.PrevTaxAppliedForReApplication_Amount AS PrevTaxAppliedForReApplication  
   ,RDME.IsReApplication AS IsReApplication
   ,ISNULL(ROUND(((ISNULL(RAAM.AmountApplied,0.00) * RAAM.LeaseComponentBalance)/NULLIF(RAAM.LeaseComponentBalance + RAAM.NonLeaseComponentBalance,0)),2),0.00) AS LeaseComponentAmountApplied
   ,ISNULL(ROUND(((ISNULL(RAAM.AmountApplied,0.00) * RAAM.NonLeaseComponentBalance)/NULLIF(RAAM.LeaseComponentBalance + RAAM.NonLeaseComponentBalance,0)),2),0.00) AS NonLeaseComponentAmountApplied
   FROM [ReceiptDetailsMigration_Extract] RDME 
   INNER JOIN #ReceiptAmountApplicationsForMigration RAAM 
		ON @JobStepInstanceId=RAAM.JobStepInstanceId 
			AND RDME.ReceiptId =RAAM.ReceiptId 
			AND RDME.ReceivableId=RAAM.ReceivableId 
			AND RDME.ReceivableDetailId=RAAM.ReceivableDetailId
	WHERE RDME.JobStepInstanceId = @JobStepInstanceId

    
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


UPDATE ReceiptMigration_Extract SET IsProcessed=1 WHERE JobStepInstanceId=@JobStepInstanceId

DROP TABLE #ReceivableDetailsForReceiptMigration
DROP TABLE #ReceiptAmountApplicationsForMigration
DROP TABLE #RARD_ExtractTemp
DROP TABLE #RARD_Extracts
DROP TABLE #UpdatedRARDTemp

END
END

GO

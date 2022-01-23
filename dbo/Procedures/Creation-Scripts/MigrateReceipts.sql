SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[MigrateReceipts]  
(  
	 @UserId BIGINT  
	,@ModuleIterationStatusId BIGINT  
	,@CreatedTime DATETIMEOFFSET  
	,@ProcessedRecords BIGINT OUTPUT  
	,@FailedRecords BIGINT OUTPUT
	,@ToolIdentifier INT   
)  
AS  
--DECLARE @UserId BIGINT;  
--DECLARE @FailedRecords BIGINT;  
--DECLARE @ProcessedRecords BIGINT;  
--DECLARE @CreatedTime DATETIMEOFFSET;  
--DECLARE @ModuleIterationStatusId BIGINT;  
--Set @UserId = 1;  
--Set @CreatedTime = SYSDATETIMEOFFSET();   
--Select @ModuleIterationStatusId = MAX(ModuleIterationStatusId) FROM stgProcessingLog;  
--Set @ModuleIterationStatusId  = (Select TOP 1 Id From stgModuleIterationStatus);  
BEGIN

DECLARE @RoundingValue DECIMAL(16,2) = 0.01;

CREATE TABLE #RARD_Temp  
(  
	RARD_ExtractId BIGINT,  
	ReceivableDetailId BIGINT,
	AmountApplied DECIMAL(16,2), 
	LeaseComponentAmountApplied DECIMAL(16,2), 
	NonLeaseComponentAmountApplied DECIMAL(16,2),  
)  

CREATE TABLE #RARD_Extracts
(  
	RARD_ExtractId BIGINT,  
	ReceivableDetailId BIGINT,
	RowNumber BIGINT,
	Amount_Amount DECIMAL(16,2), 
	ComponentType NVARCHAR(20)
)  

CREATE TABLE #UpdatedRARDTemp
(
  Id BIGINT
)

DECLARE @ReceivableDisplayOption NVARCHAR(40) = 'ShowUngroupedReceivables';  
DECLARE @ReceiptClassification NVARCHAR(40) = 'Cash';  
DECLARE @ReceiptStatus NVARCHAR(20) = 'Posted';  
DECLARE @count INT = 1;  
DECLARE @TotalRecordsCount BIGINT;  
DECLARE @MaxReceiptNumber BIGINT = 0;
DECLARE @SQL Nvarchar(max) =''
DECLARE @Number INT =0
SET @FailedRecords = 0; 
DECLARE @IsCloneDone BIT = ISNULL(@ToolIdentifier,0)
SET @ProcessedRecords = 0;  
DECLARE @Module VARCHAR(50) = NULL
SET @Module = (SELECT StgModule.Name FROM StgModule INNER JOIN StgModuleIterationStatus ON StgModule.Id = StgModuleIterationStatus.ModuleId WHERE StgModuleIterationStatus.Id = @ModuleIterationStatusId)
EXEC ResetStagingTempFields @Module,@ToolIdentifier
SELECT @TotalRecordsCount = ISNULL(COUNT(Id), 0) From stgDummyReceipt Where IsMigrated=0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier) And IsFailed=0  
IF(@TotalRecordsCount > 0)  
BEGIN  
SELECT   
	 LegalEntities.Id As LegalEntityId   
	,BankAccountId  
	,BankAccounts.AccountName  
	,BankBranches.Name As BankBranchName  
	,BankBranches.Id As BankBranchId  
INTO #LegalEntityBankAccountDetails  
FROM  
	LegalEntities  
	INNER JOIN LegalEntityBankAccounts 
		ON LegalEntities.Id = LegalEntityBankAccounts.LegalEntityId   
	INNER JOIN BankAccounts 
		ON BankAccounts.Id = LegalEntityBankAccounts.BankAccountId  
	INNER JOIN BankBranches 
		ON BankAccounts.BankBranchId = BankBranches.Id  
--Pending
SELECT 
	 ReceivableTypeId
	,[Order] As ReceivableTypeOrder 
INTO #ReceivableTypeOrder
FROM 
	ReceiptHierarchyTemplates
	INNER JOIN ReceiptPostingOrders 
		ON ReceiptPostingOrders.ReceiptHierarchyTemplateId = ReceiptHierarchyTemplates.Id
		AND ReceiptHierarchyTemplates.Name = 'Migration'
	INNER JOIN ReceivableTypes 
		ON ReceivableTypes.Id = ReceiptPostingOrders.ReceivableTypeId
SELECT   
	Id As ReceiptId  
INTO #DuplicatedReceipts  
FROM 
	stgDummyReceipt AS DummyReceipt  
	INNER JOIN   
		( 
			SELECT 
				 ContractSequenceNumber
				,ReceivedDate
				,NoOfEntries = Count(*) 
			FROM 
				stgDummyReceipt   
			WHERE
				IsMigrated = 0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier) AND IsFailed = 0 
			GROUP BY 
				 ContractSequenceNumber 
				,ReceivedDate  
			Having Count(*) > 1  
		) As DuplicateRceipts 
		ON DuplicateRceipts.ContractSequenceNumber = DummyReceipt.ContractSequenceNumber   
		AND DuplicateRceipts.Receiveddate = DummyReceipt.ReceivedDate ;  
DECLARE @MaxId BigInt = 0;  
WHILE(@COUNT > 0)  
BEGIN        
CREATE TABLE #ErrorLogs(Msg Nvarchar(MAX), EntityId BigInt);   
CREATE TABLE #FailedProcessingLogs([Action] NVARCHAR(10) NOT NULL, [Id] BIGINT NOT NULL, [ReceiptId] BIGINT NOT NULL);   
CREATE TABLE #CreatedReceiptIds(InsertedReceiptId BIGINT NOT NULL, Id BIGINT NOT NULL);   
CREATE TABLE #CreatedReceiptApplicationIds(InsertedReceiptApplicationId BIGINT NOT NULL, InsertedReceiptId BIGINT NOT NULL);   
CREATE TABLE #CreatedProcessingLogs([Action] NVARCHAR(10) NOT NULL, [Id] bigint NOT NULL);  
SELECT TOP 100 * INTO #ProcessableReceipts FROM stgDummyReceipt WHERE IsMigrated=0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier) And IsFailed=0 AND Id > @MaxId
ORDER BY Id;  
SELECT @MaxReceiptNumber = ISNULL(MAX(CONVERT(BIGINT,Number)),0) FROM Receipts;
SELECT @MaxId = MAX(Id) FROM #ProcessableReceipts;
SELECT  
	 ProcessableReceipts.*     
	,Contracts.Id As ContractId  
	,Contracts.ContractType  
	,LegalEntities.Id As LegalEntityId  
	,ReceiptTypes.Id As ReceiptTypeId  
	,Currencies.Id As CurrencyId  
	,GLTemplates.Id As ReceiptGLTemplateId  
	,#LegalEntityBankAccountDetails.BankAccountId As BankAccountId  
	,1 As IsReceiptAmountEqualsReceivableAmount   
	,IIF(Contracts.ContractType='Lease',LeaseFinances.CustomerId,LoanFinances.CustomerId) AS CustomerId 
	,(CASE WHEN ProcessableReceipts.PostDate IS NOT NULL AND ((ProcessableReceipts.PostDate < GLFinancialOpenPeriods.FromDate) OR (ProcessableReceipts.PostDate > GLFinancialOpenPeriods.ToDate)) THEN 0 ELSE 1 END) AS IsPostDateInGLFinancialOpenPeriod  
	,GLFinancialOpenPeriods.FromDate As OpenPeriodFromDate  
	,GLFinancialOpenPeriods.ToDate As OpenPeriodToDate  
	,Contracts.LineofBusinessId As ContractLOBId  
	,IIF(Contracts.ContractType='Lease',LeaseFinances.LegalEntityId,LoanFinances.LegalEntityId) As ContractLegalEntityId  
	,IIF(Contracts.ContractType='Lease',LeaseFinances.CostCenterId,LoanFinances.CostCenterId) As ContractCosCenterId  
	,IIF(Contracts.ContractType='Lease',LeaseFinances.BranchId,LoanFinances.BranchId) As ContractBranchId  
	,IIF(Contracts.ContractType='Lease',LeaseFinances.InstrumentTypeId,LoanFinances.InstrumentTypeId) As ContractInstrumentTypeId  
	,CASE WHEN #DuplicatedReceipts.ReceiptId IS NOT NULL THEN 1 ELSE 0 END IsDuplicateReceipt  
INTO #ReceiptMigrationDetails  
FROM      
	#ProcessableReceipts ProcessableReceipts  
	LEFT JOIN Contracts 
		ON Contracts.SequenceNumber = ProcessableReceipts.ContractSequenceNumber  
	LEFT JOIN LeaseFinances 
		ON LeaseFinances.ContractId = Contracts.Id 
		AND LeaseFinances.IsCurrent = 1 
	LEFT JOIN LoanFinances
		ON LoanFinances.ContractId=Contracts.Id
		AND LoanFinances.IsCurrent=1	
	LEFT JOIN LegalEntities 
		ON LegalEntities.LegalEntityNumber = ProcessableReceipts.LegalEntityNumber
		AND LegalEntities.Status = 'Active' 
	LEFT JOIN Currencies 
		ON Currencies.Name = ProcessableReceipts.CurrencyCode  
	LEFT JOIN ReceiptTypes 
		ON ReceiptTypes.ReceiptTypeName = ProcessableReceipts.ReceiptTypeName  
		AND ReceiptTypes.ReceiptTypeName NOT IN ('ACH','PAP','WebOneTimeACH','WebOneTimePAP')  
		AND ReceiptMode = 'MoneyOrder'     
	LEFT JOIN GLTemplates 
		ON GLTemplates.Name = ProcessableReceipts.ReceiptGLTemplateName 
		AND LegalEntities.GLConfigurationId = GLTemplates.GLConfigurationId   
	LEFT JOIN GLTransactionTypes 
		ON GLTransactionTypes.Id = GLTemplates.GLTransactionTypeId        
	LEFT JOIN GLFinancialOpenPeriods 
		ON GLFinancialOpenPeriods.LegalEntityId = LegalEntities.Id  
		AND GLFinancialOpenPeriods.IsCurrent=1  
	LEFT JOIN BankAccounts
		ON BankAccounts.UniqueIdentifier = ProcessableReceipts.BankAccountUniqueIdentifier  
	LEFT JOIN #LegalEntityBankAccountDetails 
		ON #LegalEntityBankAccountDetails.LegalEntityId = LegalEntities.Id  
		AND BankAccounts.Id = #LegalEntityBankAccountDetails.BankAccountId    
	LEFT JOIN #DuplicatedReceipts 
		ON #DuplicatedReceipts.ReceiptId = 	ProcessableReceipts.Id
SELECT   
	 FilteredContracts.ContractId
	,Contracts.ContractType  
	,Receivables.DueDate  
	,ReceivableDetails.Id  As ReceivableDetailId  
	,Receivables.Id As ReceivableId  
	,ReceivableDetails.Balance_Amount As ReceivableDetailBalanceAmount
	,ISNULL(ReceivableDetails.LeaseComponentBalance_Amount,0.00) As ReceivableDetailLeaseBalanceAmount
	,ISNULL(ReceivableDetails.NonLeaseComponentBalance_Amount,0.00) As ReceivableDetailNonLeaseBalanceAmount
	,ReceivableDetails.EffectiveBookBalance_Amount As ReceivableDetailEffectiveBookBalanceAmount  
	,ReceivableDetails.EffectiveBalance_Currency As Currency  
	,ISNULL(ReceivableTaxDetails.Balance_Amount,0.0) As ReceivableTaxBalanceAmount  
	,ReceivableInvoices.Id As ReceivableInvoiceId  
	,ISNULL(ReceivableTaxes.IsGLPosted, 0) IsTaxGLPosted  
	,ISNULL(Receivables.IsGLPosted, 0) As IsGLPosted  
	,#ReceivableTypeOrder.ReceivableTypeId
	,#ReceivableTypeOrder.ReceivableTypeOrder
INTO #ReceiptApplicationReceivableDetailInfo  
FROM   
	Contracts  
	INNER JOIN 	#ReceiptMigrationDetails FilteredContracts
		ON FilteredContracts.ContractId = Contracts.Id       
	LEFT JOIN LeaseFinances 
		ON Contracts.Id = LeaseFinances.ContractId   
		AND LeaseFinances.IsCurrent = 1  
	LEFT JOIN LoanFinances 
		ON Contracts.Id = LoanFinances.ContractId   
		AND LoanFinances.IsCurrent = 1  
	INNER JOIN Receivables 
		ON Receivables.EntityId = Contracts.Id   
		AND Receivables.EntityType = 'CT'
		AND Receivables.IsActive = 1 
		AND Receivables.IsDummy = 0          
		AND Receivables.IsCollected = 1  
	INNER JOIN ReceivableDetails 
		ON ReceivableDetails.ReceivableId = Receivables.Id   
		AND ReceivableDetails.IsActive = 1  
	INNER JOIN ReceivableCodes 
		ON ReceivableCodes.Id = Receivables.ReceivableCodeId            
	INNER JOIN ReceivableTypes 
		ON ReceivableTypes.Id = ReceivableCodes.ReceivableTypeId  
	LEFT JOIN #ReceivableTypeOrder 
		ON #ReceivableTypeOrder.ReceivableTypeId = ReceivableTypes.Id  
	LEFT JOIN ReceivableInvoiceDetails 
		ON ReceivableInvoiceDetails.ReceivableDetailId = ReceivableDetails.Id   
		And ReceivableInvoiceDetails.IsActive = 1     
	LEFT JOIN ReceivableInvoices 
		ON ReceivableInvoices.Id = ReceivableInvoiceDetails.ReceivableInvoiceId  
		AND ReceivableInvoiceDetails.IsActive = 1  
		AND ReceivableInvoices.IsActive = 1     
	LEFT JOIN ReceivableTaxDetails 
		ON ReceivableTaxDetails.ReceivableDetailId = ReceivableDetails.Id  
		AND ReceivableTaxDetails.IsActive = 1  
		And ReceivableTaxDetails.Balance_Amount > 0  
	LEFT JOIN ReceivableTaxes 
		ON ReceivableTaxes.Id = ReceivableTaxDetails.ReceivableTaxId  
		AND ReceivableTaxes.IsActive = 1  
WHERE   
(Receivables.TotalBalance_Amount > 0  OR ReceivableTaxes.Balance_Amount > 0)  
AND Contracts.Id IS NOT NULL 
AND Receivables.IncomeType NOT IN ('InterimInterest','TakeDownInterest')  
AND (LeaseFinances.Id IS NOT NULL OR LoanFinances.Id IS NOT NULL)
   select COunt(*) from #ReceiptApplicationReceivableDetailInfo
SELECT   
	 ReceiptMigrationDetails.Id As ReceiptId  
	,ReceiptMigrationDetails.ContractId  
	,ReceiptApplicationReceivableDetailInfo.DueDate  
	,ReceivableDetailId   
	,ReceivableId  
	,ReceivableDetailBalanceAmount 
	,ReceivableDetailLeaseBalanceAmount
	,ReceivableDetailNonLeaseBalanceAmount
	,Convert(Decimal(16,2), 0.0) As LeaseComponentAmountApplied
	,Convert(Decimal(16,2), 0.0) As NonLeaseComponentAmountApplied
	,ReceivableDetailEffectiveBookBalanceAmount  
	,Currency  
	,ReceivableTaxBalanceAmount  
	,ReceivableInvoiceId  
	,IsTaxGLPosted  
	,IsGLPosted  
	,ReceiptMigrationDetails.ReceiptAmount_Amount As ReceiptAmount
	,IsPartialReceipt  
	,ReceivableTypeId 
	,ReceivableTypeOrder
	,Convert(Decimal(16,2), 0.0) As DistributedBalanceAmount
	,Convert(Decimal(16,2), 0.0) As DistributedTaxAmount
	,Convert(Bit, 0) As IsCounterForReceiptPosting
	,ReceiptOrder = ROW_NUMBER() OVER(Partition By ReceiptMigrationDetails.Id, DueDate Order By ReceivableTypeOrder, ReceivableDetailId )  
	,ReceiptMigrationDetails.ContractType
INTO #ReceiptApplicationReceivableDetail  
FROM   
	#ReceiptMigrationDetails ReceiptMigrationDetails
	INNER JOIN #ReceiptApplicationReceivableDetailInfo ReceiptApplicationReceivableDetailInfo 
		ON ReceiptApplicationReceivableDetailInfo.ContractId = ReceiptMigrationDetails.ContractId   
		AND ReceiptMigrationDetails.IsDuplicateReceipt = 0  
		AND ReceiptApplicationReceivableDetailInfo.DueDate <= ReceiptMigrationDetails.ReceivedDate
DECLARE @ReceivableBalanceAmount Decimal(16,2), @ReceivableTaxBalanceAmount Decimal(16,2), @ReceiptId Bigint, @ReceiptAmount Decimal(16,2), @ReceivableDetailId Bigint , @GlobalReceiptId Bigint, @GlobalReceiptAmount Decimal(16,2), @GlobalReceivableDetailsId Bigint
Select TOP 1 @GlobalReceiptId = ReceiptId, @GlobalReceiptAmount = ReceiptAmount From #ReceiptApplicationReceivableDetail;
DECLARE DistributeAmount CURSOR
LOCAL SCROLL STATIC  
FOR  
Select ReceiptId, ReceivableDetailBalanceAmount, ReceivableTaxBalanceAmount, ReceiptAmount, ReceivableDetailId FROM #ReceiptApplicationReceivableDetail Where IsPartialReceipt=1 ORDER BY ReceiptId,DueDate,ReceiptOrder;
OPEN DistributeAmount
FETCH NEXT FROM DistributeAmount
INTO @ReceiptId, @ReceivableBalanceAmount, @ReceivableTaxBalanceAmount, @ReceiptAmount, @ReceivableDetailId   
WHILE @@FETCH_STATUS = 0  
BEGIN 		
IF(@GlobalReceiptId <> @ReceiptId)
	Begin
		Set @GlobalReceiptId = @ReceiptId;
		Set @GlobalReceiptAmount = @ReceiptAmount;				
	End
--print '-----------------------------------------' 
--Print @ReceiptId;
--Print @ReceivableBalanceAmount;
--Print @ReceivableTaxBalanceAmount;
--Print @ReceivableDetailId;
--Print @GlobalReceiptId;
--Print @GlobalReceiptAmount;
--print '-----------------------------------------'
IF(@GlobalReceiptAmount <> 0.0)
Begin
	IF((@GlobalReceiptAmount <= @ReceivableBalanceAmount))
		Begin
			Update #ReceiptApplicationReceivableDetail Set DistributedBalanceAmount = @GlobalReceiptAmount Where ReceivableDetailId = @ReceivableDetailId;
			Set @GlobalReceiptAmount = 0.0;
		End
	IF(@GlobalReceiptAmount > @ReceivableBalanceAmount)
		Begin
			Update #ReceiptApplicationReceivableDetail Set DistributedBalanceAmount = @ReceivableBalanceAmount Where ReceivableDetailId = @ReceivableDetailId;
			Set @GlobalReceiptAmount = @GlobalReceiptAmount - @ReceivableBalanceAmount;
		End
	IF((@GlobalReceiptAmount <= @ReceivableTaxBalanceAmount))
		Begin
			Update #ReceiptApplicationReceivableDetail Set DistributedTaxAmount = @GlobalReceiptAmount Where ReceivableDetailId = @ReceivableDetailId;
			Set @GlobalReceiptAmount = 0.0;
		End
	IF(@GlobalReceiptAmount > @ReceivableTaxBalanceAmount)
		Begin
			Update #ReceiptApplicationReceivableDetail Set DistributedTaxAmount = @ReceivableTaxBalanceAmount Where ReceivableDetailId = @ReceivableDetailId;
			Set @GlobalReceiptAmount = @GlobalReceiptAmount - @ReceivableTaxBalanceAmount;
		End
	Update #ReceiptApplicationReceivableDetail Set IsCounterForReceiptPosting = 1 Where ReceivableDetailId = @ReceivableDetailId;
End		
FETCH NEXT FROM DistributeAmount
INTO @ReceiptId, @ReceivableBalanceAmount, @ReceivableTaxBalanceAmount, @ReceiptAmount, @ReceivableDetailId 
END  
CLOSE DistributeAmount
DEALLOCATE DistributeAmount
UPDATE #ReceiptApplicationReceivableDetail Set IsCounterForReceiptPosting = 1 Where IsPartialReceipt=0;
SELECT    
	ReceiptId  
	,ISNULL(SUM(RARD.ReceivableDetailBalanceAmount),0) + ISNULL(SUM(RARD.ReceivableTaxBalanceAmount),0) As ReceivableAmount   
	,ISNULL(SUM(RARD.DistributedBalanceAmount),0) + ISNULL(SUM(RARD.DistributedTaxAmount),0) As DistributedReceivableAmount   
INTO #ReceiptsWithCalReceivableAmount     
FROM  
	#ReceiptApplicationReceivableDetail As RARD  
GROUP BY 
	ReceiptId    
SELECT  
	 ReceiptId  
	,ContractId 
	,ReceivableTaxDetails.ReceivableTaxId
	,#ReceiptApplicationReceivableDetail.ReceivableDetailId  
	,ReceivableTaxImpositions.Id As ReceivableTaxImpositionId  
	,ReceivableTaxImpositions.Balance_Amount As BalanceAmount  
	,ReceivableTaxImpositions.Balance_Currency As Currency  
INTO #ReceiptApplicationReceivableTaxImposition  
FROM   
	#ReceiptApplicationReceivableDetail  
	INNER JOIN ReceivableTaxDetails 
		ON ReceivableTaxDetails.ReceivableDetailId = #ReceiptApplicationReceivableDetail.ReceivableDetailId 
		AND #ReceiptApplicationReceivableDetail.IsCounterForReceiptPosting = 1 
		AND #ReceiptApplicationReceivableDetail.IsPartialReceipt = 0
		AND ReceivableTaxDetails.IsActive = 1  
	INNER JOIN ReceivableTaxImpositions 
		ON ReceivableTaxImpositions.ReceivableTaxDetailId = ReceivableTaxDetails.Id  
		AND ReceivableTaxImpositions.Balance_Amount > 0   
SELECT
	 ReceiptId 
	,ContractId  
	,ReceivableTaxDetails.ReceivableTaxId
	,#ReceiptApplicationReceivableDetail.ReceivableDetailId  
	,ReceivableTaxImpositions.Id As ReceivableTaxImpositionId
	,ReceivableTaxDetails.Id As ReceivableTaxDetailId
	,ReceivableTaxDetails.Balance_Amount As  ReceivableTaxDetailBalanceAmount
	,ReceivableTaxImpositions.Balance_Amount As ReceivableTaxImpositionBalanceAmount
	,ReceivableTaxImpositions.Balance_Currency As ReceivableTaxImpositionBalanceCurrency
	,DistributedTaxAmount
	,Convert(Decimal(16,2), 0.0) As DistributedBalanceAmount
INTO #ReceiptWithReceivableTaxImposition  
FROM   
	#ReceiptApplicationReceivableDetail
	INNER JOIN ReceivableTaxDetails 
		ON ReceivableTaxDetails.ReceivableDetailId = #ReceiptApplicationReceivableDetail.ReceivableDetailId  
		AND #ReceiptApplicationReceivableDetail.IsPartialReceipt=1
		And IsCounterForReceiptPosting = 1
	INNER JOIN ReceivableTaxes 
		ON ReceivableTaxes.Id = ReceivableTaxDetails.ReceivableTaxId  
		And ReceivableTaxes.IsActive = 1  
		And ReceivableTaxDetails.IsActive = 1  
		And ReceivableTaxDetails.Balance_Amount > 0 
	INNER JOIN ReceivableTaxImpositions 
		ON ReceivableTaxImpositions.ReceivableTaxDetailId = ReceivableTaxDetails.Id  
		And ReceivableTaxImpositions.Balance_Amount > 0 	    
DECLARE @GlobalReceivableDetailId Bigint, @GlobalDistributedTaxAmount Decimal(16,2), @ReceivableDetail Bigint, @DistributedTaxAmount Decimal(16,2), @ReceivableTaxImpositionBalanceAmount Decimal(16,2), @ReceivableTaxImpositionId Bigint
SELECT TOP 1 @GlobalReceivableDetailId = ReceivableDetailId, @GlobalDistributedTaxAmount = DistributedTaxAmount From #ReceiptWithReceivableTaxImposition;
DECLARE DistributeReceivableTaxTaxAmount CURSOR
LOCAL SCROLL STATIC  
FOR  
Select ReceivableDetailId, DistributedTaxAmount, ReceivableTaxImpositionBalanceAmount, ReceivableTaxImpositionId From #ReceiptWithReceivableTaxImposition ORDER BY ReceiptId
OPEN DistributeReceivableTaxTaxAmount
FETCH NEXT FROM DistributeReceivableTaxTaxAmount
INTO @ReceivableDetail, @DistributedTaxAmount, @ReceivableTaxImpositionBalanceAmount, @ReceivableTaxImpositionId 
WHILE @@FETCH_STATUS = 0  
BEGIN 		
	IF(@GlobalReceivableDetailId <> @ReceivableDetail)
		Begin
			Set @GlobalReceivableDetailId = @ReceivableDetail;
			Set @GlobalDistributedTaxAmount = @DistributedTaxAmount;				
		End
	print '-----------------------------------------' 
	print @GlobalReceivableDetailId;
	print @GlobalDistributedTaxAmount;
	print '-----------------------------------------'
	IF(@GlobalDistributedTaxAmount <> 0.0)
	Begin
		IF((@GlobalDistributedTaxAmount <= @ReceivableTaxImpositionBalanceAmount))
			Begin
				Update #ReceiptWithReceivableTaxImposition Set DistributedBalanceAmount = @GlobalDistributedTaxAmount Where ReceivableTaxImpositionId = @ReceivableTaxImpositionId;
				Set @GlobalDistributedTaxAmount = 0.0;
			End
		IF(@GlobalDistributedTaxAmount > @ReceivableTaxImpositionBalanceAmount)
			Begin
				Update #ReceiptWithReceivableTaxImposition Set DistributedBalanceAmount = @ReceivableTaxImpositionBalanceAmount Where ReceivableTaxImpositionId = @ReceivableTaxImpositionId;
				Set @GlobalDistributedTaxAmount = @GlobalDistributedTaxAmount - @ReceivableTaxImpositionBalanceAmount;
			End			
	End		
FETCH NEXT FROM DistributeReceivableTaxTaxAmount
INTO @ReceivableDetail, @DistributedTaxAmount, @ReceivableTaxImpositionBalanceAmount, @ReceivableTaxImpositionId 
END  
CLOSE DistributeReceivableTaxTaxAmount
DEALLOCATE DistributeReceivableTaxTaxAmount
INSERT INTO #ReceiptApplicationReceivableTaxImposition
(
	ReceiptId
	,ContractId
	,ReceivableDetailId
	,ReceivableTaxImpositionId
	,BalanceAmount
	,Currency
	,ReceivableTaxId
)
SELECT
	ReceiptId
	,ContractId
	,ReceivableDetailId
	,ReceivableTaxImpositionId
	,DistributedBalanceAmount As BalanceAmount
	,ReceivableTaxImpositionBalanceCurrency
	,ReceivableTaxId
FROM 
	#ReceiptWithReceivableTaxImposition
UPDATE #ReceiptMigrationDetails SET 
	IsReceiptAmountEqualsReceivableAmount = CASE 
												WHEN (RMD.ReceiptAmount_Amount >= #ReceiptsWithCalReceivableAmount.ReceivableAmount AND #ReceiptsWithCalReceivableAmount.ReceivableAmount != 0.00) 
													  OR (RMD.ReceiptAmount_Amount >= #ReceiptsWithCalReceivableAmount.DistributedReceivableAmount AND #ReceiptsWithCalReceivableAmount.DistributedReceivableAmount != 0.00) 
											    THEN 1 
											    ELSE 0 
											END  
FROM 
	#ReceiptMigrationDetails As RMD  
	INNER Join #ReceiptsWithCalReceivableAmount 
		ON #ReceiptsWithCalReceivableAmount.ReceiptId = RMD.Id          
--========================================Validations==========================================================    
UPDATE stgDummyReceipt SET 
	 R_ContractId = RMD.ContractId
	,R_LegalEntityId = RMD.LegalEntityId 
	,R_ReceiptTypeId = RMD.ReceiptTypeId 
	,R_CurrencyId = RMD.CurrencyId 
	,R_ReceiptGLTemplateId = RMD.ReceiptGLTemplateId 
	,R_BankAccountId = RMD.BankAccountId
FROM 
	stgDummyReceipt R  
	INNER JOIN #ReceiptMigrationDetails RMD 
		ON R.Id = RMD.Id    
Insert Into #ErrorLogs  
Select 'Receipt: Duplicate Receipt entries with same ReceivedDate and ContractSequenceNumber. [Id, ContractSequenceNumber, ReceivedDate]:['+Convert(NVARCHAR(40),R.Id)+','+IsNUll(R.ContractSequenceNumber,'Null')+','+IsNUll(CONVERT(NVARCHAR(40),R.ReceivedDate,101),'Null')+' ]', R.Id  
From stgDummyReceipt As R   
Inner Join #ReceiptMigrationDetails WITH (NOLOCK) On #ReceiptMigrationDetails.Id = R.Id  
And #ReceiptMigrationDetails.IsDuplicateReceipt = 1  
Insert Into #ErrorLogs  
Select 'Receipt: ReceivedDate is Required. [Id, ReceivedDate]:['+Convert(NVARCHAR(40),R.Id)+','+IsNUll(CONVERT(NVARCHAR(40),R.ReceivedDate,101),'Null')+' ]', R.Id  
From stgDummyReceipt As R   
Inner Join #ReceiptMigrationDetails WITH (NOLOCK) On #ReceiptMigrationDetails.Id = R.Id  
Where R.ReceivedDate Is Null;  
Insert Into #ErrorLogs  
Select 'Receipt: CheckNumber is Required. [Id, CheckNumber]:['+Convert(NVARCHAR(40),R.Id)+','+IsNull(R.CheckNumber, 'Null')+' ]', R.Id  
From stgDummyReceipt As R   
Inner Join #ReceiptMigrationDetails WITH (NOLOCK) On #ReceiptMigrationDetails.Id = R.Id  
Where R.CheckNumber Is Null;   
Insert Into #ErrorLogs  
Select 'Receipt: ContractSequenceNumber provided is not valid for [Id, ContractSequenceNumber] :['+Convert(NVARCHAR(40),R.Id)+','+IsNull(R.ContractSequenceNumber,'Null')+' ]', R.Id  
From stgDummyReceipt As R   
Inner Join #ReceiptMigrationDetails WITH (NOLOCK) On #ReceiptMigrationDetails.Id = R.Id  
Where R.R_ContractId IS NULL AND R.ContractSequenceNumber IS NOT NULL AND LTRIM(RTRIM(R.ContractSequenceNumber)) <> '';   
Insert Into #ErrorLogs  
Select 'Receipt: LegalEntityNumber provided is not valid for [Id, LegalEntityNumber] :['+Convert(NVARCHAR(40),R.Id)+','+IsNull(R.LegalEntityNumber,'Null')+' ]', R.Id  
From stgDummyReceipt As R   
Inner Join #ReceiptMigrationDetails WITH (NOLOCK) On #ReceiptMigrationDetails.Id = R.Id  
Where R.R_LegalEntityId IS NULL AND R.LegalEntityNumber IS NOT NULL AND LTRIM(RTRIM(R.LegalEntityNumber)) <> '';   
Insert Into #ErrorLogs  
Select 'Receipt: ReceiptGLTemplateName provided is not valid for [Id, ReceiptGLTemplateName] :['+Convert(NVARCHAR(40),R.Id)+','+IsNull(R.ReceiptGLTemplateName,'Null')+' ]', R.Id  
From stgDummyReceipt As R   
Inner Join #ReceiptMigrationDetails WITH (NOLOCK) On #ReceiptMigrationDetails.Id = R.Id  
Where R.R_ReceiptGLTemplateId IS NULL;  
Insert Into #ErrorLogs  
Select 'Receipt: CurrencyCode provided is not valid for [Id, CurrencyCode] :['+Convert(NVARCHAR(40),R.Id)+','+IsNull(R.CurrencyCode,'Null')+' ]', R.Id  
From stgDummyReceipt As R   
Inner Join #ReceiptMigrationDetails WITH (NOLOCK) On #ReceiptMigrationDetails.Id = R.Id  
Where R.R_CurrencyId IS NULL;  
Insert Into #ErrorLogs  
Select 'Receipt: Invalid Bank Account Details.Please provide valid Uniqueidentifier for bankAccount associated with LegalEntity For [Id, BankAccountUniqueIdentifier] :['+Convert(NVARCHAR(40),R.Id)+','+IsNull(R.BankAccountUniqueIdentifier,'Null')+' ]', R.Id  
From stgDummyReceipt As R   
Inner Join #ReceiptMigrationDetails WITH (NOLOCK) On #ReceiptMigrationDetails.Id = R.Id  
Where R.R_BankAccountId IS NULL;        
Insert Into #ErrorLogs  
Select 'Receipt: ReceiptTypeName provided is not valid for [Id, ReceiptTypeName] :['+Convert(NVARCHAR(40),R.Id)+','+IsNull(R.ReceiptTypeName,'Null')+' ]', R.Id  
From stgDummyReceipt As R   
Inner Join #ReceiptMigrationDetails WITH (NOLOCK) On #ReceiptMigrationDetails.Id = R.Id  
Where R.R_ReceiptTypeId IS NULL ;  
--Insert Into #ErrorLogs  
--Select 'Receipt: ReceiptAmount should not be Zero for [Id, ReceiptAmount] :['+Convert(NVARCHAR(40),R.Id)+','+CONVERT(nvarchar,R.ReceiptAmount_Amount)+' ]', R.Id  
--From stgDummyReceipt As R   
--Inner Join #ReceiptMigrationDetails WITH (NOLOCK) On #ReceiptMigrationDetails.Id = R.Id  
--Where #ReceiptMigrationDetails.ReceiptAmount_Amount=0;  
Insert Into #ErrorLogs  
Select 'Receipt: ReceiptAmount_Currency should not be blank for [Id, ReceiptAmount_Currency]:['+Convert(NVARCHAR(40),R.Id)+','+IsNull(R.ReceiptAmount_Currency,'Null')+' ]', R.Id  
From stgDummyReceipt As R   
Inner Join #ReceiptMigrationDetails WITH (NOLOCK) On #ReceiptMigrationDetails.Id = R.Id  
Where #ReceiptMigrationDetails.ReceiptAmount_Currency Is Null;  
Insert Into #ErrorLogs  
Select 'Receipt: ReceiptAmount_Currency should be equal to CurrencyCode for [Id]:['+Convert(NVARCHAR(40),R.Id)+' ]', R.Id  
From stgDummyReceipt As R   
Inner Join #ReceiptMigrationDetails WITH (NOLOCK) On #ReceiptMigrationDetails.Id = R.Id  
Where #ReceiptMigrationDetails.ReceiptAmount_Currency <> R.CurrencyCode;  
Insert Into #ErrorLogs  
Select 'Receipt: ReceiptAmount is not equal to Sum of ReceivableAmount for [Id, ReceiptAmount, CalculatedTotalReceivableAmount] :['+Convert(NVARCHAR(40),R.Id)+','+CONVERT(nvarchar,R.ReceiptAmount_Amount)+','+CONVERT(nvarchar,IsNull(#ReceiptsWithCalReceivableAmount.ReceivableAmount,0))+' ]', R.Id  
From stgDummyReceipt As R   
Inner Join #ReceiptMigrationDetails WITH (NOLOCK) On #ReceiptMigrationDetails.Id = R.Id  
Left Join #ReceiptsWithCalReceivableAmount On #ReceiptsWithCalReceivableAmount.ReceiptId = R.Id  
Where #ReceiptMigrationDetails.IsReceiptAmountEqualsReceivableAmount = 0 AND R.IsPartialReceipt = 0;  
Insert Into #ErrorLogs  
Select 'Receipt: PostDate is required for [Id] :['+Convert(NVARCHAR(40),R.Id)' ]', R.Id  
From stgDummyReceipt As R   
Inner Join #ReceiptMigrationDetails WITH (NOLOCK) On #ReceiptMigrationDetails.Id = R.Id  
Where #ReceiptMigrationDetails.PostDate Is NULL;  
Insert Into #ErrorLogs  
Select 'Receipt: PostDate should be within the GLFinancial Open Period '+IsNull(Convert(NVARCHAR,#ReceiptMigrationDetails.OpenPeriodFromDate,101),'NULL')+' to '+IsNull(Convert(NVARCHAR,#ReceiptMigrationDetails.OpenPeriodToDate,101),'NULL')+' for [Id] :[ '+Convert(NVARCHAR(40),R.Id)+' ]', R.Id  
From stgDummyReceipt As R   
Inner Join #ReceiptMigrationDetails WITH (NOLOCK) On #ReceiptMigrationDetails.Id = R.Id  
Where #ReceiptMigrationDetails.IsPostDateInGLFinancialOpenPeriod = 0;       
--========================================End Validations=====================================================  
--========================================Log Errors==========================================================     
Merge stgProcessingLog As ProcessingLog  
Using (Select  
Distinct EntityId StagingRootEntityId  
    From  
#ErrorLogs WITH (NOLOCK)  
    ) As ErrorReceipts  
On (ProcessingLog.StagingRootEntityId = ErrorReceipts.StagingRootEntityId AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)  
WHEN MATCHED Then  
Update Set UpdatedTime = @CreatedTime  
When Not Matched Then  
Insert  
(  
StagingRootEntityId  
    ,CreatedById  
    ,CreatedTime  
    ,ModuleIterationStatusId  
)  
Values  
(  
    Errorreceipts.StagingRootEntityId  
    ,@UserId  
    ,@CreatedTime  
    ,@ModuleIterationStatusId  
)  
Output $action, Inserted.Id,ErrorReceipts.StagingRootEntityId INTO #FailedProcessingLogs;   
INSERT INTO stgProcessingLogDetail  
(  
	Message  
    ,Type  
    ,CreatedById  
    ,CreatedTime   
    ,ProcessingLogId  
)  
SELECT  
	#ErrorLogs.Msg  
    ,'Error'  
    ,@UserId  
    ,@CreatedTime  
    ,#FailedProcessingLogs.Id  
FROM  
	#ErrorLogs  
	INNER JOIN #FailedProcessingLogs  WITH (NOLOCK) 
		ON #ErrorLogs.EntityId = #FailedProcessingLogs.ReceiptId;   
UPDATE stgDummyReceipt SET IsFailed = 1 WHERE Id IN (SELECT EntityId FROM #errorLogs);  
SET @FailedRecords = @FailedRecords + ISNULL((SELECT COUNT(DISTINCT EntityId) FROM #errorLogs),0);  
SELECT 
	 DummyReceipt.Id
	,CalReceiptNumber = ROW_NUMBER() OVER(ORDER BY DummyReceipt.Id) 
INTO #ReceiptNumbersForReceipt 
FROM 
	stgDummyReceipt AS DummyReceipt   
	INNER JOIN #ReceiptMigrationDetails RMD 
		ON RMD.Id = DummyReceipt.Id  
WHERE 
	DummyReceipt.IsFailed=0 and DummyReceipt.IsMigrated=0 AND (DummyReceipt.ToolIdentifier IS NULL OR DummyReceipt.ToolIdentifier = @ToolIdentifier)
----========================================End ErrorLogs==========================================================  
MERGE Receipts As Receipt  
USING  
(  
	SELECT DummyReceipt.*, RMD.ContractBranchId,RMD.CustomerId,(#ReceiptNumbersForReceipt.CalReceiptNumber + @MaxReceiptNumber) As ReceiptNumber , (CASE WHEN RMD.IsPartialReceipt = 0 THEN IsNUll(#ReceiptsWithCalReceivableAmount.ReceivableAmount, 0) ELSE IsNUll(#ReceiptsWithCalReceivableAmount.DistributedReceivableAmount, 0) END) As ReceiptAmount ,RMD.ContractType
	FROM stgDummyReceipt AS DummyReceipt  
	INNER JOIN #ReceiptMigrationDetails RMD ON RMD.Id = DummyReceipt.Id  
	LEFT JOIN #ReceiptsWithCalReceivableAmount ON #ReceiptsWithCalReceivableAmount.ReceiptId = DummyReceipt.Id  
	LEFT JOIN #ReceiptNumbersForReceipt ON #ReceiptNumbersForReceipt.Id = DummyReceipt.Id  
	WHERE DummyReceipt.IsFailed=0 and DummyReceipt.IsMigrated=0 AND (DummyReceipt.ToolIdentifier IS NULL OR DummyReceipt.ToolIdentifier = @ToolIdentifier) AND ((#ReceiptsWithCalReceivableAmount.ReceivableAmount<> 0 And RMD.IsPartialReceipt=0) OR (RMD.IsPartialReceipt=1 AND #ReceiptsWithCalReceivableAmount.DistributedReceivableAmount <> 0))
) As ReceiptsToMigrate  
ON 1 = 0  
WHEN NOT MATCHED   
THEN  
INSERT  
(            
     [Number]    
    ,[ReceiptAmount_Amount]    
    ,[ReceiptAmount_Currency]    
    ,[EntityType]    
    ,[PostDate]    
    ,[ReceivedDate]    
    ,[Status]    
    ,[CreateRefund]    
    ,[CheckNumber]    
    ,[Comment]    
    ,[CreatedById]    
    ,[CreatedTime]    
    ,[LegalEntityId]    
    ,[CurrencyId]    
    ,[BankAccountId]    
    ,[TypeId]    
    ,[ContractId]    
    ,[BranchId]    
    ,[ReceiptGLTemplateId]    
    ,[CustomerId]    
    ,[Balance_Amount]    
    ,[Balance_Currency]    
    ,[ApplyByReceivable]    
    ,[NonCashReason]    
    ,[IsFromReceiptBatch]    
    ,[ReceiptClassification]    
    ,[SecurityDepositLiabilityContractAmount_Amount]    
    ,[SecurityDepositLiabilityContractAmount_Currency]    
    ,[SecurityDepositLiabilityAmount_Amount]    
    ,[SecurityDepositLiabilityAmount_Currency]    
    ,[IsReceiptCreatedFromLockBox]    
	,[PayableWithholdingTaxRate]
)     
Values  
(    
    ReceiptNumber    
    ,ReceiptAmount    
    ,ReceiptAmount_Currency    
    ,ContractType 
    ,PostDate  
    ,ReceivedDate  
    ,@ReceiptStatus  
    ,0     
    ,CheckNumber  
    ,Comment  
    ,@UserId  
    ,@CreatedTime    
    ,R_LegalEntityId  
    ,R_CurrencyId    
    ,R_BankAccountId    
    ,R_ReceiptTypeId    
    ,R_ContractId    
    ,ContractBranchId  
    ,R_ReceiptGLTemplateId    
    ,CustomerId  
    ,0    
    ,ReceiptAmount_Currency    
    ,1    
    ,'_'    
    ,0    
    ,@ReceiptClassification    
    ,0    
    ,ReceiptAmount_Currency  
    ,0    
    ,ReceiptAmount_Currency  
    ,0    
	,0.0
)  
Output Inserted.Id, ReceiptsToMigrate.Id INTO #CreatedReceiptIds; 
INSERT INTO [dbo].[ReceiptAllocations]    
(    
    [EntityType]    
    ,[AllocationAmount_Amount]    
    ,[AllocationAmount_Currency]    
    ,[Description]    
    ,[IsActive]    
    ,[CreatedById]    
    ,[CreatedTime]    
    ,[LegalEntityId]    
    ,[ContractId]    
    ,[ReceiptId]    
    ,[AmountApplied_Amount]    
    ,[AmountApplied_Currency]    
)    
SELECT     
    Receipt.ContractType,    
    (CASE WHEN Receipt.IsPartialReceipt = 0 THEN IsNUll(#ReceiptsWithCalReceivableAmount.ReceivableAmount, 0) ELSE IsNUll(#ReceiptsWithCalReceivableAmount.DistributedReceivableAmount, 0) END) As AllocationAmount_Amount,    
    Receipt.ReceiptAmount_Currency,     
    NULL,    
    1,    
    @UserId,    
    @CreatedTime,    
    Receipt.LegalEntityId,    
    Receipt.ContractId,  
    #CreatedReceiptIds.InsertedReceiptId,    
    (CASE WHEN Receipt.IsPartialReceipt = 0 THEN IsNUll(#ReceiptsWithCalReceivableAmount.ReceivableAmount, 0) ELSE IsNUll(#ReceiptsWithCalReceivableAmount.DistributedReceivableAmount, 0) END) As AmountApplied_Amount,    
    Receipt.ReceiptAmount_Currency   
FROM     
    #ReceiptMigrationDetails As Receipt            
    INNER JOIN #CreatedReceiptIds 
		ON #CreatedReceiptIds.Id = Receipt.Id  
    LEFT JOIN #ReceiptsWithCalReceivableAmount 
		ON #ReceiptsWithCalReceivableAmount.ReceiptId = Receipt.Id;  
INSERT INTO ReceiptApplications    
(    
    PostDate    
    ,Comment    
    ,AmountApplied_Amount    
    ,AmountApplied_Currency    
    ,IsFullCash    
    ,CreatedById    
    ,CreatedTime    
    ,ReceiptId    
    ,CreditApplied_Amount    
    ,CreditApplied_Currency    
    ,ReceivableDisplayOption   
	,ApplyByReceivable
)    
OUTPUT inserted.Id,inserted.ReceiptId INTO #CreatedReceiptApplicationIds    
SELECT     
    Receipt.PostDate,    
    Receipt.Comment,    
    0.0,     
    Receipt.ReceiptAmount_Currency,    
    CASE WHEN Receipt.IsPartialReceipt = 1 Then 0 Else 1 End,    
    @UserId,    
    @CreatedTime,    
    #CreatedReceiptIds.InsertedReceiptId As ReceiptId,    
    0.0,    
    Receipt.ReceiptAmount_Currency,    
    @ReceivableDisplayOption ,
	1
FROM     
	#ReceiptMigrationDetails As Receipt  
	INNER JOIN #CreatedReceiptIds 
		ON #CreatedReceiptIds.Id = Receipt.Id;  
INSERT INTO [dbo].[ReceiptApplicationDetails]    
(    
    [Id]    
    ,[CreatedById]    
    ,[CreatedTime]    
    ,[ReceiptApplicationId]    
)    
SELECT     
    #CreatedReceiptApplicationIds.InsertedReceiptId    
    ,@UserId    
    ,@CreatedTime    
    ,#CreatedReceiptApplicationIds.InsertedReceiptApplicationId    
FROM     
    #CreatedReceiptApplicationIds   
INSERT INTO ReceiptApplicationReceivableDetails    
(    
     AmountApplied_Amount    
    ,AmountApplied_Currency    
    ,TaxApplied_Amount    
    ,TaxApplied_Currency    
    ,IsActive    
    ,CreatedById    
    ,CreatedTime    
    ,ReceivableDetailId    
    ,ReceiptApplicationId    
    ,PreviousAmountApplied_Amount    
    ,PreviousAmountApplied_Currency    
    ,IsReApplication    
    ,PreviousTaxApplied_Amount    
    ,PreviousTaxApplied_Currency    
    ,ReceiptApplicationInvoiceId
    ,ReceivableInvoiceId    
    ,PayableId    
    ,IsGLPosted    
    ,IsTaxGLPosted    
    ,RecoveryAmount_Amount    
    ,RecoveryAmount_Currency    
    ,GainAmount_Amount    
    ,GainAmount_Currency    
    ,BookAmountApplied_Amount    
    ,BookAmountApplied_Currency    
    ,SundryPayableId    
    ,SundryReceivableId    
    ,PreviousBookAmountApplied_Amount    
    ,PreviousBookAmountApplied_Currency    
    ,ReceiptApplicationReceivableGroupId 
	,LeaseComponentAmountApplied_Amount
	,LeaseComponentAmountApplied_Currency
	,NonLeaseComponentAmountApplied_Amount
	,NonLeaseComponentAmountApplied_Currency
	,PrevLeaseComponentAmountApplied_Amount
	,PrevLeaseComponentAmountApplied_Currency
	,PrevNonLeaseComponentAmountApplied_Amount
	,PrevNonLeaseComponentAmountApplied_Currency
	,AdjustedWithholdingTax_Amount
	,AdjustedWithholdingTax_Currency
	,ReceivedAmount_Amount
	,ReceivedAmount_Currency
	,PreviousAdjustedWithHoldingTax_Amount
	,PreviousAdjustedWithHoldingTax_Currency
	,LeaseComponentPrepaidAmount_Amount
	,LeaseComponentPrepaidAmount_Currency
	,NonLeaseComponentPrepaidAmount_Amount
	,NonLeaseComponentPrepaidAmount_Currency
	,WithHoldingTaxBookAmountApplied_Amount
	,WithHoldingTaxBookAmountApplied_Currency
	,ReceivedTowardsInterest_Amount
	,ReceivedTowardsInterest_Currency
	,PrepaidAmount_Amount
	,PrepaidAmount_Currency
	,PrepaidTaxAmount_Amount
	,PrepaidTaxAmount_Currency
)    

OUTPUT INSERTED.Id,INSERTED.ReceivableDetailId,INSERTED.AmountApplied_Amount,INSERTED.LeaseComponentAmountApplied_Amount,INSERTED.NonLeaseComponentAmountApplied_Amount into #RARD_Temp
SELECT     
    #ReceiptApplicationReceivableDetail.ReceivableDetailBalanceAmount,    
    #ReceiptApplicationReceivableDetail.Currency,  
    #ReceiptApplicationReceivableDetail.ReceivableTaxBalanceAmount,    
    #ReceiptApplicationReceivableDetail.Currency,  
    CAST(1 AS BIT),    
    @UserId,    
    @CreatedTime,    
    ReceivableDetailId,    
    #CreatedReceiptApplicationIds.InsertedReceiptApplicationId,    
    #ReceiptApplicationReceivableDetail.ReceivableDetailBalanceAmount,    
    #ReceiptApplicationReceivableDetail.Currency,    
    CAST(0 AS BIT),    
    #ReceiptApplicationReceivableDetail.ReceivableTaxBalanceAmount,    
    #ReceiptApplicationReceivableDetail.Currency,    
    NULL,               
	#ReceiptApplicationReceivableDetail.ReceivableInvoiceId,
    NULL,    
    IsGLPosted,    
    IsTaxGLPosted,    
    0.0,    
    #ReceiptApplicationReceivableDetail.Currency,  
    0.0,    
    #ReceiptApplicationReceivableDetail.Currency,  
    0.0,    
    #ReceiptApplicationReceivableDetail.Currency,  
    NULL,    
    NULL,    
    0.0,    
    #ReceiptApplicationReceivableDetail.Currency,  
    NULL,
    ISNULL(ROUND(((#ReceiptApplicationReceivableDetail.ReceivableDetailBalanceAmount * #ReceiptApplicationReceivableDetail.ReceivableDetailLeaseBalanceAmount)/NULLIF(#ReceiptApplicationReceivableDetail.ReceivableDetailLeaseBalanceAmount + #ReceiptApplicationReceivableDetail.ReceivableDetailNonLeaseBalanceAmount,0)),2),0.00), 
    #ReceiptApplicationReceivableDetail.Currency,
	ISNULL(ROUND(((#ReceiptApplicationReceivableDetail.ReceivableDetailBalanceAmount * #ReceiptApplicationReceivableDetail.ReceivableDetailNonLeaseBalanceAmount)/NULLIF(#ReceiptApplicationReceivableDetail.ReceivableDetailLeaseBalanceAmount + #ReceiptApplicationReceivableDetail.ReceivableDetailNonLeaseBalanceAmount,0)),2),0.00),     
    #ReceiptApplicationReceivableDetail.Currency,
	ISNULL(ROUND(((#ReceiptApplicationReceivableDetail.ReceivableDetailBalanceAmount * #ReceiptApplicationReceivableDetail.ReceivableDetailLeaseBalanceAmount)/NULLIF(#ReceiptApplicationReceivableDetail.ReceivableDetailLeaseBalanceAmount + #ReceiptApplicationReceivableDetail.ReceivableDetailNonLeaseBalanceAmount,0)),2),0.00),    
    #ReceiptApplicationReceivableDetail.Currency,
	ISNULL(ROUND(((#ReceiptApplicationReceivableDetail.ReceivableDetailBalanceAmount * #ReceiptApplicationReceivableDetail.ReceivableDetailNonLeaseBalanceAmount)/NULLIF(#ReceiptApplicationReceivableDetail.ReceivableDetailLeaseBalanceAmount + #ReceiptApplicationReceivableDetail.ReceivableDetailNonLeaseBalanceAmount,0)),2),0.00),        
    #ReceiptApplicationReceivableDetail.Currency,
	0.0,    
    #ReceiptApplicationReceivableDetail.Currency,  
	0.0,    
    #ReceiptApplicationReceivableDetail.Currency,  
	0.0,    
    #ReceiptApplicationReceivableDetail.Currency,
	0.0,
	#ReceiptApplicationReceivableDetail.Currency,
	0.0,
	#ReceiptApplicationReceivableDetail.Currency,
	0.0,
	#ReceiptApplicationReceivableDetail.Currency,
	0.0,
	#ReceiptApplicationReceivableDetail.Currency,
	0.0,
	#ReceiptApplicationReceivableDetail.Currency,
	0.0,
	#ReceiptApplicationReceivableDetail.Currency
FROM  
	#CreatedReceiptIds  
	INNER JOIN #CreatedReceiptApplicationIds 
		ON #CreatedReceiptIds.InsertedReceiptId = #CreatedReceiptApplicationIds.InsertedReceiptId  
	INNER JOIN #ReceiptApplicationReceivableDetail 
		ON #ReceiptApplicationReceivableDetail.ReceiptId = #CreatedReceiptIds.Id
		AND #ReceiptApplicationReceivableDetail.IsPartialReceipt = 0;  
INSERT INTO ReceiptApplicationReceivableDetails    
(    
     AmountApplied_Amount    
    ,AmountApplied_Currency    
    ,TaxApplied_Amount    
    ,TaxApplied_Currency    
    ,IsActive    
    ,CreatedById    
    ,CreatedTime    
    ,ReceivableDetailId    
    ,ReceiptApplicationId    
    ,PreviousAmountApplied_Amount    
    ,PreviousAmountApplied_Currency    
    ,IsReApplication    
    ,PreviousTaxApplied_Amount    
    ,PreviousTaxApplied_Currency    
    ,ReceiptApplicationInvoiceId    
    ,ReceivableInvoiceId    
    ,PayableId    
    ,IsGLPosted    
    ,IsTaxGLPosted    
    ,RecoveryAmount_Amount    
    ,RecoveryAmount_Currency    
    ,GainAmount_Amount    
    ,GainAmount_Currency    
    ,BookAmountApplied_Amount    
    ,BookAmountApplied_Currency    
    ,SundryPayableId    
    ,SundryReceivableId    
    ,PreviousBookAmountApplied_Amount    
    ,PreviousBookAmountApplied_Currency    
    ,ReceiptApplicationReceivableGroupId 
	,LeaseComponentAmountApplied_Amount
	,LeaseComponentAmountApplied_Currency
	,NonLeaseComponentAmountApplied_Amount
	,NonLeaseComponentAmountApplied_Currency
	,PrevLeaseComponentAmountApplied_Amount
	,PrevLeaseComponentAmountApplied_Currency
	,PrevNonLeaseComponentAmountApplied_Amount
	,PrevNonLeaseComponentAmountApplied_Currency
	,AdjustedWithholdingTax_Amount
	,AdjustedWithholdingTax_Currency
	,ReceivedAmount_Amount
	,ReceivedAmount_Currency
	,PreviousAdjustedWithHoldingTax_Amount
	,PreviousAdjustedWithHoldingTax_Currency
	,LeaseComponentPrepaidAmount_Amount
	,LeaseComponentPrepaidAmount_Currency
	,NonLeaseComponentPrepaidAmount_Amount
	,NonLeaseComponentPrepaidAmount_Currency  
	,WithHoldingTaxBookAmountApplied_Amount
	,WithHoldingTaxBookAmountApplied_Currency  
	,ReceivedTowardsInterest_Amount
	,ReceivedTowardsInterest_Currency
	,PrepaidAmount_Amount
	,PrepaidAmount_Currency
	,PrepaidTaxAmount_Amount
	,PrepaidTaxAmount_Currency
)    
OUTPUT INSERTED.Id,INSERTED.ReceivableDetailId,INSERTED.AmountApplied_Amount,INSERTED.LeaseComponentAmountApplied_Amount,INSERTED.NonLeaseComponentAmountApplied_Amount into #RARD_Temp
SELECT     
    #ReceiptApplicationReceivableDetail.DistributedBalanceAmount,    
    #ReceiptApplicationReceivableDetail.Currency,  
    #ReceiptApplicationReceivableDetail.DistributedTaxAmount,    
    #ReceiptApplicationReceivableDetail.Currency,  
    CAST(1 AS BIT),    
    @UserId,    
    @CreatedTime,    
    ReceivableDetailId,    
    #CreatedReceiptApplicationIds.InsertedReceiptApplicationId,    
    #ReceiptApplicationReceivableDetail.DistributedBalanceAmount,    
    #ReceiptApplicationReceivableDetail.Currency,    
    CAST(0 AS BIT),    
    #ReceiptApplicationReceivableDetail.DistributedTaxAmount,    
    #ReceiptApplicationReceivableDetail.Currency,    
    NULL,       
	#ReceiptApplicationReceivableDetail.ReceivableInvoiceId,
    NULL,    
    IsGLPosted,    
    IsTaxGLPosted,    
    0.0,    
    #ReceiptApplicationReceivableDetail.Currency,  
    0.0,    
    #ReceiptApplicationReceivableDetail.Currency,  
    0.0,    
    #ReceiptApplicationReceivableDetail.Currency,  
    NULL,    
    NULL,    
    0.0,    
    #ReceiptApplicationReceivableDetail.Currency,  
    NULL,
	ISNULL(ROUND(((#ReceiptApplicationReceivableDetail.DistributedBalanceAmount * #ReceiptApplicationReceivableDetail.ReceivableDetailLeaseBalanceAmount)/NULLIF(#ReceiptApplicationReceivableDetail.ReceivableDetailLeaseBalanceAmount + #ReceiptApplicationReceivableDetail.ReceivableDetailNonLeaseBalanceAmount,0)),2),0.00), 
    #ReceiptApplicationReceivableDetail.Currency,
	ISNULL(ROUND(((#ReceiptApplicationReceivableDetail.DistributedBalanceAmount * #ReceiptApplicationReceivableDetail.ReceivableDetailNonLeaseBalanceAmount)/NULLIF(#ReceiptApplicationReceivableDetail.ReceivableDetailLeaseBalanceAmount + #ReceiptApplicationReceivableDetail.ReceivableDetailNonLeaseBalanceAmount,0)),2),0.00),     
    #ReceiptApplicationReceivableDetail.Currency,
	ISNULL(ROUND(((#ReceiptApplicationReceivableDetail.DistributedBalanceAmount * #ReceiptApplicationReceivableDetail.ReceivableDetailLeaseBalanceAmount)/NULLIF(#ReceiptApplicationReceivableDetail.ReceivableDetailLeaseBalanceAmount + #ReceiptApplicationReceivableDetail.ReceivableDetailNonLeaseBalanceAmount,0)),2),0.00),    
    #ReceiptApplicationReceivableDetail.Currency,
	ISNULL(ROUND(((#ReceiptApplicationReceivableDetail.DistributedBalanceAmount * #ReceiptApplicationReceivableDetail.ReceivableDetailNonLeaseBalanceAmount)/NULLIF(#ReceiptApplicationReceivableDetail.ReceivableDetailLeaseBalanceAmount + #ReceiptApplicationReceivableDetail.ReceivableDetailNonLeaseBalanceAmount,0)),2),0.00),        
    #ReceiptApplicationReceivableDetail.Currency,
	0.0,    
    #ReceiptApplicationReceivableDetail.Currency,   
	0.0,    
    #ReceiptApplicationReceivableDetail.Currency,   
	0.0,    
    #ReceiptApplicationReceivableDetail.Currency,
	0.0,
	#ReceiptApplicationReceivableDetail.Currency,
	0.0,
    #ReceiptApplicationReceivableDetail.Currency,
	0.0,
	#ReceiptApplicationReceivableDetail.Currency,
	0.0,
	#ReceiptApplicationReceivableDetail.Currency,
	0.0,
	#ReceiptApplicationReceivableDetail.Currency,
	0.0,
	#ReceiptApplicationReceivableDetail.Currency

FROM  
	#CreatedReceiptIds  
	INNER JOIN #CreatedReceiptApplicationIds 
		ON #CreatedReceiptIds.InsertedReceiptId = #CreatedReceiptApplicationIds.InsertedReceiptId  
	INNER JOIN #ReceiptApplicationReceivableDetail 
		ON #ReceiptApplicationReceivableDetail.ReceiptId = #CreatedReceiptIds.Id
		AND #ReceiptApplicationReceivableDetail.IsPartialReceipt = 1;
INSERT INTO ReceiptApplicationReceivableTaxImpositions    
(    
    AmountPosted_Amount,     
    AmountPosted_Currency,     
    ReceivableTaxImpositionId,     
    ReceiptApplicationId,     
    CreatedById,     
    CreatedTime,     
    IsActive    
)     
SELECT   
    #ReceiptApplicationReceivableTaxImposition.BalanceAmount AS AmountPosted_Amount,    
    #ReceiptApplicationReceivableTaxImposition.Currency AS AmountPosted_Currency,     
    #ReceiptApplicationReceivableTaxImposition.ReceivableTaxImpositionId AS ReceivableTaxImpositionId,     
    #CreatedReceiptApplicationIds.InsertedReceiptApplicationId As ReceiptApplicationId,    
    @UserId AS CreatedById,    
    @CreatedTime AS CreatedTime,     
    1 AS IsActive     
FROM     
	#CreatedReceiptIds  
	INNER JOIN #CreatedReceiptApplicationIds 
		ON #CreatedReceiptIds.InsertedReceiptId = #CreatedReceiptApplicationIds.InsertedReceiptId  
	INNER JOIN #ReceiptApplicationReceivableTaxImposition 
		ON #CreatedReceiptIds.Id = #ReceiptApplicationReceivableTaxImposition.ReceiptId  
		And #ReceiptApplicationReceivableTaxImposition.BalanceAmount <> 0  
SELECT  
	ReceiptId  
	,CASE WHEN IsPartialReceipt = 0 THEN SUM(ISNULL(ReceivableDetailBalanceAmount,0)) ELSE SUM(ISNULL(DistributedBalanceAmount,0)) END As AmountApplied  
	,Currency  
	,CASE WHEN IsPartialReceipt = 0 THEN SUM(ISNULL(ReceivableTaxBalanceAmount,0)) ELSE SUM(ISNULL(DistributedTaxAmount,0)) END As TaxApplied  
	,ReceivableInvoiceId          
INTO #ReceivableInvoiceReceiptDetails
FROM   
	#ReceiptApplicationReceivableDetail 
WHERE 
	ReceivableInvoiceId IS NOT NULL 
GROUP BY 
	 ReceiptId
	,ReceivableInvoiceId
	,Currency
	,IsPartialReceipt    
INSERT INTO ReceivableInvoiceReceiptDetails     
(  
	ReceiptId,   
	ReceivedDate,   
	IsActive,   
	ReceivableInvoiceId,  
	AmountApplied_Amount,   
	AmountApplied_Currency,   
	TaxApplied_Amount,   
	TaxApplied_Currency,    
	CreatedById,   
	CreatedTime  
)    
SELECT   
	#CreatedReceiptIds.InsertedReceiptId As ReceiptId,  
	RMD.ReceivedDate As ReceivedDate,  
	1,  
	ReceivableInvoiceId,  
	ReceivableInvoiceReceiptDetails.AmountApplied As AmountApplied_Amount,  
	ReceivableInvoiceReceiptDetails.Currency As AmountApplied_Currency,  
	ReceivableInvoiceReceiptDetails.TaxApplied As TaxApplied_Amount,  
	ReceivableInvoiceReceiptDetails.Currency As TaxApplied_Currency,  
	@UserId,  
	@CreatedTime    
FROM   
	#CreatedReceiptIds  
	INNER JOIN #CreatedReceiptApplicationIds 
		ON #CreatedReceiptIds.InsertedReceiptId = #CreatedReceiptApplicationIds.InsertedReceiptId       
	INNER JOIN #ReceivableInvoiceReceiptDetails ReceivableInvoiceReceiptDetails
		ON ReceivableInvoiceReceiptDetails.ReceiptId = #CreatedReceiptIds.Id
	INNER JOIN #ReceiptMigrationDetails As RMD 
		ON RMD.Id = #CreatedReceiptIds.Id  

	
    INSERT INTO #RARD_Extracts(RARD_ExtractId,ReceivableDetailId,Amount_Amount,ComponentType,RowNumber)
    SELECT RARD_ExtractId,ReceivableDetailId,LeaseComponentAmountApplied AS Amount_Amount,'Lease',
	CASE WHEN LeaseComponentAmountApplied >= NonLeaseComponentAmountApplied THEN 1 ELSE 2 END AS RowNumber
	FROM #RARD_Temp RE
    UNION ALL
	SELECT RARD_ExtractId,ReceivableDetailId,NonLeaseComponentAmountApplied AS Amount_Amount,'NonLease',
	CASE WHEN NonLeaseComponentAmountApplied > LeaseComponentAmountApplied THEN 1 ELSE 2 END AS RowNumber
	FROM #RARD_Temp RE
	
	 UPDATE #RARD_Extracts
	SET Amount_Amount = Amount_Amount + RoundingValue
	OUTPUT INSERTED.RARD_ExtractId INTO #UpdatedRARDTemp
	FROM #RARD_Extracts
	JOIN (
	        SELECT #RARD_Temp.RARD_ExtractId,(#RARD_Temp.AmountApplied - SUM(Amount_Amount)) DifferenceAfterDistribution,
			CASE WHEN (#RARD_Temp.AmountApplied - SUM(Amount_Amount)) < 0 THEN -(@RoundingValue) ELSE @RoundingValue END AS RoundingValue
		    FROM  #RARD_Temp
			JOIN #RARD_Extracts ON #RARD_Temp.RARD_ExtractId = #RARD_Extracts.RARD_ExtractId
			GROUP BY  #RARD_Temp.ReceivableDetailId,#RARD_Temp.RARD_ExtractId,#RARD_Temp.AmountApplied
			HAVING #RARD_Temp.AmountApplied <> SUM(Amount_Amount)
         ) AS AppliedRARD_Extracts
		 ON #RARD_Extracts.RARD_ExtractId = AppliedRARD_Extracts.RARD_ExtractId
    WHERE  (#RARD_Extracts.RowNumber <= CAST(AppliedRARD_Extracts.DifferenceAfterDistribution/RoundingValue AS BIGINT)
	     AND AppliedRARD_Extracts.RARD_ExtractId = #RARD_Extracts.RARD_ExtractId)

	UPDATE ReceiptApplicationReceivableDetails
       SET LeaseComponentAmountApplied_Amount = CASE WHEN #RARD_Extracts.ComponentType = 'Lease' THEN #RARD_Extracts.Amount_Amount ELSE LeaseComponentAmountApplied_Amount END
	      ,PrevLeaseComponentAmountApplied_Amount = CASE WHEN #RARD_Extracts.ComponentType = 'Lease' THEN #RARD_Extracts.Amount_Amount ELSE PrevLeaseComponentAmountApplied_Amount END
         ,NonLeaseComponentAmountApplied_Amount = CASE WHEN #RARD_Extracts.ComponentType = 'NonLease' THEN #RARD_Extracts.Amount_Amount ELSE NonLeaseComponentAmountApplied_Amount END
		 ,PrevNonLeaseComponentAmountApplied_Amount = CASE WHEN #RARD_Extracts.ComponentType = 'NonLease' THEN #RARD_Extracts.Amount_Amount ELSE PrevNonLeaseComponentAmountApplied_Amount END
    FROM #RARD_Extracts
    INNER JOIN ReceiptApplicationReceivableDetails RARD ON #RARD_Extracts.RARD_ExtractId = RARD.Id
    INNER JOIN #UpdatedRARDTemp ON RARD.Id = #UpdatedRARDTemp.Id

UPDATE Receivables    
SET TotalEffectiveBalance_Amount = 0.0,    
    TotalBalance_Amount = 0.0,    
    TotalBookBalance_Amount = 0.0,    
    UpdatedTime = @CreatedTime,    
    UpdatedById = @UserId  
    FROM Receivables RC    
    INNER JOIN (SELECT    
        ReceiptId,ReceivableId    
    FROM    
    #ReceiptApplicationReceivableDetail where IsPartialReceipt = 0 And IsCounterForReceiptPosting=1 GROUP BY ReceiptId,ReceivableId ) AS ReceivableBalances ON RC.Id = ReceivableBalances.ReceivableId    
    Inner JOIN #CreatedReceiptIds On #CreatedReceiptIds.Id = ReceivableBalances.ReceiptId;
	UPDATE Receivables    
    SET TotalEffectiveBalance_Amount = TotalEffectiveBalance_Amount - ReceivableBalanceAmount,    
    TotalBalance_Amount = TotalBalance_Amount - ReceivableBalanceAmount,    
    TotalBookBalance_Amount = 0.0, 
    UpdatedTime = @CreatedTime,    
    UpdatedById = @UserId  
    FROM Receivables RC    
    INNER JOIN (SELECT    
        ReceiptId,ReceivableId, SUM(DistributedBalanceAmount)As ReceivableBalanceAmount    
    FROM    
    #ReceiptApplicationReceivableDetail where IsPartialReceipt = 1 And IsCounterForReceiptPosting=1 Group By ReceiptId,ReceivableId ) AS ReceivableBalances ON RC.Id = ReceivableBalances.ReceivableId    
    Inner JOIN #CreatedReceiptIds On #CreatedReceiptIds.Id = ReceivableBalances.ReceiptId    
UPDATE ReceivableDetails    
    SET EffectiveBalance_Amount = EffectiveBalance_Amount - (CASE WHEN IsPartialReceipt=0 THEN RARD.ReceivableDetailBalanceAmount ELSE RARD.DistributedBalanceAmount END),    
    Balance_Amount = Balance_Amount - (CASE WHEN IsPartialReceipt=0 THEN RARD.ReceivableDetailBalanceAmount ELSE RARD.DistributedBalanceAmount END),    
	LeaseComponentBalance_Amount = LeaseComponentBalance_Amount - RARD.LeaseComponentAmountApplied,
	NonLeaseComponentBalance_Amount = NonLeaseComponentBalance_Amount - RARD.NonLeaseComponentAmountApplied,
    EffectiveBookBalance_Amount = 0.0,
    UpdatedById = @UserId,    
    UpdatedTime = @CreatedTime    
FROM ReceivableDetails RD           
Inner JOIN #ReceiptApplicationReceivableDetail As RARD  ON RD.Id = RARD.ReceivableDetailId AND IsCounterForReceiptPosting=1   
Inner JOIN #CreatedReceiptIds On #CreatedReceiptIds.Id = RARD.ReceiptId  
UPDATE ReceivableTaxes    
SET EffectiveBalance_Amount = 0.0,    
    Balance_Amount =0.0,    
    UpdatedTime = @CreatedTime,    
    UpdatedById = @UserId    
FROM    
ReceivableTaxes RT                    
Inner Join 
(
	SELECT    
		ReceiptId,ReceivableId
    FROM    
    #ReceiptApplicationReceivableDetail Where IsPartialReceipt=0 Group By  ReceiptId,ReceivableId 
)As RARI On RARI.ReceivableId = RT.ReceivableId 
Inner JOIN #CreatedReceiptIds On #CreatedReceiptIds.Id = RARI.ReceiptId  
UPDATE ReceivableTaxes    
SET EffectiveBalance_Amount = EffectiveBalance_Amount - ReceivableBalanceAmount,    
    Balance_Amount = Balance_Amount - ReceivableBalanceAmount,    
    UpdatedTime = @CreatedTime,    
    UpdatedById = @UserId    
FROM    
ReceivableTaxes RT                    
Inner Join 
(
	SELECT    
		ReceiptId,ReceivableTaxId, SUM(DistributedBalanceAmount)As ReceivableBalanceAmount    
    FROM    
    #ReceiptWithReceivableTaxImposition Group By  ReceiptId,ReceivableTaxId 
)As RARI On RARI.ReceivableTaxId = RT.Id 
Inner JOIN #CreatedReceiptIds On #CreatedReceiptIds.Id = RARI.ReceiptId          
UPDATE ReceivableTaxDetails    
    SET EffectiveBalance_Amount = 0.0,    
    Balance_Amount = 0.0,    
    UpdatedById = @UserId,    
    UpdatedTime = @CreatedTime    
FROM ReceivableTaxDetails TaxDetail 
Inner Join 
(
	SELECT    
		ReceiptId,ReceivableDetailId
    FROM    
    #ReceiptApplicationReceivableDetail Where IsPartialReceipt=0 Group By  ReceiptId,ReceivableDetailId 
)As RARI On RARI.ReceivableDetailId = TaxDetail.ReceivableDetailId           
Inner JOIN #CreatedReceiptIds On #CreatedReceiptIds.Id = RARI.ReceiptId  
WHERE TaxDetail.IsActive=1 	 
UPDATE ReceivableTaxDetails    
    SET EffectiveBalance_Amount = EffectiveBalance_Amount - ReceiptWithReceivableTaxDetail.DistributedTaxBalanceAmount,    
    Balance_Amount = Balance_Amount - ReceiptWithReceivableTaxDetail.DistributedTaxBalanceAmount,    
    UpdatedById = @UserId,    
    UpdatedTime = @CreatedTime    
FROM ReceivableTaxDetails TaxDetail    
Inner Join 
(
	Select ReceiptId,ReceivableTaxDetailId, Sum(DistributedBalanceAmount) As DistributedTaxBalanceAmount From #ReceiptWithReceivableTaxImposition Group By ReceiptId,ReceivableTaxDetailId
)As ReceiptWithReceivableTaxDetail On ReceiptWithReceivableTaxDetail.ReceivableTaxDetailId = TaxDetail.Id
Inner JOIN #CreatedReceiptIds On #CreatedReceiptIds.Id = ReceiptWithReceivableTaxDetail.ReceiptId  	  
WHERE TaxDetail.IsActive=1   	                   
UPDATE ReceivableTaxImpositions    
SET Balance_Amount = Balance_Amount - RARTI.BalanceAmount,    
    EffectiveBalance_Amount = EffectiveBalance_Amount - RARTI.BalanceAmount    
FROM    
ReceivableTaxImpositions RTI    
Inner Join  ( SELECT    
	ReceiptId,ReceivableTaxImpositionId, BalanceAmount    
    FROM    
    #ReceiptApplicationReceivableTaxImposition ) AS RARTI On RTI.Id = RARTI.ReceivableTaxImpositionId And RTI.IsActive=1   
Inner JOIN #CreatedReceiptIds On #CreatedReceiptIds.Id = RARTI.ReceiptId  
UPDATE ReceivableInvoiceDetails    
SET Balance_Amount = 0.0,    
    EffectiveBalance_Amount = 0.0,    
    TaxBalance_Amount = 0.0,    
    EffectiveTaxBalance_Amount = 0.0  ,  
    UpdatedById = @UserId,    
    UpdatedTime = @CreatedTime    
FROM     
ReceivableInvoiceDetails RID    
    INNER JOIN ( SELECT    
			ReceiptId, ReceivableInvoiceId, ReceivableDetailId     
    FROM    
    #ReceiptApplicationReceivableDetail Where ReceivableInvoiceId Is NOT NULL AND IsPartialReceipt=0 And IsCounterForReceiptPosting=1) AS ReceivableInv On RID.ReceivableInvoiceId = ReceivableInv.ReceivableInvoiceId 
	And RID.ReceivableDetailId = ReceivableInv.ReceivableDetailId
	And RID.IsActive=1  
    Inner JOIN #CreatedReceiptIds On #CreatedReceiptIds.Id = ReceivableInv.ReceiptId ;
UPDATE ReceivableInvoiceDetails    
SET Balance_Amount = Balance_Amount - DistributedBalanceAmount,    
    EffectiveBalance_Amount = EffectiveBalance_Amount - DistributedBalanceAmount,    
    TaxBalance_Amount = TaxBalance_Amount - DistributedTaxAmount,    
    EffectiveTaxBalance_Amount = EffectiveTaxBalance_Amount - DistributedTaxAmount,  
    UpdatedById = @UserId,    
    UpdatedTime = @CreatedTime    
FROM     
ReceivableInvoiceDetails RID    
    INNER JOIN ( SELECT    
			ReceiptId, ReceivableInvoiceId, ReceivableDetailId, DistributedBalanceAmount, DistributedTaxAmount    
    FROM    
    #ReceiptApplicationReceivableDetail Where ReceivableInvoiceId Is NOT NULL AND IsPartialReceipt=1 And IsCounterForReceiptPosting=1) AS ReceivableInv On RID.ReceivableInvoiceId = ReceivableInv.ReceivableInvoiceId 
	And RID.ReceivableDetailId = ReceivableInv.ReceivableDetailId
	And RID.IsActive=1  
    Inner JOIN #CreatedReceiptIds On #CreatedReceiptIds.Id = ReceivableInv.ReceiptId  
UPDATE ReceivableInvoices    
SET Balance_Amount = CASE WHEN IsPartialReceipt = 0 THEN Balance_Amount - ReceivableDetailBalance ELSE Balance_Amount - DistributedBalanceAmount END,    
    EffectiveBalance_Amount = CASE WHEN IsPartialReceipt = 0 THEN EffectiveBalance_Amount - ReceivableDetailBalance ELSE EffectiveBalance_Amount - DistributedBalanceAmount END,        
    TaxBalance_Amount = CASE WHEN IsPartialReceipt = 0 THEN TaxBalance_Amount - ReceivableTaxBalance ELSE TaxBalance_Amount - DistributedTaxAmount END,    
    EffectiveTaxBalance_Amount = CASE WHEN IsPartialReceipt = 0 THEN EffectiveTaxBalance_Amount - ReceivableTaxBalance ELSE EffectiveTaxBalance_Amount - DistributedTaxAmount END,    
    UpdatedById = @UserId,    
    UpdatedTime = @CreatedTime    
FROM     
    ReceivableInvoices RI    
    INNER JOIN ( SELECT    
        ReceiptId,ReceivableInvoiceId, SUM(ReceivableDetailBalanceAmount) As ReceivableDetailBalance, SUM(ReceivableTaxBalanceAmount) As ReceivableTaxBalance, SUM(DistributedBalanceAmount) As DistributedBalanceAmount, SUM(DistributedTaxAmount) As DistributedTaxAmount, IsPartialReceipt      
    FROM    
    #ReceiptApplicationReceivableDetail Where ReceivableInvoiceId Is NOT NULL And IsCounterForReceiptPosting=1 GROUP BY ReceiptId,ReceivableInvoiceId, IsPartialReceipt) AS ReceivableInv On RI.Id = ReceivableInv.ReceivableInvoiceId And RI.IsActive=1   
    Inner JOIN #CreatedReceiptIds On #CreatedReceiptIds.Id = ReceivableInv.ReceiptId 
UPDATE     
ReceivableInvoices    
SET    
LastReceivedDate = RMD.ReceivedDate,    
UpdatedById = @UserId,     
UpdatedTime = @CreatedTime     
FROM   
ReceivableInvoices    
INNER JOIN ( SELECT    
    Distinct ReceiptId ,ReceivableInvoiceId    
    FROM    
    #ReceiptApplicationReceivableDetail Where ReceivableInvoiceId Is NOT NULL And IsCounterForReceiptPosting=1) AS ReceivableInv On ReceivableInvoices.Id = ReceivableInv.ReceivableInvoiceId And ReceivableInvoices.IsActive=1   
Inner Join (Select Id As ReceiptId, ReceivedDate From #ReceiptMigrationDetails) As RMD On RMD.ReceiptId = ReceivableInv.ReceiptId  
WHERE  
ReceivableInvoices.LastReceivedDate IS NULL OR   
ReceivableInvoices.LastReceivedDate < RMD.ReceivedDate  
Update stgDummyReceipt Set IsMigrated = 1  
From stgDummyReceipt R  
Inner join #CreatedReceiptIds On #CreatedReceiptIds.Id = R.Id  
MERGE stgProcessingLog AS ProcessingLog  
USING (SELECT Id As ReceiptId FROM #CreatedReceiptIds      
    ) AS ProcessedReceipts  
ON (ProcessingLog.StagingRootEntityId = ProcessedReceipts.ReceiptId AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)  
WHEN MATCHED THEN  
UPDATE SET UpdatedTime = @CreatedTime  
WHEN NOT MATCHED THEN  
INSERT  
(  
    StagingRootEntityId  
    ,CreatedById  
    ,CreatedTime  
    ,ModuleIterationStatusId  
)  
VALUES  
(  
    ProcessedReceipts.ReceiptId  
    ,@UserId  
    ,@CreatedTime  
    ,@ModuleIterationStatusId  
)  
OUTPUT $action, Inserted.Id INTO #CreatedProcessingLogs;  
INSERT INTO stgProcessingLogDetail  
(  
Message  
    ,Type  
    ,CreatedById  
    ,CreatedTime   
    ,ProcessingLogId  
)  
SELECT  
'Successful'  
    ,'Information'  
    ,@UserId  
    ,@CreatedTime  
    ,Id  
FROM  
#CreatedProcessingLogs  
IF(SELECT MAX(ID) FROM stgDummyReceipt WHERE IsMigrated=0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier) And IsFailed=0) <= @MaxId
	SET @Count = 0
ELSE 
	SELECT @COUNT = Count(*) FROM stgDummyReceipt WHERE IsMigrated=0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier) And IsFailed=0;
	IF EXISTS(SELECT Id FROM #CreatedReceiptIds)
	BEGIN
	SET @Number = (SELECT MAX(Id) FROM #CreatedReceiptIds)
	END
	IF(@IsCloneDone = 0)
	BEGIN
	SET @SQL = 'ALTER SEQUENCE Receipt RESTART WITH ' + CONVERT(NVARCHAR(20),@Number+1)
	EXEC sp_executesql @sql
	END
DROP TABLE #ErrorLogs;        
DROP TABLE #CreatedReceiptIds;  
DROP TABLE #FailedProcessingLogs;  
DROP TABLE #CreatedProcessingLogs  
DROP TABLE #ProcessableReceipts;  
DROP TABLE #CreatedReceiptApplicationIds  
DROP TABLE #ReceiptMigrationDetails;  
DROP TABLE #ReceiptNumbersForReceipt;  
DROP TABLE #ReceiptApplicationReceivableDetailInfo;  
DROP TABLE #ReceiptsWithCalReceivableAmount;  
DROP TABLE #ReceiptApplicationReceivableDetail;  
DROP TABLE #ReceiptWithReceivableTaxImposition
DROP TABLE #ReceiptApplicationReceivableTaxImposition;  
DROP TABLE #ReceivableInvoiceReceiptDetails
End  
  Set @ProcessedRecords = @ProcessedRecords + @TotalRecordsCount;  
  Drop Table #DuplicatedReceipts;  
  Drop Table #LegalEntityBankAccountDetails; 
  DROP Table #ReceivableTypeOrder;  
  DROP TABLE #RARD_ExtractTemp;
  DROP TABLE #RARD_Extracts;
  DROP TABLE #UpdatedRARDTemp;

 End  
End

GO

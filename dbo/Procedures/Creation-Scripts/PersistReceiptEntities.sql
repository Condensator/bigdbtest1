SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PersistReceiptEntities]
(
@ReceiptParam ReceiptParam READONLY,
@ReceiptAllocationParam ReceiptAllocationParam READONLY,
@ReceiptApplicationParam ReceiptApplicationParam READONLY,
@ReceiptApplicationInvoiceParam ReceiptApplicationInvoiceParam READONLY,
@ReceiptApplicationReceivableGroupParam ReceiptApplicationReceivableGroupParam READONLY,
@ReceiptApplicationReceivableDetailParam ReceiptApplicationReceivableDetailParam READONLY,
@ReceiptJournalParam ReceiptJournalParam READONLY,
@ReceiptJournalDetailParam ReceiptJournalDetailParam READONLY,
@SundryParam SundryParam READONLY,
@CPUParam CPUParam READONLY,
@OTPCashBasedReceivableParam OTPCashBasedReceivableParam READONLY,
@CurrencyISO NVARCHAR(3),
@IsReceiptInNewMode BIT,
@IsReversal BIT,
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET,
@SundrySourceTableValue VARCHAR(24),
@SundryRecurringSourceTableValue VARCHAR(24),
@RecoveryStatusValue VARCHAR(20),
@RecoveryReportStatusValue VARCHAR(100),
@DoNotAssessTaxForTaxExemptSundries BIT,
@IsSalesTaxRequiredForLoan BIT,
@PayableStatusValueForReceipt VARCHAR(25)
)
AS
BEGIN
SET NOCOUNT ON
--BEGIN TRAN T
DECLARE @ReceiptId BIGINT;
DECLARE @ContractId BIGINT;
DECLARE @ReceiptApplicationId BIGINT;
DECLARE @ApplyByReceivable BIT;
DECLARE @CurrentReceiptBatchId BIGINT;
DECLARE @ReceivableDisplayOption NVARCHAR(24);
DECLARE @ReceivedDate DATE;
DECLARE @PostDate DATE;
DECLARE @IsSelfTaxAssessed BIT = @DoNotAssessTaxForTaxExemptSundries --ISNULL((SELECT Value FROM GlobalParameters WHERE Category = 'Sundry' AND Name = 'DoNotAssessTaxForTaxExemptSundries'),0);
--DECLARE @IsSalesTaxRequiredForLoan BIT = @IsSalesTaxRequiredForLoan --ISNULL((SELECT Value FROM GlobalParameters WHERE Category = 'SalesTax' AND Name = 'IsSalesTaxRequiredForLoan'),0);
--DECLARE @PayableStatusValueForReceipt VARCHAR(25) = @ReceiptPayableStatus --ISNULL((SELECT Value FROM GlobalParameters WHERE Category = 'Receipt' AND Name = 'ReceiptPayableStatus'),'Pending');
DECLARE @ReceiptNumber VARCHAR(20);
CREATE TABLE #ReceiptInfo
(
Id BIGINT,
ContractId BIGINT,
ReceivedDate DATE,
PostDate DATE,
ApplyByReceivable BIT,
ReceiptBatchId BIGINT,
Number VARCHAR(20)
)
CREATE TABLE #ReceiptApplicationInvoiceInfo
(
Id BIGINT,
ReceivableInvoiceId BIGINT
)
CREATE TABLE #ReceiptApplicationGroupInfo
(
Id BIGINT,
CustomerId BIGINT,
DueDate DATE,
ReceivableType NVARCHAR(21),
SequenceNumber NVARCHAR(40),
InvoiceNumber NVARCHAR(40)
)
CREATE TABLE #ReceiptApplicationReceivableDetailInfo
(
Id BIGINT,
ReceivableDetailId BIGINT,
ContractId BIGINT,
AmountApplied DECIMAL(16,2),
TaxApplied DECIMAL(16,2),
AccountingTreatment NVARCHAR(12),
IsRental BIT,
RecoveryAmount DECIMAL(16,2),
GainAmount DECIMAL(16,2)
)
CREATE TABLE #GLJournal
(
GLJournalId BIGINT,
SourceId BIGINT,
SourceType VARCHAR(15),
LegalEntityId BIGINT,
PostDate DATE,
IsReversal BIT,
UniqueIdentifier BIGINT,
AssetValueHistoryIds VARCHAR(MAX)
)
CREATE TABLE #OTPGLJournalInfo
(
ID INT IDENTITY(1,1),
GLJournalId BIGINT,
AssetValueHistoryIds VARCHAR(MAX)
)
CREATE TABLE #LeaseIncomeGL
(
ID INT IDENTITY(1,1),
LeaseIncomeScheduleIdsInCSV VARCHAR(MAX)
)
CREATE TABLE #PayableInfo
(
RARDId BIGINT,
ReceivableDetailId BIGINT,
AmountApplied DECIMAL(16,2),
SourceTable VARCHAR(24),
SourceId BIGINT,
DueDate DATE,
PayableCodeId BIGINT,
LegalEntityId BIGINT,
PayableRemitToId BIGINT,
PayeeId BIGINT,
Memo VARCHAR(MAX),
EntityType VARCHAR(2),
ContractId BIGINT,
CustomerId BIGINT,
CurrencyId BIGINT
)
CREATE TABLE #PersistedPayableInfo
(
PayableId BIGINT,
PayableLegalEntityId BIGINT,
PayableEntityType VARCHAR(3),
PayableEntityId BIGINT,
PayeeId BIGINT,
CurrencyId BIGINT,
PayableRemitToId BIGINT,
PayableDueDate DATETIME,
InternalComment NVARCHAR(200),
PayableAmount DECIMAL(16,2),
ReceivableDetailId BIGINT,
SundryId BIGINT,
ContractId BIGINT,
IsScrapePayable BIT
)
CREATE TABLE #PersistedSundryInfo
(
SundryId BIGINT,
SundryType VARCHAR(14),
ReceivableDetailId BIGINT,
IsTaxExempt BIT
)
CREATE TABLE #SyndicatedReceivableInfo
(
ReceivableId BIGINT,
SundryId BIGINT,
Amount DECIMAL(16,2),
BillToId BIGINT,
IsTaxExempt BIT
)
CREATE TABLE #AssetValueHistoryGLMap
(
AssetValueHistoryId BIGINT,
GLJournalId BIGINT
)
CREATE TABLE #ContractNBVWithBlendedInfo
(
ContractId BIGINT,
ContractType NVARCHAR(30),
NBV DECIMAL(16,2),
NBVWithBlended DECIMAL(16,2)
);
CREATE TABLE #WriteDownNBVInfo
(
ContractId BIGINT,
ContractType VARCHAR(14),
LeaseFinanceId BIGINT,
LoanFinanceId BIGINT,
NetInvestmentWithBlended DECIMAL(16,2),
TotalWriteDownAmount DECIMAL(16,2),
TotalRecoveryAmount DECIMAL(16,2),
TotalAmountApplied DECIMAL(16,2),
NetInvestmentWithReserve DECIMAL(16,2),
GLTemplateId BIGINT,
RecoveryReceivableCodeId BIGINT,
RecoveryGLTemplateId BIGINT,
WriteDownReason NVarChar(18)
)
CREATE TABLE #PersistedWriteDownInfo
(
Id BIGINT,
ContractId BIGINT,
RecoveryAmount DECIMAL(16,2),
GLTemplateId BIGINT,
RecoveryGLTemplateId BIGINT,
PostDate DATETIME,
LeaseFinanceId BIGINT,
LoanFinanceId BIGINT
)
CREATE TABLE #CPUPayableIds
(
Id BIGINT,
ReceivableDetailId BIGINT
);
CREATE TABLE #ReceivableDetailsComponent
(
	LeaseComponentAmount     DECIMAL(16, 2), 
	NonLeaseComponentAmount  DECIMAL(16, 2), 
	ReceivableDetailId       BIGINT
);
DECLARE @ContractIds RecoveredContractIdCollection;
DECLARE @RecentTransactionParams RecentTransactionParameters;
INSERT INTO Receipts
(
Number
,ReceiptAmount_Amount
,ReceiptAmount_Currency
,EntityType
,PostDate
,ReceivedDate
,Status
,ReversalDate
,ReversalPostDate
,CreateRefund
,PayableDate
,DueDate
,CheckNumber
,CheckDate
,NameOnCheck
,BankName
,Comment
,CreatedById
,CreatedTime
,UpdatedById
,UpdatedTime
,LegalEntityId
,CurrencyId
,BankAccountId
,TypeId
,ContractId
,LineofBusinessId
,InstrumentTypeId
,ReceiptBatchId
,ReceiptGLTemplateId
,ReversalReasonId
,VendorId
,PayableCodeId
,PayableRemitToId
,BillToId
,ReceivableCodeId
,CustomerId
,Balance_Amount
,Balance_Currency
,ApplyByReceivable
,NonCashReason
,ReceivableRemitToId
,SundryId
,IsFromReceiptBatch
,LocationId
,ReceiptClassification
,EscrowGLTemplateId
,SecurityDepositLiabilityContractAmount_Amount
,SecurityDepositLiabilityContractAmount_Currency
,SecurityDepositLiabilityAmount_Amount
,SecurityDepositLiabilityAmount_Currency
,CashTypeId
,IsReceiptCreatedFromLockBox
,CostCenterId
)
OUTPUT inserted.Id,inserted.ContractId,inserted.ReceivedDate,inserted.PostDate,inserted.ApplyByReceivable,inserted.ReceiptBatchId,inserted.Number into #ReceiptInfo
SELECT
Number
, ReceiptAmount
, @CurrencyISO
, EntityType
, PostDate
, ReceivedDate
, Status
, ReversalDate
, ReversalPostDate
, CreateRefund
, PayableDate
, DueDate
, CheckNumber
, CheckDate
, NameOnCheck
, BankName
, Comment
, @CreatedById
, @CreatedTime
, NULL
, NULL
, LegalEntityId
, CurrencyId
, BankAccountId
, TypeId
, ContractId
, LineofBusinessId
, InstrumentTypeId
, ReceiptBatchId
, ReceiptGLTemplateId
, ReversalReasonId
, VendorId
, PayableCodeId
, PayableRemitToId
, BillToId
, ReceivableCodeId
, CustomerId
, Balance
, @CurrencyISO
, ApplyByReceivable
, NonCashReason
, ReceivableRemitToId
, SundryId
, IsFromReceiptBatch
, LocationId
, ReceiptClassification
, EscrowGLTemplateId
, SecurityDepositLiabilityContractAmount
, @CurrencyISO
, SecurityDepositLiabilityAmount
, @CurrencyISO
, CashTypeId
, 0
,CostCenterId
FROM
@ReceiptParam
SELECT @ReceiptId = Id,@CurrentReceiptBatchId = ReceiptBatchId,@ContractId = ContractId,@ReceivedDate = ReceivedDate,@PostDate =PostDate,@ReceiptNumber = Number,@ApplyByReceivable = ApplyByReceivable
FROM #ReceiptInfo
INSERT INTO ReceiptAllocations
(EntityType
,AllocationAmount_Amount
,AllocationAmount_Currency
,Description
,IsActive
,CreatedById
,CreatedTime
,UpdatedById
,UpdatedTime
,LegalEntityId
,ContractId
,ReceiptId
,AmountApplied_Amount
,AmountApplied_Currency)
SELECT
EntityType
,AllocationAmount
,@CurrencyISO
,Description
,1
,@CreatedById
,@CreatedTime
,NULL
,NULL
,LegalEntityId
,ContractId
,@ReceiptId
,AmountApplied
,@CurrencyISO
FROM
@ReceiptAllocationParam
INSERT INTO ReceiptApplications
(
PostDate
,Comment
,AmountApplied_Amount
,AmountApplied_Currency
,IsFullCash
,CreatedById
,CreatedTime
,UpdatedById
,UpdatedTime
,ReceiptId
,CreditApplied_Amount
,CreditApplied_Currency
,ReceivableDisplayOption
)
SELECT
PostDate
, Comment
, AmountApplied
, @CurrencyISO
, IsFullCash
, @CreatedById
, @CreatedTime
, NULL
, NULL
, @ReceiptId
, CreditApplied
, @CurrencyISO
, ReceivableDisplayOption
FROM
@ReceiptApplicationParam
SET @ReceiptApplicationId = SCOPE_IDENTITY()
SET @ReceivableDisplayOption = (SELECT TOP 1 ReceivableDisplayOption FROM ReceiptApplications WHERE Id = @ReceiptApplicationId);
INSERT INTO ReceiptApplicationDetails
(
Id
,CreatedById
,CreatedTime
,UpdatedById
,UpdatedTime
,ReceiptApplicationId
)
VALUES
(
@ReceiptId
, @CreatedById
, @CreatedTime
, NULL
, NULL
, @ReceiptApplicationId
)
IF(@ApplyByReceivable = 0)
BEGIN
INSERT INTO ReceiptApplicationInvoices
(
AmountApplied_Amount
,AmountApplied_Currency
,TaxApplied_Amount
,TaxApplied_Currency
,IsActive
,PreviousAmountApplied_Amount
,PreviousAmountApplied_Currency
,PreviousTaxApplied_Amount
,PreviousTaxApplied_Currency
,IsReApplication
,CreatedById
,CreatedTime
,UpdatedById
,UpdatedTime
,ReceivableInvoiceId
,ReceiptApplicationId
,AdjustedWithHoldingTax_Amount
,AdjustedWithHoldingTax_Currency
,ReceivedAmount_Amount
,ReceivedAmount_Currency
,PreviousAdjustedWithHoldingTax_Amount
,PreviousAdjustedWithHoldingTax_Currency
)
OUTPUT inserted.Id,inserted.ReceivableInvoiceId into #ReceiptApplicationInvoiceInfo
SELECT
AmountApplied
, @CurrencyISO
, TaxApplied
, @CurrencyISO
, IsActive
, PreviousAmountApplied
, @CurrencyISO
, PreviousTaxApplied
, @CurrencyISO
, IsReApplication
, @CreatedById
, @CreatedTime
, NULL
, NULL
, ReceivableInvoiceId
, @ReceiptApplicationId
, 0.00
, @CurrencyISO
, 0.00
, @CurrencyISO
, 0.00
, @CurrencyISO
FROM
@ReceiptApplicationInvoiceParam
END
MERGE ReceiptApplicationReceivableGroups ReceiptApplicationReceivableGroup
USING @ReceiptApplicationReceivableGroupParam RARGParam ON 1!=1
WHEN NOT MATCHED THEN
INSERT
(
AmountApplied_Amount
,AmountApplied_Currency
,TaxApplied_Amount
,TaxApplied_Currency
,IsActive
,PreviousAmountApplied_Amount
,PreviousAmountApplied_Currency
,PreviousTaxApplied_Amount
,PreviousTaxApplied_Currency
,IsReApplication
,CreatedById
,CreatedTime
,UpdatedById
,UpdatedTime
,ReceiptApplicationId
,BookAmountApplied_Amount
,BookAmountApplied_Currency
,PreviousBookAmountApplied_Amount
,PreviousBookAmountApplied_Currency
,AdjustedWithHoldingTax_Amount
,AdjustedWithHoldingTax_Currency
,ReceivedAmount_Amount
,ReceivedAmount_Currency
,PreviousAdjustedWithHoldingTax_Amount
,PreviousAdjustedWithHoldingTax_Currency
)
VALUES
(
AmountApplied
, @CurrencyISO
, TaxApplied
, @CurrencyISO
, IsActive
, PreviousAmountApplied
, @CurrencyISO
, PreviousTaxApplied
, @CurrencyISO
, IsReApplication
, @CreatedById
, @CreatedTime
, NULL
, NULL
, @ReceiptApplicationId
, BookAmountApplied
, @CurrencyISO
, PreviousBookAmountApplied
, @CurrencyISO
, 0.00
, @CurrencyISO
, 0.00
, @CurrencyISO
, 0.00
, @CurrencyISO
)
OUTPUT inserted.Id as ReceiptApplicationReceivableGroupId,RARGParam.CustomerId,RARGParam.DueDate,RARGParam.ReceivableType,RARGParam.SequenceNumber,RARGParam.InvoiceNumber INTO #ReceiptApplicationGroupInfo;
MERGE ReceiptApplicationReceivableDetails AS ReceiptApplicationReceivableDetails
USING (SELECT RARDParam.*,#ReceiptApplicationInvoiceInfo.Id as ReceiptApplicationInvoiceId FROM  @ReceiptApplicationReceivableDetailParam RARDParam
LEFT JOIN #ReceiptApplicationInvoiceInfo ON RARDParam.ReceivableInvoiceId = #ReceiptApplicationInvoiceInfo.ReceivableInvoiceId) AS S1 ON 1 = 0
WHEN NOT MATCHED THEN
INSERT (AmountApplied_Amount
,AmountApplied_Currency
,TaxApplied_Amount
,TaxApplied_Currency
,IsActive
,CreatedById
,CreatedTime
,UpdatedById
,UpdatedTime
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
,AdjustedWithholdingTax_Amount
,AdjustedWithholdingTax_Currency
,ReceivedAmount_Amount
,ReceivedAmount_Currency
,PreviousAdjustedWithHoldingTax_Amount
,PreviousAdjustedWithHoldingTax_Currency
,WithHoldingTaxBookAmountApplied_Amount
,WithHoldingTaxBookAmountApplied_Currency
,ReceivedTowardsInterest_Amount
,ReceivedTowardsInterest_Currency
)
VALUES
(
AmountApplied
, @CurrencyISO
, TaxApplied
, @CurrencyISO
, IsActive
, @CreatedById
, @CreatedTime
, NULL
, NULL
, ReceivableDetailId
, @ReceiptApplicationId
, PreviousAmountApplied
, @CurrencyISO
, IsReApplication
, PreviousTaxApplied
, @CurrencyISO
, CASE WHEN @ApplyByReceivable =0 THEN ReceiptApplicationInvoiceId ELSE NULL END
, ReceivableInvoiceId
, NULL--PayableId, bigint,
, IsGLPosted
, IsTaxGLPosted
, RecoveryAmount
, @CurrencyISO
, GainAmount
, @CurrencyISO
, BookAmountApplied
, @CurrencyISO
, NULL--SundryPayableId, bigint,
, NULL-- SundryReceivableId, bigint,
, PreviousBookAmountApplied
, @CurrencyISO
, NULL --ReceiptApplicationReceivableGroupId, bigint,
, 0.00
, @CurrencyISO
, 0.00
, @CurrencyISO
, 0.00
, @CurrencyISO
, 0.00
, @CurrencyISO
, 0.00
, @CurrencyISO
)
OUTPUT Inserted.Id,Inserted.ReceivableDetailId,S1.ContractId,Inserted.AmountApplied_Amount,Inserted.TaxApplied_Amount,S1.AccountingTreatment,S1.IsRental,Inserted.RecoveryAmount_Amount as RecoveryAmount,Inserted.GainAmount_Amount as GainAmount
INTO #ReceiptApplicationReceivableDetailInfo;
-- Remove this if it is from Lockbox/ACH ---
IF(@ApplyByReceivable = 1 AND @ReceivableDisplayOption = 'ShowGroupedReceivables')
BEGIN
SELECT
ReceiptApplicationReceivableDetails.Id as RARDId,
Receivables.CustomerId,
Receivables.DueDate,
ReceivableTypes.Name as ReceivableTypeName,
Contracts.SequenceNumber,
ReceivableInvoices.Number as InvoiceNumber
INTO #ReceivableGroupInfo
FROM
ReceiptApplications
JOIN  ReceiptApplicationReceivableDetails ON ReceiptApplicationReceivableDetails.ReceiptApplicationId = ReceiptApplications.Id AND ReceiptApplications.Id = @ReceiptApplicationId
JOIN ReceivableDetails ON ReceiptApplicationReceivableDetails.ReceivableDetailId = ReceivableDetails.Id
JOIN Receivables ON ReceivableDetails.ReceivableId = Receivables.Id
JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
LEFT JOIN Contracts ON Receivables.EntityType='CT' AND Receivables.EntityId = Contracts.Id
LEFT JOIN ReceivableInvoices ON ReceiptApplicationReceivableDetails.ReceivableInvoiceId = ReceivableInvoices.Id AND ReceivableInvoices.IsActive =1
UPDATE ReceiptApplicationReceivableDetails SET ReceiptApplicationReceivableGroupId = #ReceiptApplicationGroupInfo.Id
FROM
ReceiptApplicationReceivableDetails
JOIN #ReceivableGroupInfo ON ReceiptApplicationReceivableDetails.Id = #ReceivableGroupInfo.RARDId AND ReceiptApplicationId = @ReceiptApplicationId
JOIN #ReceiptApplicationGroupInfo ON #ReceivableGroupInfo.CustomerId = #ReceiptApplicationGroupInfo.CustomerId AND #ReceivableGroupInfo.DueDate = #ReceiptApplicationGroupInfo.DueDate
AND #ReceivableGroupInfo.ReceivableTypeName = #ReceiptApplicationGroupInfo.ReceivableType AND #ReceivableGroupInfo.SequenceNumber = #ReceiptApplicationGroupInfo.SequenceNumber
AND #ReceivableGroupInfo.InvoiceNumber = #ReceiptApplicationGroupInfo.InvoiceNumber
END
IF (@CurrentReceiptBatchId IS NOT NULL)
BEGIN
INSERT INTO ReceiptBatchDetails
(
IsActive
,CreatedById
,CreatedTime
,UpdatedById
,UpdatedTime
,ReceiptId
,ReceiptBatchId)
VALUES
(
1
,@CreatedById
,@CreatedTime
,NULL
,NULL
,@ReceiptId
,@CurrentReceiptBatchId
)
END
MERGE GLJournals GLJournal
USING @ReceiptJournalParam ReceiptJournalParam ON 1 = 0
WHEN NOT MATCHED THEN
INSERT (PostDate
,IsManualEntry
,IsReversalEntry
,CreatedById
,CreatedTime
,UpdatedById
,UpdatedTime
,LegalEntityId)
VALUES(
PostDate
, IsManualEntry
, IsReversalEntry
, @CreatedById
, @CreatedTime
, NULL
, NULL
, LegalEntityId)
OUTPUT inserted.Id, ReceiptJournalParam.SourceId,ReceiptJournalParam.SourceType,inserted.LegalEntityId,inserted.PostDate, inserted.IsReversalEntry,ReceiptJournalParam.UniqueIdentifier,ReceiptJournalParam.AssetValueHistoryIds INTO #GLJournal;
INSERT INTO GLJournalDetails
(EntityId
,EntityType
,Amount_Amount
,Amount_Currency
,IsDebit
,GLAccountNumber
,Description
,SourceId
,CreatedById
,CreatedTime
,UpdatedById
,UpdatedTime
,GLAccountId
,GLTemplateDetailId
,MatchingGLTemplateDetailId
,ExportJobId
,GLJournalId
,IsActive
,LineofBusinessId)
SELECT
EntityId
, EntityType
, Amount
, Currency
, IsDebit
, GLAccountNumber
, Description
, @ReceiptId
, @CreatedById
, @CreatedTime
, NULL
, NULL
, GLAccountId
, GLTemplateDetailId
, MatchingGLTemplateDetailId
, NULL
, #GLJournal.GLJournalId
, IsActive
, LineofBusinessId
FROM @ReceiptJournalDetailParam JournalDetail
JOIN #GLJournal ON JournalDetail.SourceId = #GLJournal.SourceId AND JournalDetail.SourceType = #GLJournal.SourceType
AND #GLJournal.UniqueIdentifier = JournalDetail.UniqueIdentifier
-- Populate Receipt GL Journals --
INSERT INTO ReceiptGLJournals
(PostDate
,IsReversal
,CreatedById
,CreatedTime
,UpdatedById
,UpdatedTime
,LegalEntityId
,GLJournalId
,ReceiptId)
SELECT
PostDate
, IsReversal
, @CreatedById
, @CreatedTime
, NULL
, NULL
, LegalEntityId
, GLJournalId
, @ReceiptId
FROM
#GLJournal
WHERE
SourceType ='Receipt'
-- Populate OTP GL Journal Info ---
INSERT INTO #OTPGLJournalInfo
SELECT
GLJournalId, AssetValueHistoryIds
FROM
#GLJournal
WHERE
SourceType = 'OTP' AND AssetValueHistoryIds IS NOT NULL
DECLARE @ReceiptReceivedDate DATE = (SELECT TOP 1 ReceivedDate FROM #ReceiptInfo);
-- Update Receivable Balances --
EXEC UpdateReceivablesForReceiptApplicationForLockbox @ReceiptId = @ReceiptId,@ContractId = @ContractId,@UpdateBalance = 1,@CurrentUserId =@CreatedById,@ApplicationId = @ReceiptApplicationId,
@IsNewlyAdded = @IsReceiptInNewMode,@IsReversal = @IsReversal,@IsApplyByReceivable = @ApplyByReceivable,@IsFromBatch = 0,@CurrentTime =@CreatedTime,@ReceivedDate= @ReceiptReceivedDate;
-- Process Prepaid Receivables --
DECLARE @PrepaidReceivableSummaryParam PrepaidReceivableSummary;
INSERT INTO @PrepaidReceivableSummaryParam
SELECT ReceivableId
,IsGLPosted
,IsTaxGLPosted
,SUM(TotalReceivableAmountToPostGL) TotalReceivableAmountToPostGL
,SUM(TotalTaxAmountToPostGL) TotalTaxAmountToPostGL
,SUM(TotalFinancingReceivableAmountToPostGL) TotalFinancingReceivableAmountToPostGL
FROM
(SELECT ReceivableDetails.ReceivableId
,ReceiptApplicationReceivableDetails.IsGLPosted
,ReceiptApplicationReceivableDetails.IsTaxGLPosted
,CASE WHEN ReceivableDetails.AssetComponentType = 'Finance' THEN 0.00 ELSE SUM(ReceiptApplicationReceivableDetails.AmountApplied_Amount) END TotalReceivableAmountToPostGL
,SUM(ReceiptApplicationReceivableDetails.TaxApplied_Amount) TotalTaxAmountToPostGL
,CASE WHEN ReceivableDetails.AssetComponentType = 'Finance' THEN SUM(ReceiptApplicationReceivableDetails.AmountApplied_Amount) ELSE 0.00 END TotalFinancingReceivableAmountToPostGL
FROM ReceiptApplications
JOIN ReceiptApplicationReceivableDetails ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId
JOIN ReceivableDetails ON ReceiptApplicationReceivableDetails.ReceivableDetailId = ReceivableDetails.Id
WHERE ReceiptApplications.Id = @ReceiptApplicationId
AND ReceiptApplicationReceivableDetails.IsActive=1
GROUP BY ReceivableDetails.ReceivableId,ReceiptApplicationReceivableDetails.IsGLPosted,ReceiptApplicationReceivableDetails.IsTaxGLPosted,ReceivableDetails.AssetComponentType)
AS PrepaidReceivableInfo
GROUP BY ReceivableId
,IsGLPosted
,IsTaxGLPosted
EXEC ProcessPrePaidReceivables @ReceiptId = @ReceiptId,@IsReversal = @IsReversal,@Currency=@CurrencyISO,@PrepaidReceivableSummary = @PrepaidReceivableSummaryParam,@CurrentUserId=@CreatedById,@CurrentTime=@CreatedTime;
-- Receipt Impacts --
-- Process Cash Based Pass Through Sundries--
INSERT INTO #PayableInfo
SELECT
#ReceiptApplicationReceivableDetailInfo.Id as RARDId,
ReceivableDetails.Id AS ReceivableDetailId,
#ReceiptApplicationReceivableDetailInfo.AmountApplied,
@SundrySourceTableValue as SourceTable,
Sundries.Id as SourceId,
CASE WHEN Sundries.PayableDueDate > @ReceivedDate THEN Sundries.PayableDueDate ELSE @ReceivedDate END as DueDate,
Sundries.PayableCodeId as PayableCodeId,
Sundries.LegalEntityId as LegalEntityId,
Sundries.PayableRemitToId as PayableRemitToId,
Sundries.VendorId as PayeeId,
Sundries.Memo,
Sundries.EntityType,
Sundries.ContractId,
Sundries.CustomerId,
Sundries.CurrencyId
FROM
#ReceiptApplicationReceivableDetailInfo
JOIN ReceivableDetails ON #ReceiptApplicationReceivableDetailInfo.ReceivableDetailId = ReceivableDetails.Id AND AmountApplied <> 0
JOIN Sundries ON ReceivableDetails.ReceivableId= Sundries.ReceivableId AND Sundries.IsActive = 1 AND Sundries.IsOwned = 1 AND Sundries.SundryType = 'PassThrough'
WHERE
AccountingTreatment IN ('CashBased','MemoBased')
INSERT INTO #PayableInfo
SELECT
#ReceiptApplicationReceivableDetailInfo.Id as RARDId,
ReceivableDetails.Id AS ReceivableDetailId,
#ReceiptApplicationReceivableDetailInfo.AmountApplied,
@SundryRecurringSourceTableValue as SourceTable,
SundryRecurringPaymentSchedules.Id as SourceId,
CASE WHEN SundryRecurringPaymentSchedules.DueDate > @ReceivedDate THEN SundryRecurringPaymentSchedules.DueDate ELSE @ReceivedDate END as DueDate,
SundryRecurrings.PayableCodeId as PayableCodeId,
SundryRecurrings.LegalEntityId as LegalEntityId,
SundryRecurrings.PayableRemitToId as PayableRemitToId,
SundryRecurrings.VendorId as PayeeId,
SundryRecurrings.Memo,
SundryRecurrings.EntityType,
SundryRecurrings.ContractId,
SundryRecurrings.CustomerId,
SundryRecurrings.CurrencyId
FROM
#ReceiptApplicationReceivableDetailInfo
JOIN ReceivableDetails ON #ReceiptApplicationReceivableDetailInfo.ReceivableDetailId = ReceivableDetails.Id AND AmountApplied <> 0
JOIN SundryRecurringPaymentSchedules ON ReceivableDetails.ReceivableId = SundryRecurringPaymentSchedules.ReceivableId AND  SundryRecurringPaymentSchedules.IsActive = 1
JOIN SundryRecurrings ON SundryRecurringPaymentSchedules.SundryRecurringId = SundryRecurrings.Id AND SundryRecurrings.SundryType = 'PassThrough'
AND SundryRecurrings.IsOwned = 1
WHERE
AccountingTreatment IN ('CashBased','MemoBased')
MERGE Payables
USING #PayableInfo ON 1 = 0
WHEN NOT MATCHED THEN
INSERT
(
EntityType
,EntityId
,Amount_Amount
,Amount_Currency
,Balance_Amount
,Balance_Currency
,DueDate
,Status
,SourceTable
,SourceId
,InternalComment
,IsGLPosted
,CreatedById
,CreatedTime
,UpdatedById
,UpdatedTime
,CurrencyId
,PayableCodeId
,LegalEntityId
,PayeeId
,RemitToId
,TaxPortion_Amount
,TaxPortion_Currency
)
VALUES
(
EntityType
, CASE WHEN EntityType='CT' THEN ContractId ELSE CustomerId END
, AmountApplied
, @CurrencyISO
, AmountApplied
, @CurrencyISO
, DueDate
, 'Pending'
, SourceTable
, SourceId
, Memo
, 0
, @CreatedById
, @CreatedTime
, NULL
, NULL
, CurrencyId
, PayableCodeId
, LegalEntityId
, PayeeId
, PayableRemitToId
, 0
, @CurrencyISO
)
OUTPUT Inserted.Id as PayableId,#PayableInfo.LegalEntityId as PayableLegalEntityId,#PayableInfo.EntityType as PayableEntityType,
Inserted.EntityId as PayableEntityId,#PayableInfo.PayeeId as PayeeId,
Inserted.CurrencyId as CurrencyId,#PayableInfo.PayableRemitToId as PayableRemitToId,#PayableInfo.DueDate as PayableDueDate,#PayableInfo.Memo as InternalComment, #PayableInfo.AmountApplied as PayableAmount,
#PayableInfo.ReceivableDetailId,NULL,NULL,0 INTO #PersistedPayableInfo;
UPDATE ReceiptApplicationReceivableDetails SET PayableId = #PersistedPayableInfo.PayableId
FROM
ReceiptApplicationReceivableDetails
JOIN #PersistedPayableInfo ON ReceiptApplicationReceivableDetails.ReceivableDetailId = #PersistedPayableInfo.ReceivableDetailId
-- Process Chargeoff Recovery ---
SELECT
#ReceiptApplicationReceivableDetailInfo.ContractId,
ChargeOffs.ChargeOffAmount_Amount as ChargedoffAmount,
ChargeOffs.ContractType,
ChargeOffs.GLTemplateId,
ISNULL(SUM(RecoveredChargeoffs.ChargeoffAmount_Amount),0) as RecoveredAmount,
SUM(#ReceiptApplicationReceivableDetailInfo.RecoveryAmount + #ReceiptApplicationReceivableDetailInfo.GainAmount) as AmountApplied
INTO #ChargeoffInfo
FROM
#ReceiptApplicationReceivableDetailInfo
JOIN Chargeoffs on #ReceiptApplicationReceivableDetailInfo.ContractId = ChargeOffs.ContractId AND ChargeOffs.Status ='Approved' AND IsRecovery = 0
LEFT JOIN ChargeOffs AS RecoveredChargeoffs ON #ReceiptApplicationReceivableDetailInfo.ContractId = RecoveredChargeoffs.ContractId AND ChargeOffs.Status = 'Approved'
AND RecoveredChargeoffs.IsRecovery = 1 AND RecoveredChargeoffs.ReceiptId <> @ReceiptId
WHERE
(#ReceiptApplicationReceivableDetailInfo.RecoveryAmount + #ReceiptApplicationReceivableDetailInfo.GainAmount) <> 0
GROUP BY #ReceiptApplicationReceivableDetailInfo.ContractId,ChargeOffs.ChargeOffAmount_Amount,ChargeOffs.ContractType,ChargeOffs.GLTemplateId
INSERT INTO ChargeOffs
(
ChargeOffDate
,ChargeOffAmount_Amount
,ChargeOffAmount_Currency
,PostDate
,ContractType
,IsActive
,Status
,Comment
,CreatedById
,CreatedTime
,UpdatedById
,UpdatedTime
,GLTemplateId
,ContractId
,IsRecovery
,ReceiptId
,NetWritedown_Amount
,NetWritedown_Currency
,GrossWritedown_Amount
,GrossWritedown_Currency
,NetInvestmentWithBlended_Amount
,NetInvestmentWithBlended_Currency)
SELECT
@ReceivedDate
, AmountApplied * (-1)
, @CurrencyISO
, @PostDate
, ContractType
, 1
, 'Approved'
, NULL
, @CreatedById
, @CreatedTime
, NULL
, NULL
, GLTemplateId
, ContractId
, 1
, @ReceiptId
, 0
, @CurrencyISO
, 0
, @CurrencyISO
, 0
, @CurrencyISO
FROM
#ChargeoffInfo
-- Merge Contract Report Status Histories--
SELECT c.Id 
INTO #ContractIdToUpdates
FROM COntracts C
JOIN #ChargeoffInfo ON #ChargeoffInfo.ContractId = Contracts.Id 
WHERE C.reportStatus <> @RecoveryStatusValue

-- Update Contract ChargeoffStatus--
UPDATE Contracts
SET ChargeOffStatus = @RecoveryStatusValue,
ReportStatus = CASE WHEN (#ChargeoffInfo.AmountApplied + #ChargeoffInfo.ChargedoffAmount + #ChargeoffInfo.RecoveredAmount) < 0 THEN @RecoveryReportStatusValue ELSE ReportStatus END,
UpdatedById = @CreatedById,
UpdatedTime = @CreatedTime
FROM
Contracts
JOIN #ChargeoffInfo ON #ChargeoffInfo.ContractId = Contracts.Id

INSERT INTO ContractReportStatusHistories
(ReportStatus
,CreatedById
,CreatedTime
,ContractId)
SELECT 
@RecoveryReportStatusValue
, @CreatedById
, @CreatedTime
, #ContractIdToUpdates.ID
FROM #ContractIdToUpdates;

-- Update Reprocess Flag in Deferred Tax --
INSERT INTO @ContractIds
SELECT
#ChargeoffInfo.ContractId
FROM
#ChargeoffInfo
EXEC UpdateReprocessInDeferredTaxes @RecoveredContractIds = @ContractIds,@ReceivedDate = @ReceivedDate,@CreatedById = @CreatedById,@CreatedTime = @CreatedTime
-- Process Syndicated Receivables --
MERGE Sundries
USING (SELECT SP.*,Contracts.ContractType,ReceivableCodes.IsTaxExempt
FROM @SundryParam SP
JOIN Contracts ON SP.ContractId = Contracts.Id
JOIN ReceivableCodes ON SP.ReceivableCodeId = ReceivableCodes.Id) AS S ON 1 = 0
WHEN NOT MATCHED THEN
INSERT
(SundryType
,EntityType
,ReceivableDueDate
,InvoiceComment
,PayableDueDate
,Memo
,IsAssetBased
,Amount_Amount
,Amount_Currency
,IsActive
,IsTaxExempt
,IsServiced
,IsCollected
,IsPrivateLabel
,CreatedById
,CreatedTime
,UpdatedById
,UpdatedTime
,ReceivableCodeId
,PayableCodeId
,BillToId
,LegalEntityId
,ContractId
,CustomerId
,VendorId
,ReceivableRemitToId
,PayableRemitToId
,LocationId
,ReceivableId
,CurrencyId
,PayableId
,LineofBusinessId
,InstrumentTypeId
,IsOwned
,IsAssignAtAssetLevel
,IsSystemGenerated
,InvoiceAmendmentType
,Type
,TaxPortionOfPayable_Amount
,TaxPortionOfPayable_Currency)
VALUES
(
SundryType
, EntityType
, ReceivableDueDate
, InvoiceComment
, PayableDueDate
, Memo
, 0
, Amount
, @CurrencyISO
, 1
, CASE WHEN ContractType= 'Loan' AND @IsSelfTaxAssessed = 1 THEN IsTaxExempt WHEN ContractType='Loan' AND @IsSalesTaxRequiredForLoan = 0 THEN 1 END
, IsServiced
, IsCollected
, IsPrivateLabel
, @CreatedById
, @CreatedTime
, NULL
, NULL
, ReceivableCodeId
, PayableCodeId
, BillToId
, LegalEntityId
, ContractId
, CustomerId
, VendorId
, ReceivableRemitToId
, PayableRemitToId
, LocationId
, NULL --ReceivableId
, CurrencyId
, NULL--PayableId
, LineofBusinessId
, InstrumentTypeId
, IsOwned
, IsAssignAtAssetLevel
, IsSystemGenerated
, InvoiceAmendmentType
, Type
, TaxPortionOfPayable
, @CurrencyISO)
OUTPUT Inserted.Id as SundryId,Inserted.SundryType,S.ReceivableDetailId,Inserted.IsTaxExempt INTO #PersistedSundryInfo;
IF EXISTS(SELECT * FROM #PersistedSundryInfo WHERE SundryType='ReceivableOnly')
BEGIN
MERGE Receivables
USING (SELECT SP.*,#PersistedSundryInfo.SundryId,#PersistedSundryInfo.IsTaxExempt,ReceivableCodes.DefaultInvoiceReceivableGroupingOption
FROM
@SundryParam SP
JOIN #PersistedSundryInfo ON SP.ReceivableDetailId = #PersistedSundryInfo.ReceivableDetailId AND SP.SundryType = 'ReceivableOnly' AND #PersistedSundryInfo.SundryType = 'ReceivableOnly'
JOIN ReceivableCodes ON SP.ReceivableCodeId = ReceivableCodes.Id  )AS S ON 1 = 0
WHEN NOT MATCHED THEN
INSERT
(EntityType
,EntityId
,DueDate
,IsDSL
,IsActive
,InvoiceComment
,InvoiceReceivableGroupingOption
,IsGLPosted
,IncomeType
,PaymentScheduleId
,IsCollected
,IsServiced
,CreatedById
,CreatedTime
,UpdatedById
,UpdatedTime
,ReceivableCodeId
,CustomerId
,FunderId
,RemitToId
,TaxRemitToId
,LocationId
,LegalEntityId
,IsDummy
,IsPrivateLabel
,SourceId
,SourceTable
,TotalAmount_Amount
,TotalAmount_Currency
,TotalBalance_Amount
,TotalBalance_Currency
,TotalEffectiveBalance_Amount
,TotalEffectiveBalance_Currency
,TotalBookBalance_Amount
,TotalBookBalance_Currency)
VALUES
(
EntityType
, CASE WHEN EntityType = 'CT' THEN ContractId ELSE CustomerId END
, ReceivableDueDate
, 0
, 1
, InvoiceComment
, DefaultInvoiceReceivableGroupingOption
, 0
, '_'
, NULL
, IsCollected
, IsServiced
, @CreatedById
, @CreatedTime
, NULL
, NULL
, ReceivableCodeId
, CustomerId
, NULL
, ReceivableRemitToId
, ReceivableRemitToId
, LocationId
, LegalEntityId
, 0
, IsPrivateLabel
, SourceTableId
, SourceTable
, Amount
, @CurrencyISO
, Amount
, @CurrencyISO
, Amount
, @CurrencyISO
, Amount
, @CurrencyISO
)
OUTPUT Inserted.Id as ReceivableId,S.SundryId,S.Amount,S.BillToId,S.IsTaxExempt INTO #SyndicatedReceivableInfo;
INSERT INTO ReceivableDetails
(Amount_Amount
,Amount_Currency
,Balance_Amount
,Balance_Currency
,EffectiveBalance_Amount
,EffectiveBalance_Currency
,IsActive
,BilledStatus
,IsTaxAssessed
,CreatedById
,CreatedTime
,UpdatedById
,UpdatedTime
,AssetId
,BillToId
,AdjustmentBasisReceivableDetailId
,ReceivableId
,StopInvoicing
,EffectiveBookBalance_Amount
,EffectiveBookBalance_Currency
,AssetComponentType
,LeaseComponentAmount_Amount
,LeaseComponentAmount_Currency
,NonLeaseComponentAmount_Amount
,NonLeaseComponentAmount_Currency
,LeaseComponentBalance_Amount
,LeaseComponentBalance_Currency
,NonLeaseComponentBalance_Amount
,NonLeaseComponentBalance_Currency
,PreCapitalizationRent_Amount
,PreCapitalizationRent_Currency)
SELECT
Amount
, @CurrencyISO
, Amount
, @CurrencyISO
, Amount
, @CurrencyISO
, 1
, 'NotInvoiced'
, IsTaxExempt
, @CreatedById
, @CreatedTime
, NULL
, NULL
, NULL
, BillToId
, NULL
, ReceivableId
, 0
, Amount
, @CurrencyISO
, '_'
, 0.00
, @CurrencyISO
, 0.00
, @CurrencyISO
, 0.00
, @CurrencyISO
, 0.00
, @CurrencyISO
, 0.00
, @CurrencyISO
FROM
#SyndicatedReceivableInfo

INSERT INTO #ReceivableDetailsComponent
SELECT *
FROM
(
    SELECT CASE
               WHEN la.IsLeaseAsset = 1 THEN rd.Amount_Amount
               ELSE 0.00
           END AS LeaseComponentAmount
         , CASE
               WHEN la.IsLeaseAsset = 0 THEN rd.Amount_Amount
               ELSE 0.00
           END AS NonLeaseComponentAmount
         , rd.Id AS ReceivableDetailId
    FROM Receivables r WITH(NOLOCK)
		 INNER JOIN #SyndicatedReceivableInfo sri ON sri.ReceivableId = R.Id
         INNER JOIN ReceivableDetails rd WITH(NOLOCK) ON rd.ReceivableId = r.Id
         INNER JOIN ReceivableCodes rc ON rc.Id = r.ReceivableCodeId
         INNER JOIN ReceivableTypes rt ON rc.ReceivableTypeId = rt.Id
         INNER JOIN LeaseAssets la ON la.AssetId =  rd.AssetId
		 INNER JOIN Assets a ON la.AssetId = a.Id
    WHERE rt.Name IN('CapitalLeaseRental', 'OperatingLeaseRental', 'BuyOut', 'LeasePayOff', 'LeveragedLeasePayoff') 
		  AND a.IsSKU = 0
    UNION
    SELECT SUM(CASE WHEN las.IsLeaseComponent = 1 THEN rs.Amount_Amount
                    ELSE 0.00
               END) AS LeaseComponentAmount
         , SUM(CASE
                   WHEN las.IsLeaseComponent = 0 THEN rs.Amount_Amount
                   ELSE 0.00
               END) AS  NonLeaseComponentAmount
         , rd.Id AS ReceivableDetailId
    FROM Receivables r WITH(NOLOCK)
		 INNER JOIN #SyndicatedReceivableInfo sri ON sri.ReceivableId = R.Id
         INNER JOIN ReceivableDetails rd WITH(NOLOCK) ON rd.ReceivableId = r.Id
         INNER JOIN LeaseAssets la ON rd.AssetId = la.AssetId
         INNER JOIN LeaseAssetSKUs las ON la.Id = las.LeaseAssetId
         INNER JOIN ReceivableSKUs rs WITH(NOLOCK) ON las.AssetSKUId = rs.AssetSKUId AND rd.Id = rs.ReceivableDetailId
         INNER JOIN ReceivableCodes rc ON rc.Id = r.ReceivableCodeId
         INNER JOIN ReceivableTypes rt ON rc.ReceivableTypeId = rt.Id
    WHERE rt.Name IN('CapitalLeaseRental', 'OperatingLeaseRental', 'BuyOut', 'LeasePayOff', 'LeveragedLeasePayoff') 
    GROUP BY rd.Id
           , rd.AssetId
) AS Temp;


UPDATE ReceivableDetails
  SET 
      LeaseComponentAmount_Amount = rdc.LeaseComponentAmount
    , NonLeaseComponentAmount_Amount = rdc.NonLeaseComponentAmount
    , LeaseComponentBalance_Amount = rdc.LeaseComponentAmount
    , NonLeaseComponentBalance_Amount = rdc.NonLeaseComponentAmount
FROM ReceivableDetails rd WITH(NOLOCK)
     INNER JOIN #ReceivableDetailsComponent rdc ON rd.Id = rdc.ReceivableDetailId;

UPDATE ReceivableDetails
  SET 
      LeaseComponentAmount_Amount = rd.Amount_Amount
    , LeaseComponentBalance_Amount = rd.Balance_Amount
FROM ReceivableDetails rd WITH(NOLOCK)
	 INNER JOIN #SyndicatedReceivableInfo sri ON rd.ReceivableId  = sri.ReceivableId
	 LEFT JOIN #ReceivableDetailsComponent rdc ON rd.Id = rdc.ReceivableDetailId
	 WHERE rdc.ReceivableDetailId IS NULL

UPDATE Sundries SET ReceivableId = #SyndicatedReceivableInfo.ReceivableId
FROM
Sundries
JOIN #SyndicatedReceivableInfo ON Sundries.Id = #SyndicatedReceivableInfo.SundryId
END
IF EXISTS(SELECT * FROM #PersistedSundryInfo WHERE SundryType = 'PayableOnly')
BEGIN
MERGE Payables
USING (SELECT SP.*,#PersistedSundryInfo.SundryId
FROM
@SundryParam SP
JOIN #PersistedSundryInfo ON SP.ReceivableDetailId = #PersistedSundryInfo.ReceivableDetailId AND SP.SundryType = 'PayableOnly' AND #PersistedSundryInfo.SundryType = 'PayableOnly') S ON 1 = 0
WHEN NOT MATCHED THEN
INSERT
(EntityType
,EntityId
,Amount_Amount
,Amount_Currency
,Balance_Amount
,Balance_Currency
,DueDate
,Status
,SourceTable
,SourceId
,InternalComment
,IsGLPosted
,CreatedById
,CreatedTime
,UpdatedById
,UpdatedTime
,CurrencyId
,PayableCodeId
,LegalEntityId
,PayeeId
,RemitToId
,TaxPortion_Amount
,TaxPortion_Currency)
VALUES
(
EntityType
, CASE WHEN EntityType = 'CT' THEN ContractId ELSE CustomerID END
, Amount
, @CurrencyISO
, Amount
, @CurrencyISO
, PayableDueDate
, @PayableStatusValueForReceipt
, SourceTable
, SourceTableId
, Memo
, 0
, @CreatedById
, @CreatedTime
, NULL
, NULL
, CurrencyId
, PayableCodeId
, LegalEntityId
, VendorId
, PayableRemitToId
, TaxPortionOfPayable
, @CurrencyISO
)
OUTPUT Inserted.Id as PayableId,Inserted.LegalEntityId as PayableLegalEntityId,Inserted.EntityType as PayableEntityType,Inserted.EntityId as PayableEntityId,Inserted.PayeeId as PayeeId,Inserted.CurrencyId as CurrencyId, Inserted.RemitToId as PayableRemitToId, Inserted.DueDate as PayableDueDate,Inserted.InternalComment as InternalComment,Inserted.Amount_Amount as PayableAmount,
S.ReceivableDetailId,S.SundryId,S.ContractId,1 INTO #PersistedPayableInfo;
UPDATE Sundries SET PayableId = #PersistedPayableInfo.PayableId
FROM
Sundries
JOIN #PersistedPayableInfo ON Sundries.Id = #PersistedPayableInfo.SundryId
END
UPDATE ReceiptApplicationReceivableDetails
SET SundryReceivableId = CASE WHEN #PersistedSundryInfo.SundryType = 'ReceivableOnly' THEN #PersistedSundryInfo.SundryId ELSE NULL END,
SundryPayableId = CASE WHEN #PersistedSundryInfo.SundryType = 'PayableOnly' THEN #PersistedSundryInfo.SundryId ELSE NULL END
FROM
ReceiptApplicationReceivableDetails
JOIN #PersistedSundryInfo ON ReceiptApplicationReceivableDetails.ReceivableDetailId = ReceiptApplicationReceivableDetails.ReceivableDetailId
-- Process CPU Based Receivables --
IF EXISTS(SELECT * FROM @CPUParam)
BEGIN
MERGE Payables
USING @CPUParam AS p ON 1 = 0
WHEN NOT MATCHED THEN
INSERT
(EntityType
,EntityId
,Amount_Amount
,Amount_Currency
,Balance_Amount
,Balance_Currency
,DueDate
,Status
,SourceTable
,SourceId
,IsGLPosted
,CreatedById
,CreatedTime
,CurrencyId
,PayableCodeId
,LegalEntityId
,PayeeId
,RemitToId
,TaxPortion_Amount
,TaxPortion_Currency)
VALUES
(
EntityType
, EntityId
, Amount
, @CurrencyISO
, Amount
, @CurrencyISO
, DueDate
, @PayableStatusValueForReceipt
, SourceTable
, SourceId
, 0
, @CreatedById
, @CreatedTime
, Currency
, PayableCode
, LegalEntity
, Payee
, RemitTo
,0
,@CurrencyISO)
OUTPUT Inserted.Id, p.ReceivableDetailId INTO #CPUPayableIds;
UPDATE ReceiptApplicationReceivableDetails
SET PayableId = cp.Id
FROM
ReceiptApplicationReceivableDetails
JOIN #CPUPayableIds cp ON ReceiptApplicationReceivableDetails.ReceivableDetailId = cp.ReceivableDetailId
END
-- Process OTP Cash Based Receivables --
-- Map Asset Value Histories with GL Journal Ids --
IF EXISTS (SELECT TOP 1 ReceivableDetailId FROM @OTPCashBasedReceivableParam)
BEGIN
---- Insert into AssetValueHistory Details for Finance OTP Cash Based Lease --
INSERT INTO AssetValueHistoryDetails
(AmountPosted_Amount
,AmountPosted_Currency
,IsActive
,CreatedById
,CreatedTime
,UpdatedById
,UpdatedTime
,ReceiptApplicationReceivableDetailId
,GLJournalId
,AssetValueHistoryId)
SELECT
DepreciationAmount
, @CurrencyISO
, 1
, @CreatedById
, @CreatedTime
, NULL
, NULL
, #ReceiptApplicationReceivableDetailInfo.Id
, NULL -- GLJournalId
, OTPParam.AssetValueHistoryId
FROM
@OTPCashBasedReceivableParam OTPParam
JOIN #ReceiptApplicationReceivableDetailInfo ON OTPParam.ReceivableDetailId = #ReceiptApplicationReceivableDetailInfo.ReceivableDetailId
WHERE
OTPParam.AssetValueHistoryId IS NOT NULL
DECLARE @CNT INT=(SELECT COUNT(*) FROM #OTPGLJournalInfo);
DECLARE @I INT = 1;
DECLARE @Query NVARCHAR(MAX) = '';
WHILE @I <=@CNT
BEGIN
DECLARE @GLJournalId BIGINT
DECLARE @T NVARCHAR(MAX);
SELECT @GLJournalId = GLJournalId,@T = AssetValueHistoryIds FROM #OTPGLJournalInfo WHERE ID = @I
---- Update Journal Id in AVH Detail ---
UPDATE AssetValueHistoryDetails SET GLJournalId = @GLJournalId,
UpdatedById = @CreatedById,
UpdatedTime = @CreatedTime
WHERE
AssetValueHistoryId IN (@T)
SET @I = @I +1;
END
----- Update AssetValueHistories GLJournalId ---
UPDATE AssetValueHistories SET GLJournalId = MaxGLJournalId,
UpdatedById = @CreatedById,
UpdatedTime = @CreatedTime
FROM
AssetValueHistories
JOIN (SELECT
AssetValueHistories.Id,
MAX(AssetValueHistoryDetails.GLJournalId) as MaxGLJournalId
FROM
@OTPCashBasedReceivableParam OTPParam
JOIN AssetValueHistories ON OTPParam.AssetValueHistoryId = AssetValueHistories.Id AND OTPParam.CanUpdateHeaderGLJournal = 1 and AssetValueHistories.IsLessorOwned = 1
JOIN AssetValueHistoryDetails ON AssetValueHistories.Id = AssetValueHistoryDetails.AssetValueHistoryId
GROUP BY AssetValueHistories.Id) AssetValueHistoryJournalTemp ON AssetValueHistories.Id = AssetValueHistoryJournalTemp.Id
END
--Update Lease Income Schedule GL Posted ---
IF EXISTS (SELECT TOP 1 ReceivableDetailId FROM @OTPCashBasedReceivableParam WHERE CanUpdateIncomeScheduleGL = 1)
BEGIN
INSERT INTO #LeaseIncomeGL
SELECT DISTINCT
LeaseIncomeScheduleIdsInCSV
FROM
@OTPCashBasedReceivableParam
WHERE CanUpdateIncomeScheduleGL = 1
DECLARE @IncomeCNT INT=(SELECT COUNT(*) FROM #LeaseIncomeGL);
DECLARE @J INT = 1;
DECLARE @Ids NVARCHAR(MAX) = '';
DECLARE @SQL NVARCHAR(MAX) = '';
WHILE @J <=@IncomeCNT
BEGIN
SELECT @Ids = LeaseIncomeScheduleIdsInCSV FROM #LeaseIncomeGL WHERE ID = @J
SET @SQL = @SQL + 'UPDATE LeaseIncomeSchedules SET IsGLPosted = 1, UpdatedById = ' + CAST(@CreatedById AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@CreatedTime AS NVARCHAR(MAX)) + ''' WHERE Id IN (' +@Ids+');'
SET @J = @J+1;
IF(@J > @IncomeCNT AND @Ids IS NOT NULL AND @Ids != '')
EXEC(@SQL)
END
END
-- Process WriteDown Recovery ---
IF EXISTS (SELECT * FROM @ReceiptApplicationReceivableDetailParam RARDParam JOIN WriteDowns ON RARDParam.ContractId = WriteDowns.ContractId AND WriteDowns.Status = 'Approved' AND WriteDowns.IsActive = 1)
BEGIN
SELECT
Contracts.Id as ContractId,
Contracts.ContractType,
WriteDownContractInfo.WriteDownDate,
WriteDownContractInfo.TotalWriteDownAmount,
WriteDownContractInfo.TotalRecoveryAmount,
SUM(RARDParam.AmountApplied) as TotalAmountApplied
INTO #WriteDownHeaderInfo
FROM
@ReceiptApplicationReceivableDetailParam RARDParam
JOIN ReceivableDetails ON RARDParam.ReceivableDetailId = ReceivableDetails.Id
JOIN Receivables ON ReceivableDetails.ReceivableId = Receivables.Id AND Receivables.FunderId IS NULL
JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
JOIN Contracts ON RARDParam.ContractId = Contracts.Id AND RARDParam.AmountApplied <> 0 AND Contracts.ContractType IN ('Lease','Loan')
JOIN
(SELECT
Writedowns.ContractId,
MIN(CASE WHEN IsRecovery = 0  THEN WriteDownDate END) as WriteDownDate,
ISNULL(SUM(CASE WHEN IsRecovery = 0 THEN WriteDownAmount_Amount ELSE 0 END),0) as TotalWriteDownAmount,
ISNULL(SUM(CASE WHEN IsRecovery = 1 THEN WriteDownAmount_Amount ELSE 0 END),0) as TotalRecoveryAmount
FROM
WriteDowns
WHERE
WriteDowns.Status ='Approved'
AND WriteDowns.IsActive = 1
GROUP BY WriteDowns.ContractId) AS WriteDownContractInfo ON WriteDownContractInfo.ContractId = Contracts.Id
LEFT JOIN
(
SELECT
Sundries.ReceivableId as ReceivableId,
BlendedItems.EndDate
FROM
Sundries
JOIN BlendedItemDetails ON Sundries.Id = BlendedItemDetails.SundryId
JOIN BlendedItems ON BlendedItemDetails.BlendedItemId = BlendedItems.Id
WHERE
BlendedItemDetails.IsActive = 1
AND BlendedItems.IsFAS91 = 1
AND BlendedItems.BookRecognitionMode IN ('Amortize','Accrete')
AND Sundries.IsActive = 1
) AS BlendedItemInfo ON Receivables.Id = BlendedItemInfo.ReceivableId AND BlendedItemInfo.EndDate >= Contracts.NonAccrualDate
LEFT JOIN LeasePaymentSchedules ON Contracts.ContractType = 'Lease' AND Receivables.PaymentScheduleId = LeasePaymentSchedules.Id
LEFT JOIN LoanPaymentSchedules ON Contracts.ContractType ='Loan' AND Receivables.PaymentScheduleId = LoanPaymentSchedules.Id
WHERE
((LeasePaymentSchedules.Id IS NOT NULL AND LeasePaymentSchedules.PaymentType IN ('FixedTerm','DownPayment','MaturityPayment','CustomerGuaranteedResidual','ThirdPartyGuaranteedResidual'))
OR (LoanPaymentSchedules.Id IS NOT NULL AND LoanPaymentSchedules.PaymentType IN ('FixedTerm','Downpayment'))
OR (LeasePaymentSchedules.Id IS NULL AND LoanPaymentSchedules.Id IS NULL))
AND (ReceivableTypes.Name IN ('CapitalLeaseRental','LeaseFloatRateAdj','LoanInterest','LoanPrincipal')
OR (ReceivableTypes.Name = 'OperatingLeaseRental' AND ReceivableDetails.AssetComponentType = 'Finance')
OR (ReceivableTypes.Name IN ('Sundry','SundrySeparate') AND BlendedItemInfo.ReceivableId IS NOT NULL))
GROUP BY Contracts.Id , Contracts.ContractType,WriteDownContractInfo.WriteDownDate,WriteDownContractInfo.TotalWriteDownAmount,WriteDownContractInfo.TotalRecoveryAmount
DECLARE @NBVWithBlendedCalculatorInput NBVWithBlendedCalculatorInput;
INSERT INTO @NBVWithBlendedCalculatorInput
SELECT ContractId,ContractType,WriteDownDate FROM #WriteDownHeaderInfo
INSERT INTO #ContractNBVWithBlendedInfo
EXEC CalculateNBVWithBlended @NBVWithBlendedCalculatorInput = @NBVWithBlendedCalculatorInput
UPDATE #ContractNBVWithBlendedInfo SET NBVWithBlended = NBVWithBlended + #WriteDownHeaderInfo.TotalAmountApplied
FROM
#ContractNBVWithBlendedInfo
JOIN #WriteDownHeaderInfo ON #ContractNBVWithBlendedInfo.ContractId = #WriteDownHeaderInfo.ContractId
INSERT INTO #WriteDownNBVInfo
SELECT
#ContractNBVWithBlendedInfo.ContractId,
#ContractNBVWithBlendedInfo.ContractType,
LeaseFinances.Id AS LeaseFinanceId,
LoanFinances.Id AS LoanFinanceId,
#ContractNBVWithBlendedInfo.NBVWithBlended,
MIN(#WriteDownHeaderInfo.TotalWriteDownAmount) as TotalWriteDownAmount,
MIN(#WriteDownHeaderInfo.TotalRecoveryAmount) as TotalRecoveryAmount,
MIN(#WriteDownHeaderInfo.TotalAmountApplied) as TotalAmountApplied,
0 as NetInvestmentWithReserve,
MIN(WriteDowns.GLTemplateId) as GLTemplateId,
MIN(WriteDowns.RecoveryReceivableCodeId) as RecoveryReceivableCodeId,
MIN(WriteDowns.RecoveryGLTemplateId) as RecoveryGLTemplateId,
WriteDowns.WriteDownReason
FROM
#WriteDownHeaderInfo
JOIN WriteDowns ON #WriteDownHeaderInfo.ContractId = WriteDowns.ContractId
JOIN #ContractNBVWithBlendedInfo ON #WriteDownHeaderInfo.ContractId = #ContractNBVWithBlendedInfo.ContractId
LEFT JOIN LeaseFinances ON #ContractNBVWithBlendedInfo.ContractId = LeaseFinances.ContractId AND LeaseFinances.IsCurrent = 1 AND #ContractNBVWithBlendedInfo.ContractType ='Lease'
LEFT JOIN LoanFinances ON #ContractNBVWithBlendedInfo.ContractId = LoanFinances.ContractId AND LoanFinances.IsCurrent = 1 AND #ContractNBVWithBlendedInfo.ContractType = 'Loan'
GROUP BY
#ContractNBVWithBlendedInfo.ContractId,#ContractNBVWithBlendedInfo.ContractType,LeaseFinances.Id,LoanFinances.Id,#WriteDownHeaderInfo.WriteDownDate,#ContractNBVWithBlendedInfo.NBVWithBlended,WriteDowns.WriteDownReason
UPDATE #WriteDownNBVInfo SET NetInvestmentWithReserve = CASE WHEN NetInvestmentWithBlended - TotalWriteDownAmount - TotalRecoveryAmount > 0
THEN NetInvestmentWithBlended - TotalWriteDownAmount - TotalRecoveryAmount ELSE 0 END
INSERT INTO WriteDowns
(WriteDownDate
,WriteDownAmount_Amount
,WriteDownAmount_Currency
,IsAssetWriteDown
,IsRecovery
,PostDate
,ContractType
,IsActive
,Status
,CreatedById
,CreatedTime
,UpdatedById
,UpdatedTime
,GLTemplateId
,ContractId
,LeaseFinanceId
,LoanFinanceId
,WriteDownGLJournalId
,Comment
,RecoveryGLTemplateId
,RecoveryReceivableCodeId
,ReceiptId
,NetWritedown_Amount
,NetWritedown_Currency
,GrossWritedown_Amount
,GrossWritedown_Currency
,NetInvestmentWithBlended_Amount
,NetInvestmentWithBlended_Currency
,NetInvestmentWithReserve_Amount
,NetInvestmentWithReserve_Currency
,SourceId
,SourceModule
,WriteDownReason)
OUTPUT inserted.Id as Id,inserted.ContractId, inserted.WriteDownAmount_Amount as RecoveryAmount,inserted.GLTemplateId,inserted.RecoveryGLTemplateId, @PostDate as PostDate,inserted.LeaseFinanceId,inserted.LoanFinanceId INTO #PersistedWriteDownInfo
SELECT
@ReceivedDate
,CASE WHEN TotalWriteDownAmount + TotalRecoveryAmount <> 0
THEN (CASE WHEN (TotalAmountApplied - NetInvestmentWithReserve) > (TotalWriteDownAmount + TotalRecoveryAmount) THEN (TotalWriteDownAmount + TotalRecoveryAmount) * (-1)
ELSE (TotalAmountApplied - NetInvestmentWithReserve) * (-1) END)
ELSE 0 END
,@CurrencyISO
,0
,1
,@PostDate
,#WriteDownNBVInfo.ContractType
,1
,'Approved'
,@CreatedById
,@CreatedTime
,NULL
,NULL
,GLTemplateId
,ContractId
,LeaseFinanceId
,LoanFinanceId
,NULL
,NULL
,RecoveryGLTemplateId
,RecoveryReceivableCodeId
,@ReceiptId
,CASE WHEN TotalWriteDownAmount + TotalRecoveryAmount <> 0
THEN (CASE WHEN (TotalAmountApplied - NetInvestmentWithReserve) > (TotalWriteDownAmount + TotalRecoveryAmount) THEN 0.00
ELSE  TotalWriteDownAmount + TotalRecoveryAmount + (TotalAmountApplied - NetInvestmentWithReserve) * (-1) END)
ELSE TotalWriteDownAmount + TotalRecoveryAmount END
,@CurrencyISO
,TotalWriteDownAmount
,@CurrencyISO
,CASE WHEN (#WriteDownNBVInfo.NetInvestmentWithBlended - #WriteDownNBVInfo.TotalAmountApplied) < 0
THEN 0.00
ELSE #WriteDownNBVInfo.NetInvestmentWithBlended - #WriteDownNBVInfo.TotalAmountApplied END
,@CurrencyISO
,0.00
,@CurrencyISO
,@ReceiptId
,'Receipt'
,WriteDownReason
FROM
#WriteDownNBVInfo
WHERE
(TotalAmountApplied > 0 AND TotalAmountApplied > NetInvestmentWithReserve) OR
(TotalWriteDownAmount + TotalRecoveryAmount = 0)
-- Fetch WriteDownAssetDetailSummary --
SELECT
#PersistedWriteDownInfo.ContractId,
#PersistedWriteDownInfo.Id as WriteDownId,
#PersistedWriteDownInfo.RecoveryAmount,
CASE WHEN #WriteDownHeaderInfo.TotalWriteDownAmount <> 0
THEN (#PersistedWriteDownInfo.RecoveryAmount * (WriteDownAssetDetailInfo.TotalWriteDownAmountForAsset / #WriteDownHeaderInfo.TotalWriteDownAmount))
ELSE  0 END as RecoveryAmountForAsset,
WriteDownAssetDetailInfo.AssetId,
ROW_NUMBER() OVER(PARTITION BY #PersistedWriteDownInfo.ContractId ORDER BY AssetId DESC) as IsLastAsset
INTO #WriteDownAssetDetailsInfo
FROM
#PersistedWriteDownInfo
JOIN #WriteDownHeaderInfo ON #PersistedWriteDownInfo.ContractId = #WriteDownHeaderInfo.ContractId
JOIN
(SELECT
WriteDowns.ContractId,
WriteDownAssetDetails.AssetId,
SUM(WriteDownAssetDetails.WriteDownAmount_Amount) as TotalWriteDownAmountForAsset
FROM
WriteDowns
JOIN WriteDownAssetDetails ON WriteDowns.Id = WriteDownAssetDetails.WriteDownId
JOIN #WriteDownHeaderInfo ON WriteDowns.ContractId = #WriteDownHeaderInfo.ContractId
WHERE
WriteDownAssetDetails.IsActive = 1
AND WriteDowns.IsActive = 1
AND WriteDowns.Status = 'Approved'
AND WriteDowns.IsRecovery = 0
GROUP BY WriteDowns.ContractId,WriteDownAssetDetails.AssetId) AS WriteDownAssetDetailInfo ON #PersistedWriteDownInfo.ContractId = WriteDownAssetDetailInfo.ContractId
UPDATE #WriteDownAssetDetailsInfo SET RecoveryAmountForAsset = RecoveryAmountForAsset + (RecoveryAmount - RecoveredAmountSummary.TotalRecoveredAmount)
FROM
#WriteDownAssetDetailsInfo
JOIN (SELECT
WriteDownId,
SUM(RecoveryAmountForAsset) as TotalRecoveredAmount
FROM
#WriteDownAssetDetailsInfo
GROUP BY WriteDownId) AS RecoveredAmountSummary ON #WriteDownAssetDetailsInfo.WriteDownId = RecoveredAmountSummary.WriteDownId
WHERE #WriteDownAssetDetailsInfo.IsLastAsset = 1
INSERT INTO WriteDownAssetDetails
(WriteDownAmount_Amount
,WriteDownAmount_Currency
,IsActive
,CreatedById
,CreatedTime
,UpdatedById
,UpdatedTime
,AssetId
,WriteDownId
,NetWritedown_Amount
,NetWritedown_Currency
,GrossWritedown_Amount
,GrossWritedown_Currency
,NetInvestmentWithReserve_Amount
,NetInvestmentWithReserve_Currency
,NetInvestmentWithBlended_Amount
,NetInvestmentWithBlended_Currency)
SELECT
RecoveryAmountForAsset * (-1)
,@CurrencyISO
,1
,@CreatedById
,@CreatedTime
,NULL
,NULL
,AssetId
,WriteDownId
,0
,@CurrencyISO
,0
,@CurrencyISO
,0
,@CurrencyISO
,0
,@CurrencyISO
FROM
#WriteDownAssetDetailsInfo
-- Update Reprocess Flag in Deferred Tax for Write Down Recovery--
DELETE FROM @ContractIds WHERE EXISTS(SELECT * FROM @ContractIds)
INSERT INTO @ContractIds
SELECT
DISTINCT
#PersistedWriteDownInfo.ContractId
FROM
#PersistedWriteDownInfo
EXEC UpdateReprocessInDeferredTaxes @RecoveredContractIds = @ContractIds,@ReceivedDate = @ReceivedDate,@CreatedById = @CreatedById,@CreatedTime = @CreatedTime
END
-- Process Late Fee Receivable Reversal ---
-- Update Funds Received in Placement --
SELECT
AgencyLegalPlacements.Id as LegalPlacementId,
AgencyLegalPlacementContracts.ContractId,
SUM(AmountApplied + TaxApplied) as TotalAmount,
AgencyLegalPlacementContracts.FundsReceived_Currency as Currency
INTO #PlacementInfo
FROM
@ReceiptApplicationReceivableDetailParam RARDParam
JOIN AgencyLegalPlacementContracts ON RARDParam.ContractId = AgencyLegalPlacementContracts.ContractId
JOIN AgencyLegalPlacements ON AgencyLegalPlacementContracts.AgencyLegalPlacementId = AgencyLegalPlacements.Id
WHERE
AgencyLegalPlacements.IsActive = 1
AND AgencyLegalPlacements.IsActive = 1
AND AgencyLegalPlacements.Status <> 'RemovedFromAgency'
AND (@PostDate >= AgencyLegalPlacements.DateOfPlacement)
GROUP BY AgencyLegalPlacements.Id,AgencyLegalPlacementContracts.ContractId,AgencyLegalPlacementContracts.FundsReceived_Currency
IF EXISTS (SELECT COUNT(*) FROM #PlacementInfo)
BEGIN
UPDATE AgencyLegalPlacementContracts SET FundsReceived_Amount = FundsReceived_Amount + TotalAmount, UpdatedById = @CreatedById, UpdatedTime = @CreatedTime
FROM
AgencyLegalPlacementContracts
JOIN #PlacementInfo ON AgencyLegalPlacementContracts.ContractId = #PlacementInfo.ContractId AND IsActive = 1 AND LegalPlacementId = #PlacementInfo.LegalPlacementId
UPDATE AgencyLegalPlacementAmounts SET FundsReceived_Amount = AgencyLegalPlacementAmounts.FundsReceived_Amount + TotalFundsReceived,
Balance_Amount = Balance_Amount + TotalAcceleratedBalance, UpdatedById = @CreatedById, UpdatedTime = @CreatedTime
FROM
AgencyLegalPlacementAmounts
JOIN (SELECT
#PlacementInfo.LegalPlacementId,
Contracts.CurrencyId,
SUM(CASE WHEN AcceleratedBalanceDetails.Id IS NOT NULL THEN AcceleratedBalanceDetails.Balance_Amount ELSE 0 END) as TotalAcceleratedBalance,
SUM(AgencyLegalPlacementContracts.FundsReceived_Amount) as TotalFundsReceived
FROM
AgencyLegalPlacementContracts
JOIN Contracts ON AgencyLegalPlacementContracts.ContractId = Contracts.Id
JOIN #PlacementInfo ON Contracts.Id = #PlacementInfo.ContractId AND AgencyLegalPlacementContracts.AgencyLegalPlacementId = #PlacementInfo.LegalPlacementId
LEFT JOIN AcceleratedBalanceDetails ON AgencyLegalPlacementContracts.AcceleratedBalanceDetailId = AcceleratedBalanceDetails.Id
GROUP BY Contracts.CurrencyId, #PlacementInfo.LegalPlacementId) as CurrencyDetailInfo ON AgencyLegalPlacementAmounts.AgencyLegalPlacementId = CurrencyDetailInfo.LegalPlacementId
AND AgencyLegalPlacementAmounts.CurrencyId = CurrencyDetailInfo.CurrencyId
END
-- Create Recent Transactions --
INSERT INTO @RecentTransactionParams
SELECT
'Receipt' as EntityType,
@ReceiptId as EntityId,
'ReceiptPosted' as TransactionName,
'Edit' as [Transaction],
@ReceiptNumber as ReferenceNumber,
RecentTransactionSummary.ContractId as ContractId,
RecentTransactionSummary.CustomerId as CustomerId,
'' as Description,
@CreatedById,
@CreatedTime
FROM
(SELECT
RARDParam.ContractId as ContractId,
Receivables.CustomerId as CustomerId
FROM
@ReceiptApplicationReceivableDetailParam RARDParam
JOIN ReceivableDetails ON RARDParam.ReceivableDetailId = ReceivableDetails.Id
JOIN Receivables ON ReceivableDetails.ReceivableId = Receivables.Id
GROUP BY RARDParam.ContractId,Receivables.CustomerId) as RecentTransactionSummary
EXEC CreateRecentTransactions @RecentTransactionParams
-- Returning the final ResultSet --
SELECT
PayableId,
PayableLegalEntityId,
PayableEntityType,
PayableEntityId,
PayeeId,
CurrencyId,
PayableRemitToId,
PayableDueDate,
InternalComment,
PayableAmount,
ReceivableDetailId,
SundryId,
ContractId,
IsScrapePayable
FROM
#PersistedPayableInfo
SELECT
#PersistedWriteDownInfo.Id as WriteDownId,
#PersistedWriteDownInfo.ContractId as ContractId,
#PersistedWriteDownInfo.RecoveryAmount as RecoveryAmount,
#PersistedWriteDownInfo.GLTemplateId as GLTemplateId,
#PersistedWriteDownInfo.RecoveryGLTemplateId as RecoveryGLTemplateId,
#PersistedWriteDownInfo.PostDate as PostDate,
CASE WHEN LeaseFinances.Id IS NOT NULL THEN LeaseFinances.LegalEntityId ELSE LoanFinances.LegalEntityId END AS LegalEntityId,
CASE WHEN LeaseFinances.Id IS NOT NULL THEN LeaseFinances.InstrumentTypeId ELSE LoanFinances.InstrumentTypeId END AS InstrumentTypeId,
CASE WHEN LeaseFinances.Id IS NOT NULL THEN LeaseFinances.LineofBusinessId ELSE LoanFinances.LineofBusinessId END AS LineofBusinessId,
CASE WHEN LeaseFinances.Id IS NOT NULL THEN LeaseFinances.CostCenterId ELSE LoanFinances.CostCenterId END AS CostCenterId,
Contracts.SequenceNumber AS SequenceNumber
FROM
#PersistedWriteDownInfo
JOIN Contracts ON #PersistedWriteDownInfo.ContractId = Contracts.Id
LEFT JOIN LeaseFinances on #PersistedWriteDownInfo.LeaseFinanceId = LeaseFinances.Id
LEFT JOIN LoanFinances on #PersistedWriteDownInfo.LoanFinanceId = LoanFinances.Id
SELECT @ReceiptId as Id
--STUFF((SELECT ',' +CAST(PayableId AS NVARCHAR) FROM #PersistedPayableInfo FOR XML PATH('')),1,1,'') as PayableIdsInCsv
SELECT * FROM #CPUPayableIds --Getting the CPU Payable ids for DR creation
END
--ROLLBACK TRAN T
SET NOCOUNT OFF

GO

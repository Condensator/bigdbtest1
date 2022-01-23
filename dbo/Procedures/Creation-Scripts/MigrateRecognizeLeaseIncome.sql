SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[MigrateRecognizeLeaseIncome]
(
@UserId BIGINT ,
@ModuleIterationStatusId BIGINT,
@CreatedTime DATETIMEOFFSET,
@ProcessedRecords BIGINT OUTPUT,
@FailedRecords BIGINT OUTPUT
)
AS
BEGIN
SET NOCOUNT ON
DECLARE @Counter INT = 0
DECLARE @TakeCount INT = 500
DECLARE @SkipCount INT = 0
DECLARE @MaxRecognizeIncomeId INT = 0
SET @FailedRecords = 0
SET @ProcessedRecords = 0
WHILE @Counter < 1
BEGIN
CREATE TABLE #LeaseIncomeEntryItems
(
EntryItem NVARCHAR(100) NOT NULL,
AccountingTreatment NVARCHAR(100) NOT NULL,
IsDebit BIT NOT NULL,
ContractType  NVARCHAR(100) NOT NULL
)
CREATE TABLE #LeaseInterimInterestEntryItems
(
EntryItem NVARCHAR(100) NOT NULL,
AccountingTreatment NVARCHAR(100) NOT NULL,
IsDebit BIT NOT NULL
)
CREATE TABLE #LeaseInterimRentEntryItems
(
EntryItem NVARCHAR(100) NOT NULL,
AccountingTreatment NVARCHAR(100) NOT NULL,
IsDebit BIT NOT NULL
)
CREATE TABLE #LeaseAssetHistoryEntryItems
(
EntryItem NVARCHAR(100) NOT NULL,
AccountingTreatment NVARCHAR(100) NOT NULL,
IsDebit BIT NOT NULL
)
CREATE TABLE #LeaseBlendedIncomeEntryItems
(
EntryItem NVARCHAR(100) NOT NULL,
IsDebit BIT NOT NULL,
IncomeType NVARCHAR(100) NOT NULL,
SystemConfigType NVARCHAR(100) NULL,
BookRecognitionMode  NVARCHAR(100) NULL,
AccumulateExpense bit
)
CREATE TABLE #LeaseBlendedSetupEntryItems
(
EntryItem NVARCHAR(100) NOT NULL,
IsDebit BIT NOT NULL,
IncomeType NVARCHAR(100) NOT NULL,
BookRecognitionMode  NVARCHAR(100) NULL
)
--Lease Income Entries
INSERT INTO #LeaseIncomeEntryItems(EntryItem, AccountingTreatment, IsDebit, ContractType)
VALUES('UnearnedIncome', 'Both', 1, 'Capital')
INSERT INTO #LeaseIncomeEntryItems(EntryItem, AccountingTreatment, IsDebit, ContractType)
VALUES('UnearnedUnguaranteedResidualIncome', 'Both', 1, 'Capital')
INSERT INTO #LeaseIncomeEntryItems(EntryItem, AccountingTreatment, IsDebit, ContractType)
VALUES('Income', 'Both', 0, 'Capital')
INSERT INTO #LeaseIncomeEntryItems(EntryItem, AccountingTreatment, IsDebit, ContractType)
VALUES('UnguaranteedResidualIncome', 'Both', 0, 'Capital')
--Operating Lease
INSERT INTO #LeaseIncomeEntryItems(EntryItem, AccountingTreatment, IsDebit, ContractType)
VALUES('DeferredRentalRevenue', 'Both', 1, 'Operating')
INSERT INTO #LeaseIncomeEntryItems(EntryItem, AccountingTreatment, IsDebit, ContractType)
VALUES('RentalRevenue', 'AccrualBased', 0, 'Operating')
--Lease asset value histories
INSERT INTO #LeaseAssetHistoryEntryItems(EntryItem, AccountingTreatment, IsDebit)
VALUES('FixedTermDepreciation', 'Both', 1)
INSERT INTO #LeaseAssetHistoryEntryItems(EntryItem, AccountingTreatment, IsDebit)
VALUES('AccumulatedFixedTermDepreciation', 'Both', 0 )
--INSERT INTO #LeaseIncomeEntryItems(EntryItem, AccountingTreatment, IsDebit, ContractType)
--VALUES('SuspendedRentalRevenue', 'Both', 0, 'Operating')  --doubt Supplement Rent will be included or not
--Lease Interim Interest Entries
INSERT INTO #LeaseInterimInterestEntryItems(EntryItem, AccountingTreatment, IsDebit)
VALUES('AccruedInterimInterest', 'AccrualBased', 1)
INSERT INTO #LeaseInterimInterestEntryItems(EntryItem, AccountingTreatment, IsDebit)
VALUES('LeaseInterimInterestIncome', 'AccrualBased', 0)
--Lease Interim Rent Entries
INSERT INTO #LeaseInterimRentEntryItems(EntryItem, AccountingTreatment, IsDebit)
VALUES('DeferredInterimRentIncome', 'AccrualBased', 1)
INSERT INTO #LeaseInterimRentEntryItems(EntryItem, AccountingTreatment, IsDebit)
VALUES('InterimRentIncome', 'AccrualBased', 0)
--Lease Blended Income Entries
INSERT INTO #LeaseBlendedIncomeEntryItems(EntryItem, IsDebit, IncomeType, SystemConfigType, AccumulateExpense)
VALUES('UnearnedIncome', 1, 'Income','ReAccrualResidualIncome',0)
INSERT INTO #LeaseBlendedIncomeEntryItems(EntryItem, IsDebit, IncomeType, SystemConfigType, AccumulateExpense)
VALUES('Income', 0, 'Income','ReAccrualResidualIncome',0)
INSERT INTO #LeaseBlendedIncomeEntryItems(EntryItem, IsDebit, IncomeType, SystemConfigType, AccumulateExpense)
VALUES('UnearnedUnguaranteedResidualIncome', 1, 'Income','ReAccrualResidualIncome', 0)
INSERT INTO #LeaseBlendedIncomeEntryItems(EntryItem, IsDebit, IncomeType, SystemConfigType, AccumulateExpense)
VALUES('UnguaranteedResidualIncome', 0, 'Income','ReAccrualResidualIncome',0)
INSERT INTO #LeaseBlendedIncomeEntryItems(EntryItem, IsDebit, IncomeType, SystemConfigType, AccumulateExpense)
VALUES('DeferredRentalRevenue', 1, 'Income','ReAccrualRentalIncome',0)
INSERT INTO #LeaseBlendedIncomeEntryItems(EntryItem, IsDebit, IncomeType, SystemConfigType, AccumulateExpense)
VALUES('RentalRevenue', 0, 'Income','ReAccrualRentalIncome',0)
INSERT INTO #LeaseBlendedIncomeEntryItems(EntryItem, IsDebit, IncomeType, SystemConfigType, AccumulateExpense)
VALUES('DeferredBlendedIncome', 1, 'Income',NULL,0)
INSERT INTO #LeaseBlendedIncomeEntryItems(EntryItem, IsDebit, IncomeType, SystemConfigType, AccumulateExpense)
VALUES('BlendedIncome', 0, 'Income', NULL,0)
--Lease Blended Expense Entries
INSERT INTO #LeaseBlendedIncomeEntryItems(EntryItem, IsDebit, IncomeType, BookRecognitionMode, AccumulateExpense)
VALUES('BlendedExpense', 1, 'Expense', 'Both', 0)
INSERT INTO #LeaseBlendedIncomeEntryItems(EntryItem, IsDebit, IncomeType, BookRecognitionMode, AccumulateExpense)
VALUES('BlendedAccumulatedExpenseAccrete', 0,'Expense', 'Accrete',0)
INSERT INTO #LeaseBlendedIncomeEntryItems(EntryItem, IsDebit, IncomeType, BookRecognitionMode, AccumulateExpense)
VALUES('BlendedAccumulatedExpense', 0, 'Expense','Amortize',1)
INSERT INTO #LeaseBlendedIncomeEntryItems(EntryItem, IsDebit, IncomeType, BookRecognitionMode, AccumulateExpense)
VALUES('BlendedUnamortizedExpense', 0, 'Expense','Amortize',0)
--Lease Blended Setup Entries
INSERT INTO #LeaseBlendedSetupEntryItems(EntryItem, IsDebit, IncomeType, BookRecognitionMode)
VALUES('BlendedIncomeReceivable', 1, 'Income', 'Both')
INSERT INTO #LeaseBlendedSetupEntryItems(EntryItem, IsDebit, IncomeType, BookRecognitionMode)
VALUES('BlendedIncome', 0,'Income', 'RecognizeImmediately')
INSERT INTO #LeaseBlendedSetupEntryItems(EntryItem, IsDebit, IncomeType, BookRecognitionMode)
VALUES('DeferredBlendedIncome', 0, 'Income','Amortize')
INSERT INTO #LeaseBlendedSetupEntryItems(EntryItem, IsDebit, IncomeType, BookRecognitionMode)
VALUES('DeferredBlendedIncome', 0, 'Income','Accrete')
INSERT INTO #LeaseBlendedSetupEntryItems(EntryItem, IsDebit, IncomeType, BookRecognitionMode)
VALUES('BlendedExpensePayable', 0, 'Other','Both')
INSERT INTO #LeaseBlendedSetupEntryItems(EntryItem, IsDebit, IncomeType, BookRecognitionMode)
VALUES('BlendedExpense', 1, 'Other','RecognizeImmediately')
INSERT INTO #LeaseBlendedSetupEntryItems(EntryItem, IsDebit, IncomeType, BookRecognitionMode)
VALUES('BlendedUnamortizedExpense', 1, 'Other','Amortize')
INSERT INTO #LeaseBlendedSetupEntryItems(EntryItem, IsDebit, IncomeType, BookRecognitionMode)
VALUES('BlendedAccumulatedExpenseAccrete', 1, 'Other','Accrete')
DECLARE @TotalRecordsCount INT = (SELECT COUNT(Id) FROM stgRecognizeIncomeParam IntermediateIncomeDetails
WHERE	IsMigrated = 0)
SET @MaxRecognizeIncomeId = 0
SET  @SkipCount = 0
WHILE @SkipCount < @TotalRecordsCount
BEGIN
CREATE TABLE #ErrorLogs
(
Id BIGINT not null IDENTITY PRIMARY KEY,
StagingRootEntityId BIGINT,
Result NVARCHAR(12),
Message NVARCHAR(MAX)
)
CREATE TABLE #FailedProcessingLogs
(
[Action] NVARCHAR(10) NOT NULL,
[Id] BIGINT NOT NULL,
StagingRootEntityId BIGINT
)
CREATE TABLE #CreatedProcessingLogs
(
[Action] NVARCHAR(10) NOT NULL,
[Id] BIGINT NOT NULL
)
CREATE TABLE #CreatedGLJournalIds
(
[Action] NVARCHAR(10) NOT NULL,
[Id] BIGINT NOT NULL,
[LeaseIncomeScheduleId] BIGINT NOT NULL,
[LeaseIncomeParamId] BIGINT,
Postdate datetime
)
CREATE TABLE #CreatedBlendedGLJournalIds
(
[Action] NVARCHAR(10) NOT NULL,
[Id] BIGINT NOT NULL,
[BlendedIncomeScheduleId] BIGINT NOT NULL,
[BlendedItemId] BIGINT NOT NULL,
[LeaseIncomeParamId] BIGINT,
Postdate datetime
)
CREATE TABLE #CreatedBlendedSetupGLJournalIds
(
[Action] NVARCHAR(10) NOT NULL,
[Id] BIGINT NOT NULL,
[BlendedItemDetailId] BIGINT NOT NULL,
[BlendedItemId] BIGINT NOT NULL,
[LeaseIncomeParamId] BIGINT,
Postdate datetime
)
CREATE TABLE #LeaseGLDetails
(
GLTemplateId BIGINT,
MatchingGLTemplateDetailId BIGINT NULL,
GLTemplateDetailId BIGINT NOT NULL,
GLAccountId BIGINT NOT NULL,
EntryItemId BIGINT,
UserBookId BIGINT,
EntryItemName nvarchar(40),
IsDebit bit,
GLTemplateCategory  nvarchar(100)
)
CREATE TABLE #GLJournalDetailsToCreate
(
EntityId BIGINT,
EntityType  NVarChar(23),
Amount Decimal(16,2),
Currency nvarchar(3),
IsDebit BIT,
GLAccountNumber NVarChar(129),
Description NVarChar(200),
SourceId BIGINT,
CreatedById BIGINT
,CreatedTime DATETIMEOFFSET
,GLAccountId BIGINT
,GLTemplateDetailId BIGINT
,IncomeDate DATETIME
,SequenceNumber  NVarChar(129)
,LeaseIncomeParamId BIGINT
,LeaseIncomeScheduleId BIGINT
,LineOfBusinessId BIGINT
,Category NVarChar(129)
,MatchingGLTemplateDetailId BIGINT
)
SELECT TOP(@TakeCount)* INTO #LeaseIncomeRecognitionSubSet
FROM
stgRecognizeIncomeParam IntermediateLeaseIncome
WHERE
IntermediateLeaseIncome.IsMigrated = 0
AND IntermediateLeaseIncome.Id > @MaxRecognizeIncomeId
ORDER BY IntermediateLeaseIncome.Id
SELECT
IntermediateLeaseIncomeParam.Id AS LeaseIncomeParamId
,IntermediateLeaseIncomeParam.SequenceNumber
,IntermediateLeaseIncomeParam.ProcessThroughDate
,IntermediateLeaseIncomeParam.PostDate
,C.Id AS ContractId
,C.ContractType
,LFD.LeaseIncomeGLTemplateId
,LFD.LeaseBookingGLTemplateId
,LFD.InterimInterestIncomeGLTemplateId
,LFD.InterimRentIncomeGLTemplateId
,LIGL.IsActive AS IsLeaseIncomeGLActive
,LIGL.IsReadyToUse AS IsLeaseIncomeGLReadyToUse
,LF.LegalEntityId
,LF.CustomerId
,LF.Id AS LeaseFinanceId
,LFD.MaturityDate
,LFD.LeaseContractType
,LFD.IsOverTermLease
,RC.GLTemplateId LeaseARGLtemplateID
INTO #LeaseIncomeContractDetails
FROM #LeaseIncomeRecognitionSubSet IntermediateLeaseIncomeParam
JOIN Contracts C
ON IntermediateLeaseIncomeParam.SequenceNumber = C.SequenceNumber
JOIN LeaseFinances LF
ON C.Id = LF.ContractId and LF.IsCurrent=1
JOIN LeaseFinanceDetails LFD
ON LF.Id = LFD.Id
JOIN ReceivableCodes RC
ON RC.id = LFD.FixedTermReceivableCodeId
JOIN GLTemplates LIGL
ON LFD.LeaseIncomeGLTemplateId = LIGL.Id
SELECT @MaxRecognizeIncomeId = MAX(LeaseIncomeParamId) FROM #LeaseIncomeContractDetails
SELECT
GLTemplateDetails.GLTemplateId MatchingGLTemplateId
,GLTemplateDetails.Id GLTemplateDetailId
,GLTemplateDetails.GLAccountId
,GLTemplateDetails.EntryItemId
INTO #MatchingEntryItems
FROM #LeaseIncomeContractDetails
JOIN GLTemplateDetails
ON ((#LeaseIncomeContractDetails.LeaseContractType = 'Operating' AND #LeaseIncomeContractDetails.LeaseARGLtemplateID = GLTemplateDetails.GLTemplateId ) OR (#LeaseIncomeContractDetails.LeaseContractType != 'Operating' AND #LeaseIncomeContractDetails.LeaseBookingGLTemplateId = GLTemplateDetails.GLTemplateId ))
AND GLTemplateDetails.IsActive = 1
--Lease GL Details
INSERT INTO #LeaseGLDetails
(
GLTemplateId ,
MatchingGLTemplateDetailId,
GLTemplateDetailId,
GLAccountId,
EntryItemId ,
UserBookId ,
EntryItemName,
IsDebit ,
GLTemplateCategory
)
SELECT
GLTemplateId
,MatchingGLTemplateDetailId
,GLTemplateDetailId
,GLAccountId
,EntryItemId
,UserBookId
,EntryItemName
,IsDebit
,GLTemplateCategory
FROM
(
SELECT DISTINCT
LI.LeaseIncomeGLTemplateId GLTemplateId
,CASE WHEN GLTD.GLAccountId IS NOT NULL THEN NULL ELSE ME.GLTemplateDetailId END MatchingGLTemplateDetailId
,GLTD.Id AS GLTemplateDetailId
,CASE WHEN GLTD.GLAccountId IS NOT NULL THEN GLTD.GLAccountId ELSE ME.GLAccountId END GLAccountId
,GLTD.EntryItemId
,GLTD.UserBookId
,GLE.Name EntryItemName
,GLE.IsDebit
,'LeaseIncomeGLTemplate' GLTemplateCategory
FROM #LeaseIncomeContractDetails LI
JOIN GLTemplateDetails GLTD
ON LI.LeaseIncomeGLTemplateId = GLTD.GLTemplateId AND GLTD.IsActive = 1
JOIN GLEntryItems GLE
ON GLTD.EntryItemId = GLE.Id
LEFT JOIN GLAccountDetails GLAD
ON GLTD.GLAccountId = GLAD.GLAccountId
LEFT JOIN GLMatchingEntryItems GLME
ON GLE.Id = GLME.GLEntryItemId
LEFT JOIN #MatchingEntryItems ME
ON ((LI.LeaseContractType = 'Operating' AND  LI.LeaseARGLtemplateID = ME.MatchingGLTemplateId ) OR (LI.LeaseContractType != 'Operating' AND  LI.LeaseBookingGLTemplateId = ME.MatchingGLTemplateId ) )
AND GLME.MatchingEntryItemId = ME.EntryItemId
UNION ALL
SELECT DISTINCT
LI.InterimInterestIncomeGLTemplateId GLTemplateId
,NULL MatchingGLTemplateDetailId
,GLTD.Id AS GLTemplateDetailId
,GLTD.GLAccountId GLAccountId
,GLTD.EntryItemId
,GLTD.UserBookId
,GLE.Name EntryItemName
,GLE.IsDebit
,'InterimInterestIncomeGLTemplate' GLTemplateCategory
FROM #LeaseIncomeContractDetails LI
JOIN GLTemplateDetails GLTD
ON LI.InterimInterestIncomeGLTemplateId = GLTD.GLTemplateId AND GLTD.IsActive = 1
JOIN GLEntryItems GLE
ON GLTD.EntryItemId = GLE.Id
LEFT JOIN GLAccountDetails GLAD
ON GLTD.GLAccountId = GLAD.GLAccountId
UNION ALL
SELECT DISTINCT
LI.InterimRentIncomeGLTemplateId GLTemplateId
,NULL MatchingGLTemplateDetailId
,GLTD.Id AS GLTemplateDetailId
,GLTD.GLAccountId GLAccountId
,GLTD.EntryItemId
,GLTD.UserBookId
,GLE.Name EntryItemName
,GLE.IsDebit
,'InterimRentIncomeGLTemplate' GLTemplateCategory
FROM #LeaseIncomeContractDetails LI
JOIN GLTemplateDetails GLTD
ON LI.InterimRentIncomeGLTemplateId = GLTD.GLTemplateId AND GLTD.IsActive = 1
JOIN GLEntryItems GLE
ON GLTD.EntryItemId = GLE.Id
LEFT JOIN GLAccountDetails GLAD
ON GLTD.GLAccountId = GLAD.GLAccountId
UNION ALL
SELECT DISTINCT
BI.RecognitionGLTemplateId GLTemplateId
,CASE WHEN GLTD.GLAccountId IS NOT NULL THEN NULL ELSE MEGLTD.ID END MatchingGLTemplateDetailId
,GLTD.Id AS GLTemplateDetailId
,CASE WHEN GLTD.GLAccountId IS NOT NULL THEN GLTD.GLAccountId ELSE MEGLTD.GLAccountId END GLAccountId
,GLTD.EntryItemId
,GLTD.UserBookId
,GLE.Name EntryItemName
,GLE.IsDebit
,'BIRecognitionGLTemplate' GLTemplateCategory
FROM #LeaseIncomeContractDetails LI
JOIN LeaseBlendedItems LBI
ON LBI.LeaseFinanceid = LI.LeaseFinanceid
JOIN BlendedItems BI
ON BI.id = LBI.BlendedItemid
JOIN GLTemplateDetails GLTD
ON BI.RecognitionGLTemplateId = GLTD.GLTemplateId AND GLTD.IsActive = 1
JOIN GLEntryItems GLE
ON GLTD.EntryItemId = GLE.Id
JOIN #LeaseBlendedIncomeEntryItems BE
ON GLE.Name = BE.EntryItem
LEFT JOIN GLAccountDetails GLAD
ON GLTD.GLAccountId = GLAD.GLAccountId
LEFT JOIN GLMatchingEntryItems GLME
ON GLE.Id = GLME.GLEntryItemId
LEFT JOIN GLTemplateDetails MEGLTD
ON MEGLTD.GLTemplateId = BI.BookingGLTemplateId
AND GLME.MatchingEntryItemId = MEGLTD.EntryItemId
WHERE BI.SystemConfigType not in ('ReAccrualIncome','ReAccrualResidualIncome','ReAccrualRentalIncome')
UNION
SELECT DISTINCT
BI.BookingGLTemplateId GLTemplateId
,NULL MatchingGLTemplateDetailId
,GLTD.Id AS GLTemplateDetailId
,GLTD.GLAccountId GLAccountId
,GLTD.EntryItemId
,GLTD.UserBookId
,GLE.Name EntryItemName
,GLE.IsDebit
,'BISetupGLTemplate' GLTemplateCategory
FROM #LeaseIncomeContractDetails LI
JOIN LeaseBlendedItems LBI
ON LBI.LeaseFinanceid = LI.LeaseFinanceid
JOIN BlendedItems BI
ON BI.id = LBI.BlendedItemid
JOIN GLTemplateDetails GLTD
ON BI.BookingGLTemplateId = GLTD.GLTemplateId AND GLTD.IsActive = 1
JOIN GLEntryItems GLE
ON GLTD.EntryItemId = GLE.Id
JOIN #LeaseBlendedSetupEntryItems BE
ON GLE.Name = BE.EntryItem
LEFT JOIN GLAccountDetails GLAD
ON GLTD.GLAccountId = GLAD.GLAccountId
where BI.BookingGLTemplateId is not null
) TEMP
SELECT DISTINCT
LI.GLAccountId, GLAD.SegmentNumber, GLAD.SegmentValue
INTO #LISegmentDetails
FROM #LeaseGLDetails LI
JOIN GLAccountDetails GLAD
ON LI.GLAccountId = GLAD.GLAccountId AND GLAD.IsDynamic = 0 ;--AND GLAD.IsActive = 1 ;
SELECT DISTINCT
LIGL.GLTemplateId
,LIGL.GLTemplateDetailId
,LIGL.GLAccountId
,LIGL.EntryItemId
,LIGL.UserBookId
,AN.SegmentValue GLAccountNumber
,LIGL.EntryItemName
,LIGL.IsDebit
,LIGL.GLTemplateCategory
INTO #LeaseIncomeGLAccountDetails
FROM #LeaseGLDetails LIGL
JOIN #LISegmentDetails AN
ON LIGL.GLAccountId = AN.GLAccountId
SELECT
ContractDetail.SequenceNumber
,ContractDetail.LeaseIncomeParamId
,ContractDetail.ContractId
,ContractDetail.ContractType
,ContractDetail.LeaseContractType
,ContractDetail.LeaseFinanceId
,ContractDetail.LegalEntityId
,ContractDetail.CustomerId
,ContractDetail.ProcessThroughDate
,ContractDetail.MaturityDate
,ContractDetail.LeaseIncomeGLTemplateId
,ContractDetail.InterimInterestIncomeGLTemplateID
,ContractDetail.InterimRentIncomeGLTemplateID
,LIS.Id AS LeaseIncomeScheduleId
,LIS.IncomeDate
,ContractDetail.PostDate
,LIS.IncomeType
,LIS.AccountingTreatment
,LIS.ResidualIncome_Amount
,LIS.RentalIncome_Amount
,LIS.IncomeAccrued_Amount
,LIS.Income_Amount
,LIS.IsNonAccrual
,LIS.IsGLPosted
,ContractDetail.IsLeaseIncomeGLReadyToUse
,LIS.Income_Currency
,null as GLJournalId
INTO #LeaseIncomeMappedWithTarget
FROM #LeaseIncomeContractDetails ContractDetail
JOIN LeaseIncomeSchedules LIS
ON ContractDetail.LeaseFinanceId = LIS.LeaseFinanceId
WHERE LIS.IncomeDate <= ContractDetail.ProcessThroughDate AND LIS.IsAccounting = 1 AND LIS.AdjustmentEntry = 0 AND LIS.IsGLPosted = 0
AND LIS.IncomeType NOT IN ( 'OverTerm','Supplemental')
ORDER BY ContractDetail.LeaseIncomeParamId
SELECT
ContractDetail.SequenceNumber
,ContractDetail.LeaseIncomeParamId
,ContractDetail.ContractId
,ContractDetail.ContractType
,ContractDetail.LeaseContractType
,ContractDetail.LeaseFinanceId
,ContractDetail.LegalEntityId
,ContractDetail.CustomerId
,ContractDetail.ProcessThroughDate
,ContractDetail.MaturityDate
,BIS.IncomeDate
,bis.id BlendedIncomeScheduleId
,ContractDetail.PostDate
,BIS.Income_Amount
,BIS.Income_Currency
,BIS.IsNonAccrual
,BIS.BlendedItemId
,BI.Name BlendedItemName
,ContractDetail.IsLeaseIncomeGLReadyToUse
,null as GLJournalId
,BI.RecognitionGLTemplateID
,BI.Type IncomeType
,BI.BookRecognitionMode
,BI.AccumulateExpense
,BI.SystemConfigType
,CASE WHEN BI.SystemConfigType  in ('ReAccrualIncome','ReAccrualResidualIncome','ReAccrualRentalIncome') THEN ContractDetail.LeaseIncomeGLTemplateId ELSE BI.RecognitionGLTemplateID
END AS GLTemplateID
,CASE WHEN BI.SystemConfigType  in ('ReAccrualIncome','ReAccrualResidualIncome','ReAccrualRentalIncome') THEN 'LeaseIncomeGLTemplate' ELSE 'BIRecognitionGLTemplate'
END AS GLTemplateCategory
INTO #LeaseBlendedIncomeMappedWithTarget
FROM #LeaseIncomeContractDetails ContractDetail
JOIN BlendedIncomeSchedules BIS
ON ContractDetail.LeaseFinanceId = BIS.LeaseFinanceId
JOIN BlendedItems BI
ON BI.Id = BIS.BlendedItemId
WHERE BIS.IncomeDate <= ContractDetail.ProcessThroughDate AND BIS.IsAccounting = 1 AND BIS.AdjustmentEntry = 0
and BIS.PostDate is null
ORDER BY ContractDetail.LeaseIncomeParamId
----Blended Item Setup GL's
SELECT
ContractDetail.SequenceNumber
,ContractDetail.LeaseIncomeParamId
,ContractDetail.ContractId
,ContractDetail.ContractType
,ContractDetail.LeaseContractType
,ContractDetail.LeaseFinanceId
,ContractDetail.LegalEntityId
,ContractDetail.CustomerId
,ContractDetail.ProcessThroughDate
,ContractDetail.MaturityDate
,BID.DueDate
,BID.id blendedItemdetailId
,ContractDetail.PostDate
,BID.Amount_Amount
,BID.Amount_Currency
,BID.BlendedItemId
,BI.Name BlendedItemName
,ContractDetail.IsLeaseIncomeGLReadyToUse
,null as GLJournalId
,BI.RecognitionGLTemplateID
,BI.Type IncomeType
,BI.BookRecognitionMode
,BI.Occurrence
,BI.AccumulateExpense
,BI.SystemConfigType
,BI.BookingGLTemplateID
INTO #LeaseBlendedSetupMappedWithTarget
FROM #LeaseIncomeContractDetails ContractDetail
JOIN LeaseBlendedItems LBI
ON ContractDetail.LeaseFinanceId = LBI.LeaseFinanceId
JOIN BlendedItems BI
ON BI.Id = LBI.BlendedItemId AND BI.ISACTIVE =1
JOIN BlendedItemDetails BID
ON BID.BlendedItemId = BI.Id
WHERE BID.DueDate <= ContractDetail.ProcessThroughDate AND BID.IsGLposted = 0
AND (BI.Occurrence = 'Recurring' OR BookRecognitionMode = 'Accrete')
ORDER BY ContractDetail.LeaseIncomeParamId
--Lease Blended Income
SELECT
LIS.ContractId AS EntityId
,'Contract' AS EntityType
,LIS.Income_Amount Amount
,LIS.Income_Currency Currency
,LIG.IsDebit
,Concat(LE.LegalEntityNumber,'-',CCC.CostCenter,'-',LTRIM(LIGA.GLAccountNumber)) GLAccountNumber --LIGA.GLAccountNumber
,'Blended Item Name: ' + LIS.BlendedItemName + ' Seq Number : ' + LIS.SequenceNumber + ' IncomeDate : ' + 	 CAST (LIS.IncomeDate AS NVARCHAR(25)) AS Description
,LIS.BlendedItemId AS SourceId
,@UserId AS CreatedById
,@CreatedTime AS CreatedTime
,LIGA.GLAccountId
,LIGA.GLTemplateDetailId
,LIS.IncomeDate
,LIS.SequenceNumber
,LIS.LeaseIncomeParamId
,LIS.BlendedIncomeScheduleId
,LF.LineOfBusinessId
,NULL GLJOURNALID
,LIG.MatchingGLTemplateDetailId
INTO #TemporaryBlendedIncomeGLJournalDetails
FROM #LeaseBlendedIncomeMappedWithTarget LIS
JOIN #LeaseGLDetails LIG
ON LIS.GLTemplateId = LIG.GLTemplateId
AND LIG.GLTemplateCategory = LIS.GLTemplateCategory
JOIN LeaseFinances LF
ON LF.ID = LIS.LeaseFinanceID
JOIN #LeaseIncomeGLAccountDetails LIGA
ON LIG.GLTemplateDetailId = LIGA.GLTemplateDetailId
AND LIG.GLAccountId = LIGA.GLAccountId
AND LIG.EntryItemName  = LIGA.EntryItemName
AND LIG.IsDebit = LIGA.IsDebit
JOIN #LeaseBlendedIncomeEntryItems LIE
ON LIG.EntryItemName = LIE.EntryItem
AND LIG.IsDebit = LIE.IsDebit
AND
((LIS.IncomeType = 'Income' AND LIS.IncomeType = LIE.IncomeType AND (LIS.SystemConfigType NOT IN ('ReAccrualIncome','ReAccrualResidualIncome','ReAccrualRentalIncome') OR LIS.SystemConfigType = LIE.SystemConfigType))
OR (LIS.IncomeType != 'Income' AND LIE.IncomeType != 'Income' AND  (LIE.BookRecognitionMode = 'BOTH' OR (LIS.BookRecognitionMode = LIE.BookRecognitionMode AND (LIE.BookRecognitionMode != 'Amortize' OR LIS.AccumulateExpense = LIE.AccumulateExpense))))
)
JOIN LegalEntities LE on LIS.LegalEntityId = LE.Id
JOIN Contracts C on LIS.ContractId = C.Id
JOIN CostCenterConfigs CCC on C.CostCenterId = CCC.Id
WHERE 1 = 1
--Lease Blended Setup
SELECT
LIS.ContractId AS EntityId
,'Contract' AS EntityType
,LIS.Amount_Amount Amount
,LIS.Amount_Currency Currency
,LIG.IsDebit
,Concat(LE.LegalEntityNumber,'-',CCC.CostCenter,'-',LTRIM(LIGA.GLAccountNumber)) GLAccountNumber --LIGA.GLAccountNumber
,LIS.Occurrence + ' setup for Blended Item Name: ' + LIS.BlendedItemName +' DueDate : ' + 	 CAST (LIS.DueDate AS NVARCHAR(25)) AS Description
,LIS.BlendedItemDetailId AS SourceId
,@UserId AS CreatedById
,@CreatedTime AS CreatedTime
,LIGA.GLAccountId
,LIGA.GLTemplateDetailId
,LIS.DueDate
,LIS.SequenceNumber
,LIS.LeaseIncomeParamId
,LIS.BlendedItemDetailId
,LIS.BlendedItemId
,LF.LineOfBusinessId
,LIG.MatchingGLTemplateDetailId
INTO #TemporaryBlendedSetupGLJournalDetails
FROM #LeaseBlendedSetupMappedWithTarget LIS
JOIN #LeaseGLDetails LIG
ON LIS.BookingGLTemplateID = LIG.GLTemplateId
AND LIG.GLTemplateCategory = 'BISetupGLTemplate'
JOIN LeaseFinances LF
ON LF.ID = LIS.LeaseFinanceID
JOIN #LeaseIncomeGLAccountDetails LIGA
ON LIG.GLTemplateDetailId = LIGA.GLTemplateDetailId
AND LIG.GLAccountId = LIGA.GLAccountId
AND LIG.EntryItemName  = LIGA.EntryItemName
AND LIG.IsDebit = LIGA.IsDebit
JOIN #LeaseBlendedSetupEntryItems LIE
ON LIG.EntryItemName = LIE.EntryItem
AND LIG.IsDebit = LIE.IsDebit
AND
(
(LIS.IncomeType = 'Income' AND LIS.IncomeType = LIE.IncomeType AND (LIE.BookRecognitionMode = 'BOTH' OR LIS.BookRecognitionMode  = LIE.BookRecognitionMode))
OR (LIS.IncomeType != 'Income' AND LIE.IncomeType = 'Other' AND  (LIE.BookRecognitionMode = 'BOTH' OR LIS.BookRecognitionMode = LIE.BookRecognitionMode ))
)
JOIN LegalEntities LE on LIS.LegalEntityId = LE.Id
JOIN Contracts C on LIS.ContractId = C.Id
JOIN CostCenterConfigs CCC on C.CostCenterId = CCC.Id
WHERE 1 = 1
--Lease FixedTerm
INSERT INTO #GLJournalDetailsToCreate
(
EntityId ,
EntityType  ,
Amount ,
Currency ,
IsDebit ,
GLAccountNumber ,
Description ,
SourceId ,
CreatedById ,
CreatedTime,
GLAccountId ,
GLTemplateDetailId ,
IncomeDate ,
SequenceNumber ,
LeaseIncomeParamId ,
LeaseIncomeScheduleId ,
LineOfBusinessId ,
category,
MatchingGLTemplateDetailId
)
SELECT
LIS.ContractId AS EntityId
,'Contract' AS EntityType
, case when LIS.LeaseContractType = 'Operating' then LIS.RentalIncome_Amount
else
CASE WHEN LIE.EntryItem  IN('UnearnedIncome', 'Income', 'SuspendedIncome') THEN LIS.Income_Amount - LIS.ResidualIncome_Amount
WHEN LIE.EntryItem  IN('UnearnedUnguaranteedResidualIncome', 'UnguaranteedResidualIncome', 'SuspendedUnguaranteedResidualIncome')  THEN LIS.ResidualIncome_Amount
ELSE 0.0 END
end Amount
,LIS.Income_Currency Currency
,LIG.IsDebit
,Concat(LE.LegalEntityNumber,'-',CCC.CostCenter,'-',LTRIM(LIGA.GLAccountNumber)) GLAccountNumber --LIGA.GLAccountNumber
,'Lease Income recognized for ' + LIS.SequenceNumber + ' lease and ' + CAST (LIS.IncomeDate AS NVARCHAR(25)) + ' income' AS Description
,LIS.LeaseIncomeScheduleId AS SourceId
,@UserId AS CreatedById
,@CreatedTime AS CreatedTime
,LIGA.GLAccountId
,LIGA.GLTemplateDetailId
,LIS.IncomeDate
,LIS.SequenceNumber
,LIS.LeaseIncomeParamId
,LIS.LeaseIncomeScheduleId
,LF.LineOfBusinessId
,'LeaseIncome'
,LIG.MatchingGLTemplateDetailId
--INTO #TemporaryLeaseIncomeGLJournalDetails
FROM #LeaseIncomeMappedWithTarget LIS
JOIN #LeaseGLDetails LIG
ON LIS.LeaseIncomeGLTemplateId = LIG.GLTemplateId
AND LIG.GLTemplateCategory ='LeaseIncomeGLTemplate'
JOIN LeaseFinances LF
ON LF.ID = LIS.LeaseFinanceID
JOIN #LeaseIncomeGLAccountDetails LIGA
ON LIG.GLTemplateDetailId = LIGA.GLTemplateDetailId AND LIG.GLAccountId = LIGA.GLAccountId
AND LIG.EntryItemName  = LIGA.EntryItemName AND LIG.IsDebit = LIGA.IsDebit
JOIN #LeaseIncomeEntryItems LIE
ON LIG.EntryItemName  = LIE.EntryItem
AND LIG.IsDebit = LIE.IsDebit
AND (LIS.LeaseContractType !=  'Operating' OR LIE.ContractType = LIS.LeaseContractType )
AND ((LIE.ContractType = 'Operating' And ( LIE.AccountingTreatment  = 'Both' OR LIE.AccountingTreatment  = LIS.AccountingTreatment ))  OR (LIE.ContractType !=  'Operating' AND LIE.AccountingTreatment  = 'Both' OR  LIE.AccountingTreatment =  LIS.AccountingTreatment ))
JOIN LegalEntities LE on LIS.LegalEntityId = LE.Id
JOIN Contracts C on LIS.ContractId = C.Id
JOIN CostCenterConfigs CCC on C.CostCenterId = CCC.Id
WHERE 1 = 1
AND LIS.IncomeType IN ( 'FixedTerm')
--Lease Asset value Histories
SELECT DISTINCT
TEMP.LeaseIncomeParamId
,AVH.AssetId
,AVH.Id assetValueHistoryID
,AVH.Value_Amount ValueAmount
,TEMP.LeaseIncomeScheduleId
,TEMP.IncomeDate
into #LeaseAssetValueHistories
FROM #LeaseIncomeMappedWithTarget TEMP
JOIN LeaseAssets LA ON LA.LeaseFinanceId = TEMP.LeaseFinanceId
join assetValueHistories AVH on LA.AssetId = AVH.AssetId
WHERE (LA.IsActive = 1 OR LA.TerminationDate > TEMP.MaturityDate) and AVH.GLJournalId is null
AND AVH.IncomeDate <= TEMP.ProcessThroughDate
AND TEMP.LeaseContractType = 'Operating' AND AVH.SourceModule = 'FixedTermDepreciation'
AND AVH.IncomeDate = TEMP.IncomeDate
AND TEMP.IncomeType = 'FixedTerm'
AND AVH.IsLessorOwned = 1
--OR (TEMP.IsOverTermLease = 1 AND TEMP.LeaseContractType != 'Operating' AND AVH.SourceModule IN ( 'ResidualRecapture' ,'ResidualReclass')) )-- TO CHECK LIS.IncomeType IN ( 'OverTerm','Supplemental')
;WITH CTE_FixedTermDep
AS
(
SELECT T.LeaseIncomeParamId,T.IncomeDate,T.LeaseIncomeScheduleId,-sum(T.ValueAmount) ValueAmount
FROM #LeaseAssetValueHistories T
GROUP BY T.LeaseIncomeParamId,T.IncomeDate,T.LeaseIncomeScheduleId
)
INSERT INTO #GLJournalDetailsToCreate
(
EntityId ,
EntityType  ,
Amount ,
Currency ,
IsDebit ,
GLAccountNumber ,
Description ,
SourceId ,
CreatedById ,
CreatedTime,
GLAccountId ,
GLTemplateDetailId ,
IncomeDate ,
SequenceNumber ,
LeaseIncomeParamId ,
LeaseIncomeScheduleId ,
LineOfBusinessId ,
category ,
MatchingGLTemplateDetailId
)
SELECT
LIS.ContractId AS EntityId
,'Contract' AS EntityType
, FTDep.ValueAmount Amount
,LIS.Income_Currency Currency
,LIG.IsDebit
,Concat(LE.LegalEntityNumber,'-',CCC.CostCenter,'-',LTRIM(LIGA.GLAccountNumber)) GLAccountNumber --LIGA.GLAccountNumber
,'Fixed Term Depreciation for ' + LIS.SequenceNumber + ' lease and ' + CAST (LIS.IncomeDate AS NVARCHAR(25)) + ' income' AS Description
,LIS.LeaseIncomeScheduleId AS SourceId
,@UserId AS CreatedById
,@CreatedTime AS CreatedTime
,LIGA.GLAccountId
,LIGA.GLTemplateDetailId
,LIS.IncomeDate
,LIS.SequenceNumber
,LIS.LeaseIncomeParamId
,LIS.LeaseIncomeScheduleId
,LF.LineOfBusinessId
,'FixedTermDep'
,LIG.MatchingGLTemplateDetailId
--INTO #TemporaryLeaseFixedTermDepGLJournalDetails
FROM #LeaseIncomeMappedWithTarget LIS
JOIN #LeaseGLDetails LIG
ON LIS.LeaseIncomeGLTemplateId = LIG.GLTemplateId
AND LIG.GLTemplateCategory ='LeaseIncomeGLTemplate'
JOIN LeaseFinances LF
ON LF.ID = LIS.LeaseFinanceID
JOIN CTE_FixedTermDep FTDep
ON FTDep.LeaseIncomeParamId = LIS.LeaseIncomeParamId
AND FTDep.IncomeDate = LIS.IncomeDate
AND FTDep.LeaseIncomeScheduleId = LIS.LeaseIncomeScheduleId
JOIN #LeaseIncomeGLAccountDetails LIGA
ON LIG.GLTemplateDetailId = LIGA.GLTemplateDetailId AND LIG.GLAccountId = LIGA.GLAccountId
AND LIG.EntryItemName  = LIGA.EntryItemName AND LIG.IsDebit = LIGA.IsDebit
JOIN #LeaseAssetHistoryEntryItems LIE
ON LIG.EntryItemName  = LIE.EntryItem
AND LIG.IsDebit = LIE.IsDebit
AND (LIE.AccountingTreatment  = 'Both' OR LIE.AccountingTreatment  = LIS.AccountingTreatment )
JOIN LegalEntities LE on LIS.LegalEntityId = LE.Id
JOIN Contracts C on LIS.ContractId = C.Id
JOIN CostCenterConfigs CCC on C.CostCenterId = CCC.Id
WHERE 1 = 1
AND LIS.LeaseContractType =  'Operating'
AND LIS.IncomeType IN ( 'FixedTerm')
--Lease InterimInterest
INSERT INTO #GLJournalDetailsToCreate
(
EntityId ,
EntityType  ,
Amount ,
Currency ,
IsDebit ,
GLAccountNumber ,
Description ,
SourceId ,
CreatedById ,
CreatedTime,
GLAccountId ,
GLTemplateDetailId ,
IncomeDate ,
SequenceNumber ,
LeaseIncomeParamId ,
LeaseIncomeScheduleId ,
LineOfBusinessId ,
category,
MatchingGLTemplateDetailId
)
SELECT
LIS.ContractId AS EntityId
,'Contract' AS EntityType
,LIS.Income_Amount Amount
,LIS.Income_Currency Currency
,LIG.IsDebit
,Concat(LE.LegalEntityNumber,'-',CCC.CostCenter,'-',LTRIM(LIGA.GLAccountNumber)) GLAccountNumber --LIGA.GLAccountNumber
,'Lease Income recognized for ' + LIS.SequenceNumber + ' lease and ' + CAST (LIS.IncomeDate AS NVARCHAR(25)) + ' income' AS Description
,LIS.LeaseIncomeScheduleId AS SourceId
,@UserId AS CreatedById
,@CreatedTime AS CreatedTime
,LIGA.GLAccountId
,LIGA.GLTemplateDetailId
,LIS.IncomeDate
,LIS.SequenceNumber
,LIS.LeaseIncomeParamId
,LIS.LeaseIncomeScheduleId
,LF.LineOfBusinessId
,'InterimInterest'
,LIG.MatchingGLTemplateDetailId
--INTO #TemporaryLeaseInterimInterestGLJournalDetails
FROM #LeaseIncomeMappedWithTarget LIS
JOIN #LeaseGLDetails LIG
ON LIS.InterimRentIncomeGLTemplateID = LIG.GLTemplateId
AND LIG.GLTemplateCategory = 'InterimInterestIncomeGLTemplate'
JOIN LeaseFinances LF
ON LF.ID = LIS.LeaseFinanceID
JOIN #LeaseIncomeGLAccountDetails LIGA
ON LIG.GLTemplateDetailId = LIGA.GLTemplateDetailId AND LIG.GLAccountId = LIGA.GLAccountId
AND LIG.EntryItemName  = LIGA.EntryItemName AND LIG.IsDebit = LIGA.IsDebit
JOIN #LeaseInterimInterestEntryItems LIE
ON LIG.EntryItemName  = LIE.EntryItem  AND (LIE.AccountingTreatment  = 'Both' OR LIE.AccountingTreatment  = LIS.AccountingTreatment  )
AND LIG.IsDebit = LIE.IsDebit
JOIN LegalEntities LE on LIS.LegalEntityId = LE.Id
JOIN Contracts C on LIS.ContractId = C.Id
JOIN CostCenterConfigs CCC on C.CostCenterId = CCC.Id
WHERE 1 = 1
AND LIS.IncomeType IN ( 'InterimInterest')
--Lease InterimRent
INSERT INTO #GLJournalDetailsToCreate
(
EntityId ,
EntityType  ,
Amount ,
Currency ,
IsDebit ,
GLAccountNumber ,
Description ,
SourceId ,
CreatedById ,
CreatedTime,
GLAccountId ,
GLTemplateDetailId ,
IncomeDate ,
SequenceNumber ,
LeaseIncomeParamId ,
LeaseIncomeScheduleId ,
LineOfBusinessId ,
category,
MatchingGLTemplateDetailId
)
SELECT
LIS.ContractId AS EntityId
,'Contract' AS EntityType
,LIS.RentalIncome_Amount Amount
,LIS.Income_Currency Currency
,LIG.IsDebit
,Concat(LE.LegalEntityNumber,'-',CCC.CostCenter,'-',LTRIM(LIGA.GLAccountNumber)) GLAccountNumber --LIGA.GLAccountNumber
,'Lease Income recognized for ' + LIS.SequenceNumber + ' lease and ' + CAST (LIS.IncomeDate AS NVARCHAR(25)) + ' income' AS Description
,LIS.LeaseIncomeScheduleId AS SourceId
,@UserId AS CreatedById
,@CreatedTime AS CreatedTime
,LIGA.GLAccountId
,LIGA.GLTemplateDetailId
,LIS.IncomeDate
,LIS.SequenceNumber
,LIS.LeaseIncomeParamId
,LIS.LeaseIncomeScheduleId
,LF.LineOfBusinessId
,'InterimRent'
,LIG.MatchingGLTemplateDetailId
--INTO #TemporaryLeaseInterimRentGLJournalDetails
FROM #LeaseIncomeMappedWithTarget LIS
JOIN #LeaseGLDetails LIG
ON LIS.InterimRentIncomeGLTemplateID = LIG.GLTemplateId
AND LIG.GLTemplateCategory = 'InterimRentIncomeGLTemplate'
JOIN LeaseFinances LF
ON LF.ID = LIS.LeaseFinanceID
JOIN #LeaseIncomeGLAccountDetails LIGA
ON LIG.GLTemplateDetailId = LIGA.GLTemplateDetailId AND LIG.GLAccountId = LIGA.GLAccountId
AND LIG.EntryItemName  = LIGA.EntryItemName AND LIG.IsDebit = LIGA.IsDebit
JOIN #LeaseInterimRentEntryItems LIE
ON LIG.EntryItemName  = LIE.EntryItem  AND (LIE.AccountingTreatment  = 'Both' OR LIE.AccountingTreatment  = LIS.AccountingTreatment  )
AND LIG.IsDebit = LIE.IsDebit
JOIN LegalEntities LE on LIS.LegalEntityId = LE.Id
JOIN Contracts C on LIS.ContractId = C.Id
JOIN CostCenterConfigs CCC on C.CostCenterId = CCC.Id
WHERE 1 = 1
AND LIS.IncomeType IN ( 'InterimRent')
--errorlogs--
INSERT INTO #ErrorLogs
SELECT
DISTINCT LeaseIncomeParamId
,'Error'
,('No <Lease> found with filter <SequenceNumber='+  SequenceNumber +'> while executing EditReference<Lease>')  AS Message
FROM
#LeaseIncomeContractDetails
WHERE SequenceNumber IS NOT NULL AND ContractId IS NULL
INSERT INTO #ErrorLogs
SELECT
LeaseIncomeParamId
,'Error'
,('Lease Income GL Template is not Ready to Use')  AS Message
FROM
#LeaseIncomeContractDetails
WHERE LeaseIncomeGLTemplateId IS NOT NULL AND IsLeaseIncomeGLReadyToUse = 0
INSERT INTO #ErrorLogs
SELECT
DISTINCT T.LeaseIncomeParamId
,'Error'
,('No income schedules were found before the process through date'+' '+Convert(varchar(50),T.ProcessThroughDate))  AS Message
FROM
#LeaseIncomeContractDetails T
LEFT JOIN #LeaseIncomeMappedWithTarget L1 ON T.LeaseIncomeParamId = L1.LeaseIncomeParamId
LEFT JOIN #TemporaryBlendedIncomeGLJournalDetails L2 ON T.LeaseIncomeParamId = L2.LeaseIncomeParamId
LEFT JOIN #TemporaryBlendedSetupGLJournalDetails L3 ON T.LeaseIncomeParamId = L3.LeaseIncomeParamId
where ( L1.LeaseIncomeParamId is null and  L2.LeaseIncomeParamId is null  and L3.LeaseIncomeParamId is null)
--INSERT INTO #ErrorLogs
--	SELECT
--	DISTINCT T.LeaseIncomeParamId
--	,'Error'
--	,('No Records found')  AS Message
--	FROM #LeaseIncomeMappedWithTarget T
--	LEFT JOIN #GLJournalDetailsToCreate LI ON T.LeaseIncomeParamId = LI.LeaseIncomeParamId
--	WHERE LI.LeaseIncomeScheduleId IS NULL
--	--GROUP BY T.LeaseIncomeParamId HAVING count(LI.LeaseIncomeScheduleId) = 0
--INSERT INTO #ErrorLogs
--	SELECT
--	DISTINCT T.LeaseIncomeParamId
--	,'Error'
--	,('No Records found')  AS Message
--	FROM #LeaseBlendedIncomeMappedWithTarget T
--	LEFT JOIN #TemporaryBlendedIncomeGLJournalDetails LI ON T.LeaseIncomeParamId = LI.LeaseIncomeParamId
--	WHERE LI.BlendedIncomeScheduleId IS NULL
--	--GROUP BY T.LeaseIncomeParamId HAVING count(LI.BlendedIncomeScheduleId) = 0
--INSERT INTO #ErrorLogs
--	SELECT
--	DISTINCT T.LeaseIncomeParamId
--	,'Error'
--	,('No Records found')  AS Message
--	FROM #LeaseBlendedSetupMappedWithTarget T
--	LEFT JOIN #TemporaryBlendedSetupGLJournalDetails LI ON T.LeaseIncomeParamId = LI.LeaseIncomeParamId
--	WHERE LI.BlendedItemId IS NULL
--	--GROUP BY T.LeaseIncomeParamId HAVING count(LI.BlendedItemId) = 0
INSERT INTO #ErrorLogs
SELECT
LeaseIncomeParamId
,'Error'
,('Post date is not within the GL open period')  AS Message
FROM
#LeaseIncomeContractDetails LCD
JOIN GLFinancialOpenPeriods GLF
ON LCD.LegalEntityId=GLF.LegalEntityId
WHERE LCD.PostDate NOT BETWEEN GLF.FromDate AND GLF.ToDate AND GLF.IsCurrent=1
SELECT
LI.SequenceNumber
,LI.IncomeDate
,LI.IsDebit
,CASE WHEN IsDebit = 1 THEN Amount ELSE (-1 * Amount) END Amount
,LI.LeaseIncomeParamId
INTO #LeaseIncomeAmounts
FROM #GLJournalDetailsToCreate LI
where category ='LeaseIncome'
SELECT
LI.SequenceNumber
,LI.IncomeDate
,LI.IsDebit
,CASE WHEN IsDebit = 1 THEN Amount ELSE (-1 * Amount) END Amount
,LI.LeaseIncomeParamId
into #LeaseInterimInterestAmounts
FROM #GLJournalDetailsToCreate LI
where category ='InterimInterest'
SELECT
LI.SequenceNumber
,LI.IncomeDate
,LI.IsDebit
,CASE WHEN IsDebit = 1 THEN Amount ELSE (-1 * Amount) END Amount
,LI.LeaseIncomeParamId
into #LeaseInterimRentAmounts
FROM #GLJournalDetailsToCreate LI
where category ='InterimRent'
SELECT
LI.SequenceNumber
,LI.IncomeDate
,LI.IsDebit
,CASE WHEN IsDebit = 1 THEN Amount ELSE (-1 * Amount) END Amount
,LI.LeaseIncomeParamId
into #LeaseFTDepAmounts
FROM #GLJournalDetailsToCreate LI
where category ='FixedTermDep'
SELECT
LI.SequenceNumber
,LI.IncomeDate
,LI.IsDebit
,CASE WHEN IsDebit = 1 THEN Amount ELSE (-1 * Amount) END Amount
,LI.LeaseIncomeParamId
into #LeaseBIAmounts
FROM #TemporaryBlendedIncomeGLJournalDetails LI
--where category ='BlendedIncome'
--#TemporaryBlendedSetupGLJournalDetails
SELECT
LI.SequenceNumber
,LI.DueDate
,LI.IsDebit
,CASE WHEN IsDebit = 1 THEN Amount ELSE (-1 * Amount) END Amount
,LI.LeaseIncomeParamId
into #LeaseBISetupAmounts
FROM #TemporaryBlendedSetupGLJournalDetails LI
INSERT INTO #ErrorLogs
SELECT
DISTINCT LI.LeaseIncomeParamId
,'Error'
,('Total Credit should be equal to Total Debit for Lease income on'+' '+Convert(varchar(50),IncomeDate))  AS Message
FROM
#LeaseIncomeAmounts LI
GROUP BY LI.LeaseIncomeParamId, LI.SequenceNumber, LI.IncomeDate HAVING SUM(Amount) <> 0
INSERT INTO #ErrorLogs
SELECT
DISTINCT LI.LeaseIncomeParamId
,'Error'
,('Total Credit should be equal to Total Debit for Lease Fixed Term Dep income on'+' '+Convert(varchar(50),IncomeDate))  AS Message
FROM
#LeaseFTDepAmounts LI
GROUP BY LI.LeaseIncomeParamId, LI.SequenceNumber, LI.IncomeDate HAVING SUM(Amount) <> 0
INSERT INTO #ErrorLogs
SELECT
DISTINCT LI.LeaseIncomeParamId
,'Error'
,('Total Credit should be equal to Total Debit for Lease Interim Rent Dep income on'+' '+Convert(varchar(50),IncomeDate))  AS Message
FROM
#LeaseInterimRentAmounts LI
GROUP BY LI.LeaseIncomeParamId, LI.SequenceNumber, LI.IncomeDate HAVING SUM(Amount) <> 0
INSERT INTO #ErrorLogs
SELECT
DISTINCT LI.LeaseIncomeParamId
,'Error'
,('Total Credit should be equal to Total Debit for Lease Interim Interest income on'+' '+Convert(varchar(50),IncomeDate))  AS Message
FROM
#LeaseInterimInterestAmounts LI
GROUP BY LI.LeaseIncomeParamId, LI.SequenceNumber, LI.IncomeDate HAVING SUM(Amount) <> 0
INSERT INTO #ErrorLogs
SELECT
DISTINCT LI.LeaseIncomeParamId
,'Error'
,('Total Credit should be equal to Total Debit for Lease Blended Income on'+' '+Convert(varchar(50),IncomeDate))  AS Message
FROM
#LeaseBIAmounts LI
GROUP BY LI.LeaseIncomeParamId, LI.SequenceNumber, LI.IncomeDate HAVING SUM(Amount) <> 0
INSERT INTO #ErrorLogs
SELECT
DISTINCT LI.LeaseIncomeParamId
,'Error'
,('Total Credit should be equal to Total Debit for Lease Blended Income on'+' '+Convert(varchar(50),DueDate))  AS Message
FROM
#LeaseBISetupAmounts LI
GROUP BY LI.LeaseIncomeParamId, LI.SequenceNumber, LI.DueDate HAVING SUM(Amount) <> 0
--INSERT INTO #ErrorLogs
--	SELECT
--	DISTINCT T.LeaseIncomeParamId
--	,'Error'
--	,('No Records found')  AS Message
--	FROM #LeaseIncomeMappedWithTarget T
--	LEFT JOIN #GLJournalDetailsToCreate LI ON T.LeaseIncomeParamId = LI.LeaseIncomeParamId
--	WHERE LI.LeaseIncomeScheduleId IS NULL
--	--GROUP BY T.LeaseIncomeParamId HAVING count(LI.LeaseIncomeScheduleId) = 0
--INSERT INTO #ErrorLogs
--	SELECT
--	DISTINCT T.LeaseIncomeParamId
--	,'Error'
--	,('No Records found')  AS Message
--	FROM #LeaseBlendedIncomeMappedWithTarget T
--	LEFT JOIN #TemporaryBlendedIncomeGLJournalDetails LI ON T.LeaseIncomeParamId = LI.LeaseIncomeParamId
--	WHERE LI.BlendedIncomeScheduleId IS NULL
--	--GROUP BY T.LeaseIncomeParamId HAVING count(LI.BlendedIncomeScheduleId) = 0
--INSERT INTO #ErrorLogs
--	SELECT
--	DISTINCT T.LeaseIncomeParamId
--	,'Error'
--	,('No Records found')  AS Message
--	FROM #LeaseBlendedSetupMappedWithTarget T
--	LEFT JOIN #TemporaryBlendedSetupGLJournalDetails LI ON T.LeaseIncomeParamId = LI.LeaseIncomeParamId
--	WHERE LI.BlendedItemId IS NULL
--	--GROUP BY T.LeaseIncomeParamId HAVING count(LI.BlendedItemId) = 0
---Creation Blended Income----
MERGE INTO GLJournals
USING (SELECT
Income.*,#ErrorLogs.StagingRootEntityId
FROM
#LeaseBlendedIncomeMappedWithTarget Income
LEFT JOIN #ErrorLogs
ON (Income.LeaseIncomeParamId = #ErrorLogs.StagingRootEntityId AND #ErrorLogs.Result = 'Error'))AS GLJournalsToMigrate
ON GLJournalsToMigrate.GLJournalId = GLJournals.Id
WHEN MATCHED AND GLJournalsToMigrate.StagingRootEntityId IS NULL
THEN UPDATE SET GLJournals.UpdatedTime = @CreatedTime
WHEN NOT MATCHED AND GLJournalsToMigrate.StagingRootEntityId IS NULL
THEN
INSERT ([PostDate]
,[IsManualEntry]
,[IsReversalEntry]
,[CreatedById]
,[CreatedTime]
,[LegalEntityId])
VALUES(GLJournalsToMigrate.PostDate
,0
,0
,@UserId
,@CreatedTime
,GLJournalsToMigrate.LegalEntityId)
OUTPUT $action, Inserted.Id, GLJournalsToMigrate.BlendedIncomeScheduleId,GLJournalsToMigrate.BlendedItemId,GLJournalsToMigrate.LeaseIncomeParamId,GLJournalsToMigrate.PostDate INTO #CreatedBlendedGLJournalIds;
INSERT INTO GLJournalDetails
([EntityId]
,[EntityType]
,[Amount_Amount]
,[Amount_Currency]
,[IsDebit]
,[GLAccountNumber]
,[Description]
,[SourceId]
,[CreatedById]
,[CreatedTime]
,[GLAccountId]
,[GLTemplateDetailId]
,[MatchingGLTemplateDetailId]
,[ExportJobId]
,[GLJournalId]
,LineofBusinessId
,IsActive)
SELECT
I.EntityId
,I.EntityType
,I.Amount
,I.Currency
,I.IsDebit
,I.GLAccountNumber
,I.Description
,I.SourceId
,@UserId
,@CreatedTime
,I.GLAccountId
,I.GLTemplateDetailId
,I.MatchingGLTemplateDetailId
,NULL
,GL.Id
,I.LineofBusinessId
,1
from #TemporaryBlendedIncomeGLJournalDetails I
JOIN #CreatedBlendedGLJournalIds GL
ON GL.LeaseIncomeParamId = I.LeaseIncomeParamId AND GL.BlendedIncomeScheduleId = I.BlendedIncomeScheduleId
WHERE I.Amount <> 0
---Creation Blended Setup----
MERGE INTO GLJournals
USING (SELECT
Income.*,#ErrorLogs.StagingRootEntityId
FROM
#LeaseBlendedSetupMappedWithTarget Income
LEFT JOIN #ErrorLogs
ON (Income.LeaseIncomeParamId = #ErrorLogs.StagingRootEntityId AND #ErrorLogs.Result = 'Error'))AS GLJournalsToMigrate
ON GLJournalsToMigrate.GLJournalId = GLJournals.Id
WHEN MATCHED AND GLJournalsToMigrate.StagingRootEntityId IS NULL
THEN UPDATE SET GLJournals.UpdatedTime = @CreatedTime
WHEN NOT MATCHED AND GLJournalsToMigrate.StagingRootEntityId IS NULL
THEN
INSERT ([PostDate]
,[IsManualEntry]
,[IsReversalEntry]
,[CreatedById]
,[CreatedTime]
,[LegalEntityId])
VALUES(GLJournalsToMigrate.PostDate
,0
,0
,@UserId
,@CreatedTime
,GLJournalsToMigrate.LegalEntityId)
OUTPUT $action, Inserted.Id, GLJournalsToMigrate.BlendedItemDetailId,GLJournalsToMigrate.BlendedItemId,GLJournalsToMigrate.LeaseIncomeParamId,GLJournalsToMigrate.PostDate INTO #CreatedBlendedSetupGLJournalIds;
INSERT INTO GLJournalDetails
([EntityId]
,[EntityType]
,[Amount_Amount]
,[Amount_Currency]
,[IsDebit]
,[GLAccountNumber]
,[Description]
,[SourceId]
,[CreatedById]
,[CreatedTime]
,[GLAccountId]
,[GLTemplateDetailId]
,[MatchingGLTemplateDetailId]
,[ExportJobId]
,[GLJournalId]
,LineofBusinessId
,IsActive)
SELECT
I.EntityId
,I.EntityType
,I.Amount
,I.Currency
,I.IsDebit
,I.GLAccountNumber
,I.Description
,I.SourceId
,@UserId
,@CreatedTime
,I.GLAccountId
,I.GLTemplateDetailId
,I.MatchingGLTemplateDetailId
,NULL
,GL.Id
,I.LineofBusinessId
,1
from #TemporaryBlendedSetupGLJournalDetails I
JOIN #CreatedBlendedSetupGLJournalIds GL
ON GL.LeaseIncomeParamId = I.LeaseIncomeParamId AND GL.BlendedItemDetailId = I.BlendedItemDetailId
WHERE I.Amount <> 0
---Creation Lease Income----
MERGE INTO GLJournals
USING (SELECT
Income.*,#ErrorLogs.StagingRootEntityId
FROM
#LeaseIncomeMappedWithTarget Income
LEFT JOIN #ErrorLogs
ON (Income.LeaseIncomeParamId = #ErrorLogs.StagingRootEntityId AND #ErrorLogs.Result = 'Error'))AS GLJournalsToMigrate
ON GLJournalsToMigrate.GLJournalId = GLJournals.Id
WHEN MATCHED AND GLJournalsToMigrate.StagingRootEntityId IS NULL
THEN UPDATE SET GLJournals.UpdatedTime = @CreatedTime
WHEN NOT MATCHED AND GLJournalsToMigrate.StagingRootEntityId IS NULL
THEN
INSERT ([PostDate]
,[IsManualEntry]
,[IsReversalEntry]
,[CreatedById]
,[CreatedTime]
,[LegalEntityId])
VALUES(GLJournalsToMigrate.PostDate
,0
,0
,@UserId
,@CreatedTime
,GLJournalsToMigrate.LegalEntityId)
OUTPUT $action, Inserted.Id, GLJournalsToMigrate.LeaseIncomeScheduleId,GLJournalsToMigrate.LeaseIncomeParamId,GLJournalsToMigrate.PostDate INTO #CreatedGLJournalIds;
INSERT INTO GLJournalDetails
([EntityId]
,[EntityType]
,[Amount_Amount]
,[Amount_Currency]
,[IsDebit]
,[GLAccountNumber]
,[Description]
,[SourceId]
,[CreatedById]
,[CreatedTime]
,[GLAccountId]
,[GLTemplateDetailId]
,[MatchingGLTemplateDetailId]
,[ExportJobId]
,[GLJournalId]
,LineofBusinessId
,IsActive)
SELECT
I.EntityId
,I.EntityType
,I.Amount
,I.Currency
,I.IsDebit
,I.GLAccountNumber
,I.Description
,I.SourceId
,@UserId
,@CreatedTime
,I.GLAccountId
,I.GLTemplateDetailId
,I.MatchingGLTemplateDetailId
,NULL
,GL.Id
,I.LineofBusinessId
,1
from #GLJournalDetailsToCreate I
JOIN #CreatedGLJournalIds GL
ON GL.LeaseIncomeParamId = I.LeaseIncomeParamId AND GL.LeaseIncomeScheduleId = I.LeaseIncomeScheduleId
WHERE I.Amount <> 0
UPDATE RI SET RI.IsMigrated = 1 ,UpdatedById = @UserId , UpdatedTime = @CreatedTime
FROM stgRecognizeIncomeParam RI
JOIN #CreatedGLJournalIds GL
ON RI.Id = GL.LeaseIncomeParamId
UPDATE LIS SET
LIS.IsGLPosted = 1,
LIS.PostDate = GL.PostDate,
UpdatedById=@UserId,
UpdatedTime=@CreatedTime
From LeaseIncomeSchedules LIS
JOIN #CreatedGLJournalIds GL
ON LIS.Id = GL.LeaseIncomeScheduleId
UPDATE BIS SET
BIS.PostDate = GL.PostDate,
UpdatedById=@UserId,
UpdatedTime=@CreatedTime
From BlendedIncomeSchedules BIS
JOIN #CreatedBlendedGLJournalIds GL
ON BIS.Id = GL.BlendedIncomeScheduleId
Update BlendedItemDetails
SET
BlendedItemDetails.PostDate =  GL.PostDate,
BlendedItemDetails.IsGLPosted = 1,
UpdatedById=@UserId,
UpdatedTime=@CreatedTime
FROM BlendedItemDetails
INNER JOIN #CreatedBlendedSetupGLJournalIds GL ON BlendedItemDetails.Id = GL.BlendedItemDetailId
Update AssetValueHistories
SET
AssetValueHistories.PostDate = GL.PostDate
,AssetValueHistories.GLJournalId = GL.Id
,AssetValueHistories.NetValue_Amount =  CASE WHEN AssetValueHistories.SourceModule = 'ResidualRecapture' THEN AssetValueHistories.NetValue_Amount  ELSE AssetValueHistories.NetValue_Amount END
,AssetValueHistories.IsCleared = CASE WHEN AssetValueHistories.SourceModule = 'ResidualRecapture' THEN AssetValueHistories.IsCleared  ELSE AssetValueHistories.IsCleared END
,UpdatedById=@UserId,UpdatedTime=@CreatedTime
FROM AssetValueHistories
INNER JOIN #LeaseAssetValueHistories TVP ON AssetValueHistories.Id = TVP.assetValueHistoryID
JOIN #CreatedGLJournalIds GL ON TVP.LeaseIncomeScheduleId = GL.LeaseIncomeScheduleId
MERGE stgProcessingLog AS ProcessingLog
USING (SELECT
DISTINCT LeaseIncomeParamId
FROM
#CreatedGLJournalIds
) AS ProcessedRecognizeIncomes
ON (ProcessingLog.StagingRootEntityId=ProcessedRecognizeIncomes.LeaseIncomeParamId
AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
WHEN MATCHED THEN
UPDATE SET ProcessingLog.UpdatedTime=@CreatedTime
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
ProcessedRecognizeIncomes.LeaseIncomeParamId
,@UserId
,@CreatedTime
,@ModuleIterationStatusId
)
OUTPUT $action, Inserted.Id INTO #CreatedProcessingLogs;
INSERT INTO
stgProcessingLogDetail
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
MERGE stgProcessingLog AS ProcessingLog
USING (SELECT
DISTINCT e.StagingRootEntityId
FROM
#ErrorLogs  E
) AS ErrorRecognizeIncomes
ON (ProcessingLog.StagingRootEntityId = ErrorRecognizeIncomes.StagingRootEntityId AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
WHEN MATCHED THEN
UPDATE SET ProcessingLog.UpdatedTime=@CreatedTime
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
StagingRootEntityId
,@UserId
,@CreatedTime
,@ModuleIterationStatusId
)
OUTPUT $action, Inserted.Id ,ErrorRecognizeIncomes.StagingRootEntityId INTO #FailedProcessingLogs;
DECLARE @TotalRecordsFailed INT = (SELECT  COUNT( DISTINCT StagingRootEntityId) FROM #FailedProcessingLogs)
INSERT INTO
stgProcessingLogDetail
(
Message
,Type
,CreatedById
,CreatedTime
,ProcessingLogId
)
SELECT
#ErrorLogs.Message
,#ErrorLogs.Result
,@UserId
,@CreatedTime
,#FailedProcessingLogs.Id
FROM
#ErrorLogs
JOIN #FailedProcessingLogs
ON #ErrorLogs.StagingRootEntityId = #FailedProcessingLogs.StagingRootEntityId
SET @FailedRecords =  @FailedRecords + @TotalRecordsFailed
SET @SkipCount = @SkipCount + @TakeCount
DROP TABLE #LeaseIncomeMappedWithTarget
DROP TABLE #LeaseIncomeRecognitionSubSet
DROP TABLE #LeaseGLDetails
DROP TABLE #LeaseIncomeGLAccountDetails
DROP TABLE #LISegmentDetails
DROP TABLE #CreatedGLJournalIds
DROP TABLE #ErrorLogs
DROP TABLE #LeaseIncomeContractDetails
DROP TABLE #FailedProcessingLogs
DROP TABLE #CreatedProcessingLogs
DROP TABLE #TemporaryBlendedIncomeGLJournalDetails
DROP TABLE #TemporaryBlendedSetupGLJournalDetails
DROP TABLE #GLJournalDetailsToCreate
DROP TABLE #LeaseIncomeAmounts
DROP TABLE #LeaseFTDepAmounts
DROP TABLE #LeaseBIAmounts
DROP TABLE #LeaseBISetupAmounts
DROP TABLE #LeaseInterimInterestAmounts
DROP TABLE #LeaseInterimRentAmounts
DROP TABLE #MatchingEntryItems
DROP TABLE #LeaseAssetValueHistories
END
--DROP TABLE #OTPIncomeEntryItems
DROP TABLE #LeaseIncomeEntryItems
SET @Counter = @Counter + 1;
SET @MaxRecognizeIncomeId = 0;
END
SET @ProcessedRecords = @ProcessedRecords + @TotalRecordsCount;
END

GO

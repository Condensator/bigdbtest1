SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[MigratePostTaxToGL]
(
@UserId bigint,
@ModuleIterationStatusId bigint,
@CreatedTime datetime,
@ProcessedRecords bigint OUT,
@FailedRecords bigint OUT
)
AS
BEGIN
SET NOCOUNT ON
DECLARE @SkipCount int = 0
DECLARE @TakeCount int = 500
DECLARE @MaxPostReceivableTaxToGLParamId int = 0
SET @FailedRecords = 0
SET @ProcessedRecords = (SELECT COUNT(Id) FROM stgPostReceivableTaxToGLParam WHERE IsMigrated = 0)
SELECT
IntermediateLease.SequenceNumber,IntermediateLease.CustomerNumber,IntermediateLease.ProcessThroughDate
INTO #DuplicatePostTaxToGLDetails
FROM stgPostReceivableTaxToGLParam IntermediateLease WHERE IsMigrated = 0
GROUP BY IntermediateLease.SequenceNumber,IntermediateLease.CustomerNumber,IntermediateLease.ProcessThroughDate
HAVING COUNT (*) >1
SELECT
IntermediateLease.Id
INTO #DuplicatePostTaxToGLDetailIds
FROM stgPostReceivableTaxToGLParam IntermediateLease
JOIN #DuplicatePostTaxToGLDetails Duplicates ON IntermediateLease.SequenceNumber = Duplicates.SequenceNumber AND IntermediateLease.CustomerNumber = Duplicates.CustomerNumber AND IntermediateLease.ProcessThroughDate = Duplicates.ProcessThroughDate
WHILE @SkipCount < @ProcessedRecords
BEGIN
SET @SkipCount = @SkipCount + @TakeCount
CREATE TABLE #TaxReceivableToProcess (
ReceivableId bigint,
ReceivableTaxId bigint,
ContractId bigint,
SequenceNumber nvarchar(40),
DueDate date,
TotalAmount decimal(16, 2),
TotalBalance decimal(16, 2),
Currency nvarchar(3),
GLTemplateId bigint,
IsReadyToUse bit,
LegalEntityId bigint,
PostReceivableTaxToGLParamId bigint,
ProcessThroughDate date,
PostDate date,
GLTemplateName nvarchar(40),
Description nvarchar(200),
IsPostDateInOpenPeriod bit,
GLJournalId bigint,
GLFinancialFromDate date,
GLFinancialToDate date,
CustomerNumber nvarchar(40),
EntityId bigint,
TaxRemittancePreference nvarchar(20),
AccountingTreatment nvarchar(20),
EntityType nvarchar(2)
)
CREATE TABLE #TaxReceivableGLJournalDetails (
ReceivableId bigint,
ReceivableTaxId bigint,
ContractId bigint,
SequenceNumber nvarchar(40),
DueDate date,
TotalAmount decimal(16, 2),
TotalBalance decimal(16, 2),
Currency nvarchar(3),
GLTemplateId bigint,
IsReadyToUse bit,
LegalEntityId bigint,
PostReceivableTaxToGLParamId bigint,
ProcessThroughDate date,
PostDate date,
GLTemplateName nvarchar(40),
Description nvarchar(200),
IsPostDateInOpenPeriod bit,
GLJournalId bigint,
GLFinancialFromDate date,
GLFinancialToDate date,
CustomerNumber nvarchar(40),
EntityId bigint,
TaxRemittancePreference nvarchar(20),
AccountingTreatment nvarchar(20),
EntityType nvarchar(2),
GLTemplateDetailId bigint,
IsDebit bit,
Amount decimal(16, 2),
GLAccountNumber nvarchar(50),
GLAccountId bigint,
--ReceivableTaxDetailId BIGINT,
--ReceivableTaxImpositionId BIGINT,
-- TaxImpositionTypeDetailId BIGINT,
LineOfBusinessId bigint,
)
CREATE TABLE #ReceivableTaxAmountDetails
(
ReceivableTaxId BIGINT,
--TaxImpositionTypeDetailId BIGINT,
GLTemplateId BIGINT,
Amount DECIMAL(16,2),
Balance DECIMAL(16,2),
RemainingAmount DECIMAL(16,2),
LegalEntityid BigInt,
ContractId BigInt
)
CREATE TABLE #CreatedGLJournals (
MergeAction NVARCHAR(20),
GLJournalId BIGINT,
ReceivableTaxId BIGINT,
-- TaxImpositionTypeDetailId BIGINT,
ReceivableTaxGLId BIGINT,
PostDate DATE,
PostReceivableTaxToGLParamId BIGINT
)
CREATE TABLE #CreatedReceivableTaxGLDetails (
MergeAction NVARCHAR(20),
ReceivableTaxGLId BIGINT,
ReceivableTaxId BIGINT,
--TaxImpositionTypeDetailId BIGINT
)
CREATE TABLE #NonSyndicatedGLEntryItems (
EntryItem nvarchar(100) NOT NULL,
IsDebit bit NOT NULL,
AccountingTreatment nvarchar(50)
)
CREATE TABLE #ErrorLogs (
Id bigint NOT NULL IDENTITY PRIMARY KEY,
StagingRootEntityId bigint,
Result nvarchar(20),
Message nvarchar(max)
)
CREATE TABLE #CreatedProcessingLogs (
MergeAction nvarchar(20),
InsertedId bigint,
LeaseSequenceNumber nvarchar(40),
ProcessThroughDate datetime
)
CREATE TABLE #FailedProcessingLogs (
MergeAction nvarchar(20),
InsertedId bigint,
StagingRootEntityId bigint
)
INSERT INTO #NonSyndicatedGLEntryItems (EntryItem,IsDebit,AccountingTreatment)
VALUES ('SalesTaxReceivable', 1,'Both')
INSERT INTO #NonSyndicatedGLEntryItems (EntryItem, IsDebit,AccountingTreatment)
VALUES ('UncollectedSalesTaxAR', 0,'CashBased')
INSERT INTO #NonSyndicatedGLEntryItems (EntryItem, IsDebit,AccountingTreatment)
VALUES ('SalesTaxPayable', 0 ,'AccrualBased')
INSERT INTO #NonSyndicatedGLEntryItems (EntryItem, IsDebit,AccountingTreatment)
VALUES ('PrePaidSalesTaxReceivable', 1,'Both')
SELECT TOP (@TakeCount)
* INTO #PostReceivableTaxToGLParamSubset
FROM stgPostReceivableTaxToGLParam PostReceivableTaxToGLParam
WHERE PostReceivableTaxToGLParam.Id > @MaxPostReceivableTaxToGLParamId AND PostReceivableTaxToGLParam.IsMigrated = 0
ORDER BY PostReceivableTaxToGLParam.Id
INSERT INTO #TaxReceivableToProcess
(ReceivableId,
ReceivableTaxId,
ContractId,
SequenceNumber,
DueDate,
TotalAmount,
TotalBalance,
Currency,
GLTemplateId,
IsReadyToUse,
LegalEntityId,
PostReceivableTaxToGLParamId,
ProcessThroughDate,
PostDate,
GLTemplateName,
Description,
IsPostDateInOpenPeriod,
GLJournalId,
GLFinancialFromDate,
GLFinancialToDate,
CustomerNumber,
EntityId,
TaxRemittancePreference ,
AccountingTreatment,
EntityType)
SELECT
r.Id,
rt2.Id,
c.Id,
pttgs.SequenceNumber,
r.DueDate,
rt2.Amount_Amount,
rt2.Balance_Amount,
rt2.Amount_Currency,
g.Id,
g.IsReadyToUse,
le.Id,
pttgs.Id,
pttgs.ProcessThroughDate,
pttgs.PostDate,
g.Name AS GLTemplateName,
'Due Date : ' + CONVERT(varchar(10), r.DueDate, 110),
CASE
WHEN
pttgs.PostDate < gop.FromDate OR
pttgs.PostDate > gop.ToDate THEN CONVERT(bit, 0)
ELSE CONVERT(bit, 1)
END 'IsPostDateInOpenPeriod',
NULL,
gop.FromDate,
gop.ToDate,
pttgs.CustomerNumber,
r.EntityId,
Case When r.EntityType='CT' Then c.SalesTaxRemittanceMethod
else LE.TaxRemittancePreference
end TaxRemittancePreference,
rc.AccountingTreatment,
r.EntityType
FROM #PostReceivableTaxToGLParamSubset pttgs
LEFT JOIN dbo.Contracts c ON UPPER(pttgs.SequenceNumber) = UPPER(c.SequenceNumber)
LEFT JOIN dbo.LeaseFinances lf ON lf.ContractId = c.Id AND lf.IsCurrent = 1
LEFT JOIN dbo.Parties P ON pttgs.CustomerNumber = P.PartyNumber
JOIN dbo.Receivables r ON (c.Id = r.EntityId AND r.EntityType = 'CT') OR (P.Id = r.EntityId and r.EntityType = 'CU')
JOIN dbo.ReceivableCodes rc ON rc.Id = r.ReceivableCodeId
JOIN dbo.ReceivableTypes rt ON rt.Id = rc.ReceivableTypeId
JOIN dbo.ReceivableTaxes rt2 ON r.Id = rt2.ReceivableId AND rt2.IsActive = 1
JOIN dbo.ReceivableTaxDetails rtd on rtd.ReceivableTaxId = rt2.Id
JOIN dbo.GLTemplates g ON rt2.GLTemplateId = g.Id
LEFT JOIN dbo.LegalEntities le ON r.LegalEntityId = le.Id
LEFT JOIN dbo.GLFinancialOpenPeriods gop ON gop.LegalEntityId = le.Id AND gop.IsCurrent = 1
WHERE (rt2.IsActive = 1 AND rt2.IsGLPosted = 0 AND rtd.IsGLPosted = 0)
AND (c.Id IS NULL OR (c.ChargeOffStatus <> 'ChargedOff' AND lf.BookingStatus <> 'Inactive'))
AND (lf.Id IS NULL OR (lf.BookingStatus = 'Commenced' OR lf.BookingStatus = 'FullyPaidOff' OR lf.BookingStatus = 'Pending') )
AND r.DueDate <= pttgs.ProcessThroughDate
SELECT
@MaxPostReceivableTaxToGLParamId = MAX(trtp.PostReceivableTaxToGLParamId)
FROM #TaxReceivableToProcess trtp;
INSERT INTO #ErrorLogs
SELECT DISTINCT
trtp.PostReceivableTaxToGLParamId,
'Error',
('No <Lease> found with filter <SequenceNumber=' + SequenceNumber + '> while executing EditReference<Lease>') AS Message
FROM #TaxReceivableToProcess trtp
WHERE trtp.SequenceNumber IS NOT NULL AND trtp.ContractId IS NULL
INSERT INTO #ErrorLogs
SELECT DISTINCT
trtp.PostReceivableTaxToGLParamId,
'Information',
'No tax receivables were found before the process through date =' + CONVERT(varchar(10), trtp.ProcessThroughDate, 110) + ' for Lease = ' + trtp.SequenceNumber AS Message
FROM #TaxReceivableToProcess trtp
WHERE trtp.ContractId IS NOT NULL AND trtp.ReceivableTaxId IS NULL
DELETE FROM #TaxReceivableToProcess WHERE (SequenceNumber IS NOT NULL AND ContractId IS NULL) OR (ContractId IS NOT NULL AND ReceivableTaxId IS NULL)
INSERT INTO #ErrorLogs
SELECT DISTINCT
trtp.PostReceivableTaxToGLParamId,
'Error',
'GL Template { ' + trtp.GLTemplateName + ' } is not ready to Use' AS Message
FROM #TaxReceivableToProcess trtp
WHERE trtp.IsReadyToUse IS NOT NULL AND trtp.IsReadyToUse = 0
INSERT INTO #ErrorLogs
SELECT DISTINCT
trtp.PostReceivableTaxToGLParamId,
'Error',
'Post Date is not within the financial open period : ' + CONVERT(varchar(10), trtp.GLFinancialFromDate, 110) + ' and ' + CONVERT(varchar(10), trtp.GLFinancialToDate, 110) AS Message
FROM #TaxReceivableToProcess trtp
WHERE trtp.LegalEntityId IS NOT NULL AND trtp.IsPostDateInOpenPeriod = 0
INSERT INTO #ErrorLogs
SELECT
trtp.PostReceivableTaxToGLParamId,
'Error',
('Duplicates Found for the Combination of Lease = '+ trtp.SequenceNumber +' Customer = ' + trtp.CustomerNumber + ' and process through date =' + CONVERT(varchar(10), trtp.ProcessThroughDate, 110)) AS Message
FROM #TaxReceivableToProcess trtp
WHERE trtp.PostReceivableTaxToGLParamId IN (SELECT Id FROM #DuplicatePostTaxToGLDetailIds)
DELETE FROM #TaxReceivableToProcess WHERE (IsReadyToUse IS NOT NULL AND IsReadyToUse = 0) OR (LegalEntityId IS NOT NULL AND IsPostDateInOpenPeriod = 0)
DELETE FROM #TaxReceivableToProcess WHERE PostReceivableTaxToGLParamId in(SELECT Id FROM #DuplicatePostTaxToGLDetailIds)
INSERT INTO #ReceivableTaxAmountDetails
(
ReceivableTaxId,
GLTemplateId,
Amount,
Balance,
RemainingAmount,
LegalEntityid,
ContractId
)
SELECT trtp.ReceivableTaxId
,trtp.GLTemplateId
,SUM(rti.Amount_Amount) AS Amount
,SUM(rti.Balance_Amount) AS Balance
,SUM(rti.Amount_Amount - rti.Balance_Amount) AS RemainingAmount
,trtp.LegalEntityId
,trtp.ContractId
FROM #TaxReceivableToProcess trtp
JOIN dbo.ReceivableTaxDetails rtd ON trtp.ReceivableTaxId = rtd.ReceivableTaxId AND rtd.IsActive = 1
JOIN dbo.ReceivableTaxImpositions rti ON rti.ReceivableTaxDetailId = rtd.Id
GROUP BY trtp.ReceivableTaxId,trtp.GLTemplateId,trtp.LegalEntityId,trtp.ContractId
--SELECT TI.Name, TI.TaxJurisdictionLevel, TID.SegmentNumber, S.ShortName
--INTO #TaxImpositionDetails
--FROM TaxImpositionTypes TI
----JOIN TaxImpositionTypeDetails TID on TI.Id = TID.TaxImpositionTypeId
--JOIN States S on TID.StateId = S.Id
----WHERE TID.IsActive = 1
SELECT DISTINCT
gd.GLTemplateId,
gd.Id 'GLTemplateDetailId',
gd.GLAccountId,
-- rtad.TaxImpositionTypeDetailId,
gad.SegmentValue,
gad.IsDynamic,
rtad.LegalEntityid,
rtad.ContractId
INTO #GLTemplateAccountDetails
FROM #ReceivableTaxAmountDetails rtad
JOIN dbo.GLTemplateDetails gd ON rtad.GLTemplateId = gd.GLTemplateId AND gd.IsActive = 1
JOIN GLAccountDetails gad ON gd.GLAccountId = gad.GLAccountId
JOIN dbo.GLEntryItems gi ON gd.EntryItemId = gi.Id AND gi.IsActive = 1
JOIN #NonSyndicatedGLEntryItems ogi ON gi.Name = ogi.EntryItem
--JOIN dbo.TaxImpositionTypeDetails titd ON rtad.TaxImpositionTypeDetailId = titd.Id
SELECT DISTINCT
gad.GLAccountId,
gad.SegmentValue AS SegmentNumber,
gad.IsDynamic
INTO #SegmentDetails
FROM #GLTemplateAccountDetails gad;
--JOIN #TaxImpositionDetails TI ON gad.TaxImpositionTypeDetailId = TI.TaxImpositionTypeDetailId;
WITH CTE_GLAccountNumberDetails
AS (SELECT
GLAccountId,
STUFF((SELECT '-' + CAST(SegmentNumber AS varchar(10)) [text()]
FROM #SegmentDetails
WHERE GLAccountId = t.GLAccountId
FOR xml PATH (''), TYPE)
.value('.', 'NVARCHAR(MAX)'), 1, 1, ' ') GLAccountNumber
FROM #SegmentDetails t
GROUP BY GLAccountId)
SELECT DISTINCT
gad.GLTemplateId,
gad.GLTemplateDetailId,
gad.GLAccountId,
gad.IsDynamic,
Concat(LE.LegalEntityNumber,'-',CCC.CostCenter,'-',LTRIM(cgnd.GLAccountNumber)) GLAccountNumber INTO #GLAccountDetails
FROM #GLTemplateAccountDetails gad
LEFT JOIN LegalEntities LE on gad.LegalEntityId=LE.Id
LEFT JOIN Contracts C on gad.ContractId=C.Id
JOIN CostCenterConfigs CCC on C.CostCenterId=CCC.Id
JOIN CTE_GLAccountNumberDetails cgnd ON gad.GLAccountId = cgnd.GLAccountId
INSERT INTO #TaxReceivableGLJournalDetails
(ReceivableId,
ReceivableTaxId,
ContractId,
SequenceNumber,
DueDate,
TotalAmount,
TotalBalance,
Currency,
GLTemplateId,
IsReadyToUse,
LegalEntityId,
PostReceivableTaxToGLParamId,
ProcessThroughDate,
PostDate,
GLTemplateName,
Description,
IsPostDateInOpenPeriod,
GLJournalId,
GLFinancialFromDate,
GLFinancialToDate,
CustomerNumber,
EntityId,
TaxRemittancePreference ,
AccountingTreatment,
EntityType,
GLTemplateDetailId,
IsDebit,
Amount,
GLAccountNumber,
GLAccountId,
--ReceivableTaxDetailId,
--ReceivableTaxImpositionId,
--TaxImpositionTypeDetailId,
LineofBusinessId)
SELECT
trtp.*,
gd.Id AS GLTemplateDetailId,
--NULL AS MatchingGLTemplateDetailId,
ogi.IsDebit,
CASE
WHEN gi.Name = 'SalesTaxReceivable' THEN rtad.Balance
WHEN gi.Name = 'PrePaidSalesTaxReceivable' THEN rtad.RemainingAmount
WHEN gi.Name = 'SalesTaxPayable' THEN rtad.Amount
ELSE rtad.Amount
END AS Amount,
--CASE WHEN gd2.IsDynamic = 1 THEN TI.SegmentNumber ELSE
gd2.GLAccountNumber,
gd2.GLAccountId,
--rtd.Id,
--rti.Id,
--rtad.TaxImpositionTypeDetailId,
Case When trtp.EntityType = 'CT' then lf.LineofBusinessId
When trtp.EntityType = 'CU' and R.SourceTable = 'Sundry' then S.LineofBusinessId
When trtp.EntityType = 'CU' and R.SourceTable = 'SundryRecurring' then SR.LineofBusinessId
End
FROM #TaxReceivableToProcess trtp
LEFT JOIN dbo.LeaseFinances lf ON lf.ContractId = trtp.ContractId AND lf.IsCurrent = 1
LEFT JOIN dbo.Receivables R on trtp.Receivableid = R.Id
LEFT JOIN dbo.Sundries S ON S.Id = R.SourceId and R.SourceTable = 'Sundry'
LEFT JOIN dbo.SundryRecurringPaymentSchedules SRPS on SRPS.Id = r.SourceId and r.SourceTable = 'SundryRecurring'
LEFT JOIN dbo.SundryRecurrings SR on SRPS.SundryRecurringId=SR.Id
JOIN #ReceivableTaxAmountDetails rtad ON trtp.ReceivableTaxId = rtad.ReceivableTaxId
JOIN dbo.GLTemplateDetails gd ON trtp.GLTemplateId = gd.GLTemplateId AND gd.IsActive = 1
JOIN #GLAccountDetails gd2 ON gd.Id = gd2.GLTemplateDetailId
JOIN dbo.GLEntryItems gi ON gi.Id = gd.EntryItemId AND gi.IsActive = 1
JOIN #NonSyndicatedGLEntryItems ogi ON gi.Name = ogi.EntryItem
and (ogi.AccountingTreatment = 'Both' or
(ogi.AccountingTreatment = 'AccrualBased' and ogi.AccountingTreatment = trtp.AccountingTreatment and ogi.AccountingTreatment = trtp.TaxRemittancePreference) or
(ogi.AccountingTreatment = 'CashBased')
)
DELETE FROM #TaxReceivableGLJournalDetails WHERE #TaxReceivableGLJournalDetails.Amount <= 0.0
MERGE INTO GLJournals
USING (SELECT
trtp.*
FROM #TaxReceivableToProcess trtp
JOIN #ReceivableTaxAmountDetails rtad ON trtp.ReceivableTaxId = rtad.ReceivableTaxId) AS receivablesToPostTaxGL
ON receivablesToPostTaxGL.GLJournalId = GLJournals.Id
WHEN MATCHED
THEN UPDATE SET UpdatedTime = @CreatedTime
WHEN NOT MATCHED
THEN
INSERT
(PostDate
,IsManualEntry
,IsReversalEntry
,CreatedById
,CreatedTime
,LegalEntityId
)
VALUES
(receivablesToPostTaxGL.PostDate,
0,
0,
@UserId,
@CreatedTime,
receivablesToPostTaxGL.LegalEntityId
)
OUTPUT $ACTION, INSERTED.Id, receivablesToPostTaxGL.ReceivableTaxId, NULL, receivablesToPostTaxGL.PostDate, receivablesToPostTaxGL.PostReceivableTaxToGLParamId INTO #CreatedGLJournals;
INSERT INTO GLJournalDetails
(EntityId,
EntityType,
Amount_Amount,
Amount_Currency,
IsDebit,
GLAccountNumber,
Description,
SourceId,
CreatedById,
CreatedTime,
GLAccountId,
GLTemplateDetailId,
MatchingGLTemplateDetailId,
GLJournalId,
LineofBusinessId,
IsActive)
SELECT distinct
trgd.EntityId,
Case When trgd.EntityType='CT' then 'Contract'
else 'Customer'
end,
trgd.Amount,
trgd.Currency,
trgd.IsDebit,
trgd.GLAccountNumber,
trgd.Description,
trgd.ReceivableTaxId,
@UserId,
@CreatedTime,
trgd.GLAccountId,
trgd.GLTemplateDetailId,
NULL,
cgi.GLJournalId,
trgd.LineofBusinessId,
1
FROM #TaxReceivableGLJournalDetails trgd
LEFT JOIN #CreatedGLJournals cgi ON trgd.ReceivableTaxId = cgi.ReceivableTaxId --AND trgd.TaxImpositionTypeDetailId = cgi.TaxImpositionTypeDetailId
MERGE INTO ReceivableTaxGLs
USING (SELECT
cgi.*
FROM #CreatedGLJournals cgi) AS createdReceivableTaxGLs
ON createdReceivableTaxGLs.ReceivableTaxGLId = ReceivableTaxGLs.Id
WHEN MATCHED
THEN UPDATE SET UpdatedTime = @CreatedTime
WHEN NOT MATCHED
THEN
INSERT
(PostDate,
IsReversal,
CreatedById,
CreatedTime,
GLJournalId,
ReceivableTaxId)
VALUES
(createdReceivableTaxGLs.PostDate,
0,
@UserId,
@CreatedTime,
createdReceivableTaxGLs.GLJournalId,
createdReceivableTaxGLs.ReceivableTaxId)
OUTPUT $ACTION, INSERTED.Id, createdReceivableTaxGLs.ReceivableTaxId INTO #CreatedReceivableTaxGLDetails;
UPDATE rt
SET rt.IsGLPosted = 1,
rt.UpdatedTime = @CreatedTime,
rt.UpdatedById = @UserId
FROM dbo.ReceivableTaxes rt
JOIN #CreatedGLJournals cgi ON rt.Id = cgi.ReceivableTaxId
UPDATE rt
SET rt.IsGLPosted = 1,
rt.UpdatedTime = @CreatedTime,
rt.UpdatedById = @UserId
FROM dbo.ReceivableTaxDetails rt
JOIN #CreatedGLJournals cgi ON rt.ReceivableTaxId = cgi.ReceivableTaxId
UPDATE pttg
SET pttg.IsMigrated = 1,
pttg.UpdatedTime = @CreatedTime,
pttg.UpdatedById = @UserId
FROM stgPostReceivableTaxToGLParam pttg
JOIN #CreatedGLJournals cgi ON pttg.Id = cgi.PostReceivableTaxToGLParamId
MERGE stgProcessingLog AS ProcessingLog
USING (SELECT DISTINCT
trtp.PostReceivableTaxToGLParamId,
trtp.SequenceNumber,
trtp.ProcessThroughDate
FROM #TaxReceivableToProcess trtp) AS ProcessedTaxReceivables
ON (ProcessingLog.StagingRootEntityId = ProcessedTaxReceivables.PostReceivableTaxToGLParamId  AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
WHEN MATCHED THEN
UPDATE SET UpdatedTime = @CreatedTime
WHEN NOT MATCHED THEN
INSERT
(StagingRootEntityId
,CreatedById
,CreatedTime
,ModuleIterationStatusId)
VALUES
(ProcessedTaxReceivables.PostReceivableTaxToGLParamId
,@UserId
,@CreatedTime
,@ModuleIterationStatusId)
OUTPUT $ACTION, INSERTED.Id, ProcessedTaxReceivables.SequenceNumber, ProcessedTaxReceivables.ProcessThroughDate INTO #CreatedProcessingLogs;
INSERT INTO stgProcessingLogDetail
(Message
,Type
,CreatedById
,CreatedTime
,ProcessingLogId)
SELECT
'Tax Receivables of Lease =' + #CreatedProcessingLogs.LeaseSequenceNumber + ' have been successfully GL posted till ' + CONVERT(varchar(10), #CreatedProcessingLogs.ProcessThroughDate, 110) + '.',
'Information',
@UserId,
@CreatedTime,
#CreatedProcessingLogs.InsertedId
FROM #CreatedProcessingLogs
MERGE stgProcessingLog AS ProcessingLog
USING (SELECT
DISTINCT
StagingRootEntityId
FROM #ErrorLogs) AS ErrorReceivables
ON (ProcessingLog.StagingRootEntityId = ErrorReceivables.StagingRootEntityId AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
WHEN MATCHED THEN
UPDATE SET UpdatedTime = @CreatedTime
WHEN NOT MATCHED THEN
INSERT
(StagingRootEntityId
,CreatedById
,CreatedTime
,ModuleIterationStatusId)
VALUES
(ErrorReceivables.StagingRootEntityId
,@UserId
,@CreatedTime
,@ModuleIterationStatusId)
OUTPUT $ACTION, INSERTED.Id, ErrorReceivables.StagingRootEntityId INTO #FailedProcessingLogs;
INSERT INTO stgProcessingLogDetail
(Message
,Type
,CreatedById
,CreatedTime
,ProcessingLogId)
SELECT
#ErrorLogs.Message,
#ErrorLogs.Result,
@UserId,
@CreatedTime,
#FailedProcessingLogs.InsertedId
FROM #ErrorLogs
INNER JOIN #FailedProcessingLogs ON #ErrorLogs.StagingRootEntityId = #FailedProcessingLogs.StagingRootEntityId
DECLARE @TotalRecordsFailed int = (SELECT
COUNT(DISTINCT InsertedId)
FROM #FailedProcessingLogs
WHERE #FailedProcessingLogs.StagingRootEntityId NOT IN (SELECT trtp.PostReceivableTaxToGLParamId FROM #TaxReceivableToProcess trtp))
SET @FailedRecords = @FailedRecords + @TotalRecordsFailed;
DROP TABLE #CreatedGLJournals
DROP TABLE #CreatedProcessingLogs
DROP TABLE #CreatedReceivableTaxGLDetails
DROP TABLE #ErrorLogs
DROP TABLE #FailedProcessingLogs
DROP TABLE #GLAccountDetails
DROP TABLE #GLTemplateAccountDetails
DROP TABLE #NonSyndicatedGLEntryItems
DROP TABLE #PostReceivableTaxToGLParamSubset
DROP TABLE #ReceivableTaxAmountDetails
DROP TABLE #SegmentDetails
DROP TABLE #TaxReceivableGLJournalDetails
DROP TABLE #TaxReceivableToProcess
--DROP TABLE #TaxImpositionDetails
END
DROP TABLE #DuplicatePostTaxToGLDetails
DROP TABLE #DuplicatePostTaxToGLDetailIds
END

GO

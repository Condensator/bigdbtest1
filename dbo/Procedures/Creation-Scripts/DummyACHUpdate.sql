SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DummyACHUpdate]
(@UserId                 BIGINT,
@ModuleIterationStatusId BIGINT,
@CreatedTime             DATETIMEOFFSET,
@ProcessedRecords        BIGINT OUTPUT,
@FailedRecords           BIGINT OUTPUT
)
AS
BEGIN

SET XACT_ABORT ON
SET NOCOUNT ON
SET ANSI_WARNINGS ON

SELECT @ProcessedRecords= COUNT(Id)
FROM stgACHScheduleUpdate
WHERE IsMigrated = 0

IF OBJECT_ID('tempdb..#ErrorLogs') IS NOT NULL
    DROP TABLE #ErrorLogs;

IF OBJECT_ID('tempdb..#UpdatedACHSchedule') IS NOT NULL
	DROP TABLE #UpdatedACHSchedule;

IF OBJECT_ID('tempdb..#UpdatedACHScheduleContractID') IS NOT NULL
	DROP TABLE #UpdatedACHScheduleContractID;

IF OBJECT_ID('tempdb..#CreatedProcessingLogs') IS NOT NULL
	DROP TABLE #CreatedProcessingLogs;

IF OBJECT_ID('tempdb..#FailedProcessingLogs') IS NOT NULL
	DROP TABLE #FailedProcessingLogs;

CREATE TABLE #ErrorLogs
(
[Id] BIGINT NOT NULL IDENTITY PRIMARY KEY,
[StagingRootEntityId] BIGINT,
[Result] NVARCHAR(10),
[Message] NVARCHAR(MAX)
);

CREATE TABLE #UpdatedACHSchedule
(
[StagingRootEntityId] BIGINT NOT NULL , 
[EntityKey] BIGINT NOT NULL, 
[EntityNaturalId] NVARCHAR(MAX) NOT NULL
);

CREATE TABLE #UpdatedACHScheduleContractID
(
[StagingRootEntityId] BIGINT NOT NULL , 
[EntityKey] BIGINT NOT NULL, 
[EntityNaturalId] NVARCHAR(MAX) NOT NULL,
[Type] NVARCHAR(11),
[Message] NVARCHAR(MAX)
);

CREATE TABLE #CreatedProcessingLogs
([ProcessingLogId] BIGINT NOT NULL , 
[StagingRootEntityId] BIGINT NOT NULL
);

CREATE TABLE #FailedProcessingLogs
([ProcessingLogId]          BIGINT NOT NULL,
[StagingRootEntityId] BIGINT NOT NULL
);

INSERT INTO #ErrorLogs
SELECT ACHU.Id
, 'Error'
, ('Invalid Contract Sequence Number {' + ACHU.SequenceNumber + '} for ACHScheduleUpdate Id {' + CONVERT(NVARCHAR(MAX), ACHU.Id) + '}')
FROM stgACHScheduleUpdate ACHU
LEFT JOIN Contracts C ON ACHU.SequenceNumber = C.SequenceNumber
WHERE ACHU.IsMigrated = 0
AND C.Id IS NULL;

UPDATE [ACHSchedules]
SET [Status] = 'Completed'
OUTPUT ACHU.Id,C.Id,C.SequenceNumber into #UpdatedACHSchedule
FROM stgACHScheduleUpdate ACHU
JOIN Contracts C ON ACHU.SequenceNumber = C.SequenceNumber
JOIN ACHSchedules ACHS ON ACHS.ContractBillingId = C.ID  
WHERE ACHU.IsMigrated = 0 AND ACHS.SettlementDate<= ACHU.ACHRuntilldate
AND ACHU.Id NOT IN
(
SELECT StagingRootEntityId
FROM #ErrorLogs
) 

INSERT INTO #UpdatedACHScheduleContractID ([StagingRootEntityId], [EntityKey], [EntityNaturalId],[Type],[Message])
SELECT DISTINCT StagingRootEntityId, EntityKey, EntityNaturalId ,'Information','Successful'
FROM  #UpdatedACHSchedule

INSERT INTO #UpdatedACHScheduleContractID ([StagingRootEntityId], [EntityKey], [EntityNaturalId],[Type],[Message])
SELECT ACHU.Id
,C.ID
,C.SequenceNumber
,'Warning'
,('No ACH Schedule found for Sequence Number {' + ACHU.SequenceNumber + '} with ACHScheduleUpdate Id {' + CONVERT(NVARCHAR(MAX), ACHU.Id) + '}')
FROM stgACHScheduleUpdate ACHU
JOIN Contracts C ON ACHU.SequenceNumber = C.SequenceNumber
WHERE ACHU.IsMigrated = 0
AND ACHU.Id NOT IN
(
SELECT StagingRootEntityId FROM #ErrorLogs
UNION
SELECT StagingRootEntityId FROM #UpdatedACHScheduleContractID
)

Update stgACHScheduleUpdate
Set [IsMigrated] = 1
,UpdatedById = @UserId
,UpdatedTime = CURRENT_TIMESTAMP
FROM stgACHScheduleUpdate 
WHERE IsMigrated = 0
AND Id NOT IN
(
SELECT StagingRootEntityId FROM #ErrorLogs
)

MERGE stgProcessingLog AS ProcessingLog
USING
(
SELECT StagingRootEntityId
FROM #UpdatedACHScheduleContractID
) AS ProcessedACHScheduleUpdate
ON(ProcessingLog.StagingRootEntityId = ProcessedACHScheduleUpdate.StagingRootEntityId
AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
WHEN MATCHED
THEN UPDATE SET
UpdatedTime = @CreatedTime
WHEN NOT MATCHED
THEN
INSERT(StagingRootEntityId
, CreatedById
, CreatedTime
, ModuleIterationStatusId)
VALUES
(ProcessedACHScheduleUpdate.StagingRootEntityId
, @UserId
, @CreatedTime
, @ModuleIterationStatusId
)
OUTPUT Inserted.Id ,Inserted.StagingRootEntityId
INTO #CreatedProcessingLogs;

INSERT INTO stgProcessingLogDetail
(Message
, Type
, EntityName
, CreatedById
, CreatedTime
, ProcessingLogId
, EntityKey
, EntityNaturalId
)
SELECT #UpdatedACHScheduleContractID.[Message]
, #UpdatedACHScheduleContractID.[Type]
, 'Contract'
, @UserId
, @CreatedTime
, #CreatedProcessingLogs.ProcessingLogId
, #UpdatedACHScheduleContractID.EntityKey
, #UpdatedACHScheduleContractID.EntityNaturalId
FROM #CreatedProcessingLogs
JOIN #UpdatedACHScheduleContractID ON #UpdatedACHScheduleContractID.StagingRootEntityId = #CreatedProcessingLogs.StagingRootEntityId;

MERGE stgProcessingLog AS ProcessingLog
USING
(
SELECT  
StagingRootEntityId
FROM #ErrorLogs
) AS ErrorACHScheduleUpdate
ON(ProcessingLog.StagingRootEntityId = ErrorACHScheduleUpdate.StagingRootEntityId
AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
WHEN MATCHED
THEN UPDATE SET
UpdatedTime = @CreatedTime
, UpdatedById = @UserId
WHEN NOT MATCHED
THEN
INSERT(StagingRootEntityId
, CreatedById
, CreatedTime
, ModuleIterationStatusId)
VALUES
(ErrorACHScheduleUpdate.StagingRootEntityId
, @UserId
, @CreatedTime
, @ModuleIterationStatusId
)
OUTPUT Inserted.Id
, Inserted.StagingRootEntityId
INTO #FailedProcessingLogs;

INSERT INTO stgProcessingLogDetail
(Message
, Type
, EntityName
, CreatedById
, CreatedTime
, ProcessingLogId
)
SELECT #ErrorLogs.Message
, #ErrorLogs.Result
, 'Contract'
, @UserId
, @CreatedTime
, #FailedProcessingLogs.ProcessingLogId
FROM #ErrorLogs
JOIN #FailedProcessingLogs ON #ErrorLogs.StagingRootEntityId = #FailedProcessingLogs.StagingRootEntityId;

SELECT @FailedRecords= COUNT(DISTINCT StagingRootEntityId)
FROM #ErrorLogs

DROP TABLE #ErrorLogs;
DROP TABLE #UpdatedACHSchedule;
DROP TABLE #UpdatedACHScheduleContractID;
DROP TABLE #CreatedProcessingLogs;
DROP TABLE #FailedProcessingLogs; 

SET NOCOUNT OFF
SET XACT_ABORT OFF
SET ANSI_WARNINGS OFF

END;

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ValidateMasterAgreements]
(@UserId                  BIGINT,
@ModuleIterationStatusId BIGINT,
@CreatedTime             DATETIMEOFFSET,
@ProcessedRecords        BIGINT OUTPUT,
@FailedRecords           BIGINT OUTPUT
)
AS
BEGIN
CREATE TABLE #ErrorLogs
(Id                  BIGINT NOT NULL IDENTITY PRIMARY KEY,
StagingRootEntityId BIGINT,
Result              NVARCHAR(10),
Message             NVARCHAR(MAX)
);
CREATE TABLE #FailedProcessingLogs
(Id                 BIGINT NOT NULL,
MasterAgreementId BIGINT NOT NULL
);
CREATE TABLE #CreatedProcessingLogs([Id] BIGINT NOT NULL);
SET @ProcessedRecords =
(
SELECT ISNULL(COUNT(Id), 0)
FROM stgMasterAgreement
WHERE IsMigrated = 0
);
INSERT INTO #ErrorLogs
SELECT MA.Id
, 'Error'
, ('Line of Business is invalid for Master Agreement :' + ISNULL(MA.Number, '')) AS Message
FROM stgMasterAgreement MA
LEFT JOIN dbo.LineofBusinesses lb ON MA.LineOfBusinessName = lb.Name
AND lb.IsActive = 1
WHERE LineOfBusinessName IS NOT NULL
AND MA.IsMigrated = 0
AND lb.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT MA.Id
, 'Error'
, ('Legal Entity is invalid for Master Agreement :' + ISNULL(MA.Number, '')) AS Message
FROM stgMasterAgreement MA
LEFT JOIN dbo.LegalEntities le ON le.LegalEntityNumber = MA.LegalEntityNumber
WHERE le.Id IS NULL
AND MA.LegalEntityNumber IS NOT NULL
AND MA.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT MA.Id
, 'Error'
, ('Agreement Type Name is invalid for Master Agreement :' + ISNULL(MA.Number, '')) AS Message
FROM stgMasterAgreement MA
LEFT JOIN AgreementTypeConfigs ON REPLACE(LTRIM(RTRIM(MA.AgreementTypeName)), ' ', '')=REPLACE(LTRIM(RTRIM(AgreementTypeConfigs.Name)), ' ', '')
AND AgreementTypeConfigs.IsActive = 1
WHERE AgreementTypeConfigs.Id IS NULL
AND MA.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT DISTINCT
MA.Id
, 'Error'
, ('Line of Business and Legal entity combination is invalid for Master Agreement :' + ISNULL(MA.Number, '')) AS Message
FROM stgMasterAgreement MA
LEFT JOIN LegalEntities LE ON MA.LegalEntityNumber = LE.LegalEntityNumber
AND MA.IsMigrated = 0
LEFT JOIN dbo.LineofBusinesses lb ON lb.Name = MA.LineOfBusinessName
JOIN GLOrgStructureConfigs GSC ON LE.Id = GSC.LegalEntityId
AND lb.Id = GSC.LineofbusinessId
AND GSC.ISActive = 1
GROUP BY LE.Id
, MA.LineOfBusinessName
, MA.Id
, MA.Number
HAVING COUNT(*) = 0;
INSERT INTO #ErrorLogs
SELECT DISTINCT
MA.Id
, 'Error'
, ('The entered value for the field Agreement #:' + ISNULL(MA.Number, '') + ' already exists in Master Agreement. Please enter a unique value.') AS Message
FROM MasterAgreements
INNER JOIN stgMasterAgreement MA ON MasterAgreements.Number = MA.Number
WHERE MA.IsMigrated = 0;
SET @FailedRecords =
(
SELECT ISNULL(COUNT(DISTINCT StagingRootEntityId), 0)
FROM #ErrorLogs
);
MERGE stgProcessingLog AS ProcessingLog
USING
(
SELECT Id
FROM StgMasterAgreement
WHERE IsMigrated = 0
AND Id NOT IN
(
SELECT StagingRootEntityId
FROM #ErrorLogs
)
) AS ProcessedMasterAgreements
ON(ProcessingLog.StagingRootEntityId = ProcessedMasterAgreements.Id
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
(ProcessedMasterAgreements.Id
, @UserId
, @CreatedTime
, @ModuleIterationStatusId
)
OUTPUT Inserted.Id
INTO #CreatedProcessingLogs;
INSERT INTO stgProcessingLogDetail
(Message
, Type
, CreatedById
, CreatedTime
, ProcessingLogId
)
SELECT 'Successful'
, 'Information'
, @UserId
, @CreatedTime
, Id
FROM #CreatedProcessingLogs;
MERGE stgProcessingLog AS ProcessingLog
USING
(
SELECT DISTINCT
StagingRootEntityId
FROM #ErrorLogs
) AS ProcessedMasterAgreements
ON(ProcessingLog.StagingRootEntityId = ProcessedMasterAgreements.StagingRootEntityId
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
(ProcessedMasterAgreements.StagingRootEntityId
, @UserId
, @CreatedTime
, @ModuleIterationStatusId
)
OUTPUT Inserted.Id
, ProcessedMasterAgreements.StagingRootEntityId
INTO #FailedProcessingLogs;
INSERT INTO stgProcessingLogDetail
(Message
, Type
, CreatedById
, CreatedTime
, ProcessingLogId
)
SELECT #ErrorLogs.Message
, #ErrorLogs.Result
, @UserId
, @CreatedTime
, #FailedProcessingLogs.Id
FROM #ErrorLogs
JOIN #FailedProcessingLogs ON #ErrorLogs.StagingRootEntityId = #FailedProcessingLogs.MasterAgreementId;
DROP TABLE #ErrorLogs;
DROP TABLE #FailedProcessingLogs;
DROP TABLE #CreatedProcessingLogs;
END;

GO

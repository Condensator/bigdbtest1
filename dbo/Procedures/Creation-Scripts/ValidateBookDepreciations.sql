SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ValidateBookDepreciations]
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
([Id]                 BIGINT NOT NULL,
[BookDepreciationId] BIGINT NOT NULL
);
CREATE TABLE #CreatedProcessingLogs([Id] BIGINT NOT NULL);
SET @ProcessedRecords =
(
SELECT ISNULL(COUNT(Id), 0)
FROM stgBookDepreciation
WHERE IsMigrated = 0
);
INSERT INTO #ErrorLogs
SELECT Id
, 'Error'
, ('Remaining Life in Months must be greater than 0 for BookDepreciation {' + CONVERT(nvarchar(10),Id) + '}') AS Message
FROM stgBookDepreciation
WHERE EndDate IS NOT NULL
AND RemainingLifeInMonths < 0
AND stgBookDepreciation.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT Id
, 'Error'
, ('Cost Basis must not be equal to 0 for BookDepreciation {' + CONVERT(nvarchar(10),Id) + '}') AS Message
FROM stgBookDepreciation
WHERE CostBasis_Amount = 0.0
AND stgBookDepreciation.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT Id
, 'Error'
, ('Termination Date must be between the Begin Date and End Date for BookDepreciation {' + CONVERT(nvarchar(10),Id) + '}') AS Message
FROM stgBookDepreciation
WHERE TerminatedDate IS NOT NULL
AND TerminatedDate < BeginDate
AND TerminatedDate > EndDate
AND stgBookDepreciation.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT stgBookDepreciation.Id
, 'Error'
, ('Invalid GL Template selected for BookDepreciation {' + CONVERT(nvarchar(10),stgBookDepreciation.Id) + '}') AS Message
FROM stgBookDepreciation
LEFT JOIN GLTemplates ON stgBookDepreciation.GLTemplateName = GLTemplates.Name
AND GLTemplates.IsActive = 1
WHERE GLTemplates.Id IS NULL
AND stgBookDepreciation.IsMigrated = 0
AND stgBookDepreciation.GLTemplateName IS NOT NULL;
INSERT INTO #ErrorLogs
SELECT stgBookDepreciation.Id
, 'Error'
, ('GL Template selected should have GL Transaction type as Book Depreciation for BookDepreciation {' + CONVERT(nvarchar(10),stgBookDepreciation.Id) + '}') AS Message
FROM stgBookDepreciation
LEFT JOIN GLTemplates ON stgBookDepreciation.GLTemplateName = GLTemplates.Name
LEFT JOIN GLTransactionTypes ON GLTemplates.GLTransactionTypeId = GLTransactionTypes.Id
WHERE GLTransactionTypes.Name != 'BookDepreciation'
AND GLTemplates.IsActive = 1
AND GLTransactionTypes.IsActive = 1
AND stgBookDepreciation.IsMigrated = 0
AND GLTransactionTypes.Id IS NULL
AND stgBookDepreciation.GLTemplateName IS NOT NULL;
INSERT INTO #ErrorLogs
SELECT stgBookDepreciation.Id
, 'Error'
, ('Matching Line of Business not found for :' + LineofBusinessName + ' for BookDepreciation {' + CONVERT(nvarchar(10),stgBookDepreciation.Id) + '}') AS Message
FROM stgBookDepreciation
LEFT JOIN dbo.LineofBusinesses lb ON stgBookDepreciation.LineofBusinessName = lb.Name
WHERE lb.Id IS NULL
AND stgBookDepreciation.IsMigrated = 0
AND stgBookDepreciation.LineofBusinessName IS NOT NULL;
INSERT INTO #ErrorLogs
SELECT stgBookDepreciation.Id
, 'Error'
, ('Matching Book Depreciation Template not found for : ' + BookDepreciationTemplateName + ' for BookDepreciation {' + CONVERT(nvarchar(10),stgBookDepreciation.Id) + '}') AS Message
FROM stgBookDepreciation
LEFT JOIN BookDepreciationTemplates ON BookDepreciationTemplates.Name = stgBookDepreciation.BookDepreciationTemplateName
AND BookDepreciationTemplates.IsActive = 1
WHERE BookDepreciationTemplates.Id IS NULL
AND BookDepreciationTemplateName IS NOT NULL
AND stgBookDepreciation.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT stgBookDepreciation.Id
, 'Error'
, ('Matching Branch Name not found for : ' + stgBookDepreciation.BranchName + ' for BookDepreciation {' + CONVERT(nvarchar(10),stgBookDepreciation.Id) + '}') AS Message
FROM stgBookDepreciation
LEFT JOIN Branches ON Branches.BranchName = stgBookDepreciation.BranchName
AND Branches.STATUS = 'Active'
WHERE Branches.Id IS NULL
AND Branches.BranchName IS NOT NULL
AND stgBookDepreciation.IsMigrated = 0;
SET @FailedRecords =
(
SELECT ISNULL(COUNT(DISTINCT StagingRootEntityId), 0)
FROM #ErrorLogs
);
MERGE stgProcessingLog AS ProcessingLog
USING
(
SELECT Id
FROM stgBookDepreciation
WHERE IsMigrated = 0
AND Id NOT IN
(
SELECT StagingRootEntityId
FROM #ErrorLogs
)
) AS ProcessedBookDepreciations
ON(ProcessingLog.StagingRootEntityId = ProcessedBookDepreciations.Id
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
(ProcessedBookDepreciations.Id
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
) AS ErrorBookDepreciations
ON(ProcessingLog.StagingRootEntityId = ErrorBookDepreciations.StagingRootEntityId
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
(ErrorBookDepreciations.StagingRootEntityId
, @UserId
, @CreatedTime
, @ModuleIterationStatusId
)
OUTPUT Inserted.Id
, ErrorBookDepreciations.StagingRootEntityId
INTO #FailedProcessingLogs;
INSERT INTO stgProcessingLogDetail
(Message
, Type
, CreatedById
, CreatedTime
, ProcessingLogId
)
SELECT #ErrorLogs.Message
, 'Error'
, @UserId
, @CreatedTime
, #FailedProcessingLogs.Id
FROM #ErrorLogs
JOIN #FailedProcessingLogs ON #ErrorLogs.StagingRootEntityId = #FailedProcessingLogs.BookDepreciationId;
DROP TABLE #ErrorLogs;
DROP TABLE #FailedProcessingLogs;
DROP TABLE #CreatedProcessingLogs;
END;

GO

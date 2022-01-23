SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ValidateInsurancePolicies]
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
(Id                BIGINT NOT NULL,
InsurancePolicyId BIGINT NOT NULL
);
CREATE TABLE #CreatedProcessingLogs([Id] BIGINT NOT NULL);
SET @ProcessedRecords =
(
SELECT ISNULL(COUNT(Id), 0)
FROM dbo.stgInsurancePolicy
WHERE IsMigrated = 0
);
INSERT INTO #ErrorLogs
SELECT DISTINCT
ip.Id
, 'Error'
, ('Invalid legal entity number { ' + ISNULL(ip.LegalEntityNumber, 'NULL') + '} for insurance policy {' + CONVERT(NVARCHAR(10), ip.Id) + '}') AS Message
FROM dbo.stgInsurancePolicy ip
LEFT JOIN dbo.LegalEntities le ON le.LegalEntityNumber = ip.LegalEntityNumber
AND le.STATUS = 'Active'
WHERE ip.IsMigrated = 0
AND ip.LegalEntityNumber IS NOT NULL
AND le.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
ip.Id
, 'Error'
, ('Invalid currency code { ' + ISNULL(ip.CurrencyCode, 'NULL') + '} for insurance policy {' + CONVERT(NVARCHAR(10), ip.Id) + '}') AS Message
FROM dbo.stgInsurancePolicy ip
LEFT JOIN dbo.CurrencyCodes cc ON ip.CurrencyCode = cc.ISO
AND cc.IsActive = 1
LEFT JOIN dbo.Currencies c ON cc.Id = c.CurrencyCodeId
AND c.IsActive = 1
WHERE ip.IsMigrated = 0
AND ip.CurrencyCode IS NOT NULL
AND c.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
ip.Id
, 'Error'
, ('Invalid state name { ' + ISNULL(ip.StateShortName, 'NULL') + '} for Lien Filing {' + CONVERT(NVARCHAR(10), ip.Id) + '}') AS Message
FROM dbo.stgInsurancePolicy ip
LEFT JOIN dbo.States s ON ip.StateShortName = s.ShortName
AND s.IsActive = 1
LEFT JOIN dbo.Countries c ON c.ShortName = ip.CountryShortName
AND c.Id = s.CountryId
AND c.IsActive = 1
WHERE ip.IsMigrated = 0
AND ip.StateShortName IS NOT NULL
AND c.Id IS NULL;
SET @FailedRecords =
(
SELECT ISNULL(COUNT(DISTINCT StagingRootEntityId), 0)
FROM #ErrorLogs
);
MERGE stgProcessingLog AS ProcessingLog
USING
(
SELECT Id
FROM stgInsurancePolicy
WHERE IsMigrated = 0
AND Id NOT IN
(
SELECT StagingRootEntityId
FROM #ErrorLogs
)
) AS ProcessedInsurancePolicys
ON(ProcessingLog.StagingRootEntityId = ProcessedInsurancePolicys.Id
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
(ProcessedInsurancePolicys.Id
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
) AS ErrorInsurancePolicys
ON(ProcessingLog.StagingRootEntityId = ErrorInsurancePolicys.StagingRootEntityId
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
(ErrorInsurancePolicys.StagingRootEntityId
, @UserId
, @CreatedTime
, @ModuleIterationStatusId
)
OUTPUT Inserted.Id
, ErrorInsurancePolicys.StagingRootEntityId
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
JOIN #FailedProcessingLogs ON #ErrorLogs.StagingRootEntityId = #FailedProcessingLogs.InsurancePolicyId;
DROP TABLE #ErrorLogs;
DROP TABLE #FailedProcessingLogs;
DROP TABLE #CreatedProcessingLogs;
END;

GO

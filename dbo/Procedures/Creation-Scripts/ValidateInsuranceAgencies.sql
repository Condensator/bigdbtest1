SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ValidateInsuranceAgencies]
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
InsuranceAgencyId BIGINT NOT NULL
);
CREATE TABLE #CreatedProcessingLogs([Id] BIGINT NOT NULL);
SET @ProcessedRecords =
(
SELECT ISNULL(COUNT(Id), 0)
FROM stgInsuranceAgency
WHERE IsMigrated = 0
);
INSERT INTO #ErrorLogs
SELECT IA.Id
, 'Error'
, ('CompanyName is mandatory for InsuranceAgency for InsuranceAgencyId {' + CONVERT(NVARCHAR(MAX), IA.Id) + '}')
FROM stgInsuranceAgency IA
WHERE IA.IsMigrated = 0
AND LTRIM(RTRIM(IA.CompanyName)) = '';
INSERT INTO #ErrorLogs
SELECT IA.Id
, 'Error'
, ('Invalid State for InsuranceAgency Address Id {' + CONVERT(NVARCHAR(MAX), IAA.Id) + '} with InsuranceAgencyId {' + CONVERT(NVARCHAR(MAX), IA.Id) + '}')
FROM stgInsuranceAgency IA
INNER JOIN stgInsuranceAgencyAddress IAA ON IAA.InsuranceAgencyId = IA.Id
LEFT JOIN dbo.States ON IAA.State = States.ShortName
WHERE IA.IsMigrated = 0
AND LTRIM(RTRIM(IAA.State)) <> ''
AND States.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT IA.Id
, 'Error'
, ('Invalid HomeState for InsuranceAgency Address Id {' + CONVERT(NVARCHAR(MAX), IAA.Id) + '} with InsuranceAgencyId {' + CONVERT(NVARCHAR(MAX), IA.Id) + '}')
FROM stgInsuranceAgency IA
INNER JOIN stgInsuranceAgencyAddress IAA ON IAA.InsuranceAgencyId = IA.Id
LEFT JOIN dbo.States ON IAA.HomeState = States.ShortName
WHERE IA.IsMigrated = 0
AND LTRIM(RTRIM(IAA.HomeState)) <> ''
AND States.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT IA.Id
, 'Error'
, ('Invalid Country for InsuranceAgency Address Id {' + CONVERT(NVARCHAR(MAX), IAA.Id) + '} with InsuranceAgencyId {' + CONVERT(NVARCHAR(MAX), IA.Id) + '}')
FROM stgInsuranceAgency IA
INNER JOIN stgInsuranceAgencyAddress IAA ON IAA.InsuranceAgencyId = IA.Id
LEFT JOIN dbo.Countries ON IAA.Country = Countries.ShortName
WHERE IA.IsMigrated = 0
AND LTRIM(RTRIM(IAA.Country)) <> ''
AND Countries.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT IA.Id
, 'Error'
, ('Invalid HomeCountry for InsuranceAgency Address Id {' + CONVERT(NVARCHAR(MAX), IAA.Id) + '} with InsuranceAgencyId {' + CONVERT(NVARCHAR(MAX), IA.Id) + '}')
FROM stgInsuranceAgency IA
INNER JOIN stgInsuranceAgencyAddress IAA ON IAA.InsuranceAgencyId = IA.Id
LEFT JOIN dbo.Countries ON IAA.HomeCountry = Countries.ShortName
WHERE IA.IsMigrated = 0
AND LTRIM(RTRIM(IAA.HomeCountry)) <> ''
AND Countries.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT IA.Id
, 'Error'
, ('PostalCode : {' + ISNULL(IAA.PostalCode, 'NULL') + '} is not in correct format, please enter PostalCode with the regex format : {' + dbo.Countries.PostalCodeMask + '} with InsuranceAgency Id {' + CONVERT(NVARCHAR(MAX), IAA.InsuranceAgencyId) + '}') AS Message
FROM stgInsuranceAgency IA
INNER JOIN stgInsuranceAgencyAddress IAA ON IA.Id = IAA.InsuranceAgencyId
INNER JOIN dbo.Countries ON IAA.Country = Countries.ShortName
WHERE IA.IsMigrated = 0
AND dbo.Countries.PostalCodeMask IS NOT NULL
AND IAA.PostalCode IS NOT NULL
AND dbo.RegexStringMatch(IAA.PostalCode, dbo.Countries.PostalCodeMask) = 0;
INSERT INTO #ErrorLogs
SELECT IA.Id
, 'Error'
, ('HomePostalCode : {' + ISNULL(IAA.HomePostalCode, 'NULL') + '} is not in correct format, please enter HomePostalCode with the regex format : {' + dbo.Countries.PostalCodeMask + '} with InsuranceAgency Id  {' + CONVERT(NVARCHAR(MAX), IAA.InsuranceAgencyId) + '}') AS Message
FROM stgInsuranceAgency IA
INNER JOIN stgInsuranceAgencyAddress IAA ON IA.Id = IAA.InsuranceAgencyId
INNER JOIN dbo.Countries ON IAA.HomeCountry = Countries.ShortName
WHERE IA.IsMigrated = 0
AND dbo.Countries.PostalCodeMask IS NOT NULL
AND IAA.HomePostalCode IS NOT NULL
AND dbo.RegexStringMatch(IAA.HomePostalCode, dbo.Countries.PostalCodeMask) = 0;
INSERT INTO #ErrorLogs
SELECT IAA.InsuranceAgencyId
, 'Error'
, ('Please enter Valid Office Address for the Address indicated as Main Address with InsuranceAgencyId {' + CONVERT(NVARCHAR(MAX), IA.Id) + ' and UniqueIdentifier ' + ISNULL(IAA.UniqueIdentifier, 'NULL') + '}')
FROM stgInsuranceAgency IA
INNER JOIN stgInsuranceAgencyAddress IAA ON IAA.InsuranceAgencyId = IA.Id
WHERE IA.IsMigrated = 0
AND IAA.Id IS NOT NULL
AND IAA.IsMain = 1
AND (IAA.AddressLine1 IS NULL
AND IAA.City IS NULL
AND IAA.State IS NULL
AND IAA.Country IS NULL
AND IAA.PostalCode IS NULL);
INSERT INTO #ErrorLogs
SELECT IA.Id
, 'Error'
, ('Provided Home Address is not valid for InsuranceAgencyId {' + CONVERT(NVARCHAR(MAX), IA.Id) + ' and UniqueIdentifier ' + ISNULL(IAA.UniqueIdentifier, 'NULL') + '}')
FROM stgInsuranceAgency IA
INNER JOIN stgInsuranceAgencyAddress IAA ON IAA.InsuranceAgencyId = IA.Id
WHERE IA.IsMigrated = 0
AND IAA.Id IS NOT NULL
AND (IAA.HomeAddressLine1 IS NOT NULL
AND (IAA.HomeState IS NULL
OR IAA.HomeCity IS NULL
OR IAA.HomePostalCode IS NULL
OR IAA.HomeCountry IS NULL)
OR IAA.HomeState IS NOT NULL
AND (IAA.HomeAddressLine1 IS NULL
OR IAA.HomeCity IS NULL
OR IAA.HomePostalCode IS NULL
OR IAA.HomeCountry IS NULL)
OR IAA.HomeCity IS NOT NULL
AND (IAA.HomeState IS NULL
OR IAA.HomeAddressLine1 IS NULL
OR IAA.HomePostalCode IS NULL
OR IAA.HomeCountry IS NULL)
OR IAA.HomePostalCode IS NOT NULL
AND (IAA.HomeState IS NULL
OR IAA.HomeAddressLine1 IS NULL
OR IAA.HomeCity IS NULL
OR IAA.HomeCountry IS NULL)
OR IAA.HomeCountry IS NOT NULL
AND (IAA.HomeState IS NULL
OR IAA.HomeAddressLine1 IS NULL
OR IAA.HomeCity IS NULL
OR IAA.HomePostalCode IS NULL));
INSERT INTO #ErrorLogs
SELECT IA.Id
, 'Error'
, ('Provided Office Address is not valid for InsuranceAgencyId {' + CONVERT(NVARCHAR(MAX), IA.Id) + ' and UniqueIdentifier ' + ISNULL(IAA.UniqueIdentifier, 'NULL') + '}')
FROM stgInsuranceAgency IA
INNER JOIN stgInsuranceAgencyAddress IAA ON IAA.InsuranceAgencyId = IA.Id
WHERE IA.IsMigrated = 0
AND IAA.Id IS NOT NULL
AND (IAA.AddressLine1 IS NOT NULL
AND (IAA.State IS NULL
OR IAA.City IS NULL
OR IAA.PostalCode IS NULL
OR IAA.Country IS NULL)
OR IAA.State IS NOT NULL
AND (IAA.AddressLine1 IS NULL
OR IAA.City IS NULL
OR IAA.PostalCode IS NULL
OR IAA.Country IS NULL)
OR IAA.City IS NOT NULL
AND (IAA.State IS NULL
OR IAA.AddressLine1 IS NULL
OR IAA.PostalCode IS NULL
OR IAA.Country IS NULL)
OR IAA.PostalCode IS NOT NULL
AND (IAA.State IS NULL
OR IAA.AddressLine1 IS NULL
OR IAA.City IS NULL
OR IAA.Country IS NULL)
OR IAA.Country IS NOT NULL
AND (IAA.State IS NULL
OR IAA.AddressLine1 IS NULL
OR IAA.City IS NULL
OR IAA.PostalCode IS NULL));
INSERT INTO #ErrorLogs
SELECT IA.Id
, 'Error'
, ('Please set at least one of the address as Main Address for Vendor with VendorId {' + CONVERT(NVARCHAR(MAX), IA.Id) + '}')
FROM stgInsuranceAgency IA
WHERE IA.IsMigrated = 0
AND IA.Id NOT IN
(
SELECT IAA.InsuranceAgencyId
FROM stgInsuranceAgencyAddress IAA
WHERE IsMain = 1
GROUP BY IAA.InsuranceAgencyId
HAVING COUNT(*) > 0
);
SET @FailedRecords =
(
SELECT ISNULL(COUNT(DISTINCT StagingRootEntityId), 0)
FROM #ErrorLogs
);
MERGE stgProcessingLog AS ProcessingLog
USING
(
SELECT Id
FROM stgInsuranceAgency
WHERE IsMigrated = 0
AND Id NOT IN
(
SELECT StagingRootEntityId
FROM #ErrorLogs
)
) AS ProcessedInsuranceAgencys
ON(ProcessingLog.StagingRootEntityId = ProcessedInsuranceAgencys.Id
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
(ProcessedInsuranceAgencys.Id
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
) AS ErrorInsuranceAgencys
ON(ProcessingLog.StagingRootEntityId = ErrorInsuranceAgencys.StagingRootEntityId
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
(ErrorInsuranceAgencys.StagingRootEntityId
, @UserId
, @CreatedTime
, @ModuleIterationStatusId
)
OUTPUT Inserted.Id
, ErrorInsuranceAgencys.StagingRootEntityId
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
JOIN #FailedProcessingLogs ON #ErrorLogs.StagingRootEntityId = #FailedProcessingLogs.InsuranceAgencyId;
DROP TABLE #ErrorLogs;
DROP TABLE #FailedProcessingLogs;
DROP TABLE #CreatedProcessingLogs;
END;

GO

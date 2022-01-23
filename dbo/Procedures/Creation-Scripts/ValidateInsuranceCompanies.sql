SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ValidateInsuranceCompanies]
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
InsuranceCompanyId BIGINT NOT NULL
);
CREATE TABLE #CreatedProcessingLogs([Id] BIGINT NOT NULL);
SET @ProcessedRecords =
(
SELECT ISNULL(COUNT(Id), 0)
FROM stgInsuranceCompany
WHERE IsMigrated = 0
);
INSERT INTO #ErrorLogs
SELECT IC.Id
, 'Error'
, ('CompanyName is mandatory for InsuranceCompany for InsuranceCompanyId {' + CONVERT(NVARCHAR(MAX), IC.Id) + '}')
FROM stgInsuranceCompany IC
WHERE IC.IsMigrated = 0
AND LTRIM(RTRIM(IC.CompanyName)) = '';
INSERT INTO #ErrorLogs
SELECT IC.Id
, 'Error'
, ('Invalid State for InsuranceCompany Address Id {' + CONVERT(NVARCHAR(MAX), ICA.Id) + '} with InsuranceCompanyId {' + CONVERT(NVARCHAR(MAX), IC.Id) + '}')
FROM stgInsuranceCompany IC
INNER JOIN stgInsuranceCompanyAddress ICA ON ICA.InsuranceCompanyId = IC.Id
LEFT JOIN dbo.States ON ICA.State = States.ShortName
WHERE IC.IsMigrated = 0
AND LTRIM(RTRIM(ICA.State)) <> ''
AND States.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT IC.Id
, 'Error'
, ('Invalid HomeState for InsuranceCompany Address Id {' + CONVERT(NVARCHAR(MAX), ICA.Id) + '} with InsuranceCompanyId {' + CONVERT(NVARCHAR(MAX), IC.Id) + '}')
FROM stgInsuranceCompany IC
INNER JOIN stgInsuranceCompanyAddress ICA ON ICA.InsuranceCompanyId = IC.Id
LEFT JOIN dbo.States ON ICA.HomeState = States.ShortName
WHERE IC.IsMigrated = 0
AND LTRIM(RTRIM(ICA.HomeState)) <> ''
AND States.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT IC.Id
, 'Error'
, ('Invalid Country for InsuranceCompany Address Id {' + CONVERT(NVARCHAR(MAX), ICA.Id) + '} with InsuranceCompanyId {' + CONVERT(NVARCHAR(MAX), IC.Id) + '}')
FROM stgInsuranceCompany IC
INNER JOIN stgInsuranceCompanyAddress ICA ON ICA.InsuranceCompanyId = IC.Id
LEFT JOIN dbo.Countries ON ICA.Country = Countries.ShortName
WHERE IC.IsMigrated = 0
AND LTRIM(RTRIM(ICA.Country)) <> ''
AND Countries.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT IC.Id
, 'Error'
, ('Invalid HomeCountry for InsuranceCompany Address Id {' + CONVERT(NVARCHAR(MAX), ICA.Id) + '} with InsuranceCompanyId {' + CONVERT(NVARCHAR(MAX), IC.Id) + '}')
FROM stgInsuranceCompany IC
INNER JOIN stgInsuranceCompanyAddress ICA ON ICA.InsuranceCompanyId = IC.Id
LEFT JOIN dbo.Countries ON ICA.HomeCountry = Countries.ShortName
WHERE IC.IsMigrated = 0
AND LTRIM(RTRIM(ICA.HomeCountry)) <> ''
AND Countries.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT IC.Id
, 'Error'
, ('PostalCode : {' + ISNULL(ICA.PostalCode, 'NULL') + '} is not in correct format, please enter PostalCode with the regex format : {' + dbo.Countries.PostalCodeMask + '} with InsuranceCompany Id {' + CONVERT(NVARCHAR(MAX), ICA.InsuranceCompanyId) + '}') AS Message
FROM stgInsuranceCompany IC
INNER JOIN stgInsuranceCompanyAddress ICA ON IC.Id = ICA.InsuranceCompanyId
INNER JOIN dbo.Countries ON ICA.Country = Countries.ShortName
WHERE IC.IsMigrated = 0
AND dbo.Countries.PostalCodeMask IS NOT NULL
AND ICA.PostalCode IS NOT NULL
AND dbo.RegexStringMatch(ICA.PostalCode, dbo.Countries.PostalCodeMask) = 0;
INSERT INTO #ErrorLogs
SELECT IC.Id
, 'Error'
, ('HomePostalCode : {' + ISNULL(ICA.HomePostalCode, 'NULL') + '} is not in correct format, please enter HomePostalCode with the regex format : {' + dbo.Countries.PostalCodeMask + '} with InsuranceCompany Id  {' + CONVERT(NVARCHAR(MAX), ICA.InsuranceCompanyId) + '}') AS Message
FROM stgInsuranceCompany IC
INNER JOIN stgInsuranceCompanyAddress ICA ON IC.Id = ICA.InsuranceCompanyId
INNER JOIN dbo.Countries ON ICA.HomeCountry = Countries.ShortName
WHERE IC.IsMigrated = 0
AND dbo.Countries.PostalCodeMask IS NOT NULL
AND ICA.HomePostalCode IS NOT NULL
AND dbo.RegexStringMatch(ICA.HomePostalCode, dbo.Countries.PostalCodeMask) = 0;
INSERT INTO #ErrorLogs
SELECT ICA.InsuranceCompanyId
, 'Error'
, ('Please enter Valid Office Address for the Address indicated as Main Address with InsuranceCompanyId {' + CONVERT(NVARCHAR(MAX), IC.Id) + ' and UniqueIdentifier ' + ISNULL(ICA.UniqueIdentifier, 'NULL') + '}')
FROM stgInsuranceCompany IC
INNER JOIN stgInsuranceCompanyAddress ICA ON ICA.InsuranceCompanyId = IC.Id
WHERE IC.IsMigrated = 0
AND ICA.Id IS NOT NULL
AND ICA.IsMain = 1
AND (ICA.AddressLine1 IS NULL
AND ICA.City IS NULL
AND ICA.State IS NULL
AND ICA.Country IS NULL
AND ICA.PostalCode IS NULL);
INSERT INTO #ErrorLogs
SELECT IC.Id
, 'Error'
, ('Provided Home Address is not valid for InsuranceCompanyId {' + CONVERT(NVARCHAR(MAX), IC.Id) + ' and UniqueIdentifier ' + ISNULL(ICA.UniqueIdentifier, 'NULL') + '}')
FROM stgInsuranceCompany IC
INNER JOIN stgInsuranceCompanyAddress ICA ON ICA.InsuranceCompanyId = IC.Id
WHERE IC.IsMigrated = 0
AND ICA.Id IS NOT NULL
AND (ICA.HomeAddressLine1 IS NOT NULL
AND (ICA.HomeState IS NULL
OR ICA.HomeCity IS NULL
OR ICA.HomePostalCode IS NULL
OR ICA.HomeCountry IS NULL)
OR ICA.HomeState IS NOT NULL
AND (ICA.HomeAddressLine1 IS NULL
OR ICA.HomeCity IS NULL
OR ICA.HomePostalCode IS NULL
OR ICA.HomeCountry IS NULL)
OR ICA.HomeCity IS NOT NULL
AND (ICA.HomeState IS NULL
OR ICA.HomeAddressLine1 IS NULL
OR ICA.HomePostalCode IS NULL
OR ICA.HomeCountry IS NULL)
OR ICA.HomePostalCode IS NOT NULL
AND (ICA.HomeState IS NULL
OR ICA.HomeAddressLine1 IS NULL
OR ICA.HomeCity IS NULL
OR ICA.HomeCountry IS NULL)
OR ICA.HomeCountry IS NOT NULL
AND (ICA.HomeState IS NULL
OR ICA.HomeAddressLine1 IS NULL
OR ICA.HomeCity IS NULL
OR ICA.HomePostalCode IS NULL));
INSERT INTO #ErrorLogs
SELECT IC.Id
, 'Error'
, ('Provided Office Address is not valid for InsuranceCompanyId {' + CONVERT(NVARCHAR(MAX), IC.Id) + ' and UniqueIdentifier ' + ISNULL(ICA.UniqueIdentifier, 'NULL') + '}')
FROM stgInsuranceCompany IC
INNER JOIN stgInsuranceCompanyAddress ICA ON ICA.InsuranceCompanyId = IC.Id
WHERE IC.IsMigrated = 0
AND ICA.Id IS NOT NULL
AND (ICA.AddressLine1 IS NOT NULL
AND (ICA.State IS NULL
OR ICA.City IS NULL
OR ICA.PostalCode IS NULL
OR ICA.Country IS NULL)
OR ICA.State IS NOT NULL
AND (ICA.AddressLine1 IS NULL
OR ICA.City IS NULL
OR ICA.PostalCode IS NULL
OR ICA.Country IS NULL)
OR ICA.City IS NOT NULL
AND (ICA.State IS NULL
OR ICA.AddressLine1 IS NULL
OR ICA.PostalCode IS NULL
OR ICA.Country IS NULL)
OR ICA.PostalCode IS NOT NULL
AND (ICA.State IS NULL
OR ICA.AddressLine1 IS NULL
OR ICA.City IS NULL
OR ICA.Country IS NULL)
OR ICA.Country IS NOT NULL
AND (ICA.State IS NULL
OR ICA.AddressLine1 IS NULL
OR ICA.City IS NULL
OR ICA.PostalCode IS NULL));
INSERT INTO #ErrorLogs
SELECT IC.Id
, 'Error'
, ('Please set at least one of the address as Main Address for Vendor with VendorId {' + CONVERT(NVARCHAR(MAX), IC.Id) + '}')
FROM stgInsuranceCompany IC
WHERE IC.IsMigrated = 0
AND IC.Id NOT IN
(
SELECT ICA.InsuranceCompanyId
FROM stgInsuranceCompanyAddress ICA
WHERE IsMain = 1
GROUP BY ICA.InsuranceCompanyId
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
FROM stgInsuranceCompany
WHERE IsMigrated = 0
AND Id NOT IN
(
SELECT StagingRootEntityId
FROM #ErrorLogs
)
) AS ProcessedInsuranceCompanys
ON(ProcessingLog.StagingRootEntityId = ProcessedInsuranceCompanys.Id
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
(ProcessedInsuranceCompanys.Id
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
) AS ErrorInsuranceCompanys
ON(ProcessingLog.StagingRootEntityId = ErrorInsuranceCompanys.StagingRootEntityId
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
(ErrorInsuranceCompanys.StagingRootEntityId
, @UserId
, @CreatedTime
, @ModuleIterationStatusId
)
OUTPUT Inserted.Id
, ErrorInsuranceCompanys.StagingRootEntityId
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
JOIN #FailedProcessingLogs ON #ErrorLogs.StagingRootEntityId = #FailedProcessingLogs.InsuranceCompanyId;
DROP TABLE #ErrorLogs;
DROP TABLE #FailedProcessingLogs;
DROP TABLE #CreatedProcessingLogs;
END;

GO

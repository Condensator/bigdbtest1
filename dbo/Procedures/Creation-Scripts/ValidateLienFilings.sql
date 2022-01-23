SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ValidateLienFilings]
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
(Id           BIGINT NOT NULL,
LienFilingId BIGINT NOT NULL
);
CREATE TABLE #CreatedProcessingLogs([Id] BIGINT NOT NULL);
SET @ProcessedRecords =
(
SELECT ISNULL(COUNT(Id), 0)
FROM stgLienFiling
WHERE IsMigrated = 0
);
DECLARE @IsILien BIT=
(
SELECT CASE
WHEN Value = 'true'
THEN 1
ELSE 0
END
FROM GlobalParameters
WHERE Category = 'LienFiling'
AND Name = 'IsILien'
);
DECLARE @ExternalBusinessTypeConfig TABLE(BusinessTypeName NVARCHAR(100));
INSERT INTO @ExternalBusinessTypeConfig
SELECT Name
FROM ExternalBusinessTypeConfigs
WHERE IsILien = @IsILien;
INSERT INTO #ErrorLogs
SELECT DISTINCT
lf.Id
, 'Error'
, ('Selected Secured Legal Entity Number does not exist: ' + ISNULL(lf.SecuredLegalEntityNumber, 'NULL') + ' for Lien Filing {' + CONVERT(NVARCHAR(10), lf.Id) + '}') AS Message
FROM dbo.stgLienFiling lf
LEFT JOIN dbo.LegalEntities le ON le.LegalEntityNumber = lf.SecuredLegalEntityNumber
AND le.STATUS = 'Active'
WHERE lf.IsMigrated = 0
AND lf.SecuredLegalEntityNumber IS NOT NULL
AND le.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
lf.Id
, 'Error'
, ('Invalid Alt Filing Type for Lien Filing {' + CONVERT(NVARCHAR(10), lf.Id) + '}') AS Message
FROM dbo.stgLienFiling lf
LEFT JOIN dbo.LegalEntities le ON le.LegalEntityNumber = lf.SecuredLegalEntityNumber
AND le.STATUS = 'Active'
WHERE lf.IsMigrated = 0
AND @IsILien = 1
AND lf.AltFilingType IS NOT NULL
AND lf.AltFilingType <> '_'
AND lf.AltFilingType NOT IN('AgLien', 'NonUCCFiling', 'TransmittingUtility', 'ManufacturedHome', 'PublicFinance', 'FoodSecurityAct', 'FixtureFiling', 'NOAltType');
INSERT INTO #ErrorLogs
SELECT DISTINCT
lf.Id
, 'Error'
, ('Invalid Alt Name Designation for Lien Filing {' + CONVERT(NVARCHAR(10), lf.Id) + '}') AS Message
FROM dbo.stgLienFiling lf
WHERE lf.IsMigrated = 0
AND @IsILien = 1
AND lf.AltNameDesignation IS NOT NULL
AND lf.AltNameDesignation <> '_'
AND lf.AltNameDesignation NOT IN('Lessee_Lessor', 'Consignee_Consignor', 'Bailee_Bailor', 'Seller_Buyer', 'NOAltName');
INSERT INTO #ErrorLogs
SELECT DISTINCT
lf.Id
, 'Error'
, ('Invalid Attachment Type for Lien Filing {' + CONVERT(NVARCHAR(10), lf.Id) + '}') AS Message
FROM dbo.stgLienFiling lf
WHERE lf.IsMigrated = 0
AND @IsILien = 1
AND lf.AttachmentType IS NOT NULL
AND lf.AttachmentType <> '_'
AND lf.AttachmentType NOT IN('NoType', 'F', 'C', 'E', 'P');
INSERT INTO #ErrorLogs
SELECT DISTINCT
lf.Id
, 'Error'
, ('Only Approved Lien Filing can be migrated for Lien Filing {' + CONVERT(NVARCHAR(10), lf.Id) + '}') AS Message
FROM dbo.stgLienFiling lf
WHERE lf.IsMigrated = 0
AND (lf.LienRefNumber IS NULL
OR lf.LienFilingStatus <> 'Approved');
INSERT INTO #ErrorLogs
SELECT DISTINCT
lf.Id
, 'Error'
, ('Selected Date Of Maturity cannot be null for Filing {' + CONVERT(NVARCHAR(10), lf.Id) + '}') AS Message
FROM dbo.stgLienFiling lf
WHERE lf.IsMigrated = 0
AND lf.DateOfMaturity IS NULL
AND lf.IsNoFixedDate = 0
AND lf.Type = 'PPSA';
INSERT INTO #ErrorLogs
SELECT DISTINCT
lf.Id
, 'Error'
, ('Selected Description does not exist for Filing {' + CONVERT(NVARCHAR(10), lf.Id) + '}') AS Message
FROM dbo.stgLienFiling lf
WHERE lf.IsMigrated = 0
AND lf.Description IS NULL
AND lf.IsFinancialStatementRequiredForRealEstate = 1;
INSERT INTO #ErrorLogs
SELECT DISTINCT
lf.Id
, 'Error'
, ('Selected Filing Alias cannot contain special characters for Filing {' + CONVERT(NVARCHAR(10), lf.Id) + '}') AS Message
FROM dbo.stgLienFiling lf
WHERE lf.IsMigrated = 0
AND lf.FilingAlias LIKE '%[^a-z 0-9]%';
INSERT INTO #ErrorLogs
SELECT DISTINCT
lf.Id
, 'Error'
, ('Lien Response should be available for {' + CONVERT(NVARCHAR(10), lf.Id) + '}') AS Message
FROM dbo.stgLienFiling lf
LEFT JOIN dbo.stgLienResponse lr ON lr.Id = lf.Id
WHERE lf.IsMigrated = 0
AND lr.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
lf.Id
, 'Error'
, ('Selected Amendment Type does not exist for Filing {' + CONVERT(NVARCHAR(10), lf.Id) + '}') AS Message
FROM dbo.stgLienFiling lf
WHERE lf.IsMigrated = 0
AND (lf.AmendmentType IS NULL
OR lf.AmendmentType = '_')
AND lf.TransactionType = 'Amendment' 
INSERT INTO #ErrorLogs
SELECT DISTINCT
lf.Id
, 'Error'
, ('Invalid Amendment Type {' + CONVERT(NVARCHAR(10), lf.Id) + '}') AS Message
FROM dbo.stgLienFiling lf
WHERE lf.IsMigrated = 0
AND lf.TransactionType = 'Amendment'
AND (@IsILien = 1
AND lf.AmendmentType NOT IN('AmendmentCollateral', 'AmendmentParties', 'Assignment', 'Continuation', 'TerminationSecuredParty', 'NOType')
OR @IsILien = 0
AND lf.AmendmentType NOT IN('DebtorAmendment', 'AmendmentCollateral', 'AmendmentParties', 'Assignment', 'Continuation', 'Termination', 'NOType'));
INSERT INTO #ErrorLogs
SELECT DISTINCT
lf.Id
, 'Error'
, ('Selected Amendment Action does not exist for Filing {' + CONVERT(NVARCHAR(10), lf.Id) + '}') AS Message
FROM dbo.stgLienFiling lf
WHERE lf.IsMigrated = 0
AND (lf.AmendmentAction IS NULL
OR lf.AmendmentAction = '_')
AND lf.TransactionType = 'Amendment' 
INSERT INTO #ErrorLogs
SELECT DISTINCT
lf.Id
, 'Error'
, ('Selected Authorizing Party Type does not exist for Filing {' + CONVERT(NVARCHAR(10), lf.Id) + '}') AS Message
FROM dbo.stgLienFiling lf
WHERE lf.IsMigrated = 0
AND (lf.AuthorizingPartyType IS NULL
OR lf.AuthorizingPartyType = '_')
AND lf.TransactionType = 'Amendment'
INSERT INTO #ErrorLogs
SELECT DISTINCT
lf.Id
, 'Error'
, ('Selected Authorizing Legal Entity Number does not exist for Filing {' + CONVERT(NVARCHAR(10), lf.Id) + '}') AS Message
FROM dbo.stgLienFiling lf
LEFT JOIN dbo.LegalEntities le ON lf.AuthorizingLegalEntityNumber = le.LegalEntityNumber
AND le.STATUS = 'Active'
WHERE lf.IsMigrated = 0
AND le.Id IS NULL
AND lf.TransactionType = 'Amendment'
AND lf.AuthorizingPartyType = 'LegalEntity';
INSERT INTO #ErrorLogs
SELECT DISTINCT
lf.Id
, 'Error'
, ('Selected Authorizing Legal Entity Number does not exist {' + ISNULL(lasp.SecuredLegalEntityNumber, 'NULL') + '} for additional secured party {' + CONVERT(NVARCHAR(10), lasp.Id) + '}   for Filing {' + CONVERT(NVARCHAR(10), lf.Id) + '}') AS Message
FROM dbo.stgLienFiling lf
INNER JOIN dbo.stgLienAdditionalSecuredParty lasp ON lf.Id = lasp.LienFilingId
LEFT JOIN dbo.LegalEntities le ON le.LegalEntityNumber = lasp.SecuredLegalEntityNumber
AND le.STATUS = 'Active'
WHERE lf.IsMigrated = 0
AND le.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
lf.Id
, 'Error'
, ('Business Type is not valid for Secured Legal Entity {' + ISNULL(lasp.SecuredLegalEntityNumber, 'NULL') + '} for additional secured party {' + CONVERT(NVARCHAR(10), lasp.Id) + '}   for Filing {' + CONVERT(NVARCHAR(10), lf.Id) + '}') AS Message
FROM dbo.stgLienFiling lf
INNER JOIN dbo.stgLienAdditionalSecuredParty lasp ON lf.Id = lasp.LienFilingId
INNER JOIN dbo.LegalEntities le ON le.LegalEntityNumber = lasp.SecuredLegalEntityNumber
AND le.STATUS = 'Active'
LEFT JOIN dbo.BusinessTypes bt ON le.BusinessTypeId = bt.Id
LEFT JOIN dbo.ExternalBusinessTypeConfigs ebtc ON bt.ExternalBusinessTypeId = ebtc.Id
AND ebtc.Name NOT IN(SELECT BusinessTypeName
FROM @ExternalBusinessTypeConfig)
WHERE ebtc.Id IS NULL
AND lf.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT DISTINCT
lf.Id
, 'Error'
, ('Invalid state for Filing {' + CONVERT(NVARCHAR(10), lf.Id) + '}') AS Message
FROM dbo.stgLienFiling lf
LEFT JOIN dbo.States s ON lf.StateShortName = s.ShortName
AND s.IsActive = 1
WHERE lf.IsMigrated = 0
AND S.Id IS NULL
AND lf.StateShortName IS NOT NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
lf.Id
, 'Error'
, ('Initial File Date cannot be null for Filing {' + CONVERT(NVARCHAR(10), lf.Id) + '} of type {' + ISNULL(lf.TransactionType, 'NULL') + '}') AS Message
FROM dbo.stgLienFiling lf
WHERE lf.IsMigrated = 0
AND (lf.TransactionType = 'InitialHISUCC1'
OR lf.TransactionType = 'AmendmentHISUCC3')
AND lf.InitialFileDate IS NULL
AND @IsIlien = 0;
INSERT INTO #ErrorLogs
SELECT DISTINCT
lf.Id
, 'Error'
, ('Initial File Number cannot be null for Filing {' + CONVERT(NVARCHAR(10), lf.Id) + '} of type {' + ISNULL(lf.TransactionType, 'NULL') + '}') AS Message
FROM dbo.stgLienFiling lf
WHERE lf.IsMigrated = 0
AND (lf.TransactionType = 'InitialHISUCC1'
OR lf.TransactionType = 'AmendmentHISUCC3')
AND lf.InitialFileNumber IS NULL
AND @IsIlien = 0;
INSERT INTO #ErrorLogs
SELECT DISTINCT
lf.Id
, 'Error'
, ('Historical Expiration Date cannot be null for Filing {' + CONVERT(NVARCHAR(10), lf.Id) + '} of type {' + ISNULL(lf.TransactionType, 'NULL') + '}') AS Message
FROM dbo.stgLienFiling lf
WHERE lf.IsMigrated = 0
AND (TransactionType = 'InitialHISUCC1'
OR TransactionType = 'AmendmentHISUCC3')
AND HistoricalExpirationDate IS NULL
AND @IsIlien = 0;
INSERT INTO #ErrorLogs
SELECT DISTINCT
lf.Id
, 'Error'
, ('Financing Statement Date cannot be null for Filing {' + CONVERT(NVARCHAR(10), lf.Id) + '} of type {' + ISNULL(lf.TransactionType, 'NULL') + '}') AS Message
FROM dbo.stgLienFiling lf
WHERE lf.IsMigrated = 0
AND (TransactionType = 'AmendmentHISUCC3')
AND FinancingStatementDate IS NULL
AND @IsIlien = 0;
INSERT INTO #ErrorLogs
SELECT DISTINCT
lf.Id
, 'Error'
, ('Financing Statement File Number cannot be null for Filing {' + CONVERT(NVARCHAR(10), lf.Id) + '} of type {' + ISNULL(lf.TransactionType, 'NULL') + '}') AS Message
FROM dbo.stgLienFiling lf
WHERE lf.IsMigrated = 0
AND (TransactionType = 'AmendmentHISUCC3')
AND FinancingStatementFileNumber IS NULL
AND @IsIlien = 0;
SET @FailedRecords =
(
SELECT ISNULL(COUNT(DISTINCT StagingRootEntityId), 0)
FROM #ErrorLogs
);
MERGE stgProcessingLog AS ProcessingLog
USING
(
SELECT Id
FROM stgLienFiling
WHERE IsMigrated = 0
AND Id NOT IN
(
SELECT StagingRootEntityId
FROM #ErrorLogs
)
) AS ProcessedLienFilings
ON(ProcessingLog.StagingRootEntityId = ProcessedLienFilings.Id
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
(ProcessedLienFilings.Id
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
) AS ErrorLienFilings
ON(ProcessingLog.StagingRootEntityId = ErrorLienFilings.StagingRootEntityId
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
(ErrorLienFilings.StagingRootEntityId
, @UserId
, @CreatedTime
, @ModuleIterationStatusId
)
OUTPUT Inserted.Id
, ErrorLienFilings.StagingRootEntityId
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
JOIN #FailedProcessingLogs ON #ErrorLogs.StagingRootEntityId = #FailedProcessingLogs.LienFilingId;
DROP TABLE #ErrorLogs;
DROP TABLE #FailedProcessingLogs;
DROP TABLE #CreatedProcessingLogs;
END;

GO

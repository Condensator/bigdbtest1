SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ValidateSecurityDeposits]
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
([Id]                BIGINT NOT NULL,
[SecurityDepositId] BIGINT NOT NULL
);
CREATE TABLE #CreatedProcessingLogs([Id] BIGINT NOT NULL);
SET @ProcessedRecords =
(
SELECT ISNULL(COUNT(Id), 0)
FROM stgSecurityDeposit
WHERE IsMigrated = 0
);
SELECT DISTINCT
LineofBusinessId
, LegalEntityId
INTO #LegalEntityLOB
FROM GLOrgStructureConfigs
WHERE IsActive = 1;
SELECT DISTINCT
LegalEntityId
, CostCenterId
, LineofBusinessId
INTO #GLOrgStructureConfigs
FROM GLOrgStructureConfigs
WHERE IsActive = 1;
UPDATE stgSecurityDeposit
SET
R_LineOfBusinessId = LineofBusinesses.Id
FROM stgSecurityDeposit SD
INNER JOIN LineofBusinesses ON LineofBusinesses.Name = SD.LineofBusinessName
AND LineofBusinesses.IsActive = 1
AND SD.EntityType = 'CU'
WHERE SD.IsMigrated = 0
AND SD.R_LineOfBusinessId IS NULL;
INSERT INTO #ErrorLogs
SELECT SD.Id
, 'Error'
, 'Invalid LineofBusinessName : ' + ISNULL(SD.LineofBusinessName, 'NULL') + ' for Security Deposit {Id : ' + CONVERT(NVARCHAR, SD.Id) + '} with EntityType {' + SD.EntityType + '}'
FROM stgSecurityDeposit SD
WHERE SD.IsMigrated = 0
AND SD.R_LineOfBusinessId IS NULL
AND SD.EntityType = 'CU';
UPDATE stgSecurityDeposit
SET
R_LegalEntityId = #LegalEntityLOB.LegalEntityId
FROM stgSecurityDeposit SD
INNER JOIN LineofBusinesses ON LineofBusinesses.Name = SD.LineofBusinessName
AND LineofBusinesses.IsActive = 1
INNER JOIN LegalEntities ON LegalEntities.LegalEntityNumber = SD.LegalEntityNumber
AND LegalEntities.STATUS = 'Active'
INNER JOIN #LegalEntityLOB ON #LegalEntityLOB.LegalEntityId = LegalEntities.Id
AND LineofBusinesses.Id = #LegalEntityLOB.LineofBusinessId
WHERE SD.IsMigrated = 0
AND SD.R_LegalEntityId IS NULL
AND SD.EntityType = 'CU';
INSERT INTO #ErrorLogs
SELECT SD.Id
, 'Error'
, 'Invalid LegalEntityNumber : ' + ISNULL(SD.LegalEntityNumber, 'NULL') + ' for Security Deposit {Id : ' + CONVERT(NVARCHAR, SD.Id) + '} with EntityType {' + SD.EntityType + '}'
FROM stgSecurityDeposit SD
WHERE SD.IsMigrated = 0
AND SD.R_LegalEntityId IS NULL
AND SD.EntityType = 'CU';
UPDATE stgSecurityDeposit
SET
R_CostCenterId = #GLOrgStructureConfigs.CostCenterId
FROM stgSecurityDeposit SD
INNER JOIN LineofBusinesses ON UPPER(LineofBusinesses.Name) = UPPER(SD.LineofBusinessName)
AND LineofBusinesses.IsActive = 1
INNER JOIN LegalEntities ON UPPER(LegalEntities.LegalEntityNumber) = UPPER(SD.LegalEntityNumber)
AND LegalEntities.STATUS = 'Active'
INNER JOIN CostCenterConfigs ON SD.CostCenterName = CostCenterConfigs.CostCenter
AND CostCenterConfigs.IsActive = 1
INNER JOIN #GLOrgStructureConfigs ON #GLOrgStructureConfigs.LegalEntityId = LegalEntities.Id
AND LineofBusinesses.Id = #GLOrgStructureConfigs.LineofBusinessId
AND CostCenterConfigs.Id = #GLOrgStructureConfigs.CostCenterId
WHERE SD.IsMigrated = 0
AND SD.R_CostCenterId IS NULL
AND SD.EntityType = 'CU';
INSERT INTO #ErrorLogs
SELECT SD.Id
, 'Error'
, 'Invalid CostCenterName : ' + ISNULL(SD.CostCenterName, 'NULL') + ' for Security Deposit {Id : ' + CONVERT(NVARCHAR, SD.Id) + '} with EntityType {' + SD.EntityType + '}'
FROM stgSecurityDeposit SD
WHERE SD.R_CostCenterId IS NULL
AND IsMigrated = 0
AND SD.EntityType = 'CU';
UPDATE stgSecurityDeposit
SET
R_InstrumentTypeId = InstrumentTypes.Id
FROM stgSecurityDeposit SD
INNER JOIN InstrumentTypes ON InstrumentTypes.Code = SD.InstrumentTypeCode
AND InstrumentTypes.IsActive = 1
WHERE SD.IsMigrated = 0
AND SD.R_InstrumentTypeId IS NULL
AND SD.EntityType = 'CU';
INSERT INTO #ErrorLogs
SELECT SD.Id
, 'Error'
, 'Invalid InstrumentTypeCode : ' + ISNULL(SD.InstrumentTypeCode, 'NULL') + ' for Security Deposit {Id : ' + CONVERT(NVARCHAR, SD.Id) + '} with EntityType {' + SD.EntityType + '}'
FROM stgSecurityDeposit SD
WHERE SD.R_InstrumentTypeId IS NULL
AND SD.IsMigrated = 0
AND SD.EntityType = 'CU';
UPDATE stgSecurityDeposit
SET
R_CurrencyId = Currencies.Id
FROM stgSecurityDeposit SD
LEFT JOIN CurrencyCodes ON CurrencyCodes.ISO = SD.CurrencyCode
LEFT JOIN Currencies ON Currencies.CurrencyCodeId = CurrencyCodes.Id
AND Currencies.IsActive = 1
WHERE SD.R_CurrencyId IS NULL
AND SD.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT SD.Id
, 'Error'
, 'Invalid CurrencyCode : ' + SD.CurrencyCode + ' for Security Deposit {Id : ' + CONVERT(NVARCHAR, SD.Id) + '}'
FROM stgSecurityDeposit SD
WHERE SD.R_CurrencyId IS NULL
AND IsMigrated = 0;
UPDATE stgSecurityDeposit
SET
R_RemitToId = RemitToes.Id
FROM stgSecurityDeposit SD
INNER JOIN LegalEntities ON SD.LegalEntityNumber = LegalEntities.LegalEntityNumber
AND LegalEntities.STATUS = 'Active'
INNER JOIN LegalEntityRemitToes ON LegalEntities.Id = LegalEntityRemitToes.LegalEntityId
INNER JOIN RemitToes ON SD.RemitToUniqueIdentifier = RemitToes.UniqueIdentifier
AND LegalEntityRemitToes.RemitToId = RemitToes.Id
AND RemitToes.IsActive = 1
WHERE SD.IsMigrated = 0
AND SD.R_RemitToId IS NULL;
INSERT INTO #ErrorLogs
SELECT SD.Id
, 'Error'
, 'Invalid RemitToUniqueIdentifier : ' + SD.RemitToUniqueIdentifier + ' for Security Deposit {Id : ' + CONVERT(NVARCHAR, SD.Id) + '} with LegalEntityNumber: ' + SD.LegalEntityNumber
FROM stgSecurityDeposit SD
WHERE SD.R_RemitToId IS NULL
AND IsMigrated = 0;
UPDATE stgSecurityDeposit
SET
R_ReceivableCodeId = ReceivableCodes.Id
FROM stgSecurityDeposit SD
INNER JOIN ReceivableCodes ON ReceivableCodes.Name = SD.ReceivableCodeName
AND ReceivableCodes.IsActive = 1
WHERE SD.IsMigrated = 0
AND SD.R_ReceivableCodeId IS NULL;
INSERT INTO #ErrorLogs
SELECT SD.Id
, 'Error'
, 'Invalid ReceivableCode : ' + SD.ReceivableCodeName + ' for Security Deposit {Id : ' + CONVERT(NVARCHAR, SD.Id) + '}'
FROM stgSecurityDeposit SD
WHERE SD.ReceivableCodeName IS NOT NULL
AND SD.R_ReceivableCodeId IS NULL
AND IsMigrated = 0;
UPDATE stgSecurityDeposit
SET
R_ReceiptGLTemplateId = GLTemplates.Id
FROM stgSecurityDeposit SD
INNER JOIN LegalEntities ON SD.LegalEntityNumber = LegalEntities.LegalEntityNumber
AND LegalEntities.STATUS = 'Active'
INNER JOIN GLTemplates ON GLTemplates.Name = SD.ReceiptGLTemplateName
AND GLTemplates.IsActive = 1
AND GLTemplates.GLConfigurationId = LegalEntities.GLConfigurationId
INNER JOIN GLTransactionTypes ON GLTemplates.GLTransactionTypeId = GLTransactionTypes.Id
AND GLTransactionTypes.Name = 'ReceiptNonCash'
WHERE SD.IsMigrated = 0
AND SD.R_ReceiptGLTemplateId IS NULL;
INSERT INTO #ErrorLogs
SELECT SD.Id
, 'Error'
, 'Invalid ReceiptGLTemplateName : ' + SD.ReceiptGLTemplateName + ' for Security Deposit {Id : ' + CONVERT(NVARCHAR, SD.Id) + '}'
FROM stgSecurityDeposit SD
WHERE SD.ReceiptGLTemplateName IS NOT NULL
AND SD.R_ReceiptGLTemplateId IS NULL
AND IsMigrated = 0;
SET @FailedRecords =
(
SELECT ISNULL(COUNT(DISTINCT StagingRootEntityId), 0)
FROM #ErrorLogs
);
MERGE stgProcessingLog AS ProcessingLog
USING
(
SELECT Id
FROM stgSecurityDeposit
WHERE IsMigrated = 0
AND Id NOT IN
(
SELECT StagingRootEntityId
FROM #ErrorLogs
)
) AS ProcessedSecurityDeposits
ON(ProcessingLog.StagingRootEntityId = ProcessedSecurityDeposits.Id
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
(ProcessedSecurityDeposits.Id
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
) AS ErrorSecurityDeposits
ON(ProcessingLog.StagingRootEntityId = ErrorSecurityDeposits.StagingRootEntityId
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
(ErrorSecurityDeposits.StagingRootEntityId
, @UserId
, @CreatedTime
, @ModuleIterationStatusId
)
OUTPUT Inserted.Id
, ErrorSecurityDeposits.StagingRootEntityId
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
JOIN #FailedProcessingLogs ON #ErrorLogs.StagingRootEntityId = #FailedProcessingLogs.SecurityDepositId;
DROP TABLE #ErrorLogs;
DROP TABLE #FailedProcessingLogs;
DROP TABLE #CreatedProcessingLogs;
DROP TABLE #LegalEntityLOB;
DROP TABLE #GLOrgStructureConfigs;
END;

GO

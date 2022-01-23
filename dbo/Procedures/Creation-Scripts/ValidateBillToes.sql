SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ValidateBillToes]
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
([Id]       BIGINT NOT NULL,
[BillToId] BIGINT NOT NULL
);
CREATE TABLE #CreatedProcessingLogs([Id] BIGINT NOT NULL);
SET @ProcessedRecords =
(
SELECT ISNULL(COUNT(Id), 0)
FROM stgBillTo
WHERE IsMigrated = 0
);
DECLARE @TaxDataSourceIsVertex NVARCHAR(10);
SELECT @TaxDataSourceIsVertex = Value
FROM GlobalParameters
WHERE Category = 'SalesTax'
AND Name = 'IsTaxSourceVertex';
UPDATE BillTo
SET
BillTo.R_EmailTemplateId = EmailTemplates.Id
FROM stgBillTo BillTo
JOIN EmailTemplates ON EmailTemplates.Name = BillTo.[PreACHNotificationEmailTemplateName]
JOIN EmailTemplateTypes ON EmailTemplateTypes.Id = EmailTemplates.EmailTemplateTypeId
WHERE BillTo.IsMigrated = 0
AND BillTo.IsFailed = 0
AND EmailTemplateTypes.Name = 'ACHPreNotification'
AND BillTo.IsPreACHNotification = 1
AND BillTo.[PreACHNotificationEmailTemplateName] IS NOT NULL;

INSERT INTO #ErrorLogs
(StagingRootEntityId
, Result
, Message
)
SELECT Id
, 'Error'
, 'ACHNotificationInvalid'
FROM stgBillTo BillTo
WHERE IsMigrated = 0
AND BillTo.IsFailed = 0
AND BillTo.[IsPreACHNotification] = 1
AND BillTo.[R_EmailTemplateId] IS NULL;

UPDATE BillTo
SET
BillTo.R_PostACHNotificationEmailTemplateId = EmailTemplates.Id
FROM stgBillTo BillTo
JOIN EmailTemplates ON EmailTemplates.Name = BillTo.[PostACHNotificationEmailTemplateName]
JOIN EmailTemplateTypes ON EmailTemplateTypes.Id = EmailTemplates.EmailTemplateTypeId
WHERE BillTo.IsMigrated = 0
AND BillTo.IsFailed = 0
AND EmailTemplateTypes.Name = 'ACHPostNotification'
AND BillTo.IsPostACHNotification = 1
AND BillTo.[PostACHNotificationEmailTemplateName] IS NOT NULL;

INSERT INTO #ErrorLogs
(StagingRootEntityId
, Result
, Message
)
SELECT Id
, 'Error'
, 'ACHPostNotificationInvalid'
FROM stgBillTo BillTo
WHERE IsMigrated = 0
AND BillTo.IsFailed = 0
AND BillTo.[IsPostACHNotification] = 1
AND BillTo.[R_PostACHNotificationEmailTemplateId] IS NULL;

UPDATE BillTo
SET
BillTo.R_ReturnACHNotificationEmailTemplateId = EmailTemplates.Id
FROM stgBillTo BillTo
JOIN EmailTemplates ON EmailTemplates.Name = BillTo.[ReturnACHNotificationEmailTemplateName]
JOIN EmailTemplateTypes ON EmailTemplateTypes.Id = EmailTemplates.EmailTemplateTypeId
WHERE BillTo.IsMigrated = 0
AND BillTo.IsFailed = 0
AND EmailTemplateTypes.Name = 'ACHReturnNotification'
AND BillTo.IsReturnACHNotification = 1
AND BillTo.[ReturnACHNotificationEmailTemplateName] IS NOT NULL;

INSERT INTO #ErrorLogs
(StagingRootEntityId
, Result
, Message
)
SELECT Id
, 'Error'
, 'ACHReturnNotificationInvalid'
FROM stgBillTo BillTo
WHERE IsMigrated = 0
AND BillTo.IsFailed = 0
AND BillTo.[IsReturnACHNotification] = 1
AND BillTo.[R_ReturnACHNotificationEmailTemplateId] IS NULL;

UPDATE BillTo
SET
BillTo.R_LanguageConfigId = LanguageConfigs.Id
FROM stgBillTo BillTo
JOIN LanguageConfigs ON LanguageConfigs.Name = BillTo.LanguageConfigName
WHERE BillTo.IsMigrated = 0
AND BillTo.IsFailed = 0
AND BillTo.LanguageConfigName IS NOT NULL;
INSERT INTO #ErrorLogs
(StagingRootEntityId
, Result
, Message
)
SELECT Id
, 'Error'
, 'LanguageInvalid'
FROM stgBillTo BillTo
WHERE IsMigrated = 0
AND BillTo.IsFailed = 0
AND BillTo.[R_LanguageConfigId] IS NULL;
UPDATE [BIP]
SET
[BIP].[R_BlendReceivableTypeId] = [RT].Id
FROM ReceivableTypes [RT]
JOIN stgBillToInvoiceParameter [BIP] ON [BIP].[BlendedReceivableType] = [RT].Name
AND [RT].Isactive = 1
JOIN stgBillTo BillTo ON [BillTo].Id = [BIP].BillToId
WHERE [BillTo].IsMigrated = 0
AND BillTo.IsFailed = 0
AND LEN([BIP].[BlendedReceivableType]) > 0;
UPDATE [BIP]
SET
[BIP].[R_ReceivableTypeLabelId] = [RTL].Id
FROM ReceivableTypeLabelConfigs [RTL]
JOIN stgBillToInvoiceParameter [BIP] ON [BIP].[ReceivableTypeLabel] = [RTL].Name
AND [RTL].isactive = 1
JOIN stgBillTo BillTo ON [BillTo].Id = [BIP].BillToId
WHERE [BillTo].IsMigrated = 0
AND BillTo.IsFailed = 0
AND LEN([BIP].[ReceivableTypeLabel]) > 0;
UPDATE [BIP]
SET
[BIP].[R_ReceivableTypeLanguageLabelId] = [RTL].Id
FROM ReceivableTypeLanguageLabels [RTL]
JOIN stgBillToInvoiceParameter [BIP] ON [BIP].[ReceivableTypeLanguageInvoiceLabel] = [RTL].InvoiceLabel
AND [RTL].isactive = 1
JOIN stgBillTo BillTo ON [BillTo].Id = [BIP].BillToId
WHERE [BillTo].IsMigrated = 0
AND BillTo.IsFailed = 0
AND LEN([BIP].[ReceivableTypeLanguageInvoiceLabel]) > 0;
UPDATE [BIF]
SET
[BIF].[R_InvoiceFormatlId] = [IF].Id
FROM InvoiceFormats [IF]
JOIN stgBillToInvoiceFormat [BIF] ON [BIF].[InvoiceFormatName] = [IF].Name
AND [IF].isactive = 1
JOIN stgBillTo BillTo ON [BillTo].Id = [BIF].BillToId
WHERE [BillTo].IsMigrated = 0
AND BillTo.IsFailed = 0
AND LEN([BIF].[InvoiceFormatName]) > 0;
UPDATE [BIF]
SET
[BIF].[R_InvoiceTypeLabellId] = [ILC].Id
FROM InvoiceTypeLabelConfigs [ILC]
JOIN stgBillToInvoiceFormat [BIF] ON [BIF].[InvoiceTypeLabel] = [ILC].Name
AND [ILC].IsActive = 1
JOIN InvoiceTypes [IT] ON [ILC].InvoiceTypeId = IT.Id
JOIN stgBillTo BillTo ON [BillTo].Id = [BIF].BillToId
WHERE [BillTo].IsMigrated = 0
AND BillTo.IsFailed = 0
AND LEN([BIF].[InvoiceTypeLabel]) > 0;
UPDATE [BIF]
SET
[BIF].[R_InvoiceEmailTemplateId] = EmailTemplates.Id
FROM stgBillToInvoiceFormat [BIF]
JOIN stgBillTo BillTo ON [BillTo].Id = [BIF].BillToId
JOIN EmailTemplates ON EmailTemplates.Name = [BIF].InvoiceEmailTemplateName
JOIN EmailTemplateTypes ON EmailTemplates.EmailTemplateTypeId = EmailTemplateTypes.Id
AND EmailTemplateTypes.Name = 'Invoice'
AND EmailTemplates.IsActive = 1
WHERE [BillTo].IsMigrated = 0
AND BillTo.IsFailed = 0;
UPDATE BillTo
SET
BillTo.R_LocationId = Locations.Id
FROM stgBillTo BillTo
JOIN Locations ON Locations.Code = BillTo.LocationCode
AND Locations.IsActive = 1
AND Locations.CustomerId = R_CustomerId
WHERE BillTo.IsMigrated = 0
AND BillTo.IsFailed = 0
AND BillTo.LocationCode IS NOT NULL;
UPDATE stgBillTo
SET
stgBillTo.R_JurisdictionId = Jurisdictions.Id
, stgBillTo.R_JurisdictionDetailId = JurisdictionDetails.Id
FROM Jurisdictions
JOIN States ON States.Id = Jurisdictions.StateId
JOIN Countries ON Countries.Id = Jurisdictions.CountryId
JOIN Counties ON Counties.Id = Jurisdictions.CountyId
JOIN Cities ON Cities.Id = Jurisdictions.CityId
JOIN JurisdictionDetails ON JurisdictionDetails.JurisdictionId = Jurisdictions.Id
JOIN stgBillTo BillTo ON States.ShortName = BillTo.JurisdictionStateShortName
AND Countries.ShortName = BillTo.JurisdictionCountryShortName
AND States.ShortName = BillTo.JurisdictionStateShortName
AND Counties.Name = BillTo.JurisdictionCountyName
AND Jurisdictions.IsActive = 1
WHERE BillTo.IsMigrated = 0
AND BillTo.IsFailed = 0
AND BillTo.R_JurisdictionId IS NULL
AND BillTo.LocationCode IS NOT NULL
AND BillTo.JurisdictionCountryShortName IS NOT NULL
AND BillTo.JurisdictionStateShortName IS NOT NULL
AND BillTo.JurisdictionCityName IS NOT NULL
AND BillTo.JurisdictionCityName IS NOT NULL
AND @TaxDataSourceIsVertex != 'True';
UPDATE BillTo
SET
TaxAreaId = Locations.TaxAreaId
, UpfrontTaxMode = Locations.UpfrontTaxMode
, TaxAreaVerifiedTillDate = Locations.TaxAreaVerifiedTillDate
, TaxBasisType = Locations.TaxBasisType
, R_JurisdictionId = CASE
WHEN R_LocationId IS NOT NULL
THEN Locations.JurisdictionId
END
, R_JurisdictionDetailId = CASE
WHEN R_LocationId IS NOT NULL
THEN Locations.JurisdictionDetailId
END
FROM stgBillTo BillTo
JOIN Locations ON Locations.Id = R_LocationId
WHERE BillTo.IsMigrated = 0
AND BillTo.IsFailed = 0;
INSERT INTO #ErrorLogs
(StagingRootEntityId
, Result
, Message
)
SELECT [BillToInvoiceParameter].BillToId
, 'Error'
, 'InvoiceParam-BlendedReceivableTypeInvalid'
FROM stgBillToInvoiceParameter BillToInvoiceParameter
JOIN stgBillTo BillTo ON BillTo.Id = [BillToInvoiceParameter].BillToId
WHERE BillTo.IsMigrated = 0
AND BillTo.IsFailed = 0
AND LEN([BlendedReceivableType]) > 0
AND [BillToInvoiceParameter].[R_BlendReceivableTypeId] IS NULL;
INSERT INTO #ErrorLogs
(StagingRootEntityId
, Result
, Message
)
SELECT [BillToInvoiceParameter].BillToId
, 'Error'
, 'InvoiceParam-ReceivabletypelabelInvalid'
FROM stgBillToInvoiceParameter BillToInvoiceParameter
JOIN stgBillTo BillTo ON BillTo.Id = [BillToInvoiceParameter].BillToId
WHERE BillTo.IsMigrated = 0
AND BillTo.IsFailed = 0
AND LEN([ReceivableTypeLabel]) > 0
AND [BillToInvoiceParameter].[R_ReceivableTypeLabelId] IS NULL;
INSERT INTO #ErrorLogs
(StagingRootEntityId
, Result
, Message
)
SELECT [BillToInvoiceParameter].BillToId
, 'Error'
, 'InvoiceParam-LanguageInvoiceLabelInvalid'
FROM stgBillToInvoiceParameter BillToInvoiceParameter
JOIN stgBillTo BillTo ON BillTo.Id = [BillToInvoiceParameter].BillToId
WHERE BillTo.IsMigrated = 0
AND BillTo.IsFailed = 0
AND LEN([ReceivableTypeLanguageInvoiceLabel]) > 0
AND [BillToInvoiceParameter].[R_ReceivableTypeLanguageLabelId] IS NULL;
--Invoice Format validation
INSERT INTO #ErrorLogs
(StagingRootEntityId
, Result
, Message
)
SELECT [BillToInvoiceFormat].BillToId
, 'Error'
, 'InvoiceFormat-FormatNameInvalid'
FROM stgBillToInvoiceFormat BillToInvoiceFormat
JOIN stgBillTo BillTo ON BillTo.Id = [BillToInvoiceFormat].BillToId
WHERE BillTo.IsMigrated = 0
AND BillTo.IsFailed = 0
AND LEN([BillToInvoiceFormat].[InvoiceFormatName]) > 0
AND [BillToInvoiceFormat].[R_InvoiceFormatlId] IS NULL;
INSERT INTO #ErrorLogs
(StagingRootEntityId
, Result
, Message
)
SELECT [BillToInvoiceFormat].BillToId
, 'Error'
, 'InvoiceFormat-TypeLabelInvalid'
FROM stgBillToInvoiceFormat BillToInvoiceFormat
JOIN stgBillTo BillTo ON BillTo.Id = [BillToInvoiceFormat].BillToId
WHERE BillTo.IsMigrated = 0
AND BillTo.IsFailed = 0
AND LEN([BillToInvoiceFormat].[InvoiceTypeLabel]) > 0
AND [BillToInvoiceFormat].[R_InvoiceTypeLabellId] IS NULL;
INSERT INTO #ErrorLogs
(StagingRootEntityId
, Result
, Message
)
SELECT BillTo.Id
, 'Error'
, 'BillTo-UpFrontTaxMode should be none or unknown'
FROM stgBillTo BillTo
WHERE BillTo.IsMigrated = 0
AND R_LocationId IS NULL
AND LocationCode IS NULL
AND (BillTo.TaxBasisType = '_'
OR BillTo.TaxBasisType = 'Stream')
AND (BillTo.UpfrontTaxMode != '_'
OR BillTo.UpfrontTaxMode != 'None')
AND @TaxDataSourceIsVertex != 'True';
INSERT INTO #ErrorLogs
(StagingRootEntityId
, Result
, Message
)
SELECT BillTo.Id
, 'Error'
, 'BillTo- LocationCode Invalid'
FROM stgBillTo BillTo
WHERE BillTo.IsMigrated = 0
AND R_LocationId IS NULL
AND LocationCode IS NOT NULL;
INSERT INTO #ErrorLogs
(StagingRootEntityId
, Result
, Message
)
SELECT BillTo.Id
, 'Error'
, 'BillTo- Jurisdication Details Not Required'
FROM stgBillTo BillTo
WHERE BillTo.IsMigrated = 0
AND BillTo.JurisdictionCountryShortName IS NOT NULL
AND R_LocationId IS NOT NULL
AND BillTo.JurisdictionCityName IS NOT NULL
AND BillTo.JurisdictionCountryShortName IS NOT NULL;
--BillTo StatementInvoiceFormat Conditional mandatory Validation
INSERT INTO #ErrorLogs
(StagingRootEntityId
, Result
, Message
)
SELECT BillTo.Id
, 'Error'
, 'BillTo- StatementInvoiceFormat is Required when GenerateStatementInvoice is true'
FROM stgBillTo BillTo
WHERE BillTo.IsMigrated = 0
AND BillTo.IsFailed=0
AND BillTo.StatementInvoiceFormat IS NULL 
AND BillTo.GenerateStatementInvoice=1;
INSERT INTO #ErrorLogs
(StagingRootEntityId
, Result
, Message
)
SELECT BillTo.Id
, 'Error'
, 'BillTo- Jurisdication Details Invalid'
FROM stgBillTo BillTo
WHERE BillTo.IsMigrated = 0
AND BillTo.R_JurisdictionId IS NULL
AND BillTo.JurisdictionCountryShortName IS NOT NULL
AND R_LocationId IS NULL
AND BillTo.JurisdictionCityName IS NOT NULL
AND BillTo.JurisdictionCountryShortName IS NOT NULL
AND @TaxDataSourceIsVertex = 'False';
INSERT INTO #ErrorLogs
(StagingRootEntityId
, Result
, Message
)
SELECT BillTo.Id
, 'Error'
, 'BillToInvoiceFormat - InvoiceEmailTemplateName Invalid'
FROM stgBillTo BillTo
JOIN stgBillToInvoiceFormat BillToInvoiceFormat ON BillTo.Id = BillToInvoiceFormat.BillToId
WHERE IsMigrated = 0
AND BillTo.IsFailed = 0
AND BillToInvoiceFormat.[R_InvoiceEmailTemplateId] IS NULL
AND BillToInvoiceFormat.InvoiceEmailTemplateName IS NOT NULL;
INSERT INTO #ErrorLogs
(StagingRootEntityId
, Result
, Message
)
SELECT Id
, 'Error'
, 'Tax Area Verified Till Date should not be greater than System Date'
FROM stgBillTo BillTo
WHERE IsMigrated = 0
AND BillTo.IsFailed = 0
AND BillTo.[TaxAreaVerifiedTillDate] >= CONVERT(DATE, @CreatedTime);
INSERT INTO #ErrorLogs
(StagingRootEntityId
, Result
, Message
)
SELECT BillTo.Id
, 'Error'
, 'IncludeInInvoice cannot be false for Attributes Amount and InvoiceTotal'
FROM stgBillTo BillTo
JOIN stgBillToInvoiceBodyDynamicContent BI ON BillTo.Id = BI.BillToId
WHERE IsMigrated = 0
AND BillTo.IsFailed = 0
AND ((BI.AttributeName = 'Amount'
AND BI.IncludeInInvoice = 0)
OR (BI.AttributeName = 'InvoiceTotal'
AND BI.IncludeInInvoice = 0));
SET @FailedRecords =
(
SELECT ISNULL(COUNT(DISTINCT StagingRootEntityId), 0)
FROM #ErrorLogs
);
MERGE stgProcessingLog AS ProcessingLog
USING
(
SELECT Id
FROM stgBillTo
WHERE IsMigrated = 0
AND Id NOT IN
(
SELECT StagingRootEntityId
FROM #ErrorLogs
)
) AS ProcessedBillTos
ON(ProcessingLog.StagingRootEntityId = ProcessedBillTos.Id
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
(ProcessedBillTos.Id
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
) AS ErrorBillTos
ON(ProcessingLog.StagingRootEntityId = ErrorBillTos.StagingRootEntityId
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
(ErrorBillTos.StagingRootEntityId
, @UserId
, @CreatedTime
, @ModuleIterationStatusId
)
OUTPUT Inserted.Id
, ErrorBillTos.StagingRootEntityId
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
JOIN #FailedProcessingLogs ON #ErrorLogs.StagingRootEntityId = #FailedProcessingLogs.BillToId;
DROP TABLE #ErrorLogs;
DROP TABLE #FailedProcessingLogs;
DROP TABLE #CreatedProcessingLogs;
END;

GO

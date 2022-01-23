SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ValidateCreditProfiles]
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
([Id]               BIGINT NOT NULL,
[CreditProfileId] BIGINT NOT NULL
);
CREATE TABLE #CreatedProcessingLogs([Id] BIGINT NOT NULL);
SET @ProcessedRecords =
(
SELECT ISNULL(COUNT(Id), 0)
FROM dbo.stgCreditProfile
WHERE IsMigrated = 0
);
INSERT INTO #ErrorLogs
SELECT DISTINCT
cp.Id
, 'Error'
, ('Invalid legal entity number for credit profile number {' + cp.Number + '}') AS Message
FROM stgCreditProfile cp
LEFT JOIN dbo.LegalEntities le ON cp.LegalEntityNumber = le.LegalEntityNumber
AND le.STATUS = 'Active'
WHERE cp.LegalEntityNumber IS NOT NULL
AND IsMigrated = 0
AND le.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
cp.Id
, 'Error'
, ('Invalid line of business name for credit profile number {' + cp.Number + '}') AS Message
FROM stgCreditProfile cp
LEFT JOIN dbo.LineofBusinesses lb ON cp.LineOfBusinessName = lb.Name
AND lb.IsActive = 1
WHERE cp.LineOfBusinessName IS NOT NULL
AND IsMigrated = 0
AND lb.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
cp.Id
, 'Error'
, ('Invalid cost center for credit profile number {' + cp.Number + '}') AS Message
FROM stgCreditProfile cp
LEFT JOIN dbo.CostCenterConfigs ccc ON cp.CostCenter = ccc.CostCenter
AND ccc.IsActive = 1
WHERE cp.LegalEntityNumber IS NOT NULL
AND IsMigrated = 0
AND ccc.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
cp.Id
, 'Error'
, ('Invalid origination source type for credit profile number {' + cp.Number + '}') AS Message
FROM stgCreditProfile cp
LEFT JOIN dbo.OriginationSourceTypes ost ON cp.OriginationSourceType = ost.Name
AND ost.IsActive = 1
WHERE cp.LegalEntityNumber IS NOT NULL
AND IsMigrated = 0
AND ost.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
cp.Id
, 'Error'
, ('Invalid product and service type config name for credit profile number {' + cp.Number + '}') AS Message
FROM stgCreditProfile cp
LEFT JOIN dbo.ProductAndServiceTypeConfigs pastc ON cp.ProductAndServiceTypeConfigName = pastc.ProductAndServiceTypeCode
WHERE cp.LegalEntityNumber IS NOT NULL
AND IsMigrated = 0
AND pastc.Id IS NULL
AND LTRIM(RTRIM(ISNULL(cp.ProductAndServiceTypeConfigName,'')))<>''
INSERT INTO #ErrorLogs
SELECT DISTINCT
cp.Id
, 'Error'
, ('Invalid currency for credit profile number {' + cp.Number + '}') AS Message
FROM stgCreditProfile cp
LEFT JOIN dbo.CurrencyCodes cc ON cp.Currency = cc.ISO
LEFT JOIN dbo.Currencies c ON cc.Id = c.CurrencyCodeId
AND cc.IsActive = 1
AND c.IsActive = 1
WHERE cp.Currency IS NOT NULL
AND IsMigrated = 0
AND c.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
cp.Id
, 'Error'
, ('Invalid acquired portfolio for credit profile number {' + cp.Number + '}') AS Message
FROM stgCreditProfile cp
LEFT JOIN dbo.AcquiredPortfolios ap ON cp.AcquiredPortfolio = ap.Name
WHERE cp.AcquiredPortfolio IS NOT NULL
AND IsMigrated = 0
AND ap.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
cp.Id
, 'Error'
, ('Invalid fee type for credit profile additional charge with credit profile number {' + cp.Number + '}') AS Message
FROM stgCreditProfile cp
INNER JOIN dbo.stgCreditProfileAdditionalCharge cpac ON cp.Id = cpac.CreditProfileId
LEFT JOIN dbo.FeeTypeConfigs ftc ON ftc.Name = cpac.FeeName
WHERE cpac.FeeName IS NOT NULL
AND IsMigrated = 0
AND ftc.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
cp.Id
, 'Error'
, ('Invalid receivable code name for credit profile additional charge with credit profile number {' + cp.Number + '}') AS Message
FROM stgCreditProfile cp
INNER JOIN dbo.stgCreditProfileAdditionalCharge cpac ON cp.Id = cpac.CreditProfileId
LEFT JOIN dbo.ReceivableCodes rc ON rc.Name = cpac.ReceivableCodeName
AND rc.IsActive = 1
WHERE cpac.ReceivableCodeName IS NOT NULL
AND IsMigrated = 0
AND rc.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
cp.Id
, 'Error'
, ('Invalid GL template name for credit profile additional charge with credit profile number {' + cp.Number + '}') AS Message
FROM stgCreditProfile cp
INNER JOIN dbo.stgCreditProfileAdditionalCharge cpac ON cp.Id = cpac.CreditProfileId
LEFT JOIN dbo.GLTemplates g ON g.Name = cpac.GLTemplateName
AND g.IsActive = 1
WHERE cpac.GLTemplateName IS NOT NULL
AND IsMigrated = 0
AND g.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
cp.Id
, 'Error'
, ('Invalid deal type name for credit approved structure with credit profile number {' + cp.Number + '}') AS Message
FROM stgCreditProfile cp
INNER JOIN dbo.stgCreditApprovedStructure cas ON cp.Id = cas.CreditProfileId
LEFT JOIN dbo.DealTypes dt ON dt.ProductType = cas.DealTypeName
AND dt.IsLoan = 0
AND (dt.Name != 'Tax Exempt Lease'
AND dt.Name != 'Leveraged Lease'
AND dt.Name != 'Tax Exempt Loan')
AND dt.IsActive = 1
WHERE cas.DealTypeName IS NOT NULL
AND IsMigrated = 0
AND dt.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
cp.Id
, 'Error'
, ('Invalid deal product type name for credit approved structure with credit profile number {' + cp.Number + '}') AS Message
FROM stgCreditProfile cp
INNER JOIN dbo.stgCreditApprovedStructure cas ON cp.Id = cas.CreditProfileId
INNER JOIN dbo.DealTypes dt ON dt.ProductType = cas.DealTypeName
AND dt.IsActive = 1
LEFT JOIN dbo.DealProductTypes dpt ON dpt.Name = cas.DealProductTypeName
AND dpt.IsActive = 1
WHERE cas.DealTypeName IS NOT NULL
AND IsMigrated = 0
AND dpt.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
cp.Id
, 'Error'
, ('Invalid program indicator code for credit approved structure with credit profile number {' + cp.Number + '}') AS Message
FROM stgCreditProfile cp
INNER JOIN dbo.stgCreditApprovedStructure cas ON cp.Id = cas.CreditProfileId
LEFT JOIN dbo.ProgramIndicatorConfigs pic ON pic.ProgramIndicatorCode = cas.ProgramIndicatorConfigName
WHERE cas.ProgramIndicatorConfigName IS NOT NULL
AND IsMigrated = 0
AND pic.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
cp.Id
, 'Error'
, ('Invalid progress funding base index for credit approved structure with credit profile number {' + cp.Number + '}') AS Message
FROM stgCreditProfile cp
INNER JOIN dbo.stgCreditApprovedStructure cas ON cp.Id = cas.CreditProfileId
LEFT JOIN dbo.FloatRateIndexes fri ON fri.Name = cas.ProgressFundingBaseIndex
AND fri.IsActive = 1
WHERE cas.ProgressFundingBaseIndex IS NOT NULL
AND IsMigrated = 0
AND fri.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
cp.Id
, 'Error'
, ('Invalid pricing base index for credit approved structure with credit profile number {' + cp.Number + '}') AS Message
FROM stgCreditProfile cp
INNER JOIN dbo.stgCreditApprovedStructure cas ON cp.Id = cas.CreditProfileId
LEFT JOIN dbo.FloatRateIndexes fri ON fri.Name = cas.PricingBaseIndex
AND fri.IsActive = 1
WHERE cas.PricingBaseIndex IS NOT NULL
AND IsMigrated = 0
AND fri.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
cp.Id
, 'Error'
, ('Invalid low side override reason code for credit approved structure with credit profile number {' + cp.Number + '}') AS Message
FROM stgCreditProfile cp
INNER JOIN dbo.stgCreditDecision cd ON cd.CreditProfileId = cp.Id
LEFT JOIN dbo.LowSideOverrideReasonCodes lsorc ON cd.LowSideOverrideReasonCode = lsorc.Code
AND lsorc.IsActive = 1
WHERE cd.LowSideOverrideReasonCode IS NOT NULL
AND IsMigrated = 0
AND lsorc.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
cp.Id
, 'Error'
,CASE WHEN ( cas.PaymentFrequency = 'Monthly' OR cas.PaymentFrequency = 'Quarterly' OR cas.PaymentFrequency = 'HalfYearly' OR cas.PaymentFrequency = 'Yearly')
	     THEN 'Compounding Frequency must be either monthly or equal to payment frequency for [CreditProfile Number] : [' + cp.Number + ' ]'
		 ELSE
		   'Compounding Frequency must be monthly for [CreditProfile Number] : [' + cp.Number + ' ]' 
		 END AS Message  
FROM stgCreditProfile cp
INNER JOIN dbo.stgCreditApprovedStructure cas ON cp.Id = cas.CreditProfileId 
WHERE cas.CompoundingFrequency <> (CASE WHEN cas.CompoundingFrequency = 'Monthly' 
									   THEN cas.CompoundingFrequency
									   WHEN ( cas.PaymentFrequency = 'Monthly' OR cas.PaymentFrequency = 'Quarterly' OR cas.PaymentFrequency = 'HalfYearly' OR cas.PaymentFrequency = 'Yearly' OR cas.PaymentFrequency = 'Irregular')
                                       THEN    cas.PaymentFrequency 
		                               ELSE  'Monthly' END 
								 )
AND IsMigrated = 0;

INSERT INTO #ErrorLogs
SELECT DISTINCT
cp.Id
, 'Error'
,'For the particular Credit Approved Structure ('+cas.Number+') both Rent Amount and Rent Factor is provided.Either only Rent Amount or Rent Factor should be provided.'
FROM stgCreditProfile cp
INNER JOIN dbo.stgCreditApprovedStructure cas ON cp.Id = cas.CreditProfileId 
WHERE  IsMigrated = 0 and cas.RentFactor <> 0 and cas.Rent_Amount <> 0;

INSERT INTO #ErrorLogs
SELECT DISTINCT
cp.Id
, 'Error'
,'For the particular Credit Approved Structure ('+cas.Number+') both Inception Payment Amount and Inception Rent Factor is provided.Either only Inception Payment Amount or Inception Rent Factor should be provided.'

FROM stgCreditProfile cp
INNER JOIN dbo.stgCreditApprovedStructure cas ON cp.Id = cas.CreditProfileId 
WHERE  IsMigrated = 0 and cas.InceptionRentFactor <> 0 and cas.InceptionPayment_Amount <> 0;

INSERT INTO #ErrorLogs
SELECT DISTINCT
cp.Id
, 'Error'
,'For the particular Credit Approved Structure ('+cas.Number+') both Customer Expected Residual Amount and Customer Expected Residual Factor is provided.Either only Customer Expected Residual Amount or Customer Expected Residual Factor should be provided.'
FROM stgCreditProfile cp
INNER JOIN dbo.stgCreditApprovedStructure cas ON cp.Id = cas.CreditProfileId 
WHERE  IsMigrated = 0 and cas.CustomerExpectedResidualFactor <> 0 and cas.CustomerExpectedResidual_Amount <> 0;

INSERT INTO #ErrorLogs
SELECT DISTINCT
cp.Id
, 'Error'
,'For the particular Credit Approved Structure ('+cas.Number+') both Guaranteed Residual Amount and Guaranteed Residual Factor is provided.Either only Guaranteed Residual Amount or Guaranteed Residual Factor  should be provided.'
FROM stgCreditProfile cp
INNER JOIN dbo.stgCreditApprovedStructure cas ON cp.Id = cas.CreditProfileId 
WHERE  IsMigrated = 0 and cas.GuaranteedResidualFactor <> 0 and cas.GuaranteedResidual_Amount <> 0;

INSERT INTO #ErrorLogs
SELECT DISTINCT
cp.Id
, 'Error'
,'For the particular Credit Profile EquipmentDetail ('+STR(ced.Id)+') both Rent Amount and Rent Factor is provided.Either only Rent Amount or Rent Factor should be provided.'
FROM stgCreditProfile cp
INNER JOIN dbo.stgCreditApprovedStructure cas ON cp.Id = cas.CreditProfileId 
INNER JOIN dbo.stgCreditProfileEquipmentDetail ced ON ced.CreditApprovedStructureId = cas.Id
WHERE  IsMigrated = 0 and ced.RentFactor <> 0 and ced.Rent_Amount <> 0;

INSERT INTO #ErrorLogs
SELECT DISTINCT
cp.Id
, 'Error'
,'For the particular Credit Profile EquipmentDetail ('+STR(ced.Id)+') both Customer Expected Residual Amount and Customer Expected Residual Factor is provided.Either only Customer Expected Residual Amount or Customer Expected Residual Factor should be provided.'
FROM stgCreditProfile cp
INNER JOIN dbo.stgCreditApprovedStructure cas ON cp.Id = cas.CreditProfileId 
INNER JOIN dbo.stgCreditProfileEquipmentDetail ced ON ced.CreditApprovedStructureId = cas.Id
WHERE  IsMigrated = 0 and ced.CustomerExpectedResidualFactor <> 0 and ced.CustomerExpectedResidual_Amount <> 0;

INSERT INTO #ErrorLogs
SELECT DISTINCT
cp.Id
, 'Error'
,'For the particular Credit Profile EquipmentDetail ('+STR(ced.Id)+') both Interim Rent Amount and Interim Rent Factor is provided.Either only Interim Rent Amount or Interim Rent Factor should be provided.'
FROM stgCreditProfile cp
INNER JOIN dbo.stgCreditApprovedStructure cas ON cp.Id = cas.CreditProfileId 
INNER JOIN dbo.stgCreditProfileEquipmentDetail ced ON ced.CreditApprovedStructureId = cas.Id
WHERE  IsMigrated = 0 and ced.InterimRentFactor <> 0 and ced.InterimRent_Amount <> 0;

INSERT INTO #ErrorLogs
SELECT DISTINCT
cp.Id
, 'Error'
,'For the particular Credit Profile EquipmentDetail ('+STR(ced.Id)+') both Guaranteed Residual Amount and Guaranteed Residual Factor is provided.Either only Guaranteed Residual Amount or Guaranteed Residual Factor  should be provided.'
FROM stgCreditProfile cp
INNER JOIN dbo.stgCreditApprovedStructure cas ON cp.Id = cas.CreditProfileId
INNER JOIN dbo.stgCreditProfileEquipmentDetail ced ON ced.CreditApprovedStructureId = cas.Id
WHERE  IsMigrated = 0 and  ced.GuaranteedResidualFactor <> 0 and ced.GuaranteedResidual_Amount <> 0;

INSERT INTO #ErrorLogs
SELECT DISTINCT
cp.Id
, 'Error'
,'For the particular Credit Decision ('+STR(cd.Id)+') both Tolerance Amount and Tolerance Factor is provided.Either only Tolerance Amount or Tolerance Factor should be provided.'
FROM stgCreditProfile cp
INNER JOIN dbo.stgCreditDecision cd ON cp.Id = cd.CreditProfileId 
WHERE  IsMigrated = 0 and cd.ToleranceFactor <> 0 and cd.ToleranceAmount_Amount <> 0;

SET @FailedRecords =
(
SELECT ISNULL(COUNT(DISTINCT StagingRootEntityId), 0)
FROM #ErrorLogs
);
MERGE stgProcessingLog AS ProcessingLog
USING
(
SELECT Id
FROM stgCreditProfile
WHERE IsMigrated = 0
AND Id NOT IN
(
SELECT StagingRootEntityId
FROM #ErrorLogs
)
) AS ProcessedCreditProfiles
ON(ProcessingLog.StagingRootEntityId = ProcessedCreditProfiles.Id
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
(ProcessedCreditProfiles.Id
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
) AS ErrorCreditProfiles
ON(ProcessingLog.StagingRootEntityId = ErrorCreditProfiles.StagingRootEntityId
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
(ErrorCreditProfiles.StagingRootEntityId
, @UserId
, @CreatedTime
, @ModuleIterationStatusId
)
OUTPUT Inserted.Id
, ErrorCreditProfiles.StagingRootEntityId
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
JOIN #FailedProcessingLogs ON #ErrorLogs.StagingRootEntityId = #FailedProcessingLogs.CreditProfileId;
DROP TABLE #ErrorLogs;
DROP TABLE #FailedProcessingLogs;
DROP TABLE #CreatedProcessingLogs;
END;

GO

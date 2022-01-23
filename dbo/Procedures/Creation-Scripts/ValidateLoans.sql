SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ValidateLoans]
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
(Id     BIGINT NOT NULL,
LoanId BIGINT NOT NULL
);
CREATE TABLE #CreatedProcessingLogs([Id] BIGINT NOT NULL);
SET @ProcessedRecords =
(
SELECT ISNULL(COUNT(Id), 0)
FROM stgLoan
WHERE IsMigrated = 0
);
INSERT INTO #ErrorLogs
SELECT DISTINCT
l.Id
, 'Error'
, ('Loan: Invalid Line of business for [SequenceNumber,LineOfBusinessName] :[' + l.SequenceNumber + ',' + ISNULL(l.LineOfBusinessName, 'NULL') + ']')
FROM stgLoan l
LEFT JOIN dbo.LineofBusinesses lb ON l.LineOfBusinessName = lb.Name
AND lb.IsActive = 1
WHERE l.IsMigrated = 0
AND l.LineofBusinessName IS NOT NULL
AND lb.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
l.Id
, 'Error'
, ('Loan: Invalid legal entity number for [SequenceNumber,LegalEntityNumber] :[' + l.SequenceNumber + ',' + ISNULL(l.LegalEntityNumber, 'NULL') + ']')
FROM stgLoan l
LEFT JOIN dbo.LegalEntities le ON le.LegalEntityNumber = l.LegalEntityNumber
AND le.STATUS = 'Active'
WHERE l.IsMigrated = 0
AND l.LegalEntityNumber IS NOT NULL
AND le.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
l.Id
, 'Error'
, ('Loan: Invalid currency code for [SequenceNumber,CurrencyCode] :[' + l.SequenceNumber + ',' + ISNULL(l.CurrencyCode, 'NULL') + ']')
FROM stgLoan l
LEFT JOIN dbo.CurrencyCodes cc ON cc.ISO = l.CurrencyCode
AND cc.IsActive = 1
LEFT JOIN dbo.Currencies c ON cc.Id = c.CurrencyCodeId
AND C.IsActive = 1
WHERE l.IsMigrated = 0
AND l.CurrencyCode IS NOT NULL
AND c.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
l.Id
, 'Error'
, ('Loan: Invalid language name for [SequenceNumber,LanguageName] :[' + l.SequenceNumber + ',' + ISNULL(l.Language, 'NULL') + ']')
FROM stgLoan l
LEFT JOIN dbo.LanguageConfigs lc ON l.Language = lc.Name
AND lc.IsActive = 1
WHERE l.IsMigrated = 0
AND l.Language IS NOT NULL
AND lc.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
l.Id
, 'Error'
, ('Loan: Invalid RemitTo UniqueIdentifier for [SequenceNumber,RemitToUniqueIdentifier] :[' + l.SequenceNumber + ',' + ISNULL(l.RemitToUniqueIdentifier, 'NULL') + ']')
FROM stgLoan l
LEFT JOIN dbo.RemitToes rt ON l.RemitToUniqueIdentifier = rt.UniqueIdentifier
WHERE l.IsMigrated = 0
AND l.RemitToUniqueIdentifier IS NOT NULL
AND rt.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
l.Id
, 'Error'
, ('Loan: Invalid deal type name for [SequenceNumber,DealTypeName] :[' + l.SequenceNumber + ',' + ISNULL(l.DealTypeName, 'NULL') + ']')
FROM stgLoan l
LEFT JOIN dbo.DealTypes dt ON dt.ProductType = l.DealTypeName
AND dt.IsActive = 1
WHERE l.IsMigrated = 0
AND l.DealTypeName IS NOT NULL
AND dt.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
l.Id
, 'Error'
, ('Loan: Invalid deal product type name for [SequenceNumber,DealProductTypeName] :[' + l.SequenceNumber + ',' + ISNULL(l.DealProductTypeName, 'NULL') + ']')
FROM stgLoan l
LEFT JOIN dbo.DealTypes dt ON dt.ProductType = l.DealTypeName
AND dt.IsActive = 1
LEFT JOIN dbo.DealProductTypes dpt ON dpt.Name = l.DealProductTypeName
AND dt.Id = dpt.DealTypeId
WHERE l.IsMigrated = 0
AND l.DealProductTypeName IS NOT NULL
AND dpt.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
l.Id
, 'Error'
, ('Loan: Invalid receipt hierarchy template name for [SequenceNumber,ReceiptHierarchyTemplateName] :[' + l.SequenceNumber + ',' + ISNULL(l.ReceiptHierarchyTemplateName, 'NULL') + ']')
FROM stgLoan l
LEFT JOIN dbo.ReceiptHierarchyTemplates rht ON l.ReceiptHierarchyTemplateName = rht.Name
AND rht.IsActive = 1
WHERE l.IsMigrated = 0
AND l.ReceiptHierarchyTemplateName IS NOT NULL
AND rht.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
l.Id
, 'Error'
, ('Loan: Invalid cost center name for [SequenceNumber,CostCenterName] :[' + l.SequenceNumber + ',' + ISNULL(l.CostCenterName, 'NULL') + ']')
FROM stgLoan l
LEFT JOIN dbo.CostCenterConfigs ccc ON l.CostCenterName = ccc.CostCenter
AND ccc.IsActive = 1
WHERE l.IsMigrated = 0
AND l.CostCenterName IS NOT NULL
AND ccc.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
l.Id
, 'Error'
, ('Loan: Invalid program indicator config name for [SequenceNumber,ProgramIndicatorConfigName] :[' + l.SequenceNumber + ',' + ISNULL(l.ProgramIndicatorConfigName, 'NULL') + ']')
FROM stgLoan l
LEFT JOIN dbo.ProgramIndicatorConfigs pic ON l.ProgramIndicatorConfigName = pic.ProgramIndicatorCode
WHERE l.IsMigrated = 0
AND l.ProgramIndicatorConfigName IS NOT NULL
AND pic.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
l.Id
, 'Error'
, ('Loan: Invalid product and service type config code for [SequenceNumber,ProductAndServiceTypeConfigCode] :[' + l.SequenceNumber + ',' + ISNULL(l.ProductAndServiceTypeConfigCode, 'NULL') + ']')
FROM stgLoan l
LEFT JOIN dbo.ProductAndServiceTypeConfigs pastc ON l.ProductAndServiceTypeConfigCode = pastc.ProductAndServiceTypeCode
WHERE l.IsMigrated = 0
AND l.ProductAndServiceTypeConfigCode IS NOT NULL
AND pastc.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
l.Id
, 'Error'
, ('LoanLateFee: Invalid late fee template name for [SequenceNumber,LateFeeTemplateName] :[' + l.SequenceNumber + ',' + ISNULL(llf.LateFeeTemplateName, 'NULL') + ']')
FROM stgLoan l
INNER JOIN dbo.stgLoanLateFee llf ON l.Id = llf.Id
LEFT JOIN dbo.LateFeeTemplates lft ON llf.LateFeeTemplateName = lft.Name
AND lft.IsActive = 1
WHERE l.IsMigrated = 0
AND llf.LateFeeTemplateName IS NOT NULL
AND lft.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
l.Id
, 'Error'
, ('LoanBilling: Invalid pre notification email template name for [SequenceNumber,PreNotificationEmailTemplate] :[' + l.SequenceNumber + ',' + ISNULL(lb.PreNotificationEmailTemplate, 'NULL') + ']')
FROM stgLoan l
INNER JOIN dbo.stgLoanBilling lb ON l.Id = lb.Id
LEFT JOIN dbo.EmailTemplates et ON lb.PreNotificationEmailTemplate = et.Name
AND et.IsActive = 1
WHERE l.IsMigrated = 0
AND lb.PreNotificationEmailTemplate IS NOT NULL
AND et.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
l.Id
, 'Error'
, ('LoanBilling: Invalid receipt legal entity number for [SequenceNumber,ReceiptLegalEntityNumber] :[' + l.SequenceNumber + ',' + ISNULL(lb.ReceiptLegalEntityNumber, 'NULL') + ']')
FROM stgLoan l
INNER JOIN dbo.stgLoanBilling lb ON l.Id = lb.Id
LEFT JOIN dbo.LegalEntities le ON le.LegalEntityNumber = lb.ReceiptLegalEntityNumber
AND le.STATUS = 'Active'
WHERE l.IsMigrated = 0
AND lb.ReceiptLegalEntityNumber IS NOT NULL
AND le.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
l.Id
, 'Error'
, ('LoanSyndication: Invalid upfront syndication fee code for [SequenceNumber,UpfrontSyndicationFeeCode] :[' + l.SequenceNumber + ',' + ISNULL(ls.UpfrontSyndicationFeeCode, 'NULL') + ']')
FROM stgLoan l
INNER JOIN dbo.stgLoanSyndication ls ON l.Id = ls.LoanId
LEFT JOIN dbo.BlendedItemCodes bic ON ls.UpfrontSyndicationFeeCode = bic.Name
AND bic.IsActive = 1
WHERE l.IsMigrated = 0
AND ls.UpfrontSyndicationFeeCode IS NOT NULL
AND bic.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
l.Id
, 'Error'
, ('LoanSyndication: Invalid rental proceeds payable code for [SequenceNumber,RentalProceedsPayableCode] :[' + l.SequenceNumber + ',' + ISNULL(ls.RentalProceedsPayableCode, 'NULL') + ']')
FROM stgLoan l
INNER JOIN dbo.stgLoanSyndication ls ON l.Id = ls.LoanId
LEFT JOIN dbo.PayableCodes pc ON pc.Name = ls.RentalProceedsPayableCode
AND pc.IsActive = 1
WHERE l.IsMigrated = 0
AND ls.RentalProceedsPayableCode IS NOT NULL
AND pc.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
l.Id
, 'Error'
, ('LoanSyndication: Invalid scrape receivable code for [SequenceNumber,ScrapeReceivableCode] :[' + l.SequenceNumber + ',' + ISNULL(ls.ScrapeReceivableCode, 'NULL') + ']')
FROM stgLoan l
INNER JOIN dbo.stgLoanSyndication ls ON l.Id = ls.LoanId
LEFT JOIN dbo.ReceivableCodes rc ON ls.ScrapeReceivableCode = rc.Name
AND rc.IsActive = 1
WHERE l.IsMigrated = 0
AND ls.ScrapeReceivableCode IS NOT NULL
AND rc.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
l.Id
, 'Error'
, ('Loan: Invalid agreement type name for [SequenceNumber,AgreementTypeName] :[' + l.SequenceNumber + ',' + ISNULL(l.AgreementTypeName, 'NULL') + ']')
FROM stgLoan l
INNER JOIN dbo.LineofBusinesses lb ON l.LineOfBusinessName = lb.Name AND lb.IsActive = 1
INNER JOIN dbo.DealTypes dt ON dt.ProductType = l.DealTypeName AND dt.IsActive = 1
LEFT JOIN dbo.AgreementTypeConfigs atc ON REPLACE(LTRIM(RTRIM( l.AgreementTypeName)), ' ', '') = REPLACE(LTRIM(RTRIM( atc.Name)), ' ', '')AND atc.IsActive = 1
LEFT JOIN dbo.AgreementTypes at ON at.AgreementTypeConfigId = atc.Id AND at.IsActive = 1
LEFT JOIN AgreementTypeDetails atd ON atd.AgreementTypeId = at.Id AND atd.IsActive = 1
WHERE l.IsMigrated = 0
AND l.AgreementTypeName IS NOT NULL
AND atd.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
l.Id
, 'Error'
, ('Loan: Invalid interim income recognition GLTemplate name for [SequenceNumber,InterimIncomeRecognitionGLTemplateName] :[' + l.SequenceNumber + ',' + ISNULL(l.InterimIncomeRecognitionGLTemplateName, 'NULL') + ']')
FROM stgLoan l
LEFT JOIN dbo.GLTemplates g ON l.InterimIncomeRecognitionGLTemplateName = g.Name
WHERE l.IsMigrated = 0
AND l.InterimIncomeRecognitionGLTemplateName IS NOT NULL
AND g.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
l.Id
, 'Error'
, ('Loan: Invalid loan income recognition GL template name for [SequenceNumber,LoanIncomeRecognitionGLTemplateName] :[' + l.SequenceNumber + ',' + ISNULL(l.LoanIncomeRecognitionGLTemplateName, 'NULL') + ']')
FROM stgLoan l
LEFT JOIN dbo.GLTemplates g ON l.LoanIncomeRecognitionGLTemplateName = g.Name
WHERE l.IsMigrated = 0
AND l.LoanIncomeRecognitionGLTemplateName IS NOT NULL
AND g.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
l.Id
, 'Error'
, ('Loan: Invalid loan booking GL template name for [SequenceNumber,LoanBookingGLTemplateName] :[' + l.SequenceNumber + ',' + ISNULL(l.LoanBookingGLTemplateName, 'NULL') + ']')
FROM stgLoan l
LEFT JOIN dbo.GLTemplates g ON l.LoanBookingGLTemplateName = g.Name
WHERE l.IsMigrated = 0
AND l.LoanBookingGLTemplateName IS NOT NULL
AND g.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
l.Id
, 'Error'
, ('Loan: Invalid loan principal receivable code name for [SequenceNumber,LoanPrincipalReceivableCodeName] :[' + l.SequenceNumber + ',' + ISNULL(l.LoanPrincipalReceivableCodeName, 'NULL') + ']')
FROM stgLoan l
LEFT JOIN dbo.ReceivableCodes rc ON l.LoanPrincipalReceivableCodeName = rc.Name
AND rc.IsActive = 1
WHERE l.IsMigrated = 0
AND l.LoanPrincipalReceivableCodeName IS NOT NULL
AND rc.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
l.Id
, 'Error'
, ('Loan: Invalid loan interest receivable code name for [SequenceNumber,LoanInterestReceivableCodeName] :[' + l.SequenceNumber + ',' + ISNULL(l.LoanInterestReceivableCodeName, 'NULL') + ']')
FROM stgLoan l
LEFT JOIN dbo.ReceivableCodes rc ON l.LoanInterestReceivableCodeName = rc.Name
AND rc.IsActive = 1
WHERE l.IsMigrated = 0
AND l.LoanInterestReceivableCodeName IS NOT NULL
AND rc.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
l.Id
, 'Error'
, ('Loan: Invalid origination source type name for [SequenceNumber,OriginationSourceTypeName] :[' + l.SequenceNumber + ',' + ISNULL(l.OriginationSourceTypeName, 'NULL') + ']')
FROM stgLoan l
LEFT JOIN dbo.OriginationSourceTypes ost ON l.OriginationSourceTypeName = ost.Name
AND ost.IsActive = 1
WHERE l.IsMigrated = 0
AND l.OriginationSourceTypeName IS NOT NULL
AND ost.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
l.Id
, 'Error'
, ('Loan: Invalid acquired portfolio name for [SequenceNumber,AcquiredPortfolioName] :[' + l.SequenceNumber + ',' + ISNULL(l.AcquiredPortfolioName, 'NULL') + ']')
FROM stgLoan l
LEFT JOIN dbo.AcquiredPortfolios ap ON ap.Name = l.AcquiredPortfolioName
WHERE l.IsMigrated = 0
AND l.AcquiredPortfolioName IS NOT NULL
AND ap.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
l.Id
, 'Error'
, ('Loan: Invalid origination fee blended item code name for [SequenceNumber,OriginationFeeBlendedItemCodeName] :[' + l.SequenceNumber + ',' + ISNULL(l.OriginationFeeBlendedItemCodeName, 'NULL') + ']')
FROM stgLoan l
LEFT JOIN dbo.BlendedItemCodes bic ON bic.Name = l.OriginationFeeBlendedItemCodeName
WHERE l.IsMigrated = 0
AND l.OriginationFeeBlendedItemCodeName IS NOT NULL
AND bic.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
l.Id
, 'Error'
, ('Loan: Invalid scrape payable code name for [SequenceNumber,ScrapePayableCodeName] :[' + l.SequenceNumber + ',' + ISNULL(l.ScrapePayableCodeName, 'NULL') + ']')
FROM stgLoan l
LEFT JOIN dbo.PayableCodes pc ON pc.Name = l.ScrapePayableCodeName
WHERE l.IsMigrated = 0
AND l.ScrapePayableCodeName IS NOT NULL
AND pc.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
l.Id
, 'Error'
, ('LoanFunding: Invalid other cost payable code name for [SequenceNumber,OtherCostPayableCodeName] :[' + l.SequenceNumber + ',' + ISNULL(lf.OtherCostPayableCodeName, 'NULL') + ']')
FROM stgLoan l
INNER JOIN dbo.stgLoanFunding lf ON l.Id = lf.LoanId
LEFT JOIN dbo.PayableCodes pc ON pc.Name = lf.OtherCostPayableCodeName
WHERE l.IsMigrated = 0
AND lf.OtherCostPayableCodeName IS NOT NULL
AND pc.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
l.Id
, 'Error'
, ('LoanInterestRate: Invalid float rate index name for [SequenceNumber,FloatRateIndexName] :[' + l.SequenceNumber + ',' + ISNULL(lir.FloatRateIndexName, 'NULL') + ']')
FROM stgLoan l
INNER JOIN dbo.stgLoanInterestRate lir ON l.Id = lir.LoanId
LEFT JOIN dbo.FloatRateIndexes fri ON fri.Name = lir.FloatRateIndexName
WHERE l.IsMigrated = 0
AND lir.FloatRateIndexName IS NOT NULL
AND fri.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
l.Id
, 'Error'
, ('LoanInsuranceRequirement: Invalid coverage type for [SequenceNumber,FloatRateIndexName] :[' + l.SequenceNumber + ',' + ISNULL(lir.CoverageType, 'NULL') + ']')
FROM stgLoan l
INNER JOIN dbo.stgLoanInsuranceRequirement lir ON l.Id = lir.LoanId
LEFT JOIN dbo.CoverageTypeConfigs ctc ON ctc.CoverageType = lir.CoverageType
WHERE l.IsMigrated = 0
AND lir.CoverageType IS NOT NULL
AND ctc.Id IS NULL;
SET @FailedRecords =
(
SELECT ISNULL(COUNT(DISTINCT StagingRootEntityId), 0)
FROM #ErrorLogs
);
MERGE stgProcessingLog AS ProcessingLog
USING
(
SELECT Id
FROM stgLoan
WHERE IsMigrated = 0
AND Id NOT IN
(
SELECT StagingRootEntityId
FROM #ErrorLogs
)
) AS ProcessedLoans
ON(ProcessingLog.StagingRootEntityId = ProcessedLoans.Id
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
(ProcessedLoans.Id
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
) AS ErrorLoans
ON(ProcessingLog.StagingRootEntityId = ErrorLoans.StagingRootEntityId
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
(ErrorLoans.StagingRootEntityId
, @UserId
, @CreatedTime
, @ModuleIterationStatusId
)
OUTPUT Inserted.Id
, ErrorLoans.StagingRootEntityId
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
JOIN #FailedProcessingLogs ON #ErrorLogs.StagingRootEntityId = #FailedProcessingLogs.LoanId;
DROP TABLE #ErrorLogs;
DROP TABLE #FailedProcessingLogs;
DROP TABLE #CreatedProcessingLogs;
END;

GO

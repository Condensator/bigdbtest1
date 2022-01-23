SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ValidateLeases]
(@UserId                  BIGINT,
@ModuleIterationStatusId BIGINT,
@CreatedTime             DATETIMEOFFSET,
@ProcessedRecords        BIGINT OUTPUT,
@FailedRecords           BIGINT OUTPUT
)
AS
BEGIN
CREATE TABLE #FailedProcessingLogs
([Id]      BIGINT NOT NULL,
[LeaseId] BIGINT NOT NULL
);
CREATE TABLE #Params
(CSV            NVARCHAR(MAX),
EntityId       BIGINT,
SequenceNumber NVARCHAR(MAX)
);
CREATE TABLE #CreatedProcessingLogs([Id] BIGINT NOT NULL);
SET @ProcessedRecords =
(
SELECT ISNULL(COUNT(Id), 0)
FROM dbo.stgLease
WHERE IsMigrated = 0
AND IsFailed = 0
);
DECLARE @UseTaxBooks NVARCHAR(50);
SELECT @UseTaxBooks = Value
FROM GlobalParameters
WHERE Category = 'TaxDepAmortizationGL'
AND Name = 'UseTaxBooks';
SELECT * 
INTO #ProcessableLeaseTemp
FROM stgLease
WHERE IsMigrated = 0 AND IsFailed = 0;
SELECT Category
, Name
, Value
, PortfolioId
INTO #PortfolioParameters
FROM PortfolioParameterConfigs AS ppc
LEFT JOIN PortfolioParameters AS pp WITH(NOLOCK) ON ppc.Id = pp.PortfolioParameterConfigId;
SELECT gt.Id
, gt.Name
, gtt.Name GLTransactionType
, gt.GLConfigurationId
, LegalEntityNumber
INTO #GlTemplateTemp
FROM GLTemplates gt
JOIN GLTransactionTypes gtt ON gt.GLTransactionTypeId = gtt.Id
JOIN LegalEntities le ON gt.GLConfigurationId = le.GLConfigurationId;
SELECT PartyId
, BanAccountUniqueIdentifier = BA.UniqueIdentifier
, BankAccountId
INTO #PartyBankAccountDetails
FROM PartyBankAccounts PBA
INNER JOIN Parties ON Parties.Id = PBA.PartyId
INNER JOIN BankAccounts BA ON BA.Id = PBA.BankAccountId
AND (BA.AutomatedPaymentMethod='ACHOrPAP' OR BA.AutomatedPaymentMethod='CreditCard')
AND BA.IsActive = 1
GROUP BY PartyId
, BA.UniqueIdentifier
, BankAccountId;
SELECT DISTINCT
l.Id
, rt.Id AS                        RemitToId
, rht.Id AS                       ReceiptHierarchyTemplateId
, dpt.Id AS                       DealProductTypeId
, dt.Id AS                        DealTypeId
, lb.Id AS                        LineofBusinessId
, c.Id AS                         CurrencyId
, le.Id AS                        LegalEntityId
, tpt.Id AS                       TaxProductTypeId
, it.Id AS                        InstrumentTypeId
, rb.Id AS                        ReferralBankerId
, ccc.Id AS                       CostCenterId
, pastc.Id AS                     ProductAndServiceTypeConfigId
, pic.Id AS                       ProgramIndicatorConfigId
, lc.Id AS                        LanguageId
, atd.ID AS                       AgreementTypeDetailId
, branch.Id AS                    BranchId
, ost.Id AS                       OriginationSourceTypeId
, ap.Id AS                        AcquiredPortfolioId
, bic.Id AS                       OriginationFeeBlendedItemCodeId
, pc.Id AS                        ScrapePayableCodeId
, lb2.Id AS                       OriginatingLineofBusinessId
, rc.Id AS                        DocFeeReceivableCodeId
, L.Currency
, pp1.Value AS                    AcquisitionId
, pp2.Value AS                    WaiveIfLateFeeBelowAmount
, pp3.Value AS                    WaiveIfInvoiceAmountBelowAmount
, DefaultReceiptLegalEntity.Id AS ReceiptLegalEntityId
INTO #LeaseTable
FROM dbo.stgLease AS l WITH(NOLOCK)
INNER JOIN dbo.stgLease lt ON l.Id = lt.Id
LEFT JOIN RemitToes AS rt WITH(NOLOCK) ON l.RemitToUniqueIdentifier = rt.UniqueIdentifier
LEFT JOIN ReceiptHierarchyTemplates AS rht WITH(NOLOCK) ON l.ReceiptHierarchyTemplateName = rht.Name
LEFT JOIN DealTypes AS dt WITH(NOLOCK) ON l.DealTypeName = dt.ProductType
LEFT JOIN DealProductTypes AS dpt WITH(NOLOCK) ON l.DealProductTypeName = dpt.Name
AND dt.Id = dpt.DealTypeId
LEFT JOIN LineofBusinesses AS lb WITH(NOLOCK) ON l.LineOfBusinessName = lb.Name
LEFT JOIN CurrencyCodes AS cc WITH(NOLOCK) ON cc.ISO = l.Currency
LEFT JOIN Currencies AS c WITH(NOLOCK) ON cc.Id = c.CurrencyCodeId
LEFT JOIN LegalEntities AS le WITH(NOLOCK) ON l.LegalEntityNumber = le.LegalEntityNumber
LEFT JOIN BusinessUnits AS bu WITH(NOLOCK) ON le.BusinessUnitId = bu.Id
LEFT JOIN #PortfolioParameters pp1 WITH(NOLOCK) ON pp1.Category = 'GL'
AND pp1.Name = 'AcquisitionId'
AND pp1.PortfolioId = bu.PortfolioId
LEFT JOIN #PortfolioParameters pp2 WITH(NOLOCK) ON pp2.Category = 'LateFee'
AND pp2.Name = 'WaiveIfLateFeeBelowAmount'
AND pp2.PortfolioId = bu.PortfolioId
LEFT JOIN #PortfolioParameters pp3 WITH(NOLOCK) ON pp3.Category = 'LateFee'
AND pp3.Name = 'WaiveIfInvoiceAmountBelowAmount'
AND pp3.PortfolioId = bu.PortfolioId
LEFT JOIN #PortfolioParameters pp4 WITH(NOLOCK) ON pp4.Category = 'Receipt'
AND pp4.Name = 'DefaultReceiptLegalEntity'
AND pp4.PortfolioId = bu.PortfolioId
LEFT JOIN LegalEntities AS DefaultReceiptLegalEntity ON DefaultReceiptLegalEntity.LegalEntityNumber = pp4.Value
LEFT JOIN LegalEntityLineOfBusinesses AS lelob WITH(NOLOCK) ON lb.Id = lelob.Id
LEFT JOIN TaxProductTypes AS tpt WITH(NOLOCK) ON l.TaxProductType = tpt.ProductType
LEFT JOIN InstrumentTypes AS it WITH(NOLOCK) ON l.InstrumentTypeCode = it.Code
LEFT JOIN Users AS rb WITH(NOLOCK) ON l.ReferralBankerLoginName = rb.LoginName
LEFT JOIN Branches AS branch WITH(NOLOCK) ON le.Id = branch.LegalEntityId
AND branch.BranchName = l.BranchName
--LEFT JOIN CreditApprovedStructures cas
LEFT JOIN CostCenterConfigs AS ccc WITH(NOLOCK) ON l.CostCenterConfigName = ccc.CostCenter
LEFT JOIN ProductAndServiceTypeConfigs AS pastc WITH(NOLOCK) ON l.ProductAndServiceTypeConfigCode = pastc.ProductAndServiceTypeCode
LEFT JOIN ProgramIndicatorConfigs AS pic WITH(NOLOCK) ON l.ProgramIndicatorConfigName = pic.ProgramIndicatorCode
LEFT JOIN LanguageConfigs AS lc WITH(NOLOCK) ON l.Language = lc.Name
--ThirdPartyResidualGuarantorId       BIGINT,
--    ThirdPartyResidualGuarantorBillToId BIGINT,
LEFT JOIN AgreementTypeConfigs AS atc WITH(NOLOCK) ON REPLACE(LTRIM(RTRIM( l.AgreementTypeName)), ' ', '') = REPLACE(LTRIM(RTRIM( atc.Name)), ' ', '')
LEFT JOIN AgreementTypes AS at WITH(NOLOCK) ON at.AgreementTypeConfigId = atc.Id
LEFT JOIN AgreementTypeDetails AS atd WITH(NOLOCK) ON atd.AgreementTypeId = at.Id
AND atd.LineofBusinessId = lb.Id
AND atd.DealTypeId = dt.Id
--LEFT JOIN Branches b2 WITH (NOLOCK) ON l.ba
LEFT JOIN OriginationSourceTypes AS ost WITH(NOLOCK) ON l.OriginationSourceTypeName = ost.Name
--OriginationSourceUserId
LEFT JOIN AcquiredPortfolios AS ap WITH(NOLOCK) ON l.AcquiredPortfolioName = ap.Name
LEFT JOIN BlendedItemCodes AS bic WITH(NOLOCK) ON l.OriginationFeeBlendedItemCode = bic.Name
LEFT JOIN PayableCodes AS pc WITH(NOLOCK) ON l.ScrapePayableCodeName = pc.Name
LEFT JOIN LineofBusinesses AS lb2 WITH(NOLOCK) ON l.OriginatingLineofBusinessName = lb2.Name
LEFT JOIN ReceivableCodes AS rc WITH(NOLOCK) ON l.DocFeeReceivableCodeName = rc.Name;
UPDATE dbo.stgLease
SET
R_RemitToId = lt.RemitToId
, R_ReceiptHierarchyTemplateId = lt.ReceiptHierarchyTemplateId
, R_DealProductTypeId = lt.DealProductTypeId
, R_DealTypeId = lt.DealTypeId
, R_LineofBusinessId = lt.LineofBusinessId
, R_CurrencyId = lt.CurrencyId
, R_LegalEntityId = lt.LegalEntityId
, R_TaxProductTypeId = lt.TaxProductTypeId
, R_InstrumentTypeId = lt.InstrumentTypeId
, R_ReferralBankerId = lt.ReferralBankerId
, R_CostCenterId = lt.CostCenterId
, R_ProductAndServiceTypeConfigId = lt.ProductAndServiceTypeConfigId
, R_ProgramIndicatorConfigId = lt.ProgramIndicatorConfigId
, R_LanguageId = lt.LanguageId
, R_AgreementTypeDetailId = lt.AgreementTypeDetailId
, R_BranchId = lt.BranchId
, R_OriginationSourceTypeId = lt.OriginationSourceTypeId
, R_AcquiredPortfolioId = lt.AcquiredPortfolioId
, R_OriginationFeeBlendedItemCodeId = lt.OriginationFeeBlendedItemCodeId
, R_ScrapePayableCodeId = lt.ScrapePayableCodeId
, R_OriginatingLineofBusinessId = lt.OriginatingLineofBusinessId
, R_DocFeeReceivableCodeId = lt.DocFeeReceivableCodeId
, R_AcquisitionId = lt.AcquisitionId
FROM #LeaseTable lt
WHERE lt.Id = dbo.stgLease.Id;
UPDATE dbo.stgLease
SET
AccountingStandard = ISNULL(LE.AccountingStandard, '_')
FROM dbo.stgLease AS l
INNER JOIN LegalEntities LE ON l.LegalEntityNumber = LE.LegalEntityNumber
WHERE(l.AccountingStandard IS NULL
OR l.AccountingStandard = '_')
AND l.IsMigrated = 0;

INSERT INTO #Params
SELECT 'Lease: SequenceNumber provided already exists. [SequenceNumber] :[' + l.SequenceNumber + ' ]'
, l.Id
, l.SequenceNumber
FROM #ProcessableLeaseTemp AS l WITH(NOLOCK)
INNER JOIN dbo.Contracts c ON c.SequenceNumber = l.SequenceNumber

INSERT INTO #Params
SELECT 'Lease: LeaseFinance Detail should be provided for [SequenceNumber] :['+l.SequenceNumber+' ]'
, l.Id
, l.SequenceNumber
FROM #ProcessableLeaseTemp AS l WITH (NOLOCK)
LEFT JOIN dbo.stgLeaseFinanceDetail lfd ON lfd.Id=l.Id WHERE lfd.Id IS NULL;

INSERT INTO #Params
SELECT 'Lease: RemitToUniqueIdentifier provided is not valid for [SequenceNumber, RemitToUniqueIdentifier] :[' + l.SequenceNumber + ',' + l.RemitToUniqueIdentifier + ' ]'
, l.Id
, l.SequenceNumber
FROM #ProcessableLeaseTemp AS l WITH(NOLOCK)
WHERE l.R_RemitToId IS NULL
AND LTRIM(RTRIM(ISNULL(l.RemitToUniqueIdentifier ,''))) <> '';

INSERT INTO #Params
SELECT 'Lease: ReceiptHierarchyTemplateName provided is not valid for [SequenceNumber, ReceiptHierarchyTemplateName] :[' + l.SequenceNumber + ',' + l.ReceiptHierarchyTemplateName + ' ]'
, l.Id
, l.SequenceNumber
FROM #ProcessableLeaseTemp AS l WITH(NOLOCK)
WHERE l.R_ReceiptHierarchyTemplateId IS NULL
AND LTRIM(RTRIM(ISNULL(l.ReceiptHierarchyTemplateName ,''))) <> '';

INSERT INTO #Params
SELECT 'Lease: DealTypeName provided is not valid for [SequenceNumber, DealTypeName] :[' + l.SequenceNumber + ',' + l.DealTypeName + ' ]'
, l.Id
, l.SequenceNumber
FROM #ProcessableLeaseTemp AS l WITH(NOLOCK)
WHERE l.R_DealTypeId IS NULL
AND LTRIM(RTRIM(ISNULL(l.DealTypeName ,''))) <> '';

INSERT INTO #Params
SELECT 'Lease: DealProductTypeName provided is not valid for [SequenceNumber, DealProductTypeName] :[' + l.SequenceNumber + ',' + l.DealProductTypeName + ' ]'
, l.Id
, l.SequenceNumber
FROM #ProcessableLeaseTemp AS l WITH(NOLOCK)
WHERE l.R_DealProductTypeId IS NULL
AND LTRIM(RTRIM(ISNULL(l.DealProductTypeName ,'_'))) <> '_';

INSERT INTO #Params
SELECT 'Lease: LineOfBusinessName provided is not valid for [SequenceNumber, LineOfBusinessName] :[' + l.SequenceNumber + ',' + l.LineOfBusinessName + ' ]'
, l.Id
, l.SequenceNumber
FROM #ProcessableLeaseTemp AS l WITH(NOLOCK)
WHERE l.R_LineofBusinessId IS NULL
AND LTRIM(RTRIM(ISNULL(l.LineOfBusinessName ,''))) <> '';

INSERT INTO #Params
SELECT 'Lease: Currency provided is not valid for [SequenceNumber, Currency] :[' + l.SequenceNumber + ',' + l.Currency + ' ]'
, l.Id
, l.SequenceNumber
FROM #ProcessableLeaseTemp AS l WITH(NOLOCK)
WHERE l.R_CurrencyId IS NULL
AND LTRIM(RTRIM(ISNULL(l.Currency ,''))) <> '';

INSERT INTO #Params
SELECT 'Lease: LegalEntityNumber provided is not valid for [SequenceNumber, LegalEntityNumber] :[' + l.SequenceNumber + ',' + l.LegalEntityNumber + ' ]'
, l.Id
, l.SequenceNumber
FROM #ProcessableLeaseTemp AS l WITH(NOLOCK)
WHERE l.R_LegalEntityId IS NULL
AND LTRIM(RTRIM(ISNULL(l.LegalEntityNumber ,''))) <> '';

INSERT INTO #Params
SELECT 'Lease: TaxProductType provided is not valid for [SequenceNumber, TaxProductType] :[' + l.SequenceNumber + ',' + l.TaxProductType + ' ]'
, l.Id
, l.SequenceNumber
FROM #ProcessableLeaseTemp AS l WITH(NOLOCK)
WHERE l.R_TaxProductTypeId IS NULL
AND LTRIM(RTRIM(ISNULL(l.TaxProductType ,''))) <> '';

INSERT INTO #Params
SELECT 'Lease: InstrumentTypeCode provided is not valid for [SequenceNumber, InstrumentTypeCode] :[' + l.SequenceNumber + ',' + l.InstrumentTypeCode + ' ]'
, l.Id
, l.SequenceNumber
FROM #ProcessableLeaseTemp AS l WITH(NOLOCK)
WHERE l.R_InstrumentTypeId IS NULL
AND LTRIM(RTRIM(ISNULL(l.InstrumentTypeCode ,''))) <> '';

INSERT INTO #Params
SELECT 'Lease: ReferralBankerLoginName provided is not valid for [SequenceNumber, ReferralBankerLoginName] :[' + l.SequenceNumber + ',' + l.ReferralBankerLoginName + ' ]'
, l.Id
, l.SequenceNumber
FROM #ProcessableLeaseTemp AS l WITH(NOLOCK)
WHERE l.R_ReferralBankerId IS NULL
AND LTRIM(RTRIM(ISNULL(l.ReferralBankerLoginName ,''))) <> '';

INSERT INTO #Params
SELECT 'Lease: CostCenterConfigName provided is not valid for [SequenceNumber, CostCenterConfigName] :[' + l.SequenceNumber + ',' + l.CostCenterConfigName + ' ]'
, l.Id
, l.SequenceNumber
FROM #ProcessableLeaseTemp AS l WITH(NOLOCK)
WHERE l.R_CostCenterId IS NULL
AND LTRIM(RTRIM(ISNULL(l.CostCenterConfigName ,''))) <> '';

INSERT INTO #Params
SELECT 'Lease: ProductAndServiceTypeConfigCode provided is not valid for [SequenceNumber, ProductAndServiceTypeConfigCode] :[' + l.SequenceNumber + ',' + l.ProductAndServiceTypeConfigCode + ' ]'
, l.Id
, l.SequenceNumber
FROM #ProcessableLeaseTemp AS l WITH(NOLOCK)
WHERE l.R_ProductAndServiceTypeConfigId IS NULL
AND LTRIM(RTRIM(ISNULL(l.ProductAndServiceTypeConfigCode ,''))) <> '';

INSERT INTO #Params
SELECT 'Lease: ProgramIndicatorConfigName provided is not valid for [SequenceNumber, ProgramIndicatorConfigName] :[' + l.SequenceNumber + ',' + l.ProgramIndicatorConfigName + ' ]'
, l.Id
, l.SequenceNumber
FROM #ProcessableLeaseTemp AS l WITH(NOLOCK)
WHERE l.R_ProgramIndicatorConfigId IS NULL
AND LTRIM(RTRIM(ISNULL(l.ProgramIndicatorConfigName ,''))) <> '';

INSERT INTO #Params
SELECT 'Lease: Language provided is not valid for [SequenceNumber, Language] :[' + l.SequenceNumber + ',' + l.Language + ' ]'
, l.Id
, l.SequenceNumber
FROM #ProcessableLeaseTemp AS l WITH(NOLOCK)
WHERE l.R_LanguageId IS NULL
AND LTRIM(RTRIM(ISNULL(l.Language ,''))) <> '';

INSERT INTO #Params
SELECT 'Lease: AgreementTypeName provided is not valid for [SequenceNumber, AgreementTypeName] :[' + l.SequenceNumber + ',' + l.AgreementTypeName + ' ]'
, l.Id
, l.SequenceNumber
FROM #ProcessableLeaseTemp AS l WITH(NOLOCK)
WHERE l.R_AgreementTypeDetailId IS NULL
AND LTRIM(RTRIM(ISNULL(l.AgreementTypeName ,'_'))) <> '_';

INSERT INTO #Params
SELECT 'Lease: OriginationSourceTypeName provided is not valid for [SequenceNumber, OriginationSourceTypeName] :[' + l.SequenceNumber + ',' + l.OriginationSourceTypeName + ' ]'
, l.Id
, l.SequenceNumber
FROM #ProcessableLeaseTemp AS l WITH(NOLOCK)
WHERE l.R_OriginationSourceTypeId IS NULL
AND LTRIM(RTRIM(ISNULL(l.OriginationSourceTypeName ,'_'))) <> '_';

INSERT INTO #Params
SELECT 'Lease: AcquiredPortfolioName provided is not valid for [SequenceNumber, AcquiredPortfolioName] :[' + l.SequenceNumber + ',' + l.AcquiredPortfolioName + ' ]'
, l.Id
, l.SequenceNumber
FROM #ProcessableLeaseTemp AS l WITH(NOLOCK)
WHERE l.R_AcquiredPortfolioId IS NULL
AND LTRIM(RTRIM(ISNULL(l.AcquiredPortfolioName ,''))) <> '';

INSERT INTO #Params
SELECT 'Lease: OriginationFeeBlendedItemCode provided is not valid for [SequenceNumber, OriginationFeeBlendedItemCode] :[' + l.SequenceNumber + ',' + l.OriginationFeeBlendedItemCode + ' ]'
, l.Id
, l.SequenceNumber
FROM #ProcessableLeaseTemp AS l WITH(NOLOCK)
WHERE l.R_OriginationFeeBlendedItemCodeId IS NULL
AND LTRIM(RTRIM(ISNULL(l.OriginationFeeBlendedItemCode ,''))) <> '';

INSERT INTO #Params
SELECT 'Lease: ScrapePayableCodeName provided is not valid for [SequenceNumber, ScrapePayableCodeName] :[' + l.SequenceNumber + ',' + l.ScrapePayableCodeName + ' ]'
, l.Id
, l.SequenceNumber
FROM #ProcessableLeaseTemp AS l WITH(NOLOCK)
WHERE l.R_ScrapePayableCodeId IS NULL
AND LTRIM(RTRIM(ISNULL(l.ScrapePayableCodeName ,''))) <> '';

INSERT INTO #Params
SELECT 'Lease: OriginatingLineofBusinessName provided is not valid for [SequenceNumber, OriginatingLineofBusinessName] :[' + l.SequenceNumber + ',' + l.OriginatingLineofBusinessName + ' ]'
, l.Id
, l.SequenceNumber
FROM #ProcessableLeaseTemp AS l WITH(NOLOCK)
WHERE l.R_OriginatingLineofBusinessId IS NULL
AND LTRIM(RTRIM(ISNULL(l.OriginatingLineofBusinessName ,''))) <> '';

INSERT INTO #Params
SELECT 'Lease: ProgramVendorOriginationSourceNumber provided is not valid for [SequenceNumber, ProgramVendorOriginationSourceNumber] :[' + l.SequenceNumber + ',' + l.ProgramVendorOriginationSourceNumber + ' ]'
, l.Id
, l.SequenceNumber
FROM #ProcessableLeaseTemp AS l WITH(NOLOCK)
WHERE l.R_ProgramVendorOriginationSourceId IS NULL
AND LTRIM(RTRIM(ISNULL(l.ProgramVendorOriginationSourceNumber ,''))) <> '';

INSERT INTO #Params
SELECT 'Lease: DocFeeReceivableCodeName provided is not valid for [SequenceNumber, DocFeeReceivableCodeName] :[' + l.SequenceNumber + ',' + l.DocFeeReceivableCodeName + ' ]'
, l.Id
, l.SequenceNumber
FROM #ProcessableLeaseTemp AS l WITH(NOLOCK)
WHERE l.R_DocFeeReceivableCodeId IS NULL
AND LTRIM(RTRIM(ISNULL(l.DocFeeReceivableCodeName ,''))) <> '';

INSERT INTO #Params
SELECT 'Lease: BranchName provided is not valid for [SequenceNumber, BranchName] :[' + l.SequenceNumber + ',' + l.BranchName + ' ]'
, l.Id
, l.SequenceNumber
FROM #ProcessableLeaseTemp AS l WITH(NOLOCK)
WHERE l.R_BranchId IS NULL
AND LTRIM(RTRIM(ISNULL(l.BranchName ,''))) <> '';

INSERT INTO #Params
SELECT 'LeaseFinanceDetail: Syndicated leases cannot be a Tax Lease for [SequenceNumber] :['+Lease.SequenceNumber+']', Lease.Id, Lease.SequenceNumber  
FROM stgLeaseFinanceDetail AS lfdt WITH (NOLOCK)
INNER JOIN #ProcessableLeaseTemp as Lease ON Lease.Id = lfdt.Id
WHERE (Lease.SyndicationType != 'None' AND Lease.SyndicationType != '_') AND IsTaxLease = 1;

SELECT lfd.Id
, rc.Id AS  FixedTermReceivableCodeId
, rc1.Id AS FloatRateARReceivableCodeId
, rc2.Id AS OTPReceivableCodeId
, rc4.Id AS SupplementalReceivableCodeId
, rc3.Id AS PropertyTaxReceivableCodeId
, g1.Id AS  LeaseBookingGLTemplateId
, g2.Id AS  LeaseIncomeGLTemplateId
, g.Id AS   FloatIncomeGLTemplateId
, g3.Id AS  OTPIncomeGLTemplateId
, g4.ID AS  DeferredTaxGLTemplateId
, g6.Id AS  TaxDepExpenseGLTemplateId
, g5.Id AS  TaxAssetSetupGLTemplateId
, g7.Id AS  TaxDepDisposalTemplateId
INTO #LeaseFinanceDetailTable
FROM stgLeaseFinanceDetail AS lfd WITH(NOLOCK)
INNER JOIN stgLease AS l WITH(NOLOCK) ON lfd.Id = l.Id
LEFT JOIN LegalEntities AS le ON l.LegalEntityNumber = le.LegalEntityNumber
LEFT JOIN ReceivableCodes AS rc WITH(NOLOCK) ON lfd.FixedTermRentReceivableCodeName = rc.Name
LEFT JOIN ReceivableCodes AS rc1 WITH(NOLOCK) ON lfd.FloatRateARReceivableCodeName = rc1.Name
LEFT JOIN ReceivableCodes AS rc2 WITH(NOLOCK) ON lfd.OTPReceivableCodeName = rc2.Name
LEFT JOIN ReceivableCodes AS rc3 WITH(NOLOCK) ON lfd.PropertyTaxReceivableCodeName = rc3.Name
LEFT JOIN ReceivableCodes AS rc4 WITH(NOLOCK) ON lfd.SupplementalReceivableCodeName = rc4.Name
LEFT JOIN #GlTemplateTemp AS g WITH(NOLOCK) ON lfd.FloatIncomeGLTemplateName = g.Name
AND g.GLConfigurationId = le.GLConfigurationId
AND g.LegalEntityNumber = le.LegalEntityNumber
AND g.GLTransactionType = 'FloatIncome'
LEFT JOIN #GlTemplateTemp AS g1 WITH(NOLOCK) ON lfd.LeaseBookingGLTemplateName = g1.Name
AND g1.GLConfigurationId = le.GLConfigurationId
AND g1.LegalEntityNumber = le.LegalEntityNumber
AND ((g1.GLTransactionType = 'OperatingLeaseBooking'
AND lfd.ContractType = 'Operating')
OR (g1.GLTransactionType = 'CapitalLeaseBooking'
AND lfd.ContractType IN('DirectFinance', 'ConditionalSales', 'SalesType', 'Financing', 'IFRSFinanceLease')))
LEFT JOIN #GlTemplateTemp AS g2 WITH(NOLOCK) ON lfd.LeaseIncomeGLTemplateName = g2.Name
AND g2.GLConfigurationId = le.GLConfigurationId
AND g2.LegalEntityNumber = le.LegalEntityNumber
AND ((g2.GLTransactionType = 'OperatingLeaseIncome'
AND lfd.ContractType = 'Operating')
OR (g2.GLTransactionType = 'CapitalLeaseIncome'
AND lfd.ContractType IN('DirectFinance', 'ConditionalSales', 'SalesType', 'Financing', 'IFRSFinanceLease')))
LEFT JOIN #GlTemplateTemp AS g3 WITH(NOLOCK) ON lfd.OTPIncomeGLTemplateName = g3.Name
AND g3.GLConfigurationId = le.GLConfigurationId
AND g3.LegalEntityNumber = le.LegalEntityNumber
AND g3.GLTransactionType = 'OTPIncome'
LEFT JOIN #GlTemplateTemp AS g4 WITH(NOLOCK) ON lfd.DeferredTaxGLTemplateName = g4.Name
AND g4.GLConfigurationId = le.GLConfigurationId
AND g4.LegalEntityNumber = le.LegalEntityNumber
AND g4.GLTransactionType = 'DeferredTaxLiability'
LEFT JOIN #GlTemplateTemp AS g5 WITH(NOLOCK) ON lfd.TaxAssetSetupGLTemplateName = g5.Name
AND g5.GLConfigurationId = le.GLConfigurationId
AND g5.LegalEntityNumber = le.LegalEntityNumber
AND g5.GLTransactionType = 'TaxAssetSetup'
LEFT JOIN #GlTemplateTemp AS g6 WITH(NOLOCK) ON lfd.TaxDepExpenseGLTemplateName = g6.Name
AND g6.GLConfigurationId = le.GLConfigurationId
AND g6.LegalEntityNumber = le.LegalEntityNumber
AND g6.GLTransactionType = 'TaxDepreciation'
LEFT JOIN #GlTemplateTemp AS g7 WITH(NOLOCK) ON lfd.TaxDepDisposalTemplateName = g7.Name
AND g7.GLConfigurationId = le.GLConfigurationId
AND g7.LegalEntityNumber = le.LegalEntityNumber
AND g7.GLTransactionType = 'TaxDepreciationDisposal';
UPDATE stgLeaseFinanceDetail
SET
R_FixedTermReceivableCodeId = lfdt.FixedTermReceivableCodeId
, R_FloatRateARReceivableCodeId = lfdt.FloatRateARReceivableCodeId
, R_OTPReceivableCodeId = lfdt.OTPReceivableCodeId
, R_SupplementalReceivableCodeId = lfdt.SupplementalReceivableCodeId
, R_PropertyTaxReceivableCodeId = lfdt.PropertyTaxReceivableCodeId
, R_LeaseBookingGLTemplateId = lfdt.LeaseBookingGLTemplateId
, R_LeaseIncomeGLTemplateId = lfdt.LeaseIncomeGLTemplateId
, R_FloatIncomeGLTemplateId = lfdt.FloatIncomeGLTemplateId
, R_OTPIncomeGLTemplateId = lfdt.OTPIncomeGLTemplateId
, R_DeferredTaxGLTemplateId = lfdt.DeferredTaxGLTemplateId
, R_TaxDepExpenseGLTemplateId = lfdt.TaxDepExpenseGLTemplateId
, R_TaxAssetSetupGLTemplateId = lfdt.TaxAssetSetupGLTemplateId
, R_TaxDepDisposalTemplateId = lfdt.TaxDepDisposalTemplateId
FROM #LeaseFinanceDetailTable lfdt
WHERE lfdt.Id = stgLeaseFinanceDetail.Id;

INSERT INTO #Params  
SELECT 'LeaseFinanceDetail: OTP Rent Preference should be either Lease level or Asset level :['+lease.SequenceNumber+','+ISNULL(lfdt.OTPRentPreference, 'NULL')+' ]', lease.Id, lease.SequenceNumber  
FROM stgLeaseFinanceDetail AS lfdt WITH (NOLOCK)
	 JOIN #ProcessableLeaseTemp lease WITH (NOLOCK) on lfdt.Id = lease.Id     
	   WHERE lfdt.isotplease = 1 AND lfdt.OTPRentPreference NOT IN ('LeaseLevel' , 'AssetLevel');

INSERT INTO #Params
SELECT 'LeaseFinanceDetail: FixedTermRentReceivableCodeName provided is not valid for [SequenceNumber, FixedTermRentReceivableCodeName] :[' + l.SequenceNumber + ',' + ISNULL(lfdt.FixedTermRentReceivableCodeName, 'NULL') + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseFinanceDetail AS lfdt WITH(NOLOCK)
JOIN #ProcessableLeaseTemp l ON lfdt.Id = l.Id
WHERE lfdt.R_FixedTermReceivableCodeId IS NULL
AND (LTRIM(RTRIM(ISNULL(lfdt.FixedTermRentReceivableCodeName ,''))) <> ''
OR (l.SyndicationType = 'None'
OR l.SyndicationType = '_'));

INSERT INTO #Params
SELECT 'LeaseFinanceDetail: FloatRateARReceivableCodeName provided is not valid for [SequenceNumber, FloatRateARReceivableCodeName] :[' + l.SequenceNumber + ',' + ISNULL(lfdt.FloatRateARReceivableCodeName, 'NULL') + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseFinanceDetail AS lfdt WITH(NOLOCK)
JOIN #ProcessableLeaseTemp l ON lfdt.Id = l.Id
WHERE lfdt.R_FloatRateARReceivableCodeId IS NULL
AND (LTRIM(RTRIM(ISNULL(lfdt.FloatRateARReceivableCodeName ,''))) <> ''
OR lfdt.IsFloatRateLease = 1);

INSERT INTO #Params
SELECT 'LeaseFinanceDetail: OTPReceivableCodeName provided is not valid for [SequenceNumber, OTPReceivableCodeName] :[' + l.SequenceNumber + ',' + ISNULL(lfdt.OTPReceivableCodeName, 'NULL') + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseFinanceDetail AS lfdt WITH(NOLOCK)
JOIN #ProcessableLeaseTemp AS l ON l.id = lfdt.Id
WHERE lfdt.R_OTPReceivableCodeId IS NULL
AND (LTRIM(RTRIM(ISNULL(lfdt.OTPReceivableCodeName ,''))) <> ''
OR IsOTPLease = 1);

INSERT INTO #Params
SELECT 'LeaseFinanceDetail: PropertyTaxReceivableCodeName provided is not valid for [SequenceNumber, PropertyTaxReceivableCodeName] :[' + l.SequenceNumber + ',' + lfdt.PropertyTaxReceivableCodeName + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseFinanceDetail AS lfdt WITH(NOLOCK)
JOIN #ProcessableLeaseTemp AS l ON l.id = lfdt.Id
WHERE lfdt.R_PropertyTaxReceivableCodeId IS NULL
AND LTRIM(RTRIM(ISNULL(lfdt.PropertyTaxReceivableCodeName ,''))) <> '';

INSERT INTO #Params
SELECT 'LeaseFinanceDetail: SupplementalReceivableCodeName provided is not valid for [SequenceNumber, SupplementalReceivableCodeName] :[' + l.SequenceNumber + ',' + lfdt.SupplementalReceivableCodeName + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseFinanceDetail AS lfdt WITH(NOLOCK)
JOIN #ProcessableLeaseTemp AS l ON l.id = lfdt.Id
WHERE lfdt.R_SupplementalReceivableCodeId IS NULL
AND LTRIM(RTRIM(ISNULL(lfdt.SupplementalReceivableCodeName ,''))) <> '';

INSERT INTO #Params
SELECT 'LeaseFinanceDetail: FloatIncomeGLTemplateName provided is not valid for [SequenceNumber, FloatIncomeGLTemplateName] :[' + l.SequenceNumber + ',' + ISNULL(lfdt.FloatIncomeGLTemplateName, 'NULL') + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseFinanceDetail AS lfdt WITH(NOLOCK)
JOIN #ProcessableLeaseTemp AS l ON l.id = lfdt.Id
WHERE lfdt.R_FloatIncomeGLTemplateId IS NULL
AND (LTRIM(RTRIM(ISNULL(lfdt.FloatIncomeGLTemplateName ,''))) <> ''
OR lfdt.IsFloatRateLease = 1);

INSERT INTO #Params
SELECT 'LeaseFinanceDetail: LeaseBookingGLTemplateName provided is not valid for [SequenceNumber, LeaseBookingGLTemplateName] :[' + lease.SequenceNumber + ',' + ISNULL(lfdt.LeaseBookingGLTemplateName, 'NULL') + ' ]'
, lease.Id
, lease.SequenceNumber
FROM stgLeaseFinanceDetail AS lfdt WITH(NOLOCK)
JOIN #ProcessableLeaseTemp lease ON lfdt.Id = lease.Id
WHERE lfdt.R_LeaseBookingGLTemplateId IS NULL
AND (LTRIM(RTRIM(ISNULL(lfdt.LeaseBookingGLTemplateName ,''))) <> ''
OR (lease.SyndicationType = 'None'
OR lease.SyndicationType = '_'));

INSERT INTO #Params
SELECT 'LeaseFinanceDetail: LeaseIncomeGLTemplateName provided is not valid for [SequenceNumber, LeaseIncomeGLTemplateName] :[' + l.SequenceNumber + ',' + ISNULL(lfdt.LeaseIncomeGLTemplateName, 'NULL') + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseFinanceDetail AS lfdt WITH(NOLOCK)
JOIN #ProcessableLeaseTemp AS l ON l.id = lfdt.Id
WHERE lfdt.R_LeaseIncomeGLTemplateId IS NULL
AND (LTRIM(RTRIM(ISNULL(lfdt.LeaseIncomeGLTemplateName ,''))) <> ''
OR (l.SyndicationType = 'None'
OR l.SyndicationType = '_'));

INSERT INTO #Params
SELECT 'LeaseFinanceDetail: OTPIncomeGLTemplateName provided is not valid for [SequenceNumber, OTPIncomeGLTemplateName] :[' + l.SequenceNumber + ',' + ISNULL(lfdt.OTPIncomeGLTemplateName, 'NULL') + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseFinanceDetail AS lfdt WITH(NOLOCK)
JOIN #ProcessableLeaseTemp AS l ON l.id = lfdt.Id
WHERE lfdt.R_OTPIncomeGLTemplateId IS NULL
AND (LTRIM(RTRIM(ISNULL(lfdt.OTPIncomeGLTemplateName ,''))) <> ''
OR IsOTPLease = 1);

INSERT INTO #Params
SELECT 'LeaseFinanceDetail: DeferredTaxGLTemplateName provided is not valid for [SequenceNumber, DeferredTaxGLTemplateName] :[' + l.SequenceNumber + ',' + lfdt.DeferredTaxGLTemplateName + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseFinanceDetail AS lfdt WITH(NOLOCK)
JOIN #ProcessableLeaseTemp AS l ON l.id = lfdt.Id
WHERE lfdt.R_DeferredTaxGLTemplateId IS NULL
AND LTRIM(RTRIM(ISNULL(lfdt.DeferredTaxGLTemplateName ,''))) <> '';

INSERT INTO #Params
SELECT 'LeaseFinanceDetail: DeferredTaxGLTemplateName provided is not valid for [SequenceNumber, DeferredTaxGLTemplateName] :[' + l.SequenceNumber + ',' + ISNULL(lfdt.DeferredTaxGLTemplateName, 'NULL') + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseFinanceDetail AS lfdt WITH(NOLOCK)
JOIN #ProcessableLeaseTemp AS l ON l.id = lfdt.Id
WHERE lfdt.R_DeferredTaxGLTemplateId IS NULL
AND IsTaxLease = 1;

INSERT INTO #Params
SELECT 'LeaseFinanceDetail: TaxAssetSetupGLTemplateName provided is not valid for [SequenceNumber, TaxAssetSetupGLTemplateName] :[' + l.SequenceNumber + ',' + ISNULL(lfdt.TaxAssetSetupGLTemplateName, 'NULL') + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseFinanceDetail AS lfdt WITH(NOLOCK)
JOIN #ProcessableLeaseTemp AS l ON l.id = lfdt.Id
WHERE lfdt.R_TaxAssetSetupGLTemplateId IS NULL
AND (LTRIM(RTRIM(ISNULL(lfdt.TaxAssetSetupGLTemplateName ,''))) <> ''
OR (@UseTaxBooks = 'True'
AND lfdt.IsTaxLease = 1));

INSERT INTO #Params
SELECT 'LeaseFinanceDetail: TaxDepExpenseGLTemplateName provided is not valid for [SequenceNumber, TaxDepExpenseGLTemplateName] :[' + l.SequenceNumber + ',' + ISNULL(lfdt.TaxDepExpenseGLTemplateName, 'NULL') + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseFinanceDetail AS lfdt WITH(NOLOCK)
JOIN #ProcessableLeaseTemp AS l ON l.id = lfdt.Id
WHERE lfdt.R_TaxDepExpenseGLTemplateId IS NULL
AND (LTRIM(RTRIM(ISNULL(lfdt.TaxDepExpenseGLTemplateName ,''))) <> ''
OR (@UseTaxBooks = 'True'
AND lfdt.IsTaxLease = 1));

INSERT INTO #Params
SELECT 'LeaseFinanceDetail: TaxDepDisposalTemplateName provided is not valid for [SequenceNumber, TaxDepDisposalTemplateName] :[' + l.SequenceNumber + ',' + ISNULL(lfdt.TaxDepDisposalTemplateName, 'NULL') + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseFinanceDetail AS lfdt WITH(NOLOCK)
JOIN #ProcessableLeaseTemp AS l ON l.id = lfdt.Id
WHERE lfdt.R_TaxDepDisposalTemplateId IS NULL
AND LTRIM(RTRIM(ISNULL(lfdt.TaxDepDisposalTemplateName ,''))) <> '';

INSERT INTO #Params
SELECT 'Lease: ContractType provided is not valid for [SequenceNumber, ContractType] :[' + l.SequenceNumber + ',' + lfdt.ContractType + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseFinanceDetail AS lfdt WITH(NOLOCK)
INNER JOIN #ProcessableLeaseTemp l ON l.Id = lfdt.Id
INNER JOIN DealProductTypes ON l.R_DealProductTypeId = DealProductTypes.Id
AND ((l.AccountingStandard = 'ASC840_IAS17'
AND lfdt.ContractType != 'Operating'
AND lfdt.ContractType != DealProductTypes.CapitalLeaseType)
OR (l.AccountingStandard = 'ASC842'
AND lfdt.ContractType != 'Financing'
AND lfdt.ContractType != 'SalesType'
AND lfdt.ContractType != 'DirectFinance'
AND lfdt.ContractType != 'Operating')
OR (l.AccountingStandard = 'IFRS16'
AND lfdt.ContractType != 'Financing'
AND lfdt.ContractType != 'IFRSFinanceLease'
AND lfdt.ContractType != 'Operating'));

INSERT INTO #Params
SELECT 'LeaseFinanceDetail: Number of OTP payments must be greater than zero for OTP Lease [SequenceNumber] :[' + l.SequenceNumber + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseFinanceDetail AS lfdt WITH(NOLOCK)
JOIN #ProcessableLeaseTemp AS l ON l.id = lfdt.Id
WHERE lfdt.IsOTPLease = 1
AND NumberOfOTPPayments <= 0
AND lfdt.IsOTPScheduled = 1;

INSERT INTO #Params
SELECT 'LeaseFinanceDetail: OTPPaymentFrequency provided is not valid  for OTP Lease [SequenceNumber, OTPPaymentFrequency] :[' + l.SequenceNumber + ',' + ISNULL(lfdt.OTPPaymentFrequency, 'NULL') + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseFinanceDetail AS lfdt WITH(NOLOCK)
JOIN #ProcessableLeaseTemp AS l ON l.id = lfdt.Id
WHERE lfdt.IsOTPLease = 1
AND LTRIM(RTRIM(ISNULL(lfdt.OTPPaymentFrequency,'_'))) = '_';

INSERT INTO #Params
SELECT 'LeaseFinanceDetail: OTP Payment Frequency Days should be 28,30 for OTP Lease [SequenceNumber, OTPPaymentFrequencyUnit] :[' + l.SequenceNumber + ',' + CONVERT(NVARCHAR(5), lfdt.OTPPaymentFrequencyUnit) + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseFinanceDetail AS lfdt WITH(NOLOCK)
JOIN #ProcessableLeaseTemp AS l ON l.id = lfdt.Id
WHERE lfdt.IsOTPLease = 1
AND LTRIM(RTRIM(ISNULL(lfdt.OTPPaymentFrequency,''))) = 'Days'
AND OTPPaymentFrequencyUnit NOT IN(28, 30);

INSERT INTO #Params
SELECT 'LeaseFinanceDetail: The Number of Payments given in Lease Payment Schedule does not match the number of payments given in Lease Finance Detail for [SequenceNumber] : [' + l.SequenceNumber + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseFinanceDetail AS lfd
INNER JOIN #ProcessableLeaseTemp AS l ON l.id = lfd.Id
INNER JOIN stgLeasePaymentSchedule AS lps ON lps.LeaseFinanceDetailId = lfd.Id
AND lps.PaymentType = 'FixedTerm'
GROUP BY l.Id
, l.SequenceNumber
, lfd.NumberOfPayments
HAVING COUNT(lps.Id) > 0
AND lfd.NumberOfPayments != COUNT(lps.Id);

INSERT INTO #Params
SELECT 'LeaseFinanceDetail: The Number of OTP Payments given in Lease Payment Schedule does not match the Number of OTP Payments given in Lease Finance Detail for [SequenceNumber] : [' + l.SequenceNumber + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseFinanceDetail AS lfd
JOIN #ProcessableLeaseTemp AS l ON l.id = lfd.Id
INNER JOIN stgLeasePaymentSchedule AS lps ON lps.LeaseFinanceDetailId = lfd.Id
AND lps.PaymentType = 'OTP'
GROUP BY l.Id
, l.SequenceNumber
, lfd.NumberOfOTPPayments
HAVING COUNT(lps.Id) > 0
AND lfd.NumberOfOTPPayments != COUNT(lps.Id);

UPDATE stgLeaseAsset
SET
stgLeaseAsset.R_TaxDepTemplateId = tdt.Id
FROM TaxDepTemplates tdt
WHERE stgLeaseAsset.TaxDepTemplate = tdt.Name
AND LeaseId IN
(
SELECT ID
FROM #ProcessableLeaseTemp
);

INSERT INTO #Params
SELECT CASE WHEN ( lfdt.PaymentStreamFrequency = 'Monthly' OR lfdt.PaymentStreamFrequency = 'Quarterly' OR lfdt.PaymentStreamFrequency = 'HalfYearly' OR lfdt.PaymentStreamFrequency = 'Yearly')
	     THEN 'LeaseFinanceDetail: Compounding Frequency must be either monthly or equal to payment frequency for [SequenceNumber] : [' + l.SequenceNumber + ' ]'
		 ELSE
		   'LeaseFinanceDetail: Compounding Frequency must be monthly for [SequenceNumber] : [' + l.SequenceNumber + ' ]' 
		 END
, l.Id
, l.SequenceNumber
FROM stgLeaseFinanceDetail AS lfdt WITH(NOLOCK)
JOIN #ProcessableLeaseTemp AS l ON l.id = lfdt.Id
WHERE lfdt.CompoundingFrequency <> (CASE WHEN lfdt.CompoundingFrequency = 'Monthly' 
									   THEN lfdt.CompoundingFrequency
									   WHEN ( lfdt.PaymentStreamFrequency = 'Monthly' OR lfdt.PaymentStreamFrequency = 'Quarterly' OR lfdt.PaymentStreamFrequency = 'HalfYearly' OR lfdt.PaymentStreamFrequency = 'Yearly')
                                       THEN    lfdt.PaymentStreamFrequency 
		                               ELSE  'Monthly' END 
								 );

INSERT INTO #Params 
SELECT 'The following Lease: '+ Temp.SequenceNumber+' should have atleast one lease asset associated to it.' ,Temp.Id,Temp.SequenceNumber
FROM
(
	SELECT l.Id,l.SequenceNumber
	FROM 
		#ProcessableLeaseTemp l with(nolock)
		LEFT JOIN stgLeaseAsset leaseasset with(nolock) ON l.id = leaseasset.leaseid
	    WHERE leaseasset.Id IS NULL
)AS Temp

INSERT INTO #Params
SELECT 'LeaseAsset: TaxDepTemplate provided is not valid for [SequenceNumber, TaxDepTemplate] :[' + l.SequenceNumber + ',' + la.TaxDepTemplate + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseAsset AS la WITH(NOLOCK)
JOIN #ProcessableLeaseTemp AS l ON l.id = la.LeaseId
WHERE la.R_TaxDepTemplateId IS NULL
AND LTRIM(RTRIM(ISNULL(la.TaxDepTemplate ,''))) <> '';

UPDATE stgLeaseAsset
SET
stgLeaseAsset.R_BookDepreciationTemplateId = bdt.Id
FROM BookDepreciationTemplates bdt
WHERE stgLeaseAsset.BookDepreciationTemplateName = bdt.Name
AND LeaseId IN
(
SELECT ID
FROM #ProcessableLeaseTemp
);

INSERT INTO #Params
SELECT 'LeaseAsset: BookDepreciationTemplateName provided is not valid for [SequenceNumber, BookDepreciationTemplateName] :[' + l.SequenceNumber + ',' + la.BookDepreciationTemplateName + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseAsset AS la WITH(NOLOCK)
JOIN #ProcessableLeaseTemp AS l ON l.id = la.LeaseId
WHERE la.R_BookDepreciationTemplateId IS NULL
AND LTRIM(RTRIM(ISNULL(la.BookDepreciationTemplateName ,''))) <> '';

UPDATE stgLeaseInterestRate
SET
stgLeaseInterestRate.R_FloatRateIndexId = fri.Id
FROM FloatRateIndexes fri
WHERE stgLeaseInterestRate.FloatRateIndexName = fri.Name
AND LeaseFinanceDetailId IN
(
SELECT ID
FROM #ProcessableLeaseTemp
);

INSERT INTO #Params
SELECT 'LeaseInterestRate: FloatRateIndexName provided is not valid for [SequenceNumber, FloatRateIndexName] :[' + l.SequenceNumber + ',' + lir.FloatRateIndexName + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseInterestRate AS lir WITH(NOLOCK)
JOIN #ProcessableLeaseTemp AS l ON l.id = lir.LeaseFinanceDetailId
WHERE lir.R_FloatRateIndexId IS NULL
AND LTRIM(RTRIM(ISNULL(lir.FloatRateIndexName ,''))) <> '';

INSERT INTO #Params
SELECT 'LeaseInterestRate: HighPrimeInterest cannot be true when FloatRate is false'
, l.Id
, l.SequenceNumber
FROM stgLeaseInterestRate AS lir WITH(NOLOCK)
JOIN #ProcessableLeaseTemp AS l ON l.id = lir.LeaseFinanceDetailId
WHERE lir.IsHighPrimeInterest = 1
AND lir.IsFloatRate = 0;

UPDATE stgLeaseLateFeeReceivableType
SET
stgLeaseLateFeeReceivableType.R_ReceivableTypeId = rt.Id
FROM dbo.ReceivableTypes rt
WHERE stgLeaseLateFeeReceivableType.ReceivableTypeName = rt.Name
AND LeaseLateFeeId IN
(
SELECT ID
FROM #ProcessableLeaseTemp
);

INSERT INTO #Params
SELECT 'LeaseLateFeeReceivableType: ReceivableTypeName provided is not valid for [SequenceNumber, ReceivableTypeName] :[' + l.SequenceNumber + ',' + llfrt.ReceivableTypeName + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseLateFeeReceivableType AS llfrt
JOIN #ProcessableLeaseTemp AS l ON l.id = llfrt.LeaseLateFeeId
WHERE llfrt.R_ReceivableTypeId IS NULL
AND LTRIM(RTRIM(ISNULL(llfrt.ReceivableTypeName ,''))) <> '';

UPDATE stgLeaseLateFee
SET
stgLeaseLateFee.R_LateFeeTemplateId = lft.Id
FROM dbo.LateFeeTemplates lft
WHERE stgLeaseLateFee.LateFeeTemplateName = lft.Name
AND stgLeaseLateFee.Id IN
(
SELECT ID
FROM #ProcessableLeaseTemp
);

INSERT INTO #Params
SELECT 'LeaseLateFee: LateFeeTemplateName provided is not valid for [SequenceNumber, LateFeeTemplateName] :[' + l.SequenceNumber + ',' + llf.LateFeeTemplateName + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseLateFee AS llf
JOIN #ProcessableLeaseTemp AS l ON l.id = llf.Id
WHERE llf.R_LateFeeTemplateId IS NULL
AND LTRIM(RTRIM(ISNULL(llf.LateFeeTemplateName ,''))) <> '';
--=============================stgLeaseBilling=================================
UPDATE stgLeaseBilling
SET
stgLeaseBilling.R_PreACHNotificationEmailTemplateId = et.Id
FROM dbo.EmailTemplates et
WHERE stgLeaseBilling.PreNotificationEmailTemplate = et.Name
AND stgLeaseBilling.Id IN
(
SELECT ID
FROM #ProcessableLeaseTemp
);

INSERT INTO #Params
SELECT 'LeaseBilling: PreNotificationEmailTemplate provided is not valid for [SequenceNumber, PreNotificationEmailTemplate] :[' + l.SequenceNumber + ',' + lb.PreNotificationEmailTemplate + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseBilling AS lb
JOIN #ProcessableLeaseTemp AS l ON l.id = lb.Id
WHERE lb.R_PreACHNotificationEmailTemplateId IS NULL
AND LTRIM(RTRIM(ISNULL(ISNULL(lb.PreNotificationEmailTemplate, '') ,''))) <> '';

UPDATE stgLeaseBilling
SET
stgLeaseBilling.R_PostACHNotificationEmailTemplateId = et.Id
FROM dbo.EmailTemplates et
WHERE stgLeaseBilling.PostNotificationEmailTemplate = et.Name
AND stgLeaseBilling.Id IN
(
SELECT ID
FROM #ProcessableLeaseTemp
);

INSERT INTO #Params
SELECT 'LeaseBilling: PostNotificationEmailTemplate provided is not valid for [SequenceNumber, PostNotificationEmailTemplate] :[' + l.SequenceNumber + ',' + lb.PostNotificationEmailTemplate + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseBilling AS lb
JOIN #ProcessableLeaseTemp AS l ON l.id = lb.Id
WHERE lb.R_PostACHNotificationEmailTemplateId IS NULL
AND LTRIM(RTRIM(ISNULL(lb.PostNotificationEmailTemplate, ''))) <> '';

UPDATE stgLeaseBilling
SET
stgLeaseBilling.R_ReturnACHNotificationEmailTemplateId = et.Id
FROM dbo.EmailTemplates et
WHERE stgLeaseBilling.ReturnNotificationEmailTemplate = et.Name
AND stgLeaseBilling.Id IN
(
SELECT ID
FROM #ProcessableLeaseTemp
);

INSERT INTO #Params
SELECT 'LeaseBilling: ReturnNotificationEmailTemplate provided is not valid for [SequenceNumber, ReturnNotificationEmailTemplate] :[' + l.SequenceNumber + ',' + lb.ReturnNotificationEmailTemplate + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseBilling AS lb
JOIN #ProcessableLeaseTemp AS l ON l.id = lb.Id
WHERE lb.R_ReturnACHNotificationEmailTemplateId IS NULL
AND LTRIM(RTRIM(ISNULL(lb.ReturnNotificationEmailTemplate, ''))) <> '';

UPDATE stgLeaseBilling
SET
stgLeaseBilling.R_ReceiptLegalEntityId = le.Id
FROM dbo.LegalEntities le
WHERE stgLeaseBilling.ReceiptLegalEntityNumber = le.LegalEntityNumber
AND stgLeaseBilling.Id IN
(
SELECT ID
FROM #ProcessableLeaseTemp
);
UPDATE stgLeaseBilling
SET
R_ReceiptLegalEntityId = le.Id
FROM stgLeaseBilling lb
INNER JOIN #ProcessableLeaseTemp l ON l.Id = lb.Id
INNER JOIN LegalEntities le ON le.LegalEntityNumber = lb.ReceiptLegalEntityNumber;

INSERT INTO #Params
SELECT 'LeaseBilling: ReceiptLegalEntity provided is not valid for [SequenceNumber, ReceiptLegalEntityNumber] :[' + l.SequenceNumber + ',' + lb.ReceiptLegalEntityNumber + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseBilling AS lb
JOIN #ProcessableLeaseTemp AS l ON l.id = lb.Id
WHERE lb.R_ReceiptLegalEntityId IS NULL
AND LTRIM(RTRIM(ISNULL(lb.ReceiptLegalEntityNumber ,''))) <> '';
--=============================stgLeaseBillingPreference=================================
UPDATE stgLeaseBillingPreference
SET
stgLeaseBillingPreference.R_ReceivableTypeId = rt.Id
FROM dbo.ReceivableTypes rt
WHERE stgLeaseBillingPreference.ReceivableType = rt.Name
AND LeaseBillingId IN
(
SELECT ID
FROM #ProcessableLeaseTemp
);

INSERT INTO #Params
SELECT 'LeaseBillingPreference: ReceivableType provided is not valid for [SequenceNumber, ReceivableType] :[' + l.SequenceNumber + ',' + lbp.ReceivableType + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseBillingPreference AS lbp
JOIN #ProcessableLeaseTemp AS l ON l.id = lbp.LeaseBillingId
WHERE lbp.R_ReceivableTypeId IS NULL
AND LTRIM(RTRIM(ISNULL(lbp.ReceivableType ,'_'))) <> '_';

UPDATE stgLeaseBlendedItem
SET
stgLeaseBlendedItem.R_BlendedItemCodeId = bic.Id
FROM BlendedItemCodes bic WITH(NOLOCK)
WHERE bic.Name = stgLeaseBlendedItem.BlendedItemCode
AND LeaseId IN
(
SELECT ID
FROM #ProcessableLeaseTemp
);

INSERT INTO #Params
SELECT 'LeaseBlendedItem: BlendedItemCode provided is not valid for [SequenceNumber, BlendedItemCode] :[' + l.SequenceNumber + ',' + lbi.BlendedItemCode + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseBlendedItem AS lbi WITH(NOLOCK)
JOIN #ProcessableLeaseTemp AS l ON l.id = lbi.LeaseId
WHERE lbi.R_BlendedItemCodeId IS NULL
AND LTRIM(RTRIM(ISNULL(lbi.BlendedItemCode ,''))) <> '';

UPDATE stgLeaseBlendedItem
SET
stgLeaseBlendedItem.R_ReceivableCodeId = rc.Id
FROM dbo.ReceivableCodes rc WITH(NOLOCK)
WHERE stgLeaseBlendedItem.ReceivableCodeName = rc.Name
AND LeaseId IN
(
SELECT ID
FROM #ProcessableLeaseTemp
);
INSERT INTO #Params
SELECT 'LeaseBlendedItem: ReceivableCodeName provided is not valid for [SequenceNumber, ReceivableCodeName] :[' + l.SequenceNumber + ',' + lbi.ReceivableCodeName + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseBlendedItem AS lbi WITH(NOLOCK)
JOIN #ProcessableLeaseTemp AS l ON l.id = lbi.LeaseId
WHERE lbi.R_ReceivableCodeId IS NULL
AND LTRIM(RTRIM(ISNULL(lbi.ReceivableCodeName ,''))) <> '';

UPDATE stgLeaseBlendedItem
SET
stgLeaseBlendedItem.R_PayableCodeId = pc.Id
FROM dbo.PayableCodes pc WITH(NOLOCK)
WHERE stgLeaseBlendedItem.PayableCodeName = pc.Name
AND LeaseId IN
(
SELECT ID
FROM #ProcessableLeaseTemp
);

INSERT INTO #Params
SELECT 'stgLeaseBlendedItem: PayableCodeName provided is not valid for [SequenceNumber, PayableCodeName] :[' + l.SequenceNumber + ',' + lbi.PayableCodeName + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseBlendedItem AS lbi WITH(NOLOCK)
JOIN #ProcessableLeaseTemp AS l ON l.id = lbi.LeaseId
WHERE lbi.R_PayableCodeId IS NULL
AND LTRIM(RTRIM(ISNULL(lbi.PayableCodeName ,''))) <> '';

INSERT INTO #Params
SELECT 'ETC blended items can only exist for Operating / Direct Finance leases for [SequenceNumber] :[' + l.SequenceNumber + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseBlendedItem AS lbi WITH(NOLOCK)
JOIN #ProcessableLeaseTemp AS l ON l.id = lbi.LeaseId
JOIN stgLeaseFinanceDetail lfd ON lfd.Id = l.id
WHERE lbi.IsETC = 1
AND NOT(lfd.ContractType = 'Operating'
OR lfd.ContractType = 'DirectFinance');

UPDATE stgLeaseBlendedItem
SET
stgLeaseBlendedItem.R_RecognitionGlTransactionType = (CASE
WHEN Type = 'IDC'
OR Type = 'Expense'
THEN 'BlendedExpenseRecognition'
ELSE 'BlendedIncomeRecognition'
END)
WHERE LeaseId IN
(
SELECT ID
FROM #ProcessableLeaseTemp
);
UPDATE stgLeaseBlendedItem
SET
stgLeaseBlendedItem.R_GlTransactionType = (CASE
WHEN Type = 'IDC'
OR Type = 'Expense'
THEN 'BlendedExpenseSetup'
ELSE 'BlendedIncomeSetup'
END)
WHERE LeaseId IN
(
SELECT ID
FROM #ProcessableLeaseTemp
);
UPDATE stgLeaseBlendedItem
SET
stgLeaseBlendedItem.R_BookingGLTemplateId = g.Id
FROM dbo.GLTemplates g WITH(NOLOCK)
INNER JOIN dbo.GLTransactionTypes gt WITH(NOLOCK) ON g.GLTransactionTypeId = gt.Id
WHERE stgLeaseBlendedItem.BookingGLTemplateName = g.Name
AND gt.Name = stgLeaseBlendedItem.R_GlTransactionType
AND LeaseId IN
(
SELECT ID
FROM #ProcessableLeaseTemp
);
INSERT INTO #Params
SELECT 'LeaseBlendedItem: BookingGLTemplateName provided is not valid for [SequenceNumber, BookingGLTemplateName] :[' + l.SequenceNumber + ',' + lbi.BookingGLTemplateName + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseBlendedItem AS lbi WITH(NOLOCK)
JOIN #ProcessableLeaseTemp AS l WITH(NOLOCK) ON l.id = lbi.LeaseId
WHERE lbi.R_BookingGLTemplateId IS NULL
AND LTRIM(RTRIM(ISNULL(lbi.BookingGLTemplateName ,''))) <> '';

UPDATE stgLeaseBlendedItem
SET
stgLeaseBlendedItem.R_RecognitionGLTemplateId = g.Id
FROM dbo.GLTemplates g WITH(NOLOCK)
INNER JOIN dbo.GLTransactionTypes gt WITH(NOLOCK) ON g.GLTransactionTypeId = gt.Id
WHERE stgLeaseBlendedItem.RecognitionGLTemplateName = g.Name
AND gt.Name = stgLeaseBlendedItem.R_RecognitionGlTransactionType
AND LeaseId IN
(
SELECT ID
FROM #ProcessableLeaseTemp
);

INSERT INTO #Params
SELECT 'LeaseBlendedItem: RecognitionGLTemplateName provided is not valid for [SequenceNumber, RecognitionGLTemplateName] :[' + l.SequenceNumber + ',' + lbi.RecognitionGLTemplateName + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseBlendedItem AS lbi
JOIN #ProcessableLeaseTemp AS l ON l.id = lbi.LeaseId
WHERE lbi.R_RecognitionGLTemplateId IS NULL
AND LTRIM(RTRIM(ISNULL(lbi.RecognitionGLTemplateName ,''))) <> '';

UPDATE stgLeaseBlendedItem
SET
stgLeaseBlendedItem.R_TaxDepTemplateId = tdt.Id
FROM dbo.TaxDepTemplates tdt
WHERE stgLeaseBlendedItem.TaxDepTemplateName = tdt.Name
AND LeaseId IN
(
SELECT ID
FROM #ProcessableLeaseTemp
);

INSERT INTO #Params
SELECT 'LeaseBlendedItem: TaxDepTemplateName provided is not valid for [SequenceNumber, TaxDepTemplateName] :[' + l.SequenceNumber + ',' + lbi.TaxDepTemplateName + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseBlendedItem AS lbi
JOIN #ProcessableLeaseTemp AS l ON l.id = lbi.LeaseId
WHERE lbi.R_TaxDepTemplateId IS NULL
AND LTRIM(RTRIM(ISNULL(lbi.TaxDepTemplateName ,''))) <> '';

INSERT INTO #Params
SELECT 'LeaseBlendedItem: StartDate should be on or beyond the CommencementDate.[SequenceNumber, BlendedItemName, CommencementDate, StartDate] :[' + l.SequenceNumber + ', ' + lbi.Name + ', ' + ISNULL(CONVERT(NVARCHAR(10), lfd.CommencementDate), 'NULL') + ', ' + ISNULL(CONVERT(NVARCHAR(10), lbi.StartDate), 'NULL') + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseBlendedItem AS lbi
JOIN #ProcessableLeaseTemp AS l ON l.id = lbi.LeaseId
JOIN stgLeaseFinanceDetail lfd ON lfd.Id = l.Id
WHERE(lbi.StartDate IS NULL
OR (lbi.StartDate < lfd.CommencementDate))
AND BookRecognitionMode != 'RecognizeImmediately';

INSERT INTO #Params
SELECT 'LeaseBlendedItem: EndDate should not be null.[SequenceNumber, BlendedItemName] :[' + l.SequenceNumber + ', ' + lbi.Name + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseBlendedItem AS lbi
JOIN #ProcessableLeaseTemp AS l ON l.id = lbi.LeaseId
JOIN stgLeaseFinanceDetail lfd ON lfd.Id = l.Id
WHERE lbi.EndDate IS NULL
AND lbi.BookRecognitionMode != 'RecognizeImmediately'
AND lbi.Type != 'IDC';

INSERT INTO #Params
SELECT 'LeaseBlendedItem: Start Date must be on or before End Date.[SequenceNumber, BlendedItemName, StartDate, EndDate] :[' + l.SequenceNumber + ', ' + lbi.Name + ', ' + ISNULL(CONVERT(NVARCHAR(10), lbi.StartDate), 'NULL') + ', ' + ISNULL(CONVERT(NVARCHAR(10), lbi.EndDate), 'NULL') + ' ]'
, l.Id
, l.SequenceNumber
FROM stgLeaseBlendedItem AS lbi
JOIN #ProcessableLeaseTemp AS l ON l.id = lbi.LeaseId
JOIN stgLeaseFinanceDetail lfd ON lfd.Id = l.Id
WHERE(lbi.StartDate IS NOT NULL
AND (lbi.StartDate > lbi.EndDate))
AND lbi.BookRecognitionMode != 'RecognizeImmediately'
AND lbi.Type != 'IDC';

INSERT INTO #Params
SELECT 'Lease can have only one primary employee assignment for a given role function {Role Function Name : ' +eal.RoleFunctionName+' Lease Id : ' +CONVERT(NVARCHAR(MAX), l.Id)+'}'
    , l.Id
	, l.SequenceNumber
FROM #ProcessableLeaseTemp l  
INNER JOIN stgEmployeesAssignedToLease eal ON l.Id = eal.LeaseId
WHERE eal.IsPrimary = 1 AND LTRIM(RTRIM(ISNULL(eal.RoleFunctionName, '' ))) <> ''
GROUP BY l.SequenceNumber , l.Id, eal.RoleFunctionName
HAVING COUNT(*) > 1

SET @FailedRecords =
(
SELECT ISNULL(COUNT(DISTINCT EntityId), 0)
FROM #Params
);
MERGE stgProcessingLog AS ProcessingLog
USING
(
SELECT Id
FROM dbo.stgLease
WHERE IsMigrated = 0
AND Id NOT IN
(
SELECT EntityId
FROM #Params
)
) AS ProcessedLeases
ON(ProcessingLog.StagingRootEntityId = ProcessedLeases.Id
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
(ProcessedLeases.Id
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
EntityId
FROM #Params
) AS ErrorLeases
ON(ProcessingLog.StagingRootEntityId = ErrorLeases.EntityId
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
(ErrorLeases.EntityId
, @UserId
, @CreatedTime
, @ModuleIterationStatusId
)
OUTPUT Inserted.Id
, ErrorLeases.EntityId
INTO #FailedProcessingLogs;
INSERT INTO stgProcessingLogDetail
(Message
, Type
, CreatedById
, CreatedTime
, ProcessingLogId
)
SELECT #Params.CSV
, 'Error'
, @UserId
, @CreatedTime
, #FailedProcessingLogs.Id
FROM #Params
JOIN #FailedProcessingLogs ON #Params.EntityId = #FailedProcessingLogs.LeaseId;
DROP TABLE #FailedProcessingLogs;
DROP TABLE #Params;
DROP TABLE #CreatedProcessingLogs;
DROP TABLE #PortfolioParameters;
DROP TABLE #GlTemplateTemp;
DROP TABLE #PartyBankAccountDetails;
DROP TABLE #LeaseTable;
DROP TABLE #LeaseFinanceDetailTable;
DROP TABLE #ProcessableLeaseTemp;
END;

GO

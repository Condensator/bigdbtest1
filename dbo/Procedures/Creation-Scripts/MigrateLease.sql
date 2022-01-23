SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE  PROCEDURE [dbo].[MigrateLease]  
(   
	 @UserId BIGINT
	 ,@CreatedTime DATETIMEOFFSET= NULL
	 ,@ModuleIterationStatusId BIGINT
	 ,@ProcessedRecords BIGINT OUTPUT
	 ,@FailedRecords BIGINT OUTPUT
	 ,@ToolIdentifier INT
)  
AS  
--DECLARE @UserId BIGINT;
--DECLARE @FailedRecords BIGINT;
--DECLARE @ProcessedRecords BIGINT;
--DECLARE @CreatedTime DATETIMEOFFSET;
--DECLARE @ModuleIterationStatusId BIGINT;
--SET @UserId = 1;
--SET @CreatedTime = SYSDATETIMEOFFSET();	
--SELECT @ModuleIterationStatusId=MAX(ModuleIterationStatusId) from stgProcessingLog;
BEGIN  
SET NOCOUNT ON;  
set XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED  
ALTER TABLE ReceivableDetails NOCHECK CONSTRAINT EReceivable_ReceivableDetails
SET @FailedRecords = 0  
SET @ProcessedRecords = 0  
DECLARE @u_ConversionSource nvarchar(50); 
DECLARE @ETCAllowableCredit DECIMAL(16,2);
DECLARE @UseTaxBooks nvarchar(50);
DECLARE @BillToLevel nvarchar(50);
DECLARE @TakeCount INT = 1000; 
DECLARE @MaxLeaseId INT = 0;
DECLARE @BatchCount INT = 0;
SELECT @u_ConversionSource = Value FROM GlobalParameters WHERE Category ='Migration' AND Name = 'ConversionSource'
SELECT @ETCAllowableCredit = Value FROM GlobalParameters WHERE Category ='ETC' AND Name = 'AllowableCredit'
SELECT @UseTaxBooks = Value FROM GlobalParameters WHERE Category ='TaxDepAmortizationGL' AND Name = 'UseTaxBooks'
SELECT @BillToLevel = Value FROM GlobalParameters WHERE Category ='LeaseProfile' AND Name = 'BillToLevel'
CREATE TABLE #CommencedLeaseIds(Id BIGINT);  
CREATE TABLE #LeaseYieldValues (Yield NVARCHAR(50) NOT NULL);
CREATE TABLE #Params(CSV NVARCHAR(MAX) NOT NULL, EntityId BIGINT, SequenceNumber NVARCHAR(MAX));  
CREATE TABLE #FailedProcessingLogs([Action] NVARCHAR(10) NOT NULL, [Id] BIGINT NOT NULL, [LeaseId] BIGINT NOT NULL); 
CREATE TABLE #RequiredUpdation (LeaseId BIGINT ,R_ContractId BIGINT,R_LeaseFinanceId BIGINT)
INSERT INTO #LeaseYieldValues(Yield) VALUES ('ImplicitInterestRate'),('MISF'), ('IRR'), ('EBOYield'), ('ROE')
SELECT Category, Name, Value, PortfolioId INTO #PortfolioParameters
FROM PortfolioParameterConfigs AS ppc
INNER JOIN PortfolioParameters AS pp WITH (NOLOCK) ON ppc.Id =  pp.PortfolioParameterConfigId 	 	 
SELECT gt.Id , gt.Name, gtt.Name GLTransactionType, gt.GLConfigurationId, LegalEntityNumber INTO #GlTemplateTemp  
FROM GLTemplates gt   
JOIN GLTransactionTypes gtt on gt.GLTransactionTypeId = gtt.Id  
JOIN LegalEntities le on gt.GLConfigurationId = le.GLConfigurationId
WHERE gt.IsActive = 1 AND gtt.IsActive = 1 AND le.Status ='Active'
SELECT rc.Name AS ReceivableCodeName, gt.GLConfigurationId, rt.Name AS ReceivableTypeName, gtt.Name AS GLTransactionTypeName, rc.Id INTO #ReceivableCodeTemp
FROM ReceivableCodes rc
INNER JOIN GLTemplates gt ON rc.GLTemplateId = gt.Id
INNER JOIN ReceivableTypes rt ON rc.ReceivableTypeId = rt.Id
INNER JOIN GLTransactionTypes gtt on gt.GLTransactionTypeId = gtt.Id
WHERE rc.IsActive = 1 AND gt.IsActive = 1 AND rt.IsActive = 1 AND gtt.IsActive = 1
SELECT PartyId, BanAccountUniqueIdentifier = BA.UniqueIdentifier, BankAccountId
INTO #PartyBankAccountDetails
FROM PartyBankAccounts PBA
INNER JOIN Parties ON Parties.Id = PBA.PartyId
INNER JOIN BankAccounts BA ON BA.Id = PBA.BankAccountId AND (BA.AutomatedPaymentMethod='ACHOrPAP' OR BA.AutomatedPaymentMethod='CreditCard') AND BA.IsActive=1
GROUP BY PartyId, BA.UniqueIdentifier, BankAccountId
Select @ProcessedRecords = ISNULL(COUNT(Id), 0) FROM stgLease WHERE IsMigrated = 0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier) And IsFailed = 0  
DECLARE @count INT = (SELECT COUNT(*) FROM stgLease WHERE IsMigrated = 0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier) AND IsFailed = 0)  
DECLARE @Module VARCHAR(50) = NULL
SET @Module = (SELECT StgModule.Name FROM StgModule INNER JOIN StgModuleIterationStatus ON StgModule.Id = StgModuleIterationStatus.ModuleId WHERE StgModuleIterationStatus.Id = @ModuleIterationStatusId)
EXEC ResetStagingTempFields @Module , @ToolIdentifier
DECLARE @SkipCount INT = 0
WHILE  @SkipCount <@count 
BEGIN  
BEGIN TRY 
CREATE TABLE #CreatedProcessingLogs ([Id] bigint NOT NULL);
CREATE TABLE #CreatedContractIds(InsertedContractId BIGINT NOT NULL, Id BIGINT NOT NULL);  
CREATE TABLE #InsertedTaxExemptRuleIds(Id BIGINT, ContractId BIGINT);  
CREATE TABLE #InsertedContractOriginationIds(Id BIGINT, ContractId BIGINT);  
CREATE TABLE #InsertedContractOriginationServicingDetailIds(Id BIGINT, ContractId BIGINT, ContractOriginationId BIGINT);  
CREATE TABLE #CreatedLeaseFinanceIds(InsertedId BIGINT NOT NULL, ContractId BIGINT, Id BIGINT NOT NULL);  
CREATE TABLE #CreatedLeaseAssetIds(InsertedId BIGINT NOT NULL, AssetId BIGINT); 
SELECT TOP (@TakeCount) ID , SequenceNumber INTO #ProcessableLeaseTemp  
FROM stgLease WITH (NOLOCK)  
WHERE IsMigrated = 0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier) AND IsFailed = 0  AND stgLease.Id >@MaxLeaseId;
SELECT @MaxLeaseId = ISNULL(MAX(Id),0) FROM #ProcessableLeaseTemp
SELECT @BatchCount = ISNULL(COUNT(Id),0) FROM #ProcessableLeaseTemp
CREATE NONCLUSTERED INDEX IX_Id 
ON #ProcessableLeaseTemp(Id)

CREATE NONCLUSTERED INDEX IX_Id 
ON #CreatedLeaseFinanceIds(Id)

CREATE NONCLUSTERED INDEX IX_InsertedId 
ON #CreatedLeaseFinanceIds(InsertedId)
--=============================stgLease=================================  
CREATE TABLE #LeaseTable
(
 Id BIGINT NULL
,WaiveIfLateFeeBelowAmount DECIMAL(16,2)
,WaiveIfInvoiceAmountBelowAmount DECIMAL(16,2)
,ReceiptLegalEntityId BIGINT
,Currency nvarchar(10)
)
UPDATE stgLease SET R_OriginatingLineofBusinessid = lb.Id
FROM stgLease AS l WITh (NOLOCK) 
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id 
LEFT JOIN LineofBusinesses AS lb WITH (NOLOCK) ON CASE WHEN l.HoldingStatus='HFS' THEN l.OriginatingLineofBusinessName ELSE l.LineOfBusinessName END = lb.Name
UPDATE stgLease SET R_AcquisitionId = pp.Value, R_CustomerId = p.Id, R_LineofBusinessId = lb.Id, R_LegalEntityId = le.Id, R_BranchId = branch.Id, R_CustomerClass = customerclass.Class, R_BillToId = b.Id 
FROM stgLease AS l  WITH (NOLOCK)  
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id  
LEFT JOIN LegalEntities AS le WITH (NOLOCK) ON l.LegalEntityNumber = le.LegalEntityNumber
LEFT JOIN Branches AS branch WITH (NOLOCK) ON le.Id = branch.LegalEntityId AND branch.BranchName = l.BranchName
LEFT JOIN Parties AS p WITH (NOLOCK) ON l.CustomerPartyNumber = p.PartyNumber
LEFT JOIN Customers AS customer WITH (NOLOCK) ON p.Id = customer.Id
LEFT JOIN CustomerClasses AS customerclass WITH (NOLOCK) ON customer.CustomerClassId = customerclass.Id
LEFT JOIN Billtoes AS b WITH (NOLOCK) ON l.BillToName = b.Name AND p.ID = b.CustomerId  
LEFT JOIN LineofBusinesses AS lb WITH (NOLOCK) ON l.LineOfBusinessName = lb.Name  
LEFT JOIN BusinessUnits AS bu WITH (NOLOCK) ON le.BusinessUnitId = bu.Id
LEFT JOIN #PortfolioParameters pp WITH (NOLOCK) ON pp.Category = 'GL' AND pp.Name = 'AcquisitionId'  AND pp.PortfolioId  = bu.PortfolioId
Update stgLease Set AccountingStandard = IsNULL(LE.AccountingStandard, '_') 
From stgLease As l WITH (NOLOCK) 
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id  
INNER JOIN LegalEntities LE WITH (NOLOCK) ON l.LegalEntityNumber = LE.LegalEntityNumber
WHERE l.AccountingStandard Is NULL Or l.AccountingStandard = '_'
UPDATE stgLease set R_ReceiptHierarchyTemplateId = rht.Id, R_CurrencyId = c.Id, R_TaxProductTypeId = tpt.Id, R_InstrumentTypeId = it.Id, R_ReferralBankerId = rb.Id, R_OriginationSourceTypeId = ost.Id, R_OriginationSourceId = p.Id, R_CountryId = ct.Id, R_OriginationChannelId = ost1.Id
FROM stgLease AS l  WITH (NOLOCK)  
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id  
LEFT JOIN ReceiptHierarchyTemplates AS rht WITH (NOLOCK) ON l.ReceiptHierarchyTemplateName = rht.Name  
LEFT JOIN CurrencyCodes AS cc WITH (NOLOCK) ON cc.ISO = l.Currency  
LEFT JOIN Currencies AS c WITH (NOLOCK) ON cc.Id = c.CurrencyCodeId  
LEFT JOIN TaxProductTypes AS tpt WITH (NOLOCK) ON l.TaxProductType = tpt.ProductType  
LEFT JOIN InstrumentTypes AS it WITH (NOLOCK) ON l.InstrumentTypeCode = it.Code  
LEFT JOIN Users AS rb WITH (NOLOCK) ON l.ReferralBankerLoginName = rb.LoginName  
LEFT JOIN Countries As ct WITH(NOLOCK) on l.Country = ct.ShortName
LEFT JOIN OriginationSourceTypes AS ost WITH (NOLOCK) ON l.OriginationSourceTypeName = ost.Name  
LEFT JOIN OriginationSourceTypes AS ost1 WITH (NOLOCK) ON l.OriginationSourceChannelName = ost.Name 
LEFT JOIN Parties AS p WITH (NOLOCK) ON l.OriginationSourceNumber = p.PartyNumber 	
UPDATE stgLease set R_ProductAndServiceTypeConfigId = pastc.Id, R_ProgramIndicatorConfigId = pic.Id, R_CostCenterId = ccc.Id, R_LanguageId = lc.Id, R_MasterAgreementId = ma.Id, R_ScrapePayableCodeId = pc.Id, R_ProgramVendorOriginationSourceId = p.Id, R_DocFeeReceivableCodeId = rc.Id
FROM stgLease AS l  WITH (NOLOCK)  
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id
LEFT JOIN LegalEntities AS le WITH (NOLOCK) ON l.LegalEntityNumber = le.LegalEntityNumber
LEFT JOIN CostCenterConfigs AS ccc WITH (NOLOCK) ON l.CostCenterConfigName = ccc.CostCenter  
LEFT JOIN ProductAndServiceTypeConfigs AS pastc WITH (NOLOCK) ON l.ProductAndServiceTypeConfigCode = pastc.ProductAndServiceTypeCode  
LEFT JOIN ProgramIndicatorConfigs AS pic WITH (NOLOCK) ON l.ProgramIndicatorConfigName = pic.ProgramIndicatorCode  
LEFT JOIN LanguageConfigs AS lc WITH (NOLOCK) ON l.Language = lc.Name  
LEFT JOIN MasterAgreements AS ma WITH (NOLOCK) ON l.MasterAgreementNumber = ma.Number  
LEFT JOIN PayableCodes AS pc WITH (NOLOCK) ON l.ScrapePayableCodeName = pc.Name  
LEFT JOIN Parties AS p WITH (NOLOCK) ON l.ProgramVendorOriginationSourceNumber = p.PartyNumber  
LEFT JOIN #ReceivableCodeTemp AS rc WITH (NOLOCK) ON l.DocFeeReceivableCodeName = rc.ReceivableCodeName AND le.GLConfigurationId = rc.GLConfigurationId AND rc.ReceivableTypeName IN ('Sundry','SundrySeparate')
UPDATE stgLease set R_RemitToId = rt2.Id, R_AcquiredPortfolioId = ap.Id, R_AcquisitionId = COALESCE(ap.AcquisitionId,l.R_AcquisitionId),R_OriginationFeeBlendedItemCodeId = bic.Id, R_OriginatorPayableRemitToId = rt.Id, R_DealProductTypeId = dpt.Id, R_DealTypeId = dt.Id,R_AgreementTypeDetailId = atd.Id
FROM stgLease AS l  WITH (NOLOCK)  
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id  
LEFT JOIN AcquiredPortfolios AS ap WITH (NOLOCK) ON l.AcquiredPortfolioName = ap.Name  
LEFT JOIN BlendedItemCodes AS bic WITH (NOLOCK) ON l.OriginationFeeBlendedItemCode = bic.Name  
LEFT JOIN RemitToes AS rt WITH (NOLOCK) ON l.OriginatorPayableRemitToUniqueIdentifier = rt.UniqueIdentifier  
LEFT JOIN RemitToes AS rt2 WITH (NOLOCK) ON l.RemitToUniqueIdentifier = rt2.UniqueIdentifier  
LEFT JOIN DealTypes AS dt WITH (NOLOCK) ON l.DealTypeName = dt.ProductType  
LEFT JOIN DealProductTypes AS dpt WITH (NOLOCK) ON l.DealProductTypeName = dpt.Name AND dt.Id = dpt.DealTypeId  
LEFT JOIN AgreementTypeConfigs AS atc WITH(NOLOCK) ON REPLACE(LTRIM(RTRIM( l.AgreementTypeName)), ' ', '') = REPLACE(LTRIM(RTRIM( atc.Name)), ' ', '')
LEFT JOIN AgreementTypes AS at WITH(NOLOCK) ON at.AgreementTypeConfigId = atc.Id
LEFT JOIN AgreementTypeDetails AS atd WITH (NOLOCK) ON atd.AgreementTypeId = at.Id AND atd.LineofBusinessId = R_LineofBusinessId AND atd.DealTypeId = dt.Id  

UPDATE stglease set R_QuoteLeaseTypeId = ql.Id
FROM stgLease AS l  WITH (NOLOCK)  
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id 
INNER JOIN QuoteLeaseTypes ql ON l.QuoteLeaseType = ql.Code and ql.IsActive=1



INSERT INTO #LeaseTable (
Id,
WaiveIfLateFeeBelowAmount,
WaiveIfInvoiceAmountBelowAmount,
ReceiptLegalEntityId,
Currency)
SELECT
 l.Id,
 pp2.Value AS WaiveIfLateFeeBelowAmount, 
 pp3.Value AS WaiveIfInvoiceAmountBelowAmount,
 DefaultReceiptLegalEntity.Id,
 l.Currency
FROM stgLease AS l  WITH (NOLOCK)  
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id 
LEFT JOIN LegalEntities le ON le.Id = l.R_LegalEntityId
LEFT JOIN BusinessUnits AS bu WITH (NOLOCK) ON le.BusinessUnitId = bu.Id
LEFT JOIN #PortfolioParameters pp2 WITH (NOLOCK) ON pp2.Category = 'LateFee' AND pp2.Name = 'WaiveIfLateFeeBelowAmount' AND pp2.PortfolioId  = bu.PortfolioId
LEFT JOIN #PortfolioParameters pp3 WITH (NOLOCK) ON pp3.Category = 'LateFee' AND pp3.Name = 'WaiveIfInvoiceAmountBelowAmount' AND pp3.PortfolioId  = bu.PortfolioId
LEFT JOIN #PortfolioParameters pp4 WITH (NOLOCK) ON pp4.Category = 'Receipt' AND pp4.Name = 'DefaultReceiptLegalEntity' AND pp4.PortfolioId  = bu.PortfolioId
LEFT JOIN LegalEntities AS DefaultReceiptLegalEntity ON DefaultReceiptLegalEntity.LegalEntityNumber = pp4.Value

INSERT INTO #Params  
SELECT 'Lease: Please Enter Quote Lease Type for Lease:['+l.SequenceNumber+' ]', l.Id, l.SequenceNumber  
FROM stgLease lease   
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lease.Id  
	   WHERE lease.R_QuoteLeaseTypeId IS NULL

INSERT INTO #Params
SELECT 'Lease: For Holding Status ''HFS'', OriginatingLineOfBusinessName should not be null. [SequenceNumber] :['+l.SequenceNumber+' ]', l.Id, l.SequenceNumber
FROM stgLease AS l WITH (NOLOCK)
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id
WHERE l.HoldingStatus = 'HFS' AND l.OriginatingLineofBusinessName is null
INSERT INTO #Params
SELECT 'Lease: SequenceNumber provided is already exists. [SequenceNumber] :['+l.SequenceNumber+' ]', l.Id, l.SequenceNumber
FROM stgLease AS l WITH (NOLOCK)
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id
INNER JOIN dbo.Contracts c On c.SequenceNumber=lt.SequenceNumber;
INSERT INTO #Params  
SELECT 'Lease: CustomerPartyNumber provided is not valid for [SequenceNumber, CustomerPartyNumber] :['+l.SequenceNumber+','+l.CustomerPartyNumber+' ]', l.Id, l.SequenceNumber  
FROM stgLease AS l WITH (NOLOCK)  
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id  
	   WHERE l.R_CustomerId IS NULL AND LTRIM(RTRIM(ISNULL(l.CustomerPartyNumber, '' ))) <> ''  ;

INSERT INTO #Params  
SELECT DISTINCT 'Lease: Alias must be unique with respect to the selected customer [Alias, CustomerPartyNumber] :['+l.Alias+','+l.CustomerPartyNumber+' ]', l.Id, l.SequenceNumber  
FROM stgLease AS l WITH (NOLOCK)  
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id  
JOIN LeaseFinances ON LeaseFinances.CustomerId = l.R_CustomerId AND LeaseFinances.IsCurrent = 1
JOIN Contracts ON Contracts.Id = LeaseFinances.ContractId WHERE Contracts.Alias = l.Alias
INSERT INTO #Params
SELECT 'Lease: LeaseFinance Detail should be provided for [SequenceNumber] :['+l.SequenceNumber+' ]', l.Id, l.SequenceNumber
FROM stgLease AS l WITH (NOLOCK)
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id  
LEFT JOIN stgLeaseFinanceDetail lfd ON lfd.Id=lt.Id WHERE lfd.Id IS NULL
INSERT INTO #Params  
SELECT DISTINCT 'Lease: Alias must be unique with respect to the selected customer [Alias, CustomerPartyNumber] :['+l.Alias+','+l.CustomerPartyNumber+' ]', l.Id, l.SequenceNumber  
FROM stgLease AS l WITH (NOLOCK)  
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id  
JOIN LeveragedLeases ON LeveragedLeases.CustomerId = l.R_CustomerId AND LeveragedLeases.IsCurrent = 1
JOIN Contracts ON Contracts.Id = LeveragedLeases.ContractId WHERE Contracts.Alias = l.Alias
INSERT INTO #Params  
SELECT 'Lease: BillToName provided is not valid for [SequenceNumber, BillToName] :['+l.SequenceNumber+','+l.BillToName+' ]', l.Id, l.SequenceNumber  
FROM stgLease AS l  WITH (NOLOCK)  
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id  
	   WHERE l.R_BillToId IS NULL AND LTRIM(RTRIM(ISNULL(l.BillToName, '' ))) <> ''  ;  
INSERT INTO #Params  
SELECT 'Lease: RemitToUniqueIdentifier provided is not valid for [SequenceNumber, RemitToUniqueIdentifier] :['+l.SequenceNumber+','+l.RemitToUniqueIdentifier+' ]', l.Id, l.SequenceNumber  
FROM stgLease AS l WITH (NOLOCK)  
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id  
	   WHERE l.R_RemitToId IS NULL AND LTRIM(RTRIM(ISNULL(l.RemitToUniqueIdentifier, '' ))) <> ''  ;  
INSERT INTO #Params  
SELECT 'Lease: ReceiptHierarchyTemplateName provided is not valid for [SequenceNumber, ReceiptHierarchyTemplateName] :['+l.SequenceNumber+','+l.ReceiptHierarchyTemplateName+' ]', l.Id, l.SequenceNumber  
FROM stgLease AS l WITH (NOLOCK)   
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id  
	   WHERE l.R_ReceiptHierarchyTemplateId IS NULL AND LTRIM(RTRIM(ISNULL(l.ReceiptHierarchyTemplateName, '' ))) <> ''  ;  
INSERT INTO #Params  
SELECT 'Lease: DealTypeName provided is not valid for [SequenceNumber, DealTypeName] :['+l.SequenceNumber+','+l.DealTypeName+' ]', l.Id, l.SequenceNumber  
FROM stgLease AS l WITH (NOLOCK)   
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id  
	   WHERE l.R_DealTypeId IS NULL AND LTRIM(RTRIM(ISNULL(l.DealTypeName, '' ))) <> ''  ;  
INSERT INTO #Params  
SELECT 'Lease: DealProductTypeName provided is not valid for [SequenceNumber, DealProductTypeName] :['+l.SequenceNumber+','+l.DealProductTypeName+' ]', l.Id, l.SequenceNumber  
FROM stgLease AS l WITH (NOLOCK)   
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id  
	   WHERE l.R_DealProductTypeId IS NULL AND LTRIM(RTRIM(ISNULL(l.DealProductTypeName, '_' ))) <> '_'  ;  
INSERT INTO #Params  
SELECT 'Lease: LineOfBusinessName provided is not valid for [SequenceNumber, LineOfBusinessName] :['+l.SequenceNumber+','+l.LineOfBusinessName+' ]', l.Id, l.SequenceNumber  
FROM stgLease AS l WITH (NOLOCK)   
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id  
	   WHERE l.R_LineofBusinessId IS NULL AND LTRIM(RTRIM(ISNULL(l.LineOfBusinessName, '' ))) <> ''  ;  
INSERT INTO #Params  
SELECT 'Lease: Currency provided is not valid for [SequenceNumber, Currency] :['+l.SequenceNumber+','+l.Currency+' ]', l.Id, l.SequenceNumber  
FROM stgLease AS l WITH (NOLOCK)   
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id  
	   WHERE l.R_CurrencyId IS NULL AND LTRIM(RTRIM(ISNULL(l.Currency, '' ))) <> ''  ;  
INSERT INTO #Params  
SELECT 'Lease: LegalEntityNumber provided is not valid for [SequenceNumber, LegalEntityNumber] :['+l.SequenceNumber+','+l.LegalEntityNumber+' ]', l.Id, l.SequenceNumber  
FROM stgLease AS l WITH (NOLOCK)   
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id  
	   WHERE l.R_LegalEntityId IS NULL AND LTRIM(RTRIM(ISNULL(l.LegalEntityNumber, '' ))) <> ''  ;  
INSERT INTO #Params  
SELECT 'Lease: Remit To selected is not associated with the Legal Entity of the contract [SequenceNumber,LegalEntity, RemitToId] :['+l.SequenceNumber+','+CAST(ISNULL(l.R_LegalEntityId,'') AS NVARCHAR)+','+CAST(ISNULL(l.R_RemitToId,'') AS NVARCHAR)+' ]', l.Id, l.SequenceNumber  
FROM stgLease AS l WITH (NOLOCK)  
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id 
WHERE NOT EXISTS (SELECT Id FROM LegalEntityRemitToes ler WHERE ler.IsActive=1 AND ler.LegalEntityId=l.R_LegalEntityId AND ler.RemitToId=l.R_RemitToId);
INSERT INTO #Params  
SELECT 'Lease: TaxProductType provided is not valid for [SequenceNumber, TaxProductType] :['+l.SequenceNumber+','+l.TaxProductType+' ]', l.Id, l.SequenceNumber  
FROM stgLease AS l WITH (NOLOCK)   
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id  
	   WHERE l.R_TaxProductTypeId IS NULL AND LTRIM(RTRIM(ISNULL(l.TaxProductType, '' ))) <> ''  ;  
INSERT INTO #Params  
SELECT 'Lease: InstrumentTypeCode provided is not valid for [SequenceNumber, InstrumentTypeCode] :['+l.SequenceNumber+','+l.InstrumentTypeCode+' ]', l.Id, l.SequenceNumber  
FROM stgLease AS l WITH (NOLOCK)   
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id  
	   WHERE l.R_InstrumentTypeId IS NULL AND LTRIM(RTRIM(ISNULL(l.InstrumentTypeCode, '' ))) <> ''  ;  
INSERT INTO #Params  
SELECT 'Lease: ReferralBankerLoginName provided is not valid for [SequenceNumber, ReferralBankerLoginName] :['+l.SequenceNumber+','+l.ReferralBankerLoginName+' ]', l.Id, l.SequenceNumber  
FROM stgLease AS l WITH (NOLOCK)   
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id  
	   WHERE l.R_ReferralBankerId IS NULL AND LTRIM(RTRIM(ISNULL(l.ReferralBankerLoginName, '' ))) <> ''  ;  
INSERT INTO #Params  
SELECT 'Lease: CostCenterConfigName provided is not valid for [SequenceNumber, CostCenterConfigName] :['+l.SequenceNumber+','+l.CostCenterConfigName+' ]', l.Id, l.SequenceNumber  
FROM stgLease AS l WITH (NOLOCK)   
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id  
	   WHERE l.R_CostCenterId IS NULL AND LTRIM(RTRIM(ISNULL(l.CostCenterConfigName, '' ))) <> ''  ;  
INSERT INTO #Params  
SELECT 'Lease: ProductAndServiceTypeConfigCode provided is not valid for [SequenceNumber, ProductAndServiceTypeConfigCode] :['+l.SequenceNumber+','+l.ProductAndServiceTypeConfigCode+' ]', l.Id, l.SequenceNumber  
FROM stgLease AS l WITH (NOLOCK)   
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id  
	   WHERE l.R_ProductAndServiceTypeConfigId IS NULL AND LTRIM(RTRIM(ISNULL(l.ProductAndServiceTypeConfigCode, '' ))) <> ''  ;  
INSERT INTO #Params  
SELECT 'Lease: ProgramIndicatorConfigName provided is not valid for [SequenceNumber, ProgramIndicatorConfigName] :['+l.SequenceNumber+','+l.ProgramIndicatorConfigName+' ]', l.Id, l.SequenceNumber  
FROM stgLease AS l WITH (NOLOCK)   
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id  
	   WHERE l.R_ProgramIndicatorConfigId IS NULL AND LTRIM(RTRIM(ISNULL(l.ProgramIndicatorConfigName, '' ))) <> ''  ;  
INSERT INTO #Params  
SELECT 'Lease: Language provided is not valid for [SequenceNumber, Language] :['+l.SequenceNumber+','+l.Language+' ]', l.Id, l.SequenceNumber  
FROM stgLease AS l WITH (NOLOCK)   
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id  
	   WHERE l.R_LanguageId IS NULL AND LTRIM(RTRIM(ISNULL(l.Language, '' ))) <> ''  ;  
INSERT INTO #Params  
SELECT 'Lease: MasterAgreementNumber provided is not valid for [SequenceNumber, MasterAgreementNumber] :['+l.SequenceNumber+','+l.MasterAgreementNumber+' ]', l.Id, l.SequenceNumber  
FROM stgLease AS l WITH (NOLOCK)   
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id  
	   WHERE l.R_MasterAgreementId IS NULL AND LTRIM(RTRIM(ISNULL(l.MasterAgreementNumber, '' ))) <> ''  ;  
INSERT INTO #Params  
SELECT 'Lease: AgreementTypeName provided is not valid for [SequenceNumber, AgreementTypeName] :['+l.SequenceNumber+','+l.AgreementTypeName+' ]', l.Id, l.SequenceNumber  
FROM stgLease AS l WITH (NOLOCK)   
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id  
	   WHERE l.R_AgreementTypeDetailId IS NULL AND LTRIM(RTRIM(ISNULL(l.AgreementTypeName, '_'))) <> '_'  ;
INSERT INTO #Params  
SELECT 'Lease: OriginationSourceTypeName provided is not valid for [SequenceNumber, OriginationSourceTypeName] :['+l.SequenceNumber+','+l.OriginationSourceTypeName+' ]', l.Id, l.SequenceNumber  
FROM stgLease AS l WITH (NOLOCK)   
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id  
	   WHERE l.R_OriginationSourceTypeId IS NULL AND LTRIM(RTRIM(ISNULL(l.OriginationSourceTypeName, '_' ))) <> '_'  ;  
INSERT INTO #Params  
SELECT 'Lease: OriginationSourceChannelName provided is not valid for [SequenceNumber, OriginationSourceTypeName] :['+l.SequenceNumber+','+l.OriginationSourceChannelName+' ]', l.Id, l.SequenceNumber  
FROM stgLease AS l WITH (NOLOCK)   
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id  
	   WHERE l.R_OriginationChannelId IS NULL AND LTRIM(RTRIM(ISNULL(l.OriginationSourceChannelName, '_' ))) <> '_'  ;  
INSERT INTO #Params  
SELECT 'Lease: OriginationSourceTypeName must be Indirect When AcquiredPortfolioName is provided [SequenceNumber, OriginationSourceTypeName ] :['+l.SequenceNumber+' ,'+l.OriginationSourceTypeName+']', l.Id, l.SequenceNumber  
FROM stgLease AS l WITH (NOLOCK)   
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id  
	   WHERE LTRIM(RTRIM(ISNULL(l.AcquiredPortfolioName, '' ))) <> '' AND  l.OriginationSourceTypeName<>'Indirect' ; 
INSERT INTO #Params  
SELECT 'Lease: OriginationSourceNumber provided is not valid for [SequenceNumber, OriginationSourceNumber] :['+l.SequenceNumber+','+l.OriginationSourceNumber+' ]', l.Id, l.SequenceNumber  
FROM stgLease AS l WITH (NOLOCK)   
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id  
	   WHERE l.R_OriginationSourceId IS NULL AND LTRIM(RTRIM(ISNULL(l.OriginationSourceNumber, '' ))) <> ''  ;  
INSERT INTO #Params  
SELECT 'Lease: AcquiredPortfolioName provided is not valid for [SequenceNumber, AcquiredPortfolioName] :['+l.SequenceNumber+','+l.AcquiredPortfolioName+' ]', l.Id, l.SequenceNumber  
FROM stgLease AS l WITH (NOLOCK)   
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id  
	   WHERE l.R_AcquiredPortfolioId IS NULL AND LTRIM(RTRIM(ISNULL(l.AcquiredPortfolioName, '' ))) <> ''  ;  
INSERT INTO #Params  
SELECT 'Lease: OriginationFeeBlendedItemCode provided is not valid for [SequenceNumber, OriginationFeeBlendedItemCode] :['+l.SequenceNumber+','+l.OriginationFeeBlendedItemCode+' ]', l.Id, l.SequenceNumber  
FROM stgLease AS l WITH (NOLOCK)   
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id  
	   WHERE l.R_OriginationFeeBlendedItemCodeId IS NULL AND LTRIM(RTRIM(ISNULL(l.OriginationFeeBlendedItemCode, '' ))) <> ''  ;  
INSERT INTO #Params  
SELECT 'Lease: OriginatorPayableRemitToUniqueIdentifier provided is not valid for [SequenceNumber, OriginatorPayableRemitToUniqueIdentifier] :['+l.SequenceNumber+','+l.OriginatorPayableRemitToUniqueIdentifier+' ]', l.Id, l.SequenceNumber  
FROM stgLease AS l WITH (NOLOCK)   
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id  
	   WHERE l.R_OriginatorPayableRemitToId IS NULL AND LTRIM(RTRIM(ISNULL(l.OriginatorPayableRemitToUniqueIdentifier, '' ))) <> ''   
	AND (l.OriginationSourceTypeName = 'Vendor' OR l.OriginationSourceTypeName = 'InDirect') ;  
INSERT INTO #Params  
SELECT 'Lease: ScrapePayableCodeName provided is not valid for [SequenceNumber, ScrapePayableCodeName] :['+l.SequenceNumber+','+l.ScrapePayableCodeName+' ]', l.Id, l.SequenceNumber  
FROM stgLease AS l WITH (NOLOCK)   
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id  
	   WHERE l.R_ScrapePayableCodeId IS NULL AND LTRIM(RTRIM(ISNULL(l.ScrapePayableCodeName, '' ))) <> ''  ;  
INSERT INTO #Params  
SELECT 'Lease: OriginatingLineofBusinessName provided is not valid for [SequenceNumber, OriginatingLineofBusinessName] :['+l.SequenceNumber+','+l.OriginatingLineofBusinessName+' ]', l.Id, l.SequenceNumber  
FROM stgLease AS l WITH (NOLOCK)   
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id  
	   WHERE l.R_OriginatingLineofBusinessId IS NULL AND LTRIM(RTRIM(ISNULL(l.OriginatingLineofBusinessName, '' ))) <> ''  ;  
INSERT INTO #Params  
SELECT 'Lease: ProgramVendorOriginationSourceNumber provided is not valid for [SequenceNumber, ProgramVendorOriginationSourceNumber] :['+l.SequenceNumber+','+l.ProgramVendorOriginationSourceNumber+' ]', l.Id, l.SequenceNumber  
FROM stgLease AS l WITH (NOLOCK)   
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id  
	   WHERE l.R_ProgramVendorOriginationSourceId IS NULL AND LTRIM(RTRIM(ISNULL(l.ProgramVendorOriginationSourceNumber, '' ))) <> ''  ;  
INSERT INTO #Params  
SELECT 'Lease: DocFeeReceivableCodeName provided is not valid for [SequenceNumber, DocFeeReceivableCodeName] :['+l.SequenceNumber+','+l.DocFeeReceivableCodeName+' ]', l.Id, l.SequenceNumber  
FROM stgLease AS l WITH (NOLOCK)   
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id  
	   WHERE l.R_DocFeeReceivableCodeId IS NULL AND LTRIM(RTRIM(ISNULL(l.DocFeeReceivableCodeName, '' ))) <> ''  ; 
INSERT INTO #Params  
SELECT 'Lease: BranchName provided is not valid for [SequenceNumber, BranchName] :['+l.SequenceNumber+','+l.BranchName+' ]', l.Id, l.SequenceNumber  
FROM stgLease AS l WITH (NOLOCK)   
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id
	   WHERE l.R_BranchId IS NULL AND LTRIM(RTRIM(ISNULL(l.BranchName, '' ))) <> ''  ;    
INSERT INTO #Params  
SELECT 'Lease: Country provided is not valid for [SequenceNumber, Country] :['+l.SequenceNumber+','+l.Country+' ]', l.Id, l.SequenceNumber  
FROM stgLease AS l WITH (NOLOCK)   
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id  
	   WHERE l.R_CountryId IS NULL  AND LTRIM(RTRIM(ISNULL(l.Country, '' ))) <> ''  ;
INSERT INTO #Params
SELECT 'Lease: Please provide Vendor Payable Code Name for [SequenceNumber]:['+l.SequenceNumber+']',l.Id,l.SequenceNumber
FROM (SELECT DISTINCT l.Id,l.SequenceNumber 
FROM stgLease as L WITH (NOLOCK)
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id
INNER JOIN stgLeaseAsset la WITH (NOLOCK) on la.LeaseId=l.Id 
 WHERE la.SalesTaxRemittanceResponsibility ='Vendor' AND l.VendorPayableCodeName IS NULL) as l
 UPDATE stgLease 
 SET stgLease.R_VendorPayableCodeId = PayableCode.Id
 FROM stgLease  WITH (NOLOCK) 
INNER JOIN PayableCodes PayableCode  WITH (NOLOCK) ON UPPER(stgLease.VendorPayableCodeName) = UPPER(PayableCode.Name) AND PayableCode.IsActive = 1
AND stgLease.VendorPayableCodeName IS NOT NULL
INNER JOIN PayableTypes PayableType  WITH (NOLOCK) ON PayableCode.PayableTypeId = PayableType.Id AND PayableType.IsActive = 1
INNER JOIN GLTemplates GLT  WITH (NOLOCK) ON GLT.Id = PayableCode.GLTemplateId
INNER JOIN #ProcessableLeaseTemp lf  WITH (NOLOCK) ON stgLease.Id = lf.Id
INNER JOIN LegalEntities LE  WITH (NOLOCK) ON LE.Id = stgLease.R_LegalEntityId AND LE.GLConfigurationId = GLT.GLConfigurationId
WHERE  PayableType.Name = 'DueToInvestorAP'
INSERT INTO #Params
 SELECT 'Lease: Please provide valid DueToInvestorAP Type Payable Code for Vendor Payable Code Name for [SequenceNumber]:['+l.SequenceNumber+']',l.Id,l.SequenceNumber
From(SELECT DISTINCT l.Id,l.SequenceNumber 
FROM stgLease as L WITH (NOLOCK)
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id
INNER JOIN stgLeaseAsset la on la.LeaseId=l.Id 
 WHERE la.SalesTaxRemittanceResponsibility ='Vendor' AND l.VendorPayableCodeName IS NOT NULL AND l.R_VendorPayableCodeId IS NULL) as l
print '3'
--=============================stgLeaseFinanceDetail=================================  
UPDATE stgLeaseFinanceDetail SET R_LeaseBookingGLTemplateId = g1.Id, R_LeaseIncomeGLTemplateId = g2.Id, R_FloatIncomeGLTemplateId = g.Id, R_OTPIncomeGLTemplateId = g3.Id, R_DeferredTaxGLTemplateId = g4.Id, R_TaxAssetSetupGLTemplateId = g5.Id, R_TaxDepExpenseGLTemplateId = g6.Id, R_TaxDepDisposalTemplateId = g7.Id
FROM stgLeaseFinanceDetail AS lfd WITH (NOLOCK)  
INNER JOIN stgLease AS l WITH (NOLOCK) ON lfd.Id = l.Id
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id  
INNER JOIN LegalEntities AS le WITH (NOLOCK) ON le.Id = l.R_LegalEntityId 
LEFT JOIN #GlTemplateTemp AS g WITH (NOLOCK) ON lfd.FloatIncomeGLTemplateName = g.Name AND g.GLConfigurationId = le.GLConfigurationId AND g.LegalEntityNumber = le.LegalEntityNumber AND g.GLTransactionType = 'FloatIncome'  
LEFT JOIN #GlTemplateTemp AS g1 WITH (NOLOCK) ON lfd.LeaseBookingGLTemplateName = g1.Name AND g1.GLConfigurationId = le.GLConfigurationId AND g1.LegalEntityNumber = le.LegalEntityNumber AND ((g1.GLTransactionType = 'OperatingLeaseBooking' AND lfd.ContractType = 'Operating') OR (g1.GLTransactionType = 'CapitalLeaseBooking' AND lfd.ContractType In ('DirectFinance','ConditionalSales','SalesType','Financing', 'IFRSFinanceLease')))  
LEFT JOIN #GlTemplateTemp AS g2 WITH (NOLOCK) ON lfd.LeaseIncomeGLTemplateName = g2.Name AND g2.GLConfigurationId = le.GLConfigurationId AND g2.LegalEntityNumber = le.LegalEntityNumber AND ( (g2.GLTransactionType = 'OperatingLeaseIncome' AND lfd.ContractType = 'Operating') OR  (g2.GLTransactionType = 'CapitalLeaseIncome' AND lfd.ContractType In ('DirectFinance','ConditionalSales','SalesType','Financing', 'IFRSFinanceLease')))  
LEFT JOIN #GlTemplateTemp AS g3 WITH (NOLOCK) ON lfd.OTPIncomeGLTemplateName = g3.Name AND g3.GLConfigurationId = le.GLConfigurationId AND g3.LegalEntityNumber = le.LegalEntityNumber AND g3.GLTransactionType = 'OTPIncome'  
LEFT JOIN #GlTemplateTemp AS g4 WITH (NOLOCK) ON lfd.DeferredTaxGLTemplateName = g4.Name AND g4.GLConfigurationId = le.GLConfigurationId AND g4.LegalEntityNumber = le.LegalEntityNumber AND g4.GLTransactionType = 'DeferredTaxLiability'  
LEFT JOIN #GlTemplateTemp AS g5 WITH (NOLOCK) ON lfd.TaxAssetSetupGLTemplateName = g5.Name AND g5.GLConfigurationId = le.GLConfigurationId AND g5.LegalEntityNumber = le.LegalEntityNumber AND g5.GLTransactionType = 'TaxAssetSetup'  
LEFT JOIN #GlTemplateTemp AS g6 WITH (NOLOCK) ON lfd.TaxDepExpenseGLTemplateName = g6.Name AND g6.GLConfigurationId = le.GLConfigurationId AND g6.LegalEntityNumber = le.LegalEntityNumber AND g6.GLTransactionType = 'TaxDepreciation'  
LEFT JOIN #GlTemplateTemp AS g7 WITH (NOLOCK) ON lfd.TaxDepDisposalTemplateName = g7.Name AND g7.GLConfigurationId = le.GLConfigurationId AND g7.LegalEntityNumber = le.LegalEntityNumber AND g7.GLTransactionType = 'TaxDepreciationDisposal';  


UPDATE stgLeaseFinanceDetail  SET R_FixedTermReceivableCodeId = rc.Id, R_FloatRateARReceivableCodeId = rc1.Id, R_OTPReceivableCodeId = rc2.Id, R_PropertyTaxReceivableCodeId = rc3.Id, R_SupplementalReceivableCodeId = rc4.Id, R_OTPPayableCodeId = pc1.Id
FROM stgLeaseFinanceDetail AS lfd WITH (NOLOCK)  
INNER JOIN stgLease AS l WITH (NOLOCK) ON lfd.Id = l.Id
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id
INNER JOIN LegalEntities le WITH (NOLOCK) ON le.Id = l.R_LegalEntityId
LEFT JOIN #ReceivableCodeTemp AS rc WITH (NOLOCK) ON lfd.FixedTermRentReceivableCodeName = rc.ReceivableCodeName AND le.GLConfigurationId = rc.GLConfigurationId AND ((rc.ReceivableTypeName = 'OperatingLeaseRental' AND lfd.ContractType = 'Operating') OR (rc.ReceivableTypeName = 'CapitalLeaseRental' AND lfd.ContractType != 'Operating' )) AND ((rc.GLTransactionTypeName = 'OperatingLeaseAR' AND lfd.ContractType = 'Operating') OR (rc.GLTransactionTypeName = 'CapitalLeaseAR' AND lfd.ContractType != 'Operating' ))  
LEFT JOIN #ReceivableCodeTemp AS rc1 WITH (NOLOCK) ON lfd.FloatRateARReceivableCodeName = rc1.ReceivableCodeName AND le.GLConfigurationId = rc1.GLConfigurationId AND rc1.ReceivableTypeName IN ('LeaseFloatRateAdj') AND rc1.GLTransactionTypeName IN ('FloatRateAR')
LEFT JOIN #ReceivableCodeTemp AS rc2 WITH (NOLOCK) ON lfd.OTPReceivableCodeName = rc2.ReceivableCodeName AND le.GLConfigurationId = rc2.GLConfigurationId AND rc2.ReceivableTypeName IN ('OverTermRental') AND rc2.GLTransactionTypeName IN ('OTPAR') 
LEFT JOIN #ReceivableCodeTemp AS rc3 WITH (NOLOCK) ON lfd.PropertyTaxReceivableCodeName = rc3.ReceivableCodeName AND le.GLConfigurationId = rc3.GLConfigurationId AND rc3.ReceivableTypeName IN ('PropertyTax') AND rc3.GLTransactionTypeName IN ('PropertyTaxAR')  
LEFT JOIN #ReceivableCodeTemp AS rc4 WITH (NOLOCK) ON lfd.SupplementalReceivableCodeName = rc4.ReceivableCodeName AND le.GLConfigurationId = rc4.GLConfigurationId  AND rc4.ReceivableTypeName IN ('Supplemental') AND rc4.GLTransactionTypeName IN ('OTPAR')  
LEFT JOIN PayableCodes AS pc1 WITH (NOLOCK) ON lfd.OTPPayableCodeName = pc1.Name

UPDATE stgLeaseFinanceDetail  SET R_DownPaymentPercentageId = dp.Id
FROM stgLeaseFinanceDetail AS lfd WITH (NOLOCK)
INNER JOIN stgLease AS l WITH (NOLOCK) ON lfd.Id = l.Id
INNER JOIN #ProcessableLeaseTemp lt ON l.Id = lt.Id
INNER JOIN QuoteDownPayments dp on lfd.DownPaymentPercentage = dp.DownPaymentPercentage AND dp.IsActive=1


INSERT INTO #Params  
SELECT 'LeaseFinanceDetail: Please Enter Down Payment Percentage for Lease:['+l.SequenceNumber+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseFinanceDetail AS lfdt WITH (NOLOCK)
	 JOIN stgLease lease on lfdt.Id = lease.Id     
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lfdt.Id  
	   WHERE lfdt.R_DownPaymentPercentageId IS NULL

print '5'
INSERT INTO #Params  
SELECT 'LeaseFinanceDetail: Supplemental and OTP related fields should be populated only if IsOTP flag is set for lease with [SequenceNumber] :['+l.SequenceNumber+','+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseFinanceDetail AS lfdt WITH (NOLOCK)   
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lfdt.Id  
	   WHERE lfdt.IsOTPLease = 0 AND( 
		  lfdt.IsBillOTPForSoftAssets = 1
	   OR lfdt.IsOTPRegularPaymentStream = 1
	   OR lfdt.SupplementalFrequencyUnit != 0
	   OR (ISNULL(lfdt.OTPPaymentFrequency,'_')<>'_' AND lfdt.OTPPaymentFrequency != 'NotApplicable')
	   OR lfdt.OTPRentPreference NOT IN ('_' ,'AssetLevel')
	   OR lfdt.OTPRentalAmount_Amount != 0
	   OR lfdt.SupplementalRent_Amount != 0
	   OR lfdt.IsOTPScheduled = 1
	   OR lfdt.OTPReceivableCodeName IS NOT NULL
	   OR lfdt.OTPIncomeGLTemplateName IS NOT NULL
	   OR lfdt.SupplementalReceivableCodeName IS NOT NULL 
	   OR lfdt.IsSupplementalAdvance = 1
	   OR (ISNULL(lfdt.SupplementalFrequency,'_')<>'_' AND lfdt.SupplementalFrequency != 'NotApplicable')
	   OR lfdt.SupplementalGracePeriod != 0
	   OR lfdt.TerminationNoticeReceived = 1
	   OR lfdt.TerminationNoticeReceivedOn IS NOT NULL
	   OR lfdt.TerminationNoticeDate IS NOT NULL
	   OR lfdt.otppayablecodename IS NOT NULL
	   OR lfdt.OTPRentPayableWithholdingTaxRate != 0
	   OR lfdt.NumberOfOTPPayments != 0
	   )
INSERT INTO #Params  
SELECT 'LeaseFinanceDetail: OTP Rent Preference should be either Lease level or Asset level :['+l.SequenceNumber+','+ISNULL(lfdt.OTPRentPreference, 'NULL')+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseFinanceDetail AS lfdt WITH (NOLOCK)
	 JOIN stgLease lease on lfdt.Id = lease.Id     
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lfdt.Id  
	   WHERE lfdt.isotplease = 1 AND lfdt.OTPRentPreference NOT IN ('LeaseLevel' , 'AssetLevel');
INSERT INTO #Params  
SELECT 'LeaseFinanceDetail: FixedTermRentReceivableCodeName provided is not valid for [SequenceNumber, FixedTermRentReceivableCodeName] :['+l.SequenceNumber+','+ISNULL(lfdt.FixedTermRentReceivableCodeName, 'NULL')+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseFinanceDetail AS lfdt WITH (NOLOCK)
	 JOIN stgLease lease on lfdt.Id = lease.Id     
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lfdt.Id  
	   WHERE lfdt.R_FixedTermReceivableCodeId IS NULL AND (LTRIM(RTRIM(ISNULL(lfdt.FixedTermRentReceivableCodeName, '' ))) <> '' OR (lease.SyndicationType = 'None' OR lease.SyndicationType = '_'));
INSERT INTO #Params  
SELECT 'LeaseFinanceDetail: FloatRateARReceivableCodeName provided is not valid for [SequenceNumber, FloatRateARReceivableCodeName] :['+l.SequenceNumber+','+ISNULL(lfdt.FloatRateARReceivableCodeName, 'NULL')+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseFinanceDetail AS lfdt WITH (NOLOCK)   
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lfdt.Id  
	   WHERE lfdt.R_FloatRateARReceivableCodeId IS NULL AND (LTRIM(RTRIM(ISNULL(lfdt.FloatRateARReceivableCodeName, '' ))) <> ''  OR lfdt.IsFloatRateLease = 1);  

INSERT INTO #Params  
SELECT 'LeaseFinanceDetail: PromissoryNote should be Greater Than Zero for [SequenceNumber] :['+l.SequenceNumber+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseFinanceDetail AS lfdt WITH (NOLOCK)   
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lfdt.Id  
	   WHERE lfdt.PromissoryNote_Amount = 0.00  AND  lfdt.IsPromissoryNote = 1;  

INSERT INTO #Params  
SELECT 'LeaseFinanceDetail: OTPReceivableCodeName provided is not valid for [SequenceNumber, OTPReceivableCodeName] :['+l.SequenceNumber+','+ISNULL(lfdt.OTPReceivableCodeName, 'NULL')+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseFinanceDetail AS lfdt WITH (NOLOCK)   
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lfdt.Id  
	   WHERE lfdt.R_OTPReceivableCodeId IS NULL AND (LTRIM(RTRIM(ISNULL(lfdt.OTPReceivableCodeName, '' ))) <> '' OR IsOTPLease = 1) ;  
INSERT INTO #Params
SELECT 'LeaseFinanceDetail: PropertyTaxReceivableCodeName provided is not valid for [SequenceNumber, PropertyTaxReceivableCodeName] :['+l.SequenceNumber+','+ISNULL(lfdt.PropertyTaxReceivableCodeName, 'NULL')+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseFinanceDetail AS lfdt WITH (NOLOCK)   
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lfdt.Id  
	   WHERE lfdt.R_PropertyTaxReceivableCodeId IS NULL AND LTRIM(RTRIM(ISNULL(lfdt.PropertyTaxReceivableCodeName, '' ))) <> ''  ; 
INSERT INTO #Params
SELECT 'LeaseFinanceDetail: OTPPayableCodeName provided is not valid for [SequenceNumber, OTPPayableCodeName] :['+l.SequenceNumber+','+IsNull(lfdt.OTPPayableCodeName,'NULL')+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseFinanceDetail AS lfdt WITH (NOLOCK)   
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lfdt.Id  
	   WHERE lfdt.R_OTPPayableCodeId IS NULL AND (LTRIM(RTRIM(ISNULL(lfdt.OTPPayableCodeName, '' ))) <> '') ;
INSERT INTO #Params
SELECT 'LeaseFinanceDetail: OTPPayableCodeName provided is not valid for [SequenceNumber, OTPPayableCodeName] :['+l.SequenceNumber+','+IsNull(lfdt.OTPPayableCodeName,'NULL')+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseFinanceDetail AS lfdt WITH (NOLOCK)   
JOIN #ProcessableLeaseTemp AS l  WITH (NOLOCK) ON l.id = lfdt.Id  
JOIN stgLease AS lf WITH (NOLOCK)  ON lf.Id = lfdt.id
JOIN payableCodes  WITH (NOLOCK) ON payableCodes.Id=lfdt.R_OTPPayableCodeId
JOIN payableTypes WITH (NOLOCK)  ON payableCodes.PayableTypeId =  payableTypes.Id
JOIN glTemplates  WITH (NOLOCK) ON payableCodes.GLTemplateId = glTemplates.Id
JOIN LegalEntities  WITH (NOLOCK) ON lf.R_LegalEntityId = LegalEntities.Id
WHERE NOT(payableTypes.Name = 'DueToInvestorAP' AND payableCodes.IsActive = 1 AND payableTypes.IsActive = 1 AND glTemplates.GLConfigurationId = LegalEntities.GLConfigurationId) 

INSERT INTO #Params  
SELECT 'LeaseFinanceDetail:The Lease with OTP Sharing parameter should be Over term lease and have Origination source as vendor  [SequenceNumber] :['+l.SequenceNumber+' ]', l.Id, l.SequenceNumber  
FROM stgLease AS lf WITH (NOLOCK)   
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lf.Id
	 JOIN stgLeaseFinanceDetail AS lfdt on lfdt.id=l.id
	   WHERE lf.OriginationSourceTypeName <> 'Vendor' AND lfdt.IsOTPLease<>1 AND lf.Id in (Select LeaseFinanceDetailId From stgLeaseOTPSharingParameter)

INSERT INTO #Params  
SELECT 'LeaseFinanceDetail: The Lease with OTP Sharing parameter should have a Payable code  [SequenceNumber] :['+l.SequenceNumber+' ]', l.Id, l.SequenceNumber  
FROM stgLease AS lf WITH (NOLOCK)   
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lf.Id
	 JOIN stgLeaseFinanceDetail AS lfdt on lfdt.id=l.id
	   WHERE lf.OriginationSourceTypeName = 'Vendor' AND lfdt.IsOTPLease=1 AND lf.Id in (Select LeaseFinanceDetailId From stgLeaseOTPSharingParameter) AND lfdt.OTPPayableCodeName IS NULL

INSERT INTO #Params  
SELECT 'LeaseFinanceDetail: SupplementalReceivableCodeName provided is not valid for [SequenceNumber, SupplementalReceivableCodeName] :['+l.SequenceNumber+','+ISNULL(lfdt.SupplementalReceivableCodeName, 'NULL')+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseFinanceDetail AS lfdt WITH (NOLOCK)   
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lfdt.Id  
	   WHERE lfdt.R_SupplementalReceivableCodeId IS NULL AND LTRIM(RTRIM(ISNULL(lfdt.SupplementalReceivableCodeName, '' ))) <> ''  ;  
INSERT INTO #Params  
SELECT 'LeaseFinanceDetail: FloatIncomeGLTemplateName provided is not valid for [SequenceNumber, FloatIncomeGLTemplateName] :['+l.SequenceNumber+','+ISNULL(lfdt.FloatIncomeGLTemplateName, 'NULL')+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseFinanceDetail AS lfdt WITH (NOLOCK)   
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lfdt.Id  
	   WHERE lfdt.R_FloatIncomeGLTemplateId IS NULL AND (LTRIM(RTRIM(ISNULL(lfdt.FloatIncomeGLTemplateName, '' ))) <> ''  OR lfdt.IsFloatRateLease = 1);  
INSERT INTO #Params  
SELECT 'LeaseFinanceDetail: LeaseBookingGLTemplateName provided is not valid for [SequenceNumber, LeaseBookingGLTemplateName] :['+l.SequenceNumber+','+ISNULL(lfdt.LeaseBookingGLTemplateName, 'NULL')+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseFinanceDetail AS lfdt WITH (NOLOCK)
	 JOIN stgLease lease on lfdt.Id = lease.Id       
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lfdt.Id  
	   WHERE lfdt.R_LeaseBookingGLTemplateId IS NULL AND (LTRIM(RTRIM(ISNULL(lfdt.LeaseBookingGLTemplateName, '' ))) <> '' OR  (lease.SyndicationType = 'None' OR lease.SyndicationType = '_')) ;
INSERT INTO #Params  
SELECT 'LeaseFinanceDetail: LeaseIncomeGLTemplateName provided is not valid for [SequenceNumber, LeaseIncomeGLTemplateName] :['+l.SequenceNumber+','+ISNULL(lfdt.LeaseIncomeGLTemplateName, 'NULL')+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseFinanceDetail AS lfdt WITH (NOLOCK)
	 JOIN stgLease lease on lfdt.Id = lease.Id       
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lfdt.Id  
	   WHERE lfdt.R_LeaseIncomeGLTemplateId IS NULL AND (LTRIM(RTRIM(ISNULL(lfdt.LeaseIncomeGLTemplateName, '' ))) <> '' OR (lease.SyndicationType = 'None' OR lease.SyndicationType = '_') );
INSERT INTO #Params  
SELECT 'LeaseFinanceDetail: OTPIncomeGLTemplateName provided is not valid for [SequenceNumber, OTPIncomeGLTemplateName] :['+l.SequenceNumber+','+ISNULL(lfdt.OTPIncomeGLTemplateName, 'NULL')+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseFinanceDetail AS lfdt WITH (NOLOCK)   
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lfdt.Id  
	   WHERE lfdt.R_OTPIncomeGLTemplateId IS NULL AND (LTRIM(RTRIM(ISNULL(lfdt.OTPIncomeGLTemplateName, '' ))) <> ''  OR IsOTPLease = 1);  
INSERT INTO #Params  
SELECT 'LeaseFinanceDetail: DeferredTaxGLTemplateName provided is not valid for [SequenceNumber, DeferredTaxGLTemplateName] :['+l.SequenceNumber+','+ISNULL(lfdt.DeferredTaxGLTemplateName, 'NULL')+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseFinanceDetail AS lfdt WITH (NOLOCK)   
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lfdt.Id  
	   WHERE lfdt.R_DeferredTaxGLTemplateId IS NULL AND LTRIM(RTRIM(ISNULL(lfdt.DeferredTaxGLTemplateName, '' ))) <> ''  ;
INSERT INTO #Params  
SELECT 'LeaseFinanceDetail: Syndicated leases cannot be a Tax Lease for [SequenceNumber] :['+l.SequenceNumber+']', l.Id, l.SequenceNumber  
FROM stgLeaseFinanceDetail AS lfdt WITH (NOLOCK)
INNER JOIN stgLease as Lease ON Lease.Id = lfdt.Id
INNER JOIN #ProcessableLeaseTemp AS l ON l.id = lfdt.Id  
WHERE (Lease.SyndicationType != 'None' AND Lease.SyndicationType != '_') AND IsTaxLease = 1;

INSERT INTO #Params  
SELECT 'LeaseFinanceDetail: DeferredTaxGLTemplateName provided is not valid for [SequenceNumber, DeferredTaxGLTemplateName] :['+l.SequenceNumber+','+ISNULL(lfdt.DeferredTaxGLTemplateName,'NULL')+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseFinanceDetail AS lfdt WITH (NOLOCK)   
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lfdt.Id  
	   WHERE lfdt.R_DeferredTaxGLTemplateId IS NULL AND IsTaxLease = 1;
INSERT INTO #Params  
SELECT 'LeaseFinanceDetail: TaxAssetSetupGLTemplateName provided is not valid for [SequenceNumber, TaxAssetSetupGLTemplateName] :['+l.SequenceNumber+','+ISNULL(lfdt.TaxAssetSetupGLTemplateName,'NULL')+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseFinanceDetail AS lfdt WITH (NOLOCK)   
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lfdt.Id  
	   WHERE lfdt.R_TaxAssetSetupGLTemplateId IS NULL AND (LTRIM(RTRIM(ISNULL(lfdt.TaxAssetSetupGLTemplateName, '' ))) <> '' OR (@UseTaxBooks = 'True' AND lfdt.IsTaxLease = 1));  
INSERT INTO #Params  
SELECT 'LeaseFinanceDetail: TaxDepExpenseGLTemplateName provided is not valid for [SequenceNumber, TaxDepExpenseGLTemplateName] :['+l.SequenceNumber+','+ISNULL(lfdt.TaxDepExpenseGLTemplateName,'NULL')+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseFinanceDetail AS lfdt WITH (NOLOCK)   
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lfdt.Id  
	   WHERE lfdt.R_TaxDepExpenseGLTemplateId IS NULL AND (LTRIM(RTRIM(ISNULL(lfdt.TaxDepExpenseGLTemplateName, '' ))) <> ''  OR (@UseTaxBooks = 'True' AND lfdt.IsTaxLease = 1));  
INSERT INTO #Params  
SELECT 'LeaseFinanceDetail: TaxDepDisposalTemplateName provided is not valid for [SequenceNumber, TaxDepDisposalTemplateName] :['+l.SequenceNumber+','+ISNULL(lfdt.TaxDepDisposalTemplateName,'NULL')+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseFinanceDetail AS lfdt WITH (NOLOCK)   
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lfdt.Id  
	   WHERE lfdt.R_TaxDepDisposalTemplateId IS NULL AND LTRIM(RTRIM(ISNULL(lfdt.TaxDepDisposalTemplateName, '' ))) <> ''  ;  
INSERT INTO #Params  
SELECT 'Lease: ContractType provided is not valid for [SequenceNumber, ContractType] :['+l.SequenceNumber+','+lfdt.ContractType+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseFinanceDetail AS lfdt WITH (NOLOCK)   
INNER JOIN #ProcessableLeaseTemp l ON l.Id = lfdt.Id
INNER JOIN stgLease as  Lease ON Lease.Id = lfdt.Id
INNER JOIN DealProductTypes ON Lease.R_DealProductTypeId = DealProductTypes.Id  
	   WHERE ((Lease.AccountingStandard ='ASC840_IAS17' AND lfdt.ContractType != 'Operating' AND lfdt.ContractType != DealProductTypes.CapitalLeaseType) OR
			  (Lease.AccountingStandard ='ASC842' AND lfdt.ContractType != 'Financing' AND lfdt.ContractType != 'SalesType' AND lfdt.ContractType != 'DirectFinance' AND lfdt.ContractType != 'Operating') OR
			  (Lease.AccountingStandard ='IFRS16' AND lfdt.ContractType != 'Financing' AND lfdt.ContractType != 'IFRSFinanceLease' AND lfdt.ContractType != 'Operating'))
	   print '6'
INSERT INTO #Params
SELECT 'LeaseFinanceDetail: Number of OTP payments must be greater than zero for OTP Lease [SequenceNumber] :['+l.SequenceNumber+' ]', l.Id, l.SequenceNumber
FROM stgLeaseFinanceDetail AS lfdt WITH (NOLOCK) 
     JOIN #ProcessableLeaseTemp AS l ON l.id = lfdt.Id
       WHERE lfdt.IsOTPLease = 1 AND NumberOfOTPPayments <= 0 AND lfdt.IsOTPScheduled = 1;
INSERT INTO #Params
SELECT 'LeaseFinanceDetail: OTPPaymentFrequency provided is not valid  for OTP Lease [SequenceNumber, OTPPaymentFrequency] :['+l.SequenceNumber+','+ISNULL(lfdt.OTPPaymentFrequency,'NULL')+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseFinanceDetail AS lfdt WITH (NOLOCK) 
     JOIN #ProcessableLeaseTemp AS l ON l.id = lfdt.Id
       WHERE lfdt.IsOTPLease = 1 AND LTRIM(RTRIM(ISNULL(lfdt.OTPPaymentFrequency, '_'))) = '_'  ;  
INSERT INTO #Params
SELECT 'LeaseFinanceDetail: OTP Payment Frequency Days should be 28,30 for OTP Lease [SequenceNumber, OTPPaymentFrequencyUnit] :['+l.SequenceNumber+','+CONVERT(nvarchar(5),lfdt.OTPPaymentFrequencyUnit)+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseFinanceDetail AS lfdt WITH (NOLOCK) 
     JOIN #ProcessableLeaseTemp AS l ON l.id = lfdt.Id
       WHERE lfdt.IsOTPLease = 1 AND LTRIM(RTRIM(ISNULL(lfdt.OTPPaymentFrequency, ''))) = 'Days' AND OTPPaymentFrequencyUnit NOT IN (28, 30);  
INSERT INTO #Params
SELECT 'LeaseFinanceDetail: The Number of Payments given in Lease Finance Detail must be greater than 0 for [SequenceNumber] : ['+l.SequenceNumber+' ]', l.Id, l.SequenceNumber
FROM stgLeaseFinanceDetail AS lfd
INNER JOIN #ProcessableLeaseTemp AS l ON l.id = lfd.Id
WHERE lfd.NumberOfPayments = 0
INSERT INTO #Params
SELECT 'LeaseFinanceDetail: The Number of Payments given in Lease Payment Schedule does not match the number of payments given in Lease Finance Detail for [SequenceNumber] : ['+l.SequenceNumber+' ]', l.Id, l.SequenceNumber
FROM stgLeaseFinanceDetail AS lfd
INNER JOIN #ProcessableLeaseTemp AS l ON l.id = lfd.Id
INNER JOIN stgLeasePaymentSchedule AS lps ON lps.LeaseFinanceDetailId = lfd.Id AND lps.PaymentType = 'FixedTerm'
GROUP BY l.Id, l.SequenceNumber,lfd.NumberOfPayments
HAVING COUNT(lps.Id) > 0 AND lfd.NumberOfPayments != COUNT(lps.Id)
INSERT INTO #Params
SELECT 'LeaseFinanceDetail: The Number of OTP Payments given in Lease Payment Schedule does not match the Number of OTP Payments given in Lease Finance Detail for [SequenceNumber] : [' + l.SequenceNumber + ' ]', l.Id, l.SequenceNumber
FROM stgLeaseFinanceDetail AS lfd
JOIN #ProcessableLeaseTemp AS l ON l.id = lfd.Id
INNER JOIN stgLeasePaymentSchedule AS lps ON lps.LeaseFinanceDetailId = lfd.Id AND lps.PaymentType = 'OTP'
GROUP BY l.Id, l.SequenceNumber,lfd.NumberOfOTPPayments
HAVING COUNT(lps.Id) > 0 AND lfd.NumberOfOTPPayments != COUNT(lps.Id)
INSERT INTO #Params
SELECT 
     CASE WHEN ( lfd.PaymentStreamFrequency = 'Monthly' OR lfd.PaymentStreamFrequency = 'Quarterly' OR lfd.PaymentStreamFrequency = 'HalfYearly' OR lfd.PaymentStreamFrequency = 'Yearly')
	     THEN 'Compounding Frequency must be either monthly or equal to payment frequency for [SequenceNumber] : [' + l.SequenceNumber + ' ]'
		 ELSE
		   'Compounding Frequency must be monthly for [SequenceNumber] : [' + l.SequenceNumber + ' ]' 
		 END,l.Id, l.SequenceNumber
FROM stgLeaseFinanceDetail AS lfd
JOIN #ProcessableLeaseTemp AS l ON l.id = lfd.Id
WHERE lfd.CompoundingFrequency <> (CASE WHEN lfd.CompoundingFrequency = 'Monthly' 
									   THEN lfd.CompoundingFrequency
									   WHEN ( lfd.PaymentStreamFrequency = 'Monthly' OR lfd.PaymentStreamFrequency = 'Quarterly' OR lfd.PaymentStreamFrequency = 'HalfYearly' OR lfd.PaymentStreamFrequency = 'Yearly')
                                       THEN    lfd.PaymentStreamFrequency 
		                               ELSE  'Monthly' END 
								 ) 

--=============================stgLeaseContact=================================  
UPDATE stgLeaseContact  
  SET stgLeaseContact.R_PartyAddressId = pa.Id  
FROM PartyAddresses pa WITH (NOLOCK)   
	   WHERE pa.UniqueIdentifier = stgLeaseContact.AddressUniqueIdentifier   
   AND stgLeaseContact.LeaseId IN (SELECT ID FROM #ProcessableLeaseTemp);  
INSERT INTO #Params  
SELECT 'LeaseContact: AddressUniqueIdentifier provided is not valid for [SequenceNumber, AddressUniqueIdentifier] :['+l.SequenceNumber+','+lct.AddressUniqueIdentifier+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseContact AS lct WITH (NOLOCK)   
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lct.LeaseId  
	   WHERE lct.R_PartyAddressId IS NULL AND LTRIM(RTRIM(ISNULL(lct.AddressUniqueIdentifier, '' ))) <> '';  
UPDATE stgLeaseContact  
  SET stgLeaseContact.R_PartyContactId = pa.Id  
FROM PartyContacts pa  WITH (NOLOCK) 
	   WHERE pa.UniqueIdentifier = stgLeaseContact.UniqueIdentifier AND stgLeaseContact.LeaseId IN (SELECT ID FROM #ProcessableLeaseTemp);  
INSERT INTO #Params  
SELECT 'LeaseContact: UniqueIdentifier provided is not valid for [SequenceNumber, UniqueIdentifier] :['+l.SequenceNumber+','+lct.UniqueIdentifier+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseContact AS lct WITH (NOLOCK)   
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lct.LeaseId  
	   WHERE lct.R_PartyContactId IS NULL AND LTRIM(RTRIM(ISNULL(lct.UniqueIdentifier, '' ))) <> '';  
--=============================stgLeaseAsset=================================  
print '7'
UPDATE stgLeaseAsset  SET R_AssetId = a.Id ,R_TaxDepTemplateId = tdt.Id,R_BillToId = b.Id, 
R_AcquisitionLocationId= Locations.Id,R_VendorRemitToId = RemitTo.Id,R_BookDepreciationTemplateId = bdt.Id     
FROM stgLeaseAsset la WITH (NOLOCK)
Left JOIN Assets a WITH (NOLOCK) ON la.AssetAlias = a.Alias  
Left Join TaxDepTemplates tdt WITH (NOLOCK)  On la.TaxDepTemplate = tdt.Name 
Left Join BillToes b WITH (NOLOCK) ON la.BillToName = b.Name AND @BillToLevel != 'Deal'
Left Join Locations WITH (NOLOCK) ON Locations.CustomerId IS NULL AND UPPER(la.AcquisitionLocationCode) = UPPER(Locations.Code) AND Locations.IsActive = 1
Left Join Remittoes RemitTo WITH (NOLOCK) ON la.VendorRemitToUniqueIdentifier = RemitTo.UniqueIdentifier AND la.SalesTaxRemittanceResponsibility ='Vendor'
Left Join BookDepreciationTemplates bdt WITH (NOLOCK) ON la.BookDepreciationTemplateName = bdt.Name 
JOIN #ProcessableLeaseTemp plt WITH (NOLOCK) on la.LeaseId = plt.Id  
JOIN stgLease l WITH (NOLOCK) on plt.Id = l.Id AND a.CustomerId = l.R_CustomerId

UPDATE stgLeaseAsset  SET R_BranchAddressId = ba.Id
FROM stgLeaseAsset la WITH (NOLOCK)
JOIN #ProcessableLeaseTemp plt WITH (NOLOCK) on la.LeaseId = plt.Id  
JOIN stgLease l WITH (NOLOCK) on plt.Id = l.Id 
JOIN LegalEntities le on le.Id = l.R_LegalEntityId
JOIN Branches b on le.Id = b.LegalEntityId
JOIN BranchAddresses ba on la.BranchAddress = ba.AddressLine1
WHERE la.BranchAddress IS NOT NULL

UPDATE stgLeaseAsset  SET R_BranchAddressId = ba.Id
FROM stgLeaseAsset la WITH (NOLOCK)
JOIN #ProcessableLeaseTemp plt WITH (NOLOCK) on la.LeaseId = plt.Id  
JOIN stgLease l WITH (NOLOCK) on plt.Id = l.Id 
JOIN LegalEntities le on le.Id = l.R_LegalEntityId
JOIN Branches b on le.Id = b.LegalEntityId
JOIN BranchAddresses ba on b.Id = ba.BranchId
WHERE la.BranchAddress IS NULL


INSERT INTO #Params 
SELECT 'The following Lease: '+ Temp.SequenceNumber+' should have atleast one lease asset associated to it.' ,Temp.Id,Temp.SequenceNumber
FROM
(
	SELECT plt.Id,plt.SequenceNumber
	FROM 
		#ProcessableLeaseTemp plt
		LEFT JOIN stgLeaseAsset leaseasset ON plt.id = leaseasset.leaseid
	    WHERE leaseasset.Id IS NULL
)AS Temp
INSERT INTO #Params  
SELECT 'LeaseAsset: AssetAlias provided is not valid for [SequenceNumber, AssetAlias] :['+l.SequenceNumber+','+la.AssetAlias+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseAsset AS la WITH (NOLOCK)   
	 JOIN #ProcessableLeaseTemp AS l ON l.id = la.LeaseId  
	   WHERE la.R_AssetId IS NULL AND LTRIM(RTRIM(ISNULL(la.AssetAlias, '' ))) <> '' ;  

INSERT INTO #Params  
SELECT 'LeaseAsset: TaxDepTemplate provided is not valid for [SequenceNumber, TaxDepTemplate] :['+l.SequenceNumber+','+la.TaxDepTemplate+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseAsset AS la WITH (NOLOCK)   
	 JOIN #ProcessableLeaseTemp AS l ON l.id = la.LeaseId  
	   WHERE la.R_TaxDepTemplateId IS NULL AND LTRIM(RTRIM(ISNULL(la.TaxDepTemplate, '' ))) <> '';  

--INSERT INTO #Params
--SELECT 'LeaseAsset: Asset does not have a location for [SequenceNumber, AssetAlias] : ['+l.SequenceNumber+','+la.AssetAlias+']',l.Id, l.SequenceNumber
--FROM StgLeaseAsset AS la WITH (NOLOCK) 
--	JOIN #ProcessableLeaseTemp AS l ON l.id = la.LeaseId
--	JOIN stgAsset AS a ON la.AssetAlias = a.alias
--	LEFT JOIN stgAssetLocation al ON a.Id = al.AssetId 
--		WHERE al.Id is NULL;

INSERT INTO #Params  
SELECT 'LeaseAsset: BillToName provided is not valid for [SequenceNumber, BillToName] :['+l.SequenceNumber+','+la.BillToName+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseAsset AS la WITH (NOLOCK)   
	 JOIN #ProcessableLeaseTemp AS l ON l.id = la.LeaseId  
	   WHERE la.R_BillToId IS NULL AND LTRIM(RTRIM(ISNULL(la.BillToName, '' ))) <> '' AND @BillToLevel != 'Deal';
INSERT INTO #Params  
SELECT 'LeaseAsset: BillToName should not be provided as the BillToLevel is Deal [SequenceNumber, BillToName] :['+l.SequenceNumber+','+la.BillToName+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseAsset AS la WITH (NOLOCK)   
	 JOIN #ProcessableLeaseTemp AS l ON l.id = la.LeaseId
	 JOIN stgLease AS lease on l.Id = lease.Id  
	   WHERE la.R_BillToId IS NULL AND LTRIM(RTRIM(ISNULL(la.BillToName, '' ))) <> '' AND @BillToLevel = 'Deal' AND lease.BillToName != la.BillToName;

	   INSERT INTO #Params  
SELECT 'LeaseAsset: Factors, NBV, FMV, Rent, and Residuals should be given at SKU level for [SequenceNumber, AssetAlias] :[' + l.SequenceNumber + ',' + la.AssetAlias + ' ]'
     , l.Id
     , l.SequenceNumber
FROM stgLeaseAsset la
INNER JOIN Assets a ON la.R_AssetId = a.Id
INNER JOIN #ProcessableLeaseTemp AS l ON l.id = la.LeaseId
WHERE a.FinancialType IN('Real', 'Dummy')
      AND a.Id IN (SELECT DISTINCT AssetId FROM AssetSKUs)
     AND (la.BookedResidualFactor != 0.00
          OR la.ResidualBookedAmount_Amount != 0.00
          OR la.CustomerExpectedResidualFactor != 0.00
          OR la.CustomerExpectedResidualAmount_Amount != 0.00
          OR la.CustomerGuaranteedResidualFactor != 0.00
          OR la.CustomerGuaranteedResidualAmount_Amount != 0.00
          OR la.ThirdPartyGuaranteedResidualFactor != 0.00
          OR la.ThirdPartyGuaranteedResidualAmount_Amount != 0.00
		  OR la.NBV_Amount != 0.00
		  OR la.FMV_Amount != 0.00
		  OR la.FixedTermRentalAmount_Amount != 0.00
		  OR la.RentFactor != 0.00);

INSERT INTO #Params
SELECT 'LeaseAsset: Acquisition Location Code is not Valid for [SequenceNumber, AcquisitionLocationCode] :['+l.SequenceNumber+','+la.AcquisitionLocationCode+' ]',l.Id,l.SequenceNumber
FROM stgLeaseAsset As la WITH (NOLOCK)
	JOIN #ProcessableLeaseTemp AS l ON l.id = la.LeaseId
	JOIN stgLease AS lease on l.Id = lease.Id
	WHERE la.R_AcquisitionLocationId IS NULL AND la.AcquisitionLocationCode IS NOT NULL
INSERT INTO #Params  
SELECT 'LeaseAsset: Please provide RemitToUniqueIdentifier for [SequenceNumber]:['+l.SequenceNumber+']',l.Id,l.SequenceNumber
From stgLeaseAsset as la WITH (NOLOCK)
	JOIN #ProcessableLeaseTemp AS l ON l.id = la.LeaseId 
 WHERE la.SalesTaxRemittanceResponsibility ='Vendor' AND la.VendorRemitToUniqueIdentifier IS NULL
INSERT INTO #Params  
SELECT 'LeaseAsset: RemitToUniqueIdentifier provided is not valid for [SequenceNumber,VendorRemitToUniqueIdentifier]:['+l.SequenceNumber+','+la.VendorRemitToUniqueIdentifier+']',l.Id,l.SequenceNumber
From stgLeaseAsset as la WITH (NOLOCK)
	JOIN #ProcessableLeaseTemp AS l ON l.id = la.LeaseId 
 WHERE la.SalesTaxRemittanceResponsibility ='Vendor' AND la.R_VendorRemitToId IS NULL AND  la.VendorRemitToUniqueIdentifier IS NOT NULL
INSERT INTO #Params  
SELECT 'LeaseAsset: BookDepreciationTemplateName provided is not valid for [SequenceNumber, BookDepreciationTemplateName] :['+l.SequenceNumber+','+la.BookDepreciationTemplateName+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseAsset AS la WITH (NOLOCK)   
	 JOIN #ProcessableLeaseTemp AS l ON l.id = la.LeaseId  
	   WHERE la.R_BookDepreciationTemplateId IS NULL AND LTRIM(RTRIM(ISNULL(la.BookDepreciationTemplateName, '' ))) <> '' ;  
INSERT INTO #Params  
SELECT 'LeaseAsset: Both FixedTermRentalFactor and FixedTermRentalAmount cannot be provided for [SequenceNumber, AssetAlias] :['+l.SequenceNumber+','+la.AssetAlias+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseAsset AS la WITH (NOLOCK)   
     JOIN #ProcessableLeaseTemp AS l ON l.id = la.LeaseId  
       WHERE la.RentFactor > 0.00 AND la.FixedTermRentalAmount_Amount > 0.00
INSERT INTO #Params  
SELECT 'LeaseAsset: Both BookedResidualFactor and ResidualBookedAmount cannot be provided for [SequenceNumber, AssetAlias] :['+l.SequenceNumber+','+la.AssetAlias+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseAsset AS la WITH (NOLOCK)   
     JOIN #ProcessableLeaseTemp AS l ON l.id = la.LeaseId  
       WHERE la.BookedResidualFactor > 0.00 AND la.ResidualBookedAmount_Amount > 0.00
INSERT INTO #Params  
SELECT 'LeaseAsset: Both RVRecapFactor and RVRecapAmount cannot be provided for [SequenceNumber, AssetAlias] :['+l.SequenceNumber+','+la.AssetAlias+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseAsset AS la WITH (NOLOCK)   
     JOIN #ProcessableLeaseTemp AS l ON l.id = la.LeaseId  
       WHERE la.RVRecapFactor > 0.00 AND la.RVRecapAmount_Amount > 0.00
INSERT INTO #Params  
SELECT 'LeaseAsset: Both CustomerExpectedResidualFactor and CustomerExpectedResidualAmount cannot be provided for [SequenceNumber, AssetAlias] :['+l.SequenceNumber+','+la.AssetAlias+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseAsset AS la WITH (NOLOCK)   
     JOIN #ProcessableLeaseTemp AS l ON l.id = la.LeaseId  
       WHERE la.CustomerExpectedResidualFactor > 0.00 AND la.CustomerExpectedResidualAmount_Amount > 0.00
INSERT INTO #Params  
SELECT 'LeaseAsset: Both CustomerGuaranteedResidualFactor and CustomerGuaranteedResidualAmount cannot be provided for [SequenceNumber, AssetAlias] :['+l.SequenceNumber+','+la.AssetAlias+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseAsset AS la WITH (NOLOCK)   
     JOIN #ProcessableLeaseTemp AS l ON l.id = la.LeaseId  
       WHERE la.CustomerGuaranteedResidualFactor > 0.00 AND la.CustomerGuaranteedResidualAmount_Amount > 0.00
INSERT INTO #Params  
SELECT 'LeaseAsset: Both InterimRentFactor and InterimRentalAmount cannot be provided for [SequenceNumber, AssetAlias] :['+l.SequenceNumber+','+la.AssetAlias+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseAsset AS la WITH (NOLOCK)   
     JOIN #ProcessableLeaseTemp AS l ON l.id = la.LeaseId  
       WHERE la.InterimRentFactor > 0.00 AND la.InterimRentalAmount_Amount > 0.00
INSERT INTO #Params  
SELECT 'LeaseAsset: Both RVRecapFactor and RVRecapAmount cannot be provided for [SequenceNumber, AssetAlias] :['+l.SequenceNumber+','+la.AssetAlias+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseAsset AS la WITH (NOLOCK)   
     JOIN #ProcessableLeaseTemp AS l ON l.id = la.LeaseId  
       WHERE la.RVRecapFactor > 0.00 AND la.RVRecapAmount_Amount > 0.00
INSERT INTO #Params  
SELECT 'LeaseAsset: Both OTPRentFactor and OTPRentalAmount cannot be provided for [SequenceNumber, AssetAlias] :['+l.SequenceNumber+','+la.AssetAlias+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseAsset AS la WITH (NOLOCK)   
     JOIN #ProcessableLeaseTemp AS l ON l.id = la.LeaseId  
       WHERE la.OTPRentFactor > 0.00 AND la.OTPRentalAmount_Amount > 0.00
INSERT INTO #Params  
SELECT 'LeaseAsset: Both SupplementalRentFactor and SupplementalRent cannot be provided for [SequenceNumber, AssetAlias] :['+l.SequenceNumber+','+la.AssetAlias+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseAsset AS la WITH (NOLOCK)   
     JOIN #ProcessableLeaseTemp AS l ON l.id = la.LeaseId  
       WHERE la.SupplementalRentFactor > 0.00 AND la.SupplementalRent_Amount > 0.00
INSERT INTO #Params  
SELECT 'LeaseAsset: Both ThirdPartyGuaranteedResidualFactor and ThirdPartyGuaranteedResidualAmount cannot be provided for [SequenceNumber, AssetAlias] :['+l.SequenceNumber+','+la.AssetAlias+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseAsset AS la WITH (NOLOCK)   
     JOIN #ProcessableLeaseTemp AS l ON l.id = la.LeaseId  
       WHERE la.ThirdPartyGuaranteedResidualFactor > 0.00 AND la.ThirdPartyGuaranteedResidualAmount_Amount > 0.00
--=============================stgLeaseAssetSKU=================================  
select distinct las.Id, [as].Id AssetSKUId
into #stgLeaseAssetSKU
FROM stgLeaseAssetSKU las WITH (NOLOCK)
INNER JOIN StgLeaseAsset sla WITH (NOLOCK) ON sla.Id = las.LeaseAssetId
INNER JOIN AssetSKUs [as] WITH (NOLOCK) ON las.SKUAlias = [as].Alias AND [as].AssetId = sla.R_AssetId
INNER JOIN #ProcessableLeaseTemp ltemp on sla.LeaseId = ltemp.Id

IF EXISTS(SELECT Id FROM #stgLeaseAssetSKU)
BEGIN
	DECLARE @BatchSize BIGINT = 5000;

	WHILE(EXISTS(SELECT Id FROM #stgLeaseAssetSKU))
	BEGIN
		CREATE TABLE #SKUBatchInfo (Id BIGINT, AssetSKUId BIGINT)

		DELETE TOP (@BatchSize) FROM #stgLeaseAssetSKU
		OUTPUT deleted.Id, deleted.AssetSKUId
		INTO #SKUBatchInfo

		IF EXISTS(SELECT * FROM #SKUBatchInfo)
		BEGIN
			UPDATE stgLeaseAssetSKU  
			SET R_SKUAliasId = sku.AssetSKUId  
			FROM stgLeaseAssetSKU las
			INNER JOIN #SKUBatchInfo sku on las.Id=sku.Id			
		END

		DROP TABLE #SKUBatchInfo
	END
END 

INSERT INTO #Params  
SELECT 'LeaseAssetSKU: SKUAlias provided is not valid for [SequenceNumber, SKUAlias] :['+l.SequenceNumber+','+las.SKUAlias+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseAssetSKU las WITH (NOLOCK)
INNER JOIN stgLeaseAsset AS la WITH (NOLOCK) ON las.LeaseAssetId = la.Id
INNER JOIN #ProcessableLeaseTemp AS l ON l.id = la.LeaseId  
WHERE las.R_SKUAliasId IS NULL AND LTRIM(RTRIM(las.SKUAlias)) <> '';  

INSERT INTO #Params  
SELECT 'LeaseAssetSKU: Residuals cannot be given for soft SKUs for [SequenceNumber, SKUAlias] :[' + l.SequenceNumber + ',' + las.SKUAlias + ' ]'
     , l.Id
     , l.SequenceNumber
FROM stgLeaseAssetSKU las WITH(NOLOCK)
     INNER JOIN stgLeaseAsset AS la WITH(NOLOCK) ON las.LeaseAssetId = la.Id
     INNER JOIN Assets a ON la.R_AssetId = a.Id
     INNER JOIN AssetSKUs [AS] ON las.SKUAlias = [AS].Alias AND la.R_AssetId = [AS].AssetId
     INNER JOIN AssetTypes [AT] ON [AT].Id = [AS].TypeId
     INNER JOIN #ProcessableLeaseTemp AS l ON l.id = la.LeaseId
WHERE a.FinancialType IN('Real', 'Dummy')
     AND [AT].IsSoft = 1
     AND (las.BookedResidualFactor != 0.00
          OR las.BookedResidual_Amount != 0.00
          OR las.CustomerExpectedResidualFactor != 0.00
          OR las.CustomerExpectedResidual_Amount != 0.00
          OR las.CustomerGuaranteedResidualFactor != 0.00
          OR las.CustomerGuaranteedResidual_Amount != 0.00
          OR las.ThirdPartyGuaranteedResidualFactor != 0.00
          OR las.ThirdPartyGuaranteedResidual_Amount != 0.00);
--=============================stgLeaseInterestRate=================================  
UPDATE stgLeaseInterestRate  
  SET stgLeaseInterestRate.R_FloatRateIndexId = fri.Id  
FROM FloatRateIndexes fri  WITH(NOLOCK)
	   WHERE stgLeaseInterestRate.FloatRateIndexName = fri.Name AND LeaseFinanceDetailId IN (SELECT ID FROM #ProcessableLeaseTemp);  
INSERT INTO #Params  
SELECT 'LeaseInterestRate: FloatRateIndexName provided is not valid for [SequenceNumber, FloatRateIndexName] :['+l.SequenceNumber+','+lir.FloatRateIndexName+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseInterestRate AS lir WITH (NOLOCK)   
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lir.LeaseFinanceDetailId  
	   WHERE lir.R_FloatRateIndexId IS NULL AND LTRIM(RTRIM(ISNULL(lir.FloatRateIndexName, '' ))) <> '' ;
INSERT INTO #Params  
SELECT 'LeaseInterestRate: HighPrimeInterest cannot be true when FloatRate is false', l.Id, l.SequenceNumber  
FROM stgLeaseInterestRate AS lir WITH (NOLOCK)   
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lir.LeaseFinanceDetailId  
	   WHERE lir.IsHighPrimeInterest = 1 AND lir.IsFloatRate = 0;
--=============================stgLeaseInsuranceRequirement=================================  
UPDATE stgLeaseInsuranceRequirement  
  SET stgLeaseInsuranceRequirement.R_CoverageTypeConfigId = ctc.Id  
FROM CoverageTypeConfigs ctc  WITH (NOLOCK) 
	   WHERE stgLeaseInsuranceRequirement.CoverageType = ctc.CoverageType AND LeaseId IN (SELECT ID FROM #ProcessableLeaseTemp);  
INSERT INTO #Params  
SELECT 'LeaseInsuranceRequirement: CoverageType provided is not valid for [SequenceNumber, CoverageType] :['+l.SequenceNumber+','+lir.CoverageType+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseInsuranceRequirement AS lir WITH (NOLOCK)   
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lir.LeaseId  
	   WHERE lir.R_CoverageTypeConfigId IS NULL AND LTRIM(RTRIM(ISNULL(lir.CoverageType, '' ))) <> '' ;  
--=============================stgLeaseBlendedItem=================================  

UPDATE stgLeaseBlendedItem  
SET R_ParentBlendedItemId = bi.Id,R_BlendedItemCodeId = bic.Id ,R_BillTOId = bt.Id,R_ReceivableCodeId = rc.Id,R_PayableCodeId = pc.Id,R_LocationId = l.id
,R_RecognitionGlTransactionType = Case When lbi.Type in ('IDC','Expense') Then 'BlendedExpenseRecognition' Else 'BlendedIncomeRecognition' End
,R_GlTransactionType = Case When lbi.Type in ('IDC','Expense') Then 'BlendedExpenseSetup' Else 'BlendedIncomeSetup' End 
,R_BookingGLTemplateId = g.Id,R_RecognitionGLTemplateId = rg.Id,R_TaxDepTemplateId = tdt.Id,R_PartyId = p.Id 
,R_ReceivableRemitToId = rt.Id, R_PayableRemitToId = r.Id, R_FeeDetailId = fd.Id
FROM stgLeaseBlendedItem lbi  WITH (NOLOCK)  
Left Join stgLeaseBlendedItemAsset lba  WITH (NOLOCK) on lbi.id = lba.LeaseBlendedItemId
Left Join BlendedItems bi ON lbi.ParentBlendedItemName = bi.Name 
Left Join BlendedItemCodes bic WITH (NOLOCK) ON lbi.BlendedItemCode = bic.Name
Left Join FeeDetails fd  WITH (NOLOCK) ON fd.BlendedItemCodeId = bic.Id
Left Join dbo.BillToes bt WITH (NOLOCK) ON lbi.BillToName = bt.Name
Left Join ReceivableCodes rc WITH (NOLOCK) ON lbi.ReceivableCodeName = rc.Name
Left Join dbo.PayableCodes pc WITH (NOLOCK) ON lbi.PayableCodeName = pc.Name 
Left Join dbo.Locations l WITH (NOLOCK) ON lbi.LocationCode = l.Code
Left JOIN dbo.Assets a WITH (NOLOCK) ON lba.AssetAlias = a.Alias
Left JOIN StgLeaseAsset la WITH (NOLOCK) ON lbi.LeaseId = la.LeaseId AND lba.AssetAlias = la.AssetAlias 
Left Join dbo.GLTemplates g WITH (NOLOCK) ON lbi.BookingGLTemplateName = g.Name   
Left JOIN dbo.GLTransactionTypes gt  WITH (NOLOCK) ON g.GLTransactionTypeId = gt.Id   AND gt.Name = lbi.R_GlTransactionType 
Left Join dbo.GLTemplates rg WITH (NOLOCK) ON lbi.RecognitionGLTemplateName = rg.Name   
Left JOIN dbo.GLTransactionTypes rgt  WITH (NOLOCK) ON rg.GLTransactionTypeId = rgt.Id   AND rgt.Name = lbi.R_RecognitionGlTransactionType 
Left Join dbo.TaxDepTemplates tdt WITH (NOLOCK) ON lbi.TaxDepTemplateName = tdt.Name
Left Join dbo.Parties p WITH (NOLOCK)  ON lbi.PartyNumber = p.PartyNumber
Left Join dbo.RemitToes rt WITH (NOLOCK)  ON lbi.RemitToUniqueIdentifier = rt.UniqueIdentifier
Left Join dbo.RemitToes r WITH (NOLOCK) ON lbi.PayableRemitToUniqueIdentifier = r.UniqueIdentifier 
Join #ProcessableLeaseTemp plt  WITH (NOLOCK) on plt.Id = lbi.LeaseId 

INSERT INTO #Params  
SELECT 'LeaseBlendedItem: ParentBlendedItemName provided is not valid for [SequenceNumber, ParentBlendedItemName] :['+l.SequenceNumber+','+lbi.ParentBlendedItemName+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseBlendedItem AS lbi WITH (NOLOCK)   
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lbi.LeaseId  
	   WHERE lbi.R_ParentBlendedItemId IS NULL AND LTRIM(RTRIM(ISNULL(lbi.ParentBlendedItemName, '' ))) <> '' ;  
INSERT INTO #Params  
SELECT 'LeaseBlendedItem: BlendedItemCode provided is not valid for [SequenceNumber, BlendedItemCode] :['+l.SequenceNumber+','+lbi.BlendedItemCode+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseBlendedItem AS lbi WITH (NOLOCK)   
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lbi.LeaseId  
	   WHERE lbi.R_BlendedItemCodeId IS NULL AND LTRIM(RTRIM(ISNULL(lbi.BlendedItemCode, '' ))) <> '' ;  
INSERT INTO #Params  
SELECT 'LeaseBlendedItem: BillToName provided is not valid for [SequenceNumber, BillToName] :['+l.SequenceNumber+','+ISNULL(lbi.BillToName, '')+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseBlendedItem AS lbi WITH (NOLOCK)   
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lbi.LeaseId  
	   WHERE lbi.R_BillToId IS NULL AND (LTRIM(RTRIM(ISNULL(lbi.BillToName, '' ))) <> '' OR lbi.BillToName Is NOT NULL) ;  
INSERT INTO #Params  
SELECT 'LeaseBlendedItem: ReceivableCodeName provided is not valid for [SequenceNumber, ReceivableCodeName] :['+l.SequenceNumber+','+lbi.ReceivableCodeName+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseBlendedItem AS lbi WITH (NOLOCK)   
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lbi.LeaseId  
	   WHERE lbi.R_ReceivableCodeId IS NULL AND LTRIM(RTRIM(ISNULL(lbi.ReceivableCodeName, '' ))) <> '' ;  
INSERT INTO #Params  
SELECT 'LeaseBlendedItem: PayableCodeName provided is not valid for [SequenceNumber, PayableCodeName] :['+l.SequenceNumber+','+lbi.PayableCodeName+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseBlendedItem AS lbi WITH (NOLOCK)   
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lbi.LeaseId  
	   WHERE lbi.R_PayableCodeId IS NULL AND LTRIM(RTRIM(ISNULL(lbi.PayableCodeName, '' ))) <> '' ;  
INSERT INTO #Params  
SELECT 'LeaseBlendedItem: LocationCode provided is not valid for [SequenceNumber, LocationCode] :['+l.SequenceNumber+','+lbi.LocationCode+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseBlendedItem AS lbi WITH (NOLOCK)   
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lbi.LeaseId  
	   WHERE lbi.R_LocationId IS NULL AND LTRIM(RTRIM(ISNULL(lbi.LocationCode, '' ))) <> '' ;   
With CTE_MultipleAssets AS 
(
  	SELECT lbi.Id, COUNT(lbi.Id) AS Count
	FROM #ProcessableLeaseTemp AS l
	INNER JOIN stgLeaseBlendedItem lbi ON l.id = lbi.LeaseId  
	INNER JOIN stgLeaseBlendedItemAsset lbia WITH (NOLOCK)  ON lbi.Id = lbia.LeaseBlendedItemId
	WHERE NOT (lbi.Type = 'Income' AND IsAssetBased = 1 AND IsETC = 1)
	GROUP BY lbi.Id
)
INSERT INTO #Params  
SELECT 'LeaseBlendedItem: Multiple assets cannot be added for [SequenceNumber, BlendedItemName] :['+l.SequenceNumber+','+lbi.Name+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseBlendedItem AS lbi WITH (NOLOCK)   
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lbi.LeaseId
	 JOIN CTE_MultipleAssets AS CTE ON CTE.Id = lbi.Id
	   WHERE CTE.Count > 1
UPDATE stgLeaseBlendedItemAsset  
  SET stgLeaseBlendedItemAsset.R_AssetId = a.Id  
FROM stgLeaseBlendedItem lbi WITH (NOLOCK)   
	 INNER JOIN stgLeaseBlendedItemAsset WITH (NOLOCK)  ON lbi.Id = LeaseBlendedItemId  
	 INNER JOIN dbo.Assets a WITH (NOLOCK) ON stgLeaseBlendedItemAsset.AssetAlias = a.Alias
	 INNER JOIN StgLeaseAsset la WITH (NOLOCK) ON lbi.LeaseId = la.LeaseId AND stgLeaseBlendedItemAsset.AssetAlias = la.AssetAlias  
	 WHERE lbi.LeaseId IN (SELECT ID FROM #ProcessableLeaseTemp);  
INSERT INTO #Params  
SELECT 'ETC blended items can only exist for Operating / Direct Finance leases for [SequenceNumber] :['+l.SequenceNumber + ' ]', l.Id, l.SequenceNumber  
FROM stgLeaseBlendedItem AS lbi WITH (NOLOCK)   
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lbi.LeaseId
	 JOIN stgLeaseFinanceDetail lfd ON lfd.Id = l.id
	   WHERE lbi.IsETC = 1 AND NOT (lfd.ContractType ='Operating' OR  lfd.ContractType ='DirectFinance')
print '8'
INSERT INTO #Params  
SELECT 'LeaseBlendedItemAsset: AssetAlias provided is not valid for [SequenceNumber, AssetAlias] :['+l.SequenceNumber+','+lbia.AssetAlias+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseBlendedItem AS lbi WITH (NOLOCK)   
	 INNER JOIN stgLeaseBlendedItemAsset lbia WITH (NOLOCK)  ON lbi.Id = lbia.LeaseBlendedItemId  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lbi.LeaseId  
	   WHERE lbia.R_AssetId IS NULL AND LTRIM(RTRIM(ISNULL(lbia.AssetAlias, '' ))) <> '';  

INSERT INTO #Params  
SELECT 'LeaseBlendedItem: BookingGLTemplateName provided is not valid for [SequenceNumber, BookingGLTemplateName] :['+l.SequenceNumber+','+lbi.BookingGLTemplateName+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseBlendedItem AS lbi WITH (NOLOCK)   
	 JOIN #ProcessableLeaseTemp AS l WITH (NOLOCK)  ON l.id = lbi.LeaseId  
	   WHERE lbi.R_BookingGLTemplateId IS NULL AND LTRIM(RTRIM(ISNULL(lbi.BookingGLTemplateName, '' ))) <> '';  
INSERT INTO #Params  
SELECT 'LeaseBlendedItem: RecognitionGLTemplateName provided is not valid for [SequenceNumber, RecognitionGLTemplateName] :['+l.SequenceNumber+','+lbi.RecognitionGLTemplateName+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseBlendedItem AS lbi  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lbi.LeaseId  
	   WHERE lbi.R_RecognitionGLTemplateId IS NULL AND LTRIM(RTRIM(ISNULL(lbi.RecognitionGLTemplateName, '' ))) <> '';  
INSERT INTO #Params  
SELECT 'LeaseBlendedItem: TaxDepTemplateName provided is not valid for [SequenceNumber, TaxDepTemplateName] :['+l.SequenceNumber+','+lbi.TaxDepTemplateName+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseBlendedItem AS lbi  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lbi.LeaseId  
	   WHERE lbi.R_TaxDepTemplateId IS NULL AND LTRIM(RTRIM(ISNULL(lbi.TaxDepTemplateName, '' ))) <> '' ;  
INSERT INTO #Params  
SELECT 'LeaseBlendedItem: PartyNumber provided is not valid for [SequenceNumber, PartyNumber] :['+l.SequenceNumber+','+lbi.PartyNumber+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseBlendedItem AS lbi  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lbi.LeaseId  
	   WHERE lbi.R_PartyId IS NULL AND LTRIM(RTRIM(ISNULL(lbi.PartyNumber, '' ))) <> '' ;  
INSERT INTO #Params  
SELECT 'LeaseBlendedItem: RemitToUniqueIdentifier provided is not valid for [SequenceNumber, RemitToUniqueIdentifier] :['+l.SequenceNumber+','+lbi.RemitToUniqueIdentifier+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseBlendedItem AS lbi  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lbi.LeaseId  
	   WHERE lbi.R_ReceivableRemitToId IS NULL AND LTRIM(RTRIM(ISNULL(lbi.RemitToUniqueIdentifier, '' ))) <> '' ;
INSERT INTO #Params
SELECT 'LeaseBlendedItem: RemitToUniqueIdentifier provided is not associated with the Legal Entity of the contract [SequenceNumber,LegalEntity, RemitToUniqueIdentifier] :['+l.SequenceNumber+','+CAST(ISNULL(l.R_LegalEntityId,'') AS NVARCHAR)+','+ ISNULL(lbi.RemitToUniqueIdentifier,'')+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseBlendedItem AS lbi  
	 JOIN #ProcessableLeaseTemp AS t ON t.id = lbi.LeaseId  
	 JOIN stglease AS l ON l.id = t.Id
	   WHERE lbi.R_ReceivableRemitToId IS NOT NULL
	   AND NOT EXISTS (SELECT Id FROM LegalEntityRemitToes ler WHERE ler.IsActive=1 AND ler.LegalEntityId=l.R_LegalEntityId AND lbi.R_ReceivableRemitToId=ler.RemitToId)
INSERT INTO #Params 
SELECT 'LeaseBlendedItem: PayableRemitToUniqueIdentifier provided is not valid for [SequenceNumber, PayableRemitToUniqueIdentifier] :['+l.SequenceNumber+','+lbi.PayableRemitToUniqueIdentifier+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseBlendedItem AS lbi  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lbi.LeaseId  
	   WHERE lbi.R_PayableRemitToId IS NULL AND LTRIM(RTRIM(ISNULL(lbi.PayableRemitToUniqueIdentifier, '' ))) <> '' ; 
INSERT INTO #Params  
SELECT 'LeaseBlendedItem: StartDate should be on or beyond the CommencementDate.[SequenceNumber, BlendedItemName, CommencementDate, StartDate] :['+l.SequenceNumber+', '+lbi.Name+', '+IsNull(CONVERT(NVARCHAR(10),lfd.CommencementDate),'NULL')+', '+IsNull(CONVERT(NVARCHAR(10),lbi.StartDate),'NULL')+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseBlendedItem AS lbi  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lbi.LeaseId  
	 JOIN stgLeaseFinanceDetail lfd on lfd.Id = l.Id
	 WHERE (lbi.StartDate Is NULL OR (lbi.StartDate < lfd.CommencementDate)) AND BookRecognitionMode != 'RecognizeImmediately';
INSERT INTO #Params  
SELECT 'LeaseBlendedItem: BookRecognitionMode should be RecognizeImmediately for [SequenceNumber, BlendedItemName] :['+l.SequenceNumber+', '+lbi.Name+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseBlendedItem AS lbi  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lbi.LeaseId  
	 WHERE lbi.Type ='Income' AND lbi.IsAssetBased = 1 AND lbi.IsETC = 1 AND lbi.BookRecognitionMode != 'RecognizeImmediately'
INSERT INTO #Params  
SELECT 'LeaseBlendedItem: EndDate should not be null.[SequenceNumber, BlendedItemName] :['+l.SequenceNumber+', '+lbi.Name+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseBlendedItem AS lbi  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lbi.LeaseId  
	 JOIN stgLeaseFinanceDetail lfd on lfd.Id = l.Id
	 WHERE lbi.EndDate Is NULL AND (lbi.BookRecognitionMode != 'RecognizeImmediately' AND NOT (lbi.Type ='Income' AND lbi.IsAssetBased = 1 AND lbi.IsETC = 1)) AND lbi.Type != 'IDC';
INSERT INTO #Params  
SELECT 'LeaseBlendedItem: Start Date must be on or before End Date.[SequenceNumber, BlendedItemName, StartDate, EndDate] :['+l.SequenceNumber+', '+lbi.Name+', '+IsNull(CONVERT(NVARCHAR(10),lbi.StartDate),'NULL')+', '+IsNull(CONVERT(NVARCHAR(10),lbi.EndDate),'NULL')+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseBlendedItem AS lbi  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lbi.LeaseId  
	 JOIN stgLeaseFinanceDetail lfd on lfd.Id = l.Id
	 WHERE (lbi.StartDate Is NOT NULL AND (lbi.StartDate > lbi.EndDate)) AND lbi.BookRecognitionMode != 'RecognizeImmediately' AND lbi.Type != 'IDC';
INSERT INTO #Params  
SELECT 'LeaseBlendedItem: Tax Credit Tax Basis Percentage should be zero for [SequenceNumber, BlendedItemName] :['+l.SequenceNumber+', '+lbi.Name+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseBlendedItem AS lbi  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lbi.LeaseId  
	 WHERE NOT (lbi.Type ='Income' AND lbi.IsAssetBased = 1 AND lbi.IsETC = 1) AND lbi.TaxCreditTaxBasisPercentage != 0.00 
INSERT INTO #Params  
SELECT 'LeaseBlendedItem: Tax Credit Tax Basis Percentage should not be zero for [SequenceNumber, BlendedItemName] :['+l.SequenceNumber+', '+lbi.Name+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseBlendedItem AS lbi  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lbi.LeaseId  
	 WHERE lbi.Type ='Income' AND lbi.IsAssetBased = 1 AND lbi.IsETC = 1 AND lbi.TaxCreditTaxBasisPercentage = 0.00 
INSERT INTO #Params  
SELECT 'LeaseBlendedItem: Occurrence should be One Time for [SequenceNumber, BlendedItemName] :['+l.SequenceNumber+', '+lbi.Name+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseBlendedItem AS lbi  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lbi.LeaseId  
	 WHERE lbi.Type ='Income' AND lbi.IsAssetBased = 1 AND lbi.IsETC = 1 AND Occurrence != 'OneTime'
INSERT INTO #Params  
SELECT 'LeaseBlendedItem: Start Date and End Date should be null for [SequenceNumber, BlendedItemName] :['+l.SequenceNumber+', '+lbi.Name+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseBlendedItem AS lbi  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lbi.LeaseId  
	 WHERE lbi.Type ='Income' AND lbi.IsAssetBased = 1 AND lbi.IsETC = 1 AND (lbi.StartDate IS NOT NULL OR lbi.EndDate IS NOT NULL)
INSERT INTO #Params  
SELECT 'LeaseBlendedItem: At least one active asset must be associated for [SequenceNumber, BlendedItemName] :['+l.SequenceNumber+', '+lbi.Name+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseBlendedItem AS lbi  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lbi.LeaseId  
	 WHERE lbi.Id IN
				(SELECT lbi.Id FROM 
				stgLeaseBlendedItem lbi
			    INNER JOIN #ProcessableLeaseTemp AS l ON l.id = lbi.LeaseId 
				LEFT JOIN stgLeaseBlendedItemAsset lbia WITH (NOLOCK)  ON lbi.Id = lbia.LeaseBlendedItemId
				WHERE IsAssetBased = 1 AND lbia.Id IS NULL)
--=============================stgContractPledge==============================
UPDATE stgContractPledge  
  SET stgContractPledge.R_InterestBaseId = fri.Id  
FROM stgContractPledge 
     JOIN  FloatRateIndexes fri  WITH(NOLOCK) ON stgContractPledge.InterestBase = fri.Name
	   WHERE stgContractPledge.R_InterestBaseId IS NULL AND LeaseId IN (SELECT ID FROM #ProcessableLeaseTemp);  

UPDATE stgContractPledge  
  SET stgContractPledge.R_LoanNumberId = fri.Id  
FROM stgContractPledge 
     JOIN  ContractPledgeConfigs fri  WITH(NOLOCK) ON stgContractPledge.LoanNumber = fri.LoanNumber
	   WHERE stgContractPledge.R_LoanNumberId IS NULL AND LeaseId IN (SELECT ID FROM #ProcessableLeaseTemp); 


INSERT INTO #Params  
SELECT 'ContractPledge: Please Enter Loan Number for [SequenceNumber] :['+l.SequenceNumber+' ]', l.Id, l.SequenceNumber
FROM stgContractPledge sp
JOIN #ProcessableLeaseTemp AS l ON l.id = sp.LeaseId
WHERE sp.R_LoanNumberId IS NULL


--=============================stgLeaseOTPSharingParameter==============================
INSERT INTO #Params  
SELECT 'LeaseOTPParameter: PaymentNumber provided is not valid for [SequenceNumber,PaymentNumber] :['+l.SequenceNumber+','+CONVERT(nvarchar(max),PaymentNumber)+' ]', l.Id, l.SequenceNumber
FROM stgLeaseOTPSharingParameter sp
JOIN #ProcessableLeaseTemp AS l ON l.id = sp.LeaseFinanceDetailId
WHERE sp.PaymentNumber<=0

INSERT INTO #Params  
SELECT 'LeaseOTPParameter: OTPSharingPercentage provided is not valid for [SequenceNumber,OTPSharingPercentage] :['+l.SequenceNumber+','+CONVERT(nvarchar(max),OTPSharingPercentage)+' ]', l.Id, l.SequenceNumber
FROM stgLeaseOTPSharingParameter sp
JOIN #ProcessableLeaseTemp AS l ON l.id = sp.LeaseFinanceDetailId	
WHERE OTPSharingPercentage<0 OR OTPSharingPercentage>100
--=============================stgLeaseAdditionalCharge=================================  
UPDATE stgLeaseAdditionalCharge
  SET stgLeaseAdditionalCharge.R_FeeId= ftc.Id
FROM dbo.FeeTypeConfigs ftc WITH (NOLOCK)
	   WHERE stgLeaseAdditionalCharge.FeeName = ftc.Name AND LeaseId IN (SELECT ID FROM #ProcessableLeaseTemp);
INSERT INTO #Params  
SELECT 'LeaseAdditionalCharge: FeeName provided is not valid for [SequenceNumber, AdditionalCharge] :['+l.SequenceNumber+','+lac.FeeName+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseAdditionalCharge AS lac  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lac.LeaseId  
	   WHERE lac.R_FeeId IS NULL AND LTRIM(RTRIM(ISNULL(lac.FeeName, '' ))) <> '' ; 
UPDATE stgLeaseAdditionalCharge  
  SET stgLeaseAdditionalCharge.R_GLTemplateId = g.Id  
FROM stgLeaseAdditionalCharge AS lac   WITH (NOLOCK) 
INNER JOIN stgLease AS l  WITH (NOLOCK) ON l.Id = lac.LeaseId  
INNER JOIN #ProcessableLeaseTemp AS ltmp  WITH (NOLOCK) ON l.Id = ltmp.Id  
INNER JOIN LegalEntities AS le WITH (NOLOCK)  on l.LegalEntityNumber = le.LegalEntityNumber  
INNER JOIN #GlTemplateTemp g  WITH (NOLOCK) ON lac.GLTemplateName = g.Name AND g.GLConfigurationId = le.GLConfigurationId AND g.LegalEntityNumber = le.LegalEntityNumber AND g.GLTransactionType = 'AdditionalCapitalizedCharges'  
INSERT INTO #Params  
SELECT 'LeaseAdditionalCharge: GLTemplateName provided is not valid for [SequenceNumber, GLTemplateName] :['+l.SequenceNumber+','+lac.GLTemplateName+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseAdditionalCharge AS lac  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lac.LeaseId  
	   WHERE lac.R_GLTemplateId IS NULL AND LTRIM(RTRIM(ISNULL(lac.GLTemplateName, '' ))) <> '' ;
UPDATE stgLeaseAdditionalCharge  
  SET stgLeaseAdditionalCharge.R_ReceivableCodeId = rc.Id ,stgLeaseAdditionalCharge.IsIncludeinAPR = rc.IncludeInEAR ,stgLeaseAdditionalCharge.IsVatable = case when rc.IsTaxExempt=1 then 0 else 1 end  
FROM dbo.ReceivableCodes rc  WITH (NOLOCK)
	   WHERE stgLeaseAdditionalCharge.ReceivableCodeName = rc.Name AND LeaseId IN (SELECT ID FROM #ProcessableLeaseTemp);  

UPDATE stgLeaseAdditionalCharge  
  SET stgLeaseAdditionalCharge.R_PayableCodeId = rc.Id  
FROM dbo.PayableCodes rc  WITH (NOLOCK)
	   WHERE stgLeaseAdditionalCharge.PayableCode = rc.Name AND LeaseId IN (SELECT ID FROM #ProcessableLeaseTemp);  

UPDATE stgLeaseAdditionalCharge  
  SET stgLeaseAdditionalCharge.R_VendorId = p.Id  
FROM stgLeaseAdditionalCharge AS lac   WITH (NOLOCK) 
INNER JOIN stgLease AS l  WITH (NOLOCK) ON l.Id = lac.LeaseId  
INNER JOIN #ProcessableLeaseTemp AS ltmp  WITH (NOLOCK) ON l.Id = ltmp.Id  
INNER JOIN Parties p on p.PartyNumber = lac.VendorNumber
INNER JOIN VendorLegalEntities vl on vl.VendorId = p.Id AND vl.LegalEntityId = l.R_LegalEntityId

UPDATE stgLeaseAdditionalCharge  
  SET stgLeaseAdditionalCharge.R_RemitToId = r.Id  
FROM stgLeaseAdditionalCharge AS lac   WITH (NOLOCK) 
INNER JOIN stgLease AS l  WITH (NOLOCK) ON l.Id = lac.LeaseId  
INNER JOIN #ProcessableLeaseTemp AS ltmp  WITH (NOLOCK) ON l.Id = ltmp.Id  
INNER JOIN RemitToes r on r.Name = lac.RemitToName
INNER JOIN PartyRemitToes pr on pr.PartyId = lac.R_VendorId AND r.Id = pr.RemitToId

INSERT INTO #Params  
SELECT 'LeaseAdditionalCharge: RemitTo provided is not valid for [SequenceNumber, Vendor] :['+l.SequenceNumber+','+lac.RemitToName+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseAdditionalCharge AS lac  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lac.LeaseId  
	   WHERE lac.R_RemitToId IS NULL AND lac.SundryType in ('PassThrough','PayableOnly') AND LTRIM(RTRIM(ISNULL(lac.RemitToName, '' ))) <> '' ;

INSERT INTO #Params  
SELECT 'LeaseAdditionalCharge: Vendor Number provided is not valid for [SequenceNumber, Vendor] :['+l.SequenceNumber+','+lac.VendorNumber+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseAdditionalCharge AS lac  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lac.LeaseId  
	   WHERE lac.R_VendorId IS NULL AND lac.SundryType in ('PassThrough','PayableOnly') AND LTRIM(RTRIM(ISNULL(lac.VendorNumber, '' ))) <> '' ;

INSERT INTO #Params  
SELECT 'LeaseAdditionalCharge: ReceivableCodeName provided is not valid for [SequenceNumber, ReceivableCodeName] :['+l.SequenceNumber+','+lac.ReceivableCodeName+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseAdditionalCharge AS lac  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lac.LeaseId  
	   WHERE lac.R_ReceivableCodeId IS NULL AND lac.SundryType in ('PassThrough','ReceivableOnly') AND LTRIM(RTRIM(ISNULL(lac.ReceivableCodeName, '' ))) <> '' ;
INSERT INTO #Params  
SELECT 'LeaseAdditionalCharge: PayableCodeName provided is not valid for [SequenceNumber, PayableCodeName] :['+l.SequenceNumber+','+lac.PayableCode+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseAdditionalCharge AS lac  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lac.LeaseId  
	   WHERE lac.R_PayableCodeId IS NULL AND lac.SundryType in ('PassThrough','PayableOnly') AND LTRIM(RTRIM(ISNULL(lac.PayableCode, '' ))) <> '' ;
INSERT INTO #Params
SELECT 'LeaseAdditionalCharge: Enter Receivable Code Name for [SequenceNumber, ReceivableCodeName] :['+l.SequenceNumber+','+ISNULL(lac.ReceivableCodeName,'NULL')+' ]',l.Id,l.SequenceNumber
FROM stgLeaseAdditionalCharge as lac
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lac.LeaseId  
	 JOIN stgLeaseFinanceDetail lfd on lfd.Id = l.Id
	WHERE lac.Capitalize = 0  AND lac.SundryType in ('PassThrough','ReceivableOnly') AND LTRIM(RTRIM(ISNULL(LAC.ReceivableCodeName, ''))) =''
INSERT INTO #Params
SELECT 'LeaseAdditionalCharge: Enter ReceivableDueDate for [SequenceNumber, LeaseAdditionalChargeId] :['+l.SequenceNumber+','+CONVERT(nvarchar(20),lac.Id)+' ]',l.Id,l.SequenceNumber
FROM stgLeaseAdditionalCharge as lac
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lac.LeaseId  
	 JOIN stgLeaseFinanceDetail lfd on lfd.Id = l.Id
	WHERE lac.Capitalize = 0  AND lac.SundryType in ('PassThrough','ReceivableOnly')AND LAC.ReceivableDueDate IS NULL
INSERT INTO #Params
SELECT 'LeaseAdditionalCharge: Enter Fee Name for [SequenceNumber, LeaseAdditionalChargeId] :['+l.SequenceNumber+','+CONVERT(nvarchar(20),lac.Id)+' ]',l.Id,l.SequenceNumber
FROM stgLeaseAdditionalCharge as lac
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lac.LeaseId  
	 JOIN stgLeaseFinanceDetail lfd on lfd.Id = l.Id
	WHERE LTRIM(RTRIM(ISNULL(LAC.FeeName, ''))) =''
INSERT INTO #Params
SELECT 'LeaseAdditionalCharge: Enter Amount for [SequenceNumber, LeaseAdditionalChargeId] :['+l.SequenceNumber+','+CONVERT(nvarchar(20),lac.Id)+' ]',l.Id,l.SequenceNumber
FROM stgLeaseAdditionalCharge as lac
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lac.LeaseId  
	 JOIN stgLeaseFinanceDetail lfd on lfd.Id = l.Id
	WHERE  LAC.Amount_Amount =0
INSERT INTO #Params
SELECT 'LeaseAdditionalCharge: Enter GLTemplate for [SequenceNumber, LeaseAdditionalChargeId] :['+l.SequenceNumber+','+CONVERT(nvarchar(20),lac.Id)+' ]',l.Id,l.SequenceNumber
FROM stgLeaseAdditionalCharge as lac
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lac.LeaseId  
	 JOIN stgLeaseFinanceDetail lfd on lfd.Id = l.Id
	WHERE lac.Capitalize = 1 and LTRIM(RTRIM(ISNULL(lac.GLTemplateName, ''))) =''
INSERT INTO #Params
SELECT 'LeaseAdditionalCharge: Enter RecurringNumber for [SequenceNumber, LeaseAdditionalChargeId] :['+l.SequenceNumber+','+CONVERT(nvarchar(20),lac.Id)+' ]',l.Id,l.SequenceNumber
FROM stgLeaseAdditionalCharge as lac
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lac.LeaseId  
	 JOIN stgLeaseFinanceDetail lfd on lfd.Id = l.Id
	WHERE lac.Recurring = 1 AND (LAC.RecurringNumber Is NULL OR LAC.RecurringNumber = 0)
INSERT INTO #Params
SELECT 'LeaseAdditionalCharge: Enter ReceivableCodeName for [SequenceNumber, LeaseAdditionalChargeId] :['+l.SequenceNumber+','+CONVERT(nvarchar(20),lac.Id)+' ]',l.Id,l.SequenceNumber
FROM stgLeaseAdditionalCharge as lac
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lac.LeaseId  
	 JOIN stgLeaseFinanceDetail lfd on lfd.Id = l.Id
	WHERE lac.Recurring = 1 AND LTRIM(RTRIM(ISNULL(LAC.ReceivableCodeName, ''))) =''
INSERT INTO #Params
SELECT 'LeaseAdditionalCharge: Recurring should be zero for [SequenceNumber, LeaseAdditionalChargeId] :['+l.SequenceNumber+','+CONVERT(nvarchar(20),lac.Id)+' ]',l.Id,l.SequenceNumber
FROM stgLeaseAdditionalCharge as lac
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lac.LeaseId  
	 JOIN stgLeaseFinanceDetail lfd on lfd.Id = l.Id
	WHERE lac.Capitalize = 1 AND LAC.Recurring = 1
INSERT INTO #Params
SELECT 'LeaseAdditionalCharge: Remove FirstDueDate for [SequenceNumber, LeaseAdditionalChargeId] :['+l.SequenceNumber+','+CONVERT(nvarchar(20),lac.Id)+' ]',l.Id,l.SequenceNumber
FROM stgLeaseAdditionalCharge as lac
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lac.LeaseId  
	 JOIN stgLeaseFinanceDetail lfd on lfd.Id = l.Id
	WHERE lac.Capitalize = 1 AND LAC.FirstDueDate IS NOT NULL
INSERT INTO #Params
SELECT 'LeaseAdditionalCharge: Remove RecurringNumber for [SequenceNumber, LeaseAdditionalChargeId] :['+l.SequenceNumber+','+CONVERT(nvarchar(20),lac.Id)+' ]',l.Id,l.SequenceNumber
FROM stgLeaseAdditionalCharge as lac
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lac.LeaseId  
	 JOIN stgLeaseFinanceDetail lfd on lfd.Id = l.Id
	WHERE lac.Capitalize = 1 AND LAC.RecurringNumber IS NOT NULL
INSERT INTO #Params
SELECT 'LeaseAdditionalCharge: Remove Frequency for [SequenceNumber, LeaseAdditionalChargeId] :['+l.SequenceNumber+','+CONVERT(nvarchar(20),lac.Id)+' ]',l.Id,l.SequenceNumber
FROM stgLeaseAdditionalCharge as lac
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lac.LeaseId  
	 JOIN stgLeaseFinanceDetail lfd on lfd.Id = l.Id
	WHERE lac.Capitalize = 1 AND LAC.Frequency <>'_'
INSERT INTO #Params
SELECT 'LeaseAdditionalCharge: Remove DueDay for [SequenceNumber, LeaseAdditionalChargeId] :['+l.SequenceNumber+','+CONVERT(nvarchar(20),lac.Id)+' ]',l.Id,l.SequenceNumber
FROM stgLeaseAdditionalCharge as lac
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lac.LeaseId  
	 JOIN stgLeaseFinanceDetail lfd on lfd.Id = l.Id
	WHERE lac.Capitalize = 1 AND LAC.DueDay IS NOT NULL
INSERT INTO #Params
SELECT 'LeaseAdditionalCharge: Remove ReceivableDueDate for [SequenceNumber, LeaseAdditionalChargeId] :['+l.SequenceNumber+','+CONVERT(nvarchar(20),lac.Id)+' ]',l.Id,l.SequenceNumber
FROM stgLeaseAdditionalCharge as lac
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lac.LeaseId  
	 JOIN stgLeaseFinanceDetail lfd on lfd.Id = l.Id
	WHERE lac.Capitalize = 1 AND LAC.ReceivableDueDate IS NOT NULL
INSERT INTO #Params
SELECT 'LeaseAdditionalCharge: Remove ReceivableCodeName for [SequenceNumber, LeaseAdditionalChargeId] :['+l.SequenceNumber+','+CONVERT(nvarchar(20),lac.Id)+' ]',l.Id,l.SequenceNumber
FROM stgLeaseAdditionalCharge as lac
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lac.LeaseId  
	 JOIN stgLeaseFinanceDetail lfd on lfd.Id = l.Id
	WHERE lac.Capitalize = 1 AND LTRIM(RTRIM(ISNULL(LAC.ReceivableCodeName, ''))) <>''
--=============================stgLeaseBilling=================================  
UPDATE stgLeaseBilling  
  SET stgLeaseBilling.R_PreACHNotificationEmailTemplateId = et.Id  
FROM dbo.EmailTemplates et  with (NOLOCK)
	   WHERE stgLeaseBilling.PreNotificationEmailTemplate = et.Name AND stgLeaseBilling.Id IN (SELECT ID FROM #ProcessableLeaseTemp);  

INSERT INTO #Params  
SELECT 'LeaseBilling: PreNotificationEmailTemplate provided is not valid for [SequenceNumber, PreNotificationEmailTemplate] :['+l.SequenceNumber+','+lb.PreNotificationEmailTemplate+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseBilling AS lb  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lb.Id  
	   WHERE lb.R_PreACHNotificationEmailTemplateId IS NULL AND LTRIM(RTRIM(ISNULL(lb.PreNotificationEmailTemplate, '' ))) <> '';  

UPDATE stgLeaseBilling  
  SET stgLeaseBilling.R_PostACHNotificationEmailTemplateId = et.Id  
FROM dbo.EmailTemplates et  with (NOLOCK)
	   WHERE stgLeaseBilling.PostNotificationEmailTemplate = et.Name AND stgLeaseBilling.Id IN (SELECT ID FROM #ProcessableLeaseTemp);  

INSERT INTO #Params  
SELECT 'LeaseBilling: PostNotificationEmailTemplate provided is not valid for [SequenceNumber, PostNotificationEmailTemplate] :['+l.SequenceNumber+','+lb.PostNotificationEmailTemplate+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseBilling AS lb  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lb.Id  
	   WHERE lb.R_PostACHNotificationEmailTemplateId IS NULL AND LTRIM(RTRIM(ISNULL(lb.PostNotificationEmailTemplate, '' ))) <> '';  

UPDATE stgLeaseBilling  
  SET stgLeaseBilling.R_ReturnACHNotificationEmailTemplateId = et.Id  
FROM dbo.EmailTemplates et with (NOLOCK)
	   WHERE stgLeaseBilling.ReturnNotificationEmailTemplate = et.Name AND stgLeaseBilling.Id IN (SELECT ID FROM #ProcessableLeaseTemp);  

INSERT INTO #Params  
SELECT 'LeaseBilling: ReturnNotificationEmailTemplate provided is not valid for [SequenceNumber, ReturnNotificationEmailTemplate] :['+l.SequenceNumber+','+lb.ReturnNotificationEmailTemplate+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseBilling AS lb  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lb.Id  
	   WHERE lb.R_ReturnACHNotificationEmailTemplateId IS NULL AND LTRIM(RTRIM(ISNULL(lb.ReturnNotificationEmailTemplate, '' ))) <> ''; 

UPDATE stgLeaseBilling  
  SET stgLeaseBilling.R_ReceiptLegalEntityId = le.Id  
FROM dbo.LegalEntities le  with (NOLOCK)
	   WHERE stgLeaseBilling.ReceiptLegalEntityNumber = le.LegalEntityNumber AND stgLeaseBilling.Id IN (SELECT ID FROM #ProcessableLeaseTemp);
UPDATE stgLeaseBilling  SET R_ReceiptLegalEntityId = le.Id
From stgLeaseBilling lb  WITH (NOLOCK) 
Inner Join #ProcessableLeaseTemp l  WITH (NOLOCK) ON l.Id = lb.Id
Inner Join LegalEntities le  WITH (NOLOCK) ON le.LegalEntityNumber =  lb.ReceiptLegalEntityNumber
INSERT INTO #Params  
SELECT 'LeaseBilling: ReceiptLegalEntity provided is not valid for [SequenceNumber, ReceiptLegalEntityNumber] :['+l.SequenceNumber+','+lb.ReceiptLegalEntityNumber+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseBilling AS lb  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lb.Id  
	   WHERE lb.R_ReceiptLegalEntityId IS NULL AND LTRIM(RTRIM(ISNULL(lb.ReceiptLegalEntityNumber, '' ))) <> '';  
--=============================stgLeaseBillingPreference=================================  
UPDATE stgLeaseBillingPreference  
  SET stgLeaseBillingPreference.R_ReceivableTypeId = rt.Id  
FROM dbo.ReceivableTypes rt  with (NOLOCK)
	   WHERE stgLeaseBillingPreference.ReceivableType = rt.Name AND LeaseBillingId IN (SELECT ID FROM #ProcessableLeaseTemp);  
INSERT INTO #Params  
SELECT 'LeaseBillingPreference: ReceivableType provided is not valid for [SequenceNumber, ReceivableType] :['+l.SequenceNumber+','+lbp.ReceivableType+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseBillingPreference AS lbp  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lbp.LeaseBillingId  
	   WHERE lbp.R_ReceivableTypeId IS NULL AND LTRIM(RTRIM(ISNULL(lbp.ReceivableType, '_' ))) <> '_';  
--=============================stgLeaseACHAssignment=================================  

UPDATE stgLeaseACHAssignment  
 SET stgLeaseACHAssignment.R_ReceivableTypeId = rt.Id  , stgLeaseACHAssignment.R_BankAccountId = ba.Id
FROM dbo.ReceivableTypes rt  with (NOLOCK)
Left Join stgLeaseACHAssignment la on la.ReceivableTypeName = rt.Name  
Left JOIN stgLease l  WITH (NOLOCK) ON la.LeaseBillingId = l.Id  
Left JOIN dbo.BankAccounts ba  WITH (NOLOCK) ON la.BankAccountName =ba.AccountName  
Left JOIN BankBranches bb  WITH (NOLOCK) ON ba.BankBranchId = bb.Id AND la.BankBranchName = bb.Name  
Left JOIN PartyBankAccounts pba  WITH (NOLOCK) ON ba.Id = pba.BankAccountId AND ba.IsActive = 1 AND ba.AutomatedPaymentMethod = 'ACHOrPAP'and l.R_CustomerId = pba.PartyId
Join #ProcessableLeaseTemp plt ON la.LeaseBillingId =  plt.Id

INSERT INTO #Params  
SELECT DISTINCT 'LeaseACHAssignment: ReceivableTypeName provided is not valid for [SequenceNumber, ReceivableTypeName] :['+l.SequenceNumber+','+lACH.ReceivableTypeName+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseACHAssignment AS lACH  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lACH.LeaseBillingId  
	   WHERE lACH.R_ReceivableTypeId IS NULL AND LTRIM(RTRIM(ISNULL(lACH.ReceivableTypeName, '' ))) <> '' ;  
   print '9'
INSERT INTO #Params  
SELECT DISTINCT 'LeaseACHAssignment: BankAccountNumber provided is not valid for [SequenceNumber, BankAccountNumber] :['+l.SequenceNumber+','+lACH.BankAccountNumber+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseACHAssignment AS lACH  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lACH.LeaseBillingId  
	   WHERE lACH.R_BankAccountId IS NULL AND LTRIM(RTRIM(ISNULL(lACH.BankAccountNumber, '' ))) <> '' ;  
--=============================stgLeaseLateFee=================================
UPDATE stgLeaseLateFee  
  SET stgLeaseLateFee.R_LateFeeTemplateId = lft.Id  
FROM dbo.LateFeeTemplates lft  WITH (NOLOCK)
	   WHERE stgLeaseLateFee.LateFeeTemplateName = lft.Name AND stgLeaseLateFee.Id IN (SELECT ID FROM #ProcessableLeaseTemp);  
INSERT INTO #Params  
SELECT 'LeaseLateFee: LateFeeTemplateName provided is not valid for [SequenceNumber, LateFeeTemplateName] :['+l.SequenceNumber+','+llf.LateFeeTemplateName+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseLateFee AS llf  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = llf.Id  
	   WHERE llf.R_LateFeeTemplateId IS NULL AND LTRIM(RTRIM(ISNULL(llf.LateFeeTemplateName, '' ))) <> '' ;  
--=============================stgLeaseLateFeeReceivableType=================================  
UPDATE stgLeaseLateFeeReceivableType  
  SET stgLeaseLateFeeReceivableType.R_ReceivableTypeId = rt.Id  
FROM dbo.ReceivableTypes rt  WITH (NOLOCK)
	   WHERE stgLeaseLateFeeReceivableType.ReceivableTypeName = rt.Name AND LeaseLateFeeId IN (SELECT ID FROM #ProcessableLeaseTemp);  
INSERT INTO #Params  
SELECT 'LeaseLateFeeReceivableType: ReceivableTypeName provided is not valid for [SequenceNumber, ReceivableTypeName] :['+l.SequenceNumber+','+llfrt.ReceivableTypeName+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseLateFeeReceivableType AS llfrt  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = llfrt.LeaseLateFeeId  
	   WHERE llfrt.R_ReceivableTypeId IS NULL AND LTRIM(RTRIM(ISNULL(llfrt.ReceivableTypeName, '' ))) <> '' ;  
--=============================stgLeaseRelatedContract=================================  
UPDATE stgLeaseRelatedContract  
  SET stgLeaseRelatedContract.R_ContractId = c.Id  
FROM dbo.Contracts c   WITH (NOLOCK)
	   WHERE stgLeaseRelatedContract.ContractSequenceNumber = c.SequenceNumber AND LeaseId IN (SELECT ID FROM #ProcessableLeaseTemp);  
INSERT INTO #Params  
SELECT 'LeaseRelatedContract: ContractSequenceNumber provided is not valid for [SequenceNumber, ContractSequenceNumber] :['+l.SequenceNumber+','+lrc.ContractSequenceNumber+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseRelatedContract AS lrc  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lrc.LeaseId  
	   WHERE lrc.R_ContractId IS NULL AND LTRIM(RTRIM(ISNULL(lrc.ContractSequenceNumber, '' ))) <> '';  
--=============================stgLeaseSyndicationDetail=================================  
print '9.2'
UPDATE stgLeaseSyndicationDetail  
SET R_LoanPaydownGLTemplateId = g.Id,R_ProgressPaymentReimbursementCodeId = r.Id ,
R_UpfrontSyndicationFeeCodeId = bic.Id ,R_ScrapeReceivableCodeId = rc.Id  ,R_RentalProceedsPayableCodeId= pc.id   
FROM stgLeaseSyndicationDetail AS lsd  WITH (NOLOCK)  
Left Join stgLease AS l  WITH (NOLOCK) ON l.Id = lsd.LeaseId   
Left Join LegalEntities AS le  WITH (NOLOCK) on l.LegalEntityNumber = le.LegalEntityNumber  
Left Join #GlTemplateTemp g  WITH (NOLOCK) ON lsd.LoanPaydownGLTemplateName = g.Name AND g.GLConfigurationId = le.GLConfigurationId AND g.LegalEntityNumber = le.LegalEntityNumber AND g.GLTransactionType = 'Paydown'
Left Join dbo.BlendedItemCodes bic  WITH (NOLOCK) ON lsd.UpfrontSyndicationFeeCode = bic.Name 
Left Join dbo.ReceivableCodes rc  WITH (NOLOCK) ON lsd.ScrapeReceivableCode = rc.Name 
Left Join dbo.ReceivableCodes r WITH (NOLOCK) ON lsd.ProgressPaymentReimbusementReceivableCode = r.Name 
Left Join dbo.PayableCodes pc  WITH (NOLOCK) ON lsd.RentalProceedsPayableCode = pc.Name 
Join #ProcessableLeaseTemp AS ltmp  WITH (NOLOCK) ON l.Id = ltmp.Id 

INSERT INTO #Params  
SELECT 'LeaseSyndicationDetail: LoanPaydownGLTemplateName provided is not valid for [SequenceNumber, LoanPaydownGLTemplateName] :['+l.SequenceNumber+','+lsd.LoanPaydownGLTemplateName+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseSyndicationDetail AS lsd  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lsd.LeaseId  
	   WHERE lsd.R_LoanPaydownGLTemplateId IS NULL AND LTRIM(RTRIM(ISNULL(lsd.LoanPaydownGLTemplateName, '' ))) <> '' ;  
INSERT INTO #Params  
SELECT 'LeaseSyndicationDetail: UpfrontSyndicationFeeCode provided is not valid for [SequenceNumber, UpfrontSyndicationFeeCode] :['+l.SequenceNumber+','+lsd.UpfrontSyndicationFeeCode+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseSyndicationDetail AS lsd  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lsd.LeaseId  
	   WHERE lsd.R_UpfrontSyndicationFeeCodeId IS NULL AND LTRIM(RTRIM(ISNULL(lsd.UpfrontSyndicationFeeCode, '' ))) <> '' ;  
INSERT INTO #Params  
SELECT 'LeaseSyndicationDetail: ScrapeReceivableCode provided is not valid for [SequenceNumber, ScrapeReceivableCode] :['+l.SequenceNumber+','+lsd.ScrapeReceivableCode+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseSyndicationDetail AS lsd  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lsd.LeaseId  
	   WHERE lsd.R_ScrapeReceivableCodeId IS NULL AND LTRIM(RTRIM(ISNULL(lsd.ScrapeReceivableCode, '' ))) <> '' ;  
INSERT INTO #Params  
SELECT 'LeaseSyndicationDetail: ProgressPaymentReimbusementReceivableCode provided is not valid for [SequenceNumber, ProgressPaymentReimbusementReceivableCode] :['+l.SequenceNumber+','+lsd.ProgressPaymentReimbusementReceivableCode+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseSyndicationDetail AS lsd  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lsd.LeaseId  
	   WHERE lsd.R_ProgressPaymentReimbursementCodeId IS NULL AND LTRIM(RTRIM(ISNULL(lsd.ProgressPaymentReimbusementReceivableCode, '' ))) <> '' ;  
INSERT INTO #Params  
SELECT 'LeaseSyndicationDetail: RentalProceedsPayableCode provided is not valid for [SequenceNumber, RentalProceedsPayableCode] :['+l.SequenceNumber+','+lsd.RentalProceedsPayableCode+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseSyndicationDetail AS lsd  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lsd.LeaseId  
	   WHERE lsd.R_RentalProceedsPayableCodeId IS NULL AND LTRIM(RTRIM(ISNULL(lsd.RentalProceedsPayableCode, '' ))) <> '' ; 
--=============================stgLeaseSyndicationFundingSource=================================  
SELECT lsd.ID INTO #ProcessableLeaseSyndicationDetailIds  
FROM #ProcessableLeaseTemp l   
INNER JOIN stgLeaseSyndicationDetail lsd ON l.Id = lsd.LeaseId  
UPDATE stgLeaseSyndicationFundingSource  
SET stgLeaseSyndicationFundingSource.R_FunderId = p.Id ,R_FunderLocationId = l.Id,R_FunderRemitToId = rt.Id,R_FunderBillToId = bt.Id       
FROM dbo.Parties p  WITH (NOLOCK)
Left Join stgLeaseSyndicationFundingSource lsf ON lsf.FunderPartyNumber = p.PartyNumber 
Left Join dbo.Locations l  WITH (NOLOCK) ON lsf.FunderLocation = l.Code
Left Join dbo.RemitToes rt  WITH (NOLOCK) ON lsf.FunderRemitTo = rt.Name
Left Join dbo.BillToes bt  WITH (NOLOCK) ON lsf.FunderBillTo = bt.Name
Join #ProcessableLeaseSyndicationDetailIds pl ON pl.id = lsf.LeaseSyndicationDetailId 
INSERT INTO #Params  
SELECT 'LeaseSyndicationFundingSource: FunderPartyNumber provided is not valid for [SequenceNumber, FunderPartyNumber] :['+l.SequenceNumber+','+ISNULL(lsfs.FunderPartyNumber, 'NULL')+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseSyndicationFundingSource AS lsfs  
	 JOIN stgLeaseSyndicationDetail AS lsd ON lsfs.LeaseSyndicationDetailId = lsd.Id  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lsd.LeaseId
	 JOIN stgLease AS Lease ON l.Id = Lease.Id  
	   WHERE Lease.HoldingStatus <> 'HFI' AND lsfs.R_FunderId IS NULL  
INSERT INTO #Params  
SELECT 'LeaseSyndicationFundingSource: FunderLocation provided is not valid for [SequenceNumber, FunderLocation] :['+l.SequenceNumber+','+ISNULL(lsfs.FunderLocation, 'NULL')+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseSyndicationFundingSource AS lsfs  
	 JOIN stgLeaseSyndicationDetail AS lsd ON lsfs.LeaseSyndicationDetailId = lsd.Id  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lsd.LeaseId
	 JOIN stgLease AS Lease ON l.Id = Lease.Id    
	   WHERE Lease.HoldingStatus <> 'HFI' AND lsfs.R_FunderLocationId IS NULL  
INSERT INTO #Params  
SELECT 'LeaseSyndicationFundingSource: FunderRemitTo provided is not valid for [SequenceNumber, FunderRemitTo] :['+l.SequenceNumber+','+ISNULL(lsfs.FunderRemitTo, 'NULL')+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseSyndicationFundingSource AS lsfs  
	 JOIN stgLeaseSyndicationDetail AS lsd ON lsfs.LeaseSyndicationDetailId = lsd.Id  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lsd.LeaseId 
	 JOIN stgLease AS Lease ON l.Id = Lease.Id   
	   WHERE Lease.HoldingStatus <> 'HFI' AND lsfs.R_FunderRemitToId IS NULL 
INSERT INTO #Params  
SELECT 'LeaseSyndicationFundingSource: FunderBillTo provided is not valid for [SequenceNumber, FunderBillTo] :['+l.SequenceNumber+','+ISNULL(lsfs.FunderBillTo, 'NULL')+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseSyndicationFundingSource AS lsfs  
	 JOIN stgLeaseSyndicationDetail AS lsd ON lsfs.LeaseSyndicationDetailId = lsd.Id  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lsd.LeaseId
	 JOIN stgLease AS Lease ON l.Id = Lease.Id    
	   WHERE Lease.HoldingStatus <> 'HFI' AND lsfs.R_FunderBillToId IS NULL   
INSERT INTO #Params  
SELECT 'LeaseSyndicationFundingSource: At least one Funder is required for [SequenceNumber] :['+l.SequenceNumber' ]', l.Id, l.SequenceNumber  
FROM #ProcessableLeaseTemp AS l
JOIN stgLease AS Lease ON l.Id = Lease.Id 
JOIN stgLeaseSyndicationDetail AS lsd ON l.id = lsd.LeaseId   
LEFT JOIN stgLeaseSyndicationFundingSource AS lsfs ON  lsfs.LeaseSyndicationDetailId = lsd.Id
WHERE Lease.HoldingStatus <> 'HFI' AND lsfs.Id IS NULL
--=============================stgLeaseSyndicationServicingDetail=================================  
UPDATE stgLeaseSyndicationServicingDetail  
  SET stgLeaseSyndicationServicingDetail.R_RemitToId = rt.Id  
FROM dbo.RemitToes rt  with (NOLOCK)
	   WHERE stgLeaseSyndicationServicingDetail.InvoicingRemitToUniqueIdentifier = rt.UniqueIdentifier AND LeaseSyndicationDetailId IN (SELECT Id FROM #ProcessableLeaseSyndicationDetailIds);  
INSERT INTO #Params  
SELECT 'LeaseSyndicationServicingDetail: InvoicingRemitToUniqueIdentifier provided is not valid for [SequenceNumber, InvoicingRemitToUniqueIdentifier] :['+l.SequenceNumber+','+lssd.InvoicingRemitToUniqueIdentifier+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseSyndicationServicingDetail AS lssd  
	 JOIN stgLeaseSyndicationDetail AS lsd ON lssd.LeaseSyndicationDetailId = lsd.Id  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lsd.LeaseId  
	   WHERE lssd.R_RemitToId IS NULL AND LTRIM(RTRIM(ISNULL(lssd.InvoicingRemitToUniqueIdentifier, '' ))) <> '' ; 
INSERT INTO #Params  
SELECT 'LeaseSyndicationFundingSource: At least one Servicing detail is required for [SequenceNumber] :['+l.SequenceNumber' ]', l.Id, l.SequenceNumber  
FROM #ProcessableLeaseTemp AS l 
JOIN stgLease lease ON l.Id = lease.Id
INNER JOIN stgLeaseSyndicationDetail AS lsd ON l.id = lsd.LeaseId
LEFT JOIN stgLeaseSyndicationServicingDetail AS lssd ON lssd.LeaseSyndicationDetailId = lsd.Id        
WHERE lssd.Id IS NULL AND lease.SyndicationType= 'FullSale'     
--=============================stgLeaseThirdPartyRelationship=================================  
print '9.3'

UPDATE stgLeaseThirdPartyRelationship  SET R_ThirdPartyId = p.Id,R_ThirdPartyAddressId = pa.Id, R_ThirdPartyContactId = pc.Id     
FROM dbo.Parties p  with (NOLOCK)
Left Join stgLeaseThirdPartyRelationship ltr  ON ltr.ThirdPartyNumber = p.PartyNumber 
Left Join dbo.PartyAddresses pa  with (NOLOCK) ON ltr.ThirdPartyAddressUniqueIdentifier = pa.UniqueIdentifier 
Left Join dbo.PartyContacts pc  with (NOLOCK) ON ltr.ThirdPartyContactUniqueIdentifier = pc.UniqueIdentifier
Join #ProcessableLeaseTemp plt on plt.id = ltr.LeaseId 

INSERT INTO #Params  
SELECT 'LeaseThirdPartyRelationship: ThirdPartyNumber provided is not valid for [SequenceNumber, ThirdPartyNumber] :['+l.SequenceNumber+','+ltpr.ThirdPartyNumber+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseThirdPartyRelationship AS ltpr  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = ltpr.LeaseId  
	   WHERE ltpr.R_ThirdPartyId IS NULL AND LTRIM(RTRIM(ISNULL(ltpr.ThirdPartyNumber, '' ))) <> '';  
INSERT INTO #Params  
SELECT 'LeaseThirdPartyRelationship: ThirdPartyAddressUniqueIdentifier provided is not valid for [SequenceNumber, ThirdPartyAddressUniqueIdentifier] :['+l.SequenceNumber+','+ltpr.ThirdPartyAddressUniqueIdentifier+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseThirdPartyRelationship AS ltpr  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = ltpr.LeaseId  
	   WHERE ltpr.R_ThirdPartyAddressId IS NULL AND LTRIM(RTRIM(ISNULL(ltpr.ThirdPartyAddressUniqueIdentifier, '' ))) <> '' ;  
INSERT INTO #Params  
SELECT 'LeaseThirdPartyRelationship: ThirdPartyContactUniqueIdentifier provided is not valid for [SequenceNumber, ThirdPartyContactUniqueIdentifier] :['+l.SequenceNumber+','+ltpr.ThirdPartyContactUniqueIdentifier+' ]', l.Id, l.SequenceNumber  
FROM stgLeaseThirdPartyRelationship AS ltpr  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = ltpr.LeaseId  
	   WHERE ltpr.R_ThirdPartyContactId IS NULL AND LTRIM(RTRIM(ISNULL(ltpr.ThirdPartyContactUniqueIdentifier, '' ))) <> '';  
--=============================stgEmployeesAssignedToLease=================================  
print '9.4'
UPDATE stgEmployeesAssignedToLease  
  SET R_EmployeeId = u.Id, R_RoleFunctionId = rf.Id  
FROM stgEmployeesAssignedToLease eatl   WITH (NOLOCK) 
	 INNER JOIN users u  WITH (NOLOCK) ON eatl.LoginName = u.LoginName  
	 INNER JOIN dbo.RoleFunctions rf  WITH (NOLOCK) ON eatl.RoleFunctionName = rf.Name  
	   WHERE rf.IsActive = 1 AND eatl.LeaseId IN (SELECT ID FROM #ProcessableLeaseTemp);  
INSERT INTO #Params  
SELECT 'EmployeesAssignedToLease: LoginName provided is not valid for [SequenceNumber, LoginName] :['+l.SequenceNumber+','+eatl.LoginName+' ]',l.Id,l.SequenceNumber  
FROM stgEmployeesAssignedToLease AS eatl  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = eatl.LeaseId  
	   WHERE eatl.R_EmployeeId IS NULL AND LTRIM(RTRIM(ISNULL(eatl.LoginName, '' ))) <> '';  
INSERT INTO #Params  
SELECT 'EmployeesAssignedToLease: RoleFunctionName provided is not valid for [SequenceNumber, RoleFunctionName] :['+l.SequenceNumber+','+eatl.RoleFunctionName+' ]',l.Id,l.SequenceNumber  
FROM stgEmployeesAssignedToLease AS eatl  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = eatl.LeaseId  
	   WHERE eatl.R_RoleFunctionId IS NULL AND LTRIM(RTRIM(ISNULL(eatl.RoleFunctionName, '' ))) <> '';  

INSERT INTO #Params
SELECT 'Lease can have only one primary employee assignment for a given role function {Role Function Name : ' +eal.RoleFunctionName+' Lease Id : ' +CONVERT(NVARCHAR(MAX), l.Id)+'}'
    , l.Id
	, l.SequenceNumber
FROM stgLease l  
INNER JOIN stgEmployeesAssignedToLease eal ON l.Id = eal.LeaseId
WHERE l.IsMigrated = 0 AND eal.IsPrimary = 1 AND LTRIM(RTRIM(ISNULL(eal.RoleFunctionName, '' ))) <> ''
GROUP BY l.SequenceNumber , l.Id, eal.RoleFunctionName
HAVING COUNT(*) > 1
--=====================stgLeaseBankAccountPaymentThreshold===============
Update stgLeaseBankAccountPaymentThreshold
	SET R_BankAccountId = PBAD.BankAccountId
FROM stgLeaseBankAccountPaymentThreshold LBPT WITH (NOLOCK) 
INNER JOIN #ProcessableLeaseTemp PLT  WITH (NOLOCK) ON PLT.Id = LBPT.LeaseId
Inner JOIN stgLease L WITH (NOLOCK)  On L.Id = PLT.Id
INNER JOIN #PartyBankAccountDetails PBAD WITH (NOLOCK)  ON PBAD.BanAccountUniqueIdentifier = LBPT.BankAccountUniqueIdentifier
 AND PBAD.PartyId = l.R_CustomerId
INSERT INTO #Params  
SELECT 'LeaseBankAccountPaymentThreshold: BankAccountUniqueIdentifier provided is not valid for [SequenceNumber, BankAccountUniqueIdentifier] :['+l.SequenceNumber+','+CAST(lbpt.BankAccountUniqueIdentifier AS NVARCHAR(100))+' ]',l.Id,l.SequenceNumber  
FROM stgLeaseBankAccountPaymentThreshold AS lbpt  
	 JOIN #ProcessableLeaseTemp AS l ON l.id = lbpt.LeaseId  
	   WHERE lbpt.R_BankAccountId IS NULL AND LTRIM(RTRIM(ISNULL(lbpt.BankAccountUniqueIdentifier, '' ))) <> '';  
Update stgLease
	SET R_TaxExemptionReasonConfigId = TaxExemptionReasonConfigs.Id
FROM stgLease with (NOLOCK)
INNER JOIN #ProcessableLeaseTemp l  WITH (NOLOCK) ON stgLease.Id = l.Id
INNER Join TaxExemptionReasonConfigs  WITH (NOLOCK) On stgLease.TaxExemptionReasonConfigName = TaxExemptionReasonConfigs.Reason
WHERE TaxExemptionReasonConfigs.EntityType='Lease' And TaxExemptionReasonConfigs.IsActive=1 AND (stgLease.IsCountryTaxExempt = 1 OR LTRIM(RTRIM(ISNULL(stgLease.TaxExemptionReasonConfigName, '' ))) <> '')
Update stgLease
	SET R_StateTaxExemptionReasonConfigId = TaxExemptionReasonConfigs.Id
FROM stgLease with (NOLOCK)
INNER JOIN #ProcessableLeaseTemp AS l WITH (NOLOCK)  ON stgLease.Id = l.Id
INNER JOIN TaxExemptionReasonConfigs  WITH (NOLOCK)  On stgLease.StateTaxExemptionReasonConfigName = TaxExemptionReasonConfigs.Reason
WHERE TaxExemptionReasonConfigs.EntityType='Lease' And TaxExemptionReasonConfigs.IsActive=1  AND (stgLease.IsStateTaxExempt = 1 OR LTRIM(RTRIM(ISNULL(stgLease.StateTaxExemptionReasonConfigName, '' ))) <> '')   
INSERT INTO #Params  
SELECT 'Lease: TaxExemptionReason provided is not valid for [SequenceNumber, TaxExemptionReason] :['+l.SequenceNumber+','+ ISNULL(lease.TaxExemptionReasonConfigName,'')+' ]', l.Id, l.SequenceNumber  
FROM stgLease AS lease  
JOIN #ProcessableLeaseTemp AS l ON l.id = lease.Id
WHERE lease.R_TaxExemptionReasonConfigId IS NULL AND (lease.IsCountryTaxExempt = 1 OR LTRIM(RTRIM(ISNULL(lease.TaxExemptionReasonConfigName, '' ))) <> '')
INSERT INTO #Params  
SELECT 'Lease: TaxExemptionReason provided is not valid for [SequenceNumber, TaxExemptionReason] :['+l.SequenceNumber+','+ISNULL(lease.StateTaxExemptionReasonConfigName,'')+' ]', l.Id, l.SequenceNumber  
FROM stgLease AS lease  
JOIN #ProcessableLeaseTemp AS l ON l.id = lease.Id
WHERE lease.R_StateTaxExemptionReasonConfigId IS NULL AND (lease.IsStateTaxExempt = 1 OR LTRIM(RTRIM(ISNULL(lease.StateTaxExemptionReasonConfigName, '' ))) <> '') 
--===================Validation==============================================================
--Contracts  
BEGIN TRANSACTION
MERGE Contracts AS Contract  
USING  
(  
 SELECT Lease.*, p.EntityId   
 FROM #ProcessableLeaseTemp lt WITH (NOLOCK)  
 INNER JOIN stgLease as Lease   WITH (NOLOCK) ON lt.Id = Lease.Id  
	  LEFT JOIN #Params AS p ON Lease.Id = p.EntityId   
		WHERE Lease.IsFailed = 0 AND Lease.IsMigrated = 0 AND (Lease.ToolIdentifier IS NULL OR Lease.ToolIdentifier = @ToolIdentifier) and  p.EntityId  is null ) AS ContractToMigrate  
ON 1=0  
WHEN NOT MATCHED AND ContractToMigrate.EntityId IS NULL  
	  THEN  
	  INSERT(SequenceNumber, Alias, ReferenceType, ContractType, DiscountForLoanStatus, SyndicationType, IsSyndictaionGeneratePayable, IsLienFilingRequired, IsLienFilingException, LienExceptionComment, LienExceptionReason, IsConfidential, ReceivableAmendmentType, InvoiceComment, ChargeOffStatus, OriginalBookingDate, FinalAcceptanceDate, SalesTaxRemittanceMethod,  LastPaymentAmount_Amount, LastPaymentAmount_Currency, LastPaymentDate, TaxPaidtoVendor_Amount, TaxPaidtoVendor_Currency, GSTTaxPaidtoVendor_Amount, GSTTaxPaidtoVendor_Currency, HSTTaxPaidtoVendor_Amount, HSTTaxPaidtoVendor_Currency, QSTorPSTTaxPaidtoVendor_Amount, QSTorPSTTaxPaidtoVendor_Currency,IsNonAccrual, NonAccrualDate, Status, IsOnHold, IsAssignToRecovery, ReportStatus, CreatedById, CreatedTime, CurrencyId, BillToId, RemitToId, DealProductTypeId, LineofBusinessId, ReceiptHierarchyTemplateId, IsPostScratchIndicator, PreviousScheduleNumber, ExternalReferenceNumber, IsReportableDelinquency, InterimLoanAndSecurityAgreementDate, u_ConversionSource, DecisionComments, DealTypeId, CostCenterId, ProductAndServiceTypeConfigId, ProgramIndicatorConfigId, DocumentMethod, FirstRightOfRefusal, LanguageId, IsNonAccrualExempt, TaxAssessmentLevel, ServicingRole, AccountingStandard, DiscountingSharedPercentage, FollowOldDueDayMethod, CountryId, DoubtfulCollectability , VehicleLeaseType,BackgroundProcessingPending)  
	  VALUES(ContractToMigrate.SequenceNumber, ContractToMigrate.Alias, '_', 'Lease', '_', ContractToMigrate.SyndicationType, CAST (0 AS BIT), ContractToMigrate.IsLienFilingRequired, ContractToMigrate.IsLienFilingException, ContractToMigrate.LienExceptionComment, ContractToMigrate.LienExceptionReason, ContractToMigrate.IsConfidential, 'Credit', ContractToMigrate.InvoiceComment, '_', ContractToMigrate.OriginalBookingDate, ContractToMigrate.FinalAcceptanceDate, ContractToMigrate.SalesTaxRemittanceMethod, 0.00, ContractToMigrate.TaxPaidtoVendor_Currency, NULL, ContractToMigrate.TaxPaidtoVendor_Amount, ContractToMigrate.TaxPaidtoVendor_Currency, ContractToMigrate.GSTTaxPaidtoVendor_Amount, ContractToMigrate.GSTTaxPaidtoVendor_Currency, ContractToMigrate.HSTTaxPaidtoVendor_Amount, ContractToMigrate.HSTTaxPaidtoVendor_Currency, ContractToMigrate.QSTorPSTTaxPaidtoVendor_Amount, ContractToMigrate.QSTorPSTTaxPaidtoVendor_Currency,CAST(0 AS BIT), NULL, 'Commenced', CAST(0 AS BIT), ContractToMigrate.IsAssignToRecovery, 'Active', @UserId, @CreatedTime, ContractToMigrate.R_CurrencyId, ContractToMigrate.R_BillToId, ContractToMigrate.R_RemitToId, ContractToMigrate.R_DealProductTypeId, ContractToMigrate.R_LineofBusinessId, ContractToMigrate.R_ReceiptHierarchyTemplateId, ContractToMigrate.IsPostScratchIndicator, ContractToMigrate.PreviousScheduleNumber, ContractToMigrate.ExternalReferenceNumber, CAST (0 AS BIT) , ContractToMigrate.InterimLoanAndSecurityAgreementDate, @u_ConversionSource, NULL, ContractToMigrate.R_DealTypeId, ContractToMigrate.R_CostCenterId, ContractToMigrate.R_ProductAndServiceTypeConfigId, ContractToMigrate.R_ProgramIndicatorConfigId, '_', ContractToMigrate.FirstRightOfRefusal, ContractToMigrate.R_LanguageId, IsNonAccrualExempt, ContractToMigrate.TaxAssessmentLevel, '_', AccountingStandard, DiscountingSharedPercentage, FollowOldDueDayMethod,ContractToMigrate.R_CountryId, 0 , ContractToMigrate.VehicleLeaseType, 0)        
OUTPUT Inserted.Id, ContractToMigrate.Id  
	   INTO #CreatedContractIds;  
print 'TaxExemptRules'
--TaxExemptRules  
MERGE INTO TaxExemptRules
USING
(
 SELECT #CreatedContractIds.*, Lease.IsCityTaxExempt, Lease.IsCountyTaxExempt, Lease.IsCountryTaxExempt, IsStateTaxExempt, R_TaxExemptionReasonConfigId As TaxExemptionReasonConfigId, R_StateTaxExemptionReasonConfigId As StateTaxExemptionReasonConfigId, StateExemptionNumber, CountryExemptionNumber
 FROM #CreatedContractIds WITH (NOLOCK)
 INNER Join stgLease as Lease ON Lease.Id = #CreatedContractIds.Id) AS TR
ON 1 = 0
WHEN NOT MATCHED
	  THEN
	  INSERT
			([EntityType]
			,[IsCountryTaxExempt]
			,[IsStateTaxExempt]
			,[IsCityTaxExempt]
			,[IsCountyTaxExempt]
			,[CreatedById]
			,[CreatedTime]
			,[TaxExemptionReasonId]
			,[StateTaxExemptionReasonId]
			,[StateExemptionNumber]
			,[CountryExemptionNumber])
		VALUES(
			'Lease'
			,IsCountryTaxExempt
			,IsStateTaxExempt
			,IsCityTaxExempt
			,IsCountyTaxExempt
			,@UserId
			,@CreatedTime
			,TaxExemptionReasonConfigId
			,StateTaxExemptionReasonConfigId
			,StateExemptionNumber
			,CountryExemptionNumber)
OUTPUT inserted.Id, TR.InsertedContractId
	   INTO #InsertedTaxExemptRuleIds;
--ContractOriginations  
MERGE INTO dbo.ContractOriginations  
USING  
(  
 SELECT Lease.*, c.InsertedContractId  
 FROM #CreatedContractIds c WITH (NOLOCK)  
 INNER JOIN stgLease as Lease ON Lease.Id = c.Id) AS CO  
ON 1 = 0  
WHEN NOT MATCHED  
	  THEN  
	  INSERT(OriginationFee_Amount, OriginationFee_Currency, OriginationScrapeFactor, IsOriginationGeneratePayable, ManagementSegment, CreatedById, CreatedTime, OriginationSourceTypeId, OriginationSourceId, OriginationSourceUserId, AcquiredPortfolioId, OriginationFeeBlendedItemCodeId, OriginatorPayableRemitToId, ScrapePayableCodeId,ScrapeWithholdingTaxRate, OriginatingLineofBusinessId, ProgramVendorOriginationSourceId, DocFeeAmount_Amount, DocFeeAmount_Currency, DocFeeReceivableCodeId,CommissionType,CommissionValueExcludingVAT_Amount,CommissionValueExcludingVAT_Currency,OriginationChannelId)  
	  VALUES(CO.OriginationFee_Amount, CO.OriginationFee_Currency, CO.OriginationScrapeFactor, CAST(0 AS BIT) , CO.ManagementSegment, @UserId, @CreatedTime, CO.R_OriginationSourceTypeId, CO.R_OriginationSourceId, CO.R_OriginationSourceUserId, CO.R_AcquiredPortfolioId, CO.R_OriginationFeeBlendedItemCodeId, CO.R_OriginatorPayableRemitToId, CO.R_ScrapePayableCodeId, CO.ScrapeWithholdingTaxRate, CO.R_OriginatingLineofBusinessId, CO.R_ProgramVendorOriginationSourceId, CO.DocFeeAmount_Amount, CO.DocFeeAmount_Currency, CO.R_DocFeeReceivableCodeId,CommissionType,CommissionValueExcludingVAT_Amount,CommissionValueExcludingVAT_Currency,R_OriginationChannelId)  
OUTPUT inserted.Id, CO.InsertedContractId  
	   INTO #InsertedContractOriginationIds;  
  print 'ServicingDetails'
--ServicingDetails  
 MERGE INTO dbo.ServicingDetails  
USING  
(  
 SELECT Lease.*, lfd.CommencementDate,lfd.IsNonNotification, c.InsertedContractId, #InsertedContractOriginationIds.Id AS ContractOriginationId  
 FROM #CreatedContractIds AS c WITH (NOLOCK)  
 Inner Join stgLease as Lease ON Lease.Id = c.Id
 Inner Join stgLeaseFinanceDetail AS lfd ON Lease.Id = lfd.Id   
 Inner Join #InsertedContractOriginationIds ON c.InsertedContractId = #InsertedContractOriginationIds.ContractId And Lease.OriginationSourceTypeName In ('Indirect', 'Vendor')) AS SD  
ON 1 = 0  
WHEN NOT MATCHED  
	  THEN  
	  INSERT(EffectiveDate, IsServiced, IsCollected, IsPerfectPay, IsActive, IsPrivateLabel, IsCobrand, CreatedById, CreatedTime, IsNonNotification)  
	  VALUES(SD.CommencementDate, SD.IsOriginationServiced, SD.IsOriginationCollected, CAST(0 AS BIT), CAST(1 AS BIT), SD.IsOriginationPrivateLabel, SD.IsOriginationCobrand, @UserId, @CreatedTime, SD.IsNonNotification)  
OUTPUT inserted.Id, SD.InsertedContractId, SD.ContractOriginationId  
	   INTO #InsertedContractOriginationServicingDetailIds;  
--ContractOriginationServicingDetails  
INSERT INTO dbo.ContractOriginationServicingDetails(IsFromAcquiredPortfolio, CreatedById, CreatedTime, ServicingDetailId, ContractOriginationId)  
SELECT CAST(0 AS BIT), @UserId, @CreatedTime, #InsertedContractOriginationServicingDetailIds.Id, ContractOriginationId  
FROM #InsertedContractOriginationServicingDetailIds
Inner Join ContractOriginations On ContractOriginations.Id =   #InsertedContractOriginationServicingDetailIds.ContractOriginationId
Inner Join OriginationSourceTypes On OriginationSourceTypes.Id  = ContractOriginations.OriginationSourceTypeId
	And OriginationSourceTypes.Name In ('Indirect', 'Vendor');

--ContractPledge

Insert into ContractPledges(IsExpired,CreatedById,CreatedTime,IsActive,Bank,BIC,BankAccountBGN,BankAccountEUR,PledgeReceivables,PledgeVehicles,PledgeInFavorOf,CascoCoverage,Comment,InterestBaseId,LoanNumberId,ContractId)
SELECT pledge.IsExpired,@UserId,@CreatedTime,pledge.IsActive,pledge.Bank,pledge.BIC,pledge.BankAccountBGN,pledge.BankAccountEUR,pledge.PledgeReceivables,pledge.PledgeVehicles,pledge.PledgeInFavorOf,pledge.CascoCoverage,pledge.Comment,pledge.R_InterestBaseId,pledge.R_LoanNumberId,c.Id
 FROM #CreatedContractIds c WITH (NOLOCK)  
 INNER JOIN stgLease as Lease ON Lease.Id = c.Id
 INNER JOIN stgContractPledge as pledge ON pledge.LeaseId = Lease.Id


--LeaseFinance  
	print 'LeaseFinance'
MERGE LeaseFinances AS LeaseFinance  
USING  
(  
 SELECT Lease.*, c.InsertedContractId AS ContractId, tr.Id AS TaxExemptRuleId, co.Id AS ContractOriginationId  
 FROM #CreatedContractIds AS c WITH (NOLOCK)  
 INNER JOIN stgLease as Lease ON Lease.Id = c.Id
	  INNER JOIN #InsertedTaxExemptRuleIds AS tr ON c.InsertedContractId = tr.ContractId  
	  INNER JOIN #InsertedContractOriginationIds AS co ON c.InsertedContractId = co.ContractId) AS LeaseFinanceToMigrate  
ON 1 = 0
WHEN NOT MATCHED  
	  THEN  
  INSERT(BookingStatus, ApprovalStatus, IsCurrent, IsSalesTaxExempt, PropertyTaxResponsibility, IsPaymentScheduleGenerated, PaymentScheduleParametersChanged, IsPricedPerformed, PricingParametersChanged, ManagementYieldParametersChanged, SendToGAIC, GAICStatus, GAICRejectionReason, HoldingStatus, HoldingStatusComment, PurchaseOrderNumber, AcquisitionId, InterimRentAdjustmentEffectiveDate, InterimRentUpdateHasBeenRun, InterimInterestAdjustmentEffectiveDate, InterimInterestUpdateHasBeenRun, LeaseStipLossDetailDocument_Source, LeaseStipLossDetailDocument_Type, LeaseStipLossDetailDocument_Content, ClassificationTestParametersChanged, IsAMReviewCompleted, IsAMReviewRequired, IsFundingApproved, IsAccountingApproved, FloatRateUpdateRunDate, BankQualified, IsHostedSolution, IsRetrievedFromSalesTaxParametersChanged, IsRePricingParametersChanged, IsRetrievedFromSalesTax, CustomerClass, IsRepricedForSalesTax, IsFutureFunding, IsSalesTaxReviewRequired, IsSalesTaxReviewCompleted, IsSalesLeaseBackReviewCompleted, IsSalesTaxExemption, IsConduit, IsRecoveryContract, CreatedById, CreatedTime, LegalEntityId, CustomerId, ContractId, ContractOriginationId, TaxProductTypeId, ThirdPartyResidualGuarantorId, ThirdPartyResidualGuarantorBillToId, InstrumentTypeId, ReferralBankerId, LineofBusinessId, IsTaxReserve, Is467Lease, TimbreNumber, MasterAgreementId, AgreementTypeDetailId, IsNewMasterAgreement, SFDCUniqueId, CostCenterId, TaxExemptRuleId, IsFederalIncomeTaxExempt, IsNotQuotable, BranchId, IsBillInAlternateCurrency,VendorPayableCodeId,VendorWithholdingTaxRate,IsOTPDepreciationParameterChanged,PreparedBy,IsSubleasing,IsFinancialRiskInsurance,IsVat,QuoteLeaseTypeId,IsLetterOfConsentForPledge)  
	   VALUES('Pending','Approved', CAST (1 AS BIT), LeaseFinanceToMigrate.IsSalesTaxExempt, LeaseFinanceToMigrate.PropertyTaxResponsibility, CAST (0 AS BIT), CAST (0 AS BIT), CAST (0 AS BIT), CAST (0 AS BIT), CAST (0 AS BIT), LeaseFinanceToMigrate.SendToGAIC, CASE WHEN LeaseFinanceToMigrate.SendToGAIC = 1 THEN 'Queued' ELSE '_' END, NULL, LeaseFinanceToMigrate.HoldingStatus, NULL, LeaseFinanceToMigrate.PurchaseOrderNumber, ISNULL(LeaseFinanceToMigrate.R_AcquisitionId,'000'), NULL, CAST (0 AS BIT), NULL, CAST (0 AS BIT), '', '', NULL, CAST (0 AS BIT), CAST (0 AS BIT), CAST (0 AS BIT), CAST (0 AS BIT), CAST (0 AS BIT), NULL, LeaseFinanceToMigrate.BankQualified, LeaseFinanceToMigrate.IsHostedSolution, CAST (0 AS BIT), CAST (0 AS BIT), CAST (0 AS BIT),  LeaseFinanceToMigrate.R_CustomerClass, CAST (0 AS BIT), LeaseFinanceToMigrate.IsFutureFunding, CAST (0 AS BIT), CAST (0 AS BIT), CAST (0 AS BIT), LeaseFinanceToMigrate.IsSalesTaxExemption, CAST(0 AS BIT), LeaseFinanceToMigrate.IsRecoveryContract, @UserId, @CreatedTime, LeaseFinanceToMigrate.R_LegalEntityId, LeaseFinanceToMigrate.R_CustomerId, LeaseFinanceToMigrate.ContractId, LeaseFinanceToMigrate.ContractOriginationId, LeaseFinanceToMigrate.R_TaxProductTypeId, NULL, NULL, LeaseFinanceToMigrate.R_InstrumentTypeId, LeaseFinanceToMigrate.R_ReferralBankerId, LeaseFinanceToMigrate.R_LineofBusinessId, LeaseFinanceToMigrate.IsTaxReserve, LeaseFinanceToMigrate.Is467Lease, LeaseFinanceToMigrate.TimbreNumber, LeaseFinanceToMigrate.R_MasterAgreementId, LeaseFinanceToMigrate.R_AgreementTypeDetailId, CAST(0 AS BIT), NULL, LeaseFinanceToMigrate.R_CostCenterId, LeaseFinanceToMigrate.TaxExemptRuleId, LeaseFinanceToMigrate.FederalIncomeTaxExempt, LeaseFinanceToMigrate.IsNotQuotable, LeaseFinanceToMigrate.R_BranchId, LeaseFinanceToMigrate.IsBillInAlternateCurrency,R_VendorPayableCodeId,LeaseFinanceToMigrate.VendorWithholdingTaxRate,0,LeaseFinanceToMigrate.PreparedBy,LeaseFinanceToMigrate.IsSubleasing,LeaseFinanceToMigrate.IsFinancialRiskInsurance,LeaseFinanceToMigrate.IsVat,LeaseFinanceToMigrate.R_QuoteLeaseTypeId,IsLetterOfConsentForPledge)  
OUTPUT Inserted.Id, LeaseFinanceToMigrate.ContractId, LeaseFinanceToMigrate.Id  
	   INTO #CreatedLeaseFinanceIds;  

  print 'LeaseCustomAmorts'
INSERT INTO dbo.LeaseCustomAmorts  
(  
	Id,  
	UploadCustomAmort,  
	CustomAmortDocument_Source,  
	CustomAmortDocument_Type,  
	CustomAmortDocument_Content,  
	CreatedById,  
	CreatedTime  
)  
SELECT   
#CreatedLeaseFinanceIds.InsertedId,  
0,  
'',  
'',  
NULL,  
@UserId,  
@CreatedTime  
FROM #CreatedLeaseFinanceIds  
	print 'LeaseFinanceDetails'
--LeaseFinanceDetails  
  
INSERT INTO dbo.LeaseFinanceDetails(Id,InterimPaymentFrequency,InterimPaymentFrequencyDays,InterimAssessmentMethod,InterimInterestBillingType,InterimInterestFrequencyStartDate,InterimInterestDayCountConvention,CreateSoftAssetsForInterimInterest,InterimRentBillingType,IsInterimRentInAdvance,InterimRentFrequencyStartDate,InterimRentDayCountConvention,CreateSoftAssetsForInterimRent,DueDay,RentAccrualDate,CommencementDate,FrequencyStartDate,NumberOfPayments,IsAdvance,NumberOfInceptionPayments,InceptionPayment_Amount,InceptionPayment_Currency,DownPayment_Amount,DownPayment_Currency,DownPaymentDueDate,DayCountConvention,IsRegularPaymentStream,PaymentFrequency,CompoundingFrequency,PaymentFrequencyDays,MaturityDate,TermInMonths,Markup_Amount,Markup_Currency,InterimRent_Amount,InterimRent_Currency,Rent_Amount,Rent_Currency,CustomerExpectedResidual_Amount,CustomerExpectedResidual_Currency,BookedResidual_Amount,BookedResidual_Currency,CustomerGuaranteedResidual_Amount,CustomerGuaranteedResidual_Currency,ThirdPartyGuaranteedResidual_Amount,ThirdPartyGuaranteedResidual_Currency,ResidualValueInsurance_Amount,ResidualValueInsurance_Currency,IsPricingYieldExtreme,ManagementYield,IsManagementYieldExtreme,IsTotalYieldExtreme,PurchaseRVIForCapitalLeaseTreatment,LastExtensionARUpdateRunDate,LastSupplementalARUpdateRunDate,PurchaseOption,LessorYield,IsLessorYieldExtreme,ClassificationYield,IsClassificationYieldExtreme,PostDate,ClassificationContractType,LeaseContractType,CostOfFunds,TotalEconomicLifeInMonths,RemainingEconomicLifeInMonths,IsBargainPurchaseOption,IsTransferOfOwnership,PreRVINinetyPercentTestResult,PreRVINinetyPercentTestPresentValue_Amount,PreRVINinetyPercentTestPresentValue_Currency,NinetyPercentTestResult,NinetyPercentTestPresentValue_Amount,NinetyPercentTestPresentValue_Currency,TotalEconomicLifeTestResult,SalesTypeLeaseGrossProfit_Amount,SalesTypeLeaseGrossProfit_Currency,IsClassificationTestDone,IsCalculationDoneAsOfSalesType,RateCardRate,RateExpirationDate,ApprovalDateSwapRate,VendorExceptionApprovalNumber,VendorRateBuyDownAmount_Amount,VendorRateBuyDownAmount_Currency,BankYieldSpread,TotalYield,InternalYield,IsInternalYieldExtreme,IsYieldComputed,IsManagementYieldComputed,IsTaxLease,NetInvestment_Amount,NetInvestment_Currency,IsFloatRateLease,CreateSoftAssetsForCappedSalesTax,CapitalizeUpfrontSalesTax,IsOverTermLease,BillOTPForSoftAssets,NumberOfOverTermPayments,OTPPaymentFrequency,OTPPaymentFrequencyUnit,OTPRent_Amount,OTPRent_Currency,SupplementalRent_Amount,SupplementalRent_Currency,IsSupplementalAdvance,SupplementalFrequency,SupplementalFrequencyUnit,SupplementalGracePeriod,DeliverViaMail,DeliverViaEmail,SendEmailNotificationTo,SendCCEmailNotificationTo,IsLessorNotice,IsLesseeNotice,MaturityDateBasis,NoticeBasis,MaxNoticePeriod,MinNoticePeriod,RemarketingResponsibility,OfferLetterAdditionalDays,FollowUpLeadDays,CustomerNotificationLeadDays,InvestorNotificationLeadDays,LessorNoticePeriod,DeferredTaxBalance_Amount,DeferredTaxBalance_Currency,IsOTPRegularPaymentStream,OTPRentPreference,TerminationNoticeReceived,TerminationNoticeReceivedOn,TerminationNoticeEffectiveDate,IsOTPScheduled,FloridaStampTax_Amount,FloridaStampTax_Currency,TennesseeIndebtednessTax_Amount,TennesseeIndebtednessTax_Currency,TNIndebtednessDiligenzFee_Amount,TNIndebtednessDiligenzFee_Currency,CapitalizedSalesTaxPayment_Amount,CapitalizedSalesTaxPayment_Currency,TotalStreamTaxAmount_Amount,TotalStreamTaxAmount_Currency,TotalUpfrontTaxAmount_Amount,TotalUpfrontTaxAmount_Currency,CustomerFacingYield,InvestmentModifiedAfterPayment,CreatedById,CreatedTime,ClassificationOverriddenById,InterimInterestReceivableCodeId,InterimRentReceivableCodeId,FixedTermReceivableCodeId,FloatRateARReceivableCodeId,OTPReceivableCodeId,SupplementalReceivableCodeId,InterimInterestIncomeGLTemplateId,InterimRentIncomeGLTemplateId,LeaseBookingGLTemplateId,LeaseIncomeGLTemplateId,PropertyTaxReceivableCodeId,FloatIncomeGLTemplateId,OTPIncomeGLTemplateId,GLJournalId,DeferredTaxGLTemplateId,RegularPaymentAmount_Amount,RegularPaymentAmount_Currency,CustomerTermInMonths,CreateInvoiceForAdvanceRental,BillInterimAsOf,TaxDepExpenseGLTemplateId,TaxAssetSetupGLTemplateId,TaxDepDisposalTemplateId,InvestmentModifiedAfterPaymentForSpecificCostAdj,EligibleForResidualValueInsurance,FMV_Amount,FMV_Currency,MaturityPayment_Amount,MaturityPayment_Currency,IsSpecializedUseAssets,LessorYieldLeaseAsset,LessorYieldFinanceAsset,NinetyPercent5ATestResult,NinetyPercent5BTestResult,NinetyPercentTestPresentValue5A_Amount,NinetyPercentTestPresentValue5A_Currency,NinetyPercentTestPresentValue5B_Amount,NinetyPercentTestPresentValue5B_Currency,DeferredSellingProfit_Amount,DeferredSellingProfit_Currency,ClassificationYield5A,ClassificationYield5B,NinetyPercent5ATestResultPassed,NinetyPercent5BTestResultPassed,IsClassificationYield5AExtreme,IsClassificationYield5BExtreme,IsLessorYieldLeaseAssetExtreme,IsLessorYieldFinanceAssetExtreme,YieldCalculationParametersChanged,ProfitLossStatus,NinetyPercentTestResultPassed,IsStepPayment,StepPercentage,StepPeriod,StubAdjustment,RecalculateInterestonReprice, RestructureOnFloatRateChange, PercentageToVendor, OTPRentPayableCodeId, OTPRentPayableWithholdingTaxRate, EffectiveAnnualRate,IsDownpaymentIncludesTax,VATDownPayment_Amount,VATDownPayment_Currency,TotalDownPayment_Amount,TotalDownPayment_Currency,FinancedAmountExclVAT_Amount,FinancedAmountExclVAT_Currency,AdvancetoDealer_Amount,AdvancetoDealer_Currency,IsBuybackGuaranteebyVendor,DownPaymentPercentageId,NetTermBasis,NetTerms,IsOTPParametersChanged,OverrideReason,IsPromissoryNote,PromissoryNote_Amount,PromissoryNote_Currency,IsApplicable,DateOfIncorporation,ExpirationDate,IsReleased,CashGuaranteesAmount_Amount,CashGuaranteesAmount_Currency)  
SELECT LF.InsertedId,'_',0,'_','_',NULL,'_',0,'_',0,NULL,'_',0,DueDay,NULL,CommencementDate,FrequencyStartDate,NumberOfPayments,IsAdvance,NumberOfCommencementPayments,RentAtCommencement_Amount,RentAtCommencement_Currency,DownPaymentAmount_Amount,DownPaymentAmount_Currency,CommencementDate,DayCountConvention,IsRegularPaymentStream,PaymentStreamFrequency,CompoundingFrequency,0,NULL,0,0.00,DownPaymentAmount_Currency,0.00,DownPaymentAmount_Currency,0.00,DownPaymentAmount_Currency,0.00,DownPaymentAmount_Currency,0.00,DownPaymentAmount_Currency,0.00,DownPaymentAmount_Currency,0.00,DownPaymentAmount_Currency,0.00,DownPaymentAmount_Currency,CAST (0 AS BIT) AS IsPricingYieldExtreme,0.00,CAST (0 AS BIT),CAST (0 AS BIT),PurchaseRVIForCapitalLeaseTreatment,NULL,NULL,ISNULL(DealProductTypeName, '_'),0.00,CAST (0 AS BIT),0.00,CAST (0 AS BIT),PostDate,lfd.ContractType,lfd.ContractType,CostOfFunds,0,RemainingEconomicLifeInMonths,IsBargainPurchaseOption,IsTransferOfOwnership,0.00,0.00,DownPaymentAmount_Currency,0.00,0.00,DownPaymentAmount_Currency,0.00,0.00,DownPaymentAmount_Currency,CAST (0 AS BIT),CAST (0 AS BIT),RateCardRate,RateExpirationDate,ApprovalDateSwapRate,VendorExceptionApprovalNumber,VendorRateBuyDownAmount_Amount,VendorRateBuyDownAmount_Currency,0.00,0.00,0.00,CAST (0 AS BIT),0.00,CAST (0 AS BIT),IsTaxLease,0.00,DownPaymentAmount_Currency,IsFloatRateLease,CreateSoftAssetsForCappedSalesTax,CAST (0 AS BIT),IsOTPLease,IsBillOTPForSoftAssets,NumberOfOTPPayments,OTPPaymentFrequency,OTPPaymentFrequencyUnit,OTPRentalAmount_Amount,OTPRentalAmount_Currency,SupplementalRent_Amount,SupplementalRent_Currency,IsSupplementalAdvance,SupplementalFrequency,SupplementalFrequencyUnit,SupplementalGracePeriod,DeliverViaMail,DeliverViaEmail,SendEmailNotificationTo,SendCCEmailNotificationTo,IsLessorNotice,IsLesseeNotice,MaturityDateBasis,NoticeBasis,MaxNoticePeriod,MinNoticePeriod,RemarketingResponsibility,OfferLetterAdditionalDays,FollowUpLeadDays,CustomerNotificationLeadDays,InvestorNotificationLeadDays,LessorNoticePeriod,0.00,DownPaymentAmount_Currency,IsOTPRegularPaymentStream,OTPRentPreference,TerminationNoticeReceived,TerminationNoticeReceivedOn,TerminationNoticeDate,IsOTPScheduled,0.00,DownPaymentAmount_Currency,0.00,DownPaymentAmount_Currency,0.00,DownPaymentAmount_Currency,0.00,DownPaymentAmount_Currency,0.00,DownPaymentAmount_Currency,0.00,DownPaymentAmount_Currency,PricingInterestRate AS CustomerFacingYield,CAST (0 AS BIT),@UserId,@CreatedTime,NULL AS ClassificationOverriddenById,NULL,NULL,R_FixedTermReceivableCodeId,R_FloatRateARReceivableCodeId,R_OTPReceivableCodeId,R_SupplementalReceivableCodeId,NULL,NULL,R_LeaseBookingGLTemplateId,R_LeaseIncomeGLTemplateId,R_PropertyTaxReceivableCodeId,R_FloatIncomeGLTemplateId,R_OTPIncomeGLTemplateId,NULL AS GLJournalId,R_DeferredTaxGLTemplateId,RegularPaymentAmount_Amount,RegularPaymentAmount_Currency,CustomerTermInMonths,CreateInvoiceForAdvanceRental,'_',R_TaxDepExpenseGLTemplateId,R_TaxAssetSetupGLTemplateId,R_TaxDepDisposalTemplateId,0 AS InvestmentModifiedAfterPaymentForSpecificCostAdj,'_',0.00,RegularPaymentAmount_Currency,0,RegularPaymentAmount_Currency,IsSpecializedUseAssets,0.0,0.0,0.0,0.0,0.0,RegularPaymentAmount_Currency,0.0,RegularPaymentAmount_Currency,0.0,RegularPaymentAmount_Currency,0.0,0.0,0,0,0,0,0,0,0,'_',0,IsStepPayment,StepPercentage,StepPeriod,StubAdjustment,0, 0, 0.0, R_OTPPayableCodeId, lfd.OTPRentPayableWithholdingTaxRate,0.00,0,0.00,RegularPaymentAmount_Currency,0.00,RegularPaymentAmount_Currency,lfd.FinancedAmountExclVAT_Amount,lfd.FinancedAmountExclVAT_Currency,lfd.AdvancetoDealer_Amount,lfd.AdvancetoDealer_Currency,lfd.IsBuybackGuaranteebyVendor,lfd.R_DownPaymentPercentageId,NetTermBasis,NetTerms,CAST (0 AS BIT),OverrideReason,IsPromissoryNote,PromissoryNote_Amount,PromissoryNote_Currency,IsApplicable,DateOfIncorporation,ExpirationDate,IsReleased,CashGuaranteesAmount_Amount,CashGuaranteesAmount_Currency
FROM #CreatedLeaseFinanceIds AS LF
INNER JOIN stgLease AS l WITH (NOLOCK) ON l.Id = LF.Id
INNER JOIN stgLeaseFinanceDetail AS lfd ON l.Id = lfd.Id  

print 'LeaseAssets'

--LeaseOTPParameter

INSERT INTO dbo.LeaseOTPSharingParameters(PaymentNumber,OTPSharingPercentage,LeaseFinanceDetailId,IsActive,CreatedById,CreatedTime,UpdatedById,UpdatedTime,IsNewlyAdded)
SELECT sp.PaymentNumber,sp.OTPSharingPercentage,LF.InsertedId,1,@UserId,@CreatedTime,NULL,NULL,0
FROM stgLeaseOTPSharingParameter sp
JOIN #ProcessableLeaseTemp AS l ON l.id = sp.LeaseFinanceDetailId
INNER JOIN #CreatedLeaseFinanceIds AS LF ON l.Id = LF.Id;  

--LeaseFinanceWHTDetail

INSERT INTO dbo.LeaseFinanceWHTDetails(LeaseFinanceDetailId,EffectiveFromDate,IsApplicableForWHT,IsActive,CreatedById,CreatedTime,UpdatedById,UpdatedTime)
SELECT LF.InsertedId,sp.EffectiveFromDate,sp.IsApplicableForWHT,1,@UserId,@CreatedTime,NULL,NULL
FROM stgLeaseFinanceWHTDetail sp
JOIN #ProcessableLeaseTemp AS l ON l.id = sp.LeaseFinanceDetailId
INNER JOIN #CreatedLeaseFinanceIds AS LF ON l.Id = LF.Id; 

--LeaseAssets

SELECT sla.R_AssetId,l.AccountingStandard
INTO #LeaseAccountingStandard
FROM stglease l
JOIN #ProcessableLeaseTemp AS p ON p.id = l.Id
JOIN LegalEntities le ON l.R_LegalEntityId=le.Id
JOIN stgLeaseAsset sla ON l.id=sla.leaseid
JOIN stgAsset sa on sla.R_AssetId=sa.Id
WHERE l.AccountingStandard<>le.AccountingStandard AND sla.R_AssetId IS NOT NULL

create table #AssetsWithIsLeaseComponentChanged
(
Assetid int,
IsLeaseComponent bit
)

UPDATE asset SET IsLeaseComponent= atc.IsLeaseComponent
OUTPUT INSERTED.ID,INSERTED.IsLeaseComponent into #AssetsWithIsLeaseComponentChanged
FROM Assets asset with (NOLOCK)
JOIN #LeaseAccountingStandard st ON asset.Id= st.R_AssetId
JOIN AssetTypeAccountingComplianceDetails atc ON st.AccountingStandard=atc.AccountingStandard AND asset.TypeId= atc.AssetTypeId

UPDATE assetvaluehistory SET assetvaluehistory.IsLeaseComponent=assetsWithIsLeaseComponentChanged.isleasecomponent
FROM  AssetValueHistories assetvaluehistory with (NOLOCK)
JOIN #AssetsWithIsLeaseComponentChanged assetsWithIsLeaseComponentChanged
on assetvaluehistory.AssetId=assetsWithIsLeaseComponentChanged.Assetid


INSERT INTO dbo.LeaseAssets ( ReferenceNumber ,NBV_Amount ,NBV_Currency ,Markup_Amount ,Markup_Currency ,SpecificCostAdjustment_Amount ,SpecificCostAdjustment_Currency ,SpecificCostAdjustmentOnCommencement_Amount ,SpecificCostAdjustmentOnCommencement_Currency ,InstallationDate ,UsePayDate ,PaymentDate ,InterimInterestProcessedAfterPayment ,InterimRentProcessedAfterPayment ,InterimInterestStartDate ,InterimRentStartDate ,BillMaxInterim ,MaximumInterimDays ,InterimRentFactor ,InterimRent_Amount ,InterimRent_Currency ,RentFactor ,Rent_Amount ,Rent_Currency ,OTPRentFactor ,OTPRent_Amount ,OTPRent_Currency ,RVRecapFactor ,RVRecapAmount_Amount ,RVRecapAmount_Currency ,SupplementalRentFactor ,SupplementalRent_Amount ,SupplementalRent_Currency ,CustomerExpectedResidualFactor ,CustomerExpectedResidual_Amount ,CustomerExpectedResidual_Currency ,BookedResidualFactor ,BookedResidual_Amount ,BookedResidual_Currency ,CustomerGuaranteedResidualFactor ,CustomerGuaranteedResidual_Amount ,CustomerGuaranteedResidual_Currency ,ThirdPartyGuaranteedResidualFactor ,ThirdPartyGuaranteedResidual_Amount ,ThirdPartyGuaranteedResidual_Currency ,ResidualValueInsuranceFactor ,ResidualValueInsurance_Amount ,ResidualValueInsurance_Currency ,CapitalizedInterimInterest_Amount ,CapitalizedInterimInterest_Currency ,CapitalizedInterimRent_Amount ,CapitalizedInterimRent_Currency ,CapitalizedSalesTax_Amount ,CapitalizedSalesTax_Currency ,CapitalizationType ,IsEligibleForBilling ,TerminationDate ,IsActive ,IsTransferAsset ,InterimInterestGeneratedTillDate ,InterimRentGeneratedTillDate ,IsTaxDepreciable ,IsTaxAccountingActive ,TaxBasisAmount_Amount ,TaxBasisAmount_Currency ,TaxDepStartDate ,TaxDepEndDate ,AccumulatedDepreciation_Amount ,AccumulatedDepreciation_Currency ,AssetImpairment_Amount ,AssetImpairment_Currency ,DeferredRentalIncome_Amount ,DeferredRentalIncome_Currency ,CapitalizedProgressPayment_Amount ,CapitalizedProgressPayment_Currency ,IsCollateralOnLoan ,IsNewlyAdded ,IsPrimary ,OriginalCapitalizedAmount_Amount ,OriginalCapitalizedAmount_Currency ,SalesTaxAmount_Amount ,SalesTaxAmount_Currency ,IsApproved ,TaxPaidtoVendor_Amount ,TaxPaidtoVendor_Currency ,GSTTaxPaidtoVendor_Amount ,GSTTaxPaidtoVendor_Currency ,HSTTaxPaidtoVendor_Amount ,HSTTaxPaidtoVendor_Currency ,QSTorPSTTaxPaidtoVendor_Amount ,QSTorPSTTaxPaidtoVendor_Currency ,CreatedById ,CreatedTime ,AssetId ,CapitalizedForId ,TaxDepTemplateId ,BillToId ,PayableInvoiceId ,LeaseTaxAssessmentDetailId ,LeaseRestructureId ,LeaseFinanceId ,OTPDepreciationTerm ,TaxReservePercentage ,BookDepreciationTemplateId ,AssessedUpfrontTax_Amount ,AssessedUpfrontTax_Currency ,CustomerCost_Amount ,CustomerCost_Currency ,ETCAdjustmentAmount_Amount ,ETCAdjustmentAmount_Currency ,PrepaidUpfrontTax_Amount ,PrepaidUpfrontTax_Currency ,FXTaxBasisAmount_Amount ,FXTaxBasisAmount_Currency ,IsPrepaidUpfrontTax ,ValueAsOfDate ,OnRoadDate ,IsLeaseAsset ,IsSaleLeaseback ,CapitalizedIDC_Amount ,CapitalizedIDC_Currency ,MaturityPaymentFactor ,IsFailedSaleLeaseback ,FMV_Amount ,FMV_Currency ,MaturityPayment_Amount ,MaturityPayment_Currency ,InterimMarkup_Amount ,InterimMarkup_Currency ,CapitalizedAdditionalCharge_Amount ,CapitalizedAdditionalCharge_Currency ,PreviousCapitalizedAdditionalCharge_Amount ,PreviousCapitalizedAdditionalCharge_Currency ,IsAdditionalChargeSoftAsset ,AcquisitionLocationId ,SalesTaxRemittanceResponsibility ,VendorRemitToId ,EligibleForResidualValueInsurance ,TRACPercentage ,CertificateOfAcceptanceNumber ,CertificateOfAcceptanceStatus ,TrueDownPayment_Amount ,TrueDownPayment_Currency,
RequestedResidualPercentage,InsuranceAssessment_Amount,InsuranceAssessment_Currency,BranchAddressId,PreCapitalizationRent_Amount, PreCapitalizationRent_Currency,UpfrontLossOnLease_Amount,UpfrontLossOnLease_Currency)
OUTPUT Inserted.Id, Inserted.AssetId into #CreatedLeaseAssetIds
SELECT ROW_NUMBER() OVER (PARTITION BY la.LeaseId ORDER BY la.Id) AS ReferenceNumber ,NBV_Amount ,NBV_Currency ,Markup_Amount ,Markup_Currency ,0.00 ,NBV_Currency ,0.00 ,NBV_Currency ,a.InServiceDate ,UsePayDate ,PaymentDate ,CAST(0 AS BIT) ,CAST(0 AS BIT) ,InterimInterestStartDate ,InterimRentStartDate ,BillMaxInterimRent ,MaximumInterimDays ,InterimRentFactor ,InterimRentalAmount_Amount ,InterimRentalAmount_Currency ,RentFactor ,FixedTermRentalAmount_Amount ,FixedTermRentalAmount_Currency ,OTPRentFactor ,OTPRentalAmount_Amount ,OTPRentalAmount_Currency ,RVRecapFactor ,RVRecapAmount_Amount ,RVRecapAmount_Currency ,SupplementalRentFactor ,SupplementalRent_Amount ,SupplementalRent_Currency ,CustomerExpectedResidualFactor ,CustomerExpectedResidualAmount_Amount ,CustomerExpectedResidualAmount_Currency ,BookedResidualFactor ,ResidualBookedAmount_Amount ,ResidualBookedAmount_Currency ,CustomerGuaranteedResidualFactor ,CustomerGuaranteedResidualAmount_Amount ,CustomerGuaranteedResidualAmount_Currency ,ThirdPartyGuaranteedResidualFactor ,ThirdPartyGuaranteedResidualAmount_Amount ,ThirdPartyGuaranteedResidualAmount_Currency ,0.00 ,0.00 ,Markup_Currency ,0.0 ,Markup_Currency ,0.0 ,Markup_Currency ,0.00 ,Markup_Currency ,'_' ,IsApproved ,NULL ,CAST(1 AS BIT) ,CAST(0 AS BIT) ,NULL ,NULL ,0 ,CAST(0 AS BIT) ,0.00 ,NBV_Currency ,NULL ,NULL ,0.00 ,NBV_Currency ,0.00 ,NBV_Currency ,0.00 ,NBV_Currency ,0.00 ,Markup_Currency ,CAST(0 AS BIT) ,CAST(1 AS BIT) ,IsPrimary ,0.00 ,Markup_Currency ,0.00 ,Markup_Currency ,IsApproved ,la.TaxPaidtoVendor_Amount ,la.TaxPaidtoVendor_Currency ,la.GSTTaxPaidtoVendor_Amount ,la.GSTTaxPaidtoVendor_Currency ,la.HSTTaxPaidtoVendor_Amount ,la.HSTTaxPaidtoVendor_Currency ,la.QSTorPSTTaxPaidtoVendor_Amount ,la.QSTorPSTTaxPaidtoVendor_Currency ,@UserId ,@CreatedTime ,R_AssetId ,NULL ,NULL ,CASE  WHEN @BillToLevel = 'Deal' THEN lease.R_BillToId WHEN la.R_BillToId IS NULL THEN lease.R_BillToId ELSE la.R_BillToId END ,NULL ,NULL ,NULL ,LF.InsertedId ,OTPRemainingLifeInMonths ,TaxReservePercentage ,R_BookDepreciationTemplateId ,0.0 ,la.QSTorPSTTaxPaidtoVendor_Currency ,0.00 ,Markup_Currency ,0.00 ,Markup_Currency ,0.00 ,Markup_Currency ,0.00 ,NBV_Currency ,CAST(0 AS BIT) ,a.InServiceDate ,OnRoadDate ,CASE  WHEN (a.IsLeaseComponent = 1AND IsFailedSaleLeaseback = 0) THEN 1 ELSE 0 END ,a.IsSaleLeaseback ,0.0 ,FMV_Currency ,0.0 ,IsFailedSaleLeaseback ,FMV_Amount ,FMV_Currency ,AssetMaturityPayment_Amount ,AssetMaturityPayment_Currency ,0.00 ,Markup_Currency ,0.00 ,Markup_Currency ,0.00 ,Markup_Currency ,0 ,la.R_AcquisitionLocationId ,la.SalesTaxRemittanceResponsibility ,la.R_VendorRemitToId ,'_' ,la.TRACPercentage ,la.CertificateOfAcceptanceNumber ,la.CertificateOfAcceptanceStatus ,0.00 ,Markup_Currency,la.RequestedResidualPercentage,la.InsuranceAssessment_Amount,la.InsuranceAssessment_Currency,la.R_BranchAddressId, 0.00, Markup_currency, 0.00, Markup_currency 
FROM stgLeaseAsset la  
	 INNER JOIN dbo.Assets a ON la.R_AssetId = a.Id
	 INNER JOIN stgLease lease on la.leaseId = lease.Id  
	 INNER JOIN #CreatedLeaseFinanceIds AS LF ON la.LeaseId = LF.Id;  

INSERT INTO dbo.LeaseAssetSKUs(NBV_Amount, NBV_Currency, CreatedById, CreatedTime, FMV_Amount, FMV_Currency, CustomerCost_Amount, CustomerCost_Currency, SpecificCostAdjustment_Amount, SpecificCostAdjustment_Currency, SpecificCostAdjustmentOnCommencement_Amount, SpecificCostAdjustmentOnCommencement_Currency, InterimRent_Amount, InterimRent_Currency, Rent_Amount, Rent_Currency, OTPRent_Amount, OTPRent_Currency, RVRecapAmount_Amount, RVRecapAmount_Currency, SupplementalRent_Amount, SupplementalRent_Currency, BookedResidual_Amount, BookedResidual_Currency, CustomerGuaranteedResidual_Amount, CustomerGuaranteedResidual_Currency, ThirdPartyGuaranteedResidual_Amount, ThirdPartyGuaranteedResidual_Currency, ResidualValueInsurance_Amount, ResidualValueInsurance_Currency, MaturityPayment_Amount, MaturityPayment_Currency, PrepaidUpfrontTax_Amount, PrepaidUpfrontTax_Currency, IsActive, IsLeaseComponent, AssetSKUId, LeaseAssetId, InterimRentFactor, RentFactor, OTPRentFactor, RVRecapFactor, SupplementalRentFactor, BookedResidualFactor, CustomerExpectedResidualFactor, CustomerExpectedResidual_Amount, CustomerExpectedResidual_Currency, CustomerGuaranteedResidualFactor, ThirdPartyGuaranteedResidualFactor, ResidualValueInsuranceFactor, MaturityPaymentFactor, Markup_Amount, Markup_Currency, InterimMarkup_Amount, InterimMarkup_Currency, ETCAdjustmentAmount_Amount, ETCAdjustmentAmount_Currency, CapitalizedInterimInterest_Amount, CapitalizedInterimInterest_Currency, CapitalizedInterimRent_Amount, CapitalizedInterimRent_Currency, CapitalizedSalesTax_Amount, CapitalizedSalesTax_Currency, CapitalizedIDC_Amount, CapitalizedIDC_Currency, CapitalizedProgressPayment_Amount, CapitalizedProgressPayment_Currency, CapitalizedAdditionalCharge_Amount, CapitalizedAdditionalCharge_Currency, AccumulatedDepreciation_Amount, AccumulatedDepreciation_Currency, SalesTaxAmount_Amount, SalesTaxAmount_Currency,OriginalCapitalizedAmount_Amount, OriginalCapitalizedAmount_Currency, PreCapitalizationRent_Amount, PreCapitalizationRent_Currency)
SELECT las.NBV_Amount, las.NBV_Currency, @UserId, @CreatedTime, las.FMV_Amount, las.FMV_Currency, 0.00, las.FMV_Currency, 0.00, las.FMV_Currency, 0.00, las.FMV_Currency, 0.00, las.FMV_Currency, las.Rent_Amount , las.Rent_Currency, las.OTPRent_Amount, las.OTPRent_Currency, las.RVRecapAmount_Amount, las.RVRecapAmount_Currency, las.SupplementalRent_Amount, las.SupplementalRent_Currency, las.BookedResidual_Amount, las.BookedResidual_Currency, las.CustomerGuaranteedResidual_Amount, las.CustomerGuaranteedResidual_Currency, las.ThirdPartyGuaranteedResidual_Amount, las.ThirdPartyGuaranteedResidual_Currency, las.ResidualValueInsurance_Amount, las.ResidualValueInsurance_Currency, las.MaturityPayment_Amount, las.MaturityPayment_Currency, 0.00, las.MaturityPayment_Currency, CAST (1 AS BIT), [as].IsLeaseComponent, las.R_SKUAliasId, LeaseAssets.Id, 0.00, las.RentFactor, las.OTPRentFactor, las.RVRecapFactor, las.SupplementalRentFactor, las.BookedResidualFactor, las.CustomerExpectedResidualFactor, las.CustomerExpectedResidual_Amount, las.CustomerExpectedResidual_Currency, las.CustomerGuaranteedResidualFactor, las.ThirdPartyGuaranteedResidualFactor, las.ResidualValueInsuranceFactor, las.MaturityPaymentFactor, las.Markup_Amount, las.Markup_Currency, 0.00, las.Markup_Currency, 0.00, las.Markup_Currency, 0.00, las.Markup_Currency, 0.00, las.Markup_Currency, 0.00, las.Markup_Currency, 0.00, las.Markup_Currency, 0.00, las.Markup_Currency, 0.00, las.Markup_Currency, 0.00, las.Markup_Currency , 0.00, las.Markup_Currency,0.00, las.Markup_Currency, 0.00, las.Markup_Currency
FROM stgLeaseAssetSKU las
INNER JOIN stgLeaseAsset la ON las.LeaseAssetId = la.Id
INNER JOIN LeaseAssets ON LeaseAssets.AssetId = la.R_AssetId
INNER JOIN Assets a ON la.R_AssetId = a.Id
INNER JOIN AssetSKUs [as] ON [as].Alias = las.SKUAlias AND [as].AssetId = a.Id
INNER JOIN #CreatedLeaseFinanceIds AS LF ON la.LeaseId = LF.Id;  

INSERT INTO dbo.LeasePreclassificationResults(Id, CreatedById, CreatedTime, ContractType, PreClassificationYield5A, PreClassificationYield5B, PreClassificationYield, NinetyPercentTestPresentValue5A_Amount, NinetyPercentTestPresentValue5A_Currency, NinetyPercentTestPresentValue5B_Amount, NinetyPercentTestPresentValue5B_Currency, NinetyPercentTestPresentValue_Amount, NinetyPercentTestPresentValue_Currency, PreRVINinetyPercentTestPresentValue_Amount, PreRVINinetyPercentTestPresentValue_Currency)
SELECT cli.InsertedId, @UserId, @CreatedTime, la.ContractType, 0.00, 0.00, 0.00, 0.00, la.NBV_Currency, 0.00, la.NBV_Currency, 0.00, la.NBV_Currency, 0.00, la.NBV_Currency
FROM stgLeaseAsset la WITH (NOLOCK)
INNER JOIN #CreatedLeaseAssetIds cli ON la.R_AssetId = cli.AssetId

UPDATE LeaseAssets SET NBV_Amount = Temp.NBV_Amount, FMV_Amount = Temp.FMV_Amount
FROM LeaseAssets la  with (NOLOCK)
INNER JOIN 
(SELECT SUM(las.NBV_Amount) AS NBV_Amount, FMV_Amount = SUM(las.FMV_Amount), las.LeaseAssetId AS LeaseAssetId
FROM LeaseAssets la WITH (NOLOCK)
INNER JOIN LeaseAssetSKUs las WITH (NOLOCK) ON la.Id = las.LeaseAssetId
INNER JOIN LeaseFinances lf  with (NOLOCK) ON la.LeaseFinanceId = lf.Id
INNER JOIN #CreatedLeaseFinanceIds AS clf ON clf.ContractId = lf.ContractId
GROUP BY las.LeaseAssetId
) AS Temp ON la.Id = Temp.LeaseAssetId

UPDATE LeaseAssets SET IsLeaseAsset = CASE WHEN Assets.IsLeaseComponent = 1  AND LeaseAssets.IsFailedSaleLeaseback = 1 THEN 0
										   WHEN Assets.IsLeaseComponent = 1  AND LeaseAssets.IsFailedSaleLeaseback = 0 THEN 1
										   WHEN Assets.IsLeaseComponent = 0 THEN 0
									  END	
FROM LeaseAssets  with (NOLOCK)
INNER JOIN Assets  with (NOLOCK) ON LeaseAssets.AssetId = Assets.Id
INNER JOIN #CreatedLeaseFinanceIds AS LF ON LeaseAssets.LeaseFinanceId = LF.InsertedId
WHERE LeaseAssets.IsSaleLeaseback = 1;  

UPDATE LeaseAssetSKUs SET IsLeaseComponent = CASE WHEN AssetSKUs.IsLeaseComponent = 1  AND LeaseAssets.IsFailedSaleLeaseback = 1 THEN 0
												WHEN AssetSKUs.IsLeaseComponent = 1  AND LeaseAssets.IsFailedSaleLeaseback = 0 THEN 1
												WHEN AssetSKUs.IsLeaseComponent = 0 THEN 0
											END
FROM LeaseAssetSKUs  with (NOLOCK)
INNER JOIN LeaseAssets  with (NOLOCK) ON LeaseAssetSKUs.LeaseAssetId = LeaseAssets.Id
INNER JOIN AssetSKUs  with (NOLOCK) ON AssetSKUs.AssetId = LeaseAssets.AssetId AND AssetSKUs.Id = LeaseAssetSKUs.AssetSKUId
INNER JOIN #CreatedLeaseFinanceIds AS LF ON LeaseAssets.LeaseFinanceId = LF.InsertedId
WHERE LeaseAssets.IsSaleLeaseback = 1;

UPDATE agl SET agl.HoldingStatus = lease.HoldingStatus,agl.InstrumentTypeId = ISNULL(lease.R_InstrumentTypeId,agl.InstrumentTypeId)
,agl.LineofBusinessId = ISNULL(lease.R_LineofBusinessId,agl.LineofBusinessId),agl.OriginalInstrumentTypeId = ISNULL(lease.R_InstrumentTypeId,agl.OriginalInstrumentTypeId)
,agl.OriginalLineofBusinessId = ISNULL(lease.R_LineofBusinessId, agl.OriginalLineofBusinessId)
,agl.CostCenterId = ISNULL(lease.R_CostCenterId, agl.CostCenterId),agl.BranchId = ISNULL(lease.R_BranchId,agl.BranchId)
FROM AssetGLDetails agl WITH (NOLOCK) 
INNER JOIN stgLeaseAsset la  WITH (NOLOCK) ON agl.Id = la.R_AssetId
INNER JOIN stgLease lease  WITH (NOLOCK) on la.leaseId = lease.Id
INNER JOIN #CreatedLeaseFinanceIds AS LF WITH (NOLOCK)  ON la.LeaseId = LF.Id; 
	   print 'LeaseBlendedItemAsset'
UPDATE stgLeaseBlendedItemAsset SET R_LeaseAssetId = la.Id  
FROM 
stgLeaseBlendedItemAsset lbia WITH (NOLOCK) 
INNER JOIN stgLeaseBlendedItem lbi  WITH (NOLOCK) ON lbia.LeaseBlendedItemId = lbi.Id
INNER JOIN #CreatedLeaseFinanceIds AS LF  WITH (NOLOCK) ON lbi.LeaseId = LF.Id
INNER JOIN dbo.LeaseAssets la  WITH (NOLOCK) ON lbia.R_AssetId = la.AssetId
WHERE lbia.R_AssetId IS NOT NULL  

--------LeaseFinanceCollateral
Insert into LeaseFinanceCollaterals(Type,CreatedById,CreatedTime,DateOfIncorporation,ExpirationDate,IsReleased,IsActive,LeaseFinanceId)
select Collateral.Type,@UserId, @CreatedTime,Collateral.DateOfIncorporation,Collateral.ExpirationDate,Collateral.IsReleased,Collateral.IsActive,LF.Id
FROM #CreatedLeaseFinanceIds AS LF (NOLOCK)  
 INNER JOIN stgLease as Lease ON Lease.Id = LF.Id
 INNER JOIN stgLeaseFinanceCollateral as Collateral ON Collateral.LeaseId = Lease.Id
--LeaseInterestRates  
CREATE TABLE #InterestRateDetail  
(InterestRateDetailId BIGINT, LeaseFinanceId BIGINT, LeaseId BIGINT);  
MERGE INTO InterestRateDetails  
USING  
(  
 SELECT lir.*, LF.InsertedId LeaseFinanceId, LF.Id LeaseId  
 FROM stgLeaseInterestRate lir WITH (NOLOCK)  
	  INNER JOIN #CreatedLeaseFinanceIds AS LF ON lir.LeaseFinanceDetailId = LF.Id) IR  ON 1 = 0  
WHEN NOT MATCHED  
	  THEN  
	  INSERT(IsFloatRate, EffectiveDate, BaseRate, Spread, InterestRate, FloorPercent, CeilingPercent, FloatRateResetFrequency, FloatRateResetUnit, FirstResetDate, CompoundingFrequency, HolidayMoveMethod, IsActive, IsIndexPercentage, PercentageBasis, Percentage, IsLeadUnitsinBusinessDays, LeadFrequency, LeadUnits, EffectiveDayofMonth, IsMoveAcrossMonth, ModificationType, IsNewlyAdded, BankIndexDescription, CreatedById, CreatedTime, FloatRateIndexId, IsHighPrimeInterest,IsManualInterestMargin,InterestConfiguration,RateCardInterest)  
	  VALUES  
(IsFloatRate, EffectiveDate, BaseRate, Spread, InterestRate, CASE WHEN IsHighPrimeInterest = 1 THEN 0.00 ELSE FloorPercent END, CASE WHEN IsHighPrimeInterest = 1 THEN CAST(9999.00 AS Decimal(10, 6)) ELSE CeilingPercent END, FloatRateResetFrequency, FloatRateResetUnit, FirstResetDate, 'NotApplicable', HolidayMethod, CAST(1 AS BIT), IsIndexPercentage, PercentageBasis, Percentage, IsLeadUnitsinBusinessDays, CASE WHEN IR.LeadDays <> 0 THEN 'Day' ELSE 'Month' END, CASE WHEN IR.LeadDays <> 0 THEN LeadDays ELSE LeadMonths END, EffectiveDayofMonth, IsMoveAcrossMonth, 'LeaseBooking', CAST(0 AS BIT), NULL, @UserId, @CreatedTime, R_FloatRateIndexId, IsHighPrimeInterest,IsManualInterestMargin,InterestConfiguration,RateCardInterest)  
OUTPUT INSERTED.Id, IR.LeaseFinanceId, IR.LeaseId  
	   INTO #InterestRateDetail;  
INSERT INTO dbo.LeaseInterestRates(IsPricingInterestRate, IsSystemGenerated, CreatedById, CreatedTime, InterestRateDetailId, ParentLeaseInterestRateId, LeaseFinanceDetailId)  
SELECT CAST(1 AS BIT), CAST(0 AS BIT), @UserId, @CreatedTime, InterestRateDetailId, NULL, ird.LeaseFinanceId  
FROM stgLeaseInterestRate lir  
	 INNER JOIN #InterestRateDetail ird ON lir.LeaseFinanceDetailId = ird.LeaseId;  
--LeaseBlendedItem  
CREATE TABLE #BlendedItem(BlendedItemId BIGINT,LeaseBlendedItemId BIGINT, LeaseId BIGINT, LeaseFinanceId BIGINT, Currency NVARCHAR(25));  
	  print 'BlendedItems'
MERGE INTO BlendedItems  
USING  
(  
SELECT lbi.*,ROW_NUMBER() OVER (PARTITION BY lbi.LeaseId ORDER By lbi.Id) AS RowNumber, LF.InsertedId LeaseFinanceId,lfd.CommencementDate, LeaseAssets.Id As LeaseAssetId 
 FROM stgLeaseBlendedItem lbi WITH (NOLOCK)
	  INNER JOIN stgLeaseFinanceDetail lfd WITH (NOLOCK) ON lbi.LeaseId = lfd.Id
	  INNER JOIN #CreatedLeaseFinanceIds AS LF ON lbi.LeaseId = LF.Id	  
	  LEFT JOIN stgLeaseBlendedItemAsset lbia WITH (NOLOCK) ON lbia.LeaseBlendedItemId = lbi.Id
	  LEFT JOIN LeaseAssets On LeaseAssets.LeaseFinanceId = LF.InsertedId AND LeaseAssets.AssetId = lbia.R_AssetId
	  WHERE NOT (lbi.Type = 'Income' AND IsAssetBased = 1 AND IsETC = 1)
UNION 
SELECT lbi.*,ROW_NUMBER() OVER (PARTITION BY lbi.LeaseId ORDER By lbi.Id) AS RowNumber, LF.InsertedId LeaseFinanceId,lfd.CommencementDate, NULL As LeaseAssetId 
 FROM stgLeaseBlendedItem lbi WITH (NOLOCK)
	  INNER JOIN stgLeaseFinanceDetail lfd WITH (NOLOCK) ON lbi.LeaseId = lfd.Id
	  INNER JOIN #CreatedLeaseFinanceIds AS LF ON lbi.LeaseId = LF.Id
	  WHERE lbi.Type = 'Income' AND IsAssetBased = 1 AND IsETC = 1
) BI 
ON 1 = 0 
WHEN NOT MATCHED  
	  THEN  
	  INSERT(Name, RowNumber, EntityType, Amount_Amount, VATAmount_Amount,VATAmount_Currency , Amount_Currency, StartDate, EndDate, CurrentEndDate, DueDate, DueDay, Frequency, FrequencyUnit, Occurrence, NumberOfPayments, NumberOfReceivablesGenerated, Type, DeferRecognition, IsAssetBased, IsFAS91, IncludeInClassificationTest, IncludeInBlendedYield, Description, AccumulateExpense, BookRecognitionMode, RecognitionMethod, ExpenseRecognitionMode, TaxRecognitionMode, GeneratePayableOrReceivable, InvoiceReceivableGroupingOption, IsActive, IsNewlyAdded, PostDate, SystemConfigType, IsSystemGenerated, IsVendorSubsidy, IsVendorCommission, IsETC, TaxCreditTaxBasisPercentage, EarnedAmount_Amount, EarnedAmount_Currency, AmountBilled_Amount, AmountBilled_Currency, CreatedById, CreatedTime, ParentBlendedItemId, BlendedItemCodeId, ReceivableCodeId, PayableCodeId, LeaseAssetId, LocationId, BillToId, PayableRemitToId, BookingGLTemplateId, RecognitionGLTemplateId, TaxDepTemplateId, PartyId, IsFromST, ReceivableRemitToId,PayableWithholdingTaxRate)  
	  VALUES(Name, RowNumber, 'Lease', Amount_Amount,0.00,Amount_Currency, Amount_Currency, StartDate, EndDate, NULL, ISNULL(DueDate,CommencementDate), DueDay, Frequency, FrequencyUnit, Occurrence, NumberOfPayments, CAST (0 AS BIT), Type, CAST(0 AS BIT), IsAssetBased, IsFAS91, IncludeInClassificationTest, IncludeInBlendedYield, Description, AccumulateExpense, BookRecognitionMode, RecognitionMethod, '_', TaxRecognitionMode, GeneratePayableOrReceivable, InvoiceReceivableGroupingOption, CAST(1 AS BIT), CAST(0 AS BIT), PostDate, '_', CAST(0 AS BIT), IsVendorSubsidy, IsVendorCommission, IsETC, TaxCreditTaxBasisPercentage, 0.00, Amount_Currency, 0.00, Amount_Currency, @UserId, @CreatedTime, R_ParentBlendedItemId, R_BlendedItemCodeId, R_ReceivableCodeId, R_PayableCodeId, LeaseAssetId, R_LocationId, R_BillToId, R_PayableRemitToId, R_BookingGLTemplateId, R_RecognitionGLTemplateId, R_TaxDepTemplateId, R_PartyId, CAST(0 AS BIT), R_ReceivableRemitToId, PayableWithholdingTaxRate)  
OUTPUT INSERTED.Id,BI.Id, BI.LeaseId, BI.LeaseFinanceId, BI.Amount_Currency
	   INTO #BlendedItem;  
UPDATE BlendedItems SET StartDate = NULL, EndDate = NULL
	  FROM  BlendedItems bi WITH (NOLOCK)
	  INNER JOIN #BlendedItem tbi ON bi.Id = tbi.BlendedItemId
	  WHERE bi.BookRecognitionMode = 'RecognizeImmediately'
		   
INSERT INTO dbo.BlendedItemAssets(Cost_Amount, Cost_Currency, TaxCredit_Amount, TaxCredit_Currency, UpfrontTaxReduction_Amount, UpfrontTaxReduction_Currency, NewTaxBasis_Amount, NewTaxBasis_Currency, BookBasis_Amount, BookBasis_Currency, TaxCreditTaxBasisPercentage, IsActive, CreatedById, CreatedTime, LeaseAssetId, BlendedItemId)  
SELECT la.NBV_Amount, Currency, (la.NBV_Amount * lbi.TaxCreditTaxBasisPercentage /100), Currency,  (la.NBV_Amount * @ETCAllowableCredit / 100 * lbi.TaxCreditTaxBasisPercentage / 100), Currency,  la.NBV_Amount -  (la.NBV_Amount * @ETCAllowableCredit / 100 * lbi.TaxCreditTaxBasisPercentage / 100), Currency,  la.NBV_Amount - (la.NBV_Amount * lbi.TaxCreditTaxBasisPercentage / 100), Currency, lbi.TaxCreditTaxBasisPercentage, CAST(1 AS BIT), @UserId, @CreatedTime, lbia.R_LeaseAssetId, BlendedItemId  
FROM stgLeaseBlendedItemAsset lbia   
INNER JOIN #BlendedItem bi ON lbia.LeaseBlendedItemId = bi.LeaseBlendedItemId
INNER JOIN LeaseAssets la ON lbia.R_LeaseAssetId = la.Id
INNER JOIN stgLeaseBlendedItem lbi ON lbi.Id = lbia.LeaseBlendedItemId
INSERT INTO dbo.LeaseBlendedItems(Revise, CreatedById, CreatedTime, BlendedItemId, PayableInvoiceOtherCostId, FundingSourceId, FundingId, LeaseFinanceId,FeeDetailId)  
SELECT 0, @UserId, @CreatedTime, bi.BlendedItemId, NULL, NULL, NULL, bi.LeaseFinanceId, lbi.R_FeeDetailId  
FROM stgLeaseBlendedItem lbi  
	 INNER JOIN #BlendedItem bi ON lbi.LeaseId = bi.LeaseId AND lbi.Id = bi.LeaseBlendedItemId;  
UPDATE BlendedItems SET Amount_Amount = temp.Amount
FROM BlendedItems bi WITH (NOLOCK)
INNER JOIN (SELECT SUM(bia.TaxCredit_Amount) AS Amount, bia.BlendedItemId AS Id
			FROM #BlendedItem bi 
			INNER JOIN BlendedItemAssets bia  WITH (NOLOCK) ON bi.BlendedItemId = bia.BlendedItemId
			GROUP BY bia.BlendedItemId) AS temp ON bi.Id = temp.Id
WHERE bi.Type='Income' AND bi.IsETC = 1 AND bi.IsAssetBased = 1
UPDATE BlendedItems
SET  RowNumber = UpdateTarget.RowNumber
FROM
(
    SELECT  
			#BlendedItem.BlendedItemId
			,ROW_NUMBER() OVER (PARTITION BY #BlendedItem.LeaseId ORDER By #BlendedItem.BlendedItemId) AS RowNumber
    FROM    #BlendedItem
) AS UpdateTarget
WHERE BlendedItems.Id = UpdateTarget.BlendedItemId;
INSERT INTO dbo.LeaseBlendedItemVATInfoes(Amount_Amount,Amount_Currency,CreatedById,CreatedTime,VATAmount_Amount,VATAmount_Currency,DueDate,IsActive
,BlendedItemId,LeaseBlendedItemId)  
SELECT  Amount_Amount,Amount_Currency,CreatedById,CreatedTime,VATAmount_Amount,VATAmount_Currency,DueDate,CAST(1 AS BIT),bi.BlendedItemId, bi.LeaseBlendedItemId
FROM stgLeaseBlendedItemVATInfo lbi  
	 INNER JOIN #BlendedItem bi ON lbi.LeaseBlendedItemId = bi.LeaseBlendedItemId;  
--LeaseAdditionalCharge
CREATE TABLE #AdditionalCharge(AdditionalChargeId BIGINT,LeaseAdditionalChargeId BIGINT, LeaseId BIGINT, LeaseFinanceId BIGINT,Currency NVARCHAR(25));
	print 'AdditionalCharges'
MERGE INTO AdditionalCharges
USING 
(
SELECT lac.*,ROW_NUMBER() OVER (PARTITION BY lac.LeaseId ORDER By lac.Id) AS RowNumber,LF.InsertedId LeaseFinanceId,lfd.CommencementDate
 FROM stgLeaseAdditionalCharge lac WITH (NOLOCK)
	  INNER JOIN stgLeaseFinanceDetail lfd WITH (NOLOCK) ON lac.LeaseId = lfd.Id
	  INNER JOIN #CreatedLeaseFinanceIds AS LF ON lac.LeaseId = LF.Id
) AC
on 1 = 0
WHEN NOT MATCHED
	  THEN  
	  INSERT(RowNumber, Amount_Amount,VATAmount_Amount,VATAmount_Currency , Amount_Currency, CreatedById, CreatedTime, Capitalize, CreateSoftAsset, Recurring, ReceivableDueDate, RecurringNumber, FirstDueDate, DueDay, Frequency, ChargeApplicable, IsActive, FeeId, ReceivableCodeId, GLTemplateId, SourceType)  
	  VALUES(RowNumber, Amount_Amount, 0.00, Amount_Currency, Amount_Currency, @UserId, @CreatedTime, Capitalize, 0, Recurring, ReceivableDueDate, RecurringNumber, FirstDueDate, DueDay, Frequency, 0, CAST(1 AS BIT), R_FeeId, R_ReceivableCodeId, R_GLTemplateId, '_')  
OUTPUT INSERTED.Id ,AC.Id, AC.LeaseId, AC.LeaseFinanceId, AC.Amount_Currency
	   INTO #AdditionalCharge; 
INSERT INTO dbo.LeaseFinanceAdditionalCharges(CreatedById, CreatedTime, AdditionalChargeId, SundryId, RecurringSundryId, LeaseAssetId, LeaseFinanceId,IsAssetBased,SundryType,GracePeriodinMonths,DueDate,IsRentalBased,IsIncludeinAPR,IsVatable,ReceivableAmountInclVAT_Amount,ReceivableAmountInclVAT_Currency,PayableAmount_Amount,PayableAmount_Currency,VendorId,RemitToId,PayableCodeId)  
SELECT @UserId, @CreatedTime, ac.AdditionalChargeId, NULL, NULL, NULL, ac.LeaseFinanceId,lac.IsAssetBased,lac.SundryType,lac.GracePeriodinMonths,lac.payableDueDate,lac.IsRentalBased,lac.IsIncludeinAPR,lac.IsVatable,lac.ReceivableAmountInclVAT_Amount,lac.ReceivableAmountInclVAT_Currency,lac.PayableAmount_Amount,lac.PayableAmount_Currency,lac.R_VendorId,lac.R_RemitToId,lac.R_PayableCodeId  
FROM stgLeaseAdditionalCharge lac  
	 INNER JOIN #AdditionalCharge ac ON lac.LeaseId = ac.LeaseId AND lac.Id = ac.LeaseAdditionalChargeId; 
INSERT INTO dbo.LeaseFinanceAdditionalChargeVATInfoes(Amount_Amount, Amount_Currency, VATAmount_Amount,VATAmount_Currency , CreatedById, CreatedTime,
DueDate, IsActive, LeaseFinanceAdditionalChargeId, AdditionalChargeId )  
SELECT  Amount_Amount,Amount_Currency,VATAmount_Amount,VATAmount_Currency,CreatedById,CreatedTime,DueDate,CAST(1 AS BIT),lacvi.LeaseAdditionalChargeId
, AC.AdditionalChargeId
FROM stgLeaseAdditionalChargeVATInfo lacvi  
	 INNER JOIN #AdditionalCharge AC ON lacvi.LeaseAdditionalChargeId = AC.LeaseAdditionalChargeId;  	
--LeaseContractOptions  
	 print 'LeaseContractOptions' 
INSERT INTO dbo.LeaseContractOptions(ContractOption, ContractOptionTerms, IsEarly, IsAnyDay, OptionDate, PurchaseFactor, RenewalFactor, Penalty, IsPartialPermitted, IsExcluded, IsRenewalOfferApproved, LesseeNoticeDays, RestockingFee, IsActive, CreatedById, CreatedTime, LeaseFinanceId, OptionMonth, Amount_Amount, Amount_Currency, IsOptionControlledByLessor, IsLesseeReasonablyCertainToExerciseOption)  
SELECT ContractOption, ContractOptionTerms, IsEarly, IsAnyDay, OptionDate, PurchaseFactor, RenewalFactor, Penalty, IsPartialPermitted, IsExcluded, IsRenewalOfferApproved, LesseeNoticeDays, RestockingFee, CAST(1 AS BIT), @UserId, @CreatedTime, LF.InsertedId, OptionMonth, Amount_Amount, Amount_Currency, IsOptionControlledByLessor, IsLesseeReasonablyCertainToExerciseOption  
FROM stgLeaseContractOption lco  
	 INNER JOIN #CreatedLeaseFinanceIds AS LF ON lco.LeaseId = LF.Id;  
--ContractLateFees  
CREATE TABLE #LeaseLateFee  
(LeaseLateFeeId BIGINT, LeaseId BIGINT, LateFeeTemplateId BIGINT);  
	 print 'ContractLateFees' 
MERGE INTO ContractLateFees  
USING  
(  
 SELECT LF.ContractId AS ID, LF.Id AS LeaseId, InvoiceGraceDays, InvoiceGraceDaysAtInception, Spread, InterestFloorPercentage, InterestCeilingPercentage, HolidayMethod, IsMoveAcrossMonth, IsIndexPercentage, PercentageBasis, Percentage, R_LateFeeTemplateId, LT.Currency AS Currency ,Lft.FloorAmount_Amount, Lft.CeilingAmount_Amount, LT.WaiveIfLateFeeBelowAmount, LT.WaiveIfInvoiceAmountBelowAmount
 FROM #CreatedLeaseFinanceIds AS LF 
 INNER JOIN #LeaseTable LT ON LF.Id = LT.Id
 LEFT JOIN stgLeaseLateFee AS LLF WITH (NOLOCK) ON LLF.Id = LF.Id
 LEFT JOIN Latefeetemplates Lft  ON LLF.R_LateFeeTemplateId = Lft.Id) CLF
ON 1 = 0  
WHEN NOT MATCHED  
	  THEN  
	  INSERT(Id, InvoiceGraceDays, LateFeeFloorAmount_Amount, LateFeeFloorAmount_Currency, LateFeeCeilingAmount_Amount, LateFeeCeilingAmount_Currency, WaiveIfLateFeeBelow_Amount, WaiveIfLateFeeBelow_Currency, WaiveIfInvoiceAmountBelow_Amount, WaiveIfInvoiceAmountBelow_Currency, InvoiceGraceDaysAtInception, Spread, InterestFloorPercentage, InterestCeilingPercentage, HolidayMethod, IsMoveAcrossMonth, IsIndexPercentage, PercentageBasis, Percentage, IsActive, CreatedById, CreatedTime, LateFeeTemplateId)  
	  	  VALUES(Id, ISNULL(InvoiceGraceDays,0), ISNULL(FloorAmount_Amount,0.00), Currency, ISNULL(CeilingAmount_Amount,0.00), Currency, ISNULL(WaiveIfLateFeeBelowAmount, 0.00), Currency, ISNULL(WaiveIfInvoiceAmountBelowAmount, 0.00), Currency, ISNULL(InvoiceGraceDaysAtInception, 0), ISNULL(Spread, 0.00), ISNULL(InterestFloorPercentage, 0.00), ISNULL(InterestCeilingPercentage, 0.00), ISNULL(HolidayMethod, '_'), ISNULL(IsMoveAcrossMonth, 0), ISNULL(IsIndexPercentage, 0), ISNULL(PercentageBasis, '_'), ISNULL(Percentage, 0.00), CAST(1 AS BIT), @UserId, @CreatedTime, R_LateFeeTemplateId) 
OUTPUT INSERTED.Id, CLF.LeaseId, Inserted.LateFeeTemplateId  
	   INTO #LeaseLateFee;  
--ContractBillings  
	 print 'ContractBillings' 
CREATE TABLE #LeaseFinanceCustomerTransitDays(
LeaseFinanceInsertedId BIGINT PRIMARY KEY,
CustomerInvoiceTransitDays INT
)
INSERT INTO #LeaseFinanceCustomerTransitDays(LeaseFinanceInsertedId, CustomerInvoiceTransitDays)
SELECT LF.Id, C.InvoiceTransitDays 
FROM LeaseFinances LF WITH (NOLOCK)
INNER JOIN #CreatedLeaseFinanceIds AS CLF ON LF.Id = CLF.InsertedId 
INNER JOIN #LeaseTable LT ON CLF.Id = LT.Id 
INNER JOIN Customers C WITH (NOLOCK) ON LF.CustomerId = C.Id;
INSERT INTO dbo.ContractBillings(Id, InvoiceComment, InvoiceCommentBeginDate, InvoiceCommentEndDate, InvoiceLeaddays,InvoiceTransitDays, IsPreACHNotification, PreACHNotificationEmail,IsPostACHNotification, PostACHNotificationEmailTo,IsReturnACHNotification, ReturnACHNotificationEmailTo,IsActive, CreatedById, CreatedTime, NotaryDate, ActaNumber, PreACHNotificationEmailTemplateId,PostACHNotificationEmailTemplateId,ReturnACHNotificationEmailTemplateId, ReceiptLegalEntityId)  
SELECT LF.ContractId, InvoiceComment, InvoiceCommentBeginDate, InvoiceCommentEndDate, ISNULL(InvoiceLeaddays, 0),LFCTD.CustomerInvoiceTransitDays, ISNULL(IsPreACHNotification, 0), PreACHNotificationEmail,ISNULL(IsPostACHNotification, 0), PostACHNotificationEmailTo,ISNULL(IsReturnACHNotification, 0), ReturnACHNotificationEmailTo,  CAST(1 AS BIT), @UserId, @CreatedTime, NotaryDate, ActaNumber, R_PreACHNotificationEmailTemplateId,R_PostACHNotificationEmailTemplateId,R_ReturnACHNotificationEmailTemplateId, ISNULL(R_ReceiptLegalEntityId, ReceiptLegalEntityId)
FROM #CreatedLeaseFinanceIds AS LF 
INNER JOIN #LeaseTable LT ON LF.Id = LT.Id
INNER JOIN #LeaseFinanceCustomerTransitDays LFCTD ON LF.InsertedId = LFCTD.LeaseFinanceInsertedId 
LEFT JOIN stgLeaseBilling lb ON lb.Id = LF.Id;  
--ContractBillingPreferences  
INSERT INTO ContractBillingPreferences(InvoicePreference, EffectiveFromDate, IsActive, CreatedById, CreatedTime, ReceivableTypeId, ContractBillingId)  
SELECT InvoicePreference, EffectiveFromDate, CAST(1 AS BIT), @UserId, @CreatedTime, R_ReceivableTypeId, LF.ContractId  
FROM stgLeaseBillingPreference lbp  
	 INNER JOIN #CreatedLeaseFinanceIds AS LF ON lbp.LeaseBillingId = LF.Id;  
	print 'ContractACHAssignments' 
--ContractACHAssignments  
INSERT INTO dbo.ContractACHAssignments(AssignmentNumber, BeginDate, EndDate, PaymentType, IsActive, CreatedById, CreatedTime, ReceivableTypeId, BankAccountId, ContractBillingId, RecurringPaymentMethod, DayoftheMonth, RecurringACHPaymentRequestId, IsEndPaymentOnMaturity)  
SELECT ROW_NUMBER() OVER (PARTITION BY la.LeaseBillingId ORDER By la.Id) AS AssignmentNumber, StartDate, EndDate, PaymentType, CAST(1 AS BIT), @UserId, @CreatedTime, R_ReceivableTypeId, R_BankAccountId, LF.ContractId, RecurringPaymentMethod, DayoftheMonth, NULL, IsEndPaymentOnMaturity  
FROM stgLeaseACHAssignment la  
	 INNER JOIN #CreatedLeaseFinanceIds AS LF ON la.LeaseBillingId = LF.Id;  	
	print 'Contractlatefeedetails' 
--Contractlatefeedetails  
INSERT INTO Contractlatefeedetails(Dayslate, Interestrate, Paypercent, Flatfee_Amount, Flatfee_Currency, Isactive, Createdbyid, Createdtime, Contractlatefeeid)  
SELECT Dayslate, Interestrate, Paypercent, Flatfeeamount_Amount, Flatfeeamount_Currency, CAST(1 AS BIT), @UserId, @CreatedTime, Llf.Leaselatefeeid  
FROM Latefeetemplates Lft  
	 INNER JOIN #Leaselatefee Llf ON Lft.Id = Llf.Latefeetemplateid  
	 INNER JOIN Dbo.Latefeetemplatedetails Lftd ON Lft.Id = Lftd.Latefeetemplateid;  
--ContractLateFeeReceivableTypes  
	print 'ContractLateFeeReceivableTypes' 
INSERT INTO ContractLateFeeReceivableTypes(IsActive, CreatedById, CreatedTime, ReceivableTypeId, ContractLateFeeId)  
SELECT CAST(1 AS BIT), @UserId, @CreatedTime, llfrt.R_ReceivableTypeId, Llf.Leaselatefeeid  
FROM stgLeaseLateFeeReceivableType llfrt  
	 INNER JOIN #Leaselatefee Llf ON llfrt.LeaseLateFeeId = Llf.LeaseId;  
--ContractContacts  
INSERT INTO dbo.ContractContacts(IsActive, ActivationDate, DeactivationDate, IsNewAddress, IsNewContact, CreatedById, CreatedTime, PartyAddressId, PartyContactId, ContractId,IsSignatory)  
SELECT CAST(1 AS BIT), Convert(date, getdate()), NULL, LC.IsNewAddress, CAST (1 AS BIT), @UserID, @CreatedTime, LC.R_PartyAddressId, LC.R_PartyContactId, LF.ContractId, LC.IsSignatory  
FROM stgLeaseContact AS LC  
  INNER JOIN stgLease L ON LC.LeaseId = L.Id  
	 INNER JOIN #CreatedLeaseFinanceIds AS LF ON l.Id = LF.Id;  
--LeaseInsuranceRequirement LeaseInsuranceRequirements  
INSERT INTO LeaseInsuranceRequirements(PerOccurrenceAmount_Amount, PerOccurrenceAmount_Currency, AggregateAmount_Amount, AggregateAmount_Currency, PerOccurrenceDeductible_Amount, PerOccurrenceDeductible_Currency, AggregateDeductible_Amount, AggregateDeductible_Currency, IsManual, IsActive, Status, IsContractAmount, CreatedById, CreatedTime, CoverageTypeConfigId, LeaseFinanceId)  
SELECT PerOccurrenceAmount_Amount, PerOccurrenceAmount_Currency, AggregateAmount_Amount, AggregateAmount_Currency, PerOccurrenceDeductible_Amount, PerOccurrenceDeductible_Currency, AggregateDeductible_Amount, AggregateDeductible_Currency, IsManual, 1, 'Met', IsContractAmount, @UserID, @CreatedTime,R_CoverageTypeConfigId, LF.InsertedId  
FROM stgLeaseInsuranceRequirement LIR  
	 INNER JOIN stgLease L ON LIR.LeaseId = L.Id  
	 INNER JOIN #CreatedLeaseFinanceIds AS LF ON l.Id = LF.Id;  
--LeaseRelatedContract LeaseRelatedContracts  
INSERT INTO LeaseRelatedContracts(IsActive, IsInclude, ReasonCode, ScheduleDate, MasterDate, ContractId, CreatedById, CreatedTime, LeaseFinanceId, IsParent)  
SELECT 1, IsInclude, ReasonCode, ScheduleDate, MasterDate, LRC.R_ContractId, @UserId, @CreatedTime, LF.InsertedId, CAST (1 AS BIT)  
FROM stgLeaseRelatedContract LRC  
	 INNER JOIN stgLease L ON LRC.LeaseId = L.Id  
	 INNER JOIN #CreatedLeaseFinanceIds AS LF ON l.Id = LF.Id;  
--LeaseStipLossDetail LeaseStipLossDetails  
INSERT INTO LeaseStipLossDetails(Month, Factor, IsActive, CreatedById, CreatedTime, TerminationValue, LeaseFinanceId)  
SELECT Month, Factor, 1, @UserId, @CreatedTime, TerminationValue, LF.InsertedId  
FROM stgLeaseStipLossDetail LSLD  
	 INNER JOIN stgLease L ON LSLD.LeaseId = L.Id  
	 INNER JOIN #CreatedLeaseFinanceIds AS LF ON l.Id = LF.Id;  
--LeaseSyndicationDetail LeaseSyndications  
--LeaseSyndicationFundingSource LeaseSyndicationFundingSources  
--LeaseSyndicationServicingDetail LeaseSyndicationServicingDetails  
CREATE TABLE #LeaseSyndications  
(LeaseSyndicationId BIGINT, LeaseFinanceId BIGINT, LeaseId BIGINT);  
MERGE INTO LeaseSyndications  
USING  
(  
 SELECT LSD.RetainedPercentage, LSD.FundedAmount_Amount, LSD.FundedAmount_Currency, 1 IsActive, LSD.R_RentalProceedsPayableCodeId, LSD.R_ProgressPaymentReimbursementCodeId, LSD.R_ScrapeReceivableCodeId, LSD.R_UpfrontSyndicationFeeCodeId, LSD.R_LoanPaydownGLTemplateId, LSD.FundingDate, LF.InsertedId LeaseFinanceId, L.Id LeaseId ,  LSD.RentalProceedsWithholdingTaxRate
 FROM stgLeaseSyndicationDetail LSD WITH (NOLOCK)  
   INNER JOIN stgLease L ON LSD.LeaseId = L.Id  
	  INNER JOIN #CreatedLeaseFinanceIds AS LF ON l.Id = LF.Id) AS S1  
ON 1 = 0  
WHEN NOT MATCHED  
	  THEN  
	  INSERT(Id, RetainedPercentage, FundedAmount_Amount, FundedAmount_Currency, IsActive, CreatedById, CreatedTime, RentalProceedsPayableCodeId, RentalProceedsWithholdingTaxRate, ProgressPaymentReimbursementCodeId, ScrapeReceivableCodeId, UpfrontSyndicationFeeCodeId, LoanPaydownGLTemplateId, FundingDate)  
	  VALUES(S1.LeaseFinanceId, S1.RetainedPercentage, S1.FundedAmount_Amount, S1.FundedAmount_Currency, S1.IsActive, @UserId, @CreatedTime, S1.R_RentalProceedsPayableCodeId, S1.RentalProceedsWithholdingTaxRate, S1.R_ProgressPaymentReimbursementCodeId, S1.R_ScrapeReceivableCodeId, S1.R_UpfrontSyndicationFeeCodeId, S1.R_LoanPaydownGLTemplateId, S1.FundingDate)  
OUTPUT INSERTED.Id LeaseSyndicationId, S1.LeaseFinanceId, S1.LeaseId  
	   INTO #LeaseSyndications;  
INSERT INTO LeaseSyndicationFundingSources(ParticipationPercentage, LessorGuaranteedResidualAmount_Amount, LessorGuaranteedResidualAmount_Currency, CashHoldbackAmount_Amount, CashHoldbackAmount_Currency, UpfrontSyndicationFee_Amount, UpfrontSyndicationFee_Currency, ScrapeFactor, IsActive, SalesTaxResponsibility, CreatedById, CreatedTime, FunderId, FunderRemitToId, FunderBillToId, FunderLocationId, LeaseSyndicationId)  
SELECT ParticipationPercentage, LessorGuaranteedResidualAmount_Amount, LessorGuaranteedResidualAmount_Currency, CashHoldbackAmount_Amount, CashHoldbackAmount_Currency, UpfrontSyndicationFee_Amount, UpfrontSyndicationFee_Currency, ScrapeFactor, 1, SalesTaxResponsibility, @UserId, @CreatedTime, R_FunderId, R_FunderRemitToId, R_FunderBillToId, R_FunderLocationId, LeaseSyndicationId  
FROM stgLeaseSyndicationFundingSource LSFS  
	 JOIN stgLeaseSyndicationDetail LSD ON LSFS.LeaseSyndicationDetailId = LSD.Id  
	 JOIN #LeaseSyndications LS ON LSD.LeaseId = LS.LeaseId;  
INSERT INTO LeaseSyndicationServicingDetails(EffectiveDate, IsServiced, IsCobrand, IsPerfectPay, IsCollected, IsPrivateLabel, PropertyTaxResponsibility, IsActive, CreatedById, CreatedTime, RemitToId, LeaseSyndicationId)  
SELECT L.CommencementDate, -- need to add effective date  
IsServiced, IsCobrand, IsPerfectPay, IsCollected, IsPrivateLabel, LSSD.PropertyTaxResponsibility, 1, @UserId, @CreatedTime, R_RemitToId, LeaseSyndicationId  
FROM stgLeaseSyndicationServicingDetail LSSD  
	 JOIN stgLeaseSyndicationDetail LSD ON LSSD.LeaseSyndicationDetailId = LSD.Id  
	 JOIN #LeaseSyndications LS ON LSD.LeaseId = LS.LeaseId  
	 JOIN stgLeaseFinanceDetail L ON L.Id = LS.LeaseId;  
DROP TABLE #LeaseSyndications;  
--LeaseThirdPartyRelationship CustomerThirdPartyRelationships, ContractThirdPartyRelationships  
CREATE TABLE #CustomerThirdPartyRelationships  
(CustomerThirdPartyRelationshipID BIGINT, ContractId BIGINT, LeaseId BIGINT);  
MERGE INTO CustomerThirdPartyRelationships  
USING  
(  
 SELECT RelationshipType, Description, 1 IsActive, Convert(date, getdate()) AS ActivationDate, 0 IsNewRelation, 0 IsNewAddress, 0 IsFromAssumption, 0 IsAssumptionApproved, LTPR.R_ThirdPartyId, LTPR.R_ThirdPartyAddressId, LTPR.R_ThirdPartyContactId, L.R_CustomerID, 0 LimitByDurationInMonths, 0 LimitByPercentage, 0 LimitByAmount_Amount, L.Currency LimitByAmount_Currency, '_' Scope, '_' Coverage, 'Customer' PersonalGuarantorCustomerOrContact, 0 IsNewContact, LF.ContractId ContractId, L.Id LeaseId  
 FROM stgLeaseThirdPartyRelationship LTPR WITH (NOLOCK)  
	  INNER JOIN stgLease L ON LTPR.LeaseId = L.Id  
	  INNER JOIN #CreatedLeaseFinanceIds AS LF ON l.Id = LF.Id
	  WHERE LTPR.Id IN 
	(
	  SELECT MIN(LTPR.Id) FROM stgLeaseThirdPartyRelationship LTPR
	  INNER JOIN stgLease L ON LTPR.LeaseId = L.Id  
	  GROUP BY L.R_CustomerId,LTPR.ThirdPartyNumber,LTPR.RelationshipType
	)   
) AS S1  
ON 1 = 0  
WHEN NOT MATCHED AND NOT EXISTS (SELECT * FROM CustomerThirdPartyRelationships WHERE CustomerThirdPartyRelationships.RelationshipType = S1.RelationshipType AND CustomerThirdPartyRelationships.CustomerId = S1.R_CustomerId AND (S1.R_ThirdPartyId IS NOT NULL
 AND CustomerThirdPartyRelationships.ThirdPartyId = S1.R_ThirdPartyId) OR (S1.R_ThirdPartyId IS NULL AND CustomerThirdPartyRelationships.ThirdPartyContactId = S1.R_ThirdPartyContactId))  
	  THEN  
	  INSERT(RelationshipType, Description, IsActive, ActivationDate, IsNewRelation, IsNewAddress, IsFromAssumption, IsAssumptionApproved, CreatedById, CreatedTime, ThirdPartyId, ThirdPartyAddressId, ThirdPartyContactId, CustomerId, LimitByDurationInMonths, LimitByPercentage, LimitByAmount_Amount, LimitByAmount_Currency, Scope, Coverage, PersonalGuarantorCustomerOrContact, IsNewContact)  
	  VALUES(S1.RelationshipType, S1.Description, S1.IsActive, Convert(date, getdate()), S1.IsNewRelation, S1.IsNewAddress, S1.IsFromAssumption, IsAssumptionApproved, @UserId, @CreatedTime, S1.R_ThirdPartyId, S1.R_ThirdPartyAddressId, S1.R_ThirdPartyContactId, S1.R_CustomerId, LimitByDurationInMonths, LimitByPercentage, LimitByAmount_Amount, LimitByAmount_Currency, Scope, Coverage, PersonalGuarantorCustomerOrContact, IsNewContact)  
OUTPUT INSERTED.Id CustomerThirdPartyRelationshipID, S1.ContractId, S1.LeaseId  
	   INTO #CustomerThirdPartyRelationships;  
INSERT INTO ContractThirdPartyRelationships(RelationshipPercentage, IsActive, ActivationDate, CreatedById, CreatedTime, ThirdPartyRelationshipId, ContractId)
SELECT DISTINCT RelationshipPercentage, 1, Convert(date, getdate()), @UserId, @CreatedTime, CTPR.Id, LF.ContractId
FROM stgLeaseThirdPartyRelationship LTPR
JOIN stgLease LL on LTPR.LeaseId = LL.Id
JOIN #CreatedLeaseFinanceIds AS LF ON LL.Id = LF.Id
JOIN CustomerThirdPartyRelationships CTPR ON LL.R_CustomerId = CTPR.CustomerId
AND CTPR.RelationshipType = LTPR.RelationshipType
AND CTPR.ThirdPartyId = LTPR.R_ThirdPartyId
DROP TABLE #CustomerThirdPartyRelationships;  
--EmployeesAssignedToCustomers, EmployeesAssignedToContracts  
CREATE TABLE #EmployeesAssignedToCustomers  
(EmployeesAssignedToCustomerID BIGINT,EmployeeID BIGINT, RoleFunctionId BIGINT, CustomerId BIGINT);  
INSERT INTO #EmployeesAssignedToCustomers (EmployeesAssignedToCustomerID,EmployeeID, RoleFunctionId, CustomerId)
SELECT DISTINCT eatp.Id, R_EmployeeId, R_RoleFunctionId, eatp.PartyId
FROM stgLease L WITH (NOLOCK)
INNER JOIN #CreatedLeaseFinanceIds AS LF ON l.Id = LF.Id
INNER JOIN stgEmployeesAssignedToLease eatl WITH (NOLOCK) ON L.Id = eatl.LeaseId  
INNER JOIN dbo.EmployeesAssignedToParties eatp ON l.R_CustomerId = eatp.PartyId AND eatp.RoleFunctionId = R_RoleFunctionId AND eatp.EmployeeId = R_EmployeeId
MERGE INTO EmployeesAssignedToParties  
USING
(  
 SELECT DISTINCT 1 IsActive, Convert(date, getdate()) AS ActivationDate,MAX(CONVERT(int,EAT.IsPrimary)) AS IsPrimary, 0 IsFromAssumption, 0 IsAssumptionApproved, R_RoleFunctionId, R_EmployeeId, L.R_CustomerID
 FROM stgEmployeesAssignedToLease EAT WITH (NOLOCK)  
	  INNER JOIN stgLease L WITH (NOLOCK) ON EAT.LeaseId = L.Id  
	  INNER JOIN #CreatedLeaseFinanceIds AS LF ON l.Id = LF.Id  
	  LEFT JOIN #EmployeesAssignedToCustomers eatc ON l.R_CustomerId = eatc.CustomerId AND EAT.R_EmployeeId = eatc.EmployeeId AND EAT.R_RoleFunctionId = eatc.RoleFunctionId 
	  WHERE eatc.EmployeesAssignedToCustomerID IS NULL
	  GROUP BY R_CustomerId,R_EmployeeId, R_RoleFunctionId) AS S1  
ON 1 = 0  
WHEN NOT MATCHED  
	  THEN  
	  INSERT(IsActive, ActivationDate,  IsPrimary, IsFromAssumption, IsAssumptionApproved, CreatedById, CreatedTime, RoleFunctionId, EmployeeId, PartyId, PartyRole)  
	  VALUES(S1.IsActive, S1.ActivationDate, 
	  Case When (Select Top 1 Id From EmployeesAssignedToParties Where RoleFunctionId = R_RoleFunctionId And PartyId = R_CustomerId And IsPrimary = 1) IS NOT NULL Then 0 Else S1.IsPrimary End, S1.IsFromAssumption, S1.IsAssumptionApproved, @UserId, @CreatedTime, S1.R_RoleFunctionId, S1.R_EmployeeId, S1.R_CustomerID, 'Customer')  
OUTPUT INSERTED.Id EmployeesAssignedToCustomerID,S1.R_EmployeeId EmployeeID, S1.R_RoleFunctionId RoleFunctionId, S1.R_CustomerID CustomerId  
	   INTO #EmployeesAssignedToCustomers;  
INSERT INTO EmployeesAssignedToContracts(IsActive, ActivationDate, IsPrimary, IsDisplayDashboard, CreatedById, CreatedTime, EmployeeAssignedToPartyId, ContractId,IsSignatory)  
SELECT DISTINCT 1, Convert(date, getdate()), IsPrimary, IsDisplayDashboard, @UserId, @CreatedTime, EC.EmployeesAssignedToCustomerID, LF.ContractId , EAL.IsSignatory
FROM stgEmployeesAssignedToLease EAL WITH (NOLOCK)
INNER JOIN stgLease L WITH (NOLOCK) ON EAL.LeaseId = L.Id   
INNER JOIN #EmployeesAssignedToCustomers EC ON L.R_CustomerId = EC.CustomerId AND EAL.R_EmployeeId = EC.EmployeeId AND EAL.R_RoleFunctionId = EC.RoleFunctionId
INNER JOIN #CreatedLeaseFinanceIds AS LF ON l.Id = LF.Id    
--LeasePaymentSchedule LeasePaymentSchedules  
INSERT INTO LeasePaymentSchedules(PaymentNumber, DueDate, StartDate, EndDate, Disbursement_Amount, Disbursement_Currency, Amount_Amount, Amount_Currency,VATAmount_Amount,VATAmount_Currency, PaymentType, BeginBalance_Amount, BeginBalance_Currency, EndBalance_Amount, EndBalance_Currency, Principal_Amount, Principal_Currency, Interest_Amount, Interest_Currency, PaymentStructure, Calculate, IsActive, ReceivableAdjustmentAmount_Amount, ReceivableAdjustmentAmount_Currency, ActualPayment_Amount, ActualPayment_Currency, IsRenewal, InterestAccrued_Amount, InterestAccrued_Currency, CreatedById, CreatedTime, LeaseFinanceDetailId, CustomerId, IsVATProjected,Fee_Amount,Fee_Currency,VATonFee_Amount,VATonFee_Currency)  
SELECT PaymentNumber, DueDate, StartDate, EndDate, 0.00, Currency, Amount_Amount, Currency, VATAmount_Amount, Currency, PaymentType, 0.00, Currency, 0.00, Currency, 0.00, Currency, 0, Currency, PaymentStructure, Calculate, 1, 0.00, Currency, 0.00, Currency, CAST (0 AS BIT), 0.00, Currency, @UserId, @CreatedTime, LF.InsertedId, L.R_CustomerId , 1, Fee_Amount, Fee_Currency, VATonFee_Amount, VATonFee_Currency
FROM stgLeasePaymentSchedule LPS  
	 JOIN stgLeaseFinanceDetail LFD ON LPS.LeaseFinanceDetailId = LFD.Id  
	 INNER JOIN stgLease L ON LFD.Id = L.Id  
	 INNER JOIN #CreatedLeaseFinanceIds AS LF ON l.Id = LF.Id; 
 --LeasecashFlow
INSERT INTO LeaseCashFlows(Date, Rent_Amount, Rent_Currency, Residual_Amount, Residual_Currency, Equity_Amount, Equity_Currency, Fees_Amount, Fees_Currency, PreTaxCashFlow_Amount, PreTaxCashFlow_Currency, Taxpaid_Amount, Taxpaid_Currency, PostTaxCashFlow_Amount, PostTaxCashFlow_Currency, CumulativePostTaxCashFlow_Amount, CumulativePostTaxCashFlow_Currency, PeriodicIncome_Amount, PeriodicIncome_Currency, PeriodicExpense_Amount, PeriodicExpense_Currency, FederalTaxPaid_Amount, FederalTaxPaid_Currency, StateTaxPaid_Amount, StateTaxPaid_Currency, SecurityDepositAmount_Amount, SecurityDepositAmount_Currency, LendingLoanTakedown_Amount, LendingLoanTakedown_Currency, CreatedById, CreatedTime, UpdatedById, UpdatedTime, LeaseFinanceId, IsActive)
SELECT Date, Rent_Amount, Rent_Currency, Residual_Amount, Residual_Currency, Equity_Amount, Equity_Currency, Fees_Amount, Fees_Currency, PreTaxCashFlow_Amount, PreTaxCashFlow_Currency, Taxpaid_Amount, Taxpaid_Currency, PostTaxCashFlow_Amount, PostTaxCashFlow_Currency, CumulativePostTaxCashFlow_Amount, CumulativePostTaxCashFlow_Currency, PeriodicIncome_Amount, PeriodicIncome_Currency, PeriodicExpense_Amount, PeriodicExpense_Currency, FederalTaxPaid_Amount, FederalTaxPaid_Currency, StateTaxPaid_Amount, StateTaxPaid_Currency, SecurityDepositAmount_Amount, SecurityDepositAmount_Currency, LendingLoanTakedown_Amount, LendingLoanTakedown_Currency, @UserId, @CreatedTime, NULL, NULL, LF.InsertedId, 1
FROM stgLeaseCashFlow LCF
	INNER JOIN stgLease L ON LCF.LeaseId = L.Id  
	INNER JOIN #CreatedLeaseFinanceIds AS LF ON l.Id = LF.Id; 
--LeaseYields
INSERT INTO LeaseYields(Yield, PreTaxWithoutFees, PreTaxWithFees, PostTaxWithoutFees, PostTaxWithFees, IsActive, CreatedById, CreatedTime, LeaseFinanceId) 
SELECT Yield,CAST(0.00 AS Decimal(10, 6)),CAST(0.00 AS Decimal(10, 6)),CAST(0.00 AS Decimal(10, 6)),CAST(0.00 AS Decimal(10, 6)), CAST(0 AS BIT), @UserId, @CreatedTime, #CreatedLeaseFinanceIds.InsertedId
FROM #LeaseYieldValues
CROSS JOIN #CreatedLeaseFinanceIds
----ContractQualifiedPromotions
----INSERT INTO ContractQualifiedPromotions(IsActive, CreatedById, CreatedTime, UpdatedById, UpdatedTime, VendorPromotionId, ContractId)
----SELECT 1, @UserId, @CreatedTime, NULL, NULL, R_VendorPromotionId, R_ContractId
----FROM stgLeaseQualifiedPromotion LQP
----	INNER JOIN stgLease L ON LQP.LeaseId = L.Id  
----	INNER JOIN #ProcessableLeaseTemp LT ON LT.Id = L.Id  
----	INNER JOIN #CreatedLeaseFinanceIds AS LF ON l.Id = LF.Id; 
--ContractBankAccountPaymentThresholds
SELECT 
	Distinct LeaseId = PLT.Id, BankAccountId = LAA.R_BankAccountId 
INTO #LeaseACHBankAccountDetails
FROM #ProcessableLeaseTemp PLT 
INNER JOIN stgLeaseACHAssignment LAA ON LAA.LeaseBillingId = PLT.Id 
INSERT INTO ContractBankAccountPaymentThresholds(PaymentThreshold, PaymentThresholdAmount_Amount, PaymentThresholdAmount_Currency, EmailId, IsActive, CreatedById, CreatedTime, UpdatedById, UpdatedTime, BankAccountId, ContractId)
SELECT ISNULL(PaymentThreshold, 0), ISNULL(PaymentThresholdAmount_Amount, 0.00), ISNULL(PaymentThresholdAmount_Currency, L.Currency), EmailId, 1, @UserId, @CreatedTime, NULL, NULL, LABAD.BankAccountId, LF.ContractId
FROM stgLease L 
	INNER JOIN #CreatedLeaseFinanceIds AS LF ON l.Id = LF.Id
	INNER JOIN #LeaseACHBankAccountDetails LABAD ON LABAD.LeaseId = L.Id
	LEFT JOIN stgLeaseBankAccountPaymentThreshold LBP ON LBP.LeaseId = L.Id AND LBP.R_BankAccountId = LABAD.BankAccountId
--ContractCollectionDetails
INSERT INTO dbo.ContractCollectionDetails
(ContractId,OneToThirtyDaysLate,ThirtyPlusDaysLate,SixtyPlusDaysLate,NinetyPlusDaysLate,OneHundredTwentyPlusDaysLate,LegacyZeroPlusDaysLate,LegacyThirtyPlusDaysLate,LegacySixtyPlusDaysLate,LegacyNinetyPlusDaysLate,LegacyOneHundredTwentyPlusDaysLate,TotalOneToThirtyDaysLate,TotalThirtyPlusDaysLate,TotalSixtyPlusDaysLate,TotalNinetyPlusDaysLate,TotalOneHundredTwentyPlusDaysLate,InterestDPD,RentOrPrincipalDPD,MaturityDPD,OverallDPD,CreatedById,CreatedTime,CalculateDeliquencyDetails)  
SELECT C.InsertedContractId, 0, 0, 0, 0, 0, lcd.TotalOneToThirtyDaysLate, lcd.TotalThirtyPlusDaysLate, lcd.TotalSixtyPlusDaysLate, lcd.TotalNinetyPlusDaysLate, lcd.TotalOneHundredTwentyPlusDaysLate, lcd.TotalOneToThirtyDaysLate, lcd.TotalThirtyPlusDaysLate, lcd.TotalSixtyPlusDaysLate, lcd.TotalNinetyPlusDaysLate, lcd.TotalOneHundredTwentyPlusDaysLate, 0, 0, 0, 0, @UserId,@CreatedTime,0
FROM 
stgLeaseCollectionDetail lcd
INNER JOIN stgLease lease on lcd.Id = lease.Id
INNER JOIN #CreatedContractIds C on C.Id = lease.Id
--ContractCollectionDetails
Update LeaseAssets Set FMV_Amount = CASE WHEN Contracts.AccountingStandard ='ASC840_IAS17' Then NBV_Amount 
										 WHEN LeaseAssets.FMV_Amount = 0 Then NBV_Amount
										 ELSE FMV_Amount
									END
From LeaseAssets WITH (NOLOCK) 
Inner Join #CreatedLeaseFinanceIds  WITH (NOLOCK) On #CreatedLeaseFinanceIds.InsertedId = LeaseAssets.LeaseFinanceId
Inner Join LeaseFinances  WITH (NOLOCK) On LeaseFinances.Id = #CreatedLeaseFinanceIds.InsertedId
Inner Join Contracts  WITH (NOLOCK) On Contracts.Id = LeaseFinances.ContractId
UPDATE LeaseFinanceDetails Set FMV_Amount = LeaseWithFMV.FMV_Amount
From LeaseFinanceDetails As LFD WITH (NOLOCK) 
INNER JOIN (
				SELECT SUM(FMV_Amount) As FMV_Amount, LF.InsertedId As LeaseFinanceId
				FROM #CreatedLeaseFinanceIds LF
				INNER JOIN LeaseAssets LA  WITH (NOLOCK) On LA.LeaseFinanceId = LF.InsertedId
				GROUP BY LF.InsertedId
			) As LeaseWithFMV ON LeaseWithFMV.LeaseFinanceId = LFD.Id  

INSERT INTO #CommencedLeaseIds(Id)  
SELECT Id LeaseFinanceId   
FROM #CreatedLeaseFinanceIds  
  MERGE stgProcessingLog AS ProcessingLog
			USING (SELECT Id FROM #CommencedLeaseIds				
				  ) AS ProcessedCustomers
			ON (ProcessingLog.StagingRootEntityId = ProcessedCustomers.Id AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
			WHEN NOT MATCHED THEN
			INSERT
				(
					StagingRootEntityId
				   ,CreatedById
				   ,CreatedTime
				   ,ModuleIterationStatusId
				)
			VALUES
				(
					ProcessedCustomers.Id
				   ,@UserId
				   ,@CreatedTime
				   ,@ModuleIterationStatusId
				)
				OUTPUT  Inserted.Id INTO #CreatedProcessingLogs;
			INSERT INTO stgProcessingLogDetail
			(
				Message
			   ,Type
			   ,CreatedById
			   ,CreatedTime	
			   ,ProcessingLogId
			)
			SELECT
				'Successful'
			   ,'Information'
			   ,@UserId
			   ,@CreatedTime
			   ,Id
			FROM
				#CreatedProcessingLogs

INSERT INTO #RequiredUpdation (LeaseId,R_ContractId,R_LeaseFinanceId) SELECT Id,ContractId,InsertedId FROM #CreatedLeaseFinanceIds  

SET @SkipCount = @SkipCount  + @TakeCount;

   MERGE stgProcessingLog AS ProcessingLog  
    USING (SELECT  
	DISTINCT EntityId StagingRootEntityId  
	  FROM  
	#Params WITH (NOLOCK)  
	 ) AS ErrorLeases  
  ON (ProcessingLog.StagingRootEntityId = ErrorLeases.StagingRootEntityId AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId) 
  WHEN NOT MATCHED THEN  
  INSERT  
   (  
	StagingRootEntityId  
	  ,CreatedById  
	  ,CreatedTime  
	  ,ModuleIterationStatusId  
   )  
  VALUES  
   (  
	  ErrorLeases.StagingRootEntityId  
	  ,@UserId  
	  ,@CreatedTime  
	  ,@ModuleIterationStatusId  
   )  
  OUTPUT $action, Inserted.Id,ErrorLeases.StagingRootEntityId INTO #FailedProcessingLogs;   
  INSERT INTO   
   stgProcessingLogDetail  
   (  
	Message  
	  ,Type  
	  ,CreatedById  
	  ,CreatedTime   
	  ,ProcessingLogId  
   )  
  SELECT  
	  #Params.CSV  
	 ,'Error'  
	 ,@UserId  
	 ,@CreatedTime  
	 ,#FailedProcessingLogs.Id  
  FROM  
   #Params  
  INNER JOIN #FailedProcessingLogs  
	ON #Params.EntityId = #FailedProcessingLogs.LeaseId  
UPDATE stgLease  
  SET IsFailed = 1  
	   WHERE Id IN(  
				   SELECT p.EntityId  
				   FROM #Params AS p);   
 SET @FailedRecords = @FailedRecords + ISNULL((SELECT COUNT(DISTINCT EntityId) FROM #Params),0); 
 DELETE #FailedProcessingLogs
 DELETE #Params

COMMIT TRANSACTION
END TRY
BEGIN CATCH
	SET @SkipCount = @SkipCount  + @TakeCount;
	DECLARE @ErrorMessage Nvarchar(max);
	DECLARE @ErrorLine Nvarchar(max);
	DECLARE @ErrorSeverity INT;
	DECLARE @ErrorState INT;
	DECLARE @ErrorLogs ErrorMessageList;
	DECLARE @ModuleName Nvarchar(max) = 'MigrateLease'
	Insert into @ErrorLogs(StagingRootEntityId, ModuleIterationStatusId, Message,Type) VALUES (0,@ModuleIterationStatusId,ERROR_MESSAGE(),'Error')
	SELECT  @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE(),@ErrorLine=ERROR_LINE(),@ErrorMessage=ERROR_MESSAGE()
	IF (XACT_STATE()) = -1  
	BEGIN  
		ROLLBACK TRANSACTION;
		EXEC [dbo].[ExceptionLog] @ErrorLogs,@ErrorLine,@UserId,@CreatedTime,@ModuleName
		SET @FailedRecords = @FailedRecords+@BatchCount;
	END;  
	ELSE IF (XACT_STATE()) = 1  
	BEGIN
		COMMIT TRANSACTION;
		RAISERROR (@ErrorMessage,@ErrorSeverity, @ErrorState);     
	END;  
	ELSE
	BEGIN
		EXEC [dbo].[ExceptionLog] @ErrorLogs,@ErrorLine,@UserId,@CreatedTime,@ModuleName
        SET @FailedRecords = @FailedRecords+@BatchCount;
	END;
END CATCH
DROP TABLE IF EXISTS #EmployeesAssignedToCustomers  
DROP TABLE IF EXISTS #LeaseLateFee  
DROP TABLE IF EXISTS #BlendedItem  
DROP TABLE IF EXISTS #InterestRateDetail  
DROP TABLE IF EXISTS #LeaseTable  
DROP TABLE IF EXISTS #ProcessableLeaseSyndicationDetailIds;  
DROP TABLE IF EXISTS #ProcessableLeaseTemp;  
DROP TABLE IF EXISTS #CreatedContractIds;  
DROP TABLE IF EXISTS #InsertedTaxExemptRuleIds;  
DROP TABLE IF EXISTS #InsertedContractOriginationIds;  
DROP TABLE IF EXISTS #InsertedContractOriginationServicingDetailIds;  
DROP TABLE IF EXISTS #CreatedLeaseFinanceIds;  
DROP TABLE IF EXISTS #LeaseACHBankAccountDetails;
DROP TABLE IF EXISTS #CreatedProcessingLogs
DROP TABLE IF EXISTS #AdditionalCharge
DROP TABLE IF EXISTS #CreatedLeaseAssetIds;
DROP TABLE IF EXISTS #LeaseFinanceCustomerTransitDays;
DROP TABLE IF EXISTS #LeaseAccountingStandard
DROP TABLE IF EXISTS #AssetsWithIsLeaseComponentChanged
DROP TABLE IF EXISTS #stgLeaseAssetSKU
END   
UPDATE stgLease  
SET stgLease.IsMigrated = 0  
WHERE Id IN (SELECT Id FROM #CommencedLeaseIds clfi)    

UPDATE stgLease SET R_ContractId = RU.R_ContractId, R_LeaseFinanceId = RU.R_LeaseFinanceId FROM #RequiredUpdation RU  WHERE stgLease.Id = RU.LeaseId;  
UPDATE stgLeaseFinanceDetail SET R_LeaseFinanceId = RU.R_LeaseFinanceId FROM #RequiredUpdation RU  WHERE stgLeaseFinanceDetail.Id = RU.LeaseId;

DROP TABLE #Params;  
DROP TABLE #CommencedLeaseIds;
DROP TABLE #PartyBankAccountDetails
DROP TABLE #GlTemplateTemp;
DROP TABLE #LeaseYieldValues
DROP TABLE #PortfolioParameters
DROP TABLE #FailedProcessingLogs; 
DROP TABLE #ReceivableCodeTemp; 
DROP TABLE #RequiredUpdation;
SET NOCOUNT OFF
SET XACT_ABORT OFF
END 

GO

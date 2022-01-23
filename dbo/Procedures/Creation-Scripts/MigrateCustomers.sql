SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[MigrateCustomers]
(
	@UserId BIGINT ,
	@ModuleIterationStatusId BIGINT,
	@CreatedTime  DATETIMEOFFSET,
	@ProcessedRecords BIGINT OUTPUT,
	@FailedRecords BIGINT OUTPUT
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
SET XACT_ABORT ON
DECLARE @Number BIGINT = 0
DECLARE @SQL Nvarchar(max) =''
DECLARE @Module VARCHAR(50) = NULL
SET @Module = (SELECT StgModule.Name FROM StgModule INNER JOIN StgModuleIterationStatus ON StgModule.Id = StgModuleIterationStatus.ModuleId WHERE StgModuleIterationStatus.Id = @ModuleIterationStatusId)
EXEC ResetStagingTempFields @Module , NULL
CREATE TABLE #ErrorLogs 
(
	Id BIGINT NOT NULL IDENTITY PRIMARY KEY,
	StagingRootEntityId BIGINT,
	Result NVARCHAR(10),
	Message NVARCHAR(MAX)
);	
CREATE TABLE #FailedProcessingLogs 
(
			[Id] BIGINT NOT NULL,
			[SecurityDepositId] BIGINT NOT NULL
);	
DECLARE @Counter INT = 0;
	DECLARE @TakeCount INT = 50000; 
	DECLARE @SkipCount INT = 0;
	DECLARE @MaxErrorStagingRootEntityId INT = 0;
	DECLARE @BatchCount INT = 0;
	SET @FailedRecords = 0;
	SET @ProcessedRecords = 0;
	DECLARE @TotalRecordsCount INT = (SELECT COUNT(Id) FROM stgCustomer WHERE IsMigrated = 0);
	SET @MaxErrorStagingRootEntityId= 0;
	SET @SkipCount = 0;
UPDATE stgCustomer Set R_StateofIncorporationId = States.Id
FROM stgCustomer C
INNER JOIN States ON UPPER(States.ShortName) = UPPER(C.StateOfIncorporation)
WHERE C.IsMigrated = 0 AND c.StateOfIncorporation Is NOT NULL 
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Invalid State of Incorporation for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
WHERE C.IsMigrated = 0 AND c.StateOfIncorporation Is NOT NULL AND C.R_StateofIncorporationId Is NULL 
UPDATE stgCustomer Set R_JurisdictionOfSovereignCountryId = Countries.Id
FROM stgCustomer C
INNER JOIN Countries ON Countries.ShortName = C.ISOCountryCodeForJurisdictionOfSovereign
WHERE C.IsMigrated = 0 AND c.ISOCountryCodeForJurisdictionOfSovereign Is NOT NULL 
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Invalid CountryCode for JurisdictionOfSovereign for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
WHERE C.IsMigrated = 0 AND c.StateOfIncorporation Is NOT NULL AND C.R_StateofIncorporationId Is NULL
UPDATE stgCustomer Set R_BusinessTypeId = BusinessTypes.Id
FROM stgCustomer C
INNER JOIN dbo.BusinessTypes ON C.BusinessType = BusinessTypes.Name AND BusinessTypes.IsActive=1
WHERE C.IsMigrated = 0 AND C.BusinessType Is NOT NULL 
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Invalid BusinessType for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
WHERE C.IsMigrated = 0 AND C.BusinessType Is NOT NULL AND C.R_BusinessTypeId Is NULL

INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Please Enter Email in an Proper Format for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
WHERE C.IsMigrated = 0 AND C.IsLimitedDisclosureParty =1 AND C.Email Is NOT NULL AND C.Email NOT LIKE '%_@__%.__%'

INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Please Enter BusinessType for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
WHERE C.IsMigrated = 0 AND (C.IsCorporate=1 AND C.IsSoleProprietor=0) AND C.R_BusinessTypeId Is NULL

INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Please Enter WayOfRepresentation for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
WHERE C.IsMigrated = 0 AND (C.IsCorporate=1 AND C.IsSoleProprietor=0) AND C.WayOfRepresentation Is NULL

INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Please Enter Representative1 for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
WHERE C.IsMigrated = 0 AND (C.IsCorporate=1 AND C.IsSoleProprietor=0) AND C.Representative1 Is NULL

INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Please Enter Representative2 for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
WHERE C.IsMigrated = 0 AND (C.IsCorporate=1 AND C.IsSoleProprietor=0) AND C.Representative2 Is NULL

INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Please Enter Representative3 for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
WHERE C.IsMigrated = 0 AND (C.IsCorporate=1 AND C.IsSoleProprietor=0) AND C.Representative3 Is NULL


INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Please Enter EGNNumber for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
WHERE C.IsMigrated = 0 AND (C.IsCorporate=0) AND C.EGNNumber Is NULL

INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Please Enter EGNNumber for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
WHERE C.IsMigrated = 0 AND (C.IsCorporate=1 AND C.IsSoleProprietor=1) AND C.EGNNumber Is NULL


INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Please Enter EGN Number for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
WHERE C.IsMigrated = 0 AND (C.IsCorporate=1 AND C.IsSoleProprietor=0) AND C.EGNNumber Is NULL


UPDATE stgCustomer Set R_PreACHNotificationEmailTemplateId = preACHNotificationEmailTemplate.Id
FROM stgCustomer C
LEFT JOIN dbo.EmailTemplates preACHNotificationEmailTemplate ON C.PreACHNotificationEmailTemplate = preACHNotificationEmailTemplate.Name AND preACHNotificationEmailTemplate.IsActive=1
LEFT JOIN dbo.EmailTemplateTypes emailTemplateType ON preACHNotificationEmailTemplate.EmailTemplateTypeId=emailTemplateType.Id AND emailTemplateType.Name='ACHPreNotification'
WHERE C.IsMigrated = 0 AND C.IsPreACHNotification = 1 AND C.PreACHNotificationEmailTemplate Is NOT NULL
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Invalid PreACHNotificationEmailTemplate for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
WHERE C.IsMigrated = 0 AND C.IsPreACHNotification = 1 AND C.PreACHNotificationEmailTemplate Is NOT NULL AND C.R_PreACHNotificationEmailTemplateId Is NULL

UPDATE stgCustomer Set R_PostACHNotificationEmailTemplateId = postACHNotificationEmailTemplate.Id
FROM stgCustomer C
LEFT JOIN dbo.EmailTemplates postACHNotificationEmailTemplate ON C.PostACHNotificationEmailTemplate = postACHNotificationEmailTemplate.Name AND postACHNotificationEmailTemplate.IsActive=1
LEFT JOIN dbo.EmailTemplateTypes emailTemplateType ON postACHNotificationEmailTemplate.EmailTemplateTypeId=emailTemplateType.Id AND emailTemplateType.Name='ACHPostNotification'
WHERE C.IsMigrated = 0 AND C.IsPostACHNotification = 1 AND C.PostACHNotificationEmailTemplate Is NOT NULL
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Invalid PostACHNotificationEmailTemplate for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
WHERE C.IsMigrated = 0 AND C.IsPostACHNotification = 1 AND C.PostACHNotificationEmailTemplate Is NOT NULL AND C.R_PostACHNotificationEmailTemplateId Is NULL

UPDATE stgCustomer Set R_ReturnACHNotificationEmailTemplateId = returnACHNotificationEmailTemplate.Id
FROM stgCustomer C
LEFT JOIN dbo.EmailTemplates returnACHNotificationEmailTemplate ON C.ReturnACHNotificationEmailTemplate = returnACHNotificationEmailTemplate.Name AND returnACHNotificationEmailTemplate.IsActive=1
LEFT JOIN dbo.EmailTemplateTypes emailTemplateType ON returnACHNotificationEmailTemplate.EmailTemplateTypeId=emailTemplateType.Id AND emailTemplateType.Name='ACHReturnNotification'
WHERE C.IsMigrated = 0 AND C.IsReturnACHNotification = 1 AND C.ReturnACHNotificationEmailTemplate Is NOT NULL
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Invalid ReturnACHNotificationEmailTemplate for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
WHERE C.IsMigrated = 0 AND C.IsReturnACHNotification = 1 AND C.ReturnACHNotificationEmailTemplate Is NOT NULL AND C.R_ReturnACHNotificationEmailTemplateId Is NULL

UPDATE stgCustomer Set R_MedicalSpecialityId = MedicalSpecialities.Id
FROM stgCustomer C
INNER JOIN MedicalSpecialities ON C.MedicalSpecialityDescription = MedicalSpecialities.Description AND MedicalSpecialities.IsActive=1
WHERE C.IsMigrated = 0 AND C.MedicalSpecialityDescription Is NOT NULL 
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Invalid Medical Speciality Description for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
WHERE C.IsMigrated = 0 AND C.MedicalSpecialityDescription Is NOT NULL AND C.R_MedicalSpecialityId Is NULL
UPDATE stgCustomer Set R_LegalFormationTypeConfigId = LegalFormationTypeConfigs.Id
FROM stgCustomer C
INNER JOIN LegalFormationTypeConfigs ON C.LegalFormationTypeCode = LegalFormationTypeConfigs.LegalFormationTypeCode 
WHERE C.IsMigrated = 0 AND C.LegalFormationTypeCode Is NOT NULL
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Invalid LegalFormationTypeCode for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
WHERE C.IsMigrated = 0 AND C.R_LegalFormationTypeConfigId Is NULL AND (C.LegalFormationTypeCode Is NOT NULL)
UPDATE stgCustomer Set R_CustomerApprovedExchangesConfigId = approvedExchange.Id
FROM stgCustomer C
INNER JOIN dbo.CustomerApprovedExchangesConfigs approvedExchange ON C.ApprovedExchange = approvedExchange.Name 
	AND approvedExchange.IsActive=1
WHERE C.IsMigrated = 0 AND C.ApprovedExchange Is NOT NULL 
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Invalid ApprovedExchange Config Name for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
WHERE C.IsMigrated = 0 AND C.ApprovedExchange Is NOT NULL AND C.R_CustomerApprovedExchangesConfigId Is NULL
UPDATE stgCustomer Set R_CustomerApprovedRegulatorConfigId = ApprovedRegulator.Id
FROM stgCustomer C
INNER JOIN dbo.CustomerApprovedRegulatorsConfigs approvedRegulator ON C.ApprovedRegulator=approvedRegulator.Name AND approvedRegulator.IsActive=1
WHERE C.IsMigrated = 0 AND C.ApprovedRegulator Is NOT NULL 
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Invalid ApprovedRegulator Config Name for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
WHERE C.IsMigrated = 0 AND C.ApprovedRegulator Is NOT NULL AND C.R_CustomerApprovedRegulatorConfigId Is NULL
UPDATE stgCustomer Set R_CountryId = Countries.Id
FROM stgCustomer C
INNER JOIN Countries ON C.Country = Countries.ShortName AND Countries.IsActive=1
WHERE C.IsMigrated = 0 AND C.Country Is NOT NULL 
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Invalid Country for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
WHERE C.IsMigrated = 0 AND C.Country Is NOT NULL AND C.R_CountryId Is NULL
UPDATE stgCustomer Set R_ReceiptHierarchyTemplateId = ReceiptHierarchyTemplates.Id
FROM stgCustomer C
INNER JOIN ReceiptHierarchyTemplates ON C.ReceiptHierarchyTemplateName = ReceiptHierarchyTemplates.Name AND ReceiptHierarchyTemplates.IsActive=1
WHERE C.IsMigrated = 0 AND C.ReceiptHierarchyTemplateName Is NOT NULL 
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Invalid ReceiptHierarchyTemplate Name for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
WHERE C.IsMigrated = 0 AND C.ReceiptHierarchyTemplateName Is NOT NULL AND C.R_ReceiptHierarchyTemplateId Is NULL
UPDATE stgCustomer Set R_CustomerClassId = customerClass.Id
FROM stgCustomer C
INNER JOIN dbo.CustomerClasses customerClass ON C.CustomerClass = customerClass.Class
WHERE C.IsMigrated = 0 AND C.CustomerClass Is NOT NULL 
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Invalid CustomerClass for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
WHERE C.IsMigrated = 0 AND C.CustomerClass Is NOT NULL AND C.R_CustomerClassId Is NULL
UPDATE stgCustomer Set R_NAICSCodeId = code.Id,R_SICCodeId = scode.Id
FROM stgCustomer C
INNER JOIN dbo.BusinessTypeNAICSCodes code ON C.NAICSCode = code.NAICSCode AND code.IsActive=1
INNER JOIN dbo.BusinessTypesSICsCodes scode on  C.SICCode = scode.Name and code.BusinessTypesSICsCodeId = scode.Id and scode.IsActive = 1
WHERE C.IsMigrated = 0 AND C.NAICSCode Is NOT NULL AND C.SICCode Is NOT NULL

--update R_SICCodeId where naicscode is null and siccode is not null
UPDATE stgCustomer Set R_SICCodeId = scode.Id
FROM stgCustomer C
INNER JOIN dbo.BusinessTypesSICsCodes scode on  C.SICCode = scode.Name  and scode.IsActive = 1
WHERE C.IsMigrated = 0 AND C.NAICSCode Is NULL AND C.SICCode Is NOT NULL

--update R_NAICSCodeId = code.Id and R_SICCodeId = scode.Id where single sic name is associated with single naics code
UPDATE stgCustomer Set R_NAICSCodeId = code.Id,R_SICCodeId = scode.Id
FROM stgCustomer C
INNER JOIN dbo.BusinessTypeNAICSCodes code ON C.NAICSCode = code.NAICSCode AND code.IsActive=1
INNER JOIN dbo.BusinessTypesSICsCodes scode on   code.BusinessTypesSICsCodeId = scode.Id and scode.IsActive = 1
WHERE C.IsMigrated = 0 AND C.NAICSCode Is NOT NULL AND C.SICCode Is  NULL and  C.NAICSCode  IN  (SELECT  N.NAICSCode FROM BusinessTypeNAICSCodes N
INNER JOIN BusinessTypesSICsCodes S
ON S.Id = N.BusinessTypesSICsCodeId
GROUP BY N.NAICSCode
HAVING COUNT(*) = 1)

INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Invalid SICCode for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
WHERE C.IsMigrated = 0 AND C.R_SICCodeId Is NULL AND C.SICCode IS NOT NULL
INSERT INTO #ErrorLogs
SELECT
 C.Id
 ,'Error'
 ,('Invalid NAICSCode or multiple SICCode associated with NAICSCode for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
WHERE C.IsMigrated = 0 AND C.R_NAICSCodeId Is NULL AND C.NAICSCode IS NOT NULL

--insert error msg for sic id is not associated with naics id
INSERT INTO #ErrorLogs
SELECT
 C.Id
 ,'Error'
 ,('Invalid combination of SICCode and NAICSCode for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
WHERE C.IsMigrated = 0 AND C.R_SICCodeId Is NULL AND C.SICCode IS NOT NULL  and C.R_NAICSCodeId Is NULL AND C.NAICSCode IS NOT NULL


UPDATE stgCustomer Set R_LanguageConfigId = L.Id
FROM stgCustomer C
INNER JOIN dbo.LanguageConfigs L ON C.Language = L.Name AND L.IsActive=1
WHERE C.IsMigrated = 0 AND C.Language Is NOT NULL 
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Invalid Language for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
WHERE C.IsMigrated = 0 AND C.Language Is NOT NULL AND C.R_LanguageConfigId Is NULL
UPDATE stgCustomer Set R_StateTaxExemptionReasonId = TX.Id
FROM stgCustomer C
INNER JOIN dbo.TaxExemptionReasonConfigs TX ON TX.Reason=C.StateTaxExemptionReason AND TX.EntityType='Customer'
WHERE C.IsMigrated = 0 AND C.IsStateTaxExempt=1 AND C.StateTaxExemptionReason Is NOT NULL 
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Invalid StateTaxExemptionReason for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
WHERE C.IsMigrated = 0 AND C.IsStateTaxExempt=1 AND C.StateTaxExemptionReason Is NOT NULL AND C.R_StateTaxExemptionReasonId Is NULL
UPDATE stgCustomer Set R_CountryTaxExemptionReasonId = TX.Id
FROM stgCustomer C
INNER JOIN dbo.TaxExemptionReasonConfigs TX ON TX.Reason=C.CountryTaxExemptionReason AND TX.EntityType='Customer'
WHERE C.IsMigrated = 0 AND C.IsCountryTaxExempt=1 AND C.CountryTaxExemptionReason Is NOT NULL 
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Invalid CountryTaxExemptionReason for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
WHERE C.IsMigrated = 0 AND C.IsCountryTaxExempt=1 AND C.CountryTaxExemptionReason Is NOT NULL AND C.R_CountryTaxExemptionReasonId Is NULL
UPDATE stgCustomer Set R_CIPDocumentSourceId = CIP.Id
FROM stgCustomer C
INNER JOIN dbo.CIPDocumentSourceConfigs CIP ON CIP.Name = C.CIPDocumentSourceName 
WHERE C.IsMigrated = 0 AND C.CIPDocumentSourceName IS NOT NULL 
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Invalid CIPDocumentSourceName for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
WHERE C.IsMigrated = 0 AND C.R_CIPDocumentSourceId Is NULL AND C.CIPDocumentSourceName IS NOT NULL;
UPDATE stgCustomer Set R_CollectionStatusId = CS.Id
FROM stgCustomer C
INNER JOIN dbo.CollectionStatus CS ON CS.Name = C.CollectionStatus
WHERE C.IsMigrated = 0 AND C.CollectionStatus IS NOT NULL AND CS.IsActive = 1
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Invalid Collection Status for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
WHERE C.IsMigrated = 0 AND C.R_CollectionStatusId Is NULL AND C.CollectionStatus IS NOT NULL  
UPDATE stgCustomer Set R_PortfolioId = Portfolios.Id
FROM stgCustomer customer
INNER JOIN Portfolios ON Portfolios.Name = customer.PortfolioName AND Portfolios.IsActive = 1
WHERE customer.IsMigrated = 0 ;
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Invalid Portfolio Name for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
WHERE C.IsMigrated = 0 AND R_PortfolioId IS NULL
UPDATE stgCustomer SET stgCustomer.R_LateFeeTemplateId = lft.Id  
FROM stgCustomer customer
INNER JOIN dbo.LateFeeTemplates lft ON Customer.LateFeeTemplate = lft.Name AND lft.IsActive = 1
WHERE customer.IsMigrated = 0 AND LTRIM(RTRIM(customer.LateFeeTemplate)) <> '' ;
INSERT INTO #ErrorLogs  
SELECT 
    C.Id
	,'Error'
	,('LateFeeTemplate provided is not valid for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C 
WHERE C.IsMigrated = 0 AND C.R_LateFeeTemplateId IS NULL AND LTRIM(RTRIM(C.LateFeeTemplate)) <> '' ;
----Customer Address
UPDATE stgCustomerAddress Set R_CountryId = Countries.Id
FROM stgCustomerAddress CA
INNER JOIN stgCustomer C ON C.Id = CA.CustomerId
INNER JOIN dbo.Countries ON CA.Country = Countries.ShortName AND Countries.IsActive = 1
WHERE C.IsMigrated = 0 AND CA.Country Is NOT NULL 
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Invalid Country for Customer Address Id {'+CONVERT(NVARCHAR(MAX),CA.Id)+'} with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
INNER JOIN stgCustomerAddress CA ON CA.CustomerId = C.Id
WHERE C.IsMigrated = 0 AND CA.Country Is NOT NULL AND CA.R_CountryId Is NULL
UPDATE stgCustomerAddress Set R_HomeCountryId = Countries.Id
FROM stgCustomerAddress CA
INNER JOIN stgCustomer C ON C.Id = CA.CustomerId
INNER JOIN dbo.Countries ON CA.HomeCountry = Countries.ShortName AND Countries.IsActive = 1
WHERE C.IsMigrated = 0 AND CA.HomeCountry Is NOT NULL 
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Invalid HomeCountry for Customer Address Id {'+CONVERT(NVARCHAR(MAX),CA.Id)+'} with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
INNER JOIN stgCustomerAddress CA ON CA.CustomerId = C.Id
WHERE C.IsMigrated = 0 AND CA.HomeCountry Is NOT NULL AND CA.R_HomeCountryId Is NULL
UPDATE stgCustomerAddress Set R_StateId = States.Id
FROM stgCustomerAddress CA
INNER JOIN stgCustomer C ON C.Id = CA.CustomerId
INNER JOIN dbo.States ON CA.State = States.ShortName AND CA.R_CountryId = States.CountryId AND States.IsActive = 1  
WHERE C.IsMigrated = 0 AND CA.State Is NOT NULL
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Invalid State for Customer Address Id {'+CONVERT(NVARCHAR(MAX),CA.Id)+'} with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
INNER JOIN stgCustomerAddress CA ON CA.CustomerId = C.Id
WHERE C.IsMigrated = 0 AND CA.State Is NOT NULL AND CA.R_StateId Is NULL
UPDATE stgCustomerAddress Set R_HomeStateId = States.Id
FROM stgCustomerAddress CA
INNER JOIN stgCustomer C ON C.Id = CA.CustomerId
INNER JOIN dbo.States ON CA.HomeState = States.ShortName AND CA.R_HomeCountryId = States.CountryId AND States.IsActive = 1
WHERE C.IsMigrated = 0 AND CA.HomeState Is NOT NULL 
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Invalid HomeState for Customer Address Id {'+CONVERT(NVARCHAR(MAX),CA.Id)+'} with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
INNER JOIN stgCustomerAddress CA ON CA.CustomerId = C.Id
WHERE C.IsMigrated = 0 AND CA.HomeState Is NOT NULL AND CA.R_HomeStateId Is NULL

----Customer Tax Registration Details
Update stgCustomerTaxRegistrationDetail Set R_CountryId = Countries.Id
FROM stgCustomerTaxRegistrationDetail CTRD
INNER JOIN stgCustomer C ON C.Id = CTRD.CustomerId
INNER JOIN dbo.Countries ON CTRD.CountryName = Countries.ShortName AND Countries.IsActive = 1
WHERE C.IsMigrated = 0 AND CTRD.CountryName Is NOT NULL
INSERT INTO #ErrorLogs
select
	C.Id,'Error',
	('Invalid Country ShortName '+ISNULL(CTRD.CountryName,'NULL'))
FROM stgCustomer C
INNER JOIN stgCustomerTaxRegistrationDetail CTRD on CTRD.CustomerId = C.Id
WHERE CTRD.R_CountryId is null

Update stgCustomerTaxRegistrationDetail Set R_StateId = States.Id
FROM stgCustomerTaxRegistrationDetail CTRD
INNER JOIN stgCustomer C ON C.Id = CTRD.CustomerId
INNER JOIN dbo.States ON CTRD.StateName = States.ShortName AND States.IsActive = 1
WHERE C.IsMigrated = 0 AND CTRD.StateName Is NOT NULL 
INSERT INTO #ErrorLogs
select
	C.Id,'Error',
	('Invalid State ShortName '+ISNULL(CTRD.StateName,'NULL'))
	FROM stgCustomer C
INNER JOIN stgCustomerTaxRegistrationDetail CTRD on CTRD.CustomerId = C.Id
WHERE CTRD.R_StateId is null

----CustomerBankAccount
UPDATE stgCustomerBankAccount Set R_BankBranchId = BankBranches.Id
FROM stgCustomerBankAccount CBA
INNER JOIN stgCustomer C ON C.Id = CBA.CustomerId
INNER JOIN BankBranches ON UPPER(CBA.BankBranch) = UPPER(BankBranches.Name)
WHERE C.IsMigrated = 0 AND CBA.BankBranch Is NOT NULL 
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Invalid BankBranch for CustomerBankAccount Id {'+CONVERT(NVARCHAR(MAX),CBA.Id)+'} with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
INNER JOIN stgCustomerBankAccount CBA ON CBA.CustomerId = C.Id
WHERE C.IsMigrated = 0 AND CBA.BankBranch Is NOT NULL AND CBA.R_BankBranchId Is NULL
UPDATE stgCustomerBankAccount Set R_CurrencyId = Currencies.Id
FROM stgCustomerBankAccount CBA
INNER JOIN stgCustomer C ON C.Id = CBA.CustomerId
INNER JOIN CurrencyCodes ON CurrencyCodes.ISO = CBA.CurrencyCode
INNER JOIN dbo.Currencies ON CurrencyCodes.Id = Currencies.CurrencyCodeId
WHERE C.IsMigrated = 0 AND CBA.CurrencyCode Is NOT NULL 
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Invalid Currency for CustomerBankAccount Id {'+CONVERT(NVARCHAR(MAX),CBA.Id)+'} with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
INNER JOIN stgCustomerBankAccount CBA ON CBA.CustomerId = C.Id
WHERE C.IsMigrated = 0 AND CBA.CurrencyCode Is NOT NULL AND CBA.R_CurrencyId Is NULL
UPDATE stgCustomerContact Set R_TimeZoneId = TimeZones.Id
FROM stgCustomerContact CC
INNER JOIN stgCustomer C ON C.Id = CC.CustomerId
INNER JOIN TimeZones ON UPPER(TimeZones.Name) = UPPER(CC.TimeZone)
WHERE C.IsMigrated = 0 AND CC.TimeZone Is NOT NULL 
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Invalid TimeZone for Contact with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+' and ContactUniqueIdentifier '+ ISNULL(CC.UniqueIdentifier,'NULL') +'}')
FROM stgCustomer C
JOIN stgCustomerContact CC ON C.Id = CC.CustomerId
WHERE C.IsMigrated = 0 AND CC.TimeZone Is NOT NULL AND CC.R_TimeZoneId Is NULL 
--Validate Mandatory Account Number Field based on CountryCurrencyRelationships
INSERT INTO #ErrorLogs
SELECT C.Id
		, 'Error'
		,('Please enter Account Number for CustomerBankAccount Id {'+CONVERT(NVARCHAR(MAX),CBA.Id)+'} with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
JOIN stgCustomerBankAccount CBA ON CBA.CustomerId = C.Id
JOIN BankBranches BB ON CBA.R_BankBranchId = BB.Id
LEFT JOIN CountryCurrencyRelationships CCR ON BB.CountryId = CCR.CountryId AND CBA.R_CurrencyId = CCR.CurrencyId
WHERE C.IsMigrated = 0  AND  (CCR.Id Is NULL OR CCR.MandatoryAccountNumberField = 'AccountNumber') AND (CBA.AccountNumber IS NULL OR CBA.AccountNumber ='') AND CBA.AutomatedPaymentMethod <>'CreditCard'

INSERT INTO #ErrorLogs
SELECT C.Id
		, 'Error'
		,('Account Number for CustomerBankAccount Id {'+CONVERT(NVARCHAR(MAX),CBA.Id)+'} with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'} applicable only for Non-Credit Card Accounts')
FROM stgCustomer C
JOIN stgCustomerBankAccount CBA ON CBA.CustomerId = C.Id
WHERE C.IsMigrated = 0  AND  (CBA.AccountNumber IS NOT NULL) AND CBA.AutomatedPaymentMethod ='CreditCard'

INSERT INTO #ErrorLogs
SELECT C.Id
		, 'Error'
		,('Please enter Payment ProfileId for credit card CustomerBankAccount Id {'+CONVERT(NVARCHAR(MAX),CBA.Id)+'} with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
JOIN stgCustomerBankAccount CBA ON CBA.CustomerId = C.Id
WHERE C.IsMigrated = 0  AND (CBA.PaymentProfileId IS NULL OR CBA.PaymentProfileId ='') AND CBA.AutomatedPaymentMethod ='CreditCard'

INSERT INTO #ErrorLogs
SELECT C.Id
		, 'Error'
		,('Automated Payment Method for CustomerBankAccount Id {'+CONVERT(NVARCHAR(MAX),CBA.Id)+'} with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'} must be Credit Card for Credit Card Account')
FROM stgCustomer C
JOIN stgCustomerBankAccount CBA ON CBA.CustomerId = C.Id
WHERE C.IsMigrated = 0  AND  CBA.AutomatedPaymentMethod <> 'CreditCard' AND CBA.BankAccountCategoryName = 'Credit Card'

INSERT INTO #ErrorLogs
SELECT C.Id
		, 'Error'
		,('Account Category for CustomerBankAccount Id {'+CONVERT(NVARCHAR(MAX),CBA.Id)+'} with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'} must be Credit Card for Credit Card Account')
FROM stgCustomer C
JOIN stgCustomerBankAccount CBA ON CBA.CustomerId = C.Id
WHERE C.IsMigrated = 0  AND  CBA.AutomatedPaymentMethod = 'CreditCard' AND CBA.BankAccountCategoryName <> 'Credit Card'


INSERT INTO #ErrorLogs
SELECT C.Id
		, 'Error'
		,('Please enter IBAN for CustomerBankAccount Id {'+CONVERT(NVARCHAR(MAX),CBA.Id)+'} with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
JOIN stgCustomerBankAccount CBA ON CBA.CustomerId = C.Id
JOIN BankBranches BB ON CBA.R_BankBranchId = BB.Id
LEFT JOIN CountryCurrencyRelationships CCR ON BB.CountryId = CCR.CountryId AND CBA.R_CurrencyId = CCR.CurrencyId
WHERE (CCR.Id IS NOT NULL AND CCR.MandatoryAccountNumberField = 'IBAN') AND (CBA.IBAN IS NULL OR CBA.IBAN ='') AND CBA.BankAccountCategoryName <>'Credit Card'
UPDATE stgCustomerBillingPreference Set R_ReceivableTypeId = ReceivableTypes.Id
FROM stgCustomerBillingPreference CBP
INNER JOIN stgCustomer C ON C.Id = CBP.CustomerId
INNER JOIN ReceivableTypes ON ReceivableTypes.Name = CBP.ReceivableType
WHERE C.IsMigrated = 0 AND CBP.ReceivableType Is NOT NULL 
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Invalid ReceivableType for Customer Billing Preferences Id {'+CONVERT(NVARCHAR(MAX),CBP.Id)+'} with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
INNER JOIN stgCustomerBillingPreference CBP ON CBP.CustomerId = C.Id
WHERE C.IsMigrated = 0 AND CBP.ReceivableType Is NOT NULL AND CBP.R_ReceivableTypeId Is NULL
----Employees Assigned To Customer
UPDATE stgEmployeesAssignedToCustomer Set R_EmployeeId = Users.Id
FROM stgEmployeesAssignedToCustomer EAC
INNER JOIN stgCustomer C ON C.Id = EAC.CustomerId
INNER JOIN Users ON Users.LoginName = EAC.LoginName
WHERE C.IsMigrated = 0 AND EAC.LoginName Is NOT NULL 
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Invalid Login Name {'+ISNULL(EAC.LoginName,'NULL')+'} for EmployeesAssignedToCustomer Id {'+CONVERT(NVARCHAR(MAX),EAC.Id)+'} with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
INNER JOIN stgEmployeesAssignedToCustomer EAC ON EAC.CustomerId = C.Id
WHERE C.IsMigrated = 0 AND EAC.LoginName Is NOT NULL AND EAC.R_EmployeeId Is NULL
UPDATE stgEmployeesAssignedToCustomer Set R_RoleFunctionId = RoleFunctions.Id
FROM stgEmployeesAssignedToCustomer EAC
INNER JOIN stgCustomer C ON C.Id = EAC.CustomerId
INNER JOIN RoleFunctions ON RoleFunctions.Name = EAC.RoleFunctionName
WHERE C.IsMigrated = 0 AND EAC.RoleFunctionName Is NOT NULL 
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Invalid Role Function Name {'+ISNULL(EAC.RoleFunctionName,'NULL')+'} for EmployeesAssignedToCustomer Id {'+CONVERT(NVARCHAR(MAX),EAC.Id)+'} with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
INNER JOIN stgEmployeesAssignedToCustomer EAC ON EAC.CustomerId = C.Id
WHERE C.IsMigrated = 0 AND EAC.RoleFunctionName Is NOT NULL AND EAC.R_RoleFunctionId Is NULL

INSERT INTO #ErrorLogs
SELECT 
	c.Id
	,'Error'
	,('Customer can have only one primary employee assignment for a given role function {Role Function Name : ' +eac.RoleFunctionName+' Customer Id : ' +CONVERT(NVARCHAR(MAX), c.Id)+'}')
FROM stgCustomer c  
INNER JOIN stgEmployeesAssignedToCustomer eac ON c.Id = eac.CustomerId 
WHERE c.IsMigrated = 0 AND eac.IsPrimary = 1 AND eac.RoleFunctionName Is NOT NULL
GROUP BY c.Id, eac.RoleFunctionName
HAVING COUNT(*) > 1

----CustomerLateFeeSetup
UPDATE stgCustomerLateFeeSetup Set R_ReceivableTypeId = ReceivableTypes.Id
FROM stgCustomerLateFeeSetup CLS
INNER JOIN stgCustomer C ON C.Id = CLS.CustomerId
INNER JOIN ReceivableTypes ON ReceivableTypes.Name = CLS.ReceivableType
WHERE C.IsMigrated = 0 AND CLS.ReceivableType Is NOT NULL
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Invalid ReceivableType {'+ISNULL(CustomerLateFeeSetup.ReceivableType,'NULL')+'} for CustomerLateFeeSetup Id {'+CONVERT(NVARCHAR(MAX),CustomerLateFeeSetup.Id)+'} with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
INNER JOIN stgCustomerLateFeeSetup CustomerLateFeeSetup ON CustomerLateFeeSetup.CustomerId = C.Id
WHERE C.IsMigrated = 0 AND CustomerLateFeeSetup.ReceivableType Is NOT NULL AND CustomerLateFeeSetup.R_ReceivableTypeId Is NULL
----CustomerBondRating
UPDATE stgCustomerBondRating Set R_BondRatingId = BondRatings.Id
FROM stgCustomerBondRating CBR
INNER JOIN stgCustomer C ON C.Id = CBR.CustomerId
INNER JOIN BondRatings ON BondRatings.Rating = CBR.BondRating AND BondRatings.Agency = CBR.BondRatingAgency AND BondRatings.IsActive = 1
WHERE C.IsMigrated = 0 AND CBR.BondRating Is NOT NULL AND CBR.BondRatingAgency Is NOT NULL 
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Invalid BondRating {'+ISNULL(CBR.BondRating,'NULL')+'} and BondRatingAgency {'+CBR.BondRatingAgency+'} for CutomerBonRating Id {'+CONVERT(NVARCHAR(MAX),CBR.Id)+'} with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
INNER JOIN stgCustomerBondRating CBR ON CBR.CustomerId = C.Id
WHERE C.IsMigrated = 0 AND CBR.BondRating Is NOT NULL AND CBR.BondRatingAgency Is NOT NULL AND CBR.R_BondRatingId Is NULL
----Customer CreditRiskGrade
UPDATE stgCreditRiskGrade Set R_RatingModelConfigId = RatingModelConfigs.Id
FROM stgCreditRiskGrade CRG
INNER JOIN stgCustomer C ON C.Id = CRG.CustomerId
INNER JOIN RatingModelConfigs ON RatingModelConfigs.RatingModel = CRG.RatingModel 
WHERE C.IsMigrated = 0 AND CRG.RatingModel Is NOT NULL 
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Invalid RatingModel {'+ISNULL(CRG.RatingModel,'NULL')+'} for CustomerCreditRiskGrade Id {'+CONVERT(NVARCHAR(MAX),CRG.Id)+'} with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
INNER JOIN stgCreditRiskGrade CRG ON CRG.CustomerId = C.Id
WHERE C.IsMigrated = 0 AND CRG.RatingModel Is NOT NULL AND CRG.RatingModel Is NOT NULL AND CRG.R_RatingModelConfigId Is NULL
UPDATE stgCreditRiskGrade Set R_AdjustmentReasonConfigId = AdjustmentReasonConfigs.Id
FROM stgCreditRiskGrade CRG
INNER JOIN stgCustomer C ON C.Id = CRG.CustomerId
INNER JOIN AdjustmentReasonConfigs ON AdjustmentReasonConfigs.AdjustmentReason = CRG.AdjustmentReasonConfig
WHERE C.IsMigrated = 0 AND CRG.AdjustmentReasonConfig Is NOT NULL 
UPDATE stgCreditRiskGrade Set R_ContractId = Contracts.Id
FROM stgCreditRiskGrade CRG
INNER JOIN stgCustomer C ON C.Id = CRG.CustomerId
INNER JOIN Contracts ON Contracts.SequenceNumber = CRG.ContractSequenceNumber AND (Contracts.Status !='Cancelled' AND Contracts.Status != 'Inactive')
WHERE C.IsMigrated = 0 AND CRG.ContractSequenceNumber Is NOT NULL 
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Invalid AdjustmentReasonConfig {'+ISNULL(CRG.AdjustmentReasonConfig,'NULL')+'} for CustomerCreditRiskGrade Id {'+CONVERT(NVARCHAR(MAX),CRG.Id)+'} with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
INNER JOIN stgCreditRiskGrade CRG ON CRG.CustomerId = C.Id
WHERE C.IsMigrated = 0 AND CRG.AdjustmentReasonConfig Is NOT NULL AND CRG.R_AdjustmentReasonConfigId Is NULL
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Invalid Contract {'+ISNULL(CRG.ContractSequenceNumber,'NULL')+'} for CustomerCreditRiskGrade Id {'+CONVERT(NVARCHAR(MAX),CRG.Id)+'} with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
INNER JOIN stgCreditRiskGrade CRG ON CRG.CustomerId = C.Id
WHERE C.IsMigrated = 0 AND CRG.ContractSequenceNumber Is NOT NULL AND CRG.R_ContractId Is NULL
----CustomerThirdPartyRelationship
----CustomerACHAssignment
UPDATE stgCustomerACHAssignment Set R_BankAccountNumber = ISNULL(CBA.AccountNumber,CBA.PaymentProfileId), R_BankBranchName = CBA.BankBranch
FROM stgCustomerACHAssignment CAA
INNER JOIN stgCustomer C ON C.Id=CAA.CustomerId
INNER JOIN stgCustomerBankAccount CBA ON CBA.CustomerId = CAA.CustomerId
	AND (CBA.AutomatedPaymentMethod= 'ACHOrPAP' OR CBA.AutomatedPaymentMethod = 'CreditCard')
	AND ((CAA.BankAccountNumber IS NOT NULL AND CAA.BankAccountNumber = CBA.AccountNumber) OR (CAA.BankAccountName IS NOT NULL AND CAA.BankAccountName = CBA.AccountName)
			OR (CAA.BankAccountNumber IS NOT NULL OR CAA.BankAccountNumber = CBA.PaymentProfileId))
	AND CBA.BankBranch = CAA.BankBranchName
WHERE C.IsMigrated = 0 AND (CAA.BankAccountNumber Is NOT NULL OR CAA.BankAccountName IS NOT NULL) AND CAA.BankBranchName Is NOT NULL 
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('CustomerACHAssignment with Id {'+CONVERT(NVARCHAR(MAX),CAA.Id)+'} with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'} contains invalid BankAccountNumber and BankBranchName')
FROM stgCustomer C
INNER JOIN stgCustomerACHAssignment CAA ON CAA.CustomerId = C.Id
WHERE C.IsMigrated = 0 AND (CAA.BankAccountNumber Is NOT NULL OR CAA.BankBranchName IS NOT NULL OR CAA.BankAccountName IS NOT NULL) AND (CAA.R_BankAccountNumber IS NULL OR CAA.R_BankBranchName IS NULL)
UPDATE stgCustomerACHAssignment Set R_ReceivableTypeId = ReceivableTypes.Id
FROM stgCustomerACHAssignment CAA
INNER JOIN stgCustomer C ON C.Id=CAA.CustomerId
INNER JOIN ReceivableTypes ON ReceivableTypes.Name = CAA.ReceivableTypeName AND ReceivableTypes.IsActive=1
WHERE C.IsMigrated = 0 AND CAA.ReceivableTypeName Is NOT NULL 
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('CustomerACHAssignment with Id {'+CONVERT(NVARCHAR(MAX),CAA.Id)+'} with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'} contains invalid Receivable Type')
FROM stgCustomer C
INNER JOIN stgCustomerACHAssignment CAA ON CAA.CustomerId = C.Id
WHERE C.IsMigrated = 0 AND CAA.ReceivableTypeName Is NOT NULL AND CAA.R_ReceivableTypeId Is NULL
-- Credit Bureau
UPDATE stgCreditBureau Set R_BusinessBureauId = CBC.Id
FROM stgCreditBureau CB
INNER JOIN stgCustomer C ON C.Id = CB.CustomerId
INNER JOIN CreditBureauConfigs CBC ON CB.BusinessBureau = CBC.Code
WHERE 
C.IsMigrated = 0 AND CBC.IsActive = 1 AND CBC.IsBusinessBureau = 1 AND CB.BusinessBureau IS NOT NULL AND CBC.Code !='NoReport'
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('CreditBureau with Id {'+CONVERT(NVARCHAR(MAX),CB.Id)+'} with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'} contains invalid BusinessBureau')
FROM stgCustomer C
INNER JOIN stgCreditBureau CB ON CB.CustomerId = C.Id
WHERE C.IsMigrated = 0 AND CB.BusinessBureau Is NOT NULL AND CB.R_BusinessBureauId Is NULL
UPDATE stgCustomerBankAccount Set R_BankAccountCategoryId= CBAC.Id
FROM stgCustomerBankAccount CBA
INNER JOIN stgCustomer C ON C.Id = CBA.CustomerId
INNER JOIN BankAccountCategories CBAC ON CBA.BankAccountCategoryName = CBAC.AccountCategory
WHERE 
C.IsMigrated = 0
INSERT INTO #ErrorLogs
SELECT C.Id
		, 'Error'
		,('CustomerBankAccountId {'+CONVERT(NVARCHAR(MAX),CBA.Id)+'} associated with  CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'} cannot be an ACH or Primary ACH account and cannot have Account Category')
FROM stgCustomer C
JOIN stgCustomerBankAccount CBA ON CBA.CustomerId = C.Id
WHERE (CBA.IBAN IS NOT NULL AND (CBA.AutomatedPaymentMethod = 'ACHOrPAP' OR CBA.IsPrimaryACH = 1 OR CBA.R_BankAccountCategoryId IS NOT NULL)) 
INSERT INTO #ErrorLogs
SELECT
   	C.Id
	,'Error'
	,('Bank Account with Id {'+CONVERT(NVARCHAR(MAX),CBA.Id)+'} with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'} Must have a value for Account Category since  the account is ACH Account')
FROM stgCustomer C
INNER JOIN stgCustomerBankAccount CBA ON CBA.CustomerId = C.Id
WHERE C.IsMigrated=0 AND  CBA.R_BankAccountCategoryId Is NULL AND ((CBA.AutomatedPaymentMethod = 'ACHOrPAP' OR CBA.AutomatedPaymentMethod = 'CreditCard')OR CBA.IsPrimaryACH = 1)
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Bank Account with Id {'+CONVERT(NVARCHAR(MAX),CBA.Id)+'} with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'} contains invalid Bank Account Category')
FROM stgCustomer C
INNER JOIN stgCustomerBankAccount CBA ON CBA.CustomerId = C.Id
WHERE C.IsMigrated = 0 AND CBA.BankAccountCategoryName Is NOT NULL AND CBA.R_BankAccountCategoryId Is NULL
----Customer Validations
INSERT INTO #ErrorLogs
SELECT
	C.Id
	,'Error'
	,('The entered value for the field CustomerNumber:' + C.CustomerNumber + ' already exists. Please enter a unique value')
FROM
stgCustomer C
INNER JOIN Parties Party
ON C.IsMigrated=0 AND C.CustomerNumber = Party.PartyNumber	
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('CompanyName is required for the Corporate Customer with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
WHERE IsMigrated = 0 AND ( IsCorporate = 1 AND IsSoleProprietor = 0) AND CompanyName Is NULL
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('FirstName and LastName is mandatory for the Sole Proprietor with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
WHERE 
	  IsMigrated = 0 
		AND
	  (IsCorporate = 0 OR ( IsCorporate = 1 AND IsSoleProprietor = 1) ) 
		AND 
	  ( FirstName Is NULL OR LastName Is NULL)
INSERT INTO #ErrorLogs
SELECT
	C.Id
	,'Error'
	,('Please enter Company Legal Name with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}') AS Message
FROM 
stgCustomer C
WHERE IsMigrated = 0 AND C.IsCorporate = 1 AND C.IsSoleProprietor=0 AND C.CompanyName IS NULL
INSERT INTO #ErrorLogs
SELECT
	C.Id
	,'Error'
	,('Please enter Business Type with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}') AS Message
FROM 
stgCustomer C
WHERE IsMigrated = 0 AND C.BusinessType IS NULL AND C.IsLimitedDisclosureParty = 0;		
    INSERT INTO #ErrorLogs
	SELECT
		C.Id
		,'Error'
		,('PostalCode Is Mandatory for Customer Address Id {'+CONVERT(NVARCHAR(MAX),CA.Id)+'} with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
	FROM stgCustomer C
	INNER JOIN stgCustomerAddress CA ON CA.CustomerId = C.Id
	INNER JOIN Countries Country on CA.R_CountryId = Country.Id
	WHERE 
	  C.IsMigrated = 0 AND (CA.PostalCode IS NULL AND Country.IsPostalCodeMandatory = 1 )
    INSERT INTO #ErrorLogs
	SELECT
		C.Id
		,'Error'
		,('HomePostalCode Is Mandatory Customer Address Id {'+CONVERT(NVARCHAR(MAX),CA.Id)+'} with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
	FROM stgCustomer C
	INNER JOIN stgCustomerAddress CA ON CA.CustomerId = C.Id
	INNER JOIN Countries Country on CA.R_HomeCountryId = Country.Id
	WHERE 
	  C.IsMigrated = 0 AND (CA.HomePostalCode IS NULL AND Country.IsPostalCodeMandatory = 1 ) 
INSERT INTO #ErrorLogs
SELECT
	C.Id
	,'Error'
	,('A Customer {'+C.CustomerNumber+'} With ParentCustomerNumber {'+C.ParentCustomerNumber+'} cannot act as a Parent to itself') AS Message
FROM 
stgCustomer C
WHERE C.IsMigrated=0 AND C.ParentCustomerNumber IS NOT NULL AND C.CustomerNumber = C.ParentCustomerNumber
INSERT INTO #ErrorLogs
SELECT
	C.Id
	,'Error'
	,('Invoice Transit Days cannot be less than zero for the Customer Id {'+CONVERT(NVARCHAR(MAX),C.Id)+'}') AS Message
FROM stgCustomer C
WHERE IsMigrated = 0 AND InvoiceTransitDays < 0
INSERT INTO #ErrorLogs
SELECT
	C.Id
	,'Error'
	,('Invoice Grace Days cannot be less than zero for the Customer Id {'+CONVERT(NVARCHAR(MAX),C.Id)+'}') AS Message
FROM stgCustomer C
WHERE IsMigrated=0 AND InvoiceGraceDays < 0
INSERT INTO #ErrorLogs
SELECT
	C.Id
	,'Error'
	,('Invoice Lead Days cannot be less than zero for the Customer Id {'+CONVERT(NVARCHAR(MAX),C.Id)+'}') AS Message
FROM stgCustomer C
WHERE IsMigrated = 0 AND InvoiceLeadDays < 0
INSERT INTO #ErrorLogs		
SELECT
	CBA.CustomerId
	,'Error'
	,('The following IBAN(s) '+ISNULL(CBA.IBAN,'NULL')+' already exists. Please enter unique IBAN number for Customer Id {'+CONVERT(NVARCHAR(MAX),CBA.CustomerId)+'}') AS Message
FROM 
stgCustomer C
INNER JOIN stgCustomerBankAccount CBA ON CBA.CustomerId = C.Id AND C.IsMigrated = 0
WHERE CBA.IBAN <> '' AND CBA.IBAN IS NOT NULL
GROUP BY CBA.CustomerId,CBA.IBAN
HAVING COUNT(*)>1
INSERT INTO #ErrorLogs
SELECT
	CBA.CustomerId
	,'Error'
	,('The combination of fields Bank Name, Branch Name and Account Number should be unique. Please check for Bank Accounts with the following Account Numbers: '+ CBA.AccountNumber+' with Customer Id {'+CONVERT(NVARCHAR(MAX),CBA.CustomerId)+'}') AS Message
FROM 
stgCustomerBankAccount CBA
INNER JOIN stgCustomer C ON C.Id = CBA.CustomerId
WHERE C.IsMigrated=0 AND CBA.AccountNumber IS NOT NULL
AND CBA.AutomatedPaymentMethod = 'ACHOrPAP'
GROUP BY CBA.CustomerId,CBA.AccountNumber,CBA.BankBranch
HAVING COUNT(*)>1

INSERT INTO #ErrorLogs
SELECT
	CBA.CustomerId
	,'Error'
	,('The combination of fields Bank Name, Branch Name and Payment ProfileId should be unique. Please check for Bank Accounts with the following Account Numbers: '+ CBA.PaymentProfileId+' with Customer Id {'+CONVERT(NVARCHAR(MAX),CBA.CustomerId)+'}') AS Message
FROM 
stgCustomerBankAccount CBA
INNER JOIN stgCustomer C ON C.Id = CBA.CustomerId
WHERE C.IsMigrated=0 AND CBA.PaymentProfileId IS NOT NULL
AND CBA.AutomatedPaymentMethod = 'CreditCard'
GROUP BY CBA.CustomerId,CBA.PaymentProfileId,CBA.BankBranch
HAVING COUNT(*)>1

INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('IBAN is Invalid. First two characters must be alphabets and Length must be between 4 and 34 for CustomerBankAccount Id {'+CONVERT(NVARCHAR(MAX),CBA.Id)+'} with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
INNER JOIN stgCustomerBankAccount CBA ON CBA.CustomerId = C.Id
WHERE C.IsMigrated = 0 AND CBA.IBAN IS NOT NULL AND CBA.IBAN NOT LIKE '[a-Z][a-Z]%' OR (LEN(CBA.IBAN) NOT BETWEEN 4 AND 34)
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('GL Segment Value cannot be null for CustomerBankAccount Id {'+CONVERT(NVARCHAR(MAX),CBA.Id)+'} with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
INNER JOIN stgCustomerBankAccount CBA ON CBA.CustomerId = C.Id
WHERE C.IsMigrated = 0 AND CBA.GLSegmentValue IS NULL AND C.IsInterCompany = 1
INSERT INTO #ErrorLogs
SELECT
	CBP.CustomerId
	,'Error'
	,('Please enter Invoice Preference for the following Receivable Type(s) :' + CBP.ReceivableType+' for CustomerBillingPreference with Customer Id {'+CONVERT(NVARCHAR(Max),CBP.CustomerId)+'}') AS Message
FROM 
stgCustomerBillingPreference CBP
INNER JOIN stgCustomer C ON C.Id=CBP.CustomerId
WHERE C.IsMigrated = 0 AND CBP.InvoicePreference IS NULL
INSERT INTO #ErrorLogs
SELECT
	CBP.CustomerId
	,'Error'
	,('The ReceivableType(s) and Respective Effective from Date must be unique in the System for CustomerBillingPreference with CustomerId {'+CONVERT(NVARCHAR(MAX),CBP.CustomerId)+'}') AS Message
FROM 
stgCustomerBillingPreference CBP 
INNER JOIN stgCustomer C On C.Id = CBP.CustomerId
WHERE C.IsMigrated=0
GROUP BY CBP.CustomerId,CBP.R_ReceivableTypeId,CBP.EffectiveFromDate
HAVING COUNT(*) > 1 
INSERT INTO #ErrorLogs
SELECT
	C.Id
	,'Error'
	,('Invalid Legal Formation Type for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}') AS Message
FROM 
stgCustomer C
WHERE C.IsMigrated=0 AND C.LegalFormationTypeCode IS NOT NULL AND  C.R_LegalFormationTypeConfigId IS NULL	
INSERT INTO #ErrorLogs
SELECT
	EAC.CustomerId
	,'Error'
	,('Invalid RoleFunction {'+EAC.RoleFunctionName+'} for EmployeeAssignedToCustomerId {'+CONVERT(NVARCHAR(MAX),EAC.Id)+'} with CustomerId {'+CONVERT(NVARCHAR(MAX),EAC.CustomerId)+'}')
FROM stgEmployeesAssignedToCustomer EAC
INNER JOIN stgCustomer C On C.Id = EAC.CustomerId
WHERE C.IsMigrated=0 AND EAC.RoleFunctionName IS NOT NULL AND EAC.R_RoleFunctionId IS NULL	
INSERT INTO #ErrorLogs
SELECT
	customerACHAssignment.CustomerId
	,'Error'
	,('Following CustomerACHAssignment with Id '+ CONVERT(NVARCHAR(10),customerACHAssignment.Id)  +' must have Start Date with Customer Id {'+CONVERT(NVARCHAR(MAX),customerACHAssignment.CustomerId)+'}')
FROM stgCustomerACHAssignment customerACHAssignment
INNER JOIN stgCustomer C ON C.Id = customerACHAssignment.CustomerId
WHERE C.IsMigrated=0 AND customerACHAssignment.StartDate IS NULL
INSERT INTO #ErrorLogs
SELECT
	customerACHAssignment.CustomerId
	,'Error'
	,('End Date must be on or after Begin Date for following CustomerACHAssignment with Id {'+CONVERT(NVARCHAR(MAX),customerACHAssignment.Id)+'}') AS Message
FROM stgCustomerACHAssignment customerACHAssignment
INNER JOIN stgCustomer C ON C.Id = customerACHAssignment.CustomerId
WHERE C.IsMigrated=0 AND customerACHAssignment.StartDate IS NOT NULL AND customerACHAssignment.EndDate IS NOT NULL AND customerACHAssignment.EndDate < customerACHAssignment.StartDate
INSERT INTO #ErrorLogs
SELECT
	employeeAssgToCustomer.CustomerId
	,'Error'
	,('Selected Employee is not mapped with the selected RoleFunction with CustomerId {'+CONVERT(NVARCHAR(MAX),employeeAssgToCustomer.CustomerId)+'}') AS Message
FROM 
stgEmployeesAssignedToCustomer employeeAssgToCustomer
INNER JOIN stgCustomer C ON C.Id = employeeAssgToCustomer.CustomerId
LEFT JOIN dbo.RolesForUsers roleForUsers ON roleForUsers.UserId = employeeAssgToCustomer.R_EmployeeId
LEFT JOIN dbo.Roles roles ON roles.Id = roleForUsers.RoleId
WHERE C.IsMigrated=0 AND roleForUsers.IsActive=1 AND roles.IsActive=1 AND NOT EXISTS(SELECT NULL FROM dbo.RoleFunctions WHERE IsActive=1 AND id = employeeAssgToCustomer.R_RoleFunctionId)
UPDATE stgFinancialStatement Set R_DocumentTypeId = DT.Id
FROM stgCustomer C
INNER JOIN stgFinancialStatement FS ON FS.CustomerId = C.Id
INNER JOIN DocumentTypes DT ON DT.Name = FS.DocumentTypeName
WHERE C.IsMigrated = 0 AND FS.DocumentTypeName Is NOT NULL 
INSERT INTO #ErrorLogs
SELECT 
	C.Id
	,'Error'
	,('Invalid Document Type for FinancialStatement with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
FROM stgCustomer C
INNER JOIN stgFinancialStatement FS ON FS.CustomerId = C.Id
WHERE C.IsMigrated = 0 AND FS.DocumentTypeName Is NOT NULL AND R_DocumentTypeId Is NULL 
INSERT INTO #ErrorLogs
SELECT
	Employee.CustomerId
	,'Error'
	,('Following Employee(s) having same Role Function have already been assigned:' + Employee.LoginName+' for CustomerId {'+CONVERT(NVARCHAR(MAX),Employee.CustomerId)+'}') AS Message
FROM stgEmployeesAssignedToCustomer Employee
INNER JOIN stgCustomer C ON C.Id = Employee.CustomerId
WHERE C.IsMigrated=0 AND Employee.CustomerId in  ( SELECT CustomerId FROM ( SELECT *, RANK() OVER ( PARTITION BY CustomerId, R_EmployeeId , R_RoleFunctionId ORDER BY CustomerId DESC) rank 
															FROM stgEmployeesAssignedToCustomer )T WHERE rank > 1 )
INSERT INTO #ErrorLogs
SELECT
	creditRiskGrade.CustomerId
	,'Error'
	,('The length of RAID field should be 5 or 6 characters for CreditRiskGrade with Customer Id {'+CONVERT(NVARCHAR(MAX),creditRiskGrade.CustomerId)+'}') AS Message
FROM stgCreditRiskGrade creditRiskGrade
INNER JOIN stgCustomer C ON C.Id = creditRiskGrade.CustomerId
WHERE (creditRiskGrade.RatingModel='RiskCalc' AND LEN(creditRiskGrade.RAID) != 5 AND LEN(creditRiskGrade.RAID) != 6) OR (creditRiskGrade.RatingModel!='RiskCalc' AND (creditRiskGrade.RAID != 0 AND LEN(creditRiskGrade.RAID) != 5 AND LEN(creditRiskGrade.RAID) != 6))
UPDATE stgCustomerPayoffTemplateAssignment SET [IsDefault] = 0
WHERE Id <> ALL (SELECT MAX(Id) From stgCustomerPayoffTemplateAssignment
WHERE [IsDefault] = 1 
GROUP BY CustomerId
HAVING COUNT(CustomerId) > 1)
--Payoff Template assignments
UPDATE stgCustomerPayoffTemplateAssignment Set R_PayOffTemplateId= templates.Id
FROM stgCustomerPayoffTemplateAssignment Payoff
INNER JOIN stgCustomer V ON V.Id = payoff.CustomerId
INNER JOIN PayOffTemplates templates ON  Payoff.PayOffTemplateName = templates.TemplateName
WHERE templates.IsActive =1 AND templates.TemplateType = 'Customer' AND V.IsMigrated = 0 
AND payoff.Id IS NOT NULL AND Payoff.R_PayOffTemplateId IS NULL
INSERT INTO #ErrorLogs
SELECT 
	V.Id
	,'Error'
	,('Invalid PayOff Template Name for Customer with  CustomerId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
FROM stgCustomer V
INNER JOIN stgCustomerPayoffTemplateAssignment payoff ON payoff.CustomerId = V.Id
WHERE V.IsMigrated = 0 AND payoff.Id Is NOT NULL AND payoff.R_PayOffTemplateId IS NULL
UPDATE stgCustomerBankAccount SET [IsPrimaryACH] = 0
	WHERE Id <> ALL (SELECT MAX(Id) From stgCustomerBankAccount
	WHERE [IsPrimaryACH] = 1 
	GROUP BY CustomerId)
INSERT INTO #ErrorLogs
SELECT
	CC.CustomerId
	,'Error'
	,('The entered value for the field ContactUniqueIdentifier:' + CC.UniqueIdentifier + ' already exists. Please enter a unique value ') AS Message
FROM
stgCustomerContact CC
INNER JOIN stgCustomer C On C.Id = CC.CustomerId
INNER JOIN PartyContacts PC on CC.UniqueIdentifier = PC.UniqueIdentifier
WHERE C.IsMigrated = 0  

INSERT INTO #ErrorLogs
SELECT
	CC.CustomerId
	,'Error'
    , ('Business Start Time In Hours must be between 0 and 23 for contact with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+' and ContactUniqueIdentifier {'+ ISNULL(CC.UniqueIdentifier,'NULL') +'}') AS Message
FROM
stgCustomerContact CC
INNER JOIN stgCustomer C On C.Id = CC.CustomerId 
WHERE C.IsMigrated = 0  AND CC.BusinessStartTimeInHours NOT BETWEEN 0 AND 23 

INSERT INTO #ErrorLogs
SELECT
	CC.CustomerId
	,'Error'
    , ('Business End Time In Hours must be between 0 and 23 for contact with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+' and ContactUniqueIdentifier {'+ ISNULL(CC.UniqueIdentifier,'NULL') +'}') AS Message
FROM
stgCustomerContact CC
INNER JOIN stgCustomer C On C.Id = CC.CustomerId 
WHERE C.IsMigrated = 0  AND CC.BusinessEndTimeInHours NOT BETWEEN 0 AND 23

INSERT INTO #ErrorLogs
SELECT
	CC.CustomerId
	,'Error'
    , ('Business Start Time In Minutes must be between 0 and 59 for contact with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+' and ContactUniqueIdentifier {'+ ISNULL(CC.UniqueIdentifier,'NULL') +'}') AS Message
FROM
stgCustomerContact CC
INNER JOIN stgCustomer C On C.Id = CC.CustomerId 
WHERE C.IsMigrated = 0  AND CC.BusinessStartTimeInMinutes NOT BETWEEN 0 AND 59

INSERT INTO #ErrorLogs
SELECT
	CC.CustomerId
	,'Error'
    , ('Business End Time In Minutes must be between 0 and 59 for contact with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+' and ContactUniqueIdentifier {'+ ISNULL(CC.UniqueIdentifier,'NULL') +'}') AS Message
FROM
stgCustomerContact CC
INNER JOIN stgCustomer C On C.Id = CC.CustomerId 
WHERE C.IsMigrated = 0  AND CC.BusinessEndTimeInMinutes NOT BETWEEN 0 AND 59 

INSERT INTO #ErrorLogs
SELECT
	CC.CustomerId
	,'Error'
    , ('Business End Time should be greater than Business Start Time for contact with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+' and ContactUniqueIdentifier '+ ISNULL(CC.UniqueIdentifier,'NULL') +'}') AS Message
FROM
stgCustomerContact CC
INNER JOIN stgCustomer C On C.Id = CC.CustomerId
WHERE C.IsMigrated = 0  AND ((BusinessEndTimeInHours <> 0 OR BusinessStartTimeInHours <> 0 OR BusinessEndTimeInMinutes <> 0 OR BusinessStartTimeInMinutes <> 0 )
AND ((CC.BusinessEndTimeInHours < CC.BusinessStartTimeInHours) 
OR (CC.BusinessEndTimeInHours = CC.BusinessStartTimeInHours AND CC.BusinessEndTimeInMinutes <= CC.BusinessStartTimeInMinutes)))

INSERT INTO #ErrorLogs
SELECT
	CA.CustomerId
	,'Error'
	,('The entered value for the field AddressUniqueIdentifier:' + CA.UniqueIdentifier + ' already exists. Please enter a unique value ') AS Message
FROM
stgCustomerAddress CA
INNER JOIN stgCustomer C On C.Id = CA.CustomerId
INNER JOIN PartyAddresses PA on CA.UniqueIdentifier = PA.UniqueIdentifier
WHERE C.IsMigrated = 0
INSERT INTO #ErrorLogs
SELECT
    CBA.CustomerId
	,'Error'
	,('The entered value for the Bank Account UniqueIdentifier:' + CBA.UniqueIdentifier + ' already exists. Please enter a unique value ') AS Message
FROM
stgCustomerBankAccount CBA
INNER JOIN stgCustomer C On CBA.CustomerId = C.Id 
INNER JOIN BankAccounts BA on CBA.UniqueIdentifier = BA.UniqueIdentifier
WHERE C.IsMigrated = 0
INSERT INTO #ErrorLogs
SELECT
    CBA.CustomerId
	,'Error'
	,('AccountCategory Is Required For ACH CustomerBankAcccount with Customer ID {'+CONVERT(NVARCHAR(MAX),CBA.CustomerId)+'}') AS Message
FROM
stgCustomerBankAccount CBA
INNER JOIN stgCustomer C On CBA.CustomerId = C.Id 
INNER JOIN BankAccountCategories BA on CBA.BankAccountCategoryName = BA.AccountCategory
WHERE C.IsMigrated = 0 AND( CBA.AutomatedPaymentMethod = 'ACHOrPAP' OR CBA.AutomatedPaymentMethod = 'CreditCard') AND CBA.BankAccountCategoryName  Is NULL
	INSERT INTO #ErrorLogs
	SELECT
	C.Id
	,'Error'
	,('Please set at least one of the address as Main Address for Customer with CustomerId
	{'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
	FROM
	stgCustomer C
    WHERE C.IsMigrated = 0 AND C.Id NOT IN
	(
	SELECT CA.CustomerId FROM stgCustomerAddress CA
	WHERE IsMain = 1
	GROUP BY CA.CustomerId
	HAVING COUNT (*) >0 
	)
	INSERT INTO #ErrorLogs
	SELECT
	C.Id
	,'Error'
	,('Please set only one of the addresses as Main Address for Customer with CustomerId
	{'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
	FROM
	stgCustomer C
    WHERE C.IsMigrated = 0 AND C.Id IN
	(
	SELECT CA.CustomerId FROM stgCustomerAddress CA
	WHERE IsMain = 1
	GROUP BY CA.CustomerId
	HAVING COUNT (*) >1
	)
    INSERT INTO #ErrorLogs
	SELECT 
		CA.CustomerId
		,'Error'
		,('Please enter Valid Office Address for the Address indicated as Main Address with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+' and UniqueIdentifier '+ ISNULL(CA.UniqueIdentifier,'NULL') +'}')
	FROM stgCustomer C
	INNER JOIN stgCustomerAddress CA ON CA.CustomerId = C.Id
	WHERE 
	    C.IsMigrated = 0 AND CA.Id IS NOT NULL AND CA.IsMain=1 AND C.IsCorporate = 1
		and 
		(
		CA.AddressLine1 IS NULL AND CA.City IS NULL AND CA.State IS NULL AND CA.Country IS NULL AND CA.PostalCode IS NULL
		)
    INSERT INTO #ErrorLogs
	SELECT 
		 C.Id
		,'Error'
		,('Provide Home Address for the Address indicated as Main Address for Non Commercial Party with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+' and UniqueIdentifier '+ ISNULL(CA.UniqueIdentifier,'NULL') +'}')
	FROM stgCustomer C
	INNER JOIN stgCustomerAddress CA ON CA.CustomerId = C.Id
	WHERE 
	  C.IsMigrated = 0 AND CA.Id IS NOT NULL AND C.IsCorporate = 0 AND IsMain = 1
	  AND 
	  (
	  CA.HomeAddressLine1 IS NULL AND CA.HomeState IS NULL AND CA.HomeCity IS NULL AND CA.HomePostalCode IS NULL AND CA.HomeCountry IS NULL
	  )
	INSERT INTO #ErrorLogs
	SELECT 
		C.Id
		,'Error'
		,('Provided Home Address is not valid for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+' and UniqueIdentifier '+ ISNULL(CA.UniqueIdentifier,'NULL') +'}')
	FROM stgCustomer C
	INNER JOIN stgCustomerAddress CA ON CA.CustomerId = C.Id
	WHERE 
	  C.IsMigrated = 0 AND CA.Id IS NOT NULL
	  AND 
	  (
	  CA.HomeAddressLine1 IS NOT NULL AND ( CA.HomeState IS NULL OR CA.HomeCity IS NULL OR CA.HomePostalCode IS NULL OR CA.HomeCountry IS NULL)
	  OR
	  CA.HomeState IS NOT NULL AND ( CA.HomeAddressLine1 IS NULL OR CA.HomeCity IS NULL OR CA.HomePostalCode IS NULL OR CA.HomeCountry IS NULL)
	  OR
	  CA.HomeCity IS NOT NULL AND ( CA.HomeState IS NULL OR CA.HomeAddressLine1 IS NULL OR CA.HomePostalCode IS NULL OR CA.HomeCountry IS NULL)
	  OR
	  CA.HomePostalCode IS NOT NULL AND (CA.HomeState IS NULL OR CA.HomeAddressLine1 IS NULL OR CA.HomeCity IS NULL OR CA.HomeCountry IS NULL)
	  OR 
	  CA.HomeCountry IS NOT NULL AND (CA.HomeState IS NULL OR CA.HomeAddressLine1 IS NULL OR CA.HomeCity IS NULL OR CA.HomePostalCode IS NULL)
	  )
	INSERT INTO #ErrorLogs
	SELECT 
		C.Id
		,'Error'
		,('Provided Office Address is not valid for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+' and UniqueIdentifier '+ ISNULL(CA.UniqueIdentifier,'NULL') +'}')
	FROM stgCustomer C
	INNER JOIN stgCustomerAddress CA ON CA.CustomerId = C.Id 
	WHERE 
	  C.IsMigrated = 0 AND CA.Id IS NOT NULL 
	 AND 
	 (
	  CA.AddressLine1 IS NOT NULL AND ( CA.State IS NULL OR CA.City IS NULL OR CA.PostalCode IS NULL OR CA.Country IS NULL)
	  OR
	  CA.State IS NOT NULL AND ( CA.AddressLine1 IS NULL OR CA.City IS NULL OR CA.PostalCode IS NULL OR CA.Country IS NULL)
	  OR
	  CA.City IS NOT NULL AND ( CA.State IS NULL OR CA.AddressLine1 IS NULL OR CA.PostalCode IS NULL OR CA.Country IS NULL)
	  OR
	  CA.PostalCode IS NOT NULL AND (CA.State IS NULL OR CA.AddressLine1 IS NULL OR CA.City IS NULL OR CA.Country IS NULL)
	  OR 
	  CA.Country IS NOT NULL AND (CA.State IS NULL OR CA.AddressLine1 IS NULL OR CA.City IS NULL OR CA.PostalCode IS NULL)
	 )
    INSERT INTO #ErrorLogs
	SELECT 
		C.Id
		,'Error'
		,('PostalCode Is Mandatory for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+' and UniqueIdentifier '+ ISNULL(CA.UniqueIdentifier,'NULL') +'}')
	FROM stgCustomer C
	INNER JOIN stgCustomerAddress CA ON CA.CustomerId = C.Id
	INNER JOIN Countries CC on CA.R_CountryId = CC.Id
	WHERE 
	  C.IsMigrated = 0 AND CA.R_CountryId IS NOT NULL AND ( CA.PostalCode IS NULL AND CC.IsPostalCodeMandatory = 1 )
    INSERT INTO #ErrorLogs
	SELECT 
		C.Id
		,'Error'
		,('HomePostalCode Is Mandatory for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+' and UniqueIdentifier '+ ISNULL(CA.UniqueIdentifier,'NULL') +'}')
	FROM stgCustomer C
	INNER JOIN stgCustomerAddress CA ON CA.CustomerId = C.Id
	INNER JOIN Countries CC on CA.R_HomeCountryId = CC.Id
	WHERE 
	  C.IsMigrated = 0 AND CA.R_HomeCountryId IS NOT NULL AND (CA.HomePostalCode IS NULL AND CC.IsPostalCodeMandatory = 1 ) 
	--INSERT INTO #ErrorLogs
	--SELECT DISTINCT
	--	C.Id as [CustomerId]
	--	,'Error'
	--	,('TaxId : {'+C.TaxId+'} is not in correct format, please enter TaxId with the regex format : {'+ dbo.Countries.CorporateTaxIDMask +'} with Customer Id {'+CONVERT(NVARCHAR(MAX),CA.CustomerId)+'}') AS Message
	--FROM
	--stgCustomer C
	--INNER JOIN stgCustomerAddress CA on C.Id = CA.CustomerId
	--INNER JOIN dbo.Countries on CA.R_CountryId = dbo.Countries.Id
	--WHERE C.IsMigrated = 0
	--AND C.[IsCorporate] = 1 
	--AND dbo.Countries.CorporateTaxIDMask IS NOT NULL
	--AND C.TaxId IS NOT NULL
	--AND CA.IsMain = 1 
	--AND CA.R_CountryId IS NOT NULL
	--AND dbo.RegexStringMatch(C.TaxId,dbo.Countries.CorporateTaxIDMask) = 0
	--INSERT INTO #ErrorLogs
	--SELECT DISTINCT
	--	C.Id as [CustomerId]
	--	,'Error'
	--	,('SocialSecurityNumber : {'+C.SocialSecurityNumber+'} is not in correct format, please enter SocialSecurityNumber with the regex format : {'+dbo.Countries.IndividualTaxIDMask +'} with Customer Id {'+CONVERT(NVARCHAR(MAX),CA.CustomerId)+'}') AS Message
	--FROM
	--stgCustomer C
	--INNER JOIN stgCustomerAddress CA on C.id = CA.CustomerId 
	--INNER JOIN dbo.Countries on ISNULL(CA.R_CountryId,CA.R_HomeCountryId) = dbo.Countries.Id
	--WHERE C.IsMigrated = 0
	--AND C.[IsCorporate] = 0 
	--AND dbo.Countries.IndividualTaxIDMask IS NOT NULL
	--AND C.SocialSecurityNumber IS NOT NULL
	--AND CA.IsMain=1 
	--and (CA.R_CountryId IS NOT NULL OR CA.R_HomeCountryId IS NOT NULL)
	--AND dbo.RegexStringMatch(C.SocialSecurityNumber,dbo.Countries.IndividualTaxIDMask ) = 0
	INSERT INTO #ErrorLogs
	SELECT DISTINCT
		C.Id as [CustomerId]
		,'Error'
		,('PostalCode : {'+ISNULL(CA.PostalCode, 'NULL')+'} is not in correct format, please enter PostalCode with the regex format : {'+dbo.Countries.PostalCodeMask +'} with Customer Id {'+CONVERT(NVARCHAR(MAX),CA.CustomerId)+'}') AS Message
	FROM
	stgCustomer C
	INNER JOIN stgCustomerAddress CA on C.id = CA.CustomerId
	INNER JOIN dbo.Countries on dbo.Countries.Id =  CA.R_CountryId
	WHERE C.IsMigrated = 0
	AND dbo.Countries.PostalCodeMask IS NOT NULL
	AND CA.R_CountryId IS NOT NULL 
	AND CA.PostalCode IS NOT NULL
	AND dbo.RegexStringMatch(CA.PostalCode,dbo.Countries.PostalCodeMask ) = 0
	INSERT INTO #ErrorLogs
	SELECT DISTINCT 
		C.Id as [CustomerId]
		,'Error'
		,('HomePostalCode : {'+ISNULL(CA.HomePostalCode, 'NULL')+'} is not in correct format, please enter HomePostalCode with the regex format : {'+dbo.Countries.PostalCodeMask +'} with Customer Id  {'+CONVERT(NVARCHAR(MAX),CA.CustomerId)+'}') AS Message
	FROM
	stgCustomer C
	INNER JOIN stgCustomerAddress CA on C.id = CA.CustomerId
	INNER JOIN dbo.Countries on dbo.Countries.Id =  CA.R_HomeCountryId
	WHERE C.IsMigrated = 0
	AND dbo.Countries.PostalCodeMask IS NOT NULL
	AND CA.R_HomeStateId IS NOT NULL 
	AND CA.HomePostalCode IS NOT NULL
	AND dbo.RegexStringMatch(CA.HomePostalCode,dbo.Countries.PostalCodeMask ) = 0

	UPDATE C set C.R_ConsentConfigId = CC.Id
	FROM stgCustomer C1 
		JOIN stgCustomerConsent C on C1.Id = C.CustomerId
		JOIN Countries C2 on C.Country = C2.ShortName
		JOIN Consents C3 on C.Title = C3.Title
		JOIN ConsentConfigs CC on C3.Id = CC.ConsentId AND C2.ID = CC.CountryId
	WHERE C1.IsMigrated =0 and CC.IsActive = 1 AND CC.EntityType ='Customer'

	UPDATE C set C.R_ConsentConfigId = CC.Id
	FROM stgCustomer C4
		JOIN stgCustomerContact C1  on C4.Id = C1.CustomerId 
		JOIN stgCustomerContactConsent C on C1.Id = C.CustomerContactId 
		JOIN Countries C2 on C.Country = C2.ShortName
		JOIN Consents C3 on C.Title = C3.Title
		JOIN ConsentConfigs CC on C3.Id = CC.ConsentId AND C2.ID = CC.CountryId
	WHERE C4.IsMigrated =0 and CC.IsActive = 1 AND CC.EntityType ='CustomerContact'


	INSERT INTO #ErrorLogs
	SELECT 
		C.Id
		,'Error'
		,('Invalid Consent Combination (Title,Country,EntityType) for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
	FROM stgCustomer C
	JOIN  stgCustomerConsent CC on C.Id = CC.CustomerId
	WHERE C.IsMigrated = 0 AND CC.R_ConsentConfigId Is NULL

	INSERT INTO #ErrorLogs
	SELECT 
		C.Id as 'Customer Id'
		,'Error'
		,('Invalid Consent Combination (Title,Country,EntityType) for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'} and CustomerContactId {'+CONVERT(NVARCHAR(MAX),CC.Id)+'}')
	FROM stgCustomer C
	JOIN  stgCustomerContact CC on C.Id = CC.CustomerId
	JOIN  stgCustomerContactConsent C1 on CC.Id = C1.CustomerContactId
	WHERE C.IsMigrated = 0 AND C1.R_ConsentConfigId Is NULL

	INSERT INTO #ErrorLogs
	SELECT
		C.Id
		,'Error'
		,('Expiry date must be after Effective Date for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
	FROM stgCustomer C
	JOIN  stgCustomerConsent CC on C.Id = CC.CustomerId
	WHERE C.IsMigrated = 0 AND CC.R_ConsentConfigId Is NOT NULL AND CC.ExpiryDate Is NOT NULL and CC.ExpiryDate < CC.EffectiveDate

	INSERT INTO #ErrorLogs
	SELECT 
		C.Id as 'Customer Id'
		,'Error'
		,('Expiry date must be after Effective Date for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'} and CustomerContactId {'+CONVERT(NVARCHAR(MAX),CC.Id)+'}')
	FROM stgCustomer C
	JOIN  stgCustomerContact CC on C.Id = CC.CustomerId
	JOIN  stgCustomerContactConsent C1 on CC.Id = C1.CustomerContactId
	WHERE C.IsMigrated = 0 AND C1.R_ConsentConfigId Is NOT NULL AND C1.ExpiryDate Is NOT NULL and C1.ExpiryDate < C1.EffectiveDate

	UPDATE C set C.R_CustomerLegalStatus = CLC.Id
	FROM stgCustomer C
	JOIN CustomerLegalStatusConfigs CLC on C.CustomerLegalStatus = CLC.Description
	WHERE C.IsMigrated = 0 AND C.R_CustomerLegalStatus IS NULL AND CLC.IsActive=1

	UPDATE C set C.R_Sector = SC.Id
	FROM stgCustomer C
	JOIN SectorConfigs SC on C.Sector = SC.Description
	WHERE C.IsMigrated = 0 AND C.R_Sector IS NULL AND SC.IsActive=1

	UPDATE C set C.R_Profession = PC.Id
	FROM stgCustomer C
	JOIN ProfessionsConfigs PC on C.profession = PC.Code
	WHERE C.IsMigrated = 0 AND C.R_Profession IS NULL AND PC.IsActive=1
   
    INSERT INTO #ErrorLogs
	SELECT 
		 C.Id as 'Customer Id'
		,'Error'
		,('Customer Legal Status is Invalid for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id))
	FROM stgCustomer C
	WHERE C.IsMigrated=0 AND C.R_CustomerLegalStatus IS NULL

	INSERT INTO #ErrorLogs
	SELECT 
		 C.Id as 'Customer Id'
		,'Error'
		,('Sector is Invalid for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id))
	FROM stgCustomer C
	WHERE C.IsMigrated=0 AND (C.R_Sector IS NULL AND C.IsCorporate=1)

	INSERT INTO #ErrorLogs
	SELECT 
		 C.Id as 'Customer Id'
		,'Error'
		,('Profession is Invalid for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id))
	FROM stgCustomer C
	WHERE C.IsMigrated=0 AND c.Profession IS NOT NULL AND C.R_Profession IS NULL

	INSERT INTO #ErrorLogs
	SELECT 
		 C.Id as 'Customer Id'
		,'Error'
		,('Vat Registration should be true in case of Corporate Customer, for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id))
	FROM stgCustomer C
	WHERE C.IsMigrated=0 AND (C.IsCorporate =1 AND C.VATRegistration=0 )

	INSERT INTO #ErrorLogs
	SELECT 
		 C.Id as 'Customer Id'
		,'Error'
		,('Please Enter National Id Card Number for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id))
	FROM stgCustomer C
	WHERE C.IsMigrated=0 AND 
	C.NationalIdCardNumber IS NULL AND 
	((C.IsCorporate =0 AND C.IsForeigner=0) OR (C.IsCorporate=1 AND C.IsSoleProprietor=1 AND C.IsForeigner=0))

	INSERT INTO #ErrorLogs
	SELECT 
		 C.Id as 'Customer Id'
		,'Error'
		,('Please Enter DateofIssueID CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id))
	FROM stgCustomer C
	WHERE C.IsMigrated=0 AND 
	C.DateofIssueID IS NULL AND
	 ((C.IsCorporate =0 AND C.IsForeigner=0) OR (C.IsCorporate=1 AND C.IsSoleProprietor=1 AND C.IsForeigner=0))

	INSERT INTO #ErrorLogs
	SELECT 
		 C.Id as 'Customer Id'
		,'Error'
		,('Please Enter IssuedIN for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id))
	FROM stgCustomer C
	WHERE C.IsMigrated=0 AND 
	C.IssuedIn IS NULL AND 
	((C.IsCorporate =0 AND C.IsForeigner=0) OR (C.IsCorporate=1 AND C.IsSoleProprietor=1 AND C.IsForeigner=0))

	INSERT INTO #ErrorLogs
	SELECT 
		 C.Id as 'Customer Id'
		,'Error'
		,('Please Enter Gender for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id))
	FROM stgCustomer C
	WHERE C.IsMigrated=0 AND 
	C.Gender IS NULL AND 
	((C.IsCorporate =0) OR (C.IsCorporate=1 AND C.IsSoleProprietor=1))

	INSERT INTO #ErrorLogs
	SELECT 
		 C.Id as 'Customer Id'
		,'Error'
		,('Please Enter LN4 for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id))
	FROM stgCustomer C
	WHERE C.IsMigrated=0 AND 
	C.Ln4 IS NULL AND 
	C.IsForeigner=1

	INSERT INTO #ErrorLogs
	SELECT 
		 C.Id as 'Customer Id'
		,'Error'
		,('Please Enter Passport Number for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id))
	FROM stgCustomer C
	WHERE C.IsMigrated=0 AND 
	C.PassportNo IS NULL AND 
	C.IsForeigner=1

	INSERT INTO #ErrorLogs
	SELECT 
		 C.Id as 'Customer Id'
		,'Error'
		,('Please Enter Passport Country for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id))
	FROM stgCustomer C
	WHERE C.IsMigrated=0 AND 
	C.PassportCountry IS NULL AND 
	C.IsForeigner=1

	INSERT INTO #ErrorLogs
	SELECT 
		 C.Id as 'Customer Id'
		,'Error'
		,('Please Enter Passport Address for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id))
	FROM stgCustomer C
	WHERE C.IsMigrated=0 AND 
	C.PassportAddress IS NULL AND 
	C.IsForeigner=1

	INSERT INTO #ErrorLogs
    SELECT
    	CC.CustomerId
    	,'Error'
        , ('Please Enter EGN Number for Customer contact with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+' and ContactUniqueIdentifier {'+ ISNULL(CC.UniqueIdentifier,'NULL') +'}') AS Message
    FROM
    stgCustomerContact CC
    INNER JOIN stgCustomer C On C.Id = CC.CustomerId 
	INNER JOIN stgCustomerContactType CCT on CC.Id = cct.CustomerContactId
    WHERE C.IsMigrated = 0  AND CC.EGNNumber IS NULL AND 
	((CCT.ContactType IN ('Representative','Equity Owner','Attorney')) AND C.IsForeigner=0)

	INSERT INTO #ErrorLogs
    SELECT
    	CC.CustomerId
    	,'Error'
        , ('Please Enter Middle Name for Customer contact with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+' and ContactUniqueIdentifier {'+ ISNULL(CC.UniqueIdentifier,'NULL') +'}') AS Message
    FROM
    stgCustomerContact CC
    INNER JOIN stgCustomer C On C.Id = CC.CustomerId 	
    WHERE C.IsMigrated = 0  AND CC.MiddleName IS NULL

	INSERT INTO #ErrorLogs
    SELECT
    	CC.CustomerId
    	,'Error'
        , ('Please Enter EMail for Customer contact with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+' and ContactUniqueIdentifier {'+ ISNULL(CC.UniqueIdentifier,'NULL') +'}') AS Message
    FROM
    stgCustomerContact CC
    INNER JOIN stgCustomer C On C.Id = CC.CustomerId 
	INNER JOIN stgCustomerContactType CCT on CC.Id = cct.CustomerContactId
    WHERE C.IsMigrated = 0  AND CC.EMailId IS NULL AND 
	CCT.ContactType ='Billing'

	INSERT INTO #ErrorLogs
    SELECT
    	CC.CustomerId
    	,'Error'
        , ('Please Enter Phone Number for Customer contact with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+' and ContactUniqueIdentifier {'+ ISNULL(CC.UniqueIdentifier,'NULL') +'}') AS Message
    FROM
    stgCustomerContact CC
    INNER JOIN stgCustomer C On C.Id = CC.CustomerId 
	INNER JOIN stgCustomerContactType CCT on CC.Id = cct.CustomerContactId
    WHERE C.IsMigrated = 0  AND CC.PhoneNumber1 IS NULL AND 
	CCT.ContactType ='Billing'

	INSERT INTO #ErrorLogs
    SELECT
    	CC.CustomerId
    	,'Error'
        , ('Please Enter National Id CardNumber for Customer contact with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+' and ContactUniqueIdentifier {'+ ISNULL(CC.UniqueIdentifier,'NULL') +'}') AS Message
    FROM
    stgCustomerContact CC
    INNER JOIN stgCustomer C On C.Id = CC.CustomerId 
	INNER JOIN stgCustomerContactType CCT on CC.Id = cct.CustomerContactId
    WHERE C.IsMigrated = 0  AND CC.NationalIdCardNumber IS NULL AND 
	((CCT.ContactType IN ('Representative','Equity Owner','Attorney')) AND C.IsForeigner=0)

	INSERT INTO #ErrorLogs
    SELECT
    	CC.CustomerId
    	,'Error'
        , ('Please Enter Id CardNumber for Customer contact with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+' and ContactUniqueIdentifier {'+ ISNULL(CC.UniqueIdentifier,'NULL') +'}') AS Message
    FROM
    stgCustomerContact CC
    INNER JOIN stgCustomer C On C.Id = CC.CustomerId 
	INNER JOIN stgCustomerContactType CCT on CC.Id = cct.CustomerContactId
    WHERE C.IsMigrated = 0  AND CC.IdCardNumber IS NULL AND 
	((CCT.ContactType IN ('Representative','Equity Owner','Attorney')) AND C.IsForeigner=0)

	INSERT INTO #ErrorLogs
    SELECT
    	CC.CustomerId
    	,'Error'
        , ('Please Enter ID Card Issued On for Customer contact with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+' and ContactUniqueIdentifier {'+ ISNULL(CC.UniqueIdentifier,'NULL') +'}') AS Message
    FROM
    stgCustomerContact CC
    INNER JOIN stgCustomer C On C.Id = CC.CustomerId 
	INNER JOIN stgCustomerContactType CCT on CC.Id = cct.CustomerContactId
    WHERE C.IsMigrated = 0  AND CC.IDCardIssuedOn IS NULL AND 
	((CCT.ContactType IN ('Representative','Equity Owner','Attorney')) AND C.IsForeigner=0)

	INSERT INTO #ErrorLogs
    SELECT
    	CC.CustomerId
    	,'Error'
        , ('Please Enter ID Card Issued In for Customer contact with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+' and ContactUniqueIdentifier {'+ ISNULL(CC.UniqueIdentifier,'NULL') +'}') AS Message
    FROM
    stgCustomerContact CC
    INNER JOIN stgCustomer C On C.Id = CC.CustomerId 
	INNER JOIN stgCustomerContactType CCT on CC.Id = cct.CustomerContactId
    WHERE C.IsMigrated = 0  AND CC.IDCardIssuedIn IS NULL AND 
	((CCT.ContactType IN ('Representative','Equity Owner','Attorney')) AND C.IsForeigner=0)

    INSERT INTO #ErrorLogs
    SELECT
    	CC.CustomerId
    	,'Error'
        , ('Please Enter Gender for Customer contact with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+' and ContactUniqueIdentifier {'+ ISNULL(CC.UniqueIdentifier,'NULL') +'}') AS Message
    FROM
    stgCustomerContact CC
    INNER JOIN stgCustomer C On C.Id = CC.CustomerId 
	INNER JOIN stgCustomerContactType CCT on CC.Id = cct.CustomerContactId
    WHERE C.IsMigrated = 0  AND CC.Gender IS NULL AND 
	((CCT.ContactType IN ('Representative','Equity Owner','Attorney')) AND C.IsForeigner=0)

	INSERT INTO #ErrorLogs
    SELECT
    	CC.CustomerId
    	,'Error'
        , ('Please Enter Date Of Birth for Customer contact with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+' and ContactUniqueIdentifier {'+ ISNULL(CC.UniqueIdentifier,'NULL') +'}') AS Message
    FROM
    stgCustomerContact CC
    INNER JOIN stgCustomer C On C.Id = CC.CustomerId 
	INNER JOIN stgCustomerContactType CCT on CC.Id = cct.CustomerContactId
    WHERE C.IsMigrated = 0  AND CC.DateOfBirth IS NULL AND 
	((CCT.ContactType IN ('Representative','Equity Owner','Attorney')) AND C.IsForeigner=0)

	INSERT INTO #ErrorLogs
    SELECT
    	CC.CustomerId
    	,'Error'
        , ('Please Enter LN4 for Customer contact with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+' and ContactUniqueIdentifier {'+ ISNULL(CC.UniqueIdentifier,'NULL') +'}') AS Message
    FROM
    stgCustomerContact CC
    INNER JOIN stgCustomer C On C.Id = CC.CustomerId 	
    WHERE C.IsMigrated = 0  AND CC.Ln4 IS NULL AND 
    CC.IsForeigner=1

	INSERT INTO #ErrorLogs
    SELECT
    	CC.CustomerId
    	,'Error'
        , ('Please Enter Passport Number for Customer contact with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+' and ContactUniqueIdentifier {'+ ISNULL(CC.UniqueIdentifier,'NULL') +'}') AS Message
    FROM
    stgCustomerContact CC
    INNER JOIN stgCustomer C On C.Id = CC.CustomerId 	
    WHERE C.IsMigrated = 0  AND CC.PassportNo IS NULL AND 
    CC.IsForeigner=1

   INSERT INTO #ErrorLogs
    SELECT
    	CC.CustomerId
    	,'Error'
        , ('Please Enter Passport Address for Customer contact with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+' and ContactUniqueIdentifier {'+ ISNULL(CC.UniqueIdentifier,'NULL') +'}') AS Message
    FROM
    stgCustomerContact CC
    INNER JOIN stgCustomer C On C.Id = CC.CustomerId 	
    WHERE C.IsMigrated = 0  AND CC.PassportAddress IS NULL AND 
    CC.IsForeigner=1

	INSERT INTO #ErrorLogs
    SELECT
    	CC.CustomerId
    	,'Error'
        , ('Please Enter Passport Country for Customer contact with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+' and ContactUniqueIdentifier {'+ ISNULL(CC.UniqueIdentifier,'NULL') +'}') AS Message
    FROM
    stgCustomerContact CC
    INNER JOIN stgCustomer C On C.Id = CC.CustomerId 	
    WHERE C.IsMigrated = 0  AND CC.PassportCountry IS NULL AND 
    CC.IsForeigner=1

	INSERT INTO #ErrorLogs
    SELECT
    	CC.CustomerId
    	,'Error'
        , ('Please Enter Date Of Issue for Customer contact with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+' and ContactUniqueIdentifier {'+ ISNULL(CC.UniqueIdentifier,'NULL') +'}') AS Message
    FROM
    stgCustomerContact CC
    INNER JOIN stgCustomer C On C.Id = CC.CustomerId 	
    WHERE C.IsMigrated = 0  AND CC.DateofIssue IS NULL AND 
    CC.IsForeigner=1

	INSERT INTO #ErrorLogs
    SELECT
    	CC.CustomerId
    	,'Error'
        , ('Please Enter Driving License for Customer contact with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+' and ContactUniqueIdentifier {'+ ISNULL(CC.UniqueIdentifier,'NULL') +'}') AS Message
    FROM
    stgCustomerContact CC
    INNER JOIN stgCustomer C On C.Id = CC.CustomerId 
	INNER JOIN stgCustomerContactType CCT on CC.Id = cct.CustomerContactId
    WHERE C.IsMigrated = 0  AND CC.DrivingLicense IS NULL AND 
	CCT.ContactType ='Recipient of the car'

	INSERT INTO #ErrorLogs
    SELECT
    	CC.CustomerId
    	,'Error'
        , ('Please Enter Driving License Issued IN for Customer contact with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+' and ContactUniqueIdentifier {'+ ISNULL(CC.UniqueIdentifier,'NULL') +'}') AS Message
    FROM
    stgCustomerContact CC
    INNER JOIN stgCustomer C On C.Id = CC.CustomerId 
	INNER JOIN stgCustomerContactType CCT on CC.Id = cct.CustomerContactId
    WHERE C.IsMigrated = 0  AND CC.IssuedIn IS NULL AND 
	CCT.ContactType ='Recipient of the car'

	INSERT INTO #ErrorLogs
    SELECT
    	CC.CustomerId
    	,'Error'
        , ('Please Enter Driving License Issued ON for Customer contact with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+' and ContactUniqueIdentifier {'+ ISNULL(CC.UniqueIdentifier,'NULL') +'}') AS Message
    FROM
    stgCustomerContact CC
    INNER JOIN stgCustomer C On C.Id = CC.CustomerId 
	INNER JOIN stgCustomerContactType CCT on CC.Id = cct.CustomerContactId
    WHERE C.IsMigrated = 0  AND CC.IssuedOn IS NULL AND 
	CCT.ContactType ='Recipient of the car'

	INSERT INTO #ErrorLogs
    SELECT
    	CC.CustomerId
    	,'Error'
        , ('Please Enter Driving License Validity for Customer contact with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+' and ContactUniqueIdentifier {'+ ISNULL(CC.UniqueIdentifier,'NULL') +'}') AS Message
    FROM
    stgCustomerContact CC
    INNER JOIN stgCustomer C On C.Id = CC.CustomerId 
	INNER JOIN stgCustomerContactType CCT on CC.Id = cct.CustomerContactId
    WHERE C.IsMigrated = 0  AND CC.Validity IS NULL AND 
	CCT.ContactType ='Recipient of the car'

	INSERT INTO #ErrorLogs
    SELECT
    	CC.CustomerId
    	,'Error'
        , ('Please Enter Power Of Attorney Number for Customer contact with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+' and ContactUniqueIdentifier {'+ ISNULL(CC.UniqueIdentifier,'NULL') +'}') AS Message
    FROM
    stgCustomerContact CC
    INNER JOIN stgCustomer C On C.Id = CC.CustomerId 
	INNER JOIN stgCustomerContactType CCT on CC.Id = cct.CustomerContactId
    WHERE C.IsMigrated = 0  AND CC.PowerOfAttorneyNumber IS NULL AND 
	CCT.ContactType ='Attorney'

	INSERT INTO #ErrorLogs
    SELECT
    	CC.CustomerId
    	,'Error'
        , ('Please Enter Power Of Attorney Validity for Customer contact with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+' and ContactUniqueIdentifier {'+ ISNULL(CC.UniqueIdentifier,'NULL') +'}') AS Message
    FROM
    stgCustomerContact CC
    INNER JOIN stgCustomer C On C.Id = CC.CustomerId 
	INNER JOIN stgCustomerContactType CCT on CC.Id = cct.CustomerContactId
    WHERE C.IsMigrated = 0  AND CC.PowerOfAttorneyValidity IS NULL AND 
	CCT.ContactType ='Attorney'

	INSERT INTO #ErrorLogs
    SELECT
    	CC.CustomerId
    	,'Error'
        , ('Please Enter Notary for Customer contact with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+' and ContactUniqueIdentifier {'+ ISNULL(CC.UniqueIdentifier,'NULL') +'}') AS Message
    FROM
    stgCustomerContact CC
    INNER JOIN stgCustomer C On C.Id = CC.CustomerId 
	INNER JOIN stgCustomerContactType CCT on CC.Id = cct.CustomerContactId
    WHERE C.IsMigrated = 0  AND CC.Notary IS NULL AND 
	CCT.ContactType ='Attorney'

	INSERT INTO #ErrorLogs
    SELECT
    	CC.CustomerId
    	,'Error'
        , ('Please Enter Registaration # Of Notary for Customer contact with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+' and ContactUniqueIdentifier {'+ ISNULL(CC.UniqueIdentifier,'NULL') +'}') AS Message
    FROM
    stgCustomerContact CC
    INNER JOIN stgCustomer C On C.Id = CC.CustomerId 
	INNER JOIN stgCustomerContactType CCT on CC.Id = cct.CustomerContactId
    WHERE C.IsMigrated = 0  AND CC.RegistarationNoOfNotary IS NULL AND 
	CCT.ContactType ='Attorney'

SELECT
	*
INTO #ErrorLogDetails
FROM #ErrorLogs ORDER BY StagingRootEntityId ;
		CREATE TABLE #ProcessedCustomer
		(
			CustomerID BIGINT
		);

DECLARE @TotalValidRecords BIGINT =  @TotalRecordsCount - (SELECT COUNT(DISTINCT StagingRootEntityId) FROM #ErrorLogDetails);

WHILE @SkipCount < @TotalValidRecords
BEGIN
        SELECT
			TOP(@TakeCount) 
			C.*
		INTO #Customers
		FROM
		stgCustomer C
		WHERE 
			IsMigrated = 0        
 		   AND 
			C.Id  NOT IN (Select CustomerID from #ProcessedCustomer)
			AND 
			C.Id NOT IN (SELECT StagingRootEntityId FROM #ErrorLogDetails) Order by C.ParentCustomerNumber	
			SELECT @BatchCount = ISNULL(COUNT(Id),0) FROM #Customers
        DECLARE @ParentCount BIGINT
		DECLARE @ChildCount  BIGINT
		DECLARE @IncorrectParentNumber BIGINT = 0;
		Select @ChildCount=Count(*) from #Customers where ParentCustomerNumber is not NULL
		Select @ParentCount=Count(*) from #Customers where ParentCustomerNumber is NULL
		if(@ParentCount>0 and @ChildCount>0)
		BEGIN
		Delete from #Customers where ParentCustomerNumber is not NULL
		Set @ChildCount=0
		END
		Insert Into #ProcessedCustomer(CustomerID) Select Id From #Customers
		If(@ChildCount>0)
		 BEGIN
			UPDATE #Customers Set R_ParentPartyId = Parties.Id
			FROM #Customers C
			INNER JOIN Parties WITH(NOLOCK) ON Parties.PartyNumber = C.ParentCustomerNumber
			WHERE C.IsMigrated = 0 AND c.ParentCustomerNumber Is NOT NULL ;  
		    INSERT INTO #ErrorLogDetails
		    SELECT 
			C.Id
			,'Error'
			,('Invalid Parent Customer for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
		    FROM #Customers C
		    WHERE IsMigrated = 0 AND C.ParentCustomerNumber IS NOT NULL AND C.R_ParentPartyId IS NULL;
			DELETE C
			from #Customers C inner join 
			#ErrorLogDetails E on C.Id=E.StagingRootEntityId
			SET @IncorrectParentNumber = @@ROWCOUNT;
		  END
BEGIN TRY  
BEGIN TRANSACTION
		CREATE TABLE #CreatedCustomers
		(
			[Id] BIGINT NOT NULL
			,[CustomerId] BIGINT NOT NULL
		);
		CREATE TABLE #CreatedPartyContactIds 
		(
			[Id] bigint NOT NULL,
			[CustomerContactId] bigint NOT NULL
		);
		CREATE TABLE #CreatedBankAccountIds 
		(
			[Id] bigint NOT NULL,
			[CustomerBankAccountId] bigint NOT NULL,
			[AccountNumber] NVARCHAR(50),
		    [CustomerId] bigint,
			[BankBranchId] bigint
		);
		CREATE TABLE #CreatedTaxExemptRuleId
		(  
			InsertedId BIGINT,
			CustomerId BIGINT
		);
		CREATE TABLE #CreatedConsentDetails
		(  
			Id BIGINT,
			CustomerId BIGINT
		);
		CREATE TABLE #CreatedContactConsentDetails
		(  
			Id BIGINT,
			CustomerContactId BIGINT
		);
		CREATE TABLE #CreatedProcessingLogs 
		(
			[Id] bigint NOT NULL
		);
		CREATE TABLE #CustomerPaymentThresholdValues
		(
			BankAccountNumber NVARCHAR(100) NOT NULL,
			CustomerId BIGINT NOT NULL
		);
	MERGE Parties 
	USING(Select * FROM #Customers) AS CustomersToMigrate
	ON 1=0
	WHEN NOT MATCHED
	THEN
	INSERT
	(
		[PartyNumber]
		,[IsCorporate]
		,[FirstName]
		,[LastName]
		,[CompanyName]
		,[PartyName]
		,[Alias]
		,[DateOfBirth]
		,[DoingBusinessAs]
		,[CreationDate]
		,[IncorporationDate]
		,[CurrentRole]
		,[CreatedById]
		,[CreatedTime]
		,[ParentPartyId]
		,[IsSoleProprietor]
		,[StateOfIncorporationId]
		,[IsIntercompany]
		,[ExternalPartyNumber]
		,[LanguageId]
		,[UniqueIdentificationNumber_CT]
		,[VATRegistrationNumber]
		,[MiddleName]
		,[PartyEntityType]
		,[LastFourDigitUniqueIdentificationNumber]
		,[PortfolioId]
		,[Suffix]
		,[EIKNumber_CT]
		,WayOfRepresentation
		,Representative1
		,Representative2
		,Representative3
		,IsVATRegistration
		,VATRegistration
		,NationalIdCardNumber_CT
		,DateofIssueID
		,IssuedIn
		,Gender
		,IsForeigner
		,Ln4
		,PassportNo
		,DateofIssue
		,PassportCountry
		,PassportAddress
		,IsSpecialClient
		,EquityOwnerEGN1
		,EquityOwnerEGN2
		,EquityOwnerEGN3
		,CustomerLegalStatusId
		,SectorId
		,ProfessionsId
		,Email
	)
	VALUES
	(
		CustomersToMigrate.[CustomerNumber]
		,CustomersToMigrate.[IsCorporate]
		,CASE WHEN (CustomersToMigrate.[IsCorporate] = 0 OR (CustomersToMigrate.[IsCorporate] = 1 AND CustomersToMigrate.[IsSoleProprietor]=1)) THEN CustomersToMigrate.[FirstName] ELSE NULL END
		,CASE WHEN (CustomersToMigrate.[IsCorporate] = 0 OR (CustomersToMigrate.[IsCorporate] = 1 AND CustomersToMigrate.[IsSoleProprietor]=1)) THEN CustomersToMigrate.[LastName] ELSE NULL END
		,CASE WHEN (CustomersToMigrate.[IsCorporate] = 1 AND CustomersToMigrate.IsSoleProprietor=0) THEN CustomersToMigrate.[CompanyName] ELSE NULL END
		,CASE WHEN (CustomersToMigrate.[IsCorporate] = 1 AND CustomersToMigrate.IsSoleProprietor=0) THEN CustomersToMigrate.[CompanyName] ELSE (CustomersToMigrate.[FirstName] + (IIF((ISNULL(CustomersToMigrate.[MiddleName], '') = ''), '', (' ' + CustomersToMigrate.[MiddleName]))) + (' ' + CustomersToMigrate.[LastName]) + (IIF((ISNULL(CustomersToMigrate.[Suffix], '') = ''), '', (' ' + CustomersToMigrate.[Suffix]))))  END
		,CustomersToMigrate.[Alias]
		,CASE WHEN ((CustomersToMigrate.[IsCorporate] = 1 AND CustomersToMigrate.[IsSoleProprietor] = 1) OR (CustomersToMigrate.[IsCorporate] = 0 AND CustomersToMigrate.[IsSoleProprietor] = 0)) THEN CustomersToMigrate.[DateOfBirth] ELSE NULL END
		,NULL
		,CustomersToMigrate.[CreationDate]
		,CASE WHEN CustomersToMigrate.[IsCorporate] = 1 THEN CustomersToMigrate.[IncorporationDate] ELSE NULL END
		,'Customer'
		,@UserId
		,@CreatedTime
		,CustomersToMigrate.[R_ParentPartyId]
		,CustomersToMigrate.IsSoleProprietor
		,CustomersToMigrate.R_StateOfIncorporationId
		,CustomersToMigrate.IsIntercompany
		,ExternalPartyNumber
		,R_LanguageConfigId
		,CASE WHEN CustomersToMigrate.EGNNumber IS NOT NULL THEN [dbo].[Encrypt]('nvarchar',CustomersToMigrate.EGNNumber, 'M4WHMOVTTT74UP6EL71GWMU4NTXQLLN5') ELSE NULL END
		--,CASE WHEN CustomersToMigrate.[IsCorporate] = 1 THEN CONVERT(VARBINARY,CustomersToMigrate.TaxId) ELSE CONVERT(VARBINARY,CustomersToMigrate.SocialSecurityNumber)  END
		,VATRegistrationNumber
		,CustomersToMigrate.MiddleName
		,'_'
		,CASE WHEN CustomersToMigrate.EGNNumber IS NOT NULL AND LEN(CustomersToMigrate.EGNNumber) > 4 THEN SUBSTRING(CustomersToMigrate.EGNNumber,LEN(CustomersToMigrate.EGNNumber) - 3,4) ELSE NULL END
		,CustomersToMigrate.R_PortfolioId
		,CustomersToMigrate.[Suffix]
		,CASE WHEN CustomersToMigrate.EIKNumber IS NOT NULL THEN [dbo].[Encrypt]('nvarchar',CustomersToMigrate.EIKNumber, 'M4WHMOVTTT74UP6EL71GWMU4NTXQLLN5') ELSE NULL END
		,CustomersToMigrate.WayOfRepresentation
		,CustomersToMigrate.Representative1
		,CustomersToMigrate.Representative2
		,CustomersToMigrate.Representative3
		,CustomersToMigrate.IsVATRegistration
		,CustomersToMigrate.VATRegistration
		,CASE WHEN CustomersToMigrate.NationalIdCardNumber IS NOT NULL THEN [dbo].[Encrypt]('nvarchar',CustomersToMigrate.NationalIdCardNumber, 'M4WHMOVTTT74UP6EL71GWMU4NTXQLLN5') ELSE NULL END
		,CustomersToMigrate.DateofIssueID
		,CustomersToMigrate.IssuedIn
		,CustomersToMigrate.Gender
		,CustomersToMigrate.IsForeigner
		,CustomersToMigrate.Ln4
		,CustomersToMigrate.PassportNo
		,CustomersToMigrate.DateofIssue
		,CustomersToMigrate.PassportCountry
		,CustomersToMigrate.PassportAddress
		,CustomersToMigrate.IsSpecialClient
		,CustomersToMigrate.EquityOwnerEGN1
		,CustomersToMigrate.EquityOwnerEGN2
		,CustomersToMigrate.EquityOwnerEGN3
		,CustomersToMigrate.R_CustomerLegalStatus
		,CustomersToMigrate.R_Sector
		,CustomersToMigrate.R_Profession
		,CustomersToMigrate.Email
	)
	OUTPUT  Inserted.Id, CustomersToMigrate.Id INTO #CreatedCustomers;	
	INSERT INTO [dbo].[PartyRoles]
		(
		[Role]
		,[CreatedById]
		,[CreatedTime]
		,[PartyId]
		)
	SELECT
		'Customer'
		,@UserId
		,@CreatedTime
		,#CreatedCustomers.Id
	FROM #CreatedCustomers
	INSERT INTO [dbo].[PartyAddresses]
				([UniqueIdentifier]
				,[AddressLine1]
				,[AddressLine2]
				,[City]
				,[PostalCode]
				,[Description]
				,[IsActive]
				,[IsMain]
				,[CreatedById]
				,[CreatedTime]
				,[StateId]
				,[PartyId]
				,[Division]
				,[HomeAddressLine1]
				,[HomeAddressLine2]
				,[HomeCity]
				,[HomeDivision]
				,[HomePostalCode]
				,[HomeStateId]
				,[IsHeadquarter]
				,[AddressLine3]
				,[Neighborhood]
				,[SubdivisionOrMunicipality]
				,[HomeAddressLine3]
				,[HomeNeighborhood]
				,[HomeSubdivisionOrMunicipality]
				,[AttentionTo]
				,[IsForDocumentation]
				,[SFDCAddressId]
				,[IsCreateLocation]
				,Settlement
				,HomeSettlement
				,HomeAttentionTo
				,IsCompanyHeadquartersPermanentAddress
				)
			SELECT
				CustomerAddress.[UniqueIdentifier]
				,CustomerAddress.[AddressLine1]
				,CustomerAddress.[AddressLine2]
				,CustomerAddress.[City]
				,CustomerAddress.[PostalCode]
				,CustomerAddress.[Description]
				,1
				,CustomerAddress.[IsMain]
				,@UserId
				,@CreatedTime
				,CustomerAddress.[R_StateId]
				,#CreatedCustomers.Id
				,CustomerAddress.Division
				,CustomerAddress.HomeAddressLine1
				,CustomerAddress.HomeAddressLine2
				,CustomerAddress.HomeCity
				,CustomerAddress.HomeDivision
				,CustomerAddress.HomePostalCode
				,CustomerAddress.R_HomeStateId
				,CustomerAddress.IsHeadquarter
				,CustomerAddress.AddressLine3
				,CustomerAddress.Neighborhood
				,CustomerAddress.SubdivisionOrMunicipality
				,CustomerAddress.HomeAddressLine3
				,CustomerAddress.HomeNeighborhood
				,CustomerAddress.HomeSubdivisionOrMunicipality
				,CustomerAddress.AttentionTo
				,CustomerAddress.IsForDocumentation
				,CustomerAddress.SFDCAddressId
				,0
                ,CustomerAddress.Settlement
				,CustomerAddress.HomeSettlement
				,CustomerAddress.HomeAttentionTo
				,CustomerAddress.IsCompanyHeadquartersPermanentAddress
			FROM stgCustomerAddress CustomerAddress
			INNER JOIN #CreatedCustomers ON #CreatedCustomers.CustomerId = CustomerAddress.CustomerId			
			MERGE PartyContacts AS PartyContact
			USING (SELECT CC.*, #CreatedCustomers.Id As PartyId, PA.Id AS PartyAddressId FROM stgCustomerContact CC
					INNER JOIN #CreatedCustomers ON #CreatedCustomers.CustomerId = CC.CustomerId
					INNER JOIN stgCustomer C ON C.Id = CC.CustomerId
					LEFT JOIN PartyAddresses PA ON PA.UniqueIdentifier = CC.AddressUniqueIdentifier
					) AS CustomerContactToMigrate
			ON (1=0)
			WHEN NOT MATCHED
			THEN		
			INSERT 
			   ([UniqueIdentifier]
			   ,[Prefix]
			   ,[FirstName]
			   ,[MiddleName]
			   ,[LastName]
			   ,[FullName]
			   ,[DateOfBirth]
			   ,[OwnershipPercentage]
			   ,[EMailId]
			   ,[PhoneNumber1]
			   ,[ExtensionNumber1]
			   ,[PhoneNumber2]
			   ,[ExtensionNumber2]
			   ,[MobilePhoneNumber]
			   ,[FaxNumber]	   
			   ,[Description]
			   ,[MailingAddressId]
			   ,[IsActive]
			   ,[CreatedById]
			   ,[CreatedTime]
			   ,[PartyId]
			   ,[MortgageHighCredit_Amount]
			   ,[MortgageHighCredit_Currency]
			   ,[IsSCRA]
			   ,[SCRAStartDate]
			   ,[SCRAEndDate]
			   ,[IsFromAssumption]
			   ,[IsAssumptionApproved]
			   ,[CIPDocumentSourceNameId]		
			   ,[CIPDocumentSourceForAddress]
			   ,[CIPDocumentSourceForTaxIdOrSSN]
			   ,[BenefitsAndProtection]
			   ,[SFDCContactId]
			   ,[IsBookingNotificationAllowed]
			   ,[IsCreditNotificationAllowed]
			   ,[SocialSecurityNumber_CT]
			   ,[LastFourDigitSocialSecurityNumber]
			   ,[LastName2]
			   ,[ParalegalName]
			   ,[SecretaryName]
			   ,[Webpage]
			   ,[CIPDocumentSourceForName]
               ,[BusinessStartTimeInHours]
			   ,[BusinessEndTimeInHours]
			   ,[BusinessStartTimeInMinutes]
			   ,[BusinessEndTimeInMinutes]
               ,[TimeZoneId]
			   ,[EGNNumber_CT]
			   ,DrivingLicense
			   ,IssuedOn
			   ,IssuedIn
			   ,Validity
			   ,Foreigner
			   ,IDCardNumber
			   ,IDCardIssuedOn
			   ,IDCardIssuedIn
			   ,Gender
			   ,LN4
			   ,PassportNo
			   ,PassportIssuedOn
			   ,PassportCountry
			   ,PassportAddress
			   ,EMail2
			   ,PowerOfAttorneyNumber
			   ,PowerOfAttorneyValidity
			   ,Notary
			   ,RegistarationNoOfNotary
			   ,NationalIDCardNumber_CT
			   )
			VALUES
			   (
				   CustomerContactToMigrate.[UniqueIdentifier]
				  ,CustomerContactToMigrate.[Prefix]
				  ,CustomerContactToMigrate.[FirstName]
				  ,CustomerContactToMigrate.[MiddleName]
				  ,CustomerContactToMigrate.[LastName]
				  ,CustomerContactToMigrate.[FirstName] + ' ' + ISNULL(CustomerContactToMigrate.[MiddleName],'') + IIF(CustomerContactToMigrate.[MiddleName] IS NOT NULL,' ','') + CustomerContactToMigrate.[LastName]
				  ,CustomerContactToMigrate.[DateOfBirth]
				  ,CustomerContactToMigrate.[OwnershipPercentage]
				  ,CustomerContactToMigrate.[EmailId]
				  ,CustomerContactToMigrate.[PhoneNumber1]
				  ,CustomerContactToMigrate.[ExtensionNumber1]
				  ,CustomerContactToMigrate.[PhoneNumber2]
				  ,CustomerContactToMigrate.[ExtensionNumber2]
				  ,CustomerContactToMigrate.[MobilePhoneNumber]
				  ,CustomerContactToMigrate.[FaxNumber]
				  ,CustomerContactToMigrate.[Description]
				  ,CustomerContactToMigrate.PartyAddressID
				  ,1
				  ,@UserId
				  ,@CreatedTime
				  ,CustomerContactToMigrate.PartyId
				  ,0.0
				  ,'USD'
				  ,CustomerContactToMigrate.IsSCRA
				  ,CustomerContactToMigrate.[SCRAStartDate]
				  ,CustomerContactToMigrate.[SCRAEndDate]
				  ,0
				  ,0
				  ,NULL
				  ,'_'
				  ,'_'
				  ,CustomerContactToMigrate.BenefitsAndProtection
				  ,CustomerContactToMigrate.SFDCContactId
				  ,0
				  ,0
				  ,CASE WHEN CustomerContactToMigrate.SocialSecurityNumber Is NOT NULL THEN [dbo].[Encrypt]('nvarchar',CustomerContactToMigrate.SocialSecurityNumber, 'M4WHMOVTTT74UP6EL71GWMU4NTXQLLN5') ELSE NULL  END
				  ,CASE WHEN LEN(Replace(CustomerContactToMigrate.SocialSecurityNumber,'-','')) >= 4 THEN RIGHT(Replace(CustomerContactToMigrate.SocialSecurityNumber,'-',''),4) ELSE NULL END
				  ,CustomerContactToMigrate.LastName2
				  ,CustomerContactToMigrate.ParalegalName
				  ,CustomerContactToMigrate.SecretaryName
				  ,CustomerContactToMigrate.Webpage
				  ,'_' 
				  ,CustomerContactToMigrate.BusinessStartTimeInHours
				  ,CustomerContactToMigrate.BusinessEndTimeInHours
				  ,CustomerContactToMigrate.BusinessStartTimeInMinutes
				  ,CustomerContactToMigrate.BusinessEndTimeInMinutes
				  ,CustomerContactToMigrate.R_TimeZoneId
				  ,CASE WHEN CustomerContactToMigrate.EGNNumber Is NOT NULL THEN [dbo].[Encrypt]('nvarchar',CustomerContactToMigrate.EGNNumber, 'M4WHMOVTTT74UP6EL71GWMU4NTXQLLN5') ELSE NULL  END
				  ,CustomerContactToMigrate.DrivingLicense
			      ,CustomerContactToMigrate.IssuedOn
			      ,CustomerContactToMigrate.IssuedIn
			      ,CustomerContactToMigrate.Validity
			      ,CustomerContactToMigrate.IsForeigner
			      ,CustomerContactToMigrate.IDCardNumber
			      ,CustomerContactToMigrate.IDCardIssuedOn
			      ,CustomerContactToMigrate.IDCardIssuedIn
			      ,CustomerContactToMigrate.Gender
			      ,CustomerContactToMigrate.LN4
			      ,CustomerContactToMigrate.PassportNo
			      ,CustomerContactToMigrate.DateofIssue
			      ,CustomerContactToMigrate.PassportCountry
			      ,CustomerContactToMigrate.PassportAddress
			      ,CustomerContactToMigrate.EMail2
			      ,CustomerContactToMigrate.PowerOfAttorneyNumber
			      ,CustomerContactToMigrate.PowerOfAttorneyValidity
			      ,CustomerContactToMigrate.Notary
			      ,CustomerContactToMigrate.RegistarationNoOfNotary
				  ,CASE WHEN CustomerContactToMigrate.NationalIDCardNumber Is NOT NULL THEN [dbo].[Encrypt]('nvarchar',CustomerContactToMigrate.NationalIDCardNumber, 'M4WHMOVTTT74UP6EL71GWMU4NTXQLLN5') ELSE NULL  END
			  )
			  OUTPUT  Inserted.Id, CustomerContactToMigrate.Id INTO #CreatedPartyContactIds;
			  INSERT INTO [dbo].[PartyContactTypes]
				  (
					[IsActive]
					,[ContactType]
					,[CreatedById]
					,[CreatedTime]
					,[PartyContactId]
					,[IsForDocumentation]
				   )
			  SELECT
			   1
			  ,CCT.[ContactType]
			  ,@UserId
			  ,@CreatedTime
			  ,#CreatedPartyContactIds.Id
			  ,CCT.IsForDocumentation
			FROM stgCustomerContactType CCT
			INNER JOIN #CreatedPartyContactIds ON CCT.CustomerContactId = #CreatedPartyContactIds.CustomerContactId	
			MERGE BankAccounts AS BankAccount
			USING (
					SELECT
						CBA.*
				    FROM stgCustomerBankAccount CBA
				    INNER JOIN #CreatedCustomers ON #CreatedCustomers.CustomerId = CBA.CustomerId
				  ) AS CustomerBankAccountToMigrate
			ON (1=0)
			WHEN MATCHED THEN
				UPDATE SET [AccountName] = CustomerBankAccountToMigrate.[AccountName]
			WHEN NOT MATCHED  
			THEN
			INSERT 
			   ([AccountName]
			   ,[AccountNumber_CT]
			   ,[AutomatedPaymentMethod]
			   ,[IsOneTimeACHOnly]
			   ,[IsExpired]
			   ,[IsOwnersAuthorizationReceived]
			   ,[BankBranchId]
			   ,[ReceiptGLTemplateId]
			   ,[CurrencyId]
			   ,[IsPrimaryACH]
			   ,[IsActive]
			   ,[DefaultToAP]
			   ,[CreatedById]
			   ,[CreatedTime]
			   ,[IBAN]
			   ,[AccountType]
			   ,[GLSegmentValue]
			   ,[IsFromCustomerPortal]
			   ,[UniqueIdentifier]
			   ,[LastFourDigitAccountNumber]
			   ,[RemittanceType]
			   ,[DefaultAccountFor]
			   ,[BankAccountCategoryId]
			   ,[PaymentProfileId]
			   ,[ACHFailureCount]
			   ,[OnHold]
			   ,[AccountOnHoldCount]
			   )
			VALUES
			   (CustomerBankAccountToMigrate.[AccountName]
			   ,[dbo].[Encrypt]('nvarchar',CustomerBankAccountToMigrate.AccountNumber, 'M4WHMOVTTT74UP6EL71GWMU4NTXQLLN5') 
			   ,CustomerBankAccountToMigrate.[AutomatedPaymentMethod]
			   ,0
			   ,0
			   ,0
			   ,CustomerBankAccountToMigrate.[R_BankBranchId]
			   ,NULL
			   ,CustomerBankAccountToMigrate.[R_CurrencyId]
			   ,CustomerBankAccountToMigrate.[IsPrimaryACH]
			   ,1
			   ,0
			   ,@UserId
			   ,@CreatedTime
			   ,CustomerBankAccountToMigrate.IBAN
			   ,'_'
			   ,CustomerBankAccountToMigrate.GLSegmentValue
			   ,0	
			   ,CustomerBankAccountToMigrate.UniqueIdentifier
			   ,CASE WHEN LEN(AccountNumber) > 4 THEN SUBSTRING(AccountNumber,LEN(AccountNumber) - 3,4) ELSE AccountNumber END
			   ,'Check'
			   ,'Check'
			   ,[R_BankAccountCategoryId]
			   ,[PaymentProfileId]
			   ,[ACHFailureCount]
			   ,[OnHold]
			   ,[AccountOnHoldCount]
			   )
			   OUTPUT  Inserted.Id, CustomerBankAccountToMigrate.Id, ISNULL(CustomerBankAccountToMigrate.AccountNumber,CustomerBankAccountToMigrate.PaymentProfileId),CustomerBankAccountToMigrate.CustomerId,CustomerBankAccountToMigrate.R_BankBranchId INTO #CreatedBankAccountIds;
			   INSERT INTO PartyBankAccounts
				(
					PartyId
					,BankAccountId
					,CreatedById
					,CreatedTime 
				)
				SELECT
					#CreatedCustomers.Id
				   ,BankId.Id
				   ,@UserId
				   ,@CreatedTime
				FROM stgCustomerBankAccount CustomerBankAccount
				INNER JOIN #CreatedCustomers
						ON CustomerBankAccount.CustomerId = #CreatedCustomers.CustomerId
				INNER JOIN #CreatedBankAccountIds BankId
					ON CustomerBankAccount.Id = BankId.CustomerBankAccountId
			MERGE dbo.TaxExemptRules AS taxExempt
			USING (select #CreatedCustomers.Id,C.Id As CustomerId,C.IsCountryTaxExempt,C.IsStateTaxExempt, C.R_CountryTaxExemptionReasonId,C.IsCountyTaxExempt,C.IsCityTaxExempt, R_StateTaxExemptionReasonId, StateExemptionNumber, CountryExemptionNumber from stgCustomer C
					INNER JOIN #CreatedCustomers ON #CreatedCustomers.CustomerId = C.Id)  AS customer
			ON (1=2)
			WHEN NOT MATCHED THEN
			INSERT
			(
				EntityType
				,IsCountryTaxExempt
				,IsStateTaxExempt
				,CreatedById
				,CreatedTime
				,TaxExemptionReasonId
				,StateTaxExemptionReasonId
				,IsCountyTaxExempt
				,IsCityTaxExempt
				,StateExemptionNumber
				,CountryExemptionNumber
			)
			VALUES
			(
				 'Customer'
				,ISNULL(IsCountryTaxExempt,0)
				,ISNULL(IsStateTaxExempt,0)
				,1
				,@CreatedTime
				,R_CountryTaxExemptionReasonId
				,R_StateTaxExemptionReasonId
				,ISNULL(IsCountyTaxExempt,0)
				,ISNULL(IsCityTaxExempt,0)
				,StateExemptionNumber
				,CountryExemptionNumber
			)
			OUTPUT  INSERTED.Id,customer.CustomerId  INTO #CreatedTaxExemptRuleId;
			INSERT INTO [dbo].[Customers]
			(	
				[Id]
			   ,[Status]
			   ,[ActivationDate]
			   ,[IsLienFilingRequired]
			   ,[OrganizationID]
			   ,[OwnershipPattern]
			   ,[IsNSFChargeEligible]
			   ,[InvoiceTransitDays]
			   ,[InvoiceBillingCycle]
			   ,[InvoiceGraceDays]
			   ,[InvoiceLeadDays]
			   ,[InvoiceComment]
			   ,[IsConsolidated]
			   ,[DeliverInvoiceViaMail]
			   ,[DeliverInvoiceViaEmail]
			   ,[InvoiceEmailTo]
			   ,[InvoiceEmailCC]
			   ,[InvoiceEmailBCC]
			   ,[LateFeeTemplateId]
			   ,[CreatedById]
			   ,[CreatedTime]
			   ,[BankCreditExposureDirect_Amount]
			   ,[BankCreditExposureDirect_Currency]
			   ,[BankCreditExposureIndirect_Amount]
			   ,[BankCreditExposureIndirect_Currency]
			   ,[RevenueAmount_Amount]
			   ,[RevenueAmount_Currency]
			   ,[IsBankrupt]
			   ,[DebtRatio]
			   ,[IsSCRA]
			   ,[SCRAStartDate]
			   ,[SCRAEndDate]
			   ,[OriginationSourceType]
			   ,CIPDocumentSourceNameId
			   ,[CIPDocumentSourceForAddress]
			   ,[CIPDocumentSourceForTaxIdOrSSN]
			   ,[BankLendingStrategy]
			   ,[EFLendingStrategy]
			   ,[Comment]
			   ,[LoanReviewDueDate]
			   ,[LoanReviewResponsibility]
			   ,[LoanReviewCompletedDate]
			   ,[LoanReviewCompletedBy]
			   ,[BankCreditExposureDate]
			   ,[ObligorRating]
			   ,[StockSymbol]
			   ,[OwnershipType]
			   ,[BenefitsAndProtection]
			   ,[IsPreACHNotification]
			   ,[PreACHNotificationEmailTo]
			   ,[IsPostACHNotification]
			   ,[PostACHNotificationEmailTo]
			   ,[IsReturnACHNotification]
			   ,[ReturnACHNotificationEmailTo]
			   ,[BusinessTypeId]
			   ,[ReceiptHierarchyTemplateId]
			   ,[CustomerClassId]
			   ,[ClabeNumber]
			   ,[IsBuyer]
			   ,[IsCustomerPortalAccessBlock]
			   ,[IsPEP]
			   ,[IsHNW]
			   ,[AlsoKnownAs]
			   ,[SalesForceCustomerName]
			   ,[LegalNameValidationDate]
			   ,[CompanyURL]
			   ,[PartyType]
			   ,[IsMaterialAndRelevantPEP]
			   ,[IsMaterialAndRelevantAdverseMedia]
			   ,[CustomerRiskRating]
			   ,[CustomerRiskRatingScore]
			   ,[CustomerRiskRatingDates]
			   ,[PercentageOfGovernmentOwnership]
			   ,[ApprovedExchangeId]
			   ,[ApprovedRegulatorId]
			   ,[AnnualCreditReviewDate]
			   ,[ExtensionDate]
			   ,[PrimaryBusinessLevel1]
			   ,[TypeLevel2]
			   ,[FacilitiesLevel4]
			   ,[OtherMiscLevel5]
			   ,[ManagementLevel6]
			   ,[OwnershipLevel7]
			   ,[IncomeTaxStatus]
			   ,[IsEPSMaster]
			   ,[MedicalSpecialityId]
			   ,[JurisdictionOfSovereignId]			  
			   ,[SFDCId]
			   ,[PreACHNotificationEmailTemplateId]	
	           ,[PostACHNotificationEmailTemplateId]			   
			   ,[ReturnACHNotificationEmailTemplateId]			   
			   ,BaselRetail
			   ,MonthsInBusiness
			   ,MonthsAsOwner
			   ,NumberOfBeds
			   ,OccupancyRate
			   ,SameDayCreditApprovals_Amount
			   ,SameDayCreditApprovals_Currency
			   ,ReplacementAmount_Amount
			   ,ReplacementAmount_Currency
			   ,PricingIndicator
			   ,TaxExemptRuleId
			   ,[LegalFormationTypeConfigId]
			   ,IsLimitedDisclosureParty
			   ,Prospect
			   ,Priority	
			   ,CreditScore		
			   ,IsBureauReportingExempt
			   ,IsNonAccrualExempt
			   ,IsManualReviewRequired
			   ,IsFinancialDocumentRequired
			   ,ConsentDate
			   ,BusinessTypeNAICSCodeId
			   ,BusinessTypesSICsCodeId
			   ,InvoiceCommentBeginDate
			   ,InvoiceCommentEndDate
			   ,CIPDocumentSourceForName
			   ,FinancialDate
			   ,FinancialExpectedDate
			   ,CreditReviewFrequency
			   ,CollectionStatusId
			   ,IsRelatedToLessor
			   ,NextReviewDate
			   ,FiscalYearEndMonth
			   ,IsWithholdingTaxApplicable
			   ,IsRelatedtoPEP
			   ,ParentPartyName
			   ,ParentPartyEIK
			   ,IsNotificationviaPhone
			   ,IsNotificationviaSMS
			   ,IsNotificationviaEMail
			 )
		     SELECT
			   #CreatedCustomers.Id
			   ,Customer.[Status]
			   ,Customer.[ActivationDate]
			   ,Customer.[IsLienFilingRequired]
			   ,Customer.[OrganizationID]
			   ,'_'
			   ,Customer.[IsNSFChargeEligible]
			   ,Customer.[InvoiceTransitDays]
			   ,0
			   ,Customer.[InvoiceGraceDays]
			   ,Customer.[InvoiceLeadDays]
			   ,Customer.[InvoiceComment]
			   ,Customer.[IsConsolidated]
			   ,Customer.[DeliverInvoiceViaMail]
			   ,Customer.[DeliverInvoiceViaEmail]
			   ,Customer.[InvoiceEmailTo]
			   ,Customer.[InvoiceEmailCC]
			   ,Customer.[InvoiceEmailBCC]
			   ,Customer.[R_LateFeeTemplateId]
			   ,@UserId
			   ,@CreatedTime
			   ,0.0
			   ,'USD'
			   ,0.0
			   ,'USD'
			   ,0.00
			   ,'USD'
			   ,Customer.[IsBankrupt]
			   ,0.00
			   ,Customer.[IsSCRA]
			   ,Customer.[SCRAStartDate]
			   ,Customer.[SCRAEndDate]
			   ,'_'
			   ,Customer.R_CIPDocumentSourceId
			   ,Customer.[CIPDocumentSourceForAddress]
			   ,Customer.[CIPDocumentSourceForTaxIdOrSSN]
			   ,'_'
			   ,'_'
			   ,Customer.[Comment]
			   ,Null
			   ,'_'
			   ,Null
			   ,'_'
			   ,NULL
			   ,'_'
			   ,Customer.[StockSymbol]
			   ,Customer.[OwnershipType]
			   ,Customer.[BenefitsAndProtection]
			   ,Customer.[IsPreACHNotification]
			   ,Customer.[PreACHNotificationEmailTo]
			   ,Customer.[IsPostACHNotification]
			   ,Customer.[PostACHNotificationEmailTo]
			   ,Customer.[IsReturnACHNotification]
			   ,Customer.[ReturnACHNotificationEmailTo]
			   ,Customer.[R_BusinessTypeId]
			   ,Customer.[R_ReceiptHierarchyTemplateId]
			   ,Customer.[R_CustomerClassId]
			   ,Customer.[ClabeNumber]
			   ,Customer.[IsBuyer]
			   ,Customer.[IsCustomerPortalAccessBlock]
			   ,Customer.[IsPEP]
			   ,Customer.[IsHNW]
			   ,Customer.[AlsoKnownAs]
			   ,Customer.[SalesForceCustomerName]
			   ,Customer.[LegalNameValidationDate]
			   ,Customer.[CompanyURL]
			   ,ISNULL(Customer.[PartyType],'_')
			   ,Customer.[IsMaterialAndRelevantPEP]
			   ,Customer.[IsMaterialAndRelevantAdverseMedia]
			   ,'_'
			   ,0.00
			   ,NULL
			   ,Customer.[PercentageOfGovernmentOwnership]
			   ,Customer.R_CustomerApprovedExchangesConfigId
			   ,Customer.R_CustomerApprovedRegulatorConfigId
			   ,Customer.[AnnualCreditReviewDate]
			   ,Customer.[ExtensionDate]
			   ,Customer.[PrimaryBusinessLevel1]
			   ,Customer.[TypeLevel2]
			   ,Customer.[FacilitiesLevel4]
			   ,Customer.[OtherMiscLevel5]
			   ,Customer.[ManagementLevel6]
			   ,Customer.[OwnershipLevel7]
			   ,ISNULL(Customer.[IncomeTaxStatus],'_')
			   ,Customer.[IsEPSMaster]
			   ,Customer.[R_MedicalSpecialityId]
			   ,Customer.R_JurisdictionOfSovereignCountryId
			   ,Customer.SFDCId
			   ,Customer.[R_PreACHNotificationEmailTemplateId]
			   ,Customer.[R_PostACHNotificationEmailTemplateId]
			   ,Customer.[R_ReturnACHNotificationEmailTemplateId]
			   ,0
			   ,0
			   ,0
			   ,0
			   ,0.0
			   ,0.00
			   ,'USD'
			   ,0.00
			   ,'USD'
			   ,Null
			   ,#CreatedTaxExemptRuleId.InsertedId
			   ,Customer.[R_LegalFormationTypeConfigId]
			   ,Customer.IsLimitedDisclosureParty
			   ,Customer.Prospect
			   ,Customer.Priority
			   ,Customer.CreditScore
			   ,Customer.IsBureauReportingExempt
			   ,Customer.IsNonAccrualExempt
			   ,Customer.IsManualReviewRequired
			   ,Customer.IsFinancialDocumentRequired
			   ,ConsentDate
			   ,R_NAICSCodeId
			   ,R_SICCodeId
			   ,InvoiceCommentBeginDate
			   ,InvoiceCommentEndDate
			   ,'_'
			   ,Customer.FinancialDate
			   ,Customer.FinancialExpectedDate
			   ,Customer.CreditReviewFrequency
			   ,Customer.R_CollectionStatusId
			   ,IsRelatedToLessor
			   ,NextReviewDate 		
			   ,Customer.FiscalYearEndMonth
			   ,Customer.IsWithholdingTaxApplicable
			   ,Customer.IsRelatedtoPEP
			   ,Customer.ParentPartyName
			   ,Customer.ParentPartyEIK
			   ,Customer.IsNotificationviaPhone
			   ,Customer.IsNotificationviaSMS
			   ,Customer.IsNotificationviaEMail
			 FROM stgCustomer Customer
			 INNER JOIN #CreatedCustomers ON #CreatedCustomers.CustomerId = Customer.Id
			 INNER JOIN #CreatedTaxExemptRuleId ON #CreatedTaxExemptRuleId.CustomerId=Customer.Id

			 --Consent Begin
			 MERGE ConsentDetails AS ConsentDetail
			 USING (SELECT CC.EffectiveDate
                ,CC.ExpiryDate
                ,CC.ConsentStatus
                ,CC.ConsentCaptureMode
                ,1 AS IsActive
                ,'Customer' AS EntityType
                ,CC.R_ConsentConfigId AS ConsentConfigId
                ,#CreatedCustomers.Id  AS CustomerId
            FROM stgCustomerConsent CC
            INNER JOIN #CreatedCustomers ON #CreatedCustomers.CustomerId = CC.CustomerId
            INNER JOIN stgCustomer C ON C.Id = CC.CustomerId
            WHERE CC.R_ConsentConfigId Is NOT NULL
			) AS ConsentDetailToMigrate
			ON (1=0)
			WHEN NOT MATCHED
			THEN       
			INSERT
			    (
			    EffectiveDate,
			    ExpiryDate,
			    CreatedById,
			    CreatedTime,
			    ConsentCaptureMode,
			    ConsentStatus,
			    IsActive,
			    EntityType,
			    ConsentConfigId
			    )
			VALUES
			(
				ConsentDetailToMigrate.EffectiveDate,
				ConsentDetailToMigrate.ExpiryDate,
				@UserId,
				@CreatedTime,
				ConsentDetailToMigrate.ConsentCaptureMode,
				ConsentDetailToMigrate.ConsentStatus,
				ConsentDetailToMigrate.IsActive,
				ConsentDetailToMigrate.EntityType,
				ConsentDetailToMigrate.ConsentConfigId
			)
			OUTPUT  Inserted.Id, ConsentDetailToMigrate.CustomerId INTO #CreatedConsentDetails;
            
			INSERT INTO [dbo].[PartyConsentDetails]
			(
			    ConsentDetailId,
			    PartyId,
			    CreatedById,
			    CreatedTime
			)
			SELECT Id
			    ,CustomerId
			    ,@UserId
			    ,@CreatedTime
			FROM #CreatedConsentDetails

	        MERGE ConsentDetails AS ConsentDetail
            USING (SELECT     CC.EffectiveDate
                ,CC.ExpiryDate
                ,CC.ConsentStatus
                ,CC.ConsentCaptureMode
                ,1 AS IsActive
                ,'CustomerContact' AS EntityType
                ,CC.R_ConsentConfigId AS ConsentConfigId
                ,#CreatedPartyContactIds.Id  AS CustomerContactId
            FROM stgCustomerContactConsent CC
            INNER JOIN #CreatedPartyContactIds ON #CreatedPartyContactIds.CustomerContactId = CC.CustomerContactId
            WHERE CC.R_ConsentConfigId Is NOT NULL
            ) AS ConsentDetailToMigrate
		    ON (1=0)
			WHEN NOT MATCHED
			THEN      
			INSERT
			    (
			    EffectiveDate,
			    ExpiryDate,
			    CreatedById,
			    CreatedTime,
			    ConsentCaptureMode,
			    ConsentStatus,
			    IsActive,
			    EntityType,
			    ConsentConfigId
			    )
			VALUES
			    (
			        ConsentDetailToMigrate.EffectiveDate,
			        ConsentDetailToMigrate.ExpiryDate,
			        @UserId,
			        @CreatedTime,
			        ConsentDetailToMigrate.ConsentCaptureMode,
			        ConsentDetailToMigrate.ConsentStatus,
			        ConsentDetailToMigrate.IsActive,
			        ConsentDetailToMigrate.EntityType,
			        ConsentDetailToMigrate.ConsentConfigId
			    )
			OUTPUT Inserted.Id, ConsentDetailToMigrate.CustomerContactId INTO #CreatedContactConsentDetails;
			   
			INSERT INTO [dbo].[PartyContactConsentDetails]
			(
			    ConsentDetailId,
			    PartyContactId,
			    CreatedById,
			    CreatedTime
			)
			SELECT Id
			    ,CustomerContactId
			    ,@UserId
			    ,@CreatedTime
			FROM #CreatedContactConsentDetails
			 --Consent End
			 			 			
			 INSERT INTO [dbo].[PartyTaxRegistrationDetails]
			 ([CreatedById],
			  [CreatedTime],
			  [IsActive],[EffectiveDate],
			  [CountryId],[StateId],
			  [PartyId],
			  [TaxRegistrationName],[TaxRegistrationId])
			 SELECT
			 @UserId
			   ,@CreatedTime,
			   1,CustomerTaxRegistrationDetail.[EffectiveDate],
			   CustomerTaxRegistrationDetail.[R_CountryId],
			   CustomerTaxRegistrationDetail.[R_StateId],
			   #CreatedCustomers.Id,
			   CustomerTaxRegistrationDetail.[TaxRegistrationName],
			   CustomerTaxRegistrationDetail.[TaxRegistrationId]
			  From stgCustomerTaxRegistrationDetail CustomerTaxRegistrationDetail
			  inner join #CreatedCustomers on CustomerTaxRegistrationDetail.CustomerId = #CreatedCustomers.CustomerId
			 INSERT INTO [dbo].[CustomerBillingPreferences]
			   ([InvoicePreference]
			   ,[EffectiveFromDate]
			   ,[IsActive]
			   ,[CreatedById]
			   ,[CreatedTime]
			   ,[ReceivableTypeId]
			   ,[CustomerId])
			SELECT
				CustomerBillingPreference.[InvoicePreference]
			   ,CustomerBillingPreference.[EffectiveFromDate]
			   ,1
			   ,@UserId
			   ,@CreatedTime
			   ,CustomerBillingPreference.[R_ReceivableTypeId]
			   ,#CreatedCustomers.Id
			FROM stgCustomerBillingPreference CustomerBillingPreference
			INNER JOIN #CreatedCustomers
				ON CustomerBillingPreference.CustomerId = #CreatedCustomers.CustomerId
			INSERT INTO [dbo].[EmployeesAssignedToParties]
			   ([IsActive]
			   ,[ActivationDate]
			   ,[IsPrimary]
			   ,[CreatedById]
			   ,[CreatedTime]
			   ,[RoleFunctionId]
			   ,[EmployeeId]
			   ,[PartyId]
			   ,[IsFromAssumption]
			   ,[IsAssumptionApproved]
			   ,[PartyRole])
			SELECT 
				1
			   ,EmployeesAssignedToCustomer.[ActivationDate]
			   ,EmployeesAssignedToCustomer.[IsPrimary]
			   ,@UserId
			   ,@CreatedTime
			   ,EmployeesAssignedToCustomer.[R_RoleFunctionId]
			   ,EmployeesAssignedToCustomer.[R_EmployeeId]
			   ,#CreatedCustomers.Id
			   ,0
			   ,0
			   ,'Customer'
			FROM stgEmployeesAssignedToCustomer EmployeesAssignedToCustomer
			INNER JOIN #CreatedCustomers
				ON EmployeesAssignedToCustomer.CustomerId = #CreatedCustomers.CustomerId
			INSERT INTO [dbo].[CustomerLateFeeSetups]
			   ([AssessLateFee]
			   ,[IsActive]
			   ,[CreatedById]
			   ,[CreatedTime]
			   ,[ReceivableTypeId]
			   ,[CustomerId])
			SELECT
				CustomerLateFeeSetup.[AssessLateFee]
			   ,1
			   ,@UserId
			   ,@CreatedTime
			   ,CustomerLateFeeSetup.[R_ReceivableTypeId]
			   ,#CreatedCustomers.Id
			FROM stgCustomerLateFeeSetup CustomerLateFeeSetup
			INNER JOIN #CreatedCustomers
				ON CustomerLateFeeSetup.CustomerId = #CreatedCustomers.CustomerId
			INSERT INTO [dbo].[CustomerPayoffTemplateAssignments]
           ([IsDefault]
           ,[IsActive]
           ,[CreatedById]
           ,[CreatedTime]
           ,[UpdatedById]
           ,[UpdatedTime]
           ,[PayOffTemplateId]
           ,[CustomerId]
		   ,[AvailableInCustomerPortal])
		   SELECT
            payoff.[IsDefault]
           ,1
           ,@UserId
           ,@CreatedTime
           ,NULL
           ,NULL
           ,R_PayOffTemplateId
           ,#CreatedCustomers.Id
		   ,0
		   FROM stgCustomerPayoffTemplateAssignment payoff
		   INNER JOIN stgCustomer V ON payoff.CustomerId = V.Id
		   INNER JOIN  #CreatedCustomers ON V.Id = #CreatedCustomers.CustomerId
		   WHERE R_PayOffTemplateId IS NOT NULL
			INSERT INTO [dbo].[CustomerACHAssignments]
			   ([AssignmentNumber]
			   ,[PaymentType]
			   ,[StartDate]
			   ,[EndDate]
			   ,[IsActive]
			   ,[CreatedById]
			   ,[CreatedTime]
			   ,[ReceivableTypeId]
			   ,[BankAccountId]
			   ,[CustomerId]
			   ,RecurringPaymentMethod
			   ,DayoftheMonth
			   )
			SELECT 
				ROW_NUMBER() OVER(PARTITION BY CustomerACHAssignment.CustomerId ORDER BY CustomerACHAssignment.CustomerId)
			   ,CustomerACHAssignment.[PaymentType]
			   ,CustomerACHAssignment.[StartDate]
			   ,CustomerACHAssignment.[EndDate]
			   ,1
			   ,@UserId
			   ,@CreatedTime
			   ,CustomerACHAssignment.[R_ReceivableTypeId]
			   ,#CreatedBankAccountIds.Id
			   ,#CreatedCustomers.Id
			   ,CustomerACHAssignment.RecurringPaymentMethod
			   ,CustomerACHAssignment.DayoftheMonth
			FROM stgCustomerACHAssignment CustomerACHAssignment
			INNER JOIN #CreatedCustomers
				ON CustomerACHAssignment.CustomerId = #CreatedCustomers.CustomerId
			INNER JOIN #CreatedBankAccountIds
				ON CustomerACHAssignment.R_BankAccountNumber = #CreatedBankAccountIds.AccountNumber
				AND #CreatedBankAccountIds.CustomerId = #CreatedCustomers.CustomerId
			INSERT INTO [dbo].[CreditSummaryExposures]
			        ( ExposureType ,
			          Direct_Amount ,
			          Direct_Currency ,
			          Indirect_Amount ,
			          Indirect_Currency ,
			          PrimaryCustomer_Amount ,
			          PrimaryCustomer_Currency ,
			          AsOfDate ,
			          CreatedById ,
			          CreatedTime ,
			          CustomerId
			        )
					SELECT
						  'EF',
						  0.0 ,
						  'USD',
						  0.0,
						  'USD',
						  0.0,
						  'USD',
						  @CreatedTime,
						  @UserId,
						  @CreatedTime 	
						  ,#CreatedCustomers.Id					  
					 FROM #CreatedCustomers;
					 INSERT INTO [dbo].[CreditSummaryExposures]
			        ( ExposureType ,
			          Direct_Amount ,
			          Direct_Currency ,
			          Indirect_Amount ,
			          Indirect_Currency ,
			          PrimaryCustomer_Amount ,
			          PrimaryCustomer_Currency ,
			          AsOfDate ,
			          CreatedById ,
			          CreatedTime ,
			          CustomerId
			        )
					SELECT
						  'Bank',
						  0.0 ,
						  'USD',
						  0.0,
						  'USD',
						  0.0,
						  'USD',
						  @CreatedTime,
						  @UserId,
						  @CreatedTime 	
						  ,#CreatedCustomers.Id					  
					 FROM #CreatedCustomers;
			INSERT INTO dbo.CreditRiskGrades
			        ( 
			          CreatedById ,
			          CreatedTime ,
			          CustomerId ,
			          RatingModelId ,
			          Code ,
			          AdjustedCode ,
			          EntryDate ,
			          FinancialStatementDate ,
			          RAID ,
			          IsRatingSubstitution ,
			          DefaultEvent ,
			          OverrideParty ,
			          OverrideRating ,
			          OverrideRatingDate ,
					  IsActive ,
					  AdjustmentReasonId ,
					  ContractId
			        )
			SELECT
				@UserId
				,@CreatedTime
				,#CreatedCustomers.Id
				,creditRiskGrade.R_RatingModelConfigId
				,creditRiskGrade.Code
				,creditRiskGrade.AdjustedCode
				,creditRiskGrade.EntryDate
				,creditRiskGrade.FinancialStatementDate
				,creditRiskGrade.RAID
				,creditRiskGrade.IsRatingSubstitution
				,creditRiskGrade.DefaultEvent
				,creditRiskGrade.OverrideParty
				,creditRiskGrade.OverrideRating
				,creditRiskGrade.OverrideRatingDate
				,1
				,creditRiskGrade.R_AdjustmentReasonConfigId
				,R_ContractId
			FROM stgCreditRiskGrade creditRiskGrade
			INNER JOIN #CreatedCustomers ON creditRiskGrade.CustomerId = #CreatedCustomers.CustomerId
			INSERT INTO dbo.CreditBureaux
			        ( BureauCustomerNumber ,
			          BureauCustomerName ,
			          AddedDate ,
			          IsNoMatchFound ,
			          IsActive ,
			          CreatedById ,
			          CreatedTime ,
			          CustomerId ,
					  BusinessBureauId
			        )
			SELECT 
				creditBureau.BureauCustomerNumber
				,creditBureau.BureauCustomerName
				,creditBureau.AddedDate
				,creditBureau.IsNoMatchFound
				,1
				,@UserId
				,@CreatedTime
				,#CreatedCustomers.Id
				,R_BusinessBureauId
			FROM stgCreditBureau creditBureau
			INNER JOIN #CreatedCustomers
						ON creditBureau.CustomerId = #CreatedCustomers.CustomerId
			INSERT INTO dbo.CustomerBondRatings
			        ( Agency ,
			          AgencyCustomerName ,
			          AgencyCustomerNumber ,
			          AsOfDate ,
			          CreatedById ,
			          CreatedTime ,
			          CustomerId ,
			          BondratingId ,
			          IsActive
			        )
			SELECT
				customerBondRating.Agency
				,customerBondRating.AgencyCustomerName
				,customerBondRating.AgencyCustomerNumber
				,customerBondRating.AsOfDate
				,@UserId
				,@CreatedTime
				,#CreatedCustomers.Id
				,customerBondRating.R_BondRatingId
				,1
			FROM stgCustomerBondRating customerBondRating
			INNER JOIN #CreatedCustomers
						ON customerBondRating.CustomerId = #CreatedCustomers.CustomerId
			INSERT INTO dbo.CustomerServiceOrWorkouts
			        ( CreditWatch ,
			          [Date] ,
			          Reason ,
			          Comments ,
			          CreatedById ,
			          CreatedTime ,
			          CustomerId
			        )
			SELECT
				customerServiceOrWorkout.CreditWatch
				,customerServiceOrWorkout.[Date]
				,customerServiceOrWorkout.Reason
				,customerServiceOrWorkout.Comments
				,@UserId
				,@CreatedTime
				,#CreatedCustomers.Id
            FROM stgCustomerServiceOrWorkout customerServiceOrWorkout
			INNER JOIN #CreatedCustomers
						ON customerServiceOrWorkout.CustomerId = #CreatedCustomers.CustomerId;
			INSERT INTO dbo.CustomerDoingBusinessAs
			        ( 
						DoingBusinessAsName,
			            EffectiveDate,
			            Comments,
			            IsActive,
			            CreatedById,
			            CreatedTime,
			            CustomerId
			        )
			SELECT
				customerDoingBusinessAs.DoingBusinessAsName
				,customerDoingBusinessAs.EffectiveDate
				,customerDoingBusinessAs.Comments
				,1
				,@UserId
				,@CreatedTime
				,#CreatedCustomers.Id
			FROM stgCustomerDoingBusinessAs customerDoingBusinessAs
			INNER JOIN #CreatedCustomers
						ON customerDoingBusinessAs.CustomerId = #CreatedCustomers.CustomerId
			INSERT INTO FormerlyKnownAs
			(
				FormerName
				,EffectiveDate
				,Comments
				,IsActive
				,CustomerId
				,CreatedById
				,CreatedTime
			)
			SELECT
				FKA.FormerName
				,FKA.EffectiveDate
				,FKA.Comments
				,1
				,#CreatedCustomers.Id
				,@UserId
				,@CreatedTime
			FROM stgFormerlyKnownAs AS FKA
			INNER JOIN #CreatedCustomers ON #CreatedCustomers.CustomerId = FKA.CustomerId
			INSERT INTO FinancialStatements
			(
				Frequency
				,OtherStatementType
				,StatementDate
				,DaysToUpload
				,Comment
				,IsActive
				,CreatedById
				,CreatedTime
				,DocumentTypeId
				,PartyId
				,RAIDNumber
				,UploadByDate
			)
			SELECT
				Frequency
				,OtherStatementType
				,StatementDate
				,DaysToUpload
				,Comment
				,1
				,@UserId
				,@CreatedTime
				,R_DocumentTypeId
				,#CreatedCustomers.Id
				,RAIDNumber
				,dateadd(dd,DaysToUpload,StatementDate)
			FROM stgFinancialStatement AS FS
			INNER JOIN #CreatedCustomers ON #CreatedCustomers.CustomerId = FS.CustomerId
			INSERT INTO ParentPartyRelationshipHistories
			(
				 AssignedDate
				,CreatedById
				,CreatedTime
				,ParentPartyId
				,PartyId
			)
			SELECT 
				Convert(date, @CreatedTime) 
				,@UserId
				,@CreatedTime
				,Customer.R_ParentPartyId
				,#CreatedCustomers.Id
			FROM #Customers Customer
			INNER JOIN #CreatedCustomers ON #CreatedCustomers.CustomerId = Customer.Id	
			WHERE Customer.R_ParentPartyId IS NOT NULL;
			SELECT
				CustomerId
				,CustomerAddressId
				,AddressLine1
				,AddressLine2
				,HomeAddressLine1
				,HomeAddressLine2
				,City
				,HomeCity
				,PostalCode
				,HomePostalCode
				,R_StateId
				,R_HomeStateId
			INTO #LatestCustomerAddressAssociatedWithCustomer
			FROM
			(
				SELECT 
					CustomerAddress.CustomerId
					,CustomerAddress.Id As CustomerAddressId
					,AddressLine1
					,AddressLine2
					,HomeAddressLine1
					,HomeAddressLine2
					,City
					,HomeCity
					,PostalCode
					,HomePostalCode
					,R_StateId
					,R_HomeStateId
					,CustomerAddressOrder = Row_Number()OVER(Partition By CustomerAddress.CustomerId Order By CustomerAddress.Id)
				FROM
				stgCustomerAddress CustomerAddress
				INNER JOIN #CreatedCustomers ON #CreatedCustomers.CustomerId = CustomerAddress.CustomerId
					AND CustomerAddress.IsMain=1							
			) As LatestCustomerAddressAssociatedWithCustomer Where CustomerAddressOrder=1
			INSERT INTO CustomerCIPHistories
			(
			     FirstName
				,LastName
				,CompanyName
				,UniqueIdentificationNumber
				,AddressLine1
				,AddressLine2
				,City
				,PostalCode
				,CIPDocumentSourceForName
				,CIPDocumentSourceForAddress
				,CIPDocumentSourceForTaxIdOrSSN
				,CIPDocumentSourceNameId
				,StateId
				,CustomerId
				,CreatedById
				,CreatedTime
			)
			SELECT
				 Customer.FirstName
				,Customer.LastName
				,Customer.CompanyName
				,CASE WHEN Customer.EGNNumber IS NOT NULL THEN Customer.EGNNumber ELSE NULL  END
				,COALESCE(CustomerAddress.AddressLine1, CustomerAddress.HomeAddressLine1)
				,COALESCE(CustomerAddress.AddressLine2, CustomerAddress.HomeAddressLine2)
				,COALESCE(CustomerAddress.City, CustomerAddress.HomeCity)
				,COALESCE(CustomerAddress.PostalCode, CustomerAddress.HomePostalCode)
				,'_'
				,CIPDocumentSourceForAddress
				,CIPDocumentSourceForTaxIdOrSSN
				,R_CIPDocumentSourceId
				,COALESCE(CustomerAddress.R_StateId, CustomerAddress.R_HomeStateId)
				,#CreatedCustomers.Id
				,@UserId
				,@CreatedTime
			FROM stgCustomer Customer
			INNER JOIN #CreatedCustomers ON #CreatedCustomers.CustomerId = Customer.Id
			INNER JOIN #LatestCustomerAddressAssociatedWithCustomer CustomerAddress ON CustomerAddress.CustomerId=Customer.Id  
			WHERE R_CIPDocumentSourceId IS NOT NULL AND	CIPDocumentSourceForAddress != '_' AND CIPDocumentSourceForTaxIdOrSSN !='_' 
			INSERT INTO #CustomerPaymentThresholdValues 
			(
				 BankAccountNumber
				,CustomerId
			)
			SELECT
				 R_BankAccountNumber
				,CAA.CustomerId
			FROM stgCustomerACHAssignment CAA
			INNER JOIN #CreatedCustomers ON CAA.CustomerId = #CreatedCustomers.CustomerId
			WHERE CAA.R_BankAccountNumber IS NOT NULL
			GROUP BY CAA.R_BankAccountNumber,CAA.CustomerId
			INSERT INTO CustomerBankAccountPaymentThresholds
			(
				 PaymentThreshold
				,PaymentThresholdAmount_Amount
				,PaymentThresholdAmount_Currency
				,EmailId
				,IsActive
				,CreatedById
				,CreatedTime
				,BankAccountId
				,CustomerId			
			)
			SELECT
				 CASE WHEN PaymentThresholdAmount > 0.00 THEN 1 ELSE 0 END
				,PaymentThresholdAmount
				,CASE WHEN CBA.CurrencyCode IS NULL THEN 'USD' 
					  ELSE CBA.CurrencyCode END
				,PaymentThresholdEmailId
				,1
				,@UserId
				,@CreatedTime
				,#CreatedBankAccountIds.Id
				,#CreatedCustomers.Id
			FROM stgCustomerBankAccount CBA
			INNER JOIN #CreatedBankAccountIds ON 
			#CreatedBankAccountIds.CustomerId = CBA.CustomerId 
			AND CBA.AccountNumber = #CreatedBankAccountIds.AccountNumber
			AND #CreatedBankAccountIds.BankBranchId = CBA.R_BankBranchId
			INNER JOIN #CreatedCustomers ON #CreatedCustomers.CustomerId = CBA.CustomerId
			WHERE EXISTS (select 1 from #CustomerPaymentThresholdValues Value where CBA.CustomerId = Value.CustomerId AND CBA.AccountNumber = Value.BankAccountNumber)
			Update C Set C.IsMigrated=1 ,UpdatedById = @UserId , UpdatedTime = @CreatedTime
			from stgCustomer C inner join 
			#CreatedCustomers CC on C.Id=CC.CustomerId
			IF EXISTS(SELECT Id FROM #CreatedBankAccountIds)
			BEGIN
			SET @Number = (SELECT MAX(CAST(REPLACE(UniqueIdentifier,'-','') AS BIGINT)) FROM BankAccounts)
			SET @SQL = 'ALTER SEQUENCE BankAccount RESTART WITH ' + CONVERT(NVARCHAR(20),@Number+1)
			EXEC sp_executesql @sql
			END
			IF EXISTS(SELECT Id FROM #CreatedCustomers)
			BEGIN
			SET @Number = (SELECT MAX(Id) FROM #CreatedCustomers)
			SET @SQL = 'ALTER SEQUENCE Party RESTART WITH ' + CONVERT(NVARCHAR(20),@Number+1)
			EXEC sp_executesql @sql
			END
			MERGE stgProcessingLog AS ProcessingLog
			USING (SELECT CustomerId FROM #CreatedCustomers				
				  ) AS ProcessedCustomers
			ON (ProcessingLog.StagingRootEntityId = ProcessedCustomers.CustomerId AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
			WHEN MATCHED THEN
				UPDATE SET UpdatedTime = @CreatedTime
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
					ProcessedCustomers.CustomerId
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
			SET @SkipCount = @SkipCount+(SELECT COUNT(DISTINCT Id) FROM #Customers)+@IncorrectParentNumber;	
			DROP TABLE #CreatedCustomers;
			DROP TABLE #CreatedPartyContactIds;
			DROP TABLE #CreatedBankAccountIds;
			DROP TABLE #CreatedTaxExemptRuleId;
			DROP TABLE #CreatedProcessingLogs;
			DROP TABLE #CreatedConsentDetails;
			DROP TABLE #CreatedContactConsentDetails;
			DROP TABLE #Customers;	
			DROP TABLE #CustomerPaymentThresholdValues;
			DROP TABLE #LatestCustomerAddressAssociatedWithCustomer;
COMMIT TRANSACTION
END TRY
BEGIN CATCH
	SET @SkipCount = @SkipCount  + @TakeCount;
	DECLARE @ErrorMessage Nvarchar(max);
	DECLARE @ErrorLine Nvarchar(max);
	DECLARE @ErrorSeverity INT;
	DECLARE @ErrorState INT;
	DECLARE @ErrorLogs ErrorMessageList;
	DECLARE @ModuleName Nvarchar(max) = 'MigrateCustomers'
	Insert into @ErrorLogs(StagingRootEntityId, ModuleIterationStatusId, Message,Type) VALUES (0,@ModuleIterationStatusId,ERROR_MESSAGE(),'Error')
	SELECT  @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE(),@ErrorLine=ERROR_LINE(),@ErrorMessage=ERROR_MESSAGE()
	IF (XACT_STATE()) = -1  
	BEGIN  
		ROLLBACK TRANSACTION;
		EXEC [dbo].[ExceptionLog] @ErrorLogs,@ErrorLine,@UserId,@CreatedTime,@ModuleName
		SET @FailedRecords = @FailedRecords+@BatchCount;
	END;  
	IF (XACT_STATE()) = 1  
	BEGIN
		COMMIT TRANSACTION;
		RAISERROR (@ErrorMessage,@ErrorSeverity, @ErrorState);     
	END;  
END CATCH
END
-- Migrate 
MERGE stgProcessingLog AS ProcessingLog
USING (SELECT DISTINCT StagingRootEntityId FROM #ErrorLogDetails ) AS ErrorCustomers
		ON (ProcessingLog.StagingRootEntityId = ErrorCustomers.StagingRootEntityId AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
		WHEN MATCHED THEN
			UPDATE SET UpdatedTime = @CreatedTime,UpdatedById = @UserId
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
				ErrorCustomers.StagingRootEntityId
				,@UserId
				,@CreatedTime
				,@ModuleIterationStatusId
			)
		OUTPUT  Inserted.Id, ErrorCustomers.StagingRootEntityId INTO #FailedProcessingLogs;
		INSERT INTO stgProcessingLogDetail
		(
			Message
			,Type
			,CreatedById
			,CreatedTime	
			,ProcessingLogId
		)
		SELECT
			#ErrorLogDetails.Message
			,'Error'
			,@UserId
			,@CreatedTime
			,#FailedProcessingLogs.Id
		FROM #ErrorLogDetails
		JOIN #FailedProcessingLogs ON #ErrorLogDetails.StagingRootEntityId = #FailedProcessingLogs.SecurityDepositId;	
		SET @FailedRecords = @FailedRecords+(SELECT COUNT(DISTINCT StagingRootEntityId) FROM #ErrorLogDetails)
		SET @ProcessedRecords = @ProcessedRecords + @TotalRecordsCount;		
DROP TABLE #ErrorLogs;
DROP TABLE #ErrorLogDetails;
DROP TABLE #FailedProcessingLogs
DROP TABLE #ProcessedCustomer
SET NOCOUNT OFF;
SET XACT_ABORT OFF;
END

GO

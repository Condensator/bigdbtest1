SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE  PROCEDURE [dbo].[MigrateVendorForCustomers]
(
@UserId BIGINT ,
@ModuleIterationStatusId BIGINT,
@CreatedTime DATETIMEOFFSET,
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
SET XACT_ABORT ON;
DECLARE @Number INT =0
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
[Action] NVARCHAR(10) NOT NULL,
[Id] BIGINT NOT NULL,
[VendorId] BIGINT NOT NULL
);
CREATE TABLE #VendorIdsToMigrate
(
[Id] BIGINT NOT NULL
);
INSERT INTO #VendorIdsToMigrate (Id)
SELECT vendor.Id FROM stgVendor vendor
INNER JOIN Parties customer ON vendor.VendorNumber = customer.PartyNumber
WHERE vendor.IsMigrated = 0
DECLARE @Counter INT = 0;
DECLARE @TakeCount INT = 50000;
DECLARE @SkipCount INT = 0;
DECLARE @BatchCount INT = 0;
DECLARE @MaxErrorStagingRootEntityId INT = 0;
SET @FailedRecords = 0;
SET @ProcessedRecords = 0;
DECLARE @TotalRecordsCount INT = (SELECT Count(Id) FROM #VendorIdsToMigrate);
SET @MaxErrorStagingRootEntityId= 0;
SET @SkipCount = 0;
DECLARE @DefaultCountry NVARCHAR(40);
SELECT @DefaultCountry = ISNULL(Value,'USA') FROM GlobalParameters WHERE Category ='Country' AND Name ='DefaultCountry' AND IsActive = 1
UPDATE stgVendor Set R_LineofBusinessId = LineofBusinesses.Id
FROM stgVendor vendor
INNER JOIN #VendorIdsToMigrate v ON vendor.Id = v.Id
INNER JOIN LineofBusinesses ON LineofBusinesses.Name = vendor.LineofBusinessName
WHERE vendor.LineofBusinessName IS NOT NULL AND vendor.R_LineofBusinessId IS NULL;
INSERT INTO #ErrorLogs
SELECT
V.Id
,'Error'
,('Invalid Default Line of Business for VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
FROM stgVendor V
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
WHERE V.LineofBusinessName IS NOT NULL AND V.R_LineofBusinessId IS NULL

UPDATE stgVendor Set R_LegalOrganizationFormId = BusinessTypes.Id
	FROM stgVendor vendor
	INNER JOIN BusinessTypes ON BusinessTypes.Name = vendor.LegalOrganizationForm
	WHERE vendor.IsMigrated = 0 AND vendor.R_LegalOrganizationFormId IS NULL;  

	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Please Enter LegalOrganizationForm for VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	WHERE V.IsMigrated = 0 AND V.R_LegalOrganizationFormId IS NULL 

INSERT INTO #ErrorLogs
SELECT
V.Id
,'Error'
,('Type is mandatory for vendor for VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
FROM stgVendor V
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
WHERE V.Type IS NULL
UPDATE stgVendor
SET R_IsUSBased = 1
FROM
stgVendor V
INNER JOIN
#VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
INNER JOIN
stgCustomer C ON C.CustomerNumber = V.VendorNumber
INNER JOIN
stgCustomerAddress CA ON C.Id = CA.CustomerId AND CA.IsMain = 1
WHERE (CA.Country= @DefaultCountry OR CA.HomeCountry= @DefaultCountry)
UPDATE stgVendor
SET R_IsLegalEntityUSBased = 1
FROM
stgVendor V
INNER JOIN
#VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
INNER JOIN
stgVendorLegalEntity VLE ON VLE.VendorId = V.Id
INNER JOIN
LegalEntities  LE ON VLE.LegalEntityNumber = LE.LegalEntityNumber
INNER JOIN
LegalEntityAddresses address on address.LegalEntityId = LE.Id
INNER JOIN
States state on state.Id = address.StateId
INNER JOIN
Countries country on country.Id = state.Id
WHERE
(country.ShortName = @DefaultCountry)
AND
address.IsActive=1
UPDATE stgVendor SET R_IsUSBased = ISNULL(R_IsUSBased,0), R_IsLegalEntityUSBased = ISNULL(R_IsLegalEntityUSBased,0)
FROM stgVendor V
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
INSERT INTO #ErrorLogs
SELECT
V.Id
,'Error'
,('Remove W8IssueDate/W8ExpirationDate/FATCA/Percentage1441 for Vendor with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
FROM stgVendor V
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
WHERE (V.R_IsUSBased = 1 OR (V.R_IsLegalEntityUSBased != 1 AND V.R_IsUSBased != 1))
AND (V.W8IssueDate IS NOT NULL OR V.W8ExpirationDate IS NOT NULL OR V.FATCA !=0 OR V.Percent1441 !=0)
----Remit To Vendor
UPDATE stgVendorRemitTo
SET R_AddressUniqueIdentifier= CA.Id
FROM
stgVendorRemitTo VRT
INNER JOIN
stgVendor V ON V.Id = VRT.VendorId
INNER JOIN
#VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
INNER JOIN
stgCustomer C ON C.CustomerNumber = V.VendorNumber
INNER JOIN
stgCustomerAddress CA ON C.Id = CA.CustomerId AND VRT.AddressUniqueIdentifier = CA.UniqueIdentifier
WHERE VRT.Id IS NOT NULL AND VRT.R_AddressUniqueIdentifier Is NULL
UPDATE stgVendorRemitTo
SET R_LogoId= Logoes.Id
FROM
stgVendorRemitTo VRT
INNER JOIN
stgVendor V ON V.Id = VRT.VendorId
INNER JOIN
#VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
INNER JOIN
Logoes Logoes ON Logoes.Name = VRT.LogoName AND Logoes.IsActive=1
WHERE VRT.Id IS NOT NULL AND VRT.R_LogoId Is NULL
INSERT INTO #ErrorLogs
SELECT
V.Id
,'Error'
,('Invalid Remit To Address UniqueIdentifier {'+ISNULL(VRT.AddressUniqueIdentifier,'NULL')+'} for VendorRemitTo Id {'+CONVERT(NVARCHAR(MAX),VRT.Id)+'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
FROM stgVendor V
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
INNER JOIN stgVendorRemitTo VRT ON VRT.VendorId = V.Id
WHERE VRT.Id Is NOT NULL AND  VRT.R_AddressUniqueIdentifier IS NULL
INSERT INTO #ErrorLogs
SELECT
V.Id
,'Error'
,('Invalid Remit To Logo Name {'+ISNULL(VRT.LogoName,'NULL')+'} for VendorRemitTo Id {'+CONVERT(NVARCHAR(MAX),VRT.Id)+'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
FROM stgVendor V
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
INNER JOIN stgVendorRemitTo VRT ON VRT.VendorId = V.Id
WHERE VRT.Id Is NOT NULL AND  (VRT.LogoName IS NOT NULL and len(VRT.LogoName)>0 )AND VRT.R_LogoId IS NULL
UPDATE stgVendorRemitToWireDetail
SET R_BankAccountId= BA.Id
FROM
stgVendorRemitToWireDetail VRTW
INNER JOIN
stgVendorRemitTo VRT ON VRTW.VendorRemitToId = VRT.Id
INNER JOIN
stgVendor V ON V.Id = VRT.VendorId
INNER JOIN
#VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
INNER JOIN
stgCustomer C ON C.CustomerNumber = V.VendorNumber
INNER JOIN
stgCustomerBankAccount CBA ON CBA.CustomerId = C.Id
INNER JOIN
BankAccounts BA ON BA.UniqueIdentifier =  CBA.UniqueIdentifier
WHERE VRT.Id IS NOT NULL AND VRTW.R_BankAccountId Is NULL
AND CBA.AccountNumber =VRTW.BankAccountNumber
INSERT INTO #ErrorLogs
SELECT
V.Id
,'Error'
,('Invalid Wire Remit To BankAccountNumber {'+ISNULL(VRTW.BankAccountNumber,'NULL')+'} for VendorRemitTo Id {'+CONVERT(NVARCHAR(MAX),VRT.Id)+'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
FROM stgVendor V
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
INNER JOIN stgVendorRemitTo VRT ON VRT.VendorId = V.Id
INNER JOIN stgVendorRemitToWireDetail VRTW ON VRTW.VendorRemitToId=VRT.Id
WHERE VRT.Id Is NOT NULL AND  VRTW.R_BankAccountId IS NULL AND VRT.ReceiptType!='Check'
--Vendor LegalEntity
UPDATE stgVendorLegalEntity
SET R_LegalEntityId=LE.Id
FROM
stgVendorLegalEntity VLE
INNER JOIN
stgVendor V on VLE.VendorId = V.Id
INNER JOIN
#VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
INNER JOIN
LegalEntities LE ON LE.LegalEntityNumber = VLE.LegalEntityNumber
WHERE
VLE.R_LegalEntityId IS NULL
INSERT INTO #ErrorLogs
SELECT
V.Id
,'Error'
,('Invalid Legal Entity Number {'+ISNULL(VLE.LegalEntityNumber,'NULL')+'} for VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
FROM stgVendor V
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
INNER JOIN stgVendorLegalEntity VLE ON VLE.VendorId = V.Id
WHERE VLE.Id Is NOT NULL AND  VLE.R_LegalEntityId IS NULL
INSERT INTO #ErrorLogs
SELECT
V.Id
,'Error'
,('Cumulative Funding Limit should be greater than or equal to zero for the following Vendor Legal Entities {'+ISNULL(VLE.LegalEntityNumber,'NULL')+'} for VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
FROM stgVendor V
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
INNER JOIN stgVendorLegalEntity VLE ON VLE.VendorId = V.Id
WHERE VLE.Id Is NOT NULL AND VLE.CumulativeFundingLimit_Amount<0
-- Program Vendor ProgramVendorsAssignedToDealer Dealer/Distributor
INSERT INTO #ErrorLogs
SELECT
V.Id
,'Error'
,('VendorProgramType Is Mandatory for ProgramVendor {'+CONVERT(nvarchar(MAX),V.Id) +'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
FROM stgVendor V
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
WHERE V.IsVendorProgram=1 AND (V.VendorProgramType IS NULL OR V.VendorProgramType ='_')
INSERT INTO #ErrorLogs
SELECT
V.Id
,'Error'
,('Default Line of Business Name is mandatory for ProgramVendorsAssignedToDealer {'+CONVERT(nvarchar(MAX),PV.Id) +'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
FROM stgVendor V
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
INNER JOIN stgProgramVendorsAssignedToDealer PV ON PV.VendorId = V.Id
WHERE PV.Id Is NOT NULL AND PV.LineofBusinessName IS NULL AND PV.ProgramVendorNumber IS NOT NULL AND V.VendorProgramType='DealerOrDistributor'
INSERT INTO #ErrorLogs
SELECT
V.Id
,'Error'
,('Program is mandatory for ProgramVendorsAssignedToDealer {'+CONVERT(nvarchar(MAX),PV.Id) +'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
FROM stgVendor V
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
INNER JOIN stgProgramVendorsAssignedToDealer PV ON PV.VendorId = V.Id
WHERE PV.Id Is NOT NULL AND PV.Program IS NULL AND V.VendorProgramType='DealerOrDistributor'
UPDATE stgProgramVendorsAssignedToDealer Set R_LineofBusinessId= business.Id
FROM stgProgramVendorsAssignedToDealer PV
INNER JOIN stgVendor V ON V.Id = PV.VendorId
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
INNER JOIN LineofBusinesses business on business.Name = PV.LineofBusinessName
WHERE PV.Id IS NOT NULL AND PV.R_LineofBusinessId IS NULL AND V.IsVendorProgram=1 AND V.VendorProgramType='DealerOrDistributor'
INSERT INTO #ErrorLogs
SELECT
V.Id
,'Error'
,('Invalid Line of Business Name for ProgramVendorsAssignedToDealer {'+CONVERT(nvarchar(MAX),PV.Id) +'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
FROM stgVendor V
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
INNER JOIN stgProgramVendorsAssignedToDealer PV ON PV.VendorId = V.Id
WHERE PV.Id Is NOT NULL AND PV.R_LineofBusinessId IS NULL AND PV.LineofBusinessName IS NOT NULL AND V.VendorProgramType='DealerOrDistributor'
UPDATE stgProgramVendorsAssignedToDealer  Set R_ProgramId= programs.Id
FROM stgProgramVendorsAssignedToDealer PV
INNER JOIN stgVendor V ON V.Id = PV.VendorId
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
INNER JOIN Programs programs on programs.Name = PV.Program
WHERE PV.Id IS NOT NULL AND PV.R_ProgramId IS NULL AND PV.Program IS NOT NULL AND V.IsVendorProgram=1 AND V.VendorProgramType='DealerOrDistributor'
INSERT INTO #ErrorLogs
SELECT
V.Id
,'Error'
,('Invalid Program Number for ProgramVendorsAssignedToDealer {'+CONVERT(nvarchar(MAX),PV.Id) +'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
FROM stgVendor V
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
INNER JOIN stgProgramVendorsAssignedToDealer PV ON PV.VendorId = V.Id
WHERE PV.Id IS NOT NULL AND PV.R_ProgramId IS NULL AND PV.Program is not null AND V.IsVendorProgram=1 AND V.VendorProgramType='DealerOrDistributor'
UPDATE stgProgramVendorsAssignedToDealer Set R_ProgramVendorId= party.Id
FROM stgProgramVendorsAssignedToDealer PV
INNER JOIN stgVendor V ON V.Id = PV.VendorId
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
INNER JOIN Parties party on party.PartyNumber= PV.ProgramVendorNumber
WHERE PV.Id IS NOT NULL AND PV.R_ProgramVendorId IS NULL AND V.IsVendorProgram=1 AND V.VendorProgramType='DealerOrDistributor'
INSERT INTO #ErrorLogs
SELECT
V.Id
,'Error'
,('Invalid Program Vendor Number for ProgramVendorsAssignedToDealer {'+CONVERT(nvarchar(MAX),PV.Id) +'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
FROM stgVendor V
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
INNER JOIN stgProgramVendorsAssignedToDealer PV ON PV.VendorId = V.Id
WHERE PV.Id Is NOT NULL AND PV.R_ProgramVendorId IS NULL AND PV.ProgramVendorNumber IS NOT NULL AND V.VendorProgramType='DealerOrDistributor'
INSERT INTO #ErrorLogs
SELECT
V.Id
,'Error'
,('The Program Vendor selected should have one Primary Sales Rep assigned for ProgramVendor {'+CONVERT(nvarchar(MAX),PV.ProgramVendorNumber) +'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
FROM stgVendor V
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
INNER JOIN stgProgramVendorsAssignedToDealer PV ON PV.VendorId = V.Id
INNER JOIN Parties P ON PV.R_ProgramVendorId = P.Id
LEFT JOIN EmployeesAssignedToParties EATP ON EATP.PartyId = P.Id AND EATP.IsPrimary = 1 AND EATP.IsActive = 1
LEFT JOIN RoleFunctions RF ON EATP.RoleFunctionId = RF.Id
WHERE PV.ProgramVendorNumber IS NOT NULL AND V.VendorProgramType='DealerOrDistributor' AND ((EATP.Id IS NOT NULL AND RF.SystemDefinedName !='SalesRep') OR EATP.Id IS NULL)
-- Vendor Program
UPDATE stgVendor Set R_ProgramId= programs.Id
FROM stgVendor V
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
INNER JOIN Programs programs on programs.Name = V.Program
WHERE  V.R_ProgramId IS NULL AND V.IsVendorProgram=1 AND V.VendorProgramType='ProgramVendor'
INSERT INTO #ErrorLogs
SELECT
V.Id
,'Error'
,('Invalid Program for ProgramVendor {'+CONVERT(nvarchar(MAX),V.Id) +'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
FROM stgVendor V
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
WHERE  V.R_ProgramId IS NULL AND V.IsVendorProgram=1 AND V.VendorProgramType='ProgramVendor'
-- Vendor Program Promotion
UPDATE stgVendorProgramPromotion Set R_ProgramPromotionId= programpromotions.Id
FROM stgVendorProgramPromotion VPP
INNER JOIN stgVendor V ON V.Id = VPP.VendorId
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
INNER JOIN ProgramPromotions programpromotions on programpromotions.PromotionCode = VPP.ProgramPromotionCode AND programpromotions.IsActive = 1
INNER JOIN Programs P ON P.ProgramDetailId = programpromotions.ProgramDetailId AND V.R_ProgramId = P.Id
WHERE VPP.Id IS NOT NULL AND VPP.R_ProgramPromotionId IS NULL AND V.RestrictPromotions = 1 AND V.IsVendorProgram=1 AND V.VendorProgramType='ProgramVendor'
INSERT INTO #ErrorLogs
SELECT
V.Id
,'Error'
,('Invalid Program Promotions for ProgramVendor {'+CONVERT(nvarchar(MAX),V.Program) +'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
FROM stgVendor V
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
INNER JOIN stgVendorProgramPromotion VPP ON VPP.VendorId = V.Id
WHERE VPP.Id IS NOT NULL AND VPP.R_ProgramPromotionId IS NULL AND V.RestrictPromotions = 1 AND V.IsVendorProgram=1 AND V.VendorProgramType='ProgramVendor'
-- Vendor Program Promotion
UPDATE stgVendorProgramPromotion Set R_ProgramPromotionId= programpromotions.Id
FROM stgVendorProgramPromotion VPP
INNER JOIN stgVendor V ON V.Id = VPP.VendorId
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
INNER JOIN StgProgramVendorsAssignedToDealer PVATD ON  V.Id = PVATD.VendorId
INNER JOIN ProgramPromotions programpromotions on programpromotions.PromotionCode = VPP.ProgramPromotionCode AND programpromotions.IsActive = 1
INNER JOIN Programs P ON P.ProgramDetailId = programpromotions.ProgramDetailId AND PVATD.R_ProgramId = P.Id
WHERE VPP.Id IS NOT NULL AND VPP.R_ProgramPromotionId IS NULL AND V.RestrictPromotions = 1 AND V.IsVendorProgram=1 AND V.VendorProgramType='DealerOrDistributor'
INSERT INTO #ErrorLogs
SELECT
V.Id
,'Error'
,('Invalid Program Promotion Code {'+CONVERT(nvarchar(MAX),VPP.ProgramPromotionCode) +'} for VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
FROM stgVendor V
INNER JOIN stgVendorProgramPromotion VPP ON VPP.VendorId = V.Id
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
WHERE VPP.Id IS NOT NULL AND VPP.R_ProgramPromotionId IS NULL AND V.RestrictPromotions = 1 AND V.IsVendorProgram=1 AND V.VendorProgramType='DealerOrDistributor'
UPDATE stgVendorPayoffTemplateAssignment SET [IsDefault] = 0
WHERE Id <> ALL (SELECT MAX(V.Id) From stgVendorPayoffTemplateAssignment V
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
WHERE [IsDefault] = 1
GROUP BY VendorId
HAVING COUNT(VendorId) > 1)
UPDATE stgProgramVendorsAssignedToDealer SET [IsDefault] = 0
WHERE Id <> ALL (SELECT MAX(V.Id) From stgProgramVendorsAssignedToDealer V
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
WHERE [IsDefault] = 1
GROUP BY VendorId
HAVING COUNT(VendorId) > 1)

UPDATE stgVendorPayoffTemplateAssignment Set R_PayOffTemplateId= templates.Id
FROM stgVendorPayoffTemplateAssignment Payoff
INNER JOIN stgVendor V ON V.Id = payoff.VendorId
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
INNER JOIN PayOffTemplates templates ON Payoff.PayOffTemplateName = templates.TemplateName
WHERE templates.IsActive =1 AND templates.TemplateType = 'Vendor' AND V.IsMigrated = 0
AND payoff.Id IS NOT NULL AND R_PayOffTemplateId IS NULL
AND (templates.FRRApplicable = 0 OR (templates.FRRApplicable = 1 AND ( (templates.FRROption = '_' AND V.FirstRightOfRefusal = '_') OR (templates.FRROption != '_' AND V.FirstRightOfRefusal != '_') )))
AND (templates.RetainedVendorApplicable =0 OR (templates.RetainedVendorApplicable =1 AND (templates.VendorRetained = V.IsRetained)))
INSERT INTO #ErrorLogs
SELECT
V.Id
,'Error'
,('Invalid PayOff Template Name for Vendor with  VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
FROM stgVendor V
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
INNER JOIN stgVendorPayoffTemplateAssignment payoff ON payoff.VendorId = V.Id
WHERE payoff.Id Is NOT NULL AND payoff.R_PayOffTemplateId IS NULL
-- Vendor Validations
UPDATE stgVendor Set R_LanguageConfigId = L.Id
FROM stgVendor V
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
INNER JOIN dbo.LanguageConfigs L ON V.Language = L.Name AND L.IsActive=1
WHERE V.Language Is NOT NULL AND V.R_LanguageConfigId Is NULL
INSERT INTO #ErrorLogs
SELECT
V.Id
,'Error'
,('Invalid Language for VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
FROM stgVendor V
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
WHERE V.Language Is NOT NULL AND V.R_LanguageConfigId Is NULL
INSERT INTO #ErrorLogs
SELECT
V.Id
,'Error'
,('A Vendor {'+V.VendorNumber+'} With ParentVendorNumber {'+V.ParentVendorNumber+'} cannot act as a Parent to itself') AS Message
FROM
stgVendor V
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
WHERE V.ParentVendorNumber IS NOT NULL AND V.VendorNumber = V.ParentVendorNumber
INSERT INTO #ErrorLogs
SELECT
V.Id
,'Error'
,('Please enter Type for Vendor with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}') AS Message
FROM stgVendor V
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
WHERE V.Type IS NULL
INSERT INTO #ErrorLogs
SELECT
V.Id
,'Error'
,('Lessor Contact Email is required for Vendor with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
FROM stgVendor V
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
WHERE V.IsVendorProgram=1 AND  V.LessorContactEmail IS NULL
INSERT INTO #ErrorLogs
SELECT
V.Id
,'Error'
,('At least one Active Vendor Legal Entity Association for Vendor with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
FROM stgVendor V
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
INNER JOIN stgVendorLegalEntity VLE ON VLE.VendorId = V.Id
WHERE VLE.Id IS NULL
INSERT INTO #ErrorLogs
SELECT
V.Id
,'Error'
,('Contingency percentage is mandatory for Vendor with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
FROM stgVendor V
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
WHERE
V.IsContingencyPercentage=1 AND V.ContingencyPercentage IS NULL
INSERT INTO #ErrorLogs
SELECT
V.Id
,'Error'
,('Flat Fee Amount is mandatory for Vendor with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
FROM stgVendor V
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
WHERE
V.IsFlatFee = 1 AND V.FlatFeeAmount_Amount IS NULL
INSERT INTO #ErrorLogs
SELECT
V.Id
,'Error'
,('Hourly Amount is mandatory for Vendor with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
FROM stgVendor V
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
WHERE
V.IsHourly =1 AND V.HourlyAmount_Amount IS NULL
INSERT INTO #ErrorLogs
SELECT
V.Id
,'Error'
,('RVI Factor should be between 0 and 1 for Vendor with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
FROM stgVendor V
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
WHERE
V.Type='Insurance' AND V.RVIFactor NOT BETWEEN 0 AND 1
INSERT INTO #ErrorLogs
SELECT
V.Id
,'Error'
,('Doc Fee Amount / Doc Fee % must not be negative for Vendor with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
FROM stgVendor V
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
WHERE
((V.IsPercentageBasedDocFee=0 AND V.DocFeeAmount_Amount< 0) OR (V.IsPercentageBasedDocFee=1 AND V.DocFeePercentage<0))

SELECT
*
INTO #ErrorLogDetails
FROM #ErrorLogs ORDER BY StagingRootEntityId ;
WHILE @SkipCount < @TotalRecordsCount
BEGIN
BEGIN TRY
BEGIN TRANSACTION
CREATE TABLE #CreatedVendors
(
[Id] BIGINT NOT NULL
,[VendorId] BIGINT NOT NULL
);
CREATE TABLE #CreatedRemitToIds
(
[Action] NVARCHAR(10) NOT NULL,
[Id] bigint NOT NULL,
[RemitToId] bigint NOT NULL,
[VendorId]  bigint NOT NULL,
);
CREATE TABLE #CreatedProcessingLogs
(
[Action] NVARCHAR(10) NOT NULL,
[Id] bigint NOT NULL
);
SELECT TOP(@TakeCount) V.*
INTO #Vendors
FROM stgVendor V
INNER JOIN #VendorIdsToMigrate VendorId ON VendorId.Id = V.Id
WHERE
NOT Exists (SELECT * FROM #ErrorLogDetails WHERE StagingRootEntityId = V.Id);
SELECT @BatchCount = ISNULL(COUNT(Id),0) FROM #Vendors;
INSERT INTO #CreatedVendors (Id,VendorId)
SELECT P.Id,V.Id
FROM
Parties P
INNER JOIN
#Vendors V ON V.VendorNumber = P.PartyNumber
INSERT INTO [dbo].[PartyRoles]
(
[Role]
,[CreatedById]
,[CreatedTime]
,[PartyId]
)
SELECT
'Vendor'
,@UserId
,@CreatedTime
,#CreatedVendors.Id
FROM #CreatedVendors
INSERT INTO [dbo].[Vendors]
([Id]
,[Type]
,[Status]
,[Status1099]
,[ActivationDate]
,[NextReviewDate]
,[InactivationReason]
,[RejectionReasonCode]
,[W8IssueDate]
,[W8ExpirationDate]
,[FATCA]
,[Percentage1441]
,[IsVendorProgram]
,[IsVendorRecourse]
,[VendorProgramType]
,[MaxQuoteExpirationDays]
,[LessorContactEmail]
,[RVIFactor]
,[ApprovalStatus]
,[IsForVendorLegalEntityAddition]
,[IsForRemittance]
,[IsForVendorEdit]
,[LEApprovalStatus]
,[Website]
,[SalesTaxRate]
,[Specialities]
,[MaximumResidualSharingPercentage]
,[MaximumResidualSharingAmount_Amount]
,[MaximumResidualSharingAmount_Currency]
,[IsFlatFee]
,[IsContingencyPercentage]
,[IsHourly]
,[FlatFeeAmount_Amount]
,[FlatFeeAmount_Currency]
,[HourlyAmount_Amount]
,[HourlyAmount_Currency]
,[ContingencyPercentage]
,[PTMSExternalId]
,[ParalegalName]
,[SecretaryName]
,[WebPage]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[LineofBusinessId]
,[FundingApprovalLeadDays]
,[IsPercentageBasedDocFee]
,[DocFeePercentage]
,[DocFeeAmount_Amount]
,[DocFeeAmount_Currency]
,[IsManualCreditDecision]
,[IsPITAAgreement]
,[PITASignedDate]
,[RestrictPromotions]
,[PSTorQSTNumber]
,[FirstRightOfRefusal]
,[IsRetained]
,[IsAMReviewRequired]
,[IsNotQuotable]
,[ProgramId]
,[IsWithholdingTaxApplicable]
,IsRelatedToLessor
,BusinessTypeId
,IsRoadTrafficOffice
,IsMunicipalityRoadTax
)
SELECT
#CreatedVendors.Id
,Vendor.[Type]
,Vendor.[Status]
,Vendor.[Status1099]
,Vendor.[ActivationDate]
,Vendor.[NextReviewDate]
,NULL--Vendor.[InactivationReason]
,'_'--Vendor.[RejectionReasonCode]
,Vendor.[W8IssueDate]
,Vendor.[W8ExpirationDate]
,ISNULL(Vendor.[FATCA],0)
,ISNULL(Vendor.[Percent1441],0)
,Vendor.[IsVendorProgram]
,Vendor.[IsVendorRecourse]
,Vendor.[VendorProgramType]
,0 [MaxQuoteExpirationDays]
,Vendor.[LessorContactEmail]
,Vendor.[RVIFactor]
,Vendor.[ApprovalStatus]
,0--Vendor.[IsForVendorLegalEntityAddition]
,0--Vendor.[IsForRemittance]
,0--Vendor.[IsForVendorEdit]
,Vendor.ApprovalStatus
,Vendor.[Website]
,Vendor.[SalesTaxRate]
,Vendor.[Specialities]
,Vendor.[MaximumResidualSharingPercentage]
,Vendor.[MaximumResidualSharingAmount_Amount]
,Vendor.[MaximumResidualSharingAmount_Currency]
,Vendor.[IsFlatFee]
,Vendor.IsContingencyPercentage
,Vendor.[IsHourly]
,Vendor.[FlatFeeAmount_Amount]
,Vendor.[FlatFeeAmount_Currency]
,Vendor.[HourlyAmount_Amount]
,Vendor.[HourlyAmount_Currency]
,Vendor.ContingencyPercentage
,Vendor.[PTMSExternalId]
,Vendor.[ParalegalName]
,Vendor.[SecretaryName]
,Vendor.[WebPage]
,@UserId
,@CreatedTime
,NULL
,NULL
,Vendor.R_LineofBusinessId
,Vendor.[FundingApprovalLeadDays]
,Vendor.[IsPercentageBasedDocFee]
,Vendor.[DocFeePercentage]
,Vendor.[DocFeeAmount_Amount]
,Vendor.[DocFeeAmount_Currency]
,Vendor.[IsManualCreditDecision]
,Vendor.[IsPITAAgreement]
,Vendor.[PITASignedDate]
,Vendor.[RestrictPromotions]
,Vendor.[PSTorQSTNumber]
,Vendor.[FirstRightOfRefusal]
,Vendor.[IsRetained]
,Vendor.[IsAMReviewRequired]
,Vendor.IsNotQuotable
,Vendor.[R_ProgramId]
,Vendor.[IsWithholdingTaxApplicable]
,Vendor.IsRelatedToLessor
,Vendor.R_LegalOrganizationFormId
,Vendor.IsRoadTrafficOffice
,Vendor.IsMunicipalityRoadTax
FROM stgVendor Vendor
INNER JOIN #CreatedVendors ON #CreatedVendors.VendorId = Vendor.Id
INNER JOIN stgCustomer Customer ON Customer.CustomerNumber = Vendor.VendorNumber
/*Vendor Contact Types*/
/* Set Customer Main Contact as Vendor Primary and PayTO Contacts*/
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
,'Primary'
,@UserId
,@CreatedTime
,PC.Id
,0
FROM
PartyContacts PC
INNER JOIN
#CreatedVendors CV ON CV.Id = PC.PartyId
INNER JOIN
PartyContactTypes PCT ON PCT.PartyContactId = PC.Id
WHERE PCT.ContactType = 'Main'
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
,'PayTo'
,@UserId
,@CreatedTime
,PC.Id
,0
FROM
PartyContacts PC
INNER JOIN
#CreatedVendors CV ON CV.Id = PC.PartyId
INNER JOIN
PartyContactTypes PCT ON PCT.PartyContactId = PC.Id
WHERE PCT.ContactType = 'Main'
INSERT INTO [dbo].[VendorLegalEntities]
([IsApproved]
,[IsOnHold]
,[IsActive]
,[CumulativeFundingLimit_Amount]
,[CumulativeFundingLimit_Currency]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[LegalEntityId]
,[VendorId])
SELECT
[IsApproved]
,[IsOnHold]
,1--[IsActive]
,[CumulativeFundingLimit_Amount]
,[CumulativeFundingLimit_Currency]
,@UserId
,@CreatedTime
,NULL
,NULL
,VLE.R_LegalEntityId
,#CreatedVendors.Id
FROM stgVendor V
INNER JOIN stgVendorLegalEntity VLE ON V.Id = VLE.VendorId
INNER JOIN #CreatedVendors ON #CreatedVendors.VendorId = V.Id
INSERT INTO [dbo].[VendorProgramPromotions]
([IsActive]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[ProgramPromotionId]
,[VendorId])
SELECT
1--[IsActive]
,@UserId
,@CreatedTime
,NULL
,NULL
,VPP.R_ProgramPromotionId
,#CreatedVendors.Id
FROM stgVendor V
INNER JOIN stgVendorProgramPromotion VPP ON V.Id = VPP.VendorId
INNER JOIN #CreatedVendors ON #CreatedVendors.VendorId = V.Id
MERGE RemitToes
USING(SELECT VRT.*,#CreatedVendors.VendorId AS VendorRemitToId,PartyAddresses.Id AS AddressId, Parties.PortfolioId AS PortfolioId
FROM stgVendorRemitTo VRT
INNER JOIN #CreatedVendors ON #CreatedVendors.VendorId = VRT.VendorId
INNER JOIN PartyAddresses ON PartyAddresses.Id=VRT.R_AddressUniqueIdentifier
INNER JOIN Parties ON Parties.Id = #CreatedVendors.Id
WHERE R_AddressUniqueIdentifier IS NOT NULL) AS VendorRemitTo
ON 1=0
WHEN NOT MATCHED
THEN
INSERT
([Name]
,[Code]
,[UniqueIdentifier]
,[ReceiptType]
,[WireType]
,[IsActive]
,[ActivationDate]
,[DeactivationDate]
,[Description]
,[IsSecuredParty]
,[IsPrivateLabel]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[LegalEntityContactId]
,[LegalEntityAddressId]
,[PartyContactId]
,[PartyAddressId]
,[UserGroupId]
,[LogoId]
,[DefaultFromEmail]
,[InvoiceComment]
,[InvoiceFooterText]
,PortfolioId
)
VALUES(
VendorRemitTo.RemitToName
,VendorRemitTo.RemitToCode
,VendorRemitTo.RemitToUniqueIdentifier
,VendorRemitTo.ReceiptType
,CASE WHEN VendorRemitTo.ReceiptType ='Check' THEN '_'
WHEN VendorRemitTo.ReceiptType = 'ACH' AND VendorRemitTo.WireType IS NULL THEN '_'
ELSE VendorRemitTo.WireType
END
,1
,[ActivationDate]
,NULL
,[Description]
,VendorRemitTo.SecuredParty
,VendorRemitTo.IsPrivateLabel
,@UserId
,@CreatedTime
,NULL
,NULL
,NULL--[LegalEntityContactId]
,NULL--[LegalEntityAddressId]
,NULL--VendorRemitTo.ContactId
,VendorRemitTo.AddressId
,NULL
,VendorRemitTo.R_LogoId
,[DefaultFromEmail]
,NULL--[InvoiceComment]
,NULL--[InvoiceFooterText]
,PortfolioId
)
OUTPUT $action, Inserted.Id, VendorRemitTo.Id,VendorRemitTo.VendorRemitToId INTO #CreatedRemitToIds;
INSERT INTO [dbo].[PartyRemitToes]
([IsDefault]
,[RemittanceGroupingOption]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[RemitToId]
,[PartyId])
SELECT
VRT.IsDefault
,VRT.RemittanceGroupingOption
,@UserId
,@CreatedTime
,NULL
,NULL
,#CreatedRemitToIds.Id
,#CreatedVendors.Id
FROM
stgVendorRemitTo VRT
INNER JOIN #CreatedRemitToIds ON #CreatedRemitToIds.RemitToId = VRT.Id
INNER JOIN #CreatedVendors ON #CreatedVendors.VendorId = #CreatedRemitToIds.VendorId
INSERT INTO [dbo].[RemitToWireDetails]
([IsBeneficiary]
,[IsCorrespondent]
,[IsActive]
,[ACHOriginatorID]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[BankAccountId]
,[RemitToId]
,[UniqueIdentifier]
)
SELECT
VRTW.IsBeneficiary
,VRTW.[IsCorrespondent]
,1
,NULL
,@UserId
,@CreatedTime
,NULL
,NULL
,R_BankAccountId
,#CreatedRemitToIds.Id
,CONCAT(VRTW.UniqueIdentifier,#CreatedRemitToIds.Id)
FROM stgVendorRemitToWireDetail  VRTW
INNER JOIN stgVendorRemitTo VRT ON VRT.Id = VRTW.VendorRemitToId AND VRTW.R_BankAccountId IS NOT NULL
INNER JOIN #CreatedRemitToIds ON #CreatedRemitToIds.RemitToId = VRT.Id AND VRT.ReceiptType!='Check'
MERGE [ProgramsAssignedToAllVendors] Target
USING(SELECT CAST(1 AS BIT) AS IsAssigned,
@UserId as [CreatedById],
@CreatedTime as [CreatedTime],
@UserId as [UpdatedById],
@CreatedTime as [UpdatedTime],
PAD.[AssignmentDate],
PAD.[ExternalVendorCode],
PAD.R_LineofBusinessId as [LineofBusinessId],
PAD.R_ProgramVendorId as[ProgramVendorId],
PAD.R_ProgramId as [ProgramId],
#CreatedVendors.Id as [VendorId],
PAD.[IsDefault]  FROM stgProgramVendorsAssignedToDealer PAD
INNER JOIN stgVendor V ON PAD.VendorId = V.Id
INNER JOIN #CreatedVendors ON #CreatedVendors.VendorId = V.Id
WHERE PAD.Id IS NOT NULL AND V.IsVendorProgram=1 AND V.VendorProgramType='DealerOrDistributor'And
PAD.R_LineofBusinessId IS NOT NULL AND
PAD.R_ProgramId IS NOT NULL AND
PAD.R_ProgramVendorId IS NOT NULL
) AS Source
ON Target.VendorId = Source.VendorId and Target.ProgramId =Source.ProgramId
and Target.ProgramVendorId = source.ProgramVendorId
WHEN NOT MATCHED
THEN
INSERT
(
[IsAssigned],
[CreatedById],
[CreatedTime],
[UpdatedById],
[UpdatedTime],
[AssignmentDate],
[ExternalVendorCode],
[LineofBusinessId],
[ProgramVendorId],
[ProgramId],
[VendorId],
[IsDefault]
)
VALUES
(
Source.[IsAssigned],
Source.[CreatedById],
Source.[CreatedTime],
Source.[UpdatedById],
Source.[UpdatedTime],
Source.[AssignmentDate],
Source.[ExternalVendorCode],
Source.[LineofBusinessId],
Source.[ProgramVendorId],
Source.[ProgramId],
Source.[VendorId],
Source.[IsDefault]
)
When Matched then
update set
[IsAssigned] =Source.[IsAssigned],
[UpdatedById]=Source.[UpdatedById],
[UpdatedTime]=Source.[UpdatedTime],
[AssignmentDate]=Source.[AssignmentDate],
[ExternalVendorCode]=Source.[ExternalVendorCode],
[LineofBusinessId]=Source.[LineofBusinessId],
[IsDefault]=Source.[IsDefault]
;
INSERT INTO [dbo].[VendorPayoffTemplateAssignments]
([IsDefault]
,[IsActive]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[PayOffTemplateId]
,[VendorId]
,[IsAvailableInVendorPortal])
SELECT
payoff.[IsDefault]
,1
,@UserId
,@CreatedTime
,NULL
,NULL
,R_PayOffTemplateId
,#CreatedVendors.Id
,0
FROM stgVendorPayoffTemplateAssignment payoff
INNER JOIN stgVendor V ON payoff.VendorId = V.Id
INNER JOIN  #CreatedVendors ON V.Id = #CreatedVendors.VendorId
WHERE R_PayOffTemplateId IS NOT NULL

UPDATE Parties SET CurrentRole='Vendor'
FROM stgVendor vendor
INNER JOIN Parties customer ON vendor.VendorNumber = customer.PartyNumber
WHERE vendor.IsMigrated = 0

UPDATE  stgVendor SET IsMigrated = 1 ,UpdatedById = @UserId , UpdatedTime = @CreatedTime
WHERE Id in ( SELECT VendorId FROM #CreatedVendors);
MERGE stgProcessingLog AS ProcessingLog
USING (SELECT VendorId FROM #CreatedVendors
) AS ProcessedVendors
ON (ProcessingLog.StagingRootEntityId = ProcessedVendors.VendorId AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
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
ProcessedVendors.VendorId
,@UserId
,@CreatedTime
,@ModuleIterationStatusId
)
OUTPUT $action, Inserted.Id INTO #CreatedProcessingLogs;
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
SET @SkipCount = @SkipCount + @TakeCount;
IF EXISTS(SELECT Id FROM #CreatedVendors)
BEGIN
SET @Number = (SELECT MAX(Id) FROM #CreatedVendors)
SET @SQL = 'ALTER SEQUENCE party RESTART WITH ' + CONVERT(NVARCHAR(20),@Number+1)
EXEC sp_executesql @sql
END
IF EXISTS(SELECT Id FROM #CreatedRemitToIds)
BEGIN
SET @Number = (SELECT MAX(Id) FROM #CreatedRemitToIds)
SET @SQL = 'ALTER SEQUENCE RemitToWireDetail RESTART WITH ' + CONVERT(NVARCHAR(20),@Number+1)
EXEC sp_executesql @sql
END
DROP TABLE #CreatedVendors
DROP TABLE #CreatedProcessingLogs
DROP TABLE #Vendors
DROP TABLE #CreatedRemitToIds
COMMIT TRANSACTION
END TRY
BEGIN CATCH
SET @SkipCount = @SkipCount  + @TakeCount;
DECLARE @ErrorMessage Nvarchar(max);
DECLARE @ErrorLine Nvarchar(max);
DECLARE @ErrorSeverity INT;
DECLARE @ErrorState INT;
DECLARE @ErrorLogs ErrorMessageList;
DECLARE @ModuleName Nvarchar(max) = 'MigrateVendorForCustomers'
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
MERGE stgProcessingLog AS ProcessingLog
USING (SELECT DISTINCT StagingRootEntityId FROM #ErrorLogDetails ) AS ErrorVendors
ON (ProcessingLog.StagingRootEntityId = ErrorVendors.StagingRootEntityId AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
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
ErrorVendors.StagingRootEntityId
,@UserId
,@CreatedTime
,@ModuleIterationStatusId
)
OUTPUT $action, Inserted.Id, ErrorVendors.StagingRootEntityId INTO #FailedProcessingLogs;
INSERT INTO stgProcessingLogDetail
(
Message
,Type
,CreatedById
,CreatedTime
,ProcessingLogId
)
SELECT
#ErrorLogs.Message
,'Error'
,@UserId
,@CreatedTime
,#FailedProcessingLogs.Id
FROM #ErrorLogs
JOIN #FailedProcessingLogs ON #ErrorLogs.StagingRootEntityId = #FailedProcessingLogs.VendorId;
SET @FailedRecords = @FailedRecords+(SELECT COUNT(DISTINCT StagingRootEntityId) FROM #ErrorLogDetails)
SET @ProcessedRecords = @ProcessedRecords + @TotalRecordsCount;
DROP TABLE #ErrorLogs;
DROP TABLE #ErrorLogDetails;
DROP TABLE #FailedProcessingLogs;
DROP TABLE #VendorIdsToMigrate;
END
SET NOCOUNT OFF;
SET XACT_ABORT OFF;

GO

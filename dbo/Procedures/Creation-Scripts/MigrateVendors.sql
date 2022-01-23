SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[MigrateVendors]
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
	[Action] NVARCHAR(10) NOT NULL,
	[Id] BIGINT NOT NULL,
	[VendorId] BIGINT NOT NULL
);	
    DECLARE @Counter INT = 0;
	DECLARE @TakeCount INT = 50000;
	DECLARE @SkipCount INT = 0;
	DECLARE @BatchCount INT = 0;
	DECLARE @MaxErrorStagingRootEntityId INT = 0;
	SET @FailedRecords = 0;
	SET @ProcessedRecords = 0;
	DECLARE @TotalRecordsCount INT = (SELECT COUNT(Id) FROM stgVendor WHERE IsMigrated = 0);
	SET @MaxErrorStagingRootEntityId= 0;
	SET @SkipCount = 0;
	DECLARE @DefaultCountry NVARCHAR(40);
	SELECT @DefaultCountry = ISNULL(Value,'USA') FROM GlobalParameters WHERE Category ='Country' AND Name ='DefaultCountry' AND IsActive = 1
	UPDATE stgVendor Set R_StateofIncorporationId = States.Id
	FROM stgVendor V
	INNER JOIN States ON UPPER(States.ShortName) = UPPER(V.StateOfIncorporation)
	WHERE IsMigrated = 0 AND V.StateOfIncorporation IS NOT NULL AND V.R_StateofIncorporationId IS NULL 
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Invalid State of Incorporation for VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	WHERE V.IsMigrated = 0 AND V.StateOfIncorporation IS NOT NULL AND V.R_StateofIncorporationId IS NULL 
	UPDATE stgVendor Set R_LineofBusinessId = LineofBusinesses.Id
	FROM stgVendor vendor
	INNER JOIN LineofBusinesses ON LineofBusinesses.Name = vendor.LineofBusinessName
	WHERE vendor.IsMigrated = 0 AND vendor.LineofBusinessName IS NOT NULL AND vendor.R_LineofBusinessId IS NULL;  
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Invalid Default Line of Business for VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	WHERE V.IsMigrated = 0 AND V.LineofBusinessName IS NOT NULL AND V.R_LineofBusinessId IS NULL 

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
	WHERE V.IsMigrated = 0 AND V.Type IS NULL
	UPDATE stgVendor Set R_PortfolioId = Portfolios.Id
	FROM stgVendor vendor
	INNER JOIN Portfolios ON Portfolios.Name = vendor.PortfolioName
	WHERE vendor.IsMigrated = 0 AND vendor.R_PortfolioId IS NULL;
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Invalid Portfolio Name for VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	WHERE V.IsMigrated = 0 AND R_PortfolioId IS NULL
	----Vendor Address
	UPDATE stgVendorAddress Set R_CountryId = Countries.Id
	FROM stgVendorAddress VA
	INNER JOIN stgVendor V ON V.Id = VA.VendorId
	INNER JOIN dbo.Countries ON VA.Country = Countries.ShortName
	WHERE V.IsMigrated = 0 AND VA.Country IS NOT NULL AND VA.R_CountryId IS NULL
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Invalid Country for Vendor Address Id {'+CONVERT(NVARCHAR(MAX),VA.Id)+'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	INNER JOIN stgVendorAddress VA ON VA.VendorId= V.Id
	WHERE V.IsMigrated = 0 AND VA.Country IS NOT NULL AND VA.R_CountryId IS NULL
	UPDATE stgVendorAddress Set R_HomeCountryId = Countries.Id
	FROM stgVendorAddress VA
	INNER JOIN stgVendor V ON V.Id = VA.VendorId
	INNER JOIN dbo.Countries ON VA.HomeCountry = Countries.ShortName
	WHERE V.IsMigrated = 0 AND VA.HomeCountry IS NOT NULL AND VA.R_HomeCountryId IS NULL
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Invalid HomeCountry for Vendor Address Id {'+CONVERT(NVARCHAR(MAX),VA.Id)+'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	INNER JOIN stgVendorAddress VA ON VA.VendorId = V.Id
	WHERE V.IsMigrated = 0 AND VA.HomeCountry IS NOT NULL AND VA.R_HomeCountryId IS NULL
	UPDATE stgVendorAddress Set R_StateId = States.Id
	FROM stgVendorAddress VA
	INNER JOIN stgVendor V ON V.Id = VA.VendorId
	INNER JOIN dbo.States ON VA.State = States.ShortName AND States.CountryId = VA.R_CountryId
	WHERE V.IsMigrated = 0 AND VA.State IS NOT NULL AND VA.R_StateId IS NULL
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Invalid State for Vendor Address Id {'+CONVERT(NVARCHAR(MAX),VA.Id)+'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	INNER JOIN stgVendorAddress VA ON VA.VendorId = V.Id
	WHERE V.IsMigrated = 0 AND VA.State IS NOT NULL AND VA.R_StateId IS NULL
	UPDATE stgVendorAddress Set R_HomeStateId = States.Id
	FROM stgVendorAddress VA
	INNER JOIN stgVendor V ON V.Id = VA.VendorId
	INNER JOIN dbo.States ON VA.HomeState = States.ShortName AND States.CountryId = VA.R_HomeCountryId
	WHERE V.IsMigrated = 0 AND VA.HomeState IS NOT NULL AND VA.R_HomeStateId IS NULL
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Invalid HomeState for Vendor Address Id {'+CONVERT(NVARCHAR(MAX),VA.Id)+'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	INNER JOIN stgVendorAddress VA ON VA.VendorId = V.Id
	WHERE V.IsMigrated = 0 AND VA.HomeState IS NOT NULL AND VA.R_HomeStateId IS NULL
	UPDATE stgVendor SET R_IsUSBased = 1
	FROM stgVendor V
	INNER JOIN stgVendorAddress VA ON VA.VendorId = V.Id
	WHERE (VA.Country= @DefaultCountry OR VA.HomeCountry = @DefaultCountry) AND V.IsMigrated = 0
	UPDATE stgVendor SET R_IsLegalEntityUSBased = 1
	FROM stgVendor V
	INNER JOIN stgVendorLegalEntity VLE ON VLE.VendorId = V.Id
	INNER JOIN LegalEntities  LE ON VLE.LegalEntityNumber = LE.LegalEntityNumber
	INNER JOIN LegalEntityAddresses address on address.LegalEntityId = LE.Id 
	INNER JOIN States state on state.Id = address.StateId
	INNER JOIN Countries country on country.Id= state.Id 
	WHERE (country.ShortName = @DefaultCountry) AND address.IsActive=1 AND V.IsMigrated = 0
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Remove W8IssueDate/W8ExpirationDate/FATCA/Percentage1441 for Vendor with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	WHERE V.IsMigrated = 0 AND (V.R_IsUSBased = 1 OR (V.R_IsLegalEntityUSBased != 1 AND V.R_IsUSBased != 1)) 
	AND (V.W8IssueDate IS NOT NULL OR V.W8ExpirationDate IS NOT NULL OR V.FATCA !=0 OR V.Percent1441 !=0)

----Vendor Tax Registration Details	
Update stgVendorTaxRegistrationDetail Set R_CountryId = Countries.Id
FROM stgVendorTaxRegistrationDetail VTRD
INNER JOIN stgVendor C ON C.Id = VTRD.VendorId
INNER JOIN dbo.Countries ON VTRD.CountryName = Countries.ShortName AND Countries.IsActive = 1
WHERE C.IsMigrated = 0 AND VTRD.CountryName Is NOT NULL
INSERT INTO #ErrorLogs
select
	C.Id,'Error',
	('Invalid Country ShortName '+ISNULL(VTRD.CountryName,'NULL'))
from stgVendor C
INNER JOIN stgVendorTaxRegistrationDetail VTRD on VTRD.VendorId = C.Id
where VTRD.R_CountryId is null

Update stgVendorTaxRegistrationDetail Set R_StateId = States.Id
FROM stgVendorTaxRegistrationDetail VTRD
INNER JOIN stgVendor C ON C.Id = VTRD.VendorId
INNER JOIN dbo.States ON VTRD.StateName = States.ShortName AND States.IsActive = 1
WHERE C.IsMigrated = 0 AND VTRD.StateName Is NOT NULL 
INSERT INTO #ErrorLogs
select
	C.Id,'Error',
	('Invalid State ShortName '+ISNULL(VTRD.StateName,'NULL'))
	from stgVendor C
INNER JOIN stgVendorTaxRegistrationDetail VTRD on VTRD.VendorId = C.Id
where VTRD.R_StateId is null

	--Vendor Contact
	UPDATE stgVendorContact Set R_VendorId = Parties.Id
	FROM stgVendorContact VC
	INNER JOIN stgVendor V ON VC.VendorId = V.Id
	INNER JOIN Parties ON Parties.PartyNumber = VC.VendorNumber
	WHERE IsMigrated = 0 AND VC.VendorNumber IS NOT NULL AND VC.R_VendorId IS NULL;  
	INSERT INTO #ErrorLogs
	SELECT 
	V.Id
	,'Error'
	,('Invalid VendorNumber for VendorContact with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendorContact VC
	INNER JOIN stgVendor V ON VC.VendorId = V.Id
	WHERE V.IsMigrated = 0 AND VC.VendorNumber IS NOT NULL AND VC.R_VendorId Is NULL
	----Vendor BankAccount
	UPDATE stgVendorBankAccount Set R_BankBranchId = BankBranches.Id
	FROM stgVendorBankAccount VBA
	INNER JOIN stgVendor V ON V.Id =VBA.VendorId
	INNER JOIN BankBranches ON UPPER(VBA.BankBranchName) = UPPER(BankBranches.Name)
	WHERE V.IsMigrated = 0 AND VBA.BankBranchName IS NOT NULL AND VBA.R_BankBranchId IS NULL
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Invalid BankBranch for VendorBankAccount Id {'+CONVERT(NVARCHAR(MAX),VBA.Id)+'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	INNER JOIN stgVendorBankAccount VBA ON VBA.VendorId= V.Id
	WHERE V.IsMigrated = 0 AND VBA.BankBranchName IS NOT NULL AND VBA.R_BankBranchId IS NULL
	UPDATE stgVendorBankAccount Set R_CurrencyId = Currencies.Id
	FROM stgVendorBankAccount VBA
	INNER JOIN stgVendor V ON V.Id = VBA.VendorId
	INNER JOIN CurrencyCodes ON CurrencyCodes.ISO = VBA.CurrencyCode
	INNER JOIN dbo.Currencies ON CurrencyCodes.Id = Currencies.CurrencyCodeId
	WHERE V.IsMigrated = 0 AND VBA.CurrencyCode IS NOT NULL AND VBA.R_CurrencyId IS NULL
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Invalid Currency for VendorBankAccount Id {'+CONVERT(NVARCHAR(MAX),VBA.Id)+'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	INNER JOIN stgVendorBankAccount VBA ON VBA.VendorId = V.Id
	WHERE V.IsMigrated = 0 AND VBA.CurrencyCode IS NOT NULL AND VBA.R_CurrencyId IS NULL
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('GL Segment Value cannot be null for VendorBankAccount Id {'+CONVERT(NVARCHAR(MAX),VBA.Id)+'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	INNER JOIN stgVendorBankAccount VBA ON VBA.VendorId = V.Id
	WHERE V.IsMigrated = 0 AND VBA.GLSegmentValue IS NULL AND V.IsInterCompany = 1
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('IBAN is Invalid. First two characters must be alphabets and Length must be between 4 and 34 for VendorBankAccount Id {'+CONVERT(NVARCHAR(MAX),VBA.Id)+'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	INNER JOIN stgVendorBankAccount VBA ON VBA.VendorId = V.Id
	WHERE V.IsMigrated = 0 AND VBA.IBAN IS NOT NULL AND VBA.IBAN NOT LIKE '[a-Z][a-Z]%' OR (LEN(VBA.IBAN) NOT BETWEEN 4 AND 34)
--	INSERT INTO #ErrorLogs
--	SELECT
--	VBA.VendorId
--	,'Error'
--	,('The combination of fields Bank Name, Branch Name and Account Number should be unique. Please check for Bank Accounts with the following Account Numbers: '+ VBA.AccountNumber+' with Vendor Id {'+CONVERT(NVARCHAR(MAX),VBA.VendorId)+'}') AS Message
--FROM 
--stgVendorBankAccount VBA
--INNER JOIN stgVendor V ON V.Id = VBA.VendorId
--WHERE V.IsMigrated=0 
--GROUP BY VBA.VendorId,VBA.AccountNumber,VBA.BankBranchName
--HAVING COUNT(*)>1
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Please enter Account Number for VendorBankAccount Id {'+CONVERT(NVARCHAR(MAX),VBA.Id)+'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	INNER JOIN stgVendorBankAccount VBA ON VBA.VendorId = V.Id
	JOIN BankBranches BB ON VBA.R_BankBranchId = BB.Id
	LEFT JOIN CountryCurrencyRelationships CCR ON BB.CountryId = CCR.CountryId AND VBA.R_CurrencyId = CCR.CurrencyId
	WHERE (CCR.Id Is NULL OR CCR.MandatoryAccountNumberField = 'AccountNumber') AND (VBA.AccountNumber IS NULL OR VBA.AccountNumber ='')
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Please enter IBAN for VendorBankAccount Id {'+CONVERT(NVARCHAR(MAX),VBA.Id)+'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	JOIN stgVendorBankAccount VBA ON VBA.VendorId = V.Id
	JOIN BankBranches BB ON VBA.R_BankBranchId = BB.Id
	JOIN CountryCurrencyRelationships CCR ON BB.CountryId = CCR.CountryId AND VBA.R_CurrencyId = CCR.CurrencyId
	WHERE (CCR.MandatoryAccountNumberField = 'IBAN') AND (VBA.IBAN IS NULL OR VBA.IBAN ='')
	        
	INSERT INTO #ErrorLogs
	SELECT V.Id
		, 'Error'
		,('VendorBankAccount {'+CONVERT(NVARCHAR(MAX),VBA.Id)+'} associated with  VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'} cannot be an ACH or Primary ACH account')
	FROM stgVendor V
	JOIN stgVendorBankAccount VBA ON VBA.VendorId = V.Id
	JOIN BankBranches BB ON VBA.R_BankBranchId = BB.Id
	JOIN CountryCurrencyRelationships CCR ON BB.CountryId = CCR.CountryId AND VBA.R_CurrencyId = CCR.CurrencyId
	WHERE (VBA.IBAN IS NOT NULL AND (VBA.AutomatedPaymentMethod = 'ACHOrPAP' OR VBA.IsPrimaryACH = 1 )) AND CCR.MandatoryAccountNumberField = 'IBAN'
	
	UPDATE stgVendorBankAccount Set R_BankAccountCategoryId= BAC.Id
	FROM stgVendorBankAccount VBA
	INNER JOIN stgVendor V ON VBA.VendorId = V.Id
	INNER JOIN BankAccountCategories BAC ON VBA.BankAccountCategoryName = BAC.AccountCategory
	WHERE 
	V.IsMigrated = 0 AND VBA.BankAccountCategoryName IS NOT NULL
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Bank Account with Id {'+CONVERT(NVARCHAR(MAX),VBA.Id)+'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'} contains invalid Bank Account Category')
	FROM stgVendor V
	INNER JOIN stgVendorBankAccount VBA ON VBA.VendorId = V.Id
	WHERE V.IsMigrated = 0 AND VBA.BankAccountCategoryName Is NOT NULL AND VBA.R_BankAccountCategoryId Is NULL
	INSERT INTO #ErrorLogs
    SELECT
   	    V.Id
	   ,'Error'
	   ,('Bank Account with Id {'+CONVERT(NVARCHAR(MAX),VBA.Id)+'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'} Must have a value for Account Category since  the account is ACH Account')
    FROM stgVendor V
	INNER JOIN stgVendorBankAccount VBA ON VBA.VendorId = V.Id
    WHERE V.IsMigrated=0 AND  VBA.R_BankAccountCategoryId Is NULL AND (VBA.AutomatedPaymentMethod = 'ACHOrPAP' OR VBA.IsPrimaryACH = 1)
	----Employees Assigned To Vendor
	UPDATE stgEmployeesAssignedToVendor Set R_EmployeeId = Users.Id
	FROM stgEmployeesAssignedToVendor EAV
	INNER JOIN stgVendor V ON V.Id = EAV.VendorId
	INNER JOIN Users ON Users.LoginName = EAV.LoginName
	WHERE V.IsMigrated = 0 AND EAV.LoginName Is NOT NULL AND EAV.R_EmployeeId Is NULL
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Invalid Login Name {'+ISNULL(EAV.LoginName,'NULL')+'} for EmployeesAssignedToVendor Id {'+CONVERT(NVARCHAR(MAX),EAV.Id)+'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	INNER JOIN stgEmployeesAssignedToVendor EAV ON EAV.VendorId = V.Id
	WHERE V.IsMigrated = 0 AND EAV.LoginName Is NOT NULL AND EAV.R_EmployeeId Is NULL
	UPDATE stgEmployeesAssignedToVendor Set R_RoleFunctionId = RoleFunctions.Id
	FROM stgEmployeesAssignedToVendor EAV
	INNER JOIN stgVendor V ON V.Id = EAV.VendorId
	INNER JOIN RoleFunctions ON RoleFunctions.Name = EAV.RoleFunctionName
	WHERE V.IsMigrated = 0 AND EAV.RoleFunctionName Is NOT NULL AND EAV.R_RoleFunctionId Is NULL
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Invalid Role Function Name {'+ISNULL(EAV.RoleFunctionName,'NULL')+'} for EmployeesAssignedToVendor Id {'+CONVERT(NVARCHAR(MAX),EAV.Id)+'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	INNER JOIN stgEmployeesAssignedToVendor EAV ON EAV.VendorId = V.Id
	WHERE V.IsMigrated = 0 AND EAV.RoleFunctionName Is NOT NULL AND EAV.R_RoleFunctionId Is NULL
	----Remit To Vendor
	UPDATE stgVendorRemitTo Set R_AddressUniqueIdentifier= VA.Id 
	FROM stgVendorRemitTo VRT
	INNER JOIN stgVendor V ON V.Id = VRT.VendorId
	INNER JOIN stgVendorAddress VA ON VRT.VendorId = VA.VendorId AND VRT.AddressUniqueIdentifier = VA.UniqueIdentifier 
	WHERE V.IsMigrated = 0 AND VRT.Id IS NOT NULL AND VRT.R_AddressUniqueIdentifier Is NULL
	UPDATE stgVendorRemitTo Set R_ContactUniqueIdentifier= VC.Id 
    FROM stgVendorRemitTo VRT
	INNER JOIN stgVendor V ON V.Id = VRT.VendorId
	INNER JOIN stgVendorContact VC ON VRT.VendorId = VC.VendorId AND VRT.ContactUniqueIdentifier = VC.UniqueIdentifier 
	WHERE V.IsMigrated = 0 AND VRT.Id IS NOT NULL AND VRT.R_ContactUniqueIdentifier Is NULL
	UPDATE stgVendorRemitTo Set R_LogoId= Logoes.Id 
	FROM stgVendorRemitTo VRT
	INNER JOIN stgVendor V ON V.Id = VRT.VendorId
	INNER JOIN Logoes Logoes ON Logoes.Name = VRT.LogoName AND Logoes.IsActive=1 AND VRT.LogoEntityType = Logoes.EntityType
	WHERE V.IsMigrated = 0 AND VRT.Id IS NOT NULL AND VRT.LogoName IS NOT NULL AND VRT.R_LogoId Is NULL
	UPDATE stgVendorRemitTo Set R_UserGroupId= UG.Id 
	FROM stgVendorRemitTo VRT
	INNER JOIN stgVendor V ON V.Id = VRT.VendorId
	INNER JOIN UserGroups UG ON UG.Name = VRT.PrivateLabelCollectorUserGroupName AND UG.IsActive=1
	INNER JOIN RoleFunctions RF ON RF.Id = UG.DefaultRoleFunctionId AND RF.SystemDefinedName = 'Collections'	
	WHERE V.IsMigrated = 0 AND VRT.Id IS NOT NULL AND VRT.R_UserGroupId Is NULL AND VRT.IsPrivateLabel = 1
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Invalid Remit To User Group Name {'+ISNULL(VRT.PrivateLabelCollectorUserGroupName,'NULL')+'} for VendorRemitTo Id {'+CONVERT(NVARCHAR(MAX),VRT.Id)+'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	INNER JOIN stgVendorRemitTo VRT ON VRT.VendorId = V.Id
	WHERE V.IsMigrated = 0 AND VRT.Id Is NOT NULL AND  VRT.R_UserGroupId IS NULL AND PrivateLabelCollectorUserGroupName IS NOT NULL
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Invalid Remit To Address UniqueIdentifier {'+ISNULL(VRT.AddressUniqueIdentifier,'NULL')+'} for VendorRemitTo Id {'+CONVERT(NVARCHAR(MAX),VRT.Id)+'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	INNER JOIN stgVendorRemitTo VRT ON VRT.VendorId = V.Id
	WHERE V.IsMigrated = 0 AND VRT.Id Is NOT NULL AND  VRT.R_AddressUniqueIdentifier IS NULL
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Invalid Remit To Contact UniqueIdentifier {'+ISNULL(VRT.ContactUniqueIdentifier,'NULL')+'} for VendorRemitTo Id {'+CONVERT(NVARCHAR(MAX),VRT.Id)+'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	INNER JOIN stgVendorRemitTo VRT ON VRT.VendorId = V.Id
	WHERE V.IsMigrated = 0 AND VRT.Id Is NOT NULL AND  VRT.ContactUniqueIdentifier IS NOT NULL AND VRT.R_ContactUniqueIdentifier IS NULL
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Invalid Remit To Logo Name {'+ISNULL(VRT.LogoName,'NULL')+'} for VendorRemitTo Id {'+CONVERT(NVARCHAR(MAX),VRT.Id)+'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	INNER JOIN stgVendorRemitTo VRT ON VRT.VendorId = V.Id
	WHERE V.IsMigrated = 0 AND VRT.Id Is NOT NULL AND  VRT.LogoName IS NOT NULL AND VRT.R_LogoId IS NULL
	UPDATE stgVendorRemitToWireDetail Set R_BankAccountId= VBA.Id 
	FROM stgVendorRemitToWireDetail VRTW
	INNER JOIN stgVendorRemitTo VRT ON VRTW.VendorRemitToId = VRT.Id
	INNER JOIN stgVendorBankAccount VBA ON VBA.VendorId = VRT.VendorId
	INNER JOIN stgVendor V ON VRT.VendorId = V.Id
	WHERE VRT.Id IS NOT NULL AND VRTW.R_BankAccountId Is NULL AND V.IsMigrated=0
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Invalid Wire Remit To BankAccountNumber {'+ISNULL(VRTW.BankAccountNumber,'NULL')+'} for VendorRemitTo Id {'+CONVERT(NVARCHAR(MAX),VRT.Id)+'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	INNER JOIN stgVendorRemitTo VRT ON VRT.VendorId = V.Id
	INNER JOIN stgVendorRemitToWireDetail VRTW ON VRTW.VendorRemitToId=VRT.Id
	WHERE V.IsMigrated = 0 AND VRT.Id Is NOT NULL AND  VRTW.R_BankAccountId IS NULL AND VRT.ReceiptType!='Check'
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Both Beneficiary and Correspondent cannot be true for VendorRemitToWireDetail Id {'+CONVERT(NVARCHAR(MAX),VRTW.Id)+'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	INNER JOIN stgVendorRemitTo VRT ON VRT.VendorId = V.Id
	INNER JOIN stgVendorRemitToWireDetail VRTW ON VRTW.VendorRemitToId=VRT.Id
	WHERE V.IsMigrated = 0 AND VRTW.IsCorrespondent = 1 AND VRTW.IsBeneficiary = 1
	--Vendor LegalEntity 
	UPDATE stgVendorLegalEntity  SET R_LegalEntityId=LE.Id
	FROM stgVendorLegalEntity VLE
	INNER JOIN stgVendor V on VLE.VendorId = V.Id
	INNER JOIN LegalEntities LE ON LE.LegalEntityNumber = VLE.LegalEntityNumber
	WHERE V.IsMigrated=0 AND VLE.R_LegalEntityId IS NULL 
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Invalid Legal Entity Number {'+ISNULL(VLE.LegalEntityNumber,'NULL')+'} for VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	INNER JOIN stgVendorLegalEntity VLE ON VLE.VendorId = V.Id
	WHERE V.IsMigrated = 0 AND VLE.Id Is NOT NULL AND  VLE.R_LegalEntityId IS NULL
		INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Cumulative Funding Limit should be greater than or equal to zero for the following Vendor Legal Entities {'+ISNULL(VLE.LegalEntityNumber,'NULL')+'} for VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	INNER JOIN stgVendorLegalEntity VLE ON VLE.VendorId = V.Id
	WHERE V.IsMigrated = 0 AND VLE.Id Is NOT NULL AND VLE.CumulativeFundingLimit_Amount<0
	-- Program Vendor ProgramVendorsAssignedToDealer Dealer/Distributor
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('VendorProgramType Is Mandatory for ProgramVendor {'+CONVERT(nvarchar(MAX),V.Id) +'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
		WHERE  V.IsMigrated=0 AND V.IsVendorProgram=1 AND V.VendorProgramType IS NULL
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Default Line of Business Name is mandatory for ProgramVendorsAssignedToDealer {'+CONVERT(nvarchar(MAX),PV.Id) +'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	INNER JOIN stgProgramVendorsAssignedToDealer PV ON PV.VendorId = V.Id
	WHERE V.IsMigrated = 0 AND PV.Id Is NOT NULL AND PV.LineofBusinessName IS NULL AND PV.ProgramVendorNumber IS NOT NULL AND V.VendorProgramType='DealerOrDistributor'
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Program is mandatory for ProgramVendorsAssignedToDealer {'+CONVERT(nvarchar(MAX),PV.Id) +'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	INNER JOIN stgProgramVendorsAssignedToDealer PV ON PV.VendorId = V.Id
	WHERE V.IsMigrated = 0 AND PV.Id Is NOT NULL AND PV.Program IS NULL AND V.VendorProgramType='DealerOrDistributor'
	UPDATE stgProgramVendorsAssignedToDealer Set R_LineofBusinessId= business.Id
	FROM stgProgramVendorsAssignedToDealer PV
	INNER JOIN stgVendor V ON V.Id = PV.VendorId
	INNER JOIN LineofBusinesses business on business.Name = PV.LineofBusinessName
	WHERE PV.Id IS NOT NULL AND PV.R_LineofBusinessId IS NULL AND V.IsMigrated=0 AND V.IsVendorProgram=1 AND V.VendorProgramType='DealerOrDistributor'
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Invalid Line of Business Name for ProgramVendorsAssignedToDealer {'+CONVERT(nvarchar(MAX),PV.Id) +'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	INNER JOIN stgProgramVendorsAssignedToDealer PV ON PV.VendorId = V.Id
	WHERE V.IsMigrated = 0 AND PV.Id Is NOT NULL AND PV.R_LineofBusinessId IS NULL AND PV.LineofBusinessName IS NOT NULL AND V.VendorProgramType='DealerOrDistributor'
	UPDATE stgProgramVendorsAssignedToDealer  Set R_ProgramId= programs.Id
	FROM stgProgramVendorsAssignedToDealer PV
	INNER JOIN stgVendor V ON V.Id = PV.VendorId
	INNER JOIN Programs programs on programs.Name = PV.Program 
	WHERE PV.Id IS NOT NULL AND PV.R_ProgramId IS NULL AND PV.Program IS NOT NULL AND V.IsMigrated=0 AND V.IsVendorProgram=1 AND V.VendorProgramType='DealerOrDistributor'
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Invalid Program Name for ProgramVendorsAssignedToDealer {'+CONVERT(nvarchar(MAX),PV.Id) +'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	INNER JOIN stgProgramVendorsAssignedToDealer PV ON PV.VendorId = V.Id
	WHERE PV.Id IS NOT NULL AND PV.R_ProgramId IS NULL AND PV.Program is not null AND V.IsMigrated=0 AND V.IsVendorProgram=1 AND V.VendorProgramType='DealerOrDistributor'
	UPDATE stgProgramVendorsAssignedToDealer Set R_ProgramVendorId= party.Id
	FROM stgProgramVendorsAssignedToDealer PV
	INNER JOIN stgVendor V ON V.Id = PV.VendorId
	INNER JOIN Parties party on party.PartyNumber= PV.ProgramVendorNumber
	WHERE PV.Id IS NOT NULL AND PV.R_ProgramVendorId IS NULL AND V.IsMigrated=0 AND V.IsVendorProgram=1 AND V.VendorProgramType='DealerOrDistributor'
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Invalid Program Vendor Number for ProgramVendorsAssignedToDealer {'+CONVERT(nvarchar(MAX),PV.Id) +'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	INNER JOIN stgProgramVendorsAssignedToDealer PV ON PV.VendorId = V.Id
	WHERE V.IsMigrated = 0 AND PV.Id Is NOT NULL AND PV.R_ProgramVendorId IS NULL AND PV.ProgramVendorNumber IS NOT NULL AND V.VendorProgramType='DealerOrDistributor'
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('The Program Vendor selected should have one Primary Sales Rep assigned for ProgramVendor {'+CONVERT(nvarchar(MAX),PV.ProgramVendorNumber) +'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	INNER JOIN stgProgramVendorsAssignedToDealer PV ON PV.VendorId = V.Id
	INNER JOIN Parties P ON PV.R_ProgramVendorId = P.Id
	LEFT JOIN EmployeesAssignedToParties EATP ON EATP.PartyId = P.Id AND EATP.IsPrimary = 1 AND EATP.IsActive = 1
	LEFT JOIN RoleFunctions RF ON EATP.RoleFunctionId = RF.Id
	WHERE PV.ProgramVendorNumber IS NOT NULL AND V.VendorProgramType='DealerOrDistributor' AND ((EATP.Id IS NOT NULL AND RF.SystemDefinedName !='SalesRep') OR EATP.Id IS NULL) 
	-- Vendor Program
	UPDATE stgVendor Set R_ProgramId= programs.Id
	FROM stgVendor V
	INNER JOIN Programs programs on programs.Name = V.Program 
	WHERE  V.R_ProgramId IS NULL AND V.IsMigrated=0 AND V.IsVendorProgram=1 AND V.VendorProgramType='ProgramVendor'
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Invalid Program for ProgramVendor {'+CONVERT(nvarchar(MAX),V.Id) +'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
		WHERE  V.R_ProgramId IS NULL AND V.IsMigrated=0 AND V.IsVendorProgram=1 AND V.VendorProgramType='ProgramVendor'
	-- Vendor Program Promotion
	UPDATE stgVendorProgramPromotion Set R_ProgramPromotionId= programpromotions.Id
	FROM stgVendorProgramPromotion VPP
	INNER JOIN stgVendor V ON V.Id = VPP.VendorId
	INNER JOIN ProgramPromotions programpromotions on programpromotions.PromotionCode = VPP.ProgramPromotionCode AND programpromotions.IsActive = 1
	INNER JOIN Programs P ON P.ProgramDetailId = programpromotions.ProgramDetailId AND V.R_ProgramId = P.Id
	WHERE VPP.Id IS NOT NULL AND VPP.R_ProgramPromotionId IS NULL AND V.RestrictPromotions = 1 AND V.IsMigrated=0 AND V.IsVendorProgram=1 AND V.VendorProgramType='ProgramVendor'
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Invalid Program Promotions for ProgramVendor {'+CONVERT(nvarchar(MAX),V.Program) +'} with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	INNER JOIN stgVendorProgramPromotion VPP ON VPP.VendorId = V.Id
	WHERE VPP.Id IS NOT NULL AND VPP.R_ProgramPromotionId IS NULL AND V.RestrictPromotions = 1 AND V.IsMigrated=0 AND V.IsVendorProgram=1 AND V.VendorProgramType='ProgramVendor'
	-- Vendor Program Promotion
	UPDATE stgVendorProgramPromotion Set R_ProgramPromotionId= programpromotions.Id
	FROM stgVendorProgramPromotion VPP
	INNER JOIN stgVendor V ON V.Id = VPP.VendorId
	INNER JOIN StgProgramVendorsAssignedToDealer PVATD ON  V.Id = PVATD.VendorId
	INNER JOIN ProgramPromotions programpromotions on programpromotions.PromotionCode = VPP.ProgramPromotionCode AND programpromotions.IsActive = 1
	INNER JOIN Programs P ON P.ProgramDetailId = programpromotions.ProgramDetailId AND PVATD.R_ProgramId = P.Id
	WHERE VPP.Id IS NOT NULL AND VPP.R_ProgramPromotionId IS NULL AND V.RestrictPromotions = 1 AND V.IsMigrated=0 AND V.IsVendorProgram=1 AND V.VendorProgramType='DealerOrDistributor'
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Invalid Program Promotion Code {'+CONVERT(nvarchar(MAX),VPP.ProgramPromotionCode) +'} for VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	INNER JOIN stgVendorProgramPromotion VPP ON VPP.VendorId = V.Id
	WHERE VPP.Id IS NOT NULL AND VPP.R_ProgramPromotionId IS NULL AND V.RestrictPromotions = 1 AND V.IsMigrated=0 AND V.IsVendorProgram=1 AND V.VendorProgramType='DealerOrDistributor';
	WITH VendorBankAccountCTE AS
	(
	SELECT *,ROW_NUMBER() OVER(PARTITION BY Vendorid ORDER BY id DESC) RowNumber FROM stgVendorBankAccount WHERE [IsPrimaryACH]=1
	) 
	UPDATE VendorBankAccountCTE SET [IsPrimaryACH]=0 WHERE RowNumber > 1;
	WITH VendorPayoffTemplateAssignmentCTE AS
	(
	SELECT *,ROW_NUMBER() OVER(PARTITION BY Vendorid ORDER BY id DESC) RowNumber FROM stgVendorPayoffTemplateAssignment WHERE [IsDefault]=1
	) 
	UPDATE VendorPayoffTemplateAssignmentCTE SET [IsDefault]=0 WHERE RowNumber > 1;
	WITH ProgramVendorsAssignedToDealerCTE AS
	(
	SELECT *,ROW_NUMBER() OVER(PARTITION BY Vendorid ORDER BY id DESC) RowNumber FROM stgProgramVendorsAssignedToDealer WHERE IsDefault=1
	) 
	UPDATE ProgramVendorsAssignedToDealerCTE SET isDefault=0 WHERE RowNumber > 1;
	--Payoff Template assignments
	UPDATE stgVendorPayoffTemplateAssignment Set R_PayOffTemplateId= templates.Id
	FROM stgVendorPayoffTemplateAssignment Payoff
	INNER JOIN stgVendor V ON V.Id = payoff.VendorId
	INNER JOIN PayOffTemplates templates ON  Payoff.PayOffTemplateName = templates.TemplateName
	WHERE templates.IsActive =1 AND templates.TemplateType = 'Vendor' AND V.IsMigrated = 0 
	AND payoff.Id IS NOT NULL AND Payoff.R_PayOffTemplateId IS NULL
	AND (templates.FRRApplicable = 0 OR (templates.FRRApplicable = 1 AND ( (templates.FRROption = '_' AND V.FirstRightOfRefusal = '_') OR (templates.FRROption != '_' AND V.FirstRightOfRefusal != '_') )))
	AND (templates.RetainedVendorApplicable =0 OR (templates.RetainedVendorApplicable =1 AND (templates.VendorRetained = V.IsRetained)))
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Invalid PayOff Template Name for Vendor with  VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	INNER JOIN stgVendorPayoffTemplateAssignment payoff ON payoff.VendorId = V.Id
	WHERE V.IsMigrated = 0 AND payoff.Id Is NOT NULL AND payoff.R_PayOffTemplateId IS NULL
		-- Vendor Validations
	INSERT INTO #ErrorLogs
	SELECT
		V.Id
		,'Error'
		,('The entered value for the field VendorNumber:' + V.VendorNumber+ ' already exists. Please enter a unique value')
	FROM
	stgVendor V
	INNER JOIN Parties Party
	ON V.IsMigrated=0 AND V.VendorNumber= Party.PartyNumber	
	UPDATE stgVendor Set R_LanguageConfigId = L.Id
	FROM stgVendor V
	INNER JOIN dbo.LanguageConfigs L ON V.Language = L.Name AND L.IsActive=1
	WHERE V.IsMigrated = 0 AND V.Language Is NOT NULL AND V.R_LanguageConfigId Is NULL
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Invalid Language for VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	WHERE V.IsMigrated = 0 AND V.Language Is NOT NULL AND V.R_LanguageConfigId Is NULL
	INSERT INTO #ErrorLogs
	SELECT
	V.Id
	,'Error'
	,('A Vendor {'+V.VendorNumber+'} With ParentVendorNumber {'+V.ParentVendorNumber+'} cannot act as a Parent to itself') AS Message
	FROM 
	stgVendor V
	WHERE V.IsMigrated=0 AND V.ParentVendorNumber IS NOT NULL AND V.VendorNumber = V.ParentVendorNumber
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Please enter Type for Vendor with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}') AS Message
	FROM stgVendor V
	WHERE V.IsMigrated = 0 AND V.Type IS NULL
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('CompanyName is required for the Corporate Vendor with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	WHERE V.IsMigrated = 0 AND ( V.IsCorporate = 1 AND V.IsSoleProprietor = 0) AND V.CompanyName Is NULL
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('FirstName and LastName is mandatory for the Sole Proprietor with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	WHERE 
	  V.IsMigrated = 0 
		AND
	  (V.IsCorporate = 0 OR ( V.IsCorporate = 1 AND V.IsSoleProprietor = 1) ) 
		AND 
	  ( V.FirstName IS NULL OR V.LastName IS NULL)
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Lessor Contact Email is required for Vendor with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	WHERE 
	  V.IsMigrated = 0 AND V.IsVendorProgram=1 AND  V.LessorContactEmail IS NULL
	INSERT INTO #ErrorLogs
	SELECT
	V.Id
	,'Error'
	,('Please set at least one of the address as Main Address for Vendor with VendorId 
	{'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM
	stgVendor V
    WHERE V.IsMigrated = 0 AND V.Id NOT IN
	(
	SELECT VA.VendorId FROM stgVendorAddress VA
	WHERE IsMain = 1
	GROUP BY VA.VendorId
	HAVING COUNT (*) >0 
	)
    INSERT INTO #ErrorLogs
	SELECT 
		VA.VendorId
		,'Error'
		,('Please enter Valid Office Address for the Address indicated as Main Address with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+' and UniqueIdentifier '+ ISNULL(VA.UniqueIdentifier,'NULL') +'}')
	FROM stgVendor V
	INNER JOIN stgVendorAddress VA ON VA.VendorId = V.Id
	WHERE 
	    V.IsMigrated = 0 AND VA.Id IS NOT NULL AND VA.IsMain=1
		and 
		(
		VA.AddressLine1 IS NULL AND VA.City IS NULL AND VA.State IS NULL AND VA.Country IS NULL AND VA.PostalCode IS NULL
		)
    INSERT INTO #ErrorLogs
	SELECT 
		 V.Id
		,'Error'
		,('Provide Home Address for the Address indicated as Main Address for Non Commercial Party with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+' and UniqueIdentifier '+ ISNULL(VA.UniqueIdentifier,'NULL') +'}')
	FROM stgVendor V
	INNER JOIN stgVendorAddress VA ON VA.VendorId = V.Id
	WHERE 
	  V.IsMigrated = 0 AND VA.Id IS NOT NULL AND V.IsCorporate = 0 AND IsMain = 1
	  AND 
	  (
	  VA.HomeAddressLine1 IS NULL AND VA.HomeState IS NULL AND VA.HomeCity IS NULL AND VA.HomePostalCode IS NULL AND VA.HomeCountry IS NULL
	  )
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Provided Home Address is not valid for VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+' and UniqueIdentifier '+ ISNULL(VA.UniqueIdentifier,'NULL') +'}')
	FROM stgVendor V
	INNER JOIN stgVendorAddress VA ON VA.VendorId = V.Id
	WHERE 
	  V.IsMigrated = 0 AND VA.Id IS NOT NULL
	  AND 
	  (
	  VA.HomeAddressLine1 IS NOT NULL AND ( VA.HomeState IS NULL OR VA.HomeCity IS NULL OR VA.HomePostalCode IS NULL OR VA.HomeCountry IS NULL)
	  OR
	  VA.HomeState IS NOT NULL AND ( VA.HomeAddressLine1 IS NULL OR VA.HomeCity IS NULL OR VA.HomePostalCode IS NULL OR VA.HomeCountry IS NULL)
	  OR
	  VA.HomeCity IS NOT NULL AND ( VA.HomeState IS NULL OR VA.HomeAddressLine1 IS NULL OR VA.HomePostalCode IS NULL OR VA.HomeCountry IS NULL)
	  OR
	  VA.HomePostalCode IS NOT NULL AND (VA.HomeState IS NULL OR VA.HomeAddressLine1 IS NULL OR VA.HomeCity IS NULL OR VA.HomeCountry IS NULL)
	  OR 
	  VA.HomeCountry IS NOT NULL AND (VA.HomeState IS NULL OR VA.HomeAddressLine1 IS NULL OR VA.HomeCity IS NULL OR VA.HomePostalCode IS NULL)
	  )
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Provided Office Address is not valid for VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+' and UniqueIdentifier '+ ISNULL(VA.UniqueIdentifier,'NULL') +'}')
	FROM stgVendor V
	INNER JOIN stgVendorAddress VA ON VA.VendorId = V.Id 
	WHERE 
	  V.IsMigrated = 0 AND VA.Id IS NOT NULL 
	 AND 
	 (
	  VA.AddressLine1 IS NOT NULL AND ( VA.State IS NULL OR VA.City IS NULL OR VA.PostalCode IS NULL OR VA.Country IS NULL)
	  OR
	  VA.State IS NOT NULL AND ( VA.AddressLine1 IS NULL OR VA.City IS NULL OR VA.PostalCode IS NULL OR VA.Country IS NULL)
	  OR
	  VA.City IS NOT NULL AND ( VA.State IS NULL OR VA.AddressLine1 IS NULL OR VA.PostalCode IS NULL OR VA.Country IS NULL)
	  OR
	  VA.PostalCode IS NOT NULL AND (VA.State IS NULL OR VA.AddressLine1 IS NULL OR VA.City IS NULL OR VA.Country IS NULL)
	  OR 
	  VA.Country IS NOT NULL AND (VA.State IS NULL OR VA.AddressLine1 IS NULL OR VA.City IS NULL OR VA.PostalCode IS NULL)
	 )
    INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('PostalCode Is Mandatory for VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+' and UniqueIdentifier '+ ISNULL(VA.UniqueIdentifier,'NULL') +'}')
	FROM stgVendor V
	INNER JOIN stgVendorAddress VA ON VA.VendorId = V.Id
	INNER JOIN Countries C on VA.R_CountryId = C.Id
	WHERE 
	  V.IsMigrated = 0 AND VA.R_CountryId IS NOT NULL AND ( VA.PostalCode IS NULL AND C.IsPostalCodeMandatory = 1 )
    INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('HomePostalCode Is Mandatory for VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+' and UniqueIdentifier '+ ISNULL(VA.UniqueIdentifier,'NULL') +'}')
	FROM stgVendor V
	INNER JOIN stgVendorAddress VA ON VA.VendorId = V.Id
	INNER JOIN Countries C on VA.R_HomeCountryId = C.Id
	WHERE 
	  V.IsMigrated = 0 AND VA.R_HomeCountryId IS NOT NULL AND (VA.HomePostalCode IS NULL AND C.IsPostalCodeMandatory = 1 ) 
	INSERT INTO #ErrorLogs
	SELECT DISTINCT
		V.Id
		,'Error'
		,('At least one Active Vendor Legal Entity Association for Vendor with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	LEFT JOIN 
	(SELECT DISTINCT VLE.VendorId AS Id
	FROM stgVendorLegalEntity VLE
	GROUP BY VLE.VendorId) AS T ON V.Id = T.Id
	WHERE 
	  V.IsMigrated = 0 AND T.Id IS NULL
	   INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Contingency percentage is mandatory for Vendor with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	WHERE 
	  V.IsMigrated = 0 AND V.IsContingencyPercentage=1 AND V.ContingencyPercentage IS NULL
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Flat Fee Amount is mandatory for Vendor with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	WHERE 
	  V.IsMigrated = 0 AND V.IsFlatFee = 1 AND V.FlatFeeAmount_Amount IS NULL
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Hourly Amount is mandatory for Vendor with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	WHERE 
	  V.IsMigrated = 0 AND V.IsHourly =1 AND V.HourlyAmount_Amount IS NULL
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('RVI Factor should be between 0 and 1 for Vendor with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	WHERE 
	  V.IsMigrated = 0 AND V.Type='Insurance' AND V.RVIFactor NOT BETWEEN 0 AND 1
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Doc Fee Amount / Doc Fee % must not be negative for Vendor with VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	WHERE 
	  V.IsMigrated = 0 AND ((V.IsPercentageBasedDocFee=0 AND V.DocFeeAmount_Amount< 0) OR (V.IsPercentageBasedDocFee=1 AND V.DocFeePercentage<0))
	--INSERT INTO #ErrorLogs
	--SELECT
	--	V.Id as [VendorId]
	--	,'Error'
	--	,('TaxId : {'+V.TaxId+'} is not in correct format, please enter TaxId with the regex format : {'+ dbo.Countries.CorporateTaxIDMask +'} with Vendor Id {'+CONVERT(NVARCHAR(MAX),VA.VendorId)+'}') AS Message
	--FROM
	--stgVendor V
	--INNER JOIN stgVendorAddress VA on V.id = VA.VendorId 
	--INNER JOIN dbo.Countries on R_CountryId = dbo.Countries.Id
	--WHERE V.IsMigrated = 0
	--AND V.[IsCorporate] = 1 
	--AND dbo.Countries.CorporateTaxIDMask IS NOT NULL
	--AND V.TaxId IS NOT NULL
	--AND VA.IsMain = 1 
	--AND VA.R_CountryId IS NOT NULL
	--AND dbo.RegexStringMatch(V.TaxId,dbo.Countries.CorporateTaxIDMask) = 0
	--INSERT INTO #ErrorLogs
	--SELECT
	--	V.Id as [VendorId]
	--	,'Error'
	--	,('SocialSecurityNumber : {'+V.SocialSecurityNumber+'} is not in correct format, please enter SocialSecurityNumber with the regex format : {'+dbo.Countries.IndividualTaxIDMask +'} with Vendor Id {'+CONVERT(NVARCHAR(MAX),VA.VendorId)+'}') AS Message
	--FROM
	--stgVendor V
	--INNER JOIN stgVendorAddress VA on V.id = VA.VendorId 
	--INNER JOIN dbo.Countries on ISNULL(VA.R_CountryId,VA.R_HomeCountryId) = dbo.Countries.Id
	--WHERE V.IsMigrated = 0
	--AND V.[IsCorporate] = 0 
	--AND dbo.Countries.IndividualTaxIDMask IS NOT NULL
	--AND V.SocialSecurityNumber IS NOT NULL
	--AND VA.IsMain=1 
	--and (VA.R_HomeCountryId IS NOT NULL OR VA.R_CountryId IS NOT NULL)
	--AND dbo.RegexStringMatch(V.SocialSecurityNumber,dbo.Countries.IndividualTaxIDMask ) = 0
	
	UPDATE C set R_ConsentConfigId = CC.Id
    FROM stgVendorConsent C
    JOIN stgVendor C1 on C.VendorId = C1.Id
    JOIN Countries C2 on C.Country = C2.ShortName
    JOIN Consents C3 on C.Title = C3.Title
    JOIN ConsentConfigs CC on C3.Id = CC.ConsentId AND C2.ID = CC.CountryId
    WHERE C1.IsMigrated =0 and CC.IsActive = 1 AND CC.EntityType ='Vendor'

	UPDATE C set R_ConsentConfigId = CC.Id
    FROM stgVendor V
	JOIN stgVendorContact VC on V.Id = VC.VendorId
	JOIN stgVendorContactConsent C on VC.Id = C.VendorContactId
    JOIN Countries C2 on C.Country = C2.ShortName
    JOIN Consents C3 on C.Title = C3.Title
    JOIN ConsentConfigs CC on C3.Id = CC.ConsentId AND C2.ID = CC.CountryId
    WHERE V.IsMigrated =0 and CC.IsActive = 1 AND CC.EntityType ='VendorContact'

    INSERT INTO #ErrorLogs
    SELECT 
        V.Id
        ,'Error'
        ,('Invalid Consent Combination (Title,Country,EntityType) for VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	JOIN  stgVendorConsent VC on V.Id = VC.VendorId
	WHERE V.IsMigrated = 0 AND VC.R_ConsentConfigId Is NULL
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Invalid Consent Combination (Title,Country,EntityType) for VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'} and VendorContactId {'+CONVERT(NVARCHAR(MAX),VC.Id)+'}')
	FROM stgVendor V
	JOIN  stgVendorContact VC on V.Id = VC.VendorId
	JOIN  stgVendorContactConsent VCC on VC.Id = VCC.VendorContactId
	WHERE V.IsMigrated = 0 AND VCC.R_ConsentConfigId Is NULL
	INSERT INTO #ErrorLogs
    SELECT 
        V.Id
        ,'Error'
        ,('Expiry date must be after Effective Date for VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	FROM stgVendor V
	JOIN  stgVendorConsent VC on V.Id = VC.VendorId
	WHERE V.IsMigrated = 0 AND VC.R_ConsentConfigId Is NOT NULL AND VC.ExpiryDate Is NOT NULL and VC.ExpiryDate < VC.EffectiveDate
	INSERT INTO #ErrorLogs
	SELECT 
		V.Id
		,'Error'
		,('Expiry date must be after Effective Date for VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'} and VendorContactId {'+CONVERT(NVARCHAR(MAX),VC.Id)+'}')
	FROM stgVendor V
	JOIN  stgVendorContact VC on V.Id = VC.VendorId
	JOIN  stgVendorContactConsent VCC on VC.Id = VCC.VendorContactId
	WHERE V.IsMigrated = 0 AND VCC.R_ConsentConfigId Is NOT NULL AND VCC.ExpiryDate Is NOT NULL and VCC.ExpiryDate < VCC.EffectiveDate
    
	INSERT INTO #ErrorLogs
	SELECT
		V.Id as [VendorId]
		,'Error'
		,('PostalCode : {'+ISNULL(VA.PostalCode, 'NULL')+'} is not in correct format, please enter PostalCode with the regex format : {'+dbo.Countries.PostalCodeMask +'} with Vendor Id {'+CONVERT(NVARCHAR(MAX),VA.VendorId)+'}') AS Message
	FROM
	stgVendor V
	INNER JOIN stgVendorAddress VA on V.id = VA.VendorId 
	INNER JOIN dbo.Countries on VA.R_CountryId = dbo.Countries.Id
	WHERE V.IsMigrated = 0
	AND dbo.Countries.PostalCodeMask IS NOT NULL
	AND VA.R_CountryId IS NOT NULL 
	AND VA.PostalCode IS NOT NULL
	AND dbo.RegexStringMatch(VA.PostalCode,dbo.Countries.PostalCodeMask ) = 0
	INSERT INTO #ErrorLogs
	SELECT
		V.Id as [VendorId]
		,'Error'
		,('HomePostalCode : {'+ISNULL(VA.HomePostalCode, 'NULL')+'} is not in correct format, please enter HomePostalCode with the regex format : {'+dbo.Countries.PostalCodeMask +'} with Vendor Id  {'+CONVERT(NVARCHAR(MAX),VA.VendorId)+'}') AS Message
	FROM
	stgVendor V
	INNER JOIN stgVendorAddress VA on V.id = VA.VendorId 
	INNER JOIN dbo.Countries on VA.R_HomeCountryId = dbo.Countries.Id
	WHERE V.IsMigrated = 0
	AND dbo.Countries.PostalCodeMask IS NOT NULL
	AND VA.R_HomeCountryId IS NOT NULL 
	AND VA.HomePostalCode IS NOT NULL
	AND dbo.RegexStringMatch(VA.HomePostalCode,dbo.Countries.PostalCodeMask ) = 0
	SELECT *
	INTO #ErrorLogDetails
	FROM #ErrorLogs ORDER BY StagingRootEntityId ;
  CREATE TABLE #ProcessedVendor  
  (  
         VendorID BIGINT  
  );  
WHILE @SkipCount < @TotalRecordsCount
BEGIN
IF OBJECT_ID('tempdb..#Vendors', 'U') IS NOT NULL
Begin
DROP TABLE #Vendors
END
        SELECT
			TOP(@TakeCount) 
			V.*
		INTO #Vendors
		FROM
		stgVendor V
		WHERE 
		IsMigrated = 0 
		AND
		V.Id NOT IN (SELECT VendorID FROM #ProcessedVendor)
		AND
		V.Id NOT IN (SELECT StagingRootEntityId FROM #ErrorLogDetails) ORDER BY V.ParentVendorNumber;
		SELECT @BatchCount =ISNULL(COUNT(Id),0) from #Vendors
        DECLARE @ParentCount BIGINT  
		DECLARE @ChildCount  BIGINT  
		Select @ChildCount=Count(*) FROM #Vendors WHERE ParentVendorNumber IS NOT NULL
		Select @ParentCount=Count(*) FROM #Vendors WHERE ParentVendorNumber IS NULL  
		IF(@ParentCount>0 and @ChildCount>0)  
		BEGIN  
		DELETE FROM #Vendors WHERE ParentVendorNumber is not NULL  
		SET @ChildCount=0  
		END  
		INSERT INTO #ProcessedVendor(VendorID) SELECT Id FROM #Vendors; 
		If(@ChildCount>0)  
        BEGIN  
             	UPDATE stgVendor SET R_ParentVendorId = Parties.Id
	            FROM stgVendor vendor
	            INNER JOIN Parties ON Parties.PartyNumber = vendor.ParentVendorNumber
	            WHERE vendor.IsMigrated = 0 AND vendor.ParentVendorNumber IS NOT NULL AND vendor.R_ParentVendorId IS NULL;  
	            INSERT INTO #ErrorLogDetails
	            SELECT 
	            	V.Id
	            	,'Error'
	            	,('Invalid Parent Vendor for VendorId {'+CONVERT(NVARCHAR(MAX),V.Id)+'}')
	            FROM stgVendor V
	            WHERE IsMigrated = 0 AND V.ParentVendorNumber IS NOT NULL AND V.R_ParentVendorId IS NULL
                DELETE V  
                FROM #Vendors V inner join   
                #ErrorLogDetails E on V.Id=E.StagingRootEntityId  
        END  
BEGIN TRY  
BEGIN TRANSACTION
		CREATE TABLE #CreatedVendors
		(
			[Action] NVARCHAR(10) NOT NULL
			,[Id] BIGINT NOT NULL
			,[VendorId] BIGINT NOT NULL
		);
		CREATE TABLE #CreatedPartyContactIds 
		(
			[Action] NVARCHAR(10) NOT NULL,
			[Id] bigint NOT NULL,
			[VendorContactId] bigint NOT NULL
		);
		CREATE TABLE #CreatedPartyAddressIds 
		(
			[Action] NVARCHAR(10) NOT NULL,
			[Id] bigint NOT NULL,
			[VendorAddressId] bigint NOT NULL
		);
		CREATE TABLE #CreatedBankAccountIds 
		(
			[Action] NVARCHAR(10) NOT NULL,
			[Id] bigint NOT NULL,
			[VendorBankAccountId] bigint NOT NULL,
			[AccountNumber] NVARCHAR(50)
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
		CREATE TABLE #CreatedConsentDetails
		(  
			Id BIGINT,
			VendorId BIGINT
		);
		CREATE TABLE #CreatedContactConsentDetails
		(  
			Id BIGINT,
			VendorContactId BIGINT
		);
		MERGE Parties 
		USING(Select * FROM #Vendors) AS VendorsToMigrate
		ON 1=0
		WHEN NOT MATCHED
		THEN
		INSERT
		(
		[PartyNumber]
		,[IsCorporate]
		,[FirstName]
		,[MiddleName]
		,[LastName]
		,[CompanyName]
		,[PartyName]
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
		,[LanguageId]
		,[UniqueIdentificationNumber_CT]
		,[ExternalPartyNumber]
		,[LastFourDigitUniqueIdentificationNumber]
		,[PortfolioId]
		,[Suffix]
		,IsVATRegistration
		,IsSpecialClient
		,EIKNumber_CT
		)
		VALUES
		(
		     VendorsToMigrate.VendorNumber
			,VendorsToMigrate.IsCorporate
			,CASE WHEN (VendorsToMigrate.[IsCorporate] = 0 OR (VendorsToMigrate.[IsCorporate] = 1 AND VendorsToMigrate.[IsSoleProprietor]=1)) THEN VendorsToMigrate.[FirstName] ELSE NULL END
			,CASE WHEN (VendorsToMigrate.[IsCorporate] = 0 OR (VendorsToMigrate.[IsCorporate] = 1 AND VendorsToMigrate.[IsSoleProprietor]=1)) THEN VendorsToMigrate.[MiddleName] ELSE NULL END
			,CASE WHEN (VendorsToMigrate.[IsCorporate] = 0 OR (VendorsToMigrate.[IsCorporate] = 1 AND VendorsToMigrate.[IsSoleProprietor]=1)) THEN VendorsToMigrate.[LastName] ELSE NULL END
			,CASE WHEN (VendorsToMigrate.[IsCorporate] = 1 AND VendorsToMigrate.IsSoleProprietor=0) THEN VendorsToMigrate.[CompanyName] ELSE NULL END
			,CASE WHEN (VendorsToMigrate.[IsCorporate] = 1 AND VendorsToMigrate.IsSoleProprietor=0) THEN VendorsToMigrate.[CompanyName] ELSE VendorsToMigrate.[FirstName] + (IIF((ISNULL(VendorsToMigrate.[MiddleName], '') = ''), '', (' ' + VendorsToMigrate.[MiddleName]))) + (' ' + VendorsToMigrate.[LastName]) + (IIF((ISNULL(VendorsToMigrate.[Suffix], '') = ''), '', (' ' + VendorsToMigrate.[Suffix]))) END 
			,CASE WHEN (VendorsToMigrate.[IsCorporate] = 1 AND VendorsToMigrate.[IsSoleProprietor]=1) THEN VendorsToMigrate.[DateOfBirth] ELSE NULL END
			,CASE WHEN (VendorsToMigrate.[IsCorporate] = 1 AND VendorsToMigrate.IsSoleProprietor=0) THEN VendorsToMigrate.[DoingBusinessAs] ELSE NULL END
			,VendorsToMigrate.[CreationDate]
			,CASE WHEN VendorsToMigrate.[IsCorporate] = 1 THEN VendorsToMigrate.[IncorporationDate] ELSE NULL END
			,'Vendor'
			,@UserId
			,@CreatedTime
			,VendorsToMigrate.[R_ParentVendorId]
			,VendorsToMigrate.[IsSoleProprietor]
			,VendorsToMigrate.[R_StateOfIncorporationId]
			,VendorsToMigrate.IsIntercompany
			,R_LanguageConfigId
			,NULL --CASE WHEN VendorsToMigrate.[IsCorporate] = 1 THEN [dbo].[Encrypt]('nvarchar',VendorsToMigrate.TaxId, 'M4WHMOVTTT74UP6EL71GWMU4NTXQLLN5') ELSE [dbo].[Encrypt]('nvarchar',VendorsToMigrate.SocialSecurityNumber, 'M4WHMOVTTT74UP6EL71GWMU4NTXQLLN5') END
			,VendorsToMigrate.ExternalPartyNumber
			,NULL --CASE WHEN IsCorporate = 1 AND LEN(TaxId) > 4 THEN SUBSTRING(TaxId,LEN(TaxId) - 3,4)
			 --WHEN IsCorporate = 0  AND LEN(SocialSecurityNumber) > 4 THEN SUBSTRING(SocialSecurityNumber,LEN(SocialSecurityNumber) - 3,4)
			 --ELSE NULL END
			,R_PortfolioId
			,VendorsToMigrate.[Suffix]
			,1
			,0
			,CASE WHEN VendorsToMigrate.EIKNumber IS NOT NULL THEN [dbo].[Encrypt]('nvarchar',VendorsToMigrate.EIKNumber, 'M4WHMOVTTT74UP6EL71GWMU4NTXQLLN5') ELSE NULL END
		)
	  OUTPUT $action, Inserted.Id, VendorsToMigrate.Id INTO #CreatedVendors;
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
	MERGE  [dbo].[PartyAddresses]
	USING(SELECT VendorAddress.* ,#CreatedVendors.Id AS PartyVendorId FROM stgVendorAddress VendorAddress
			INNER JOIN #CreatedVendors ON #CreatedVendors.VendorId = VendorAddress.VendorId) as VendorAddress
	ON 1=0
	WHEN NOT MATCHED
	THEN		
	INSERT 
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
				,IsCompanyHeadquartersPermanentAddress
				)
			VALUES(
				VendorAddress.[UniqueIdentifier]
				,VendorAddress.[AddressLine1]
				,VendorAddress.[AddressLine2]
				,VendorAddress.[City]
				,VendorAddress.[PostalCode]
				,VendorAddress.[Description]
				,1
				,VendorAddress.[IsMain]
				,@UserId
				,@CreatedTime
				,VendorAddress.[R_StateId]
				,VendorAddress.PartyVendorId
				,VendorAddress.Division
				,VendorAddress.HomeAddressLine1
				,VendorAddress.HomeAddressLine2
				,VendorAddress.HomeCity
				,VendorAddress.HomeDivision
				,VendorAddress.HomePostalCode
				,VendorAddress.R_HomeStateId
				,VendorAddress.IsHeadquarter
				,VendorAddress.AddressLine3
				,VendorAddress.Neighborhood
				,VendorAddress.SubdivisionOrMunicipality
				,VendorAddress.HomeAddressLine3
				,VendorAddress.HomeNeighborhood
				,VendorAddress.HomeSubdivisionOrMunicipality
				,VendorAddress.AttentionTo
				,VendorAddress.IsForDocumentation
				,VendorAddress.SFDCAddressId
				,0
				,VendorAddress.IsCompanyHeadquartersPermanentAddress
				)
			 OUTPUT $action, Inserted.Id, VendorAddress.Id INTO #CreatedPartyAddressIds;
			MERGE PartyContacts AS PartyContact
			USING (SELECT VC.*,#CreatedVendors.Id As PartyId FROM stgVendorContact VC
					INNER JOIN #CreatedVendors ON #CreatedVendors.VendorId = VC.VendorId
					INNER JOIN stgVendor V ON V.Id = VC.VendorId) AS VendorContactToMigrate
			ON (PartyContact.[UniqueIdentifier] = VendorContactToMigrate.[UniqueIdentifier])
			WHEN MATCHED THEN
				UPDATE SET [UniqueIdentifier]  = VendorContactToMigrate.[UniqueIdentifier]
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
			   ,[BenefitsAndProtection]
			   ,[SFDCContactId]
			   ,IsCreditNotificationAllowed
			   ,IsBookingNotificationAllowed
			   ,OwnershipPercentage
			   ,LastName2
			   ,ParalegalName
			   ,SecretaryName
			   ,Webpage
			   ,SocialSecurityNumber_CT
			   ,LastFourDigitSocialSecurityNumber
			   ,VendorId
			   ,[BusinessStartTimeInHours]
			   ,[BusinessEndTimeInHours]
			   ,[BusinessStartTimeInMinutes]
			   ,[BusinessEndTimeInMinutes]
			   ,Foreigner
               )
			VALUES
			   (
				   VendorContactToMigrate.[UniqueIdentifier]
				  ,VendorContactToMigrate.[Prefix]
				  ,VendorContactToMigrate.[FirstName]
				  ,VendorContactToMigrate.[MiddleName]
				  ,VendorContactToMigrate.[LastName]
				  ,VendorContactToMigrate.[FirstName] + ' ' + ISNULL(VendorContactToMigrate.[MiddleName],'') + VendorContactToMigrate.[LastName]
				  ,VendorContactToMigrate.[DateOfBirth]
				  ,VendorContactToMigrate.[EmailId]
				  ,VendorContactToMigrate.[PhoneNumber1]
				  ,VendorContactToMigrate.[ExtensionNumber1]
				  ,VendorContactToMigrate.[PhoneNumber2]
				  ,VendorContactToMigrate.[ExtensionNumber2]
				  ,VendorContactToMigrate.[MobilePhoneNumber]
				  ,VendorContactToMigrate.[FaxNumber]
				  ,VendorContactToMigrate.[Description]
				  ,(SELECT Id FROM PartyAddresses WHERE [UniqueIdentifier] = VendorContactToMigrate.[AddressUniqueIdentifier])
				  ,1
				  ,@UserId
				  ,@CreatedTime
				  ,VendorContactToMigrate.PartyId
				  ,0.0
				  ,'USD'
				  ,VendorContactToMigrate.IsSCRA
				  ,VendorContactToMigrate.[SCRAStartDate]
				  ,VendorContactToMigrate.[SCRAEndDate]
				  ,0
				  ,0
				  ,VendorContactToMigrate.BenefitsAndProtection
				  ,VendorContactToMigrate.SFDCContactId
				  ,VendorContactToMigrate.IsCreditNotificationAllowed
			      ,VendorContactToMigrate.IsBookingNotificationAllowed
				  ,0.00
				  ,VendorContactToMigrate.LastName2
				  ,VendorContactToMigrate.ParalegalName
				  ,VendorContactToMigrate.SecretaryName
				  ,VendorContactToMigrate.Webpage
				  ,CASE WHEN VendorContactToMigrate.SocialSecurityNumber IS NOT NULL THEN [dbo].[Encrypt]('nvarchar',VendorContactToMigrate.SocialSecurityNumber, 'M4WHMOVTTT74UP6EL71GWMU4NTXQLLN5') ELSE NULL  END
				  ,CASE WHEN VendorContactToMigrate.SocialSecurityNumber IS NOT NULL AND LEN(SocialSecurityNumber) > 4 THEN SUBSTRING(SocialSecurityNumber,LEN(SocialSecurityNumber) - 3,4)
				   ELSE VendorContactToMigrate.SocialSecurityNumber END
				  ,VendorContactToMigrate.R_VendorId
                  ,0
				  ,0
				  ,0
				  ,0
				  ,0
			  )
			  OUTPUT $action, Inserted.Id, VendorContactToMigrate.Id INTO #CreatedPartyContactIds;
			INSERT INTO [dbo].[PartyContactTypes]
			   ([IsActive]
			   ,[ContactType]
			   ,[CreatedById]
			   ,[CreatedTime]
			   ,[PartyContactId]
			   ,[IsForDocumentation])
			SELECT
			   1
			  ,VCT.[ContactType]
			  ,@UserId
			  ,@CreatedTime
			  ,#CreatedPartyContactIds.Id
			  ,VCT.IsForDocumentation
			FROM stgVendorContactType VCT
			INNER JOIN #CreatedPartyContactIds ON VCT.VendorContactId= #CreatedPartyContactIds.VendorContactId
			MERGE BankAccounts AS BankAccount
			USING (
					SELECT
						VBA.*
				    FROM stgVendorBankAccount VBA
				    INNER JOIN #CreatedVendors ON #CreatedVendors.VendorId = VBA.VendorId
				  ) AS VendorBankAccountToMigrate
			ON (BankAccount.[AccountName] = VendorBankAccountToMigrate.[AccountName]
				AND BankAccount.AccountNumber_CT = VendorBankAccountToMigrate.[AccountNumber]
				AND BankAccount.[BankBranchId] = VendorBankAccountToMigrate.[R_BankBranchId])
			WHEN MATCHED THEN
				UPDATE SET [AccountName] = VendorBankAccountToMigrate.[AccountName]
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
			   ,[DefaultAccountFor]
			   ,[RemittanceType]
			   ,[LastFourDigitAccountNumber]
			   ,[BankAccountCategoryId]
			   ,[ACHFailureCount]
			   ,[OnHold]
			   ,[AccountOnHoldCount]
			   )
			VALUES
			   (VendorBankAccountToMigrate.[AccountName]
			   ,[dbo].[Encrypt]('nvarchar',VendorBankAccountToMigrate.[AccountNumber], 'M4WHMOVTTT74UP6EL71GWMU4NTXQLLN5') 
			   ,VendorBankAccountToMigrate.[AutomatedPaymentMethod]
			   ,0
			   ,0
			   ,0
			   ,VendorBankAccountToMigrate.[R_BankBranchId]
			   ,VendorBankAccountToMigrate.[R_CurrencyId]
			   ,VendorBankAccountToMigrate.[IsPrimaryACH]
			   ,1
			   ,0
			   ,@UserId
			   ,@CreatedTime
			   ,VendorBankAccountToMigrate.IBAN
			   ,'_'
			   ,VendorBankAccountToMigrate.GLSegmentValue
			   ,0	--hardcoded value
			   ,VendorBankAccountToMigrate.UniqueIdentifier
			   ,'Check'
			   ,'Check'
			   ,CASE WHEN LEN(AccountNumber) > 4 THEN SUBSTRING(AccountNumber,LEN(AccountNumber) - 3,4)
			    ELSE AccountNumber END
			   ,R_BankAccountCategoryId
			   ,0
			   ,0
			   ,0
			   )
			   OUTPUT $action, Inserted.Id, VendorBankAccountToMigrate.Id, VendorBankAccountToMigrate.AccountNumber INTO #CreatedBankAccountIds;
			   INSERT INTO PartyBankAccounts
				(
					PartyId
					,BankAccountId
					,CreatedById
					,CreatedTime
				)
				SELECT
					#CreatedVendors.Id
				   ,BankId.Id
				   ,@UserId
				   ,@CreatedTime
				FROM stgVendorBankAccount VendorBankAccount
				INNER JOIN #CreatedVendors
						ON VendorBankAccount.VendorId = #CreatedVendors.VendorId
				INNER JOIN #CreatedBankAccountIds BankId
					ON VendorBankAccount.Id = BankId.VendorBankAccountId
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
		   ,IsMunicipalityRoadTax)
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
           ,0
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
		   ,Vendor.IsWithholdingTaxApplicable
		   ,Vendor.IsRelatedToLessor
		   ,Vendor.R_LegalOrganizationFormId
		   ,Vendor.IsRoadTrafficOffice
		   ,Vendor.IsMunicipalityRoadTax
		   FROM stgVendor Vendor
		   INNER JOIN #CreatedVendors ON #CreatedVendors.VendorId = Vendor.Id
			 INSERT INTO [dbo].EmployeesAssignedToParties
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
			   ,EmployeesAssignedToVendor.[ActivationDate]
			   ,EmployeesAssignedToVendor.[IsPrimary]
			   ,@UserId
			   ,@CreatedTime
			   ,EmployeesAssignedToVendor.[R_RoleFunctionId]
			   ,EmployeesAssignedToVendor.[R_EmployeeId]
			   ,#CreatedVendors.Id
			   ,0
			   ,0
			   ,'Vendor'
			FROM stgEmployeesAssignedToVendor EmployeesAssignedToVendor
			INNER JOIN #CreatedVendors
				ON EmployeesAssignedToVendor.VendorId = #CreatedVendors.VendorId
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
			   1,VendorTaxRegistrationDetail.[EffectiveDate],
			   VendorTaxRegistrationDetail.[R_CountryId],
			   VendorTaxRegistrationDetail.[R_StateId],
			   #CreatedVendors.Id,
			   VendorTaxRegistrationDetail.[TaxRegistrationName],
			   VendorTaxRegistrationDetail.[TaxRegistrationId]
			  From stgVendorTaxRegistrationDetail VendorTaxRegistrationDetail
			  inner join #CreatedVendors on VendorTaxRegistrationDetail.VendorId = #CreatedVendors.VendorId
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
			USING(Select VRT.*,#CreatedVendors.Id AS VendorRemitToId,#CreatedPartyContactIds.Id AS ContactId,#CreatedPartyAddressIds.Id AS AddressId,V.R_PortfolioId FROM stgVendorRemitTo VRT
				  INNER JOIN #CreatedVendors ON #CreatedVendors.VendorId = VRT.VendorId
				  INNER JOIN stgVendor V ON VRT.VendorId = V.Id
				  INNER JOIN #CreatedPartyAddressIds ON #CreatedPartyAddressIds.VendorAddressId=VRT.R_AddressUniqueIdentifier
				  LEFT JOIN #CreatedPartyContactIds ON #CreatedPartyContactIds.VendorContactId = VRT.R_ContactUniqueIdentifier
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
           ,[LogoId]
           ,[DefaultFromEmail]
		   ,[UserGroupId]
		   ,[PortfolioId])
		   VALUES(
            VendorRemitTo.RemitToName
           ,VendorRemitTo.RemitToCode
           ,VendorRemitTo.RemitToUniqueIdentifier
           ,VendorRemitTo.ReceiptType
           ,CASE WHEN VendorRemitTo.ReceiptType ='Check' THEN '_'
				 WHEN VendorRemitTo.ReceiptType = 'ACH' AND VendorRemitTo.WireType IS NULL THEN '_'
				 ELSE ISNULL(VendorRemitTo.WireType,'_')
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
           ,VendorRemitTo.ContactId
           ,VendorRemitTo.AddressId
           ,VendorRemitTo.R_LogoId
           ,[DefaultFromEmail]
		   ,VendorRemitTo.R_UserGroupId
		   ,VendorRemitTo.R_PortfolioId
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
           ,#CreatedRemitToIds.VendorId
		   FROM
		    stgVendorRemitTo VRT 
			INNER JOIN #CreatedRemitToIds ON #CreatedRemitToIds.RemitToId = VRT.Id
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
           ,[UniqueIdentifier])
		   SELECT
            VRTW.IsBeneficiary
           ,VRTW.[IsCorrespondent]
           ,1
           ,NULL
           ,@UserId
           ,@CreatedTime
           ,NULL
           ,NULL
           ,#CreatedBankAccountIds.Id
           ,#CreatedRemitToIds.Id
           ,VRTW.UniqueIdentifier
		   FROM stgVendorRemitToWireDetail  VRTW
		   INNER JOIN stgVendorRemitTo VRT ON VRT.Id = VRTW.VendorRemitToId AND VRTW.R_BankAccountId IS NOT NULL
		   INNER JOIN #CreatedBankAccountIds ON #CreatedBankAccountIds.VendorBankAccountId = VRTW.R_BankAccountId
		   INNER JOIN #CreatedRemitToIds ON #CreatedRemitToIds.RemitToId = VRT.Id AND VRT.ReceiptType!='Check'
		   
			 --Consent Begin
			 MERGE ConsentDetails AS ConsentDetail
			 USING (SELECT CC.EffectiveDate
                ,CC.ExpiryDate
                ,CC.ConsentStatus
                ,CC.ConsentCaptureMode
                ,1 AS IsActive
                ,'Vendor' AS EntityType
                ,CC.R_ConsentConfigId AS ConsentConfigId
                ,#CreatedVendors.Id  AS VendorId
            FROM stgVendorConsent CC
            INNER JOIN #CreatedVendors ON #CreatedVendors.VendorId = CC.VendorId
            INNER JOIN stgVendor C ON C.Id = CC.VendorId
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
			OUTPUT  Inserted.Id, ConsentDetailToMigrate.VendorId INTO #CreatedConsentDetails;
            
			INSERT INTO [dbo].[PartyConsentDetails]
			(
			    ConsentDetailId,
			    PartyId,
			    CreatedById,
			    CreatedTime
			)
			SELECT Id
			    ,VendorId
			    ,@UserId
			    ,@CreatedTime
			FROM #CreatedConsentDetails

	        MERGE ConsentDetails AS ConsentDetail
            USING (SELECT     CC.EffectiveDate
                ,CC.ExpiryDate
                ,CC.ConsentStatus
                ,CC.ConsentCaptureMode
                ,1 AS IsActive
                ,'VendorContact' AS EntityType
                ,CC.R_ConsentConfigId AS ConsentConfigId
                ,#CreatedPartyContactIds.Id  AS VendorContactId
            FROM stgVendorContactConsent CC
            INNER JOIN #CreatedPartyContactIds ON #CreatedPartyContactIds.VendorContactId = CC.VendorContactId
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
			OUTPUT Inserted.Id, ConsentDetailToMigrate.VendorContactId INTO #CreatedContactConsentDetails;
			   
			INSERT INTO [dbo].[PartyContactConsentDetails]
			(
			    ConsentDetailId,
			    PartyContactId,
			    CreatedById,
			    CreatedTime
			)
			SELECT Id
			    ,VendorContactId
			    ,@UserId
			    ,@CreatedTime
			FROM #CreatedContactConsentDetails
			 --Consent End


------ProgramsAssignedToAllVendors
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
		   WHERE PAD.Id IS NOT NULL AND V.IsMigrated=0 AND V.IsVendorProgram=1 AND V.VendorProgramType='DealerOrDistributor'And 
		   PAD.R_ProgramId IS NOT NULL
		   ) AS Source
			ON (1=0)
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
				,V.R_ParentVendorId
				,#CreatedVendors.Id
			FROM stgVendor V
			INNER JOIN #CreatedVendors ON #CreatedVendors.VendorId = V.Id	
			WHERE V.R_ParentVendorId IS NOT NULL
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
		SET @SkipCount = @SkipCount  + @TakeCount; 
		    IF EXISTS(SELECT Id FROM #CreatedBankAccountIds)
			BEGIN
		    SET @Number = (SELECT MAX(CAST(REPLACE(UniqueIdentifier,'-','')AS BIGINT)) FROM BankAccounts)
			SET @SQL = 'ALTER SEQUENCE BankAccount RESTART WITH ' + CONVERT(NVARCHAR(20),@Number+1)
			EXEC sp_executesql @sql
			END
			IF EXISTS(SELECT Id FROM #CreatedVendors)
			BEGIN
			SET @Number = (SELECT MAX(Id) FROM #CreatedVendors)
			SET @SQL = 'ALTER SEQUENCE Party RESTART WITH ' + CONVERT(NVARCHAR(20),@Number+1)
			EXEC sp_executesql @sql	
			END
			IF EXISTS(SELECT Id FROM #CreatedRemitToIds)
			BEGIN
			SET @Number = (SELECT MAX(Id) FROM #CreatedRemitToIds)
			SET @SQL = 'ALTER SEQUENCE RemitToWireDetail RESTART WITH ' + CONVERT(NVARCHAR(20),@Number+1)
			EXEC sp_executesql @sql	
			END
			drop table #CreatedVendors
			drop table #CreatedPartyContactIds
			drop table #CreatedPartyAddressIds
			drop table #CreatedProcessingLogs
			drop table #Vendors
			drop table #CreatedRemitToIds
			drop table #CreatedBankAccountIds
			--drop table #CreatedVendorAssetTypeIds
COMMIT TRANSACTION
END TRY
BEGIN CATCH
	SET @SkipCount = @SkipCount  + @TakeCount;
	DECLARE @ErrorMessage Nvarchar(max);
	DECLARE @ErrorLine Nvarchar(max);
	DECLARE @ErrorSeverity INT;
	DECLARE @ErrorState INT;
	DECLARE @ErrorLogs ErrorMessageList;
	DECLARE @ModuleName Nvarchar(max) = 'MigrateVendors'
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
			#ErrorLogDetails.Message
			,'Error'
			,@UserId
			,@CreatedTime
			,#FailedProcessingLogs.Id
		FROM #ErrorLogDetails
		JOIN #FailedProcessingLogs ON #ErrorLogDetails.StagingRootEntityId = #FailedProcessingLogs.VendorId;	
		SET @FailedRecords = @FailedRecords+(SELECT COUNT(DISTINCT StagingRootEntityId) FROM #ErrorLogDetails)
		SET @ProcessedRecords = @ProcessedRecords + @TotalRecordsCount;		
drop table #ErrorLogs
drop table #ErrorLogDetails
drop table #FailedProcessingLogs
drop table #ProcessedVendor
END
SET NOCOUNT OFF;
SET XACT_ABORT OFF;

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ValidateVendors]
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
(Id       BIGINT NOT NULL,
VendorId BIGINT NOT NULL
);
CREATE TABLE #CreatedProcessingLogs([Id] BIGINT NOT NULL);
SET @ProcessedRecords =
(
SELECT ISNULL(COUNT(Id), 0)
FROM stgVendor
WHERE IsMigrated = 0
);
UPDATE stgVendor
SET
R_StateofIncorporationId = States.Id
FROM stgVendor V
INNER JOIN States ON UPPER(States.ShortName) = UPPER(V.StateOfIncorporation)
WHERE V.IsMigrated = 0
AND V.StateOfIncorporation IS NOT NULL
AND V.R_StateofIncorporationId IS NULL;
INSERT INTO #ErrorLogs
SELECT V.Id
, 'Error'
, ('Invalid State of Incorporation for VendorId {' + CONVERT(NVARCHAR(MAX), V.Id) + '}')
FROM stgVendor V
WHERE V.IsMigrated = 0
AND V.StateOfIncorporation IS NOT NULL
AND V.R_StateofIncorporationId IS NULL;
UPDATE stgVendor
SET
R_LineofBusinessId = LineofBusinesses.Id
FROM stgVendor vendor
INNER JOIN LineofBusinesses ON LineofBusinesses.Name = vendor.LineofBusinessName
WHERE vendor.IsMigrated = 0
AND vendor.LineofBusinessName IS NOT NULL
AND vendor.R_LineofBusinessId IS NULL;
INSERT INTO #ErrorLogs
SELECT V.Id
, 'Error'
, ('Invalid Default Line of Business for VendorId {' + CONVERT(NVARCHAR(MAX), V.Id) + '}')
FROM stgVendor V
WHERE V.IsMigrated = 0
AND V.LineofBusinessName IS NOT NULL
AND V.R_LineofBusinessId IS NULL;
INSERT INTO #ErrorLogs
SELECT V.Id
, 'Error'
, ('Type is mandatory for vendor for VendorId {' + CONVERT(NVARCHAR(MAX), V.Id) + '}')
FROM stgVendor V
WHERE V.IsMigrated = 0
AND V.Type IS NULL;
UPDATE stgVendor
SET
R_PortfolioId = Portfolios.Id
FROM stgVendor vendor
INNER JOIN Portfolios ON Portfolios.Name = vendor.PortfolioName
WHERE vendor.IsMigrated = 0
AND vendor.R_PortfolioId IS NULL;
INSERT INTO #ErrorLogs
SELECT V.Id
, 'Error'
, ('Invalid Portfolio Name for VendorId {' + CONVERT(NVARCHAR(MAX), V.Id) + '}')
FROM stgVendor V
WHERE V.IsMigrated = 0
AND R_PortfolioId IS NULL;
UPDATE stgVendorAddress
SET
R_CountryId = Countries.Id
FROM stgVendorAddress VA
INNER JOIN stgVendor V ON V.Id = VA.VendorId
INNER JOIN dbo.Countries ON VA.Country = Countries.ShortName
WHERE V.IsMigrated = 0
AND VA.Country IS NOT NULL
AND VA.R_CountryId IS NULL;
INSERT INTO #ErrorLogs
SELECT V.Id
, 'Error'
, ('Invalid Country for Vendor Address Id {' + CONVERT(NVARCHAR(MAX), VA.Id) + '} with VendorId {' + CONVERT(NVARCHAR(MAX), V.Id) + '}')
FROM stgVendor V
INNER JOIN stgVendorAddress VA ON VA.VendorId = V.Id
WHERE V.IsMigrated = 0
AND VA.Country IS NOT NULL
AND VA.R_CountryId IS NULL;
UPDATE stgVendorAddress
SET
R_HomeCountryId = Countries.Id
FROM stgVendorAddress VA
INNER JOIN stgVendor V ON V.Id = VA.VendorId
INNER JOIN dbo.Countries ON VA.HomeCountry = Countries.ShortName
WHERE V.IsMigrated = 0
AND VA.HomeCountry IS NOT NULL
AND VA.R_HomeCountryId IS NULL;
INSERT INTO #ErrorLogs
SELECT V.Id
, 'Error'
, ('Invalid HomeCountry for Vendor Address Id {' + CONVERT(NVARCHAR(MAX), VA.Id) + '} with VendorId {' + CONVERT(NVARCHAR(MAX), V.Id) + '}')
FROM stgVendor V
INNER JOIN stgVendorAddress VA ON VA.VendorId = V.Id
WHERE V.IsMigrated = 0
AND VA.HomeCountry IS NOT NULL
AND VA.R_HomeCountryId IS NULL;
UPDATE stgVendorAddress
SET
R_StateId = States.Id
FROM stgVendorAddress VA
INNER JOIN stgVendor V ON V.Id = VA.VendorId
INNER JOIN dbo.States ON VA.State = States.ShortName
AND States.CountryId = VA.R_CountryId
WHERE V.IsMigrated = 0
AND VA.State IS NOT NULL
AND VA.R_StateId IS NULL;
INSERT INTO #ErrorLogs
SELECT V.Id
, 'Error'
, ('Invalid State for Vendor Address Id {' + CONVERT(NVARCHAR(MAX), VA.Id) + '} with VendorId {' + CONVERT(NVARCHAR(MAX), V.Id) + '}')
FROM stgVendor V
INNER JOIN stgVendorAddress VA ON VA.VendorId = V.Id
WHERE V.IsMigrated = 0
AND VA.State IS NOT NULL
AND VA.R_StateId IS NULL;
UPDATE stgVendorAddress
SET
R_HomeStateId = States.Id
FROM stgVendorAddress VA
INNER JOIN stgVendor V ON V.Id = VA.VendorId
INNER JOIN dbo.States ON VA.HomeState = States.ShortName
AND States.CountryId = VA.R_HomeCountryId
WHERE V.IsMigrated = 0
AND VA.HomeState IS NOT NULL
AND VA.R_HomeStateId IS NULL;
INSERT INTO #ErrorLogs
SELECT V.Id
, 'Error'
, ('Invalid HomeState for Vendor Address Id {' + CONVERT(NVARCHAR(MAX), VA.Id) + '} with VendorId {' + CONVERT(NVARCHAR(MAX), V.Id) + '}')
FROM stgVendor V
INNER JOIN stgVendorAddress VA ON VA.VendorId = V.Id
WHERE V.IsMigrated = 0
AND VA.HomeState IS NOT NULL
AND VA.R_HomeStateId IS NULL;
UPDATE stgVendorBankAccount
SET
R_CurrencyId = Currencies.Id
FROM stgVendorBankAccount VBA
INNER JOIN stgVendor V ON V.Id = VBA.VendorId
INNER JOIN CurrencyCodes ON CurrencyCodes.ISO = VBA.CurrencyCode
INNER JOIN dbo.Currencies ON CurrencyCodes.Id = Currencies.CurrencyCodeId
WHERE V.IsMigrated = 0
AND VBA.CurrencyCode IS NOT NULL
AND VBA.R_CurrencyId IS NULL;
INSERT INTO #ErrorLogs
SELECT V.Id
, 'Error'
, ('Invalid Currency for VendorBankAccount Id {' + CONVERT(NVARCHAR(MAX), VBA.Id) + '} with VendorId {' + CONVERT(NVARCHAR(MAX), V.Id) + '}')
FROM stgVendor V
INNER JOIN stgVendorBankAccount VBA ON VBA.VendorId = V.Id
WHERE V.IsMigrated = 0
AND VBA.CurrencyCode IS NOT NULL
AND VBA.R_CurrencyId IS NULL;
UPDATE stgVendorBankAccount
SET
R_BankBranchId = BankBranches.Id
FROM stgVendorBankAccount VBA
INNER JOIN stgVendor V ON V.Id = VBA.VendorId
INNER JOIN BankBranches ON UPPER(VBA.BankBranchName) = UPPER(BankBranches.Name)
WHERE V.IsMigrated = 0
AND VBA.BankBranchName IS NOT NULL
AND VBA.R_BankBranchId IS NULL;

INSERT INTO #ErrorLogs
SELECT V.Id
, 'Error'
, ('Invalid BankBranch for VendorBankAccount Id {' + CONVERT(NVARCHAR(MAX), VBA.Id) + '} with VendorId {' + CONVERT(NVARCHAR(MAX), V.Id) + '}')
FROM stgVendor V
INNER JOIN stgVendorBankAccount VBA ON VBA.VendorId = V.Id
WHERE V.IsMigrated = 0
AND VBA.BankBranchName IS NOT NULL
AND VBA.R_BankBranchId IS NULL;
INSERT INTO #ErrorLogs
SELECT V.Id
, 'Error'
, ('Please enter Account Number for VendorBankAccount Id {' + CONVERT(NVARCHAR(MAX), VBA.Id) + '} with VendorId {' + CONVERT(NVARCHAR(MAX), V.Id) + '}')
FROM stgVendor V
INNER JOIN stgVendorBankAccount VBA ON VBA.VendorId = V.Id
JOIN BankBranches BB ON VBA.R_BankBranchId = BB.Id
LEFT JOIN CountryCurrencyRelationships CCR ON BB.CountryId = CCR.CountryId
AND VBA.R_CurrencyId = CCR.CurrencyId
WHERE(CCR.Id IS NULL
OR CCR.MandatoryAccountNumberField = 'AccountNumber')
AND (VBA.AccountNumber IS NULL
OR VBA.AccountNumber = '');
INSERT INTO #ErrorLogs
SELECT V.Id
, 'Error'
, ('Please enter IBAN for VendorBankAccount Id {' + CONVERT(NVARCHAR(MAX), VBA.Id) + '} with VendorId {' + CONVERT(NVARCHAR(MAX), V.Id) + '}')
FROM stgVendor V
JOIN stgVendorBankAccount VBA ON VBA.VendorId = V.Id
JOIN BankBranches BB ON VBA.R_BankBranchId = BB.Id
JOIN CountryCurrencyRelationships CCR ON BB.CountryId = CCR.CountryId
AND VBA.R_CurrencyId = CCR.CurrencyId
WHERE(CCR.MandatoryAccountNumberField = 'IBAN')
AND (VBA.IBAN IS NULL
OR VBA.IBAN = '');
INSERT INTO #ErrorLogs
SELECT V.Id
, 'Error'
, ('VendorBankAccount {' + CONVERT(NVARCHAR(MAX), VBA.Id) + '} associated with  VendorId {' + CONVERT(NVARCHAR(MAX), V.Id) + '} cannot be an ACH or Primary ACH account')
FROM stgVendor V
JOIN stgVendorBankAccount VBA ON VBA.VendorId = V.Id
WHERE(VBA.IBAN IS NOT NULL
AND (VBA.AutomatedPaymentMethod = 'ACHOrPAP'
OR VBA.IsPrimaryACH = 1));
UPDATE stgVendorBankAccount
SET
R_BankAccountCategoryId = BAC.Id
FROM stgVendorBankAccount VBA
INNER JOIN stgVendor V ON VBA.VendorId = V.Id
INNER JOIN BankAccountCategories BAC ON VBA.BankAccountCategoryName = BAC.AccountCategory
WHERE V.IsMigrated = 0
AND VBA.BankAccountCategoryName IS NOT NULL;
INSERT INTO #ErrorLogs
SELECT V.Id
, 'Error'
, ('Bank Account with Id {' + CONVERT(NVARCHAR(MAX), VBA.Id) + '} with VendorId {' + CONVERT(NVARCHAR(MAX), V.Id) + '} contains invalid Bank Account Category')
FROM stgVendor V
INNER JOIN stgVendorBankAccount VBA ON VBA.VendorId = V.Id
WHERE V.IsMigrated = 0
AND VBA.BankAccountCategoryName IS NOT NULL
AND VBA.R_BankAccountCategoryId IS NULL;
INSERT INTO #ErrorLogs
SELECT V.Id
, 'Error'
, ('Bank Account with Id {' + CONVERT(NVARCHAR(MAX), VBA.Id) + '} with VendorId {' + CONVERT(NVARCHAR(MAX), V.Id) + '} Must have a value for Account Category since  the account is ACH Account')
FROM stgVendor V
INNER JOIN stgVendorBankAccount VBA ON VBA.VendorId = V.Id
WHERE V.IsMigrated = 0
AND VBA.R_BankAccountCategoryId IS NULL
AND (VBA.AutomatedPaymentMethod = 'ACHOrPAP'
OR VBA.IsPrimaryACH = 1);
UPDATE stgVendorRemitTo
SET
R_AddressUniqueIdentifier = VA.Id
FROM stgVendorRemitTo VRT
INNER JOIN stgVendor V ON V.Id = VRT.VendorId
INNER JOIN stgVendorAddress VA ON VRT.VendorId = VA.VendorId
AND VRT.AddressUniqueIdentifier = VA.UniqueIdentifier
WHERE V.IsMigrated = 0
AND VRT.Id IS NOT NULL
AND VRT.R_AddressUniqueIdentifier IS NULL;
UPDATE stgVendorRemitTo
SET
R_ContactUniqueIdentifier = VC.Id
FROM stgVendorRemitTo VRT
INNER JOIN stgVendor V ON V.Id = VRT.VendorId
INNER JOIN stgVendorContact VC ON VRT.VendorId = VC.VendorId
AND VRT.ContactUniqueIdentifier = VC.UniqueIdentifier
WHERE V.IsMigrated = 0
AND VRT.Id IS NOT NULL
AND VRT.R_ContactUniqueIdentifier IS NULL;
INSERT INTO #ErrorLogs
SELECT V.Id
, 'Error'
, ('Invalid Remit To Address UniqueIdentifier {' + ISNULL(VRT.AddressUniqueIdentifier, 'NULL') + '} for VendorRemitTo Id {' + CONVERT(NVARCHAR(MAX), VRT.Id) + '} with VendorId {' + CONVERT(NVARCHAR(MAX), V.Id) + '}')
FROM stgVendor V
INNER JOIN stgVendorRemitTo VRT ON VRT.VendorId = V.Id
WHERE V.IsMigrated = 0
AND VRT.Id IS NOT NULL
AND VRT.R_AddressUniqueIdentifier IS NULL;
INSERT INTO #ErrorLogs
SELECT V.Id
, 'Error'
, ('Invalid Remit To Contact UniqueIdentifier {' + ISNULL(VRT.ContactUniqueIdentifier, 'NULL') + '} for VendorRemitTo Id {' + CONVERT(NVARCHAR(MAX), VRT.Id) + '} with VendorId {' + CONVERT(NVARCHAR(MAX), V.Id) + '}')
FROM stgVendor V
INNER JOIN stgVendorRemitTo VRT ON VRT.VendorId = V.Id
WHERE V.IsMigrated = 0
AND VRT.Id IS NOT NULL
AND VRT.ContactUniqueIdentifier IS NOT NULL
AND VRT.R_ContactUniqueIdentifier IS NULL;
INSERT INTO #ErrorLogs
SELECT V.Id
, 'Error'
, ('Both Beneficiary and Correspondent cannot be true for VendorRemitToWireDetail Id {' + CONVERT(NVARCHAR(MAX), VRTW.Id) + '} with VendorId {' + CONVERT(NVARCHAR(MAX), V.Id) + '}')
FROM stgVendor V
INNER JOIN stgVendorRemitTo VRT ON VRT.VendorId = V.Id
INNER JOIN stgVendorRemitToWireDetail VRTW ON VRTW.VendorRemitToId = VRT.Id
WHERE V.IsMigrated = 0
AND VRTW.IsCorrespondent = 1
AND VRTW.IsBeneficiary = 1;
UPDATE stgVendorLegalEntity
SET
R_LegalEntityId = LE.Id
FROM stgVendorLegalEntity VLE
INNER JOIN stgVendor V ON VLE.VendorId = V.Id
INNER JOIN LegalEntities LE ON LE.LegalEntityNumber = VLE.LegalEntityNumber
WHERE V.IsMigrated = 0
AND VLE.R_LegalEntityId IS NULL;
INSERT INTO #ErrorLogs
SELECT V.Id
, 'Error'
, ('Invalid Legal Entity Number {' + ISNULL(VLE.LegalEntityNumber, 'NULL') + '} for VendorId {' + CONVERT(NVARCHAR(MAX), V.Id) + '}')
FROM stgVendor V
INNER JOIN stgVendorLegalEntity VLE ON VLE.VendorId = V.Id
WHERE V.IsMigrated = 0
AND VLE.Id IS NOT NULL
AND VLE.R_LegalEntityId IS NULL;
INSERT INTO #ErrorLogs
SELECT V.Id
, 'Error'
, ('VendorProgramType Is Mandatory for ProgramVendor {' + CONVERT(NVARCHAR(MAX), V.Id) + '} with VendorId {' + CONVERT(NVARCHAR(MAX), V.Id) + '}')
FROM stgVendor V
WHERE V.IsMigrated = 0
AND V.IsVendorProgram = 1
AND V.VendorProgramType IS NULL;
INSERT INTO #ErrorLogs
SELECT V.Id
, 'Error'
, ('Default Line of Business Name is mandatory for ProgramVendorsAssignedToDealer {' + CONVERT(NVARCHAR(MAX), PV.Id) + '} with VendorId {' + CONVERT(NVARCHAR(MAX), V.Id) + '}')
FROM stgVendor V
INNER JOIN stgProgramVendorsAssignedToDealer PV ON PV.VendorId = V.Id
WHERE V.IsMigrated = 0
AND PV.Id IS NOT NULL
AND PV.LineofBusinessName IS NULL
AND PV.ProgramVendorNumber IS NOT NULL
AND V.VendorProgramType = 'DealerOrDistributor';
INSERT INTO #ErrorLogs
SELECT V.Id
, 'Error'
, ('Program is mandatory for ProgramVendorsAssignedToDealer {' + CONVERT(NVARCHAR(MAX), PV.Id) + '} with VendorId {' + CONVERT(NVARCHAR(MAX), V.Id) + '}')
FROM stgVendor V
INNER JOIN stgProgramVendorsAssignedToDealer PV ON PV.VendorId = V.Id
WHERE V.IsMigrated = 0
AND PV.Id IS NOT NULL
AND PV.Program IS NULL
AND V.VendorProgramType = 'DealerOrDistributor';
UPDATE stgProgramVendorsAssignedToDealer
SET
R_ProgramId = programs.Id
FROM stgProgramVendorsAssignedToDealer PV
INNER JOIN stgVendor V ON V.Id = PV.VendorId
INNER JOIN Programs programs ON programs.Name = PV.Program
WHERE PV.Id IS NOT NULL
AND PV.R_ProgramId IS NULL
AND PV.Program IS NOT NULL
AND V.IsMigrated = 0
AND V.IsVendorProgram = 1
AND V.VendorProgramType = 'DealerOrDistributor';
INSERT INTO #ErrorLogs
SELECT V.Id
, 'Error'
, ('Invalid Program Name for ProgramVendorsAssignedToDealer {' + CONVERT(NVARCHAR(MAX), PV.Id) + '} with VendorId {' + CONVERT(NVARCHAR(MAX), V.Id) + '}')
FROM stgVendor V
INNER JOIN stgProgramVendorsAssignedToDealer PV ON PV.VendorId = V.Id
WHERE PV.Id IS NOT NULL
AND PV.R_ProgramId IS NULL
AND PV.Program IS NOT NULL
AND V.IsMigrated = 0
AND V.IsVendorProgram = 1
AND V.VendorProgramType = 'DealerOrDistributor';
UPDATE stgVendor
SET
R_ProgramId = programs.Id
FROM stgVendor V
INNER JOIN Programs programs ON programs.Name = V.Program
WHERE V.R_ProgramId IS NULL
AND V.IsMigrated = 0
AND V.IsVendorProgram = 1
AND V.VendorProgramType = 'ProgramVendor';
INSERT INTO #ErrorLogs
SELECT V.Id
, 'Error'
, ('Invalid Program for ProgramVendor {' + CONVERT(NVARCHAR(MAX), V.Id) + '} with VendorId {' + CONVERT(NVARCHAR(MAX), V.Id) + '}')
FROM stgVendor V
WHERE V.R_ProgramId IS NULL
AND V.IsMigrated = 0
AND V.IsVendorProgram = 1
AND V.VendorProgramType = 'ProgramVendor';
INSERT INTO #ErrorLogs
SELECT V.Id
, 'Error'
, ('Please set at least one of the address as Main Address for Vendor with VendorId {' + CONVERT(NVARCHAR(MAX), V.Id) + '}')
FROM stgVendor V
WHERE V.IsMigrated = 0
AND V.Id NOT IN
(
SELECT VA.VendorId
FROM stgVendorAddress VA
WHERE IsMain = 1
GROUP BY VA.VendorId
HAVING COUNT(*) > 0
);
INSERT INTO #ErrorLogs
SELECT VA.VendorId
, 'Error'
, ('Please enter Valid Office Address for the Address indicated as Main Address with VendorId {' + CONVERT(NVARCHAR(MAX), V.Id) + ' and UniqueIdentifier ' + ISNULL(VA.UniqueIdentifier, 'NULL') + '}')
FROM stgVendor V
INNER JOIN stgVendorAddress VA ON VA.VendorId = V.Id
WHERE V.IsMigrated = 0
AND VA.Id IS NOT NULL
AND VA.IsMain = 1
AND (VA.AddressLine1 IS NULL
AND VA.City IS NULL
AND VA.State IS NULL
AND VA.Country IS NULL
AND VA.PostalCode IS NULL);
INSERT INTO #ErrorLogs
SELECT V.Id
, 'Error'
, ('Provide Home Address for the Address indicated as Main Address for Non Commercial Party with VendorId {' + CONVERT(NVARCHAR(MAX), V.Id) + ' and UniqueIdentifier ' + ISNULL(VA.UniqueIdentifier, 'NULL') + '}')
FROM stgVendor V
INNER JOIN stgVendorAddress VA ON VA.VendorId = V.Id
WHERE V.IsMigrated = 0
AND VA.Id IS NOT NULL
AND V.IsCorporate = 0
AND IsMain = 1
AND (VA.HomeAddressLine1 IS NULL
AND VA.HomeState IS NULL
AND VA.HomeCity IS NULL
AND VA.HomePostalCode IS NULL
AND VA.HomeCountry IS NULL);
INSERT INTO #ErrorLogs
SELECT V.Id
, 'Error'
, ('Provided Home Address is not valid for VendorId {' + CONVERT(NVARCHAR(MAX), V.Id) + ' and UniqueIdentifier ' + ISNULL(VA.UniqueIdentifier, 'NULL') + '}')
FROM stgVendor V
INNER JOIN stgVendorAddress VA ON VA.VendorId = V.Id
WHERE V.IsMigrated = 0
AND VA.Id IS NOT NULL
AND (VA.HomeAddressLine1 IS NOT NULL
AND (VA.HomeState IS NULL
OR VA.HomeCity IS NULL
OR VA.HomePostalCode IS NULL
OR VA.HomeCountry IS NULL)
OR VA.HomeState IS NOT NULL
AND (VA.HomeAddressLine1 IS NULL
OR VA.HomeCity IS NULL
OR VA.HomePostalCode IS NULL
OR VA.HomeCountry IS NULL)
OR VA.HomeCity IS NOT NULL
AND (VA.HomeState IS NULL
OR VA.HomeAddressLine1 IS NULL
OR VA.HomePostalCode IS NULL
OR VA.HomeCountry IS NULL)
OR VA.HomePostalCode IS NOT NULL
AND (VA.HomeState IS NULL
OR VA.HomeAddressLine1 IS NULL
OR VA.HomeCity IS NULL
OR VA.HomeCountry IS NULL)
OR VA.HomeCountry IS NOT NULL
AND (VA.HomeState IS NULL
OR VA.HomeAddressLine1 IS NULL
OR VA.HomeCity IS NULL
OR VA.HomePostalCode IS NULL));
INSERT INTO #ErrorLogs
SELECT V.Id
, 'Error'
, ('Provided Office Address is not valid for VendorId {' + CONVERT(NVARCHAR(MAX), V.Id) + ' and UniqueIdentifier ' + ISNULL(VA.UniqueIdentifier, 'NULL') + '}')
FROM stgVendor V
INNER JOIN stgVendorAddress VA ON VA.VendorId = V.Id
WHERE V.IsMigrated = 0
AND VA.Id IS NOT NULL
AND (VA.AddressLine1 IS NOT NULL
AND (VA.State IS NULL
OR VA.City IS NULL
OR VA.PostalCode IS NULL
OR VA.Country IS NULL)
OR VA.State IS NOT NULL
AND (VA.AddressLine1 IS NULL
OR VA.City IS NULL
OR VA.PostalCode IS NULL
OR VA.Country IS NULL)
OR VA.City IS NOT NULL
AND (VA.State IS NULL
OR VA.AddressLine1 IS NULL
OR VA.PostalCode IS NULL
OR VA.Country IS NULL)
OR VA.PostalCode IS NOT NULL
AND (VA.State IS NULL
OR VA.AddressLine1 IS NULL
OR VA.City IS NULL
OR VA.Country IS NULL)
OR VA.Country IS NOT NULL
AND (VA.State IS NULL
OR VA.AddressLine1 IS NULL
OR VA.City IS NULL
OR VA.PostalCode IS NULL));
INSERT INTO #ErrorLogs
SELECT V.Id
, 'Error'
, ('PostalCode Is Mandatory for VendorId {' + CONVERT(NVARCHAR(MAX), V.Id) + ' and UniqueIdentifier ' + ISNULL(VA.UniqueIdentifier, 'NULL') + '}')
FROM stgVendor V
INNER JOIN stgVendorAddress VA ON VA.VendorId = V.Id
INNER JOIN Countries C ON VA.R_CountryId = C.Id
WHERE V.IsMigrated = 0
AND VA.R_CountryId IS NOT NULL
AND (VA.PostalCode IS NULL
AND C.IsPostalCodeMandatory = 1);
INSERT INTO #ErrorLogs
SELECT V.Id
, 'Error'
, ('HomePostalCode Is Mandatory for VendorId {' + CONVERT(NVARCHAR(MAX), V.Id) + ' and UniqueIdentifier ' + ISNULL(VA.UniqueIdentifier, 'NULL') + '}')
FROM stgVendor V
INNER JOIN stgVendorAddress VA ON VA.VendorId = V.Id
INNER JOIN Countries C ON VA.R_HomeCountryId = C.Id
WHERE V.IsMigrated = 0
AND VA.R_HomeCountryId IS NOT NULL
AND (VA.HomePostalCode IS NULL
AND C.IsPostalCodeMandatory = 1);
INSERT INTO #ErrorLogs
SELECT V.Id
, 'Error'
, ('At least one Active Vendor Legal Entity Association for Vendor with VendorId {' + CONVERT(NVARCHAR(MAX), V.Id) + '}')
FROM stgVendor V
LEFT JOIN stgVendorLegalEntity VLE ON VLE.VendorId = V.Id
WHERE V.IsMigrated = 0
AND VLE.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT V.Id AS                                                                                                                                                                                                       [VendorId]
, 'Error'
, ('TaxId : {' + V.TaxId + '} is not in correct format, please enter TaxId with the regex format : {' + dbo.Countries.CorporateTaxIDMask + '} with Vendor Id {' + CONVERT(NVARCHAR(MAX), VA.VendorId) + '}') AS Message
FROM stgVendor V
INNER JOIN stgVendorAddress VA ON V.id = VA.VendorId
INNER JOIN dbo.Countries ON R_CountryId = dbo.Countries.Id
WHERE V.IsMigrated = 0
AND V.[IsCorporate] = 1
AND dbo.Countries.CorporateTaxIDMask IS NOT NULL
AND V.TaxId IS NOT NULL
AND VA.IsMain = 1
AND VA.R_CountryId IS NOT NULL
AND dbo.RegexStringMatch(V.TaxId, dbo.Countries.CorporateTaxIDMask) = 0;
INSERT INTO #ErrorLogs
SELECT V.Id AS                                                                                                                                                                                                                                                     [VendorId]
, 'Error'
, ('SocialSecurityNumber : {' + V.SocialSecurityNumber + '} is not in correct format, please enter SocialSecurityNumber with the regex format : {' + dbo.Countries.IndividualTaxIDMask + '} with Vendor Id {' + CONVERT(NVARCHAR(MAX), VA.VendorId) + '}') AS Message
FROM stgVendor V
INNER JOIN stgVendorAddress VA ON V.id = VA.VendorId
INNER JOIN dbo.Countries ON ISNULL(VA.R_CountryId, VA.R_HomeCountryId) = dbo.Countries.Id
WHERE V.IsMigrated = 0
AND V.[IsCorporate] = 0
AND dbo.Countries.IndividualTaxIDMask IS NOT NULL
AND V.SocialSecurityNumber IS NOT NULL
AND VA.IsMain = 1
AND (VA.R_HomeCountryId IS NOT NULL
OR VA.R_CountryId IS NOT NULL)
AND dbo.RegexStringMatch(V.SocialSecurityNumber, dbo.Countries.IndividualTaxIDMask) = 0;
INSERT INTO #ErrorLogs
SELECT V.Id AS                                                                                                                                                                                                                                   [VendorId]
, 'Error'
, ('PostalCode : {' + ISNULL(VA.PostalCode, 'NULL') + '} is not in correct format, please enter PostalCode with the regex format : {' + dbo.Countries.PostalCodeMask + '} with Vendor Id {' + CONVERT(NVARCHAR(MAX), VA.VendorId) + '}') AS Message
FROM stgVendor V
INNER JOIN stgVendorAddress VA ON V.id = VA.VendorId
INNER JOIN dbo.Countries ON VA.R_CountryId = dbo.Countries.Id
WHERE V.IsMigrated = 0
AND dbo.Countries.PostalCodeMask IS NOT NULL
AND VA.R_CountryId IS NOT NULL
AND VA.PostalCode IS NOT NULL
AND dbo.RegexStringMatch(VA.PostalCode, dbo.Countries.PostalCodeMask) = 0;
INSERT INTO #ErrorLogs
SELECT V.Id AS                                                                                                                                                                                                                                                [VendorId]
, 'Error'
, ('HomePostalCode : {' + ISNULL(VA.HomePostalCode, 'NULL') + '} is not in correct format, please enter HomePostalCode with the regex format : {' + dbo.Countries.PostalCodeMask + '} with Vendor Id  {' + CONVERT(NVARCHAR(MAX), VA.VendorId) + '}') AS Message
FROM stgVendor V
INNER JOIN stgVendorAddress VA ON V.id = VA.VendorId
INNER JOIN dbo.Countries ON VA.R_HomeCountryId = dbo.Countries.Id
WHERE V.IsMigrated = 0
AND dbo.Countries.PostalCodeMask IS NOT NULL
AND VA.R_HomeCountryId IS NOT NULL
AND VA.HomePostalCode IS NOT NULL
AND dbo.RegexStringMatch(VA.HomePostalCode, dbo.Countries.PostalCodeMask) = 0;


SET @FailedRecords =
(
SELECT ISNULL(COUNT(DISTINCT StagingRootEntityId), 0)
FROM #ErrorLogs
);
MERGE stgProcessingLog AS ProcessingLog
USING
(
SELECT Id
FROM stgVendor
WHERE IsMigrated = 0
AND Id NOT IN
(
SELECT StagingRootEntityId
FROM #ErrorLogs
)
) AS ProcessedVendors
ON(ProcessingLog.StagingRootEntityId = ProcessedVendors.Id
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
(ProcessedVendors.Id
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
) AS ErrorVendors
ON(ProcessingLog.StagingRootEntityId = ErrorVendors.StagingRootEntityId
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
(ErrorVendors.StagingRootEntityId
, @UserId
, @CreatedTime
, @ModuleIterationStatusId
)
OUTPUT Inserted.Id
, ErrorVendors.StagingRootEntityId
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
JOIN #FailedProcessingLogs ON #ErrorLogs.StagingRootEntityId = #FailedProcessingLogs.VendorId;
DROP TABLE #ErrorLogs;
DROP TABLE #FailedProcessingLogs;
DROP TABLE #CreatedProcessingLogs;
END;

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ValidateFunders]
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
FunderId BIGINT NOT NULL
);
CREATE TABLE #CreatedProcessingLogs([Id] BIGINT NOT NULL);
SET @ProcessedRecords =
(
SELECT ISNULL(COUNT(Id), 0)
FROM stgFunder
WHERE IsMigrated = 0
);

INSERT INTO #ErrorLogs
SELECT F.Id
, 'Error'
, ('Invalid State of Incorporation for FunderId {' + CONVERT(NVARCHAR(MAX), F.Id) + '}')
FROM stgFunder F
LEFT JOIN States ON UPPER(States.ShortName) = UPPER(F.StateOfIncorporation)
WHERE F.IsMigrated = 0
AND LTRIM(RTRIM(F.StateOfIncorporation)) <> ''
AND States.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT F.Id
, 'Error'
, ('Invalid Portfolio Name for FunderId {' + CONVERT(NVARCHAR(MAX), F.Id) + '}')
FROM stgFunder F
LEFT JOIN Portfolios ON Portfolios.Name = F.PortfolioName
WHERE F.IsMigrated = 0
AND Portfolios.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT F.Id
, 'Error'
, ('Invalid State for Funder Address Id {' + CONVERT(NVARCHAR(MAX), FA.Id) + '} with FunderId {' + CONVERT(NVARCHAR(MAX), F.Id) + '}')
FROM stgFunder F
INNER JOIN stgFunderAddress FA ON FA.FunderId = F.Id
LEFT JOIN dbo.States ON FA.State = States.ShortName
WHERE F.IsMigrated = 0
AND LTRIM(RTRIM(FA.State)) <> ''
AND States.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT F.Id
, 'Error'
, ('Invalid HomeState for Funder Address Id {' + CONVERT(NVARCHAR(MAX), FA.Id) + '} with FunderId {' + CONVERT(NVARCHAR(MAX), F.Id) + '}')
FROM stgFunder F
INNER JOIN stgFunderAddress FA ON FA.FunderId = F.Id
LEFT JOIN dbo.States ON FA.HomeState = States.ShortName
WHERE F.IsMigrated = 0
AND LTRIM(RTRIM(FA.HomeState)) <> ''
AND States.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT F.Id
, 'Error'
, ('Invalid Country for Funder Address Id {' + CONVERT(NVARCHAR(MAX), FA.Id) + '} with FunderId {' + CONVERT(NVARCHAR(MAX), F.Id) + '}')
FROM stgFunder F
INNER JOIN stgFunderAddress FA ON FA.FunderId = F.Id
LEFT JOIN dbo.Countries ON FA.Country = Countries.ShortName
WHERE F.IsMigrated = 0
AND LTRIM(RTRIM(FA.Country)) <> ''
AND Countries.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT F.Id
, 'Error'
, ('Invalid HomeCountry for Funder Address Id {' + CONVERT(NVARCHAR(MAX), FA.Id) + '} with FunderId {' + CONVERT(NVARCHAR(MAX), F.Id) + '}')
FROM stgFunder F
INNER JOIN stgFunderAddress FA ON FA.FunderId = F.Id
LEFT JOIN dbo.Countries ON FA.HomeCountry = Countries.ShortName
WHERE F.IsMigrated = 0
AND LTRIM(RTRIM(FA.HomeCountry)) <> ''
AND Countries.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT F.Id
, 'Error'
, ('TaxId : {' + F.TaxId + '} is not in correct format, please enter TaxId with the regex format : {' + dbo.Countries.CorporateTaxIDMask + '} with Funder Id {' + CONVERT(NVARCHAR(MAX), FA.FunderId) + '}') AS Message
FROM stgFunder F
INNER JOIN stgFunderAddress FA ON F.Id = FA.FunderId
INNER JOIN dbo.Countries ON FA.Country = Countries.ShortName
WHERE F.IsMigrated = 0
AND F.[IsCorporate] = 1
AND dbo.Countries.CorporateTaxIDMask IS NOT NULL
AND F.TaxId IS NOT NULL
AND FA.IsMain = 1
AND dbo.RegexStringMatch(F.TaxId, dbo.Countries.CorporateTaxIDMask) = 0;
INSERT INTO #ErrorLogs
SELECT F.Id
, 'Error'
, ('SocialSecurityNumber : {' + F.SocialSecurityNumber + '} is not in correct format, please enter SocialSecurityNumber with the regex format : {' + dbo.Countries.IndividualTaxIDMask + '} with Funder Id {' + CONVERT(NVARCHAR(MAX), FA.FunderId) + '}') AS Message
FROM stgFunder F
INNER JOIN stgFunderAddress FA ON F.Id = FA.FunderId
INNER JOIN dbo.Countries ON ISNULL(FA.Country, FA.HomeCountry) = Countries.ShortName
WHERE F.IsMigrated = 0
AND F.[IsCorporate] = 0
AND dbo.Countries.IndividualTaxIDMask IS NOT NULL
AND F.SocialSecurityNumber IS NOT NULL
AND FA.IsMain = 1
AND dbo.RegexStringMatch(F.SocialSecurityNumber, dbo.Countries.IndividualTaxIDMask) = 0;
INSERT INTO #ErrorLogs
SELECT F.Id
, 'Error'
, ('PostalCode : {' + ISNULL(FA.PostalCode, 'NULL') + '} is not in correct format, please enter PostalCode with the regex format : {' + dbo.Countries.PostalCodeMask + '} with Funder Id {' + CONVERT(NVARCHAR(MAX), FA.FunderId) + '}') AS Message
FROM stgFunder F
INNER JOIN stgFunderAddress FA ON F.Id = FA.FunderId
INNER JOIN dbo.Countries ON FA.Country = Countries.ShortName
WHERE F.IsMigrated = 0
AND dbo.Countries.PostalCodeMask IS NOT NULL
AND FA.PostalCode IS NOT NULL
AND dbo.RegexStringMatch(FA.PostalCode, dbo.Countries.PostalCodeMask) = 0;
INSERT INTO #ErrorLogs
SELECT F.Id
, 'Error'
, ('HomePostalCode : {' + ISNULL(FA.HomePostalCode, 'NULL') + '} is not in correct format, please enter HomePostalCode with the regex format : {' + dbo.Countries.PostalCodeMask + '} with Funder Id  {' + CONVERT(NVARCHAR(MAX), FA.FunderId) + '}') AS Message
FROM stgFunder F
INNER JOIN stgFunderAddress FA ON F.Id = FA.FunderId
INNER JOIN dbo.Countries ON FA.HomeCountry = Countries.ShortName
WHERE F.IsMigrated = 0
AND dbo.Countries.PostalCodeMask IS NOT NULL
AND FA.HomePostalCode IS NOT NULL
AND dbo.RegexStringMatch(FA.HomePostalCode, dbo.Countries.PostalCodeMask) = 0;
INSERT INTO #ErrorLogs
SELECT F.Id
, 'Error'
, ('Invalid BankBranch for FunderBankAccount Id {' + CONVERT(NVARCHAR(MAX), FBA.Id) + '} with FunderId {' + CONVERT(NVARCHAR(MAX), F.Id) + '}')
FROM stgFunder F
INNER JOIN stgFunderBankAccount FBA ON FBA.FunderId = F.Id
LEFT JOIN BankBranches ON UPPER(FBA.BankBranchName) = UPPER(BankBranches.Name)
WHERE F.IsMigrated = 0
AND LTRIM(RTRIM(FBA.BankBranchName)) <> ''
AND BankBranches.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT F.Id
, 'Error'
, ('Invalid Currency for FunderBankAccount Id {' + CONVERT(NVARCHAR(MAX), FBA.Id) + '} with FunderId {' + CONVERT(NVARCHAR(MAX), F.Id) + '}')
FROM stgFunder F
INNER JOIN stgFunderBankAccount FBA ON FBA.FunderId = F.Id
LEFT JOIN CurrencyCodes ON CurrencyCodes.ISO = FBA.CurrencyCode
LEFT JOIN dbo.Currencies ON CurrencyCodes.Id = Currencies.CurrencyCodeId
WHERE F.IsMigrated = 0
AND LTRIM(RTRIM(FBA.CurrencyCode)) <> ''
AND Currencies.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT F.Id
, 'Error'
, ('IBAN is Invalid. First two characters must be alphabets and Length must be between 4 and 34 for FunderBankAccount Id {' + CONVERT(NVARCHAR(MAX), FBA.Id) + '} with FunderId {' + CONVERT(NVARCHAR(MAX), F.Id) + '}')
FROM stgFunder F
INNER JOIN stgFunderBankAccount FBA ON FBA.FunderId = F.Id
WHERE F.IsMigrated = 0
AND LTRIM(RTRIM(FBA.IBAN)) <> ''
AND FBA.IBAN NOT LIKE '[a-Z][a-Z]%'
OR (LEN(FBA.IBAN) NOT BETWEEN 4 AND 34);
INSERT INTO #ErrorLogs
SELECT FBA.FunderId
, 'Error'
, ('The following IBAN(s) ' + ISNULL(FBA.IBAN, 'NULL') + ' already exists. Please enter unique IBAN number for Funder Id {' + CONVERT(NVARCHAR(MAX), FBA.FunderId) + '}') AS Message
FROM stgFunder F
INNER JOIN stgFunderBankAccount FBA ON FBA.FundeRId = F.Id
AND F.IsMigrated = 0
WHERE FBA.IBAN IS NOT NULL
AND LTRIM(RTRIM(FBA.IBAN)) <> ''
GROUP BY FBA.FunderId
, FBA.IBAN
HAVING COUNT(*) > 1;
INSERT INTO #ErrorLogs
SELECT FA.FunderId
, 'Error'
, ('Please enter Valid Office Address for the Address indicated as Main Address with FunderId {' + CONVERT(NVARCHAR(MAX), F.Id) + ' and UniqueIdentifier ' + ISNULL(FA.UniqueIdentifier, 'NULL') + '}')
FROM stgFunder F
INNER JOIN stgFunderAddress FA ON FA.FunderId = F.Id
WHERE F.IsMigrated = 0
AND FA.Id IS NOT NULL
AND FA.IsMain = 1
AND (FA.AddressLine1 IS NULL
AND FA.City IS NULL
AND FA.State IS NULL
AND FA.Country IS NULL
AND FA.PostalCode IS NULL);
INSERT INTO #ErrorLogs
SELECT F.Id
, 'Error'
, ('Provide Home Address for the Address indicated as Main Address for Non Commercial Party with FunderId {' + CONVERT(NVARCHAR(MAX), F.Id) + ' and UniqueIdentifier ' + ISNULL(FA.UniqueIdentifier, 'NULL') + '}')
FROM stgFunder F
INNER JOIN stgFunderAddress FA ON FA.FunderId = F.Id
WHERE F.IsMigrated = 0
AND FA.Id IS NOT NULL
AND F.IsCorporate = 0
AND IsMain = 1
AND (FA.HomeAddressLine1 IS NULL
AND FA.HomeState IS NULL
AND FA.HomeCity IS NULL
AND FA.HomePostalCode IS NULL
AND FA.HomeCountry IS NULL);
INSERT INTO #ErrorLogs
SELECT F.Id
, 'Error'
, ('Provided Home Address is not valid for FunderId {' + CONVERT(NVARCHAR(MAX), F.Id) + ' and UniqueIdentifier ' + ISNULL(FA.UniqueIdentifier, 'NULL') + '}')
FROM stgFunder F
INNER JOIN stgFunderAddress FA ON FA.FunderId = F.Id
WHERE F.IsMigrated = 0
AND FA.Id IS NOT NULL
AND (FA.HomeAddressLine1 IS NOT NULL
AND (FA.HomeState IS NULL
OR FA.HomeCity IS NULL
OR FA.HomePostalCode IS NULL
OR FA.HomeCountry IS NULL)
OR FA.HomeState IS NOT NULL
AND (FA.HomeAddressLine1 IS NULL
OR FA.HomeCity IS NULL
OR FA.HomePostalCode IS NULL
OR FA.HomeCountry IS NULL)
OR FA.HomeCity IS NOT NULL
AND (FA.HomeState IS NULL
OR FA.HomeAddressLine1 IS NULL
OR FA.HomePostalCode IS NULL
OR FA.HomeCountry IS NULL)
OR FA.HomePostalCode IS NOT NULL
AND (FA.HomeState IS NULL
OR FA.HomeAddressLine1 IS NULL
OR FA.HomeCity IS NULL
OR FA.HomeCountry IS NULL)
OR FA.HomeCountry IS NOT NULL
AND (FA.HomeState IS NULL
OR FA.HomeAddressLine1 IS NULL
OR FA.HomeCity IS NULL
OR FA.HomePostalCode IS NULL));
INSERT INTO #ErrorLogs
SELECT F.Id
, 'Error'
, ('Provided Office Address is not valid for FunderId {' + CONVERT(NVARCHAR(MAX), F.Id) + ' and UniqueIdentifier ' + ISNULL(FA.UniqueIdentifier, 'NULL') + '}')
FROM stgFunder F
INNER JOIN stgFunderAddress FA ON FA.FunderId = F.Id
WHERE F.IsMigrated = 0
AND FA.Id IS NOT NULL
AND (FA.AddressLine1 IS NOT NULL
AND (FA.State IS NULL
OR FA.City IS NULL
OR FA.PostalCode IS NULL
OR FA.Country IS NULL)
OR FA.State IS NOT NULL
AND (FA.AddressLine1 IS NULL
OR FA.City IS NULL
OR FA.PostalCode IS NULL
OR FA.Country IS NULL)
OR FA.City IS NOT NULL
AND (FA.State IS NULL
OR FA.AddressLine1 IS NULL
OR FA.PostalCode IS NULL
OR FA.Country IS NULL)
OR FA.PostalCode IS NOT NULL
AND (FA.State IS NULL
OR FA.AddressLine1 IS NULL
OR FA.City IS NULL
OR FA.Country IS NULL)
OR FA.Country IS NOT NULL
AND (FA.State IS NULL
OR FA.AddressLine1 IS NULL
OR FA.City IS NULL
OR FA.PostalCode IS NULL));
INSERT INTO #ErrorLogs
SELECT F.Id
, 'Error'
, ('Both Beneficiary and Correspondent cannot be true for FunderRemitToWireDetail Id {' + CONVERT(NVARCHAR(MAX), FRTW.Id) + '} with FunderId {' + CONVERT(NVARCHAR(MAX), F.Id) + '}')
FROM stgFunder F
INNER JOIN stgFunderRemitTo FRT ON FRT.FunderId = F.Id
INNER JOIN stgFunderRemitToWireDetail FRTW ON FRTW.FunderRemitToId = FRT.Id
WHERE F.IsMigrated = 0
AND FRTW.IsCorrespondent = 1
AND FRTW.IsBeneficiary = 1;
INSERT INTO #ErrorLogs
SELECT F.Id
, 'Error'
, ('Invalid FunderBankAccount for BankAccountNumber {' + ISNULL(FRTW.BankAccountNumber, 'NULL') + '} for FunderRemitTo Id {' + CONVERT(NVARCHAR(MAX), FRT.Id) + '} with FunderId {' + CONVERT(NVARCHAR(MAX), F.Id) + '}')
FROM stgFunder F
INNER JOIN stgFunderRemitTo FRT ON FRT.FunderId = F.Id
INNER JOIN stgFunderRemitToWireDetail FRTW ON FRTW.FunderRemitToId = FRT.Id
LEFT JOIN stgFunderBankAccount FBA ON FBA.FunderId = FRT.FunderId
AND FBA.AccountNumber = FRTW.BankAccountNumber
WHERE F.IsMigrated = 0
AND FRT.Id IS NOT NULL
AND FBA.Id IS NULL
AND FRT.ReceiptType != 'Check';
INSERT INTO #ErrorLogs
SELECT F.Id
, 'Error'
, ('Invalid Remit To Address UniqueIdentifier {' + ISNULL(FRT.AddressUniqueIdentifier, 'NULL') + '} for FunderRemitTo Id {' + CONVERT(NVARCHAR(MAX), FRT.Id) + '} with FunderId {' + CONVERT(NVARCHAR(MAX), F.Id) + '}')
FROM stgFunder F
INNER JOIN stgFunderRemitTo FRT ON FRT.FunderId = F.Id
LEFT JOIN stgFunderAddress FA ON FRT.FunderId = FA.FunderId
AND FRT.AddressUniqueIdentifier = FA.UniqueIdentifier
WHERE F.IsMigrated = 0
AND FRT.Id IS NOT NULL
AND FA.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT F.Id
, 'Error'
, ('Invalid Remit To Contact UniqueIdentifier {' + ISNULL(FRT.ContactUniqueIdentifier, 'NULL') + '} for FunderRemitTo Id {' + CONVERT(NVARCHAR(MAX), FRT.Id) + '} with FunderId {' + CONVERT(NVARCHAR(MAX), F.Id) + '}')
FROM stgFunder F
INNER JOIN stgFunderRemitTo FRT ON FRT.FunderId = F.Id
LEFT JOIN stgFunderContact FC ON FRT.FunderId = FC.FunderId
AND FRT.ContactUniqueIdentifier = FC.UniqueIdentifier
WHERE F.IsMigrated = 0
AND FRT.Id IS NOT NULL
AND LTRIM(RTRIM(FRT.ContactUniqueIdentifier)) <> ''
AND FC.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT F.Id
, 'Error'
, ('Invalid Remit To Logo Name {' + ISNULL(FRT.LogoName, 'NULL') + '} for FunderRemitTo Id {' + CONVERT(NVARCHAR(MAX), FRT.Id) + '} with FunderId {' + CONVERT(NVARCHAR(MAX), F.Id) + '}')
FROM stgFunder F
INNER JOIN stgFunderRemitTo FRT ON FRT.FunderId = F.Id
LEFT JOIN Logoes Logoes ON Logoes.Name = FRT.LogoName
AND Logoes.IsActive = 1
AND FRT.LogoEntityType = Logoes.EntityType
WHERE F.IsMigrated = 0
AND FRT.Id IS NOT NULL
AND LTRIM(RTRIM(FRT.LogoName)) <> ''
AND Logoes.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT F.Id
, 'Error'
, ('Please set at least one of the address as Main Address for Funder with FunderId {' + CONVERT(NVARCHAR(MAX), F.Id) + '}')
FROM stgFunder F
WHERE F.IsMigrated = 0
AND F.Id NOT IN
(
SELECT FA.FunderId
FROM stgFunderAddress FA
WHERE IsMain = 1
GROUP BY FA.FunderId
HAVING COUNT(*) > 0
);


SET @FailedRecords =
(
SELECT ISNULL(COUNT(DISTINCT StagingRootEntityId), 0)
FROM #ErrorLogs
);
MERGE stgProcessingLog AS ProcessingLog
USING
(
SELECT Id
FROM stgFunder
WHERE IsMigrated = 0
AND Id NOT IN
(
SELECT StagingRootEntityId
FROM #ErrorLogs
)
) AS ProcessedFunders
ON(ProcessingLog.StagingRootEntityId = ProcessedFunders.Id
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
(ProcessedFunders.Id
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
) AS ErrorFunders
ON(ProcessingLog.StagingRootEntityId = ErrorFunders.StagingRootEntityId
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
(ErrorFunders.StagingRootEntityId
, @UserId
, @CreatedTime
, @ModuleIterationStatusId
)
OUTPUT Inserted.Id
, ErrorFunders.StagingRootEntityId
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
JOIN #FailedProcessingLogs ON #ErrorLogs.StagingRootEntityId = #FailedProcessingLogs.FunderId;
DROP TABLE #ErrorLogs;
DROP TABLE #FailedProcessingLogs;
DROP TABLE #CreatedProcessingLogs;
END;

GO

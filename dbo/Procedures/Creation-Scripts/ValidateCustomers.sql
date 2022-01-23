SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ValidateCustomers]
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
        ([Id]         BIGINT NOT NULL, 
         [CustomerId] BIGINT NOT NULL
        );
        CREATE TABLE #CreatedProcessingLogs([Id] BIGINT NOT NULL);
        SET @ProcessedRecords =
        (
            SELECT ISNULL(COUNT(Id), 0)
            FROM stgCustomer
            WHERE IsMigrated = 0
        );
        UPDATE stgCustomer
          SET 
              R_CountryId = Countries.Id
        FROM stgCustomer C
             INNER JOIN Countries ON C.Country = Countries.ShortName
                                     AND Countries.IsActive = 1
        WHERE C.IsMigrated = 0
              AND C.Country IS NOT NULL;
        INSERT INTO #ErrorLogs
        SELECT C.Id
             , 'Error'
             , 'Invalid Country for CustomerId {' + CONVERT(NVARCHAR(MAX), C.Id) + '}'
        FROM stgCustomer AS C
        WHERE C.IsMigrated = 0
              AND C.Country IS NOT NULL
              AND C.R_CountryId IS NULL;
        INSERT INTO #ErrorLogs
        SELECT C.Id
             , 'Error'
             , CONCAT('Please set at least one of the address as Main Address for Customer with CustomerId {', CONVERT(NVARCHAR(MAX), C.Id), '}')
        FROM stgCustomer AS C
        WHERE C.IsMigrated = 0
              AND C.Id NOT IN
        (
            SELECT CA.CustomerId
            FROM stgCustomerAddress AS CA
            WHERE IsMain = 1
            GROUP BY CA.CustomerId
            HAVING COUNT(*) > 0
        );
        INSERT INTO #ErrorLogs
        SELECT CBA.CustomerId
             , 'Error'
             , CONCAT('The following IBAN(s) ', ISNULL(CBA.IBAN, 'NULL'), ' already exists. Please enter unique IBAN number for Customer Id {', CONVERT(NVARCHAR(MAX), CBA.CustomerId), '}') AS Message
        FROM stgCustomer AS C
             INNER JOIN stgCustomerBankAccount AS CBA ON CBA.CustomerId = C.Id
        WHERE C.IsMigrated = 0
              AND CBA.IBAN <> ''
              AND CBA.IBAN IS NOT NULL
        GROUP BY CBA.CustomerId
               , CBA.IBAN
        HAVING COUNT(*) > 1;
        UPDATE stgCustomerAddress
          SET 
              R_CountryId = Countries.Id
        FROM stgCustomerAddress CA
             INNER JOIN stgCustomer C ON C.Id = CA.CustomerId
             INNER JOIN dbo.Countries ON CA.Country = Countries.ShortName
                                         AND Countries.IsActive = 1
        WHERE C.IsMigrated = 0
              AND CA.Country IS NOT NULL;
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
        INSERT INTO #ErrorLogs
        SELECT C.Id
             , 'Error'
             , 'Invalid Country for Customer Address Id {' + CONVERT(NVARCHAR(MAX), CA.Id) + '} with CustomerId {' + CONVERT(NVARCHAR(MAX), C.Id) + '}'
        FROM stgCustomer AS C
             INNER JOIN stgCustomerAddress AS CA ON CA.CustomerId = C.Id
        WHERE C.IsMigrated = 0
              AND CA.Country IS NOT NULL
              AND CA.R_CountryId IS NULL;       
        INSERT INTO #ErrorLogs
        SELECT CA.CustomerId
             , 'Error'
             , CONCAT('Please enter Valid Office Address for the Address indicated as Main Address with CustomerId {', CONVERT(NVARCHAR(MAX), C.Id), ' and UniqueIdentifier ', ISNULL(CA.UniqueIdentifier, 'NULL'), '}')
        FROM stgCustomer AS C
             INNER JOIN stgCustomerAddress AS CA ON CA.CustomerId = C.Id
        WHERE C.IsMigrated = 0
              AND CA.Id IS NOT NULL
              AND CA.IsMain = 1
              AND C.IsCorporate = 1
              AND CA.AddressLine1 IS NULL
              AND CA.City IS NULL
              AND CA.State IS NULL
              AND CA.Country IS NULL
              AND CA.PostalCode IS NULL;
        INSERT INTO #ErrorLogs
        SELECT C.Id
             , 'Error'
             , CONCAT('Provide Home Address for the Address indicated as Main Address for Non Commercial Party with CustomerId {', CONVERT(NVARCHAR(MAX), C.Id), ' and UniqueIdentifier ', ISNULL(CA.UniqueIdentifier, 'NULL'), '}')
        FROM stgCustomer AS C
             INNER JOIN stgCustomerAddress AS CA ON CA.CustomerId = C.Id
        WHERE C.IsMigrated = 0
              AND CA.Id IS NOT NULL
              AND C.IsCorporate = 0
              AND IsMain = 1
              AND CA.HomeAddressLine1 IS NULL
              AND CA.HomeState IS NULL
              AND CA.HomeCity IS NULL
              AND CA.HomePostalCode IS NULL
              AND CA.HomeCountry IS NULL;
        INSERT INTO #ErrorLogs
        SELECT C.Id
             , 'Error'
             , ('Please enter Business Type with CustomerId {' + CONVERT(NVARCHAR(MAX), C.Id) + '}') AS Message
        FROM stgCustomer C
        WHERE IsMigrated = 0
              AND C.BusinessType = '_'
              AND C.IsLimitedDisclosureParty = 0;
        INSERT INTO #ErrorLogs
        SELECT C.Id
             , 'Error'
             , CONCAT('Provided Home Address is not valid for CustomerId {', CONVERT(NVARCHAR(MAX), C.Id), ' and UniqueIdentifier ', ISNULL(CA.UniqueIdentifier, 'NULL'), '}')
        FROM stgCustomer AS C
             INNER JOIN stgCustomerAddress AS CA ON CA.CustomerId = C.Id
        WHERE C.IsMigrated = 0
              AND CA.Id IS NOT NULL
              AND (CA.HomeAddressLine1 IS NOT NULL
                   AND (CA.HomeState IS NULL
                        OR CA.HomeCity IS NULL
                        OR CA.HomePostalCode IS NULL
                        OR CA.HomeCountry IS NULL)
                   OR CA.HomeState IS NOT NULL
                   AND (CA.HomeAddressLine1 IS NULL
                        OR CA.HomeCity IS NULL
                        OR CA.HomePostalCode IS NULL
                        OR CA.HomeCountry IS NULL)
                   OR CA.HomeCity IS NOT NULL
                   AND (CA.HomeState IS NULL
                        OR CA.HomeAddressLine1 IS NULL
                        OR CA.HomePostalCode IS NULL
                        OR CA.HomeCountry IS NULL)
                   OR CA.HomePostalCode IS NOT NULL
                   AND (CA.HomeState IS NULL
                        OR CA.HomeAddressLine1 IS NULL
                        OR CA.HomeCity IS NULL
                        OR CA.HomeCountry IS NULL)
                   OR CA.HomeCountry IS NOT NULL
                   AND (CA.HomeState IS NULL
                        OR CA.HomeAddressLine1 IS NULL
                        OR CA.HomeCity IS NULL
                        OR CA.HomePostalCode IS NULL));
        INSERT INTO #ErrorLogs
        SELECT C.Id
             , 'Error'
             , CONCAT('Provided Office Address is not valid for CustomerId {', CONVERT(NVARCHAR(MAX), C.Id), ' and UniqueIdentifier ', ISNULL(CA.UniqueIdentifier, 'NULL'), '}')
        FROM stgCustomer AS C
             INNER JOIN stgCustomerAddress AS CA ON CA.CustomerId = C.Id
        WHERE C.IsMigrated = 0
              AND CA.Id IS NOT NULL
              AND (CA.AddressLine1 IS NOT NULL
                   AND (CA.State IS NULL
                        OR CA.City IS NULL
                        OR CA.PostalCode IS NULL
                        OR CA.Country IS NULL)
                   OR CA.State IS NOT NULL
                   AND (CA.AddressLine1 IS NULL
                        OR CA.City IS NULL
                        OR CA.PostalCode IS NULL
                        OR CA.Country IS NULL)
                   OR CA.City IS NOT NULL
                   AND (CA.State IS NULL
                        OR CA.AddressLine1 IS NULL
                        OR CA.PostalCode IS NULL
                        OR CA.Country IS NULL)
                   OR CA.PostalCode IS NOT NULL
                   AND (CA.State IS NULL
                        OR CA.AddressLine1 IS NULL
                        OR CA.City IS NULL
                        OR CA.Country IS NULL)
                   OR CA.Country IS NOT NULL
                   AND (CA.State IS NULL
                        OR CA.AddressLine1 IS NULL
                        OR CA.City IS NULL
                        OR CA.PostalCode IS NULL));
        UPDATE stgCustomer
          SET 
              R_StateofIncorporationId = States.Id
        FROM stgCustomer C
             INNER JOIN States ON UPPER(States.ShortName) = UPPER(C.StateOfIncorporation)
        WHERE C.IsMigrated = 0
              AND c.StateOfIncorporation IS NOT NULL;
        INSERT INTO #ErrorLogs
        SELECT C.Id
             , 'Error'
             , 'Invalid State of Incorporation for CustomerId {' + CONVERT(NVARCHAR(MAX), C.Id) + '}'
        FROM stgCustomer AS C
        WHERE C.IsMigrated = 0
              AND C.StateOfIncorporation IS NOT NULL
              AND C.R_StateofIncorporationId IS NULL;
        UPDATE stgCustomer
          SET 
              R_JurisdictionOfSovereignCountryId = Countries.Id
        FROM stgCustomer C
             INNER JOIN Countries ON Countries.ShortName = C.ISOCountryCodeForJurisdictionOfSovereign
        WHERE C.IsMigrated = 0
              AND C.ISOCountryCodeForJurisdictionOfSovereign IS NOT NULL;
        INSERT INTO #ErrorLogs
        SELECT C.Id
             , 'Error'
             , 'Invalid CountryCode for JurisdictionOfSovereign for CustomerId {' + CONVERT(NVARCHAR(MAX), C.Id) + '}'
        FROM stgCustomer AS C
        WHERE C.IsMigrated = 0
              AND C.ISOCountryCodeForJurisdictionOfSovereign IS NOT NULL
              AND C.R_JurisdictionOfSovereignCountryId IS NULL;
        UPDATE stgCustomer
          SET 
              R_NAICSCodeId = code.Id
			 ,R_SICCodeId = scode.Id
        FROM stgCustomer C
             INNER JOIN dbo.BusinessTypeNAICSCodes code ON C.NAICSCode = code.NAICSCode
                                                           AND code.IsActive = 1
			 INNER JOIN dbo.BusinessTypesSICsCodes scode on C.SICCode = scode.Name 
														   AND code.BusinessTypesSICsCodeId = scode.Id 
														   AND scode.IsActive = 1
        WHERE C.IsMigrated = 0
              AND C.NAICSCode IS NOT NULL;
        INSERT INTO #ErrorLogs
        SELECT C.Id
             , 'Error'
             , 'Invalid NAICSCode for CustomerId {' + CONVERT(NVARCHAR(MAX), C.Id) + '}'
        FROM stgCustomer AS C
        WHERE C.IsMigrated = 0 
			  AND C.R_NAICSCodeId IS NULL 
			  AND C.NAICSCode IS NOT NULL
		INSERT INTO #ErrorLogs
		SELECT C.Id
			 , 'Error'
			 , ('Invalid SICCode for CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'}')
		FROM stgCustomer C
		WHERE C.IsMigrated = 0 
			  AND C.R_SICCodeId IS NULL 
			  AND C.SICCode IS NOT NULL
        UPDATE stgCustomer
          SET 
              R_CIPDocumentSourceId = CIP.Id
        FROM stgCustomer C
             INNER JOIN dbo.CIPDocumentSourceConfigs CIP ON CIP.Name = C.CIPDocumentSourceName
        WHERE C.IsMigrated = 0
              AND C.CIPDocumentSourceName IS NOT NULL;
        INSERT INTO #ErrorLogs
        SELECT C.Id
             , 'Error'
             , 'Invalid CIPDocumentSourceName for CustomerId {' + CONVERT(NVARCHAR(MAX), C.Id) + '}'
        FROM stgCustomer AS C
        WHERE C.IsMigrated = 0
              AND C.R_CIPDocumentSourceId IS NULL
              AND C.CIPDocumentSourceName IS NOT NULL;
        UPDATE stgCustomerAddress
          SET 
              R_HomeCountryId = Countries.Id
        FROM stgCustomerAddress CA
             INNER JOIN stgCustomer C ON C.Id = CA.CustomerId
             INNER JOIN dbo.Countries ON CA.HomeCountry = Countries.ShortName
                                         AND Countries.IsActive = 1
        WHERE C.IsMigrated = 0
              AND CA.HomeCountry IS NOT NULL;
        INSERT INTO #ErrorLogs
        SELECT C.Id
             , 'Error'
             , 'Invalid HomeCountry for Customer Address Id {' + CONVERT(NVARCHAR(MAX), CA.Id) + '} with CustomerId {' + CONVERT(NVARCHAR(MAX), C.Id) + '}'
        FROM stgCustomer AS C
             INNER JOIN stgCustomerAddress AS CA ON CA.CustomerId = C.Id
        WHERE C.IsMigrated = 0
              AND CA.HomeCountry IS NOT NULL
              AND CA.R_HomeCountryId IS NULL;
        UPDATE stgCustomerAddress
          SET 
              R_StateId = States.Id
        FROM stgCustomerAddress CA
             INNER JOIN stgCustomer C ON C.Id = CA.CustomerId
             INNER JOIN dbo.States ON CA.State = States.ShortName
                                      AND CA.R_CountryId = States.CountryId
                                      AND States.IsActive = 1
        WHERE C.IsMigrated = 0
              AND CA.State IS NOT NULL;
        INSERT INTO #ErrorLogs
        SELECT C.Id
             , 'Error'
             , 'Invalid State for Customer Address Id {' + CONVERT(NVARCHAR(MAX), CA.Id) + '} with CustomerId {' + CONVERT(NVARCHAR(MAX), C.Id) + '}'
        FROM stgCustomer AS C
             INNER JOIN stgCustomerAddress AS CA ON CA.CustomerId = C.Id
        WHERE C.IsMigrated = 0
              AND CA.State IS NOT NULL
              AND CA.R_StateId IS NULL;
        UPDATE stgCustomerAddress
          SET 
              R_HomeStateId = States.Id
        FROM stgCustomerAddress CA
             INNER JOIN stgCustomer C ON C.Id = CA.CustomerId
             INNER JOIN dbo.States ON CA.HomeState = States.ShortName
                                      AND CA.R_HomeCountryId = States.CountryId
                                      AND States.IsActive = 1
        WHERE C.IsMigrated = 0
              AND CA.HomeState IS NOT NULL;
        INSERT INTO #ErrorLogs
        SELECT C.Id
             , 'Error'
             , 'Invalid HomeState for Customer Address Id {' + CONVERT(NVARCHAR(MAX), CA.Id) + '} with CustomerId {' + CONVERT(NVARCHAR(MAX), C.Id) + '}'
        FROM stgCustomer AS C
             INNER JOIN stgCustomerAddress AS CA ON CA.CustomerId = C.Id
        WHERE C.IsMigrated = 0
              AND CA.HomeState IS NOT NULL
              AND CA.R_HomeStateId IS NULL;
        ----CustomerBankAccount
		
		INSERT INTO #ErrorLogs
		SELECT C.Id
				, 'Error'
				,('Automated Payment Method for CustomerBankAccount Id {'+CONVERT(NVARCHAR(MAX),CBA.Id)+'} with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'} must be Credit Card for Credit Card Account')
		FROM stgCustomer C
		JOIN stgCustomerBankAccount CBA ON CBA.CustomerId = C.Id
		WHERE C.IsMigrated = 0 AND  CBA.AutomatedPaymentMethod <> 'CreditCard' AND CBA.BankAccountCategoryName = 'Credit Card'

		INSERT INTO #ErrorLogs
		SELECT C.Id
				, 'Error'
				,('Account Category for CustomerBankAccount Id {'+CONVERT(NVARCHAR(MAX),CBA.Id)+'} with CustomerId {'+CONVERT(NVARCHAR(MAX),C.Id)+'} must be Credit Card for Credit Card Account')
		FROM stgCustomer C
		JOIN stgCustomerBankAccount CBA ON CBA.CustomerId = C.Id
		WHERE  C.IsMigrated = 0  AND  CBA.AutomatedPaymentMethod = 'CreditCard' AND CBA.BankAccountCategoryName <> 'Credit Card'

        UPDATE stgCustomerBankAccount
          SET 
              R_BankBranchId = BankBranches.Id
        FROM stgCustomerBankAccount CBA
             INNER JOIN stgCustomer C ON C.Id = CBA.CustomerId
             INNER JOIN BankBranches ON UPPER(CBA.BankBranch) = UPPER(BankBranches.Name)
        WHERE C.IsMigrated = 0
              AND CBA.BankBranch IS NOT NULL;
        INSERT INTO #ErrorLogs
        SELECT C.Id
             , 'Error'
             , 'Invalid BankBranch for CustomerBankAccount Id {' + CONVERT(NVARCHAR(MAX), CBA.Id) + '} with CustomerId {' + CONVERT(NVARCHAR(MAX), C.Id) + '}'
        FROM stgCustomer AS C
             INNER JOIN stgCustomerBankAccount AS CBA ON CBA.CustomerId = C.Id
        WHERE C.IsMigrated = 0
              AND CBA.BankBranch IS NOT NULL
              AND CBA.R_BankBranchId IS NULL;
        UPDATE stgCustomerBankAccount
          SET 
              R_CurrencyId = Currencies.Id
        FROM stgCustomerBankAccount CBA
             INNER JOIN stgCustomer C ON C.Id = CBA.CustomerId
             INNER JOIN CurrencyCodes ON CurrencyCodes.ISO = CBA.CurrencyCode
             INNER JOIN dbo.Currencies ON CurrencyCodes.Id = Currencies.CurrencyCodeId
        WHERE C.IsMigrated = 0
              AND CBA.CurrencyCode IS NOT NULL;
        INSERT INTO #ErrorLogs
        SELECT C.Id
             , 'Error'
             , 'Invalid Currency for CustomerBankAccount Id {' + CONVERT(NVARCHAR(MAX), CBA.Id) + '} with CustomerId {' + CONVERT(NVARCHAR(MAX), C.Id) + '}'
        FROM stgCustomer AS C
             INNER JOIN stgCustomerBankAccount AS CBA ON CBA.CustomerId = C.Id
        WHERE C.IsMigrated = 0
              AND CBA.CurrencyCode IS NOT NULL
              AND CBA.R_CurrencyId IS NULL;
        UPDATE stgCustomerACHAssignment
          SET 
              R_ReceivableTypeId = ReceivableTypes.Id
        FROM stgCustomerACHAssignment CAA
             INNER JOIN stgCustomer C ON C.Id = CAA.CustomerId
             INNER JOIN ReceivableTypes ON ReceivableTypes.Name = CAA.ReceivableTypeName
                                           AND ReceivableTypes.IsActive = 1
        WHERE C.IsMigrated = 0
              AND CAA.ReceivableTypeName IS NOT NULL;
        INSERT INTO #ErrorLogs
        SELECT C.Id
             , 'Error'
             , 'CustomerACHAssignment with Id {' + CONVERT(NVARCHAR(MAX), CAA.Id) + '} with CustomerId {' + CONVERT(NVARCHAR(MAX), C.Id) + '} contains invalid Receivable Type'
        FROM stgCustomer AS C
             INNER JOIN stgCustomerACHAssignment AS CAA ON CAA.CustomerId = C.Id
        WHERE C.IsMigrated = 0
              AND CAA.ReceivableTypeName IS NOT NULL
              AND CAA.R_ReceivableTypeId IS NULL;
        UPDATE stgCustomerBankAccount
          SET 
              R_BankAccountCategoryId = CBAC.Id
        FROM stgCustomerBankAccount CBA
             INNER JOIN stgCustomer C ON C.Id = CBA.CustomerId
             INNER JOIN BankAccountCategories CBAC ON CBA.BankAccountCategoryName = CBAC.AccountCategory
        WHERE C.IsMigrated = 0;
        INSERT INTO #ErrorLogs
        SELECT C.Id
             , 'Error'
             , 'CustomerBankAccountId {' + CONVERT(NVARCHAR(MAX), CBA.Id) + '} associated with  CustomerId {' + CONVERT(NVARCHAR(MAX), C.Id) + '} cannot be an ACH or Primary ACH account and cannot have Account Category'
        FROM stgCustomer AS C
             JOIN stgCustomerBankAccount AS CBA ON CBA.CustomerId = C.Id
        WHERE CBA.IBAN IS NOT NULL
              AND (CBA.AutomatedPaymentMethod = 'ACHOrPAP'
                   OR CBA.IsPrimaryACH = 1
                   OR CBA.R_BankAccountCategoryId IS NOT NULL);
        INSERT INTO #ErrorLogs
        SELECT C.Id
             , 'Error'
             , 'Bank Account with Id {' + CONVERT(NVARCHAR(MAX), CBA.Id) + '} with CustomerId {' + CONVERT(NVARCHAR(MAX), C.Id) + '} Must have a value for Account Category since the account is ACH Account'
        FROM stgCustomer AS C
             INNER JOIN stgCustomerBankAccount AS CBA ON CBA.CustomerId = C.Id
        WHERE C.IsMigrated = 0
              AND CBA.R_BankAccountCategoryId IS NULL
              AND (CBA.AutomatedPaymentMethod = 'ACHOrPAP'
                   OR CBA.IsPrimaryACH = 1);
        INSERT INTO #ErrorLogs
        SELECT C.Id
             , 'Error'
             , 'Bank Account with Id {' + CONVERT(NVARCHAR(MAX), CBA.Id) + '} with CustomerId {' + CONVERT(NVARCHAR(MAX), C.Id) + '} contains invalid Bank Account Category'
        FROM stgCustomer AS C
             INNER JOIN stgCustomerBankAccount AS CBA ON CBA.CustomerId = C.Id
        WHERE C.IsMigrated = 0
              AND CBA.BankAccountCategoryName IS NOT NULL
              AND CBA.R_BankAccountCategoryId IS NULL;
        INSERT INTO #ErrorLogs
        SELECT C.Id
             , 'Error'
             , 'PostalCode Is Mandatory for Customer Address Id {' + CONVERT(NVARCHAR(MAX), CA.Id) + '} with CustomerId {' + CONVERT(NVARCHAR(MAX), C.Id) + '}'
        FROM stgCustomer AS C
             INNER JOIN stgCustomerAddress AS CA ON CA.CustomerId = C.Id
             INNER JOIN Countries AS Country ON CA.R_CountryId = Country.Id
        WHERE C.IsMigrated = 0
              AND CA.PostalCode IS NULL
              AND Country.IsPostalCodeMandatory = 1;
        INSERT INTO #ErrorLogs
        SELECT C.Id
             , 'Error'
             , 'HomePostalCode Is Mandatory Customer Address Id {' + CONVERT(NVARCHAR(MAX), CA.Id) + '} with CustomerId {' + CONVERT(NVARCHAR(MAX), C.Id) + '}'
        FROM stgCustomer AS C
             INNER JOIN stgCustomerAddress AS CA ON CA.CustomerId = C.Id
             INNER JOIN Countries AS Country ON CA.R_HomeCountryId = Country.Id
        WHERE C.IsMigrated = 0
              AND CA.HomePostalCode IS NULL
              AND Country.IsPostalCodeMandatory = 1;
        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               C.Id AS                                                                                                                                                                                                                                     CustomerId
             , 'Error'
             , 'PostalCode : {' + ISNULL(CA.PostalCode, 'NULL') + '} is not in correct format, please enter PostalCode with the regex format : {' + dbo.Countries.PostalCodeMask + '} with Customer Id {' + CONVERT(NVARCHAR(MAX), CA.CustomerId) + '}' AS Message
        FROM stgCustomer AS C
             INNER JOIN stgCustomerAddress AS CA ON C.id = CA.CustomerId
             INNER JOIN dbo.Countries ON dbo.Countries.Id = CA.R_CountryId
        WHERE C.IsMigrated = 0
              AND dbo.Countries.PostalCodeMask IS NOT NULL
              AND CA.R_CountryId IS NOT NULL
              AND CA.PostalCode IS NOT NULL
              AND dbo.RegexStringMatch(CA.PostalCode, dbo.Countries.PostalCodeMask) = 0;
        INSERT INTO #ErrorLogs
        SELECT DISTINCT 
               C.Id AS                                                                                                                                                                                                                                                  CustomerId
             , 'Error'
             , 'HomePostalCode : {' + ISNULL(CA.HomePostalCode, 'NULL') + '} is not in correct format, please enter HomePostalCode with the regex format : {' + dbo.Countries.PostalCodeMask + '} with Customer Id  {' + CONVERT(NVARCHAR(MAX), CA.CustomerId) + '}' AS Message
        FROM stgCustomer AS C
             INNER JOIN stgCustomerAddress AS CA ON C.id = CA.CustomerId
             INNER JOIN dbo.Countries ON dbo.Countries.Id = CA.R_HomeCountryId
        WHERE C.IsMigrated = 0
              AND dbo.Countries.PostalCodeMask IS NOT NULL
              AND CA.R_HomeStateId IS NOT NULL
              AND CA.HomePostalCode IS NOT NULL
              AND dbo.RegexStringMatch(CA.HomePostalCode, dbo.Countries.PostalCodeMask) = 0;
        INSERT INTO #ErrorLogs
        SELECT C.Id
             , 'Error'
             , CONCAT('At least one contact having contact type = Owner should be entered when Sole Proprietor is selected for Customer with CustomerId {', CONVERT(NVARCHAR(MAX), C.Id), '}')
        FROM stgCustomer AS C
        WHERE C.Id IN
        (
            SELECT DISTINCT 
                   C.Id
            FROM stgCustomer AS C
                 LEFT JOIN stgCustomerContact AS CC ON C.Id = CC.CustomerId
                 LEFT JOIN stgCustomerContactType AS CCT ON CCT.CustomerContactId = CC.Id
                 LEFT JOIN stgCustomerThirdPartyRelationship AS CTR ON C.Id = CTR.CustomerId
            WHERE C.IsMigrated = 0
                  AND C.IsSoleProprietor = 1
                  AND CTR.Id IS NULL
            GROUP BY C.Id
                   , CCT.ContactType
            HAVING CCT.ContactType != 'Owner'
        );
        INSERT INTO #ErrorLogs
        SELECT customerACHAssignment.CustomerId
             , 'Error'
             , ('Following CustomerACHAssignment with Id ' + CONVERT(NVARCHAR(10), customerACHAssignment.Id) + ' must have Start Date with Customer Id {' + CONVERT(NVARCHAR(MAX), customerACHAssignment.CustomerId) + '}')
        FROM stgCustomerACHAssignment customerACHAssignment
             INNER JOIN stgCustomer C ON C.Id = customerACHAssignment.CustomerId
        WHERE C.IsMigrated = 0
              AND customerACHAssignment.StartDate IS NULL;
        INSERT INTO #ErrorLogs
        SELECT customerACHAssignment.CustomerId
             , 'Error'
             , ('End Date must be on or after Begin Date for following CustomerACHAssignment with Id {' + CONVERT(NVARCHAR(MAX), customerACHAssignment.Id) + '}') AS Message
        FROM stgCustomerACHAssignment customerACHAssignment
             INNER JOIN stgCustomer C ON C.Id = customerACHAssignment.CustomerId
        WHERE C.IsMigrated = 0
              AND customerACHAssignment.StartDate IS NOT NULL
              AND customerACHAssignment.EndDate IS NOT NULL
              AND customerACHAssignment.EndDate < customerACHAssignment.StartDate;
        INSERT INTO #ErrorLogs
        SELECT stgCustomerACHAssignment.CustomerId
             , 'Error'
             , ('Following ACH Assignment(s) : ' + CONVERT(NVARCHAR(10), stgCustomerACHAssignment.Id) + ' must have End Date with Customer Id {' + CONVERT(NVARCHAR(MAX), stgCustomerACHAssignment.CustomerId) + '}')
        FROM stgCustomerACHAssignment
        WHERE Id IN
        (
            SELECT Id
            FROM stgCustomerACHAssignment
                 INNER JOIN
            (
                SELECT caa.ReceivableTypeName
                     , caa.CustomerId
                FROM stgCustomerACHAssignment caa
                     JOIN stgcustomer c ON c.id = caa.CustomerId
                WHERE c.IsMigrated = 0
                GROUP BY caa.ReceivableTypeName
                       , caa.CustomerId
                HAVING COUNT(caa.ReceivableTypeName) > 1
            ) AS Temp ON Temp.ReceivableTypeName = stgCustomerACHAssignment.ReceivableTypeName
                         AND Temp.CustomerId = stgCustomerACHAssignment.CustomerId
            ORDER BY stgCustomerACHAssignment.StartDate DESC
                   , stgCustomerACHAssignment.Id DESC
            OFFSET 1 ROWS
        )
            AND EndDate IS NULL;

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


        SET @FailedRecords =
        (
            SELECT ISNULL(COUNT(DISTINCT StagingRootEntityId), 0)
            FROM #ErrorLogs
        );
        MERGE stgProcessingLog AS ProcessingLog
        USING
        (
            SELECT Id
            FROM stgCustomer
            WHERE IsMigrated = 0
                  AND Id NOT IN
            (
                SELECT StagingRootEntityId
                FROM #ErrorLogs
            )
        ) AS ProcessedCustomers
        ON(ProcessingLog.StagingRootEntityId = ProcessedCustomers.Id
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
        (ProcessedCustomers.Id
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
        ) AS ErrorCustomers
        ON(ProcessingLog.StagingRootEntityId = ErrorCustomers.StagingRootEntityId
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
        (ErrorCustomers.StagingRootEntityId
       , @UserId
       , @CreatedTime
       , @ModuleIterationStatusId
        )
        OUTPUT Inserted.Id
             , ErrorCustomers.StagingRootEntityId
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
             JOIN #FailedProcessingLogs ON #ErrorLogs.StagingRootEntityId = #FailedProcessingLogs.CustomerId;
        DROP TABLE #ErrorLogs;
        DROP TABLE #FailedProcessingLogs;
        DROP TABLE #CreatedProcessingLogs;
    END;

GO

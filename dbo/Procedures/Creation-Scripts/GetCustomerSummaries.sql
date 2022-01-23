SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetCustomerSummaries](
@CustomerNumber          NVARCHAR(80) =NULL,
@CustomerName            NVARCHAR(500)=NULL,
@Last4DigitTaxIdSSNNationalID   NVARCHAR(24) =NULL,
@AccountNumber           NVARCHAR(80) =NULL,
@ContactNumber           NVARCHAR(40) =NULL,
@ContactFirstName        NVARCHAR(80) =NULL,
@ContactLastName         NVARCHAR(80) =NULL,
@DoingBusinessAs         NVARCHAR(200)=NULL,
@CustomerId              BIGINT       =NULL,
@ContractId              BIGINT       =NULL,
@IsContractSummary       BIT          =0,
@IsInvoiceSummary        BIT          =0,
@InvoiceId               BIGINT       =NULL,
@ContractAlias           NVARCHAR(80) =NULL,
@ContractSequenceNumber  NVARCHAR(80) =NULL,
@InvoiceNumber           NVARCHAR(80) =NULL,
@VendorName              NVARCHAR(80) =NULL,
@VendorNumber            NVARCHAR(80) =NULL,
@VendorInvoiceNumber     NVARCHAR(80) =NULL,
@VendorOrderNumber       NVARCHAR(80) =NULL,
@CustomerAssetNumber     NVARCHAR(80) =NULL,
@GuarantorName           NVARCHAR(500)=NULL,
@GuarantorNumber         NVARCHAR(80) =NULL,
@FunderAccountNumber     NVARCHAR(80) =NULL,
@FunderName              NVARCHAR(500)=NULL,
@AssetSerialNumber       NVARCHAR(200)=NULL,
@CollateralCode          NVARCHAR(80) =NULL,
@BillToId                NVARCHAR(40) =NULL,
@ExternalReferenceNumber NVARCHAR(80) =NULL,
@PreviousScheduleNumber  NVARCHAR(80) =NULL,
@AccessibleLegalEntities NVARCHAR(MAX),
@UserId                  BIGINT,
@CurrentPortFolioId BIGINT)
AS
SET NOCOUNT ON;
BEGIN
SELECT * INTO #AccessibleLegalEntityIds FROM ConvertCSVToBigIntTable(@AccessibleLegalEntities, ',')
DECLARE
@Query NVARCHAR(MAX);
DECLARE
@Contract NVARCHAR(MAX);
DECLARE @DoingBusinessAsFilter NVARCHAR(MAX) = ''

DECLARE
@LAssetQuery NVARCHAR(MAX);
DECLARE
@LnAssetQuery NVARCHAR(MAX);
DECLARE
@where NVARCHAR(MAX);
SELECT CAH.ContractId,
CAH.CustomerId,
Parties.PartyNumber,
Parties.PartyName,
A.NewCustomerId
INTO #AssumptionDetails
FROM ContractAssumptionHistories CAH
INNER JOIN Assumptions A ON A.Id = CAH.AssumptionId
INNER JOIN Parties ON Parties.Id=CAH.CustomerId
AND (Parties.PartyNumber LIKE REPLACE( REPLACE( @CustomerNumber, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )
OR Parties.PartyName LIKE REPLACE( REPLACE( @CustomerName, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' ))
INNER JOIN Contracts C ON A.ContractID = C.ID
WHERE (@ContractSequenceNumber IS NULL OR C.SequenceNumber LIKE REPLACE( REPLACE( @ContractSequenceNumber, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' ))

SET @Query=N'
CUSTOMERDOINGBUSINESSASFILTER

SELECT DISTINCT
p.PartyNumber CustomerNumber
,p.PartyName CustomerName
,p.LastFourDigitUniqueIdentificationNumber UniqueIdentificationNumber
,DoingBusinessName AS DoingBusinessAs
ReplaceFilterCustomerNumber
ReplaceFilterCustomerName
ReplaceContactNumber
ReplaceContractSequenceNumber
ReplaceSequenceNumberFromInvoice
ReplaceInvoiceNumber
FROM
Customers Cus
join Parties P
on Cus.Id = P.Id
DBA_JOIN
BANK_ACC_DETAIL
JOIN_INVOICE
JOIN_GUARONTOR
JOIN_FUNDER
JOIN_CONTRACT
JOIN_CONTACT
JOIN_THIRD_PARTY_CONTRACT
where 1=1 WHERECLAUSE';
IF @AccountNumber IS NOT NULL
BEGIN
SET @Query=REPLACE( @Query, 'BANK_ACC_DETAIL', ' join PartyBankAccounts PBA
on P.Id = PBA.PartyId
join BankAccounts BA
on PBA.BankAccountId = BA.Id
AND BA.LastFourDigitAccountNumber LIKE '''+REPLACE( REPLACE( @AccountNumber, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+'''' );
END;
ELSE
BEGIN
SET @Query=REPLACE( @Query, 'BANK_ACC_DETAIL', ' ' );
END;
IF @ContactNumber IS NOT NULL
OR @ContactFirstName IS NOT NULL
OR @ContactLastName IS NOT NULL
BEGIN
SET @Query=REPLACE( @Query, 'JOIN_CONTACT', ' join PartyContacts PC
on p.Id = PC.PartyId
AND PC.IsActive = 1
PHONENUMBER
JOIN_CONTRACTCONTACT
FIRSTNAME
LASTNAME' );
IF @IsContractSummary =1
BEGIN
SET @Query=REPLACE( @Query, 'JOIN_CONTRACTCONTACT', ' JOIN ContractContacts CC ON PC.Id = CC.PartyContactId AND CC.ContractId =Contract.ContractId AND CC.IsActive = 1' );
END;
ELSE
BEGIN
SET @Query=REPLACE( @Query, 'JOIN_CONTRACTCONTACT', ' ' );
END;
IF @ContactNumber IS NOT NULL
BEGIN
SET @Query=REPLACE( @Query, 'PHONENUMBER', ' AND (PC.PhoneNumber1 LIKE  '''+REPLACE( REPLACE( @ContactNumber, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+''' OR PC.PhoneNumber2 LIKE  '''+REPLACE( REPLACE( @ContactNumber, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+''')' );
END;
ELSE
BEGIN
SET @Query=REPLACE( @Query, 'PHONENUMBER', ' ' );
END;
IF @ContactFirstName IS NOT NULL
BEGIN
SET @Query=REPLACE( @Query, 'FIRSTNAME', ' AND PC.FirstName LIKE  '''+REPLACE( REPLACE( @ContactFirstName, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+'''' );
END;
ELSE
BEGIN
SET @Query=REPLACE( @Query, 'FIRSTNAME', ' ' );
END;
IF @ContactLastName IS NOT NULL
BEGIN
SET @Query=REPLACE( @Query, 'LASTNAME', ' AND PC.LastName LIKE  '''+REPLACE( REPLACE( @ContactLastName, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+'''' );
END;
ELSE
BEGIN
SET @Query=REPLACE( @Query, 'LASTNAME', ' ' );
END;
SET @Query=REPLACE( @Query, 'ReplaceContactNumber', ' ,PC.MobilePhoneNumber ContactNumber ' );
END;
ELSE
BEGIN
SET @Query=REPLACE( @Query, 'JOIN_CONTACT', ' ' );
SET @Query=REPLACE( @Query, 'ReplaceContactNumber', ' ' );
END;
SET @Contract=' JOIN (( SELECT LF.CustomerId ,
SequenceNumber ,
LeaseContract.Id ContractId
AssetIdSelection
FROM LeaseFinances LF
INNER JOIN Legalentities
ON LF.LegalEntityId  = Legalentities.Id
INNER JOIN #AccessibleLegalEntityIds
ON Legalentities.Id = #AccessibleLegalEntityIds.Id
INNER JOIN Contracts LeaseContract
ON LF.ContractId = LeaseContract.Id
AND LF.IsCurrent=1
AND (LeaseContract.IsConfidential = 0  OR
LeaseContract.ID IN	(SELECT C.[Id]
FROM  [dbo].[Contracts] AS C
INNER JOIN [dbo].[EmployeesAssignedToContracts] AS EAC ON C.[Id] = EAC.[ContractId]
INNER JOIN [dbo].[EmployeesAssignedToParties] AS EACu ON EAC.[EmployeeAssignedToPartyId] = EACu.[Id]
WHERE EACu.[EmployeeId] = '''+REPLACE( @UserId, CHAR(39), CHAR(39)+CHAR(39) )+''' AND C.[IsConfidential] = 1) )
LeaseAssetFilter
LeaseContractFilter
)
UNION (SELECT LF.CustomerId ,
SequenceNumber,
LoanContract.Id ContractId
AssetIdSelection
From LoanFinances LF
INNER JOIN Legalentities
ON LF.LegalEntityId  = Legalentities.Id
INNER JOIN #AccessibleLegalEntityIds
ON Legalentities.Id = #AccessibleLegalEntityIds.Id
INNER JOIN Contracts LoanContract
ON LF.ContractId = LoanContract.Id
AND LF.IsCurrent=1
AND (LoanContract.IsConfidential = 0 OR
LoanContract.ID IN	(SELECT C.[Id]
FROM  [dbo].[Contracts] AS C
INNER JOIN [dbo].[EmployeesAssignedToContracts] AS EAC ON C.[Id] = EAC.[ContractId]
INNER JOIN [dbo].[EmployeesAssignedToParties] AS EACu ON EAC.[EmployeeAssignedToPartyId] = EACu.[Id]
WHERE EACu.[EmployeeId] = '''+REPLACE( @UserId, CHAR(39), CHAR(39)+CHAR(39) )+'''  AND C.[IsConfidential] = 1))
LoanAssetFilter
LoanContractFilter
))
Contract
ON Cus.Id = Contract.CustomerId
InvoiceNumberFilter
ContractSequenceNumberFilter
AssetIdFilter
Contract_Guarantor
Contract_Funder
LEFT JOIN #AssumptionDetails AD ON Contract.ContractId = Ad.ContractId';
IF @ContractSequenceNumber IS NOT NULL
AND @ContractAlias IS NULL
BEGIN
SET @Contract=REPLACE( @Contract, 'LeaseAssetFilter', ' AND LeaseContract.SequenceNumber LIKE '''+REPLACE( REPLACE( @ContractSequenceNumber, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+''' LeaseAssetFilter ' );
SET @Contract=REPLACE( @Contract, 'LoanAssetFilter', ' AND LoanContract.SequenceNumber LIKE '''+REPLACE( REPLACE( @ContractSequenceNumber, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+''' LoanAssetFilter ' );
END;
ELSE
IF @ContractSequenceNumber IS NULL
AND @ContractAlias IS NOT NULL
BEGIN
SET @Contract=REPLACE( @Contract, 'LeaseAssetFilter', ' AND LeaseContract.Alias LIKE '''+REPLACE( REPLACE( @ContractAlias, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+''' LeaseAssetFilter ' );
SET @Contract=REPLACE( @Contract, 'LoanAssetFilter', ' AND LoanContract.Alias LIKE '''+REPLACE( REPLACE( @ContractAlias, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+''' LoanAssetFilter ' );
END;
ELSE
IF @ContractSequenceNumber IS NOT NULL
AND @ContractAlias IS NOT NULL
BEGIN
SET @Contract=REPLACE( @Contract, 'LeaseAssetFilter', ' AND LeaseContract.Alias LIKE '''+REPLACE( REPLACE( @ContractAlias, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+''+''' AND LeaseContract.SequenceNumber LIKE '''+REPLACE( REPLACE( @ContractSequenceNumber, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+''' LeaseAssetFilter ' );
SET @Contract=REPLACE( @Contract, 'LoanAssetFilter', ' AND LoanContract.Alias LIKE '''+REPLACE( REPLACE( @ContractAlias, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+''+''' AND LoanContract.SequenceNumber LIKE '''+REPLACE( REPLACE( @ContractSequenceNumber, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+''' LoanAssetFilter ' );
END;
ELSE
IF @ContractId IS NOT NULL
BEGIN
SET @Contract=REPLACE( @Contract, 'LeaseAssetFilter', '  AND LeaseContract.Id = '''+REPLACE( REPLACE( @ContractId, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+''' LeaseAssetFilter ' );
SET @Contract=REPLACE( @Contract, 'LoanAssetFilter', '  AND LoanContract.Id = '''+REPLACE( REPLACE( @ContractId, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+''' LoanAssetFilter ' );
END;;;
IF @BillToId IS NOT NULL
BEGIN
SET @Contract=REPLACE( @Contract, 'LeaseContractFilter', 'JOIN BillToes ON BillToes.Id = LeaseContract.BillToId AND BillToes.Name LIKE '''+REPLACE( REPLACE( @BillToId, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+''' LeaseContractFilter' );
SET @Contract=REPLACE( @Contract, 'LoanContractFilter', 'JOIN BillToes ON BillToes.Id = LoanContract.BillToId AND BillToes.Name LIKE '''+REPLACE( REPLACE( @BillToId, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+''' LoanContractFilter' );
END;
IF @ExternalReferenceNumber IS NOT NULL
BEGIN
SET @Contract=REPLACE( @Contract, 'LeaseContractFilter', ' AND LeaseContract.ExternalReferenceNumber LIKE '''+REPLACE( REPLACE( @ExternalReferenceNumber, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+''' LeaseContractFilter' );
SET @Contract=REPLACE( @Contract, 'LoanContractFilter', ' AND LoanContract.ExternalReferenceNumber LIKE '''+REPLACE( REPLACE( @ExternalReferenceNumber, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+''' LoanContractFilter' );
END;
IF @PreviousScheduleNumber IS NOT NULL
BEGIN
SET @Contract=REPLACE( @Contract, 'LeaseContractFilter', ' AND LeaseContract.PreviousScheduleNumber LIKE '''+REPLACE( REPLACE( @PreviousScheduleNumber, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+'''' );
SET @Contract=REPLACE( @Contract, 'LoanContractFilter', ' AND LoanContract.PreviousScheduleNumber LIKE '''+REPLACE( REPLACE( @PreviousScheduleNumber, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+'''' );
END;
ELSE
BEGIN
SET @Contract=REPLACE( @Contract, 'LeaseContractFilter', ' ' );
SET @Contract=REPLACE( @Contract, 'LoanContractFilter', ' ' );
END;
IF @CustomerAssetNumber IS NOT NULL
OR @VendorOrderNumber IS NOT NULL
OR @AssetSerialNumber IS NOT NULL
OR @CollateralCode IS NOT NULL
BEGIN
	IF @AssetSerialNumber IS NOT NULL
	BEGIN
		SET @LAssetQuery='INNER JOIN LeaseAssets on LeaseAssets.LeaseFinanceId = LF.id
		INNER JOIN Assets on LeaseAssets.AssetId = assets.id AND LeaseAssets.IsActive=1 AND LF.IsCurrent=1
		INNER JOIN (
			SELECT DISTINCT AssetId FROM AssetSerialNumbers WHERE IsActive=1
			_SerialNumberFilter
			)ASN ON Assets.Id =  ASN.AssetId  
		_Filter
		_CATALOGFilter';
		SET @LnAssetQuery='inner join CollateralAssets on CollateralAssets.LoanFinanceId = LF.id
		inner join Assets on CollateralAssets.AssetId = Assets.id AND CollateralAssets.IsActive = 1 AND LF.IsCurrent = 1 
		INNER JOIN (
			SELECT DISTINCT AssetId FROM AssetSerialNumbers WHERE IsActive=1
			_SerialNumberFilter
			)ASN ON Assets.Id =  ASN.AssetId  
		_Filter
		_CATALOGFilter';
	END
	ELSE
	BEGIN
		SET @LAssetQuery='INNER JOIN LeaseAssets on LeaseAssets.LeaseFinanceId = LF.id
		INNER JOIN Assets on LeaseAssets.AssetId = assets.id AND LeaseAssets.IsActive=1 AND LF.IsCurrent=1  _Filter
		_CATALOGFilter';
		SET @LnAssetQuery='inner join CollateralAssets on CollateralAssets.LoanFinanceId = LF.id
		inner join Assets on CollateralAssets.AssetId = Assets.id AND CollateralAssets.IsActive = 1 AND LF.IsCurrent = 1  _Filter
		_CATALOGFilter';
	END
IF @CustomerAssetNumber IS NOT NULL
AND @VendorOrderNumber IS NOT NULL
BEGIN
SET @LAssetQuery=REPLACE( @LAssetQuery, '_Filter', 'AND Assets.VendorOrderNumber Like '''+REPLACE( REPLACE( @VendorOrderNumber, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+''' AND Assets.CustomerAssetNumber Like '''+REPLACE( REPLACE( @CustomerAssetNumber, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+'''' );
SET @LnAssetQuery=REPLACE( @LnAssetQuery, '_Filter', 'AND Assets.VendorOrderNumber Like '''+REPLACE( REPLACE( @VendorOrderNumber, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+''' AND Assets.CustomerAssetNumber Like '''+REPLACE( REPLACE( @CustomerAssetNumber, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+'''' );
END;
ELSE
IF @CustomerAssetNumber IS NOT NULL
AND @VendorOrderNumber IS NULL
BEGIN
SET @LAssetQuery=REPLACE( @LAssetQuery, '_Filter', ' AND Assets.CustomerAssetNumber Like '''+REPLACE( REPLACE( @CustomerAssetNumber, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+'''' );
SET @LnAssetQuery=REPLACE( @LnAssetQuery, '_Filter', ' AND Assets.CustomerAssetNumber Like '''+REPLACE( REPLACE( @CustomerAssetNumber, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+'''' );
END;
ELSE
IF @CustomerAssetNumber IS NULL
AND @VendorOrderNumber IS NOT NULL
BEGIN
SET @LAssetQuery=REPLACE( @LAssetQuery, '_Filter', 'AND Assets.VendorOrderNumber Like '''+REPLACE( REPLACE( @VendorOrderNumber, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+'''' );
SET @LnAssetQuery=REPLACE( @LnAssetQuery, '_Filter', 'AND Assets.VendorOrderNumber Like '''+REPLACE( REPLACE( @VendorOrderNumber, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+'''' );
PRINT @LAssetQuery;
END;
ELSE --if @CustomerAssetNumber is null and @VendorOrderNumber is null
BEGIN
SET @LAssetQuery=REPLACE( @LAssetQuery, '_Filter', ' ' );
SET @LnAssetQuery=REPLACE( @LnAssetQuery, '_Filter', ' ' );
END;;;
IF @AssetSerialNumber IS NOT NULL
BEGIN
SET @LAssetQuery=REPLACE( @LAssetQuery, '_SerialNumberFilter', 'AND SerialNumber LIKE '''+REPLACE( REPLACE( @AssetSerialNumber, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+'''' );
SET @LnAssetQuery=REPLACE( @LnAssetQuery, '_SerialNumberFilter', 'AND SerialNumber LIKE '''+REPLACE( REPLACE( @AssetSerialNumber, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+'''' );
END;
ELSE
BEGIN
SET @LAssetQuery=REPLACE( @LAssetQuery, '_SerialNumberFilter', ' ' );
SET @LnAssetQuery=REPLACE( @LnAssetQuery, '_SerialNumberFilter', ' ' );
END;
IF @CollateralCode IS NOT NULL
BEGIN
SET @LAssetQuery=REPLACE( @LAssetQuery, '_CATALOGFilter', 'INNER JOIN AssetCatalogs ON AssetCatalogs.Id = assets.AssetCatalogId AND AssetCatalogs.CollateralCode LIKE '''+REPLACE( REPLACE( @CollateralCode, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+'''' );
SET @LnAssetQuery=REPLACE( @LnAssetQuery, '_CATALOGFilter', 'INNER JOIN AssetCatalogs ON AssetCatalogs.Id = assets.AssetCatalogId AND AssetCatalogs.CollateralCode LIKE '''+REPLACE( REPLACE( @CollateralCode, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+'''' );
END;
ELSE
BEGIN
SET @LAssetQuery=REPLACE( @LAssetQuery, '_CATALOGFilter', ' ' );
SET @LnAssetQuery=REPLACE( @LnAssetQuery, '_CATALOGFilter', ' ' );
END;
END;
IF @CustomerAssetNumber IS NOT NULL
OR @VendorOrderNumber IS NOT NULL
OR @AssetSerialNumber IS NOT NULL
OR @CollateralCode IS NOT NULL
BEGIN
SET @Contract=REPLACE( @Contract, 'LeaseAssetFilter', @LAssetQuery );
SET @Contract=REPLACE( @Contract, 'LoanAssetFilter', @LnAssetQuery );
END;
ELSE
BEGIN
SET @Contract=REPLACE( @Contract, 'LeaseAssetFilter', '' );
SET @Contract=REPLACE( @Contract, 'LoanAssetFilter', '' );
END;
IF @GuarantorName IS NOT NULL
OR @GuarantorNumber IS NOT NULL
BEGIN
declare @includeSequenceNumber NVARCHAR(MAX);
SET @Query=REPLACE( @Query, 'JOIN_GUARONTOR', 'JOIN
(SELECT ThirdPartyRelationship_Guarantor.customerId,Contract_Guarantor.SequenceNumber FROM CustomerThirdPartyRelationships ThirdPartyRelationship_Guarantor
JOIN Parties Party_Guarantor on ThirdPartyRelationship_Guarantor.ThirdPartyId=Party_Guarantor.Id AND ThirdPartyRelationship_Guarantor.IsActive=1
LEFT JOIN contractThirdPartyRelationships contractThirdPartyRelationship_Guarantor
ON contractThirdPartyRelationship_Guarantor.ThirdPartyRelationshipId = ThirdPartyRelationship_Guarantor.Id
AND contractThirdPartyRelationship_Guarantor.IsActive = 1
LEFT JOIN Contracts Contract_Guarantor ON contractThirdPartyRelationship_Guarantor.CONtractId= Contract_Guarantor.Id
WHERE (RelationshipType = ''CorporateGuarantor'' OR RelationshipType = ''PersonalGuarantor'')
GUARANTOR_NAME
GUARANTOR_NUMBER
)
Guarantor
on Cus.Id=Guarantor.CustomerID' );
If EXISTS(
SELECT Party_Guarantor.Id
FROM CustomerThirdPartyRelationships ThirdPartyRelationship_Guarantor
JOIN Parties Party_Guarantor
ON ThirdPartyRelationship_Guarantor.ThirdPartyId=Party_Guarantor.Id
AND ThirdPartyRelationship_Guarantor.IsActive=1
INNER JOIN contractThirdPartyRelationships contractThirdPartyRelationship_Guarantor
ON contractThirdPartyRelationship_Guarantor.ThirdPartyRelationshipId = ThirdPartyRelationship_Guarantor.Id
AND contractThirdPartyRelationship_Guarantor.IsActive = 1
INNER JOIN Contracts Contract_Guarantor ON contractThirdPartyRelationship_Guarantor.CONtractId= Contract_Guarantor.Id
WHERE
(RelationshipType = 'CorporateGuarantor' OR RelationshipType = 'PersonalGuarantor')
AND (@GuarantorName IS NULL OR Party_Guarantor.PartyName = REPLACE(REPLACE( @GuarantorName, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' ))
AND (@GuarantorNumber IS NULL OR Party_Guarantor.PartyNumber = REPLACE(REPLACE( @GuarantorNumber, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' ))
)
BEGIN
SET @IsContractSummary =1
END
IF @GuarantorName IS NOT NULL
BEGIN
SET @Query=REPLACE( @Query, 'GUARANTOR_NAME', 'AND Party_Guarantor.PartyName LIKE '''+REPLACE( REPLACE( @GuarantorName, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+'''' );
SET @Contract=REPLACE( @Contract, 'Contract_Guarantor', 'AND Contract.CustomerId = Guarantor.CustomerId  AND Contract.SequenceNumber = Guarantor.SequenceNumber' );
END;
ELSE
BEGIN
SET @Query=REPLACE( @Query, 'GUARANTOR_NAME', ' ' );
END;
IF @GuarantorNumber IS NOT NULL
BEGIN
SET @Query=REPLACE( @Query, 'GUARANTOR_NUMBER', 'AND Party_Guarantor.PartyNumber LIKE '''+REPLACE( REPLACE( @GuarantorNumber, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+'''' );
SET @Contract=REPLACE( @Contract, 'Contract_Guarantor', 'AND Contract.CustomerId = Guarantor.CustomerId  AND Contract.SequenceNumber = Guarantor.SequenceNumber' );
END;
ELSE
BEGIN
SET @Query=REPLACE( @Query, 'GUARANTOR_NUMBER', ' ' );
END;
END;
ELSE
BEGIN
SET @Query=REPLACE( @Query, 'JOIN_GUARONTOR', ' ' );
SET @Contract=REPLACE( @Contract, 'Contract_Guarantor', '' );
END;
IF @FunderName IS NOT NULL
OR @FunderAccountNumber IS NOT NULL
BEGIN
SET @Query=REPLACE( @Query, 'JOIN_FUNDER', 'JOIN(
SELECT Contracts.SequenceNumber ,Customers.Id CustomerId
FROM
ReceivableForTransfers
INNER JOIN ReceivableForTransferFundingSources
ON (ReceivableForTransferId = ReceivableForTransfers.Id
AND ReceivableForTransfers.ApprovalStatus = ''Approved'')
INNER JOIN Contracts
ON ContractId =Contracts.Id
INNER JOIN Parties Party_Funder
ON Party_Funder.Id = ReceivableForTransferFundingSources.FunderId
LEFT JOIN LeaseFinances
ON Contracts.Id = LeaseFinances.ContractId
LEFT JOIN LoanFinances
ON Contracts.Id = LoanFinances.ContractId
INNER JOIN Customers
ON (LeaseFinances.Id IS NULL OR LeaseFinances.CustomerId = Customers.Id)
AND (LoanFinances.Id IS NULL OR LoanFinances.CustomerId = Customers.Id)
WHERE 1=1
FUNDER_NAME
FUNDER_NUMBER
GROUP BY
Contracts.SequenceNumber,
Customers.Id)
Funder
ON Cus.Id=Funder.CustomerID' );
IF @FunderName IS NOT NULL
BEGIN
SET @Query=REPLACE( @Query, 'FUNDER_NAME', 'AND Party_Funder.PartyName LIKE '''+REPLACE( REPLACE( @FunderName, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+'''' );
SET @Contract=REPLACE( @Contract, 'Contract_Funder', 'AND Contract.CustomerId = Funder.CustomerId AND Contract.SequenceNumber = Funder.SequenceNumber' );
END;
ELSE
BEGIN
SET @Query=REPLACE( @Query, 'FUNDER_NAME', ' ' );
END;
IF @FunderAccountNumber IS NOT NULL
BEGIN
SET @Query=REPLACE( @Query, 'FUNDER_NUMBER', 'AND Party_Funder.PartyNumber LIKE '''+REPLACE( REPLACE( @FunderAccountNumber, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+'''' );
SET @Contract=REPLACE( @Contract, 'Contract_Funder', 'AND Contract.CustomerId = Funder.CustomerId AND Contract.SequenceNumber = Funder.SequenceNumber' );
END;
ELSE
BEGIN
SET @Query=REPLACE( @Query, 'FUNDER_NUMBER', ' ' );
END;
END;
ELSE
BEGIN
SET @Query=REPLACE( @Query, 'JOIN_FUNDER', ' ' );
SET @Contract=REPLACE( @Contract, 'Contract_Funder', '' );
END;

IF @ContractSequenceNumber IS NOT NULL AND (@IsInvoiceSummary = 1 OR @InvoiceNumber  IS NOT NULL OR @InvoiceId IS NOT NULL)
BEGIN 
SET @Contract=REPLACE( @Contract, 'InvoiceNumberFilter',  ' AND Contract.ContractId = rid.EntityId');
END
ELSE IF @PreviousScheduleNumber IS NOT NULL AND (@IsInvoiceSummary = 1 OR @InvoiceNumber  IS NOT NULL OR @InvoiceId IS NOT NULL)
BEGIN 
SET @Contract=REPLACE( @Contract, 'InvoiceNumberFilter',  ' AND Contract.ContractId = rid.EntityId');
END
ELSE 
BEGIN 
SET @Contract=REPLACE( @Contract, 'InvoiceNumberFilter', '');
END;

IF @ContractSequenceNumber IS NOT NULL
BEGIN 
SET @Contract=REPLACE( @Contract, 'ContractSequenceNumberFilter',  ' AND Contract.SequenceNumber LIKE '''+ REPLACE( REPLACE( @ContractSequenceNumber, CHAR(39), CHAR(39)+CHAR(39) ),'*', '%' )+'''');
END
ELSE 
BEGIN 
SET @Contract=REPLACE( @Contract, 'ContractSequenceNumberFilter', '');
END;

IF @AssetSerialNumber IS NOT NULL AND (@IsInvoiceSummary = 1 OR @InvoiceNumber  IS NOT NULL OR @InvoiceId IS NOT NULL)
BEGIN
SET @Contract=REPLACE( @Contract, 'AssetIdSelection',  ', ASSETS.Id AS AssetId');
SET @Contract=REPLACE( @Contract, 'AssetIdFilter',  ' AND Contract.AssetId =  Rd.AssetId');
END
ELSE 
BEGIN 
SET @Contract=REPLACE( @Contract, 'AssetIdFilter', '');
SET @Contract=REPLACE( @Contract, 'AssetIdSelection', '');
END;

IF @IsContractSummary=1
OR @ContractSequenceNumber IS NOT NULL
OR @ContractAlias IS NOT NULL
OR @ContractId IS NOT NULL
OR @CustomerAssetNumber IS NOT NULL
OR @VendorOrderNumber IS NOT NULL
OR @FunderName IS NOT NULL
OR @FunderAccountNumber IS NOT NULL
OR @AssetSerialNumber IS NOT NULL
OR @CollateralCode IS NOT NULL
OR @BillToId IS NOT NULL
OR @ExternalReferenceNumber IS NOT NULL
OR @PreviousScheduleNumber IS NOT NULL
BEGIN
SET @Query=REPLACE( @Query, 'JOIN_CONTRACT', @Contract );
SET @Query=REPLACE( @Query, 'ReplaceContractSequenceNumber', ' ,Contract.SequenceNumber  ContractSequenceNumber' );
SET @Query=REPLACE( @Query, 'ReplaceSequenceNumberFromInvoice', ' ' );
END;
ELSE
BEGIN
SET @Query=REPLACE( @Query, 'JOIN_CONTRACT', ' ' );
SET @Query=REPLACE( @Query, 'ReplaceContractSequenceNumber', ' ' );
END;
IF @InvoiceNumber IS NOT NULL
BEGIN
SET @Query=REPLACE( @Query, 'JOIN_INVOICE', ' join ReceivableInvoices I
on Cus.Id = I.CustomerId
AND  I.Number LIKE  '''+REPLACE( REPLACE( @InvoiceNumber, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+'''
join #AccessibleLegalEntityIds on I.LegalEntityId = #AccessibleLegalEntityIds.Id
join ReceivableInvoiceDetails rid
on i.Id = rid.ReceivableInvoiceId
join receivables r
on rid.ReceivableId = r.Id
left join contracts c
on c.id = r.EntityId
and (c.IsConfidential = 0  OR
c.ID IN	(SELECT [Contracts].[Id]
FROM  [dbo].[Contracts]
INNER JOIN [dbo].[EmployeesAssignedToContracts] AS EAC ON [Contracts].[Id] = EAC.[ContractId]
INNER JOIN [dbo].[EmployeesAssignedToParties] AS EACu ON EAC.[EmployeeAssignedToPartyId] = EACu.[Id]
WHERE EACu.[EmployeeId] = '''+REPLACE( @UserId, CHAR(39), CHAR(39)+CHAR(39) )+''' AND [Contracts].[IsConfidential] = 1) )
and r.EntityType = ''CT''' );
SET @Query=REPLACE( @Query, 'ReplaceInvoiceNumber', ' ,I.Number InvoiceNumber ' );
SET @Query=REPLACE( @Query, 'ReplaceSequenceNumberFromInvoice', ' ,c.SequenceNumber  ContractSequenceNumber' );
END;
ELSE
IF @InvoiceId IS NOT NULL
BEGIN
SET @Query=REPLACE( @Query, 'JOIN_INVOICE', ' join ReceivableInvoices I
on Cus.Id = I.CustomerId
AND  I.Id = '''+REPLACE( REPLACE( @InvoiceId, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+'''
join #AccessibleLegalEntityIds on I.LegalEntityId = #AccessibleLegalEntityIds.Id
join ReceivableInvoiceDetails rid
on i.Id = rid.ReceivableInvoiceId
join receivables r
on rid.ReceivableId = r.Id
left join contracts c
on c.id = r.EntityId
and (c.IsConfidential = 0  OR
c.ID IN	(SELECT [Contracts].[Id]
FROM  [dbo].[Contracts]
INNER JOIN [dbo].[EmployeesAssignedToContracts] AS EAC ON [Contracts].[Id] = EAC.[ContractId]
INNER JOIN [dbo].[EmployeesAssignedToParties] AS EACu ON EAC.[EmployeeAssignedToPartyId] = EACu.[Id]
WHERE EACu.[EmployeeId] = '''+REPLACE( @UserId, CHAR(39), CHAR(39)+CHAR(39) )+''' AND [Contracts].[IsConfidential] = 1) )
and r.EntityType = ''CT''' );
SET @Query=REPLACE( @Query, 'ReplaceInvoiceNumber', ' ,I.Number InvoiceNumber ' );
SET @Query=REPLACE( @Query, 'ReplaceSequenceNumberFromInvoice', ' ,c.SequenceNumber  ContractSequenceNumber' );
END;
ELSE
IF @IsInvoiceSummary=1
AND @InvoiceNumber IS NULL
AND @InvoiceId IS NULL
BEGIN
SET @Query=REPLACE( @Query, 'JOIN_INVOICE', ' join ReceivableInvoices I
on Cus.Id = I.CustomerId
join #AccessibleLegalEntityIds on I.LegalEntityId = #AccessibleLegalEntityIds.Id
join ReceivableInvoiceDetails rid
on i.Id = rid.ReceivableInvoiceId
join receivables r
on rid.ReceivableId = r.Id
left join contracts c
on c.id = r.EntityId
and (c.IsConfidential = 0  OR
c.ID IN	(SELECT [Contracts].[Id]
FROM  [dbo].[Contracts]
INNER JOIN [dbo].[EmployeesAssignedToContracts] AS EAC ON [Contracts].[Id] = EAC.[ContractId]
INNER JOIN [dbo].[EmployeesAssignedToParties] AS EACu ON EAC.[EmployeeAssignedToPartyId] = EACu.[Id]
WHERE EACu.[EmployeeId] = '''+REPLACE( @UserId, CHAR(39), CHAR(39)+CHAR(39) )+''' AND [Contracts].[IsConfidential] = 1) )
and r.EntityType = ''CT''' );
SET @Query=REPLACE( @Query, 'ReplaceInvoiceNumber', ' ,I.Number InvoiceNumber ' );
SET @Query=REPLACE( @Query, 'ReplaceSequenceNumberFromInvoice', ' ,c.SequenceNumber  ContractSequenceNumber' );
END;
ELSE
BEGIN
SET @Query=REPLACE( @Query, 'JOIN_INVOICE', ' ' );
SET @Query=REPLACE( @Query, 'ReplaceInvoiceNumber', ' ' );
SET @Query=REPLACE( @Query, 'ReplaceSequenceNumberFromInvoice', ' ' );
END;;;
--@WHERECLAUSE--
DECLARE
@WhereClause NVARCHAR(MAX)='';
IF @CustomerNumber IS NOT NULL
BEGIN
IF @CustomerNumber IS NOT NULL
AND ( @IsContractSummary=1 OR @ContractSequenceNumber IS NOT NULL)
BEGIN
SET @WhereClause=@WhereClause+' AND ( UPPER(P.PartyNumber) LIKE '''+REPLACE( REPLACE( @CustomerNumber, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+'''OR Contract.ContractId IN (SELECT ContractId FROM #AssumptionDetails WHERE #AssumptionDetails.PartyNumber LIKE '''+REPLACE( REPLACE( @CustomerNumber, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+'''))';
SET @Query=REPLACE( @Query, 'ReplaceFilterCustomerNumber', ' ,ISNULL(AD.PartyNumber,p.PartyNumber) [FilteredCustomerNumber],ISNULL(AD.PartyName,p.PartyName) [FilteredCustomerName]' );
END;
ELSE
BEGIN
SET @WhereClause=@WhereClause+' AND UPPER(P.PartyNumber) LIKE '''+REPLACE( REPLACE( @CustomerNumber, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+'''';
SET @Query=REPLACE( @Query, 'ReplaceFilterCustomerNumber', ' ' );
END;
END
ELSE
BEGIN
SET @Query=REPLACE( @Query, 'ReplaceFilterCustomerNumber', ' ' );
END
;
IF @ContractId IS NOT NULL
OR @ContractAlias IS NOT NULL
OR @ContractSequenceNumber IS NOT NULL
OR @VendorOrderNumber IS NOT NULL
OR @CustomerAssetNumber IS NOT NULL
BEGIN
SET @WhereClause=@WhereClause+' AND Contract.SequenceNumber is not null';
END;
IF @CustomerId IS NOT NULL
BEGIN
SET @WhereClause=@WhereClause+' AND P.Id = '+REPLACE( REPLACE( @CustomerId, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+'';
END;
IF @CustomerName IS NOT NULL
BEGIN
IF @CustomerNumber IS NOT NULL AND ( @IsContractSummary=1 OR @ContractSequenceNumber IS NOT NULL)
BEGIN
SET @WhereClause=@WhereClause+' AND (UPPER(P.PartyName) LIKE '''+REPLACE( REPLACE( @CustomerName, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+'''OR Contract.ContractId IN (SELECT ContractId FROM #AssumptionDetails WHERE #AssumptionDetails.PartyName LIKE '''+REPLACE( REPLACE( @CustomerName, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+'''))';
SET @Query=REPLACE( @Query, 'ReplaceFilterCustomerName', ' ' );
END;
ELSE IF (@IsContractSummary=1 OR @ContractSequenceNumber IS NOT NULL)
BEGIN
SET @WhereClause=@WhereClause+' AND (UPPER(P.PartyName) LIKE '''+REPLACE( REPLACE( @CustomerName, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+'''OR Contract.ContractId IN (SELECT ContractId FROM #AssumptionDetails WHERE #AssumptionDetails.PartyName LIKE '''+REPLACE( REPLACE( @CustomerName, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+'''))';
SET @Query=REPLACE( @Query, 'ReplaceFilterCustomerName', ' ,ISNULL(AD.PartyNumber,p.PartyNumber) [FilteredCustomerNumber],ISNULL(AD.PartyName,p.PartyName) [FilteredCustomerName]' );
END;
ELSE
BEGIN
SET @WhereClause=@WhereClause+' AND UPPER(P.PartyName) LIKE '''+REPLACE( REPLACE( @CustomerName, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+'''';
SET @Query=REPLACE( @Query, 'ReplaceFilterCustomerName', ' ' );
END;
END;
ELSE
BEGIN
SET @Query=REPLACE( @Query, 'ReplaceFilterCustomerName', ' ' );
END;
IF @Last4DigitTaxIdSSNNationalID IS NOT NULL AND (@IsContractSummary = 0 OR @IsInvoiceSummary = 1)
BEGIN
SET @WhereClause=@WhereClause+' AND p.LastFourDigitUniqueIdentificationNumber LIKE '''+REPLACE( REPLACE( @Last4DigitTaxIdSSNNationalID, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+'''';
END;
IF @DoingBusinessAs IS NOT NULL OR @DoingBusinessAs <>''
BEGIN
SET @Query = REPLACE(@query,'DoingBusinessName','#DBA.DoingBusinessAs')
SET @DoingBusinessAsFilter = N'SELECT
  CustomerID
, COUNT(*) CustomerDBACount
, MIN(Id) Id
INTO #CustomerDoingBusinessAs
FROM CustomerDoingBusinessAs
WHERE IsActive = 1
DoingBusinessAsNameFilter
GROUP BY CustomerID

SELECT BA.CustomerID, CASE WHEN CustomerDBACount > 1 THEN ''Multiple'' ELSE DBA.DoingBusinessAsName END DoingBusinessAs
INTO #DBA
FROM #CustomerDoingBusinessAs BA
JOIN CustomerDoingBusinessAs DBA ON BA.Id = DBA.Id'
SET  @DoingBusinessAsFilter = REPLACE(@DoingBusinessAsFilter,'DoingBusinessAsNameFilter',' AND DoingBusinessAsName LIKE ''' + REPLACE(REPLACE(@DoingBusinessAs,CHAR(39),CHAR(39)+CHAR(39)),'*','%')  + '%' + '''');
              SET @Query=REPLACE( @Query, 'CUSTOMERDOINGBUSINESSASFILTER', @DoingBusinessAsFilter );
              SET @Query=REPLACE(@Query, 'DBA_JOIN', 'INNER JOIN #DBA ON Cus.Id = #DBA.CustomerID');
END

SET @WhereClause =@WhereClause + ' AND P.PortfolioId = '+REPLACE( REPLACE( @CurrentPortFolioId, CHAR(39), CHAR(39)+CHAR(39) ), '*', '%' )+'';
       
        
IF @IsContractSummary = 1 AND @Last4DigitTaxIdSSNNationalID IS NOT NULL                   
BEGIN  
	DECLARE @SQLQuery NVARCHAR(MAX) = '';  
	DECLARE @ThridPartyWhereClause NVARCHAR(MAX) = '';
	CREATE TABLE #ThirdPartyContracts (ContractId BIGINT PRIMARY KEY)

	SET @ThridPartyWhereClause = @ThridPartyWhereClause + '  P.LastFourDigitUniqueIdentificationNumber LIKE ''' + REPLACE(REPLACE(@Last4DigitTaxIdSSNNationalID, CHAR(39), CHAR(39) + CHAR(39)), '*', '%') + '''';

	SET @SQLQuery = N'        
	INSERT INTO #ThirdPartyContracts
	SELECT Id ContractId
	FROM (
		SELECT C.Id
		FROM Contracts C
		JOIN LeaseFinances LF ON LF.ContractId = C.Id AND IsCurrent=1
		JOIN Parties P ON P.Id = LF.CustomerId
		WHERE' + @ThridPartyWhereClause + '
	
		UNION ALL
	
		SELECT C.Id
		FROM Contracts C
		JOIN LoanFinances LF ON LF.ContractId = C.Id AND IsCurrent=1
		JOIN Parties P ON P.Id = LF.CustomerId
		WHERE ' + @ThridPartyWhereClause + '
		) T

	UNION

	SELECT C.Id
	FROM Contracts C
	JOIN ContractThirdPartyRelationships CTR ON CTR.ContractId = C.Id AND CTR.IsActive = 1
	JOIN CustomerThirdPartyRelationships CTP ON CTP.Id = CTR.ThirdPartyRelationshipId AND CTP.IsActive = 1
	JOIN Parties P ON P.Id = CTP.ThirdPartyId
	WHERE ' + @ThridPartyWhereClause 

	SET @Query=REPLACE( @Query, 'JOIN_THIRD_PARTY_CONTRACT', ' join #ThirdPartyContracts ON #ThirdPartyContracts.ContractId=Contract.ContractId' );        
   
	SET @Query=@SQLQuery+@Query;
 END
 ELSE
 BEGIN
	SET @Query=REPLACE( @Query, 'JOIN_THIRD_PARTY_CONTRACT', '' );   
END    

IF @CustomerNumber IS NULL
AND @CustomerName IS NULL
AND @Last4DigitTaxIdSSNNationalID IS NULL
AND @CustomerId IS NULL
AND @ContractId IS NULL
AND @ContractAlias IS NULL
AND @ContractSequenceNumber IS NULL
BEGIN
SET @WhereClause=' ';
END;

IF @DoingBusinessAs IS NULL
BEGIN
              SET @Query=REPLACE( @Query, 'CUSTOMERDOINGBUSINESSASFILTER', '' );
              SET @Query=REPLACE(@Query, 'DBA_JOIN', 'LEFT JOIN (SELECT CustomerId,COUNT(*) AS Count,MAX(DoingBusinessAsName) AS DoingBusinessAs  from CustomerDoingBusinessAs GROUP BY CustomerId) AS DBA ON Cus.Id = DBA.CustomerId');
              SET @Query = REPLACE(@query,'DoingBusinessName','CASE WHEN ISNULL(DBA.Count,0) > 1 THEN  ''Multiple'' ELSE DBA.DoingBusinessAs END ' )
END

SET @Query=REPLACE( @Query, 'WHERECLAUSE', @WhereClause );
PRINT @Query;
EXEC sp_executesql @Query

,
N'@CustomerNumber nvarchar(50) = null
,@CustomerName nvarchar(500)  = null
,@Last4DigitTaxIdSSNNationalID nvarchar(24)  = null
,@AccountNumber nvarchar(80) = null
,@ContactNumber nvarchar(40) = null
,@ContactFirstName nvarchar(80) = null
,@ContactLastName  nvarchar(80) = null
,@DoingBusinessAs nvarchar(200) = null
,@CustomerId Bigint = null
,@ContractId Bigint = null
,@InvoiceId bigint = null
,@ContractAlias nvarchar(80) = null
,@ContractSequenceNumber nvarchar(80) = null
,@InvoiceNumber nvarchar(80) = null
,@VendorName nvarchar(80) = null
,@VendorNumber nvarchar(80) = null
,@VendorInvoiceNumber nvarchar(80) = null
,@GuarantorName nvarchar(80) = null
,@GuarantorNumber nvarchar(80) = null
,@FunderAccountNumber nvarchar(80) = null
,@FunderName nvarchar(80) = null
,@AssetSerialNumber nvarchar(80) = null
,@CollateralCode nvarchar(80) = null
,@BillToId nvarchar(40) = null
,@ExternalReferenceNumber nvarchar(80) = null
,@PreviousScheduleNumber nvarchar(80) = null',
@CustomerNumber,
@CustomerName,
@Last4DigitTaxIdSSNNationalID,
@AccountNumber,
@ContactNumber,
@ContactFirstName,
@ContactLastName,
@DoingBusinessAs,
@CustomerId,
@ContractId,
@InvoiceId,
@ContractAlias,
@ContractSequenceNumber,
@InvoiceNumber,
@VendorName,
@VendorNumber,
@VendorInvoiceNumber,
@GuarantorName,
@GuarantorNumber,
@FunderAccountNumber,
@FunderName,
@AssetSerialNumber,
@CollateralCode,
@BillToId,
@ExternalReferenceNumber,
@PreviousScheduleNumber;
END;

GO

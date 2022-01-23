SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetGuarantorsForEIPOutBoundInterface]
AS
BEGIN
SET NOCOUNT ON;
WITH CTE_PartyContacts AS
(
SELECT * FROM(
SELECT
PartyId=PartyContacts.PartyId,
PartyContactId=PartyContacts.Id,
PartyContactTypeId=PartyContactTypes.Id,
PartyFullName=PartyContacts.FullName,
GurantorTaxId='****'+PartyContacts.LastFourDigitSocialSecurityNumber,
RANK=ROW_NUMBER() OVER(PARTITION BY PartyId ORDER BY PartyContacts.Id DESC)
FROM PartyContacts
INNER JOIN PartyContactTypes ON PartyContacts.Id=PartyContactTypes.PartyContactId
AND PartyContactTypes.ContactType='Main' AND PartyContacts.IsActive=1 AND PartyContactTypes.IsActive=1
)TEMP WHERE RANK=1
),
CTE_Guarantors AS
(
SELECT
CustomerId=Customers.Id,
CustomerThirdPartyRelationshipId= CustomerThirdPartyRelationships.Id,
GuarantorName=Guarantor.PartyName,
GuarantorAddress1=CASE WHEN CustomerThirdPartyRelationships.ThirdPartyAddressId Is Not NULL THEN CustomerThirdPartyAddress.AddressLine1
ELSE PartyAddresses.AddressLine1 END,
GuarantorAddress2=CASE WHEN CustomerThirdPartyRelationships.ThirdPartyAddressId Is Not NULL THEN CustomerThirdPartyAddress.AddressLine2
ELSE PartyAddresses.AddressLine2 END,
GuarantorCity=CASE WHEN CustomerThirdPartyRelationships.ThirdPartyAddressId Is Not NULL THEN CustomerThirdPartyAddress.City
ELSE PartyAddresses.City END,
GuarantorState=CASE WHEN CustomerThirdPartyRelationships.ThirdPartyAddressId Is Not NULL THEN CustomerThirdPartyState.LongName
ELSE States.LongName END,
GuarantorZIPCode=CASE WHEN CustomerThirdPartyRelationships.ThirdPartyAddressId Is Not NULL THEN CustomerThirdPartyAddress.PostalCode
ELSE PartyAddresses.PostalCode END,
CountryName=CASE WHEN CustomerThirdPartyRelationships.ThirdPartyAddressId Is Not NULL THEN CustomerThirdPartyCountry.LongName
ELSE Countries.LongName END,
LimitedGuaranteeComment=CustomerThirdPartyRelationships.Description,
GuarantorTypeDescription=CustomerThirdPartyRelationships.RelationshipType,
GurantorTaxId='****'+Guarantor.LastFourDigitUniqueIdentificationNumber,
CustomerNumber=Customer.PartyNumber
FROM Customers
INNER JOIN Parties Customer ON Customer.Id=Customers.Id
INNER JOIN CustomerThirdPartyRelationships ON Customers.Id=CustomerThirdPartyRelationships.CustomerId
AND RelationshipType IN ('CoLessee','CoBorrower','CorporateGuarantor')
AND CustomerThirdPartyRelationships.IsActive=1
LEFT JOIN Parties Guarantor ON Guarantor.Id=CustomerThirdPartyRelationships.ThirdPartyId
LEFT JOIN PartyAddresses CustomerThirdPartyAddress ON CustomerThirdPartyAddress.Id=CustomerThirdPartyRelationships.ThirdPartyAddressId
AND CustomerThirdPartyRelationships.ThirdPartyId=CustomerThirdPartyAddress.PartyId
LEFT JOIN States CustomerThirdPartyState ON CustomerThirdPartyState.Id=CustomerThirdPartyAddress.StateId AND CustomerThirdPartyState.IsActive=1
LEFT JOIN Countries CustomerThirdPartyCountry ON CustomerThirdPartyCountry.Id=CustomerThirdPartyState.CountryId AND CustomerThirdPartyCountry.IsActive=1
LEFT JOIN PartyAddresses ON PartyAddresses.PartyId=Customer.Id
AND PartyAddresses.IsMain=1
LEFT JOIN States ON States.Id=PartyAddresses.StateId AND States.IsActive=1
LEFT JOIN Countries ON Countries.Id=States.CountryId AND Countries.IsActive=1
UNION ALL
SELECT
CustomerId=Customers.Id,
CustomerThirdPartyRelationshipId= CustomerThirdPartyRelationships.Id,
GuarantorName=PartyContacts.FullName,
GuarantorAddress1=PartyAddresses.AddressLine1,
GuarantorAddress2=PartyAddresses.AddressLine2,
GuarantorCity=PartyAddresses.City,
GuarantorState=States.LongName,
GuarantorZIPCode=PartyAddresses.PostalCode,
CountryName=Countries.LongName,
LimitedGuaranteeComment=CustomerThirdPartyRelationships.Description,
GuarantorTypeDescription=CustomerThirdPartyRelationships.RelationshipType,
GurantorTaxId='****'+PartyContacts.LastFourDigitSocialSecurityNumber,
CustomerNumber=Customer.PartyNumber
FROM Customers
INNER JOIN Parties Customer ON Customers.Id=Customer.Id
INNER JOIN CustomerThirdPartyRelationships ON Customer.Id=CustomerThirdPartyRelationships.CustomerId
AND CustomerThirdPartyRelationships.IsActive=1
INNER JOIN PartyAddresses ON PartyAddresses.Id=CustomerThirdPartyRelationships.ThirdPartyAddressId
AND CustomerThirdPartyRelationships.RelationshipType='PersonalGuarantor'
LEFT JOIN PartyContacts ON PartyAddresses.PartyId=PartyContacts.PartyId AND PartyContacts.Id=CustomerThirdPartyRelationships.ThirdPartyContactId
LEFT JOIN PartyContactTypes ON PartyContactTypes.PartyContactId=PartyContacts.Id AND PartyContactTypes.ContactType='PersonalGuarantor' AND PartyContacts.IsActive=1 AND PartyContactTypes.IsActive=1
LEFT JOIN States ON States.Id=PartyAddresses.StateId AND States.IsActive=1
LEFT JOIN Countries ON Countries.Id=states.CountryId AND Countries.IsActive=1
),
CTE_ContractOriginationWithLatestServiceDetail AS
(
SELECT * FROM (
Select
ContractOriginationId=ContractOriginations.Id,
EffectiveDate=ServicingDetails.EffectiveDate,
IsPrivateLabel=CASE
WHEN ServicingDetails.IsPrivateLabel = 1 THEN 'Y'
ELSE 'N'
END,
RANK=ROW_NUMBER() OVER(Partition By ContractOriginations.Id Order By ServicingDetails.EffectiveDate DESC)
FROM ContractOriginations
INNER JOIN ContractOriginationServicingDetails ON ContractOriginationServicingDetails.ContractOriginationId=ContractOriginations.Id
INNER JOIN ServicingDetails ON ServicingDetails.Id=ContractOriginationServicingDetails.ServicingDetailId
AND ServicingDetails.IsActive=1
)TEMP WHERE RANK=1
),
CTE_ContractGuarantors AS
(
SELECT
LeaseNumber=Contracts.SequenceNumber,
GuarantorName=CTE_Guarantors.GuarantorName,
GuarantorAddress1=CTE_Guarantors.GuarantorAddress1,
GuarantorAddress2=CTE_Guarantors.GuarantorAddress2,
GuarantorCity=CTE_Guarantors.GuarantorCity,
GuarantorState=CTE_Guarantors.GuarantorState,
GuarantorZIPCode=CTE_Guarantors.GuarantorZIPCode,
CountryName=CTE_Guarantors.CountryName,
GurantorTaxId=CTE_Guarantors.GurantorTaxId,
LimitedGuaranteeComment=CTE_Guarantors.LimitedGuaranteeComment,
GuarantorTypeDescription=CTE_Guarantors.GuarantorTypeDescription,
LimitedGuaranteePercent=ISNULL(ContractThirdPartyRelationships.RelationshipPercentage,0.0),
CustomerNumber=CTE_Guarantors.CustomerNumber,
CustomerContactId=CTE_PartyContacts.PartyContactId,
IsAssigned=ISNULL(CONVERT(NVARCHAR,ContractThirdPartyRelationships.IsActive),'0'),
Private_Label_Flag=CTE_ContractOriginationWithLatestServiceDetail.IsPrivateLabel
FROM Contracts
INNER JOIN LeaseFinances ON Contracts.Id=LeaseFinances.ContractId AND LeaseFinances.IsCurrent=1 AND LeaseFinances.BookingStatus NOT IN('Pending','InstallingAssets')
INNER JOIN CTE_Guarantors ON CTE_Guarantors.CustomerId=LeaseFinances.CustomerId
LEFT JOIN ContractThirdPartyRelationships ON ContractThirdPartyRelationships.ThirdPartyRelationshipId=CTE_Guarantors.CustomerThirdPartyRelationshipId
AND ContractThirdPartyRelationships.ContractId=Contracts.Id
AND ContractThirdPartyRelationships.IsActive=1
LEFT JOIN CTE_ContractOriginationWithLatestServiceDetail ON CTE_ContractOriginationWithLatestServiceDetail.ContractOriginationId=LeaseFinances.ContractOriginationId
LEFT JOIN CTE_PartyContacts ON CTE_PartyContacts.PartyId=LeaseFinances.CustomerId
UNION ALL
SELECT
LeaseNumber=Contracts.SequenceNumber,
GuarantorName=CTE_Guarantors.GuarantorName,
GuarantorAddress1=CTE_Guarantors.GuarantorAddress1,
GuarantorAddress2=CTE_Guarantors.GuarantorAddress2,
GuarantorCity=CTE_Guarantors.GuarantorCity,
GuarantorState=CTE_Guarantors.GuarantorState,
GuarantorZIPCode=CTE_Guarantors.GuarantorZIPCode,
CountryName=CTE_Guarantors.CountryName,
GurantorTaxId=CTE_Guarantors.GurantorTaxId,
LimitedGuaranteeComment=CTE_Guarantors.LimitedGuaranteeComment,
GuarantorTypeDescription=CTE_Guarantors.GuarantorTypeDescription,
LimitedGuaranteePercent=ISNULL(ContractThirdPartyRelationships.RelationshipPercentage,0.0),
CustomerNumber=CTE_Guarantors.CustomerNumber,
CustomerContactId=CTE_PartyContacts.PartyContactId,
IsAssigned=ISNULL(CONVERT(NVARCHAR,ContractThirdPartyRelationships.IsActive),'0'),
Private_Label_Flag=CTE_ContractOriginationWithLatestServiceDetail.IsPrivateLabel
FROM Contracts
INNER JOIN LoanFinances ON Contracts.Id=LoanFinances.ContractId AND LoanFinances.IsCurrent=1 AND LoanFinances.Status Not IN('Uncommenced')
INNER JOIN CTE_Guarantors ON CTE_Guarantors.CustomerId=LoanFinances.CustomerId
LEFT JOIN ContractThirdPartyRelationships ON ContractThirdPartyRelationships.ThirdPartyRelationshipId=CTE_Guarantors.CustomerThirdPartyRelationshipId
AND ContractThirdPartyRelationships.ContractId=Contracts.Id
AND ContractThirdPartyRelationships.IsActive=1
LEFT JOIN CTE_ContractOriginationWithLatestServiceDetail ON CTE_ContractOriginationWithLatestServiceDetail.ContractOriginationId=LoanFinances.ContractOriginationId
LEFT JOIN CTE_PartyContacts ON CTE_PartyContacts.PartyId=LoanFinances.CustomerId
)
SELECT
LeaseNumber,
GuarantorName,
GuarantorAddress1,
GuarantorAddress2,
GuarantorCity,
GuarantorState,
GuarantorZIPCode,
CountryName,
GurantorTaxId,
LimitedGuaranteeComment,
GuarantorTypeDescription,
LimitedGuaranteePercent,
CustomerNumber,
CustomerContactId,
IsAssigned,
Private_Label_Flag
FROM
CTE_ContractGuarantors
ORDER BY CTE_ContractGuarantors.LeaseNumber
END

GO

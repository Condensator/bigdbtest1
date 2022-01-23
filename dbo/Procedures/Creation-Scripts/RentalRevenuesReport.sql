SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[RentalRevenuesReport]
(
@FromDate DATE=NULL,
@ToDate DATE=NULL,
@LegalEntityNumber NVARCHAR(MAX) = NULL,
@DealProductType NVARCHAR(40) = NULL,
@CustomerNumber NVARCHAR(40) = NULL,
@FromSequenceNumber AS NVARCHAR(80) = NULL,
@ToSequenceNumber AS NVARCHAR(80) = NULL,
@Culture  NVARCHAR(10)
)
AS
BEGIN
WITH CTE_BasicInfo
AS
(
SELECT
Party.PartyNumber AS CustomerNumber,
Party.PartyName AS Customer,
Contract.SequenceNumber AS ContractSequenceNumber,
Contract.Alias AS LeaseAlias,
ISNULL(EntityResourcesForDealType.Value,DealType.Name) AS DealType,
LeaseFinanceDetail.LeaseContractType AS LeaseContractType,
ISNULL(EntityResourceForCountry.Value,Country.ShortName) AS Country,
ISNULL(EntityResourceForState.Value,State.ShortName) AS State,
Location.Division AS County,
Location.City AS City,
ReceivableDetail.Amount_Currency AS Currency,
ISNULL(ReceivableTaxDetail.Revenue_Amount,0.00) AS RentalAmount
,ReceivableType.Name AS ReceivableType
FROM ReceivableDetails ReceivableDetail
JOIN Receivables Receivable ON ReceivableDetail.ReceivableId = Receivable.Id
JOIN ReceivableCodes ReceivableCode ON Receivable.ReceivableCodeId = ReceivableCode.Id
JOIN ReceivableTypes ReceivableType ON ReceivableCode.ReceivableTypeId = ReceivableType.Id
JOIN ReceivableTaxDetails ReceivableTaxDetail ON ReceivableDetail.Id = ReceivableTaxDetail.ReceivableDetailId
JOIN Locations Location ON ReceivableTaxDetail.LocationId = Location.Id
JOIN States State ON Location.StateId = State.Id
JOIN Countries Country ON State.CountryId = Country.Id
JOIN Contracts Contract ON Receivable.EntityId = Contract.Id
JOIN LeaseFinances LeaseFinance ON Contract.Id = LeaseFinance.ContractId and LeaseFinance.IsCurrent=1
JOIN LeaseFinanceDetails LeaseFinanceDetail on LeaseFinance.Id = LeaseFinanceDetail.Id
JOIN LegalEntities LegalEntity on LeaseFinance.LegalEntityId = LegalEntity.Id
JOIN DealProductTypes DealProductType on Contract.DealProductTypeId = DealProductType.Id
JOIN DealTypes DealType on DealProductType.DealTypeId = DealType.Id
JOIN Customers Customer ON Receivable.CustomerId = Customer.Id
JOIN Parties Party ON Customer.Id = Party.Id
LEFT JOIN EntityResources EntityResourceForState ON State.Id = EntityResourceForState.EntityId
AND EntityResourceForState.EntityType='State'
AND EntityResourceForState.Name='ShortName'
AND EntityResourceForState.Culture=@Culture
LEFT JOIN EntityResources EntityResourcesForDealType on EntityResourcesForDealType.EntityId=DealType.Id
AND EntityResourcesForDealType.EntityType='DealType'
AND EntityResourcesForDealType.Name='Name'
AND EntityResourcesForDealType.Culture=@Culture
LEFT JOIN EntityResources EntityResourceForCountry  ON Country.Id=EntityResourceForCountry.EntityId
AND EntityResourceForCountry.EntityType='Country'
AND EntityResourceForCountry.Name='ShortName'
AND EntityResourceForCountry.Culture=@Culture
WHERE Receivable.IsActive = 1
AND ReceivableDetail.IsActive = 1
AND ReceivableDetail.IsTaxAssessed = 1
AND ReceivableTaxDetail.IsActive = 1
AND ReceivableType.IsActive = 1
AND ReceivableType.IsRental = 1
AND Receivable.DueDate >= @FromDate
AND Receivable.DueDate <= @ToDate
AND (@LegalEntityNumber IS NULL OR LegalEntity.LegalEntityNumber in (select value from String_split(@LegalEntityNumber,',')))
AND (@DealProductType IS NULL OR DealProductType.Name = @DealProductType)
AND (DealProductType.Name != 'Synthetic')
AND (@CustomerNumber IS NULL OR Party.PartyNumber = @CustomerNumber)
AND ((@FromSequenceNumber IS NULL AND @ToSequenceNumber IS NULL)
OR (@FromSequenceNumber IS NOT NULL AND @ToSequenceNumber IS NULL AND Contract.SequenceNumber = @FromSequenceNumber)
OR (@ToSequenceNumber IS NOT NULL AND @FromSequenceNumber IS NULL AND Contract.SequenceNumber = @ToSequenceNumber)
OR (@FromSequenceNumber IS NOT NULL AND @ToSequenceNumber IS NOT NULL AND Contract.SequenceNumber BETWEEN @FromSequenceNumber AND @ToSequenceNumber))
),
CTE_InterimRental
AS
(
SELECT
CustomerNumber,
Customer,
ContractSequenceNumber,
LeaseAlias,
DealType,
LeaseContractType,
Country,
State,
County,
City,
Currency,
SUM(RentalAmount) AS InterimRentalAmount,
0.00 AS LeaseRentalAmount
FROM CTE_BasicInfo
WHERE ReceivableType='InterimRental'
GROUP BY
CustomerNumber,
Customer,
ContractSequenceNumber,
LeaseAlias,
DealType,
LeaseContractType,
Country,
State,
County,
City,
Currency
),
CTE_LeaseRental
AS
(
SELECT
CustomerNumber,
Customer,
ContractSequenceNumber,
LeaseAlias,
DealType,
LeaseContractType,
Country,
State,
County,
City,
Currency,
0.00 AS InterimRentalAmount,
SUM(RentalAmount) AS LeaseRentalAmount
FROM CTE_BasicInfo
WHERE ReceivableType!='InterimRental'
GROUP BY
CustomerNumber,
Customer,
ContractSequenceNumber,
LeaseAlias,
DealType,
LeaseContractType,
Country,
State,
County,
City,
Currency
),
CTE_RESULT
AS
(
SELECT * FROM CTE_LeaseRental
UNION
SELECT * FROM CTE_InterimRental
)
SELECT
CustomerNumber,
Customer,
ContractSequenceNumber,
LeaseAlias,
DealType,
LeaseContractType,
Country,
State,
County,
City,
Currency,
SUM(LeaseRentalAmount) AS LeaseRentalAmount,
SUM(InterimRentalAmount) AS InterimRentalAmount
FROM CTE_RESULT
GROUP BY CustomerNumber,
Customer,
ContractSequenceNumber,
LeaseAlias,
DealType,
LeaseContractType,
Country,
State,
County,
City,
Currency
ORDER BY ContractSequenceNumber
END

GO

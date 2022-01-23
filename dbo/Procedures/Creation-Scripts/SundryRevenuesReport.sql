SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[SundryRevenuesReport]
(
@FromDate DATETIMEOFFSET=NULL,
@ToDate DATETIMEOFFSET=NULL,
@LegalEntityNumber NVARCHAR(MAX) = NULL,
@DealProductType NVARCHAR(40) = NULL,
@ReceivableType NVARCHAR(40) = NULL,
@CustomerNumber NVARCHAR(40) = NULL,
@SequenceNumber AS NVARCHAR(80) = NULL,
@Culture NVARCHAR(10)
)
AS
BEGIN
SELECT
Party.PartyNumber AS CustomerNumber,
Party.PartyName AS Customer,
Contract.SequenceNumber AS ContractSequenceNumber,
Contract.Alias AS LeaseAlias,
ISNULL(EntityResourcesForDealType.Value,DealType.Name) AS DealType,
LeaseFinanceDetail.LeaseContractType AS LeaseContractType,
ISNULL(EntityResourceForCountry.Value,Country.ShortName) AS Country,
ISNULL(EntityResourceForState.Value,State.ShortName),
Location.Division AS County,
Location.City AS City,
ReceivableDetail.Amount_Currency AS Currency,
SUM(ISNULL(ReceivableTaxDetail.Revenue_Amount,0.00)) AS SundryRevenue
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
LEFT JOIN EntityResources EntityResourceForState ON  EntityResourceForState.EntityId=State.Id
AND EntityResourceForState.EntityType='State'
AND EntityResourceForState.Name='ShortName'
AND EntityResourceForState.Culture=@Culture
LEFT JOIN EntityResources EntityResourcesForDealType on EntityResourcesForDealType.EntityId=DealType.Id
AND EntityResourcesForDealType.EntityType='DealType'
AND EntityResourcesForDealType.Name='Name'
AND EntityResourcesForDealType.Culture=@Culture
LEFT JOIN EntityResources EntityResourceForCountry  ON EntityResourceForCountry.EntityId=Country.Id
AND EntityResourceForCountry.EntityType='Country'
AND EntityResourceForCountry.Name='ShortName'
AND EntityResourceForCountry.Culture=@Culture
WHERE Receivable.IsActive = 1
AND ReceivableDetail.IsActive = 1
AND ReceivableDetail.IsTaxAssessed = 1
AND ReceivableTaxDetail.IsActive = 1
AND Receivable.DueDate >= @FromDate
AND Receivable.DueDate <= @ToDate
AND (@LegalEntityNumber IS NULL OR LegalEntity.LegalEntityNumber in (select value from String_split(@LegalEntityNumber,',')))
AND (@DealProductType IS NULL OR DealProductType.Name = @DealProductType)
AND (DealProductType.Name != 'Synthetic')
AND (@ReceivableType IS NULL OR ReceivableType.Name = @ReceivableType)
AND (@CustomerNumber IS NULL OR Party.PartyNumber = @CustomerNumber)
AND (@SequenceNumber IS NULL OR Contract.SequenceNumber = @SequenceNumber)
AND ReceivableType.IsActive = 1
AND ReceivableType.Name IN ('PropertyTax','SecurityDeposit','Sundry','SundrySeparate','InsurancePremiumAdmin','InsurancePremium','LateFee','CPIOverage')
GROUP BY
Party.PartyNumber,
Party.PartyName,
Contract.SequenceNumber,
Contract.Alias,
ISNULL(EntityResourcesForDealType.Value,DealType.Name),
LeaseFinanceDetail.LeaseContractType,
ISNULL(EntityResourceForCountry.Value,Country.ShortName),
ISNULL(EntityResourceForState.Value,State.ShortName),
Location.Division,
Location.City,
ReceivableDetail.Amount_Currency
ORDER BY ContractSequenceNumber
END

GO

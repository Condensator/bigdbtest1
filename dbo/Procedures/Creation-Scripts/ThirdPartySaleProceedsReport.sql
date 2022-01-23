SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[ThirdPartySaleProceedsReport]
(
@FromDate DATETIMEOFFSET=NULL,
@ToDate DATETIMEOFFSET=NULL,
@DealProductType NVARCHAR(32) = NULL,
@LegalEntityNumber NVARCHAR(MAX) = NULL,
@CustomerNumber NVARCHAR(40) = NULL,
@SequenceNumber AS NVARCHAR(80) = NULL,
@Culture NVARCHAR(10)
)
AS
BEGIN
WITH CTE_AssetLocationDetails
AS
(
SELECT
Asset.Id AS AssetId,
MAX(AssetLocation.EffectiveFromDate) as LocationEffectiveDate
FROM AssetSaleDetails AssetSaleDetail
JOIN AssetSales AssetSale ON AssetSaleDetail.AssetSaleId = AssetSale.Id
JOIN Assets Asset ON AssetSaleDetail.AssetId = Asset.Id
JOIN AssetLocations AssetLocation ON Asset.Id = AssetLocation.AssetId
WHERE AssetLocation.IsActive = 1
AND AssetLocation.EffectiveFromDate <= AssetSale.DueDate
GROUP BY Asset.Id
),
CTE_TaxDepDetails
AS
(
SELECT AssetSale.Id as AssetSaleId,
MAX(TaxDepAmortizationDetails.DepreciationDate) as MaxDepreciationDate
FROM AssetSaleDetails AssetSaleDetail
JOIN AssetSales AssetSale ON AssetSaleDetail.AssetSaleId = AssetSale.Id
JOIN TaxDepEntities ON TaxDepEntities.AssetId = AssetSaleDetail.AssetId  AND TaxDepEntities.IsActive = 1
JOIN TaxDepTemplates ON TaxDepEntities.TaxDepTemplateId = TaxDepTemplates.Id AND TaxDepTemplates.IsActive = 1
JOIN TaxDepTemplateDetails ON TaxDepTemplates.Id = TaxDepTemplateDetails.TaxDepTemplateId
AND TaxDepTemplateDetails.TaxBook='Federal'
JOIN TaxDepRates on TaxDepTemplateDetails.TaxDepRateId = TaxDepRates.Id AND TaxDepRates.System != 'WDV' AND TaxDepRates.IsActive=1
JOIN TaxDepAmortizations ON TaxDepEntities.Id = TaxDepAmortizations.TaxDepEntityId AND TaxDepAmortizations.IsActive = 1
AND TaxDepAmortizations.TaxDepreciationTemplateId = TaxDepTemplates.Id
JOIN TaxDepAmortizationDetails ON TaxDepAmortizations.Id = TaxDepAmortizationDetails.TaxDepAmortizationId
AND TaxDepAmortizationDetails.TaxDepreciationTemplateDetailId = TaxDepTemplateDetails.Id
AND
TaxDepAmortizationDetails.IsSchedule = 1
AND TaxDepAmortizationDetails.EndNetBookValue_Currency = AssetSaleDetail.NetValue_Currency
WHERE TaxDepAmortizationDetails.DepreciationDate <= AssetSale.DueDate
GROUP BY AssetSale.Id
)
SELECT
Party.PartyNumber AS CustomerNumber,
Party.PartyName AS Customer,
Contract.SequenceNumber AS ContractSequenceNumber,
Contract.Alias AS LeaseAlias,
ISNULL(EntityResourceForDealType.Value,DealType.Name) AS DealType,
LeaseFinanceDetail.LeaseContractType AS LeaseContractType,
ISNULL(EntityResourceForCountry.Value,Country.ShortName) AS Country,
ISNULL(EntityResourceForState.Value,State.ShortName) AS State,
Location.Division AS County,
Location.City AS City,
AssetSaleDetail.NetValue_Currency AS Currency,
SUM(ISNULL(AssetSaleDetail.FairMarketValue_Amount,0.00)) AS Proceeds,
AssetSaleDetail.FairMarketValue_Currency AS ProceedsCurrency,
SUM(ISNULL(AssetSaleDetail.NetValue_Amount,0.00)) AS NetBasis,
TaxDepAmortizationDetails.EndNetBookValue_Amount AS TaxNBV,
TaxDepAmortizationDetails.EndNetBookValue_Currency AS TaxNBVCurrency
FROM AssetSaleDetails AssetSaleDetail
JOIN AssetSales AssetSale ON AssetSaleDetail.AssetSaleId = AssetSale.Id
JOIN CTE_TaxDepDetails TaxDepDetail ON AssetSale.Id = TaxDepDetail.AssetSaleId
JOIN TaxDepEntities ON TaxDepEntities.AssetId = AssetSaleDetail.AssetId  AND TaxDepEntities.IsActive = 1
JOIN TaxDepTemplates ON TaxDepEntities.TaxDepTemplateId = TaxDepTemplates.Id AND TaxDepTemplates.IsActive = 1
JOIN TaxDepTemplateDetails ON TaxDepTemplates.Id = TaxDepTemplateDetails.TaxDepTemplateId
AND TaxDepTemplateDetails.TaxBook='Federal'
JOIN TaxDepRates on TaxDepTemplateDetails.TaxDepRateId = TaxDepRates.Id AND TaxDepRates.System != 'WDV' AND TaxDepRates.IsActive=1
JOIN TaxDepAmortizations ON TaxDepEntities.Id = TaxDepAmortizations.TaxDepEntityId AND TaxDepAmortizations.IsActive = 1
AND TaxDepAmortizations.TaxDepreciationTemplateId = TaxDepTemplates.Id
JOIN TaxDepAmortizationDetails ON TaxDepAmortizations.Id = TaxDepAmortizationDetails.TaxDepAmortizationId
AND TaxDepAmortizationDetails.TaxDepreciationTemplateDetailId = TaxDepTemplateDetails.Id
AND TaxDepAmortizationDetails.IsSchedule = 1
AND TaxDepAmortizationDetails.EndNetBookValue_Currency = AssetSaleDetail.NetValue_Currency
JOIN CTE_AssetLocationDetails AssetLocationDetail ON AssetSaleDetail.AssetId = AssetLocationDetail.AssetId
JOIN AssetLocations AssetLocation ON AssetLocationDetail.AssetId = AssetLocation.AssetId
JOIN Locations Location ON AssetLocation.LocationId = Location.Id
JOIN States State ON Location.StateId = State.Id
JOIN Countries Country ON State.CountryId = Country.Id
JOIN LeaseAssets LeaseAsset ON AssetLocationDetail.AssetId = LeaseAsset.AssetId
JOIN LeaseFinances LeaseFinance ON LeaseAsset.LeaseFinanceId = LeaseFinance.Id and LeaseFinance.IsCurrent = 1
JOIN LeaseFinanceDetails LeaseFinanceDetail on LeaseFinance.Id = LeaseFinanceDetail.Id
JOIN LegalEntities LegalEntity on LeaseFinance.LegalEntityId = LegalEntity.Id
JOIN Contracts Contract ON LeaseFinance.ContractId = Contract.Id
JOIN DealProductTypes DealProductType on Contract.DealProductTypeId = DealProductType.Id
JOIN DealTypes DealType on DealProductType.DealTypeId = DealType.Id
JOIN Customers Customer ON LeaseFinance.CustomerId = Customer.Id
JOIN Parties Party ON Customer.Id = Party.Id
LEFT JOIN EntityResources EntityResourceForState ON  EntityResourceForState.EntityId=State.Id
AND EntityResourceForState.EntityType='State'
AND EntityResourceForState.Name='ShortName'
AND EntityResourceForState.Culture=@Culture
LEFT JOIN EntityResources EntityResourceForCountry  ON EntityResourceForCountry.EntityId=Country.Id
AND EntityResourceForCountry.EntityType='Country'
AND EntityResourceForCountry.Name='ShortName'
AND EntityResourceForCountry.Culture=@Culture
LEFT JOIN EntityResources EntityResourceForDealType ON EntityResourceForDealType.EntityId=DealType.Id
AND EntityResourceForDealType.EntityType='DealType'
AND EntityResourceForDealType.Name='Name'
AND EntityResourceForDealType.Culture=@Culture
WHERE AssetSaleDetail.IsActive = 1
AND AssetSale.DueDate >= @FromDate
AND AssetSale.DueDate <= @ToDate
AND (@LegalEntityNumber IS NULL OR LegalEntity.LegalEntityNumber in (select value from String_split(@LegalEntityNumber,',')))
AND (@DealProductType IS NULL OR DealProductType.Name = @DealProductType)
AND (DealProductType.Name != 'Synthetic')
AND (@CustomerNumber IS NULL OR Party.PartyNumber = @CustomerNumber)
AND (@SequenceNumber IS NULL OR Contract.SequenceNumber = @SequenceNumber)
AND AssetLocation.EffectiveFromDate = AssetLocationDetail.LocationEffectiveDate
AND TaxDepAmortizationDetails.DepreciationDate = TaxDepDetail.MaxDepreciationDate
GROUP BY
Party.PartyNumber,
Party.PartyName,
Contract.SequenceNumber,
Contract.Alias,
ISNULL(EntityResourceForDealType.Value,DealType.Name),
LeaseFinanceDetail.LeaseContractType,
ISNULL(EntityResourceForCountry.Value,Country.ShortName),
ISNULL(EntityResourceForState.Value,State.ShortName),
Location.Division,
Location.City,
AssetSaleDetail.NetValue_Currency,
TaxDepAmortizationDetails.EndNetBookValue_Amount,
TaxDepAmortizationDetails.EndNetBookValue_Currency,
AssetSaleDetail.FairMarketValue_Currency
ORDER BY ContractSequenceNumber
END

GO

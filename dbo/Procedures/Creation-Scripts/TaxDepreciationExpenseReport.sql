SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[TaxDepreciationExpenseReport]
(
@FromDate DATETIMEOFFSET = NULL
,@ToDate DATETIMEOFFSET = NULL
,@FilterOption NVARCHAR(15) = NULL
,@FromAsset  NVARCHAR(40) = NULL
,@ToAsset  NVARCHAR(40) = NULL
,@TaxBook NVARCHAR(40) = NULL
,@LeaseContractType NVARCHAR(40) = NULL
,@LegalEntityNumber NVARCHAR(MAX) = NULL
,@Culture NVARCHAR(10)
)
AS
BEGIN
WITH CTE_LatestAssetLocation
AS
(
SELECT
Asset.Id AS AssetId,
MAX(AssetLocation.EffectiveFromDate) as LocationEffectiveDate
FROM Assets Asset
JOIN AssetLocations AssetLocation ON Asset.Id = AssetLocation.AssetId
WHERE AssetLocation.IsActive = 1
--AND (@FromDate IS NULL OR AssetLocation.EffectiveFromDate >= @FromDate)
AND (@ToDate IS NULL OR AssetLocation.EffectiveFromDate <= @ToDate)
GROUP BY Asset.Id
)
SELECT
Parties.PartyNumber AS CustomerNumber
,Parties.PartyName AS CustomerName
,Contracts.SequenceNumber
,Contracts.Alias
,Assets.Id AS AssetId
,LeaseFinanceDetails.LeaseContractType
,ISNULL(EntityResourceForCountry.Value,Country.ShortName) AS CountryName
,ISNULL(EntityResourceForState.Value  ,State.ShortName) AS StateName
,Location.Division
,Location.City
,ISNULL(SUM(TaxDepAmortizationDetails.DepreciationAmount_Amount),0.00) AS TaxDepreciationExpenseAmount
,CurrencyCodes.ISO AS Currency
FROM  Assets
LEFT JOIN LeaseAssets ON LeaseAssets.AssetId = Assets.Id
LEFT JOIN LeaseFinances ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id
LEFT JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
LEFT JOIN Parties ON LeaseFinances.CustomerId = Parties.Id
LEFT JOIN Contracts ON LeaseFinances.ContractId = Contracts.Id
JOIN AssetLocations AssetLocation ON Assets.Id = AssetLocation.AssetId
JOIN Locations Location ON AssetLocation.LocationId = Location.Id AND Location.IsActive = 1
JOIN States State ON Location.StateId = State.Id
JOIN Countries Country ON State.CountryId = Country.Id
JOIN CTE_LatestAssetLocation ON Assets.Id = CTE_LatestAssetLocation.AssetId
JOIN LegalEntities ON Assets.LegalEntityId = LegalEntities.Id
JOIN TaxDepEntities ON TaxDepEntities.AssetId = Assets.Id
JOIN TaxDepTemplates ON TaxDepEntities.TaxDepTemplateId = TaxDepTemplates.Id
AND TaxDepTemplates.IsActive = 1 AND TaxDepEntities.IsActive = 1
JOIN TaxDepTemplateDetails ON TaxDepTemplates.Id = TaxDepTemplateDetails.TaxDepTemplateId
JOIN TaxDepAmortizations ON TaxDepEntities.Id = TaxDepAmortizations.TaxDepEntityId
AND TaxDepAmortizations.IsActive = 1
AND TaxDepAmortizations.TaxDepreciationTemplateId = TaxDepTemplates.Id
JOIN TaxDepAmortizationDetails ON TaxDepAmortizations.Id = TaxDepAmortizationDetails.TaxDepAmortizationId
AND TaxDepAmortizationDetails.TaxDepreciationTemplateDetailId = TaxDepTemplateDetails.Id
AND TaxDepAmortizationDetails.IsSchedule = 1
JOIN Currencies Currency ON TaxDepAmortizationDetails.CurrencyId = Currency.Id
JOIN CurrencyCodes ON Currency.CurrencyCodeId = CurrencyCodes.Id
LEFT JOIN EntityResources EntityResourceForCountry
ON Country.Id = EntityResourceForCountry.EntityId
AND EntityResourceForCountry.EntityType = 'Country'
AND EntityResourceForCountry.Name = 'ShortName'
AND EntityResourceForCountry.Culture = @Culture
LEFT JOIN EntityResources EntityResourceForState
ON State.Id = EntityResourceForState.EntityId
AND EntityResourceForState.EntityType = 'State'
AND EntityResourceForState.Name = 'ShortName'
AND EntityResourceForState.Culture = @Culture
WHERE Assets.Status IN('Leased','Inventory','Scrap','Error','Sold')
AND ((Assets.Status = 'Leased' AND LeaseAssets.IsActive=1 AND LeaseFinances.IsCurrent=1) OR (LeaseAssets.IsActive=0 AND LeaseAssets.TerminationDate IS NOT NULL))
AND AssetLocation.EffectiveFromDate = CTE_LatestAssetLocation.LocationEffectiveDate
AND (@LegalEntityNumber IS NULL OR LegalEntities.LegalEntityNumber in (select value from String_split(@LegalEntityNumber,',')))
AND (@FromDate IS NULL OR CAST(TaxDepAmortizationDetails.DepreciationDate AS DATE) >= CAST(@FromDate AS DATE)
AND (@ToDate IS NULL OR CAST(TaxDepAmortizationDetails.DepreciationDate AS DATE) <= CAST(@ToDate AS DATE)))
AND (@FilterOption IS NULL OR (@FilterOption ='One' AND Assets.Id = @FromAsset)
OR (@FilterOption ='Range' AND Assets.Id BETWEEN @FromAsset AND @ToAsset)
OR (@FilterOption ='All'))
AND (@TaxBook IS NULL OR TaxDepTemplateDetails.TaxBook = @TaxBook)
AND (@LeaseContractType IS NULL OR LeaseFinanceDetails.LeaseContractType = @LeaseContractType)
-- (TaxDepEntities.Id IS NOT NULL AND TaxDepEntities.FXTaxBasisAmount_Currency!=TaxDepEntities.TaxBasisAmount_Currency)
--AND LeaseAssets.AssetId = 189131699 TODO Testing
GROUP BY
Parties.PartyNumber
,Parties.PartyName
,Contracts.SequenceNumber
,Contracts.Alias
,Assets.Id
,LeaseFinanceDetails.LeaseContractType
,ISNULL(EntityResourceForCountry.Value,Country.ShortName)
,ISNULL(EntityResourceForState.Value  ,State.ShortName)
,Location.Division
,Location.City
,CurrencyCodes.ISO
END

GO

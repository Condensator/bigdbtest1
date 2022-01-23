SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[AccumulatedTaxDepreciationReport]
(
@AsOfDate DATETIMEOFFSET = NULL
,@FilterOption NVARCHAR(15) = NULL
,@FromAsset  NVARCHAR(40) = NULL
,@ToAsset  NVARCHAR(40) = NULL
,@TaxBook NVARCHAR(40) = NULL
,@LeaseContractType NVARCHAR(40) = NULL
,@CustomerNumber NVARCHAR(40) = NULL
,@SequenceNumber AS NVARCHAR(80) = NULL
,@LegalEntityNumber NVARCHAR(MAX) = NULL
,@Culture NVARCHAR(10) = NULL
,@CurrentPortfolioId BIGINT = NULL
)
AS
BEGIN
WITH CTE_AssetLocationDetails
AS
(
SELECT
Assets.Id AS AssetId,
MAX(AssetLocation.EffectiveFromDate) as LocationEffectiveDate
FROM Contracts
JOIN LeaseFinances ON Contracts.Id = LeaseFinances.ContractId AND LeaseFinances.IsCurrent=1
JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
JOIN LeaseAssets ON LeaseFinances.Id = LeaseAssets.LeaseFinanceId
JOIN Assets On LeaseAssets.AssetId = Assets.Id
JOIN AssetLocations AssetLocation ON Assets.Id = AssetLocation.AssetId
WHERE AssetLocation.IsActive = 1
AND AssetLocation.EffectiveFromDate <= @AsOfDate
GROUP BY Assets.Id
),
CTE_AmortizationDetails
AS
(
SELECT
Parties.PartyNumber AS CustomerNumber
,Parties.PartyName AS CustomerName
,Contracts.SequenceNumber
,Contracts.Alias
,LeaseAssets.AssetId
,LeaseFinanceDetails.LeaseContractType
,ISNULL(EntityResourceForCountry.Value,Country.ShortName) AS CountryName
,ISNULL(EntityResourceForState.Value,State.ShortName) AS StateName
,Location.Division
,Location.City
,ISNULL(SUM(TaxDepAmortizationDetails.DepreciationAmount_Amount),0.00) AS AccumulatedDepreciationAmount,
MAX(TaxDepAmortizationDetails.Id) AS TaxDepAmortizationDetailId
,CurrencyCodes.ISO AS Currency
FROM Contracts
JOIN LeaseFinances ON Contracts.Id = LeaseFinances.ContractId AND LeaseFinances.IsCurrent=1
JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
JOIN Parties ON LeaseFinances.CustomerId = Parties.Id
JOIN LeaseAssets ON LeaseFinances.Id = LeaseAssets.LeaseFinanceId
JOIN Assets On LeaseAssets.AssetId = Assets.Id
JOIN CTE_AssetLocationDetails AssetLocationDetail ON LeaseAssets.AssetId = AssetLocationDetail.AssetId
JOIN AssetLocations AssetLocation ON AssetLocationDetail.AssetId = AssetLocation.AssetId
JOIN Locations Location ON AssetLocation.LocationId = Location.Id AND Location.IsActive = 1
JOIN States State ON Location.StateId = State.Id
LEFT JOIN EntityResources EntityResourceForState ON State.Id = EntityResourceForState.EntityId
AND EntityResourceForState.EntityType = 'State'
AND EntityResourceForState.Name ='ShortName'
AND EntityResourceForState.Culture = @Culture
JOIN Countries Country ON State.CountryId = Country.Id
LEFT JOIN EntityResources EntityResourceForCountry ON State.Id = EntityResourceForCountry.EntityId
AND EntityResourceForCountry.EntityType = 'Country'
AND EntityResourceForCountry.Name ='ShortName'
AND EntityResourceForCountry.Culture = @Culture
JOIN LegalEntities ON Assets.LegalEntityId = LegalEntities.Id
JOIN TaxDepEntities ON TaxDepEntities.AssetId = Assets.Id
JOIN TaxDepTemplates ON TaxDepEntities.TaxDepTemplateId = TaxDepTemplates.Id AND TaxDepTemplates.IsActive = 1 AND TaxDepEntities.IsActive = 1
JOIN TaxDepTemplateDetails ON TaxDepTemplates.Id = TaxDepTemplateDetails.TaxDepTemplateId
JOIN TaxDepRates on TaxDepTemplateDetails.TaxDepRateId = TaxDepRates.Id AND TaxDepRates.IsActive=1 AND TaxDepRates.System !='WDV'
JOIN TaxDepAmortizations ON TaxDepEntities.Id = TaxDepAmortizations.TaxDepEntityId AND TaxDepAmortizations.IsActive = 1 AND TaxDepAmortizations.TaxDepreciationTemplateId = TaxDepTemplates.Id
JOIN TaxDepAmortizationDetails ON TaxDepAmortizations.Id = TaxDepAmortizationDetails.TaxDepAmortizationId AND TaxDepAmortizationDetails.TaxDepreciationTemplateDetailId = TaxDepTemplateDetails.Id
AND TaxDepAmortizationDetails.IsSchedule = 1 AND TaxDepAmortizationDetails.CurrencyId = Contracts.CurrencyId
JOIN Currencies Currency ON TaxDepAmortizationDetails.CurrencyId = Currency.Id
JOIN CurrencyCodes ON Currency.CurrencyCodeId = CurrencyCodes.Id
JOIN DealProductTypes DealProductType on Contracts.DealProductTypeId = DealProductType.Id
JOIN DealTypes DealType on DealProductType.DealTypeId = DealType.Id
WHERE (@AsOfDate IS NULL OR CAST(TaxDepAmortizationDetails.DepreciationDate AS DATE) <= CAST(@AsOfDate AS DATE))
AND (@FilterOption IS NULL OR (@FilterOption ='One' AND Assets.Id = @FromAsset)
OR (@FilterOption ='Range' AND Assets.Id BETWEEN @FromAsset AND @ToAsset)
OR (@FilterOption ='All'))
AND (@TaxBook IS NULL OR TaxDepTemplateDetails.TaxBook = @TaxBook)
AND (@LeaseContractType IS NULL OR LeaseFinanceDetails.LeaseContractType = @LeaseContractType)
AND ((@CustomerNumber IS NULL AND Parties.PortfolioId=@CurrentPortfolioId) OR Parties.PartyNumber = @CustomerNumber)
AND (@SequenceNumber IS NULL OR Contracts.SequenceNumber = @SequenceNumber)
AND (@LegalEntityNumber IS NULL OR LegalEntities.LegalEntityNumber in (select value from string_split(@LegalEntityNumber,',')))
AND (LeaseAssets.IsActive=1 OR ( LeaseAssets.IsActive=0 AND  LeaseAssets.TerminationDate IS NOT NULL))
AND (DealProductType.Name != 'Synthetic')
AND AssetLocation.EffectiveFromDate = AssetLocationDetail.LocationEffectiveDate
GROUP BY
Parties.PartyNumber
,Parties.PartyName
,Contracts.SequenceNumber
,Contracts.Alias
,LeaseAssets.AssetId
,LeaseFinanceDetails.LeaseContractType
,ISNULL(EntityResourceForCountry.Value,Country.ShortName)
,ISNULL(EntityResourceForState.Value,State.ShortName)
,Location.Division
,Location.City
,CurrencyCodes.ISO
)
SELECT AmortizationDetail.CustomerNumber
,AmortizationDetail.CustomerName
,AmortizationDetail.SequenceNumber
,AmortizationDetail.Alias
,AmortizationDetail.AssetId
,AmortizationDetail.LeaseContractType
,AmortizationDetail.CountryName
,AmortizationDetail.StateName
,AmortizationDetail.Division
,AmortizationDetail.City
,AmortizationDetail.AccumulatedDepreciationAmount
,AmortizationDetail.Currency
,TaxDepAmortizationDetail.BeginNetBookValue_Amount
FROM CTE_AmortizationDetails AmortizationDetail
JOIN TaxDepAmortizationDetails TaxDepAmortizationDetail ON AmortizationDetail.TaxDepAmortizationDetailId = TaxDepAmortizationDetail.Id
END

GO

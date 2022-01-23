SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[NonTaxLeaseNetInvestmentReport]
(
@AsOfDate DATETIMEOFFSET=NULL,
@LegalEntityNumber NVARCHAR(MAX) = NULL,
@DealProductType NVARCHAR(40) = NULL,
@LeaseContractType NVARCHAR(40) = NULL,
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
AssetLocation.AssetId AS AssetId,
MAX(AssetLocation.EffectiveFromDate) as LocationEffectiveDate
FROM AssetLocations AssetLocation
JOIN LeaseAssets LeaseAsset on LeaseAsset.AssetId = AssetLocation.AssetId
WHERE AssetLocation.IsActive = 1
AND LeaseAsset.IsActive = 1
AND AssetLocation.EffectiveFromDate <= @AsOfDate
GROUP BY AssetLocation.AssetId
)
SELECT
Party.PartyNumber AS CustomerNumber
,Party.PartyName  AS CustomerName
,Contract.SequenceNumber
,Contract.Alias
,LeaseFinanceDetail.LeaseContractType
,ISNULL(EntityResourceForCountry.Value,Country.ShortName) AS CountryName
,ISNULL(EntityResourceForState.Value,State.ShortName) AS StateName
,Location.Division
,Location.City
,AssetIncomeSchedule.EndNetBookValue_Currency AS Currency
,SUM(ISNULL(AssetIncomeSchedule.EndNetBookValue_Amount,0.00)) AS NetInvestment
FROM LeaseAssets LeaseAsset
JOIN Assets Asset ON LeaseAsset.AssetId = Asset.Id
JOIN AssetIncomeSchedules AssetIncomeSchedule on LeaseAsset.AssetId = AssetIncomeSchedule.AssetId
JOIN LeaseIncomeSchedules LeaseIncomeSchedule on AssetIncomeSchedule.LeaseIncomeScheduleId = LeaseIncomeSchedule.Id
JOIN CTE_AssetLocationDetails AssetLocationDetail ON LeaseAsset.AssetId = AssetLocationDetail.AssetId
JOIN AssetLocations AssetLocation ON Asset.Id = AssetLocation.AssetId
JOIN Locations Location ON AssetLocation.LocationId = Location.Id
JOIN States State ON Location.StateId = State.Id
LEFT JOIN EntityResources EntityResourceForState
ON State.Id = EntityResourceForState.EntityId
AND EntityResourceForState.EntityType = 'State'
AND EntityResourceForState.Name = 'ShortName'
AND EntityResourceForState.Culture = @Culture
JOIN Countries Country ON State.CountryId = Country.Id
LEFT JOIN EntityResources EntityResourceForCountry
ON Country.Id = EntityResourceForCountry.EntityId
AND EntityResourceForCountry.EntityType = 'Country'
AND EntityResourceForCountry.Name = 'ShortName'
AND EntityResourceForCountry.Culture = @Culture
JOIN LeaseFinances LeaseFinance ON LeaseAsset.LeaseFinanceId = LeaseFinance.Id and LeaseFinance.IsCurrent = 1
JOIN LeaseFinanceDetails LeaseFinanceDetail on LeaseFinance.Id = LeaseFinanceDetail.Id
JOIN LegalEntities LegalEntity on LeaseFinance.LegalEntityId = LegalEntity.Id
JOIN Contracts Contract ON LeaseFinance.ContractId = Contract.Id
JOIN DealProductTypes DealProductType on Contract.DealProductTypeId = DealProductType.Id
JOIN DealTypes DealType on DealProductType.DealTypeId = DealType.Id
JOIN Customers Customer ON LeaseFinance.CustomerId = Customer.Id
JOIN Parties Party ON Customer.Id = Party.Id
WHERE LeaseFinanceDetail.IsTaxLease=0
AND AssetIncomeSchedule.IsActive=1
AND (@AsOfDate IS NULL OR CAST(LeaseIncomeSchedule.IncomeDate AS DATE) = CAST(@AsOfDate AS DATE))
AND (@LegalEntityNumber IS NULL OR LegalEntity.LegalEntityNumber in (SELECT value
FROM STRING_SPLIT(@LegalEntityNumber,',')))
AND (@LeaseContractType IS NULL OR LeaseFinanceDetail.LeaseContractType = @LeaseContractType)
AND (@DealProductType IS NULL OR DealProductType.Name = @DealProductType)
AND (DealProductType.Name != 'Synthetic')
AND (@CustomerNumber IS NULL OR Party.PartyNumber = @CustomerNumber)
AND (@SequenceNumber IS NULL OR Contract.SequenceNumber = @SequenceNumber)
AND AssetLocation.EffectiveFromDate = AssetLocationDetail.LocationEffectiveDate
GROUP BY
Party.PartyNumber
,Party.PartyName
,Contract.SequenceNumber
,Contract.Alias
,LeaseFinanceDetail.LeaseContractType
,ISNULL(EntityResourceForCountry.Value,Country.ShortName)
,ISNULL(EntityResourceForState.Value,State.ShortName)
,Location.Division
,Location.City
,AssetIncomeSchedule.EndNetBookValue_Currency
END

GO

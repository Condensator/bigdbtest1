SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[ProceedsAndNetTaxBasisNonTaxLeasesReport]
(
@FromDate DATETIMEOFFSET=NULL
,@ToDate DATETIMEOFFSET=NULL
,@TransactionType NVARCHAR(30) = NULL
,@CustomerNumber NVARCHAR(40) = NULL
,@LegalEntityNumber NVARCHAR(MAX) = NULL
,@SequenceNumber NVARCHAR(40) = NULL
,@Culture NVARCHAR(10)
)
AS
BEGIN
SET NOCOUNT ON;
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
,Parties.PartyName  AS CustomerName
,Contracts.SequenceNumber
,Contracts.Alias
,LeaseFinanceDetails.LeaseContractType
,ISNULL(EntityResourceForCountry.Value,Countries.ShortName) AS CountryName
,ISNULL(EntityResourceForState.Value,States.ShortName) AS StateName
,Locations.Division
,Locations.City
,ISNULL(SUM(PayoffAssets.BuyoutAmount_Amount),0.00) AS Proceeds
,0.00 AS NetBasis
,Payoffs.PayoffAmount_Currency AS Currency
FROM Payoffs
JOIN LeaseFinances ON Payoffs.LeaseFinanceId = LeaseFinances.Id AND Payoffs.Status = 'Activated'
JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id AND LeaseFinanceDetails.IsTaxLease=0
JOIN LegalEntities ON LeaseFinances.LegalEntityId = LegalEntities.Id
JOIN Contracts ON LeaseFinances.ContractId = Contracts.Id AND LeaseFinances.BookingStatus = 'Commenced'
JOIN Parties ON LeaseFinances.CustomerId = Parties.Id
JOIN PayoffAssets ON Payoffs.Id = PayoffAssets.PayoffId AND PayoffAssets.IsActive=1
JOIN LeaseAssets ON PayoffAssets.LeaseAssetId = LeaseAssets.Id
JOIN Assets ON LeaseAssets.AssetId = Assets.Id AND Assets.Status ='Sold'
JOIN AssetLocations ON Assets.Id = AssetLocations.AssetId AND AssetLocations.IsActive=1
JOIN CTE_LatestAssetLocation ON AssetLocations.AssetId = CTE_LatestAssetLocation.AssetId
AND AssetLocations.EffectiveFromDate = CTE_LatestAssetLocation.LocationEffectiveDate
JOIN Locations ON AssetLocations.LocationId=Locations.Id AND Locations.IsActive=1
JOIN States ON Locations.StateId = States.Id AND States.IsActive=1
JOIN Countries ON States.CountryId = Countries.Id AND Countries.IsActive=1
JOIN DealProductTypes ON Contracts.DealProductTypeId = DealProductTypes.Id AND DealProductTypes.IsActive=1
LEFT JOIN EntityResources EntityResourceForState ON States.Id = EntityResourceForState.EntityId
AND EntityResourceForState.EntityType='State'
AND EntityResourceForState.Name='ShortName'
AND EntityResourceForState.Culture=@Culture
LEFT JOIN EntityResources EntityResourceForCountry  ON Countries.Id=EntityResourceForCountry.EntityId
AND EntityResourceForCountry.EntityType='Country'
AND EntityResourceForCountry.Name='ShortName'
AND EntityResourceForCountry.Culture=@Culture
WHERE (@FromDate IS NULL OR CAST(Payoffs.PayoffEffectiveDate AS DATE) >= CAST(@FromDate AS DATE)
AND (@ToDate IS NULL OR CAST(Payoffs.PayoffEffectiveDate AS DATE) <= CAST(@ToDate AS DATE)))
AND (@TransactionType IS NULL OR DealProductTypes.Name = @TransactionType)
AND (DealProductTypes.Name != 'Synthetic')
AND (@CustomerNumber IS NULL OR Parties.PartyNumber = @CustomerNumber)
AND (@LegalEntityNumber IS NULL OR LegalEntities.LegalEntityNumber in (select value from String_split(@LegalEntityNumber,',')))
AND (@SequenceNumber IS NULL OR Contracts.SequenceNumber = @SequenceNumber)
AND (LeaseAssets.IsActive=1 OR (LeaseAssets.IsActive=0 AND LeaseAssets.TerminationDate IS NOT NULL))
GROUP BY
Locations.Division
,Locations.City
,Parties.PartyNumber
,Parties.PartyName
,Contracts.SequenceNumber
,Contracts.Alias
,LeaseFinanceDetails.LeaseContractType
,ISNULL(EntityResourceForCountry.Value,Countries.ShortName)
,ISNULL(EntityResourceForState.Value,States.ShortName)
,Payoffs.PayoffAmount_Currency
END

GO

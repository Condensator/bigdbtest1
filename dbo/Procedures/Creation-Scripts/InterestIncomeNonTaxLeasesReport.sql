SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[InterestIncomeNonTaxLeasesReport]
(
@LegalEntityNumber NVARCHAR(MAX),
@FromDate DATE,
@ToDate DATE,
@LeaseCommencedBookingStatus NVARCHAR(MAX),
@CurrentDate DATE,
@Culture NVARCHAR(10)
)
AS
BEGIN
SET NOCOUNT ON;
SELECT P.PartyNumber 'CustomerNumber',
P.PartyName 'CustomerName',
C.SequenceNumber,
C.Alias,
LFD.LeaseContractType,
CS.ISO 'Currency',
LF.Id 'LeaseFinanceId',
C.Id 'ContractId',
PF.Id 'IsFromPayoff',
LF.BookingStatus 'BookingStatus'
INTO #TempLeaseDetails
FROM LeaseFinances LF
LEFT JOIN LeaseAmendments LA ON LF.Id = LA.CurrentLeaseFinanceId AND LA.AmendmentType = 'Payoff'
LEFT JOIN Payoffs PF ON LA.OriginalLeaseFinanceId = PF.LeaseFinanceId
JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
JOIN Contracts C ON LF.ContractId = C.Id
JOIN LegalEntities LE ON LF.LegalEntityId = LE.Id
JOIN Parties P ON LF.CustomerId = P.Id
JOIN Currencies CC ON C.CurrencyId = CC.Id
JOIN CurrencyCodes CS ON CC.CurrencyCodeId = CS.Id
WHERE LE.LegalEntityNumber = @LegalEntityNumber
AND LF.IsCurrent = 1
AND LFD.IsTaxLease = 0
AND LF.BookingStatus IN (@LeaseCommencedBookingStatus, 'FullyPaidOff')
AND (PF.Id IS NULL OR PF.PayoffEffectiveDate > @FromDate)
;
SELECT
LA.LeaseFinanceId,
MAX(AL.Id) 'MaxLocationId'
INTO #TempAssetEffectiveDates
FROM LeaseAssets LA
JOIN Assets A ON LA.AssetId = A.Id
JOIN AssetLocations AL ON A.Id = AL.AssetId
JOIN LeaseFinances LF ON LA.LeaseFinanceId = LF.Id
WHERE (LA.LeaseFinanceId IN (SELECT LeaseFinanceId FROM #TempLeaseDetails Where IsFromPayoff IS NULL))
AND LA.IsActive = 1
AND LF.ContractId IN (SELECT ContractId from #TempLeaseDetails)
AND AL.IsActive = 1
AND AL.EffectiveFromDate <= @ToDate
AND AL.EffectiveFromDate >= @FromDate
GROUP BY LA.LeaseFinanceId
SELECT LA.LeaseFinanceId,
L.Division,
L.City,
ISNULL(EntityResourceForState.Value,S.ShortName) 'State',
ISNULL(EntityResourceForCountry.Value,C.ShortName) 'Country',
SUM(AIS.Income_Amount) 'InterestIncome',
LF.ContractId
INTO #TempAssetIncomeSummary
FROM LeaseAssets LA
JOIN #TempAssetEffectiveDates TAE ON LA.LeaseFinanceId = TAE.LeaseFinanceId
JOIN Assets A ON LA.AssetId = A.Id
JOIN AssetLocations AL ON AL.Id = TAE.MaxLocationId
JOIN Locations L ON AL.LocationId = L.Id
JOIN States S ON L.StateId = S.Id
LEFT JOIN EntityResources EntityResourceForState
ON S.Id = EntityResourceForState.EntityId
AND EntityResourceForState.EntityType = 'State'
AND EntityResourceForState.Name = 'ShortName'
AND EntityResourceForState.Culture = @Culture
JOIN Countries C ON S.CountryId = C.Id
LEFT JOIN EntityResources EntityResourceForCountry
ON C.Id = EntityResourceForCountry.EntityId
AND EntityResourceForCountry.EntityType = 'Country'
AND EntityResourceForCountry.Name = 'ShortName'
AND EntityResourceForCountry.Culture = @Culture
JOIN AssetIncomeSchedules AIS ON AIS.AssetId = A.Id
JOIN LeaseIncomeSchedules LIS ON AIS.LeaseIncomeScheduleId = LIS.Id
JOIN LeaseFinances LF ON LIS.LeaseFinanceId = LF.Id
WHERE (LA.LeaseFinanceId IN (SELECT LeaseFinanceId FROM #TempLeaseDetails Where IsFromPayoff IS NULL))
AND LA.IsActive = 1
AND AIS.IsActive = 1
AND LIS.IsSchedule = 1
AND LIS.IncomeDate <= @ToDate
AND LIS.IncomeDate >= @FromDate
AND LF.ContractId IN (SELECT ContractId from #TempLeaseDetails)
GROUP BY LA.LeaseFinanceId, L.Division, L.City, ISNULL(EntityResourceForState.Value,S.ShortName), ISNULL(EntityResourceForCountry.Value,C.ShortName), LF.ContractId
SELECT
LF.ContractId,
LA.AssetId,
MAX(AL.Id) 'MaxLocationId'
INTO #TempPayoffAssetEffectiveDates
FROM LeaseAssets LA
JOIN Assets A ON LA.AssetId = A.Id
JOIN AssetLocations AL ON A.Id = AL.AssetId
JOIN LeaseFinances LF ON LA.LeaseFinanceId = LF.Id
WHERE LA.IsActive = 1
AND LF.ContractId IN (SELECT ContractId from #TempLeaseDetails Where IsFromPayoff IS NOT NULL)
AND AL.IsActive = 1
AND AL.EffectiveFromDate <= @ToDate
AND AL.EffectiveFromDate >= @FromDate
GROUP BY LF.ContractId,LA.AssetId
SELECT LA.LeaseFinanceId,
L.Division,
L.City,
ISNULL(EntityResourceForState.Value,S.ShortName) 'State',
ISNULL(EntityResourceForCountry.Value,C.ShortName) 'Country',
SUM(AIS.Income_Amount) 'InterestIncome',
LF.ContractId
INTO #TempPayoffAssetIncomeSummary
FROM LeaseAssets LA
JOIN #TempPayoffAssetEffectiveDates TPE ON LA.AssetId = TPE.AssetId
JOIN Assets A ON LA.AssetId = A.Id
JOIN AssetLocations AL ON AL.Id = TPE.MaxLocationId
JOIN Locations L ON AL.LocationId = L.Id
JOIN States S ON L.StateId = S.Id
LEFT JOIN EntityResources EntityResourceForState
ON S.Id = EntityResourceForState.EntityId
AND EntityResourceForState.EntityType = 'State'
AND EntityResourceForState.Name = 'ShortName'
AND EntityResourceForState.Culture = @Culture
JOIN Countries C ON S.CountryId = C.Id
LEFT JOIN EntityResources EntityResourceForCountry
ON C.Id = EntityResourceForCountry.EntityId
AND EntityResourceForCountry.EntityType = 'Country'
AND EntityResourceForCountry.Name = 'ShortName'
AND EntityResourceForCountry.Culture = @Culture
JOIN AssetIncomeSchedules AIS ON AIS.AssetId = A.Id
JOIN LeaseIncomeSchedules LIS ON AIS.LeaseIncomeScheduleId = LIS.Id
JOIN LeaseFinances LF ON LIS.LeaseFinanceId = LF.Id
WHERE LA.IsActive = 1
AND AIS.IsActive = 1
AND LIS.IsSchedule = 1
AND LIS.IncomeDate <= @ToDate
AND LIS.IncomeDate >= @FromDate
AND LF.ContractId IN (SELECT ContractId from #TempLeaseDetails Where IsFromPayoff IS NOT NULL)
GROUP BY LA.LeaseFinanceId, L.Division, L.City, ISNULL(EntityResourceForState.Value,S.ShortName), ISNULL(EntityResourceForCountry.Value,C.ShortName), LF.ContractId
SELECT DISTINCT Lease.CustomerNumber
,Lease.CustomerName
,Lease.SequenceNumber
,Lease.Alias
,Lease.LeaseContractType
,CASE WHEN Asset.LeaseFinanceId IS NOT NULL THEN Asset.Country ELSE PayoffAsset.Country END 'Country'
,CASE WHEN Asset.LeaseFinanceId IS NOT NULL THEN Asset.State ELSE PayoffAsset.State END 'State'
,CASE WHEN Asset.LeaseFinanceId IS NOT NULL THEN Asset.Division ELSE PayoffAsset.Division END 'Division'
,CASE WHEN Asset.LeaseFinanceId IS NOT NULL THEN Asset.City ELSE PayoffAsset.City END 'City'
,CASE WHEN Asset.LeaseFinanceId IS NOT NULL THEN Asset.InterestIncome ELSE PayoffAsset.InterestIncome END 'InterestIncome'
,Lease.Currency
FROM #TempLeaseDetails Lease
LEFT JOIN #TempAssetIncomeSummary Asset ON Lease.LeaseFinanceId = Asset.LeaseFinanceId AND Lease.IsFromPayoff IS NULL
LEFT JOIN  #TempPayoffAssetIncomeSummary PayoffAsset ON Lease.ContractId = PayoffAsset.ContractId AND Lease.IsFromPayoff IS NOT NULL
WHERE (Asset.LeaseFinanceId IS NOT NULL OR PayoffAsset.LeaseFinanceId IS NOT NULL)
;
DROP TABLE #TempLeaseDetails;
DROP TABLE #TempAssetIncomeSummary;
DROP TABLE #TempPayoffAssetIncomeSummary;
DROP TABLE #TempPayoffAssetEffectiveDates;
DROP TABLE #TempAssetEffectiveDates;
SET NOCOUNT OFF;
END

GO

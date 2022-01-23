SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[AssetLocationChangeReport]
(
@PostFromDate DATETIME,
@PostToDate DATETIME,
@FromAssetId BIGINT = NULL,
@ToAssetId BIGINT = NULL,
@LegalEntityName nvarchar(max) = NULL,
@CustomerNumber NVARCHAR(MAX) = NULL,
@SequenceNumber nvarchar(max) = NULL,
@LegalEntityId nvarchar(max) = NULL
)
AS
--DECLARE	@PostFromDate DATETIME
--DECLARE	@PostToDate DATETIME
--DECLARE	@FromAssetId BIGINT
--DECLARE	@ToAssetId BIGINT
--DECLARE	@LegalEntityId nvarchar(max)
--DECLARE	@CustomerName nvarchar(max)
--DECLARE	@SequenceNumber nvarchar(max)
--SET	@PostFromDate = '1/1/14'
--SET	@PostToDate = '12/31/15'
--SET	@FromAssetId =null --20668
--SET	@ToAssetId =null --20791
--SET	@LegalEntityId =null
--SET	@CustomerName ='Customer-01'
--SET	@SequenceNumber= null --'58-6'
BEGIN
SET NOCOUNT ON;
WITH CTE_SeqNos AS
(
SELECT Assets.Id As AssetId, Contracts.Id As ContractId, Contracts.SequenceNumber FROM Assets
JOIN LeaseAssets ON Assets.Id = LeaseAssets.AssetId
JOIN LeaseFinances ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id
JOIN Contracts ON LeaseFinances.ContractId = Contracts.Id
WHERE LeaseAssets.IsActive = 1 AND LeaseFinances.BookingStatus != 'Inactive'
UNION ALL
SELECT  Assets.Id As AssetId, Contracts.Id As ContractId, Contracts.SequenceNumber FROM Assets
JOIN CollateralAssets ON Assets.Id = CollateralAssets.AssetId
JOIN LoanFinances ON CollateralAssets.LoanFinanceId = LoanFinances.Id
JOIN Contracts ON LoanFinances.ContractId = Contracts.Id
WHERE CollateralAssets.IsActive = 1 AND LoanFinances.Status != 'Inactive'
)
SELECT AL.Id [AssetLocationId],A.Id [AssetId],AL.LocationId [LocationId],P.PartyName,AL.EffectiveFromDate,
ROW_NUMBER() OVER (PARTITION BY A.Id,EffectiveFromDate ORDER BY EffectiveFromDate DESC,AL.Id DESC) [TopLocation]
INTO #Locations
FROM AssetLocations AL
JOIN Assets A ON AL.AssetId = A.Id
JOIN Parties P ON A.CustomerId = P.Id
JOIN LegalEntities LE ON A.LegalEntityId = LE.Id
LEFT JOIN CTE_SeqNos SeqNo ON A.Id = SeqNo.AssetId
WHERE (( @ToAssetId IS NULL AND ( @FromAssetId IS NULL OR A.Id = @FromAssetId ))
OR (@ToAssetId IS NOT NULL AND A.Id >= @FromAssetId AND A.Id <= @ToAssetId ))
AND (@CustomerNumber IS NULL OR P.PartyNumber = @CustomerNumber)
AND (@LegalEntityId IS NULL OR LE.Id in (select value from String_split(@LegalEntityId,',')))
AND (@SequenceNumber IS NULL OR SeqNo.SequenceNumber = @SequenceNumber)
SELECT *
INTO #LocationsBeforeFromDate
FROM #Locations
WHERE CAST(EffectiveFromDate AS DATE) < CAST(@PostFromDate AS DATE)
SELECT AssetId,LocationId,EffectiveFromDate,AssetLocationId
INTO #LocationsBtwnFromToDate
FROM #Locations
WHERE CAST(EffectiveFromDate AS DATE) >= CAST(@PostFromDate AS DATE) AND CAST(EffectiveFromDate AS DATE) <= CAST(@PostToDate AS DATE)
SELECT #LocationsBeforeFromDate.AssetId,#LocationsBeforeFromDate.LocationId,#LocationsBeforeFromDate.EffectiveFromDate,#LocationsBeforeFromDate.AssetLocationId
INTO #OldLocation
FROM
#LocationsBeforeFromDate
JOIN
AssetLocations ON #LocationsBeforeFromDate.AssetId = AssetLocations.AssetId
WHERE TopLocation = 1 and #LocationsBeforeFromDate.AssetId IS NULL
SELECT AssetId,LocationId,EffectiveFromDate,
ROW_NUMBER() OVER (PARTITION BY AssetId ORDER BY AssetLocationId,EffectiveFromDate) [RowNumber]
INTO #AssetLocations
FROM
(
SELECT AssetId,LocationId,EffectiveFromDate,AssetLocationId
FROM #LocationsBtwnFromToDate
UNION ALL
SELECT AssetId,LocationId,EffectiveFromDate,AssetLocationId
FROM #OldLocation
)
[SumofLocations]
SELECT Assets.Id [AssetId],Parties.PartyNumber,Parties.PartyName,Assets.PartNumber,Assets.Description,cast(#AssetLocations.EffectiveFromDate as Date) [LocationChangeDate],
ISNULL(Old.AddressLine1 +
CASE WHEN Old.AddressLine2 IS NULL THEN '' ELSE + ','+ Old.AddressLine2 + ',' END+
CASE WHEN Old.City IS NULL THEN '' ELSE Old.City + ',' END +
CASE WHEN Old.Division IS NULL THEN '' ELSE Old.Division + ',' END +
CASE WHEN Old.PostalCode IS NULL THEN '' ELSE Old.PostalCode  END,'') [OldLocationId],
ISNULL(New.AddressLine1 +
CASE WHEN New.AddressLine2 IS NULL THEN '' ELSE + ',' + New.AddressLine2 + ',' END+
CASE WHEN New.City IS NULL THEN '' ELSE New.City + ',' END +
CASE WHEN New.Division IS NULL THEN '' ELSE New.Division + ',' END +
CASE WHEN New.PostalCode IS NULL THEN '' ELSE New.PostalCode  END,'') [NewLocationId]
FROM
#AssetLocations
LEFT JOIN
#AssetLocations al on #AssetLocations.AssetId = al.AssetId and al.RowNumber = (#AssetLocations.RowNumber-1)
LEFT JOIN
Locations New ON #AssetLocations.LocationId = New.Id
LEFT JOIN
Locations Old ON al.LocationId = Old.Id
JOIN
Assets ON #AssetLocations.AssetId = Assets.Id
JOIN
Parties ON Assets.CustomerId = Parties.Id
END
--DROP Table #Locations
--Drop table #AssetLocations
--Drop Table #LocationsBtwnFromToDate
--Drop Table #OldLocation
--Drop Table #LocationsBeforeFromDate

GO

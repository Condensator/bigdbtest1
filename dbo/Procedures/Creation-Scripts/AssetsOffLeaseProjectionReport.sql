SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[AssetsOffLeaseProjectionReport]
(
@LegalEntityNumber NVARCHAR(MAX),
@FromDate DATE,
@ToDate DATE,
@LeaseCommencedBookingStatus NVARCHAR(MAX),
@SyndicationApprovedStatus NVARCHAR(MAX),
@FullSaleSyndicationType NVARCHAR(MAX),
@Culture NVARCHAR(10)
)
AS
BEGIN
SET NOCOUNT ON;
SELECT A.Id 'AssetId',
LE.LegalEntityNumber 'LegalEntity',
CI.ISO,
C.SequenceNumber,
A.Alias,
AT.Name 'AssetType',
AC.Name 'Category',
A.Description,
A.InServiceDate,
LFD.MaturityDate,
CONVERT(NVARCHAR(3),(CASE WHEN LFD.LastExtensionARUpdateRunDate IS NOT NULL THEN 'Yes' ELSE 'No' END)) 'InOTP',
L.Code,
L.AddressLine1,
L.City,
ISNULL(EntityResourcesForState.Value,S.LongName) 'State',
L.PostalCode,
L.Division
INTO #TempAssetDetails
FROM Assets A
JOIN LeaseAssets LA ON A.Id = LA.AssetId AND LA.IsActive = 1
JOIN LeaseFinances LF ON LA.LeaseFinanceId = LF.Id
JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
JOIN Contracts C ON LF.ContractId = C.Id
JOIN LegalEntities LE ON LF.LegalEntityId = LE.Id
JOIN AssetTypes AT ON A.TypeId = AT.Id
LEFT JOIN AssetCategories AC ON A.AssetCategoryId = AC.Id
JOIN AssetLocations AL ON A.Id = AL.AssetId AND AL.IsCurrent = 1
JOIN Locations L ON AL.LocationId = L.Id
JOIN States S ON L.StateId = S.Id
JOIN Currencies CC ON C.CurrencyId = CC.Id
JOIN CurrencyCodes CI ON CC.CurrencyCodeId = CI.Id
LEFT JOIN EntityResources EntityResourcesForState on S.Id = EntityResourcesForState.EntityId
AND EntityResourcesForState.EntityType = 'State'
AND EntityResourcesForState.Name = 'LongName'
AND EntityResourcesForState.Culture = @Culture
LEFT JOIN ReceivableForTransfers RTF ON C.Id = RTF.ContractId AND RTF.ApprovalStatus = @SyndicationApprovedStatus
WHERE LE.LegalEntityNumber = @LegalEntityNumber
AND LF.IsCurrent = 1
AND LF.BookingStatus = @LeaseCommencedBookingStatus
AND LFD.MaturityDate >= @FromDate
AND LFD.MaturityDate <= @ToDate
AND (RTF.Id IS NULL OR RTF.ReceivableForTransferType <> @FullSaleSyndicationType)
;
SELECT AVH.AssetId,
MIN(AVH.Id) 'ValueHistoryId'
INTO #ValueHistoryRecortds
FROM AssetValueHistories AVH
WHERE AVH.AssetId in (SELECT AssetId FROM #TempAssetDetails)
AND AVH.IsSchedule = 1
AND AVH.IsLessorOwned = 1
GROUP BY AVH.AssetId
;
SELECT T.AssetId,
T.LegalEntity,
T.ISO,
T.SequenceNumber,
T.Alias,
T.AssetType,
T.Category,
T.Description,
AVH.Cost_Amount 'Cost',
T.InServiceDate,
T.MaturityDate,
T.InOTP,
T.Code,
T.AddressLine1,
T.City,
T.State,
T.PostalCode,
T.Division
FROM #TempAssetDetails T
JOIN #ValueHistoryRecortds V ON T.AssetId = V.AssetId
JOIN AssetValueHistories AVH ON V.ValueHistoryId = AVH.Id
;
DROP TABLE #TempAssetDetails;
DROP TABLE #ValueHistoryRecortds;
SET NOCOUNT OFF;
END

GO

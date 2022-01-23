SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[CreateAssetMaintenanceForRMAAssets]
(
@RMAprofileId BIGINT,
@UserId BIGINT,
@CurrentTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
SELECT 	rmaAsset.AssetId,
rmaAsset.WarehouseLocationId,
rmaAsset.EffectiveFromDate
INTO  #rmaAssets
FROM  RMAProfiles RMA
JOIN  RMAAssets rmaAsset ON RMA.Id = rmaAsset.RMAProfileId AND rmaAsset.IsActive = 1 AND rmaAsset.WarehouseLocationId is not null  AND rmaAsset.EffectiveFromDate is not null
WHERE RMA.Id = @RMAprofileId

INSERT INTO AssetMaintenances
(
AssetId,
EffectiveFromDate,
LocationId,
IsCurrent,
CreatedById,
CreatedTime,
IsActive
)
SELECT
rmaAsset.AssetId,
rmaAsset.EffectiveFromDate,
rmaAsset.WarehouseLocationId,
0,
@UserId,
@CurrentTime,
1
FROM #rmaAssets rmaAsset

UPDATE AssetMaintenances
SET IsCurrent = 0, UpdatedById = @UserId, UpdatedTime = @CurrentTime
FROM AssetMaintenances AM
JOIN #rmaAssets rmaAsset ON AM.AssetId = rmaAsset.AssetId
WHERE IsCurrent = 1
SELECT AM.AssetId, CAST(MAX(AM.EffectiveFromDate) AS DATE) [EffectiveFromDate]
INTO #MaxEffectiveFromDates
FROM AssetMaintenances AM
JOIN #rmaAssets rmaAsset ON AM.AssetId = rmaAsset.AssetId
GROUP BY AM.AssetId
SELECT MAX(AM.Id) [AssetMaintenanceId]
INTO #AssetMaintenences
FROM AssetMaintenances AM
JOIN #MaxEffectiveFromDates #MED on AM.AssetId = #MED.AssetId AND CAST(AM.EffectiveFromDate AS DATE) = #MED.EffectiveFromDate
GROUP BY #MED.AssetId,#MED.EffectiveFromDate
ORDER BY MAX(Id)
UPDATE AssetMaintenances
SET IsCurrent = 1, UpdatedById = @UserId, UpdatedTime = @CurrentTime
FROM AssetMaintenances AM
JOIN #AssetMaintenences #AM ON AM.Id = #AM.AssetMaintenanceId
END

GO

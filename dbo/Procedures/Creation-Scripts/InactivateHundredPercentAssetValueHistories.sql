SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[InactivateHundredPercentAssetValueHistories]
(
@ContractIds ContractIdTVPToInactivateAVH READONLY,
@AssetIds AssetIdTVPToInactivateTVP READONLY,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET(7)
)
AS
SET NOCOUNT ON;
BEGIN
UPDATE BookDepreciations
Set IsActive = 0 ,
UpdatedById = @UpdatedById,
UpdatedTime = @UpdatedTime
FROM BookDepreciations
JOIN @ContractIds contractIds ON BookDepreciations.ContractId = contractIds.ContractId
JOIN @AssetIds assetIds ON BookDepreciations.AssetId = assetIds.AssetId
WHERE BookDepreciations.IsLessorOwned = 0 AND BookDepreciations.IsActive = 1
UPDATE AssetValueHistories
Set IsSchedule = 0,
UpdatedById = @UpdatedById,
UpdatedTime = @UpdatedTime
FROM AssetValueHistories
JOIN @AssetIds assetIds ON AssetValueHistories.AssetId = assetIds.AssetId
WHERE AssetValueHistories.IsLessorOwned = 0
AND AssetValueHistories.SourceModule = 'FixedTermDepreciation'
AND AssetValueHistories.IsSchedule = 1
END

GO

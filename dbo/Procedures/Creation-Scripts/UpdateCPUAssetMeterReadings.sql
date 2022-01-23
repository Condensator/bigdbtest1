SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateCPUAssetMeterReadings]
(
@ContractSequenceNumber NVARCHAR(40),
@OldCPUFinanceId BIGINT,
@CurrentUserId BIGINT,
@CurrentTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
SELECT
CPUAssets.AssetId,
CPUAssets.Id CPUAssetId,
CPUSchedules.ScheduleNumber
INTO
#NewCPUAsset
FROM
CPUContracts
INNER JOIN CPUFinances	ON CPUContracts.CPUFinanceId = CPUFinances.Id
INNER JOIN CPUSchedules ON CPUFinances.Id = CPUSchedules.CPUFinanceId
INNER JOIN CPUAssets	ON CPUSchedules.Id = CPUAssets.CPUScheduleId
WHERE
CPUContracts.SequenceNumber = @ContractSequenceNumber
SELECT
CPUAssets.AssetId,
CPUAssets.Id CPUAssetId,
CPUSchedules.ScheduleNumber
INTO
#OLDCPUAsset
FROM
CPUFinances
INNER JOIN CPUSchedules	ON  CPUSchedules.CPUFinanceId = CPUFinances.Id AND CPUFinances.Id = @OldCPUFinanceId
INNER JOIN CPUAssets	ON CPUSchedules.Id = CPUAssets.CPUScheduleId
UPDATE
CPUAssetMeterReadings
SET
CPUAssetId = #NewCPUAsset.CPUAssetId,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
FROM
CPUAssetMeterReadings
INNER JOIN #OLDCPUAsset ON CPUAssetMeterReadings.CPUAssetId = #OLDCPUAsset.CPUAssetId
INNER JOIN #NewCPUAsset ON #OLDCPUAsset.AssetId = #NewCPUAsset.AssetId AND #OLDCPUAsset.ScheduleNumber = #NewCPUAsset.ScheduleNumber
UPDATE
CPUAssetMeterReadingHeaders
SET
CPUAssetId = #NewCPUAsset.CPUAssetId,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
FROM
CPUAssetMeterReadingHeaders
INNER JOIN #OLDCPUAsset ON CPUAssetMeterReadingHeaders.CPUAssetId = #OLDCPUAsset.CPUAssetId
INNER JOIN #NewCPUAsset ON #OLDCPUAsset.AssetId = #NewCPUAsset.AssetId AND #OLDCPUAsset.ScheduleNumber = #NewCPUAsset.ScheduleNumber
SET NOCOUNT OFF;
END

GO

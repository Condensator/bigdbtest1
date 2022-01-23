SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateCPUReceivableGeneratedInfo]
(
@CPUSequenceNumber  NVarChar(40),
@OldCPUFinanceId BIGINT,
@CurrentUserId BIGINT,
@CurrentTime DATETIMEOFFSET(7)
)
AS
BEGIN
SET NOCOUNT ON;
SELECT
CPUAssets.AssetId,
CPUAssets.Id AS CPUAssetId ,
CPUAssets.BaseReceivablesGeneratedTillDate,
CPUSchedules.ScheduleNumber
INTO
#NewCPUAsset
FROM
CPUContracts
INNER JOIN CPUFinances	ON CPUContracts.CPUFinanceId = CPUFinances.Id
INNER JOIN CPUSchedules ON CPUFinances.Id = CPUSchedules.CPUFinanceId
INNER JOIN CPUAssets	ON CPUSchedules.Id = CPUAssets.CPUScheduleId
WHERE
CPUContracts.SequenceNumber = @CPUSequenceNumber
AND CPUSchedules.IsActive = 1
AND CPUAssets.IsActive = 1
SELECT
CPUAssets.AssetId,
CPUAssets.Id AS CPUAssetId,
CPUAssets.BaseReceivablesGeneratedTillDate,
CPUSchedules.ScheduleNumber
INTO
#OLDCPUAsset
FROM
CPUSchedules
INNER JOIN CPUAssets	ON CPUSchedules.Id = CPUAssets.CPUScheduleId
WHERE
CPUSchedules.CPUFinanceId = @OldCPUFinanceId
AND CPUSchedules.IsActive = 1
AND CPUAssets.IsActive = 1
UPDATE
CPUAssets
SET
BaseReceivablesGeneratedTillDate = #OLDCPUAsset.BaseReceivablesGeneratedTillDate,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
FROM
CPUAssets
INNER JOIN #NewCPUAsset ON	CPUAssets.Id = #NewCPUAsset.CPUAssetId
INNER JOIN #OLDCPUAsset ON	#NewCPUAsset.AssetId = #OLDCPUAsset.AssetId
AND #NewCPUAsset.ScheduleNumber = #OLDCPUAsset.ScheduleNumber
SET NOCOUNT OFF;
END

GO

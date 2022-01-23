SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[InActivateMeterReadings]
(
@MeterReadingInfo MeterReadingInfo READONLY,
@IsEstimatedInActivation NVARCHAR(20),
@CurrentUserId BIGINT,
@CurrentTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
IF(@IsEstimatedInActivation=0)
BEGIN
SELECT * INTO #MeterReadingInfo FROM @MeterReadingInfo  WHERE CPUAssetId IS NOT NULL
INSERT INTO #MeterReadingInfo
SELECT DISTINCT MeterReadingInfo.CPUContractSequenceNumber,MeterReadingInfo.CPUScheduleNumber,CPUAssets.Id,MeterReadingInfo.EffectiveFrom
FROM @MeterReadingInfo MeterReadingInfo
INNER JOIN CPUContracts ON MeterReadingInfo.CPUContractSequenceNumber = CPUContracts.SequenceNumber
--INNER JOIN CPURestructures ON CPUContracts.Id = CPURestructures.CPUContractId
INNER JOIN CPUFinances ON CPUContracts.CPUFinanceId = CPUFinances.Id
INNER JOIN CPUSchedules ON CPUFinances.Id = CPUSchedules.CPUFinanceId AND MeterReadingInfo.CPUScheduleNumber = CPUSchedules.ScheduleNumber
INNER JOIN CPUAssets ON CPUSchedules.Id = CPUAssets.CPUScheduleId
WHERE MeterReadingInfo.CPUAssetId IS NULL AND CPUSchedules.IsActive =1 AND CPUAssets.IsActive=1
UPDATE
CPUAssetMeterReadings
SET IsActive = 0,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
FROM CPUAssetMeterReadings
INNER JOIN #MeterReadingInfo ON CPUAssetMeterReadings.CPUAssetId = #MeterReadingInfo.CPUAssetId
WHERE CPUAssetMeterReadings.IsActive =1 AND CPUAssetMeterReadings.EndPeriodDate>#MeterReadingInfo.EffectiveFrom
END
ELSE
BEGIN
SELECT * INTO #MeterReadingsToInActivate FROM @MeterReadingInfo
UPDATE CPUAssetMeterReadings
SET IsActive=0,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
FROM  CPUAssetMeterReadings
INNER JOIN #MeterReadingsToInActivate ON CPUAssetMeterReadings.CPUAssetId = #MeterReadingsToInActivate.CPUAssetId
WHERE CPUAssetMeterReadings.EndPeriodDate>=#MeterReadingsToInActivate.EffectiveFrom
END
IF OBJECT_ID('tempdb..#MeterReadingInfo', 'U') IS NOT NULL
DROP TABLE #MeterReadingInfo
IF OBJECT_ID('tempdb..#MeterReadingsToProcess', 'U') IS NOT NULL
DROP TABLE #MeterReadingsToProcess
IF OBJECT_ID('tempdb..#MeterReadingsToInActivate', 'U') IS NOT NULL
DROP TABLE #MeterReadingsToInActivate
SET NOCOUNT OFF
END

GO

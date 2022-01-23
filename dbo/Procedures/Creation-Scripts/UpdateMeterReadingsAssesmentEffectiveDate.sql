SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateMeterReadingsAssesmentEffectiveDate]
(
@ContractSequenceNumber NVARCHAR(40),
@EffectiveFrom DATETIME,
@ReadDay int,
@CurrentUserId BIGINT,
@CurrentTime DATETIMEOFFSET(7)
)
AS
BEGIN
SET NOCOUNT ON
SELECT DATEDIFF(DAY, DATEADD(DAY, 1-DAY(EndPeriodDate), EndPeriodDate),
DATEADD(MONTH, 1, DATEADD(DAY, 1-DAY(EndPeriodDate), EndPeriodDate))) AS CurrentMonthEndDay,
DATEFROMPARTS (YEAR(DATEADD(MONTH,1,EndPeriodDate)),MONTH(DATEADD(MONTH,1,EndPeriodDate)), DATEDIFF(DAY, DATEADD(DAY, 1-DAY(DATEADD(MONTH,1,EndPeriodDate)), DATEADD(MONTH,1,EndPeriodDate)),
DATEADD(MONTH, 1, DATEADD(DAY, 1-DAY(DATEADD(MONTH,1,EndPeriodDate)), DATEADD(MONTH,1,EndPeriodDate))))) AS NextMonthEndDate,CPUAssetMeterReadings.Id MeterReadingId INTO #MeterReadingInfo
FROM CPUAssetMeterReadings
INNER JOIN CPUAssets ON CPUAssetMeterReadings.CPUAssetId = CPUAssets.Id
INNER JOIN CPUSchedules ON CPUAssets.CPUScheduleId = CPUSchedules.Id
INNER JOIN CPUFinances ON CPUSchedules.CPUFinanceId = CPUFinances.Id
--INNER JOIN CPURestructures ON CPUFinances.Id = CPURestructures.OldCPUFinanceId
INNER JOIN CPUContracts ON CPUFinances.Id = CPUContracts.CPUFinanceId
WHERE CPUContracts.SequenceNumber = @ContractSequenceNumber AND CPUAssetMeterReadings.EndPeriodDate>@EffectiveFrom
UPDATE CPUAssetMeterReadings
SET AssessmentEffectiveDate = CASE
WHEN @ReadDay>=DAY(CPUAssetMeterReadings.EndPeriodDate) AND @ReadDay<=#MeterReadingInfo.CurrentMonthEndDay
THEN  DATEFROMPARTS (YEAR(CPUAssetMeterReadings.EndPeriodDate),MONTH(CPUAssetMeterReadings.EndPeriodDate),@ReadDay)
ELSE
CASE WHEN DAY(#MeterReadingInfo.NextMonthEndDate)<@ReadDay
THEN #MeterReadingInfo.NextMonthEndDate ELSE
DATEFROMPARTS (YEAR(#MeterReadingInfo.NextMonthEndDate),MONTH(#MeterReadingInfo.NextMonthEndDate),@ReadDay)
END
END,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
FROM CPUAssetMeterReadings
INNER JOIN #MeterReadingInfo ON CPUAssetMeterReadings.Id = #MeterReadingInfo.MeterReadingId
IF OBJECT_ID('tempdb..#MeterReadingInfo', 'U') IS NOT NULL
DROP TABLE #MeterReadingInfo
SET NOCOUNT OFF
END

GO

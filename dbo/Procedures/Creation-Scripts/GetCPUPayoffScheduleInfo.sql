SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetCPUPayoffScheduleInfo]
(
@CPUFinanceId BIGINT
)
AS
BEGIN
SET NOCOUNT ON;
SELECT
CPUSchedules.ScheduleNumber[ScheduleNumber],
CPUSchedules.CommencementDate[ScheduleBeginDate],
CPUBaseStructures.IsAggregate,
AssetMeterTypes.Name[MeterType],
CPUBaseStructures.BaseAmount_Amount[BaseAmount],
CPUBaseStructures.DistributionBasis[DistributionBasis],
CPUBaseStructures.IsRegularPaymentStream,
CPUBaseStructures.FrequencyStartDate,
CPUFinances.IsAdvanceBilling,
CPUFinances.BasePaymentFrequency,
CPUFinances.DueDay,
CPUBaseStructures.NumberofPayments,
NumberOfAssets = (select Count(Id) from CPUAssets where CPUScheduleId = CPUSchedules.Id And  CPUAssets.IsActive = 1 AND CPUAssets.PayoffDate Is Null)
FROM
CPUFinances
JOIN CPUSchedules ON CPUFinances.Id = CPUSchedules.CPUFinanceId
JOIN CPUBaseStructures ON CPUSchedules.Id = CPUBaseStructures.Id
JOIN AssetMeterTypes ON CPUSchedules.MeterTypeId=AssetMeterTypes.Id AND AssetMeterTypes.IsActive = 1
WHERE
CPUFinances.Id = @CPUFinanceId AND CPUSchedules.IsActive = 1
SET NOCOUNT OFF;
END

GO

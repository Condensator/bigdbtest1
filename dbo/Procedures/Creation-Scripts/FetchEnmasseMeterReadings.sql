SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[FetchEnmasseMeterReadings]
(
@InstanceId UNIQUEIDENTIFIER,
@SkipCount INT NULL,
@TakeCount INT NULL
)
AS
BEGIN
SELECT Id,EndPeriodDate,ReadDate,BeginReading,EndReading,ServiceCredits,Source,IsEstimated,MeterResetType
,IsFaulted,CPUAssetId,IsFirstReading,IsCorrection,BeginPeriodDate,EnmasseMeterReadingInstances.CPUScheduleId,CPUAssetMeterReadingHeaderId
,IsAggregate,MeterMaxReading,RowId,IsFirstReadingCorrected
,CPUOverageAssessmentId,ContractSequenceNumber,ScheduleNumber
,AssetBeginDate INTO #EnmasseMeterReadingInstances
FROM EnmasseMeterReadingInstances
INNER JOIN (SELECT DISTINCT EnmasseMeterReadingInstances.CPUScheduleId,ROW_NUMBER() OVER (ORDER BY EnmasseMeterReadingInstances.CPUScheduleId) AS ROWNUMBER
FROM EnmasseMeterReadingInstances
WHERE CPUAssetId IS NOT NULL AND
InstanceId = @InstanceId AND
IsFaulted =0
GROUP BY EnmasseMeterReadingInstances.CPUScheduleId
) AS CPUAssets ON EnmasseMeterReadingInstances.CPUScheduleId = CPUAssets.CPUScheduleId
WHERE  (ROWNUMBER BETWEEN @SkipCount +1  AND
@SkipCount + @TakeCount) AND
InstanceId = @InstanceId AND
IsFaulted =0
ORDER BY ROWNUMBER
SELECT * FROM #EnmasseMeterReadingInstances
SELECT DISTINCT CPUFinances.ReadDay,CASE WHEN CPUTransactions.TransactionType='Booking' THEN CPUTransactions.[Date] ELSE DATEADD(Day,1,CPUTransactions.Date) END AS      EffectiveFrom FROM
CPUContracts
INNER JOIN CPUTransactions ON CPUContracts.Id = CPUTransactions.CPUContractId
INNER JOIN CPUFinances ON CPUTransactions.CPUFinanceId = CPUFinances.Id
INNER JOIN #EnmasseMeterReadingInstances ON CPUContracts.SequenceNumber = #EnmasseMeterReadingInstances.ContractSequenceNumber
--To pick all paid off assets and its payoff date
;WITH CTE_DistinctCPUAssetId AS
(
SELECT DISTINCT CPUAssetId FROM #EnmasseMeterReadingInstances
)
SELECT DistinctCPUAssetId.CPUAssetId, CPUAssets.PayoffDate
FROM CTE_DistinctCPUAssetId DistinctCPUAssetId
JOIN CPUAssets ON DistinctCPUAssetId.CPUAssetId = CPUAssets.Id
WHERE CPUAssets.PayoffDate IS NOT NULL
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateIncomeSchedulesForBookDepTerminationFromGLTransfer]
(
@LeaseFinanceId BIGINT,
@SourceModule VARCHAR(100),
@TerminatedDate DATE,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
SELECT
DISTINCT
Assets.Id as AssetId
INTO #BookDepAssociatedAssets
FROM
BookDepreciations
JOIN Assets ON BookDepreciations.AssetId = Assets.Id
JOIN LeaseAssets ON Assets.Id = LeaseAssets.AssetId AND LeaseAssets.LeaseFinanceId = @LeaseFinanceId
WHERE
BookDepreciations.IsActive = 1
AND LeaseAssets.IsActive = 1
AND LeaseAssets.IsLeaseAsset = 1
AND (BookDepreciations.TerminatedDate IS NULL OR BookDepreciations.TerminatedDate >= @TerminatedDate)
AND BookDepreciations.EndDate >= @TerminatedDate
SELECT
AVH.AssetId,
AVH.BeginBookValue_Amount,
AVH.IsLessorOwned,
ROW_NUMBER() OVER(PARTITION BY AVH.AssetId, AVH.IsLessorOwned ORDER BY AVH.IncomeDate ASC) as Rank
INTO #AssetNBVSummary
FROM
AssetValueHistories AVH
JOIN #BookDepAssociatedAssets BDA  ON AVH.AssetId = BDA.AssetId
WHERE
AVH.IncomeDate >= @TerminatedDate
AND AVH.AdjustmentEntry = 0
AND AVH.IsLeaseComponent = 1
AND ((AVH.IsLessorOwned = 1 AND AVH.IsAccounted = 1 and AVH.IsLessorOwned = 1) OR (AVH.IsLessorOwned = 0 AND AVH.IsSchedule=1))
ORDER BY AVH.IncomeDate ASC
UPDATE AssetIncomeSchedules
SET
OperatingBeginNetBookValue_Amount = AssetSummary.BeginBookValue_Amount,
OperatingEndNetBookValue_Amount = AssetSummary.BeginBookValue_Amount,
Depreciation_Amount = 0.0,
UpdatedById = @UpdatedById,
UpdatedTime = @UpdatedTime
FROM
AssetIncomeSchedules AIS
INNER JOIN LeaseIncomeSchedules LISE ON AIS.LeaseIncomeScheduleId = LISE.Id
INNER JOIN #AssetNBVSummary AssetSummary ON  AIS.AssetId = AssetSummary.AssetId
WHERE
LISE.LeaseFinanceId = @LeaseFinanceId
AND AIS.IsActive = 1
AND AssetSummary.Rank = 1
AND LISE.AdjustmentEntry = 0
AND LISE.IncomeDate >= @TerminatedDate
AND LISE.IsLessorOwned = AssetSummary.IsLessorOwned
UPDATE dbo.LeaseIncomeSchedules
SET
OperatingBeginNetBookValue_Amount = LIS.OperatingBeginNetBookValue_Amount,
OperatingEndNetBookValue_Amount = LIS.OperatingEndNetBookValue_Amount,
Depreciation_Amount = LIS.Depreciation_Amount,
UpdatedById = @UpdatedById,
UpdatedTime = @UpdatedTime
FROM
(
SELECT
AIS.LeaseIncomeScheduleId,
SUM(AIS.OperatingBeginNetBookValue_Amount) [OperatingBeginNetBookValue_Amount],
SUM(AIS.OperatingEndNetBookValue_Amount) [OperatingEndNetBookValue_Amount] ,
SUM(AIS.Depreciation_Amount) [Depreciation_Amount]
FROM dbo.AssetIncomeSchedules AIS
INNER JOIN dbo.LeaseIncomeSchedules LISE ON AIS.LeaseIncomeScheduleId = LISE.Id
WHERE LISE.LeaseFinanceId = @LeaseFinanceId
AND AIS.IsActive = 1
AND LISE.AdjustmentEntry = 0
AND LISE.IncomeDate >= @TerminatedDate
GROUP BY AIS.LeaseIncomeScheduleId
) AS LIS
WHERE
LeaseIncomeSchedules.Id = LIS.LeaseIncomeScheduleId
AND LeaseIncomeSchedules.AdjustmentEntry = 0
--AND LeaseIncomeSchedules.IsLessorOwned = 1
AND LeaseIncomeSchedules.IncomeDate >= @TerminatedDate
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateOperatingNBVForLeaseIncomeScheduleFromReaccrual]
(
@LeaseFinanceId BIGINT,
@SourceModule NVARCHAR(MAX),
@ReaccrualDate DATE,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
UPDATE AssetIncomeSchedules
SET
OperatingBeginNetBookValue_Amount = AVH.BeginBookValue_Amount,
OperatingEndNetBookValue_Amount = AVH.EndBookValue_Amount,
Depreciation_Amount = AVH.Value_Amount,
UpdatedById = @UpdatedById,
UpdatedTime = @UpdatedTime
FROM  dbo.AssetIncomeSchedules AIS
INNER JOIN dbo.LeaseIncomeSchedules LISE ON AIS.LeaseIncomeScheduleId = LISE.Id
INNER JOIN dbo.AssetValueHistories AVH ON LISE.IncomeDate = AVH.IncomeDate
WHERE LISE.LeaseFinanceId = @LeaseFinanceId
AND AIS.IsActive = 1
AND AVH.SourceModuleId = @LeaseFinanceId
AND AVH.IsLessorOwned = 1
AND AVH.AssetId = AIS.AssetId
AND AVH.SourceModule = @SourceModule
AND AVH.IncomeDate >= @ReaccrualDate
UPDATE LeaseIncomeSchedules
SET
OperatingBeginNetBookValue_Amount = LIS.OperatingBeginNetBookValue_Amount,
OperatingEndNetBookValue_Amount = LIS.OperatingEndNetBookValue_Amount,
Depreciation_Amount = LIS.Depreciation_Amount,
UpdatedById = @UpdatedById,
UpdatedTime = @UpdatedTime
FROM (
SELECT
AIS.LeaseIncomeScheduleId,
SUM(AIS.OperatingBeginNetBookValue_Amount) [OperatingBeginNetBookValue_Amount],
SUM(AIS.OperatingEndNetBookValue_Amount) [OperatingEndNetBookValue_Amount] ,
SUM(AIS.Depreciation_Amount) [Depreciation_Amount]
FROM dbo.AssetIncomeSchedules AIS
INNER JOIN dbo.LeaseIncomeSchedules LISE ON AIS.LeaseIncomeScheduleId = LISE.Id
WHERE LISE.LeaseFinanceId = @LeaseFinanceId
AND AIS.IsActive = 1
AND LISE.IncomeDate >= @ReaccrualDate
GROUP BY AIS.LeaseIncomeScheduleId
) AS LIS
WHERE LeaseIncomeSchedules.Id = LIS.LeaseIncomeScheduleId
SET NOCOUNT OFF
END

GO

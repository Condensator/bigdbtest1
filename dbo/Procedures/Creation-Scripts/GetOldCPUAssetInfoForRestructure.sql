SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetOldCPUAssetInfoForRestructure]
(
@CPUFinanceId BIGINT
)
AS
BEGIN
SET NOCOUNT ON;
/*CPU Asset Info*/
SELECT
CPUSchedules.ScheduleNumber,
CPUAssets.BaseDistributionBasisAmount_Amount AS BaseDistributionBasisAmount,
CPUAssets.BaseUnits ,
CPUAssets.BaseAmount_Amount AS BaseAmount
FROM CPUAssets
JOIN CPUSchedules ON CPUAssets.CPUScheduleId = CPUSchedules.Id
WHERE CPUAssets.IsActive = 1
AND CPUSchedules.IsActive = 1
AND CPUSchedules.CPUFinanceId = @CPUFinanceId
SET NOCOUNT OFF;
END

GO

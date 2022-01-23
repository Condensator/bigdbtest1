SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetLeaseAssetsEffectiveDateInfo]
(
	@AssetIds LeaseAssetIdCollection readonly,
	@OldLeaseFinanceId BIGINT,
	@InventoryBookDepreciationType NVARCHAR(40),
	@FixedTermDepreciationType NVARCHAR(40),
	@AssetValueAdjustmentType NVARCHAR(40),
	@AssetImpairmentType NVARCHAR(40),
	@OTPDepreciationType NVARCHAR(40),
	@ResidualRecaptureType NVARCHAR(40),
	@ETCType NVARCHAR(40),
	@LeaseBookingType NVARCHAR(40),
	@IsRebook BIT
)
AS
BEGIN

SET NOCOUNT ON;

DECLARE @SourceModules SourceModuleList

DECLARE @SourceModuleId BIGINT

SELECT * INTO #Assets FROM @AssetIds

If(@IsRebook = 1)
BEGIN
	INSERT INTO @SourceModules VALUES (@InventoryBookDepreciationType),	(@FixedTermDepreciationType), (@ETCType), (@LeaseBookingType)
	SET @SourceModuleId = @OldLeaseFinanceId
END
ELSE
BEGIN
	INSERT INTO @SourceModules VALUES (@InventoryBookDepreciationType)
	SET @SourceModuleId = 0
END

SELECT
	RANK() OVER (PARTITION BY AssetValueHistories.AssetId ORDER BY AssetValueHistories.incomeDate DESC, AssetValueHistories.Id DESC) AS RankInfo,
	AssetValueHistories.Id
INTO #AssetInfo
FROM
AssetValueHistories
JOIN #Assets AssetIds ON AssetValueHistories.AssetId = AssetIds.AssetId
WHERE AssetValueHistories.IsSchedule=1
AND AssetValueHistories.SourceModule NOT IN (SELECT * FROM @SourceModules)
AND AssetValueHistories.SourceModuleId != @SourceModuleId

SELECT
	AssetValueHistories.AssetId,
	CASE WHEN AssetValueHistories.SourceModule IN (@FixedTermDepreciationType,@AssetValueAdjustmentType,@AssetImpairmentType,@OTPDepreciationType,@ResidualRecaptureType)
		THEN DATEADD(DAY,1,AssetValueHistories.IncomeDate)
		ELSE
		AssetValueHistories.IncomeDate
	END AS EffectiveDate
FROM AssetValueHistories
JOIN #AssetInfo CTE_AssetInfo ON AssetValueHistories.Id = CTE_AssetInfo.Id
WHERE CTE_AssetInfo.RankInfo =1

DROP TABLE #Assets
DROP TABLE #AssetInfo

SET NOCOUNT OFF;
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetSKUProportions]
(
	@AssetIds AssetIds ReadOnly,
	@IncomeDate Date NULL
)
AS
BEGIN
SET NOCOUNT ON


SELECT SKUValueProportions.AssetSKUId,AssetValueHistories.AssetId,SKUValueProportions.Value_Amount, RowNumber = ROW_NUMBER() OVER (PARTITION BY SKUValueProportions.AssetSKUId ORDER BY SKUValueProportions.Id DESC) into #LatestSKUValueProportion
FROM  @AssetIds Assets 
INNER JOIN AssetValueHistories ON Assets.AssetId = AssetValueHistories.AssetId
INNER JOIN SKUValueProportions ON AssetValueHistories.Id = SKUValueProportions.AssetValueHistoryId
WHERE (@IncomeDate IS NULL OR AssetValueHistories.IncomeDate <= @IncomeDate) AND AssetValueHistories.IsSchedule = 1AND SKUValueProportions.IsActive = 1
ORDER BY AssetValueHistories.IncomeDate DESC, SKUValueProportions.Id DESC

SELECT AssetSKUId,AssetId,Value_Amount 'SKUValue' FROM #LatestSKUValueProportion WHERE RowNumber=1 ORDER BY assetId,assetSKUid

IF OBJECT_ID('tempdb..#LatestSKUValueProportion') IS NOT NULL
    DROP TABLE #LatestSKUValueProportion

SET NOCOUNT OFF

END

GO

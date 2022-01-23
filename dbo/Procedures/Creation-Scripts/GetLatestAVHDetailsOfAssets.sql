SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetLatestAVHDetailsOfAssets]
(
@AssetInputs AssetInput_AVHCreationForCapitalLeasePayoff READONLY
)
AS
BEGIN
SET NOCOUNT ON;

	SELECT 
		AssetId = AD.AssetId,
		NBV = AVH.EndBookValue_Amount,
		Cost = AVH.Cost_Amount,
		IsLessorOwned = AVH.IsLessorOwned,
	    Row_Num = ROW_NUMBER() OVER (PARTITION BY AVH.AssetId, AVH.IsLessorOwned ORDER BY AVH.IncomeDate DESC, AVH.Id DESC) 
	INTO #AssetValueHistoriesInfo
	FROM AssetValueHistories AVH
	JOIN @AssetInputs AD ON AVH.AssetId = AD.AssetId
	WHERE AVH.IncomeDate <= AD.PayoffEffectiveDate
	AND AVH.IsSchedule=1; 

	SELECT 
		AssetId,
		Cost,
		NBV,
		IsLessorOwned
	FROM #AssetValueHistoriesInfo
	WHERE Row_Num = 1;

	DROP TABLE #AssetValueHistoriesInfo

END

GO

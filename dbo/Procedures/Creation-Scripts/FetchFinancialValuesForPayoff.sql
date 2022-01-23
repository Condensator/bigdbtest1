SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[FetchFinancialValuesForPayoff] (
	@AssetIds AssetIdsWithEffectiveDate ReadOnly
)
AS
BEGIN
	SET NOCOUNT ON

	SELECT * INTO #AssetIds FROM @AssetIds;
	
	WITH CTE_AssetIncomeSchedule AS (
		SELECT ROW_NUMBER() OVER ( PARTITION BY ais.AssetId ORDER BY lis.IncomeDate ASC) AssetIncomeScheduleRank,
			ais.AssetId, ais.OperatingBeginNetBookValue_Amount, ais.LeaseBeginNetBookValue_Amount, ais.FinanceBeginNetBookValue_Amount
		FROM #AssetIds assetId
		JOIN AssetIncomeSchedules ais ON ais.AssetId = assetId.Id
		JOIN LeaseIncomeSchedules lis ON lis.Id = ais.LeaseIncomeScheduleId
		WHERE ais.IsActive = 1
		AND lis.IsSchedule = 1
		AND lis.IsLessorOwned = 1
		AND lis.IncomeDate >= assetId.EffectiveDate
	)
	SELECT AssetId,
		OperatingBeginNBV = OperatingBeginNetBookValue_Amount, 
		LeaseBeginNBV = LeaseBeginNetBookValue_Amount,
		FinanceBeginNBV = FinanceBeginNetBookValue_Amount
	FROM CTE_AssetIncomeSchedule
	WHERE AssetIncomeScheduleRank = 1
	
END

GO

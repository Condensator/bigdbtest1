SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[UpdateLeaseAssetRelatedFieldsFromSyndication]
(
	@ContractId bigint,	
	@LeaseFinanceId bigint,
	@AssetYieldTVP AssetYieldTVP READONLY,
	@UpdatedById BIGINT,
	@UpdatedTime DATETIMEOFFSET
)
AS
	BEGIN
SET NOCOUNT ON
SELECT
	AssetIncomeSchedules.AssetId,
	SUM(AssetIncomeSchedules.Income_Amount) Income,
	SUM(AssetIncomeSchedules.ResidualIncome_Amount) ResidualIncome,
	SUM(AssetIncomeSchedules.FinanceIncome_Amount)  FinanceIncome,
	SUM(AssetIncomeSchedules.LeaseIncome_Amount)  LeaseIncome,
	SUM(AssetIncomeSchedules.FinanceResidualIncome_Amount) FinanceResidualIncome ,
	SUM(AssetIncomeSchedules.LeaseResidualIncome_Amount) LeaseResidualIncome INTO #AssetIncomeSummary
	
FROM AssetIncomeSchedules  With (ForceSeek)   
INNER JOIN LeaseIncomeSchedules  With (ForceSeek)   
	ON AssetIncomeSchedules.LeaseIncomeScheduleId = LeaseIncomeSchedules.Id
INNER JOIN LeaseFinances
	ON LeaseIncomeSchedules.LeaseFinanceId = LeaseFinances.Id
WHERE LeaseFinances.ContractId = @ContractId
AND AssetIncomeSchedules.IsActive = 1
AND LeaseIncomeSchedules.IsSchedule = 1
AND LeaseIncomeSchedules.IsLessorOwned = 1
AND LeaseIncomeSchedules.IncomeType = 'FixedTerm'
GROUP BY AssetIncomeSchedules.AssetId

IF EXISTS (SELECT
		*
	FROM #AssetIncomeSummary)
BEGIN
UPDATE LeaseAssetIncomeDetails
SET	Income_Amount = #AssetIncomeSummary.Income,
	ResidualIncome_Amount = #AssetIncomeSummary.ResidualIncome,
	FinanceIncome_Amount = #AssetIncomeSummary.FinanceIncome,
	LeaseIncome_Amount = #AssetIncomeSummary.LeaseIncome,
	FinanceResidualIncome_Amount = #AssetIncomeSummary.FinanceResidualIncome,
	LeaseResidualIncome_Amount = #AssetIncomeSummary.LeaseResidualIncome,
	AssetYieldForLeaseComponents = ISNULL(YieldTVP.Yield, LeaseAssetIncomeDetails.AssetYieldForLeaseComponents),
	UpdatedById = @UpdatedById,
	UpdatedTime = @UpdatedTime
FROM #AssetIncomeSummary
INNER JOIN LeaseAssets With (ForceSeek)
	ON #AssetIncomeSummary.AssetId = LeaseAssets.AssetId
	AND LeaseAssets.IsActive = 1
	AND LeaseAssets.LeaseFinanceId = @LeaseFinanceId
INNER JOIN LeaseAssetIncomeDetails ON LeaseAssets.Id = LeaseAssetIncomeDetails.Id
LEFT JOIN @AssetYieldTVP YieldTVP
	ON YieldTVP.AssetId = LeaseAssets.AssetId

END
ELSE
BEGIN
UPDATE LeaseAssetIncomeDetails
SET	Income_Amount = 0.00,
	ResidualIncome_Amount = 0.00,
	LeaseIncome_Amount = 0.00,
	LeaseResidualIncome_Amount = 0.00,
	FinanceIncome_Amount = 0.00,
	FinanceResidualIncome_Amount = 0.00,
	UpdatedById = @UpdatedById,
	UpdatedTime = @UpdatedTime
FROM LeaseAssetIncomeDetails
INNER JOIN LeaseAssets ON LeaseAssetIncomeDetails.Id = LeaseAssets.Id
WHERE LeaseFinanceId = @LeaseFinanceId
AND IsActive = 1
END

END

GO

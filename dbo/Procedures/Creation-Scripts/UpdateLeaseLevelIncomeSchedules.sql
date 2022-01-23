SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateLeaseLevelIncomeSchedules]
(
@LeaseFinanceId bigint
)
AS
BEGIN
SET NOCOUNT ON
SELECT
LeaseIncomeSchedules.Id as 'LeaseIncomeScheduleId',
SUM(AssetIncomeSchedules.BeginNetBookValue_Amount) as 'BeginNBV',
SUM(AssetIncomeSchedules.EndNetBookValue_Amount) as 'EndNBV',
SUM(AssetIncomeSchedules.RentalIncome_Amount) as 'RentalIncome',
SUM(AssetIncomeSchedules.DeferredRentalIncome_Amount) as 'DeferredRentalIncome',
SUM(AssetIncomeSchedules.Income_Amount) as 'Income',
SUM(AssetIncomeSchedules.IncomeAccrued_Amount) as 'IncomeAccrued',
SUM(AssetIncomeSchedules.IncomeBalance_Amount) as 'IncomeBalance',
SUM(AssetIncomeSchedules.ResidualIncome_Amount) as 'ResidualIncome',
SUM(AssetIncomeSchedules.ResidualIncomeBalance_Amount) as 'ResidualIncomeBalance',
SUM(AssetIncomeSchedules.Payment_Amount) as 'PaymentAmount'
INTO #LeaseIncomeSummary
FROM
AssetIncomeSchedules WITH (NOLOCK)
JOIN LeaseIncomeSchedules WITH (NOLOCK)  ON AssetIncomeSchedules.LeaseIncomeScheduleId = LeaseIncomeSchedules.Id
WHERE
AssetIncomeSchedules.IsActive = 1
and LeaseIncomeSchedules.IsAccounting = 1
and LeaseIncomeSchedules.IsSchedule = 1
and LeaseIncomeSchedules.LeaseFinanceId = @LeaseFinanceId
GROUP BY LeaseIncomeSchedules.Id
UPDATE LeaseIncomeSchedules
SET
BeginNetBookValue_Amount = #LeaseIncomeSummary.BeginNBV,
EndNetBookValue_Amount = #LeaseIncomeSummary.EndNBV,
RentalIncome_Amount  = #LeaseIncomeSummary.RentalIncome,
DeferredRentalIncome_Amount = #LeaseIncomeSummary.DeferredRentalIncome,
Income_Amount = #LeaseIncomeSummary.Income,
IncomeAccrued_Amount = #LeaseIncomeSummary.IncomeAccrued,
IncomeBalance_Amount = #LeaseIncomeSummary.IncomeBalance,
ResidualIncome_Amount = #LeaseIncomeSummary.ResidualIncome,
ResidualIncomeBalance_Amount = #LeaseIncomeSummary.ResidualIncomeBalance,
Payment_Amount = #LeaseIncomeSummary.PaymentAmount
FROM
#LeaseIncomeSummary
JOIN LeaseIncomeSchedules WITH (NOLOCK) ON #LeaseIncomeSummary.LeaseIncomeScheduleId = LeaseIncomeSchedules.Id
IF OBJECT_ID('tempdb..#LeaseIncomeSummary') IS NOT NULL
DROP TABLE #LeaseIncomeSummary
END

GO

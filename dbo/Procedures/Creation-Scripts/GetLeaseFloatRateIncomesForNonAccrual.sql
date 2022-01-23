SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[GetLeaseFloatRateIncomesForNonAccrual]
(
	@ContractIds ContractIds READONLY,
	@FetchAssetFloatRateIncomeSchedules BIT
)
AS 
BEGIN
	SET NOCOUNT ON;

	SELECT * INTO #ContractIds FROM @ContractIds

	SELECT 
		LF.ContractId,
		LeaseFinanceId,
		LFI.Id AS Id,
		IncomeDate,
		CustomerIncomeAmount_Amount AS CustomerIncomeAmount,
		CustomerIncomeAccruedAmount_Amount AS CustomerIncomeAccruedAmount,
		CustomerReceivableAmount_Amount AS CustomerReceivableAmount,
		IsGLPosted,
		IsAccounting,
		IsScheduled,
		IsNonAccrual,
		AdjustmentEntry,
		InterestRate,
		FloatRateIndexDetailId
	INTO #LeaseFloatRateIncomes
	FROM #ContractIds 
	JOIN LeaseFinances LF ON #ContractIds.Id = LF.ContractId
	JOIN LeaseFloatRateIncomes LFI ON LF.Id = LFI.LeaseFinanceId
	WHERE (LFI.IsAccounting=1 OR LFI.IsScheduled=1) AND LFI.IsLessorOwned=1

	SELECT * FROM #LeaseFloatRateIncomes

	IF (@FetchAssetFloatRateIncomeSchedules = 1)
	BEGIN
		SELECT 
			AFI.Id,
			AssetId,
			LeaseFloatRateIncomeId,
			CustomerIncomeAmount_Amount AS CustomerIncomeAmount,
			CustomerIncomeAccruedAmount_Amount AS CustomerIncomeAccruedAmount,
			CustomerReceivableAmount_Amount AS CustomerReceivableAmount
		FROM #LeaseFloatRateIncomes LFI
		JOIN AssetFloatRateIncomes AFI ON LFI.Id = AFI.LeaseFloatRateIncomeId
		WHERE AFI.IsActive=1
	END

	DROP TABLE #LeaseFloatRateIncomes
	DROP TABLE #ContractIds
END

GO

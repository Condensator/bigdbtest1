SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetOTPLeaseIncomeSchedules] 
(
	@LeaseInputs LeaseInput_LeaseIncomeAdjustment READONLY,
	@LeaseOTPIncomeTypeValue NVARCHAR(40)
)
AS
BEGIN
SET NOCOUNT ON;


	SELECT 
		LeaseIncomeScheduleId = LIS.Id,
		LeaseFinanceId = LIS.LeaseFinanceId,
		IncomeDate = LIS.IncomeDate,
		LI.AdjustmentStartDate,
		AccountingTreatment = LIS.AccountingTreatment,
		PostDate = LIS.PostDate,
		IsSchedule = LIS.IsSchedule,
		IsAccounting = LIS.IsAccounting,
		IsGLPosted = LIS.IsGLPosted,
		IsNonAccrual = LIS.IsNonAccrual,
		IsLessorOwned = LIS.IsLessorOwned,
		IncomeType = LIS.IncomeType,
		Income = LIS.Income_Amount,
		RentalIncome = LIS.RentalIncome_Amount,
		ResidualIncome = LIS.ResidualIncome_Amount,
		Depreciation = LIS.Depreciation_Amount
	INTO #OTPLeaseIncomeSchedules
	FROM LeaseIncomeSchedules LIS
	JOIN LeaseFinances LF ON LIS.LeaseFinanceId  = LF.Id
	JOIN @LeaseInputs LI ON LI.ContractId = LF.ContractId
	WHERE
	(LIS.IsSchedule = 1 OR LIS.IsAccounting = 1)
	AND LIS.IncomeType = @LeaseOTPIncomeTypeValue
	AND LIS.IncomeDate > LI.AdjustmentStartDate
	AND LIS.AdjustmentEntry = 0;

	SELECT 
		LeaseIncomeScheduleId = LIS.LeaseIncomeScheduleId,
		AssetId = AIS.AssetId,
		IsLeaseAsset = LA.IsLeaseAsset,
		Income = AIS.Income_Amount,
		RentalIncome = AIS.RentalIncome_Amount,
		ResidualIncome = AIS.ResidualIncome_Amount,
		Depreciation = AIS.Depreciation_Amount
	INTO #OTPAssetIncomeSchedules
	FROM AssetIncomeSchedules AIS
	JOIN #OTPLeaseIncomeSchedules LIS ON AIS.LeaseIncomeScheduleId = LIS.LeaseIncomeScheduleId
	JOIN LeaseAssets LA ON AIS.AssetId = LA.AssetId AND LIS.LeaseFinanceId = LA.LeaseFinanceId
	WHERE AIS.IsActive = 1
	AND LIS.IncomeDate > LIS.AdjustmentStartDate


	SELECT DISTINCT LegalEntityId
	INTO #DistinctLegalEntities
	FROM @LeaseInputs
	
	SELECT 
		FromDate = GLFinancialOpenPeriods.FromDate,
		ToDate = GLFinancialOpenPeriods.ToDate,
		LegalEntityId = GLFinancialOpenPeriods.LegalEntityId
	INTO #LegalEntityGLFinancialOpenPeriods
	FROM GLFinancialOpenPeriods
	JOIN #DistinctLegalEntities ON #DistinctLegalEntities.LegalEntityId = GLFinancialOpenPeriods.LegalEntityId
	WHERE GLFinancialOpenPeriods.IsCurrent = 1

	SELECT * FROM #OTPLeaseIncomeSchedules;
	SELECT * FROM #OTPAssetIncomeSchedules;
	SELECT * FROM #LegalEntityGLFinancialOpenPeriods;

	DROP TABLE #DistinctLegalEntities;
	DROP TABLE #OTPLeaseIncomeSchedules;
	DROP TABLE #OTPAssetIncomeSchedules;
	DROP TABLE #LegalEntityGLFinancialOpenPeriods;


END

GO

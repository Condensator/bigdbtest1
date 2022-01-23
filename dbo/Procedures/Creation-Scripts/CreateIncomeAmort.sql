SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[CreateIncomeAmort]
(
	@LeaseIncomeAmorts LeaseIncomeAmortTVP READONLY,
	@AssetIncomeAmorts AssetIncomeAmortTVP READONLY,
	@CreatedById BIGINT,
	@CreatedTime DATETIMEOFFSET(7)
)
AS

SET NOCOUNT ON;

CREATE TABLE #PersistedIncomeSchedule 
(
	[LeaseIncomeKey] BIGINT,
	[Id] BIGINT
)


MERGE LeaseIncomeSchedules LIS
USING @LeaseIncomeAmorts LAI
ON 1 = 0
WHEN NOT MATCHED
THEN 
INSERT(
	IncomeDate
	, IncomeType
	, IsGLPosted
	, AccountingTreatment
	, IsAccounting
	, IsSchedule
	, LeaseModificationType
	, LeaseModificationID
	, IsLessorOwned
	, IsNonAccrual
	, BeginNetBookValue_Amount
	, BeginNetBookValue_Currency
	, EndNetBookValue_Amount
	, EndNetBookValue_Currency
	, OperatingBeginNetBookValue_Amount
	, OperatingBeginNetBookValue_Currency
	, OperatingEndNetBookValue_Amount
	, OperatingEndNetBookValue_Currency
	, Depreciation_Amount
	, Depreciation_Currency
	, Income_Amount
	, Income_Currency
	, IncomeAccrued_Amount
	, IncomeAccrued_Currency
	, IncomeBalance_Amount
	, IncomeBalance_Currency
	, RentalIncome_Amount
	, RentalIncome_Currency
	, DeferredRentalIncome_Amount
	, DeferredRentalIncome_Currency
	, ResidualIncome_Amount
	, ResidualIncome_Currency
	, ResidualIncomeBalance_Amount
	, ResidualIncomeBalance_Currency
	, Payment_Amount
	, Payment_Currency
	, PostDate
	, CreatedById
	, CreatedTime
	, LeaseFinanceId
	, FinanceBeginNetBookValue_Amount
	, FinanceBeginNetBookValue_Currency
	, FinanceEndNetBookValue_Amount
	, FinanceEndNetBookValue_Currency
	, FinanceIncome_Amount
	, FinanceIncome_Currency
	, FinanceIncomeAccrued_Amount
	, FinanceIncomeAccrued_Currency
	, FinanceIncomeBalance_Amount
	, FinanceIncomeBalance_Currency
	, FinanceRentalIncome_Amount
	, FinanceRentalIncome_Currency
	, FinanceDeferredRentalIncome_Amount
	, FinanceDeferredRentalIncome_Currency
	, FinanceResidualIncome_Amount
	, FinanceResidualIncome_Currency
	, FinanceResidualIncomeBalance_Amount
	, FinanceResidualIncomeBalance_Currency
	, FinancePayment_Amount
	, FinancePayment_Currency
	, DeferredSellingProfitIncome_Amount
	, DeferredSellingProfitIncome_Currency
	, DeferredSellingProfitIncomeBalance_Amount
	, DeferredSellingProfitIncomeBalance_Currency
	, IsReclassOTP
	, AdjustmentEntry
) 
VALUES 
(
	LAI.IncomeDate
	, LAI.IncomeType
	, LAI.IsGLPosted
	, LAI.AccountingTreatment
	, LAI.IsAccounting
	, LAI.IsSchedule
	, LAI.LeaseModificationType
	, LAI.LeaseModificationID
	, LAI.IsLessorOwned
	, LAI.IsNonAccrual
	, LAI.BeginNBV
	, LAI.Currency
	, LAI.EndNBV
	, LAI.Currency
	, LAI.OperatingBeginNBV
	, LAI.Currency
	, LAI.OperatingEndNBV
	, LAI.Currency
	, LAI.Depreciation
	, LAI.Currency
	, LAI.Income
	, LAI.Currency
	, LAI.IncomeAccrued
	, LAI.Currency
	, LAI.IncomeBalance
	, LAI.Currency
	, LAI.RentalIncome
	, LAI.Currency
	, LAI.DeferredRentalIncome
	, LAI.Currency
	, LAI.ResidualIncome
	, LAI.Currency
	, LAI.ResidualIncomeBalance
	, LAI.Currency
	, LAI.Payment
	, LAI.Currency
	, LAI.PostDate
	, @CreatedById
	, @CreatedTime
	, LAI.LeaseFinanceId
	, LAI.FinanceBeginNBV
	, LAI.Currency
	, LAI.FinanceEndNBV
	, LAI.Currency
	, LAI.FinanceIncome
	, LAI.Currency
	, LAI.FinanceIncomeAccrued
	, LAI.Currency
	, LAI.FinanceIncomeBalance
	, LAI.Currency
	, LAI.FinanceRentalIncome
	, LAI.Currency
	, LAI.FinanceDeferredRentalIncome
	, LAI.Currency
	, LAI.FinanceResidualIncome
	, LAI.Currency
	, LAI.FinanceResidualIncomeBalance
	, LAI.Currency
	, LAI.FinancePayment
	, LAI.Currency
	, LAI.DSPIncome
	, LAI.Currency
	, LAI.DSPIncomeBalance
	, LAI.Currency
	, LAI.IsReclassOTP
	, LAI.AdjustmentEntry
)
OUTPUT LAI.[Key] AS [LeaseIncomeKey], INSERTED.Id AS [Id] INTO #PersistedIncomeSchedule;




INSERT INTO AssetIncomeSchedules (
	BeginNetBookValue_Amount,
	BeginNetBookValue_Currency,
	EndNetBookValue_Amount,
	EndNetBookValue_Currency,
	Income_Amount,
	Income_Currency,
	IncomeAccrued_Amount,
	IncomeAccrued_Currency,
	IncomeBalance_Amount,
	IncomeBalance_Currency,
	ResidualIncome_Amount,
	ResidualIncome_Currency,
	ResidualIncomeBalance_Amount,
	ResidualIncomeBalance_Currency,
	OperatingBeginNetBookValue_Amount,
	OperatingBeginNetBookValue_Currency,
	OperatingEndNetBookValue_Amount,
	OperatingEndNetBookValue_Currency,
	Depreciation_Amount,
	Depreciation_Currency,
	RentalIncome_Amount,
	RentalIncome_Currency,
	DeferredRentalIncome_Amount,
	DeferredRentalIncome_Currency,
	Payment_Amount,
	Payment_Currency,
	DeferredSellingProfitIncome_Amount,
	DeferredSellingProfitIncome_Currency,
	DeferredSellingProfitIncomeBalance_Amount,
	DeferredSellingProfitIncomeBalance_Currency,
	IsActive,
	CreatedById,
	CreatedTime,
	AssetId,
	LeaseIncomeScheduleId,
	
	 /*Finance component fields*/
	FinanceBeginNetBookValue_Amount,
    FinanceBeginNetBookValue_Currency,
    FinanceEndNetBookValue_Amount,
    FinanceEndNetBookValue_Currency,
    FinancePayment_Amount,
    FinancePayment_Currency,
    FinanceIncome_Amount,
    FinanceIncome_Currency,
    FinanceIncomeAccrued_Amount,
    FinanceIncomeAccrued_Currency,
    FinanceIncomeBalance_Amount,
    FinanceIncomeBalance_Currency,
    FinanceResidualIncome_Amount,
    FinanceResidualIncome_Currency,
    FinanceResidualIncomeBalance_Amount,
    FinanceResidualIncomeBalance_Currency,
    FinanceRentalIncome_Amount,
    FinanceRentalIncome_Currency,
    FinanceDeferredRentalIncome_Amount,
    FinanceDeferredRentalIncome_Currency,
	/*Lease component fields*/
	LeaseBeginNetBookValue_Amount,
	LeaseBeginNetBookValue_Currency,
    LeaseEndNetBookValue_Amount,
    LeaseEndNetBookValue_Currency,
    LeasePayment_Amount,
    LeasePayment_Currency,
    LeaseIncome_Amount,
    LeaseIncome_Currency,
    LeaseIncomeAccrued_Amount,
    LeaseIncomeAccrued_Currency,
    LeaseIncomeBalance_Amount,
    LeaseIncomeBalance_Currency,
    LeaseResidualIncome_Amount,
    LeaseResidualIncome_Currency,
    LeaseResidualIncomeBalance_Amount,
    LeaseResidualIncomeBalance_Currency,
    LeaseRentalIncome_Amount,
    LeaseRentalIncome_Currency,
    LeaseDeferredRentalIncome_Amount,
    LeaseDeferredRentalIncome_Currency
)
SELECT 
	AIA.BeginNBV,
	AIA.Currency,
	AIA.EndNBV,
	AIA.Currency,
	AIA.Income,
	AIA.Currency,
	AIA.IncomeAccrued,
	AIA.Currency,
	AIA.IncomeBalance,
	AIA.Currency,
	AIA.ResidualIncome,
	AIA.Currency, 
	AIA.ResidualIncomeBalance,
	AIA.Currency,
	AIA.OperatingBeginNBV,
	AIA.Currency,
	AIA.OperatingEndNBV,
	AIA.Currency,
	AIA.Depreciation,
	AIA.Currency,
	AIA.RentalIncome,
	AIA.Currency,
	AIA.DeferredRentalIncome,
	AIA.Currency,
	AIA.Payment,
	AIA.Currency,
	AIA.DSPIncome,
	AIA.Currency,
	AIA.DSPIncomeBalance,
	AIA.Currency,
	AIA.IsActive,
	@CreatedById, 
	@CreatedTime, 
	AIA.AssetId,
	#PersistedIncomeSchedule.Id,

	/*Finance component fields*/
	AIA.FinanceBeginNBV,
    AIA.Currency,
    AIA.FinanceEndNBV,
    AIA.Currency,
    AIA.FinancePayment,
    AIA.Currency,
    AIA.FinanceIncome,
    AIA.Currency,
    AIA.FinanceIncomeAccrued,
    AIA.Currency,
    AIA.FinanceIncomeBalance,
    AIA.Currency,
    AIA.FinanceResidualIncome,
    AIA.Currency,
    AIA.FinanceResidualIncomeBalance,
    AIA.Currency,
    AIA.FinanceRentalIncome,
    AIA.Currency,
    AIA.FinanceDeferredRentalIncome,
    AIA.Currency,

	/*Lease component fields*/
	AIA.LeaseBeginNBV,
    AIA.Currency,
    AIA.LeaseEndNBV,
    AIA.Currency,
    AIA.LeasePayment,
    AIA.Currency,
    AIA.LeaseIncome,
    AIA.Currency,
    AIA.LeaseIncomeAccrued,
    AIA.Currency,
    AIA.LeaseIncomeBalance,
    AIA.Currency,
    AIA.LeaseResidualIncome,
    AIA.Currency,
    AIA.LeaseResidualIncomeBalance,
    AIA.Currency,
    AIA.LeaseRentalIncome,
    AIA.Currency,
    AIA.LeaseDeferredRentalIncome,
    AIA.Currency
FROM @AssetIncomeAmorts AIA 
JOIN #PersistedIncomeSchedule ON AIA.LeaseIncomeKey =#PersistedIncomeSchedule.LeaseIncomeKey


GO

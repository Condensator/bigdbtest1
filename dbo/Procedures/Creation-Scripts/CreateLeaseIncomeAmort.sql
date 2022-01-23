SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CreateLeaseIncomeAmort]
(
@LeaseIncomeAmorts LeaseIncomeAmortTVP READONLY,
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET(7)
)
AS
SET NOCOUNT ON;
CREATE TABLE #PersistedIncomeSchedule
(
[Key] BIGINT,
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
OUTPUT LAI.[Key] AS [Key], INSERTED.Id AS [Id] INTO #PersistedIncomeSchedule;
SELECT * FROM #PersistedIncomeSchedule

GO

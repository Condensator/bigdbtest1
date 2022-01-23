SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FillFloatRateIncome](
@ContractId BIGINT,
@StartDate DATE,
@PreviousStartDate DATE,
@LeaseFinanceId BIGINT)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
--GetInterestRateData
--_pricingInterestRates
SELECT
EffectiveDate = InterestRateDetails.EffectiveDate,
InterestRate = InterestRateDetails.InterestRate / 100,
IsSystemGenerated = LeaseInterestRates.IsSystemGenerated,
InterestRateDetailId = LeaseInterestRates.InterestRateDetailId,
IsFloatRate = InterestRateDetails.IsFloatRate
FROM LeaseFinanceDetails
JOIN LeaseInterestRates ON LeaseFinanceDetails.Id = LeaseInterestRates.LeaseFinanceDetailId
JOIN InterestRateDetails ON LeaseInterestRates.InterestRateDetailId = InterestRateDetails.Id
WHERE LeaseInterestRates.IsPricingInterestRate = 1
AND IsActive = 1
AND LeaseFinanceDetails.Id = @LeaseFinanceId
--GetIncomeDates
--_leaseIncomeSchedules
SELECT Id = LeaseIncomeSchedules.Id,
IncomeDate = LeaseIncomeSchedules.IncomeDate,
IsLessorOwned = LeaseIncomeSchedules.IsLessorOwned,
LeaseFinanceId = LeaseIncomeSchedules.LeaseFinanceId
FROM LeaseIncomeSchedules
JOIN LeaseFinances ON LeaseIncomeSchedules.LeaseFinanceId = LeaseFinances.Id
WHERE LeaseFinances.ContractId = @ContractId
AND LeaseIncomeSchedules.IncomeDate >= @PreviousStartDate
AND LeaseIncomeSchedules.IsSchedule = 1
ORDER BY LeaseIncomeSchedules.IncomeDate
--GetLastFloatRateRecords
--_lastLeaseFloatRateRecord
SELECT TOP 1
Id = LeaseFloatRateIncomes.Id,
CustomerIncomeAccruedAmount = CustomerIncomeAccruedAmount_Amount
FROM LeaseFloatRateIncomes
JOIN LeaseFinances ON LeaseFloatRateIncomes.LeaseFinanceId = LeaseFinances.Id
WHERE LeaseFloatRateIncomes.IsScheduled = 1
AND LeaseFinances.ContractId = @ContractId
AND LeaseFloatRateIncomes.IncomeDate <= @StartDate
ORDER BY LeaseFloatRateIncomes.IncomeDate DESC
--GetalternateBillingCurrencyDetails
SELECT
AlternateBillingCurrencyId = LeaseFinanceAlternateCurrencyDetails.BillingCurrencyId,
ExchangeRate = LeaseFinanceAlternateCurrencyDetails.BillingExchangeRate,
EffectiveDate = LeaseFinanceAlternateCurrencyDetails.EffectiveDate
FROM LeaseFinanceAlternateCurrencyDetails
JOIN LeaseFinances ON LeaseFinanceAlternateCurrencyDetails.LeaseFinanceId = LeaseFinances.Id
WHERE LeaseFinances.IsBillInAlternateCurrency = 1
AND LeaseFinanceAlternateCurrencyDetails.IsActive = 1
AND LeaseFinances.Id = @LeaseFinanceId
AND LeaseFinances.IsCurrent = 1
ORDER BY LeaseFinanceAlternateCurrencyDetails.EffectiveDate
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[LoanIncomeScheduleInterestRateDetailsReport]
(
@ContractId BIGINT
)
AS
SELECT
InterestRateDetails.EffectiveDate,
FloatRateIndexes.Name [FloatRateIndex],
InterestRateDetails.BaseRate,
InterestRateDetails.Spread,
InterestRateDetails.FloorPercent,
InterestRateDetails.CeilingPercent,
InterestRateDetails.CompoundingFrequency,
InterestRateDetails.InterestRate
FROM   Contracts
INNER JOIN LoanFinances ON Contracts.Id = LoanFinances.ContractId
INNER JOIN LoanInterestRates ON LoanFinances.Id = LoanInterestRates.LoanFinanceId
INNER JOIN InterestRateDetails ON LoanInterestRates.InterestRateDetailId = InterestRateDetails.Id AND
InterestRateDetails.IsActive = 1
LEFT JOIN FloatRateIndexes ON InterestRateDetails.FloatRateIndexId = FloatRateIndexes.Id
WHERE LoanFinances.IsCurrent = 1 AND Contracts.Id = @ContractId

GO

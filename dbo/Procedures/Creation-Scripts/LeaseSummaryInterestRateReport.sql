SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[LeaseSummaryInterestRateReport]
(
@SequenceNumber  NVARCHAR(40)
)
AS
BEGIN
SELECT
InterestRateDetails.EffectiveDate,
FloatRateIndexes.Name AS FloatRateIndex,
InterestRateDetails.BaseRate,
InterestRateDetails.Spread,
InterestRateDetails.FloorPercent,
InterestRateDetails.CeilingPercent,
InterestRateDetails.CompoundingFrequency
FROM
Contracts
INNER JOIN
LeaseFinances ON Contracts.Id = LeaseFinances.ContractId AND LeaseFinances.IsCurrent = 1
INNER JOIN
LeaseFinanceDetails  ON LeaseFinances.Id = LeaseFinanceDetails.Id
INNER JOIN
LeaseInterestRates  ON LeaseFinanceDetails.Id = LeaseInterestRates.LeaseFinanceDetailId
INNER JOIN
InterestRateDetails ON LeaseInterestRates.InterestRateDetailId = InterestRateDetails.Id AND InterestRateDetails.IsActive=1
LEFT JOIN
FloatRateIndexes ON InterestRateDetails.FloatRateIndexId = FloatRateIndexes.Id
WHERE
Contracts.SequenceNumber=@SequenceNumber
END

GO

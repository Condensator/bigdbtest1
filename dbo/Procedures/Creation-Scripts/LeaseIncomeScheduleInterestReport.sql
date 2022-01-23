SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[LeaseIncomeScheduleInterestReport]
(
@SequenceNumber  NVARCHAR(40),
@IsAccounting BIT
)
AS
BEGIN
SELECT
interestRateDetail.EffectiveDate,
floatRateIndex.Name as 'FloatRateIndex',
interestRateDetail.BaseRate,
interestRateDetail.Spread,
interestRateDetail.FloorPercent,
interestRateDetail.CeilingPercent
FROM
Contracts AS contract
INNER JOIN
LeaseFinances AS lease ON contract.Id = lease.ContractId AND lease.IsCurrent=1
INNER JOIN
LeaseFinanceDetails AS leaseDetail ON lease.Id = leaseDetail.Id
INNER JOIN
LeaseInterestRates AS leaseInterestRate ON leaseDetail.Id = leaseInterestRate.LeaseFinanceDetailId
INNER JOIN
InterestRateDetails AS interestRateDetail ON leaseInterestRate.InterestRateDetailId = interestRateDetail.Id AND interestRateDetail.IsActive=1
LEFT JOIN
FloatRateIndexes AS floatRateIndex ON interestRateDetail.FloatRateIndexId = floatRateIndex.Id
WHERE
contract.SequenceNumber=@SequenceNumber
END

GO

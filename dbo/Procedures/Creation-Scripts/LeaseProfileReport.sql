SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[LeaseProfileReport]
(
@SequenceNumber NVARCHAR(40)
)
AS
BEGIN
SELECT
CurrencyCodes.ISO AS Currency,
Parties.PartyNumber,
Parties.PartyName,
LeaseFinanceDetails.CommencementDate,
LeaseFinanceDetails.MaturityDate,
LeaseFinanceDetails.PaymentFrequency,
LeaseFinances.BookingStatus,
LeaseFinanceDetails.LeaseContractType,
Contracts.SequenceNumber,
LeaseFinanceDetails.TermInMonths,
LeaseFinanceDetails.NumberOfPayments,
LeaseFinanceDetails.NumberOfInceptionPayments,
CASE WHEN LeaseFinanceDetails.IsRegularPaymentStream=1 THEN 'Regular'ELSE 'Irregular' END AS LeaseStructureType,
SUM(LeaseAssets.BookedResidual_Amount) AS BookedResidual_Amount,
SUM(LeaseAssets.Rent_Amount) AS RegularPaymentAmount,
SUM(LeaseAssets.NBV_Amount -LeaseAssets.ETCAdjustmentAmount_Amount) As NetInvestmentAmount
FROM
Contracts
INNER JOIN
Currencies ON Contracts.CurrencyId = Currencies.Id
INNER JOIN
CurrencyCodes ON Currencies.CurrencyCodeId = CurrencyCodes.Id
INNER JOIN
LeaseFinances ON Contracts.Id = LeaseFinances.ContractId AND LeaseFinances.IsCurrent = 1
INNER JOIN
Parties ON LeaseFinances.CustomerId = Parties.Id
INNER JOIN
LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
LEFT JOIN
LeaseAssets ON LeaseFinances.Id = LeaseAssets.LeaseFinanceId AND (LeaseAssets.IsActive=1 OR LeaseAssets.TerminationDate IS NOT NULL)
WHERE
Contracts.SequenceNumber=@SequenceNumber
GROUP BY
CurrencyCodes.ISO,
Contracts.SequenceNumber,
Parties.PartyNumber,
Parties.PartyName,
LeaseFinances.BookingStatus,
LeaseFinanceDetails.CommencementDate,
LeaseFinanceDetails.MaturityDate,
LeaseFinanceDetails.NumberOfPayments,
LeaseFinanceDetails.NumberOfInceptionPayments,
LeaseFinanceDetails.TermInMonths,
LeaseFinanceDetails.PaymentFrequency,
LeaseFinanceDetails.IsRegularPaymentStream,
LeaseFinanceDetails.BookedResidual_Amount,
LeaseFinanceDetails.IsRegularPaymentStream,
LeaseFinanceDetails.LeaseContractType
END

GO

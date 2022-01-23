SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[OperatingLeaseNewBusinessReport]
(
@LegalEntityNumber NVARCHAR(MAX) = NULL,
@LeaseSequenceNumber AS NVARCHAR(40) = NULL,
@CustomerName AS NVARCHAR(250) = NULL,
@FromDate DATE,
@ToDate DATE
)
AS
BEGIN
;WITH CTE_PaymentSchedules
AS
(
SELECT
LeasePaymentSchedules.LeaseFinanceDetailId,
SUM(LeasePaymentSchedules.Amount_Amount) AS FixedTermRent
FROM
LeasePaymentSchedules
WHERE
LeasePaymentSchedules.IsActive=1 AND LeasePaymentSchedules.PaymentType='FixedTerm'
GROUP BY
LeasePaymentSchedules.LeaseFinanceDetailId
)
SELECT
Contracts.SequenceNumber,
CurrencyCodes.ISO AS Currency,
LegalEntities.LegalEntityNumber,
Parties.PartyName AS CustomerName,
LeaseFinanceDetails.CommencementDate,
LeaseFinanceDetails.TermInMonths AS LeaseTermInMonths,
LeaseFinanceDetails.MaturityDate,
ISNULL(CTE_PaymentSchedules.FixedTermRent + LeaseFinanceDetails.DownPayment_Amount,0.00) AS TotalReceivable,
SUM(LeaseAssets.NBV_Amount -LeaseAssets.ETCAdjustmentAmount_Amount) AS BookCost,
SUM(LeaseAssets.BookedResidual_Amount) AS Residual,
LeaseFinanceDetails.PaymentFrequency AS Frequency,
LeaseFinanceDetails.PaymentFrequencyDays AS FrequencyDays,
LeaseFinanceDetails.IsAdvance AS IsInAdvance,
LeaseFinanceDetails.IsRegularPaymentStream AS IsRegular
FROM
Contracts
INNER JOIN
Currencies ON Contracts.CurrencyId = Currencies.Id
INNER JOIN
CurrencyCodes ON Currencies.CurrencyCodeId = CurrencyCodes.Id
INNER JOIN
LeaseFinances ON Contracts.Id = LeaseFinances.ContractId AND LeaseFinances.IsCurrent = 1
INNER JOIN
LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
INNER JOIN
Customers ON LeaseFinances.CustomerId = Customers.Id
INNER JOIN
LegalEntities ON LeaseFinances.LegalEntityId = LegalEntities.Id
INNER JOIN
Parties ON Customers.Id = Parties.Id
LEFT JOIN
LeaseAssets ON LeaseFinances.Id = LeaseAssets.LeaseFinanceId AND (LeaseAssets.IsActive=1 OR LeaseAssets.TerminationDate IS NOT NULL)
LEFT JOIN
CTE_PaymentSchedules ON LeaseFinanceDetails.Id = CTE_PaymentSchedules.LeaseFinanceDetailId
WHERE
LeaseFinanceDetails.LeaseContractType = 'Operating' AND LeaseFinances.BookingStatus='Commenced'
AND (@LeaseSequenceNumber IS NULL OR @LeaseSequenceNumber = Contracts.SequenceNumber)
AND (@LegalEntityNumber IS NULL OR LegalEntities.LegalEntityNumber in (select value from String_split(@LegalEntityNumber,',')))
AND (@CustomerName IS NULL OR @CustomerName = Parties.PartyName)
AND (@FromDate IS NULL OR @FromDate <= LeaseFinanceDetails.CommencementDate)
AND (@ToDate IS NULL OR @ToDate >= LeaseFinanceDetails.CommencementDate)
GROUP BY
Contracts.SequenceNumber,
CurrencyCodes.ISO,
LegalEntities.LegalEntityNumber,
Parties.PartyName,
LeaseFinanceDetails.CommencementDate,
LeaseFinanceDetails.TermInMonths,
LeaseFinanceDetails.MaturityDate,
LeaseFinanceDetails.BookedResidual_Amount,
LeaseFinanceDetails.PaymentFrequency,
LeaseFinanceDetails.PaymentFrequencyDays,
LeaseFinanceDetails.IsAdvance,
LeaseFinanceDetails.IsRegularPaymentStream,
CTE_PaymentSchedules.FixedTermRent,
LeaseFinanceDetails.DownPayment_Amount,
LeaseFinanceDetails.InceptionPayment_Amount
END

GO

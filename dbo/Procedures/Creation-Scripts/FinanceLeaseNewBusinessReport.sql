SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FinanceLeaseNewBusinessReport]
(
@LegalEntityNumber NVARCHAR(MAX) = NULL,
@LeaseSequenceNumber AS NVARCHAR(40) = NULL,
@CustomerName AS NVARCHAR(250) = NULL,
@FromDate DATE,
@ToDate DATE
)
AS
BEGIN
SET NOCOUNT ON
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
,CTE_LeaseIncomeSchedules
AS
(
SELECT
LeaseIncomeSchedules.LeaseFinanceId,
SUM(LeaseIncomeSchedules.Income_Amount - LeaseIncomeSchedules.ResidualIncome_Amount) AS UnearnedMLPIncome,
SUM(LeaseIncomeSchedules.ResidualIncome_Amount) AS UnearnedRI
FROM
LeaseIncomeSchedules
WHERE
LeaseIncomeSchedules.IsAccounting=1
GROUP BY
LeaseIncomeSchedules.LeaseFinanceId
)
,CTE_LeaseAssets
AS
(
SELECT
LeaseAssets.LeaseFinanceId,
SUM(LeaseAssets.CustomerGuaranteedResidual_Amount) AS CustomerGuaranteedResidual,
SUM(LeaseAssets.ThirdPartyGuaranteedResidual_Amount) AS ThirdPartyGuaranteedResidual,
SUM(LeaseAssets.BookedResidual_Amount - LeaseAssets.CustomerGuaranteedResidual_Amount - LeaseAssets.ThirdPartyGuaranteedResidual_Amount) AS LessorRisk,
SUM(LeaseAssets.NBV_Amount - LeaseAssets.ETCAdjustmentAmount_Amount) AS NetInvestment
FROM
LeaseAssets
WHERE
(LeaseAssets.IsActive=1 OR LeaseAssets.TerminationDate IS NOT NULL)
GROUP BY
LeaseAssets.LeaseFinanceId
)
SELECT
Contracts.SequenceNumber,
CurrencyCodes.ISO AS Currency,
LegalEntities.LegalEntityNumber,
Parties.PartyName AS CustomerName,
LeaseFinanceDetails.CommencementDate,
LeaseFinanceDetails.TermInMonths AS LeaseTermInMonths,
LeaseFinanceDetails.MaturityDate,
LeaseFinanceDetails.Rent_Amount AS LeaseRent,
ISNULL(CTE_PaymentSchedules.FixedTermRent + LeaseFinanceDetails.DownPayment_Amount + CTE_LeaseAssets.CustomerGuaranteedResidual + CTE_LeaseAssets.ThirdPartyGuaranteedResidual,0.00) AS TotalReceivable,
LeaseFinanceDetails.LessorYield,
ISNULL(CTE_LeaseAssets.NetInvestment,0.00) AS NetInvestment,
ISNULL(CTE_LeaseIncomeSchedules.UnearnedMLPIncome,0.00) AS UnearnedMLPIncome,
ISNULL(CTE_LeaseAssets.LessorRisk,0.00) AS LessorRisk,
ISNULL(CTE_LeaseIncomeSchedules.UnearnedRI,0.00) AS UnearnedRI,
LeaseFinanceDetails.CostOfFunds,
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
CTE_LeaseAssets ON LeaseFinances.Id = CTE_LeaseAssets.LeaseFinanceId
LEFT JOIN
CTE_PaymentSchedules ON LeaseFinanceDetails.Id = CTE_PaymentSchedules.LeaseFinanceDetailId
LEFT JOIN
CTE_LeaseIncomeSchedules ON LeaseFinances.Id = CTE_LeaseIncomeSchedules.LeaseFinanceId
WHERE
LeaseFinanceDetails.LeaseContractType != 'Operating' AND LeaseFinances.BookingStatus in ('Commenced','FullyPaidOff')
AND (@LeaseSequenceNumber IS NULL OR @LeaseSequenceNumber = Contracts.SequenceNumber)
AND (@LegalEntityNumber IS NULL OR LegalEntities.LegalEntityNumber in (SELECT value
FROM STRING_SPLIT(@LegalEntityNumber,',')))
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
LeaseFinanceDetails.Rent_Amount,
LeaseFinanceDetails.LessorYield,
LeaseFinanceDetails.CostOfFunds,
LeaseFinanceDetails.PaymentFrequency,
LeaseFinanceDetails.PaymentFrequencyDays,
LeaseFinanceDetails.IsAdvance,
LeaseFinanceDetails.IsRegularPaymentStream,
CTE_LeaseIncomeSchedules.UnearnedRI,
CTE_LeaseIncomeSchedules.UnearnedMLPIncome,
CTE_PaymentSchedules.FixedTermRent,
CTE_LeaseAssets.CustomerGuaranteedResidual,
CTE_LeaseAssets.ThirdPartyGuaranteedResidual,
CTE_LeaseAssets.LessorRisk,
CTE_LeaseAssets.NetInvestment,
LeaseFinanceDetails.DownPayment_Amount,
LeaseFinanceDetails.CustomerGuaranteedResidual_Amount,
LeaseFinanceDetails.ThirdPartyGuaranteedResidual_Amount,
LeaseFinanceDetails.InceptionPayment_Amount
END

GO

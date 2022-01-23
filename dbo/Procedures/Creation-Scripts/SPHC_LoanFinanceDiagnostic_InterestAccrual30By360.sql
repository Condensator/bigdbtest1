SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[SPHC_LoanFinanceDiagnostic_InterestAccrual30By360]
(
@InterestAccrual30By360_LegalEntityId LoanFinanceDiagnostic_InterestAccrual30By360_LegalEntityIds readonly
)
AS
SET NOCOUNT ON;
DECLARE @Messages StoredProcMessage
DECLARE @ErrorCount int
SELECT Sequencenumber
, L.Name
, LineofBusinesses.Name [LOBName]
, LoanFinances.Id
, IsDailySensitive
, PaymentFrequency
, DueDay
, CommencementDate
, MaturityDate
, Contracts.Id          [ContractId]
, DayCountConvention
, SyndicationType
INTO #SelectedContracts
FROM LoanFinances
JOIN LegalEntities L ON LoanFinances.LegalEntityId = L.Id
JOIN Contracts ON Contracts.Id = LoanFinances.ContractId
JOIN LineofBusinesses ON LineofBusinesses.Id = Contracts.LineofBusinessId
WHERE ContractType = 'Loan'
AND LoanFinances.STATUS NOT IN('FullyPaidOff', 'Uncommenced', 'Cancelled')
AND DayCountConvention = '_30By360'
AND IsDailySensitive = 0
AND (
NOT EXISTS
(
SELECT LegalEntityId
FROM @InterestAccrual30By360_LegalEntityId
)
OR LoanFinances.LegalEntityId IN
(
SELECT LegalEntityId
FROM @InterestAccrual30By360_LegalEntityId
));
SELECT Sequencenumber
, #SelectedContracts.ContractId
, LoanFinanceId
, DueDate             FundingDate
, InvoiceTotal_Amount FundingAmount
INTO #FutureFundings
FROM #SelectedContracts
JOIN LoanFundings ON #SelectedContracts.Id = LoanFundings.LoanFinanceId
AND LoanFundings.IsActive = 1
AND LoanFundings.TYPE != 'Origination'
JOIN PayableInvoices ON LoanFundings.FundingId = PayableInvoices.Id;
SELECT Name
, #SelectedContracts.Sequencenumber
, LOBName
, LoanIncomeSchedules.LoanFinanceId
, IsDailySensitive
, DueDay
, IncomeDate
, InterestAccrued_Amount
, DayCountConvention
, CommencementDate
, MaturityDate
, CASE
WHEN MONTH(IncomeDate) = 2
AND DAY(IncomeDate) = 28
AND ISDATE(CAST(YEAR(IncomeDate) AS CHAR(4)) + '0229') != 1
AND DueDay NOT IN(29, 30)
THEN ROUND(((CASE
WHEN IncomeDate = CommencementDate
AND FundingDate = DATEADD(d, 1, CommencementDate)
THEN BeginNetBookValue_Amount + PrincipalAdded_Amount - PrincipalRepayment_Amount - ISNULL(FundingAmount, 0)
WHEN IncomeDate = CommencementDate
THEN BeginNetBookValue_Amount + PrincipalAdded_Amount - PrincipalRepayment_Amount
ELSE BeginNetBookValue_Amount
END) * (InterestRate / 360) * 3), 2)
WHEN MONTH(IncomeDate) = 2
AND DAY(IncomeDate) = 29
AND DueDay NOT IN(29, 30)
THEN ROUND(((CASE
WHEN IncomeDate = CommencementDate
AND FundingDate = DATEADD(d, 1, CommencementDate)
THEN BeginNetBookValue_Amount + PrincipalAdded_Amount - PrincipalRepayment_Amount - ISNULL(FundingAmount, 0)
WHEN IncomeDate = CommencementDate
THEN BeginNetBookValue_Amount + PrincipalAdded_Amount - PrincipalRepayment_Amount
ELSE BeginNetBookValue_Amount
END) * (InterestRate / 360) * 2), 2)
WHEN MONTH(IncomeDate) = 2
AND DAY(IncomeDate) = 28
AND DueDay = 29
THEN ROUND(((CASE
WHEN IncomeDate = CommencementDate
AND FundingDate = DATEADD(d, 1, CommencementDate)
THEN BeginNetBookValue_Amount + PrincipalAdded_Amount - PrincipalRepayment_Amount - ISNULL(FundingAmount, 0)
WHEN IncomeDate = CommencementDate
THEN BeginNetBookValue_Amount + PrincipalAdded_Amount - PrincipalRepayment_Amount
ELSE BeginNetBookValue_Amount
END) * (InterestRate / 360) * 1), 2)
WHEN MONTH(IncomeDate) = 2
AND DAY(IncomeDate) = 28
AND DueDay = 30
THEN ROUND(((CASE
WHEN IncomeDate = CommencementDate
AND FundingDate = DATEADD(d, 1, CommencementDate)
THEN BeginNetBookValue_Amount + PrincipalAdded_Amount - PrincipalRepayment_Amount - ISNULL(FundingAmount, 0)
WHEN IncomeDate = CommencementDate
THEN BeginNetBookValue_Amount + PrincipalAdded_Amount - PrincipalRepayment_Amount
ELSE BeginNetBookValue_Amount
END) * (InterestRate / 360) * 2), 2)
WHEN MONTH(IncomeDate) = 3
AND DAY(IncomeDate) = 28
AND DueDay = 29
THEN ROUND(((CASE
WHEN IncomeDate = CommencementDate
AND FundingDate = DATEADD(d, 1, CommencementDate)
THEN BeginNetBookValue_Amount + PrincipalAdded_Amount - PrincipalRepayment_Amount - ISNULL(FundingAmount, 0)
WHEN IncomeDate = CommencementDate
THEN BeginNetBookValue_Amount + PrincipalAdded_Amount - PrincipalRepayment_Amount
ELSE BeginNetBookValue_Amount
END) * (InterestRate / 360) * 3), 2)
WHEN MONTH(IncomeDate) = 3
AND DAY(IncomeDate) = 29
AND DueDay = 30
THEN ROUND(((CASE
WHEN IncomeDate = CommencementDate
AND FundingDate = DATEADD(d, 1, CommencementDate)
THEN BeginNetBookValue_Amount + PrincipalAdded_Amount - PrincipalRepayment_Amount - ISNULL(FundingAmount, 0)
WHEN IncomeDate = CommencementDate
THEN BeginNetBookValue_Amount + PrincipalAdded_Amount - PrincipalRepayment_Amount
ELSE BeginNetBookValue_Amount
END) * (InterestRate / 360) * 2), 2)
WHEN DAY(IncomeDate) = 31
THEN 0
ELSE ROUND((CASE
WHEN IncomeDate = CommencementDate
AND FundingDate = DATEADD(d, 1, CommencementDate)
THEN BeginNetBookValue_Amount + PrincipalAdded_Amount - PrincipalRepayment_Amount - ISNULL(FundingAmount, 0)
WHEN IncomeDate = CommencementDate
THEN BeginNetBookValue_Amount + PrincipalAdded_Amount - PrincipalRepayment_Amount
ELSE BeginNetBookValue_Amount
END) * (InterestRate / 360), 2)
END [CalculatedAmount]
, PaymentFrequency
, Payment_Amount
, CapitalizedInterest_Amount
, BeginNetBookValue_Amount
, InterestRate
, PrincipalAdded_Amount
, PrincipalRepayment_Amount
, InterestPayment_Amount
, EndNetBookValue_Amount
, #SelectedContracts.ContractId
, SyndicationType
INTO #IncomeDetails
FROM LoanIncomeSchedules
INNER JOIN #SelectedContracts ON #SelectedContracts.Id = LoanIncomeSchedules.LoanFinanceId
LEFT JOIN #FutureFundings ON #FutureFundings.LoanFinanceId = #SelectedContracts.Id
WHERE IsSchedule = 1;
SELECT @ErrorCount = COUNT(*)
FROM #IncomeDetails
WHERE ABS(InterestAccrued_Amount - CalculatedAmount) > 0.99
IF(@ErrorCount > 0)
BEGIN
INSERT INTO @Messages VALUES ('LoanError', 'Count=' + str(@ErrorCount));
END;
ELSE
BEGIN
INSERT INTO @Messages VALUES ('Success', null);
END;
SELECT DISTINCT
Name
, Sequencenumber
, LOBName
, IsDailySensitive
, DueDay
, DayCountConvention
FROM #IncomeDetails
WHERE ABS(InterestAccrued_Amount - CalculatedAmount) > 0.99;
SELECT Name, ParameterValuesCsv FROM @Messages;
SET NOCOUNT OFF;

GO

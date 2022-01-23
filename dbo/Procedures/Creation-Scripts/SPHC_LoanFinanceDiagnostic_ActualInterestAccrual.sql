SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[SPHC_LoanFinanceDiagnostic_ActualInterestAccrual]
(
@ActualInterestAccrual_LegalEntityId LoanFinanceDiagnostic_ActualInterestAccrual_LegalEntityIds readonly
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
INNER JOIN Contracts ON Contracts.Id = LoanFinances.ContractId
INNER JOIN LineofBusinesses ON LineofBusinesses.Id = Contracts.LineofBusinessId
WHERE ContractType = 'Loan'
AND LoanFinances.STATUS NOT IN('FullyPaidOff', 'Uncommenced', 'Cancelled')
AND DayCountConvention != '_30By360'
AND(
NOT EXISTS (
SELECT *
FROM @ActualInterestAccrual_LegalEntityId
)
OR LoanFinances.LegalEntityId IN
(
SELECT LegalEntityId
FROM @ActualInterestAccrual_LegalEntityId
))
SELECT Name
, Sequencenumber
, LOBName
, LoanFinanceId
, IsDailySensitive
, DueDay
, IncomeDate
, InterestAccrued_Amount
, DayCountConvention
, CommencementDate
, MaturityDate
, CASE
WHEN DayCountConvention = 'ActualBy360'
THEN ROUND((CASE
WHEN IncomeDate = CommencementDate
THEN BeginNetBookValue_Amount + PrincipalAdded_Amount - PrincipalRepayment_Amount
ELSE BeginNetBookValue_Amount
END) * (InterestRate / 360), 2)
ELSE ROUND((CASE
WHEN IncomeDate = CommencementDate
THEN BeginNetBookValue_Amount + PrincipalAdded_Amount - PrincipalRepayment_Amount
ELSE BeginNetBookValue_Amount
END) * (InterestRate / 365), 2)
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
, ContractId
, SyndicationType
INTO #IncomeDetails
FROM LoanIncomeSchedules
INNER JOIN #SelectedContracts ON #SelectedContracts.Id = LoanIncomeSchedules.LoanFinanceId
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

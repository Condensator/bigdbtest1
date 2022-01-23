SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[SPHC_LoanFinanceDiagnostic_NonDailySensitiveLoanAnalysis]
(
@NonDailySensitiveLoanAnalysis_LegalEntityId LoanFinanceDiagnostic_NonDailySensitiveLoanAnalysis_LegalEntityIds readonly
)
AS
SET NOCOUNT ON;
DECLARE @Messages StoredProcMessage
DECLARE @ErrorCount int
SELECT C.SequenceNumber
, lf.DayCountConvention
, lf.DueDay
, lf.Id                             LoanFinanceId
, lp.PaymentStructure
, lp.Id                             PaymentScheduleId
, StartDate
, EndDate
, lp.Amount_Amount
, lp.BeginBalance_Amount
, lp.EndBalance_Amount
, lp.Principal_Amount
, Interest_Amount
, PaymentType
, CommencementDate
, SyndicationType
, ContractId
, Name                              [LOBName]
, SUM(ISNULL(lci.Amount_Amount, 0)) [CapitalizedAmount]
INTO #PaymentSchedules
FROM LoanPaymentSchedules lp
JOIN LoanFinances lf ON lp.LoanfinanceId = lf.id
AND lp.IsActive = 1
AND lf.IsDailySensitive = 0
AND DayCountConvention = '_30By360'
AND lf.IsCurrent = 1
AND lp.PaymentType = 'FixedTerm'
JOIN Contracts c ON lf.ContractId = C.Id
AND ContractType = 'Loan'
INNER JOIN LineofBusinesses ON LineofBusinesses.Id = C.LineofBusinessId
LEFT JOIN LoanCapitalizedInterests lci ON lci.LoanFinanceId = lf.id
AND lci.IsActive = 1
AND lci.CapitalizedDate BETWEEN lp.StartDate AND lp.EndDate
WHERE(
NOT EXISTS(
SELECT *
FROM @NonDailySensitiveLoanAnalysis_LegalEntityId
)
OR lf.LegalEntityId IN
(
SELECT LegalEntityId
FROM @NonDailySensitiveLoanAnalysis_LegalEntityId
))
GROUP BY C.SequenceNumber
, lf.DayCountConvention
, lf.DueDay
, lf.Id
, lp.PaymentStructure
, lp.Id
, StartDate
, EndDate
, lp.Amount_Amount
, lp.BeginBalance_Amount
, lp.EndBalance_Amount
, lp.Principal_Amount
, Interest_Amount
, PaymentType
, CommencementDate
, SyndicationType
, ContractId
, Name;
CREATE TABLE #IncomeSchedules
(IncomeId                      BIGINT,
IncomeDate                    DATETIME,
Payment_Amount                DECIMAL(16, 2),
BeginNetBookValue_Amount      DECIMAL(16, 2),
EndNetBookValue_Amount        DECIMAL(16, 2),
PrincipalRepayment_Amount     DECIMAL(16, 2),
PrincipalAdded_Amount         DECIMAL(16, 2),
TotalPrincipalAdded_Amount    DECIMAL(16, 2),
InterestPayment_Amount        DECIMAL(16, 2),
InterestAccrued_Amount        DECIMAL(16, 2),
InterestAccrualBalance_Amount DECIMAL(16, 2),
CapitalizedInterest_Amount    DECIMAL(16, 2),
CompoundDate                  DATETIME,
LoanFinanceId                 BIGINT,
InterestRate                  DECIMAL(10, 8),
TotalInterestAccrued_Amount   DECIMAL(16, 2),
PaymentScheduleId             BIGINT,
InterestPaydown_Amount        DECIMAL(16, 2)
);
CREATE TABLE #IncomeInterests
(PaymentScheduleId           BIGINT,
IncomeDate                  DATETIME,
TotalInterestAccrued_Amount DECIMAL(16, 2)
);
CREATE TABLE #PrincipalAdded
(PaymentScheduleId     BIGINT,
IncomeDate            DATETIME,
PrincipalAdded_Amount DECIMAL(16, 2)
);
CREATE TABLE #CompoundedInterest
(PaymentScheduleId             BIGINT,
EndDate                       DATETIME,
InterestAccrualBalance_Amount DECIMAL(16, 2),
);
CREATE TABLE #CapitalizedInterest
(PaymentScheduleId          BIGINT,
EndDate                    DATETIME,
CapitalizedInterest_Amount DECIMAL(16, 2),
);
CREATE TABLE #PayDown
(PaymentScheduleId       BIGINT,
PaydownDate             DATETIME,
InterestPaydown_Amount  DECIMAL(16, 2),
PrincipalPaydown_Amount DECIMAL(16, 2)
);
CREATE TABLE #FutureFundingOnCommencement
(FundingDate   DATETIME,
FundingAmount DECIMAL(16, 2),
);
DECLARE @ContractId BIGINT;
DECLARE INCOME_CURSOR CURSOR LOCAL FORWARD_ONLY
FOR SELECT DISTINCT
ContractId
FROM #PaymentSchedules
ORDER BY ContractId;
OPEN INCOME_CURSOR;
FETCH NEXT FROM INCOME_CURSOR INTO @ContractId;
WHILE @@FETCH_STATUS = 0
BEGIN
INSERT INTO #IncomeInterests
SELECT #PaymentSchedules.PaymentScheduleId
, MAX(IncomeDate)
, SUM(InterestAccrued_Amount - CapitalizedInterest_Amount) TotalInterestAccrued_Amount
FROM LoanIncomeSchedules
JOIN LoanFinances L ON LoanIncomeSchedules.LoanFinanceId = L.Id
JOIN #PaymentSchedules ON L.ContractId = #PaymentSchedules.ContractId
WHERE L.ContractId = @ContractId
AND IsSchedule = 1
AND IncomeDate BETWEEN #PaymentSchedules.StartDate AND #PaymentSchedules.EndDate
GROUP BY #PaymentSchedules.PaymentScheduleId;
INSERT INTO #PrincipalAdded
SELECT #PaymentSchedules.PaymentScheduleId
, MAX(IncomeDate)
, SUM(PrincipalAdded_Amount) PrincipalAdded_Amount
FROM LoanIncomeSchedules
JOIN LoanFinances L ON LoanIncomeSchedules.LoanFinanceId = L.Id
JOIN #PaymentSchedules ON L.ContractId = #PaymentSchedules.ContractId
WHERE L.ContractId = @ContractId
AND IsSchedule = 1
AND IncomeDate BETWEEN #PaymentSchedules.StartDate AND #PaymentSchedules.EndDate
AND l.CommencementDate <> IncomeDate
GROUP BY #PaymentSchedules.PaymentScheduleId;
INSERT INTO #CapitalizedInterest
SELECT #PaymentSchedules.PaymentScheduleId
, MAX(IncomeDate)
, SUM(CapitalizedInterest_Amount) CapitalizedInterest_Amount
FROM LoanIncomeSchedules
JOIN LoanFinances L ON LoanIncomeSchedules.LoanFinanceId = L.Id
JOIN #PaymentSchedules ON L.ContractId = #PaymentSchedules.ContractId
WHERE L.ContractId = @ContractId
AND IsSchedule = 1
AND IncomeDate BETWEEN #PaymentSchedules.StartDate AND #PaymentSchedules.EndDate
AND l.CommencementDate <> IncomeDate
GROUP BY #PaymentSchedules.PaymentScheduleId;
INSERT INTO #PayDown
SELECT PaymentScheduleId
, PaydownDate
, SUM(InterestPaydown_Amount)  InterestPaydown_Amount
, SUM(PrincipalPaydown_Amount) PrincipalPaydown_Amount
FROM #PaymentSchedules
INNER JOIN LoanFinances ON LoanFinances.ContractId = #PaymentSchedules.ContractId
INNER JOIN LoanPaydowns ON LoanPaydowns.LoanFinanceId = LoanFinances.Id
WHERE #PaymentSchedules.ContractId = @ContractId
AND LoanPaydowns.STATUS = 'Active'
AND PaydownDate BETWEEN #PaymentSchedules.StartDate AND #PaymentSchedules.EndDate
GROUP BY PaymentScheduleId
, PaydownDate;
INSERT INTO #CompoundedInterest
SELECT #PaymentSchedules.PaymentScheduleId
, #PaymentSchedules.EndDate
, MAX(InterestAccrualBalance_Amount) InterestAccrualBalance_Amount
FROM LoanIncomeSchedules
JOIN LoanFinances L ON LoanIncomeSchedules.LoanFinanceId = L.Id
JOIN #PaymentSchedules ON L.ContractId = #PaymentSchedules.ContractId
WHERE L.ContractId = @ContractId
AND IsSchedule = 1
AND IncomeDate BETWEEN #PaymentSchedules.StartDate AND #PaymentSchedules.EndDate
AND CompoundDate <> #PaymentSchedules.EndDate
AND CompoundDate = IncomeDate
AND InterestAccrualBalance_Amount <> 0
GROUP BY #PaymentSchedules.PaymentScheduleId
, #PaymentSchedules.EndDate;
INSERT INTO #IncomeSchedules
SELECT li.Id
, CONVERT(DATE, li.IncomeDate)
, Payment_Amount
, BeginNetBookValue_Amount
, EndNetBookValue_Amount
, PrincipalRepayment_Amount
, li.PrincipalAdded_Amount
, #PrincipalAdded.PrincipalAdded_Amount
, InterestPayment_Amount
, InterestAccrued_Amount
, InterestAccrualBalance_Amount
, #CapitalizedInterest.CapitalizedInterest_Amount
, CompoundDate
, li.LoanFinanceId
, InterestRate
, TotalInterestAccrued_Amount
, #PaymentSchedules.PaymentScheduleId
, InterestPaydown_Amount
FROM LoanIncomeSchedules li
JOIN LoanFinances L ON li.LoanFinanceId = L.Id
JOIN #PaymentSchedules ON L.ContractId = #PaymentSchedules.ContractId
JOIN #IncomeInterests ON #PaymentSchedules.PaymentScheduleId = #IncomeInterests.PaymentScheduleId
JOIN #PrincipalAdded ON #PaymentSchedules.PaymentScheduleId = #PrincipalAdded.PaymentScheduleId
AND li.IncomeDate = #IncomeInterests.IncomeDate
JOIN #CapitalizedInterest ON #PaymentSchedules.PaymentScheduleId = #CapitalizedInterest.PaymentScheduleId
AND li.IncomeDate = #IncomeInterests.IncomeDate
LEFT JOIN #PayDown ON #PayDown.PaymentScheduleId = #PaymentSchedules.PaymentScheduleId
WHERE li.IsSchedule = 1
AND li.IncomeDate = #IncomeInterests.IncomeDate;
IF
(
SELECT COUNT(*)
FROM #PrincipalAdded
) > 0
BEGIN
INSERT INTO #FutureFundingOnCommencement
SELECT DISTINCT
#PaymentSchedules.EndDate
, SUM(PIOC.Amount_Amount)
FROM LoanFundings
JOIN PayableInvoices PaI ON PaI.Id = LoanFundings.FundingId
JOIN PayableInvoiceOtherCosts PIOC ON PIOC.PayableInvoiceId = PaI.Id
AND PIOC.AllocationMethod = 'LoanDisbursement'
JOIN LoanFinances L ON LoanFundings.LoanFinanceId = L.Id
JOIN #PaymentSchedules ON L.ContractId = #PaymentSchedules.ContractId
WHERE #PaymentSchedules.ContractId = @ContractId
AND L.CommencementDate = DATEADD(DAY, -1, PaI.DueDate)
AND PaI.DueDate BETWEEN #PaymentSchedules.StartDate AND #PaymentSchedules.EndDate
GROUP BY #PaymentSchedules.EndDate;
END;
WITH CTE_BeginNBV
AS (SELECT #PaymentSchedules.PaymentScheduleId
, #PaymentSchedules.EndDate
, li.BeginNetBookValue_Amount + li.PrincipalAdded_Amount [BeginNetBookValue_Amount]
FROM LoanIncomeSchedules li
JOIN LoanFinances L ON li.LoanFinanceId = L.Id
JOIN #PaymentSchedules ON L.ContractId = #PaymentSchedules.ContractId
WHERE #PaymentSchedules.StartDate = li.IncomeDate
AND #PaymentSchedules.ContractId = @ContractId
AND IsSchedule = 1)
UPDATE #IncomeSchedules
SET
#IncomeSchedules.BeginNetBookValue_Amount = CTE_BeginNBV.BeginNetBookValue_Amount - ISNULL(FundingAmount, 0)
FROM #IncomeSchedules
JOIN CTE_BeginNBV ON CTE_BeginNBV.PaymentScheduleId = #IncomeSchedules.PaymentScheduleId
AND CTE_BeginNBV.EndDate = #IncomeSchedules.IncomeDate
LEFT JOIN #FutureFundingOnCommencement ON #FutureFundingOnCommencement.FundingDate = CTE_BeginNBV.EndDate;
TRUNCATE TABLE #IncomeInterests;
TRUNCATE TABLE #PrincipalAdded;
TRUNCATE TABLE #FutureFundingOnCommencement;
TRUNCATE TABLE #PayDown;
TRUNCATE TABLE #CapitalizedInterest;
FETCH NEXT FROM INCOME_CURSOR INTO @ContractId;
END;
CLOSE INCOME_CURSOR;
DEALLOCATE INCOME_CURSOR;
SELECT ContractId
, SequenceNumber
, SyndicationType
, lp.LoanFinanceId
, lp.DayCountConvention
, lp.Dueday
, CONVERT(DATE, li.IncomeDate) [IncomeDate]
, lp.Amount_Amount             LPAmount
, li.Payment_Amount            LIAmount
, lp.Amount_Amount - li.Payment_Amount                                          AmountDifference
, lp.BeginBalance_Amount       LPBeginBalance
, CASE
WHEN CommencementDate = IncomeDate
THEN li.BeginNetBookValue_Amount + PrincipalAdded_Amount
ELSE li.BeginNetBookValue_Amount
END                          LIBeginBalance
, C.InterestAccrualBalance_Amount                                               CompoundedInterest
, lp.BeginBalance_Amount - li.BeginNetBookValue_Amount                          [BeginBalanceDifference]
, lp.EndBalance_Amount         LPEndBalance
, li.EndNetBookValue_Amount    LIEndBalance
, TotalPrincipalAdded_Amount
, lp.EndBalance_Amount - (li.EndNetBookValue_Amount - li.PrincipalAdded_Amount) EndBalanceDifference
, CASE
WHEN lp.Amount_Amount = 0
THEN 0
ELSE lp.Principal_Amount
END                          LPPrincipal
, li.PrincipalRepayment_Amount LIPrincipal
, CASE
WHEN lp.Amount_Amount = 0
THEN 0
ELSE lp.Principal_Amount
END - li.PrincipalRepayment_Amount                                            PrincipalDifference
, CASE
WHEN lp.Amount_Amount = 0
THEN 0
ELSE lp.Interest_Amount
END                          LPInterest
, li.InterestPayment_Amount    LIInterestPayment
, li.TotalInterestAccrued_Amount - ISNULL(li.InterestPaydown_Amount, 0)         LInterestAccrualInterestAccrued
, CASE
WHEN lp.Amount_Amount = 0
THEN 0
ELSE lp.Interest_Amount
END - li.InterestPayment_Amount                                               InterestPaymentDifference
, CASE
WHEN lp.Amount_Amount = 0
THEN 0
ELSE lp.Interest_Amount
END - (li.TotalInterestAccrued_Amount - ISNULL(li.InterestPaydown_Amount, 0)) InterestAccrualInterestDifference
, li.CapitalizedInterest_Amount LICapitalizedInterest
, lp.CapitalizedAmount         LCCapitalizedAmount
, ISNULL(li.CapitalizedInterest_Amount, 0) - ISNULL(lp.CapitalizedAmount, 0)    CapitalizedInterestDifference
, lp.PaymentScheduleId
INTO #PaymentIncomes
FROM #PaymentSchedules lp
JOIN #IncomeSchedules li ON lp.PaymentScheduleId = li.PaymentScheduleId
AND lp.EndDate = li.IncomeDate
LEFT JOIN #CompoundedInterest C ON c.PaymentScheduleId = li.PaymentScheduleId
AND li.IncomeDate = c.EndDate;
-- To Get the differences
--SELECT *
--FROM #PaymentIncomes
--WHERE ABS(AmountDifference) > 0.02
--      OR ABS(BeginBalanceDifference) > 0.02
--      OR ABS(EndBalanceDifference) > 0.02
--      OR ABS(PrincipalDifference) > 0.02
--      OR ABS(InterestPaymentDifference) > 0.02
--      OR ABS(InterestAccrualInterestDifference) > 0.02
--      OR ABS(CapitalizedInterestDifference) > 0.02
--ORDER BY SequenceNumber
--       , IncomeDate;
--SELECT DISTINCT
--       SequenceNumber
--     , LoanFinanceId
--FROM #PaymentIncomes
--WHERE ABS(AmountDifference) > 0.02
--      OR ABS(BeginBalanceDifference) > 0.02
--      OR ABS(EndBalanceDifference) > 0.02
--      OR ABS(PrincipalDifference) > 0.02
--      OR ABS(InterestPaymentDifference) > 0.02
--      OR ABS(InterestAccrualInterestDifference) > 0.02
--      OR ABS(CapitalizedInterestDifference) > 0.02;
SELECT RD.Id ReceivableDetailId
, RD.AdjustmentBasisReceivableDetailId
INTO #T
FROM Receivables R
JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId
AND R.IsActive = 1
AND RD.IsActive = 1
AND RD.AdjustmentBasisReceivableDetailId IS NOT NULL
JOIN #PaymentIncomes P ON R.PaymentScheduleId = P.PaymentScheduleId
JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
AND RT.Name IN('LoanInterest', 'LoanPrincipal');
WITH CTE
AS (SELECT ReceivableDetailId Id
FROM #T
UNION
SELECT AdjustmentBasisReceivableDetailId Id
FROM #T)
SELECT P.LoanFinanceId
, SequenceNumber
, ContractId
, R.PaymentScheduleId
, R.DueDate
, R.TotalAmount_Amount
, P.LIInterestPayment
, P.LIPrincipal
, RT.Name
, CASE
WHEN RT.Name = 'LoanInterest'
THEN P.LPInterest - R.TotalAmount_Amount
ELSE(CASE
WHEN RT.Name = 'LoanPrincipal'
THEN P.LPPrincipal - R.TotalAmount_Amount
END)
END ReceivableDifference
INTO #Receivables
FROM Receivables R
JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId
AND R.IsActive = 1
AND RD.IsActive = 1
JOIN #PaymentIncomes P ON R.PaymentScheduleId = P.PaymentScheduleId
JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
AND RT.Name IN('LoanInterest', 'LoanPrincipal')
AND RD.Id NOT IN(SELECT Id
FROM CTE)
ORDER BY SequenceNumber;
SELECT @ErrorCount = COUNT(*)
FROM #Receivables
WHERE ABS(ReceivableDifference) <> 0
IF(@ErrorCount > 0)
BEGIN
INSERT INTO @Messages VALUES ('LoanError', 'Count=' + str(@ErrorCount));
END;
ELSE
BEGIN
INSERT INTO @Messages VALUES ('Success', null);
END;
SELECT *
FROM #Receivables
WHERE ABS(ReceivableDifference) <> 0
ORDER BY Duedate;
SELECT Name, ParameterValuesCsv FROM @Messages;
SET NOCOUNT OFF;

GO

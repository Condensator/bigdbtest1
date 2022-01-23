SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[SPHC_LoanFinanceDiagnostic_DailySensitiveLoanAnalysis]
(
@DailySensitiveLoanAnalysis_LegalEntityId LoanFinanceDiagnostic_DailySensitiveLoanAnalysis_LegalEntityIds readonly
)
AS
SET NOCOUNT ON;
DECLARE @Messages StoredProcMessage
DECLARE @ErrorCount int
SELECT LoanFinances.Id LoanFinanceId
, IsDailySensitive
, PaymentFrequency
, dueday
, CommencementDate
, CompoundingFrequency
, sequenceNumber
, ContractId
INTO #SelectedContracts
FROM LoanFinances
INNER JOIN Contracts ON Contracts.Id = LoanFinances.ContractId
WHERE IsCurrent = 1
AND DayCountConvention LIKE '_30By360'
AND LoanFinances.Status NOT IN('FullyPaidOff', 'Uncommenced', 'Cancelled')
AND IsDailySensitive = 1
AND ( NOT EXISTS
(
SELECT *
FROM @DailySensitiveLoanAnalysis_LegalEntityId
)
OR LoanFinances.LegalEntityId IN
(
SELECT LegalEntityId
FROM @DailySensitiveLoanAnalysis_LegalEntityId
));
SELECT sequenceNumber
, ContractId
, LoanIncomeSchedules.Id IncomeId
, LoanIncomeSchedules.LoanFinanceId
, IncomeDate
, CommencementDate
, InterestAccrued_Amount
, CASE
WHEN MONTH(IncomeDate) = 2
AND DAY(IncomeDate) = 28
AND DueDay NOT IN(29, 30)
THEN ROUND(((CASE
WHEN incomedate = commencementdate
THEN BeginNetBookValue_Amount + PrincipalAdded_Amount
ELSE BeginNetBookValue_Amount
END) * (InterestRate / 360) * 3), 2)
WHEN MONTH(IncomeDate) = 2
AND DAY(IncomeDate) = 29
AND DueDay NOT IN(29, 30)
THEN ROUND(((CASE
WHEN incomedate = commencementdate
THEN BeginNetBookValue_Amount + PrincipalAdded_Amount
ELSE BeginNetBookValue_Amount
END) * (InterestRate / 360) * 2), 2)
WHEN MONTH(IncomeDate) = 2
AND DAY(IncomeDate) = 28
AND DueDay = 29
THEN ROUND(((CASE
WHEN incomedate = commencementdate
THEN BeginNetBookValue_Amount + PrincipalAdded_Amount
ELSE BeginNetBookValue_Amount
END) * (InterestRate / 360) * 1), 2)
WHEN MONTH(IncomeDate) = 2
AND DAY(IncomeDate) = 28
AND DueDay = 30
THEN ROUND(((CASE
WHEN incomedate = commencementdate
THEN BeginNetBookValue_Amount + PrincipalAdded_Amount
ELSE BeginNetBookValue_Amount
END) * (InterestRate / 360) * 2), 2)
WHEN MONTH(IncomeDate) = 3
AND DAY(IncomeDate) = 28
AND DueDay = 29
THEN ROUND(((CASE
WHEN IncomeDate = CommencementDate
THEN BeginNetBookValue_Amount + PrincipalAdded_Amount - PrincipalRepayment_Amount
ELSE BeginNetBookValue_Amount
END) * (InterestRate / 360) * 3), 2)
WHEN MONTH(IncomeDate) = 3
AND DAY(IncomeDate) = 29
AND DueDay = 30
THEN ROUND(((CASE
WHEN IncomeDate = CommencementDate
THEN BeginNetBookValue_Amount + PrincipalAdded_Amount - PrincipalRepayment_Amount
ELSE BeginNetBookValue_Amount
END) * (InterestRate / 360) * 2), 2)
WHEN DAY(IncomeDate) = 31
THEN 0
ELSE ROUND((CASE
WHEN incomedate = commencementdate
THEN BeginNetBookValue_Amount + PrincipalAdded_Amount
ELSE BeginNetBookValue_Amount
END) * (InterestRate / 360), 2)
END                    [CalculatedAmount]
, InterestAccrualBalance_Amount
, Payment_Amount
, InterestPayment_Amount
, PrincipalRepayment_Amount
, BeginNetBookValue_Amount
, PrincipalAdded_Amount
, EndNetBookValue_Amount
, InterestRate
, CapitalizedInterest_Amount
, FloatRateIndexDetailId
INTO #IncomeDetails
FROM LoanIncomeSchedules
JOIN #SelectedContracts ON #SelectedContracts.LoanFinanceId = LoanIncomeSchedules.LoanFinanceId
WHERE IsSchedule = 1
AND IsLessorOwned = 1;
DECLARE @LoanFinanceId BIGINT;
DECLARE @ContractId BIGINT;
DECLARE @SequenceNumber NVARCHAR(200);
DECLARE @PreviousInterestAccrualBalance DECIMAL(16, 2);
DECLARE @IncomeDate DATETIME;
DECLARE @CommencementDate DATETIME;
DECLARE @InterestAccrued_Amount DECIMAL(16, 2);
DECLARE @InterestAccrualBalance_Amount DECIMAL(16, 2);
DECLARE @CapitalizedInterest_Amount DECIMAL(16, 2);
DECLARE @Payment_Amount DECIMAL(16, 2);
DECLARE @InterestPayment_Amount DECIMAL(16, 2);
DECLARE @PrincipalRepayment_Amount DECIMAL(16, 2);
DECLARE @BeginNetBookValue_Amount DECIMAL(16, 2);
DECLARE @EndNetBookValue_Amount DECIMAL(16, 2);
DECLARE @PrincipalAdded_Amount DECIMAL(16, 2);
CREATE TABLE #ResultSet
(LoanFinanceId  BIGINT,
SequenceNumber NVARCHAR(100),
IsValid        BIT,
Comment        NVARCHAR(200)
);
DECLARE LoanCur CURSOR
FOR SELECT DISTINCT
LoanFinanceId
, SequenceNumber
, ContractId
, CommencementDate
FROM #IncomeDetails
ORDER BY LoanFinanceId;
OPEN LoanCur;
FETCH NEXT FROM LoanCur INTO @LoanFinanceId, @SequenceNumber, @ContractId, @CommencementDate;
WHILE @@FETCH_STATUS = 0
BEGIN
SET @PreviousInterestAccrualBalance = 0;
DECLARE INCOME_CURSOR CURSOR LOCAL FORWARD_ONLY
FOR SELECT IncomeDate
, InterestAccrued_Amount
, InterestAccrualBalance_Amount
, CapitalizedInterest_Amount
, Payment_Amount
, InterestPayment_Amount
, PrincipalRepayment_Amount
, BeginNetBookValue_Amount
, PrincipalAdded_Amount
FROM LoanIncomeSchedules
INNER JOIN LoanFinances ON LoanFinances.id = LoanIncomeSchedules.LoanFinanceId
WHERE LoanFinances.ContractId = @ContractId
AND IsSchedule = 1
AND IsLessorOwned = 1
ORDER BY IncomeDate;
OPEN INCOME_CURSOR;
FETCH NEXT FROM INCOME_CURSOR INTO @IncomeDate, @InterestAccrued_Amount, @InterestAccrualBalance_Amount, @CapitalizedInterest_Amount, @Payment_Amount, @InterestPayment_Amount, @PrincipalRepayment_Amount, @BeginNetBookValue_Amount, @PrincipalAdded_Amount;
WHILE @@FETCH_STATUS = 0
BEGIN
IF @IncomeDate = @CommencementDate
AND @InterestAccrualBalance_Amount != @InterestAccrued_Amount - @InterestPayment_Amount
BEGIN
INSERT INTO #ResultSet
VALUES
(@LoanFinanceId
, @SequenceNumber
, 0
, 'Interest Accrual Balance Mismatch @ ' + CAST(@IncomeDate AS NVARCHAR(200))
);
END;
IF @IncomeDate != @CommencementDate
AND (@InterestAccrualBalance_Amount != 0
AND @InterestAccrualBalance_Amount != @PreviousInterestAccrualBalance + @InterestAccrued_Amount - @InterestPayment_Amount)
BEGIN
PRINT @PreviousInterestAccrualBalance;
PRINT @InterestAccrualBalance_Amount;
PRINT @InterestAccrued_Amount;
PRINT @InterestPayment_Amount;
INSERT INTO #ResultSet
VALUES
(@LoanFinanceId
, @SequenceNumber
, 0
, 'Interest Accrual Balance Mismatch @ ' + CAST(@IncomeDate AS NVARCHAR(200))
);
END;
IF @IncomeDate != @CommencementDate
AND (@EndNetBookValue_Amount != @BeginNetBookValue_Amount + @Payment_Amount - @InterestPayment_Amount)
BEGIN
INSERT INTO #ResultSet
VALUES
(@LoanFinanceId
, @SequenceNumber
, 0
, 'ENDNBV Mismatch @ ' + CAST(@IncomeDate AS NVARCHAR(200))
);
END;
IF @IncomeDate = @CommencementDate
SET @PreviousInterestAccrualBalance = @InterestAccrued_Amount;
ELSE
IF @InterestAccrualBalance_Amount <> 0
SET @PreviousInterestAccrualBalance = @InterestAccrualBalance_Amount;
IF @Payment_Amount <> 0
AND @InterestAccrualBalance_Amount = 0
BEGIN
SET @PreviousInterestAccrualBalance = 0;
END;
FETCH NEXT FROM INCOME_CURSOR INTO @IncomeDate, @InterestAccrued_Amount, @InterestAccrualBalance_Amount, @CapitalizedInterest_Amount, @Payment_Amount, @InterestPayment_Amount, @PrincipalRepayment_Amount, @BeginNetBookValue_Amount, @PrincipalAdded_Amount;
END;
CLOSE INCOME_CURSOR;
DEALLOCATE INCOME_CURSOR;
FETCH NEXT FROM LoanCur INTO @LoanFinanceId, @SequenceNumber, @ContractId, @CommencementDate;
END;
CLOSE LoanCur;
DEALLOCATE LoanCur;
SELECT @ErrorCount = COUNT(*)
FROM #ResultSet
WHERE IsValid = 0
IF(@ErrorCount > 0)
BEGIN
INSERT INTO @Messages VALUES ('LoanError', 'Count=' + str(@ErrorCount));
END;
ELSE
BEGIN
INSERT INTO @Messages VALUES ('Success', null);
END;
-- Output: Data dump
SELECT *
FROM #ResultSet
WHERE IsValid = 0
ORDER BY LoanFinanceId;
SELECT Name, ParameterValuesCsv FROM @Messages;
SET NOCOUNT OFF;

GO

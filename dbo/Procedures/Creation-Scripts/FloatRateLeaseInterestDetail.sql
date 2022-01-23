SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[FloatRateLeaseInterestDetail]
(
@InvoiceId BIGINT,
@AddendumPagesCount INT
)WITH RECOMPILE
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
--Declare @InvoiceId BIGINT = 48200;
DECLARE @StartDate DATETIME;
DECLARE @EndDate DATETIME;
DECLARE @IsAdvance TINYINT;
DECLARE @PaymentNumber INT;
DECLARE @LeaseFinanceDetailId BIGINT;
DECLARE @PaymentType NVARCHAR(20);
DECLARE @BeginBalance DECIMAL(16,2);
CREATE TABLE #FloatRateResult(InvoiceId BIGINT,InterestRate DECIMAL(10,8),ChangeAmount DECIMAL(18,2),Balance DECIMAL(18,2),InterestAmount DECIMAL(18,2),DaysInPeriod INT,
PrincipalAmount DECIMAL(18,2),TaxAmount DECIMAL(18,2),TotalInterest DECIMAL(18,2),TotalAmountDue DECIMAL(18,2))
CREATE TABLE #Result(FloatRateIndexDetailId BIGINT IDENTITY(1,1),InterestRate DECIMAL(10,8),InterestAmount DECIMAL(16,2),ChangeAmount DECIMAL(16,2),Balance DECIMAL(16,2),
DaysInPeriod INT,PrincipalAmount DECIMAL(16,2),TaxAmount DECIMAL(16,2),TotalInterest DECIMAL(16,2),TotalAmountDue DECIMAL(16,2))
SELECT DISTINCT lf2.Id LeaseFinanceId, lf3.Id LeaseFinanceDetailId,lf3.IsAdvance,lf3.CommencementDate,lp.StartDate,lp.EndDate,lp.DueDate,lp.PaymentNumber,lp.PaymentType
INTO #LeaseDetails
FROM dbo.ReceivableInvoices ri
INNER JOIN dbo.ReceivableInvoiceDetails rid ON ri.Id = rid.ReceivableInvoiceId
INNER JOIN dbo.ReceivableDetails rd ON rid.ReceivableDetailId = rd.id
INNER JOIN dbo.Receivables r ON rd.ReceivableId = r.Id
INNER JOIN dbo.LeasePaymentSchedules lp ON r.PaymentScheduleId = lp.Id
AND lp.PaymentType != 'InterimInterest'
INNER JOIN dbo.Contracts c ON rid.EntityId = c.Id
INNER JOIN dbo.LeaseFinances lf2 ON c.Id = lf2.ContractId
AND lf2.IsCurrent = 1
INNER JOIN dbo.LeaseFinanceDetails lf3 ON lf2.Id = lf3.Id
INNER JOIN dbo.ReceivableCodes rc ON r.ReceivableCodeId = rc.Id
AND rc.IsActive = 1
INNER JOIN dbo.ReceivableTypes rt ON rc.ReceivableTypeId = rt.Id
AND rt.IsRental = 1
WHERE ri.IsActive = 1 AND ri.Id = @InvoiceId
SELECT @IsAdvance = IsAdvance, @PaymentNumber = PaymentNumber, @StartDate = StartDate
,@EndDate = EndDate,@LeaseFinanceDetailId = LeaseFinanceDetailId
FROM #LeaseDetails
IF @IsAdvance = 1 AND @PaymentNumber != 1
SELECT @StartDate = StartDate, @EndDate = EndDate, @PaymentType = PaymentType
FROM LeasePaymentSchedules WHERE LeaseFinanceDetailId = @LeaseFinanceDetailId
AND IsActive = 1 AND PaymentNumber = @PaymentNumber - 1 AND PaymentType = 'FixedTerm'
;WITH FloatRate AS
(
SELECT Distinct lfr.IncomeDate,@StartDate StartDate,@EndDate EndDate,ISNULL(lfr.InterestRate,0) InterestRate
,lp.BeginBalance_Amount,lf3.DayCountConvention,ri.Id InvoiceId,lp.Principal_Amount PrincipalAmount,ri.InvoiceTaxAmount_Amount TaxAmount
,lp.Interest_Amount+lp.ReceivableAdjustmentAmount_Amount ActualInterest
FROM dbo.ReceivableInvoices ri
INNER JOIN dbo.ReceivableInvoiceDetails rid ON ri.Id = rid.ReceivableInvoiceId
INNER JOIN dbo.ReceivableDetails rd ON rid.ReceivableDetailId = rd.id
INNER JOIN dbo.Receivables r ON rd.ReceivableId = r.Id
INNER JOIN dbo.LeasePaymentSchedules lp ON r.PaymentScheduleId = lp.Id
AND lp.PaymentType != 'InterimInterest'
INNER JOIN dbo.Contracts c ON rid.EntityId = c.Id
INNER JOIN dbo.LeaseFinances lf2 ON c.Id = lf2.ContractId
INNER JOIN dbo.LeaseFinanceDetails lf3 ON lf2.Id = lf3.Id
LEFT JOIN dbo.LeaseFloatRateIncomes lfr ON lf2.Id = lfr.LeaseFinanceId
AND lfr.IsScheduled = 1
AND lfr.IncomeDate BETWEEN @StartDate AND @EndDate
WHERE ri.IsActive = 1 AND ri.Id = @InvoiceId
)
SELECT ROW_NUMBER() OVER(ORDER BY IncomeDate) RowNumber,0 DaysInPeriod,* INTO #FloatRateDetails FROM FloatRate
WHERE IncomeDate IS NOT NULL
IF @IsAdvance = 1 AND @PaymentNumber != 1
BEGIN
SELECT  @BeginBalance = BeginBalance_Amount FROM LeasePaymentSchedules WHERE LeaseFinanceDetailId = @LeaseFinanceDetailId
AND IsActive = 1 AND PaymentNumber = @PaymentNumber - 1 AND PaymentType = 'FixedTerm'
UPDATE #FloatRateDetails SET BeginBalance_Amount = @BeginBalance
END
DECLARE @SDate DATETIME;
DECLARE @EDate DATETIME;
DECLARE @RowCount INT;
DECLARE @LastRow INT;
DECLARE @Row INT;
DECLARE @Days INT;
DECLARE @DayCount NVARCHAR(MAX);
DECLARE @DayCountMethod INT;
DECLARE @Spread DECIMAL(10,6);
DECLARE @IncomeDate DATETIME;
DECLARE @Diff DECIMAL(16,2);
DECLARE @Interest DECIMAL(16,2);
DECLARE @ActualInterest DECIMAL(16,2);
SELECT @RowCount = COUNT(*) FROM #FloatRateDetails
SELECT @LastRow = MAX(RowNumber) FROM #FloatRateDetails
SET @Row = 1;
SELECT @SDate = StartDate FROM #FloatRateDetails WHERE RowNumber = @Row
IF @Row = 1
SELECT @EDate = IncomeDate FROM #FloatRateDetails WHERE RowNumber = @Row
ELSE
SELECT @EDate = IncomeDate FROM #FloatRateDetails WHERE RowNumber = @Row + 1
SELECT @DayCount = DayCountConvention FROM #FloatRateDetails WHERE RowNumber = @Row
IF(@DayCount = '_30By360' OR @DayCount = 'ActualBy360')
BEGIN
SET @DayCountMethod = 360
END
ELSE
BEGIN
SET @DayCountMethod = 365
END
WHILE(@RowCount > 0 and @Row <= @Lastrow)
BEGIN
IF @Row = 1
SELECT @Days = dbo.DaysInPeriod(@SDate,@EDate,@DayCount)
ELSE
SELECT @Days = dbo.DaysInPeriod(DATEADD(DD,1,@SDate),@EDate,@DayCount)
UPDATE #FloatRateDetails SET DaysInPeriod = ISNULL(@Days,0) WHERE RowNumber = @Row;
IF @Row = @LastRow
BEGIN
SELECT @EDate = EndDate FROM #FloatRateDetails WHERE RowNumber = @Row;
END
ELSE
BEGIN
SELECT @EDate = IncomeDate FROM #FloatRateDetails WHERE RowNumber = @Row+1;
END
SELECT @SDate = IncomeDate FROM #FloatRateDetails WHERE RowNumber = @Row;
SET @Row = @Row + 1;
END
--INSERT INTO #FloatRateResult
--SELECT RowNumber,InvoiceId,InterestRate,0,BeginBalance_Amount,ROUND((BeginBalance_Amount*DaysInPeriod*InterestRate)/@DayCountMethod,2)
--,DaysInPeriod,PrincipalAmount,TaxAmount,0,0
--FROM #FloatRateDetails
;WITH CTE_FloatRateResult AS
(
SELECT InvoiceId,InterestRate,BeginBalance_Amount,SUM(DaysInPeriod) DaysInPeriod,PrincipalAmount,TaxAmount
FROM #FloatRateDetails GROUP BY InvoiceId,InterestRate,BeginBalance_Amount,PrincipalAmount,TaxAmount
)
INSERT INTO #FloatRateResult
SELECT InvoiceId,InterestRate,0,BeginBalance_Amount,ROUND((BeginBalance_Amount*DaysInPeriod*InterestRate)/@DayCountMethod,2)
,DaysInPeriod,PrincipalAmount,TaxAmount,0,0
FROM CTE_FloatRateResult
;WITH PreviousPayment AS
(
SELECT DISTINCT lp.*,ri.Id InvoiceId
FROM dbo.ReceivableInvoices ri
INNER JOIN dbo.ReceivableInvoiceDetails rid ON ri.Id = rid.ReceivableInvoiceId
INNER JOIN dbo.ReceivableDetails rd ON rid.ReceivableDetailId = rd.id
INNER JOIN dbo.Receivables r ON rd.ReceivableId = r.Id
INNER JOIN dbo.LeasePaymentSchedules lp ON r.PaymentScheduleId = lp.Id
INNER JOIN dbo.Contracts c ON rid.EntityId = c.Id
INNER JOIN dbo.LeaseFinances lf2 ON c.Id = lf2.ContractId
WHERE ri.IsActive = 1 AND ri.Id = @InvoiceId
)
SELECT TOP 1 lp.PaymentNumber,lp.Principal_Amount,pp.InvoiceId
INTO #ChangeAmount
FROM LeasePaymentSchedules lp
JOIN PreviousPayment pp ON lp.LeaseFinanceDetailId = pp.LeaseFinanceDetailId
AND lp.PaymentType = 'FixedTerm'
WHERE lp.PaymentNumber < pp.PaymentNumber ORDER BY lp.Id DESC,lp.PaymentNumber DESC
UPDATE #FloatRateResult SET ChangeAmount = Principal_Amount
FROM #ChangeAmount JOIN #FloatRateResult ON #FloatRateResult.InvoiceId = #ChangeAmount.InvoiceId
--Assuming that for advance leases for first payment there won't be any interest
IF @IsAdvance = 1 AND @PaymentNumber = 1
UPDATE #FloatRateResult SET InterestRate = 0, InterestAmount = 0
SELECT @Interest = SUM(InterestAmount) FROM #FloatRateResult;
SELECT TOP 1 @ActualInterest = ActualInterest FROM #FloatRateDetails;
SET @Diff = @ActualInterest - @Interest;
--UPDATE #FloatRateResult SET InterestAmount = InterestAmount + @Diff WHERE RowNumber = @LastRow;
UPDATE #FloatRateResult SET TotalInterest = (SELECT SUM(InterestAmount) FROM #FloatRateResult)
UPDATE #FloatRateResult SET TotalAmountDue =  TotalInterest + PrincipalAmount + TaxAmount
INSERT INTO #Result
SELECT InterestRate,SUM(InterestAmount) InterestAmount,ChangeAmount,Balance,SUM(DaysInPeriod) DaysInPeriod
,PrincipalAmount,TaxAmount,TotalInterest,TotalAmountDue FROM #FloatRateResult WHERE DaysInPeriod > 0
GROUP BY InterestRate,ChangeAmount,Balance,PrincipalAmount,TaxAmount,TotalInterest,TotalAmountDue
UPDATE #Result SET TotalInterest = TotalInterest + @Diff
,TotalAmountDue = TotalAmountDue + @Diff;
UPDATE #Result SET InterestAmount = InterestAmount + @Diff
WHERE FloatRateIndexDetailId = (SELECT MAX(FloatRateIndexDetailId) FROM #Result WHERE DaysInPeriod > 0 AND InterestAmount != 0);
SELECT * FROM #Result;
DROP TABLE #FloatRateDetails
DROP TABLE #FloatRateResult
DROP TABLE #ChangeAmount
DROP TABLE #Result
DROP TABLE #LeaseDetails
END

GO

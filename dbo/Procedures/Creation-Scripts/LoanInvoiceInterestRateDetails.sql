SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[LoanInvoiceInterestRateDetails]
(
@InvoiceId BIGINT
)WITH RECOMPILE
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
--DECLARE @InvoiceId BIGINT = 12374;
DECLARE @LoanFinanceId BIGINT;
DECLARE @FloatRateIndexDetailId BIGINT;
DECLARE @InterestRate DECIMAL(10,8);
DECLARE @IncludeRepaymentAmount TINYINT;
DECLARE @CommencementDate DATETIME;
DECLARE @IsAdvance TINYINT;
DECLARE @StartDate DATETIME;
DECLARE @EndDate DATETIME;
DECLARE @ActualStartDate DATETIME;
DECLARE @ActualEndDate DATETIME;
DECLARE @IsDistinctRecordNeeded TINYINT;
DECLARE @PaymentFrequency NVARCHAR(26);
DECLARE @PaymentStructure NVARCHAR(26);
DECLARE @DaysFrequency INT;
DECLARE @IsDSL TINYINT;
DECLARE @LFId BIGINT;
DECLARE @IsRateChanged TINYINT;
DECLARE @IsRateChangedForNextEvent TINYINT;
DECLARE @FirstInterestRate DECIMAL(10,8);
DECLARE @PreviousInterest  DECIMAL(16,2);
DECLARE @IsPaymentReceived TINYINT;
DECLARE @IsFunding TINYINT;
DECLARE @IsFundingForNextEvent TINYINT;
DECLARE @IsEventOccured TINYINT;
DECLARE @LFinanceId BIGINT;
DECLARE @PaymentNumber INT;
DECLARE @PaymentType NVARCHAR(11);
DECLARE @DueDate DATETIME;
DECLARE @InterimPaymentType NVARCHAR(20);
DECLARE @IsAmortRan BIGINT;
DECLARE @SyndicationType NVARCHAR(30);
DECLARE @IsSyndicated TINYINT;
DECLARE @ContractId BIGINT;
DECLARE @InterimDayCount NVARCHAR(14);
CREATE TABLE #FinalResult(DetailId BIGINT IDENTITY(1,1),InterestRate DECIMAL(10,8),InterestAmount DECIMAL(16,2),ChangeAmount DECIMAL(16,2),Balance DECIMAL(16,2),
DaysInPeriod INT,PaymentAmount DECIMAL(16,2),PrincipalAmount DECIMAL(16,2),TaxAmount DECIMAL(16,2),TotalInterest DECIMAL(16,2),TotalAmountDue DECIMAL(16,2)
,PrincipalCodeName NVARCHAR(200),InterestCodeName NVARCHAR(200),InterestPayment DECIMAL(16,2), Label NVARCHAR(20),DownPayment DECIMAL(16,2),PaymentNumber INT,PaymentType NVARCHAR(11))
CREATE TABLE #Result(DetailId BIGINT IDENTITY(1,1),InterestRate DECIMAL(10,8),InterestAmount DECIMAL(16,2),ChangeAmount DECIMAL(16,2),Balance DECIMAL(16,2),
DaysInPeriod INT,PaymentAmount DECIMAL(16,2),PrincipalAmount DECIMAL(16,2),TaxAmount DECIMAL(16,2),TotalInterest DECIMAL(16,2),TotalAmountDue DECIMAL(16,2)
,PrincipalCodeName NVARCHAR(200),InterestCodeName NVARCHAR(200),InterestPayment DECIMAL(16,2), Label NVARCHAR(20),DownPayment DECIMAL(16,2),PaymentNumber INT,PaymentType NVARCHAR(11))
SELECT DISTINCT lp.LoanFinanceId,lp.StartDate,lp.EndDate,lf2.IsAdvance,lf2.IsDailySensitive
,lp.PaymentNumber,lp.PaymentType,ri.DueDate,rid.EntityId
INTO #AdvLoanDetails
FROM dbo.ReceivableInvoices ri
INNER JOIN dbo.ReceivableInvoiceDetails rid ON ri.Id = rid.ReceivableInvoiceId
INNER JOIN dbo.ReceivableDetails rd ON rid.ReceivableDetailId = rd.id
INNER JOIN dbo.Receivables r ON rd.ReceivableId = r.Id
INNER JOIN dbo.LoanPaymentSchedules lp ON r.PaymentScheduleId = lp.Id
AND lp.IsActive = 1
INNER JOIN dbo.LoanFinances lf2 ON lp.LoanFinanceId = lf2.Id
WHERE ri.IsActive = 1 AND ri.Id = @InvoiceId
SELECT @IsAdvance = IsAdvance, @StartDate = StartDate, @ActualStartDate = StartDate,@ActualEndDate = EndDate,
@LFinanceId = LoanFinanceId, @PaymentNumber = PaymentNumber, @PaymentType = PaymentType, @DueDate = DueDate,
@IsDSL = IsDailySensitive,@ContractId = EntityId
FROM #AdvLoanDetails
SELECT @SyndicationType = SyndicationType FROM Contracts WHERE Id IN
(SELECT ContractId FROM LoanFinances WHERE Id = @LFinanceId)
IF @SyndicationType != 'None'
SET @IsSyndicated = 1
ELSE
SET @IsSyndicated = 0
/*We need to use some other logic to check whther the amort has been ran or not*/
SELECT @IsAmortRan = COUNT(*) FROM dbo.LoanIncomeSchedules WITH(NOLOCK) WHERE LoanFinanceId = @LFinanceId AND IsSchedule = 1
SELECT @InterimPaymentType = PaymentType FROM #AdvLoanDetails WHERE PaymentType = 'Interim'
SELECT @InterimDayCount = InterimDayCountConvention FROM LoanFinances WHERE Id = @LFinanceId AND IsCurrent = 1
/*Block - Exceptional cases*/
IF @StartDate IS NULL AND @PaymentType = 'Downpayment' --AND @IsDSL = 1
BEGIN
DECLARE @DownPaymentAmount DECIMAL(16,2);
SELECT @DownPaymentAmount = ISNULL(SUM(lp.Amount_Amount),0) FROM
LoanPaymentSchedules lp
WHERE lp.PaymentType = 'Downpayment' AND lp.DueDate = @DueDate
AND lp.IsActive = 1 AND lp.LoanFinanceId = @LFinanceId
INSERT INTO #Result(InterestRate,InterestAmount,ChangeAmount,Balance,DaysInPeriod,PaymentAmount,PrincipalAmount,TaxAmount,TotalInterest,TotalAmountDue
,PrincipalCodeName,InterestCodeName,InterestPayment,Label,DownPayment,PaymentNumber,PaymentType)
SELECT 0,0,0,0,0,0,@DownPaymentAmount,0,0,@DownPaymentAmount,'Loan Principal',NULL,0,NULL,@DownPaymentAmount,0,NULL
SELECT DetailId,InterestRate,InterestAmount,ChangeAmount,Balance,DaysInPeriod,PrincipalAmount,TaxAmount,TotalInterest,TotalAmountDue
,PrincipalCodeName,InterestCodeName,InterestPayment, Label,DownPayment FROM #Result
DROP TABLE #Result;
END
ELSE IF @IsAdvance = 1 AND @PaymentNumber = 1 AND @IsDSL = 1 AND @PaymentType != 'Interim' AND @InterimPaymentType IS NULL
BEGIN
DECLARE @PrincipalAmount DECIMAL(16,2);
SELECT @PrincipalAmount = ISNULL(SUM(lp.Principal_Amount),0) FROM
LoanPaymentSchedules lp
WHERE lp.DueDate = @DueDate
AND lp.IsActive = 1 AND lp.LoanFinanceId = @LFinanceId
AND lp.PaymentType = 'FixedTerm'
INSERT INTO #Result(InterestRate,InterestAmount,ChangeAmount,Balance,DaysInPeriod,PaymentAmount,PrincipalAmount,TaxAmount,TotalInterest,TotalAmountDue
,PrincipalCodeName,InterestCodeName,InterestPayment,Label,DownPayment,PaymentNumber,PaymentType)
SELECT 0,0,0,0,0,0,@PrincipalAmount,0,0,@PrincipalAmount,'Loan Principal',NULL,0,NULL,0,0,NULL
SELECT DetailId,InterestRate,InterestAmount,ChangeAmount,Balance,DaysInPeriod,PrincipalAmount,TaxAmount,TotalInterest,TotalAmountDue
,PrincipalCodeName,InterestCodeName,InterestPayment, Label,DownPayment FROM #Result
DROP TABLE #Result;
END
ELSE IF @IsAdvance = 1 AND @PaymentNumber = 1 AND @IsDSL = 0 AND @IsAmortRan = 0
BEGIN
DECLARE @PrinAmount DECIMAL(16,2);
DECLARE @DownPayment DECIMAL(16,2);
SELECT @PrinAmount = ISNULL(SUM(lp.Principal_Amount),0) FROM
LoanPaymentSchedules lp
WHERE lp.DueDate = @DueDate
AND lp.IsActive = 1 AND lp.LoanFinanceId = @LFinanceId
AND lp.PaymentType = 'FixedTerm'
SELECT @DownPayment = ISNULL(SUM(lp.Principal_Amount),0) FROM
LoanPaymentSchedules lp
WHERE lp.DueDate = @DueDate
AND lp.IsActive = 1 AND lp.LoanFinanceId = @LFinanceId
AND lp.PaymentType = 'DownPayment'
INSERT INTO #Result(InterestRate,InterestAmount,ChangeAmount,Balance,DaysInPeriod,PaymentAmount,PrincipalAmount,TaxAmount,TotalInterest,TotalAmountDue
,PrincipalCodeName,InterestCodeName,InterestPayment,Label,DownPayment,PaymentNumber,PaymentType)
SELECT 0,0,0,0,0,0,@PrincipalAmount,0,0,@PrinAmount,'Loan Principal',NULL,0,NULL,@DownPayment,0,NULL
SELECT DetailId,InterestRate,InterestAmount,ChangeAmount,Balance,DaysInPeriod,PrincipalAmount,TaxAmount,TotalInterest,TotalAmountDue
,PrincipalCodeName,InterestCodeName,InterestPayment, Label,DownPayment FROM #Result
DROP TABLE #Result;
END
/*Block - Exceptional cases*/
ELSE
BEGIN
CREATE TABLE #LoanDetails(LoanFinanceId BIGINT, StartDate DATETIME,EndDate DATETIME ,BeginBalance_Amount DECIMAL(16,2),DayCountConvention NVARCHAR(MAX)
,InvoiceId BIGINT,PaymentAmount DECIMAL(16,2),PrincipalAmount DECIMAL(16,2),InterestAmount DECIMAL(16,2),TaxAmount DECIMAL(16,2),IsDailySensitive TINYINT,CommencementDate DATETIME,IsAdvance TINYINT
,PaymentFrequency NVARCHAR(26),PaymentNumber INT,PaymentStructure NVARCHAR(26),PaymentType NVARCHAR(11))
CREATE TABLE #IncomeDetails(RowNumber INT,LoanFinanceId BIGINT,IncomeDate DATETIME,BeginNetBookValue_Amount DECIMAL(16,2),EndNetBookValue_Amount DECIMAL(16,2),PrincipalRepayment DECIMAL(16,2),InterestRepayment DECIMAL(16,2),PrincipalAdded DECIMAL(16,2)
,StartDate DATETIME,EndDate DATETIME,DayCountConvention NVARCHAR(14),BeginBalance DECIMAL(16,2),DaysInPeriod INT,InterestRate DECIMAL(10,8),PaymentAmount DECIMAL(16,2),PrincipalAmount DECIMAL(16,2),InterestAmount DECIMAL(16,2)
,IsRateChanged TINYINT,IsFunding TINYINT,PaymentNumber INT,PaymentType NVARCHAR(11));
CREATE TABLE #IncomeDetails_Temp(LoanFinanceId BIGINT,IncomeDate DATETIME,BeginNetBookValue_Amount DECIMAL(16,2),EndNetBookValue_Amount DECIMAL(16,2),PrincipalRepayment DECIMAL(16,2),InterestRepayment DECIMAL(16,2),PrincipalAdded DECIMAL(16,2)
,StartDate DATETIME,EndDate DATETIME,DayCountConvention NVARCHAR(14),BeginBalance DECIMAL(16,2),DaysInPeriod INT,InterestRate DECIMAL(10,8),PaymentAmount DECIMAL(16,2),PrincipalAmount DECIMAL(16,2),InterestAmount DECIMAL(16,2)
,IsRateChanged TINYINT,IsFunding TINYINT,PaymentNumber INT,PaymentType NVARCHAR(11));
CREATE TABLE #LoanIncomeRecords(LoanFinanceId BIGINT,IncomeDate DATETIME,BeginNetBookValue_Amount DECIMAL(16,2),EndNetBookValue_Amount DECIMAL(16,2),PrincipalRepayment DECIMAL(16,2),InterestRepayment DECIMAL(16,2),PrincipalAdded DECIMAL(16,2)
,StartDate DATETIME,EndDate DATETIME,DayCountConvention NVARCHAR(14),BeginBalance DECIMAL(16,2),DaysInPeriod INT,InterestRate DECIMAL(10,8),PaymentAmount DECIMAL(16,2),PrincipalAmount DECIMAL(16,2),InterestAmount DECIMAL(16,2)
,IsRateChanged TINYINT,IsFunding TINYINT,PaymentNumber INT,PaymentType NVARCHAR(11));
IF @IsAdvance = 1 AND @PaymentNumber != 1 AND @PaymentType != 'Interim'
SELECT @StartDate = StartDate, @EndDate = EndDate FROM LoanPaymentSchedules WHERE LoanFinanceId = @LFinanceId
AND IsActive = 1 AND PaymentNumber = @PaymentNumber - 1 AND PaymentType = 'FixedTerm'
ELSE
SELECT @StartDate = StartDate, @EndDate = EndDate FROM #AdvLoanDetails
IF @IsAdvance = 1 AND @PaymentNumber != 1 AND @PaymentType != 'Interim'
BEGIN
INSERT INTO #LoanDetails
SELECT DISTINCT lis.LoanFinanceId, @StartDate StartDate,@EndDate EndDate ,lp.BeginBalance_Amount,lf2.DayCountConvention
,ri.Id InvoiceId,lp.Amount_Amount PaymentAmount,lp.Principal_Amount PrincipalAmount,lp.Interest_Amount InterestAmount,ri.InvoiceTaxAmount_Amount TaxAmount
,lf2.IsDailySensitive,lf2.CommencementDate,lf2.IsAdvance,lf2.PaymentFrequency,lp.PaymentNumber,lp.PaymentStructure,lp.PaymentType
FROM dbo.ReceivableInvoices ri
INNER JOIN dbo.ReceivableInvoiceDetails rid ON ri.Id = rid.ReceivableInvoiceId
INNER JOIN dbo.ReceivableDetails rd ON rid.ReceivableDetailId = rd.id
INNER JOIN dbo.Receivables r ON rd.ReceivableId = r.Id
INNER JOIN dbo.LoanPaymentSchedules lp ON r.PaymentScheduleId = lp.Id
AND lp.IsActive = 1
INNER JOIN dbo.Contracts c ON rid.EntityId = c.Id
INNER JOIN dbo.LoanFinances lf2 ON c.Id = lf2.ContractId
INNER JOIN dbo.LoanIncomeSchedules lis ON lis.LoanFinanceId = lf2.Id
AND lis.IsSchedule = 1
AND lis.IsLessorOwned = CASE WHEN @IsSyndicated = 1 THEN 0
ELSE 1 END
AND lis.IncomeDate BETWEEN @StartDate AND @EndDate
WHERE ri.IsActive = 1 AND ri.Id = @InvoiceId
END
ELSE
BEGIN
INSERT INTO #LoanDetails
SELECT DISTINCT lis.LoanFinanceId,lp.StartDate,lp.EndDate,lp.BeginBalance_Amount,lf2.DayCountConvention
,ri.Id InvoiceId,lp.Amount_Amount PaymentAmount,lp.Principal_Amount PrincipalAmount,lp.Interest_Amount InterestAmount,ri.InvoiceTaxAmount_Amount TaxAmount
,lf2.IsDailySensitive,lf2.CommencementDate,lf2.IsAdvance,lf2.PaymentFrequency,lp.PaymentNumber,lp.PaymentStructure,lp.PaymentType
FROM dbo.ReceivableInvoices ri
INNER JOIN dbo.ReceivableInvoiceDetails rid ON ri.Id = rid.ReceivableInvoiceId
INNER JOIN dbo.ReceivableDetails rd ON rid.ReceivableDetailId = rd.id
INNER JOIN dbo.Receivables r ON rd.ReceivableId = r.Id
INNER JOIN dbo.LoanPaymentSchedules lp ON r.PaymentScheduleId = lp.Id
AND lp.IsActive = 1
INNER JOIN dbo.Contracts c ON rid.EntityId = c.Id
INNER JOIN dbo.LoanFinances lf2 ON c.Id = lf2.ContractId
INNER JOIN dbo.LoanIncomeSchedules lis ON lis.LoanFinanceId = lf2.Id
AND lis.IsSchedule = 1
AND lis.IsLessorOwned = CASE WHEN @IsSyndicated = 1 THEN 0
ELSE 1 END
AND lis.IncomeDate BETWEEN lp.StartDate AND lp.EndDate
WHERE ri.IsActive = 1 AND ri.Id = @InvoiceId
END
SELECT @CommencementDate = CommencementDate, @IsAdvance = IsAdvance, @StartDate = StartDate, @PaymentFrequency = PaymentFrequency
,@IsDSL = IsDailySensitive, @PaymentStructure = PaymentStructure
FROM #LoanDetails
SELECT @PreviousInterest = ISNULL(SUM(InterestAccrualBalance_Amount),0)  FROM LoanIncomeSchedules lis
INNER JOIN #LoanDetails ld ON lis.LoanFinanceId = ld.LoanFinanceId
AND lis.IsAccounting = 1 AND lis.IsSchedule = 1
WHERE lis.IncomeDate = DATEADD(DD,-1,@StartDate)
IF(@CommencementDate = @StartDate AND @IsAdvance = 1)
SET @IncludeRepaymentAmount = 1
IF(@CommencementDate = @StartDate)
SET @IsDistinctRecordNeeded = 1
SELECT DISTINCT lis.LoanFinanceId,lis.FloatRateIndexDetailId,lis.InterestRate
INTO #InterestDetails
FROM LoanIncomeSchedules lis
INNER JOIN #LoanDetails ld ON lis.LoanFinanceId = ld.LoanFinanceId
AND lis.IsSchedule = 1
AND lis.IncomeDate BETWEEN ld.StartDate AND ld.EndDate
DECLARE LoanCursor CURSOR FOR
SELECT LoanFinanceId, FloatRateIndexDetailId, InterestRate
FROM #InterestDetails
OPEN LoanCursor
FETCH NEXT FROM LoanCursor INTO @LoanFinanceId, @FloatRateIndexDetailId, @InterestRate
WHILE @@FETCH_STATUS = 0
BEGIN
IF(@FloatRateIndexDetailId IS NOT NULL)
BEGIN
INSERT INTO #LoanIncomeRecords
SELECT TOP 1 lis.LoanFinanceId,lis.IncomeDate,lis.BeginNetBookValue_Amount,lis.EndNetBookValue_Amount,lis.PrincipalRepayment_Amount,lis.InterestPayment_Amount, lis.PrincipalAdded_Amount
,ld.StartDate,ld.EndDate,ld.DayCountConvention,0 BeginBalance, 0 DaysInPeriod,lis.InterestRate InterestRate,ld.PaymentAmount,ld.PrincipalAmount,ld.InterestAmount,0 IsRateChanged,0 IsFunding
,ld.PaymentNumber,ld.PaymentType
FROM LoanIncomeSchedules lis
INNER JOIN #LoanDetails ld ON lis.LoanFinanceId = ld.LoanFinanceId
AND lis.IsSchedule = 1
AND lis.IsLessorOwned = CASE WHEN @IsSyndicated = 1 THEN 0
ELSE 1 END
AND lis.IncomeDate BETWEEN ld.StartDate AND ld.EndDate
AND lis.FloatRateIndexDetailId = @FloatRateIndexDetailId
ORDER BY lis.IncomeDate
END
ELSE
BEGIN
INSERT INTO #LoanIncomeRecords
SELECT TOP 1 lis.LoanFinanceId,lis.IncomeDate,lis.BeginNetBookValue_Amount,lis.EndNetBookValue_Amount,lis.PrincipalRepayment_Amount,lis.InterestPayment_Amount, lis.PrincipalAdded_Amount
,ld.StartDate,ld.EndDate,ld.DayCountConvention,0 BeginBalance, 0 DaysInPeriod,lis.InterestRate InterestRate,ld.PaymentAmount,ld.PrincipalAmount,ld.InterestAmount,0 IsRateChanged,0 IsFunding
,ld.PaymentNumber,ld.PaymentType
FROM LoanIncomeSchedules lis
INNER JOIN #LoanDetails ld ON lis.LoanFinanceId = ld.LoanFinanceId
AND lis.IsSchedule = 1
AND lis.IsLessorOwned = CASE WHEN @IsSyndicated = 1 THEN 0
ELSE 1 END
AND lis.IncomeDate BETWEEN ld.StartDate AND ld.EndDate
AND lis.InterestRate = @InterestRate
ORDER BY lis.IncomeDate
END
FETCH NEXT FROM LoanCursor INTO @LoanFinanceId, @FloatRateIndexDetailId, @InterestRate
END;
CLOSE LoanCursor
DEALLOCATE LoanCursor
SET @FirstInterestRate = (SELECT TOP 1 InterestRate FROM #LoanIncomeRecords ORDER BY IncomeDate)
;WITH PaymentDetails AS
(
SELECT * FROM #LoanIncomeRecords
UNION ALL
SELECT lis.LoanFinanceId,lis.IncomeDate,lis.BeginNetBookValue_Amount,lis.EndNetBookValue_Amount,lis.PrincipalRepayment_Amount PrincipalRepayment,lis.InterestPayment_Amount, lis.PrincipalAdded_Amount
,ld.StartDate,ld.EndDate,ld.DayCountConvention,0 BeginBalance, 0 DaysInPeriod,lis.InterestRate InterestRate,ld.PaymentAmount,ld.PrincipalAmount,ld.InterestAmount,0,0
,ld.PaymentNumber,ld.PaymentType
FROM LoanIncomeSchedules lis
INNER JOIN #LoanDetails ld ON lis.LoanFinanceId = ld.LoanFinanceId
AND lis.IsSchedule = 1
AND lis.IsLessorOwned = CASE WHEN @IsSyndicated = 1 THEN 0
ELSE 1 END
AND (lis.PrincipalRepayment_Amount > 0 OR lis.PrincipalAdded_Amount > 0)
--OR lis.InterestPayment_Amount > 0 TODO: InterestPayment
AND lis.IncomeDate BETWEEN ld.StartDate AND ld.EndDate
)
SELECT * INTO #TempResult FROM PaymentDetails
IF(@IsDistinctRecordNeeded = 1)
BEGIN
INSERT INTO #IncomeDetails_Temp
SELECT DISTINCT * FROM #TempResult
END
ELSE
BEGIN
INSERT INTO #IncomeDetails_Temp
SELECT * FROM #TempResult
END
/*Only for Non-DSL
System adds one day additional interest due to payment event*/
DELETE id FROM #IncomeDetails_Temp id
INNER JOIN #LoanDetails ld ON id.LoanFinanceId = ld.LoanFinanceId
AND ld.IsDailySensitive = 0
WHERE IncomeDate = id.EndDate
INSERT INTO #IncomeDetails
SELECT ROW_NUMBER() OVER(ORDER BY IncomeDate) RowNumber,* FROM #IncomeDetails_Temp
UPDATE #IncomeDetails SET IsRateChanged = 1 WHERE InterestRate != @FirstInterestRate;
UPDATE #IncomeDetails SET IsFunding = 1 WHERE PrincipalAdded != 0;
UPDATE #IncomeDetails SET DayCountConvention = @InterimDayCount WHERE PaymentType = 'Interim'
DECLARE @SDate DATETIME;
DECLARE @EDate DATETIME;
DECLARE @RowCount INT;
DECLARE @LastRow INT;
DECLARE @Row INT;
DECLARE @Days INT;
DECLARE @DayCount NVARCHAR(MAX);
DECLARE @DayCountMethod INT;
DECLARE @IncomeDate DATETIME;
DECLARE @BeginBalance DECIMAL(16,2);
DECLARE @CurrentPaymentType NVARCHAR(11);
DECLARE @NextPaymentType NVARCHAR(11);
DECLARE @CurrentIncomeDate DATETIME;
DECLARE @NextIncomeDate DATETIME;
--IF @PaymentFrequency = 'Monthly'
--	SET @DaysFrequency = 30
--IF @PaymentFrequency = 'Quarterly'
--	SET @DaysFrequency = 90
--IF @PaymentFrequency = 'HalfYearly'
--	SET @DaysFrequency = 180
--IF @PaymentFrequency = 'Yearly'
--	SET @DaysFrequency = 360
SELECT @RowCount = COUNT(*) FROM #IncomeDetails
SELECT @LastRow = MAX(RowNumber) FROM #IncomeDetails
/*To check whether any event occured or not*/
--IF @RowCount > 1
--	SET @IsEventOccured = 1
--ELSE
--	SET @IsEventOccured = 0
SET @Row = 1;
SELECT @DayCount = DayCountConvention FROM #IncomeDetails WHERE RowNumber = @Row
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
IF @RowCount > 1
BEGIN
SELECT @CurrentIncomeDate = IncomeDate FROM #IncomeDetails WHERE RowNumber = @Row
SELECT @NextIncomeDate = IncomeDate FROM #IncomeDetails WHERE RowNumber = @Row + 1
IF(@CurrentIncomeDate != @NextIncomeDate)
SET @IsEventOccured = 1
ELSE
SET @IsEventOccured = 0
END
ELSE
SET @IsEventOccured = 0
SELECT @IncomeDate = IncomeDate, @LFId = LoanFinanceId, @IsRateChanged = IsRateChanged, @SDate = IncomeDate, @IsFunding = IsFunding
,@CurrentPaymentType = PaymentType
FROM #IncomeDetails WHERE RowNumber = @Row;
IF(@IsDSL = 1)
SELECT @IsPaymentReceived = (CASE WHEN PrincipalRepayment != 0 OR InterestRepayment != 0 THEN 1
ELSE 0 END)
FROM #IncomeDetails WHERE RowNumber = @Row;
IF @Row = @LastRow
BEGIN
SELECT @EDate = EndDate FROM #IncomeDetails WHERE RowNumber = @Row;
END
ELSE
BEGIN
SELECT @NextPaymentType = PaymentType FROM #IncomeDetails WHERE RowNumber = @Row + 1
IF @IsAdvance = 1 AND @CurrentPaymentType = 'Interim' AND @NextPaymentType = 'FixedTerm'
SELECT @EDate = EndDate FROM #IncomeDetails WHERE RowNumber = @Row
ELSE
SELECT @EDate = IncomeDate FROM #IncomeDetails WHERE RowNumber = @Row + 1
SELECT @IsRateChangedForNextEvent = IsRateChanged, @IsFundingForNextEvent = IsFunding FROM #IncomeDetails WHERE RowNumber = @Row + 1
END
SET @Days = dbo.DaysInPeriodForLoanInterest(@SDate,@EDate,@IsDSL,@IsRateChanged,@Row,@LastRow,@LFId,ISNULL(@IsRateChangedForNextEvent,0),ISNULL(@IsPaymentReceived,0),ISNULL(@IsFunding,0),ISNULL(@IsFundingForNextEvent,0),@IsEventOccured,@DayCount)
IF @Row = 1
BEGIN
IF(@IncludeRepaymentAmount = 1)
SELECT @BeginBalance = BeginNetBookValue_Amount + PrincipalAdded - PrincipalRepayment FROM #IncomeDetails WHERE RowNumber = @Row;
ELSE
SELECT @BeginBalance = BeginNetBookValue_Amount + PrincipalAdded FROM #IncomeDetails WHERE RowNumber = @Row;
END
ELSE
SELECT @BeginBalance = BeginNetBookValue_Amount - PrincipalRepayment + PrincipalAdded FROM #IncomeDetails WHERE RowNumber = @Row;
UPDATE #IncomeDetails SET DaysInPeriod = @Days
,BeginBalance = @BeginBalance
WHERE RowNumber = @Row;
SET @Row = @Row + 1;
END
INSERT INTO #Result(InterestRate,InterestAmount,ChangeAmount,Balance,
DaysInPeriod,PaymentAmount,PrincipalAmount,TaxAmount,TotalInterest,TotalAmountDue,InterestPayment,DownPayment,PaymentNumber,PaymentType)
SELECT InterestRate,ROUND((BeginBalance*DaysInPeriod*InterestRate)/@DayCountMethod,2), -1 * PrincipalRepayment + PrincipalAdded,BeginBalance
,DaysInPeriod,PaymentAmount,PrincipalAmount,0,0,0,0,0,PaymentNumber,PaymentType
FROM #IncomeDetails
/*Interest Payment*/
;WITH CTE_InterestPayment AS
(
SELECT ISNULL(SUM(lp.Interest_Amount),0) InterestPayment FROM
LoanPaymentSchedules lp
INNER JOIN #LoanDetails ld ON lp.LoanFinanceId = ld.LoanFinanceId
AND lp.IsActive = 1
AND lp.StartDate BETWEEN ld.StartDate AND ld.EndDate
WHERE (lp.PaymentType = 'Paydown' OR lp.IsFromReceiptPosting = 1)
)
UPDATE #Result SET InterestPayment = CTE_InterestPayment.InterestPayment - ISNULL(@PreviousInterest,0)
FROM CTE_InterestPayment
/*Interest Payment*/
/*Down Payment Selection*/
IF @IsDSL = 0 AND @IsAdvance = 1
BEGIN
;WITH CTE_DownPayment AS
(
SELECT ISNULL(SUM(lp.Amount_Amount),0) DownPayment FROM
LoanPaymentSchedules lp
WHERE lp.PaymentType = 'Downpayment'
AND lp.IsActive = 1
AND lp.DueDate BETWEEN @ActualStartDate AND @ActualEndDate
AND lp.LoanFinanceId = @LFinanceId
)
UPDATE #Result SET DownPayment = CTE_DownPayment.DownPayment
FROM CTE_DownPayment
END
ELSE IF @IsDSL = 0 AND @IsAdvance = 0
BEGIN
;WITH CTE_DownPayment AS
(
SELECT ISNULL(SUM(lp.Amount_Amount),0) DownPayment FROM
LoanPaymentSchedules lp
WHERE lp.PaymentType = 'Downpayment'
AND lp.IsActive = 1
AND lp.DueDate = @DueDate
AND lp.LoanFinanceId = @LFinanceId
)
UPDATE #Result SET DownPayment = CTE_DownPayment.DownPayment
FROM CTE_DownPayment
END
/*When we have both Interim & Fixed Pmt for DSL Advance loan*/
IF @IsDSL = 1 AND @IsAdvance = 1 AND @PaymentNumber = 1
BEGIN
DECLARE @PAmount DECIMAL(16,2);
SELECT @PAmount = SUM(lp.Principal_Amount)
FROM LoanPaymentSchedules lp
JOIN #AdvLoanDetails ld ON lp.LoanFinanceId = ld.LoanFinanceId
AND ld.DueDate = lp.DueDate
AND ld.PaymentNumber = lp.PaymentNumber
AND lp.IsActive = 1
AND lp.PaymentType = 'FixedTerm'
UPDATE #Result SET PrincipalAmount = @PAmount
END
/*Added as per the discussion with Kritika since we are not showing the principal change amount
client defect #813*/
IF @IsDSL = 1 AND @IsAdvance = 0 AND @PaymentNumber != 1
BEGIN
DECLARE @PStartDate DATE;
DECLARE @ResultDetailId INT;
DECLARE @PrincipalChangeAmount DECIMAL(16,2);
SELECT @PStartDate = StartDate FROM #IncomeDetails WHERE RowNumber = 1;
SELECT @ResultDetailId = DetailId FROM #Result ORDER BY Balance
SELECT @PrincipalChangeAmount = SUM(lis.PrincipalRepayment_Amount)
FROM dbo.LoanIncomeSchedules lis
JOIN #AdvLoanDetails ld ON lis.LoanFinanceId = ld.LoanFinanceId
AND lis.IsSchedule = 1
AND lis.IsLessorOwned = CASE WHEN @IsSyndicated = 1 THEN 0
ELSE 1 END
AND lis.IncomeDate = DATEADD(DD,-1,@PStartDate)
UPDATE #Result SET ChangeAmount = -1 * @PrincipalChangeAmount WHERE DetailId = @ResultDetailId;
END
IF @IsAdvance = 1 AND @PaymentNumber = 1
UPDATE #Result SET InterestAmount = 0 WHERE PaymentNumber = 1 AND PaymentType != 'Interim'
UPDATE #Result SET TotalInterest = (SELECT SUM(InterestAmount) FROM #Result)
UPDATE #Result SET PrincipalAmount = CASE WHEN @IsDSL = 1 AND @PaymentStructure = 'FixedPrincipal' THEN PrincipalAmount
WHEN @IsDSL = 1 AND @PaymentNumber != 1 AND InterestPayment > 0 THEN PaymentAmount - (TotalInterest - InterestPayment)
WHEN @IsDSL = 1 AND @PaymentNumber != 1 AND PaymentType != 'Interim' THEN PaymentAmount - TotalInterest
ELSE PrincipalAmount END
UPDATE #Result SET Label = CASE WHEN ChangeAmount > 0 THEN 'Funding'
WHEN ChangeAmount < 0 THEN 'Payment'
END
,InterestPayment = CASE WHEN InterestPayment > 0 THEN -1 * InterestPayment
ELSE 0.00
END
UPDATE #Result SET TotalAmountDue = CASE WHEN @IsDSL = 1 AND @PaymentStructure = 'FixedPrincipal' THEN TotalInterest + PrincipalAmount + TaxAmount + InterestPayment
WHEN @IsDSL = 1 THEN TotalInterest + PrincipalAmount + TaxAmount + DownPayment + InterestPayment
ELSE TotalInterest + PrincipalAmount + TaxAmount + DownPayment END
;WITH PrincipalCode AS
(
SELECT Distinct ri.Id InvoiceId,rtl.Name 'ReceivableCode'
FROM dbo.ReceivableInvoices ri
INNER JOIN dbo.ReceivableInvoiceDetails rid ON ri.Id = rid.ReceivableInvoiceId
INNER JOIN dbo.ReceivableDetails rd ON rid.ReceivableDetailId = rd.id
INNER JOIN dbo.Receivables r ON rd.ReceivableId = r.Id
INNER JOIN dbo.ReceivableCodes rc ON r.ReceivableCodeId = rc.Id
INNER JOIN dbo.InvoiceGroupingParameters igp ON rc.ReceivableCategoryId = igp.ReceivableCategoryId
AND rc.ReceivableTypeId = igp.ReceivableTypeId
AND igp.IsActive = 1
INNER JOIN dbo.BillToInvoiceParameters bp ON igp.Id = bp.InvoiceGroupingParameterId
AND ri.BillToId = bp.BillToId
INNER JOIN dbo.ReceivableTypeLabelConfigs rtl ON bp.ReceivableTypeLabelId = rtl.Id
AND rtl.IsActive = 1
INNER JOIN dbo.ReceivableTypes rt ON rc.ReceivableTypeId = rt.Id
WHERE ri.IsActive = 1 AND ri.Id = @InvoiceId
AND rt.Name = 'LoanPrincipal'
)
UPDATE #Result SET PrincipalCodeName = ReceivableCode
FROM PrincipalCode;
;WITH InterestCode AS
(
SELECT Distinct ri.Id InvoiceId,rtl.Name 'ReceivableCode'
FROM dbo.ReceivableInvoices ri
INNER JOIN dbo.ReceivableInvoiceDetails rid ON ri.Id = rid.ReceivableInvoiceId
INNER JOIN dbo.ReceivableDetails rd ON rid.ReceivableDetailId = rd.id
INNER JOIN dbo.Receivables r ON rd.ReceivableId = r.Id
INNER JOIN dbo.ReceivableCodes rc ON r.ReceivableCodeId = rc.Id
INNER JOIN dbo.InvoiceGroupingParameters igp ON rc.ReceivableCategoryId = igp.ReceivableCategoryId
AND rc.ReceivableTypeId = igp.ReceivableTypeId
AND igp.IsActive = 1
INNER JOIN dbo.BillToInvoiceParameters bp ON igp.Id = bp.InvoiceGroupingParameterId
AND ri.BillToId = bp.BillToId
INNER JOIN dbo.ReceivableTypeLabelConfigs rtl ON bp.ReceivableTypeLabelId = rtl.Id
AND rtl.IsActive = 1
INNER JOIN dbo.ReceivableTypes rt ON rc.ReceivableTypeId = rt.Id
WHERE ri.IsActive = 1 AND ri.Id = @InvoiceId
AND rt.Name = 'LoanInterest'
)
UPDATE #Result SET InterestCodeName = ReceivableCode
FROM InterestCode;
INSERT INTO #FinalResult(InterestRate,InterestAmount,ChangeAmount,Balance,DaysInPeriod,PaymentAmount,PrincipalAmount,TaxAmount,TotalInterest,TotalAmountDue
,PrincipalCodeName,InterestCodeName,InterestPayment,Label,DownPayment,PaymentNumber,PaymentType)
SELECT InterestRate,InterestAmount,ChangeAmount,Balance,DaysInPeriod,PaymentAmount,PrincipalAmount,TaxAmount,TotalInterest,TotalAmountDue
,PrincipalCodeName,InterestCodeName,InterestPayment,Label,DownPayment,PaymentNumber,PaymentType FROM #Result WHERE DaysInPeriod > 0 ORDER BY TotalAmountDue DESC;
SELECT DetailId,InterestRate,InterestAmount,ChangeAmount,Balance,DaysInPeriod,PrincipalAmount,TaxAmount,TotalInterest,TotalAmountDue
,PrincipalCodeName,InterestCodeName,InterestPayment,Label,DownPayment FROM #FinalResult;
DROP TABLE #LoanDetails;
DROP TABLE #InterestDetails;
DROP TABLE #LoanIncomeRecords;
DROP TABLE #IncomeDetails;
DROP TABLE #Result;
DROP TABLE #IncomeDetails_Temp;
DROP TABLE #TempResult;
END
DROP TABLE #AdvLoanDetails;
DROP TABLE #FinalResult;
END

GO

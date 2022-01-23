SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetPaymentDueDateForSundryRecurring]
(
@LastDueDate DATE,
@DueDay INT,
@Frequency NVARCHAR(40),
@NumberOfDays INT,
@EndDate DATE OUTPUT
)
AS
BEGIN
SET NOCOUNT ON;
DECLARE @Day INT = 0 ;
DECLARE @PaymentDate DATE;
DECLARE @MonthsToAdd INT;
DECLARE @PaymentNumber INT =1;
SET @MonthsToAdd = CASE WHEN @Frequency = 'Monthly' THEN 1
WHEN @Frequency = 'BiMonthly' THEN 2
WHEN @Frequency = 'Quarterly' THEN 3
WHEN @Frequency = 'HalfYearly' THEN 6
WHEN @Frequency = 'Yearly' THEN 12
ELSE 1 END
IF @Frequency = 'Days'
BEGIN
SET @PaymentDate  = DATEADD(DAY,@NumberOfDays -1 ,@LastDueDate);
END
IF @Frequency = 'Weekly'
BEGIN
SET @PaymentDate = DATEADD(DAY,6,@LastDueDate);
END
IF @Frequency = 'BiWeekly'
BEGIN
SET @PaymentDate = DATEADD(DAY,13,@LastDueDate) ;
END
IF @PaymentDate IS NULL
BEGIN
IF MONTH(@LastDueDate) = MONTH(DATEADD(DAY,1,@LastDueDate))
BEGIN
IF DAY(@LastDueDate) < 	@DueDay
BEGIN
SET @MonthsToAdd =	@MonthsToAdd - 1;
END
END
SET @DueDay = @DueDay - 1;
IF @DueDay = 0
BEGIN
SET @MonthsToAdd  = @MonthsToAdd - 1;
SET @DueDay = 31;
END
SET @LastDueDate = DATEADD(MONTH,@MonthsToAdd,@LastDueDate)
IF DAY(EOMONTH(@LastDueDate)) < @DueDay
BEGIN
SET @Day = DAY(EOMONTH(@LastDueDate))
END
IF @Day = 0
BEGIN
SET @PaymentDate = DATEADD(DAY,@DueDay - DAY(@LastDueDate),@LastDueDate)
END
ELSE
BEGIN
SET @PaymentDate = DATEADD(DAY,@Day - DAY(@LastDueDate),@LastDueDate)
END
IF NOT(MONTH(@PaymentDate) = MONTH(DATEADD(DAY,1,@PaymentDate)))
BEGIN
IF @DueDay != 31
BEGIN
SET @PaymentDate =  DATEADD(DAY,-1,@PaymentDate);
END
END
END
SET @EndDate = @PaymentDate
SET NOCOUNT OFF
END

GO

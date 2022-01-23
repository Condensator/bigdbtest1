SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[DaysInPeriodForLoanInterest](
@SDate DATE,
@EDate DATE,
@IsDSL TINYINT,
@IsRateChanged TINYINT,
@Row INT,
@LastRow INT,
@LFId BIGINT,
@IsRateChangedForNextEvent TINYINT,
@IsPaymentReceived TINYINT,
@IsFunding TINYINT,
@IsFundingForNextEvent TINYINT,
@IsEventOccured TINYINT,
@DayCount NVARCHAR(MAX)
)
RETURNS INT
AS
BEGIN
DECLARE @Days INT;
DECLARE @InterestAccrued DECIMAL(16,2);
IF @Row = @LastRow
BEGIN
SELECT @InterestAccrued = InterestAccrued_Amount FROM LoanIncomeSchedules WHERE LoanFinanceId = @LFId AND IsAccounting = 1 AND IsSchedule = 1
AND IncomeDate = @EDate
IF(@IsEventOccured = 0 AND @DayCount = '_30By360')
SET @Days = 30
ELSE IF(@InterestAccrued = 0)
SET @Days = DATEDIFF(DD,@SDate,DATEADD(DD,-1,@EDate)) + 1
ELSE
BEGIN
IF(@IsPaymentReceived = 1)
SET @Days = DATEDIFF(DD,@SDate,@EDate)
ELSE
SET @Days = DATEDIFF(DD,@SDate,@EDate) + 1
END
END
ELSE IF(@Row = 1)
BEGIN
IF(@IsRateChangedForNextEvent = 1 OR @IsFundingForNextEvent = 1)
SET @Days = DATEDIFF(DD,@SDate,@EDate)
ELSE
SET @Days = DATEDIFF(DD,@SDate,@EDate) + 1
END
ELSE
BEGIN
IF((@IsRateChanged = 1 AND @IsRateChangedForNextEvent = 1) OR (@IsFunding = 1 AND @IsFundingForNextEvent = 1))
SET @Days = DATEDIFF(DD,@SDate,@EDate)
ELSE IF((@IsRateChanged = 1 AND @IsRateChangedForNextEvent = 0) OR (@IsFunding = 1 AND @IsFundingForNextEvent = 0))
SET @Days = DATEDIFF(DD,@SDate,@EDate) + 1
ELSE IF((@IsPaymentReceived = 1 AND @IsRateChangedForNextEvent = 1) OR (@IsPaymentReceived = 1 AND @IsFundingForNextEvent = 1))
SET @Days = DATEDIFF(DD,@SDate,@EDate) - 1
ELSE
SET @Days = DATEDIFF(DD,@SDate,@EDate)
END
RETURN @Days;
END

GO

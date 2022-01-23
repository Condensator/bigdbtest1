SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[DaysInPeriod](
@FromDate   DATE,
@ToDate     DATE,
@DayCountConvention NVARCHAR(MAX)
)
RETURNS INT
AS
BEGIN
DECLARE @Days INT;
IF(@DayCountConvention = '_30By360')
BEGIN
DECLARE @D1 INT;
DECLARE @D2 INT;
DECLARE @LD1 INT;
DECLARE @LD2 INT;
SET @FromDate = DATEADD(DD,-1,@FromDate);
SET @LD1 = DAY(EOMONTH(@FromDate));
SET @LD2 = DAY(EOMONTH(@ToDate));
SET @D1 = DAY(@FromDate);
SET @D2 = DAY(@ToDate);
IF(@LD1 = @D1)
SET @D1 = 30
IF(@LD2 = @D2)
SET	@D2 = 30
SET @Days = ((360 * (DATEPART(YY,@ToDate)-DATEPART(YY,@FromDate)) + 30 * (DATEPART(MM,@ToDate)-DATEPART(MM,@FromDate))) + (@D2-@D1));
END
IF(@DayCountConvention = 'ActualBy365' OR @DayCountConvention = 'ActualBy360')
BEGIN
SET @Days = DATEDIFF(DD,@FromDate,@ToDate) + 1;
END
RETURN @Days;
END

GO

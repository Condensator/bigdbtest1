SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetDaysBetweenLBDayAndEOM]
(
@Date DATETIME
)
RETURNS INT
AS
BEGIN
DECLARE @result INT
DECLARE @EOMDate DATETIME
DECLARE @LBDate DATETIME
SET @EOMDate=(SELECT DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,@Date)+1,0)))
SET @LBDate= (SELECT MAX(BusinessDate) FROM BusinessCalendarDetails
JOIN BusinessCalendars ON BusinessCalendarDetails.BusinessCalendarId= BusinessCalendars.Id
WHERE BusinessCalendars.IsActive=1 AND BusinessCalendarDetails.IsHoliday=0
AND BusinessCalendarDetails.IsWeekday=1 AND BusinessCalendarDetails.BusinessDate<@EOMDate)
IF @LBDate!=@Date
BEGIN
SET @result=0
END
ELSE
BEGIN
SET @result=DATEDIFF(DAY,@Date, @EOMDate)
END
RETURN @result
END

GO

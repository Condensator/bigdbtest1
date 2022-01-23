SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetStartDateOfType] (@AsOfDate DATETIME , @Type NVARCHAR(MAX), @FiscalYearStartMonth INT)
RETURNS DATETIME
BEGIN
DECLARE @OutputDate DATETIME
IF (@Type = 'Yearly')
BEGIN
SET @OutputDate = DATEADD(MM, DATEDIFF(MM, 0, @AsOfDate) - (12 + DATEPART(MM, @AsOfDate) - @FiscalYearStartMonth) % 12, 0)
END
IF (@Type = 'Quarterly')
BEGIN
SET @OutputDate = DATEADD(QQ, DATEDIFF(QQ, @FiscalYearStartMonth, @AsOfDate), 0)
END
IF (@Type = 'Monthly')
BEGIN
SET @OutputDate = DATEADD(MM, DATEDIFF(MM, 0, @AsOfDate), 0)
END
IF (@Type = 'TillDate')
BEGIN
SET @OutputDate = @AsOfDate
END
RETURN @OutputDate
END

GO

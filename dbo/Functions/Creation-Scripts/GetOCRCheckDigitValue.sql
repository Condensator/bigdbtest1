SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Function [dbo].[GetOCRCheckDigitValue]
(
@Input NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
DECLARE @LengthOfInput BIGINT = LEN(@Input);
DECLARE @Start BIGINT = 1;
DECLARE @Sum BIGINT = 0;
DECLARE @Product BIGINT = 0;
DECLARE @CurrentDigit BIGINT = 0;
WHILE @Start <= @LengthOfInput
BEGIN
IF(@Start % 2 = 0)
SET @Product = (2 * CONVERT(BIGINT, SUBSTRING(@Input, @Start, 1)));
ELSE
SET @Product = (1 * CONVERT(BIGINT, SUBSTRING(@Input, @Start, 1)));
WHILE @Product > 0
BEGIN
SET @CurrentDigit = (@Product % 10);
SET @Sum = @Sum + @CurrentDigit;
SET @Product = (@Product - @CurrentDigit) / 10;
END
SET @Start = @Start + 1;
END
RETURN (CASE WHEN (@Sum % 10 = 0) THEN @Sum ELSE (@Sum - (@Sum % 10) + 10) END) - @Sum;
END

GO

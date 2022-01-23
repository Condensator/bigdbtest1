SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetParsedString]
(
@ActualData NVARCHAR(MAX),
@IsLeftTrim BIT=0,
@RequiredLength INT,
@FillChar CHAR=''
)
RETURNS
NVARCHAR(MAX)
AS
BEGIN
DECLARE @ResultData NVARCHAR(MAX)
IF(LEN(@ActualData)=@RequiredLength)
SET @ResultData =@ActualData
IF(LEN(@ActualData)<@RequiredLength)
BEGIN
IF(@IsLeftTrim=1)
SET @ResultData=LEFT(REPLICATE(@FillChar, @RequiredLength - LEN(@ActualData) )+@ActualData,@RequiredLength)
IF(@IsLeftTrim=0)
SET @ResultData=RIGHT(@ActualData+REPLICATE(@FillChar, @RequiredLength - LEN(@ActualData) ),@RequiredLength)
END
IF(LEN(@ActualData)>@RequiredLength)
BEGIN
IF(@IsLeftTrim=1)
SET @ResultData = RIGHT(@ActualData, @RequiredLength)
IF(@IsLeftTrim=0)
SET @ResultData = LEFT(@ActualData, @RequiredLength)
END
RETURN @ResultData
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetAddressFormat]
(
@Address1 NVARCHAR(300),
@Address2 NVARCHAR(100),
@City NVARCHAR(80),
@State NVARCHAR(100),
@PostalCode NVARCHAR(50)
)
RETURNS VARCHAR(1000)
AS
BEGIN
--DECLARE @Address1 NVARCHAR(300) = NULL
--DECLARE @Address2 NVARCHAR(100) = 'A2'
--DECLARE @City NVARCHAR(80) = 'C'
--DECLARE @State NVARCHAR(100) ='S'
--DECLARE @PostalCode NVARCHAR(50) = '34'
DECLARE @Address VARCHAR(1000)
SET @Address = ''
IF @Address1 IS NOT NULL AND LEN(@Address1) > 0
SET @Address = @Address1 + ', ';
ELSE
SET @Address = @Address;
IF @Address2 IS NOT NULL AND LEN(@Address2) > 0
SET @Address =  @Address + @Address2 + ', '
ELSE
SET @Address = @Address;
IF @City IS NOT NULL AND LEN(@City) > 0
SET @Address =  @Address + @City + ', '
ELSE
SET @Address = @Address;
IF @State IS NOT NULL AND LEN(@State) > 0
SET @Address =  @Address + @State + ', '
ELSE
SET @Address = @Address;
IF @PostalCode IS NOT NULL AND LEN(@PostalCode) > 0
SET @Address =  @Address + @PostalCode + ', '
ELSE
SET @Address = @Address;
/*To Remove Last comma*/
IF LEN(@Address) > 0
SET @Address = LEFT(RTRIM(@Address), (LEN(RTRIM(@Address))) - 1);
ELSE
SET @Address = '';
RETURN @Address
END

GO

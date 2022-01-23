SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[IsValidUrl]
(
    @Url varchar(MAX)
)
RETURNS BIT
AS
BEGIN

	DECLARE @http NVARCHAR(7) = 'http://'
	DECLARE @https NVARCHAR(8) = 'https://'
	
	IF (CHARINDEX(@http, @url) > 0 AND (CHARINDEX(@http, @url) <> 1 OR (LEN(@Url) - LEN(REPLACE(@Url, @http, '')))/LEN(@http) > 1)) 
		OR (CHARINDEX(@https, @url) > 0 AND (CHARINDEX(@https, @url) <> 1) OR (LEN(@Url) - LEN(REPLACE(@Url, @https, '')))/LEN(@https) > 1)
    BEGIN
        RETURN 0;
    END

    SET @Url = (SELECT REPLACE(@Url,@http,''))
    SET @Url = (SELECT REPLACE(@Url,@https,''))

    IF (CHARINDEX('/', @Url) !=0)
        SET @Url = SUBSTRING(@Url, 0, CHARINDEX('/', @Url))

    IF (@Url LIKE '%[^a-zA-Z0-9.]%' OR CHARINDEX('.', @Url) = 0)
    BEGIN
        RETURN 0;
    END
	
	IF (SELECT COUNT(*) FROM STRING_SPLIT(@Url,'.') WHERE value = '') > 0
	BEGIN
        RETURN 0;
    END

    RETURN 1
END

GO

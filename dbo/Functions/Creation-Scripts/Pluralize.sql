SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [dbo].[Pluralize]
(
    @Name sysname
)
RETURNS sysname
As BEGIN
	DECLARE @PluralVersion sysname = ''
    DECLARE @NounVersions TABLE(Term sysname NOT NULL)
    DECLARE @QueryString nvarchar(4000) SET @QueryString = N'FORMSOF(INFLECTIONAL,"' + @Name + N'")'
    INSERT INTO @NounVersions SELECT TOP 10 display_term FROM sys.dm_fts_parser(@QueryString,1033,0,0)
    SELECT TOP 1 @PluralVersion = Term  FROM @NounVersions WHERE Term Not Like '%''%' AND RIGHT(Term,1) = 's'
    SET @PluralVersion = UPPER(LEFT(@PluralVersion,1))+LOWER(SUBSTRING(@PluralVersion,2,LEN(@PluralVersion)))
	if @PluralVersion='' set @PluralVersion=@Name + 's'
    return @PluralVersion 
End

GO

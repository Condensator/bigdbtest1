SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Jeba Singh
-- Create date: 19 July 2013
-- Description:	To update Id columns in case of self-referencing entities
-- =============================================
CREATE PROC [dbo].[UpdateSelfReferenceId]
(
 @val [dbo].UpdateSelfReference READONLY,
 @TableName NVarChar(128)
)
AS
SET NOCOUNT ON;
DECLARE @sql NVARCHAR(max)
SET @sql=(Select ' UPDATE ' + @TableName + ' SET ' + S.Setters + ' Where Id=' + cast(S.Id as varchar(30)) + ';' from @val S for xml path(''));

EXECUTE sp_executesql @sql

SET @sql=N'Select [Id],Cast(RowVersion as BigInt) RowVersion from ' + @TableName + ' where Id in (Select s.Id from @tvp s)'
EXECUTE sp_executesql @sql,N'@tvp dbo.UpdateSelfReference READONLY',@val


GO

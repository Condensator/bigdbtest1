SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[UpdateTableColumns]
(
 @val [dbo].UpdateColumn READONLY,
 @TableName NVARCHAR(128),
 @IncludeRowVersion BIT,
 @PreserveXml BIT = 0
)
AS
SET NOCOUNT ON;

DECLARE @sql NVARCHAR(max)

IF(@IncludeRowVersion = 1)
BEGIN

	IF(@PreserveXml = 1)
	BEGIN
	SET @sql=(Select ' UPDATE ' + @TableName + ' SET ' + S.Setters + ' OUTPUT Deleted.Id, Deleted.RowVersion as PrevRowVersion, Inserted.RowVersion as NewRowVersion Where Id=' + cast(S.Id as varchar(30)) + ';' from @val S);
	END
	ELSE
	BEGIN
	SET @sql=(Select ' UPDATE ' + @TableName + ' SET ' + S.Setters + ' OUTPUT Deleted.Id, Deleted.RowVersion as PrevRowVersion, Inserted.RowVersion as NewRowVersion Where Id=' + cast(S.Id as varchar(30)) + ';' from @val S for xml path(''));
	END
	IF OBJECT_ID('tempdb..#OutputTable') IS NOT NULL
		DROP TABLE #OutputTable

	CREATE TABLE #OutputTable 
	(
		Id BIGINT null,
		PrevRowVersion BIGINT,
		NewRowVersion BIGINT
	)
	INSERT INTO #OutputTable EXECUTE sp_executesql @sql

	SELECT a.Id, 1 as ErrorCode FROM #OutputTable a Join @val b on a.ID = b.Id WHERE (b.RowVersion is not null AND a.PrevRowVersion <> b.RowVersion)
END
ELSE
BEGIN
	IF(@PreserveXml = 1)
	BEGIN
	SET @sql=(Select ' UPDATE ' + @TableName + ' SET ' + S.Setters + ' Where Id =' + cast(S.Id as varchar(30)) + ';' from @val S);
	END
	ELSE
	BEGIN
	SET @sql=(Select ' UPDATE ' + @TableName + ' SET ' + S.Setters + ' Where Id =' + cast(S.Id as varchar(30)) + ';' from @val S for xml path(''));
	END
	EXECUTE sp_executesql @sql
END

GO

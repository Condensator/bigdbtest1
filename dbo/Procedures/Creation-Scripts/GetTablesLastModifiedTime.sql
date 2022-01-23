SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetTablesLastModifiedTime]
(
	@TableNamesCsv NVARCHAR(MAX) NULL
)
AS
BEGIN

IF NOT EXISTS(select 1 from sys.dm_exec_requests where command = 'ALTER INDEX')
BEGIN

	SELECT 
	Item [TableName]
	INTO #TableNames
	FROM ConvertCSVToStringTable(@TableNamesCsv, ',')

	SELECT
		   tbl.name [TableName]
		  ,MAX(ius.last_user_update) [LastModifiedTime]
	FROM sys.dm_db_index_usage_stats ius 
	INNER JOIN sys.tables tbl ON (tbl.OBJECT_ID = ius.OBJECT_ID)
	INNER JOIN #TableNames ON tbl.name = #TableNames.TableName
	WHERE ius.index_id = 1
	GROUP BY tbl.name

END

END

GO

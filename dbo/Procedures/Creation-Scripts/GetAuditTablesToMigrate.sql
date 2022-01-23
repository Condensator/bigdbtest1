SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetAuditTablesToMigrate]
(
	@LastProcessedLSN LastProcessedLSNForDataMigration READONLY
)
AS
BEGIN
	DECLARE @SQL NVARCHAR(MAX) = ''
	CREATE TABLE #Temp
	(
		TableName		 NVARCHAR(100),
		CTTableName		 NVARCHAR(100),
		TotalRecords     BIGINT,
		LastProcessedLsn BINARY(10)
	)
	
	SET @SQL = '' + CHAR(13) + STUFF((
	SELECT 'INSERT INTO #Temp(TableName, TotalRecords, CTTableName, LastProcessedLsn) SELECT ''' +  tbl.TableName
	+ ''', COUNT(1), ''' + tbl.CTTableName + ''', ' +   IIF(LSN.TableName IS NULL,'0x0',CONVERT(NVARCHAR(MAX), LSN.[ProcessedLsn], 1)) 
	+ ' FROM cdc.' + tbl.CTTableName + IIF(LSN.TableName IS NULL,'',' WHERE __$start_lsn > ' + CONVERT(NVARCHAR(MAX), LSN.[ProcessedLsn], 1))
	+ ' HAVING COUNT(1) > 0' + CHAR(13)
	FROM AuditTablesView tbl
	LEFT OUTER JOIN @LastProcessedLSN LSN
	ON LSN.TableName = tbl.TableName
	FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 0, '')
	
	EXEC sp_executesql @SQL
	
	SELECT * FROM #Temp  
	
	DROP TABLE #Temp
END

GO

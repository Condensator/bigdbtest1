SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[PurgeCDCData]
(
	@RetentionPeriodInDays INT,
	@LastProcessedLSN LastProcessedLSNForDataPurging READONLY
)
AS
BEGIN
	DECLARE @SQL NVARCHAR(MAX) = ''

	SELECT @SQL = STUFF((
	SELECT CHAR(13) + 'DELETE  CT '+ CHAR(13) +'FROM cdc.dbo_' + ATV.TableName + '_CT CT' + 
	CHAR(13) + 'INNER JOIN cdc.lsn_time_mapping LSNT ON CT.__$start_lsn = LSNT.start_lsn' +
	CHAR(13) + 'WHERE __$start_lsn <= '+CONVERT(NVARCHAR(MAX), lsn.[ProcessedLsn], 1) +' AND LSNT.tran_end_time <= '
	+'DATEADD(dd, ' + CAST(@RetentionPeriodInDays AS VARCHAR(3)) + ' * -1 ,GETDATE()) ' 
	+ ';' + CHAR(13) 
	FROM AuditTablesView ATV
	INNER JOIN @LastProcessedLSN lsn ON ATV.TableName = lsn.TableName
	FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 0, ' ')
	
	EXEC sp_executesql @SQL
END

GO

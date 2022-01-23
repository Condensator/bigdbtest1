SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[CreateSynonymForTables]
(@sourceDBName sysname
,@SynPrefix varchar(3)='stg'
)
as
DECLARE @sql NVARCHAR(max)=''
SET @sql='delete from Mig_StagingTableLists Where TableName in ( select Name from ' + @sourceDBName + '.sys.tables where type=''U'' and is_ms_shipped=0)'
EXEC sp_executesql @sql
SET @sql='Insert into Mig_StagingTableLists (TableName,DatabaseName,CreatedById,CreatedTime) select name,''' + @sourceDBName + ''', 1, Getdate() from ' + @sourceDBName + '.sys.tables where type=''U'' and is_ms_shipped=0'
EXEC sp_executesql @sql
SET @sql=''
SELECT @sql =  @sql +'IF OBJECT_ID(''dbo.' +@SynPrefix + TableName+''') IS NOT NULL DROP SYNONYM dbo.'+ @SynPrefix + TableName + ';'+ CHAR(10) + ';' from Mig_StagingTableLists
WHERE DatabaseName = @sourceDBName
EXEC sp_executesql @sql
SET @sql=''
SELECT @sql =  @sql + 'Create synonym dbo.' + @SynPrefix + TableName + ' for ' + @sourceDBName + '.dbo.' + TableName + ';' from Mig_StagingTableLists
WHERE DatabaseName = @sourceDBName
EXEC sp_executesql @sql

GO

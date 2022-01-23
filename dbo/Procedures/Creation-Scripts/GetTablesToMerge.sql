SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[GetTablesToMerge]
(@sourceDBName nvarchar(100))
as
begin
DECLARE @sql NVARCHAR(max)='';
set @sql='exec ' + @SourceDBName + '.dbo.StoreTablesRowCount 1'
EXEC sp_executesql @sql
if exists(select * from sys.synonyms where name='Mig_TablesRCSyn')
Drop synonym dbo.Mig_TablesRCSyn;
set @sql='create synonym dbo.Mig_TablesRCSyn for ' + @SourceDBName + '.dbo.Mig_TablesRowCounts;'
EXEC sp_executesql @sql;
select pre.tableName AS TableName,t.MaxId AS PreMigrationMaxId,t.HasIdentity AS HasIdentity, post.RowsCount AS RowsCount
from Mig_TablesRowCounts pre 
join dbo.Mig_TablesRCSyn post on pre.tableName=post.tableName and pre.PostMigration=0 and post.PostMigration=1 
join Mig_LWTables t on t.TableName=pre.TableName 
left join PurgeTableConfigs on PurgeTableConfigs.TableName = pre.tableName 
where post.RowsCount>0 and pre.RowsCount<>post.RowsCount and post.tableName not like 'mig_%'  
and pre.tableName NOT IN ('JobStepInstanceLogs','JobServiceDetails') and PurgeTableConfigs.TableName is null
order by post.RowsCount desc
end

GO

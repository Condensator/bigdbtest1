SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[CompareRowVersion]
(@sourceDBname sysname)
as
DECLARE @tableName sysname
DECLARE @sql NVARCHAR(max)='';
DECLARE @PreMigMaxId bigint
declare cur cursor for select pre.tableName,t.MaxId from Mig_TablesRowCounts pre join Mig_LWTables t on t.TableName=pre.TableName where pre.PostMigration=0 and pre.RowsCount>0 and pre.tableName not like 'mig_%' and t.MaxId>0 order by pre.TableName
create table #t (TableName sysname not null, Id bigint not null);
open cur
fetch next from cur into @tableName,@PreMigMaxId
while @@FETCH_STATUS=0
begin
set @sql='insert into #t select ''' + @tableName + ''',t1.Id from ' + @tableName + ' t1 join ' + @sourceDBname + '.dbo.' + @tableName + ' t2 on t1.Id=t2.Id and t1.RowVersion<>t2.RowVersion and t1.Id<=' + Cast(@PreMigMaxId as varchar(100));
--print @sql
EXEC sp_executesql @sql;
fetch next from cur into @tableName,@PreMigMaxId
end
close cur
deallocate cur
select * from #t order by TableName
drop table #t

GO

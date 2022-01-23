SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROCEDURE [dbo].[ClearNonPresetTables]
As
declare @Table sysname,@HasFK bit,@HasIdentity bit
declare @ConfigTable sysname,@DeleteWhereClause nvarchar(100),@UpdateSQL nvarchar(250)
declare @sql nvarchar(2000)

Exec sp_MSForEachTable 'Alter Table ? NoCheck Constraint All';

declare cur cursor read_only FORWARD_ONLY STATIC for
select s.name,OBJECTPROPERTY(object_id,'TableHasForeignRef'),OBJECTPROPERTY(object_id,'TableHasIdentity'),p.DeleteWhereClause,p.UpdateSQL,p.Name as ConfigTable from sys.tables s left join PresetTableConfigs p on s.name=p.Name where is_ms_shipped=0 and is_memory_optimized=0
open cur
fetch next from cur into @Table,@HasFK,@HasIdentity,@DeleteWhereClause,@UpdateSQL,@ConfigTable
while @@FETCH_STATUS=0
begin
	set @sql=''
	if @DeleteWhereClause is not null and len(@DeleteWhereClause)>1
	begin
		set @sql='Delete from ' + @Table + ' where ' + @DeleteWhereClause
		if @HasIdentity=1
		begin
			set @sql=@sql+ ';declare @maxId bigint; select @maxId=IsNull(Max(Id),0) from ' + @Table
			set @sql=@sql+ ';DBCC CHECKIDENT ([' + @Table + '], RESEED,@maxId);'
		end
		set @sql=@sql+ ';Alter INDEX ALL ON [dbo].[' + @Table + '] rebuild WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON);'
	end
	else if @ConfigTable is not null and len(@UpdateSQL)>1
		set @sql=@UpdateSQL
	else if @ConfigTable is not null
		set @sql='' /*Ignore this preset table*/
	else if @HasFK=1
	begin
		set @sql='Delete from ' + @Table
		if @HasIdentity=1
			set @sql=@sql+ ';DBCC CHECKIDENT ([' + @Table + '], RESEED,1);'

		set @sql=@sql+ ';Alter INDEX ALL ON [dbo].[' + @Table + '] rebuild WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON);'
	end
	else
		set @sql='truncate table ' + @Table
	
	if len(@sql)>1
		exec (@sql)

	fetch next from cur into @Table,@HasFK,@HasIdentity,@DeleteWhereClause,@UpdateSQL,@ConfigTable
end
close cur
deallocate cur

Exec sp_MSForEachTable 'Alter Table ? WITH Check Check Constraint All';

GO

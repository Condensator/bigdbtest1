SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Proc [dbo].[DropObjects]
(
	@includeIndexes bit=0,
	@runAsExclusive bit=0,
	@DropAll bit=0
)
as
declare @stmt nvarchar(max)
declare @n char(1)
set @n = char(10)

if @runAsExclusive=1
begin
	set @stmt='alter database ' +  db_name() + ' set single_user with rollback immediate;'
	exec sp_executesql @stmt
end

set @stmt='drop procedure '
if @DropAll=0
	select @stmt = isnull( @stmt + @n, '' ) +
		'[dbo].[' + name + '],'
	from sys.procedures where schema_id = SCHEMA_ID('dbo') and name not like 'u[_]%'
	and name in (select p.name from sys.parameter_type_usages u join sys.types t on t.user_type_id=u.user_type_id
	and t.is_table_type=1 and t.is_user_defined=1
	join sys.procedures p on p.object_id=u.object_id)
else
	select @stmt = isnull( @stmt + @n, '' ) +
		'[dbo].[' + name + '],'
	from sys.procedures where schema_id = SCHEMA_ID('dbo') and name not like 'u[_]%' and name <> 'DropObjects'
if len(@stmt)>17
begin
	set @stmt=LEFT(@stmt,LEN(@stmt)-1)
	exec sp_executesql @stmt
	--print @stmt
end

set @stmt=''
select @stmt = isnull( @stmt + @n, '' ) +
	'drop function [dbo].[' + name + ']'
from sys.objects
where type in ( 'FN', 'IF', 'TF' )
and schema_id = SCHEMA_ID('dbo') and name not like 'u[_]%'
exec sp_executesql @stmt

if @DropAll=1
begin
	set @stmt=''
	-- check constraints
	select @stmt = isnull( @stmt + @n, '' ) +
	'alter table [dbo].[' + object_name( parent_object_id ) + ']  drop constraint [' + name + ']'
	from sys.check_constraints
	where schema_id = SCHEMA_ID('dbo') and name not like 'u[_]%'
	exec sp_executesql @stmt

	set @stmt=''
	select @stmt = isnull( @stmt + @n, '' ) +
		'drop view [dbo].[' + name + ']'
	from sys.views
	where schema_id = SCHEMA_ID('dbo') and name not like 'u[_]%'
	exec sp_executesql @stmt
end

set @stmt=''
select @stmt = isnull( @stmt + @n, '' ) +
    'drop type [dbo].[' + name + ']'
from sys.types where is_user_defined = 1
and schema_id = SCHEMA_ID('dbo') and name not like 'u[_]%'
exec sp_executesql @stmt

set @stmt=''
if @includeIndexes=1
begin
		select @stmt = isnull( @stmt + @n, '' ) + 'DROP INDEX ' + ix.name + ' ON ' + o.name + ';' FROM  sys.indexes ix
	JOIN sys.objects o ON ix.OBJECT_ID = o.OBJECT_ID JOIN sys.schemas ON o.schema_id = schemas.schema_id 
	WHERE o.is_ms_shipped = 0 and schemas.name=N'dbo'
	 AND NOT EXISTS (SELECT 1 FROM sys.objects WHERE objects.name = ix.name) 
	 AND ix.name IS NOT NULL and ix.name not like 'u[_]%'
	 AND ix.type_desc != 'CLUSTERED'
	 exec sp_executesql @stmt
end

if @runAsExclusive=1
begin
	set @stmt='alter database ' +  db_name() + '  set multi_user with rollback immediate;'
	exec sp_executesql @stmt
end

GO

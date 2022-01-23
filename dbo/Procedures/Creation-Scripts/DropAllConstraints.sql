SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE proc [dbo].[DropAllConstraints]
as
DECLARE @sql NVARCHAR(MAX);
SET @sql = N'';
SELECT @sql = @sql + N'
ALTER TABLE ' + QUOTENAME(s.name) + N'.'
+ QUOTENAME(t.name) + N' DROP CONSTRAINT '
+ QUOTENAME(c.name) + ';'
FROM sys.objects AS c
INNER JOIN sys.tables AS t
ON c.parent_object_id = t.[object_id]
join Mig_LWTables on t.name=Mig_LWTables.tableName
INNER JOIN sys.schemas AS s
ON t.[schema_id] = s.[schema_id]
--WHERE c.[type] IN ('D','C','F','PK','UQ')
WHERE c.[type] IN ('F')
ORDER BY c.[type];
EXEC sys.sp_executesql @sql;
declare @qry nvarchar(max);
select @qry =
(SELECT  'DROP INDEX ' + indexes.name + ' ON ' + OBJECT_NAME(indexes.object_id) + '; '
from sys.indexes
inner join sys.tables on tables.object_id = indexes.object_id
inner join Mig_LWTables on tables.name = Mig_LWTables.tableName
and tables.type='U' and is_ms_shipped=0
where (indexes.type=2 and indexes.is_primary_key = 0)
for xml path(''));
exec sp_executesql @qry

GO

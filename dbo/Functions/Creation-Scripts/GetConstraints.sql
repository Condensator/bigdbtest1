SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create function [dbo].[GetConstraints]
(@table_name SYSNAME)
RETURNS NVARCHAR(MAX)
AS
BEGIN
DECLARE
@object_name SYSNAME
, @object_id INT
SELECT
@object_name = '[' + s.name + '].[' + o.name + ']'
, @object_id = o.[object_id]
FROM sys.objects o WITH (NOWAIT)
JOIN sys.schemas s WITH (NOWAIT) ON o.[schema_id] = s.[schema_id]
WHERE s.name + '.' + o.name = @table_name
AND o.[type] = 'U'
AND o.is_ms_shipped = 0
DECLARE @SQL NVARCHAR(MAX) = ''
;WITH index_column AS
(
SELECT
ic.[object_id]
, ic.index_id
, ic.is_descending_key
, ic.is_included_column
, c.name
FROM sys.index_columns ic WITH (NOWAIT)
JOIN sys.columns c WITH (NOWAIT) ON ic.[object_id] = c.[object_id] AND ic.column_id = c.column_id
WHERE ic.[object_id] = @object_id
),
fk_columns AS
(
SELECT
k.constraint_object_id
, cname = c.name
, rcname = rc.name
FROM sys.foreign_key_columns k WITH (NOWAIT)
JOIN sys.columns rc WITH (NOWAIT) ON rc.[object_id] = k.referenced_object_id AND rc.column_id = k.referenced_column_id
JOIN sys.columns c WITH (NOWAIT) ON c.[object_id] = k.parent_object_id AND c.column_id = k.parent_column_id
WHERE k.parent_object_id = @object_id
)
SELECT @SQL = ISNULL((SELECT (
SELECT CHAR(13) +
'ALTER TABLE ' + @object_name + ' WITH'
+ CASE WHEN fk.is_not_trusted = 1
THEN ' NOCHECK'
ELSE ' CHECK'
END +
' ADD CONSTRAINT [' + fk.name  + '] FOREIGN KEY('
+ STUFF((
SELECT ', [' + k.cname + ']'
FROM fk_columns k
WHERE k.constraint_object_id = fk.[object_id]
FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '')
+ ')' +
' REFERENCES [' + SCHEMA_NAME(ro.[schema_id]) + '].[' + ro.name + '] ('
+ STUFF((
SELECT ', [' + k.rcname + ']'
FROM fk_columns k
WHERE k.constraint_object_id = fk.[object_id]
FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '')
+ ')'
+ CASE
WHEN fk.delete_referential_action = 1 THEN ' ON DELETE CASCADE'
WHEN fk.delete_referential_action = 2 THEN ' ON DELETE SET NULL'
WHEN fk.delete_referential_action = 3 THEN ' ON DELETE SET DEFAULT'
ELSE ''
END
+ CASE
WHEN fk.update_referential_action = 1 THEN ' ON UPDATE CASCADE'
WHEN fk.update_referential_action = 2 THEN ' ON UPDATE SET NULL'
WHEN fk.update_referential_action = 3 THEN ' ON UPDATE SET DEFAULT'
ELSE ''
END
+ CHAR(13) + 'ALTER TABLE ' + @object_name + case when fk.is_disabled=1 then 'NOCHECK' else 'CHECK' end + ' CONSTRAINT [' + fk.name  + ']' + CHAR(13)
FROM sys.foreign_keys fk WITH (NOWAIT)
JOIN sys.objects ro WITH (NOWAIT) ON ro.[object_id] = fk.referenced_object_id
WHERE fk.parent_object_id = @object_id
FOR XML PATH(N''), TYPE).value('.', 'NVARCHAR(MAX)')), '')
+ ISNULL(((SELECT
CHAR(13) + 'CREATE' + CASE WHEN i.is_unique = 1 THEN ' UNIQUE' ELSE '' END
+ ' NONCLUSTERED INDEX [' + i.name + '] ON ' + @object_name + ' (' +
STUFF((
SELECT ', [' + c.name + ']' + CASE WHEN c.is_descending_key = 1 THEN ' DESC' ELSE ' ASC' END
FROM index_column c
WHERE c.is_included_column = 0
AND c.index_id = i.index_id
FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') + ')'
+ ISNULL(CHAR(13) + 'INCLUDE (' +
STUFF((
SELECT ', [' + c.name + ']'
FROM index_column c
WHERE c.is_included_column = 1
AND c.index_id = i.index_id
FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') + ')', '')  + case when i.filter_definition is not null then ' Where ' + i.filter_definition else '' end +
case when i.fill_factor between 1 and 100 then ' WITH (FILLFACTOR = ' + Cast(i.fill_factor as varchar(3)) + ') on [' + f.[name] + '];' else '' end + CHAR(13)
FROM sys.indexes i WITH (NOWAIT)
INNER JOIN [sys].[filegroups] f
    ON f.[data_space_id] = i.[data_space_id]
and i.[object_id] = @object_id
AND i.is_primary_key = 0
AND i.[type] = 2
FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)')
), '')

Set @Sql = @SQL +ISNULL((SELECT ISNULL(CHAR(13) +
'ALTER TABLE ' + @object_name + ' WITH'
+ CASE WHEN con.is_not_trusted = 1
THEN ' NOCHECK'
ELSE ' CHECK'
END +
' ADD CONSTRAINT [' + con.[name]  + '] CHECK ('
+ con.[definition] +')','')
+ CHAR(13) + 'ALTER TABLE ' + @object_name + case when con.is_disabled=1 then 'NOCHECK' else 'CHECK' end + ' CONSTRAINT [' + con.name  + ']' + CHAR(13)
from sys.check_constraints con
		where con.parent_object_id = @object_id
	   FOR XML PATH(N''), TYPE).value('.', 'NVARCHAR(MAX)'
	   ), '')
RETURN @SQL
END

GO

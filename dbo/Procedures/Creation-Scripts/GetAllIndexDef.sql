SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




 create   proc [dbo].[GetAllIndexDef]
 as
INSERT INTO [LW_Monitor].dbo.[AllIndexDef]
           ([table_name]
           ,[index_name]
           ,[index_description]
           ,[indexed_columns]
           ,[included_columns]
           ,[fill_factor]
           ,[filter_definition]
           ,[CreatedDate])
 SELECT '[' + s.NAME + '].[' + o.NAME + ']' AS 'table_name'
    ,+ i.NAME AS 'index_name'
    ,LOWER(i.type_desc) + CASE 
        WHEN i.is_unique = 1
            THEN ', unique'
        ELSE ''
        END + CASE 
        WHEN i.is_primary_key = 1
            THEN ', primary key'
        ELSE ''
        END AS 'index_description'
    ,STUFF((
            SELECT ', [' + sc.NAME + ']' AS "text()"
            FROM syscolumns AS sc
            INNER JOIN sys.index_columns AS ic ON ic.object_id = sc.id
                AND ic.column_id = sc.colid
            WHERE sc.id = so.object_id
                AND ic.index_id = i1.indid
                AND ic.is_included_column = 0
            ORDER BY key_ordinal
            FOR XML PATH('')
            ), 1, 2, '') AS 'indexed_columns'
    ,STUFF((
            SELECT ', [' + sc.NAME + ']' AS "text()"
            FROM syscolumns AS sc
            INNER JOIN sys.index_columns AS ic ON ic.object_id = sc.id
                AND ic.column_id = sc.colid
            WHERE sc.id = so.object_id
                AND ic.index_id = i1.indid
                AND ic.is_included_column = 1
            FOR XML PATH('')
            ), 1, 2, '') AS 'included_columns'
			,i.fill_factor
			,i.filter_definition
			,GETDATE()
FROM sysindexes AS i1
INNER JOIN sys.indexes AS i ON i.object_id = i1.id
    AND i.index_id = i1.indid
INNER JOIN sysobjects AS o ON o.id = i1.id
INNER JOIN sys.objects AS so ON so.object_id = o.id
    AND is_ms_shipped = 0
INNER JOIN sys.schemas AS s ON s.schema_id = so.schema_id
WHERE so.type = 'U'
    AND i1.indid < 255
    --AND i1.STATUS & 64 = 0 --index with duplicates
    --AND i1.STATUS & 8388608 = 0 --auto created index
    --AND i1.STATUS & 16777216 = 0 --stats no recompute
    AND i.is_disabled=0 and i.is_primary_key=0
    AND so.NAME <> 'sysdiagrams'
	--and so.name like '%users%'
ORDER BY table_name,index_name;

GO

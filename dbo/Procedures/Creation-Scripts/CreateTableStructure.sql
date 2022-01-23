SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--exec CreateTableStructure 'dbo.LeaseInsuranceRequirements',2,'dbo.xxLeaseInsuranceRequirements';
create proc [dbo].[CreateTableStructure]
(@table_name SYSNAME
,@TotalNodes int
,@NewTableName SYSNAME
)
as
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

DECLARE @ITYPE NVARCHAR(20);
SELECT @ITYPE = type_desc FROM SYS.INDEXES WHERE object_id = @object_id and is_primary_key = 1;

DECLARE @DefaultConstraintInfo TABLE
(
DfConstraintName NVARCHAR(200),
Parent_object_id INT,
Parent_column_id INT
)

INSERT INTO @DefaultConstraintInfo
SELECT name, parent_object_id,parent_column_id FROM sys.default_constraints WHERE parent_object_id = @object_id and type='D';

DECLARE @SQL NVARCHAR(MAX) = ''

SELECT @SQL = @SQL + 'EXEC sp_rename '''+DfConstraintName+''''+', '+'''ly'+DfConstraintName+''''+';'
from @DefaultConstraintInfo
EXEC sys.sp_executesql @SQL

SELECT @SQL = 'CREATE TABLE ' + @NewTableName + CHAR(13) + '(' + CHAR(13) + STUFF((
    SELECT CHAR(9) + ', [' + c.name + '] ' + 
        CASE WHEN c.is_computed = 1
            THEN 'AS ' + cc.[definition] 
            ELSE UPPER(tp.name) + 
                CASE WHEN tp.name IN ('varchar', 'char', 'varbinary', 'binary', 'text')
                       THEN '(' + CASE WHEN c.max_length = -1 THEN 'MAX' ELSE CAST(c.max_length AS VARCHAR(5)) END + ')'
                     WHEN tp.name IN ('nvarchar', 'nchar', 'ntext')
                       THEN '(' + CASE WHEN c.max_length = -1 THEN 'MAX' ELSE CAST(c.max_length / 2 AS VARCHAR(5)) END + ')'
                     WHEN tp.name IN ('datetime2', 'time2', 'datetimeoffset') 
                       THEN '(' + CAST(c.scale AS VARCHAR(5)) + ')'
                     WHEN tp.name = 'decimal' 
                       THEN '(' + CAST(c.[precision] AS VARCHAR(5)) + ',' + CAST(c.scale AS VARCHAR(5)) + ')'
                    ELSE ''
                END +
				CASE WHEN mc.is_masked = 1 THEN ' MASKED WITH (FUNCTION = ''' + mc.masking_function +''')' ELSE '' END+
                CASE WHEN mc.is_masked IS NULL AND c.collation_name IS NOT NULL THEN ' COLLATE ' + c.collation_name ELSE '' END +
                CASE WHEN c.is_nullable = 1 THEN ' NULL' ELSE ' NOT NULL' END +
                CASE WHEN dc.[definition] IS NOT NULL THEN ' CONSTRAINT ['+dci.DfConstraintName+'] DEFAULT' + dc.[definition] ELSE '' END + 
                CASE WHEN ic.is_identity = 1 THEN ' IDENTITY(' + CAST(ISNULL(ic.seed_value, '0') AS CHAR(1)) + ',' + CAST(@TotalNodes AS varchar(2)) + ')' ELSE '' END 
        END + CHAR(13)
    FROM sys.columns c WITH (NOWAIT)
    JOIN sys.types tp WITH (NOWAIT) ON c.user_type_id = tp.user_type_id
	LEFT JOIN sys.masked_columns mc WITH (NOWAIT) ON c.object_id = mc.object_id and c.name=mc.name 
    LEFT JOIN sys.computed_columns cc WITH (NOWAIT) ON c.[object_id] = cc.[object_id] AND c.column_id = cc.column_id
    LEFT JOIN sys.default_constraints dc WITH (NOWAIT) ON c.default_object_id != 0 AND c.[object_id] = dc.parent_object_id AND c.column_id = dc.parent_column_id
	LEFT JOIN @DefaultConstraintInfo dci ON c.default_object_id != 0 AND c.[object_id] = dci.parent_object_id AND c.column_id = dci.parent_column_id
    LEFT JOIN sys.identity_columns ic WITH (NOWAIT) ON c.is_identity = 1 AND c.[object_id] = ic.[object_id] AND c.column_id = ic.column_id
    WHERE c.[object_id] = @object_id
    ORDER BY c.column_id
    FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, CHAR(9) + ' ')
    + ISNULL((SELECT CHAR(9) + ', PRIMARY KEY '+@ITYPE+' (' + 
                    (SELECT STUFF((
                         SELECT ', [' + c.name + '] ' + CASE WHEN ic.is_descending_key = 1 THEN 'DESC' ELSE 'ASC' END
                         FROM sys.index_columns ic WITH (NOWAIT)
                         JOIN sys.columns c WITH (NOWAIT) ON c.[object_id] = ic.[object_id] AND c.column_id = ic.column_id
                         WHERE ic.is_included_column = 0
                             AND ic.[object_id] = k.parent_object_id 
                             AND ic.index_id = k.unique_index_id     
                         FOR XML PATH(N''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, ''))
			+ ')' + case when i.fill_factor between 1 and 100 then  ' WITH (FILLFACTOR = ' + Cast(i.fill_factor as varchar(3)) + ') on [' + f.[name] + ']' else '' end +CHAR(13)

            FROM sys.key_constraints k WITH (NOWAIT)
			INNER JOIN sys.indexes i 
			ON i.[object_id] = k.[parent_object_id] AND i.is_primary_key = 1
            INNER JOIN [sys].[filegroups] f
			ON f.[data_space_id] = i.[data_space_id]
			WHERE k.parent_object_id = @object_id 
                AND k.[type] = 'PK'), '') + ')'  + CHAR(13)
	+ ISNULL(' With (DATA_COMPRESSION=' + (isnull ((Select top 1 sp.data_compression_desc FROM sys.partitions SP INNER JOIN sys.tables ST ON st.object_id = sp.object_id
WHERE st.object_id= @object_id and sp.data_compression_desc ='PAGE'),'NONE')
) + ');','')  
--select @SQL
EXEC sys.sp_executesql @SQL

--Create clustered indexes not in primary key
declare @indexColumn nvarchar(max);
SELECT @indexColumn = b.name FROM sys.indexes i INNER JOIN sys.index_columns a ON i.object_id = a.object_id AND i.index_id = a.index_id
			   INNER JOIN sys.columns b ON a.object_id = b.object_id AND a.column_id = b.column_id INNER JOIN sys.tables c ON i.object_id = c.object_id
			   WHERE i.type_desc = 'clustered' AND i.type=1 AND i.is_primary_key = 0 AND c.name = Right(@table_name,Len(@table_name)-4)
if(@indexColumn is not null)
EXEC ChangeClusteredIndex @table_name=@NewTableName,@reqcolumn= @indexColumn

GO

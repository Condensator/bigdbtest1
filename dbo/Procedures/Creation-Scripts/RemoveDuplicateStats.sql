SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





/*
    Script to find auto-created statistics that are no longer needed due
    to an index existing with the first column the same as the column
    the statistic is on. Disabled indexes are ignored. Based on script from
    mattsql.wordpress.com/2013/08/28/duplicate-statistics/
 
	Disabled indexes are ignored.
    Filtered indexes are ignored.
 
    ShaunJStuart.com
 
    8-8-16  Initial release
 
*/
create   proc [dbo].[RemoveDuplicateStats]
as
set nocount on;
DECLARE @sql NVARCHAR(MAX);

IF OBJECT_ID('tempdb..##UnneededStats') IS NOT NULL
    DROP TABLE ##UnneededStats;
 
CREATE TABLE ##UnneededStats
    (
        [DropStatCommand] NVARCHAR(4000) NOT NULL
    );

SET @sql = 'WITH  stats_on_indexes ( [object_id], [table_column_id], [index_name] )
    AS ( SELECT   o.[object_id] AS [object_id] ,
                ic.[column_id] AS [table_column_id] ,
                i.name
        FROM     sys.indexes i
                JOIN sys.objects o ON i.[object_id] = o.[object_id]
                JOIN sys.stats st ON i.[object_id] = st.[object_id]
                                        AND i.name = st.name
                JOIN sys.index_columns ic ON i.index_id = ic.index_id
                                                AND i.[object_id] = ic.[object_id]
        WHERE    o.is_ms_shipped = 0
                AND i.has_filter = 0
                AND ic.key_ordinal = 1
                AND i.is_disabled = 0
        )
INSERT  INTO ##UnneededStats
    ( 
        [DropStatCommand]
    )
    SELECT  ''DROP STATISTICS ['' + sch.name
            + ''].['' + o.name + ''].['' + s.name + ''];'' AS DropStatCommand
    FROM    sys.stats s
            JOIN sys.stats_columns sc ON s.stats_id = sc.stats_id
                                            AND s.[object_id] = sc.[object_id]
            JOIN sys.objects o ON sc.[object_id] = o.[object_id]
            JOIN sys.schemas sch ON o.schema_id = sch.schema_id
            JOIN sys.columns c ON sc.[object_id] = c.[object_id]
                                    AND sc.column_id = c.column_id
            JOIN stats_on_indexes ON o.[object_id] = stats_on_indexes.[object_id]
                                        AND stats_on_indexes.table_column_id = c.column_id
    WHERE   s.auto_created = 1
            AND s.has_filter = 0;';
 
EXEC sp_executesql @sql;

set @sql =''
select  @sql =  @sql + '' +  DropStatCommand + '' from ##UnneededStats group by DropStatCommand
/*group by is needed because sometimes more than one index will start
    with the same column, resulting in two DROP statements being generated
    for the same statistic, which would cause an error when executed. */

if len(@sql)>1
begin
	EXEC sp_executesql @sql;
	print Cast(@@RowCount as varchar(20)) + ' duplicate stats removed'
end
DROP TABLE ##UnneededStats;

GO

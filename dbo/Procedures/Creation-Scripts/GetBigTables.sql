SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE   proc [dbo].[GetBigTables]
as
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
with pages as (
SELECT object_id, SUM (reserved_page_count) as reserved_pages, SUM (used_page_count) as used_pages,
SUM (case
when (index_id < 2) then (in_row_data_page_count + lob_used_page_count + row_overflow_used_page_count)
else lob_used_page_count + row_overflow_used_page_count
end) as pages
FROM sys.dm_db_partition_stats
group by object_id
), extra as (
SELECT p.object_id, sum(reserved_page_count) as reserved_pages, sum(used_page_count) as used_pages
FROM sys.dm_db_partition_stats p, sys.internal_tables it
WHERE it.internal_type IN (202,204,211,212,213,214,215,216) AND p.object_id = it.object_id
group by p.object_id
)
SELECT p.object_id,object_schema_name(p.object_id) + '.' + object_name(p.object_id) as TableName, (p.reserved_pages + isnull(e.reserved_pages, 0)) * 8 as reserved_kb,
pages * 8 as data_kb,
(CASE WHEN p.used_pages + isnull(e.used_pages, 0) > pages THEN (p.used_pages + isnull(e.used_pages, 0) - pages) ELSE 0 END) * 8 as index_kb,
(CASE WHEN p.reserved_pages + isnull(e.reserved_pages, 0) > p.used_pages + isnull(e.used_pages, 0) THEN (p.reserved_pages + isnull(e.reserved_pages, 0) - p.used_pages + isnull(e.used_pages, 0)) else 0 end) * 8 as unused_kb
into #table
from pages p
left outer join extra e on p.object_id = e.object_id;

select sum(p.rows) as RowsCount,t.object_id into #t from #table t
INNER JOIN   sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE  i.OBJECT_ID > 255 AND  i.index_id <= 1
GROUP BY t.object_id,i.object_id, i.index_id

select top 50 TableName,RowsCount,data_kb/1024 as Data_MB,index_kb/1024 as Index_MB,unused_kb/1024 as unused_MB,reserved_kb/1024 as Reserved_MB
from #table join #t on #table.object_id=#t.object_id where reserved_kb>10000 order by Reserved_MB Desc

GO

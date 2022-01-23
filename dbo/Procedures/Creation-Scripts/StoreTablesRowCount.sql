SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[StoreTablesRowCount]
(@PostMigration bit=0)
as
if (@PostMigration=0)
truncate table Mig_TablesRowCounts;
insert into Mig_TablesRowCounts(TableName,RowsCount,PostMigration,CreatedById,CreatedTime)
select t.name,sum(p.rows) as RowsCount,@PostMigration,1,SYSDATETIMEOFFSET()
from sys.tables t
INNER JOIN  sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN
sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN
sys.allocation_units a ON p.partition_id = a.container_id
WHERE  i.OBJECT_ID > 255 AND  i.index_id <= 1 and t.is_ms_shipped=0 and t.type='U'
GROUP BY t.name,i.object_id, i.index_id

GO

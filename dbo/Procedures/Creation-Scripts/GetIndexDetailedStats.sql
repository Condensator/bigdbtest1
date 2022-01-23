SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE   proc [dbo].[GetIndexDetailedStats]
as
Insert into LW_Monitor.dbo.IndexDetailedStats
(TableName, IndexName, user_seeks,user_scans, user_lookups, user_updates, RecordCount, CreatedTime)
SELECT 
o.name as TableName
, indexname=i.name
, user_seeks 
,user_scans 
, user_lookups   
, user_updates   
, rows = (SELECT SUM(p.rows) FROM sys.partitions p WHERE p.index_id = s.index_id AND s.object_id = p.object_id)
,GETDATE()
FROM sys.dm_db_index_usage_stats s  
INNER JOIN sys.indexes i ON i.index_id = s.index_id AND s.object_id = i.object_id   
INNER JOIN sys.objects o on s.object_id = o.object_id
and s.database_id=db_id()
WHERE OBJECTPROPERTY(s.object_id,'IsUserTable') = 1

GO

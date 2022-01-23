SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




create   proc [dbo].[GetFragmentedIndexes]
(@pageCountFilter int=5000)
as
declare @DBId int=DB_ID();

INSERT INTO LW_Monitor.dbo.FragmentedIndexes
           ([ObjectName]
           ,[IndexName]
           ,[ObjectType]
           ,[IndexType]
           ,[PageCount]
           ,[RecordCount]
           ,[AvgFragmentationInPercent]
           ,[CreatedTime])
SELECT top 50
       ob.[name] AS ObjectName,
       ix.[name] AS IndexName,
       ob.type_desc AS ObjectType,
       ix.type_desc AS IndexType,
       -- ips.partition_number AS PartitionNumber,
       ips.page_count AS [PageCount], -- Only Available in DETAILED Mode
       ips.record_count AS [RecordCount],
       ips.avg_fragmentation_in_percent AS AvgFragmentationInPercent,
	   GetDate() as CreatedTime
/* FROM sys.dm_db_index_physical_stats (@DBId, NULL, NULL, NULL, 'DETAILED') ips --SLOW */
FROM sys.dm_db_index_physical_stats (@DBId, NULL, NULL, NULL, 'SAMPLED') ips
INNER JOIN sys.indexes ix ON ips.[object_id] = ix.[object_id] 
                AND ips.index_id = ix.index_id
INNER JOIN sys.objects ob ON ix.[object_id] = ob.[object_id]
WHERE ob.[type] IN('U','V')
AND ob.is_ms_shipped = 0
AND ix.[type] IN(1,2,3,4)
AND ix.is_disabled = 0
AND ix.is_hypothetical = 0
AND ips.alloc_unit_type_desc = 'IN_ROW_DATA'
AND ips.index_level = 0
AND ips.page_count > @pageCountFilter -- Filter to check only table with over X pages
 AND ips.avg_fragmentation_in_percent >= 45
ORDER BY ips.page_count desc

GO

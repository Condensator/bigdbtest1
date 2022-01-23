SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




Create   proc [dbo].[GetFrequentQueriesFromStore]
as
INSERT INTO [LW_Monitor].dbo.[FrequentQueries]
           ([query_sql_text]
           ,[parent_object]
           ,[total_executions]
           ,[avg_duration]
           ,[avg_cpu_time]
           ,[avg_logical_io_reads]
           ,[avg_physical_io_reads]
           ,[CreatedDate])
SELECT TOP 100 t.query_sql_text, object_name(q.object_id) AS parent_object, 
	SUM(s.count_executions) as total_executions,s.avg_duration
	,s.avg_cpu_time,s.avg_logical_io_reads,s.avg_physical_io_reads
	,getdate() as CreatedDate
 FROM sys.query_store_query_text t JOIN sys.query_store_query q
   ON t.query_text_id = q.query_text_id 
   JOIN sys.query_store_plan p ON q.query_id = p.query_id 
   JOIN sys.query_store_runtime_stats s ON p.plan_id = s.plan_id
GROUP BY  t.query_sql_text, object_name(q.object_id),s.avg_duration
	,s.avg_cpu_time,s.avg_logical_io_reads,s.avg_physical_io_reads
ORDER BY SUM(s.count_executions) DESC

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




create   proc [dbo].[GetCompiledTimeoutQueries]
as
WITH XMLNAMESPACES('http://schemas.microsoft.com/sqlserver/2004/07/showplan' AS p)
SELECT  CASE
              WHEN qs.statement_end_offset > 0
                     THEN substring(st.text, qs.statement_start_offset/2 + 1,
                                                       (qs.statement_end_offset-qs.statement_start_offset)/2)
              ELSE 'SQL Statement'
       END as timeout_statement,
       st.text AS BatchStatement,
	   db_name(qp.dbid) as DBName,
       qp.query_plan,
	   qs.plan_handle,
	   GetDate() as CheckDate
	   into #t
FROM    (
       SELECT  TOP 200 *
       FROM sys.dm_exec_query_stats
       ORDER BY total_worker_time DESC
) AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp
WHERE qp.query_plan.exist('//p:StmtSimple/@StatementOptmEarlyAbortReason[.="TimeOut"]') = 1

insert into LW_Monitor.dbo.CompiledTimeout
           ([timeout_statement]
           ,[BatchStatement]
           ,[DBName]
           ,[query_plan]
           ,[plan_handle]
           ,[CheckDate])
select [timeout_statement]
           ,[BatchStatement]
           ,[DBName]
           ,[query_plan]
           ,[plan_handle]
           ,[CheckDate] from #t

GO

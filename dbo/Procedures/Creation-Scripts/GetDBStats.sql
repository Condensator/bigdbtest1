SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/* To capture Odessa DB & DB Server Perf health monitoring stats in LW_Monitor DB */
Create   proc [dbo].[GetDBStats]
(@ClearHistory tinyint=0
,@CaptureServerDetails tinyint=1
,@CaptureUsageDetails tinyint=0
,@LastXMonths tinyint=2
)
As
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
declare @sql nvarchar(max)

if @ClearHistory=1
Begin
	exec [LW_Monitor].dbo.ClearTables
End

declare @restartDate datetime
declare @DBName sysname=db_name();

SELECT @restartDate=sqlserver_start_time FROM sys.dm_os_sys_info
Insert into [LW_Monitor].dbo.RunInfo(SourceDBName,CreatedDate,SqlRestartDate) values (DB_Name(),GetDate(),@restartDate);

if @CaptureServerDetails=1
begin

	INSERT INTO [LW_Monitor].dbo.[WaitStats]
           ([WaitType]
           ,[Wait_Sec]
           ,[WaitCount]
           ,[Percentage]
           ,[AvgWait_Sec]
           ,[CheckDate])
    exec master.dbo.GetDbPerformance 'Waits'

	exec sp_BlitzCache @databaseName=@DBName, @Top = 30,@SortOrder='Duration',@OutputDatabaseName='LW_Monitor',@OutputSchemaName='dbo',@OutputTableName='BlitzCacheResult';

	exec sp_blitz @IgnorePrioritiesAbove=99,@CheckServerInfo=1, @OutputDatabaseName='LW_Monitor', @OutputSchemaName='dbo', @OutputTableName='BlitzResult';

	declare @cloneDBName sysname;
	declare @Counter int=1

	while @Counter<3
	begin
		set @cloneDBName=@DBName+ '_Stats' + cast(@Counter as char(1))
		if not exists (select * from sys.databases where name=@cloneDBName)
			set @Counter=3 --exit the loop
		else
			set @Counter=@Counter+1
	end

	INSERT INTO [LW_Monitor].[dbo].[SQLConfiguration]
           ([Setting]
           ,[CurrentValue]
           ,[CheckDate])
   exec master.dbo.GetDbPerformance 'Settings'

End

exec dbo.RemoveDuplicateStats;

Insert into [LW_Monitor].dbo.IndexUsages(Name,Idx_Name,Idx_Id,Reads,Writes,[Rows],Reads_Per_Write) exec GetIndexUsage;

Insert into [LW_Monitor].dbo.MissingIndices(Impact,[Table],CreateIndexStatement,Eqality_Columns,Ineqality_Columns,Included_Columns) exec FindMissingIndexes;

Insert into [LW_Monitor].dbo.MassiveTables(TableName,RowsCount,Data_MB,Index_MB,Unused_MB,Reserved_MB) exec GetBigTables;

Insert into [LW_Monitor].dbo.TableInfo(TableName,Reason,CreatedDate) SELECT SCH.name + '.' + TBL.name AS TableName,'Heap' as Reason, GetDate()
FROM sys.tables AS TBL  INNER JOIN sys.schemas AS SCH   ON TBL.schema_id = SCH.schema_id INNER JOIN sys.indexes AS IDX  ON TBL.object_id = IDX.object_id AND IDX.type = 0 ORDER BY TableName;

Insert into [LW_Monitor].dbo.TableInfo(TableName,Reason,CreatedDate)
SELECT t.name AS table_name,'No FK' as Reason, GetDate()
FROM sys.tables t
WHERE object_id NOT IN
(
SELECT Parent_object_id
FROM sys.foreign_keys where is_disabled=0
union all
SELECT referenced_object_id
FROM sys.foreign_keys where is_disabled=0
)
and t.Name not like '%config%'
and t.name not like 'CDC%'
and t.is_ms_shipped=0;

INSERT INTO LW_Monitor.dbo.[ExpensiveSPs]
           ([DBName]
           ,[SP Name]
           ,[execution_count]
           ,[AvgElapsedTimeSec]
           ,[LastElapsedTimeSec]
           ,[MaxElapsedTimeSec]
           ,[Avg_logical_reads]
           ,[Avg_physical_reads]
		   )
		   exec master.dbo.GetDbPerformance 'SP' 

		   INSERT INTO [LW_Monitor].[dbo].[ExpensiveQueries]
           ([Querytxt]
           ,[DBName]
           ,[execution_count]
           ,[last_elapsed_time_in_S]
           ,[avg_elapsed_time_in_S]
           ,[avg_logical_reads]
           ,[query_plan]
           )
		   exec master.dbo.GetDbPerformance 'Query' 

		   INSERT INTO LW_Monitor.[dbo].[FreqQueriesFromStartup]
           ([text]
           ,[execution_count]
           ,[total_elapsed_time]
           ,[DBName]
           ,[last_execution_time]
		   )
			SELECT top 100 st.[text], qs.execution_count, qs.total_elapsed_time
			,DB_NAME(st.dbid) as DBName, qs.last_execution_time
			FROM sys.dm_exec_query_stats AS qs
			CROSS APPLY sys.dm_exec_sql_text( qs.sql_handle ) AS st
			where st.dbid=DB_ID()
			ORDER BY qs.execution_count DESC;

exec dbo.GetIndexDetailedStats;
exec dbo.GetFrequentQueriesFromStore;
exec dbo.GetAllIndexDef;
exec dbo.GetCompiledTimeoutQueries;

/* Clone DB for stats */
if exists(select * from sys.databases d where d.database_id=DB_ID() and d.database_id>4 and is_read_only=0) 
begin
	declare @Updatable nvarchar(100)
    select @Updatable=Cast(DATABASEPROPERTYEX(@DBName, 'Updateability') as nvarchar(100))
	if @Updatable!='READ_ONLY'
	begin
		declare @readonly bit=0
		select @readonly=is_read_only from sys.databases where name=@cloneDBName
		if @readonly=1
		begin
			set @sql ='ALTER DATABASE [' + @cloneDBName + '] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;'
			EXEC SP_ExecuteSQL @sql
			set @sql ='Drop database [' + @cloneDBName + '];' 
			EXEC SP_ExecuteSQL @sql
		end
		BEGIN TRY 
			DBCC CLONEDATABASE (@DBName, @cloneDBName);
		END TRY
		BEGIN CATCH
			Print 'Following error occurred during cloning DB: '
			Print ERROR_MESSAGE()
		END CATCH
	end
end

if @CaptureUsageDetails=1
BEGIN
	exec dbo.GetFragmentedIndexes;
	
	declare @XMonths int=@LastXMonths*-1
	exec dbo.GetUnUsedJobs;
	exec dbo.GetUnUsedTables;

	exec dbo.GetDuplicateRecords;

	Insert into LW_Monitor.dbo.TraceUsage (EventType,Form,[Transaction],Total,CreatedDate)
	select EventType,Form,[Transaction], COUNT(*) As Total, GETDATE() as CreatedDate from TraceEventLogs where CreatedTime>Dateadd(m,@XMonths,getdate()) group by EventType,Form,[Transaction];

	declare @cols varchar(max)

	set @sql='Use LW_monitor; if exists(select * from sys.tables where name=''JobConfigDetails'') drop table JobConfigDetails;'
	EXEC SP_ExecuteSQL @sql
	declare @n char(1) = char(10)
	select @cols=isnull( @cols + @n, '' ) + OBJECT_NAME(c.object_id) + '.' + name + ' as ' + OBJECT_NAME(c.object_id) + '_'+ Name + ',' from sys.all_columns c where OBJECT_NAME(c.object_id) in ('Jobs','JobSteps','JobSchedules','JobTaskConfigs','JobServices') and name<>'RowVersion'
	set @cols=@cols + 'GetDate() as Health_RunDate'

	set @sql='select ' + @cols + ' into LW_Monitor.dbo.JobConfigDetails from Jobs join JobSteps on JobSteps.JobId=Jobs.Id join JobSchedules on JobSchedules.Id = Jobs.Id join JobTaskConfigs on JobTaskConfigs.id=JobSteps.TaskId left join JobServices on Jobs.JobServiceId=JobServices.Id where Jobs.IsActive=1 and Jobs.ScheduleType=''Recurring'' and JobSteps.IsActive=1'
	EXEC SP_ExecuteSQL @sql

	set @sql='Use LW_monitor; if exists(select * from sys.tables where name=''JobRunDetails'') drop table JobRunDetails;'
	EXEC SP_ExecuteSQL @sql

	select * into LW_Monitor.dbo.JobRunDetails from (select Jobs.Name,JobStepInstances.JobStepId,JobSteps.ExecutionOrder,JobTaskConfigs.UserFriendlyName as Task,JobStepInstances.StartDate,JobStepInstances.EndDate,JobStepInstances.Status, DateDiff(MINUTE,JobStepInstances.StartDate,ISNULL(JobStepInstances.EndDate,JobStepInstances.StartDate)) as DurationInMins, JobStepInstances.JobInstanceId,GetDate() as Health_RunDate from Jobs join JobSteps on JobSteps.JobId=Jobs.Id
	join JobStepInstances on JobStepInstances.JobStepId=JobSteps.Id join JobTaskConfigs on JobSteps.TaskId = JobTaskConfigs.Id
	where
	Jobs.IsActive=1 and  Jobs.ScheduleType='Recurring' and JobSteps.IsActive=1 and
	JobStepInstances.CreatedTime>DATEADD(M,@XMonths,getdate()))T
	where T.DurationInMins > 20;

	Delete from LW_Monitor.dbo.BookedContracts where CreatedDate>DATEADD(M,@XMonths,getdate());
	INSERT into LW_Monitor.dbo.BookedContracts(NewContracts,CreatedDate,ContractType)
	select COUNT(*) as NewContracts,Cast(CreatedTime as date) as CreatedDate,ContractType from Contracts
	where CreatedTime>DATEADD(M,@XMonths,getdate())
	group by ContractType,Cast(CreatedTime as date);

	Delete from LW_Monitor.dbo.TransactionDetails where CreatedDate>DATEADD(M,@XMonths,getdate());
	INSERT INTO LW_Monitor.[dbo].[TransactionDetails]
	([TransactionCount]
	,[CreatedDate]
	,[EntityName]
	,[TransactionName])
	select COUNT(*) as TransactionCount,Cast(CreatedTime as date) as CreatedDate,EntityName,TransactionName  from TransactionInstances
	where CreatedTime>DATEADD(M,@XMonths,getdate())
	group by EntityName,TransactionName, Cast(CreatedTime as date);
end

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE   PROCEDURE [dbo].[GetMigrationDashboardData]
(
	@isMasterCall bit=0
)
AS

select 
	stgProcessingLogDetail.ProcessingLogId
	,max(case stgProcessingLogDetail.Type when 'Error' then 1 else 0 end) IsFailed
into #ProcessingLogDetail
from stgProcessingLogDetail 
group by stgProcessingLogDetail.ProcessingLogId


select stgModuleIterationStatus.Id ModuleIterationStatusId
	,Sum(case #ProcessingLogDetail.IsFailed when 1 then 1 else 0 end) Failed
	,Sum(case #ProcessingLogDetail.IsFailed when 1 then 0 else 1 end) Passed
	,Count(isnull(#ProcessingLogDetail.ProcessingLogId,0)) as Processed
	,datediff(SS,max(stgModuleIterationStatus.StartTime),max(stgModuleIterationStatus.EndTime)) as MinutesPerModuleIteration
into #ModuleIterationEntityCount
from stgModuleIterationStatus 
left join stgProcessingLog on stgProcessingLog.ModuleIterationStatusId=stgModuleIterationStatus.Id   
left join #ProcessingLogDetail on #ProcessingLogDetail.ProcessingLogId=stgProcessingLog.Id
group by  stgModuleIterationStatus.Id

insert into #Results
select 
DB_name() as DBName
,case when stgModule.usesqlscript=1 then 'SQL Script' else 'Transaction Script' end ModuleApproach
,stgModule.Name ModuleName
,StgModule.ProcessingOrder
,Min(stgModuleIterationStatus.StartTime) MinStartTime	
,max(isnull(stgModuleIterationStatus.EndTime,SYSDATETIMEOFFSET())) MaxEndTime
,isnull(sum(#ModuleIterationEntityCount.Processed),1) Processed
,Isnull(sum(#ModuleIterationEntityCount.Passed),case when max(stgModuleIterationStatus.Status)='Completed' then 1 else 0 end) Passed
,isnull(sum(#ModuleIterationEntityCount.Failed),case when max(stgModuleIterationStatus.Status)!='Completed' then 1 else 0 end) Failed
,count(*) 'Number of Run'
,convert(nvarchar(10), sum(#ModuleIterationEntityCount.MinutesPerModuleIteration) /(24*60*60))+ ':' +cast(cast(convert(varchar,dateadd(second, sum(#ModuleIterationEntityCount.MinutesPerModuleIteration), 0),108) as time(0))as nvarchar(10))
,cast((sum(#ModuleIterationEntityCount.Passed)/cast(sum(#ModuleIterationEntityCount.Processed) as decimal(18,4))*100) as decimal(18,2))'Migrated %'
from stgModuleIterationStatus
	left join #ModuleIterationEntityCount on stgModuleIterationStatus.Id=#ModuleIterationEntityCount.ModuleIterationStatusId
	join stgModule on stgModuleIterationStatus.ModuleId=stgModule.Id
	where stgModule.IsActive=1
group by stgModule.usesqlscript
		,stgModule.Name
	,stgModule.ProcessingOrder

if(@isMasterCall=1)
begin
insert into #Results
select 
	DB_name() as DBName
	,case when stgModule.usesqlscript=1 then 'SQL Script' else 'Transaction Script' end ModuleApproach
	,stgModule.Name ModuleName	
	,StgModule.ProcessingOrder
	,null MinStartTime	
	,null MaxEndTime
	,0 Processed
	,0 Passed
	,0 Failed
	,0 'Number of Run'
	,null ActualExecutionTime
	,0.00 'Migrated %'
from stgModule 
left join stgModuleIterationStatus on stgModule.Id=stgModuleIterationStatus.ModuleId
where stgModule.IsActive=1 and stgModuleIterationStatus.StartTime is null
end

GO

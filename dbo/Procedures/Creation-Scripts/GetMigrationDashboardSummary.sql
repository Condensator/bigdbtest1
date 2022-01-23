SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE [dbo].[GetMigrationDashboardSummary]
(
@CloneCount tinyint = 1,
@UserId bigint ,  
@ModuleIterationStatusId bigint,  
@CreatedTime datetimeoffset = NULL
)
AS 

create table #Results(
			DBName sysname,
			ModuleApproach nvarchar(30),
			ModuleName nvarchar(100),
			ProcessingOrder decimal(10,2),
			MinStartTime datetime,
			MaxEndTime datetime,
			Processed Bigint,
			Passed bigint,
			Failed bigint,
			NumberOfRun bigint,
			[ActualExecutionTime] nvarchar(100),
			[MigratedPercent] Decimal(10,2)
			)


declare @DatabaseName SYSNAME = DB_Name()

DECLARE @IsMasterDB bit = 1
DECLARE @MasterDBName sysname = @DatabaseName
SELECT @IsMasterDB = 0 From StgModule Where ToolIdentifier IS NOT NULL AND ToolIdentifier != @CloneCount
if(@IsMasterDB=0)
Select  @MasterDBName = LEFT(@DatabaseName,len(@DatabaseName)-(Select Top 1 LEN(ToolIdentifier) From StgModule))

create table #DBNames ( DatabaseName SYSNAME,IsMasterDB bit)
insert into #DBNames values(@MasterDBName,1)
DECLARE @SQLCommand NVARCHAR(MAX);
declare @Iterator tinyint = 1
 
 SET @SQLCommand = 'exec '+@MasterDBName+'..GetMigrationDashboardData 1'
EXEC(@SQLCommand)
Declare @processinglogid bigint,@isFirstFailure bit=1;
while (@Iterator< @CloneCount and @CloneCount>1)
begin
	Declare @CurrentDatabaseName sysname = @MasterDBName +cast(@Iterator as nvarchar(20))
	If DB_ID(@CurrentDatabaseName) is not null
	begin
		SET @SQLCommand = 'exec '+@CurrentDatabaseName+'..GetMigrationDashboardData'
		EXEC(@SQLCommand)
		insert into #DBNames values(@CurrentDatabaseName,0)
	end
	else
	begin
		if(@isFirstFailure = 1)
		begin
			INSERT INTO stgProcessingLog (StagingRootEntityId,CreatedById,CreatedTime,ModuleIterationStatusId) values (0,@UserId,@CreatedTime,@ModuleIterationStatusId);
			set @processinglogid=Scope_identity();
			set @isFirstFailure= 0;
		end
		INSERT INTO stgProcessingLogDetail (Message ,Type ,EntityName ,CreatedById ,CreatedTime ,ProcessingLogId)  
			values ('The DB '+@CurrentDatabaseName+' could not be found as Clone Operation might not have run.','Information','MigrationDashboard',@UserId,@CreatedTime,@processinglogid);
	end	
	set @Iterator=@Iterator+1
end
select * from #Results order by ProcessingOrder,ModuleName,DBName

GO

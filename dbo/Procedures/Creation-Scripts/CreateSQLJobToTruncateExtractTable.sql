SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE   PROCEDURE [dbo].[CreateSQLJobToTruncateExtractTable]    
@DatabaseName SYSNAME,    
@LoginName SYSNAME,    
@ServerName SYSNAME = '(local)'    
AS    
BEGIN    
EXEC ('USE [msdb]');    
/****** Object:  Job [TruncateExtractTable]  ******/    
BEGIN TRANSACTION    
DECLARE @ReturnCode INT    
SELECT @ReturnCode = 0    
/****** Object:  JobCategory [[Uncategorized (Local)]]  ******/    
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)    
BEGIN    
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'    
IF (@@ERROR <> 0 OR @ReturnCode <> 0)    
GOTO QuitWithRollback    
END    
DECLARE @jobId BINARY(16)    
DECLARE @job_name sysname = 'ClearExtractTables_' + @DatabaseName    
SELECT @jobId = job_id  FROM msdb.dbo.sysjobs WHERE (NAME = @job_name)    
IF (@jobId IS NOT NULL)    
BEGIN    
EXEC msdb.dbo.sp_delete_job  @job_name = @job_name    
END    
SET @jobId = NULL    
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name = @job_name,    
@enabled=1,    
@notify_level_eventlog=0,    
@notify_level_email=0,    
@notify_level_netsend=0,    
@notify_level_page=0,    
@delete_level=0,    
@description=N'No description available.',    
@category_name=N'[Uncategorized (Local)]',    
@owner_login_name= @LoginName, @job_id = @jobId OUTPUT    
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback  
/****** Object:  Step [PurgeTempData]    Script Date: 3/31/2020 11:10:43 AM ******/  
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'PurgeTempData',   
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC PurgeTempData', 
		@database_name=@DatabaseName, 
		@flags=0 
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback    
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1    
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback    
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'SundayLunchTime',    
@enabled=1,    
@freq_type=8,    
@freq_interval=1,    
@freq_subday_type=1,    
@freq_subday_interval=0,    
@freq_relative_interval=0,    
@freq_recurrence_factor=1,    
@active_start_date=20190506,    
@active_end_date=99991231,    
@active_start_time=130000,    
@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback    
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = @ServerName    
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback    
COMMIT TRANSACTION    
GOTO EndSave    
QuitWithRollback:    
IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION    
EndSave:    
END

GO

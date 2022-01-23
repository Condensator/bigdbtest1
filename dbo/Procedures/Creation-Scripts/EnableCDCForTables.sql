SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create procedure [dbo].[EnableCDCForTables]
(
@enable bit
,@rolename sysname='cdc_admin'
)
as
DECLARE @TableName sysname;
declare @sql nvarchar(max)

DECLARE tableCursor CURSOR FAST_FORWARD FOR
SELECT name FROM sys.tables t where t.Is_ms_shipped=0 and t.is_tracked_by_cdc<>@enable 
and (@enable=0 or name in (select TableName from dbo.AuditEntityConfigs c where c.IsActive=1 and c.IsEnabled=1))
order by Name

OPEN tableCursor
FETCH NEXT FROM tableCursor INTO @TableName

WHILE @@FETCH_STATUS = 0
BEGIN
	if @enable = 1
		EXEC sys.sp_cdc_enable_table @source_schema ='dbo',@source_name=@TableName
			  , @role_name = @rolename
			  , @supports_net_changes=0
	else
		EXEC sys.sp_cdc_disable_table @source_schema = 'dbo',@source_name = @TableName,  @capture_instance ='all'
 FETCH NEXT FROM tableCursor INTO @TableName
END
CLOSE tableCursor
DEALLOCATE tableCursor

--disable jobs
if @enable=1 and exists(select * from [msdb].sys.tables where name like '%cdc_jobs%')
begin
	declare @Jobid uniqueidentifier;
	declare cur cursor for SELECT [job_id] FROM [msdb].[dbo].[cdc_jobs]  where database_id=DB_ID();
	open cur
	fetch next from cur into @Jobid
	while @@fetch_status=0
	begin
		IF (exists(select job_id FROM msdb.dbo.sysjobs WHERE job_id = @Jobid))
		BEGIN
			EXEC msdb.dbo.sp_delete_job @job_id=@Jobid;
		END
		fetch next from cur into @Jobid
	end
	close cur
	deallocate cur
end

GO

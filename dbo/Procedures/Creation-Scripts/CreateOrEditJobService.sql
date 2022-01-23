SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[CreateOrEditJobService]
(
	@HostName nvarchar(250),
	@ServiceName nvarchar(250),
	@PhysicalPath nvarchar(500),
	@UserId bigint,
	@CurrentTime datetimeoffset,
	@HostingEnvironment nvarchar(50),
	@JobServiceId BIGINT OUT
)
AS

SET NOCOUNT ON;

select @JobServiceId=Id from JobServices where HostName = @HostName and ServiceName = @ServiceName and HostingEnvironment = @HostingEnvironment

begin tran

if (@JobServiceId > 0)
	begin
		update JobServices set  			
			RecentActiveTime = @CurrentTime, 
			IsRunning = 1, 
			UpdatedTime = @CurrentTime, 
			UpdatedById = @UserId,
			PhysicalPath = @PhysicalPath,
			HostingEnvironment = @HostingEnvironment
		where Id = @JobServiceId
	end
else
	begin
		insert into jobservices(HostName, ServiceName, IsRunning, PhysicalPath, CreatedById, CreatedTime, RecentActiveTime, HostingEnvironment)
		values(@HostName, @ServiceName, 1, @PhysicalPath, @UserId, @CurrentTime, @CurrentTime, @HostingEnvironment) 
		select @JobServiceId=scope_identity()
	end


INSERT INTO JobServiceDetails (JobServiceId,StartTime,CreatedById,CreatedTime)
VALUES (@JobServiceId,@CurrentTime,@UserId,@CurrentTime)

commit

GO

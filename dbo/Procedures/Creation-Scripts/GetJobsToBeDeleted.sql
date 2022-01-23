SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




Create   PROCEDURE [dbo].[GetJobsToBeDeleted]
(
	@ApprovalStatus NVARCHAR(50),
	@DeletedStatus NVARCHAR(50),
	@JobServiceId BIGINT,
	@UserId BIGINT,
	@CurrentTime DATETIMEOFFSET
)
AS
CREATE TABLE #InactiveJobIds
(
	Id BIGINT NOT NULL
);

UPDATE Jobs SET ScheduledStatus = @DeletedStatus 
,UpdatedById = @UserId
,UpdatedTime = @CurrentTime
output deleted.Id INTO #InactiveJobIds
Where Id in (select J.Id from Jobs j WHERE j.IsActive = 0 AND j.JobServiceId = @JobServiceId AND j.ApprovalStatus = @ApprovalStatus AND j.ScheduledStatus != @DeletedStatus
AND EXISTS (SELECT 1 FROM JobSchedulerKeys jsk WHERE jsk.JobId=j.Id AND jsk.IsActive=1))

SELECT Id FROM #InactiveJobIds

GO

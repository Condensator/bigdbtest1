SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE   PROCEDURE [dbo].[GetJobsToBeScheduled]
(
	 @JobServiceId BIGINT
	,@QuartzThreadCount BIGINT
	,@SubmittedScheduledStatus NVARCHAR(50)
	,@ScheduledInvocationReason NVARCHAR(50)=null
	,@RunAgainInvocationReason NVARCHAR(50)=null
	,@ResumedInvocationReason NVARCHAR(50)=null
	,@UpdatedById BIGINT
	,@UpdatedTime DATETIMEOFFSET
)
AS
	 UPDATE TOP(@QuartzThreadCount) J
	 SET
	 JobServiceId = @JobServiceId
	,ScheduledStatus = @SubmittedScheduledStatus
	,UpdatedById = @UpdatedById
	,UpdatedTime = @UpdatedTime
	 OUTPUT
	 DELETED.Id AS [JobId],
	 DELETED.ScheduledStatus as PreviousScheduledStatus
	 FROM dbo.Jobs J
	 LEFT JOIN dbo.JobServices JS ON J.JobServiceId = JS.Id
	 WHERE J.IsActive = 1
		AND J.ApprovalStatus = 'Approved'  
		AND J.ScheduledStatus IN ('NotSubmitted' , 'Changed' ,'RunAgain' ,'Resumed') 
		AND (J.JobServiceId IS NULL OR J.JobServiceId = @JobServiceId OR JS.IsRunning = 0)

GO

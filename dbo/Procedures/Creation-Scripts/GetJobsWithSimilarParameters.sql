SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetJobsWithSimilarParameters](
	 @JobId BIGINT
    ,@ScheduleType NVARCHAR(200)
	,@NotSubmittedScheduledStatus NVARCHAR(200)
	,@ResumedScheduledStatus NVARCHAR(200)
	,@RunAgainScheduledStatus NVARCHAR(200)
    ,@ExpiryDate DATETIMEOFFSET
    ,@CronExpression NVARCHAR(200)
    ,@TaskConfigIdsCsv NVARCHAR(MAX)
)
AS
BEGIN

	CREATE TABLE #JobTaskConfigIds
	(
		JobTaskConfigId BIGINT
	);

	INSERT INTO #JobTaskConfigIds 
	SELECT Id 
	FROM ConvertCSVToBigIntTable(@TaskConfigIdsCsv,',');

	CREATE TABLE #MatchingJobIdsByStepsCount
	(
		JobId BIGINT
	);
	 
	INSERT INTO #MatchingJobIdsByStepsCount
	SELECT DISTINCT
		 J.Id AS JobId
	FROM Jobs J
	JOIN JobSteps JS ON JS.JobId = J.Id	AND JS.IsActive = 1
	JOIN #JobTaskConfigIds #JTC ON JS.TaskId = #JTC.JobTaskConfigId
	WHERE   J.Id != @JobId
		AND J.IsActive = 1
		AND J.ScheduleType = @ScheduleType
		AND J.ScheduledStatus IN (@NotSubmittedScheduledStatus, @ResumedScheduledStatus, @RunAgainScheduledStatus)
		AND COALESCE(J.CronExpression,'') = COALESCE(@CronExpression,'')
		AND COALESCE(J.ExpiryDate,'') = COALESCE(@ExpiryDate,'')

	SELECT 
	 J.Id AS JobId
	,J.ScheduleType AS ScheduleType
	,J.ScheduledStatus AS ScheduledStatus
	,J.ExpiryDate AS ExpiryDate
	,JS.Id AS JobStepId
	,JS.TaskId AS JobTaskConfigId
	,JS.TaskParam AS TaskParam
	FROM Jobs J
	JOIN #MatchingJobIdsByStepsCount #MJ on J.Id = #MJ.JobId
	JOIN JobSteps JS ON JS.JobId = J.Id AND JS.IsActive = 1

	DROP TABLE #JobTaskConfigIds
	DROP TABLE #MatchingJobIdsByStepsCount
END

GO

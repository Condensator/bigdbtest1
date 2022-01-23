SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetRunningJobsWithSimilarParameters](
	 @JobId BIGINT
    ,@TaskConfigIdsCsv NVARCHAR(MAX)
	,@RunningStatus NVARCHAR(200)
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

	CREATE TABLE #MatchingRunningJobIdsByStepsCount
	(
		JobId BIGINT
	);	 

	INSERT INTO #MatchingRunningJobIdsByStepsCount
	SELECT DISTINCT
		 J.Id AS JobId
	FROM JobInstances JI 
	JOIN Jobs J ON JI.JobId = J.Id AND J.IsActive = 1
	JOIN JobSteps JS ON JS.JobId = J.Id	AND JS.IsActive = 1
	JOIN #JobTaskConfigIds #JTC ON JS.TaskId = #JTC.JobTaskConfigId
	WHERE   J.Id != @JobId
		AND JI.Status = @RunningStatus

	SELECT 
	 J.Id AS JobId
	,JS.Id AS JobStepId
	,JS.TaskId AS JobTaskConfigId
	,JS.TaskParam AS TaskParam
	FROM Jobs J
	JOIN #MatchingRunningJobIdsByStepsCount #MJ on J.Id = #MJ.JobId
	JOIN JobSteps JS ON JS.JobId = J.Id AND JS.IsActive = 1

	DROP TABLE #JobTaskConfigIds
	DROP TABLE #MatchingRunningJobIdsByStepsCount

END

GO

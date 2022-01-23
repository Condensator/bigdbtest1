SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AllocateEventsToActiveJobServices]
(
 @TriggeringJobServiceId BIGINT,
 @PollingThresholdInSec BIGINT
)
AS
DECLARE @EndingIndex BIGINT
DECLARE @ActiveIndex BIGINT
DECLARE @AvailableJobServicesCount BIGINT
DECLARE @ActiveJobServiceIndex BIGINT = 1
	
IF OBJECT_ID('tempdb..##AllocateEventsToActiveJobServicesLock') IS NULL
BEGIN	
	CREATE TABLE ##AllocateEventsToActiveJobServicesLock (Id BIGINT NOT NULL IDENTITY (1,1), EventInstanceId BIGINT NOT NULL)

	--Get all available job service is's into a temp table
	CREATE TABLE #ActiveJobServices
	(
		Id INT NOT NULL IDENTITY (1,1),
		JobServiceId BIGINT NOT NULL
	)

	INSERT INTO #ActiveJobServices (JobServiceId)
	SELECT js.Id
	FROM JobServices js
	WHERE js.IsRunning = 1 
		AND (js.RecentActiveTime IS NULL OR DATEDIFF(SECOND, js.RecentActiveTime, SYSDATETIMEOFFSET()) <= @PollingThresholdInSec)
		AND HostingEnvironment != 'WebApp'
			
	SELECT @AvailableJobServicesCount = COUNT(*) FROM #ActiveJobServices

	IF NOT EXISTS (SELECT 1 FROM #ActiveJobServices WHERE JobServiceId = @TriggeringJobServiceId)
	BEGIN
		INSERT INTO #ActiveJobServices (JobServiceId) VALUES(@TriggeringJobServiceId)
		SELECT @AvailableJobServicesCount = COUNT(*) FROM #ActiveJobServices
	END	

	--get the starting and ending index of non processed Events 
	INSERT INTO ##AllocateEventsToActiveJobServicesLock (EventInstanceId)
	SELECT Id FROM EventInstances WHERE (Status = 'Pending' OR Status = 'Retry') AND JobServiceId IS NULL
	SET @ActiveIndex = 1
	SELECT @EndingIndex = MAX(Id) FROM ##AllocateEventsToActiveJobServicesLock

	--iterate through the non processed events and allocate them to a job service
	WHILE @ActiveIndex <= @EndingIndex
	BEGIN
		UPDATE EventInstances
		SET JobServiceId = (SELECT ajs.JobServiceId FROM #ActiveJobServices ajs WHERE ajs.Id = @ActiveJobServiceIndex)
		WHERE Id = (SELECT EventInstanceId FROM ##AllocateEventsToActiveJobServicesLock WHERE Id = @ActiveIndex) AND JobServiceID IS NULL

		SET @ActiveIndex = @ActiveIndex + 1
		IF(@ActiveJobServiceIndex = @AvailableJobServicesCount)
			SET @ActiveJobServiceIndex = 1
		ELSE
			SET @ActiveJobServiceIndex = @ActiveJobServiceIndex + 1
	END

	DROP TABLE #ActiveJobServices
	DROP TABLE ##AllocateEventsToActiveJobServicesLock
END

GO

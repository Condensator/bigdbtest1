SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetLoadToDistribute]
(
	@JobStepInstanceId BIGINT,
	@QueueId BIGINT,
	@AutoQueueAssignment VARCHAR(6)
)
AS
BEGIN
	
	CREATE TABLE #CustomerToDistribute
	(
		CustomerId BIGINT NOT NULL,
		IsWorkListUnassigned BIT NOT NULL
	)

	INSERT INTO #CustomerToDistribute
	SElECT DISTINCT CustomerId, 1
		FROM CollectionsJobExtracts
		INNER JOIN CollectionQueues ON CollectionsJobExtracts.AllocatedQueueId = CollectionQueues.Id
	WHERE 
		JobStepInstanceId = @JobStepInstanceId AND
		AllocatedQueueId = @QueueId AND
		CollectionQueues.AssignmentMethod = @AutoQueueAssignment AND
		IsWorkListIdentified = 1 AND
		PrimaryCollectorId IS NULL


	INSERT INTO #CustomerToDistribute
	SELECT DISTINCT CollectionsJobExtracts.CustomerId, 0
		FROM CollectionsJobExtracts
			LEFT JOIN #CustomerToDistribute ON CollectionsJobExtracts.CustomerId = #CustomerToDistribute.CustomerId
		WHERE 
			JobStepInstanceId = @JobStepInstanceId AND
			#CustomerToDistribute.CustomerId IS NULL AND
			AllocatedQueueId = @QueueId AND
			IsWorkListIdentified = 0 AND
			IsWorkListCreated = 0 AND
			PrimaryCollectorId IS NULL
	
	SELECT DISTINCT CustomerId, IsWorkListUnassigned FROM #CustomerToDistribute

	DROP TABLE #CustomerToDistribute

END

GO

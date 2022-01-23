SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[CloseWorkLists]
(
	@JobStepInstanceId BIGINT,
	@BusinessUnitId BIGINT,
	@CustomerId BIGINT,
	@NonDelinquent NVARCHAR(29),
	@NotQualifiedInQueueAssignment NVARCHAR(29),
	@MovedToAnotherQueue NVARCHAR(29),
	@WorkListStatusClosed NVARCHAR(11),	
	@UserId BIGINT,
	@ServerTimeStamp DATETIMEOFFSET,
	@AccessibleLegalEntities CollectionsContractLegalEntityId READONLY
)
AS
BEGIN
	 
	CREATE TABLE #WorkListDetailsToClose
	(
		Id BIGINT,
		Reason NVARCHAR(58)
	)

	--NonDelinquentContracts
	
	INSERT INTO #WorkListDetailsToClose
	(
		Id,
		Reason
	)
	SELECT
		CollectionWorklistContractDetails.Id,
		@NonDelinquent
	FROM
		CollectionWorklistContractDetails
		INNER JOIN CollectionWorkLists
			ON CollectionWorkListContractDetails.CollectionWorkListId = CollectionWorkLists.Id
		INNER JOIN CollectionsJobContractExtracts
			ON CollectionsJobContractExtracts.ContractId = CollectionWorklistContractDetails.ContractId
		INNER JOIN @AccessibleLegalEntities AccessibleLegalEntities
			ON AccessibleLegalEntities.LegalEntityId = CollectionsJobContractExtracts.LegalEntityId
		LEFT JOIN CollectionsJobExtracts
			ON CollectionWorkListContractDetails.ContractId = CollectionsJobExtracts.ContractId AND
			   CollectionWorkLists.CustomerId = CollectionsJobExtracts.CustomerId AND
			   CollectionWorkLists.BusinessUnitId = CollectionsJobExtracts.BusinessUnitId AND
			   (ISNULL(CollectionWorkLists.RemitToId, 0) = ISNULL(CollectionsJobExtracts.RemitToId, 0)) AND
			   CollectionsJobExtracts.JobStepInstanceId = @JobStepInstanceId  
	WHERE
		CollectionWorkListContractDetails.IsWorkCompleted = 0 AND
		CollectionsJobExtracts.ContractId IS NULL AND
		(@CustomerId = 0 OR CollectionWorkLists.CustomerId = @CustomerId)  -- BU Not required


	--Disqualified in Queue
	
	INSERT INTO #WorkListDetailsToClose
	(
		Id,
		Reason
	)
	SELECT
		CollectionWorklistContractDetails.Id,
		@NotQualifiedInQueueAssignment
	FROM
		CollectionWorklistContractDetails
		INNER JOIN CollectionWorkLists
			ON CollectionWorkListContractDetails.CollectionWorkListId = CollectionWorkLists.Id
		INNER JOIN CollectionsJobExtracts
			ON CollectionWorkListContractDetails.ContractId = CollectionsJobExtracts.ContractId AND
			   CollectionWorkLists.CustomerId = CollectionsJobExtracts.CustomerId AND
			   CollectionWorkLists.BusinessUnitId = CollectionsJobExtracts.BusinessUnitId AND
			   (ISNULL(CollectionWorkLists.RemitToId, 0) = ISNULL(CollectionsJobExtracts.RemitToId, 0))
	WHERE
		CollectionWorkListContractDetails.IsWorkCompleted = 0 AND
		CollectionsJobExtracts.JobStepInstanceId = @JobStepInstanceId AND
		CollectionWorkLists.Status <> @WorkListStatusClosed AND
		CollectionsJobExtracts.AllocatedQueueId IS NULL

	-- Queue movement without previous assignment
	INSERT INTO #WorkListDetailsToClose
	(
		Id,
		Reason
	)
	SELECT
		CollectionsJobExtracts.PreviousWorkListDetailId,
		@MovedToAnotherQueue
	FROM 
		CollectionsJobExtracts
		INNER JOIN CollectionQueues
			ON CollectionsJobExtracts.AllocatedQueueId = CollectionQueues.Id
		INNER JOIN CollectionWorkListContractDetails 
			ON CollectionsJobExtracts.PreviousWorkListDetailId = CollectionWorkListContractDetails.Id
		INNER JOIN CollectionWorkLists
			ON CollectionWorkListContractDetails.CollectionWorkListId = CollectionWorkLists.Id
		INNER JOIN CollectionQueues PreviousQueue
			ON CollectionsJobExtracts.PreviousQueueId = PreviousQueue.Id
	WHERE 
		CollectionsJobExtracts.JobStepInstanceId = @JobStepInstanceId AND
		(CollectionQueues.AcrossQueue = 0 OR PreviousQueue.IsActive = 0) AND
		CollectionsJobExtracts.PreviousQueueId <> CollectionsJobExtracts.AllocatedQueueId AND
		CollectionWorkListContractDetails.IsWorkCompleted = 0


	UPDATE CollectionWorkListContractDetails
		SET IsWorkCompleted = 1, CompletionReason = #WorkListDetailsToClose.Reason, UpdatedById = @UserId, UpdatedTime = @ServerTimeStamp
	FROM CollectionWorkListContractDetails WorklistDetails
		INNER JOIN #WorkListDetailsToClose
			ON WorklistDetails.Id = #WorkListDetailsToClose.Id

	-- Worklists Without active collection worklist details

	SELECT 
		DISTINCT CollectionWorkLists.Id INTO #ActiveCollectionWorklists
	FROM
		CollectionWorkLists
	INNER JOIN CollectionWorkListContractDetails
		ON CollectionWorkLists.Id = CollectionWorkListContractDetails.CollectionWorkListId
	WHERE
		CollectionWorkLists.BusinessUnitId = @BusinessUnitId AND --to avoid closing of other BU contracts work completed = 0 WLs, job at same time
		(@CustomerId = 0 OR CollectionWorkLists.CustomerId = @CustomerId) AND
		CollectionWorkListContractDetails.IsWorkCompleted = 0 AND
		CollectionWorkLists.Status <> @WorkListStatusClosed


	UPDATE CollectionWorkLists
		SET Status = @WorkListStatusClosed, UpdatedById = @UserId, UpdatedTime = @ServerTimeStamp
	FROM CollectionWorkLists Worklists
		LEFT JOIN #ActiveCollectionWorklists
			ON Worklists.Id = #ActiveCollectionWorklists.Id
	WHERE
		Worklists.BusinessUnitId = @BusinessUnitId AND
		(@CustomerId = 0 OR Worklists.CustomerId = @CustomerId) AND
		Worklists.Status <> @WorkListStatusClosed AND
		#ActiveCollectionWorklists.Id IS NULL


END

GO

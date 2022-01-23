SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[ProcessPreviousAssignments]
(
	@JobStepInstanceId BIGINT,
	@WorkListStatusClosed NVARCHAR(11)	
)
AS
BEGIN

	UPDATE CollectionsJobExtracts
		SET AllocatedQueueId = PreviousQueueId 
	FROM CollectionsJobExtracts
		INNER JOIN CollectionQueues
			ON CollectionsJobExtracts.PreviousQueueId = CollectionQueues.Id
			AND CollectionQueues.IsActive = 1
		WHERE JobStepInstanceId = @JobStepInstanceId AND CollectionsJobExtracts.AcrossQueue = 1


	UPDATE CollectionsJobExtracts
				SET IsWorkListCreated = 1,
					IsWorkListIdentified = 1,
					PreviousWorkListId = CollectionWorkLists.Id,
					PrimaryCollectorId = CollectionWorkLists.PrimaryCollectorId
		FROM CollectionsJobExtracts
			INNER JOIN CollectionWorklistContractDetails 
				ON CollectionsJobExtracts.ContractId = CollectionWorklistContractDetails.ContractId
			INNER JOIN CollectionWorkLists
				ON CollectionWorkListContractDetails.CollectionWorkListId = CollectionWorkLists.Id AND
				   CollectionsJobExtracts.AllocatedQueueId = CollectionWorkLists.CollectionQueueId AND
				   CollectionsJobExtracts.CustomerId = CollectionWorkLists.CustomerId AND
				   CollectionsJobExtracts.CurrencyId = CollectionWorkLists.CurrencyId AND
				   CollectionsJobExtracts.BusinessUnitId = CollectionWorkLists.BusinessUnitId AND  -- Cont_1 -> BU_1, LE_1, -> WL_1, change LE_1 to LE_2 in BU_2
				   (ISNULL(CollectionsJobExtracts.RemitToId, 0) = ISNULL(CollectionWorkLists.RemitToId, 0))
		WHERE 
			CollectionsJobExtracts.JobStepInstanceId = @JobStepInstanceId AND
			CollectionWorkListContractDetails.IsWorkCompleted = 0 

	UPDATE
			CollectionsJobExtracts
		SET IsWorkListIdentified = 1, 
				PreviousWorkListId = CollectionWorkLists.Id,
				PrimaryCollectorId = CollectionWorkLists.PrimaryCollectorId
			FROM CollectionsJobExtracts AQW
				INNER JOIN CollectionWorkLists
					ON CollectionWorkLists.CollectionQueueId = AQW.AllocatedQueueId AND
					   CollectionWorkLists.CustomerId = AQW.CustomerId AND
					   CollectionWorkLists.CurrencyId = AQW.CurrencyId AND
					   CollectionWorkLists.BusinessUnitId = AQW.BusinessUnitId AND
					   (ISNULL(CollectionWorkLists.RemitToId, 0) = ISNULL(AQW.RemitToId, 0))					   
		WHERE 
			AQW.JobStepInstanceId = @JobStepInstanceId AND
			AQW.IsWorkListIdentified = 0 AND
			CollectionWorkLists.Status <> @WorkListStatusClosed

	
	UPDATE
		CollectionsJobExtracts
	SET  PrimaryCollectorId = CollectionWorkLists.PrimaryCollectorId 
		FROM CollectionsJobExtracts AQW
			INNER JOIN CollectionWorkLists
				ON AQW.AllocatedQueueId = CollectionWorkLists.CollectionQueueId AND 
				   AQW.CustomerId = CollectionWorkLists.CustomerId				   
			WHERE
				AQW.JobStepInstanceId = @JobStepInstanceId AND
				CollectionWorkLists.Status <> @WorkListStatusClosed AND
				AQW.IsWorkListIdentified = 0


	UPDATE	
		CollectionsJobExtracts
	SET PrimaryCollectorId = ExtractWithCollectors.PrimaryCollectorId
		FROM CollectionsJobExtracts 
			INNER JOIN CollectionsJobExtracts ExtractWithCollectors
				ON CollectionsJobExtracts.AllocatedQueueId = ExtractWithCollectors.AllocatedQueueId AND
				   CollectionsJobExtracts.CustomerId = ExtractWithCollectors.CustomerId
			WHERE
				CollectionsJobExtracts.JobStepInstanceId = @JobStepInstanceId AND
				ExtractWithCollectors.JobStepInstanceId = @JobStepInstanceId AND
				CollectionsJobExtracts.PrimaryCollectorId IS NULL AND
				ExtractWithCollectors.PrimaryCollectorId IS NOT NULL

END

GO

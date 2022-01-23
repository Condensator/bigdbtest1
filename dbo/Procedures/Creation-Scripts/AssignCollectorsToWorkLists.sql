SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[AssignCollectorsToWorkLists]
(
	@JobStepInstanceId BIGINT,
	@WorkListStatusClosed NVARCHAR(11),
	@UserId BIGINT,
	@ServerTimeStamp DATETIMEOFFSET,
	@CollectorAssignments CollectorAssignment READONLY
)
AS
BEGIN

	UPDATE CollectionWorkLists
			SET PrimaryCollectorId = Collector.PrimaryCollectorId, 
				UpdatedById = @UserId, 
				UpdatedTime = @ServerTimeStamp
		FROM CollectionWorkLists
			INNER JOIN CollectionsJobExtracts ON CollectionWorkLists.CollectionQueueId = CollectionsJobExtracts.AllocatedQueueId
				AND CollectionWorkLists.CustomerId = CollectionsJobExtracts.CustomerId				
			INNER JOIN @CollectorAssignments Collector ON CollectionWorkLists.CollectionQueueId = Collector.AllocatedQueueId
				AND CollectionWorkLists.CustomerId = Collector.CustomerId
		WHERE CollectionsJobExtracts.JobStepInstanceId = @JobStepInstanceId -- 2 runs running parallel; latest collector will be updated
			AND CollectionWorkLists.Status <> @WorkListStatusClosed

END

GO

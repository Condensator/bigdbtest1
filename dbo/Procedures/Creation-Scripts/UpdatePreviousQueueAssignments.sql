SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[UpdatePreviousQueueAssignments]
(
	@JobStepInstanceId BIGINT,
	@UserActiveStatus NVARCHAR(8),
	@RoleFunctionCollections NVARCHAR(22),
	@CustomAssignmentMethod NVARCHAR(6)
)
AS 
BEGIN
   
	SELECT
		CollectionExtractId,
		CollectionWorkListId,
		CollectionWorkListStatus,
		CollectionQueueId,
		PrimaryCollectorId,
		WorkListDetailId 
	INTO #PreviousQueueAssignments
	FROM
		(SELECT
			CollectionsJobExtracts.Id CollectionExtractId,
			CollectionWorkLists.Id CollectionWorkListId,
			CollectionWorkLists.Status CollectionWorkListStatus,
			CollectionWorkListContractDetails.Id WorkListDetailId,
			CollectionWorkLists.CollectionQueueId,
			CASE WHEN CollectionQueues.AssignmentMethod = @CustomAssignmentMethod THEN Users.Id ELSE UsersInUserGroups.UserId END AS PrimaryCollectorId,
			ROW_NUMBER() OVER(PARTITION BY CollectionWorkListContractDetails.ContractId, CollectionWorklists.CustomerId, CollectionsJobExtracts.RemitToId, CollectionsJobExtracts.BusinessUnitId ORDER BY CollectionWorkListContractDetails.Id DESC) RowNumber
		FROM
			CollectionWorkListContractDetails
		INNER JOIN CollectionsJobExtracts
			ON CollectionWorkListContractDetails.ContractId = CollectionsJobExtracts.ContractId 
		INNER JOIN CollectionWorkLists
			ON CollectionWorkListContractDetails.CollectionWorkListId = CollectionWorkLists.Id AND
			   CollectionsJobExtracts.CustomerId = CollectionWorkLists.CustomerId AND
			   CollectionsJobExtracts.BusinessUnitId = CollectionWorkLists.BusinessUnitId AND
			   (ISNULL(CollectionsJobExtracts.RemitToId, 0) = ISNULL(CollectionWorkLists.RemitToId, 0))
		LEFT JOIN CollectionQueues ON CollectionWorkLists.CollectionQueueId = CollectionQueues.Id 
				AND CollectionQueues.IsActive = 1
		LEFT JOIN Users On CollectionWorkLists.PrimaryCollectorId = Users.Id 
				AND Users.ApprovalStatus = @UserActiveStatus
		LEFT JOIN UsersInUserGroups ON CollectionQueues.PrimaryCollectionGroupId = UsersInUserGroups.UserGroupId 
				AND Users.Id = UsersInUserGroups.UserId AND UsersInUserGroups.IsActive = 1
		WHERE CollectionsJobExtracts.JobStepInstanceId = @JobStepInstanceId
	) AS PreviousAssignments
	 WHERE
		RowNumber = 1


	 UPDATE CollectionsJobExtracts
			SET PreviousQueueId = #PreviousQueueAssignments.CollectionQueueId, 
				PrimaryCollectorId = CASE WHEN CollectionsExtract.AcrossQueue = 1 THEN  #PreviousQueueAssignments.PrimaryCollectorId ELSE NULL END,
				PreviousWorkListId = #PreviousQueueAssignments.CollectionWorkListId, 
				PreviousWorkListDetailId = #PreviousQueueAssignments.WorkListDetailId
		 FROM CollectionsJobExtracts CollectionsExtract
				INNER JOIN #PreviousQueueAssignments 
					ON #PreviousQueueAssignments.CollectionExtractId = CollectionsExtract.Id			

END

GO

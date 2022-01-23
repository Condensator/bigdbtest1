SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetCollectionLogData]
(
	@JobStepInstanceId BIGINT,
	@CollectionOpenStatus NVARCHAR(11),
	@RoleFunctionCollections NVARCHAR(22),
	@UserActiveStatus NVARCHAR(8),
	@AutoQueueAssignment VARCHAR(6)
)
AS
BEGIN
	
	SElECT DISTINCT 
				CollectionsJobExtracts.AllocatedQueueId AS CollectionQueueId
				,CollectionQueues.[Name] AS QueueName
		INTO #QualifiedQueues
		FROM CollectionsJobExtracts
			INNER JOIN CollectionQueues ON CollectionsJobExtracts.AllocatedQueueId = CollectionQueues.Id
			WHERE 
				CollectionsJobExtracts.JobStepInstanceId = @JobStepInstanceId 


	SELECT DISTINCT 
			CollectionQueues.Id AS CollectionQueueId 
		INTO #QueueWithCollectors
		FROM #QualifiedQueues
			INNER JOIN CollectionQueues 
				ON #QualifiedQueues.CollectionQueueId = CollectionQueues.Id
			INNER JOIN UserGroups 
				ON CollectionQueues.PrimaryCollectionGroupId = UserGroups.Id
			INNER JOIN RoleFunctions
				ON UserGroups.DefaultRoleFunctionId = RoleFunctions.Id
					AND RoleFunctions.SystemDefinedName = @RoleFunctionCollections 
			INNER JOIN UsersInUserGroups 
				ON UserGroups.Id = UsersInUserGroups.UserGroupId
			INNER JOIN Users 
				On UsersInUserGroups.UserId = Users.Id
			INNER JOIN RolesForUsers 
				ON Users.Id = RolesForUsers.UserId
			INNER JOIN Roles
				ON RolesForUsers.RoleId = Roles.Id
		WHERE CollectionQueues.IsActive = 1
			AND UserGroups.IsActive = 1
			AND RoleFunctions.IsActive = 1
			AND UsersInUserGroups.IsActive = 1
			AND Users.ApprovalStatus = @UserActiveStatus
			AND RolesForUsers.IsActive = 1
			AND Roles.IsActive = 1
		GROUP BY 
			CollectionQueues.Id,
			Users.Id;

	
	DECLARE @NewWorkListCount BIGINT;
	DECLARE @AssignedWorkListCount BIGINT;
	DECLARE @UnQualifiedContractCount BIGINT;
	DECLARE @UnQualifiedContractSequenceNumberCSV NVARCHAR(MAX);
	DECLARE @QueuesWithNoCollectorsCSV NVARCHAR(MAX);
	

	-- Queues with Collectors
	SELECT 
			@QueuesWithNoCollectorsCSV = STRING_AGG(CAST(QueueName AS NVARCHAR(MAX)), ',')
		FROM
		(
			SELECT DISTINCT #QualifiedQueues.QueueName 
				FROM #QualifiedQueues
					LEFT JOIN #QueueWithCollectors ON #QualifiedQueues.CollectionQueueId = #QueueWithCollectors.CollectionQueueId
				WHERE #QueueWithCollectors.CollectionQueueId IS NULL
		)
		AS QueueWithoutCollector


    -- Contracts not qualified for any queue
	SELECT 
		@UnQualifiedContractCount = Count(*)
		,@UnQualifiedContractSequenceNumberCSV = STRING_AGG(CAST(SequenceNumber AS NVARCHAR(MAX)), ',')
		FROM
		(
			SElECT DISTINCT 
					CollectionsJobExtracts.ContractId
					,Contracts.SequenceNumber
				FROM CollectionsJobExtracts
					INNER JOIN Contracts ON CollectionsJobExtracts.ContractId = Contracts.Id
					WHERE 
						CollectionsJobExtracts.JobStepInstanceId = @JobStepInstanceId AND
						CollectionsJobExtracts.AllocatedQueueId IS NULL
		)
		AS ContractsWithoutQueue;


	-- New CollectionWorkLists and Assigned CollectionWorkLists Count
	SELECT 
			@NewWorkListCount = COUNT(*)
			,@AssignedWorkListCount = COUNT(PrimaryCollectorId)
		FROM
		(
			SELECT DISTINCT	
					CollectionWorkLists.Id AS WorklistId
					,CollectionWorkLists.PrimaryCollectorId
				 FROM 
						CollectionsJobExtracts
						INNER JOIN CollectionWorkLists ON CollectionsJobExtracts.AllocatedQueueId = CollectionWorkLists.CollectionQueueId AND
						   CollectionsJobExtracts.CustomerId = CollectionWorkLists.CustomerId AND
						   CollectionsJobExtracts.CurrencyId = CollectionWorkLists.CurrencyId AND
						   CollectionsJobExtracts.BusinessUnitId = CollectionWorkLists.BusinessUnitId AND
						   (ISNULL(CollectionsJobExtracts.RemitToId, 0) = ISNULL(CollectionWorkLists.RemitToId, 0))
					WHERE CollectionsJobExtracts.JobStepInstanceId = @JobStepInstanceId
						AND CollectionsJobExtracts.IsWorkListCreated = 0
						AND CollectionsJobExtracts.IsWorkListIdentified = 0
						AND CollectionWorkLists.Status = @CollectionOpenStatus
		)
		AS NewWorklistCreated

	SELECT @NewWorkListCount AS NewWorkListCount
			,@AssignedWorkListCount AS AssignedWorkListCount
			,@UnQualifiedContractCount AS UnQualifiedContractCount
			,@UnQualifiedContractSequenceNumberCSV AS UnQualifiedContractSequenceNumberCSV
			,@QueuesWithNoCollectorsCSV AS QueuesWithNoCollectorsCSV;


	DROP TABLE #QualifiedQueues;
	DROP TABLE #QueueWithCollectors;
	

END

GO

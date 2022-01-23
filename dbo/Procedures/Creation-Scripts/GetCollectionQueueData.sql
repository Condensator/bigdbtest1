SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetCollectionQueueData]
(
	@JobStepInstanceId BIGINT,
	@CollectionOpenStatus NVARCHAR(11),
	@RoleFunctionCollections NVARCHAR(22),
	@UserActiveStatus NVARCHAR(8),
	@AutoQueueAssignment VARCHAR(6),
	@CollectorDefaultCapacity INT
)
AS
BEGIN
	
	SElECT 
		DISTINCT CollectionsJobExtracts.AllocatedQueueId
	INTO #Queues
	FROM CollectionsJobExtracts
		INNER JOIN CollectionQueues ON CollectionsJobExtracts.AllocatedQueueId = CollectionQueues.Id
		WHERE 
			CollectionsJobExtracts.JobStepInstanceId = @JobStepInstanceId AND
			CollectionQueues.AssignmentMethod = @AutoQueueAssignment AND
			CollectionsJobExtracts.PrimaryCollectorId IS NULL

	SELECT CollectionQueues.Id CollectionQueueId, 
			CollectionQueues.Name QueueName,
			Users.Id CollectorId,
			MAX(Roles.CollectorCapacity) CollectorCapacity
		INTO #QueueCollectors
		FROM #Queues
			INNER JOIN CollectionQueues 
				ON #Queues.AllocatedQueueId = CollectionQueues.Id
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
			AND RoleFunctions.IsActive = 1
			AND UsersInUserGroups.IsActive = 1
			AND Users.ApprovalStatus = @UserActiveStatus
			AND RolesForUsers.IsActive = 1
			AND Roles.IsActive = 1
		GROUP BY 
			CollectionQueues.Id,
			CollectionQueues.Name,
			Users.Id

	SELECT DISTINCT CollectorId, CollectorCapacity INTO #DistinctCollectors FROM #QueueCollectors

	SELECT  #DistinctCollectors.CollectorId, 
			COUNT(CurrentLoad.CustomerId) CurrentLoad,
			ISNULL(CAST(CollectorCapacity AS INT), @CollectorDefaultCapacity) Capacity			 
		INTO #CollectorsLoad
		FROM #DistinctCollectors
				LEFT JOIN 
				(
					SELECT DISTINCT CollectionWorkLists.CustomerID, 
									CollectionWorkLists.CollectionQueueId, 
									CollectionWorkLists.PrimaryCollectorId
						FROM CollectionWorkLists
					WHERE CollectionWorkLists.Status = @CollectionOpenStatus
				) AS CurrentLoad
					ON #DistinctCollectors.CollectorId = CurrentLoad.PrimaryCollectorId	
		GROUP BY #DistinctCollectors.CollectorId, CollectorCapacity

	SELECT CollectionQueueId, QueueName, CollectorId FROM #QueueCollectors;

	SELECT * FROM #CollectorsLoad;

	DROP TABLE #Queues;
	DROP TABLE #QueueCollectors;
	DROP TABLE #CollectorsLoad;
	DROP TABLE #DistinctCollectors;

END

GO

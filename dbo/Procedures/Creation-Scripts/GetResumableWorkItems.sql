SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  
CREATE PROCEDURE [dbo].[GetResumableWorkItems](@CurrentUserId bigint,@EntityId bigint,@EnityName nvarchar(100),@AvoidDummyEndStep bit, @CurrentSubsystemId bigint, @Assigned NVARCHAR(20), @UnAssigned NVARCHAR(20), @PortfolioAccessScope NVARCHAR(20), @PortfolioId bigint, @BusinessUnitAccessScope  NVARCHAR(20), @BusinessUnitId bigint, @LegalEntityAccessScope NVARCHAR(20), @LegalEntityIdsCSV NVARCHAR(MAX), @GetAcquirableOtherWorkItems BIT)
AS
BEGIN

DECLARE @LegalEntityIds TABLE (Id bigint);
INSERT INTO @LegalEntityIds 
SELECT Id FROM ConvertCSVToBigIntTable(@LegalEntityIdsCsv, ',');

WITH CTE_WorkItem
AS(
SELECT
	TransactionInstances.EntityId ,
	TransactionInstances.EntityName ,
	WorkItems.Id [WorkItemId],
	WorkItems.OwnerUserId,
	WorkItems.WorkItemConfigId,
	TransactionInstances.Id ,
	TransactionInstances.TransactionName ,
	WorkItemConfigs.Label ,
	WorkItemConfigs.Name [StepName],
	WorkItemConfigs.AcquireFromOtherUser,
	WorkItemConfigs.Form,
	WorkItems.Status
FROM
	WorkItems

	INNER JOIN TransactionInstances
		ON	TransactionInstances.Id = WorkItems.TransactionInstanceId
		AND	TransactionInstances.EntityId = @EntityId
		AND TransactionInstances.EntityName = @EnityName
		AND (TransactionInstances.AccessScopeId IS NULL 
				OR (TransactionInstances.AccessScope = @PortfolioAccessScope AND TransactionInstances.AccessScopeId = @PortfolioId) 
				OR (TransactionInstances.AccessScope = @BusinessUnitAccessScope AND TransactionInstances.AccessScopeId = @BusinessUnitId)
				OR (TransactionInstances.AccessScope = @LegalEntityAccessScope AND TransactionInstances.AccessScopeId IN (SELECT Id FROM @LegalEntityIds)))
		AND TransactionInstances.IsFromAutoAction = 0

	INNER JOIN WorkItemConfigs
		ON	WorkItemConfigs.id = WorkItems.WorkItemConfigId
		AND (@AvoidDummyEndStep = 0 OR WorkItemConfigs.DummyEndStep = 0)
		
	INNER JOIN WorkItemSubSystemConfigs 
		ON WorkItemConfigs.Id = WorkItemSubSystemConfigs.WorkItemConfigId 
		AND WorkItemSubSystemConfigs.SubSystemId = @CurrentSubsystemId
		AND WorkItemSubSystemConfigs.Viewable = 1
	

WHERE
	WorkItems.Status IN (@UnAssigned,@Assigned)
),
CTE_UnassignedWorkItems
AS
(
SELECT
	CTE_WorkItem.EntityId ,
	CTE_WorkItem.EntityName ,
	CTE_WorkItem.WorkItemId,
	CTE_WorkItem.OwnerUserId,
	CTE_WorkItem.WorkItemConfigId,
	CTE_WorkItem.Id ,
	CTE_WorkItem.Label,
	CTE_WorkItem.StepName,
	CTE_WorkItem.Form,
	TransactionName
FROM
	CTE_WorkItem
WHERE
	CTE_WorkItem.Status = @UnAssigned
	AND NOT EXISTS(
			SELECT 1
			FROM
				WorkItemAssignments
			WHERE
				WorkItemAssignments.WorkItemId  = CTE_WorkItem.WorkItemId) 
)
,CTE_MyAssignedWorkItems
AS
(
SELECT 
	CTE_WorkItem.EntityId ,
	CTE_WorkItem.EntityName ,
	CTE_WorkItem.WorkItemId,
	CTE_WorkItem.OwnerUserId,
	CTE_WorkItem.WorkItemConfigId,
	CTE_WorkItem.Id ,
	CTE_WorkItem.Label,
	CTE_WorkItem.StepName,
	CTE_WorkItem.Form,
	TransactionName
FROM CTE_WorkItem
	WHERE CTE_WorkItem.OwnerUserId = @CurrentUserId
),
CTE_MyUnassignedWorkItems
AS
(
SELECT
	CTE_WorkItem.EntityId ,
	CTE_WorkItem.EntityName ,
	CTE_WorkItem.WorkItemId,
	CTE_WorkItem.OwnerUserId,
	CTE_WorkItem.WorkItemConfigId,
	CTE_WorkItem.Id ,
	CTE_WorkItem.Label,
	CTE_WorkItem.StepName,
	CTE_WorkItem.Form,TransactionName
FROM
	CTE_WorkItem

	INNER JOIN WorkItemAssignments
		ON	WorkItemAssignments.WorkItemId = CTE_WorkItem.WorkItemId
	WHERE (CTE_WorkItem.Status = @UnAssigned and WorkItemAssignments.UserId = @CurrentUserId)
)
,CTE_MyWorkItemsAssignedToOtherUsers
AS
(
SELECT 
	CTE_WorkItem.EntityId ,
	CTE_WorkItem.EntityName ,
	CTE_WorkItem.WorkItemId,
	CTE_WorkItem.OwnerUserId,
	CTE_WorkItem.WorkItemConfigId,
	CTE_WorkItem.Id ,
	CTE_WorkItem.Label,
	CTE_WorkItem.StepName,
	CTE_WorkItem.Form,
	TransactionName
FROM CTE_WorkItem
LEFT JOIN WorkItemAssignments ON WorkItemAssignments.WorkItemId = CTE_WorkItem.WorkItemId
WHERE @GetAcquirableOtherWorkItems = 1 
AND CTE_WorkItem.Status = @Assigned
AND CTE_WorkItem.AcquireFromOtherUser = 1
AND (WorkItemAssignments.Id IS NULL OR WorkItemAssignments.UserId = @CurrentUserId)
AND CTE_WorkItem.OwnerUserId IS NOT NULL AND CTE_WorkItem.OwnerUserId != @CurrentUserId
),
CTE_FINAL
AS(
SELECT
	CTE_MyAssignedWorkItems.EntityId ,
	CTE_MyAssignedWorkItems.EntityName ,
	CTE_MyAssignedWorkItems.WorkItemId,
	CTE_MyAssignedWorkItems.OwnerUserId,
	CTE_MyAssignedWorkItems.WorkItemConfigId,
	CTE_MyAssignedWorkItems.Id ,
	CTE_MyAssignedWorkItems.Label,
	CTE_MyAssignedWorkItems.StepName,
	CTE_MyAssignedWorkItems.Form,TransactionName
FROM
	CTE_MyAssignedWorkItems
UNION
SELECT
	CTE_MyUnassignedWorkItems.EntityId ,
	CTE_MyUnassignedWorkItems.EntityName ,
	CTE_MyUnassignedWorkItems.WorkItemId,
	CTE_MyUnassignedWorkItems.OwnerUserId,
	CTE_MyUnassignedWorkItems.WorkItemConfigId,
	CTE_MyUnassignedWorkItems.Id ,
	CTE_MyUnassignedWorkItems.Label,
	CTE_MyUnassignedWorkItems.StepName,
	CTE_MyUnassignedWorkItems.Form,TransactionName
FROM
	CTE_MyUnassignedWorkItems
UNION
SELECT
	CTE_UnassignedWorkItems.EntityId ,
	CTE_UnassignedWorkItems.EntityName ,
	CTE_UnassignedWorkItems.WorkItemId,
	CTE_UnassignedWorkItems.OwnerUserId,
	CTE_UnassignedWorkItems.WorkItemConfigId,
	CTE_UnassignedWorkItems.Id ,
	CTE_UnassignedWorkItems.Label,
	CTE_UnassignedWorkItems.StepName,
	CTE_UnassignedWorkItems.Form,TransactionName
FROM
	CTE_UnassignedWorkItems
UNION
SELECT
	CTE_MyWorkItemsAssignedToOtherUsers.EntityId ,
	CTE_MyWorkItemsAssignedToOtherUsers.EntityName ,
	CTE_MyWorkItemsAssignedToOtherUsers.WorkItemId,
	CTE_MyWorkItemsAssignedToOtherUsers.OwnerUserId,
	CTE_MyWorkItemsAssignedToOtherUsers.WorkItemConfigId,
	CTE_MyWorkItemsAssignedToOtherUsers.Id ,
	CTE_MyWorkItemsAssignedToOtherUsers.Label,
	CTE_MyWorkItemsAssignedToOtherUsers.StepName,
	CTE_MyWorkItemsAssignedToOtherUsers.Form,TransactionName
FROM
	CTE_MyWorkItemsAssignedToOtherUsers
)
SELECT * FROM CTE_FINAL;
END;

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetEnMasseWorkItemAssignmentInfos](
	 @WorkItemIdsCsv NVARCHAR(MAX)
	,@Completed NVARCHAR(20)
)
AS
BEGIN

DECLARE @WorkItemIds TABLE (Id bigint);
INSERT INTO @WorkItemIds 
SELECT Id FROM ConvertCSVToBigIntTable(@WorkItemIdsCsv, ',')

CREATE TABLE #AccessibleWorkItems
(
	WorkItemId BIGINT NOT NULL PRIMARY KEY,
	TransactionInstanceId BIGINT NOT NULL,
	CreatedDate DATETIMEOFFSET NOT NULL
);

CREATE TABLE #RecentCompletedWorkItemIds
(
	WorkItemId BIGINT NOT NULL PRIMARY KEY,
	CompletedWorkItemId BIGINT NOT NULL
);

CREATE TABLE #RecentCompletedWorkItems
(
	WorkItemId BIGINT NOT NULL PRIMARY KEY,
	MovedFrom NVARCHAR(500) NOT NULL,
	MovedBy NVARCHAR(500) NOT NULL
);

INSERT INTO #AccessibleWorkItems
SELECT
	   WI.Id [WorkItemId]
	  ,WI.TransactionInstanceId
	  ,WI.CreatedDate
FROM WorkItems WI
JOIN @WorkItemIds #EWI ON WI.Id = #EWI.Id

INSERT INTO #RecentCompletedWorkItemIds
SELECT
	  #AccessibleWorkItems.WorkItemId
	 ,MAX(RCWI.Id) [CompletedWorkItemId]
FROM #AccessibleWorkItems
JOIN WorkItems RCWI ON RCWI.TransactionInstanceId = #AccessibleWorkItems.TransactionInstanceId
WHERE RCWI.Status = @Completed
  AND RCWI.EndDate <= #AccessibleWorkItems.CreatedDate
GROUP BY #AccessibleWorkItems.WorkItemId;

INSERT INTO #RecentCompletedWorkItems
SELECT
	  #RecentCompletedWorkItemIds.WorkItemId
	 ,RCWIC.Label [MovedFrom]
	 ,RCWIOwner.FullName [MovedBy]
FROM #RecentCompletedWorkItemIds
JOIN WorkItems RCWI ON RCWI.Id = #RecentCompletedWorkItemIds.CompletedWorkItemId
JOIN WorkItemConfigs RCWIC ON RCWI.WorkItemConfigId = RCWIC.Id
JOIN Users RCWIOwner ON RCWIOwner.Id = RCWI.OwnerUserId;

SELECT
	  WI.Id
	 ,WI.Id [WorkItemId]
	 ,WI.DueDate
	 ,WI.IsOptional
	 ,WI.Status
	 ,WI.OwnerUserId
	 ,WIOwner.FullName [AssignedTo]
	 ,WI.CreatedDate
	 ,WI.FollowupDate
	 ,WI.Comment
	 ,WorkItemConfigs.Label	[WorkItem]
	 ,TransactionStageConfigs.Label [Stage]
	 ,TransactionInstances.EntityId
	 ,TransactionInstances.EntityName
	 ,TransactionInstances.TransactionName
	 ,TransactionInstances.WorkflowSource
	 ,TransactionInstances.EntitySummary
	 ,TransactionInstances.Status [TransactionStatus]
	 ,TIStarter.FullName [CreatedBy]
	 ,#RecentCompletedWorkItems.MovedFrom
	 ,#RecentCompletedWorkItems.MovedBy
	 ,WorkItemConfigs.AcquireFromOtherUser
FROM WorkItems WI
JOIN #AccessibleWorkItems ON #AccessibleWorkItems.WorkItemId = WI.Id
LEFT JOIN Users WIOwner ON WIOwner.Id = WI.OwnerUserId
JOIN WorkItemConfigs ON WorkItemConfigs.Id = WI.WorkItemConfigId
JOIN TransactionStageConfigs ON TransactionStageConfigs.Id = WorkItemConfigs.TransactionStageConfigId
JOIN TransactionInstances ON TransactionInstances.Id = WI.TransactionInstanceId	
JOIN Users TIStarter ON TIStarter.Id = TransactionInstances.CreatedById
LEFT JOIN #RecentCompletedWorkItems ON #RecentCompletedWorkItems.WorkItemId = #AccessibleWorkItems.WorkItemId

END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateCollectionOwnerUser]
(
@CollectionWorkListIds CollectionWorkListIds READONLY,
@UpdatedUserId BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
--Set Transaction Isolation Level Read UnCommitted;
SELECT * INTO #CollectionWorkListIds
FROM @CollectionWorkListIds
UPDATE WorkItems
SET WorkItems.OwnerUserId = CollectionWorkLists.PrimaryCollectorId
,WorkItems.UpdatedById = @UpdatedUserId
,WorkItems.UpdatedTime = @UpdatedTime
FROM CollectionWorkLists
JOIN #CollectionWorkListIds ON #CollectionWorkListIds.CollectionWorkListId = CollectionWorkLists.Id
JOIN TransactionInstances ON CollectionWorkLists.Id = TransactionInstances.EntityId
JOIN WorkItems ON WorkItems.TransactionInstanceId = TransactionInstances.Id
WHERE WorkItems.Status = 'Assigned'
AND TransactionInstances.EntityName = 'CollectionWorkList'
AND TransactionInstances.Status = 'Active'
UPDATE WorkItemAssignments
SET WorkItemAssignments.UserId = CollectionWorkLists.PrimaryCollectorId
,WorkItemAssignments.UpdatedById = @UpdatedUserId
,WorkItemAssignments.UpdatedTime = @UpdatedTime
FROM CollectionWorkLists
JOIN #CollectionWorkListIds ON #CollectionWorkListIds.CollectionWorkListId = CollectionWorkLists.Id
JOIN TransactionInstances ON CollectionWorkLists.Id = TransactionInstances.EntityId
JOIN WorkItems ON WorkItems.TransactionInstanceId = TransactionInstances.Id
JOIN WorkItemAssignments ON WorkItemAssignments.WorkItemId = WorkItems.Id
WHERE WorkItems.Status = 'Assigned'
AND TransactionInstances.EntityName = 'CollectionWorkList'
AND TransactionInstances.Status = 'Active'
END

GO

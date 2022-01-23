SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[UpdateCollectionOwnerUserId]
(
@cwlId BigInt,
@UpdatedUserId BigInt,
@UpdatedTime DateTimeOffset
)
As
Begin
Set NoCount On;
--Set Transaction Isolation Level Read UnCommitted;
Declare @TransactionInstanceId BigInt;
Declare @workItemId BigInt;
Declare @primaryCollectorId BigInt;
Select @primaryCollectorId = PrimaryCollectorId From CollectionWorkLists
Where Id = @cwlId;
Select @TransactionInstanceId = Id From TransactionInstances
Where EntityName = 'CollectionWorkList' And EntityId = @cwlId
And Status = 'Active';
Select @workItemId = Id From WorkItems Where TransactionInstanceId = @TransactionInstanceId;
Update WorkItems Set OwnerUserId = @primaryCollectorId
,UpdatedById = @UpdatedUserId
,UpdatedTime = @UpdatedTime
Where TransactionInstanceId = @TransactionInstanceId
And Status = 'Assigned'
Update WorkItemAssignments Set UserId = @primaryCollectorId
,UpdatedById = @UpdatedUserId
,UpdatedTime = @UpdatedTime
Where WorkItemId = @workItemId;
End

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[UpdateReceiptWorkItemStatusFromReceiptBatch]
(
@ReceiptId ReceiptIdCollection READONLY,
@UpdatedUserId BigInt,
@UpdatedTime DateTimeOffset
)
As
Begin
Set NoCount On;
Set Transaction Isolation Level Read UnCommitted;

SELECT ReceiptId INTO #ReceiptIds FROM @ReceiptId

Select T.Id AS TransactionId,WorkItem.Id AS WorkItemId INTO #TransactionWorkItem 
From #ReceiptIds R
JOIN TransactionInstances T ON T.EntityId = R.ReceiptId AND EntityName = 'Receipt'
JOIN WorkItems WorkItem ON WorkItem.TransactionInstanceId = T.Id
WHERE T.Status = 'Active' AND WorkItem.Status != 'Completed'

Update T Set Status = 'Completed',
UpdatedById = @UpdatedUserId,
UpdatedTime = @UpdatedTime
FROM TransactionInstances T
JOIN #TransactionWorkItem TId ON TId.TransactionId = T.Id

Update WorkItem Set Status = 'Completed',
UpdatedById = @UpdatedUserId,
UpdatedTime = @UpdatedTime
FROM WorkItems WorkItem
JOIN #TransactionWorkItem WId ON WId.WorkItemId = WorkItem.Id AND WorkItem.TransactionInstanceId = WId.TransactionId

End

GO

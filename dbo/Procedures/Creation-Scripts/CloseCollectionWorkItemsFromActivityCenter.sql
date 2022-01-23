SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[CloseCollectionWorkItemsFromActivityCenter]
(
@CustomerId BigInt
,@UpdatedById BigInt
,@UpdatedTime DateTimeOffset
)
As
Begin
Set NoCount On;
Set Transaction Isolation Level Read UnCommitted;
Declare @Sql Nvarchar(Max);
Set @Sql =N'
Update CollectionWorkLists Set Status = ''Closed''
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime
Where Status = ''Open''
And CustomerId = @CustomerId
Update WorkItems Set Status=''Completed''
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime
Where Id in  (Select  W.Id from WorkItems W
join TransactionInstances T on W.TransactionInstanceId = T.Id
Where T.EntityName=''CollectionWorklist'' and
T.EntityId in (SELECT ID FROM CollectionWorkLists Where Status = ''Open'' And CustomerId = @CustomerId))
'
Exec sp_executesql @sql,N'@CustomerId BigInt,@UpdatedById BigInt,@UpdatedTime DateTimeOffset',@CustomerId,@UpdatedById,@UpdatedTime
End

GO

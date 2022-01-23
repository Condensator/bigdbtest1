SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[GetContractsForCollectionQueueAssignment]
(
@CustomerList CustomerList READONLY
)
As
Begin
Set NoCount On;
Set Transaction Isolation Level Read UnCommitted;
Declare @QueueId BigInt;
Create Table #Contracts(ContractId BigInt);
Create Table #ContractResult(ContractId BigInt,CustomerId BigInt,QueueId BigInt);
Create Table #ContractType(ContractId BigInt,ContractType NVarchar(25));
Create TABLE #CollectionQueue(QueueId BigInt, RowNumber Bigint)
Insert Into #CollectionQueue ( QueueId , RowNumber )
Select Id,Row_Number() Over (Order By Id) From dbo.CollectionQueues Where IsActive = 1 Order By Id
Declare @LastRowNumber BigInt = (Select IsNull(Max(RowNumber),0) From #CollectionQueue)
Declare @CurrentRowNumber BigInt = 1
While (@LastRowNumber >= @CurrentRowNumber)
Begin
Set @QueueId = (Select QueueId From #CollectionQueue Where RowNumber = @CurrentRowNumber)
Declare @Query NVarchar(Max);
Select @Query = RuleExpression From CollectionQueues Where Id = @QueueId
Truncate Table #Contracts
Truncate Table #ContractType
Insert Into #Contracts(ContractId)
EXEC SP_EXECUTESQL @Query
Insert into #ContractType
Select c.Id
,Case When lf.CustomerId Is Not Null Then 'Loan'
When lf1.CustomerId Is Not Null Then 'Lease'
When lf2.CustomerId Is Not Null Then 'LeveragedLease'
Else NULL
End ContractType
From Contracts c
Join #Contracts
on c.Id = #Contracts.ContractId
Left Join LoanFinances lf
on c.Id = lf.ContractId
And lf.IsCurrent = 1
Left Join LeaseFinances lf1
on c.Id = lf1.ContractId
And lf1.IsCurrent = 1
Left Join LeveragedLeases lf2
on c.Id = lf.ContractId
And lf2.IsCurrent = 1
;With AssumedContracts As
(
Select c.Id ContractId
,a.OriginalCustomerId CustomerId
,Sum(rd.Balance_Amount + IsNull(rid.TaxBalance_Amount,0)) ReceivableBalance
From Contracts c
Join #Contracts
on c.Id = #Contracts.ContractId
Join Assumptions a
on #Contracts.ContractId = a.ContractId
Join Receivables r
on r.EntityId = a.ContractId
And r.CustomerId = a.OriginalCustomerId
And r.EntityType = 'CT'
And r.IsActive = 1
Join ReceivableDetails rd
on rd.ReceivableId = r.Id
Left Join ReceivableInvoiceDetails rid
on rd.Id = rid.ReceivableDetailId
And rid.EntityId = a.ContractId
And rid.EntityType = 'CT'
Where c.Status Not In('Cancelled','Inactive','Terminated')
And a.Status = 'Approved'
Group By c.Id,a.OriginalCustomerId
)
Insert Into #ContractResult(ContractId ,CustomerId,QueueId)
Select ContractId, CustomerId, @QueueId From AssumedContracts Where ReceivableBalance != 0
Insert Into #ContractResult(ContractId ,CustomerId,QueueId)
Select c.Id
,lf.CustomerId
,@QueueId
From Contracts c
Join #Contracts
on c.Id = #Contracts.ContractId
Join #ContractType
on c.Id = #ContractType.ContractId
Join LoanFinances lf
on c.Id = lf.ContractId
And lf.IsCurrent = 1
Left Join CollectionWorkListContractDetails cwlContract
on c.Id = cwlContract.ContractId
And cwlContract.Id Is Null
Where c.Status Not In('Cancelled','Inactive','Terminated')
And (#ContractType.ContractType = 'Loan' And Not ((c.Status = 'Pending' OR c.Status = 'InstallingAssets' OR c.Status = 'UnCommenced') And lf.CreateInvoiceForAdvanceRental = 1))
Union All
Select c.Id
,lf.CustomerId
,@QueueId
From Contracts c
Join #Contracts
on c.Id = #Contracts.ContractId
Join #ContractType
on c.Id = #ContractType.ContractId
Join LeaseFinances lf
on c.Id = lf.ContractId
And lf.IsCurrent = 1
Join LeaseFinanceDetails lfd
on lf.Id = lfd.Id
Left Join CollectionWorkListContractDetails cwlContract
on c.Id = cwlContract.ContractId
And cwlContract.Id Is Null
Where c.Status Not In('Cancelled','Inactive','Terminated')
And (#ContractType.ContractType = 'Lease' And Not ((c.Status = 'Pending' OR c.Status = 'InstallingAssets' OR c.Status = 'UnCommenced') And lfd.CreateInvoiceForAdvanceRental = 1))
Union All
Select c.Id
,lf.CustomerId
,@QueueId
From Contracts c
Join #Contracts
on c.Id = #Contracts.ContractId
Join #ContractType
on c.Id = #ContractType.ContractId
Join LeveragedLeases lf
on c.Id = lf.ContractId
And lf.IsCurrent = 1
Left Join CollectionWorkListContractDetails cwlContract
on c.Id = cwlContract.ContractId
And cwlContract.Id Is Null
Where c.Status Not In('Cancelled','Inactive','Terminated')
And #ContractType.ContractType = 'LeveragedLease'
Insert Into #ContractResult(ContractId ,CustomerId,QueueId)
Select c.Id
,lf.CustomerId
,@QueueId
From Contracts c
Join #Contracts
on c.Id = #Contracts.ContractId
Join #ContractType
on c.Id = #ContractType.ContractId
Join LoanFinances lf
on c.Id = lf.ContractId
And lf.IsCurrent = 1
Join CollectionWorkListContractDetails cwlContract
on c.Id = cwlContract.ContractId
Join CollectionWorkLists cwl
on cwlContract.collectionWorkListId = cwl.Id
Where c.Status Not In('Cancelled','Inactive','Terminated')
And cwl.Status In('Closed','Cancelled')
And (#ContractType.ContractType = 'Loan' And Not ((c.Status = 'Pending' OR c.Status = 'InstallingAssets' OR c.Status = 'UnCommenced') And lf.CreateInvoiceForAdvanceRental = 1))
Union All
Select c.Id
,lf.CustomerId
,@QueueId
From Contracts c
Join #Contracts
on c.Id = #Contracts.ContractId
Join #ContractType
on c.Id = #ContractType.ContractId
Join LeaseFinances lf
on c.Id = lf.ContractId
And lf.IsCurrent = 1
Join LeaseFinanceDetails lfd
on lf.Id = lfd.Id
Join CollectionWorkListContractDetails cwlContract
on c.Id = cwlContract.ContractId
Join CollectionWorkLists cwl
on cwlContract.collectionWorkListId = cwl.Id
Where c.Status Not In('Cancelled','Inactive','Terminated')
And cwl.Status In('Closed','Cancelled')
And (#ContractType.ContractType = 'Lease' And Not ((c.Status = 'Pending' OR c.Status = 'InstallingAssets' OR c.Status = 'UnCommenced') And lfd.CreateInvoiceForAdvanceRental = 1))
Union All
Select c.Id
,lf.CustomerId
,@QueueId
From Contracts c
Join #Contracts
on c.Id = #Contracts.ContractId
Join #ContractType
on c.Id = #ContractType.ContractId
Join LeveragedLeases lf
on c.Id = lf.ContractId
And lf.IsCurrent = 1
Join CollectionWorkListContractDetails cwlContract
on c.Id = cwlContract.ContractId
Join CollectionWorkLists cwl
on cwlContract.collectionWorkListId = cwl.Id
Where c.Status Not In('Cancelled','Inactive','Terminated')
And cwl.Status In('Closed','Cancelled')
And #ContractType.ContractType = 'LeveragedLease'
Set @CurrentRowNumber = @CurrentRowNumber + 1
End
Select Distinct ContractId,#ContractResult.CustomerId,#ContractResult.QueueId From #ContractResult
Join @CustomerList CL On CL.CustomerId = #ContractResult.CustomerId
Order By ContractId
Drop Table #Contracts;
Drop Table #ContractResult;
Drop Table #ContractType;
Drop Table #CollectionQueue;
End

GO

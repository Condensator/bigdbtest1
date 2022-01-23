SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Proc [dbo].[FutureFundingsReport]
(
@LineofBusinessId BigInt
,@FromDate DateTime
,@ToDate DateTime
,@FutureScheduledFunding NVARCHAR(30)
,@BlendedItemPayable NVARCHAR(30)
,@BlendedItemReceivable NVARCHAR(30)
,@CurrentPortfolioId BigInt
)
As
Begin
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
Declare @SQL Nvarchar(max)
Set @SQL='
Select
PartyID
,CustomerNumber
,CustomerName
,ContractType
,SequenceNumber
,ContractId
,LegalEntityName
,PayeeName
,Type
,CurrencyName
,DueDate
,TotalAmount
,InvoiceNumber
,BlendedItemName
From
(
Select
customer.Id As PartyID
,customer.PartyNumber As CustomerNumber
,customer.PartyName As CustomerName
,Contracts.ContractType
,Contracts.SequenceNumber
,Contracts.Id As ContractId
,LegalEntities.Name As LegalEntityName
,vendor.Id As VendorId
,vendor.PartyName As PayeeName
,@FutureScheduledFunding As Type
,PayableInvoices.InvoiceTotal_Currency CurrencyName
,PayableInvoices.DueDate
,SUM(PayableInvoices.InvoiceTotal_Amount) As TotalAmount
,PayableInvoices.InvoiceNumber
,null As BlendedItemName
From PayableInvoices
Join Contracts on PayableInvoices.ContractId = Contracts.Id
Join LeaseFinances on Contracts.Id = LeaseFinances.ContractId
Join LeaseFundings on PayableInvoices.Id=LeaseFundings.FundingId
and LeaseFinances.Id = LeaseFundings.LeaseFinanceId and LeaseFundings.IsActive = 1
Join Parties customer on LeaseFinances.CustomerId=customer.Id
Join LegalEntities on LeaseFinances.LegalEntityId=LegalEntities.Id
Join Parties vendor on PayableInvoices.VendorId=vendor.Id
Left Join LineofBusinesses on Contracts.LineofBusinessId=LineofBusinesses.Id
Where
PayableInvoices.Status!=''InActive''
And Contracts.ContractType=''Lease''
And LeaseFinances.BookingStatus!=''FullyPaidOff''
And LeaseFinances.BookingStatus!=''Inactive''
And LeaseFinances.IsCurrent=1
And LeaseFundings.Type=''FutureScheduled''
And PayableInvoices.DueDate Between @FromDate and @ToDate
And LeaseFundings.IsActive=1
LINEOFBUSINESSCONDITION
GROUP BY
customer.Id
,customer.PartyNumber
,customer.PartyName
,Contracts.ContractType
,Contracts.SequenceNumber
,Contracts.Id
,LegalEntities.Name
,vendor.Id
,vendor.PartyName
,PayableInvoices.InvoiceTotal_Currency
,PayableInvoices.DueDate
,PayableInvoices.InvoiceNumber
Union all
Select
customer.Id As PartyID
,customer.PartyNumber As CustomerNumber
,customer.PartyName As CustomerName
,Contracts.ContractType
,Contracts.SequenceNumber
,Contracts.Id As ContractId
,LegalEntities.Name As LegalEntityName
,vendor.Id As VendorId
,vendor.PartyName As PayeeName
,case When (BlendedItems.Type=''IDC'' or BlendedItems.Type=''Expense'')
And BlendedItems.GeneratePayableOrReceivable=1
Then @BlendedItemPayable
Else
@BlendedItemReceivable
End AS Type
,BlendedItems.Amount_Currency As CurrencyName
,BlendedItems.DueDate
,SUM(BlendedItems.Amount_Amount) As TotalAmount
,null As InvoiceNumber
,BlendedItems.Name As BlendedItemName
From BlendedItems
Join LeaseBlendedItems on BlendedItems.Id=LeaseBlendedItems.BlendedItemId
Join LeaseFinances on LeaseBlendedItems.LeaseFinanceId=LeaseFinances.Id
Join Contracts on LeaseFinances.ContractId=Contracts.Id
Join Parties customer on LeaseFinances.CustomerId=customer.Id
Join LegalEntities on LeaseFinances.LegalEntityId=LegalEntities.Id
Left Join LineofBusinesses on Contracts.LineofBusinessId=LineofBusinesses.Id
Left Join Parties vendor on BlendedItems.PartyId=vendor.Id
Where Contracts.ContractType=''Lease''
And BlendedItems.IsActive=1
And LeaseBlendedItems.FundingId is  not null
And LeaseBlendedItems.PayableInvoiceOtherCostId is null
And LeaseFinances.BookingStatus!=''FullyPaidOff''
And LeaseFinances.BookingStatus!=''Inactive''
And LeaseFinances.IsCurrent=1
And LeaseFinances.IsFutureFunding=1
And BlendedItems.DueDate  Between @FromDate and @ToDate
LINEOFBUSINESSCONDITION
GROUP BY
customer.Id
,customer.PartyNumber
,customer.PartyName
,Contracts.ContractType
,Contracts.SequenceNumber
,Contracts.Id
,LegalEntities.Name
,vendor.Id
,vendor.PartyName
,BlendedItems.Type
,BlendedItems.GeneratePayableOrReceivable
,BlendedItems.Amount_Currency
,BlendedItems.DueDate
,BlendedItems.Name
UNION ALL
Select
customer.Id As PartyID
,customer.PartyNumber As CustomerNumber
,customer.PartyName As CustomerName
,Contracts.ContractType
,Contracts.SequenceNumber
,Contracts.Id As ContractId
,LegalEntities.Name As LegalEntityName
,vendor.Id As VendorId
,vendor.PartyName As PayeeName
,@FutureScheduledFunding As Type
,PayableInvoices.InvoiceTotal_Currency CurrencyName
,PayableInvoices.DueDate
,SUM(PayableInvoices.InvoiceTotal_Amount) As TotalAmount
,PayableInvoices.InvoiceNumber
,null As BlendedItemName
From PayableInvoices
Join Contracts on PayableInvoices.ContractId = Contracts.Id
Join LoanFinances on Contracts.Id = LoanFinances.ContractId
Join LoanFundings on PayableInvoices.Id = LoanFundings.FundingId
and LoanFinances.Id = LoanFundings.LoanFinanceId and LoanFundings.IsActive = 1
Join Parties customer on LoanFinances.CustomerId=customer.Id
Join LegalEntities on LoanFinances.LegalEntityId=LegalEntities.Id
Join Parties vendor on PayableInvoices.VendorId=vendor.Id
Left Join LineofBusinesses on Contracts.LineofBusinessId=LineofBusinesses.Id
Where
PayableInvoices.Status!=''InActive''
And (LoanFinances.Status=''Uncommenced'' Or LoanFinances.Status=''Commenced'' )
And LoanFinances.IsCurrent=1
And LoanFundings.Type=''FutureScheduled''
And LoanFundings.IsActive=1
And PayableInvoices.DueDate  Between @FromDate and @ToDate
LINEOFBUSINESSCONDITION
GROUP BY
customer.Id
,customer.PartyNumber
,customer.PartyName
,Contracts.ContractType
,Contracts.SequenceNumber
,Contracts.Id
,LegalEntities.Name
,vendor.Id
,vendor.PartyName
,PayableInvoices.InvoiceTotal_Currency
,PayableInvoices.DueDate
,PayableInvoices.InvoiceNumber
Union all
Select
customer.Id As PartyID
,customer.PartyNumber As CustomerNumber
,customer.PartyName As CustomerName
,Contracts.ContractType
,Contracts.SequenceNumber
,Contracts.Id As ContractId
,LegalEntities.Name As LegalEntityName
,vendor.Id As VendorId
,vendor.PartyName As PayeeName
,case When (BlendedItems.Type=''IDC'' or BlendedItems.Type=''Expense'')
And BlendedItems.GeneratePayableOrReceivable=1
Then @BlendedItemPayable
Else
@BlendedItemReceivable
End AS  Type
,BlendedItems.Amount_Currency As CurrencyName
,BlendedItems.DueDate
,SUM(BlendedItems.Amount_Amount) As TotalAmount
,null As InvoiceNumber
,BlendedItems.Name As BlendedItemName
From BlendedItems
Join LoanBlendedItems on BlendedItems.Id=LoanBlendedItems.BlendedItemId
Join LoanFinances on LoanBlendedItems.LoanFinanceId=LoanFinances.Id
Join Contracts on LoanFinances.ContractId=Contracts.Id
Join Parties customer on LoanFinances.CustomerId=customer.Id
Join LegalEntities on LoanFinances.LegalEntityId=LegalEntities.Id
Left Join LineofBusinesses on Contracts.LineofBusinessId=LineofBusinesses.Id
Left Join Parties vendor on BlendedItems.PartyId=vendor.Id
Where
BlendedItems.IsActive=1
And LoanBlendedItems.PayableInvoiceOtherCostId is null
And (LoanFinances.Status=''Uncommenced'' Or LoanFinances.Status=''Commenced'' )
And LoanFinances.IsCurrent=1
And BlendedItems.DueDate Between @FromDate and @ToDate
LINEOFBUSINESSCONDITION
GROUP BY
customer.Id
,customer.PartyNumber
,customer.PartyName
,Contracts.ContractType
,Contracts.SequenceNumber
,Contracts.Id
,LegalEntities.Name
,vendor.Id
,vendor.PartyName
,BlendedItems.Type
,BlendedItems.GeneratePayableOrReceivable
,BlendedItems.Amount_Currency
,BlendedItems.DueDate
,BlendedItems.Name
) as temp
Order by PartyID
,ContractId
,DueDate
,Type
,VendorId
,TotalAmount desc '
If(@LineOfBusinessId!=null  or @LineOfBusinessId!=0)
Set @SQL=REPLACE(@SQL,'LINEOFBUSINESSCONDITION','And Contracts.LineofBusinessId = @LineOfBusinessId')
Else
Set @SQL=REPLACE(@SQL,'LINEOFBUSINESSCONDITION','And LineOfBusinesses.PortfolioId=@CurrentPortfolioId')
EXECUTE sp_executesql @SQL,N' @LineofBusinessId BigInt
,@FromDate DateTime
,@ToDate DateTime
,@FutureScheduledFunding NVARCHAR(30)
,@BlendedItemPayable NVARCHAR(30)
,@BlendedItemReceivable NVARCHAR(30)
,@CurrentPortfolioId BigInt'
,@LineofBusinessId
,@FromDate
,@ToDate
,@FutureScheduledFunding
,@BlendedItemPayable
,@BlendedItemReceivable
,@CurrentPortfolioId
End

GO

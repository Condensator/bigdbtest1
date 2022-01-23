SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[GetCustomerDueDetailsForCustomerPortal]      
(      
 @CustomerId bigint      
)      
as      
BEGIN      
IF OBJECT_ID('tempdb..#AssumptionDetails') IS NOT NULL DROP TABLE #AssumptionDetails          
IF OBJECT_ID('tempdb..#ReceivableInvoiceDetails') IS NOT NULL DROP TABLE #ReceivableInvoiceDetails          
IF OBJECT_ID('tempdb..#ContractWithNoAssumptions') IS NOT NULL DROP TABLE #ContractWithNoAssumptions          
          
declare @CurrentDate date;          
select @CurrentDate = CurrentBusinessDate      
from BusinessUnits       
where isdefault =1      
          
create table #AssumptionDetails          
(          
 ContractId bigint,          
 AssumptionDate date,          
 IsAssumed bit          
);          
          
Create table #ReceivableInvoiceDetails          
(          
    ReceivableInvoiceId bigint,          
 InvoiceBalanceAmount decimal(16,2),          
 InvoiceCurrency nvarchar(5),          
 ReceivableDueDate date,          
 InvoiceDueDate date          
);          
          
Declare @OverDuePaymentDetails as table(OverDueAmount decimal(16,2),Currency nvarchar(5));          
Declare @NextDuePaymentDetails as table(NextDueAmount decimal(16,2),Currency nvarchar(5));          
Declare @LastPaymentDetails as table(LastPaymentAmount decimal(16,2),Currency nvarchar(5));          
          
INSERT INTO #AssumptionDetails           
(          
ContractId,          
AssumptionDate,          
IsAssumed           
)          
(          
select CAH.ContractId          
   ,MAX(A.AssumptionDate)          
   ,0          
from ContractAssumptionHistories CAH          
 join Assumptions A          
  on CAH.AssumptionId = A.Id           
  and CAH.IsActive = 1           
  and A.OriginalCustomerId = @CustomerId and A.[Status] = 'Approved'          
group by CAH.ContractId          
union all          
select CAH.ContractId          
   ,Max(A.AssumptionDate)          
   ,1          
from ContractAssumptionHistories CAH          
 join Assumptions A          
  on CAH.AssumptionId = A.Id           
  and CAH.IsActive = 1           
  and A.NewCustomerId = @CustomerId and A.[Status] = 'Approved'          
group by CAH.ContractId          
);          
          
select t.ContractId          
into #ContractWithNoAssumptions          
from          
(          
select C.Id [ContractId]          
from Contracts C          
 JOIN LeaseFinances LF          
  on LF.ContractId = C.Id and LF.IsCurrent = 1 and LF.CustomerId = @CustomerId          
UNION          
select C.Id [ContractId]          
from Contracts C          
 JOIN LoanFinances LF          
  on LF.ContractId = C.Id and LF.IsCurrent = 1 and LF.CustomerId = @CustomerId       
EXCEPT          
select ContractId          
from #AssumptionDetails          
) as t          
          
          
INSERT INTO #ReceivableInvoiceDetails          
(          
 ReceivableInvoiceId,          
 InvoiceBalanceAmount,          
 InvoiceCurrency,          
 ReceivableDueDate,          
 InvoiceDueDate          
)          
(          
SELECT RI.Id [ReceivableInvoiceId]          
  ,RID.Balance_Amount+RID.TaxBalance_Amount InvoiceBalanceAmount          
  ,RID.Balance_Currency InvoiceCurrency          
  ,R.DueDate [ReceivableDueDate]          
  ,RI.DueDate [InvoiceDueDate]          
from ReceivableInvoices RI          
 JOIN ReceivableInvoiceDetails RID          
  on RI.Id = RID.ReceivableInvoiceId          
  and RI.IsActive =1           
  and RID.IsActive = 1           
  and RID.Balance_Amount+RID.TaxBalance_Amount !=0      
  and RI.CustomerId = @CustomerId     
  and RI.IsDummy = 0  
 JOIN ReceivableDetails RD          
  on RD.Id = RID.ReceivableDetailId           
 JOIN Receivables R          
  on R.Id = RD.ReceivableId and R.IsActive = 1 and R.IsServiced = 1           
  and R.EntityType= 'CU' and R.EntityId = @CustomerId          
          
union all          
          
SELECT RI.Id [ReceivableInvoiceId]          
  ,RID.Balance_Amount+RID.TaxBalance_Amount InvoiceBalanceAmount          
  ,RID.Balance_Currency InvoiceCurrency          
  ,R.DueDate [ReceivableDueDate]          
  ,RI.DueDate [InvoiceDueDate]          
from ReceivableInvoices RI          
 JOIN ReceivableInvoiceDetails RID          
  on RI.Id = RID.ReceivableInvoiceId          
  and RI.IsActive =1           
  and RID.IsActive = 1           
  and RID.Balance_Amount+RID.TaxBalance_Amount !=0             
  and RI.CustomerId = @CustomerId    
  and RI.IsDummy = 0  
 JOIN ReceivableDetails RD          
  on RD.Id = RID.ReceivableDetailId           
 JOIN Receivables R          
  on R.Id = RD.ReceivableId and R.IsActive = 1 and R.IsServiced = 1           
    JOIN #ContractWithNoAssumptions AD          
  on AD.ContractId = R.EntityId and R.EntityType= 'CT'       
          
union all          
          
SELECT RI.Id [ReceivableInvoiceId]          
  ,RID.Balance_Amount+RID.TaxBalance_Amount InvoiceBalanceAmount          
  ,RID.Balance_Currency InvoiceCurrency          
  ,R.DueDate [ReceivableDueDate]          
  ,RI.DueDate [InvoiceDueDate]          
from ReceivableInvoices RI          
 JOIN ReceivableInvoiceDetails RID          
  on RI.Id = RID.ReceivableInvoiceId          
  and RI.IsActive =1           
  and RID.IsActive = 1           
  and RID.Balance_Amount +RID.TaxBalance_Amount!=0           
    and RI.CustomerId = @CustomerId   
 and RI.IsDummy = 0  
 JOIN ReceivableDetails RD          
  on RD.Id = RID.ReceivableDetailId           
 JOIN Receivables R          
  on R.Id = RD.ReceivableId and R.IsActive = 1 and R.IsServiced = 1 and R.PaymentScheduleID  is null          
 JOIN #AssumptionDetails AD          
  on AD.ContractId = R.EntityId and R.EntityType= 'CT'       
where ((IsAssumed =0 and R.DueDate < AssumptionDate) or (IsAssumed =1 and R.DueDate >= AssumptionDate))          
union all      
SELECT RI.Id [ReceivableInvoiceId]          
  ,RID.Balance_Amount+RID.TaxBalance_Amount InvoiceBalanceAmount          
  ,RID.Balance_Currency InvoiceCurrency          
  ,R.DueDate [ReceivableDueDate]          
  ,RI.DueDate [InvoiceDueDate]          
from ReceivableInvoices RI          
 JOIN ReceivableInvoiceDetails RID          
  on RI.Id = RID.ReceivableInvoiceId          
  and RI.IsActive =1           
  and RID.IsActive = 1           
  and RID.Balance_Amount +RID.TaxBalance_Amount!=0           
    
    and RI.CustomerId = @CustomerId   
   and RI.IsDummy = 0  
 JOIN ReceivableDetails RD          
  on RD.Id = RID.ReceivableDetailId           
 JOIN Receivables R          
  on R.Id = RD.ReceivableId and R.IsActive = 1 and R.IsServiced = 1 and R.PaymentScheduleID  is not null      
 JOIN #AssumptionDetails AD          
  on AD.ContractId = R.EntityId and R.EntityType= 'CT'       
  join LeaseFinances LF       
 on LF.ContractID = R.EntityID and LF.IsCurrent =1      
 join LeaseFinanceDetails LFD      
 on LF.Id = LFD.Id      
 JOIN LeasePaymentSchedules LPS      
 on LPS.Id = R.PaymentScheduleId and LF.Id = LPS.LeaseFinanceDetailId      
where ((IsAssumed =0 and LPS.StartDate < AssumptionDate) or (IsAssumed =1 and LPS.StartDate >= AssumptionDate))     
      
union all      
SELECT RI.Id [ReceivableInvoiceId]          
  ,RID.Balance_Amount+RID.TaxBalance_Amount InvoiceBalanceAmount          
  ,RID.Balance_Currency InvoiceCurrency          
  ,R.DueDate [ReceivableDueDate]          
  ,RI.DueDate [InvoiceDueDate]          
from ReceivableInvoices RI          
 JOIN ReceivableInvoiceDetails RID          
  on RI.Id = RID.ReceivableInvoiceId          
  and RI.IsActive =1           
  and RID.IsActive = 1           
  and RID.Balance_Amount +RID.TaxBalance_Amount!=0              
    and RI.CustomerId = @CustomerId   
   and RI.IsDummy = 0  
 JOIN ReceivableDetails RD          
  on RD.Id = RID.ReceivableDetailId           
 JOIN Receivables R          
  on R.Id = RD.ReceivableId and R.IsActive = 1 and R.IsServiced = 1 and R.PaymentScheduleID  is not null      
 JOIN #AssumptionDetails AD          
  on AD.ContractId = R.EntityId and R.EntityType= 'CT'       
  join LoanFinances LF       
 on LF.ContractID = R.EntityID and LF.IsCurrent =1      
 JOIN LoanPaymentSchedules LPS      
 on LPS.Id = R.PaymentScheduleId and LF.Id = LPS.LoanFinanceId      
where ((IsAssumed =0 and LPS.StartDate < AssumptionDate) or (IsAssumed =1 and LPS.StartDate >= AssumptionDate))        
      
)          
         
      
insert into @OverDuePaymentDetails          
(OverDueAmount,Currency)          
SELECT SUM(InvoiceBalanceAmount),InvoiceCurrency          
FROM #ReceivableInvoiceDetails          
where InvoiceDueDate <= @CurrentDate      
group by InvoiceCurrency          
          
          
insert into @NextDuePaymentDetails          
(NextDueAmount,Currency)          
SELECT SUM(InvoiceBalanceAmount),InvoiceCurrency          
FROM #ReceivableInvoiceDetails          
where InvoiceDueDate > @CurrentDate           
group by InvoiceCurrency          
          
;with receiptcte as          
(          
 Select Max(ReceiptId) [ReceiptId] ,Currency         
 from          
 (          
  select Max(Re.Id) [ReceiptId],ReCeiptAmount_Currency  [Currency]        
  from Receipts Re          
   join Contracts C          
    on Re.ContractId= C.Id and Re.EntityType = 'Lease'          
   join LeaseFinances LF          
    on LF.ContractId = C.Id and LF.IsCurrent = 1          
  where LF.CustomerId = @CustomerId and Re.Status = 'Posted' and Re.ReceivedDate <= @CurrentDate     
  group by  ReCeiptAmount_Currency    
           
  UNION ALL          
          
  select Max(Re.Id) [ReceiptId],ReCeiptAmount_Currency  [Currency]        
  from Receipts Re          
   join Contracts C          
    on Re.ContractId= C.Id and Re.EntityType = 'Loan'          
   join LoanFinances LF          
    on LF.ContractId = C.Id and LF.IsCurrent = 1          
  where LF.CustomerId = @CustomerId and Re.Status = 'Posted' and Re.ReceivedDate <= @CurrentDate          
  group by  ReCeiptAmount_Currency      
  UNION  ALL          
           
  select Max(Re.Id) [ReceiptId], ReCeiptAmount_Currency [Currency]        
  from Receipts Re           
  where Re.CustomerId = @CustomerId and Re.Status = 'Posted' and Re.ReceivedDate <= @CurrentDate          
  group by  ReCeiptAmount_Currency         
 ) as t      
 group by Currency    
)          
insert into @LastPaymentDetails          
(LastPaymentAmount,Currency)          
select R.ReceiptAmount_Amount,R.ReceiptAmount_Currency          
from Receipts R          
 join receiptcte           
  on r.Id = receiptcte.ReceiptId     
  and R.ReCeiptAmount_Currency =receiptcte.Currency        
          
          
;with FinalCte as          
(          
 select OverDueAmount          
    ,0 [NextDueAmount]          
    ,0 LastPaymentAmount           
    ,Currency           
 from @OverDuePaymentDetails          
 union all          
 select 0 OverDueAmount          
    ,[NextDueAmount]          
    ,0 LastPaymentAmount           
    ,Currency           
 from @NextDuePaymentDetails          
 union all          
 select 0 OverDueAmount          
    ,0 [NextDueAmount]          
    ,LastPaymentAmount           
    ,Currency           
 from @LastPaymentDetails          
)          
select SUM(OverDueAmount) [Overdue],          
    SUM(NextDueAmount) [NextDue],          
    SUM(LastPaymentAmount) [LastPayment],          
    Currency          
from FinalCte          
group by Currency                            
         
IF OBJECT_ID('tempdb..#AssumptionDetails') IS NOT NULL DROP TABLE #AssumptionDetails          
IF OBJECT_ID('tempdb..#ReceivableInvoiceDetails') IS NOT NULL DROP TABLE #ReceivableInvoiceDetails          
IF OBJECT_ID('tempdb..#ContractWithNoAssumptions') IS NOT NULL DROP TABLE #ContractWithNoAssumptions        
END

GO

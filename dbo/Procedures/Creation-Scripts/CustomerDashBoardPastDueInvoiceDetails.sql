SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create proc [dbo].[CustomerDashBoardPastDueInvoiceDetails]  
(  
  @CustomerId bigint   
)  
as  
BEGIN  
IF OBJECT_ID('tempdb..#AssumptionDetails') IS NOT NULL DROP TABLE #AssumptionDetails        
IF OBJECT_ID('tempdb..#ReceivableInvoiceDetails') IS NOT NULL DROP TABLE #ReceivableInvoiceDetails        
IF OBJECT_ID('tempdb..#ContractWithNoAssumptions') IS NOT NULL DROP TABLE #ContractWithNoAssumptions          
        
create table #AssumptionDetails        
(        
 ContractId bigint,        
 AssumptionDate date,        
 IsAssumed bit        
);        
        
Create table #ReceivableInvoiceDetails        
(        
    ReceivableInvoiceId bigint,      
 InvoiceTotalAmount decimal(16,2),  
 InvoiceBalanceAmount decimal(16,2),        
 InvoiceCurrency nvarchar(5),        
 ReceivableDueDate date,        
 InvoiceDueDate date,      
 EntityType nvarchar(10),      
 EntityId bigint   
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
 InvoiceTotalAmount,  
 InvoiceBalanceAmount,        
 InvoiceCurrency,        
 ReceivableDueDate,        
 InvoiceDueDate,  
 EntityType,  
 EntityId  
)        
(        
SELECT RI.Id [ReceivableInvoiceId]     
,RID.InvoiceAmount_Amount + RID.InvoiceTaxAmount_Amount InvoiceTotalAmount  
  ,RID.EffectiveBalance_Amount+RID.EffectiveTaxBalance_Amount InvoiceBalanceAmount    
  ,RID.Balance_Currency InvoiceCurrency        
  ,R.DueDate [ReceivableDueDate]        
  ,RI.DueDate [InvoiceDueDate]   
  ,R.EntityType      
  ,R.EntityId     
from ReceivableInvoices RI        
 JOIN ReceivableInvoiceDetails RID        
  on RI.Id = RID.ReceivableInvoiceId        
  and RI.IsActive =1         
  and RID.IsActive = 1         
  and RID.Balance_Amount+RID.TaxBalance_Amount !=0    
  and RI.CustomerId = @CustomerId    
 JOIN ReceivableDetails RD        
  on RD.Id = RID.ReceivableDetailId         
 JOIN Receivables R        
  on R.Id = RD.ReceivableId and R.IsActive = 1 and R.IsServiced = 1         
  and R.EntityType= 'CU' and R.EntityId = @CustomerId        
        
union all        
        
SELECT RI.Id [ReceivableInvoiceId]        
,RID.InvoiceAmount_Amount + RID.InvoiceTaxAmount_Amount InvoiceTotalAmount  
  ,RID.EffectiveBalance_Amount+RID.EffectiveTaxBalance_Amount InvoiceBalanceAmount      
  ,RID.Balance_Currency InvoiceCurrency        
  ,R.DueDate [ReceivableDueDate]        
  ,RI.DueDate [InvoiceDueDate]    
  ,R.EntityType      
  ,R.EntityId     
from ReceivableInvoices RI        
 JOIN ReceivableInvoiceDetails RID        
  on RI.Id = RID.ReceivableInvoiceId        
  and RI.IsActive =1         
  and RID.IsActive = 1         
  and RID.Balance_Amount+RID.TaxBalance_Amount !=0             
  and RI.CustomerId = @CustomerId  
 JOIN ReceivableDetails RD        
  on RD.Id = RID.ReceivableDetailId         
 JOIN Receivables R        
  on R.Id = RD.ReceivableId and R.IsActive = 1 and R.IsServiced = 1         
    JOIN #ContractWithNoAssumptions AD        
  on AD.ContractId = R.EntityId and R.EntityType= 'CT'     
        
union all        
        
SELECT RI.Id [ReceivableInvoiceId]        
 ,RID.InvoiceAmount_Amount + RID.InvoiceTaxAmount_Amount InvoiceTotalAmount  
  ,RID.EffectiveBalance_Amount+RID.EffectiveTaxBalance_Amount InvoiceBalanceAmount        
  ,RID.Balance_Currency InvoiceCurrency        
  ,R.DueDate [ReceivableDueDate]        
  ,RI.DueDate [InvoiceDueDate]   
  ,R.EntityType      
  ,R.EntityId     
from ReceivableInvoices RI        
 JOIN ReceivableInvoiceDetails RID        
  on RI.Id = RID.ReceivableInvoiceId        
  and RI.IsActive =1         
  and RID.IsActive = 1         
  and RID.Balance_Amount +RID.TaxBalance_Amount!=0           
    and RI.CustomerId = @CustomerId  
 JOIN ReceivableDetails RD        
  on RD.Id = RID.ReceivableDetailId         
 JOIN Receivables R        
  on R.Id = RD.ReceivableId and R.IsActive = 1 and R.IsServiced = 1 and R.PaymentScheduleID  is null        
 JOIN #AssumptionDetails AD        
  on AD.ContractId = R.EntityId and R.EntityType= 'CT'     
where ((IsAssumed =0 and R.DueDate < AssumptionDate) or (IsAssumed =1 and R.DueDate >= AssumptionDate))        
union all    
SELECT RI.Id [ReceivableInvoiceId]        
,RID.InvoiceAmount_Amount + RID.InvoiceTaxAmount_Amount InvoiceTotalAmount  
  ,RID.EffectiveBalance_Amount+RID.EffectiveTaxBalance_Amount InvoiceBalanceAmount       
  ,RID.Balance_Currency InvoiceCurrency        
  ,R.DueDate [ReceivableDueDate]        
  ,RI.DueDate [InvoiceDueDate]   
  ,R.EntityType      
  ,R.EntityId     
from ReceivableInvoices RI        
 JOIN ReceivableInvoiceDetails RID        
  on RI.Id = RID.ReceivableInvoiceId        
  and RI.IsActive =1         
  and RID.IsActive = 1         
  and RID.Balance_Amount +RID.TaxBalance_Amount!=0          
    and RI.CustomerId = @CustomerId  
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
  ,RID.InvoiceAmount_Amount + RID.InvoiceTaxAmount_Amount InvoiceTotalAmount  
  ,RID.EffectiveBalance_Amount+RID.EffectiveTaxBalance_Amount InvoiceBalanceAmount        
  ,RID.Balance_Currency InvoiceCurrency        
  ,R.DueDate [ReceivableDueDate]        
  ,RI.DueDate [InvoiceDueDate]  
  ,R.EntityType      
  ,R.EntityId     
from ReceivableInvoices RI        
 JOIN ReceivableInvoiceDetails RID        
  on RI.Id = RID.ReceivableInvoiceId        
  and RI.IsActive =1         
  and RID.IsActive = 1         
  and RID.Balance_Amount +RID.TaxBalance_Amount!=0            
    and RI.CustomerId = @CustomerId  
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
    
);        
     
with InvoiceDetailsCTE as  
(  
SELECT ReceivableInvoiceId  
   ,InvoiceCurrency  
   ,SUM(InvoiceTotalAmount) InvoiceTotalAmount,SUM(InvoiceBalanceAmount) InvoiceBalanceAmount  
FROM #ReceivableInvoiceDetails   
GROUP BY ReceivableInvoiceId,InvoiceCurrency  
)  
,ReceivableContractCte as  
(  
 select distinct ReceivableInvoiceId,EntityId,EntityType  
 from #ReceivableInvoiceDetails  
)  
,ContractDetails as  
(  
 select ReceivableInvoiceId  
     ,STRING_AGG(t.SequenceNumber,',') SequenceNumber  
 from  
 (  
 select ReceivableInvoiceId  
     ,STRING_AGG(C.SequenceNumber,',') WITHIN GROUP (ORDER BY C.Id) SequenceNumber  
 from ReceivableContractCte RID  
  join Contracts C  
   on C.Id = RID.EntityId and RID.EntityType = 'CT'  
 group by ReceivableInvoiceId  
 union all  
 select ReceivableInvoiceId  
     ,'' as SequenceNumber  
 from ReceivableContractCte RID  
 where RID.EntityType = 'CU'  
 ) as t  
 group by ReceivableInvoiceId  
)  
,FinalCte as
(
 select C.ReceivableInvoiceId as [Id]
   ,RI.InvoiceFile_Source [InvoiceFile_Source]
   ,RI.InvoiceFile_Type [InvoiceFile_Type] 
   ,RI.InvoiceFile_Content [InvoiceFile_Content]
   ,RI.DueDate  
   ,RI.Number [InvoiceNumber]  
   ,InvoiceTotalAmount [TotalAmount]  
   ,InvoiceBalanceAmount [TotalBalance]  
   ,InvoiceCurrency [Currency]  
   ,SequenceNumber
 from InvoiceDetailsCTE cte  
  join ReceivableInvoices RI  
   on RI.Id = cte.ReceivableInvoiceId  and RI.IsDummy = 0
  join ContractDetails C  
   on C.ReceivableInvoiceId = cte.ReceivableInvoiceId
  
 )
 select *
 FROM FinalCte
order by DueDate 
  
        
     
IF OBJECT_ID('tempdb..#AssumptionDetails') IS NOT NULL DROP TABLE #AssumptionDetails      
IF OBJECT_ID('tempdb..#ReceivableInvoiceDetails') IS NOT NULL DROP TABLE #ReceivableInvoiceDetails      
IF OBJECT_ID('tempdb..#ContractWithNoAssumptions') IS NOT NULL DROP TABLE #ContractWithNoAssumptions    
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[PopulateSundryRecurring]
(
       @EntityType NVARCHAR(30),
       @IsInvoiceSensitive bit ,
       @CreatedById BIGINT,
       @CreatedTime DATETIMEOFFSET,
       @FilterOption NVARCHAR(10),
       @AllFilterOption NVARCHAR(10),
       @OneFilterOption NVARCHAR(10),
       @CustomerId BIGINT,
       @ContractId BIGINT,
       @ProcessThroughDate DATE,  
       @JobStepInstanceId BIGINT, 
    @ValidLegalEntityIds IdList READONLY 
)AS
BEGIN
SET NOCOUNT ON
SET ANSI_WARNINGS OFF

Declare @Lease NVARCHAR(5) ='Lease';
Declare @Loan NVARCHAR(5) ='Loan';
Declare @ProgressLoan NVARCHAR(15) ='ProgressLoan';

;with cte_sundry_recurring as
(
Select 
       SR.Id SundryRecurringId,
       SR.ContractId,
       SR.CustomerId,
       SR.SundryType,
       SR.TerminationDate,
       (CASE WHEN @IsInvoiceSensitive = 1 THEN
              (CASE WHEN SR.ContractId Is Not Null AND CB.InvoiceLeaddays != 0 THEN CB.InvoiceLeaddays 
                      ELSE CU.InvoiceLeadDays END)
              ELSE 0 END) InvoiceLeadDays,
       SR.BillPastEndDate,  
       CASE WHEN C.SyndicationType <> 'None' And C.SyndicationType <> '_' AND SR.SundryType = 'PassThrough'
		THEN SR.VendorId
		ELSE NULL
		END FunderId,
       CASE WHEN C.SyndicationType Is Not Null And C.SyndicationType <> 'None' And C.SyndicationType <> '_' THEN CAST(1 As bit) ELSE CAST(0 As bit ) END IsSyndicated,
       SR.CurrencyId,
       SR.EntityType
From SundryRecurrings SR 
Join @ValidLegalEntityIds LE ON SR.LegalEntityId = LE.ID
Left Join PartyRemitToes PR ON SR.ReceivableRemitToId = PR.RemitToId
Left Join Customers CU ON SR.CustomerId = CU.Id
Left Join Contracts C ON SR.ContractId = C.Id
Left Join ContractBillings CB On C.Id = CB.Id
Where SR.IsActive = 1 AND sR.Status = 'Approved'   
       AND ((@FilterOption = @AllFilterOption AND ( @EntityType = 'Customer' OR (@EntityType=@Lease  AND C.ContractType= @Lease) OR  
                                                                                    (@EntityType=@Loan   AND (C.ContractType= @Loan OR C.ContractType= @ProgressLoan))))  
            OR ((@EntityType = 'Lease' OR @EntityType = 'Loan') AND @FilterOption = @OneFilterOption  AND C.Id = @ContractId)      
              OR (@EntityType = 'Customer' AND @FilterOption = @OneFilterOption  AND CU.Id = @CustomerId)  
              )  
)
select * 
       , CASE WHEN TerminationDate IS NOT NULL 
                                                And TerminationDate <= DATEADD(DAY, InvoiceLeadDays, @ProcessThroughDate) 
                           THEN DATEADD(Day,-1,TerminationDate)
                     ELSE DATEADD(DAY, InvoiceLeadDays,@ProcessThroughDate) 
                     END ProcessThruDate 
INTO #SundryRecurringTemp 
from cte_sundry_recurring;

Select
Distinct SR.SundryRecurringId,
SR.ContractId,
SR.CustomerId,
SR.ProcessThruDate,
SR.BillPastEndDate,
SR.FunderId,
SR.IsSyndicated,
SR.SundryType,
SR.EntityType
INTO #SundryRecurringDetails From #SundryRecurringTemp SR 
       Join SundryRecurringPaymentSchedules SRP On SR.SundryRecurringId = SRP.SundryRecurringId And SRP.IsActive = 1 
       where SR.BillPastEndDate = 1 
OR (SRP.DueDate <= SR.ProcessThruDate 
AND ( (SR.SundryType='PayableOnly' and SRP.PayableId IS NULL) OR (SR.SundryType<>'PayableOnly' AND SRP.ReceivableId IS NULL)));

       


INSERT INTO [dbo].[SundryRecurringJobExtracts]
           ([SundryRecurringId]
                 ,[FunderId]
                 ,[IsAdvance]
                 ,[IsSyndicated]
                 ,[ComputedProcessThroughDate]
                 ,[LastExtensionARUpdateRunDate]
                 ,[EntityType]
                 ,[ContractId]
                 ,[JobStepInstanceId]
           ,[CreatedById]
           ,[CreatedTime]  
           ,[IsSubmitted]
           )

Select SR.SundryRecurringId,      
       SR.FunderId,
       COALESCE(LFD.IsAdvance,LoanF.IsAdvance,CAST(0 As bit)) IsAdvance,
       SR.IsSyndicated,     
       SR.ProcessThruDate ComputedProcessThroughDate,
       LFD.LastExtensionARUpdateRunDate ,
       SR.EntityType ,
       SR.ContractId,
       @JobStepInstanceId,
       @CreatedById,
       @CreatedTime ,
       0
From #SundryRecurringDetails SR
Left Join LeaseFinances LeaseF On SR.ContractId = LeaseF.ContractId And LeaseF.IsCurrent = 1
Left Join LeaseFinanceDetails LFD On LeaseF.Id = LFD.ID
Left Join LoanFinances LoanF On SR.ContractId = LoanF.ContractId And LoanF.IsCurrent =1
Where ( @EntityType = 'Customer'
     OR (LeaseF.Id IS NOT NULL AND LeaseF.BookingStatus in ('Commenced','InstallingAssets','FullyPaidOff'))
       OR (LoanF.Id IS NOT NULL AND LoanF.Status in ('Commenced','Uncommenced','FullyPaidOff')) 
   )

INSERT INTO [dbo].[SundryRecurringLeaseOtpInfoes]
                     ([SundryRecurringId]
                     ,[MaturityDate]
                  ,[LastExtensionARUpdateRunDate]
                  ,[LastSupplementalARUpdateRunDate]
                     ,[JobStepInstanceId]
                     ,[CreatedById]
            ,[CreatedTime]
                     )
SELECT 
       SR.SundryRecurringId ,
       LFD.MaturityDate ,
       LFD.LastExtensionARUpdateRunDate ,
       LFD.LastSupplementalARUpdateRunDate ,
       @JobStepInstanceId ,
       @CreatedById ,
       @CreatedTime 
FROM #SundryRecurringDetails SR
Left Join LeaseFinances LeaseF On SR.ContractId = LeaseF.ContractId And LeaseF.IsCurrent = 1
Left Join LeaseFinanceDetails LFD On LeaseF.Id = LFD.ID
Where LeaseF.Id IS NOT NULL AND LeaseF.BookingStatus in ('Commenced','InstallingAssets')
       

IF OBJECT_ID('tempDB..#SundryRecurringTemp') IS NOT NULL
       DROP TABLE #SundryRecurringTemp

IF OBJECT_ID('tempDB..#SundryRecurringDetails') IS NOT NULL
       DROP TABLE #SundryRecurringDetails

SET NOCOUNT OFF
SET ANSI_WARNINGS ON
END

GO

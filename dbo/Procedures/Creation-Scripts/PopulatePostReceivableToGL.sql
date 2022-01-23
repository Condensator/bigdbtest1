SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

  
Create PROCEDURE [dbo].[PopulatePostReceivableToGL]  
(  
       @EntityType NVARCHAR(30),  
       @CreatedById BIGINT,  
       @CreatedTime DATETIMEOFFSET,  
       @FilterOption NVARCHAR(10),  
       @AllFilterOption NVARCHAR(10),  
       @OneFilterOption NVARCHAR(10),  
       @CustomerId BIGINT,  
       @ContractId BIGINT,  
       @ProcessThroughDate DATE,  
	   @JobRunDate DATE,  
       @JobStepInstanceId BIGINT,   
       @ValidLegalEntityIds IdList READONLY,  
       @ConsiderFiscalCalendar BIT,  
       @PostDate DATE,  
       @PostReceivable BIT,  
       @PostReceivableTax BIT,  
	   @ReceivableMinId BIGINT,  
	   @ReceivableMaxId BIGINT,
	   @ExcludeBackgroundProcessingPendingContracts BIT
)AS  
BEGIN  
SET NOCOUNT ON  
--SET ANSI_WARNINGS OFF  
  
DECLARE @True BIT  
DECLARE @False BIT  
SET @True = 1  
SET @False = 0  
  
--Local Variables---  
Declare @Lease NVARCHAR(5) ='Lease';  
Declare @LeveragedLease NVARCHAR(15) ='LeveragedLease';  
Declare @Loan NVARCHAR(5) ='Loan';  
Declare @ProgressLoan NVARCHAR(15) ='ProgressLoan';  
Declare @Discounting NVARCHAR(15) ='Discounting';  
Declare @CT NVARCHAR(5) ='CT';  
Declare @DT NVARCHAR(5) ='DT';  
Declare @Unknown NVARCHAR(5) = '_' ;  
Declare @None NVARCHAR(5) = 'None' ;  
Declare  @Customer NVARCHAR(15) ='Customer';  
Declare  @SundryRecurring NVARCHAR(15) ='SundryRecurring';  
Declare @Terminated NVARCHAR(15) ='Terminated';  
Declare @Finance NVARCHAR(15) ='Finance';  
Declare @CPUSchedule NVARCHAR(15) ='CPUSchedule';  
Declare @Inactive NVARCHAR(15) ='Inactive';  
Declare @Sundry NVARCHAR(15) ='Sundry';  
Declare @FixedTerm NVARCHAR(15) ='FixedTerm';  
Declare @CU NVARCHAR(15) ='CU';  
Declare @Commenced NVARCHAR(15) ='Commenced';  
Declare @LateFee NVARCHAR(15) ='LateFee';  
Declare @FullyPaidOff NVARCHAR(15) ='FullyPaidOff';  
Declare @AssetSaleReceivable NVARCHAR(20) ='AssetSaleReceivable';  
Declare @Approved NVARCHAR(15) ='Approved';  
Declare @SecurityDeposit NVARCHAR(15) ='SecurityDeposit';
    
SELECT LegalEntities.Id LegalEntityId  
              , LegalEntities.Name LegalEntityName  
              , MIN(FiscalEndDate) PostDate  
              , MIN(CalendarEndDate) ProcessThroughDate  
       INTO #FiscalCalendarInfo  
       FROM LegalEntities  
       JOIN BusinessCalendars ON LegalEntities.BusinessCalendarId = BusinessCalendars.Id  
       JOIN FiscalCalendars ON BusinessCalendars.Id = FiscalCalendars.BusinessCalendarId  
       WHERE FiscalCalendars.FiscalEndDate >= @JobRunDate  
       GROUP BY LegalEntities.Id , LegalEntities.Name;  
  
       CREATE TABLE #LegalEntityOpenPeriodDetails  
       (  
              LegalEntityId BIGINT,  
              LegalEntityName NVARCHAR(200),  
              FromDate DATE,  
              ToDate DATE,  
              IsPostDateValid BIT,  
              PostDate DATE,  
              ProcessThroughDate DATE  
       );  
    CREATE TABLE #PrglValidReceivables  
       (  
           ReceivableId BIGINT,
		   PostDate DATE,  
           ProcessThroughDate DATE             
       );  

	    CREATE INDEX idx_ValidReceivableId
	    ON #PrglValidReceivables (ReceivableId);

     CREATE TABLE #PrglValidReceivableTaxes  
       (  
           ReceivableId BIGINT,  
		   PostDate DATE,  
           ProcessThroughDate DATE  
       );  
  
	   CREATE INDEX idx_ValidReceivableTaxId
	   ON #PrglValidReceivableTaxes (ReceivableId);

	    CREATE TABLE #BackgroundProcessingPendingContracts (Id BIGINT)
		IF (@ExcludeBackgroundProcessingPendingContracts = 1)
		BEGIN
		INSERT INTO #BackgroundProcessingPendingContracts (Id) SELECT Id FROM Contracts CT WHERE CT.BackgroundProcessingPending = 1
		END

       IF (@ConsiderFiscalCalendar = @True)  
       BEGIN  
              INSERT INTO #LegalEntityOpenPeriodDetails  
                     SELECT fiscalCalendarInfo.LegalEntityId AS LegalEntityId  
                           , fiscalCalendarInfo.LegalEntityName AS LegalEntityName  
                           , glPeriod.FromDate AS FromDate  
                           , glPeriod.ToDate AS ToDate  
                           , IsPostDateValid = CASE WHEN (fiscalCalendarInfo.PostDate >= glPeriod.FromDate AND fiscalCalendarInfo.PostDate <= glPeriod.ToDate) THEN @True  
                                                                     ELSE @False END  
                           , fiscalCalendarInfo.PostDate AS PostDate  
                           , fiscalCalendarInfo.ProcessThroughDate AS ProcessThroughDate  
                           FROM GLFinancialOpenPeriods AS glPeriod  
                           JOIN #FiscalCalendarInfo AS fiscalCalendarInfo ON fiscalCalendarInfo.LegalEntityId = glPeriod.LegalEntityId  
      WHERE glPeriod.IsCurrent = @True;  

				----Get all the valid Receivables  
				IF (@PostReceivable = @True)  
				BEGIN  
				INSERT  INTO #PrglValidReceivables  
				Select REC.Id ReceivableId, FISC.PostDate, FISC.ProcessThroughDate 
				from Receivables REC 
				JOIN #FiscalCalendarInfo FISC ON REC.LegalEntityId = FISC.LegalEntityId 
				LEFT JOIN #BackgroundProcessingPendingContracts BPPC ON REC.EntityId = BPPC.Id AND REC.EntityType = @CT
				 Where  BPPC.Id IS NULL AND REC.IsDummy = @False and REC.DueDate <= FISC.ProcessThroughDate and REC.IsActive = 1 AND REC.IsGLPosted = 0 
				 AND ((@FilterOption = @AllFilterOption AND REC.Id BETWEEN @ReceivableMinId AND @ReceivableMaxId ) 
					OR (((@EntityType = @Lease OR @EntityType = @LeveragedLease OR @EntityType = @Loan OR @EntityType=@ProgressLoan) AND @FilterOption =@OneFilterOption  AND REC.EntityId = @ContractId AND REC.EntityType=@CT)        
							OR (@EntityType = @Customer AND @FilterOption = @OneFilterOption  AND REC.CustomerId = @CustomerId)  
							OR  @EntityType=@Discounting)) -- for discounting filter will happen at Cte_Discounting_Receivables   
				END  
  
				----Get all the valid Receivable Taxes  
      
				IF (@PostReceivableTax = @True)  
				BEGIN  
				INSERT INTO  #PrglValidReceivableTaxes  
				Select distinct REC.Id ReceivableId, FISC.PostDate, FISC.ProcessThroughDate                   
							   from Receivables REC   
					   Join ReceivableTaxes RT on  RT.ReceivableId = REC.Id   
					 Join ReceivableTaxDetails RTD on RT.Id = RTD.ReceivableTaxId AND RTD.IsActive = 1 AND  RTD.IsGLPosted = 0 
					 Join #FiscalCalendarInfo FISC ON REC.LegalEntityId = FISC.LegalEntityId 
					 Left Join #BackgroundProcessingPendingContracts BPPC ON REC.EntityId = BPPC.Id AND REC.EntityType = @CT
					   Where BPPC.Id IS NULL AND REC.IsDummy = @False and REC.DueDate <= FISC.ProcessThroughDate AND ((@FilterOption = @AllFilterOption AND REC.Id BETWEEN @ReceivableMinId AND @ReceivableMaxId ) OR 
	   
					   (((@EntityType = @Lease OR @EntityType = @LeveragedLease OR @EntityType = @Loan OR @EntityType=@ProgressLoan) AND @FilterOption =@OneFilterOption  AND REC.EntityId = @ContractId AND REC.EntityType=@CT)        
														OR (@EntityType = @Customer AND @FilterOption = @OneFilterOption  AND REC.CustomerId = @CustomerId)  
														OR  @EntityType=@Discounting))  
				END  
       END  
       ELSE  
       BEGIN  
              INSERT INTO #LegalEntityOpenPeriodDetails  
                     SELECT legalEntity.Id AS LegalEntityId  
                           , legalEntity.Name AS LegalEntityName  
                           , glPeriod.FromDate AS FromDate  
                           , glPeriod.ToDate AS ToDate  
                           , IsPostDateValid = CASE WHEN (@PostDate >= glPeriod.FromDate AND @PostDate <= glPeriod.ToDate) THEN @True  
                                                                     ELSE @False END  
                           , @PostDate AS PostDate  
                           , @ProcessThroughDate AS ProcessThroughDate  
                           FROM LegalEntities AS legalEntity  
                           JOIN GLFinancialOpenPeriods AS glPeriod ON glPeriod.LegalEntityId = legalEntity.Id  
                           WHERE glPeriod.IsCurrent = @True;  
				----Get all the valid Receivables  
  
     
				IF (@PostReceivable = @True)  
				BEGIN  
				INSERT  INTO #PrglValidReceivables  
				Select REC.Id ReceivableId, @PostDate, @ProcessThroughDate 
				from Receivables REC       
				Left Join #BackgroundProcessingPendingContracts BPPC ON REC.EntityId = BPPC.Id AND REC.EntityType = @CT
				 Where  BPPC.Id IS NULL AND REC.IsDummy = @False and REC.DueDate <= @ProcessThroughDate and REC.IsActive = 1 AND REC.IsGLPosted = 0 AND ((@FilterOption = @AllFilterOption AND REC.Id BETWEEN @ReceivableMinId AND @ReceivableMaxId ) OR 

				 (((@EntityType = @Lease OR @EntityType = @LeveragedLease OR @EntityType = @Loan OR @EntityType=@ProgressLoan) AND @FilterOption =@OneFilterOption  AND REC.EntityId = @ContractId AND REC.EntityType=@CT)        
														OR (@EntityType = @Customer AND @FilterOption = @OneFilterOption  AND REC.CustomerId = @CustomerId)  
														OR  @EntityType=@Discounting)) -- for discounting filter will happen at Cte_Discounting_Receivables   
				END  
  
				----Get all the valid Receivable Taxes  
      
				IF (@PostReceivableTax = @True)  
				BEGIN  
				INSERT INTO  #PrglValidReceivableTaxes  
				Select distinct REC.Id ReceivableId, @PostDate, @ProcessThroughDate                
							   from Receivables REC  
					   Join ReceivableTaxes RT on  RT.ReceivableId = REC.Id   
					 Join ReceivableTaxDetails RTD on RT.Id = RTD.ReceivableTaxId AND RTD.IsActive = 1 AND  RTD.IsGLPosted = 0   
					 Left Join #BackgroundProcessingPendingContracts BPPC ON REC.EntityId = BPPC.Id AND REC.EntityType = @CT
					   Where BPPC.Id IS NULL AND REC.IsDummy = @False and REC.DueDate <= @ProcessThroughDate AND ((@FilterOption = @AllFilterOption AND REC.Id BETWEEN @ReceivableMinId AND @ReceivableMaxId ) OR 
	   
					   (((@EntityType = @Lease OR @EntityType = @LeveragedLease OR @EntityType = @Loan OR @EntityType=@ProgressLoan) AND @FilterOption =@OneFilterOption  AND REC.EntityId = @ContractId AND REC.EntityType=@CT)        
														OR (@EntityType = @Customer AND @FilterOption = @OneFilterOption  AND REC.CustomerId = @CustomerId)  
														OR  @EntityType=@Discounting))  
				END  
       END  
  
    Select REC.Id ReceivableId  
              ,REC.ReceivableCodeId          
              ,REC.EntityType  
              ,REC.EntityId  
              ,REC.DueDate  
              ,REC.CustomerId           
               ,REC.FunderId  
              ,REC.LegalEntityId          
              ,REC.Id GLSourceId  
              ,REC.IncomeType  
              ,REC.TotalAmount_Amount            
               ,REC.TotalAmount_Currency Currency  
              ,REC.SourceId  
              ,REC.SourceTable  
              ,REC.IsDSL  
              ,REC.PaymentScheduleId  
              ,REC.IsGLPosted IsReceivableGlPosted  
     ,REC.IsCollected  
     ,RT.IsGLPosted IsTaxGlPosted  
              ,RT.Id ReceivableTaxId  
              ,RT.GLTemplateId TaxGlTemplateId        
               ,RT.IsCashBased   
      ,CASE WHEN REC.IsActive=1 and REC.IsGLPosted=0 THEN @True  
                        ELSE @False END IsReceivableValid  
      ,CASE WHEN RT.Id is not null THEN @True   
      ELSE @False END IsReceivableTaxValid     
           ,RCO.Name ReceivableCode  
              ,RCO.AccountingTreatment   
     ,GLTT.Name GLTransactionType  
              ,SGLTT.Name SyndicationGLTransactionType  
                      ,RGLT.Name ReceivableGlTransactionType  
              ,GT.Id GLTemplateId  
              ,SGT.Id SyndicationGLTemplateId  
     ,CT.ContractType   
               ,CT.Id ContractId           
               ,CT.SyndicationType         
              ,CASE WHEN CT.ChargeOffStatus <> @Unknown THEN @True ELSE @False END IsChargedOffContract          
              ,PT.IsIntercompany  
              ,CT.DealProductTypeId  
			  ,VALID_REC.PostDate
			  ,VALID_REC.ProcessThroughDate
     INTO #PRGLReceivables    
     From   
     ((select * from #PrglValidReceivables)  
   UNION   
    (Select * from #PrglValidReceivableTaxes)) As VALID_REC  
    join Receivables REC on VALID_REC.ReceivableId = REC.Id  
    left Join ReceivableTaxes RT on  RT.ReceivableId = REC.Id AND  RT.IsActive =1  
    Join LegalEntities LE on REC.LegalEntityId = LE.Id  
       Join @ValidLegalEntityIds VLE ON VLE.ID = LE.ID   
       Join ReceivableCodes RCO on REC.ReceivableCodeId = RCO.Id  
       Join ReceivableTypes REC_TYPE on RCO.ReceivableTypeId = REC_TYPE.Id  
       Join GLTemplates GT on RCO.GLTemplateId = GT.Id  
       Join GLTransactionTypes GLTT on GT.GLTransactionTypeId = GLTT.Id   
       Join Parties PT on REC.CustomerId = PT.Id      
          join GLTransactionTypes RGLT on REC_TYPE.GLTransactionTypeId = RGLT.Id  
       Left Join GLTemplates SGT on RCO.SyndicationGLTemplateId = SGT.Id  
       Left Join GLTransactionTypes SGLTT on SGT.GLTransactionTypeId = SGLTT.Id  
       Left Join Contracts CT on  REC.EntityId = CT.Id  and REC.EntityType = @CT  
    WHERE ( (@EntityType=@Customer)  
                     or ((@EntityType=@Lease OR @EntityType = @LeveragedLease or @EntityType=@Loan or @EntityType=@ProgressLoan) AND REC.EntityType=@CT )  
                        or (@EntityType=@Discounting and REC.EntityType=@DT)                         
                   )  
              and ( ((@FilterOption = @AllFilterOption AND REC.Id BETWEEN @ReceivableMinId AND @ReceivableMaxId AND ((@EntityType=@Lease  AND           CT.ContractType= @Lease) OR  
                                               (@EntityType=@Loan   AND CT.ContractType= @Loan)  OR  
                                               (@EntityType=@Loan   AND CT.ContractType= @ProgressLoan) OR  
                                               (@EntityType=@LeveragedLease   AND CT.ContractType= @LeveragedLease) OR  
                                               @EntityType=@Customer  )))  
                    OR ((@EntityType = @Lease OR @EntityType = @LeveragedLease OR @EntityType = @Loan OR @EntityType=@ProgressLoan) AND @FilterOption =@OneFilterOption  AND REC.EntityId = @ContractId AND REC.EntityType=@CT)        
                                        OR (@EntityType = @Customer AND @FilterOption = @OneFilterOption  AND REC.CustomerId = @CustomerId)  
                                        OR  @EntityType=@Discounting -- for discounting filter will happen at Cte_Discounting_Receivables   
                     )  
            and (CT.Id is Null or CT.Status <> @Terminated)   
  
        
  
CREATE INDEX idx_ReceivableId  
ON #PRGLReceivables (ReceivableId);  
  
CREATE INDEX idx_PaymentScheduleId  
ON #PRGLReceivables (PaymentScheduleId);  
  
CREATE INDEX idx_EntityId  
ON #PRGLReceivables (EntityId);  
  
CREATE INDEX idx_SourceId  
ON #PRGLReceivables (SourceId);  
  
CREATE INDEX idx_ReceivableTaxId  
ON #PRGLReceivables (ReceivableTaxId);  
  
  
  
------Get Tax Summary  
CREATE TABLE #ReceivableTaxSummary  
(  
       ReceivableTaxId BIGINT,  
       ReceivableId BIGINT,  
       Amount DECIMAL(16,2),  
       Balance DECIMAL(16,2),  
       TaxCurrencyCode NVARCHAR(6),  
       TaxGlTemplateId BIGINT,  
       IsCashBased BIT,  
       IsGLPosted BIT,  
       IsReceivableTaxValid BIT  
);  
  
IF (@PostReceivableTax = @True)  
BEGIN  
INSERT INTO #ReceivableTaxSummary(ReceivableTaxId, ReceivableId, Amount, Balance, TaxCurrencyCode, TaxGlTemplateId, IsCashBased, IsGLPosted, IsReceivableTaxValid)  
Select REC.ReceivableTaxId,REC.ReceivableId,SUM(RTIM.Amount_Amount) Amount, SUM(RTIM.Balance_Amount) Balance,RTIM.Cost_Currency TaxCurrencyCode, REC.TaxGlTemplateId, REC.IsCashBased, REC.IsTaxGlPosted,REC.IsReceivableTaxValid   
from #PrglReceivables REC   
join ReceivableTaxDetails RTIM on REC.ReceivableTaxId = RTIM.ReceivableTaxId and RTIM.IsActive = @True and RTIM.IsGlPosted = 0  
Group by REC.ReceivableTaxId,REC.ReceivableId,REC.TaxGlTemplateId,RTIM.Cost_Currency,REC.IsCashBased,REC.IsTaxGLPosted,REC.IsReceivableTaxValid;  
END  
  
;with Cte_Finance_Receivables AS  
  (  
  Select RECD.ReceivableId,SUM(RECD.NonLeaseComponentAmount_Amount) FinancingAmount,SUM(RECD.NonLeaseComponentBalance_Amount) FinancingBalance 
  from #PrglReceivables REC Join ReceivableDetails RECD on REC.ReceivableId = RECD.ReceivableId AND REC.IsReceivableGlPosted = 0
       Where  REC.PaymentScheduleId  is not null
              and REC.PaymentScheduleId != 0
              and REC.SourceTable != @SundryRecurring
              and REC.SourceTable != @CPUSchedule 
               Group By RECD.ReceivableId  
  )  
    
  --- Get Lease Receivables with Payment Schedules    
  select REC.ReceivableId ReceivableId  
        ,LF.ContractId  
              ,LF.InstrumentTypeId LeaseInstrumentTypeId  
              ,LFD.LeaseBookingGLTemplateId  
              ,LFD.InterimInterestIncomeGLTemplateId LeaseInterimInterestIncomeGLTemplateId  
              ,LFD.InterimRentIncomeGLTemplateId LeaseInterimRentIncomeGLTemplateId  
              ,LF.BranchId  
              ,LF.CostCenterId LeaseCostCenterId  
              ,LF.LineofBusinessId  
              ,LF.AcquisitionId  
              ,CASE WHEN CFREC.ReceivableId is not null THEN CFREC.FinancingAmount ELSE @False END  FinancingAmount  
              ,CASE WHEN CFREC.ReceivableId is not null THEN CFREC.FinancingBalance ELSE @False END  FinancingBalance  
              INTO #PrglLeaseReceivablesWithPaymentSchedule  
              from #PrglReceivables REC join LeasePaymentSchedules LEPS on REC.PaymentScheduleId = LEPS.Id and REC.EntityType=@CT and REC.IsReceivableGlPosted = 0  
  Join LeaseFinanceDetails LFD on LEPS.LeaseFinanceDetailId = LFD.Id  
  Join LeaseFinances LF on LFD.Id = LF.Id  
  Join Contracts CT on LF.ContractId = CT.Id    
  Left Join Cte_Finance_Receivables CFREC on REC.ReceivableId = CFREC.ReceivableId  
  where  REC.ContractId = LF.ContractId  
        and CT.ContractType = @Lease  
              and (@EntityType=@Lease or @EntityType=@Customer)  
        and REC.PaymentScheduleId  is not null  
        and REC.PaymentScheduleId != 0  
        and REC.SourceTable != @SundryRecurring  
        and REC.SourceTable != @CPUSchedule  
        and (REC.IncomeType = @FixedTerm and (CT.Status = @Commenced or CT.Status = @FullyPaidOff)  
             or (REC.IncomeType != @FixedTerm and CT.Status != @Terminated));  
  
--- Get Lease Receivables without Payment Schedules  
  
select REC.ReceivableId ReceivableId  
        ,LF.ContractId  
              ,LF.InstrumentTypeId LeaseInstrumentTypeId  
              ,LFD.LeaseBookingGLTemplateId  
              ,LFD.InterimInterestIncomeGLTemplateId LeaseInterimInterestIncomeGLTemplateId  
              ,LFD.InterimRentIncomeGLTemplateId LeaseInterimRentIncomeGLTemplateId  
              ,LF.BranchId  
              ,LF.CostCenterId LeaseCostCenterId  
              ,LF.LineofBusinessId  
              ,0  FinancingAmount  
              ,0  FinancingBalance  
              ,LF.AcquisitionId  
              INTO #PrglLeaseReceivablesWithoutPaymentSchedule  
              from #PrglReceivables REC   Join Contracts CT on REC.ContractId = CT.Id and REC.EntityType = @CT and REC.IsReceivableGlPosted = 0  
              Join LeaseFinances LF on LF.ContractId = CT.Id and LF.IsCurrent = 1  
              Join LeaseFinanceDetails LFD on LF.Id = LFD.Id           
              where REC.ContractId = LF.ContractId  
                     and CT.ContractType = @Lease  
                     and (@EntityType=@Lease or @EntityType=@Customer)  
                     and(    REC.PaymentScheduleId is null  
                                  or REC.PaymentScheduleId = 0  
                                  or REC.SourceTable = @SundryRecurring  
                                  or REC.SourceTable = @CPUSchedule  
                           );  
  
-----------------Get Lease Receivables for Tax  
select REC.ReceivableId ReceivableId  
        ,LF.ContractId  
              ,LF.InstrumentTypeId LeaseInstrumentTypeId  
              ,LFD.LeaseBookingGLTemplateId  
              ,LFD.InterimInterestIncomeGLTemplateId LeaseInterimInterestIncomeGLTemplateId  
              ,LFD.InterimRentIncomeGLTemplateId LeaseInterimRentIncomeGLTemplateId  
              ,LF.BranchId  
              ,LF.CostCenterId LeaseCostCenterId  
              ,LF.LineofBusinessId  
              ,0  FinancingAmount  
              ,0  FinancingBalance  
              ,LF.AcquisitionId  
              INTO #PrglLeaseReceivablesForTax  
              from #PrglReceivables REC   Join Contracts CT on REC.ContractId = CT.Id and REC.EntityType = @CT  
              Join #ReceivableTaxSummary RTXS on REC.ReceivableId = RTXS.ReceivableId    and RTXS.IsReceivableTaxValid = @True   
              Join LeaseFinances LF on LF.ContractId = CT.Id and LF.IsCurrent = 1  
              Join LeaseFinanceDetails LFD on LF.Id = LFD.Id  
              where REC.ContractId = LF.ContractId  
                     and CT.ContractType = @Lease  
                     and (@EntityType=@Lease or @EntityType=@Customer)  
                
                       
  
---------- Get Loan Receivables with Payment Schedules  
select REC.ReceivableId ReceivableId  
        ,LF.ContractId  
              ,LF.InstrumentTypeId LoanInstrumentTypeId  
              ,LF.LoanBookingGLTemplateId  
              ,LF.LoanIncomeRecognitionGLTemplateId LoanIncomeRecognitionGLTemplateId  
              ,LF.InterimIncomeRecognitionGLTemplateId LoanInterimIncomeRecognitionGLTemplateId  
              ,LF.CommencementDate  
              ,LF.BranchId  
              ,LF.CostCenterId LoanCostCenterId  
              ,LF.LineofBusinessId  
              ,LF.AcquisitionId  
              INTO #PrglLoanReceivablesWithPaymentSchedule  
              from #PrglReceivables REC  Join  Contracts CT on REC.ContractId = CT.Id and REC.EntityType = @CT and REC.IsReceivableGlPosted = 0  
              join LoanPaymentSchedules LOPS on REC.PaymentScheduleId = LOPS.Id  
  Join LoanFinances LF on LF.Id = LOPS.LoanFinanceId    
  where (CT.ContractType = @Loan or CT.ContractType = @ProgressLoan)  
        and (@EntityType=@Loan or @EntityType=@ProgressLoan or @EntityType=@Customer)  
        and REC.PaymentScheduleId  is not null  
        and REC.PaymentScheduleId != 0  
        and REC.SourceTable != @SundryRecurring   ;  
                
  
----- Get Loan Receivables without Payment Schedules  
select REC.ReceivableId ReceivableId  
        ,LF.ContractId  
              ,LF.InstrumentTypeId LoanInstrumentTypeId  
              ,LF.LoanBookingGLTemplateId  
              ,LF.LoanIncomeRecognitionGLTemplateId   
              ,LF.InterimIncomeRecognitionGLTemplateId LoanInterimIncomeRecognitionGLTemplateId  
              ,LF.CommencementDate  
              ,LF.BranchId  
              ,LF.CostCenterId LoanCostCenterId  
              ,LF.LineofBusinessId  
              ,LF.AcquisitionId  
              Into #PrglLoanReceivablesWithoutPaymentSchedule  
              from #PrglReceivables REC Join  Contracts CT on REC.ContractId = CT.Id and REC.EntityType = @CT and REC.IsReceivableGlPosted = 0  
  Join LoanFinances LF on LF.ContractId = CT.Id and LF.IsCurrent=1  
  where   (CT.ContractType = @Loan or CT.ContractType = @ProgressLoan)  
   and (@EntityType=@Loan or @EntityType=@ProgressLoan or @EntityType=@Customer)  
        and ( REC.PaymentScheduleId is null  
                       Or REC.PaymentScheduleId = 0  
                       Or REC.SourceTable = @SundryRecurring      ) ;  
  
----- Get Loan Receivables for taxes  
select REC.ReceivableId ReceivableId  
        ,LF.ContractId  
              ,LF.InstrumentTypeId LoanInstrumentTypeId  
              ,LF.LoanBookingGLTemplateId  
              ,LF.LoanIncomeRecognitionGLTemplateId   
              ,LF.InterimIncomeRecognitionGLTemplateId LoanInterimIncomeRecognitionGLTemplateId  
              ,LF.CommencementDate  
              ,LF.BranchId  
              ,LF.CostCenterId LoanCostCenterId  
              ,LF.LineofBusinessId  
              ,LF.AcquisitionId  
              Into #PrglLoanReceivablesForTax  
              from #PrglReceivables REC Join  Contracts CT on REC.ContractId = CT.Id and REC.EntityType = @CT  
              Join #ReceivableTaxSummary RTXS on REC.ReceivableId = RTXS.ReceivableId    and RTXS.IsReceivableTaxValid = @True   
  Join LoanFinances LF on LF.ContractId = CT.Id and LF.IsCurrent=1  
  where   (CT.ContractType = @Loan or CT.ContractType = @ProgressLoan)  
   and (@EntityType=@Loan or @EntityType=@ProgressLoan or @EntityType=@Customer)  
  
  -- Prepaid Receivables  
;with Cte_Prepaid_Recv AS  
  ( Select PRP.ReceivableId ,SUM(PRP.PrePaidAmount_Amount) PrepaidAmount , SUM(PRP.FinancingPrePaidAmount_Amount) FinancingPrepaidAmount  
    From PrepaidReceivables PRP  Where PRP.IsActive = 1  
       Group By PRP.ReceivableId  
      
  ),  
  Cte_Discounting_Receivables AS  
  (  
  select REC.ReceivableId ReceivableId  
        ,DC.Id DiscountingId  
              ,DC.SequenceNumber  
              ,DF.DiscountingGLTemplateId DiscountingBookingGLTemplateId  
              ,DF.InstrumentTypeId DiscountingInstrumentTypeId  
              ,DF.CostCenterId DiscountingCostCenterId  
              ,DF.LineOfBusinessId DiscountingLineOfBusinessId  
              ,DF.CommencementDate  
              ,DF.BranchId  
              from #PrglReceivables REC Join  Discountings DC on REC.EntityId = DC.Id and REC.EntityType=@DT   
  Join DiscountingFinances DF on DF.DiscountingId = DC.Id   
  where DF.IsCurrent=1 and  DF.BookingStatus != @Inactive  
          and (  @FilterOption = @AllFilterOption   
                       OR (@EntityType=@Discounting AND @FilterOption = @OneFilterOption  AND DC.Id = @ContractId)  
        OR (@EntityType=@Customer AND @FilterOption = @OneFilterOption AND REC.CustomerId = @CustomerId)  
                     )  
  )  
   ,Cte_Cpu_Receivables AS  
  (  
  select REC.ReceivableId ReceivableId  
        ,CPF.Id CPUFinanceId  
              ,CPC.SequenceNumber  
              ,CPA.InstrumentTypeId  
              ,CPA.CostCenterId  
              ,CPA.LineofBusinessId  
              ,CPF.CommencementDate               
              ,CPA.BranchId                
              from #PrglReceivables REC Join  CPUSchedules CPS on REC.SourceId = CPS.Id and REC.SourceTable = @CPUSchedule and REC.EntityType = @CU   
              Join CPUFinances CPF on CPF.Id = CPS.CPUFinanceId  
              Join CPUContracts CPC on CPC.CPUFinanceId = CPF.Id  
              join CPUAccountings CPA on CPA.Id = CPF.Id  
              Where CPC.Status!=@Inactive and @EntityType=@Customer  
  ),  
  Cte_Blended_Receivables AS(  
   select REC.ReceivableId ReceivableId,  
   BITM.Id BlendedItemId,  
   BITM.IsFAS91,  
   BITM.BookingGLTemplateId,  
   ROW_NUMBER() OVER (Partition by ReceivableId Order by BITD.BlendedItemId desc) as RowNum  
   from #PrglReceivables REC Join BlendedItemDetails BITD on REC.SourceId = BITD.SundryId and BITD.SundryId is not null   
   join BlendedItems BITM  on BITD.BlendedItemId = BITM.Id  
   where REC.SourceTable=@Sundry  
   ),  
   Cte_DR_Receivables AS(  
   select REC.ReceivableId ReceivableId,  
   DRS.APGLTemplateId  
   from #PrglReceivables REC Join DisbursementRequests DRS on REC.SourceId = DRS.SundryId and DRS.SundryId is not null and REC.IsReceivableGlPosted = 0  
   where REC.SourceTable=@Sundry  
   ),  
   Cte_PY_Receivables AS(  
   select REC.ReceivableId ReceivableId,  
   PV.APGLTemplateId  
   from #PrglReceivables REC Join PaymentVoucherInfoes PV on REC.SourceId = PV.SundryId and PV.SundryId is not null and REC.IsReceivableGlPosted = 0  
   where REC.SourceTable=@Sundry  
   )  
     
   INSERT INTO [PostReceivableToGLJob_Extracts]  
           ([ReceivableId]  
           ,[ReceivableCode]  
           ,[AccountingTreatment]  
           ,[EntityType]  
           ,[DueDate]  
           ,[CustomerId]  
           ,[GLTransactionType]  
           ,[SyndicationGLTransactionType]  
           ,[GLTemplateId]  
           ,[SyndicationGLTemplateId]  
           ,[FunderId]  
           ,[LegalEntityId]  
           ,[IncomeType]  
           ,[TotalAmount]  
           ,[PrepaidAmount]  
           ,[FinancingPrepaidAmount]  
           ,[FinancingTotalAmount]  
           ,[Currency]  
           ,[ContractType]  
           ,[ContractId]  
           ,[DiscountingId]  
           ,[CommencementDate]  
           ,[IsChargedOffContract]  
           ,[InstrumentTypeId]  
           ,[BookingGLTemplateId]  
           ,[CostCenterId]  
           ,[LineOfBusinessId]  
           ,[IsIntercompany]  
           ,[IsDSL]  
         ,[IsSundryBlendedItemFAS91]  
           ,[AcquisitionID]  
           ,[DealProductTypeId]  
           ,[BranchId]  
           ,[APGLTemplateId]  
           ,[SundryBlendedItemBookingGlTemplateId]  
           ,[LeaseInterimInterestIncomeGLTemplateId]  
           ,[LeaseInterimRentIncomeGLTemplateId]  
           ,[LoanIncomeRecognitionGLTemplateId]  
           ,[LoanInterimIncomeRecognitionGLTemplateId]  
           ,[ReceivableTaxId]  
           ,[TaxTotalAmount]   
           ,[TaxBalanceAmount]   
           ,[TaxCurrencyCode]   
           ,[TaxGlTemplateId]   
           ,[SecurityDepositId]  
           ,[ReceivableForTransferId]  
           ,[ReceivableForTransferType]  
           ,[StartDate]   
           ,[IsContractSyndicated]            
           ,[IsCashBased]  
           ,[IsReceivableValid]  
           ,[IsReceivableTaxValid]  
           ,[BlendedItemId]  
		,[IsVendorOwned]  
           ,[PostDate]  
           ,[ProcessThroughDate]  
           ,[JobStepInstanceId]  
           ,[IsSubmitted]  
		,[ReceivableIsCollected]  
		,[ReceivableGlTransactionType]               
           ,[IsTiedToDiscounting]            
          )  
       
Select PREC.ReceivableId,  
PREC.ReceivableCode,  
PREC.AccountingTreatment,  
PREC.EntityType,  
PREC.DueDate,  
PREC.CustomerId,  
PREC.GLTransactionType,  
PREC.SyndicationGLTransactionType,  
PREC.GLTemplateId,  
PREC.SyndicationGLTemplateId,  
PREC.FunderId,  
PREC.LegalEntityId,  
PREC.IncomeType,  
CASE WHEN LRWPS.ReceivableId  is not null and LRWPS.FinancingAmount is not null THEN PREC.TotalAmount_Amount - LRWPS.FinancingAmount ELSE PREC.TotalAmount_Amount END TotalAmount,  
CASE WHEN PRPREC.ReceivableId is not null and PRPREC.PrepaidAmount is not null  THEN PRPREC.PrepaidAmount ELSE @False END PrepaidAmount,  
CASE WHEN PRPREC.ReceivableId is not null and PRPREC.FinancingPrepaidAmount is not null THEN PRPREC.FinancingPrepaidAmount ELSE @False END FinancingPrepaidAmount,  
CASE WHEN LRWPS.ReceivableId  is not null and LRWPS.FinancingAmount is not null THEN LRWPS.FinancingAmount ELSE @False END  FinancingTotalAmount,  
PREC.Currency,  
PREC.ContractType,  
PREC.ContractId,  
DR.DiscountingId,  
CASE  WHEN LORWPS.ReceivableId  is not null THEN LORWPS.CommencementDate  
         WHEN LORWTPS.ReceivableId  is not null THEN LORWTPS.CommencementDate  
         WHEN LORFT.ReceivableId is not null THEN LORFT.CommencementDate  
         WHEN DR.ReceivableId  is not null THEN DR.CommencementDate  
         WHEN CR.ReceivableId  is not null THEN CR.CommencementDate  
         WHEN LVR.Id is not null THEN LVR.CommencementDate  
         ELSE NULL   
         END CommencementDate,  
PREC.IsChargedOffContract,  
Case WHEN LRWPS.ReceivableId  is not null THEN LRWPS.LeaseInstrumentTypeId  
     WHEN LRWTPS.ReceivableId is not null THEN LRWTPS.LeaseInstrumentTypeId  
       WHEN LORWPS.ReceivableId is not null THEN LORWPS.LoanInstrumentTypeId  
       WHEN LORWTPS.ReceivableId is not null THEN LORWTPS.LoanInstrumentTypeId  
       WHEN LRFT.ReceivableId is not null THEN LRFT.LeaseInstrumentTypeId  
       WHEN LORFT.ReceivableId is not null THEN LORFT.LoanInstrumentTypeId  
       WHEN DR.ReceivableId is not null THEN DR.DiscountingInstrumentTypeId  
       WHEN CR.ReceivableId is not null THEN CR.InstrumentTypeId  
       WHEN LVR.Id is not null THEN LVR.InstrumentTypeId  
       WHEN LFR.Id is not null THEN LFR.InstrumentTypeId  
       WHEN ASL.Id is not null THEN ASL.InstrumentTypeId  
       WHEN SR.Id is not null THEN SR.InstrumentTypeId  
       WHEN SREC.Id is not null THEN SREC.InstrumentTypeId  
       WHEN SEDP.Id is not null THEN SEDP.InstrumentTypeId  
       ELSE NULL  
       END InstrumentTypeId,  
  
Case WHEN LRWPS.ReceivableId  is not null THEN LRWPS.LeaseBookingGLTemplateId  
     WHEN LRWTPS.ReceivableId is not null THEN LRWTPS.LeaseBookingGLTemplateId  
       WHEN LORWPS.ReceivableId is not null THEN LORWPS.LoanBookingGLTemplateId  
       WHEN LORWTPS.ReceivableId is not null THEN LORWTPS.LoanBookingGLTemplateId  
       WHEN LRFT.ReceivableId is not null THEN LRFT.LeaseBookingGLTemplateId  
       WHEN LORFT.ReceivableId is not null THEN LORFT.LoanBookingGLTemplateId  
       WHEN DR.ReceivableId is not null THEN DR.DiscountingBookingGLTemplateId  
       WHEN LVR.Id is not null THEN LVR.BookingGLTemplateId    
       ELSE NULL  
       END BookingGLTemplateId,  
Case WHEN LRWPS.ReceivableId  is not null THEN LRWPS.LeaseCostCenterId  
     WHEN LRWTPS.ReceivableId is not null THEN LRWTPS.LeaseCostCenterId  
       WHEN LORWPS.ReceivableId is not null THEN LORWPS.LoanCostCenterId  
       WHEN LORWTPS.ReceivableId is not null THEN LORWTPS.LoanCostCenterId  
       WHEN LRFT.ReceivableId is not null THEN LRFT.LeaseCostCenterId  
       WHEN LORFT.ReceivableId is not null THEN LORFT.LoanCostCenterId  
       WHEN DR.ReceivableId is not null THEN DR.DiscountingCostCenterId  
       WHEN CR.ReceivableId is not null THEN CR.CostCenterId  
       WHEN LVR.Id is not null THEN LVR.CostCenterId  
       WHEN LFR.Id is not null THEN LFR.CostCenterId  
       WHEN ASL.Id is not null THEN ASL.CostCenterId  
       WHEN SR.Id is not null THEN SR.CostCenterId  
       WHEN SREC.Id is not null THEN SREC.CostCenterId  
       WHEN SEDP.Id is not null THEN SEDP.CostCenterId  
       ELSE NULL  
       END CostCenterId,  
Case WHEN LRWPS.ReceivableId  is not null THEN LRWPS.LineofBusinessId  
     WHEN LRWTPS.ReceivableId is not null THEN LRWTPS.LineofBusinessId  
       WHEN LORWPS.ReceivableId is not null THEN LORWPS.LineofBusinessId  
       WHEN LORWTPS.ReceivableId is not null THEN LORWTPS.LineofBusinessId  
       WHEN LORFT.ReceivableId is not null THEN LORFT.LineofBusinessId  
       WHEN LRFT.ReceivableId is not null THEN LRFT.LineofBusinessId  
       WHEN DR.ReceivableId is not null THEN DR.DiscountingLineOfBusinessId  
       WHEN CR.ReceivableId is not null THEN CR.LineOfBusinessId  
       WHEN LVR.Id is not null THEN LVR.LineOfBusinessId  
       WHEN LFR.Id is not null THEN LFR.LineOfBusinessId  
       WHEN ASL.Id is not null THEN ASL.LineOfBusinessId  
       WHEN SR.Id is not null THEN SR.LineOfBusinessId  
       WHEN SREC.Id is not null THEN SREC.LineOfBusinessId  
       WHEN SEDP.Id is not null THEN SEDP.LineofBusinessId  
       ELSE NULL  
       END LineOfBusinessId,  
PREC.IsInterCompany,  
PREC.IsDSL,  
Case WHEN CBIR.ReceivableId is not null THEN CBIR.IsFAS91 ELSE @False END IsSundryBlendedItemFAS91,  
Case WHEN LRWPS.ReceivableId  is not null THEN LRWPS.AcquisitionId  
     WHEN LRWTPS.ReceivableId is not null THEN LRWTPS.AcquisitionId  
       WHEN LORWPS.ReceivableId is not null THEN LORWPS.AcquisitionId  
       WHEN LORWTPS.ReceivableId is not null THEN LORWTPS.AcquisitionId  
     WHEN LRFT.ReceivableId is not null THEN LRFT.AcquisitionId  
    WHEN LORFT.ReceivableId is not null THEN LORFT.AcquisitionId   
       WHEN LVR.Id is not null THEN LVR.AcquisitionId  
       ELSE NULL  
       END AcquisitionId,  
PREC.DealProductTypeId,  
Case WHEN LRWPS.ReceivableId  is not null THEN LRWPS.BranchId  
     WHEN LRWTPS.ReceivableId is not null THEN LRWTPS.BranchId  
       WHEN LORWPS.ReceivableId is not null THEN LORWPS.BranchId  
       WHEN LORWTPS.ReceivableId is not null THEN LORWTPS.BranchId  
       WHEN LORWTPS.ReceivableId is not null THEN LORWTPS.BranchId  
       WHEN LRFT.ReceivableId is not null THEN LRFT.BranchId  
       WHEN DR.ReceivableId is not null THEN DR.BranchId  
       WHEN CR.ReceivableId is not null THEN CR.BranchId  
       ELSE NULL  
       END BranchId,  
Case WHEN DRS.ReceivableId is not null THEN DRS.APGLTemplateId  
       WHEN PY.ReceivableId is not null THEN PY.APGLTemplateId  
       ELSE NULL  
       END APGLTemplateId,  
Case WHEN CBIR.ReceivableId is not null THEN CBIR.BookingGLTemplateId ELSE NULL END SundryBlendedItemBookingGlTemplateId,  
CASE WHEN LRWPS.ReceivableId  is not null THEN LRWPS.LeaseInterimInterestIncomeGLTemplateId ELSE LRWTPS.LeaseInterimInterestIncomeGLTemplateId END ,  
CASE WHEN LRWPS.ReceivableId  is not null THEN LRWPS.LeaseInterimRentIncomeGLTemplateId ELSE LRWTPS.LeaseInterimRentIncomeGLTemplateId END ,  
CASE WHEN LORWPS.ReceivableId  is not null THEN LORWPS.LoanIncomeRecognitionGLTemplateId ELSE LORWTPS.LoanIncomeRecognitionGLTemplateId END ,  
CASE WHEN LORWPS.ReceivableId  is not null THEN LORWPS.LoanInterimIncomeRecognitionGLTemplateId ELSE LORWTPS.LoanInterimIncomeRecognitionGLTemplateId END ,  
RTXS.ReceivableTaxId,  
RTXS.Amount TaxTotalAmount,  
RTXS.Balance TaxBalanceAmount,  
RTXS.TaxCurrencyCode,  
RTXS.TaxGlTemplateId,  
SEDP.Id,  
RFTR.Id ,  
RFTR.ReceivableForTransferType,  
CASE WHEN PREC.ContractType = @Lease and LEPS.Id is not null THEN LEPS.StartDate   
        WHEN PREC.ContractType != @Lease and LOPS.Id is not null THEN LOPS.StartDate  
       ELSE NULL END StartDate ,  
CASE WHEN PREC.SyndicationType is not null and PREC.SyndicationType != @Unknown and  PREC.SyndicationType != @None and RFTR.EffectiveDate is not null and PREC.DueDate>=RFTR.EffectiveDate THEN 1  
     ELSE @False END IsContractSyndicated,  
CASE WHEN RTXS.IsCashBased is not null then RTXS.IsCashBased else @False END,  
PREC.IsReceivableValid,  
CASE WHEN RTXS.ReceivableTaxId is null THEN @False ELSE RTXS.IsReceivableTaxValid END,  
CBIR.BlendedItemId,  
CASE WHEN RSD.Id IS NOT NULL THEN @True ELSE @False END,  
PREC.PostDate,  
PREC.ProcessThroughDate,  
@JobStepInstanceId,  
0,  
PREC.IsCollected ReceivableIsCollected,  
PREC.ReceivableGlTransactionType,  
CASE WHEN TCPD.Id IS NOT NULL THEN @True ELSE @False END
from  #PrglReceivables PREC Inner Join #LegalEntityOpenPeriodDetails LEOP on PREC.LegalEntityId = LEOP.LegalEntityId  
                             Left Join Cte_Prepaid_Recv PRPREC on PREC.ReceivableId = PRPREC.ReceivableId  
                             Left Join #PrglLeaseReceivablesWithPaymentSchedule LRWPS on PREC.ReceivableId = LRWPS.ReceivableId  
                             Left Join #PrglLeaseReceivablesWithoutPaymentSchedule LRWTPS on PREC.ReceivableId = LRWTPS.ReceivableId  
                             Left Join #PrglLeaseReceivablesForTax LRFT on PREC.ReceivableId = LRFT.ReceivableId  
                             left join #PrglLoanReceivablesWithPaymentSchedule LORWPS on LORWPS.ReceivableId = PREC.ReceivableId  
                             left join #PrglLoanReceivablesWithoutPaymentSchedule LORWTPS on LORWTPS.ReceivableId = PREC.ReceivableId  
                             Left Join #PrglLoanReceivablesForTax LORFT on PREC.ReceivableId = LORFT.ReceivableId  
                             left join LeveragedLeases LVR on LVR.ContractId = PREC.ContractId and LVR.IsCurrent = @True  
                             left join Cte_Discounting_Receivables DR on DR.ReceivableId=PREC.ReceivableId  
                             left join   Cte_Cpu_Receivables CR on CR.ReceivableId = PREC.ReceivableId  
                             Left join Sundries SR on SR.ID = PREC.SourceId and PREC.SourceTable=@Sundry  
                             Left Join Branches SRBR on SR.BranchId = SRBR.Id  
                             Left join SundryRecurringPaymentSchedules SRPS on SRPS.Id = PREC.SourceId and PREC.SourceTable = @SundryRecurring and PREC.EntityType=@CU  
                             Left Join SundryRecurrings SREC on SREC.Id=SRPS.SundryRecurringId  
                             Left Join Branches SRECBR on SREC.BranchId = SRECBR.Id  
                             Left Join LateFeeReceivables LFR on LFR.Id=PREC.SourceId and PREC.SourceTable=@LateFee and PREC.EntityType=@CU                            
                             Left Join AssetSaleReceivables ASR on ASR.Id = PREC.SourceId and PREC.SourceTable=@AssetSaleReceivable and PREC.EntityType=@CU  
                             Left Join AssetSales ASL on ASL.Id = ASR.AssetSaleId   
                             Left Join Branches ASLBR on ASL.BranchId = ASLBR.Id  
                             Left Join Cte_Blended_Receivables CBIR on PREC.ReceivableId = CBIR.ReceivableId AND CBIR.RowNum = 1  
                             Left Join Cte_DR_Receivables DRS on PREC.ReceivableId = DRS.ReceivableId  
                             Left Join Cte_PY_Receivables PY on PREC.ReceivableId = PY.ReceivableId  
                             Left Join #ReceivableTaxSummary RTXS on PREC.ReceivableId = RTXS.ReceivableId AND RTXS.IsReceivableTaxValid = 1  
                             Left Join ReceivableForTransfers RFTR on PREC.ContractId = RFTR.ContractId and RFTR.ApprovalStatus = @Approved  
                             --Left join LeasePaymentSchedules LEPS on RFTR.LeasePaymentId = LEPS.Id and RFTR.LeasePaymentId is not null  
                             --Left join LoanPaymentSchedules LOPS on RFTR.LoanPaymentId = LOPS.Id and RFTR.LoanPaymentId is not null  
         Left join LeasePaymentSchedules LEPS on PREC.PaymentScheduleId = LEPS.Id and PREC.ContractType = @Lease  
         and PREC.SourceTable != @SundryRecurring and PREC.SourceTable != @CPUSchedule   
                             Left join LoanPaymentSchedules LOPS on PREC.PaymentScheduleId = LOPS.Id and (PREC.ContractType = @Loan OR PREC.ContractType = @ProgressLoan)  
        and PREC.SourceTable != @SundryRecurring and PREC.SourceTable != @CPUSchedule   
                             Left Join SecurityDeposits SEDP on PREC.SourceId = SEDP.Id and SourceTable=@SecurityDeposit  
        Left Join RentSharingDetails RSD on RSD.ReceivableId = PREC.ReceivableId and RSD.IsActive = 1  						 
							 Left join TiedContractPaymentDetails TCPD on PREC.ContractId = TCPD.ContractId   
		Left join DiscountingRepaymentSchedules DRPS on TCPD.DiscountingRepaymentScheduleId = DRPS.ID 
		Left join DiscountingFinances DF ON DF.ID = DRPS.DiscountingFinanceId

								and (TCPD.PaymentScheduleId = LEPS.Id OR TCPD.PaymentScheduleId = LOPS.Id )  
								and  TCPD.IsActive = 1  
					
                             Where  
                              ( LRWPS.ContractId is not null or LRWTPS.ContractId is not null  
                                 or LORWPS.ContractId is not null or LORWTPS.ContractId is not null  
                                    or LRFT.ContractId is not null or LORFT.ContractId is not null   
         or LVR.ContractId is not null  
                                 or DR.DiscountingId is not null or  Sr.CurrencyId  is not null  
                      or SREC.CurrencyId  is not null or LFR.CurrencyId  is not null  
                       or ASL.CurrencyId  is not null or CR.CPUFinanceId  is not null or SEDP.Id is not null  )  
                           AND (@FilterOption = @AllFilterOption   
                        OR ((@EntityType = @Lease OR @EntityType = @Loan OR @EntityType=@ProgressLoan OR @EntityType = @LeveragedLease) AND @FilterOption = @OneFilterOption  AND PREC.ContractId = @ContractId)         
                           OR (@EntityType = @Customer AND @FilterOption = @OneFilterOption  AND PREC.CustomerId = @CustomerId)  
                                  OR (@EntityType=@Discounting AND @FilterOption = @OneFilterOption  AND DR.DiscountingId = @ContractId)  
                           )  
                           AND LEOP.IsPostDateValid = @True  
         AND(   ( @PostReceivable =1 and @PostReceivableTax=0 and IsReceivableValid =1)  
              OR( @PostReceivable =0 and @PostReceivableTax=1 and RTXS.IsReceivableTaxValid =1 )  
        OR( @PostReceivable=1 and @PostReceivableTax=1 and (IsReceivableValid =1 or RTXS.IsReceivableTaxValid =1))  
		AND  (TCPD.ContractId is null OR DF.Id is null OR DF.IsCurrent = 1)		
		)  
  
                             
                             
  
SELECT Distinct(LEOP.LegalEntityId)  
              , LEOP.LegalEntityName  
              , LEOP.FromDate  
              , LEOP.ToDate  
              , LEOP.IsPostDateValid  
              FROM #LegalEntityOpenPeriodDetails LEOP  
              INNER JOIN #PrglReceivables PREC ON PREC.LegalEntityId = LEOP.LegalEntityId  
              WHERE LEOP.IsPostDateValid = @False  
  
  
     
IF OBJECT_ID('tempDB..#PrglReceivables') IS NOT NULL  
       DROP TABLE #PrglReceivables  
IF OBJECT_ID('tempDB..#LegalEntityOpenPeriodDetails') IS NOT NULL  
       DROP TABLE #LegalEntityOpenPeriodDetails  
IF OBJECT_ID('tempDB..#PrglLeaseReceivablesWithPaymentSchedule') IS NOT NULL  
       DROP TABLE #PrglLeaseReceivablesWithPaymentSchedule  
IF OBJECT_ID('tempDB..#PrglLeaseReceivablesWithoutPaymentSchedule') IS NOT NULL  
       DROP TABLE #PrglLeaseReceivablesWithoutPaymentSchedule  
IF OBJECT_ID('tempDB..#PrglLoanReceivablesWithPaymentSchedule') IS NOT NULL  
       DROP TABLE #PrglLoanReceivablesWithPaymentSchedule  
IF OBJECT_ID('tempDB..#PrglLoanReceivablesWithoutPaymentSchedule') IS NOT NULL  
       DROP TABLE #PrglLoanReceivablesWithoutPaymentSchedule  
IF OBJECT_ID('tempDB..#ReceivableTaxSummary') IS NOT NULL  
       DROP TABLE #ReceivableTaxSummary  
IF OBJECT_ID('tempDB..#FiscalCalendarInfo') IS NOT NULL  
      DROP TABLE #FiscalCalendarInfo  
IF OBJECT_ID('tempDB..#PrglLeaseReceivablesForTax') IS NOT NULL  
      DROP TABLE #PrglLeaseReceivablesForTax  
IF OBJECT_ID('tempDB..#PrglLoanReceivablesForTax') IS NOT NULL  
      DROP TABLE #PrglLoanReceivablesForTax  
                             
  
SET NOCOUNT OFF  
--SET ANSI_WARNINGS ON  
END

GO

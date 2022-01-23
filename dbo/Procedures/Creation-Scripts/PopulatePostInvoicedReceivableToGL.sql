SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

  
CREATE PROCEDURE [dbo].[PopulatePostInvoicedReceivableToGL]  
(  
	   @ReceivableInput ReceivableIdInputTemp READONLY, 
	   @JobStepInstanceId  BIGINT,
       @CreatedById BIGINT,  
       @CreatedTime DATETIMEOFFSET,
	   @PostVATInvoicedReceivableToGL BIT,
	   @PostSalesTaxInvoicedReceivableToGL NVARCHAR(15),
	   @PRGLRunDate DATETIMEOFFSET,
	   @ExcludeBackgroundProcessingPendingContracts BIT
)AS  
BEGIN  
SET NOCOUNT ON  
--SET ANSI_WARNINGS OFF  

DECLARE @True BIT  = 1
DECLARE @False BIT  = 0

DECLARE 
@Lease NVARCHAR(5)				  ='Lease',  
@LeveragedLease NVARCHAR(15)	  ='LeveragedLease',  
@Loan NVARCHAR(5)				  ='Loan',  
@ProgressLoan NVARCHAR(15)		  ='ProgressLoan',  
@Discounting NVARCHAR(15)		  ='Discounting',  
@CT NVARCHAR(5)					  ='CT',  
@DT NVARCHAR(5)					  ='DT',  
@Unknown NVARCHAR(5)			  = '_' ,  
@Customer NVARCHAR(15)			  ='Customer',  
@SundryRecurring NVARCHAR(15)	  ='SundryRecurring',  
@Terminated NVARCHAR(15)		  ='Terminated',  
@Finance NVARCHAR(15)			  ='Finance',  
@CPUSchedule NVARCHAR(15)		  ='CPUSchedule',  
@Inactive NVARCHAR(15)			  ='Inactive',  
@Sundry NVARCHAR(15)			  ='Sundry',  
@FixedTerm NVARCHAR(15)			  ='FixedTerm',  
@CU NVARCHAR(15)				  ='CU',  
@Commenced NVARCHAR(15)			  ='Commenced',  
@LateFee NVARCHAR(15)			  ='LateFee',  
@FullyPaidOff NVARCHAR(15)		  ='FullyPaidOff',  
@AssetSaleReceivable NVARCHAR(20) ='AssetSaleReceivable',  
@Approved NVARCHAR(15)			  ='Approved',  
@SecurityDeposit NVARCHAR(15)	  ='SecurityDeposit',
@VAT NVARCHAR(5)				  = 'VAT',
@SalesTax NVARCHAR(15)			  = 'SalesTax',
@Receivable NVARCHAR(15)		  = 'RECEIVABLE',
@Tax NVARCHAR(5)				  = 'TAX',
@Both NVARCHAR(5)				  = 'BOTH',
@None NVARCHAR(5)				  = 'NONE'  

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

CREATE TABLE #ReceivableSummary
(
		ReceivableId BIGINT,
		FinancingAmount DECIMAL(16,2),
		FinancingBalance DECIMAL(16,2)
);

CREATE TABLE #ReceivableHeaderDetails
(
		ReceivableId BIGINT,
		ReceivableTaxId BIGINT,
		ReceivableCodeId BIGINT,
		EntityType NVARCHAR(2),
		EntityId BIGINT,
		DueDate DATE,
		CustomerId BIGINT,
		FunderId BIGINT,
		LegalEntityId BIGINT,
		GLSourceId BIGINT,
		IncomeType NVARCHAR(16),
		TotalAmount DECIMAL(16,2),
		Currency NVARCHAR(3),
		SourceId BIGINT,
		SourceTable NVARCHAR(20),
		IsDSL BIT,
		PaymentScheduleId BIGINT,
		IsReceivableGlPosted BIT,
		IsCollected BIT,
		IsTaxGlPosted BIT,
		TaxGlTemplateId BIGINT,
		IsCashBased BIT,
		IsReceivableValid BIT,
		IsReceivableTaxValid BIT,
		ReceivableCode NVARCHAR(100),
		AccountingTreatment NVARCHAR(12),
		GLTransactionType NVARCHAR(29),
		SyndicationGLTransactionType NVARCHAR(29),
		ReceivableGlTransactionType NVARCHAR(29),
		GLTemplateId BIGINT,
		SyndicationGLTemplateId BIGINT,
		IsIntercompany BIT,
		ProcessThroughDate DATE,
		ContractType NVARCHAR(14),
		ContractId BIGINT,
		SyndicationType NVARCHAR(16),
		IsChargedOffContract BIT,
		DealProductTypeId BIGINT
);

	CREATE NONCLUSTERED INDEX IX_ReceivableHeaderDetails_ReceivableId 
	ON #ReceivableHeaderDetails(ReceivableId);

 INSERT INTO #ReceivableHeaderDetails
 SELECT 
	ReceivableId				 = REC.Id,
	ReceivableTaxId				 = RT.Id,    
    ReceivableCodeId			 = REC.ReceivableCodeId,          
    EntityType					 = REC.EntityType,  
    EntityId					 = REC.EntityId,  
    DueDate						 = REC.DueDate,  
    CustomerId					 = REC.CustomerId,           
    FunderId					 = REC.FunderId,  
    LegalEntityId				 = REC.LegalEntityId,          
    GLSourceId					 = REC.Id,  
    IncomeType					 = REC.IncomeType,  
    TotalAmount				     = REC.TotalAmount_Amount,       
    Currency					 = REC.TotalAmount_Currency,  
    SourceId					 = REC.SourceId,  
    SourceTable					 = REC.SourceTable,  
    IsDSL						 = REC.IsDSL,  
    PaymentScheduleId			 = REC.PaymentScheduleId,  
    IsReceivableGlPosted		 = RTGE.IsReceivableGLPosted,  
    IsCollected					 = REC.IsCollected,  
    IsTaxGlPosted				 = RTGE.IsTaxGLPosted,  
    TaxGlTemplateId				 = RT.GLTemplateId,        
    IsCashBased					 = RT.IsCashBased,   
	IsReceivableValid			 = CASE 
								   WHEN RTGE.ReceivableTaxType = @VAT AND RTGE.IsReceivableGLPosted=0 AND @PostVATInvoicedReceivableToGL = @True THEN @True 
								   WHEN RTGE.ReceivableTaxType = @SalesTax AND RTGE.IsReceivableGLPosted=0 AND (UPPER(@PostSalesTaxInvoicedReceivableToGL) = @Receivable
								   OR UPPER(@PostSalesTaxInvoicedReceivableToGL) = @Both) THEN @True ELSE @False END,
	IsReceivableTaxValid		 = CASE 							 
								   WHEN RTGE.ReceivableTaxType = @VAT AND RTGE.IsTaxGLPosted=0 AND (@PostVATInvoicedReceivableToGL = @True 
								   OR @PostVATInvoicedReceivableToGL = @False) THEN @True 
							       WHEN RTGE.ReceivableTaxType = @SalesTax AND RTGE.IsTaxGLPosted=0 AND (UPPER(@PostSalesTaxInvoicedReceivableToGL) = @Tax
							       OR UPPER(@PostSalesTaxInvoicedReceivableToGL) = @Both) THEN @True ELSE @False END,
	ReceivableCode				 = RCO.[Name],
	AccountingTreatment			 = RCO.AccountingTreatment,   
	GLTransactionType			 = GLTT.[Name],  
	SyndicationGLTransactionType = SGLTT.[Name],  
	ReceivableGlTransactionType  = RGLT.[Name],  
	GLTemplateId				 = GT.Id, 
	SyndicationGLTemplateId		 = SGT.Id, 
	IsIntercompany				 = PT.IsIntercompany,  
	ProcessThroughDate			 = RTGE.InvoiceRunDate,
	ContractType				 = CT.ContractType,   
	ContractId					 = CT.Id,           
	SyndicationType				 = CT.SyndicationType,         
	IsChargedOffContract		 = CASE WHEN CT.ChargeOffStatus <> @Unknown THEN @True ELSE @False END,          
	DealProductTypeId			 = CT.DealProductTypeId
    FROM ReceivablesToGlPosting_Extract RTGE
	JOIN @ReceivableInput RI ON RTGE.ReceivableId = RI.Id
    JOIN Receivables REC ON RI.Id = REC.Id 
    JOIN ReceivableTaxes RT ON  RT.ReceivableId = REC.Id AND  RT.IsActive =1  
    JOIN ReceivableCodes RCO ON REC.ReceivableCodeId = RCO.Id  
    JOIN ReceivableTypes REC_TYPE ON RCO.ReceivableTypeId = REC_TYPE.Id  
    JOIN GLTemplates GT ON RCO.GLTemplateId = GT.Id  
    JOIN GLTransactionTypes GLTT ON GT.GLTransactionTypeId = GLTT.Id   
    JOIN Parties PT ON REC.CustomerId = PT.Id      
    JOIN GLTransactionTypes RGLT ON REC_TYPE.GLTransactionTypeId = RGLT.Id  
    JOIN GLTemplates SGT ON RCO.SyndicationGLTemplateId = SGT.Id  
    JOIN GLTransactionTypes SGLTT ON SGT.GLTransactionTypeId = SGLTT.Id
    JOIN Contracts CT ON REC.EntityId = CT.Id AND REC.EntityType = @CT AND (CT.Id IS NULL OR CT.[Status] <> @Terminated)
	WHERE @ExcludeBackgroundProcessingPendingContracts = 0 OR CT.BackgroundProcessingPending = 0;

	INSERT INTO #ReceivableTaxSummary(ReceivableTaxId, ReceivableId, Amount, Balance, TaxCurrencyCode, TaxGlTemplateId, IsCashBased, IsGLPosted, IsReceivableTaxValid)  
	SELECT 
		ReceivableTaxId		 = REC.ReceivableTaxId,
		ReceivableId		 = REC.ReceivableId,
		Amount				 = SUM(RTIM.Amount_Amount), 
		Balance				 = SUM(RTIM.Balance_Amount),
		TaxCurrencyCode		 = RTIM.Cost_Currency, 
		TaxGlTemplateId		 = REC.TaxGlTemplateId, 
		IsCashBased			 = REC.IsCashBased, 
		IsGLPosted			 = REC.IsTaxGlPosted,
		IsReceivableTaxValid = REC.IsReceivableTaxValid   
	FROM #ReceivableHeaderDetails REC   
	JOIN ReceivableTaxDetails RTIM ON REC.ReceivableTaxId = RTIM.ReceivableTaxId AND RTIM.IsActive = @True AND RTIM.IsGlPosted = 0  
	GROUP BY REC.ReceivableTaxId,REC.ReceivableId,REC.TaxGlTemplateId,RTIM.Cost_Currency,REC.IsCashBased,REC.IsTaxGLPosted,REC.IsReceivableTaxValid;


	INSERT INTO #ReceivableSummary(ReceivableId,FinancingAmount,FinancingBalance)
	SELECT 
		ReceivableId     = RECD.ReceivableId,
		FinancingAmount  = SUM(RECD.NonLeaseComponentAmount_Amount),
		FinancingBalance = SUM(RECD.NonLeaseComponentBalance_Amount) 
    FROM #ReceivableHeaderDetails REC 
	JOIN ReceivableDetails RECD ON REC.ReceivableId = RECD.ReceivableId AND REC.IsReceivableGlPosted = 0
    WHERE  REC.PaymentScheduleId  IS NOT NULL
           AND REC.PaymentScheduleId != 0
           AND REC.SourceTable != @SundryRecurring
           AND REC.SourceTable != @CPUSchedule 
    GROUP BY RECD.ReceivableId; 

	--Get Lease Receivables with Payment Schedules    
    SELECT 
		ReceivableId						   = REC.ReceivableId,  
        ContractId							   = LF.ContractId,  
        LeaseInstrumentTypeId				   = LF.InstrumentTypeId,  
        LeaseBookingGLTemplateId			   = LFD.LeaseBookingGLTemplateId,  
        LeaseInterimInterestIncomeGLTemplateId = LFD.InterimInterestIncomeGLTemplateId, 
        LeaseInterimRentIncomeGLTemplateId	   = LFD.InterimRentIncomeGLTemplateId,  
        BranchId							   = LF.BranchId,  
        LeaseCostCenterId					   = LF.CostCenterId,  
        LineofBusinessId					   = LF.LineofBusinessId,  
        AcquisitionId						   = LF.AcquisitionId,  
        FinancingAmount						   = CASE WHEN CFREC.ReceivableId IS NOT NULL THEN CFREC.FinancingAmount ELSE @False END,  
        FinancingBalance					   = CASE WHEN CFREC.ReceivableId IS NOT NULL THEN CFREC.FinancingBalance ELSE @False END   
    INTO #LeaseReceivablesWithPaymentSchedule  
    FROM #ReceivableHeaderDetails REC 
	JOIN LeasePaymentSchedules LEPS ON REC.PaymentScheduleId = LEPS.Id AND REC.EntityType=@CT AND REC.IsReceivableGlPosted = 0  
    JOIN LeaseFinanceDetails LFD ON LEPS.LeaseFinanceDetailId = LFD.Id  
    JOIN LeaseFinances LF ON LFD.Id = LF.Id  
    JOIN Contracts CT ON LF.ContractId = CT.Id    
    LEFT JOIN #ReceivableSummary CFREC ON REC.ReceivableId = CFREC.ReceivableId  
    WHERE REC.ContractId = LF.ContractId  
          AND CT.ContractType = @Lease
          AND REC.PaymentScheduleId  IS NOT NULL  
          AND REC.PaymentScheduleId != 0  
          AND REC.SourceTable != @SundryRecurring  
          AND REC.SourceTable != @CPUSchedule  
          AND (REC.IncomeType = @FixedTerm AND (CT.[Status] = @Commenced OR CT.[Status] = @FullyPaidOff)  
          OR (REC.IncomeType != @FixedTerm AND CT.[Status] != @Terminated)); 

	--Get Lease Receivables without Payment Schedules   
	SELECT 
		ReceivableId						   = REC.ReceivableId,  
        ContractId							   = LF.ContractId,  
        LeaseInstrumentTypeId				   = LF.InstrumentTypeId,  
        LeaseBookingGLTemplateId			   = LFD.LeaseBookingGLTemplateId,  
        LeaseInterimInterestIncomeGLTemplateId = LFD.InterimInterestIncomeGLTemplateId,  
        LeaseInterimRentIncomeGLTemplateId     = LFD.InterimRentIncomeGLTemplateId,   
        BranchId							   = LF.BranchId,  
        LeaseCostCenterId					   = LF.CostCenterId,  
        LineofBusinessId					   = LF.LineofBusinessId,  
        FinancingAmount						   = 0,    
        FinancingBalance					   = 0,    
        AcquisitionId						   = LF.AcquisitionId  
    INTO #LeaseReceivablesWithoutPaymentSchedule  
    FROM #ReceivableHeaderDetails REC   
	JOIN Contracts CT on REC.ContractId = CT.Id AND REC.EntityType = @CT AND REC.IsReceivableGlPosted = 0  
    JOIN LeaseFinances LF on LF.ContractId = CT.Id AND LF.IsCurrent = 1  
    JOIN LeaseFinanceDetails LFD on LF.Id = LFD.Id           
    WHERE REC.ContractId = LF.ContractId  
          AND CT.ContractType = @Lease  
          AND(REC.PaymentScheduleId IS NULL  
          OR REC.PaymentScheduleId = 0  
          OR REC.SourceTable = @SundryRecurring  
          OR REC.SourceTable = @CPUSchedule); 
	
	--Get Lease Receivables for Tax  
	SELECT 
		ReceivableId = REC.ReceivableId,   
        ContractId = LF.ContractId,  
        LeaseInstrumentTypeId = LF.InstrumentTypeId,  
        LeaseBookingGLTemplateId = LFD.LeaseBookingGLTemplateId,  
        LeaseInterimInterestIncomeGLTemplateId = LFD.InterimInterestIncomeGLTemplateId,  
        LeaseInterimRentIncomeGLTemplateId = LFD.InterimRentIncomeGLTemplateId,  
        BranchId = LF.BranchId,  
        LeaseCostCenterId = LF.CostCenterId,  
        LineofBusinessId = LF.LineofBusinessId,  
        FinancingAmount = 0,  
        FinancingBalance = 0,  
        AcquisitionId = LF.AcquisitionId  
    INTO #LeaseReceivablesForTax  
    FROM #ReceivableHeaderDetails REC   
	JOIN Contracts CT ON REC.ContractId = CT.Id AND REC.EntityType = @CT  
    JOIN #ReceivableTaxSummary RTXS ON REC.ReceivableId = RTXS.ReceivableId AND RTXS.IsReceivableTaxValid = @True   
    JOIN LeaseFinances LF ON LF.ContractId = CT.Id AND LF.IsCurrent = 1  
    JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id  
    WHERE REC.ContractId = LF.ContractId  
          AND CT.ContractType = @Lease  	
		  
	 --Get Loan Receivables with Payment Schedules  
	SELECT 
		ReceivableId							 = REC.ReceivableId,  
        ContractId								 = LF.ContractId,  
        LoanInstrumentTypeId					 = LF.InstrumentTypeId,  
        LoanBookingGLTemplateId					 = LF.LoanBookingGLTemplateId,  
        LoanIncomeRecognitionGLTemplateId		 = LF.LoanIncomeRecognitionGLTemplateId,  
        LoanInterimIncomeRecognitionGLTemplateId = LF.InterimIncomeRecognitionGLTemplateId,  
        CommencementDate						 = LF.CommencementDate,  
        BranchId								 = LF.BranchId,  
        LoanCostCenterId						 = LF.CostCenterId,   
        LineofBusinessId						 = LF.LineofBusinessId,  
        AcquisitionId							 = LF.AcquisitionId  
    INTO #LoanReceivablesWithPaymentSchedule  
	FROM #ReceivableHeaderDetails REC  
	JOIN Contracts CT ON REC.ContractId = CT.Id AND REC.EntityType = @CT AND REC.IsReceivableGlPosted = 0  
    JOIN LoanPaymentSchedules LOPS ON REC.PaymentScheduleId = LOPS.Id  
    JOIN LoanFinances LF ON LF.Id = LOPS.LoanFinanceId    
    WHERE (CT.ContractType = @Loan OR CT.ContractType = @ProgressLoan)  
          AND REC.PaymentScheduleId  IS NOT NULL  
          AND REC.PaymentScheduleId != 0  
          AND REC.SourceTable != @SundryRecurring; 

    -- Get Loan Receivables without Payment Schedules  
	SELECT 
		ReceivableId							 = REC.ReceivableId,  
        ContractId								 = LF.ContractId,  
        LoanInstrumentTypeId					 = LF.InstrumentTypeId,  
        LoanBookingGLTemplateId					 = LF.LoanBookingGLTemplateId,  
        LoanIncomeRecognitionGLTemplateId		 = LF.LoanIncomeRecognitionGLTemplateId,   
        LoanInterimIncomeRecognitionGLTemplateId = LF.InterimIncomeRecognitionGLTemplateId,  
        CommencementDate						 = LF.CommencementDate,  
        BranchId								 = LF.BranchId,  
        LoanCostCenterId						 = LF.CostCenterId,  
        LineofBusinessId						 = LF.LineofBusinessId,  
        AcquisitionId							 = LF.AcquisitionId  
    INTO #LoanReceivablesWithoutPaymentSchedule  
    FROM #ReceivableHeaderDetails REC 
	JOIN Contracts CT ON REC.ContractId = CT.Id AND REC.EntityType = @CT AND REC.IsReceivableGlPosted = 0  
    JOIN LoanFinances LF ON LF.ContractId = CT.Id AND LF.IsCurrent=1  
    WHERE (CT.ContractType = @Loan OR CT.ContractType = @ProgressLoan)  
          AND (REC.PaymentScheduleId IS NULL  
          OR REC.PaymentScheduleId = 0  
          OR REC.SourceTable = @SundryRecurring);

	--Get Loan Receivables for taxes  
	SELECT 
		ReceivableId = REC.ReceivableId,   
        ContractId = LF.ContractId,  
        LoanInstrumentTypeId = LF.InstrumentTypeId,  
        LoanBookingGLTemplateId = LF.LoanBookingGLTemplateId,  
        LoanIncomeRecognitionGLTemplateId = LF.LoanIncomeRecognitionGLTemplateId,   
        LoanInterimIncomeRecognitionGLTemplateId = LF.InterimIncomeRecognitionGLTemplateId,  
        CommencementDate = LF.CommencementDate,  
        BranchId = LF.BranchId,  
        LoanCostCenterId = LF.CostCenterId,  
        LineofBusinessId = LF.LineofBusinessId,  
        AcquisitionId = LF.AcquisitionId  
     INTO #LoanReceivablesForTax  
     FROM #ReceivableHeaderDetails REC 
	 JOIN Contracts CT ON REC.ContractId = CT.Id AND REC.EntityType = @CT  
     JOIN #ReceivableTaxSummary RTXS ON REC.ReceivableId = RTXS.ReceivableId AND RTXS.IsReceivableTaxValid = @True   
	 JOIN LoanFinances LF ON LF.ContractId = CT.Id AND LF.IsCurrent=1  
	 WHERE (CT.ContractType = @Loan OR CT.ContractType = @ProgressLoan); 

	 --Prepaid Receivables  
    SELECT 
		ReceivableId		   = REC.ReceivableId ,
		PrepaidAmount		   = SUM(PRP.PrePaidAmount_Amount), 
		FinancingPrepaidAmount = SUM(PRP.FinancingPrePaidAmount_Amount)
	INTO #PrepaidReceivable  
    FROM #ReceivableHeaderDetails REC
	JOIN PrepaidReceivables PRP ON REC.ReceivableId = PRP.ReceivableId
	WHERE PRP.IsActive = 1  
    GROUP BY REC.ReceivableId;
	
	--Discounting Receivables
	SELECT
		ReceivableId				   = REC.ReceivableId,   
        DiscountingId				   = DC.Id,  
        SequenceNumber				   = DC.SequenceNumber,  
        DiscountingBookingGLTemplateId = DF.DiscountingGLTemplateId,   
        DiscountingInstrumentTypeId	   = DF.InstrumentTypeId,  
        DiscountingCostCenterId		   = DF.CostCenterId,  
        DiscountingLineOfBusinessId	   = DF.LineOfBusinessId,  
        CommencementDate			   = DF.CommencementDate,  
        BranchId					   = DF.BranchId 
	INTO #DiscountingReceivables 
    FROM #ReceivableHeaderDetails REC 
	JOIN Discountings DC ON REC.EntityId = DC.Id AND REC.EntityType = @DT   
    JOIN DiscountingFinances DF ON DF.DiscountingId = DC.Id   
    WHERE DF.IsCurrent = 1 AND DF.BookingStatus != @Inactive 

	--CPU Receivables
	SELECT 
		ReceivableId	 = REC.ReceivableId,   
        CPUFinanceId	 = CPF.Id,  
        SequenceNumber	 = CPC.SequenceNumber,  
        InstrumentTypeId = CPA.InstrumentTypeId,  
        CostCenterId	 = CPA.CostCenterId,  
        LineofBusinessId = CPA.LineofBusinessId,  
        CommencementDate = CPF.CommencementDate,               
        BranchId		 = CPA.BranchId
	INTO #CPUReceivables                
    FROM #ReceivableHeaderDetails REC 
	JOIN CPUSchedules CPS ON REC.SourceId = CPS.Id AND REC.SourceTable = @CPUSchedule AND REC.EntityType = @CU   
    JOIN CPUFinances CPF ON CPF.Id = CPS.CPUFinanceId  
    JOIN CPUContracts CPC ON CPC.CPUFinanceId = CPF.Id  
    JOIN CPUAccountings CPA ON CPA.Id = CPF.Id  
    WHERE CPC.[Status]!=@Inactive  

	 --Blended Receivables 
    SELECT 
	   ReceivableId		   = REC.ReceivableId,  
	   BlendedItemId	   = BITM.Id,  
	   IsFAS91			   = BITM.IsFAS91,  
	   BookingGLTemplateId = BITM.BookingGLTemplateId,  
	   ROW_NUMBER() OVER (PARTITION BY ReceivableId ORDER BY BITD.BlendedItemId DESC) AS RowNum 
	INTO #BlendedReceivables 
    FROM #ReceivableHeaderDetails REC 
    JOIN BlendedItemDetails BITD ON REC.SourceId = BITD.SundryId AND BITD.SundryId IS NOT NULL   
    JOIN BlendedItems BITM  ON BITD.BlendedItemId = BITM.Id  
    WHERE REC.SourceTable=@Sundry  
     
	--Disbursement Request Receivables
    SELECT 
		ReceivableId   = REC.ReceivableId,  
		APGLTemplateId = DRS.APGLTemplateId
	INTO #DisbursementRequestReceivables  
    FROM #ReceivableHeaderDetails REC 
    JOIN DisbursementRequests DRS ON REC.SourceId = DRS.SundryId AND DRS.SundryId IS NOT NULL AND REC.IsReceivableGlPosted = 0  
    WHERE REC.SourceTable=@Sundry  
      
    --PaymentVoucher Receivables 
    SELECT 
		ReceivableId   = REC.ReceivableId,  
		APGLTemplateId = PV.APGLTemplateId
	INTO #PaymentVoucherReceivables
    FROM #ReceivableHeaderDetails REC 
    JOIN PaymentVoucherInfoes PV ON REC.SourceId = PV.SundryId AND PV.SundryId IS NOT NULL AND REC.IsReceivableGlPosted = 0  
    WHERE REC.SourceTable=@Sundry  
     
	INSERT INTO [dbo].[PostReceivableToGLJob_Extracts]  
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
           ,[IsTiedToDiscounting])
	SELECT 
		ReceivableId							 = REC.ReceivableId,  
		ReceivableCode							 = REC.ReceivableCode,  
		AccountingTreatment						 = REC.AccountingTreatment,  
		EntityType								 = REC.EntityType,  
		DueDate									 = REC.DueDate,  
		CustomerId								 = REC.CustomerId,  
		GLTransactionType						 = REC.GLTransactionType,  
		SyndicationGLTransactionType			 = REC.SyndicationGLTransactionType,  
		GLTemplateId							 = REC.GLTemplateId,  
		SyndicationGLTemplateId					 = REC.SyndicationGLTemplateId,  
		FunderId								 = REC.FunderId,  
		LegalEntityId							 = REC.LegalEntityId,  
		IncomeType								 = REC.IncomeType,
		TotalAmount								 = CASE WHEN LRWPS.ReceivableId  IS NOT NULL AND LRWPS.FinancingAmount IS NOT NULL 
												        THEN REC.TotalAmount - LRWPS.FinancingAmount ELSE REC.TotalAmount END,  
		PrepaidAmount							 = CASE WHEN PRPREC.ReceivableId IS NOT NULL AND PRPREC.PrepaidAmount IS NOT NULL  
												        THEN PRPREC.PrepaidAmount ELSE @False END,  
		FinancingPrepaidAmount					 = CASE WHEN PRPREC.ReceivableId IS NOT NULL AND PRPREC.FinancingPrepaidAmount IS NOT NULL THEN PRPREC.FinancingPrepaidAmount ELSE @False END,  
		FinancingTotalAmount					 = CASE WHEN LRWPS.ReceivableId  IS NOT NULL AND LRWPS.FinancingAmount IS NOT NULL THEN LRWPS.FinancingAmount ELSE @False END,
		Currency								 = REC.Currency,  
		ContractType							 = REC.ContractType,  
		ContractId								 = REC.ContractId,  
		DiscountingId							 = DR.DiscountingId,  
		CommencementDate						 = CASE WHEN LORWPS.ReceivableId  IS NOT NULL THEN LORWPS.CommencementDate  
												   WHEN LORWTPS.ReceivableId  IS NOT NULL THEN LORWTPS.CommencementDate  
												   WHEN LORFT.ReceivableId IS NOT NULL THEN LORFT.CommencementDate  
												   WHEN DR.ReceivableId  IS NOT NULL THEN DR.CommencementDate  
												   WHEN CR.ReceivableId  IS NOT NULL THEN CR.CommencementDate  
												   WHEN LVR.Id IS NOT NULL THEN LVR.CommencementDate  
												   ELSE NULL END,  
		IsChargedOffContract					 = REC.IsChargedOffContract,
		InstrumentTypeId						 = Case WHEN LRWPS.ReceivableId IS NOT NULL THEN LRWPS.LeaseInstrumentTypeId  
												   WHEN LRWTPS.ReceivableId IS NOT NULL THEN LRWTPS.LeaseInstrumentTypeId  
												   WHEN LORWPS.ReceivableId IS NOT NULL THEN LORWPS.LoanInstrumentTypeId  
												   WHEN LORWTPS.ReceivableId IS NOT NULL THEN LORWTPS.LoanInstrumentTypeId  
												   WHEN LRFT.ReceivableId IS NOT NULL THEN LRFT.LeaseInstrumentTypeId  
												   WHEN LORFT.ReceivableId IS NOT NULL THEN LORFT.LoanInstrumentTypeId  
												   WHEN DR.ReceivableId IS NOT NULL THEN DR.DiscountingInstrumentTypeId  
												   WHEN CR.ReceivableId IS NOT NULL THEN CR.InstrumentTypeId  
												   WHEN LVR.Id IS NOT NULL THEN LVR.InstrumentTypeId  
												   WHEN LFR.Id IS NOT NULL THEN LFR.InstrumentTypeId  
												   WHEN ASL.Id IS NOT NULL THEN ASL.InstrumentTypeId  
												   WHEN SR.Id IS NOT NULL THEN SR.InstrumentTypeId  
												   WHEN SREC.Id IS NOT NULL THEN SREC.InstrumentTypeId  
												   WHEN SEDP.Id IS NOT NULL THEN SEDP.InstrumentTypeId  
												   ELSE NULL END,  
		BookingGLTemplateId						 = Case WHEN LRWPS.ReceivableId IS NOT NULL THEN LRWPS.LeaseBookingGLTemplateId  
												   WHEN LRWTPS.ReceivableId IS NOT NULL THEN LRWTPS.LeaseBookingGLTemplateId  
												   WHEN LORWPS.ReceivableId IS NOT NULL THEN LORWPS.LoanBookingGLTemplateId  
												   WHEN LORWTPS.ReceivableId IS NOT NULL THEN LORWTPS.LoanBookingGLTemplateId  
												   WHEN LRFT.ReceivableId IS NOT NULL THEN LRFT.LeaseBookingGLTemplateId  
												   WHEN LORFT.ReceivableId IS NOT NULL THEN LORFT.LoanBookingGLTemplateId  
												   WHEN DR.ReceivableId IS NOT NULL THEN DR.DiscountingBookingGLTemplateId  
												   WHEN LVR.Id IS NOT NULL THEN LVR.BookingGLTemplateId    
												   ELSE NULL END,  
		CostCenterId							 = Case WHEN LRWPS.ReceivableId  IS NOT NULL THEN LRWPS.LeaseCostCenterId  
												   WHEN LRWTPS.ReceivableId IS NOT NULL THEN LRWTPS.LeaseCostCenterId  
												   WHEN LORWPS.ReceivableId IS NOT NULL THEN LORWPS.LoanCostCenterId  
												   WHEN LORWTPS.ReceivableId IS NOT NULL THEN LORWTPS.LoanCostCenterId  
												   WHEN LRFT.ReceivableId IS NOT NULL THEN LRFT.LeaseCostCenterId  
												   WHEN LORFT.ReceivableId IS NOT NULL THEN LORFT.LoanCostCenterId  
												   WHEN DR.ReceivableId IS NOT NULL THEN DR.DiscountingCostCenterId  
												   WHEN CR.ReceivableId IS NOT NULL THEN CR.CostCenterId  
												   WHEN LVR.Id IS NOT NULL THEN LVR.CostCenterId  
												   WHEN LFR.Id IS NOT NULL THEN LFR.CostCenterId  
												   WHEN ASL.Id IS NOT NULL THEN ASL.CostCenterId  
												   WHEN SR.Id IS NOT NULL THEN SR.CostCenterId  
												   WHEN SREC.Id IS NOT NULL THEN SREC.CostCenterId  
												   WHEN SEDP.Id IS NOT NULL THEN SEDP.CostCenterId  
												   ELSE NULL END ,  
		LineOfBusinessId						 = Case WHEN LRWPS.ReceivableId IS NOT NULL THEN LRWPS.LineofBusinessId  
												   WHEN LRWTPS.ReceivableId IS NOT NULL THEN LRWTPS.LineofBusinessId  
												   WHEN LORWPS.ReceivableId IS NOT NULL THEN LORWPS.LineofBusinessId  
												   WHEN LORWTPS.ReceivableId IS NOT NULL THEN LORWTPS.LineofBusinessId  
												   WHEN LORFT.ReceivableId IS NOT NULL THEN LORFT.LineofBusinessId  
												   WHEN LRFT.ReceivableId IS NOT NULL THEN LRFT.LineofBusinessId  
												   WHEN DR.ReceivableId IS NOT NULL THEN DR.DiscountingLineOfBusinessId  
												   WHEN CR.ReceivableId IS NOT NULL THEN CR.LineOfBusinessId  
												   WHEN LVR.Id IS NOT NULL THEN LVR.LineOfBusinessId  
												   WHEN LFR.Id IS NOT NULL THEN LFR.LineOfBusinessId  
												   WHEN ASL.Id IS NOT NULL THEN ASL.LineOfBusinessId  
												   WHEN SR.Id IS NOT NULL THEN SR.LineOfBusinessId  
												   WHEN SREC.Id IS NOT NULL THEN SREC.LineOfBusinessId  
												   WHEN SEDP.Id IS NOT NULL THEN SEDP.LineofBusinessId  
												   ELSE NULL END,  
		IsInterCompany							 = REC.IsInterCompany,  
		IsDSL									 = REC.IsDSL,  
		IsSundryBlendedItemFAS91				 = Case WHEN CBIR.ReceivableId IS NOT NULL THEN CBIR.IsFAS91 ELSE @False END,  
		AcquisitionId							 = Case WHEN LRWPS.ReceivableId IS NOT NULL THEN LRWPS.AcquisitionId  
												   WHEN LRWTPS.ReceivableId IS NOT NULL THEN LRWTPS.AcquisitionId  
												   WHEN LORWPS.ReceivableId IS NOT NULL THEN LORWPS.AcquisitionId  
												   WHEN LORWTPS.ReceivableId IS NOT NULL THEN LORWTPS.AcquisitionId  
												   WHEN LRFT.ReceivableId IS NOT NULL THEN LRFT.AcquisitionId  
												   WHEN LORFT.ReceivableId IS NOT NULL THEN LORFT.AcquisitionId   
												   WHEN LVR.Id IS NOT NULL THEN LVR.AcquisitionId  
												   ELSE NULL END,  
		DealProductTypeId						 = REC.DealProductTypeId,  
		BranchId								 = Case WHEN LRWPS.ReceivableId IS NOT NULL THEN LRWPS.BranchId  
												   WHEN LRWTPS.ReceivableId IS NOT NULL THEN LRWTPS.BranchId  
												   WHEN LORWPS.ReceivableId IS NOT NULL THEN LORWPS.BranchId  
												   WHEN LORWTPS.ReceivableId IS NOT NULL THEN LORWTPS.BranchId  
												   WHEN LORWTPS.ReceivableId IS NOT NULL THEN LORWTPS.BranchId  
												   WHEN LRFT.ReceivableId IS NOT NULL THEN LRFT.BranchId  
												   WHEN DR.ReceivableId IS NOT NULL THEN DR.BranchId  
												   WHEN CR.ReceivableId IS NOT NULL THEN CR.BranchId  
												   ELSE NULL END,  
		APGLTemplateId							 = Case WHEN DRS.ReceivableId IS NOT NULL THEN DRS.APGLTemplateId  
												   WHEN PY.ReceivableId IS NOT NULL THEN PY.APGLTemplateId  
												   ELSE NULL END,  
		SundryBlendedItemBookingGlTemplateId     = Case WHEN CBIR.ReceivableId IS NOT NULL THEN CBIR.BookingGLTemplateId ELSE NULL END,  
		LeaseInterimInterestIncomeGLTemplateId   = CASE WHEN LRWPS.ReceivableId IS NOT NULL THEN LRWPS.LeaseInterimInterestIncomeGLTemplateId ELSE LRWTPS.LeaseInterimInterestIncomeGLTemplateId END ,  
		LeaseInterimRentIncomeGLTemplateId       = CASE WHEN LRWPS.ReceivableId IS NOT NULL THEN LRWPS.LeaseInterimRentIncomeGLTemplateId ELSE LRWTPS.LeaseInterimRentIncomeGLTemplateId END ,  
		LoanIncomeRecognitionGLTemplateId        = CASE WHEN LORWPS.ReceivableId IS NOT NULL THEN LORWPS.LoanIncomeRecognitionGLTemplateId ELSE LORWTPS.LoanIncomeRecognitionGLTemplateId END ,  
		LoanInterimIncomeRecognitionGLTemplateId = CASE WHEN LORWPS.ReceivableId IS NOT NULL THEN LORWPS.LoanInterimIncomeRecognitionGLTemplateId ELSE LORWTPS.LoanInterimIncomeRecognitionGLTemplateId END ,  
		ReceivableTaxId							 = RTXS.ReceivableTaxId,  
		TaxTotalAmount							 = RTXS.Amount,  
		TaxBalanceAmount						 = RTXS.Balance,  
		TaxCurrencyCode							 = RTXS.TaxCurrencyCode,  
		TaxGlTemplateId							 = RTXS.TaxGlTemplateId,  
		SecurityDepositId						 = SEDP.Id,  
		ReceivableForTransferId					 = RFTR.Id ,  
		ReceivableForTransferType				 = RFTR.ReceivableForTransferType,  
		StartDate								 = CASE WHEN REC.ContractType = @Lease AND LEPS.Id IS NOT NULL THEN LEPS.StartDate   
												   WHEN REC.ContractType != @Lease AND LOPS.Id IS NOT NULL THEN LOPS.StartDate  
												   ELSE NULL END,  
		IsContractSyndicated					 = CASE WHEN REC.SyndicationType IS NOT NULL AND REC.SyndicationType != @Unknown AND REC.SyndicationType != @None 
												   AND RFTR.EffectiveDate IS NOT NULL AND REC.DueDate >= RFTR.EffectiveDate THEN 1  
												   ELSE @False END,  
		IsCashBased								 = CASE WHEN RTXS.IsCashBased IS NOT NULL THEN RTXS.IsCashBased ELSE @False END,  
		IsReceivableValid						 = REC.IsReceivableValid,  
 		IsReceivableTaxValid					 = CASE WHEN RTXS.ReceivableTaxId IS NULL THEN @False ELSE RTXS.IsReceivableTaxValid END,  
		BlendedItemId							 = CBIR.BlendedItemId,  
		IsVendorOwned							 = CASE WHEN RSD.Id IS NOT NULL THEN @True ELSE @False END,  
		PostDate								 = CASE WHEN @PRGLRunDate > REC.ProcessThroughDate THEN @PRGLRunDate ELSE REC.ProcessThroughDate END,  
		ProcessThroughDate						 = REC.ProcessThroughDate,  
		JobStepInstanceId						 = @JobStepInstanceId,  
		IsSubmitted								 = 0,  
		ReceivableIsCollected					 = REC.IsCollected,  
		ReceivableGlTransactionType				 = REC.ReceivableGlTransactionType,  
		IsTiedToDiscounting						 = CASE WHEN TiedContractPaymentDetailsTemp.Id IS NOT NULL THEN @True ELSE @False END
	FROM #ReceivableHeaderDetails REC 
    LEFT JOIN #PrepaidReceivable PRPREC ON REC.ReceivableId = PRPREC.ReceivableId  
    LEFT JOIN #LeaseReceivablesWithPaymentSchedule LRWPS ON REC.ReceivableId = LRWPS.ReceivableId  
    LEFT JOIN #LeaseReceivablesWithoutPaymentSchedule LRWTPS ON REC.ReceivableId = LRWTPS.ReceivableId  
    LEFT JOIN #LeaseReceivablesForTax LRFT ON REC.ReceivableId = LRFT.ReceivableId  
    LEFT JOIN #LoanReceivablesWithPaymentSchedule LORWPS ON REC.ReceivableId = LORWPS.ReceivableId   
    LEFT JOIN #LoanReceivablesWithoutPaymentSchedule LORWTPS ON REC.ReceivableId = LORWTPS.ReceivableId 
    LEFT JOIN #LoanReceivablesForTax LORFT ON REC.ReceivableId = LORFT.ReceivableId  
    LEFT JOIN LeveragedLeases LVR ON REC.ReceivableId = LVR.ContractId AND LVR.IsCurrent = @True  
    LEFT JOIN #DiscountingReceivables DR ON REC.ReceivableId = DR.ReceivableId 
    LEFT JOIN #CPUReceivables CR ON REC.ReceivableId = CR.ReceivableId 
    LEFT JOIN Sundries SR ON REC.ReceivableId = SR.ID AND REC.SourceTable = @Sundry  
    LEFT JOIN Branches SRBR ON SR.BranchId = SRBR.Id  
    LEFT JOIN SundryRecurringPaymentSchedules SRPS ON REC.SourceId = SRPS.Id AND REC.SourceTable = @SundryRecurring AND REC.EntityType = @CU  
    LEFT JOIN SundryRecurrings SREC ON SREC.Id = SRPS.SundryRecurringId  
    LEFT JOIN Branches SRECBR ON SREC.BranchId = SRECBR.Id  
    LEFT JOIN LateFeeReceivables LFR ON REC.SourceId = LFR.Id AND REC.SourceTable = @LateFee AND REC.EntityType = @CU                            
    LEFT JOIN AssetSaleReceivables ASR ON REC.SourceId = ASR.Id AND REC.SourceTable= @AssetSaleReceivable AND REC.EntityType = @CU  
    LEFT JOIN AssetSales ASL ON ASL.Id = ASR.AssetSaleId   
    LEFT JOIN Branches ASLBR ON ASL.BranchId = ASLBR.Id  
    LEFT JOIN #BlendedReceivables CBIR ON REC.ReceivableId = CBIR.ReceivableId AND CBIR.RowNum = 1  
    LEFT JOIN #DisbursementRequestReceivables DRS ON REC.ReceivableId = DRS.ReceivableId  
    LEFT JOIN #PaymentVoucherReceivables PY ON REC.ReceivableId = PY.ReceivableId  
    LEFT JOIN #ReceivableTaxSummary RTXS ON REC.ReceivableId = RTXS.ReceivableId AND RTXS.IsReceivableTaxValid = 1  
    LEFT JOIN ReceivableForTransfers RFTR ON REC.ContractId = RFTR.ContractId AND RFTR.ApprovalStatus = @Approved  
    LEFT JOIN LeasePaymentSchedules LEPS ON REC.PaymentScheduleId = LEPS.Id AND REC.ContractType = @Lease  
              AND REC.SourceTable != @SundryRecurring AND REC.SourceTable != @CPUSchedule   
    LEFT JOIN LoanPaymentSchedules LOPS ON REC.PaymentScheduleId = LOPS.Id AND (REC.ContractType = @Loan OR REC.ContractType = @ProgressLoan)  
			  AND REC.SourceTable != @SundryRecurring AND REC.SourceTable != @CPUSchedule   
    LEFT JOIN SecurityDeposits SEDP ON REC.SourceId = SEDP.Id AND SourceTable = @SecurityDeposit  
    LEFT JOIN RentSharingDetails RSD ON REC.ReceivableId = RSD.ReceivableId AND RSD.IsActive = 1  						 
	LEFT JOIN (SELECT TOP(1) TCPD.* FROM #ReceivableHeaderDetails PRGLRec
	LEFT JOIN LeasePaymentSchedules LEPS ON PRGLRec.PaymentScheduleId = LEPS.Id AND PRGLRec.ContractType = @Lease  
			  AND PRGLRec.SourceTable != @SundryRecurring AND PRGLRec.SourceTable != @CPUSchedule   
	LEFT JOIN LoanPaymentSchedules LOPS ON PRGLRec.PaymentScheduleId = LOPS.Id AND (PRGLRec.ContractType = @Loan OR PRGLRec.ContractType = @ProgressLoan)  
			  AND PRGLRec.SourceTable != @SundryRecurring AND PRGLRec.SourceTable != @CPUSchedule   
	LEFT JOIN TiedContractPaymentDetails TCPD ON PRGLRec.ContractId = TCPD.ContractId AND (TCPD.PaymentScheduleId = LEPS.Id OR TCPD.PaymentScheduleId = LOPS.Id) AND TCPD.IsActive = 1
	LEFT JOIN DiscountingRepaymentSchedules DRPS ON TCPD.DiscountingRepaymentScheduleId = DRPS.ID 
	LEFT JOIN DiscountingFinances DF ON DF.ID = DRPS.DiscountingFinanceId AND DF.IsCurrent=1) AS TiedContractPaymentDetailsTemp ON REC.ContractId = TiedContractPaymentDetailsTemp.ContractId
	WHERE (LRWPS.ContractId IS NOT NULL OR LRWTPS.ContractId IS NOT NULL OR LORWPS.ContractId IS NOT NULL OR LORWTPS.ContractId IS NOT NULL  
           OR LRFT.ContractId IS NOT NULL OR LORFT.ContractId IS NOT NULL OR LVR.ContractId IS NOT NULL OR DR.DiscountingId IS NOT NULL OR  Sr.CurrencyId  IS NOT NULL  
           OR SREC.CurrencyId IS NOT NULL OR LFR.CurrencyId  IS NOT NULL OR ASL.CurrencyId  IS NOT NULL OR CR.CPUFinanceId  IS NOT NULL OR SEDP.Id IS NOT NULL  )  
           AND (IsReceivableValid =1 OR RTXS.IsReceivableTaxValid =1); 
		   
END

GO

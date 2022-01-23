SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SPHC_LoanGLPosting_Reconciliation]
(
	@ResultOption NVARCHAR(20),
	@LegalEntityIds ReconciliationId READONLY,
	@ContractIds ReconciliationId READONLY,  
	@CustomerIds ReconciliationId READONLY
)
AS
BEGIN

        SET NOCOUNT ON;
        SET ANSI_WARNINGS OFF;
        IF OBJECT_ID('tempdb..#LoanDetails') IS NOT NULL
            BEGIN
                DROP TABLE #LoanDetails;
        END;
        IF OBJECT_ID('tempdb..#BasicDetails') IS NOT NULL
            BEGIN
                DROP TABLE #BasicDetails;
        END;
        IF OBJECT_ID('tempdb..#LoanTableValues') IS NOT NULL
            BEGIN
                DROP TABLE #LoanTableValues;
        END;
        IF OBJECT_ID('tempdb..#LoanIncomeScheduleTemp') IS NOT NULL
            BEGIN
                DROP TABLE #LoanIncomeScheduleTemp;
        END;
        IF OBJECT_ID('tempdb..#LoanFinanceBasicTemp') IS NOT NULL
            BEGIN
                DROP TABLE #LoanFinanceBasicTemp;
        END;
        IF OBJECT_ID('tempdb..#ReceivableDetailsTemp') IS NOT NULL
            BEGIN
                DROP TABLE #ReceivableDetailsTemp;
        END;
        IF OBJECT_ID('tempdb..#LoanPaydownTemp') IS NOT NULL
            BEGIN
                DROP TABLE #LoanPaydownTemp;
        END;
        IF OBJECT_ID('tempdb..#FutureScheduledFundedTemp') IS NOT NULL
            BEGIN
                DROP TABLE #FutureScheduledFundedTemp;
        END;
        IF OBJECT_ID('tempdb..#CapitalizedInterests') IS NOT NULL
            BEGIN
                DROP TABLE #CapitalizedInterests;
        END;
        IF OBJECT_ID('tempdb..#GLTrialBalance') IS NOT NULL
            BEGIN
                DROP TABLE #GLTrialBalance;
        END;
        IF OBJECT_ID('tempdb..#LoanGLJournalValues') IS NOT NULL
            BEGIN
                DROP TABLE #LoanGLJournalValues;
        END;
        IF OBJECT_ID('tempdb..#AccrualDetails') IS NOT NULL
            BEGIN
                DROP TABLE #AccrualDetails;
        END;
        IF OBJECT_ID('tempdb..#ReceivableSumAmount') IS NOT NULL
            BEGIN
                DROP TABLE #ReceivableSumAmount;
        END;
        IF OBJECT_ID('tempdb..#RePossessionAmount') IS NOT NULL
            BEGIN
                DROP TABLE #RePossessionAmount;
        END;
        IF OBJECT_ID('tempdb..#CumulativeInterestAppliedToPrincipal') IS NOT NULL
            BEGIN
                DROP TABLE #CumulativeInterestAppliedToPrincipal;
        END;
        IF OBJECT_ID('tempdb..#TotalGainAmount') IS NOT NULL
            BEGIN
                DROP TABLE #TotalGainAmount;
        END;
        IF OBJECT_ID('tempdb..#WriteDown') IS NOT NULL
            BEGIN
                DROP TABLE #WriteDown;
        END;
        IF OBJECT_ID('tempdb..#ChargeOffDetails') IS NOT NULL
            BEGIN
                DROP TABLE #ChargeOffDetails;
        END;
        IF OBJECT_ID('tempdb..#BlendedItemTemp') IS NOT NULL
            BEGIN
                DROP TABLE #BlendedItemTemp;
        END;
        IF OBJECT_ID('tempdb..#InterestApplied') IS NOT NULL
            BEGIN
                DROP TABLE #InterestApplied;
        END;
        IF OBJECT_ID('tempdb..#ReceiptDetails') IS NOT NULL
            BEGIN
                DROP TABLE #ReceiptDetails;
        END;
		IF OBJECT_ID('tempdb..#ResultList') IS NOT NULL
            BEGIN
                DROP TABLE #ResultList;
        END;
		IF OBJECT_ID('tempdb..#RefundDetails') IS NOT NULL
            BEGIN
                DROP TABLE #RefundDetails;
        END;
		IF OBJECT_ID('tempdb..#RefundGLJournalIds') IS NOT NULL
            BEGIN
                DROP TABLE #RefundGLJournalIds;
        END;
		IF OBJECT_ID('tempdb..#RefundTableValue') IS NOT NULL
		BEGIN
			DROP TABLE #RefundTableValue;
		END
		IF OBJECT_ID('tempdb..#GLDetails') IS NOT NULL
		BEGIN
			DROP TABLE #GLDetails;
		END
		IF OBJECT_ID('tempdb..#SyndicationReceivableValues') IS NOT NULL
            BEGIN
                DROP TABLE #SyndicationReceivableValues;
        END;
		IF OBJECT_ID('tempdb..#PayableDetails') IS NOT NULL
            BEGIN
                DROP TABLE #PayableDetails;
        END;
		IF OBJECT_ID('tempdb..#SyndicationProceedsReceivables') IS NOT NULL
            BEGIN
                DROP TABLE #SyndicationProceedsReceivables;
        END;
		IF OBJECT_ID('tempdb..#SyndicationProceedsAmount') IS NOT NULL
            BEGIN
                DROP TABLE #SyndicationProceedsAmount;
        END;
		IF OBJECT_ID('tempdb..#SyndicationFunderRemitting') IS NOT NULL
            BEGIN
                DROP TABLE #SyndicationFunderRemitting;
        END;
		IF OBJECT_ID('tempdb..#ReceivableTaxDetails') IS NOT NULL
            BEGIN
                DROP TABLE #ReceivableTaxDetails;
        END;
		IF OBJECT_ID('tempdb..#SyndicationDetailsTemp') IS NOT NULL
            BEGIN
                DROP TABLE #SyndicationDetailsTemp;
        END;
		IF OBJECT_ID('tempdb..#SyndicationPayableValues') IS NOT NULL
            BEGIN
                DROP TABLE #SyndicationPayableValues;
        END;
		IF OBJECT_ID('tempdb..#DRDetails') IS NOT NULL
            BEGIN
                DROP TABLE #DRDetails;
        END;
		IF OBJECT_ID('tempdb..#PayableGLAmount') IS NOT NULL
            BEGIN
                DROP TABLE #PayableGLAmount;
        END;
		IF OBJECT_ID('tempdb..#FunderCashPostedAmount') IS NOT NULL
            BEGIN
                DROP TABLE #FunderCashPostedAmount;
        END;
		IF OBJECT_ID('tempdb..#MaxReceivablePaymentEndDate') IS NOT NULL
            BEGIN
                DROP TABLE #MaxReceivablePaymentEndDate;
        END;
		IF OBJECT_ID('tempdb..#CasualtyLoanPayments') IS NOT NULL
            BEGIN
                DROP TABLE #CasualtyLoanPayments;
        END;
		IF OBJECT_ID('tempdb..#MinNonServicingDate') IS NOT NULL
            BEGIN
                DROP TABLE #MinNonServicingDate;
        END;
		IF OBJECT_ID('tempdb..#ReceivablesPosted') IS NOT NULL
            BEGIN
                DROP TABLE #ReceivablesPosted;
        END;
		IF OBJECT_ID('tempdb..#ProgressPaymentCredit') IS NOT NULL
            BEGIN
                DROP TABLE #ProgressPaymentCredit;
        END;
		IF OBJECT_ID('tempdb..#ProgressPaymentCreditAmount') IS NOT NULL
            BEGIN
                DROP TABLE #ProgressPaymentCreditAmount;
        END;
		IF OBJECT_ID('tempdb..#ProgressPaymentCreditGLAmount') IS NOT NULL
            BEGIN
                DROP TABLE #ProgressPaymentCreditGLAmount;
        END;
		IF OBJECT_ID('tempdb..#NonCashSalesTax') IS NOT NULL
            BEGIN
                DROP TABLE #NonCashSalesTax;
        END;
		IF OBJECT_ID('tempdb..#LoanSummary') IS NOT NULL
            BEGIN
                DROP TABLE #LoanSummary;
        END;
		IF OBJECT_ID('tempdb..#ReceiptApplicationReceivableDetails') IS NOT NULL
			BEGIN
				DROP TABLE #ReceiptApplicationReceivableDetails;
		END
		IF OBJECT_ID('tempdb..#ChargeoffRecoveryReceiptIds') IS NOT NULL
			BEGIN
				DROP TABLE #ChargeoffRecoveryReceiptIds;
		END
		IF OBJECT_ID('tempdb..#ChargeoffExpenseReceiptIds') IS NOT NULL
			BEGIN
				DROP TABLE #ChargeoffExpenseReceiptIds;
		END
		IF OBJECT_ID('tempdb..#NonSKUChargeoffRecoveryRecords') IS NOT NULL
			BEGIN
				DROP TABLE #NonSKUChargeoffRecoveryRecords;
		END
		IF OBJECT_ID('tempdb..#NonSKUChargeoffExpenseRecords') IS NOT NULL
			BEGIN
				DROP TABLE #NonSKUChargeoffExpenseRecords;
		END
		
        /**************************************************************************************************************************/
        /*Declare Values*/
		DECLARE @IsGainPresent BIT = 0
        DECLARE @True BIT= 1;
        DECLARE @False BIT= 0;
		DECLARE @MigrationSource nvarchar(50); 
		SELECT @MigrationSource = Value FROM GlobalParameters WHERE Category ='Migration' AND Name = 'ConversionSource'
        DECLARE @Unknown NVARCHAR(3)= '_';
        DECLARE @ProgressLoanContractType NVARCHAR(50)= 'ProgressLoan';
        DECLARE @LoanCancelledStatus NVARCHAR(50)= 'Cancelled';
        DECLARE @CompletedStatus NVARCHAR(50)= 'Completed';
        DECLARE @Uncommenced NVARCHAR(50)= 'Uncommenced';
        DECLARE @LoanDownPayment NVARCHAR(20)= 'Downpayment';
        DECLARE @FullSale NVARCHAR(20)= 'FullSale';
        DECLARE @ApprovalStatus NVARCHAR(50)= 'Approved';
        DECLARE @Origination NVARCHAR(50)= 'Origination';
        DECLARE @OriginationRestoredType NVARCHAR(50)= 'OriginationRestored';
        DECLARE @LoanDisbursementAllocationMethod NVARCHAR(50)= 'LoanDisbursement';
        DECLARE @InActive NVARCHAR(50)= 'InActive';
        DECLARE @PayableInvoiceOtherCost NVARCHAR(50)= 'PayableInvoiceOtherCost';
        DECLARE @ContractEntityType NVARCHAR(3)= 'CT';
        DECLARE @None NVARCHAR(5)= 'None';
        DECLARE @ActiveStatus NVARCHAR(20)= 'Active';
        DECLARE @CapitalizedInterestDueToSkipPayments NVARCHAR(60)= 'ShortPayment';
        DECLARE @CapitalizedInterestDueToRateChange NVARCHAR(60)= 'RateChange';
        DECLARE @CapitalizedInterestFromPaydown NVARCHAR(60)= 'Paydown';
        DECLARE @CapitalizedInterestDueToScheduledFunding NVARCHAR(60)= 'ScheduledFunding';
        DECLARE @LoanPrincipal NVARCHAR(50)= 'LoanPrincipal';
        DECLARE @LoanPrincipalAR NVARCHAR(20)= 'LoanPrincipalAR';
        DECLARE @LoanInterestAR NVARCHAR(20)= 'LoanInterestAR';
        DECLARE @SuspendedIncome NVARCHAR(20)= 'SuspendedIncome';
        DECLARE @LoanIncomeRecognition NVARCHAR(25)= 'LoanIncomeRecognition';
        DECLARE @LoanChargeoff NVARCHAR(25)= 'LoanChargeoff';
        DECLARE @WritedownAccount NVARCHAR(25)= 'WritedownAccount';
        DECLARE @WriteDown NVARCHAR(20)= 'WriteDown';
        DECLARE @WriteDownRecovery NVARCHAR(25)= 'WriteDownRecovery';
        DECLARE @ChargeoffExpense NVARCHAR(20)= 'ChargeoffExpense';
        DECLARE @ChargeOffRecovery NVARCHAR(20)= 'ChargeOffRecovery';
        DECLARE @GainOnRecovery NVARCHAR(20)= 'GainOnRecovery';
        DECLARE @RecoveryIncome NVARCHAR(20)= 'RecoveryIncome';
        DECLARE @ReaccrualSystemConfigType NVARCHAR(MAX)= 'ReAccrualResidualIncome,ReAccrualRentalIncome,ReAccrualIncome,ReAccrualFinanceIncome,ReAccrualFinanceResidualIncome,ReAccrualDeferredSellingProfitIncome';
        DECLARE @RecognizeImmediately NVARCHAR(25)= 'RecognizeImmediately';
        DECLARE @ReAccrualRentalIncome NVARCHAR(25)= 'ReAccrualRentalIncome';
        DECLARE @SaleOfPaymentsType NVARCHAR(25)= 'SaleOfPayments';
        DECLARE @LoanInterest NVARCHAR(50)= 'LoanInterest';
        DECLARE @LoanInterimInterest NVARCHAR(50)= 'InterimInterest';
        DECLARE @FixedTerm NVARCHAR(50)= 'FixedTerm';
        DECLARE @SundryRecurring NVARCHAR(50)= 'SundryRecurring';
        DECLARE @FullyPaidOff NVARCHAR(20)= 'FullyPaidOff';
        DECLARE @ProgressLoanInterestCapitalized NVARCHAR(50)= 'ProgressLoan';
        DECLARE @CapitalizedAdditionalFeeCharge NVARCHAR(50)= 'AdditionalFeeCharge';
        DECLARE @Paydown NVARCHAR(20)= 'Paydown';
        DECLARE @FullPaydown NVARCHAR(20)= 'FullPaydown';
        DECLARE @Casualty NVARCHAR(20)= 'Casualty';
        DECLARE @RePossession NVARCHAR(20)= 'RePossession';
        DECLARE @GainLossAdjustment NVARCHAR(20)= 'GainLossAdjustment';
        DECLARE @AccruedInterest NVARCHAR(20)= 'AccruedInterest';
        DECLARE @Contract NVARCHAR(20)= 'Contract';
        DECLARE @DisbursementRequest NVARCHAR(30)= 'DisbursementRequest';
        DECLARE @NoteReceivable NVARCHAR(30)= 'NoteReceivable';
        DECLARE @Disbursement NVARCHAR(30)= 'Disbursement';
        DECLARE @PrincipalReceivable NVARCHAR(30)= 'PrincipalReceivable';
        DECLARE @InterestReceivable NVARCHAR(30)= 'InterestReceivable';
        DECLARE @Receivable NVARCHAR(30)= 'Receivable';
        DECLARE @AccruedInterestCapitalized NVARCHAR(30)= 'AccruedInterestCapitalized';
        DECLARE @PrepaidInterestReceivable NVARCHAR(30)= 'PrepaidInterestReceivable';
        DECLARE @PrepaidPrincipalReceivable NVARCHAR(30)= 'PrepaidPrincipalReceivable';
        DECLARE @CapitalizedAdditionalFee NVARCHAR(30)= 'CapitalizedAdditionalFee';
        DECLARE @ReceiptCash NVARCHAR(20)= 'ReceiptCash';
        DECLARE @ReceiptNonCash NVARCHAR(20)= 'ReceiptNonCash';
        DECLARE @PostedStatus NVARCHAR(20)= 'Posted';
        DECLARE @ReceiptSourceTable NVARCHAR(20)= 'Receipt';
        DECLARE @ReversedStatus NVARCHAR(20)= 'Reversed';
        DECLARE @ReceiptRefundEntityType NVARCHAR(5)= 'RR';
        DECLARE @InactiveStatus NVARCHAR(10)= 'Inactive';
        DECLARE @UnappliedAR NVARCHAR(15)= 'UnAppliedAR';
        DECLARE @PayableCash NVARCHAR(20)= 'PayableCash';
		DECLARE @SyndicatedAR NVARCHAR(20) = 'SyndicatedAR'
		DECLARE @DueToThirdPartyAR NVARCHAR(25) ='DueToThirdPartyAR'
		DECLARE @PrePaidDueToThirdPartyAR NVARCHAR(30) = 'PrePaidDueToThirdPartyAR'
		DECLARE @LegalEntitiesCount BIGINT = ISNULL((SELECT COUNT(*) FROM @LegalEntityIds), 0)
		DECLARE @ContractsCount BIGINT = ISNULL((SELECT COUNT(*) FROM @ContractIds), 0)
		DECLARE @CustomersCount BIGINT = ISNULL((SELECT COUNT(*) FROM @CustomerIds), 0)
        /**************************************************************************************************************************/
        /*Create LoanDetails*/

        CREATE TABLE #LoanDetails
        (ContractId                   BIGINT, 
         LoanFinanceId                BIGINT, 
         CommencementDate             DATE, 
         MaturityDate                 DATE, 
         ContractType                 NVARCHAR(32), 
         InstrumentTypeId             BIGINT, 
         Status                       NVARCHAR(32), 
         HoldingStatus                NVARCHAR(28), 
         IsDSL                        BIT, 
         LegalEntityId                BIGINT, 
         CustomerId                   BIGINT, 
         SyndicationType              NVARCHAR(32), 
         ParticipatedPercentage       DECIMAL(16, 2), 
		 RetainedPortion			  DECIMAL(16, 2),
		 SoldNBVAmount				  DECIMAL(16, 2),
         SyndicationEffectiveDate     DATE, 
         IsMigratedContract           BIT, 
         IsChargedOff                 BIT, 
         IsNonAccrual                 BIT, 
         IsProgressLoan               BIT, 
         IsInInterim                  BIT, 
         PrincipalBalance             DECIMAL(16, 2), 
         TotalAmount                  DECIMAL(16, 2), 
         PrincipalBalanceIncomeExists BIT,
		 SyndicationId				  BIGINT,
		 SyndicationGLJournalId	      BIGINT,
		 SyndicationCreatedTIme	      DATETIMEOFFSET,
		 IsFromContract				  BIGINT,
		 IsAdvance					  BIT
        );

        /*Create BasicDetails*/

        CREATE TABLE #BasicDetails
        (ContractId                      BIGINT, 
         SyndicationType                 NVARCHAR(32), 
         CommencementDate                DATE, 
         IsChargedOff                    BIT, 
         MaxIncomeDate                   DATE, 
         MaxNonAccrualDate               DATE, 
         MaxIncomeDatePriorToSyndication DATE, 
         ChargeOffDate                   DATE
        );

        /*Create LoanTableValues*/

        CREATE TABLE #LoanTableValues
        (ContractId                                BIGINT, 
         TotalFinancedAmount_Amount                DECIMAL(18, 2) DEFAULT 0, 
         PrincipalBalance_Amount                   DECIMAL(18, 2) DEFAULT 0, 
         LoanPrincipalOSAR_Amount                  DECIMAL(18, 2) DEFAULT 0, 
         LoanInterestOSAR_Amount                   DECIMAL(18, 2) DEFAULT 0, 
         InterimInterestOSAR_Amount                DECIMAL(18, 2) DEFAULT 0, 
         IncomeAccrualBalance_Amount               DECIMAL(18, 2) DEFAULT 0, 
         ProgressFundings_Amount                   DECIMAL(18, 2) DEFAULT 0, 
         ProgressPaymentCredits_Amount             DECIMAL(18, 2) DEFAULT 0, 
         SyndicatedFixedTermReceivablesOSAR_Amount DECIMAL(18, 2) DEFAULT 0, 
         PrincipalBalanceAdjustment_Amount         DECIMAL(18, 2) DEFAULT 0, 
         PrepaidReceivables_Amount                 DECIMAL(18, 2) DEFAULT 0, 
         SyndicatedPrepaidReceivables_Amount       DECIMAL(18, 2) DEFAULT 0, 
         PrepaidInterest_Amount                    DECIMAL(18, 2) DEFAULT 0, 
         SuspendedIncomeBalance_Amount             DECIMAL(18, 2) DEFAULT 0, 
         UnappliedCash_Amount                      DECIMAL(18, 2) DEFAULT 0,
		 SyndicatedLoanInterestOSAR_Amount         DECIMAL(18, 2) DEFAULT 0,
		 SyndicatedLoanPrincipalOSAR_Amount		   DECIMAL(18, 2) DEFAULT 0
        );

        CREATE TABLE #BlendedItemTemp
        (ContractId             BIGINT, 
         BlendedItemId          BIGINT, 
         IsFAS91                BIT, 
         Type                   NVARCHAR(14), 
         BookRecognitionMode    NVARCHAR(40), 
         BlendedItemAmount      DECIMAL(18, 2), 
         SystemConfigType       NVARCHAR(46), 
         IncomeAmount           DECIMAL(16, 2), 
         SuspendedIncomeAmount  DECIMAL(16, 2), 
         IsReaccrualBlendedItem BIT
        );

        /*Create LoanIncomeScheduleTemp*/

        CREATE TABLE #LoanIncomeScheduleTemp
        (ContractId                BIGINT, 
         BeginNetBookValue_Amount  DECIMAL(16, 2), 
         EndNetBookValue_Amount    DECIMAL(16, 2), 
         PrincipalRepayment_Amount DECIMAL(16, 2), 
         PrincipalAdded_Amount     DECIMAL(16, 2), 
         NBVDifference_Amount      DECIMAL(16, 2), 
         IncomeDate                DATE, 
         IsNonAccrual              BIT, 
         IsLessorOwned             BIT, 
         IsAccounting              BIT, 
         IsSchedule                BIT, 
         InterestAccrued_Amount    DECIMAL(16, 2), 
         InterestRepayment_Amount  DECIMAL(16, 2), 
         IsGLPosted                BIT, 
         CommencementDate          DATE
        );

        /*Create LoanFinanceBasicTemp*/

        CREATE TABLE #LoanFinanceBasicTemp
        (ContractId                BIGINT, 
         Amount                    DECIMAL(16, 2), 
         FundingId                 BIGINT, 
         Type                      NVARCHAR(21), 
         PayableInvoiceId          BIGINT, 
         Status                    NVARCHAR(9), 
         OtherCostId               BIGINT, 
         AllocationMethod          NVARCHAR(50), 
         IsForeignCurrency         BIT, 
         InitialExchangeRate       DECIMAL(20, 10), 
         InvoiceDate               DATE, 
         SourceTransaction         NVARCHAR(20), 
         DisbursementRequestId     BIGINT, 
         DisbursementRequestStatus NVARCHAR(21), 
         IsOrigination             BIT, 
         PayableId                 BIGINT, 
         PayableSourceTable        NVARCHAR(50), 
         PayableStatus             NVARCHAR(50), 
         DRPayableIsActive         BIT, 
         PayableSourceId           BIGINT,
		 InvoiceTotalAmount		   DECIMAL(16,2)
        );

		/*Create ReceivableDetailsTemp*/
        CREATE TABLE #ReceivableDetailsTemp
        (ContractId                  BIGINT, 
         IncomeType                  NVARCHAR(16), 
         ReceivableId                BIGINT, 
         ReceivableType              NVARCHAR(25), 
         Balance_Amount              DECIMAL(16, 2), 
         Amount_Amount               DECIMAL(16, 2), 
         DueDate                     DATE, 
         FunderId                    BIGINT, 
         IsGLPosted                  BIT, 
         AccountingTreatment         NVARCHAR(12), 
         IsDummy                     BIT, 
         EffectiveBookBalance_Amount DECIMAL(16, 2), 
         PaymentStartDate            DATE, 
         PaymentEndDate              DATE, 
         PaymentDueDate              DATE, 
         PaymentType                 NVARCHAR(28),
		 PaymentScheduleId           BIGINT,
		 IsCollected                 BIT,
		 InvoiceComment				 NVARCHAR(400),
		 SourceId					 BIGINT,
		 SourceTable				 NVARCHAR(40),
		 DownPaymentEndDate			 DATE
        );
		CREATE TABLE #SyndicationDetailsTemp
        (ContractId                BIGINT, 
         RetainedPercentage        DECIMAL(18, 8), 
         ReceivableForTransferType NVARCHAR(32), 
         SyndicationEffectiveDate  DATE, 
         SyndicationId             BIGINT, 
         IsServiced                BIT, 
         IsCollected               BIT, 
         SyndicationAtInception    BIT
        );

        /*Create LoanPaydownTemp*/
        CREATE TABLE #LoanPaydownTemp
        (ContractId              BIGINT, 
         IsDailySensitive        BIT, 
         PaydownDate             DATE, 
         PaydownReason           NVARCHAR(30), 
         PrincipalBalance_Amount DECIMAL(16, 2), 
         PrincipalPaydown_Amount DECIMAL(16, 2), 
         AccruedInterest_Amount  DECIMAL(16, 2), 
         InterestPaydown_Amount  DECIMAL(16, 2), 
         Id                      BIGINT,
		 CreatedTime		     DATETIMEOFFSET,
        );

        /*Create FutureScheduledFundedTemp*/
        CREATE TABLE #FutureScheduledFundedTemp
        (ContractId  BIGINT, 
         FundingId   BIGINT, 
         Amount      DECIMAL(16, 2), 
         InvoiceDate DATE, 
         PaymentDate DATE, 
         DRStatus    NVARCHAR(25), 
         DueDate     DATE, 
         IsGLPosted  BIT
        );

		CREATE TABLE #PayableDetails
		(PayableId           BIGINT, 
		 ReceivableId        BIGINT, 
		 ContractId          BIGINT, 
		 Amount_Amount		 DECIMAL(16,2),
		 ReceivableType      NVARCHAR(50), 
		 CreationSourceTable NVARCHAR(20)
		);

		CREATE TABLE #NonCashSalesTax
		(LessorPortionNonCash   DECIMAL(16, 2), 
		 FunderPortionNonCash   DECIMAL(16, 2), 
		 FunderRemittingNonCash DECIMAL(16, 2), 
		 ContractId             BIGINT
		);
		
		CREATE TABLE #ChargeOffDetails
		(ContractId                  BIGINT, 
		 ChargeOffExpense_LC_Table   DECIMAL(16, 2), 
		 ChargeOffExpense_NLC_Table  DECIMAL(16, 2), 
		 ChargeOffRecovery_LC_Table  DECIMAL(16, 2), 
		 ChargeOffRecovery_NLC_Table DECIMAL(16, 2),
		 ChargeOffExpense            DECIMAL(16, 2),
		 ChargeOffRecovery           DECIMAL(16, 2),
		 GainOnRecovery_LC_Table	 DECIMAL(16, 2),
		 GainOnRecovery_NLC_Table	 DECIMAL(16, 2)
		);

		CREATE TABLE #RefundGLJournalIds
		(ContractId  BIGINT NOT NULL, 
		 GLJournalId BIGINT NOT NULL, 
		 EntityType  NVARCHAR(20) NOT NULL,
		 Id			 BIGINT NOT NULL,
		 Amount		 DECIMAL(16, 2) NOT NULL,
		 IsReversal  BIT
		);

		CREATE TABLE #RefundTableValue
		(ContractId       BIGINT NOT NULL, 
		 PaymentVoucherId BIGINT NOT NULL, 
		 Amount           DECIMAL(16, 2) NOT NULL
		);

        /**************************************************************************************************************************/
        /*Insert LoanDetails*/

        INSERT INTO #LoanDetails
        SELECT Contract.Id AS ContractId
             , Loan.Id AS LoanFinanceId
             , Loan.CommencementDate AS CommencementDate
             , Loan.MaturityDate AS MaturityDate
             , Contract.ContractType AS ContractType
             , Loan.InstrumentTypeId AS InstrumentTypeId
             , Loan.Status AS Status
             , Loan.HoldingStatus AS HoldingStatus
             , Loan.IsDailySensitive AS IsDSL
             , Loan.LegalEntityId AS LegalEntityId
             , Loan.CustomerId AS CustomerId
             , Contract.SyndicationType AS SyndicationType
             , 100 - ISNULL(Syndication.RetainedPercentage, 0) AS ParticipatedPercentage
			 , ISNULL(Syndication.RetainedPercentage / 100, 1) AS RetainedPortion
			 , ISNULL(Syndication.SoldNBV_Amount, 0.00) AS SoldNBVAmount
             , Syndication.EffectiveDate AS SyndicationEffectiveDate
             , CASE
                   WHEN Contract.u_ConversionSource = @MigrationSource
                   THEN CAST(1 AS BIT)
                   ELSE CAST(0 AS BIT)
               END AS IsMigratedContract
             , CASE
                   WHEN Contract.ChargeOffStatus = @Unknown
                   THEN CAST(0 AS BIT)
                   ELSE CAST(1 AS BIT)
               END AS IsChargedOff
             , Contract.IsNonAccrual
             , CASE
                   WHEN Contract.ContractType = @ProgressLoanContractType
                   THEN CAST(1 AS BIT)
                   ELSE CAST(0 AS BIT)
               END AS IsProgressLoan
             , CASE
                   WHEN Loan.InterimBillingType != @Unknown
                   THEN CAST(1 AS BIT)
                   ELSE CAST(0 AS BIT)
               END AS IsInInterim
             , 0.00
             , 0.00
             , 0
			 , Syndication.Id AS SyndicationId
			 , Syndication.SyndicationGLJournalId AS SyndicationGLJournalId
			 , Syndication.CreatedTime
			 , Syndication.IsFromContract
			 , Loan.IsAdvance
        FROM Contracts Contract
             JOIN LoanFinances Loan ON Contract.Id = Loan.ContractId
             LEFT JOIN ReceivableForTransfers Syndication ON Syndication.ContractId = Contract.Id
                                                             AND Syndication.ApprovalStatus = 'Approved'
        WHERE Loan.IsCurrent = @True
              AND Loan.Status NOT IN ('Cancelled', 'Uncommenced')
 			  AND @True = (CASE 
							   WHEN @LegalEntitiesCount > 0 AND EXISTS (SELECT Id FROM @LegalEntityIds WHERE Id = Loan.LegalEntityId) THEN @True
							   WHEN @LegalEntitiesCount = 0 THEN @True ELSE @False END)
			  AND @True = (CASE 
							   WHEN @CustomersCount > 0 AND EXISTS (SELECT Id FROM @CustomerIds WHERE Id = Loan.CustomerId) THEN @True
							   WHEN @CustomersCount = 0 THEN @True ELSE @False END)
			  AND @True = (CASE 
							   WHEN @ContractsCount > 0 AND EXISTS (SELECT Id FROM @ContractIds WHERE Id = Loan.ContractId) THEN @True
							   WHEN @ContractsCount = 0 THEN @True ELSE @False END)
 
		CREATE NONCLUSTERED INDEX IX_Id ON #LoanDetails(ContractId);
	 
        INSERT INTO #BasicDetails
        SELECT ContractId
             , SyndicationType
             , CommencementDate
             , IsChargedOff
             , NULL MaxIncomeDate
             , NULL MaxNonAccrualDate
             , NULL MaxIncomeDatePriorToSyndication
             , NULL ChargeOffDate
        FROM #LoanDetails;

        CREATE NONCLUSTERED INDEX IX_Id ON #BasicDetails(ContractId);

        /*Insert LoanTableValues*/
		
        INSERT INTO #LoanTableValues(ContractId)
        SELECT ContractId
        FROM #BasicDetails;

        CREATE NONCLUSTERED INDEX IX_Id ON #LoanTableValues(ContractId);
		
        /*Insert LoanIncomeScheduleTemp*/
			
        IF EXISTS (SELECT 1 FROM #LoanDetails)
        BEGIN
                INSERT INTO #LoanIncomeScheduleTemp
                SELECT Contract.ContractId
                     , IncomeSched.BeginNetBookValue_Amount
                     , IncomeSched.EndNetBookValue_Amount
                     , IncomeSched.PrincipalRepayment_Amount
                     , IncomeSched.PrincipalAdded_Amount
                     , CASE
                           WHEN IncomeSched.IsAccounting = 1 AND IncomeSched.IsLessorOwned = 1 AND IncomeSched.IsSchedule = 1
                           THEN ISNULL(IncomeSched.PrincipalAdded_Amount, 0.000) + ISNULL(IncomeSched.BeginNetBookValue_Amount, 0.000) + ISNULL(IncomeSched.CapitalizedInterest_Amount, 0.00)
						   --IIF(IncomeSched.CompoundDate IS NULL, ISNULL(IncomeSched.CapitalizedInterest_Amount, 0.00), 0.00) 
						   - ISNULL(IncomeSched.EndNetBookValue_Amount, 0.000) - ISNULL(IncomeSched.PrincipalRepayment_Amount, 0.000)
                           ELSE 0.00
                       END NBVDifference_Amount
                     , IncomeSched.IncomeDate
                     , IncomeSched.IsNonAccrual
                     , IncomeSched.IsLessorOwned
                     , IncomeSched.IsAccounting
                     , IncomeSched.IsSchedule
                     , IncomeSched.InterestAccrued_Amount
                     , IncomeSched.InterestPayment_Amount
                     , IncomeSched.IsGLPosted
                     , Loan.CommencementDate
                FROM #LoanDetails Contract
                     JOIN LoanFinances Loan ON Contract.ContractId = Loan.ContractId
                     JOIN LoanIncomeSchedules IncomeSched ON Loan.Id = IncomeSched.LoanFinanceId
                WHERE IncomeSched.IsSchedule = 1
                      OR IncomeSched.IsAccounting = 1;
        END;

        CREATE NONCLUSTERED INDEX IX_Id ON #LoanIncomeScheduleTemp(ContractId);

        /*Insert LoanFinanceBasicTemp*/

        IF EXISTS(SELECT 1 FROM #LoanDetails)
        BEGIN
                INSERT INTO #LoanFinanceBasicTemp
                SELECT DISTINCT 
                       Contract.ContractId
                     , InvoiceOtherCost.Amount_Amount AS Amount
                     , Funding.FundingId
                     , Funding.Type
                     , Invoice.Id AS PayableInvoiceId
                     , Invoice.Status
                     , InvoiceOtherCost.Id AS OtherCostId
                     , InvoiceOtherCost.AllocationMethod AS AllocationMethod
                     , Invoice.IsForeignCurrency
                     , Invoice.InitialExchangeRate
                     , Invoice.InvoiceDate
                     , Invoice.SourceTransaction
                     , DR.Id AS DisbursementRequestId
                     , DR.Status AS DisbursementRequestStatus
                     , CASE
                           WHEN Funding.Type = @Origination
                           THEN 1
                           ELSE 0
                       END AS IsOrigination
                     , Payables.Id AS PayableId
                     , Payables.SourceTable AS PayableSourceTable
                     , Payables.Status AS PayableStatus
                     , DRPayable.IsActive AS DRPayableIsActive
                     , Payables.SourceId AS PayableSourceId
					 , Invoice.InvoiceTotal_Amount
                FROM #LoanDetails Contract
                     JOIN LoanFundings Funding ON Contract.LoanFinanceId = Funding.LoanFinanceId
                                                  AND Funding.IsActive = 1
                     JOIN PayableInvoices Invoice ON Funding.FundingId = Invoice.Id
                     JOIN PayableInvoiceOtherCosts InvoiceOtherCost ON Invoice.Id = InvoiceOtherCost.PayableInvoiceId
                                                                       AND InvoiceOtherCost.IsActive = 1
                     LEFT JOIN Payables ON InvoiceOtherCost.Id = Payables.SourceId
                                           AND Payables.SourceTable = @PayableInvoiceOtherCost
                     LEFT JOIN DisbursementRequestInvoices DRInvoice ON DRInvoice.InvoiceId = Invoice.Id
                     LEFT JOIN DisbursementRequests DR ON DRInvoice.DisbursementRequestId = DR.Id
                     LEFT JOIN DisbursementRequestPayables DRPayable ON DR.Id = DRPayable.DisbursementRequestId
                WHERE InvoiceOtherCost.AllocationMethod = @LoanDisbursementAllocationMethod;
        END;
        
		CREATE NONCLUSTERED INDEX IX_Id ON #LoanFinanceBasicTemp(ContractId);

        /*Insert ReceivableDetailsTemp*/

        IF EXISTS(SELECT 1 FROM #LoanDetails)
            BEGIN
                INSERT INTO #ReceivableDetailsTemp
                SELECT Contract.ContractId
                     , Receivable.IncomeType
                     , Receivable.Id AS ReceivableId
                     , Type.Name AS ReceivableType
                     , Receivable.TotalBalance_Amount
                     , Receivable.TotalAmount_Amount
                     , Receivable.DueDate
                     , Receivable.FunderId
                     , Receivable.IsGLPosted
                     , Code.AccountingTreatment
                     , Receivable.IsDummy
                     , Receivable.TotalBookBalance_Amount
                     , PaymentSched.StartDate AS PaymentStartDate
                     , PaymentSched.EndDate AS PaymentEndDate
                     , PaymentSched.DueDate AS PaymentDueDate
                     , PaymentSched.PaymentType AS PaymentType
					 , Receivable.PaymentScheduleId AS PaymentScheduleId
					 , Receivable.IsCollected
					 , Receivable.InvoiceComment
					 , Receivable.SourceId
					 , Receivable.SourceTable
					 , CASE WHEN PaymentSched.PaymentType = 'DownPayment'
							THEN Receivable.DueDate
							ELSE PaymentSched.EndDate 
					   END AS DownPaymentEndDate
                FROM #LoanDetails Contract
                     JOIN Receivables Receivable ON Contract.ContractId = Receivable.EntityId
                                                    AND Receivable.EntityType = @ContractEntityType
                                                    AND Receivable.IsActive = 1
                     JOIN ReceivableCodes Code ON Receivable.ReceivableCodeId = Code.Id
                     JOIN ReceivableTypes Type ON Code.ReceivableTypeId = Type.Id
                     LEFT JOIN LoanPaymentSchedules PaymentSched ON Receivable.PaymentScheduleId = PaymentSched.Id
                                                                    AND Receivable.SourceTable != @SundryRecurring
        END;

        CREATE NONCLUSTERED INDEX IX_Id ON #ReceivableDetailsTemp(ContractId);

        /*Insert LoanPaydownTemp*/

        IF EXISTS(SELECT 1 FROM #LoanDetails)
        BEGIN
                INSERT INTO #LoanPaydownTemp
                SELECT Contract.ContractId
                     , Loan.IsDailySensitive
                     , LoanPaydown.PaydownDate
                     , LoanPaydown.PaydownReason
                     , LoanPaydown.PrincipalBalance_Amount
                     , LoanPaydown.PrincipalPaydown_Amount
                     , LoanPaydown.AccruedInterest_Amount
                     , LoanPaydown.InterestPaydown_Amount
                     , LoanPaydown.Id
					 , LoanPaydown.CreatedTime
                FROM #LoanDetails Contract
                     JOIN LoanFinances Loan ON Contract.ContractId = Loan.ContractId
                     JOIN LoanPaydowns LoanPaydown ON Loan.Id = LoanPaydown.LoanFinanceId
                                                      AND LoanPaydown.Status = @ActiveStatus;
        END;

        CREATE NONCLUSTERED INDEX IX_Id ON #LoanPaydownTemp(ContractId);


		SELECT ContractId, ReceivableId
		INTO #SyndicationProceedsReceivables
		FROM #ReceivableDetailsTemp
		WHERE IsGLPosted = 1
		AND IsCollected = 1
		AND InvoiceComment = 'Syndication Actual Proceeds';

		CREATE NONCLUSTERED INDEX IX_Id ON #SyndicationProceedsReceivables(ContractId);
		CREATE NONCLUSTERED INDEX Receivable_Id ON #SyndicationProceedsReceivables(ReceivableId);

		SELECT ContractId, SUM(Amount_Amount) AS Amount
		INTO #SyndicationProceedsAmount
		FROM #ReceivableDetailsTemp
		WHERE IsGLPosted = 1
		AND IsCollected = 1
		AND InvoiceComment = 'Syndication Actual Proceeds'
		GROUP BY ContractId;

		SELECT ContractId,SyndicationId
		INTO #SyndicationFunderRemitting
		FROM #LoanDetails 
		WHERE SyndicationType <> @None
		AND SyndicationId IN (SELECT ReceivableForTransferId FROM ReceivableForTransferFundingSources WHERE SalesTaxResponsibility ='RemitOnly');

		CREATE NONCLUSTERED INDEX IX_Id ON #SyndicationFunderRemitting(ContractId);

		SELECT temp.ContractId
			 , SUM(CASE
					   WHEN temp.FunderId IS NULL
							 AND rt.IsGLPosted = 1
					   THEN rt.Amount_Amount
					   ELSE 0.00
				   END) AS LessorPortion
			 , SUM(CASE
					   WHEN temp.FunderId IS NULL
							AND rt.IsGLPosted = 1
							AND Contract.IsNonAccrual = 0
					   THEN rt.Balance_Amount
					   ELSE 0.00
				   END) AS LessorRemittingAccrualOSAR
			 , SUM(CASE
					   WHEN temp.FunderId IS NULL
							AND rt.IsGLPosted = 1
							AND Contract.IsNonAccrual = 1
					   THEN rt.EffectiveBalance_Amount
					   ELSE 0.00
				   END) AS LessorRemittingNonAccrualOSAR
			 , SUM(CASE
					   WHEN temp.FunderId IS NULL
							AND rt.IsGLPosted = 0
							AND Contract.IsNonAccrual = 0
							AND rt.Amount_Amount != rt.Balance_Amount
					   THEN rt.Amount_Amount - rt.Balance_Amount
					   ELSE 0.00
				   END) AS LessorRemittingPrepaidAccrual
			 , SUM(CASE
					   WHEN temp.FunderId IS NULL
							AND rt.IsGLPosted = 0
							AND Contract.IsNonAccrual = 1
							AND rt.Amount_Amount != rt.EffectiveBalance_Amount
					   THEN rt.Amount_Amount - rt.EffectiveBalance_Amount
					   ELSE 0.00
				   END) AS LessorRemittingPrepaidNonAccrual
			 , SUM(CASE
					   WHEN Funder.ContractId IS NULL
							AND temp.FunderId IS NOT NULL
							AND rt.IsGLPosted = 1
							AND Contract.IsNonAccrual = 0
					   THEN rt.Balance_Amount
					   ELSE 0.00
				   END) AS LessorRemittingAccrualOSARFunderPortion
			 , SUM(CASE
					   WHEN Funder.ContractId IS NULL
							AND temp.FunderId IS NOT NULL
							AND rt.IsGLPosted = 1
							AND Contract.IsNonAccrual = 1
					   THEN rt.EffectiveBalance_Amount
					   ELSE 0.00
				   END) AS LessorRemittingNonAccrualOSARFunderPortion
			 , SUM(CASE
					   WHEN temp.FunderId IS NOT NULL
						    AND Funder.ContractId IS NULL
							AND rt.IsGLPosted = 1
					   THEN rt.Amount_Amount
					   ELSE 0.00
				   END) AS LessorRemittingFunderPortion
			 , SUM(CASE
					   WHEN temp.FunderId IS NOT NULL
							AND Funder.ContractId IS NULL
							AND rt.IsGLPosted = 0
							AND Contract.IsNonAccrual = 0
							AND rt.Amount_Amount != rt.Balance_Amount
					   THEN rt.Amount_Amount - rt.Balance_Amount
					   ELSE 0.00
				   END) AS LessorRemittingPrepaidAccrualFunderPortion
			 , SUM(CASE
					   WHEN temp.FunderId IS NOT NULL
							AND Funder.ContractId IS NULL
							AND rt.IsGLPosted = 0
							AND Contract.IsNonAccrual = 1
							AND rt.Amount_Amount != rt.EffectiveBalance_Amount
					   THEN rt.Amount_Amount - rt.EffectiveBalance_Amount
					   ELSE 0.00
				   END) AS LessorRemittingPrepaidNonAccrualFunderPortion
			 , SUM(CASE
					   WHEN Funder.ContractId IS NOT NULL
							AND temp.FunderId IS NOT NULL
							AND rt.IsGLPosted = 1
					   THEN rt.Amount_Amount
					   ELSE 0.00
				   END) AS FunderRemitting
			 , SUM(CASE
					   WHEN Funder.ContractId IS NOT NULL
							AND temp.FunderId IS NOT NULL
							AND rt.IsGLPosted = 1
							AND Contract.IsNonAccrual = 0
					   THEN rt.Balance_Amount
					   ELSE 0.00
				   END) AS FunderRemittingAccrualOSAR
			 , SUM(CASE
					   WHEN Funder.ContractId IS NOT NULL
							AND temp.FunderId IS NOT NULL
							AND rt.IsGLPosted = 1
							AND Contract.IsNonAccrual = 1
					   THEN rt.EffectiveBalance_Amount
					   ELSE 0.00
				   END) AS FunderRemittingNonAccrualOSAR
			 , SUM(CASE
					   WHEN Funder.ContractId IS NOT NULL
							AND temp.FunderId IS NOT NULL
							AND rt.IsGLPosted = 0
							AND Contract.IsNonAccrual = 0
							AND rt.Amount_Amount != rt.Balance_Amount
					   THEN rt.Amount_Amount - rt.Balance_Amount
					   ELSE 0.00
				   END) AS FunderRemittingPrepaidAccrual
			 , SUM(CASE
					   WHEN Funder.ContractId IS NOT NULL
							AND temp.FunderId IS NOT NULL
							AND rt.IsGLPosted = 0
							AND Contract.IsNonAccrual = 1
							AND rt.Amount_Amount != rt.EffectiveBalance_Amount
					   THEN rt.Amount_Amount - rt.EffectiveBalance_Amount
					   ELSE 0.00
				   END) AS FunderRemittingPrepaidNonAccrual
		INTO #ReceivableTaxDetails
		FROM #ReceivableDetailsTemp temp
			 INNER JOIN ReceivableTaxes rt ON rt.ReceivableId = temp.ReceivableId
			 INNER JOIN #LoanDetails contract ON temp.ContractId = Contract.ContractId
			 LEFT JOIN #SyndicationFunderRemitting Funder ON temp.ContractId = Funder.ContractId
		WHERE rt.IsActive = 1
			  AND rt.IsDummy = 0
			  AND temp.IsCollected = 1
		GROUP BY temp.ContractId;

		CREATE NONCLUSTERED INDEX IX_Id ON #ReceivableTaxDetails(ContractId);

		DECLARE @Sql nvarchar(max) ='';

		IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ReceivableTaxes' AND COLUMN_NAME = 'IsCashBased')
		BEGIN
		SET @Sql = '
		SELECT SUM(CASE WHEN temp.FunderId IS NULL THEN rard.TaxApplied_Amount ELSE 0.00 END) AS LessorPortionNonCash
			  , SUM(CASE WHEN temp.FunderId IS NOT NULL AND Funder.ContractId IS NULL THEN rard.TaxApplied_Amount ELSE 0.00 END) AS FunderPortionNonCash
			  , SUM(CASE WHEN temp.FunderId IS NOT NULL AND Funder.ContractId IS NOT NULL THEN rard.TaxApplied_Amount ELSE 0.00 END) AS FunderRemittingNonCash
			  , temp.ContractId
		FROM #ReceivableDetailsTemp temp
		INNER JOIN ReceivableTaxes rt ON rt.ReceivableId = temp.ReceivableId
		INNER JOIN ReceivableDetails rd on rd.ReceivableId = temp.ReceivableId
		INNER JOIN ReceiptApplicationReceivableDetails rard on rard.ReceivableDetailId = rd.Id
		INNER JOIN ReceiptApplications ra on rard.ReceiptApplicationId = ra.Id
		INNER JOIN Receipts receipt ON receipt.Id = ra.ReceiptId
		LEFT JOIN #SyndicationFunderRemitting Funder ON temp.ContractId = Funder.ContractId
		WHERE rt.IsActive = 1
			  AND rt.IsCashBased = 1
			  AND rt.IsDummy = 0
			  AND temp.IsCollected = 1
			  AND receipt.ReceiptClassification = ''NonCash''
			  AND receipt.Status IN (''Completed'', ''Posted'')
		GROUP BY temp.ContractId'

		INSERT INTO #NonCashSalesTax(LessorPortionNonCash, FunderPortionNonCash, FunderRemittingNonCash, ContractId)
		EXEC (@Sql)

		CREATE NONCLUSTERED INDEX IX_Id ON #NonCashSalesTax(ContractId);

		END

        /*Update BasicDetails*/

		
		SELECT Receivable.ContractId
             , MAX(Receivable.DownPaymentEndDate) AS EndDate
		INTO #MaxReceivablePaymentEndDate
        FROM #ReceivableDetailsTemp Receivable
             JOIN #LoanDetails ON Receivable.ContractId = #LoanDetails.ContractId
        WHERE Receivable.IsGLPosted = 1
              AND Receivable.DownPaymentEndDate IS NOT NULL
         GROUP BY Receivable.ContractId;


		 CREATE NONCLUSTERED INDEX IX_Id ON #MaxReceivablePaymentEndDate(ContractId);

		UPDATE #BasicDetails SET  MaxIncomeDate = MaxIncomeDateTemp.MaxIncomeDate
         FROM #BasicDetails Contract
         JOIN
             (
                 SELECT IncomeSched.ContractId
                      , MAX(IncomeSched.IncomeDate) AS MaxIncomeDate
                 FROM #LoanIncomeScheduleTemp IncomeSched
				 JOIN #MaxReceivablePaymentEndDate receivable ON receivable.ContractId = IncomeSched.ContractId
																 AND IncomeSched.IsSchedule = 1
																 AND receivable.EndDate >= IncomeSched.IncomeDate
                 GROUP BY IncomeSched.ContractId
             ) AS MaxIncomeDateTemp ON Contract.ContractId = MaxIncomeDateTemp.ContractId;


        UPDATE #BasicDetails
          SET 
              MaxNonAccrualDate = NonAccrual.NonAccrualDate
        FROM #BasicDetails Contract
             JOIN
        (
            SELECT Contract.ContractId
                 , MAX(NonAccrualContract.NonAccrualDate) AS NonAccrualDate
            FROM #BasicDetails Contract
                 JOIN NonAccrualContracts NonAccrualContract ON Contract.ContractId = NonAccrualContract.ContractId
                                                                AND NonAccrualContract.IsActive = 1
                 JOIN NonAccruals NonAccrual ON NonAccrualContract.NonAccrualId = NonAccrual.Id
                                                AND NonAccrual.Status = @ApprovalStatus
            GROUP BY Contract.ContractId
        ) AS NonAccrual ON Contract.ContractId = NonAccrual.ContractId;

        UPDATE #BasicDetails
          SET 
              ChargeOffDate = ChargeOff.ChargeOffDate
        FROM #BasicDetails Contract
             JOIN ChargeOffs ChargeOff ON Contract.ContractId = ChargeOff.ContractId
                                          AND ChargeOff.IsActive = 1
                                          AND ChargeOff.IsRecovery = 0
		WHERE ChargeOff.Status = 'Approved';

        /*Insert SyndicationDetailsTemp*/


		SELECT *
		INTO #MinNonServicingDate
		FROM
		(
			SELECT Contract.ContractId
					, MIN(ServicingDetail.EffectiveDate) AS EffectiveDate
			FROM #BasicDetails Contract
					JOIN ReceivableForTransfers ReceivableForTransfer ON Contract.ContractId = ReceivableForTransfer.ContractId
																		AND ReceivableForTransfer.ApprovalStatus = @ApprovalStatus
					JOIN ReceivableForTransferServicings ServicingDetail ON ReceivableForTransfer.Id = ServicingDetail.ReceivableForTransferId
																			AND ServicingDetail.IsActive = 1
					WHERE ServicingDetail.IsServiced = 0
			GROUP BY Contract.ContractId
		) AS t;
		
		CREATE NONCLUSTERED INDEX IX_Id ON #MinNonServicingDate(ContractId);

        IF EXISTS
        (
            SELECT *
            FROM #BasicDetails
            WHERE SyndicationType <> @None
        )
            BEGIN
                WITH CTE_MaxServicingEffectiveDate
                     AS (SELECT Contract.ContractId
                              , MAX(ServicingDetail.EffectiveDate) AS EffectiveDate
                              , MAX(ReceivableForTransfer.Id) ReceivableForTransferId
                         FROM #BasicDetails Contract
                              JOIN ReceivableForTransfers ReceivableForTransfer ON Contract.ContractId = ReceivableForTransfer.ContractId
                                                                                   AND ReceivableForTransfer.ApprovalStatus = @ApprovalStatus
                              JOIN ReceivableForTransferServicings ServicingDetail ON ReceivableForTransfer.Id = ServicingDetail.ReceivableForTransferId
                                                                                      AND ServicingDetail.IsActive = 1
                         GROUP BY Contract.ContractId)
					 INSERT INTO #SyndicationDetailsTemp
                     SELECT Contract.ContractId
                          , ReceivableForTransfer.RetainedPercentage
                          , ReceivableForTransfer.ReceivableForTransferType
                          , ReceivableForTransfer.EffectiveDate AS SyndicationEffectiveDate
                          , ReceivableForTransfer.Id AS SyndicationId
                          , ServicingDetail.IsServiced
                          , ServicingDetail.IsCollected
                          , CASE
                                WHEN ReceivableForTransfer.EffectiveDate = Contract.CommencementDate
                                THEN 1
                                ELSE 0
                            END AS SyndicationAtInception
                     FROM #BasicDetails Contract
                          JOIN CTE_MaxServicingEffectiveDate LatestServicingInfo ON LatestServicingInfo.ContractId = Contract.ContractId
                          JOIN ReceivableForTransfers ReceivableForTransfer ON LatestServicingInfo.ReceivableForTransferId = ReceivableForTransfer.Id
                          JOIN ReceivableForTransferServicings ServicingDetail ON ReceivableForTransfer.Id = ServicingDetail.ReceivableForTransferId
                                                                                  AND ServicingDetail.EffectiveDate = LatestServicingInfo.EffectiveDate
                                                                                  AND ServicingDetail.IsActive = 1;
        END;

        INSERT INTO #BlendedItemTemp
        SELECT Contract.ContractId
             , BlendedItem.Id AS BlendedItemId
             , BlendedItem.IsFAS91
             , BlendedItem.Type
             , BlendedItem.BookRecognitionMode
             , BlendedItem.Amount_Amount AS BlendedItemAmount
             , BlendedItem.SystemConfigType
             , 0 AS IncomeAmount
             , 0 AS SuspendedIncomeAmount
             , CAST(0 AS BIT) AS IsReaccrualBlendedItem
        FROM #LoanDetails Contract
             JOIN LoanFinances Loan ON Contract.ContractId = Loan.ContractId
                                       AND Loan.IsCurrent = 1
             JOIN LoanBlendedItems ContractBlendedItem ON Loan.Id = ContractBlendedItem.LoanFinanceId
             JOIN BlendedItems BlendedItem ON ContractBlendedItem.BlendedItemId = BlendedItem.Id
                                              AND BlendedItem.IsActive = 1
             LEFT JOIN #SyndicationDetailsTemp SyndicationDetail ON Contract.ContractId = SyndicationDetail.ContractId
        WHERE SyndicationDetail.SyndicationId IS NULL
              OR SyndicationDetail.RetainedPercentage > 0.0
			   OR (SyndicationDetail.ReceivableForTransferType = @FullSale AND BlendedItem.DueDate <= SyndicationDetail.SyndicationEffectiveDate);

        UPDATE #BlendedItemTemp
          SET 
              IsReaccrualBlendedItem = CAST(1 AS BIT)
        FROM #BlendedItemTemp BlendedItem
        WHERE BlendedItem.SystemConfigType IN
        (
            SELECT *
            FROM dbo.ConvertCSVToStringTable(@ReAccrualSystemConfigType, ',')
        );

			UPDATE temp
			  SET 
				  IncomeAmount = CASE WHEN t.ReAccrualBlendedIncome != 0.00 
									  THEN t.ReAccrualBlendedIncome 
									  ELSE t.IncomeAmount
								  END
				, SuspendedIncomeAmount = t.SuspendedIncomeAmount
			FROM #BlendedItemTemp temp
				 INNER JOIN
			(
				SELECT BlendedItem.BlendedItemId
					 , SUM(IncomeSched.Income_Amount) AS IncomeAmount
					 , SUM(CASE
							   WHEN IncomeSched.IsNonAccrual = 1
							   THEN IncomeSched.Income_Amount
							   ELSE 0
						   END) AS SuspendedIncomeAmount
					 , SUM(CASE
							   WHEN BlendedItem.IsReaccrualBlendedItem = 1
									AND BlendedItem.SystemConfigType != @ReAccrualRentalIncome
							   THEN IncomeSched.Income_Amount
							   ELSE 0
						   END) AS ReAccrualBlendedIncome
				FROM #BlendedItemTemp BlendedItem
					 INNER JOIN BlendedIncomeSchedules IncomeSched ON BlendedItem.BlendedItemId = IncomeSched.BlendedItemId
				WHERE IncomeSched.IsAccounting = 1
					  AND IncomeSched.PostDate IS NOT NULL
				GROUP BY BlendedItem.BlendedItemId
			) AS t ON t.BlendedItemId = temp.BlendedItemId;

        /*Insert FutureScheduledFundedTemp*/

        IF EXISTS(SELECT 1 FROM #LoanFinanceBasicTemp WHERE IsOrigination = 0)
            BEGIN
                WITH CTE_FutureScheduleReceivableDetails
                     AS (SELECT LoanTemp.ContractId
                              , LoanTemp.FundingId
                              , MAX(ReceivableDetail.PaymentDueDate) AS DueDate
                         FROM
                         (
                             SELECT *
                             FROM #LoanFinanceBasicTemp
                             WHERE IsOrigination = 0
                         ) LoanTemp
                         JOIN #ReceivableDetailsTemp ReceivableDetail ON LoanTemp.ContractId = ReceivableDetail.ContractId
                                                                         AND LoanTemp.InvoiceDate >= ReceivableDetail.PaymentStartDate
                                                                         AND LoanTemp.InvoiceDate <= ReceivableDetail.PaymentEndDate
                         GROUP BY LoanTemp.ContractId
                                , LoanTemp.FundingId)
                     INSERT INTO #FutureScheduledFundedTemp
                     SELECT LoanTemp.ContractId
                          , LoanTemp.FundingId
                          , LoanTemp.Amount
                          , DATEADD(DAY, -1, LoanTemp.InvoiceDate) AS InvoiceDate
                          , DRPayable.RequestedPaymentDate AS PaymentDate
                          , DR.Status DRStatus
                          , ReceivableDetail.DueDate
                          , CAST(0 AS BIT) AS IsGLPosted
                     FROM
                     (
                         SELECT *
                         FROM #LoanFinanceBasicTemp
                         WHERE IsOrigination = 0
                     ) LoanTemp
                     LEFT JOIN CTE_FutureScheduleReceivableDetails AS ReceivableDetail ON LoanTemp.ContractId = ReceivableDetail.ContractId
                                                                                          AND LoanTemp.FundingId = ReceivableDetail.FundingId
                     LEFT JOIN DisbursementRequestInvoices DRInvoice ON LoanTemp.PayableInvoiceId = DRInvoice.InvoiceId
                                                                        AND DRInvoice.IsActive = 1
                     LEFT JOIN DisbursementRequestPaymentDetails DRPayable ON DRInvoice.DisbursementRequestId = DRPayable.DisbursementRequestId
                                                                              AND DRPayable.IsActive = 1
                     LEFT JOIN DisbursementRequests DR ON DRPayable.DisbursementRequestId = DR.Id;
                UPDATE #FutureScheduledFundedTemp
                  SET 
                      IsGLPosted = ReceivableDetail.IsGLPosted
                FROM #FutureScheduledFundedTemp FSRDT
                     JOIN #ReceivableDetailsTemp ReceivableDetail ON FSRDT.ContractId = ReceivableDetail.ContractId
                                                                     AND FSRDT.DueDate = ReceivableDetail.DueDate;
        END;

        /*Update LoanDetails*/
        IF EXISTS(SELECT 1 FROM #LoanDetails)
            BEGIN
                UPDATE #LoanDetails
                  SET 
                      PrincipalBalance = EndNBVInfo.EndNetBookValue_Amount
                    , PrincipalBalanceIncomeExists = CAST(1 AS BIT)
                FROM #LoanDetails Loan
                     JOIN
                (
                    SELECT IncomeSched.ContractId
                         , SUM(CASE WHEN Contract.MaxIncomeDate < ld.SyndicationEffectiveDate
								    THEN IncomeSched.EndNetBookValue_Amount - ld.SoldNBVAmount
									ELSE IncomeSched.EndNetBookValue_Amount
								END) EndNetBookValue_Amount
                    FROM #LoanIncomeScheduleTemp IncomeSched
						 JOIN #LoanDetails ld ON ld.ContractId = IncomeSched.ContractId
                         JOIN #BasicDetails Contract ON Contract.ContractId = IncomeSched.ContractId
					WHERE IncomeSched.IncomeDate = Contract.MaxIncomeDate
                          AND IncomeSched.IsLessorOwned = 1
                          AND IncomeSched.IsSchedule = 1
                    GROUP BY IncomeSched.ContractId
                ) AS EndNBVInfo ON Loan.ContractId = EndNBVInfo.ContractId;

                UPDATE #LoanDetails
                  SET 
                      TotalAmount = LoanDisbursementInfo.TotalAmount - Loan.SoldNBVAmount
                FROM #LoanDetails Loan
                     JOIN
                (
                    SELECT LoanTemp.ContractId
                         , SUM(CASE
                                   WHEN(LoanInnerQuery.IsMigratedContract = 0
                                        AND LoanTemp.DisbursementRequestStatus != @InActive
                                        AND LoanTemp.PayableStatus != @InActive
                                        OR LoanInnerQuery.IsMigratedContract = 1)
                                       AND LoanTemp.IsForeignCurrency = 0
                                   THEN LoanTemp.Amount
                                   WHEN(LoanInnerQuery.IsMigratedContract = 0
                                        AND LoanTemp.DisbursementRequestStatus != @InActive
                                        OR LoanInnerQuery.IsMigratedContract = 1)
                                       AND LoanTemp.IsForeignCurrency = 1
                                   THEN LoanTemp.Amount * LoanTemp.InitialExchangeRate
                                   ELSE 0.00
                               END) TotalAmount
                    --SUM(CASE WHEN LoanTemp.IsForeignCurrency = 0 THEN (LoanTemp.Amount) ELSE (LoanTemp.Amount * LoanTemp.InitialExchangeRate) END) TotalAmount
                    FROM #LoanFinanceBasicTemp LoanTemp
                         LEFT JOIN #LoanDetails LoanInnerQuery ON LoanInnerQuery.ContractId = LoanTemp.ContractId
                    WHERE LoanTemp.Status = @CompletedStatus
                          AND LoanTemp.IsOrigination = 1
                          AND LoanTemp.AllocationMethod = @LoanDisbursementAllocationMethod
                    GROUP BY LoanTemp.ContractId
                ) AS LoanDisbursementInfo ON Loan.ContractId = LoanDisbursementInfo.ContractId;

                WITH CTE_DownPaymentInfo
                     AS (SELECT Receivable.ContractId
                              , Receivable.IsGLPosted
                              , SUM(Receivable.Amount_Amount) AS Downpayment
                         FROM #ReceivableDetailsTemp Receivable
                         WHERE Receivable.PaymentType = @LoanDownPayment
                         GROUP BY Receivable.ContractId
                                , Receivable.IsGLPosted)
                     UPDATE #LoanDetails
                       SET 
                           PrincipalBalance = PrincipalBalance + (ISNULL(PrincipalInfo.Downpayment, 0.00) * Loan.RetainedPortion)
                         , TotalAmount =  TotalAmount - (ISNULL(DisbursementInfo.Downpayment, 0.00) * Loan.RetainedPortion)
                     FROM #LoanDetails Loan
                          LEFT JOIN CTE_DownPaymentInfo PrincipalInfo ON Loan.ContractId = PrincipalInfo.ContractId
                                                                         AND PrincipalInfo.IsGLPosted = 0
                          LEFT JOIN CTE_DownPaymentInfo DisbursementInfo ON Loan.ContractId = DisbursementInfo.ContractId
                                                                            AND DisbursementInfo.IsGLPosted = 1;
        END;
        /*Table Value Calculation*/
        /*TotalFinancedAmount*/ 

        IF EXISTS(SELECT 1 FROM #LoanDetails)
        BEGIN
                WITH CTE_FundingsWithCompletedDR
                     AS (SELECT LoanTemp.ContractId
                              , SUM(CASE
                                        WHEN LoanTemp.DisbursementRequestStatus = @CompletedStatus
										THEN 
											CASE 
												WHEN LoanTemp.IsForeignCurrency = 0
												THEN payables.AmountToPay_Amount
												ELSE payables.AmountToPay_Amount * LoanTemp.InitialExchangeRate 
											END
										ELSE 0.00 END) AS FinancedAmount
                         FROM
                         (
                             SELECT DISTINCT 
                                    IsForeignCurrency
                                  , DisbursementRequestId
                                  , ContractId
                                  , PayableSourceTable
                                  , PayableStatus
                                  , DRPayableIsActive
                                  , DisbursementRequestStatus
                                  , InitialExchangeRate
                                  , PayableId
                                  , PayableSourceId
                             FROM #LoanFinanceBasicTemp
                             WHERE DRPayableIsActive = @True
                         ) loanTemp
                         INNER JOIN DIsbursementRequests dr ON loanTemp.DisbursementRequestId = dr.Id AND dr.Status != @InactiveStatus
                         INNER JOIN DisbursementRequestPaymentDetails drp ON drp.DisbursementRequestId = dr.Id
                         INNER JOIN DisbursementRequestPayables payables ON dr.Id = payables.DisbursementRequestId
                                                                            AND loanTemp.PayableId = payables.PayableId
                         WHERE LoanTemp.PayableSourceTable = @PayableInvoiceOtherCost
							   AND LoanTemp.PayableStatus != @InActive
                         GROUP BY LoanTemp.ContractId),
                     CTE_FundingsForMigratedContract
                     AS (SELECT Contract.ContractId
					            , SUM(CASE
                                        WHEN LoanTemp.Status = @CompletedStatus
										THEN 
											CASE 
												WHEN LoanTemp.IsForeignCurrency = 0
												THEN LoanTemp.Amount
												ELSE LoanTemp.Amount * LoanTemp.InitialExchangeRate 
											END
										ELSE 0.00 END) AS FinancedAmount
                         FROM
                         (
                             SELECT ContractId
                             FROM #LoanDetails
                             WHERE IsProgressLoan = 0
                                   AND IsMigratedContract = 1
                         ) Contract
                         JOIN #LoanFinanceBasicTemp LoanTemp ON Contract.ContractId = LoanTemp.ContractId
                                                                AND LoanTemp.IsOrigination = 1
                                                                AND LoanTemp.PayableSourceTable = @PayableInvoiceOtherCost
                         GROUP BY Contract.ContractId)
                     UPDATE #LoanTableValues
                       SET 
                           TotalFinancedAmount_Amount = CASE
                                                            WHEN Contract.IsProgressLoan = 0
                                                            THEN ISNULL(FundingsWithCompletedDR.FinancedAmount, 0) + ISNULL(FundingsForMigratedContract.FinancedAmount, 0)
                                                            ELSE tv.TotalFinancedAmount_Amount + ISNULL(FundingsWithCompletedDR.FinancedAmount, 0)
                                                        END
                     FROM #LoanTableValues tv
                          JOIN #LoanDetails Contract ON tv.ContractId = Contract.ContractId
                          LEFT JOIN CTE_FundingsWithCompletedDR FundingsWithCompletedDR ON tv.ContractId = FundingsWithCompletedDR.ContractId
                          LEFT JOIN CTE_FundingsForMigratedContract FundingsForMigratedContract ON tv.ContractId = FundingsForMigratedContract.ContractId;
        END;
		

        IF EXISTS(SELECT 1 FROM #LoanDetails WHERE IsProgressLoan = 0)
        BEGIN
                UPDATE #LoanTableValues
                  SET 
                      PrincipalBalance_Amount = CASE
                                                    WHEN Contract.PrincipalBalanceIncomeExists = 0
                                                    THEN ISNULL(Contract.TotalAmount, 0)
                                                    ELSE ISNULL(Contract.PrincipalBalance, 0)
                                                END
                FROM #LoanTableValues tv
                     JOIN #LoanDetails Contract ON Contract.ContractId = tv.ContractId
                                                   AND Contract.IsProgressLoan = 0
                                                   AND Contract.IsChargedOff = 0;
        END;

        SELECT PaydownTemp.ContractId
             , SUM(PrePaymentAmount_Amount) AS PrePaymentAmount
        INTO #RePossessionAmount
        FROM #LoanPaydownTemp PaydownTemp
             JOIN #LoanDetails Contract ON Contract.ContractId = PaydownTemp.ContractId
             JOIN LoanPaydownAssetDetails lpad ON lpad.LoanPayDownId = PaydownTemp.Id
        WHERE lpad.IsActive = 1
              AND AssetPaydownStatus != 'CollateralOnLoan'
              AND PaydownTemp.PaydownReason IN(@RePossession)
             AND Contract.SyndicationType != @FullSale
             AND Contract.IsChargedOff = 0
        GROUP BY PaydownTemp.ContractId;

		CREATE NONCLUSTERED INDEX IX_Id ON #RePossessionAmount(ContractId);

        SELECT t.ContractId
             , lis.CumulativeInterestAppliedToPrincipal_Amount AS CumulativeInterestAppliedToPrincipal
        INTO #CumulativeInterestAppliedToPrincipal
        FROM
        (
            SELECT PaydownTemp.ContractId
                 , MAX(lis.Id) AS Id
            FROM #LoanPaydownTemp PaydownTemp
                 JOIN LoanFinances lf ON lf.ContractId = PaydownTemp.ContractId
                 JOIN LoanIncomeSchedules lis ON lis.LoanFinanceId = lf.Id
            WHERE lis.IsSchedule = 1
                  AND lis.IncomeDate = PaydownTemp.PaydownDate
            GROUP BY PaydownTemp.ContractId
        ) AS t
        INNER JOIN LoanIncomeSchedules lis ON t.Id = lis.Id;

        CREATE NONCLUSTERED INDEX IX_Id ON #CumulativeInterestAppliedToPrincipal(ContractId);

        WITH CTE_FutureDatedPaydown
             AS (SELECT PaydownTemp.ContractId
                      , SUM(CASE
                                WHEN Contract.IsChargedOff = 0
                                     AND PaydownTemp.PaydownDate > ISNULL(ContractDateInfo.MaxIncomeDate, DATEADD(DAY, -1, Contract.CommencementDate))
                                THEN CASE
                                         WHEN PaydownTemp.PaydownReason = @FullPaydown
                                              AND PaydownTemp.IsDailySensitive = 0
                                         THEN 
											  CASE WHEN PaydownTemp.PaydownDate = Contract.SyndicationEffectiveDate AND PaydownTemp.CreatedTime < Contract.SyndicationCreatedTIme
											  THEN ISNULL(PaydownTemp.PrincipalBalance_Amount, 0) - ISNULL(PaydownTemp.PrincipalPaydown_Amount, 0)  
											  WHEN Contract.SyndicationEffectiveDate > PaydownTemp.PaydownDate OR Contract.SyndicationEffectiveDate IS NULL
												   THEN ISNULL(PaydownTemp.PrincipalBalance_Amount, 0) - ISNULL(PaydownTemp.PrincipalPaydown_Amount, 0)
												   ELSE (ISNULL(PaydownTemp.PrincipalBalance_Amount, 0) - ISNULL(PaydownTemp.PrincipalPaydown_Amount, 0)) * Contract.RetainedPortion
											  END
                                         WHEN PaydownTemp.PaydownReason = @Casualty
                                         THEN 
											   CASE  
													WHEN PaydownTemp.PaydownDate = Contract.SyndicationEffectiveDate AND PaydownTemp.CreatedTime < Contract.SyndicationCreatedTIme
											        THEN ISNULL(PaydownTemp.PrincipalPaydown_Amount, 0) - ISNULL(interest.CumulativeInterestAppliedToPrincipal, 0)
													WHEN Contract.SyndicationEffectiveDate > PaydownTemp.PaydownDate OR Contract.SyndicationEffectiveDate IS NULL
												    THEN ISNULL(PaydownTemp.PrincipalPaydown_Amount, 0) - ISNULL(interest.CumulativeInterestAppliedToPrincipal, 0)
													ELSE (ISNULL(PaydownTemp.PrincipalPaydown_Amount, 0) - ISNULL(interest.CumulativeInterestAppliedToPrincipal, 0)) * Contract.RetainedPortion
											   END
                                         WHEN PaydownTemp.PaydownReason = @RePossession
                                         THEN 
											  CASE 
												   WHEN PaydownTemp.PaydownDate = Contract.SyndicationEffectiveDate AND PaydownTemp.CreatedTime < Contract.SyndicationCreatedTIme
												   THEN ISNULL(RePossession.PrePaymentAmount, 0)
												   WHEN Contract.SyndicationEffectiveDate > PaydownTemp.PaydownDate OR Contract.SyndicationEffectiveDate IS NULL 
												   THEN ISNULL(RePossession.PrePaymentAmount, 0)
												   ELSE ISNULL(RePossession.PrePaymentAmount, 0) * Contract.RetainedPortion
											  END
                                         ELSE 0
                                     END
                                ELSE 0
                            END) AS PaydownAmount
                 FROM #LoanPaydownTemp PaydownTemp
                      JOIN #LoanDetails Contract ON Contract.ContractId = PaydownTemp.ContractId
                                                    AND PaydownTemp.PaydownReason IN(@FullPaydown, @Casualty, @RePossession)
                      JOIN #BasicDetails ContractDateInfo ON PaydownTemp.ContractId = ContractDateInfo.ContractId
                      LEFT JOIN #RePossessionAmount RePossession ON PaydownTemp.ContractId = RePossession.ContractId
                      LEFT JOIN #CumulativeInterestAppliedToPrincipal interest ON PaydownTemp.ContractId = interest.ContractId
                 GROUP BY PaydownTemp.ContractId)
             UPDATE #LoanTableValues
               SET 
                   PrincipalBalance_Amount = PrincipalBalance_Amount - FuturePaydown.PaydownAmount
             FROM #LoanTableValues tv
                  JOIN CTE_FutureDatedPaydown FuturePaydown ON tv.ContractId = FuturePaydown.ContractId;


        WITH CTE_CapitalizedInterestPositiveAdjustment
             AS (SELECT Contract.ContractId
                      , SUM(ISNULL(CASE WHEN Contract.SyndicationEffectiveDate < CapInterest.CapitalizedDate 
										THEN CapInterest.Amount_Amount * Contract.RetainedPortion
										ELSE CapInterest.Amount_Amount END, 0)) AS CapitalizedInterestPositiveAdjustment
                 FROM
				 #LoanDetails Contract
                 JOIN LoanCapitalizedInterests CapInterest ON Contract.LoanFinanceId = CapInterest.LoanFinanceId
                                                              AND CapInterest.IsActive = 1
                                                              AND CapInterest.GLJournalId IS NOT NULL
															  AND Contract.IsProgressLoan = 0 AND Contract.SyndicationType != @FullSale AND Contract.IsChargedOff = 0
                 JOIN #BasicDetails ContractDateInfo ON Contract.ContractId = ContractDateInfo.ContractId
                 WHERE (CapInterest.Source IN(@CapitalizedInterestDueToSkipPayments, @CapitalizedInterestFromPaydown)
                 AND CapInterest.CapitalizedDate > ISNULL(ContractDateInfo.MaxIncomeDate, DATEADD(DAY, -1, Contract.CommencementDate)))
                 OR (CapInterest.Source IN(@CapitalizedInterestDueToScheduledFunding, @CapitalizedInterestDueToRateChange)
                 AND CapInterest.CapitalizedDate > ISNULL(DATEADD(DAY, 1, ContractDateInfo.MaxIncomeDate), DATEADD(DAY, -1, Contract.CommencementDate)))
                 GROUP BY Contract.ContractId)
             UPDATE #LoanTableValues
               SET 
                   PrincipalBalance_Amount = PrincipalBalance_Amount + PositiveAdjustment.CapitalizedInterestPositiveAdjustment
             FROM #LoanTableValues tv
                  JOIN CTE_CapitalizedInterestPositiveAdjustment PositiveAdjustment ON tv.ContractId = PositiveAdjustment.ContractId;

        WITH CTE_CapitalizedInterestNegativeAdjustment
             AS (SELECT Contract.ContractId
                      , SUM(ISNULL(CASE WHEN Contract.SyndicationEffectiveDate < CapInterest.CapitalizedDate 
										THEN CapInterest.Amount_Amount * Contract.RetainedPortion
										ELSE CapInterest.Amount_Amount END, 0)) AS CapitalizedInterestNegativeAdjustment
                 FROM
				 #LoanDetails Contract
                 JOIN LoanCapitalizedInterests CapInterest ON Contract.LoanFinanceId = CapInterest.LoanFinanceId
                                                              AND CapInterest.IsActive = 1
                                                              AND CapInterest.GLJournalId IS NULL
															  AND Contract.IsProgressLoan = 0 AND Contract.SyndicationType != @FullSale AND Contract.IsChargedOff = 0
                 JOIN #BasicDetails ContractDateInfo ON Contract.ContractId = ContractDateInfo.ContractId
                 WHERE CapInterest.Source IN(@CapitalizedInterestDueToSkipPayments, @CapitalizedInterestFromPaydown)
                 AND CapInterest.CapitalizedDate <= ContractDateInfo.MaxIncomeDate
                 OR CapInterest.Source IN(@CapitalizedInterestDueToScheduledFunding, @CapitalizedInterestDueToRateChange)
                 AND CapInterest.CapitalizedDate <= DATEADD(DAY, 1, ContractDateInfo.MaxIncomeDate)
                 GROUP BY Contract.ContractId)
             UPDATE #LoanTableValues
               SET 
                   PrincipalBalance_Amount = PrincipalBalance_Amount - NegativeAdjustment.CapitalizedInterestNegativeAdjustment
             FROM #LoanTableValues tv
                  JOIN CTE_CapitalizedInterestNegativeAdjustment NegativeAdjustment ON tv.ContractId = NegativeAdjustment.ContractId;

        UPDATE #LoanTableValues
          SET 
              PrincipalBalance_Amount = CASE
                                            WHEN ContractDateInfo.MaxIncomeDate IS NULL
                                            THEN 0
                                            ELSE tv.PrincipalBalance_Amount
                                        END
        FROM #LoanTableValues tv
             JOIN #LoanDetails Contract ON Contract.ContractId = tv.ContractId
                                           AND Contract.Status = @FullyPaidOff
             JOIN #LoanPaydownTemp PaydownTemp ON Contract.ContractId = PaydownTemp.ContractId
                                                  AND PaydownTemp.PaydownReason = @FullPaydown
                                                  AND Contract.CommencementDate = PaydownTemp.PaydownDate
             JOIN #BasicDetails ContractDateInfo ON Contract.ContractId = ContractDateInfo.ContractId;



        /*Loan Principal Receivable with EndDate<=MaxIncomeDate but no GL Posted*/
        WITH CTE_PrincipalReceivableNotGlPosted
             AS (SELECT Receivable.ContractId
                      , SUM(Receivable.Amount_Amount) AS Principal_NotGLPosted
                 FROM #BasicDetails Loan
                      JOIN #ReceivableDetailsTemp Receivable ON Loan.ContractId = Receivable.ContractId
                                                                AND Receivable.ReceivableType = @LoanPrincipal
                                                                AND Loan.MaxIncomeDate IS NOT NULL
                 WHERE Receivable.IsGLPosted = 0
                       AND IsChargedOff = 0
                           AND Receivable.PaymentStartDate <= Loan.MaxIncomeDate
                           AND Receivable.PaymentEndDate <= Loan.MaxIncomeDate
						   AND Receivable.FunderId IS NULL
                 GROUP BY Receivable.ContractId)
             UPDATE #LoanTableValues
               SET 
                   PrincipalBalance_Amount = PrincipalBalance_Amount + Principal_NotGLPosted
             FROM #LoanTableValues tv
                  JOIN CTE_PrincipalReceivableNotGlPosted PrincipalReceivableNotGlPosted ON tv.contractid = PrincipalReceivableNotGlPosted.ContractId;

        /*PrincipalBalanceAdjustment*/

        IF EXISTS(SELECT 1 FROM #LoanFinanceBasicTemp WHERE IsOrigination = 0)
        BEGIN
                WITH CTE_CompletedDRAdjustment
                     AS (SELECT FSFT.ContractId
                              , SUM(ISNULL(FSFT.Amount, 0)) AS Amount
                         FROM #FutureScheduledFundedTemp FSFT
                         WHERE FSFT.IsGLPosted = 0
                               AND FSFT.DRStatus IS NOT NULL
                               AND FSFT.DRStatus = @CompletedStatus
                         GROUP BY FSFT.ContractId),
                     CTE_GLPostedInCompletedDRAdjustment
                     AS (SELECT FSFT.ContractId
                              , SUM(ISNULL(FSFT.Amount, 0) * (-1)) AS Amount
                         FROM #FutureScheduledFundedTemp FSFT
                         WHERE FSFT.IsGLPosted = 1
                               AND (FSFT.DRStatus IS NULL
                                    OR FSFT.DRStatus != @CompletedStatus)
                         GROUP BY FSFT.ContractId)
                     UPDATE #LoanTableValues
                       SET 
                           PrincipalBalanceAdjustment_Amount = ISNULL(CompletedDRAdjustment.Amount, 0) + ISNULL(InCompletedDRAdjustment.Amount, 0)
                     FROM #LoanTableValues tv
                          LEFT JOIN CTE_CompletedDRAdjustment CompletedDRAdjustment ON tv.ContractId = CompletedDRAdjustment.ContractId
                          LEFT JOIN CTE_GLPostedInCompletedDRAdjustment InCompletedDRAdjustment ON tv.ContractId = InCompletedDRAdjustment.ContractId;
        END

                /*LoanPrincipalOSAR*/
                ;
        WITH CTE_DSLLoanPrincipalReceivable
             AS (SELECT Contract.ContractId
                      , SUM(CASE
                                WHEN Contract.IsNonAccrual = 0
                                THEN ReceivableDetail.Balance_Amount
                                ELSE ReceivableDetail.EffectiveBookBalance_Amount
                            END) AS DSLLoanPrincipalAmount
                 FROM
                 (
                     SELECT ContractId
                          , IsNonAccrual
                     FROM #LoanDetails
                     WHERE IsDSL = 1
                           AND IsChargedOff = 0
                 ) Contract
                 JOIN #ReceivableDetailsTemp ReceivableDetail ON Contract.ContractId = ReceivableDetail.ContractId
                                                                 AND ReceivableDetail.ReceivableType = @LoanPrincipal
                                                                 AND ReceivableDetail.FunderId IS NULL
                                                                 AND ReceivableDetail.IsGLPosted = 1
                 GROUP BY Contract.ContractId)
             UPDATE #LoanTableValues
               SET 
                   LoanPrincipalOSAR_Amount = LoanPrincipalOSAR_Amount + LoanPrincipalReceivable.DSLLoanPrincipalAmount
             FROM #LoanTableValues tv
                  JOIN CTE_DSLLoanPrincipalReceivable LoanPrincipalReceivable ON tv.ContractId = LoanPrincipalReceivable.ContractId;

        WITH CTE_NonDSLLoanPrincipalReceivable
             AS (SELECT Contract.ContractId
                      , SUM(CASE WHEN Contract.IsNonAccrual = 0 AND ReceivableDetail.FunderId IS NULL AND Contract.IsChargedOff = 0 THEN ReceivableDetail.Balance_Amount ELSE 0.00 END) AS NonDSLLoanPrincipalAmount
					  , SUM(CASE WHEN Contract.IsNonAccrual = 0 AND ReceivableDetail.FunderId IS NOT NULL THEN ReceivableDetail.Balance_Amount ELSE 0.00 END) AS SyndicatedNonDSLLoanPrincipalAmount
					  , SUM(CASE WHEN Contract.IsNonAccrual = 1 AND ReceivableDetail.FunderId IS NULL AND Contract.IsChargedOff = 0 THEN ReceivableDetail.EffectiveBookBalance_Amount ELSE 0.00 END) AS NonAccruedNonDSLLoanPrincipalAmount
					  , SUM(CASE WHEN Contract.IsNonAccrual = 1 AND ReceivableDetail.FunderId IS NOT NULL THEN ReceivableDetail.EffectiveBookBalance_Amount ELSE 0.00 END) AS NonAccruedSyndicatedNonDSLLoanPrincipalAmount
                 FROM #LoanDetails Contract
                 JOIN #ReceivableDetailsTemp ReceivableDetail ON Contract.ContractId = ReceivableDetail.ContractId
                                                                 AND ReceivableDetail.ReceivableType = @LoanPrincipal
                                                                 AND ReceivableDetail.IsGLPosted = 1
				 WHERE Contract.IsDSL = 0
                 GROUP BY Contract.ContractId)
             UPDATE #LoanTableValues
               SET 
                   LoanPrincipalOSAR_Amount = LoanPrincipalOSAR_Amount + NDSLLoanPrincipalReceivable.NonDSLLoanPrincipalAmount + NDSLLoanPrincipalReceivable.NonAccruedNonDSLLoanPrincipalAmount,
				   SyndicatedLoanPrincipalOSAR_Amount = SyndicatedLoanPrincipalOSAR_Amount + NDSLLoanPrincipalReceivable.SyndicatedNonDSLLoanPrincipalAmount + NDSLLoanPrincipalReceivable.NonAccruedSyndicatedNonDSLLoanPrincipalAmount
             FROM #LoanTableValues tv
                  JOIN CTE_NonDSLLoanPrincipalReceivable NDSLLoanPrincipalReceivable ON tv.ContractId = NDSLLoanPrincipalReceivable.ContractId;

        /*LoanInterestOSAR*/
        IF EXISTS(SELECT 1 FROM #LoanDetails)
		BEGIN
                WITH CTE_AccrualLoanInterestReceivable
                     AS (SELECT Contract.ContractId
                              , SUM(CASE WHEN ReceivableDetail.FunderId IS NULL AND Contract.IsNonAccrual = 0 THEN ReceivableDetail.Balance_Amount ELSE 0.00 END) AS LoanInterestAmount
							  , SUM(CASE WHEN ReceivableDetail.FunderId IS NOT NULL AND Contract.IsNonAccrual = 0 THEN ReceivableDetail.Balance_Amount ELSE 0.00 END) AS SyndicatedLoanInterestAmount
							  , SUM(CASE WHEN ReceivableDetail.FunderId IS NULL AND Contract.IsNonAccrual = 1 THEN ReceivableDetail.EffectiveBookBalance_Amount ELSE 0.00 END) AS NonAccruedLoanInterestAmount
							  , SUM(CASE WHEN ReceivableDetail.FunderId IS NOT NULL AND Contract.IsNonAccrual = 1 THEN ReceivableDetail.EffectiveBookBalance_Amount ELSE 0.00 END) AS NonAccruedSyndicatedLoanInterestAmount
                         FROM #LoanDetails Contract
                         JOIN #ReceivableDetailsTemp ReceivableDetail ON Contract.ContractId = ReceivableDetail.ContractId
                                                                         AND ReceivableDetail.ReceivableType = @LoanInterest
                                                                         AND ReceivableDetail.IsGLPosted = 1
                         WHERE Contract.IsDSL = 0
						 GROUP BY Contract.ContractId)
                     UPDATE #LoanTableValues
                       SET 
                           LoanInterestOSAR_Amount = LoanInterestOSAR_Amount + LoanInterestReceivable.LoanInterestAmount + LoanInterestReceivable.NonAccruedLoanInterestAmount,
						   SyndicatedLoanInterestOSAR_Amount = SyndicatedLoanInterestOSAR_Amount + LoanInterestReceivable.SyndicatedLoanInterestAmount + LoanInterestReceivable.NonAccruedSyndicatedLoanInterestAmount
                     FROM #LoanTableValues tv
                          JOIN CTE_AccrualLoanInterestReceivable LoanInterestReceivable ON tv.ContractId = LoanInterestReceivable.ContractId;
        END;

        /*IncomeAccrualBalance*/

        IF EXISTS(SELECT 1 FROM #LoanDetails)
            BEGIN

                WITH CTE_LoanInterestIncome
                     AS (SELECT Contract.ContractId
                              , SUM(IncomeSched.InterestAccrued_Amount) AS InterestAccruedAmount
                         FROM #LoanDetails Contract
                              JOIN #LoanIncomeScheduleTemp IncomeSched ON Contract.ContractId = IncomeSched.ContractId
                                                                          AND IncomeSched.IsLessorOwned = 1
                                                                          AND IncomeSched.IsAccounting = 1
                                                                          AND IncomeSched.IsGLPosted = 1
                         GROUP BY Contract.ContractId)
                     UPDATE #LoanTableValues
                       SET 
                           IncomeAccrualBalance_Amount = LoanInterestIncome.InterestAccruedAmount
                     FROM #LoanTableValues tv
                          JOIN CTE_LoanInterestIncome LoanInterestIncome ON tv.ContractId = LoanInterestIncome.ContractId;

                UPDATE #LoanTableValues
                  SET 
                      IncomeAccrualBalance_Amount = IncomeAccrualBalance_Amount - CapitalizedInterest.CapitalizedInterestAmount
                FROM #LoanTableValues tv
                     JOIN
                (
                    SELECT Contract.ContractId
                         , SUM(CASE WHEN (contract.SyndicationEffectiveDate > CapInterest.CapitalizedDate  OR contract.SyndicationEffectiveDate IS NULL)
									THEN CapInterest.Amount_Amount
									ELSE CapInterest.Amount_Amount * Contract.RetainedPortion 
							   END) AS CapitalizedInterestAmount
                    FROM #LoanDetails Contract
                         JOIN LoanCapitalizedInterests CapInterest ON Contract.LoanFinanceId = CapInterest.LoanFinanceId
																	  AND CapInterest.GLJournalId IS NOT NULL
                                                                      AND CapInterest.Source != @ProgressLoanInterestCapitalized
                                                                      AND CapInterest.Source != @CapitalizedAdditionalFeeCharge
                    GROUP BY Contract.ContractId
                ) AS CapitalizedInterest ON tv.ContractId = CapitalizedInterest.ContractId;

                UPDATE #LoanTableValues
                  SET 
                      IncomeAccrualBalance_Amount = IncomeAccrualBalance_Amount - ReceivableIncomeAccrual.LoanInterestAmount
                FROM #LoanTableValues tv
                     JOIN
                (
                    SELECT ReceivableDetail.ContractId
                         , SUM(ReceivableDetail.Amount_Amount) AS LoanInterestAmount
                    FROM #ReceivableDetailsTemp ReceivableDetail
                         INNER JOIN #BasicDetails ld ON ReceivableDetail.ContractId = ld.ContractId
                    WHERE ReceivableDetail.ReceivableType = @LoanInterest
                          AND ReceivableDetail.FunderId IS NULL
                          AND ReceivableDetail.IsGLPosted = 1
                    GROUP BY ReceivableDetail.ContractId
                ) AS ReceivableIncomeAccrual ON tv.ContractId = ReceivableIncomeAccrual.ContractId;

                UPDATE #LoanTableValues
                  SET 
                      IncomeAccrualBalance_Amount = IncomeAccrualBalance_Amount - PaydownAdjutsment.PaydownAmount
                FROM #LoanTableValues tv
                     JOIN
                (
                    SELECT PaydownTemp.ContractId
                         , SUM(CASE
                                   WHEN PaydownTemp.PaydownReason = @FullPaydown
                                        AND PaydownTemp.IsDailySensitive = 0
                                   THEN CASE
											 WHEN PaydownTemp.PaydownDate = Contract.SyndicationEffectiveDate AND PaydownTemp.CreatedTime < Contract.SyndicationCreatedTIme
											 THEN PaydownTemp.AccruedInterest_Amount - PaydownTemp.InterestPaydown_Amount
											 WHEN Contract.SyndicationEffectiveDate > PaydownTemp.PaydownDate OR Contract.SyndicationEffectiveDate IS NULL
											 THEN PaydownTemp.AccruedInterest_Amount - PaydownTemp.InterestPaydown_Amount
											 ELSE (PaydownTemp.AccruedInterest_Amount - PaydownTemp.InterestPaydown_Amount) * Contract.RetainedPortion
										END
                                   WHEN PaydownReason = @Casualty
                                   THEN CASE
											 WHEN PaydownTemp.PaydownDate = Contract.SyndicationEffectiveDate AND PaydownTemp.CreatedTime < Contract.SyndicationCreatedTIme
											 THEN PaydownTemp.InterestPaydown_Amount + ISNULL(interest.CumulativeInterestAppliedToPrincipal, 0)  
											 WHEN Contract.SyndicationEffectiveDate > PaydownTemp.PaydownDate OR Contract.SyndicationEffectiveDate IS NULL
											 THEN PaydownTemp.InterestPaydown_Amount + ISNULL(interest.CumulativeInterestAppliedToPrincipal, 0)
											 ELSE (PaydownTemp.InterestPaydown_Amount + ISNULL(interest.CumulativeInterestAppliedToPrincipal, 0)) * Contract.RetainedPortion
										 END
                                   WHEN PaydownReason = @Repossession
                                   THEN CASE 
											 WHEN PaydownTemp.PaydownDate = Contract.SyndicationEffectiveDate AND PaydownTemp.CreatedTime < Contract.SyndicationCreatedTIme
											 THEN PaydownTemp.InterestPaydown_Amount
											 WHEN Contract.SyndicationEffectiveDate > PaydownTemp.PaydownDate OR Contract.SyndicationEffectiveDate IS NULL	
											 THEN PaydownTemp.InterestPaydown_Amount
											 ELSE PaydownTemp.InterestPaydown_Amount * Contract.RetainedPortion
										 END
                                   ELSE 0
                               END) AS PaydownAmount
                    FROM #LoanPaydownTemp PaydownTemp
						 INNER JOIN	#LoanDetails Contract ON PaydownTemp.ContractId = Contract.ContractId
                         LEFT JOIN #CumulativeInterestAppliedToPrincipal interest ON PaydownTemp.ContractId = interest.ContractId
                    WHERE PaydownTemp.PaydownReason IN(@FullPaydown, @Casualty, @Repossession)
                    GROUP BY PaydownTemp.ContractId
                ) AS PaydownAdjutsment ON tv.ContractId = PaydownAdjutsment.ContractId;
        END;
        WITH CTE_ReceivableInfo
             AS (SELECT Receivable.ContractId
                      , SUM(CASE
                                WHEN FunderId IS NULL AND ld.IsNonAccrual = 0 AND Receivable.Amount_Amount != Receivable.Balance_Amount
                                THEN Receivable.Amount_Amount - Receivable.Balance_Amount
                                ELSE 0.00
                            END) AS ReceivableAmount
                      , SUM(CASE
                                WHEN FunderId IS NULL AND ld.IsNonAccrual = 1 AND Receivable.Amount_Amount != Receivable.EffectiveBookBalance_Amount
                                THEN Receivable.Amount_Amount - Receivable.EffectiveBookBalance_Amount
                                ELSE 0.00
                            END) AS NonAccrualReceivableAmount
                 --,SUM(CASE WHEN FunderId IS NOT NULL THEN Receivable.Amount_Amount - Receivable.Balance_Amount ELSE 0.00 END) AS SyndicatedReceivableAmount
                 FROM #BasicDetails Contract
					  JOIN #LoanDetails ld ON Contract.ContractId = ld.ContractId
                      JOIN #ReceivableDetailsTemp Receivable ON Contract.ContractId = Receivable.ContractId
                                                                AND Receivable.IsGLPosted = 0
                                                                AND Receivable.IsDummy = 0
                                                                AND Receivable.ReceivableType = @LoanPrincipal
                                                                AND (Contract.IsChargedOff = 0
                                                                     OR Receivable.PaymentStartDate < Contract.ChargeOffDate)
                 GROUP BY Receivable.ContractId)
             UPDATE #LoanTableValues
               SET 
                   PrepaidReceivables_Amount = PrepaidReceivable.ReceivableAmount + PrepaidReceivable.NonAccrualReceivableAmount
             --,SyndicatedPrepaidReceivables_Amount = PrepaidReceivable.SyndicatedReceivableAmount
             FROM #LoanTableValues tv
                  JOIN CTE_ReceivableInfo PrepaidReceivable ON tv.ContractId = PrepaidReceivable.ContractId;

        /*PrepaidPrincipalReceivable*/
        /*PrepaidInterstReceivable*/

        IF EXISTS(SELECT 1 FROM #LoanDetails)
            BEGIN
                WITH CTE_PrepaidInterest
                     AS (SELECT Contract.ContractId
                              , SUM(CASE WHEN Receivable.Amount_Amount != Receivable.Balance_Amount AND Contract.IsNonAccrual = 0 
										 THEN ISNULL(Receivable.Amount_Amount, 0) - ISNULL(Receivable.Balance_Amount, 0) 
										 ELSE 0.00 
									END) AS PrepaidInterestAmount
							  , SUM(CASE WHEN Receivable.Amount_Amount != Receivable.EffectiveBookBalance_Amount AND Contract.IsNonAccrual = 1	
										 THEN ISNULL(Receivable.Amount_Amount, 0) - ISNULL(Receivable.EffectiveBookBalance_Amount, 0) 
										 ELSE 0.00 
									END) AS NonAccrualPrepaidInterestAmount
                         FROM #LoanDetails Contract
                              JOIN #BasicDetails ContractDateInfo ON Contract.ContractId = ContractDateInfo.ContractId
                              JOIN #ReceivableDetailsTemp Receivable ON Contract.ContractId = Receivable.ContractId
                                                                        AND Receivable.ReceivableType = @LoanInterest
                                                                        AND Receivable.IsGLPosted = 0
                                                                        AND Receivable.IsDummy = 0
                                                                        AND Receivable.FunderId IS NULL
                         WHERE Contract.IsChargedOff = 0
                               OR Receivable.PaymentStartDate < ContractDateInfo.ChargeOffDate
                         GROUP BY Contract.ContractId)
                     UPDATE #LoanTableValues
                       SET 
                           PrepaidInterest_Amount = PrepaidInterest.PrepaidInterestAmount + PrepaidInterest.NonAccrualPrepaidInterestAmount
                     FROM #LoanTableValues tv
                          JOIN CTE_PrepaidInterest PrepaidInterest ON tv.ContractId = PrepaidInterest.ContractId;

        END;

        WITH CTE_UnappliedCashInfo
             AS (SELECT Receipt.ContractId
                      , SUM(Receipt.Balance_Amount) AS UnappliedCash
                 FROM #LoanDetails Contract
                      JOIN Receipts Receipt ON Contract.ContractId = Receipt.ContractId
                                               AND Receipt.Status IN (@PostedStatus)
                      JOIN ReceiptAllocations Allocation ON Allocation.ReceiptId = Receipt.Id
                                                            AND Allocation.IsActive = 1
                 GROUP BY Receipt.ContractId),
             CTE_PayableBalanceInfo
             AS (SELECT Contract.ContractId
                      , SUM(Payable.Balance_Amount) AS PayableBalance
                 FROM #BasicDetails Contract
                      JOIN Receipts Receipt ON Contract.ContractId = Receipt.ContractId
                                               AND Receipt.Status = @PostedStatus
                      JOIN Payables Payable ON Receipt.Id = Payable.SourceId
                                               AND Payable.SourceTable = @ReceiptSourceTable
                                               AND Payable.EntityType = @ReceiptRefundEntityType
                      JOIN UnallocatedRefunds Refund ON Payable.EntityId = Refund.Id
                                                        AND Refund.Status != @ReversedStatus
                 WHERE Payable.Status != @InactiveStatus
                 GROUP BY Contract.ContractId)
             UPDATE #LoanTableValues
               SET 
                   UnappliedCash_Amount = UnappliedCashInfo.UnappliedCash + ISNULL(PayableBalanceInfo.PayableBalance, 0.00)
             FROM #LoanTableValues RNI
                  JOIN CTE_UnappliedCashInfo UnappliedCashInfo ON RNI.ContractId = UnappliedCashInfo.ContractId
                  LEFT JOIN CTE_PayableBalanceInfo PayableBalanceInfo ON RNI.ContractId = PayableBalanceInfo.ContractId;

        /*CapitalizedInterests*/

        SELECT bd.ContractId
             , SUM(CASE WHEN ld.SyndicationEffectiveDate > lci.CapitalizedDate OR ld.SyndicationEffectiveDate IS NULL 
						THEN lci.Amount_Amount 
                        ELSE lci.Amount_Amount * RetainedPortion  
					END) AS CapitalizedInterest_Amount
        INTO #CapitalizedInterests
        FROM #LoanDetails ld
             JOIN #BasicDetails bd ON ld.ContractId = bd.ContractId
             JOIN LoanCapitalizedInterests lci ON ld.LoanFinanceId = lci.LoanFinanceId
        WHERE lci.IsActive = 1
              AND lci.Source NOT IN  (@ProgressLoanInterestCapitalized, @CapitalizedAdditionalFeeCharge)
			  AND lci.GLJournalId IS NOT NULL
        GROUP BY bd.ContractId;

        SELECT Contract.ContractId
             , SUM(Receivable.EffectiveBookBalance_Amount - Receivable.Balance_Amount) AS InterestAppliedAmount
        INTO #InterestApplied
        FROM #LoanDetails Contract
             JOIN #BasicDetails ContractDateInfo ON Contract.ContractId = ContractDateInfo.ContractId
             JOIN #ReceivableDetailsTemp Receivable ON Contract.ContractId = Receivable.ContractId
                                                       AND Receivable.Amount_Amount != Receivable.Balance_Amount
        WHERE Receivable.ReceivableType = @LoanInterest
              AND Receivable.EffectiveBookBalance_Amount != Receivable.Balance_Amount
        GROUP BY Contract.ContractId;

        /**************************************************************************************************************************/
        /*GL Value Calculation*/

        SELECT ContractId
             , EntryItemId
             , SUM(DebitAmount) DebitAmount
             , SUM(CreditAmount) CreditAmount
             , MatchingEntryName
             , SourceId
			 , GLJournalId
        INTO #GLTrialBalance
        FROM
        (
            SELECT gljd.EntityId AS ContractId
                 , glei.Id AS EntryItemId
                 , CASE
                       WHEN gljd.IsDebit = 1
                       THEN gljd.Amount_Amount
                       ELSE 0.00
                   END DebitAmount
                 , CASE
                       WHEN gljd.IsDebit = 0
                       THEN gljd.Amount_Amount
                       ELSE 0.00
                   END CreditAmount
                 , mglei.Name MatchingEntryName
                 , gljd.SourceId
				 , gljd.GLJournalId
            FROM GLJournalDetails gljd
                 INNER JOIN GLTemplateDetails gltd ON gltd.Id = gljd.GLTemplateDetailId
                 INNER JOIN GLEntryItems glei ON glei.Id = gltd.EntryItemId
                                                 AND glei.Name IN(@NoteReceivable, @PrincipalReceivable, @InterestReceivable, @Receivable, @AccruedInterest, @AccruedInterestCapitalized, @PrepaidInterestReceivable, @PrepaidPrincipalReceivable, @GainLossAdjustment, @AccruedInterest, @SuspendedIncome, @WritedownAccount, @ChargeoffExpense, @ChargeOffRecovery, @GainOnRecovery, @RecoveryIncome, @UnappliedAR, @DueToThirdPartyAR, @PrePaidDueToThirdPartyAR, 'NonRentalReceivable', 'PrePaidNonRentalReceivable', 'DueFromInterCompanyReceivable', 'PrePaidDueFromInterCompanyReceivable', 'PrePaidSyndicatedSalesTaxReceivable', 'SyndicatedSalesTaxReceivable', 'SalesTaxReceivable', 'PrepaidSalesTaxReceivable', 'RentDueToInvestorAP')
                 INNER JOIN GLTransactionTypes gltt ON glei.GLTransactionTypeId = gltt.Id
                 INNER JOIN #BasicDetails bd ON gljd.EntityId = bd.ContractId
                                                AND gljd.EntityType = @Contract
                 LEFT JOIN GLTemplateDetails mgltd ON gljd.MatchingGLTemplateDetailId = mgltd.Id
                 LEFT JOIN GLEntryItems mglei ON mglei.Id = mgltd.EntryItemId
                 LEFT JOIN GLTransactionTypes mgltt ON mgltt.Id = mglei.GLTransactionTypeId
        ) AS T
        GROUP BY ContractId
               , EntryItemId
               , MatchingEntryName
               , SourceId
			   , GLJournalId;

        INSERT INTO #GLTrialBalance
        (ContractId
       , EntryItemId
       , DebitAmount
       , CreditAmount
       , MatchingEntryName
       , SourceId
	   , GLJournalId
        )
        SELECT lfbt.ContractId AS ContractId
             , glei.Id AS EntryItemId
             , SUM(CASE
                       WHEN gljd.IsDebit = 1
                       THEN gljd.Amount_Amount
                       ELSE 0.00
                   END) DebitAmount
             , SUM(CASE
                       WHEN gljd.IsDebit = 0
                       THEN gljd.Amount_Amount
                       ELSE 0.00
                   END) CreditAmount
             , mglei.Name MatchingEntryName
             , gljd.SourceId
			 , gljd.GLJournalId
        FROM GLJournalDetails gljd
             INNER JOIN GLTemplateDetails gltd ON gltd.Id = gljd.GLTemplateDetailId
             INNER JOIN GLEntryItems glei ON glei.Id = gltd.EntryItemId
                                             AND glei.Name IN(@Disbursement)
             INNER JOIN GLTransactionTypes gltt ON glei.GLTransactionTypeId = gltt.Id
             INNER JOIN #LoanFinanceBasicTemp lfbt ON gljd.EntityId = lfbt.DisbursementRequestId
                                                      AND gljd.EntityType = @DisbursementRequest
                                                      AND gljd.SourceId = lfbt.PayableId
                                                      AND lfbt.AllocationMethod = @LoanDisbursementAllocationMethod
             LEFT JOIN #LoanDetails ld ON lfbt.ContractId = ld.ContractId
             LEFT JOIN GLTemplateDetails mgltd ON gljd.MatchingGLTemplateDetailId = mgltd.Id
             LEFT JOIN GLEntryItems mglei ON mglei.Id = mgltd.EntryItemId
             LEFT JOIN GLTransactionTypes mgltt ON mgltt.Id = mglei.GLTransactionTypeId
        WHERE DRPayableIsActive = @True
        GROUP BY lfbt.ContractId
               , glei.Id
               , mglei.Name
               , gljd.SourceId
			   , gljd.GLJournalId;


        CREATE NONCLUSTERED INDEX IX_Id ON #GLTrialBalance(ContractId);

		 WITH CTE_BIIncomeInfo
             AS (SELECT BIIncomeSched.ContractId
                      , SUM(CASE
                                WHEN BIIncomeSched.SystemConfigType IN('ReAccrualIncome', 'ReAccrualResidualIncome')
                                THEN BIIncomeSched.IncomeAmount
                                ELSE 0.00
                            END) AS ReAccrualAdjIncomeAmount
                 FROM #LoanFinanceBasicTemp Contract
                      JOIN #BlendedItemTemp BIIncomeSched ON Contract.ContractId = BIIncomeSched.ContractId
                                                             AND BIIncomeSched.IsReaccrualBlendedItem = 1
                                                             AND BIIncomeSched.BookRecognitionMode != @RecognizeImmediately
                 GROUP BY BIIncomeSched.ContractId)

             UPDATE lt SET IncomeAccrualBalance_Amount = IncomeAccrualBalance_Amount + ReAccrualAdjIncomeAmount
             FROM #LoanTableValues lt
                  INNER JOIN CTE_BIIncomeInfo bi ON lt.ContractId = bi.ContractId;


        UPDATE lt SET IncomeAccrualBalance_Amount = IncomeAccrualBalance_Amount + t.BIAmount
        FROM #LoanTableValues lt
        INNER JOIN
		(
            SELECT SUM(bi.BlendedItemAmount) AS BIAmount
                 , bi.ContractId
            FROM #BlendedItemTemp bi
            WHERE bi.IsReaccrualBlendedItem = 1
                  AND bi.BookRecognitionMode = @RecognizeImmediately
            GROUP BY bi.ContractId
        ) AS t ON t.ContractId = lt.ContractId;
		
        SELECT RS1.ContractId
             , SUM(RS1.PrincipalBalance_Debit - RS1.PrincipalBalance_Credit) PrincipalBalance_GL
             , SUM(RS1.LoanPrincipalOSAR_Debit - RS1.LoanPrincipalOSAR_Credit) LoanPrincipalOSAR_GL
             , SUM(RS1.LoanInterestOSAR_Debit - RS1.LoanInterestOSAR_Credit) LoanInterestOSAR_GL
             , SUM(RS1.IncomeAccrualBalance_Debit - RS1.IncomeAccrualBalance_Credit) IncomeAccrualBalance_GL
             , SUM(RS1.PrepaidPrincipalReceivable_Credit - RS1.PrepaidPrincipalReceivable_Debit) PrepaidPrincipalReceivable_GL
             , SUM(RS1.PrepaidInterestReceivable_Credit - RS1.PrepaidInterestReceivable_Debit) PrepaidInterestReceivable_GL
             , SUM(RS1.CapitalizedInterest_Credit - RS1.CapitalizedInterest_Debit) CapitalizedInterest_GL
             , SUM(RS1.Disbursement_Debit - RS1.Disbursement_Credit) AS TotalFinancedAmount_GL
             , SUM(RS1.GainLossAdjustment_Credit - RS1.GainLossAdjustment_Debit) GainLossAdjustment_GL
             , SUM(RS1.LoanPrincipalAR_Credit - RS1.LoanPrincipalAR_Debit) LoanPrincipalAR_GL
             , SUM(RS1.LoanInterestAR_Credit - RS1.LoanInterestAR_Debit) LoanInterestAR_GL
             , SUM(RS1.SuspendedIncome_Credit - RS1.SuspendedIncome_Debit) SuspendedIncome_GL
             , SUM(RS1.GrossWriteDown_Credit - RS1.GrossWriteDown_Debit) GrossWriteDown_GL
             , SUM(RS1.NetWriteDown_Credit - RS1.NetWriteDown_Debit) NetWriteDown_GL
             , SUM(RS1.ChargeOffExpense_Debit - RS1.ChargeOffExpense_Credit) ChargeOffExpense_GL
             , SUM(RS1.Recovery_Debit - RS1.Recovery_Credit) Recovery_GL
             , SUM(RS1.PrincipalCashPosting_Credit - RS1.PrincipalCashPosting_Debit) PrincipalCashPosting_GL
             , SUM(RS1.InterestCashPosting_Credit - InterestCashPosting_Debit) AS InterestCashPosting_GL
             , SUM(RS1.PrincipalNonCashPosting_Credit - RS1.PrincipalNonCashPosting_Debit) PrincipalNonCashPosting_GL
             , SUM(RS1.InterestNonCashPosting_Credit - RS1.InterestNonCashPosting_Debit) InterestNonCashPosting_GL
             , SUM(RS1.UnAppliedCash_Credit - RS1.UnAppliedCash_Debit) UnAppliedCash_GL
			 , SUM(RS1.DueToThirdPartyAR_Debit - RS1.DueToThirdPartyAR_Credit) DueToThirdPartyAR_GL
			 , SUM(RS1.PrePaidDueToThirdPartyAR_Credit - RS1.PrePaidDueToThirdPartyAR_Debit) PrePaidDueToThirdPartyAR_GL
			 , SUM(RS1.LoanSyndicationOSAR_Debit - RS1.LoanSyndicationOSAR_Credit) AS LoanSyndicationOSAR_GL
			 , SUM(RS1.SyndicationProceeds_Debit - RS1.SyndicationProceeds_Credit) AS SyndicationProceeds_GL
			 , SUM(RS1.SalesTaxReceivableAR_Debit - RS1.SalesTaxReceivableAR_Credit) AS SalesTaxReceivableAR_GL
			 , SUM(RS1.SalesTaxReceivableOSAR_Debit - RS1.SalesTaxReceivableOSAR_Credit) AS SalesTaxReceivableOSAR_GL
			 , SUM(RS1.SalesTaxReceivablePrepaid_Credit - RS1.SalesTaxReceivablePrepaid_Debit) AS SalesTaxReceivablePrepaid_GL
			 , SUM(RS1.SalesTaxFunderReceivableLessorRemitting_Debit - RS1.SalesTaxFunderReceivableLessorRemitting_Credit) AS SalesTaxFunderReceivableLessorRemitting_GL
			 , SUM(RS1.SalesTaxFunderReceivableLessorRemittingOSAR_Debit - RS1.SalesTaxFunderReceivableLessorRemittingOSAR_Credit) AS SalesTaxFunderReceivableLessorRemittingOSAR_GL
			 , SUM(RS1.SalesTaxReceivablePrepaidFunderPortion_Credit - RS1.SalesTaxReceivablePrepaidFunderPortion_Debit) AS SalesTaxReceivablePrepaidFunderPortion_GL
			 , SUM(RS1.RentDueToInvestor_Credit - RS1.RentDueToInvestor_Debit) AS RentDueToInvestor_GL
			 , SUM(RS1.SyndicationGainLossAdjustment_Debit - RS1.SyndicationGainLossAdjustment_Credit) SyndicationGainLossAdjustment_GL
			 , SUM(RS1.SyndicatedCashPosting_Credit  - RS1.SyndicatedCashPosting_Debit) AS SyndicatedCashPosting_GL
			 , SUM(RS1.SyndicatedNonCashPosting_Credit  - RS1.SyndicatedNonCashPosting_Debit) AS SyndicatedNonCashPosting_GL
			 , SUM(RS1.LessorOwnedCashPosting_Credit  - RS1.LessorOwnedCashPosting_Debit) AS LessorOwnedCashPosting_GL
			 , SUM(RS1.LessorOwnedNonCashPosting_Credit  - RS1.LessorOwnedNonCashPosting_Debit) AS LessorOwnedNonCashPosting_GL
			 , SUM(RS1.LessorPortionCashPosting_Credit  - RS1.LessorPortionCashPosting_Debit) AS LessorPortionCashPosting_GL
			 , SUM(RS1.LessorPortionNonCashPosting_Credit  - RS1.LessorPortionNonCashPosting_Debit) AS LessorPortionNonCashPosting_GL
        INTO #LoanGLJournalValues
        FROM
        (
            SELECT gltb.ContractId AS ContractId
                 , CASE
                       WHEN gle.Name = @NoteReceivable
                       THEN gltb.DebitAmount
                       ELSE 0
                   END PrincipalBalance_Debit
                 , CASE
                       WHEN gle.Name = @NoteReceivable
                       THEN gltb.CreditAmount
                       ELSE 0
                   END PrincipalBalance_Credit
                 , CASE
                       WHEN (gle.Name = @PrincipalReceivable
                            AND gltb.MatchingEntryName IS NULL)
                            OR (gle.Name = @Receivable
                               AND gltb.MatchingEntryName = @PrincipalReceivable)
                       THEN gltb.DebitAmount
                       ELSE 0
                   END LoanPrincipalOSAR_Debit
                 , CASE
                       WHEN (gle.Name = @PrincipalReceivable
                            AND gltb.MatchingEntryName IS NULL)
                            OR (gle.Name = @Receivable
                               AND gltb.MatchingEntryName = @PrincipalReceivable)
                       THEN gltb.CreditAmount
                       ELSE 0
                   END LoanPrincipalOSAR_Credit
                 , CASE
                       WHEN (gle.Name = @InterestReceivable
                            AND gltb.MatchingEntryName IS NULL)
                            OR (gle.Name = @Receivable
                               AND gltb.MatchingEntryName = @InterestReceivable)
                       THEN gltb.DebitAmount
                       ELSE 0
                   END LoanInterestOSAR_Debit
                 , CASE
                       WHEN (gle.Name = @InterestReceivable
                            AND gltb.MatchingEntryName IS NULL)
                            OR (gle.Name = @Receivable
                               AND gltb.MatchingEntryName = @InterestReceivable)
                       THEN gltb.CreditAmount
                       ELSE 0
                   END LoanInterestOSAR_Credit
                 , CASE
                       WHEN gle.Name IN(@AccruedInterest, @AccruedInterestCapitalized)
                       THEN gltb.DebitAmount
                       ELSE 0
                   END IncomeAccrualBalance_Debit
                 , CASE
                       WHEN gle.Name IN(@AccruedInterest, @AccruedInterestCapitalized)
                       THEN gltb.CreditAmount
                       ELSE 0
                   END IncomeAccrualBalance_Credit
                 , CASE
                       WHEN (gle.Name = @PrepaidPrincipalReceivable
                            AND gltb.MatchingEntryName IS NULL)
                            OR (gle.Name = @Receivable
                               AND gltb.MatchingEntryName = @PrepaidPrincipalReceivable)
                       THEN gltb.DebitAmount
                       ELSE 0
                   END PrepaidPrincipalReceivable_Debit
                 , CASE
                       WHEN (gle.Name = @PrepaidPrincipalReceivable
                            AND gltb.MatchingEntryName IS NULL)
                            OR (gle.Name = @Receivable
                               AND gltb.MatchingEntryName = @PrepaidPrincipalReceivable)
                       THEN gltb.CreditAmount
                       ELSE 0
                   END PrepaidPrincipalReceivable_Credit
                 , CASE
                       WHEN (gle.Name = @PrepaidInterestReceivable
                            AND gltb.MatchingEntryName IS NULL)
                            OR (gle.Name = @Receivable
                               AND gltb.MatchingEntryName = @PrepaidInterestReceivable)
                       THEN gltb.DebitAmount
                       ELSE 0
                   END PrepaidInterestReceivable_Debit
                 , CASE
                       WHEN (gle.Name = @PrepaidInterestReceivable
                            AND gltb.MatchingEntryName IS NULL)
                            OR (gle.Name = @Receivable
                               AND gltb.MatchingEntryName = @PrepaidInterestReceivable)
                       THEN gltb.CreditAmount
                       ELSE 0
                   END PrepaidInterestReceivable_Credit
                 , CASE
                       WHEN gle.Name IN( @AccruedInterestCapitalized)
                       THEN gltb.DebitAmount
                       ELSE 0
                   END CapitalizedInterest_Debit
                 , CASE
                       WHEN gle.Name IN(@AccruedInterestCapitalized)
                       THEN gltb.CreditAmount
                       ELSE 0
                   END CapitalizedInterest_Credit
                 , CASE
                       WHEN gle.Name IN(@Disbursement)
                            AND gltt.Name IN(@Disbursement)
                       THEN gltb.DebitAmount
                       ELSE 0
                   END Disbursement_Debit
                 , CASE
                       WHEN gle.Name IN(@Disbursement)
                            AND gltt.Name IN(@Disbursement)
                       THEN gltb.CreditAmount
                       ELSE 0
                   END Disbursement_Credit
                 , CASE
                       WHEN gle.Name IN(@GainLossAdjustment)
                            AND gltt.Name = @Paydown
							AND (loan.SyndicationGLJournalId IS NULL OR gltb.GLJournalId != loan.SyndicationGLJournalId)
                       THEN gltb.DebitAmount
                       ELSE 0
                   END GainLossAdjustment_Debit
                 , CASE
                       WHEN gle.Name IN(@GainLossAdjustment)
                            AND gltt.Name = @Paydown
							AND (loan.SyndicationGLJournalId IS NULL OR gltb.GLJournalId != loan.SyndicationGLJournalId) 
                       THEN gltb.CreditAmount
                       ELSE 0
                   END GainLossAdjustment_Credit
                 , CASE
                       WHEN gle.Name IN(@NoteReceivable)
                            AND gltt.Name = @LoanPrincipalAR
                       THEN gltb.DebitAmount
                       ELSE 0
                   END LoanPrincipalAR_Debit
                 , CASE
                       WHEN gle.Name IN(@NoteReceivable)
                            AND gltt.Name = @LoanPrincipalAR
                       THEN gltb.CreditAmount
                       ELSE 0
                   END LoanPrincipalAR_Credit
                 , CASE
                       WHEN gle.Name IN(@AccruedInterest)
                            AND gltt.Name = @LoanInterestAR
                       THEN gltb.DebitAmount
                       ELSE 0
                   END LoanInterestAR_Debit
                 , CASE
                       WHEN gle.Name IN(@AccruedInterest)
                            AND gltt.Name = @LoanInterestAR
                       THEN gltb.CreditAmount
                       ELSE 0
                   END LoanInterestAR_Credit
                 , CASE
                       WHEN gle.Name IN(@SuspendedIncome)
                            AND gltt.Name IN(@LoanIncomeRecognition, @Paydown, @LoanChargeoff)
                       THEN gltb.DebitAmount
                       ELSE 0
                   END SuspendedIncome_Debit
                 , CASE
                       WHEN gle.Name IN(@SuspendedIncome)
                            AND gltt.Name IN(@LoanIncomeRecognition, @Paydown, @LoanChargeoff)
                       THEN gltb.CreditAmount
                       ELSE 0
                   END SuspendedIncome_Credit
                 , CASE
                       WHEN gle.Name IN(@WritedownAccount)
                            AND gltt.Name IN(@WriteDown)
                       THEN gltb.DebitAmount
                       ELSE 0
                   END GrossWriteDown_Debit
                 , CASE
                       WHEN gle.Name IN(@WritedownAccount)
                            AND gltt.Name IN(@WriteDown)
                       THEN gltb.CreditAmount
                       ELSE 0
                   END GrossWriteDown_Credit
                 , CASE
                       WHEN gle.Name IN(@WritedownAccount)
                            AND gltt.Name IN(@WriteDown, @WriteDownRecovery)
                       THEN gltb.DebitAmount
                       ELSE 0
                   END NetWriteDown_Debit
                 , CASE
                       WHEN gle.Name IN(@WritedownAccount)
                            AND gltt.Name IN(@WriteDown, @WriteDownRecovery)
                       THEN gltb.CreditAmount
                       ELSE 0
                   END NetWriteDown_Credit
                 , CASE
                       WHEN gle.Name IN(@ChargeOffRecovery, @GainOnRecovery, @RecoveryIncome)
                       THEN gltb.DebitAmount
                       ELSE 0
                   END Recovery_Debit
                 , CASE
                       WHEN gle.Name IN(@ChargeOffRecovery, @GainOnRecovery, @RecoveryIncome)
                       THEN gltb.CreditAmount
                       ELSE 0
                   END Recovery_Credit
                 , CASE
                       WHEN gle.Name IN(@ChargeoffExpense)
                       THEN gltb.DebitAmount
                       ELSE 0
                   END ChargeOffExpense_Debit
                 , CASE
                       WHEN gle.Name IN(@ChargeoffExpense)
                       THEN gltb.CreditAmount
                       ELSE 0
                   END ChargeOffExpense_Credit
                 , CASE
                       WHEN gle.Name IN(@Receivable)
                            AND gltb.MatchingEntryName IN(@PrepaidPrincipalReceivable, @PrincipalReceivable)
                            AND gltt.Name IN(@ReceiptCash)
                       THEN gltb.DebitAmount
                       ELSE 0
                   END PrincipalCashPosting_Debit
                 , CASE
                       WHEN gle.Name IN(@Receivable)
                            AND gltb.MatchingEntryName IN(@PrepaidPrincipalReceivable, @PrincipalReceivable)
                            AND gltt.Name IN(@ReceiptCash)
                       THEN gltb.CreditAmount
                       ELSE 0
                   END PrincipalCashPosting_Credit
                 , CASE
                       WHEN gle.Name IN(@Receivable)
                            AND gltb.MatchingEntryName IN(@PrepaidInterestReceivable, @InterestReceivable)
                            AND gltt.Name IN(@ReceiptCash)
                       THEN gltb.DebitAmount
                       ELSE 0
                   END InterestCashPosting_Debit
                 , CASE
                       WHEN gle.Name IN(@Receivable)
                            AND gltb.MatchingEntryName IN(@PrepaidInterestReceivable, @InterestReceivable)
                            AND gltt.Name IN(@ReceiptCash)
                       THEN gltb.CreditAmount
                       ELSE 0
                   END InterestCashPosting_Credit
                 , CASE
                       WHEN gle.Name IN(@Receivable)
                            AND gltb.MatchingEntryName IN(@PrepaidPrincipalReceivable, @PrincipalReceivable)
                            AND gltt.Name IN(@ReceiptNonCash)
                       THEN gltb.DebitAmount
                       ELSE 0
                   END PrincipalNonCashPosting_Debit
                 , CASE
                       WHEN gle.Name IN(@Receivable)
                            AND gltb.MatchingEntryName IN(@PrepaidPrincipalReceivable, @PrincipalReceivable)
                            AND gltt.Name IN(@ReceiptNonCash)
                       THEN gltb.CreditAmount
                       ELSE 0
                   END PrincipalNonCashPosting_Credit
                 , CASE
                       WHEN gle.Name IN(@Receivable)
                            AND gltb.MatchingEntryName IN(@PrepaidInterestReceivable, @InterestReceivable)
                            AND gltt.Name IN(@ReceiptNonCash)
                       THEN gltb.DebitAmount
                       ELSE 0
                   END InterestNonCashPosting_Debit
                 , CASE
                       WHEN gle.Name IN(@Receivable)
                            AND gltb.MatchingEntryName IN(@PrepaidInterestReceivable, @InterestReceivable)
                            AND gltt.Name IN(@ReceiptNonCash)
                       THEN gltb.CreditAmount
                       ELSE 0
                   END InterestNonCashPosting_Credit
                 , CASE
                       WHEN gle.Name IN(@UnappliedAR)
                       THEN gltb.DebitAmount
                       ELSE 0
                   END UnAppliedCash_Debit
                 , CASE
                       WHEN gle.Name IN(@UnappliedAR) 
                       THEN gltb.CreditAmount
                       ELSE 0
                   END UnAppliedCash_Credit
                 , CASE
                       WHEN gle.Name IN(@DueToThirdPartyAR, @PrePaidDueToThirdPartyAR)
                            AND gltt.Name IN(@SyndicatedAR) 
                       THEN gltb.CreditAmount
                       ELSE 0
                   END DueToThirdPartyAR_Credit
                 , CASE
                       WHEN gle.Name IN(@DueToThirdPartyAR, @PrePaidDueToThirdPartyAR)
                            AND gltt.Name IN(@SyndicatedAR) 
                       THEN gltb.DebitAmount
                       ELSE 0
                   END DueToThirdPartyAR_Debit
                 , CASE
                       WHEN (gle.Name IN(@Receivable) AND gltb.MatchingEntryName IN(@PrePaidDueToThirdPartyAR))
							OR (gle.Name = @PrePaidDueToThirdPartyAR AND gltt.Name IN(@SyndicatedAR)) 
                       THEN gltb.CreditAmount
                       ELSE 0
                   END PrePaidDueToThirdPartyAR_Credit
                 , CASE
                       WHEN (gle.Name IN(@Receivable) AND gltb.MatchingEntryName IN(@PrePaidDueToThirdPartyAR))
							OR (gle.Name = @PrePaidDueToThirdPartyAR AND gltt.Name IN(@SyndicatedAR)) 
                       THEN gltb.DebitAmount
                       ELSE 0
                   END PrePaidDueToThirdPartyAR_Debit
				 , CASE
                       WHEN (gle.Name = @DueToThirdPartyAR
                            AND gltb.MatchingEntryName IS NULL)
                            OR (gle.Name = @Receivable
                               AND gltb.MatchingEntryName = @DueToThirdPartyAR)
                       THEN gltb.DebitAmount
                       ELSE 0
                   END LoanSyndicationOSAR_Debit
				 , CASE
                       WHEN (gle.Name = @DueToThirdPartyAR
                            AND gltb.MatchingEntryName IS NULL)
                            OR (gle.Name = @Receivable
                               AND gltb.MatchingEntryName = @DueToThirdPartyAR)
                       THEN gltb.CreditAmount
                       ELSE 0
                   END LoanSyndicationOSAR_Credit
                 , CASE
                       WHEN gle.Name IN('NonRentalReceivable', 'PrePaidNonRentalReceivable', 'DueFromInterCompanyReceivable', 'PrePaidDueFromInterCompanyReceivable')
                            AND gltt.Name IN('NonRentalAR')
							AND gltb.SourceId IN (SELECT ReceivableId FROM #SyndicationProceedsReceivables WHERE ContractId = gltb.ContractId) 
                       THEN gltb.CreditAmount
                       ELSE 0
                   END SyndicationProceeds_Credit
                 , CASE
                       WHEN gle.Name IN('NonRentalReceivable', 'PrePaidNonRentalReceivable', 'DueFromInterCompanyReceivable', 'PrePaidDueFromInterCompanyReceivable')
                            AND gltt.Name IN('NonRentalAR')
							AND gltb.SourceId IN (SELECT ReceivableId FROM #SyndicationProceedsReceivables WHERE ContractId = gltb.ContractId)  
                       THEN gltb.DebitAmount
                       ELSE 0
                   END SyndicationProceeds_Debit
                 , CASE
                       WHEN gle.Name IN('SalesTaxReceivable', 'PrePaidSalesTaxReceivable')
                            AND gltt.Name = 'SalesTax'
                       THEN gltb.DebitAmount
                       ELSE 0
                   END SalesTaxReceivableAR_Debit
                 , CASE
                       WHEN gle.Name IN('SalesTaxReceivable', 'PrePaidSalesTaxReceivable')
                            AND gltt.Name = 'SalesTax'
                       THEN gltb.CreditAmount
                       ELSE 0
                   END SalesTaxReceivableAR_Credit
                 , CASE
                       WHEN (gle.Name IN('SalesTaxReceivable') AND gltt.Name = 'SalesTax')
							OR (gle.Name = @Receivable AND gltb.MatchingEntryName ='SalesTaxReceivable')
                       THEN gltb.DebitAmount
                       ELSE 0
                   END SalesTaxReceivableOSAR_Debit
                 , CASE
                       WHEN (gle.Name IN('SalesTaxReceivable') AND gltt.Name = 'SalesTax')
							OR (gle.Name = @Receivable AND gltb.MatchingEntryName ='SalesTaxReceivable')
                       THEN gltb.CreditAmount
                       ELSE 0
                   END SalesTaxReceivableOSAR_Credit
                 , CASE
                       WHEN (gle.Name IN(@Receivable) AND gltb.MatchingEntryName IN('PrepaidSalesTaxReceivable'))
							OR (gle.Name = 'PrepaidSalesTaxReceivable' AND gltt.Name IN('SalesTax')) 
                       THEN gltb.DebitAmount
                       ELSE 0
                   END SalesTaxReceivablePrepaid_Debit
                 , CASE
                       WHEN (gle.Name IN(@Receivable) AND gltb.MatchingEntryName IN('PrepaidSalesTaxReceivable'))
							OR (gle.Name = 'PrepaidSalesTaxReceivable' AND gltt.Name IN('SalesTax')) 
                       THEN gltb.CreditAmount
                       ELSE 0
                   END SalesTaxReceivablePrepaid_Credit
                 , CASE
                       WHEN gle.Name IN('SyndicatedSalesTaxReceivable')
                            AND gltt.Name = 'SalesTax'
                       THEN gltb.DebitAmount
                       ELSE 0
                   END SalesTaxFunderReceivableLessorRemitting_Debit
                 , CASE
                       WHEN gle.Name IN('SyndicatedSalesTaxReceivable')
                            AND gltt.Name = 'SalesTax'
                       THEN gltb.CreditAmount
                       ELSE 0
                   END SalesTaxFunderReceivableLessorRemitting_Credit
                 , CASE
                       WHEN (gle.Name IN('SyndicatedSalesTaxReceivable') AND gltt.Name = 'SalesTax')
							OR (gle.Name = @Receivable AND gltb.MatchingEntryName ='SyndicatedSalesTaxReceivable')
                       THEN gltb.DebitAmount
                       ELSE 0
                   END SalesTaxFunderReceivableLessorRemittingOSAR_Debit
                 , CASE
                       WHEN (gle.Name IN('SyndicatedSalesTaxReceivable') AND gltt.Name = 'SalesTax')
							OR (gle.Name = @Receivable AND gltb.MatchingEntryName ='SyndicatedSalesTaxReceivable')
                       THEN gltb.CreditAmount
                       ELSE 0
                   END SalesTaxFunderReceivableLessorRemittingOSAR_Credit
                 , CASE
                       WHEN (gle.Name IN(@Receivable) AND gltb.MatchingEntryName IN('PrePaidSyndicatedSalesTaxReceivable'))
							OR (gle.Name = 'PrePaidSyndicatedSalesTaxReceivable' AND gltt.Name IN('SalesTax')) 
                       THEN gltb.DebitAmount
                       ELSE 0
                   END SalesTaxReceivablePrepaidFunderPortion_Debit
                 , CASE
                       WHEN (gle.Name IN(@Receivable) AND gltb.MatchingEntryName IN('PrePaidSyndicatedSalesTaxReceivable'))
							OR (gle.Name = 'PrePaidSyndicatedSalesTaxReceivable' AND gltt.Name IN('SalesTax')) 
                       THEN gltb.CreditAmount
                       ELSE 0
                   END SalesTaxReceivablePrepaidFunderPortion_Credit
                 , CASE
                       WHEN gle.Name IN('RentDueToInvestorAP')
                            AND gltt.Name = 'DueToInvestorAP'
                       THEN gltb.DebitAmount
                       ELSE 0
                   END RentDueToInvestor_Debit
                 , CASE
                       WHEN gle.Name IN('RentDueToInvestorAP')
                            AND gltt.Name = 'DueToInvestorAP'
                       THEN gltb.CreditAmount
                       ELSE 0
                   END RentDueToInvestor_Credit
                 , CASE
                       WHEN gle.Name IN(@GainLossAdjustment)
                            AND gltt.Name = @Paydown
							AND (loan.SyndicationGLJournalId IS NOT NULL AND gltb.GLJournalId = loan.SyndicationGLJournalId)
                       THEN gltb.DebitAmount
                       ELSE 0
                   END SyndicationGainLossAdjustment_Debit
                 , CASE
                       WHEN gle.Name IN(@GainLossAdjustment)
                            AND gltt.Name = @Paydown
							AND (loan.SyndicationGLJournalId IS NOT NULL AND gltb.GLJournalId = loan.SyndicationGLJournalId) 
                       THEN gltb.CreditAmount
                       ELSE 0
                   END SyndicationGainLossAdjustment_Credit
                 , CASE
                       WHEN gle.Name IN(@Receivable)
                            AND gltb.MatchingEntryName IN(@DueToThirdPartyAR, @PrePaidDueToThirdPartyAR)
                            AND gltt.Name IN(@ReceiptCash)
                       THEN gltb.DebitAmount
                       ELSE 0
                   END SyndicatedCashPosting_Debit
                 , CASE
                       WHEN gle.Name IN(@Receivable)
                            AND gltb.MatchingEntryName IN(@DueToThirdPartyAR, @PrePaidDueToThirdPartyAR)
                            AND gltt.Name IN(@ReceiptCash)
                       THEN gltb.CreditAmount
                       ELSE 0
                   END SyndicatedCashPosting_Credit
                 , CASE
                       WHEN gle.Name IN(@Receivable)
                            AND gltb.MatchingEntryName IN(@DueToThirdPartyAR, @PrePaidDueToThirdPartyAR)
                            AND gltt.Name IN(@ReceiptNonCash)
                       THEN gltb.DebitAmount
                       ELSE 0
                   END SyndicatedNonCashPosting_Debit
                 , CASE
                       WHEN gle.Name IN(@Receivable)
                            AND gltb.MatchingEntryName IN(@DueToThirdPartyAR, @PrePaidDueToThirdPartyAR)
                            AND gltt.Name IN(@ReceiptNonCash)
                       THEN gltb.CreditAmount
                       ELSE 0
                   END SyndicatedNonCashPosting_Credit
                 , CASE
                       WHEN gle.Name IN(@Receivable)
                            AND gltb.MatchingEntryName IN('SyndicatedSalesTaxReceivable', 'PrePaidSyndicatedSalesTaxReceivable')
                            AND gltt.Name IN(@ReceiptCash)
                       THEN gltb.DebitAmount
                       ELSE 0
                   END LessorOwnedCashPosting_Debit
                 , CASE
                       WHEN gle.Name IN(@Receivable)
                            AND gltb.MatchingEntryName IN('SyndicatedSalesTaxReceivable', 'PrePaidSyndicatedSalesTaxReceivable')
                            AND gltt.Name IN(@ReceiptCash)
                       THEN gltb.CreditAmount
                       ELSE 0
                   END LessorOwnedCashPosting_Credit
                 , CASE
                       WHEN gle.Name IN(@Receivable)
                            AND gltb.MatchingEntryName IN('SyndicatedSalesTaxReceivable', 'PrePaidSyndicatedSalesTaxReceivable')
                            AND gltt.Name IN(@ReceiptNonCash)
                       THEN gltb.DebitAmount
                       ELSE 0
                   END LessorOwnedNonCashPosting_Debit
                 , CASE
                       WHEN gle.Name IN(@Receivable)
                            AND gltb.MatchingEntryName IN('SyndicatedSalesTaxReceivable', 'PrePaidSyndicatedSalesTaxReceivable')
                            AND gltt.Name IN(@ReceiptNonCash)
                       THEN gltb.CreditAmount
                       ELSE 0
                   END LessorOwnedNonCashPosting_Credit
                 , CASE
                       WHEN gle.Name IN(@Receivable)
                            AND gltb.MatchingEntryName IN('SalesTaxReceivable', 'PrePaidSalesTaxReceivable')
                            AND gltt.Name IN(@ReceiptCash)
                       THEN gltb.DebitAmount
                       ELSE 0
                   END LessorPortionCashPosting_Debit
                 , CASE
                       WHEN gle.Name IN(@Receivable)
                            AND gltb.MatchingEntryName IN('SalesTaxReceivable', 'PrePaidSalesTaxReceivable')
                            AND gltt.Name IN(@ReceiptCash)
                       THEN gltb.CreditAmount
                       ELSE 0
                   END LessorPortionCashPosting_Credit
                 , CASE
                       WHEN gle.Name IN(@Receivable)
                            AND gltb.MatchingEntryName IN('SalesTaxReceivable', 'PrePaidSalesTaxReceivable')
                            AND gltt.Name IN(@ReceiptNonCash)
                       THEN gltb.DebitAmount
                       ELSE 0
                   END LessorPortionNonCashPosting_Debit
                 , CASE
                       WHEN gle.Name IN(@Receivable)
                            AND gltb.MatchingEntryName IN('SalesTaxReceivable', 'PrePaidSalesTaxReceivable')
                            AND gltt.Name IN(@ReceiptNonCash)
                       THEN gltb.CreditAmount
                       ELSE 0
                   END LessorPortionNonCashPosting_Credit
            FROM #GLTrialBalance gltb
                 INNER JOIN GLEntryItems gle ON gltb.EntryItemId = gle.Id
                 INNER JOIN GLTransactionTypes gltt ON gle.GLTransactionTypeId = gltt.Id
				 INNER JOIN #LoanDetails loan ON gltb.ContractId = loan.ContractId
        ) AS RS1
        GROUP BY RS1.ContractId;

		CREATE NONCLUSTERED INDEX IX_Id ON #LoanGLJournalValues(ContractId);
		

		UPDATE gl
		  SET 
			  PrincipalBalance_GL = PrincipalBalance_GL + PrincipalBalance
			 ,UnAppliedCash_GL = UnAppliedCash_GL -  UnAppliedAmount
		FROM #LoanGLJournalValues gl
			 INNER JOIN(
			SELECT gl.ContractId
				 , SUM(CASE
						   WHEN lfbt.PayableId = gltb.SourceId
								AND gle.Name = @Disbursement
						   THEN gltb.DebitAmount - gltb.CreditAmount 
						   ELSE 0.00
					   END) AS PrincipalBalance
				 , SUM(CASE
						   WHEN lfbt.PayableId = gltb.SourceId
								AND gltt.Name = 'PayableCash'
						   THEN gltb.CreditAmount - gltb.DebitAmount
						   ELSE 0.00
					   END) AS UnAppliedAmount
			FROM #LoanGLJournalValues gl
				 INNER JOIN #GLTrialBalance gltb ON gl.ContractId = gltb.ContractId
				 INNER JOIN GLEntryItems gle ON gltb.EntryItemId = gle.Id
                 INNER JOIN GLTransactionTypes gltt ON gle.GLTransactionTypeId = gltt.Id
				 INNER JOIN #LoanDetails ld ON gltb.ContractId = ld.ContractId
				 INNER JOIN #LoanFinanceBasicTemp lfbt ON lfbt.ContractId = gltb.ContractId
														  AND (lfbt.IsOrigination != @True OR (lfbt.IsOrigination = @True AND lfbt.DisbursementRequestStatus = @CompletedStatus AND ld.Status = @Uncommenced))
			GROUP BY gl.ContractId
		) AS t ON t.ContractId = gl.ContractId;

        UPDATE gl
          SET 
              TotalFinancedAmount_GL = ltv.TotalFinancedAmount_Amount
        FROM #LoanGLJournalValues gl
             INNER JOIN #LoanDetails ld ON gl.ContractId = ld.ContractId
             INNER JOIN #LoanTableValues ltv ON ltv.ContractId = ld.ContractId
        WHERE ld.IsMigratedContract = 1;

		
        /**************************************************************************************************************************/
        /*Additional Output Columns*/

        SELECT bd.ContractId
             , MAX(nc.Id) AS NonAccrualContractId
             , MAX(rac.Id) AS ReAccrualContractId
             , MAX(rac.ReAccrualDate) AS ReAccrualDate
             , MAX(nc.NonAccrualDate) AS NonAccrualDate
        INTO #AccrualDetails
        FROM #BasicDetails bd
             LEFT JOIN NonAccrualContracts nc ON nc.ContractId = bd.ContractId
                                                 AND nc.IsActive = 1
             LEFT JOIN ReAccrualContracts rac ON rac.ContractId = bd.ContractId
                                                 AND RAC.IsActive = 1
        GROUP BY bd.ContractId;

        SELECT ContractId
             , SUM(PostedPrincipalReceivableSum) AS PostedPrincipalReceivableSum
             , SUM(PostedInterestReceivableSum) AS PostedInterestReceivableSum
        INTO #ReceivableSumAmount
        FROM
        (
            SELECT Loan.ContractId
                 , CASE
                       WHEN ld.IsChargedOff = 0
                            AND Receivable.ReceivableType = @LoanInterest
                            AND Receivable.IsGLPosted = 1
                       THEN Receivable.Amount_Amount
                       ELSE 0.00
                   END AS PostedInterestReceivableSum
                 , CASE
                       WHEN ld.IsChargedOff = 0
                            AND Receivable.ReceivableType = @LoanPrincipal
                            AND Receivable.IsGLPosted = 1
                       THEN Receivable.Amount_Amount
                       ELSE 0.00
                   END AS PostedPrincipalReceivableSum
            FROM #BasicDetails Loan
                 INNER JOIN #LoanDetails ld ON Loan.ContractId = ld.ContractId
                 JOIN #ReceivableDetailsTemp Receivable ON Loan.ContractId = Receivable.ContractId
            WHERE Receivable.IsDummy = 0
				  AND Receivable.FunderId IS NULL
        ) AS t
        GROUP BY ContractId;

		CREATE NONCLUSTERED INDEX IX_Id ON #ReceivableSumAmount(ContractId);

        SELECT temp.ContractId
             , SUM(CASE WHEN lp.PaydownDate = Contract.SyndicationEffectiveDate AND lp.CreatedTime < Contract.SyndicationCreatedTIme
						THEN GainLoss_Amount
						WHEN Contract.SyndicationEffectiveDate > lp.PaydownDate OR Contract.SyndicationEffectiveDate IS NULL
						THEN GainLoss_Amount
						ELSE GainLoss_Amount * Contract.RetainedPortion
					END) AS TotalGainAmount
        INTO #TotalGainAmount
        FROM #LoanPaydownTemp temp
             INNER JOIN LoanPaydowns lp ON temp.Id = lp.Id
			 INNER JOIN #LoanDetails Contract ON Contract.ContractId = temp.ContractId
        GROUP BY temp.ContractId;

        UPDATE lt
          SET 
              SuspendedIncomeBalance_Amount = t.Amount
        FROM #LoanTableValues lt
             INNER JOIN
        (
            SELECT IncomeSched.ContractId
                 , SUM(IncomeSched.InterestAccrued_Amount) AS Amount
            FROM #LoanIncomeScheduleTemp IncomeSched
            WHERE IncomeSched.IsAccounting = 1
                  AND IncomeSched.IsGLPosted = 1
                  AND IncomeSched.IsNonAccrual = 1
				  AND IncomeSched.IsLessorOwned = 1
            GROUP BY IncomeSched.ContractId
        ) AS t ON t.ContractId = lt.ContractId;

        SELECT Loan.ContractId
             , SUM(CASE
                       WHEN IsRecovery = 0
                       THEN WriteDownAmount_Amount
                       ELSE 0
                   END) AS GrossWriteDown
             , SUM(WriteDownAmount_Amount) AS NetWriteDown
        INTO #WriteDown
        FROM WriteDowns wd
             INNER JOIN #BasicDetails Loan ON wd.ContractId = Loan.ContractId
        WHERE Status = 'Approved'
        GROUP BY Loan.ContractId;


		IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ChargeOffs' AND COLUMN_NAME = 'LeaseComponentGain_Amount')
		BEGIN
			SET @IsGainPresent = 1
			SET @SQL =	
				'SELECT ec.ContractId
					 , SUM(CASE
							   WHEN co.IsRecovery = 0
							   THEN co.LeaseComponentAmount_Amount
							   ELSE 0.00
						   END) [ChargeOffExpense_LC_Table]
					 , SUM(CASE
							   WHEN co.IsRecovery = 0
							   THEN co.NonLeaseComponentAmount_Amount
							   ELSE 0.00
						   END) [ChargeOffExpense_NLC_Table]
					 , SUM(CASE
							   WHEN co.IsRecovery = 1
							   THEN co.LeaseComponentAmount_Amount * (-1)
							   ELSE 0.00
						   END) [ChargeOffRecovery_LC_Table]
					 , SUM(CASE
							   WHEN co.IsRecovery = 1
							   THEN co.NonLeaseComponentAmount_Amount * (-1)
							   ELSE 0.00
						   END) [ChargeOffRecovery_NLC_Table]
					, SUM(CASE
							 WHEN co.IsRecovery = 0
							 THEN co.ChargeOffAmount_Amount
						  END) AS ChargeOffExpense
				   , SUM(CASE
							 WHEN co.IsRecovery = 1
							 THEN co.ChargeOffAmount_Amount  * (-1)
						  END) AS ChargeOffRecovery
				   , SUM(CASE
							 WHEN co.IsRecovery = 1
							 THEN co.LeaseComponentGain_Amount * (-1)   
						  END) AS GainOnRecovery_LC_Table
				   , SUM(CASE
							 WHEN co.IsRecovery = 1
							 THEN co.NonLeaseComponentGain_Amount * (-1)   
						  END) AS GainOnRecovery_NLC_Table	
				FROM #BasicDetails ec
					 INNER JOIN ChargeOffs co ON co.ContractId = ec.ContractId
				WHERE co.IsActive = 1
					  AND co.Status = ''Approved''
					  AND co.PostDate IS NOT NULL
				GROUP BY ec.ContractId;'
				INSERT INTO #ChargeOffDetails
				EXEC(@SQL)
			END


		IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ChargeOffs' AND COLUMN_NAME = 'LeaseComponentGain_Amount')
		BEGIN
		SET @IsGainPresent = 0
        INSERT INTO #ChargeOffDetails
		SELECT ec.ContractId
			 , SUM(CASE
					   WHEN co.IsRecovery = 0
					   THEN co.ChargeOffAmount_Amount
					   ELSE 0.00
				   END) AS [ChargeOffExpense_LC_Table]
			 , 0.00 AS [ChargeOffExpense_NLC_Table]
			 , SUM(CASE
					   WHEN co.IsRecovery = 1
					   THEN co.ChargeOffAmount_Amount * (-1)
					   ELSE 0.00
				   END) AS [ChargeOffRecovery_LC_Table]
			 , 0.00 AS [ChargeOffRecovery_NLC_Table]
			 , SUM(CASE
					   WHEN co.IsRecovery = 0
					   THEN co.ChargeOffAmount_Amount
				   END) AS ChargeOffExpense
			 , SUM(CASE
					   WHEN co.IsRecovery = 1
					   THEN co.ChargeOffAmount_Amount  * (-1)
				   END) AS ChargeOffRecovery
			 , 0.00 AS GainOnRecovery_LC_Table
			 , 0.00 AS GainOnRecovery_NLC_Table
		FROM #BasicDetails ec
			 INNER JOIN ChargeOffs co ON co.ContractId = ec.ContractId
		WHERE co.IsActive = 1
			  AND co.Status = 'Approved'
			  AND co.PostDate IS NOT NULL
		GROUP BY ec.ContractId;
		END

		MERGE #ChargeOffDetails AS [Target]
		USING(
            SELECT wd.ContractId
                 , SUM(CASE
                           WHEN wd.IsRecovery = 1
                           THEN ISNULL(wd.WriteDownAmount_Amount, 0)
                           ELSE 0
                       END) AS RecoveryAmount
            FROM WriteDowns wd
            WHERE wd.Status = 'Approved'
            GROUP BY wd.ContractId
        ) AS [Source]
		ON (Target.ContractId = Source.ContractId)
		WHEN MATCHED
			 THEN UPDATE SET ChargeOffRecovery = ChargeOffRecovery + [Source].RecoveryAmount,
			                 [ChargeOffRecovery_LC_Table] = [ChargeOffRecovery_LC_Table] + [Source].RecoveryAmount
		WHEN NOT MATCHED
		 THEN
		 INSERT (ContractId, ChargeOffRecovery, [ChargeOffRecovery_LC_Table])
		 VALUES ([Source].ContractId, [Source].RecoveryAmount, [Source].RecoveryAmount);
		
		
		SELECT Contract.ContractId
			 , receipt.ReceiptClassification
			 , rt.ReceiptTypeName
			 , Contract.IsNonAccrual
			 , r.ReceivableType
			 , lps.StartDate
			 , rard.BookAmountApplied_Amount
			 , rard.AmountApplied_Amount
			 , rard.GainAmount_Amount
			 , rard.RecoveryAmount_Amount
			 , IIF(rard.RecoveryAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS RecoveryAmount_LC
			 , IIF(rard.GainAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS GainAmount_LC
			 , CAST(0.00 AS DECIMAL(16, 2)) AS ChargeoffExpenseAmount
			 , CAST(0.00 AS DECIMAL(16, 2)) AS ChargeoffExpenseAmount_LC
			 , ReceiptId
			 , Receipt.Status AS ReceiptStatus
			 , r.IsGLPosted
			 , r.AccountingTreatment
			 , rard.Id AS RardId
			 , r.DueDate
			 , NULL AS IsRecovery
			 , detail.ChargeOffDate
			 , Contract.IsAdvance
			 , rard.TaxApplied_Amount
		INTO #ReceiptApplicationReceivableDetails
		FROM #LoanDetails Contract
			 JOIN #BasicDetails detail ON Contract.ContractId = detail.ContractId
			 JOIN Receipts Receipt ON Receipt.STATUS IN(@PostedStatus, @CompletedStatus, @ReversedStatus)
			 JOIN ReceiptTypes rt ON rt.Id = Receipt.TypeId
			 JOIN ReceiptApplications ra ON ra.ReceiptId = Receipt.Id
			 JOIN ReceiptApplicationReceivableDetails rard ON rard.ReceiptApplicationId = ra.Id
			 JOIN ReceivableDetails rd ON rd.Id = rard.ReceivableDetailId
			 JOIN #ReceivableDetailsTemp r ON r.ReceivableId = rd.ReceivableId
											  AND r.ContractId = Contract.ContractId
			 LEFT JOIN LoanPaymentSchedules lps ON r.PaymentScheduleId = lps.Id
		WHERE rard.IsActive = 1
			  AND r.FunderId IS NULL;

			SELECT c.Id
				 , co.ReceiptId
				 , 0.00 AS LeaseComponentAmount_Amount
				 , 0.00 AS LeaseComponentGain_Amount
			INTO #ChargeoffRecoveryReceiptIds
			FROM Contracts c
				 INNER JOIN ChargeOffs co ON co.ContractId = c.Id
			WHERE co.IsActive = 1
				  AND co.Status = 'Approved'
				  AND co.IsRecovery = 1
				  AND co.ReceiptId IS NOT NULL
				  AND co.ContractId IN (SELECT Distinct c.ContractId FROM #LoanDetails c) 
			GROUP BY co.ReceiptId
				   , c.Id ;


		CREATE NONCLUSTERED INDEX IX_Id ON #ChargeoffRecoveryReceiptIds(Id, ReceiptId);

		SELECT DISTINCT 
			   r.ContractId
			 , rt.ReceiptTypeName
			 , receipt.Id
			 , r.RecoveryAmount_Amount
			 , r.GainAmount_Amount
			 , r.StartDate
			 , IIF(r.RecoveryAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS RecoveryAmount_LC
			 , IIF(r.GainAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS GainAmount_LC
			 , r.BookAmountApplied_Amount AS BookAmountApplied
			 , r.RardId
			 , r.IsNonAccrual
		INTO #NonSKUChargeoffRecoveryRecords
		FROM #ReceiptApplicationReceivableDetails r
			 JOIN Receipts receipt ON r.ReceiptId = Receipt.Id
			 JOIN ReceiptTypes rt ON rt.Id = receipt.TypeId
			 JOIN #ChargeoffRecoveryReceiptIds co ON r.ContractId = co.Id
													AND co.ReceiptId = receipt.Id
		WHERE r.ReceivableType IN ('LoanInterest', 'LoanPrincipal')

		CREATE NONCLUSTERED INDEX IX_Id ON #NonSKUChargeoffRecoveryRecords(RardId);


		UPDATE #NonSKUChargeoffRecoveryRecords SET 
												   RecoveryAmount_LC = BookAmountApplied
		WHERE RecoveryAmount_Amount != 0.00
			  AND IsNonAccrual = 1 AND RecoveryAmount_Amount = BookAmountApplied;

		UPDATE #NonSKUChargeoffRecoveryRecords SET 
												   GainAmount_LC = BookAmountApplied
		WHERE GainAmount_Amount != 0.00
			 AND RecoveryAmount_Amount = BookAmountApplied;

		UPDATE rard SET 
						RecoveryAmount_LC = ISNULL(coe.RecoveryAmount_LC, 0.00)
					  , GainAmount_LC = ISNULL(coe.GainAmount_LC, 0.00)
					  , IsRecovery = CAST(1 AS BIT)
		FROM #ReceiptApplicationReceivableDetails rard
			 INNER JOIN #NonSKUChargeoffRecoveryRecords coe ON coe.RardId = rard.RardId;

	-- Chargeoff Expense logic
		SELECT c.Id
			 , co.ReceiptId
			 , 0.00 AS LeaseComponentAmount_Amount
			 , 0.00 AS LeaseComponentGain_Amount
		INTO #ChargeoffExpenseReceiptIds
		FROM Contracts c
			 INNER JOIN ChargeOffs co ON co.ContractId = c.Id
		WHERE co.IsActive = 1
			  AND co.Status = 'Approved'
			  AND co.IsRecovery = 0
			  AND co.ReceiptId IS NOT NULL
			  AND co.ContractId IN (SELECT Distinct c.ContractId FROM #LoanDetails c) 
		GROUP BY c.Id
			   , co.ReceiptId;

	CREATE NONCLUSTERED INDEX IX_Id ON #ChargeoffExpenseReceiptIds(Id, ReceiptId);
	
	SELECT DISTINCT
	  r.ContractId
	, r.ReceiptTypeName
	, r.ReceiptId
	, r.BookAmountApplied_Amount
	, r.RecoveryAmount_Amount
	, r.GainAmount_Amount
	, r.StartDate
	, r.BookAmountApplied_Amount - (r.RecoveryAmount_Amount + r.GainAmount_Amount) AS ChargeoffExpenseAmount
	, IIF(r.BookAmountApplied_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)),CAST(0 AS DECIMAL(16, 2)))  AS ChargeoffExpenseAmount_LC
	, IIF(r.RecoveryAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS RecoveryAmount_LC
	, IIF(r.GainAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS GainAmount_LC
	, r.RardId
	INTO #NonSKUChargeoffExpenseRecords
	FROM #ReceiptApplicationReceivableDetails r
	JOIN #ChargeoffExpenseReceiptIds co ON r.ContractId = co.Id
										   AND co.ReceiptId = r.ReceiptId
	WHERE r.ReceivableType IN ('LoanInterest', 'LoanPrincipal')
		    
	UPDATE #NonSKUChargeoffExpenseRecords SET 
											  ChargeoffExpenseAmount_LC = 0.00
	WHERE ChargeoffExpenseAmount = 0.00;

	UPDATE #NonSKUChargeoffExpenseRecords SET 
											  ChargeoffExpenseAmount_LC = ChargeoffExpenseAmount
	WHERE ChargeoffExpenseAmount != 0.00;



	UPDATE rard SET 
					  RecoveryAmount_LC = ISNULL(coe.RecoveryAmount_LC, 0.00)
					, GainAmount_LC = ISNULL(coe.GainAmount_LC, 0.00)
					, ChargeoffExpenseAmount_LC = ISNULL(coe.ChargeoffExpenseAmount_LC, 0.00)
					, IsRecovery = CAST(0 AS BIT)
	FROM #ReceiptApplicationReceivableDetails rard
			INNER JOIN #NonSKUChargeoffExpenseRecords coe ON coe.RardId = rard.RardId;
 
        SELECT t.ContractId
             , SUM(PrincipalCashPosted) AS PrincipalCashPosted
             , SUM(PrincipalNonCashPosted) AS PrincipalNonCashPosted
             , SUM(InterestCashPosted) AS InterestCashPosted
             , SUM(InterestNonCashPosted) AS InterestNonCashPosted
			 , SUM(TaxCashPosted) AS TaxCashPosted
			 , SUM(TaxNonCashPosted) AS TaxNonCashPosted
			 , SUM(PrincipalBalanceAmount) AS PrincipalBalanceAmount
			 , SUM(InterestBalanceAmount) AS InterestBalanceAmount
        INTO #ReceiptDetails
        FROM
        (
            SELECT ContractId
                 , CASE
                       WHEN ReceiptClassification IN('Cash', 'NonAccrualNonDSL') AND ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit')
                            AND ReceivableType = @LoanPrincipal
							AND RecoveryAmount_Amount = 0.00 AND GainAmount_Amount = 0.00 AND ChargeoffExpenseAmount_LC = 0.00 AND (ChargeOffDate IS NULL OR (IsAdvance = 0 AND StartDate < ChargeOffDate) OR (IsAdvance = 1 AND StartDate <= ChargeOffDate))
                       THEN CASE
                                WHEN IsNonAccrual = 1
                                THEN BookAmountApplied_Amount
                                ELSE AmountApplied_Amount
                            END
                       ELSE 0
                   END AS PrincipalCashPosted
                 , CASE
                       WHEN (ReceiptClassification NOT IN('Cash', 'NonAccrualNonDSL') OR ReceiptTypeName IN ('PayableOffset', 'SecurityDeposit'))
                            AND ReceivableType = @LoanPrincipal
							AND RecoveryAmount_Amount = 0.00 AND GainAmount_Amount = 0.00 AND ChargeoffExpenseAmount_LC = 0.00 AND (ChargeOffDate IS NULL OR (IsAdvance = 0 AND StartDate < ChargeOffDate) OR (IsAdvance = 1 AND StartDate <= ChargeOffDate))
                       THEN CASE
                                WHEN IsNonAccrual = 1
                                THEN BookAmountApplied_Amount
                                ELSE AmountApplied_Amount
                            END
                       ELSE 0
                   END AS PrincipalNonCashPosted
                 , CASE
                       WHEN ReceiptClassification IN('Cash', 'NonAccrualNonDSL') AND ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit')
                            AND ReceivableType = @LoanInterest
							AND RecoveryAmount_Amount = 0.00 AND GainAmount_Amount = 0.00 AND ChargeoffExpenseAmount_LC = 0.00 AND (ChargeOffDate IS NULL OR (IsAdvance = 0 AND StartDate < ChargeOffDate) OR (IsAdvance = 1 AND StartDate <= ChargeOffDate))
                       THEN CASE
                                WHEN IsNonAccrual = 1
                                THEN BookAmountApplied_Amount
                                ELSE AmountApplied_Amount
                            END
                       ELSE 0
                   END AS InterestCashPosted
                 , CASE
                       WHEN (ReceiptClassification NOT IN('Cash', 'NonAccrualNonDSL') OR ReceiptTypeName IN ('PayableOffset', 'SecurityDeposit'))
                            AND ReceivableType = @LoanInterest
							AND RecoveryAmount_Amount = 0.00 AND GainAmount_Amount = 0.00 AND ChargeoffExpenseAmount_LC = 0.00 AND (ChargeOffDate IS NULL OR (IsAdvance = 0 AND StartDate < ChargeOffDate) OR (IsAdvance = 1 AND StartDate <= ChargeOffDate))
                       THEN CASE
                                WHEN IsNonAccrual = 1
                                THEN BookAmountApplied_Amount
                                ELSE AmountApplied_Amount
                            END
                       ELSE 0
                   END AS InterestNonCashPosted
                 , CASE
                       WHEN ReceiptClassification IN('Cash', 'NonAccrualNonDSL') AND ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit')
                       THEN TaxApplied_Amount
                       ELSE 0
                   END AS TaxCashPosted
                 , CASE
                       WHEN (ReceiptClassification NOT IN('Cash', 'NonAccrualNonDSL') OR ReceiptTypeName IN ('PayableOffset', 'SecurityDeposit'))
                       THEN TaxApplied_Amount
                       ELSE 0
                   END AS TaxNonCashPosted
                 , CASE
                       WHEN ((IsAdvance = 0 AND StartDate < ChargeOffDate) OR (IsAdvance = 1 AND StartDate <= ChargeOffDate))
							AND ReceivableType = @LoanPrincipal	
							AND RecoveryAmount_Amount = 0.00 AND GainAmount_Amount = 0.00 AND ChargeoffExpenseAmount_LC = 0.00
                       THEN BookAmountApplied_Amount
                       ELSE 0
                   END AS PrincipalBalanceAmount
                 , CASE
                       WHEN ((IsAdvance = 0 AND StartDate < ChargeOffDate) OR (IsAdvance = 1 AND StartDate <= ChargeOffDate))
							AND ReceivableType = @LoanInterest
							AND RecoveryAmount_Amount = 0.00  AND GainAmount_Amount = 0.00 AND ChargeoffExpenseAmount_LC = 0.00
                       THEN BookAmountApplied_Amount
                       ELSE 0
                   END AS InterestBalanceAmount
            FROM #ReceiptApplicationReceivableDetails
			WHERE ReceiptStatus IN ('Posted', 'Completed')
        ) AS t
        GROUP BY t.ContractId;

		SELECT t.ContractId
			 , SUM(CashPosted) + SUM(CashTaxApplied) AS CashPosted
			 , SUM(NonCashPosted) + SUM(NonCashTaxApplied) AS NonCashPosted
			 , SUM(LessorRemittanceCashTaxApplied) AS LessorRemittanceCashTaxApplied
			 , SUM(LessorRemittanceNonCashTaxApplied) AS LessorRemittanceNonCashTaxApplied
		INTO #FunderCashPostedAmount
		FROM
		(
			SELECT Contract.ContractId
				 , CASE
					   WHEN ReceiptClassification IN('Cash', 'NonAccrualNonDSL') AND rt.ReceiptTypeName NOT IN('PayableOffset', 'SecurityDeposit')
					   THEN CASE
								WHEN Contract.IsNonAccrual = 1
								THEN rard.BookAmountApplied_Amount
								ELSE rard.AmountApplied_Amount
							END
					   ELSE 0
				   END AS CashPosted
				 , CASE
					   WHEN ReceiptClassification NOT IN('Cash', 'NonAccrualNonDSL') OR rt.ReceiptTypeName IN('PayableOffset', 'SecurityDeposit')
					   THEN CASE
								WHEN Contract.IsNonAccrual = 1
								THEN rard.BookAmountApplied_Amount
								ELSE rard.AmountApplied_Amount
							END
					   ELSE 0
				   END AS NonCashPosted
				 , CASE
					   WHEN funderRemitting.ContractId IS NOT NULL AND ReceiptClassification IN('Cash', 'NonAccrualNonDSL') AND rt.ReceiptTypeName NOT IN('PayableOffset', 'SecurityDeposit')
					   THEN rard.TaxApplied_Amount
					   ELSE 0.00
				   END AS CashTaxApplied
				 , CASE
					   WHEN funderRemitting.ContractId IS NOT NULL AND (ReceiptClassification NOT IN('Cash', 'NonAccrualNonDSL') OR rt.ReceiptTypeName IN('PayableOffset', 'SecurityDeposit'))
					   THEN rard.TaxApplied_Amount
					   ELSE 0.00
				   END AS NonCashTaxApplied
				 , CASE
					   WHEN funderRemitting.ContractId IS NULL AND ReceiptClassification IN('Cash', 'NonAccrualNonDSL') AND rt.ReceiptTypeName NOT IN('PayableOffset', 'SecurityDeposit')
					   THEN rard.TaxApplied_Amount
					   ELSE 0.00
				   END AS LessorRemittanceCashTaxApplied
				 , CASE
					   WHEN funderRemitting.ContractId IS NULL AND (ReceiptClassification NOT IN('Cash', 'NonAccrualNonDSL') OR rt.ReceiptTypeName IN('PayableOffset', 'SecurityDeposit'))
					   THEN rard.TaxApplied_Amount
					   ELSE 0.00
				   END AS LessorRemittanceNonCashTaxApplied
			FROM #LoanDetails Contract
				 JOIN #BasicDetails detail ON Contract.ContractId = detail.ContractId
				 JOIN Receipts Receipt ON Receipt.Status IN(@PostedStatus, @CompletedStatus)
				 JOIN ReceiptTypes rt ON rt.Id = Receipt.TypeId
				 JOIN ReceiptApplications ra ON ra.ReceiptId = Receipt.Id
				 JOIN ReceiptApplicationReceivableDetails rard ON rard.ReceiptApplicationId = ra.Id
				 JOIN ReceivableDetails rd ON rd.Id = rard.ReceivableDetailId
				 JOIN #ReceivableDetailsTemp r ON r.ReceivableId = rd.ReceivableId
												  AND r.ContractId = Contract.ContractId
				 LEFT JOIN #SyndicationFunderRemitting funderRemitting ON funderRemitting.ContractId = Contract.ContractId
			WHERE rard.IsActive = 1
				  AND r.FunderId IS NOT NULL
		) AS t
		GROUP BY t.ContractId;

		DECLARE @RefundSql nvarchar(max) ='';

		SET @RefundSql =
		'SELECT DISTINCT
			ec.ContractId
			,pgl.GLJournalId
			,''Payable''
			,p.Id
			,p.Amount_Amount
			,pgl.IsReversal
 		FROM #LoanDetails ec
			INNER JOIN Receipts r ON r.Status IN (''Reversed'',''Completed'',''Posted'')
				AND ec.ContractId = r.ContractId
			INNER JOIN ReceiptAllocations ra ON r.Id = ra.ReceiptId
			INNER JOIN UnallocatedRefundDetails uard ON uard.ReceiptAllocationId = ra.Id
			INNER JOIN UnallocatedRefunds uar ON uar.Id = uard.UnallocatedRefundId
				AND uar.Status = ''Approved''
			INNER JOIN Payables p ON p.SourceId = r.Id
				AND p.SourceTable = ''Receipt''
				AND p.Status = ''Approved''
				AND p.IsGLPosted = 1
			INNER JOIN PayableGLJournals pgl ON pgl.PayableId = p.Id
		WHERE ra.EntityType = ''UnAllocated''
			AND ra.IsActive = 1
			RefundFilterCondition;'
		
		IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'UnallocatedRefunds' AND COLUMN_NAME = 'TYPE')
			BEGIN
				SET @RefundSql = REPLACE(@RefundSql, 'RefundFilterCondition', ' AND uar.TYPE = ''Refund''');
			END;
		ELSE
			BEGIN
				SET @RefundSql = REPLACE(@RefundSql, 'RefundFilterCondition', '');
			END;

		INSERT INTO #RefundGLJournalIds
		EXEC (@RefundSql);

		SET @RefundSql =
		'SELECT DISTINCT 
			ec.ContractId
			,pvgl.GLJournalId
		    ,''PaymentVoucher''
		    ,pvd.PaymentVoucherId
		    ,0.00		
			,pgl.IsReversal
		FROM #LoanDetails ec
			INNER JOIN Receipts r ON r.Status IN (''Reversed'',''Completed'',''Posted'')
				AND ec.ContractId = r.ContractId
			INNER JOIN ReceiptAllocations ra ON r.Id = ra.ReceiptId
			INNER JOIN UnallocatedRefundDetails uard ON uard.ReceiptAllocationId = ra.Id
			INNER JOIN UnallocatedRefunds uar ON uar.Id = uard.UnallocatedRefundId
				AND uar.Status = ''Approved''
			INNER JOIN Payables p ON p.SourceId = r.Id
				AND p.SourceTable = ''Receipt''
				AND p.Status = ''Approved''
				AND p.IsGLPosted = 1
			INNER JOIN TreasuryPayableDetails tpd ON tpd.PayableId = p.Id
				AND tpd.IsActive = 1
			INNER JOIN PaymentVoucherDetails pvd ON pvd.TreasuryPayableId = tpd.TreasuryPayableId
			INNER JOIN PaymentVoucherGLJournals pvgl ON pvgl.PaymentVoucherId = pvd.PaymentVoucherId
			LEFT JOIN PayableGLJournals pgl ON pgl.PayableId = p.Id
		WHERE uar.Status = ''Approved''
			AND pgl.GLJournalId IS NULL
			RefundFilterCondition;'
		
		IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'UnallocatedRefunds' AND COLUMN_NAME = 'TYPE')
			BEGIN
				SET @RefundSql = REPLACE(@RefundSql, 'RefundFilterCondition', ' AND uar.TYPE = ''Refund''');
			END;
		ELSE
			BEGIN
				SET @RefundSql = REPLACE(@RefundSql, 'RefundFilterCondition', '');
			END;

		INSERT INTO #RefundGLJournalIds
		EXEC (@RefundSql);
		
		CREATE NONCLUSTERED INDEX IX_GLJournalId ON #RefundGLJournalIds(GLJournalId);
		CREATE NONCLUSTERED INDEX IX_Id ON #RefundGLJournalIds(ContractId);
		
		SET @RefundSql =
		'SELECT DISTINCT 
			ec.ContractId
		   ,pvd.PaymentVoucherId
		   ,SUM(p.Amount_Amount) AS Amount
		FROM #LoanDetails ec
			INNER JOIN Receipts r ON r.Status IN (''Reversed'',''Completed'',''Posted'')
				AND ec.ContractId = r.ContractId
			INNER JOIN ReceiptAllocations ra ON r.Id = ra.ReceiptId
			INNER JOIN UnallocatedRefundDetails uard ON uard.ReceiptAllocationId = ra.Id
			INNER JOIN UnallocatedRefunds uar ON uar.Id = uard.UnallocatedRefundId
				AND uar.Status = ''Approved''
			INNER JOIN Payables p ON p.SourceId = r.Id
				AND p.SourceTable = ''Receipt''
				AND p.Status = ''Approved''
				AND p.IsGLPosted = 1
			INNER JOIN TreasuryPayableDetails tpd ON tpd.PayableId = p.Id
				AND tpd.IsActive = 1
			INNER JOIN PaymentVoucherDetails pvd ON pvd.TreasuryPayableId = tpd.TreasuryPayableId
			LEFT JOIN PayableGLJournals pgl ON pgl.PayableId = p.Id
		WHERE uar.Status = ''Approved''
			AND pgl.GLJournalId IS NULL
			RefundFilterCondition
		GROUP BY ec.ContractId
				,pvd.PaymentVoucherId;'
		
		IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'UnallocatedRefunds' AND COLUMN_NAME = 'TYPE')
			BEGIN
				SET @RefundSql = REPLACE(@RefundSql, 'RefundFilterCondition', ' AND uar.TYPE = ''Refund''');
			END;
		ELSE
			BEGIN
				SET @RefundSql = REPLACE(@RefundSql, 'RefundFilterCondition', '');
			END;
			 
		INSERT INTO #RefundTableValue
		EXEC (@RefundSql);

				SELECT 
			 t.Id
			,t.EntityType
			,SUM(t.Refunds_Debit - t.Refunds_Credit) [Refunds_GL]
		INTO #GLDetails
		FROM (
			SELECT 
				 dr.Id
				,dr.EntityType
				,CASE
					WHEN gld.IsDebit = 1
					THEN gld.Amount_Amount
					ELSE 0
				END Refunds_Debit
				,CASE
					WHEN gld.IsDebit = 0
					THEN gld.Amount_Amount
					ELSE 0
				END Refunds_Credit
			FROM GLJournalDetails gld 
				INNER JOIN (SELECT DISTINCT Id, GLJournalId, EntityType FROM #RefundGLJournalIds) dr ON dr.GLJournalId = gld.GLJournalId
																		  
				INNER JOIN GLTemplateDetails gltd ON gltd.Id = gld.GLTemplateDetailId
				INNER JOIN GLEntryItems glei ON glei.Id = gltd.EntryItemId
					AND glei.IsActive = 1
				INNER JOIN GLTransactionTypes gltt ON glei.GLTransactionTypeId = gltt.Id
					AND gltt.IsActive = 1
			WHERE (glei.Name = 'UnAppliedAR' AND gltt.Name = 'PayableCash') OR (glei.Name = 'CashPayable' AND gltt.Name = 'AccountsPayable')
			) AS t
		GROUP BY t.Id
				,t.EntityType ;
		
		CREATE NONCLUSTERED INDEX IX_Id ON #GLDetails(Id);

		SELECT refund.ContractId
			 , SUM(refund.Amount) AS [Refunds_GL]
		INTO #RefundDetails
		FROM #GLDetails gl
		INNER JOIN(SELECT Id, SUM(CASE WHEN IsReversal = 0 THEN Amount ELSE (-1)*Amount END) AS TableAmount FROM #RefundGLJournalIds WHERE EntityType = 'Payable' GROUP BY Id) AS t ON gl.Id = t.Id
		INNER JOIN #RefundGLJournalIds refund ON t.Id = refund.Id 
		WHERE gl.EntityType = 'Payable'
		AND refund.EntityType = 'Payable'
		AND gl.Refunds_GL = t.TableAmount
		GROUP BY refund.ContractId;
		
		MERGE #RefundDetails AS gl
		USING(SELECT refund.ContractId
				   , SUM(refund.Amount) AS [Refunds]
			  FROM #GLDetails gl
			  INNER JOIN (SELECT DISTINCT Id FROM #RefundGLJournalIds WHERE EntityType = 'PaymentVoucher') AS t ON gl.Id = t.Id
			  INNER JOIN PaymentVouchers pv ON pv.Id = t.Id
			  INNER JOIN #RefundTableValue refund ON t.Id = refund.PaymentVoucherId 
			  WHERE gl.EntityType = 'PaymentVoucher'
					AND gl.Refunds_GL = pv.Amount_Amount
			  GROUP BY refund.ContractId) AS [table]
		ON (gl.ContractId = [table].ContractId)
		WHEN MATCHED
			 THEN UPDATE SET [Refunds_GL] += [table].[Refunds]
		WHEN NOT MATCHED
		 THEN
		 INSERT (ContractId, [Refunds_GL])
		 VALUES ([table].ContractId, [table].[Refunds]);

		UPDATE gl SET UnAppliedCash_GL = UnAppliedCash_GL - refund.Refunds_GL
		FROM #LoanGLJournalValues gl 
		INNER JOIN #RefundDetails refund ON gl.ContractId = refund.ContractId

        UPDATE #LoanTableValues
          SET 
              PrincipalBalance_Amount = 0.00
            , PrincipalBalanceAdjustment_Amount = 0.00
            , IncomeAccrualBalance_Amount = 0.00
            , PrepaidReceivables_Amount = 0.00
            , LoanPrincipalOSAR_Amount = 0.00
            , LoanInterestOSAR_Amount = 0.00
            , PrepaidInterest_Amount = 0.00
			, SuspendedIncomeBalance_Amount = 0.00
        FROM #LoanTableValues
             INNER JOIN #LoanDetails ld ON #LoanTableValues.ContractId = ld.ContractId
        WHERE ld.IsChargedoff = 1;

		 UPDATE #LoanTableValues
          SET 
              PrincipalBalance_Amount = 0.00
		  FROM #LoanTableValues
             INNER JOIN #LoanDetails ld ON #LoanTableValues.ContractId = ld.ContractId
			 INNER JOIN #BasicDetails bd ON bd.ContractId = ld.ContractId 	
		  WHERE ld.SyndicationType = @FullSale AND (ld.CommencementDate = ld.SyndicationEffectiveDate OR ld.SyndicationEffectiveDate <= bd.MaxIncomeDate)


		UPDATE #ReceivableSumAmount SET 
										PostedPrincipalReceivableSum = rd.PrincipalBalanceAmount
									  , PostedInterestReceivableSum = rd.InterestBalanceAmount
		FROM #ReceivableSumAmount
			 INNER JOIN #LoanDetails ld ON #ReceivableSumAmount.ContractId = ld.ContractId
			 INNER JOIN #ReceiptDetails rd ON rd.ContractId = #ReceivableSumAmount.ContractId
		WHERE ld.IsChargedoff = 1;

        UPDATE #ReceivableSumAmount
          SET 
              PostedPrincipalReceivableSum = CASE
                                                 WHEN LoanPrincipalAR_GL = 0.00
                                                 THEN 0.00
                                                 ELSE PostedPrincipalReceivableSum
                                             END
            , PostedInterestReceivableSum = CASE
                                                WHEN LoanInterestAR_GL = 0.00
                                                THEN 0.00
                                                ELSE PostedInterestReceivableSum
                                            END
        FROM #ReceivableSumAmount
             INNER JOIN #LoanDetails ld ON #ReceivableSumAmount.ContractId = ld.ContractId
             INNER JOIN #LoanGLJournalValues gld ON gld.ContractId = ld.ContractId
        WHERE ld.IsChargedoff = 1;

		SELECT ld.ContractId
			 , SUM(CASE
					   WHEN receivable.ReceivableType = @LoanPrincipal AND receivable.IsGLPosted = 1
					   THEN receivable.Amount_Amount
					   ELSE 0.00
				   END) AS PrincipalAmount
			 , SUM(CASE
					   WHEN receivable.ReceivableType = @LoanInterest AND receivable.IsGLPosted = 1
					   THEN receivable.Amount_Amount
					   ELSE 0.00
				   END) AS InterestAmount
			 , SUM(CASE
					   WHEN receivable.ReceivableType = @LoanPrincipal AND receivable.IsGLPosted = 0 AND ld.IsNonAccrual = 0 AND receivable.Amount_Amount != receivable.Balance_Amount
					   THEN receivable.Amount_Amount - receivable.Balance_Amount
					   ELSE 0.00
				   END) AS PrepaidPrincipalAmount
			 , SUM(CASE
					   WHEN receivable.ReceivableType = @LoanPrincipal AND receivable.IsGLPosted = 0 AND ld.IsNonAccrual = 1 AND receivable.Amount_Amount != receivable.EffectiveBookBalance_Amount
					   THEN receivable.Amount_Amount - receivable.EffectiveBookBalance_Amount
					   ELSE 0.00
				   END) AS NonAccrualPrepaidPrincipalAmount
			 , SUM(CASE
					   WHEN receivable.ReceivableType = @LoanInterest AND receivable.IsGLPosted = 0 AND ld.IsNonAccrual = 0 AND receivable.Amount_Amount != receivable.Balance_Amount
					   THEN receivable.Amount_Amount - receivable.Balance_Amount
					   ELSE 0.00
				   END) AS PrepaidInterestAmount
			 , SUM(CASE
					   WHEN receivable.ReceivableType = @LoanInterest AND receivable.IsGLPosted = 0 AND ld.IsNonAccrual = 1 AND receivable.Amount_Amount != receivable.EffectiveBookBalance_Amount
					   THEN receivable.Amount_Amount - receivable.EffectiveBookBalance_Amount
					   ELSE 0.00
				   END) AS NonAccrualPrepaidInterestAmount
			 , SUM(CASE
					   WHEN receivable.IsGLPosted = 1 AND (s.Id IS NOT NULL OR sr.Id IS NOT NULL)
					   THEN receivable.Amount_Amount
					   ELSE 0.00
				   END) AS SundryAmount
			 , SUM(CASE
					   WHEN receivable.IsGLPosted = 0 AND ld.IsNonAccrual = 0 AND receivable.Amount_Amount != receivable.Balance_Amount AND (s.Id IS NOT NULL OR sr.Id IS NOT NULL)
					   THEN receivable.Amount_Amount - receivable.Balance_Amount
					   ELSE 0.00
				   END) AS PrepaidSundryAmount
			 , SUM(CASE
					   WHEN receivable.IsGLPosted = 0 AND ld.IsNonAccrual = 1 AND receivable.Amount_Amount != receivable.EffectiveBookBalance_Amount AND (s.Id IS NOT NULL OR sr.Id IS NOT NULL)
					   THEN receivable.Amount_Amount - receivable.EffectiveBookBalance_Amount
					   ELSE 0.00
				   END) AS NonAccrualPrepaidSundryAmount
			 , SUM(CASE
					   WHEN receivable.IsGLPosted = 1 AND ld.IsNonAccrual = 0 AND (s.Id IS NOT NULL OR sr.Id IS NOT NULL) 
					   THEN receivable.Balance_Amount
					   ELSE 0.00
				   END) AS SundryOSARAmount
			 , SUM(CASE
					   WHEN receivable.IsGLPosted = 1 AND ld.IsNonAccrual = 1 AND (s.Id IS NOT NULL OR sr.Id IS NOT NULL)
					   THEN receivable.EffectiveBookBalance_Amount
					   ELSE 0.00
				   END) AS NonAccrualSundryOSARAmount
			, SUM(CASE WHEN paydownSundry.Id IS NOT NULL AND receivable.IsGLPosted = 1 THEN receivable.Amount_Amount ELSE 0.00 END) AS PaydownSundryAmount
		INTO #SyndicationReceivableValues
		FROM #LoanDetails ld
			 INNER JOIN #ReceivableDetailsTemp receivable ON ld.ContractId = receivable.ContractId
			 LEFT JOIN Sundries s ON s.Id = receivable.SourceId AND receivable.SourceTable ='Sundry' AND s.SundryType ='PassThrough' AND s.Isowned = 0 AND s.IsActive = 1
			 LEFT JOIN SundryRecurringPaymentSchedules schedule ON schedule.Id = receivable.SourceId AND receivable.SourceTable ='SundryRecurring' AND schedule.IsActive = 1
			 LEFT JOIN SundryRecurrings sr ON sr.Id = schedule.SundryRecurringId AND sr.SundryType ='PassThrough' AND sr.Isowned = 0 AND sr.IsActive = 1
			 LEFT JOIN Sundries paydownSundry ON paydownSundry.ReceivableId = receivable.ReceivableId AND sr.Isowned = 0 AND receivable.SourceTable = 'LoanPaydown' 
												 AND paydownSundry.IsActive = 1
		WHERE receivable.FunderId IS NOT NULL
			  AND receivable.IsDummy = 0
			  AND receivable.IsCollected = 1
			  AND ld.SyndicationType != @None
		GROUP BY ld.ContractId;

		IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Payables' AND COLUMN_NAME = 'CreationSourceTable')
		BEGIN
		SET @Sql= 'SELECT p.Id AS PayableId
			 , receivable.ReceivableId
			 , receivable.ContractId
			 , P.Amount_Amount
			 , receivable.ReceivableType
			 , p.CreationSourceTable
		FROM #ReceivableDetailsTemp receivable
			 INNER JOIN Payables p ON p.SourceId = receivable.ReceivableId
		WHERE receivable.FunderId IS NOT NULL
			  AND receivable.IsDummy = 0
			  AND p.SourceTable = ''SyndicatedAR''
			  AND p.Status = ''Approved''
			  AND p.IsGLPosted = 1
			  AND p.EntityType =''CT'';'

		INSERT INTO #PayableDetails (PayableId, ReceivableId, ContractId, Amount_Amount, ReceivableType, CreationSourceTable)
		EXEC (@Sql)

		END

		IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Payables' AND COLUMN_NAME = 'CreationSourceTable')
		BEGIN
		SET @Sql= 'SELECT p.Id AS PayableId
			 , receivable.ReceivableId
			 , receivable.ContractId
			 , P.Amount_Amount
			 , receivable.ReceivableType
			 , NULL AS CreationSourceTable
		FROM #ReceivableDetailsTemp receivable
			 INNER JOIN Payables p ON p.SourceId = receivable.ReceivableId
		WHERE receivable.FunderId IS NOT NULL
			  AND receivable.IsDummy = 0
			  AND p.SourceTable = ''SyndicatedAR''
			  AND p.Status = ''Approved''
			  AND p.IsGLPosted = 1
			  AND p.EntityType =''CT'';'
		INSERT INTO #PayableDetails (PayableId, ReceivableId, ContractId, Amount_Amount, ReceivableType, CreationSourceTable)
		EXEC (@Sql)
		END

		SELECT DISTINCT 
			   dr.Id AS DrId
			 , p.ContractId
		INTO #DRDetails
		FROM #PayableDetails p
			 INNER JOIN DisbursementRequestPayables drp ON p.PayableId = drp.PayableId
			 INNER JOIN DisbursementRequests dr ON drp.DisbursementRequestId = dr.Id;

	   CREATE NONCLUSTERED INDEX IX_Id ON #DRDetails(DrId)

		SELECT ContractId
			 , SUM(CASE
					   WHEN ReceivableType = @LoanPrincipal
					   THEN Amount_Amount
					   ELSE 0.00
				   END) AS PrincipalAmount
			 , SUM(CASE
					   WHEN ReceivableType = @LoanInterest
					   THEN Amount_Amount
					   ELSE 0.00
				   END) AS InterestAmount
			, 0.00 AS SalesTaxAmount
			, 0.0 as SundryAmount
		INTO #SyndicationPayableValues
		FROM #PayableDetails
		GROUP BY ContractId;

		UPDATE syndication
		SET SalesTaxAmount = t.Amount
		FROM 
		#SyndicationPayableValues syndication
		INNER JOIN
		(SELECT ld.ContractId,
			   SUM(p.Amount_Amount) AS Amount
		FROM #SyndicationFunderRemitting ld
		INNER JOIN #PayableDetails p ON p.ContractId = ld.ContractId 
		WHERE p.CreationSourceTable = 'RARTD'
		GROUP BY ld.ContractId) as t ON t.ContractId = syndication.ContractId;

		UPDATE syndication
		SET SundryAmount = t.Amount
		FROM #SyndicationPayableValues syndication
		INNER JOIN
		(SELECT pd.ContractId, SUM(s.Amount_Amount) AS Amount
		 FROM #ReceivableDetailsTemp pd
		 INNER JOIN Sundries s ON s.ReceivableId = pd.ReceivableId
		 WHERE s.IsActive = 1
			   AND s.EntityType = 'CT'
			   AND s.Status = 'Approved'
			   AND pd.FunderId IS NOT NULL
			   AND pd.SourceTable ='Sundry'
			   AND pd.IsCollected = 1
			   AND s.IsOwned = 0
		 GROUP BY pd.ContractId) as t ON t.ContractId = syndication.ContractId 

	SELECT t.ContractId 
			 , SUM(t.DRCreditAmount - t.DRDebitAmount) AS DRAmount
		INTO #PayableGLAmount
		FROM
		(
			SELECT ld.ContractId
				 , CASE
					   WHEN gl.IsDebit = 1 AND gtt.Name IN('DueToInvestorAP') 
							AND DR.DrId IS NOT NULL
					   THEN gl.Amount_Amount
					   ELSE 0
				   END AS DRDebitAmount
				 , CASE
					   WHEN gl.IsDebit = 0 and gtt.Name IN('DueToInvestorAP')
							AND DR.DrId IS NOT NULL
					   THEN gl.Amount_Amount
					   ELSE 0
				   END DRCreditAmount
			FROM GLJournalDetails gl 
				 INNER JOIN GLTemplateDetails gtd ON gl.GLTemplateDetailId = gtd.Id
				 INNER JOIN GLEntryItems gle ON gtd.EntryItemId = gle.Id
				 INNER JOIN GLTransactionTypes gtt ON gle.GLTransactionTypeId = gtt.Id
				 INNER JOIN #DRDetails dr ON dr.DrId = gl.EntityId and GL.EntityType = @DisbursementRequest
				 INNER JOIN #LoanDetails ld ON ld.ContractId = dr.ContractId
			WHERE gle.Name IN('RentDueToInvestorAP')
		) t 
		GROUP BY t.ContractId;

		SELECT DISTINCT 
			  ld.ContractId
			 , dr.Id AS DisbursementRequestId
			 , p.Id AS PayableId
			 , pioc.Amount_Amount
			 , CAST (0 AS BIT) IsSyndicated
		INTO #ProgressPaymentCredit
		FROM #LoanDetails ld
		INNER JOIN LoanFinances lf ON lf.ContractId = ld.ContractId AND lf.IsCurrent = 1
		INNER JOIN LoanFundings funding ON funding.LoanFinanceId = lf.Id AND funding.IsActive = 1 AND funding.IsApproved = 1 
		INNER JOIN PayableInvoiceOtherCosts pioc ON pioc.PayableInvoiceId = funding.FundingId AND pioc.IsActive = 1 AND pioc.AllocationMethod = 'ProgressPaymentCredit'
		INNER JOIN PayableInvoiceOtherCosts pl ON pl.Id = pioc.ProgressFundingId AND pl.IsActive = 1
		INNER JOIN DisbursementRequestInvoices invoice ON invoice.InvoiceId = pioc.PayableInvoiceId AND invoice.IsActive = 1
		INNER JOIN DisbursementRequests dr ON dr.Id = invoice.DisbursementRequestId AND dr.Status = 'Completed'
		INNER JOIN DisbursementRequestPayables drp ON drp.DisbursementRequestId = dr.Id
		INNER JOIN Payables p ON p.Id = drp.PayableId AND p.SourceTable = 'PayableInvoiceOtherCost' AND p.SourceId = pioc.Id
		WHERE pioc.ProgressFundingId IS NOT NULL AND ld.SyndicationType = @None
			  AND ld.IsMigratedContract = 0


		INSERT INTO #ProgressPaymentCredit
		SELECT DISTINCT ld.ContractId
			  , 0
			  , 0
			  , pioc.Amount_Amount
			  , CAST(1 AS BIT) 
		 FROM #LoanDetails ld
		INNER JOIN LoanFinances lf ON lf.ContractId = ld.ContractId AND lf.IsCurrent = 1
		INNER JOIN LoanFundings funding ON funding.LoanFinanceId = lf.Id AND funding.IsActive = 1 AND funding.IsApproved = 1 
		INNER JOIN PayableInvoiceOtherCosts pioc ON pioc.PayableInvoiceId = funding.FundingId AND pioc.IsActive = 1 AND pioc.AllocationMethod = 'ProgressPaymentCredit'
		INNER JOIN PayableInvoiceOtherCosts pl ON pl.Id = pioc.ProgressFundingId AND pl.IsActive = 1
		WHERE pioc.ProgressFundingId IS NOT NULL AND (ld.SyndicationType != @None OR ld.IsMigratedContract = 1)

		CREATE NONCLUSTERED INDEX IX_Id ON #ProgressPaymentCredit(ContractId)

		SELECT ContractId
			 , SUM(ABS(Amount_Amount)) AS Amount
		INTO #ProgressPaymentCreditAmount
		FROM #ProgressPaymentCredit
		GROUP BY ContractId;


		CREATE NONCLUSTERED INDEX IX_Id ON #ProgressPaymentCreditAmount(ContractId)

	SELECT t.ContractId 
			 , SUM(t.DRCreditAmount - t.DRDebitAmount) AS DRAmount
		INTO #ProgressPaymentCreditGLAmount
		FROM
		(
			SELECT ppc.ContractId
				 , CASE
					   WHEN gl.IsDebit = 1  
					   THEN gl.Amount_Amount
					   ELSE 0
				   END AS DRDebitAmount
				 , CASE
					   WHEN gl.IsDebit = 0  
					   THEN gl.Amount_Amount
					   ELSE 0
				   END DRCreditAmount
			FROM GLJournalDetails gl 
				 INNER JOIN GLTemplateDetails gtd ON gl.GLTemplateDetailId = gtd.Id
				 INNER JOIN GLEntryItems gle ON gtd.EntryItemId = gle.Id
				 INNER JOIN GLTransactionTypes gtt ON gle.GLTransactionTypeId = gtt.Id
				 INNER JOIN #ProgressPaymentCredit ppc ON ppc.DisbursementRequestId = gl.EntityId and GL.EntityType = @DisbursementRequest
														  AND ppc.PayableId = gl.SourceId
			WHERE gle.Name IN('Disbursement') AND gtt.Name ='Disbursement'
		) t 
		GROUP BY t.ContractId;

		CREATE NONCLUSTERED INDEX IX_Id ON #ProgressPaymentCreditGLAmount(ContractId)

		MERGE #ProgressPaymentCreditGLAmount AS Target
		USING (SELECT * FROM #ProgressPaymentCreditAmount) AS Source
		ON Source.ContractId = Target.ContractId
		WHEN NOT MATCHED 
				 THEN 
				 INSERT (ContractId, DRAmount)
				 VALUES(ContractId,Amount);


				 UPDATE gld SET 
							   LoanPrincipalAR_GL = LoanPrincipalAR_GL - (LoanPrincipalCashPosted + LoanPrincipalNonCashPosted)
							 , LoanInterestAR_GL = LoanInterestAR_GL - (LoanInterestCashPosted + LoanInterestNonCashPosted)
							 , PrincipalCashPosting_GL -= LoanPrincipalCashPosted
							 , InterestCashPosting_GL -= LoanInterestCashPosted
							 , PrincipalNonCashPosting_GL -= LoanPrincipalNonCashPosted
							 , InterestNonCashPosting_GL -= LoanInterestNonCashPosted
		FROM #LoanGLJournalValues gld
			 INNER JOIN
		(
			SELECT r.ContractId
				 , SUM(CASE
						   WHEN ReceiptClassification IN('Cash', 'NonAccrualNonDSL', 'DSL') AND ReceiptTypeName NOT IN('PayableOffset', 'SecurityDeposit', 'EscrowRefund')
							    AND ((IsAdvance = 0 AND StartDate < ChargeOffDate) OR (IsAdvance = 1 AND StartDate <= ChargeOffDate))
								AND r.ReceivableType = @LoanPrincipal
						   THEN ISNULL(r.ChargeoffExpenseAmount_LC, 0.00)
						   ELSE 0.00
					   END) AS LoanPrincipalCashPosted
				, SUM(CASE
						   WHEN ReceiptClassification IN('Cash', 'NonAccrualNonDSL', 'DSL') AND ReceiptTypeName NOT IN('PayableOffset', 'SecurityDeposit', 'EscrowRefund')
							    AND ((IsAdvance = 0 AND StartDate < ChargeOffDate) OR (IsAdvance = 1 AND StartDate <= ChargeOffDate))
								AND r.ReceivableType = @LoanInterest
						   THEN ISNULL(r.ChargeoffExpenseAmount_LC, 0.00)
						   ELSE 0.00
					   END) AS LoanInterestCashPosted
				 , SUM(CASE
						   WHEN (ReceiptClassification NOT IN('Cash', 'NonAccrualNonDSL', 'DSL') OR ReceiptTypeName IN('PayableOffset', 'SecurityDeposit', 'EscrowRefund'))
							    AND ((IsAdvance = 0 AND @LoanPrincipal < ChargeOffDate) OR (IsAdvance = 1 AND StartDate <= ChargeOffDate))
								AND r.ReceivableType = @LoanInterest
						   THEN ISNULL(r.ChargeoffExpenseAmount_LC, 0.00)
						   ELSE 0.00
					   END) AS LoanPrincipalNonCashPosted
				, SUM(CASE
						   WHEN (ReceiptClassification NOT IN('Cash', 'NonAccrualNonDSL', 'DSL') OR ReceiptTypeName IN('PayableOffset', 'SecurityDeposit', 'EscrowRefund'))
							    AND ((IsAdvance = 0 AND StartDate < ChargeOffDate) OR (IsAdvance = 1 AND StartDate <= ChargeOffDate))
								AND r.ReceivableType = @LoanInterest
						   THEN ISNULL(r.ChargeoffExpenseAmount_LC, 0.00)
						   ELSE 0.00
					   END) AS LoanInterestNonCashPosted
			FROM #ReceiptApplicationReceivableDetails r
			WHERE ReceiptStatus IN(@ReversedStatus)
				 AND r.IsRecovery IS NOT NULL
				 AND r.IsRecovery = 0
				 AND r.IsGLPosted = 1
			GROUP BY r.ContractId
		) AS t ON t.ContractId = gld.ContractId;

        /**************************************************************************************************************************/
        /*FinalOutput*/

	SELECT *, 
		   CASE 
			   WHEN TotalFinancedAmount_Difference != 0.00
                    OR PrincipalBalance_Difference != 0.00
                    OR IncomeAccrualBalance_Difference != 0.00
                    OR SuspendedIncomeBalance_Difference != 0.00
                    OR CapitalizedInterest_Difference != 0.00
                    OR PrincipalReceivableGLPosted_Difference != 0.00
					OR [PrincipalReceivable_OSAR_Difference] != 0.00
					OR [PrincipalReceivable_Prepaid_Difference] != 0.00
					OR [InterestReceivable_OSAR_Difference] != 0.00
					OR [InterestReceivable_Prepaid_Difference] != 0.00
                    OR InterestReceivableGLPosted_Difference != 0.00
                    OR TotalGainOrLossAmount_Difference != 0.00
                    OR [Principal_TotalCashApplication_Difference] != 0.00
                    OR [Principal_TotalNonCashApplication_Difference] != 0.00
                    OR [Interest_TotalCashApplication_Difference] != 0.00
                    OR [Interest_TotalNonCashApplication_Difference] != 0.00
                    OR UnappliedCash_Difference != 0.00
                    OR GrossWritedowns_Difference != 0.00
                    OR NetWritedowns_Difference != 0.00
                    OR ChargeoffExpense_Difference != 0.00
                    OR RecoveryAmount_Difference != 0.00
					OR [FunderOwnedTotalReceivablesAndTaxes_Prepaid_Difference] != 0.00
					OR [FunderOwnedTotalReceivablesAndTaxes_OSAR_Difference] != 0.00
					OR [FunderOwnedTotalReceivablesAndTaxes_GLPosted_Difference] != 0.00
					OR [LessorOwnedSalesTax_PrePaid_Difference] != 0.00
					OR [LessorOwnedSalesTax_OSAR_Difference] != 0.00
					OR [LessorOwnedSalesTax_GLPosted_Difference] != 0.00
					OR [FunderOwnedLessorRemitting_SalesTax_Prepaid_Difference] != 0.00
					OR [FunderOwnedLessorRemitting_SalesTax_OSAR_Difference] != 0.00
					OR [FunderOwnedLessorRemitting_SalesTax_TotalNonCashApplication_Difference] != 0.00
					OR [SyndicationProceeds_Difference] != 0.00
					OR [TotalPayable_GLPosted_Difference] != 0.00
					OR [SyndicationSoldNBV_Difference] != 0.00
					OR [FunderOwnedLessorRemitting_SalesTax_GLPosted_Difference] != 0.00
					OR [FunderOwnedReceivablesAndTaxes_TotalCashApplication_Difference] != 0.00
					OR [FunderOwnedReceivablesAndTaxes_TotalNonCashApplication_Difference] != 0.00
					OR [FunderOwnedLessorRemitting_SalesTax_TotalCashApplication_Difference] != 0.00
					OR [LessorOwnedSalesTax_TotalCashApplication_Difference] != 0.00
					OR [LessorOwnedSalesTax_TotalNonCashApplication_Difference] != 0.00
					OR [ProgressPaymentCredit_Difference] != 0.00
			   THEN 'Problem Record'
			   ELSE 'Not Problem Record'
			END AS Result
	INTO #ResultList
	FROM(
            SELECT c.Id AS ContractId
                 , c.SequenceNumber
				 , c.Alias AS ContractAlias
                 , le.Name AS LegalEntityName
                 , p.PartyName AS CustomerName
                 , ld.LoanFinanceId AS LoanFinanceId
                 , ld.ContractType
                 , ld.CommencementDate
                 , ld.MaturityDate
                 , ld.Status AS LoanStatus
                 , IIF(ld.IsProgressLoan = 1, 'Yes', 'No') AS IsProgressLoan 
                 , IIF(ld.IsDSL = 1, 'Yes', 'No') AS IsDSL  
                 , IIF(ld.IsMigratedContract = 1, 'Yes', 'No') AS IsMigratedContract
                 , IIF(ld.IsInInterim = 1, 'Yes', 'No') AS LoanWithInterim   
                 , pdc.PaydownDate AS FullPaydownEffectiveDate
                 , IIF(ld.SyndicationType = @None, 'NA', ld.SyndicationType) AS SyndicationType
                 , ld.ParticipatedPercentage
                 , ld.SyndicationEffectiveDate
				 , IIF(ld.IsFromContract = 1, 'Yes', 'No') AS [IsSyndicatedFromInception]
                 , IIF(ld.IsNonAccrual = @False, 'Accrual', 'Non-Accrual') AS AccrualStatus
				 , IIF(ad.NonAccrualContractId IS NOT NULL, 'Yes', 'No') AS WasNonAccrualAnytime
                 , ad.NonAccrualDate NonAccrualDate
				 , IIF(ad.ReAccrualContractId IS NOT NULL, 'Yes', 'No') AS IsReAccrualDone
                 , ad.ReAccrualDate ReAccrualDate
                 , IIF(ld.IsChargedOff = 1, 'Yes', 'No') AS IsChargedOff
                 , bd.ChargeOffDate
                 , ISNULL(tv.TotalFinancedAmount_Amount, 0.00) TotalFinancedAmount_Table
                 , ISNULL(gld.TotalFinancedAmount_GL, 0.00) TotalFinancedAmount_GL
                 , ISNULL(tv.TotalFinancedAmount_Amount, 0.00) - ISNULL(gld.TotalFinancedAmount_GL, 0.00) TotalFinancedAmount_Difference
				 , ISNULL(ppca.Amount, 0.00) AS [ProgressPaymentCredit_Table]
				 , ISNULL(ppcaGL.DRAmount, 0.00) as [ProgressPaymentCredit_GL]
				 , ISNULL(ppca.Amount, 0.00) - ISNULL(ppcaGL.DRAmount, 0.00) AS [ProgressPaymentCredit_Difference]
                 , ISNULL(tv.PrincipalBalance_Amount, 0.00) + ISNULL(tv.PrincipalBalanceAdjustment_Amount, 0.00) PrincipalBalance_Table
                 , ISNULL(gld.PrincipalBalance_GL, 0.00) PrincipalBalance_GL
                 , ISNULL(tv.PrincipalBalance_Amount, 0.00) + ISNULL(tv.PrincipalBalanceAdjustment_Amount, 0.00) - ISNULL(gld.PrincipalBalance_GL, 0.00) PrincipalBalance_Difference
                 , ISNULL(tv.IncomeAccrualBalance_Amount, 0.00) IncomeAccrualBalance_Table
                 , ISNULL(gld.IncomeAccrualBalance_GL, 0.00) IncomeAccrualBalance_GL
                 , ISNULL(tv.IncomeAccrualBalance_Amount, 0.00) - ISNULL(gld.IncomeAccrualBalance_GL, 0.00) IncomeAccrualBalance_Difference
                 , ISNULL(tv.SuspendedIncomeBalance_Amount, 0.00) SuspendedIncomeBalance_Table
                 , ISNULL(gld.SuspendedIncome_GL, 0.00) SuspendedIncomeBalance_GL
                 , ISNULL(tv.SuspendedIncomeBalance_Amount, 0.00) - ISNULL(gld.SuspendedIncome_GL, 0.00) SuspendedIncomeBalance_Difference
                 , ISNULL(ci.CapitalizedInterest_Amount, 0.00) CapitalizedInterest_Table
                 , ISNULL(gld.CapitalizedInterest_GL, 0.00) CapitalizedInterest_GL
                 , ISNULL(ci.CapitalizedInterest_Amount, 0.00) - ISNULL(gld.CapitalizedInterest_GL, 0.00) CapitalizedInterest_Difference
                 , ISNULL(ReceivableSum.PostedPrincipalReceivableSum, 0.00) PrincipalReceivableGLPosted_Table
                 , ISNULL(gld.LoanPrincipalAR_GL, 0.00) AS PrincipalReceivableGLPosted_GL
                 , ISNULL(ReceivableSum.PostedPrincipalReceivableSum, 0.00) - ISNULL(gld.LoanPrincipalAR_GL, 0.00) PrincipalReceivableGLPosted_Difference
                 , ISNULL(tv.PrepaidReceivables_Amount, 0.00) [PrincipalReceivable_Prepaid_Table]
                 , ISNULL(gld.PrepaidPrincipalReceivable_GL, 0.00) [PrincipalReceivable_Prepaid_GL]
                 , ISNULL(tv.PrepaidReceivables_Amount, 0.00) - ISNULL(gld.PrepaidPrincipalReceivable_GL, 0.00) [PrincipalReceivable_Prepaid_Difference]
                 , ISNULL(tv.LoanPrincipalOSAR_Amount, 0.00) [PrincipalReceivable_OSAR_Table]
                 , ISNULL(gld.LoanPrincipalOSAR_GL, 0.00) [PrincipalReceivable_OSAR_GL]
                 , ISNULL(tv.LoanPrincipalOSAR_Amount, 0.00) - ISNULL(gld.LoanPrincipalOSAR_GL, 0.00) [PrincipalReceivable_OSAR_Difference]
                 , ISNULL(ReceivableSum.PostedInterestReceivableSum, 0.00) InterestReceivableGLPosted_Table
                 , ISNULL(gld.LoanInterestAR_GL, 0.00) AS InterestReceivableGLPosted_GL
                 , ISNULL(ReceivableSum.PostedInterestReceivableSum, 0.00) - ISNULL(gld.LoanInterestAR_GL, 0.00) InterestReceivableGLPosted_Difference
				 , ISNULL(tv.PrepaidInterest_Amount, 0.00) [InterestReceivable_Prepaid_Table]
                 , ISNULL(gld.PrepaidInterestReceivable_GL, 0.00) [InterestReceivable_Prepaid_GL]
                 , ISNULL(tv.PrepaidInterest_Amount, 0.00) - ISNULL(gld.PrepaidInterestReceivable_GL, 0.00) [InterestReceivable_Prepaid_Difference]
                 , ISNULL(tv.LoanInterestOSAR_Amount, 0.00) [InterestReceivable_OSAR_Table]
                 , ISNULL(gld.LoanInterestOSAR_GL, 0.00) [InterestReceivable_OSAR_GL]
                 , ISNULL(tv.LoanInterestOSAR_Amount, 0.00) - ISNULL(gld.LoanInterestOSAR_GL, 0.00) [InterestReceivable_OSAR_Difference]
                 , ISNULL(rd.PrincipalCashPosted, 0.00) [Principal_TotalCashApplication_Table]
                 , ISNULL(gld.PrincipalCashPosting_GL, 0.00) AS [Principal_TotalCashApplication_GL]
                 , ABS(ISNULL(rd.PrincipalCashPosted, 0.00)) - ABS(ISNULL(gld.PrincipalCashPosting_GL, 0.00)) AS [Principal_TotalCashApplication_Difference]
				 , ISNULL(rd.PrincipalNonCashPosted, 0.00) [Principal_TotalNonCashApplication_Table]
                 , ISNULL(gld.PrincipalNonCashPosting_GL, 0.00) AS [Principal_TotalNonCashApplication_GL]
                 , ABS(ISNULL(rd.PrincipalNonCashPosted, 0.00)) - ABS(ISNULL(gld.PrincipalNonCashPosting_GL, 0.00)) AS [Principal_TotalNonCashApplication_Difference]
                 , ISNULL(rd.InterestCashPosted, 0.00) [Interest_TotalCashApplication_Table]
                 , ISNULL(gld.InterestCashPosting_GL, 0.00) AS [Interest_TotalCashApplication_GL]
                 , ABS(ISNULL(rd.InterestCashPosted, 0.00)) - ABS(ISNULL(gld.InterestCashPosting_GL, 0.00)) AS [Interest_TotalCashApplication_Difference]
                 , ISNULL(rd.InterestNonCashPosted, 0.00) [Interest_TotalNonCashApplication_Table]
                 , ISNULL(gld.InterestNonCashPosting_GL, 0.00) AS [Interest_TotalNonCashApplication_GL]
                 , ABS(ISNULL(rd.InterestNonCashPosted, 0.00)) - ABS(ISNULL(gld.InterestNonCashPosting_GL, 0.00)) AS [Interest_TotalNonCashApplication_Difference]
				 , ABS(ISNULL(ia.InterestAppliedAmount, 0.00)) AS InterestAmountAppliedTowardsPrincipalRepayment
                 , ISNULL(TotalGainAmount, 0.00) TotalGainOrLossAmount_Table
                 , ISNULL(GainLossAdjustment_GL, 0.00) AS TotalGainOrLossAmount_GL
                 , ISNULL(TotalGainAmount, 0.00) - ISNULL(GainLossAdjustment_GL, 0.00) AS TotalGainOrLossAmount_Difference
                 , ISNULL(tv.UnappliedCash_Amount, 0.00) UnappliedCash_Table
                 , ISNULL(gld.UnAppliedCash_GL, 0.00) UnappliedCash_GL
                 , ISNULL(tv.UnappliedCash_Amount, 0.00) - ISNULL(gld.UnAppliedCash_GL, 0.00) UnappliedCash_Difference
                 , ISNULL(wd.GrossWriteDown, 0.00) GrossWritedowns_Table
                 , ISNULL(gld.GrossWriteDown_GL, 0.00) GrossWritedowns_GL
                 , ABS(ISNULL(wd.GrossWriteDown, 0.00)) - ABS(ISNULL(gld.GrossWriteDown_GL, 0.00)) GrossWritedowns_Difference
                 , ISNULL(wd.NetWriteDown, 0.00) NetWritedowns_Table
                 , ISNULL(gld.NetWriteDown_GL, 0.00) NetWritedowns_GL
                 , ABS(ISNULL(wd.NetWriteDown, 0.00)) - ABS(ISNULL(gld.NetWriteDown_GL, 0.00)) NetWritedowns_Difference
                 , ISNULL(cod.ChargeOffExpense, 0.00) ChargeoffExpense_Table
                 , ISNULL(gld.ChargeOffExpense_GL, 0.00) ChargeoffExpense_GL
                 , ABS(ISNULL(cod.ChargeOffExpense, 0.00)) - ABS(ISNULL(gld.ChargeOffExpense_GL, 0.00)) ChargeoffExpense_Difference
                 , ISNULL(cod.ChargeOffRecovery, 0.00) RecoveryAmount_Table
                 , ISNULL(gld.Recovery_GL, 0.00) RecoveryAmount_GL
                 , ABS(ISNULL(cod.ChargeOffRecovery, 0.00)) - ABS(ISNULL(gld.Recovery_GL, 0.00)) RecoveryAmount_Difference
                 --, ISNULL(ReceivableSum.PostedPrincipalReceivableSum, 0.00) [LessorOwnedSalesTax-GLPosted]
				 , ISNULL(rtd.LessorPortion, 0.00) - ISNULL(ncst.LessorPortionNonCash, 0.00) AS [LessorOwnedSalesTax_GLPosted_Table]
				 , ISNULL(gld.SalesTaxReceivableAR_GL, 0.00) AS [LessorOwnedSalesTax_GLPosted_GL]
				 , ISNULL(rtd.LessorPortion, 0.00) - ISNULL(ncst.LessorPortionNonCash, 0.00) - ISNULL(gld.SalesTaxReceivableAR_GL, 0.00) AS [LessorOwnedSalesTax_GLPosted_Difference]
				 , ISNULL(rtd.LessorRemittingPrepaidAccrual, 0.00) + ISNULL(rtd.LessorRemittingPrepaidNonAccrual, 0.00) AS [LessorOwnedSalesTax_PrePaid_Table]
				 , ISNULL(gld.SalesTaxReceivablePrepaid_GL, 0.00) AS [LessorOwnedSalesTax_PrePaid_GL]
				 , ISNULL(rtd.LessorRemittingPrepaidAccrual, 0.00) + ISNULL(rtd.LessorRemittingPrepaidNonAccrual, 0.00) - ISNULL(gld.SalesTaxReceivablePrepaid_GL, 0.00) AS [LessorOwnedSalesTax_PrePaid_Difference]
				 , ISNULL(rtd.LessorRemittingAccrualOSAR, 0.00) + ISNULL(rtd.LessorRemittingNonAccrualOSAR, 0.00) AS [LessorOwnedSalesTax_OSAR_Table]
				 , ISNULL(gld.SalesTaxReceivableOSAR_GL, 0.00) AS [LessorOwnedSalesTax_OSAR_GL]
				 , ISNULL(rtd.LessorRemittingAccrualOSAR, 0.00) + ISNULL(rtd.LessorRemittingNonAccrualOSAR, 0.00) - ISNULL(gld.SalesTaxReceivableOSAR_GL, 0.00) AS [LessorOwnedSalesTax_OSAR_Difference]
				 , ISNULL(rd.TaxCashPosted, 0.00) AS [LessorOwnedSalesTax_TotalCashApplication_Table]
				 , ISNULL(gld.LessorPortionCashPosting_GL, 0.00) AS [LessorOwnedSalesTax_TotalCashApplication_GL]
				 , ISNULL(rd.TaxCashPosted, 0.00) - ISNULL(gld.LessorPortionCashPosting_GL, 0.00) [LessorOwnedSalesTax_TotalCashApplication_Difference]
				 , ISNULL(rd.TaxNonCashPosted, 0.00) - ISNULL(ncst.LessorPortionNonCash, 0.00) AS [LessorOwnedSalesTax_TotalNonCashApplication_Table]
				 , ISNULL(gld.LessorPortionNonCashPosting_GL, 0.00) [LessorOwnedSalesTax_TotalNonCashApplication_GL]
				 , ISNULL(rd.TaxNonCashPosted, 0.00) - ISNULL(ncst.LessorPortionNonCash, 0.00) -  ISNULL(gld.LessorPortionNonCashPosting_GL, 0.00) AS [LessorOwnedSalesTax_TotalNonCashApplication_Difference]
				 , ISNULL(spa.Amount, 0.00) AS [SyndicationProceeds_Table]
				 , ISNULL(gld.SyndicationProceeds_GL, 0.00) AS [SyndicationProceeds_GL]
				 , ISNULL(spa.Amount, 0.00) - ISNULL(gld.SyndicationProceeds_GL, 0.00) AS [SyndicationProceeds_Difference]
				 , CASE WHEN ld.IsFromContract = 1 
						THEN 0.00
					    ELSE ISNULL(ld.SoldNBVAmount, 0.00) 
				   END AS [SyndicationSoldNBV_Table]
				 , ISNULL(gld.SyndicationGainLossAdjustment_GL, 0.00) AS [SyndicationSoldNBV_GL]
				 , CASE WHEN ld.IsFromContract = 1 
						THEN 0.00 - ISNULL(gld.SyndicationGainLossAdjustment_GL, 0.00) 
					    ELSE ISNULL(ld.SoldNBVAmount, 0.00) - ISNULL(gld.SyndicationGainLossAdjustment_GL, 0.00) 
				   END AS [SyndicationSoldNBV_Difference]
				 , ISNULL(syndication.PrincipalAmount, 0.00) AS [FunderOwnedPrinicipalReceivable_GLPosted_Table]
				 , ISNULL(syndication.InterestAmount, 0.00) AS [FunderOwnedInterestReceivable_GLPosted_Table]
				 , ISNULL(rtd.FunderRemitting, 0.00) - ISNULL(ncst.FunderRemittingNonCash, 0.00) AS [FunderOwnedAndFunderRemittingSalesTaxReceivable_GLPosted_Table] 
				 , ISNULL(syndication.SundryAmount, 0.00) + ISNULL(syndication.PaydownSundryAmount, 0.00) AS [FunderOwnedSundryReceivable_GLPosted_Table]
				 , ISNULL(gld.DueToThirdPartyAR_GL, 0.00) AS [FunderOwnedTotalReceivablesAndTaxes_GLPosted_GL]
				 , ISNULL(syndication.PrincipalAmount, 0.00) + ISNULL(syndication.InterestAmount, 0.00) + ISNULL(rtd.FunderRemitting, 0.00) +  ISNULL(syndication.PaydownSundryAmount, 0.00) + ISNULL(syndication.SundryAmount, 0.00) - ISNULL(gld.DueToThirdPartyAR_GL, 0.00) - ISNULL(ncst.FunderRemittingNonCash, 0.00) as [FunderOwnedTotalReceivablesAndTaxes_GLPosted_Difference]
				 , ISNULL(syndication.PrepaidPrincipalAmount, 0.00) + ISNULL(syndication.NonAccrualPrepaidPrincipalAmount, 0.00) AS [FunderOwnedPrinicipalReceivable_Prepaid_Table]
				 , ISNULL(syndication.PrepaidInterestAmount, 0.00) + ISNULL(syndication.NonAccrualPrepaidInterestAmount, 0.00) AS [FunderOwnedInterestReceivable_Prepaid_Table]
				 , ISNULL(rtd.FunderRemittingPrepaidAccrual, 0.00) + ISNULL(rtd.FunderRemittingPrepaidNonAccrual, 0.00) AS [FunderOwnedAndFunderRemittingSalesTaxReceivable_Prepaid_Table]
				 , ISNULL(syndication.PrepaidSundryAmount, 0.00) +  ISNULL(syndication.NonAccrualPrepaidSundryAmount, 0.00) AS [FunderOwnedSundryReceivable_Prepaid_Table]
				 , ABS(ISNULL(gld.PrePaidDueToThirdPartyAR_GL, 0.00)) AS [FunderOwnedTotalReceivablesAndTaxes_Prepaid_GL]
				 , ISNULL(syndication.PrepaidPrincipalAmount, 0.00) + ISNULL(syndication.NonAccrualPrepaidPrincipalAmount, 0.00) + ISNULL(syndication.PrepaidInterestAmount, 0.00) + ISNULL(syndication.NonAccrualPrepaidInterestAmount, 0.00) + ISNULL(syndication.PrepaidSundryAmount, 0.00) + ISNULL(syndication.NonAccrualPrepaidSundryAmount, 0.00) + ISNULL(rtd.FunderRemittingPrepaidAccrual, 0.00) + ISNULL(rtd.FunderRemittingPrepaidNonAccrual, 0.00) - ABS(ISNULL(gld.PrePaidDueToThirdPartyAR_GL, 0.00)) AS [FunderOwnedTotalReceivablesAndTaxes_Prepaid_Difference]
				 , ISNULL(tv.SyndicatedLoanPrincipalOSAR_Amount, 0.00) [FunderOwnedPrinicipalReceivable_OSAR_Table]
				 , ISNULL(tv.SyndicatedLoanInterestOSAR_Amount, 0.00) [FunderOwnedInterestReceivable_OSAR_Table]
				 , ISNULL(rtd.FunderRemittingAccrualOSAR, 0.00) + ISNULL(rtd.FunderRemittingNonAccrualOSAR, 0.00) AS [FunderOwnedAndFunderRemittingSalesTaxReceivable_OSAR_Table]
				 , ISNULL(syndication.SundryOSARAmount, 0.00) + ISNULL (syndication.NonAccrualSundryOSARAmount, 0.00) AS [FunderOwnedSundryReceivable_OSAR_Table]
				 , ABS(ISNULL(LoanSyndicationOSAR_GL, 0.00)) AS [FunderOwnedTotalReceivablesAndTaxes_OSAR_GL]
				 , ISNULL(tv.SyndicatedLoanPrincipalOSAR_Amount, 0.00) + ISNULL(tv.SyndicatedLoanInterestOSAR_Amount, 0.00) + ISNULL(rtd.FunderRemittingAccrualOSAR, 0.00) + ISNULL(rtd.FunderRemittingNonAccrualOSAR, 0.00) + ISNULL(syndication.SundryOSARAmount, 0.00) + ISNULL (syndication.NonAccrualSundryOSARAmount, 0.00) - ABS(ISNULL(LoanSyndicationOSAR_GL, 0.00)) AS [FunderOwnedTotalReceivablesAndTaxes_OSAR_Difference]
				 , ISNULL(fcpa.CashPosted, 0.00) AS [FunderOwnedReceivablesAndTaxes_TotalCashApplication_Table]
				 , ISNULL(gld.SyndicatedCashPosting_GL, 0.00) AS [FunderOwnedReceivablesAndTaxes_TotalCashApplication_GL]
				 , ISNULL(fcpa.CashPosted, 0.00) - ISNULL(gld.SyndicatedCashPosting_GL, 0.00) AS [FunderOwnedReceivablesAndTaxes_TotalCashApplication_Difference]
				 , ISNULL(fcpa.NonCashPosted, 0.00) - ISNULL(ncst.FunderRemittingNonCash, 0.00)  AS [FunderOwnedReceivablesAndTaxes_TotalNonCashApplication_Table]
				 , ISNULL(gld.SyndicatedNonCashPosting_GL, 0.00) AS [FunderOwnedReceivablesAndTaxes_TotalNonCashApplication_GL]
				 , ISNULL(fcpa.NonCashPosted, 0.00) - ISNULL(gld.SyndicatedNonCashPosting_GL, 0.00)  AS [FunderOwnedReceivablesAndTaxes_TotalNonCashApplication_Difference]
				 , ISNULL(rtd.LessorRemittingFunderPortion, 0.00) - ISNULL(ncst.FunderPortionNonCash, 0.00) AS [FunderOwnedLessorRemitting_SalesTax_GLPosted_Table]
				 , ISNULL(gld.SalesTaxFunderReceivableLessorRemitting_GL, 0.00) AS [FunderOwnedLessorRemitting_SalesTax_GLPosted_GL]
				 , ISNULL(rtd.LessorRemittingFunderPortion, 0.00) - ISNULL(ncst.FunderPortionNonCash, 0.00) - ISNULL(gld.SalesTaxFunderReceivableLessorRemitting_GL, 0.00) AS [FunderOwnedLessorRemitting_SalesTax_GLPosted_Difference]
				 , ISNULL(rtd.LessorRemittingPrepaidAccrualFunderPortion, 0.00) + ISNULL(rtd.LessorRemittingPrepaidNonAccrualFunderPortion, 0.00) AS [FunderOwnedLessorRemitting_SalesTax_Prepaid_Table]
				 , ISNULL(gld.SalesTaxReceivablePrepaidFunderPortion_GL, 0.00) AS [FunderOwnedLessorRemitting_SalesTax_Prepaid_GL]
				 , ISNULL(rtd.LessorRemittingPrepaidAccrualFunderPortion, 0.00) + ISNULL(rtd.LessorRemittingPrepaidNonAccrualFunderPortion, 0.00) - ISNULL(gld.SalesTaxReceivablePrepaidFunderPortion_GL, 0.00) AS [FunderOwnedLessorRemitting_SalesTax_Prepaid_Difference]
				 , ISNULL(rtd.LessorRemittingAccrualOSARFunderPortion, 0.00) + ISNULL(rtd.LessorRemittingNonAccrualOSARFunderPortion, 0.00) AS [FunderOwnedLessorRemitting_SalesTax_OSAR_Table]
				 , ISNULL(gld.SalesTaxFunderReceivableLessorRemittingOSAR_GL, 0.00) AS [FunderOwnedLessorRemitting_SalesTax_OSAR_GL]
				 , ISNULL(rtd.LessorRemittingAccrualOSARFunderPortion, 0.00) + ISNULL(rtd.LessorRemittingNonAccrualOSARFunderPortion, 0.00) - ISNULL(gld.SalesTaxFunderReceivableLessorRemittingOSAR_GL, 0.00) AS [FunderOwnedLessorRemitting_SalesTax_OSAR_Difference]
				 , ISNULL(fcpa.LessorRemittanceCashTaxApplied, 0.00) AS [FunderOwnedLessorRemitting_SalesTax_TotalCashApplication_Table]
				 , ISNULL(gld.LessorOwnedCashPosting_GL, 0.00) [FunderOwnedLessorRemitting_SalesTax_TotalCashApplication_GL]
				 , ISNULL(fcpa.LessorRemittanceCashTaxApplied, 0.00) - ISNULL(gld.LessorOwnedCashPosting_GL, 0.00) AS [FunderOwnedLessorRemitting_SalesTax_TotalCashApplication_Difference]
				 , ISNULL(fcpa.LessorRemittanceNonCashTaxApplied, 0.00) - ISNULL(ncst.FunderPortionNonCash, 0.00) AS [FunderOwnedLessorRemitting_SalesTax_TotalNonCashApplication_Table]
				 , ISNULL(gld.LessorOwnedNonCashPosting_GL, 0.00) [FunderOwnedLessorRemitting_SalesTax_TotalNonCashApplication_GL]
				 , ISNULL(fcpa.LessorRemittanceNonCashTaxApplied, 0.00) - ISNULL(gld.LessorOwnedCashPosting_GL, 0.00) -  ISNULL(ncst.FunderPortionNonCash, 0.00) AS [FunderOwnedLessorRemitting_SalesTax_TotalNonCashApplication_Difference]
				 , ISNULL(spv.PrincipalAmount, 0.00) AS [PrincipalPayable_GLPosted_Table]
				 , ISNULL(spv.InterestAmount, 0.00) AS [InterestPayable_GLPosted_Table]
				 , ISNULL(spv.SalesTaxAmount, 0.00) AS [SalesTaxPayable_GLPosted_Table]
				 , ISNULL(spv.SundryAmount, 0.00) AS [SundryPayable_GLPosted_Table]
				 , ISNULL(gld.RentDueToInvestor_GL, 0.00) +  ISNULL(pgla.DRAmount, 0.00) AS [TotalPayable_GLPosted_GL]
				 , ISNULL(spv.PrincipalAmount, 0.00) + ISNULL(spv.InterestAmount, 0.00) + ISNULL(spv.SalesTaxAmount, 0.00) + ISNULL(spv.SundryAmount, 0.00) - (ISNULL(gld.RentDueToInvestor_GL, 0.00) +  ISNULL(pgla.DRAmount, 0.00)) AS [TotalPayable_GLPosted_Difference]
            FROM Contracts c
                 INNER JOIN #BasicDetails bd ON bd.ContractId = c.Id
                 INNER JOIN #LoanDetails ld ON bd.ContractId = ld.ContractId
                 LEFT JOIN LegalEntities le ON le.Id = ld.LegalEntityId
                 LEFT JOIN Parties p ON ld.CustomerId = p.Id
                 LEFT JOIN #LoanTableValues tv ON tv.ContractId = bd.ContractId
                 LEFT JOIN #CapitalizedInterests ci ON bd.ContractId = ci.ContractId
                 LEFT JOIN #LoanGLJournalValues gld ON bd.ContractId = gld.ContractId
                 LEFT JOIN #AccrualDetails ad ON bd.ContractId = ad.ContractId
                 LEFT JOIN #LoanPaydownTemp pdc ON bd.ContractId = pdc.ContractId
                                                   AND Pdc.Paydownreason = @FullPaydown
                 LEFT JOIN #ReceivableSumAmount ReceivableSum ON bd.ContractId = ReceivableSum.ContractId
                 LEFT JOIN #TotalGainAmount TotalGainAmount ON bd.ContractId = TotalGainAmount.ContractId
                 LEFT JOIN #WriteDown wd ON bd.ContractId = wd.ContractId
                 LEFT JOIN #ChargeOffDetails cod ON bd.ContractId = cod.ContractId
                 LEFT JOIN #InterestApplied ia ON bd.ContractId = ia.ContractId
                 LEFT JOIN #ReceiptDetails rd ON bd.ContractId = rd.ContractId
				 LEFT JOIN #SyndicationReceivableValues syndication ON bd.ContractId = syndication.ContractId
				 LEFT JOIN #SyndicationPayableValues spv ON bd.ContractId = spv.ContractId
				 LEFT JOIN #SyndicationProceedsAmount spa ON bd.ContractId = spa.ContractId
				 LEFT JOIN #ReceivableTaxDetails rtd ON bd.ContractId = rtd.ContractId
				 LEFT JOIN #PayableGLAmount pgla ON bd.ContractId = pgla.ContractId
				 LEFT JOIN #FunderCashPostedAmount fcpa ON bd.ContractId = fcpa.ContractId
				 LEFT JOIN #ProgressPaymentCreditAmount ppca ON bd.ContractId = ppca.ContractId
				 LEFT JOIN #ProgressPaymentCreditGLAmount ppcaGL on bd.ContractId = ppcaGL.ContractId
				 LEFT JOIN #NonCashSalesTax ncst ON bd.ContractId = ncst.ContractId
            WHERE ld.IsDSL = 0 
                  AND ld.IsProgressLoan = 0) as t;


		CREATE NONCLUSTERED INDEX IX_Id ON #ResultList(ContractId);


		SELECT name AS Name, 0 AS Count, CAST (0 AS BIT) AS IsProcessed, CAST('' AS NVARCHAR(max)) AS Label, column_Id AS ColumnId
		INTO #LoanSummary
		FROM tempdb.sys.columns
		WHERE object_id = OBJECT_ID('tempdb..#ResultList')
		AND Name LIKE '%Difference';

		DECLARE @query NVARCHAR(MAX);
		DECLARE @TableName NVARCHAR(max);
		WHILE EXISTS (SELECT 1 FROM #LoanSummary WHERE IsProcessed = 0)
		BEGIN
		SELECT TOP 1 @TableName = Name FROM #LoanSummary WHERE IsProcessed = 0

		SET @query = 'UPDATE #LoanSummary SET Count = (SELECT COUNT(*) FROM #ResultList WHERE ' + @TableName+ ' != 0.00), IsProcessed = 1
					  WHERE Name = '''+ @TableName+''' ;'
		EXEC (@query)
		END
				

UPDATE #LoanSummary SET 
                        Label = CASE
                                    WHEN Name = 'TotalFinancedAmount_Difference'
                                    THEN '1_Total Financed Amount_Difference'
                                    WHEN Name = 'PrincipalBalance_Difference'
                                    THEN '3_Principal Balance_Difference'
                                    WHEN Name = 'IncomeAccrualBalance_Difference'
                                    THEN '4_Income Accrual Balance_Difference'
                                    WHEN Name = 'SuspendedIncomeBalance_Difference'
                                    THEN '5_Suspended Income Balance_Difference'
                                    WHEN Name = 'CapitalizedInterest_Difference'
                                    THEN '6_Capitalized Interest_Difference'
                                    WHEN Name = 'PrincipalReceivableGLPosted_Difference'
                                    THEN '7_Principal Receivable - GLPosted_Difference'
                                    WHEN Name = 'PrincipalReceivable_OSAR_Difference'
                                    THEN '9_Principal Receivable - OSAR_Difference'
                                    WHEN Name = 'PrincipalReceivable_Prepaid_Difference'
                                    THEN '8_Principal Receivable - Prepaid_Difference'
                                    WHEN Name = 'InterestReceivable_OSAR_Difference'
                                    THEN '12_Interest Receivable - OSAR_Difference'
                                    WHEN Name = 'InterestReceivable_Prepaid_Difference'
                                    THEN '11_Interest Receivable - Prepaid_Difference'
                                    WHEN Name = 'InterestReceivableGLPosted_Difference'
                                    THEN '10_Interest Receivable - GL Posted_Difference'
                                    WHEN Name = 'TotalGainOrLossAmount_Difference'
                                    THEN '17_Total Gain/Loss Amount_Difference'
                                    WHEN Name = 'Principal_TotalCashApplication_Difference'
                                    THEN '13_Principal - Total Cash Application_Difference'
                                    WHEN Name = 'Principal_TotalNonCashApplication_Difference'
                                    THEN '14_Principal - Total Non-Cash Application_Difference'
                                    WHEN Name = 'Interest_TotalCashApplication_Difference'
                                    THEN '15_Interest - Total Cash Application_Difference'
                                    WHEN Name = 'Interest_TotalNonCashApplication_Difference'
                                    THEN '16_Interest - Total Non-Cash Application_Difference'
                                    WHEN Name = 'UnappliedCash_Difference'
                                    THEN '18_Unapplied Cash_Difference'
                                    WHEN Name = 'GrossWritedowns_Difference'
                                    THEN '19_Gross Writedowns_Difference'
                                    WHEN Name = 'NetWritedowns_Difference'
                                    THEN '20_Net Writedowns_Difference'
                                    WHEN Name = 'ChargeoffExpense_Difference'
                                    THEN '21_Charge-off Expense_Difference'
                                    WHEN Name = 'RecoveryAmount_Difference'
                                    THEN '22_Recovery Amount_Difference'
                                    WHEN Name = 'FunderOwnedTotalReceivablesAndTaxes_Prepaid_Difference'
                                    THEN '31_Funder Owned: Total Receivables&Taxes - Prepaid_Difference'
                                    WHEN Name = 'FunderOwnedTotalReceivablesAndTaxes_OSAR_Difference'
                                    THEN '32_Funder Owned: Total Receivables&Taxes - OSAR_Difference'
                                    WHEN Name = 'FunderOwnedTotalReceivablesAndTaxes_GLPosted_Difference'
                                    THEN '30_Funder Owned: TotalReceivables&Taxes - GLPosted_Difference'
                                    WHEN Name = 'LessorOwnedSalesTax_PrePaid_Difference'
                                    THEN '24_Lessor Owned: SalesTax - PrePaid_Difference'
                                    WHEN Name = 'LessorOwnedSalesTax_OSAR_Difference'
                                    THEN '25_Lessor Owned: SalesTax - OSAR_Difference'
                                    WHEN Name = 'LessorOwnedSalesTax_GLPosted_Difference'
                                    THEN '23_Lessor Owned: SalesTax - GLPosted_Difference'
                                    WHEN Name = 'FunderOwnedLessorRemitting_SalesTax_Prepaid_Difference'
                                    THEN '36_Funder Owned & Lessor Remitting - SalesTax - Prepaid_Difference'
                                    WHEN Name = 'FunderOwnedLessorRemitting_SalesTax_OSAR_Difference'
                                    THEN '37_Funder Owned & Lessor Remitting - SalesTax - OSAR_Difference'
                                    WHEN Name = 'FunderOwnedLessorRemitting_SalesTax_TotalNonCashApplication_Difference'
                                    THEN '39_Funder Owned & Lessor Remitting - SalesTax - Total Non-Cash Application_Difference'
                                    WHEN Name = 'SyndicationProceeds_Difference'
                                    THEN '28_Syndication Proceeds_Difference'
                                    WHEN Name = 'TotalPayable_GLPosted_Difference'
                                    THEN '40_Total Payable - GLPosted_Difference'
                                    WHEN Name = 'SyndicationSoldNBV_Difference'
                                    THEN '29_Syndication SoldNBV_Difference'
                                    WHEN Name = 'FunderOwnedLessorRemitting_SalesTax_GLPosted_Difference'
                                    THEN '35_Funder Owned & Lessor Remitting - SalesTax - GLPosted_Difference'
                                    WHEN Name = 'FunderOwnedReceivablesAndTaxes_TotalCashApplication_Difference'
                                    THEN '33_Funder Owned: Receivables&Taxes - TotalCashApplication_Difference'
                                    WHEN Name = 'FunderOwnedReceivablesAndTaxes_TotalNonCashApplication_Difference'
                                    THEN '34_Funder Owned: Receivables&Taxes - Total Non-Cash Application_Difference'
                                    WHEN Name = 'FunderOwnedLessorRemitting_SalesTax_TotalCashApplication_Difference'
                                    THEN '38_Funder Owned & Lessor Remitting - SalesTax - Total Cash Application_Difference'
                                    WHEN Name = 'LessorOwnedSalesTax_TotalCashApplication_Difference'
                                    THEN '26_Lessor Owned: SalesTax - Total Cash Application_Difference'
                                    WHEN Name = 'LessorOwnedSalesTax_TotalNonCashApplication_Difference'
                                    THEN '27_LessorOwned: SalesTax- Total Non-Cash Application_Difference'
                                    WHEN Name = 'ProgressPaymentCredit_Difference'
                                    THEN '2_ProgressPaymentCredit_Difference'
                                END;


		SELECT Label AS Name, Count
		FROM #LoanSummary
		ORDER BY ColumnId
		
		IF (@ResultOption = 'All')
		BEGIN
        SELECT *
        FROM #ResultList
		ORDER BY ContractId;
		END

		IF (@ResultOption = 'Failed')
		BEGIN
		SELECT *
		FROM #ResultList
		WHERE Result = 'Problem Record'
		ORDER BY ContractId;
		END

		IF (@ResultOption = 'Passed')
		BEGIN
		SELECT *
		FROM #ResultList
		WHERE Result = 'Not Problem Record'
		ORDER BY ContractId;
		END

		DECLARE @TotalCount BIGINT;
		SELECT @TotalCount = ISNULL(COUNT(*), 0) FROM #ResultList
		DECLARE @InCorrectCount BIGINT;
		SELECT @InCorrectCount = ISNULL(COUNT(*), 0) FROM #ResultList WHERE Result  = 'Problem Record' 
		DECLARE @Messages StoredProcMessage
		
		INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('TotalLoans', (Select 'Loans=' + CONVERT(nvarchar(40), @TotalCount)))
		INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('LoanSuccessful', (Select 'LoanSuccessful=' + CONVERT(nvarchar(40), (@TotalCount - @InCorrectCount))))
		INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('LoanIncorrect', (Select 'LoanIncorrect=' + CONVERT(nvarchar(40), @InCorrectCount)))

		INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('LoanResultOption', (Select 'ResultOption=' + CONVERT(nvarchar(40), @ResultOption)))

		SELECT * FROM @Messages

        DROP TABLE #LoanDetails;
        DROP TABLE #BasicDetails;
        DROP TABLE #LoanTableValues;
        DROP TABLE #LoanIncomeScheduleTemp;
        DROP TABLE #LoanFinanceBasicTemp;
        DROP TABLE #ReceivableDetailsTemp;
        DROP TABLE #LoanPaydownTemp;
        DROP TABLE #FutureScheduledFundedTemp;
        DROP TABLE #CapitalizedInterests;
        DROP TABLE #GLTrialBalance;
        DROP TABLE #LoanGLJournalValues;
        DROP TABLE #AccrualDetails;
        DROP TABLE #ReceivableSumAmount;
        DROP TABLE #RePossessionAmount;
        DROP TABLE #CumulativeInterestAppliedToPrincipal;
        DROP TABLE #WriteDown;
        DROP TABLE #ChargeOffDetails;
        DROP TABLE #BlendedItemTemp;
        DROP TABLE #InterestApplied;
        DROP TABLE #ReceiptDetails;
		DROP TABLE #ResultList;
		DROP TABLE #RefundDetails;
		DROP TABLE #RefundGLJournalIds;
		DROP TABLE #GLDetails;
		DROP TABLE #SyndicationReceivableValues;
		DROP TABLE #SyndicationProceedsReceivables
		DROP TABLE #SyndicationProceedsAmount
		DROP TABLE #ReceivableTaxDetails;
		DROP TABLE #SyndicationDetailsTemp;
		DROP TABLE #SyndicationPayableValues;
		DROP TABLE #DRDetails
		DROP TABLE #PayableGLAmount
		DROP TABLE #FunderCashPostedAmount
		DROP TABLE #MaxReceivablePaymentEndDate
		DROP TABLE #MinNonServicingDate
		DROP TABLE #ProgressPaymentCredit
		DROP TABLE #ProgressPaymentCreditAmount
		DROP TABLE #ProgressPaymentCreditGLAmount
		DROP TABLE #NonCashSalesTax
		DROP TABLE #LoanSummary
		IF OBJECT_ID('tempdb..#ReceiptApplicationReceivableDetails') IS NOT NULL
		BEGIN
			DROP TABLE #ReceiptApplicationReceivableDetails;
		END
		IF OBJECT_ID('tempdb..#ChargeoffRecoveryReceiptIds') IS NOT NULL
		BEGIN
			DROP TABLE #ChargeoffRecoveryReceiptIds;
		END
		IF OBJECT_ID('tempdb..#ChargeoffExpenseReceiptIds') IS NOT NULL
		BEGIN
			DROP TABLE #ChargeoffExpenseReceiptIds;
		END
		IF OBJECT_ID('tempdb..#NonSKUChargeoffRecoveryRecords') IS NOT NULL
		BEGIN
			DROP TABLE #NonSKUChargeoffRecoveryRecords;
		END
		IF OBJECT_ID('tempdb..#NonSKUChargeoffExpenseRecords') IS NOT NULL
		BEGIN
			DROP TABLE #NonSKUChargeoffExpenseRecords;
		END
	
		SET NOCOUNT OFF
		SET ANSI_WARNINGS ON 
    END;

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[SPHC_CapitalLeaseGLPosting_Reconciliation]
(
	@ResultOption NVARCHAR(20),
	@LegalEntityIds ReconciliationId READONLY,
	@ContractIds ReconciliationId READONLY,  
	@CustomerIds ReconciliationId READONLY
)
AS
BEGIN
	SET NOCOUNT ON
	SET ANSI_WARNINGS OFF
	IF OBJECT_ID('tempdb..#EligibleContracts') IS NOT NULL
	BEGIN
		DROP TABLE #EligibleContracts;
	END
	IF OBJECT_ID('tempdb..#OverTerm') IS NOT NULL
	BEGIN
		DROP TABLE #OverTerm;
	END
	IF OBJECT_ID('tempdb..#PaymentAmount') IS NOT NULL
	BEGIN
		DROP TABLE #PaymentAmount;
	END
	IF OBJECT_ID('tempdb..#FullPaidOffContracts') IS NOT NULL
	BEGIN
		DROP TABLE #FullPaidOffContracts;
	END
	IF OBJECT_ID('tempdb..#LeaseAmendment') IS NOT NULL
	BEGIN
		DROP TABLE #LeaseAmendment;
	END
	IF OBJECT_ID('tempdb..#HasFinanceAsset') IS NOT NULL
	BEGIN
		DROP TABLE #HasFinanceAsset;
	END
	IF OBJECT_ID('tempdb..#ChargeOff') IS NOT NULL
	BEGIN
		DROP TABLE #ChargeOff;
	END
	IF OBJECT_ID('tempdb..#Resultlist') IS NOT NULL
	BEGIN
		DROP TABLE #Resultlist;
	END
	IF OBJECT_ID('tempdb..#AccrualDetails') IS NOT NULL
	BEGIN
		DROP TABLE #AccrualDetails;
	END
	IF OBJECT_ID('tempdb..#SumOfReceivables') IS NOT NULL
	BEGIN
		DROP TABLE #SumOfReceivables;
	END
	IF OBJECT_ID('tempdb..#SumOfReceivableDetails') IS NOT NULL
	BEGIN
		DROP TABLE #SumOfReceivableDetails;
	END
	IF OBJECT_ID('tempdb..#PaidReceivables') IS NOT NULL
	BEGIN
		DROP TABLE #PaidReceivables;
	END
	IF OBJECT_ID('tempdb..#AssetResiduals') IS NOT NULL
	BEGIN
		DROP TABLE #AssetResiduals;
	END
	IF OBJECT_ID('tempdb..#SKUResiduals') IS NOT NULL
	BEGIN
		DROP TABLE #SKUResiduals;
	END
	IF OBJECT_ID('tempdb..#PrePaid') IS NOT NULL
	BEGIN
		DROP TABLE #PrePaid;
	END
	IF OBJECT_ID('tempdb..#Receivable') IS NOT NULL
	BEGIN
		DROP TABLE #Receivable;
	END
	IF OBJECT_ID('tempdb..#GLTrialBalance') IS NOT NULL
	BEGIN
		DROP TABLE #GLTrialBalance;
	END
	IF OBJECT_ID('tempdb..#GLJournalDetail') IS NOT NULL
	BEGIN
		DROP TABLE #GLJournalDetail;
	END
	IF OBJECT_ID('tempdb..#LeaseIncomeScheduleDetails') IS NOT NULL
	BEGIN
		DROP TABLE #LeaseIncomeScheduleDetails;
	END
	IF OBJECT_ID('tempdb..#BlendedIncomeSchInfo') IS NOT NULL
	BEGIN
		DROP TABLE #BlendedIncomeSchInfo;
	END
	IF OBJECT_ID('tempdb..#BlendedItemInfo') IS NOT NULL
	BEGIN
		DROP TABLE #BlendedItemInfo;
	END
	IF OBJECT_ID('tempdb..#WriteDownInfo') IS NOT NULL
	BEGIN
		DROP TABLE #WriteDownInfo;
	END
	IF OBJECT_ID('tempdb..#ChargeOffInfo') IS NOT NULL
	BEGIN
		DROP TABLE #ChargeOffInfo;
	END
	IF OBJECT_ID('tempdb..#SumOfReceipts') IS NOT NULL
	BEGIN
		DROP TABLE #SumOfReceipts;
	END
	IF OBJECT_ID('tempdb..#SumOfPayables') IS NOT NULL
	BEGIN
		DROP TABLE #SumOfPayables;
	END
	IF OBJECT_ID('tempdb..#OTPReclass') IS NOT NULL
	BEGIN
		DROP TABLE #OTPReclass;
	END
	IF OBJECT_ID('tempdb..#OTPPaidResiduals') IS NOT NULL
	BEGIN
		DROP TABLE #OTPPaidResiduals;
	END
	IF OBJECT_ID('tempdb..#OTPPaidResiduals_SKU') IS NOT NULL
	BEGIN
		DROP TABLE #OTPPaidResiduals_SKU;
	END
	IF OBJECT_ID('tempdb..#ReceivableForTaxes') IS NOT NULL
	BEGIN
		DROP TABLE #ReceivableForTaxes;
	END
	IF OBJECT_ID('tempdb..#SalesTaxDetails') IS NOT NULL
	BEGIN
		DROP TABLE #SalesTaxDetails;
	END
	IF OBJECT_ID('tempdb..#ReceivableTaxDetails') IS NOT NULL
	BEGIN
		DROP TABLE #ReceivableTaxDetails;
	END
	IF OBJECT_ID('tempdb..#CapitalizedDetails') IS NOT NULL
	BEGIN
		DROP TABLE #CapitalizedDetails;
	END
	IF OBJECT_ID('tempdb..#RefundGLJournalIds') IS NOT NULL
	BEGIN
		DROP TABLE #RefundGLJournalIds;
	END
	IF OBJECT_ID('tempdb..#SaleOfPaymentsUnguaranteedInfo') IS NOT NULL
	BEGIN
		DROP TABLE #SaleOfPaymentsUnguaranteedInfo;
	END	
	IF OBJECT_ID('tempdb..#RefundTableValue') IS NOT NULL
	BEGIN
		DROP TABLE #RefundTableValue;
	END
	IF OBJECT_ID('tempdb..#GLDetails') IS NOT NULL
	BEGIN
		DROP TABLE #GLDetails;
	END
	IF OBJECT_ID('tempdb..#RRGLDetails') IS NOT NULL
	BEGIN
		DROP TABLE #RRGLDetails;
	END
	IF OBJECT_ID('tempdb..#RenewalDetails') IS NOT NULL
	BEGIN
		DROP TABLE #RenewalDetails;
	END
	IF OBJECT_ID('tempdb..#CapitalLeaseSummary') IS NOT NULL
	BEGIN
		DROP TABLE #CapitalLeaseSummary;
	END
	IF OBJECT_ID('tempdb..#InterimReceivableInfo') IS NOT NULL
	BEGIN
		DROP TABLE #InterimReceivableInfo;
	END
	IF OBJECT_ID('tempdb..#CapitalizeInterimAmount') IS NOT NULL
	BEGIN
		DROP TABLE #CapitalizeInterimAmount;
	END
	IF OBJECT_ID('tempdb..#SumOfInterimReceivables') IS NOT NULL
	BEGIN
		DROP TABLE #SumOfInterimReceivables;
	END
	IF OBJECT_ID('tempdb..#SumOfVendorRentSharing') IS NOT NULL
	BEGIN
		DROP TABLE #SumOfVendorRentSharing;
	END
	IF OBJECT_ID('tempdb..#SumOfInterimReceiptApplicationReceivableDetails') IS NOT NULL
	BEGIN
		DROP TABLE #SumOfInterimReceiptApplicationReceivableDetails;
	END
	IF OBJECT_ID('tempdb..#SumOfPrepaidInterimReceivables') IS NOT NULL
	BEGIN
		DROP TABLE #SumOfPrepaidInterimReceivables;
	END
	IF OBJECT_ID('tempdb..#InterimLeaseIncomeSchInfo') IS NOT NULL
	BEGIN
		DROP TABLE #InterimLeaseIncomeSchInfo;
	END
	IF OBJECT_ID('tempdb..#InterimOtherBuckets') IS NOT NULL
	BEGIN
		DROP TABLE #InterimOtherBuckets;
	END
	IF OBJECT_ID('tempdb..#ContractsWithManualGLEntries') IS NOT NULL
	BEGIN
		DROP TABLE #ContractsWithManualGLEntries;
	END
	IF OBJECT_ID('tempdb..#FloatRateReceivableDetails') IS NOT NULL
	BEGIN
		DROP TABLE #FloatRateReceivableDetails;
	END
	IF OBJECT_ID('tempdb..#FloatRateReceiptDetails') IS NOT NULL
	BEGIN
		DROP TABLE #FloatRateReceiptDetails;
	END
	IF OBJECT_ID('tempdb..#FloatRateIncomeDetails') IS NOT NULL
	BEGIN
		DROP TABLE #FloatRateIncomeDetails;
	END
	IF OBJECT_ID('tempdb..#FunderReceivableInfo') IS NOT NULL
	BEGIN
		DROP TABLE #FunderReceivableInfo;
	END
	IF OBJECT_ID('tempdb..#RemitOnlyContracts') IS NOT NULL
	BEGIN
		DROP TABLE #RemitOnlyContracts;
	END
	IF OBJECT_ID('tempdb..#FunderReceivableTaxDetails') IS NOT NULL
	BEGIN
		DROP TABLE #FunderReceivableTaxDetails;
	END
	IF OBJECT_ID('tempdb..#SalesTaxNonCashAppliedFO') IS NOT NULL
	BEGIN
		DROP TABLE #SalesTaxNonCashAppliedFO;
	END
	IF OBJECT_ID('tempdb..#FunderReceivableDetailsAmount') IS NOT NULL
	BEGIN
		DROP TABLE #FunderReceivableDetailsAmount;
	END
	IF OBJECT_ID('tempdb..#FunderReceiptApplicationDetails') IS NOT NULL
	BEGIN
		DROP TABLE #FunderReceiptApplicationDetails;
	END
	IF OBJECT_ID('tempdb..#ReceiptApplicationReceivableDetails') IS NOT NULL
	BEGIN
		DROP TABLE #ReceiptApplicationReceivableDetails;
	END
	IF OBJECT_ID('tempdb..#ChargeoffRecoveryReceiptIds') IS NOT NULL
	BEGIN
		DROP TABLE #ChargeoffRecoveryReceiptIds;
	END
	IF OBJECT_ID('tempdb..#ChargeoffRecoveryRecords') IS NOT NULL
	BEGIN
		DROP TABLE #ChargeoffRecoveryRecords;
	END
	IF OBJECT_ID('tempdb..#ChargeoffExpenseReceiptIds') IS NOT NULL
	BEGIN
		DROP TABLE #ChargeoffExpenseReceiptIds;
	END
	IF OBJECT_ID('tempdb..#ChargeoffExpenseRecords') IS NOT NULL
	BEGIN
		DROP TABLE #ChargeoffExpenseRecords;
	END
	IF OBJECT_ID('tempdb..#SumOfVendorRentSharing') IS NOT NULL
	BEGIN
		DROP TABLE #SumOfVendorRentSharing;
	END
	IF OBJECT_ID('tempdb..#FloatRateReceivableDetails') IS NOT NULL
	BEGIN
		DROP TABLE #FloatRateReceivableDetails;
	END
	IF OBJECT_ID('tempdb..#NonSKUChargeoffRecoveryRecords') IS NOT NULL
	BEGIN
		DROP TABLE #NonSKUChargeoffRecoveryRecords;
	END
	IF OBJECT_ID('tempdb..#NonSKUChargeoffExpenseRecords') IS NOT NULL
	BEGIN
		DROP TABLE #NonSKUChargeoffExpenseRecords;
	END

	CREATE TABLE #HasFinanceAsset
	( 
		ContractId BIGINT NOT NULL
	)
	 
	CREATE TABLE #SumOfReceivableDetails
	(ContractId                                      BIGINT NOT NULL, 
	 [GLPostedReceivables_LeaseComponent_Table]      DECIMAL(16, 2) NOT NULL, 
	 [GLPostedReceivables_FinanceComponent_Table]    DECIMAL(16, 2) NOT NULL, 
	 [OutstandingReceivables_LeaseComponent_Table]   DECIMAL(16, 2) NOT NULL, 
	 [OutstandingReceivables_FinanceComponent_Table] DECIMAL(16, 2) NOT NULL,
	 [LongTermReceivables_LeaseComponent_Table]    	 DECIMAL(16, 2) NOT NULL,	 
	 [LongTermReceivables_FinanceComponent_Table]    DECIMAL(16, 2) NOT NULL
	);
	
	CREATE TABLE #PaidReceivables
	 (ContractId                                       				BIGINT NOT NULL, 
	 [PaidReceivables_LeaseComponent_Table]           				DECIMAL(16, 2) NOT NULL,
	 [PaidReceivablesviaCash_LeaseComponent_Table]	  				DECIMAL(16, 2) NOT NULL,
	 [PaidReceivablesviaNonCash_LeaseComponent_Table] 				DECIMAL(16, 2) NOT NULL,
	 [PaidReceivables_FinanceComponent_Table]		  				DECIMAL(16, 2) NOT NULL,
	 [PaidReceivablesviaCash_FinanceComponent_Table]  				DECIMAL(16, 2) NOT NULL,
	 [PaidReceivablesviaNonCash_FinanceComponent_Table]			 	DECIMAL(16, 2) NOT NULL,
	 [Recovery_LeaseComponent_Table]				  				DECIMAL(16, 2) NOT NULL,
	 [Recovery_NonLeaseComponent_Table]				  				DECIMAL(16, 2) NOT NULL,
	 [GLPosted_PreChargeoff_LeaseComponent_Table]	  				DECIMAL(16, 2) NOT NULL,
	 [GlPosted_PreChargeoff_NonLeaseComponent_Table]  				DECIMAL(16, 2) NOT NULL,
	 [ChargeOffGainOnRecovery_LeaseComponent_Table]					DECIMAL(16, 2) NOT NULL,
	 [ChargeOffGainOnRecovery_NonLeaseComponent_Table]				DECIMAL(16, 2) NOT NULL
	);

	CREATE TABLE #AssetResiduals
	(ContractId                                    	BIGINT NOT NULL, 
	 [BookedResidual_LeaseAssets]  					DECIMAL(16, 2) NOT NULL, 
	 [CustomerGuaranteedResidual_LeaseAssets] 		DECIMAL(16, 2) NOT NULL, 
	 [ThirdPartyGuaranteedResidual_LeaseAssets]     DECIMAL(16, 2) NOT NULL, 
	 [BookedResidual_FinanceAssets]   				DECIMAL(16, 2) NOT NULL,
	 [CustomerGuaranteedResidual_FinanceAssets]     DECIMAL(16, 2) NOT NULL,
	 [ThirdPartyGuaranteedResidual_FinanceAssets]	DECIMAL(16, 2) NOT NULL
	);
	
	CREATE TABLE #OTPPaidResiduals
	(ContractId                                    	BIGINT NOT NULL, 
	 [BookedResidual_LeaseAssets]  					DECIMAL(16, 2) NOT NULL, 
	 [CustomerGuaranteedResidual_LeaseAssets] 		DECIMAL(16, 2) NOT NULL, 
	 [ThirdPartyGuaranteedResidual_LeaseAssets]     DECIMAL(16, 2) NOT NULL, 
	 [BookedResidual_FinanceAssets]   				DECIMAL(16, 2) NOT NULL,
	 [CustomerGuaranteedResidual_FinanceAssets]     DECIMAL(16, 2) NOT NULL,
	 [ThirdPartyGuaranteedResidual_FinanceAssets]	DECIMAL(16, 2) NOT NULL
	);

	CREATE TABLE #SalesTaxDetails
	(ContractId               BIGINT NOT NULL, 
	 GLPosted_CashRem_NonCash DECIMAL(16, 2) NOT NULL, 
	 TotalPaid_taxes          DECIMAL(16, 2) NOT NULL, 
	 Paid_CashRem_NonCash     DECIMAL(16, 2) NOT NULL, 
	 TotalPrePaid_Taxes       DECIMAL(16, 2) NOT NULL,
	 PaidTaxesviaCash         DECIMAL(16, 2) NOT NULL, 
	 PaidTaxesviaNonCash      DECIMAL(16, 2) NOT NULL
	);

	CREATE TABLE #CapitalizedDetails
	(ContractId                  BIGINT NOT NULL, 
	 CapitalizedAdditionalCharge DECIMAL(16, 2) NOT NULL, 
	 CapitalizedSalesTax         DECIMAL(16, 2) NOT NULL, 
	 CapitalizedInterimInterest  DECIMAL(16, 2) NOT NULL, 
	 CapitalizedInterimRent      DECIMAL(16, 2) NOT NULL,
	 CapitalizedProgressPayment  DECIMAL(16, 2) NOT NULL
	);
	
	CREATE TABLE #SumOfVendorRentSharing
	(ContractId							   BIGINT NOT NULL,
	VendorInterimRentSharingAmount		   DECIMAL (16, 2) NOT NULL,
	GLPostedVendorInterimRentSharingAmount DECIMAL (16, 2) NOT NULL
	);

	CREATE TABLE #FloatRateReceivableDetails
	(ContractId                     BIGINT, 
	 TotalAmount                    DECIMAL(16, 2), 
	 LeaseComponentAmount           DECIMAL(16, 2), 
	 NonLeaseComponentAmount        DECIMAL(16, 2), 
	 TotalPrepaidAmount             DECIMAL(16, 2), 
	 LeaseComponentPrepaidAmount    DECIMAL(16, 2), 
	 NonLeaseComponentPrepaidAmount DECIMAL(16, 2), 
	 TotalOSARAmount                DECIMAL(16, 2), 
	 LeaseComponentOSARAmount       DECIMAL(16, 2), 
	 NonLeaseComponentOSARAmount    DECIMAL(16, 2),
	);

	CREATE TABLE #FloatRateReceiptDetails
	(ContractId                                              BIGINT, 
	 TotalPaid                                               DECIMAL(16, 2), 
	 LeaseComponentTotalPaid                                 DECIMAL(16, 2), 
	 NonLeaseComponentTotalPaid                              DECIMAL(16, 2), 
	 TotalCashPaidAmount                                     DECIMAL(16, 2), 
	 TotalLeaseComponentCashPaidAmount                       DECIMAL(16, 2), 
	 TotalNonLeaseComponentCashPaidAmount                    DECIMAL(16, 2), 
	 TotalNonCashPaidAmount                                  DECIMAL(16, 2), 
	 TotalLeaseComponentNonCashPaidAmount                    DECIMAL(16, 2), 
	 TotalNonLeaseComponentNonCashPaidAmount                 DECIMAL(16, 2), 
	 GLPosted_PreChargeoff_LeaseComponent_Table              DECIMAL(16, 2), 
	 GlPosted_PreChargeoff_NonLeaseComponent_Table           DECIMAL(16, 2), 
	 Recovery_LeaseComponent_Table                           DECIMAL(16, 2), 
	 Recovery_NonLeaseComponent_Table                        DECIMAL(16, 2)
	);

	CREATE TABLE #SalesTaxNonCashAppliedFO
	(ContractId           BIGINT NOT NULL,
	 FunderPortionNonCash DECIMAL(16, 2) NOT NULL
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

	CREATE TABLE #ReceiptApplicationReceivableDetails
	(EntityId                              BIGINT, 
	 ReceiptClassification                 NVARCHAR(30),
	 ReceiptTypeName					   NVARCHAR(50), 
	 AssetComponentType                    NVARCHAR(10), 
	 IsNonAccrual                          BIT, 
	 ReceivableType                        NVARCHAR(50), 
	 StartDate                             DATE, 
	 BookAmountApplied_Amount              DECIMAL(16, 2), 
	 LeaseComponentAmountApplied_Amount    DECIMAL(16, 2), 
	 NonLeaseComponentAmountApplied_Amount DECIMAL(16, 2), 
	 GainAmount_Amount                     DECIMAL(16, 2), 
	 RecoveryAmount_Amount                 DECIMAL(16, 2), 
	 RecoveryAmount_LC                     DECIMAL(16, 2), 
	 RecoveryAmount_NLC                    DECIMAL(16, 2), 
	 GainAmount_LC                         DECIMAL(16, 2), 
	 GainAmount_NLC                        DECIMAL(16, 2), 
	 ChargeoffExpenseAmount                DECIMAL(16, 2), 
	 ChargeoffExpenseAmount_LC             DECIMAL(16, 2), 
	 ChargeoffExpenseAmount_NLC            DECIMAL(16, 2), 
	 AmountApplied_Amount                  DECIMAL(16, 2), 
	 ReceiptId                             BIGINT, 
	 ReceiptStatus                         NVARCHAR(30), 
	 IsGLPosted                            BIT, 
	 AccountingTreatment                   NVARCHAR(25), 
	 RardId                                BIGINT, 
	 GLTransactionType                     NVARCHAR(50), 
	 DueDate                               DATE,
	 IsRecovery						       BIT NULL
	);

	CREATE TABLE #ChargeoffExpenseReceiptIds
	(Id                             BIGINT, 
	 ReceiptId                      BIGINT, 
	 LeaseComponentAmount_Amount    DECIMAL(16, 2), 
	 NonLeaseComponentAmount_Amount DECIMAL(16, 2), 
	 LeaseComponentGain_Amount      DECIMAL(16, 2), 
	 NonLeaseComponentGain_Amount   DECIMAL(16, 2)
	);

	CREATE TABLE #ChargeoffRecoveryReceiptIds
	(Id                             BIGINT, 
	 ReceiptId                      BIGINT, 
	 LeaseComponentAmount_Amount    DECIMAL(16, 2), 
	 NonLeaseComponentAmount_Amount DECIMAL(16, 2), 
	 LeaseComponentGain_Amount      DECIMAL(16, 2), 
	 NonLeaseComponentGain_Amount   DECIMAL(16, 2)
	);

	CREATE TABLE #ChargeoffRecoveryRecords
	(EntityId                              BIGINT, 
	 ReceiptTypeName                       NVARCHAR(50), 
	 Id                                    BIGINT, 
	 LeaseComponentAmountApplied_Amount    DECIMAL(16, 2), 
	 NonLeaseComponentAmountApplied_Amount DECIMAL(16, 2), 
	 RecoveryAmount_Amount                 DECIMAL(16, 2), 
	 GainAmount_Amount                     DECIMAL(16, 2), 
	 StartDate                             DATE, 
	 RecoveryAmount_LC                     DECIMAL(16, 2), 
	 RecoveryAmount_NLC                    DECIMAL(16, 2), 
	 GainAmount_LC                         DECIMAL(16, 2), 
	 GainAmount_NLC                        DECIMAL(16, 2), 
	 AmountApplied                         DECIMAL(16, 2), 
	 RardId                                BIGINT
	);

	CREATE TABLE #ChargeoffExpenseRecords
	(EntityId                              BIGINT, 
	 ReceiptTypeName                       NVARCHAR(50), 
	 Id                                    BIGINT, 
	 LeaseComponentAmountApplied_Amount    DECIMAL(16, 2), 
	 NonLeaseComponentAmountApplied_Amount DECIMAL(16, 2), 
	 RecoveryAmount_Amount                 DECIMAL(16, 2), 
	 GainAmount_Amount                     DECIMAL(16, 2), 
	 StartDate                             DATE, 
	 RecoveryAmount_LC                     DECIMAL(16, 2) NULL, 
	 RecoveryAmount_NLC                    DECIMAL(16, 2) NULL, 
	 GainAmount_LC                         DECIMAL(16, 2) NULL,  
	 GainAmount_NLC                        DECIMAL(16, 2) NULL, 
	 ChargeoffExpenseAmount                DECIMAL(16, 2), 
	 ChargeoffExpenseAmount_LC             DECIMAL(16, 2) NULL, 
	 ChargeoffExpenseAmount_NLC            DECIMAL(16, 2) NULL, 
	 AmountApplied                         DECIMAL(16, 2), 
	 RardId                                BIGINT, 
	 ReceiptStatus                         NVARCHAR(40)
	);


	CREATE TABLE #ChargeOffInfo
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

	DECLARE @True BIT= 1;
    DECLARE @False BIT= 0;
	DECLARE @IsGainPresent BIT = 0
	DECLARE @LegalEntitiesCount BIGINT = ISNULL((SELECT COUNT(*) FROM @LegalEntityIds), 0)
	DECLARE @ContractsCount BIGINT = ISNULL((SELECT COUNT(*) FROM @ContractIds), 0)
	DECLARE @CustomersCount BIGINT = ISNULL((SELECT COUNT(*) FROM @CustomerIds), 0)
	DECLARE @u_ConversionSource nvarchar(50); 
	SELECT @u_ConversionSource = Value FROM GlobalParameters WHERE Category ='Migration' AND Name = 'ConversionSource'
	DECLARE @Residual_GP nvarchar(50);
	SELECT @Residual_GP = Value FROM GlobalParameters WHERE Category like 'Lease' AND Name like 'IncludeGuaranteedResidualinLongTermReceivables'
	DECLARE @Refunds_GP nvarchar(50);
	SELECT @Refunds_GP = Value FROM GlobalParameters WHERE Category like 'Receipt' AND Name like 'RefundPayableStatus'
	DECLARE @DeferInterimRentIncomeRecognition nvarchar(50);
	SELECT @DeferInterimRentIncomeRecognition = Value FROM GlobalParameters WHERE Category = 'LeaseFinance' AND Name = 'DeferInterimRentIncomeRecognition';
	DECLARE @DeferInterimRentIncomeRecognitionForSingleInstallment nvarchar(50);
	SELECT @DeferInterimRentIncomeRecognitionForSingleInstallment = Value FROM GlobalParameters WHERE Category = 'LeaseFinance' AND Name = 'DeferInterimRentIncomeRecognitionForSingleInstallment';
	DECLARE @DeferInterimInterestIncomeRecognition nvarchar(50);
	SELECT @DeferInterimInterestIncomeRecognition = Value FROM GlobalParameters WHERE Category = 'LeaseFinance' AND Name = 'DeferInterimInterestIncomeRecognition';
	DECLARE @DeferInterimInterestIncomeRecognitionForSingleInstallment nvarchar(50);
	SELECT @DeferInterimInterestIncomeRecognitionForSingleInstallment = Value FROM GlobalParameters WHERE Category = 'LeaseFinance' AND Name = 'DeferInterimInterestIncomeRecognitionForSingleInstallment';

	SELECT c.Sequencenumber as SequenceNumber
		 , c.Alias AS ContractAlias
		 , c.Id as ContractId
		 , lfd.LeaseContractType
		 , lf.legalEntityId as LegalEntityID
		 , c.LineofBusinessId
		 , lf.Id as LeaseFinanceID
		 , lf.CustomerId as CustomerID
		 , CASE
			WHEN c.u_ConversionSource = ISNULL(@u_ConversionSource, 'PMS')
			THEN 'Migrated'
			ELSE 'Not Migrated'
			END AS IsMigrated
		 , c.AccountingStandard
		 , c.Status as ContractStatus
		 , CASE 
			WHEN lfd.IsAdvance = 1
			THEN 'Advance'
			ELSE 'Arrear'
		END as AdvanceOrArrear
		 , lfd.TermInMonths
		 , lfd.NumberOfPayments
		 , lfd.PaymentFrequency
		 , lfd.CommencementDate 
		 , lfd.MaturityDate
		 , CASE 
				   WHEN lfd.IsRegularPaymentStream = 1 
				   THEN 'Regular' 
				   ELSE 'Irregular' 
			   END as RegularOrIrregularPayment
		 , lfd.LeaseContractType as ContractType
		 , IIF(lfd.InterimAssessmentMethod = '_', 'No', 'Yes') AS LeaseWithInterim
		 , lfd.InterimAssessmentMethod
		 , lfd.InterimInterestBillingType
		 , lfd.InterimRentBillingType
		 , c.SyndicationType
		 , CASE 
				WHEN c.IsNonAccrual = 0
				THEN 'Accrual'
				ELSE 'Non Accrual'
			END as AccrualStatus
		, c.ChargeOffStatus
		, CASE 
			WHEN lf.HoldingStatus NOT IN ('_')
			THEN lfd.SalesTypeLeaseGrossProfit_Amount
			ELSE 0
		 END as SalesTypeLeaseGrossProfit_Amount
		 , lfd.IsFloatRateLease
		 , rft.Id AS ReceivableForTransfersId
		 , rft.LeaseFinanceId AS SyndicationLeaseFinanceId
		 , rft.EffectiveDate AS SyndicationEffectiveDate
		 INTO #EligibleContracts
	FROM Contracts c
		 INNER JOIN LeaseFinances lf ON lf.ContractId = c.Id
		 INNER JOIN LeaseFinanceDetails lfd ON lfd.Id = lf.Id
		 LEFT JOIN ReceivableForTransfers rft ON rft.ContractId = c.Id
			AND rft.ApprovalStatus = 'Approved'
	WHERE lf.IsCurrent = 1
		  AND lfd.LeaseContractType != 'Operating'
		  AND (c.Status = 'FullyPaid'
			   OR c.Status = 'Commenced'
			   OR C.Status = 'FullyPaidOff')
		  AND @True = (CASE 
						   WHEN @LegalEntitiesCount > 0 AND EXISTS (SELECT Id FROM @LegalEntityIds WHERE Id = lf.LegalEntityId) THEN @True
						   WHEN @LegalEntitiesCount = 0 THEN @True ELSE @False END)
		  AND @True = (CASE 
						   WHEN @CustomersCount > 0 AND EXISTS (SELECT Id FROM @CustomerIds WHERE Id = lf.CustomerId) THEN @True
						   WHEN @CustomersCount = 0 THEN @True ELSE @False END)
		  AND @True = (CASE 
						   WHEN @ContractsCount > 0 AND EXISTS (SELECT Id FROM @ContractIds WHERE Id = lf.ContractId) THEN @True
						   WHEN @ContractsCount = 0 THEN @True ELSE @False END)

	CREATE NONCLUSTERED INDEX IX_Id ON #EligibleContracts(ContractId);

	SELECT 
		ec.ContractId
	INTO #OverTerm
	FROM #EligibleContracts ec
		INNER JOIN LeaseFinances lf ON lf.Contractid = ec.ContractId
		INNER JOIN LeaseIncomeSchedules lis ON lis.LeaseFinanceId = lf.id
	WHERE lis.IncomeType = 'OverTerm'
		AND lis.IsSchedule = 1
	GROUP BY ec.ContractId;

	CREATE NONCLUSTERED INDEX IX_Id ON #OverTerm(ContractId);
	
	SELECT 
		ec.ContractId AS ContractId
		,ISNULL(lps.Amount_Amount, 0.00) AS PaymentAmount
		INTO #PaymentAmount
		FROM #EligibleContracts ec
		INNER JOIN LeasePaymentSchedules lps ON lps.LeaseFinanceDetailId = ec.LeaseFinanceId
		INNER JOIN (
		SELECT 
			MIN(lps.PaymentNumber) AS MinNonInceptionPaymentNubmer
			,ec.ContractId
	FROM #EligibleContracts ec
			INNER JOIN LeasePaymentSchedules lps ON lps.LeaseFinanceDetailId = ec.LeaseFinanceId
			INNER JOIN LeaseFinanceDetails lfd ON ec.LeaseFinanceId = lfd.Id
	WHERE lps.PaymentNumber >= lfd.NumberOfInceptionPayments + 1
			AND lps.Amount_Amount != 0.00
			AND lps.IsActive = 1
			AND lps.PaymentType = 'FixedTerm'
		GROUP BY ec.ContractId
		) AS t ON t.ContractId = ec.ContractId
		WHERE lps.PaymentNumber = t.MinNonInceptionPaymentNubmer
		AND lps.IsActive = 1
		AND lps.PaymentType = 'FixedTerm'
		GROUP BY ec.ContractId,lps.Amount_Amount;

	CREATE NONCLUSTERED INDEX IX_Id ON #PaymentAmount(ContractId);
	

	SELECT 
		ec.ContractId
		,p.PayoffEffectiveDate
		INTO #FullPaidOffContracts
	FROM #EligibleContracts ec
		INNER JOIN LeaseFinances lf ON ec.ContractId = lf.ContractId
		INNER JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
		INNER JOIN Payoffs p ON lf.Id = p.LeaseFinanceId
	WHERE p.Status = 'Activated'
		AND p.FullPayoff = 1;

	CREATE NONCLUSTERED INDEX IX_Id ON #FullPaidOffContracts(ContractId);
	
	SELECT
		ec.ContractId
		,MAX(nc.Id) AS NonAccrualId
		,MAX(rac.Id) AS ReAccrualId
		,MAX(rac.ReAccrualDate) AS ReAccrualDate
		,MAX(nc.NonAccrualDate) AS NonAccrualDate
	INTO #AccrualDetails
	FROM #EligibleContracts ec
		LEFT JOIN NonAccrualContracts nc ON nc.ContractId = ec.ContractId
		LEFT JOIN NonAccruals na ON nc.NonAccrualId = na.Id
			AND nc.IsActive = 1
			AND na.Status = 'Approved'
		LEFT JOIN ReAccrualContracts rac ON rac.ContractId = ec.ContractId
		LEFT JOIN ReAccruals rc ON rac.ReAccrualId = rc.Id
			AND rac.IsActive = 1
			AND rc.Status = 'Approved'
	GROUP BY ec.ContractId;
	
	CREATE NONCLUSTERED INDEX IX_Id ON #AccrualDetails(ContractId);
	
	DECLARE @IsSku BIT = 0
	DECLARE @FilterCondition nvarchar(max) = ''
	DECLARE @Sql nvarchar(max) ='';
	
	IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Assets' AND COLUMN_NAME = 'IsSku')
	BEGIN
	SET @FilterCondition =' AND a.IsSKU = 0';
	SET @IsSku = 1;
	END
	
	SET @Sql = 
	'SELECT DISTINCT ec.ContractId
	FROM #EligibleContracts ec
	INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
	INNER JOIN LeaseAssets la ON la.LeaseFinanceId = lf.Id
	INNER JOIN Assets a ON la.AssetId = a.Id
	WHERE la.IsLeaseAsset = 0
		AND la.IsActive = 1
		FilterCondition';
		
	IF @FilterCondition IS NOT NULL
		BEGIN
			SET @Sql = REPLACE(@Sql, 'FilterCondition', @FilterCondition);
		END;
	ELSE
		BEGIN
			SET @Sql = REPLACE(@Sql, 'FilterCondition', '');
		END;
		
	INSERT INTO #HasFinanceAsset (ContractId)
	EXEC (@Sql)

	IF @IsSku = 1
	BEGIN
	SET @Sql = 'SELECT DISTINCT ec.ContractId
		FROM #EligibleContracts ec
		INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
		INNER JOIN LeaseAssets la ON la.LeaseFinanceId = lf.Id
		INNER JOIN LeaseAssetSKUs las ON las.LeaseAssetId = la.Id
		INNER JOIN Assets a ON la.AssetId = a.Id
		LEFT JOIN #HasFinanceAsset financeAssets ON financeAssets.ContractId = ec.ContractId
		WHERE a.IsSKU = 1 
			AND la.IsActive = 1
			AND las.IsLeaseComponent = 0
			AND financeAssets.ContractId IS NULL';

	INSERT INTO #HasFinanceAsset (ContractId)
	EXEC (@Sql)
	END

	CREATE NONCLUSTERED INDEX IX_Id ON #HasFinanceAsset(ContractId);
		
		
	SELECT DISTINCT 
		   ec.ContractId
	,	SUM 
		(CASE
			WHEN la.AmendmentType = 'Renewal'
			 THEN 1
			 ELSE 0
		END) AS IsRenewal
	,	SUM
		(CASE
			WHEN la.AmendmentType = 'Assumption'
			 THEN 1
			 ELSE 0
		END) AS IsAssumed	
	INTO #LeaseAmendment
	FROM #EligibleContracts ec
		 INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
		 INNER JOIN LeaseAmendments la ON la.CurrentLeaseFinanceId = lf.Id
	AND la.LeaseAmendmentStatus = 'Approved'
	GROUP BY ec.Contractid;

	SELECT c.ContractId
		 , co.ChargeOffDate
	INTO #ChargeOff
	FROM #EligibleContracts c
		 INNER JOIN ChargeOffs co ON co.ContractId = c.ContractId
	WHERE co.IsActive = 1
		  AND co.Status = 'Approved'
		  AND co.IsRecovery = 0
		  AND co.ReceiptId IS NULL
	
	SELECT Receivables.Id
			, Receivables.EntityID
			, Receivables.DueDate
			, Receivables.IsGLPosted
			, Receivables.TotalAmount_Amount
			, Receivables.TotalBalance_Amount
			, lps.StartDate
			, rt.Name AS ReceivableTypeName
	INTO #Receivable
	FROM #EligibleContracts
			JOIN Receivables ON #EligibleContracts.ContractId = Receivables.EntityID
								AND Receivables.IsActive = 1
								AND Receivables.FunderID IS NULL
								AND Receivables.EntityType = 'CT'
			INNER JOIN ReceivableCodes rc ON rc.id = Receivables.ReceivableCodeId
			INNER JOIN ReceivableTypes rt ON rt.id = rc.ReceivableTypeId
			LEFT JOIN LeasePaymentSchedules lps ON lps.Id = Receivables.PaymentScheduleId
	WHERE rt.Name IN ('LeaseFloatRateAdj', 'CapitalLeaseRental');

	CREATE NONCLUSTERED INDEX IX_Id ON #Receivable(EntityID);
	
	SELECT Receivables.Id
	,	Receivables.EntityID
	,	Receivables.DueDate
	,	Receivables.IsGLPosted
	INTO #ReceivableForTaxes
	FROM #EligibleContracts
		JOIN Receivables ON #EligibleContracts.ContractId = Receivables.EntityId
	WHERE Receivables.IsActive = 1
		  AND Receivables.FunderID IS NULL
		  AND Receivables.EntityType = 'CT'
							
	CREATE NONCLUSTERED INDEX IX_Id ON #ReceivableForTaxes(EntityID);

	SELECT Receivables.EntityID ContractId
	, SUM(CASE
			WHEN co.ContractId IS NULL
			THEN (pd.PrePaidAmount_Amount)
			ELSE 0.00 
		  END) as PrepaidReceivables_LeaseComponent_Table
	, SUM(CASE
			WHEN co.ContractId IS NULL
			THEN (pd.FinancingPrePaidAmount_Amount)
			ELSE 0.00 
		  END) as PrepaidReceivables_FinanceComponent_Table	
	INTO #PrePaid
	FROM #Receivable Receivables
		INNER JOIN PrepaidReceivables pd ON pd.Receivableid = Receivables.ID
					AND Receivables.IsGLPosted = 0
					AND pd.isActive = 1
		LEFT JOIN #ChargeOff co on co.ContractId = Receivables.EntityId
	WHERE Receivables.ReceivableTypeName = 'CapitalLeaseRental'
	GROUP BY Receivables.EntityID
		  
		CREATE NONCLUSTERED INDEX IX_Id ON #PrePaid(ContractId);
		
		  
	SELECT #EligibleContracts.ContractId
		, SUM(Receivables.TotalAmount_Amount) TotalPayments
		, SUM(CASE
				WHEN c.ContractID IS NULL 
					AND Receivables.IsGLPosted = 1
				THEN Receivables.TotalAmount_Amount
				ELSE 0.00
			END) as TotalGLPostedReceivables
		, SUM(Receivables.TotalAmount_Amount) LeaseBookingReceivables
		, SUM(Receivables.TotalBalance_Amount) ReceivablesBalance
		, SUM(CASE
				   WHEN Receivables.IsGLPosted = 1
				   AND c.ChargeOffDate IS NULL
				   THEN Receivables.TotalBalance_Amount
				   ELSE 0
			   END) as TotalOutStandingReceivables 
		, SUM(CASE
				   WHEN Receivables.IsGLPosted = 0
				   AND c.ChargeOffDate IS NULL
				   THEN Receivables.TotalAmount_Amount
				   ELSE 0
			   END) as TotalLongTermReceivables			
	INTO #SumOfReceivables
	FROM #EligibleContracts
		JOIN #Receivable Receivables ON #EligibleContracts.ContractId = Receivables.EntityId
		LEFT JOIN #Chargeoff c ON c.ContractId = #EligibleContracts.ContractId
	WHERE Receivables.ReceivableTypeName = 'CapitalLeaseRental'
	GROUP BY #EligibleContracts.ContractId;
	
		CREATE NONCLUSTERED INDEX IX_Id ON #SumOfReceivables(ContractId);
	
	
	IF @IsSku = 0
	BEGIN
	SET @Sql = 
	'	SELECT #EligibleContracts.ContractId
		, SUM(CASE
				   WHEN Receivables.IsGLPosted = 1 
						AND c.ChargeOffDate IS NULL
						AND rd.AssetComponentType = ''Lease'' 
				   THEN rd.Amount_Amount
				   ELSE 0
			   END) as GLPostedReceivables_LeaseComponent_Table
		, SUM(CASE
				   WHEN Receivables.IsGLPosted = 1 
						AND c.ChargeOffDate IS NULL
						AND rd.AssetComponentType = ''Finance''
				   THEN rd.Amount_Amount
				   ELSE 0
			   END) as GLPostedReceivables_FinanceComponent_Table
		, SUM(CASE
				   WHEN Receivables.IsGLPosted = 1 
						AND c.ChargeOffDate IS NULL
						AND rd.AssetComponentType = ''Lease'' 
				   THEN rd.Balance_Amount
				   ELSE 0
			   END) as OutstandingReceivables_LeaseComponent_Table
		, SUM(CASE
					WHEN Receivables.IsGLPosted = 1 
						AND c.ChargeOffDate IS NULL
						AND rd.AssetComponentType = ''Finance'' 
				   THEN rd.Balance_Amount
				   ELSE 0
			   END) as OutstandingReceivables_FinanceComponent_Table
		, SUM(CASE
				   WHEN Receivables.IsGLPosted = 0
						AND rd.AssetComponentType = ''Lease''
						AND c.ChargeOffDate IS NULL
				   THEN rd.Amount_Amount
				   ELSE 0
			   END) as LongTermReceivables_LeaseComponent_Table
		, SUM(CASE
				   WHEN Receivables.IsGLPosted = 0
						AND rd.AssetComponentType = ''Finance'' 
						AND c.ChargeOffDate IS NULL
				   THEN rd.Amount_Amount
				   ELSE 0
			   END) as LongTermReceivables_FinanceComponent_Table	
	FROM #EligibleContracts
		JOIN #Receivable Receivables ON #EligibleContracts.ContractId = Receivables.EntityID
		INNER JOIN ReceivableDetails rd ON rd.ReceivableID = Receivables.ID
		LEFT JOIN #Chargeoff c ON c.ContractId = #EligibleContracts.ContractId
		WHERE rd.IsActive = 1 
			  AND Receivables.ReceivableTypeName = ''CapitalLeaseRental''
		GROUP BY #EligibleContracts.ContractId;'
	INSERT INTO #SumOfReceivableDetails
	EXEC (@Sql)
	END
	
	IF @IsSku = 1
	BEGIN
	SET @Sql = 
	'SELECT #EligibleContracts.ContractId
		, SUM(CASE
				   WHEN Receivables.IsGLPosted = 1 AND c.ChargeOffDate IS NULL 
				   THEN rd.LeaseComponentAmount_Amount
				   ELSE 0
			   END) as GLPostedReceivables_LeaseComponent_Table
		, SUM(CASE
				   WHEN Receivables.IsGLPosted = 1 AND c.ChargeOffDate IS NULL 
				   THEN rd.NonLeaseComponentAmount_Amount
				   ELSE 0
			   END) as GLPostedReceivables_FinanceComponent_Table
		, SUM(CASE
				   WHEN Receivables.IsGLPosted = 1 AND c.ChargeOffDate IS NULL 
				   THEN rd.LeaseComponentBalance_Amount
				   ELSE 0
			   END) as OutstandingReceivables_LeaseComponent_Table
		, SUM(CASE
				   WHEN Receivables.IsGLPosted = 1 AND c.ChargeOffDate IS NULL 
				   THEN rd.NonLeaseComponentBalance_Amount
				   ELSE 0
			   END) as OutstandingReceivables_FinanceComponent_Table
		, SUM(CASE
				   WHEN Receivables.IsGLPosted = 0 AND c.ChargeOffDate IS NULL 
				   THEN rd.LeaseComponentAmount_Amount
				   ELSE 0
			   END) as LongTermReceivables_LeaseComponent_Table
		, SUM(CASE
				   WHEN Receivables.IsGLPosted = 0 AND c.ChargeOffDate IS NULL 
				   THEN rd.NonLeaseComponentAmount_Amount
				   ELSE 0
			   END) as LongTermReceivables_FinanceComponent_Table	
	FROM #EligibleContracts
	INNER JOIN #Receivable Receivables ON #EligibleContracts.ContractId = Receivables.EntityID
	INNER JOIN ReceivableDetails rd ON rd.ReceivableID = Receivables.ID
	LEFT JOIN #Chargeoff c ON c.ContractId = #EligibleContracts.ContractId
	WHERE rd.IsActive = 1
		  AND Receivables.ReceivableTypeName = ''CapitalLeaseRental''
	GROUP BY #EligibleContracts.ContractId;'

	INSERT INTO #SumOfReceivableDetails
	EXEC (@Sql)
	END
		
	CREATE NONCLUSTERED INDEX IX_Id ON #SumOfReceivableDetails(ContractId);
	
	
	IF @IsSku = 0
	BEGIN
		INSERT INTO #ReceiptApplicationReceivableDetails
		SELECT r.EntityId
			 , ReceiptClassification
			 , rt.ReceiptTypeName
			 , rd.AssetComponentType
			 , CASE WHEN AccrualStatus = 'Accrual'
					THEN CAST(1 AS BIT)
					ELSE CAST(0 AS BIT)
			   END AS IsNonAccrual
			 , receivableTypes.Name AS ReceivableType
			 , lps.StartDate
			 , rard.BookAmountApplied_Amount
		     , CASE WHEN rd.AssetComponentType != 'Finance' 
					 THEN rard.AmountApplied_Amount 
					 ELSE 0.00 
		      END LeaseComponentAmountApplied_Amount
			, CASE WHEN rd.AssetComponentType = 'Finance' 
				   THEN rard.AmountApplied_Amount 
				   ELSE 0.00 
			  END NonLeaseComponentAmountApplied_Amount
			 , rard.GainAmount_Amount
			 , rard.RecoveryAmount_Amount
			 , IIF(rard.RecoveryAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS RecoveryAmount_LC
			 , IIF(rard.RecoveryAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS RecoveryAmount_NLC
			 , IIF(rard.GainAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS GainAmount_LC
			 , IIF(rard.GainAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS GainAmount_NLC
			 , CAST (0.00 AS DECIMAL(16, 2)) AS ChargeoffExpenseAmount
			 , CAST (0.00 AS DECIMAL(16, 2)) AS ChargeoffExpenseAmount_LC
			 , CAST (0.00 AS DECIMAL(16, 2)) AS ChargeoffExpenseAmount_NLC
			 , rard.AmountApplied_Amount
			 , Receipt.Id AS ReceiptId
			 , Receipt.Status AS ReceiptStatus
			 , r.IsGLPosted
			 , rc.AccountingTreatment
			 , rard.Id AS RardId
			 , GTT.Name AS GLTransactionType
			 , r.DueDate
			 , NULL AS IsRecovery
		FROM #EligibleContracts
			 JOIN Receivables r ON #EligibleContracts.ContractId = r.EntityId AND r.EntityType = 'CT'
			 JOIN ReceivableDetails rd ON rd.ReceivableId = r.Id
			 JOIN ReceivableCodes rc ON rc.id = r.ReceivableCodeId
			 JOIN ReceivableTypes receivableTypes ON receivableTypes.id = rc.ReceivableTypeId
			 JOIN GLTemplates GT ON RC.GLTemplateId = GT.Id
		     JOIN GLTransactionTypes GTT ON GT.GLTransactionTypeId = GTT.Id
			 JOIN ReceiptApplicationReceivableDetails rard ON rard.ReceivableDetailId = rd.Id
			 JOIN ReceiptApplications ra ON ra.Id = rard.ReceiptApplicationId
			 JOIN Receipts Receipt ON ra.ReceiptId = Receipt.Id
			 JOIN ReceiptTypes rt ON rt.Id = receipt.TypeId
			 LEFT JOIN #ChargeOff co ON r.EntityId = co.ContractId
			 LEFT JOIN LeasePaymentSchedules lps ON lps.Id = r.PaymentScheduleId
		WHERE rd.IsActive = 1
			 AND rard.IsActive = 1
			 AND rt.IsActive = 1
			 AND r.FunderId IS NULL
			 AND (receivableTypes.Name IN('CapitalLeaseRental', 'LeaseFloatRateAdj', 'OperatingLeaseRental', 'OverTermRental', 'Supplemental', 'LoanInterest', 'LoanPrincipal')
				  OR (r.IsGLPosted = 0 AND receivableTypes.Name NOT IN('CapitalLeaseRental', 'LeaseFloatRateAdj', 'OperatingLeaseRental', 'OverTermRental', 'Supplemental', 'LoanInterest', 'LoanPrincipal', 'PropertyTax', 'PropertyTaxEscrow', 'AssetSale'))
				  OR (rc.AccountingTreatment= 'CashBased' AND receivableTypes.Name = 'AssetSale'));


		INSERT INTO #ChargeoffRecoveryReceiptIds
			SELECT c.Id
				 , co.ReceiptId
				 , 0.00 AS LeaseComponentAmount_Amount
				 , 0.00 AS NonLeaseComponentAmount_Amount
				 , 0.00 AS LeaseComponentGain_Amount
				 , 0.00 AS NonLeaseComponentGain_Amount
			FROM Contracts c
				 INNER JOIN ChargeOffs co ON co.ContractId = c.Id
			WHERE co.IsActive = 1
				  AND co.Status = 'Approved'
				  AND co.IsRecovery = 1
				  AND co.ReceiptId IS NOT NULL
				  AND co.ContractId IN (SELECT Distinct c.ContractId FROM #EligibleContracts c) 
			GROUP BY co.ReceiptId
				   , c.Id ;


		CREATE NONCLUSTERED INDEX IX_Id ON #ChargeoffRecoveryReceiptIds(Id, ReceiptId);

		SELECT DISTINCT 
			   r.EntityId
			 , rt.ReceiptTypeName
			 , receipt.Id
			 , r.LeaseComponentAmountApplied_Amount
			 , r.NonLeaseComponentAmountApplied_Amount
			 , r.RecoveryAmount_Amount
			 , r.GainAmount_Amount
			 , r.StartDate
			 , IIF(r.RecoveryAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS RecoveryAmount_LC
			 , IIF(r.RecoveryAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS RecoveryAmount_NLC
			 , IIF(r.GainAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS GainAmount_LC
			 , IIF(r.GainAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS GainAmount_NLC
			 , r.AmountApplied_Amount AS AmountApplied
			 , r.RardId
		INTO #NonSKUChargeoffRecoveryRecords
		FROM #ReceiptApplicationReceivableDetails r
			 JOIN Receipts receipt ON r.ReceiptId = Receipt.Id
			 JOIN ReceiptTypes rt ON rt.Id = receipt.TypeId
			 JOIN #ChargeoffRecoveryReceiptIds co ON r.EntityId = co.Id
													AND co.ReceiptId = receipt.Id
		WHERE (r.ReceivableType IN('CapitalLeaseRental', 'LeaseFloatRateAdj', 'OperatingLeaseRental', 'OverTermRental', 'Supplemental', 'LoanInterest', 'LoanPrincipal')
			   OR (r.IsGLPosted = 0 AND r.ReceivableType NOT IN('CapitalLeaseRental', 'LeaseFloatRateAdj', 'OperatingLeaseRent', 'OverTermRental', 'Supplemental', 'LoanInterest', 'LoanPrincipal', 'PropertyTax', 'PropertyTaxEscrow', 'AssetSale'))
			   OR (r.AccountingTreatment = 'CashBased' AND r.ReceivableType = 'AssetSale'));

		CREATE NONCLUSTERED INDEX IX_Id ON #NonSKUChargeoffRecoveryRecords(RardId);


		UPDATE #NonSKUChargeoffRecoveryRecords SET 
												   RecoveryAmount_LC = LeaseComponentAmountApplied_Amount
												 , RecoveryAmount_NLC = NonLeaseComponentAmountApplied_Amount
		WHERE RecoveryAmount_Amount != 0.00
			  AND RecoveryAmount_Amount = AmountApplied;

		UPDATE #NonSKUChargeoffRecoveryRecords SET 
												   GainAmount_LC = LeaseComponentAmountApplied_Amount
												 , GainAmount_NLC = NonLeaseComponentAmountApplied_Amount
		WHERE GainAmount_Amount != 0.00
			  AND GainAmount_Amount = AmountApplied;

		UPDATE #NonSKUChargeoffRecoveryRecords SET 
												   RecoveryAmount_LC = CASE
																		   WHEN NonLeaseComponentAmountApplied_Amount = 0.00
																		   THEN RecoveryAmount_Amount
																		   ELSE RecoveryAmount_LC
																	   END
												 , RecoveryAmount_NLC = CASE
																			WHEN LeaseComponentAmountApplied_Amount = 0.00
																			THEN RecoveryAmount_Amount
																			ELSE RecoveryAmount_NLC
																		END
		WHERE RecoveryAmount_Amount != 0.00
			  AND (RecoveryAmount_LC IS NULL OR RecoveryAmount_NLC IS NULL)
			  AND (NonLeaseComponentAmountApplied_Amount = 0.00 OR LeaseComponentAmountApplied_Amount = 0.00);

		UPDATE #NonSKUChargeoffRecoveryRecords SET 
												   GainAmount_LC = CASE
																	   WHEN NonLeaseComponentAmountApplied_Amount = 0.00
																	   THEN GainAmount_Amount
																	   ELSE GainAmount_LC
																   END
												 , GainAmount_NLC = CASE
																		WHEN LeaseComponentAmountApplied_Amount = 0.00
																		THEN GainAmount_Amount
																		ELSE GainAmount_NLC
																	END
		WHERE GainAmount_Amount != 0.00
			  AND (GainAmount_LC IS NULL OR GainAmount_NLC IS NULL)
			  AND (NonLeaseComponentAmountApplied_Amount = 0.00 OR LeaseComponentAmountApplied_Amount = 0.00);

		UPDATE #NonSKUChargeoffRecoveryRecords SET 
												   RecoveryAmount_NLC = CASE
																			WHEN NonLeaseComponentAmountApplied_Amount = 0.00
																			THEN 0.00
																			ELSE RecoveryAmount_NLC
																		END
												 , RecoveryAmount_LC = CASE
																		   WHEN LeaseComponentAmountApplied_Amount = 0.00
																		   THEN 0.00
																		   ELSE RecoveryAmount_LC
																	   END
												 , GainAmount_NLC = CASE
																		WHEN NonLeaseComponentAmountApplied_Amount = 0.00
																		THEN 0.00
																		ELSE GainAmount_NLC
																	END
												 , GainAmount_LC = CASE
																	   WHEN LeaseComponentAmountApplied_Amount = 0.00
																	   THEN 0.00
																	   ELSE GainAmount_LC
																   END
		WHERE(NonLeaseComponentAmountApplied_Amount = 0.00 OR LeaseComponentAmountApplied_Amount = 0.00);

		UPDATE rard SET 
						RecoveryAmount_LC = ISNULL(coe.RecoveryAmount_LC, 0.00)
					  , RecoveryAmount_NLC = ISNULL(coe.RecoveryAmount_NLC, 0.00)
					  , GainAmount_LC = ISNULL(coe.GainAmount_LC, 0.00)
					  , GainAmount_NLC = ISNULL(coe.GainAmount_NLC, 0.00)
					  , IsRecovery = CAST(1 AS BIT)
		FROM #ReceiptApplicationReceivableDetails rard
			 INNER JOIN #NonSKUChargeoffRecoveryRecords coe ON coe.RardId = rard.RardId;

	-- Chargeoff Expense logic
	INSERT INTO #ChargeoffExpenseReceiptIds
		SELECT c.Id
			 , co.ReceiptId
			 , 0.00 AS LeaseComponentAmount_Amount
			 , 0.00 AS NonLeaseComponentAmount_Amount
			 , 0.00 AS LeaseComponentGain_Amount
			 , 0.00 AS NonLeaseComponentGain_Amount
		FROM Contracts c
			 INNER JOIN ChargeOffs co ON co.ContractId = c.Id
		WHERE co.IsActive = 1
			  AND co.Status = 'Approved'
			  AND co.IsRecovery = 0
			  AND co.ReceiptId IS NOT NULL
			  AND co.ContractId IN (SELECT Distinct c.ContractId FROM #EligibleContracts c) 
		GROUP BY c.Id
			   , co.ReceiptId;

	CREATE NONCLUSTERED INDEX IX_Id ON #ChargeoffExpenseReceiptIds(Id, ReceiptId);

	SELECT DISTINCT
	  r.EntityId
	, r.ReceiptTypeName
	, r.ReceiptId
	, r.LeaseComponentAmountApplied_Amount
	, r.NonLeaseComponentAmountApplied_Amount
	, r.RecoveryAmount_Amount
	, r.GainAmount_Amount
	, r.StartDate
	, r.AmountApplied_Amount - (r.RecoveryAmount_Amount + r.GainAmount_Amount) AS ChargeoffExpenseAmount
	, IIF(r.LeaseComponentAmountApplied_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)),CAST(0 AS DECIMAL(16, 2)))  AS ChargeoffExpenseAmount_LC
	, IIF(r.NonLeaseComponentAmountApplied_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)),CAST(0 AS DECIMAL(16, 2))) AS ChargeoffExpenseAmount_NLC
	, r.AmountApplied_Amount AS AmountApplied
	, IIF(r.RecoveryAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS RecoveryAmount_LC
	, IIF(r.RecoveryAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS RecoveryAmount_NLC
	, IIF(r.GainAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS GainAmount_LC
	, IIF(r.GainAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS GainAmount_NLC
	, r.RardId
	INTO #NonSKUChargeoffExpenseRecords
	FROM #ReceiptApplicationReceivableDetails r
	JOIN #ChargeoffExpenseReceiptIds co ON r.EntityId = co.Id
										   AND co.ReceiptId = r.ReceiptId
	WHERE (r.ReceivableType IN ('CapitalLeaseRental', 'LeaseFloatRateAdj', 'OperatingLeaseRental', 'OverTermRental', 'Supplemental', 'LoanInterest', 'LoanPrincipal')
		   OR (r.IsGLPosted = 0 AND r.ReceivableType NOT IN ('CapitalLeaseRental', 'LeaseFloatRateAdj', 'OperatingLeaseRental', 'OverTermRental', 'Supplemental', 'LoanInterest', 'LoanPrincipal', 'PropertyTax', 'PropertyTaxEscrow', 'AssetSale'))
		   OR (r.AccountingTreatment = 'CashBased' AND r.ReceivableType = 'AssetSale'))
		    
	UPDATE #NonSKUChargeoffExpenseRecords SET 
											  ChargeoffExpenseAmount_LC = 0.00
											, ChargeoffExpenseAmount_NLC = 0.00
	WHERE ChargeoffExpenseAmount = 0.00;


	UPDATE #NonSKUChargeoffExpenseRecords SET 
											  ChargeoffExpenseAmount_LC = CASE
																			  WHEN NonLeaseComponentAmountApplied_Amount = 0.00
																			  THEN ChargeoffExpenseAmount
																			  ELSE ChargeoffExpenseAmount_LC
																		  END
											, ChargeoffExpenseAmount_NLC = CASE
																			   WHEN LeaseComponentAmountApplied_Amount = 0.00
																			   THEN ChargeoffExpenseAmount
																			   ELSE ChargeoffExpenseAmount_NLC
																		   END
	WHERE ChargeoffExpenseAmount != 0.00
		  AND (ChargeoffExpenseAmount_LC IS NULL OR ChargeoffExpenseAmount_NLC IS NULL)
		  AND (NonLeaseComponentAmountApplied_Amount = 0.00 OR LeaseComponentAmountApplied_Amount = 0.00);


 	UPDATE #NonSKUChargeoffExpenseRecords SET 
												RecoveryAmount_LC = CASE
																		WHEN NonLeaseComponentAmountApplied_Amount = 0.00 AND RecoveryAmount_Amount != 0.00
																		THEN RecoveryAmount_Amount
																		ELSE RecoveryAmount_LC
																	END
											, RecoveryAmount_NLC = CASE
																		WHEN LeaseComponentAmountApplied_Amount = 0.00 AND RecoveryAmount_Amount != 0.00
																		THEN RecoveryAmount_Amount
																		ELSE RecoveryAmount_NLC
																	END
											, GainAmount_LC = CASE
																	WHEN NonLeaseComponentAmountApplied_Amount = 0.00 AND GainAmount_Amount != 0.00
																	THEN GainAmount_Amount
																	ELSE GainAmount_LC
																END
											, GainAmount_NLC = CASE
																	WHEN LeaseComponentAmountApplied_Amount = 0.00 AND GainAmount_Amount != 0.00
																	THEN GainAmount_Amount
																	ELSE GainAmount_NLC
																END
	WHERE RecoveryAmount_Amount != 0.00 OR GainAmount_Amount != 0.00
			AND (RecoveryAmount_LC IS NULL OR RecoveryAmount_NLC IS NULL OR GainAmount_LC IS NULL OR GainAmount_NLC IS NULL)
			AND (NonLeaseComponentAmountApplied_Amount = 0.00 OR LeaseComponentAmountApplied_Amount = 0.00);
	

	UPDATE rard SET 
					RecoveryAmount_LC = ISNULL(coe.RecoveryAmount_LC, 0.00)
					, RecoveryAmount_NLC = ISNULL(coe.RecoveryAmount_NLC, 0.00)
					, GainAmount_LC = ISNULL(coe.GainAmount_LC, 0.00)
					, GainAmount_NLC = ISNULL(coe.GainAmount_NLC, 0.00)
					, ChargeoffExpenseAmount_LC = ISNULL(coe.ChargeoffExpenseAmount_LC, 0.00)
					, ChargeoffExpenseAmount_NLC = ISNULL(coe.ChargeoffExpenseAmount_NLC, 0.00)
					, IsRecovery = CAST(0 AS BIT)
	FROM #ReceiptApplicationReceivableDetails rard
			INNER JOIN #NonSKUChargeoffExpenseRecords coe ON coe.RardId = rard.RardId;


	INSERT INTO #PaidReceivables
	SELECT r.EntityId
		, SUM(CASE WHEN r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00 AND RecoveryAmount_Amount = 0.00 
						AND (r.StartDate < co.ChargeOffDate  OR co.ChargeOffDate IS NULL) 
				   THEN r.LeaseComponentAmountApplied_Amount
				   ELSE 0.00
			  END) as PaidReceivables_LeaseComponent_Table
		, SUM(CASE
					WHEN ReceiptClassification = 'Cash'
						AND r.ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund')
						AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00 AND RecoveryAmount_Amount = 0.00
						AND (r.StartDate < co.ChargeOffDate  OR co.ChargeOffDate IS NULL) 
					THEN r.LeaseComponentAmountApplied_Amount
					ELSE 0.00
				END) as PaidReceivablesviaCash_LeaseComponent_Table
		, SUM(CASE
					WHEN (ReceiptClassification NOT IN ('Cash')
						  OR r.ReceiptTypeName IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund'))
						 AND RecoveryAmount_Amount = 0.00 AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00
						 AND (r.StartDate < co.ChargeOffDate OR co.ChargeOffDate IS NULL)
					THEN r.LeaseComponentAmountApplied_Amount
					ELSE 0
				END) as PaidReceivablesviaNonCash_LeaseComponent_Table
		, SUM(CASE WHEN RecoveryAmount_Amount = 0.00 AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_NLC = 0.00
						AND (r.StartDate < co.ChargeOffDate OR co.ChargeOffDate IS NULL)
				   THEN r.NonLeaseComponentAmountApplied_Amount
				   ELSE 0.00
			  END) as PaidReceivables_FinanceComponent_Table
		, SUM(CASE
					WHEN ReceiptClassification = 'Cash'
						AND r.ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund')
						AND RecoveryAmount_Amount = 0.00 AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_NLC = 0.00
						AND (r.StartDate < co.ChargeOffDate OR co.ChargeOffDate IS NULL)
					THEN r.NonLeaseComponentAmountApplied_Amount
					ELSE 0
				END) as PaidReceivablesviaCash_FinanceComponent_Table
		, SUM(CASE
					WHEN (ReceiptClassification NOT IN ('Cash')
						OR r.ReceiptTypeName IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund'))
						AND RecoveryAmount_Amount = 0.00 AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_NLC = 0.00
						AND (r.StartDate < co.ChargeOffDate OR co.ChargeOffDate IS NULL)
					THEN r.NonLeaseComponentAmountApplied_Amount
					ELSE 0
				END) as PaidReceivablesviaNonCash_FinanceComponent_Table
		, SUM(CASE
					WHEN r.RecoveryAmount_LC != 0.00 OR r.GainAmount_LC != 0.00
					THEN r.RecoveryAmount_LC + r.GainAmount_LC
					ELSE 0
				END) as Recovery_LeaseComponent_Table	
		, SUM(CASE
					WHEN r.RecoveryAmount_NLC != 0.00 OR r.GainAmount_NLC != 0.00
					THEN r.RecoveryAmount_NLC + GainAmount_NLC
					ELSE 0
				END) as Recovery_NonLeaseComponent_Table
		, SUM(CASE
					WHEN (r.RecoveryAmount_Amount = 0.00 AND r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00)
						AND r.StartDate < co.ChargeOffDate
						AND co.Contractid IS NOT NULL
					THEN r.LeaseComponentAmountApplied_Amount
					ELSE 0
				END) as GLPosted_PreChargeoff_LeaseComponent_Table	
		, SUM(CASE
					WHEN (r.RecoveryAmount_Amount = 0.00 AND r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_NLC = 0.00)
						AND r.StartDate < co.ChargeOffDate
						AND co.Contractid IS NOT NULL
					THEN r.NonLeaseComponentAmountApplied_Amount
					ELSE 0
				END) AS GlPosted_PreChargeoff_NonLeaseComponent_Table
		, SUM(ISNULL(r.GainAmount_LC, 0.00)) [ChargeOffGainOnRecovery_LeaseComponent_Table]
		, SUM(ISNULL(r.GainAmount_NLC, 0.00)) AS [ChargeOffGainOnRecovery_NonLeaseComponent_Table]
	FROM #ReceiptApplicationReceivableDetails r
		LEFT JOIN #ChargeOff co ON r.EntityId = co.ContractId
	WHERE r.ReceiptStatus IN ('Completed','Posted')
		  AND r.ReceivableType IN ('CapitalLeaseRental')
	GROUP BY r.EntityId;
	
	END
	
	IF @IsSku = 1
	BEGIN
		SET @SQL = 
		'SELECT DISTINCT
			   r.EntityId
			 , ReceiptClassification
			 , rt.ReceiptTypeName
			 , rd.AssetComponentType
			 , CASE WHEN AccrualStatus = ''Accrual''
					THEN CAST(1 AS BIT)
					ELSE CAST(0 AS BIT)
			   END AS IsNonAccrual
			 , receivableTypes.Name AS ReceivableType
			 , lps.StartDate
			 , rard.BookAmountApplied_Amount
			 , rard.LeaseComponentAmountApplied_Amount
			 , rard.NonLeaseComponentAmountApplied_Amount
			 , rard.GainAmount_Amount
			 , rard.RecoveryAmount_Amount
			 , IIF(rard.RecoveryAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS RecoveryAmount_LC
			 , IIF(rard.RecoveryAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS RecoveryAmount_NLC
			 , IIF(rard.GainAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS GainAmount_LC
			 , IIF(rard.GainAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS GainAmount_NLC
			 , CAST (0.00 AS DECIMAL(16, 2)) AS ChargeoffExpenseAmount
			 , CAST (0.00 AS DECIMAL(16, 2)) AS ChargeoffExpenseAmount_LC
			 , CAST (0.00 AS DECIMAL(16, 2)) AS ChargeoffExpenseAmount_NLC
			 , rard.AmountApplied_Amount
			 , Receipt.Id AS ReceiptId
			 , Receipt.Status AS ReceiptStatus
			 , r.IsGLPosted
			 , rc.AccountingTreatment
			 , rard.Id AS RardId
			 , GTT.Name AS GLTransactionType
			 , r.DueDate
			 , NULL AS IsRecovery
		FROM #EligibleContracts
			 JOIN Receivables r ON #EligibleContracts.ContractId = r.EntityId AND r.EntityType = ''CT''
			 JOIN ReceivableDetails rd ON rd.ReceivableId = r.Id
			 JOIN ReceivableCodes rc ON rc.id = r.ReceivableCodeId
			 JOIN ReceivableTypes receivableTypes ON receivableTypes.id = rc.ReceivableTypeId
			 JOIN GLTemplates GT ON RC.GLTemplateId = GT.Id
		     JOIN GLTransactionTypes GTT ON GT.GLTransactionTypeId = GTT.Id
			 JOIN ReceiptApplicationReceivableDetails rard ON rard.ReceivableDetailId = rd.Id
			 JOIN ReceiptApplications ra ON ra.Id = rard.ReceiptApplicationId
			 JOIN Receipts Receipt ON ra.ReceiptId = Receipt.Id
			 JOIN ReceiptTypes rt ON rt.Id = receipt.TypeId
			 LEFT JOIN #ChargeOff co ON r.EntityId = co.ContractId
			 LEFT JOIN LeasePaymentSchedules lps ON lps.Id = r.PaymentScheduleId
		WHERE rd.IsActive = 1
			 AND rard.IsActive = 1
			 AND rt.IsActive = 1
			 AND r.FunderId IS NULL
		 	 AND (receivableTypes.Name IN(''CapitalLeaseRental'', ''LeaseFloatRateAdj'', ''OperatingLeaseRental'', ''OverTermRental'', ''Supplemental'', ''LoanInterest'', ''LoanPrincipal'')
			 	  OR (r.IsGLPosted = 0 AND receivableTypes.Name NOT IN(''CapitalLeaseRental'', ''LeaseFloatRateAdj'', ''OperatingLeaseRental'', ''OverTermRental'', ''Supplemental'', ''LoanInterest'', ''LoanPrincipal'', ''PropertyTax'', ''PropertyTaxEscrow'', ''AssetSale''))
				  OR (rc.AccountingTreatment= ''CashBased'' AND receivableTypes.Name = ''AssetSale''));'
		INSERT INTO #ReceiptApplicationReceivableDetails
		EXEC (@SQL)

		   -- Charge off recovery calculation logic
	IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ChargeOffs' AND COLUMN_NAME = 'LeaseComponentGain_Amount')
	BEGIN    
	SET @SQL = 
		'SELECT c.Id
			 , co.ReceiptId
			 , SUM(co.LeaseComponentAmount_Amount) AS LeaseComponentAmount_Amount
			 , SUM(co.NonLeaseComponentAmount_Amount) AS NonLeaseComponentAmount_Amount
			 , SUM(co.LeaseComponentGain_Amount) AS LeaseComponentGain_Amount
			 , SUM(co.NonLeaseComponentGain_Amount) AS NonLeaseComponentGain_Amount
		FROM Contracts c
			 INNER JOIN ChargeOffs co ON co.ContractId = c.Id
		WHERE co.IsActive = 1
			  AND co.Status = ''Approved''
			  AND co.IsRecovery = 1
			  AND co.ReceiptId IS NOT NULL
			  AND co.ContractId IN (SELECT Distinct c.ContractId FROM #EligibleContracts c) 
		GROUP BY co.ReceiptId
			   , c.Id ;'

	    INSERT INTO #ChargeoffRecoveryReceiptIds
	    EXEC (@SQL)
	END

	IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ChargeOffs' AND COLUMN_NAME = 'LeaseComponentGain_Amount')
	BEGIN
	SET @SQL = 
		'SELECT c.Id
			 , co.ReceiptId
			 , 0.00 AS LeaseComponentAmount_Amount
			 , 0.00 AS NonLeaseComponentAmount_Amount
			 , 0.00 AS LeaseComponentGain_Amount
			 , 0.00 AS NonLeaseComponentGain_Amount
		FROM Contracts c
			 INNER JOIN ChargeOffs co ON co.ContractId = c.Id
		WHERE co.IsActive = 1
			  AND co.Status = ''Approved''
			  AND co.IsRecovery = 1
			  AND co.ReceiptId IS NOT NULL
			  AND co.ContractId IN (SELECT Distinct c.ContractId FROM #EligibleContracts c) 
		GROUP BY co.ReceiptId
			   , c.Id ;'

	    INSERT INTO #ChargeoffRecoveryReceiptIds
	    EXEC (@SQL)
	END

	CREATE NONCLUSTERED INDEX IX_ReceiptId ON #ChargeoffRecoveryReceiptIds(Id, ReceiptId);


		SET @SQL =
	   'SELECT DISTINCT 
			   r.EntityId
			 , rt.ReceiptTypeName
			 , receipt.Id
			 , r.LeaseComponentAmountApplied_Amount
			 , r.NonLeaseComponentAmountApplied_Amount
			 , r.RecoveryAmount_Amount
			 , r.GainAmount_Amount
			 , r.StartDate
			 , IIF(r.RecoveryAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS RecoveryAmount_LC
			 , IIF(r.RecoveryAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS RecoveryAmount_NLC
			 , IIF(r.GainAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS GainAmount_LC
			 , IIF(r.GainAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS GainAmount_NLC
			 , r.AmountApplied_Amount AS AmountApplied
			 , r.RardId
		FROM #ReceiptApplicationReceivableDetails r
			 JOIN Receipts receipt ON r.ReceiptId = Receipt.Id
			 JOIN ReceiptTypes rt ON rt.Id = receipt.TypeId
			 JOIN #ChargeoffRecoveryReceiptIds co ON r.EntityId = co.Id
													AND co.ReceiptId = receipt.Id
		WHERE Receipt.Status IN(''Posted'', ''Completed'')
			 AND (r.ReceivableType IN(''CapitalLeaseRental'', ''LeaseFloatRateAdj'', ''OperatingLeaseRental'', ''OverTermRental'', ''Supplemental'', ''LoanInterest'', ''LoanPrincipal'')
				  OR (r.IsGLPosted = 0 AND r.ReceivableType NOT IN(''CapitalLeaseRental'', ''LeaseFloatRateAdj'', ''OperatingLeaseRental'', ''OverTermRental'', ''Supplemental'', ''LoanInterest'', ''LoanPrincipal'', ''PropertyTax'', ''PropertyTaxEscrow'', ''AssetSale''))
				  OR (r.AccountingTreatment = ''CashBased'' AND r.ReceivableType = ''AssetSale''));'

		INSERT INTO #ChargeoffRecoveryRecords
		EXEC (@SQL)					
		 

		CREATE NONCLUSTERED INDEX IX_Id ON #ChargeoffRecoveryRecords(EntityId);

		UPDATE #ChargeoffRecoveryRecords SET 
											RecoveryAmount_LC = LeaseComponentAmountApplied_Amount
										  , RecoveryAmount_NLC = NonLeaseComponentAmountApplied_Amount
		WHERE RecoveryAmount_Amount != 0.00
			  AND RecoveryAmount_Amount = AmountApplied;


		UPDATE #ChargeoffRecoveryRecords SET 
											GainAmount_LC = LeaseComponentAmountApplied_Amount
										  , GainAmount_NLC = NonLeaseComponentAmountApplied_Amount
		WHERE GainAmount_Amount != 0.00
			  AND GainAmount_Amount = AmountApplied;		

		UPDATE #ChargeoffRecoveryRecords SET 
											RecoveryAmount_LC = CASE
																	WHEN NonLeaseComponentAmountApplied_Amount = 0.00
																	THEN RecoveryAmount_Amount
																	ELSE RecoveryAmount_LC
																END
										  , RecoveryAmount_NLC = CASE
																	 WHEN LeaseComponentAmountApplied_Amount = 0.00
																	 THEN RecoveryAmount_Amount
																	 ELSE RecoveryAmount_NLC
																 END
		WHERE RecoveryAmount_Amount != 0.00
			  AND (RecoveryAmount_LC IS NULL OR RecoveryAmount_NLC IS NULL)
			  AND (NonLeaseComponentAmountApplied_Amount = 0.00 OR LeaseComponentAmountApplied_Amount = 0.00);

		UPDATE #ChargeoffRecoveryRecords SET 
											GainAmount_LC = CASE
																WHEN NonLeaseComponentAmountApplied_Amount = 0.00
																THEN GainAmount_Amount
																ELSE GainAmount_LC
															END
										  , GainAmount_NLC = CASE
																 WHEN LeaseComponentAmountApplied_Amount = 0.00
																 THEN GainAmount_Amount
																 ELSE GainAmount_NLC
															 END
		WHERE GainAmount_Amount != 0.00
			  AND (GainAmount_LC IS NULL OR GainAmount_NLC IS NULL)
			  AND (NonLeaseComponentAmountApplied_Amount = 0.00 OR LeaseComponentAmountApplied_Amount = 0.00);

		UPDATE #ChargeoffRecoveryRecords SET 
											RecoveryAmount_NLC = CASE
																	 WHEN NonLeaseComponentAmountApplied_Amount = 0.00
																	 THEN 0.00
																	 ELSE RecoveryAmount_NLC
																 END
										  , RecoveryAmount_LC = CASE
																	WHEN LeaseComponentAmountApplied_Amount = 0.00
																	THEN 0.00
																	ELSE RecoveryAmount_LC
																END
										  , GainAmount_NLC = CASE
																 WHEN NonLeaseComponentAmountApplied_Amount = 0.00
																 THEN 0.00
																 ELSE GainAmount_NLC
															 END
										  , GainAmount_LC = CASE
																WHEN LeaseComponentAmountApplied_Amount = 0.00
																THEN 0.00
																ELSE GainAmount_LC
															END
		WHERE(NonLeaseComponentAmountApplied_Amount = 0.00 OR LeaseComponentAmountApplied_Amount = 0.00);

	
		WITH CTE_ChargeoffRecovery
			 AS (SELECT ABS(co.LeaseComponentAmount_Amount) - ABS(RecoveryAmount_LC) AS ChargeoffRecoveryAmount_LC
					  , ABS(co.NonLeaseComponentAmount_Amount) - ABS(RecoveryAmount_NLC) AS ChargeoffRecoveryAmount_NLC
					  , ABS(co.LeaseComponentGain_Amount) - ABS(GainAmount_LC) AS ChargeoffGainAmount_LC
					  , ABS(co.NonLeaseComponentGain_Amount) - ABS(GainAmount_NLC) AS ChargeoffGainAmount_NLC
					  , co.ReceiptId
				 FROM #ChargeoffRecoveryReceiptIds co
					  INNER JOIN
				 (
					 SELECT SUM(ISNULL(RecoveryAmount_LC, 0.00)) AS RecoveryAmount_LC
						  , SUM(ISNULL(RecoveryAmount_NLC, 0.00)) AS RecoveryAmount_NLC
						  , SUM(ISNULL(GainAmount_LC, 0.00)) AS GainAmount_LC
						  , SUM(ISNULL(GainAmount_NLC, 0.00)) AS GainAmount_NLC
						  , Id
					 FROM #ChargeoffRecoveryRecords
					 GROUP BY Id
				 ) AS t ON t.Id = co.ReceiptId)


			UPDATE #ChargeoffRecoveryRecords SET 
												RecoveryAmount_LC = CASE
																	    WHEN coe.RecoveryAmount_LC IS NULL
																		THEN cte.ChargeoffRecoveryAmount_LC
																		ELSE coe.RecoveryAmount_LC
																	END
											, RecoveryAmount_NLC = CASE
																	    WHEN coe.RecoveryAmount_NLC IS NULL
																		THEN cte.ChargeoffRecoveryAmount_NLC
																		ELSE coe.RecoveryAmount_NLC
																	END
											, GainAmount_LC = CASE
																	WHEN coe.GainAmount_LC IS NULL
																	THEN cte.ChargeoffGainAmount_LC
																	ELSE coe.GainAmount_LC
																END
											, GainAmount_NLC = CASE
																	WHEN coe.GainAmount_NLC IS NULL
																	THEN cte.ChargeoffGainAmount_NLC
																	ELSE coe.GainAmount_NLC
																END
			FROM #ChargeoffRecoveryRecords coe
				INNER JOIN CTE_ChargeoffRecovery cte ON cte.ReceiptId = coe.Id
			WHERE(coe.RecoveryAmount_Amount != 0.00 OR coe.GainAmount_Amount != 0.00)
				AND (coe.RecoveryAmount_LC IS NULL OR coe.RecoveryAmount_NLC IS NULL
					OR coe.GainAmount_LC IS NULL OR coe.GainAmount_NLC IS NULL);

			UPDATE rard SET 
								RecoveryAmount_LC = coe.RecoveryAmount_LC
							  , RecoveryAmount_NLC = coe.RecoveryAmount_NLC
							  , GainAmount_LC = coe.GainAmount_LC
							  , GainAmount_NLC = coe.GainAmount_NLC
							  , IsRecovery = CAST(1 AS BIT)
				FROM #ReceiptApplicationReceivableDetails rard
					 INNER JOIN #ChargeoffRecoveryRecords coe ON coe.RardId = rard.RardId;


		-- Charge off expense calculation logic
	IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ChargeOffs' AND COLUMN_NAME = 'LeaseComponentGain_Amount')
	BEGIN
		SET @SQL = 
	   'SELECT c.Id
			 , co.ReceiptId
			 , SUM(co.LeaseComponentAmount_Amount) AS LeaseComponentAmount_Amount
			 , SUM(co.NonLeaseComponentAmount_Amount) AS NonLeaseComponentAmount_Amount
			 , SUM(co.LeaseComponentGain_Amount) AS LeaseComponentGain_Amount
			 , SUM(co.NonLeaseComponentGain_Amount) AS NonLeaseComponentGain_Amount
		FROM Contracts c
			 INNER JOIN ChargeOffs co ON co.ContractId = c.Id
		WHERE co.IsActive = 1
			  AND co.Status = ''Approved''
			  AND co.IsRecovery = 0
			  AND co.ReceiptId IS NOT NULL
			  AND co.ContractId IN (SELECT Distinct c.ContractId FROM #EligibleContracts c) 
		GROUP BY c.Id
			   , co.ReceiptId;'
		INSERT INTO #ChargeoffExpenseReceiptIds
		EXEC (@SQL)

	END

	IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ChargeOffs' AND COLUMN_NAME = 'LeaseComponentGain_Amount')
	BEGIN
		SET @SQL = 
	   'SELECT c.Id
			 , co.ReceiptId
			 , 0.00 AS LeaseComponentAmount_Amount
			 , 0.00 AS NonLeaseComponentAmount_Amount
			 , 0.00 AS LeaseComponentGain_Amount
			 , 0.00 AS NonLeaseComponentGain_Amount
		FROM Contracts c
			 INNER JOIN ChargeOffs co ON co.ContractId = c.Id
		WHERE co.IsActive = 1
			  AND co.Status = ''Approved''
			  AND co.IsRecovery = 0
			  AND co.ReceiptId IS NOT NULL
			  AND co.ContractId IN (SELECT Distinct c.ContractId FROM #EligibleContracts c) 
		GROUP BY c.Id
			   , co.ReceiptId;'
		INSERT INTO #ChargeoffExpenseReceiptIds
		EXEC (@SQL)

	END

		CREATE NONCLUSTERED INDEX IX_ReceiptId ON #ChargeoffExpenseReceiptIds(Id, ReceiptId);

		SET @SQL =
		'SELECT DISTINCT 
			   r.EntityId
			 , rt.ReceiptTypeName
			 , receipt.Id
			 , r.LeaseComponentAmountApplied_Amount
			 , r.NonLeaseComponentAmountApplied_Amount
			 , r.RecoveryAmount_Amount
			 , r.GainAmount_Amount
			 , r.StartDate
			 , IIF(r.RecoveryAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS RecoveryAmount_LC
			 , IIF(r.RecoveryAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS RecoveryAmount_NLC
			 , IIF(r.GainAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS GainAmount_LC
			 , IIF(r.GainAmount_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS GainAmount_NLC
			 , r.AmountApplied_Amount - (r.RecoveryAmount_Amount + r.GainAmount_Amount) AS ChargeoffExpenseAmount
			 , IIF(r.LeaseComponentAmountApplied_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS ChargeoffExpenseAmount_LC
			 , IIF(r.NonLeaseComponentAmountApplied_Amount != 0.00, CAST(NULL AS DECIMAL(16, 2)), CAST(0 AS DECIMAL(16, 2))) AS ChargeoffExpenseAmount_NLC
			 , r.AmountApplied_Amount AS AmountApplied
			 , r.RardId
			 , Receipt.Status AS ReceiptStatus
		FROM #ReceiptApplicationReceivableDetails r
			 JOIN Receipts receipt ON r.ReceiptId = Receipt.Id
			 JOIN ReceiptTypes rt ON rt.Id = receipt.TypeId
			 JOIN #ChargeoffExpenseReceiptIds co ON r.EntityId = co.Id
													AND co.ReceiptId = receipt.Id
		WHERE (r.ReceivableType IN(''CapitalLeaseRental'', ''LeaseFloatRateAdj'', ''OperatingLeaseRental'', ''OverTermRental'', ''Supplemental'', ''LoanInterest'', ''LoanPrincipal'')
			   OR (r.IsGLPosted = 0 AND r.ReceivableType NOT IN(''CapitalLeaseRental'', ''LeaseFloatRateAdj'', ''OperatingLeaseRent'', ''OverTermRental'', ''Supplemental'', ''LoanInterest'', ''LoanPrincipal'', ''PropertyTax'', ''PropertyTaxEscrow'', ''AssetSale''))
			   OR (r.AccountingTreatment = ''CashBased'' AND r.ReceivableType = ''AssetSale''));'

		INSERT INTO #ChargeoffExpenseRecords
		EXEC (@SQL)
		
		 		
		CREATE NONCLUSTERED INDEX IX_Id ON #ChargeoffExpenseRecords(EntityId);

		UPDATE #ChargeoffExpenseRecords SET 
											ChargeoffExpenseAmount_LC = 0.00
										  , ChargeoffExpenseAmount_NLC = 0.00
		WHERE ChargeoffExpenseAmount = 0.00;

		UPDATE #ChargeoffExpenseRecords SET 
											RecoveryAmount_LC = LeaseComponentAmountApplied_Amount
										  , RecoveryAmount_NLC = NonLeaseComponentAmountApplied_Amount
		WHERE RecoveryAmount_Amount != 0.00
			  AND RecoveryAmount_Amount = AmountApplied;

		UPDATE #ChargeoffExpenseRecords SET 
											GainAmount_LC = LeaseComponentAmountApplied_Amount
										  , GainAmount_NLC = NonLeaseComponentAmountApplied_Amount
		WHERE GainAmount_Amount != 0.00
			  AND GainAmount_Amount = AmountApplied;

			  
		UPDATE #ChargeoffExpenseRecords SET 
											RecoveryAmount_LC = CASE
																	WHEN NonLeaseComponentAmountApplied_Amount = 0.00
																	THEN RecoveryAmount_Amount
																	ELSE RecoveryAmount_LC
																END
										  , RecoveryAmount_NLC = CASE
																	 WHEN LeaseComponentAmountApplied_Amount = 0.00
																	 THEN RecoveryAmount_Amount
																	 ELSE RecoveryAmount_NLC
																 END
		WHERE RecoveryAmount_Amount != 0.00
			  AND (RecoveryAmount_LC IS NULL OR RecoveryAmount_NLC IS NULL)
			  AND (NonLeaseComponentAmountApplied_Amount = 0.00 OR LeaseComponentAmountApplied_Amount = 0.00);

		UPDATE #ChargeoffExpenseRecords SET 
											GainAmount_LC = CASE
																WHEN NonLeaseComponentAmountApplied_Amount = 0.00
																THEN GainAmount_Amount
																ELSE GainAmount_LC
															END
										  , GainAmount_NLC = CASE
																 WHEN LeaseComponentAmountApplied_Amount = 0.00
																 THEN GainAmount_Amount
																 ELSE GainAmount_NLC
															 END
		WHERE GainAmount_Amount != 0.00
			  AND (GainAmount_LC IS NULL OR GainAmount_NLC IS NULL)
			  AND (NonLeaseComponentAmountApplied_Amount = 0.00 OR LeaseComponentAmountApplied_Amount = 0.00);
			  
		UPDATE #ChargeoffExpenseRecords SET 
											RecoveryAmount_NLC = CASE
																	 WHEN NonLeaseComponentAmountApplied_Amount = 0.00
																	 THEN 0.00
																	 ELSE RecoveryAmount_NLC
																 END
										  , RecoveryAmount_LC = CASE
																	WHEN LeaseComponentAmountApplied_Amount = 0.00
																	THEN 0.00
																	ELSE RecoveryAmount_LC
																END
										  , ChargeoffExpenseAmount_LC = CASE
																			WHEN LeaseComponentAmountApplied_Amount = 0.00
																			THEN 0.00
																			ELSE ChargeoffExpenseAmount_LC
																		END
										  , ChargeoffExpenseAmount_NLC = CASE
																			 WHEN NonLeaseComponentAmountApplied_Amount = 0.00
																			 THEN 0.00
																			 ELSE ChargeoffExpenseAmount_NLC
																		 END
										  , GainAmount_NLC = CASE
																 WHEN NonLeaseComponentAmountApplied_Amount = 0.00
																 THEN 0.00
																 ELSE GainAmount_NLC
															 END
										  , GainAmount_LC = CASE
																WHEN LeaseComponentAmountApplied_Amount = 0.00
																THEN 0.00
																ELSE GainAmount_LC
															END
		FROM #ChargeoffExpenseRecords
		WHERE(NonLeaseComponentAmountApplied_Amount = 0.00 OR LeaseComponentAmountApplied_Amount = 0.00);

		UPDATE #ChargeoffExpenseRecords SET 
											ChargeoffExpenseAmount_LC = LeaseComponentAmountApplied_Amount
										  , ChargeoffExpenseAmount_NLC = NonLeaseComponentAmountApplied_Amount
		WHERE ChargeoffExpenseAmount != 0.00 AND ChargeoffExpenseAmount = AmountApplied;

		UPDATE #ChargeoffExpenseRecords SET 
											ChargeoffExpenseAmount_LC = CASE
																			WHEN NonLeaseComponentAmountApplied_Amount = 0.00
																			THEN ChargeoffExpenseAmount
																			ELSE ChargeoffExpenseAmount_LC
																		END
										  , ChargeoffExpenseAmount_NLC = CASE
																			 WHEN LeaseComponentAmountApplied_Amount = 0.00
																			 THEN ChargeoffExpenseAmount
																			 ELSE ChargeoffExpenseAmount_NLC
																		 END
		WHERE ChargeoffExpenseAmount != 0.00
			  AND (ChargeoffExpenseAmount_LC IS NULL OR ChargeoffExpenseAmount_NLC IS NULL)
			  AND (NonLeaseComponentAmountApplied_Amount = 0.00 OR LeaseComponentAmountApplied_Amount = 0.00);



		;WITH CTE_ChargeoffExpense
			 AS (SELECT ABS(ChargeoffExpenseAmount_LC) - co.LeaseComponentAmount_Amount AS ChargeoffExpenseAmount_LC
					  , ABS(ChargeoffExpenseAmount_NLC) - co.NonLeaseComponentAmount_Amount AS ChargeoffExpenseAmount_NLC
					  , ABS(GainAmount_LC) - co.LeaseComponentGain_Amount AS ChargeoffGainAmount_LC
					  , ABS(GainAmount_NLC) - co.NonLeaseComponentGain_Amount AS ChargeoffGainAmount_NLC
					  , co.ReceiptId
				 FROM #ChargeoffExpenseReceiptIds co
					  INNER JOIN
				 (
					 SELECT SUM(ISNULL(ChargeoffExpenseAmount_LC, 0.00)) AS ChargeoffExpenseAmount_LC
						  , SUM(ISNULL(ChargeoffExpenseAmount_NLC, 0.00)) AS ChargeoffExpenseAmount_NLC
						  , SUM(ISNULL(GainAmount_LC, 0.00)) AS GainAmount_LC
						  , SUM(ISNULL(GainAmount_NLC, 0.00)) AS GainAmount_NLC
						  , Id
					 FROM #ChargeoffExpenseRecords
					 GROUP BY Id
				 ) AS t ON t.Id = co.ReceiptId)

			 UPDATE #ChargeoffExpenseRecords SET 
												 ChargeoffExpenseAmount_LC = CASE
																				 WHEN coe.ChargeoffExpenseAmount_LC IS NULL
																				 THEN cte.ChargeoffExpenseAmount_LC
																				 ELSE coe.ChargeoffExpenseAmount_LC
																			 END
											   , ChargeoffExpenseAmount_NLC = CASE
																				  WHEN coe.ChargeoffExpenseAmount_NLC IS NULL
																				  THEN cte.ChargeoffExpenseAmount_NLC
																				  ELSE coe.ChargeoffExpenseAmount_NLC
																			  END
											   , GainAmount_LC = CASE
																	 WHEN coe.GainAmount_LC IS NULL
																	 THEN cte.ChargeoffGainAmount_LC
																	 ELSE coe.GainAmount_LC
																 END
											   , GainAmount_NLC = CASE
																	  WHEN coe.GainAmount_NLC IS NULL
																	  THEN cte.ChargeoffGainAmount_NLC
																	  ELSE coe.GainAmount_NLC
																  END
			 FROM #ChargeoffExpenseRecords coe
				  INNER JOIN CTE_ChargeoffExpense cte ON cte.ReceiptId = coe.Id
			 WHERE(coe.ChargeoffExpenseAmount != 0.00
				   OR coe.GainAmount_Amount != 0.00)
				  AND (coe.ChargeoffExpenseAmount_LC IS NULL OR coe.ChargeoffExpenseAmount_NLC IS NULL
					   OR coe.GainAmount_LC IS NULL OR coe.GainAmount_NLC IS NULL);

		UPDATE #ChargeoffExpenseRecords SET 
											RecoveryAmount_LC = CASE
																	WHEN RecoveryAmount_LC IS NULL
																	THEN LeaseComponentAmountApplied_Amount - (ChargeoffExpenseAmount_LC + ISNULL(GainAmount_LC, 0.00))
																	ELSE RecoveryAmount_LC
																END
										  , RecoveryAmount_NLC = CASE
																	 WHEN RecoveryAmount_NLC IS NULL
																	 THEN NonLeaseComponentAmountApplied_Amount - (ChargeoffExpenseAmount_NLC + ISNULL(GainAmount_NLC, 0.00))
																	 ELSE RecoveryAmount_NLC
																 END
		WHERE(RecoveryAmount_NLC IS NULL OR RecoveryAmount_LC IS NULL)
			 AND (ChargeoffExpenseAmount_LC IS NOT NULL AND ChargeoffExpenseAmount_NLC IS NOT NULL);


		UPDATE rard SET 
						RecoveryAmount_LC = coe.RecoveryAmount_LC
					  , RecoveryAmount_NLC = coe.RecoveryAmount_NLC
					  , GainAmount_LC = coe.GainAmount_LC
					  , GainAmount_NLC = coe.GainAmount_NLC
					  , ChargeoffExpenseAmount_LC = coe.ChargeoffExpenseAmount_LC
					  , ChargeoffExpenseAmount_NLC = coe.ChargeoffExpenseAmount_NLC
					  , ChargeoffExpenseAmount = coe.ChargeoffExpenseAmount
					  , IsRecovery = CAST(0 AS BIT)
		FROM #ReceiptApplicationReceivableDetails rard
			 INNER JOIN #ChargeoffExpenseRecords coe ON coe.RardId = rard.RardId

		  INSERT INTO #PaidReceivables
		  SELECT r.EntityId
		, SUM(CASE WHEN r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00 AND RecoveryAmount_Amount = 0.00 
						AND (r.StartDate < co.ChargeOffDate  OR co.ChargeOffDate IS NULL) 
				   THEN r.LeaseComponentAmountApplied_Amount
				   ELSE 0.00
			  END) as PaidReceivables_LeaseComponent_Table
		, SUM(CASE
					WHEN ReceiptClassification = 'Cash'
						AND r.ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund')
						AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00 AND RecoveryAmount_Amount = 0.00
						AND (r.StartDate < co.ChargeOffDate  OR co.ChargeOffDate IS NULL) 
					THEN r.LeaseComponentAmountApplied_Amount
					ELSE 0
				END) as PaidReceivablesviaCash_LeaseComponent_Table
		, SUM(CASE
					WHEN (ReceiptClassification NOT IN ('Cash')
						  OR r.ReceiptTypeName IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund'))
						 AND RecoveryAmount_Amount = 0.00 AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00
						 AND (r.StartDate < co.ChargeOffDate OR co.ChargeOffDate IS NULL)
					THEN r.LeaseComponentAmountApplied_Amount
					ELSE 0
				END) as PaidReceivablesviaNonCash_LeaseComponent_Table
		, SUM(CASE WHEN RecoveryAmount_Amount = 0.00 AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_NLC = 0.00
						AND (r.StartDate < co.ChargeOffDate OR co.ChargeOffDate IS NULL)
				   THEN r.NonLeaseComponentAmountApplied_Amount
				   ELSE 0.00
			  END) as PaidReceivables_FinanceComponent_Table
		, SUM(CASE
					WHEN ReceiptClassification = 'Cash'
						AND r.ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund')
						AND RecoveryAmount_Amount = 0.00 AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_NLC = 0.00
						AND (r.StartDate < co.ChargeOffDate OR co.ChargeOffDate IS NULL)
					THEN r.NonLeaseComponentAmountApplied_Amount
					ELSE 0
				END) as PaidReceivablesviaCash_FinanceComponent_Table
		, SUM(CASE
					WHEN (ReceiptClassification NOT IN ('Cash')
						OR r.ReceiptTypeName IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund'))
						AND RecoveryAmount_Amount = 0.00 AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_NLC = 0.00
						AND (r.StartDate < co.ChargeOffDate OR co.ChargeOffDate IS NULL)
					THEN r.NonLeaseComponentAmountApplied_Amount
					ELSE 0
				END) as PaidReceivablesviaNonCash_FinanceComponent_Table
		, SUM(CASE
					WHEN r.RecoveryAmount_LC != 0.00 OR r.GainAmount_LC != 0.00
					THEN r.RecoveryAmount_LC + r.GainAmount_LC
					ELSE 0
				END) as Recovery_LeaseComponent_Table	
		, SUM(CASE
					WHEN r.RecoveryAmount_NLC != 0.00 OR r.GainAmount_NLC != 0.00
					THEN r.RecoveryAmount_NLC + GainAmount_NLC
					ELSE 0
				END) as Recovery_NonLeaseComponent_Table
		, SUM(CASE
					WHEN (r.RecoveryAmount_Amount = 0.00 AND r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00)
						AND r.StartDate < co.ChargeOffDate
						AND co.Contractid IS NOT NULL
					THEN r.LeaseComponentAmountApplied_Amount
					ELSE 0
				END) as GLPosted_PreChargeoff_LeaseComponent_Table	
		, SUM(CASE
					WHEN (r.RecoveryAmount_Amount = 0.00 AND r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_NLC = 0.00)
						AND r.StartDate < co.ChargeOffDate
						AND co.Contractid IS NOT NULL
					THEN r.NonLeaseComponentAmountApplied_Amount
					ELSE 0
				END) as GlPosted_PreChargeoff_NonLeaseComponent_Table
		, SUM(ISNULL(r.GainAmount_LC, 0.00)) [ChargeOffGainOnRecovery_LeaseComponent_Table]
		, SUM(ISNULL(r.GainAmount_NLC, 0.00)) [ChargeOffGainOnRecovery_NonLeaseComponent_Table]
	FROM #ReceiptApplicationReceivableDetails r
		LEFT JOIN #ChargeOff co ON r.EntityId = co.ContractId
	WHERE r.ReceiptStatus IN ('Completed','Posted')
		  AND r.ReceivableType IN ('CapitalLeaseRental')
	GROUP BY r.EntityId;

	END
								
	CREATE NONCLUSTERED INDEX IX_Id ON #PaidReceivables(ContractId);

	UPDATE sod SET 
				   GLPostedReceivables_LeaseComponent_Table+=pr.GLPosted_PreChargeoff_LeaseComponent_Table
				 , GLPostedReceivables_FinanceComponent_Table+=pr.GlPosted_PreChargeoff_NonLeaseComponent_Table
	FROM #SumOfReceivableDetails sod
		 INNER JOIN #PaidReceivables pr ON sod.ContractID = pr.ContractID
		 INNER JOIN #ChargeOff co ON co.ContractID = sod.ContractID;

	UPDATE sod SET 
				   sod.TotalGlPostedReceivables = sod.TotalGlPostedReceivables + pr.GLPosted_PreChargeoff_LeaseComponent_Table + GlPosted_PreChargeoff_NonLeaseComponent_Table
				 , sod.ReceivablesBalance = sod.ReceivablesBalance + Recovery_LeaseComponent_Table + Recovery_NonLeaseComponent_Table
	FROM #SumOfReceivables sod
		 INNER JOIN #PaidReceivables pr ON sod.ContractID = pr.ContractID
		 INNER JOIN #ChargeOff co ON co.ContractID = sod.ContractID;

	SELECT la.ContractId
		,MAX(lam.CurrentLeaseFinanceId) AS RenewalFinanceId
		,NULL AS LeaseIncomeId
	INTO #RenewalDetails
	FROM #LeaseAmendment la
		INNER JOIN LeaseFinances lf ON lf.ContractId = la.ContractId
			AND la.IsRenewal >= 1
		INNER JOIN LeaseAmendments lam ON lf.Id = lam.CurrentLeaseFinanceId
			AND lam.AmendmentType = 'Renewal' AND lam.LeaseAmendmentStatus = 'Approved'
	GROUP BY la.ContractId;

	CREATE NONCLUSTERED INDEX IX_Id ON #RenewalDetails(ContractId);
	

	UPDATE rd
		SET LeaseIncomeId = t.LeaseIncomeId
	FROM #RenewalDetails rd
		INNER JOIN (
				SELECT MIN(lis.Id) AS LeaseIncomeId,rd.ContractId
				FROM LeaseIncomeSchedules lis
					INNER JOIN LeaseFinances lf ON lis.LeaseFinanceId = lf.Id
					INNER JOIN #RenewalDetails rd ON lf.ContractId = rd.ContractId
				WHERE lis.LeaseFinanceId >= rd.RenewalFinanceId
				GROUP BY rd.ContractId) AS t ON t.ContractId = rd.ContractId;

	SELECT
	DISTINCT
	ec.ContractId
	INTO #OTPReclass
	FROM #EligibleContracts ec
	INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
	INNER JOIN LeaseIncomeSchedules lis ON lis.LeaseFinanceId = lf.Id
	LEFT JOIN #RenewalDetails rd ON rd.ContractId = ec.ContractId
	WHERE lis.IncomeType = 'OverTerm'
	AND lis.IsLessorOwned = 1
	AND lis.IsSchedule = 1
	AND lis.IsReclassOTP = 1
	AND ((rd.ContractId IS NOT NULL AND lis.LeaseFinanceId >= rd.RenewalFinanceId) OR rd.ContractId IS NULL)
	GROUP BY ec.ContractId;

	CREATE NONCLUSTERED INDEX IX_Id ON #OTPReclass(ContractId);

	SET @Sql =	
	'SELECT #EligibleContracts.ContractId
		, SUM(CASE
				   WHEN la.IsLeaseAsset = 1
				   THEN la.BookedResidual_Amount
				   ELSE 0
				END) as BookedResidual_LeaseAssets
		, SUM(CASE
				   WHEN la.IsLeaseAsset = 1
				   THEN la.CustomerGuaranteedResidual_Amount
				   ELSE 0
				END) as CustomerGuaranteedResidual_LeaseAssets
		, SUM(CASE
				   WHEN la.IsLeaseAsset = 1
				   THEN la.ThirdPartyGuaranteedResidual_Amount
				   ELSE 0
				END) as ThirdPartyGuaranteedResidual_LeaseAssets
		, SUM(CASE
				   WHEN la.IsLeaseAsset = 0
				   THEN la.BookedResidual_Amount
				   ELSE 0
				END) as BookedResidual_FinanceAssets
		, SUM(CASE
				   WHEN la.IsLeaseAsset = 0
				   THEN la.CustomerGuaranteedResidual_Amount
				   ELSE 0
				END) as CustomerGuaranteedResidual_FinanceAssets
		, SUM(CASE
				   WHEN la.IsLeaseAsset = 0
				   THEN la.ThirdPartyGuaranteedResidual_Amount
				   ELSE 0
				END) as ThirdPartyGuaranteedResidual_FinanceAssets				
	FROM #EligibleContracts
		JOIN LeaseAssets la ON #EligibleContracts.LeaseFinanceID = la.LeaseFinanceID
							AND la.IsActive = 1
		INNER JOIN Assets a ON a.id = la.AssetId
							FilterCondition
							GROUP BY #EligibleContracts.ContractId;'
	
	IF @FilterCondition IS NOT NULL
		BEGIN
			SET @sql = REPLACE(@sql, 'FilterCondition', @FilterCondition);
		END;
	ELSE
		BEGIN
			SET @sql = REPLACE(@sql, 'FilterCondition', '');
		END;
	
	INSERT INTO #AssetResiduals (ContractId,BookedResidual_LeaseAssets,CustomerGuaranteedResidual_LeaseAssets,ThirdPartyGuaranteedResidual_LeaseAssets,
								 BookedResidual_FinanceAssets,CustomerGuaranteedResidual_FinanceAssets,ThirdPartyGuaranteedResidual_FinanceAssets)
	EXEC (@Sql)

	IF @IsSku = 1
	BEGIN
	SET @Sql = 
	'SELECT #EligibleContracts.ContractId
		, SUM(CASE
				   WHEN las.IsLeaseComponent = 1
				   THEN las.BookedResidual_Amount
				   ELSE 0
				END) as BookedResidual_LeaseSKUs
		, SUM(CASE
				   WHEN las.IsLeaseComponent = 1
				   THEN las.CustomerGuaranteedResidual_Amount
				   ELSE 0
				END) as CustomerGuaranteedResidual_LeaseSKUs
		, SUM(CASE
				   WHEN las.IsLeaseComponent = 1
				   THEN las.ThirdPartyGuaranteedResidual_Amount
				   ELSE 0
				END) as ThirdPartyGuaranteedResidual_LeaseSKUs
		, SUM(CASE
				   WHEN las.IsLeaseComponent = 0
				   THEN las.BookedResidual_Amount
				   ELSE 0
				END) as BookedResidual_FinanceSKUs
		, SUM(CASE
				   WHEN las.IsLeaseComponent = 0
				   THEN las.CustomerGuaranteedResidual_Amount
				   ELSE 0
				END) as CustomerGuaranteedResidual_FinanceSKUs
		, SUM(CASE
				   WHEN las.IsLeaseComponent = 0
				   THEN las.ThirdPartyGuaranteedResidual_Amount
				   ELSE 0
				END) as ThirdPartyGuaranteedResidual_FinanceSKUs				
	INTO #SKUResiduals
	FROM #EligibleContracts
		JOIN LeaseAssets la ON #EligibleContracts.LeaseFinanceID = la.LeaseFinanceID
							AND la.IsActive = 1
		INNER JOIN LeaseAssetSKUs las ON las.LeaseAssetId = la.ID
		INNER JOIN Assets a ON a.id = la.AssetId
							AND a.IsSKU = 1
							GROUP BY #EligibleContracts.ContractId;		
	
	MERGE #AssetResiduals AS AssetResiduals
		USING (SELECT * FROM #SKUResiduals) AS SKUResiduals
		ON (AssetResiduals.ContractId = SKUResiduals.ContractId)
		WHEN MATCHED THEN
			UPDATE SET BookedResidual_LeaseAssets += SKUResiduals.BookedResidual_LeaseSKUs,
					  CustomerGuaranteedResidual_LeaseAssets += SKUResiduals.CustomerGuaranteedResidual_LeaseSKUs,
					  ThirdPartyGuaranteedResidual_LeaseAssets += SKUResiduals.ThirdPartyGuaranteedResidual_LeaseSKUs,
					  BookedResidual_FinanceAssets += SKUResiduals.BookedResidual_FinanceSKUs,
					  CustomerGuaranteedResidual_FinanceAssets += SKUResiduals.CustomerGuaranteedResidual_FinanceSKUs,
					  ThirdPartyGuaranteedResidual_FinanceAssets += SKUResiduals.ThirdPartyGuaranteedResidual_FinanceSKUs
		WHEN NOT MATCHED THEN
			INSERT (ContractId, BookedResidual_LeaseAssets,CustomerGuaranteedResidual_LeaseAssets,ThirdPartyGuaranteedResidual_LeaseAssets,
					BookedResidual_FinanceAssets,CustomerGuaranteedResidual_FinanceAssets,ThirdPartyGuaranteedResidual_FinanceAssets)
			VALUES (SKUResiduals.ContractId, SKUResiduals.BookedResidual_LeaseSKUs, SKUResiduals.CustomerGuaranteedResidual_LeaseSKUs,SKUResiduals.ThirdPartyGuaranteedResidual_LeaseSKUs,
					SKUResiduals.BookedResidual_FinanceSKUs,SKUResiduals.CustomerGuaranteedResidual_FinanceSKUs,SKUResiduals.ThirdPartyGuaranteedResidual_FinanceSKUs);'
	EXEC (@Sql)
	
	CREATE NONCLUSTERED INDEX IX_Id ON #AssetResiduals(ContractId);

	END

		UPDATE AssetResiduals
		SET 
			BookedResidual_LeaseAssets =
			(CASE 
				WHEN c.ChargeOffDate IS NULL
				THEN BookedResidual_LeaseAssets * rft.RetainedPercentage / 100
				ELSE 0.00
			END)
		,	CustomerGuaranteedResidual_LeaseAssets =
			(CASE 
				WHEN c.ChargeOffDate IS NULL
				THEN CustomerGuaranteedResidual_LeaseAssets * rft.RetainedPercentage / 100
				ELSE 0.00
			END)
		,	ThirdPartyGuaranteedResidual_LeaseAssets =
			(CASE 
				WHEN c.ChargeOffDate IS NULL
				THEN ThirdPartyGuaranteedResidual_LeaseAssets * rft.RetainedPercentage / 100
				ELSE 0.00
			END)
		,	BookedResidual_FinanceAssets =
			(CASE 
				WHEN c.ChargeOffDate IS NULL
				THEN BookedResidual_FinanceAssets * rft.RetainedPercentage / 100
				ELSE 0.00
			END)
		,	CustomerGuaranteedResidual_FinanceAssets =
			(CASE 
				WHEN c.ChargeOffDate IS NULL
				THEN CustomerGuaranteedResidual_FinanceAssets * rft.RetainedPercentage / 100
				ELSE 0.00
			END)
		,	ThirdPartyGuaranteedResidual_FinanceAssets =
			(CASE 
				WHEN c.ChargeOffDate IS NULL
				THEN ThirdPartyGuaranteedResidual_FinanceAssets * rft.RetainedPercentage / 100
				ELSE 0.00
			END)
	FROM #AssetResiduals AssetResiduals
			INNER JOIN #EligibleContracts ec on ec.Contractid = AssetResiduals.Contractid
			LEFT JOIN ReceivableForTransfers rft ON rft.ContractId = AssetResiduals.ContractId AND rft.ApprovalStatus = 'Approved'
			AND rft.ContractType = 'Lease'
			LEFT JOIN #ChargeOff c ON c.Contractid = AssetResiduals.Contractid
			WHERE (rft.id is NOT NULL OR c.ContractId is NOT NULL) AND ec.SyndicationType NOT IN ('SaleOfPayments')
			;


	SET @Sql =	
	'SELECT #EligibleContracts.ContractId
		, SUM(CASE
				   WHEN la.IsLeaseAsset = 1
				   THEN la.BookedResidual_Amount
				   ELSE 0
				END) as BookedResidual_LeaseAssets
		, SUM(CASE
				   WHEN la.IsLeaseAsset = 1
				   THEN la.CustomerGuaranteedResidual_Amount
				   ELSE 0
				END) as CustomerGuaranteedResidual_LeaseAssets
		, SUM(CASE
				   WHEN la.IsLeaseAsset = 1
				   THEN la.ThirdPartyGuaranteedResidual_Amount
				   ELSE 0
				END) as ThirdPartyGuaranteedResidual_LeaseAssets
		, SUM(CASE
				   WHEN la.IsLeaseAsset = 0
				   THEN la.BookedResidual_Amount
				   ELSE 0
				END) as BookedResidual_FinanceAssets
		, SUM(CASE
				   WHEN la.IsLeaseAsset = 0
				   THEN la.CustomerGuaranteedResidual_Amount
				   ELSE 0
				END) as CustomerGuaranteedResidual_FinanceAssets
		, SUM(CASE
				   WHEN la.IsLeaseAsset = 0
				   THEN la.ThirdPartyGuaranteedResidual_Amount
				   ELSE 0
				END) as ThirdPartyGuaranteedResidual_FinanceAssets				
	FROM #EligibleContracts
		JOIN LeaseAssets la ON #EligibleContracts.LeaseFinanceID = la.LeaseFinanceID
							AND la.IsActive = 0 AND la.TerminationDate IS NOT NULL
							AND la.TerminationDate > #EligibleContracts.MaturityDate
		INNER JOIN Assets a ON a.id = la.AssetId
							FilterCondition
		INNER JOIN #OverTerm ot on #EligibleContracts.Contractid = ot.ContractId
		LEFT JOIN #OTPReclass oc on oc.ContractId = #EligibleContracts.ContractId
							WHERE oc.ContractId IS NULL
							GROUP BY #EligibleContracts.ContractId;'

	IF @FilterCondition IS NOT NULL
		BEGIN
			SET @sql = REPLACE(@sql, 'FilterCondition', @FilterCondition);
		END;
	ELSE
		BEGIN
			SET @sql = REPLACE(@sql, 'FilterCondition', '');
		END;
	
	INSERT INTO #OTPPaidResiduals (ContractId,BookedResidual_LeaseAssets,CustomerGuaranteedResidual_LeaseAssets,ThirdPartyGuaranteedResidual_LeaseAssets,
									BookedResidual_FinanceAssets,CustomerGuaranteedResidual_FinanceAssets,ThirdPartyGuaranteedResidual_FinanceAssets)
	EXEC (@Sql)

	IF @IsSku = 1
	BEGIN
	SET @Sql = 
	'SELECT #EligibleContracts.ContractId
		, SUM(CASE
				   WHEN las.IsLeaseComponent = 1
				   THEN las.BookedResidual_Amount
				   ELSE 0
				END) as BookedResidual_LeaseSKUs
		, SUM(CASE
				   WHEN las.IsLeaseComponent = 1
				   THEN las.CustomerGuaranteedResidual_Amount
				   ELSE 0
				END) as CustomerGuaranteedResidual_LeaseSKUs
		, SUM(CASE
				   WHEN las.IsLeaseComponent = 1
				   THEN las.ThirdPartyGuaranteedResidual_Amount
				   ELSE 0
				END) as ThirdPartyGuaranteedResidual_LeaseSKUs
		, SUM(CASE
				   WHEN las.IsLeaseComponent = 0
				   THEN las.BookedResidual_Amount
				   ELSE 0
				END) as BookedResidual_FinanceSKUs
		, SUM(CASE
				   WHEN las.IsLeaseComponent = 0
				   THEN las.CustomerGuaranteedResidual_Amount
				   ELSE 0
				END) as CustomerGuaranteedResidual_FinanceSKUs
		, SUM(CASE
				   WHEN las.IsLeaseComponent = 0
				   THEN las.ThirdPartyGuaranteedResidual_Amount
				   ELSE 0
				END) as ThirdPartyGuaranteedResidual_FinanceSKUs
	INTO #OTPPaidResiduals_SKU
	FROM #EligibleContracts
		JOIN LeaseAssets la ON #EligibleContracts.LeaseFinanceID = la.LeaseFinanceID
							AND la.IsActive = 0 AND la.TerminationDate IS NOT NULL
							AND la.TerminationDate > #EligibleContracts.MaturityDate
		INNER JOIN LeaseAssetSKUs las ON las.LeaseAssetId = la.ID
		INNER JOIN Assets a ON a.id = la.AssetId
					AND a.IsSKU = 1
		INNER JOIN #OverTerm ot on #EligibleContracts.Contractid = ot.ContractId
		LEFT JOIN #OTPReclass oc on oc.Contractid = #EligibleContracts.Contractid
					WHERE oc.ContractId IS NULL
					GROUP BY #EligibleContracts.ContractId;
							
		MERGE #OTPPaidResiduals AS AssetResiduals
		USING (SELECT * FROM #OTPPaidResiduals_SKU) AS SKUResiduals
		ON (AssetResiduals.ContractId = SKUResiduals.ContractId)
		WHEN MATCHED THEN
			UPDATE SET BookedResidual_LeaseAssets += SKUResiduals.BookedResidual_LeaseSKUs,
					  CustomerGuaranteedResidual_LeaseAssets += SKUResiduals.CustomerGuaranteedResidual_LeaseSKUs,
					  ThirdPartyGuaranteedResidual_LeaseAssets += SKUResiduals.ThirdPartyGuaranteedResidual_LeaseSKUs,
					  BookedResidual_FinanceAssets += SKUResiduals.BookedResidual_FinanceSKUs,
					  CustomerGuaranteedResidual_FinanceAssets += SKUResiduals.CustomerGuaranteedResidual_FinanceSKUs,
					  ThirdPartyGuaranteedResidual_FinanceAssets += SKUResiduals.ThirdPartyGuaranteedResidual_FinanceSKUs
		WHEN NOT MATCHED THEN
			INSERT (ContractId, BookedResidual_LeaseAssets,CustomerGuaranteedResidual_LeaseAssets,ThirdPartyGuaranteedResidual_LeaseAssets,
					BookedResidual_FinanceAssets,CustomerGuaranteedResidual_FinanceAssets,ThirdPartyGuaranteedResidual_FinanceAssets)
			VALUES (SKUResiduals.ContractId, SKUResiduals.BookedResidual_LeaseSKUs, SKUResiduals.CustomerGuaranteedResidual_LeaseSKUs,SKUResiduals.ThirdPartyGuaranteedResidual_LeaseSKUs,
					SKUResiduals.BookedResidual_FinanceSKUs,SKUResiduals.CustomerGuaranteedResidual_FinanceSKUs,SKUResiduals.ThirdPartyGuaranteedResidual_FinanceSKUs);'

	EXEC (@Sql)

	CREATE NONCLUSTERED INDEX IX_Id ON #OTPPaidResiduals(ContractId);

	END
	
	UPDATE AssetResiduals
		SET 
			BookedResidual_LeaseAssets =
			(CASE 
				WHEN c.ChargeOffDate IS NULL
				THEN BookedResidual_LeaseAssets * rft.RetainedPercentage / 100
				ELSE 0.00
			END)
		,	CustomerGuaranteedResidual_LeaseAssets =
			(CASE 
				WHEN c.ChargeOffDate IS NULL
				THEN CustomerGuaranteedResidual_LeaseAssets * rft.RetainedPercentage / 100
				ELSE 0.00
			END)
		,	ThirdPartyGuaranteedResidual_LeaseAssets =
			(CASE 
				WHEN c.ChargeOffDate IS NULL
				THEN ThirdPartyGuaranteedResidual_LeaseAssets * rft.RetainedPercentage / 100
				ELSE 0.00
			END)
		,	BookedResidual_FinanceAssets =
			(CASE 
				WHEN c.ChargeOffDate IS NULL
				THEN BookedResidual_FinanceAssets * rft.RetainedPercentage / 100
				ELSE 0.00
			END)
		,	CustomerGuaranteedResidual_FinanceAssets =
			(CASE 
				WHEN c.ChargeOffDate IS NULL
				THEN CustomerGuaranteedResidual_FinanceAssets * rft.RetainedPercentage / 100
				ELSE 0.00
			END)
		,	ThirdPartyGuaranteedResidual_FinanceAssets =
			(CASE 
				WHEN c.ChargeOffDate IS NULL
				THEN ThirdPartyGuaranteedResidual_FinanceAssets * rft.RetainedPercentage / 100
				ELSE 0.00
			END)
	FROM #OTPPaidResiduals AssetResiduals
			INNER JOIN #EligibleContracts ec on ec.Contractid = AssetResiduals.Contractid
			LEFT JOIN ReceivableForTransfers rft ON rft.ContractId = AssetResiduals.ContractId AND rft.ApprovalStatus = 'Approved'
			AND rft.ContractType = 'Lease'
			LEFT JOIN #ChargeOff c ON c.Contractid = AssetResiduals.Contractid
			WHERE (rft.id is NOT NULL OR c.ContractId is NOT NULL) AND ec.SyndicationType NOT IN ('SaleOfPayments')
			;

	SELECT LISD.ContractId
		, SUM(LISD.TotalIncome_Accounting) TotalIncome_Accounting
		, SUM(LISD.TotalIncome_Schedule) TotalIncome_Schedule
		, SUM(LISD.TotalSellingProfitIncome_Accounting) TotalSellingProfitIncome_Accounting
		, SUM(LISD.TotalSellingProfitIncome_Schedule) TotalSellingProfitIncome_Schedule
		, SUM(LISD.Finance_TotalIncome_Accounting) Finance_TotalIncome_Accounting
		, SUM(LISD.Finance_TotalIncome_Schedule) Finance_TotalIncome_Schedule
		, SUM(LISD.TotalUnearnedIncome) TotalUnearnedIncome
		, SUM(LISD.Financing_TotalUnearnedIncome) Financing_TotalUnearnedIncome
		, SUM(LISD.UnearnedIncome) UnearnedIncome
		, SUM(LISD.Financing_UnearnedIncome) Financing_UnearnedIncome
		, SUM(LISD.UnearnedResidualIncome) UnearnedResidualIncome
		, SUM(LISD.Financing_UnearnedResidualIncome) Financing_UnearnedResidualIncome
		, SUM(LISD.UnearnedSellingProfitIncome) UnearnedSellingProfitIncome
		, SUM(LISD.TotalEarnedIncome) - SUM(LISD.TotalEarnedIncBtwnNACandCh) TotalEarnedIncome
		, SUM(LISD.Financing_TotalEarnedIncome) - SUM(LISD.TotalFinEarnedIncBtwnNACandCh) Financing_TotalEarnedIncome
		, SUM(LISD.EarnedIncome) - SUM(LISD.EarnedIncBtwnNACandCh) EarnedIncome
		, SUM(LISD.Financing_EarnedIncome) - SUM(LISD.FinEarnedIncBtwnNACandCh) Financing_EarnedIncome
		, SUM(LISD.EarnedResidualIncome) - SUM(LISD.EarnedResBtwnNACandCh) EarnedResidualIncome
		, SUM(LISD.Financing_EarnedResidualIncome) - SUM(LISD.FinEarnedResBtwnNACandCh) Financing_EarnedResidualIncome
		, SUM(LISD.EarnedSellingProfitIncome) - SUM(LISD.EarnedSPBtwnNACandCh) EarnedSellingProfitIncome
		, SUM(LISD.TotalSuspendedIncome) TotalSuspendedIncome
		, SUM(LISD.Financing_TotalSuspendedIncome) Financing_TotalSuspendedIncome
		, SUM(LISD.RecognizedSuspendedIncome) RecognizedSuspendedIncome
		, SUM(LISD.Financing_RecognizedSuspendedIncome) Financing_RecognizedSuspendedIncome
		, SUM(LISD.RecognizedSuspendedResidualIncome) RecognizedSuspendedResidualIncome
		, SUM(LISD.Financing_RecognizedSuspendedResidualIncome) Financing_RecognizedSuspendedResidualIncome
		, SUM(LISD.RecognizedSuspendedSellingProfitIncome) RecognizedSuspendedSellingProfitIncome
	INTO #LeaseIncomeScheduleDetails
	FROM
	(	SELECT ec.ContractId
				, CASE
					WHEN lis.IsAccounting = 1 AND co.contractid IS NULL
					THEN lis.Income_Amount
					WHEN lis.IsAccounting = 1 AND co.contractid IS NOT NULL
					AND  lis.IncomeDate < co.ChargeOffDate
					THEN lis.Income_Amount
					ELSE 0.00
				 END TotalIncome_Accounting
				, CASE
					WHEN lis.IsSchedule = 1 AND co.contractid IS NULL
					AND ac.ReAccrualId IS NULL
					THEN lis.Income_Amount
					WHEN lis.IsSchedule = 1 AND co.contractid IS NOT NULL
					AND  lis.IncomeDate < co.ChargeOffDate
					THEN lis.Income_Amount
					WHEN lis.IsSchedule = 1 AND co.contractid IS NULL 
					AND ac.ReAccrualId IS NOT NULL
					AND IsNonAccrual = 0
					THEN lis.Income_Amount
					ELSE 0.00
				 END TotalIncome_Schedule
				, CASE
					WHEN lis.IsAccounting = 1 AND co.contractid IS NULL
					THEN lis.DeferredSellingProfitIncome_Amount
					WHEN lis.IsAccounting = 1 AND co.contractid IS NOT NULL
					AND  lis.IncomeDate < co.ChargeOffDate
					THEN lis.DeferredSellingProfitIncome_Amount
					ELSE 0.00
				 END TotalSellingProfitIncome_Accounting
				, CASE
					WHEN lis.IsSchedule = 1 AND co.contractid IS NULL
					AND ac.ReAccrualId IS NULL
					THEN lis.DeferredSellingProfitIncome_Amount
					WHEN lis.IsSchedule = 1 AND co.contractid IS NOT NULL
					AND  lis.IncomeDate < co.ChargeOffDate
					THEN lis.DeferredSellingProfitIncome_Amount
					WHEN lis.IsSchedule = 1 AND co.contractid IS NULL 
					AND ac.ReAccrualId IS NOT NULL
					AND IsNonAccrual = 0
					THEN lis.DeferredSellingProfitIncome_Amount
					ELSE 0.00
				 END TotalSellingProfitIncome_Schedule
				, CASE
					WHEN lis.IsAccounting = 1 AND co.contractid IS NULL
					THEN lis.FinanceIncome_Amount
					WHEN lis.IsAccounting = 1 AND co.contractid IS NOT NULL
					AND  lis.IncomeDate < co.ChargeOffDate
					THEN lis.FinanceIncome_Amount
					ELSE 0.00
				 END Finance_TotalIncome_Accounting
				, CASE
					WHEN lis.IsSchedule = 1 AND co.contractid IS NULL
					AND ac.ReAccrualId IS NULL
					THEN lis.FinanceIncome_Amount
					WHEN lis.IsSchedule = 1 AND co.contractid IS NOT NULL
					AND  lis.IncomeDate < co.ChargeOffDate
					THEN lis.FinanceIncome_Amount
					WHEN lis.IsSchedule = 1 AND co.contractid IS NULL 
					AND ac.ReAccrualId IS NOT NULL
					AND IsNonAccrual = 0
					THEN lis.FinanceIncome_Amount
					ELSE 0.00
				 END Finance_TotalIncome_Schedule  
				, CASE
					WHEN lis.IsAccounting = 1
						AND lis.IsGLPosted = 0
					THEN lis.Income_Amount
					ELSE 0.00
				 END TotalUnearnedIncome
				, CASE
					WHEN lis.IsAccounting = 1
						AND lis.IsGLPosted = 0
					THEN lis.FinanceIncome_Amount
					ELSE 0.00
				 END Financing_TotalUnearnedIncome
				, CASE
					WHEN lis.IsAccounting = 1
						AND lis.IsGLPosted = 0
					THEN lis.Income_Amount - lis.ResidualIncome_Amount
					ELSE 0.00
				 END UnearnedIncome
				, CASE
					WHEN lis.IsAccounting = 1
						AND lis.IsGLPosted = 0
					THEN lis.FinanceIncome_Amount - lis.FinanceResidualIncome_Amount
					ELSE 0.00
				 END Financing_UnearnedIncome
				, CASE
					WHEN lis.IsAccounting = 1
						AND lis.IsGLPosted = 0
					THEN lis.ResidualIncome_Amount
					ELSE 0.00
				 END UnearnedResidualIncome
				, CASE
					WHEN lis.IsAccounting = 1
						AND lis.IsGLPosted = 0
					THEN lis.FinanceResidualIncome_Amount
					ELSE 0.00
				 END Financing_UnearnedResidualIncome
				, CASE
					WHEN lis.IsAccounting = 1
						AND lis.IsGLPosted = 0
					THEN lis.DeferredSellingProfitIncome_Amount
					ELSE 0.00
				 END UnearnedSellingProfitIncome
				, CASE
					WHEN lis.IsAccounting = 1
						AND lis.IsGLPosted = 1
						AND lis.IsNonAccrual = 0
						AND rl.ContractId IS NULL 
					THEN lis.Income_Amount
					WHEN lis.IsAccounting = 1
						AND lis.IsGLPosted = 1
						AND lis.IsNonAccrual = 0
						AND rl.ContractId IS NOT NULL
					    AND lis.LeaseFinanceID >= rl.RenewalFinanceID
					THEN lis.Income_Amount
					ELSE 0.00
				 END TotalEarnedIncome
				, CASE
					WHEN lis.IsAccounting = 1
						AND lis.IsGLPosted = 1
						AND lis.IsNonAccrual = 0
						AND rl.ContractId IS NULL
					THEN lis.FinanceIncome_Amount
					WHEN lis.IsAccounting = 1
						AND lis.IsGLPosted = 1
						AND lis.IsNonAccrual = 0
						AND rl.ContractId IS NOT NULL
					    AND lis.LeaseFinanceID >= rl.RenewalFinanceID
					THEN lis.FinanceIncome_Amount
					ELSE 0.00
				 END Financing_TotalEarnedIncome
				, CASE
					WHEN lis.IsAccounting = 1
						AND lis.IsGLPosted = 1
						AND lis.IsNonAccrual = 0
						AND rl.ContractId IS NULL 
					THEN lis.Income_Amount - lis.ResidualIncome_Amount
					WHEN lis.IsAccounting = 1
						AND lis.IsGLPosted = 1
						AND lis.IsNonAccrual = 0
						AND rl.ContractId IS NOT NULL
					    AND lis.LeaseFinanceID >= rl.RenewalFinanceID
					THEN lis.Income_Amount - lis.ResidualIncome_Amount
					ELSE 0.00
				 END EarnedIncome
				, CASE
					WHEN lis.IsAccounting = 1
						AND lis.IsGLPosted = 1
						AND lis.IsNonAccrual = 0
						AND rl.ContractId IS NULL 
					THEN lis.FinanceIncome_Amount - lis.FinanceResidualIncome_Amount
					WHEN lis.IsAccounting = 1
						AND lis.IsGLPosted = 1
						AND lis.IsNonAccrual = 0
						AND rl.ContractId IS NOT NULL
					    AND lis.LeaseFinanceID >= rl.RenewalFinanceID
					THEN lis.FinanceIncome_Amount - lis.FinanceResidualIncome_Amount
					ELSE 0.00
				 END Financing_EarnedIncome
				, CASE
					WHEN lis.IsAccounting = 1
						AND lis.IsGLPosted = 1
						AND lis.IsNonAccrual = 0
						AND rl.ContractId IS NULL
					THEN lis.ResidualIncome_Amount
					WHEN lis.IsAccounting = 1
						AND lis.IsGLPosted = 1
						AND lis.IsNonAccrual = 0
						AND rl.ContractId IS NOT NULL
					    AND lis.LeaseFinanceID >= rl.RenewalFinanceID
					THEN lis.ResidualIncome_Amount
					ELSE 0.00
				 END EarnedResidualIncome
				, CASE
					WHEN lis.IsAccounting = 1
						AND lis.IsGLPosted = 1
						AND lis.IsNonAccrual = 0
						AND rl.ContractId IS NULL
					THEN lis.FinanceResidualIncome_Amount
					WHEN lis.IsAccounting = 1
						AND lis.IsGLPosted = 1
						AND lis.IsNonAccrual = 0
						AND rl.ContractId IS NOT NULL
					    AND lis.LeaseFinanceID >= rl.RenewalFinanceID
					THEN lis.FinanceResidualIncome_Amount
					ELSE 0.00
				 END Financing_EarnedResidualIncome
				, CASE
					WHEN lis.IsAccounting = 1
						AND lis.IsGLPosted = 1
						AND lis.IsNonAccrual = 0
						AND rl.ContractId IS NULL
					THEN lis.DeferredSellingProfitIncome_Amount
					WHEN lis.IsAccounting = 1
						AND lis.IsGLPosted = 1
						AND lis.IsNonAccrual = 0
						AND rl.ContractId IS NOT NULL
					    AND lis.LeaseFinanceID >= rl.RenewalFinanceID
					THEN lis.DeferredSellingProfitIncome_Amount
					ELSE 0.00
				 END EarnedSellingProfitIncome
				, CASE
					WHEN lis.IsAccounting = 1
						AND lis.IsGLPosted = 1
						AND lis.IsNonAccrual = 1
					THEN lis.Income_Amount
					ELSE 0.00
				 END TotalSuspendedIncome
				, CASE
					WHEN lis.IsAccounting = 1
						AND lis.IsGLPosted = 1
						AND lis.IsNonAccrual = 1
					THEN lis.FinanceIncome_Amount
					ELSE 0.00
				 END Financing_TotalSuspendedIncome
				, CASE
					WHEN lis.IsAccounting = 1
						AND lis.IsGLPosted = 1
						AND lis.IsNonAccrual = 1
					THEN lis.Income_Amount - lis.ResidualIncome_Amount
					ELSE 0.00
				 END RecognizedSuspendedIncome
				, CASE
					WHEN lis.IsAccounting = 1
						AND lis.IsGLPosted = 1
						AND lis.IsNonAccrual = 1
					THEN lis.FinanceIncome_Amount - lis.FinanceResidualIncome_Amount
					ELSE 0.00
				 END Financing_RecognizedSuspendedIncome
				, CASE
					WHEN lis.IsAccounting = 1
						AND lis.IsGLPosted = 1
						AND lis.IsNonAccrual = 1
					THEN lis.ResidualIncome_Amount
					ELSE 0.00
				 END RecognizedSuspendedResidualIncome
				, CASE
					WHEN lis.IsAccounting = 1
						AND lis.IsGLPosted = 1
						AND lis.IsNonAccrual = 1
					THEN lis.FinanceResidualIncome_Amount
					ELSE 0.00
				 END Financing_RecognizedSuspendedResidualIncome
				, CASE
					WHEN lis.IsAccounting = 1
						AND lis.IsGLPosted = 1
						AND lis.IsNonAccrual = 1
					THEN lis.DeferredSellingProfitIncome_Amount
					ELSE 0.00
				 END RecognizedSuspendedSellingProfitIncome
				, CASE 
					WHEN lis.IsAccounting = 1
						AND lis.IsGLPosted = 1
						AND IsNonAccrual = 1
						AND co.ContractId IS NOT NULL AND ac.NonAccrualId IS NOT NULL
						AND co.ChargeOffDate != ac.NonAccrualDate
						AND lis.IncomeDate >= ac.NonAccrualDate
						AND lis.IncomeDate < co.ChargeOffDate
					THEN lis.Income_Amount
					ELSE 0.00
				END AS TotalEarnedIncBtwnNACandCh
				, CASE 
					WHEN lis.IsAccounting = 1
						AND lis.IsGLPosted = 1
						AND IsNonAccrual = 1
						AND co.ContractId IS NOT NULL AND ac.NonAccrualId IS NOT NULL
						AND co.ChargeOffDate != ac.NonAccrualDate
						AND lis.IncomeDate >= ac.NonAccrualDate
						AND lis.IncomeDate < co.ChargeOffDate
					THEN lis.Income_Amount - lis.ResidualIncome_Amount
					ELSE 0.00
				END AS EarnedIncBtwnNACandCh
				, CASE
					WHEN lis.IsAccounting = 1
						AND lis.IsGLPosted = 1
						AND IsNonAccrual = 1
						AND co.ContractId IS NOT NULL AND ac.NonAccrualId IS NOT NULL
						AND co.ChargeOffDate != ac.NonAccrualDate
						AND lis.IncomeDate >= ac.NonAccrualDate
						AND lis.IncomeDate < co.ChargeOffDate
					THEN lis.ResidualIncome_Amount
					ELSE 0.00
				END AS EarnedResBtwnNACandCh
				, CASE 
					WHEN lis.IsAccounting = 1
						AND lis.IsGLPosted = 1
						AND IsNonAccrual = 1
						AND co.ContractId IS NOT NULL AND ac.NonAccrualId IS NOT NULL
						AND co.ChargeOffDate != ac.NonAccrualDate
						AND lis.IncomeDate >= ac.NonAccrualDate
						AND lis.IncomeDate < co.ChargeOffDate
					THEN lis.FinanceIncome_Amount
					ELSE 0.00
				END AS TotalFinEarnedIncBtwnNACandCh
				, CASE 
					WHEN lis.IsAccounting = 1
						AND lis.IsGLPosted = 1
						AND IsNonAccrual = 1
						AND co.ContractId IS NOT NULL AND ac.NonAccrualId IS NOT NULL
						AND co.ChargeOffDate != ac.NonAccrualDate
						AND lis.IncomeDate >= ac.NonAccrualDate
						AND lis.IncomeDate < co.ChargeOffDate
					THEN lis.FinanceIncome_Amount - lis.FinanceResidualIncome_Amount
					ELSE 0.00
				END AS FinEarnedIncBtwnNACandCh
				, CASE 
					WHEN lis.IsAccounting = 1
						AND lis.IsGLPosted = 1
						AND IsNonAccrual = 1
						AND co.ContractId IS NOT NULL AND ac.NonAccrualId IS NOT NULL
						AND co.ChargeOffDate != ac.NonAccrualDate
						AND lis.IncomeDate >= ac.NonAccrualDate
						AND lis.IncomeDate < co.ChargeOffDate
					THEN lis.FinanceResidualIncome_Amount
					ELSE 0.00
				END AS FinEarnedResBtwnNACandCh
				, CASE 
					WHEN lis.IsAccounting = 1
						AND lis.IsGLPosted = 1
						AND IsNonAccrual = 1
						AND co.ContractId IS NOT NULL AND ac.NonAccrualId IS NOT NULL
						AND co.ChargeOffDate != ac.NonAccrualDate
						AND lis.IncomeDate >= ac.NonAccrualDate
						AND lis.IncomeDate < co.ChargeOffDate
					THEN lis.DeferredSellingProfitIncome_Amount
					ELSE 0.00
				END AS EarnedSPBtwnNACandCh
			FROM #EligibleContracts ec
				INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
				INNER JOIN LeaseIncomeSchedules lis ON lis.LeaseFinanceId = lf.Id
				LEFT JOIN #ChargeOff co ON co.ContractID = ec.ContractId
				LEFT JOIN #AccrualDetails ac ON ac.Contractid = ec.ContractId
				LEFT JOIN #RenewalDetails rl ON rl.Contractid = ec.ContractId				
			WHERE lis.IncomeType = 'FixedTerm'
				AND lis.IsLessorOwned = 1 	
		) LISD
		GROUP BY ContractId;
		
	CREATE NONCLUSTERED INDEX IX_Id ON #LeaseIncomeScheduleDetails(ContractId);

	SELECT
		ec.ContractId
		,SUM(
			CASE
				WHEN bi.SystemConfigType = 'ReAccrualIncome'
				THEN bi.Amount_Amount
				ELSE 0.00
			END) [ReAccrualIncome_BI]
		,SUM(
			CASE
				WHEN bi.SystemConfigType = 'ReAccrualResidualIncome'
				THEN bi.Amount_Amount
				ELSE 0.00
			END) [ReAccrualResidualIncome_BI]
		,SUM(
			CASE
				WHEN bi.SystemConfigType = 'ReAccrualDeferredSellingProfitIncome'
				THEN bi.Amount_Amount
				ELSE 0.00
			END) [ReAccrualDeferredSellingProfitIncome_BI]
		,SUM(
			CASE
				WHEN bi.SystemConfigType = 'ReAccrualFinanceIncome'
				THEN bi.Amount_Amount
				ELSE 0.00
			END) [ReAccrualFinanceIncome_BI]
		,SUM(
			CASE
				WHEN bi.SystemConfigType = 'ReAccrualFinanceResidualIncome'
				THEN bi.Amount_Amount
				ELSE 0.00
			END) [ReAccrualFinanceResidualIncome_BI]
	INTO #BlendedItemInfo
	FROM #EligibleContracts ec
		INNER JOIN #AccrualDetails ac on ac.ContractId = ec.ContractId and ac.ReAccrualId IS NOT NULL
		INNER JOIN LeaseBlendedItems lbi ON lbi.LeaseFinanceId = ec.LeaseFinanceId
		INNER JOIN BlendedItems bi ON lbi.BlendedItemId = bi.Id
	WHERE bi.IsActive = 1
		AND bi.BookRecognitionMode = 'RecognizeImmediately'
	GROUP BY ec.ContractId;

	CREATE NONCLUSTERED INDEX IX_Id ON #BlendedItemInfo(ContractId);

	SELECT
		ac.ContractId
		,SUM(
			CASE
				WHEN bi.SystemConfigType = 'ReAccrualIncome'
					AND bis.IsNonAccrual = 0
				THEN bis.Income_Amount
				ELSE 0.00
			END) [ReAccrualIncome_BIS]
		,SUM(
			CASE
				WHEN bi.SystemConfigType = 'ReAccrualResidualIncome'
					AND bis.IsNonAccrual = 0
				THEN bis.Income_Amount
				ELSE 0.00
			END) [ReAccrualResidualIncome_BIS]
		,SUM(
			CASE
				WHEN bi.SystemConfigType = 'ReAccrualDeferredSellingProfitIncome'
					AND bis.IsNonAccrual = 0
				THEN bis.Income_Amount
				ELSE 0.00
			END) [ReAccrualDeferredSellingProfitIncome_BIS]
		,SUM(
			CASE
				WHEN bi.SystemConfigType = 'ReAccrualFinanceIncome'
					AND bis.IsNonAccrual = 0
				THEN bis.Income_Amount
				ELSE 0.00
			END) [ReAccrualFinanceIncome_BIS]
		,SUM(
			CASE
				WHEN bi.SystemConfigType = 'ReAccrualFinanceResidualIncome'
					AND bis.IsNonAccrual = 0
				THEN bis.Income_Amount
				ELSE 0.00
			END) [ReAccrualFinanceResidualIncome_BIS]
		,SUM(
			CASE
				WHEN bi.SystemConfigType = 'ReAccrualIncome'
					AND bis.IsNonAccrual = 0
					AND bis.PostDate IS NOT NULL
				THEN bis.Income_Amount
				ELSE 0.00
			END) [ReAccrualEarnedIncome_BIS]
		,SUM(
			CASE
				WHEN bi.SystemConfigType = 'ReAccrualResidualIncome'
					AND bis.IsNonAccrual = 0
					AND bis.PostDate IS NOT NULL
				THEN bis.Income_Amount
				ELSE 0.00
			END) [ReAccrualEarnedResidualIncome_BIS]
		,SUM(
			CASE
				WHEN bi.SystemConfigType = 'ReAccrualDeferredSellingProfitIncome'
					AND bis.IsNonAccrual = 0
					AND bis.PostDate IS NOT NULL
				THEN bis.Income_Amount
				ELSE 0.00
			END) [ReAccrualEarnedDeferredSellingProfitIncome_BIS]
		,SUM(
			CASE
				WHEN bi.SystemConfigType = 'ReAccrualFinanceIncome'
					AND bis.IsNonAccrual = 0
					AND bis.PostDate IS NOT NULL
				THEN bis.Income_Amount
				ELSE 0.00
			END) [ReAccrualEarnedFinanceIncome_BIS]
		,SUM(
			CASE
				WHEN bi.SystemConfigType = 'ReAccrualFinanceResidualIncome'
					AND bis.IsNonAccrual = 0
					AND bis.PostDate IS NOT NULL
				THEN bis.Income_Amount
				ELSE 0.00
			END) [ReAccrualEarnedFinanceResidualIncome_BIS]
		,SUM(
			CASE
				WHEN bi.SystemConfigType = 'ReAccrualIncome'
					AND bis.PostDate IS NULL
				THEN bis.Income_Amount
				ELSE 0.00
			END) [ReAccrualUnearnedIncome_BIS]
		,SUM(
			CASE
				WHEN bi.SystemConfigType = 'ReAccrualResidualIncome'
					AND bis.PostDate IS NULL
				THEN bis.Income_Amount
				ELSE 0.00
			END) [ReAccrualUnearnedResidualIncome_BIS]
		,SUM(
			CASE
				WHEN bi.SystemConfigType = 'ReAccrualDeferredSellingProfitIncome'
					AND bis.PostDate IS NULL
				THEN bis.Income_Amount
				ELSE 0.00
			END) [ReAccrualUnearnedDeferredSellingProfitIncome_BIS]
		,SUM(
			CASE
				WHEN bi.SystemConfigType = 'ReAccrualFinanceIncome'
					AND bis.PostDate IS NULL
				THEN bis.Income_Amount
				ELSE 0.00
			END) [ReAccrualUnearnedFinanceIncome_BIS]
		,SUM(
			CASE
				WHEN bi.SystemConfigType = 'ReAccrualFinanceResidualIncome'
					AND bis.PostDate IS NULL
				THEN bis.Income_Amount
				ELSE 0.00
			END) [ReAccrualUnearnedFinanceResidualIncome_BIS]		
	INTO #BlendedIncomeSchInfo
	FROM #AccrualDetails ac
		INNER JOIN LeaseFinances lf ON lf.ContractId = ac.ContractId and ac.ReAccrualId IS NOT NULL
		INNER JOIN BlendedIncomeSchedules bis ON bis.LeaseFinanceId = lf.Id
		INNER JOIN BlendedItems bi ON bis.BlendedItemId = bi.Id
	WHERE bi.IsActive = 1
		AND bis.IsAccounting = 1
		AND bi.BookRecognitionMode != 'RecognizeImmediately'
	GROUP BY ac.ContractId;

	CREATE NONCLUSTERED INDEX IX_Id ON #BlendedIncomeSchInfo(ContractId);

		SELECT
		ec.ContractId
		,SUM(
			CASE
				WHEN wd.IsRecovery = 0
				THEN wd.WriteDownAmount_Amount
				ELSE 0.00
			END) [GrossWriteDown_Table]
		,SUM(
			CASE
				WHEN wd.IsRecovery = 1
				THEN wd.WriteDownAmount_Amount
				ELSE 0.00
			END) [WriteDownRecovered_Table]
	INTO #WriteDownInfo
	FROM #EligibleContracts ec
		INNER JOIN WriteDowns wd ON wd.ContractId = ec.ContractId
	WHERE wd.IsActive = 1
		AND wd.Status = 'Approved'
	GROUP BY ec.ContractId;

	CREATE NONCLUSTERED INDEX IX_Id ON #WriteDownInfo(ContractId);
	
	
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
		FROM #EligibleContracts ec
			 INNER JOIN ChargeOffs co ON co.ContractId = ec.ContractId
		WHERE co.IsActive = 1
			  AND co.Status = ''Approved''
			  AND co.PostDate IS NOT NULL
		GROUP BY ec.ContractId;'
		INSERT INTO #ChargeoffInfo
		EXEC(@SQL)
	END

	IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ChargeOffs' AND COLUMN_NAME = 'LeaseComponentGain_Amount')
	BEGIN
	SET @IsGainPresent = 0
	INSERT INTO #ChargeoffInfo
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
	FROM #EligibleContracts ec
		 INNER JOIN ChargeOffs co ON co.ContractId = ec.ContractId
	WHERE co.IsActive = 1
		  AND co.Status = 'Approved'
		  AND co.PostDate IS NOT NULL
	GROUP BY ec.ContractId;

	MERGE #PaidReceivables pd
	USING
		(SELECT 
			r.EntityId AS ContractId
			,SUM(ISNULL(r.GainAmount_LC, 0.00)) AS OtherGainAmount_LC_Table
			,SUM(ISNULL(r.GainAmount_NLC, 0.00)) AS OtherGainAmount_NLC_Table
		FROM #ReceiptApplicationReceivableDetails r
			  LEFT JOIN #ChargeOff cod ON cod.ContractId = r.EntityId
		WHERE r.ReceiptStatus IN ('Completed','Posted')
			  AND r.ReceivableType NOT IN ('CapitalLeaseRental') 
		GROUP BY r.EntityId) sr
	ON (sr.ContractId = pd.ContractId)
	WHEN MATCHED
	THEN UPDATE
		SET ChargeOffGainOnRecovery_LeaseComponent_Table += sr.OtherGainAmount_LC_Table +  sr.OtherGainAmount_NLC_Table
	WHEN NOT MATCHED
		THEN
			INSERT(ContractId,[PaidReceivables_LeaseComponent_Table], [PaidReceivablesviaCash_LeaseComponent_Table], [PaidReceivablesviaNonCash_LeaseComponent_Table],
				   [PaidReceivables_FinanceComponent_Table], [PaidReceivablesviaCash_FinanceComponent_Table], [PaidReceivablesviaNonCash_FinanceComponent_Table],
				   [Recovery_LeaseComponent_Table], [Recovery_NonLeaseComponent_Table], [GLPosted_PreChargeoff_LeaseComponent_Table], [GlPosted_PreChargeoff_NonLeaseComponent_Table], [ChargeOffGainOnRecovery_LeaseComponent_Table], [ChargeOffGainOnRecovery_NonLeaseComponent_Table])
			VALUES(sr.ContractId, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, sr.OtherGainAmount_LC_Table +  sr.OtherGainAmount_NLC_Table, 0.00);
	
	UPDATE sord SET ChargeOffGainOnRecovery_LeaseComponent_Table += ChargeOffGainOnRecovery_NonLeaseComponent_Table
				  , ChargeOffGainOnRecovery_NonLeaseComponent_Table = 0.00
	FROM #PaidReceivables sord
	WHERE ChargeOffGainOnRecovery_NonLeaseComponent_Table != 0.00
	
	END

	CREATE NONCLUSTERED INDEX IX_Id ON #ChargeOffInfo(ContractId);
	
	SELECT
		ec.ContractId
		,SUM(r.Balance_Amount) [ReceiptBalance_Amount]
	INTO #SumOfReceipts
	FROM #EligibleContracts ec
		INNER JOIN Receipts r ON r.ContractId = ec.ContractId
		INNER JOIN ReceiptAllocations ra ON ra.ReceiptId = r.Id
	WHERE r.Status = 'Posted'
		AND ra.IsActive = 1
	GROUP BY ec.ContractId;

	CREATE NONCLUSTERED INDEX IX_Id ON #SumOfReceipts(ContractId);

	SELECT
		ec.ContractId
		,SUM(p.Balance_Amount) [PayablesBalance_Amount]
	INTO #SumOfPayables
	FROM #EligibleContracts ec
		INNER JOIN Receipts r ON r.ContractId = ec.ContractId
		INNER JOIN Payables p ON p.SourceId = r.Id
			AND p.SourceTable = 'Receipt'
		INNER JOIN UnallocatedRefunds uar ON uar.Id = p.EntityId
			AND p.EntityType = 'RR'
			AND uar.Status != 'Reversed'
	WHERE p.Status != 'Inactive'
	GROUP BY ec.ContractId;

	CREATE NONCLUSTERED INDEX IX_Id ON #SumOfPayables(ContractId);

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ReceivableTaxes' AND COLUMN_NAME = 'IsCashBased')
BEGIN
SET @SQL =
	'SELECT #EligibleContracts.ContractId
	,	SUM(CASE 
				WHEN ReceivableTaxes.IsCashBased = 1
					AND Receipt.ReceiptClassification = ''NonCash''
				THEN ReceiptApplicationReceivableDetails.TaxApplied_Amount
				ELSE 0.00
			END) GLPosted_CashRem_NonCash
	,	SUM(ReceiptApplicationReceivableDetails.TaxApplied_Amount) TotalPaid_taxes
	,	SUM(CASE 
				WHEN ReceivableTaxes.IsCashBased = 1
					AND Receipt.ReceiptClassification = ''NonCash''
				THEN ReceiptApplicationReceivableDetails.TaxApplied_Amount
				ELSE 0.00
			END) Paid_CashRem_NonCash
	,	SUM(CASE
				WHEN ReceivableTaxes.IsGLPosted = 0
				THEN ReceiptApplicationReceivableDetails.TaxApplied_Amount
				ELSE 0.00
			END) TotalPrePaid_Taxes
	,	SUM(CASE
				WHEN Receipt.ReceiptClassification = ''Cash''
					AND ReceiptTypes.ReceiptTypeName NOT IN (''PayableOffset'', ''SecurityDeposit'', ''EscrowRefund'')
				THEN ReceiptApplicationReceivableDetails.TaxApplied_Amount
				ELSE 0.00
			END) PaidTaxesviaCash
	,	SUM(CASE
				WHEN Receipt.ReceiptClassification NOT IN (''Cash'')
					OR ReceiptTypes.ReceiptTypeName IN (''PayableOffset'', ''SecurityDeposit'', ''EscrowRefund'')
				THEN ReceiptApplicationReceivableDetails.TaxApplied_Amount
				ELSE 0.00
			END) PaidTaxesviaNonCash
	From #EligibleContracts
	INNER JOIN #ReceivableForTaxes Receivables on #EligibleContracts.Contractid = Receivables.EntityID
	INNER JOIN ReceivableTaxes on ReceivableTaxes.ReceivableId = Receivables.Id and ReceivableTaxes.IsActive = 1
	INNER JOIN ReceivableDetails on ReceivableDetails.ReceivableId = ReceivableTaxes.ReceivableId and ReceivableDetails.IsActive = 1
	INNER JOIN ReceiptApplicationReceivableDetails on ReceiptApplicationReceivableDetails.ReceivableDetailId = ReceivableDetails.Id
	INNER JOIN ReceiptApplications on ReceiptApplicationReceivableDetails.ReceiptApplicationId = ReceiptApplications.Id
	INNER JOIN Receipts Receipt on ReceiptApplications.ReceiptId = Receipt.Id
				AND Receipt.Status in (''Completed'',''Posted'')
	INNER JOIN ReceiptTypes on ReceiptTypes.Id = Receipt.Typeid
	WHERE ReceiptApplicationReceivableDetails.IsActive=1 
	GROUP BY #EligibleContracts.ContractId'

	INSERT INTO #SalesTaxDetails
	EXEC (@Sql)
END
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ReceivableTaxes' AND COLUMN_NAME = 'IsCashBased')
BEGIN
INSERT INTO #SalesTaxDetails
SELECT #EligibleContracts.ContractId
	,	0 AS GLPosted_CashRem_NonCash
	,	SUM(ReceiptApplicationReceivableDetails.TaxApplied_Amount) TotalPaid_taxes
	,	0 AS Paid_CashRem_NonCash
	,	SUM(CASE
				WHEN ReceivableTaxes.IsGLPosted = 0
				THEN ReceiptApplicationReceivableDetails.TaxApplied_Amount
				ELSE 0.00
			END) TotalPrePaid_Taxes
	,	SUM(CASE
				WHEN Receipt.ReceiptClassification = 'Cash'
					AND ReceiptTypes.ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund')
				THEN ReceiptApplicationReceivableDetails.TaxApplied_Amount
				ELSE 0.00
			END) PaidTaxesviaCash
	,	SUM(CASE
				WHEN Receipt.ReceiptClassification NOT IN ('Cash')
					OR ReceiptTypes.ReceiptTypeName IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund')
				THEN ReceiptApplicationReceivableDetails.TaxApplied_Amount
				ELSE 0.00
			END) PaidTaxesviaNonCash
	From #EligibleContracts
	INNER JOIN #ReceivableForTaxes Receivables on #EligibleContracts.Contractid = Receivables.EntityID
	INNER JOIN ReceivableTaxes on ReceivableTaxes.ReceivableId = Receivables.Id and ReceivableTaxes.IsActive = 1
	INNER JOIN ReceivableDetails on ReceivableDetails.ReceivableId = ReceivableTaxes.ReceivableId and ReceivableDetails.IsActive = 1
	INNER JOIN ReceiptApplicationReceivableDetails on ReceiptApplicationReceivableDetails.ReceivableDetailId = ReceivableDetails.Id
	INNER JOIN ReceiptApplications on ReceiptApplicationReceivableDetails.ReceiptApplicationId = ReceiptApplications.Id
	INNER JOIN Receipts Receipt on ReceiptApplications.ReceiptId = Receipt.Id
				AND Receipt.Status in ('Completed','Posted')
	INNER JOIN ReceiptTypes on ReceiptTypes.Id = Receipt.Typeid
	WHERE ReceiptApplicationReceivableDetails.IsActive=1 
	GROUP BY #EligibleContracts.ContractId

END

	SELECT #EligibleContracts.ContractId
	,	SUM(CASE
				WHEN ReceivableTaxes.IsGLPosted = 1
				THEN ReceivableTaxes.Amount_Amount
				ELSE 0.00
			END) GLPostedTaxes
	,	SUM(CASE
				WHEN ReceivableTaxes.IsGLPosted = 1
				THEN ReceivableTaxes.Balance_Amount
				ELSE 0.00
			END) OutStandingTaxes
	INTO #ReceivableTaxDetails
	From #EligibleContracts
	INNER JOIN #ReceivableForTaxes Receivables on #EligibleContracts.Contractid = Receivables.EntityID
	INNER JOIN ReceivableTaxes on ReceivableTaxes.ReceivableId = Receivables.Id and ReceivableTaxes.IsActive = 1
	GROUP BY #EligibleContracts.ContractId

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'LeaseAssets' AND COLUMN_NAME = 'CapitalizedAdditionalCharge_Amount')
BEGIN
SET @Sql = 
	'SELECT #EligibleContracts.ContractId
	,	SUM(CASE
				WHEN la.IsAdditionalChargeSoftAsset = 1
				THEN la.NBV_Amount
				ELSE la.CapitalizedAdditionalCharge_Amount
			END) CapitalizedAdditionalCharge
	, SUM(CASE 
			WHEN lfd.CreateSoftAssetsForCappedSalesTax = 1 
			THEN la.OriginalCapitalizedAmount_Amount
			ELSE la.CapitalizedSalesTax_Amount
		  END) CapitalizedSalesTax
	, SUM(CASE 
			WHEN lfd.CreateSoftAssetsForInterimInterest = 1
			THEN la.OriginalCapitalizedAmount_Amount
			ELSE la.CapitalizedInterimInterest_Amount
		   END) CapitalizedInterimInterest
	, SUM(CASE
			WHEN lfd.CreateSoftAssetsForInterimRent = 1
			THEN la.OriginalCapitalizedAmount_Amount
			ELSE la.CapitalizedInterimRent_Amount
		  END) CapitalizedInterimRent
	, SUM(CASE
			WHEN la.CapitalizationType = ''CapitalizedProgressPayment''
			THEN la.OriginalCapitalizedAmount_Amount
			ELSE 0.00
		 END) CapitalizedProgressPayment
	FROM #EligibleContracts
		INNER JOIN LeaseFinanceDetails lfd ON lfd.Id = #EligibleContracts.LeaseFinanceID
		INNER JOIN LeaseAssets la ON la.LeaseFinanceId = #EligibleContracts.LeaseFinanceId
						AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL 
							AND la.TerminationDate >= #EligibleContracts.CommencementDate))
						GROUP BY #EligibleContracts.ContractId;'

INSERT INTO #CapitalizedDetails
EXEC (@Sql)
END

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'LeaseAssets' AND COLUMN_NAME = 'CapitalizedAdditionalCharge_Amount')
BEGIN
 INSERT INTO #CapitalizedDetails
 SELECT #EligibleContracts.ContractId
	, 0 CapitalizedAdditionalCharge
	, SUM(CASE 
			WHEN lfd.CreateSoftAssetsForCappedSalesTax = 1 
			THEN la.OriginalCapitalizedAmount_Amount
			ELSE la.CapitalizedSalesTax_Amount
		  END) CapitalizedSalesTax
	, SUM(CASE 
			WHEN lfd.CreateSoftAssetsForInterimInterest = 1
			THEN la.OriginalCapitalizedAmount_Amount
			ELSE la.CapitalizedInterimInterest_Amount
		   END) CapitalizedInterimInterest
	, SUM(CASE
			WHEN lfd.CreateSoftAssetsForInterimRent = 1
			THEN la.OriginalCapitalizedAmount_Amount
			ELSE la.CapitalizedInterimRent_Amount
		  END) CapitalizedInterimRent
	, SUM(CASE
			WHEN la.CapitalizationType = 'CapitalizedProgressPayment'
			THEN la.OriginalCapitalizedAmount_Amount
			ELSE 0.00
		 END) CapitalizedProgressPayment
	FROM #EligibleContracts
		INNER JOIN LeaseFinanceDetails lfd ON lfd.Id = #EligibleContracts.LeaseFinanceID
		INNER JOIN LeaseAssets la ON la.LeaseFinanceId = #EligibleContracts.LeaseFinanceId
						AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL
							AND la.TerminationDate >= #EligibleContracts.CommencementDate))
						GROUP BY #EligibleContracts.ContractId;
END

UPDATE cd
	SET cd.CapitalizedInterimInterest = cd.CapitalizedInterimInterest + cd.CapitalizedProgressPayment
FROM #CapitalizedDetails cd;

	 UPDATE ar
		 SET
			ar.BookedResidual_FinanceAssets -= ar.BookedResidual_FinanceAssets
		 ,	ar.BookedResidual_LeaseAssets -= ar.BookedResidual_LeaseAssets
		 ,	ar.CustomerGuaranteedResidual_LeaseAssets -= ar.CustomerGuaranteedResidual_LeaseAssets
		 ,	ar.CustomerGuaranteedResidual_FinanceAssets -= ar.CustomerGuaranteedResidual_FinanceAssets
		 ,	ar.ThirdPartyGuaranteedResidual_LeaseAssets -= ar.ThirdPartyGuaranteedResidual_LeaseAssets
		 ,	ar.ThirdPartyGuaranteedResidual_FinanceAssets -= ar.ThirdPartyGuaranteedResidual_FinanceAssets
		 FROM #AssetResiduals ar
		 INNER JOIN #OTPReclass oc on oc.ContractId = ar.ContractId

	MERGE #AssetResiduals AS AssetResiduals
		USING (SELECT * FROM #OTPPaidResiduals) AS OTPResiduals
		ON (AssetResiduals.ContractId = OTPResiduals.ContractId)
		WHEN MATCHED THEN
			UPDATE SET BookedResidual_LeaseAssets += OTPResiduals.BookedResidual_LeaseAssets,
					  CustomerGuaranteedResidual_LeaseAssets += OTPResiduals.CustomerGuaranteedResidual_LeaseAssets,
					  ThirdPartyGuaranteedResidual_LeaseAssets += OTPResiduals.ThirdPartyGuaranteedResidual_LeaseAssets,
					  BookedResidual_FinanceAssets += OTPResiduals.BookedResidual_FinanceAssets,
					  CustomerGuaranteedResidual_FinanceAssets += OTPResiduals.CustomerGuaranteedResidual_FinanceAssets,
					  ThirdPartyGuaranteedResidual_FinanceAssets += OTPResiduals.ThirdPartyGuaranteedResidual_FinanceAssets
		WHEN NOT MATCHED THEN
			INSERT (ContractId, BookedResidual_LeaseAssets,CustomerGuaranteedResidual_LeaseAssets,ThirdPartyGuaranteedResidual_LeaseAssets
			,BookedResidual_FinanceAssets,CustomerGuaranteedResidual_FinanceAssets,ThirdPartyGuaranteedResidual_FinanceAssets)
			VALUES (OTPResiduals.ContractId,OTPResiduals.BookedResidual_LeaseAssets,OTPResiduals.CustomerGuaranteedResidual_LeaseAssets
			,OTPResiduals.ThirdPartyGuaranteedResidual_LeaseAssets,OTPResiduals.BookedResidual_FinanceAssets
			,OTPResiduals.CustomerGuaranteedResidual_FinanceAssets,OTPResiduals.ThirdPartyGuaranteedResidual_FinanceAssets);

	UPDATE lis
		SET 
			lis.TotalIncome_Accounting = lis.TotalIncome_Accounting + bi.ReAccrualIncome_BI + bi.ReAccrualResidualIncome_BI
		,	lis.TotalSellingProfitIncome_Accounting = lis.TotalSellingProfitIncome_Accounting + bi.ReAccrualDeferredSellingProfitIncome_BI
		,	lis.TotalIncome_Schedule = lis.TotalIncome_Schedule + bi.ReAccrualIncome_BI + bi.ReAccrualResidualIncome_BI
		,	lis.TotalSellingProfitIncome_Schedule = lis.TotalSellingProfitIncome_Schedule + bi.ReAccrualDeferredSellingProfitIncome_BI
		,	lis.TotalEarnedIncome = lis.TotalEarnedIncome + bi.ReAccrualIncome_BI + bi.ReAccrualResidualIncome_BI
		,	lis.EarnedIncome = lis.EarnedIncome + bi.ReAccrualIncome_BI
		,	lis.EarnedResidualIncome = lis.EarnedResidualIncome + bi.ReAccrualResidualIncome_BI
		,	lis.EarnedSellingProfitIncome = lis.EarnedSellingProfitIncome + bi.ReAccrualDeferredSellingProfitIncome_BI
		,	lis.Finance_TotalIncome_Accounting = lis.Finance_TotalIncome_Accounting + bi.ReAccrualFinanceIncome_BI
		,	lis.Finance_TotalIncome_Schedule = lis.Finance_TotalIncome_Schedule + bi.ReAccrualFinanceIncome_BI
		,	lis.Financing_TotalEarnedIncome = lis.Financing_TotalEarnedIncome + bi.ReAccrualFinanceIncome_BI + bi.ReAccrualFinanceResidualIncome_BI
		,	lis.Financing_EarnedIncome = lis.Financing_EarnedIncome + bi.ReAccrualFinanceIncome_BI
		,	lis.Financing_EarnedResidualIncome = lis.Financing_EarnedResidualIncome + bi.ReAccrualFinanceResidualIncome_BI
	FROM #LeaseIncomeScheduleDetails lis
	INNER JOIN #BlendedItemInfo bi on lis.ContractId = bi.ContractId;

	UPDATE lis
	SET 
			lis.TotalIncome_Accounting = lis.TotalIncome_Accounting + bis.ReAccrualIncome_BIS + bis.ReAccrualResidualIncome_BIS
		,	lis.TotalSellingProfitIncome_Accounting = lis.TotalSellingProfitIncome_Accounting + bis.ReAccrualDeferredSellingProfitIncome_BIS
		,	lis.TotalIncome_Schedule = lis.TotalIncome_Schedule + bis.ReAccrualIncome_BIS + bis.ReAccrualResidualIncome_BIS
		,	lis.TotalSellingProfitIncome_Schedule = lis.TotalSellingProfitIncome_Schedule + bis.ReAccrualDeferredSellingProfitIncome_BIS
		,	lis.TotalEarnedIncome = lis.TotalEarnedIncome + bis.ReAccrualEarnedResidualIncome_BIS + bis.ReAccrualEarnedIncome_BIS
		,	lis.EarnedIncome = lis.EarnedIncome + bis.ReAccrualEarnedIncome_BIS
		,	lis.EarnedResidualIncome = lis.EarnedResidualIncome + bis.ReAccrualEarnedResidualIncome_BIS
		,	lis.EarnedSellingProfitIncome = lis.EarnedSellingProfitIncome + bis.ReAccrualEarnedDeferredSellingProfitIncome_BIS
		,	lis.Finance_TotalIncome_Accounting = lis.Finance_TotalIncome_Accounting + bis.ReAccrualFinanceIncome_BIS
		,	lis.Finance_TotalIncome_Schedule = lis.Finance_TotalIncome_Schedule + bis.ReAccrualFinanceIncome_BIS
		,	lis.Financing_TotalEarnedIncome = lis.Financing_TotalEarnedIncome + bis.ReAccrualEarnedFinanceIncome_BIS + bis.ReAccrualEarnedResidualIncome_BIS
		,	lis.Financing_EarnedIncome = lis.Financing_EarnedIncome + bis.ReAccrualEarnedFinanceIncome_BIS
		,	lis.Financing_EarnedResidualIncome = lis.Financing_EarnedResidualIncome + bis.ReAccrualEarnedResidualIncome_BIS
		,	lis.TotalUnearnedIncome = lis.TotalUnearnedIncome + bis.ReAccrualUnearnedIncome_BIS + bis.ReAccrualUnearnedResidualIncome_BIS
		,	lis.UnearnedSellingProfitIncome = lis.UnearnedSellingProfitIncome + bis.ReAccrualUnearnedDeferredSellingProfitIncome_BIS
		,	lis.UnearnedIncome = lis.UnearnedIncome + bis.ReAccrualUnearnedIncome_BIS
		,	lis.UnearnedResidualIncome = lis.UnearnedResidualIncome + bis.ReAccrualUnearnedResidualIncome_BIS
		,	lis.Financing_UnearnedIncome = lis.Financing_UnearnedIncome + bis.ReAccrualUnearnedFinanceIncome_BIS
		,	lis.Financing_UnearnedResidualIncome = lis.Financing_UnearnedResidualIncome + bis.ReAccrualUnearnedFinanceResidualIncome_BIS
		,	lis.Financing_TotalUnearnedIncome = lis.Financing_TotalUnearnedIncome + bis.ReAccrualUnearnedFinanceIncome_BIS + bis.ReAccrualUnearnedFinanceResidualIncome_BIS
	FROM #LeaseIncomeScheduleDetails lis
	INNER JOIN #BlendedIncomeSchInfo bis on lis.ContractId = bis.ContractId;
	
	/*Interim*/
	SELECT
		ec.ContractId
		,r.Id
		,r.DueDate
		,r.IsGLPosted
		,r.TotalAmount_Amount
		,r.TotalBalance_Amount
		,rt.Name AS ReceivableTypeName
	INTO #InterimReceivableInfo
	FROM #EligibleContracts ec
		INNER JOIN Receivables r ON r.EntityId = ec.ContractId
		INNER JOIN ReceivableCodes rc ON r.ReceivableCodeId = rc.Id
		INNER JOIN ReceivableTypes rt ON rc.ReceivableTypeId = rt.Id
		LEFT JOIN #RenewalDetails rn ON rn.ContractId = ec.ContractId
	WHERE r.IsActive = 1
		AND r.EntityType = 'CT'
		AND rt.Name IN ('InterimRental','LeaseInterimInterest')
		AND rn.ContractId IS NULL;
	
	CREATE NONCLUSTERED INDEX IX_Id ON #InterimReceivableInfo(ContractId);

	SELECT
		#EligibleContracts.ContractId
		,SUM(CASE WHEN @DeferInterimInterestIncomeRecognition = 'False'
				AND lfd.InterimInterestBillingType = 'Capitalize'
			THEN la.CapitalizedInterimInterest_Amount
			ELSE 0.00
			END) CapitalizedInterimInterest
		,SUM(CASE WHEN @DeferInterimRentIncomeRecognition = 'False'
				AND lfd.InterimRentBillingType = 'Capitalize'
			THEN la.CapitalizedInterimRent_Amount
			ELSE 0.00
			END) CapitalizedInterimRent
	INTO #CapitalizeInterimAmount
	FROM #EligibleContracts
		INNER JOIN LeaseFinanceDetails lfd ON lfd.Id = #EligibleContracts.LeaseFinanceId
		INNER JOIN LeaseAssets la ON la.LeaseFinanceId = #EligibleContracts.LeaseFinanceId
	GROUP BY #EligibleContracts.ContractId;
	
	CREATE NONCLUSTERED INDEX IX_Id ON #CapitalizeInterimAmount(ContractId);

	SELECT
		ec.ContractId
		,SUM(
			CASE 
				WHEN r.ReceivableTypeName = 'InterimRental'
				THEN r.TotalAmount_Amount
				ELSE 0.00
			END) [TotalInterimRentAmount]
		,SUM(
			CASE
				WHEN r.ReceivableTypeName = 'InterimRental'
				THEN r.TotalBalance_Amount
				ELSE 0.00
			END) [TotalInterimRentBalanceAmount]
		,SUM(
			CASE
				WHEN r.ReceivableTypeName = 'InterimRental' AND r.IsGLPosted = 1
				THEN r.TotalAmount_Amount
				ELSE 0.00
			END) [TotalGLPosted_InterimRentReceivables_Table]
		,SUM(
			CASE
				WHEN r.ReceivableTypeName = 'InterimRental' AND r.IsGLPosted = 1
				THEN r.TotalBalance_Amount
				ELSE 0.00
			END) [TotalOutstandingInterimRentReceivables_Table]
		,SUM(
			CASE 
				WHEN r.ReceivableTypeName = 'LeaseInterimInterest'
				THEN r.TotalAmount_Amount
				ELSE 0.00
			END) [TotalInterimInterestAmount]
		,SUM(
			CASE
				WHEN r.ReceivableTypeName = 'LeaseInterimInterest'
				THEN r.TotalBalance_Amount
				ELSE 0.00
			END) [TotalInterimInterestBalanceAmount]
		,SUM(
			CASE
				WHEN r.ReceivableTypeName = 'LeaseInterimInterest' AND r.IsGLPosted = 1
				THEN r.TotalAmount_Amount
				ELSE 0.00
			END) [TotalGLPosted_InterimInterestReceivables_Table]
		,SUM(
			CASE
				WHEN r.ReceivableTypeName = 'LeaseInterimInterest' AND r.IsGLPosted = 1
				THEN r.TotalBalance_Amount
				ELSE 0.00
			END) [TotalOutstandingInterimInterestReceivables_Table]
	INTO #SumOfInterimReceivables
	FROM #EligibleContracts ec
		INNER JOIN #InterimReceivableInfo r ON r.ContractId = ec.ContractId
	GROUP BY ec.ContractId;
	
	CREATE NONCLUSTERED INDEX IX_Id ON #SumOfInterimReceivables(ContractId);

	DECLARE @IsRentSharing BIT = 0
	IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'RentSharingDetails')
	BEGIN
		SET @IsRentSharing = 1;
	END

	IF @IsRentSharing = 1
	BEGIN
		SET @Sql = 
		'SELECT
			ec.ContractId
			,SUM(r.TotalAmount_Amount) [VendorInterimRentSharingAmount]
			,SUM(
				CASE
					WHEN r.IsGLPosted = 1
					THEN r.TotalAmount_Amount
					ELSE 0.00
				END) [GLPostedVendorInterimRentSharingAmount]
		FROM #EligibleContracts ec
			INNER JOIN #InterimReceivableInfo r ON r.ContractId = ec.ContractId
			INNER JOIN RentSharingDetails rs ON rs.ReceivableId = r.Id
				AND rs.SourceType = ''Interim''
		GROUP BY ec.ContractId';
			
		INSERT INTO #SumOfVendorRentSharing
		EXEC (@Sql)
	END

	CREATE NONCLUSTERED INDEX IX_Id ON #SumOfVendorRentSharing(ContractId);
	
	SELECT
		ec.ContractId
		,SUM(
			CASE
				WHEN r.ReceivableTypeName = 'InterimRental' 
					AND rp.ReceiptClassification = 'Cash'
					AND rpt.ReceiptTypeName NOT IN ('PayableOffset','SecurityDeposit','EscrowRefund')
				THEN rard.AmountApplied_Amount
				ELSE 0.00
			END) [TotalPaidviaCash_InterimRentReceivables_Table]
		,SUM(
			CASE
				WHEN r.ReceivableTypeName = 'InterimRental' 
					AND (rp.ReceiptClassification = 'NonCash'
					OR (rp.ReceiptClassification = 'Cash' AND rpt.ReceiptTypeName IN ('PayableOffset','SecurityDeposit','EscrowRefund')))
				THEN rard.AmountApplied_Amount
				ELSE 0.00
			END) [TotalPaidviaNonCash_InterimRentReceivables_Table]
		,SUM(
			CASE
				WHEN r.ReceivableTypeName = 'LeaseInterimInterest' 
					AND rp.ReceiptClassification = 'Cash'
					AND rpt.ReceiptTypeName NOT IN ('PayableOffset','SecurityDeposit','EscrowRefund')
				THEN rard.AmountApplied_Amount
				ELSE 0.00
			END) [TotalPaidviaCash_InterimInterestReceivables_Table]
		,SUM(
			CASE
				WHEN r.ReceivableTypeName = 'LeaseInterimInterest' 
					AND (rp.ReceiptClassification = 'NonCash'
					OR (rp.ReceiptClassification = 'Cash' AND rpt.ReceiptTypeName IN ('PayableOffset','SecurityDeposit','EscrowRefund')))
				THEN rard.AmountApplied_Amount
				ELSE 0.00
			END) [TotalPaidviaNonCash_InterimInterestReceivables_Table]
	INTO #SumOfInterimReceiptApplicationReceivableDetails
	FROM #EligibleContracts ec
		INNER JOIN #InterimReceivableInfo r ON r.ContractId = ec.ContractId
		INNER JOIN ReceivableDetails rd ON rd.ReceivableId = r.Id
		INNER JOIN ReceiptApplicationReceivableDetails rard ON rard.ReceivableDetailId = rd.Id
		INNER JOIN ReceiptApplications ra ON rard.ReceiptApplicationId = ra.Id
		INNER JOIN Receipts rp ON ra.ReceiptId = rp.Id
		INNER JOIN ReceiptTypes rpt ON rp.TypeId = rpt.Id
	WHERE rd.IsActive = 1
		AND rard.IsActive = 1
		AND rp.Status IN ('Completed','Posted')
	GROUP BY ec.ContractId;
	
	CREATE NONCLUSTERED INDEX IX_Id ON #SumOfInterimReceiptApplicationReceivableDetails(ContractId);

	SELECT
		ec.ContractId
		,SUM(
			CASE
				WHEN r.ReceivableTypeName = 'InterimRental'
				THEN pr.PrePaidAmount_Amount
				ELSE 0.00
			END) [TotalPrepaid_InterimRentReceivables_Table]
		,SUM(
			CASE
				WHEN r.ReceivableTypeName = 'LeaseInterimInterest'
				THEN pr.PrePaidAmount_Amount
				ELSE 0.00
			END) [TotalPrepaid_InterimInterestReceivables_Table]
	INTO #SumOfPrepaidInterimReceivables
	FROM #EligibleContracts ec
		INNER JOIN #InterimReceivableInfo r ON r.ContractId = ec.ContractId
		INNER JOIN PrepaidReceivables pr ON pr.ReceivableId = r.Id
	WHERE r.IsGLPosted = 0
		AND pr.IsActive = 1
	GROUP BY ec.ContractId;
	
	CREATE NONCLUSTERED INDEX IX_Id ON #SumOfPrepaidInterimReceivables(ContractId);

	SELECT
		ec.ContractId
		,SUM(
			CASE
				WHEN lis.IncomeType = 'InterimRent'
					AND lis.IsSchedule = 1
				THEN lis.RentalIncome_Amount
				ELSE 0.00
			END) [TotalScheduleRentalIncome_InterimRentIncome_Table]
		,SUM(
			CASE
				WHEN lis.IncomeType = 'InterimRent'
					AND lis.IsAccounting = 1
				THEN lis.RentalIncome_Amount
				ELSE 0.00
			END) [TotalAccountingRentalIncome_InterimRentIncome_Table]
		,SUM(
			CASE
				WHEN lis.IncomeType = 'InterimRent'
					AND lis.IsAccounting = 1
					AND lis.IsGLPosted = 1
					AND @DeferInterimRentIncomeRecognition = 'False'
					AND ((ec.InterimRentBillingType = 'Periodic')
						OR (ec.InterimRentBillingType = 'SingleInstallment' 
							AND @DeferInterimRentIncomeRecognitionForSingleInstallment = 'False'))
				THEN lis.RentalIncome_Amount
				ELSE 0.00
			END) [GLPosted_InterimRentIncome_Table]
		,SUM(
			CASE
				WHEN lis.IncomeType = 'InterimRent'
					AND lis.IsAccounting = 1
					AND ec.InterimRentBillingType = 'Capitalize'
					AND @DeferInterimRentIncomeRecognition = 'False'
				THEN lis.RentalIncome_Amount
				ELSE 0.00
			END) [TotalCapitalizedIncome_InterimRentIncome_Table]
		,SUM(
			CASE
				WHEN lis.IncomeType = 'InterimRent'
					AND lis.IsSchedule = 1
					AND lis.IsGLPosted = 1
					AND ec.InterimRentBillingType = 'Capitalize'
					AND @DeferInterimRentIncomeRecognition = 'False'
				THEN lis.RentalIncome_Amount
				ELSE 0.00
			END) [DeferCapitalizedIncome_InterimRentIncome_Table]
		,SUM(
			CASE
				WHEN lis.IncomeType = 'InterimInterest'
					AND lis.IsSchedule = 1
				THEN lis.Income_Amount
				ELSE 0.00
			END) [TotalScheduleIncome_InterimInterestIncome_Table]
		,SUM(
			CASE
				WHEN lis.IncomeType = 'InterimInterest'
					AND lis.IsAccounting = 1
				THEN lis.Income_Amount
				ELSE 0.00
			END) [TotalAccountingIncome_InterimInterestIncome_Table]
		,SUM(
			CASE
				WHEN lis.IncomeType = 'InterimInterest'
					AND lis.IsAccounting = 1
					AND lis.IsGLPosted = 1
					AND @DeferInterimInterestIncomeRecognition = 'False'
					AND ((ec.InterimInterestBillingType = 'Periodic')
						OR (ec.InterimInterestBillingType = 'SingleInstallment' 
							AND @DeferInterimInterestIncomeRecognitionForSingleInstallment = 'False'))
				THEN lis.Income_Amount
				ELSE 0.00
			END) [GLPosted_InterimInterestIncome_Table]
		,SUM(
			CASE
				WHEN lis.IncomeType = 'InterimInterest'
					AND lis.IsAccounting = 1
					AND ec.InterimInterestBillingType = 'Capitalize'
					AND @DeferInterimInterestIncomeRecognition = 'False'
				THEN lis.Income_Amount
				ELSE 0.00
			END) [TotalCapitalizedIncome_InterimInterestIncome_Table]
		,SUM(
			CASE
				WHEN lis.IncomeType = 'InterimInterest'
					AND lis.IsSchedule = 1
					AND lis.IsGLPosted = 1
					AND ec.InterimInterestBillingType = 'Capitalize'
					AND @DeferInterimInterestIncomeRecognition = 'False'
				THEN lis.Income_Amount
				ELSE 0.00
			END) [AccruedCapitalizedIncome_InterimInterestIncome_Table]
	INTO #InterimLeaseIncomeSchInfo
	FROM #EligibleContracts ec
		INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
		INNER JOIN LeaseIncomeSchedules lis ON lis.LeaseFinanceId = lf.Id
		LEFT JOIN #RenewalDetails rn ON rn.ContractId = ec.ContractId
	WHERE lis.IsLessorOwned = 1
		AND lis.IncomeType IN ('InterimRent','InterimInterest')
		AND rn.ContractId IS NULL
	GROUP BY ec.ContractId;
	
	CREATE NONCLUSTERED INDEX IX_Id ON #InterimLeaseIncomeSchInfo(ContractId);

	SELECT
		ec.ContractId
		,CASE
			WHEN (ec.InterimRentBillingType = 'Periodic' AND @DeferInterimRentIncomeRecognition = 'True')
				OR ((ec.InterimRentBillingType = 'SingleInstallment')
					AND (@DeferInterimRentIncomeRecognition = 'True' OR @DeferInterimRentIncomeRecognitionForSingleInstallment = 'True'))
			THEN ISNULL(ilis.TotalScheduleRentalIncome_InterimRentIncome_Table,0.00) - (ISNULL(soir.TotalGLPosted_InterimRentReceivables_Table,0.00) - ISNULL(sovrs.GLPostedVendorInterimRentSharingAmount,0.00))
			WHEN (ec.InterimRentBillingType = 'Periodic' AND @DeferInterimRentIncomeRecognition = 'False')
				OR ((ec.InterimRentBillingType = 'SingleInstallment')
					AND (@DeferInterimRentIncomeRecognition = 'False' AND @DeferInterimRentIncomeRecognitionForSingleInstallment = 'False'))
			THEN (ISNULL(soir.TotalGLPosted_InterimRentReceivables_Table,0.00) - ISNULL(sovrs.GLPostedVendorInterimRentSharingAmount,0.00)) - ISNULL(ilis.GLPosted_InterimRentIncome_Table,0.00)
			WHEN (ec.InterimRentBillingType = 'Capitalize' AND @DeferInterimRentIncomeRecognition = 'False')
			THEN ISNULL(cia.CapitalizedInterimRent,0.00) - ISNULL(ilis.DeferCapitalizedIncome_InterimRentIncome_Table,0.00)
			ELSE 0.00
		END [DeferInterimRentIncome_Table]
		,CASE
			WHEN (ec.InterimInterestBillingType = 'Periodic' AND @DeferInterimInterestIncomeRecognition = 'True')
				OR ((ec.InterimInterestBillingType = 'SingleInstallment')
					AND (@DeferInterimInterestIncomeRecognition = 'True' OR @DeferInterimInterestIncomeRecognitionForSingleInstallment = 'True'))
			THEN ISNULL(ilis.TotalScheduleIncome_InterimInterestIncome_Table,0.00) - ISNULL(soir.TotalGLPosted_InterimInterestReceivables_Table,0.00)
			WHEN (ec.InterimInterestBillingType = 'Periodic' AND @DeferInterimInterestIncomeRecognition = 'False')
				OR ((ec.InterimInterestBillingType = 'SingleInstallment')
					AND (@DeferInterimInterestIncomeRecognition = 'False' AND @DeferInterimInterestIncomeRecognitionForSingleInstallment = 'False'))
			THEN ISNULL(ilis.GLPosted_InterimInterestIncome_Table,0.00) - ISNULL(soir.TotalGLPosted_InterimInterestReceivables_Table,0.00)
			WHEN (ec.InterimInterestBillingType = 'Capitalize' AND @DeferInterimInterestIncomeRecognition = 'False')
			THEN ISNULL(cia.CapitalizedInterimInterest,0.00) - ISNULL(ilis.AccruedCapitalizedIncome_InterimInterestIncome_Table,0.00)
			ELSE 0.00
		END [AccruedInterimInterestIncome_Table]
	INTO #InterimOtherBuckets
	FROM #EligibleContracts ec
		LEFT JOIN #SumOfInterimReceivables soir ON soir.ContractId = ec.ContractId
		LEFT JOIN #InterimLeaseIncomeSchInfo ilis ON ilis.ContractId = ec.ContractId
		LEFT JOIN #SumOfVendorRentSharing sovrs ON sovrs.ContractId = ec.ContractId
		LEFT JOIN #CapitalizeInterimAmount cia ON cia.ContractId = ec.ContractId;
	
	CREATE NONCLUSTERED INDEX IX_Id ON #InterimOtherBuckets(ContractId);

	/*FloatRate*/
	IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Assets' AND COLUMN_NAME = 'IsSKU')
	BEGIN
		SET @Sql = 
		'SELECT 
			ec.ContractId
			,SUM(CASE
					WHEN cod.ContractId IS NULL
					THEN rd.Amount_Amount
					ELSE 0.00
				END) [TotalAmount]
			,SUM(CASE
					WHEN r.IsGLPosted = 1
						AND cod.ContractId IS NULL
					THEN rd.LeaseComponentAmount_Amount
					ELSE 0.00
				END) [LeaseComponentAmount]
			,SUM(CASE
					WHEN r.IsGLPosted = 1
						AND cod.ContractId IS NULL
					THEN rd.NonLeaseComponentAmount_Amount
					ELSE 0.00
				END) [NonLeaseComponentAmount]
			,SUM(CASE
					WHEN r.IsGLPosted = 0
						AND rd.Amount_Amount != rd.Balance_Amount
						AND cod.ContractId IS NULL
					THEN rd.Amount_Amount
					ELSE 0.00
				END) [TotalPrepaidAmount]
			,SUM(CASE
					WHEN r.IsGLPosted = 0
						AND rd.LeaseComponentAmount_Amount != rd.LeaseComponentBalance_Amount
						AND cod.ContractId IS NULL
					THEN rd.LeaseComponentAmount_Amount
					ELSE 0.00
				END) [LeaseComponentPrepaidAmount]
			,SUM(CASE
					WHEN r.IsGLPosted = 0
						AND rd.NonLeaseComponentAmount_Amount != rd.NonLeaseComponentBalance_Amount
						AND cod.ContractId IS NULL
					THEN rd.NonLeaseComponentAmount_Amount
					ELSE 0.00
				END) [NonLeaseComponentPrepaidAmount]
			,SUM(CASE
					WHEN r.IsGLPosted = 1
						AND cod.ContractId IS NULL
					THEN rd.Balance_Amount
					ELSE 0.00
				END) [TotalOSARAmount]
			,SUM(CASE
					WHEN r.IsGLPosted = 1
						AND cod.ContractId IS NULL
					THEN rd.LeaseComponentBalance_Amount
					ELSE 0.00
				END) [LeaseComponentOSARAmount]
			,SUM(CASE
					WHEN r.IsGLPosted = 1
						AND cod.ContractId IS NULL
					THEN rd.NonLeaseComponentBalance_Amount
					ELSE 0.00
				END) [NonLeaseComponentOSARAmount]
		FROM #EligibleContracts ec
			INNER JOIN Receivables r ON r.EntityId = ec.ContractId AND r.EntityType = ''CT''
			INNER JOIN ReceivableDetails rd ON rd.ReceivableId = r.Id
			INNER JOIN Receivablecodes rc ON rc.Id = r.ReceivableCodeId
			INNER JOIN Receivabletypes rt ON rt.Id = rc.ReceivableTypeId
			LEFT JOIN #ChargeOff cod ON cod.ContractId = ec.ContractId
		WHERE rt.Name = ''LeaseFloatRateAdj''
			AND r.IsActive = 1
			AND r.FunderId IS NULL
			AND r.EntityType = ''CT''
			AND ec.IsFloatRateLease = 1
		GROUP BY ec.ContractId;'

	INSERT INTO #FloatRateReceivableDetails
	EXEC (@Sql)
	END

	IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Assets' AND COLUMN_NAME = 'IsSKU')
	BEGIN
	INSERT INTO #FloatRateReceivableDetails
	SELECT 
		ec.ContractId
		,SUM(CASE
				WHEN cod.ContractId IS NULL 
				THEN rd.Amount_Amount
				ELSE 0.00
			END) [TotalAmount]
		,SUM(CASE
				WHEN rd.AssetComponentType != 'Finance'
					AND r.IsGLPosted = 1
					AND cod.ContractId IS NULL
				THEN rd.Amount_Amount
				ELSE 0.00
			END) [LeaseComponentAmount]
		,SUM(CASE
				WHEN rd.AssetComponentType = 'Finance'
					AND r.IsGLPosted = 1
					AND cod.ContractId IS NULL
				THEN rd.Amount_Amount
				ELSE 0.00
			END) [NonLeaseComponentAmount]
		,SUM(CASE
				WHEN r.IsGLPosted = 0
					AND rd.Amount_Amount != rd.Balance_Amount
					AND cod.ContractId IS NULL
				THEN rd.Amount_Amount
				ELSE 0.00
			END) [TotalPrepaidAmount]
		,SUM(CASE
				WHEN r.IsGLPosted = 0
					AND rd.AssetComponentType != 'Finance'
					AND cod.ContractId IS NULL
					AND rd.Amount_Amount != rd.Balance_Amount
				THEN rd.Amount_Amount
				ELSE 0.00
			END) [LeaseComponentPrepaidAmount]
		,SUM(CASE
				WHEN r.IsGLPosted = 0
					AND rd.AssetComponentType = 'Finance'
					AND cod.ContractId IS NULL
					AND rd.Amount_Amount != rd.Balance_Amount
				THEN rd.Amount_Amount
				ELSE 0.00
			END) [NonLeaseComponentPrepaidAmount]
		,SUM(CASE
				WHEN r.IsGLPosted = 1
					AND cod.ContractId IS NULL
				THEN rd.Balance_Amount
				ELSE 0.00
			END) [TotalOSARAmount]
		,SUM(CASE
				WHEN r.IsGLPosted = 1
					AND rd.AssetComponentType != 'Finance'
					AND cod.ContractId IS NULL
				THEN rd.Balance_Amount
				ELSE 0.00
			END) [LeaseComponentOSARAmount]
		,SUM(CASE
				WHEN r.IsGLPosted = 1
					AND rd.AssetComponentType = 'Finance'
					AND cod.ContractId IS NULL
				THEN rd.Balance_Amount
				ELSE 0.00
			END) [NonLeaseComponentOSARAmount]
	FROM #EligibleContracts ec
		INNER JOIN Receivables r ON r.EntityId = ec.ContractId AND r.EntityType = 'CT'
		INNER JOIN ReceivableDetails rd ON rd.ReceivableId = r.Id
		INNER JOIN Receivablecodes rc ON rc.id = r.ReceivableCodeId
		INNER JOIN Receivabletypes rt ON rt.id = rc.ReceivableTypeId
		LEFT JOIN #ChargeOff cod ON cod.ContractId = ec.ContractId
	WHERE rt.name = 'LeaseFloatRateAdj'
		AND r.IsActive = 1
		AND r.FunderId IS NULL
		AND rd.IsActive = 1
		AND r.EntityType = 'CT'
		AND ec.IsFloatRateLease = 1
	GROUP BY ec.ContractId;
	END

	CREATE NONCLUSTERED INDEX IX_Id ON #FloatRateReceivableDetails(ContractId);

	IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Assets' AND COLUMN_NAME = 'IsSKU')
	BEGIN

	INSERT INTO #FloatRateReceiptDetails
	SELECT ec.ContractId
		 , SUM(CASE
				   WHEN r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount = 0.00 AND RecoveryAmount_Amount = 0.00
						AND (r.StartDate < co.ChargeOffDate OR co.ChargeOffDate IS NULL)
				   THEN r.AmountApplied_Amount
				   ELSE 0.00
			   END) [TotalPaid]
		 , SUM(CASE
				   WHEN r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00 AND RecoveryAmount_Amount = 0.00
						AND (r.StartDate < co.ChargeOffDate OR co.ChargeOffDate IS NULL)
				   THEN r.LeaseComponentAmountApplied_Amount
				   ELSE 0.00
			   END) AS [LeaseComponentTotalPaid]
		 , SUM(CASE
				   WHEN r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_NLC = 0.00 AND RecoveryAmount_Amount = 0.00
						AND (r.StartDate < co.ChargeOffDate OR co.ChargeOffDate IS NULL)
				   THEN r.NonLeaseComponentAmountApplied_Amount
				   ELSE 0.00
			   END) [NonLeaseComponentTotalPaid]
		 , SUM(CASE
				   WHEN ReceiptClassification = 'Cash' AND ReceiptTypeName NOT IN('PayableOffset', 'SecurityDeposit', 'EscrowRefund')
						AND r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount = 0.00 AND RecoveryAmount_Amount = 0.00
						AND (r.StartDate < co.ChargeOffDate OR co.ChargeOffDate IS NULL)
				   THEN AmountApplied_Amount
				   ELSE 0.00
			   END) [TotalCashPaidAmount]
		 , SUM(CASE
				   WHEN ReceiptClassification = 'Cash' AND ReceiptTypeName NOT IN('PayableOffset', 'SecurityDeposit', 'EscrowRefund')
						AND r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00 AND RecoveryAmount_Amount = 0.00
						AND (r.StartDate < co.ChargeOffDate OR co.ChargeOffDate IS NULL)
				   THEN LeaseComponentAmountApplied_Amount
				   ELSE 0.00
			   END) [TotalLeaseComponentCashPaidAmount]
		 , SUM(CASE
				   WHEN ReceiptClassification = 'Cash' AND ReceiptTypeName NOT IN('PayableOffset', 'SecurityDeposit', 'EscrowRefund')
						AND r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_NLC = 0.00 AND RecoveryAmount_Amount = 0.00
						AND (r.StartDate < co.ChargeOffDate OR co.ChargeOffDate IS NULL)
				   THEN NonLeaseComponentAmountApplied_Amount
				   ELSE 0.00
			   END) [TotalNonLeaseComponentCashPaidAmount]
		 , SUM(CASE
				   WHEN(ReceiptClassification != 'Cash' OR ReceiptTypeName NOT IN('PayableOffset', 'SecurityDeposit', 'EscrowRefund'))
					   AND r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount = 0.00 AND RecoveryAmount_Amount = 0.00
					   AND (r.StartDate < co.ChargeOffDate OR co.ChargeOffDate IS NULL)
				   THEN AmountApplied_Amount
				   ELSE 0.00
			   END) [TotalNonCashPaidAmount]
		 , SUM(CASE
				   WHEN(ReceiptClassification != 'Cash' OR ReceiptTypeName IN('PayableOffset', 'SecurityDeposit', 'EscrowRefund'))
					   AND r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00 AND RecoveryAmount_Amount = 0.00
					   AND (r.StartDate < co.ChargeOffDate OR co.ChargeOffDate IS NULL)
				   THEN LeaseComponentAmountApplied_Amount
				   ELSE 0.00
			   END) [TotalLeaseComponentNonCashPaidAmount]
		 , SUM(CASE
				   WHEN(ReceiptClassification != 'Cash' OR ReceiptTypeName IN('PayableOffset', 'SecurityDeposit', 'EscrowRefund'))
					   AND r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_NLC = 0.00 AND RecoveryAmount_Amount = 0.00
					   AND (r.StartDate < co.ChargeOffDate OR co.ChargeOffDate IS NULL)
				   THEN NonLeaseComponentAmountApplied_Amount
				   ELSE 0.00
			   END) [TotalNonLeaseComponentNonCashPaidAmount]
		 , SUM(CASE
				   WHEN(RecoveryAmount_Amount = 0.00 AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00)
					   AND r.StartDate < co.ChargeOffDate AND co.Contractid IS NOT NULL
				   THEN LeaseComponentAmountApplied_Amount
				   ELSE 0.00
			   END) [GLPosted_PreChargeoff_LeaseComponent_Table]
		 , SUM(CASE
				   WHEN(RecoveryAmount_Amount = 0.00 AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_NLC = 0.00)
					   AND r.StartDate < co.ChargeOffDate AND co.Contractid IS NOT NULL
				   THEN NonLeaseComponentAmountApplied_Amount
				   ELSE 0.00
			   END) [GlPosted_PreChargeoff_NonLeaseComponent_Table]
		 , SUM(CASE
				   WHEN RecoveryAmount_LC != 0.00 OR GainAmount_LC != 0.00
				   THEN r.RecoveryAmount_LC + r.GainAmount_LC
				   ELSE 0.00
			   END) [Recovery_LeaseComponent_Table]
		 , SUM(CASE
				   WHEN RecoveryAmount_NLC != 0.00 OR GainAmount_NLC != 0.00
				   THEN r.RecoveryAmount_NLC + r.GainAmount_NLC
				   ELSE 0.00
			   END) [Recovery_NonLeaseComponent_Table]
	FROM #ReceiptApplicationReceivableDetails r
		 INNER JOIN #EligibleContracts ec ON r.EntityId = ec.ContractId
		 LEFT JOIN #ChargeOff co ON r.EntityId = co.ContractId
	WHERE r.ReceiptStatus IN('Completed', 'Posted')
		 AND r.ReceivableType = 'LeaseFloatRateAdj'
		 AND r.ReceiptStatus IN('Completed', 'Posted')
	AND ec.IsFloatRateLease = 1
	GROUP BY ec.ContractId;
	END

	IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Assets' AND COLUMN_NAME = 'IsSKU')
	BEGIN
	INSERT INTO #FloatRateReceiptDetails
	SELECT 
		ec.ContractId
		,SUM(rard.AmountApplied_Amount) [TotalPaid]
		,SUM(CASE WHEN rd.AssetComponentType != 'Finance' THEN rard.AmountApplied_Amount ELSE 0.00 END) [LeaseComponentTotalPaid]
		,SUM(CASE WHEN rd.AssetComponentType = 'Finance' THEN rard.AmountApplied_Amount ELSE 0.00 END) [NonLeaseComponentTotalPaid]
		,SUM(CASE
				WHEN receipt.ReceiptClassification = 'Cash'
					AND rtt.ReceiptTypeName NOT IN ('PayableOffset','SecurityDeposit','EscrowRefund')
				THEN rard.AmountApplied_Amount
				ELSE 0.00
			END) [TotalCashPaidAmount]
		,SUM(CASE
				WHEN receipt.ReceiptClassification = 'Cash'
					AND rtt.ReceiptTypeName NOT IN ('PayableOffset','SecurityDeposit','EscrowRefund')
					AND rd.AssetComponentType != 'Finance'
				THEN rard.AmountApplied_Amount
				ELSE 0.00
			END) [TotalLeaseComponentCashPaidAmount]
		,SUM(CASE
				WHEN receipt.ReceiptClassification = 'Cash'
					AND rtt.ReceiptTypeName NOT IN ('PayableOffset','SecurityDeposit','EscrowRefund')
					AND rd.AssetComponentType = 'Finance'
				THEN rard.AmountApplied_Amount
				ELSE 0.00
			END) [TotalNonLeaseComponentCashPaidAmount]
		,SUM(CASE
				WHEN receipt.ReceiptClassification != 'Cash'
					OR rtt.ReceiptTypeName NOT IN ('PayableOffset','SecurityDeposit','EscrowRefund')
				THEN rard.AmountApplied_Amount
				ELSE 0.00
			END) [TotalNonCashPaidAmount]
		,SUM(CASE
				WHEN (receipt.ReceiptClassification != 'Cash'
					OR rtt.ReceiptTypeName IN ('PayableOffset','SecurityDeposit','EscrowRefund'))
					AND rd.AssetComponentType != 'Finance'
				THEN rard.AmountApplied_Amount
				ELSE 0.00
			END) [TotalLeaseComponentNonCashPaidAmount]
		,SUM(CASE
				WHEN (receipt.ReceiptClassification != 'Cash'
					OR rtt.ReceiptTypeName IN ('PayableOffset','SecurityDeposit','EscrowRefund'))
					AND rd.AssetComponentType = 'Finance'
				THEN rard.AmountApplied_Amount
				ELSE 0.00
			END) [TotalNonLeaseComponentNonCashPaidAmount]
		,SUM(CASE
				WHEN (rard.RecoveryAmount_Amount = 0.00 AND rard.GainAmount_Amount = 0.00)
					AND lps.StartDate < cod.ChargeOffDate
					AND rd.AssetComponentType != 'Finance'
					AND cod.Contractid IS NOT NULL
				THEN rard.AmountApplied_Amount
				ELSE 0.00
			END) [GLPosted_PreChargeoff_LeaseComponent_Table]
		,SUM(CASE
				WHEN (rard.RecoveryAmount_Amount = 0.00 AND rard.GainAmount_Amount = 0.00)
					AND lps.StartDate < cod.ChargeOffDate
					AND rd.AssetComponentType = 'Finance'
					AND cod.Contractid IS NOT NULL
				THEN rard.AmountApplied_Amount
				ELSE 0.00
			END) [GlPosted_PreChargeoff_NonLeaseComponent_Table]
		,SUM(CASE
				WHEN (rard.RecoveryAmount_Amount != 0.00 OR rard.GainAmount_Amount != 0.00)
					AND rd.AssetComponentType != 'Finance'
				THEN rard.AmountApplied_Amount
				ELSE 0.00
			END) [Recovery_LeaseComponent_Table]
		,SUM(CASE
				WHEN (rard.RecoveryAmount_Amount != 0.00 OR rard.GainAmount_Amount != 0.00)
					AND rd.AssetComponentType = 'Finance'
				THEN rard.AmountApplied_Amount
				ELSE 0.00
			END) [Recovery_NonLeaseComponent_Table]
	FROM #EligibleContracts ec
		INNER JOIN Receivables r ON ec.ContractId = r.EntityId
		INNER JOIN ReceivableDetails rd ON r.Id = rd.ReceivableId
		INNER JOIN ReceiptApplicationReceivableDetails rard ON rard.ReceivableDetailId = rd.Id
		INNER JOIN ReceiptApplications ra ON rard.ReceiptApplicationId = ra.Id
		INNER JOIN Receipts receipt ON ra.ReceiptId = receipt.Id
		INNER JOIN ReceiptTypes rtt ON receipt.TypeId = rtt.Id
		INNER JOIN ReceivableCodes rc ON r.ReceivableCodeId = rc.Id
		INNER JOIN ReceivableTypes rt ON rc.ReceivableTypeId = rt.Id
		LEFT JOIN #ChargeOff cod ON cod.ContractId = ec.ContractId
		LEFT JOIN LeasePaymentSchedules lps ON lps.Id = r.PaymentScheduleId	
	WHERE r.IsActive = 1
		AND r.FunderId IS NULL
		AND r.EntityType = 'CT'
		AND rt.Name = 'LeaseFloatRateAdj'
		AND rard.IsActive = 1
		AND rd.IsActive = 1
		AND receipt.Status IN('Completed', 'Posted')
		AND ec.IsFloatRateLease = 1
	GROUP BY ec.ContractId
	END

	CREATE NONCLUSTERED INDEX IX_Id ON #FloatRateReceiptDetails(ContractId);

	UPDATE rd 
		SET LeaseComponentAmount += receipt.GLPosted_PreChargeoff_LeaseComponent_Table
			,NonLeaseComponentAmount += receipt.GlPosted_PreChargeoff_NonLeaseComponent_Table
			,TotalAmount = receipt.GLPosted_PreChargeoff_LeaseComponent_Table + receipt.GlPosted_PreChargeoff_NonLeaseComponent_Table
	FROM #FloatRateReceivableDetails rd
		INNER JOIN #FloatRateReceiptDetails receipt ON rd.ContractId = receipt.ContractId
		INNER JOIN #ChargeOff cod ON cod.ContractId = rd.ContractId;
	
	SELECT 
		ec.ContractId
		,SUM(CASE
				WHEN income.IsScheduled = 1
				THEN income.CustomerIncomeAmount_Amount
				ELSE 0.00
			END) [Income_Schedule]
		,SUM(CASE
				WHEN income.IsAccounting = 1
				THEN income.CustomerIncomeAmount_Amount
				ELSE 0.00
			END) [Income_Accounting]
		,SUM(CASE
				WHEN income.IsAccounting = 1
					AND income.IsGLPosted = 1
					AND income.IsNonAccrual = 0
				THEN income.CustomerIncomeAmount_Amount
				ELSE 0.00
			END) [Income_GLPosted]
		,SUM(CASE
				WHEN income.IsNonAccrual = 1
					AND income.IsGLPosted = 1
				THEN income.CustomerIncomeAmount_Amount
				ELSE 0.00
			END) [Income_Suspended]
		,SUM(CASE
				WHEN income.IsGLPosted = 1
					AND income.IsAccounting = 1
				THEN income.CustomerIncomeAmount_Amount
				ELSE 0.00
			END) [Income_Accrued]
	INTO #FloatRateIncomeDetails
	FROM #EligibleContracts ec
		INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
		INNER JOIN LeaseFloatRateIncomes income ON income.LeaseFinanceId = lf.Id
		LEFT JOIN #ChargeOff cod ON cod.ContractId = ec.ContractId
		LEFT JOIN #AccrualDetails ad ON ad.ContractId = ec.ContractId
	WHERE (income.IsAccounting = 1
		OR income.IsScheduled = 1)
		AND ec.IsFloatRateLease = 1
		AND income.IsLessorOwned = 1
	GROUP BY ec.ContractId;
	
	CREATE NONCLUSTERED INDEX IX_Id ON #FloatRateIncomeDetails(ContractId);

	SELECT
		ec.ContractId
		,r.Id AS ReceivableId
		,r.IsGLPosted
		,r.DueDate
		,rt.Name AS ReceivableType
		,rc.AccountingTreatment
		,CASE
			WHEN bi.Id IS NOT NULL
			THEN bi.StartDate
			ELSE lps.StartDate 
		END AS StartDate
		,r.FunderId
		,bi.IsFAS91
		,s.InvoiceComment
		,OriginalGTT.Name AS OriginalGLTransactionType
	INTO #FunderReceivableInfo
	FROM #EligibleContracts ec
		INNER JOIN Receivables r ON r.EntityId = ec.ContractId
		INNER JOIN ReceivableCodes rc ON r.ReceivableCodeId = rc.Id
		INNER JOIN ReceivableTypes rt ON rc.ReceivableTypeId = rt.Id
		INNER JOIN GLTemplates gt ON rc.GLTemplateId = gt.Id
		INNER JOIN GLTransactionTypes gtt ON gt.GLTransactionTypeId = gtt.Id
		INNER JOIN GLTemplates OriginalGT ON rc.GLTemplateId = OriginalGT.Id
		INNER JOIN GLTransactionTypes OriginalGTT ON OriginalGT.GLTransactionTypeId = OriginalGTT.Id
		LEFT JOIN Sundries s ON r.SourceId = s.Id AND r.SourceTable = 'Sundry'
		LEFT JOIN BlendedItemDetails bid ON s.Id = bid.SundryId AND s.Id IS NOT NULL
		LEFT JOIN BlendedItems bi ON bid.BlendedItemId = bi.Id AND bid.Id IS NOT NULL
		LEFT JOIN LeasePaymentSchedules lps ON r.PaymentScheduleId = lps.Id	AND r.SourceTable NOT IN ('CPUSchedule','SundryRecurring')
	WHERE r.IsActive = 1
		AND r.EntityType = 'CT'
		AND r.IsCollected = 1
		AND r.IsDummy = 0;

	CREATE NONCLUSTERED INDEX IX_Id ON #FunderReceivableInfo(ContractId);

	SELECT DISTINCT
		ec.ContractId
		,ec.ReceivableForTransfersId
	INTO #RemitOnlyContracts
	FROM #EligibleContracts ec
		INNER JOIN ReceivableForTransferFundingSources rftfs ON ec.ReceivableForTransfersId = rftfs.ReceivableForTransferId
	WHERE rftfs.IsActive = 1
		AND rftfs.SalesTaxResponsibility = 'RemitOnly';
		
	CREATE NONCLUSTERED INDEX IX_Id ON #RemitOnlyContracts(ContractId);

	SELECT
		r.ContractId
		,SUM(
			CASE
				WHEN rt.IsGLPosted = 1
					AND roc.ContractId IS NOT NULL
				THEN rt.Amount_Amount
				ELSE 0.00
			END) AS FunderRemittingSalesTaxGLPosted
		,SUM(
			CASE
				WHEN rt.IsGLPosted = 1
					AND roc.ContractId IS NOT NULL
				THEN rt.Balance_Amount
				ELSE 0.00
			END) AS FunderRemittingSalesTaxOSAR
		,SUM(
			CASE
				WHEN rt.IsGLPosted = 0
					AND roc.ContractId IS NOT NULL
				THEN rt.Amount_Amount - rt.Balance_Amount
				ELSE 0.00
			END) AS FunderRemittingSalesTaxPrepaid
		,SUM(
			CASE
				WHEN rt.IsGLPosted = 1
					AND roc.ContractId IS NULL
				THEN rt.Amount_Amount
				ELSE 0.00
			END) AS LessorRemittingSalesTaxGLPosted
		,SUM(
			CASE
				WHEN rt.IsGLPosted = 1
					AND roc.ContractId IS NULL
				THEN rt.Balance_Amount
				ELSE 0.00
			END) AS LessorRemittingSalesTaxOSAR
		,SUM(
			CASE
				WHEN rt.IsGLPosted = 0
					AND roc.ContractId IS NULL
				THEN rt.Amount_Amount - rt.Balance_Amount
				ELSE 0.00
			END) AS LessorRemittingSalesTaxPrepaid
	INTO #FunderReceivableTaxDetails
	FROM #FunderReceivableInfo r
		INNER JOIN ReceivableTaxes rt ON r.ReceivableId = rt.ReceivableId
		LEFT JOIN #RemitOnlyContracts roc ON roc.ContractId = r.ContractId
	WHERE rt.IsActive = 1
		AND r.FunderId IS NOT NULL
	GROUP BY r.ContractId;

	CREATE NONCLUSTERED INDEX IX_Id ON #FunderReceivableTaxDetails(ContractId);

	IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ReceivableTaxes' AND COLUMN_NAME = 'IsCashBased')
	BEGIN
	SET @Sql = 
	'SELECT 
		SUM(rard.TaxApplied_Amount) AS FunderPortionNonCash
		,r.ContractId
	FROM #FunderReceivableInfo r
		INNER JOIN ReceivableTaxes rt ON rt.ReceivableId = r.ReceivableId
		INNER JOIN ReceivableDetails rd on rd.ReceivableId = r.ReceivableId
		INNER JOIN ReceiptApplicationReceivableDetails rard on rard.ReceivableDetailId = rd.Id
		INNER JOIN ReceiptApplications ra on rard.ReceiptApplicationId = ra.Id
		INNER JOIN Receipts rp ON rp.Id = ra.ReceiptId
		INNER JOIN #RemitOnlyContracts roc ON roc.ContractId = r.ContractId
	WHERE rt.IsActive = 1
		AND rt.IsCashBased = 1
		AND rt.IsDummy = 0
		AND r.FunderId IS NOT NULL
		AND rp.ReceiptClassification = ''NonCash''
		AND rp.Status IN (''Completed'',''Posted'')
		AND rard.IsActive = 1
	GROUP BY r.ContractId'
	
	INSERT INTO #SalesTaxNonCashAppliedFO (FunderPortionNonCash,ContractId)
	EXEC (@Sql)

	END

	CREATE NONCLUSTERED INDEX IX_Id ON #SalesTaxNonCashAppliedFO(ContractId);

	SELECT
		r.ContractId
		,SUM(
			CASE
				WHEN r.IsGLPosted = 1
				THEN rd.Amount_Amount
				ELSE 0.00
			END) [GLPostedFO]
		,SUM(
			CASE
				WHEN r.IsGLPosted = 1
				THEN rd.Balance_Amount
				ELSE 0.00
			END) [OutstandingFO]
		,SUM(
			CASE
				WHEN r.IsGLPosted = 0
				THEN rd.Amount_Amount - rd.Balance_Amount
				ELSE 0.00
			END) [PrepaidFO]
	INTO #FunderReceivableDetailsAmount
	FROM #FunderReceivableInfo r
		INNER JOIN ReceivableDetails rd ON rd.ReceivableId = r.ReceivableId
		LEFT JOIN #ChargeOff cod ON cod.ContractId = r.ContractId
	WHERE rd.IsActive = 1
		AND r.FunderId IS NOT NULL
	GROUP BY r.ContractId;

	CREATE NONCLUSTERED INDEX IX_Id ON #FunderReceivableDetailsAmount(ContractId);

	SELECT
		r.ContractId
		,SUM(
			CASE
				WHEN rp.ReceiptClassification = 'Cash'
					AND rpt.ReceiptTypeName NOT IN ('PayableOffset','SecurityDeposit','EscrowRefund')
					AND rard.RecoveryAmount_Amount = 0.00 AND rard.GainAmount_Amount = 0.00
				THEN rard.AmountApplied_Amount
				ELSE 0.00
			END) [PaidCashFO]
		,SUM(
			CASE
				WHEN (rp.ReceiptClassification = 'NonCash'
					OR rpt.ReceiptTypeName IN ('PayableOffset','SecurityDeposit','EscrowRefund'))
					AND rard.RecoveryAmount_Amount = 0.00 AND rard.GainAmount_Amount = 0.00
				THEN rard.AmountApplied_Amount
				ELSE 0.00
			END) [PaidNonCashFO]
		,SUM(
			CASE
				WHEN rp.ReceiptClassification = 'Cash'
					AND rpt.ReceiptTypeName NOT IN ('PayableOffset','SecurityDeposit','EscrowRefund')
					AND roc.ContractId IS NOT NULL
					AND rard.RecoveryAmount_Amount = 0.00 AND rard.GainAmount_Amount = 0.00
				THEN rard.TaxApplied_Amount
				ELSE 0.00
			END) [SalesTaxCashAppliedFO]
		,SUM(
			CASE
				WHEN (rp.ReceiptClassification = 'NonCash'
					OR rpt.ReceiptTypeName IN ('PayableOffset','SecurityDeposit','EscrowRefund'))
					AND roc.ContractId IS NOT NULL
					AND rard.RecoveryAmount_Amount = 0.00 AND rard.GainAmount_Amount = 0.00
				THEN rard.TaxApplied_Amount
				ELSE 0.00
			END) [SalesTaxNonCashAppliedFO]
		,SUM(
			CASE
				WHEN r.AccountingTreatment IN ('CashBased','MemoBased')
					AND (rp.ReceiptClassification = 'NonCash' AND rpt.ReceiptTypeName NOT IN ('PayableOffset','SecurityDeposit','EscrowRefund'))
					AND rard.RecoveryAmount_Amount = 0.00 AND rard.GainAmount_Amount = 0.00
					AND ((r.StartDate < cod.ChargeOffDate
							OR cod.ChargeOffDate IS NULL
							OR r.StartDate IS NULL)
						OR (cod.ContractId IS NOT NULL
							AND (r.OriginalGLTransactionType IN ('AssetSaleAR','PropertyTaxAR','PropertyTaxEscrow','SecurityDeposit')
								OR r.IsFAS91 = 0
								OR r.InvoiceComment IN ('Syndication Actual Proceeds','Syndication Scrape Receivable'))))
				THEN rard.AmountApplied_Amount
				ELSE 0.00
			END) [NonCashAmountFO]
		,SUM(
			CASE
				WHEN rp.ReceiptClassification = 'Cash'
					AND rpt.ReceiptTypeName NOT IN ('PayableOffset','SecurityDeposit','EscrowRefund')
					AND roc.ContractId IS NULL
				THEN rard.TaxApplied_Amount
				ELSE 0.00
			END) [LessorSalesTaxCashAppliedFO]
		,SUM(
			CASE
				WHEN (rp.ReceiptClassification = 'NonCash'
					OR rpt.ReceiptTypeName IN ('PayableOffset','SecurityDeposit','EscrowRefund'))
					AND roc.ContractId IS NULL
				THEN rard.TaxApplied_Amount
				ELSE 0.00
			END) [LessorSalesTaxNonCashAppliedFO]
	INTO #FunderReceiptApplicationDetails
	FROM #FunderReceivableInfo r
		INNER JOIN ReceivableDetails rd ON rd.ReceivableId = r.ReceivableId
		INNER JOIN ReceiptApplicationReceivableDetails rard ON rd.Id = rard.ReceivableDetailId
		INNER JOIN ReceiptApplications ra ON rard.ReceiptApplicationId = ra.Id 
		INNER JOIN Receipts rp ON ra.ReceiptId = rp.Id
		INNER JOIN ReceiptTypes rpt ON rpt.Id = rp.TypeId
		LEFT JOIN #ChargeOff cod ON cod.ContractId = r.ContractId
		LEFT JOIN #RemitOnlyContracts roc ON roc.ContractId = r.ContractId
	WHERE rp.Status IN ('Posted','Completed')
		AND rd.IsActive = 1
		AND rard.IsActive = 1
		AND rpt.IsActive = 1
		AND r.FunderId IS NOT NULL
	GROUP BY r.ContractId;

	SELECT
		ec.ContractId
		,SUM(CASE WHEN ec.SyndicationEffectiveDate = lfd.CommencementDate AND lis.IncomeDate = ec.SyndicationEffectiveDate
			AND oc.ContractId IS NULL AND co.ContractId IS NULL
			THEN lis.ResidualIncomeBalance_Amount
			WHEN ec.SyndicationEffectiveDate != lfd.CommencementDate AND lis.IncomeDate = DATEADD(DAY,-1,ec.SyndicationEffectiveDate)
			AND oc.ContractId IS NULL AND co.ContractId IS NULL
			THEN lis.ResidualIncomeBalance_Amount
			ELSE 0.00 END) AS ResidualIncomeBalance_LeaseComponent
		,SUM(CASE WHEN ec.SyndicationEffectiveDate = lfd.CommencementDate AND lis.IncomeDate = ec.SyndicationEffectiveDate
			AND oc.ContractId IS NULL AND co.ContractId IS NULL
			THEN lis.FinanceResidualIncomeBalance_Amount
			WHEN ec.SyndicationEffectiveDate != lfd.CommencementDate AND lis.IncomeDate = DATEADD(DAY,-1,ec.SyndicationEffectiveDate)
			AND oc.ContractId IS NULL AND co.ContractId IS NULL
			THEN lis.FinanceResidualIncomeBalance_Amount
			ELSE 0.00 END) AS ResidualIncomeBalance_FinanceComponent
	INTO #SaleOfPaymentsUnguaranteedInfo
	FROM #EligibleContracts ec
	INNER JOIN LeaseIncomeSchedules lis ON ec.SyndicationLeaseFinanceId = lis.LeaseFinanceId
	INNER JOIN LeaseFinanceDetails lfd ON lfd.Id = lis.LeaseFinanceId
	INNER JOIN (
		SELECT
			DISTINCT ec.ContractId
		FROM #EligibleContracts ec
		INNER JOIN LeaseAssets la ON ec.SyndicationLeaseFinanceId = la.LeaseFinanceId
		INNER JOIN #AssetResiduals ar ON ec.ContractId = ar.ContractId
		WHERE ec.SyndicationType = 'SaleOfPayments' AND ec.AccountingStandard != 'ASC840_IAS17'
		AND la.BookedResidual_Amount != 0.00 AND la.ThirdPartyGuaranteedResidual_Amount = 0.00 
		AND la.CustomerGuaranteedResidual_Amount = 0.00) AS t ON t.ContractId = ec.ContractId
	LEFT JOIN #OTPReclass oc ON oc.ContractId = ec.ContractId
	LEFT JOIN #ChargeOff co ON co.ContractId = ec.ContractId
	WHERE lis.IsAccounting = 1 AND lis.IsLessorOwned = 1
	GROUP BY ec.ContractId;
	
	SELECT GLJournalDetails.EntityId 
			 , GLJournalDetails.SourceId
			 , GLEntryItems.Name as EntryItem
			 , GLTransactionTypes.Name GLTransactionType
			 , ge.Name MatchingEntryItem
			 , gtt.Name MatchingGLTransactionType
			 , SUM(CASE
				   WHEN GLJournalDetails.IsDebit = 1
				   THEN GLJournalDetails.Amount_Amount
				   ELSE 0
			   END) DebitAmount
			 , SUM(CASE
				   WHEN GLJournalDetails.IsDebit = 0
				   THEN GLJournalDetails.Amount_Amount
				   ELSE 0
			   END) CreditAmount
	INTO #GLTrialBalance
	FROM GLJournals
			 INNER JOIN GLJournalDetails ON GLJournals.Id = GLJournalDetails.GLJournalId 
			 INNER JOIN GLAccounts ON GLJournalDetails.GLAccountId = GLAccounts.Id
			 INNER JOIN GLTemplateDetails ON GLTemplateDetails.Id = GLJournalDetails.GLTemplateDetailId
			 INNER JOIN GLEntryItems ON GLEntryItems.Id = GLTemplateDetails.EntryItemId
				AND GLEntryItems.Name IN
				('Income','FinancingIncome','UnearnedIncome','UnearnedUnguaranteedResidualIncome','UnguaranteedResidualIncome'
				,'Receivable','SuspendedIncome','SuspendedUnguaranteedResidualIncome','FinancingUnearnedIncome'
				,'FinancingUnearnedUnguaranteedResidualIncome','FinancingUnguaranteedResidualIncome','FinancingSuspendedIncome'
				,'FinancingSuspendedUnguaranteedResidualIncome','DeferredSellingProfit','SellingProfitIncome'
				,'SuspendedSellingProfitIncome','LongTermLeaseReceivable','ShortTermLeaseReceivable','PrePaidCapitalLeaseReceivable'
				,'FinancingLongTermLeaseReceivable','FinancingShortTermLeaseReceivable','GuaranteedResidual','UnguaranteedResidualBooked'
				,'OTPLeasedAsset','FinancingUnguaranteedResidualIncome','FinancingUnguaranteedResidualBooked'
				,'FinancingPrePaidLeaseReceivable','FinancingGuaranteedResidual','ResidualRecapture','ChargeOffExpense','ChargeOffRecovery'
				,'CostOfSales','SalesTypeRevenue','WriteDownAccount','GainOnRecovery','UnAppliedAR','SalesTaxReceivable'
				,'PrePaidSalesTaxReceivable','SyndicatedSalesTaxReceivable','PrePaidSyndicatedSalesTaxReceivable','SalesTaxPayable'
				,'CapitalizedAdditionalFee','CapitalizedInterimRent','CapitalizedInterimInterest','InterimRentReceivable'
				,'PrepaidInterimRentReceivable','InterimRentIncome','DeferredInterimRentIncome','LeaseInterimInterestReceivable'
				,'PrepaidLeaseInterimInterestReceivable','LeaseInterimInterestIncome','AccruedInterimInterestIncome'
				,'AccruedInterimInterest','FloatRateAR','PrePaidFloatRateAR','FloatInterestIncome','FloatRateSuspendedIncome'
				,'AccruedFloatRateInterestIncome','DueToThirdPartyAR','PrepaidDueToThirdPartyAR', 'FinancingChargeOffExpense', 'FinancingChargeOffRecovery', 'FinancingGainOnRecovery')
			 INNER JOIN GLTransactionTypes ON GLTransactionTypes.Id = GLEntryItems.GLTransactionTypeId
			 INNER JOIN #EligibleContracts c ON GLJournalDetails.EntityId = c.ContractId
			 LEFT JOIN GLTemplateDetails gtd ON gtd.Id = GLJournalDetails.MatchingGLTemplateDetailId
			 LEFT JOIN GLEntryItems ge ON gtd.EntryItemId = ge.Id
			 LEFT JOIN GLTransactionTypes gtt ON gtt.Id = ge.GLTransactionTypeId
			 WHERE GLJournalDetails.EntityType IN ('Contract', 'DisbursementRequest')
			 GROUP BY EntityId
				, GLEntryItems.Name
				, GLTransactionTypes.Name
				, ge.Name
				, gtt.Name
				, GLJournalDetails.SourceId
		CREATE NONCLUSTERED INDEX IX_Id ON #GLTrialBalance(EntityId);
		
	SELECT RS1.ContractId
		, SUM(RS1.GLPostedReceivables_LeaseComponent_Debit) - SUM(RS1.GLPostedReceivables_LeaseComponent_Credit) GLPostedReceivables_LeaseComponent_GL
		, SUM(RS1.GLPostedReceivables_FinanceComponent_Debit) - SUM(RS1.GLPostedReceivables_FinanceComponent_Credit) GLPostedReceivables_FinanceComponent_GL
		, SUM(RS1.PaidReceivables_LeaseComponent_Credit) - SUM(RS1.PaidReceivables_LeaseComponent_Debit) PaidReceivables_LeaseComponent_GL
		, SUM(RS1.PaidReceivablesCash_LeaseComponent_Credit) - SUM(RS1.PaidReceivablesCash_LeaseComponent_Debit) PaidReceivablesviaCash_LeaseComponent_GL
		, SUM(RS1.PaidReceivablesNonCash_LeaseComponent_Credit) - SUM(RS1.PaidReceivablesNonCash_LeaseComponent_Debit) PaidReceivablesviaNonCash_LeaseComponent_GL
		, SUM(RS1.PaidReceivables_FinanceComponent_Credit) - SUM(RS1.PaidReceivables_FinanceComponent_Debit) PaidReceivables_FinanceComponent_GL
		, SUM(RS1.PaidReceivablesCash_FinanceComponent_Credit) - SUM(RS1.PaidReceivablesCash_FinanceComponent_Debit) PaidReceivablesviaCash_FinanceComponent_GL
		, SUM(RS1.PaidReceivablesNonCash_FinanceComponent_Credit) - SUM(RS1.PaidReceivablesNonCash_FinanceComponent_Debit) PaidReceivablesviaNonCash_FinanceComponent_GL
		, (SUM(RS1.PrePaidReceivablesPosted_Lease_Credit) - SUM(RS1.PrePaidReceivablesPosted_Lease_Debit)) - (SUM(RS1.PrePaidReceivablesPaid_Lease_Debit) - SUM(PrePaidReceivablesPaid_Lease_Credit)) PrepaidReceivables_LeaseComponent_GL
		, (SUM(RS1.PrePaidReceivablesPosted_Finance_Credit) - SUM(RS1.PrePaidReceivablesPosted_Finance_Debit)) - (SUM(RS1.PrePaidReceivablesPaid_Finance_Debit) - SUM(PrePaidReceivablesPaid_Finance_Credit)) PrepaidReceivables_FinanceComponent_GL
		, (SUM(RS1.ReceivablesPosted_Lease_Debit) - SUM(RS1.ReceivablesPosted_Lease_Credit)) - (SUM(RS1.ReceiptPosted_Lease_Credit) - SUM(RS1.ReceiptPosted_Lease_Debit)) OutstandingReceivables_LeaseComponent_GL
		, (SUM(RS1.ReceivablesPosted_Finance_Debit) - SUM(RS1.ReceivablesPosted_Finance_Credit)) - (SUM(RS1.ReceiptPosted_Finance_Credit) - SUM(RS1.ReceiptPosted_Finance_Debit)) OutstandingReceivables_FinanceComponent_GL
		, SUM(RS1.LongTermReceivables_Lease_Debit) - SUM(RS1.LongTermReceivables_Lease_Credit) LongTermReceivables_LeaseComponent_GL
		, SUM(RS1.LongTermReceivables_Finance_Debit) - SUM(RS1.LongTermReceivables_Finance_Credit) LongTermReceivables_FinanceComponent_GL
		, SUM(RS1.UnguaranteedResidual_Lease_Debit) - SUM(RS1.UnguaranteedResidual_Lease_Credit) UnguaranteedResidual_LeaseComponent_GL
		, SUM(RS1.UnguaranteedResidual_Finance_Debit) - SUM(RS1.UnguaranteedResidual_Finance_Credit) UnguaranteedResidual_FinanceComponent_GL
		, CASE
				WHEN @Residual_GP = 'False'
				THEN SUM(RS1.GuaranteedResidual_Lease_Debit) - SUM(RS1.GuaranteedResidual_Lease_Credit)
				ELSE 0
			END GuaranteedResidual_LeaseComponent_GL
		, CASE
				WHEN @Residual_GP = 'False'
				THEN SUM(RS1.GuaranteedResidual_Finance_Debit) - SUM(RS1.GuaranteedResidual_Finance_Credit)
				ELSE 0
			END GuaranteedResidual_FinanceComponent_GL
		, SUM(RS1.SalesTypeRevenue_Credit) - SUM(RS1.SalesTypeRevenue_Debit) SalesTypeRevenue_GL
		, SUM(RS1.CostOfSales_Debit) - SUM(RS1.CostOfSales_Credit) CostOfSales_GL
		, SUM(RS1.LeaseUnearnedIncome_Credit) - SUM(RS1.LeaseUnearnedIncome_Debit) LeaseUnearnedIncome_GL
		, SUM(RS1.FinanceUnearnedIncome_Credit) - SUM(RS1.FinanceUnearnedIncome_Debit) FinanceUnearnedIncome_GL
		, SUM(RS1.LeaseUnearnedResidualIncome_Credit) - SUM(RS1.LeaseUnearnedResidualIncome_Debit) LeaseUnearnedResidualIncome_GL
		, SUM(RS1.FinanceUnearnedResidualIncome_Credit) - SUM(RS1.FinanceUnearnedResidualIncome_Debit) FinanceUnearnedResidualIncome_GL
		, SUM(RS1.UnearnedSellingProfitIncome_Credit) - SUM(RS1.UnearnedSellingProfitIncome_Debit) UnearnedSellingProfitIncome_GL
		, SUM(RS1.LeaseEarnedIncome_Credit) - SUM(RS1.LeaseEarnedIncome_Debit) LeaseEarnedIncome_GL
		, SUM(RS1.FinanceEarnedIncome_Credit) - SUM(RS1.FinanceEarnedIncome_Debit) FinanceEarnedIncome_GL
		, SUM(RS1.LeaseEarnedResidualIncome_Credit) - SUM(RS1.LeaseEarnedResidualIncome_Debit) LeaseEarnedResidualIncome_GL
		, SUM(RS1.FinanceEarnedResidualIncome_Credit) - SUM(RS1.FinanceEarnedResidualIncome_Debit) FinanceEarnedResidualIncome_GL
		, SUM(RS1.EarnedSellingProfitIncome_Credit) - SUM(RS1.EarnedSellingProfitIncome_Debit) EarnedSellingProfitIncome_GL
		, SUM(RS1.LeaseRecognizedSuspendedIncome_Credit) - SUM(RS1.LeaseRecognizedSuspendedIncome_Debit) LeaseRecognizedSuspendedIncome_GL
		, SUM(RS1.FinanceRecognizedSuspendedIncome_Credit) - SUM(RS1.FinanceRecognizedSuspendedIncome_Debit) FinanceRecognizedSuspendedIncome_GL
		, SUM(RS1.LeaseRecognizedSuspendedResidualIncome_Credit) - SUM(RS1.LeaseRecognizedSuspendedResidualIncome_Debit) LeaseRecognizedSuspendedResidualIncome_GL
		, SUM(RS1.FinanceRecognizedSuspendedResidualIncome_Credit) - SUM(RS1.FinanceRecognizedSuspendedResidualIncome_Debit) FinanceRecognizedSuspendedResidualIncome_GL
		, SUM(RS1.RecognizedSuspendedSellingProfitIncome_Credit) - SUM(RS1.RecognizedSuspendedSellingProfitIncome_Debit) RecognizedSuspendedSellingProfitIncome_GL
		, SUM(RS1.GrossWriteDown_Credit) - SUM(RS1.GrossWriteDown_Debit) GrossWriteDown_GL
		, SUM(RS1.WriteDownRecovered_Credit) - SUM(WriteDownRecovered_Debit) WriteDownRecovered_GL
		, SUM(RS1.ChargeOffExpense_Debit) - SUM(RS1.ChargeOffExpense_Credit) ChargeOffExpense_GL
		, SUM(RS1.FinancingChargeOffExpense_Debit) - SUM(RS1.FinancingChargeOffExpense_Credit) FinancingChargeOffExpense_GL
		, SUM(RS1.ChargeOffRecovery_Credit) - SUM(RS1.ChargeOffRecovery_Debit) ChargeOffRecovery_GL
		, SUM(RS1.FinancingChargeOffRecovery_Credit) - SUM(RS1.FinancingChargeOffRecovery_Debit) FinancingChargeOffRecovery_GL
		, SUM(RS1.ChargeOffGainOnRecovery_Credit) - SUM(RS1.ChargeOffGainOnRecovery_Debit) ChargeOffGainOnRecovery_GL
		, SUM(RS1.FinancingChargeOffGainOnRecovery_Credit) - SUM(RS1.FinancingChargeOffGainOnRecovery_Debit) FinancingChargeOffGainOnRecovery_GL
		, SUM(RS1.UnAppliedAR_Credit) - SUM(RS1.UnAppliedAR_Debit) ContractUnAppliedAR_GL
		, SUM(RS1.GLPostedSalesTaxReceivable_Debit) - SUM(RS1.GLPostedSalesTaxReceivable_Credit) GLPostedSalesTaxReceivable_GL
		, SUM(RS1.TotalPaid_SalesTaxReceivables_Credit) - SUM(RS1.TotalPaid_SalesTaxReceivables_Debit) TotalPaid_SalesTaxReceivables_GL
		, SUM(RS1.PrePaidTaxes_Credit) - SUM(RS1.PrePaidTaxes_Debit) PrePaidTaxes_GL
		, SUM(RS1.PrePaidTaxReceivable_Debit) - SUM(RS1.PrePaidTaxReceivable_Credit) PrePaidTaxReceivable_GL
		, SUM(RS1.TaxReceivablePosted_Debit) - SUM(RS1.TaxReceivablePosted_Credit) TaxReceivablePosted_GL
		, SUM(RS1.TaxReceivablesPaid_Credit) - SUM(RS1.TaxReceivablesPaid_Debit) TaxReceivablesPaid_GL
		, SUM(RS1.Paid_SalesTaxReceivablesviaCash_Credit) - SUM(RS1.Paid_SalesTaxReceivablesviaCash_Debit) Paid_SalesTaxReceivablesviaCash_GL
		, SUM(RS1.Paid_SalesTaxReceivablesviaNonCash_Credit) - SUM(RS1.Paid_SalesTaxReceivablesviaNonCash_Debit) Paid_SalesTaxReceivablesviaNonCash_GL

		, SUM(RS1.CapitalizedSalesTax_Credit) - SUM(RS1.CapitalizedSalesTax_Debit) CapitalizedSalesTax_GL
		, SUM(RS1.CapitalizedAdditionalCharge_Credit) - SUM(RS1.CapitalizedAdditionalCharge_Debit) CapitalizedAdditionalCharge_GL
		, SUM(RS1.CapitalizedInterimInterest_Credit) - SUM(RS1.CapitalizedInterimInterest_Debit) CapitalizedInterimInterest_GL
		, SUM(RS1.CapitalizedInterimRent_Credit) - SUM(RS1.CapitalizedInterimRent_Debit) CapitalizedInterimRent_GL

		,SUM(RS1.InterimRentReceivable_Debit - RS1.InterimRentReceivable_Credit) + SUM(RS1.PrepaidInterimRentReceivable_Debit - RS1.PrepaidInterimRentReceivable_Credit) [TotalGLPosted_InterimRentReceivables_GL]
		,SUM(RS1.CashInterimRentReceivable_Credit - RS1.CashInterimRentReceivable_Debit) + SUM(RS1.NonCashInterimRentReceivable_Credit - RS1.NonCashInterimRentReceivable_Debit) + SUM(RS1.CashPrepaidInterimRentReceivable_Credit - RS1.CashPrepaidInterimRentReceivable_Debit) + SUM(RS1.NonCashPrepaidInterimRentReceivable_Credit - RS1.NonCashPrepaidInterimRentReceivable_Debit) [TotalPaid_InterimRentReceivables_GL]
		,SUM(RS1.CashInterimRentReceivable_Credit - RS1.CashInterimRentReceivable_Debit) + SUM(RS1.CashPrepaidInterimRentReceivable_Credit - RS1.CashPrepaidInterimRentReceivable_Debit) [TotalPaidviaCash_InterimRentReceivables_GL]
		,SUM(RS1.NonCashInterimRentReceivable_Credit - RS1.NonCashInterimRentReceivable_Debit) + SUM(RS1.NonCashPrepaidInterimRentReceivable_Credit - RS1.NonCashPrepaidInterimRentReceivable_Debit) [TotalPaidviaNonCash_InterimRentReceivables_GL]
		,(SUM(RS1.CashPrepaidInterimRentReceivable_Credit - RS1.CashPrepaidInterimRentReceivable_Debit) + SUM(RS1.NonCashPrepaidInterimRentReceivable_Credit - RS1.NonCashPrepaidInterimRentReceivable_Debit)) - SUM(RS1.PrepaidInterimRentReceivable_Debit - RS1.PrepaidInterimRentReceivable_Credit) [TotalPrepaid_InterimRentReceivables_GL]
		,SUM(RS1.InterimRentReceivable_Debit - RS1.InterimRentReceivable_Credit) - (SUM(RS1.CashInterimRentReceivable_Credit - RS1.CashInterimRentReceivable_Debit) + SUM(RS1.NonCashInterimRentReceivable_Credit - RS1.NonCashInterimRentReceivable_Debit)) [TotalOutstanding_InterimRentReceivables_GL]
		,SUM(RS1.InterimRentIncome_Credit - RS1.InterimRentIncome_Debit) [GLPosted_InterimRentIncome_GL]
		,SUM(RS1.DeferCapitalizedInterimRent_Credit - DeferCapitalizedInterimRent_Debit) [TotalCapitalizedIncome_InterimRentIncome_GL]
		,SUM(RS1.BookingDeferredInterimRentIncome_Debit - RS1.BookingDeferredInterimRentIncome_Credit) [BookingDeferredInterimRentIncome_GL]
		,SUM(RS1.ARDeferredInterimRentIncome_Credit - RS1.ARDeferredInterimRentIncome_Debit) [ARDeferredInterimRentIncome_GL]
		,SUM(RS1.IRDeferredInterimRentIncome_Debit - RS1.IRDeferredInterimRentIncome_Credit) [IRDeferredInterimRentIncome_GL]
		,CAST (0 AS DECIMAL (16,2)) [DeferInterimRentIncome_GL]

		,SUM(RS1.InterimInterestReceivable_Debit - RS1.InterimInterestReceivable_Credit) + SUM(RS1.PrepaidInterimInterestReceivable_Debit - RS1.PrepaidInterimInterestReceivable_Credit) [TotalGLPosted_InterimInterestReceivables_GL]
		,SUM(RS1.CashInterimInterestReceivable_Credit - RS1.CashInterimInterestReceivable_Debit) + SUM(RS1.NonCashInterimInterestReceivable_Credit - RS1.NonCashInterimInterestReceivable_Debit) + SUM(RS1.CashPrepaidInterimInterestReceivable_Credit - RS1.CashPrepaidInterimInterestReceivable_Debit) + SUM(RS1.NonCashPrepaidInterimInterestReceivable_Credit - RS1.NonCashPrepaidInterimInterestReceivable_Debit) [TotalPaid_InterimInterestReceivables_GL]
		,SUM(RS1.CashInterimInterestReceivable_Credit - RS1.CashInterimInterestReceivable_Debit) + SUM(RS1.CashPrepaidInterimInterestReceivable_Credit - RS1.CashPrepaidInterimInterestReceivable_Debit) [TotalPaidviaCash_InterimInterestReceivables_GL]
		,SUM(RS1.NonCashInterimInterestReceivable_Credit - RS1.NonCashInterimInterestReceivable_Debit) + SUM(RS1.NonCashPrepaidInterimInterestReceivable_Credit - RS1.NonCashPrepaidInterimInterestReceivable_Debit) [TotalPaidviaNonCash_InterimInterestReceivables_GL]
		,(SUM(RS1.CashPrepaidInterimInterestReceivable_Credit - RS1.CashPrepaidInterimInterestReceivable_Debit) + SUM(RS1.NonCashPrepaidInterimInterestReceivable_Credit - RS1.NonCashPrepaidInterimInterestReceivable_Debit)) - SUM(RS1.PrepaidInterimInterestReceivable_Debit - RS1.PrepaidInterimInterestReceivable_Credit) [TotalPrepaid_InterimInterestReceivables_GL]
		,SUM(RS1.InterimInterestReceivable_Debit - RS1.InterimInterestReceivable_Credit) - (SUM(RS1.CashInterimInterestReceivable_Credit - RS1.CashInterimInterestReceivable_Debit) + SUM(RS1.NonCashInterimInterestReceivable_Credit - RS1.NonCashInterimInterestReceivable_Debit)) [TotalOutstanding_InterimInterestReceivables_GL]
		,SUM(RS1.InterimInterestIncome_Credit - RS1.InterimInterestIncome_Debit) [GLPosted_InterimInterestIncome_GL]
		,SUM(RS1.DeferCapitalizedInterimInterest_Credit - RS1.DeferCapitalizedInterimInterest_Debit) [TotalCapitalizedIncome_InterimInterestIncome_GL]
		,SUM(RS1.BookingAccruedInterimInterestIncome_Debit - RS1.BookingAccruedInterimInterestIncome_Credit) [BookingAccruedInterimInterestIncome_GL]
		,SUM(RS1.ARAccruedInterimInterestIncome_Credit - RS1.ARAccruedInterimInterestIncome_Debit) [ARAccruedInterimInterestIncome_GL]
		,SUM(RS1.IRAccruedInterimInterestIncome_Debit - RS1.IRAccruedInterimInterestIncome_Credit) [IRAccruedInterimInterestIncome_GL]
		,CAST (0 AS DECIMAL (16,2)) [AccruedInterimInterestIncome_GL]

		,SUM(RS1.TotalGLPosted_Debit - RS1.TotalGLPosted_Credit) [TotalGLPosted_GL]
		,SUM(RS1.OSAR_Debit - RS1.OSAR_Credit) [OSAR_GL]
		,SUM(RS1.TotalPaid_Credit - RS1.TotalPaid_Debit) [TotalPaid_GL]
		,SUM(RS1.TotalCashPaid_Credit - RS1.TotalCashPaid_Debit) [TotalCashPaid_GL]
		,SUM(RS1.TotalNonCashPaid_Credit - RS1.TotalNonCashPaid_Debit) [TotalNonCashPaid_GL]
		,SUM(RS1.TotalPrePaid_Credit - RS1.TotalPrePaid_Debit) [TotalPrePaid_GL]
		,SUM(RS1.TotalFloatRateIncome_Credit - RS1.TotalFloatRateIncome_Debit) [TotalFloatRateIncome_GL]
		,SUM(RS1.TotalSuspendedFloatRateIncome_Credit - RS1.TotalSuspendedFloatRateIncome_Debit) [TotalSuspendedFloatRateIncome_GL]
		,SUM(RS1.TotalAccruedFloatRateIncome_Credit - RS1.TotalAccruedFloatRateIncome_Debit) [TotalAccruedFloatRateIncome_GL]

		,SUM(RS1.DueToThirdPartyAR_Debit - RS1.DueToThirdPartyAR_Credit) + SUM(RS1.PrepaidDueToThirdPartyAR_Debit - RS1.PrepaidDueToThirdPartyAR_Credit) [TotalGLPosted_FunderOwned_GL]
		,SUM(RS1.CashDueToThirdPartyAR_Credit - RS1.CashDueToThirdPartyAR_Debit) + SUM(RS1.CashPrepaidDueToThirdPartyAR_Credit - RS1.CashPrepaidDueToThirdPartyAR_Debit) [TotalPaidCash_FunderOwned_GL]
		,SUM(RS1.NonCashDueToThirdPartyAR_Credit - RS1.NonCashDueToThirdPartyAR_Debit) + SUM(RS1.NonCashPrepaidDueToThirdPartyAR_Credit - RS1.NonCashPrepaidDueToThirdPartyAR_Debit) [TotalPaidNonCash_FunderOwned_GL]
		,(SUM(RS1.CashPrepaidDueToThirdPartyAR_Credit - RS1.CashPrepaidDueToThirdPartyAR_Debit) + SUM(RS1.NonCashPrepaidDueToThirdPartyAR_Credit - RS1.NonCashPrepaidDueToThirdPartyAR_Debit)) - (SUM(RS1.PrepaidDueToThirdPartyAR_Debit - RS1.PrepaidDueToThirdPartyAR_Credit)) [TotalPrepaid_FunderOwned_GL]
		,(SUM(RS1.DueToThirdPartyAR_Debit - RS1.DueToThirdPartyAR_Credit)) - (SUM(RS1.CashDueToThirdPartyAR_Credit - RS1.CashDueToThirdPartyAR_Debit) + SUM(RS1.NonCashDueToThirdPartyAR_Credit - RS1.NonCashDueToThirdPartyAR_Debit)) [TotalOutstanding_FunderOwned_GL]

		,SUM(RS1.SyndicatedSalesTaxReceivable_Debit - RS1.SyndicatedSalesTaxReceivable_Credit) + SUM(RS1.PrepaidSyndicatedSalesTaxReceivable_Debit - RS1.PrepaidSyndicatedSalesTaxReceivable_Credit) [TotalGLPosted_FunderOwned_LessorRemit_SalesTax_GL]
		,SUM(RS1.CashSyndicatedSalesTaxReceivable_Credit - RS1.CashSyndicatedSalesTaxReceivable_Debit) + SUM(RS1.CashPrepaidSyndicatedSalesTaxReceivable_Credit - RS1.CashPrepaidSyndicatedSalesTaxReceivable_Debit) [TotalPaidCash_FunderOwned_LessorRemit_SalesTax_GL]
		,SUM(RS1.NonCashSyndicatedSalesTaxReceivable_Credit - RS1.NonCashSyndicatedSalesTaxReceivable_Debit) + SUM(RS1.NonCashPrepaidSyndicatedSalesTaxReceivable_Credit - RS1.NonCashPrepaidSyndicatedSalesTaxReceivable_Debit) [TotalPaidNonCash_FunderOwned_LessorRemit_SalesTax_GL]
		,(SUM(RS1.CashPrepaidSyndicatedSalesTaxReceivable_Credit - RS1.CashPrepaidSyndicatedSalesTaxReceivable_Debit) + SUM(RS1.NonCashPrepaidSyndicatedSalesTaxReceivable_Credit - RS1.NonCashPrepaidSyndicatedSalesTaxReceivable_Debit)) - SUM(RS1.PrepaidSyndicatedSalesTaxReceivable_Debit - RS1.PrepaidSyndicatedSalesTaxReceivable_Credit) [TotalPrepaid_FunderOwned_LessorRemit_SalesTax_GL]
		,SUM(RS1.SyndicatedSalesTaxReceivable_Debit - RS1.SyndicatedSalesTaxReceivable_Credit) - (SUM(RS1.CashSyndicatedSalesTaxReceivable_Credit - RS1.CashSyndicatedSalesTaxReceivable_Debit) + SUM(RS1.NonCashSyndicatedSalesTaxReceivable_Credit - RS1.NonCashSyndicatedSalesTaxReceivable_Debit)) [TotalOutstanding_FunderOwned_LessorRemit_SalesTax_GL]

	INTO #GLJournalDetail
	FROM
	(SELECT 
		gtb.EntityId ContractId
		,CASE
			WHEN gtb.EntryItem IN ('ShortTermLeaseReceivable','PrePaidCapitalLeaseReceivable')
			AND gtb.GlTransactionType IN ('CapitalLeaseAR')
			THEN gtb.DebitAmount
			ELSE 0
		END GLPostedReceivables_LeaseComponent_Debit
		,CASE
			WHEN gtb.EntryItem IN ('ShortTermLeaseReceivable','PrePaidCapitalLeaseReceivable')
			AND gtb.GlTransactionType IN ('CapitalLeaseAR')
			THEN gtb.CreditAmount
			ELSE 0
		END GLPostedReceivables_LeaseComponent_Credit
		,CASE
			WHEN gtb.EntryItem IN ('FinancingShortTermLeaseReceivable','FinancingPrePaidLeaseReceivable')
			AND gtb.GlTransactionType IN ('CapitalLeaseAR')
			THEN gtb.DebitAmount
			ELSE 0
		END GLPostedReceivables_FinanceComponent_Debit
		,CASE
			WHEN gtb.EntryItem IN ('FinancingShortTermLeaseReceivable','FinancingPrePaidLeaseReceivable')
			AND gtb.GlTransactionType IN ('CapitalLeaseAR')
			THEN gtb.CreditAmount
			ELSE 0
		END GLPostedReceivables_FinanceComponent_Credit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GlTransactionType IN ('ReceiptCash','ReceiptNonCash')
			AND gtb.MatchingGLTransactionType IN ('CapitalLeaseAR')
			AND gtb.MatchingEntryItem IN ('ShortTermLeaseReceivable','PrePaidCapitalLeaseReceivable')
			THEN gtb.DebitAmount
			ELSE 0
		END PaidReceivables_LeaseComponent_Debit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GlTransactionType IN ('ReceiptCash','ReceiptNonCash')
			AND gtb.MatchingGLTransactionType IN ('CapitalLeaseAR')
			AND gtb.MatchingEntryItem IN ('ShortTermLeaseReceivable','PrePaidCapitalLeaseReceivable')
			THEN gtb.CreditAmount
			ELSE 0
		END PaidReceivables_LeaseComponent_Credit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GlTransactionType IN ('ReceiptCash')
			AND gtb.MatchingGLTransactionType IN ('CapitalLeaseAR')
			AND gtb.MatchingEntryItem IN ('ShortTermLeaseReceivable','PrePaidCapitalLeaseReceivable')
			THEN gtb.DebitAmount
			ELSE 0
		END PaidReceivablesCash_LeaseComponent_Debit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GlTransactionType IN ('ReceiptCash')
			AND gtb.MatchingGLTransactionType IN ('CapitalLeaseAR')
			AND gtb.MatchingEntryItem IN ('ShortTermLeaseReceivable','PrePaidCapitalLeaseReceivable')
			THEN gtb.CreditAmount
			ELSE 0
		END PaidReceivablesCash_LeaseComponent_Credit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GlTransactionType IN ('ReceiptNonCash')
			AND gtb.MatchingGLTransactionType IN ('CapitalLeaseAR')
			AND gtb.MatchingEntryItem IN ('ShortTermLeaseReceivable','PrePaidCapitalLeaseReceivable')
			THEN gtb.DebitAmount
			ELSE 0
		END PaidReceivablesNonCash_LeaseComponent_Debit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GlTransactionType IN ('ReceiptNonCash')
			AND gtb.MatchingGLTransactionType IN ('CapitalLeaseAR')
			AND gtb.MatchingEntryItem IN ('ShortTermLeaseReceivable','PrePaidCapitalLeaseReceivable')
			THEN gtb.CreditAmount
			ELSE 0
		END PaidReceivablesNonCash_LeaseComponent_Credit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GlTransactionType IN ('ReceiptCash','ReceiptNonCash')
			AND gtb.MatchingGLTransactionType IN ('CapitalLeaseAR')
			AND gtb.MatchingEntryItem IN ('FinancingShortTermLeaseReceivable','FinancingPrePaidLeaseReceivable')
			THEN gtb.DebitAmount
			ELSE 0
		END PaidReceivables_FinanceComponent_Debit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GlTransactionType IN ('ReceiptCash','ReceiptNonCash')
			AND gtb.MatchingGLTransactionType IN ('CapitalLeaseAR')
			AND gtb.MatchingEntryItem IN ('FinancingShortTermLeaseReceivable','FinancingPrePaidLeaseReceivable')
			THEN gtb.CreditAmount
			ELSE 0
		END PaidReceivables_FinanceComponent_Credit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GlTransactionType IN ('ReceiptCash')
			AND gtb.MatchingGLTransactionType IN ('CapitalLeaseAR')
			AND gtb.MatchingEntryItem IN ('FinancingShortTermLeaseReceivable','FinancingPrePaidLeaseReceivable')
			THEN gtb.DebitAmount
			ELSE 0
		END PaidReceivablesCash_FinanceComponent_Debit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GlTransactionType IN ('ReceiptCash')
			AND gtb.MatchingGLTransactionType IN ('CapitalLeaseAR')
			AND gtb.MatchingEntryItem IN ('FinancingShortTermLeaseReceivable','FinancingPrePaidLeaseReceivable')
			THEN gtb.CreditAmount
			ELSE 0
		END PaidReceivablesCash_FinanceComponent_Credit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GlTransactionType IN ('ReceiptNonCash')
			AND gtb.MatchingGLTransactionType IN ('CapitalLeaseAR')
			AND gtb.MatchingEntryItem IN ('FinancingShortTermLeaseReceivable','FinancingPrePaidLeaseReceivable')
			THEN gtb.DebitAmount
			ELSE 0
		END PaidReceivablesNonCash_FinanceComponent_Debit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GlTransactionType IN ('ReceiptNonCash')
			AND gtb.MatchingGLTransactionType IN ('CapitalLeaseAR')
			AND gtb.MatchingEntryItem IN ('FinancingShortTermLeaseReceivable','FinancingPrePaidLeaseReceivable')
			THEN gtb.CreditAmount
			ELSE 0
		END PaidReceivablesNonCash_FinanceComponent_Credit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GlTransactionType IN ('ReceiptCash','ReceiptNonCash')
			AND gtb.MatchingGLTransactionType IN ('CapitalLeaseAR')
			AND gtb.MatchingEntryItem IN ('PrePaidCapitalLeaseReceivable')
			THEN gtb.DebitAmount
			ELSE 0
		END PrePaidReceivablesPosted_Lease_Debit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GlTransactionType IN ('ReceiptCash','ReceiptNonCash')
			AND gtb.MatchingGLTransactionType IN ('CapitalLeaseAR')
			AND gtb.MatchingEntryItem IN ('PrePaidCapitalLeaseReceivable')
			THEN gtb.CreditAmount
			ELSE 0
		END PrePaidReceivablesPosted_Lease_Credit
		,CASE
			WHEN gtb.EntryItem IN ('PrePaidCapitalLeaseReceivable')
			AND gtb.GlTransactionType IN ('CapitalLeaseAR')
			THEN gtb.DebitAmount
			ELSE 0
		END PrePaidReceivablesPaid_Lease_Debit
		,CASE
			WHEN gtb.EntryItem IN ('PrePaidCapitalLeaseReceivable')
			AND gtb.GlTransactionType IN ('CapitalLeaseAR')
			THEN gtb.CreditAmount
			ELSE 0
		END PrePaidReceivablesPaid_Lease_Credit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GlTransactionType IN ('ReceiptCash','ReceiptNonCash')
			AND gtb.MatchingGLTransactionType IN ('CapitalLeaseAR')
			AND gtb.MatchingEntryItem IN ('FinancingPrePaidLeaseReceivable')
			THEN gtb.DebitAmount
			ELSE 0
		END PrePaidReceivablesPosted_Finance_Debit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GlTransactionType IN ('ReceiptCash','ReceiptNonCash')
			AND gtb.MatchingGLTransactionType IN ('CapitalLeaseAR')
			AND gtb.MatchingEntryItem IN ('FinancingPrePaidLeaseReceivable')
			THEN gtb.CreditAmount
			ELSE 0
		END PrePaidReceivablesPosted_Finance_Credit
		,CASE
			WHEN gtb.EntryItem IN ('FinancingPrePaidLeaseReceivable')
			AND gtb.GlTransactionType IN ('CapitalLeaseAR')
			THEN gtb.DebitAmount
			ELSE 0
		END PrePaidReceivablesPaid_Finance_Debit
		,CASE
			WHEN gtb.EntryItem IN ('FinancingPrePaidLeaseReceivable')
			AND gtb.GlTransactionType IN ('CapitalLeaseAR')
			THEN gtb.CreditAmount
			ELSE 0
		END PrePaidReceivablesPaid_Finance_Credit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GlTransactionType IN ('ReceiptCash','ReceiptNonCash')
			AND gtb.MatchingGLTransactionType IN ('CapitalLeaseAR')
			AND gtb.MatchingEntryItem IN ('ShortTermLeaseReceivable')
			THEN gtb.DebitAmount
			ELSE 0
		END ReceiptPosted_Lease_Debit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GlTransactionType IN ('ReceiptCash','ReceiptNonCash')
			AND gtb.MatchingGLTransactionType IN ('CapitalLeaseAR')
			AND gtb.MatchingEntryItem IN ('ShortTermLeaseReceivable')
			THEN gtb.CreditAmount
			ELSE 0
		END ReceiptPosted_Lease_Credit
		,CASE
			WHEN gtb.EntryItem IN ('ShortTermLeaseReceivable')
			AND gtb.GlTransactionType IN ('CapitalLeaseAR')
			THEN gtb.DebitAmount
			ELSE 0
		END ReceivablesPosted_Lease_Debit
		,CASE
			WHEN gtb.EntryItem IN ('ShortTermLeaseReceivable')
			AND gtb.GlTransactionType IN ('CapitalLeaseAR')
			THEN gtb.CreditAmount
			ELSE 0
		END ReceivablesPosted_Lease_Credit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GlTransactionType IN ('ReceiptCash','ReceiptNonCash')
			AND gtb.MatchingGLTransactionType IN ('CapitalLeaseAR')
			AND gtb.MatchingEntryItem IN ('FinancingShortTermLeaseReceivable')
			THEN gtb.DebitAmount
			ELSE 0
		END ReceiptPosted_Finance_Debit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GlTransactionType IN ('ReceiptCash','ReceiptNonCash')
			AND gtb.MatchingGLTransactionType IN ('CapitalLeaseAR')
			AND gtb.MatchingEntryItem IN ('FinancingShortTermLeaseReceivable')
			THEN gtb.CreditAmount
			ELSE 0
		END ReceiptPosted_Finance_Credit
		,CASE
			WHEN gtb.EntryItem IN ('FinancingShortTermLeaseReceivable')
			AND gtb.GlTransactionType IN ('CapitalLeaseAR')
			THEN gtb.DebitAmount
			ELSE 0
		END ReceivablesPosted_Finance_Debit
		,CASE
			WHEN gtb.EntryItem IN ('FinancingShortTermLeaseReceivable')
			AND gtb.GlTransactionType IN ('CapitalLeaseAR')
			THEN gtb.CreditAmount
			ELSE 0
		END ReceivablesPosted_Finance_Credit
		,CASE
			WHEN gtb.EntryItem IN ('LongTermLeaseReceivable')
			AND gtb.GlTransactionType IN ('CapitalLeaseAR','CapitalLeaseBooking','CapitalLeasePayoff','CapitalLeaseChargeoff')
			THEN gtb.CreditAmount
			ELSE 0
		END LongTermReceivables_Lease_Credit
		,CASE
			WHEN gtb.EntryItem IN ('LongTermLeaseReceivable')
			AND gtb.GlTransactionType IN ('CapitalLeaseAR','CapitalLeaseBooking','CapitalLeasePayoff','CapitalLeaseChargeoff')
			THEN gtb.DebitAmount
			ELSE 0
		END LongTermReceivables_Lease_Debit
		,CASE
			WHEN gtb.EntryItem IN ('FinancingLongTermLeaseReceivable')
			AND gtb.GlTransactionType IN ('CapitalLeaseAR','CapitalLeaseBooking','CapitalLeasePayoff','CapitalLeaseChargeoff')
			THEN gtb.DebitAmount
			ELSE 0
		END LongTermReceivables_Finance_Debit
		,CASE
			WHEN gtb.EntryItem IN ('FinancingLongTermLeaseReceivable')
			AND gtb.GlTransactionType IN ('CapitalLeaseAR','CapitalLeaseBooking','CapitalLeasePayoff','CapitalLeaseChargeoff')
			THEN gtb.CreditAmount
			ELSE 0
		END LongTermReceivables_Finance_Credit
		,CASE
			WHEN gtb.EntryItem IN ('UnguaranteedResidualBooked')
			AND gtb.GlTransactionType IN ('ResidualImpairment','CapitalLeaseBooking','CapitalLeasePayoff','CapitalLeaseChargeoff','OTPIncome')
			THEN gtb.DebitAmount
			ELSE 0
		END UnguaranteedResidual_Lease_Debit
		,CASE
			WHEN gtb.EntryItem IN ('UnguaranteedResidualBooked')
			AND gtb.GlTransactionType IN ('ResidualImpairment','CapitalLeaseBooking','CapitalLeasePayoff','CapitalLeaseChargeoff','OTPIncome')
			THEN gtb.CreditAmount
			ELSE 0
		END UnguaranteedResidual_Lease_Credit
		,CASE
			WHEN gtb.EntryItem IN ('FinancingUnguaranteedResidualBooked')
			AND gtb.GlTransactionType IN ('ResidualImpairment','CapitalLeaseBooking','CapitalLeasePayoff','CapitalLeaseChargeoff','OTPIncome')
			THEN gtb.DebitAmount
			ELSE 0
		END UnguaranteedResidual_Finance_Debit
		,CASE
			WHEN gtb.EntryItem IN ('FinancingUnguaranteedResidualBooked')
			AND gtb.GlTransactionType IN ('ResidualImpairment','CapitalLeaseBooking','CapitalLeasePayoff','CapitalLeaseChargeoff','OTPIncome')
			THEN gtb.CreditAmount
			ELSE 0
		END UnguaranteedResidual_Finance_Credit
		,CASE
			WHEN gtb.EntryItem IN ('GuaranteedResidual')
			AND gtb.GlTransactionType IN ('ResidualImpairment','CapitalLeaseBooking','CapitalLeasePayoff','CapitalLeaseChargeoff','OTPIncome')
			THEN gtb.DebitAmount
			ELSE 0
		END GuaranteedResidual_Lease_Debit
		,CASE
			WHEN gtb.EntryItem IN ('GuaranteedResidual')
			AND gtb.GlTransactionType IN ('ResidualImpairment','CapitalLeaseBooking','CapitalLeasePayoff','CapitalLeaseChargeoff','OTPIncome')
			THEN gtb.CreditAmount
			ELSE 0
		END GuaranteedResidual_Lease_Credit
		,CASE
			WHEN gtb.EntryItem IN ('FinancingGuaranteedResidual')
			AND gtb.GlTransactionType IN ('ResidualImpairment','CapitalLeaseBooking','CapitalLeasePayoff','CapitalLeaseChargeoff','OTPIncome')
			THEN gtb.DebitAmount
			ELSE 0
		END GuaranteedResidual_Finance_Debit
		,CASE
			WHEN gtb.EntryItem IN ('FinancingGuaranteedResidual')
			AND gtb.GlTransactionType IN ('ResidualImpairment','CapitalLeaseBooking','CapitalLeasePayoff','CapitalLeaseChargeoff','OTPIncome')
			THEN gtb.CreditAmount
			ELSE 0
		END GuaranteedResidual_Finance_Credit
		,CASE
			WHEN gtb.EntryItem IN ('UnearnedIncome')
			AND gtb.GLTransactionType IN ('CapitalLeaseBooking','CapitalLeasePayoff','CapitalLeaseChargeoff','CapitalLeaseIncome','BlendedIncomeSetup')
			THEN gtb.CreditAmount
			ELSE 0
		END LeaseUnearnedIncome_Credit
		,CASE
			WHEN gtb.EntryItem IN ('UnearnedIncome')
			AND gtb.GLTransactionType IN ('CapitalLeaseBooking','CapitalLeasePayoff','CapitalLeaseChargeoff','CapitalLeaseIncome','BlendedIncomeSetup')
			THEN gtb.DebitAmount
			ELSE 0
		END LeaseUnearnedIncome_Debit
		,CASE
			WHEN gtb.EntryItem IN ('FinancingUnearnedIncome')
			AND gtb.GLTransactionType IN ('CapitalLeaseBooking','CapitalLeasePayoff','CapitalLeaseChargeoff','CapitalLeaseIncome','BlendedIncomeSetup')
			THEN gtb.CreditAmount
			ELSE 0
		END FinanceUnearnedIncome_Credit
		,CASE
			WHEN gtb.EntryItem IN ('FinancingUnearnedIncome')
			AND gtb.GLTransactionType IN ('CapitalLeaseBooking','CapitalLeasePayoff','CapitalLeaseChargeoff','CapitalLeaseIncome','BlendedIncomeSetup')
			THEN gtb.DebitAmount
			ELSE 0
		END FinanceUnearnedIncome_Debit
		,CASE
			WHEN gtb.EntryItem IN ('UnearnedUnguaranteedResidualIncome')
			AND gtb.GLTransactionType IN ('CapitalLeaseBooking','CapitalLeasePayoff','CapitalLeaseChargeoff','CapitalLeaseIncome','ResidualImpairment')
			THEN gtb.CreditAmount
			ELSE 0
		END LeaseUnearnedResidualIncome_Credit
		,CASE
			WHEN gtb.EntryItem IN ('UnearnedUnguaranteedResidualIncome')
			AND gtb.GLTransactionType IN ('CapitalLeaseBooking','CapitalLeasePayoff','CapitalLeaseChargeoff','CapitalLeaseIncome','ResidualImpairment')
			THEN gtb.DebitAmount
			ELSE 0
		END LeaseUnearnedResidualIncome_Debit
		,CASE
			WHEN gtb.EntryItem IN ('FinancingUnearnedUnguaranteedResidualIncome')
			AND gtb.GLTransactionType IN ('CapitalLeaseBooking','CapitalLeasePayoff','CapitalLeaseChargeoff','CapitalLeaseIncome','ResidualImpairment')
			THEN gtb.CreditAmount
			ELSE 0
		END FinanceUnearnedResidualIncome_Credit
		,CASE
			WHEN gtb.EntryItem IN ('FinancingUnearnedUnguaranteedResidualIncome')
			AND gtb.GLTransactionType IN ('CapitalLeaseBooking','CapitalLeasePayoff','CapitalLeaseChargeoff','CapitalLeaseIncome','ResidualImpairment')
			THEN gtb.DebitAmount
			ELSE 0
		END FinanceUnearnedResidualIncome_Debit
		,CASE
			WHEN gtb.EntryItem IN ('DeferredSellingProfit')
			AND gtb.GLTransactionType IN ('CapitalLeaseBooking','CapitalLeasePayoff','CapitalLeaseChargeoff','CapitalLeaseIncome')
			THEN gtb.CreditAmount
			ELSE 0
		END UnearnedSellingProfitIncome_Credit
		,CASE
			WHEN gtb.EntryItem IN ('DeferredSellingProfit')
			AND gtb.GLTransactionType IN ('CapitalLeaseBooking','CapitalLeasePayoff','CapitalLeaseChargeoff','CapitalLeaseIncome')
			THEN gtb.DebitAmount
			ELSE 0
		END UnearnedSellingProfitIncome_Debit
		,CASE
			WHEN gtb.EntryItem IN ('Income')
			AND gtb.GLTransactionType IN ('CapitalLeaseIncome')
			AND rl.ContractId IS NULL
			THEN gtb.CreditAmount
			WHEN gtb.EntryItem IN ('Income')
			AND gtb.GLTransactionType IN ('CapitalLeaseIncome')
			AND rl.ContractId IS NOT NULL
			AND gtb.SourceId >= rl.LeaseIncomeID
			THEN gtb.CreditAmount
			ELSE 0
		END LeaseEarnedIncome_Credit
		,CASE
			WHEN gtb.EntryItem IN ('Income')
			AND gtb.GLTransactionType IN ('CapitalLeaseIncome')
			AND rl.ContractId IS NULL
			THEN gtb.DebitAmount
			WHEN gtb.EntryItem IN ('Income')
			AND gtb.GLTransactionType IN ('CapitalLeaseIncome')
			AND rl.ContractId IS NOT NULL
			AND gtb.SourceId >= rl.LeaseIncomeID
			THEN gtb.DebitAmount
			ELSE 0
		END LeaseEarnedIncome_Debit
		,CASE
			WHEN gtb.EntryItem IN ('FinancingIncome')
			AND gtb.GLTransactionType IN ('CapitalLeaseIncome')
			AND rl.ContractId IS NULL
			THEN gtb.CreditAmount
			WHEN gtb.EntryItem IN ('FinancingIncome')
			AND gtb.GLTransactionType IN ('CapitalLeaseIncome')
			AND rl.ContractId IS NOT NULL
			AND gtb.SourceId >= rl.LeaseIncomeID
			THEN gtb.CreditAmount
			ELSE 0
		END FinanceEarnedIncome_Credit
		,CASE
			WHEN gtb.EntryItem IN ('FinancingIncome')
			AND gtb.GLTransactionType IN ('CapitalLeaseIncome')
			AND rl.ContractId IS NULL
			THEN gtb.DebitAmount
			WHEN gtb.EntryItem IN ('FinancingIncome')
			AND gtb.GLTransactionType IN ('CapitalLeaseIncome')
			AND rl.ContractId IS NOT NULL
			AND gtb.SourceId >= rl.LeaseIncomeID
			THEN gtb.DebitAmount
			ELSE 0
		END FinanceEarnedIncome_Debit
		,CASE
			WHEN gtb.EntryItem IN ('UnguaranteedResidualIncome')
			AND gtb.GLTransactionType IN ('CapitalLeaseIncome')
			AND rl.ContractId IS NULL
			THEN gtb.CreditAmount
			WHEN gtb.EntryItem IN ('UnguaranteedResidualIncome')
			AND gtb.GLTransactionType IN ('CapitalLeaseIncome')
			AND rl.ContractId IS NOT NULL
			AND gtb.SourceId >= rl.LeaseIncomeID
			THEN gtb.CreditAmount
			ELSE 0
		END LeaseEarnedResidualIncome_Credit
		,CASE
			WHEN gtb.EntryItem IN ('UnguaranteedResidualIncome')
			AND gtb.GLTransactionType IN ('CapitalLeaseIncome')
			AND rl.ContractId IS NULL
			THEN gtb.DebitAmount
			WHEN gtb.EntryItem IN ('UnguaranteedResidualIncome')
			AND gtb.GLTransactionType IN ('CapitalLeaseIncome')
			AND rl.ContractId IS NOT NULL
			AND gtb.SourceId >= rl.LeaseIncomeID
			THEN gtb.DebitAmount
			ELSE 0
		END LeaseEarnedResidualIncome_Debit
		,CASE
			WHEN gtb.EntryItem IN ('FinancingUnguaranteedResidualIncome')
			AND gtb.GLTransactionType IN ('CapitalLeaseIncome')
			AND rl.ContractId IS NULL
			THEN gtb.CreditAmount
			WHEN gtb.EntryItem IN ('FinancingUnguaranteedResidualIncome')
			AND gtb.GLTransactionType IN ('CapitalLeaseIncome')
			AND rl.ContractId IS NOT NULL
			AND gtb.SourceId >= rl.LeaseIncomeID
			THEN gtb.CreditAmount
			ELSE 0
		END FinanceEarnedResidualIncome_Credit
		,CASE
			WHEN gtb.EntryItem IN ('FinancingUnguaranteedResidualIncome')
			AND gtb.GLTransactionType IN ('CapitalLeaseIncome')
			AND rl.ContractId IS NULL
			THEN gtb.DebitAmount
			WHEN gtb.EntryItem IN ('FinancingUnguaranteedResidualIncome')
			AND gtb.GLTransactionType IN ('CapitalLeaseIncome')
			AND rl.ContractId IS NOT NULL
			AND gtb.SourceId >= rl.LeaseIncomeID
			THEN gtb.DebitAmount
			ELSE 0
		END FinanceEarnedResidualIncome_Debit
		,CASE
			WHEN gtb.EntryItem IN ('SellingProfitIncome')
			AND gtb.GLTransactionType IN ('CapitalLeaseIncome')
			AND rl.ContractId IS NULL
			THEN gtb.CreditAmount
			WHEN gtb.EntryItem IN ('SellingProfitIncome')
			AND gtb.GLTransactionType IN ('CapitalLeaseIncome')
			AND rl.ContractId IS NOT NULL
			AND gtb.SourceId >= rl.LeaseIncomeID
			THEN gtb.CreditAmount
			ELSE 0
		END EarnedSellingProfitIncome_Credit
		,CASE
			WHEN gtb.EntryItem IN ('SellingProfitIncome')
			AND gtb.GLTransactionType IN ('CapitalLeaseIncome')
			AND rl.ContractId IS NULL
			THEN gtb.DebitAmount
			WHEN gtb.EntryItem IN ('SellingProfitIncome')
			AND gtb.GLTransactionType IN ('CapitalLeaseIncome')
			AND rl.ContractId IS NOT NULL
			AND gtb.SourceId >= rl.LeaseIncomeID
			THEN gtb.DebitAmount
			ELSE 0
		END EarnedSellingProfitIncome_Debit
		,CASE
			WHEN gtb.EntryItem IN ('SuspendedIncome')
			AND gtb.GLTransactionType IN ('CapitalLeaseIncome','CapitalLeaseChargeoff')
			THEN gtb.CreditAmount
			ELSE 0
		END LeaseRecognizedSuspendedIncome_Credit
		,CASE
			WHEN gtb.EntryItem IN ('SuspendedIncome')
			AND gtb.GLTransactionType IN ('CapitalLeaseIncome','CapitalLeaseChargeoff')
			THEN gtb.DebitAmount
			ELSE 0
		END LeaseRecognizedSuspendedIncome_Debit
		,CASE
			WHEN gtb.EntryItem IN ('FinancingSuspendedIncome')
			AND gtb.GLTransactionType IN ('CapitalLeaseIncome','CapitalLeaseChargeoff')
			THEN gtb.CreditAmount
			ELSE 0
		END FinanceRecognizedSuspendedIncome_Credit
		,CASE
			WHEN gtb.EntryItem IN ('FinancingSuspendedIncome')
			AND gtb.GLTransactionType IN ('CapitalLeaseIncome','CapitalLeaseChargeoff')
			THEN gtb.DebitAmount
			ELSE 0
		END FinanceRecognizedSuspendedIncome_Debit
		,CASE
			WHEN gtb.EntryItem IN ('SuspendedUnguaranteedResidualIncome')
			AND gtb.GLTransactionType IN ('CapitalLeaseIncome','CapitalLeaseChargeoff')
			THEN gtb.CreditAmount
			ELSE 0
		END LeaseRecognizedSuspendedResidualIncome_Credit
		,CASE
			WHEN gtb.EntryItem IN ('SuspendedUnguaranteedResidualIncome')
			AND gtb.GLTransactionType IN ('CapitalLeaseIncome','CapitalLeaseChargeoff')
			THEN gtb.DebitAmount
			ELSE 0
		END LeaseRecognizedSuspendedResidualIncome_Debit
		,CASE
			WHEN gtb.EntryItem IN ('FinancingSuspendedUnguaranteedResidualIncome')
			AND gtb.GLTransactionType IN ('CapitalLeaseIncome','CapitalLeaseChargeoff')
			THEN gtb.CreditAmount
			ELSE 0
		END FinanceRecognizedSuspendedResidualIncome_Credit
		,CASE
			WHEN gtb.EntryItem IN ('FinancingSuspendedUnguaranteedResidualIncome')
			AND gtb.GLTransactionType IN ('CapitalLeaseIncome','CapitalLeaseChargeoff')
			THEN gtb.DebitAmount
			ELSE 0
		END FinanceRecognizedSuspendedResidualIncome_Debit
		,CASE
			WHEN gtb.EntryItem IN ('SuspendedSellingProfitIncome')
			AND gtb.GLTransactionType IN ('CapitalLeaseIncome','CapitalLeaseChargeoff')
			THEN gtb.CreditAmount
			ELSE 0
		END RecognizedSuspendedSellingProfitIncome_Credit
		,CASE
			WHEN gtb.EntryItem IN ('SuspendedSellingProfitIncome')
			AND gtb.GLTransactionType IN ('CapitalLeaseIncome','CapitalLeaseChargeoff')
			THEN gtb.DebitAmount
			ELSE 0
		END RecognizedSuspendedSellingProfitIncome_Debit
		,CASE
			WHEN gtb.EntryItem IN ('SalesTypeRevenue') 
			AND rl.ContractId IS NULL 
			AND gtb.GLTransactionType IN ('CapitalLeaseBooking')
			THEN gtb.CreditAmount
			WHEN gtb.EntryItem IN ('SalesTypeRevenue')
			AND gtb.GLTransactionType IN ('CapitalLeaseBooking')
			AND rl.ContractId IS NOT NULL
			AND gtb.SourceId >= rl.RenewalFinanceID
			THEN gtb.CreditAmount
			ELSE 0
		END SalesTypeRevenue_Credit
		,CASE
			WHEN gtb.EntryItem IN ('SalesTypeRevenue') 
			AND gtb.GLTransactionType IN ('CapitalLeaseBooking')
			AND rl.ContractId IS NULL
			THEN gtb.DebitAmount
			WHEN gtb.EntryItem IN ('SalesTypeRevenue')
			AND gtb.GLTransactionType IN ('CapitalLeaseBooking')
			AND rl.ContractId IS NOT NULL
			AND gtb.SourceId >= rl.RenewalFinanceID
			THEN gtb.DebitAmount
			ELSE 0
		END SalesTypeRevenue_Debit
		,CASE
			WHEN gtb.EntryItem IN ('CostOfSales')
			AND rl.ContractId IS NULL
			AND gtb.GLTransactionType IN ('CapitalLeaseBooking')
			THEN gtb.CreditAmount
			WHEN gtb.EntryItem IN ('CostOfSales')
			AND gtb.GLTransactionType IN ('CapitalLeaseBooking')
			AND rl.ContractId IS NOT NULL
			AND gtb.SourceId >= rl.RenewalFinanceID
			THEN gtb.CreditAmount
			ELSE 0
		END CostOfSales_Credit
		,CASE
			WHEN gtb.EntryItem IN ('CostOfSales')
			AND rl.ContractId IS NULL
			AND gtb.GLTransactionType IN ('CapitalLeaseBooking')
			THEN gtb.DebitAmount
			WHEN gtb.EntryItem IN ('CostOfSales')
			AND gtb.GLTransactionType IN ('CapitalLeaseBooking')
			AND rl.ContractId IS NOT NULL
			AND gtb.SourceId >= rl.RenewalFinanceID
			THEN gtb.DebitAmount
			ELSE 0
		END CostOfSales_Debit
		,CASE
			WHEN gtb.EntryItem IN ('WriteDownAccount')
			AND gtb.GLTransactionType IN ('WriteDown')
			THEN gtb.CreditAmount
			ELSE 0
		END GrossWriteDown_Credit
		,CASE
			WHEN gtb.EntryItem IN ('WriteDownAccount')
			AND gtb.GLTransactionType IN ('WriteDown')
			THEN gtb.DebitAmount
			ELSE 0
		END GrossWriteDown_Debit
		,CASE
			WHEN gtb.EntryItem IN ('WriteDownAccount')
			AND gtb.GLTransactionType IN ('WriteDownRecovery')
			THEN gtb.CreditAmount
			ELSE 0
		END WriteDownRecovered_Credit
		,CASE
			WHEN gtb.EntryItem IN ('WriteDownAccount')
			AND gtb.GLTransactionType IN ('WriteDownRecovery')
			THEN gtb.DebitAmount
			ELSE 0
		END WriteDownRecovered_Debit
		,CASE
			WHEN gtb.EntryItem IN ('ChargeOffExpense')
			THEN gtb.CreditAmount
			ELSE 0
		END ChargeOffExpense_Credit
		,CASE
			WHEN gtb.EntryItem IN ('ChargeOffExpense')
			THEN gtb.DebitAmount
			ELSE 0
		END ChargeOffExpense_Debit
		,CASE
			WHEN gtb.EntryItem IN ('FinancingChargeOffExpense')
			THEN gtb.CreditAmount
			ELSE 0
		END FinancingChargeOffExpense_Credit
		,CASE
			WHEN gtb.EntryItem IN ('FinancingChargeOffExpense')
			THEN gtb.DebitAmount
			ELSE 0
		END FinancingChargeOffExpense_Debit
		,CASE
			WHEN gtb.EntryItem IN ('ChargeOffRecovery')
			AND gtb.GLTransactionType IN ('ReceiptCash')
			THEN gtb.CreditAmount
			ELSE 0
		END ChargeOffRecovery_Credit
		,CASE
			WHEN gtb.EntryItem IN ('ChargeOffRecovery')
			AND gtb.GLTransactionType IN ('ReceiptCash')
			THEN gtb.DebitAmount
			ELSE 0
		END ChargeOffRecovery_Debit
		,CASE
			WHEN gtb.EntryItem IN ('FinancingChargeOffRecovery')
			AND gtb.GLTransactionType IN ('ReceiptCash')
			THEN gtb.CreditAmount
			ELSE 0
		END FinancingChargeOffRecovery_Credit
		,CASE
			WHEN gtb.EntryItem IN ('FinancingChargeOffRecovery')
			AND gtb.GLTransactionType IN ('ReceiptCash')
			THEN gtb.DebitAmount
			ELSE 0
		END FinancingChargeOffRecovery_Debit
		,CASE
			WHEN gtb.EntryItem IN ('GainOnRecovery')
			AND gtb.GLTransactionType IN ('ReceiptCash')
			THEN gtb.CreditAmount
			ELSE 0
		END ChargeOffGainOnRecovery_Credit
		,CASE
			WHEN gtb.EntryItem IN ('GainOnRecovery')
			AND gtb.GLTransactionType IN ('ReceiptCash')
			THEN gtb.DebitAmount
			ELSE 0
		END ChargeOffGainOnRecovery_Debit
		,CASE
			WHEN gtb.EntryItem IN ('FinancingGainOnRecovery')
			AND gtb.GLTransactionType IN ('ReceiptCash')
			THEN gtb.CreditAmount
			ELSE 0
		END FinancingChargeOffGainOnRecovery_Credit
		,CASE
			WHEN gtb.EntryItem IN ('FinancingGainOnRecovery')
			AND gtb.GLTransactionType IN ('ReceiptCash')
			THEN gtb.DebitAmount
			ELSE 0
		END FinancingChargeOffGainOnRecovery_Debit
		,CASE
			WHEN gtb.EntryItem IN ('UnAppliedAR')
			AND gtb.GLTransactionType IN ('ReceiptCash','ReceiptNonCash')
			THEN gtb.DebitAmount
			ELSE 0
		END UnAppliedAR_Debit
		,CASE
			WHEN gtb.EntryItem IN ('UnAppliedAR')
			AND gtb.GLTransactionType IN ('ReceiptCash','ReceiptNonCash')
			THEN gtb.CreditAmount
			ELSE 0
		END UnAppliedAR_Credit
		,CASE
			WHEN gtb.EntryItem IN ('SalesTaxReceivable','PrePaidSalesTaxReceivable')
			AND gtb.GLTransactionType IN ('SalesTax')
			THEN gtb.CreditAmount
			ELSE 0
		END GLPostedSalesTaxReceivable_Credit
		,CASE
			WHEN gtb.EntryItem IN ('SalesTaxReceivable','PrePaidSalesTaxReceivable')
			AND gtb.GLTransactionType IN ('SalesTax')
			THEN gtb.DebitAmount
			ELSE 0
		END GLPostedSalesTaxReceivable_Debit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GlTransactionType IN ('ReceiptCash','ReceiptNonCash')
			AND gtb.MatchingEntryItem IN ('SalesTaxReceivable','PrePaidSalesTaxReceivable')
			THEN gtb.CreditAmount
			ELSE 0
		END TotalPaid_SalesTaxReceivables_Credit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GlTransactionType IN ('ReceiptCash','ReceiptNonCash')
			AND gtb.MatchingEntryItem IN ('SalesTaxReceivable','PrePaidSalesTaxReceivable')
			THEN gtb.DebitAmount
			ELSE 0
		END TotalPaid_SalesTaxReceivables_Debit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GlTransactionType IN ('ReceiptCash')
			AND gtb.MatchingEntryItem IN ('SalesTaxReceivable','PrePaidSalesTaxReceivable')
			THEN gtb.CreditAmount
			ELSE 0
		END Paid_SalesTaxReceivablesviaCash_Credit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GlTransactionType IN ('ReceiptCash')
			AND gtb.MatchingEntryItem IN ('SalesTaxReceivable','PrePaidSalesTaxReceivable')
			THEN gtb.DebitAmount
			ELSE 0
		END Paid_SalesTaxReceivablesviaCash_Debit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GlTransactionType IN ('ReceiptNonCash')
			AND gtb.MatchingEntryItem IN ('SalesTaxReceivable','PrePaidSalesTaxReceivable')
			THEN gtb.CreditAmount
			ELSE 0
		END Paid_SalesTaxReceivablesviaNonCash_Credit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GlTransactionType IN ('ReceiptNonCash')
			AND gtb.MatchingEntryItem IN ('SalesTaxReceivable','PrePaidSalesTaxReceivable')
			THEN gtb.DebitAmount
			ELSE 0
		END Paid_SalesTaxReceivablesviaNonCash_Debit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GlTransactionType IN ('ReceiptCash','ReceiptNonCash')
			AND gtb.MatchingEntryItem IN ('PrePaidSalesTaxReceivable')
			THEN gtb.CreditAmount
			ELSE 0
		END PrePaidTaxes_Credit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GlTransactionType IN ('ReceiptCash','ReceiptNonCash')
			AND gtb.MatchingEntryItem IN ('PrePaidSalesTaxReceivable')
			THEN gtb.DebitAmount
			ELSE 0
		END PrePaidTaxes_Debit
		,CASE
			WHEN gtb.EntryItem IN ('PrePaidSalesTaxReceivable')
			AND gtb.GLTransactionType IN ('SalesTax')
			THEN gtb.CreditAmount
			ELSE 0
		END PrePaidTaxReceivable_Credit
		,CASE
			WHEN gtb.EntryItem IN ('PrePaidSalesTaxReceivable')
			AND gtb.GLTransactionType IN ('SalesTax')
			THEN gtb.DebitAmount
			ELSE 0
		END PrePaidTaxReceivable_Debit
		,CASE
			WHEN gtb.EntryItem IN ('SalesTaxReceivable')
			AND gtb.GLTransactionType IN ('SalesTax')
			THEN gtb.CreditAmount
			ELSE 0
		END TaxReceivablePosted_Credit
		,CASE
			WHEN gtb.EntryItem IN ('SalesTaxReceivable')
			AND gtb.GLTransactionType IN ('SalesTax')
			THEN gtb.DebitAmount
			ELSE 0
		END TaxReceivablePosted_Debit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GlTransactionType IN ('ReceiptCash','ReceiptNonCash')
			AND gtb.MatchingEntryItem IN ('SalesTaxReceivable')
			THEN gtb.CreditAmount
			ELSE 0
		END TaxReceivablesPaid_Credit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GlTransactionType IN ('ReceiptCash','ReceiptNonCash')
			AND gtb.MatchingEntryItem IN ('SalesTaxReceivable')
			THEN gtb.DebitAmount
			ELSE 0
		END TaxReceivablesPaid_Debit
		,CASE
			WHEN gtb.EntryItem IN ('SalesTaxPayable')
			AND gtb.GLTransactionType IN ('CapitalLeaseBooking')
			AND (rl.ContractId IS NULL OR (rl.ContractId IS NOT NULL AND gtb.SourceId >= rl.RenewalFinanceId))
			THEN gtb.CreditAmount
			ELSE 0
		END CapitalizedSalesTax_Credit
		,CASE
			WHEN gtb.EntryItem IN ('SalesTaxPayable')
			AND gtb.GLTransactionType IN ('CapitalLeaseBooking')
			AND (rl.ContractId IS NULL OR (rl.ContractId IS NOT NULL AND gtb.SourceId >= rl.RenewalFinanceId))
			THEN gtb.DebitAmount
			ELSE 0
		END CapitalizedSalesTax_Debit
		,CASE
			WHEN gtb.EntryItem IN ('CapitalizedAdditionalFee')
			AND gtb.GLTransactionType IN ('CapitalLeaseBooking')
			AND (rl.ContractId IS NULL OR (rl.ContractId IS NOT NULL AND gtb.SourceId >= rl.RenewalFinanceId))
			THEN gtb.CreditAmount
			ELSE 0
		END CapitalizedAdditionalCharge_Credit
		,CASE
			WHEN gtb.EntryItem IN ('CapitalizedAdditionalFee')
			AND gtb.GLTransactionType IN ('CapitalLeaseBooking')
			AND (rl.ContractId IS NULL OR (rl.ContractId IS NOT NULL AND gtb.SourceId >= rl.RenewalFinanceId))
			THEN gtb.DebitAmount
			ELSE 0
		END CapitalizedAdditionalCharge_Debit
		,CASE
			WHEN gtb.EntryItem IN ('CapitalizedInterimInterest')
			AND gtb.GLTransactionType IN ('CapitalLeaseBooking')
			AND (rl.ContractId IS NULL OR (rl.ContractId IS NOT NULL AND gtb.SourceId >= rl.RenewalFinanceId))
			THEN gtb.CreditAmount
			ELSE 0
		END CapitalizedInterimInterest_Credit
		,CASE
			WHEN gtb.EntryItem IN ('CapitalizedInterimInterest')
			AND gtb.GLTransactionType IN ('CapitalLeaseBooking')
			AND (rl.ContractId IS NULL OR (rl.ContractId IS NOT NULL AND gtb.SourceId >= rl.RenewalFinanceId))
			THEN gtb.DebitAmount
			ELSE 0
		END CapitalizedInterimInterest_Debit
		,CASE
			WHEN gtb.EntryItem IN ('CapitalizedInterimRent')
			AND gtb.GLTransactionType IN ('CapitalLeaseBooking')
			AND (rl.ContractId IS NULL OR (rl.ContractId IS NOT NULL AND gtb.SourceId >= rl.RenewalFinanceId))
			THEN gtb.CreditAmount
			ELSE 0
		END CapitalizedInterimRent_Credit
		,CASE
			WHEN gtb.EntryItem IN ('CapitalizedInterimRent')
			AND gtb.GLTransactionType IN ('CapitalLeaseBooking')
			AND (rl.ContractId IS NULL OR (rl.ContractId IS NOT NULL AND gtb.SourceId >= rl.RenewalFinanceId))
			THEN gtb.DebitAmount
			ELSE 0
		END CapitalizedInterimRent_Debit
		,CASE
			WHEN gtb.EntryItem IN ('InterimRentReceivable')
			AND gtb.GLTransactionType IN ('InterimRentAR')
			AND rl.ContractId IS NULL
			THEN gtb.CreditAmount
			ELSE 0
		END InterimRentReceivable_Credit
		,CASE
			WHEN gtb.EntryItem IN ('InterimRentReceivable')
			AND gtb.GLTransactionType IN ('InterimRentAR')
			AND rl.ContractId IS NULL
			THEN gtb.DebitAmount
			ELSE 0
		END InterimRentReceivable_Debit
		,CASE
			WHEN gtb.EntryItem IN ('PrepaidInterimRentReceivable')
			AND gtb.GLTransactionType IN ('InterimRentAR')
			AND rl.ContractId IS NULL
			THEN gtb.CreditAmount
			ELSE 0
		END PrepaidInterimRentReceivable_Credit
		,CASE
			WHEN gtb.EntryItem IN ('PrepaidInterimRentReceivable')
			AND gtb.GLTransactionType IN ('InterimRentAR')
			AND rl.ContractId IS NULL
			THEN gtb.DebitAmount
			ELSE 0
		END PrepaidInterimRentReceivable_Debit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GLTransactionType IN ('ReceiptCash')
			AND gtb.MatchingEntryItem IN ('InterimRentReceivable')
			AND gtb.MatchingGLTransactionType IN ('InterimRentAR')
			AND rl.ContractId IS NULL
			THEN gtb.CreditAmount
			ELSE 0
		END CashInterimRentReceivable_Credit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GLTransactionType IN ('ReceiptCash')
			AND gtb.MatchingEntryItem IN ('InterimRentReceivable')
			AND gtb.MatchingGLTransactionType IN ('InterimRentAR')
			AND rl.ContractId IS NULL
			THEN gtb.DebitAmount
			ELSE 0
		END CashInterimRentReceivable_Debit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GLTransactionType IN ('ReceiptNonCash')
			AND gtb.MatchingEntryItem IN ('InterimRentReceivable')
			AND gtb.MatchingGLTransactionType IN ('InterimRentAR')
			AND rl.ContractId IS NULL
			THEN gtb.CreditAmount
			ELSE 0
		END NonCashInterimRentReceivable_Credit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GLTransactionType IN ('ReceiptNonCash')
			AND gtb.MatchingEntryItem IN ('InterimRentReceivable')
			AND gtb.MatchingGLTransactionType IN ('InterimRentAR')
			AND rl.ContractId IS NULL
			THEN gtb.DebitAmount
			ELSE 0
		END NonCashInterimRentReceivable_Debit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GLTransactionType IN ('ReceiptCash')
			AND gtb.MatchingEntryItem IN ('PrePaidInterimRentReceivable')
			AND gtb.MatchingGLTransactionType IN ('InterimRentAR')
			AND rl.ContractId IS NULL
			THEN gtb.CreditAmount
			ELSE 0
		END CashPrepaidInterimRentReceivable_Credit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GLTransactionType IN ('ReceiptCash')
			AND gtb.MatchingEntryItem IN ('PrePaidInterimRentReceivable')
			AND gtb.MatchingGLTransactionType IN ('InterimRentAR')
			AND rl.ContractId IS NULL
			THEN gtb.DebitAmount
			ELSE 0
		END CashPrepaidInterimRentReceivable_Debit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GLTransactionType IN ('ReceiptNonCash')
			AND gtb.MatchingEntryItem IN ('PrePaidInterimRentReceivable')
			AND gtb.MatchingGLTransactionType IN ('InterimRentAR')
			AND rl.ContractId IS NULL
			THEN gtb.CreditAmount
			ELSE 0
		END NonCashPrepaidInterimRentReceivable_Credit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GLTransactionType IN ('ReceiptNonCash')
			AND gtb.MatchingEntryItem IN ('PrePaidInterimRentReceivable')
			AND gtb.MatchingGLTransactionType IN ('InterimRentAR')
			AND rl.ContractId IS NULL
			THEN gtb.DebitAmount
			ELSE 0
		END NonCashPrepaidInterimRentReceivable_Debit
		,CASE
			WHEN gtb.EntryItem IN ('InterimRentIncome')
			AND gtb.GLTransactionType IN ('LeaseInterimRentIncome')
			AND @DeferInterimRentIncomeRecognition = 'False'
				AND ((booking.InterimRentBillingType = 'Periodic')
					OR (booking.InterimRentBillingType = 'SingleInstallment' 
						AND @DeferInterimRentIncomeRecognitionForSingleInstallment = 'False'))
			AND rl.ContractId IS NULL
			THEN gtb.CreditAmount
			ELSE 0
		END InterimRentIncome_Credit
		,CASE
			WHEN gtb.EntryItem IN ('InterimRentIncome')
			AND gtb.GLTransactionType IN ('LeaseInterimRentIncome')
			AND @DeferInterimRentIncomeRecognition = 'False'
				AND ((booking.InterimRentBillingType = 'Periodic')
					OR (booking.InterimRentBillingType = 'SingleInstallment' 
						AND @DeferInterimRentIncomeRecognitionForSingleInstallment = 'False'))
			AND rl.ContractId IS NULL
			THEN gtb.DebitAmount
			ELSE 0
		END InterimRentIncome_Debit
		,CASE
			WHEN gtb.EntryItem IN ('CapitalizedInterimRent')
			AND gtb.GLTransactionType IN ('CapitalLeaseBooking')
			AND gtb.MatchingEntryItem IN ('DeferredInterimRentIncome')
			AND booking.InterimRentBillingType = 'Capitalize'
				AND @DeferInterimRentIncomeRecognition = 'False'
			AND rl.ContractId IS NULL
			THEN gtb.CreditAmount
			ELSE 0
		END DeferCapitalizedInterimRent_Credit
		,CASE
			WHEN gtb.EntryItem IN ('CapitalizedInterimRent')
			AND gtb.GLTransactionType IN ('CapitalLeaseBooking')
			AND gtb.MatchingEntryItem IN ('DeferredInterimRentIncome')
			AND booking.InterimRentBillingType = 'Capitalize'
				AND @DeferInterimRentIncomeRecognition = 'False'
			AND rl.ContractId IS NULL
			THEN gtb.DebitAmount
			ELSE 0
		END DeferCapitalizedInterimRent_Debit
		,CASE
			WHEN gtb.EntryItem IN ('DeferredInterimRentIncome')
			AND gtb.GLTransactionType IN ('CapitalLeaseBooking')
			AND rl.ContractId IS NULL
			THEN gtb.CreditAmount
			ELSE 0
		END BookingDeferredInterimRentIncome_Credit
		,CASE
			WHEN gtb.EntryItem IN ('DeferredInterimRentIncome')
			AND gtb.GLTransactionType IN ('CapitalLeaseBooking')
			AND rl.ContractId IS NULL
			THEN gtb.DebitAmount
			ELSE 0
		END BookingDeferredInterimRentIncome_Debit
		,CASE
			WHEN gtb.EntryItem IN ('DeferredInterimRentIncome')
			AND gtb.GLTransactionType IN ('InterimRentAR')
			AND rl.ContractId IS NULL
			THEN gtb.CreditAmount
			ELSE 0
		END ARDeferredInterimRentIncome_Credit
		,CASE
			WHEN gtb.EntryItem IN ('DeferredInterimRentIncome')
			AND gtb.GLTransactionType IN ('InterimRentAR')
			AND rl.ContractId IS NULL
			THEN gtb.DebitAmount
			ELSE 0
		END ARDeferredInterimRentIncome_Debit
		,CASE
			WHEN gtb.EntryItem IN ('DeferredInterimRentIncome')
			AND gtb.GLTransactionType IN ('LeaseInterimRentIncome')
			AND rl.ContractId IS NULL
			THEN gtb.CreditAmount
			ELSE 0
		END IRDeferredInterimRentIncome_Credit
		,CASE
			WHEN gtb.EntryItem IN ('DeferredInterimRentIncome')
			AND gtb.GLTransactionType IN ('LeaseInterimRentIncome')
			AND rl.ContractId IS NULL
			THEN gtb.DebitAmount
			ELSE 0
		END IRDeferredInterimRentIncome_Debit
		,CASE
			WHEN gtb.EntryItem IN ('LeaseInterimInterestReceivable')
			AND gtb.GLTransactionType IN ('LeaseInterimInterestAR')
			AND rl.ContractId IS NULL
			THEN gtb.CreditAmount
			ELSE 0
		END InterimInterestReceivable_Credit
		,CASE
			WHEN gtb.EntryItem IN ('LeaseInterimInterestReceivable')
			AND gtb.GLTransactionType IN ('LeaseInterimInterestAR')
			AND rl.ContractId IS NULL
			THEN gtb.DebitAmount
			ELSE 0
		END InterimInterestReceivable_Debit
		,CASE
			WHEN gtb.EntryItem IN ('PrepaidLeaseInterimInterestReceivable')
			AND gtb.GLTransactionType IN ('LeaseInterimInterestAR')
			AND rl.ContractId IS NULL
			THEN gtb.CreditAmount
			ELSE 0
		END PrepaidInterimInterestReceivable_Credit
		,CASE
			WHEN gtb.EntryItem IN ('PrepaidLeaseInterimInterestReceivable')
			AND gtb.GLTransactionType IN ('LeaseInterimInterestAR')
			AND rl.ContractId IS NULL
			THEN gtb.DebitAmount
			ELSE 0
		END PrepaidInterimInterestReceivable_Debit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GLTransactionType IN ('ReceiptCash')
			AND gtb.MatchingEntryItem IN ('LeaseInterimInterestReceivable')
			AND gtb.MatchingGLTransactionType IN ('LeaseInterimInterestAR')
			AND rl.ContractId IS NULL
			THEN gtb.CreditAmount
			ELSE 0
		END CashInterimInterestReceivable_Credit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GLTransactionType IN ('ReceiptCash')
			AND gtb.MatchingEntryItem IN ('LeaseInterimInterestReceivable')
			AND gtb.MatchingGLTransactionType IN ('LeaseInterimInterestAR')
			AND rl.ContractId IS NULL
			THEN gtb.DebitAmount
			ELSE 0
		END CashInterimInterestReceivable_Debit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GLTransactionType IN ('ReceiptNonCash')
			AND gtb.MatchingEntryItem IN ('LeaseInterimInterestReceivable')
			AND gtb.MatchingGLTransactionType IN ('LeaseInterimInterestAR')
			AND rl.ContractId IS NULL
			THEN gtb.CreditAmount
			ELSE 0
		END NonCashInterimInterestReceivable_Credit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GLTransactionType IN ('ReceiptNonCash')
			AND gtb.MatchingEntryItem IN ('LeaseInterimInterestReceivable')
			AND gtb.MatchingGLTransactionType IN ('LeaseInterimInterestAR')
			AND rl.ContractId IS NULL
			THEN gtb.DebitAmount
			ELSE 0
		END NonCashInterimInterestReceivable_Debit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GLTransactionType IN ('ReceiptCash')
			AND gtb.MatchingEntryItem IN ('PrepaidLeaseInterimInterestReceivable')
			AND gtb.MatchingGLTransactionType IN ('LeaseInterimInterestAR')
			AND rl.ContractId IS NULL
			THEN gtb.CreditAmount
			ELSE 0
		END CashPrepaidInterimInterestReceivable_Credit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GLTransactionType IN ('ReceiptCash')
			AND gtb.MatchingEntryItem IN ('PrepaidLeaseInterimInterestReceivable')
			AND gtb.MatchingGLTransactionType IN ('LeaseInterimInterestAR')
			AND rl.ContractId IS NULL
			THEN gtb.DebitAmount
			ELSE 0
		END CashPrepaidInterimInterestReceivable_Debit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GLTransactionType IN ('ReceiptNonCash')
			AND gtb.MatchingEntryItem IN ('PrepaidLeaseInterimInterestReceivable')
			AND gtb.MatchingGLTransactionType IN ('LeaseInterimInterestAR')
			AND rl.ContractId IS NULL
			THEN gtb.CreditAmount
			ELSE 0
		END NonCashPrepaidInterimInterestReceivable_Credit
		,CASE
			WHEN gtb.EntryItem IN ('Receivable')
			AND gtb.GLTransactionType IN ('ReceiptNonCash')
			AND gtb.MatchingEntryItem IN ('PrepaidLeaseInterimInterestReceivable')
			AND gtb.MatchingGLTransactionType IN ('LeaseInterimInterestAR')
			AND rl.ContractId IS NULL
			THEN gtb.DebitAmount
			ELSE 0
		END NonCashPrepaidInterimInterestReceivable_Debit
		,CASE
			WHEN gtb.EntryItem IN ('LeaseInterimInterestIncome')
			AND gtb.GLTransactionType IN ('LeaseInterimInterestIncome')
			AND @DeferInterimInterestIncomeRecognition = 'False'
				AND ((booking.InterimInterestBillingType = 'Periodic')
					OR (booking.InterimInterestBillingType = 'SingleInstallment' 
						AND @DeferInterimInterestIncomeRecognitionForSingleInstallment = 'False'))
			AND rl.ContractId IS NULL
			THEN gtb.CreditAmount
			ELSE 0
		END InterimInterestIncome_Credit
		,CASE
			WHEN gtb.EntryItem IN ('LeaseInterimInterestIncome')
			AND gtb.GLTransactionType IN ('LeaseInterimInterestIncome')
			AND @DeferInterimInterestIncomeRecognition = 'False'
				AND ((booking.InterimInterestBillingType = 'Periodic')
					OR (booking.InterimInterestBillingType = 'SingleInstallment' 
						AND @DeferInterimInterestIncomeRecognitionForSingleInstallment = 'False'))
			AND rl.ContractId IS NULL
			THEN gtb.DebitAmount
			ELSE 0
		END InterimInterestIncome_Debit
		,CASE
			WHEN gtb.EntryItem IN ('CapitalizedInterimInterest')
			AND gtb.GLTransactionType IN ('CapitalLeaseBooking')
			AND gtb.MatchingEntryItem IN ('AccruedInterimInterest')
			AND booking.InterimInterestBillingType = 'Capitalize'
			AND @DeferInterimInterestIncomeRecognition = 'False'
			AND rl.ContractId IS NULL
			THEN gtb.CreditAmount
			ELSE 0
		END DeferCapitalizedInterimInterest_Credit
		,CASE
			WHEN gtb.EntryItem IN ('CapitalizedInterimInterest')
			AND gtb.GLTransactionType IN ('CapitalLeaseBooking')
			AND gtb.MatchingEntryItem IN ('AccruedInterimInterest')
			AND booking.InterimInterestBillingType = 'Capitalize'
			AND @DeferInterimInterestIncomeRecognition = 'False'
			AND rl.ContractId IS NULL
			THEN gtb.DebitAmount
			ELSE 0
		END DeferCapitalizedInterimInterest_Debit
		,CASE
			WHEN gtb.EntryItem IN ('AccruedInterimInterestIncome')
			AND gtb.GLTransactionType IN ('CapitalLeaseBooking')
			AND rl.ContractId IS NULL
			THEN gtb.CreditAmount
			ELSE 0
		END BookingAccruedInterimInterestIncome_Credit
		,CASE
			WHEN gtb.EntryItem IN ('AccruedInterimInterestIncome')
			AND gtb.GLTransactionType IN ('CapitalLeaseBooking')
			AND rl.ContractId IS NULL
			THEN gtb.DebitAmount
			ELSE 0
		END BookingAccruedInterimInterestIncome_Debit
		,CASE
			WHEN gtb.EntryItem IN ('AccruedInterimInterest')
			AND gtb.GLTransactionType IN ('LeaseInterimInterestAR')
			AND rl.ContractId IS NULL
			THEN gtb.CreditAmount
			ELSE 0
		END ARAccruedInterimInterestIncome_Credit
		,CASE
			WHEN gtb.EntryItem IN ('AccruedInterimInterest')
			AND gtb.GLTransactionType IN ('LeaseInterimInterestAR')
			AND rl.ContractId IS NULL
			THEN gtb.DebitAmount
			ELSE 0
		END ARAccruedInterimInterestIncome_Debit
		,CASE
			WHEN gtb.EntryItem IN ('AccruedInterimInterest')
			AND gtb.GLTransactionType IN ('LeaseInterimInterestIncome')
			AND rl.ContractId IS NULL
			THEN gtb.CreditAmount
			ELSE 0
		END IRAccruedInterimInterestIncome_Credit
		,CASE
			WHEN gtb.EntryItem IN ('AccruedInterimInterest')
			AND gtb.GLTransactionType IN ('LeaseInterimInterestIncome')
			AND rl.ContractId IS NULL
			THEN gtb.DebitAmount
			ELSE 0
		END IRAccruedInterimInterestIncome_Debit
		,CASE
			WHEN gtb.GLTransactionType = 'FloatRateAR'
				AND gtb.EntryItem IN ('FloatRateAR','PrePaidFloatRateAR')
				AND booking.IsFloatRateLease = 1
			THEN gtb.CreditAmount
			ELSE 0
		END TotalGLPosted_Credit
		,CASE
			WHEN gtb.GLTransactionType = 'FloatRateAR'
				AND gtb.EntryItem IN ('FloatRateAR','PrePaidFloatRateAR')
				AND booking.IsFloatRateLease = 1
			THEN gtb.DebitAmount
			ELSE 0
		END TotalGLPosted_Debit
		,CASE
			WHEN ((gtb.EntryItem = 'FloatRateAR' AND gtb.MatchingEntryItem IS NULL)
					OR (gtb.EntryItem = 'Receivable' AND gtb.GLTransactionType IN ('ReceiptCash','ReceiptNonCash') 
						AND gtb.MatchingEntryItem = 'FloatRateAR'))
				AND booking.IsFloatRateLease = 1
			THEN gtb.CreditAmount
			ELSE 0
		END OSAR_Credit
		,CASE
			WHEN ((gtb.EntryItem = 'FloatRateAR' AND gtb.MatchingEntryItem IS NULL)
					OR (gtb.EntryItem = 'Receivable' AND gtb.GLTransactionType IN ('ReceiptCash','ReceiptNonCash') 
						AND gtb.MatchingEntryItem = 'FloatRateAR'))
				AND booking.IsFloatRateLease = 1
			THEN gtb.DebitAmount
			ELSE 0
		END OSAR_Debit
		,CASE
			WHEN gtb.EntryItem = 'Receivable'
				AND gtb.GLTransactionType IN ('ReceiptCash','ReceiptNonCash')
				AND gtb.MatchingGLTransactionType = 'FloatRateAR'
				AND gtb.MatchingEntryItem IN ('FloatRateAR','PrePaidFloatRateAR')
				AND booking.IsFloatRateLease = 1
			THEN gtb.CreditAmount
			ELSE 0
		END TotalPaid_Credit
		,CASE
			WHEN gtb.EntryItem = 'Receivable'
				AND gtb.GLTransactionType IN('ReceiptCash','ReceiptNonCash')
				AND gtb.MatchingGLTransactionType = 'FloatRateAR'
				AND gtb.MatchingEntryItem IN('FloatRateAR','PrePaidFloatRateAR')
				AND booking.IsFloatRateLease = 1
			THEN gtb.DebitAmount
			ELSE 0
		END TotalPaid_Debit
		,CASE
			WHEN gtb.EntryItem = 'Receivable'
				AND gtb.GLTransactionType IN ('ReceiptCash')
				AND gtb.MatchingGLTransactionType = 'FloatRateAR'
				AND gtb.MatchingEntryItem IN ('FloatRateAR','PrePaidFloatRateAR')
				AND booking.IsFloatRateLease = 1
			THEN gtb.CreditAmount
			ELSE 0
		END TotalCashPaid_Credit
		,CASE
			WHEN gtb.EntryItem = 'Receivable'
				AND gtb.GLTransactionType IN ('ReceiptCash')
				AND gtb.MatchingGLTransactionType = 'FloatRateAR'
				AND gtb.MatchingEntryItem IN ('FloatRateAR','PrePaidFloatRateAR')
				AND booking.IsFloatRateLease = 1
			THEN gtb.DebitAmount
			ELSE 0
		END TotalCashPaid_Debit
		,CASE
			WHEN gtb.EntryItem = 'Receivable'
				AND gtb.GLTransactionType IN ('ReceiptNonCash')
				AND gtb.MatchingGLTransactionType = 'FloatRateAR'
				AND gtb.MatchingEntryItem IN ('FloatRateAR','PrePaidFloatRateAR')
				AND booking.IsFloatRateLease = 1
			THEN gtb.CreditAmount
			ELSE 0
		END TotalNonCashPaid_Credit
		,CASE
			WHEN gtb.EntryItem = 'Receivable'
				AND gtb.GLTransactionType IN ('ReceiptNonCash')
				AND gtb.MatchingGLTransactionType = 'FloatRateAR'
				AND gtb.MatchingEntryItem IN ('FloatRateAR','PrePaidFloatRateAR')
				AND booking.IsFloatRateLease = 1
			THEN gtb.DebitAmount
			ELSE 0
		END TotalNonCashPaid_Debit
		,CASE
			WHEN ((gtb.EntryItem = 'PrePaidFloatRateAR' AND gtb.MatchingEntryItem IS NULL)
					OR (gtb.EntryItem = 'Receivable' AND gtb.MatchingEntryItem = 'PrePaidFloatRateAR'))
				AND booking.IsFloatRateLease = 1
			THEN gtb.CreditAmount
			ELSE 0
		END TotalPrePaid_Credit
		,CASE
			WHEN ((gtb.EntryItem = 'PrePaidFloatRateAR' AND gtb.MatchingEntryItem IS NULL)
					OR (gtb.EntryItem = 'Receivable' AND gtb.MatchingEntryItem = 'PrePaidFloatRateAR'))
				AND booking.IsFloatRateLease = 1
			THEN gtb.DebitAmount
			ELSE 0
		END TotalPrePaid_Debit
		,CASE
			WHEN gtb.GLTransactionType = 'FloatIncome'
				AND gtb.EntryItem = 'FloatInterestIncome'
				AND booking.IsFloatRateLease = 1
			THEN gtb.CreditAmount
			ELSE 0
		END TotalFloatRateIncome_Credit
		,CASE
			WHEN gtb.GLTransactionType = 'FloatIncome'
				AND gtb.EntryItem = 'FloatInterestIncome'
				AND booking.IsFloatRateLease = 1
			THEN gtb.DebitAmount
			ELSE 0
		END TotalFloatRateIncome_Debit
		,CASE
			WHEN gtb.GLTransactionType IN ( 'FloatIncome' , 'CapitalLeaseChargeoff')
				AND gtb.EntryItem = 'FloatRateSuspendedIncome'
				AND booking.IsFloatRateLease = 1
			THEN gtb.CreditAmount
			ELSE 0
		END TotalSuspendedFloatRateIncome_Credit
		,CASE
			WHEN gtb.GLTransactionType IN ( 'FloatIncome' , 'CapitalLeaseChargeoff')
				AND gtb.EntryItem = 'FloatRateSuspendedIncome'
				AND booking.IsFloatRateLease = 1
			THEN gtb.DebitAmount
			ELSE 0
		END TotalSuspendedFloatRateIncome_Debit
		,CASE
			WHEN gtb.GLTransactionType IN ('FloatIncome','FloatRateAR')
				AND gtb.EntryItem = 'AccruedFloatRateInterestIncome'
				AND booking.IsFloatRateLease = 1
			THEN gtb.CreditAmount
			ELSE 0
		END TotalAccruedFloatRateIncome_Credit
		,CASE
			WHEN gtb.GLTransactionType IN ('FloatIncome', 'FloatRateAR')
				AND gtb.EntryItem = 'AccruedFloatRateInterestIncome'
				AND booking.IsFloatRateLease = 1
			THEN gtb.DebitAmount
			ELSE 0
		END TotalAccruedFloatRateIncome_Debit
		,CASE
			WHEN gtb.GLTransactionType IN ('SyndicatedAR')
				AND gtb.EntryItem IN ('DueToThirdPartyAR')
			THEN gtb.CreditAmount
			ELSE 0
		END DueToThirdPartyAR_Credit
		,CASE
			WHEN gtb.GLTransactionType IN ('SyndicatedAR')
				AND gtb.EntryItem IN ('DueToThirdPartyAR')
			THEN gtb.DebitAmount
			ELSE 0
		END DueToThirdPartyAR_Debit
		,CASE
			WHEN gtb.GLTransactionType IN ('SyndicatedAR')
				AND gtb.EntryItem IN ('PrepaidDueToThirdPartyAR')
			THEN gtb.CreditAmount
			ELSE 0
		END PrepaidDueToThirdPartyAR_Credit
		,CASE
			WHEN gtb.GLTransactionType IN ('SyndicatedAR')
				AND gtb.EntryItem IN ('PrepaidDueToThirdPartyAR')
			THEN gtb.DebitAmount
			ELSE 0
		END PrepaidDueToThirdPartyAR_Debit
		,CASE
			WHEN gtb.GLTransactionType IN ('ReceiptCash')
				AND gtb.EntryItem IN ('Receivable')
				AND gtb.MatchingGLTransactionType IN ('SyndicatedAR')
				AND gtb.MatchingEntryItem IN ('DueToThirdPartyAR')
			THEN gtb.CreditAmount
			ELSE 0
		END CashDueToThirdPartyAR_Credit
		,CASE
			WHEN gtb.GLTransactionType IN ('ReceiptCash')
				AND gtb.EntryItem IN ('Receivable')
				AND gtb.MatchingGLTransactionType IN ('SyndicatedAR')
				AND gtb.MatchingEntryItem IN ('DueToThirdPartyAR')
			THEN gtb.DebitAmount
			ELSE 0
		END CashDueToThirdPartyAR_Debit
		,CASE
			WHEN gtb.GLTransactionType IN ('ReceiptCash')
				AND gtb.EntryItem IN ('Receivable')
				AND gtb.MatchingGLTransactionType IN ('SyndicatedAR')
				AND gtb.MatchingEntryItem IN ('PrepaidDueToThirdPartyAR')
			THEN gtb.CreditAmount
			ELSE 0
		END CashPrepaidDueToThirdPartyAR_Credit
		,CASE
			WHEN gtb.GLTransactionType IN ('ReceiptCash')
				AND gtb.EntryItem IN ('Receivable')
				AND gtb.MatchingGLTransactionType IN ('SyndicatedAR')
				AND gtb.MatchingEntryItem IN ('PrepaidDueToThirdPartyAR')
			THEN gtb.DebitAmount
			ELSE 0
		END CashPrepaidDueToThirdPartyAR_Debit
		,CASE
			WHEN gtb.GLTransactionType IN ('ReceiptNonCash')
				AND gtb.EntryItem IN ('Receivable')
				AND gtb.MatchingGLTransactionType IN ('SyndicatedAR')
				AND gtb.MatchingEntryItem IN ('DueToThirdPartyAR')
			THEN gtb.CreditAmount
			ELSE 0
		END NonCashDueToThirdPartyAR_Credit
		,CASE
			WHEN gtb.GLTransactionType IN ('ReceiptNonCash')
				AND gtb.EntryItem IN ('Receivable')
				AND gtb.MatchingGLTransactionType IN ('SyndicatedAR')
				AND gtb.MatchingEntryItem IN ('DueToThirdPartyAR')
			THEN gtb.DebitAmount
			ELSE 0
		END NonCashDueToThirdPartyAR_Debit
		,CASE
			WHEN gtb.GLTransactionType IN ('ReceiptNonCash')
				AND gtb.EntryItem IN ('Receivable')
				AND gtb.MatchingGLTransactionType IN ('SyndicatedAR')
				AND gtb.MatchingEntryItem IN ('PrepaidDueToThirdPartyAR')
			THEN gtb.CreditAmount
			ELSE 0
		END NonCashPrepaidDueToThirdPartyAR_Credit
		,CASE
			WHEN gtb.GLTransactionType IN ('ReceiptNonCash')
				AND gtb.EntryItem IN ('Receivable')
				AND gtb.MatchingGLTransactionType IN ('SyndicatedAR')
				AND gtb.MatchingEntryItem IN ('PrepaidDueToThirdPartyAR')
			THEN gtb.DebitAmount
			ELSE 0
		END NonCashPrepaidDueToThirdPartyAR_Debit
		,CASE
			WHEN gtb.GLTransactionType IN ('SalesTax')
				AND gtb.EntryItem IN ('SyndicatedSalesTaxReceivable')
			THEN gtb.CreditAmount
			ELSE 0
		END SyndicatedSalesTaxReceivable_Credit
		,CASE
			WHEN gtb.GLTransactionType IN ('SalesTax')
				AND gtb.EntryItem IN ('SyndicatedSalesTaxReceivable')
			THEN gtb.DebitAmount
			ELSE 0
		END SyndicatedSalesTaxReceivable_Debit
		,CASE
			WHEN gtb.GLTransactionType IN ('SalesTax')
				AND gtb.EntryItem IN ('PrepaidSyndicatedSalesTaxReceivable')
			THEN gtb.CreditAmount
			ELSE 0
		END PrepaidSyndicatedSalesTaxReceivable_Credit
		,CASE
			WHEN gtb.GLTransactionType IN ('SalesTax')
				AND gtb.EntryItem IN ('PrepaidSyndicatedSalesTaxReceivable')
			THEN gtb.DebitAmount
			ELSE 0
		END PrepaidSyndicatedSalesTaxReceivable_Debit
		,CASE
			WHEN gtb.GLTransactionType IN ('ReceiptCash')
				AND gtb.EntryItem IN ('Receivable')
				AND gtb.MatchingGLTransactionType IN ('SalesTax')
				AND gtb.MatchingEntryItem IN ('SyndicatedSalesTaxReceivable')
			THEN gtb.CreditAmount
			ELSE 0
		END CashSyndicatedSalesTaxReceivable_Credit
		,CASE
			WHEN gtb.GLTransactionType IN ('ReceiptCash')
				AND gtb.EntryItem IN ('Receivable')
				AND gtb.MatchingGLTransactionType IN ('SalesTax')
				AND gtb.MatchingEntryItem IN ('SyndicatedSalesTaxReceivable')
			THEN gtb.DebitAmount
			ELSE 0
		END CashSyndicatedSalesTaxReceivable_Debit
		,CASE
			WHEN gtb.GLTransactionType IN ('ReceiptCash')
				AND gtb.EntryItem IN ('Receivable')
				AND gtb.MatchingGLTransactionType IN ('SalesTax')
				AND gtb.MatchingEntryItem IN ('PrepaidSyndicatedSalesTaxReceivable')
			THEN gtb.CreditAmount
			ELSE 0
		END CashPrepaidSyndicatedSalesTaxReceivable_Credit
		,CASE
			WHEN gtb.GLTransactionType IN ('ReceiptCash')
				AND gtb.EntryItem IN ('Receivable')
				AND gtb.MatchingGLTransactionType IN ('SalesTax')
				AND gtb.MatchingEntryItem IN ('PrepaidSyndicatedSalesTaxReceivable')
			THEN gtb.DebitAmount
			ELSE 0
		END CashPrepaidSyndicatedSalesTaxReceivable_Debit
		,CASE
			WHEN gtb.GLTransactionType IN ('ReceiptNonCash')
				AND gtb.EntryItem IN ('Receivable')
				AND gtb.MatchingGLTransactionType IN ('SalesTax')
				AND gtb.MatchingEntryItem IN ('SyndicatedSalesTaxReceivable')
			THEN gtb.CreditAmount
			ELSE 0
		END NonCashSyndicatedSalesTaxReceivable_Credit
		,CASE
			WHEN gtb.GLTransactionType IN ('ReceiptNonCash')
				AND gtb.EntryItem IN ('Receivable')
				AND gtb.MatchingGLTransactionType IN ('SalesTax')
				AND gtb.MatchingEntryItem IN ('SyndicatedSalesTaxReceivable')
			THEN gtb.DebitAmount
			ELSE 0
		END NonCashSyndicatedSalesTaxReceivable_Debit
		,CASE
			WHEN gtb.GLTransactionType IN ('ReceiptNonCash')
				AND gtb.EntryItem IN ('Receivable')
				AND gtb.MatchingGLTransactionType IN ('SalesTax')
				AND gtb.MatchingEntryItem IN ('PrepaidSyndicatedSalesTaxReceivable')
			THEN gtb.CreditAmount
			ELSE 0
		END NonCashPrepaidSyndicatedSalesTaxReceivable_Credit
		,CASE
			WHEN gtb.GLTransactionType IN ('ReceiptNonCash')
				AND gtb.EntryItem IN ('Receivable')
				AND gtb.MatchingGLTransactionType IN ('SalesTax')
				AND gtb.MatchingEntryItem IN ('PrepaidSyndicatedSalesTaxReceivable')
			THEN gtb.DebitAmount
			ELSE 0
		END NonCashPrepaidSyndicatedSalesTaxReceivable_Debit
	FROM #GLTrialBalance gtb
		INNER JOIN #EligibleContracts booking ON booking.ContractId = gtb.EntityId 
		LEFT JOIN #RenewalDetails rl ON booking.ContractId = rl.ContractId
	) RS1
	GROUP BY RS1.ContractId;
	
	IF @Residual_GP = 'TRUE'
		BEGIN 
			UPDATE #SumOfReceivableDetails
				SET LongTermReceivables_LeaseComponent_Table += ar.CustomerGuaranteedResidual_LeaseAssets + ar.ThirdPartyGuaranteedResidual_LeaseAssets
			, 		LongTermReceivables_FinanceComponent_Table += ar.CustomerGuaranteedResidual_FinanceAssets + ar.ThirdPartyGuaranteedResidual_FinanceAssets
			FROM #SumOfReceivableDetails 
			INNER JOIN #AssetResiduals ar ON ar.ContractId = #SumOfReceivableDetails.ContractId
		END
	
	DECLARE @RefundSql nvarchar(max) ='';

	SET @RefundSql =
	'SELECT DISTINCT
		ec.ContractId
		,pgl.GLJournalId
		,''Payable''
		,p.Id
		,p.Amount_Amount
		,pgl.IsReversal
 	FROM #EligibleContracts ec
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
	FROM #EligibleContracts ec
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
	FROM #EligibleContracts ec
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

	SELECT t.ContractId
		 , SUM(t.TableAmount) AS [Refunds_GL]
	INTO #RRGLDetails
	FROM #GLDetails gl
	INNER JOIN(SELECT ContractId,Id, SUM(CASE WHEN IsReversal = 0 THEN Amount ELSE (-1)*Amount END) AS TableAmount FROM #RefundGLJournalIds WHERE EntityType = 'Payable' GROUP BY ContractId,Id) AS t ON gl.Id = t.Id
	WHERE gl.EntityType = 'Payable'
	AND gl.Refunds_GL = t.TableAmount
	GROUP BY t.ContractId;


	MERGE #RRGLDetails AS gl
	USING(SELECT refund.ContractId
			   , SUM(refund.Amount) AS [Refunds]
		  FROM #GLDetails gl
		  INNER JOIN(SELECT DISTINCT Id FROM #RefundGLJournalIds WHERE EntityType = 'PaymentVoucher') AS t ON gl.Id = t.Id
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
		  
	CREATE NONCLUSTERED INDEX IX_Id ON #RRGLDetails(ContractId);

	UPDATE gld
	SET DeferInterimRentIncome_GL = 
	CASE WHEN (ec.InterimRentBillingType = 'Periodic' AND @DeferInterimRentIncomeRecognition = 'True') 
				OR (ec.InterimRentBillingType = 'SingleInstallment' 
					AND (@DeferInterimRentIncomeRecognition = 'True' OR @DeferInterimRentIncomeRecognitionForSingleInstallment = 'True'))
		THEN ISNULL(gld.BookingDeferredInterimRentIncome_GL,0.00) - ISNULL(gld.ARDeferredInterimRentIncome_GL,0.00)
		WHEN (ec.InterimRentBillingType = 'Periodic' AND @DeferInterimRentIncomeRecognition = 'False') 
				OR (ec.InterimRentBillingType = 'SingleInstallment' 
					AND (@DeferInterimRentIncomeRecognition = 'False' AND @DeferInterimRentIncomeRecognitionForSingleInstallment = 'False'))
		THEN ISNULL(gld.ARDeferredInterimRentIncome_GL,0.00) - ISNULL(gld.IRDeferredInterimRentIncome_GL,0.00)
		WHEN (ec.InterimRentBillingType = 'Capialize' AND @DeferInterimRentIncomeRecognition = 'False')
		THEN ISNULL(gld.BookingDeferredInterimRentIncome_GL,0.00) - ISNULL(gld.IRDeferredInterimRentIncome_GL,0.00)
		ELSE 0.00
	END
	,AccruedInterimInterestIncome_GL =
	CASE WHEN (ec.InterimInterestBillingType = 'Periodic' AND @DeferInterimInterestIncomeRecognition = 'True') 
				OR (ec.InterimInterestBillingType = 'SingleInstallment' 
					AND (@DeferInterimInterestIncomeRecognition = 'True' OR @DeferInterimInterestIncomeRecognitionForSingleInstallment = 'True'))
		THEN ISNULL(gld.BookingAccruedInterimInterestIncome_GL,0.00) - ISNULL(gld.ARAccruedInterimInterestIncome_GL,0.00)
		WHEN (ec.InterimInterestBillingType = 'Periodic' AND @DeferInterimInterestIncomeRecognition = 'False') 
				OR (ec.InterimInterestBillingType = 'SingleInstallment' 
					AND (@DeferInterimInterestIncomeRecognition = 'False' AND @DeferInterimInterestIncomeRecognitionForSingleInstallment = 'False'))
		THEN ISNULL(gld.IRAccruedInterimInterestIncome_GL,0.00) - ISNULL(gld.ARAccruedInterimInterestIncome_GL,0.00)
		WHEN (ec.InterimInterestBillingType = 'Capialize' AND @DeferInterimInterestIncomeRecognition = 'False')
		THEN ISNULL(gld.BookingAccruedInterimInterestIncome_GL,0.00) - ISNULL(gld.IRAccruedInterimInterestIncome_GL,0.00)
		ELSE 0.00
	END
	FROM #GLJournalDetail gld
		INNER JOIN #EligibleContracts ec ON gld.ContractId = ec.ContractId;

	SELECT 
		DISTINCT t.ContractId
	INTO #ContractsWithManualGLEntries
	FROM(
		SELECT
			c.ContractId
		FROM #EligibleContracts c
			INNER JOIN GLManualJournalEntries gje ON gje.ContractId = c.ContractId
		WHERE gje.EntityType='Contract'
			AND gje.IsActive = 1  
		UNION
		SELECT
			c.ContractId
		FROM #EligibleContracts c
			INNER JOIN ReceivableForTransfers rft ON rft.ContractId = c.ContractId
			INNER JOIN GLManualJournalEntries gje ON gje.ContractId = c.ContractId
		WHERE gje.EntityType='RT'
			AND gje.IsActive = 1 
		) AS t;

	CREATE NONCLUSTERED INDEX IX_Id ON #ContractsWithManualGLEntries(ContractId);

		UPDATE gld SET 
					   GLPostedReceivables_LeaseComponent_GL -= t.LeaseComponentGLPosted
					 , GLPostedReceivables_FinanceComponent_GL -= t.FinanceComponentGLPosted
					 , TotalGLPosted_GL -= t.FloatRateGL
		FROM #GLJournalDetail gld
			 INNER JOIN
		(
			SELECT r.EntityId
				 , ABS(SUM(CASE
						   WHEN r.StartDate < co.ChargeoffDate AND r.ReceivableType = 'CapitalLeaseRental'
						   THEN ISNULL(r.ChargeoffExpenseAmount_LC, 0.00)
						   ELSE 0.00
					   END)) AS LeaseComponentGLPosted
				 , ABS(SUM(CASE
						   WHEN r.StartDate < co.ChargeoffDate AND r.ReceivableType = 'CapitalLeaseRental'
						   THEN ISNULL(r.ChargeoffExpenseAmount_NLC, 0.00)
						   ELSE 0.00
					   END)) AS FinanceComponentGLPosted
				 , ABS(SUM(CASE
						   WHEN (r.StartDate < co.ChargeoffDate OR r.StartDate IS NULL)AND r.ReceivableType = 'LeaseFloatRateAdj'
						   THEN ISNULL(r.ChargeoffExpenseAmount_NLC, 0.00) + ISNULL(r.ChargeoffExpenseAmount_LC, 0.00)
						   ELSE 0.00
					   END)) AS FloatRateGL
			FROM #ReceiptApplicationReceivableDetails r
				 INNER JOIN #ChargeOff co ON r.EntityId = co.ContractId
			WHERE ReceiptStatus IN('Reversed')
				 AND r.IsRecovery IS NOT NULL
				 AND r.IsRecovery = 0
				 AND r.IsGLPosted = 1
			GROUP BY r.EntityId
		) AS t ON t.EntityId = gld.ContractId;

		
		UPDATE gld SET 
					   PaidReceivables_LeaseComponent_GL = PaidReceivables_LeaseComponent_GL - (t.LeaseComponentCashPosted + t.LeaseComponentNonCashPosted)
					 , PaidReceivables_FinanceComponent_GL = PaidReceivables_LeaseComponent_GL - (t.FinanceComponentCashPosted + t.FinanceComponentNonCashPosted)
					 , PaidReceivablesviaCash_LeaseComponent_GL -= t.LeaseComponentCashPosted
					 , PaidReceivablesviaCash_FinanceComponent_GL -= t.FinanceComponentCashPosted
					 , PaidReceivablesviaNonCash_LeaseComponent_GL -= t.LeaseComponentNonCashPosted
					 , PaidReceivablesviaNonCash_FinanceComponent_GL -= t.FinanceComponentNonCashPosted
					 , TotalPaid_GL = TotalPaid_GL - (t.FloatRateCashPosted + t.FloatRateNonCashPosted)
					 , TotalCashPaid_GL -= t.FloatRateCashPosted
				     , TotalNonCashPaid_GL -= t.FloatRateNonCashPosted

		FROM #GLJournalDetail gld
			 INNER JOIN
		(
			SELECT r.EntityId
				 , SUM(CASE
						   WHEN ReceiptClassification IN('Cash', 'NonAccrualNonDSL', 'DSL') AND ReceiptTypeName NOT IN('PayableOffset', 'SecurityDeposit', 'EscrowRefund')
							    AND (r.StartDate < co.ChargeoffDate AND r.ReceivableType = 'CapitalLeaseRental')
						   THEN ISNULL(r.ChargeoffExpenseAmount_LC, 0.00)
						   ELSE 0.00
					   END) AS LeaseComponentCashPosted
				 , SUM(CASE
						   WHEN ReceiptClassification IN('Cash', 'NonAccrualNonDSL', 'DSL')	AND ReceiptTypeName NOT IN('PayableOffset', 'SecurityDeposit', 'EscrowRefund')
							    AND (r.StartDate < co.ChargeoffDate AND r.ReceivableType = 'CapitalLeaseRental')
						   THEN ISNULL(r.ChargeoffExpenseAmount_NLC, 0.00)
						   ELSE 0.00
					   END) AS FinanceComponentCashPosted
				 , SUM(CASE
						   WHEN (ReceiptClassification NOT IN('Cash', 'NonAccrualNonDSL', 'DSL') OR ReceiptTypeName IN('PayableOffset', 'SecurityDeposit', 'EscrowRefund'))
							    AND (r.StartDate < co.ChargeoffDate AND r.ReceivableType = 'CapitalLeaseRental')
						   THEN ISNULL(r.ChargeoffExpenseAmount_LC, 0.00)
						   ELSE 0.00
					   END) AS LeaseComponentNonCashPosted
				 , SUM(CASE
						   WHEN (ReceiptClassification NOT IN('Cash', 'NonAccrualNonDSL', 'DSL') OR ReceiptTypeName IN('PayableOffset', 'SecurityDeposit', 'EscrowRefund'))
								AND (r.StartDate < co.ChargeoffDate AND r.ReceivableType = 'CapitalLeaseRental')
						   THEN ISNULL(r.ChargeoffExpenseAmount_NLC, 0.00)
						   ELSE 0.00
					   END) AS FinanceComponentNonCashPosted
				 , SUM(CASE
						   WHEN ReceiptClassification IN('Cash', 'NonAccrualNonDSL', 'DSL') AND ReceiptTypeName NOT IN('PayableOffset', 'SecurityDeposit', 'EscrowRefund')
							    AND (r.StartDate < co.ChargeoffDate OR r.StartDate IS NULL) AND r.ReceivableType = 'LeaseFloatRateAdj'
						   THEN ISNULL(r.ChargeoffExpenseAmount_LC, 0.00) + ISNULL(r.ChargeoffExpenseAmount_NLC, 0.00)
						   ELSE 0.00
					   END)	AS FloatRateCashPosted
				 , SUM(CASE
						   WHEN (ReceiptClassification NOT IN('Cash', 'NonAccrualNonDSL', 'DSL') OR ReceiptTypeName IN('PayableOffset', 'SecurityDeposit', 'EscrowRefund'))
							    AND (r.StartDate < co.ChargeoffDate OR r.StartDate IS NULL) AND r.ReceivableType = 'LeaseFloatRateAdj'
						   THEN ISNULL(r.ChargeoffExpenseAmount_LC, 0.00) + ISNULL(r.ChargeoffExpenseAmount_NLC, 0.00)
						   ELSE 0.00
					   END)	AS FloatRateNonCashPosted	
			FROM #ReceiptApplicationReceivableDetails r
				 INNER JOIN #ChargeOff co ON r.EntityId = co.ContractId
			WHERE ReceiptStatus IN('Reversed')
				 AND r.IsRecovery IS NOT NULL
				 AND r.IsRecovery = 0
				 AND r.IsGLPosted = 1
			GROUP BY r.EntityId
		) AS t ON t.EntityId = gld.ContractId;

	SELECT *
		, CASE
			WHEN [GLPostedReceivables_LeaseComponent_Difference] != 0.00
				OR	[PaidReceivables_LeaseComponent_Difference] != 0.00	
				OR	[PaidReceivablesviaCash_LeaseComponent_Difference] != 0.00
				OR	[PaidReceivablesviaNonCash_LeaseComponent_Difference] != 0.00
				OR	[PrepaidReceivables_LeaseComponent_Difference] != 0.00
				OR	[OutstandingReceivables_LeaseComponent_Difference] != 0.00
				OR	[LongTermReceivables_LeaseComponent_Difference] != 0.00
				OR 	[UnguaranteedResidual_LeaseComponent_Difference] != 0.00
				OR	[GuaranteedResidual_LeaseComponent_Difference] != 0.00
				OR	[GLPostedReceivables_FinanceComponent_Difference] != 0.00
				OR	[PaidReceivables_FinanceComponent_Difference] != 0.00
				OR	[PaidReceivablesviaCash_FinanceComponent_Difference] != 0.00
				OR	[PaidReceivablesviaNonCash_FinanceComponent_Difference] != 0.00
				OR	[PrepaidReceivables_FinanceComponent_Difference] != 0.00
				OR	[OutstandingReceivables_FinanceComponent_Difference] != 0.00
				OR	[LongTermReceivables_FinanceComponent_Difference] != 0.00
				OR	[UnguaranteedResidual_FinanceComponent_Difference] != 0.00
				OR	[GuaranteedResidual_FinanceComponent_Difference] != 0.00
				OR	[TotalIncome_Accounting_Schedule_Difference] != 0.00
				OR	[TotalSellingProfitIncome_Accounting_Schedule_Difference] != 0.00
				OR	[LeaseEarnedIncome_Difference] != 0.00
				OR	[LeaseEarnedResidualIncome_Difference] != 0.00
				OR	[EarnedSellingProfitIncome_Difference] != 0.00
				OR	[LeaseUnearnedIncome_Difference] != 0.00
				OR	[LeaseUnearnedResidualIncome_Difference] != 0.00
				OR	[UnearnedSellingProfitIncome_Difference] != 0.00
				OR	[LeaseRecognizedSuspendedIncome_Difference] != 0.00
				OR	[LeaseRecognizedSuspendedResidualIncome_Difference] != 0.00
				OR	[RecognizedSuspendedSellingProfitIncome_Difference] != 0.00
				OR	[Finance_TotalIncome_Accounting_Schedule_Difference] != 0.00
				OR	[FinanceEarnedIncome_Difference] != 0.00
				OR	[FinanceEarnedResidualIncome_Difference] != 0.00
				OR	[FinanceUnearnedIncome_Difference] != 0.00
				OR	[FinanceUnearnedResidualIncome_Difference] != 0.00
				OR	[FinanceRecognizedSuspendedIncome_Difference] != 0.00
				OR	[FinanceRecognizedSuspendedResidualIncome_Difference] != 0.00
				OR	[SalesTypeLeaseGrossProfit_Difference] != 0.00
				OR 	[GrossWriteDown_Difference] != 0.00
				OR 	[WriteDownRecovered_Difference] != 0.00
				OR 	[NetWriteDown_Difference] != 0.00
				OR 	[ChargeOffExpense_LeaseComponent_Difference] != 0.00
				OR 	[ChargeOffRecovery_LeaseComponent_Difference] != 0.00
				OR 	[ChargeOffGainOnRecovery_LeaseComponent_Difference] != 0.00
				OR 	[ChargeOffExpense_NonLeaseComponent_Difference] != 0.00
				OR 	[ChargeOffRecovery_NonLeaseComponent_Difference] != 0.00
				OR 	[ChargeOffGainOnRecovery_NonLeaseComponent_Difference] != 0.00
				OR	[UnAppliedCash_Difference] != 0.00

				OR	[TotalGLPosted_SalesTaxReceivable_Difference] != 0.00
				OR	[TotalPaid_SalesTaxReceivables_Difference] != 0.00
				OR	[TotalPrepaidPaid_SalesTaxReceivables_Difference] != 0.00
				OR	[TotalOutstanding_SalesTaxReceivables_Difference] != 0.00
				OR	[TotalPaidviacash_SalesTaxReceivables_Difference] != 0.00
				OR	[TotalPaidvianoncash_SalesTaxReceivables_Difference] != 0.00

				OR	[TotalCapitalizedSalesTax_Difference] != 0.00
				OR	[TotalCapitalizedInterimInterest_Difference] != 0.00
				OR	[TotalCapitalizedInterimRent_Difference] != 0.00
				OR	[TotalCapitalizedAdditionalCharge_Difference] != 0.00

				OR	[TotalGLPosted_InterimRentReceivables_Difference] != 0.00
				OR	[TotalPaid_InterimRentReceivables_Difference] != 0.00
				OR	[TotalPaidviaCash_InterimRentReceivables_Difference] != 0.00
				OR	[TotalPaidviaNonCash_InterimRentReceivables_Difference] != 0.00
				OR	[TotalPrepaid_InterimRentReceivables_Difference] != 0.00
				OR	[TotalOutstanding_InterimRentReceivables_Difference] != 0.00
				OR	[GLPosted_InterimRentIncome_Difference] != 0.00
				OR	[TotalCapitalizedIncome_InterimRentIncome_Difference] != 0.00
				OR	[TotalInterimRent_IncomeandReceivable_Difference] != 0.00
				OR	[DeferInterimRentIncome_Difference] != 0.00

				OR	[TotalGLPosted_InterimInterestReceivables_Difference] != 0.00
				OR	[TotalPaid_InterimInterestReceivables_Difference] != 0.00
				OR	[TotalPaidviaCash_InterimInterestReceivables_Difference] != 0.00
				OR	[TotalPaidviaNonCash_InterimInterestReceivables_Difference] != 0.00
				OR	[TotalPrepaid_InterimInterestReceivables_Difference] != 0.00
				OR	[TotalOutstanding_InterimInterestReceivables_Difference] != 0.00
				OR	[GLPosted_InterimInterestIncome_Difference] != 0.00
				OR	[TotalCapitalizedIncome_InterimInterestIncome_Difference] != 0.00
				OR	[TotalInterimInterest_IncomeandReceivable_Difference] != 0.00
				OR	[AccruedInterimInterestIncome_Difference] != 0.00

				OR	[TotalGLPostedFloatRateReceivables_Difference] != 0.00
				OR	[TotalPaidFloatRateReceivables_Difference] != 0.00
				OR	[TotalCashPaidFloatRateReceivables_Difference] != 0.00
				OR	[TotalNonCashPaidFloatRateReceivables_Difference] != 0.00
				OR	[OutstandingFloatRateReceivables_Difference] != 0.00
				OR	[PrepaidFloatRateReceivables_Difference] != 0.00
				OR	[TotalFloatRateIncome_AccountingAndSchedule_Difference] != 0.00
				OR	[TotalGLPostedFloatRateIncome_Difference] != 0.00
				OR	[TotalSuspendedIncome_Difference] != 0.00
				OR	[TotalAccruedIncome_Difference] != 0.00

				OR [TotalGLPosted_FunderOwned_Difference] != 0.00
				OR [TotalPaidCash_FunderOwned_Difference] != 0.00
				OR [TotalPaidNonCash_FunderOwned_Difference] != 0.00
				OR [TotalOSAR_FunderOwned_Difference] != 0.00
				OR [TotalPrepaid_FunderOwned_Difference] != 0.00
				OR [TotalGLPosted_FunderOwned_LessorRemit_SalesTax_Difference] != 0.00
				OR [TotalPaidCash_FunderOwned_LessorRemit_SalesTax_Difference] != 0.00
				OR [TotalPaidNonCash_FunderOwned_LessorRemit_SalesTax_Difference] != 0.00
				OR [TotalOSAR_FunderOwned_LessorRemit_SalesTax_Difference] != 0.00
				OR [TotalPrepaid_FunderOwned_LessorRemit_SalesTax_Difference] != 0.00
				OR [TotalChargeoffAmountVSLCAndNLC] != 0.00
				OR [TotalRecoveryAndGainVSRecoveryAndGainLCAndNLC] != 0.00
			THEN 'Problem Record'
			ELSE 'Not Problem Record'
		END [Result]
	INTO #Resultlist
	FROM (
		SELECT 
			ec.SequenceNumber [SequenceNumber]
		,   ec.ContractAlias [ContractAlias]
		,	ec.ContractId [ContractId]   
		, 	LegalEntities.Name [LegalEntityName]
		,	lob.Name [LineOfBusinessName]
		, 	Parties.PartyNumber [CustomerNumber]
		,	ec.IsMigrated
		,	ec.AccountingStandard
		,	ec.LeaseContractType
		,   ec.ContractStatus 
		,	ec.AdvanceOrArrear
		,	ec.TermInMonths
		,	ec.NumberOfPayments
		,	ec.PaymentFrequency
		,	ec.RegularOrIrregularPayment
		,	ISNULL(pa.PaymentAmount, 0.00) [PaymentAmount]
		,	ec.CommencementDate
		,	ec.MaturityDate
		,	IIF(ot.ContractID IS NOT NULL, 'Yes', 'No') IsOverTermLease
		,	ec.LeaseWithInterim
		,	ec.InterimAssessmentMethod
		,	ec.InterimInterestBillingType
		,	ec.InterimRentBillingType
		,	fpc.PayoffEffectiveDate
		,	CASE
				WHEN ec.SyndicationType = 'None'
				THEN 'Not Syndicated'
				ELSE ec.SyndicationType
			END AS [SyndicationType]
		,	rft.EffectiveDate [SyndicationDate]
		,	ec.AccrualStatus
		,	CASE
				WHEN ad.NonAccrualId IS NOT NULL
				THEN 'Was Non-Accrual'
				ELSE 'Was Not Non-Accrual'
			    END AS [WasNonAccrualAnytime]
		,	ad.NonAccrualDate [NonAccrualDate]
		,	CASE
				WHEN ad.ReAccrualId IS NOT NULL
				THEN 'Yes'
				ELSE 'No'
				END AS [IsReAccrualDone]
		,	ad.ReAccrualDate [ReAccrualDate]
		,	CASE
				WHEN fa.ContractId IS NOT NULL
				THEN 'Yes'
				ELSE 'No'
				END AS [HasFinanceAsset]
		,	CASE
				WHEN co.ContractId IS NOT NULL
				THEN 'Yes'
				ELSE 'No'
				END as [IsChargedOffLease]
		,	co.ChargeOffDate [ChargeOffDate]
		,	ec.ChargeOffStatus
		,	CASE
				WHEN rl.IsRenewal > 0
				THEN 'Yes'
				ELSE 'No'
				END as [IsRenewalLease]
		,	CASE
				WHEN rl.IsAssumed > 0
				THEN 'Yes'
				ELSE 'No'
				END as [IsAssumption]
		,	ISNULL(sd.TotalPayments, 0.00) AS [TotalPayments]
		,	ISNULL(sd.TotalGLPostedReceivables, 0.00) AS [TotalGLPostedReceivables]
		,	ISNULL(srd.GLPostedReceivables_LeaseComponent_Table, 0.00) AS [GLPostedReceivables_LeaseComponent_Table]
		,	ISNULL(gld.GLPostedReceivables_LeaseComponent_GL, 0.00) AS [GLPostedReceivables_LeaseComponent_GL]
		,	ISNULL(srd.GLPostedReceivables_LeaseComponent_Table, 0.00) - ISNULL(gld.GLPostedReceivables_LeaseComponent_GL, 0.00) AS [GLPostedReceivables_LeaseComponent_Difference]
		,	ISNULL(sd.LeaseBookingReceivables, 0.00) - ISNULL(sd.ReceivablesBalance, 0.00) [TotalPaidReceivables]
		,	ISNULL(pr.PaidReceivables_LeaseComponent_Table, 0.00) AS [PaidReceivables_LeaseComponent_Table]
		,	ISNULL(gld.PaidReceivables_LeaseComponent_GL, 0.00) AS [PaidReceivables_LeaseComponent_GL]
		,	ISNULL(pr.PaidReceivables_LeaseComponent_Table, 0.00) - ISNULL(gld.PaidReceivables_LeaseComponent_GL, 0.00) AS [PaidReceivables_LeaseComponent_Difference]
		,	ISNULL(pr.PaidReceivablesviaCash_LeaseComponent_Table, 0.00) AS [PaidReceivablesviaCash_LeaseComponent_Table]
		,	ISNULL(gld.PaidReceivablesviaCash_LeaseComponent_GL, 0.00) AS [PaidReceivablesviaCash_LeaseComponent_GL]
		,	ISNULL(pr.PaidReceivablesviaCash_LeaseComponent_Table, 0.00) - ISNULL(gld.PaidReceivablesviaCash_LeaseComponent_GL, 0.00) AS [PaidReceivablesviaCash_LeaseComponent_Difference]
		,	ISNULL(pr.PaidReceivablesviaNonCash_LeaseComponent_Table, 0.00) AS [PaidReceivablesviaNonCash_LeaseComponent_Table]
		,	ISNULL(gld.PaidReceivablesviaNonCash_LeaseComponent_GL, 0.00) AS [PaidReceivablesviaNonCash_LeaseComponent_GL]
		,	ISNULL(pr.PaidReceivablesviaNonCash_LeaseComponent_Table, 0.00) - ISNULL(gld.PaidReceivablesviaNonCash_LeaseComponent_GL, 0.00) AS [PaidReceivablesviaNonCash_LeaseComponent_Difference]
		,	ISNULL(pd.PrepaidReceivables_LeaseComponent_Table, 0.00) + ISNULL(pd.PrepaidReceivables_FinanceComponent_Table, 0.00) AS [TotalPrepaidReceivables]
		,	ISNULL(pd.PrepaidReceivables_LeaseComponent_Table, 0.00) AS [PrepaidReceivables_LeaseComponent_Table]
		,	ISNULL(gld.PrepaidReceivables_LeaseComponent_GL, 0.00) AS [PrepaidReceivables_LeaseComponent_GL]
		,	ISNULL(pd.PrepaidReceivables_LeaseComponent_Table, 0.00) - ISNULL(gld.PrepaidReceivables_LeaseComponent_GL, 0.00) AS [PrepaidReceivables_LeaseComponent_Difference]
		,	ISNULL(sd.TotalOutStandingReceivables, 0.00) AS [TotalOutStandingReceivables]
		,	ISNULL(srd.OutstandingReceivables_LeaseComponent_Table, 0.00) AS [OutstandingReceivables_LeaseComponent_Table]
		,	ISNULL(gld.OutstandingReceivables_LeaseComponent_GL, 0.00) AS [OutstandingReceivables_LeaseComponent_GL]
		,	ISNULL(srd.OutstandingReceivables_LeaseComponent_Table, 0.00) - ISNULL(gld.OutstandingReceivables_LeaseComponent_GL, 0.00) AS [OutstandingReceivables_LeaseComponent_Difference]
		,	ISNULL(sd.TotalLongTermReceivables, 0.00) AS [TotalLongTermReceivables]
		,	ISNULL(srd.LongTermReceivables_LeaseComponent_Table, 0.00) AS [LongTermReceivables_LeaseComponent_Table]
		, 	ISNULL(gld.LongTermReceivables_LeaseComponent_GL, 0.00) AS [LongTermReceivables_LeaseComponent_GL]
		,	ISNULL(srd.LongTermReceivables_LeaseComponent_Table, 0.00) - ISNULL(gld.LongTermReceivables_LeaseComponent_GL, 0.00) AS [LongTermReceivables_LeaseComponent_Difference]
		,	CASE WHEN sou.ContractId IS NULL
			THEN ISNULL(ar.BookedResidual_LeaseAssets, 0.00) - ISNULL(ar.CustomerGuaranteedResidual_LeaseAssets, 0.00)
				- ISNULL(ar.ThirdPartyGuaranteedResidual_LeaseAssets, 0.00)
			ELSE ISNULL(sou.ResidualIncomeBalance_LeaseComponent,0.00)
			END AS [UnguaranteedResidual_LeaseComponent_Table]
		,	ISNULL(gld.UnguaranteedResidual_LeaseComponent_GL, 0.00) AS [UnguaranteedResidual_LeaseComponent_GL]
		,	(CASE WHEN sou.ContractId IS NULL
			THEN ISNULL(ar.BookedResidual_LeaseAssets, 0.00) - ISNULL(ar.CustomerGuaranteedResidual_LeaseAssets, 0.00)
				- ISNULL(ar.ThirdPartyGuaranteedResidual_LeaseAssets, 0.00)
			ELSE ISNULL(sou.ResidualIncomeBalance_LeaseComponent,0.00)
			END) - ISNULL(gld.UnguaranteedResidual_LeaseComponent_GL, 0.00) AS [UnguaranteedResidual_LeaseComponent_Difference]
		,	ISNULL(ar.CustomerGuaranteedResidual_LeaseAssets, 0.00) + ISNULL(ar.ThirdPartyGuaranteedResidual_LeaseAssets, 0.00) AS [GuaranteedResidual_LeaseComponent_Table]
		,	ISNULL(gld.GuaranteedResidual_LeaseComponent_GL, 0.00) AS [GuaranteedResidual_LeaseComponent_GL]
		,	ISNULL(ar.CustomerGuaranteedResidual_LeaseAssets, 0.00) + ISNULL(ar.ThirdPartyGuaranteedResidual_LeaseAssets, 0.00) 
				- ISNULL(gld.GuaranteedResidual_LeaseComponent_GL, 0.00) AS [GuaranteedResidual_LeaseComponent_Difference]
--LeaseIncomes
		,	CASE 
				WHEN ec.ContractType = 'SalesType' 
				THEN ISNULL(ec.SalesTypeLeaseGrossProfit_Amount, 0.00)
				ELSE 0.00
			END AS [SalesTypeLeaseGrossProfit_Amount]
		,	CASE 
				WHEN ec.ContractType = 'SalesType' 
				THEN ISNULL(gld.SalesTypeRevenue_GL, 0.00) - ISNULL(gld.CostOfSales_GL, 0.00) 
				ELSE 0.00
			END AS [SalesTypeLeaseGrossProfit_GL]
		,	CASE 
				WHEN ec.ContractType = 'SalesType' 
				THEN ISNULL(ec.SalesTypeLeaseGrossProfit_Amount, 0.00) - (ISNULL(gld.SalesTypeRevenue_GL, 0.00) - ISNULL(gld.CostOfSales_GL, 0.00)) 
				ELSE 0.00
			END AS [SalesTypeLeaseGrossProfit_Difference]
		,	ISNULL(lsd.TotalIncome_Accounting, 0.00) AS [TotalIncome_Accounting]
		,	ISNULL(lsd.TotalIncome_Schedule, 0.00) AS [TotalIncome_Schedule]
		,	ISNULL(lsd.TotalIncome_Accounting, 0.00) - ISNULL(lsd.TotalIncome_Schedule, 0.00) AS [TotalIncome_Accounting_Schedule_Difference]
		,	ISNULL(lsd.TotalSellingProfitIncome_Accounting, 0.00) AS [TotalSellingProfitIncome_Accounting]
		,	ISNULL(lsd.TotalSellingProfitIncome_Schedule, 0.00) AS [TotalSellingProfitIncome_Schedule]
		,	ISNULL(lsd.TotalSellingProfitIncome_Accounting, 0.00) - ISNULL(lsd.TotalSellingProfitIncome_Schedule, 0.00) AS [TotalSellingProfitIncome_Accounting_Schedule_Difference]
		,	ISNULL(lsd.TotalEarnedIncome, 0.00) AS [Lease_TotalEarnedIncome]
		,	ISNULL(lsd.EarnedIncome, 0.00) AS [LeaseEarnedIncome]
		,	ISNULL(gld.LeaseEarnedIncome_GL, 0.00) AS [LeaseEarnedIncome_GL]
		,	ISNULL(lsd.EarnedIncome, 0.00) - ISNULL(gld.LeaseEarnedIncome_GL, 0.00) AS [LeaseEarnedIncome_Difference]
		,	ISNULL(lsd.EarnedResidualIncome, 0.00) AS [LeaseEarnedResidualIncome]
		,	ISNULL(gld.LeaseEarnedResidualIncome_GL, 0.00) AS [LeaseEarnedResidualIncome_GL]
		,	ISNULL(lsd.EarnedResidualIncome, 0.00) - ISNULL(gld.LeaseEarnedResidualIncome_GL, 0.00) AS [LeaseEarnedResidualIncome_Difference]
		,	ISNULL(lsd.EarnedSellingProfitIncome, 0.00) AS [EarnedSellingProfitIncome]
		,	ISNULL(gld.EarnedSellingProfitIncome_GL, 0.00) AS [EarnedSellingProfitIncome_GL]
		,	ISNULL(lsd.EarnedSellingProfitIncome, 0.00) - ISNULL(gld.EarnedSellingProfitIncome_GL, 0.00) AS [EarnedSellingProfitIncome_Difference]
		,	ISNULL(lsd.TotalUnearnedIncome, 0.00) AS [Lease_TotalUnearnedIncome]
		,	ISNULL(lsd.UnearnedIncome, 0.00) AS [LeaseUnearnedIncome]
		,	ISNULL(gld.LeaseUnearnedIncome_GL, 0.00) AS [LeaseUnearnedIncome_GL]
		,	ISNULL(lsd.UnearnedIncome, 0.00) - ISNULL(gld.LeaseUnearnedIncome_GL, 0.00) AS [LeaseUnearnedIncome_Difference]
		,	ISNULL(lsd.UnearnedResidualIncome, 0.00) AS [LeaseUnearnedResidualIncome]
		,	ISNULL(gld.LeaseUnearnedResidualIncome_GL, 0.00) AS [LeaseUnearnedResidualIncome_GL]
		,	ISNULL(lsd.UnearnedResidualIncome, 0.00) - ISNULL(gld.LeaseUnearnedResidualIncome_GL, 0.00) AS [LeaseUnearnedResidualIncome_Difference]
		,	ISNULL(lsd.UnearnedSellingProfitIncome, 0.00) AS [UnearnedSellingProfitIncome]
		,	ISNULL(gld.UnearnedSellingProfitIncome_GL, 0.00) AS [UnearnedSellingProfitIncome_GL]
		,	ISNULL(lsd.UnearnedSellingProfitIncome, 0.00) - ISNULL(gld.UnearnedSellingProfitIncome_GL, 0.00) AS [UnearnedSellingProfitIncome_Difference]
		,	ISNULL(lsd.TotalSuspendedIncome, 0.00) AS [Lease_TotalSuspendedIncome]
		,	ISNULL(lsd.RecognizedSuspendedIncome, 0.00) AS [LeaseRecognizedSuspendedIncome]
		,	ISNULL(gld.LeaseRecognizedSuspendedIncome_GL, 0.00) AS [LeaseRecognizedSuspendedIncome_GL]
		,	ISNULL(lsd.RecognizedSuspendedIncome, 0.00) - ISNULL(gld.LeaseRecognizedSuspendedIncome_GL, 0.00) AS [LeaseRecognizedSuspendedIncome_Difference]
		,	ISNULL(lsd.RecognizedSuspendedResidualIncome, 0.00) AS [LeaseRecognizedSuspendedResidualIncome]
		,	ISNULL(gld.LeaseRecognizedSuspendedResidualIncome_GL, 0.00) AS [LeaseRecognizedSuspendedResidualIncome_GL]
		,	ISNULL(lsd.RecognizedSuspendedResidualIncome, 0.00) - ISNULL(gld.LeaseRecognizedSuspendedResidualIncome_GL, 0.00) AS [LeaseRecognizedSuspendedResidualIncome_Difference]
		,	ISNULL(lsd.RecognizedSuspendedSellingProfitIncome, 0.00) AS [LeaseRecognizedSuspendedSellingProfitIncome]
		,	ISNULL(gld.RecognizedSuspendedSellingProfitIncome_GL, 0.00) AS [RecognizedSuspendedSellingProfitIncome_GL]
		,	ISNULL(lsd.RecognizedSuspendedSellingProfitIncome, 0.00)  - ISNULL(gld.RecognizedSuspendedSellingProfitIncome_GL, 0.00) AS [RecognizedSuspendedSellingProfitIncome_Difference]
--FinanceReceivables
		,	ISNULL(srd.GLPostedReceivables_FinanceComponent_Table, 0.00) AS [GLPostedReceivables_FinanceComponent_Table]
		,	ISNULL(gld.GLPostedReceivables_FinanceComponent_GL, 0.00) AS [GLPostedReceivables_FinanceComponent_GL]
		,	ISNULL(srd.GLPostedReceivables_FinanceComponent_Table, 0.00) - ISNULL(gld.GLPostedReceivables_FinanceComponent_GL, 0.00) AS [GLPostedReceivables_FinanceComponent_Difference]
		,	ISNULL(pr.PaidReceivables_FinanceComponent_Table, 0.00) AS [PaidReceivables_FinanceComponent_Table]
		,	ISNULL(gld.PaidReceivables_FinanceComponent_GL, 0.00) AS [PaidReceivables_FinanceComponent_GL]
		,	ISNULL(pr.PaidReceivables_FinanceComponent_Table, 0.00) - ISNULL(gld.PaidReceivables_FinanceComponent_GL, 0.00) AS [PaidReceivables_FinanceComponent_Difference]
		,	ISNULL(pr.PaidReceivablesviaCash_FinanceComponent_Table, 0.00) AS [PaidReceivablesviaCash_FinanceComponent_Table]
		,	ISNULL(gld.PaidReceivablesviaCash_FinanceComponent_GL, 0.00) AS [PaidReceivablesviaCash_FinanceComponent_GL]
		,	ISNULL(pr.PaidReceivablesviaCash_FinanceComponent_Table, 0.00) - ISNULL(gld.PaidReceivablesviaCash_FinanceComponent_GL, 0.00) AS [PaidReceivablesviaCash_FinanceComponent_Difference]
		,	ISNULL(pr.PaidReceivablesviaNonCash_FinanceComponent_Table, 0.00) AS [PaidReceivablesviaNonCash_FinanceComponent_Table]
		,	ISNULL(gld.PaidReceivablesviaNonCash_FinanceComponent_GL, 0.00) AS [PaidReceivablesviaNonCash_FinanceComponent_GL]
		,	ISNULL(pr.PaidReceivablesviaNonCash_FinanceComponent_Table, 0.00) - ISNULL(gld.PaidReceivablesviaNonCash_FinanceComponent_GL, 0.00) AS [PaidReceivablesviaNonCash_FinanceComponent_Difference]
		,	ISNULL(pd.PrepaidReceivables_FinanceComponent_Table, 0.00) AS [PrepaidReceivables_FinanceComponent_Table]
		,	ISNULL(gld.PrepaidReceivables_FinanceComponent_GL, 0.00) AS [PrepaidReceivables_FinanceComponent_GL]
		,	ISNULL(pd.PrepaidReceivables_FinanceComponent_Table, 0.00) - ISNULL(gld.PrepaidReceivables_FinanceComponent_GL, 0.00) AS [PrepaidReceivables_FinanceComponent_Difference]
		,	ISNULL(srd.OutstandingReceivables_FinanceComponent_Table, 0.00) AS [OutstandingReceivables_FinanceComponent_Table]
		,	ISNULL(gld.OutstandingReceivables_FinanceComponent_GL, 0.00) AS [OutstandingReceivables_FinanceComponent_GL]
		,	ISNULL(srd.OutstandingReceivables_FinanceComponent_Table, 0.00) - ISNULL(gld.OutstandingReceivables_FinanceComponent_GL, 0.00) AS [OutstandingReceivables_FinanceComponent_Difference]
		,	ISNULL(srd.LongTermReceivables_FinanceComponent_Table, 0.00) AS [LongTermReceivables_FinanceComponent_Table]
		, 	ISNULL(gld.LongTermReceivables_FinanceComponent_GL, 0.00) AS [LongTermReceivables_FinanceComponent_GL]
		,	ISNULL(srd.LongTermReceivables_FinanceComponent_Table, 0.00) - ISNULL(gld.LongTermReceivables_FinanceComponent_GL, 0.00) AS [LongTermReceivables_FinanceComponent_Difference]
		,   CASE WHEN sou.ContractId IS NULL
			THEN ISNULL(ar.BookedResidual_FinanceAssets, 0.00) - ISNULL(ar.CustomerGuaranteedResidual_FinanceAssets, 0.00)
				- ISNULL(ar.ThirdPartyGuaranteedResidual_FinanceAssets, 0.00)
			ELSE ISNULL(sou.ResidualIncomeBalance_FinanceComponent,0.00)
			END AS [UnguaranteedResidual_FinanceComponent_Table]
		,	ISNULL(gld.UnguaranteedResidual_FinanceComponent_GL, 0.00) AS [UnguaranteedResidual_FinanceComponent_GL]
		,	(CASE WHEN sou.ContractId IS NULL
			THEN ISNULL(ar.BookedResidual_FinanceAssets, 0.00) - ISNULL(ar.CustomerGuaranteedResidual_FinanceAssets, 0.00)
				- ISNULL(ar.ThirdPartyGuaranteedResidual_FinanceAssets, 0.00)
			ELSE ISNULL(sou.ResidualIncomeBalance_FinanceComponent,0.00)
			END) - ISNULL(gld.UnguaranteedResidual_FinanceComponent_GL, 0.00) AS [UnguaranteedResidual_FinanceComponent_Difference]
		,	ISNULL(ar.CustomerGuaranteedResidual_FinanceAssets, 0.00) + ISNULL(ar.ThirdPartyGuaranteedResidual_FinanceAssets, 0.00) AS [GuaranteedResidual_FinanceComponent_Table]
		,	ISNULL(gld.GuaranteedResidual_FinanceComponent_GL, 0.00) AS [GuaranteedResidual_FinanceComponent_GL]
		,	ISNULL(ar.CustomerGuaranteedResidual_FinanceAssets, 0.00) + ISNULL(ar.ThirdPartyGuaranteedResidual_FinanceAssets, 0.00)
				- ISNULL(gld.GuaranteedResidual_FinanceComponent_GL, 0.00) AS [GuaranteedResidual_FinanceComponent_Difference]
--FinanceIncome
		,	ISNULL(lsd.Finance_TotalIncome_Accounting, 0.00) AS [Finance_TotalIncome_Accounting]
		,	ISNULL(lsd.Finance_TotalIncome_Schedule, 0.00) AS [Finance_TotalIncome_Schedule]
		,	ISNULL(lsd.Finance_TotalIncome_Accounting, 0.00) - ISNULL(lsd.Finance_TotalIncome_Schedule, 0.00) AS [Finance_TotalIncome_Accounting_Schedule_Difference]
		,	ISNULL(lsd.Financing_TotalEarnedIncome, 0.00) AS [Financing_TotalEarnedIncome]
		,	ISNULL(lsd.Financing_EarnedIncome, 0.00) AS [FinanceEarnedIncome]
		,	ISNULL(gld.FinanceEarnedIncome_GL, 0.00) AS [FinanceEarnedIncome_GL]
		,	ISNULL(lsd.Financing_EarnedIncome, 0.00) - ISNULL(gld.FinanceEarnedIncome_GL, 0.00) AS [FinanceEarnedIncome_Difference]
		,	ISNULL(lsd.Financing_EarnedResidualIncome, 0.00) AS [FinanceEarnedResidualIncome]
		,	ISNULL(gld.FinanceEarnedResidualIncome_GL, 0.00) AS [FinanceEarnedResidualIncome_GL]
		,	ISNULL(lsd.Financing_EarnedResidualIncome, 0.00) - ISNULL(gld.FinanceEarnedResidualIncome_GL, 0.00)  AS [FinanceEarnedResidualIncome_Difference]
		,	ISNULL(lsd.Financing_TotalUnearnedIncome, 0.00) AS [FinanceTotalUnearnedIncome]
		,	ISNULL(lsd.Financing_UnearnedIncome, 0.00) AS [FinanceUnearnedIncome]
		,	ISNULL(gld.FinanceUnearnedIncome_GL, 0.00) AS [FinanceUnearnedIncome_GL]
		,	ISNULL(lsd.Financing_UnearnedIncome, 0.00) - ISNULL(gld.FinanceUnearnedIncome_GL, 0.00) AS [FinanceUnearnedIncome_Difference]
		,	ISNULL(lsd.Financing_UnearnedResidualIncome, 0.00) AS [FinanceUnearnedResidualIncome]
		,	ISNULL(gld.FinanceUnearnedResidualIncome_GL, 0.00) AS [FinanceUnearnedResidualIncome_GL]
		,	ISNULL(lsd.Financing_UnearnedResidualIncome, 0.00) - ISNULL(gld.FinanceUnearnedResidualIncome_GL, 0.00) AS [FinanceUnearnedResidualIncome_Difference]
		,	ISNULL(lsd.Financing_TotalSuspendedIncome, 0.00) AS [FinanceTotalSuspendedIncome]
		,	ISNULL(lsd.Financing_RecognizedSuspendedIncome, 0.00) AS [FinanceRecognizedSuspendedIncome]
		,	ISNULL(gld.FinanceRecognizedSuspendedIncome_GL, 0.00) AS [FinanceRecognizedSuspendedIncome_GL]
		,	ISNULL(lsd.Financing_RecognizedSuspendedIncome, 0.00) - ISNULL(gld.FinanceRecognizedSuspendedIncome_GL, 0.00) AS [FinanceRecognizedSuspendedIncome_Difference]
		,	ISNULL(lsd.Financing_RecognizedSuspendedResidualIncome, 0.00) AS [Financing_RecognizedSuspendedResidualIncome]
		,	ISNULL(gld.FinanceRecognizedSuspendedResidualIncome_GL, 0.00) AS [FinanceRecognizedSuspendedResidualIncome_GL]
		,	ISNULL(lsd.Financing_RecognizedSuspendedResidualIncome, 0.00) - ISNULL(gld.FinanceRecognizedSuspendedResidualIncome_GL, 0.00) AS [FinanceRecognizedSuspendedResidualIncome_Difference]
--Capitalized
		,	ISNULL(ctd.CapitalizedSalesTax, 0.00) AS [TotalCapitalizedSalesTax_Table]
		,	ISNULL(gld.CapitalizedSalesTax_GL, 0.00) AS [TotalCapitalizedSalesTax_GL]
		,	ISNULL(ctd.CapitalizedSalesTax, 0.00) - ISNULL(gld.CapitalizedSalesTax_GL, 0.00) AS [TotalCapitalizedSalesTax_Difference]
		,	ISNULL(ctd.CapitalizedInterimInterest, 0.00) AS [TotalCapitalizedInterimInterest_Table]
		,	ISNULL(gld.CapitalizedInterimInterest_GL, 0.00) AS [TotalCapitalizedInterimInterest_GL]
		,	ISNULL(ctd.CapitalizedInterimInterest, 0.00) - ISNULL(gld.CapitalizedInterimInterest_GL, 0.00) AS [TotalCapitalizedInterimInterest_Difference]
		,	ISNULL(ctd.CapitalizedInterimRent, 0.00) AS [TotalCapitalizedInterimRent_Table]
		,	ISNULL(gld.CapitalizedInterimRent_GL, 0.00) AS [TotalCapitalizedInterimRent_GL]
		,	ISNULL(ctd.CapitalizedInterimRent, 0.00) - ISNULL(gld.CapitalizedInterimRent_GL, 0.00) AS [TotalCapitalizedInterimRent_Difference]
		,	ISNULL(ctd.CapitalizedAdditionalCharge, 0.00) AS [TotalCapitalizedAdditionalCharge_Table]
		,	ISNULL(gld.CapitalizedAdditionalCharge_GL, 0.00) AS [TotalCapitalizedAdditionalCharge_GL]
		,	ISNULL(ctd.CapitalizedAdditionalCharge, 0.00) - ISNULL(gld.CapitalizedAdditionalCharge_GL, 0.00) AS [TotalCapitalizedAdditionalCharge_Difference]
--FloatRate
		,	ISNULL(frrd.TotalAmount, 0.00) [Total_FloatRateReceivable_Table]
		,	ISNULL(frrd.LeaseComponentAmount, 0.00) [TotalGLPostedFloatRateReceivables_LeaseComponent_Table]
		,	ISNULL(frrd.NonLeaseComponentAmount, 0.00) [TotalGLPostedFloatRateReceivables_NonLeaseComponent_Table]
		,	ISNULL(gld.TotalGLPosted_GL, 0.00) [TotalGLPostedFloatRateReceivables_GL]
		,	ABS(ISNULL(frrd.LeaseComponentAmount, 0.00) + ISNULL(frrd.NonLeaseComponentAmount, 0.00)) - ABS(ISNULL(gld.TotalGLPosted_GL, 0.00)) [TotalGLPostedFloatRateReceivables_Difference]
		,	ISNULL(frrpd.TotalPaid, 0.00) [TotalPaidFloatRateReceivables_Table]
		,	ISNULL(frrpd.LeaseComponentTotalPaid, 0.00) [TotalPaidFloatRateReceivables_LeaseComponent_Table]
		,	ISNULL(frrpd.NonLeaseComponentTotalPaid, 0.00) [TotalPaidFloatRateReceivables_NonLeaseComponent_Table]
		,	ISNULL(gld.TotalPaid_GL, 0.00) [TotalPaidFloatRateReceivables_NonLeaseComponent_GL]
		,	ABS(ISNULL(frrpd.LeaseComponentTotalPaid, 0.00) + ISNULL(frrpd.NonLeaseComponentTotalPaid, 0.00)) - ABS(ISNULL(gld.TotalPaid_GL, 0.00)) [TotalPaidFloatRateReceivables_Difference]
		,	ISNULL(frrpd.TotalCashPaidAmount, 0.00) [TotalCashPaidFloatRateReceivables_Table]
		,	ISNULL(frrpd.TotalLeaseComponentCashPaidAmount, 0.00) [TotalCashPaidFloatRateReceivables_LeaseComponent_Table]
		,	ISNULL(frrpd.TotalNonLeaseComponentCashPaidAmount, 0.00) [TotalCashPaidFloatRateReceivables_NonLeaseComponent_Table]
		,	ISNULL(gld.TotalCashPaid_GL, 0.00) [TotalCashPaidFloatRateReceivables_NonLeaseComponent_GL]
		,	ABS(ISNULL(frrpd.TotalLeaseComponentCashPaidAmount, 0.00) + ISNULL(frrpd.TotalNonLeaseComponentCashPaidAmount, 0.00)) - ABS(ISNULL(gld.TotalCashPaid_GL, 0.00)) [TotalCashPaidFloatRateReceivables_Difference]
		,	ISNULL(frrpd.TotalNonCashPaidAmount, 0.00) [TotalNonCashPaidFloatRateReceivables_Table]
		,	ISNULL(frrpd.TotalLeaseComponentNonCashPaidAmount, 0.00) [TotalNonCashPaidFloatRateReceivables_LeaseComponent_Table]
		,	ISNULL(frrpd.TotalNonLeaseComponentNonCashPaidAmount, 0.00) [TotalNonCashPaidFloatRateReceivables_NonLeaseComponent_Table]
		,	ISNULL(gld.TotalNonCashPaid_GL, 0.00) [TotalNonCashPaidFloatRateReceivables_NonLeaseComponent_GL]
		,	ABS(ISNULL(frrpd.TotalLeaseComponentNonCashPaidAmount, 0.00) + ISNULL(frrpd.TotalNonLeaseComponentNonCashPaidAmount, 0.00)) - ABS(ISNULL(gld.TotalNonCashPaid_GL, 0.00)) [TotalNonCashPaidFloatRateReceivables_Difference]
		,	ISNULL(frrd.TotalPrepaidAmount, 0.00) [PrepaidFloatRateReceivables_Table]
		,	ISNULL(frrd.LeaseComponentPrepaidAmount, 0.00) [PrepaidFloatRateReceivables_LeaseComponent_Table]
		,	ISNULL(frrd.NonLeaseComponentPrepaidAmount, 0.00) [PrepaidFloatRateReceivables_NonLeaseComponent_Table]
		,	ISNULL(gld.TotalPrePaid_GL, 0.00) [PrepaidFloatRateReceivables_GL]
		,	ABS(ISNULL(frrd.LeaseComponentPrepaidAmount, 0.00) + ISNULL(frrd.NonLeaseComponentPrepaidAmount, 0.00)) - ABS(ISNULL(gld.TotalPrePaid_GL, 0.00)) [PrepaidFloatRateReceivables_Difference]
		,	ISNULL(frrd.TotalOSARAmount, 0.00) [OutstandingFloatRateReceivables_Table]
		,	ISNULL(frrd.LeaseComponentOSARAmount, 0.00) [OutstandingFloatRateReceivables_LeaseComponent_Table]
		,	ISNULL(frrd.NonLeaseComponentOSARAmount, 0.00) [OutstandingFloatRateReceivables_NonLeaseComponent_Table]
		,	ISNULL(gld.OSAR_GL, 0.00) [OutstandingFloatRateReceivables_GL]
		,	ABS(ISNULL(frrd.LeaseComponentOSARAmount, 0.00) + ISNULL(frrd.NonLeaseComponentOSARAmount, 0.00)) - ABS(ISNULL(gld.OSAR_GL, 0.00)) [OutstandingFloatRateReceivables_Difference]
		,	ISNULL(frid.Income_Schedule, 0.00) [TotalFloatRateIncome_Scheduled]
		,	ISNULL(frid.Income_Accounting, 0.00) [TotalFloatRateIncome_Accounting]
		,	ABS(ISNULL(frid.Income_Schedule, 0.00)) - ABS( ISNULL(frid.Income_Accounting, 0.00))			[TotalFloatRateIncome_AccountingAndSchedule_Difference]
		,	ISNULL(frid.Income_GLPosted, 0.00) [Total_GLPostedFloatRateIncome_Table]
		,	ISNULL(gld.TotalFloatRateIncome_GL, 0.00) [Total_GLPostedFloatRateIncome_GL]
		,	ABS(ISNULL(frid.Income_GLPosted, 0.00)) - ABS(ISNULL(gld.TotalFloatRateIncome_GL, 0.00)) [TotalGLPostedFloatRateIncome_Difference]
		,	ISNULL(frid.Income_Suspended, 0.00) [TotalSuspendedIncome_Table]
		,	ISNULL(gld.TotalSuspendedFloatRateIncome_GL, 0.00) [TotalSuspendedIncome_GL]
		,	ABS(ISNULL(frid.Income_Suspended, 0.00)) - ABS(ISNULL(gld.TotalSuspendedFloatRateIncome_GL, 0.00)) [TotalSuspendedIncome_Difference]
		,	ABS(ISNULL(frid.Income_Accrued, 0.00) - (ISNULL(frrd.LeaseComponentAmount, 0.00) + ISNULL(frrd.NonLeaseComponentAmount, 0.00))) [TotalAccruedIncome_Table]
		,	ISNULL(gld.TotalAccruedFloatRateIncome_GL, 0.00) [TotalAccruedIncome_GL]
		,	ABS(ISNULL(frid.Income_Accrued, 0.00) - (ISNULL(frrd.LeaseComponentAmount, 0.00) + ISNULL(frrd.NonLeaseComponentAmount, 0.00))) - ABS(ISNULL(gld.TotalAccruedFloatRateIncome_GL, 0.00)) [TotalAccruedIncome_Difference]
--InterimRent
		,	ISNULL(soir.TotalInterimRentAmount, 0.00) [TotalAmount_InterimRentReceivables_Table]
		,	CASE 
				WHEN @IsRentSharing = 1 
				THEN ISNULL(sovrs.VendorInterimRentSharingAmount, 0.00) 
				ELSE 0.00 
			END [VendorInterimRentSharingAmount_Table]
		,	ISNULL(soir.TotalGLPosted_InterimRentReceivables_Table, 0.00) [TotalGLPosted_InterimRentReceivables_Table]
		,	ISNULL(gld.TotalGLPosted_InterimRentReceivables_GL, 0.00) [TotalGLPosted_InterimRentReceivables_GL]
		,	ISNULL(soir.TotalGLPosted_InterimRentReceivables_Table, 0.00) - ISNULL(gld.TotalGLPosted_InterimRentReceivables_GL, 0.00)	[TotalGLPosted_InterimRentReceivables_Difference]
		,	ISNULL(soir.TotalInterimRentAmount, 0.00) - ISNULL(soir.TotalInterimRentBalanceAmount, 0.00) [TotalPaid_InterimRentReceivables_Table]
		,	ISNULL(gld.TotalPaid_InterimRentReceivables_GL, 0.00) [TotalPaid_InterimRentReceivables_GL]
		,	ISNULL(soir.TotalInterimRentAmount, 0.00) - ISNULL(soir.TotalInterimRentBalanceAmount, 0.00) - ISNULL(gld.TotalPaid_InterimRentReceivables_GL, 0.00) [TotalPaid_InterimRentReceivables_Difference]
		,	ISNULL(soirard.TotalPaidviaCash_InterimRentReceivables_Table, 0.00) [TotalPaidviaCash_InterimRentReceivables_Table]
		,	ISNULL(gld.TotalPaidviaCash_InterimRentReceivables_GL, 0.00) [TotalPaidviaCash_InterimRentReceivables_GL]
		,	ISNULL(soirard.TotalPaidviaCash_InterimRentReceivables_Table, 0.00) - ISNULL(gld.TotalPaidviaCash_InterimRentReceivables_GL, 0.00) [TotalPaidviaCash_InterimRentReceivables_Difference]
		,	ISNULL(soirard.TotalPaidviaNonCash_InterimRentReceivables_Table, 0.00) [TotalPaidviaNonCash_InterimRentReceivables_Table]
		,	ISNULL(gld.TotalPaidviaNonCash_InterimRentReceivables_GL, 0.00) [TotalPaidviaNonCash_InterimRentReceivables_GL]
		,	ISNULL(soirard.TotalPaidviaNonCash_InterimRentReceivables_Table, 0.00) - ISNULL(gld.TotalPaidviaNonCash_InterimRentReceivables_GL, 0.00) [TotalPaidviaNonCash_InterimRentReceivables_Difference]
		,	ISNULL(sopir.TotalPrepaid_InterimRentReceivables_Table, 0.00) [TotalPrepaid_InterimRentReceivables_Table]
		,	ISNULL(gld.TotalPrepaid_InterimRentReceivables_GL, 0.00) [TotalPrepaid_InterimRentReceivables_GL]
		,	ISNULL(sopir.TotalPrepaid_InterimRentReceivables_Table, 0.00) - ISNULL(gld.TotalPrepaid_InterimRentReceivables_GL, 0.00) [TotalPrepaid_InterimRentReceivables_Difference]
		,	ISNULL(soir.TotalOutstandingInterimRentReceivables_Table, 0.00) [TotalOutstanding_InterimRentReceivables_Table]
		,	ISNULL(gld.TotalOutstanding_InterimRentReceivables_GL, 0.00) [TotalOutstanding_InterimRentReceivables_GL]
		,	ISNULL(soir.TotalOutstandingInterimRentReceivables_Table, 0.00) - ISNULL(gld.TotalOutstanding_InterimRentReceivables_GL, 0.00) [TotalOutstanding_InterimRentReceivables_Difference]
		,	ISNULL(ilis.TotalScheduleRentalIncome_InterimRentIncome_Table, 0.00) [TotalScheduleRentalIncome_InterimRentIncome_Table]
		,	ISNULL(ilis.TotalAccountingRentalIncome_InterimRentIncome_Table, 0.00) [TotalAccountingRentalIncome_InterimRentIncome_Table]
		,	ISNULL(ilis.GLPosted_InterimRentIncome_Table, 0.00) [GLPosted_InterimRentIncome_Table]
		,	ISNULL(gld.GLPosted_InterimRentIncome_GL, 0.00) [GLPosted_InterimRentIncome_GL]
		,	ISNULL(ilis.GLPosted_InterimRentIncome_Table, 0.00) - ISNULL(gld.GLPosted_InterimRentIncome_GL, 0.00) [GLPosted_InterimRentIncome_Difference]
		,	ISNULL(ilis.TotalCapitalizedIncome_InterimRentIncome_Table, 0.00) [TotalCapitalizedIncome_InterimRentIncome_Table]
		,	ISNULL(gld.TotalCapitalizedIncome_InterimRentIncome_GL, 0.00) [TotalCapitalizedIncome_InterimRentIncome_GL]
		,	ISNULL(ilis.TotalCapitalizedIncome_InterimRentIncome_Table, 0.00) - ISNULL(gld.TotalCapitalizedIncome_InterimRentIncome_GL, 0.00) [TotalCapitalizedIncome_InterimRentIncome_Difference]
		,	CASE	
				WHEN @DeferInterimRentIncomeRecognition = 'False' 	
					AND @DeferInterimRentIncomeRecognitionForSingleInstallment = 'False'	
				THEN (ISNULL(ilis.TotalAccountingRentalIncome_InterimRentIncome_Table, 0.00) - ISNULL(ilis.TotalCapitalizedIncome_InterimRentIncome_Table, 0.00)) - (ISNULL(soir.TotalInterimRentAmount, 0.00) - ISNULL(sovrs.VendorInterimRentSharingAmount, 0.00))	
				ELSE 0.00	
			END [TotalInterimRent_IncomeandReceivable_Difference]
		,	ISNULL(iob.DeferInterimRentIncome_Table, 0.00) [DeferInterimRentIncome_Table]
		,	ISNULL(gld.DeferInterimRentIncome_GL, 0.00) [DeferInterimRentIncome_GL]
		,	ISNULL(iob.DeferInterimRentIncome_Table, 0.00) - ISNULL(gld.DeferInterimRentIncome_GL, 0.00) [DeferInterimRentIncome_Difference]
--InterimInterest
		,	ISNULL(soir.TotalInterimInterestAmount, 0.00) [TotalAmount_InterimInterestReceivables_Table]
		,	ISNULL(soir.TotalGLPosted_InterimInterestReceivables_Table, 0.00) [TotalGLPosted_InterimInterestReceivables_Table]
		,	ISNULL(gld.TotalGLPosted_InterimInterestReceivables_GL, 0.00) [TotalGLPosted_InterimInterestReceivables_GL]
		,	ISNULL(soir.TotalGLPosted_InterimInterestReceivables_Table, 0.00) - ISNULL(gld.TotalGLPosted_InterimInterestReceivables_GL, 0.00)	[TotalGLPosted_InterimInterestReceivables_Difference]
		,	ISNULL(soir.TotalInterimInterestAmount, 0.00) - ISNULL(soir.TotalInterimInterestBalanceAmount, 0.00) [TotalPaid_InterimInterestReceivables_Table]
		,	ISNULL(gld.TotalPaid_InterimInterestReceivables_GL, 0.00) [TotalPaid_InterimInterestReceivables_GL]
		,	ISNULL(soir.TotalInterimInterestAmount, 0.00) - ISNULL(soir.TotalInterimInterestBalanceAmount, 0.00) - ISNULL(gld.TotalPaid_InterimInterestReceivables_GL, 0.00) [TotalPaid_InterimInterestReceivables_Difference]
		,	ISNULL(soirard.TotalPaidviaCash_InterimInterestReceivables_Table, 0.00) [TotalPaidviaCash_InterimInterestReceivables_Table]
		,	ISNULL(gld.TotalPaidviaCash_InterimInterestReceivables_GL, 0.00) [TotalPaidviaCash_InterimInterestReceivables_GL]
		,	ISNULL(soirard.TotalPaidviaCash_InterimInterestReceivables_Table, 0.00) - ISNULL(gld.TotalPaidviaCash_InterimInterestReceivables_GL, 0.00) [TotalPaidviaCash_InterimInterestReceivables_Difference]
		,	ISNULL(soirard.TotalPaidviaNonCash_InterimInterestReceivables_Table, 0.00) [TotalPaidviaNonCash_InterimInterestReceivables_Table]
		,	ISNULL(gld.TotalPaidviaNonCash_InterimInterestReceivables_GL, 0.00) [TotalPaidviaNonCash_InterimInterestReceivables_GL]
		,	ISNULL(soirard.TotalPaidviaNonCash_InterimInterestReceivables_Table, 0.00) - ISNULL(gld.TotalPaidviaNonCash_InterimInterestReceivables_GL, 0.00) [TotalPaidviaNonCash_InterimInterestReceivables_Difference]
		,	ISNULL(sopir.TotalPrepaid_InterimInterestReceivables_Table, 0.00) [TotalPrepaid_InterimInterestReceivables_Table]
		,	ISNULL(gld.TotalPrepaid_InterimInterestReceivables_GL, 0.00) [TotalPrepaid_InterimInterestReceivables_GL]
		,	ISNULL(sopir.TotalPrepaid_InterimInterestReceivables_Table, 0.00) - ISNULL(gld.TotalPrepaid_InterimInterestReceivables_GL, 0.00) [TotalPrepaid_InterimInterestReceivables_Difference]
		,	ISNULL(soir.TotalOutstandingInterimInterestReceivables_Table, 0.00) [TotalOutstanding_InterimInterestReceivables_Table]
		,	ISNULL(gld.TotalOutstanding_InterimInterestReceivables_GL, 0.00) [TotalOutstanding_InterimInterestReceivables_GL]
		,	ISNULL(soir.TotalOutstandingInterimInterestReceivables_Table, 0.00) - ISNULL(gld.TotalOutstanding_InterimInterestReceivables_GL, 0.00) [TotalOutstanding_InterimInterestReceivables_Difference]
		,	ISNULL(ilis.TotalScheduleIncome_InterimInterestIncome_Table, 0.00) [TotalScheduleIncome_InterimInterestIncome_Table]
		,	ISNULL(ilis.TotalAccountingIncome_InterimInterestIncome_Table, 0.00) [TotalAccountingIncome_InterimInterestIncome_Table]
		,	ISNULL(ilis.GLPosted_InterimInterestIncome_Table, 0.00) [GLPosted_InterimInterestIncome_Table]
		,	ISNULL(gld.GLPosted_InterimInterestIncome_GL, 0.00) [GLPosted_InterimInterestIncome_GL]
		,	ISNULL(ilis.GLPosted_InterimInterestIncome_Table, 0.00) - ISNULL(gld.GLPosted_InterimInterestIncome_GL, 0.00) [GLPosted_InterimInterestIncome_Difference]
		,	ISNULL(ilis.TotalCapitalizedIncome_InterimInterestIncome_Table, 0.00) [TotalCapitalizedIncome_InterimInterestIncome_Table]
		,	ISNULL(gld.TotalCapitalizedIncome_InterimInterestIncome_GL, 0.00) [TotalCapitalizedIncome_InterimInterestIncome_GL]
		,	ISNULL(ilis.TotalCapitalizedIncome_InterimInterestIncome_Table, 0.00) - ISNULL(gld.TotalCapitalizedIncome_InterimInterestIncome_GL, 0.00) [TotalCapitalizedIncome_InterimInterestIncome_Difference]
		,	CASE	
				WHEN @DeferInterimInterestIncomeRecognition = 'False' 	
					AND @DeferInterimInterestIncomeRecognitionForSingleInstallment = 'False'	
				THEN ISNULL(ilis.TotalAccountingIncome_InterimInterestIncome_Table, 0.00) - ISNULL(ilis.TotalCapitalizedIncome_InterimInterestIncome_Table, 0.00) - ISNULL(soir.TotalInterimInterestAmount, 0.00) 	
				ELSE 0.00
			END [TotalInterimInterest_IncomeandReceivable_Difference]
		,	ISNULL(iob.AccruedInterimInterestIncome_Table, 0.00) [AccruedInterimInterestIncome_Table]
		,	ISNULL(gld.AccruedInterimInterestIncome_GL, 0.00) [AccruedInterimInterestIncome_GL]
		,	ISNULL(iob.AccruedInterimInterestIncome_Table, 0.00) - ISNULL(gld.AccruedInterimInterestIncome_GL, 0.00) [AccruedInterimInterestIncome_Difference]
--WriteDownAndChargeOff
		,	ISNULL(wdi.GrossWriteDown_Table, 0.00) AS [GrossWriteDown_Table]
		,	ISNULL(gld.GrossWriteDown_GL, 0.00) AS [GrossWriteDown_GL]
		,	ISNULL(wdi.GrossWriteDown_Table, 0.00) - ISNULL(gld.GrossWriteDown_GL, 0.00) AS [GrossWriteDown_Difference]
		,	ISNULL(wdi.WriteDownRecovered_Table, 0.00) AS [WriteDownRecovered_Table]
		,	ISNULL(gld.WriteDownRecovered_GL, 0.00) AS [WriteDownRecovered_GL]
		,	ISNULL(wdi.WriteDownRecovered_Table, 0.00) - ISNULL(gld.WriteDownRecovered_GL, 0.00) AS [WriteDownRecovered_Difference]
		,	ISNULL(wdi.GrossWriteDown_Table, 0.00) - ISNULL(wdi.WriteDownRecovered_Table, 0.00) AS [NetWriteDown_Table]
		,	ISNULL(gld.GrossWriteDown_GL, 0.00) - ISNULL(gld.WriteDownRecovered_GL, 0.00) AS [NetWriteDown_GL]
		,	(ISNULL(wdi.GrossWriteDown_Table, 0.00) - ISNULL(wdi.WriteDownRecovered_Table, 0.00)) - (ISNULL(gld.GrossWriteDown_GL, 0.00) - ISNULL(gld.WriteDownRecovered_GL, 0.00)) AS [NetWriteDown_Difference]
		,	ISNULL(coi.ChargeOffExpense_LC_Table, 0.00) AS [ChargeOffExpense_LeaseComponent_Table]
		,	ISNULL(gld.ChargeOffExpense_GL, 0.00) AS [ChargeOffExpense_LeaseComponent_GL]
		,	ISNULL(coi.ChargeOffExpense_LC_Table, 0.00) - ISNULL(gld.ChargeOffExpense_GL, 0.00) AS [ChargeOffExpense_LeaseComponent_Difference]
		,	ISNULL(coi.ChargeOffExpense_NLC_Table, 0.00) AS [ChargeOffExpense_NonLeaseComponent_Table]
		,	ISNULL(gld.FinancingChargeOffExpense_GL, 0.00) AS [ChargeOffExpense_NonLeaseComponent_GL]
		,	ISNULL(coi.ChargeOffExpense_NLC_Table, 0.00) - ISNULL(gld.FinancingChargeOffExpense_GL, 0.00) AS [ChargeOffExpense_NonLeaseComponent_Difference]
		,	ISNULL(coi.ChargeOffExpense, 0.00) AS [TotalChargeoffAmount_Table]
		,	ISNULL(coi.ChargeOffExpense_LC_Table, 0.00) + ISNULL(coi.ChargeOffExpense_NLC_Table, 0.00) AS [TotalChargeoffAmount_Calculation]
		,   ISNULL(coi.ChargeOffExpense, 0.00) - (ISNULL(coi.ChargeOffExpense_LC_Table, 0.00) + ISNULL(coi.ChargeOffExpense_NLC_Table, 0.00)) AS [TotalChargeoffAmountVSLCAndNLC]
		,   IIF(@IsGainPresent = 1, ISNULL(coi.ChargeOffRecovery_LC_Table, 0.00), ISNULL(coi.ChargeOffRecovery_LC_Table, 0.00) - ISNULL(pr.ChargeOffGainOnRecovery_LeaseComponent_Table, 0.00))  AS [ChargeOffRecovery_LeaseComponent_Table]
		,   ISNULL(gld.ChargeOffRecovery_GL, 0.00) AS [ChargeOffRecovery_LeaseComponent_GL]
		,   IIF(@IsGainPresent = 1, ISNULL(coi.ChargeOffRecovery_LC_Table, 0.00), ISNULL(coi.ChargeOffRecovery_LC_Table, 0.00) - ISNULL(pr.ChargeOffGainOnRecovery_LeaseComponent_Table, 0.00)) - ISNULL(gld.ChargeOffRecovery_GL, 0.00) AS [ChargeOffRecovery_LeaseComponent_Difference]
		,   IIF(@IsGainPresent = 1, ISNULL(coi.ChargeOffRecovery_NLC_Table, 0.00), ISNULL(coi.ChargeOffRecovery_NLC_Table, 0.00) - ISNULL(pr.ChargeOffGainOnRecovery_NonLeaseComponent_Table, 0.00)) AS [ChargeOffRecovery_NonLeaseComponent_Table]
		,   ISNULL(gld.FinancingChargeOffRecovery_GL, 0.00) AS [ChargeOffRecovery_NonLeaseComponent_GL]
		,   IIF(@IsGainPresent = 1, ISNULL(coi.ChargeOffRecovery_NLC_Table, 0.00), ISNULL(coi.ChargeOffRecovery_NLC_Table, 0.00) - ISNULL(pr.ChargeOffGainOnRecovery_NonLeaseComponent_Table, 0.00)) - ISNULL(gld.FinancingChargeOffRecovery_GL, 0.00) AS [ChargeOffRecovery_NonLeaseComponent_Difference]
		,	IIF(@IsGainPresent = 1, ISNULL(coi.GainOnRecovery_LC_Table, 0.00), ISNULL(pr.ChargeOffGainOnRecovery_LeaseComponent_Table, 0.00)) AS [ChargeOffGainOnRecovery_LeaseComponent_Table]
		,	ISNULL(gld.ChargeOffGainOnRecovery_GL, 0.00) AS [ChargeOffGainOnRecovery_LeaseComponent_GL]
		,	IIF(@IsGainPresent = 1, ISNULL(coi.GainOnRecovery_LC_Table, 0.00), ISNULL(pr.ChargeOffGainOnRecovery_LeaseComponent_Table, 0.00)) - ISNULL(gld.ChargeOffGainOnRecovery_GL, 0.00) AS [ChargeOffGainOnRecovery_LeaseComponent_Difference]
		,	IIF(@IsGainPresent = 1, ISNULL(coi.GainOnRecovery_NLC_Table, 0.00), ISNULL(pr.ChargeOffGainOnRecovery_NonLeaseComponent_Table , 0.00)) AS [ChargeOffGainOnRecovery_NonLeaseComponent_Table]
		,	ISNULL(gld.FinancingChargeOffGainOnRecovery_GL, 0.00) AS [ChargeOffGainOnRecovery_NonLeaseComponent_GL]
		,	IIF(@IsGainPresent = 1, ISNULL(coi.GainOnRecovery_NLC_Table, 0.00), ISNULL(pr.ChargeOffGainOnRecovery_NonLeaseComponent_Table, 0.00)) - ISNULL(gld.FinancingChargeOffGainOnRecovery_GL, 0.00) AS [ChargeOffGainOnRecovery_NonLeaseComponent_Difference]
		,	ISNULL(coi.ChargeOffRecovery, 0.00) AS [TotalRecoveryAndGain_Table] 
		,   IIF(@IsGainPresent = 1, ISNULL(coi.ChargeOffRecovery_LC_Table, 0.00), ISNULL(coi.ChargeOffRecovery_LC_Table, 0.00) - ISNULL(pr.ChargeOffGainOnRecovery_LeaseComponent_Table, 0.00)) + IIF(@IsGainPresent = 1, ISNULL(coi.ChargeOffRecovery_NLC_Table, 0.00), ISNULL(coi.ChargeOffRecovery_NLC_Table, 0.00) - ISNULL(pr.ChargeOffGainOnRecovery_NonLeaseComponent_Table, 0.00)) + IIF(@IsGainPresent = 1, ISNULL(coi.GainOnRecovery_LC_Table, 0.00) +  ISNULL(coi.GainOnRecovery_NLC_Table, 0.00), ISNULL(pr.ChargeOffGainOnRecovery_LeaseComponent_Table, 0.00) + ISNULL(pr.ChargeOffGainOnRecovery_NonLeaseComponent_Table, 0.00)) AS [TotalRecoveryAndGain_Calculation] 
		,   ISNULL(coi.ChargeOffRecovery, 0.00) - (IIF(@IsGainPresent = 1, ISNULL(coi.ChargeOffRecovery_LC_Table, 0.00), ISNULL(coi.ChargeOffRecovery_LC_Table, 0.00) - ISNULL(pr.ChargeOffGainOnRecovery_LeaseComponent_Table, 0.00)) + IIF(@IsGainPresent = 1, ISNULL(coi.ChargeOffRecovery_NLC_Table, 0.00), ISNULL(coi.ChargeOffRecovery_NLC_Table, 0.00) - ISNULL(pr.ChargeOffGainOnRecovery_NonLeaseComponent_Table, 0.00)) + IIF(@IsGainPresent = 1, ISNULL(coi.GainOnRecovery_LC_Table, 0.00) +  ISNULL(coi.GainOnRecovery_NLC_Table, 0.00), ISNULL(pr.ChargeOffGainOnRecovery_LeaseComponent_Table, 0.00) + ISNULL(pr.ChargeOffGainOnRecovery_NonLeaseComponent_Table, 0.00))) AS [TotalRecoveryAndGainVSRecoveryAndGainLCAndNLC]
--UnAppliedAR
		,	ISNULL(sort.ReceiptBalance_Amount, 0.00) + ISNULL(sop.PayablesBalance_Amount, 0.00) AS [UnAppliedCash_Table]
		,	ISNULL(gld.ContractUnAppliedAR_GL, 0.00) - ISNULL(rrf.Refunds_GL, 0.00) AS [UnAppliedCash_GL]
		,	(ISNULL(sort.ReceiptBalance_Amount, 0.00) + ISNULL(sop.PayablesBalance_Amount, 0.00)) - (ISNULL(gld.ContractUnAppliedAR_GL, 0.00) - ISNULL(rrf.Refunds_GL, 0.00)) AS [UnAppliedCash_Difference]
--SalesTaxes
		,	ISNULL(rtxd.GLPostedTaxes, 0.00) - ISNULL(stxd.GLPosted_CashRem_NonCash, 0.00) AS [TotalGLPostedSalesTaxReceivables_Table]
		,	ISNULL(gld.GLPostedSalesTaxReceivable_GL, 0.00) AS [TotalGLPostedSalesTaxReceivable_GL]
		,	ABS(ABS(ISNULL(rtxd.GLPostedTaxes, 0.00)) - ABS(ISNULL(stxd.GLPosted_CashRem_NonCash, 0.00))) - ABS(ISNULL(gld.GLPostedSalesTaxReceivable_GL, 0.00)) [TotalGLPosted_SalesTaxReceivable_Difference]
		,	ISNULL(stxd.TotalPaid_taxes, 0.00) - ISNULL(stxd.Paid_CashRem_NonCash, 0.00) AS [TotalPaid_SalesTaxReceivables_Table]
		,	ISNULL(gld.TotalPaid_SalesTaxReceivables_GL, 0.00) AS [TotalPaid_SalesTaxReceivables_GL]
		,	ISNULL(stxd.TotalPaid_taxes, 0.00) - ISNULL(stxd.Paid_CashRem_NonCash, 0.00) - ISNULL(gld.TotalPaid_SalesTaxReceivables_GL, 0.00) AS [TotalPaid_SalesTaxReceivables_Difference]
		,	ISNULL(stxd.TotalPrePaid_Taxes, 0.00) AS [TotalPrepaidPaid_SalesTaxReceivables_Table]
		,	ISNULL(gld.PrePaidTaxes_GL, 0.00) - ISNULL(gld.PrePaidTaxReceivable_GL, 0.00) AS [TotalPrepaidPaid_SalesTaxReceivables_GL]
		,	ABS(ISNULL(stxd.TotalPrePaid_Taxes, 0.00)) - ABS(ISNULL(gld.PrePaidTaxes_GL, 0.00) - ISNULL(gld.PrePaidTaxReceivable_GL, 0.00)) AS [TotalPrepaidPaid_SalesTaxReceivables_Difference]
		,	ISNULL(rtxd.OutStandingTaxes, 0.00) AS [TotalOutstanding_SalesTaxReceivables_Table]
		,	ISNULL(gld.TaxReceivablePosted_GL, 0.00) - ISNULL(gld.TaxReceivablesPaid_GL, 0.00) AS [TotalOutstanding_SalesTaxReceivables_GL]
		,	ABS(ISNULL(rtxd.OutStandingTaxes, 0.00)) - ABS(ISNULL(gld.TaxReceivablePosted_GL, 0.00) - ISNULL(gld.TaxReceivablesPaid_GL, 0.00)) AS [TotalOutstanding_SalesTaxReceivables_Difference]
		,	ISNULL(stxd.PaidTaxesviaCash, 0.00) AS [TotalPaidviacash_SalesTaxReceivables_Table]
		,	ISNULL(gld.Paid_SalesTaxReceivablesviaCash_GL, 0.00) AS [TotalPaidviacash_SalesTaxReceivables_GL]
		,	ISNULL(stxd.PaidTaxesviaCash, 0.00) - ISNULL(gld.Paid_SalesTaxReceivablesviaCash_GL, 0.00) AS [TotalPaidviacash_SalesTaxReceivables_Difference]
		,	ISNULL(stxd.PaidTaxesviaNonCash, 0.00) - ISNULL(stxd.GLPosted_CashRem_NonCash, 0.00) AS [TotalPaidvianoncash_SalesTaxReceivables_Table]
		,	ISNULL(gld.Paid_SalesTaxReceivablesviaNonCash_GL, 0.00) AS [TotalPaidvianoncash_SalesTaxReceivables_GL]
		,	ISNULL(stxd.PaidTaxesviaNonCash, 0.00) - ISNULL(stxd.GLPosted_CashRem_NonCash, 0.00) - ISNULL(gld.Paid_SalesTaxReceivablesviaNonCash_GL, 0.00) AS [TotalPaidvianoncash_SalesTaxReceivables_Difference]
--FunderOwned
		,	ABS(ABS(ISNULL(frd.GLPostedFO, 0.00)) - ABS(ISNULL(frard.NonCashAmountFO, 0.00))) [TotalGLPosted_FunderOwned_Receivables]
		,	ABS(ABS(ISNULL(frt.FunderRemittingSalesTaxGLPosted, 0.00)) - ABS(ISNULL(stn.FunderPortionNonCash, 0.00))) [TotalGLPosted_FunderOwned_SalesTax]
		,	ABS(ABS(ISNULL(frd.GLPostedFO, 0.00)) - ABS(ISNULL(frard.NonCashAmountFO, 0.00))) + ABS(ABS(ISNULL(frt.FunderRemittingSalesTaxGLPosted, 0.00)) - ABS(ISNULL(stn.FunderPortionNonCash, 0.00))) [TotalGLPosted_FunderOwned_Table]
		,	ABS(ISNULL(gld.TotalGLPosted_FunderOwned_GL, 0.00)) [TotalGLPosted_FunderOwned_GL]
		,	(ABS(ABS(ISNULL(frd.GLPostedFO, 0.00)) - ABS(ISNULL(frard.NonCashAmountFO, 0.00))) + ABS(ABS(ISNULL(frt.FunderRemittingSalesTaxGLPosted, 0.00)) - ABS(ISNULL(stn.FunderPortionNonCash, 0.00)))) - ABS(ISNULL(gld.TotalGLPosted_FunderOwned_GL, 0.00)) [TotalGLPosted_FunderOwned_Difference]
		,	ISNULL(frard.PaidCashFO, 0.00) [TotalPaidCash_FunderOwned_Receivables]
		,	ISNULL(frard.SalesTaxCashAppliedFO, 0.00) [TotalPaidCash_FunderOwned_SalesTax]
		,	ISNULL(frard.PaidCashFO, 0.00) + ISNULL(frard.SalesTaxCashAppliedFO, 0.00) [TotalPaidCash_FunderOwned_Table]
		,	ISNULL(gld.TotalPaidCash_FunderOwned_GL, 0.00) [TotalPaidCash_FunderOwned_GL]
		,	(ISNULL(frard.PaidCashFO, 0.00) + ISNULL(frard.SalesTaxCashAppliedFO, 0.00)) - ISNULL(gld.TotalPaidCash_FunderOwned_GL, 0.00) [TotalPaidCash_FunderOwned_Difference]
		,	ABS(ISNULL(frard.PaidNonCashFO, 0.00)) - ABS(ISNULL(frard.NonCashAmountFO, 0.00)) [TotalPaidNonCash_FunderOwned_Receivables]
		,	ABS(ISNULL(frard.SalesTaxNonCashAppliedFO, 0.00)) - ABS(ISNULL(frard.NonCashAmountFO, 0.00)) [TotalPaidNonCash_FunderOwned_SalesTax]
		,	(ABS(ISNULL(frard.PaidNonCashFO, 0.00)) - ABS(ISNULL(frard.NonCashAmountFO, 0.00))) + (ABS(ISNULL(frard.SalesTaxNonCashAppliedFO, 0.00)) - ABS(ISNULL(frard.NonCashAmountFO, 0.00))) [TotalPaidNonCash_FunderOwned_Table]
		,	ISNULL(gld.TotalPaidNonCash_FunderOwned_GL, 0.00) [TotalPaidNonCash_FunderOwned_GL]
		,	((ABS(ISNULL(frard.PaidNonCashFO, 0.00)) - ABS(ISNULL(frard.NonCashAmountFO, 0.00))) + (ABS(ISNULL(frard.SalesTaxNonCashAppliedFO, 0.00)) - ABS(ISNULL(frard.NonCashAmountFO, 0.00)))) - ISNULL(gld.TotalPaidNonCash_FunderOwned_GL, 0.00) [TotalPaidNonCash_FunderOwned_Difference]
		,	ISNULL(frd.OutstandingFO, 0.00) [TotalOSAR_FunderOwned_Receivables]
		,	ISNULL(frt.FunderRemittingSalesTaxOSAR, 0.00) [TotalOSAR_FunderOwned_SalesTax]
		,	ISNULL(frd.OutstandingFO, 0.00) + ISNULL(frt.FunderRemittingSalesTaxOSAR, 0.00) [TotalOSAR_FunderOwned_Table]
		,	ISNULL(gld.TotalOutstanding_FunderOwned_GL, 0.00) [TotalOutstanding_FunderOwned_GL]
		,	ISNULL(frd.OutstandingFO, 0.00) + ISNULL(frt.FunderRemittingSalesTaxOSAR, 0.00) - ISNULL(gld.TotalOutstanding_FunderOwned_GL, 0.00) [TotalOSAR_FunderOwned_Difference]
		,	ISNULL(frd.PrepaidFO, 0.00) [TotalPrepaid_FunderOwned_Receivables]
		,	ABS(ISNULL(frt.FunderRemittingSalesTaxPrepaid, 0.00)) [TotalPrepaid_FunderOwned_SalesTax]
		,	ISNULL(frd.PrepaidFO, 0.00) + ABS(ISNULL(frt.FunderRemittingSalesTaxPrepaid, 0.00)) [TotalPrepaid_FunderOwned_Table]
		,	ISNULL(gld.TotalPrepaid_FunderOwned_GL, 0.00) [TotalPrepaid_FunderOwned_GL]
		,	ISNULL(frd.PrepaidFO, 0.00) + ABS(ISNULL(frt.FunderRemittingSalesTaxPrepaid, 0.00)) - ISNULL(gld.TotalPrepaid_FunderOwned_GL, 0.00) [TotalPrepaid_FunderOwned_Difference]
		,	ISNULL(frt.LessorRemittingSalesTaxGLPosted, 0.00) - ISNULL(stn.FunderPortionNonCash, 0.00) [TotalGLPosted_FunderOwned_LessorRemit_SalesTax_Table]
		,	ISNULL(gld.TotalGLPosted_FunderOwned_LessorRemit_SalesTax_GL, 0.00) [TotalGLPosted_FunderOwned_LessorRemit_SalesTax_GL]
		,	(ISNULL(frt.LessorRemittingSalesTaxGLPosted, 0.00) - ISNULL(stn.FunderPortionNonCash, 0.00)) - ISNULL(gld.TotalGLPosted_FunderOwned_LessorRemit_SalesTax_GL, 0.00) [TotalGLPosted_FunderOwned_LessorRemit_SalesTax_Difference]
		,	ISNULL(frard.LessorSalesTaxCashAppliedFO, 0.00) [TotalPaidCash_FunderOwned_LessorRemit_SalesTax_Table]
		,	ISNULL(gld.TotalPaidCash_FunderOwned_LessorRemit_SalesTax_GL, 0.00) [TotalPaidCash_FunderOwned_LessorRemit_SalesTax_GL]
		,	ISNULL(frard.LessorSalesTaxCashAppliedFO, 0.00) - ISNULL(gld.TotalPaidCash_FunderOwned_LessorRemit_SalesTax_GL, 0.00) [TotalPaidCash_FunderOwned_LessorRemit_SalesTax_Difference]
		,	ISNULL(frard.LessorSalesTaxNonCashAppliedFO, 0.00) [TotalPaidNonCash_FunderOwned_LessorRemit_SalesTax_Table]
		,	ISNULL(gld.TotalPaidNonCash_FunderOwned_LessorRemit_SalesTax_GL, 0.00) [TotalPaidNonCash_FunderOwned_LessorRemit_SalesTax_GL]
		,	ISNULL(frard.LessorSalesTaxNonCashAppliedFO, 0.00) - ISNULL(gld.TotalPaidNonCash_FunderOwned_LessorRemit_SalesTax_GL, 0.00) [TotalPaidNonCash_FunderOwned_LessorRemit_SalesTax_Difference]
		,	ISNULL(frt.LessorRemittingSalesTaxOSAR, 0.00) [TotalOSAR_FunderOwned_LessorRemit_SalesTax_Table]
		,	ISNULL(gld.TotalOutstanding_FunderOwned_LessorRemit_SalesTax_GL, 0.00) [TotalOSAR_FunderOwned_LessorRemit_SalesTax_GL]
		,	ISNULL(frt.LessorRemittingSalesTaxOSAR, 0.00) - ISNULL(gld.TotalOutstanding_FunderOwned_LessorRemit_SalesTax_GL, 0.00) [TotalOSAR_FunderOwned_LessorRemit_SalesTax_Difference]
		,	ISNULL(frt.LessorRemittingSalesTaxPrepaid, 0.00) [TotalPrepaid_FunderOwned_LessorRemit_SalesTax_Table]
		,	ISNULL(gld.TotalPrepaid_FunderOwned_LessorRemit_SalesTax_GL, 0.00) [TotalPrepaid_FunderOwned_LessorRemit_SalesTax_GL]
		,	ISNULL(frt.LessorRemittingSalesTaxPrepaid, 0.00) - ISNULL(gld.TotalPrepaid_FunderOwned_LessorRemit_SalesTax_GL, 0.00) [TotalPrepaid_FunderOwned_LessorRemit_SalesTax_Difference]

		,   CASE
				WHEN cwmg.ContractId IS NOT NULL
				THEN 'Yes'
				ELSE 'No'
			END [IsManualGLEntryPosted]
	FROM #EligibleContracts ec 
		INNER JOIN LegalEntities ON LegalEntities.Id = ec.LegalEntityId
		INNER JOIN LineofBusinesses lob ON lob.Id = ec.LineofBusinessId
		INNER JOIN Parties ON ec.CustomerId = Parties.id
		LEFT JOIN #OverTerm ot ON ec.ContractID = ot.ContractID
		LEFT JOIN #PaymentAmount pa ON pa.ContractId = ec.ContractId
		LEFT JOIN #FullPaidOffContracts fpc ON fpc.ContractId = ec.ContractId 
		LEFT JOIN #LeaseAmendment rl ON rl.ContractId = ec.ContractId 
		LEFT JOIN #HasFinanceAsset fa ON fa.ContractId = ec.ContractId 
		LEFT JOIN #ChargeOff co ON co.ContractId = ec.ContractId 
		LEFT JOIN #AccrualDetails ad ON ad.ContractId = ec.ContractId
		LEFT JOIN #SumOfReceivables sd ON sd.ContractId = ec.ContractId
		LEFT JOIN #SumOfReceivableDetails srd ON srd.ContractId = ec.ContractId
		LEFT JOIN #PaidReceivables pr ON pr.ContractId = ec.ContractId
		LEFT JOIN #PrePaid pd ON pd.ContractId = ec.ContractId
		LEFT JOIN #AssetResiduals ar ON ar.ContractId = ec.ContractId
		LEFT JOIN #SaleOfPaymentsUnguaranteedInfo sou ON sou.ContractId = ec.ContractId
		LEFT JOIN #LeaseIncomeScheduleDetails lsd ON lsd.ContractID = ec.ContractID
		LEFT JOIN #WriteDownInfo wdi ON wdi.ContractId = ec.ContractId
		LEFT JOIN #ChargeOffInfo coi ON coi.ContractId = ec.ContractId
		LEFT JOIN #SumOfReceipts sort ON sort.ContractId = ec.ContractId
		LEFT JOIN #SumOfPayables sop ON sop.ContractId = ec.ContractId
		LEFT JOIN #SalesTaxDetails stxd ON stxd.ContractId = ec.ContractId
		LEFT JOIN #ReceivableTaxDetails rtxd ON rtxd.ContractId = ec.ContractId
		LEFT JOIN #CapitalizedDetails ctd ON ctd.ContractId = ec.ContractId
		LEFT JOIN #SumOfInterimReceivables soir ON soir.ContractId = ec.ContractId
		LEFT JOIN #SumOfVendorRentSharing sovrs ON sovrs.ContractId = ec.ContractId
		LEFT JOIN #SumOfInterimReceiptApplicationReceivableDetails soirard ON soirard.ContractId = ec.ContractId
		LEFT JOIN #SumOfPrepaidInterimReceivables sopir ON sopir.ContractId = ec.ContractId
		LEFT JOIN #InterimLeaseIncomeSchInfo ilis ON ilis.ContractId = ec.ContractId
		LEFT JOIN #InterimOtherBuckets iob ON iob.ContractId = ec.ContractId
		LEFT JOIN #FloatRateReceivableDetails frrd ON frrd.ContractId = ec.ContractId
		LEFT JOIN #FloatRateReceiptDetails frrpd ON frrpd.ContractId = ec.ContractId
		LEFT JOIN #FloatRateIncomeDetails frid ON frid.ContractId = ec.ContractId
		LEFT JOIN #FunderReceivableTaxDetails frt ON frt.ContractId = ec.ContractId
		LEFT JOIN #SalesTaxNonCashAppliedFO stn ON stn.ContractId = ec.ContractId
		LEFT JOIN #FunderReceivableDetailsAmount frd ON frd.ContractId = ec.ContractId
		LEFT JOIN #FunderReceiptApplicationDetails frard ON frard.ContractId = ec.ContractId
		LEFT JOIN #ContractsWithManualGLEntries cwmg ON cwmg.ContractId = ec.ContractId
		LEFT JOIN #GLJournalDetail gld ON gld.ContractId = ec.ContractId
		LEFT JOIN #RRGLDetails rrf ON rrf.ContractId = ec.ContractId
		LEFT JOIN ReceivableForTransfers rft ON rft.ContractId = ec.ContractId
				  AND rft.ApprovalStatus = 'Approved') AS t;

		CREATE NONCLUSTERED INDEX IX_Id ON #ResultList(ContractId);
		
		SELECT name AS Name, 0 AS Count, CAST (0 AS BIT) AS IsProcessed, CAST('' AS NVARCHAR(max)) AS Label, column_Id AS ColumnId
		INTO #CapitalLeaseSummary
		FROM tempdb.sys.columns
		WHERE object_id = OBJECT_ID('tempdb..#ResultList')
		AND (Name LIKE '%Difference' OR Name LIKE '%VS%')



		DECLARE @query NVARCHAR(MAX);
		DECLARE @TableName NVARCHAR(max);
		WHILE EXISTS (SELECT 1 FROM #CapitalLeaseSummary WHERE IsProcessed = 0)
		BEGIN
		SELECT TOP 1 @TableName = Name FROM #CapitalLeaseSummary WHERE IsProcessed = 0

		SET @query = 'UPDATE #CapitalLeaseSummary SET Count = (SELECT COUNT(*) FROM #ResultList WHERE ' + @TableName+ ' != 0.00), IsProcessed = 1
					  WHERE Name = '''+ @TableName+''' ;'
		EXEC (@query)
		END

		
UPDATE #CapitalLeaseSummary 
		SET
			Label = CASE
				WHEN Name = 'GLPostedReceivables_LeaseComponent_Difference'
				THEN '1_Lease Component Receivables - GL Posted_Difference'
				WHEN Name ='PaidReceivables_LeaseComponent_Difference'
				THEN '2_Lease Component Receivables - Total Paid_Difference'
				WHEN Name ='PaidReceivablesviaCash_LeaseComponent_Difference'
				THEN '3_Lease Component Receivables - Total Cash Paid_Difference'
				WHEN Name ='PaidReceivablesviaNonCash_LeaseComponent_Difference'
				THEN '4_Lease Component Receivables - Total Non Cash Paid_Difference'
				WHEN Name ='PrepaidReceivables_LeaseComponent_Difference'
				THEN '5_Lease Component Receivables - Prepaid_Difference'
				WHEN Name ='OutstandingReceivables_LeaseComponent_Difference'
				THEN '6_Lease Component Receivables - OSAR_Difference'
				WHEN Name ='LongTermReceivables_LeaseComponent_Difference'
				THEN '7_Lease Component Receivables - Long Term_Difference'
				WHEN Name ='UnguaranteedResidual_LeaseComponent_Difference'
				THEN '8_Lease Component - Unguaranteed Residual_Difference'
				WHEN Name ='GuaranteedResidual_LeaseComponent_Difference'
				THEN '9_Lease Component - Guaranteed Residual_Difference'
				WHEN Name ='SalesTypeLeaseGrossProfit_Difference'
				THEN '10_Sales Type Lease Gross Profit_Difference'
				WHEN Name ='TotalIncome_Accounting_Schedule_Difference'
				THEN '11_Lease Component - Total Income_Accounting_Schedule_Difference'
				WHEN Name ='TotalSellingProfitIncome_Accounting_Schedule_Difference'
				THEN '12_Total Selling Profit Income_Accounting_Schedule_Difference'
				WHEN Name ='LeaseEarnedIncome_Difference'
				THEN '13_Lease Component - Earned Income_Difference'
				WHEN Name ='LeaseEarnedResidualIncome_Difference'
				THEN '14_Lease Component - Earned Residual Income_Difference'
				WHEN Name ='EarnedSellingProfitIncome_Difference'
				THEN '15_Earned Selling Profit Income_Difference'
				WHEN Name ='LeaseUnearnedIncome_Difference'
				THEN '16_Lease Component - Unearned Income_Difference'
				WHEN Name ='LeaseUnearnedResidualIncome_Difference'
				THEN '17_Lease Component - Unearned Residual Income_Difference'
				WHEN Name ='UnearnedSellingProfitIncome_Difference'
				THEN '18_Unearned Selling Profit Income_Difference'
				WHEN Name ='LeaseRecognizedSuspendedIncome_Difference'
				THEN '19_Lease Component - Recognized Suspended Income_Difference'
				WHEN Name ='LeaseRecognizedSuspendedResidualIncome_Difference'
				THEN '20_Lease Component - Recognized Suspended Residual Income_Difference'
				WHEN Name ='RecognizedSuspendedSellingProfitIncome_Difference'
				THEN '21_Lease Component - Suspended Selling Profit_Difference'
				WHEN Name ='GLPostedReceivables_FinanceComponent_Difference'
				THEN '22_Finance Component Receivables - GL Posted_Difference'
				WHEN Name ='PaidReceivables_FinanceComponent_Difference'
				THEN '23_Finance Component Receivables - Total Paid_Difference'
				WHEN Name ='PaidReceivablesviaCash_FinanceComponent_Difference'
				THEN '24_Finance Component Receivables - Total Cash Paid_Difference'
				WHEN Name ='PaidReceivablesviaNonCash_FinanceComponent_Difference'
				THEN '25_Finance Component Receivables - Total Non Cash Paid_Difference'
				WHEN Name ='PrepaidReceivables_FinanceComponent_Difference'
				THEN '26_Finance Component Receivables - Prepaid_Difference'
				WHEN Name ='OutstandingReceivables_FinanceComponent_Difference'
				THEN '27_Finance Component Receivables - OSAR_Difference'
				WHEN Name ='LongTermReceivables_FinanceComponent_Difference'
				THEN '28_Finance Component Receivables - Long Term_Difference'
				WHEN Name ='UnguaranteedResidual_FinanceComponent_Difference'
				THEN '29_Finance Component - Unguaranteed Residual_Difference'
				WHEN Name ='GuaranteedResidual_FinanceComponent_Difference'
				THEN '30_Finance Component - Guaranteed Residual_Difference'
				WHEN Name ='Finance_TotalIncome_Accounting_Schedule_Difference'
				THEN '31_Finance Component - Total Income_Accounting_Schedule_Difference'
				WHEN Name ='FinanceEarnedIncome_Difference'
				THEN '32_Finance Component - Earned Income_Difference'
				WHEN Name ='FinanceEarnedResidualIncome_Difference'
				THEN '33_Finance Component - Earned Residual Income_Difference'
				WHEN Name ='FinanceUnearnedIncome_Difference'
				THEN '34_Finance Component - Unearned Income_Difference'
				WHEN Name ='FinanceUnearnedResidualIncome_Difference'
				THEN '35_Finance Component - Unearned Residual Income_Difference'
				WHEN Name ='FinanceRecognizedSuspendedIncome_Difference'
				THEN '36_Finance Component - Total Recognized Suspended Income_Difference'
				WHEN Name ='FinanceRecognizedSuspendedResidualIncome_Difference'
				THEN '37_Finance Component - Total Recognized Suspended Residual Income_Difference'
				WHEN Name ='TotalCapitalizedSalesTax_Difference'
				THEN '38_Capitalized SalesTax_Difference'
				WHEN Name ='TotalCapitalizedInterimInterest_Difference'
				THEN '39_Capitalized Interim Interest_Difference'
				WHEN Name ='TotalCapitalizedInterimRent_Difference'
				THEN '40_Capitalized Interim Rent_Difference'
				WHEN Name ='TotalCapitalizedAdditionalCharge_Difference'
				THEN '41_Capitalized Additional Charge_Difference'
				WHEN NAME = 'TotalGLPostedFloatRateReceivables_Difference'
				THEN '42_Float Rate Receivables - Total GLPosted_Difference'
				WHEN NAME = 'TotalPaidFloatRateReceivables_Difference'
				THEN '43_Float Rate Receivables - Total Paid_Difference'
				WHEN NAME = 'TotalCashPaidFloatRateReceivables_Difference'
				THEN '44_Float Rate Receivables - Total Cash Paid_Difference'
				WHEN NAME = 'TotalNonCashPaidFloatRateReceivables_Difference'
				THEN '45_Float Rate Receivables - Total NonCashPaid_Difference'
				WHEN NAME = 'OutstandingFloatRateReceivables_Difference'
				THEN '47_Float Rate Receivables - Outstanding_Difference'
				WHEN NAME = 'PrepaidFloatRateReceivables_Difference'
				THEN '46_Float Rate Receivables - Prepaid_Difference'
				WHEN NAME = 'TotalFloatRateIncome_AccountingAndSchedule_Difference'
				THEN '48_Float Rate Income - Accounting And Schedule_Difference'
				WHEN NAME = 'TotalGLPostedFloatRateIncome_Difference'
				THEN '49_Float Rate Income - Total GLPosted_Difference'
				WHEN NAME = 'TotalSuspendedIncome_Difference'
				THEN '50_Float Rate Income - Total Suspended_Difference'
				WHEN NAME = 'TotalAccruedIncome_Difference'
				THEN '51_Float Rate Income - Total Accrued_Difference'
				WHEN Name ='TotalGLPosted_InterimRentReceivables_Difference'
				THEN '52_Interim Rent Receivables - Total GLPosted_Difference'
				WHEN Name ='TotalPaid_InterimRentReceivables_Difference'
				THEN '53_Interim Rent Receivables - Total Paid_Difference'
				WHEN Name ='TotalPaidviaCash_InterimRentReceivables_Difference'
				THEN '54_Interim Rent Receivables - Total PaidviaCash_Difference'
				WHEN Name ='TotalPaidviaNonCash_InterimRentReceivables_Difference'
				THEN '55_Interim Rent Receivables - Total PaidviaNonCash_Difference'
				WHEN Name ='TotalPrepaid_InterimRentReceivables_Difference'
				THEN '56_Interim Rent Receivables - Total Prepaid_Difference'
				WHEN Name ='TotalOutstanding_InterimRentReceivables_Difference'
				THEN '57_Interim Rent Receivables - Total Outstanding_Difference'
				WHEN Name ='GLPosted_InterimRentIncome_Difference'
				THEN '58_Interim Rent Income - GLPosted_Difference'
				WHEN Name ='TotalCapitalizedIncome_InterimRentIncome_Difference'
				THEN '59_Interim Rent Income - Total CapitalizedIncome_Difference'
				WHEN Name ='TotalInterimRent_IncomeandReceivable_Difference'
				THEN '60_Interim Rent Income - IncomeandReceivable_Difference'
				WHEN Name ='DeferInterimRentIncome_Difference'
				THEN '61_Interim Rent Income - DeferInterimRentIncome_Difference'
				WHEN Name ='TotalGLPosted_InterimInterestReceivables_Difference'
				THEN '62_Interim Interest Receivables - Total GLPosted_Difference'
				WHEN Name ='TotalPaid_InterimInterestReceivables_Difference'
				THEN '63_Interim Interest Receivables - Total Paid_Difference'
				WHEN Name ='TotalPaidviaCash_InterimInterestReceivables_Difference'
				THEN '64_Interim Interest Receivables - Total PaidviaCash_Difference'
				WHEN Name ='TotalPaidviaNonCash_InterimInterestReceivables_Difference'
				THEN '65_Interim Interest Receivables - Total PaidviaNonCash_Difference'
				WHEN Name ='TotalPrepaid_InterimInterestReceivables_Difference'
				THEN '66_Interim Interest Receivables - Total Prepaid_Difference'
				WHEN Name ='TotalOutstanding_InterimInterestReceivables_Difference'
				THEN '67_Interim Interest Receivables - Total Outstanding_Difference'
				WHEN Name ='GLPosted_InterimInterestIncome_Difference'
				THEN '68_Interim Interest Income - GLPosted_Difference'
				WHEN Name ='TotalCapitalizedIncome_InterimInterestIncome_Difference'
				THEN '69_Interim Interest Income - Total CapitalizedIncome_Difference'
				WHEN Name ='TotalInterimInterest_IncomeandReceivable_Difference'
				THEN '70_Interim Interest Income - ReceivableandIncome_Difference'
				WHEN Name ='AccruedInterimInterestIncome_Difference'
				THEN '71_Interim Interest Income - AccruedInterimInterestIncome_Difference'
				WHEN Name ='GrossWriteDown_Difference'
				THEN '72_Gross Writedown_Difference'
				WHEN Name ='WriteDownRecovered_Difference'
				THEN '73_Writedown Recovered_Difference'
				WHEN Name ='NetWriteDown_Difference'
				THEN '74_Net Writedown_Difference'
				WHEN Name ='ChargeOffExpense_LeaseComponent_Difference'
				THEN '75_Lease Component - Charge-off Expense_Difference'
				WHEN Name ='ChargeOffExpense_NonLeaseComponent_Difference'
				THEN '76_Finance Component - Charge-off Expense_Difference'
				WHEN Name = 'TotalChargeoffAmountVSLCAndNLC'
				THEN '77_Total Chargeoff Amount VS LC & NLC'
				WHEN Name ='ChargeOffRecovery_LeaseComponent_Difference'
				THEN '78_Lease Component - Charge-off Recovery_Difference'
				WHEN Name ='ChargeOffRecovery_NonLeaseComponent_Difference'
				THEN '79_Finance Component - Charge-off Recovery_Difference'
				WHEN Name ='ChargeOffGainOnRecovery_LeaseComponent_Difference'
				THEN '80_ Lease Component - Charge-off Gain On Recovery_Difference'
				WHEN Name ='ChargeOffGainOnRecovery_NonLeaseComponent_Difference'
				THEN '81_Finance Component - Charge-off Gain On Recovery_Difference'
				WHEN Name = 'TotalRecoveryAndGainVSRecoveryAndGainLCAndNLC'
				THEN '82_Total Recovery & Gain VS Recovery & Gain LC&NLC'
				WHEN Name ='UnAppliedCash_Difference'
				THEN '83_Unapplied Cash_Difference'
				WHEN Name ='TotalGLPosted_SalesTaxReceivable_Difference'
				THEN '84_Sales Tax Receivables - GL Posted_Difference'
				WHEN Name ='TotalPaid_SalesTaxReceivables_Difference'
				THEN '85_Sales Tax Receivables - Total Paid_Difference'
				WHEN Name ='TotalPrepaidPaid_SalesTaxReceivables_Difference'
				THEN '86_Sales Tax Receivables - Total PrepaidPaid_Difference'
				WHEN Name ='TotalOutstanding_SalesTaxReceivables_Difference'
				THEN '87_Sales Tax Receivables - Total OSAR_Difference'
				WHEN Name ='TotalPaidviacash_SalesTaxReceivables_Difference'
				THEN '88_Sales Tax Receivables - Total Cash Paid_Difference'
				WHEN Name ='TotalPaidvianoncash_SalesTaxReceivables_Difference'
				THEN '89_Sales Tax Receivables - Total Non Cash Paid_Difference'
				WHEN NAME = 'TotalGLPosted_FunderOwned_Difference'
				THEN '90_Funder Owned Receivables - Total GL Posted_Difference'
				WHEN NAME = 'TotalPaidCash_FunderOwned_Difference'
				THEN '91_Funder Owned Receivables - Total Cash Paid_Difference'
				WHEN NAME = 'TotalPaidNonCash_FunderOwned_Difference'
				THEN '92_Funder Owned Receivables - Total Non Cash Paid_Difference'
				WHEN NAME = 'TotalOSAR_FunderOwned_Difference'
				THEN '93_Funder Owned Receivables - Total OSAR_Difference'
				WHEN NAME = 'TotalPrepaid_FunderOwned_Difference'
				THEN '94_Funder Owned Receivables - Total Prepaid_Difference'
				WHEN NAME = 'TotalGLPosted_FunderOwned_LessorRemit_SalesTax_Difference'
				THEN '95_Funder Owned Receivables - Total GL Posted Lessor Remit Sales Tax_Difference'
				WHEN NAME = 'TotalPaidCash_FunderOwned_LessorRemit_SalesTax_Difference'
				THEN '96_Funder Owned Receivables - Total Cash Paid Lessor Remit Sales Tax_Difference'
				WHEN NAME = 'TotalPaidNonCash_FunderOwned_LessorRemit_SalesTax_Difference'
				THEN '97_Funder Owned Receivables - Total Non Cash Paid Lessor Remit Sales Tax_Difference'
				WHEN NAME = 'TotalOSAR_FunderOwned_LessorRemit_SalesTax_Difference'
				THEN '98_Funder Owned Receivables - Total OSAR Lessor Remit Sales Tax_Difference'
				WHEN NAME = 'TotalPrepaid_FunderOwned_LessorRemit_SalesTax_Difference'
				THEN '99_Funder Owned Receivables - Total Prepaid Lessor Remit Sales Tax_Difference'
        END;

		SELECT Label AS Name, Count
		FROM #CapitalLeaseSummary
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
		
		 INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('TotalLeases', (SELECT 'Leases=' + CONVERT(nvarchar(40), @TotalCount)))
		 INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('LeaseSuccessful', (SELECT 'LeaseSuccessful=' + CONVERT(nvarchar(40), (@TotalCount - @InCorrectCount))))
		 INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('LeaseIncorrect', (SELECT 'LeaseIncorrect=' + CONVERT(nvarchar(40), @InCorrectCount)))

		 INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('LeaseResultOption', (SELECT 'ResultOption=' + CONVERT(nvarchar(40), @ResultOption)))

		SELECT * FROM @Messages

	SET NOCOUNT OFF
	SET ANSI_WARNINGS ON 
	
	DROP TABLE #EligibleContracts
	DROP TABLE #OverTerm
	DROP TABLE #PaymentAmount
	DROP TABLE #FullPaidOffContracts
	DROP TABLE #LeaseAmendment
	DROP TABLE #HasFinanceAsset
	DROP TABLE #ChargeOff
	DROP TABLE #Resultlist
	DROP TABLE #AccrualDetails
	DROP TABLE #SumOfReceivables
	DROP TABLE #SumOfReceivableDetails
	DROP TABLE #PaidReceivables
	DROP TABLE #AssetResiduals
	IF OBJECT_ID('tempdb..#SKUResiduals') IS NOT NULL
	BEGIN
		DROP TABLE #SKUResiduals;
	END
	DROP TABLE #OTPPaidResiduals
	IF OBJECT_ID('tempdb..#OTPPaidResiduals_SKU') IS NOT NULL
	BEGIN
		DROP TABLE #SKUResiduals;
	END
	DROP TABLE #PrePaid
	DROP TABLE #Receivable
	DROP TABLE #GLJournalDetail
	DROP TABLE #ContractsWithManualGLEntries
	DROP TABLE #GLTrialBalance
	DROP TABLE #LeaseIncomeScheduleDetails
	DROP TABLE #BlendedIncomeSchInfo
	DROP TABLE #BlendedItemInfo
	DROP TABLE #WriteDownInfo
	DROP TABLE #ChargeOffInfo
	DROP TABLE #SumOfPayables
	DROP TABLE #SumOfReceipts
	DROP TABLE #OTPReclass
	DROP TABLE #ReceivableForTaxes
	DROP TABLE #SalesTaxDetails
	DROP TABLE #ReceivableTaxDetails
	DROP TABLE #CapitalizedDetails
	DROP TABLE #RRGLDetails
	DROP TABLE #SaleOfPaymentsUnguaranteedInfo
	DROP TABLE #RefundGLJournalIds
	DROP TABLE #RefundTableValue
	DROP TABLE #GLDetails
	DROP TABLE #RenewalDetails
	DROP TABLE #CapitalLeaseSummary
	DROP TABLE #InterimReceivableInfo;
	DROP TABLE #CapitalizeInterimAmount;
	DROP TABLE #SumOfInterimReceivables;
	DROP TABLE #SumOfVendorRentSharing;
	DROP TABLE #SumOfInterimReceiptApplicationReceivableDetails;
	DROP TABLE #SumOfPrepaidInterimReceivables;
	DROP TABLE #InterimLeaseIncomeSchInfo;
	DROP TABLE #InterimOtherBuckets;
	DROP TABLE #FloatRateReceivableDetails;
	DROP TABLE #FloatRateReceiptDetails;
	DROP TABLE #FloatRateIncomeDetails;
	DROP TABLE #FunderReceivableInfo;
	DROP TABLE #RemitOnlyContracts;
	DROP TABLE #FunderReceivableTaxDetails;
	DROP TABLE #SalesTaxNonCashAppliedFO;
	DROP TABLE #FunderReceivableDetailsAmount;
	DROP TABLE #FunderReceiptApplicationDetails;
	IF OBJECT_ID('tempdb..#ReceiptApplicationReceivableDetails') IS NOT NULL
	BEGIN
		DROP TABLE #ReceiptApplicationReceivableDetails;
	END
	IF OBJECT_ID('tempdb..#ChargeoffRecoveryReceiptIds') IS NOT NULL
	BEGIN
		DROP TABLE #ChargeoffRecoveryReceiptIds;
	END
	IF OBJECT_ID('tempdb..#ChargeoffRecoveryRecords') IS NOT NULL
	BEGIN
		DROP TABLE #ChargeoffRecoveryRecords;
	END
	IF OBJECT_ID('tempdb..#ChargeoffExpenseReceiptIds') IS NOT NULL
	BEGIN
		DROP TABLE #ChargeoffExpenseReceiptIds;
	END
	IF OBJECT_ID('tempdb..#ChargeoffExpenseRecords') IS NOT NULL
	BEGIN
		DROP TABLE #ChargeoffExpenseRecords;
	END
	IF OBJECT_ID('tempdb..#SumOfVendorRentSharing') IS NOT NULL
	BEGIN
		DROP TABLE #SumOfVendorRentSharing;
	END
	IF OBJECT_ID('tempdb..#FloatRateReceivableDetails') IS NOT NULL
	BEGIN
		DROP TABLE #FloatRateReceivableDetails;
	END
	IF OBJECT_ID('tempdb..#NonSKUChargeoffRecoveryRecords') IS NOT NULL
	BEGIN
		DROP TABLE #NonSKUChargeoffRecoveryRecords;
	END
	IF OBJECT_ID('tempdb..#NonSKUChargeoffExpenseRecords') IS NOT NULL
	BEGIN
		DROP TABLE #NonSKUChargeoffExpenseRecords;
	END
END

GO

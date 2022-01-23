SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[SPHC_OperatingLeaseGLPosting_Reconciliation]
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
	DROP TABLE #EligibleContracts;

	IF OBJECT_ID('tempdb..#PaymentAmount') IS NOT NULL
	DROP TABLE #PaymentAmount;

	IF OBJECT_ID('tempdb..#OverTerm') IS NOT NULL
	DROP TABLE #OverTerm;

	IF OBJECT_ID('tempdb..#FullPaidOffContracts') IS NOT NULL
	DROP TABLE #FullPaidOffContracts;

	IF OBJECT_ID('tempdb..#AccrualDetails') IS NOT NULL
	DROP TABLE #AccrualDetails;

	IF OBJECT_ID('tempdb..#HasFinanceAsset') IS NOT NULL
	DROP TABLE #HasFinanceAsset;

	IF OBJECT_ID('tempdb..#ChargeOffDetails') IS NOT NULL
	DROP TABLE #ChargeOffDetails;

	IF OBJECT_ID('tempdb..#AmendmentInfo') IS NOT NULL
	DROP TABLE #AmendmentInfo;
	
	IF OBJECT_ID('tempdb..#ReceivableInfo') IS NOT NULL
	DROP TABLE #ReceivableInfo;
	
	IF OBJECT_ID('tempdb..#RenewalDetails') IS NOT NULL
	DROP TABLE #RenewalDetails;

	IF OBJECT_ID('tempdb..#SumOfReceivables') IS NOT NULL
	DROP TABLE #SumOfReceivables;

	IF OBJECT_ID('tempdb..#SumOfReceivableDetails') IS NOT NULL
	DROP TABLE #SumOfReceivableDetails;

	IF OBJECT_ID('tempdb..#SumOfReceiptApplicationReceivableDetails') IS NOT NULL
	DROP TABLE #SumOfReceiptApplicationReceivableDetails;

	IF OBJECT_ID('tempdb..#SumOfPrepaidReceivables') IS NOT NULL
	DROP TABLE #SumOfPrepaidReceivables;
	
	IF OBJECT_ID('tempdb..#OTPReclass') IS NOT NULL
	DROP TABLE #OTPReclass;
	
	IF OBJECT_ID('tempdb..#AssetResiduals') IS NOT NULL
	DROP TABLE #AssetResiduals;

	IF OBJECT_ID('tempdb..#BlendedItemAssetsInfo') IS NOT NULL
	DROP TABLE #BlendedItemAssetsInfo;

	IF OBJECT_ID('tempdb..#SKUResiduals') IS NOT NULL
	DROP TABLE #SKUResiduals;

	IF OBJECT_ID('tempdb..#SumOfLeaseAssets') IS NOT NULL
	DROP TABLE #SumOfLeaseAssets;

	IF OBJECT_ID('tempdb..#SaleOfPaymentsUnguaranteedInfo') IS NOT NULL
	DROP TABLE #SaleOfPaymentsUnguaranteedInfo;

	IF OBJECT_ID('tempdb..#BlendedItemInfo') IS NOT NULL
	DROP TABLE #BlendedItemInfo;

	IF OBJECT_ID('tempdb..#BlendedIncomeSchInfo') IS NOT NULL
	DROP TABLE #BlendedIncomeSchInfo;

	IF OBJECT_ID('tempdb..#LeaseIncomeSchInfo') IS NOT NULL
	DROP TABLE #LeaseIncomeSchInfo;

	IF OBJECT_ID('tempdb..#PayOffDetails') IS NOT NULL
	DROP TABLE #PayOffDetails;

	IF OBJECT_ID('tempdb..#ClearedFixedTermAVHIncomeDate') IS NOT NULL
	DROP TABLE #ClearedFixedTermAVHIncomeDate;

	IF OBJECT_ID('tempdb..#ClearedFixedTermAVHIncomeDateCO') IS NOT NULL
	DROP TABLE #ClearedFixedTermAVHIncomeDateCO;

	IF OBJECT_ID('tempdb..#SyndicationAVHInfo') IS NOT NULL
	DROP TABLE #SyndicationAVHInfo;

	IF OBJECT_ID('tempdb..#FixedTermAssetValueHistoriesInfo') IS NOT NULL
	DROP TABLE #FixedTermAssetValueHistoriesInfo;

	IF OBJECT_ID('tempdb..#NBVAssetValueHistoriesInfo') IS NOT NULL
	DROP TABLE #NBVAssetValueHistoriesInfo;

	IF OBJECT_ID('tempdb..#WriteDownInfo') IS NOT NULL
	DROP TABLE #WriteDownInfo;

	IF OBJECT_ID('tempdb..#ChargeOffInfo') IS NOT NULL
	DROP TABLE #ChargeOffInfo;

	IF OBJECT_ID('tempdb..#SumOfReceipts') IS NOT NULL
	DROP TABLE #SumOfReceipts;

	IF OBJECT_ID('tempdb..#SumOfPayables') IS NOT NULL
	DROP TABLE #SumOfPayables;
	
	IF OBJECT_ID('tempdb..#ReceivableForTaxes') IS NOT NULL
	DROP TABLE #ReceivableForTaxes;

	IF OBJECT_ID('tempdb..#ReceivableTaxDetails') IS NOT NULL
	DROP TABLE #ReceivableTaxDetails;

	IF OBJECT_ID('tempdb..#SalesTaxDetails') IS NOT NULL
	DROP TABLE #SalesTaxDetails;

	IF OBJECT_ID('tempdb..#CapitalizedDetails') IS NOT NULL
	DROP TABLE #CapitalizedDetails;

	IF OBJECT_ID('tempdb..#InterimReceivableInfo') IS NOT NULL
	DROP TABLE #InterimReceivableInfo;

	IF OBJECT_ID('tempdb..#CapitalizeInterimAmount') IS NOT NULL
	DROP TABLE #CapitalizeInterimAmount;

	IF OBJECT_ID('tempdb..#SumOfInterimReceivables') IS NOT NULL
	DROP TABLE #SumOfInterimReceivables;
	
	IF OBJECT_ID('tempdb..#SumOfVendorRentSharing') IS NOT NULL
	DROP TABLE #SumOfVendorRentSharing;

	IF OBJECT_ID('tempdb..#SumOfInterimReceiptApplicationReceivableDetails') IS NOT NULL
	DROP TABLE #SumOfInterimReceiptApplicationReceivableDetails;

	IF OBJECT_ID('tempdb..#SumOfPrepaidInterimReceivables') IS NOT NULL
	DROP TABLE #SumOfPrepaidInterimReceivables;

	IF OBJECT_ID('tempdb..#InterimLeaseIncomeSchInfo') IS NOT NULL
	DROP TABLE #InterimLeaseIncomeSchInfo;

	IF OBJECT_ID('tempdb..#InterimOtherBuckets') IS NOT NULL
	DROP TABLE #InterimOtherBuckets;

	IF OBJECT_ID('tempdb..#FloatRateReceivableDetails') IS NOT NULL
	DROP TABLE #FloatRateReceivableDetails;

	IF OBJECT_ID('tempdb..#FloatRateReceiptDetails') IS NOT NULL
	DROP TABLE #FloatRateReceiptDetails;

	IF OBJECT_ID('tempdb..#FloatRateIncomeDetails') IS NOT NULL
	DROP TABLE #FloatRateIncomeDetails;
	
	IF OBJECT_ID('tempdb..#FunderReceivableInfo') IS NOT NULL
	DROP TABLE #FunderReceivableInfo;
	
	IF OBJECT_ID('tempdb..#RemitOnlyContracts') IS NOT NULL
	DROP TABLE #RemitOnlyContracts;

	IF OBJECT_ID('tempdb..#FunderReceivableTaxDetails') IS NOT NULL
	DROP TABLE #FunderReceivableTaxDetails;

	IF OBJECT_ID('tempdb..#SalesTaxNonCashAppliedFO') IS NOT NULL
	DROP TABLE #SalesTaxNonCashAppliedFO;

	IF OBJECT_ID('tempdb..#FunderReceivableDetailsAmount') IS NOT NULL
	DROP TABLE #FunderReceivableDetailsAmount;
	
	IF OBJECT_ID('tempdb..#FunderReceiptApplicationDetails') IS NOT NULL
	DROP TABLE #FunderReceiptApplicationDetails;

	IF OBJECT_ID('tempdb..#RenewalGLJournals') IS NOT NULL
	DROP TABLE #RenewalGLJournals;

	IF OBJECT_ID('tempdb..#GLDetails') IS NOT NULL
	DROP TABLE #GLDetails;

	IF OBJECT_ID('tempdb..#RefundGLJournalIds') IS NOT NULL
	DROP TABLE #RefundGLJournalIds;

	IF OBJECT_ID('tempdb..#RefundTableValue') IS NOT NULL
	DROP TABLE #RefundTableValue;
	
	IF OBJECT_ID('tempdb..#GLDetail') IS NOT NULL
	DROP TABLE #GLDetail;
	
	IF OBJECT_ID('tempdb..#RRGLDetails') IS NOT NULL
	DROP TABLE #RRGLDetails;
	
	IF OBJECT_ID('tempdb..#ContractsWithManualGLEntries') IS NOT NULL
	DROP TABLE #ContractsWithManualGLEntries;

	IF OBJECT_ID('tempdb..#ResultList') IS NOT NULL
	DROP TABLE #ResultList;
	
	IF OBJECT_ID('tempdb..#OperatingLeaseSummary') IS NOT NULL
	DROP TABLE #OperatingLeaseSummary;

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
	IF OBJECT_ID('tempdb..#NonAccrualDetails') IS NOT NULL
	BEGIN
		DROP TABLE #NonAccrualDetails;
	END


	DECLARE @u_ConversionSource nvarchar(50); 
	DECLARE @True BIT= 1;
	DECLARE @False BIT= 0;
	DECLARE @IsGainPresent BIT = 0
	DECLARE @LegalEntitiesCount BIGINT = ISNULL((SELECT COUNT(*) FROM @LegalEntityIds), 0)
	DECLARE @ContractsCount BIGINT = ISNULL((SELECT COUNT(*) FROM @ContractIds), 0)
	DECLARE @CustomersCount BIGINT = ISNULL((SELECT COUNT(*) FROM @CustomerIds), 0)
	DECLARE @IncludeGuaranteedResidualinLongTermReceivables nvarchar(50);
	DECLARE @DeferInterimRentIncomeRecognition nvarchar(50);
	DECLARE @DeferInterimRentIncomeRecognitionForSingleInstallment nvarchar(50);
	DECLARE @DeferInterimInterestIncomeRecognition nvarchar(50);
	DECLARE @DeferInterimInterestIncomeRecognitionForSingleInstallment nvarchar(50);

	SELECT @u_ConversionSource = Value FROM GlobalParameters WHERE Category ='Migration' AND Name = 'ConversionSource';
	SELECT @IncludeGuaranteedResidualinLongTermReceivables = Value FROM GlobalParameters WHERE Category = 'Lease' AND Name = 'IncludeGuaranteedResidualinLongTermReceivables';
	SELECT @DeferInterimRentIncomeRecognition = Value FROM GlobalParameters WHERE Category = 'LeaseFinance' AND Name = 'DeferInterimRentIncomeRecognition';
	SELECT @DeferInterimRentIncomeRecognitionForSingleInstallment = Value FROM GlobalParameters WHERE Category = 'LeaseFinance' AND Name = 'DeferInterimRentIncomeRecognitionForSingleInstallment';
	SELECT @DeferInterimInterestIncomeRecognition = Value FROM GlobalParameters WHERE Category = 'LeaseFinance' AND Name = 'DeferInterimInterestIncomeRecognition';
	SELECT @DeferInterimInterestIncomeRecognitionForSingleInstallment = Value FROM GlobalParameters WHERE Category = 'LeaseFinance' AND Name = 'DeferInterimInterestIncomeRecognitionForSingleInstallment';

	CREATE TABLE #HasFinanceAsset
	(ContractId BIGINT NOT NULL
	);

	CREATE TABLE #SumOfReceivableDetails
	(ContractId                                    BIGINT NOT NULL, 
	 TotalGLPostedReceivables_LeaseComponent_Table DECIMAL(16, 2) NOT NULL, 
	 GLPostedReceivables_LeaseComponent_Table      DECIMAL(16, 2) NOT NULL, 
	 GLPostedReceivables_FinanceComponent_Table    DECIMAL(16, 2) NOT NULL, 
	 OutstandingReceivables_LeaseComponent_Table   DECIMAL(16, 2) NOT NULL, 
	 OutstandingReceivables_FinanceComponent_Table DECIMAL(16, 2) NOT NULL, 
	 LongTermReceivables_FinanceComponent_Table    DECIMAL(16, 2) NOT NULL,
	);

	CREATE TABLE #SumOfReceiptApplicationReceivableDetails
	(ContractId                                             BIGINT NOT NULL, 
	 TotalPaidReceivables_LeaseComponent_Table              DECIMAL(16, 2) NOT NULL, 
	 TotalPaidReceivablesviaCash_LeaseComponent_Table       DECIMAL(16, 2) NOT NULL, 
	 TotalPaidReceivablesviaNonCash_LeaseComponent_Table    DECIMAL(16, 2) NOT NULL, 
	 TotalPaidReceivables_FinanceComponent_Table            DECIMAL(16, 2) NOT NULL, 
	 TotalPaidReceivablesviaCash_FinanceComponent_Table     DECIMAL(16, 2) NOT NULL, 
	 TotalPaidReceivablesviaNonCash_FinanceComponent_Table  DECIMAL(16, 2) NOT NULL, 
	 Recovery_LeaseComponent_Table                          DECIMAL(16, 2) NOT NULL, 
	 Recovery_FinanceComponent_Table                        DECIMAL(16, 2) NOT NULL, 
	 GLPostedPreChargeOff_LeaseComponent_Table              DECIMAL(16, 2) NOT NULL, 
	 GLPostedPreChargeOff_FinanceComponent_Table            DECIMAL(16, 2) NOT NULL, 
	 ChargeOffGainOnRecovery_LeaseComponent_Table			DECIMAL(16, 2) NOT NULL,
	 ChargeOffGainOnRecovery_NonLeaseComponent_Table        DECIMAL(16, 2) NOT NULL
	);

	CREATE TABLE #AssetResiduals
	(ContractId                                BIGINT NOT NULL, 
	 LeaseBookedResidualAmount                 DECIMAL(16, 2) NOT NULL, 
	 LeaseThirdPartyGuaranteedResidualAmount   DECIMAL(16, 2) NOT NULL, 
	 LeaseCustomerGuaranteedResidualAmount     DECIMAL(16, 2) NOT NULL, 
	 FinanceBookedResidualAmount               DECIMAL(16, 2) NOT NULL, 
	 FinanceThirdPartyGuaranteedResidualAmount DECIMAL(16, 2) NOT NULL, 
	 FinanceCustomerGuaranteedResidualAmount   DECIMAL(16, 2) NOT NULL, 
	 LeaseAssetCost                            DECIMAL(16, 2) NOT NULL
	);

	CREATE TABLE #BlendedItemAssetsInfo
	(ContractId          BIGINT NOT NULL, 
	 LeaseAssetETCAmount DECIMAL(16, 2) NOT NULL
	);

	CREATE TABLE #SKUResiduals
	(ContractId                                   BIGINT NOT NULL, 
	 SKULeaseBookedResidualAmount                 DECIMAL(16, 2) NOT NULL, 
	 SKULeaseThirdPartyGuaranteedResidualAmount   DECIMAL(16, 2) NOT NULL, 
	 SKULeaseCustomerGuaranteedResidualAmount     DECIMAL(16, 2) NOT NULL, 
	 SKUFinanceBookedResidualAmount               DECIMAL(16, 2) NOT NULL, 
	 SKUFinanceThirdPartyGuaranteedResidualAmount DECIMAL(16, 2) NOT NULL, 
	 SKUFinanceCustomerGuaranteedResidualAmount   DECIMAL(16, 2) NOT NULL, 
	 SKULeaseAssetCost                            DECIMAL(16, 2) NOT NULL
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
	(ContractId                             BIGINT NOT NULL,
	 VendorInterimRentSharingAmount         DECIMAL (16, 2) NOT NULL,
	 GLPostedVendorInterimRentSharingAmount DECIMAL (16, 2) NOT NULL
	);

	CREATE TABLE #FloatRateReceivableDetails
	(ContractId                     BIGINT NOT NULL, 
	 TotalAmount                    DECIMAL(16, 2) NOT NULL, 
	 LeaseComponentAmount           DECIMAL(16, 2) NOT NULL, 
	 NonLeaseComponentAmount        DECIMAL(16, 2) NOT NULL, 
	 TotalPrepaidAmount             DECIMAL(16, 2) NOT NULL, 
	 LeaseComponentPrepaidAmount    DECIMAL(16, 2) NOT NULL, 
	 NonLeaseComponentPrepaidAmount DECIMAL(16, 2) NOT NULL, 
	 TotalOSARAmount                DECIMAL(16, 2) NOT NULL, 
	 LeaseComponentOSARAmount       DECIMAL(16, 2) NOT NULL, 
	 NonLeaseComponentOSARAmount    DECIMAL(16, 2) NOT NULL,
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
	 GainOnRecovery_NLC_Table	 DECIMAL(16, 2),
	 ChargeOffRecovered			 DECIMAL(16, 2)
	);

	CREATE TABLE #NonAccrualDetails
	(ContractId                  BIGINT,
	 DoubtfulCollectability		 BIT
	);

	SELECT 
		c.Id AS ContractId
		,c.SequenceNumber
		,c.Alias
		,lf.Id AS LeaseFinanceId
		,lf.CustomerId AS CustomerId
		,lf.LegalEntityId AS LegalEntityId
		,c.u_ConversionSource AS ConversionSource
		,c.Status AS ContractStatus
		,c.AccountingStandard
		,lfd.IsAdvance
		,lfd.TermInMonths
		,lfd.NumberOfPayments
		,lfd.PaymentFrequency
		,lfd.IsRegularPaymentStream
		,lfd.CommencementDate
		,lfd.MaturityDate
		,lfd.InterimAssessmentMethod
		,lfd.InterimInterestBillingType
		,lfd.InterimRentBillingType
		,lf.BookingStatus
		,rft.Id AS ReceivableForTransfersId
		,rft.RetainedPercentage
		,rft.LeaseFinanceId AS SyndicationLeaseFinanceId
		,rft.EffectiveDate AS SyndicationEffectiveDate
		,CASE
			WHEN rft.Id IS NOT NULL
			THEN rft.ReceivableForTransferType
			ELSE 'None'
		END AS SyndicationType
		,rft.EffectiveDate AS SyndicationDate
		,lfd.IsFloatRateLease
	INTO #EligibleContracts
	FROM Contracts c
		INNER JOIN LeaseFinances lf ON lf.ContractId = c.Id
		INNER JOIN LeaseFinanceDetails lfd ON lfd.Id = lf.Id
		LEFT JOIN ReceivableForTransfers rft ON rft.ContractId = c.Id
			AND rft.ApprovalStatus = 'Approved'
	WHERE lf.IsCurrent = 1
		AND lfd.LeaseContractType = 'Operating'
		AND c.Status IN ('Commenced','FullyPaidOff','FullyPaid')
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
		ec.ContractId AS ContractId
		,ISNULL(lps.Amount_Amount,0.00) AS PaymentAmount
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
		DISTINCT ec.ContractId
	INTO #OverTerm
	FROM #EligibleContracts ec
		INNER JOIN LeaseIncomeSchedules lis ON lis.LeaseFinanceId = ec.LeaseFinanceId
	WHERE lis.IncomeType = 'OverTerm'
		AND lis.IsSchedule = 1
	GROUP BY ec.ContractId;

	CREATE NONCLUSTERED INDEX IX_Id ON #OverTerm(ContractId);

	SELECT 
		ec.ContractId
		,p.PayoffEffectiveDate
	INTO #FullPaidOffContracts
	FROM #EligibleContracts ec
		INNER JOIN LeaseFinances lf ON ec.ContractId = lf.ContractId
		INNER JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
		INNER JOIN Payoffs p ON lf.Id = p.LeaseFinanceId
			AND p.Status = 'Activated'
			AND p.FullPayoff = 1;

	CREATE NONCLUSTERED INDEX IX_Id ON #FullPaidOffContracts(ContractId);

	DECLARE @Sql nvarchar(max) ='';
	
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

	IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'NonAccrualContracts' AND COLUMN_NAME = 'DoubtfulCollectability')
	BEGIN
	SET @SQL = 'SELECT DISTINCT 
		   t.ContractId
	     , nc.DoubtfulCollectability
	FROM
	(
		SELECT ec.ContractId
				, MAX(nc.Id) AS NonAccrualId
		FROM #EligibleContracts ec
				LEFT JOIN NonAccrualContracts nc ON nc.ContractId = ec.ContractId
				LEFT JOIN NonAccruals na ON nc.NonAccrualId = na.Id
											AND nc.IsActive = 1
											AND na.Status = ''Approved''
		GROUP BY ec.ContractId
	) AS t
	INNER JOIN NonAccrualContracts nc ON nc.Id = t.NonAccrualId
										 AND t.ContractId = nc.ContractId';	
	
	INSERT INTO #NonAccrualDetails(ContractId, DoubtfulCollectability)
	EXEC (@Sql) 
	END
	
	IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'NonAccrualContracts' AND COLUMN_NAME = 'DoubtfulCollectability')
	BEGIN
	INSERT INTO #NonAccrualDetails
	SELECT DISTINCT 
		   t.ContractId
	     , CAST (0 AS BIT)
	FROM
	(
		SELECT ec.ContractId
				, MAX(nc.Id) AS NonAccrualId
		FROM #EligibleContracts ec
				LEFT JOIN NonAccrualContracts nc ON nc.ContractId = ec.ContractId
				LEFT JOIN NonAccruals na ON nc.NonAccrualId = na.Id
											AND nc.IsActive = 1
											AND na.Status = 'Approved'
		GROUP BY ec.ContractId
	) AS t
	INNER JOIN NonAccrualContracts nc ON nc.Id = t.NonAccrualId
										 AND t.ContractId = nc.ContractId
	
	END

	CREATE NONCLUSTERED INDEX IX_Id ON #NonAccrualDetails(ContractId)

	DECLARE @IsSku BIT = 0
	DECLARE @FilterCondition nvarchar(max) = ''

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
			SET @sql = REPLACE(@sql, 'FilterCondition', @FilterCondition);
		END;
	ELSE
		BEGIN
			SET @sql = REPLACE(@sql, 'FilterCondition', '');
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

	SELECT
		ec.ContractId
		,co.ChargeOffDate
		,co.Id AS ChargeOffId
	INTO #ChargeOffDetails
	FROM #EligibleContracts ec
		INNER JOIN ChargeOffs co ON co.ContractId = ec.ContractId
	WHERE co.IsActive = 1
		AND co.Status = 'Approved'
		AND co.IsRecovery = 0
		AND co.ReceiptId IS NULL;

	CREATE NONCLUSTERED INDEX IX_Id ON #ChargeOffDetails(ContractId);

	SELECT DISTINCT
		ec.ContractId
		,SUM(
			CASE
				WHEN la.AmendmentType = 'Renewal'
				THEN 1
				ELSE 0
			END) AS Renewal
		,SUM(
			CASE
				WHEN la.AmendmentType = 'Assumption'
				THEN 1
				ELSE 0
			END) AS Assumption
	INTO #AmendmentInfo
	FROM #EligibleContracts ec
		INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
		INNER JOIN LeaseAmendments la ON la.CurrentLeaseFinanceId = lf.Id
	WHERE la.LeaseAmendmentStatus = 'Approved'
	GROUP BY ec.ContractId;

	CREATE NONCLUSTERED INDEX IX_Id ON #AmendmentInfo(ContractId);

	SELECT
		ec.ContractId
		,r.Id
		,r.DueDate
		,r.IsGLPosted
		,r.TotalAmount_Amount
		,r.TotalBalance_Amount
		,lps.StartDate
		, rt.Name AS ReceivableTypeName
	INTO #ReceivableInfo
	FROM #EligibleContracts ec
		INNER JOIN Receivables r ON r.EntityId = ec.ContractId
		INNER JOIN ReceivableCodes rc ON r.ReceivableCodeId = rc.Id
		INNER JOIN ReceivableTypes rt ON rc.ReceivableTypeId = rt.Id
		INNER JOIN LeasePaymentSchedules lps ON r.PaymentScheduleId = lps.Id
	WHERE r.IsActive = 1
		AND r.FunderId IS NULL
		AND r.EntityType = 'CT'
		AND rt.Name IN ('OperatingLeaseRental', 'LeaseFloatRateAdj')
		AND r.SourceTable NOT IN ('CPUSchedule','SundryRecurring');
	
	CREATE NONCLUSTERED INDEX IX_Id ON #ReceivableInfo(ContractId);
	
	SELECT la.ContractId
		,MAX(lam.CurrentLeaseFinanceId) AS RenewalFinanceId
		,MAX(lam.AmendmentDate) AS RenewalDate
		,NULL AS ReceivableId
		,NULL AS LeaseIncomeId
	INTO #RenewalDetails
	FROM #AmendmentInfo la
		INNER JOIN LeaseFinances lf ON lf.ContractId = la.ContractId
			AND la.Renewal >= 1
		INNER JOIN LeaseAmendments lam ON lf.Id = lam.CurrentLeaseFinanceId
			AND lam.AmendmentType = 'Renewal' AND lam.LeaseAmendmentStatus = 'Approved'
	GROUP BY la.ContractId;

	CREATE NONCLUSTERED INDEX IX_Id ON #RenewalDetails(ContractId);
	
	UPDATE rd
		SET ReceivableId = t.ReceivableId
	FROM #RenewalDetails rd
		INNER JOIN (
				SELECT MIN(ri.Id) AS ReceivableId,ri.ContractId
				FROM #ReceivableInfo ri
					INNER JOIN #RenewalDetails rd ON ri.ContractId = rd.ContractId
				WHERE ri.StartDate > rd.RenewalDate
					  AND ri.ReceivableTypeName = 'OperatingLeaseRental'
				GROUP BY ri.ContractId) AS t ON t.ContractId = rd.ContractId;
				
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
		ec.ContractId
		,SUM(r.TotalAmount_Amount) [TotalPaymentAmount]
		,SUM(r.TotalAmount_Amount) [LeaseBookingReceivables]
		,SUM(r.TotalBalance_Amount) [ReceivablesBalance]
		,SUM(
			CASE
				WHEN r.IsGLPosted = 1 AND cod.ChargeOffId IS NULL
				THEN r.TotalAmount_Amount
				ELSE 0.00
			END) [TotalGLPostedReceivables]
		,SUM(
			CASE
				WHEN r.IsGLPosted = 1 AND cod.ChargeOffId IS NULL
				THEN r.TotalBalance_Amount
				ELSE 0.00
			END) [TotalBalanceReceivables]
	INTO #SumOfReceivables
	FROM #EligibleContracts ec
		INNER JOIN #ReceivableInfo r ON r.ContractId = ec.ContractId
		LEFT JOIN #ChargeOffDetails cod ON cod.ContractId = ec.ContractId
	WHERE r.ReceivableTypeName = 'OperatingLeaseRental'
	GROUP BY ec.ContractId;

	CREATE NONCLUSTERED INDEX IX_Id ON #SumOfReceivables(ContractId);

	IF(@IsSku = 0)
	BEGIN
	INSERT INTO #SumOfReceivableDetails
	SELECT
		ec.ContractId
		,SUM(
			CASE
				WHEN r.IsGLPosted = 1 AND rd.AssetComponentType != 'Finance'
					AND rn.ContractId IS NULL
				THEN rd.Amount_Amount
				WHEN r.IsGLPosted = 1 AND rd.AssetComponentType != 'Finance'
					AND rn.ContractId IS NOT NULL AND r.StartDate >= rn.RenewalDate
				THEN rd.Amount_Amount
				ELSE 0.00
			END) [TotalGLPostedReceivables_LeaseComponent_Table]
		,SUM(
			CASE
				WHEN r.IsGLPosted = 1 AND cod.ContractId IS NULL
					 AND rd.AssetComponentType != 'Finance'
				THEN rd.Amount_Amount
				ELSE 0.00
			END) [GLPostedReceivables_LeaseComponent_Table]
		,SUM(
			CASE
				WHEN r.IsGLPosted = 1 AND cod.ContractId IS NULL
					 AND rd.AssetComponentType = 'Finance'
				THEN rd.Amount_Amount
				ELSE 0.00
			END) [GLPostedReceivables_FinanceComponent_Table]
		,SUM(
			CASE
				WHEN r.IsGLPosted = 1 AND cod.ContractId IS NULL
					 AND rd.AssetComponentType != 'Finance'
				THEN rd.Balance_Amount
				ELSE 0.00
			END) [OutstandingReceivables_LeaseComponent_Table]
		,SUM(
			CASE
				WHEN r.IsGLPosted = 1 AND cod.ContractId IS NULL
					 AND rd.AssetComponentType = 'Finance'
				THEN rd.Balance_Amount
				ELSE 0.00
			END) [OutstandingReceivables_FinanceComponent_Table]
		,SUM(
			CASE
				WHEN r.IsGLPosted = 0 AND cod.ContractId IS NULL
					 AND rd.AssetComponentType = 'Finance'
				THEN rd.Amount_Amount
				ELSE 0.00
			END) [LongTermReceivables_FinanceComponent_Table]
	FROM #EligibleContracts ec
		INNER JOIN #ReceivableInfo r ON r.ContractId = ec.ContractId
		INNER JOIN ReceivableDetails rd ON rd.ReceivableId = r.Id
		LEFT JOIN #ChargeOffDetails cod ON cod.ContractId = ec.ContractId
		LEFT JOIN #RenewalDetails rn ON rn.ContractId = ec.ContractId
	WHERE rd.IsActive = 1
		  AND r.ReceivableTypeName = 'OperatingLeaseRental'
	GROUP BY ec.ContractId;
	END

	IF(@IsSku = 1)
	BEGIN
	SET @Sql=
	'SELECT
		ec.ContractId
		,SUM(
			CASE
				WHEN r.IsGLPosted = 1
					AND rn.ContractId IS NULL
				THEN rd.LeaseComponentAmount_Amount
				WHEN r.IsGLPosted = 1
					AND rn.ContractId IS NOT NULL AND r.StartDate >= rn.RenewalDate
				THEN rd.LeaseComponentAmount_Amount
				ELSE 0.00
			END) [TotalGLPostedReceivables_LeaseComponent_Table]
		,SUM(
			CASE
				WHEN r.IsGLPosted = 1 AND cod.ContractId IS NULL
				THEN rd.LeaseComponentAmount_Amount
				ELSE 0.00
			END) [GLPostedReceivables_LeaseComponent_Table]
		,SUM(
			CASE
				WHEN r.IsGLPosted = 1 AND cod.ContractId IS NULL
				THEN rd.NonLeaseComponentAmount_Amount
				ELSE 0.00
			END) [GLPostedReceivables_FinanceComponent_Table]
		,SUM(
			CASE
				WHEN r.IsGLPosted = 1 AND cod.ContractId IS NULL
				THEN rd.LeaseComponentBalance_Amount
				ELSE 0.00
			END) [OutstandingReceivables_LeaseComponent_Table]
		,SUM(
			CASE
				WHEN r.IsGLPosted = 1 AND cod.ContractId IS NULL
				THEN rd.NonLeaseComponentBalance_Amount
				ELSE 0.00
			END) [OutstandingReceivables_FinanceComponent_Table]
		,SUM(
			CASE
				WHEN r.IsGLPosted = 0 AND cod.ContractId IS NULL
				THEN rd.NonLeaseComponentAmount_Amount
				ELSE 0.00
			END) [LongTermReceivables_FinanceComponent_Table]
	FROM #EligibleContracts ec
		INNER JOIN #ReceivableInfo r ON r.ContractId = ec.ContractId
		INNER JOIN ReceivableDetails rd ON rd.ReceivableId = r.Id
		LEFT JOIN #ChargeOffDetails cod ON cod.ContractId = ec.ContractId
		LEFT JOIN #RenewalDetails rn ON rn.ContractId = ec.ContractId
	WHERE rd.IsActive = 1
		  AND r.ReceivableTypeName = ''OperatingLeaseRental''
	GROUP BY ec.ContractId;'

	INSERT INTO #SumOfReceivableDetails
	EXEC (@Sql)
	END

	CREATE NONCLUSTERED INDEX IX_Id ON #SumOfReceivableDetails(ContractId);

	IF(@IsSku = 0)
	BEGIN

	INSERT INTO #ReceiptApplicationReceivableDetails
		SELECT r.EntityId
			 , ReceiptClassification
			 , rt.ReceiptTypeName
			 , rd.AssetComponentType
			 , c.IsNonAccrual AS IsNonAccrual
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
			 JOIN Contracts c ON c.Id = #EligibleContracts.ContractId
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
			 LEFT JOIN #ChargeOffDetails co ON r.EntityId = co.ContractId
			 LEFT JOIN LeasePaymentSchedules lps ON lps.Id = r.PaymentScheduleId
		WHERE rd.IsActive = 1
			 AND rard.IsActive = 1
			 AND rt.IsActive = 1
			 AND r.FunderId IS NULL
			 AND (receivableTypes.Name IN('OperatingLeaseRental', 'LeaseFloatRateAdj', 'OperatingLeaseRental', 'OverTermRental', 'Supplemental', 'LoanInterest', 'LoanPrincipal')
				  OR (r.IsGLPosted = 0 AND receivableTypes.Name NOT IN('OperatingLeaseRental', 'LeaseFloatRateAdj', 'OperatingLeaseRental', 'OverTermRental', 'Supplemental', 'LoanInterest', 'LoanPrincipal', 'PropertyTax', 'PropertyTaxEscrow', 'AssetSale'))
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
		WHERE (r.ReceivableType IN('OperatingLeaseRental', 'LeaseFloatRateAdj', 'OperatingLeaseRental', 'OverTermRental', 'Supplemental', 'LoanInterest', 'LoanPrincipal')
			   OR (r.IsGLPosted = 0 AND r.ReceivableType NOT IN('OperatingLeaseRental', 'LeaseFloatRateAdj', 'OperatingLeaseRent', 'OverTermRental', 'Supplemental', 'LoanInterest', 'LoanPrincipal', 'PropertyTax', 'PropertyTaxEscrow', 'AssetSale'))
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
	WHERE (r.ReceivableType IN ('OperatingLeaseRental', 'LeaseFloatRateAdj', 'OperatingLeaseRental', 'OverTermRental', 'Supplemental', 'LoanInterest', 'LoanPrincipal')
		   OR (r.IsGLPosted = 0 AND r.ReceivableType NOT IN ('OperatingLeaseRental', 'LeaseFloatRateAdj', 'OperatingLeaseRental', 'OverTermRental', 'Supplemental', 'LoanInterest', 'LoanPrincipal', 'PropertyTax', 'PropertyTaxEscrow', 'AssetSale'))
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


	INSERT INTO #SumOfReceiptApplicationReceivableDetails
	SELECT
		  r.EntityId
		, SUM(CASE
				  WHEN r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00 AND RecoveryAmount_Amount = 0.00 
					   AND (r.StartDate < cod.ChargeOffDate  OR cod.ChargeOffDate IS NULL)
					   AND ((nc.DoubtfulCollectability IS NOT NULL AND (nc.DoubtfulCollectability = 0 OR r.GLTransactionType NOT IN ('OperatingLeaseAR'))) OR nc.DoubtfulCollectability IS NULL) 
				  THEN r.LeaseComponentAmountApplied_Amount
				  WHEN r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00 AND RecoveryAmount_Amount = 0.00 
					   AND nc.DoubtfulCollectability IS NOT NULL AND nc.DoubtfulCollectability = 1 AND r.GLTransactionType IN ('OperatingLeaseAR')
				  THEN r.LeaseComponentAmountApplied_Amount
				  ELSE 0.00
			  END) [TotalPaidReceivables_LeaseComponent_Table]
		, SUM(CASE
				  WHEN ReceiptClassification = 'Cash'
					   AND r.ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund')
					   AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00 AND RecoveryAmount_Amount = 0.00
					   AND (r.StartDate < cod.ChargeOffDate OR cod.ChargeOffDate IS NULL)
					   AND ((nc.DoubtfulCollectability IS NOT NULL AND (nc.DoubtfulCollectability = 0 OR r.GLTransactionType NOT IN ('OperatingLeaseAR'))) OR nc.DoubtfulCollectability IS NULL)  
				  THEN r.LeaseComponentAmountApplied_Amount
				  WHEN ReceiptClassification = 'Cash'
					   AND r.ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund')
					   AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00 AND RecoveryAmount_Amount = 0.00
					   AND nc.DoubtfulCollectability IS NOT NULL AND nc.DoubtfulCollectability = 1 AND r.GLTransactionType IN ('OperatingLeaseAR')
				  THEN r.LeaseComponentAmountApplied_Amount
				  ELSE 0.00
			  END) [TotalPaidReceivablesviaCash_LeaseComponent_Table]
		, SUM(CASE
				  WHEN (ReceiptClassification NOT IN ('Cash') OR r.ReceiptTypeName IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund'))
						AND RecoveryAmount_Amount = 0.00 AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00
						AND (r.StartDate < cod.ChargeOffDate OR cod.ChargeOffDate IS NULL)
						AND ((nc.DoubtfulCollectability IS NOT NULL AND (nc.DoubtfulCollectability = 0 OR r.GLTransactionType NOT IN ('OperatingLeaseAR'))) OR nc.DoubtfulCollectability IS NULL) 
					THEN r.LeaseComponentAmountApplied_Amount
					WHEN (ReceiptClassification NOT IN ('Cash') OR r.ReceiptTypeName IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund'))
						AND RecoveryAmount_Amount = 0.00 AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00
						AND nc.DoubtfulCollectability IS NOT NULL AND nc.DoubtfulCollectability = 1 AND r.GLTransactionType IN ('OperatingLeaseAR')
					THEN r.LeaseComponentAmountApplied_Amount
					ELSE 0
			  END) [TotalPaidReceivablesviaNonCash_LeaseComponent_Table]
		, SUM(CASE
				  WHEN RecoveryAmount_Amount = 0.00 AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_NLC = 0.00
					   AND (r.StartDate < cod.ChargeOffDate OR cod.ChargeOffDate IS NULL)
				  THEN r.NonLeaseComponentAmountApplied_Amount
				  ELSE 0.00
			  END) [TotalPaidReceivables_FinanceComponent_Table]
		, SUM(CASE
				  WHEN ReceiptClassification = 'Cash'
					   AND r.ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund')
					   AND RecoveryAmount_Amount = 0.00 AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_NLC = 0.00
					   AND (r.StartDate < cod.ChargeOffDate OR cod.ChargeOffDate IS NULL)
				  THEN r.NonLeaseComponentAmountApplied_Amount
				  ELSE 0.00
			  END) [TotalPaidReceivablesviaCash_FinanceComponent_Table]
		, SUM(CASE
				  WHEN (ReceiptClassification NOT IN ('Cash') OR r.ReceiptTypeName IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund'))
					   AND RecoveryAmount_Amount = 0.00 AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_NLC = 0.00
					   AND (r.StartDate < cod.ChargeOffDate OR cod.ChargeOffDate IS NULL)
				  THEN r.NonLeaseComponentAmountApplied_Amount
				  ELSE 0.00
			  END) [TotalPaidReceivablesviaNonCash_FinanceComponent_Table]
		, SUM(CASE
				  WHEN r.RecoveryAmount_LC != 0.00 OR r.GainAmount_LC != 0.00
				  THEN r.RecoveryAmount_LC + r.GainAmount_LC
				  ELSE 0.00
			  END) [Recovery_LeaseComponent_Table]
		, SUM(CASE
				  WHEN r.RecoveryAmount_NLC != 0.00 OR r.GainAmount_NLC != 0.00
				  THEN r.RecoveryAmount_NLC + GainAmount_NLC
				  ELSE 0.00
			  END) [Recovery_FinanceComponent_Table]
		, SUM(CASE
				  WHEN (r.RecoveryAmount_Amount = 0.00 AND r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00)
					   AND r.StartDate < cod.ChargeOffDate
					   AND cod.Contractid IS NOT NULL
					   AND ((nc.DoubtfulCollectability IS NOT NULL AND (nc.DoubtfulCollectability = 0 OR r.GLTransactionType NOT IN ('OperatingLeaseAR'))) OR nc.DoubtfulCollectability IS NULL)
				  THEN r.LeaseComponentAmountApplied_Amount
				  WHEN r.GLTransactionType IN ('OperatingLeaseAR')
					   AND cod.Contractid IS NOT NULL
					   AND r.RecoveryAmount_Amount = 0.00 AND r.GainAmount_Amount = 0.00  AND r.ChargeoffExpenseAmount_LC = 0.00
					   AND nc.DoubtfulCollectability IS NOT NULL AND nc.DoubtfulCollectability = 1
				  THEN r.LeaseComponentAmountApplied_Amount
				  ELSE 0
			  END) as GLPostedPreChargeOff_LeaseComponent_Table
		, SUM(CASE
					WHEN (r.RecoveryAmount_Amount = 0.00 AND r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_NLC = 0.00)
						AND r.StartDate < cod.ChargeOffDate
						AND cod.Contractid IS NOT NULL
					THEN r.NonLeaseComponentAmountApplied_Amount
					ELSE 0
			  END) AS GLPostedPreChargeOff_FinanceComponent_Table
		, SUM(ISNULL(r.GainAmount_LC, 0.00)) [ChargeOffGainOnRecovery_LeaseComponent_Table]
		, SUM(ISNULL(r.GainAmount_NLC, 0.00)) AS [ChargeOffGainOnRecovery_NonLeaseComponent_Table]
	FROM #ReceiptApplicationReceivableDetails r
		LEFT JOIN #ChargeOffDetails cod ON cod.ContractId = r.EntityId
		LEFT JOIN #NonAccrualDetails nc ON nc.ContractId = r.EntityId
	WHERE r.ReceiptStatus IN ('Completed','Posted')
		  AND r.ReceivableType IN ('OperatingLeaseRental')
	GROUP BY r.EntityId;

	END

	
	IF(@IsSku = 1)
	BEGIN

	SET @SQL = 
		'SELECT DISTINCT
			   r.EntityId
			 , ReceiptClassification
			 , rt.ReceiptTypeName
			 , rd.AssetComponentType
			 , c.IsNonAccrual AS IsNonAccrual
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
			 JOIN Contracts c ON c.Id = #EligibleContracts.ContractId
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
			 LEFT JOIN #ChargeOffDetails co ON r.EntityId = co.ContractId
			 LEFT JOIN LeasePaymentSchedules lps ON lps.Id = r.PaymentScheduleId
		WHERE rd.IsActive = 1
			 AND rard.IsActive = 1
			 AND rt.IsActive = 1
			 AND r.FunderId IS NULL
		 	 AND (receivableTypes.Name IN(''OperatingLeaseRental'', ''LeaseFloatRateAdj'', ''OperatingLeaseRental'', ''OverTermRental'', ''Supplemental'', ''LoanInterest'', ''LoanPrincipal'')
			 	  OR (r.IsGLPosted = 0 AND receivableTypes.Name NOT IN(''OperatingLeaseRental'', ''LeaseFloatRateAdj'', ''OperatingLeaseRental'', ''OverTermRental'', ''Supplemental'', ''LoanInterest'', ''LoanPrincipal'', ''PropertyTax'', ''PropertyTaxEscrow'', ''AssetSale''))
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
			 AND (r.ReceivableType IN(''OperatingLeaseRental'', ''LeaseFloatRateAdj'', ''OperatingLeaseRental'', ''OverTermRental'', ''Supplemental'', ''LoanInterest'', ''LoanPrincipal'')
				  OR (r.IsGLPosted = 0 AND r.ReceivableType NOT IN(''OperatingLeaseRental'', ''LeaseFloatRateAdj'', ''OperatingLeaseRental'', ''OverTermRental'', ''Supplemental'', ''LoanInterest'', ''LoanPrincipal'', ''PropertyTax'', ''PropertyTaxEscrow'', ''AssetSale''))
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
		WHERE (r.ReceivableType IN(''OperatingLeaseRental'', ''LeaseFloatRateAdj'', ''OperatingLeaseRental'', ''OverTermRental'', ''Supplemental'', ''LoanInterest'', ''LoanPrincipal'')
			   OR (r.IsGLPosted = 0 AND r.ReceivableType NOT IN(''OperatingLeaseRental'', ''LeaseFloatRateAdj'', ''OperatingLeaseRent'', ''OverTermRental'', ''Supplemental'', ''LoanInterest'', ''LoanPrincipal'', ''PropertyTax'', ''PropertyTaxEscrow'', ''AssetSale''))
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

	INSERT INTO #SumOfReceiptApplicationReceivableDetails
	SELECT
		  r.EntityId
		, SUM(CASE
				  WHEN r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00 AND RecoveryAmount_Amount = 0.00 
					   AND (r.StartDate < cod.ChargeOffDate  OR cod.ChargeOffDate IS NULL)
					   AND ((nc.DoubtfulCollectability IS NOT NULL AND (nc.DoubtfulCollectability = 0 OR r.GLTransactionType NOT IN ('OperatingLeaseAR'))) OR nc.DoubtfulCollectability IS NULL) 
				  THEN r.LeaseComponentAmountApplied_Amount
				  WHEN r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00 AND RecoveryAmount_Amount = 0.00 
					   AND nc.DoubtfulCollectability IS NOT NULL AND nc.DoubtfulCollectability = 1 AND r.GLTransactionType IN ('OperatingLeaseAR')
				  THEN r.LeaseComponentAmountApplied_Amount
				  ELSE 0.00
			  END) [TotalPaidReceivables_LeaseComponent_Table]
		, SUM(CASE
				  WHEN ReceiptClassification = 'Cash'
					   AND r.ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund')
					   AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00 AND RecoveryAmount_Amount = 0.00
					   AND (r.StartDate < cod.ChargeOffDate OR cod.ChargeOffDate IS NULL) 
					   AND ((nc.DoubtfulCollectability IS NOT NULL AND (nc.DoubtfulCollectability = 0 OR r.GLTransactionType NOT IN ('OperatingLeaseAR'))) OR nc.DoubtfulCollectability IS NULL)  
				  THEN r.LeaseComponentAmountApplied_Amount
				  WHEN ReceiptClassification = 'Cash'
					   AND r.ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund')
					   AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00 AND RecoveryAmount_Amount = 0.00
					   AND nc.DoubtfulCollectability IS NOT NULL AND nc.DoubtfulCollectability = 1 AND r.GLTransactionType IN ('OperatingLeaseAR')
				  THEN r.LeaseComponentAmountApplied_Amount
				  ELSE 0.00
			  END) [TotalPaidReceivablesviaCash_LeaseComponent_Table]
		, SUM(CASE
				  WHEN (ReceiptClassification NOT IN ('Cash') OR r.ReceiptTypeName IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund'))
						AND RecoveryAmount_Amount = 0.00 AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00
						AND (r.StartDate < cod.ChargeOffDate OR cod.ChargeOffDate IS NULL)
						AND ((nc.DoubtfulCollectability IS NOT NULL AND (nc.DoubtfulCollectability = 0 OR r.GLTransactionType NOT IN ('OperatingLeaseAR'))) OR nc.DoubtfulCollectability IS NULL) 
					THEN r.LeaseComponentAmountApplied_Amount
					WHEN (ReceiptClassification NOT IN ('Cash') OR r.ReceiptTypeName IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund'))
						AND RecoveryAmount_Amount = 0.00 AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00
						AND nc.DoubtfulCollectability IS NOT NULL AND nc.DoubtfulCollectability = 1 AND r.GLTransactionType IN ('OperatingLeaseAR')
					THEN r.LeaseComponentAmountApplied_Amount
					ELSE 0.00
			  END) [TotalPaidReceivablesviaNonCash_LeaseComponent_Table]
		, SUM(CASE
				  WHEN RecoveryAmount_Amount = 0.00 AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_NLC = 0.00
					   AND (r.StartDate < cod.ChargeOffDate OR cod.ChargeOffDate IS NULL)
				  THEN r.NonLeaseComponentAmountApplied_Amount
				  ELSE 0.00
			  END) [TotalPaidReceivables_FinanceComponent_Table]
		, SUM(CASE
				  WHEN ReceiptClassification = 'Cash'
					   AND r.ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund')
					   AND RecoveryAmount_Amount = 0.00 AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_NLC = 0.00
					   AND (r.StartDate < cod.ChargeOffDate OR cod.ChargeOffDate IS NULL)
				  THEN r.NonLeaseComponentAmountApplied_Amount
				  ELSE 0.00
			  END) [TotalPaidReceivablesviaCash_FinanceComponent_Table]
		, SUM(CASE
				  WHEN (ReceiptClassification NOT IN ('Cash') OR r.ReceiptTypeName IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund'))
					   AND RecoveryAmount_Amount = 0.00 AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_NLC = 0.00
				  THEN r.NonLeaseComponentAmountApplied_Amount
				  ELSE 0.00
			  END) [TotalPaidReceivablesviaNonCash_FinanceComponent_Table]
		, SUM(CASE
				  WHEN r.RecoveryAmount_LC != 0.00 OR r.GainAmount_LC != 0.00
				  THEN r.RecoveryAmount_LC + r.GainAmount_LC
				  ELSE 0.00
			  END) [Recovery_LeaseComponent_Table]
		, SUM(CASE
				  WHEN r.RecoveryAmount_NLC != 0.00 OR r.GainAmount_NLC != 0.00
				  THEN r.RecoveryAmount_NLC + GainAmount_NLC
				  ELSE 0.00
			  END) [Recovery_FinanceComponent_Table]
		, SUM(CASE
				  WHEN (r.RecoveryAmount_Amount = 0.00 AND r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00)
					   AND r.StartDate < cod.ChargeOffDate
					   AND cod.Contractid IS NOT NULL
					   AND ((nc.DoubtfulCollectability IS NOT NULL AND (nc.DoubtfulCollectability = 0 OR r.GLTransactionType NOT IN ('OperatingLeaseAR'))) OR nc.DoubtfulCollectability IS NULL)
				  THEN r.LeaseComponentAmountApplied_Amount
				   WHEN (r.RecoveryAmount_Amount = 0.00 AND r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00)
					   AND cod.Contractid IS NOT NULL
					   AND nc.DoubtfulCollectability IS NOT NULL AND nc.DoubtfulCollectability = 1 AND r.GLTransactionType IN ('OperatingLeaseAR')
				  THEN r.LeaseComponentAmountApplied_Amount
				  ELSE 0
			  END) as GLPostedPreChargeOff_LeaseComponent_Table
		, SUM(CASE
					WHEN (r.RecoveryAmount_Amount = 0.00 AND r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_NLC = 0.00)
						AND r.StartDate < cod.ChargeOffDate
						AND cod.Contractid IS NOT NULL
					THEN r.NonLeaseComponentAmountApplied_Amount
					ELSE 0
			  END) AS GLPostedPreChargeOff_FinanceComponent_Table
		, SUM(ISNULL(r.GainAmount_LC, 0.00)) [ChargeOffGainOnRecovery_LeaseComponent_Table]
		, SUM(ISNULL(r.GainAmount_NLC, 0.00)) AS [ChargeOffGainOnRecovery_NonLeaseComponent_Table]
	FROM #ReceiptApplicationReceivableDetails r
		LEFT JOIN #ChargeOffDetails cod ON cod.ContractId = r.EntityId
		LEFT JOIN #NonAccrualDetails nc ON nc.ContractId = r.EntityId
	WHERE r.ReceiptStatus IN ('Completed','Posted')
		  AND r.ReceivableType IN ('OperatingLeaseRental')
	GROUP BY r.EntityId;

	END

	CREATE NONCLUSTERED INDEX IX_Id ON #SumOfReceiptApplicationReceivableDetails(ContractId);

	UPDATE sord
		SET 
		sord.GLPostedReceivables_LeaseComponent_Table = sord.GLPostedReceivables_LeaseComponent_Table + sorard.GLPostedPreChargeOff_LeaseComponent_Table
		,sord.GLPostedReceivables_FinanceComponent_Table = sord.GLPostedReceivables_FinanceComponent_Table + sorard.GLPostedPreChargeOff_FinanceComponent_Table
	FROM #SumOfReceivableDetails sord
		INNER JOIN #SumOfReceiptApplicationReceivableDetails sorard ON sord.ContractId = sorard.ContractId
		INNER JOIN #ChargeOffDetails cod ON cod.ContractId = sord.ContractId

	UPDATE sor
		SET sor.TotalGLPostedReceivables = sor.TotalGLPostedReceivables + sorard.GLPostedPreChargeOff_LeaseComponent_Table + sorard.GLPostedPreChargeOff_FinanceComponent_Table
		,sor.ReceivablesBalance = sor.ReceivablesBalance + sorard.Recovery_LeaseComponent_Table + sorard.Recovery_FinanceComponent_Table
	FROM #SumOfReceivables sor
		INNER JOIN #SumOfReceiptApplicationReceivableDetails sorard ON sorard.ContractId = sor.ContractId
		INNER JOIN #ChargeOffDetails cod ON cod.ContractId = sor.ContractId

	SELECT
		ec.ContractId
		,SUM(CASE
				 WHEN cod.ContractId IS NULL
				 THEN pr.PrePaidAmount_Amount
				 ELSE 0.00
			 END) [PrepaidReceivables_LeaseComponent_Table]
		,SUM(CASE
				 WHEN cod.ContractId IS NULL
				 THEN pr.FinancingPrePaidAmount_Amount
				 ELSE 0.00
			 END) [PrepaidReceivables_FinanceComponent_Table]
	INTO #SumOfPrepaidReceivables
	FROM #EligibleContracts ec
		INNER JOIN #ReceivableInfo r ON r.ContractId = ec.ContractId
		INNER JOIN PrepaidReceivables pr ON pr.ReceivableId = r.Id
		LEFT JOIN #ChargeOffDetails cod ON cod.ContractId = ec.ContractId
	WHERE r.IsGLPosted = 0
		  AND pr.IsActive = 1
		  AND r.ReceivableTypeName = 'OperatingLeaseRental'
	GROUP BY ec.ContractId;

	CREATE NONCLUSTERED INDEX IX_Id ON #SumOfPrepaidReceivables(ContractId);


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
	'SELECT
		ec.ContractId
		,SUM(CASE
				WHEN la.IsLeaseAsset = 1
				THEN la.BookedResidual_Amount
				ELSE 0.00
			END) [LeaseBookedResidualAmount]
		,SUM(
			CASE
				WHEN la.IsLeaseAsset = 1
				THEN la.ThirdPartyGuaranteedResidual_Amount
				ELSE 0.00
			END) [LeaseThirdPartyGuaranteedResidualAmount]
		,SUM(CASE
				WHEN la.IsLeaseAsset = 1
				THEN la.CustomerGuaranteedResidual_Amount
				ELSE 0.00
			END) [LeaseCustomerGuaranteedResidualAmount]
		,SUM(CASE
				WHEN la.IsLeaseAsset = 0
				THEN la.BookedResidual_Amount
				ELSE 0.00
			END) [FinanceBookedResidualAmount]
		,SUM(
			CASE
				WHEN la.IsLeaseAsset = 0
				THEN la.ThirdPartyGuaranteedResidual_Amount
				ELSE 0.00
			END) [FinanceThirdPartyGuaranteedResidualAmount]
		,SUM(
			CASE
				WHEN la.IsLeaseAsset = 0
				THEN la.CustomerGuaranteedResidual_Amount
				ELSE 0.00
			END) [FinanceCustomerGuaranteedResidualAmount]
		,SUM(
			CASE
				WHEN la.IsLeaseAsset = 1
				THEN la.NBV_Amount
				ELSE 0.00
			END) [LeaseAssetCost]
	FROM #EligibleContracts ec
		INNER JOIN LeaseAssets la ON la.LeaseFinanceId = ec.LeaseFinanceId
		INNER JOIN Assets a ON la.AssetId = a.Id
		LEFT JOIN #OTPReclass otpr ON otpr.ContractId = ec.ContractId
	WHERE (la.IsActive = 1
		OR (otpr.ContractId IS NULL AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate > MaturityDate))))
		FilterCondition
	GROUP BY ec.ContractId;'

	IF @FilterCondition IS NOT NULL
		BEGIN
			SET @sql = REPLACE(@sql, 'FilterCondition', @FilterCondition);
		END;
	ELSE
		BEGIN
			SET @sql = REPLACE(@sql, 'FilterCondition', '');
		END;

	INSERT INTO #AssetResiduals
	EXEC (@Sql)

	CREATE NONCLUSTERED INDEX IX_Id ON #AssetResiduals(ContractId);

	SET @Sql =
	'SELECT
		ec.ContractId
		,SUM(bia.TaxCredit_Amount) [LeaseAssetETCAmount]
	FROM #EligibleContracts ec
		INNER JOIN LeaseAssets la ON la.LeaseFinanceId = ec.LeaseFinanceId
		INNER JOIN Assets a ON la.AssetId = a.Id
		INNER JOIN BlendedItemAssets bia ON bia.LeaseAssetId = la.Id
		LEFT JOIN #OTPReclass otpr ON otpr.ContractId = ec.ContractId
	WHERE (la.IsActive = 1
		OR (otpr.ContractId IS NULL AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate > MaturityDate))))
		AND la.IsLeaseAsset = 1
		FilterCondition
	GROUP BY ec.ContractId;'

	IF @FilterCondition IS NOT NULL
		BEGIN
			SET @sql = REPLACE(@sql, 'FilterCondition', @FilterCondition);
		END;
	ELSE
		BEGIN
			SET @sql = REPLACE(@sql, 'FilterCondition', '');
		END;

	INSERT INTO #BlendedItemAssetsInfo
	EXEC (@Sql)

	CREATE NONCLUSTERED INDEX IX_Id ON #BlendedItemAssetsInfo(ContractId);

	UPDATE ar
		SET ar.LeaseAssetCost = ar.LeaseAssetCost - bia.LeaseAssetETCAmount
	FROM #AssetResiduals ar
		INNER JOIN #BlendedItemAssetsInfo bia ON ar.ContractId = bia.ContractId;

	IF @IsSku = 1
	BEGIN
	SET @Sql = 
	'SELECT
		ec.ContractId
		,SUM(
			CASE
				WHEN las.IsLeaseComponent = 1
				THEN las.BookedResidual_Amount
				ELSE 0.00
			END) [SKULeaseBookedResidualAmount]
		,SUM(
			CASE
				WHEN las.IsLeaseComponent = 1
				THEN las.ThirdPartyGuaranteedResidual_Amount
				ELSE 0.00
			END) [SKULeaseThirdPartyGuaranteedResidualAmount]
		,SUM(
			CASE
				WHEN las.IsLeaseComponent = 1
				THEN las.CustomerGuaranteedResidual_Amount
				ELSE 0.00
			END) [SKULeaseCustomerGuaranteedResidualAmount]
		,SUM(
			CASE
				WHEN las.IsLeaseComponent = 0
				THEN las.BookedResidual_Amount
				ELSE 0.00
			END) [SKUFinanceBookedResidualAmount]
		,SUM(
			CASE
				WHEN las.IsLeaseComponent = 0
				THEN las.ThirdPartyGuaranteedResidual_Amount
				ELSE 0.00
			END) [SKUFinanceThirdPartyGuaranteedResidualAmount]
		,SUM(
			CASE
				WHEN las.IsLeaseComponent = 0
				THEN las.CustomerGuaranteedResidual_Amount
				ELSE 0.00
			END) [SKUFinanceCustomerGuaranteedResidualAmount]
		,SUM(
			CASE
				WHEN las.IsLeaseComponent = 1
				THEN las.NBV_Amount
				ELSE 0.00
			END)
		- SUM(
			CASE
				WHEN las.IsLeaseComponent = 1
				THEN las.ETCAdjustmentAmount_Amount
				ELSE 0.00
			END) [SKULeaseAssetCost]
	FROM #EligibleContracts ec
		INNER JOIN LeaseAssets la ON la.LeaseFinanceId = ec.LeaseFinanceId
		INNER JOIN Assets a ON la.AssetId = a.Id
		INNER JOIN LeaseAssetSKUs las ON las.LeaseAssetId = la.Id
		LEFT JOIN #OTPReclass otpr ON otpr.ContractId = ec.ContractId
	WHERE a.IsSKU = 1
		AND (la.IsActive = 1
		OR (otpr.ContractId IS NULL AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate > MaturityDate))))
	GROUP BY ec.ContractId;'

	INSERT INTO #SKUResiduals
	EXEC (@Sql)
	END

	CREATE NONCLUSTERED INDEX IX_Id ON #SKUResiduals(ContractId);

	MERGE #AssetResiduals ar
	USING (SELECT * FROM #SKUResiduals) sr
	ON (ar.ContractId = sr.ContractId)
		WHEN MATCHED
		THEN
		UPDATE SET ar.LeaseBookedResidualAmount = ar.LeaseBookedResidualAmount + sr.SKULeaseBookedResidualAmount
				,ar.LeaseThirdPartyGuaranteedResidualAmount = ar.LeaseThirdPartyGuaranteedResidualAmount + sr.SKULeaseThirdPartyGuaranteedResidualAmount
				,ar.LeaseCustomerGuaranteedResidualAmount = ar.LeaseCustomerGuaranteedResidualAmount + sr.SKULeaseCustomerGuaranteedResidualAmount
				,ar.FinanceBookedResidualAmount = ar.FinanceBookedResidualAmount + sr.SKUFinanceBookedResidualAmount
				,ar.FinanceThirdPartyGuaranteedResidualAmount = ar.FinanceThirdPartyGuaranteedResidualAmount + sr.SKUFinanceThirdPartyGuaranteedResidualAmount
				,ar.FinanceCustomerGuaranteedResidualAmount = ar.FinanceCustomerGuaranteedResidualAmount + sr.SKUFinanceCustomerGuaranteedResidualAmount
				,ar.LeaseAssetCost = ar.LeaseAssetCost + sr.SKULeaseAssetCost
		WHEN NOT MATCHED
		THEN
		INSERT (ContractId
			,LeaseBookedResidualAmount
			,LeaseThirdPartyGuaranteedResidualAmount
			,LeaseCustomerGuaranteedResidualAmount
			,FinanceBookedResidualAmount
			,FinanceThirdPartyGuaranteedResidualAmount
			,FinanceCustomerGuaranteedResidualAmount
			,LeaseAssetCost
			)
		VALUES (sr.ContractId
			,sr.SKULeaseBookedResidualAmount
			,sr.SKULeaseThirdPartyGuaranteedResidualAmount
			,sr.SKULeaseCustomerGuaranteedResidualAmount
			,sr.SKUFinanceBookedResidualAmount
			,sr.SKUFinanceThirdPartyGuaranteedResidualAmount
			,sr.SKUFinanceCustomerGuaranteedResidualAmount
			,sr.SKULeaseAssetCost
			);

	SELECT
		ar.ContractId
		,SUM(ar.LeaseBookedResidualAmount) - SUM(ar.LeaseThirdPartyGuaranteedResidualAmount) - SUM(ar.LeaseCustomerGuaranteedResidualAmount) [UnguaranteedResidual_LeaseComponent_Table]
		,SUM(ar.FinanceBookedResidualAmount) - SUM(ar.FinanceThirdPartyGuaranteedResidualAmount) - SUM(ar.FinanceCustomerGuaranteedResidualAmount) [UnguaranteedResidual_FinanceComponent_Table]
		,SUM(ar.LeaseThirdPartyGuaranteedResidualAmount) + SUM(ar.LeaseCustomerGuaranteedResidualAmount) [GuaranteedResidual_LeaseComponent_Table]
		,SUM(ar.FinanceThirdPartyGuaranteedResidualAmount) + SUM(ar.FinanceCustomerGuaranteedResidualAmount) [GuaranteedResidual_FinanceComponent_Table]
		,SUM(ar.LeaseAssetCost) [AssetCost_LeaseComponent_Table]
	INTO #SumOfLeaseAssets
	FROM #AssetResiduals ar
	GROUP BY ar.ContractId;

	CREATE NONCLUSTERED INDEX IX_Id ON #SumOfLeaseAssets(ContractId);

	UPDATE sola
		SET sola.UnguaranteedResidual_LeaseComponent_Table = 0.00
		,sola.UnguaranteedResidual_FinanceComponent_Table = 0.00
		,sola.GuaranteedResidual_LeaseComponent_Table = 0.00
		,sola.GuaranteedResidual_FinanceComponent_Table = 0.00
		,sola.AssetCost_LeaseComponent_Table = 0.00
	FROM #EligibleContracts ec
		INNER JOIN #SumOfLeaseAssets sola ON sola.ContractId = ec.ContractId
		INNER JOIN #OTPReclass otpr ON otpr.ContractId = ec.ContractId;

	UPDATE sola
		SET 
		sola.UnguaranteedResidual_LeaseComponent_Table = 
			(CASE
				WHEN cod.ContractId IS NULL
				THEN sola.UnguaranteedResidual_LeaseComponent_Table * rft.RetainedPercentage / 100
				ELSE 0.00
			END)
		,sola.UnguaranteedResidual_FinanceComponent_Table = 
			(CASE
				WHEN cod.ContractId IS NULL
				THEN sola.UnguaranteedResidual_FinanceComponent_Table * rft.RetainedPercentage / 100
				ELSE 0.00
			END)
		,sola.GuaranteedResidual_LeaseComponent_Table =
			(CASE
				WHEN cod.ContractId IS NULL
				THEN sola.GuaranteedResidual_LeaseComponent_Table * rft.RetainedPercentage / 100
				ELSE 0.00
			END)
		,sola.GuaranteedResidual_FinanceComponent_Table = 
			(CASE
				WHEN cod.ContractId IS NULL
				THEN sola.GuaranteedResidual_FinanceComponent_Table * rft.RetainedPercentage / 100
				ELSE 0.00
			END)
		,sola.AssetCost_LeaseComponent_Table = 
			(CASE
				WHEN cod.ContractId IS NULL
				THEN sola.AssetCost_LeaseComponent_Table * rft.RetainedPercentage / 100
				ELSE 0.00
			END)
	FROM #EligibleContracts ec
		INNER JOIN #SumOfLeaseAssets sola ON sola.ContractId = ec.ContractId
		LEFT JOIN ReceivableForTransfers rft ON rft.ContractId = sola.ContractId
			AND rft.ApprovalStatus = 'Approved'
			AND rft.ContractType = 'Lease'
		LEFT JOIN #ChargeOffDetails cod ON cod.ContractId = sola.ContractId
	WHERE (rft.Id IS NOT NULL OR cod.ContractId IS NOT NULL) AND ec.SyndicationType != 'SaleOfPayments';

	SELECT
		ec.ContractId
		,SUM(CASE WHEN ec.SyndicationEffectiveDate = lfd.CommencementDate AND lis.IncomeDate = ec.SyndicationEffectiveDate
			AND otpr.ContractId IS NULL AND cod.ContractId IS NULL
			THEN lis.FinanceResidualIncomeBalance_Amount
			WHEN ec.SyndicationEffectiveDate != lfd.CommencementDate AND lis.IncomeDate = DATEADD(DAY,-1,ec.SyndicationEffectiveDate)
			AND otpr.ContractId IS NULL AND cod.ContractId IS NULL
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
		WHERE ec.SyndicationType = 'SaleOfPayments' AND ec.AccountingStandard != 'ASC840_IAS17'
		AND la.BookedResidual_Amount != 0.00 AND la.ThirdPartyGuaranteedResidual_Amount = 0.00 AND la.CustomerGuaranteedResidual_Amount = 0.00
		) AS t ON t.ContractId = ec.ContractId
	LEFT JOIN #OTPReclass otpr ON otpr.ContractId = ec.ContractId
	LEFT JOIN #ChargeOffDetails cod ON cod.ContractId = ec.ContractId
	WHERE lis.IsAccounting = 1 AND lis.IsLessorOwned = 1
	GROUP BY ec.ContractId;

	UPDATE sola
		SET sola.UnguaranteedResidual_FinanceComponent_Table = sou.ResidualIncomeBalance_FinanceComponent
	FROM #SumOfLeaseAssets sola
		INNER JOIN #SaleOfPaymentsUnguaranteedInfo sou ON sola.ContractId = sou.ContractId;

	UPDATE sord
		SET sord.LongTermReceivables_FinanceComponent_Table = ISNULL(sord.LongTermReceivables_FinanceComponent_Table,0.00) + ISNULL(sola.GuaranteedResidual_FinanceComponent_Table,0.00)
	FROM #EligibleContracts ec
		INNER JOIN #SumOfReceivableDetails sord ON sord.ContractId = ec.ContractId
		INNER JOIN #SumOfLeaseAssets sola ON sola.ContractId = ec.ContractId
	WHERE @IncludeGuaranteedResidualinLongTermReceivables = 'True';

	SELECT
		ec.ContractId
		,SUM(
			CASE
				WHEN bi.SystemConfigType = 'ReAccrualRentalIncome' AND ad.ReAccrualId IS NOT NULL
				THEN bi.Amount_Amount
				ELSE 0.00
			END) [ReAccrualRentalIncome_BI]
		,SUM(
			CASE
				WHEN bi.SystemConfigType = 'ReAccrualFinanceIncome' AND ad.ReAccrualId IS NOT NULL
				THEN bi.Amount_Amount
				ELSE 0.00
			END) [ReAccrualFinanceIncome_BI]
		,SUM(
			CASE
				WHEN bi.SystemConfigType = 'ReAccrualFinanceResidualIncome' AND ad.ReAccrualId IS NOT NULL
				THEN bi.Amount_Amount
				ELSE 0.00
			END) [ReAccrualFinanceResidualIncome_BI]
	INTO #BlendedItemInfo
	FROM #EligibleContracts ec
		INNER JOIN LeaseBlendedItems lbi ON lbi.LeaseFinanceId = ec.LeaseFinanceId
		INNER JOIN BlendedItems bi ON lbi.BlendedItemId = bi.Id
		INNER JOIN #AccrualDetails ad ON ad.ContractId = ec.ContractId
	WHERE bi.IsActive = 1
		AND bi.BookRecognitionMode = 'RecognizeImmediately'
	GROUP BY ec.ContractId;

	CREATE NONCLUSTERED INDEX IX_Id ON #BlendedItemInfo(ContractId);

	SELECT
		ec.ContractId
		,SUM(
			CASE
				WHEN bi.SystemConfigType = 'ReAccrualRentalIncome'
					AND bis.IsNonAccrual = 0
					AND bis.PostDate IS NOT NULL
				THEN bis.Income_Amount
				ELSE 0.00
			END) [ReAccrualRentalIncome_BIS]
		,SUM(
			CASE
				WHEN bi.SystemConfigType = 'ReAccrualRentalIncome'
					AND bis.PostDate IS NOT NULL
				THEN bis.Income_Amount
				ELSE 0.00
			END) [ReAccrualDeferredRentalIncome_BIS]
		,SUM(
			CASE
				WHEN bi.SystemConfigType = 'ReAccrualFinanceIncome'
					AND bis.PostDate IS NOT NULL
				THEN bis.Income_Amount
				ELSE 0.00
			END) [ReAccrualFinanceIncome_BIS]
		,SUM(
			CASE
				WHEN bi.SystemConfigType = 'ReAccrualFinanceResidualIncome'
					AND bis.PostDate IS NOT NULL
				THEN bis.Income_Amount
				ELSE 0.00
			END) [ReAccrualFinanceResidualIncome_BIS]
		,SUM(
			CASE
				WHEN bi.SystemConfigType = 'ReAccrualFinanceIncome'
					AND bis.PostDate IS NOT NULL
					AND bis.IsNonAccrual = 0
				THEN bis.Income_Amount
				ELSE 0.00
			END) [ReAccrualFinanceEarnedIncome_BIS]
		,SUM(
			CASE
				WHEN bi.SystemConfigType = 'ReAccrualFinanceResidualIncome'
					AND bis.PostDate IS NOT NULL
					AND bis.IsNonAccrual = 0
				THEN bis.Income_Amount
				ELSE 0.00
			END) [ReAccrualFinanceEarnedResidualIncome_BIS]
		,SUM(
			CASE
				WHEN bi.SystemConfigType = 'ReAccrualFinanceIncome'
					AND bis.PostDate IS NULL
				THEN bis.Income_Amount
				ELSE 0.00
			END) [ReAccrualFinanceUnEarnedIncome_BIS]
		,SUM(
			CASE
				WHEN bi.SystemConfigType = 'ReAccrualFinanceResidualIncome'
					AND bis.PostDate IS NULL
				THEN bis.Income_Amount
				ELSE 0.00
			END) [ReAccrualFinanceUnEarnedResidualIncome_BIS]
	INTO #BlendedIncomeSchInfo
	FROM #EligibleContracts ec
		INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
		INNER JOIN BlendedIncomeSchedules bis ON bis.LeaseFinanceId = lf.Id
		INNER JOIN BlendedItems bi ON bis.BlendedItemId = bi.Id
		INNER JOIN #AccrualDetails ad ON ad.ContractId = ec.ContractId
			AND ad.ReAccrualId IS NOT NULL
	WHERE bi.IsActive = 1
		AND bis.IsAccounting = 1
		AND bi.BookRecognitionMode != 'RecognizeImmediately'
	GROUP BY ec.ContractId;

	CREATE NONCLUSTERED INDEX IX_Id ON #BlendedIncomeSchInfo(ContractId);

	SELECT
		ec.ContractId
		,SUM(
			CASE
				WHEN lis.IsGLPosted = 1
					AND lis.IsAccounting = 1
					AND lis.IsNonAccrual = 0
					AND lis.LeaseModificationType != 'ChargeOff'
					AND rd.ContractId IS NULL
				THEN lis.RentalIncome_Amount
				WHEN lis.IsGLPosted = 1
					AND lis.IsAccounting = 1
					AND lis.IsNonAccrual = 0
					AND rd.ContractId IS NOT NULL 
					AND lis.LeaseFinanceId >= rd.RenewalFinanceId 
					AND lis.LeaseModificationType != 'ChargeOff'
				THEN lis.RentalIncome_Amount
				ELSE 0.00
			END) [RentalIncome_Table]
		,SUM(
			CASE
				WHEN lis.IsGLPosted = 1
					AND lis.IsAccounting = 1
					AND lis.IsNonAccrual = 1
				THEN lis.RentalIncome_Amount
				ELSE 0.00
			END) [SuspendedRentalIncome_Table]
		,SUM(
			CASE
				WHEN lis.IsGLPosted = 1
					AND lis.IsAccounting = 1
					AND rd.ContractId IS NULL 
				THEN lis.RentalIncome_Amount
				WHEN lis.IsGLPosted = 1
					AND lis.IsAccounting = 1
					AND rd.ContractId IS NOT NULL 
					AND lis.LeaseFinanceId >= rd.RenewalFinanceId 
				THEN lis.RentalIncome_Amount
				ELSE 0.00
			END) [DeferredRentalIncome_Table]
		,SUM(
			CASE
				WHEN cod.ContractId IS NULL 
					AND lis.IsAccounting = 1
				THEN lis.FinanceIncome_Amount
				WHEN cod.ContractId IS NOT NULL 
					AND lis.IsAccounting = 1 
					AND lis.IncomeDate < cod.ChargeOffDate
				THEN lis.FinanceIncome_Amount
				ELSE 0.00
			END) [FinancingTotalIncome_Accounting_Table]
		,SUM(
			CASE
				WHEN cod.ContractId IS NULL
					AND ad.ReAccrualId IS NULL
					AND lis.IsSchedule = 1
				THEN lis.FinanceIncome_Amount
				WHEN cod.ContractId IS NOT NULL 
					AND lis.IsSchedule = 1 
					AND lis.IncomeDate < cod.ChargeOffDate
				THEN lis.FinanceIncome_Amount
				WHEN cod.ContractId IS NULL 
					AND ad.ReAccrualId IS NOT NULL 
					AND lis.IsSchedule = 1 
					AND lis.IsNonAccrual = 0
				THEN lis.FinanceIncome_Amount
				ELSE 0.00
			END) [FinancingTotalIncome_Schedule_Table]
		,SUM(
			CASE
				WHEN lis.IsGLPosted = 1
					AND lis.IsAccounting = 1
					AND lis.IsNonAccrual = 0
					AND rd.ContractId IS NULL
					AND lis.LeaseModificationType != 'ChargeOff'
				THEN lis.FinanceIncome_Amount
				WHEN lis.IsGLPosted = 1
					AND lis.IsAccounting = 1
					AND lis.IsNonAccrual = 0
					AND rd.ContractId IS NOT NULL 
					AND lis.LeaseFinanceId >= rd.RenewalFinanceId
					AND lis.LeaseModificationType != 'ChargeOff'
				THEN lis.FinanceIncome_Amount
				ELSE 0.00
			END) [FinancingTotalEarnedIncome_Table]
		,SUM(
			CASE
				WHEN lis.IsGLPosted = 1
					AND lis.IsAccounting = 1
					AND lis.IsNonAccrual = 0
					AND rd.ContractId IS NULL
					AND lis.LeaseModificationType != 'ChargeOff'
				THEN lis.FinanceIncome_Amount - lis.FinanceResidualIncome_Amount
				WHEN lis.IsGLPosted = 1
					AND lis.IsAccounting = 1
					AND lis.IsNonAccrual = 0
					AND rd.ContractId IS NOT NULL 
					AND lis.LeaseFinanceId >= rd.RenewalFinanceId
					AND lis.LeaseModificationType != 'ChargeOff'
				THEN lis.FinanceIncome_Amount - lis.FinanceResidualIncome_Amount
				ELSE 0.00
			END)[FinancingEarnedIncome_Table]
		,SUM(
			CASE
				WHEN lis.IsGLPosted = 1
					AND lis.IsAccounting = 1
					AND lis.IsNonAccrual = 0
					AND rd.ContractId IS NULL
					AND lis.LeaseModificationType != 'ChargeOff'
				THEN lis.FinanceResidualIncome_Amount
				WHEN lis.IsGLPosted = 1
					AND lis.IsAccounting = 1
					AND lis.IsNonAccrual = 0
					AND rd.ContractId IS NOT NULL 
					AND lis.LeaseFinanceId >= rd.RenewalFinanceId 
					AND lis.LeaseModificationType != 'ChargeOff'
				THEN lis.FinanceResidualIncome_Amount
				ELSE 0.00
			END) [FinancingEarnedResidualIncome_Table]
		,SUM(
			CASE
				WHEN lis.IsGLPosted = 0
					AND lis.IsAccounting = 1
				THEN lis.FinanceIncome_Amount
				ELSE 0.00
			END) [FinancingTotalUnearnedIncome_Table]
		,SUM(
			CASE
				WHEN lis.IsGLPosted = 0
					AND lis.IsAccounting = 1
				THEN lis.FinanceIncome_Amount - lis.FinanceResidualIncome_Amount
				ELSE 0.00
			END) [FinancingUnearnedIncome_Table]
		,SUM(
			CASE
				WHEN lis.IsGLPosted = 0
					AND lis.IsAccounting = 1
				THEN lis.FinanceResidualIncome_Amount
				ELSE 0.00
			END) [FinancingUnearnedResidualIncome_Table]
		,SUM(
			CASE
				WHEN lis.IsGLPosted = 1
					AND lis.IsAccounting = 1
					AND lis.IsNonAccrual = 1
				THEN lis.FinanceIncome_Amount - lis.FinanceResidualIncome_Amount
				ELSE 0.00
			END) [FinancingRecognizedSuspendedIncome_Table]
		,SUM(
			CASE
				WHEN lis.IsGLPosted = 1
					AND lis.IsAccounting = 1
					AND lis.IsNonAccrual = 1
				THEN lis.FinanceResidualIncome_Amount
				ELSE 0.00
			END) [FinancingRecognizedSuspendedResidualIncome_Table]
	INTO #LeaseIncomeSchInfo
	FROM #EligibleContracts ec
		INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
		INNER JOIN LeaseIncomeSchedules lis ON lis.LeaseFinanceId = lf.Id	
		LEFT JOIN #ChargeOffDetails cod ON cod.ContractId = ec.ContractId
		LEFT JOIN #AccrualDetails ad ON ad.ContractId = ec.ContractId
		LEFT JOIN #RenewalDetails rd ON rd.ContractId = ec.ContractId
	WHERE lis.IncomeType = 'FixedTerm'
		AND lis.IsLessorOwned = 1
	GROUP BY ec.ContractId;
	
	CREATE NONCLUSTERED INDEX IX_Id ON #LeaseIncomeSchInfo(ContractId);

	UPDATE lisi
		SET lisi.RentalIncome_Table = ISNULL(lisi.RentalIncome_Table,0.00) + ISNULL(bii.ReAccrualRentalIncome_BI,0.00) + ISNULL(bisi.ReAccrualRentalIncome_BIS,0.00)
		,lisi.DeferredRentalIncome_Table = ISNULL(lisi.DeferredRentalIncome_Table,0.00) + ISNULL(bii.ReAccrualRentalIncome_BI,0.00) + ISNULL(bisi.ReAccrualDeferredRentalIncome_BIS,0.00)
		,lisi.FinancingTotalIncome_Accounting_Table = ISNULL(lisi.FinancingTotalIncome_Accounting_Table,0.00) + ISNULL(bii.ReAccrualFinanceIncome_BI,0.00) + ISNULL(bii.ReAccrualFinanceResidualIncome_BI,0.00) + ISNULL(bisi.ReAccrualFinanceIncome_BIS,0.00) + ISNULL(bisi.ReAccrualFinanceResidualIncome_BIS,0.00)
		,lisi.FinancingTotalEarnedIncome_Table = ISNULL(lisi.FinancingTotalEarnedIncome_Table,0.00) + ISNULL(bii.ReAccrualFinanceIncome_BI,0.00) + ISNULL(bii.ReAccrualFinanceResidualIncome_BI,0.00) + ISNULL(bisi.ReAccrualFinanceEarnedIncome_BIS,0.00) + ISNULL(bisi.ReAccrualFinanceEarnedResidualIncome_BIS,0.00)
		,lisi.FinancingEarnedIncome_Table = ISNULL(lisi.FinancingEarnedIncome_Table,0.00) + ISNULL(bii.ReAccrualFinanceIncome_BI,0.00) + ISNULL(bisi.ReAccrualFinanceEarnedIncome_BIS,0.00)
		,lisi.FinancingEarnedResidualIncome_Table = ISNULL(lisi.FinancingEarnedResidualIncome_Table,0.00) + ISNULL(bii.ReAccrualFinanceResidualIncome_BI,0.00) + ISNULL(bisi.ReAccrualFinanceEarnedResidualIncome_BIS,0.00)
		,lisi.FinancingTotalUnearnedIncome_Table = ISNULL(lisi.FinancingTotalUnearnedIncome_Table,0.00) + ISNULL(bisi.ReAccrualFinanceUnEarnedIncome_BIS,0.00) + ISNULL(bisi.ReAccrualFinanceUnEarnedResidualIncome_BIS,0.00)
		,lisi.FinancingUnearnedIncome_Table = ISNULL(lisi.FinancingUnearnedIncome_Table,0.00) + ISNULL(bisi.ReAccrualFinanceUnEarnedIncome_BIS,0.00)
		,lisi.FinancingUnearnedResidualIncome_Table = ISNULL(lisi.FinancingUnearnedResidualIncome_Table,0.00) + ISNULL(bisi.ReAccrualFinanceUnEarnedResidualIncome_BIS,0.00)
	FROM #EligibleContracts ec
		LEFT JOIN #LeaseIncomeSchInfo lisi ON lisi.ContractId = ec.ContractId
		LEFT JOIN #BlendedItemInfo bii ON bii.ContractId = ec.ContractId
		LEFT JOIN #BlendedIncomeSchInfo bisi ON bisi.ContractId = ec.ContractId;

	SELECT
		DISTINCT ec.ContractId
	INTO #PayOffDetails
	FROM #EligibleContracts ec
		INNER JOIN LeaseFinances lf ON ec.ContractId = lf.ContractId
		INNER JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
		INNER JOIN Payoffs p ON lf.Id = p.LeaseFinanceId
			AND p.Status = 'Activated';

	CREATE NONCLUSTERED INDEX IX_Id ON #PayOffDetails(ContractId);

	SELECT
		ec.ContractId
		,MAX(avh.IncomeDate) [FixedTermClearedTillIncomeDate]
	INTO #ClearedFixedTermAVHIncomeDate
	FROM #EligibleContracts ec
		INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
		LEFT JOIN LeaseAmendments la ON lf.Id = la.CurrentLeaseFinanceId AND la.AmendmentType = 'NBVImpairment'
		LEFT JOIN #ChargeOffDetails cod ON ec.ContractId = cod.ContractId
		INNER JOIN AssetValueHistories avh ON (avh.SourceModuleId = lf.Id 
			OR avh.SourceModuleId = la.Id OR avh.SourceModuleId = cod.ChargeOffId)
	WHERE (avh.SourceModule = 'FixedTermDepreciation' AND avh.IsCleared = 1) 
		OR (avh.SourceModule = 'NBVImpairments' AND avh.IsCleared = 1 AND la.Id IS NOT NULL)
		OR (avh.SourceModule = 'ChargeOff' AND avh.IsCleared = 1 AND cod.ChargeOffId IS NOT NULL)
	GROUP BY ec.ContractId;
	
	CREATE NONCLUSTERED INDEX IX_Id ON #ClearedFixedTermAVHIncomeDate(ContractId);

	SELECT
		cod.ContractId
		,MAX(avh.IncomeDate) [FixedTermClearedTillIncomeDateCO]
	INTO #ClearedFixedTermAVHIncomeDateCO
	FROM #ChargeOffDetails cod
		INNER JOIN AssetValueHistories avh ON avh.SourceModuleId = cod.ChargeOffId
	WHERE avh.SourceModule = 'ChargeOff'
		AND avh.IsCleared = 1
	GROUP BY cod.ContractId;

	CREATE NONCLUSTERED INDEX IX_Id ON #ClearedFixedTermAVHIncomeDateCO(ContractId);

	SELECT
		DISTINCT ec.ContractId
		,a.Id AS AssetId
	INTO #SyndicationAVHInfo
	FROM #EligibleContracts ec
		INNER JOIN LeaseAssets la ON la.LeaseFinanceId = ec.LeaseFinanceId
		INNER JOIN Assets a ON la.AssetId = a.Id
		INNER JOIN AssetValueHistories avh ON a.Id = avh.AssetId
	WHERE avh.SourceModule = 'Syndications'
	GROUP BY ec.ContractId,a.Id;

	CREATE NONCLUSTERED INDEX IX_Id ON #SyndicationAVHInfo(ContractId);

	SELECT
		ec.ContractId
		,SUM(
			CASE
				WHEN (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL))
					AND avh.GLJournalId IS NOT NULL 
					AND avh.ReversalGLJournalId IS NULL
					AND (rd.ContractId IS NULL OR (rd.ContractId IS NOT NULL AND avh.SourceModuleId >= rd.RenewalFinanceId))
				THEN avh.Value_Amount
				ELSE 0.00
			END) [DepreciationAmount_Table]
		,ABS(SUM(
				CASE
					WHEN (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL))
						AND avh.GLJournalId IS NOT NULL
						AND (rd.ContractId IS NULL OR (rd.ContractId IS NOT NULL AND avh.SourceModuleId >= rd.RenewalFinanceId))
					THEN avh.Value_Amount
					ELSE 0.00
				END))
		- ABS(SUM(
				CASE
					WHEN (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL))
						AND avh.GLJournalId IS NOT NULL
						AND avh.ReversalGLJournalId IS NOT NULL
						AND (rd.ContractId IS NULL OR (rd.ContractId IS NOT NULL AND avh.SourceModuleId >= rd.RenewalFinanceId))
					THEN avh.Value_Amount
					ELSE 0.00
				END))
		- ABS(SUM(
				CASE
					WHEN ec.SyndicationType IN ('ParticipatedSale','FullSale')
						AND ((pod.ContractId IS NULL AND la.IsActive = 1 AND avh.IncomeDate <= DATEADD(Day,-1,ec.SyndicationDate))
							OR (pod.ContractId IS NOT NULL
								AND (la.IsActive = 1 AND avh.IncomeDate <= DATEADD(Day,-1,ec.SyndicationDate))
									OR (la.TerminationDate < DATEADD(Day,-1,ec.SyndicationDate) 
										AND avh.IncomeDate <= DATEADD(Day,-1,ec.SyndicationDate) AND savh.AssetId IS NOT NULL)
									OR (la.TerminationDate > DATEADD(Day,-1,ec.SyndicationDate) 
										AND avh.IncomeDate <= DATEADD(Day,-1,ec.SyndicationDate) AND savh.AssetId IS NOT NULL)
									OR (la.TerminationDate = DATEADD(Day,-1,ec.SyndicationDate) 
										AND avh.IncomeDate <= DATEADD(Day,-1,ec.SyndicationDate) AND savh.AssetId IS NOT NULL)))
						AND (rd.ContractId IS NULL OR (rd.ContractId IS NOT NULL AND avh.SourceModuleId >= rd.RenewalFinanceId))
					THEN (avh.Value_Amount) * ROUND((1-ec.RetainedPercentage/100),2)
					ELSE 0.00
				END))
		- ABS(SUM(
				CASE
					WHEN pod.ContractId IS NOT NULL
						AND otpr.ContractId IS NULL
						AND la.TerminationDate <= ec.MaturityDate
						AND (rd.ContractId IS NULL OR (rd.ContractId IS NOT NULL AND avh.SourceModuleId >= rd.RenewalFinanceId))
						AND (ec.SyndicationType NOT IN ('FullSale','ParticipatedSale') 
							OR (ec.SyndicationType IN ('FullSale','ParticipatedSale')
								AND ((la.TerminationDate < DATEADD(Day,-1,ec.SyndicationDate) AND avh.IncomeDate <= la.TerminationDate
										AND savh.AssetId IS NULL)
									OR (la.TerminationDate > DATEADD(Day,-1,ec.SyndicationDate) AND savh.AssetId IS NOT NULL
										AND avh.IncomeDate > DATEADD(Day,-1,ec.SyndicationDate) AND avh.IncomeDate <= la.TerminationDate)
									OR (la.TerminationDate > DATEADD(Day,-1,ec.SyndicationDate) AND avh.IncomeDate <= la.TerminationDate 
										AND savh.AssetId IS NULL)
									OR (la.TerminationDate = DATEADD(Day,-1,ec.SyndicationDate) AND avh.IncomeDate <= la.TerminationDate
										AND savh.AssetId IS NULL))))
					THEN avh.Value_Amount
					ELSE 0.00
				END))
		- ABS(SUM(
				CASE
					WHEN pod.ContractId IS NOT NULL
						AND otpr.ContractId IS NULL
						AND la.TerminationDate <= ec.MaturityDate
						AND (rd.ContractId IS NULL OR (rd.ContractId IS NOT NULL AND avh.SourceModuleId >= rd.RenewalFinanceId))
						AND ec.SyndicationType IN ('ParticipatedSale') 
						AND la.TerminationDate > DATEADD(Day,-1,ec.SyndicationDate) 
						AND savh.AssetId IS NOT NULL
						AND avh.IncomeDate <= DATEADD(Day,-1,ec.SyndicationDate)
					THEN (avh.Value_Amount) * ROUND((ec.RetainedPercentage/100),2)
					ELSE 0.00
				END)) [AccumulatedDepreciationAmount_Table]
	INTO #FixedTermAssetValueHistoriesInfo
	FROM #EligibleContracts ec
		INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
		INNER JOIN AssetValueHistories avh ON avh.SourceModuleId = lf.Id	
		INNER JOIN LeaseAssets la ON la.AssetId = avh.AssetId
			AND la.LeaseFinanceId = ec.LeaseFinanceId
		LEFT JOIN #ClearedFixedTermAVHIncomeDate cfi ON cfi.ContractId = ec.ContractId
		LEFT JOIN #PayOffDetails pod ON pod.ContractId = ec.ContractId
		LEFT JOIN #OTPReclass otpr ON otpr.ContractId = ec.ContractId
		LEFT JOIN #FullPaidOffContracts fpoc ON fpoc.ContractId = ec.ContractId
		LEFT JOIN #RenewalDetails rd ON rd.ContractId = ec.ContractId
		LEFT JOIN #SyndicationAVHInfo savh ON savh.ContractId = ec.ContractId
			AND savh.AssetId = la.AssetId
	WHERE avh.IsAccounted = 1
		AND avh.SourceModule = 'FixedTermDepreciation'
	GROUP BY ec.ContractId;

	CREATE NONCLUSTERED INDEX IX_Id ON #FixedTermAssetValueHistoriesInfo(ContractId);

	UPDATE ftavh
		SET ftavh.AccumulatedDepreciationAmount_Table = 0.00
	FROM #FixedTermAssetValueHistoriesInfo ftavh
		LEFT JOIN #OTPReclass otpr ON ftavh.ContractId = otpr.ContractId
		LEFT JOIN #ClearedFixedTermAVHIncomeDateCO cfico ON ftavh.ContractId = cfico.ContractId
	WHERE (otpr.ContractId IS NOT NULL)
		OR (cfico.ContractId IS NOT NULL);

	SELECT
		ec.ContractId
		,SUM(
			CASE
				WHEN (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL))
					AND (rd.ContractId IS NULL OR (rd.ContractId IS NOT NULL AND lam.CurrentLeaseFinanceId > rd.RenewalFinanceId))
				THEN avh.Value_Amount
				ELSE 0.00
			END) [NBVImpairment_Table]
		,SUM(
			CASE
				WHEN (la.IsActive = 1 
					OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL AND avh.IncomeDate > cfi.FixedTermClearedTillIncomeDate))
					AND (rd.ContractId IS NULL OR (rd.ContractId IS NOT NULL AND lam.CurrentLeaseFinanceId > rd.RenewalFinanceId))
				THEN avh.Value_Amount
				ELSE 0.00
			END) [AccumulatedNBVImpairment_Table]
	INTO #NBVAssetValueHistoriesInfo
	FROM #EligibleContracts ec
		INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
		INNER JOIN LeaseAmendments lam ON lam.CurrentLeaseFinanceId = lf.Id
		INNER JOIN AssetValueHistories avh ON avh.SourceModuleId = lam.Id
		INNER JOIN LeaseAssets la ON la.AssetId = avh.AssetId
			AND la.LeaseFinanceId = ec.LeaseFinanceId
		LEFT JOIN #ClearedFixedTermAVHIncomeDate cfi ON cfi.ContractId = ec.ContractId
		LEFT JOIN #RenewalDetails rd ON rd.ContractId = ec.ContractId
	WHERE avh.IsAccounted = 1
		AND avh.SourceModule = 'NBVImpairments'
		AND avh.GLJournalId IS NOT NULL
		AND avh.ReversalGLJournalId IS NULL
	GROUP BY ec.ContractId;

	CREATE NONCLUSTERED INDEX IX_Id ON #NBVAssetValueHistoriesInfo(ContractId);
	
	UPDATE nbvavh
		SET nbvavh.AccumulatedNBVImpairment_Table = 0.00
	FROM #NBVAssetValueHistoriesInfo nbvavh
		INNER JOIN #ChargeOffDetails cod ON nbvavh.ContractId = cod.ContractId
	WHERE cod.ContractId IS NOT NULL;

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
		   , SUM(CASE
					 WHEN co.IsRecovery = 1
					 THEN 1
					 ELSE 0
				 END) [ChargeOffRecovered]
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
		, SUM(CASE
			      WHEN co.IsRecovery = 1
				  THEN 1
				  ELSE 0
		      END) [ChargeOffRecovered]
	FROM #EligibleContracts ec
		 INNER JOIN ChargeOffs co ON co.ContractId = ec.ContractId
	WHERE co.IsActive = 1
		  AND co.Status = 'Approved'
		  AND co.PostDate IS NOT NULL
	GROUP BY ec.ContractId;

	MERGE #SumOfReceiptApplicationReceivableDetails sorard
	USING
		(SELECT 
			r.EntityId AS ContractId
			,SUM(ISNULL(r.GainAmount_LC, 0.00)) AS OtherGainAmount_LC_Table
			,SUM(ISNULL(r.GainAmount_NLC, 0.00)) AS OtherGainAmount_NLC_Table
		FROM #ReceiptApplicationReceivableDetails r
			  LEFT JOIN #ChargeOffDetails cod ON cod.ContractId = r.EntityId
		WHERE r.ReceiptStatus IN ('Completed','Posted')
			  AND r.ReceivableType NOT IN ('OperatingLeaseRental') 
		GROUP BY r.EntityId) sr
	ON (sr.ContractId = sorard.ContractId)
	WHEN MATCHED
	THEN UPDATE
		SET ChargeOffGainOnRecovery_LeaseComponent_Table += sr.OtherGainAmount_LC_Table + OtherGainAmount_NLC_Table
	WHEN NOT MATCHED
		THEN
			INSERT(ContractId,TotalPaidReceivables_LeaseComponent_Table, TotalPaidReceivablesviaCash_LeaseComponent_Table, TotalPaidReceivablesviaNonCash_LeaseComponent_Table,
				   TotalPaidReceivables_FinanceComponent_Table, TotalPaidReceivablesviaCash_FinanceComponent_Table, TotalPaidReceivablesviaNonCash_FinanceComponent_Table,
				   Recovery_LeaseComponent_Table, Recovery_FinanceComponent_Table, GLPostedPreChargeOff_LeaseComponent_Table, GLPostedPreChargeOff_FinanceComponent_Table, ChargeOffGainOnRecovery_LeaseComponent_Table, ChargeOffGainOnRecovery_NonLeaseComponent_Table)
			VALUES(sr.ContractId, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, sr.OtherGainAmount_LC_Table + OtherGainAmount_NLC_Table, 0);

	UPDATE sord SET ChargeOffGainOnRecovery_LeaseComponent_Table += ChargeOffGainOnRecovery_NonLeaseComponent_Table
				  , ChargeOffGainOnRecovery_NonLeaseComponent_Table = 0.00
	FROM #SumOfReceiptApplicationReceivableDetails sord
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
	
	/*SalesTax*/	
	SELECT 
		r.Id
		,r.EntityID
		,r.DueDate
		,r.IsGLPosted
	INTO #ReceivableForTaxes
	FROM #EligibleContracts ec
		INNER JOIN Receivables r ON ec.ContractId = r.EntityID
			AND r.IsActive = 1
			AND r.FunderID IS NULL
			AND r.EntityType LIKE 'CT';
							
	CREATE NONCLUSTERED INDEX IX_Id ON #ReceivableForTaxes(EntityID);

	SELECT 
		ec.ContractId
		,SUM(
			CASE
				WHEN rt.IsGLPosted = 1
				THEN rt.Amount_Amount
				ELSE 0.00
			END) GLPostedTaxes
		,SUM(
			CASE
				WHEN rt.IsGLPosted = 1
				THEN rt.Balance_Amount
				ELSE 0.00
			END) OutStandingTaxes
	INTO #ReceivableTaxDetails
	FROM #EligibleContracts ec
	INNER JOIN #ReceivableForTaxes r ON ec.Contractid = r.EntityID
	INNER JOIN ReceivableTaxes rt ON rt.ReceivableId = r.Id 
		AND rt.IsActive = 1
	GROUP BY ec.ContractId;

	CREATE NONCLUSTERED INDEX IX_Id ON #ReceivableTaxDetails(ContractId);

	IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ReceivableTaxes' AND COLUMN_NAME = 'IsCashBased')
	BEGIN
	SET @SQL =
		'SELECT 
			#EligibleContracts.ContractId
			,SUM(CASE 
					WHEN ReceivableTaxes.IsCashBased = 1
						AND Receipt.ReceiptClassification = ''NonCash''
					THEN ReceiptApplicationReceivableDetails.TaxApplied_Amount
					ELSE 0.00
				END) GLPosted_CashRem_NonCash
			,SUM(ReceiptApplicationReceivableDetails.TaxApplied_Amount) TotalPaid_taxes
			,SUM(CASE 
					WHEN ReceivableTaxes.IsCashBased = 1
						AND Receipt.ReceiptClassification = ''NonCash''
					THEN ReceiptApplicationReceivableDetails.TaxApplied_Amount
					ELSE 0.00
				END) Paid_CashRem_NonCash
			,SUM(CASE
					WHEN ReceivableTaxes.IsGLPosted = 0
					THEN ReceiptApplicationReceivableDetails.TaxApplied_Amount
					ELSE 0.00
				END) TotalPrePaid_Taxes
			,SUM(CASE
					WHEN Receipt.ReceiptClassification = ''Cash''
						AND ReceiptTypes.ReceiptTypeName NOT IN (''PayableOffset'',''SecurityDeposit'',''EscrowRefund'')
					THEN ReceiptApplicationReceivableDetails.TaxApplied_Amount
					ELSE 0.00
				END) PaidTaxesviaCash
			,SUM(CASE
					WHEN Receipt.ReceiptClassification NOT IN (''Cash'')
						OR ReceiptTypes.ReceiptTypeName IN (''PayableOffset'',''SecurityDeposit'',''EscrowRefund'')
					THEN ReceiptApplicationReceivableDetails.TaxApplied_Amount
					ELSE 0.00
				END) PaidTaxesviaNonCash
		FROM #EligibleContracts
		INNER JOIN #ReceivableForTaxes Receivables ON #EligibleContracts.Contractid = Receivables.EntityID
		INNER JOIN ReceivableTaxes ON ReceivableTaxes.ReceivableId = Receivables.Id and ReceivableTaxes.IsActive = 1
		INNER JOIN ReceivableDetails ON ReceivableDetails.ReceivableId = ReceivableTaxes.ReceivableId and ReceivableDetails.IsActive = 1
		INNER JOIN ReceiptApplicationReceivableDetails ON ReceiptApplicationReceivableDetails.ReceivableDetailId = ReceivableDetails.Id
		INNER JOIN ReceiptApplications ON ReceiptApplicationReceivableDetails.ReceiptApplicationId = ReceiptApplications.Id
		INNER JOIN Receipts Receipt ON ReceiptApplications.ReceiptId = Receipt.Id 
			AND Receipt.Status in (''Completed'',''Posted'')
		INNER JOIN ReceiptTypes ON ReceiptTypes.Id = Receipt.Typeid
		WHERE ReceiptApplicationReceivableDetails.IsActive=1 
		GROUP BY #EligibleContracts.ContractId'
	
		INSERT INTO #SalesTaxDetails
		EXEC (@Sql)
	END

	IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ReceivableTaxes' AND COLUMN_NAME = 'IsCashBased')
	BEGIN
	INSERT INTO #SalesTaxDetails
	SELECT 
		#EligibleContracts.ContractId
		,0 AS GLPosted_CashRem_NonCash
		,SUM(ReceiptApplicationReceivableDetails.TaxApplied_Amount) TotalPaid_taxes
		,0 AS Paid_CashRem_NonCash
		,SUM(CASE
				WHEN ReceivableTaxes.IsGLPosted = 0
				THEN ReceiptApplicationReceivableDetails.TaxApplied_Amount
				ELSE 0.00
			END) TotalPrePaid_Taxes
		,SUM(CASE
				WHEN Receipt.ReceiptClassification = 'Cash'
					AND ReceiptTypes.ReceiptTypeName NOT IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund')
				THEN ReceiptApplicationReceivableDetails.TaxApplied_Amount
				ELSE 0.00
			END) PaidTaxesviaCash
		,SUM(CASE
				WHEN Receipt.ReceiptClassification NOT IN ('Cash')
					OR ReceiptTypes.ReceiptTypeName IN ('PayableOffset', 'SecurityDeposit', 'EscrowRefund')
				THEN ReceiptApplicationReceivableDetails.TaxApplied_Amount
				ELSE 0.00
			END) PaidTaxesviaNonCash
	FROM #EligibleContracts
	INNER JOIN #ReceivableForTaxes Receivables ON #EligibleContracts.Contractid = Receivables.EntityID
	INNER JOIN ReceivableTaxes ON ReceivableTaxes.ReceivableId = Receivables.Id and ReceivableTaxes.IsActive = 1
	INNER JOIN ReceivableDetails ON ReceivableDetails.ReceivableId = ReceivableTaxes.ReceivableId and ReceivableDetails.IsActive = 1
	INNER JOIN ReceiptApplicationReceivableDetails ON ReceiptApplicationReceivableDetails.ReceivableDetailId = ReceivableDetails.Id
	INNER JOIN ReceiptApplications ON ReceiptApplicationReceivableDetails.ReceiptApplicationId = ReceiptApplications.Id
	INNER JOIN Receipts Receipt ON ReceiptApplications.ReceiptId = Receipt.Id
		AND Receipt.Status in ('Completed','Posted')
	INNER JOIN ReceiptTypes ON ReceiptTypes.Id = Receipt.Typeid
	WHERE ReceiptApplicationReceivableDetails.IsActive=1 
	GROUP BY #EligibleContracts.ContractId;
	
	END

	CREATE NONCLUSTERED INDEX IX_Id ON #SalesTaxDetails(ContractId);

	/*Capitalized*/
	IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'LeaseAssets' AND COLUMN_NAME = 'CapitalizedAdditionalCharge_Amount')
	BEGIN
	SET @Sql = 
		'SELECT 
		#EligibleContracts.ContractId
		,SUM(CASE
				WHEN la.IsAdditionalChargeSoftAsset = 1
				THEN la.NBV_Amount
				ELSE la.CapitalizedAdditionalCharge_Amount
		END) CapitalizedAdditionalCharge
		,SUM(CASE 
				WHEN lfd.CreateSoftAssetsForCappedSalesTax = 1 
				THEN la.OriginalCapitalizedAmount_Amount
				ELSE la.CapitalizedSalesTax_Amount
		END) CapitalizedSalesTax
		,SUM(CASE 
				WHEN lfd.CreateSoftAssetsForInterimInterest = 1
				THEN la.OriginalCapitalizedAmount_Amount
				ELSE la.CapitalizedInterimInterest_Amount
		END) CapitalizedInterimInterest
		,SUM(CASE
				WHEN lfd.CreateSoftAssetsForInterimRent = 1
				THEN la.OriginalCapitalizedAmount_Amount
				ELSE la.CapitalizedInterimRent_Amount
		END) CapitalizedInterimRent
		,SUM(CASE
				WHEN la.CapitalizationType = ''CapitalizedProgressPayment''
				THEN la.OriginalCapitalizedAmount_Amount
				ELSE 0.00
		 END) CapitalizedProgressPayment
		FROM #EligibleContracts
			INNER JOIN LeaseFinanceDetails lfd ON lfd.Id = #EligibleContracts.LeaseFinanceId
			INNER JOIN LeaseAssets la ON la.LeaseFinanceId = #EligibleContracts.LeaseFinanceId
				AND (la.IsActive = 1 
					OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= #EligibleContracts.CommencementDate))
		GROUP BY #EligibleContracts.ContractId;'
	
	INSERT INTO #CapitalizedDetails
	EXEC (@Sql)
	END
	
	IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'LeaseAssets' AND COLUMN_NAME =	'CapitalizedAdditionalCharge_Amount')
	BEGIN
	INSERT INTO #CapitalizedDetails
	SELECT
		#EligibleContracts.ContractId
		,0 CapitalizedAdditionalCharge
		,SUM(CASE 
				WHEN lfd.CreateSoftAssetsForCappedSalesTax = 1 
				THEN la.OriginalCapitalizedAmount_Amount
				ELSE la.CapitalizedSalesTax_Amount
		END) CapitalizedSalesTax
		,SUM(CASE 
				WHEN lfd.CreateSoftAssetsForInterimInterest = 1
				THEN la.OriginalCapitalizedAmount_Amount
				ELSE la.CapitalizedInterimInterest_Amount
		END) CapitalizedInterimInterest
		,SUM(CASE
				WHEN lfd.CreateSoftAssetsForInterimRent = 1
				THEN la.OriginalCapitalizedAmount_Amount
				ELSE la.CapitalizedInterimRent_Amount
		END) CapitalizedInterimRent
		,SUM(CASE
				WHEN la.CapitalizationType = 'CapitalizedProgressPayment'
				THEN la.OriginalCapitalizedAmount_Amount
				ELSE 0.00
		 END) CapitalizedProgressPayment
	FROM #EligibleContracts
		INNER JOIN LeaseFinanceDetails lfd ON lfd.Id = #EligibleContracts.LeaseFinanceId
		INNER JOIN LeaseAssets la ON la.LeaseFinanceId = #EligibleContracts.LeaseFinanceId
			AND (la.IsActive = 1 
				OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= #EligibleContracts.CommencementDate))
	GROUP BY #EligibleContracts.ContractId;
	END
	
	CREATE NONCLUSTERED INDEX IX_Id ON #CapitalizedDetails(ContractId);
	
	UPDATE cd
		SET cd.CapitalizedInterimInterest = cd.CapitalizedInterimInterest + cd.CapitalizedProgressPayment
	FROM #CapitalizedDetails cd;

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
			LEFT JOIN #ChargeOffDetails cod ON cod.ContractId = ec.ContractId
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
		LEFT JOIN #ChargeOffDetails cod ON cod.ContractId = ec.ContractId
	WHERE rt.name = 'LeaseFloatRateAdj'
		AND r.IsActive = 1
		AND r.FunderId IS NULL
		AND rd.IsActive = 1
		AND r.EntityType = 'CT'
		AND ec.IsFloatRateLease = 1
	GROUP BY ec.ContractId;
	END

	CREATE NONCLUSTERED INDEX IX_Id ON #FloatRateReceivableDetails(ContractId);

	INSERT INTO #FloatRateReceiptDetails
	SELECT ec.ContractId
			, SUM(CASE
					WHEN r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount = 0.00 AND RecoveryAmount_Amount = 0.00
						AND (r.StartDate < co.ChargeOffDate OR co.ChargeOffDate IS NULL)
						AND ((nc.DoubtfulCollectability IS NOT NULL AND (nc.DoubtfulCollectability = 0 OR r.GLTransactionType NOT IN ('FloatRateAR'))) OR nc.DoubtfulCollectability IS NULL) 
					THEN r.AmountApplied_Amount
					WHEN r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount = 0.00 AND RecoveryAmount_Amount = 0.00
						 AND nc.DoubtfulCollectability IS NOT NULL AND nc.DoubtfulCollectability = 1 AND r.GLTransactionType IN ('FloatRateAR')
					THEN r.AmountApplied_Amount
					ELSE 0.00
				END) [TotalPaid]
			, SUM(CASE
					WHEN r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00 AND RecoveryAmount_Amount = 0.00
						AND (r.StartDate < co.ChargeOffDate OR co.ChargeOffDate IS NULL)
						AND ((nc.DoubtfulCollectability IS NOT NULL AND (nc.DoubtfulCollectability = 0 OR r.GLTransactionType NOT IN ('FloatRateAR'))) OR nc.DoubtfulCollectability IS NULL) 
					THEN r.LeaseComponentAmountApplied_Amount
					WHEN r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00 AND RecoveryAmount_Amount = 0.00
						AND nc.DoubtfulCollectability IS NOT NULL AND nc.DoubtfulCollectability = 1 AND r.GLTransactionType IN ('FloatRateAR')
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
						AND ((nc.DoubtfulCollectability IS NOT NULL AND (nc.DoubtfulCollectability = 0 OR r.GLTransactionType NOT IN ('FloatRateAR'))) OR nc.DoubtfulCollectability IS NULL) 
					THEN AmountApplied_Amount
					WHEN ReceiptClassification = 'Cash' AND ReceiptTypeName NOT IN('PayableOffset', 'SecurityDeposit', 'EscrowRefund')
						AND r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount = 0.00 AND RecoveryAmount_Amount = 0.00
						AND nc.DoubtfulCollectability IS NOT NULL AND nc.DoubtfulCollectability = 1 AND r.GLTransactionType IN ('FloatRateAR')
					THEN AmountApplied_Amount
					ELSE 0.00
				END) [TotalCashPaidAmount]
			, SUM(CASE
					WHEN ReceiptClassification = 'Cash' AND ReceiptTypeName NOT IN('PayableOffset', 'SecurityDeposit', 'EscrowRefund')
						AND r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00 AND RecoveryAmount_Amount = 0.00
						AND (r.StartDate < co.ChargeOffDate OR co.ChargeOffDate IS NULL)
						AND ((nc.DoubtfulCollectability IS NOT NULL AND (nc.DoubtfulCollectability = 0 OR r.GLTransactionType NOT IN ('FloatRateAR'))) OR nc.DoubtfulCollectability IS NULL) 
					THEN LeaseComponentAmountApplied_Amount
					WHEN ReceiptClassification = 'Cash' AND ReceiptTypeName NOT IN('PayableOffset', 'SecurityDeposit', 'EscrowRefund')
						AND r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00 AND RecoveryAmount_Amount = 0.00
						AND nc.DoubtfulCollectability IS NOT NULL AND nc.DoubtfulCollectability = 1 AND r.GLTransactionType IN ('FloatRateAR')
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
						AND ((nc.DoubtfulCollectability IS NOT NULL AND (nc.DoubtfulCollectability = 0 OR r.GLTransactionType NOT IN ('FloatRateAR'))) OR nc.DoubtfulCollectability IS NULL) 
					THEN AmountApplied_Amount
					WHEN(ReceiptClassification != 'Cash' OR ReceiptTypeName NOT IN('PayableOffset', 'SecurityDeposit', 'EscrowRefund'))
						AND r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount = 0.00 AND RecoveryAmount_Amount = 0.00
						AND nc.DoubtfulCollectability IS NOT NULL AND nc.DoubtfulCollectability = 1 AND r.GLTransactionType IN ('FloatRateAR')
					THEN AmountApplied_Amount
					ELSE 0.00
				END) [TotalNonCashPaidAmount]
			, SUM(CASE
					WHEN(ReceiptClassification != 'Cash' OR ReceiptTypeName IN('PayableOffset', 'SecurityDeposit', 'EscrowRefund'))
						AND r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00 AND RecoveryAmount_Amount = 0.00
						AND (r.StartDate < co.ChargeOffDate OR co.ChargeOffDate IS NULL)
						AND ((nc.DoubtfulCollectability IS NOT NULL AND (nc.DoubtfulCollectability = 0 OR r.GLTransactionType NOT IN ('FloatRateAR'))) OR nc.DoubtfulCollectability IS NULL) 
					THEN LeaseComponentAmountApplied_Amount
					WHEN(ReceiptClassification != 'Cash' OR ReceiptTypeName IN('PayableOffset', 'SecurityDeposit', 'EscrowRefund'))
						AND r.GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00 AND RecoveryAmount_Amount = 0.00
						AND nc.DoubtfulCollectability IS NOT NULL AND nc.DoubtfulCollectability = 1 AND r.GLTransactionType IN ('FloatRateAR')
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
						AND ((nc.DoubtfulCollectability IS NOT NULL AND (nc.DoubtfulCollectability = 0 OR r.GLTransactionType NOT IN ('FloatRateAR'))) OR nc.DoubtfulCollectability IS NULL)
					THEN LeaseComponentAmountApplied_Amount
					WHEN(RecoveryAmount_Amount = 0.00 AND GainAmount_Amount = 0.00 AND r.ChargeoffExpenseAmount_LC = 0.00)
						AND nc.DoubtfulCollectability IS NOT NULL AND nc.DoubtfulCollectability = 1 AND r.GLTransactionType IN ('FloatRateAR')
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
			LEFT JOIN #ChargeOffDetails co ON r.EntityId = co.ContractId
			LEFT JOIN #NonAccrualDetails nc ON nc.ContractId = r.EntityId
	WHERE r.ReceiptStatus IN('Completed', 'Posted')
			AND r.ReceivableType = 'LeaseFloatRateAdj'
			AND r.ReceiptStatus IN('Completed', 'Posted')
	AND ec.IsFloatRateLease = 1
	GROUP BY ec.ContractId;

	CREATE NONCLUSTERED INDEX IX_Id ON #FloatRateReceiptDetails(ContractId);

	UPDATE rd 
		SET LeaseComponentAmount += receipt.GLPosted_PreChargeoff_LeaseComponent_Table
			,NonLeaseComponentAmount += receipt.GlPosted_PreChargeoff_NonLeaseComponent_Table
			,TotalAmount = receipt.GLPosted_PreChargeoff_LeaseComponent_Table + receipt.GlPosted_PreChargeoff_NonLeaseComponent_Table
	FROM #FloatRateReceivableDetails rd
		INNER JOIN #FloatRateReceiptDetails receipt ON rd.ContractId = receipt.ContractId
		INNER JOIN #ChargeOffDetails cod ON cod.ContractId = rd.ContractId;


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
					AND income.ModificationType != 'ChargeOff'
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
		LEFT JOIN #ChargeOffDetails cod ON cod.ContractId = ec.ContractId
		LEFT JOIN #AccrualDetails ad ON ad.ContractId = ec.ContractId
	WHERE (income.IsAccounting = 1
		OR income.IsScheduled = 1)
		AND ec.IsFloatRateLease = 1
		AND income.IsLessorOwned = 1
	GROUP BY ec.ContractId;
	
	CREATE NONCLUSTERED INDEX IX_Id ON #FloatRateIncomeDetails(ContractId);

	/*FunderOwned*/
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
		LEFT JOIN #ChargeOffDetails cod ON cod.ContractId = r.ContractId
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
		LEFT JOIN #ChargeOffDetails cod ON cod.ContractId = r.ContractId
		LEFT JOIN #RemitOnlyContracts roc ON roc.ContractId = r.ContractId
	WHERE rp.Status IN ('Posted','Completed')
		AND rd.IsActive = 1
		AND rard.IsActive = 1
		AND rpt.IsActive = 1
		AND r.FunderId IS NOT NULL
	GROUP BY r.ContractId;

	--#GLLogic
	SELECT 
		DISTINCT rd.ContractId
		,gld.GLJournalId AS RenewalGLJournalId
	INTO #RenewalGLJournals
	FROM #RenewalDetails rd
		INNER JOIN GLJournalDetails gld ON gld.EntityId = rd.ContractId	AND gld.EntityType = 'Contract'
		INNER JOIN GLTemplateDetails gltd ON gltd.Id = gld.GLTemplateDetailId
		INNER JOIN GLEntryItems gle ON gle.Id = gltd.EntryItemId
		INNER JOIN GLTransactionTypes gltt ON gle.GLTransactionTypeId = gltt.Id
		LEFT JOIN GLTemplateDetails mgltd ON mgltd.Id = gld.MatchingGLTemplateDetailId
		LEFT JOIN GLEntryItems mgle ON mgle.Id = mgltd.EntryItemId
		LEFT JOIN GLTransactionTypes mgltt ON mgle.GLTransactionTypeId = mgltt.Id
	WHERE gltt.Name = 'OperatingLeasePayoff'
		AND gld.SourceId = rd.RenewalFinanceId;
	
	CREATE NONCLUSTERED INDEX IX_Id ON #RenewalGLJournals(ContractId);

	SELECT 
		t.ContractId AS ContractId
		,SUM(t.GLPostedLeaseReceivable_Debit - t.GLPostedLeaseReceivable_Credit) [GLPostedReceivables_LeaseComponent_GL]
		,SUM(t.GLPostedFinancingReceivable_Debit - t.GLPostedFinancingReceivable_Credit) [GLPostedReceivables_FinanceComponent_GL]
		,SUM(t.PaidReceivableLease_Credit - t.PaidReceivableLease_Debit) [TotalPaidReceivables_LeaseComponent_GL]
		,SUM(t.PaidReceivablesviaCashLease_Credit - t.PaidReceivablesviaCashLease_Debit) [TotalPaidReceivablesviaCash_LeaseComponent_GL]
		,SUM(t.PaidReceivablesviaNonCashLease_Credit - t.PaidReceivablesviaNonCashLease_Debit) [TotalPaidReceivablesviaNonCash_LeaseComponent_GL]
		,SUM(t.PaidReceivableFinance_Credit - t.PaidReceivableFinance_Debit) [TotalPaidReceivables_FinanceComponent_GL]
		,SUM(t.PaidReceivablesviaCashFinance_Credit - t.PaidReceivablesviaCashFinance_Debit) [TotalPaidReceivablesviaCash_FinanceComponent_GL]
		,SUM(t.PaidReceivablesviaNonCashFinance_Credit - t.PaidReceivablesviaNonCashFinance_Debit) [TotalPaidReceivablesviaNonCash_FinanceComponent_GL]
		,SUM(t.ReceiptPrepaidReceivableLease_Credit - t.ReceiptPrepaidReceivableLease_Debit) - SUM(t.PrepaidReceivableLease_Debit - t.PrepaidReceivableLease_Credit) [PrepaidReceivables_LeaseComponent_GL]
		,SUM(t.ReceiptPrepaidReceivableFinance_Credit - t.ReceiptPrepaidReceivableFinance_Debit) - SUM(t.PrepaidReceivableFinance_Debit -	t.PrepaidReceivableFinance_Credit) [PrepaidReceivables_FinanceComponent_GL]
		,SUM(t.OperatingLeaseRentReceivable_Debit - t.OperatingLeaseRentReceivable_Credit) + SUM(t.RentReceivableLease_Debit -	t.RentReceivableLease_Credit) [OutstandingReceivables_LeaseComponent_GL]
		,SUM(t.FinancingShortTermLeaseReceivable_Debit - t.FinancingShortTermLeaseReceivable_Credit) + SUM(t.RentReceivableFinance_Debit -	t.RentReceivableFinance_Credit) [OutstandingReceivables_FinanceComponent_GL]
		,SUM(t.LongTermReceivableFinance_Debit - t.LongTermReceivableFinance_Credit) [LongTermReceivables_FinanceComponent_GL]
		,SUM(t.FinancingUnguaranteedResidualBooked_Debit - t.FinancingUnguaranteedResidualBooked_Credit) [UnguaranteedResidual_FinanceComponent_GL]
		,SUM(t.FinancingGuaranteedResidual_Debit - t.FinancingGuaranteedResidual_Credit) [GuaranteedResidual_FinanceComponent_GL]
		,SUM(t.OperatingLeaseAssetCost_Debit - t.OperatingLeaseAssetCost_Credit) + SUM(t.BlendedLeasedAssets_Debit - t.BlendedLeasedAssets_Credit) [AssetCost_LeaseComponent_GL]
		,SUM(t.RentalIncome_Credit - t.RentalIncome_Debit) [RentalIncome_GL]
		,SUM(t.SuspendedRentalIncome_Credit - t.SuspendedRentalIncome_Debit) [SuspendedRentalIncome_GL]
		,SUM(t.DeferredRentalIncome_Credit - t.DeferredRentalIncome_Debit) + SUM(t.ARDeferredRentalIncome_Credit - t.ARDeferredRentalIncome_Debit) + SUM	(t.CODeferredRentalIncome_Credit - t.CODeferredRentalIncome_Debit) [DeferredIncome_GL]
		,SUM(t.Depreciation_Debit - t.Depreciation_Credit) [Depreciation_GL]
		,SUM(t.MatchingAccumulatedDepreciation_Credit - t.MatchingAccumulatedDepreciation_Debit) + SUM(t.AccumulatedDepreciation_Credit -	t.AccumulatedDepreciation_Debit) [AccumulatedDepreciation_GL]
		,SUM(t.NBVImpairment_Debit - t.NBVImpairment_Credit) [NBVImpairment_GL]
		,SUM(t.AccumulatedNBVImpairment_Credit - t.AccumulatedNBVImpairment_Debit) [AccumulatedNBVImpairment_GL]
		,SUM(t.GrossWriteDown_Credit - t.GrossWriteDown_Debit) [GrossWriteDown_GL]
		,SUM(t.WriteDownRecovered_Credit - t.WriteDownRecovered_Debit) [WriteDownRecovered_GL]
		,SUM(t.ChargeOffExpense_Debit - t.ChargeOffExpense_Credit) [ChargeOffExpense_GL]
		,SUM(t.FinancingChargeOffExpense_Debit) - SUM(t.FinancingChargeOffExpense_Credit) FinancingChargeOffExpense_GL
		,SUM(t.ChargeOffRecovery_Credit - t.ChargeOffRecovery_Debit) [ChargeOffRecovery_GL]
		,SUM(t.FinancingChargeOffRecovery_Credit) - SUM(t.FinancingChargeOffRecovery_Debit) FinancingChargeOffRecovery_GL
		,SUM(t.ChargeOffGainOnRecovery_Credit - t.ChargeOffGainOnRecovery_Debit) [ChargeOffGainOnRecovery_GL]
		,SUM(t.FinancingChargeOffGainOnRecovery_Credit) - SUM(t.FinancingChargeOffGainOnRecovery_Debit) FinancingChargeOffGainOnRecovery_GL
		,SUM(t.UnAppliedAR_Credit - t.UnAppliedAR_Debit) [ContractUnAppliedAR_GL]
		,SUM(t.FinancingIncome_Credit - t.FinancingIncome_Debit) [FinancingEarnedIncome_GL]
		,SUM(t.FinancingUnguaranteedResidualIncome_Credit - t.FinancingUnguaranteedResidualIncome_Debit) [FinancingEarnedResidualIncome_GL]
		,SUM(t.FinancingUnearnedIncome_Credit - t.FinancingUnearnedIncome_Debit) [FinancingUnearnedIncome_GL]
		,SUM(t.FinancingUnearnedResidualIncome_Credit - t.FinancingUnearnedResidualIncome_Debit) [FinancingUnearnedResidualIncome_GL]
		,SUM(t.FinancingRecognizedSuspendedIncome_Credit - t.FinancingRecognizedSuspendedIncome_Debit) [FinancingRecognizedSuspendedIncome_GL]
		,SUM(t.FinancingRecognizedSuspendedResidualIncome_Credit - t.FinancingRecognizedSuspendedResidualIncome_Debit)	[FinancingRecognizedSuspendedResidualIncome_GL]

		,SUM(t.GLPostedSalesTaxReceivable_Debit) - SUM(t.GLPostedSalesTaxReceivable_Credit) [GLPostedSalesTaxReceivable_GL]
		,SUM(t.TotalPaid_SalesTaxReceivables_Credit) - SUM(t.TotalPaid_SalesTaxReceivables_Debit) [TotalPaid_SalesTaxReceivables_GL]
		,SUM(t.PrePaidTaxes_Credit) - SUM(t.PrePaidTaxes_Debit) [PrePaidTaxes_GL]
		,SUM(t.PrePaidTaxReceivable_Debit) - SUM(t.PrePaidTaxReceivable_Credit) [PrePaidTaxReceivable_GL]
		,SUM(t.TaxReceivablePosted_Debit) - SUM(t.TaxReceivablePosted_Credit) [TaxReceivablePosted_GL]
		,SUM(t.TaxReceivablesPaid_Credit) - SUM(t.TaxReceivablesPaid_Debit) [TaxReceivablesPaid_GL]
		,SUM(t.Paid_SalesTaxReceivablesviaCash_Credit) - SUM(t.Paid_SalesTaxReceivablesviaCash_Debit) [Paid_SalesTaxReceivablesviaCash_GL]
		,SUM(t.Paid_SalesTaxReceivablesviaNonCash_Credit) - SUM(t.Paid_SalesTaxReceivablesviaNonCash_Debit) [Paid_SalesTaxReceivablesviaNonCash_GL]

		,SUM(t.CapitalizedSalesTax_Credit) - SUM(t.CapitalizedSalesTax_Debit) CapitalizedSalesTax_GL
		,SUM(t.CapitalizedAdditionalCharge_Credit) - SUM(t.CapitalizedAdditionalCharge_Debit) CapitalizedAdditionalCharge_GL
		,SUM(t.CapitalizedInterimInterest_Credit) - SUM(t.CapitalizedInterimInterest_Debit) CapitalizedInterimInterest_GL
		,SUM(t.CapitalizedInterimRent_Credit) - SUM(t.CapitalizedInterimRent_Debit) CapitalizedInterimRent_GL

		,SUM(t.InterimRentReceivable_Debit - t.InterimRentReceivable_Credit) + SUM(t.PrepaidInterimRentReceivable_Debit - t.PrepaidInterimRentReceivable_Credit) [TotalGLPosted_InterimRentReceivables_GL]
		,SUM(t.CashInterimRentReceivable_Credit - t.CashInterimRentReceivable_Debit) + SUM(t.NonCashInterimRentReceivable_Credit - t.NonCashInterimRentReceivable_Debit) + SUM(t.CashPrepaidInterimRentReceivable_Credit - t.CashPrepaidInterimRentReceivable_Debit) + SUM(t.NonCashPrepaidInterimRentReceivable_Credit - t.NonCashPrepaidInterimRentReceivable_Debit) [TotalPaid_InterimRentReceivables_GL]
		,SUM(t.CashInterimRentReceivable_Credit - t.CashInterimRentReceivable_Debit) + SUM(t.CashPrepaidInterimRentReceivable_Credit - t.CashPrepaidInterimRentReceivable_Debit) [TotalPaidviaCash_InterimRentReceivables_GL]
		,SUM(t.NonCashInterimRentReceivable_Credit - t.NonCashInterimRentReceivable_Debit) + SUM(t.NonCashPrepaidInterimRentReceivable_Credit - t.NonCashPrepaidInterimRentReceivable_Debit) [TotalPaidviaNonCash_InterimRentReceivables_GL]
		,(SUM(t.CashPrepaidInterimRentReceivable_Credit - t.CashPrepaidInterimRentReceivable_Debit) + SUM(t.NonCashPrepaidInterimRentReceivable_Credit - t.NonCashPrepaidInterimRentReceivable_Debit)) - SUM(t.PrepaidInterimRentReceivable_Debit - t.PrepaidInterimRentReceivable_Credit) [TotalPrepaid_InterimRentReceivables_GL]
		,SUM(t.InterimRentReceivable_Debit - t.InterimRentReceivable_Credit) - (SUM(t.CashInterimRentReceivable_Credit - t.CashInterimRentReceivable_Debit) + SUM(t.NonCashInterimRentReceivable_Credit - t.NonCashInterimRentReceivable_Debit)) [TotalOutstanding_InterimRentReceivables_GL]
		,SUM(t.InterimRentIncome_Credit - t.InterimRentIncome_Debit) [GLPosted_InterimRentIncome_GL]
		,SUM(t.DeferCapitalizedInterimRent_Credit - DeferCapitalizedInterimRent_Debit) [TotalCapitalizedIncome_InterimRentIncome_GL]
		,SUM(t.BookingDeferredInterimRentIncome_Debit - t.BookingDeferredInterimRentIncome_Credit) [BookingDeferredInterimRentIncome_GL]
		,SUM(t.ARDeferredInterimRentIncome_Credit - t.ARDeferredInterimRentIncome_Debit) [ARDeferredInterimRentIncome_GL]
		,SUM(t.IRDeferredInterimRentIncome_Debit - t.IRDeferredInterimRentIncome_Credit) [IRDeferredInterimRentIncome_GL]
		,CAST (0 AS DECIMAL (16,2)) [DeferInterimRentIncome_GL]

		,SUM(t.InterimInterestReceivable_Debit - t.InterimInterestReceivable_Credit) + SUM(t.PrepaidInterimInterestReceivable_Debit - t.PrepaidInterimInterestReceivable_Credit) [TotalGLPosted_InterimInterestReceivables_GL]
		,SUM(t.CashInterimInterestReceivable_Credit - t.CashInterimInterestReceivable_Debit) + SUM(t.NonCashInterimInterestReceivable_Credit - t.NonCashInterimInterestReceivable_Debit) + SUM(t.CashPrepaidInterimInterestReceivable_Credit - t.CashPrepaidInterimInterestReceivable_Debit) + SUM(t.NonCashPrepaidInterimInterestReceivable_Credit - t.NonCashPrepaidInterimInterestReceivable_Debit) [TotalPaid_InterimInterestReceivables_GL]
		,SUM(t.CashInterimInterestReceivable_Credit - t.CashInterimInterestReceivable_Debit) + SUM(t.CashPrepaidInterimInterestReceivable_Credit - t.CashPrepaidInterimInterestReceivable_Debit) [TotalPaidviaCash_InterimInterestReceivables_GL]
		,SUM(t.NonCashInterimInterestReceivable_Credit - t.NonCashInterimInterestReceivable_Debit) + SUM(t.NonCashPrepaidInterimInterestReceivable_Credit - t.NonCashPrepaidInterimInterestReceivable_Debit) [TotalPaidviaNonCash_InterimInterestReceivables_GL]
		,(SUM(t.CashPrepaidInterimInterestReceivable_Credit - t.CashPrepaidInterimInterestReceivable_Debit) + SUM(t.NonCashPrepaidInterimInterestReceivable_Credit - t.NonCashPrepaidInterimInterestReceivable_Debit)) - SUM(t.PrepaidInterimInterestReceivable_Debit - t.PrepaidInterimInterestReceivable_Credit) [TotalPrepaid_InterimInterestReceivables_GL]
		,SUM(t.InterimInterestReceivable_Debit - t.InterimInterestReceivable_Credit) - (SUM(t.CashInterimInterestReceivable_Credit - t.CashInterimInterestReceivable_Debit) + SUM(t.NonCashInterimInterestReceivable_Credit - t.NonCashInterimInterestReceivable_Debit)) [TotalOutstanding_InterimInterestReceivables_GL]
		,SUM(t.InterimInterestIncome_Credit - t.InterimInterestIncome_Debit) [GLPosted_InterimInterestIncome_GL]
		,SUM(t.DeferCapitalizedInterimInterest_Credit - t.DeferCapitalizedInterimInterest_Debit) [TotalCapitalizedIncome_InterimInterestIncome_GL]
		,SUM(t.BookingAccruedInterimInterestIncome_Debit - t.BookingAccruedInterimInterestIncome_Credit) [BookingAccruedInterimInterestIncome_GL]
		,SUM(t.ARAccruedInterimInterestIncome_Credit - t.ARAccruedInterimInterestIncome_Debit) [ARAccruedInterimInterestIncome_GL]
		,SUM(t.IRAccruedInterimInterestIncome_Debit - t.IRAccruedInterimInterestIncome_Credit) [IRAccruedInterimInterestIncome_GL]
		,CAST (0 AS DECIMAL (16,2)) [AccruedInterimInterestIncome_GL]

		,SUM(t.TotalGLPosted_Debit - t.TotalGLPosted_Credit) [TotalGLPosted_GL]
		,SUM(t.OSAR_Debit - t.OSAR_Credit) [OSAR_GL]
		,SUM(t.TotalPaid_Credit - t.TotalPaid_Debit) [TotalPaid_GL]
		,SUM(t.TotalCashPaid_Credit - t.TotalCashPaid_Debit) [TotalCashPaid_GL]
		,SUM(t.TotalNonCashPaid_Credit - t.TotalNonCashPaid_Debit) [TotalNonCashPaid_GL]
		,SUM(t.TotalPrePaid_Credit - t.TotalPrePaid_Debit) [TotalPrePaid_GL]
		,SUM(t.TotalFloatRateIncome_Credit - t.TotalFloatRateIncome_Debit) [TotalFloatRateIncome_GL]
		,SUM(t.TotalSuspendedFloatRateIncome_Credit - t.TotalSuspendedFloatRateIncome_Debit) [TotalSuspendedFloatRateIncome_GL]
		,SUM(t.TotalAccruedFloatRateIncome_Credit - t.TotalAccruedFloatRateIncome_Debit) [TotalAccruedFloatRateIncome_GL]

		,SUM(t.DueToThirdPartyAR_Debit - t.DueToThirdPartyAR_Credit) + SUM(t.PrepaidDueToThirdPartyAR_Debit - t.PrepaidDueToThirdPartyAR_Credit) [TotalGLPosted_FunderOwned_GL]
		,SUM(t.CashDueToThirdPartyAR_Credit - t.CashDueToThirdPartyAR_Debit) + SUM(t.CashPrepaidDueToThirdPartyAR_Credit - t.CashPrepaidDueToThirdPartyAR_Debit) [TotalPaidCash_FunderOwned_GL]
		,SUM(t.NonCashDueToThirdPartyAR_Credit - t.NonCashDueToThirdPartyAR_Debit) + SUM(t.NonCashPrepaidDueToThirdPartyAR_Credit - t.NonCashPrepaidDueToThirdPartyAR_Debit) [TotalPaidNonCash_FunderOwned_GL]
		,(SUM(t.CashPrepaidDueToThirdPartyAR_Credit - t.CashPrepaidDueToThirdPartyAR_Debit) + SUM(t.NonCashPrepaidDueToThirdPartyAR_Credit - t.NonCashPrepaidDueToThirdPartyAR_Debit)) - (SUM(t.PrepaidDueToThirdPartyAR_Debit - t.PrepaidDueToThirdPartyAR_Credit)) [TotalPrepaid_FunderOwned_GL]
		,(SUM(t.DueToThirdPartyAR_Debit - t.DueToThirdPartyAR_Credit)) - (SUM(t.CashDueToThirdPartyAR_Credit - t.CashDueToThirdPartyAR_Debit) + SUM(t.NonCashDueToThirdPartyAR_Credit - t.NonCashDueToThirdPartyAR_Debit)) [TotalOutstanding_FunderOwned_GL]
		,SUM(t.SyndicatedSalesTaxReceivable_Debit - t.SyndicatedSalesTaxReceivable_Credit) + SUM(t.PrepaidSyndicatedSalesTaxReceivable_Debit - t.PrepaidSyndicatedSalesTaxReceivable_Credit) [TotalGLPosted_FunderOwned_LessorRemit_SalesTax_GL]
		,SUM(t.CashSyndicatedSalesTaxReceivable_Credit - t.CashSyndicatedSalesTaxReceivable_Debit) + SUM(t.CashPrepaidSyndicatedSalesTaxReceivable_Credit - t.CashPrepaidSyndicatedSalesTaxReceivable_Debit) [TotalPaidCash_FunderOwned_LessorRemit_SalesTax_GL]
		,SUM(t.NonCashSyndicatedSalesTaxReceivable_Credit - t.NonCashSyndicatedSalesTaxReceivable_Debit) + SUM(t.NonCashPrepaidSyndicatedSalesTaxReceivable_Credit - t.NonCashPrepaidSyndicatedSalesTaxReceivable_Debit) [TotalPaidNonCash_FunderOwned_LessorRemit_SalesTax_GL]
		,(SUM(t.CashPrepaidSyndicatedSalesTaxReceivable_Credit - t.CashPrepaidSyndicatedSalesTaxReceivable_Debit) + SUM(t.NonCashPrepaidSyndicatedSalesTaxReceivable_Credit - t.NonCashPrepaidSyndicatedSalesTaxReceivable_Debit)) - SUM(t.PrepaidSyndicatedSalesTaxReceivable_Debit - t.PrepaidSyndicatedSalesTaxReceivable_Credit) [TotalPrepaid_FunderOwned_LessorRemit_SalesTax_GL]
		,SUM(t.SyndicatedSalesTaxReceivable_Debit - t.SyndicatedSalesTaxReceivable_Credit) - (SUM(t.CashSyndicatedSalesTaxReceivable_Credit - t.CashSyndicatedSalesTaxReceivable_Debit) + SUM(t.NonCashSyndicatedSalesTaxReceivable_Credit - t.NonCashSyndicatedSalesTaxReceivable_Debit)) [TotalOutstanding_FunderOwned_LessorRemit_SalesTax_GL]
		--GLEntry
	INTO #GLDetails
	FROM (
		SELECT 
			ec.ContractId ContractId
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'OperatingLeaseAR'
					AND gle.Name IN ('OperatingLeaseRentReceivable','PrePaidOperatingLeaseReceivable')
				THEN gld.Amount_Amount
				ELSE 0
			END GLPostedLeaseReceivable_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'OperatingLeaseAR'
					AND gle.Name IN ('OperatingLeaseRentReceivable','PrePaidOperatingLeaseReceivable')
				THEN gld.Amount_Amount
				ELSE 0
			END GLPostedLeaseReceivable_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'OperatingLeaseAR'
					AND gle.Name IN ('FinancingShortTermLeaseReceivable','FinancingPrePaidLeaseReceivable')
				THEN gld.Amount_Amount
				ELSE 0
			END GLPostedFinancingReceivable_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'OperatingLeaseAR'
					AND gle.Name IN ('FinancingShortTermLeaseReceivable','FinancingPrePaidLeaseReceivable')
				THEN gld.Amount_Amount
				ELSE 0
			END GLPostedFinancingReceivable_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'OperatingLeaseAR'
					AND gle.Name = 'OperatingLeaseRentReceivable'
				THEN gld.Amount_Amount
				ELSE 0
			END OperatingLeaseRentReceivable_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'OperatingLeaseAR'
					AND gle.Name = 'OperatingLeaseRentReceivable'
				THEN gld.Amount_Amount
				ELSE 0
			END OperatingLeaseRentReceivable_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'OperatingLeaseAR'
					AND gle.Name = 'FinancingShortTermLeaseReceivable'
				THEN gld.Amount_Amount
				ELSE 0
			END FinancingShortTermLeaseReceivable_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'OperatingLeaseAR'
					AND gle.Name = 'FinancingShortTermLeaseReceivable'
				THEN gld.Amount_Amount
				ELSE 0
			END FinancingShortTermLeaseReceivable_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name IN ('ReceiptCash','ReceiptNonCash')
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'OperatingLeaseAR'
					AND mgle.Name IN ('OperatingLeaseRentReceivable','PrePaidOperatingLeaseReceivable')
				THEN gld.Amount_Amount
				ELSE 0
			END PaidReceivableLease_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name IN ('ReceiptCash','ReceiptNonCash')
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'OperatingLeaseAR'
					AND mgle.Name IN ('OperatingLeaseRentReceivable','PrePaidOperatingLeaseReceivable')
				THEN gld.Amount_Amount
				ELSE 0
			END PaidReceivableLease_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'ReceiptCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'OperatingLeaseAR'
					AND mgle.Name IN ('OperatingLeaseRentReceivable','PrePaidOperatingLeaseReceivable')
				THEN gld.Amount_Amount
				ELSE 0
			END PaidReceivablesviaCashLease_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'ReceiptCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'OperatingLeaseAR'
					AND mgle.Name IN ('OperatingLeaseRentReceivable','PrePaidOperatingLeaseReceivable')
				THEN gld.Amount_Amount
				ELSE 0
			END PaidReceivablesviaCashLease_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'ReceiptNonCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'OperatingLeaseAR'
					AND mgle.Name IN ('OperatingLeaseRentReceivable','PrePaidOperatingLeaseReceivable')
				THEN gld.Amount_Amount
				ELSE 0
			END PaidReceivablesviaNonCashLease_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'ReceiptNonCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'OperatingLeaseAR'
					AND mgle.Name IN ('OperatingLeaseRentReceivable','PrePaidOperatingLeaseReceivable')
				THEN gld.Amount_Amount
				ELSE 0
			END PaidReceivablesviaNonCashLease_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name IN ('ReceiptCash','ReceiptNonCash')
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'OperatingLeaseAR'
					AND mgle.Name IN ('FinancingShortTermLeaseReceivable','FinancingPrePaidLeaseReceivable')
				THEN gld.Amount_Amount
				ELSE 0
			END PaidReceivableFinance_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name IN ('ReceiptCash','ReceiptNonCash')
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'OperatingLeaseAR'
					AND mgle.Name IN ('FinancingShortTermLeaseReceivable','FinancingPrePaidLeaseReceivable')
				THEN gld.Amount_Amount
				ELSE 0
			END PaidReceivableFinance_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'ReceiptCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'OperatingLeaseAR'
					AND mgle.Name IN ('FinancingShortTermLeaseReceivable','FinancingPrePaidLeaseReceivable')
				THEN gld.Amount_Amount
				ELSE 0
			END PaidReceivablesviaCashFinance_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'ReceiptCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'OperatingLeaseAR'
					AND mgle.Name IN ('FinancingShortTermLeaseReceivable','FinancingPrePaidLeaseReceivable')
				THEN gld.Amount_Amount
				ELSE 0
			END PaidReceivablesviaCashFinance_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'ReceiptNonCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'OperatingLeaseAR'
					AND mgle.Name IN ('FinancingShortTermLeaseReceivable','FinancingPrePaidLeaseReceivable')
				THEN gld.Amount_Amount
				ELSE 0
			END PaidReceivablesviaNonCashFinance_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'ReceiptNonCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'OperatingLeaseAR'
					AND mgle.Name IN ('FinancingShortTermLeaseReceivable','FinancingPrePaidLeaseReceivable')
				THEN gld.Amount_Amount
				ELSE 0
			END PaidReceivablesviaNonCashFinance_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name IN ('ReceiptCash','ReceiptNonCash')
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'OperatingLeaseAR'
					AND mgle.Name = 'PrePaidOperatingLeaseReceivable'
				THEN gld.Amount_Amount
				ELSE 0
			END ReceiptPrepaidReceivableLease_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name IN ('ReceiptCash','ReceiptNonCash')
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'OperatingLeaseAR'
					AND mgle.Name = 'PrePaidOperatingLeaseReceivable'
				THEN gld.Amount_Amount
				ELSE 0
			END ReceiptPrepaidReceivableLease_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'OperatingLeaseAR'
					AND gle.Name = 'PrePaidOperatingLeaseReceivable'
					AND mgltt.Name IS NULL
					AND mgle.Name IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END PrepaidReceivableLease_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'OperatingLeaseAR'
					AND gle.Name = 'PrePaidOperatingLeaseReceivable'
					AND mgltt.Name IS NULL
					AND mgle.Name IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END PrepaidReceivableLease_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name IN ('ReceiptCash','ReceiptNonCash')
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'OperatingLeaseAR'
					AND mgle.Name = 'FinancingPrePaidLeaseReceivable'
				THEN gld.Amount_Amount
				ELSE 0
			END ReceiptPrepaidReceivableFinance_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name IN ('ReceiptCash','ReceiptNonCash')
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'OperatingLeaseAR'
					AND mgle.Name = 'FinancingPrePaidLeaseReceivable'
				THEN gld.Amount_Amount
				ELSE 0
			END ReceiptPrepaidReceivableFinance_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'OperatingLeaseAR'
					AND gle.Name = 'FinancingPrePaidLeaseReceivable'
					AND mgltt.Name IS NULL
					AND mgle.Name IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END PrepaidReceivableFinance_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'OperatingLeaseAR'
					AND gle.Name = 'FinancingPrePaidLeaseReceivable'
					AND mgltt.Name IS NULL
					AND mgle.Name IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END PrepaidReceivableFinance_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name IN ('ReceiptCash','ReceiptNonCash')
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'OperatingLeaseAR'
					AND mgle.Name = 'OperatingLeaseRentReceivable'
				THEN gld.Amount_Amount
				ELSE 0
			END RentReceivableLease_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name IN ('ReceiptCash','ReceiptNonCash')
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'OperatingLeaseAR'
					AND mgle.Name = 'OperatingLeaseRentReceivable'
				THEN gld.Amount_Amount
				ELSE 0
			END RentReceivableLease_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name IN ('ReceiptCash','ReceiptNonCash')
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'OperatingLeaseAR'
					AND mgle.Name = 'FinancingShortTermLeaseReceivable'
				THEN gld.Amount_Amount
				ELSE 0
			END RentReceivableFinance_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name IN ('ReceiptCash','ReceiptNonCash')
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'OperatingLeaseAR'
					AND mgle.Name = 'FinancingShortTermLeaseReceivable'
				THEN gld.Amount_Amount
				ELSE 0
			END RentReceivableFinance_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name IN ('OperatingLeaseBooking','OperatingLeasePayOff','OperatingLeaseChargeOff','OperatingLeaseAR')
					AND gle.Name = 'FinancingLongTermLeaseReceivable'
				THEN gld.Amount_Amount
				ELSE 0
			END LongTermReceivableFinance_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name IN ('OperatingLeaseBooking','OperatingLeasePayOff','OperatingLeaseChargeOff','OperatingLeaseAR')
					AND gle.Name = 'FinancingLongTermLeaseReceivable'
				THEN gld.Amount_Amount
				ELSE 0
			END LongTermReceivableFinance_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name IN ('OperatingLeaseBooking','OperatingLeasePayOff','OperatingLeaseChargeOff','OTPIncome','ResidualImpairment')
					AND gle.Name = 'FinancingUnguaranteedResidualBooked'
				THEN gld.Amount_Amount
				ELSE 0
			END FinancingUnguaranteedResidualBooked_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name IN ('OperatingLeaseBooking','OperatingLeasePayOff','OperatingLeaseChargeOff','OTPIncome','ResidualImpairment')
					AND gle.Name = 'FinancingUnguaranteedResidualBooked'
				THEN gld.Amount_Amount
				ELSE 0
			END FinancingUnguaranteedResidualBooked_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name IN ('OperatingLeaseBooking','OperatingLeasePayOff','OperatingLeaseChargeOff','OTPIncome','ResidualImpairment')
					AND gle.Name = 'FinancingGuaranteedResidual'
				THEN gld.Amount_Amount
				ELSE 0
			END FinancingGuaranteedResidual_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name IN ('OperatingLeaseBooking','OperatingLeasePayOff','OperatingLeaseChargeOff','OTPIncome','ResidualImpairment')
					AND gle.Name = 'FinancingGuaranteedResidual'
				THEN gld.Amount_Amount
				ELSE 0
			END FinancingGuaranteedResidual_Credit
			,CASE
				WHEN gld.IsDebit = 1
					--AND gltt.Name IN ('OperatingLeaseBooking','OperatingLeaseChargeoff','OperatingLeasePayOff','OTPIncome')
					AND gle.Name = 'OperatingLeaseAsset'
					AND ((rd.ContractId IS NULL AND gltt.Name IN ('OperatingLeaseBooking','OperatingLeaseChargeoff','OperatingLeasePayOff','OTPIncome'))
						OR (rd.ContractId IS NOT NULL AND 
							((gltt.Name = 'OperatingLeaseBooking' AND gld.SourceId >= rd.RenewalFinanceId)
							OR (gltt.Name = 'OperatingLeasePayOff' AND gld.GLJournalId > rgl.RenewalGLJournalId)
							OR (gltt.Name = 'OTPIncome' AND gld.SourceId >= rd.LeaseIncomeId)
							OR (gltt.Name = 'OperatingLeaseChargeOff'))))
				THEN gld.Amount_Amount
				ELSE 0
			END OperatingLeaseAssetCost_Debit
			,CASE
				WHEN gld.IsDebit = 0
					--AND gltt.Name IN ('OperatingLeaseBooking','OperatingLeaseChargeoff','OperatingLeasePayOff','OTPIncome')
					AND gle.Name = 'OperatingLeaseAsset'
					AND ((rd.ContractId IS NULL AND gltt.Name IN ('OperatingLeaseBooking','OperatingLeaseChargeoff','OperatingLeasePayOff','OTPIncome'))
						OR (rd.ContractId IS NOT NULL AND 
							((gltt.Name = 'OperatingLeaseBooking' AND gld.SourceId >= rd.RenewalFinanceId)
							OR (gltt.Name = 'OperatingLeasePayOff' AND gld.GLJournalId > rgl.RenewalGLJournalId)
							OR (gltt.Name = 'OTPIncome' AND gld.SourceId >= rd.LeaseIncomeId)
							OR (gltt.Name = 'OperatingLeaseChargeOff'))))
				THEN gld.Amount_Amount
				ELSE 0
			END OperatingLeaseAssetCost_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'BlendedIncomeSetup'
					AND gle.Name = 'LeasedAssets'
					AND mgltt.Name = 'OperatingLeaseBooking'
					AND mgle.Name = 'OperatingLeaseAsset'
				THEN gld.Amount_Amount
				ELSE 0
			END BlendedLeasedAssets_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'BlendedIncomeSetup'
					AND gle.Name = 'LeasedAssets'
					AND mgltt.Name = 'OperatingLeaseBooking'
					AND mgle.Name = 'OperatingLeaseAsset'
				THEN gld.Amount_Amount
				ELSE 0
			END BlendedLeasedAssets_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'OperatingLeaseIncome'
					AND gle.Name = 'RentalRevenue'
					AND (rd.ContractId IS NULL OR (gld.SourceId >= rd.LeaseIncomeId))
				THEN gld.Amount_Amount
				ELSE 0
			END RentalIncome_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'OperatingLeaseIncome'
					AND gle.Name = 'RentalRevenue'
					AND (rd.ContractId IS NULL OR (gld.SourceId >= rd.LeaseIncomeId))
				THEN gld.Amount_Amount
				ELSE 0
			END RentalIncome_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name IN ('OperatingLeaseIncome','OperatingLeaseChargeOff')
					AND gle.Name = 'SuspendedRentalRevenue'
				THEN gld.Amount_Amount
				ELSE 0
			END SuspendedRentalIncome_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name IN ('OperatingLeaseIncome','OperatingLeaseChargeOff')
					AND gle.Name = 'SuspendedRentalRevenue'
				THEN gld.Amount_Amount
				ELSE 0
			END SuspendedRentalIncome_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'OperatingLeaseIncome'
					AND gle.Name = 'DeferredRentalRevenue'
					AND (rd.ContractId IS NULL OR (gld.SourceId >= rd.LeaseIncomeId))
				THEN gld.Amount_Amount
				ELSE 0
			END DeferredRentalIncome_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'OperatingLeaseIncome'
					AND gle.Name = 'DeferredRentalRevenue'
					AND (rd.ContractId IS NULL OR (gld.SourceId >= rd.LeaseIncomeId))
				THEN gld.Amount_Amount
				ELSE 0
			END DeferredRentalIncome_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'OperatingLeaseAR'
					AND gle.Name = 'DeferredRentalRevenue'
					AND (rd.ContractId IS NULL OR (gld.SourceId >= rd.ReceivableId))
				THEN gld.Amount_Amount
				ELSE 0
			END ARDeferredRentalIncome_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'OperatingLeaseAR'
					AND gle.Name = 'DeferredRentalRevenue'
					AND (rd.ContractId IS NULL OR (gld.SourceId >= rd.ReceivableId))
				THEN gld.Amount_Amount
				ELSE 0
			END ARDeferredRentalIncome_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'OperatingLeaseChargeOff'
					AND gle.Name = 'DeferredRentalRevenue'
				THEN gld.Amount_Amount
				ELSE 0
			END CODeferredRentalIncome_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'OperatingLeaseChargeOff'
					AND gle.Name = 'DeferredRentalRevenue'
				THEN gld.Amount_Amount
				ELSE 0
			END CODeferredRentalIncome_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'OperatingLeaseIncome'
					AND gle.Name = 'FixedTermDepreciation'
					AND (rd.ContractId IS NULL OR (rd.ContractId IS NOT NULL AND gld.SourceId >= rd.LeaseIncomeId))
				THEN gld.Amount_Amount
				ELSE 0
			END Depreciation_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'OperatingLeaseIncome'
					AND gle.Name = 'FixedTermDepreciation'
					AND (rd.ContractId IS NULL OR (rd.ContractId IS NOT NULL AND gld.SourceId >= rd.LeaseIncomeId))
				THEN gld.Amount_Amount
				ELSE 0
			END Depreciation_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gle.Name IN ('AccumulatedFixedTermDepreciation','AccumulatedDepreciation')
					AND mgltt.Name = 'OperatingLeaseIncome'
					AND mgle.Name = 'AccumulatedFixedTermDepreciation'
					AND ((rd.ContractId IS NULL AND gltt.Name IN ('OperatingLeaseChargeOff','OperatingLeasePayoff','OTPIncome'))
						OR (rd.ContractId IS NOT NULL 
							AND ((gltt.Name = 'OperatingLeaseChargeOff')
								OR (gltt.Name = 'OTPIncome' AND gld.SourceId >= rd.LeaseIncomeId)
								OR (gltt.Name = 'OperatingLeasePayoff' AND gld.GLJournalId > rgl.RenewalGLJournalId))))			
				THEN gld.Amount_Amount
				ELSE 0
			END MatchingAccumulatedDepreciation_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gle.Name IN ('AccumulatedFixedTermDepreciation','AccumulatedDepreciation')
					AND mgltt.Name = 'OperatingLeaseIncome'
					AND mgle.Name = 'AccumulatedFixedTermDepreciation'
					AND ((rd.ContractId IS NULL AND gltt.Name IN ('OperatingLeaseChargeOff','OperatingLeasePayoff','OTPIncome'))
						OR (rd.ContractId IS NOT NULL 
							AND ((gltt.Name = 'OperatingLeaseChargeOff')
								OR (gltt.Name = 'OTPIncome' AND gld.SourceId >= rd.LeaseIncomeId)
								OR (gltt.Name = 'OperatingLeasePayoff' AND gld.GLJournalId > rgl.RenewalGLJournalId))))			
				THEN gld.Amount_Amount
				ELSE 0
			END MatchingAccumulatedDepreciation_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'OperatingLeaseIncome'
					AND gle.Name = 'AccumulatedFixedTermDepreciation'
					AND mgltt.Name IS NULL
					AND mgle.Name IS NULL
					AND (rd.ContractId IS NULL OR (rd.ContractId IS NOT NULL AND gld.SourceId >= rd.LeaseIncomeId))
				THEN gld.Amount_Amount
				ELSE 0
			END AccumulatedDepreciation_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'OperatingLeaseIncome'
					AND gle.Name = 'AccumulatedFixedTermDepreciation'
					AND mgltt.Name IS NULL
					AND mgle.Name IS NULL
					AND (rd.ContractId IS NULL OR (rd.ContractId IS NOT NULL AND gld.SourceId >= rd.LeaseIncomeId))
				THEN gld.Amount_Amount
				ELSE 0
			END AccumulatedDepreciation_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'NBVImpairment'
					AND gle.Name = 'NBVImpairment'
					AND (rd.ContractId IS NULL OR (rd.ContractId IS NOT NULL AND gld.SourceId >= rd.RenewalFinanceId))
				THEN gld.Amount_Amount
				ELSE 0
			END NBVImpairment_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'NBVImpairment'
					AND gle.Name = 'NBVImpairment'
					AND (rd.ContractId IS NULL OR (rd.ContractId IS NOT NULL AND gld.SourceId >= rd.RenewalFinanceId))
				THEN gld.Amount_Amount
				ELSE 0
			END NBVImpairment_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gle.Name = 'AccumulatedNBVImpairment'
					AND ((rd.ContractId IS NULL AND gltt.Name IN ('NBVImpairment','OperatingLeaseChargeOff','OperatingLeasePayoff')
						OR (rd.ContractId IS NOT NULL AND ((gltt.Name = 'OperatingLeaseChargeOff')
							OR (gltt.Name = 'NBVImpairment' AND gld.SourceId >= rd.RenewalFinanceId)
							OR (gltt.Name = 'OperatingLeasePayoff' AND gld.GLJournalId > rgl.RenewalGLJournalId)))))
				THEN gld.Amount_Amount
				ELSE 0
			END AccumulatedNBVImpairment_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gle.Name = 'AccumulatedNBVImpairment'
					AND ((rd.ContractId IS NULL AND gltt.Name IN ('NBVImpairment','OperatingLeaseChargeOff','OperatingLeasePayoff')
						OR (rd.ContractId IS NOT NULL AND ((gltt.Name = 'OperatingLeaseChargeOff')
							OR (gltt.Name = 'NBVImpairment' AND gld.SourceId >= rd.RenewalFinanceId)
							OR (gltt.Name = 'OperatingLeasePayoff' AND gld.GLJournalId > rgl.RenewalGLJournalId)))))
				THEN gld.Amount_Amount
				ELSE 0
			END AccumulatedNBVImpairment_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'WriteDown'
					AND gle.Name = 'WriteDownAccount'
				THEN gld.Amount_Amount
				ELSE 0
			END GrossWriteDown_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'WriteDown'
					AND gle.Name = 'WriteDownAccount'
				THEN gld.Amount_Amount
				ELSE 0
			END GrossWriteDown_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'WriteDownRecovery'
					AND gle.Name = 'WriteDownAccount'
				THEN gld.Amount_Amount
				ELSE 0
			END WriteDownRecovered_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'WriteDownRecovery'
					AND gle.Name = 'WriteDownAccount'
				THEN gld.Amount_Amount
				ELSE 0
			END WriteDownRecovered_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name IN ('ReceiptCash','OperatingLeaseChargeoff','BlendedExpenseRecognition','BlendedIncomeRecognition')
					AND gle.Name = 'ChargeOffExpense'
				THEN gld.Amount_Amount
				ELSE 0
			END ChargeOffExpense_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name IN ('ReceiptCash','OperatingLeaseChargeoff','BlendedExpenseRecognition','BlendedIncomeRecognition')
					AND gle.Name = 'ChargeOffExpense'
				THEN gld.Amount_Amount
				ELSE 0
			END ChargeOffExpense_Credit
		   ,CASE
			    WHEN gle.Name IN ('FinancingChargeOffExpense')
					 AND gltt.Name IN ('ReceiptCash','OperatingLeaseChargeoff','BlendedExpenseRecognition','BlendedIncomeRecognition')
					 AND gld.IsDebit = 0
				THEN gld.Amount_Amount
				ELSE 0
		    END FinancingChargeOffExpense_Credit
		   ,CASE
			    WHEN gle.Name IN ('FinancingChargeOffExpense')
					 AND gltt.Name IN ('ReceiptCash','OperatingLeaseChargeoff','BlendedExpenseRecognition','BlendedIncomeRecognition')
					 AND gld.IsDebit = 1
				THEN gld.Amount_Amount
				ELSE 0
			END FinancingChargeOffExpense_Debit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'ReceiptCash'
					AND gle.Name = 'ChargeOffRecovery'
				THEN gld.Amount_Amount
				ELSE 0
			END ChargeOffRecovery_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'ReceiptCash'
					AND gle.Name = 'ChargeOffRecovery'
				THEN gld.Amount_Amount
				ELSE 0
			END ChargeOffRecovery_Credit
		    ,CASE
			     WHEN gle.Name IN ('FinancingChargeOffRecovery')
					  AND gltt.Name IN ('ReceiptCash')
					  AND gld.IsDebit = 0
				 THEN gld.Amount_Amount
				 ELSE 0
			 END FinancingChargeOffRecovery_Credit
			,CASE
				WHEN gle.Name IN ('FinancingChargeOffRecovery')
					 AND gltt.Name IN ('ReceiptCash')
					 AND gld.IsDebit = 1
				THEN gld.Amount_Amount
				ELSE 0
			END FinancingChargeOffRecovery_Debit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'ReceiptCash'
					AND gle.Name = 'GainOnRecovery'
				THEN gld.Amount_Amount
				ELSE 0
			END ChargeOffGainOnRecovery_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'ReceiptCash'
					AND gle.Name = 'GainOnRecovery'
				THEN gld.Amount_Amount
				ELSE 0
			END ChargeOffGainOnRecovery_Credit
			,CASE
				 WHEN gle.Name IN ('FinancingGainOnRecovery')
					   AND gltt.Name IN ('ReceiptCash')
					   AND gld.IsDebit = 0
				 THEN gld.Amount_Amount
				 ELSE 0
			 END FinancingChargeOffGainOnRecovery_Credit
		,CASE
			 WHEN gle.Name IN ('FinancingGainOnRecovery')
				  AND gltt.Name IN ('ReceiptCash')
				  AND gld.IsDebit = 1
			THEN gld.Amount_Amount
			ELSE 0
		 END FinancingChargeOffGainOnRecovery_Debit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name IN ('ReceiptCash','ReceiptNonCash')
					AND gle.Name = 'UnAppliedAR'
				THEN gld.Amount_Amount
				ELSE 0
			END UnAppliedAR_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name IN ('ReceiptCash','ReceiptNonCash')
					AND gle.Name = 'UnAppliedAR'
				THEN gld.Amount_Amount
				ELSE 0
			END UnAppliedAR_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'OperatingLeaseIncome'
					AND gle.Name = 'FinancingIncome'
					AND (rd.ContractId IS NULL OR (rd.ContractId IS NOT NULL AND gld.SourceId >= rd.LeaseIncomeId))
				THEN gld.Amount_Amount
				ELSE 0
			END FinancingIncome_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'OperatingLeaseIncome'
					AND gle.Name = 'FinancingIncome'
					AND (rd.ContractId IS NULL OR (rd.ContractId IS NOT NULL AND gld.SourceId >= rd.LeaseIncomeId))
				THEN gld.Amount_Amount
				ELSE 0
			END FinancingIncome_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'OperatingLeaseIncome'
					AND gle.Name = 'FinancingUnguaranteedResidualIncome'
					AND (rd.ContractId IS NULL OR (rd.ContractId IS NOT NULL AND gld.SourceId >= rd.LeaseIncomeId))
				THEN gld.Amount_Amount
				ELSE 0
			END FinancingUnguaranteedResidualIncome_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'OperatingLeaseIncome'
					AND gle.Name = 'FinancingUnguaranteedResidualIncome'
					AND (rd.ContractId IS NULL OR (rd.ContractId IS NOT NULL AND gld.SourceId >= rd.LeaseIncomeId))
				THEN gld.Amount_Amount
				ELSE 0
			END FinancingUnguaranteedResidualIncome_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name IN ('OperatingLeaseBooking','OperatingLeaseChargeoff','OperatingLeasePayoff','OperatingLeaseIncome','BlendedIncomeSetup')
					AND gle.Name = 'FinancingUnearnedIncome'
				THEN gld.Amount_Amount
				ELSE 0
			END FinancingUnearnedIncome_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name IN ('OperatingLeaseBooking','OperatingLeaseChargeoff','OperatingLeasePayoff','OperatingLeaseIncome','BlendedIncomeSetup')
					AND gle.Name = 'FinancingUnearnedIncome'
				THEN gld.Amount_Amount
				ELSE 0
			END FinancingUnearnedIncome_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name IN ('OperatingLeaseBooking','OperatingLeaseChargeoff','OperatingLeasePayoff','OperatingLeaseIncome','ResidualImpairment')
					AND gle.Name = 'FinancingUnearnedUnguaranteedResidualIncome'
				THEN gld.Amount_Amount
				ELSE 0
			END FinancingUnearnedResidualIncome_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name IN ('OperatingLeaseBooking','OperatingLeaseChargeoff','OperatingLeasePayoff','OperatingLeaseIncome','ResidualImpairment')
					AND gle.Name = 'FinancingUnearnedUnguaranteedResidualIncome'
				THEN gld.Amount_Amount
				ELSE 0
			END FinancingUnearnedResidualIncome_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name IN ('OperatingLeaseChargeoff','OperatingLeaseIncome')
					AND gle.Name = 'FinancingSuspendedIncome'
				THEN gld.Amount_Amount
				ELSE 0
			END FinancingRecognizedSuspendedIncome_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name IN ('OperatingLeaseChargeoff','OperatingLeaseIncome')
					AND gle.Name = 'FinancingSuspendedIncome'
				THEN gld.Amount_Amount
				ELSE 0
			END FinancingRecognizedSuspendedIncome_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name IN ('OperatingLeaseChargeoff','OperatingLeaseIncome')
					AND gle.Name = 'FinancingSuspendedUnguaranteedResidualIncome'
				THEN gld.Amount_Amount
				ELSE 0
			END FinancingRecognizedSuspendedResidualIncome_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name IN ('OperatingLeaseChargeoff','OperatingLeaseIncome')
					AND gle.Name = 'FinancingSuspendedUnguaranteedResidualIncome'
				THEN gld.Amount_Amount
				ELSE 0
			END FinancingRecognizedSuspendedResidualIncome_Credit
			--SalesTax
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'SalesTax'
					AND gle.Name IN ('SalesTaxReceivable','PrePaidSalesTaxReceivable')
				THEN gld.Amount_Amount
				ELSE 0
			END GLPostedSalesTaxReceivable_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'SalesTax'
					AND gle.Name IN ('SalesTaxReceivable','PrePaidSalesTaxReceivable')
				THEN gld.Amount_Amount
				ELSE 0
			END GLPostedSalesTaxReceivable_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name IN ('ReceiptCash','ReceiptNonCash')
					AND gle.Name = 'Receivable'
					AND mgle.Name IN ('SalesTaxReceivable','PrePaidSalesTaxReceivable')
				THEN gld.Amount_Amount
				ELSE 0
			END TotalPaid_SalesTaxReceivables_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name IN ('ReceiptCash','ReceiptNonCash')
					AND gle.Name = 'Receivable'
					AND mgle.Name IN ('SalesTaxReceivable','PrePaidSalesTaxReceivable')
				THEN gld.Amount_Amount
				ELSE 0
			END TotalPaid_SalesTaxReceivables_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'ReceiptCash'
					AND gle.Name = 'Receivable'
					AND mgle.Name IN ('SalesTaxReceivable','PrePaidSalesTaxReceivable')
				THEN gld.Amount_Amount
				ELSE 0
			END Paid_SalesTaxReceivablesviaCash_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'ReceiptCash'
					AND gle.Name = 'Receivable'
					AND mgle.Name IN ('SalesTaxReceivable','PrePaidSalesTaxReceivable')
				THEN gld.Amount_Amount
				ELSE 0
			END Paid_SalesTaxReceivablesviaCash_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'ReceiptNonCash'
					AND gle.Name = 'Receivable'
					AND mgle.Name IN ('SalesTaxReceivable','PrePaidSalesTaxReceivable')
				THEN gld.Amount_Amount
				ELSE 0
			END Paid_SalesTaxReceivablesviaNonCash_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'ReceiptNonCash'
					AND gle.Name = 'Receivable'
					AND mgle.Name IN ('SalesTaxReceivable','PrePaidSalesTaxReceivable')
				THEN gld.Amount_Amount
				ELSE 0
			END Paid_SalesTaxReceivablesviaNonCash_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name IN ('ReceiptCash','ReceiptNonCash')
					AND gle.Name = 'Receivable'
					AND mgle.Name = 'PrePaidSalesTaxReceivable'
				THEN gld.Amount_Amount
				ELSE 0
			END PrePaidTaxes_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name IN ('ReceiptCash','ReceiptNonCash')
					AND gle.Name = 'Receivable'
					AND mgle.Name = 'PrePaidSalesTaxReceivable'
				THEN gld.Amount_Amount
				ELSE 0
			END PrePaidTaxes_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'SalesTax'
					AND gle.Name = 'PrePaidSalesTaxReceivable'
				THEN gld.Amount_Amount
				ELSE 0
			END PrePaidTaxReceivable_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'SalesTax'
					AND gle.Name = 'PrePaidSalesTaxReceivable'
				THEN gld.Amount_Amount
				ELSE 0
			END PrePaidTaxReceivable_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'SalesTax'
					AND gle.Name = 'SalesTaxReceivable'
				THEN gld.Amount_Amount
				ELSE 0
			END TaxReceivablePosted_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'SalesTax'
					AND gle.Name = 'SalesTaxReceivable'
				THEN gld.Amount_Amount
				ELSE 0
			END TaxReceivablePosted_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name IN ('ReceiptCash','ReceiptNonCash')
					AND gle.Name = 'Receivable'
					AND mgle.Name = 'SalesTaxReceivable'
				THEN gld.Amount_Amount
				ELSE 0
			END TaxReceivablesPaid_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name IN ('ReceiptCash','ReceiptNonCash')
					AND gle.Name = 'Receivable'
					AND mgle.Name = 'SalesTaxReceivable'
				THEN gld.Amount_Amount
				ELSE 0
			END TaxReceivablesPaid_Credit
			--Capitalized
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'OperatingLeaseBooking'
					AND gle.Name = 'SalesTaxPayable'
					AND (rd.ContractId IS NULL OR (rd.ContractId IS NOT NULL AND gld.SourceId >= rd.RenewalFinanceId))
				THEN gld.Amount_Amount
				ELSE 0
			END CapitalizedSalesTax_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'OperatingLeaseBooking'
					AND gle.Name = 'SalesTaxPayable'
					AND (rd.ContractId IS NULL OR (rd.ContractId IS NOT NULL AND gld.SourceId >= rd.RenewalFinanceId))
				THEN gld.Amount_Amount
				ELSE 0
			END CapitalizedSalesTax_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'OperatingLeaseBooking'
					AND gle.Name = 'CapitalizedAdditionalFee'
					AND (rd.ContractId IS NULL OR (rd.ContractId IS NOT NULL AND gld.SourceId >= rd.RenewalFinanceId))
				THEN gld.Amount_Amount
				ELSE 0
			END CapitalizedAdditionalCharge_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'OperatingLeaseBooking'
					AND gle.Name = 'CapitalizedAdditionalFee'
					AND (rd.ContractId IS NULL OR (rd.ContractId IS NOT NULL AND gld.SourceId >= rd.RenewalFinanceId))
				THEN gld.Amount_Amount
				ELSE 0
			END CapitalizedAdditionalCharge_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'OperatingLeaseBooking'
					AND gle.Name = 'CapitalizedInterimInterest'
					AND (rd.ContractId IS NULL OR (rd.ContractId IS NOT NULL AND gld.SourceId >= rd.RenewalFinanceId))
				THEN gld.Amount_Amount
				ELSE 0
			END CapitalizedInterimInterest_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'OperatingLeaseBooking'
					AND gle.Name = 'CapitalizedInterimInterest'
					AND (rd.ContractId IS NULL OR (rd.ContractId IS NOT NULL AND gld.SourceId >= rd.RenewalFinanceId))
				THEN gld.Amount_Amount
				ELSE 0
			END CapitalizedInterimInterest_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'OperatingLeaseBooking'
					AND gle.Name = 'CapitalizedInterimRent'
					AND (rd.ContractId IS NULL OR (rd.ContractId IS NOT NULL AND gld.SourceId >= rd.RenewalFinanceId))
				THEN gld.Amount_Amount
				ELSE 0
			END CapitalizedInterimRent_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'OperatingLeaseBooking'
					AND gle.Name = 'CapitalizedInterimRent'
					AND (rd.ContractId IS NULL OR (rd.ContractId IS NOT NULL AND gld.SourceId >= rd.RenewalFinanceId))
				THEN gld.Amount_Amount
				ELSE 0
			END CapitalizedInterimRent_Credit
			--InterimRent
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'InterimRentAR'
					AND gle.Name = 'InterimRentReceivable'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END InterimRentReceivable_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'InterimRentAR'
					AND gle.Name = 'InterimRentReceivable'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END InterimRentReceivable_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'InterimRentAR'
					AND gle.Name = 'PrepaidInterimRentReceivable'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END PrepaidInterimRentReceivable_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'InterimRentAR'
					AND gle.Name = 'PrepaidInterimRentReceivable'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END PrepaidInterimRentReceivable_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'ReceiptCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'InterimRentAR'
					AND mgle.Name = 'InterimRentReceivable'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END CashInterimRentReceivable_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'ReceiptCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'InterimRentAR'
					AND mgle.Name = 'InterimRentReceivable'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END CashInterimRentReceivable_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'ReceiptNonCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'InterimRentAR'
					AND mgle.Name = 'InterimRentReceivable'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END NonCashInterimRentReceivable_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'ReceiptNonCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'InterimRentAR'
					AND mgle.Name = 'InterimRentReceivable'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END NonCashInterimRentReceivable_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'ReceiptCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'InterimRentAR'
					AND mgle.Name = 'PrePaidInterimRentReceivable'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END CashPrepaidInterimRentReceivable_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'ReceiptCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'InterimRentAR'
					AND mgle.Name = 'PrePaidInterimRentReceivable'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END CashPrepaidInterimRentReceivable_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'ReceiptNonCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'InterimRentAR'
					AND mgle.Name = 'PrePaidInterimRentReceivable'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END NonCashPrepaidInterimRentReceivable_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'ReceiptNonCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'InterimRentAR'
					AND mgle.Name = 'PrePaidInterimRentReceivable'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END NonCashPrepaidInterimRentReceivable_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'LeaseInterimRentIncome'
					AND gle.Name = 'InterimRentIncome'
					AND @DeferInterimRentIncomeRecognition = 'False'
					AND ((ec.InterimRentBillingType = 'Periodic')
						OR (ec.InterimRentBillingType = 'SingleInstallment' 
							AND @DeferInterimRentIncomeRecognitionForSingleInstallment = 'False'))
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END InterimRentIncome_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'LeaseInterimRentIncome'
					AND gle.Name = 'InterimRentIncome'
					AND @DeferInterimRentIncomeRecognition = 'False'
					AND ((ec.InterimRentBillingType = 'Periodic')
						OR (ec.InterimRentBillingType = 'SingleInstallment' 
							AND @DeferInterimRentIncomeRecognitionForSingleInstallment = 'False'))
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END InterimRentIncome_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'OperatingLeaseBooking'
					AND gle.Name = 'CapitalizedInterimRent'
					AND mgle.Name = 'DeferredInterimRentIncome'
					AND ec.InterimRentBillingType = 'Capitalize'
					AND @DeferInterimRentIncomeRecognition = 'False'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END DeferCapitalizedInterimRent_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'OperatingLeaseBooking'
					AND gle.Name = 'CapitalizedInterimRent'
					AND mgle.Name = 'DeferredInterimRentIncome'
					AND ec.InterimRentBillingType = 'Capitalize'
					AND @DeferInterimRentIncomeRecognition = 'False'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END DeferCapitalizedInterimRent_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'OperatingLeaseBooking'
					AND gle.Name = 'DeferredInterimRentIncome'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END BookingDeferredInterimRentIncome_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'OperatingLeaseBooking'
					AND gle.Name = 'DeferredInterimRentIncome'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END BookingDeferredInterimRentIncome_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'InterimRentAR'
					AND gle.Name = 'DeferredInterimRentIncome'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END ARDeferredInterimRentIncome_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'InterimRentAR'
					AND gle.Name = 'DeferredInterimRentIncome'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END ARDeferredInterimRentIncome_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'LeaseInterimRentIncome'
					AND gle.Name = 'DeferredInterimRentIncome'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END IRDeferredInterimRentIncome_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'LeaseInterimRentIncome'
					AND gle.Name = 'DeferredInterimRentIncome'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END IRDeferredInterimRentIncome_Credit
			--InterimInterest
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'LeaseInterimInterestAR'
					AND gle.Name = 'LeaseInterimInterestReceivable'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END InterimInterestReceivable_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'LeaseInterimInterestAR'
					AND gle.Name = 'LeaseInterimInterestReceivable'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END InterimInterestReceivable_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'LeaseInterimInterestAR'
					AND gle.Name = 'PrepaidLeaseInterimInterestReceivable'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END PrepaidInterimInterestReceivable_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'LeaseInterimInterestAR'
					AND gle.Name = 'PrepaidLeaseInterimInterestReceivable'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END PrepaidInterimInterestReceivable_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'ReceiptCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'LeaseInterimInterestAR'
					AND mgle.Name = 'LeaseInterimInterestReceivable'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END CashInterimInterestReceivable_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'ReceiptCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'LeaseInterimInterestAR'
					AND mgle.Name = 'LeaseInterimInterestReceivable'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END CashInterimInterestReceivable_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'ReceiptNonCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'LeaseInterimInterestAR'
					AND mgle.Name = 'LeaseInterimInterestReceivable'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END NonCashInterimInterestReceivable_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'ReceiptNonCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'LeaseInterimInterestAR'
					AND mgle.Name = 'LeaseInterimInterestReceivable'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END NonCashInterimInterestReceivable_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'ReceiptCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'LeaseInterimInterestAR'
					AND mgle.Name = 'PrepaidLeaseInterimInterestReceivable'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END CashPrepaidInterimInterestReceivable_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'ReceiptCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'LeaseInterimInterestAR'
					AND mgle.Name = 'PrepaidLeaseInterimInterestReceivable'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END CashPrepaidInterimInterestReceivable_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'ReceiptNonCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'LeaseInterimInterestAR'
					AND mgle.Name = 'PrepaidLeaseInterimInterestReceivable'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END NonCashPrepaidInterimInterestReceivable_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'ReceiptNonCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'LeaseInterimInterestAR'
					AND mgle.Name = 'PrepaidLeaseInterimInterestReceivable'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END NonCashPrepaidInterimInterestReceivable_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'LeaseInterimInterestIncome'
					AND gle.Name = 'LeaseInterimInterestIncome'
					AND @DeferInterimInterestIncomeRecognition = 'False'
					AND ((ec.InterimInterestBillingType = 'Periodic')
						OR (ec.InterimInterestBillingType = 'SingleInstallment' 
							AND @DeferInterimInterestIncomeRecognitionForSingleInstallment = 'False'))
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END InterimInterestIncome_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'LeaseInterimInterestIncome'
					AND gle.Name = 'LeaseInterimInterestIncome'
					AND @DeferInterimInterestIncomeRecognition = 'False'
					AND ((ec.InterimInterestBillingType = 'Periodic')
						OR (ec.InterimInterestBillingType = 'SingleInstallment' 
							AND @DeferInterimInterestIncomeRecognitionForSingleInstallment = 'False'))
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END InterimInterestIncome_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'OperatingLeaseBooking'
					AND gle.Name = 'CapitalizedInterimInterest'
					AND mgle.Name = 'AccruedInterimInterest'
					AND ec.InterimInterestBillingType = 'Capitalize'
					AND @DeferInterimInterestIncomeRecognition = 'False'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END DeferCapitalizedInterimInterest_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'OperatingLeaseBooking'
					AND gle.Name = 'CapitalizedInterimInterest'
					AND mgle.Name = 'AccruedInterimInterest'
					AND ec.InterimInterestBillingType = 'Capitalize'
					AND @DeferInterimInterestIncomeRecognition = 'False'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END DeferCapitalizedInterimInterest_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'OperatingLeaseBooking'
					AND gle.Name = 'AccruedInterimInterestIncome'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END BookingAccruedInterimInterestIncome_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'OperatingLeaseBooking'
					AND gle.Name = 'AccruedInterimInterestIncome'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END BookingAccruedInterimInterestIncome_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'LeaseInterimInterestAR'
					AND gle.Name = 'AccruedInterimInterest'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END ARAccruedInterimInterestIncome_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'LeaseInterimInterestAR'
					AND gle.Name = 'AccruedInterimInterest'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END ARAccruedInterimInterestIncome_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'LeaseInterimInterestIncome'
					AND gle.Name = 'AccruedInterimInterest'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END IRAccruedInterimInterestIncome_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'LeaseInterimInterestIncome'
					AND gle.Name = 'AccruedInterimInterest'
					AND rd.ContractId IS NULL
				THEN gld.Amount_Amount
				ELSE 0
			END IRAccruedInterimInterestIncome_Credit
			--FloatRate
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'FloatRateAR'
					AND gle.Name IN ('FloatRateAR','PrePaidFloatRateAR')
					AND ec.IsFloatRateLease = 1
				THEN gld.Amount_Amount
				ELSE 0
			END TotalGLPosted_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'FloatRateAR'
					AND gle.Name IN ('FloatRateAR','PrePaidFloatRateAR')
					AND ec.IsFloatRateLease = 1
				THEN gld.Amount_Amount
				ELSE 0
			END TotalGLPosted_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND ((gle.Name = 'FloatRateAR' AND mgle.Name IS NULL)
						OR (gle.Name = 'Receivable' AND gltt.Name IN ('ReceiptCash','ReceiptNonCash') AND mgle.Name = 'FloatRateAR'))
					AND ec.IsFloatRateLease = 1
				THEN gld.Amount_Amount
				ELSE 0
			END OSAR_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND ((gle.Name = 'FloatRateAR' AND mgle.Name IS NULL)
						OR (gle.Name = 'Receivable' AND gltt.Name IN ('ReceiptCash','ReceiptNonCash') AND mgle.Name = 'FloatRateAR'))
					AND ec.IsFloatRateLease = 1
				THEN gld.Amount_Amount
				ELSE 0
			END OSAR_Credit
			,CASE
				WHEN gld.IsDebit = 0
					AND gle.Name = 'Receivable'
					AND gltt.Name IN ('ReceiptCash','ReceiptNonCash')
					AND mgltt.Name = 'FloatRateAR'
					AND mgle.Name IN ('FloatRateAR','PrePaidFloatRateAR')
					AND ec.IsFloatRateLease = 1
				THEN gld.Amount_Amount
				ELSE 0
			END TotalPaid_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gle.Name = 'Receivable'
					AND gltt.Name IN('ReceiptCash','ReceiptNonCash')
					AND mgltt.Name = 'FloatRateAR'
					AND mgle.Name IN('FloatRateAR','PrePaidFloatRateAR')
					AND ec.IsFloatRateLease = 1
				THEN gld.Amount_Amount
				ELSE 0
			END TotalPaid_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gle.Name = 'Receivable'
					AND gltt.Name IN ('ReceiptCash')
					AND mgltt.Name = 'FloatRateAR'
					AND mgle.Name IN ('FloatRateAR','PrePaidFloatRateAR')
					AND ec.IsFloatRateLease = 1
				THEN gld.Amount_Amount
				ELSE 0
			END TotalCashPaid_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gle.Name = 'Receivable'
					AND gltt.Name IN ('ReceiptCash')
					AND mgltt.Name = 'FloatRateAR'
					AND mgle.Name IN ('FloatRateAR','PrePaidFloatRateAR')
					AND ec.IsFloatRateLease = 1
				THEN gld.Amount_Amount
				ELSE 0
			END TotalCashPaid_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gle.Name = 'Receivable'
					AND gltt.Name IN ('ReceiptNonCash')
					AND mgltt.Name = 'FloatRateAR'
					AND mgle.Name IN ('FloatRateAR','PrePaidFloatRateAR')
					AND ec.IsFloatRateLease = 1
				THEN gld.Amount_Amount
				ELSE 0
			END TotalNonCashPaid_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gle.Name = 'Receivable'
					AND gltt.Name IN ('ReceiptNonCash')
					AND mgltt.Name = 'FloatRateAR'
					AND mgle.Name IN ('FloatRateAR','PrePaidFloatRateAR')
					AND ec.IsFloatRateLease = 1
				THEN gld.Amount_Amount
				ELSE 0
			END TotalNonCashPaid_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND ((gle.Name = 'PrePaidFloatRateAR' AND mgle.Name IS NULL)
						OR (gle.Name = 'Receivable' AND mgle.Name = 'PrePaidFloatRateAR'))
					AND ec.IsFloatRateLease = 1
				THEN gld.Amount_Amount
				ELSE 0
			END TotalPrePaid_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND ((gle.Name = 'PrePaidFloatRateAR' AND mgle.Name IS NULL)
						OR (gle.Name = 'Receivable' AND mgle.Name = 'PrePaidFloatRateAR'))
					AND ec.IsFloatRateLease = 1
				THEN gld.Amount_Amount
				ELSE 0
			END TotalPrePaid_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'FloatIncome'
					AND gle.Name = 'FloatInterestIncome'
					AND ec.IsFloatRateLease = 1
				THEN gld.Amount_Amount
				ELSE 0
			END TotalFloatRateIncome_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'FloatIncome'
					AND gle.Name = 'FloatInterestIncome'
					AND ec.IsFloatRateLease = 1
				THEN gld.Amount_Amount
				ELSE 0
			END TotalFloatRateIncome_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name IN ('FloatIncome' , 'OperatingLeaseChargeoff')
					AND gle.Name = 'FloatRateSuspendedIncome'
					AND ec.IsFloatRateLease = 1
				THEN gld.Amount_Amount
				ELSE 0
			END TotalSuspendedFloatRateIncome_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name IN ('FloatIncome' , 'OperatingLeaseChargeoff')
					AND gle.Name = 'FloatRateSuspendedIncome'
					AND ec.IsFloatRateLease = 1
				THEN gld.Amount_Amount
				ELSE 0
			END TotalSuspendedFloatRateIncome_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name IN ('FloatIncome','FloatRateAR')
					AND gle.Name = 'AccruedFloatRateInterestIncome'
					AND ec.IsFloatRateLease = 1
				THEN gld.Amount_Amount
				ELSE 0
			END TotalAccruedFloatRateIncome_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name IN ('FloatIncome', 'FloatRateAR')
					AND gle.Name = 'AccruedFloatRateInterestIncome'
					AND ec.IsFloatRateLease = 1
				THEN gld.Amount_Amount
				ELSE 0
			END TotalAccruedFloatRateIncome_Debit
			--FunderOwned
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'SyndicatedAR'
					AND gle.Name = 'DueToThirdPartyAR'
				THEN gld.Amount_Amount
				ELSE 0
			END DueToThirdPartyAR_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'SyndicatedAR'
					AND gle.Name = 'DueToThirdPartyAR'
				THEN gld.Amount_Amount
				ELSE 0
			END DueToThirdPartyAR_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'SyndicatedAR'
					AND gle.Name = 'PrepaidDueToThirdPartyAR'
				THEN gld.Amount_Amount
				ELSE 0
			END PrepaidDueToThirdPartyAR_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'SyndicatedAR'
					AND gle.Name = 'PrepaidDueToThirdPartyAR'
				THEN gld.Amount_Amount
				ELSE 0
			END PrepaidDueToThirdPartyAR_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'ReceiptCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'SyndicatedAR'
					AND mgle.Name = 'DueToThirdPartyAR'
				THEN gld.Amount_Amount
				ELSE 0
			END CashDueToThirdPartyAR_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'ReceiptCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'SyndicatedAR'
					AND mgle.Name = 'DueToThirdPartyAR'
				THEN gld.Amount_Amount
				ELSE 0
			END CashDueToThirdPartyAR_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'ReceiptCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'SyndicatedAR'
					AND mgle.Name = 'PrepaidDueToThirdPartyAR'
				THEN gld.Amount_Amount
				ELSE 0
			END CashPrepaidDueToThirdPartyAR_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'ReceiptCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'SyndicatedAR'
					AND mgle.Name = 'PrepaidDueToThirdPartyAR'
				THEN gld.Amount_Amount
				ELSE 0
			END CashPrepaidDueToThirdPartyAR_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'ReceiptNonCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'SyndicatedAR'
					AND mgle.Name = 'DueToThirdPartyAR'
				THEN gld.Amount_Amount
				ELSE 0
			END NonCashDueToThirdPartyAR_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'ReceiptNonCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'SyndicatedAR'
					AND mgle.Name = 'DueToThirdPartyAR'
				THEN gld.Amount_Amount
				ELSE 0
			END NonCashDueToThirdPartyAR_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'ReceiptNonCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'SyndicatedAR'
					AND mgle.Name = 'PrepaidDueToThirdPartyAR'
				THEN gld.Amount_Amount
				ELSE 0
			END NonCashPrepaidDueToThirdPartyAR_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'ReceiptNonCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'SyndicatedAR'
					AND mgle.Name = 'PrepaidDueToThirdPartyAR'
				THEN gld.Amount_Amount
				ELSE 0
			END NonCashPrepaidDueToThirdPartyAR_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'SalesTax'
					AND gle.Name = 'SyndicatedSalesTaxReceivable'
				THEN gld.Amount_Amount
				ELSE 0
			END SyndicatedSalesTaxReceivable_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'SalesTax'
					AND gle.Name = 'SyndicatedSalesTaxReceivable'
				THEN gld.Amount_Amount
				ELSE 0
			END SyndicatedSalesTaxReceivable_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'SalesTax'
					AND gle.Name = 'PrepaidSyndicatedSalesTaxReceivable'
				THEN gld.Amount_Amount
				ELSE 0
			END PrepaidSyndicatedSalesTaxReceivable_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'SalesTax'
					AND gle.Name = 'PrepaidSyndicatedSalesTaxReceivable'
				THEN gld.Amount_Amount
				ELSE 0
			END PrepaidSyndicatedSalesTaxReceivable_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'ReceiptCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'SalesTax'
					AND mgle.Name = 'SyndicatedSalesTaxReceivable'
				THEN gld.Amount_Amount
				ELSE 0
			END CashSyndicatedSalesTaxReceivable_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'ReceiptCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'SalesTax'
					AND mgle.Name = 'SyndicatedSalesTaxReceivable'
				THEN gld.Amount_Amount
				ELSE 0
			END CashSyndicatedSalesTaxReceivable_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'ReceiptCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'SalesTax'
					AND mgle.Name = 'PrepaidSyndicatedSalesTaxReceivable'
				THEN gld.Amount_Amount
				ELSE 0
			END CashPrepaidSyndicatedSalesTaxReceivable_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'ReceiptCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'SalesTax'
					AND mgle.Name = 'PrepaidSyndicatedSalesTaxReceivable'
				THEN gld.Amount_Amount
				ELSE 0
			END CashPrepaidSyndicatedSalesTaxReceivable_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'ReceiptNonCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'SalesTax'
					AND mgle.Name = 'SyndicatedSalesTaxReceivable'
				THEN gld.Amount_Amount
				ELSE 0
			END NonCashSyndicatedSalesTaxReceivable_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'ReceiptNonCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'SalesTax'
					AND mgle.Name = 'SyndicatedSalesTaxReceivable'
				THEN gld.Amount_Amount
				ELSE 0
			END NonCashSyndicatedSalesTaxReceivable_Debit
			,CASE
				WHEN gld.IsDebit = 0
					AND gltt.Name = 'ReceiptNonCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'SalesTax'
					AND mgle.Name = 'PrepaidSyndicatedSalesTaxReceivable'
				THEN gld.Amount_Amount
				ELSE 0
			END NonCashPrepaidSyndicatedSalesTaxReceivable_Credit
			,CASE
				WHEN gld.IsDebit = 1
					AND gltt.Name = 'ReceiptNonCash'
					AND gle.Name = 'Receivable'
					AND mgltt.Name = 'SalesTax'
					AND mgle.Name = 'PrepaidSyndicatedSalesTaxReceivable'
				THEN gld.Amount_Amount
				ELSE 0
			END NonCashPrepaidSyndicatedSalesTaxReceivable_Debit
			--GLMapping
		FROM #EligibleContracts ec
			INNER JOIN GLJournalDetails gld ON gld.EntityId = ec.ContractId AND gld.EntityType = 'Contract'
			INNER JOIN GLTemplateDetails gltd ON gltd.Id = gld.GLTemplateDetailId
			INNER JOIN GLEntryItems gle ON gle.Id = gltd.EntryItemId
			INNER JOIN GLTransactionTypes gltt ON gle.GLTransactionTypeId = gltt.Id
			LEFT JOIN GLTemplateDetails mgltd ON mgltd.Id = gld.MatchingGLTemplateDetailId
			LEFT JOIN GLEntryItems mgle ON mgle.Id = mgltd.EntryItemId
			LEFT JOIN GLTransactionTypes mgltt ON mgle.GLTransactionTypeId = mgltt.Id
			LEFT JOIN #RenewalDetails rd ON ec.ContractId = rd.ContractId
			LEFT JOIN #RenewalGLJournals rgl ON ec.ContractId = rgl.ContractId
		) AS t
		INNER JOIN #EligibleContracts ec ON t.ContractId = ec.ContractId
	GROUP BY t.ContractId;
	
	CREATE NONCLUSTERED INDEX IX_Id ON #GLDetails(ContractId);

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
	FROM #GLDetails gld
		INNER JOIN #EligibleContracts ec ON gld.ContractId = ec.ContractId;

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
	INTO #GLDetail
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
	
	CREATE NONCLUSTERED INDEX IX_Id ON #GLDetail(Id);

	SELECT t.ContractId
		 , SUM(t.TableAmount) AS [Refunds_GL]
	INTO #RRGLDetails
	FROM #GLDetail gl
	INNER JOIN(SELECT ContractId,Id, SUM(CASE WHEN IsReversal = 0 THEN Amount ELSE (-1)*Amount END) AS TableAmount FROM #RefundGLJournalIds WHERE EntityType = 'Payable' GROUP BY ContractId,Id) AS t ON gl.Id = t.Id
	WHERE gl.EntityType = 'Payable'
	AND gl.Refunds_GL = t.TableAmount
	GROUP BY t.ContractId;

	MERGE #RRGLDetails AS gl
	USING(SELECT refund.ContractId
			   , SUM(refund.Amount) AS [Refunds]
		  FROM #GLDetail gl
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
		FROM #GLDetails gld
			 INNER JOIN
		(
			SELECT r.EntityId
				 , ABS(SUM(CASE
						   WHEN r.StartDate < co.ChargeoffDate AND r.ReceivableType = 'OperatingLeaseRental'
						   THEN ISNULL(r.ChargeoffExpenseAmount_LC, 0.00)
						   ELSE 0.00
					   END)) AS LeaseComponentGLPosted
				 , ABS(SUM(CASE
						   WHEN r.StartDate < co.ChargeoffDate AND r.ReceivableType = 'OperatingLeaseRental'
						   THEN ISNULL(r.ChargeoffExpenseAmount_NLC, 0.00)
						   ELSE 0.00
					   END)) AS FinanceComponentGLPosted
				 , ABS(SUM(CASE
						   WHEN (r.StartDate < co.ChargeoffDate OR r.StartDate IS NULL)AND r.ReceivableType = 'LeaseFloatRateAdj'
						   THEN ISNULL(r.ChargeoffExpenseAmount_NLC, 0.00) + ISNULL(r.ChargeoffExpenseAmount_LC, 0.00)
						   ELSE 0.00
					   END)) AS FloatRateGL
			FROM #ReceiptApplicationReceivableDetails r
				 INNER JOIN #ChargeOffDetails co ON r.EntityId = co.ContractId
			WHERE ReceiptStatus IN('Reversed')
				 AND r.IsRecovery IS NOT NULL
				 AND r.IsRecovery = 0
				 AND r.IsGLPosted = 1
			GROUP BY r.EntityId
		) AS t ON t.EntityId = gld.ContractId;
		
		UPDATE gld SET 
					   TotalPaidReceivables_LeaseComponent_GL = TotalPaidReceivables_LeaseComponent_GL - (t.LeaseComponentCashPosted + t.LeaseComponentNonCashPosted)
					 , TotalPaidReceivables_FinanceComponent_GL = TotalPaidReceivables_FinanceComponent_GL - (t.FinanceComponentCashPosted + t.FinanceComponentNonCashPosted)
					 , TotalPaidReceivablesviaCash_LeaseComponent_GL -= t.LeaseComponentCashPosted
					 , TotalPaidReceivablesviaCash_FinanceComponent_GL -= t.FinanceComponentCashPosted
					 , TotalPaidReceivablesviaNonCash_LeaseComponent_GL -= t.LeaseComponentNonCashPosted
					 , TotalPaidReceivablesviaNonCash_FinanceComponent_GL -= t.FinanceComponentNonCashPosted
					 , TotalPaid_GL = TotalPaid_GL - (t.FloatRateCashPosted + t.FloatRateNonCashPosted)
					 , TotalCashPaid_GL -= t.FloatRateCashPosted
				     , TotalNonCashPaid_GL -= t.FloatRateNonCashPosted

		FROM #GLDetails gld
			 INNER JOIN
			(
			SELECT r.EntityId
				 , SUM(CASE
						   WHEN ReceiptClassification IN('Cash', 'NonAccrualNonDSL', 'DSL') AND ReceiptTypeName NOT IN('PayableOffset', 'SecurityDeposit', 'EscrowRefund')
							    AND (r.StartDate < co.ChargeoffDate AND r.ReceivableType = 'OperatingLeaseRental')
						   THEN ISNULL(r.ChargeoffExpenseAmount_LC, 0.00)
						   ELSE 0.00
					   END) AS LeaseComponentCashPosted
				 , SUM(CASE
						   WHEN ReceiptClassification IN('Cash', 'NonAccrualNonDSL', 'DSL')	AND ReceiptTypeName NOT IN('PayableOffset', 'SecurityDeposit', 'EscrowRefund')
							    AND (r.StartDate < co.ChargeoffDate AND r.ReceivableType = 'OperatingLeaseRental')
						   THEN ISNULL(r.ChargeoffExpenseAmount_NLC, 0.00)
						   ELSE 0.00
					   END) AS FinanceComponentCashPosted
				 , SUM(CASE
						   WHEN (ReceiptClassification NOT IN('Cash', 'NonAccrualNonDSL', 'DSL') OR ReceiptTypeName IN('PayableOffset', 'SecurityDeposit', 'EscrowRefund'))
							    AND (r.StartDate < co.ChargeoffDate AND r.ReceivableType = 'OperatingLeaseRental')
						   THEN ISNULL(r.ChargeoffExpenseAmount_LC, 0.00)
						   ELSE 0.00
					   END) AS LeaseComponentNonCashPosted
				 , SUM(CASE
						   WHEN (ReceiptClassification NOT IN('Cash', 'NonAccrualNonDSL', 'DSL') OR ReceiptTypeName IN('PayableOffset', 'SecurityDeposit', 'EscrowRefund'))
								AND (r.StartDate < co.ChargeoffDate AND r.ReceivableType = 'OperatingLeaseRental')
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
				 INNER JOIN #ChargeOffDetails co ON r.EntityId = co.ContractId
			WHERE ReceiptStatus IN('Reversed')
				 AND r.IsRecovery IS NOT NULL
				 AND r.IsRecovery = 0
				 AND r.IsGLPosted = 1
			GROUP BY r.EntityId
		) AS t ON t.EntityId = gld.ContractId;

	--Output
	SELECT *
		,CASE
			WHEN 
				/*ReceivablesLeaseComponent*/
				[GLPostedReceivables_LeaseComponent_Difference] != 0.00
				OR [TotalPaidReceivables_LeaseComponent_Difference] != 0.00
				OR [TotalPaidReceivablesviaCash_LeaseComponent_Difference] != 0.00
				OR [TotalPaidReceivablesviaNonCash_LeaseComponent_Difference] != 0.00
				OR [PrepaidReceivables_LeaseComponent_Difference] != 0.00
				OR [OutstandingReceivables_LeaseComponent_Difference] != 0.00
				/*AssetCostLeaseComponent*/
				OR [AssetCost_LeaseComponent_Difference] != 0.00
				/*Depreciation*/
				OR [AccumulatedDepreciation_Difference] != 0.00
				OR [Depreciation_Difference] != 0.00
				/*NBVImpairment*/
				OR [AccumulatedNBVImpairment_Difference] != 0.00
				OR [NBVImpairment_Difference] != 0.00
				/*Income*/
				OR [RentalIncome_Difference] != 0.00
				OR [SuspendedRentalIncome_Difference] != 0.00
				OR [DeferredIncome_Difference] != 0.00
				/*ReceivablesFinanceComponent*/
				OR [GLPostedReceivables_FinanceComponent_Difference] != 0.00
				OR [TotalPaidReceivables_FinanceComponent_Difference] != 0.00
				OR [TotalPaidReceivablesviaCash_FinanceComponent_Difference] != 0.00
				OR [TotalPaidReceivablesviaNonCash_FinanceComponent_Difference] != 0.00
				OR [PrepaidReceivables_FinanceComponent_Difference] != 0.00
				OR [OutstandingReceivables_FinanceComponent_Difference] != 0.00
				OR [LongTermReceivables_FinanceComponent_Difference] != 0.00
				/*ResidualsFinanceComponent*/
				OR [GuaranteedResiduals_FinanceComponent_Difference] != 0.00
				OR [UnguaranteedResiduals_FinanceComponent_Difference] != 0.00
				/*FinancingIncome*/
				OR [FinancingTotalIncome_AccountingSchedule_Difference] != 0.00
				OR [FinancingEarnedIncome_Difference] != 0.00
				OR [FinancingEarnedResidualIncome_Difference] != 0.00
				OR [FinancingUnearnedIncome_Difference] != 0.00
				OR [FinancingUnearnedResidualIncome_Difference] != 0.00
				OR [FinancingRecognizedSuspendedIncome_Difference] != 0.00
				OR [FinancingRecognizedSuspendedResidualIncome_Difference] != 0.00
				/*Capitalized*/
				OR [TotalCapitalizedSalesTax_Difference] != 0.00
				OR [TotalCapitalizedInterimInterest_Difference] != 0.00
				OR [TotalCapitalizedInterimRent_Difference] != 0.00
				OR [TotalCapitalizedAdditionalCharge_Difference] != 0.00
				/*FloatRate*/
				OR [TotalGLPostedFloatRateReceivables_Difference] != 0.00
				OR [TotalPaidFloatRateReceivables_Difference] != 0.00
				OR [TotalCashPaidFloatRateReceivables_Difference] != 0.00
				OR [TotalNonCashPaidFloatRateReceivables_Difference] != 0.00
				OR [OutstandingFloatRateReceivables_Difference] != 0.00
				OR [PrepaidFloatRateReceivables_Difference] != 0.00
				OR [TotalFloatRateIncome_AccountingAndSchedule_Difference] != 0.00
				OR [TotalGLPostedFloatRateIncome_Difference] != 0.00
				OR [TotalSuspendedIncome_Difference] != 0.00
				OR [TotalAccruedIncome_Difference] != 0.00
				/*InterimRent*/
				OR [TotalGLPosted_InterimRentReceivables_Difference] != 0.00
				OR [TotalPaid_InterimRentReceivables_Difference] != 0.00
				OR [TotalPaidviaCash_InterimRentReceivables_Difference] != 0.00
				OR [TotalPaidviaNonCash_InterimRentReceivables_Difference] != 0.00
				OR [TotalPrepaid_InterimRentReceivables_Difference] != 0.00
				OR [TotalOutstanding_InterimRentReceivables_Difference] != 0.00
				OR [GLPosted_InterimRentIncome_Difference] != 0.00
				OR [TotalCapitalizedIncome_InterimRentIncome_Difference] != 0.00
				OR [TotalInterimRent_IncomeandReceivable_Difference] != 0.00
				OR [DeferInterimRentIncome_Difference] != 0.00
				/*InterimInterest*/
				OR [TotalGLPosted_InterimInterestReceivables_Difference] != 0.00
				OR [TotalPaid_InterimInterestReceivables_Difference] != 0.00
				OR [TotalPaidviaCash_InterimInterestReceivables_Difference] != 0.00
				OR [TotalPaidviaNonCash_InterimInterestReceivables_Difference] != 0.00
				OR [TotalPrepaid_InterimInterestReceivables_Difference] != 0.00
				OR [TotalOutstanding_InterimInterestReceivables_Difference] != 0.00
				OR [GLPosted_InterimInterestIncome_Difference] != 0.00
				OR [TotalCapitalizedIncome_InterimInterestIncome_Difference] != 0.00
				OR [TotalInterimInterest_IncomeandReceivable_Difference] != 0.00
				OR [AccruedInterimInterestIncome_Difference] != 0.00
				/*WriteDown*/
				OR [GrossWriteDown_Difference] != 0.00
				OR [WriteDownRecovered_Difference] != 0.00
				OR [NetWriteDown_Difference] != 0.00
				/*ChargeOff*/
				OR [ChargeOffExpense_LeaseComponent_Difference] != 0.00
				OR [ChargeOffRecovery_LeaseComponent_Difference] != 0.00
				OR [ChargeOffGainOnRecovery_LeaseComponent_Difference] != 0.00
				OR [ChargeOffExpense_NonLeaseComponent_Difference] != 0.00
				OR [ChargeOffRecovery_NonLeaseComponent_Difference] != 0.00
				OR [ChargeOffGainOnRecovery_NonLeaseComponent_Difference] != 0.00
				OR [TotalChargeoffAmountVSLCAndNLC] != 0.00
				OR [TotalRecoveryAndGainVSRecoveryAndGainLCAndNLC] != 0.00
				/*UnApplied*/
				OR [UnAppliedCash_Difference] != 0.00
				/*SalesTax*/
				OR [TotalGLPosted_SalesTaxReceivable_Difference] != 0.00
				OR [TotalPaid_SalesTaxReceivables_Difference] != 0.00
				OR [TotalPaidviacash_SalesTaxReceivables_Difference] != 0.00
				OR [TotalPaidvianoncash_SalesTaxReceivables_Difference] != 0.00
				OR [TotalPrepaid_SalesTaxReceivables_Difference] != 0.00
				OR [TotalOutstanding_SalesTaxReceivables_Difference] != 0.00
				/*FunderOwned*/
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
				--Validation
			THEN 'Problem Record'
			ELSE 'Not Problem Record'
		END [Result]
	INTO #ResultList
	FROM (
		SELECT
			c.SequenceNumber [SequenceNumber]
			,c.Alias [ContractAlias]
			,ec.ContractId [ContractId]
			,le.Name [LegalEntityName]
			,lob.Name [LineOfBusinessName]
			,p.PartyNumber [CustomerNumber]
			,CASE
				WHEN ec.ConversionSource = @u_ConversionSource
				THEN 'Migrated'
				ELSE 'Not-Migrated'
			END [IsMigrated]
			,ec.AccountingStandard [AccountingStandard]
			,ec.ContractStatus [ContractStatus]
			,CASE
				WHEN ec.IsAdvance = 1
				THEN 'Advance'
				ELSE 'Arrear'
			END [AdvanceOrArrear]
			,ec.TermInMonths [TermInMonths]
			,ec.NumberOfPayments [NumberOfPayments]
			,ec.PaymentFrequency [PaymentFrequency]
			,CASE
				WHEN ec.IsRegularPaymentStream = 0
				THEN 'Irregular'
				ELSE 'Regular'
			END [RegularOrIrregularPayment]
			,ISNULL(pa.PaymentAmount,0.00) [PaymentAmount]
			,ec.CommencementDate [CommencementDate]
			,ec.MaturityDate [MaturityDate]
			,CASE
				WHEN ot.ContractId IS NULL
				THEN 'No'
				ELSE 'Yes'
			END [IsOTPLease]
			,CASE
				WHEN ec.InterimAssessmentMethod = '_'
				THEN 'No'
				ELSE 'Yes'
			END [LeaseWithInterim]
			,ec.InterimAssessmentMethod [InterimAssessmentMethod]
			,ec.InterimInterestBillingType [InterimInterestBillingType]
			,ec.InterimRentBillingType [InterimRentBillingType]
			,fpoc.PayoffEffectiveDate [FullPayoffEffectiveDate]
			,ec.SyndicationType [SyndicationType]
			,ec.SyndicationDate [SyndicationDate]
			,CASE
				WHEN c.IsNonAccrual = 0
				THEN 'Accrual'
				ELSE 'Non-Accrual'
			END [AccrualStatus]
			,CASE
				WHEN ad.NonAccrualId IS NOT NULL
				THEN 'Was Non-Accrual'
				ELSE 'Was Not Non-Accrual'
			END [WasNotNonAccrualAnytime]
			,ad.NonAccrualDate [NonAccrualDate]
			,CASE
				WHEN ad.ReAccrualId IS NOT NULL
				THEN 'ReAccrued'
				ELSE 'Not ReAccrued'
			END [IsReAccrualDone]
			,ad.ReAccrualDate [ReAccrualDate]
			,CASE
				WHEN hfa.ContractId IS NOT NULL
				THEN 'Yes'
				ELSE 'No'
			END [HasFinanceAsset]
			,CASE
				WHEN cod.ContractId IS NOT NULL
				THEN 'Yes'
				ELSE 'No'
			END [IsChargedOffLease]
			,cod.ChargeOffDate [ChargeOffDate]
			,CASE
				WHEN cod.ContractId IS NOT NULL AND coi.ChargeOffRecovered > 0
				THEN 'Recovered'
				WHEN cod.ContractId IS NOT NULL AND coi.ChargeOffRecovered = 0
				THEN 'Not Recovered'
				ELSE 'NA'
			END [ChargeOffStatus]
			,CASE
				WHEN ai.Renewal > 0
				THEN 'Yes'
				ELSE 'No'
			END [IsRenewalLease]
			,CASE
				WHEN ai.Assumption > 0
				THEN 'Yes'
				ELSE 'No'
			END [IsAssumptionLease]
			/*ReceivablesLeaseComponent*/
			,ISNULL(sor.TotalPaymentAmount,0.00) [TotalPaymentAmount_Table]
			,ISNULL(sor.TotalGLPostedReceivables,0.00) [TotalGLPostedReceivables_Table]
			,ISNULL(sord.GLPostedReceivables_LeaseComponent_Table,0.00) [GLPostedReceivables_LeaseComponent_Table]
			,ISNULL(gld.GLPostedReceivables_LeaseComponent_GL,0.00) [GLPostedReceivables_LeaseComponent_GL]
			,ISNULL(sord.GLPostedReceivables_LeaseComponent_Table,0.00) - ISNULL(gld.GLPostedReceivables_LeaseComponent_GL,0.00) [GLPostedReceivables_LeaseComponent_Difference]
			,ISNULL(sor.LeaseBookingReceivables, 0.00) - ISNULL(sor.ReceivablesBalance, 0.00) [TotalPaidReceivables_Table]
			,ISNULL(sorard.TotalPaidReceivables_LeaseComponent_Table,0.00) [TotalPaidReceivables_LeaseComponent_Table]
			,ISNULL(gld.TotalPaidReceivables_LeaseComponent_GL,0.00) [TotalPaidReceivables_LeaseComponent_GL]
			,ISNULL(sorard.TotalPaidReceivables_LeaseComponent_Table,0.00) - ISNULL(gld.TotalPaidReceivables_LeaseComponent_GL,0.00) [TotalPaidReceivables_LeaseComponent_Difference]
			,ISNULL(sorard.TotalPaidReceivablesviaCash_LeaseComponent_Table,0.00) [TotalPaidReceivablesviaCash_LeaseComponent_Table]
			,ISNULL(gld.TotalPaidReceivablesviaCash_LeaseComponent_GL,0.00) [TotalPaidReceivablesviaCash_LeaseComponent_GL]
			,ISNULL(sorard.TotalPaidReceivablesviaCash_LeaseComponent_Table,0.00) - ISNULL(gld.TotalPaidReceivablesviaCash_LeaseComponent_GL,0.00) [TotalPaidReceivablesviaCash_LeaseComponent_Difference]
			,ISNULL(sorard.TotalPaidReceivablesviaNonCash_LeaseComponent_Table,0.00) [TotalPaidReceivablesviaNonCash_LeaseComponent_Table]
			,ISNULL(gld.TotalPaidReceivablesviaNonCash_LeaseComponent_GL,0.00) [TotalPaidReceivablesviaNonCash_LeaseComponent_GL]
			,ISNULL(sorard.TotalPaidReceivablesviaNonCash_LeaseComponent_Table,0.00) - ISNULL(gld.TotalPaidReceivablesviaNonCash_LeaseComponent_GL,0.00) [TotalPaidReceivablesviaNonCash_LeaseComponent_Difference]
			,ISNULL(sopr.PrepaidReceivables_LeaseComponent_Table,0.00) +  ISNULL(sopr.PrepaidReceivables_FinanceComponent_Table,0.00)[PrepaidReceivables_Table]
			,ISNULL(sopr.PrepaidReceivables_LeaseComponent_Table,0.00) [PrepaidReceivables_LeaseComponent_Table]
			,ISNULL(gld.PrepaidReceivables_LeaseComponent_GL,0.00) [PrepaidReceivables_LeaseComponent_GL]
			,ISNULL(sopr.PrepaidReceivables_LeaseComponent_Table,0.00) - ISNULL(gld.PrepaidReceivables_LeaseComponent_GL,0.00) [PrepaidReceivables_LeaseComponent_Difference]
			,ISNULL(sor.TotalBalanceReceivables,0.00) [OutstandingReceivables_Table]
			,ISNULL(sord.OutstandingReceivables_LeaseComponent_Table,0.00) [OutstandingReceivables_LeaseComponent_Table]
			,ISNULL(gld.OutstandingReceivables_LeaseComponent_GL,0.00) [OutstandingReceivables_LeaseComponent_GL]
			,ISNULL(sord.OutstandingReceivables_LeaseComponent_Table,0.00) - ISNULL(gld.OutstandingReceivables_LeaseComponent_GL,0.00) [OutstandingReceivables_LeaseComponent_Difference]
			/*AssetCostLeaseComponent*/
			,ISNULL(sola.AssetCost_LeaseComponent_Table,0.00) [AssetCost_LeaseComponent_Table]
			,ABS(ISNULL(gld.AssetCost_LeaseComponent_GL,0.00)) [AssetCost_LeaseComponent_GL]
			,ISNULL(sola.AssetCost_LeaseComponent_Table,0.00) - ABS(ISNULL(gld.AssetCost_LeaseComponent_GL,0.00)) [AssetCost_LeaseComponent_Difference]
			/*ResidualsLeaseComponent*/
			,ISNULL(sola.GuaranteedResidual_LeaseComponent_Table,0.00) [GuaranteedResiduals_LeaseComponent_Table]
			,ISNULL(sola.UnguaranteedResidual_LeaseComponent_Table,0.00) [UnguaranteedResiduals_LeaseComponent_Table]
			/*Depreciation*/
			,ABS(ISNULL(ftavh.AccumulatedDepreciationAmount_Table,0.00)) [AccumulatedDepreciation_Table]
			,ABS(ISNULL(gld.AccumulatedDepreciation_GL,0.00)) [AccumulatedDepreciation_GL]
			,ABS(ISNULL(ftavh.AccumulatedDepreciationAmount_Table,0.00)) - ABS(ISNULL(gld.AccumulatedDepreciation_GL,0.00)) [AccumulatedDepreciation_Difference]
			,ABS(ISNULL(ftavh.DepreciationAmount_Table,0.00)) [Depreciation_Table]
			,ABS(ISNULL(gld.Depreciation_GL,0.00)) [Depreciation_GL]
			,ABS(ISNULL(ftavh.DepreciationAmount_Table,0.00)) - ABS(ISNULL(gld.Depreciation_GL,0.00)) [Depreciation_Difference]
			/*NBVImpairment*/
			,ABS(ISNULL(navh.AccumulatedNBVImpairment_Table,0.00)) [AccumulatedNBVImpairment_Table]
			,ABS(ISNULL(gld.AccumulatedNBVImpairment_GL,0.00)) [AccumulatedNBVImpairment_GL]
			,ABS(ISNULL(navh.AccumulatedNBVImpairment_Table,0.00)) - ABS(ISNULL(gld.AccumulatedNBVImpairment_GL,0.00)) [AccumulatedNBVImpairment_Difference]
			,ABS(ISNULL(navh.NBVImpairment_Table,0.00)) [NBVImpairment_Table]
			,ABS(ISNULL(gld.NBVImpairment_GL,0.00)) [NBVImpairment_GL]
			,ABS(ISNULL(navh.NBVImpairment_Table,0.00)) - ABS(ISNULL(gld.NBVImpairment_GL,0.00)) [NBVImpairment_Difference]
			/*Income*/
			,ISNULL(lisi.RentalIncome_Table,0.00) [RentalIncome_Table]
			,ISNULL(gld.RentalIncome_GL,0.00) [RentalIncome_GL]
			,ISNULL(lisi.RentalIncome_Table,0.00) - ISNULL(gld.RentalIncome_GL,0.00) [RentalIncome_Difference]
			,ISNULL(lisi.SuspendedRentalIncome_Table,0.00) [SuspendedRentalIncome_Table]
			,ISNULL(gld.SuspendedRentalIncome_GL,0.00) [SuspendedRentalIncome_GL]
			,ISNULL(lisi.SuspendedRentalIncome_Table,0.00) - ISNULL(gld.SuspendedRentalIncome_GL,0.00) [SuspendedRentalIncome_Difference]
			,CASE WHEN cod.ContractId IS NULL THEN ISNULL(sord.TotalGLPostedReceivables_LeaseComponent_Table,0.00) - ISNULL(lisi.DeferredRentalIncome_Table,0.00) ELSE 0.00 END [DeferredIncome_Table]
			,ISNULL(gld.DeferredIncome_GL,0.00) [DeferredIncome_GL]
			,(CASE WHEN cod.ContractId IS NULL THEN ISNULL(sord.TotalGLPostedReceivables_LeaseComponent_Table,0.00) - ISNULL(lisi.DeferredRentalIncome_Table,0.00) ELSE 0.00 END) - ISNULL(gld.DeferredIncome_GL,0.00) [DeferredIncome_Difference]
			/*ReceivablesFinanceComponent*/
			,ISNULL(sord.GLPostedReceivables_FinanceComponent_Table,0.00) [GLPostedReceivables_FinanceComponent_Table]
			,ISNULL(gld.GLPostedReceivables_FinanceComponent_GL,0.00) [GLPostedReceivables_FinanceComponent_GL]
			,ISNULL(sord.GLPostedReceivables_FinanceComponent_Table,0.00) - ISNULL(gld.GLPostedReceivables_FinanceComponent_GL,0.00) [GLPostedReceivables_FinanceComponent_Difference]
			,ISNULL(sorard.TotalPaidReceivables_FinanceComponent_Table,0.00) [TotalPaidReceivables_FinanceComponent_Table]
			,ISNULL(gld.TotalPaidReceivables_FinanceComponent_GL,0.00) [TotalPaidReceivables_FinanceComponent_GL]
			,ISNULL(sorard.TotalPaidReceivables_FinanceComponent_Table,0.00) - ISNULL(gld.TotalPaidReceivables_FinanceComponent_GL,0.00) [TotalPaidReceivables_FinanceComponent_Difference]
			,ISNULL(sorard.TotalPaidReceivablesviaCash_FinanceComponent_Table,0.00) [TotalPaidReceivablesviaCash_FinanceComponent_Table]
			,ISNULL(gld.TotalPaidReceivablesviaCash_FinanceComponent_GL,0.00) [TotalPaidReceivablesviaCash_FinanceComponent_GL]
			,ISNULL(sorard.TotalPaidReceivablesviaCash_FinanceComponent_Table,0.00) - ISNULL(gld.TotalPaidReceivablesviaCash_FinanceComponent_GL,0.00) [TotalPaidReceivablesviaCash_FinanceComponent_Difference]
			,ISNULL(sorard.TotalPaidReceivablesviaNonCash_FinanceComponent_Table,0.00) [TotalPaidReceivablesviaNonCash_FinanceComponent_Table]
			,ISNULL(gld.TotalPaidReceivablesviaNonCash_FinanceComponent_GL,0.00) [TotalPaidReceivablesviaNonCash_FinanceComponent_GL]
			,ISNULL(sorard.TotalPaidReceivablesviaNonCash_FinanceComponent_Table,0.00) - ISNULL(gld.TotalPaidReceivablesviaNonCash_FinanceComponent_GL,0.00) [TotalPaidReceivablesviaNonCash_FinanceComponent_Difference]
			,ISNULL(sopr.PrepaidReceivables_FinanceComponent_Table,0.00) [PrepaidReceivables_FinanceComponent_Table]
			,ISNULL(gld.PrepaidReceivables_FinanceComponent_GL,0.00) [PrepaidReceivables_FinanceComponent_GL]
			,ISNULL(sopr.PrepaidReceivables_FinanceComponent_Table,0.00) - ISNULL(gld.PrepaidReceivables_FinanceComponent_GL,0.00) [PrepaidReceivables_FinanceComponent_Difference]
			,ISNULL(sord.OutstandingReceivables_FinanceComponent_Table,0.00) [OutstandingReceivables_FinanceComponent_Table]
			,ISNULL(gld.OutstandingReceivables_FinanceComponent_GL,0.00) [OutstandingReceivables_FinanceComponent_GL]
			,ISNULL(sord.OutstandingReceivables_FinanceComponent_Table,0.00) - ISNULL(OutstandingReceivables_FinanceComponent_GL,0.00) [OutstandingReceivables_FinanceComponent_Difference]
			,ISNULL(sord.LongTermReceivables_FinanceComponent_Table,0.00) [LongTermReceivables_FinanceComponent_Table]
			,ISNULL(gld.LongTermReceivables_FinanceComponent_GL,0.00) [LongTermReceivables_FinanceComponent_GL]
			,ISNULL(sord.LongTermReceivables_FinanceComponent_Table,0.00) - ISNULL(gld.LongTermReceivables_FinanceComponent_GL,0.00) [LongTermReceivables_FinanceComponent_Difference]
			/*ResidualsFinanceComponent*/
			,ISNULL(sola.GuaranteedResidual_FinanceComponent_Table,0.00) [GuaranteedResiduals_FinanceComponent_Table]
			,CASE
				WHEN @IncludeGuaranteedResidualinLongTermReceivables = 'False'
				THEN ISNULL(gld.GuaranteedResidual_FinanceComponent_GL,0.00)
				ELSE 0.00
			END [GuaranteedResiduals_FinanceComponent_GL]
			,CASE
				WHEN @IncludeGuaranteedResidualinLongTermReceivables = 'False'
				THEN ISNULL(sola.GuaranteedResidual_FinanceComponent_Table,0.00)
					- ISNULL(gld.GuaranteedResidual_FinanceComponent_GL,0.00)
				ELSE 0.00
			END [GuaranteedResiduals_FinanceComponent_Difference]
			,ISNULL(sola.UnguaranteedResidual_FinanceComponent_Table,0.00) [UnguaranteedResiduals_FinanceComponent_Table]
			,ISNULL(gld.UnguaranteedResidual_FinanceComponent_GL,0.00) [UnguaranteedResiduals_FinanceComponent_GL]
			,ISNULL(sola.UnguaranteedResidual_FinanceComponent_Table,0.00) - ISNULL(gld.UnguaranteedResidual_FinanceComponent_GL,0.00) [UnguaranteedResiduals_FinanceComponent_Difference]
			/*FinancingIncome*/
			,ISNULL(lisi.FinancingTotalIncome_Accounting_Table,0.00) [FinancingTotalIncome_Accounting_Table]
			,ISNULL(lisi.FinancingTotalIncome_Schedule_Table,0.00) [FinancingTotalIncome_Schedule_Table]
			,ISNULL(lisi.FinancingTotalIncome_Accounting_Table,0.00) - ISNULL(lisi.FinancingTotalIncome_Schedule_Table,0.00) [FinancingTotalIncome_AccountingSchedule_Difference]
			,ISNULL(lisi.FinancingTotalEarnedIncome_Table,0.00) [FinancingTotalEarnedIncome_Table]
			,ISNULL(lisi.FinancingEarnedIncome_Table,0.00) [FinancingEarnedIncome_Table]
			,ISNULL(gld.FinancingEarnedIncome_GL,0.00) [FinancingEarnedIncome_GL]
			,ISNULL(lisi.FinancingEarnedIncome_Table,0.00) - ISNULL(gld.FinancingEarnedIncome_GL,0.00) [FinancingEarnedIncome_Difference]
			,ISNULL(lisi.FinancingEarnedResidualIncome_Table,0.00) [FinancingEarnedResidualIncome_Table]
			,ISNULL(gld.FinancingEarnedResidualIncome_GL,0.00) [FinancingEarnedResidualIncome_GL]
			,ISNULL(lisi.FinancingEarnedResidualIncome_Table,0.00) - ISNULL(gld.FinancingEarnedResidualIncome_GL,0.00) [FinancingEarnedResidualIncome_Difference]
			,ISNULL(lisi.FinancingTotalUnearnedIncome_Table,0.00) [FinancingTotalUnearnedIncome_Table]
			,ISNULL(lisi.FinancingUnearnedIncome_Table,0.00) [FinancingUnearnedIncome_Table]
			,ISNULL(gld.FinancingUnearnedIncome_GL,0.00) [FinancingUnearnedIncome_GL]
			,ISNULL(lisi.FinancingUnearnedIncome_Table,0.00) - ISNULL(gld.FinancingUnearnedIncome_GL,0.00) [FinancingUnearnedIncome_Difference]
			,ISNULL(lisi.FinancingUnearnedResidualIncome_Table,0.00) [FinancingUnearnedResidualIncome_Table]
			,ISNULL(gld.FinancingUnearnedResidualIncome_GL,0.00) [FinancingUnearnedResidualIncome_GL]
			,ISNULL(lisi.FinancingUnearnedResidualIncome_Table,0.00) - ISNULL(gld.FinancingUnearnedResidualIncome_GL,0.00) [FinancingUnearnedResidualIncome_Difference]
			,ISNULL(lisi.FinancingRecognizedSuspendedIncome_Table,0.00) [FinancingRecognizedSuspendedIncome_Table]
			,ISNULL(gld.FinancingRecognizedSuspendedIncome_GL,0.00) [FinancingRecognizedSuspendedIncome_GL]
			,ISNULL(lisi.FinancingRecognizedSuspendedIncome_Table,0.00) - ISNULL(gld.FinancingRecognizedSuspendedIncome_GL,0.00) [FinancingRecognizedSuspendedIncome_Difference]
			,ISNULL(lisi.FinancingRecognizedSuspendedResidualIncome_Table,0.00) [FinancingRecognizedSuspendedResidualIncome_Table]
			,ISNULL(gld.FinancingRecognizedSuspendedResidualIncome_GL,0.00) [FinancingRecognizedSuspendedResidualIncome_GL]
			,ISNULL(lisi.FinancingRecognizedSuspendedResidualIncome_Table,0.00) - ISNULL(gld.FinancingRecognizedSuspendedResidualIncome_GL,0.00) [FinancingRecognizedSuspendedResidualIncome_Difference]
			/*Capitalized*/
			,ISNULL(ctd.CapitalizedSalesTax, 0.00) [TotalCapitalizedSalesTax_Table]
			,ISNULL(gld.CapitalizedSalesTax_GL, 0.00) [TotalCapitalizedSalesTax_GL]
			,ISNULL(ctd.CapitalizedSalesTax, 0.00) - ISNULL(gld.CapitalizedSalesTax_GL, 0.00) [TotalCapitalizedSalesTax_Difference]
			,ISNULL(ctd.CapitalizedInterimInterest, 0.00) [TotalCapitalizedInterimInterest_Table]
			,ISNULL(gld.CapitalizedInterimInterest_GL, 0.00) [TotalCapitalizedInterimInterest_GL]
			,ISNULL(ctd.CapitalizedInterimInterest, 0.00) - ISNULL(gld.CapitalizedInterimInterest_GL, 0.00) [TotalCapitalizedInterimInterest_Difference]
			,ISNULL(ctd.CapitalizedInterimRent, 0.00) [TotalCapitalizedInterimRent_Table]
			,ISNULL(gld.CapitalizedInterimRent_GL, 0.00) [TotalCapitalizedInterimRent_GL]
			,ISNULL(ctd.CapitalizedInterimRent, 0.00) - ISNULL(gld.CapitalizedInterimRent_GL, 0.00) [TotalCapitalizedInterimRent_Difference]
			,ISNULL(ctd.CapitalizedAdditionalCharge, 0.00) [TotalCapitalizedAdditionalCharge_Table]
			,ISNULL(gld.CapitalizedAdditionalCharge_GL, 0.00) [TotalCapitalizedAdditionalCharge_GL]
			,ISNULL(ctd.CapitalizedAdditionalCharge, 0.00) - ISNULL(gld.CapitalizedAdditionalCharge_GL, 0.00) [TotalCapitalizedAdditionalCharge_Difference]
			/*FloatRate*/
			,ISNULL(frrd.TotalAmount,0.00) [Total_FloatRateReceivable_Table]
			,ISNULL(frrd.LeaseComponentAmount,0.00) [TotalGLPostedFloatRateReceivables_LeaseComponent_Table]
			,ISNULL(frrd.NonLeaseComponentAmount,0.00) [TotalGLPostedFloatRateReceivables_NonLeaseComponent_Table]
			,ISNULL(gld.TotalGLPosted_GL,0.00) [TotalGLPostedFloatRateReceivables_GL]
			,ABS(ISNULL(frrd.LeaseComponentAmount,0.00) + ISNULL(frrd.NonLeaseComponentAmount,0.00)) - ABS(ISNULL(gld.TotalGLPosted_GL,0.00)) [TotalGLPostedFloatRateReceivables_Difference]
			,ISNULL(frrpd.TotalPaid,0.00) [TotalPaidFloatRateReceivables_Table]
			,ISNULL(frrpd.LeaseComponentTotalPaid,0.00) [TotalPaidFloatRateReceivables_LeaseComponent_Table]
			,ISNULL(frrpd.NonLeaseComponentTotalPaid,0.00) [TotalPaidFloatRateReceivables_NonLeaseComponent_Table]
			,ISNULL(gld.TotalPaid_GL,0.00) [TotalPaidFloatRateReceivables_NonLeaseComponent_GL]
			,ABS(ISNULL(frrpd.LeaseComponentTotalPaid,0.00) + ISNULL(frrpd.NonLeaseComponentTotalPaid,0.00)) - ABS(ISNULL(gld.TotalPaid_GL,0.00)) [TotalPaidFloatRateReceivables_Difference]
			,ISNULL(frrpd.TotalCashPaidAmount,0.00) [TotalCashPaidFloatRateReceivables_Table]
			,ISNULL(frrpd.TotalLeaseComponentCashPaidAmount,0.00) [TotalCashPaidFloatRateReceivables_LeaseComponent_Table]
			,ISNULL(frrpd.TotalNonLeaseComponentCashPaidAmount,0.00) [TotalCashPaidFloatRateReceivables_NonLeaseComponent_Table]
			,ISNULL(gld.TotalCashPaid_GL,0.00) [TotalCashPaidFloatRateReceivables_NonLeaseComponent_GL]
			,ABS(ISNULL(frrpd.TotalLeaseComponentCashPaidAmount,0.00) + ISNULL(frrpd.TotalNonLeaseComponentCashPaidAmount,0.00)) - ABS(ISNULL(gld.TotalCashPaid_GL,0.00)) [TotalCashPaidFloatRateReceivables_Difference]
			,ISNULL(frrpd.TotalNonCashPaidAmount,0.00) [TotalNonCashPaidFloatRateReceivables_Table]
			,ISNULL(frrpd.TotalLeaseComponentNonCashPaidAmount,0.00) [TotalNonCashPaidFloatRateReceivables_LeaseComponent_Table]
			,ISNULL(frrpd.TotalNonLeaseComponentNonCashPaidAmount,0.00) [TotalNonCashPaidFloatRateReceivables_NonLeaseComponent_Table]
			,ISNULL(gld.TotalNonCashPaid_GL,0.00) [TotalNonCashPaidFloatRateReceivables_NonLeaseComponent_GL]
			,ABS(ISNULL(frrpd.TotalLeaseComponentNonCashPaidAmount,0.00) + ISNULL(frrpd.TotalNonLeaseComponentNonCashPaidAmount,0.00)) - ABS(ISNULL(gld.TotalNonCashPaid_GL,0.00)) [TotalNonCashPaidFloatRateReceivables_Difference]
			,ISNULL(frrd.TotalOSARAmount,0.00) [OutstandingFloatRateReceivables_Table]
			,ISNULL(frrd.LeaseComponentOSARAmount,0.00) [OutstandingFloatRateReceivables_LeaseComponent_Table]
			,ISNULL(frrd.NonLeaseComponentOSARAmount,0.00) [OutstandingFloatRateReceivables_NonLeaseComponent_Table]
			,ISNULL(gld.OSAR_GL,0.00) [OutstandingFloatRateReceivables_GL]
			,ABS(ISNULL(frrd.LeaseComponentOSARAmount,0.00) + ISNULL(frrd.NonLeaseComponentOSARAmount,0.00)) - ABS(ISNULL(gld.OSAR_GL,0.00)) [OutstandingFloatRateReceivables_Difference]
			,ISNULL(frrd.TotalPrepaidAmount,0.00) [PrepaidFloatRateReceivables_Table]
			,ISNULL(frrd.LeaseComponentPrepaidAmount,0.00) [PrepaidFloatRateReceivables_LeaseComponent_Table]
			,ISNULL(frrd.NonLeaseComponentPrepaidAmount,0.00) [PrepaidFloatRateReceivables_NonLeaseComponent_Table]
			,ISNULL(gld.TotalPrePaid_GL,0.00) [PrepaidFloatRateReceivables_GL]
			,ABS(ISNULL(frrd.LeaseComponentPrepaidAmount,0.00) + ISNULL(frrd.NonLeaseComponentPrepaidAmount,0.00)) - ABS(ISNULL(gld.TotalPrePaid_GL,0.00)) [PrepaidFloatRateReceivables_Difference]
			,ISNULL(frid.Income_Schedule,0.00) [TotalFloatRateIncome_Scheduled]
			,ISNULL(frid.Income_Accounting,0.00) [TotalFloatRateIncome_Accounting]
			,ABS(ISNULL(frid.Income_Schedule,0.00)) - ABS( ISNULL(frid.Income_Accounting,0.00))			[TotalFloatRateIncome_AccountingAndSchedule_Difference]
			,ISNULL(frid.Income_GLPosted,0.00) [Total_GLPostedFloatRateIncome_Table]
			,ISNULL(gld.TotalFloatRateIncome_GL,0.00) [Total_GLPostedFloatRateIncome_GL]
			,ABS(ISNULL(frid.Income_GLPosted,0.00)) - ABS(ISNULL(gld.TotalFloatRateIncome_GL,0.00)) [TotalGLPostedFloatRateIncome_Difference]
			,ISNULL(frid.Income_Suspended,0.00) [TotalSuspendedIncome_Table]
			,ISNULL(gld.TotalSuspendedFloatRateIncome_GL,0.00) [TotalSuspendedIncome_GL]
			,ABS(ISNULL(frid.Income_Suspended,0.00)) - ABS(ISNULL(gld.TotalSuspendedFloatRateIncome_GL,0.00)) [TotalSuspendedIncome_Difference]
			,ABS(ISNULL(frid.Income_Accrued,0.00) - (ISNULL(frrd.LeaseComponentAmount,0.00) + ISNULL(frrd.NonLeaseComponentAmount,0.00))) [TotalAccruedIncome_Table]
			,ISNULL(gld.TotalAccruedFloatRateIncome_GL,0.00) [TotalAccruedIncome_GL]
			,ABS(ISNULL(frid.Income_Accrued,0.00) - (ISNULL(frrd.LeaseComponentAmount,0.00) + ISNULL(frrd.NonLeaseComponentAmount,0.00))) - ABS(ISNULL(gld.TotalAccruedFloatRateIncome_GL,0.00)) [TotalAccruedIncome_Difference]
			/*InterimRent*/
			,ISNULL(soir.TotalInterimRentAmount,0.00) [TotalAmount_InterimRentReceivables_Table]
			,CASE 
				WHEN @IsRentSharing = 1 
				THEN ISNULL(sovrs.VendorInterimRentSharingAmount,0.00) 
				ELSE 0.00 
			END [VendorInterimRentSharingAmount_Table]
			,ISNULL(soir.TotalGLPosted_InterimRentReceivables_Table,0.00) [TotalGLPosted_InterimRentReceivables_Table]
			,ISNULL(gld.TotalGLPosted_InterimRentReceivables_GL,0.00) [TotalGLPosted_InterimRentReceivables_GL]
			,ISNULL(soir.TotalGLPosted_InterimRentReceivables_Table,0.00) - ISNULL(gld.TotalGLPosted_InterimRentReceivables_GL,0.00)	[TotalGLPosted_InterimRentReceivables_Difference]
			,ISNULL(soir.TotalInterimRentAmount,0.00) - ISNULL(soir.TotalInterimRentBalanceAmount,0.00) [TotalPaid_InterimRentReceivables_Table]
			,ISNULL(gld.TotalPaid_InterimRentReceivables_GL,0.00) [TotalPaid_InterimRentReceivables_GL]
			,ISNULL(soir.TotalInterimRentAmount,0.00) - ISNULL(soir.TotalInterimRentBalanceAmount,0.00) - ISNULL(gld.TotalPaid_InterimRentReceivables_GL,0.00) [TotalPaid_InterimRentReceivables_Difference]
			,ISNULL(soirard.TotalPaidviaCash_InterimRentReceivables_Table,0.00) [TotalPaidviaCash_InterimRentReceivables_Table]
			,ISNULL(gld.TotalPaidviaCash_InterimRentReceivables_GL,0.00) [TotalPaidviaCash_InterimRentReceivables_GL]
			,ISNULL(soirard.TotalPaidviaCash_InterimRentReceivables_Table,0.00) - ISNULL(gld.TotalPaidviaCash_InterimRentReceivables_GL,0.00) [TotalPaidviaCash_InterimRentReceivables_Difference]
			,ISNULL(soirard.TotalPaidviaNonCash_InterimRentReceivables_Table,0.00) [TotalPaidviaNonCash_InterimRentReceivables_Table]
			,ISNULL(gld.TotalPaidviaNonCash_InterimRentReceivables_GL,0.00) [TotalPaidviaNonCash_InterimRentReceivables_GL]
			,ISNULL(soirard.TotalPaidviaNonCash_InterimRentReceivables_Table,0.00) - ISNULL(gld.TotalPaidviaNonCash_InterimRentReceivables_GL,0.00) [TotalPaidviaNonCash_InterimRentReceivables_Difference]
			,ISNULL(sopir.TotalPrepaid_InterimRentReceivables_Table,0.00) [TotalPrepaid_InterimRentReceivables_Table]
			,ISNULL(gld.TotalPrepaid_InterimRentReceivables_GL,0.00) [TotalPrepaid_InterimRentReceivables_GL]
			,ISNULL(sopir.TotalPrepaid_InterimRentReceivables_Table,0.00) - ISNULL(gld.TotalPrepaid_InterimRentReceivables_GL,0.00) [TotalPrepaid_InterimRentReceivables_Difference]
			,ISNULL(soir.TotalOutstandingInterimRentReceivables_Table,0.00) [TotalOutstanding_InterimRentReceivables_Table]
			,ISNULL(gld.TotalOutstanding_InterimRentReceivables_GL,0.00) [TotalOutstanding_InterimRentReceivables_GL]
			,ISNULL(soir.TotalOutstandingInterimRentReceivables_Table,0.00) - ISNULL(gld.TotalOutstanding_InterimRentReceivables_GL,0.00) [TotalOutstanding_InterimRentReceivables_Difference]
			,ISNULL(ilis.TotalScheduleRentalIncome_InterimRentIncome_Table,0.00) [TotalScheduleRentalIncome_InterimRentIncome_Table]
			,ISNULL(ilis.TotalAccountingRentalIncome_InterimRentIncome_Table,0.00) [TotalAccountingRentalIncome_InterimRentIncome_Table]
			,ISNULL(ilis.GLPosted_InterimRentIncome_Table,0.00) [GLPosted_InterimRentIncome_Table]
			,ISNULL(gld.GLPosted_InterimRentIncome_GL,0.00) [GLPosted_InterimRentIncome_GL]
			,ISNULL(ilis.GLPosted_InterimRentIncome_Table,0.00) - ISNULL(gld.GLPosted_InterimRentIncome_GL,0.00) [GLPosted_InterimRentIncome_Difference]
			,ISNULL(ilis.TotalCapitalizedIncome_InterimRentIncome_Table,0.00) [TotalCapitalizedIncome_InterimRentIncome_Table]
			,ISNULL(gld.TotalCapitalizedIncome_InterimRentIncome_GL,0.00) [TotalCapitalizedIncome_InterimRentIncome_GL]
			,ISNULL(ilis.TotalCapitalizedIncome_InterimRentIncome_Table,0.00) - ISNULL(gld.TotalCapitalizedIncome_InterimRentIncome_GL,0.00) [TotalCapitalizedIncome_InterimRentIncome_Difference]
			,CASE
				WHEN @DeferInterimRentIncomeRecognition = 'False' 
					AND @DeferInterimRentIncomeRecognitionForSingleInstallment = 'False'
				THEN (ISNULL(ilis.TotalAccountingRentalIncome_InterimRentIncome_Table,0.00) - ISNULL(ilis.TotalCapitalizedIncome_InterimRentIncome_Table,0.00)) - (ISNULL(soir.TotalInterimRentAmount,0.00) - ISNULL(sovrs.VendorInterimRentSharingAmount,0.00))
				ELSE 0.00
			END [TotalInterimRent_IncomeandReceivable_Difference]
			,ISNULL(iob.DeferInterimRentIncome_Table,0.00) [DeferInterimRentIncome_Table]
			,ISNULL(gld.DeferInterimRentIncome_GL,0.00) [DeferInterimRentIncome_GL]
			,ISNULL(iob.DeferInterimRentIncome_Table,0.00) - ISNULL(gld.DeferInterimRentIncome_GL,0.00) [DeferInterimRentIncome_Difference]
			/*InterimInterest*/
			,ISNULL(soir.TotalInterimInterestAmount,0.00) [TotalAmount_InterimInterestReceivables_Table]
			,ISNULL(soir.TotalGLPosted_InterimInterestReceivables_Table,0.00) [TotalGLPosted_InterimInterestReceivables_Table]
			,ISNULL(gld.TotalGLPosted_InterimInterestReceivables_GL,0.00) [TotalGLPosted_InterimInterestReceivables_GL]
			,ISNULL(soir.TotalGLPosted_InterimInterestReceivables_Table,0.00) - ISNULL(gld.TotalGLPosted_InterimInterestReceivables_GL,0.00)	[TotalGLPosted_InterimInterestReceivables_Difference]
			,ISNULL(soir.TotalInterimInterestAmount,0.00) - ISNULL(soir.TotalInterimInterestBalanceAmount,0.00) [TotalPaid_InterimInterestReceivables_Table]
			,ISNULL(gld.TotalPaid_InterimInterestReceivables_GL,0.00) [TotalPaid_InterimInterestReceivables_GL]
			,ISNULL(soir.TotalInterimInterestAmount,0.00) - ISNULL(soir.TotalInterimInterestBalanceAmount,0.00) - ISNULL(gld.TotalPaid_InterimInterestReceivables_GL,0.00) [TotalPaid_InterimInterestReceivables_Difference]
			,ISNULL(soirard.TotalPaidviaCash_InterimInterestReceivables_Table,0.00) [TotalPaidviaCash_InterimInterestReceivables_Table]
			,ISNULL(gld.TotalPaidviaCash_InterimInterestReceivables_GL,0.00) [TotalPaidviaCash_InterimInterestReceivables_GL]
			,ISNULL(soirard.TotalPaidviaCash_InterimInterestReceivables_Table,0.00) - ISNULL(gld.TotalPaidviaCash_InterimInterestReceivables_GL,0.00) [TotalPaidviaCash_InterimInterestReceivables_Difference]
			,ISNULL(soirard.TotalPaidviaNonCash_InterimInterestReceivables_Table,0.00) [TotalPaidviaNonCash_InterimInterestReceivables_Table]
			,ISNULL(gld.TotalPaidviaNonCash_InterimInterestReceivables_GL,0.00) [TotalPaidviaNonCash_InterimInterestReceivables_GL]
			,ISNULL(soirard.TotalPaidviaNonCash_InterimInterestReceivables_Table,0.00) - ISNULL(gld.TotalPaidviaNonCash_InterimInterestReceivables_GL,0.00) [TotalPaidviaNonCash_InterimInterestReceivables_Difference]
			,ISNULL(sopir.TotalPrepaid_InterimInterestReceivables_Table,0.00) [TotalPrepaid_InterimInterestReceivables_Table]
			,ISNULL(gld.TotalPrepaid_InterimInterestReceivables_GL,0.00) [TotalPrepaid_InterimInterestReceivables_GL]
			,ISNULL(sopir.TotalPrepaid_InterimInterestReceivables_Table,0.00) - ISNULL(gld.TotalPrepaid_InterimInterestReceivables_GL,0.00) [TotalPrepaid_InterimInterestReceivables_Difference]
			,ISNULL(soir.TotalOutstandingInterimInterestReceivables_Table,0.00) [TotalOutstanding_InterimInterestReceivables_Table]
			,ISNULL(gld.TotalOutstanding_InterimInterestReceivables_GL,0.00) [TotalOutstanding_InterimInterestReceivables_GL]
			,ISNULL(soir.TotalOutstandingInterimInterestReceivables_Table,0.00) - ISNULL(gld.TotalOutstanding_InterimInterestReceivables_GL,0.00) [TotalOutstanding_InterimInterestReceivables_Difference]
			,ISNULL(ilis.TotalScheduleIncome_InterimInterestIncome_Table,0.00) [TotalScheduleIncome_InterimInterestIncome_Table]
			,ISNULL(ilis.TotalAccountingIncome_InterimInterestIncome_Table,0.00) [TotalAccountingIncome_InterimInterestIncome_Table]
			,ISNULL(ilis.GLPosted_InterimInterestIncome_Table,0.00) [GLPosted_InterimInterestIncome_Table]
			,ISNULL(gld.GLPosted_InterimInterestIncome_GL,0.00) [GLPosted_InterimInterestIncome_GL]
			,ISNULL(ilis.GLPosted_InterimInterestIncome_Table,0.00) - ISNULL(gld.GLPosted_InterimInterestIncome_GL,0.00) [GLPosted_InterimInterestIncome_Difference]
			,ISNULL(ilis.TotalCapitalizedIncome_InterimInterestIncome_Table,0.00) [TotalCapitalizedIncome_InterimInterestIncome_Table]
			,ISNULL(gld.TotalCapitalizedIncome_InterimInterestIncome_GL,0.00) [TotalCapitalizedIncome_InterimInterestIncome_GL]
			,ISNULL(ilis.TotalCapitalizedIncome_InterimInterestIncome_Table,0.00) - ISNULL(gld.TotalCapitalizedIncome_InterimInterestIncome_GL,0.00) [TotalCapitalizedIncome_InterimInterestIncome_Difference]
			,CASE
				WHEN @DeferInterimInterestIncomeRecognition = 'False' 
					AND @DeferInterimInterestIncomeRecognitionForSingleInstallment = 'False'
				THEN ISNULL(ilis.TotalAccountingIncome_InterimInterestIncome_Table,0.00) - ISNULL(ilis.TotalCapitalizedIncome_InterimInterestIncome_Table,0.00) - ISNULL(soir.TotalInterimInterestAmount,0.00) 
				ELSE 0.00
			END [TotalInterimInterest_IncomeandReceivable_Difference]
			,ISNULL(iob.AccruedInterimInterestIncome_Table,0.00) [AccruedInterimInterestIncome_Table]
			,ISNULL(gld.AccruedInterimInterestIncome_GL,0.00) [AccruedInterimInterestIncome_GL]
			,ISNULL(iob.AccruedInterimInterestIncome_Table,0.00) - ISNULL(gld.AccruedInterimInterestIncome_GL,0.00) [AccruedInterimInterestIncome_Difference]
			/*WriteDown*/
			,ISNULL(wdi.GrossWriteDown_Table,0.00) [GrossWriteDown_Table]
			,ISNULL(gld.GrossWriteDown_GL,0.00) [GrossWriteDown_GL]
			,ISNULL(wdi.GrossWriteDown_Table,0.00) - ISNULL(gld.GrossWriteDown_GL,0.00) [GrossWriteDown_Difference]
			,ISNULL(wdi.WriteDownRecovered_Table,0.00) [WriteDownRecovered_Table]
			,ISNULL(gld.WriteDownRecovered_GL,0.00) [WriteDownRecovered_GL]
			,ISNULL(wdi.WriteDownRecovered_Table,0.00) - ISNULL(gld.WriteDownRecovered_GL,0.00) [WriteDownRecovered_Difference]
			,ISNULL(wdi.GrossWriteDown_Table,0.00) - ISNULL(wdi.WriteDownRecovered_Table,0.00) [NetWriteDown_Table]
			,ISNULL(gld.GrossWriteDown_GL,0.00) - ISNULL(gld.WriteDownRecovered_GL,0.00) [NetWriteDown_GL]
			,(ISNULL(wdi.GrossWriteDown_Table,0.00) - ISNULL(wdi.WriteDownRecovered_Table,0.00)) - (ISNULL(gld.GrossWriteDown_GL,0.00) - ISNULL(gld.WriteDownRecovered_GL,0.00)) [NetWriteDown_Difference]
			/*ChargeOff*/
			,ISNULL(coi.ChargeOffExpense_LC_Table, 0.00) AS [ChargeOffExpense_LeaseComponent_Table]
			,ISNULL(gld.ChargeOffExpense_GL, 0.00) AS [ChargeOffExpense_LeaseComponent_GL]
			,ISNULL(coi.ChargeOffExpense_LC_Table, 0.00) - ISNULL(gld.ChargeOffExpense_GL, 0.00) AS [ChargeOffExpense_LeaseComponent_Difference]
			,ISNULL(coi.ChargeOffExpense_NLC_Table, 0.00) AS [ChargeOffExpense_NonLeaseComponent_Table]
			,ISNULL(gld.FinancingChargeOffExpense_GL, 0.00) AS [ChargeOffExpense_NonLeaseComponent_GL]
			,ISNULL(coi.ChargeOffExpense_NLC_Table, 0.00) - ISNULL(gld.FinancingChargeOffExpense_GL, 0.00) AS [ChargeOffExpense_NonLeaseComponent_Difference]
			,ISNULL(coi.ChargeOffExpense, 0.00) AS [TotalChargeoffAmount_Table]
			,ISNULL(coi.ChargeOffExpense_LC_Table, 0.00) + ISNULL(coi.ChargeOffExpense_NLC_Table, 0.00) AS [TotalChargeoffAmount_Calculation]
			,ISNULL(coi.ChargeOffExpense, 0.00) - (ISNULL(coi.ChargeOffExpense_LC_Table, 0.00) + ISNULL(coi.ChargeOffExpense_NLC_Table, 0.00)) AS [TotalChargeoffAmountVSLCAndNLC]
			,IIF(@IsGainPresent = 1, ISNULL(coi.ChargeOffRecovery_LC_Table, 0.00), ISNULL(coi.ChargeOffRecovery_LC_Table, 0.00) - ISNULL(sorard.ChargeOffGainOnRecovery_LeaseComponent_Table, 0.00))  AS [ChargeOffRecovery_LeaseComponent_Table]
			,ISNULL(gld.ChargeOffRecovery_GL, 0.00) AS [ChargeOffRecovery_LeaseComponent_GL]
			,IIF(@IsGainPresent = 1, ISNULL(coi.ChargeOffRecovery_LC_Table, 0.00), ISNULL(coi.ChargeOffRecovery_LC_Table, 0.00) - ISNULL(sorard.ChargeOffGainOnRecovery_LeaseComponent_Table, 0.00)) - ISNULL(gld.ChargeOffRecovery_GL, 0.00) AS [ChargeOffRecovery_LeaseComponent_Difference]
			,IIF(@IsGainPresent = 1, ISNULL(coi.ChargeOffRecovery_NLC_Table, 0.00), ISNULL(coi.ChargeOffRecovery_NLC_Table, 0.00) - ISNULL(sorard.ChargeOffGainOnRecovery_NonLeaseComponent_Table, 0.00)) AS [ChargeOffRecovery_NonLeaseComponent_Table]
			,ISNULL(gld.FinancingChargeOffRecovery_GL, 0.00) AS [ChargeOffRecovery_NonLeaseComponent_GL]
			,IIF(@IsGainPresent = 1, ISNULL(coi.ChargeOffRecovery_NLC_Table, 0.00), ISNULL(coi.ChargeOffRecovery_NLC_Table, 0.00) - ISNULL(sorard.ChargeOffGainOnRecovery_NonLeaseComponent_Table, 0.00)) - ISNULL(gld.FinancingChargeOffRecovery_GL, 0.00) AS [ChargeOffRecovery_NonLeaseComponent_Difference]
			,IIF(@IsGainPresent = 1, ISNULL(coi.GainOnRecovery_LC_Table, 0.00), ISNULL(sorard.ChargeOffGainOnRecovery_LeaseComponent_Table, 0.00)) AS [ChargeOffGainOnRecovery_LeaseComponent_Table]
			,ISNULL(gld.ChargeOffGainOnRecovery_GL, 0.00) AS [ChargeOffGainOnRecovery_LeaseComponent_GL]
			,IIF(@IsGainPresent = 1, ISNULL(coi.GainOnRecovery_LC_Table, 0.00), ISNULL(sorard.ChargeOffGainOnRecovery_LeaseComponent_Table, 0.00)) - ISNULL(gld.ChargeOffGainOnRecovery_GL, 0.00) AS [ChargeOffGainOnRecovery_LeaseComponent_Difference]
			,IIF(@IsGainPresent = 1, ISNULL(coi.GainOnRecovery_NLC_Table, 0.00), ISNULL(sorard.ChargeOffGainOnRecovery_NonLeaseComponent_Table , 0.00)) AS [ChargeOffGainOnRecovery_NonLeaseComponent_Table]
			,ISNULL(gld.FinancingChargeOffGainOnRecovery_GL, 0.00) AS [ChargeOffGainOnRecovery_NonLeaseComponent_GL]
			,IIF(@IsGainPresent = 1, ISNULL(coi.GainOnRecovery_NLC_Table, 0.00), ISNULL(sorard.ChargeOffGainOnRecovery_NonLeaseComponent_Table, 0.00)) - ISNULL(gld.FinancingChargeOffGainOnRecovery_GL, 0.00) AS [ChargeOffGainOnRecovery_NonLeaseComponent_Difference]
			,ISNULL(coi.ChargeOffRecovery, 0.00) AS [TotalRecoveryAndGain_Table] 
			,IIF(@IsGainPresent = 1, ISNULL(coi.ChargeOffRecovery_LC_Table, 0.00), ISNULL(coi.ChargeOffRecovery_LC_Table, 0.00) - ISNULL(sorard.ChargeOffGainOnRecovery_LeaseComponent_Table, 0.00)) + IIF(@IsGainPresent = 1, ISNULL(coi.ChargeOffRecovery_NLC_Table, 0.00), ISNULL(coi.ChargeOffRecovery_NLC_Table, 0.00) - ISNULL(sorard.ChargeOffGainOnRecovery_NonLeaseComponent_Table, 0.00)) + IIF(@IsGainPresent = 1, ISNULL(coi.GainOnRecovery_LC_Table, 0.00) +  ISNULL(coi.GainOnRecovery_NLC_Table, 0.00), ISNULL(sorard.ChargeOffGainOnRecovery_LeaseComponent_Table, 0.00) + ISNULL(sorard.ChargeOffGainOnRecovery_NonLeaseComponent_Table, 0.00)) AS [TotalRecoveryAndGain_Calculation] 
			,ISNULL(coi.ChargeOffRecovery, 0.00) - (IIF(@IsGainPresent = 1, ISNULL(coi.ChargeOffRecovery_LC_Table, 0.00), ISNULL(coi.ChargeOffRecovery_LC_Table, 0.00) - ISNULL(sorard.ChargeOffGainOnRecovery_LeaseComponent_Table, 0.00)) + IIF(@IsGainPresent = 1, ISNULL(coi.ChargeOffRecovery_NLC_Table, 0.00), ISNULL(coi.ChargeOffRecovery_NLC_Table, 0.00) - ISNULL(sorard.ChargeOffGainOnRecovery_NonLeaseComponent_Table, 0.00)) + IIF(@IsGainPresent = 1, ISNULL(coi.GainOnRecovery_LC_Table, 0.00) +  ISNULL(coi.GainOnRecovery_NLC_Table, 0.00), ISNULL(sorard.ChargeOffGainOnRecovery_LeaseComponent_Table, 0.00) + ISNULL(sorard.ChargeOffGainOnRecovery_NonLeaseComponent_Table, 0.00))) AS [TotalRecoveryAndGainVSRecoveryAndGainLCAndNLC]
			/*UnApplied*/
			,ISNULL(sort.ReceiptBalance_Amount,0.00) + ISNULL(sop.PayablesBalance_Amount,0.00) [UnAppliedCash_Table]
			,ISNULL(gld.ContractUnAppliedAR_GL,0.00) - ISNULL(rrgld.Refunds_GL,0.00) [UnAppliedCash_GL]
			,(ISNULL(sort.ReceiptBalance_Amount,0.00) + ISNULL(sop.PayablesBalance_Amount,0.00)) - (ISNULL(gld.ContractUnAppliedAR_GL,0.00) - ISNULL(rrgld.Refunds_GL,0.00)) [UnAppliedCash_Difference]			
			/*SalesTax*/
			,ISNULL(rtxd.GLPostedTaxes, 0.00) - ISNULL(stxd.GLPosted_CashRem_NonCash, 0.00) [TotalGLPostedSalesTaxReceivables_Table]
			,ISNULL(gld.GLPostedSalesTaxReceivable_GL, 0.00) [TotalGLPostedSalesTaxReceivable_GL]
			,ABS(ABS(ISNULL(rtxd.GLPostedTaxes, 0.00)) - ABS(ISNULL(stxd.GLPosted_CashRem_NonCash, 0.00))) - ABS(ISNULL (gld.GLPostedSalesTaxReceivable_GL, 0.00)) [TotalGLPosted_SalesTaxReceivable_Difference]
			,ISNULL(stxd.TotalPaid_taxes, 0.00) - ISNULL(stxd.Paid_CashRem_NonCash, 0.00) [TotalPaid_SalesTaxReceivables_Table]
			,ISNULL(gld.TotalPaid_SalesTaxReceivables_GL, 0.00) [TotalPaid_SalesTaxReceivables_GL]
			,ISNULL(stxd.TotalPaid_taxes, 0.00) - ISNULL(stxd.Paid_CashRem_NonCash, 0.00) - ISNULL(gld.TotalPaid_SalesTaxReceivables_GL, 0.00) [TotalPaid_SalesTaxReceivables_Difference]
			,ISNULL(stxd.PaidTaxesviaCash, 0.00) [TotalPaidviacash_SalesTaxReceivables_Table]
			,ISNULL(gld.Paid_SalesTaxReceivablesviaCash_GL, 0.00) [TotalPaidviacash_SalesTaxReceivables_GL]
			,ISNULL(stxd.PaidTaxesviaCash, 0.00) - ISNULL(gld.Paid_SalesTaxReceivablesviaCash_GL, 0.00) [TotalPaidviacash_SalesTaxReceivables_Difference]
			,ISNULL(stxd.PaidTaxesviaNonCash, 0.00) - ISNULL(stxd.GLPosted_CashRem_NonCash, 0.00) [TotalPaidvianoncash_SalesTaxReceivables_Table]
			,ISNULL(gld.Paid_SalesTaxReceivablesviaNonCash_GL, 0.00) [TotalPaidvianoncash_SalesTaxReceivables_GL]
			,ISNULL(stxd.PaidTaxesviaNonCash, 0.00) - ISNULL(stxd.GLPosted_CashRem_NonCash, 0.00) - ISNULL  (gld.Paid_SalesTaxReceivablesviaNonCash_GL, 0.00) [TotalPaidvianoncash_SalesTaxReceivables_Difference]
			,ISNULL(stxd.TotalPrePaid_Taxes, 0.00) [TotalPrepaid_SalesTaxReceivables_Table]
			,ISNULL(gld.PrePaidTaxes_GL, 0.00) - ISNULL(gld.PrePaidTaxReceivable_GL, 0.00) [TotalPrepaid_SalesTaxReceivables_GL]
			,ABS(ISNULL(stxd.TotalPrePaid_Taxes, 0.00)) - ABS(ISNULL(gld.PrePaidTaxes_GL, 0.00) - ISNULL(gld.PrePaidTaxReceivable_GL, 0.00)) [TotalPrepaid_SalesTaxReceivables_Difference]
			,ISNULL(rtxd.OutStandingTaxes, 0.00) [TotalOutstanding_SalesTaxReceivables_Table]
			,ISNULL(gld.TaxReceivablePosted_GL, 0.00) - ISNULL(gld.TaxReceivablesPaid_GL, 0.00) [TotalOutstanding_SalesTaxReceivables_GL]
			,ABS(ISNULL(rtxd.OutStandingTaxes, 0.00)) - ABS(ISNULL(gld.TaxReceivablePosted_GL, 0.00) - ISNULL(gld.TaxReceivablesPaid_GL, 0.00)) [TotalOutstanding_SalesTaxReceivables_Difference]
			/*FunderOwned*/
			,ABS(ABS(ISNULL(frd.GLPostedFO,0.00)) - ABS(ISNULL(frard.NonCashAmountFO,0.00))) [TotalGLPosted_FunderOwned_Receivables]
			,ABS(ABS(ISNULL(frt.FunderRemittingSalesTaxGLPosted,0.00)) - ABS(ISNULL(stn.FunderPortionNonCash,0.00))) [TotalGLPosted_FunderOwned_SalesTax]
			,ABS(ABS(ISNULL(frd.GLPostedFO,0.00)) - ABS(ISNULL(frard.NonCashAmountFO,0.00))) + ABS(ABS(ISNULL(frt.FunderRemittingSalesTaxGLPosted,0.00)) - ABS(ISNULL(stn.FunderPortionNonCash,0.00))) [TotalGLPosted_FunderOwned_Table]
			,ABS(ISNULL(gld.TotalGLPosted_FunderOwned_GL,0.00)) [TotalGLPosted_FunderOwned_GL]
			,(ABS(ABS(ISNULL(frd.GLPostedFO,0.00)) - ABS(ISNULL(frard.NonCashAmountFO,0.00))) + ABS(ABS(ISNULL(frt.FunderRemittingSalesTaxGLPosted,0.00)) - ABS(ISNULL(stn.FunderPortionNonCash,0.00)))) - ABS(ISNULL(gld.TotalGLPosted_FunderOwned_GL,0.00)) [TotalGLPosted_FunderOwned_Difference]
			,ISNULL(frard.PaidCashFO,0.00) [TotalPaidCash_FunderOwned_Receivables]
			,ISNULL(frard.SalesTaxCashAppliedFO,0.00) [TotalPaidCash_FunderOwned_SalesTax]
			,ISNULL(frard.PaidCashFO,0.00) + ISNULL(frard.SalesTaxCashAppliedFO,0.00) [TotalPaidCash_FunderOwned_Table]
			,ISNULL(gld.TotalPaidCash_FunderOwned_GL,0.00) [TotalPaidCash_FunderOwned_GL]
			,(ISNULL(frard.PaidCashFO,0.00) + ISNULL(frard.SalesTaxCashAppliedFO,0.00)) - ISNULL(gld.TotalPaidCash_FunderOwned_GL,0.00) [TotalPaidCash_FunderOwned_Difference]
			,ABS(ISNULL(frard.PaidNonCashFO,0.00)) - ABS(ISNULL(frard.NonCashAmountFO,0.00)) [TotalPaidNonCash_FunderOwned_Receivables]
			,ABS(ISNULL(frard.SalesTaxNonCashAppliedFO,0.00)) - ABS(ISNULL(frard.NonCashAmountFO,0.00)) [TotalPaidNonCash_FunderOwned_SalesTax]
			,(ABS(ISNULL(frard.PaidNonCashFO,0.00)) - ABS(ISNULL(frard.NonCashAmountFO,0.00))) + (ABS(ISNULL(frard.SalesTaxNonCashAppliedFO,0.00)) - ABS(ISNULL(frard.NonCashAmountFO,0.00))) [TotalPaidNonCash_FunderOwned_Table]
			,ISNULL(gld.TotalPaidNonCash_FunderOwned_GL,0.00) [TotalPaidNonCash_FunderOwned_GL]
			,((ABS(ISNULL(frard.PaidNonCashFO,0.00)) - ABS(ISNULL(frard.NonCashAmountFO,0.00))) + (ABS(ISNULL(frard.SalesTaxNonCashAppliedFO,0.00)) - ABS(ISNULL(frard.NonCashAmountFO,0.00)))) - ISNULL(gld.TotalPaidNonCash_FunderOwned_GL,0.00) [TotalPaidNonCash_FunderOwned_Difference]
			,ISNULL(frd.OutstandingFO,0.00) [TotalOSAR_FunderOwned_Receivables]
			,ISNULL(frt.FunderRemittingSalesTaxOSAR,0.00) [TotalOSAR_FunderOwned_SalesTax]
			,ISNULL(frd.OutstandingFO,0.00) + ISNULL(frt.FunderRemittingSalesTaxOSAR,0.00) [TotalOSAR_FunderOwned_Table]
			,ISNULL(gld.TotalOutstanding_FunderOwned_GL,0.00) [TotalOutstanding_FunderOwned_GL]
			,ISNULL(frd.OutstandingFO,0.00) + ISNULL(frt.FunderRemittingSalesTaxOSAR,0.00) - ISNULL(gld.TotalOutstanding_FunderOwned_GL,0.00) [TotalOSAR_FunderOwned_Difference]
			,ISNULL(frd.PrepaidFO,0.00) [TotalPrepaid_FunderOwned_Receivables]
			,ABS(ISNULL(frt.FunderRemittingSalesTaxPrepaid,0.00)) [TotalPrepaid_FunderOwned_SalesTax]
			,ISNULL(frd.PrepaidFO,0.00) + ABS(ISNULL(frt.FunderRemittingSalesTaxPrepaid,0.00)) [TotalPrepaid_FunderOwned_Table]
			,ISNULL(gld.TotalPrepaid_FunderOwned_GL,0.00) [TotalPrepaid_FunderOwned_GL]
			,ISNULL(frd.PrepaidFO,0.00) + ABS(ISNULL(frt.FunderRemittingSalesTaxPrepaid,0.00)) - ISNULL(gld.TotalPrepaid_FunderOwned_GL,0.00) [TotalPrepaid_FunderOwned_Difference]
			,ISNULL(frt.LessorRemittingSalesTaxGLPosted,0.00) - ISNULL(stn.FunderPortionNonCash,0.00) [TotalGLPosted_FunderOwned_LessorRemit_SalesTax_Table]
			,ISNULL(gld.TotalGLPosted_FunderOwned_LessorRemit_SalesTax_GL,0.00) [TotalGLPosted_FunderOwned_LessorRemit_SalesTax_GL]
			,(ISNULL(frt.LessorRemittingSalesTaxGLPosted,0.00) - ISNULL(stn.FunderPortionNonCash,0.00)) - ISNULL(gld.TotalGLPosted_FunderOwned_LessorRemit_SalesTax_GL,0.00) [TotalGLPosted_FunderOwned_LessorRemit_SalesTax_Difference]
			,ISNULL(frard.LessorSalesTaxCashAppliedFO,0.00) [TotalPaidCash_FunderOwned_LessorRemit_SalesTax_Table]
			,ISNULL(gld.TotalPaidCash_FunderOwned_LessorRemit_SalesTax_GL,0.00) [TotalPaidCash_FunderOwned_LessorRemit_SalesTax_GL]
			,ISNULL(frard.LessorSalesTaxCashAppliedFO,0.00) - ISNULL(gld.TotalPaidCash_FunderOwned_LessorRemit_SalesTax_GL,0.00) [TotalPaidCash_FunderOwned_LessorRemit_SalesTax_Difference]
			,ISNULL(frard.LessorSalesTaxNonCashAppliedFO,0.00) [TotalPaidNonCash_FunderOwned_LessorRemit_SalesTax_Table]
			,ISNULL(gld.TotalPaidNonCash_FunderOwned_LessorRemit_SalesTax_GL,0.00) [TotalPaidNonCash_FunderOwned_LessorRemit_SalesTax_GL]
			,ISNULL(frard.LessorSalesTaxNonCashAppliedFO,0.00) - ISNULL(gld.TotalPaidNonCash_FunderOwned_LessorRemit_SalesTax_GL,0.00) [TotalPaidNonCash_FunderOwned_LessorRemit_SalesTax_Difference]
			,ISNULL(frt.LessorRemittingSalesTaxOSAR,0.00) [TotalOSAR_FunderOwned_LessorRemit_SalesTax_Table]
			,ISNULL(gld.TotalOutstanding_FunderOwned_LessorRemit_SalesTax_GL,0.00) [TotalOSAR_FunderOwned_LessorRemit_SalesTax_GL]
			,ISNULL(frt.LessorRemittingSalesTaxOSAR,0.00) - ISNULL(gld.TotalOutstanding_FunderOwned_LessorRemit_SalesTax_GL,0.00) [TotalOSAR_FunderOwned_LessorRemit_SalesTax_Difference]
			,ISNULL(frt.LessorRemittingSalesTaxPrepaid,0.00) [TotalPrepaid_FunderOwned_LessorRemit_SalesTax_Table]
			,ISNULL(gld.TotalPrepaid_FunderOwned_LessorRemit_SalesTax_GL,0.00) [TotalPrepaid_FunderOwned_LessorRemit_SalesTax_GL]
			,ISNULL(frt.LessorRemittingSalesTaxPrepaid,0.00) - ISNULL(gld.TotalPrepaid_FunderOwned_LessorRemit_SalesTax_GL,0.00) [TotalPrepaid_FunderOwned_LessorRemit_SalesTax_Difference]
			,CASE
				WHEN cwmg.ContractId IS NOT NULL
				THEN 'Yes'
				ELSE 'No'
			END [IsManualGLEntryPosted]
		FROM #EligibleContracts ec
		INNER JOIN Contracts c ON c.Id = ec.ContractId
		INNER JOIN LegalEntities le ON le.Id = ec.LegalEntityId
		INNER JOIN LineofBusinesses lob ON lob.Id = c.LineofBusinessId
		INNER JOIN Parties p ON p.Id = ec.CustomerId
		LEFT JOIN #PaymentAmount pa ON pa.ContractId = ec.ContractId
		LEFT JOIN #OverTerm ot ON ot.ContractId = ec.ContractId
		LEFT JOIN #FullPaidOffContracts fpoc ON fpoc.ContractId = ec.ContractId
		LEFT JOIN #AccrualDetails ad ON ad.ContractId = ec.ContractId
		LEFT JOIN #HasFinanceAsset hfa ON hfa.ContractId = ec.ContractId
		LEFT JOIN #ChargeOffDetails cod ON cod.ContractId = ec.ContractId
		LEFT JOIN #AmendmentInfo ai ON ai.ContractId = ec.ContractId
		LEFT JOIN #SumOfReceivables sor ON sor.ContractId = ec.ContractId
		LEFT JOIN #SumOfReceivableDetails sord ON sord.ContractId = ec.ContractId
		LEFT JOIN #SumOfReceiptApplicationReceivableDetails sorard ON sorard.ContractId = ec.ContractId
		LEFT JOIN #SumOfPrepaidReceivables sopr ON sopr.ContractId = ec.ContractId
		LEFT JOIN #SumOfLeaseAssets sola ON sola.ContractId = ec.ContractId
		LEFT JOIN #LeaseIncomeSchInfo lisi ON lisi.ContractId = ec.ContractId
		LEFT JOIN #FixedTermAssetValueHistoriesInfo ftavh ON ftavh.ContractId = ec.ContractId
		LEFT JOIN #NBVAssetValueHistoriesInfo navh ON navh.ContractId = ec.ContractId
		LEFT JOIN #WriteDownInfo wdi ON wdi.ContractId = ec.ContractId
		LEFT JOIN #ChargeOffInfo coi ON coi.ContractId = ec.ContractId
		LEFT JOIN #SumOfReceipts sort ON sort.ContractId = ec.ContractId
		LEFT JOIN #SumOfPayables sop ON sop.ContractId = ec.ContractId
		LEFT JOIN #ReceivableTaxDetails rtxd ON rtxd.ContractId = ec.ContractId
		LEFT JOIN #SalesTaxDetails stxd ON stxd.ContractId = ec.ContractId
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
		LEFT JOIN #GLDetails gld ON gld.ContractId = ec.ContractId
		LEFT JOIN #RRGLDetails rrgld ON rrgld.ContractId = ec.ContractId
		) AS t
		
		CREATE NONCLUSTERED INDEX IX_Id ON #ResultList(ContractId);

		SELECT name AS Name, 0 AS Count, CAST (0 AS BIT) AS IsProcessed, CAST('' AS NVARCHAR(max)) AS Label, column_Id AS ColumnId
		INTO #OperatingLeaseSummary
		FROM tempdb.sys.columns
		WHERE object_id = OBJECT_ID('tempdb..#ResultList')
		AND (Name LIKE '%Difference' OR Name LIKE '%VS%');

		DECLARE @query NVARCHAR(MAX);
		DECLARE @TableName NVARCHAR(max);
		WHILE EXISTS (SELECT 1 FROM #OperatingLeaseSummary WHERE IsProcessed = 0)
		BEGIN
		SELECT TOP 1 @TableName = Name FROM #OperatingLeaseSummary WHERE IsProcessed = 0

		SET @query = 'UPDATE #OperatingLeaseSummary SET Count = (SELECT COUNT(*) FROM #ResultList WHERE ' + @TableName+ ' != 0.00), IsProcessed = 1
					  WHERE Name = '''+ @TableName+''' ;'
		EXEC (@query)
		END

		UPDATE #OperatingLeaseSummary 
		SET Label = CASE
					WHEN NAME = 'GLPostedReceivables_LeaseComponent_Difference'
					THEN '1_Lease Component Receivables - GL Posted_Difference'
					WHEN NAME = 'TotalPaidReceivables_LeaseComponent_Difference'
					THEN '2_Lease Component Receivables - Total Paid_Difference'
					WHEN NAME = 'TotalPaidReceivablesviaCash_LeaseComponent_Difference'
					THEN '3_Lease Component Receivables - Total Cash Paid_Difference'
					WHEN NAME = 'TotalPaidReceivablesviaNonCash_LeaseComponent_Difference'
					THEN '4_Lease Component Receivables - Total Non Cash Paid_Difference'
					WHEN NAME = 'PrepaidReceivables_LeaseComponent_Difference'
					THEN '5_Lease Component Receivables - Prepaid_Difference'
					WHEN NAME = 'OutstandingReceivables_LeaseComponent_Difference'
					THEN '6_Lease Component Receivables - OSAR_Difference'
					WHEN NAME = 'AssetCost_LeaseComponent_Difference'
					THEN '7_Lease Component - Asset Cost_Difference'
					WHEN NAME = 'AccumulatedDepreciation_Difference'
					THEN '8_Accumulated Depreciation_Difference'
					WHEN NAME = 'Depreciation_Difference'
					THEN '9_Depreciation_Difference'
					WHEN NAME = 'AccumulatedNBVImpairment_Difference'
					THEN '10_Accumulated NBV Impairment_Difference'
					WHEN NAME = 'NBVImpairment_Difference'
					THEN '11_NBV Impairment_Difference'
					WHEN NAME = 'RentalIncome_Difference'
					THEN '12_Rental Income_Difference'
					WHEN NAME = 'SuspendedRentalIncome_Difference'
					THEN '13_Suspended Rental Income_Difference'
					WHEN NAME = 'DeferredIncome_Difference'
					THEN '14_Deferred Income_Difference'
					WHEN NAME = 'GLPostedReceivables_FinanceComponent_Difference'
					THEN '15_Finance Component Receivables - GL Posted_Difference'
					WHEN NAME = 'TotalPaidReceivables_FinanceComponent_Difference'
					THEN '16_Finance Component Receivables - Total Paid_Difference'
					WHEN NAME = 'TotalPaidReceivablesviaCash_FinanceComponent_Difference'
					THEN '17_Finance Component Receivables - Total Cash Paid_Difference'
					WHEN NAME = 'TotalPaidReceivablesviaNonCash_FinanceComponent_Difference'
					THEN '18_Finance Component Receivables - Total Non Cash Paid_Difference'
					WHEN NAME = 'PrepaidReceivables_FinanceComponent_Difference'
					THEN '19_Finance Component Receivables - Prepaid_Difference'
					WHEN NAME = 'OutstandingReceivables_FinanceComponent_Difference'
					THEN '20_Finance Component Receivables - OSAR_Difference'
					WHEN NAME = 'LongTermReceivables_FinanceComponent_Difference'
					THEN '21_Finance Component Receivables - Long Term_Difference'
					WHEN NAME = 'GuaranteedResiduals_FinanceComponent_Difference'
					THEN '22_Finance Component - Guaranteed Residuals_Difference'
					WHEN NAME = 'UnguaranteedResiduals_FinanceComponent_Difference'
					THEN '23_Finance Component - Unguaranteed Residuals_Difference'
					WHEN NAME = 'FinancingTotalIncome_AccountingSchedule_Difference'
					THEN '24_Finance Component - Total Income Accounting And Schedule_Difference'
					WHEN NAME = 'FinancingEarnedIncome_Difference'
					THEN '25_Finance Component - Earned Income_Difference'
					WHEN NAME = 'FinancingEarnedResidualIncome_Difference'
					THEN '26_Finance Component - Earned Residual Income_Difference'
					WHEN NAME = 'FinancingUnearnedIncome_Difference'
					THEN '27_Finance Component - Unearned Income_Difference'
					WHEN NAME = 'FinancingUnearnedResidualIncome_Difference'
					THEN '28_Finance Component - Unearned Residual Income_Difference'
					WHEN NAME = 'FinancingRecognizedSuspendedIncome_Difference'
					THEN '29_Finance Component - Recognized Suspended Income_Difference'
					WHEN NAME = 'FinancingRecognizedSuspendedResidualIncome_Difference'
					THEN '30_Finance Component - Recognized Suspended Residual Income_Difference'
					WHEN NAME = 'TotalCapitalizedSalesTax_Difference'
					THEN '31_Capitalized - Total Sales Tax_Difference'
					WHEN NAME = 'TotalCapitalizedInterimInterest_Difference'
					THEN '32_Capitalized - Total Interim Interest_Difference'
					WHEN NAME = 'TotalCapitalizedInterimRent_Difference'
					THEN '33_Capitalized - Total Interim Rent_Difference'
					WHEN NAME = 'TotalCapitalizedAdditionalCharge_Difference'
					THEN '34_Capitalized - Total Additional Charge_Difference'
					WHEN NAME = 'TotalGLPostedFloatRateReceivables_Difference'
					THEN '35_Float Rate Receivables - Total GL Posted_Difference'
					WHEN NAME = 'TotalPaidFloatRateReceivables_Difference'
					THEN '36_Float Rate Receivables - Total Paid_Difference'
					WHEN NAME = 'TotalCashPaidFloatRateReceivables_Difference'
					THEN '37_Float Rate Receivables - Total Cash Paid_Difference'
					WHEN NAME = 'TotalNonCashPaidFloatRateReceivables_Difference'
					THEN '38_Float Rate Receivables - Total Non Cash Paid_Difference'
					WHEN NAME = 'OutstandingFloatRateReceivables_Difference'
					THEN '39_Float Rate Receivables - OSAR_Difference'
					WHEN NAME = 'PrepaidFloatRateReceivables_Difference'
					THEN '40_Float Rate Receivables - Prepaid_Difference'
					WHEN NAME = 'TotalFloatRateIncome_AccountingAndSchedule_Difference'
					THEN '41_Float Rate Income - Accounting And Schedule_Difference'
					WHEN NAME = 'TotalGLPostedFloatRateIncome_Difference'
					THEN '42_Float Rate Income - Total GL Posted_Difference'
					WHEN NAME = 'TotalSuspendedIncome_Difference'
					THEN '43_Float Rate Income - Total Suspended_Difference'
					WHEN NAME = 'TotalAccruedIncome_Difference'
					THEN '44_Float Rate Income - Total Accrued_Difference'
					WHEN NAME = 'TotalGLPosted_InterimRentReceivables_Difference'
					THEN '45_Interim Rent Receivables - Total GL Posted_Difference'
					WHEN NAME = 'TotalPaid_InterimRentReceivables_Difference'
					THEN '46_Interim Rent Receivables - Total Paid_Difference'
					WHEN NAME = 'TotalPaidviaCash_InterimRentReceivables_Difference'
					THEN '47_Interim Rent Receivables - Total Cash Paid_Difference'
					WHEN NAME = 'TotalPaidviaNonCash_InterimRentReceivables_Difference'
					THEN '48_Interim Rent Receivables - Total Non Cash Paid_Difference'
					WHEN NAME = 'TotalPrepaid_InterimRentReceivables_Difference'
					THEN '49_Interim Rent Receivables - Total Prepaid_Difference'
					WHEN NAME = 'TotalOutstanding_InterimRentReceivables_Difference'
					THEN '50_Interim Rent Receivables - Total OSAR_Difference'
					WHEN NAME = 'GLPosted_InterimRentIncome_Difference'
					THEN '51_Interim Rent Income - GL Posted_Difference'
					WHEN NAME = 'TotalCapitalizedIncome_InterimRentIncome_Difference'
					THEN '52_Interim Rent Income - Total Capitalized Income_Difference'
					WHEN NAME = 'TotalInterimRent_IncomeandReceivable_Difference'
					THEN '53_Interim Rent Income - Income And Receivable_Difference'
					WHEN NAME = 'DeferInterimRentIncome_Difference'
					THEN '54_Interim Rent Income - DeferInterim_Difference'
					WHEN NAME = 'TotalGLPosted_InterimInterestReceivables_Difference'
					THEN '55_Interim Interest Receivables - Total GL Posted_Difference'
					WHEN NAME = 'TotalPaid_InterimInterestReceivables_Difference'
					THEN '56_Interim Interest Receivables - Total Paid_Difference'
					WHEN NAME = 'TotalPaidviaCash_InterimInterestReceivables_Difference'
					THEN '57_Interim Interest Receivables - Total Cash Paid_Difference'
					WHEN NAME = 'TotalPaidviaNonCash_InterimInterestReceivables_Difference'
					THEN '58_Interim Interest Receivables - Total Non Cash Paid_Difference'
					WHEN NAME = 'TotalPrepaid_InterimInterestReceivables_Difference'
					THEN '59_Interim Interest Receivables - Total Prepaid_Difference'
					WHEN NAME = 'TotalOutstanding_InterimInterestReceivables_Difference'
					THEN '60_Interim Interest Receivables - Total OSAR_Difference'
					WHEN NAME = 'GLPosted_InterimInterestIncome_Difference'
					THEN '61_Interim Interest Income - GL Posted_Difference'
					WHEN NAME = 'TotalCapitalizedIncome_InterimInterestIncome_Difference'
					THEN '62_Interim Interest Income - Total Capitalized Income_Difference'
					WHEN NAME = 'TotalInterimInterest_IncomeandReceivable_Difference'
					THEN '63_Interim Interest Income - Income And Receivable_Difference'
					WHEN NAME = 'AccruedInterimInterestIncome_Difference'
					THEN '64_Interim Interest Income - AccruedInterim_Difference'
					WHEN NAME = 'GrossWriteDown_Difference'
					THEN '65_Gross WriteDown_Difference'
					WHEN NAME = 'WriteDownRecovered_Difference'
					THEN '66_WriteDown Recovered_Difference'
					WHEN NAME = 'NetWriteDown_Difference'
					THEN '67_Net WriteDown_Difference'
					WHEN Name ='ChargeOffExpense_LeaseComponent_Difference'
					THEN '68_Lease Component - Charge-off Expense_Difference'
					WHEN Name ='ChargeOffExpense_NonLeaseComponent_Difference'
					THEN '69_Finance Component - Charge-off Expense_Difference'
					WHEN Name = 'TotalChargeoffAmountVSLCAndNLC'
					THEN '70_Total Chargeoff Amount VS LC & NLC'
					WHEN Name ='ChargeOffRecovery_LeaseComponent_Difference'
					THEN '71_Lease Component - Charge-off Recovery_Difference'
					WHEN Name ='ChargeOffRecovery_NonLeaseComponent_Difference'
					THEN '72_Finance Component - Charge-off Recovery_Difference'
					WHEN Name ='ChargeOffGainOnRecovery_LeaseComponent_Difference'
					THEN '73_ Lease Component - Charge-off Gain On Recovery_Difference'
					WHEN Name ='ChargeOffGainOnRecovery_NonLeaseComponent_Difference'
					THEN '74_Finance Component - Charge-off Gain On Recovery_Difference'
					WHEN Name = 'TotalRecoveryAndGainVSRecoveryAndGainLCAndNLC'
					THEN '75_Total Recovery & Gain VS Recovery & Gain LC & NLC'
					WHEN NAME = 'UnAppliedCash_Difference'
					THEN '76_UnApplied Cash_Difference'
					WHEN NAME = 'TotalGLPosted_SalesTaxReceivable_Difference'
					THEN '77_Sales Tax Receivables - GL Posted_Difference'
					WHEN NAME = 'TotalPaid_SalesTaxReceivables_Difference'
					THEN '78_Sales Tax Receivables - Total Paid_Difference'
					WHEN NAME = 'TotalPaidviacash_SalesTaxReceivables_Difference'
					THEN '79_Sales Tax Receivables - Total Cash Paid_Difference'
					WHEN NAME = 'TotalPaidvianoncash_SalesTaxReceivables_Difference'
					THEN '80_Sales Tax Receivables - Total Non Cash Paid_Difference'
					WHEN NAME = 'TotalPrepaid_SalesTaxReceivables_Difference'
					THEN '81_Sales Tax Receivables - Total Prepaid_Difference'
					WHEN NAME = 'TotalOutstanding_SalesTaxReceivables_Difference'
					THEN '82_Sales Tax Receivables - Total OSAR_Difference'
					WHEN NAME = 'TotalGLPosted_FunderOwned_Difference'
					THEN '83_Funder Owned Receivables - Total GL Posted_Difference'
					WHEN NAME = 'TotalPaidCash_FunderOwned_Difference'
					THEN '84_Funder Owned Receivables - Total Cash Paid_Difference'
					WHEN NAME = 'TotalPaidNonCash_FunderOwned_Difference'
					THEN '85_Funder Owned Receivables - Total Non Cash Paid_Difference'
					WHEN NAME = 'TotalOSAR_FunderOwned_Difference'
					THEN '86_Funder Owned Receivables - Total OSAR_Difference'
					WHEN NAME = 'TotalPrepaid_FunderOwned_Difference'
					THEN '87_Funder Owned Receivables - Total Prepaid_Difference'
					WHEN NAME = 'TotalGLPosted_FunderOwned_LessorRemit_SalesTax_Difference'
					THEN '88_Funder Owned Receivables - Total GL Posted Lessor Remit Sales Tax_Difference'
					WHEN NAME = 'TotalPaidCash_FunderOwned_LessorRemit_SalesTax_Difference'
					THEN '89_Funder Owned Receivables - Total Cash Paid Lessor Remit Sales Tax_Difference'
					WHEN NAME = 'TotalPaidNonCash_FunderOwned_LessorRemit_SalesTax_Difference'
					THEN '90_Funder Owned Receivables - Total Non Cash Paid Lessor Remit Sales Tax_Difference'
					WHEN NAME = 'TotalPrepaid_FunderOwned_LessorRemit_SalesTax_Difference'
					THEN '91_Funder Owned Receivables - Total Prepaid Lessor Remit Sales Tax_Difference'
					WHEN NAME = 'TotalOSAR_FunderOwned_LessorRemit_SalesTax_Difference'
					THEN '92_Funder Owned Receivables - Total OSAR Lessor Remit Sales Tax_Difference'
		END
		
		SELECT Label AS Name, Count
		FROM #OperatingLeaseSummary
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

	DROP TABLE #EligibleContracts;
	DROP TABLE #PaymentAmount;
	DROP TABLE #OverTerm;
	DROP TABLE #FullPaidOffContracts;
	DROP TABLE #AccrualDetails;
	DROP TABLE #HasFinanceAsset;
	DROP TABLE #ChargeOffDetails;
	DROP TABLE #AmendmentInfo;
	DROP TABLE #ReceivableInfo;
	DROP TABLE #RenewalDetails;
	DROP TABLE #SumOfReceivables;
	DROP TABLE #SumOfReceivableDetails;
	DROP TABLE #SumOfReceiptApplicationReceivableDetails;
	DROP TABLE #SumOfPrepaidReceivables;
	DROP TABLE #OTPReclass;
	DROP TABLE #AssetResiduals;
	DROP TABLE #BlendedItemAssetsInfo;
	DROP TABLE #SKUResiduals;
	DROP TABLE #SumOfLeaseAssets;
	DROP TABLE #SaleOfPaymentsUnguaranteedInfo;
	DROP TABLE #BlendedItemInfo;
	DROP TABLE #BlendedIncomeSchInfo;
	DROP TABLE #LeaseIncomeSchInfo;
	DROP TABLE #PayOffDetails;
	DROP TABLE #ClearedFixedTermAVHIncomeDate;
	DROP TABLE #ClearedFixedTermAVHIncomeDateCO;
	DROP TABLE #SyndicationAVHInfo;
	DROP TABLE #FixedTermAssetValueHistoriesInfo;
	DROP TABLE #NBVAssetValueHistoriesInfo;
	DROP TABLE #WriteDownInfo;
	DROP TABLE #ChargeOffInfo;
	DROP TABLE #SumOfReceipts;
	DROP TABLE #SumOfPayables;
	DROP TABLE #ReceivableForTaxes;
	DROP TABLE #ReceivableTaxDetails;
	DROP TABLE #SalesTaxDetails;
	DROP TABLE #CapitalizedDetails;
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

	DROP TABLE #RenewalGLJournals;
	DROP TABLE #GLDetails;
	DROP TABLE #RefundGLJournalIds;
	DROP TABLE #RefundTableValue
	DROP TABLE #GLDetail
	DROP TABLE #RRGLDetails;
	DROP TABLE #ContractsWithManualGLEntries;
	DROP TABLE #ResultList;
	DROP TABLE #OperatingLeaseSummary;
	DROP TABLE #NonAccrualDetails;
	
	SET NOCOUNT OFF
	SET ANSI_WARNINGS ON 
END

GO

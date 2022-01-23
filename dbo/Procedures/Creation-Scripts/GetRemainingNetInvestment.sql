SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetRemainingNetInvestment]
(
@ContractMin BIGINT,
@ContractMax BIGINT,
--@AllCustomers BIT,
--@CustomerId BIGINT,
@IncomeDate DATE,
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET,
@InactiveStatus NVARCHAR(50),
@LoanCancelledStatus NVARCHAR(50),
@Origination NVARCHAR(50),
@DirectFinanceContractSubType NVARCHAR(50),
@OperatingContractSubType NVARCHAR(50),
@PayableInvoiceAssetSourceTable NVARCHAR(50),
@PayableInvoiceOtherCostSourceTable NVARCHAR(50),
@LoanDisbursementAllocationMethod NVARCHAR(50),
@LoanContractType NVARCHAR(50),
@ProgressLoanContractType NVARCHAR(50),
@Lease NVARCHAR(10),
@ApprovalStatus NVARCHAR(50),
@BlendedItemIDC NVARCHAR(50),
@SaleOfPaymentsType NVARCHAR(50),
@NBVImpairmentSourceModule NVARCHAR(50),
@FixedTermBookDepSourceModule NVARCHAR(50),
@CashBasedAccountingTreatment NVARCHAR(50),
@AccrualBased NVARCHAR(50),
@OperatingLeaseRental NVARCHAR(50),
@InterimRental NVARCHAR(50),
@CapitalLeaseRental NVARCHAR(50),
@OverTermRental NVARCHAR(50),
@LoanInterest NVARCHAR(50),
@LoanPrincipal NVARCHAR(50),
@LeaseFloatRateAdj NVARCHAR(50),
@LeaseInterimInterest NVARCHAR(50),
@Supplemental NVARCHAR(50),
@CommencedStatus NVARCHAR(50),
@FullyPaid NVARCHAR(50),
@UnCommencedStatus NVARCHAR(50),
@LoanInterimInterest NVARCHAR(50),
@FixedTerm NVARCHAR(50),
@BlendedItemIncome NVARCHAR(50),
@BlendedItemExpense NVARCHAR(50),
@CompletedStatus NVARCHAR(50),
@OTPDepreciation NVARCHAR(50),
@ResidualRecapture NVARCHAR(50),
@CapitalizedSalesTax NVARCHAR(50),
@PostedStatus NVARCHAR(50),
@IncludeExposure BIT,
@SpecificCostAdjustment NVARCHAR(50),
@AssetCount NVARCHAR(50),
@AssetCost NVARCHAR(50),
@Specific NVARCHAR(50),
@IsCDCEnabled BIT,
@DefaultCurrency NVARCHAR(3),
@LeasePak NVARCHAR(10),
@Unknown NVARCHAR(3),
@None NVARCHAR(5),
@RecognizeImmediately NVARCHAR(50),
@Capitalize NVARCHAR(50),
@ReAccrualSystemConfigType NVARCHAR(400),
@ContractEntityType NVARCHAR(3),
@FullSale NVARCHAR(20),
@ProgressPaymentCreditAllocationMethod NVARCHAR(50),
@FullyPaidOff NVARCHAR(20),
@OriginationRestoredType NVARCHAR(50),
@CapitalizedInterimInterest NVARCHAR(50),
@CapitalizedInterimRent NVARCHAR(50),
@CapitalizedProgressPayment NVARCHAR(50),
@ActiveStatus NVARCHAR(20),
@LoanDownPayment NVARCHAR(20),
@FullPaydown NVARCHAR(20),
@Casualty NVARCHAR(20),
@CapitalizedInterestDueToSkipPayments NVARCHAR(60),
@CapitalizedInterestDueToRateChange NVARCHAR(60),
@CapitalizedInterestFromPaydown NVARCHAR(60),
@CapitalizedInterestDueToScheduledFunding NVARCHAR(60),
@FutureScheduled NVARCHAR(20),
@FutureScheduledFunded NVARCHAR(30),
@Financing NVARCHAR(20),
@ProgressLoanInterestCapitalized NVARCHAR(50),
@CapitalizedAdditionalFeeCharge	NVARCHAR(50),
@ParticipatedSale NVARCHAR(30),
@ReceiptSourcaeTable NVARCHAR(20),
@ReversedStatus NVARCHAR(20),
@ReceiptRefundEntityType NVARCHAR(5),
@AmortizeRecognitionMode NVARCHAR(20),
@LeasePayOff NVARCHAR(20),
@BuyOut NVARCHAR(20),
@Finance NVARCHAR(10),
@OverTerm NVARCHAR(20),
@LeveragedLeaseRental NVARCHAR(50),
@LeveragedLeasePayoff NVARCHAR(50),
@Pending NVARCHAR(20),
@InstallingAssets NVARCHAR(20),
@OriginatedHFS NVARCHAR(20),
@HFS NVARCHAR(5),
@DSL NVARCHAR(5),
@NonDSL NVARCHAR(10),
@LeveragedLease NVARCHAR(20),
@ReAccrualResidualIncome NVARCHAR(50),
@ReAccrualRentalIncome NVARCHAR(50),
@ReAccrualIncome NVARCHAR(20),
@ReAccrualFinanceIncome NVARCHAR(50),
@ReAccrualFinanceResidualIncome NVARCHAR(50),
@ReAccrualDeferredSellingProfitIncome NVARCHAR(60),
@InterimRent NVARCHAR(50),
@IncludeDeferredInterimRent bit,
@ExcludeBackgroundProcessingPendingContracts bit
)
AS
BEGIN

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; -- Ramesh: Remove

--DECLARE 
--	@ContractMin BigInt=672132 ,
--	@ContractMax BigInt=673131,
--	@IncomeDate datetime='2019-04-25',
--	@CreatedById BigInt=10597,
--	@CreatedTime datetimeoffset='2021-03-05 10:22:49.3607369 +05:30',
--	@InactiveStatus Nvarchar(100)=N'Inactive',
--	@LoanCancelledStatus Nvarchar(100)=N'Cancelled',
--	@Origination Nvarchar(100)=N'Origination',
--	@DirectFinanceContractSubType Nvarchar(100)=N'DirectFinance',
--	@OperatingContractSubType Nvarchar(100)=N'Operating',
--	@PayableInvoiceAssetSourceTable Nvarchar(100)=N'PayableInvoiceAsset',
--	@PayableInvoiceOtherCostSourceTable Nvarchar(100)=N'PayableInvoiceOtherCost',
--	@LoanDisbursementAllocationMethod Nvarchar(100)=N'LoanDisbursement',
--	@LoanContractType Nvarchar(100)=N'Loan',
--	@ProgressLoanContractType Nvarchar(100)=N'ProgressLoan',
--	@Lease Nvarchar(100)=N'Lease',
--	@ApprovalStatus Nvarchar(100)=N'Approved',
--	@BlendedItemIDC Nvarchar(100)=N'IDC',
--	@SaleOfPaymentsType Nvarchar(100)=N'SaleOfPayments',
--	@NBVImpairmentSourceModule Nvarchar(100)=N'NBVImpairments',
--	@FixedTermBookDepSourceModule Nvarchar(100)=N'FixedTermDepreciation',
--	@CashBasedAccountingTreatment Nvarchar(100)=N'CashBased',
--	@AccrualBased Nvarchar(100)=N'AccrualBased',
--	@OperatingLeaseRental Nvarchar(100)=N'OperatingLeaseRental',
--	@InterimRental Nvarchar(100)=N'InterimRental',
--	@CapitalLeaseRental Nvarchar(100)=N'CapitalLeaseRental',
--	@OverTermRental Nvarchar(100)=N'OverTermRental',
--	@LoanInterest Nvarchar(100)=N'LoanInterest',
--	@LoanPrincipal Nvarchar(100)=N'LoanPrincipal',
--	@LeaseFloatRateAdj Nvarchar(100)=N'LeaseFloatRateAdj',
--	@LeaseInterimInterest Nvarchar(100)=N'LeaseInterimInterest',
--	@Supplemental Nvarchar(100)=N'Supplemental',
--	@CommencedStatus Nvarchar(100)=N'Commenced',
--	@FullyPaid Nvarchar(100)=N'FullyPaid',
--	@UnCommencedStatus Nvarchar(100)=N'Uncommenced',
--	@LoanInterimInterest Nvarchar(100)=N'InterimInterest',
--	@FixedTerm Nvarchar(100)=N'FixedTerm',
--	@BlendedItemIncome Nvarchar(100)=N'Income',
--	@BlendedItemExpense Nvarchar(100)=N'Expense',
--	@CompletedStatus Nvarchar(100)=N'Completed',
--	@OTPDepreciation Nvarchar(100)=N'OTPDepreciation',
--	@ResidualRecapture Nvarchar(100)=N'ResidualRecapture',
--	@CapitalizedSalesTax Nvarchar(100)=N'CapitalizedSalesTax',
--	@PostedStatus Nvarchar(100)=N'Posted',
--	@IncludeExposure Bit=1,
--	@SpecificCostAdjustment Nvarchar(100)=N'SpecificCostAdjustment',
--	@AssetCount Nvarchar(100)=N'AssetCount',
--	@AssetCost Nvarchar(100)=N'AssetCost',
--	@Specific Nvarchar(100)=N'Specific',
--	@IsCDCEnabled bit=0,
--	@DefaultCurrency Nvarchar(100)=N'USD',
--	@LeasePak Nvarchar(100)=N'LeasePak',
--	@Unknown Nvarchar(100)=N'_',
--	@None Nvarchar(100)=N'None',
--	@RecognizeImmediately Nvarchar(100)=N'RecognizeImmediately',
--	@Capitalize Nvarchar(100)=N'Capitalize',
--	@ReAccrualSystemConfigType Nvarchar(1000)=N'ReAccrualDeferredSellingProfitIncome,ReAccrualFinanceIncome,ReAccrualFinanceResidualIncome,ReAccrualIncome,ReAccrualRentalIncome,ReAccrualResidualIncome',
--	@ContractEntityType Nvarchar(100)=N'CT',
--	@FullSale Nvarchar(100)=N'FullSale',
--	@ProgressPaymentCreditAllocationMethod Nvarchar(100)=N'ProgressPaymentCredit',
--	@FullyPaidOff Nvarchar(100)=N'FullyPaidOff',
--	@OriginationRestoredType Nvarchar(100)=N'OriginationRestored',
--	@CapitalizedInterimInterest Nvarchar(100)=N'CapitalizedInterimInterest',
--	@CapitalizedInterimRent Nvarchar(100)=N'CapitalizedInterimRent',
--	@CapitalizedProgressPayment Nvarchar(100)=N'CapitalizedProgressPayment',
--	@ActiveStatus Nvarchar(100)=N'Active',
--	@LoanDownPayment Nvarchar(100)=N'Downpayment',
--	@FullPaydown Nvarchar(100)=N'FullPaydown',
--	@Casualty Nvarchar(100)=N'Casualty',
--	@CapitalizedInterestDueToSkipPayments Nvarchar(100)=N'CapitalizedInterestDueToSkipPayments',
--	@CapitalizedInterestDueToRateChange Nvarchar(100)=N'CapitalizedInterestDueToRateChange',
--	@CapitalizedInterestFromPaydown Nvarchar(100)=N'CapitalizedInterestFromPaydown',
--	@CapitalizedInterestDueToScheduledFunding Nvarchar(100)=N'CapitalizedInterestDueToScheduledFunding',
--	@FutureScheduled Nvarchar(100)=N'FutureScheduled',
--	@FutureScheduledFunded Nvarchar(100)=N'FutureScheduledFunded',
--	@Financing Nvarchar(100)=N'Financing',
--	@ProgressLoanInterestCapitalized Nvarchar(100)=N'ProgressLoanInterestCapitalized',
--	@ParticipatedSale Nvarchar(100)=N'ParticipatedSale',
--	@ReceiptSourcaeTable Nvarchar(100)=N'Receipt',
--	@ReversedStatus Nvarchar(100)=N'Reversed',
--	@ReceiptRefundEntityType Nvarchar(100)=N'RR',
--	@AmortizeRecognitionMode Nvarchar(100)=N'Amortize',
--	@LeasePayOff Nvarchar(100)=N'LeasePayOff',
--	@BuyOut Nvarchar(100)=N'BuyOut',
--	@Finance Nvarchar(100)=N'Finance',
--	@OverTerm Nvarchar(100)=N'OverTerm',
--	@LeveragedLeaseRental Nvarchar(100)=N'LeveragedLeaseRental',
--	@LeveragedLeasePayoff Nvarchar(100)=N'LeveragedLeasePayoff',
--	@Pending Nvarchar(100)=N'Pending',
--	@InstallingAssets Nvarchar(100)=N'InstallingAssets',
--	@OriginatedHFS Nvarchar(100)=N'OriginatedHFS',
--	@HFS Nvarchar(100)=N'HFS',
--	@DSL Nvarchar(100)=N'DSL',
--	@NonDSL Nvarchar(100)=N'Non-DSL',
--	@LeveragedLease Nvarchar(100)=N'LeveragedLease',
--	@ReAccrualResidualIncome Nvarchar(100)=N'ReAccrualResidualIncome',
--	@ReAccrualRentalIncome Nvarchar(100)=N'ReAccrualRentalIncome',
--	@ReAccrualIncome Nvarchar(100)=N'ReAccrualIncome',
--	@ReAccrualFinanceIncome Nvarchar(100)=N'ReAccrualFinanceIncome',
--	@ReAccrualFinanceResidualIncome Nvarchar(100)=N'ReAccrualFinanceResidualIncome',
--	@ReAccrualDeferredSellingProfitIncome Nvarchar(100)=N'ReAccrualDeferredSellingProfitIncome',
--	@InterimRent Nvarchar(100)=N'InterimRent',
--	@IncludeDeferredInterimRent bit=0


	CREATE TABLE #RNITemp (ContractId BIGINT PRIMARY KEY
	,RNIAmount_Amount DECIMAL(18,2) DEFAULT 0
	,ServicedRNIAmount_Amount DECIMAL(18,2) DEFAULT 0
	,PrincipalBalance_Amount DECIMAL(18,2) DEFAULT 0
	,DelayedFundingPayables_Amount DECIMAL(18,2) DEFAULT 0
	,LoanPrincipleOSAR_Amount DECIMAL(18,2) DEFAULT 0
	,LoanInterestOSAR_Amount DECIMAL(18,2) DEFAULT 0
	,InterimInterestOSAR_Amount DECIMAL(18,2) DEFAULT 0
	,IncomeAccrualBalance_Amount DECIMAL(18,2) DEFAULT 0
	,SuspendedIncomeAccrualBalance_Amount DECIMAL(18,2) DEFAULT 0
	,ProgressFundings_Amount DECIMAL(18,2) DEFAULT 0
	,ProgressPaymentCredits_Amount DECIMAL(18,2) DEFAULT 0
	,TotalFinancedAmount_Amount DECIMAL(18,2) DEFAULT 0
	,TotalFinancedAmountLOC_Amount DECIMAL(18,2) DEFAULT 0
	,UnappliedCash_Amount DECIMAL(18,2) DEFAULT 0
	,GrossWritedowns_Amount DECIMAL(18,2) DEFAULT 0
	,NetWritedowns_Amount DECIMAL(18,2) DEFAULT 0
	,IDCBalance_Amount DECIMAL(18,2) DEFAULT 0
	,SuspendedIDCBalance_Amount DECIMAL(18,2) DEFAULT 0
	,SuspendedFAS91ExpenseBalance_Amount DECIMAL(18,2) DEFAULT 0
	,SuspendedFAS91IncomeBalance_Amount DECIMAL(18,2) DEFAULT 0
	,FAS91ExpenseBalance_Amount DECIMAL(18,2) DEFAULT 0
	,FAS91IncomeBalance_Amount DECIMAL(18,2) DEFAULT 0
	,OperatingLeaseAssetGrossCost_Amount DECIMAL(18,2) DEFAULT 0
	,AccumulatedDepreciation_Amount DECIMAL(18,2) DEFAULT 0
	,OperatingLeaseRentOSAR_Amount DECIMAL(18,2) DEFAULT 0
	,InterimRentOSAR_Amount DECIMAL(18,2) DEFAULT 0
	,DeferredOperatingIncome_Amount DECIMAL(18,2) DEFAULT 0
	,DeferredExtensionIncome_Amount DECIMAL(18,2) DEFAULT 0
	,CapitalLeaseContractReceivable_Amount DECIMAL(18,2) DEFAULT 0
	,UnguaranteedResidual_Amount DECIMAL(18,2) DEFAULT 0
	,CustomerGuaranteedResidual_Amount DECIMAL(18,2) DEFAULT 0
	,ThirdPartyGauranteedResidual_Amount DECIMAL(18,2) DEFAULT 0
	,CapitalLeaseRentOSAR_Amount DECIMAL(18,2) DEFAULT 0
	,OverTermRentOSAR_Amount DECIMAL(18,2) DEFAULT 0
	,UnearnedRentalIncome_Amount DECIMAL(18,2) DEFAULT 0
	,OTPResidualRecapture_Amount DECIMAL(18,2) DEFAULT 0
	,PrepaidReceivables_Amount DECIMAL(18,2) DEFAULT 0
	,SyndicatedPrepaidReceivables_Amount DECIMAL(18,2) DEFAULT 0
	,AccumulatedNBVImpairment_Amount DECIMAL(18,2) DEFAULT 0
	,FloatRateAdjustmentOSAR_Amount DECIMAL(18,2) DEFAULT 0
	,FloatRateIncomeBalance_Amount DECIMAL(18,2) DEFAULT 0
	,SuspendedFloatRateIncomeBalance_Amount DECIMAL(18,2) DEFAULT 0
	,HeldForSaleValuationAllowance_Amount DECIMAL(18,2) DEFAULT 0
	,SyndicatedFixedTermReceivablesOSAR_Amount DECIMAL(18,2) DEFAULT 0
	,SyndicatedInterimReceivablesOSAR_Amount DECIMAL(18,2) DEFAULT 0
	,SecurityDeposit_Amount DECIMAL(18,2) DEFAULT 0
	,SecurityDepositOSAR_Amount DECIMAL(18,2) DEFAULT 0
	,VendorSubsidyOSAR_Amount DECIMAL(18,2) DEFAULT 0
	,DelayedVendorSubsidy_Amount DECIMAL(18,2) DEFAULT 0
	,SalesTaxOSAR_Amount DECIMAL(18,2) DEFAULT 0
	,SyndicatedSalesTaxOSAR_Amount DECIMAL(18,2) DEFAULT 0
	,PrincipalBalanceAdjustment_Amount DECIMAL(18,2) DEFAULT 0
	,SyndicatedCapitalLeaseContractReceivable_Amount DECIMAL(18,2)  DEFAULT 0
	,IncomeAccrualBalanceFunderPortion_Amount DECIMAL(18,2)  DEFAULT 0
	,PrincipalBalanceFunderPortion_Amount DECIMAL(18,2) DEFAULT 0
	,PrepaidInterest_Amount DECIMAL(18,2)  DEFAULT 0
	,FinanceIncomeAccrualBalance_Amount DECIMAL(18,2) DEFAULT 0
	,SuspendedFinanceIncomeAccrualBalance_Amount DECIMAL(18,2) DEFAULT 0
	,SyndicatedFinanceIncomeAccrualBalance_Amount DECIMAL(18,2) DEFAULT 0
	,DeferredSellingProfit_Amount DECIMAL(18,2) DEFAULT 0
	,SuspendedDeferredSellingProfit_Amount DECIMAL(18,2) DEFAULT 0
	,FinanceGrossWritedowns_Amount DECIMAL(18,2) DEFAULT 0
	,FinanceNetWritedowns_Amount DECIMAL(18,2) DEFAULT 0
	,FinancingContractReceivable_Amount DECIMAL(18,2) DEFAULT 0
	,SyndicatedFinancingContractReceivable_Amount DECIMAL(18,2) DEFAULT 0
	,FinanceUnguaranteedResidual_Amount DECIMAL(18,2) DEFAULT 0
	,FinanceCustomerGuaranteedResidual_Amount DECIMAL(18,2) DEFAULT 0
	,FinanceThirdPartyGauranteedResidual_Amount DECIMAL(18,2) DEFAULT 0
	,FinancingRentOSAR_Amount DECIMAL(18,2) DEFAULT 0
	,FinanceSyndicatedFixedTermReceivablesOSAR_Amount DECIMAL(18,2) DEFAULT 0);
	CREATE TABLE #LeaseDetails (ContractId BIGINT PRIMARY KEY, LeaseFinanceId BIGINT, CommencementDate DATE, MaturityDate DATE, LeaseContractType NVARCHAR(32), InstrumentTypeId BIGINT,
	BookingStatus NVARCHAR(32), HoldingStatus  NVARCHAR(28), LegalEntityId BIGINT,OTPLease BIT,  OTPReceivableCodeId BIGINT, IsInOTP BIT, SyndicationType NVARCHAR(32), IsMigratedContract BIT, IsChargedOff BIT,IsNonAccrual BIT
	, SalesTaxRemittanceMethod NVARCHAR(24));
	CREATE TABLE #LoanDetails (ContractId BIGINT PRIMARY KEY, LoanFinanceId BIGINT, CommencementDate DATE, MaturityDate DATE, InstrumentTypeId BIGINT,
	Status NVARCHAR(32), HoldingStatus  NVARCHAR(28), IsDSL BIT, LegalEntityId BIGINT, SyndicationType NVARCHAR(32), IsMigratedContract BIT
	, IsChargedOff BIT,IsNonAccrual BIT,IsProgressLoan BIT, PrincipalBalance DECIMAL(16,2), TotalAmount DECIMAL(16,2), PrincipalBalanceIncomeExists BIT
	, SalesTaxRemittanceMethod NVARCHAR(24));
	CREATE TABLE #LeveragedLeaseDetails (ContractId BIGINT, LeveragedLeaseId BIGINT, CommencementDate DATE, MaturityDate DATE, InstrumentTypeId BIGINT,
	Status NVARCHAR(32), HoldingStatus  NVARCHAR(28), IsMigratedContract BIT, SalesTaxRemittanceMethod NVARCHAR(24), LegalEntityId BIGINT);
	CREATE TABLE #BasicDetails (ContractId BIGINT PRIMARY KEY, SyndicationType NVARCHAR(32),CommencementDate DATE,IsChargedOff BIT,MaxIncomeDate DATE
	, MaxNonAccrualDate DATE,MaxIncomeDatePriorToSyndication DATE, ChargeOffDate DATE,FullSaleMaxIncomeDate DATE
	, LegalEntityId BIGINT, SalesTaxRemittanceMethod NVARCHAR(24));
	CREATE INDEX IX_ContractID ON #BasicDetails(ContractId)
	CREATE TABLE #SyndicationDetailsTemp(ContractId BIGINT, RetainedPercentage DECIMAL(18,8), ReceivableForTransferType NVARCHAR(32), SyndicationEffectiveDate DATE,
	SyndicationId BIGINT, IsServiced BIT, IsCollected  BIT, SyndicationAtInception BIT);
	CREATE TABLE #LeaseIncomeScheduleTemp(ContractId BIGINT,IncomeDate DATE,IsIncomeBeforeCommencement bit,IsNonAccrual BIT,Income_Amount DECIMAL(16,2),RentalIncome_Amount DECIMAL(16,2)
	,IsLessorOwned BIT,IsAccounting BIT,IsSchedule BIT,IncomeBalance_Amount DECIMAL(16,2),IsGLPosted BIT,IncomeType NVARCHAR(15),IsReclassOTP BIT
	,FinanceIncome_Amount DECIMAL(16,2),DeferredSellingProfitIncome_Amount DECIMAL(16,2),AccountingTreatment NVARCHAR(12));
	CREATE TABLE #LoanIncomeScheduleTemp(ContractId BIGINT,EndNetBookValue_Amount DECIMAL(16,2),IncomeDate DATE,IsNonAccrual BIT,IsLessorOwned BIT
	,IsAccounting BIT,IsSchedule BIT,InterestAccrued_Amount DECIMAL(16,2),IsGLPosted BIT,CommencementDate DATE);
	CREATE TABLE #ReceivableDetailsTemp(ContractId BIGINT,IncomeType NVARCHAR(16),ReceivableId BIGINT,ReceivableType NVARCHAR(25),Balance_Amount DECIMAL(16,2)
	,Amount_Amount DECIMAL(16,2),DueDate DATE,FunderId BIGINT,IsGLPosted BIT,AccountingTreatment NVARCHAR(12),IsDummy BIT,EffectiveBookBalance_Amount DECIMAL(16,2),
	PaymentStartDate DATE,PaymentEndDate DATE,PaymentDueDate DATE,PaymentType NVARCHAR(28),IsFinanceComponent BIT);
	CREATE TABLE #BlendedItemTemp(ContractId BIGINT, BlendedItemId BIGINT, IsFAS91 BIT, Type NVARCHAR(14),	BookRecognitionMode NVARCHAR(40),
	BlendedItemAmount DECIMAL(18,2), SystemConfigType NVARCHAR(46), IncomeAmount DECIMAL(16,2), SuspendedIncomeAmount DECIMAL(16,2),
	IsReaccrualBlendedItem BIT);
	CREATE TABLE #AssetTemp(ContractId BIGINT, Amount DECIMAL(16,2), AssetId BIGINT, CapitalizationType NVARCHAR(26), DefferedRentalAmount DECIMAL(16,2)
	, IsMigratedContract BIT, CapitalizedForId BIGINT, PayableInvoiceId BIGINT, ETCAdjustmentAmount_Amount DECIMAL(16,2), IsActive BIT
	, TerminationDate DATE, IsLeaseAsset BIT, BookedResidual_Amount DECIMAL(16,2), CustomerGuaranteedResidual_Amount DECIMAL(16,2)
	, ThirdPartyGuaranteedResidual_Amount DECIMAL(16,2), LeaseAssetId BIGINT, IsSKU BIT);
	CREATE TABLE #LoanFinanceBasicTemp(ContractId BIGINT,Amount DECIMAL(16,2),FundingId BIGINT,Type NVARCHAR(21),PayableInvoiceId BIGINT,Status NVARCHAR(9)
	,OtherCostId BIGINT,IsForeignCurrency BIT,InitialExchangeRate DECIMAL(20,10),InvoiceDate DATE,SourceTransaction NVARCHAR(20),IsOrigination BIT);
	CREATE TABLE #LoanPaydownTemp(ContractId BIGINT, IsDailySensitive BIT, PaydownDate DATE, PaydownReason NVARCHAR(30), PrincipalBalance_Amount DECIMAL(16,2)
	, PrincipalPaydown_Amount DECIMAL(16,2), AccruedInterest_Amount DECIMAL(16,2), InterestPaydown_Amount DECIMAL(16,2));
	CREATE TABLE #FutureScheduledFundedTemp(ContractId BIGINT,FundingId BIGINT,Amount DECIMAL(16,2),InvoiceDate DATE,PaymentDate DATE,
	DRStatus NVARCHAR(25),DueDate DATE, IsGLPosted BIT);
	CREATE TABLE #WriteDownDetailsTemp(ContractId BIGINT, IsLease BIT, IsRecovery BIT,WriteDownAmount DECIMAL (16,2), IsLeaseAsset BIT);
	CREATE TABLE #SuspendedIncomeInfoForDoubtfulCollectability(ContractId BIGINT PRIMARY KEY, IsNonAccrual BIT,NonAccrualDate DATE);
	CREATE TABLE #DeferredInterimRentInfoTemp(ContractId BIGINT, DeferredInterimRent DECIMAL(16,2))

	Create Index IX_ContractId ON #AssetTemp(ContractId) Include (DefferedRentalAmount)
	Create Index IX_ContractId ON #ReceivableDetailsTemp(ContractId) Include (Amount_Amount)
	Create Index IX_ContractId ON #LeaseIncomeScheduleTemp(ContractId) Include (RentalIncome_Amount)

CREATE TABLE #tempRemainingNetInvestments
( 
	[IncomeDate] [date] NOT NULL,
	[ContractType] [nvarchar](14) NOT NULL,
	[SubType] [nvarchar](100) NOT NULL,
	[IsOTP] [bit] NOT NULL,
	[IsInNonAccrual] [bit] NOT NULL,
	[NonAccrualDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[Status] [nvarchar](100) NULL,
	[HoldingStatus] [nvarchar](13) NULL,
	[RetainedPercentage] [decimal](10, 6) NULL,
	[IsPaymentStreamSold] [bit] NOT NULL,
	[RNIAmount_Amount] [decimal](16, 2) NOT NULL,
	[RNIAmount_Currency] [nvarchar](3) NOT NULL,
	[ServicedRNIAmount] [decimal](16, 2) NOT NULL,
	[PrincipalBalance] [decimal](16, 2) NOT NULL,
	[DelayedFundingPayables] [decimal](16, 2) NOT NULL,
	[LoanPrincipleOSAR] [decimal](16, 2) NOT NULL,
	[LoanInterestOSAR] [decimal](16, 2) NOT NULL,
	[InterimInterestOSAR] [decimal](16, 2) NOT NULL,
	[IncomeAccrualBalance] [decimal](16, 2) NOT NULL,
	[SuspendedIncomeAccrualBalance] [decimal](16, 2) NOT NULL,
	[ProgressFundings] [decimal](16, 2) NOT NULL,
	[ProgressPaymentCredits] [decimal](16, 2) NOT NULL,
	[TotalFinancedAmount] [decimal](16, 2) NOT NULL,
	[TotalFinancedAmountLOC] [decimal](16, 2) NOT NULL,
	[UnappliedCash] [decimal](16, 2) NOT NULL,
	[GrossWritedowns] [decimal](16, 2) NOT NULL,
	[NetWritedowns] [decimal](16, 2) NOT NULL,
	[IDCBalance] [decimal](16, 2) NOT NULL,
	[SuspendedIDCBalance] [decimal](16, 2) NOT NULL,
	[SuspendedFAS91ExpenseBalance] [decimal](16, 2) NOT NULL,
	[SuspendedFAS91IncomeBalance] [decimal](16, 2) NOT NULL,
	[FAS91ExpenseBalance] [decimal](16, 2) NOT NULL,
	[FAS91IncomeBalance] [decimal](16, 2) NOT NULL,
	[OperatingLeaseAssetGrossCost] [decimal](16, 2) NOT NULL,
	[AccumulatedDepreciation] [decimal](16, 2) NOT NULL,
	[OperatingLeaseRentOSAR] [decimal](16, 2) NOT NULL,
	[InterimRentOSAR] [decimal](16, 2) NOT NULL,
	[DeferredOperatingIncome] [decimal](16, 2) NOT NULL,
	[DeferredExtensionIncome] [decimal](16, 2) NOT NULL,
	[CapitalLeaseContractReceivable] [decimal](16, 2) NOT NULL,
	[UnguaranteedResidual] [decimal](16, 2) NOT NULL,
	[CustomerGuaranteedResidual] [decimal](16, 2) NOT NULL,
	[ThirdPartyGauranteedResidual] [decimal](16, 2) NOT NULL,
	[CapitalLeaseRentOSAR] [decimal](16, 2) NOT NULL,
	[OverTermRentOSAR] [decimal](16, 2) NOT NULL,
	[UnearnedRentalIncome] [decimal](16, 2) NOT NULL,
	[OTPResidualRecapture] [decimal](16, 2) NOT NULL,
	[PrepaidReceivables] [decimal](16, 2) NOT NULL,
	[SyndicatedPrepaidReceivables] [decimal](16, 2) NOT NULL,
	[AccumulatedNBVImpairment] [decimal](16, 2) NOT NULL,
	[FloatRateAdjustmentOSAR] [decimal](16, 2) NOT NULL,
	[FloatRateIncomeBalance] [decimal](16, 2) NOT NULL,
	[SuspendedFloatRateIncomeBalance] [decimal](16, 2) NOT NULL,
	[HeldForSaleValuationAllowance] [decimal](16, 2) NOT NULL,
	[HeldForSaleBalance] [decimal](16, 2) NOT NULL,
	[SyndicatedFixedTermReceivablesOSAR] [decimal](16, 2) NOT NULL,
	[SyndicatedInterimReceivablesOSAR] [decimal](16, 2) NOT NULL,
	[SecurityDeposit] [decimal](16, 2) NOT NULL,
	[SecurityDepositOSAR] [decimal](16, 2) NOT NULL,
	[VendorSubsidyOSAR] [decimal](16, 2) NOT NULL,
	[DelayedVendorSubsidy] [decimal](16, 2) NOT NULL,
	[SalesTaxOSAR] [decimal](16, 2) NOT NULL,
	[SyndicatedSalesTaxOSAR] [decimal](16, 2) NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[InstrumentTypeId] [bigint] NULL,
	[CreditProfileId] [bigint] NULL,
	[CurrencyId] [bigint] NULL,
	[PrincipalBalanceAdjustment] [decimal](16, 2) NOT NULL,
	[SyndicatedCapitalLeaseContractReceivable] [decimal](16, 2) NOT NULL,
	[IncomeAccrualBalanceFunderPortion] [decimal](16, 2) NOT NULL,
	[PrincipalBalanceFunderPortion] [decimal](16, 2) NOT NULL,
	[PrepaidInterest] [decimal](16, 2) NOT NULL,
	[AccountingStandard] [nvarchar](12) NULL,
	[FinanceIncomeAccrualBalance] [decimal](16, 2) NOT NULL,
	[SuspendedFinanceIncomeAccrualBalance] [decimal](16, 2) NOT NULL,
	[SyndicatedFinanceIncomeAccrualBalance] [decimal](16, 2) NOT NULL,
	[DeferredSellingProfit] [decimal](16, 2) NOT NULL,
	[SuspendedDeferredSellingProfit] [decimal](16, 2) NOT NULL,
	[FinanceGrossWritedowns] [decimal](16, 2) NOT NULL,
	[FinanceNetWritedowns] [decimal](16, 2) NOT NULL,
	[FinancingContractReceivable] [decimal](16, 2) NOT NULL,
	[SyndicatedFinancingContractReceivable] [decimal](16, 2) NOT NULL,
	[FinanceUnguaranteedResidual] [decimal](16, 2) NOT NULL,
	[FinanceCustomerGuaranteedResidual] [decimal](16, 2) NOT NULL,
	[FinanceThirdPartyGauranteedResidual] [decimal](16, 2) NOT NULL,
	[FinancingRentOSAR] [decimal](16, 2) NOT NULL,
	[FinanceSyndicatedFixedTermReceivablesOSAR] [decimal](16, 2) NOT NULL,
	[BackgroundProcessingPending] [bit] NOT NULL
);

CREATE TABLE #tempRemainingNetInvestmentsIds
(
	[Id] [bigint] NOT NULL
);

--Lease
INSERT INTO #LeaseDetails
SELECT Contract.Id AS ContractId
,Lease.Id AS LeaseFinanceId
,LeaseFinanceDetail.CommencementDate
,LeaseFinanceDetail.MaturityDate
,LeaseFinanceDetail.LeaseContractType
,Lease.InstrumentTypeId
,Lease.BookingStatus
,Lease.HoldingStatus
,Lease.LegalEntityId
,CASE WHEN LeaseFinanceDetail.LastExtensionARUpdateRunDate IS NOT NULL THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS OTPLease
,LeaseFinanceDetail.OTPReceivableCodeId
,CAST(0 AS BIT) AS IsInOTP
,Contract.SyndicationType
,(CASE WHEN Contract.u_ConversionSource = @LeasePak THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END) AS IsMigratedContract
,CASE WHEN Contract.ChargeOffStatus = @Unknown THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END AS IsChargedOff
,Contract.IsNonAccrual
,Contract.SalesTaxRemittanceMethod
FROM Contracts Contract
JOIN LeaseFinances Lease ON Contract.Id = Lease.ContractId AND Lease.IsCurrent = 1
JOIN LeaseFinanceDetails LeaseFinanceDetail With (ForceSeek) ON Lease.Id = LeaseFinanceDetail.Id
--WHERE (@AllCustomers = 1 OR (@CustomerId IS NULL OR Lease.CustomerId = @CustomerId)) AND (@CustomerId BETWEEN @ContractMin AND @ContractMax) AND Lease.ApprovalStatus != @InactiveStatus
WHERE (Lease.ContractId BETWEEN @ContractMin AND @ContractMax) AND (@ExcludeBackgroundProcessingPendingContracts = 0 OR Contract.BackgroundProcessingPending = 0) AND  Lease.ApprovalStatus != @InactiveStatus;
--Loan
INSERT INTO #LoanDetails
SELECT Contract.Id AS ContractId
,Loan.Id AS LoanFinanceId
,Loan.CommencementDate
,Loan.MaturityDate
,Loan.InstrumentTypeId
,Loan.Status
,Loan.HoldingStatus
,Loan.IsDailySensitive AS IsDSL
,Loan.LegalEntityId
,Contract.SyndicationType
,(CASE WHEN Contract.u_ConversionSource = @LeasePak THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END) AS IsMigratedContract
,CASE WHEN Contract.ChargeOffStatus = @Unknown THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END AS IsChargedOff
,Contract.IsNonAccrual
,CASE WHEN Contract.ContractType = @ProgressLoanContractType THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsProgressLoan
,0.00
,0.00
,0
,Contract.SalesTaxRemittanceMethod
FROM Contracts Contract
JOIN LoanFinances Loan With (ForceSeek) ON Contract.Id = Loan.ContractId AND Loan.IsCurrent = 1
WHERE (Loan.ContractId BETWEEN @ContractMin AND @ContractMax) AND (@ExcludeBackgroundProcessingPendingContracts = 0 OR Contract.BackgroundProcessingPending = 0) AND  Loan.Status != @LoanCancelledStatus
;
--Leveraged Lease
INSERT INTO #LeveragedLeaseDetails
SELECT Contract.Id AS ContractId
,LeveragedLease.Id AS LeveragedLeaseId
,LeveragedLease.CommencementDate
,LeveragedLease.MaturityDate
,LeveragedLease.InstrumentTypeId
,LeveragedLease.Status
,LeveragedLease.HoldingStatus
,(CASE WHEN Contract.u_ConversionSource = @LeasePak THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END) AS IsMigratedContract
,Contract.SalesTaxRemittanceMethod
,LeveragedLease.LegalEntityId
FROM Contracts Contract
JOIN LeveragedLeases LeveragedLease ON Contract.Id = LeveragedLease.ContractId AND LeveragedLease.IsCurrent = 1
WHERE (LeveragedLease.ContractId BETWEEN @ContractMin AND @ContractMax) AND (@ExcludeBackgroundProcessingPendingContracts = 0 OR Contract.BackgroundProcessingPending = 0) AND LeveragedLease.Status != @InactiveStatus
;
--Basic Details
INSERT INTO #BasicDetails
SELECT * FROM
(SELECT
ContractId,
SyndicationType,
CommencementDate,
IsChargedOff,
NULL MaxIncomeDate,
NULL MaxNonAccrualDate,
NULL MaxIncomeDatePriorToSyndication,
NULL ChargeOffDate,
NULL FullSaleMaxIncomeDate,
LegalEntityId,
SalesTaxRemittanceMethod
FROM #LeaseDetails
UNION
SELECT
ContractId,
SyndicationType,
CommencementDate,
IsChargedOff,
NULL MaxIncomeDate,
NULL MaxNonAccrualDate,
NULL MaxIncomeDatePriorToSyndication,
NULL ChargeOffDate,
NULL FullSaleMaxIncomeDate,
LegalEntityId,
SalesTaxRemittanceMethod
FROM #LoanDetails
UNION
SELECT
ContractId,
NULL,
CommencementDate,
CAST(0 AS BIT),
NULL MaxIncomeDate,
NULL MaxNonAccrualDate,
NULL MaxIncomeDatePriorToSyndication,
NULL ChargeOffDate,
NULL FullSaleMaxIncomeDate,
LegalEntityId,
SalesTaxRemittanceMethod
FROM #LeveragedLeaseDetails)
BasicDetails
;
INSERT INTO #tempRemainingNetInvestmentsIds(Id)
select RNI.Id 
FROM #BasicDetails Contract
JOIN RemainingNetInvestments RNI ON Contract.ContractId = RNI.ContractId
WHERE RNI.IncomeDate = @IncomeDate
;
INSERT INTO #RNITemp (ContractId)
SELECT ContractId FROM #BasicDetails
;
/*Syndication Portion*/
IF EXISTS (SELECT * FROM #BasicDetails WHERE SyndicationType <> @None)
BEGIN
;WITH CTE_MaxServicingEffectiveDate AS
(SELECT Contract.ContractId,
MAX(ServicingDetail.EffectiveDate) AS EffectiveDate,
MAX(ReceivableForTransfer.Id) ReceivableForTransferId
FROM #BasicDetails Contract
JOIN ReceivableForTransfers ReceivableForTransfer ON Contract.ContractId = ReceivableForTransfer.ContractId AND ReceivableForTransfer.ApprovalStatus = @ApprovalStatus
JOIN ReceivableForTransferServicings ServicingDetail ON ReceivableForTransfer.Id = ServicingDetail.ReceivableForTransferId AND ServicingDetail.IsActive = 1
GROUP BY Contract.ContractId)
INSERT INTO #SyndicationDetailsTemp
SELECT Contract.ContractId
,ReceivableForTransfer.RetainedPercentage
,ReceivableForTransfer.ReceivableForTransferType
,ReceivableForTransfer.EffectiveDate AS SyndicationEffectiveDate
,ReceivableForTransfer.Id AS SyndicationId
,ServicingDetail.IsServiced
,ServicingDetail.IsCollected
,(CASE WHEN ReceivableForTransfer.EffectiveDate = Contract.CommencementDate THEN 1 ELSE 0 END) AS SyndicationAtInception
FROM #BasicDetails Contract
join CTE_MaxServicingEffectiveDate LatestServicingInfo ON LatestServicingInfo.ContractId = Contract.ContractId
JOIN ReceivableForTransfers ReceivableForTransfer ON LatestServicingInfo.ReceivableForTransferId = ReceivableForTransfer.Id
JOIN ReceivableForTransferServicings ServicingDetail ON ReceivableForTransfer.Id = ServicingDetail.ReceivableForTransferId
AND ServicingDetail.EffectiveDate = LatestServicingInfo.EffectiveDate AND ServicingDetail.IsActive=1;
END
/*Syndication Ends*/
/*Lease Income Temp Begins*/
/*Fetched entire IncomeSchedules irrespective of commencementDate, as we need the same for DeferredOperatingIncome_Amount */
IF EXISTS(SELECT 1 FROM #LeaseDetails)
BEGIN
INSERT INTO #LeaseIncomeScheduleTemp
SELECT Contract.ContractId,
IncomeSched.IncomeDate,
CASE WHEN IncomeSched.IncomeDate >= Contract.CommencementDate THEN 0 ELSE 1 END,
IncomeSched.IsNonAccrual,
IncomeSched.Income_Amount,
IncomeSched.RentalIncome_Amount,
IncomeSched.IsLessorOwned,
IncomeSched.IsAccounting,
IncomeSched.IsSchedule,
IncomeSched.IncomeBalance_Amount,
IncomeSched.IsGLPosted,
IncomeSched.IncomeType,
IncomeSched.IsReclassOTP,
IncomeSched.FinanceIncome_Amount,
IncomeSched.DeferredSellingProfitIncome_Amount,
IncomeSched.AccountingTreatment
FROM #LeaseDetails Contract
INNER JOIN LeaseFinances Lease ON Contract.ContractId = Lease.ContractId
INNER JOIN LeaseIncomeSchedules IncomeSched ON Lease.Id = IncomeSched.LeaseFinanceId 
WHERE (IncomeSched.IsSchedule = 1 OR IncomeSched.IsAccounting = 1);
END
UPDATE Contract SET IsInOTP = CAST(1 AS BIT)
FROM #LeaseDetails AS Contract where EXISTS (SELECT ContractId  FROM #LeaseIncomeScheduleTemp LeaseIncome WHERE LeaseIncome.ContractID
= Contract.ContractID and  LeaseIncome.IsReclassOTP = 1 AND LeaseIncome.IsIncomeBeforeCommencement = 0);
/*Lease Income Temp Ends*/
/*Loan Income Temp Begins*/
IF EXISTS(SELECT 1 FROM #LoanDetails)
BEGIN
INSERT INTO #LoanIncomeScheduleTemp
SELECT Contract.ContractId,
IncomeSched.EndNetBookValue_Amount,
IncomeSched.IncomeDate,
IncomeSched.IsNonAccrual,
IncomeSched.IsLessorOwned,
IncomeSched.IsAccounting,
IncomeSched.IsSchedule,
IncomeSched.InterestAccrued_Amount,
IncomeSched.IsGLPosted,
Loan.CommencementDate
FROM #LoanDetails Contract
JOIN LoanFinances Loan ON Contract.ContractId = Loan.ContractId
JOIN LoanIncomeSchedules IncomeSched ON Loan.Id = IncomeSched.LoanFinanceId
WHERE (IncomeSched.IsSchedule = 1 OR IncomeSched.IsAccounting = 1);
END
/*Loan Income Temp Ends*/
/*Blended Item Temp Begins*/
INSERT INTO #BlendedItemTemp
SELECT * FROM
(
SELECT Contract.ContractId
,BlendedItem.Id AS BlendedItemId
,BlendedItem.IsFAS91
,BlendedItem.Type
,BlendedItem.BookRecognitionMode
,BlendedItem.Amount_Amount AS BlendedItemAmount
,BlendedItem.SystemConfigType
,0 AS IncomeAmount
,0 AS SuspendedIncomeAmount
,CAST(0 AS BIT) AS IsReaccrualBlendedItem
FROM #LeaseDetails Contract
JOIN LeaseFinances Lease ON Contract.ContractId = Lease.ContractId AND Lease.IsCurrent = 1
JOIN LeaseBlendedItems ContractBlendedItem ON Lease.Id = ContractBlendedItem.LeaseFinanceId
JOIN BlendedItems BlendedItem ON ContractBlendedItem.BlendedItemId = BlendedItem.Id AND BlendedItem.IsActive = 1
LEFT JOIN #SyndicationDetailsTemp SyndicationDetail ON Contract.ContractId = SyndicationDetail.ContractId
LEFT JOIN BlendedItems ChildBlendedItem ON BlendedItem.Id = ChildBlendedItem.RelatedBlendedItemId AND ChildBlendedItem.IsActive=1
WHERE (SyndicationDetail.SyndicationId IS NULL OR SyndicationDetail.RetainedPercentage > 0.0 OR SyndicationDetail.ReceivableForTransferType = @SaleOfPaymentsType)
AND BlendedItem.BookRecognitionMode NOT IN (@RecognizeImmediately,@Capitalize)
AND ChildBlendedItem.Id IS NULL
UNION
SELECT Contract.ContractId
,BlendedItem.Id AS BlendedItemId
,BlendedItem.IsFAS91
,BlendedItem.Type
,BlendedItem.BookRecognitionMode
,BlendedItem.Amount_Amount AS BlendedItemAmount
,BlendedItem.SystemConfigType
,0 AS IncomeAmount
,0 AS SuspendedIncomeAmount
,CAST(0 AS BIT) AS IsReaccrualBlendedItem
FROM #LoanDetails Contract
JOIN LoanFinances Loan ON Contract.ContractId = Loan.ContractId AND Loan.IsCurrent = 1
JOIN LoanBlendedItems ContractBlendedItem ON Loan.Id = ContractBlendedItem.LoanFinanceId
JOIN BlendedItems BlendedItem ON ContractBlendedItem.BlendedItemId = BlendedItem.Id AND BlendedItem.IsActive = 1 AND BlendedItem.BookRecognitionMode != @RecognizeImmediately
LEFT JOIN #SyndicationDetailsTemp SyndicationDetail ON Contract.ContractId = SyndicationDetail.ContractId
WHERE (SyndicationDetail.SyndicationId IS NULL OR (SyndicationDetail.RetainedPercentage > 0.0 OR SyndicationDetail.ReceivableForTransferType = @SaleOfPaymentsType))
UNION
SELECT SyndicatedContract.ContractId
,BlendedItem.Id AS BlendedItemId
,BlendedItem.IsFAS91
,BlendedItem.Type
,BlendedItem.BookRecognitionMode
,BlendedItem.Amount_Amount AS BlendedItemAmount
,BlendedItem.SystemConfigType
,0 AS IncomeAmount
,0 AS SuspendedIncomeAmount
,CAST(0 AS BIT) AS IsReaccrualBlendedItem
FROM #SyndicationDetailsTemp SyndicatedContract
JOIN ReceivableForTransferBlendedItems SyndicationBlendedItem ON SyndicationBlendedItem.ReceivableForTransferId = SyndicatedContract.SyndicationId
JOIN BlendedItems BlendedItem ON SyndicationBlendedItem.BlendedItemId = BlendedItem.Id AND BlendedItem.IsActive = 1
LEFT JOIN BlendedItems ChildBlendedItem ON BlendedItem.Id = ChildBlendedItem.RelatedBlendedItemId AND ChildBlendedItem.IsActive=1
WHERE (SyndicatedContract.RetainedPercentage > 0.0 OR SyndicatedContract.ReceivableForTransferType = @SaleOfPaymentsType)
AND BlendedItem.BookRecognitionMode NOT IN (@RecognizeImmediately,@Capitalize)
AND ChildBlendedItem.Id IS NULL
) AS BlendedItems
;
UPDATE #BlendedItemTemp
SET IsReaccrualBlendedItem = CAST(1 AS BIT)
FROM #BlendedItemTemp BlendedItem
WHERE BlendedItem.SystemConfigType IN (SELECT * FROM dbo.ConvertCSVToStringTable(@ReAccrualSystemConfigType,','))
;WITH CTE_GroupedBI AS
(SELECT BlendedItem.BlendedItemId
,SUM(IncomeSched.Income_Amount) AS IncomeAmount
,CASE WHEN IncomeSched.IsNonAccrual=1 THEN SUM(IncomeSched.Income_Amount) ELSE 0 END AS SuspendedIncomeAmount
FROM #BlendedItemTemp BlendedItem
JOIN BlendedIncomeSchedules IncomeSched ON BlendedItem.BlendedItemId = IncomeSched.BlendedItemId
WHERE IncomeSched.IsAccounting = 1 AND IncomeSched.PostDate IS NOT NULL
GROUP BY BlendedItem.BlendedItemId,IncomeSched.IsNonAccrual)
UPDATE #BlendedItemTemp
SET IncomeAmount = BlendedIncomeDetails.IncomeAmount,
SuspendedIncomeAmount = BlendedIncomeDetails.SuspendedIncomeAmount
FROM #BlendedItemTemp BlendedItem
JOIN (SELECT BlendedItemId
, SUM(IncomeAmount) AS IncomeAmount
, SUM(SuspendedIncomeAmount) AS SuspendedIncomeAmount
FROM CTE_GroupedBI
GROUP BY BlendedItemId)
AS BlendedIncomeDetails ON BlendedItem.BlendedItemId = BlendedIncomeDetails.BlendedItemId
;WITH CTE_GroupedReaccrualBI AS
(SELECT BlendedItem.BlendedItemId
,SUM(IncomeSched.Income_Amount) AS IncomeAmount
FROM #BlendedItemTemp BlendedItem
JOIN BlendedIncomeSchedules IncomeSched ON BlendedItem.BlendedItemId = IncomeSched.BlendedItemId AND BlendedItem.IsReaccrualBlendedItem = 1
AND BlendedItem.SystemConfigType != @ReAccrualRentalIncome AND IncomeSched.IsAccounting = 1
AND IncomeSched.PostDate IS NULL
GROUP BY BlendedItem.BlendedItemId)
UPDATE #BlendedItemTemp
SET IncomeAmount = BlendedIncomeDetails.IncomeAmount
FROM #BlendedItemTemp BlendedItem
JOIN  CTE_GroupedReaccrualBI  BlendedIncomeDetails ON BlendedItem.BlendedItemId = BlendedIncomeDetails.BlendedItemId
/*Blended Item Temp Ends*/
/*Asset Temp Begins*/
/*Asset without SKUs*/
IF EXISTS(SELECT 1 FROM #LeaseDetails)
BEGIN
SELECT Asset.Id, IsSku Into #Assets
FROM #LeaseDetails Contract
JOIN LeaseAssets LeaseAsset ON Contract.LeaseFinanceId = LeaseAsset.LeaseFinanceId
JOIN Assets Asset ON LeaseAsset.AssetId = Asset.Id

INSERT INTO #AssetTemp
SELECT Contract.ContractId
, LeaseAsset.NBV_Amount AS Amount
, LeaseAsset.AssetId
, LeaseAsset.CapitalizationType
, LeaseAsset.DeferredRentalIncome_Amount AS DefferedRentalAmount
, Contract.IsMigratedContract
, LeaseAsset.CapitalizedForId
, LeaseAsset.PayableInvoiceId
, LeaseAsset.ETCAdjustmentAmount_Amount
, LeaseAsset.IsActive
, LeaseAsset.TerminationDate
, LeaseAsset.IsLeaseAsset
, LeaseAsset.BookedResidual_Amount
, LeaseAsset.CustomerGuaranteedResidual_Amount
, LeaseAsset.ThirdPartyGuaranteedResidual_Amount
, LeaseAsset.Id AS LeaseAssetId
, 0 AS IsSKU
FROM #LeaseDetails Contract
JOIN LeaseAssets LeaseAsset ON Contract.LeaseFinanceId = LeaseAsset.LeaseFinanceId
AND (LeaseAsset.IsActive = 1 OR LeaseAsset.TerminationDate IS NOT NULL)
JOIN #Assets Asset ON LeaseAsset.AssetId = Asset.Id And Asset.IsSKU = 0


	/*Asset With SKUs*/
	/*Assumed DeferredRentalIncome_Amount will be there only for LeaseComponent*/
	INSERT INTO #AssetTemp
	SELECT Contract.ContractId
	, SUM(LeaseAssetSKU.NBV_Amount) AS Amount
	, LeaseAsset.AssetId
	, LeaseAsset.CapitalizationType
	, CASE WHEN LeaseAssetSKU.IsLeaseComponent = 0 THEN 0 ELSE LeaseAsset.DeferredRentalIncome_Amount END AS DefferedRentalAmount
	, Contract.IsMigratedContract
	, LeaseAsset.CapitalizedForId
	, LeaseAsset.PayableInvoiceId
	, SUM(LeaseAssetSKU.ETCAdjustmentAmount_Amount)
	, LeaseAsset.IsActive
	, LeaseAsset.TerminationDate
	, LeaseAssetSKU.IsLeaseComponent
	, SUM(LeaseAssetSKU.BookedResidual_Amount)
	, SUM(LeaseAssetSKU.CustomerGuaranteedResidual_Amount)
	, SUM(LeaseAssetSKU.ThirdPartyGuaranteedResidual_Amount)
	, LeaseAsset.Id AS LeaseAssetId
	, 1 AS IsSKU
	FROM #LeaseDetails Contract
	JOIN LeaseAssets LeaseAsset ON Contract.LeaseFinanceId = LeaseAsset.LeaseFinanceId
	AND (LeaseAsset.IsActive = 1 OR LeaseAsset.TerminationDate IS NOT NULL)
	JOIN #Assets Asset ON LeaseAsset.AssetId = Asset.Id AND Asset.IsSKU = 1
	JOIN LeaseAssetSKUs LeaseAssetSKU ON LeaseAsset.Id = LeaseAssetSKU.LeaseAssetId
	GROUP BY Contract.ContractId,LeaseAsset.AssetId,LeaseAsset.CapitalizationType,LeaseAsset.DeferredRentalIncome_Amount,Contract.IsMigratedContract,LeaseAsset.CapitalizedForId
	,LeaseAsset.PayableInvoiceId,LeaseAsset.IsActive,LeaseAsset.TerminationDate,LeaseAsset.Id,LeaseAssetSKU.IsLeaseComponent
	END
	/*Asset Temp Ends*/

	/*Receivable Temp Begins*/
	IF EXISTS(SELECT 1 FROM #LeaseDetails)
	BEGIN

	SELECT Contract.ContractId
	,Receivable.Id AS ReceivableId
	,ReceivableDetail.Id ReceivableDetailId
	,ReceivableDetail.LeaseComponentBalance_Amount  AS LCBalance_Amount
	,ReceivableDetail.LeaseComponentAmount_Amount  AS LCAmount_Amount
	,ReceivableDetail.NonLeaseComponentBalance_Amount AS NLCBalance_Amount
	,ReceivableDetail.NonLeaseComponentAmount_Amount AS NLCAmount_Amount
	INTO #ReceivableDetails
	FROM #LeaseDetails Contract
	JOIN Receivables Receivable ON Contract.ContractId = Receivable.EntityId AND Receivable.EntityType = @ContractEntityType AND Receivable.IsActive=1
	JOIN ReceivableDetails ReceivableDetail With (ForceSeek) ON Receivable.Id = ReceivableDetail.ReceivableId AND ReceivableDetail.IsActive = 1 

	CREATE INDEX IX_ReceivableDetailId ON #ReceivableDetails (ReceivableDetailId) 

	SELECT RD.ContractId
	,RD.ReceivableId
	,SUM(RD.LCBalance_Amount)  AS LCBalance_Amount
	,SUM(RD.LCAmount_Amount)  AS LCAmount_Amount
	,SUM(RD.NLCBalance_Amount) AS NLCBalance_Amount
	,SUM(RD.NLCAmount_Amount) AS NLCAmount_Amount
	INTO #Receivables
	FROM #ReceivableDetails RD
	GROUP BY RD.ContractId,RD.ReceivableId

	CREATE INDEX IX_ReceivableId ON #Receivables (ReceivableId)  

	--For LC

	INSERT INTO #ReceivableDetailsTemp
	SELECT ReceivableInfo.ContractId
	,Receivable.IncomeType
	,Receivable.Id AS ReceivableId
	,Type.Name AS ReceivableType
	,ReceivableInfo.LCBalance_Amount
	,ReceivableInfo.LCAmount_Amount
	,Receivable.DueDate
	,Receivable.FunderId
	,Receivable.IsGLPosted
	,Code.AccountingTreatment
	,Receivable.IsDummy
	,0.0
	,PaymentSched.StartDate AS PaymentStartDate
	,PaymentSched.EndDate  AS PaymentEndDate
	,PaymentSched.DueDate  AS PaymentDueDate
	,PaymentSched.PaymentType AS PaymentType
	,0
	FROM #Receivables AS ReceivableInfo
	JOIN Receivables Receivable ON ReceivableInfo.ReceivableId = Receivable.Id
	JOIN ReceivableCodes Code ON Receivable.ReceivableCodeId = Code.Id
	JOIN ReceivableTypes Type ON Code.ReceivableTypeId = Type.Id 
	JOIN LeasePaymentSchedules PaymentSched With (ForceSeek) ON Receivable.PaymentScheduleId = PaymentSched.Id 
		And Receivable.PaymentScheduleId > 0 -- Pls revise this query for recurring sundry????? RS
	
	INSERT INTO #ReceivableDetailsTemp
	SELECT ReceivableInfo.ContractId
	,Receivable.IncomeType
	,Receivable.Id AS ReceivableId
	,Type.Name AS ReceivableType
	,ReceivableInfo.LCBalance_Amount
	,ReceivableInfo.LCAmount_Amount
	,Receivable.DueDate
	,Receivable.FunderId
	,Receivable.IsGLPosted
	,Code.AccountingTreatment
	,Receivable.IsDummy
	,0.0
	,Null 
	,Null
	,Null
	,Null
	,0
	FROM #Receivables AS ReceivableInfo
	JOIN Receivables Receivable ON ReceivableInfo.ReceivableId = Receivable.Id
	JOIN ReceivableCodes Code ON Receivable.ReceivableCodeId = Code.Id
	JOIN ReceivableTypes Type ON Code.ReceivableTypeId = Type.Id 
		AND Receivable.PaymentScheduleId IS NULL

	--For NLC

	INSERT INTO #ReceivableDetailsTemp
	SELECT ReceivableInfo.ContractId
	,Receivable.IncomeType
	,Receivable.Id AS ReceivableId
	,Type.Name AS ReceivableType
	,ReceivableInfo.NLCBalance_Amount
	,ReceivableInfo.NLCAmount_Amount
	,Receivable.DueDate
	,Receivable.FunderId
	,Receivable.IsGLPosted
	,Code.AccountingTreatment
	,Receivable.IsDummy
	,0.0
	,PaymentSched.StartDate AS PaymentStartDate
	,PaymentSched.EndDate  AS PaymentEndDate
	,PaymentSched.DueDate  AS PaymentDueDate
	,PaymentSched.PaymentType AS PaymentType
	,1
	FROM #Receivables AS ReceivableInfo
	JOIN Receivables Receivable ON ReceivableInfo.ReceivableId = Receivable.Id
	JOIN ReceivableCodes Code ON Receivable.ReceivableCodeId = Code.Id
	JOIN ReceivableTypes Type ON Code.ReceivableTypeId = Type.Id 
	JOIN LeasePaymentSchedules PaymentSched With (ForceSeek) ON Receivable.PaymentScheduleId = PaymentSched.Id 
		And Receivable.PaymentScheduleId > 0

	INSERT INTO #ReceivableDetailsTemp
	SELECT ReceivableInfo.ContractId
	,Receivable.IncomeType
	,Receivable.Id AS ReceivableId
	,Type.Name AS ReceivableType
	,ReceivableInfo.NLCBalance_Amount
	,ReceivableInfo.NLCAmount_Amount
	,Receivable.DueDate
	,Receivable.FunderId
	,Receivable.IsGLPosted
	,Code.AccountingTreatment
	,Receivable.IsDummy
	,0.0
	,Null 
	,Null
	,Null
	,Null
	,1
	FROM #Receivables AS ReceivableInfo
	JOIN Receivables Receivable ON ReceivableInfo.ReceivableId = Receivable.Id
	JOIN ReceivableCodes Code ON Receivable.ReceivableCodeId = Code.Id
	JOIN ReceivableTypes Type ON Code.ReceivableTypeId = Type.Id 
		AND Receivable.PaymentScheduleId IS NULL
	END

	IF EXISTS(SELECT 1 FROM #LoanDetails)
	BEGIN
	INSERT INTO #ReceivableDetailsTemp
	SELECT Contract.ContractId
	,Receivable.IncomeType
	,Receivable.Id AS ReceivableId
	,Type.Name AS ReceivableType
	,Receivable.TotalBalance_Amount
	,Receivable.TotalAmount_Amount
	,Receivable.DueDate
	,Receivable.FunderId
	,Receivable.IsGLPosted
	,Code.AccountingTreatment
	,Receivable.IsDummy
	,Receivable.TotalBookBalance_Amount
	,PaymentSched.StartDate AS PaymentStartDate
	,PaymentSched.EndDate AS PaymentEndDate
	,PaymentSched.DueDate AS PaymentDueDate
	,PaymentSched.PaymentType AS PaymentType
	,CAST(0 AS BIT)
	FROM #LoanDetails Contract
	JOIN Receivables Receivable ON Contract.ContractId = Receivable.EntityId AND Receivable.EntityType = @ContractEntityType AND Receivable.IsActive=1
	JOIN ReceivableCodes Code ON Receivable.ReceivableCodeId = Code.Id
	JOIN ReceivableTypes Type ON Code.ReceivableTypeId = Type.Id
	LEFT JOIN LoanPaymentSchedules PaymentSched ON Receivable.PaymentScheduleId = PaymentSched.Id
	END
	IF EXISTS(SELECT 1 FROM #LeveragedLeaseDetails)
	BEGIN
	INSERT INTO #ReceivableDetailsTemp
	SELECT Contract.ContractId
	,Receivable.IncomeType
	,Receivable.Id AS ReceivableId
	,Type.Name AS ReceivableType
	,Receivable.TotalBalance_Amount
	,Receivable.TotalAmount_Amount
	,Receivable.DueDate
	,Receivable.FunderId
	,Receivable.IsGLPosted
	,Code.AccountingTreatment
	,Receivable.IsDummy
	,Receivable.TotalBookBalance_Amount
	,NULL AS PaymentStartDate
	,NULL AS PaymentEndDate
	,NULL AS PaymentDueDate
	,NULL AS PaymentType
	,CAST(0 AS BIT)
	FROM #LeveragedLeaseDetails Contract
	JOIN Receivables Receivable ON Contract.ContractId = Receivable.EntityId AND Receivable.EntityType = @ContractEntityType AND Receivable.IsActive=1
	JOIN ReceivableCodes Code ON Receivable.ReceivableCodeId = Code.Id
	JOIN ReceivableTypes Type ON Code.ReceivableTypeId = Type.Id
	END
	/*Receivable Temp Ends*/
	/*Basic Contract Date Info Begins*/
	UPDATE #BasicDetails
	SET MaxIncomeDatePriorToSyndication = SyndicatedInfo.IncomeDate
	FROM #BasicDetails Contract
	JOIN (SELECT IncomeSched.ContractId,
	MAX(IncomeSched.IncomeDate) AS IncomeDate
	FROM #LeaseIncomeScheduleTemp IncomeSched
	WHERE IncomeSched.IsSchedule = 1 AND IncomeSched.IsLessorOwned = 1 AND IncomeSched.IsGLPosted = 0 AND IncomeSched.IsIncomeBeforeCommencement = 0
	GROUP BY IncomeSched.ContractId) AS SyndicatedInfo
	ON Contract.ContractId = SyndicatedInfo.ContractId;

;WITH CTE_MaxGLPostedEndDate AS(
SELECT Receivable.ContractId
,MAX(Receivable.PaymentEnddate) AS EndDate
FROM #ReceivableDetailsTemp Receivable
JOIN #LoanDetails ON Receivable.ContractId = #LoanDetails.ContractId
WHERE Receivable.IsGLPosted = 1
AND Receivable.PaymentEnddate IS NOT NULL
AND Receivable.ReceivableType IN(@LoanInterest,@LoanPrincipal)
GROUP BY Receivable.ContractId
)
UPDATE #BasicDetails SET MaxIncomeDate = MaxIncomeDateTemp.MaxIncomeDate
From #BasicDetails Contract
JOIN (SELECT IncomeSched.ContractId
,MAX(IncomeSched.IncomeDate) AS MaxIncomeDate
FROM #LoanIncomeScheduleTemp IncomeSched
WHERE EXISTS(SELECT ContractId
FROM CTE_MaxGLPostedEndDate MaxGLPostedEnddate
WHERE MaxGLPostedEnddate.ContractId = IncomeSched.ContractId
AND MaxGLPostedEnddate.EndDate >= IncomeSched.IncomeDate
) AND IncomeSched.IsSchedule = 1
GROUP BY IncomeSched.ContractId) AS MaxIncomeDateTemp
ON Contract.ContractId = MaxIncomeDateTemp.ContractId

;WITH CTE_FullSaleMaxIncomeDate AS
(SELECT IncomeSched.ContractId
,MAX(IncomeSched.IncomeDate) AS MaxIncomeDate
FROM #SyndicationDetailsTemp SyndicationDetail
JOIN #LoanIncomeScheduleTemp IncomeSched ON SyndicationDetail.ReceivableForTransferType = @FullSale AND SyndicationDetail.IsServiced = 1
AND IncomeSched.ContractId = SyndicationDetail.Contractid
AND IncomeSched.IsLessorOwned = 0 AND IncomeSched.IsSchedule = 1
LEFT JOIN (SELECT Receivable.ContractId
,MAX(Receivable.PaymentEnddate) AS EndDate
FROM #LoanDetails Contract
JOIN #ReceivableDetailsTemp Receivable ON Contract.ContractId = Receivable.ContractId
AND Receivable.IsGLPosted = 1 AND Receivable.FunderId IS NOT NULL
AND Receivable.ReceivableType IN(@LoanInterest,@LoanPrincipal)
GROUP BY Receivable.ContractId) FullSaleGLPostedMaxDueDate ON IncomeSched.ContractId = FullSaleGLPostedMaxDueDate.ContractId
WHERE ((SyndicationDetail.IsCollected = 1 AND IncomeSched.IncomeDate <= FullSaleGLPostedMaxDueDate.EndDate)
OR (SyndicationDetail.IsCollected = 0 AND IncomeSched.IncomeDate <= @IncomeDate))
GROUP BY IncomeSched.ContractId)
UPDATE #BasicDetails SET FullSaleMaxIncomeDate = FullSaleMaxIncomeDate.MaxIncomeDate
From #BasicDetails Contract
JOIN CTE_FullSaleMaxIncomeDate FullSaleMaxIncomeDate ON Contract.ContractId = FullSaleMaxIncomeDate.ContractId
/*Non And ReAccrual Date Begins*/
UPDATE #BasicDetails
SET MaxNonAccrualDate = NonAccrual.NonAccrualDate
FROM #BasicDetails Contract
JOIN (SELECT Contract.ContractId,
Max(NonAccrualContract.NonAccrualDate) AS NonAccrualDate
FROM #BasicDetails Contract
JOIN NonAccrualContracts NonAccrualContract ON Contract.ContractId = NonAccrualContract.ContractId AND NonAccrualContract.IsActive = 1 AND IsNonAccrualApproved = 1  
GROUP BY Contract.ContractId) as NonAccrual ON Contract.ContractId = NonAccrual.ContractId;
/*Non And ReAccrual Date Ends*/
/*ChargeOff Date Begins*/
UPDATE #BasicDetails SET ChargeOffDate = ChargeOff.ChargeOffDate
FROM #BasicDetails Contract
JOIN ChargeOffs ChargeOff ON Contract.ContractId = ChargeOff.ContractId AND ChargeOff.IsActive = 1 AND ChargeOff.IsRecovery = 0 ;
/*ChargeOff Date Ends*/
/*Basic Contract Date Info Ends*/
/*Loan Finance Basic Temp*/
IF EXISTS(SELECT 1 FROM #LoanDetails)
BEGIN
INSERT INTO #LoanFinanceBasicTemp
SELECT Contract.ContractId,
(InvoiceOtherCost.Amount_Amount) AS Amount
,Funding.FundingId
,Funding.Type
,Invoice.Id AS PayableInvoiceId
,Invoice.Status
,InvoiceOtherCost.Id AS OtherCostId
,Invoice.IsForeignCurrency
,Invoice.InitialExchangeRate
,Invoice.InvoiceDate
,Invoice.SourceTransaction
,CASE WHEN Funding.Type = @Origination THEN 1 ELSE 0 END AS IsOrigination
FROM #LoanDetails Contract
JOIN LoanFundings Funding ON Contract.LoanFinanceId = Funding.LoanFinanceId AND Funding.IsActive = 1
JOIN PayableInvoices Invoice ON Funding.FundingId = Invoice.Id
JOIN PayableInvoiceOtherCosts InvoiceOtherCost ON Invoice.Id = InvoiceOtherCost.PayableInvoiceId AND InvoiceOtherCost.IsActive = 1
WHERE InvoiceOtherCost.AllocationMethod = @LoanDisbursementAllocationMethod
END
/*Loan Finance Basic Temp*/
/*Leveraged Lease Calc Begins*/
IF EXISTS(SELECT 1 FROM #LeveragedLeaseDetails)
BEGIN
;WITH CTE_LeveragedLeaseInfo AS (
SELECT Contract.ContractId,
SUM(Amort.IDC_Amount) AS IDCAmount,
MAX(Amort.IncomeDate) AS MaxIncomeDate
FROM #LeveragedLeaseDetails Contract
JOIN LeveragedLeases LeveragedLease ON LeveragedLease.ContractId = Contract.ContractId
JOIN LeveragedLeaseAmorts Amort ON Amort.LeveragedLeaseId = LeveragedLease.Id
WHERE Amort.IsAccounting = 1 AND Amort.IsActive = 1 AND Amort.IsSchedule = 1 AND Amort.IsGLPosted = 1
GROUP BY Contract.ContractId
)
UPDATE #RNITemp
SET IDCBalance_Amount = LeveragedLeaseInfo.IDCAmount,
UnguaranteedResidual_Amount = Amort.ResidualReceivable_Amount,
UnearnedRentalIncome_Amount = Amort.UnearnedIncome_Amount
FROM #RNITemp RNI
JOIN CTE_LeveragedLeaseInfo LeveragedLeaseInfo ON RNI.ContractId = LeveragedLeaseInfo.ContractId
JOIN LeveragedLeases LeveragedLease ON LeveragedLeaseInfo.ContractId = LeveragedLease.ContractId
JOIN LeveragedLeaseAmorts Amort ON LeveragedLease.Id = Amort.LeveragedLeaseId AND LeveragedLeaseInfo.MaxIncomeDate = Amort.IncomeDate
WHERE Amort.IsAccounting = 1 AND Amort.IsActive = 1 AND Amort.IsSchedule = 1 AND Amort.IsGLPosted = 1
END
/*Leveraged Lease Calc Ends*/
IF EXISTS(SELECT 1 FROM #LoanDetails WHERE IsProgressLoan = 1)
BEGIN
/*Progress Payment Credits*/ -- CE
;WITH CTE_ProgressPaymentCredit AS(
SELECT Contract.ContractId
, ABS(SUM(TakeDownOtherCost.Amount_Amount)) AS ProgressPaymentCredit
FROM (SELECT ContractId,LoanFinanceId FROM #LoanDetails WHERE IsProgressLoan=1) Contract
JOIN LoanFundings Funding ON Contract.LoanFinanceId = Funding.LoanFinanceId AND Funding.IsActive = 1
JOIN PayableInvoiceOtherCosts InvoiceOtherCost ON Funding.FundingId = InvoiceOtherCost.PayableInvoiceId AND InvoiceOtherCost.IsActive = 1
JOIN PayableInvoiceOtherCosts TakeDownOtherCost ON InvoiceOtherCost.Id = TakeDownOtherCost.ProgressFundingId AND TakeDownOtherCost.IsActive = 1 AND TakeDownOtherCost.AllocationMethod=@ProgressPaymentCreditAllocationMethod
JOIN DisbursementRequestInvoices DRInvoice ON TakeDownOtherCost.PayableInvoiceId = DRInvoice.InvoiceId AND DRInvoice.IsActive = 1
JOIN DisbursementRequests DR ON DRInvoice.DisbursementRequestId = DR.Id AND DR.Status != @InactiveStatus
GROUP BY Contract.ContractId
UNION ALL
SELECT Contract.ContractId
, ABS(SUM(TakeDownOtherCost.Amount_Amount)) AS ProgressPaymentCredit
FROM (SELECT ContractId,LoanFinanceId FROM #LoanDetails WHERE IsProgressLoan=1 AND SyndicationType != @None) Contract
JOIN PayableInvoiceOtherCosts TakeDownOtherCost ON TakeDownOtherCost.ContractId = Contract.ContractId AND TakeDownOtherCost.AllocationMethod = @ProgressPaymentCreditAllocationMethod
JOIN PayableInvoiceOtherCosts ProgressFundingOtherCost on TakeDownOtherCost.ProgressFundingId = ProgressFundingOtherCost.Id AND TakeDownOtherCost.IsActive=1
JOIN LoanFundings ProgressFunding ON  ProgressFundingOtherCost.PayableInvoiceId = ProgressFunding.FundingId AND ProgressFunding.IsActive = 1 AND ProgressFunding.LoanFinanceId = Contract.LoanFinanceId
JOIN LoanFundings Funding ON TakeDownOtherCost.PayableInvoiceId = Funding.FundingId AND Funding.IsActive=1
JOIN LoanFinances Loan on Funding.LoanFinanceId = Loan.Id AND Loan.Status IN (@CommencedStatus,@FullyPaidOff) AND Loan.IsCurrent = 1
JOIN LoanSyndications ON Loan.Id = LoanSyndications.Id
GROUP BY Contract.ContractId
UNION ALL
SELECT Contract.ContractId
,SUM(LeaseSyndicationPPC.TakeDownAmount_Amount) AS ProgressPaymentCredit
FROM (SELECT ContractId,LoanFinanceId FROM #LoanDetails WHERE IsProgressLoan=1) Contract
JOIN LoanFundings LoanFunding ON Contract.LoanFinanceId = LoanFunding.LoanFinanceId AND LoanFunding.IsActive = 1
JOIN PayableInvoiceOtherCosts InvoiceOtherCost ON LoanFunding.FundingId = InvoiceOtherCost.PayableInvoiceId AND InvoiceOtherCost.IsActive = 1
JOIN LeaseSyndicationProgressPaymentCredits LeaseSyndicationPPC ON InvoiceOtherCost.Id = LeaseSyndicationPPC.PayableInvoiceOtherCostId AND LeaseSyndicationPPC.IsActive = 1
JOIN LeaseSyndications LeaseSyndication ON LeaseSyndicationPPC.LeaseSyndicationId = LeaseSyndication.Id
JOIN LeaseFinances Lease ON LeaseSyndication.Id = Lease.Id AND Lease.IsCurrent=1 AND Lease.BookingStatus IN(@CommencedStatus,@FullyPaidOff)
GROUP BY Contract.ContractId)
UPDATE #RNITemp
SET ProgressPaymentCredits_Amount = ProgressPayment.ProgressPaymentCredit
FROM #RNITemp RNI
JOIN (SELECT ContractId, SUM(ProgressPaymentCredit) AS ProgressPaymentCredit FROM CTE_ProgressPaymentCredit GROUP BY ContractId )
AS ProgressPayment ON RNI.ContractId = ProgressPayment.ContractId
/*Progress Fundings*/
;WITH CTE_UnMigratedProgressFundings AS
(SELECT Contract.ContractId
,SUM(CASE WHEN LoanTemp.IsForeignCurrency = 0 THEN (LoanTemp.Amount) ELSE (LoanTemp.Amount * LoanTemp.InitialExchangeRate) END) AS Amount
FROM (SELECT ContractId,LoanFinanceId FROM #LoanDetails WHERE IsProgressLoan=1 AND IsMigratedContract=0) Contract
JOIN #LoanFinanceBasicTemp LoanTemp ON Contract.ContractId = LoanTemp.ContractId
JOIN DisbursementRequestInvoices DRInvoice ON LoanTemp.FundingId = DRInvoice.InvoiceId AND DRInvoice.IsActive = 1
JOIN DisbursementRequests DR ON DRInvoice.DisbursementRequestId = DR.Id AND DR.Status != @InactiveStatus
WHERE LoanTemp.Type != @OriginationRestoredType
GROUP BY Contract.ContractId),
CTE_MigratedProgressFundings AS
(SELECT Contract.ContractId
,SUM(CASE WHEN LoanTemp.IsForeignCurrency = 0 THEN (LoanTemp.Amount) ELSE (LoanTemp.Amount * LoanTemp.InitialExchangeRate) END) AS Amount
FROM (SELECT ContractId,LoanFinanceId FROM #LoanDetails WHERE IsProgressLoan=1 AND IsMigratedContract=1) Contract
JOIN #LoanFinanceBasicTemp LoanTemp ON Contract.ContractId = LoanTemp.ContractId AND LoanTemp.Status = @CompletedStatus
LEFT JOIN Payables Payable ON LoanTemp.OtherCostId = Payable.SourceId AND Payable.SourceTable = @PayableInvoiceOtherCostSourceTable
WHERE LoanTemp.Type != @OriginationRestoredType AND Payable.Id IS NULL
GROUP BY Contract.ContractId)
UPDATE #RNITemp SET ProgressFundings_Amount = ISNULL(ProgressFunding.Amount,0) + ISNULL(MigratedProgressFunding.Amount,0),
TotalFinancedAmount_Amount = ISNULL(MigratedProgressFunding.Amount,0)
FROM #RNITemp RNI
LEFT JOIN CTE_UnMigratedProgressFundings ProgressFunding ON RNI.ContractId = ProgressFunding.ContractId
LEFT JOIN CTE_MigratedProgressFundings MigratedProgressFunding ON RNI.ContractId = MigratedProgressFunding.ContractId
END
/*Total Financed Amount*/
/* Un Migrated */

	;WITH CTE_DistinctAsset AS
	(
	SELECT  LeaseAsset.ContractId,LeaseAsset.IsMigratedContract,LeaseAsset.AssetId,
	LeaseAsset.CapitalizationType,SUM(LeaseAsset.Amount)'Amount',LeaseAsset.CapitalizedForId,LeaseAsset.LeaseAssetId
	 FROM #AssetTemp AS LeaseAsset
	 GROUP BY LeaseAsset.ContractId,LeaseAsset.IsMigratedContract,LeaseAsset.AssetId,
	LeaseAsset.CapitalizationType,LeaseAsset.CapitalizedForId,LeaseAsset.LeaseAssetId
	),

	CTE_NBV AS
	(SELECT LeaseAsset.ContractId
	, SUM(CASE WHEN Invoice.IsForeignCurrency = 0 THEN DRPayable.AmountToPay_Amount ELSE (DRPayable.AmountToPay_Amount * Invoice.InitialExchangeRate) END) AS NBVAmount
	FROM CTE_DistinctAsset AS LeaseAsset
	JOIN PayableInvoiceAssets InvoiceAsset ON LeaseAsset.IsMigratedContract = 0 AND LeaseAsset.AssetId = InvoiceAsset.AssetId AND InvoiceAsset.IsActive = 1
	JOIN PayableInvoices Invoice ON InvoiceAsset.PayableInvoiceId = Invoice.Id AND Invoice.Status = @CompletedStatus
	JOIN Payables Payable ON InvoiceAsset.Id = Payable.SourceId AND Payable.SourceTable = @PayableInvoiceAssetSourceTable AND Payable.Status != @InactiveStatus
	JOIN DisbursementRequestPayables DRPayable ON Payable.Id = DRPayable.PayableId AND DRPayable.IsActive = 1
	JOIN DisbursementRequests DR ON DRPayable.DisbursementRequestId = DR.Id AND DR.Status = @CompletedStatus
	GROUP BY LeaseAsset.ContractId),

	CTE_AdjOtherCost AS
	(SELECT LeaseAsset.ContractId
	, SUM(CASE WHEN Invoice.IsForeignCurrency = 0 THEN DRPayable.AmountToPay_Amount  ELSE (DRPayable.AmountToPay_Amount * Invoice.InitialExchangeRate) END) AS Amount
	FROM CTE_DistinctAsset AS LeaseAsset
	JOIN PayableInvoiceOtherCosts InvoiceOtherCost ON LeaseAsset.IsMigratedContract = 0 AND LeaseAsset.AssetId = InvoiceOtherCost.AssetId AND InvoiceOtherCost.IsActive = 1 AND InvoiceOtherCost.AllocationMethod = @SpecificCostAdjustment
	JOIN PayableInvoices Invoice ON InvoiceOtherCost.PayableInvoiceId = Invoice.Id AND Invoice.Status = @CompletedStatus
	JOIN Payables Payable ON InvoiceOtherCost.Id = Payable.SourceId AND Payable.SourceTable = @PayableInvoiceOtherCostSourceTable AND Payable.Status != @InactiveStatus
	JOIN DisbursementRequestPayables DRPayable ON Payable.Id = DRPayable.PayableId AND DRPayable.IsActive = 1
	JOIN DisbursementRequests DR ON DRPayable.DisbursementRequestId = DR.Id AND DR.Status = @CompletedStatus
	GROUP BY LeaseAsset.ContractId),

	CTE_CapitalizedSalesNBV AS
	(SELECT CapitalizedLeaseAsset.ContractId
	,SUM(CapitalizedLeaseAsset.Amount) AS CapitalizedSalesNBVAmount
	FROM CTE_DistinctAsset CapitalizedLeaseAsset
	JOIN CTE_DistinctAsset LeaseAsset ON CapitalizedLeaseAsset.IsMigratedContract = 0 AND CapitalizedLeaseAsset.CapitalizationType = @CapitalizedSalesTax
	AND CapitalizedLeaseAsset.CapitalizedForId = LeaseAsset.LeaseAssetId
	JOIN PayableInvoiceAssets InvoiceAsset ON LeaseAsset.AssetId = InvoiceAsset.AssetId AND InvoiceAsset.IsActive = 1
	JOIN Payables Payable ON InvoiceAsset.Id = Payable.SourceId AND Payable.SourceTable = @PayableInvoiceAssetSourceTable AND Payable.Status != @InactiveStatus
	JOIN DisbursementRequestPayables DRPayable ON Payable.Id = DRPayable.PayableId AND DRPayable.IsActive = 1
	JOIN DisbursementRequests DR ON DRPayable.DisbursementRequestId = DR.Id AND DR.Status = @CompletedStatus
	GROUP BY CapitalizedLeaseAsset.ContractId)
	UPDATE #RNITemp SET TotalFinancedAmount_Amount =  NBV.NBVAmount +  ISNULL(AdjOtherCost.Amount,0) +  ISNULL(CapitalizedNBV.CapitalizedSalesNBVAmount,0)
	FROM #RNITemp RNI
	JOIN CTE_NBV NBV ON RNI.ContractId = NBV.ContractId
	LEFT JOIN CTE_AdjOtherCost AdjOtherCost ON RNI.ContractId = AdjOtherCost.ContractId
	LEFT JOIN CTE_CapitalizedSalesNBV CapitalizedNBV ON RNI.ContractId = CapitalizedNBV.ContractId
	/* Migrated */
	IF EXISTS(SELECT 1 FROM #LeaseDetails WHERE IsMigratedContract = 1)
	BEGIN
	UPDATE #RNITemp SET TotalFinancedAmount_Amount = Asset.Amount
	FROM #RNITemp RNI
	JOIN (SELECT LeaseAsset.ContractId
	, SUM(LeaseAsset.Amount) AS Amount
	FROM #AssetTemp LeaseAsset
	WHERE LeaseAsset.IsMigratedContract = 1
	GROUP BY LeaseAsset.ContractId)
	AS Asset ON RNI.ContractId = Asset.ContractId
	END
	IF EXISTS(SELECT 1 FROM #LoanDetails)
	BEGIN
	;WITH CTE_FundingsWithCompletedDR AS
	(SELECT LoanTemp.ContractId
	,SUM(CASE WHEN LoanTemp.IsForeignCurrency = 0 THEN (LoanTemp.Amount) ELSE (LoanTemp.Amount * LoanTemp.InitialExchangeRate) END) AS FinancedAmount
	FROM (SELECT * FROM #LoanFinanceBasicTemp WHERE IsOrigination = 1) LoanTemp
	JOIN Payables Payable ON LoanTemp.OtherCostId = Payable.SourceId AND Payable.SourceTable = @PayableInvoiceOtherCostSourceTable AND Payable.Status != @InactiveStatus
	JOIN DisbursementRequestPayables DRPayable ON Payable.Id = DRPayable.PayableId AND DRPayable.IsActive = 1
	JOIN DisbursementRequests DR ON DRPayable.DisbursementRequestId = DR.Id AND DR.Status = @CompletedStatus
	GROUP BY LoanTemp.ContractId),
	CTE_FundingsForMigratedContract AS
	(SELECT Contract.ContractId
	,SUM(CASE WHEN LoanTemp.IsForeignCurrency = 0 THEN (LoanTemp.Amount) ELSE (LoanTemp.Amount * LoanTemp.InitialExchangeRate) END) AS FinancedAmount
	FROM (SELECT ContractId FROM #LoanDetails WHERE IsProgressLoan=0 AND IsMigratedContract = 1) Contract
	JOIN #LoanFinanceBasicTemp LoanTemp ON Contract.ContractId = LoanTemp.ContractId AND LoanTemp.IsOrigination = 1	AND LoanTemp.Status = @CompletedStatus
	LEFT JOIN Payables Payable ON LoanTemp.OtherCostId = Payable.SourceId AND Payable.SourceTable = @PayableInvoiceOtherCostSourceTable
	WHERE Payable.Id IS NULL
	GROUP BY Contract.ContractId)
	UPDATE #RNITemp
	SET TotalFinancedAmount_Amount = CASE WHEN Contract.IsProgressLoan=0
	THEN ISNULL(FundingsWithCompletedDR.FinancedAmount,0) +  ISNULL(FundingsForMigratedContract.FinancedAmount,0)
	ELSE RNI.TotalFinancedAmount_Amount + ISNULL(FundingsWithCompletedDR.FinancedAmount,0) - ISNULL(RNI.ProgressPaymentCredits_Amount,0)
	END
	FROM #RNITemp RNI
	JOIN #LoanDetails Contract ON RNI.ContractId = Contract.ContractId
	LEFT JOIN CTE_FundingsWithCompletedDR FundingsWithCompletedDR ON RNI.ContractId = FundingsWithCompletedDR.ContractId
	LEFT JOIN CTE_FundingsForMigratedContract FundingsForMigratedContract ON RNI.ContractId = FundingsForMigratedContract.ContractId
	END
	/*Principal Balance*/ -- CE
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
	FROM #LoanDetails Contract
	JOIN LoanFinances Loan ON Contract.ContractId = Loan.ContractId
	JOIN LoanPaydowns LoanPaydown ON Loan.Id = LoanPaydown.LoanFinanceId AND LoanPaydown.Status = @ActiveStatus;
	UPDATE #LoanDetails
	SET PrincipalBalance = EndNBVInfo.EndNetBookValue_Amount, PrincipalBalanceIncomeExists = CAST(1 AS BIT)
	FROM #LoanDetails Loan
	JOIN (SELECT IncomeSched.ContractId
	,SUM(IncomeSched.EndNetBookValue_Amount) EndNetBookValue_Amount
	FROM #LoanIncomeScheduleTemp IncomeSched
	JOIN #BasicDetails Contract ON Contract.ContractId = IncomeSched.ContractId AND IncomeSched.IncomeDate = Contract.MaxIncomeDate
	AND IncomeSched.IsLessorOwned = 1 AND IncomeSched.IsSchedule = 1
	GROUP BY IncomeSched.ContractId)
	AS EndNBVInfo ON Loan.ContractId = EndNBVInfo.ContractId;
	UPDATE #LoanDetails
	SET TotalAmount = LoanDisbursementInfo.TotalAmount
	FROM #LoanDetails Loan
	JOIN (SELECT LoanTemp.ContractId,
	SUM(CASE WHEN LoanTemp.IsForeignCurrency = 0 THEN (LoanTemp.Amount) ELSE (LoanTemp.Amount * LoanTemp.InitialExchangeRate) END) TotalAmount
	FROM #LoanFinanceBasicTemp LoanTemp
	WHERE LoanTemp.Status = @CompletedStatus AND LoanTemp.IsOrigination = 1
	GROUP BY LoanTemp.ContractId)
	AS LoanDisbursementInfo ON Loan.ContractId = LoanDisbursementInfo.ContractId;
	;WITH CTE_DownPaymentInfo AS
	(SELECT Receivable.ContractId
	,Receivable.IsGLPosted
	,SUM(Receivable.Amount_Amount) AS Downpayment
	FROM #ReceivableDetailsTemp Receivable
	WHERE Receivable.PaymentType = @LoanDownPayment
	GROUP BY Receivable.ContractId,Receivable.IsGLPosted)
	UPDATE #LoanDetails
	SET PrincipalBalance = PrincipalBalance + ISNULL(PrincipalInfo.Downpayment,0.00),
	TotalAmount = TotalAmount - ISNULL(DisbursementInfo.Downpayment,0.00)
	FROM #LoanDetails Loan
	LEFT JOIN CTE_DownPaymentInfo PrincipalInfo ON Loan.ContractId = PrincipalInfo.ContractId AND PrincipalInfo.IsGLPosted = 0
	LEFT JOIN CTE_DownPaymentInfo DisbursementInfo ON Loan.ContractId = DisbursementInfo.ContractId AND DisbursementInfo.IsGLPosted = 1;
	END
	IF EXISTS(SELECT 1 FROM #LoanDetails WHERE SyndicationType <> @None and IsProgressLoan = 0)
	BEGIN
	;WITH CTE_PrincipalBalanceFunderPortion AS
	(SELECT Contract.ContractId
	,(CASE WHEN SyndicationDetail.ReceivableForTransferType = @FullSale
	THEN (CASE WHEN Contract.PrincipalBalanceIncomeExists = 0 THEN Contract.TotalAmount ELSE Contract.PrincipalBalance END)
	ELSE ((CASE WHEN SyndicationDetail.RetainedPercentage != 0 AND (ContractDateInfo.MaxIncomeDate IS NULL OR ContractDateInfo.MaxIncomeDate >= SyndicationDetail.SyndicationEffectiveDate)
	THEN (CASE WHEN Contract.PrincipalBalanceIncomeExists = 0
	THEN (Contract.TotalAmount * ((100 - SyndicationDetail.RetainedPercentage)/100))
	ELSE (Contract.PrincipalBalance / (SyndicationDetail.RetainedPercentage/100)) * ((1 - (SyndicationDetail.RetainedPercentage/100))) END)
	ELSE 0 END))
	END) AS PrincipalBalanceFunderPortionAmount
	FROM (SELECT ContractId,PrincipalBalance,PrincipalBalanceIncomeExists,TotalAmount FROM #LoanDetails WHERE IsProgressLoan = 0 AND IsChargedOff = 0) Contract
	JOIN #SyndicationDetailsTemp SyndicationDetail ON Contract.ContractId = SyndicationDetail.ContractId
	JOIN #BasicDetails ContractDateInfo ON Contract.ContractId = ContractDateInfo.ContractId)
	UPDATE #RNITemp
	SET PrincipalBalanceFunderPortion_Amount = FunderPortion.PrincipalBalanceFunderPortionAmount
	FROM #RNITemp RNI
	JOIN CTE_PrincipalBalanceFunderPortion FunderPortion ON RNI.ContractId = FunderPortion.ContractId
	END
	IF EXISTS(SELECT 1 FROM #LoanDetails WHERE SyndicationType <> @FullSale and IsProgressLoan = 0)
	BEGIN
	UPDATE #RNITemp
	SET PrincipalBalance_Amount = (CASE WHEN Contract.PrincipalBalanceIncomeExists = 0
	THEN ISNULL(Contract.TotalAmount,0) - ISNULL(RNI.PrincipalBalanceFunderPortion_Amount,0)
	ELSE ISNULL(Contract.PrincipalBalance,0) END)
	FROM #RNITemp RNI
	JOIN #LoanDetails Contract ON Contract.ContractId = RNI.ContractId AND Contract.SyndicationType != @FullSale AND Contract.IsProgressLoan = 0 AND Contract.IsChargedOff = 0
	END
	;WITH CTE_FutureDatedPaydown AS
	(SELECT PaydownTemp.ContractId,
	SUM(CASE WHEN PaydownTemp.PaydownReason = @FullPaydown AND PaydownTemp.IsDailySensitive = 0 THEN (ISNULL(PaydownTemp.PrincipalBalance_Amount,0) - ISNULL(PaydownTemp.PrincipalPaydown_Amount,0))
	WHEN PaydownTemp.PaydownReason = @Casualty THEN ISNULL(PaydownTemp.PrincipalPaydown_Amount,0) ELSE 0 END) AS PaydownAmount
	FROM #LoanPaydownTemp PaydownTemp
	JOIN #LoanDetails Contract ON Contract.ContractId = PaydownTemp.ContractId AND PaydownTemp.PaydownReason IN(@FullPaydown,@Casualty)
	AND Contract.SyndicationType != @FullSale AND Contract.IsChargedOff = 0
	JOIN #BasicDetails ContractDateInfo ON PaydownTemp.ContractId = ContractDateInfo.ContractId
	AND PaydownTemp.PaydownDate > ISNULL(ContractDateInfo.MaxIncomeDate,DATEADD(DAY,-1,Contract.CommencementDate))
	GROUP BY PaydownTemp.ContractId)
	UPDATE #RNITemp
	SET PrincipalBalance_Amount = PrincipalBalance_Amount - FuturePaydown.PaydownAmount
	FROM #RNITemp RNI
	JOIN CTE_FutureDatedPaydown FuturePaydown ON RNI.ContractId = FuturePaydown.ContractId
	;
	;WITH CTE_CapitalizedInterestPositiveAdjustment AS
	(SELECT Contract.ContractId
	, SUM(ISNULL(CapInterest.Amount_Amount,0)) AS CapitalizedInterestPositiveAdjustment
	FROM (SELECT ContractId,LoanFinanceId,CommencementDate FROM #LoanDetails WHERE IsProgressLoan=0 AND SyndicationType != @FullSale AND IsChargedOff = 0) Contract
	JOIN LoanCapitalizedInterests CapInterest ON Contract.LoanFinanceId = CapInterest.LoanFinanceId AND CapInterest.IsActive=1 AND CapInterest.GLJournalId IS NOT NULL
	JOIN #BasicDetails ContractDateInfo ON Contract.ContractId = ContractDateInfo.ContractId
	WHERE ((CapInterest.Source IN (@CapitalizedInterestDueToSkipPayments,@CapitalizedInterestDueToRateChange,@CapitalizedInterestFromPaydown)
	AND CapInterest.CapitalizedDate > ISNULL(ContractDateInfo.MaxIncomeDate,DATEADD(DAY,-1,Contract.CommencementDate)))
	OR (CapInterest.Source IN (@CapitalizedInterestDueToScheduledFunding) AND CapInterest.CapitalizedDate > ISNULL(ContractDateInfo.MaxIncomeDate,DATEADD(DAY,-1,Contract.CommencementDate))))
	GROUP BY Contract.ContractId)
	UPDATE #RNITemp
	SET PrincipalBalance_Amount = PrincipalBalance_Amount + PositiveAdjustment.CapitalizedInterestPositiveAdjustment
	FROM #RNITemp RNI
	JOIN CTE_CapitalizedInterestPositiveAdjustment PositiveAdjustment ON RNI.ContractId = PositiveAdjustment.ContractId
	;
	;WITH CTE_CapitalizedInterestNegativeAdjustment AS
	(SELECT Contract.ContractId
	, SUM(ISNULL(CapInterest.Amount_Amount,0)) AS CapitalizedInterestNegativeAdjustment
	FROM (SELECT ContractId,LoanFinanceId,CommencementDate FROM #LoanDetails WHERE IsProgressLoan=0 AND SyndicationType != @FullSale AND IsChargedOff = 0) Contract
	JOIN LoanCapitalizedInterests CapInterest ON Contract.LoanFinanceId = CapInterest.LoanFinanceId AND CapInterest.IsActive=1 AND CapInterest.GLJournalId IS NULL
	JOIN #BasicDetails ContractDateInfo ON Contract.ContractId = ContractDateInfo.ContractId
	WHERE ((CapInterest.Source IN (@CapitalizedInterestDueToSkipPayments,@CapitalizedInterestDueToRateChange,@CapitalizedInterestFromPaydown)
	AND CapInterest.CapitalizedDate <= ContractDateInfo.MaxIncomeDate) OR (CapInterest.Source IN (@CapitalizedInterestDueToScheduledFunding) AND CapInterest.CapitalizedDate <= DATEADD(DAY,1,ContractDateInfo.MaxIncomeDate)))
	GROUP BY Contract.ContractId)
	UPDATE #RNITemp
	SET PrincipalBalance_Amount = PrincipalBalance_Amount - NegativeAdjustment.CapitalizedInterestNegativeAdjustment
	FROM #RNITemp RNI
	JOIN CTE_CapitalizedInterestNegativeAdjustment NegativeAdjustment ON RNI.ContractId = NegativeAdjustment.ContractId
	;
	IF EXISTS(SELECT 1 FROM #LoanDetails WHERE SyndicationType = @FullSale)
	BEGIN
	UPDATE #RNITemp
	SET PrincipalBalance_Amount =  CASE WHEN Contract.CommencementDate != SyndicationDetail.SyndicationEffectiveDate THEN Contract.PrincipalBalance ELSE 0 END
	FROM #RNITemp RNI
	JOIN #LoanDetails Contract ON Contract.ContractId = RNI.ContractId AND Contract.SyndicationType = @FullSale AND Contract.IsChargedOff = 0 AND Contract.IsProgressLoan = 0
	JOIN #SyndicationDetailsTemp SyndicationDetail ON Contract.ContractId = SyndicationDetail.ContractId;
	END
	UPDATE #RNITemp
	SET PrincipalBalance_Amount = CASE WHEN ContractDateInfo.MaxIncomeDate IS NULL THEN 0 ELSE RNI.PrincipalBalance_Amount END
	FROM #RNITemp RNI
	JOIN #LoanDetails Contract ON Contract.ContractId = RNI.ContractId AND Contract.Status = @FullyPaidOff
	JOIN #LoanPaydownTemp PaydownTemp ON Contract.ContractId = PaydownTemp.ContractId AND Contract.CommencementDate = PaydownTemp.PaydownDate
	JOIN #BasicDetails ContractDateInfo ON Contract.ContractId = ContractDateInfo.ContractId
	;
	IF EXISTS(SELECT 1 FROM #LoanDetails WHERE SyndicationType = @FullSale)
	BEGIN
	WITH CTE_PrincipalBalanceFunderPortion AS
	(SELECT IncomeSched.ContractId
	,SUM(IncomeSched.EndNetBookValue_Amount) AS PrincipalBalance
	FROM (SELECT ContractId FROM #LoanDetails WHERE SyndicationType = @FullSale AND IsChargedOff = 0) Contract
	JOIN #BasicDetails ContractDateInfo ON Contract.ContractId = ContractDateInfo.ContractId
	JOIN #LoanIncomeScheduleTemp IncomeSched ON Contract.ContractId = IncomeSched.ContractId AND ContractDateInfo.FullSaleMaxIncomeDate = IncomeSched.IncomeDate
	AND IncomeSched.IsSchedule = 1 AND IncomeSched.IsLessorOwned = 0
	GROUP BY IncomeSched.ContractId)
	UPDATE #RNITemp SET PrincipalBalanceFunderPortion_Amount = FunderPortion.PrincipalBalance
	FROM #RNITemp RNI
	JOIN CTE_PrincipalBalanceFunderPortion FunderPortion ON RNI.ContractId = FunderPortion.ContractId

	UPDATE #RNITemp
	SET PrincipalBalanceFunderPortion_Amount = IIF((ContractDateInfo.MaxIncomeDate < DATEADD(DAY,-1,SyndicationDetail.SyndicationEffectiveDate) 
	OR SyndicationDetail.IsServiced = 0),0 , RNI.PrincipalBalanceFunderPortion_Amount)
	FROM #RNITemp RNI
	JOIN #SyndicationDetailsTemp SyndicationDetail ON RNI.ContractId = SyndicationDetail.ContractId
	JOIN #BasicDetails ContractDateInfo ON RNI.ContractId = ContractDateInfo.ContractId AND ContractDateInfo.SyndicationType = @FullSale AND ContractDateInfo.IsChargedOff = 0

UPDATE #RNITemp
SET PrincipalBalance_Amount = IIF(ContractDateInfo.MaxIncomeDate = DATEADD(DAY,-1,SyndicationDetail.SyndicationEffectiveDate), 0 , RNI.PrincipalBalance_Amount)
FROM #RNITemp RNI
JOIN #SyndicationDetailsTemp SyndicationDetail ON RNI.ContractId = SyndicationDetail.ContractId
JOIN #BasicDetails ContractDateInfo ON RNI.ContractId = ContractDateInfo.ContractId AND ContractDateInfo.SyndicationType = @FullSale AND ContractDateInfo.IsChargedOff = 0
;
END
/*Principal Balance Adjustment*/
IF EXISTS(SELECT 1 FROM #LoanFinanceBasicTemp WHERE IsOrigination = 0)
BEGIN
;WITH CTE_FutureScheduleReceivableDetails AS
(SELECT LoanTemp.ContractId,
LoanTemp.FundingId,
MAX(ReceivableDetail.PaymentDueDate) AS DueDate
FROM (SELECT * FROM #LoanFinanceBasicTemp WHERE IsOrigination = 0) LoanTemp
JOIN #ReceivableDetailsTemp ReceivableDetail ON LoanTemp.ContractId = ReceivableDetail.ContractId
AND LoanTemp.InvoiceDate >= ReceivableDetail.PaymentStartDate AND LoanTemp.InvoiceDate <= ReceivableDetail.PaymentEndDate
WHERE ReceivableDetail.ReceivableType IN(@LoanInterest,@LoanPrincipal)
GROUP BY LoanTemp.ContractId, LoanTemp.FundingId)
INSERT INTO #FutureScheduledFundedTemp
SELECT LoanTemp.ContractId,
LoanTemp.FundingId,
LoanTemp.Amount,
DATEADD(DAY,-1,LoanTemp.InvoiceDate) AS InvoiceDate,
DRPayable.RequestedPaymentDate AS PaymentDate,
DR.Status DRStatus,
ReceivableDetail.DueDate,
CAST(0 AS BIT) AS IsGLPosted
FROM (SELECT * FROM #LoanFinanceBasicTemp WHERE IsOrigination = 0) LoanTemp
LEFT JOIN CTE_FutureScheduleReceivableDetails AS ReceivableDetail ON LoanTemp.ContractId = ReceivableDetail.ContractId AND LoanTemp.FundingId = ReceivableDetail.FundingId
LEFT JOIN DisbursementRequestInvoices DRInvoice ON LoanTemp.PayableInvoiceId = DRInvoice.InvoiceId AND DRInvoice.IsActive = 1
LEFT JOIN DisbursementRequestPaymentDetails DRPayable ON DRInvoice.DisbursementRequestId = DRPayable.DisbursementRequestId AND DRPayable.IsActive = 1
LEFT JOIN DisbursementRequests DR ON DRPayable.DisbursementRequestId = DR.Id;
UPDATE #FutureScheduledFundedTemp SET IsGLPosted = ReceivableDetail.IsGLPosted
FROM #FutureScheduledFundedTemp FSRDT
JOIN #ReceivableDetailsTemp ReceivableDetail ON FSRDT.ContractId = ReceivableDetail.ContractId AND FSRDT.DueDate = ReceivableDetail.DueDate;
;WITH CTE_CompletedDRAdjustment AS
(SELECT FSFT.ContractId
,SUM(ISNULL(FSFT.Amount,0)) AS Amount
FROM #FutureScheduledFundedTemp FSFT
WHERE FSFT.IsGLPosted = 0 AND FSFT.DRStatus IS NOT NULL AND FSFT.DRStatus = @CompletedStatus
GROUP BY FSFT.ContractId),
CTE_GLPostedInCompletedDRAdjustment AS
(SELECT FSFT.ContractId
,SUM((ISNULL(FSFT.Amount,0)) * (-1)) AS Amount
FROM #FutureScheduledFundedTemp FSFT
WHERE FSFT.IsGLPosted = 1 AND (FSFT.DRStatus IS NULL OR FSFT.DRStatus != @CompletedStatus)
GROUP BY FSFT.ContractId)
UPDATE #RNITemp SET PrincipalBalanceAdjustment_Amount = ISNULL(CompletedDRAdjustment.Amount,0) + ISNULL(InCompletedDRAdjustment.Amount,0)
FROM #RNITemp RNI
LEFT JOIN CTE_CompletedDRAdjustment CompletedDRAdjustment ON RNI.ContractId = CompletedDRAdjustment.ContractId
LEFT JOIN CTE_GLPostedInCompletedDRAdjustment InCompletedDRAdjustment ON RNI.ContractId = InCompletedDRAdjustment.ContractId;
END
/*Delayed Funding Payables*/
--Future Funding - Not Used
;WITH CTE_DelayedFundingPayables AS
(SELECT Contract.ContractId
,(SUM(InvoiceAsset.AcquisitionCost_Amount) + ISNULL(SUM(InvoiceOtherCost.Amount_Amount),0)) AS DelayedFundingAmount
FROM #LeaseDetails Contract
JOIN LeaseFundings Funding ON Contract.LeaseFinanceId = Funding.LeaseFinanceId AND Funding.Type <> @Origination AND Contract.BookingStatus = @CommencedStatus AND Funding.IsActive = 1
JOIN PayableInvoiceAssets InvoiceAsset ON Funding.FundingId = InvoiceAsset.PayableInvoiceId AND InvoiceAsset.IsActive = 1
LEFT JOIN PayableInvoiceOtherCosts InvoiceOtherCost ON Funding.FundingId = InvoiceOtherCost.PayableInvoiceId AND InvoiceOtherCost.IsActive = 1
AND InvoiceOtherCost.AllocationMethod IN(@SpecificCostAdjustment, @AssetCount, @AssetCost, @Specific)
LEFT JOIN DisbursementRequestInvoices DRInvoice ON Funding.FundingId = DRInvoice.InvoiceId AND DRInvoice.IsActive = 1
LEFT JOIN DisbursementRequests DR ON DRInvoice.DisbursementRequestId = DR.Id
WHERE (Funding.Type = @FutureScheduled OR  (Funding.Type = @FutureScheduledFunded AND DR.Status NOT IN(@CompletedStatus,@InactiveStatus)))
GROUP BY Contract.ContractId)
UPDATE #RNITemp SET DelayedFundingPayables_Amount = DelayedFundingPayable.DelayedFundingAmount
FROM #RNITemp RNI
JOIN CTE_DelayedFundingPayables DelayedFundingPayable ON RNI.ContractId = DelayedFundingPayable.ContractId;
/*Income Accrual Balance*//*Finance Income Accrual Balance*/
;WITH CTE_LeaseIncomeInfo AS
(SELECT IncomeSched.ContractId
,SUM(IncomeSched.Income_Amount) AS IncomeAmount
,SUM(IncomeSched.FinanceIncome_Amount) AS FinanceIncomeAmount
FROM #LeaseIncomeScheduleTemp IncomeSched
WHERE IncomeSched.IsAccounting = 1 AND IsLessorOwned = 1 AND IncomeSched.IsGLPosted = 0 AND IncomeSched.IsIncomeBeforeCommencement = 0
GROUP BY IncomeSched.ContractId)
UPDATE #RNITemp SET IncomeAccrualBalance_Amount = CASE WHEN Contract.LeaseContractType NOT IN (@OperatingContractSubType,@Financing) THEN LeaseIncome.IncomeAmount ELSE 0.00 END,
FinanceIncomeAccrualBalance_Amount = LeaseIncome.FinanceIncomeAmount
FROM #RNITemp RNI
JOIN #LeaseDetails Contract ON RNI.ContractId = Contract.ContractId
JOIN CTE_LeaseIncomeInfo LeaseIncome ON RNI.ContractId = LeaseIncome.ContractId;
IF EXISTS(SELECT 1 FROM #LoanDetails)
BEGIN
;WITH CTE_LoanInterestIncome AS
(SELECT Contract.ContractId
,SUM(IncomeSched.InterestAccrued_Amount) AS InterestAccruedAmount
FROM #LoanDetails Contract
JOIN #LoanIncomeScheduleTemp IncomeSched ON Contract.ContractId = IncomeSched.ContractId AND Contract.IsChargedOff = 0
AND IncomeSched.IsLessorOwned = 1 AND IncomeSched.IsAccounting=1 AND IncomeSched.IsGLPosted = 1
WHERE (Contract.IsProgressLoan = 1 OR IncomeSched.IncomeDate >= IncomeSched.CommencementDate)
GROUP BY Contract.ContractId)
UPDATE #RNITemp SET IncomeAccrualBalance_Amount = LoanInterestIncome.InterestAccruedAmount
FROM #RNITemp RNI
JOIN CTE_LoanInterestIncome LoanInterestIncome ON RNI.ContractId = LoanInterestIncome.ContractId;
UPDATE #RNITemp
SET IncomeAccrualBalance_Amount = IncomeAccrualBalance_Amount - CapitalizedInterest.CapitalizedInterestAmount
FROM #RNITemp RNI
JOIN (SELECT Contract.ContractId
,SUM(CapInterest.Amount_Amount) AS CapitalizedInterestAmount
FROM #LoanDetails Contract
JOIN LoanCapitalizedInterests CapInterest ON Contract.LoanFinanceId = CapInterest.LoanFinanceId AND Contract.IsChargedOff = 0
AND CapInterest.GLJournalId IS NOT NULL AND CapInterest.Source != @ProgressLoanInterestCapitalized
AND CapInterest.Source != @CapitalizedAdditionalFeeCharge
GROUP BY Contract.ContractId) AS CapitalizedInterest ON RNI.ContractId = CapitalizedInterest.ContractId;
UPDATE #RNITemp SET IncomeAccrualBalance_Amount = IncomeAccrualBalance_Amount - ReceivableIncomeAccrual.LoanInterestAmount
FROM #RNITemp RNI
JOIN (SELECT  ReceivableDetail.ContractId,
SUM(ReceivableDetail.Amount_Amount) AS LoanInterestAmount
FROM #LoanDetails Contract
JOIN #ReceivableDetailsTemp ReceivableDetail on Contract.ContractId = ReceivableDetail.ContractId AND Contract.IsChargedOff = 0
WHERE ReceivableDetail.ReceivableType = @LoanInterest AND ReceivableDetail.FunderId IS NULL AND ReceivableDetail.IsGLPosted=1
GROUP BY ReceivableDetail.ContractId)
AS ReceivableIncomeAccrual ON RNI.ContractId = ReceivableIncomeAccrual.ContractId;
UPDATE #RNITemp SET IncomeAccrualBalance_Amount = IncomeAccrualBalance_Amount - PaydownAdjutsment.PaydownAmount
FROM #RNITemp RNI
JOIN (SELECT PaydownTemp.ContractId,
SUM(CASE WHEN (PaydownTemp.PaydownReason = @FullPaydown AND PaydownTemp.IsDailySensitive = 0)
THEN (PaydownTemp.AccruedInterest_Amount - PaydownTemp.InterestPaydown_Amount)
WHEN PaydownReason = @Casualty THEN PaydownTemp.InterestPaydown_Amount ELSE 0 END) AS PaydownAmount
FROM #LoanDetails Contract
JOIN #LoanPaydownTemp PaydownTemp on Contract.ContractId = PaydownTemp.ContractId AND Contract.IsChargedOff = 0
WHERE PaydownTemp.PaydownReason IN(@FullPaydown,@Casualty)
GROUP BY PaydownTemp.ContractId)
AS PaydownAdjutsment ON RNI.ContractId = PaydownAdjutsment.ContractId;
END
/*Income Accrual Balance Funder Portion*//*Syndicated Finance Income Accrual Balance*/
;WITH CTE_LeaseIncomeInfo AS
(SELECT Contract.ContractId
,SUM(IncomeSched.Income_Amount) AS IncomeAmount
,SUM(IncomeSched.FinanceIncome_Amount) AS FinanceIncomeAmount
FROM #LeaseDetails Contract
JOIN #SyndicationDetailsTemp SyndicationDetail ON Contract.ContractId = SyndicationDetail.ContractId AND SyndicationDetail.IsServiced = 1
JOIN #LeaseIncomeScheduleTemp IncomeSched ON SyndicationDetail.ContractId = IncomeSched.ContractId AND IncomeSched.IsSchedule = 1 AND IncomeSched.IsLessorOwned = 0 AND IncomeSched.IsIncomeBeforeCommencement = 0
JOIN #BasicDetails ContractDateInfo ON Contract.ContractId = ContractDateInfo.ContractId
WHERE ((Contract.SyndicationType = @SaleOfPaymentsType AND IncomeSched.IncomeDate >= ContractDateInfo.MaxIncomeDatePriorToSyndication )
OR (Contract.SyndicationType <> @SaleOfPaymentsType AND IncomeSched.IncomeDate >= Contract.CommencementDate AND IncomeSched.IncomeDate > @IncomeDate))
GROUP BY Contract.ContractId)
UPDATE #RNITemp
SET IncomeAccrualBalanceFunderPortion_Amount =CASE WHEN Contract.LeaseContractType NOT IN (@OperatingContractSubType,@Financing) THEN LeaseIncome.IncomeAmount ELSE 0.00 END,
SyndicatedFinanceIncomeAccrualBalance_Amount = ISNULL(LeaseIncome.FinanceIncomeAmount ,0)
FROM #RNITemp RNI
JOIN #LeaseDetails Contract ON RNI.ContractId = Contract.ContractId
JOIN CTE_LeaseIncomeInfo LeaseIncome ON RNI.ContractId = LeaseIncome.ContractId;
IF EXISTS(SELECT 1 FROM #LoanDetails)
BEGIN
;WITH CTE_LoanInterestIncome AS
(SELECT Contract.ContractId
,SUM(IncomeSched.InterestAccrued_Amount) AS LoanInterestAccruedAmount
FROM #LoanDetails Contract
JOIN #SyndicationDetailsTemp SyndicationDetail ON Contract.ContractId = SyndicationDetail.ContractId AND SyndicationDetail.IsServiced = 1 AND SyndicationDetail.ReceivableForTransferType IN(@FullSale,@ParticipatedSale)
JOIN #LoanIncomeScheduleTemp IncomeSched ON SyndicationDetail.ContractId = IncomeSched.ContractId AND IncomeSched.IncomeDate <= @IncomeDate AND IncomeSched.IsSchedule = 1 AND IncomeSched.IsLessorOwned = 0
WHERE (Contract.IsProgressLoan = 1 OR IncomeSched.IncomeDate >= IncomeSched.CommencementDate)
AND (SyndicationDetail.IsCollected = 0 OR IncomeSched.IncomeDate >=SyndicationDetail.SyndicationEffectiveDate)
GROUP BY Contract.ContractId)
UPDATE #RNITemp SET IncomeAccrualBalanceFunderPortion_Amount = LoanInterestIncome.LoanInterestAccruedAmount
FROM #RNITemp RNI
JOIN CTE_LoanInterestIncome LoanInterestIncome ON RNI.ContractId = LoanInterestIncome.ContractId;
END
UPDATE #RNITemp SET IncomeAccrualBalanceFunderPortion_Amount = IncomeAccrualBalanceFunderPortion_Amount * (1 - (SyndicationDetail.RetainedPercentage / 100)),
SyndicatedFinanceIncomeAccrualBalance_Amount = SyndicatedFinanceIncomeAccrualBalance_Amount * (1 - (SyndicationDetail.RetainedPercentage / 100))
FROM #RNITemp RNI
JOIN #SyndicationDetailsTemp SyndicationDetail ON RNI.ContractId = SyndicationDetail.ContractId;
IF EXISTS(SELECT 1 FROM #LoanDetails)
BEGIN
;WITH CTE_LoanInterestReceivable AS
(SELECT  Contract.ContractId,
SUM(Receivable.Amount_Amount) AS LoanInterestAmount
FROM #LoanDetails Contract
JOIN #SyndicationDetailsTemp SyndicationDetail ON Contract.ContractId = SyndicationDetail.ContractId AND SyndicationDetail.IsServiced = 1 AND SyndicationDetail.ReceivableForTransferType != @SaleOfPaymentsType
JOIN #ReceivableDetailsTemp Receivable ON Contract.ContractId = Receivable.ContractId AND Receivable.ReceivableType = @LoanInterest AND Receivable.FunderId IS NOT NULL
WHERE ((SyndicationDetail.IsCollected = 1 AND IsDummy = 0) OR (SyndicationDetail.IsCollected = 0 AND Receivable.DueDate <= @IncomeDate AND
((Contract.IsDSL = 1 AND Receivable.IsDummy = 1) OR Contract.IsDSL = 0)))
GROUP BY  Contract.ContractId)
UPDATE #RNITemp SET IncomeAccrualBalanceFunderPortion_Amount = IncomeAccrualBalanceFunderPortion_Amount - LoanInterestReceivable.LoanInterestAmount
FROM #RNITemp RNI
JOIN CTE_LoanInterestReceivable LoanInterestReceivable ON RNI.ContractId = LoanInterestReceivable.ContractId
END
;WITH CTE_AssetIncome AS
(SELECT Contract.ContractId,
SUM(IncomeSched.Income_Amount) AS AssetIncomeAmount,
SUM(IncomeSched.FinanceIncome_Amount) AS AssetFinanceIncome
FROM  #LeaseDetails Contract
JOIN #SyndicationDetailsTemp SyndicationDetail ON Contract.ContractId = SyndicationDetail.ContractId AND SyndicationDetail.IsServiced = 1 AND SyndicationDetail.ReceivableForTransferType = @SaleOfPaymentsType
JOIN #LeaseIncomeScheduleTemp IncomeSched ON Contract.ContractId = IncomeSched.ContractId AND IncomeSched.IncomeDate >= SyndicationDetail.SyndicationEffectiveDate
AND IncomeSched.IsAccounting = 1 AND IncomeSched.IsGLPosted = 0 AND IncomeSched.IsIncomeBeforeCommencement = 0
GROUP BY Contract.ContractId)
UPDATE #RNITemp SET IncomeAccrualBalanceFunderPortion_Amount = IncomeAccrualBalanceFunderPortion_Amount - AssetIncome.AssetIncomeAmount ,
SyndicatedFinanceIncomeAccrualBalance_Amount = SyndicatedFinanceIncomeAccrualBalance_Amount - AssetIncome.AssetFinanceIncome
FROM #RNITemp RNI
JOIN CTE_AssetIncome AssetIncome ON RNI.ContractId = AssetIncome.ContractId;
/*Loan Principal OSAR*/ -- CE
IF EXISTS (SELECT 1 FROM #LoanDetails)
BEGIN
;WITH CTE_DSLLoanPrincipalReceivable AS
(SELECT Contract.ContractId,
SUM(CASE WHEN Contract.IsNonAccrual = 0 THEN ReceivableDetail.Balance_Amount ELSE ReceivableDetail.EffectiveBookBalance_Amount END) AS DSLLoanPrincipalAmount
FROM (SELECT ContractId,IsNonAccrual FROM #LoanDetails WHERE IsDSL = 1 AND IsChargedOff = 0) Contract
JOIN #ReceivableDetailsTemp ReceivableDetail ON Contract.ContractId = ReceivableDetail.ContractId AND ReceivableDetail.ReceivableType = @LoanPrincipal
AND ReceivableDetail.FunderId IS NULL AND ReceivableDetail.IsGLPosted=1
GROUP BY Contract.ContractId)
UPDATE #RNITemp SET LoanPrincipleOSAR_Amount = LoanPrincipleOSAR_Amount + LoanPrincipalReceivable.DSLLoanPrincipalAmount
FROM #RNITemp RNI
JOIN CTE_DSLLoanPrincipalReceivable LoanPrincipalReceivable ON RNI.ContractId = LoanPrincipalReceivable.ContractId;
;WITH CTE_NonDSLLoanPrincipalReceivable AS
(SELECT Contract.ContractId,
SUM(ReceivableDetail.Balance_Amount) AS NonDSLLoanPrincipalAmount
FROM (SELECT ContractId,IsNonAccrual FROM #LoanDetails WHERE IsDSL = 0 AND IsNonAccrual = 0 AND IsChargedOff = 0) Contract
JOIN #ReceivableDetailsTemp ReceivableDetail ON Contract.ContractId = ReceivableDetail.ContractId AND ReceivableDetail.ReceivableType = @LoanPrincipal
AND ReceivableDetail.FunderId IS NULL AND ReceivableDetail.IsGLPosted=1
GROUP BY Contract.ContractId)
UPDATE #RNITemp SET LoanPrincipleOSAR_Amount = LoanPrincipleOSAR_Amount + NDSLLoanPrincipalReceivable.NonDSLLoanPrincipalAmount
FROM #RNITemp RNI
JOIN CTE_NonDSLLoanPrincipalReceivable NDSLLoanPrincipalReceivable ON RNI.ContractId = NDSLLoanPrincipalReceivable.ContractId;
;WITH CTE_NonAccrualBalance AS
(SELECT Contract.ContractId,
SUM(CASE WHEN PaymentStartDate >= ContractDateInfo.MaxNonAccrualDate AND ReceivableDetail.IsGLPosted = 0 THEN ReceivableDetail.Balance_Amount ELSE 0.00 END) AS BalanceAfterNonAccrual,
SUM(CASE WHEN PaymentStartDate < ContractDateInfo.MaxNonAccrualDate AND ReceivableDetail.IsGLPosted = 1 THEN ReceivableDetail.Balance_Amount ELSE 0.00 END) AS BalanceBeforeNonAccrual,
SUM(CASE WHEN PaymentStartDate >= ContractDateInfo.MaxNonAccrualDate THEN ReceivableDetail.EffectiveBookBalance_Amount ELSE 0.00 END) AS BookBalanceAfterNonAccrual
FROM (SELECT ContractId,IsNonAccrual FROM #LoanDetails WHERE IsDSL = 0 AND IsNonAccrual = 1 AND IsChargedOff = 0) AS Contract
JOIN #ReceivableDetailsTemp ReceivableDetail ON Contract.ContractId = ReceivableDetail.ContractId
AND ReceivableDetail.ReceivableType = @LoanPrincipal AND ReceivableDetail.FunderId IS NULL
JOIN #BasicDetails ContractDateInfo ON Contract.ContractId = ContractDateInfo.ContractId
GROUP BY Contract.ContractId)
UPDATE #RNITemp
SET LoanPrincipleOSAR_Amount = LoanPrincipleOSAR_Amount - NonAccrualBalance.BalanceAfterNonAccrual + NonAccrualBalance.BalanceBeforeNonAccrual + NonAccrualBalance.BookBalanceAfterNonAccrual
FROM #RNITemp RNI
JOIN CTE_NonAccrualBalance AS NonAccrualBalance ON RNI.ContractId = NonAccrualBalance.ContractId;
END
/*Syndicated Loan Principal OSAR*//*Syndicated Loan Interest OSAR*/ -- CE
IF EXISTS(SELECT 1 FROM #LoanDetails WHERE SyndicationType IN(@FullSale,@ParticipatedSale))
BEGIN
;WITH CTE_SyndicatedLoanInterestOSAR AS
(SELECT  ReceivableDetail.ContractId,
SUM(ReceivableDetail.Balance_Amount) AS Amount
FROM (SELECT ContractId,IsCollected FROM #SyndicationDetailsTemp WHERE ReceivableForTransferType IN(@FullSale,@ParticipatedSale) AND IsServiced = 1) AS SyndicationDetail
JOIN #BasicDetails Contract ON Contract.ContractId = SyndicationDetail.ContractId AND Contract.IsChargedOff = 0
JOIN #ReceivableDetailsTemp ReceivableDetail ON SyndicationDetail.ContractId = ReceivableDetail.ContractId AND ReceivableDetail.ReceivableType IN(@LoanInterest,@LoanPrincipal) AND ReceivableDetail.FunderId IS NOT NULL
AND ReceivableDetail.PaymentType IN(@LoanDownPayment,@FixedTerm)
WHERE ((SyndicationDetail.IsCollected = 1 AND ReceivableDetail.IsGLPosted=1) OR (SyndicationDetail.IsCollected = 0 AND ReceivableDetail.DueDate <= @IncomeDate))
GROUP BY  ReceivableDetail.ContractId)
UPDATE #RNITemp SET SyndicatedFixedTermReceivablesOSAR_Amount = SyndicatedFixedTermReceivablesOSAR_Amount + OSAR.Amount
FROM #RNITemp RNI
JOIN CTE_SyndicatedLoanInterestOSAR OSAR ON RNI.ContractId = OSAR.ContractId;
END
IF EXISTS (SELECT 1 FROM #LoanDetails)
BEGIN
/*Loan Interest OSAR*/ -- CE
;WITH CTE_AccrualLoanInterestReceivable AS
(SELECT  Contract.ContractId,
SUM(ISNULL(ReceivableDetail.Balance_Amount,0)) AS LoanInterestAmount
FROM (SELECT ContractId FROM #LoanDetails WHERE IsNonAccrual = 0 AND IsChargedOff = 0) AS Contract
JOIN #ReceivableDetailsTemp ReceivableDetail ON Contract.ContractId = ReceivableDetail.ContractId AND ReceivableDetail.ReceivableType = @LoanInterest
AND ReceivableDetail.PaymentType = @FixedTerm
AND ReceivableDetail.FunderId IS NULL AND ReceivableDetail.IsGLPosted=1
GROUP BY Contract.ContractId)
UPDATE #RNITemp SET LoanInterestOSAR_Amount = LoanInterestOSAR_Amount + LoanInterestReceivable.LoanInterestAmount
FROM #RNITemp RNI
JOIN CTE_AccrualLoanInterestReceivable LoanInterestReceivable ON RNI.ContractId = LoanInterestReceivable.ContractId
;WITH CTE_LoanInterestInfo AS
(SELECT Contract.ContractId,
SUM(CASE WHEN ReceivableDetail.PaymentStartDate >= ContractDateInfo.MaxNonAccrualDate THEN ReceivableDetail.EffectiveBookBalance_Amount ELSE 0.00 END) AS BookBalanceAfterNonAccrual,
SUM(CASE WHEN ReceivableDetail.PaymentStartDate < ContractDateInfo.MaxNonAccrualDate THEN ReceivableDetail.Balance_Amount ELSE 0.00 END) AS BalanceBeforeNonAccrual
FROM (SELECT ContractId FROM #LoanDetails WHERE IsNonAccrual = 1 AND IsChargedOff = 0) AS Contract
JOIN #BasicDetails ContractDateInfo ON Contract.ContractId = ContractDateInfo.ContractId
JOIN #ReceivableDetailsTemp ReceivableDetail ON ContractDateInfo.ContractId = ReceivableDetail.ContractId AND ReceivableDetail.ReceivableType = @LoanInterest
AND ReceivableDetail.IsGLPosted = 1 AND ReceivableDetail.PaymentType = @FixedTerm AND ReceivableDetail.FunderId IS NULL
GROUP BY Contract.ContractId)
UPDATE #RNITemp SET LoanInterestOSAR_Amount = LoanInterestOSAR_Amount + LoanInterestInfo.BookBalanceAfterNonAccrual + LoanInterestInfo.BalanceBeforeNonAccrual
FROM #RNITemp RNI
JOIN CTE_LoanInterestInfo LoanInterestInfo ON RNI.ContractId = LoanInterestInfo.ContractId;
/*Interim Interest OSAR*/
;WITH CTE_LoanInterimInterestOSAR AS
(SELECT ReceivableDetail.ContractId,
SUM(ReceivableDetail.Balance_Amount) AS InterimInterestOSARAmount
FROM #LoanDetails Contract
JOIN #ReceivableDetailsTemp ReceivableDetail ON Contract.ContractId = ReceivableDetail.ContractId AND ReceivableDetail.ReceivableType = @LoanInterest AND ReceivableDetail.FunderId IS NULL AND ReceivableDetail.IsGLPosted = 1
WHERE (Contract.IsProgressLoan = 1 OR ReceivableDetail.IncomeType = @LoanInterimInterest)
GROUP BY ReceivableDetail.ContractId)
UPDATE #RNITemp SET InterimInterestOSAR_Amount = OSAR.InterimInterestOSARAmount
FROM #RNITemp RNI
JOIN CTE_LoanInterimInterestOSAR OSAR ON RNI.ContractId = OSAR.ContractId;
END
/*Interim Interest OSAR - Lease*/
;WITH CTE_LeaseInterimInterestOSAR AS
(SELECT ReceivableDetail.ContractId,
SUM(ReceivableDetail.Balance_Amount) AS InterimInterestOSARAmount
FROM #ReceivableDetailsTemp ReceivableDetail
WHERE ReceivableDetail.ReceivableType = @LeaseInterimInterest AND ReceivableDetail.FunderId IS NULL AND ReceivableDetail.IsGLPosted = 1
GROUP BY ReceivableDetail.ContractId)
UPDATE #RNITemp SET InterimInterestOSAR_Amount = OSAR.InterimInterestOSARAmount
FROM #RNITemp RNI
JOIN CTE_LeaseInterimInterestOSAR OSAR ON RNI.ContractId = OSAR.ContractId;
/*Suspended Income Accrual Balance*//*Suspended Finance Income Accrual Balance*/
;WITH CTE_SuspendedLeaseIncomeInfo AS
(SELECT IncomeSched.ContractId
,SUM(CASE WHEN Contract.IsOperating = 1
THEN IncomeSched.RentalIncome_Amount
ELSE IncomeSched.Income_Amount END) AS SuspendedIncomeAmount
,SUM(IncomeSched.FinanceIncome_Amount) AS SuspendedFinanceIncomeAmount
FROM (SELECT ContractId,
CASE WHEN LeaseContractType = @OperatingContractSubType THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsOperating
FROM #LeaseDetails WHERE IsChargedOff = 0) AS Contract
JOIN #LeaseIncomeScheduleTemp IncomeSched ON Contract.ContractId = IncomeSched.ContractId AND IncomeSched.IsNonAccrual=1
AND IncomeSched.IsAccounting = 1 AND IsLessorOwned = 1 AND IncomeSched.IsGLPosted = 1 AND IncomeSched.IsIncomeBeforeCommencement = 0
GROUP BY IncomeSched.ContractId)
UPDATE #RNITemp SET SuspendedIncomeAccrualBalance_Amount = SuspendedLeaseIncomeInfo.SuspendedIncomeAmount,
SuspendedFinanceIncomeAccrualBalance_Amount = SuspendedLeaseIncomeInfo.SuspendedFinanceIncomeAmount
FROM #RNITemp RNI
JOIN CTE_SuspendedLeaseIncomeInfo SuspendedLeaseIncomeInfo ON RNI.ContractId = SuspendedLeaseIncomeInfo.ContractId;
--Suspended Income for Doubtful Collectability
--select * from #SuspendedIncomeInfoForDoubtfulCollectability
INSERT INTO #SuspendedIncomeInfoForDoubtfulCollectability
SELECT
Id,
IsNonAccrual,
NonAccrualDate
FROM Contracts
WHERE Id BETWEEN @ContractMin AND @ContractMax-- Ramesh 
AND IsNonAccrual=1
AND DoubtfulCollectability=1

;WITH CTE_FullySyndicatedDeferredRentalInfo AS
(
SELECT SI.ContractId,
LIS.DeferredRentalIncome_Amount
FROM #SuspendedIncomeInfoForDoubtfulCollectability SI
JOIN ReceivableForTransfers RFT ON SI.ContractId = RFT.ContractId
JOIN LeaseFinances LF ON RFT.ContractId = LF.ContractId
JOIN LeaseIncomeSchedules LIS ON LF.Id = LIS.LeaseFinanceId
WHERE RFT.ReceivableForTransferType = 'FullSale'
AND RFT.ApprovalStatus = 'Approved'
AND LIS.IncomeDate = DATEADD(DAY,-1,RFT.EffectiveDate)
AND LIS.IsSchedule=1 AND LIS.IsLessorOwned=1
GROUP BY SI.ContractId,LIS.DeferredRentalIncome_Amount
)
UPDATE #RNITemp SET SuspendedIncomeAccrualBalance_Amount = SuspendedIncomeAccrualBalance_Amount + FullySyndicatedDeferredRentalInfo.DeferredRentalIncome_Amount
FROM #RNITemp RNI
JOIN CTE_FullySyndicatedDeferredRentalInfo FullySyndicatedDeferredRentalInfo ON RNI.ContractId = FullySyndicatedDeferredRentalInfo.ContractId;

	IF EXISTS (SELECT 1 FROM #LoanDetails)
	BEGIN
	;WITH CTE_SuspendedLoanIncome AS
	(SELECT Contract.ContractId
	,SUM(IncomeSched.InterestAccrued_Amount) AS LoanInterestAccruedAmount
	FROM #LoanDetails Contract
	JOIN #LoanIncomeScheduleTemp IncomeSched ON Contract.IsChargedOff = 0 AND Contract.ContractId = IncomeSched.ContractId AND IncomeSched.IsNonAccrual = 1
	AND IncomeSched.IsLessorOwned = 1 AND IncomeSched.IsGLPosted = 1 AND IncomeSched.IsAccounting=1
	GROUP BY Contract.ContractId)
	UPDATE #RNITemp SET SuspendedIncomeAccrualBalance_Amount = SuspendedLoanIncome.LoanInterestAccruedAmount
	FROM #RNITemp RNI
	JOIN CTE_SuspendedLoanIncome SuspendedLoanIncome ON RNI.ContractId = SuspendedLoanIncome.ContractId;
	END
	/*Deferred Selling Profit Income*/
	;WITH CTE_DeferredSellingProfitIncome AS
	(SELECT Contract.ContractId
	,SUM(IncomeSched.DeferredSellingProfitIncome_Amount) AS DeferredSellingProfitIncomeAmount
	FROM #LeaseDetails Contract
	JOIN #LeaseIncomeScheduleTemp IncomeSched ON Contract.LeaseContractType = @DirectFinanceContractSubType AND Contract.ContractId = IncomeSched.ContractId
	AND IncomeSched.IsGLPosted = 0 AND IncomeSched.IsLessorOwned = 1 AND IncomeSched.IsAccounting = 1 AND IncomeSched.IsIncomeBeforeCommencement = 0
	GROUP BY Contract.ContractId)
	UPDATE #RNITemp
	SET DeferredSellingProfit_Amount = DeferredSellingProfit_Amount + DSPIncome.DeferredSellingProfitIncomeAmount
	FROM #RNITemp RNI
	JOIN CTE_DeferredSellingProfitIncome DSPIncome ON RNI.ContractId = DSPIncome.ContractId;
	/*Suspended Deferred Selling Profit Income*/
	;WITH CTE_SuspendedDeferredSellingProfitIncome AS
	(SELECT Contract.ContractId
	,SUM(IncomeSched.DeferredSellingProfitIncome_Amount) AS SuspendedDeferredSellingProfitIncomeAmount
	FROM (SELECT ContractId FROM #LeaseDetails WHERE IsChargedOff = 0 AND LeaseContractType = @DirectFinanceContractSubType) Contract
	JOIN #LeaseIncomeScheduleTemp IncomeSched ON Contract.ContractId = IncomeSched.ContractId AND IncomeSched.IsNonAccrual = 1
	AND IncomeSched.IsGLPosted = 1 AND IncomeSched.IsAccounting=1 AND IncomeSched.IsLessorOwned = 1 AND IncomeSched.IsIncomeBeforeCommencement = 0
	GROUP BY Contract.ContractId)
	UPDATE #RNITemp
	SET SuspendedDeferredSellingProfit_Amount = SuspendedDeferredSellingProfit_Amount + SuspendedDSPIncome.SuspendedDeferredSellingProfitIncomeAmount
	FROM #RNITemp RNI
	JOIN CTE_SuspendedDeferredSellingProfitIncome SuspendedDSPIncome ON RNI.ContractId = SuspendedDSPIncome.ContractId;

	/*Total Financed Amount LOC*/ -- CE

	SELECT  LeaseAsset.ContractId,LeaseAsset.AssetId,
	LeaseAsset.CapitalizationType,SUM(LeaseAsset.Amount)'Amount',LeaseAsset.CapitalizedForId,LeaseAsset.LeaseAssetId 
	INTO #DistinctAssetInfo
	 FROM #AssetTemp AS LeaseAsset
	 GROUP BY LeaseAsset.ContractId,LeaseAsset.AssetId,
	LeaseAsset.CapitalizationType,LeaseAsset.CapitalizedForId,LeaseAsset.LeaseAssetId


	;With CTE_NBVInfo AS
	(SELECT SUM(LeaseAsset.Amount) AS NBVLOCAmount
	, LeaseAsset.ContractId
	FROM #DistinctAssetInfo LeaseAsset
	JOIN PayableInvoiceAssets InvoiceAsset ON LeaseAsset.AssetId = InvoiceAsset.AssetId AND InvoiceAsset.IsActive = 1
	JOIN Payables Payable ON InvoiceAsset.Id = Payable.SourceId AND Payable.SourceTable = @PayableInvoiceAssetSourceTable AND Payable.Status != @InactiveStatus
	JOIN DisbursementRequestPayables DRPayable ON Payable.Id = DRPayable.PayableId AND DRPayable.IsActive = 1
	JOIN DisbursementRequests DR ON DRPayable.DisbursementRequestId = DR.Id AND DR.Status !=@InactiveStatus
	LEFT JOIN #SyndicationDetailsTemp SyndicationDetail ON LeaseAsset.ContractId = SyndicationDetail.ContractId AND SyndicationDetail.SyndicationAtInception = 1
	WHERE SyndicationDetail.ContractId IS NULL
	GROUP BY LeaseAsset.ContractId)
	UPDATE #RNITemp
	SET TotalFinancedAmountLOC_Amount = NBV.NBVLOCAmount
	FROM #RNITemp RNI
	JOIN CTE_NBVInfo NBV ON RNI.ContractId = NBV.ContractId
	;
	;WITH CTE_CapitalizedSalesNBVInfo AS
	(SELECT SUM(CapitalizedLeaseAsset.Amount) AS CapitalizedSalesNBVForLOCAmount
	, CapitalizedLeaseAsset.ContractId
	FROM #DistinctAssetInfo CapitalizedLeaseAsset
	JOIN #DistinctAssetInfo LeaseAsset ON CapitalizedLeaseAsset.CapitalizedForId = LeaseAsset.LeaseAssetId AND CapitalizedLeaseAsset.CapitalizationType = @CapitalizedSalesTax
	JOIN PayableInvoiceAssets InvoiceAsset ON LeaseAsset.AssetId = InvoiceAsset.AssetId AND InvoiceAsset.IsActive = 1
	JOIN Payables Payable ON InvoiceAsset.Id = Payable.SourceId AND Payable.SourceTable = @PayableInvoiceAssetSourceTable AND Payable.Status != @InactiveStatus
	JOIN DisbursementRequestPayables DRPayable ON Payable.Id = DRPayable.PayableId AND DRPayable.IsActive = 1
	JOIN DisbursementRequests DR ON DRPayable.DisbursementRequestId = DR.Id AND DR.Status !=@InactiveStatus
	LEFT JOIN #SyndicationDetailsTemp SyndicationDetail ON CapitalizedLeaseAsset.ContractId = SyndicationDetail.ContractId AND SyndicationDetail.SyndicationAtInception = 1
	WHERE SyndicationDetail.ContractId IS NULL
	GROUP BY CapitalizedLeaseAsset.ContractId)
	UPDATE #RNITemp
	SET TotalFinancedAmountLOC_Amount = TotalFinancedAmountLOC_Amount + CapitalizedNBV.CapitalizedSalesNBVForLOCAmount
	FROM #RNITemp RNI
	JOIN CTE_CapitalizedSalesNBVInfo CapitalizedNBV ON RNI.ContractId = CapitalizedNBV.ContractId;
	UPDATE #RNITemp
	SET TotalFinancedAmountLOC_Amount = Asset.Amount
	FROM #RNITemp RNI
	JOIN (SELECT SUM(LeaseAsset.Amount) AS Amount
	, Contract.ContractId
	FROM #LeaseDetails Contract
	JOIN #SyndicationDetailsTemp SyndicationDetail ON Contract.ContractId = SyndicationDetail.ContractId AND SyndicationDetail.SyndicationAtInception = 1
	JOIN #DistinctAssetInfo LeaseAsset ON SyndicationDetail.ContractId = LeaseAsset.ContractId
	WHERE Contract.BookingStatus IN(@CommencedStatus,@FullyPaidOff)
	GROUP BY Contract.ContractId)
	AS Asset ON RNI.ContractId = Asset.ContractId;
	IF EXISTS(SELECT 1 FROM #LoanDetails)
	BEGIN
	;WITH CTE_DisbursementRequestInfo AS
	(SELECT SUM(CASE WHEN LoanTemp.IsForeignCurrency = 0 THEN (LoanTemp.Amount) ELSE (LoanTemp.Amount * LoanTemp.InitialExchangeRate) END) AS DisbursementRequestAmount,
	LoanTemp.ContractId
	FROM #LoanFinanceBasicTemp LoanTemp
	JOIN DisbursementRequestInvoices DRInvoice ON LoanTemp.PayableInvoiceId = DRInvoice.InvoiceId AND DRInvoice.IsActive = 1
	JOIN DisbursementRequests DR ON DRInvoice.DisbursementRequestId = DR.Id AND DR.Status !=@InactiveStatus
	LEFT JOIN #SyndicationDetailsTemp SyndicationDetail ON LoanTemp.ContractId = SyndicationDetail.ContractId AND SyndicationDetail.SyndicationAtInception = 1
	WHERE SyndicationDetail.ContractId IS NULL
	GROUP BY LoanTemp.ContractId)
	UPDATE #RNITemp
	SET TotalFinancedAmountLOC_Amount = DRInfo.DisbursementRequestAmount
	FROM #RNITemp RNI
	JOIN CTE_DisbursementRequestInfo DRInfo ON RNI.ContractId = DRInfo.ContractId;
	;WITH CTE_SyndicationAtInceptionInfo AS
	(SELECT SUM(CASE WHEN LoanTemp.IsForeignCurrency = 0 THEN (LoanTemp.Amount) ELSE (LoanTemp.Amount * LoanTemp.InitialExchangeRate) END) AS SyndicationAtInceptionAmount,
	Contract.ContractId
	FROM #LoanDetails Contract
	JOIN #SyndicationDetailsTemp SyndicationDetail ON Contract.ContractId = SyndicationDetail.ContractId AND SyndicationDetail.SyndicationAtInception = 1
	JOIN #LoanFinanceBasicTemp LoanTemp ON SyndicationDetail.ContractId = LoanTemp.ContractId
	WHERE Contract.Status IN(@CommencedStatus,@FullyPaidOff)
	GROUP BY Contract.ContractId)
	UPDATE #RNITemp SET TotalFinancedAmountLOC_Amount = TotalFinancedAmountLOC_Amount + ISNULL(SyndicationInfo.SyndicationAtInceptionAmount,0)
	FROM #RNITemp RNI
	JOIN CTE_SyndicationAtInceptionInfo SyndicationInfo ON RNI.ContractId = SyndicationInfo.ContractId;
	END
	/*Unapplied Cash*/ -- CE
	;WITH CTE_UnappliedCashInfo AS
	(SELECT Receipt.ContractId
	,SUM(Receipt.Balance_Amount) AS UnappliedCash
	FROM #BasicDetails Contract
	JOIN Receipts Receipt ON Contract.ContractId = Receipt.ContractId AND Receipt.Status = @PostedStatus
	JOIN ReceiptAllocations Allocation ON Allocation.ReceiptId = Receipt.Id AND Allocation.IsActive = 1
	GROUP BY Receipt.ContractId),
	CTE_PayableBalanceInfo AS
	(SELECT Contract.ContractId,
	SUM(Payable.Balance_Amount) AS PayableBalance
	FROM #BasicDetails Contract
	JOIN Receipts Receipt ON Contract.ContractId = Receipt.ContractId AND Receipt.Status = @PostedStatus
	JOIN Payables Payable ON Receipt.Id = Payable.SourceId AND Payable.SourceTable = @ReceiptSourcaeTable AND Payable.EntityType = @ReceiptRefundEntityType
	JOIN UnallocatedRefunds Refund ON Payable.EntityId = Refund.Id AND Refund.Status != @ReversedStatus
	WHERE Payable.Status != @InactiveStatus
	GROUP BY Contract.ContractId)
	UPDATE #RNITemp
	SET UnappliedCash_Amount = UnappliedCashInfo.UnappliedCash + ISNULL(PayableBalanceInfo.PayableBalance,0.00)
	FROM #RNITemp RNI
	JOIN CTE_UnappliedCashInfo UnappliedCashInfo ON RNI.ContractId = UnappliedCashInfo.ContractId
	LEFT JOIN CTE_PayableBalanceInfo PayableBalanceInfo ON RNI.ContractId = PayableBalanceInfo.ContractId;
	/*Gross WriteDowns*/
	INSERT INTO #WriteDownDetailsTemp
	SELECT Contract.ContractId,
	CAST(1 AS BIT),
	WriteDown.IsRecovery,
	CASE WHEN LeaseAsset.IsLeaseAsset = 1 THEN WriteDownAsset.LeaseComponentWriteDownAmount_Amount 
	ELSE WriteDownAsset.NonLeaseComponentWriteDownAmount_Amount END 'WriteDownAmount_Amount',
	LeaseAsset.IsLeaseAsset
	FROM #LeaseDetails Contract
	JOIN WriteDowns WriteDown ON Contract.ContractId = WriteDown.ContractId AND WriteDown.IsActive = 1
	JOIN WriteDownAssetDetails WriteDownAsset ON WriteDown.Id = WriteDownAsset.WriteDownId AND WriteDownAsset.IsActive = 1
	JOIN #AssetTemp LeaseAsset ON Contract.ContractId = LeaseAsset.ContractId AND WriteDownAsset.AssetId = LeaseAsset.AssetId;
	INSERT INTO #WriteDownDetailsTemp
	SELECT Contract.ContractId,
	CAST(0 AS BIT),
	WriteDown.IsRecovery,
	WriteDownAsset.WriteDownAmount_Amount,
	0
	FROM #LoanDetails Contract
	JOIN WriteDowns WriteDown ON Contract.ContractId = WriteDown.ContractId AND WriteDown.IsActive = 1
	JOIN WriteDownAssetDetails WriteDownAsset ON WriteDown.Id = WriteDownAsset.WriteDownId AND WriteDownAsset.IsActive = 1;
	UPDATE #RNITemp SET GrossWritedowns_Amount = WriteDown.GrossWriteDownAmount
	FROM #RNITemp RNI
	JOIN (SELECT WriteDownTemp.ContractId,
	SUM(WriteDownTemp.WriteDownAmount) AS GrossWriteDownAmount
	FROM #WriteDownDetailsTemp WriteDownTemp
	WHERE WriteDownTemp.IsRecovery = 0 AND (WriteDownTemp.IsLease = 0 OR WriteDownTemp.IsLeaseAsset = 1)
	GROUP BY WriteDownTemp.ContractId)
	AS WriteDown ON RNI.ContractId = WriteDown.ContractId;
	/*Finance Gross WriteDowns*/
	UPDATE #RNITemp SET FinanceGrossWritedowns_Amount = WriteDown.FinanceGrossWriteDownAmount
	FROM #RNITemp RNI
	JOIN (SELECT WriteDownTemp.ContractId,
	SUM(WriteDownTemp.WriteDownAmount) AS FinanceGrossWriteDownAmount
	FROM #WriteDownDetailsTemp WriteDownTemp
	WHERE WriteDownTemp.IsRecovery = 0 AND WriteDownTemp.IsLease = 1 AND WriteDownTemp.IsLeaseAsset = 0
	GROUP BY WriteDownTemp.ContractId)
	AS WriteDown ON RNI.ContractId = WriteDown.ContractId;
	/*Net WriteDowns*/ -- CE
	UPDATE #RNITemp SET NetWritedowns_Amount = WriteDown.NetWriteDownAmount
	FROM #RNITemp RNI
	JOIN (SELECT WriteDownTemp.ContractId,
	SUM(WriteDownTemp.WriteDownAmount) AS NetWriteDownAmount
	FROM #WriteDownDetailsTemp WriteDownTemp
	WHERE (WriteDownTemp.IsLease = 0 OR WriteDownTemp.IsLeaseAsset = 1)
	GROUP BY WriteDownTemp.ContractId)
	AS WriteDown ON RNI.ContractId = WriteDown.ContractId;
	/*Finance Net WriteDowns*/
	UPDATE #RNITemp SET FinanceNetWritedowns_Amount = WriteDown.FinanceNetWriteDownAmount
	FROM #RNITemp RNI
	JOIN (SELECT WriteDownTemp.ContractId,
	SUM(WriteDownTemp.WriteDownAmount) AS FinanceNetWriteDownAmount
	FROM #WriteDownDetailsTemp WriteDownTemp
	WHERE WriteDownTemp.IsLease = 1 AND WriteDownTemp.IsLeaseAsset = 0
	GROUP BY WriteDownTemp.ContractId)
	AS WriteDown ON RNI.ContractId = WriteDown.ContractId;
	/*Blended Balance Calculation*/
	/*IDC Balance*//*FAS91 Expense Balance*//*FAS91 Income Balance*/
	;WITH CTE_BlendedItemBalanceInfo AS
	(SELECT Contract.ContractId
	, BlendedItemTemp.Type
	, SUM(ISNULL((CASE WHEN BlendedItemTemp.BookRecognitionMode = @AmortizeRecognitionMode
	THEN (BlendedItemTemp.BlendedItemAmount - BlendedItemTemp.IncomeAmount)
	ELSE BlendedItemTemp.IncomeAmount END),0)) AS Balance
	FROM #BasicDetails Contract
	JOIN #BlendedItemTemp BlendedItemTemp ON  Contract.IsChargedOff = 0 AND Contract.ContractId = BlendedItemTemp.ContractId
	AND BlendedItemTemp.IsFAS91 = 1
	AND BlendedItemTemp.IsReaccrualBlendedItem = 0
	GROUP BY Contract.ContractId,BlendedItemTemp.Type)
	UPDATE #RNITemp
	SET IDCBalance_Amount = ISNULL(BIIDCBalance.Balance,0.00),
	FAS91ExpenseBalance_Amount = ISNULL(BIFAS91ExpenseBalance.Balance,0.00),
	FAS91IncomeBalance_Amount = ISNULL(BIFAS91IncomeBalance.Balance,0.00)
	FROM #RNITemp RNI
	LEFT JOIN CTE_BlendedItemBalanceInfo BIIDCBalance ON RNI.ContractId = BIIDCBalance.ContractId AND BIIDCBalance.Type = @BlendedItemIDC
	LEFT JOIN CTE_BlendedItemBalanceInfo BIFAS91ExpenseBalance ON RNI.ContractId = BIFAS91ExpenseBalance.ContractId AND BIFAS91ExpenseBalance.Type = @BlendedItemExpense
	LEFT JOIN CTE_BlendedItemBalanceInfo BIFAS91IncomeBalance ON RNI.ContractId = BIFAS91IncomeBalance.ContractId AND BIFAS91IncomeBalance.Type = @BlendedItemIncome;
	UPDATE #RNITemp
	SET IDCBalance_Amount = CASE WHEN BlendedItemTemp.Type = @BlendedItemIDC AND BlendedItemTemp.IncomeAmount = 0 THEN 0 ELSE ISNULL(RNI.IDCBalance_Amount, 0) END,
	FAS91ExpenseBalance_Amount = CASE WHEN BlendedItemTemp.Type = @BlendedItemExpense AND BlendedItemTemp.IncomeAmount = 0 THEN 0 ELSE ISNULL(RNI.FAS91ExpenseBalance_Amount, 0) END,
	FAS91IncomeBalance_Amount = CASE WHEN BlendedItemTemp.Type = @BlendedItemIncome AND BlendedItemTemp.IncomeAmount = 0 THEN 0 ELSE ISNULL(RNI.FAS91IncomeBalance_Amount, 0) END
	FROM #RNITemp RNI
	JOIN #LoanDetails Contract ON RNI.ContractId = Contract.ContractId
	JOIN #LoanPaydownTemp PaydownTemp ON Contract.ContractId = PaydownTemp.ContractId AND Contract.CommencementDate = PaydownTemp.PaydownDate AND Contract.Status = @FullyPaidOff
	JOIN #BlendedItemTemp BlendedItemTemp ON Contract.ContractId = BlendedItemTemp.ContractId AND BlendedItemTemp.IsFAS91 = 1;
	/*Suspended Balance*/
	/*Suspended IDC Balance*//*Suspended FAS91 Expense Balance*//*Suspended FAS91 Income Balance*/
	;WITH CTE_SuspendedBlendedItemBalance AS
	(SELECT Contract.ContractId
	,BlendedItemTemp.Type
	,SUM(BlendedItemTemp.SuspendedIncomeAmount) AS SuspendedBalance
	FROM #BasicDetails Contract
	JOIN #BlendedItemTemp BlendedItemTemp ON Contract.ContractId = BlendedItemTemp.ContractId
	AND BlendedItemTemp.IsReaccrualBlendedItem=0
	AND BlendedItemTemp.IsFAS91 = 1
	GROUP BY Contract.ContractId,BlendedItemTemp.Type)
	UPDATE #RNITemp
	SET SuspendedIDCBalance_Amount = ISNULL(BISuspendedBal.SuspendedBalance,0),
	SuspendedFAS91ExpenseBalance_Amount = ISNULL(BISuspendedFAS91ExpenseBal.SuspendedBalance,0.00) ,
	SuspendedFAS91IncomeBalance_Amount = ISNULL(BISuspendedFAS91IncomeBal.SuspendedBalance,0.00)
	FROM #RNITemp RNI
	LEFT JOIN CTE_SuspendedBlendedItemBalance BISuspendedBal ON RNI.ContractId = BISuspendedBal.ContractId AND BISuspendedBal.Type = @BlendedItemIDC
	LEFT JOIN CTE_SuspendedBlendedItemBalance BISuspendedFAS91ExpenseBal ON RNI.ContractId = BISuspendedFAS91ExpenseBal.ContractId AND BISuspendedFAS91ExpenseBal.Type = @BlendedItemExpense
	LEFT JOIN CTE_SuspendedBlendedItemBalance BISuspendedFAS91IncomeBal ON RNI.ContractId = BISuspendedFAS91IncomeBal.ContractId AND BISuspendedFAS91IncomeBal.Type = @BlendedItemIncome;
	/*Blended Balance Calculation Ends*/
	/*Vendor Subsidy OSAR*/
	;WITH CTE_VendorSubsidyOSARInfo AS
	(SELECT  Contract.ContractId,
	SUM(Receivable.Balance_Amount) AS VendorSubsidyAmount,
	Receivable.IsGLPosted
	FROM #LeaseDetails Contract
	JOIN LeaseBlendedItems LeaseBI ON LeaseBI.LeaseFinanceId = Contract.LeaseFinanceId
	JOIN BlendedItems BlendedItem ON LeaseBI.BlendedItemId = BlendedItem.ID AND BlendedItem.IsVendorSubsidy = 1 AND BlendedItem.IsActive=1
	JOIN BlendedItemDetails BlendedItemDetail ON BlendedItem.Id = BlendedItemDetail.BlendedItemId AND BlendedItemDetail.IsActive=1
	JOIN Sundries Sundry ON BlendedItemDetail.SundryId = Sundry.Id AND Sundry.IsActive = 1
	JOIN #ReceivableDetailsTemp Receivable ON Sundry.ReceivableId = Receivable.ReceivableId AND Contract.ContractId = Receivable.ContractId
	GROUP BY Contract.ContractId,Receivable.IsGLPosted)
	UPDATE #RNITemp SET VendorSubsidyOSAR_Amount = ISNULL(VendorSubsidyOSAR.VendorSubsidyAmount,0.00),
	DelayedVendorSubsidy_Amount = ISNULL(DelayedVendorSubsidyOSAR.VendorSubsidyAmount,0.00)
	FROM #RNITemp RNI
	LEFT JOIN CTE_VendorSubsidyOSARInfo VendorSubsidyOSAR ON RNI.ContractId = VendorSubsidyOSAR.ContractId AND VendorSubsidyOSAR.IsGLPosted = 1
	LEFT JOIN CTE_VendorSubsidyOSARInfo DelayedVendorSubsidyOSAR ON RNI.ContractId = DelayedVendorSubsidyOSAR.ContractId AND DelayedVendorSubsidyOSAR.IsGLPosted = 0;
	/* Operating Lease Asset Gross Cost */
	;WITH CTE_OperatingLeaseAssetInfo AS(
	SELECT Contract.ContractId,
	SUM(LeaseAsset.Amount - LeaseAsset.ETCAdjustmentAmount_Amount) AS Amount
	FROM (SELECT ContractId FROM #LeaseDetails WHERE LeaseContractType = @OperatingContractSubType AND IsChargedOff = 0) Contract
	JOIN #AssetTemp LeaseAsset ON Contract.ContractId = LeaseAsset.ContractId AND LeaseAsset.IsActive = 1 AND LeaseAsset.IsLeaseAsset = 1
	GROUP BY Contract.ContractId)
	UPDATE #RNITemp
	SET OperatingLeaseAssetGrossCost_Amount = OperatingLeaseAsset.Amount
	FROM #RNITemp RNI
	JOIN CTE_OperatingLeaseAssetInfo OperatingLeaseAsset ON RNI.ContractId = OperatingLeaseAsset.ContractId;
	IF EXISTS(SELECT 1 FROM #LeaseDetails WHERE SyndicationType IN (@FullSale,@ParticipatedSale))
	BEGIN
	UPDATE #RNITemp
	SET OperatingLeaseAssetGrossCost_Amount = OperatingLeaseAssetGrossCost_Amount * (SyndicationDetail.RetainedPercentage/100)
	FROM #RNITemp RNI
	JOIN #SyndicationDetailsTemp SyndicationDetail ON RNI.ContractId = SyndicationDetail.ContractId AND SyndicationDetail.ReceivableForTransferType IN(@FullSale,@ParticipatedSale);
	END

	/*Accumulated Depreciation*/ -- CE
	;WITH CTE_AccumulateDep AS
	(SELECT Contract.ContractId
	, ABS(SUM(AVH.Value_Amount)) AS Amount
	FROM #LeaseDetails Contract
	JOIN (SELECT Asset.AssetId,Asset.ContractId FROM #AssetTemp Asset WHERE  Asset.IsActive = 1 GROUP BY Asset.AssetId,Asset.ContractId) AS Asset 
	ON Contract.SyndicationType <> @FullSale  AND Contract.ContractId = Asset.ContractId AND Contract.IsChargedOff = 0
	JOIN AssetValueHistories AVH With (ForceSeek) ON Asset.AssetId = AVH.AssetId AND AVH.SourceModule IN (@FixedTermBookDepSourceModule,@OTPDepreciation)
	AND AVH.IsAccounted = 1 AND AVH.IsCleared = 0 AND AVH.IsLessorOwned = 1 AND AVH.GLJournalId IS NOT NULL AND AVH.ReversalGLJournalId IS NULL
	LEFT JOIN #SyndicationDetailsTemp SyndicationDetail ON Contract.ContractId = SyndicationDetail.ContractId
	WHERE (Contract.SyndicationType IN(@None,@SaleOfPaymentsType) OR AVH.IncomeDate >= SyndicationDetail.SyndicationEffectiveDate )
	GROUP BY Contract.ContractId)
	UPDATE #RNITemp SET AccumulatedDepreciation_Amount = AccumulateDep.Amount
	FROM #RNITemp RNI
	JOIN CTE_AccumulateDep AccumulateDep ON RNI.ContractId = AccumulateDep.ContractId;

	/*SyndicatedAccumulatedDepreciation : Retained portion of value PRIOR to SyndicationEffectiveDate*/
	IF EXISTS(SELECT 1 FROM #LeaseDetails WHERE SyndicationType = @ParticipatedSale)
	BEGIN
	;WITH CTE_SyndicatedAccumulateDep AS
	(SELECT SyndicationDetail.ContractId
	, ABS(SUM(AVH.Value_Amount)) * (SyndicationDetail.RetainedPercentage/100) AS AmountWithRetainedPercentage
	FROM #LeaseDetails Contract
	JOIN #SyndicationDetailsTemp SyndicationDetail ON Contract.ContractId = SyndicationDetail.ContractId AND Contract.IsChargedOff = 0
	JOIN (SELECT Asset.AssetId,Asset.ContractId FROM #AssetTemp Asset WHERE  Asset.IsActive = 1 GROUP BY Asset.AssetId,Asset.ContractId) AS Asset 
	ON SyndicationDetail.ReceivableForTransferType = @ParticipatedSale AND SyndicationDetail.ContractId = Asset.ContractId  
	JOIN AssetValueHistories AVH ON Asset.AssetId = AVH.AssetId AND AVH.IncomeDate < SyndicationDetail.SyndicationEffectiveDate  AND AVH.SourceModule IN (@FixedTermBookDepSourceModule,@OTPDepreciation)
	AND AVH.IsAccounted = 1 AND AVH.IsCleared = 0 AND AVH.IsLessorOwned = 1 AND AVH.GLJournalId IS NOT NULL AND AVH.ReversalGLJournalId IS NULL
	GROUP BY SyndicationDetail.ContractId,SyndicationDetail.RetainedPercentage)
	UPDATE #RNITemp SET AccumulatedDepreciation_Amount = AccumulatedDepreciation_Amount + SyndicatedAccumulateDep.AmountWithRetainedPercentage
	FROM #RNITemp RNI
	JOIN CTE_SyndicatedAccumulateDep SyndicatedAccumulateDep ON RNI.ContractId = SyndicatedAccumulateDep.ContractId;
	END
	/*OverTerm Depreciations*/
	IF EXISTS(SELECT 1 FROM #LeaseDetails WHERE OTPLease = 1)
	BEGIN
	/*Cash Based OTP Depreciation : Partially Cash posted*/
	;WITH CTE_CashBasedOTPAVHInfo AS
	(SELECT Contract.ContractId
	,ABS(SUM(AssetValueHistoryDetail.AmountPosted_Amount)) AS OTPDepreciationCashBasedAmount
	FROM (SELECT ContractId
	FROM #LeaseDetails Lease
	JOIN ReceivableCodes ReceivableCode ON Lease.OTPReceivableCodeId = ReceivableCode.Id AND ReceivableCode.AccountingTreatment = @CashBasedAccountingTreatment
	AND SyndicationType <> @FullSale AND OTPLease = 1)  AS Contract
	JOIN (SELECT Asset.AssetId,Asset.ContractId FROM #AssetTemp Asset WHERE  Asset.IsActive = 1 GROUP BY Asset.AssetId,Asset.ContractId) AS Asset
	ON Contract.ContractId = Asset.ContractId
	JOIN AssetValueHistories AVH ON Asset.AssetId = AVH.AssetId AND AVH.SourceModule = @OTPDepreciation AND AVH.IsAccounted = 1 AND AVH.IsLessorOwned = 1 AND AVH.GLJournalId IS NULL
	JOIN AssetValueHistoryDetails AssetValueHistoryDetail ON AVH.Id = AssetValueHistoryDetail.AssetValueHistoryId AND AssetValueHistoryDetail.GLJournalId IS NOT NULL AND AssetValueHistoryDetail.IsActive = 1
	GROUP BY Contract.ContractId)
	UPDATE #RNITemp SET AccumulatedDepreciation_Amount = AccumulatedDepreciation_Amount + OTPAVHInfo.OTPDepreciationCashBasedAmount
	FROM #RNITemp RNI
	JOIN CTE_CashBasedOTPAVHInfo OTPAVHInfo ON RNI.ContractId = OTPAVHInfo.ContractId;
	/*OTP Residual Recapture*/ -- CE
	/*Cash Based Residual Recapture*/
	;WITH CTE_CashBasedAVHInfo AS
	(SELECT Contract.ContractId
	,ABS(SUM(AssetValueHistoryDetail.AmountPosted_Amount)) AS OTPResidualRecaptureCashBasedAmount
	FROM (SELECT ContractId
	FROM #LeaseDetails Lease
	JOIN ReceivableCodes ReceivableCode ON Lease.OTPReceivableCodeId = ReceivableCode.Id AND ReceivableCode.AccountingTreatment = @CashBasedAccountingTreatment
	AND SyndicationType <> @FullSale AND OTPLease = 1)  AS Contract
	JOIN (SELECT Asset.AssetId,Asset.ContractId FROM #AssetTemp Asset WHERE  Asset.IsActive = 1 GROUP BY Asset.AssetId,Asset.ContractId) AS Asset
	ON Contract.ContractId = Asset.ContractId
	JOIN AssetValueHistories AVH ON Asset.AssetId = AVH.AssetId AND AVH.SourceModule = @ResidualRecapture AND AVH.IsAccounted = 1 AND AVH.IsLessorOwned = 1 
	JOIN AssetValueHistoryDetails AssetValueHistoryDetail ON AVH.Id = AssetValueHistoryDetail.AssetValueHistoryId AND AssetValueHistoryDetail.GLJournalId IS NOT NULL AND AssetValueHistoryDetail.IsActive = 1
	GROUP BY Contract.ContractId)
	UPDATE #RNITemp SET OTPResidualRecapture_Amount = AVHInfo.OTPResidualRecaptureCashBasedAmount
	FROM #RNITemp RNI
	JOIN CTE_CashBasedAVHInfo AVHInfo ON RNI.ContractId = AVHInfo.ContractId;
	/*Accrual Based Residual Recapture*/
	;WITH CTE_AccrualBasedAVHInfo AS
	(SELECT Contract.ContractId
	,ABS(SUM(AVH.Value_Amount)) AS OTPResidualRecaptureAccrualBasedAmount
	FROM (SELECT ContractId
	FROM #LeaseDetails Lease
	JOIN ReceivableCodes ReceivableCode ON Lease.OTPReceivableCodeId = ReceivableCode.Id AND ReceivableCode.AccountingTreatment = @AccrualBased
	AND SyndicationType <> @FullSale AND OTPLease = 1)  AS Contract
	JOIN (SELECT Asset.AssetId,Asset.ContractId FROM #AssetTemp Asset WHERE  Asset.IsActive = 1 GROUP BY Asset.AssetId,Asset.ContractId) AS Asset
	ON Contract.ContractId = Asset.ContractId
	JOIN AssetValueHistories AVH ON Asset.AssetId = AVH.AssetId AND AVH.SourceModule = @ResidualRecapture AND AVH.GLJournalId IS NOT NULL AND AVH.IsAccounted = 1 AND AVH.IsLessorOwned = 1  AND AVH.ReversalGLJournalId IS NULL
	GROUP BY Contract.ContractId)
	UPDATE #RNITemp SET OTPResidualRecapture_Amount = AVHInfo.OTPResidualRecaptureAccrualBasedAmount
	FROM #RNITemp RNI
	JOIN CTE_AccrualBasedAVHInfo AVHInfo ON RNI.ContractId = AVHInfo.ContractId;
	END
	/*Operating Lease Rent OSAR*/ -- CE
	UPDATE #RNITemp SET OperatingLeaseRentOSAR_Amount = OperatingLeaseRent.OperatingLeaseRentAmount
	FROM #RNITemp RNI
	JOIN (SELECT Receivable.ContractId
	,SUM(Receivable.Balance_Amount) AS OperatingLeaseRentAmount
	FROM #LeaseDetails Contract
	JOIN #ReceivableDetailsTemp Receivable ON Contract.LeaseContractType = @OperatingContractSubType AND Contract.IsChargedOff = 0 AND Contract.ContractId = Receivable.ContractId
	AND Receivable.ReceivableType IN (@OperatingLeaseRental,@LeasePayOff,@BuyOut)
	AND Receivable.IsGLPosted = 1 AND Receivable.FunderId IS NULL AND Receivable.IsFinanceComponent = 0
	GROUP BY Receivable.ContractId)
	AS OperatingLeaseRent ON RNI.ContractId = OperatingLeaseRent.ContractId;
	/*Syndicated Operating Lease Rent OSAR*/ -- CE /*Finance Syndicated Operating Lease Rent OSAR*/ -- CE
	IF EXISTS(SELECT 1 FROM #SyndicationDetailsTemp)
	BEGIN
	;WITH CTE_SyndicatedOperatingLeaseRent AS
	(SELECT ReceivableDetail.ContractId
	,SUM(ReceivableDetail.Balance_Amount) AS [SyndicatedOperatingLeaseRent]
	,ReceivableDetail.IsFinanceComponent
	FROM #LeaseDetails Contract
	JOIN #SyndicationDetailsTemp SyndicationDetail ON Contract.LeaseContractType = @OperatingContractSubType AND Contract.ContractId = SyndicationDetail.ContractId AND SyndicationDetail.IsServiced = 1 AND Contract.IsChargedOff = 0
	JOIN #ReceivableDetailsTemp ReceivableDetail ON Contract.ContractId = ReceivableDetail.ContractId AND ReceivableDetail.ReceivableType IN (@OperatingLeaseRental,@LeasePayOff,@BuyOut)
	AND ReceivableDetail.FunderId IS NOT NULL
	AND ((SyndicationDetail.IsCollected = 1 AND ReceivableDetail.IsGLPosted = 1) OR (SyndicationDetail.IsCollected = 0 AND ReceivableDetail.DueDate <= @IncomeDate))
	GROUP BY ReceivableDetail.ContractId,ReceivableDetail.IsFinanceComponent)
	UPDATE #RNITemp
	SET SyndicatedFixedTermReceivablesOSAR_Amount = SyndicatedFixedTermReceivablesOSAR_Amount + ISNULL(OSAR.[SyndicatedOperatingLeaseRent],0.00)
	,FinanceSyndicatedFixedTermReceivablesOSAR_Amount = FinanceSyndicatedFixedTermReceivablesOSAR_Amount + ISNULL(FinanceOSAR.[SyndicatedOperatingLeaseRent],0.00)
	FROM #RNITemp RNI
	LEFT JOIN CTE_SyndicatedOperatingLeaseRent OSAR ON RNI.ContractId = OSAR.ContractId AND OSAR.IsFinanceComponent = 0
	LEFT JOIN CTE_SyndicatedOperatingLeaseRent FinanceOSAR ON RNI.ContractId = FinanceOSAR.ContractId AND FinanceOSAR.IsFinanceComponent = 1;
	END
	/*Interim Rent OSAR*/
	UPDATE #RNITemp SET InterimRentOSAR_Amount = InterimRent.InterimRentAmount
	FROM #RNITemp RNI
	JOIN (SELECT Receivable.ContractId
	,SUM(Receivable.Balance_Amount) AS InterimRentAmount
	FROM #LeaseDetails Contract
	JOIN #ReceivableDetailsTemp Receivable ON Contract.ContractId = Receivable.ContractId
	AND Receivable.ReceivableType = @InterimRental AND Receivable.FunderId IS NULL AND Receivable.IsGLPosted = 1
	GROUP BY Receivable.ContractId) AS InterimRent ON RNI.ContractId = InterimRent.ContractId;
	/*Deferred Operating Income*/
	IF(@IncludeDeferredInterimRent =1)
	BEGIN
	--Non SKU
	INSERT INTO #DeferredInterimRentInfoTemp
	SELECT LeaseAsset.ContractId
	,SUM(ReceivableDetail.Amount_Amount) AS DeferredInterimRent
	FROM #AssetTemp LeaseAsset 
	JOIN Receivables Receivable ON LeaseAsset.ContractId = Receivable.EntityId AND Receivable.EntityType = @ContractEntityType AND Receivable.IsActive=1 
	AND LeaseAsset.IsSKU=0 AND LeaseAsset.IsLeaseAsset = 1 
	JOIN ReceivableDetails ReceivableDetail ON Receivable.Id = ReceivableDetail.ReceivableId AND ReceivableDetail.IsActive = 1 
	AND LeaseAsset.AssetId = ReceivableDetail.AssetId
	WHERE Receivable.IncomeType = @InterimRent 
	GROUP BY LeaseAsset.ContractId

	--SKU
	INSERT INTO #DeferredInterimRentInfoTemp 
	SELECT  LeaseAsset.ContractId,SUM(ReceivableSKU.Amount_Amount) AS DeferredInterimRent  
	FROM #AssetTemp LeaseAsset 
	JOIN Receivables Receivable ON LeaseAsset.ContractId = Receivable.EntityId AND Receivable.EntityType = @ContractEntityType AND Receivable.IsActive=1 
	AND LeaseAsset.IsSKU =1 AND LeaseAsset.IsLeaseAsset=1
	JOIN ReceivableDetails ReceivableDetail ON Receivable.Id = ReceivableDetail.ReceivableId AND ReceivableDetail.IsActive = 1 AND LeaseAsset.AssetId = ReceivableDetail.AssetId
	JOIN LeaseAssetSKUs LeaseAssetSKU ON LeaseAssetSKU.LeaseAssetId = LeaseAsset.LeaseAssetId 
	JOIN ReceivableSKUs ReceivableSKU ON ReceivableSKU.AssetSKUId = LeaseAssetSKU.AssetSKUId and ReceivableSKU.ReceivableDetailId=ReceivableDetail.Id
	WHERE Receivable.IncomeType = @InterimRent  AND LeaseAssetSKU.IsLeaseComponent = 1
	GROUP BY LeaseAsset.ContractId
	END

	;WITH CTE_AssetInfo AS
	(SELECT Contract.ContractId,
	SUM(LeaseAsset.DefferedRentalAmount) AS LeaseAssetAmount
	FROM #LeaseDetails Contract
	JOIN #AssetTemp LeaseAsset ON Contract.LeaseContractType = @OperatingContractSubType AND Contract.ContractId = LeaseAsset.ContractId
	AND LeaseAsset.IsLeaseAsset = 1
	GROUP BY Contract.ContractId),
	CTE_ReceivableInfo AS
	(SELECT ReceivableDetail.ContractId
	,SUM(ReceivableDetail.Amount_Amount) AS TotalAmount
	FROM #ReceivableDetailsTemp ReceivableDetail
	WHERE ReceivableDetail.ReceivableType = @OperatingLeaseRental AND ReceivableDetail.IsFinanceComponent = 0
	AND ReceivableDetail.FunderId IS NULL AND ReceivableDetail.IsGLPosted = 1
	GROUP BY ReceivableDetail.ContractId),
	CTE_IncomeInfo AS
	(SELECT Contract.ContractId
	,SUM(IncomeSched.RentalIncome_Amount) AS RentalIncomeAmount
	FROM #LeaseDetails Contract
	JOIN #LeaseIncomeScheduleTemp IncomeSched ON Contract.LeaseContractType = @OperatingContractSubType AND Contract.ContractId = IncomeSched.ContractId
	AND IncomeSched.IncomeType = @FixedTerm AND IncomeSched.IsLessorOwned = 1 AND IncomeSched.IsGLPosted = 1 AND IncomeSched.IsAccounting = 1
	GROUP BY Contract.ContractId)

	UPDATE #RNITemp SET DeferredOperatingIncome_Amount = AssetInfo.LeaseAssetAmount + ISNULL(ReceivableInfo.TotalAmount,0.00) 
	+ ISNULL(DeferredInterimRentInfo.DeferredInterimRent, 0.00)- ISNULL(IncomeInfo.RentalIncomeAmount,0.00)
	FROM #RNITemp RNI
	JOIN #BasicDetails ContractInfo ON RNI.ContractId = ContractInfo.ContractId AND ContractInfo.IsChargedOff = 0
	JOIN CTE_AssetInfo AssetInfo ON RNI.ContractId = AssetInfo.ContractId
	LEFT JOIN CTE_ReceivableInfo ReceivableInfo ON RNI.ContractId = ReceivableInfo.ContractId
	LEFT JOIN CTE_IncomeInfo IncomeInfo ON RNI.ContractId = IncomeInfo.ContractId
	LEFT JOIN (SELECT ContractId, SUM(DeferredInterimRent) AS DeferredInterimRent FROM #DeferredInterimRentInfoTemp GROUP BY ContractId) DeferredInterimRentInfo 
	ON RNI.ContractId = DeferredInterimRentInfo.ContractId ;

	/*Deferred Overterm Extension Income*/
	IF EXISTS(SELECT 1 FROM #LeaseDetails WHERE OTPLease = 1 AND SyndicationType != @FullSale)
	BEGIN
	;WITH CTE_DeferredOTPReceivableInfo AS
	(SELECT Receivable.ContractId
	,SUM(Receivable.Amount_Amount) AS ReceivableAmount
	FROM #LeaseDetails Contract
	JOIN #ReceivableDetailsTemp Receivable ON Contract.ContractId = Receivable.ContractId AND Contract.SyndicationType != @FullSale
	AND Receivable.ReceivableType IN (@OverTermRental, @Supplemental) AND Receivable.IsGLPosted = 1
	GROUP BY Receivable.ContractId)
	UPDATE #RNITemp SET DeferredExtensionIncome_Amount = OTPReceivable.ReceivableAmount
	FROM #RNITemp RNI
	JOIN CTE_DeferredOTPReceivableInfo OTPReceivable ON RNI.ContractId = OTPReceivable.ContractId;
	;WITH CTE_CashBasedDeferredOTPReceivableInfo AS
	(SELECT Receivable.ContractId
	,SUM(Receivable.Amount_Amount - Receivable.Balance_Amount) AS CashBasedReceivableBalanceAmount
	FROM #LeaseDetails Contract
	JOIN #ReceivableDetailsTemp Receivable ON Contract.ContractId = Receivable.ContractId AND Contract.SyndicationType != @FullSale
	AND Receivable.AccountingTreatment = @CashBasedAccountingTreatment AND Receivable.ReceivableType IN (@OverTermRental, @Supplemental) AND Receivable.Amount_Amount != Receivable.Balance_Amount
	AND Contract.IsChargedOff = 0 
	GROUP BY Receivable.ContractId)
	UPDATE #RNITemp SET DeferredExtensionIncome_Amount = DeferredExtensionIncome_Amount - OTPReceivable.CashBasedReceivableBalanceAmount
	FROM #RNITemp RNI
	JOIN CTE_CashBasedDeferredOTPReceivableInfo OTPReceivable ON RNI.ContractId = OTPReceivable.ContractId;
	;WITH CTE_AccrualBasedDeferredOTPReceivableInfo AS
	(SELECT Contract.ContractId
	, SUM(IncomeSched.RentalIncome_Amount) AS AccrualBasedRentalAmount
	FROM #LeaseDetails Contract
	JOIN #LeaseIncomeScheduleTemp IncomeSched ON Contract.ContractId = IncomeSched.ContractId AND Contract.SyndicationType != @FullSale AND IncomeSched.IsIncomeBeforeCommencement = 0
	AND IncomeSched.IncomeType in(@OverTerm,@Supplemental) AND IncomeSched.AccountingTreatment = @AccrualBased
	AND IncomeSched.IsLessorOwned = 1 AND IncomeSched.IsGLPosted = 1 AND IncomeSched.IsAccounting = 1 AND Contract.IsChargedOff = 0 
	GROUP BY Contract.ContractId)
	UPDATE #RNITemp SET DeferredExtensionIncome_Amount = DeferredExtensionIncome_Amount - OTPReceivable.AccrualBasedRentalAmount
	FROM #RNITemp RNI
	JOIN CTE_AccrualBasedDeferredOTPReceivableInfo OTPReceivable ON RNI.ContractId = OTPReceivable.ContractId;
	END
	/*Capital Lease Contract Receivable*/ -- CE
	IF EXISTS(SELECT 1 FROM #LeveragedLeaseDetails)
	BEGIN
	UPDATE #RNITemp SET CapitalLeaseContractReceivable_Amount = Receivable.ReceivableAmount
	FROM #RNITemp RNI
	JOIN (SELECT Receivable.ContractId
	,SUM(Amount_Amount) AS ReceivableAmount
	FROM #ReceivableDetailsTemp Receivable
	WHERE Receivable.ReceivableType = @LeveragedLeaseRental AND Receivable.FunderId IS NULL AND Receivable.IsGLPosted = 0
	GROUP BY Receivable.ContractId)
	AS Receivable ON RNI.ContractId = Receivable.ContractId;
	END
	/*Capital Lease Contract Receivable*/ /*Financing Contract Receivable*/
	;WITH CTE_CapitalLeaseReceivable AS
	(SELECT ContractDateInfo.ContractId
	,SUM(ReceivableDetail.Amount_Amount) AS Amount
	,ReceivableDetail.IsFinanceComponent
	FROM #LeaseDetails Contract
	JOIN #BasicDetails ContractDateInfo ON Contract.ContractId = ContractDateInfo.ContractId
	JOIN #ReceivableDetailsTemp ReceivableDetail ON ContractDateInfo.ContractId = ReceivableDetail.ContractId
	AND ReceivableDetail.ReceivableType IN (@CapitalLeaseRental,@OperatingLeaseRental,@LeasePayOff,@BuyOut)
	AND ReceivableDetail.IsGLPosted = 0 AND ReceivableDetail.FunderId IS NULL AND ReceivableDetail.IsDummy = 0
	WHERE (Contract.LeaseContractType <> @OperatingContractSubType OR ReceivableDetail.IsFinanceComponent = 1)
	AND (ContractDateInfo.IsChargedOff = 0 OR ReceivableDetail.PaymentStartDate < ContractDateInfo.ChargeOffDate)
	GROUP BY ContractDateInfo.ContractId,ReceivableDetail.IsFinanceComponent)
	UPDATE #RNITemp
	SET CapitalLeaseContractReceivable_Amount = ISNULL(Receivable.Amount,0.00),
	FinancingContractReceivable_Amount = ISNULL(FinanceReceivable.Amount,0.00)
	FROM #RNITemp RNI
	LEFT JOIN CTE_CapitalLeaseReceivable Receivable ON RNI.ContractId = Receivable.ContractId AND Receivable.IsFinanceComponent = 0
	LEFT JOIN CTE_CapitalLeaseReceivable FinanceReceivable ON RNI.ContractId = FinanceReceivable.ContractId AND FinanceReceivable.IsFinanceComponent = 1;
	/*Syndicated Capital Lease Contract Receivable*/ -- CE
	IF EXISTS(SELECT 1 FROM #SyndicationDetailsTemp WHERE IsServiced = 1)
	BEGIN
	;WITH CTE_SyndicatedCapitalLeaseReceivable AS
	(SELECT ReceivableDetail.ContractId
	,SUM(ReceivableDetail.Amount_Amount) AS Amount
	,ReceivableDetail.IsFinanceComponent
	FROM #LeaseDetails Contract
	JOIN #BasicDetails ContractDateInfo ON Contract.ContractId = ContractDateInfo.ContractId
	JOIN #SyndicationDetailsTemp SyndicationDetail ON ContractDateInfo.ContractId = SyndicationDetail.ContractId AND SyndicationDetail.IsServiced =1
	JOIN #ReceivableDetailsTemp ReceivableDetail ON SyndicationDetail.ContractId = ReceivableDetail.ContractId AND ReceivableDetail.ReceivableType IN (@CapitalLeaseRental, @OperatingLeaseRental,@LeasePayOff,@BuyOut)
	AND ReceivableDetail.FunderId IS NOT NULL
	AND (Contract.LeaseContractType <> @OperatingContractSubType OR ReceivableDetail.IsFinanceComponent = 1)
	AND ((SyndicationDetail.IsCollected = 1 AND ReceivableDetail.IsGLPosted = 0) OR (SyndicationDetail.IsCollected = 0 AND ReceivableDetail.DueDate > @IncomeDate))
	AND (ContractDateInfo.IsChargedOff = 0 OR ReceivableDetail.PaymentStartDate < ContractDateInfo.ChargeOffDate)
	GROUP BY ReceivableDetail.ContractId,ReceivableDetail.IsFinanceComponent)
	UPDATE #RNITemp
	SET SyndicatedCapitalLeaseContractReceivable_Amount =  ISNULL(Receivable.Amount,0) ,
	SyndicatedFinancingContractReceivable_Amount = ISNULL(FinanceReceivable.Amount,0)
	FROM #RNITemp RNI
	LEFT JOIN CTE_SyndicatedCapitalLeaseReceivable Receivable ON RNI.ContractId = Receivable.ContractId AND Receivable.IsFinanceComponent = 0
	LEFT JOIN CTE_SyndicatedCapitalLeaseReceivable FinanceReceivable ON RNI.ContractId = FinanceReceivable.ContractId AND FinanceReceivable.IsFinanceComponent = 1
	END;
	/*Unguaranteed Residual,Customer Guaranteed Residual, Third Party Guaranteed residual*/
	/*Finance Unguaranteed Residual,Finance Customer Guaranteed Residual, Finance Third Party Guaranteed residual*/
	;WITH CTE_Residual AS
	(SELECT Contract.ContractId
	,SUM(LeaseAsset.BookedResidual_Amount - (LeaseAsset.CustomerGuaranteedResidual_Amount + LeaseAsset.ThirdPartyGuaranteedResidual_Amount)) AS UnguaranteedResidual
	,SUM(LeaseAsset.CustomerGuaranteedResidual_Amount) AS CustomerGuaranteedResidual
	,SUM(LeaseAsset.ThirdPartyGuaranteedResidual_Amount) AS ThirdPartyGuaranteedResidual
	,LeaseAsset.IsLeaseAsset
	FROM (SELECT ContractId,LeaseContractType FROM #LeaseDetails WHERE SyndicationType != @FullSale AND IsChargedOff = 0) Contract
	JOIN #AssetTemp LeaseAsset ON Contract.ContractId = LeaseAsset.ContractId AND LeaseAsset.IsActive = 1
	WHERE (Contract.LeaseContractType <> @OperatingContractSubType OR LeaseAsset.IsLeaseAsset = 0)
	GROUP BY Contract.ContractId, LeaseAsset.IsLeaseAsset)
	UPDATE #RNITemp
	SET UnguaranteedResidual_Amount = ISNULL(Residual.UnguaranteedResidual,0)
	, CustomerGuaranteedResidual_Amount = ISNULL(Residual.CustomerGuaranteedResidual,0)
	, ThirdPartyGauranteedResidual_Amount = ISNULL(Residual.ThirdPartyGuaranteedResidual,0)
	, FinanceUnguaranteedResidual_Amount = ISNULL(FinanceResidual.UnguaranteedResidual,0)
	, FinanceCustomerGuaranteedResidual_Amount = ISNULL(FinanceResidual.CustomerGuaranteedResidual,0)
	, FinanceThirdPartyGauranteedResidual_Amount = ISNULL(FinanceResidual.ThirdPartyGuaranteedResidual,0)
	FROM #RNITemp RNI
	LEFT JOIN CTE_Residual Residual ON RNI.ContractId = Residual.ContractId AND Residual.IsLeaseAsset=1
	LEFT JOIN CTE_Residual FinanceResidual ON RNI.ContractId = FinanceResidual.ContractId AND FinanceResidual.IsLeaseAsset=0;
	IF EXISTS(SELECT 1 FROM #SyndicationDetailsTemp WHERE RetainedPercentage > 0)
	BEGIN
	UPDATE #RNITemp SET UnguaranteedResidual_Amount = UnguaranteedResidual_Amount * (SyndicationDetail.RetainedPercentage/100),
	CustomerGuaranteedResidual_Amount = CustomerGuaranteedResidual_Amount * (SyndicationDetail.RetainedPercentage/100),
	ThirdPartyGauranteedResidual_Amount = ThirdPartyGauranteedResidual_Amount * (SyndicationDetail.RetainedPercentage/100),
	FinanceUnguaranteedResidual_Amount = FinanceUnguaranteedResidual_Amount * (SyndicationDetail.RetainedPercentage/100),
	FinanceCustomerGuaranteedResidual_Amount = FinanceCustomerGuaranteedResidual_Amount * (SyndicationDetail.RetainedPercentage/100),
	FinanceThirdPartyGauranteedResidual_Amount = FinanceThirdPartyGauranteedResidual_Amount * (SyndicationDetail.RetainedPercentage/100)
	FROM #RNITemp RNI
	JOIN #SyndicationDetailsTemp SyndicationDetail ON RNI.ContractId = SyndicationDetail.ContractId AND SyndicationDetail.RetainedPercentage > 0;
	END
	/*Capital Lease Rent OSAR*/ -- CE /*Finance Lease Rent OSAR*/ -- CE
	;WITH CTE_CapitalLeaseRent AS
	(SELECT Contract.ContractId
	,SUM(ReceivableDetail.Balance_Amount) AS LeaseRentAmount
	,ReceivableDetail.IsFinanceComponent
	FROM #LeaseDetails Contract
	JOIN #ReceivableDetailsTemp ReceivableDetail ON Contract.IsChargedOff = 0  AND Contract.ContractId = ReceivableDetail.ContractId
	AND ReceivableDetail.ReceivableType IN (@CapitalLeaseRental,@OperatingLeaseRental,@LeasePayOff,@BuyOut)
	AND (Contract.LeaseContractType <> @OperatingContractSubType OR ReceivableDetail.IsFinanceComponent = 1)
	AND ReceivableDetail.FunderId IS NULL AND ReceivableDetail.IsGLPosted = 1
	GROUP BY Contract.ContractId,ReceivableDetail.IsFinanceComponent)
	UPDATE #RNITemp SET CapitalLeaseRentOSAR_Amount =  ISNULL(OSAR.LeaseRentAmount,0.00),
	FinancingRentOSAR_Amount = ISNULL(FinanceOSAR.LeaseRentAmount,0.00)
	FROM #RNITemp RNI
	LEFT JOIN CTE_CapitalLeaseRent OSAR ON RNI.ContractId = OSAR.ContractId AND OSAR.IsFinanceComponent = 0
	LEFT JOIN CTE_CapitalLeaseRent FinanceOSAR ON RNI.ContractId = FinanceOSAR.ContractId AND FinanceOSAR.IsFinanceComponent = 1;
	IF EXISTS(SELECT 1 FROM #LeveragedLeaseDetails)
	BEGIN
	;WITH CTE_CapitalLeaseRent AS
	(SELECT Contract.ContractId
	,SUM(ReceivableDetail.Balance_Amount) AS LeaseRentAmount
	FROM #LeveragedLeaseDetails Contract
	JOIN #ReceivableDetailsTemp ReceivableDetail ON Contract.ContractId = ReceivableDetail.ContractId
	AND ReceivableDetail.ReceivableType IN (@LeveragedLeaseRental,@LeveragedLeasePayoff,@BuyOut)
	AND ReceivableDetail.FunderId IS NULL AND ReceivableDetail.IsGLPosted = 1
	GROUP BY Contract.ContractId)
	UPDATE #RNITemp SET CapitalLeaseRentOSAR_Amount =  OSAR.LeaseRentAmount
	FROM #RNITemp RNI
	JOIN CTE_CapitalLeaseRent OSAR ON RNI.ContractId = OSAR.ContractId;
	END
	/*Syndicated Capital Lease Rent OSAR*/-- CE /*Syndicated Finance Lease Rent OSAR*/-- CE
	IF EXISTS(SELECT 1 FROM #SyndicationDetailsTemp WHERE IsServiced = 1)
	BEGIN
	WITH CTE_SyndicatedLeaseRent AS
	(SELECT ReceivableDetail.ContractId
	,SUM(ReceivableDetail.Balance_Amount) AS SyndicatedLeaseRentAmount
	, ReceivableDetail.IsFinanceComponent
	FROM #LeaseDetails Contract
	JOIN #SyndicationDetailsTemp SyndicationDetail ON Contract.ContractId = SyndicationDetail.ContractId AND SyndicationDetail.IsServiced = 1 AND Contract.IsChargedOff = 0
	JOIN #ReceivableDetailsTemp ReceivableDetail ON Contract.ContractId = ReceivableDetail.ContractId
	AND ReceivableDetail.ReceivableType IN (@CapitalLeaseRental,@LeasePayOff,@BuyOut)
	AND ReceivableDetail.FunderId IS NOT NULL
	AND ((SyndicationDetail.IsCollected = 1 AND ReceivableDetail.IsGLPosted = 1) OR (SyndicationDetail.IsCollected = 0 AND ReceivableDetail.DueDate <= @IncomeDate))
	GROUP BY ReceivableDetail.ContractId, ReceivableDetail.IsFinanceComponent)
	UPDATE #RNITemp
	SET SyndicatedFixedTermReceivablesOSAR_Amount = SyndicatedFixedTermReceivablesOSAR_Amount + ISNULL(OSAR.SyndicatedLeaseRentAmount,0.00) ,
	FinanceSyndicatedFixedTermReceivablesOSAR_Amount = FinanceSyndicatedFixedTermReceivablesOSAR_Amount + ISNULL(FinanceOSAR.SyndicatedLeaseRentAmount,0.00)
	FROM #RNITemp RNI
	LEFT JOIN CTE_SyndicatedLeaseRent OSAR ON RNI.ContractId = OSAR.ContractId AND OSAR.IsFinanceComponent = 0
	LEFT JOIN CTE_SyndicatedLeaseRent FinanceOSAR ON RNI.ContractId = FinanceOSAR.ContractId AND FinanceOSAR.IsFinanceComponent = 1;
	END
	/*Over Term Rent OSAR*/ -- CE
	IF EXISTS(SELECT 1 FROM #LeaseDetails WHERE OTPLease = 1 AND SyndicationType != @FullSale)
	BEGIN
	;WITH CTE_OverTermRentOSAR AS
	(SELECT ReceivableDetail.ContractId
	,SUM(ReceivableDetail.Balance_Amount) AS OverTermRentOSARAmount
	FROM #LeaseDetails Contract
	JOIN #ReceivableDetailsTemp ReceivableDetail ON Contract.ContractId = ReceivableDetail.ContractId AND Contract.SyndicationType != @FullSale
	AND ReceivableDetail.IsGLPosted = 1 AND ReceivableDetail.FunderId IS NULL
	AND ReceivableDetail.ReceivableType IN (@OverTermRental, @Supplemental)
	AND ReceivableDetail.AccountingTreatment IN (@CashBasedAccountingTreatment, @AccrualBased) AND Contract.IsChargedOff = 0
	GROUP BY ReceivableDetail.ContractId)
	UPDATE #RNITemp
	SET OverTermRentOSAR_Amount = OSAR.OverTermRentOSARAmount
	FROM #RNITemp RNI
	JOIN CTE_OverTermRentOSAR OSAR ON RNI.ContractId = OSAR.ContractId;
	END
	/*Syndicated Over Term Rent OSAR*/ -- CE
	IF EXISTS(SELECT 1 FROM #SyndicationDetailsTemp WHERE ReceivableForTransferType IN(@FullSale,@ParticipatedSale) AND IsServiced = 1)
	BEGIN
	;WITH CTE_SyndicatedOverTermRentOSAR AS
	(SELECT Receivable.ContractId
	,SUM(Receivable.Balance_Amount) AS SyndicatedOverTermRentAmount
	FROM (SELECT ContractId,IsCollected FROM #SyndicationDetailsTemp WHERE ReceivableForTransferType IN(@FullSale,@ParticipatedSale) AND IsServiced = 1) SyndicationDetail
	JOIN #BasicDetails Contract ON Contract.ContractId = SyndicationDetail.ContractId AND Contract.IsChargedOff = 0
	JOIN #ReceivableDetailsTemp Receivable ON SyndicationDetail.ContractId = Receivable.ContractId
	AND Receivable.ReceivableType IN (@OverTermRental, @Supplemental) AND Receivable.FunderId IS NOT NULL
	AND ((SyndicationDetail.IsCollected = 1 AND Receivable.IsGLPosted = 1) OR (SyndicationDetail.IsCollected = 0 AND Receivable.DueDate <= @IncomeDate))
	GROUP BY Receivable.ContractId)
	UPDATE #RNITemp
	SET SyndicatedFixedTermReceivablesOSAR_Amount = SyndicatedFixedTermReceivablesOSAR_Amount + OSAR.SyndicatedOverTermRentAmount
	FROM #RNITemp RNI
	JOIN CTE_SyndicatedOverTermRentOSAR OSAR ON RNI.ContractId = OSAR.ContractId;
	END
	/*Accumulated NBV Impairment*/
	;WITH CTE_AccumulatedNBVImpairment AS
	(SELECT Contract.ContractId
	,(-1) * SUM(AVH.Value_Amount) AS AccumulatedNBVImpairmentAmount
	FROM (SELECT ContractId FROM #LeaseDetails WHERE (LeaseContractType = @OperatingContractSubType OR OTPLease = 1) AND SyndicationType != @FullSale) AS Contract
	JOIN #AssetTemp Asset ON Contract.ContractId = Asset.ContractId AND Asset.IsActive = 1
	JOIN AssetValueHistories AVH With (ForceSeek) ON Asset.AssetId = AVH.AssetId AND Asset.IsLeaseAsset = AVH.IsLeaseComponent  AND AVH.SourceModule = @NBVImpairmentSourceModule AND AVH.GLJournalId IS NOT NULL
	AND AVH.IsAccounted = 1 AND AVH.IsCleared = 0
	GROUP BY Contract.ContractId)
	UPDATE #RNITemp
	SET AccumulatedNBVImpairment_Amount = Impairment.AccumulatedNBVImpairmentAmount
	FROM #RNITemp RNI
	JOIN CTE_AccumulatedNBVImpairment Impairment ON RNI.ContractId = Impairment.ContractId;
	/*Held For Sale Allowance*/
	;WITH CTE_HeldForSaleAllowance AS
	(SELECT ValuationAllowance.ContractId
	,SUM(ValuationAllowance.Allowance_Amount) AS HeldForSaleAllowance
	FROM #BasicDetails Contract
	JOIN ValuationAllowances ValuationAllowance ON Contract.ContractId = ValuationAllowance.ContractId AND ValuationAllowance.IsActive = 1
	GROUP BY ValuationAllowance.ContractId)
	UPDATE #RNITemp SET HeldForSaleValuationAllowance_Amount = HFSAllowance.HeldForSaleAllowance
	FROM #RNITemp RNI
	JOIN CTE_HeldForSaleAllowance HFSAllowance ON RNI.ContractId = HFSAllowance.ContractId;
	/*Prepaid Receivables*/ -- CE
	/*Syndicated Prepaid Receivables*/ -- CE
	;WITH CTE_ReceivableInfo AS
	(SELECT Receivable.ContractId
	,SUM(CASE WHEN FunderId IS NULL THEN Receivable.Amount_Amount - Receivable.Balance_Amount ELSE 0.00 END) AS ReceivableAmount
	,SUM(CASE WHEN FunderId IS NOT NULL THEN Receivable.Amount_Amount - Receivable.Balance_Amount ELSE 0.00 END) AS SyndicatedReceivableAmount
	FROM #BasicDetails Contract
	JOIN #ReceivableDetailsTemp Receivable ON Contract.ContractId = Receivable.ContractId AND Receivable.Amount_Amount != Receivable.Balance_Amount
	AND Receivable.IsGLPosted = 0 AND Receivable.IsDummy = 0
	AND Receivable.ReceivableType IN (@InterimRental,@CapitalLeaseRental,@OperatingLeaseRental,@LeaseFloatRateAdj, @OverTermRental,@LeasePayOff,@BuyOut, @LeaseInterimInterest, @LoanPrincipal,@LeveragedLeaseRental)
	AND (Contract.IsChargedOff = 0 OR Receivable.PaymentStartDate < Contract.ChargeOffDate)
	GROUP BY Receivable.ContractId)
	UPDATE #RNITemp
	SET PrepaidReceivables_Amount = PrepaidReceivable.ReceivableAmount,
	SyndicatedPrepaidReceivables_Amount = PrepaidReceivable.SyndicatedReceivableAmount
	FROM #RNITemp RNI
	JOIN CTE_ReceivableInfo PrepaidReceivable ON RNI.ContractId = PrepaidReceivable.ContractId;

	/*Sales Tax OSAR*//*Syndicated Sales Tax OSAR*/

	SELECT DISTINCT ReceivableId,ContractId,PaymentStartDate,FunderId 
	INTO #ReceivableInfo
	FROM #ReceivableDetailsTemp WHERE AccountingTreatment = @AccrualBased

	SELECT ReceivableTaxDetails.Id ReceivableTaxDetailId, ReceivableInfo.ContractId,ReceivableInfo.PaymentStartDate,ReceivableInfo.FunderId
	INTO #ReceivableTaxDetails
		FROM #ReceivableInfo AS ReceivableInfo 
		JOIN ReceivableTaxes  With (ForceSeek) ON ReceivableInfo.ReceivableId = ReceivableTaxes.ReceivableId AND ReceivableTaxes.IsActive=1
		JOIN ReceivableTaxDetails With (ForceSeek) ON ReceivableTaxes.Id = ReceivableTaxDetails.ReceivableTaxId 
			AND ReceivableTaxDetails.IsActive =1
			AND ReceivableTaxDetails.IsGLPosted = 1

	INSERT INTO #ReceivableTaxDetails
	SELECT ReceivableTaxDetails.Id, ReceivableInfo.ContractId,ReceivableInfo.PaymentStartDate,ReceivableInfo.FunderId
		FROM #ReceivableInfo AS ReceivableInfo 
		JOIN ReceivableTaxes With (ForceSeek) ON ReceivableInfo.ReceivableId = ReceivableTaxes.ReceivableId AND ReceivableTaxes.IsActive=1
		JOIN ReceivableTaxDetails With (ForceSeek) ON ReceivableTaxes.Id = ReceivableTaxDetails.ReceivableTaxId 
			AND ReceivableTaxDetails.IsActive =1
			AND ReceivableTaxDetails.IsGLPosted = 0 AND ReceivableTaxDetails.Amount_Amount != ReceivableTaxDetails.Balance_Amount

	;WITH CTE_ReceivableSalesTax AS
	(SELECT Contract.ContractId
	,ReceivableTaxDetails.IsGLPosted
	,SUM(CASE WHEN ReceivableInfo.FunderId IS NOT NULL THEN ReceivableTaxDetails.Balance_Amount ELSE 0.00 END) AS SyndicatedSalesTaxOSARAmount
	,SUM(CASE WHEN ReceivableInfo.FunderId IS NULL THEN ReceivableTaxDetails.Balance_Amount ELSE 0.00 END) AS SalesTaxOSARAmount
	,SUM(CASE WHEN ReceivableInfo.FunderId IS NULL THEN ReceivableTaxDetails.Amount_Amount - ReceivableTaxDetails.Balance_Amount ELSE 0.00 END) AS PrepaidSalesTaxAmount
	,SUM(CASE WHEN ReceivableInfo.FunderId IS NOT NULL THEN ReceivableTaxDetails.Amount_Amount - ReceivableTaxDetails.Balance_Amount ELSE 0.00 END ) AS PrepaidSyndicatedSalesTaxOSARAmount
	FROM #BasicDetails Contract
	JOIN #ReceivableTaxDetails AS ReceivableInfo ON Contract.ContractId = ReceivableInfo.ContractId
	JOIN ReceivableTaxDetails With (ForceSeek) ON ReceivableInfo.ReceivableTaxDetailId = ReceivableTaxDetails.Id 
	JOIN LegalEntities LegalEntity ON Contract.LegalEntityId = LegalEntity.Id
	LEFT JOIN #SyndicationDetailsTemp SyndicationDetail ON Contract.ContractId = SyndicationDetail.ContractId
	WHERE @AccrualBased = (CASE WHEN (Contract.IsChargedOff =1 OR (SyndicationDetail.ContractId IS NOT NULL AND ReceivableInfo.PaymentStartDate >= SyndicationDetail.SyndicationEffectiveDate))
	THEN Contract.SalesTaxRemittanceMethod ELSE LegalEntity.TaxRemittancePreference END)
	GROUP BY Contract.ContractId,ReceivableTaxDetails.IsGLPosted
	)

	UPDATE #RNITemp
	SET PrepaidReceivables_Amount = PrepaidReceivables_Amount + ISNULL(PrepaidSalesTaxOSAR.PrepaidSalesTaxAmount,0.00),
	SyndicatedPrepaidReceivables_Amount = SyndicatedPrepaidReceivables_Amount + ISNULL(PrepaidSalesTaxOSAR.PrepaidSyndicatedSalesTaxOSARAmount, 0.00),
	SalesTaxOSAR_Amount = ISNULL(SalesTaxOSAR.SalesTaxOSARAmount,0.00),
	SyndicatedSalesTaxOSAR_Amount = ISNULL(SalesTaxOSAR.SyndicatedSalesTaxOSARAmount,0.00)
	FROM #RNITemp RNI
	LEFT JOIN CTE_ReceivableSalesTax PrepaidSalesTaxOSAR ON RNI.ContractId = PrepaidSalesTaxOSAR.ContractId AND PrepaidSalesTaxOSAR.IsGLPosted = 0
	LEFT JOIN CTE_ReceivableSalesTax SalesTaxOSAR ON RNI.ContractId = SalesTaxOSAR.ContractId AND SalesTaxOSAR.IsGLPosted = 1;
	/*Prepaid Interest*/
	IF EXISTS(SELECT 1 FROM #LoanDetails)
	BEGIN
	;WITH CTE_PrepaidInterest AS
	(SELECT Contract.ContractId
	,SUM(ISNULL(Receivable.Amount_Amount,0) - ISNULL(Receivable.Balance_Amount,0)) AS PrepaidInterestAmount
	FROM #LoanDetails Contract
	JOIN #BasicDetails ContractDateInfo ON Contract.ContractId = ContractDateInfo.ContractId
	JOIN #ReceivableDetailsTemp Receivable ON Contract.ContractId = Receivable.ContractId AND Receivable.ReceivableType = @LoanInterest
	AND Receivable.IsGLPosted = 0 AND Receivable.IsDummy = 0 AND Receivable.FunderId IS NULL
	WHERE (Contract.IsChargedOff = 0 OR Receivable.PaymentStartDate < ContractDateInfo.ChargeOffDate)
	GROUP BY Contract.ContractId)
	UPDATE #RNITemp SET PrepaidInterest_Amount = PrepaidInterest.PrepaidInterestAmount
	FROM #RNITemp RNI
	JOIN CTE_PrepaidInterest PrepaidInterest ON RNI.ContractId = PrepaidInterest.ContractId;
	END
	/*Float Rate Adjustments OSAR*/ -- CE
	;WITH CTE_FloatRateAdjustments AS
	(SELECT Contract.ContractId
	,SUM(Receivable.Balance_Amount) AS FloatRateAdjustmentAmount
	FROM #LeaseDetails Contract
	JOIN #ReceivableDetailsTemp Receivable ON Contract.IsChargedOff = 0 AND Receivable.ContractId = Contract.ContractId AND Receivable.ReceivableType = @LeaseFloatRateAdj
	AND Receivable.IsGLPosted = 1 AND Receivable.FunderId IS NULL
	GROUP BY Contract.ContractId)
	UPDATE #RNITemp SET FloatRateAdjustmentOSAR_Amount = FloatRateAdj.FloatRateAdjustmentAmount
	FROM #RNITemp RNI
	JOIN CTE_FloatRateAdjustments FloatRateAdj ON RNI.ContractId = FloatRateAdj.ContractId;
	/*Syndicated Float Rate Adjustments OSAR*/ -- CE
	IF EXISTS(SELECT 1 FROM #SyndicationDetailsTemp WHERE IsServiced = 1)
	BEGIN
	;WITH CTE_SyndicatedFloatRateAdjustments AS
	(SELECT Contract.ContractId
	,SUM(Receivable.Balance_Amount) AS SyndicatedFloatRateAdjustmentAmount
	FROM #LeaseDetails Contract
	JOIN #SyndicationDetailsTemp SyndicationDetail ON Contract.IsChargedOff = 0 AND Contract.ContractId = SyndicationDetail.ContractId AND SyndicationDetail.IsServiced = 1
	JOIN #ReceivableDetailsTemp Receivable ON Receivable.ContractId = SyndicationDetail.ContractId AND Receivable.ReceivableType = @LeaseFloatRateAdj AND Receivable.FunderId IS NOT NULL
	WHERE ((SyndicationDetail.IsCollected = 1 AND Receivable.IsGLPosted = 1) OR (SyndicationDetail.IsCollected = 0 AND Receivable.DueDate <= @IncomeDate))
	GROUP BY Contract.ContractId)
	UPDATE #RNITemp SET SyndicatedFixedTermReceivablesOSAR_Amount = SyndicatedFixedTermReceivablesOSAR_Amount + OSAR.SyndicatedFloatRateAdjustmentAmount
	FROM #RNITemp RNI
	JOIN CTE_SyndicatedFloatRateAdjustments OSAR ON RNI.ContractId = OSAR.ContractId;
	END
	/*Syndicated Interim Receivables OSAR*/
	IF EXISTS(SELECT 1 FROM #SyndicationDetailsTemp WHERE IsServiced = 1)
	BEGIN
	;WITH CTE_SyndicatedInterimReceivables AS
	(SELECT Receivable.ContractId
	,SUM(Receivable.Balance_Amount) AS SyndicatedInterimReceivableAmount
	FROM #ReceivableDetailsTemp Receivable
	WHERE Receivable.ReceivableType IN (@LeaseInterimInterest, @InterimRental) AND Receivable.FunderId IS NOT NULL AND Receivable.IsGLPosted = 1
	GROUP BY Receivable.ContractId)
	UPDATE #RNITemp SET SyndicatedInterimReceivablesOSAR_Amount = OSAR.SyndicatedInterimReceivableAmount
	FROM #RNITemp RNI
	JOIN CTE_SyndicatedInterimReceivables OSAR ON RNI.ContractId = OSAR.ContractId;
	END
	/*Float Rate Income Balance*//*Suspended Float Rate Income Balance*/
	;WITH CTE_FloatRateIncome AS
	(SELECT Contract.ContractId
	,SUM(CASE WHEN FloatRateIncome.IsNonAccrual = 1 THEN FloatRateIncome.CustomerIncomeAmount_Amount ELSE 0.00 END) AS SuspendedIncome
	,SUM(FloatRateIncome.CustomerIncomeAmount_Amount) AS Income
	FROM #LeaseDetails Contract
	JOIN LeaseFinances Lease ON Contract.ContractId = Lease.ContractId AND Contract.IsChargedOff = 0
	JOIN LeaseFloatRateIncomes FloatRateIncome ON FloatRateIncome.LeaseFinanceId = Lease.Id AND FloatRateIncome.IsAccounting = 1 AND FloatRateIncome.IsGLPosted = 1
	GROUP BY Contract.ContractId)
	UPDATE #RNITemp
	SET FloatRateIncomeBalance_Amount = FloatRateIncome.Income,
	SuspendedFloatRateIncomeBalance_Amount = FloatRateIncome.SuspendedIncome
	FROM #RNITemp RNI
	JOIN CTE_FloatRateIncome FloatRateIncome ON RNI.ContractId = FloatRateIncome.ContractId;
	UPDATE #RNITemp
	SET FloatRateIncomeBalance_Amount = FloatRateIncomeBalance_Amount - FloatRateReceivable.ReceivableAmount
	FROM #RNITemp RNI
	JOIN (SELECT Contract.ContractId
	,SUM(Receivable.Amount_Amount) AS ReceivableAmount
	FROM #LeaseDetails Contract
	JOIN #ReceivableDetailsTemp Receivable ON Receivable.ContractId = Contract.ContractId AND Receivable.ReceivableType = @LeaseFloatRateAdj AND Contract.IsChargedOff = 0
	AND Receivable.IsGLPosted = 1 AND Receivable.FunderId IS NULL
	GROUP BY Contract.ContractId)
	AS FloatRateReceivable ON RNI.ContractId = FloatRateReceivable.ContractId;
	/*Security Deposit OSAR*/
	;WITH CTE_SecurityDepositOSAR AS
	(SELECT Contract.ContractId,
	SUM(Receivable.Balance_Amount) AS SecurityDepositOSARAmount
	FROM #BasicDetails Contract
	JOIN SecurityDeposits SecurityDeposit ON Contract.ContractId = SecurityDeposit.ContractId AND SecurityDeposit.EntityType = @ContractEntityType AND SecurityDeposit.IsActive = 1
	JOIN #ReceivableDetailsTemp Receivable ON SecurityDeposit.ReceivableId = Receivable.ReceivableId AND Receivable.IsGLPosted = 1
	GROUP BY Contract.ContractId)
	UPDATE #RNITemp SET SecurityDepositOSAR_Amount = OSAR.SecurityDepositOSARAmount
	FROM #RNITemp RNI
	JOIN CTE_SecurityDepositOSAR OSAR ON RNI.ContractId = OSAR.ContractId;
	/*Security Deposit*/
	;WITH CTE_SecurityDepositAllocations AS
	(SELECT Contract.ContractId,
	SUM(SDAllocation.Amount_Amount) AS SecurityDepositAllocationAmount
	FROM #BasicDetails Contract
	JOIN SecurityDepositAllocations SDAllocation ON SDAllocation.ContractId = Contract.ContractId AND SDAllocation.IsActive = 1
	JOIN SecurityDeposits SecurityDeposit ON SDAllocation.SecurityDepositId = SecurityDeposit.Id AND SecurityDeposit.IsActive = 1
	GROUP BY Contract.ContractId)
	UPDATE #RNITemp SET SecurityDeposit_Amount = SDAllocation.SecurityDepositAllocationAmount
	FROM #RNITemp RNI
	JOIN CTE_SecurityDepositAllocations SDAllocation ON RNI.ContractId = SDAllocation.ContractId;
	;WITH CTE_SecurityDepositApplications AS
	(SELECT Contract.ContractId,
	SUM(SDApplication.TransferToIncome_Amount) + SUM(SDApplication.TransferToReceipt_Amount) AS SecurityDepositApplicationAmount
	FROM #BasicDetails Contract
	JOIN SecurityDepositApplications SDApplication ON SDApplication.ContractId = Contract.ContractId AND SDApplication.IsActive = 1
	JOIN SecurityDeposits SecurityDeposit ON SDApplication.SecurityDepositId = SecurityDeposit.Id AND SecurityDeposit.IsActive = 1
	GROUP BY Contract.ContractId)
	UPDATE #RNITemp SET SecurityDeposit_Amount = SecurityDeposit_Amount - SDApplication.SecurityDepositApplicationAmount
	FROM #RNITemp RNI
	JOIN CTE_SecurityDepositApplications SDApplication ON RNI.ContractId = SDApplication.ContractId;

	;WITH CTE_LoanBIReAccrualAdjInfo AS
	(SELECT Contract.ContractId ,SUM(BIDetail.Amount_Amount) AS ReAccrualAdjIncomeAmount
	FROM #LoanDetails Contract
	JOIN LoanBlendedItems LoanBlendedItem ON Contract.LoanFinanceId = LoanBlendedItem.LoanFinanceId 
	JOIN BlendedItems BlendedItem ON LoanBlendedItem.BlendedItemId = BlendedItem.Id AND BlendedItem.SystemConfigType = @ReAccrualIncome
	AND BlendedItem.BookRecognitionMode = @RecognizeImmediately AND BlendedItem.IsActive = 1
	JOIN BlendedItemDetails BIDetail ON BlendedItem.Id = BIDetail.BlendedItemId AND BIDetail.IsGLPosted = 1
	GROUP BY Contract.ContractId)
	UPDATE #RNITemp
	SET IncomeAccrualBalance_Amount = IncomeAccrualBalance_Amount + BIReAccrualAdj.ReAccrualAdjIncomeAmount
	FROM #RNITemp RNI
	JOIN CTE_LoanBIReAccrualAdjInfo BIReAccrualAdj ON RNI.ContractId = BIReAccrualAdj.ContractId;

	/* ReAccrual Blended Adjustment*/
	IF EXISTS(SELECT 1 FROM #BlendedItemTemp WHERE IsReaccrualBlendedItem = 1)
	BEGIN
	/*Income Adjustment*/
	;WITH CTE_BIIncomeInfo AS
	(SELECT BIIncomeSched.ContractId
	,SUM(CASE WHEN BIIncomeSched.SystemConfigType IN (@ReAccrualIncome,@ReAccrualResidualIncome) THEN BIIncomeSched.IncomeAmount ELSE 0.00 END) AS ReAccrualAdjIncomeAmount
	,SUM(CASE WHEN BIIncomeSched.SystemConfigType IN (@ReAccrualFinanceIncome,@ReAccrualFinanceResidualIncome) THEN BIIncomeSched.IncomeAmount ELSE 0.00 END) AS ReAccrualAdjFinanceIncomeAmount
	,SUM(CASE WHEN Contract.LeaseContractType = @DirectFinanceContractSubType AND BIIncomeSched.SystemConfigType = @ReAccrualDeferredSellingProfitIncome THEN BIIncomeSched.IncomeAmount ELSE 0.00 END) AS DSPReAccrualAdjIncomeAmount
	,SUM(CASE WHEN Contract.LeaseContractType = @OperatingContractSubType AND BIIncomeSched.SystemConfigType = @ReAccrualRentalIncome THEN BIIncomeSched.IncomeAmount ELSE 0.00 END) AS DeferredOperatingReAccrualAdjIncomeAmount
	FROM #LeaseDetails Contract
	JOIN #BlendedItemTemp BIIncomeSched ON Contract.ContractId = BIIncomeSched.ContractId
	AND BIIncomeSched.IsReaccrualBlendedItem=1
	GROUP BY BIIncomeSched.ContractId)
	UPDATE #RNITemp SET IncomeAccrualBalance_Amount = CASE WHEN (ContractInfo.IsChargedOff <> 0) THEN IncomeAccrualBalance_Amount + BIIncome.ReAccrualAdjIncomeAmount ELSE IncomeAccrualBalance_Amount END,
	FinanceIncomeAccrualBalance_Amount = FinanceIncomeAccrualBalance_Amount + BIIncome.ReAccrualAdjFinanceIncomeAmount,
	DeferredSellingProfit_Amount = DeferredSellingProfit_Amount + BIIncome.DSPReAccrualAdjIncomeAmount,
	DeferredOperatingIncome_Amount = DeferredOperatingIncome_Amount - BIIncome.DeferredOperatingReAccrualAdjIncomeAmount
	FROM #RNITemp RNI
	JOIN CTE_BIIncomeInfo BIIncome ON RNI.ContractId = BIIncome.ContractId
	JOIN #BasicDetails ContractInfo ON RNI.ContractId = ContractInfo.ContractId ;

	/* Income Adjustment for Loan */
	;WITH CTE_LoanBIReAccrualAdjInfo AS
	(SELECT BlendedItem.ContractId ,SUM(IncomeSched.Income_Amount) AS ReAccrualAdjIncomeAmount
	FROM #LoanDetails Contract
	JOIN #BlendedItemTemp BlendedItem ON Contract.ContractId = BlendedItem.ContractId
	AND BlendedItem.IsReaccrualBlendedItem=1 AND BlendedItem.SystemConfigType = @ReAccrualIncome
	JOIN BlendedIncomeSchedules IncomeSched ON BlendedItem.BlendedItemId = IncomeSched.BlendedItemId AND
	IncomeSched.IsAccounting = 1 AND IncomeSched.PostDate IS NOT NULL
	GROUP BY BlendedItem.ContractId)
	UPDATE #RNITemp SET IncomeAccrualBalance_Amount = IncomeAccrualBalance_Amount + BIIncome.ReAccrualAdjIncomeAmount 
	FROM #RNITemp RNI
	JOIN CTE_LoanBIReAccrualAdjInfo BIIncome ON RNI.ContractId = BIIncome.ContractId;

	/*Suspended Adjustment*/
	;WITH CTE_BISuspendedLeaseIncomeInfo AS
	(SELECT BIIncomeSched.ContractId
	,SUM(CASE WHEN BIIncomeSched.SystemConfigType IN (@ReAccrualIncome,@ReAccrualResidualIncome,@ReAccrualRentalIncome) THEN BIIncomeSched.SuspendedIncomeAmount ELSE 0.00 END) AS SuspendedReAccrualAdjIncomeAmount
	,SUM(CASE WHEN BIIncomeSched.SystemConfigType IN (@ReAccrualFinanceIncome,@ReAccrualFinanceResidualIncome) THEN BIIncomeSched.SuspendedIncomeAmount ELSE 0.00 END) AS SuspendedFinanceReAccrualAdjIncomeAmount
	,SUM(CASE WHEN Contract.LeaseContractType = @DirectFinanceContractSubType AND BIIncomeSched.SystemConfigType = @ReAccrualDeferredSellingProfitIncome THEN BIIncomeSched.SuspendedIncomeAmount ELSE 0.00 END) AS SuspendedDSPReAccrualAdjIncomeAmount
	FROM  #LeaseDetails Contract
	JOIN #BlendedItemTemp BIIncomeSched ON Contract.IsChargedOff = 0 AND Contract.ContractId = BIIncomeSched.ContractId AND BIIncomeSched.IsReaccrualBlendedItem = 1
	GROUP BY BIIncomeSched.ContractId)
	UPDATE #RNITemp SET SuspendedIncomeAccrualBalance_Amount = SuspendedIncomeAccrualBalance_Amount + BISuspendedLeaseIncomeInfo.SuspendedReAccrualAdjIncomeAmount,
	SuspendedFinanceIncomeAccrualBalance_Amount = SuspendedFinanceIncomeAccrualBalance_Amount + BISuspendedLeaseIncomeInfo.SuspendedFinanceReAccrualAdjIncomeAmount,
	SuspendedDeferredSellingProfit_Amount = SuspendedDeferredSellingProfit_Amount + BISuspendedLeaseIncomeInfo.SuspendedDSPReAccrualAdjIncomeAmount
	FROM #RNITemp RNI
	JOIN CTE_BISuspendedLeaseIncomeInfo BISuspendedLeaseIncomeInfo ON RNI.ContractId = BISuspendedLeaseIncomeInfo.ContractId;
	END
	IF EXISTS(SELECT 1 FROM #LeaseDetails WHERE LeaseContractType = @OperatingContractSubType)
	BEGIN
	;WITH CTE_BIReAccrualAdjInfo AS
	(SELECT Contract.ContractId
	,SUM(BIDetail.Amount_Amount) AS DeferredOperatingReAccrualAdjBIAmount
	FROM #LeaseDetails Contract
	JOIN LeaseBlendedItems LeaseBlendedItem ON Contract.LeaseFinanceId = LeaseBlendedItem.LeaseFinanceId AND Contract.LeaseContractType = @OperatingContractSubType
	JOIN BlendedItems BlendedItem ON LeaseBlendedItem.BlendedItemId = BlendedItem.Id AND BlendedItem.SystemConfigType = @ReAccrualRentalIncome
	AND BlendedItem.BookRecognitionMode = @RecognizeImmediately AND BlendedItem.IsActive = 1
	JOIN BlendedItemDetails BIDetail ON BlendedItem.Id = BIDetail.BlendedItemId AND BIDetail.IsGLPosted = 1
	LEFT JOIN #SyndicationDetailsTemp SyndicationDetail ON Contract.ContractId = SyndicationDetail.ContractId
	WHERE (SyndicationDetail.SyndicationId IS NULL OR SyndicationDetail.RetainedPercentage > 0.0 OR SyndicationDetail.ReceivableForTransferType = @SaleOfPaymentsType)
	GROUP BY Contract.ContractId)
	UPDATE #RNITemp
	SET DeferredOperatingIncome_Amount = DeferredOperatingIncome_Amount - BIReAccrualAdj.DeferredOperatingReAccrualAdjBIAmount
	FROM #RNITemp RNI
	JOIN CTE_BIReAccrualAdjInfo BIReAccrualAdj ON RNI.ContractId = BIReAccrualAdj.ContractId
	JOIN #BasicDetails ContractInfo ON RNI.ContractId = ContractInfo.ContractId AND ContractInfo.IsChargedOff = 0;
	END
	/* ReAccrual Blended Adjustment Ends*/
	/*RNI Amount*/
	/*Leveraged Lease*/
	UPDATE #RNITemp SET RNIAmount_Amount = RNIAmount_Amount
	+ CapitalLeaseContractReceivable_Amount
	+ UnguaranteedResidual_Amount
	+ IDCBalance_Amount
	- UnearnedRentalIncome_Amount
	+ RNI.CapitalLeaseRentOSAR_Amount
	- RNI.PrepaidReceivables_Amount
	- RNI.UnappliedCash_Amount
	FROM #RNITemp RNI
	JOIN #LeveragedLeaseDetails LeveragedLease ON RNI.ContractId = LeveragedLease.ContractId;
	/*Commenced Non DSL Loan*/
	UPDATE #RNITemp SET RNIAmount_Amount = RNIAmount_Amount
	+ PrincipalBalance_Amount
	+ IncomeAccrualBalance_Amount
	+ LoanPrincipleOSAR_Amount
	+ LoanInterestOSAR_Amount
	+ InterimInterestOSAR_Amount
	- PrepaidReceivables_Amount
	- PrepaidInterest_Amount
	- SuspendedIncomeAccrualBalance_Amount
	+ SecurityDepositOSAR_Amount
	- UnappliedCash_Amount
	- NetWritedowns_Amount
	- SecurityDeposit_Amount
	+ IDCBalance_Amount
	+ SuspendedIDCBalance_Amount
	+ FAS91ExpenseBalance_Amount
	+ SuspendedFAS91ExpenseBalance_Amount
	- FAS91IncomeBalance_Amount
	- SuspendedFAS91IncomeBalance_Amount
	- HeldForSaleValuationAllowance_Amount
	+ SalesTaxOSAR_Amount
	FROM #RNITemp RNI
	JOIN #LoanDetails Loan ON RNI.ContractId = Loan.ContractId AND Loan.IsDSL = 0
	AND Loan.Status IN(@CommencedStatus,@FullyPaidOff);
	/*Pending Loan and Progress Loan*/
	UPDATE #RNITemp SET RNIAmount_Amount = RNIAmount_Amount
	+ TotalFinancedAmount_Amount
	+ IncomeAccrualBalance_Amount
	+ InterimInterestOSAR_Amount
	- PrepaidInterest_Amount
	+ SecurityDepositOSAR_Amount
	- UnappliedCash_Amount
	- SecurityDeposit_Amount
	+ SalesTaxOSAR_Amount
	FROM #RNITemp RNI
	JOIN #LoanDetails Loan ON RNI.ContractId = Loan.ContractId
	WHERE ((Loan.IsProgressLoan = 0 AND Loan.Status = @UnCommencedStatus)
	OR (Loan.IsProgressLoan = 1 AND Loan.Status IN (@UnCommencedStatus,@FullyPaid)));
	/*DSL Commenced Loan*/
	UPDATE #RNITemp SET RNIAmount_Amount = RNIAmount_Amount
	+ PrincipalBalance_Amount
	+ IncomeAccrualBalance_Amount
	- SuspendedIncomeAccrualBalance_Amount
	+ SecurityDepositOSAR_Amount
	- UnappliedCash_Amount
	- NetWritedowns_Amount
	- SecurityDeposit_Amount
	+ IDCBalance_Amount
	+ SuspendedIDCBalance_Amount
	+ FAS91ExpenseBalance_Amount
	+ SuspendedFAS91ExpenseBalance_Amount
	- FAS91IncomeBalance_Amount
	- SuspendedFAS91IncomeBalance_Amount
	- HeldForSaleValuationAllowance_Amount
	+ SalesTaxOSAR_Amount
	FROM #RNITemp RNI
	JOIN #LoanDetails Loan ON RNI.ContractId = Loan.ContractId AND Loan.IsDSL = 1
	WHERE Loan.Status IN(@CommencedStatus,'FullyPaidOff')
	/*Commenced Operating Lease*/
	UPDATE #RNITemp SET RNIAmount_Amount = RNIAmount_Amount
	+ OperatingLeaseAssetGrossCost_Amount
	- AccumulatedDepreciation_Amount
	+ OperatingLeaseRentOSAR_Amount
	+ InterimInterestOSAR_Amount
	+ InterimRentOSAR_Amount
	+ OverTermRentOSAR_Amount
	+ SalesTaxOSAR_Amount
	- DeferredOperatingIncome_Amount
	- PrepaidReceivables_Amount
	- SuspendedIncomeAccrualBalance_Amount
	- DeferredExtensionIncome_Amount
	- AccumulatedNBVImpairment_Amount
	+ SecurityDepositOSAR_Amount
	- SecurityDeposit_Amount
	- UnappliedCash_Amount
	- DelayedFundingPayables_Amount
	+ FloatRateAdjustmentOSAR_Amount
	+ FloatRateIncomeBalance_Amount
	- SuspendedFloatRateIncomeBalance_Amount
	+ IDCBalance_Amount
	+ SuspendedIDCBalance_Amount
	+ FAS91ExpenseBalance_Amount
	+ SuspendedFAS91ExpenseBalance_Amount
	- FAS91IncomeBalance_Amount
	- SuspendedFAS91IncomeBalance_Amount
	- HeldForSaleValuationAllowance_Amount
	+ VendorSubsidyOSAR_Amount
	+ DelayedVendorSubsidy_Amount
	- FinanceIncomeAccrualBalance_Amount
	- SuspendedFinanceIncomeAccrualBalance_Amount
	+ FinancingContractReceivable_Amount
	+ FinancingRentOSAR_Amount
	+ FinanceUnguaranteedResidual_Amount
	+ FinanceCustomerGuaranteedResidual_Amount
	+ FinanceThirdPartyGauranteedResidual_Amount
	- NetWritedowns_Amount
	- FinanceNetWritedowns_Amount
	FROM #RNITemp RNI
	JOIN #LeaseDetails Lease ON RNI.ContractId = Lease.ContractId AND Lease.LeaseContractType = @OperatingContractSubType
	AND Lease.BookingStatus IN(@CommencedStatus,@FullyPaidOff);
	/*Uncommenced Lease*/
	UPDATE #RNITemp SET RNIAmount_Amount = RNIAmount_Amount
	+ TotalFinancedAmount_Amount
	+ InterimInterestOSAR_Amount
	+ InterimRentOSAR_Amount
	+ SecurityDepositOSAR_Amount
	+ SalesTaxOSAR_Amount
	- SecurityDeposit_Amount
	- UnappliedCash_Amount
	FROM #RNITemp RNI
	JOIN #LeaseDetails Lease ON RNI.ContractId = Lease.ContractId
	AND Lease.BookingStatus IN (@UnCommencedStatus, @Pending, @InstallingAssets) ;
	/*Commenced Direct Finance Lease*/
	UPDATE #RNITemp SET RNIAmount_Amount = RNIAmount_Amount
	+ CapitalLeaseContractReceivable_Amount
	+ CapitalLeaseRentOSAR_Amount
	+ InterimInterestOSAR_Amount
	+ InterimRentOSAR_Amount
	+ OverTermRentOSAR_Amount
	+ FloatRateAdjustmentOSAR_Amount
	+ SalesTaxOSAR_Amount
	- PrepaidReceivables_Amount
	+ UnguaranteedResidual_Amount
	+ CustomerGuaranteedResidual_Amount
	+ ThirdPartyGauranteedResidual_Amount
	- IncomeAccrualBalance_Amount
	- SuspendedIncomeAccrualBalance_Amount
	- DeferredExtensionIncome_Amount
	- OTPResidualRecapture_Amount
	- AccumulatedDepreciation_Amount --when GP AccumulateDepreciationForCapitalLeases is true
	+ SecurityDepositOSAR_Amount
	- SecurityDeposit_Amount
	- UnappliedCash_Amount
	- NetWritedowns_Amount
	- DelayedFundingPayables_Amount
	+ FloatRateIncomeBalance_Amount
	- SuspendedFloatRateIncomeBalance_Amount
	+ IDCBalance_Amount
	+ SuspendedIDCBalance_Amount
	+ FAS91ExpenseBalance_Amount
	+ SuspendedFAS91ExpenseBalance_Amount
	- FAS91IncomeBalance_Amount
	- SuspendedFAS91IncomeBalance_Amount
	- HeldForSaleValuationAllowance_Amount
	+ VendorSubsidyOSAR_Amount
	+ DelayedVendorSubsidy_Amount
	- AccumulatedNBVImpairment_Amount
	- FinanceIncomeAccrualBalance_Amount
	- SuspendedFinanceIncomeAccrualBalance_Amount
	- DeferredSellingProfit_Amount
	- SuspendedDeferredSellingProfit_Amount
	+ FinancingContractReceivable_Amount
	+ FinancingRentOSAR_Amount
	+ FinanceUnguaranteedResidual_Amount
	+ FinanceCustomerGuaranteedResidual_Amount
	+ FinanceThirdPartyGauranteedResidual_Amount
	- FinanceNetWritedowns_Amount
	FROM #RNITemp RNI
	JOIN #LeaseDetails Lease ON RNI.ContractId = Lease.ContractId
	AND Lease.BookingStatus IN(@CommencedStatus,@FullyPaidOff)
	AND Lease.LeaseContractType  <> @OperatingContractSubType;
	/*Serviced RNI Amount*/
		UPDATE #RNITemp SET ServicedRNIAmount_Amount = ServicedRNIAmount_Amount 
												+ RNI.PrincipalBalanceFunderPortion_Amount
												- RNI.IncomeAccrualBalanceFunderPortion_Amount
												+ ((RNI.PrincipalBalanceAdjustment_Amount + RNI.DeferredOperatingIncome_Amount)/ 
													(CASE WHEN Syndication.RetainedPercentage != 0 
														THEN (Syndication.RetainedPercentage/100) * (1 - (Syndication.RetainedPercentage/100)) ELSE 1 END))
												+ RNI.SyndicatedFixedTermReceivablesOSAR_Amount
												+ RNI.SyndicatedInterimReceivablesOSAR_Amount
												+ RNI.SalesTaxOSAR_Amount
												- RNI.SyndicatedPrepaidReceivables_Amount
												+ RNI.SyndicatedCapitalLeaseContractReceivable_Amount
												+ RNI.SyndicatedFinancingContractReceivable_Amount
												+ RNI.FinanceSyndicatedFixedTermReceivablesOSAR_Amount
		FROM #RNITemp RNI
		JOIN #BasicDetails Contract ON RNI.ContractId = Contract.ContractId
		JOIN #SyndicationDetailsTemp Syndication ON Contract.ContractId = Syndication.ContractId;

				INSERT INTO #tempRemainingNetInvestments
					(IncomeDate,
					ContractType,
					SubType,
					IsOTP,
					IsInNonAccrual,
					NonAccrualDate,
					IsActive,
					Status,
					HoldingStatus,
					RetainedPercentage,
					IsPaymentStreamSold,
					RNIAmount_Amount,
					RNIAmount_Currency,
					ServicedRNIAmount,
					PrincipalBalance,
					DelayedFundingPayables,
					LoanPrincipleOSAR,
					LoanInterestOSAR,
					InterimInterestOSAR,
					IncomeAccrualBalance,
					SuspendedIncomeAccrualBalance,
					ProgressFundings,
					ProgressPaymentCredits,
					TotalFinancedAmount,
					TotalFinancedAmountLOC,
					UnappliedCash,
					GrossWritedowns,
					NetWritedowns,
					IDCBalance,
					SuspendedIDCBalance,
					FAS91ExpenseBalance,
					FAS91IncomeBalance,
					SuspendedFAS91ExpenseBalance,
					SuspendedFAS91IncomeBalance,
					OperatingLeaseAssetGrossCost,
					AccumulatedDepreciation,
					OperatingLeaseRentOSAR,
					InterimRentOSAR,
					DeferredOperatingIncome,
					DeferredExtensionIncome,
					CapitalLeaseContractReceivable,
					UnguaranteedResidual,
					CustomerGuaranteedResidual,
					ThirdPartyGauranteedResidual,
					CapitalLeaseRentOSAR,
					OverTermRentOSAR,
					UnearnedRentalIncome,
					OTPResidualRecapture,
					PrepaidReceivables,
					SyndicatedPrepaidReceivables,
					AccumulatedNBVImpairment,
					FloatRateAdjustmentOSAR,
					FloatRateIncomeBalance,
					SuspendedFloatRateIncomeBalance,
					HeldForSaleValuationAllowance,
					HeldForSaleBalance,
					SyndicatedFixedTermReceivablesOSAR,
					SyndicatedInterimReceivablesOSAR,
					SecurityDeposit,
					SecurityDepositOSAR,
					VendorSubsidyOSAR,
					DelayedVendorSubsidy,
					SalesTaxOSAR,
					SyndicatedSalesTaxOSAR,
					PrincipalBalanceAdjustment,
					ContractId,
					InstrumentTypeId,
					CreditProfileId,
					CurrencyId,
					SyndicatedCapitalLeaseContractReceivable,
					IncomeAccrualBalanceFunderPortion,
					PrincipalBalanceFunderPortion,
					PrepaidInterest,
					AccountingStandard,
					FinanceIncomeAccrualBalance,
					SuspendedFinanceIncomeAccrualBalance,
					SyndicatedFinanceIncomeAccrualBalance,
					DeferredSellingProfit,
					SuspendedDeferredSellingProfit,
					FinanceGrossWritedowns,
					FinanceNetWritedowns,
					FinancingContractReceivable,
					SyndicatedFinancingContractReceivable,
					FinanceUnguaranteedResidual,
					FinanceCustomerGuaranteedResidual,
					FinanceThirdPartyGauranteedResidual,
					FinancingRentOSAR,
					FinanceSyndicatedFixedTermReceivablesOSAR,
					BackgroundProcessingPending
)
				SELECT 
				@IncomeDate IncomeDate
				,Contract.ContractType
				,(CASE WHEN Contract.ContractType = @Lease THEN ContractDetails.LeaseContractType ELSE (CASE WHEN Contract.ContractType = @LoanContractType THEN 
					(CASE WHEN ContractDetails.IsDSL = 1 THEN @DSL ELSE @NonDSL END) ELSE 
						(CASE WHEN Contract.ContractType != @ProgressLoanContractType THEN @LeveragedLease ELSE @Unknown END)  END) END) AS SubType
				,ContractDetails.IsInOTP 
				,Contract.IsNonAccrual
				,Contract.NonAccrualDate
				,1 IsActive
				,Contract.Status
				,(CASE WHEN ContractDetails.HoldingStatus IN (@HFS,@OriginatedHFS) THEN @HFS ELSE ContractDetails.HoldingStatus END) AS HoldingStatus
				,(CASE WHEN Syndication.ContractId IS NOT NULL THEN Syndication.RetainedPercentage ELSE 100 END) AS RetainedPercentage
				,(CASE WHEN Syndication.ContractId IS NOT NULL AND Syndication.ReceivableForTransferType = @SaleOfPaymentsType THEN 1 ELSE 0 END) AS IsPaymentStreamSold
				, RNI.RNIAmount_Amount 
				,CurrencyCode.ISO [RNIAmount_Currency]
				,RNI.ServicedRNIAmount_Amount
				,RNI.PrincipalBalance_Amount 			
				,RNI.DelayedFundingPayables_Amount 
				,RNI.LoanPrincipleOSAR_Amount 
				,RNI.LoanInterestOSAR_Amount 
				,RNI.InterimInterestOSAR_Amount
				,RNI.IncomeAccrualBalance_Amount 
				,RNI.SuspendedIncomeAccrualBalance_Amount 
				,RNI.ProgressFundings_Amount 
				,RNI.ProgressPaymentCredits_Amount
				,RNI.TotalFinancedAmount_Amount 
				,RNI.TotalFinancedAmountLOC_Amount
				,RNI.UnappliedCash_Amount
				,RNI.GrossWritedowns_Amount 
				,RNI.NetWritedowns_Amount 
				,RNI.IDCBalance_Amount 
				,RNI.SuspendedIDCBalance_Amount 
				,RNI.FAS91ExpenseBalance_Amount 
				,RNI.FAS91IncomeBalance_Amount 
				,RNI.SuspendedFAS91ExpenseBalance_Amount 
				,RNI.SuspendedFAS91IncomeBalance_Amount 
				,RNI.OperatingLeaseAssetGrossCost_Amount 
				,RNI.AccumulatedDepreciation_Amount
				,RNI.OperatingLeaseRentOSAR_Amount 
				,RNI.InterimRentOSAR_Amount 
				,RNI.DeferredOperatingIncome_Amount
				,RNI.DeferredExtensionIncome_Amount 
				,RNI.CapitalLeaseContractReceivable_Amount 
				,RNI.UnguaranteedResidual_Amount 
				,RNI.CustomerGuaranteedResidual_Amount 
				,RNI.ThirdPartyGauranteedResidual_Amount 
				,RNI.CapitalLeaseRentOSAR_Amount 
				,RNI.OverTermRentOSAR_Amount 
				,RNI.UnearnedRentalIncome_Amount 
				,RNI.OTPResidualRecapture_Amount [OTPResidualRecapture_Amount]
				,RNI.PrepaidReceivables_Amount [PrepaidReceivables_Amount]
				,RNI.SyndicatedPrepaidReceivables_Amount 
				,RNI.AccumulatedNBVImpairment_Amount 
				,RNI.FloatRateAdjustmentOSAR_Amount 
				,RNI.FloatRateIncomeBalance_Amount 
				,RNI.SuspendedFloatRateIncomeBalance_Amount 
				,(CASE WHEN ContractDetails.HoldingStatus IN (@HFS,@OriginatedHFS) THEN RNI.HeldForSaleValuationAllowance_Amount ELSE 0.00 END) AS ValuationAllowance
				,(CASE WHEN ContractDetails.HoldingStatus IN (@HFS,@OriginatedHFS) THEN RNI.RNIAmount_Amount + RNI.HeldForSaleValuationAllowance_Amount ELSE 0.00 END) AS HeldForSaleAllowance
				,RNI.SyndicatedFixedTermReceivablesOSAR_Amount 
				,RNI.SyndicatedInterimReceivablesOSAR_Amount
				,RNI.SecurityDeposit_Amount 
				,RNI.SecurityDepositOSAR_Amount 
				,RNI.VendorSubsidyOSAR_Amount 
				,RNI.DelayedVendorSubsidy_Amount 
				,RNI.SalesTaxOSAR_Amount 
				,RNI.SyndicatedSalesTaxOSAR_Amount 
				,RNI.PrincipalBalanceAdjustment_Amount 
				,RNI.ContractId
				,ContractDetails.InstrumentTypeId
				,CreditApprovedStructure.CreditProfileId
				,Contract.CurrencyId
				,RNI.SyndicatedCapitalLeaseContractReceivable_Amount 
				,RNI.IncomeAccrualBalanceFunderPortion_Amount 
				,RNI.PrincipalBalanceFunderPortion_Amount 			
				,RNI.PrepaidInterest_Amount 
				,Contract.AccountingStandard
				,RNI.FinanceIncomeAccrualBalance_Amount 
				,RNI.SuspendedFinanceIncomeAccrualBalance_Amount 
				,RNI.SyndicatedFinanceIncomeAccrualBalance_Amount 
				,RNI.DeferredSellingProfit_Amount 
				,RNI.SuspendedDeferredSellingProfit_Amount 
				,RNI.FinanceGrossWritedowns_Amount 
				,RNI.FinanceNetWritedowns_Amount 
				,RNI.FinancingContractReceivable_Amount 
				,SyndicatedFinancingContractReceivable_Amount 
				,RNI.FinanceUnguaranteedResidual_Amount 
				,RNI.FinanceCustomerGuaranteedResidual_Amount 
				,RNI.FinanceThirdPartyGauranteedResidual_Amount 
				,RNI.FinancingRentOSAR_Amount 
				,RNI.FinanceSyndicatedFixedTermReceivablesOSAR_Amount 
				,Contract.BackgroundProcessingPending
			FROM #RNITemp RNI 
			JOIN (SELECT ContractId,HoldingStatus,InstrumentTypeId,LeaseContractType,IsInOTP,CAST(0 AS BIT) AS IsDSL FROM #LeaseDetails
				  UNION
				  SELECT ContractId,HoldingStatus,InstrumentTypeId,@Unknown AS LeaseContractType,CAST(0 AS BIT) AS IsInOTP,IsDSL FROM #LoanDetails
				  UNION
				  SELECT ContractId,HoldingStatus,InstrumentTypeId,@Unknown AS LeaseContractType,CAST(0 AS BIT) AS IsInOTP,CAST(0 AS BIT) AS IsDSL FROM #LeveragedLeaseDetails)
			ContractDetails ON RNI.ContractId = ContractDetails.ContractId
			JOIN Contracts Contract ON RNI.ContractId = Contract.Id
			JOIN Currencies Currency ON Contract.CurrencyId = Currency.Id
			JOIN CurrencyCodes CurrencyCode ON Currency.CurrencyCodeId = CurrencyCode.Id
			LEFT JOIN CreditApprovedStructures CreditApprovedStructure ON Contract.CreditApprovedStructureId = CreditApprovedStructure.Id AND CreditApprovedStructure.IsActive = 1
			LEFT JOIN #SyndicationDetailsTemp Syndication ON RNI.ContractId = Syndication.ContractId
			ORDER BY RNI.ContractId;	

			SELECT 
					IncomeDate,
					ContractType,
					SubType,
					IsOTP,
					IsInNonAccrual,
					NonAccrualDate,
					IsActive,
					Status,
					HoldingStatus,
					RetainedPercentage,
					IsPaymentStreamSold,
					RNIAmount_Amount,
					RNIAmount_Currency,
					ServicedRNIAmount,
					PrincipalBalance,
					DelayedFundingPayables,
					LoanPrincipleOSAR,
					LoanInterestOSAR,
					InterimInterestOSAR,
					IncomeAccrualBalance,
					SuspendedIncomeAccrualBalance,
					ProgressFundings,
					ProgressPaymentCredits,
					TotalFinancedAmount,
					TotalFinancedAmountLOC,
					UnappliedCash,
					GrossWritedowns,
					NetWritedowns,
					IDCBalance,
					SuspendedIDCBalance,
					FAS91ExpenseBalance,
					FAS91IncomeBalance,
					SuspendedFAS91ExpenseBalance,
					SuspendedFAS91IncomeBalance,
					OperatingLeaseAssetGrossCost,
					AccumulatedDepreciation,
					OperatingLeaseRentOSAR,
					InterimRentOSAR,
					DeferredOperatingIncome,
					DeferredExtensionIncome,
					CapitalLeaseContractReceivable,
					UnguaranteedResidual,
					CustomerGuaranteedResidual,
					ThirdPartyGauranteedResidual,
					CapitalLeaseRentOSAR,
					OverTermRentOSAR,
					UnearnedRentalIncome,
					OTPResidualRecapture,
					PrepaidReceivables,
					SyndicatedPrepaidReceivables,
					AccumulatedNBVImpairment,
					FloatRateAdjustmentOSAR,
					FloatRateIncomeBalance,
					SuspendedFloatRateIncomeBalance,
					HeldForSaleValuationAllowance,
					HeldForSaleBalance,
					SyndicatedFixedTermReceivablesOSAR,
					SyndicatedInterimReceivablesOSAR,
					SecurityDeposit,
					SecurityDepositOSAR,
					VendorSubsidyOSAR,
					DelayedVendorSubsidy,
					SalesTaxOSAR,
					SyndicatedSalesTaxOSAR,
					PrincipalBalanceAdjustment,
					ContractId,
					InstrumentTypeId,
					CreditProfileId,
					CurrencyId,
					SyndicatedCapitalLeaseContractReceivable,
					IncomeAccrualBalanceFunderPortion,
					PrincipalBalanceFunderPortion,
					PrepaidInterest,
					AccountingStandard,
					FinanceIncomeAccrualBalance,
					SuspendedFinanceIncomeAccrualBalance,
					SyndicatedFinanceIncomeAccrualBalance,
					DeferredSellingProfit,
					SuspendedDeferredSellingProfit,
					FinanceGrossWritedowns,
					FinanceNetWritedowns,
					FinancingContractReceivable,
					SyndicatedFinancingContractReceivable,
					FinanceUnguaranteedResidual,
					FinanceCustomerGuaranteedResidual,
					FinanceThirdPartyGauranteedResidual,
					FinancingRentOSAR,
					FinanceSyndicatedFixedTermReceivablesOSAR,
					BackgroundProcessingPending
			FROM #tempRemainingNetInvestments;

			select Id from #tempRemainingNetInvestmentsIds;

			END

	IF OBJECT_ID('tempdb..#BasicDetails') IS NOT NULL
	DROP TABLE #BasicDetails
	IF OBJECT_ID('tempdb..#RNITemp') IS NOT NULL
	DROP TABLE #RNITemp
	IF OBJECT_ID('tempdb..#SyndicationDetailsTemp') IS NOT NULL
	DROP TABLE #SyndicationDetailsTemp
	IF OBJECT_ID('tempdb..#LeaseIncomeScheduleTemp') IS NOT NULL
	DROP TABLE #LeaseIncomeScheduleTemp
	IF OBJECT_ID('tempdb..#LoanIncomeScheduleTemp') IS NOT NULL
	DROP TABLE #LoanIncomeScheduleTemp
	IF OBJECT_ID('tempdb..#BlendedItemTemp') IS NOT NULL
	DROP TABLE #BlendedItemTemp
	IF OBJECT_ID('tempdb..#ReceivableDetailsTemp') IS NOT NULL
	DROP TABLE #ReceivableDetailsTemp
	IF OBJECT_ID('tempdb..#LoanFinanceBasicTemp') IS NOT NULL
	DROP TABLE #LoanFinanceBasicTemp
	IF OBJECT_ID('tempdb..#AssetTemp') IS NOT NULL
	DROP TABLE #AssetTemp
	IF OBJECT_ID('tempdb..#LoanPaydownTemp') IS NOT NULL
	DROP TABLE #LoanPaydownTemp
	IF OBJECT_ID('tempdb..#FutureScheduledFundedTemp') IS NOT NULL
	DROP TABLE #FutureScheduledFundedTemp
	IF OBJECT_ID('tempdb..#WriteDownDetailsTemp') IS NOT NULL
	DROP TABLE #WriteDownDetailsTemp
	IF OBJECT_ID('tempdb..#LeaseDetails') IS NOT NULL
	DROP TABLE #LeaseDetails
	IF OBJECT_ID('tempdb..#LoanDetails') IS NOT NULL
	DROP TABLE #LoanDetails
	IF OBJECT_ID('tempdb..#LeveragedLeaseDetails') IS NOT NULL
	DROP TABLE #LeveragedLeaseDetails
	IF OBJECT_ID('tempdb..#SuspendedIncomeInfoForDoubtfulCollectability') IS NOT NULL
	drop table #SuspendedIncomeInfoForDoubtfulCollectability
	IF OBJECT_ID('tempdb..#DistinctAssetInfo') IS NOT NULL
	drop table #DistinctAssetInfo
	IF OBJECT_ID('tempdb..#DeferredInterimRentInfoTemp') IS NOT NULL  
	drop table #DeferredInterimRentInfoTemp 
	IF OBJECT_ID('tempdb..#Receivables') IS NOT NULL
	DROP TABLE #Receivables
	IF OBJECT_ID('tempdb..#ReceivableDetails') IS NOT NULL
	DROP TABLE #ReceivableDetails
	IF OBJECT_ID('tempdb..#ReceivableInfo') IS NOT NULL
	DROP TABLE #ReceivableInfo
	IF OBJECT_ID('tempdb..#ReceivableTaxDetails') IS NOT NULL
	DROP TABLE  #ReceivableTaxDetails
	IF OBJECT_ID('tempdb..#tempRemainingNetInvestmentsIds') IS NOT NULL
	DROP TABLE #tempRemainingNetInvestmentsIds
	IF OBJECT_ID('tempdb..#tempRemainingNetInvestments') IS NOT NULL
	DROP TABLE #tempRemainingNetInvestments
	IF OBJECT_ID('tempdb..#Assets') IS NOT NULL
    DROP TABLE  #Assets

	SET NOCOUNT OFF;

GO

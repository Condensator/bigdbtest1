SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetUsedAmountForLOC]
(
@CreditProfileId BIGINT,
@ExcludedContractId BIGINT,
@IncomeDate DATE,
@InactiveStatus NVARCHAR(50),
@LoanCancelledStatus NVARCHAR(50),
@Origination NVARCHAR(50),
@OperatingContractSubType NVARCHAR(50),
@PayableInvoiceAssetSourceTable NVARCHAR(50),
@PayableInvoiceOtherCostSourceTable NVARCHAR(50),
@LoanDisbursementAllocationMethod NVARCHAR(50),
@LoanContractType NVARCHAR(50),
@ProgressLoanContractType NVARCHAR(50),
@Lease NVARCHAR(10),
@ApprovalStatus NVARCHAR(50),
@SaleOfPaymentsType NVARCHAR(50),
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
@FixedTerm NVARCHAR(50),
@CompletedStatus NVARCHAR(50),
@OTPDepreciation NVARCHAR(50),
@ResidualRecapture NVARCHAR(50),
@CapitalizedSalesTax NVARCHAR(50),
@PostedStatus NVARCHAR(50),
@SpecificCostAdjustment NVARCHAR(50),
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
@ActiveStatus NVARCHAR(20),
@LoanDownPayment NVARCHAR(20),
@FullPaydown NVARCHAR(20),
@Casualty NVARCHAR(20),
@CapitalizedInterestDueToSkipPayments NVARCHAR(60),
@CapitalizedInterestDueToRateChange NVARCHAR(60),
@CapitalizedInterestFromPaydown NVARCHAR(60),
@CapitalizedInterestDueToScheduledFunding NVARCHAR(60),
@Financing NVARCHAR(20),
@ProgressLoanInterestCapitalized NVARCHAR(50),
@ParticipatedSale NVARCHAR(30),
@ReceiptSourceTable NVARCHAR(20),
@ReversedStatus NVARCHAR(20),
@ReceiptRefundEntityType NVARCHAR(5),
@LeasePayOff NVARCHAR(20),
@BuyOut NVARCHAR(20),
@Finance NVARCHAR(10),
@OverTerm NVARCHAR(20),
@LeveragedLeaseRental NVARCHAR(50),
@ReAccrualResidualIncome NVARCHAR(50),
@ReAccrualIncome NVARCHAR(20),
@ReAccrualFinanceIncome NVARCHAR(50),
@ReAccrualFinanceResidualIncome NVARCHAR(50),
@IsRebook BIT,
@LoanFinanceId BIGINT =NULL
)
AS
BEGIN
--DECLARE @ExcludedContractId BIGINT
--DECLARE	@IncomeDate DATE
--DECLARE	@InactiveStatus NVARCHAR(50)
--DECLARE	@LoanCancelledStatus NVARCHAR(50)
--DECLARE   @Origination NVARCHAR(50)
--DECLARE	@OperatingContractSubType NVARCHAR(50)
--DECLARE	@PayableInvoiceAssetSourceTable NVARCHAR(50)
--DECLARE	@PayableInvoiceOtherCostSourceTable NVARCHAR(50)
--DECLARE	@LoanDisbursementAllocationMethod NVARCHAR(50)
--DECLARE	@LoanContractType NVARCHAR(50)
--DECLARE	@ProgressLoanContractType NVARCHAR(50)
--DECLARE	@Lease NVARCHAR(10)
--DECLARE	@ApprovalStatus NVARCHAR(50)
--DECLARE	@SaleOfPaymentsType NVARCHAR(50)
--DECLARE	@FixedTermBookDepSourceModule NVARCHAR(50)
--DECLARE	@CashBasedAccountingTreatment NVARCHAR(50)
--DECLARE	@AccrualBased NVARCHAR(50)
--DECLARE	@OperatingLeaseRental NVARCHAR(50)
--DECLARE	@InterimRental NVARCHAR(50)
--DECLARE	@CapitalLeaseRental NVARCHAR(50)
--DECLARE	@OverTermRental NVARCHAR(50)
--DECLARE	@LoanInterest NVARCHAR(50)
--DECLARE	@LoanPrincipal NVARCHAR(50)
--DECLARE	@LeaseFloatRateAdj NVARCHAR(50)
--DECLARE	@LeaseInterimInterest NVARCHAR(50)
--DECLARE @CommencedStatus NVARCHAR(50)
--DECLARE @FullyPaid NVARCHAR(50)
--DECLARE @UnCommencedStatus NVARCHAR(50)
--DECLARE @FixedTerm NVARCHAR(50)
--DECLARE	@CompletedStatus NVARCHAR(50)
--DECLARE @OTPDepreciation NVARCHAR(50)
--DECLARE @ResidualRecapture NVARCHAR(50)
--DECLARE @Supplemental NVARCHAR(50)
--DECLARE @CapitalizedSalesTax NVARCHAR(50)
--DECLARE @PostedStatus NVARCHAR(50)
--DECLARE @SpecificCostAdjustment NVARCHAR(50)
--DECLARE @LeasePak NVARCHAR(100)
--DECLARE @Unknown NVARCHAR(3)
--DECLARE @None NVARCHAR(5)
--DECLARE @RecognizeImmediately NVARCHAR(50)
--DECLARE @Capitalize NVARCHAR(50)
--DECLARE @ReAccrualSystemConfigType NVARCHAR(400)
--DECLARE @ContractEntityType NVARCHAR(3)
--DECLARE @FullSale NVARCHAR(20)
--DECLARE @ProgressPaymentCreditAllocationMethod NVARCHAR(50)
--DECLARE @FullyPaidOff NVARCHAR(20)
--DECLARE @OriginationRestoredType NVARCHAR(50)
--DECLARE @ActiveStatus NVARCHAR(20)
--DECLARE @LoanDownPayment NVARCHAR(20)
--DECLARE @FullPaydown NVARCHAR(20)
--DECLARE @Casualty NVARCHAR(20)
--DECLARE @CapitalizedInterestDueToSkipPayments NVARCHAR(60)
--DECLARE @CapitalizedInterestDueToRateChange NVARCHAR(60)
--DECLARE @CapitalizedInterestFromPaydown NVARCHAR(60)
--DECLARE @CapitalizedInterestDueToScheduledFunding NVARCHAR(60)
--DECLARE @Financing NVARCHAR(20)
--DECLARE @ProgressLoanInterestCapitalized NVARCHAR(50)
--DECLARE @ParticipatedSale NVARCHAR(30)
--DECLARE @ReceiptSourceTable NVARCHAR(20)
--DECLARE @ReversedStatus NVARCHAR(20)
--DECLARE @ReceiptRefundEntityType NVARCHAR(5)
--DECLARE @LeasePayOff NVARCHAR(20)
--DECLARE @BuyOut NVARCHAR(20)
--DECLARE @Finance NVARCHAR(10)
--DECLARE @OverTerm NVARCHAR(20)
--DECLARE @LeveragedLeaseRental NVARCHAR(50)
--DECLARE @CreditProfileId BIGINT
--DECLARE @ReAccrualResidualIncome NVARCHAR(50)
--DECLARE @ReAccrualIncome NVARCHAR(20)
--DECLARE @ReAccrualFinanceIncome NVARCHAR(50)
--DECLARE @ReAccrualFinanceResidualIncome NVARCHAR(50)
--DECLARE @ReAccrualDeferredSellingProfitIncome NVARCHAR(60)
--SET @CreditProfileId = 49
--SET @ExcludedContractId = 10
--SET	@IncomeDate = '2019-01-01'
--SET	@InactiveStatus ='Inactive'
--SET	@LoanCancelledStatus ='Cancelled'
--SET @Origination ='Origination'
--SET	@OperatingContractSubType ='Operating'
--SET	@PayableInvoiceAssetSourceTable ='PayableInvoiceAsset'
--SET	@PayableInvoiceOtherCostSourceTable ='PayableInvoiceOtherCost'
--SET	@LoanDisbursementAllocationMethod ='LoanDisbursement'
--SET	@LoanContractType ='Loan'
--SET	@ProgressLoanContractType ='ProgressLoan'
--SET	@Lease ='Lease'
--SET	@SaleOfPaymentsType ='SaleOfPayments'
--SET	@CashBasedAccountingTreatment ='CashBased'
--SET	@AccrualBased ='AccrualBased'
--SET	@OperatingLeaseRental ='OperatingLeaseRental'
--SET	@InterimRental ='InterimRental'
--SET	@CapitalLeaseRental ='CapitalLeaseRental'
--SET	@OverTermRental ='OverTermRental'
--SET	@LoanInterest ='LoanInterest'
--SET	@LoanPrincipal ='LoanPrincipal'
--SET	@LeaseFloatRateAdj ='LeaseFloatRateAdj'
--SET	@LeaseInterimInterest ='LeaseInterimInterest'
--SET @CommencedStatus='Commenced'
--SET @FullyPaid = 'FullyPaid'
--SET @UnCommencedStatus='Uncommenced'
--SET @FixedTerm = 'FixedTerm'
--SET @CompletedStatus = 'Completed'
--SET @OTPDepreciation = 'OTPDepreciation'
--SET @ResidualRecapture = 'ResidualRecapture'
--SET @Supplemental = 'Supplemental'
--SET @CapitalizedSalesTax ='CapitalizedSalesTax'
--SET @PostedStatus = 'Posted'
--SET @SpecificCostAdjustment = 'SpecificCostAdjustment'
--SET @ApprovalStatus='Approved'
--SET @FixedTermBookDepSourceModule = 'FixedTermDepreciation'
-- SET @LeasePak ='LeasePak'
-- SET @Unknown = '_'
--SET @None = 'None'
--SET @RecognizeImmediately ='RecognizeImmediately'
--SET @Capitalize = 'Capitalize'
--SET @ReaccrualSystemConfigType = 'ReAccrualResidualIncome,ReAccrualRentalIncome,ReAccrualIncome,ReAccrualFinanceIncome,ReAccrualFinanceResidualIncome,ReAccrualDeferredSellingProfitIncome'
--SET @ContractEntityType = 'CT'
--SET @FullSale ='FullSale'
--SET @ProgressPaymentCreditAllocationMethod = 'ProgressPaymentCredit'
--SET @FullyPaidOff = 'FullyPaidOff'
--SET @OriginationRestoredType = 'OriginationRestored'
--SET @ActiveStatus = 'Active'
--SET @LoanDownPayment = 'Downpayment'
--SET @FullPaydown = 'FullPaydown'
--SET @Casualty = 'Casualty'
--SET @CapitalizedInterestDueToSkipPayments = 'CapitalizedInterestDueToSkipPayments'
--SET @CapitalizedInterestDueToRateChange = 'CapitalizedInterestDueToRateChange'
--SET @CapitalizedInterestFromPaydown = 'CapitalizedInterestFromPaydown'
--SET @CapitalizedInterestDueToScheduledFunding = 'CapitalizedInterestDueToScheduledFunding'
--SET @Financing = 'Financing'
--SET @ProgressLoanInterestCapitalized = 'ProgressLoanInterestCapitalized'
--SET @ParticipatedSale = 'ParticipatedSale'
--SET @ReceiptSourceTable = 'Receipt'
--SET @ReversedStatus = 'Reversed'
--SET @ReceiptRefundEntityType = 'RR'
--SET @LeasePayOff = 'LeasePayOff'
--SET @BuyOut = 'BuyOut'
--SET @Finance = 'Finance'
--SET @OverTerm = 'OverTerm'
--SET @LeveragedLeaseRental = 'LeveragedLeaseRental'
--SET @ReAccrualResidualIncome = 'ReAccrualResidualIncome'
--SET @ReAccrualIncome = 'ReAccrualIncome'
--SET @ReAccrualFinanceIncome  = 'ReAccrualFinanceIncome'
--SET @ReAccrualFinanceResidualIncome = 'ReAccrualFinanceResidualIncome'
--SET @ReAccrualDeferredSellingProfitIncome = 'ReAccrualDeferredSellingProfitIncome'
SET NOCOUNT ON;
CREATE TABLE #RNITemp (ContractId BIGINT PRIMARY KEY
,PrincipalBalance_Amount DECIMAL(18,2) DEFAULT 0
,PrincipalBalanceAdjustment_Amount DECIMAL(18,2) DEFAULT 0
,LoanPrincipleOSAR_Amount DECIMAL(18,2) DEFAULT 0
,LoanInterestOSAR_Amount DECIMAL(18,2) DEFAULT 0
,IncomeAccrualBalance_Amount DECIMAL(18,2) DEFAULT 0
,ProgressFundings_Amount DECIMAL(18,2) DEFAULT 0
,ProgressPaymentCredits_Amount DECIMAL(18,2) DEFAULT 0
,TotalFinancedAmountLOC_Amount DECIMAL(18,2) DEFAULT 0
,UnappliedCash_Amount DECIMAL(18,2) DEFAULT 0
,NetWritedowns_Amount DECIMAL(18,2) DEFAULT 0
,OperatingLeaseAssetGrossCost_Amount DECIMAL(18,2) DEFAULT 0
,AccumulatedDepreciation_Amount DECIMAL(18,2) DEFAULT 0
,OperatingLeaseRentOSAR_Amount DECIMAL(18,2) DEFAULT 0
,CapitalLeaseContractReceivable_Amount DECIMAL(18,2) DEFAULT 0
,CapitalLeaseRentOSAR_Amount DECIMAL(18,2) DEFAULT 0
,OverTermRentOSAR_Amount DECIMAL(18,2) DEFAULT 0
,OTPResidualRecapture_Amount DECIMAL(18,2) DEFAULT 0
,PrepaidReceivables_Amount DECIMAL(18,2) DEFAULT 0
,SyndicatedPrepaidReceivables_Amount DECIMAL(18,2) DEFAULT 0
,FloatRateAdjustmentOSAR_Amount DECIMAL(18,2) DEFAULT 0
,SyndicatedFixedTermReceivablesOSAR_Amount DECIMAL(18,2) DEFAULT 0
,SalesTaxOSAR_Amount DECIMAL(18,2) DEFAULT 0
,SyndicatedSalesTaxOSAR_Amount DECIMAL(18,2) DEFAULT 0
,SyndicatedCapitalLeaseContractReceivable_Amount DECIMAL(18,2)  DEFAULT 0
,PrincipalBalanceFunderPortion_Amount DECIMAL(18,2) DEFAULT 0
,FinanceIncomeAccrualBalance_Amount DECIMAL(18,2) DEFAULT 0
,FinancingContractReceivable_Amount DECIMAL(18,2) DEFAULT 0
,FinancingRentOSAR_Amount DECIMAL(18,2) DEFAULT 0
,FinanceSyndicatedFixedTermReceivablesOSAR_Amount DECIMAL(18,2) DEFAULT 0);
CREATE TABLE #LeaseDetails (ContractId BIGINT PRIMARY KEY, LeaseFinanceId BIGINT, CommencementDate DATE, LeaseContractType NVARCHAR(32),
BookingStatus NVARCHAR(32), LegalEntityId BIGINT,OTPLease BIT,  OTPReceivableCodeId BIGINT, IsInOTP BIT, SyndicationType NVARCHAR(32), IsMigratedContract BIT, IsChargedOff BIT,IsNonAccrual BIT
, SalesTaxRemittanceMethod NVARCHAR(24));
CREATE INDEX IX_ContractId ON #LeaseDetails (ContractId)
CREATE TABLE #LoanDetails (ContractId BIGINT PRIMARY KEY, LoanFinanceId BIGINT, CommencementDate DATE,
Status NVARCHAR(32), IsDSL BIT, SyndicationType NVARCHAR(32), IsMigratedContract BIT
, IsChargedOff BIT,IsNonAccrual BIT,IsProgressLoan BIT, PrincipalBalance DECIMAL(16,2), TotalAmount DECIMAL(16,2)
, PrincipalBalanceIncomeExists BIT);
CREATE TABLE #BasicDetails (ContractId BIGINT PRIMARY KEY, SyndicationType NVARCHAR(32),CommencementDate DATE,IsChargedOff BIT
,MaxIncomeDate DATE, MaxNonAccrualDate DATE, ChargeOffDate DATE);
CREATE TABLE #SyndicationDetailsTemp(ContractId BIGINT, RetainedPercentage DECIMAL(18,8), ReceivableForTransferType NVARCHAR(32), SyndicationEffectiveDate DATE,
SyndicationId BIGINT, IsServiced BIT, IsCollected  BIT, SyndicationAtInception BIT);
CREATE TABLE #LeaseIncomeScheduleTemp(ContractId BIGINT,IncomeDate DATE,IsNonAccrual BIT,Income_Amount DECIMAL(16,2),IsLessorOwned BIT
,IsAccounting BIT,IsSchedule BIT,IsGLPosted BIT,IsReclassOTP BIT,FinanceIncome_Amount DECIMAL(16,2),AccountingTreatment NVARCHAR(12));
CREATE TABLE #LoanIncomeScheduleTemp(ContractId BIGINT,EndNetBookValue_Amount DECIMAL(16,2),IncomeDate DATE,IsNonAccrual BIT,IsLessorOwned BIT
,IsAccounting BIT,IsSchedule BIT,InterestAccrued_Amount DECIMAL(16,2),IsGLPosted BIT);
CREATE TABLE #ReceivableDetailsTemp(ContractId BIGINT,ReceivableId BIGINT,ReceivableType NVARCHAR(25),Balance_Amount DECIMAL(16,2)
,Amount_Amount DECIMAL(16,2),DueDate DATE,FunderId BIGINT,IsGLPosted BIT,AccountingTreatment NVARCHAR(12),IsDummy BIT,EffectiveBookBalance_Amount DECIMAL(16,2),
PaymentStartDate DATE,PaymentEndDate DATE,PaymentDueDate DATE,PaymentType NVARCHAR(28),IsFinanceComponent BIT);
CREATE TABLE #BlendedItemTemp(ContractId BIGINT, BlendedItemId BIGINT, IsFAS91 BIT, Type NVARCHAR(14), SystemConfigType NVARCHAR(46)
, IncomeAmount DECIMAL(16,2));
CREATE TABLE #AssetTemp(ContractId BIGINT, Amount DECIMAL(16,2), AssetId BIGINT, CapitalizationType NVARCHAR(26)
, IsMigratedContract BIT, CapitalizedForId BIGINT, PayableInvoiceId BIGINT, ETCAdjustmentAmount_Amount DECIMAL(16,2), IsActive BIT
, IsLeaseAsset BIT, LeaseAssetId BIGINT);
CREATE INDEX IX_ContractId_AssetId ON #AssetTemp (ContractId,AssetId)
CREATE TABLE #LoanFinanceBasicTemp(ContractId BIGINT,Amount DECIMAL(16,2),FundingId BIGINT,Type NVARCHAR(21),PayableInvoiceId BIGINT,Status NVARCHAR(9)
,OtherCostId BIGINT,IsForeignCurrency BIT,InitialExchangeRate DECIMAL(20,10),InvoiceDate DATE,IsOrigination BIT);
CREATE TABLE #LoanPaydownTemp(ContractId BIGINT, IsDailySensitive BIT, PaydownDate DATE, PaydownReason NVARCHAR(30), PrincipalBalance_Amount DECIMAL(16,2)
, PrincipalPaydown_Amount DECIMAL(16,2), AccruedInterest_Amount DECIMAL(16,2), InterestPaydown_Amount DECIMAL(16,2));
CREATE TABLE #FutureScheduledFundedTemp(ContractId BIGINT,FundingId BIGINT,Amount DECIMAL(16,2),InvoiceDate DATE,PaymentDate DATE,
DRStatus NVARCHAR(25),DueDate DATE, IsGLPosted BIT);
DECLARE @IsRevolving BIT;
SET @IsRevolving = (SELECT IsRevolving FROM CreditProfiles WHERE Id = @CreditProfileId);
--Lease
INSERT INTO #LeaseDetails
SELECT Contract.Id AS ContractId
,Lease.Id AS LeaseFinanceId
,LeaseFinanceDetail.CommencementDate
,LeaseFinanceDetail.LeaseContractType
,Lease.BookingStatus
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
JOIN CreditApprovedStructures CreditApprovedStructure ON Contract.CreditApprovedStructureId = CreditApprovedStructure.Id AND CreditApprovedStructure.CreditProfileId = @CreditProfileId AND CreditApprovedStructure.IsActive = 1
JOIN LeaseFinances Lease ON Contract.Id = Lease.ContractId AND Lease.IsCurrent = 1 AND Lease.ApprovalStatus != @InactiveStatus
JOIN LeaseFinanceDetails LeaseFinanceDetail ON Lease.Id = LeaseFinanceDetail.Id
WHERE @ExcludedContractId IS NULL OR Contract.Id != @ExcludedContractId;
--Loan
INSERT INTO #LoanDetails
SELECT Contract.Id AS ContractId
,Loan.Id AS LoanFinanceId
,Loan.CommencementDate
,Loan.Status
,Loan.IsDailySensitive AS IsDSL
,Contract.SyndicationType
,(CASE WHEN Contract.u_ConversionSource = @LeasePak THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END) AS IsMigratedContract
,CASE WHEN Contract.ChargeOffStatus = @Unknown THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END AS IsChargedOff
,Contract.IsNonAccrual
,CASE WHEN Contract.ContractType = @ProgressLoanContractType THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsProgressLoan
,0.00 [PrincipalBalance]
,0.00 [TotalAmount]
,CAST(0 AS BIT) [PrincipalBalanceIncomeExists]
FROM Contracts Contract
JOIN CreditApprovedStructures CreditApprovedStructure ON Contract.CreditApprovedStructureId = CreditApprovedStructure.Id AND CreditApprovedStructure.CreditProfileId = @CreditProfileId AND CreditApprovedStructure.IsActive = 1
JOIN LoanFinances Loan ON Contract.Id = Loan.ContractId AND((@IsRebook =1 AND Loan.Id = @LoanFinanceId) OR (@IsRebook =0 AND Loan.IsCurrent = 1)) AND Loan.Status != @LoanCancelledStatus
WHERE @ExcludedContractId IS NULL OR Contract.Id != @ExcludedContractId;
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
NULL ChargeOffDate
FROM #LeaseDetails
UNION
SELECT
ContractId,
SyndicationType,
CommencementDate,
IsChargedOff,
NULL MaxIncomeDate,
NULL MaxNonAccrualDate,
NULL ChargeOffDate
FROM #LoanDetails)
BasicDetails
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
IF EXISTS(SELECT 1 FROM #LeaseDetails)
BEGIN
INSERT INTO #LeaseIncomeScheduleTemp
SELECT Contract.ContractId,
IncomeSched.IncomeDate,
IncomeSched.IsNonAccrual,
IncomeSched.Income_Amount,
IncomeSched.IsLessorOwned,
IncomeSched.IsAccounting,
IncomeSched.IsSchedule,
IncomeSched.IsGLPosted,
IncomeSched.IsReclassOTP,
IncomeSched.FinanceIncome_Amount,
IncomeSched.AccountingTreatment
FROM #LeaseDetails Contract
INNER JOIN LeaseFinances Lease ON Contract.ContractId = Lease.ContractId
INNER JOIN LeaseIncomeSchedules IncomeSched ON Lease.Id = IncomeSched.LeaseFinanceId AND IncomeSched.IncomeDate >= Contract.CommencementDate
WHERE (IncomeSched.IsSchedule = 1 OR IncomeSched.IsAccounting = 1);
END
-- To Check if we can use IsLessorOwned - DEVI  ok-- confirm with prachi
UPDATE Contract SET IsInOTP = CAST(1 AS BIT)
FROM #LeaseDetails AS Contract where EXISTS (SELECT ContractId  FROM #LeaseIncomeScheduleTemp LeaseIncome WHERE LeaseIncome.ContractID
= Contract.ContractID and  LeaseIncome.IsReclassOTP = 1);
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
IncomeSched.IsGLPosted
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
,BlendedItem.SystemConfigType
,0 AS IncomeAmount
FROM #LeaseDetails Contract
JOIN LeaseFinances Lease ON Contract.ContractId = Lease.ContractId AND Lease.IsCurrent = 1
JOIN LeaseBlendedItems ContractBlendedItem ON Lease.Id = ContractBlendedItem.LeaseFinanceId
JOIN BlendedItems BlendedItem ON ContractBlendedItem.BlendedItemId = BlendedItem.Id AND BlendedItem.IsActive = 1
AND BlendedItem.SystemConfigType IN (SELECT * FROM dbo.ConvertCSVToStringTable(@ReAccrualSystemConfigType,','))
LEFT JOIN #SyndicationDetailsTemp SyndicationDetail ON Contract.ContractId = SyndicationDetail.ContractId
WHERE (SyndicationDetail.SyndicationId IS NULL OR SyndicationDetail.RetainedPercentage > 0.0 OR SyndicationDetail.ReceivableForTransferType = @SaleOfPaymentsType)
AND BlendedItem.BookRecognitionMode NOT IN (@RecognizeImmediately,@Capitalize)
UNION
SELECT Contract.ContractId
,BlendedItem.Id AS BlendedItemId
,BlendedItem.IsFAS91
,BlendedItem.Type
,BlendedItem.SystemConfigType
,0 AS IncomeAmount
FROM #LoanDetails Contract
JOIN LoanFinances Loan ON Contract.ContractId = Loan.ContractId AND Loan.IsCurrent = 1
JOIN LoanBlendedItems ContractBlendedItem ON Loan.Id = ContractBlendedItem.LoanFinanceId
JOIN BlendedItems BlendedItem ON ContractBlendedItem.BlendedItemId = BlendedItem.Id AND BlendedItem.IsActive = 1
AND BlendedItem.SystemConfigType IN (SELECT * FROM dbo.ConvertCSVToStringTable(@ReAccrualSystemConfigType,','))
LEFT JOIN #SyndicationDetailsTemp SyndicationDetail ON Contract.ContractId = SyndicationDetail.ContractId
WHERE (SyndicationDetail.SyndicationId IS NULL OR (SyndicationDetail.RetainedPercentage > 0.0 OR SyndicationDetail.ReceivableForTransferType = @SaleOfPaymentsType))
AND BlendedItem.BookRecognitionMode NOT IN (@RecognizeImmediately,@Capitalize)
) AS BlendedItems
;
;WITH CTE_GroupedBI AS
(SELECT BlendedItem.BlendedItemId
,SUM(IncomeSched.Income_Amount) AS IncomeAmount
FROM #BlendedItemTemp BlendedItem
JOIN BlendedIncomeSchedules IncomeSched ON BlendedItem.BlendedItemId = IncomeSched.BlendedItemId
WHERE IncomeSched.IsAccounting = 1 AND IncomeSched.PostDate IS NOT NULL
GROUP BY BlendedItem.BlendedItemId,IncomeSched.IsNonAccrual)
UPDATE #BlendedItemTemp
SET IncomeAmount = BlendedIncomeDetails.IncomeAmount
FROM #BlendedItemTemp BlendedItem
JOIN (SELECT BlendedItemId
, SUM(IncomeAmount) AS IncomeAmount
FROM CTE_GroupedBI
GROUP BY BlendedItemId)
AS BlendedIncomeDetails ON BlendedItem.BlendedItemId = BlendedIncomeDetails.BlendedItemId
/*Blended Item Temp Ends*/
/*Asset Temp Begins*/
IF EXISTS(SELECT 1 FROM #LeaseDetails)
BEGIN
INSERT INTO #AssetTemp
SELECT Contract.ContractId
, LeaseAsset.NBV_Amount AS Amount
, LeaseAsset.AssetId
, LeaseAsset.CapitalizationType
, Contract.IsMigratedContract
, LeaseAsset.CapitalizedForId
, LeaseAsset.PayableInvoiceId
, LeaseAsset.ETCAdjustmentAmount_Amount
, LeaseAsset.IsActive
, LeaseAsset.IsLeaseAsset
, LeaseAsset.Id AS LeaseAssetId
FROM #LeaseDetails Contract
JOIN LeaseAssets LeaseAsset ON Contract.LeaseFinanceId = LeaseAsset.LeaseFinanceId
AND (LeaseAsset.IsActive = 1 OR LeaseAsset.TerminationDate IS NOT NULL);
END
/*Asset Temp Ends*/
/*Receivable Temp Begins*/
IF EXISTS(SELECT 1 FROM #LeaseDetails)
BEGIN
INSERT INTO #ReceivableDetailsTemp
SELECT ReceivableInfo.ContractId
,Receivable.Id AS ReceivableId
,Type.Name AS ReceivableType
,ReceivableInfo.Balance_Amount
,ReceivableInfo.Amount_Amount
,Receivable.DueDate
,Receivable.FunderId
,Receivable.IsGLPosted
,Code.AccountingTreatment
,Receivable.IsDummy
,ReceivableInfo.EffectiveBookBalance_Amount
,PaymentSched.StartDate AS PaymentStartDate
,PaymentSched.EndDate AS PaymentEndDate
,PaymentSched.DueDate AS PaymentDueDate
,PaymentSched.PaymentType AS PaymentType
,ReceivableInfo.IsFinanceComponent
FROM (SELECT Contract.ContractId
,Receivable.Id AS ReceivableId
,SUM(ReceivableDetail.Balance_Amount) Balance_Amount
,SUM(ReceivableDetail.Amount_Amount) Amount_Amount
,SUM(ReceivableDetail.EffectiveBookBalance_Amount) EffectiveBookBalance_Amount
,CASE WHEN ReceivableDetail.AssetComponentType = @Finance THEN 1 ELSE 0 END AS IsFinanceComponent
FROM #LeaseDetails Contract
JOIN Receivables Receivable ON Contract.ContractId = Receivable.EntityId AND Receivable.EntityType = @ContractEntityType AND Receivable.IsActive=1
JOIN ReceivableDetails ReceivableDetail ON Receivable.Id = ReceivableDetail.ReceivableId AND ReceivableDetail.IsActive = 1
GROUP BY Contract.ContractId,Receivable.Id,ReceivableDetail.AssetComponentType) AS ReceivableInfo
JOIN Receivables Receivable ON ReceivableInfo.ReceivableId = Receivable.Id
JOIN ReceivableCodes Code ON Receivable.ReceivableCodeId = Code.Id
JOIN ReceivableTypes Type ON Code.ReceivableTypeId = Type.Id AND Type.Name NOT IN (@LeasePayOff,@BuyOut)
LEFT JOIN LeasePaymentSchedules PaymentSched ON Receivable.PaymentScheduleId = PaymentSched.Id
/*Payoff Buyout Receivables*/
IF EXISTS(SELECT 1 FROM #AssetTemp)
BEGIN
INSERT INTO #ReceivableDetailsTemp
SELECT ReceivableInfo.ContractId
,Receivable.Id AS ReceivableId
,Type.Name AS ReceivableType
,ReceivableInfo.Balance_Amount
,ReceivableInfo.Amount_Amount
,Receivable.DueDate
,Receivable.FunderId
,Receivable.IsGLPosted
,Code.AccountingTreatment
,Receivable.IsDummy
,ReceivableInfo.EffectiveBookBalance_Amount
,PaymentSched.StartDate AS PaymentStartDate
,PaymentSched.EndDate AS PaymentEndDate
,PaymentSched.DueDate AS PaymentDueDate
,PaymentSched.PaymentType AS PaymentType
,ReceivableInfo.IsFinanceComponent
FROM (SELECT Contract.ContractId
,Receivable.Id AS ReceivableId
,SUM(ReceivableDetail.Balance_Amount) Balance_Amount
,SUM(ReceivableDetail.Amount_Amount) Amount_Amount
,SUM(ReceivableDetail.EffectiveBookBalance_Amount) EffectiveBookBalance_Amount
,CASE WHEN Asset.IsLeaseAsset = 0 THEN 1 ELSE 0 END AS IsFinanceComponent
FROM #LeaseDetails Contract
JOIN Receivables Receivable ON Contract.ContractId = Receivable.EntityId AND Receivable.EntityType = @ContractEntityType AND Receivable.IsActive=1
JOIN ReceivableDetails ReceivableDetail ON Receivable.Id = ReceivableDetail.ReceivableId AND ReceivableDetail.IsActive = 1
JOIN #AssetTemp Asset ON Contract.ContractId = Asset.ContractId AND ReceivableDetail.AssetId = Asset.AssetId
GROUP BY Contract.ContractId,Receivable.Id,Asset.IsLeaseAsset) AS ReceivableInfo
JOIN Receivables Receivable ON ReceivableInfo.ReceivableId = Receivable.Id
JOIN ReceivableCodes Code ON Receivable.ReceivableCodeId = Code.Id
JOIN ReceivableTypes Type ON Code.ReceivableTypeId = Type.Id AND Type.Name IN (@LeasePayOff,@BuyOut)
LEFT JOIN LeasePaymentSchedules PaymentSched ON Receivable.PaymentScheduleId = PaymentSched.Id
END
END
IF EXISTS(SELECT 1 FROM #LoanDetails)
BEGIN
INSERT INTO #ReceivableDetailsTemp
SELECT Contract.ContractId
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
/*Receivable Temp Ends*/
/*Basic Contract Date Info Begins*/
;WITH CTE_MaxGLPostedEndDate AS(
SELECT Receivable.ContractId
,MAX(Receivable.PaymentEnddate) AS EndDate
FROM #ReceivableDetailsTemp Receivable
JOIN #LoanDetails ON Receivable.ContractId = #LoanDetails.ContractId
WHERE Receivable.IsGLPosted = 1
AND Receivable.PaymentEnddate IS NOT NULL
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
AND MaxGLPostedEnddate.EndDate = IncomeSched.IncomeDate
) AND IncomeSched.IsSchedule = 1
GROUP BY IncomeSched.ContractId) AS MaxIncomeDateTemp
ON Contract.ContractId = MaxIncomeDateTemp.ContractId;
/*Non And ReAccrual Date Begins*/
UPDATE #BasicDetails
SET MaxNonAccrualDate = NonAccrual.NonAccrualDate
FROM #BasicDetails Contract
JOIN (SELECT Contract.ContractId,
Max(NonAccrualContract.NonAccrualDate) AS NonAccrualDate
FROM #BasicDetails Contract
JOIN NonAccrualContracts NonAccrualContract ON Contract.ContractId = NonAccrualContract.ContractId AND NonAccrualContract.IsActive = 1 AND NonAccrualContract.IsNonaccrualApproved = 1
GROUP BY Contract.ContractId) as NonAccrual ON Contract.ContractId = NonAccrual.ContractId;
/*Non And ReAccrual Date Ends*/
/*ChargeOff Date Begins*/
UPDATE #BasicDetails SET ChargeOffDate = ChargeOff.ChargeOffDate
FROM #BasicDetails Contract
JOIN ChargeOffs ChargeOff ON Contract.ContractId = ChargeOff.ContractId AND ChargeOff.IsActive = 1 AND ChargeOff.IsRecovery = 0 ;
/*ChargeOff Date Ends*/
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
,CASE WHEN Funding.Type = @Origination THEN 1 ELSE 0 END AS IsOrigination
FROM #LoanDetails Contract
JOIN LoanFundings Funding ON Contract.LoanFinanceId = Funding.LoanFinanceId AND Funding.IsActive = 1
JOIN PayableInvoices Invoice ON Funding.FundingId = Invoice.Id
JOIN PayableInvoiceOtherCosts InvoiceOtherCost ON Invoice.Id = InvoiceOtherCost.PayableInvoiceId AND InvoiceOtherCost.IsActive = 1
WHERE InvoiceOtherCost.AllocationMethod = @LoanDisbursementAllocationMethod
END
/*Loan Finance Basic Temp*/
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
/*Progress Fundings*/ -- CE
;WITH CTE_UnMigratedProgressFundings AS
(SELECT Contract.ContractId
,SUM(CASE WHEN LoanTemp.IsForeignCurrency = 0 THEN (LoanTemp.Amount) ELSE (LoanTemp.Amount * LoanTemp.InitialExchangeRate) END) AS Amount
FROM (SELECT ContractId,LoanFinanceId FROM #LoanDetails WHERE IsProgressLoan=1 AND IsMigratedContract=0) Contract
JOIN #LoanFinanceBasicTemp LoanTemp ON Contract.ContractId = LoanTemp.ContractId -- Newly Added Checking FS
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
UPDATE #RNITemp SET ProgressFundings_Amount = ISNULL(ProgressFunding.Amount,0) + ISNULL(MigratedProgressFunding.Amount,0)
FROM #RNITemp RNI
LEFT JOIN CTE_UnMigratedProgressFundings ProgressFunding ON RNI.ContractId = ProgressFunding.ContractId
LEFT JOIN CTE_MigratedProgressFundings MigratedProgressFunding ON RNI.ContractId = MigratedProgressFunding.ContractId
END
/*Total Financed Amount LOC*/ -- CE
;WITH CTE_NBVInfo AS
(SELECT SUM(LeaseAsset.Amount) AS NBVLOCAmount
, LeaseAsset.ContractId
FROM #AssetTemp LeaseAsset
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
FROM #AssetTemp CapitalizedLeaseAsset
JOIN #AssetTemp LeaseAsset ON CapitalizedLeaseAsset.CapitalizedForId = LeaseAsset.LeaseAssetId AND CapitalizedLeaseAsset.CapitalizationType = @CapitalizedSalesTax
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
JOIN #AssetTemp LeaseAsset ON SyndicationDetail.ContractId = LeaseAsset.ContractId
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
/*Principal Balance*/ -- CE
IF @IsRevolving = 1
BEGIN
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
WHERE Receivable.PaymentType = @LoanDownPayment AND Receivable.IsGLPosted = 0
GROUP BY Receivable.ContractId,Receivable.IsGLPosted)
UPDATE #LoanDetails
SET PrincipalBalance = PrincipalBalance + ISNULL(PrincipalInfo.Downpayment,0.00),
TotalAmount = TotalAmount - ISNULL(DisbursementInfo.Downpayment,0.00)
FROM #LoanDetails Loan
LEFT JOIN CTE_DownPaymentInfo PrincipalInfo ON Loan.ContractId = PrincipalInfo.ContractId AND PrincipalInfo.IsGLPosted = 0
LEFT JOIN CTE_DownPaymentInfo DisbursementInfo ON Loan.ContractId = PrincipalInfo.ContractId AND DisbursementInfo.IsGLPosted = 1;
END
IF EXISTS(SELECT 1 FROM #LoanDetails WHERE SyndicationType <> @FullSale and IsProgressLoan = 0)
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
JOIN #LoanDetails Contract ON Contract.ContractId = PaydownTemp.ContractId AND PaydownTemp.PaydownReason IN(@FullPaydown,@Casualty) AND Contract.SyndicationType != @FullSale AND Contract.IsChargedOff = 0
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
JOIN LoanCapitalizedInterests CapInterest ON Contract.LoanFinanceId = CapInterest.LoanFinanceId  AND CapInterest.GLJournalId IS NOT NULL
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
JOIN LoanCapitalizedInterests CapInterest ON Contract.LoanFinanceId = CapInterest.LoanFinanceId AND CapInterest.GLJournalId IS NULL
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
/*Income Accrual Balance*//*Finance Income Accrual Balance - CE */
;WITH CTE_LeaseIncomeInfo AS
(SELECT IncomeSched.ContractId
,SUM(IncomeSched.Income_Amount) AS IncomeAmount
,SUM(IncomeSched.FinanceIncome_Amount) AS FinanceIncomeAmount
FROM #LeaseIncomeScheduleTemp IncomeSched
WHERE IncomeSched.IsAccounting = 1 AND IsLessorOwned = 1 AND IncomeSched.IsGLPosted = 0
GROUP BY IncomeSched.ContractId)
UPDATE #RNITemp SET IncomeAccrualBalance_Amount = CASE WHEN Contract.LeaseContractType NOT IN (@OperatingContractSubType,@Financing) THEN LeaseIncome.IncomeAmount ELSE 0.00 END,
FinanceIncomeAccrualBalance_Amount = LeaseIncome.FinanceIncomeAmount
FROM #RNITemp RNI
JOIN #LeaseDetails Contract ON RNI.ContractId = Contract.ContractId
JOIN CTE_LeaseIncomeInfo LeaseIncome ON RNI.ContractId = LeaseIncome.ContractId;
/* ReAccrual Blended Adjustment*/
IF EXISTS(SELECT 1 FROM #BlendedItemTemp)
BEGIN
;WITH CTE_BIIncomeInfo AS
(SELECT BIIncomeSched.ContractId
,SUM(CASE WHEN BIIncomeSched.SystemConfigType IN (@ReAccrualIncome,@ReAccrualResidualIncome) THEN BIIncomeSched.IncomeAmount ELSE 0.00 END) AS ReAccrualAdjIncomeAmount
,SUM(CASE WHEN BIIncomeSched.SystemConfigType IN (@ReAccrualFinanceIncome,@ReAccrualFinanceResidualIncome) THEN BIIncomeSched.IncomeAmount ELSE 0.00 END) AS ReAccrualAdjFinanceIncomeAmount
FROM #LeaseDetails Contract
JOIN #BlendedItemTemp BIIncomeSched ON Contract.ContractId = BIIncomeSched.ContractId
GROUP BY BIIncomeSched.ContractId)
UPDATE #RNITemp SET IncomeAccrualBalance_Amount = IncomeAccrualBalance_Amount + BIIncome.ReAccrualAdjIncomeAmount ,
FinanceIncomeAccrualBalance_Amount = FinanceIncomeAccrualBalance_Amount + BIIncome.ReAccrualAdjFinanceIncomeAmount
FROM #RNITemp RNI
JOIN CTE_BIIncomeInfo BIIncome ON RNI.ContractId = BIIncome.ContractId;
END
/* ReAccrual Blended Adjustment Ends*/
/*Loan Principal OSAR*/ -- CE
IF EXISTS (SELECT 1 FROM #LoanDetails)
BEGIN
;WITH CTE_DSLLoanPrincipalReceivable AS
(SELECT Contract.ContractId,
SUM(CASE WHEN Contract.IsNonAccrual = 0 THEN ReceivableDetail.Balance_Amount ELSE ReceivableDetail.EffectiveBookBalance_Amount END) AS DSLLoanPrincipalAmount
FROM (SELECT ContractId,IsNonAccrual FROM #LoanDetails WHERE IsDSL = 1) Contract
JOIN #ReceivableDetailsTemp ReceivableDetail ON Contract.ContractId = ReceivableDetail.ContractId AND ReceivableDetail.ReceivableType = @LoanPrincipal
AND ReceivableDetail.FunderId IS NULL AND ReceivableDetail.IsGLPosted=1
GROUP BY Contract.ContractId)
UPDATE #RNITemp SET LoanPrincipleOSAR_Amount = LoanPrincipleOSAR_Amount + LoanPrincipalReceivable.DSLLoanPrincipalAmount
FROM #RNITemp RNI
JOIN CTE_DSLLoanPrincipalReceivable LoanPrincipalReceivable ON RNI.ContractId = LoanPrincipalReceivable.ContractId;
;WITH CTE_NonDSLLoanPrincipalReceivable AS
(SELECT Contract.ContractId,
SUM(ReceivableDetail.Balance_Amount) AS NonDSLLoanPrincipalAmount
FROM (SELECT ContractId,IsNonAccrual FROM #LoanDetails WHERE IsDSL = 0 AND IsNonAccrual = 0) Contract
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
FROM (SELECT ContractId,IsNonAccrual FROM #LoanDetails WHERE IsDSL = 0 AND IsNonAccrual = 1) AS Contract
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
JOIN #ReceivableDetailsTemp ReceivableDetail ON ReceivableDetail.ReceivableType IN(@LoanInterest,@LoanPrincipal) AND ReceivableDetail.FunderId IS NOT NULL
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
FROM (SELECT ContractId FROM #LoanDetails WHERE IsNonAccrual = 0) AS Contract
JOIN #ReceivableDetailsTemp ReceivableDetail ON ReceivableDetail.ReceivableType = @LoanInterest AND ReceivableDetail.PaymentType = @FixedTerm
AND ReceivableDetail.FunderId IS NULL AND ReceivableDetail.IsGLPosted=1
GROUP BY Contract.ContractId)
UPDATE #RNITemp SET LoanInterestOSAR_Amount = LoanInterestOSAR_Amount + LoanInterestReceivable.LoanInterestAmount
FROM #RNITemp RNI
JOIN CTE_AccrualLoanInterestReceivable LoanInterestReceivable ON RNI.ContractId = LoanInterestReceivable.ContractId
;WITH CTE_LoanInterestInfo AS
(SELECT Contract.ContractId,
SUM(CASE WHEN ReceivableDetail.PaymentStartDate >= ContractDateInfo.MaxNonAccrualDate THEN ReceivableDetail.EffectiveBookBalance_Amount ELSE 0.00 END) AS BookBalanceAfterNonAccrual,
SUM(CASE WHEN ReceivableDetail.PaymentStartDate < ContractDateInfo.MaxNonAccrualDate THEN ReceivableDetail.Balance_Amount ELSE 0.00 END) AS BalanceBeforeNonAccrual
FROM (SELECT ContractId FROM #LoanDetails WHERE IsNonAccrual = 1) AS Contract
JOIN #BasicDetails ContractDateInfo ON Contract.ContractId = ContractDateInfo.ContractId
JOIN #ReceivableDetailsTemp ReceivableDetail ON ContractDateInfo.ContractId = ReceivableDetail.ContractId AND ReceivableDetail.ReceivableType = @LoanInterest
AND ReceivableDetail.IsGLPosted = 1 AND ReceivableDetail.PaymentType = @FixedTerm AND ReceivableDetail.FunderId IS NULL
GROUP BY Contract.ContractId)
UPDATE #RNITemp SET LoanInterestOSAR_Amount = LoanInterestOSAR_Amount + LoanInterestInfo.BookBalanceAfterNonAccrual + LoanInterestInfo.BalanceBeforeNonAccrual
FROM #RNITemp RNI
JOIN CTE_LoanInterestInfo LoanInterestInfo ON RNI.ContractId = LoanInterestInfo.ContractId;
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
JOIN Payables Payable ON Receipt.Id = Payable.SourceId AND Payable.SourceTable = @ReceiptSourceTable AND Payable.EntityType = @ReceiptRefundEntityType
JOIN UnallocatedRefunds Refund ON Payable.EntityId = Refund.Id AND Refund.Status != @ReversedStatus
WHERE Payable.Status != @InactiveStatus
GROUP BY Contract.ContractId)
UPDATE #RNITemp
SET UnappliedCash_Amount = UnappliedCashInfo.UnappliedCash + ISNULL(PayableBalanceInfo.PayableBalance,0.00)
FROM #RNITemp RNI
JOIN CTE_UnappliedCashInfo UnappliedCashInfo ON RNI.ContractId = UnappliedCashInfo.ContractId
LEFT JOIN CTE_PayableBalanceInfo PayableBalanceInfo ON RNI.ContractId = PayableBalanceInfo.ContractId;
;WITH CTE_WriteDown AS
(SELECT Contract.ContractId,
SUM(WriteDownAsset.WriteDownAmount_Amount) NetWriteDownAmount
FROM #LoanDetails Contract
JOIN WriteDowns WriteDown ON Contract.ContractId = WriteDown.ContractId AND WriteDown.IsActive = 1
JOIN WriteDownAssetDetails WriteDownAsset ON WriteDown.Id = WriteDownAsset.WriteDownId AND WriteDownAsset.IsActive = 1
GROUP BY Contract.ContractId)
UPDATE #RNITemp SET NetWritedowns_Amount = WriteDown.NetWriteDownAmount
FROM #RNITemp RNI
JOIN CTE_WriteDown WriteDown ON RNI.ContractId = WriteDown.ContractId;
/* Operating Lease Asset Gross Cost - CE*/
;WITH CTE_OperatingLeaseAssetInfo AS(
SELECT Contract.ContractId,
SUM(LeaseAsset.Amount) - SUM(LeaseAsset.ETCAdjustmentAmount_Amount) AS Amount
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
IF EXISTS(SELECT 1 FROM #LeaseDetails WHERE SyndicationType <> @FullSale)
BEGIN
;WITH CTE_AccumulateDep AS
(SELECT Contract.ContractId
, ABS(SUM(AVH.Value_Amount)) AS Amount
FROM #LeaseDetails Contract
JOIN #AssetTemp Asset ON Contract.SyndicationType <> @FullSale  AND Contract.ContractId = Asset.ContractId AND Asset.IsActive = 1 AND Asset.IsLeaseAsset=1
JOIN AssetValueHistories AVH ON Asset.AssetId = AVH.AssetId AND AVH.SourceModule IN (@FixedTermBookDepSourceModule,@OTPDepreciation)
AND AVH.IsAccounted = 1 AND AVH.IsCleared = 0 AND AVH.IsLessorOwned = 1 AND AVH.GLJournalId IS NOT NULL
LEFT JOIN #SyndicationDetailsTemp SyndicationDetail ON Contract.ContractId = SyndicationDetail.ContractId
WHERE (Contract.SyndicationType IN(@None,@SaleOfPaymentsType) OR AVH.IncomeDate >= SyndicationDetail.SyndicationEffectiveDate)
GROUP BY Contract.ContractId)
UPDATE #RNITemp SET AccumulatedDepreciation_Amount = AccumulateDep.Amount
FROM #RNITemp RNI
JOIN CTE_AccumulateDep AccumulateDep ON RNI.ContractId = AccumulateDep.ContractId;
END
IF EXISTS(SELECT 1 FROM #LeaseDetails WHERE SyndicationType = @ParticipatedSale)
BEGIN
;WITH CTE_SyndicatedAccumulateDep AS
(SELECT SyndicationDetail.ContractId
, ABS(SUM(AVH.Value_Amount)) * (SyndicationDetail.RetainedPercentage/100) AS AmountWithRetainedPercentage
FROM #SyndicationDetailsTemp SyndicationDetail
JOIN #AssetTemp Asset ON SyndicationDetail.ReceivableForTransferType = @ParticipatedSale AND SyndicationDetail.ContractId = Asset.ContractId AND Asset.IsActive = 1 AND Asset.IsLeaseAsset=1
JOIN AssetValueHistories AVH ON Asset.AssetId = AVH.AssetId AND AVH.IncomeDate < SyndicationDetail.SyndicationEffectiveDate  AND AVH.SourceModule IN (@FixedTermBookDepSourceModule,@OTPDepreciation)
AND AVH.IsAccounted = 1 AND AVH.IsCleared = 0 AND AVH.IsLessorOwned = 1 AND AVH.GLJournalId IS NOT NULL
GROUP BY SyndicationDetail.ContractId,SyndicationDetail.RetainedPercentage)
UPDATE #RNITemp SET AccumulatedDepreciation_Amount = AccumulatedDepreciation_Amount + SyndicatedAccumulateDep.AmountWithRetainedPercentage
FROM #RNITemp RNI
JOIN CTE_SyndicatedAccumulateDep SyndicatedAccumulateDep ON RNI.ContractId = SyndicatedAccumulateDep.ContractId;
END
/*OTP Residual Recapture*/ -- CE
IF EXISTS(SELECT 1 FROM #LeaseDetails WHERE OTPLease = 1)
BEGIN
;WITH CTE_CashBasedAVHInfo AS
(SELECT Contract.ContractId
,ABS(SUM(AssetValueHistoryDetail.AmountPosted_Amount)) AS OTPResidualRecaptureCashBasedAmount
FROM (SELECT ContractId
FROM #LeaseDetails Lease
JOIN ReceivableCodes ReceivableCode ON Lease.OTPReceivableCodeId = ReceivableCode.Id AND ReceivableCode.AccountingTreatment = @CashBasedAccountingTreatment
AND SyndicationType <> @FullSale AND OTPLease = 1)  AS Contract
JOIN #AssetTemp Asset ON Contract.ContractId = Asset.ContractId AND Asset.IsActive = 1
JOIN AssetValueHistories AVH ON Asset.AssetId = AVH.AssetId AND AVH.SourceModule = @ResidualRecapture AND AVH.IsAccounted = 1 AND AVH.IsLessorOwned = 1
JOIN AssetValueHistoryDetails AssetValueHistoryDetail ON AVH.Id = AssetValueHistoryDetail.AssetValueHistoryId AND AssetValueHistoryDetail.GLJournalId IS NOT NULL AND AssetValueHistoryDetail.IsActive = 1
GROUP BY Contract.ContractId)
UPDATE #RNITemp SET OTPResidualRecapture_Amount = AVHInfo.OTPResidualRecaptureCashBasedAmount
FROM #RNITemp RNI
JOIN CTE_CashBasedAVHInfo AVHInfo ON RNI.ContractId = AVHInfo.ContractId;
;WITH CTE_AccrualBasedAVHInfo AS
(SELECT Contract.ContractId
,ABS(SUM(AVH.Value_Amount)) AS OTPResidualRecaptureAccrualBasedAmount
FROM (SELECT ContractId
FROM #LeaseDetails Lease
JOIN ReceivableCodes ReceivableCode ON Lease.OTPReceivableCodeId = ReceivableCode.Id AND ReceivableCode.AccountingTreatment = @AccrualBased
AND SyndicationType <> @FullSale AND OTPLease = 1)  AS Contract
JOIN #AssetTemp Asset ON Contract.ContractId = Asset.ContractId AND Asset.IsActive = 1
JOIN AssetValueHistories AVH ON Asset.AssetId = AVH.AssetId AND AVH.SourceModule = @ResidualRecapture AND AVH.GLJournalId IS NOT NULL AND AVH.IsAccounted = 1 AND AVH.IsLessorOwned = 1
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
JOIN #SyndicationDetailsTemp SyndicationDetail ON Contract.LeaseContractType = @OperatingContractSubType AND Contract.ContractId = SyndicationDetail.ContractId AND SyndicationDetail.IsServiced = 1
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
/*Capital Lease Contract Receivable*/ /*Financing Contract Receivable*/ -- CE
;WITH CTE_CapitalLeaseReceivable AS
(SELECT ContractDateInfo.ContractId
,SUM(ReceivableDetail.Amount_Amount) AS Amount
,ReceivableDetail.IsFinanceComponent
FROM #BasicDetails ContractDateInfo
JOIN #ReceivableDetailsTemp ReceivableDetail ON ContractDateInfo.ContractId = ReceivableDetail.ContractId
AND ReceivableDetail.ReceivableType IN (@CapitalLeaseRental,@OperatingLeaseRental,@LeasePayOff,@BuyOut)
AND ReceivableDetail.IsGLPosted = 0 AND ReceivableDetail.FunderId IS NULL
WHERE (ReceivableDetail.ReceivableType <> @OperatingLeaseRental OR ReceivableDetail.IsFinanceComponent = 1)
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
FROM #BasicDetails ContractDateInfo
JOIN #SyndicationDetailsTemp SyndicationDetail ON ContractDateInfo.ContractId = SyndicationDetail.ContractId AND SyndicationDetail.IsServiced =1
JOIN #ReceivableDetailsTemp ReceivableDetail ON SyndicationDetail.ContractId = ReceivableDetail.ContractId AND ReceivableDetail.ReceivableType IN (@CapitalLeaseRental,@LeasePayOff,@BuyOut)
AND ReceivableDetail.FunderId IS NOT NULL
AND ((SyndicationDetail.IsCollected = 1 AND ReceivableDetail.IsGLPosted = 0) OR (SyndicationDetail.IsCollected = 0 AND ReceivableDetail.DueDate > @IncomeDate))
AND (ContractDateInfo.IsChargedOff = 0 OR ReceivableDetail.PaymentStartDate < ContractDateInfo.ChargeOffDate)
GROUP BY ReceivableDetail.ContractId)
UPDATE #RNITemp
SET SyndicatedCapitalLeaseContractReceivable_Amount =  ISNULL(Receivable.Amount,0)
FROM #RNITemp RNI
LEFT JOIN CTE_SyndicatedCapitalLeaseReceivable Receivable ON RNI.ContractId = Receivable.ContractId AND Receivable.IsFinanceComponent = 0
END;
/*Unguaranteed Residual,Customer Guaranteed Residual, Third Party Guaranteed residual*/
/*Finance Unguaranteed Residual,Finance Customer Guaranteed Residual, Finance Third Party Guaranteed residual*/
/*Capital Lease Rent OSAR*/ -- CE /*Finance Lease Rent OSAR*/ -- CE
;WITH CTE_CapitalLeaseRent AS
(SELECT Contract.ContractId
,SUM(ReceivableDetail.Balance_Amount) AS LeaseRentAmount
,ReceivableDetail.IsFinanceComponent
FROM #LeaseDetails Contract
JOIN #ReceivableDetailsTemp ReceivableDetail ON Contract.IsChargedOff = 0  AND Contract.ContractId = ReceivableDetail.ContractId
AND ReceivableDetail.ReceivableType IN (@CapitalLeaseRental,@OperatingLeaseRental,@LeasePayOff,@BuyOut)
AND (ReceivableDetail.ReceivableType <> @OperatingLeaseRental OR ReceivableDetail.IsFinanceComponent = 1)
AND ReceivableDetail.FunderId IS NULL AND ReceivableDetail.IsGLPosted = 1
GROUP BY Contract.ContractId,ReceivableDetail.IsFinanceComponent)
UPDATE #RNITemp SET CapitalLeaseRentOSAR_Amount =  ISNULL(OSAR.LeaseRentAmount,0.00),
FinancingRentOSAR_Amount = ISNULL(FinanceOSAR.LeaseRentAmount,0.00)
FROM #RNITemp RNI
LEFT JOIN CTE_CapitalLeaseRent OSAR ON RNI.ContractId = OSAR.ContractId AND OSAR.IsFinanceComponent = 0
LEFT JOIN CTE_CapitalLeaseRent FinanceOSAR ON RNI.ContractId = FinanceOSAR.ContractId AND FinanceOSAR.IsFinanceComponent = 1;
/*Syndicated Capital Lease Rent OSAR*/-- CE /*Syndicated Finance Lease Rent OSAR*/-- CE
IF EXISTS(SELECT 1 FROM #SyndicationDetailsTemp WHERE IsServiced = 1)
BEGIN
;WITH CTE_SyndicatedLeaseRent AS
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
AND ReceivableDetail.AccountingTreatment IN (@CashBasedAccountingTreatment, @AccrualBased)
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
JOIN #ReceivableDetailsTemp Receivable ON SyndicationDetail.ContractId = Receivable.ContractId
AND Receivable.ReceivableType IN (@OverTermRental, @Supplemental) AND Receivable.FunderId IS NOT NULL
AND ((SyndicationDetail.IsCollected = 1 AND Receivable.IsGLPosted = 1) OR (SyndicationDetail.IsCollected = 0 AND Receivable.DueDate <= @IncomeDate))
GROUP BY Receivable.ContractId)
UPDATE #RNITemp
SET SyndicatedFixedTermReceivablesOSAR_Amount = SyndicatedFixedTermReceivablesOSAR_Amount + OSAR.SyndicatedOverTermRentAmount
FROM #RNITemp RNI
JOIN CTE_SyndicatedOverTermRentOSAR OSAR ON RNI.ContractId = OSAR.ContractId;
END
/*Prepaid Receivables*/ -- CE
/*Syndicated Prepaid Receivables*/ -- CE
;WITH CTE_ReceivableInfo AS
(SELECT Receivable.ContractId
,SUM(CASE WHEN FunderId IS NULL THEN Receivable.Amount_Amount - Receivable.Balance_Amount ELSE 0.00 END) AS ReceivableAmount
,SUM(CASE WHEN FunderId IS NOT NULL THEN Receivable.Amount_Amount - Receivable.Balance_Amount ELSE 0.00 END) AS SyndicatedReceivableAmount
FROM #BasicDetails Contract
JOIN #ReceivableDetailsTemp Receivable ON Contract.ContractId = Receivable.ContractId AND Receivable.Amount_Amount != Receivable.Balance_Amount
AND Receivable.IsGLPosted = 0 AND Receivable.IsDummy = 0 AND Receivable.FunderId IS NULL
AND Receivable.ReceivableType IN (@InterimRental,@CapitalLeaseRental,@OperatingLeaseRental,@LeaseFloatRateAdj, @OverTermRental,@LeasePayOff,@BuyOut, @LeaseInterimInterest, @LoanPrincipal,@LeveragedLeaseRental)
AND (Contract.IsChargedOff = 0 OR Receivable.PaymentStartDate < Contract.ChargeOffDate)
GROUP BY Receivable.ContractId,Receivable.FunderId)
UPDATE #RNITemp
SET PrepaidReceivables_Amount = PrepaidReceivable.ReceivableAmount,
SyndicatedPrepaidReceivables_Amount = PrepaidReceivable.SyndicatedReceivableAmount
FROM #RNITemp RNI
JOIN CTE_ReceivableInfo PrepaidReceivable ON RNI.ContractId = PrepaidReceivable.ContractId;
/*Prepaid Receivables*//*Sales Tax OSAR*//*Syndicated Sales Tax OSAR*/ -- CE
;WITH CTE_ReceivableSalesTax AS
(SELECT Contract.ContractId
,ReceivableTaxDetails.IsGLPosted
,SUM(CASE WHEN ReceivableInfo.FunderId IS NOT NULL THEN ReceivableTaxDetails.Balance_Amount ELSE 0.00 END) AS SyndicatedSalesTaxOSARAmount
,SUM(CASE WHEN ReceivableInfo.FunderId IS NULL THEN ReceivableTaxDetails.Balance_Amount ELSE 0.00 END) AS SalesTaxOSARAmount
,SUM(ReceivableTaxDetails.Amount_Amount - ReceivableTaxDetails.Balance_Amount) AS PrepaidSalesTaxAmount
FROM #LeaseDetails Contract
JOIN (SELECT DISTINCT ReceivableId,ContractId,PaymentStartDate,FunderId FROM #ReceivableDetailsTemp WHERE AccountingTreatment = @AccrualBased) AS ReceivableInfo ON Contract.ContractId = ReceivableInfo.ContractId
JOIN ReceivableTaxes ON ReceivableInfo.ReceivableId = ReceivableTaxes.ReceivableId AND ReceivableTaxes.IsActive=1
JOIN ReceivableTaxDetails ON ReceivableTaxes.Id = ReceivableTaxDetails.ReceivableTaxId AND (ReceivableTaxDetails.IsGLPosted = 1 OR ReceivableTaxDetails.Amount_Amount != ReceivableTaxDetails.Balance_Amount)
JOIN LegalEntities LegalEntity ON Contract.LegalEntityId = LegalEntity.Id
LEFT JOIN #SyndicationDetailsTemp SyndicationDetail ON Contract.ContractId = SyndicationDetail.ContractId
WHERE @AccrualBased = (CASE WHEN (Contract.IsChargedOff =1 OR (SyndicationDetail.ContractId IS NOT NULL AND ReceivableInfo.PaymentStartDate >= SyndicationDetail.SyndicationEffectiveDate))
THEN Contract.SalesTaxRemittanceMethod ELSE LegalEntity.TaxRemittancePreference END)
GROUP BY Contract.ContractId,ReceivableTaxDetails.IsGLPosted)
UPDATE #RNITemp
SET PrepaidReceivables_Amount = PrepaidReceivables_Amount + ISNULL(PrepaidSalesTaxOSAR.PrepaidSalesTaxAmount,0.00),
SalesTaxOSAR_Amount = ISNULL(SalesTaxOSAR.SalesTaxOSARAmount,0.00),
SyndicatedSalesTaxOSAR_Amount = ISNULL(SalesTaxOSAR.SyndicatedSalesTaxOSARAmount,0.00)
FROM #RNITemp RNI
LEFT JOIN CTE_ReceivableSalesTax PrepaidSalesTaxOSAR ON RNI.ContractId = PrepaidSalesTaxOSAR.ContractId AND PrepaidSalesTaxOSAR.IsGLPosted = 0
LEFT JOIN CTE_ReceivableSalesTax SalesTaxOSAR ON RNI.ContractId = SalesTaxOSAR.ContractId AND SalesTaxOSAR.IsGLPosted = 1;
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
END
/*Used Amount Calculation*/
IF @IsRevolving = 0
BEGIN
SELECT
ISNULL(SUM(dbo.GetMaxValue(0,UsedAmount)),0.00) UsedAmount
FROM
(
SELECT
ContractDetails.ContractId
,CASE WHEN (Contract.ContractType=@ProgressLoanContractType)
THEN RNI.ProgressFundings_Amount - RNI.ProgressPaymentCredits_Amount
WHEN (Contract.ContractType != @ProgressLoanContractType)
THEN RNI.TotalFinancedAmountLOC_Amount
END UsedAmount
FROM #RNITemp RNI
JOIN (SELECT ContractId,LeaseContractType,IsInOTP,CAST(0 AS BIT) AS IsDSL FROM #LeaseDetails
UNION
SELECT ContractId,@Unknown AS LeaseContractType,CAST(0 AS BIT) AS IsInOTP,IsDSL FROM #LoanDetails)
ContractDetails ON RNI.ContractId = ContractDetails.ContractId
JOIN Contracts Contract ON RNI.ContractId = Contract.Id
LEFT JOIN #SyndicationDetailsTemp Syndication ON RNI.ContractId = Syndication.ContractId
) A
END
ELSE
BEGIN
SELECT
ISNULL(SUM(dbo.GetMaxValue(0,UsedAmount)),0.00) UsedAmount
FROM
(
SELECT
ContractDetails.ContractId
,CASE WHEN (Contract.ContractType=@ProgressLoanContractType)
THEN RNI.ProgressFundings_Amount - RNI.ProgressPaymentCredits_Amount
WHEN (Contract.ContractType=@LoanContractType AND Contract.Status=@UnCommencedStatus)
THEN RNI.TotalFinancedAmountLOC_Amount
WHEN (Contract.ContractType = @Lease AND Contract.Status=@UnCommencedStatus)
THEN RNI.TotalFinancedAmountLOC_Amount
WHEN (Contract.ContractType=@LoanContractType AND (Contract.Status=@CommencedStatus OR Contract.Status=@FullyPaidOff))
THEN CASE WHEN ISNULL(Syndication.RetainedPercentage,0) != 100 AND ISNULL(Syndication.RetainedPercentage,0) != 0 THEN ((RNI.PrincipalBalance_Amount*100)/ISNULL(Syndication.RetainedPercentage,0))
ELSE RNI.PrincipalBalance_Amount END
+ PrincipalBalanceAdjustment_Amount
- RNI.NetWritedowns_Amount
+ RNI.LoanPrincipleOSAR_Amount
+ RNI.LoanInterestOSAR_Amount
- RNI.PrepaidReceivables_Amount
- RNI.UnappliedCash_Amount
+ RNI.SyndicatedFixedTermReceivablesOSAR_Amount
- RNI.SyndicatedPrepaidReceivables_Amount
WHEN (Contract.ContractType = @Lease AND ContractDetails.LeaseContractType = @OperatingContractSubType
AND (Contract.Status =@CommencedStatus OR Contract.Status=@FullyPaidOff))
THEN RNI.OperatingLeaseAssetGrossCost_Amount
- RNI.AccumulatedDepreciation_Amount
+ RNI.OperatingLeaseRentOSAR_Amount
+ RNI.FloatRateAdjustmentOSAR_Amount
- RNI.UnappliedCash_Amount
+ RNI.SyndicatedFixedTermReceivablesOSAR_Amount
- RNI.SyndicatedPrepaidReceivables_Amount
- RNI.PrepaidReceivables_Amount
+ RNI.FinanceSyndicatedFixedTermReceivablesOSAR_Amount
+ RNI.FinancingContractReceivable_Amount
+ RNI.FinancingRentOSAR_Amount
- RNI.FinanceIncomeAccrualBalance_Amount
+ (CASE WHEN ContractDetails.IsInOTP = 1 THEN RNI.OverTermRentOSAR_Amount - RNI.OTPResidualRecapture_Amount ELSE 0.00 END)
WHEN (Contract.ContractType = @Lease AND ContractDetails.LeaseContractType <> @OperatingContractSubType
AND (Contract.Status = @CommencedStatus OR Contract.Status=@FullyPaidOff))
THEN RNI.CapitalLeaseContractReceivable_Amount
+ RNI.CapitalLeaseRentOSAR_Amount
+ (CASE WHEN ContractDetails.IsInOTP = 1 THEN RNI.OverTermRentOSAR_Amount - RNI.OTPResidualRecapture_Amount ELSE 0.00 END)
+ RNI.FloatRateAdjustmentOSAR_Amount
- RNI.UnappliedCash_Amount
+ RNI.SyndicatedFixedTermReceivablesOSAR_Amount
+ RNI.FinanceSyndicatedFixedTermReceivablesOSAR_Amount
+ RNI.FinancingContractReceivable_Amount
+ RNI.FinancingRentOSAR_Amount
- IncomeAccrualBalance_Amount
- FinanceIncomeAccrualBalance_Amount
- RNI.PrepaidReceivables_Amount
- RNI.SyndicatedPrepaidReceivables_Amount
END AS UsedAmount
FROM #RNITemp RNI
JOIN (SELECT ContractId,LeaseContractType,IsInOTP,CAST(0 AS BIT) AS IsDSL FROM #LeaseDetails
UNION
SELECT ContractId,@Unknown AS LeaseContractType,CAST(0 AS BIT) AS IsInOTP,IsDSL FROM #LoanDetails)
AS ContractDetails ON RNI.ContractId = ContractDetails.ContractId
JOIN Contracts Contract ON RNI.ContractId = Contract.Id
LEFT JOIN #SyndicationDetailsTemp Syndication ON RNI.ContractId = Syndication.ContractId
) A
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
IF OBJECT_ID('tempdb..#LeaseDetails') IS NOT NULL
DROP TABLE #LeaseDetails
IF OBJECT_ID('tempdb..#LoanDetails') IS NOT NULL
DROP TABLE #LoanDetails
SET NOCOUNT OFF;
END

GO

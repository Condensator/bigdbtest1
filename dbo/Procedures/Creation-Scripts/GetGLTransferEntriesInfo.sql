SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetGLTransferEntriesInfo]
@EffectiveDate DATE,
@MovePLBalance BIT,
@PLEffectiveDate DATE = NULL,
@SyndicationActualProceeds NVARCHAR(500),
@AccumulateDepreciationForDFL BIT,
@IncludeGuaranteedResidualinLongTermReceivables BIT,
@ExcludeSalesTaxPayableDuringGLTransfer BIT,
@DeferInterimInterestIncomeRecognition BIT,
@DeferInterimInterestIncomeRecognitionForSingleInstallment BIT,
@DeferInterimRentIncomeRecognition BIT,
@DeferInterimRentIncomeRecognitionForSingleInstallment BIT,
@UseTaxBooks BIT,
@ContractIds ContractIdCollection READONLY,
@IsGLTransferFromReAccrual BIT,
@IsReamortizationBlendedIncomeRecoveryMethod BIT,
@IsReamortizationBlendedExpenseRecoveryMethod BIT,
@InterimRent NVARCHAR(50)
AS
BEGIN
SET NOCOUNT ON;

CREATE TABLE #GLSummary
(
ContractId BIGINT,
GLTransactionType NVARCHAR(56),
GLTemplateId BIGINT,
GLEntryItem NVARCHAR(100),
Amount DECIMAL(16,2),
IsDebit BIT,
MatchingGLTemplateId BIGINT,
MatchingFilter NVARCHAR(80),
InstrumentTypeId BIGINT,
LineofBusinesssId BIGINT,
CostCenterId BIGINT,
LegalEntityId BIGINT
);
CREATE TABLE #ContractInfo
(
ContractId BIGINT PRIMARY KEY,
CurrencyId BIGINT,
IsChargedoff BIT,
IsNonAccrual BIT,
ContractType NVARCHAR(28),
IncomeGLPostedTillDate DATE NULL,
FloatRateIncomeGLPostedTillDate DATE NULL,
BlendedIncomeGLPostedTillDate DATE NULL,
IsFASBChangesApplicable BIT,
NonAccrualDate DATE
);
CREATE TABLE #ReceivableForTransfers(Id BIGINT,ContractId BIGINT,LeaseFinanceId BIGINT,LoanFinanceId BIGINT,SoldNBV_Amount DECIMAL(16,2),SoldInterestAccrued_Amount DECIMAL(16,2),RetainedPercentage DECIMAL(18,8),EffectiveDate DATE);
CREATE TABLE #DeferredServicingFee(ContractId BIGINT,DeferredServicingFee DECIMAL(16,2));
CREATE TABLE #FAS91ReceivableIds(ContractId BIGINT,ReceivableId BIGINT);
INSERT INTO #ContractInfo (ContractId,CurrencyId,IsChargedoff,IsNonAccrual,ContractType,IsFASBChangesApplicable,NonAccrualDate)
SELECT
C.ContractId
,Contracts.CurrencyId
,CASE WHEN Contracts.ChargeOffStatus <> '_' THEN 1 ELSE 0 END AS IsChargedOff
,Contracts.IsNonAccrual
,Contracts.ContractType
,CASE WHEN Contracts.ContractType = 'Lease' AND Contracts.AccountingStandard <> 'ASC840_IAS17' THEN 1 ELSE 0 END AS IsFASBChangesApplicable
,Contracts.NonAccrualDate
FROM @ContractIds C
JOIN Contracts ON C.ContractId = Contracts.Id
INSERT INTO #ReceivableForTransfers
SELECT ReceivableForTransfers.Id,ReceivableForTransfers.ContractId,ReceivableForTransfers.LeaseFinanceId,ReceivableForTransfers.LoanFinanceId,ReceivableForTransfers.SoldNBV_Amount,ReceivableForTransfers.SoldInterestAccrued_Amount, ReceivableForTransfers.RetainedPercentage, ReceivableForTransfers.EffectiveDate
FROM
(SELECT ContractInfo.ContractId,MIN(ReceivableForTransfers.Id) ReceivableForTransferId
FROM #ContractInfo ContractInfo
JOIN ReceivableForTransfers ON ContractInfo.ContractId = ReceivableForTransfers.ContractId
WHERE ReceivableForTransfers.ApprovalStatus = 'Approved'
GROUP BY ContractInfo.ContractId) AS Temp
JOIN ReceivableForTransfers ON Temp.ReceivableForTransferId = ReceivableForTransfers.Id
IF EXISTS(SELECT ContractId FROM #ContractInfo ContractInfo WHERE IncomeGLPostedTillDate IS NULL)
BEGIN
UPDATE ContractInfo
SET IncomeGLPostedTillDate = Info.IncomeDate
FROM #ContractInfo ContractInfo
JOIN(SELECT ContractInfo.ContractId,MAX(LeaseIncomeSchedules.IncomeDate) IncomeDate
FROM #ContractInfo ContractInfo
JOIN LeaseFinances ON ContractInfo.ContractType = 'Lease' AND ContractInfo.ContractId = LeaseFinances.ContractId
JOIN LeaseIncomeSchedules ON LeaseFinances.Id = LeaseIncomeSchedules.LeaseFinanceId AND LeaseIncomeSchedules.IsAccounting=1 AND LeaseIncomeSchedules.IsGLPosted=1
WHERE LeaseIncomeSchedules.AdjustmentEntry=0 AND LeaseIncomeSchedules.IncomeDate <= @EffectiveDate
GROUP BY ContractInfo.ContractId
UNION
SELECT ContractInfo.ContractId,MAX(LoanIncomeSchedules.IncomeDate) IncomeDate
FROM #ContractInfo ContractInfo
JOIN LoanFinances ON ContractInfo.ContractType IN('Loan','ProgressLoan') AND ContractInfo.ContractId = LoanFinances.ContractId
JOIN LoanIncomeSchedules ON LoanFinances.Id = LoanIncomeSchedules.LoanFinanceId AND LoanIncomeSchedules.IsAccounting=1 AND LoanIncomeSchedules.IsGLPosted=1
WHERE LoanIncomeSchedules.AdjustmentEntry=0 AND LoanIncomeSchedules.IncomeDate <= @EffectiveDate
GROUP BY ContractInfo.ContractId
UNION
SELECT ContractInfo.ContractId,MAX(LeveragedLeaseAmorts.IncomeDate) IncomeDate
FROM #ContractInfo ContractInfo
JOIN LeveragedLeases ON ContractInfo.ContractType = 'LeveragedLease' AND ContractInfo.ContractId = LeveragedLeases.ContractId
JOIN LeveragedLeaseAmorts ON LeveragedLeases.Id = LeveragedLeaseAmorts.LeveragedLeaseId AND LeveragedLeaseAmorts.IsActive=1 AND LeveragedLeaseAmorts.IsGLPosted=1 AND LeveragedLeaseAmorts.IncomeDate <= @EffectiveDate
GROUP BY ContractInfo.ContractId)
AS Info ON ContractInfo.ContractId = Info.ContractId
IF EXISTS(SELECT ContractId FROM #ContractInfo ContractInfo WHERE ContractType = 'Lease' AND IncomeGLPostedTillDate IS NULL)
BEGIN
UPDATE ContractInfo
SET IncomeGLPostedTillDate = CAST(DATEADD(DAY, -1, Info.IncomeDate) AS DATE)
FROM #ContractInfo ContractInfo
JOIN (SELECT ContractInfo.ContractId,
CASE WHEN LeaseFinanceDetails.InterimAssessmentMethod <> '_' THEN CASE WHEN MIN(ISNULL(LeaseAssets.InterimInterestStartDate,CommencementDate)) <= MIN(ISNULL(LeaseAssets.InterimRentStartDate,CommencementDate))
THEN MIN(ISNULL(LeaseAssets.InterimInterestStartDate,CommencementDate))
ELSE MIN(ISNULL(LeaseAssets.InterimRentStartDate,CommencementDate))
END
ELSE LeaseFinanceDetails.CommencementDate END AS IncomeDate
FROM #ContractInfo ContractInfo
JOIN LeaseFinances ON ContractInfo.ContractId = LeaseFinances.ContractId AND LeaseFinances.IsCurrent=1 AND ContractInfo.IncomeGLPostedTillDate IS NULL
JOIN LeaseAssets ON LeaseFinances.Id = LeaseAssets.LeaseFinanceId AND LeaseAssets.IsActive=1
JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
GROUP BY ContractInfo.ContractId,LeaseFinanceDetails.InterimAssessmentMethod,LeaseFinanceDetails.CommencementDate)	AS Info ON 	ContractInfo.ContractId = Info.ContractId
END
IF EXISTS(SELECT ContractId FROM #ContractInfo ContractInfo WHERE ContractType = 'LeveragedLease' AND IncomeGLPostedTillDate IS NULL)
BEGIN
UPDATE ContractInfo
SET IncomeGLPostedTillDate = CAST(DATEADD(DAY, -1, LeveragedLeases.CommencementDate) AS DATE)
FROM #ContractInfo ContractInfo
JOIN LeveragedLeases ON ContractInfo.ContractId = LeveragedLeases.ContractId AND LeveragedLeases.IsCurrent=1
WHERE ContractInfo.IncomeGLPostedTillDate IS NULL
END
IF EXISTS(SELECT ContractId FROM #ContractInfo ContractInfo WHERE ContractType IN('Loan','ProgressLoan') AND IncomeGLPostedTillDate IS NULL)
BEGIN
UPDATE ContractInfo
SET IncomeGLPostedTillDate = CAST(DATEADD(DAY, -1, Info.IncomeDate) AS DATE)
FROM #ContractInfo ContractInfo
JOIN (SELECT ContractInfo.ContractId,
CASE WHEN ContractInfo.ContractType = 'ProgressLoan' THEN MIN(PayableInvoiceOtherCosts.InterimInterestStartDate)
WHEN ContractInfo.ContractType = 'Loan' THEN CASE WHEN LoanFinances.InterimBillingType <> '_' AND MIN(ISNULL(PayableInvoiceOtherCosts.InterimInterestStartDate,CommencementDate)) <= CommencementDate
THEN MIN(ISNULL(PayableInvoiceOtherCosts.InterimInterestStartDate,CommencementDate)) ELSE CommencementDate END
END AS IncomeDate
FROM #ContractInfo ContractInfo
JOIN LoanFinances ON ContractInfo.ContractId = LoanFinances.ContractId AND LoanFinances.IsCurrent=1 AND ContractInfo.IncomeGLPostedTillDate IS NULL
JOIN LoanFundings ON LoanFinances.Id = LoanFundings.LoanFinanceId AND LoanFundings.IsActive=1
JOIN PayableInvoices ON LoanFundings.FundingId = PayableInvoices.Id
JOIN PayableInvoiceOtherCosts ON PayableInvoices.Id = PayableInvoiceOtherCosts.PayableInvoiceId AND PayableInvoiceOtherCosts.AllocationMethod = 'LoanDisbursement'
GROUP BY ContractInfo.ContractId,LoanFinances.InterimBillingType,LoanFinances.CommencementDate,ContractInfo.ContractType) AS Info ON ContractInfo.ContractId = Info.ContractId
END
END

IF EXISTS(SELECT ContractId FROM #ContractInfo ContractInfo WHERE ContractInfo.ContractType = 'Lease' AND FloatRateIncomeGLPostedTillDate IS NULL )
BEGIN
UPDATE ContractInfo
SET FloatRateIncomeGLPostedTillDate = Info.IncomeDate
FROM #ContractInfo ContractInfo
JOIN(SELECT ContractInfo.ContractId,MAX(LeaseFloatRateIncomes.IncomeDate) IncomeDate
FROM #ContractInfo ContractInfo
JOIN LeaseFinances ON ContractInfo.ContractType = 'Lease' AND ContractInfo.ContractId = LeaseFinances.ContractId
JOIN LeaseFloatRateIncomes ON LeaseFinances.Id = LeaseFloatRateIncomes.LeaseFinanceId AND LeaseFloatRateIncomes.IsAccounting=1 AND LeaseFloatRateIncomes.IsGLPosted=1
WHERE LeaseFloatRateIncomes.AdjustmentEntry=0 AND LeaseFloatRateIncomes.IncomeDate <= @EffectiveDate
GROUP BY ContractInfo.ContractId) as Info on ContractInfo.ContractId = Info.ContractId
END

IF EXISTS(SELECT ContractId FROM #ContractInfo WHERE ContractType IN('Lease','Loan'))
BEGIN
UPDATE #ContractInfo
SET BlendedIncomeGLPostedTillDate = ISNULL(BlendedIncome.IncomeDate,#ContractInfo.IncomeGLPostedTillDate)
FROM #ContractInfo
LEFT JOIN (SELECT C.ContractId,MAX(BlendedIncomeSchedules.IncomeDate) IncomeDate
FROM #ContractInfo C
JOIN LeaseFinances ON C.ContractId = LeaseFinances.ContractId
JOIN BlendedIncomeSchedules ON LeaseFinances.Id = BlendedIncomeSchedules.LeaseFinanceId
WHERE BlendedIncomeSchedules.IsAccounting=1 AND BlendedIncomeSchedules.PostDate IS NOT NULL
AND BlendedIncomeSchedules.AdjustmentEntry=0
GROUP BY C.ContractId
UNION
SELECT C.ContractId,MAX(BlendedIncomeSchedules.IncomeDate) IncomeDate
FROM #ContractInfo C
JOIN LoanFinances ON C.ContractId = LoanFinances.ContractId
JOIN BlendedIncomeSchedules ON LoanFinances.Id = BlendedIncomeSchedules.LeaseFinanceId
WHERE BlendedIncomeSchedules.IsAccounting=1 AND BlendedIncomeSchedules.PostDate IS NOT NULL
AND BlendedIncomeSchedules.AdjustmentEntry=0
GROUP BY C.ContractId)
AS BlendedIncome ON #ContractInfo.ContractId = BlendedIncome.ContractId
END
CREATE TABLE #BlendedItemInfo
(
ContractId BIGINT,
BlendedItemId BIGINT,
BookRecognitionMode NVARCHAR(40),
BookingGLTemplateId BIGINT,
RecognitionGLTemplateId BIGINT,
AccumulateExpense BIT,
Type NVARCHAR(14),
GeneratePayableOrReceivable BIT,
Amount DECIMAL(16,2),
SystemConfigType NVARCHAR(36),
IsFAS91 BIT,
IsNonAccrual BIT,
IsChargedOffContract BIT,
ContractType NVARCHAR(28),
IncomeGLPostedTillDate DATE,
EntityType NVARCHAR(11),
IsReceivableForTransferBlendedItem BIT,
IsReamortizationRecoveryMethod BIT,
NonAccrualDate DATE
);
IF EXISTS(SELECT ContractId FROM #ContractInfo WHERE ContractType IN('Lease','Loan'))
BEGIN
IF EXISTS(SELECT ContractId FROM #ContractInfo WHERE ContractType = 'Lease')
BEGIN
INSERT INTO #BlendedItemInfo
SELECT
C.ContractId,
BlendedItems.Id BlendedItemId,
BlendedItems.BookRecognitionMode,
BlendedItems.BookingGLTemplateId,
BlendedItems.RecognitionGLTemplateId,
BlendedItems.AccumulateExpense,
BlendedItems.Type,
BlendedItems.GeneratePayableOrReceivable,
BlendedItems.Amount_Amount,
BlendedItems.SystemConfigType,
BlendedItems.IsFAS91,
C.IsNonAccrual,
C.IsChargedoff,
C.ContractType,
C.BlendedIncomeGLPostedTillDate,
BlendedItems.EntityType,
CAST(0 AS BIT) IsReceivableForTransferBlendedItem,
CASE WHEN BlendedItems.Type = 'Income' 
	Then @IsReamortizationBlendedIncomeRecoveryMethod 
	ELSE @IsReamortizationBlendedExpenseRecoveryMethod 
	END IsReamortizationRecoveryMethod,
C.NonAccrualDate
FROM (SELECT * FROM #ContractInfo ContractInfo WHERE ContractType IN('Lease')) AS C
JOIN LeaseFinances ON C.ContractId = LeaseFinances.ContractId AND LeaseFinances.IsCurrent=1
JOIN LeaseBlendedItems ON LeaseFinances.Id = LeaseBlendedItems.LeaseFinanceId
JOIN BlendedItems ON LeaseBlendedItems.BlendedItemId = BlendedItems.Id AND BlendedItems.IsActive=1 AND BlendedItems.IsETC = 0
LEFT JOIN BlendedItems ReclassifiedBlendedItem ON BlendedItems.Id = ReclassifiedBlendedItem.RelatedBlendedItemId AND ReclassifiedBlendedItem.IsActive=1
WHERE (BlendedItems.SystemConfigType IS NULL OR BlendedItems.SystemConfigType <> 'GLTransfer')
AND ReclassifiedBlendedItem.Id IS NULL
AND (C.IsChargedoff = 0 OR BlendedItems.SystemConfigType NOT IN ('ReAccrualIncome','ReAccrualRentalIncome','ReAccrualResidualIncome',
'ReAccrualFinanceIncome','ReAccrualFinanceResidualIncome','ReAccrualDeferredSellingProfitIncome'))
END
IF EXISTS(SELECT ContractId FROM #ContractInfo ContractInfo WHERE ContractType = 'Loan')
BEGIN
INSERT INTO #BlendedItemInfo
SELECT
C.ContractId,
BlendedItems.Id BlendedItemId,
BlendedItems.BookRecognitionMode,
BlendedItems.BookingGLTemplateId,
BlendedItems.RecognitionGLTemplateId,
BlendedItems.AccumulateExpense,
BlendedItems.Type,
BlendedItems.GeneratePayableOrReceivable,
BlendedItems.Amount_Amount,
BlendedItems.SystemConfigType,
BlendedItems.IsFAS91,
C.IsNonAccrual,
C.IsChargedoff,
C.ContractType,
C.BlendedIncomeGLPostedTillDate,
BlendedItems.EntityType,
CAST(0 AS BIT) IsReceivableForTransferBlendedItem,
CASE WHEN BlendedItems.Type = 'Income' 
	Then @IsReamortizationBlendedIncomeRecoveryMethod 
	ELSE @IsReamortizationBlendedExpenseRecoveryMethod 
	END IsReamortizationRecoveryMethod,
C.NonAccrualDate
FROM
(SELECT * FROM #ContractInfo ContractInfo WHERE ContractType IN('Loan')) AS C
JOIN LoanFinances ON C.ContractId = LoanFinances.ContractId AND LoanFinances.IsCurrent=1
JOIN LoanBlendedItems ON LoanFinances.Id = LoanBlendedItems.LoanFinanceId
JOIN BlendedItems ON LoanBlendedItems.BlendedItemId = BlendedItems.Id AND BlendedItems.IsActive=1
WHERE (BlendedItems.SystemConfigType IS NULL OR BlendedItems.SystemConfigType <> 'GLTransfer')
AND (C.IsChargedoff = 0 OR BlendedItems.SystemConfigType NOT IN ('ReAccrualIncome'))
END
INSERT INTO #BlendedItemInfo
SELECT
C.ContractId,
BlendedItems.Id BlendedItemId,
BlendedItems.BookRecognitionMode,
BlendedItems.BookingGLTemplateId,
BlendedItems.RecognitionGLTemplateId,
BlendedItems.AccumulateExpense,
BlendedItems.Type,
BlendedItems.GeneratePayableOrReceivable,
BlendedItems.Amount_Amount,
BlendedItems.SystemConfigType,
BlendedItems.IsFAS91,
C.IsNonAccrual,
C.IsChargedoff,
C.ContractType,
C.BlendedIncomeGLPostedTillDate,
BlendedItems.EntityType,
CAST(1 AS BIT) IsReceivableForTransferBlendedItem,
CASE WHEN BlendedItems.Type = 'Income' 
	Then @IsReamortizationBlendedIncomeRecoveryMethod 
	ELSE @IsReamortizationBlendedExpenseRecoveryMethod 
	END IsReamortizationRecoveryMethod,
C.NonAccrualDate
FROM #ContractInfo AS C
JOIN #ReceivableForTransfers R ON C.ContractId = R.ContractId
JOIN ReceivableForTransferBlendedItems ON R.Id = ReceivableForTransferBlendedItems.ReceivableForTransferId
JOIN BlendedItems ON ReceivableForTransferBlendedItems.BlendedItemId = BlendedItems.Id AND BlendedItems.IsActive=1 AND BlendedItems.IsETC = 0
LEFT JOIN BlendedItems ReclassifiedBlendedItem ON BlendedItems.Id = ReclassifiedBlendedItem.RelatedBlendedItemId AND ReclassifiedBlendedItem.IsActive=1
WHERE (BlendedItems.SystemConfigType IS NULL OR BlendedItems.SystemConfigType <> 'GLTransfer')
AND ReclassifiedBlendedItem.Id IS NULL
AND (C.IsChargedoff = 0 OR BlendedItems.SystemConfigType NOT IN ('ReAccrualIncome','ReAccrualRentalIncome','ReAccrualResidualIncome',
'ReAccrualFinanceIncome','ReAccrualFinanceResidualIncome','ReAccrualDeferredSellingProfitIncome'))
IF EXISTS(SELECT ContractId FROM #BlendedItemInfo WHERE SystemConfigType = 'SyndicationFee')
BEGIN
INSERT INTO #DeferredServicingFee
SELECT BlendedItems.ContractId,MAX(BlendedItems.Amount)
FROM #BlendedItemInfo BlendedItems
WHERE BlendedItems.SystemConfigType = 'SyndicationFee'
GROUP BY BlendedItems.ContractId
END
IF EXISTS(SELECT ContractId FROM #BlendedItemInfo WHERE IsChargedOffContract = 1 AND IsFAS91 = 1 AND Type = 'Income' AND GeneratePayableOrReceivable=1)
BEGIN
INSERT INTO #FAS91ReceivableIds
SELECT B.ContractId,Sundries.ReceivableId
FROM (SELECT * FROM #BlendedItemInfo WHERE IsChargedOffContract = 1 AND IsFAS91 = 1 AND Type = 'Income' AND GeneratePayableOrReceivable=1) B
JOIN BlendedItemDetails ON B.BlendedItemId = BlendedItemDetails.BlendedItemId AND BlendedItemDetails.IsActive=1
JOIN Sundries ON BlendedItemDetails.SundryId = Sundries.Id
GROUP BY B.ContractId,Sundries.ReceivableId
END
IF EXISTS(SELECT ContractId FROM #BlendedItemInfo)
BEGIN
CREATE TABLE #ReAccrualBlendedItemGLInfo
(
BlendedItemId BIGINT,
ContractId BIGINT,
BookingGLTemplateId BIGINT,
IncomeGLTemplateId BIGINT,
ARGLTemplateId BIGINT,
LeaseContractType NVARCHAR(32),
BookingGLTransactionType NVARCHAR(56),
IncomeGLTransactionType NVARCHAR(56),
DebitEntryItem NVARCHAR(100),
CreditEntryItem NVARCHAR(100),
SuspenseCreditEntryItem NVARCHAR(100)
);
CREATE TABLE #BlendedItemSundryInfo
(
ContractId BIGINT,
BlendedItemId BIGINT,
TotalGLPostedAmount DECIMAL(16,2)
);
CREATE TABLE #BlendedIncomeSchedules
(
ContractId BIGINT,
BlendedItemId BIGINT,
BookRecognitionMode NVARCHAR(40),
IncomeDate DATE,
Balance DECIMAL(16,2),
Income DECIMAL(16,2),
IsNonAccrual BIT
);
CREATE TABLE #BlendedItemAdjustmentInfo
(
ContractId BIGINT,
BlendedItemId BIGINT,
EffectiveDate DATE,
AmountClearedFromUnAmortizedExpense DECIMAL(16,2),
AdjustmentAmount DECIMAL(16,2)
);
CREATE TABLE #BlendedItemGLInfo
(
ContractId BIGINT,
BlendedItemId BIGINT,
RemainingBalance DECIMAL(16,2),
BlendedUnamortizedBalance DECIMAL(16,2),
ClearedUnamortizedAmount DECIMAL(16,2),
LatestRecordExists BIT,
IncomeRecognizedTillDate DECIMAL(16,2),
AdjustmentAmount DECIMAL(16,2)
);
CREATE TABLE #BlendedItemHierarchy 
(	
ContractId BIGINT,
BlendedParentId BIGINT,
BlendedChildId BIGINT
);
CREATE TABLE #ReAccrualDateInfo
(
ContractId BIGINT,
ReAccrualDate DATE,
NonAccrualDate DATE
);
CREATE TABLE #ReAccrualCatchupInfo
(
ContractId BIGINT,
BlendedItemId BIGINT,
IncomeDate DATE,
CatchupAmount DECIMAL(16,2)
);
INSERT INTO #ReAccrualDateInfo
SELECT ReAccrualContracts.ContractId,
MAX(ReAccrualContracts.ReAccrualDate),
MAX(ReAccrualContracts.NonAccrualDate)
FROM ReAccrualContracts
JOIN #ContractInfo C ON  ReAccrualContracts.ContractId = C.ContractId
WHERE ReAccrualDate <= @EffectiveDate
GROUP BY ReAccrualContracts.ContractId
INSERT INTO #ReAccrualCatchupInfo
SELECT
B.ContractId,
B.BlendedItemId,
BlendedIncomeSchedules.IncomeDate,
BlendedIncomeSchedules.Income_Amount 
FROM (SELECT * FROM #BlendedItemInfo WHERE BookRecognitionMode <> 'RecognizeImmediately') B
JOIN BlendedIncomeSchedules ON B.BlendedItemId = BlendedIncomeSchedules.BlendedItemId AND BlendedIncomeSchedules.IsSchedule=1
AND BlendedIncomeSchedules.AdjustmentEntry = 0
AND BlendedIncomeSchedules.IsNonAccrual = 1
AND BlendedIncomeSchedules.IncomeDate <= B.IncomeGLPostedTillDate
JOIN #ReAccrualDateInfo ON B.ContractId = #ReAccrualDateInfo.ContractId 
AND BlendedIncomeSchedules.IncomeDate < #ReAccrualDateInfo.ReAccrualDate
IF EXISTS(SELECT ContractId FROM #BlendedItemInfo WHERE ContractType = 'Lease')
BEGIN
INSERT INTO #ReAccrualBlendedItemGLInfo
SELECT
BlendedItems.BlendedItemId,
LeaseFinances.ContractId,
LeaseFinanceDetails.LeaseBookingGLTemplateId BookingGLTemplateId,
LeaseFinanceDetails.LeaseIncomeGLTemplateId IncomeGLTemplateId,
ReceivableCodes.GLTemplateId ARGLTemplateId,
LeaseFinanceDetails.LeaseContractType,
CASE WHEN LeaseContractType = 'Operating' THEN 'OperatingLeaseBooking' ELSE 'CapitalLeaseBooking' END BookingGLTransactionType,
CASE WHEN LeaseContractType = 'Operating' THEN 'OperatingLeaseIncome' ELSE 'CapitalLeaseIncome' END IncomeGLTransactionType,
CASE WHEN BlendedItems.SystemConfigType = 'ReAccrualIncome' THEN 'UnearnedIncome'
WHEN BlendedItems.SystemConfigType = 'ReAccrualRentalIncome' THEN 'DeferredRentalRevenue'
WHEN BlendedItems.SystemConfigType = 'ReAccrualResidualIncome' THEN 'UnearnedUnguaranteedResidualIncome'
WHEN BlendedItems.SystemConfigType = 'ReAccrualFinanceIncome' THEN 'FinancingUnearnedIncome'
WHEN BlendedItems.SystemConfigType = 'ReAccrualFinanceResidualIncome' THEN 'FinancingUnearnedUnguaranteedResidualIncome'
WHEN BlendedItems.SystemConfigType = 'ReAccrualDeferredSellingProfitIncome' THEN 'DeferredSellingProfit'
END AS DebitEntryItem,
CASE WHEN BlendedItems.SystemConfigType = 'ReAccrualIncome' THEN 'Income'
WHEN BlendedItems.SystemConfigType = 'ReAccrualRentalIncome' THEN 'RentalRevenue'
WHEN BlendedItems.SystemConfigType = 'ReAccrualResidualIncome' THEN 'UnguaranteedResidualIncome'
WHEN BlendedItems.SystemConfigType = 'ReAccrualFinanceIncome' THEN 'FinancingIncome'
WHEN BlendedItems.SystemConfigType = 'ReAccrualFinanceResidualIncome' THEN 'FinancingUnguaranteedResidualIncome'
WHEN BlendedItems.SystemConfigType = 'ReAccrualDeferredSellingProfitIncome' THEN 'SellingProfitIncome'
END AS CreditEntryItem,
CASE WHEN BlendedItems.SystemConfigType = 'ReAccrualIncome' THEN 'SuspendedIncome'
WHEN BlendedItems.SystemConfigType = 'ReAccrualRentalIncome' THEN 'SuspendedRentalRevenue'
WHEN BlendedItems.SystemConfigType = 'ReAccrualResidualIncome' THEN 'SuspendedUnguaranteedResidualIncome'
WHEN BlendedItems.SystemConfigType = 'ReAccrualFinanceIncome' THEN 'FinancingSuspendedIncome'
WHEN BlendedItems.SystemConfigType = 'ReAccrualFinanceResidualIncome' THEN 'FinancingSuspendedUnguaranteedResidualIncome'
WHEN BlendedItems.SystemConfigType = 'ReAccrualDeferredSellingProfitIncome' THEN 'SuspendedSellingProfitIncome'
END AS SuspenseCreditEntryItem
FROM
(SELECT * FROM #BlendedItemInfo
WHERE ContractType = 'Lease'
AND SystemConfigType IN ('ReAccrualIncome','ReAccrualRentalIncome','ReAccrualResidualIncome',
'ReAccrualFinanceIncome','ReAccrualFinanceResidualIncome','ReAccrualDeferredSellingProfitIncome'))
AS BlendedItems
JOIN LeaseBlendedItems ON BlendedItems.BlendedItemId = LeaseBlendedItems.BlendedItemId
JOIN LeaseFinances ON LeaseBlendedItems.LeaseFinanceId = LeaseFinances.Id AND LeaseFinances.IsCurrent = 1
JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
JOIN ReceivableCodes ON LeaseFinanceDetails.FixedTermReceivableCodeId = ReceivableCodes.Id
WHERE BlendedItems.ContractId = LeaseFinances.ContractId
INSERT INTO #BlendedItemAdjustmentInfo
SELECT B.ContractId
,B.BlendedItemId
,Payoffs.PayoffEffectiveDate
,CASE WHEN B.AccumulateExpense = 1 THEN PayoffBlendedItems.AccumulatedAdjustment_Amount ELSE PayoffBlendedItems.PayoffAdjustment_Amount END
,PayoffBlendedItems.PayoffAdjustment_Amount
FROM 
		(SELECT Distinct
			C.ContractId,
			BlendedItems.Id BlendedItemId,
			BlendedItems.AccumulateExpense
			FROM (SELECT * FROM #ContractInfo ContractInfo WHERE ContractType IN('Lease')) AS C
			JOIN LeaseFinances ON C.ContractId = LeaseFinances.ContractId 
			JOIN LeaseBlendedItems ON LeaseFinances.Id = LeaseBlendedItems.LeaseFinanceId
			JOIN BlendedItems ON LeaseBlendedItems.BlendedItemId = BlendedItems.Id AND BlendedItems.IsETC = 0
			LEFT JOIN BlendedItems ReclassifiedBlendedItem ON BlendedItems.Id = ReclassifiedBlendedItem.RelatedBlendedItemId 
			WHERE (BlendedItems.SystemConfigType IS NULL OR BlendedItems.SystemConfigType <> 'GLTransfer')
			AND ReclassifiedBlendedItem.Id IS NULL
			AND (C.IsChargedoff = 0 OR BlendedItems.SystemConfigType NOT IN ('ReAccrualIncome','ReAccrualRentalIncome','ReAccrualResidualIncome',
			'ReAccrualFinanceIncome','ReAccrualFinanceResidualIncome','ReAccrualDeferredSellingProfitIncome'))) B
JOIN PayoffBlendedItems ON B.BlendedItemId = PayoffBlendedItems.BlendedItemId AND PayoffBlendedItems.IsActive=1
JOIN Payoffs ON PayoffBlendedItems.PayoffId = Payoffs.Id AND Payoffs.Status = 'Activated'
IF EXISTS(SELECT ContractId FROM #BlendedItemInfo WHERE BookRecognitionMode <> 'RecognizeImmediately' AND ContractType = 'Lease')
BEGIN
INSERT INTO #BlendedIncomeSchedules
SELECT
B.ContractId,
B.BlendedItemId,
B.BookRecognitionMode,
BlendedIncomeSchedules.IncomeDate,
BlendedIncomeSchedules.IncomeBalance_Amount,
BlendedIncomeSchedules.Income_Amount,
BlendedIncomeSchedules.IsNonAccrual
FROM (SELECT * FROM #BlendedItemInfo WHERE BookRecognitionMode <> 'RecognizeImmediately' AND ContractType = 'Lease') B
JOIN BlendedIncomeSchedules ON B.BlendedItemId = BlendedIncomeSchedules.BlendedItemId AND BlendedIncomeSchedules.IsSchedule=1
AND BlendedIncomeSchedules.IncomeDate <= B.IncomeGLPostedTillDate AND BlendedIncomeSchedules.AdjustmentEntry = 0
JOIN LeaseFinances ON BlendedIncomeSchedules.LeaseFinanceId = LeaseFinances.Id AND LeaseFinances.ContractId = B.ContractId
END
IF EXISTS(SELECT ContractId FROM #BlendedItemInfo WHERE ContractType = 'Lease' AND (IsChargedOffContract = 0 OR IsFAS91=0) AND GeneratePayableOrReceivable = 1)
BEGIN
INSERT INTO #BlendedItemSundryInfo
SELECT BlendedItem.ContractId
,BlendedItem.BlendedItemId
,CASE WHEN BlendedItem.Type = 'Income' THEN SUM(Receivables.TotalAmount_Amount) ELSE SUM(Payables.Amount_Amount) END AS TotalGLPostedAmount
FROM (SELECT * FROM #BlendedItemInfo WHERE (IsChargedOffContract = 0 OR IsFAS91=0) AND GeneratePayableOrReceivable = 1 AND ContractType = 'Lease') AS BlendedItem
JOIN BlendedItemDetails ON BlendedItem.BlendedItemId = BlendedItemDetails.BlendedItemId AND BlendedItemDetails.IsActive=1
JOIN Sundries ON BlendedItemDetails.SundryId = Sundries.Id AND Sundries.IsActive=1
JOIN LeaseBlendedItems ON BlendedItem.BlendedItemId = LeaseBlendedItems.BlendedItemId
JOIN LeaseFinances ON LeaseBlendedItems.LeaseFinanceId = LeaseFinances.Id AND LeaseFinances.IsCurrent=1
LEFT JOIN Receivables ON Sundries.ReceivableId = Receivables.Id AND Receivables.IsActive=1
LEFT JOIN Payables ON Sundries.PayableId = Payables.Id AND Payables.Status<> 'Inactive'
WHERE ((BlendedItem.Type = 'Income' AND Receivables.IsGLPosted=1)
OR (BlendedItem.Type<>'Income' AND Payables.IsGLPosted=1))
GROUP BY BlendedItem.ContractId,BlendedItem.BlendedItemId,BlendedItem.BookingGLTemplateId,BlendedItem.Type
END
END
IF EXISTS(SELECT ContractId FROM #BlendedItemInfo WHERE ContractType <> 'Lease')
BEGIN
INSERT INTO #ReAccrualBlendedItemGLInfo
SELECT
BlendedItems.BlendedItemId,
LoanFinances.ContractId,
LoanFinances.LoanBookingGLTemplateId BookingGLTemplateId,
LoanFinances.LoanIncomeRecognitionGLTemplateId IncomeGLTemplateId,
NULL ARGLTemplateId,
NULL LeaseContractType,
'LoanBooking' BookingGLTransactionType,
'LoanIncomeRecognition' IncomeGLTransactionType,
'AccruedInterest' DebitEntryItem,
'InterestIncome' CreditEntryItem,
'SuspendedIncome' SuspenseCreditEntryItem
FROM (SELECT * FROM #BlendedItemInfo WHERE ContractType <> 'Lease' AND SystemConfigType IN ('ReAccrualIncome')) AS BlendedItems
JOIN LoanBlendedItems ON BlendedItems.BlendedItemId = LoanBlendedItems.BlendedItemId
JOIN LoanFinances ON LoanBlendedItems.LoanFinanceId = LoanFinances.Id AND LoanFinances.IsCurrent = 1
WHERE BlendedItems.ContractId = LoanFinances.ContractId
INSERT INTO #BlendedItemAdjustmentInfo
SELECT B.ContractId
,B.BlendedItemId
,LoanPaydowns.PaydownDate
,CASE WHEN B.AccumulateExpense = 1 THEN LoanPaydownBlendedItems.AccumulatedAdjustment_Amount ELSE LoanPaydownBlendedItems.PaydownCostAdjustment_Amount END
,LoanPaydownBlendedItems.PaydownCostAdjustment_Amount
FROM 
		(SELECT Distinct 
			C.ContractId,
			BlendedItems.Id BlendedItemId,
			BlendedItems.AccumulateExpense
		FROM
		(SELECT * FROM #ContractInfo ContractInfo WHERE ContractType IN('Loan')) AS C
			JOIN LoanFinances ON C.ContractId = LoanFinances.ContractId 
			JOIN LoanBlendedItems ON LoanFinances.Id = LoanBlendedItems.LoanFinanceId
			JOIN BlendedItems ON LoanBlendedItems.BlendedItemId = BlendedItems.Id
		WHERE (BlendedItems.SystemConfigType IS NULL OR BlendedItems.SystemConfigType <> 'GLTransfer')
		AND (C.IsChargedoff = 0 OR BlendedItems.SystemConfigType NOT IN ('ReAccrualIncome'))) B
JOIN LoanPaydownBlendedItems ON B.BlendedItemId = LoanPaydownBlendedItems.BlendedItemId AND LoanPaydownBlendedItems.IsActive=1
JOIN LoanPaydowns ON LoanPaydownBlendedItems.LoanPaydownId = LoanPaydowns.Id AND LoanPaydowns.Status = 'Active'
IF EXISTS(SELECT ContractId FROM #BlendedItemInfo WHERE BookRecognitionMode <> 'RecognizeImmediately' AND ContractType <> 'Lease')
BEGIN
INSERT INTO #BlendedIncomeSchedules
SELECT
B.ContractId,
B.BlendedItemId,
B.BookRecognitionMode,
BlendedIncomeSchedules.IncomeDate,
BlendedIncomeSchedules.IncomeBalance_Amount,
BlendedIncomeSchedules.Income_Amount,
BlendedIncomeSchedules.IsNonAccrual
FROM (SELECT * FROM #BlendedItemInfo WHERE BookRecognitionMode <> 'RecognizeImmediately' AND ContractType <> 'Lease') B
JOIN BlendedIncomeSchedules ON B.BlendedItemId = BlendedIncomeSchedules.BlendedItemId AND BlendedIncomeSchedules.IsSchedule=1
AND BlendedIncomeSchedules.IncomeDate <= B.IncomeGLPostedTillDate AND BlendedIncomeSchedules.AdjustmentEntry = 0
JOIN LoanFinances ON BlendedIncomeSchedules.LoanFinanceId = LoanFinances.Id AND LoanFinances.ContractId = B.ContractId
END
IF EXISTS(SELECT ContractId FROM #BlendedItemInfo WHERE ContractType <> 'Lease' AND (IsChargedOffContract = 0 OR IsFAS91=0) AND GeneratePayableOrReceivable = 1)
BEGIN
INSERT INTO #BlendedItemSundryInfo
SELECT BlendedItem.ContractId
,BlendedItem.BlendedItemId
,CASE WHEN BlendedItem.Type = 'Income' THEN SUM(Receivables.TotalAmount_Amount) ELSE SUM(Payables.Amount_Amount) END AS TotalGLPostedAmount
FROM (SELECT * FROM #BlendedItemInfo WHERE (IsChargedOffContract = 0 OR IsFAS91=0) AND GeneratePayableOrReceivable = 1 AND ContractType <> 'Lease') AS BlendedItem
JOIN BlendedItemDetails ON BlendedItem.BlendedItemId = BlendedItemDetails.BlendedItemId AND BlendedItemDetails.IsActive=1
JOIN Sundries ON BlendedItemDetails.SundryId = Sundries.Id AND Sundries.IsActive=1
JOIN LoanBlendedItems ON BlendedItem.BlendedItemId = LoanBlendedItems.BlendedItemId
JOIN LoanFinances ON LoanBlendedItems.LoanFinanceId = LoanFinances.Id AND LoanFinances.IsCurrent=1
LEFT JOIN Receivables ON Sundries.ReceivableId = Receivables.Id AND Receivables.IsActive=1
LEFT JOIN Payables ON Sundries.PayableId = Payables.Id AND Payables.Status<> 'Inactive'
WHERE ((BlendedItem.Type = 'Income' AND Receivables.IsGLPosted=1)
OR (BlendedItem.Type<>'Income' AND Payables.IsGLPosted=1))
GROUP BY BlendedItem.ContractId,BlendedItem.BlendedItemId,BlendedItem.BookingGLTemplateId,BlendedItem.Type
END
END
IF EXISTS (SELECT 1 FROM #BlendedItemAdjustmentInfo )
	BEGIN
		INSERT INTO #BlendedItemHierarchy
		SELECT DISTINCT 
		C.ContractId,
		BlendedItems.Id as BlendedParentId,
		BlendedItems.ParentBlendedItemId as BlendedChildId
		FROM (SELECT * FROM #ContractInfo ContractInfo WHERE ContractType IN('Lease')) AS C
		JOIN LeaseFinances ON C.ContractId = LeaseFinances.ContractId 
		JOIN LeaseBlendedItems ON LeaseFinances.Id = LeaseBlendedItems.LeaseFinanceId
		JOIN BlendedItems ON LeaseBlendedItems.BlendedItemId = BlendedItems.Id 
		UNION ALL
		SELECT DISTINCT 
		C.ContractId,
		BlendedItems.Id as BlendedParentId,
		BlendedItems.ParentBlendedItemId as BlendedChildId
		FROM (SELECT * FROM #ContractInfo ContractInfo WHERE ContractType IN('Loan')) AS C
		JOIN LoanFinances ON C.ContractId = LoanFinances.ContractId 
		JOIN LoanBlendedItems ON LoanFinances.Id = LoanBlendedItems.LoanFinanceId
		JOIN BlendedItems ON LoanBlendedItems.BlendedItemId = BlendedItems.Id
		IF EXISTS ( SELECT 1 FROM #BlendedItemHierarchy WHERE BlendedChildId IS NOT NULL)
		BEGIN
			;WITH BasicBI AS
			(
			SELECT  BlendedParentId, BlendedChildId, 1 AS Lvl FROM #BlendedItemHierarchy 
			WHERE BlendedChildId IS NOT NULL
			UNION ALL
			SELECT bitemp.BlendedParentId, bi.BlendedChildId, Lvl+1 AS Lvl 
			FROM #BlendedItemHierarchy bitemp
			INNER JOIN BasicBI bi ON bitemp.BlendedChildId = bi.BlendedParentId
			)
			,CTE_RowNum AS 
			(
			SELECT *, ROW_NUMBER() OVER (PARTITION BY BI.BlendedChildId ORDER BY BI.Lvl DESC) RowNum
			FROM BasicBI BI
			)
			UPDATE #BlendedItemAdjustmentInfo SET BlendedItemId = BH.BlendedParentId
			FROM (
			SELECT R.BlendedChildId, R.BlendedParentId
			FROM CTE_RowNum R
			WHERE RowNum =1
			) AS BH 
			JOIN #BlendedItemAdjustmentInfo BADJ on BH.BlendedChildId = BADJ.BlendedItemId
		END
	END
IF EXISTS(SELECT ContractId FROM #BlendedItemInfo WHERE BookRecognitionMode <> 'RecognizeImmediately' AND (IsChargedOffContract = 0 OR IsFAS91=0))
BEGIN
INSERT INTO #BlendedItemGLInfo
SELECT BlendedItem.ContractId
,BlendedItem.BlendedItemId
,CASE WHEN BlendedItem.EntityType = 'Syndication'
THEN BlendedItem.Amount - ISNULL(BlendedIncome.IncomeRecognizedTillDate,0) - ISNULL(ClearedUnamortizedAmountInfo.AmountClearedFromUnAmortizedExpense,0)
ELSE ISNULL(GLPostedBlendedItemDetail.Amount,0) - (ISNULL(BlendedIncome.IncomeRecognizedTillDate,0) - (CASE WHEN BlendedItem.IsReamortizationRecoveryMethod = 1 THEN ISNULL(ReAccrualCatchup.CatchupAmount,0) ELSE 0 END)) - ISNULL(ClearedUnamortizedAmountInfo.AmountClearedFromUnAmortizedExpense,0)
END AS RemainingBalance
,CASE WHEN (BlendedItem.Type <> 'Income' AND BlendedItem.BookRecognitionMode = 'Amortize' AND BlendedItem.AccumulateExpense = 1)
THEN ISNULL(GLPostedBlendedItemDetail.Amount,0) - ISNULL(ClearedUnamortizedAmountInfo.AmountClearedFromUnAmortizedExpense,0)
ELSE 0
END AS BlendedUnamortizedBalance
,ISNULL(ClearedUnamortizedAmountInfo.AmountClearedFromUnAmortizedExpense,0) ClearedUnamortizedAmount
,CASE WHEN BlendedIncome.BlendedItemId IS NOT NULL THEN 1 ELSE 0 END AS LatestRecordExists
,ISNULL(BlendedIncome.IncomeRecognizedTillDate,0) IncomeRecognizedTillDate
,ISNULL(ClearedUnamortizedAmountInfo.AdjustmentAmount,0) AdjustmentAmount
FROM (SELECT * FROM #BlendedItemInfo WHERE BookRecognitionMode <> 'RecognizeImmediately' AND (IsChargedOffContract = 0 OR IsFAS91=0)) BlendedItem
LEFT JOIN (SELECT
BlendedItemId,ContractId,
SUM(Income) IncomeRecognizedTillDate
FROM #BlendedIncomeSchedules
GROUP BY BlendedItemId,ContractId)
AS BlendedIncome ON BlendedItem.BlendedItemId = BlendedIncome.BlendedItemId AND BlendedItem.ContractId = BlendedIncome.ContractId
LEFT JOIN (SELECT
BlendedItemId,ContractId,
SUM(AmountClearedFromUnAmortizedExpense) AmountClearedFromUnAmortizedExpense,
SUM(AdjustmentAmount) AdjustmentAmount
FROM #BlendedItemAdjustmentInfo
GROUP BY BlendedItemId,ContractId)
AS ClearedUnamortizedAmountInfo ON BlendedItem.BlendedItemId = ClearedUnamortizedAmountInfo.BlendedItemId AND BlendedItem.ContractId = ClearedUnamortizedAmountInfo.ContractId
LEFT JOIN (SELECT
BlendedItem.ContractId,
BlendedItem.BlendedItemId,
SUM(BlendedItemDetails.Amount_Amount) Amount
FROM #BlendedItemInfo BlendedItem
JOIN BlendedItemDetails ON BlendedItem.BlendedItemId = BlendedItemDetails.BlendedItemId
AND BlendedItemDetails.IsActive=1 AND BlendedItemDetails.IsGLPosted=1
WHERE BlendedItem.BookRecognitionMode <> 'RecognizeImmediately'
AND (IsChargedOffContract = 0 OR IsFAS91=0)
GROUP BY BlendedItem.ContractId,BlendedItem.BlendedItemId)
AS GLPostedBlendedItemDetail ON BlendedItem.BlendedItemId = GLPostedBlendedItemDetail.BlendedItemId AND BlendedItem.ContractId = GLPostedBlendedItemDetail.ContractId
LEFT JOIN (Select BlendedItemId,ContractId, SUM(CatchupAmount) AS CatchupAmount FROM #ReAccrualCatchupInfo GROUP BY BlendedItemId,ContractId)
AS ReAccrualCatchup ON BlendedItem.BlendedItemId = ReAccrualCatchup.BlendedItemId AND BlendedItem.ContractId = ReAccrualCatchup.ContractId
END
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit,MatchingGLTemplateId)
SELECT BlendedItem.ContractId
,CASE WHEN BlendedItem.Type = 'Income' THEN 'BlendedIncomeSetup' ELSE 'BlendedExpenseSetup' END GLTransactionType
,BlendedItem.BookingGLTemplateId GLTemplateId
,CASE WHEN BlendedItem.Type = 'Income' THEN 'BlendedIncomeReceivable' ELSE 'BlendedExpensePayable' END GLEntryItem
,ISNULL(GLPostedBlendedItemDetail.Amount_Amount,0) - ISNULL(GLPostedSundryAmountInfo.TotalGLPostedAmount,0) Amount
,CASE WHEN BlendedItem.Type = 'Income' THEN 1 ELSE 0 END IsDebit
,NULL MatchingGLTemplateId
FROM (SELECT * FROM #BlendedItemInfo WHERE IsChargedOffContract = 0 OR IsFAS91=0) BlendedItem
LEFT JOIN #BlendedItemSundryInfo GLPostedSundryAmountInfo ON BlendedItem.BlendedItemId = GLPostedSundryAmountInfo.BlendedItemId AND BlendedItem.ContractId = GLPostedSundryAmountInfo.ContractId
LEFT JOIN (SELECT B.BlendedItemId,SUM(BlendedItemDetails.Amount_Amount) Amount_Amount
FROM #BlendedItemInfo B JOIN BlendedItemDetails ON B.BlendedItemId = BlendedItemDetails.BlendedItemId
AND BlendedItemDetails.IsActive=1 AND BlendedItemDetails.IsGLPosted=1
GROUP BY B.BlendedItemId)
AS GLPostedBlendedItemDetail ON BlendedItem.BlendedItemId = GLPostedBlendedItemDetail.BlendedItemId
LEFT JOIN #ReAccrualBlendedItemGLInfo ON BlendedItem.BlendedItemId = #ReAccrualBlendedItemGLInfo.BlendedItemId
WHERE (ISNULL(GLPostedBlendedItemDetail.Amount_Amount,0) - ISNULL(GLPostedSundryAmountInfo.TotalGLPostedAmount,0)) <> 0
AND #ReAccrualBlendedItemGLInfo.BlendedItemId IS NULL
--IF EXISTS(SELECT ContractId FROM #BlendedItemInfo WHERE ContractType = 'Lease')
--BEGIN
--	INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit,MatchingGLTemplateId)
--	SELECT BlendedItem.ContractId
--		,CASE WHEN BlendedItem.ContractType = 'Loan' OR BlendedItem.SystemConfigType = 'ReAccrualRentalIncome'
--			  THEN #ReAccrualBlendedItemGLInfo.IncomeGLTransactionType
--			  ELSE #ReAccrualBlendedItemGLInfo.BookingGLTransactionType END GLTransactionType
--		,CASE WHEN BlendedItem.ContractType = 'Loan' OR BlendedItem.SystemConfigType = 'ReAccrualRentalIncome'
--			  THEN #ReAccrualBlendedItemGLInfo.IncomeGLTemplateId
--			  ELSE #ReAccrualBlendedItemGLInfo.BookingGLTemplateId END GLTemplateId
--		,#ReAccrualBlendedItemGLInfo.DebitEntryItem GLEntryItem
--		,GLPostedBlendedItemDetail.Amount_Amount Amount
--		,CASE WHEN BlendedItem.ContractType = 'Loan' OR BlendedItem.SystemConfigType = 'ReAccrualRentalIncome' THEN 1 ELSE 0 END IsDebit
--		,CASE WHEN BlendedItem.SystemConfigType = 'ReAccrualRentalIncome' THEN #ReAccrualBlendedItemGLInfo.ARGLTemplateId
--			  WHEN BlendedItem.ContractType = 'Loan' THEN BlendedItem.BookingGLTemplateId
--			  ELSE NULL END MatchingGLTemplateId
--	FROM (SELECT * FROM #BlendedItemInfo WHERE BookRecognitionMode = 'RecognizeImmediately' AND ContractType = 'Lease' AND (IsChargedOffContract = 0 OR IsFAS91=0)) BlendedItem
--	JOIN (SELECT B.BlendedItemId,SUM(BlendedItemDetails.Amount_Amount) Amount_Amount
--			FROM #ReAccrualBlendedItemGLInfo B JOIN BlendedItemDetails ON B.BlendedItemId = BlendedItemDetails.BlendedItemId
--			AND BlendedItemDetails.IsActive=1 AND BlendedItemDetails.IsGLPosted=1 and B.LeaseContractType ='Operating'
--			GROUP BY B.BlendedItemId)
--	AS GLPostedBlendedItemDetail ON BlendedItem.BlendedItemId = GLPostedBlendedItemDetail.BlendedItemId
--	JOIN #ReAccrualBlendedItemGLInfo ON BlendedItem.BlendedItemId = #ReAccrualBlendedItemGLInfo.BlendedItemId
--	WHERE GLPostedBlendedItemDetail.Amount_Amount <> 0
--END
IF EXISTS(SELECT ContractId FROM #BlendedItemInfo WHERE BookRecognitionMode <> 'RecognizeImmediately' AND (IsChargedOffContract = 0 OR IsFAS91=0))
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit,MatchingGLTemplateId)
SELECT B.ContractId
,CASE WHEN #ReAccrualBlendedItemGLInfo.BlendedItemId IS NOT NULL
THEN CASE WHEN BlendedItem.ContractType = 'Loan' OR BlendedItem.SystemConfigType = 'ReAccrualRentalIncome'
THEN #ReAccrualBlendedItemGLInfo.IncomeGLTransactionType ELSE #ReAccrualBlendedItemGLInfo.BookingGLTransactionType END
ELSE 'BlendedIncomeSetup' END
,CASE WHEN #ReAccrualBlendedItemGLInfo.BlendedItemId IS NOT NULL
THEN CASE WHEN BlendedItem.ContractType = 'Loan' OR BlendedItem.SystemConfigType = 'ReAccrualRentalIncome'
THEN #ReAccrualBlendedItemGLInfo.IncomeGLTemplateId ELSE #ReAccrualBlendedItemGLInfo.BookingGLTemplateId END
ELSE BlendedItem.BookingGLTemplateId END
,CASE WHEN #ReAccrualBlendedItemGLInfo.BlendedItemId IS NOT NULL THEN #ReAccrualBlendedItemGLInfo.DebitEntryItem ELSE 'DeferredBlendedIncome' END
,CASE WHEN #ReAccrualBlendedItemGLInfo.BlendedItemId IS NOT NULL
THEN CASE WHEN BlendedItem.ContractType = 'Loan' OR BlendedItem.SystemConfigType = 'ReAccrualRentalIncome'
THEN B.RemainingBalance * (-1) ELSE B.RemainingBalance END
ELSE B.RemainingBalance END
,CASE WHEN #ReAccrualBlendedItemGLInfo.BlendedItemId IS NOT NULL
THEN CASE WHEN BlendedItem.ContractType = 'Loan' OR BlendedItem.SystemConfigType = 'ReAccrualRentalIncome'
THEN 1 ELSE 0 END
ELSE 0 END
,CASE WHEN #ReAccrualBlendedItemGLInfo.BlendedItemId IS NOT NULL
THEN CASE WHEN BlendedItem.SystemConfigType = 'ReAccrualRentalIncome' THEN #ReAccrualBlendedItemGLInfo.ARGLTemplateId
WHEN BlendedItem.ContractType = 'Loan' THEN #ReAccrualBlendedItemGLInfo.BookingGLTemplateId
ELSE NULL END
ELSE NULL END MatchingGLTemplateId
FROM #BlendedItemGLInfo B
JOIN #BlendedItemInfo BlendedItem ON B.BlendedItemId = BlendedItem.BlendedItemId
LEFT JOIN #ReAccrualBlendedItemGLInfo ON B.BlendedItemId = #ReAccrualBlendedItemGLInfo.BlendedItemId
WHERE BlendedItem.Type = 'Income' AND BlendedItem.BookRecognitionMode <> 'RecognizeImmediately'
AND B.RemainingBalance <> 0
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit,MatchingGLTemplateId)
SELECT B.ContractId
,'BlendedExpenseSetup'
,BlendedItem.BookingGLTemplateId
,CASE WHEN BlendedItem.BookRecognitionMode = 'Accrete' THEN 'BlendedAccumulatedExpenseAccrete' ELSE 'BlendedUnamortizedExpense' END
,B.RemainingBalance
,1
,NULL
FROM #BlendedItemGLInfo B
JOIN #BlendedItemInfo BlendedItem ON B.BlendedItemId = BlendedItem.BlendedItemId
WHERE BlendedItem.Type <> 'Income' AND (BlendedItem.BookRecognitionMode = 'Accrete' OR (BlendedItem.BookRecognitionMode = 'Amortize' AND BlendedItem.AccumulateExpense=0))
AND B.RemainingBalance <> 0
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit,MatchingGLTemplateId)
SELECT B.ContractId
,'BlendedExpenseSetup'
,BlendedItem.BookingGLTemplateId
,'BlendedUnamortizedExpense'
,B.BlendedUnamortizedBalance
,1
,NULL
FROM #BlendedItemGLInfo B
JOIN #BlendedItemInfo BlendedItem ON B.BlendedItemId = BlendedItem.BlendedItemId
WHERE BlendedItem.Type <> 'Income' AND BlendedItem.BookRecognitionMode = 'Amortize' AND BlendedItem.AccumulateExpense=1
AND B.BlendedUnamortizedBalance <> 0
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit,MatchingGLTemplateId)
SELECT B.ContractId
,'BlendedExpenseRecognition'
,BlendedItem.RecognitionGLTemplateId
,'BlendedAccumulatedExpense'
,B.ClearedUnamortizedAmount - B.IncomeRecognizedTillDate
,0
,NULL
FROM #BlendedItemGLInfo B
JOIN #BlendedItemInfo BlendedItem ON B.BlendedItemId = BlendedItem.BlendedItemId
WHERE BlendedItem.Type <> 'Income' AND BlendedItem.BookRecognitionMode = 'Amortize' AND BlendedItem.AccumulateExpense=1 AND B.LatestRecordExists=1
AND (B.ClearedUnamortizedAmount - B.IncomeRecognizedTillDate) <> 0
IF EXISTS(SELECT ContractId FROM #BlendedItemInfo WHERE IsNonAccrual = 1 AND IsChargedOffContract = 0 AND BookRecognitionMode <> 'RecognizeImmediately')
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT B.ContractId
,CASE WHEN BlendedItem.Type='Income'
THEN CASE WHEN #ReAccrualBlendedItemGLInfo.BlendedItemId IS NOT NULL THEN #ReAccrualBlendedItemGLInfo.IncomeGLTransactionType ELSE 'BlendedIncomeRecognition' END
ELSE 'BlendedExpenseRecognition' END
,CASE WHEN #ReAccrualBlendedItemGLInfo.BlendedItemId IS NOT NULL
THEN #ReAccrualBlendedItemGLInfo.IncomeGLTemplateId
ELSE BlendedItem.RecognitionGLTemplateId END GLTemplateId
,CASE WHEN BlendedItem.Type='Income'
THEN CASE WHEN #ReAccrualBlendedItemGLInfo.BlendedItemId IS NOT NULL THEN #ReAccrualBlendedItemGLInfo.SuspenseCreditEntryItem ELSE 'SuspendedBlendedIncome' END
ELSE 'SuspendedBlendedExpense' END
,CASE WHEN #ReAccrualBlendedItemGLInfo.BlendedItemId IS NOT NULL AND BlendedItem.IsFAS91=1
THEN ISNULL(BlendedIncome.IncomeRecognizedTillDate,0.00) + AdjustmentAmount
ELSE ISNULL(BlendedIncome.IncomeRecognizedTillDate,0.00) END
,CASE WHEN BlendedItem.Type='Income' THEN 0 ELSE 1 END
FROM
#BlendedItemGLInfo B
JOIN (SELECT * FROM #BlendedItemInfo WHERE IsNonAccrual = 1 AND IsChargedOffContract = 0 AND BookRecognitionMode <> 'RecognizeImmediately')
AS BlendedItem ON B.BlendedItemId = BlendedItem.BlendedItemId
LEFT JOIN (SELECT
#BlendedIncomeSchedules.BlendedItemId,
#BlendedIncomeSchedules.ContractId,
SUM(Income) IncomeRecognizedTillDate
FROM #BlendedIncomeSchedules
JOIN #BlendedItemInfo on #BlendedIncomeSchedules.BlendedItemId = #BlendedItemInfo.BlendedItemId
WHERE #BlendedIncomeSchedules.IsNonAccrual = 1 AND #BlendedItemInfo.IsNonAccrual=1 
AND #BlendedIncomeSchedules.IncomeDate >= #BlendedItemInfo.NonAccrualDate
GROUP BY #BlendedIncomeSchedules.BlendedItemId,#BlendedIncomeSchedules.ContractId)
AS BlendedIncome ON B.BlendedItemId = BlendedIncome.BlendedItemId AND B.ContractId = BlendedIncome.ContractId
LEFT JOIN #ReAccrualBlendedItemGLInfo ON BlendedIncome.BlendedItemId = #ReAccrualBlendedItemGLInfo.BlendedItemId
END
END
IF(@MovePLBalance=1)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit,MatchingGLTemplateId)
SELECT B.ContractId
,CASE WHEN B.Type='Income'
THEN CASE WHEN #ReAccrualBlendedItemGLInfo.BlendedItemId IS NOT NULL THEN #ReAccrualBlendedItemGLInfo.IncomeGLTransactionType ELSE 'BlendedIncomeSetup' END
ELSE 'BlendedExpenseSetup' END GLTransactionType
,CASE WHEN #ReAccrualBlendedItemGLInfo.BlendedItemId IS NOT NULL
THEN #ReAccrualBlendedItemGLInfo.IncomeGLTemplateId
ELSE B.BookingGLTemplateId END GLTemplateId
,CASE WHEN B.Type='Income'
THEN CASE WHEN #ReAccrualBlendedItemGLInfo.BlendedItemId IS NOT NULL THEN #ReAccrualBlendedItemGLInfo.CreditEntryItem ELSE 'BlendedIncome' END
ELSE 'BlendedExpense' END GLEntryItem
,BlendedItemDetails.Amount
,CASE WHEN B.Type='Income' THEN 0 ELSE 1 END IsDebit
,NULL
FROM (SELECT * FROM #BlendedItemInfo WHERE BookRecognitionMode = 'RecognizeImmediately') B
JOIN (SELECT B.BlendedItemId,SUM(BlendedItemDetails.Amount_Amount) Amount
FROM #BlendedItemInfo B
JOIN BlendedItemDetails ON B.BlendedItemId = BlendedItemDetails.BlendedItemId AND BlendedItemDetails.IsActive=1
WHERE BlendedItemDetails.IsGLPosted = 1 AND BlendedItemDetails.DueDate >= @PLEffectiveDate AND BlendedItemDetails.DueDate < @EffectiveDate
GROUP BY B.BlendedItemId)
AS BlendedItemDetails ON B.BlendedItemId = BlendedItemDetails.BlendedItemId
LEFT JOIN #ReAccrualBlendedItemGLInfo ON B.BlendedItemId = #ReAccrualBlendedItemGLInfo.BlendedItemId
WHERE BlendedItemDetails.Amount <> 0
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit,MatchingGLTemplateId)
SELECT B.ContractId
,CASE WHEN B.Type='Income'
THEN CASE WHEN #ReAccrualBlendedItemGLInfo.BlendedItemId IS NOT NULL THEN #ReAccrualBlendedItemGLInfo.IncomeGLTransactionType ELSE 'BlendedIncomeRecognition' END
ELSE 'BlendedExpenseRecognition' END
,CASE WHEN #ReAccrualBlendedItemGLInfo.BlendedItemId IS NOT NULL
THEN #ReAccrualBlendedItemGLInfo.IncomeGLTemplateId
ELSE B.RecognitionGLTemplateId END GLTemplateId
,CASE WHEN B.Type='Income'
THEN CASE WHEN #ReAccrualBlendedItemGLInfo.BlendedItemId IS NOT NULL THEN #ReAccrualBlendedItemGLInfo.CreditEntryItem ELSE 'BlendedIncome' END
ELSE 'BlendedExpense' END
,CASE WHEN #ReAccrualBlendedItemGLInfo.BlendedItemId IS NOT NULL AND (B.IsNonAccrual = 0 OR B.IsFAS91=0)
THEN BlendedIncome.Income + ISNULL(AdjustmentInfo.AdjustmentAmount,0) + (CASE WHEN B.IsReamortizationRecoveryMethod = 1 THEN 0 ELSE ISNULL(ReAccrualCatchup.CatchupAmount,0) END)
ELSE BlendedIncome.Income + (CASE WHEN B.IsReamortizationRecoveryMethod = 1 THEN 0 ELSE ISNULL(ReAccrualCatchup.CatchupAmount,0) END)
END
,CASE WHEN B.Type='Income' THEN 0 ELSE 1 END
,NULL
FROM (SELECT * FROM #BlendedItemInfo WHERE BookRecognitionMode <> 'RecognizeImmediately') B
JOIN (SELECT BlendedIncome.BlendedItemId,SUM(BlendedIncome.Income) Income
FROM #BlendedItemInfo B
JOIN #BlendedIncomeSchedules BlendedIncome ON B.BlendedItemId = BlendedIncome.BlendedItemId AND BlendedIncome.ContractId = B.ContractId
WHERE BlendedIncome.IncomeDate >= @PLEffectiveDate AND BlendedIncome.IncomeDate < @EffectiveDate
AND BlendedIncome.IsNonAccrual = 0
GROUP BY BlendedIncome.BlendedItemId)
AS BlendedIncome ON B.BlendedItemId = BlendedIncome.BlendedItemId
LEFT JOIN #ReAccrualBlendedItemGLInfo ON B.BlendedItemId = #ReAccrualBlendedItemGLInfo.BlendedItemId
LEFT JOIN (SELECT
ContractId,
BlendedItemId,
SUM(AdjustmentAmount) AdjustmentAmount
FROM #BlendedItemAdjustmentInfo
WHERE EffectiveDate >= @PLEffectiveDate AND EffectiveDate < @EffectiveDate
GROUP BY ContractId,BlendedItemId)
AS AdjustmentInfo ON #ReAccrualBlendedItemGLInfo.BlendedItemId = AdjustmentInfo.BlendedItemId AND #ReAccrualBlendedItemGLInfo.ContractId = AdjustmentInfo.ContractId
LEFT JOIN (
SELECT BlendedItemId, ContractId, SUM(CatchupAmount) AS CatchupAmount FROM #ReAccrualCatchupInfo WHERE IncomeDate >= @PLEffectiveDate AND IncomeDate < @EffectiveDate  GROUP BY BlendedItemId,ContractId) AS ReAccrualCatchup 
ON B.BlendedItemId = ReAccrualCatchup.BlendedItemId AND B.ContractId = ReAccrualCatchup.ContractId
WHERE BlendedIncome.Income <> 0 
OR (#ReAccrualBlendedItemGLInfo.BlendedItemId IS NOT NULL AND ISNULL(AdjustmentInfo.AdjustmentAmount,0) <> 0)
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit,MatchingGLTemplateId)
SELECT B.ContractId
,CASE WHEN B.Type='Income' THEN 'BlendedIncomeRecognition' ELSE 'BlendedExpenseRecognition' END
,B.RecognitionGLTemplateId
,'CostOfGoodsSold'
,SUM(BlendedItemSummary.AdjustmentAmount)
,CASE WHEN B.Type='Income' THEN 0 ELSE 1 END
,NULL
FROM (SELECT * FROM #BlendedItemInfo WHERE BookRecognitionMode <> 'RecognizeImmediately' AND BookRecognitionMode <> 'Capitalize') B
JOIN #BlendedItemAdjustmentInfo BlendedItemSummary ON B.BlendedItemId = BlendedItemSummary.BlendedItemId AND BlendedItemSummary.ContractId = B.ContractId
LEFT JOIN #ReAccrualBlendedItemGLInfo ON B.BlendedItemId = #ReAccrualBlendedItemGLInfo.BlendedItemId
WHERE BlendedItemSummary.EffectiveDate >= @PLEffectiveDate AND BlendedItemSummary.EffectiveDate < @EffectiveDate
AND #ReAccrualBlendedItemGLInfo.BlendedItemId IS NULL
GROUP BY B.ContractId,B.BlendedItemId,B.Type,B.RecognitionGLTemplateId
HAVING SUM(BlendedItemSummary.AdjustmentAmount) <> 0
END
END
END
IF @MovePLBalance=1
BEGIN
IF EXISTS(SELECT ContractId FROM #ContractInfo WHERE ContractType IN('Lease','Loan') AND IsChargedoff = 1)
BEGIN
SELECT C.ContractId
,ChargeOffs.ChargeOffDate
,ChargeOffs.PostDate
,ChargeOffs.LeaseComponentAmount_Amount
,ChargeOffs.NonLeaseComponentAmount_Amount
,ChargeOffs.LeaseComponentGain_Amount
,ChargeOffs.NonLeaseComponentGain_Amount
,Chargeoffs.IsRecovery
,ChargeOffs.GLTemplateId
,GLTransactionTypes.Name GLTransactionType
,ChargeOffs.ReceiptId
,Receipts.ReceiptGLTemplateId 
INTO #ChargeOffInfo
FROM
(SELECT * FROM #ContractInfo ContractInfo WHERE ContractType IN('Lease','Loan') AND IsChargedoff=1) AS C
JOIN ChargeOffs ON C.ContractId = ChargeOffs.ContractId AND ChargeOffs.IsActive=1 AND ChargeOffs.Status = 'Approved' 
JOIN GLTemplates ON ChargeOffs.GLTemplateId = GLTemplates.Id
JOIN GLTransactionTypes ON GLTemplates.GLTransactionTypeId = GLTransactionTypes.Id
LEFT JOIN Receipts ON ChargeOffs.ReceiptId = Receipts.Id
IF EXISTS(SELECT ContractId FROM #ChargeOffInfo WHERE PostDate >= @PLEffectiveDate AND PostDate < @EffectiveDate)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit,MatchingGLTemplateId,MatchingFilter)
SELECT
C.ContractId,
GLTransactionTypes.Name,
C.ReceiptGLTemplateId,
'ChargeOffExpense',
SUM(C.LeaseComponentAmount_Amount),
0,
C.GLTemplateId,
C.GLTransactionType
FROM #ChargeOffInfo C
JOIN GLTemplates ON C.ReceiptGLTemplateId = GLTemplates.Id
JOIN GLTransactionTypes ON GLTemplates.GLTransactionTypeId = GLTransactionTypes.Id
WHERE C.PostDate >= @PLEffectiveDate AND C.PostDate < @EffectiveDate AND C.IsRecovery=0 AND C.ReceiptId IS NOT NULL
GROUP BY C.ContractId,C.ReceiptGLTemplateId,GLTransactionTypes.Name,C.GLTemplateId,C.GLTransactionType
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit,MatchingGLTemplateId,MatchingFilter)
SELECT
C.ContractId,
GLTransactionTypes.Name,
C.ReceiptGLTemplateId,
'FinancingChargeOffExpense',
SUM(C.NonLeaseComponentAmount_Amount),
0,
C.GLTemplateId,
C.GLTransactionType
FROM #ChargeOffInfo C
JOIN GLTemplates ON C.ReceiptGLTemplateId = GLTemplates.Id
JOIN GLTransactionTypes ON GLTemplates.GLTransactionTypeId = GLTransactionTypes.Id
WHERE C.PostDate >= @PLEffectiveDate AND C.PostDate < @EffectiveDate AND C.IsRecovery=0 AND C.ReceiptId IS NOT NULL
GROUP BY C.ContractId,C.ReceiptGLTemplateId,GLTransactionTypes.Name,C.GLTemplateId,C.GLTransactionType
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
GLTransactionTypes.Name,
C.ReceiptGLTemplateId,
'ChargeoffRecovery',
SUM(C.LeaseComponentAmount_Amount) * (-1),
0
FROM #ChargeOffInfo C
JOIN GLTemplates ON C.ReceiptGLTemplateId = GLTemplates.Id
JOIN GLTransactionTypes ON GLTemplates.GLTransactionTypeId = GLTransactionTypes.Id
WHERE C.PostDate >= @PLEffectiveDate AND C.PostDate < @EffectiveDate AND C.IsRecovery=1 AND C.ReceiptId IS NOT NULL
GROUP BY C.ContractId,C.ReceiptGLTemplateId,GLTransactionTypes.Name
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
GLTransactionTypes.Name,
C.ReceiptGLTemplateId,
'FinancingChargeOffRecovery',
SUM(C.NonLeaseComponentAmount_Amount) * (-1),
0
FROM #ChargeOffInfo C
JOIN GLTemplates ON C.ReceiptGLTemplateId = GLTemplates.Id
JOIN GLTransactionTypes ON GLTemplates.GLTransactionTypeId = GLTransactionTypes.Id
WHERE C.PostDate >= @PLEffectiveDate AND C.PostDate < @EffectiveDate AND C.IsRecovery=1 AND C.ReceiptId IS NOT NULL
GROUP BY C.ContractId,C.ReceiptGLTemplateId,GLTransactionTypes.Name
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
GLTransactionTypes.Name,
C.ReceiptGLTemplateId,
'GainOnRecovery',
SUM(C.LeaseComponentGain_Amount) * (-1),
0
FROM #ChargeOffInfo C
JOIN GLTemplates ON C.ReceiptGLTemplateId = GLTemplates.Id
JOIN GLTransactionTypes ON GLTemplates.GLTransactionTypeId = GLTransactionTypes.Id
WHERE C.PostDate >= @PLEffectiveDate AND C.PostDate < @EffectiveDate AND C.IsRecovery=1 AND C.ReceiptId IS NOT NULL
GROUP BY C.ContractId,C.ReceiptGLTemplateId,GLTransactionTypes.Name
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
GLTransactionTypes.Name,
C.ReceiptGLTemplateId,
'FinancingGainOnRecovery',
SUM(C.NonLeaseComponentGain_Amount) * (-1),
0
FROM #ChargeOffInfo C
JOIN GLTemplates ON C.ReceiptGLTemplateId = GLTemplates.Id
JOIN GLTransactionTypes ON GLTemplates.GLTransactionTypeId = GLTransactionTypes.Id
WHERE C.PostDate >= @PLEffectiveDate AND C.PostDate < @EffectiveDate AND C.IsRecovery=1 AND C.ReceiptId IS NOT NULL
GROUP BY C.ContractId,C.ReceiptGLTemplateId,GLTransactionTypes.Name
END
IF EXISTS(SELECT ContractId FROM #ChargeOffInfo WHERE ChargeOffDate >= @PLEffectiveDate AND ChargeOffDate < @EffectiveDate)
BEGIN
SELECT CASE WHEN BlendedItems.StartDate < #ChargeOffInfo.ChargeOffDate
THEN CASE WHEN #ChargeOffInfo.ChargeOffDate != BlendedItemsForGLTransfer.CommencementDate THEN #ChargeOffInfo.ChargeOffDate ELSE DATEADD(DAY,-1,BlendedItemsForGLTransfer.CommencementDate) END
ELSE EOMONTH(BlendedItems.StartDate) END AS ComputedChargeoffDate
,#ChargeOffInfo.ChargeOffDate
,BlendedItemsForGLTransfer.ContractId
,BlendedItems.StartDate
,BlendedItems.Type
,BlendedItems.RecognitionGLTemplateId
,BlendedItems.Amount_Amount
,BlendedItems.Id BlendedItemId
INTO #ChargeOffBlendedItemInfo
FROM #ChargeOffInfo
JOIN (SELECT LeaseFinanceDetails.CommencementDate,B.* FROM #BlendedItemInfo B
JOIN LeaseFinances ON B.ContractId = LeaseFinances.ContractId AND LeaseFinances.IsCurrent=1
JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
WHERE B.IsChargedOffContract = 1 AND B.IsReceivableForTransferBlendedItem = 0 AND B.BookRecognitionMode != 'Capitalize' 
UNION
SELECT LoanFinances.CommencementDate,B.* FROM #BlendedItemInfo B
JOIN LoanFinances ON B.ContractId = LoanFinances.ContractId AND LoanFinances.IsCurrent=1
WHERE B.IsChargedOffContract = 1 AND B.IsReceivableForTransferBlendedItem = 0)
AS BlendedItemsForGLTransfer ON #ChargeOffInfo.ContractId = BlendedItemsForGLTransfer.ContractId
JOIN BlendedItems ON BlendedItemsForGLTransfer.BlendedItemId = BlendedItems.Id AND BlendedItems.IsFAS91 = 1
WHERE BlendedItems.BookRecognitionMode <> 'RecognizeImmediately' AND #ChargeOffInfo.IsRecovery =0 AND #ChargeOffInfo.ReceiptId IS NULL
SELECT #ChargeOffBlendedItemInfo.BlendedItemId,SUM(BlendedIncomeSchedules.Income_Amount) AS Income
INTO #ChargeOffBlendedIncomeInfo
FROM #ChargeOffBlendedItemInfo
JOIN BlendedIncomeSchedules ON #ChargeOffBlendedItemInfo.BlendedItemId = BlendedIncomeSchedules.BlendedItemId AND BlendedIncomeSchedules.IsSchedule=1
AND BlendedIncomeSchedules.IsNonAccrual=0
WHERE BlendedIncomeSchedules.IncomeDate <= #ChargeOffBlendedItemInfo.ComputedChargeoffDate
GROUP BY #ChargeOffBlendedItemInfo.BlendedItemId
IF EXISTS(SELECT ContractId FROM #ChargeOffBlendedItemInfo)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
#ChargeOffBlendedItemInfo.ContractId,
CASE WHEN Type = 'Income' THEN 'BlendedIncomeRecognition' ELSE 'BlendedExpenseRecognition' END,
#ChargeOffBlendedItemInfo.RecognitionGLTemplateId,
'ChargeOffExpense',
CASE WHEN #ChargeOffBlendedItemInfo.StartDate >= #ChargeOffBlendedItemInfo.ChargeOffDate THEN #ChargeOffBlendedItemInfo.Amount_Amount ELSE #ChargeOffBlendedItemInfo.Amount_Amount - ISNULL(BlendedIncome.Income,0) END,
CASE WHEN Type = 'Income' THEN 0 ELSE 1 END
FROM
#ChargeOffBlendedItemInfo
LEFT JOIN #ChargeOffBlendedIncomeInfo BlendedIncome ON #ChargeOffBlendedItemInfo.BlendedItemId = BlendedIncome.BlendedItemId
END
;WITH CTE_CBIIncomeBalance AS
(SELECT #ChargeOffBlendedItemInfo.ContractId
	,SUM(IIF( #ChargeOffBlendedItemInfo.StartDate >= #ChargeOffBlendedItemInfo.ChargeOffDate 
		, #ChargeOffBlendedItemInfo.Amount_Amount 
		, #ChargeOffBlendedItemInfo.Amount_Amount - ISNULL(#ChargeOffBlendedIncomeInfo.Income,0))) AS BlendedAmount
FROM #ChargeOffBlendedItemInfo
LEFT JOIN #ChargeOffBlendedIncomeInfo ON #ChargeOffBlendedItemInfo.BlendedItemId = #ChargeOffBlendedIncomeInfo.BlendedItemId
WHERE ChargeOffDate >= @PLEffectiveDate AND ChargeOffDate < @EffectiveDate AND #ChargeOffBlendedItemInfo.Type ='Income'
GROUP BY #ChargeOffBlendedItemInfo.ContractId),
CTE_CBIExpenseBalance AS
(SELECT #ChargeOffBlendedItemInfo.ContractId
	,SUM(IIF( #ChargeOffBlendedItemInfo.StartDate >= #ChargeOffBlendedItemInfo.ChargeOffDate 
		, #ChargeOffBlendedItemInfo.Amount_Amount 
		, #ChargeOffBlendedItemInfo.Amount_Amount - ISNULL(#ChargeOffBlendedIncomeInfo.Income,0))) AS BlendedAmount
FROM #ChargeOffBlendedItemInfo
LEFT JOIN #ChargeOffBlendedIncomeInfo ON #ChargeOffBlendedItemInfo.BlendedItemId = #ChargeOffBlendedIncomeInfo.BlendedItemId
WHERE ChargeOffDate >= @PLEffectiveDate AND ChargeOffDate < @EffectiveDate AND #ChargeOffBlendedItemInfo.Type !='Income'
GROUP BY #ChargeOffBlendedItemInfo.ContractId)
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
C.GLTransactionType,
C.GLTemplateId,
'ChargeOffExpense',
SUM(C.LeaseComponentAmount_Amount) + ISNULL(CBIIncomeBalance.BlendedAmount,0) - ISNULL(CBIExpenseBalance.BlendedAmount,0),
1
FROM #ChargeOffInfo C
LEFT JOIN CTE_CBIIncomeBalance AS CBIIncomeBalance ON C.ContractId = CBIIncomeBalance.ContractId
LEFT JOIN CTE_CBIExpenseBalance AS CBIExpenseBalance ON C.ContractId = CBIExpenseBalance.ContractId
WHERE ChargeOffDate >= @PLEffectiveDate AND ChargeOffDate < @EffectiveDate AND C.IsRecovery=0 AND C.ReceiptId IS NULL
GROUP BY C.ContractId,C.GLTransactionType,C.GLTemplateId,CBIIncomeBalance.BlendedAmount,CBIExpenseBalance.BlendedAmount
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
CO.ContractId,
CO.GLTransactionType,
CO.GLTemplateId,
'FinancingChargeOffExpense',
SUM(CO.NonLeaseComponentAmount_Amount),
1
FROM #ChargeOffInfo CO
WHERE ChargeOffDate >= @PLEffectiveDate AND ChargeOffDate < @EffectiveDate AND IsRecovery=0 AND ReceiptId IS NULL
GROUP BY CO.ContractId,CO.GLTransactionType,CO.GLTemplateId
END
END
END
IF EXISTS(SELECT ContractId FROM #ContractInfo WHERE ContractType = 'Lease')
BEGIN
DECLARE @TaxLeaseContractIds ContractIdCollection;
INSERT INTO @TaxLeaseContractIds
SELECT C.ContractId FROM
(SELECT * FROM #ContractInfo ContractInfo WHERE ContractType = 'Lease') AS C
JOIN LeaseFinances ON C.ContractId = LeaseFinances.ContractId AND LeaseFinances.IsCurrent=1
JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
WHERE LeaseFinanceDetails.IsTaxLease=1
INSERT INTO #GLSummary
EXEC ProcessDeferredTaxLiabilitiesForGLTransfer @EffectiveDate = @EffectiveDate,@MovePLBalance = @MovePLBalance,@PLEffectiveDate = @PLEffectiveDate,@ContractType = 'Lease',@ContractIds = @TaxLeaseContractIds
END
CREATE TABLE #ProgressLoanContracts
(
ContractId BIGINT PRIMARY KEY,
IncomeGLPostedTillDate DATE,
InterimBillingType NVARCHAR(34),
LoanFinanceId BIGINT,
InterimIncomeRecognitionGLTemplateId BIGINT
);
INSERT INTO #ProgressLoanContracts
SELECT ContractInfo.ContractId,IncomeGLPostedTillDate,LoanFinances.InterimBillingType,LoanFinances.Id LoanFinanceId,LoanFinances.InterimIncomeRecognitionGLTemplateId
FROM #ContractInfo ContractInfo
JOIN LoanFinances ON ContractInfo.ContractId = LoanFinances.ContractId AND LoanFinances.IsCurrent=1
WHERE ContractType = 'ProgressLoan' AND IsChargedOff = 0
IF EXISTS(SELECT ContractId FROM #ProgressLoanContracts)
BEGIN
CREATE TABLE #PPCOtherCostIds(ContractId BIGINT,Id BIGINT);
INSERT INTO #PPCOtherCostIds
SELECT C.ContractId,PayableInvoiceOtherCosts.Id
FROM #ProgressLoanContracts C
JOIN LoanFundings ON C.LoanFinanceId = LoanFundings.LoanFinanceId AND LoanFundings.IsActive=1
JOIN PayableInvoices ON LoanFundings.FundingId = PayableInvoices.Id
JOIN PayableInvoiceOtherCosts ON PayableInvoices.Id = PayableInvoiceOtherCosts.PayableInvoiceId AND PayableInvoiceOtherCosts.IsActive=1
SELECT
C.ContractId,
LoanIncomeSchedules.IncomeDate,
LoanIncomeSchedules.IsNonAccrual,
LoanIncomeSchedules.InterestAccrued_Amount InterestAccrued
INTO #GLPostedProgressLoanIncomeSchedules
FROM #ProgressLoanContracts C
JOIN LoanFinances ON C.ContractId = LoanFinances.ContractId
JOIN LoanIncomeSchedules ON LoanFinances.Id = LoanIncomeSchedules.LoanFinanceId AND LoanIncomeSchedules.IncomeDate <= C.IncomeGLPostedTillDate
AND LoanIncomeSchedules.IsSchedule=1 AND LoanIncomeSchedules.IsLessorOwned=1
CREATE TABLE #ProgressLoanTakeDownInfo
(
ProgressLoanContractId BIGINT,
ContractId BIGINT,
ProgressFundingId BIGINT,
IsSyndicatedAtInception BIT,
CapitalizedProgressPaymentAmount DECIMAL(16,2),
TakeDownAmount DECIMAL(16,2),
GLTemplateId BIGINT NULL,
TakeDownDate DATE
);
CREATE TABLE #RemainingBalanceInAccruedInterest(ContractId BIGINT,Amount DECIMAL(16,2));
IF ((SELECT COUNT(ContractId) FROM #ProgressLoanContracts C WHERE InterimBillingType='Capitalize')>=1 OR @MovePLBalance=1)
BEGIN
INSERT INTO #ProgressLoanTakeDownInfo
SELECT PPCOtherCosts.ContractId ProgressLoanContractId,
LeaseFinances.ContractId,
PayableInvoiceOtherCosts.ProgressFundingId ProgressFundingId,
0 AS IsSyndicatedAtInception,
PayableInvoiceOtherCosts.CapitalizedProgressPayment_Amount CapitalizedProgressPaymentAmount,
PayableInvoiceOtherCosts.Amount_Amount * (-1) TakeDownAmount,
NULL GLTemplateId,
LeaseFinanceDetails.CommencementDate TakeDownDate
FROM #PPCOtherCostIds PPCOtherCosts
JOIN #ProgressLoanContracts C ON PPCOtherCosts.ContractId = C.ContractId AND C.InterimBillingType = 'Capitalize'
JOIN PayableInvoiceOtherCosts ON PPCOtherCosts.Id = PayableInvoiceOtherCosts.ProgressFundingId AND PayableInvoiceOtherCosts.IsActive=1
JOIN PayableInvoices ON PayableInvoiceOtherCosts.PayableInvoiceId = PayableInvoices.Id AND PayableInvoices.Status <> 'InActive'
JOIN LeaseFundings ON PayableInvoices.Id= LeaseFundings.FundingId AND LeaseFundings.IsActive=1
JOIN LeaseFinances ON LeaseFundings.LeaseFinanceId = LeaseFinances.Id AND LeaseFinances.IsCurrent=1
JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
WHERE LeaseFinances.BookingStatus = 'Commenced'
UNION
SELECT PPCOtherCosts.ContractId ProgressLoanContractId,
LeaseFinances.ContractId,
LeaseSyndicationProgressPaymentCredits.PayableInvoiceOtherCostId ProgressFundingId,
1 AS IsSyndicatedAtInception,
LeaseSyndicationProgressPaymentCredits.OtherCostCapitalizedAmount_Amount CapitalizedProgressPaymentAmount,
LeaseSyndicationProgressPaymentCredits.TakeDownAmount_Amount TakeDownAmount,
ReceivableCodes.GLTemplateId GLTemplateId,
LeaseFinanceDetails.CommencementDate TakeDownDate
FROM #PPCOtherCostIds PPCOtherCosts
JOIN #ProgressLoanContracts C ON PPCOtherCosts.ContractId = C.ContractId AND (C.InterimBillingType = 'Capitalize' OR @MovePLBalance = 1)
JOIN LeaseSyndicationProgressPaymentCredits ON PPCOtherCosts.Id = LeaseSyndicationProgressPaymentCredits.PayableInvoiceOtherCostId AND LeaseSyndicationProgressPaymentCredits.IsActive=1
JOIN LeaseSyndications ON LeaseSyndicationProgressPaymentCredits.LeaseSyndicationId = LeaseSyndications.Id
JOIN LeaseFinances ON LeaseSyndications.Id = LeaseFinances.Id AND LeaseFinances.IsCurrent=1
JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
JOIN ReceivableCodes ON LeaseSyndications.ProgressPaymentReimbursementCodeId = ReceivableCodes.Id
WHERE LeaseFinances.BookingStatus = 'Commenced'
UNION
SELECT PPCOtherCosts.ContractId ProgressLoanContractId,
LoanFinances.ContractId,
PayableInvoiceOtherCosts.ProgressFundingId ProgressFundingId,
CASE WHEN LoanSyndications.Id IS NOT NULL THEN 1 ELSE 0 END AS IsSyndicatedAtInception,
ISNULL(LoanCapitalizedInterests.Amount_Amount,0) CapitalizedProgressPaymentAmount,
PayableInvoiceOtherCosts.Amount_Amount * (-1) TakeDownAmount,
ReceivableCodes.GLTemplateId GLTemplateId,
ISNULL(PayableInvoiceOtherCosts.InterimInterestStartDate,LoanFinances.CommencementDate) TakeDownDate
FROM #PPCOtherCostIds PPCOtherCosts
JOIN #ProgressLoanContracts C ON PPCOtherCosts.ContractId = C.ContractId AND (C.InterimBillingType = 'Capitalize' OR @MovePLBalance = 1)
JOIN PayableInvoiceOtherCosts ON PPCOtherCosts.Id = PayableInvoiceOtherCosts.ProgressFundingId AND PayableInvoiceOtherCosts.IsActive=1
JOIN PayableInvoices ON PayableInvoiceOtherCosts.PayableInvoiceId = PayableInvoices.Id AND PayableInvoices.Status <> 'InActive'
JOIN LoanFundings ON PayableInvoices.Id= LoanFundings.FundingId AND LoanFundings.IsActive=1
JOIN LoanFinances ON LoanFundings.LoanFinanceId = LoanFinances.Id AND LoanFinances.IsCurrent=1
LEFT JOIN LoanCapitalizedInterests ON LoanFinances.Id = LoanCapitalizedInterests.LoanFinanceId AND LoanCapitalizedInterests.PayableInvoiceOtherCostId = PayableInvoiceOtherCosts.Id
LEFT JOIN LoanSyndications ON LoanFinances.Id = LoanSyndications.Id
LEFT JOIN ReceivableCodes ON LoanSyndications.ProgressPaymentReimbursementCodeId = ReceivableCodes.Id
WHERE LoanFinances.Status = 'Commenced'
AND (LoanCapitalizedInterests.LoanFinanceId IS NULL OR LoanCapitalizedInterests.IsActive=1)
AND (LoanCapitalizedInterests.LoanFinanceId IS NULL OR LoanCapitalizedInterests.Source='ProgressLoan')
END
IF EXISTS(SELECT ContractId FROM #ProgressLoanContracts C WHERE InterimBillingType IN('Periodic','SingleInstallment'))
BEGIN
INSERT INTO #RemainingBalanceInAccruedInterest
SELECT
C.ContractId,
ISNULL(GLPostedLoanIncome.InterestAccrued,0)-ISNULL(GLPostedLoanReceivables.AmountPosted,0) AS Amount
FROM #ProgressLoanContracts C
LEFT JOIN (SELECT ContractId,SUM(InterestAccrued) InterestAccrued FROM #GLPostedProgressLoanIncomeSchedules GROUP BY ContractId) AS GLPostedLoanIncome ON C.ContractId = GLPostedLoanIncome.ContractId
LEFT JOIN (SELECT
C.ContractId,SUM(Receivables.TotalAmount_Amount) AmountPosted
FROM
#ProgressLoanContracts C
JOIN Receivables ON C.InterimBillingType IN('Periodic','SingleInstallment') AND C.ContractId = Receivables.EntityId
AND Receivables.EntityType = 'CT' AND Receivables.IsGLPosted=1
JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id AND ReceivableTypes.Name = 'LoanInterest'
LEFT JOIN LoanPaymentSchedules ON Receivables.PaymentScheduleId = LoanPaymentSchedules.Id
WHERE ISNULL(LoanPaymentSchedules.EndDate,Receivables.DueDate) < @EffectiveDate
AND Receivables.FunderId IS NULL
GROUP BY C.ContractId)
AS GLPostedLoanReceivables ON C.ContractId = GLPostedLoanReceivables.ContractId
WHERE C.InterimBillingType IN('Periodic','SingleInstallment')
AND (GLPostedLoanIncome.ContractId IS NOT NULL OR GLPostedLoanReceivables.ContractId IS NOT NULL)
END
IF EXISTS(SELECT ContractId FROM #ProgressLoanContracts C WHERE InterimBillingType IN('Capitalize'))
BEGIN
INSERT INTO #RemainingBalanceInAccruedInterest
SELECT
C.ContractId,
ISNULL(ProgressLoanTakeDownInfo.CapitalizedProgressPaymentAmount,0)-ISNULL(GLPostedLoanIncome.InterestAccrued,0) AS Amount
FROM #ProgressLoanContracts C
LEFT JOIN (SELECT ProgressLoanContractId ContractId,SUM(CapitalizedProgressPaymentAmount) CapitalizedProgressPaymentAmount FROM #ProgressLoanTakeDownInfo GROUP BY ProgressLoanContractId) AS ProgressLoanTakeDownInfo ON C.ContractId = ProgressLoanTakeDownInfo.ContractId
LEFT JOIN (SELECT ContractId,SUM(InterestAccrued) InterestAccrued FROM #GLPostedProgressLoanIncomeSchedules GROUP BY ContractId) AS GLPostedLoanIncome ON C.ContractId = GLPostedLoanIncome.ContractId
WHERE C.InterimBillingType IN('Capitalize')
AND (GLPostedLoanIncome.ContractId IS NOT NULL OR ProgressLoanTakeDownInfo.ContractId IS NOT NULL)
END
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'LoanIncomeRecognition',
C.InterimIncomeRecognitionGLTemplateId,
'AccruedInterest',
RB.Amount,
1
FROM
#RemainingBalanceInAccruedInterest RB
JOIN #ProgressLoanContracts C ON RB.ContractId = C.ContractId
WHERE Amount<>0
IF(@MovePLBalance=1)
BEGIN
IF EXISTS(SELECT ContractId FROM #GLPostedProgressLoanIncomeSchedules)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'LoanIncomeRecognition',
C.InterimIncomeRecognitionGLTemplateId,
'InterestIncome',
SUM(LIS.InterestAccrued),
0
FROM #GLPostedProgressLoanIncomeSchedules LIS
JOIN #ProgressLoanContracts C ON LIS.ContractId = C.ContractId AND LIS.IsNonAccrual=0
WHERE LIS.IncomeDate >= @PLEffectiveDate AND LIS.IncomeDate < @EffectiveDate
GROUP BY C.ContractId,C.InterimIncomeRecognitionGLTemplateId
HAVING SUM(LIS.InterestAccrued) <> 0
END
IF EXISTS(SELECT ContractId FROM #ProgressLoanTakeDownInfo WHERE IsSyndicatedAtInception=1 AND TakeDownDate >= @PLEffectiveDate AND TakeDownDate < @EffectiveDate)
BEGIN
SELECT
ProgressLoanContracts.ProgressLoanContractId,
ProgressLoanContracts.GLTemplateId,
ProgressLoanContracts.ContractId,
ProgressLoanContracts.NetAmount,
LoanFinances.LegalEntityId
INTO #TakeDownInfo
FROM
(SELECT ProgressLoanContractId,ContractId,GLTemplateId,SUM(CapitalizedProgressPaymentAmount + TakeDownAmount) NetAmount
FROM #ProgressLoanTakeDownInfo ProgressLoanTakeDown
WHERE IsSyndicatedAtInception=1 AND TakeDownDate >= @PLEffectiveDate AND TakeDownDate < @EffectiveDate
GROUP BY ProgressLoanContractId,GLTemplateId,ContractId) AS ProgressLoanContracts
JOIN LoanFinances ON ProgressLoanContracts.ContractId = LoanFinances.ContractId AND LoanFinances.IsCurrent=1
DECLARE @GLPostedActualProceedsReceivables TABLE(ContractId BIGINT,Amount DECIMAL(16,2));
INSERT INTO @GLPostedActualProceedsReceivables
SELECT TakeDownContracts.ContractId,SUM(Receivables.TotalAmount_Amount) Amount
FROM
(SELECT ContractId FROM #TakeDownInfo GROUP BY ContractId) AS TakeDownContracts
JOIN Receivables ON TakeDownContracts.ContractId = Receivables.EntityId AND Receivables.EntityType = 'CT'
WHERE Receivables.IsActive=1 AND Receivables.IsGLPosted=1 AND Receivables.InvoiceComment = @SyndicationActualProceeds
GROUP BY TakeDownContracts.ContractId
DECLARE @PaydownGLTemplates TABLE(LegalEntityId BIGINT,GLTemplateId BIGINT);
INSERT INTO @PaydownGLTemplates
SELECT LegalEntities.Id,MIN(GLTemplates.Id)
FROM
(SELECT LegalEntityId FROM #TakeDownInfo GROUP BY LegalEntityId) AS LegalEntityIds
JOIN LegalEntities ON LegalEntityIds.LegalEntityId = LegalEntities.Id
JOIN GLConfigurations ON LegalEntities.GLConfigurationId = GLConfigurations.Id
JOIN GLTemplates ON GLConfigurations.Id = GLTemplates.GLConfigurationId AND GLTemplates.IsActive=1
JOIN GLTransactionTypes ON GLTransactionTypes.Id = GLTemplates.GLTransactionTypeId AND GLTransactionTypes.IsActive=1
WHERE GLTransactionTypes.Name = 'Paydown'
GROUP BY LegalEntities.Id
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit,MatchingGLTemplateId)
SELECT
T.ContractId,
'Paydown',
P.GLTemplateId,
'ProgressLoanReimbursementIncome',
T.NetAmount - ISNULL(GLPostedReceivables.Amount,0) Amount,
1,
T.GLTemplateId
FROM
#TakeDownInfo T
JOIN @PaydownGLTemplates P ON T.LegalEntityId = P.LegalEntityId
LEFT JOIN @GLPostedActualProceedsReceivables GLPostedReceivables ON T.ContractId = GLPostedReceivables.ContractId
WHERE (T.NetAmount - ISNULL(GLPostedReceivables.Amount,0)) <> 0
END
END
END
CREATE TABLE #LoanContracts
(
ContractId BIGINT PRIMARY KEY,
IncomeGLPostedTillDate DATE,
CommencementDate DATE,
LoanFinanceId BIGINT,
LoanIncomeRecognitionGLTemplateId BIGINT,
LoanBookingGLTemplateId BIGINT,
IsNonAccrual BIT
);
INSERT INTO #LoanContracts
SELECT ContractInfo.ContractId,IncomeGLPostedTillDate,LoanFinances.CommencementDate,LoanFinances.Id LoanFinanceId,LoanFinances.LoanIncomeRecognitionGLTemplateId,LoanFinances.LoanBookingGLTemplateId,Contracts.IsNonAccrual
FROM #ContractInfo ContractInfo
JOIN Contracts ON ContractInfo.ContractId = Contracts.Id
JOIN LoanFinances ON ContractInfo.ContractId = LoanFinances.ContractId AND LoanFinances.IsCurrent=1
WHERE Contracts.ContractType = 'Loan' AND IsChargedOff = 0
IF EXISTS(SELECT ContractId FROM #LoanContracts)
BEGIN
CREATE TABLE #DRPaidInfo (ContractId BIGINT,OtherCostId BIGINT,Type NVARCHAR(42), PaidAmount DECIMAL(16,2));
INSERT INTO #DRPaidInfo
SELECT C.ContractId,PayableInvoiceOtherCosts.Id OtherCostId,LoanFundings.Type,SUM(DisbursementRequestPayees.PaidAmount_Amount) PaidAmount
FROM #LoanContracts C
JOIN LoanFundings ON C.LoanFinanceId = LoanFundings.LoanFinanceId AND LoanFundings.IsActive=1
JOIN PayableInvoices ON LoanFundings.FundingId = PayableInvoices.Id
JOIN PayableInvoiceOtherCosts ON PayableInvoices.Id = PayableInvoiceOtherCosts.PayableInvoiceId AND PayableInvoiceOtherCosts.IsActive=1 AND PayableInvoiceOtherCosts.AllocationMethod = 'LoanDisbursement'
JOIN Payables ON Payables.EntityType = 'PI' and Payables.EntityId = PayableInvoices.Id AND payables.SourceTable = 'PayableInvoiceOtherCost'
AND Payables.SourceId = PayableInvoiceOtherCosts.Id AND Payables.Status <> 'Inactive'
JOIN DisbursementRequestPayables ON Payables.Id = DisbursementRequestPayables.PayableId AND DisbursementRequestPayables.IsActive=1
JOIN DisbursementRequestPayees ON DisbursementRequestPayables.Id = DisbursementRequestPayees.DisbursementRequestPayableId AND DisbursementRequestPayees.IsActive=1 AND DisbursementRequestPayees.ApprovedAmount_Amount <> 0
JOIN DisbursementRequests ON DisbursementRequestPayables.DisbursementRequestId = DisbursementRequests.Id AND DisbursementRequests.Status = 'Completed'
WHERE PayableInvoices.CurrencyId <> PayableInvoices.ContractCurrencyId
AND ((LoanFundings.Type IN('Origination') AND PayableInvoices.DueDate <= C.CommencementDate) OR LoanFundings.Type IN('FutureScheduledFunded'))
GROUP BY C.ContractId,PayableInvoiceOtherCosts.Id,LoanFundings.Type
CREATE TABLE #LoanNoteReceivableSetupAmount(ContractId BIGINT,NoteReceivableSetupAmount DECIMAL(16,2),OriginationFundingAmount DECIMAL(16,2),AccruedInterestCapitalized DECIMAL(16,2));
CREATE TABLE #OriginationFundingAmountInfo(ContractId BIGINT,OriginationFundingAmount DECIMAL(16,2));
INSERT INTO #OriginationFundingAmountInfo
SELECT ContractId,SUM(OriginationFundingAmountInfo.OriginationFundingAmount) OriginationFundingAmount
FROM (SELECT C.ContractId
,CASE WHEN PayableInvoices.CurrencyId <> PayableInvoices.ContractCurrencyId
THEN SUM(ISNULL(DRPaidInfo.PaidAmount,(PayableInvoiceOtherCosts.Amount_Amount * PayableInvoices.InitialExchangeRate)))
ELSE SUM(PayableInvoiceOtherCosts.Amount_Amount) END AS OriginationFundingAmount
FROM #LoanContracts C
JOIN LoanFundings ON C.LoanFinanceId = LoanFundings.LoanFinanceId AND LoanFundings.IsActive=1 AND LoanFundings.Type = 'Origination'
JOIN PayableInvoices ON LoanFundings.FundingId = PayableInvoices.Id AND PayableInvoices.DueDate <= C.CommencementDate
JOIN PayableInvoiceOtherCosts ON PayableInvoices.Id = PayableInvoiceOtherCosts.PayableInvoiceId AND PayableInvoiceOtherCosts.IsActive=1 AND PayableInvoiceOtherCosts.AllocationMethod = 'LoanDisbursement'
LEFT JOIN #DRPaidInfo DRPaidInfo ON PayableInvoiceOtherCosts.Id = DRPaidInfo.OtherCostId AND C.ContractId = DRPaidInfo.ContractId AND PayableInvoices.CurrencyId <> PayableInvoices.ContractCurrencyId
GROUP BY C.ContractId,PayableInvoices.CurrencyId,PayableInvoices.ContractCurrencyId) AS OriginationFundingAmountInfo
GROUP BY ContractId
CREATE TABLE #AccruedInterestCapitalizedInfo(ContractId BIGINT,AccruedInterestCapitalized DECIMAL(16,2));
INSERT INTO #AccruedInterestCapitalizedInfo
SELECT C.ContractId,SUM(LoanCapitalizedInterests.Amount_Amount) AccruedInterestCapitalized
FROM #LoanContracts C
JOIN LoanFinances ON C.LoanFinanceId = LoanFinances.Id
JOIN LoanCapitalizedInterests ON LoanFinances.Id = LoanCapitalizedInterests.LoanFinanceId AND LoanCapitalizedInterests.IsActive=1
WHERE LoanCapitalizedInterests.Source = 'ProgressLoan'
AND LoanCapitalizedInterests.CapitalizedDate <= C.CommencementDate
GROUP BY C.ContractId
INSERT INTO #LoanNoteReceivableSetupAmount(ContractId,NoteReceivableSetupAmount,OriginationFundingAmount,AccruedInterestCapitalized)
SELECT C.ContractId
,ISNULL(OriginationFundingAmountInfo.OriginationFundingAmount,0) + ISNULL(FutureScheduleFundedAmountInfo.FutureScheduleFundedAmount,0) + ISNULL(AccruedInterestCapitalizedInfo.AccruedInterestCapitalized,0)
,ISNULL(OriginationFundingAmountInfo.OriginationFundingAmount,0)
,ISNULL(AccruedInterestCapitalizedInfo.AccruedInterestCapitalized,0)
FROM #LoanContracts C
LEFT JOIN #OriginationFundingAmountInfo OriginationFundingAmountInfo ON C.ContractId = OriginationFundingAmountInfo.ContractId
LEFT JOIN #AccruedInterestCapitalizedInfo AccruedInterestCapitalizedInfo ON C.ContractId = AccruedInterestCapitalizedInfo.ContractId
LEFT JOIN (SELECT ContractId,SUM(PaidAmount) FutureScheduleFundedAmount FROM #DRPaidInfo WHERE Type = 'FutureScheduledFunded' GROUP BY ContractId)
AS FutureScheduleFundedAmountInfo ON C.ContractId = FutureScheduleFundedAmountInfo.ContractId
SELECT
C.ContractId,
LoanIncomeSchedules.IncomeDate,
LoanIncomeSchedules.IsNonAccrual,
LoanIncomeSchedules.InterestAccrued_Amount InterestAccrued
INTO #GLPostedLoanIncomeSchedules
FROM #LoanContracts C
JOIN LoanFinances ON C.ContractId = LoanFinances.ContractId
JOIN LoanIncomeSchedules ON LoanFinances.Id = LoanIncomeSchedules.LoanFinanceId AND LoanIncomeSchedules.IncomeDate <= C.IncomeGLPostedTillDate
AND LoanIncomeSchedules.IsSchedule=1 AND LoanIncomeSchedules.IsLessorOwned=1
CREATE TABLE #NonGLPostedInvestmentPayables(ContractId BIGINT, GLTemplateId BIGINT,Amount DECIMAL(16,2));
INSERT INTO #NonGLPostedInvestmentPayables
SELECT C.ContractId,PayableCodes.GLTemplateId,SUM(Payables.Amount_Amount) Amount
FROM #LoanContracts C
JOIN LoanFinances ON C.LoanFinanceId = LoanFinances.Id
JOIN LoanFundings ON LoanFinances.Id = LoanFundings.LoanFinanceId AND LoanFundings.IsActive=1 AND LoanFundings.Type = 'Origination'
JOIN PayableInvoices ON LoanFundings.FundingId = PayableInvoices.Id AND PayableInvoices.DueDate <= C.CommencementDate
JOIN PayableInvoiceOtherCosts ON PayableInvoices.Id = PayableInvoiceOtherCosts.PayableInvoiceId AND PayableInvoiceOtherCosts.IsActive=1
AND PayableInvoiceOtherCosts.AllocationMethod IN ('LoanDisbursement','ProgressPaymentCredit')
JOIN Payables ON PayableInvoiceOtherCosts.Id = Payables.SourceId AND Payables.SourceTable = 'PayableInvoiceOtherCost' AND Payables.IsGLPosted=0 AND Payables.Status <> 'Inactive'
JOIN PayableCodes ON Payables.PayableCodeId = PayableCodes.Id
GROUP BY C.ContractId,PayableCodes.GLTemplateId
CREATE TABLE #ClearedAmounts(ContractId BIGINT,ClearedNoteReceivableAmount DECIMAL(16,2),ClearedAccruedInterestAmount DECIMAL(16,2));
INSERT INTO #ClearedAmounts
SELECT ContractId,SUM(ClearedNoteReceivableAmount) ClearedNoteReceivableAmount,SUM(ClearedAccruedInterestAmount) ClearedAccruedInterestAmount
FROM
(SELECT C.ContractId
,CASE WHEN LoanPaydowns.PaydownReason IN ('Repossession','Casualty') THEN SUM(LoanPaydowns.PrincipalPaydown_Amount)
WHEN LoanPaydowns.PaydownReason = 'FullPaydown' THEN SUM(LoanPaydowns.PrincipalBalance_Amount) + SUM(LoanPaydowns.PrincipalPaydown_Amount)
ELSE 0 END AS ClearedNoteReceivableAmount
,CASE WHEN LoanPaydowns.PaydownReason IN ('Repossession','Casualty') THEN SUM(LoanPaydowns.InterestPaydown_Amount)
WHEN LoanPaydowns.PaydownReason = 'FullPaydown' THEN SUM(LoanPaydowns.AccruedInterest_Amount) + SUM(LoanPaydowns.InterestPaydown_Amount)
ELSE 0 END AS ClearedAccruedInterestAmount
FROM #LoanContracts C
JOIN LoanFinances ON C.ContractId = LoanFinances.ContractId
JOIN LoanPaydowns ON LoanFinances.Id = LoanPaydowns.LoanFinanceId
WHERE LoanPaydowns.Status = 'Active'
GROUP BY C.ContractId,LoanPaydowns.PaydownReason) AS LoanPaydownSummary
GROUP BY ContractId
CREATE TABLE #GLPostedLoanReceivables (ContractId BIGINT,LoanInterestAmountPosted DECIMAL(16,2),LoanPrincipalAmountPosted DECIMAL(16,2));
INSERT INTO #GLPostedLoanReceivables
SELECT ContractId,SUM(LoanInterestAmountPosted) LoanInterestAmountPosted,SUM(LoanPrincipalAmountPosted) LoanPrincipalAmountPosted
FROM (SELECT Contract.ContractId
,ReceivableTypes.Name
,CASE WHEN ReceivableTypes.Name = 'LoanInterest' THEN SUM(Receivables.TotalAmount_Amount) ELSE 0 END AS LoanInterestAmountPosted
,CASE WHEN ReceivableTypes.Name = 'LoanPrincipal' THEN SUM(Receivables.TotalAmount_Amount) ELSE 0 END AS LoanPrincipalAmountPosted
FROM #LoanContracts Contract
JOIN Receivables ON Contract.ContractId = Receivables.EntityId AND Receivables.EntityType = 'CT' AND Receivables.IsGLPosted=1 AND Receivables.IsActive=1
JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id AND ReceivableTypes.Name IN ('LoanPrincipal','LoanInterest')
LEFT JOIN LoanPaymentSchedules ON Receivables.PaymentScheduleId = LoanPaymentSchedules.Id
WHERE ISNULL(LoanPaymentSchedules.EndDate,Receivables.DueDate) < @EffectiveDate
AND Receivables.FunderId IS NULL
GROUP BY Contract.ContractId,ReceivableTypes.Name) AS GLPostedLoanReceivables
GROUP BY ContractId
CREATE TABLE #RemainingBalanceInfo(ContractId BIGINT,RemainingBalanceInNoteReceivable DECIMAL(16,2),RemainingBalanceInAccruedInterest DECIMAL(16,2));
INSERT INTO #RemainingBalanceInfo
SELECT NoteReceivable.ContractId
,ISNULL(NoteReceivable.NoteReceivableSetupAmount,0) - ISNULL(GLPostedLoanReceivable.LoanPrincipalAmountPosted,0) - ISNULL(ClearedAmount.ClearedNoteReceivableAmount,0) - ISNULL(ClearedAmountInSyndication.SoldNBV_Amount,0) RemainingBalanceInNoteReceivable
,ISNULL(GLPostedLoanIncome.InterestAccrued,0) - ISNULL(GLPostedLoanReceivable.LoanInterestAmountPosted,0) - ISNULL(NoteReceivable.AccruedInterestCapitalized,0) - ISNULL(ClearedAmount.ClearedAccruedInterestAmount,0) - ISNULL(ClearedAmountInSyndication.SoldInterestAccrued_Amount,0) RemainingBalanceInAccruedInterest
FROM #LoanNoteReceivableSetupAmount NoteReceivable
LEFT JOIN #ClearedAmounts ClearedAmount ON NoteReceivable.ContractId = ClearedAmount.ContractId
LEFT JOIN #ReceivableForTransfers ClearedAmountInSyndication ON NoteReceivable.ContractId = ClearedAmountInSyndication.ContractId
LEFT JOIN #GLPostedLoanReceivables GLPostedLoanReceivable ON NoteReceivable.ContractId = GLPostedLoanReceivable.ContractId
LEFT JOIN (SELECT ContractId,SUM(InterestAccrued) InterestAccrued FROM #GLPostedLoanIncomeSchedules GROUP BY ContractId) AS GLPostedLoanIncome ON NoteReceivable.ContractId = GLPostedLoanIncome.ContractId
WHERE (NoteReceivable.ContractId IS NOT NULL OR GLPostedLoanReceivable.ContractId IS NOT NULL
OR ClearedAmount.ContractId IS NOT NULL OR ClearedAmountInSyndication.ContractId IS NOT NULL
OR GLPostedLoanIncome.ContractId IS NOT NULL)
IF EXISTS(SELECT ContractId FROM #RemainingBalanceInfo WHERE RemainingBalanceInNoteReceivable <> 0)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'LoanBooking',
C.LoanBookingGLTemplateId,
'NoteReceivable',
RB.RemainingBalanceInNoteReceivable,
1
FROM
#RemainingBalanceInfo RB
JOIN #LoanContracts C ON RB.ContractId = C.ContractId
WHERE RemainingBalanceInNoteReceivable<>0
END
IF EXISTS(SELECT ContractId FROM #NonGLPostedInvestmentPayables WHERE Amount <> 0)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit,MatchingGLTemplateId)
SELECT
C.ContractId,
'LoanBooking',
C.LoanBookingGLTemplateId,
'WorkInProcessLoan',
NonGLPostedInvestmentPayableGroup.Amount,
0,
NonGLPostedInvestmentPayableGroup.GLTemplateId
FROM
#NonGLPostedInvestmentPayables NonGLPostedInvestmentPayableGroup
JOIN #LoanContracts C ON NonGLPostedInvestmentPayableGroup.ContractId = C.ContractId
WHERE NonGLPostedInvestmentPayableGroup.Amount<>0
END
IF EXISTS(SELECT ContractId FROM #RemainingBalanceInfo WHERE RemainingBalanceInAccruedInterest <> 0)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'LoanIncomeRecognition',
C.LoanIncomeRecognitionGLTemplateId,
'AccruedInterest',
RB.RemainingBalanceInAccruedInterest,
1
FROM
#RemainingBalanceInfo RB
JOIN #LoanContracts C ON RB.ContractId = C.ContractId
WHERE RemainingBalanceInAccruedInterest<>0
END
IF(@MovePLBalance = 1)
BEGIN
IF EXISTS(SELECT ContractId FROM #GLPostedLoanIncomeSchedules WHERE IsNonAccrual = 0 AND IncomeDate >= @PLEffectiveDate AND IncomeDate < @EffectiveDate)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'LoanIncomeRecognition',
C.LoanIncomeRecognitionGLTemplateId,
'InterestIncome',
SUM(GLPostedIncome.InterestAccrued),
0
FROM
#GLPostedLoanIncomeSchedules GLPostedIncome
JOIN #LoanContracts C ON GLPostedIncome.ContractId = C.ContractId
WHERE GLPostedIncome.IncomeDate >= @PLEffectiveDate AND GLPostedIncome.IncomeDate < @EffectiveDate
GROUP BY C.ContractId,C.LoanIncomeRecognitionGLTemplateId
HAVING SUM(GLPostedIncome.InterestAccrued)<>0
END
END
IF(@MovePLBalance=1)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'Paydown',
LoanPaydowns.PaydownGLTemplateId,
'GainLossAdjustment',
LoanPaydowns.GainLoss_Amount,
0
FROM
#LoanContracts C
JOIN LoanFinances ON C.ContractId = LoanFinances.ContractId
JOIN LoanPaydowns ON LoanFinances.Id = LoanPaydowns.LoanFinanceId
WHERE LoanPaydowns.Status = 'Active'
AND LoanPaydowns.PaydownDate >= @PLEffectiveDate
AND LoanPaydowns.PaydownDate < @EffectiveDate
AND LoanPaydowns.GainLoss_Amount <> 0
END
IF EXISTS(SELECT ContractId FROM #LoanContracts WHERE IsNonAccrual=1)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'LoanIncomeRecognition',
C.LoanIncomeRecognitionGLTemplateId,
'SuspendedIncome',
SUM(#GLPostedLoanIncomeSchedules.InterestAccrued),
0
FROM
(SELECT * FROM #LoanContracts WHERE IsNonAccrual=1) C
JOIN #GLPostedLoanIncomeSchedules ON C.ContractId = #GLPostedLoanIncomeSchedules.ContractId AND #GLPostedLoanIncomeSchedules.IsNonAccrual=1
WHERE #GLPostedLoanIncomeSchedules.IncomeDate <= C.IncomeGLPostedTillDate
GROUP BY C.ContractId,C.LoanIncomeRecognitionGLTemplateId
END
END
CREATE TABLE #LeaseContracts
(
ContractId BIGINT PRIMARY KEY,
SyndicationType NVARCHAR(32),
IncomeGLPostedTillDate DATE,
FloatRateIncomeGLPostedTillDate DATE,
CommencementDate DATE,
LeaseFinanceId BIGINT,
LeaseContractType NVARCHAR(32),
InterimAssessmentMethod NVARCHAR(16),
CapitalizeUpfrontSalesTax BIT,
IsTaxLease BIT,
InterimInterestBillingType NVARCHAR(34),
InterimRentBillingType NVARCHAR(34),
IsFloatRateLease BIT,
IsOTPOrSupplementalCashBased BIT,
IsOverTermLease BIT,
IsFutureFunding BIT,
RetainedPercentage DECIMAL(18,8),
PostDate DATE,
IsSyndicatedAtInception BIT,
IsNonAccrual BIT,
ProfitLossStatus NVARCHAR(28),
IsFASBChangesApplicable BIT,
NonAccrualDate DATE
);
INSERT INTO #LeaseContracts
SELECT ContractInfo.ContractId,
Contracts.SyndicationType,
IncomeGLPostedTillDate,
ContractInfo.FloatRateIncomeGLPostedTillDate,
LeaseFinanceDetails.CommencementDate,
LeaseFinances.Id LeaseFinanceId,
LeaseFinanceDetails.LeaseContractType,
LeaseFinanceDetails.InterimAssessmentMethod,
LeaseFinanceDetails.CapitalizeUpfrontSalesTax,
LeaseFinanceDetails.IsTaxLease,
LeaseFinanceDetails.InterimInterestBillingType,
LeaseFinanceDetails.InterimRentBillingType,
LeaseFinanceDetails.IsFloatRateLease,
CASE WHEN (LeaseFinanceDetails.OTPReceivableCodeId IS NOT NULL AND OTPReceivableCode.AccountingTreatment = 'CashBased') OR (LeaseFinanceDetails.SupplementalReceivableCodeId IS NOT NULL AND SupplementalReceivableCode.AccountingTreatment = 'CashBased')
THEN 1 ELSE 0 END AS IsOTPOrSupplementalCashBased,
LeaseFinanceDetails.IsOverTermLease,
LeaseFinances.IsFutureFunding,
CASE WHEN Contracts.SyndicationType <> 'None' THEN (ISNULL(LeaseSyndications.RetainedPercentage,R.RetainedPercentage)/100) ELSE 1 END,
LeaseFinanceDetails.PostDate,
CASE WHEN LeaseSyndications.Id IS NULL THEN 0 ELSE 1 END AS IsSyndicatedAtInception,
Contracts.IsNonAccrual,
LeaseFinanceDetails.ProfitLossStatus AS ProfitLossStatus,
ContractInfo.IsFASBChangesApplicable AS IsFASBChangesApplicable,
Contracts.NonAccrualDate
FROM #ContractInfo ContractInfo
JOIN Contracts ON ContractInfo.ContractId = Contracts.Id AND ContractInfo.ContractType = 'Lease' AND ContractInfo.IsChargedOff = 0
JOIN LeaseFinances ON ContractInfo.ContractId = LeaseFinances.ContractId AND LeaseFinances.IsCurrent=1
JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
LEFT JOIN LeaseSyndications ON LeaseFinances.Id = LeaseSyndications.Id AND LeaseSyndications.IsActive=1
LEFT JOIN #ReceivableForTransfers R ON LeaseFinances.ContractId = R.ContractId
LEFT JOIN ReceivableCodes OTPReceivableCode ON LeaseFinanceDetails.OTPReceivableCodeId = OTPReceivableCode.Id
LEFT JOIN ReceivableCodes SupplementalReceivableCode ON LeaseFinanceDetails.SupplementalReceivableCodeId = SupplementalReceivableCode.Id

IF EXISTS(SELECT ContractId FROM #LeaseContracts)
BEGIN
CREATE TABLE #AccruedIncomeBalanceSummary
(
ContractId BIGINT PRIMARY KEY,
AccruedFloatRateInterestIncomeBalance DECIMAL(16,2) default 0,
AccruedInterimInterestBalance DECIMAL(16,2) default 0,
DeferredInterimRentIncomeBalance DECIMAL(16,2) default 0,
DeferredRentalRevenueBalance DECIMAL(16,2) default 0,
IsFirstOTPIncomeGLPosted BIT default 0,
OTPDeferredIncomeBalance DECIMAL(16,2) default 0,
SupplementalDeferredIncomeBalance DECIMAL(16,2) default 0,
ClearedOTPLeaseAssetAmount DECIMAL(16,2) default 0,
FloatRateSuspendedIncomeBalance DECIMAL(16,2) default 0,
SuspendedIncomeBalance DECIMAL(16,2) default 0,
FinancingSuspendedIncomeBalance DECIMAL(16,2) default 0,
SuspendedUnguaranteedResidualIncomeBalance DECIMAL(16,2) default 0,
FinancingSuspendedUnguaranteedResidualIncomeBalance DECIMAL(16,2) default 0,
SuspendedRentalRevenueBalance DECIMAL(16,2) default 0,
SuspendedOTPIncomeBalance DECIMAL(16,2) default 0,
SuspendedSupplementalIncomeBalance DECIMAL(16,2) default 0,
InterimRentIncome DECIMAL(16,2) default 0,
LeaseInterimInterestIncome DECIMAL(16,2) default 0,
Income DECIMAL(16,2) default 0,
FinancingIncome DECIMAL(16,2) default 0,
UnguaranteedResidualIncome DECIMAL(16,2) default 0,
FinancingUnguaranteedResidualIncome DECIMAL(16,2) default 0,
RentalRevenue DECIMAL(16,2) default 0,
SellingProfitIncome DECIMAL(16,2) default 0,
SuspendedSellingProfitIncome DECIMAL(16,2) default 0,
FixedTermDepreciation DECIMAL(16,2) default 0,
OTPDepreciation DECIMAL(16,2) default 0,
ResidualRecapture DECIMAL(16,2) default 0,
OTPIncome DECIMAL(16,2) default 0,
SupplementalIncome DECIMAL(16,2) default 0,
FloatInterestIncome DECIMAL(16,2) default 0,
AccumulatedFixedTermDepreciation DECIMAL(16,2) default 0,
AccumulatedOTPDepreciation DECIMAL(16,2) default 0
);


SELECT C.ContractId
,LeaseAssets.Id LeaseAsset_Id
,LeaseAssets.IsLeaseAsset IsLeaseComponent
,LeaseAssets.NBV_Amount 
,LeaseAssets.CapitalizedInterimInterest_Amount 
,LeaseAssets.CapitalizedInterimRent_Amount 
,LeaseAssets.CapitalizedSalesTax_Amount 
,LeaseAssets.CapitalizedProgressPayment_Amount
,C.RetainedPercentage
,LeaseAssets.ETCAdjustmentAmount_Amount 
,LeaseAssets.CustomerGuaranteedResidual_Amount CustomerGuaranteedResidual
,LeaseAssets.ThirdPartyGuaranteedResidual_Amount ThirdPartyGuaranteedResidual
,LeaseAssets.BookedResidual_Amount BookedResidual
,LeaseAssetIncomeDetails.SalesTypeNBV_Amount  SalesTypeNBV
,LeaseAssets.FMV_Amount 
,LeaseAssets.CapitalizedIDC_Amount
,LeaseAssets.AssetId
INTO #LeaseAssetInfo
FROM #LeaseContracts C
JOIN LeaseAssets ON C.LeaseFinanceId = LeaseAssets.LeaseFinanceId AND LeaseAssets.IsActive=1 AND LeaseAssets.CapitalizedForId IS NULL 
JOIN LeaseAssetIncomeDetails on LeaseAssets.Id = LeaseAssetIncomeDetails.Id


SELECT #LeaseAssetInfo.ContractId
,CapitalizedLeaseAsset.IsLeaseAsset
,SUM(CapitalizedLeaseAsset.NBV_Amount) CapitalizedCost
,SUM(LeaseAssetIncomeDetails.SalesTypeNBV_Amount) SalesTypeNBV
,SUM(CapitalizedLeaseAsset.CapitalizedIDC_Amount) CapitalizedIDC
,SUM(CapitalizedLeaseAsset.FMV_Amount) FMV
,SUM(CASE WHEN CapitalizedLeaseAsset.CapitalizationType = 'CapitalizedInterimInterest' THEN CapitalizedLeaseAsset.NBV_Amount ELSE 0 END) CapitalizedInterimInterest
,SUM(CASE WHEN CapitalizedLeaseAsset.CapitalizationType = 'CapitalizedInterimRent' THEN CapitalizedLeaseAsset.NBV_Amount ELSE 0 END) CapitalizedInterimRent
,SUM(CASE WHEN CapitalizedLeaseAsset.CapitalizationType = 'CapitalizedProgressPayment' THEN CapitalizedLeaseAsset.NBV_Amount ELSE 0 END) CapitalizedProgressPayment
,SUM(CASE WHEN CapitalizedLeaseAsset.CapitalizationType = 'CapitalizedSalesTax' THEN CapitalizedLeaseAsset.NBV_Amount ELSE 0 END) CapitalizedSalesTax
INTO #CapitalizedLeaseAssetInfo
FROM #LeaseAssetInfo 
JOIN LeaseAssets CapitalizedLeaseAsset ON #LeaseAssetInfo.LeaseAsset_Id = CapitalizedLeaseAsset.CapitalizedForId AND CapitalizedLeaseAsset.IsActive=1
JOIN LeaseAssetIncomeDetails ON CapitalizedLeaseAsset.Id = LeaseAssetIncomeDetails.Id
GROUP BY #LeaseAssetInfo.ContractId, CapitalizedLeaseAsset.IsLeaseAsset


SELECT 
#LeaseAssetInfo.ContractId,
#LeaseAssetInfo.LeaseAsset_Id,
LeaseAssetSKUs.IsLeaseComponent,
MAX(#LeaseAssetInfo.RetainedPercentage) RetainedPercentage,
SUM(LeaseAssetSKUs.NBV_Amount) NBV_Amount,
SUM(LeaseAssetSKUs.CapitalizedIDC_Amount) CapitalizedIDC_Amount,
SUM(LeaseAssetSKUs.FMV_Amount) FMV_Amount, 
SUM(LeaseAssetSKUs.CustomerGuaranteedResidual_Amount) CustomerGuaranteedResidual_Amount,
SUM(LeaseAssetSKUs.ThirdPartyGuaranteedResidual_Amount) ThirdPartyGuaranteedResidual_Amount,
SUM(LeaseAssetSKUs.BookedResidual_Amount) BookedResidual_Amount,
SUM(LeaseAssetSKUs.ETCAdjustmentAmount_Amount) ETCAdjustmentAmount_Amount,
SUM(LeaseAssetSKUs.CapitalizedInterimInterest_Amount) CapitalizedInterimInterest_Amount,
SUM(LeaseAssetSKUs.CapitalizedInterimRent_Amount) CapitalizedInterimRent_Amount,
SUM(LeaseAssetSKUs.CapitalizedSalesTax_Amount) CapitalizedSalesTax_Amount,
SUM(LeaseAssetSKUs.CapitalizedProgressPayment_Amount) CapitalizedProgressPayment_Amount,
SUM(#LeaseAssetInfo.SalesTypeNBV) SalesTypeNBV
INTO #LeaseAssetSKUInfo
FROM  #LeaseAssetInfo
JOIN LeaseAssetSKUs  ON #LeaseAssetInfo.LeaseAsset_Id = LeaseAssetSKUs.LeaseAssetId AND LeaseAssetSKUs.IsActive=1
GROUP BY #LeaseAssetInfo.ContractId,#LeaseAssetInfo.LeaseAsset_Id,LeaseAssetSKUs.IsLeaseComponent



SELECT #LeaseAssetInfo.ContractId
,#LeaseAssetInfo.IsLeaseComponent
,SUM(ROUND((#LeaseAssetInfo.NBV_Amount - #LeaseAssetInfo.CapitalizedInterimInterest_Amount - #LeaseAssetInfo.CapitalizedInterimRent_Amount - #LeaseAssetInfo.CapitalizedSalesTax_Amount - #LeaseAssetInfo.CapitalizedProgressPayment_Amount) * #LeaseAssetInfo.RetainedPercentage,2)) Investment
,SUM(ROUND(#LeaseAssetInfo.ETCAdjustmentAmount_Amount * #LeaseAssetInfo.RetainedPercentage,2)) ETCAdjustmentAmount
,SUM(#LeaseAssetInfo.CapitalizedInterimInterest_Amount) + ISNULL(CapitalizedAssets.CapitalizedInterimInterest,0) CapitalizedInterimInterest
,SUM(#LeaseAssetInfo.CapitalizedInterimRent_Amount) + ISNULL(CapitalizedAssets.CapitalizedInterimInterest,0) CapitalizedInterimRent
,SUM(#LeaseAssetInfo.CapitalizedSalesTax_Amount) + ISNULL(CapitalizedAssets.CapitalizedSalesTax,0) CapitalizedSalesTax
,SUM(#LeaseAssetInfo.CapitalizedInterimInterest_Amount + #LeaseAssetInfo.CapitalizedInterimRent_Amount + #LeaseAssetInfo.CapitalizedSalesTax_Amount + #LeaseAssetInfo.CapitalizedProgressPayment_Amount) + ISNULL(CapitalizedAssets.CapitalizedCost,0) AS CapitalizedAmount
,SUM(#LeaseAssetInfo.CustomerGuaranteedResidual) CustomerGuaranteedResidual
,SUM(#LeaseAssetInfo.ThirdPartyGuaranteedResidual) ThirdPartyGuaranteedResidual
,SUM(#LeaseAssetInfo.BookedResidual) BookedResidual
,SUM(#LeaseAssetInfo.SalesTypeNBV) + ISNULL(CapitalizedAssets.SalesTypeNBV,0) SalesTypeNBV
,SUM(#LeaseAssetInfo.FMV_Amount) + ISNULL(CapitalizedAssets.FMV,0) FMV
,SUM(#LeaseAssetInfo.NBV_Amount) + ISNULL(CapitalizedAssets.CapitalizedCost,0) NBV
,SUM(#LeaseAssetInfo.CapitalizedIDC_Amount) + ISNULL(CapitalizedAssets.CapitalizedIDC,0) CapitalizedIDC 
INTO #LeaseInvestmentInfoDetail
FROM #LeaseAssetInfo
LEFT JOIN  #CapitalizedLeaseAssetInfo AS CapitalizedAssets ON #LeaseAssetInfo.ContractId = CapitalizedAssets.ContractId AND #LeaseAssetInfo.IsLeaseComponent = CapitalizedAssets.IsLeaseAsset
LEFT JOIN #LeaseAssetSKUInfo on #LeaseAssetInfo.LeaseAsset_Id= #LeaseAssetSKUInfo.LeaseAsset_Id
where #LeaseAssetSKUInfo.LeaseAsset_Id is null
GROUP BY #LeaseAssetInfo.ContractId,#LeaseAssetInfo.IsLeaseComponent,CapitalizedAssets.CapitalizedCost,CapitalizedAssets.SalesTypeNBV,CapitalizedAssets.CapitalizedInterimInterest,CapitalizedAssets.CapitalizedInterimRent,CapitalizedAssets.CapitalizedSalesTax,CapitalizedAssets.FMV,CapitalizedAssets.CapitalizedIDC



INSERT INTO #LeaseInvestmentInfoDetail
SELECT 
#LeaseAssetSKUInfo.ContractId
,#LeaseAssetSKUInfo.IsLeaseComponent
,SUM(ROUND((#LeaseAssetSKUInfo.NBV_Amount - #LeaseAssetSKUInfo.CapitalizedInterimInterest_Amount - #LeaseAssetSKUInfo.CapitalizedInterimRent_Amount - #LeaseAssetSKUInfo.CapitalizedSalesTax_Amount - #LeaseAssetSKUInfo.CapitalizedProgressPayment_Amount) * #LeaseAssetSKUInfo.RetainedPercentage,2)) Investment
,SUM(ROUND(#LeaseAssetSKUInfo.ETCAdjustmentAmount_Amount * #LeaseAssetSKUInfo.RetainedPercentage,2)) ETCAdjustmentAmount
,SUM(#LeaseAssetSKUInfo.CapitalizedInterimInterest_Amount) + ISNULL(CapitalizedAssets.CapitalizedInterimInterest,0) CapitalizedInterimInterest
,SUM(#LeaseAssetSKUInfo.CapitalizedInterimRent_Amount) + ISNULL(CapitalizedAssets.CapitalizedInterimInterest,0) CapitalizedInterimRent
,SUM(#LeaseAssetSKUInfo.CapitalizedSalesTax_Amount) + ISNULL(CapitalizedAssets.CapitalizedSalesTax,0) CapitalizedSalesTax
,SUM(#LeaseAssetSKUInfo.CapitalizedInterimInterest_Amount + #LeaseAssetSKUInfo.CapitalizedInterimRent_Amount + #LeaseAssetSKUInfo.CapitalizedSalesTax_Amount + #LeaseAssetSKUInfo.CapitalizedProgressPayment_Amount) + ISNULL(CapitalizedAssets.CapitalizedCost,0) AS CapitalizedAmount
,SUM(#LeaseAssetSKUInfo.CustomerGuaranteedResidual_Amount) CustomerGuaranteedResidual
,SUM(#LeaseAssetSKUInfo.ThirdPartyGuaranteedResidual_Amount) ThirdPartyGuaranteedResidual
,SUM(#LeaseAssetSKUInfo.BookedResidual_Amount) BookedResidual
,SUM(#LeaseAssetSKUInfo.SalesTypeNBV) + ISNULL(CapitalizedAssets.SalesTypeNBV,0) SalesTypeNBV
,SUM(#LeaseAssetSKUInfo.FMV_Amount) + ISNULL(CapitalizedAssets.FMV,0) FMV
,SUM(#LeaseAssetSKUInfo.NBV_Amount) + ISNULL(CapitalizedAssets.CapitalizedCost,0) NBV
,SUM(#LeaseAssetSKUInfo.CapitalizedIDC_Amount) + ISNULL(CapitalizedAssets.CapitalizedIDC,0) CapitalizedIDC
FROM 
#LeaseAssetSKUInfo  
LEFT JOIN  #CapitalizedLeaseAssetInfo AS CapitalizedAssets ON #LeaseAssetSKUInfo.ContractId = CapitalizedAssets.ContractId AND #LeaseAssetSKUInfo.IsLeaseComponent = CapitalizedAssets.IsLeaseAsset
GROUP BY #LeaseAssetSKUInfo.ContractId,#LeaseAssetSKUInfo.IsLeaseComponent,CapitalizedAssets.CapitalizedCost,CapitalizedAssets.SalesTypeNBV,CapitalizedAssets.CapitalizedInterimInterest,CapitalizedAssets.CapitalizedInterimRent,CapitalizedAssets.CapitalizedSalesTax,CapitalizedAssets.FMV,CapitalizedAssets.CapitalizedIDC


select 
 ContractId,IsLeaseComponent ,
 sum(Investment) Investment,
 sum(ETCAdjustmentAmount) ETCAdjustmentAmount,
 sum(CapitalizedInterimInterest) CapitalizedInterimInterest,
 sum(CapitalizedInterimRent) CapitalizedInterimRent,
 sum(CapitalizedSalesTax) CapitalizedSalesTax,
 sum(CapitalizedAmount) CapitalizedAmount,
 sum(CustomerGuaranteedResidual) CustomerGuaranteedResidual,
 sum(ThirdPartyGuaranteedResidual) ThirdPartyGuaranteedResidual,
 sum(BookedResidual) BookedResidual,
 sum(SalesTypeNBV) SalesTypeNBV,
 sum(FMV) FMV,
 sum(NBV) NBV,
 sum(CapitalizedIDC) CapitalizedIDC
into #LeaseInvestmentInfo
from #LeaseInvestmentInfoDetail
group by ContractId,IsLeaseComponent 

DECLARE @ValidReceivableTypes TABLE(Id BIGINT,Name NVARCHAR(42));
DECLARE @ValidIncomeTypes TABLE(IncomeType NVARCHAR(30));
INSERT INTO @ValidReceivableTypes
SELECT Id,Name FROM ReceivableTypes
WHERE Name IN('LeaseInterimInterest','InterimRental','OperatingLeaseRental','CapitalLeaseRental','OverTermRental','Supplemental','LeaseFloatRateAdj');
INSERT INTO @ValidIncomeTypes VALUES ('InterimInterest'),('InterimRent'),('FixedTerm'),('OverTerm'),('Supplemental');
CREATE TABLE #LeaseRentalReceivables
(
ContractId BIGINT,
ReceivableType NVARCHAR(42),
IsGLPosted BIT,
AccountingTreatment NVARCHAR(24),
AmountPosted DECIMAL(16,2),
LeaseComponentAmountPosted DECIMAL(16,2),
NonLeaseComponentAmountPosted DECIMAL(16,2),
ReceivableId BIGINT,
DueDate DATE,
IsLeaseAsset BIT
);
INSERT INTO #LeaseRentalReceivables
SELECT C.ContractId
,ValidReceivableType.Name
,Receivables.IsGLPosted
,ReceivableCodes.AccountingTreatment
,SUM(ReceivableDetails.Amount_Amount) TotalAmount_Amount
,SUM(ReceivableDetails.LeaseComponentAmount_Amount) TotalLeaseComponentAmount_Amount
,SUM(ReceivableDetails.NonLeaseComponentAmount_Amount) TotalNonLeaseComponentAmount_Amount
,Receivables.Id
,ISNULL(LeasePaymentSchedules.EndDate,Receivables.DueDate) DueDate
,LeaseAssetInfo.IsLeaseAsset
FROM
#LeaseContracts C
JOIN Receivables ON C.ContractId = Receivables.EntityId AND Receivables.EntityType = 'CT' AND Receivables.IsActive=1 AND Receivables.FunderId IS NULL
JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
JOIN @ValidReceivableTypes ValidReceivableType ON ReceivableCodes.ReceivableTypeId = ValidReceivableType.Id
JOIN ReceivableDetails ON Receivables.Id = ReceivableDetails.ReceivableId AND ReceivableDetails.IsActive=1
LEFT JOIN LeasePaymentSchedules ON Receivables.PaymentScheduleId = LeasePaymentSchedules.Id
LEFT JOIN (SELECT C.ContractId,LeaseAssets.AssetId,LeaseAssets.IsLeaseAsset
FROM #LeaseContracts C
JOIN LeaseFinances ON C.ContractId = LeaseFinances.ContractId AND LeaseFinances.IsCurrent=1
JOIN LeaseAssets ON LeaseFinances.Id = LeaseAssets.LeaseFinanceId AND (LeaseAssets.IsActive=1 OR LeaseAssets.TerminationDate IS NOT NULL))
AS LeaseAssetInfo ON ReceivableDetails.AssetId = LeaseAssetInfo.AssetId AND C.ContractId = LeaseAssetInfo.ContractId
GROUP BY C.ContractId,
Receivables.Id,
ValidReceivableType.Name,
Receivables.IsGLPosted,
ReceivableCodes.AccountingTreatment,
LeasePaymentSchedules.EndDate,
Receivables.DueDate,
LeaseAssetInfo.IsLeaseAsset
CREATE TABLE #LeaseIncomeScheduleInfoForGLTransfer
(
ContractId BIGINT,
Depreciation DECIMAL(16,2),
Income DECIMAL(16,2),
FinancingIncome DECIMAL(16,2),
IncomeDate DATE,
IncomeType NVARCHAR(30),
IsGLPosted BIT,
IsNonAccrual BIT,
RentalIncome DECIMAL(16,2),
ResidualIncome DECIMAL(16,2),
FinancingResidualIncome DECIMAL(16,2),
DeferredSellingProfitIncome DECIMAL(16,2),
AccountingTreatment NVARCHAR(24),
IsReclassOTP BIT
);
INSERT INTO #LeaseIncomeScheduleInfoForGLTransfer
SELECT C.ContractId
,LeaseIncomeSchedules.Depreciation_Amount
,LeaseIncomeSchedules.Income_Amount
,LeaseIncomeSchedules.FinanceIncome_Amount
,LeaseIncomeSchedules.IncomeDate
,LeaseIncomeSchedules.IncomeType
,LeaseIncomeSchedules.IsGLPosted
,LeaseIncomeSchedules.IsNonAccrual
,LeaseIncomeSchedules.RentalIncome_Amount
,LeaseIncomeSchedules.ResidualIncome_Amount
,LeaseIncomeSchedules.FinanceResidualIncome_Amount
,LeaseIncomeSchedules.DeferredSellingProfitIncome_Amount
,LeaseIncomeSchedules.AccountingTreatment
,LeaseIncomeSchedules.IsReclassOTP
FROM #LeaseContracts C
JOIN LeaseFinances ON C.ContractId = LeaseFinances.ContractId
JOIN LeaseIncomeSchedules ON LeaseFinances.Id = LeaseIncomeSchedules.LeaseFinanceId
JOIN @ValidIncomeTypes ValidIncomeType ON LeaseIncomeSchedules.IncomeType = ValidIncomeType.IncomeType
WHERE LeaseIncomeSchedules.IsSchedule=1 AND LeaseIncomeSchedules.IsLessorOwned=1
CREATE TABLE #FloatRateIncomeInfoForGLTransfer (ContractId BIGINT,FloatRateIncome DECIMAL(16,2),IsNonAccrual BIT,IncomeDate DATE,IsContractInNonAccrual BIT,NonAccrualDate DATE);
IF EXISTS(SELECT ContractId FROM #LeaseContracts WHERE IsFloatRateLease=1)
BEGIN
INSERT INTO #FloatRateIncomeInfoForGLTransfer
SELECT C.ContractId
,LeaseFloatRateIncomes.CustomerIncomeAmount_Amount
,LeaseFloatRateIncomes.IsNonAccrual
,LeaseFloatRateIncomes.IncomeDate
,C.IsNonAccrual
,C.NonAccrualDate
FROM #LeaseContracts C
JOIN LeaseFinances ON C.ContractId = LeaseFinances.ContractId
JOIN LeaseFloatRateIncomes ON LeaseFinances.Id = LeaseFloatRateIncomes.LeaseFinanceId AND LeaseFloatRateIncomes.IsScheduled=1
AND LeaseFloatRateIncomes.IncomeDate <= C.FloatRateIncomeGLPostedTillDate AND LeaseFloatRateIncomes.IsLessorOwned=1
END
CREATE TABLE #CashPostedCashBasedReceivableInfo(ContractId BIGINT,ReceivableIncomeType NVARCHAR(32),IsNonAccrual BIT,IncomeDate DATE,TotalDeferredIncome DECIMAL(16,2),TotalDepreciationAmount DECIMAL(16,2));
IF EXISTS(SELECT ContractId FROM #LeaseRentalReceivables WHERE AccountingTreatment='CashBased' AND DueDate < @EffectiveDate)
BEGIN
INSERT INTO #CashPostedCashBasedReceivableInfo
SELECT
Receivables.EntityId,
Receivables.IncomeType,
LeaseIncomeSchedules.IsNonAccrual,
LeaseIncomeSchedules.IncomeDate,
SUM(ReceiptApplicationReceivableDetails.AmountApplied_Amount) TotalDeferredIncome,
SUM(ISNULL(AssetValueHistoryDetails.AmountPosted_Amount,0)) TotalDepreciationAmount
FROM
(SELECT ReceivableId FROM #LeaseRentalReceivables WHERE AccountingTreatment='CashBased' AND DueDate < @EffectiveDate) AS CashBasedReceivables
JOIN Receivables ON CashBasedReceivables.ReceivableId = Receivables.Id AND Receivables.IsActive=1
JOIN LeasePaymentSchedules ON Receivables.PaymentScheduleId = LeasePaymentSchedules.Id
JOIN LeaseFinances ON Receivables.EntityId = LeaseFinances.ContractId AND Receivables.EntityType = 'CT'
JOIN LeaseIncomeSchedules ON LeaseFinances.Id = LeaseIncomeSchedules.LeaseFinanceId AND LeaseIncomeSchedules.IsSchedule=1 AND LeaseIncomeSchedules.IncomeDate = LeasePaymentSchedules.EndDate
JOIN ReceivableDetails ON Receivables.Id = ReceivableDetails.Id AND ReceivableDetails.IsActive=1
JOIN ReceiptApplicationReceivableDetails ON ReceivableDetails.Id = ReceiptApplicationReceivableDetails.ReceivableDetailId AND ReceiptApplicationReceivableDetails.IsActive=1
JOIN ReceiptApplications ON ReceiptApplicationReceivableDetails.ReceiptApplicationId = ReceiptApplications.Id
JOIN Receipts ON ReceiptApplications.ReceiptId = Receipts.Id AND Receipts.Status = 'Posted'
LEFT JOIN AssetValueHistoryDetails ON ReceiptApplicationReceivableDetails.Id = AssetValueHistoryDetails.ReceiptApplicationReceivableDetailId
LEFT JOIN AssetValueHistories ON AssetValueHistoryDetails.AssetValueHistoryId = AssetValueHistories.Id AND AssetValueHistories.IsLessorOwned = 1
WHERE (AssetValueHistoryDetails.AssetValueHistoryId IS NULL OR (AssetValueHistoryDetails.IsActive=1 AND AssetValueHistories.IsAccounted=1))
GROUP BY Receivables.EntityId,Receivables.IncomeType,LeaseIncomeSchedules.IsNonAccrual,LeaseIncomeSchedules.IncomeDate
END
CREATE TABLE #AccumulatedDepreciationInfo (ContractId BIGINT,SourceModule NVARCHAR(40),TotalAmount DECIMAL(16,2))
CREATE TABLE #AssetValueHistorySummary (ContractId BIGINT,AssetId BIGINT,IsLeaseComponent BIT,MaxAssetValueHistoryId BIGINT);
INSERT INTO #AssetValueHistorySummary
SELECT C.ContractId,AssetValueHistories.AssetId,AssetValueHistories.IsLeaseComponent IsLeaseComponent,MAX(AssetValueHistories.Id) MaxAssetValueHistoryId
FROM #LeaseContracts C
JOIN LeaseAssets ON C.LeaseFinanceId = LeaseAssets.LeaseFinanceId AND LeaseAssets.IsActive=1
JOIN AssetValueHistories ON LeaseAssets.AssetId = AssetValueHistories.AssetId AND AssetValueHistories.IsAccounted=1 AND AssetValueHistories.IsCleared=1 AND AssetValueHistories.IsLessorOwned = 1
GROUP BY C.ContractId,AssetValueHistories.AssetId,AssetValueHistories.IsLeaseComponent
IF EXISTS(SELECT ContractId FROM #LeaseContracts WHERE LeaseContractType = 'Operating' OR IsOverTermLease=1)
BEGIN
INSERT INTO #AccumulatedDepreciationInfo
SELECT ContractId,SourceModule,SUM(TotalAmount) TotalAmount
FROM (SELECT
Contracts.ContractId,
AssetValueHistories.SourceModule,
CASE WHEN LeaseIncomeSchedules.AccountingTreatment = 'AccrualBased' OR (Contracts.LeaseContractType = 'Operating' AND AVH.IsLeaseComponent = 1)
THEN SUM(AssetValueHistories.Value_Amount) * (-1)
ELSE SUM(ISNULL(AssetValueHistoryDetails.AmountPosted_Amount,0.00)) * (-1) END AS TotalAmount
FROM
#LeaseContracts AS Contracts
JOIN #AssetValueHistorySummary AVH ON Contracts.ContractId = AVH.ContractId
JOIN AssetValueHistories ON AVH.AssetId = AssetValueHistories.AssetId AND AVH.IsLeaseComponent = AssetValueHistories.IsLeaseComponent AND AssetValueHistories.IsLessorOwned = 1 AND AssetValueHistories.SourceModule IN('FixedTermDepreciation','OTPDepreciation','ResidualRecapture')
AND AssetValueHistories.IsAccounted=1
AND AssetValueHistories.IncomeDate < @EffectiveDate
JOIN AssetIncomeSchedules ON AVH.AssetId = AssetIncomeSchedules.AssetId AND AssetIncomeSchedules.IsActive=1
JOIN LeaseIncomeSchedules ON AssetIncomeSchedules.LeaseIncomeScheduleId = LeaseIncomeSchedules.Id AND AssetValueHistories.IncomeDate = LeaseIncomeSchedules.IncomeDate AND LeaseIncomeSchedules.IsSchedule = 1
LEFT JOIN AssetValueHistoryDetails ON AssetValueHistories.Id = AssetValueHistoryDetails.AssetValueHistoryId
WHERE AssetValueHistories.Id > AVH.MaxAssetValueHistoryId
AND ((((LeaseIncomeSchedules.AccountingTreatment = 'AccrualBased') OR (Contracts.LeaseContractType = 'Operating' AND AVH.IsLeaseComponent = 1)) AND AssetValueHistories.GLJournalId IS NOT NULL)
OR (LeaseIncomeSchedules.AccountingTreatment = 'CashBased' AND AssetValueHistoryDetails.Id IS NOT NULL AND AssetValueHistoryDetails.IsActive=1))
GROUP BY Contracts.ContractId,AssetValueHistories.SourceModule,Contracts.LeaseContractType,LeaseIncomeSchedules.AccountingTreatment,AVH.IsLeaseComponent) AS DepreciationInfo
GROUP BY ContractId,SourceModule
END
INSERT INTO #AccruedIncomeBalanceSummary(ContractId)
SELECT C.ContractId FROM #LeaseContracts C
UPDATE #AccruedIncomeBalanceSummary
SET AccruedInterimInterestBalance = ISNULL(GLPostedReceivables.AmountPosted,0) - ISNULL(LeaseIncome.Income,0)
FROM #AccruedIncomeBalanceSummary
LEFT JOIN (SELECT R.ContractId,SUM(R.AmountPosted) AmountPosted
FROM #LeaseRentalReceivables R
WHERE R.ReceivableType = 'LeaseInterimInterest' AND R.IsGLPosted=1
AND R.DueDate < @EffectiveDate
GROUP BY R.ContractId)
AS GLPostedReceivables ON #AccruedIncomeBalanceSummary.ContractId = GLPostedReceivables.ContractId
LEFT JOIN (SELECT LIS.ContractId,SUM(LIS.Income) Income
FROM #LeaseIncomeScheduleInfoForGLTransfer LIS
JOIN #LeaseContracts C ON LIS.ContractId = C.ContractId
WHERE LIS.IncomeType = 'InterimInterest'
AND IncomeDate <= C.IncomeGLPostedTillDate
GROUP BY LIS.ContractId)
AS LeaseIncome ON #AccruedIncomeBalanceSummary.ContractId = LeaseIncome.ContractId
WHERE GLPostedReceivables.ContractId IS NOT NULL OR LeaseIncome.ContractId IS NOT NULL
UPDATE #AccruedIncomeBalanceSummary
SET DeferredInterimRentIncomeBalance = ISNULL(GLPostedReceivables.AmountPosted,0) - ISNULL(LeaseIncome.RentalIncome,0)
FROM #AccruedIncomeBalanceSummary
LEFT JOIN (SELECT R.ContractId,SUM(R.AmountPosted) AmountPosted
FROM #LeaseRentalReceivables R
WHERE R.ReceivableType = 'InterimRental' AND R.IsGLPosted=1
AND R.DueDate < @EffectiveDate
GROUP BY R.ContractId)
AS GLPostedReceivables ON #AccruedIncomeBalanceSummary.ContractId = GLPostedReceivables.ContractId
LEFT JOIN (SELECT LIS.ContractId,SUM(LIS.RentalIncome) RentalIncome
FROM #LeaseIncomeScheduleInfoForGLTransfer LIS
JOIN #LeaseContracts C ON LIS.ContractId = C.ContractId
WHERE LIS.IncomeType = 'InterimRent' and
((@DeferInterimRentIncomeRecognition = 1 OR @DeferInterimRentIncomeRecognitionForSingleInstallment = 1) OR
(LIS.IsGLPosted = 1 AND IncomeDate <= C.IncomeGLPostedTillDate))
GROUP BY LIS.ContractId)
AS LeaseIncome ON #AccruedIncomeBalanceSummary.ContractId = LeaseIncome.ContractId
WHERE GLPostedReceivables.ContractId IS NOT NULL OR LeaseIncome.ContractId IS NOT NULL
UPDATE #AccruedIncomeBalanceSummary
SET DeferredRentalRevenueBalance = ISNULL(Receivables.AmountPosted,0) - ISNULL(LeaseIncome.RentalIncome,0) - ISNULL(GLPostedReceivables.AmountPosted,0)
FROM #AccruedIncomeBalanceSummary
LEFT JOIN (SELECT R.ContractId,SUM(R.LeaseComponentAmountPosted) AmountPosted
FROM #LeaseRentalReceivables R
WHERE R.ReceivableType = 'OperatingLeaseRental' AND R.IsGLPosted=1
AND R.DueDate < @EffectiveDate 
GROUP BY R.ContractId)
AS GLPostedReceivables ON #AccruedIncomeBalanceSummary.ContractId = GLPostedReceivables.ContractId
LEFT JOIN (SELECT LIS.ContractId,SUM(LIS.RentalIncome) RentalIncome
FROM #LeaseIncomeScheduleInfoForGLTransfer LIS
JOIN #LeaseContracts C ON LIS.ContractId = C.ContractId
WHERE LIS.IncomeType = 'FixedTerm'
AND IncomeDate > C.IncomeGLPostedTillDate
GROUP BY LIS.ContractId)
AS LeaseIncome ON #AccruedIncomeBalanceSummary.ContractId = LeaseIncome.ContractId
LEFT JOIN (SELECT R.ContractId,SUM(R.LeaseComponentAmountPosted) AmountPosted
FROM #LeaseRentalReceivables R
WHERE R.ReceivableType = 'OperatingLeaseRental' 
GROUP BY R.ContractId)
AS Receivables ON #AccruedIncomeBalanceSummary.ContractId = Receivables.ContractId
WHERE GLPostedReceivables.ContractId IS NOT NULL OR LeaseIncome.ContractId IS NOT NULL

UPDATE #AccruedIncomeBalanceSummary
SET OTPDeferredIncomeBalance = ISNULL(LeaseIncome.RentalIncome,0) + ISNULL(CashBasedReceivable.TotalDeferredIncome,0) - ISNULL(GLPostedReceivables.AmountPosted,0)
FROM #AccruedIncomeBalanceSummary
LEFT JOIN (SELECT R.ContractId,SUM(R.AmountPosted) AmountPosted
FROM #LeaseRentalReceivables R
WHERE R.ReceivableType = 'OverTermRental' AND R.IsGLPosted=1
AND R.DueDate < @EffectiveDate
GROUP BY R.ContractId)
AS GLPostedReceivables ON #AccruedIncomeBalanceSummary.ContractId = GLPostedReceivables.ContractId
LEFT JOIN (SELECT LIS.ContractId,SUM(LIS.RentalIncome) RentalIncome
FROM #LeaseIncomeScheduleInfoForGLTransfer LIS
JOIN #LeaseContracts C ON LIS.ContractId = C.ContractId
WHERE LIS.IncomeType = 'OverTerm' AND LIS.AccountingTreatment <> 'CashBased' AND LIS.IsNonAccrual=0
AND IncomeDate <= C.IncomeGLPostedTillDate
GROUP BY LIS.ContractId)
AS LeaseIncome ON #AccruedIncomeBalanceSummary.ContractId = LeaseIncome.ContractId
LEFT JOIN (SELECT C.ContractId,SUM(C.TotalDeferredIncome) TotalDeferredIncome
FROM #CashPostedCashBasedReceivableInfo C
WHERE C.ReceivableIncomeType = 'OTP' AND C.IsNonAccrual=0
GROUP BY C.ContractId)
AS CashBasedReceivable ON #AccruedIncomeBalanceSummary.ContractId = CashBasedReceivable.ContractId
WHERE GLPostedReceivables.ContractId IS NOT NULL OR LeaseIncome.ContractId IS NOT NULL OR CashBasedReceivable.ContractId IS NOT NULL
UPDATE #AccruedIncomeBalanceSummary
SET SupplementalDeferredIncomeBalance = ISNULL(LeaseIncome.RentalIncome,0) + ISNULL(CashBasedReceivable.TotalDeferredIncome,0) - ISNULL(GLPostedReceivables.AmountPosted,0)
FROM #AccruedIncomeBalanceSummary
LEFT JOIN (SELECT R.ContractId,SUM(R.AmountPosted) AmountPosted
FROM #LeaseRentalReceivables R
WHERE R.ReceivableType = 'Supplemental' AND R.IsGLPosted=1
AND R.DueDate < @EffectiveDate
GROUP BY R.ContractId)
AS GLPostedReceivables ON #AccruedIncomeBalanceSummary.ContractId = GLPostedReceivables.ContractId
LEFT JOIN (SELECT LIS.ContractId,SUM(LIS.RentalIncome) RentalIncome
FROM #LeaseIncomeScheduleInfoForGLTransfer LIS
JOIN #LeaseContracts C ON LIS.ContractId = C.ContractId
WHERE LIS.IncomeType = 'Supplemental' AND LIS.AccountingTreatment <> 'CashBased' AND LIS.IsNonAccrual=0
AND IncomeDate <= C.IncomeGLPostedTillDate
GROUP BY LIS.ContractId)
AS LeaseIncome ON #AccruedIncomeBalanceSummary.ContractId = LeaseIncome.ContractId
LEFT JOIN (SELECT C.ContractId,SUM(C.TotalDeferredIncome) TotalDeferredIncome
FROM #CashPostedCashBasedReceivableInfo C
WHERE C.ReceivableIncomeType = 'Supplemental' AND C.IsNonAccrual=0
GROUP BY C.ContractId)
AS CashBasedReceivable ON #AccruedIncomeBalanceSummary.ContractId = CashBasedReceivable.ContractId
WHERE GLPostedReceivables.ContractId IS NOT NULL OR LeaseIncome.ContractId IS NOT NULL OR CashBasedReceivable.ContractId IS NOT NULL
UPDATE #AccruedIncomeBalanceSummary
SET AccruedFloatRateInterestIncomeBalance = ISNULL(GLPostedFloatRateIncome.FloatRateIncome,0) - ISNULL(GLPostedReceivables.AmountPosted,0)
FROM #AccruedIncomeBalanceSummary
LEFT JOIN (SELECT R.ContractId,SUM(R.AmountPosted) AmountPosted
FROM #LeaseRentalReceivables R
WHERE R.ReceivableType = 'LeaseFloatRateAdj' AND R.IsGLPosted=1
AND R.DueDate < @EffectiveDate
GROUP BY R.ContractId)
AS GLPostedReceivables ON #AccruedIncomeBalanceSummary.ContractId = GLPostedReceivables.ContractId
LEFT JOIN (SELECT FloatRateIncome.ContractId,SUM(FloatRateIncome.FloatRateIncome) FloatRateIncome
FROM #FloatRateIncomeInfoForGLTransfer FloatRateIncome
GROUP BY FloatRateIncome.ContractId)
AS GLPostedFloatRateIncome ON #AccruedIncomeBalanceSummary.ContractId = GLPostedFloatRateIncome.ContractId
WHERE GLPostedReceivables.ContractId IS NOT NULL OR GLPostedFloatRateIncome.ContractId IS NOT NULL
UPDATE #AccruedIncomeBalanceSummary
SET FloatRateSuspendedIncomeBalance = GLPostedFloatRateIncome.FloatRateIncome
FROM #AccruedIncomeBalanceSummary
JOIN (SELECT FloatRateIncome.ContractId,SUM(FloatRateIncome.FloatRateIncome) FloatRateIncome
FROM #FloatRateIncomeInfoForGLTransfer FloatRateIncome
WHERE FloatRateIncome.IsNonAccrual=1 AND FloatRateIncome.IsContractInNonAccrual=1 AND FloatRateIncome.IncomeDate >= FloatRateIncome.NonAccrualDate
GROUP BY FloatRateIncome.ContractId)
AS GLPostedFloatRateIncome ON #AccruedIncomeBalanceSummary.ContractId = GLPostedFloatRateIncome.ContractId
UPDATE #AccruedIncomeBalanceSummary
SET SuspendedIncomeBalance = LeaseIncome.Income - LeaseIncome.ResidualIncome,
SuspendedUnguaranteedResidualIncomeBalance = LeaseIncome.ResidualIncome,
SuspendedRentalRevenueBalance = LeaseIncome.RentalIncome,
FinancingSuspendedIncomeBalance = LeaseIncome.FinancingIncome - LeaseIncome.FinancingResidualIncome,
FinancingSuspendedUnguaranteedResidualIncomeBalance = LeaseIncome.FinancingResidualIncome,
SuspendedSellingProfitIncome = LeaseIncome.DeferredSellingProfitIncome
FROM #AccruedIncomeBalanceSummary
JOIN (SELECT LIS.ContractId,
SUM(LIS.Income) Income,
SUM(LIS.ResidualIncome) ResidualIncome,
SUM(LIS.RentalIncome) RentalIncome,
SUM(LIS.FinancingIncome) FinancingIncome,
SUM(LIS.FinancingResidualIncome) FinancingResidualIncome,
SUM(LIS.DeferredSellingProfitIncome) DeferredSellingProfitIncome
FROM #LeaseIncomeScheduleInfoForGLTransfer LIS
JOIN #LeaseContracts C ON LIS.ContractId = C.ContractId 
WHERE LIS.IncomeType = 'FixedTerm' AND LIS.IsNonAccrual=1
AND IncomeDate <= C.IncomeGLPostedTillDate AND C.IsNonAccrual=1 AND IncomeDate >= C.NonAccrualDate
GROUP BY LIS.ContractId)
AS LeaseIncome ON #AccruedIncomeBalanceSummary.ContractId = LeaseIncome.ContractId
UPDATE #AccruedIncomeBalanceSummary
SET SuspendedOTPIncomeBalance = ISNULL(LeaseIncome.RentalIncome,0) + ISNULL(CashBasedReceivable.TotalDeferredIncome,0)
FROM #AccruedIncomeBalanceSummary
LEFT JOIN (SELECT LIS.ContractId,SUM(LIS.RentalIncome) RentalIncome
FROM #LeaseIncomeScheduleInfoForGLTransfer LIS
JOIN #LeaseContracts C ON LIS.ContractId = C.ContractId
WHERE LIS.IncomeType = 'OverTerm' AND LIS.AccountingTreatment <> 'CashBased' AND LIS.IsNonAccrual=1
AND IncomeDate <= C.IncomeGLPostedTillDate
GROUP BY LIS.ContractId) AS LeaseIncome ON #AccruedIncomeBalanceSummary.ContractId = LeaseIncome.ContractId
LEFT JOIN (SELECT C.ContractId,SUM(C.TotalDeferredIncome) TotalDeferredIncome
FROM #CashPostedCashBasedReceivableInfo C
WHERE C.ReceivableIncomeType = 'OTP' AND C.IsNonAccrual=1
GROUP BY C.ContractId) AS CashBasedReceivable ON #AccruedIncomeBalanceSummary.ContractId = CashBasedReceivable.ContractId
WHERE LeaseIncome.ContractId IS NOT NULL OR CashBasedReceivable.ContractId IS NOT NULL
UPDATE #AccruedIncomeBalanceSummary
SET SuspendedSupplementalIncomeBalance = ISNULL(LeaseIncome.RentalIncome,0) + ISNULL(CashBasedReceivable.TotalDeferredIncome,0)
FROM #AccruedIncomeBalanceSummary
LEFT JOIN (SELECT LIS.ContractId,SUM(LIS.RentalIncome) RentalIncome
FROM #LeaseIncomeScheduleInfoForGLTransfer LIS
JOIN #LeaseContracts C ON LIS.ContractId = C.ContractId
WHERE LIS.IncomeType = 'Supplemental' AND LIS.AccountingTreatment <> 'CashBased' AND LIS.IsNonAccrual=1
AND IncomeDate <= C.IncomeGLPostedTillDate
GROUP BY LIS.ContractId) AS LeaseIncome ON #AccruedIncomeBalanceSummary.ContractId = LeaseIncome.ContractId
LEFT JOIN (SELECT C.ContractId,SUM(C.TotalDeferredIncome) TotalDeferredIncome
FROM #CashPostedCashBasedReceivableInfo C
WHERE C.ReceivableIncomeType = 'Supplemental' AND C.IsNonAccrual=1
GROUP BY C.ContractId) AS CashBasedReceivable ON #AccruedIncomeBalanceSummary.ContractId = CashBasedReceivable.ContractId
WHERE LeaseIncome.ContractId IS NOT NULL OR CashBasedReceivable.ContractId IS NOT NULL
IF(@AccumulateDepreciationForDFL = 0)
BEGIN
UPDATE #AccruedIncomeBalanceSummary
SET ClearedOTPLeaseAssetAmount = AccumulatedDep.TotalAmount
FROM #AccruedIncomeBalanceSummary
JOIN #LeaseContracts C ON #AccruedIncomeBalanceSummary.ContractId = C.ContractId
JOIN #AccumulatedDepreciationInfo AS AccumulatedDep ON C.ContractId = AccumulatedDep.ContractId
WHERE AccumulatedDep.SourceModule = 'ResidualRecapture'
END
UPDATE #AccruedIncomeBalanceSummary
SET AccumulatedFixedTermDepreciation = AccumulatedDep.TotalAmount
FROM #AccruedIncomeBalanceSummary
JOIN #AccumulatedDepreciationInfo AccumulatedDep ON #AccruedIncomeBalanceSummary.ContractId = AccumulatedDep.ContractId
WHERE AccumulatedDep.SourceModule = 'FixedTermDepreciation'
UPDATE #AccruedIncomeBalanceSummary
SET AccumulatedOTPDepreciation = AccumulatedDep.TotalAmount
FROM #AccruedIncomeBalanceSummary
JOIN #AccumulatedDepreciationInfo AS AccumulatedDep ON #AccruedIncomeBalanceSummary.ContractId = AccumulatedDep.ContractId
WHERE AccumulatedDep.SourceModule = 'OTPDepreciation'
IF EXISTS(SELECT ContractId FROM #LeaseContracts WHERE IsOverTermLease = 1)
BEGIN
UPDATE #AccruedIncomeBalanceSummary
SET IsFirstOTPIncomeGLPosted = FirstIncomeRecord.IsReclassOTP
FROM #AccruedIncomeBalanceSummary
JOIN (SELECT C.ContractId,
LIS.IsReclassOTP,
ROW_NUMBER() OVER (PARTITION BY C.ContractId ORDER BY IncomeDate) AS RowNumber
FROM
#LeaseContracts C
JOIN #LeaseIncomeScheduleInfoForGLTransfer LIS ON C.ContractId = C.ContractId AND LIS.IncomeType = 'OverTerm'
WHERE C.IsOverTermLease=1)
AS FirstIncomeRecord ON #AccruedIncomeBalanceSummary.ContractId = FirstIncomeRecord.ContractId AND FirstIncomeRecord.RowNumber = 1
END
IF(@MovePLBalance = 1)
BEGIN
UPDATE #AccruedIncomeBalanceSummary
SET InterimRentIncome = LeaseIncome.RentalIncome
FROM #AccruedIncomeBalanceSummary
JOIN(SELECT LIS.ContractId,
SUM(RentalIncome) RentalIncome
FROM #LeaseIncomeScheduleInfoForGLTransfer LIS
JOIN #LeaseContracts C ON LIS.ContractId = C.ContractId
WHERE IncomeType = 'InterimRent' AND LIS.IsNonAccrual=0
AND LIS.IncomeDate >= @PLEffectiveDate AND LIS.IncomeDate < @EffectiveDate
AND IncomeDate <= C.IncomeGLPostedTillDate
GROUP BY LIS.ContractId)
AS LeaseIncome ON #AccruedIncomeBalanceSummary.ContractId = LeaseIncome.ContractId
UPDATE #AccruedIncomeBalanceSummary
SET Income = CASE WHEN C.LeaseContractType <> 'Operating' THEN LeaseIncome.Income - LeaseIncome.ResidualIncome  ELSE 0 END,
UnguaranteedResidualIncome = CASE WHEN C.LeaseContractType <> 'Operating' THEN LeaseIncome.ResidualIncome  ELSE 0 END,
RentalRevenue = CASE WHEN C.LeaseContractType = 'Operating' THEN LeaseIncome.RentalIncome  ELSE 0 END,
FinancingIncome = LeaseIncome.FinancingIncome - LeaseIncome.FinancingResidualIncome,
FinancingUnguaranteedResidualIncome = LeaseIncome.FinancingResidualIncome,
SellingProfitIncome = LeaseIncome.DeferredSellingProfitIncome
FROM #AccruedIncomeBalanceSummary
JOIN #LeaseContracts C ON #AccruedIncomeBalanceSummary.ContractId = C.ContractId
JOIN(SELECT LIS.ContractId,
SUM(Income) Income,
SUM(ResidualIncome) ResidualIncome,
SUM(RentalIncome) RentalIncome,
SUM(FinancingIncome) FinancingIncome,
SUM(FinancingResidualIncome) FinancingResidualIncome,
SUM(DeferredSellingProfitIncome) DeferredSellingProfitIncome
FROM #LeaseIncomeScheduleInfoForGLTransfer LIS
JOIN #LeaseContracts C ON LIS.ContractId = C.ContractId
WHERE IncomeType = 'FixedTerm' AND LIS.IsNonAccrual=0
AND LIS.IncomeDate >= @PLEffectiveDate AND LIS.IncomeDate < @EffectiveDate
AND IncomeDate <= C.IncomeGLPostedTillDate
GROUP BY LIS.ContractId)
AS LeaseIncome ON C.ContractId = LeaseIncome.ContractId
UPDATE #AccruedIncomeBalanceSummary
SET FixedTermDepreciation = CASE WHEN C.LeaseContractType = 'Operating' THEN LeaseIncome.Depreciation  ELSE 0 END
FROM #AccruedIncomeBalanceSummary
JOIN #LeaseContracts C ON #AccruedIncomeBalanceSummary.ContractId = C.ContractId  AND C.LeaseContractType = 'Operating'
JOIN(SELECT LIS.ContractId,
SUM(Depreciation) * (-1) Depreciation
FROM #LeaseIncomeScheduleInfoForGLTransfer LIS
JOIN #LeaseContracts C ON LIS.ContractId = C.ContractId AND C.LeaseContractType = 'Operating'
WHERE IncomeType = 'FixedTerm'
AND LIS.IncomeDate >= @PLEffectiveDate AND LIS.IncomeDate < @EffectiveDate
AND IncomeDate <= C.IncomeGLPostedTillDate
GROUP BY LIS.ContractId)
AS LeaseIncome ON C.ContractId = LeaseIncome.ContractId
UPDATE #AccruedIncomeBalanceSummary
SET OTPDepreciation = OperatingLeaseIncome.Depreciation
FROM #AccruedIncomeBalanceSummary
JOIN #LeaseContracts C ON #AccruedIncomeBalanceSummary.ContractId = C.ContractId AND C.LeaseContractType = 'Operating'
JOIN(SELECT
C.ContractId,
SUM(AssetValueHistories.Value_Amount) * (-1) Depreciation
FROM #LeaseContracts C
JOIN LeaseFinances ON C.ContractId = LeaseFinances.ContractId AND LeaseFinances.IsCurrent=1
JOIN LeaseAssets ON LeaseFinances.Id = LeaseAssets.LeaseFinanceId  AND LeaseAssets.IsActive=1
JOIN AssetValueHistories ON LeaseAssets.AssetId = AssetValueHistories.AssetId AND AssetValueHistories.IsSchedule=1 AND AssetValueHistories.IsLessorOwned = 1
WHERE SourceModule ='OTPDepreciation'
AND AssetValueHistories.IsLeaseComponent = 1
AND IncomeDate >= @PLEffectiveDate AND IncomeDate < @EffectiveDate
AND IncomeDate <= C.IncomeGLPostedTillDate
GROUP BY C.ContractId)
AS OperatingLeaseIncome ON C.ContractId = OperatingLeaseIncome.ContractId
UPDATE #AccruedIncomeBalanceSummary
SET OTPDepreciation = CASE WHEN @AccumulateDepreciationForDFL = 1
THEN OTPDepreciation + (ISNULL(CapitalLeaseIncome.Depreciation,0) + ISNULL(CashPostedCashBasedReceivable.TotalDepreciationAmount,0)) * (-1)
ELSE OTPDepreciation END,
ResidualRecapture = CASE WHEN @AccumulateDepreciationForDFL = 0
THEN (ISNULL(CapitalLeaseIncome.Depreciation,0) + ISNULL(CashPostedCashBasedReceivable.TotalDepreciationAmount,0)) * (-1)
ELSE 0 END
FROM #AccruedIncomeBalanceSummary
JOIN #LeaseContracts C ON #AccruedIncomeBalanceSummary.ContractId = C.ContractId
LEFT JOIN(SELECT
C.ContractId,
SUM(AVH.Value_Amount) Depreciation
FROM #LeaseContracts C
JOIN LeaseFinances ON C.ContractId = LeaseFinances.ContractId AND LeaseFinances.IsCurrent=1
JOIN LeaseAssets ON LeaseFinances.Id = LeaseAssets.LeaseFinanceId AND LeaseAssets.IsActive=1
JOIN AssetValueHistories AVH ON LeaseAssets.AssetId = AVH.AssetId AND AVH.SourceModule IN('OTPDepreciation','ResidualRecapture')
AND AVH.IsSchedule=1 AND AVH.IsLessorOwned = 1
JOIN AssetIncomeSchedules ON AVH.AssetId = AssetIncomeSchedules.AssetId AND AssetIncomeSchedules.IsActive=1
JOIN LeaseIncomeSchedules ON AssetIncomeSchedules.LeaseIncomeScheduleId = LeaseIncomeSchedules.Id AND AVH.IncomeDate = LeaseIncomeSchedules.IncomeDate
WHERE AccountingTreatment = 'AccrualBased'
AND (AVH.IsLeaseComponent = 0 OR C.LeaseContractType <> 'Operating')
AND AVH.IncomeDate >= @PLEffectiveDate AND AVH.IncomeDate < @EffectiveDate
AND AVH.IncomeDate <= C.IncomeGLPostedTillDate
GROUP BY C.ContractId)
AS CapitalLeaseIncome ON C.ContractId = CapitalLeaseIncome.ContractId
LEFT JOIN(SELECT ContractId,SUM(TotalDepreciationAmount) TotalDepreciationAmount
FROM #CashPostedCashBasedReceivableInfo
WHERE ReceivableIncomeType IN('OTP','Supplemental')
AND IncomeDate >= @PLEffectiveDate AND IncomeDate < @EffectiveDate
GROUP BY ContractId) AS CashPostedCashBasedReceivable ON C.ContractId = CashPostedCashBasedReceivable.ContractId
WHERE CapitalLeaseIncome.ContractId IS NOT NULL OR CashPostedCashBasedReceivable.ContractId IS NOT NULL
AND (C.LeaseContractType <> 'Operating' OR IsFASBChangesApplicable=1)
UPDATE #AccruedIncomeBalanceSummary
SET OTPIncome =ISNULL(LeaseIncome.RentalIncome,0) + ISNULL(CashPostedCashBasedReceivable.TotalDeferredIncome,0)
FROM #AccruedIncomeBalanceSummary
JOIN #LeaseContracts C ON #AccruedIncomeBalanceSummary.ContractId = C.ContractId
LEFT JOIN(SELECT LIS.ContractId,SUM(RentalIncome) RentalIncome
FROM #LeaseIncomeScheduleInfoForGLTransfer LIS
JOIN #LeaseContracts C ON LIS.ContractId = C.ContractId
WHERE IncomeType = 'OverTerm' AND AccountingTreatment = 'AccrualBased' AND LIS.IsNonAccrual=0
AND IncomeDate >= @PLEffectiveDate AND IncomeDate < @EffectiveDate
AND IncomeDate <= C.IncomeGLPostedTillDate
GROUP BY LIS.ContractId) AS LeaseIncome ON C.ContractId = LeaseIncome.ContractId
LEFT JOIN(SELECT ContractId,SUM(TotalDeferredIncome) TotalDeferredIncome
FROM #CashPostedCashBasedReceivableInfo
WHERE ReceivableIncomeType = 'OTP' AND IsNonAccrual=0
AND IncomeDate >= @PLEffectiveDate AND IncomeDate < @EffectiveDate
GROUP BY ContractId) AS CashPostedCashBasedReceivable ON C.ContractId = CashPostedCashBasedReceivable.ContractId
WHERE LeaseIncome.ContractId IS NOT NULL OR CashPostedCashBasedReceivable.ContractId IS NOT NULL
UPDATE #AccruedIncomeBalanceSummary
SET SupplementalIncome =ISNULL(LeaseIncome.RentalIncome,0) + ISNULL(CashPostedCashBasedReceivable.TotalDeferredIncome,0)
FROM #AccruedIncomeBalanceSummary
JOIN #LeaseContracts C ON #AccruedIncomeBalanceSummary.ContractId = C.ContractId
LEFT JOIN(SELECT LIS.ContractId,SUM(RentalIncome) RentalIncome
FROM #LeaseIncomeScheduleInfoForGLTransfer LIS
JOIN #LeaseContracts C ON LIS.ContractId = C.ContractId
WHERE IncomeType = 'Supplemental' AND AccountingTreatment = 'AccrualBased' AND LIS.IsNonAccrual=0
AND IncomeDate >= @PLEffectiveDate AND IncomeDate < @EffectiveDate
AND IncomeDate <= C.IncomeGLPostedTillDate
GROUP BY LIS.ContractId) AS LeaseIncome ON C.ContractId = LeaseIncome.ContractId
LEFT JOIN(SELECT ContractId,SUM(TotalDeferredIncome) TotalDeferredIncome
FROM #CashPostedCashBasedReceivableInfo
WHERE ReceivableIncomeType = 'Supplemental' AND IsNonAccrual=0
AND IncomeDate >= @PLEffectiveDate AND IncomeDate < @EffectiveDate
GROUP BY ContractId) AS CashPostedCashBasedReceivable ON C.ContractId = CashPostedCashBasedReceivable.ContractId
WHERE LeaseIncome.ContractId IS NOT NULL OR CashPostedCashBasedReceivable.ContractId IS NOT NULL
UPDATE #AccruedIncomeBalanceSummary
SET FloatInterestIncome = LeaseIncome.FloatRateIncome
FROM #AccruedIncomeBalanceSummary
JOIN #LeaseContracts C ON #AccruedIncomeBalanceSummary.ContractId = C.ContractId
JOIN(SELECT ContractId,SUM(FloatRateIncome) FloatRateIncome
FROM #FloatRateIncomeInfoForGLTransfer
WHERE IsNonAccrual=0 AND IncomeDate >= @PLEffectiveDate AND IncomeDate < @EffectiveDate
GROUP BY ContractId)
AS LeaseIncome ON C.ContractId = LeaseIncome.ContractId
END
IF EXISTS(SELECT ContractId FROM #LeaseContracts C WHERE LeaseContractType = 'Operating')
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'OperatingLeaseBooking',
LeaseFinanceDetails.LeaseBookingGLTemplateId,
'OperatingLeaseAsset',
ISNULL(LeaseInvestmentInfo.Investment + LeaseInvestmentInfo.CapitalizedAmount - LeaseInvestmentInfo.ETCAdjustmentAmount,0) - ISNULL(R.SoldNBV_Amount,0),
1
FROM
#LeaseContracts C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId =LeaseFinanceDetails.Id
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId AND C.LeaseContractType = 'Operating' AND #AccruedIncomeBalanceSummary.IsFirstOTPIncomeGLPosted=0
LEFT JOIN (SELECT * FROM #LeaseInvestmentInfo WHERE IsLeaseComponent = 1) AS LeaseInvestmentInfo ON C.ContractId = LeaseInvestmentInfo.ContractId
LEFT JOIN #ReceivableForTransfers R ON #AccruedIncomeBalanceSummary.ContractId = R.ContractId
WHERE ISNULL(LeaseInvestmentInfo.Investment + LeaseInvestmentInfo.CapitalizedAmount - LeaseInvestmentInfo.ETCAdjustmentAmount,0) - ISNULL(R.SoldNBV_Amount,0) <> 0
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit,MatchingGLTemplateId)
SELECT
C.ContractId,
'OperatingLeaseIncome',
LeaseFinanceDetails.LeaseIncomeGLTemplateId,
'DeferredRentalRevenue',
#AccruedIncomeBalanceSummary.DeferredRentalRevenueBalance,
1,
ReceivableCodes.GLTemplateId
FROM
#LeaseContracts C
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId AND C.LeaseContractType = 'Operating'
AND #AccruedIncomeBalanceSummary.DeferredRentalRevenueBalance <> 0
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN ReceivableCodes ON LeaseFinanceDetails.FixedTermReceivableCodeId = ReceivableCodes.Id
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'OperatingLeaseIncome',
LeaseFinanceDetails.LeaseIncomeGLTemplateId,
'AccumulatedFixedTermDepreciation',
#AccruedIncomeBalanceSummary.AccumulatedFixedTermDepreciation,
0
FROM
#LeaseContracts C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId =LeaseFinanceDetails.Id
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId AND C.LeaseContractType = 'Operating' AND #AccruedIncomeBalanceSummary.IsFirstOTPIncomeGLPosted = 0
WHERE #AccruedIncomeBalanceSummary.AccumulatedFixedTermDepreciation <> 0
END
IF EXISTS(SELECT ContractId FROM #LeaseContracts C WHERE LeaseContractType <> 'Operating' OR C.IsFASBChangesApplicable = 1)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'CapitalLeaseBooking' GLTransactionType,
LeaseFinanceDetails.LeaseBookingGLTemplateId,
'LongTermLeaseReceivable' GLEntryItem,
CASE WHEN IsFirstOTPIncomeGLPosted = 1 OR @IncludeGuaranteedResidualinLongTermReceivables = 0
THEN ISNULL(FixedTermReceivable.ReceivableAmount,0)
ELSE ISNULL(FixedTermReceivable.ReceivableAmount,0) + ROUND(LeaseInvestmentInfo.CustomerGuaranteedResidual + LeaseInvestmentInfo.ThirdPartyGuaranteedResidual * C.RetainedPercentage,2)
END,
1
FROM
#LeaseContracts C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId
LEFT JOIN (SELECT C.ContractId,
SUM(R.LeaseComponentAmountPosted) ReceivableAmount
FROM #LeaseContracts C
JOIN #LeaseRentalReceivables R ON C.ContractId = R.ContractId AND R.IsGLPosted = 0
WHERE (C.LeaseContractType <> 'Operating' AND R.ReceivableType = 'CapitalLeaseRental' 
)
GROUP BY C.ContractId)
AS FixedTermReceivable ON C.ContractId = FixedTermReceivable.ContractId
LEFT JOIN (SELECT * FROM #LeaseInvestmentInfo WHERE IsLeaseComponent=1) LeaseInvestmentInfo ON C.ContractId = LeaseInvestmentInfo.ContractId
WHERE C.LeaseContractType <> 'Operating'
AND (ISNULL(FixedTermReceivable.ReceivableAmount,0.00) <> 0 OR (@IncludeGuaranteedResidualinLongTermReceivables = 1 AND IsFirstOTPIncomeGLPosted=0
AND ROUND((ISNULL(LeaseInvestmentInfo.CustomerGuaranteedResidual,0.00) + ISNULL(LeaseInvestmentInfo.ThirdPartyGuaranteedResidual,0.00)) * C.RetainedPercentage,2) <> 0))
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
CASE WHEN C.LeaseContractType = 'Operating' THEN 'OperatingLeaseBooking' ELSE 'CapitalLeaseBooking' END AS GLTransactionType,
LeaseFinanceDetails.LeaseBookingGLTemplateId,
'FinancingLongTermLeaseReceivable' GLEntryItem,
CASE WHEN IsFirstOTPIncomeGLPosted = 1 OR @IncludeGuaranteedResidualinLongTermReceivables = 0
THEN ISNULL(FixedTermReceivable.ReceivableAmount,0)
ELSE ISNULL(FixedTermReceivable.ReceivableAmount,0) + ROUND(LeaseInvestmentInfo.CustomerGuaranteedResidual + LeaseInvestmentInfo.ThirdPartyGuaranteedResidual * C.RetainedPercentage,2)
END,
1
FROM
#LeaseContracts C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId
LEFT JOIN (SELECT C.ContractId,
SUM(R.NonLeaseComponentAmountPosted) ReceivableAmount
FROM #LeaseContracts C
JOIN #LeaseRentalReceivables R ON C.ContractId = R.ContractId AND R.IsGLPosted = 0 AND R.ReceivableType <> 'LeaseFloatRateAdj'
WHERE (C.IsFASBChangesApplicable=1 )
GROUP BY C.ContractId)
AS FixedTermReceivable ON C.ContractId = FixedTermReceivable.ContractId
LEFT JOIN (SELECT * FROM #LeaseInvestmentInfo WHERE IsLeaseComponent=0) LeaseInvestmentInfo ON C.ContractId = LeaseInvestmentInfo.ContractId
WHERE C.IsFASBChangesApplicable = 1
AND (ISNULL(FixedTermReceivable.ReceivableAmount,0.00) <> 0 OR (@IncludeGuaranteedResidualinLongTermReceivables = 1 AND IsFirstOTPIncomeGLPosted=0
AND ROUND((ISNULL(LeaseInvestmentInfo.CustomerGuaranteedResidual,0.00) + ISNULL(LeaseInvestmentInfo.ThirdPartyGuaranteedResidual,0.00)) * C.RetainedPercentage,2) <> 0))  
IF(@IncludeGuaranteedResidualinLongTermReceivables = 0)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
CASE WHEN C.LeaseContractType = 'Operating' THEN 'OperatingLeaseBooking' ELSE 'CapitalLeaseBooking' END GLTransactionType,
LeaseFinanceDetails.LeaseBookingGLTemplateId,
CASE WHEN #LeaseInvestmentInfo.IsLeaseComponent = 1 THEN 'GuaranteedResidual' ELSE 'FinancingGuaranteedResidual' END GLEntryItem,
ROUND((#LeaseInvestmentInfo.CustomerGuaranteedResidual + #LeaseInvestmentInfo.ThirdPartyGuaranteedResidual) * C.RetainedPercentage,2),
1
FROM
#LeaseContracts C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId AND #AccruedIncomeBalanceSummary.IsFirstOTPIncomeGLPosted=0
JOIN #LeaseInvestmentInfo ON C.ContractId = #LeaseInvestmentInfo.ContractId
WHERE (C.LeaseContractType <> 'Operating' OR #LeaseInvestmentInfo.IsLeaseComponent = 0)
AND ROUND((#LeaseInvestmentInfo.CustomerGuaranteedResidual + #LeaseInvestmentInfo.ThirdPartyGuaranteedResidual) * C.RetainedPercentage,2) <> 0
END
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
CASE WHEN C.LeaseContractType = 'Operating' THEN 'OperatingLeaseBooking' ELSE 'CapitalLeaseBooking' END GLTransactionType,
LeaseFinanceDetails.LeaseBookingGLTemplateId,
CASE WHEN #LeaseInvestmentInfo.IsLeaseComponent = 1 THEN 'UnguaranteedResidualBooked' ELSE 'FinancingUnguaranteedResidualBooked' END GLEntryItem,
ROUND((#LeaseInvestmentInfo.BookedResidual - #LeaseInvestmentInfo.CustomerGuaranteedResidual - #LeaseInvestmentInfo.ThirdPartyGuaranteedResidual) * C.RetainedPercentage,2),
1
FROM
#LeaseContracts C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId AND #AccruedIncomeBalanceSummary.IsFirstOTPIncomeGLPosted=0
JOIN #LeaseInvestmentInfo ON C.ContractId = #LeaseInvestmentInfo.ContractId
WHERE (C.LeaseContractType <> 'Operating' OR #LeaseInvestmentInfo.IsLeaseComponent = 0)
AND ROUND((#LeaseInvestmentInfo.BookedResidual - #LeaseInvestmentInfo.CustomerGuaranteedResidual - #LeaseInvestmentInfo.ThirdPartyGuaranteedResidual) * C.RetainedPercentage,2) <> 0
IF EXISTS(SELECT ContractId FROM #LeaseContracts WHERE LeaseContractType <> 'Operating')
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'CapitalLeaseBooking',
LeaseFinanceDetails.LeaseBookingGLTemplateId,
'UnearnedIncome',
SUM(L.Income - L.ResidualIncome) Amount,
0
FROM
#LeaseContracts C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN (SELECT C.ContractId,SUM(Income) Income,SUM(ResidualIncome) ResidualIncome
FROM #LeaseIncomeScheduleInfoForGLTransfer LIS
JOIN #LeaseContracts C ON LIS.ContractId = C.ContractId AND C.LeaseContractType <> 'Operating'
WHERE IncomeDate > C.IncomeGLPostedTillDate GROUP BY C.ContractId) L ON C.ContractId = L.ContractId
WHERE C.LeaseContractType <> 'Operating'
AND (L.Income - L.ResidualIncome) <> 0
GROUP BY C.ContractId,LeaseFinanceDetails.LeaseBookingGLTemplateId
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'CapitalLeaseBooking',
LeaseFinanceDetails.LeaseBookingGLTemplateId,
'UnearnedUnguaranteedResidualIncome',
SUM(L.ResidualIncome) Amount,
0
FROM
#LeaseContracts C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN (SELECT C.ContractId,SUM(ResidualIncome) ResidualIncome
FROM #LeaseIncomeScheduleInfoForGLTransfer LIS
JOIN #LeaseContracts C ON LIS.ContractId = C.ContractId AND C.LeaseContractType <> 'Operating'
WHERE IncomeDate > C.IncomeGLPostedTillDate GROUP BY C.ContractId) L ON C.ContractId = L.ContractId
WHERE C.LeaseContractType <> 'Operating'
AND L.ResidualIncome <> 0
GROUP BY C.ContractId,LeaseFinanceDetails.LeaseBookingGLTemplateId
END
IF EXISTS(SELECT ContractId FROM #LeaseContracts WHERE IsFASBChangesApplicable = 1)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
CASE WHEN C.LeaseContractType = 'Operating' THEN 'OperatingLeaseBooking' ELSE 'CapitalLeaseBooking' END GLTransactionType,
LeaseFinanceDetails.LeaseBookingGLTemplateId,
'FinancingUnearnedIncome',
L.FinancingIncome - L.FinancingResidualIncome,
0
FROM
#LeaseContracts C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN (SELECT C.ContractId,SUM(FinancingIncome) FinancingIncome,SUM(FinancingResidualIncome) FinancingResidualIncome
FROM #LeaseIncomeScheduleInfoForGLTransfer LIS
JOIN #LeaseContracts C ON LIS.ContractId = C.ContractId AND C.IsFASBChangesApplicable=1
WHERE IncomeDate > C.IncomeGLPostedTillDate  GROUP BY C.ContractId) L ON C.ContractId = L.ContractId
WHERE C.IsFASBChangesApplicable = 1
AND (L.FinancingIncome - L.FinancingResidualIncome) <> 0
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
CASE WHEN C.LeaseContractType = 'Operating' THEN 'OperatingLeaseBooking' ELSE 'CapitalLeaseBooking' END GLTransactionType,
LeaseFinanceDetails.LeaseBookingGLTemplateId,
'FinancingUnearnedUnguaranteedResidualIncome',
L.FinancingResidualIncome,
0
FROM
#LeaseContracts C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN (SELECT C.ContractId,SUM(FinancingResidualIncome) FinancingResidualIncome
FROM #LeaseIncomeScheduleInfoForGLTransfer  LIS
JOIN #LeaseContracts C ON LIS.ContractId = C.ContractId AND C.IsFASBChangesApplicable=1
WHERE IncomeDate > C.IncomeGLPostedTillDate GROUP BY C.ContractId) L ON C.ContractId = L.ContractId
WHERE C.IsFASBChangesApplicable = 1
AND L.FinancingResidualIncome <> 0
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'CapitalLeaseBooking',
LeaseFinanceDetails.LeaseBookingGLTemplateId,
'DeferredSellingProfit',
L.DeferredSellingProfitIncome,
0
FROM
#LeaseContracts C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN (SELECT C.ContractId,SUM(DeferredSellingProfitIncome) DeferredSellingProfitIncome
FROM #LeaseIncomeScheduleInfoForGLTransfer LIS
JOIN #LeaseContracts C ON LIS.ContractId = C.ContractId AND C.IsFASBChangesApplicable=1 AND C.LeaseContractType = 'DirectFinance'
WHERE IncomeDate > C.IncomeGLPostedTillDate GROUP BY C.ContractId) L ON C.ContractId = L.ContractId
WHERE C.LeaseContractType = 'DirectFinance'
AND C.IsFASBChangesApplicable = 1
AND L.DeferredSellingProfitIncome <> 0
END
IF EXISTS(SELECT ContractId FROM #LeaseContracts WHERE IsFutureFunding=1)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'CapitalLeaseBooking',
LeaseFinanceDetails.LeaseBookingGLTemplateId,
'DelayedPayable',
ISNULL(FutureFundingInvestment.ActualNBV,0) - ISNULL(GLPostedFutureFundingPayables.Amount,0),
0
FROM #LeaseContracts C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
LEFT JOIN (SELECT
C.ContractId,
SUM(NBV_Amount - CapitalizedInterimInterest_Amount - CapitalizedInterimRent_Amount - CapitalizedSalesTax_Amount - CapitalizedProgressPayment_Amount) AS ActualNBV
FROM #LeaseContracts C
JOIN LeaseAssets ON C.LeaseContractType <> 'Operating' AND C.IsFutureFunding=1 AND C.LeaseFinanceId = LeaseAssets.LeaseFinanceId
JOIN PayableInvoices ON LeaseAssets.PayableInvoiceId = PayableInvoices.Id
JOIN LeaseFundings ON PayableInvoices.Id = LeaseFundings.FundingId AND LeaseAssets.LeaseFinanceId = LeaseFundings.LeaseFinanceId
AND LeaseFundings.Type <> 'Origination' AND LeaseFundings.IsActive=1
WHERE LeaseAssets.IsActive=1 AND LeaseAssets.CapitalizedForId IS NULL
GROUP BY C.ContractId) AS FutureFundingInvestment ON C.ContractId = FutureFundingInvestment.ContractId
LEFT JOIN (SELECT C.ContractId,SUM(Payables.Amount_Amount) Amount
FROM #LeaseContracts C
JOIN LeaseFundings ON C.LeaseFinanceId = LeaseFundings.LeaseFinanceId AND LeaseFundings.Type <> 'Origination' AND LeaseFundings.IsActive=1
JOIN PayableInvoices ON LeaseFundings.FundingId = PayableInvoices.Id
JOIN Payables ON PayableInvoices.Id = Payables.EntityId AND Payables.EntityType = 'PI' AND Payables.Status <> 'Inactive' AND Payables.IsGLPosted=1
LEFT JOIN PayableInvoiceOtherCosts ON Payables.SourceTable = 'PayableInvoiceOtherCost' AND  Payables.SourceId = PayableInvoiceOtherCosts.Id AND PayableInvoiceOtherCosts.PayableInvoiceId = PayableInvoices.Id
LEFT JOIN PayableInvoiceAssets ON Payables.SourceTable = 'PayableInvoiceAsset' AND  Payables.SourceId = PayableInvoiceAssets.Id AND PayableInvoiceAssets.PayableInvoiceId = PayableInvoices.Id
WHERE PayableInvoiceAssets.Id IS NOT NULL
OR (PayableInvoiceOtherCosts.Id IS NOT NULL AND PayableInvoiceOtherCosts.AllocationMethod NOT IN ('ProgressPaymentCredit','ChargeBack','Absorb','DoNotPay','VendorSubsidy'))
GROUP BY C.ContractId) AS GLPostedFutureFundingPayables ON C.ContractId = GLPostedFutureFundingPayables.ContractId
WHERE FutureFundingInvestment.ContractId IS NOT NULL OR GLPostedFutureFundingPayables.ContractId IS NOT NULL
END
IF(@MovePLBalance=1)
BEGIN
IF EXISTS(SELECT ContractId FROM #LeaseContracts WHERE (LeaseContractType = 'SalesType' OR IsFASBChangesApplicable = 1) AND PostDate >= @PLEffectiveDate AND PostDate < @EffectiveDate)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'CapitalLeaseBooking',
LeaseFinanceDetails.LeaseBookingGLTemplateId,
'CostOfSales',
(#LeaseInvestmentInfo.Investment + #LeaseInvestmentInfo.CapitalizedAmount),
1
FROM
#LeaseContracts C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId =LeaseFinanceDetails.Id
JOIN #LeaseInvestmentInfo ON C.ContractId = #LeaseInvestmentInfo.ContractId AND #LeaseInvestmentInfo.IsLeaseComponent = 1
AND C.PostDate >= @PLEffectiveDate AND C.PostDate < @EffectiveDate
WHERE (#LeaseInvestmentInfo.Investment + #LeaseInvestmentInfo.CapitalizedAmount) <> 0
AND (C.LeaseContractType = 'SalesType' OR (C.IsFASBChangesApplicable = 1 AND (C.LeaseContractType = 'IFRSFinanceLease' AND C.ProfitLossStatus IN ('Profit','Loss'))
OR (C.LeaseContractType = 'DirectFinance' AND C.ProfitLossStatus = 'Loss')))
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'CapitalLeaseBooking',
LeaseFinanceDetails.LeaseBookingGLTemplateId,
'SalesTypeRevenue',
CASE WHEN C.IsFASBChangesApplicable = 1 THEN #LeaseInvestmentInfo.FMV ELSE #LeaseInvestmentInfo.SalesTypeNBV END,
0
FROM
#LeaseContracts C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId =LeaseFinanceDetails.Id
JOIN #LeaseInvestmentInfo ON C.ContractId = #LeaseInvestmentInfo.ContractId AND #LeaseInvestmentInfo.IsLeaseComponent = 1
AND C.PostDate >= @PLEffectiveDate AND C.PostDate < @EffectiveDate
WHERE (#LeaseInvestmentInfo.Investment + #LeaseInvestmentInfo.CapitalizedAmount) <> 0
AND (C.LeaseContractType = 'SalesType' OR (C.IsFASBChangesApplicable = 1 AND (C.LeaseContractType = 'IFRSFinanceLease' AND C.ProfitLossStatus IN ('Profit','Loss'))
OR (C.LeaseContractType = 'DirectFinance' AND C.ProfitLossStatus = 'Loss')))
END
END
END
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit,MatchingGLTemplateId)
SELECT
C.ContractId,
CASE WHEN C.LeaseContractType = 'Operating' THEN 'OperatingLeaseBooking' ELSE 'CapitalLeaseBooking' END,
LeaseFinanceDetails.LeaseBookingGLTemplateId,
'Inventory',
SUM(Amount),
0,
GLTemplateId
FROM #LeaseContracts C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN
(SELECT C.ContractId,
PayableCodes.GLTemplateId,
CASE WHEN MIN(CAST(Payables.IsGLPosted AS INT)) = 0 THEN SUM(CASE WHEN Payables.IsGLPosted=0 THEN ROUND(Payables.Amount_Amount * PayableInvoices.InitialExchangeRate,2) ELSE 0 END) - ETCAdjustmentAmount_Amount ELSE ETCAdjustmentAmount_Amount END AS Amount
FROM #LeaseContracts C
JOIN LeaseAssets ON C.LeaseFinanceId = LeaseAssets.LeaseFinanceId AND LeaseAssets.IsActive=1
JOIN PayableInvoiceAssets ON LeaseAssets.AssetId = PayableInvoiceAssets.AssetId AND PayableInvoiceAssets.IsActive=1
JOIN PayableInvoices ON PayableInvoiceAssets.PayableInvoiceId = PayableInvoices.Id AND PayableInvoices.Status = 'Completed'
JOIN Payables ON Payables.SourceId = PayableInvoiceAssets.Id AND Payables.SourceTable = 'PayableInvoiceAsset' AND Payables.Status <> 'Inactive'
JOIN PayableCodes ON Payables.PayableCodeId = PayableCodes.Id
GROUP BY C.ContractId,PayableCodes.GLTemplateId,LeaseAssets.AssetId,LeaseAssets.ETCAdjustmentAmount_Amount
UNION ALL
SELECT C.ContractId,
PayableCodes.GLTemplateId,
SUM(ROUND(Payables.Amount_Amount * PayableInvoices.InitialExchangeRate,2)) AS Amount
FROM #LeaseContracts C
JOIN LeaseFundings ON C.LeaseFinanceId = LeaseFundings.LeaseFinanceId AND LeaseFundings.IsActive=1
JOIN PayableInvoices ON LeaseFundings.FundingId = PayableInvoices.Id
JOIN Payables ON Payables.EntityType = 'PI' AND Payables.EntityId = PayableInvoices.Id AND Payables.Status <> 'Inactive' AND Payables.IsGLPosted = 0
JOIN PayableCodes ON Payables.PayableCodeId = PayableCodes.Id
LEFT JOIN PayableInvoiceOtherCosts ON Payables.SourceTable = 'PayableInvoiceOtherCost' AND  Payables.SourceId = PayableInvoiceOtherCosts.Id AND PayableInvoiceOtherCosts.PayableInvoiceId = PayableInvoices.Id
LEFT JOIN PayableInvoiceOtherCostDetails ON Payables.SourceTable = 'PayableInvoicePPCAsset' AND Payables.SourceId = PayableInvoiceOtherCostDetails.Id
LEFT JOIN PayableInvoiceOtherCosts PPCOtherCosts ON PayableInvoiceOtherCostDetails.PayableInvoiceOtherCostId = PPCOtherCosts.Id AND PPCOtherCosts.PayableInvoiceId = PayableInvoices.Id
WHERE (PayableInvoiceOtherCosts.Id IS NOT NULL AND PayableInvoiceOtherCosts.AllocationMethod NOT IN ('ProgressPaymentCredit','ChargeBack','Absorb','DoNotPay','VendorSubsidy'))
OR (PPCOtherCosts.Id IS NOT NULL AND PPCOtherCosts.AllocationMethod = 'ProgressPaymentCredit')
GROUP BY C.ContractId,PayableCodes.GLTemplateId) AS NonGLPostedPayables ON C.ContractId = NonGLPostedPayables.ContractId
GROUP BY C.ContractId,NonGLPostedPayables.GLTemplateId,C.LeaseContractType,LeaseFinanceDetails.LeaseBookingGLTemplateId
IF EXISTS(SELECT ContractId FROM #LeaseContracts WHERE InterimAssessmentMethod IN('Both','Interest') AND InterimInterestBillingType = 'Capitalize' AND @DeferInterimInterestIncomeRecognition = 0)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit,MatchingGLTemplateId,MatchingFilter)
SELECT
C.ContractId,
CASE WHEN C.LeaseContractType = 'Operating' THEN 'OperatingLeaseBooking' ELSE 'CapitalLeaseBooking' END,
LeaseFinanceDetails.LeaseBookingGLTemplateId,
'CapitalizedInterimInterest',
LeaseInvestmentInfo.CapitalizedInterimInterest - (#AccruedIncomeBalanceSummary.AccruedInterimInterestBalance * (-1)),
0,
LeaseFinanceDetails.InterimInterestIncomeGLTemplateId,
CASE WHEN C.LeaseContractType = 'Operating' THEN 'AccruedInterimInterestForOperating' ELSE 'AccruedInterimInterest' END
FROM
(SELECT * FROM #LeaseContracts WHERE InterimAssessmentMethod IN('Both','Interest') AND InterimInterestBillingType = 'Capitalize') AS C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId
JOIN (SELECT ContractId,
SUM(CapitalizedInterimInterest) CapitalizedInterimInterest
FROM #LeaseInvestmentInfo GROUP BY ContractId)
AS LeaseInvestmentInfo ON C.ContractId = LeaseInvestmentInfo.ContractId
WHERE (LeaseInvestmentInfo.CapitalizedInterimInterest - (#AccruedIncomeBalanceSummary.AccruedInterimInterestBalance * (-1))) <> 0
END
IF EXISTS(SELECT ContractId FROM #LeaseContracts WHERE InterimAssessmentMethod IN('Both','Rent') AND InterimRentBillingType = 'Capitalize' AND @DeferInterimRentIncomeRecognition = 0)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit,MatchingGLTemplateId)
SELECT
C.ContractId,
CASE WHEN C.LeaseContractType = 'Operating' THEN 'OperatingLeaseBooking' ELSE 'CapitalLeaseBooking' END,
LeaseFinanceDetails.LeaseBookingGLTemplateId,
'CapitalizedInterimRent',
LeaseInvestmentInfo.CapitalizedInterimRent - (#AccruedIncomeBalanceSummary.DeferredInterimRentIncomeBalance * (-1)),
0,
LeaseFinanceDetails.InterimRentIncomeGLTemplateId
FROM
(SELECT * FROM #LeaseContracts WHERE InterimAssessmentMethod IN('Both','Rent') AND InterimInterestBillingType = 'Capitalize') AS C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId
JOIN (SELECT ContractId,
SUM(CapitalizedInterimRent) CapitalizedInterimRent
FROM #LeaseInvestmentInfo GROUP BY ContractId)
AS LeaseInvestmentInfo ON C.ContractId = LeaseInvestmentInfo.ContractId
WHERE (LeaseInvestmentInfo.CapitalizedInterimRent - (#AccruedIncomeBalanceSummary.DeferredInterimRentIncomeBalance * (-1))) <> 0
END
IF EXISTS(SELECT ContractId FROM #LeaseContracts WHERE CapitalizeUpfrontSalesTax = 1)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
CASE WHEN C.LeaseContractType = 'Operating' THEN 'OperatingLeaseBooking' ELSE 'CapitalLeaseBooking' END,
LeaseFinanceDetails.LeaseBookingGLTemplateId,
'SalesTaxPayable',
LeaseInvestmentInfo.CapitalizedSalesTax,
0
FROM
(SELECT * FROM #LeaseContracts WHERE CapitalizeUpfrontSalesTax = 1) AS C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN (SELECT ContractId,
SUM(CapitalizedSalesTax) CapitalizedSalesTax
FROM #LeaseInvestmentInfo GROUP BY ContractId)
AS LeaseInvestmentInfo ON C.ContractId = LeaseInvestmentInfo.ContractId
WHERE LeaseInvestmentInfo.CapitalizedSalesTax <> 0
END
IF EXISTS(SELECT ContractId FROM #LeaseContracts WHERE InterimAssessmentMethod IN('Both','Interest') AND InterimInterestBillingType <> 'Capitalize')
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit,MatchingGLTemplateId)
SELECT
C.ContractId,
'LeaseInterimInterestAR',
ReceivableCodes.GLTemplateId,
'AccruedInterimInterest',
#AccruedIncomeBalanceSummary.AccruedInterimInterestBalance,
0,
LeaseFinanceDetails.InterimInterestIncomeGLTemplateId
FROM
(SELECT * FROM #LeaseContracts WHERE InterimAssessmentMethod IN('Both','Interest') AND InterimInterestBillingType <> 'Capitalize') AS C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN ReceivableCodes ON LeaseFinanceDetails.InterimInterestReceivableCodeId = ReceivableCodes.Id
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId
WHERE #AccruedIncomeBalanceSummary.AccruedInterimInterestBalance <> 0
END
IF EXISTS(SELECT ContractId FROM #LeaseContracts WHERE InterimAssessmentMethod IN('Both','Rent') AND InterimRentBillingType <> 'Capitalize')
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit,MatchingGLTemplateId)
SELECT
C.ContractId,
'InterimRentAR',
ReceivableCodes.GLTemplateId,
'DeferredInterimRentIncome',
#AccruedIncomeBalanceSummary.DeferredInterimRentIncomeBalance,
0,
LeaseFinanceDetails.InterimRentIncomeGLTemplateId
FROM
(SELECT * FROM #LeaseContracts WHERE InterimAssessmentMethod IN('Both','Rent') AND InterimRentBillingType <> 'Capitalize') AS C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN ReceivableCodes ON LeaseFinanceDetails.InterimRentReceivableCodeId = ReceivableCodes.Id
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId
WHERE #AccruedIncomeBalanceSummary.DeferredInterimRentIncomeBalance <> 0
END
IF EXISTS(SELECT ContractId FROM #LeaseContracts WHERE IsFloatRateLease = 1)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit,MatchingGLTemplateId)
SELECT
C.ContractId,
'FloatIncome',
LeaseFinanceDetails.FloatIncomeGLTemplateId,
'AccruedFloatRateInterestIncome',
#AccruedIncomeBalanceSummary.AccruedFloatRateInterestIncomeBalance,
1,
ReceivableCodes.GLTemplateId
FROM
(SELECT * FROM #LeaseContracts WHERE IsFloatRateLease = 1) AS C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN ReceivableCodes ON LeaseFinanceDetails.FloatRateARReceivableCodeId = ReceivableCodes.Id
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId
WHERE #AccruedIncomeBalanceSummary.AccruedFloatRateInterestIncomeBalance <> 0
END
IF EXISTS(SELECT ContractId FROM #LeaseContracts WHERE IsOverTermLease = 1)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'OTPIncome',
LeaseFinanceDetails.OTPIncomeGLTemplateId,
'OTPLeasedAsset',
CASE WHEN #AccruedIncomeBalanceSummary.IsFirstOTPIncomeGLPosted = 1
THEN (LeaseInvestmentInfo.OTPLeaseAsset - #AccruedIncomeBalanceSummary.ClearedOTPLeaseAssetAmount)
ELSE #AccruedIncomeBalanceSummary.ClearedOTPLeaseAssetAmount
END,
1
FROM
(SELECT * FROM #LeaseContracts WHERE IsOverTermLease = 1) AS C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId
JOIN (SELECT C.ContractId,SUM(CASE WHEN IsLeaseComponent = 1 AND C.LeaseContractType = 'Operating' THEN (Investment + CapitalizedAmount - ETCAdjustmentAmount) ELSE ROUND(BookedResidual * RetainedPercentage,2) END) OTPLeaseAsset
FROM #LeaseInvestmentInfo
JOIN #LeaseContracts C ON #LeaseInvestmentInfo.ContractId = C.ContractId
GROUP BY C.ContractId)
AS LeaseInvestmentInfo ON C.ContractId = LeaseInvestmentInfo.ContractId
WHERE (#AccruedIncomeBalanceSummary.IsFirstOTPIncomeGLPosted = 1 AND (LeaseInvestmentInfo.OTPLeaseAsset - #AccruedIncomeBalanceSummary.ClearedOTPLeaseAssetAmount) <> 0)
OR (#AccruedIncomeBalanceSummary.IsFirstOTPIncomeGLPosted = 0 AND #AccruedIncomeBalanceSummary.ClearedOTPLeaseAssetAmount<>0)
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'OTPIncome',
LeaseFinanceDetails.OTPIncomeGLTemplateId,
'AccumulatedOTPDepreciation',
CASE WHEN #AccruedIncomeBalanceSummary.IsFirstOTPIncomeGLPosted = 1
THEN (#AccruedIncomeBalanceSummary.AccumulatedFixedTermDepreciation + #AccruedIncomeBalanceSummary.AccumulatedOTPDepreciation)
ELSE #AccruedIncomeBalanceSummary.AccumulatedOTPDepreciation
END AS Amount,
0
FROM
#LeaseContracts C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId =LeaseFinanceDetails.Id
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId AND C.IsOverTermLease=1
WHERE (#AccruedIncomeBalanceSummary.AccumulatedFixedTermDepreciation + #AccruedIncomeBalanceSummary.AccumulatedOTPDepreciation) <> 0
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit,MatchingGLTemplateId)
SELECT
C.ContractId,
'OTPIncome',
LeaseFinanceDetails.OTPIncomeGLTemplateId,
'OTPDeferredIncome',
#AccruedIncomeBalanceSummary.OTPDeferredIncomeBalance,
1,
ReceivableCodes.GLTemplateId
FROM
(SELECT * FROM #LeaseContracts WHERE IsOverTermLease = 1) AS C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN ReceivableCodes ON LeaseFinanceDetails.OTPReceivableCodeId = ReceivableCodes.Id
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId
WHERE #AccruedIncomeBalanceSummary.OTPDeferredIncomeBalance <> 0
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit,MatchingGLTemplateId)
SELECT
C.ContractId,
'OTPIncome',
LeaseFinanceDetails.OTPIncomeGLTemplateId,
'SupplementalDeferredIncome',
#AccruedIncomeBalanceSummary.SupplementalDeferredIncomeBalance,
1,
ReceivableCodes.GLTemplateId
FROM
(SELECT * FROM #LeaseContracts WHERE IsOverTermLease = 1) AS C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN ReceivableCodes ON LeaseFinanceDetails.SupplementalReceivableCodeId = ReceivableCodes.Id
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId
WHERE #AccruedIncomeBalanceSummary.SupplementalDeferredIncomeBalance <> 0
END
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'NBVImpairment',
LeaseAmendments.GLTemplateId,
'AccumulatedNBVImpairment',
(SUM(AssetValueHistories.Value_Amount) * (-1)),
0
FROM #LeaseContracts C
JOIN #AssetValueHistorySummary AVH ON C.ContractId = AVH.ContractId
JOIN AssetValueHistories ON AVH.AssetId = AssetValueHistories.AssetId AND AVH.IsLeaseComponent = AssetValueHistories.IsLeaseComponent AND AssetValueHistories.IsAccounted=1 AND AssetValueHistories.IsLessorOwned = 1 AND AssetValueHistories.GLJournalId IS NOT NULL
JOIN LeaseAmendments ON AssetValueHistories.SourceModuleId = LeaseAmendments.Id AND AssetValueHistories.SourceModule = 'NBVImpairments' AND LeaseAmendments.LeaseAmendmentStatus = 'Approved'
WHERE AVH.MaxAssetValueHistoryId > AssetValueHistories.Id
GROUP BY C.ContractId,LeaseAmendments.GLTemplateId
HAVING (SUM(AssetValueHistories.Value_Amount) * (-1)) <> 0
IF(@MovePLBalance=1)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'NBVImpairment',
LeaseAmendments.GLTemplateId,
'NBVImpairment',
SUM(LeaseAmendments.ImpairmentAmount_Amount),
1
FROM #LeaseContracts C
JOIN LeaseFinances ON C.ContractId = LeaseFinances.ContractId
JOIN LeaseAmendments ON LeaseFinances.Id = LeaseAmendments.CurrentLeaseFinanceId AND LeaseAmendments.AmendmentType = 'NBVImpairment' AND LeaseAmendments.LeaseAmendmentStatus = 'Approved'
WHERE LeaseAmendments.AmendmentDate >= @PLEffectiveDate AND LeaseAmendments.AmendmentDate < @EffectiveDate
GROUP BY C.ContractId,LeaseAmendments.GLTemplateId
HAVING SUM(LeaseAmendments.ImpairmentAmount_Amount) <> 0
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'ResidualImpairment',
LeaseAmendments.GLTemplateId,
'LossOnUnguaranteedResidual',
SUM(LeaseAmendmentImpairmentAssetDetails.PVOfAsset_Amount),
1
FROM #LeaseContracts C
JOIN LeaseFinances ON C.ContractId = LeaseFinances.ContractId
JOIN LeaseAmendments ON LeaseFinances.Id = LeaseAmendments.CurrentLeaseFinanceId AND LeaseAmendments.AmendmentType = 'ResidualImpairment' AND LeaseAmendments.LeaseAmendmentStatus = 'Approved'
JOIN LeaseAmendmentImpairmentAssetDetails ON LeaseAmendments.Id = LeaseAmendmentImpairmentAssetDetails.LeaseAmendmentId AND LeaseAmendmentImpairmentAssetDetails.IsActive=1
WHERE LeaseAmendments.AmendmentDate >= @PLEffectiveDate AND LeaseAmendments.AmendmentDate < @EffectiveDate
GROUP BY C.ContractId,LeaseAmendments.GLTemplateId
HAVING SUM(LeaseAmendmentImpairmentAssetDetails.PVOfAsset_Amount) <> 0
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'LeaseInterimRentIncome',
LeaseFinanceDetails.InterimRentIncomeGLTemplateId,
'InterimRentIncome',
#AccruedIncomeBalanceSummary.InterimRentIncome,
0
FROM #LeaseContracts C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId
WHERE #AccruedIncomeBalanceSummary.InterimRentIncome <> 0
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'LeaseInterimInterestIncome',
LeaseFinanceDetails.InterimInterestIncomeGLTemplateId,
'LeaseInterimInterestIncome',
#AccruedIncomeBalanceSummary.LeaseInterimInterestIncome,
0
FROM #LeaseContracts C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId
WHERE #AccruedIncomeBalanceSummary.LeaseInterimInterestIncome <> 0
IF EXISTS(SELECT ContractId FROM #LeaseContracts WHERE LeaseContractType <> 'Operating')
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'CapitalLeaseIncome',
LeaseFinanceDetails.LeaseIncomeGLTemplateId,
'Income',
#AccruedIncomeBalanceSummary.Income,
0
FROM (SELECT * FROM #LeaseContracts  WHERE LeaseContractType <> 'Operating') C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId
WHERE #AccruedIncomeBalanceSummary.Income <> 0
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'CapitalLeaseIncome',
LeaseFinanceDetails.LeaseIncomeGLTemplateId,
'UnguaranteedResidualIncome',
#AccruedIncomeBalanceSummary.UnguaranteedResidualIncome,
0
FROM (SELECT * FROM #LeaseContracts  WHERE LeaseContractType <> 'Operating') C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId
WHERE #AccruedIncomeBalanceSummary.UnguaranteedResidualIncome <> 0
END
IF EXISTS(SELECT ContractId FROM #LeaseContracts WHERE LeaseContractType = 'Operating')
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'OperatingLeaseIncome',
LeaseFinanceDetails.LeaseIncomeGLTemplateId,
'RentalRevenue',
#AccruedIncomeBalanceSummary.RentalRevenue,
0
FROM (SELECT * FROM #LeaseContracts  WHERE LeaseContractType = 'Operating') C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'OperatingLeaseIncome',
LeaseFinanceDetails.LeaseIncomeGLTemplateId,
'FixedTermDepreciation',
#AccruedIncomeBalanceSummary.FixedTermDepreciation,
1
FROM (SELECT * FROM #LeaseContracts  WHERE LeaseContractType = 'Operating') C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId
WHERE #AccruedIncomeBalanceSummary.FixedTermDepreciation <> 0
END
IF EXISTS(SELECT ContractId FROM #LeaseContracts WHERE IsFASBChangesApplicable = 1)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
CASE WHEN C.LeaseContractType <> 'Operating' THEN 'CapitalLeaseIncome' ELSE 'OperatingLeaseIncome' END,
LeaseFinanceDetails.LeaseIncomeGLTemplateId,
'FinancingIncome',
#AccruedIncomeBalanceSummary.FinancingIncome,
0
FROM (SELECT * FROM #LeaseContracts  WHERE IsFASBChangesApplicable = 1) C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId
WHERE #AccruedIncomeBalanceSummary.FinancingIncome <> 0
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
CASE WHEN C.LeaseContractType <> 'Operating' THEN 'CapitalLeaseIncome' ELSE 'OperatingLeaseIncome' END,
LeaseFinanceDetails.LeaseIncomeGLTemplateId,
'FinancingUnguaranteedResidualIncome',
#AccruedIncomeBalanceSummary.FinancingUnguaranteedResidualIncome,
0
FROM (SELECT * FROM #LeaseContracts  WHERE IsFASBChangesApplicable = 1) C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId
WHERE #AccruedIncomeBalanceSummary.FinancingUnguaranteedResidualIncome <> 0
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'CapitalLeaseIncome',
LeaseFinanceDetails.LeaseIncomeGLTemplateId,
'SellingProfitIncome',
#AccruedIncomeBalanceSummary.SellingProfitIncome,
0
FROM (SELECT * FROM #LeaseContracts  WHERE IsFASBChangesApplicable = 1 AND LeaseContractType ='DirectFinance') C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId
WHERE #AccruedIncomeBalanceSummary.SellingProfitIncome <> 0
END
IF EXISTS(SELECT ContractId FROM #LeaseContracts C WHERE IsOverTermLease=1)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'OTPIncome',
LeaseFinanceDetails.OTPIncomeGLTemplateId,
'OTPIncome',
#AccruedIncomeBalanceSummary.OTPIncome,
0
FROM (SELECT * FROM #LeaseContracts  WHERE IsOverTermLease=1) C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId
WHERE #AccruedIncomeBalanceSummary.OTPIncome <> 0
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'OTPIncome',
LeaseFinanceDetails.OTPIncomeGLTemplateId,
'SupplementalIncome',
#AccruedIncomeBalanceSummary.SupplementalIncome,
0
FROM (SELECT * FROM #LeaseContracts  WHERE IsOverTermLease=1) C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId
WHERE #AccruedIncomeBalanceSummary.SupplementalIncome <> 0
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'OTPIncome',
LeaseFinanceDetails.OTPIncomeGLTemplateId,
'OTPDepreciation',
#AccruedIncomeBalanceSummary.OTPDepreciation,
1
FROM (SELECT * FROM #LeaseContracts  WHERE IsOverTermLease=1) C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId
WHERE #AccruedIncomeBalanceSummary.OTPDepreciation <> 0
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'OTPIncome',
LeaseFinanceDetails.OTPIncomeGLTemplateId,
'ResidualRecapture',
#AccruedIncomeBalanceSummary.ResidualRecapture,
1
FROM (SELECT * FROM #LeaseContracts  WHERE IsOverTermLease=1) C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId
WHERE #AccruedIncomeBalanceSummary.ResidualRecapture <> 0
END
IF EXISTS(SELECT ContractId FROM #LeaseContracts C WHERE IsFloatRateLease=1)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'FloatIncome',
LeaseFinanceDetails.FloatIncomeGLTemplateId,
'FloatInterestIncome',
#AccruedIncomeBalanceSummary.FloatInterestIncome,
0
FROM (SELECT * FROM #LeaseContracts  WHERE IsFloatRateLease=1) C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId
END
CREATE TABLE #ContractSyndicationServiced(ContractId BIGINT,IsSyndicationServiced BIT);
INSERT INTO #ContractSyndicationServiced
SELECT C.ContractId,ISNULL(LeaseSyndicationInfo.IsServiced,0) IsSyndicationServiced
FROM #LeaseContracts C
LEFT JOIN
(SELECT ContractId,LeaseSyndicationServicingDetails.IsServiced FROM
(SELECT C.ContractId,MAX(LeaseSyndicationServicingDetails.Id) MaxSDId FROM #LeaseContracts C
JOIN LeaseSyndications ON C.LeaseFinanceId = LeaseSyndications.Id AND C.IsSyndicatedAtInception=1 AND LeaseSyndications.IsActive=1
JOIN LeaseSyndicationServicingDetails ON LeaseSyndications.Id = LeaseSyndicationServicingDetails.LeaseSyndicationId AND LeaseSyndicationServicingDetails.IsActive=1
GROUP BY C.ContractId) AS LastLeaseSyndicationServicingDetail
JOIN LeaseSyndicationServicingDetails ON LastLeaseSyndicationServicingDetail.MaxSDId = LeaseSyndicationServicingDetails.Id
UNION
SELECT ContractId,ReceivableForTransferServicings.IsServiced FROM
(SELECT C.ContractId,MAX(ReceivableForTransferServicings.Id) MaxSDId FROM #LeaseContracts C
JOIN ReceivableForTransfers ON C.ContractId = ReceivableForTransfers.ContractId AND C.IsSyndicatedAtInception=0 AND ReceivableForTransfers.ApprovalStatus = 'Approved'
JOIN ReceivableForTransferServicings ON ReceivableForTransfers.Id = ReceivableForTransferServicings.ReceivableForTransferId AND ReceivableForTransferServicings.IsActive=1
GROUP BY C.ContractId) AS LastReceivableForTransferServicingDetail
JOIN ReceivableForTransferServicings ON LastReceivableForTransferServicingDetail.MaxSDId = ReceivableForTransferServicings.Id)
AS LeaseSyndicationInfo ON C.ContractId = LeaseSyndicationInfo.ContractId

SELECT
C.ContractId,
Payoffs.Id PayoffId,
Payoffs.PayoffGLTemplateId,
PayoffTerminationOptions.Name AS PayoffTerminationOption,
PayoffAssets.LeaseComponentAssetValuation_Amount LeaseComponentAssetValuation, 
PayoffAssets.NonLeaseComponentAssetValuation_Amount NonLeaseComponentAssetValuation, 
Payoffs.IsGLConsolidated,
CASE WHEN C.LeaseContractType <> 'Operating' 
THEN (PayoffAssets.LessorOwnedNBV_Amount + PayoffAssets.SyndicatedNBV_Amount - PayoffAssets.AssetValuation_Amount)
WHEN (C.LeaseContractType = 'Operating' )
THEN (PayoffAssets.NonLeaseComponentLessorOwnedNBV_Amount + PayoffAssets.SyndicatedNBV_Amount - PayoffAssets.NonLeaseComponentAssetValuation_Amount)
ELSE 0.00
END AS ImpairmentAtPayoff,
CASE WHEN (PayoffAssets.LessorOwnedNBV_Amount + PayoffAssets.SyndicatedNBV_Amount) <> 0 THEN PayoffAssets.LessorOwnedNBV_Amount / (PayoffAssets.LessorOwnedNBV_Amount + PayoffAssets.SyndicatedNBV_Amount) ELSE 0 END AS LessorOwnedAssetValuationFactor,
PayoffAssets.Status PayoffAssetStatus,
Payoffs.AssetBookValueAdjustmentGLTemplateId
INTO #PayoffSummary
FROM #LeaseContracts C
JOIN LeaseFinances ON C.ContractId = LeaseFinances.ContractId
JOIN Payoffs ON LeaseFinances.Id = Payoffs.LeaseFinanceId AND Payoffs.Status = 'Activated'
AND Payoffs.PayoffEffectiveDate >= @PLEffectiveDate AND Payoffs.PayoffEffectiveDate <  @EffectiveDate
JOIN PayoffAssets ON Payoffs.Id = PayoffAssets.PayoffId AND PayoffAssets.IsActive=1
JOIN LeaseAssets ON PayoffAssets.LeaseAssetId = LeaseAssets.Id
LEFT JOIN PayoffTerminationOptions ON Payoffs.TerminationOptionId = PayoffTerminationOptions.Id

---For LeaseComponent COGS
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
CASE WHEN C.LeaseContractType = 'Operating' THEN 'OperatingLeasePayoff' ELSE 'CapitalLeasePayoff' END,
#PayoffSummary.PayoffGLTemplateId,
'CostOfGoodsSold',
CASE WHEN S.IsSyndicationServiced=1 
THEN SUM(ROUND(#PayoffSummary.LeaseComponentAssetValuation * #PayoffSummary.LessorOwnedAssetValuationFactor,2))
ELSE SUM(#PayoffSummary.LeaseComponentAssetValuation) END,
1
FROM #LeaseContracts C
JOIN #PayoffSummary ON C.ContractId = #PayoffSummary.ContractId AND #PayoffSummary.PayoffAssetStatus IN ('Purchase','ReturnToUpgrade')
AND IsGLConsolidated = 0
JOIN #ContractSyndicationServiced S ON C.ContractId = S.ContractId
GROUP BY C.ContractId,#PayoffSummary.PayoffId,#PayoffSummary.PayoffGLTemplateId,S.IsSyndicationServiced,C.LeaseContractType
HAVING SUM(#PayoffSummary.LeaseComponentAssetValuation) <> 0

---For Non LeaseComponent COGS
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
CASE WHEN C.LeaseContractType = 'Operating' THEN 'OperatingLeasePayoff' ELSE 'CapitalLeasePayoff' END,
#PayoffSummary.PayoffGLTemplateId,
'FinancingCostOfGoodsSold',
CASE WHEN S.IsSyndicationServiced=1 
THEN SUM(ROUND(#PayoffSummary.NonLeaseComponentAssetValuation * #PayoffSummary.LessorOwnedAssetValuationFactor,2))
ELSE SUM(#PayoffSummary.NonLeaseComponentAssetValuation) END,
1
FROM #LeaseContracts C
JOIN #PayoffSummary ON C.ContractId = #PayoffSummary.ContractId AND #PayoffSummary.PayoffAssetStatus IN ('Purchase','ReturnToUpgrade')
AND IsGLConsolidated = 0
JOIN #ContractSyndicationServiced S ON C.ContractId = S.ContractId
GROUP BY C.ContractId,#PayoffSummary.PayoffId,#PayoffSummary.PayoffGLTemplateId,S.IsSyndicationServiced,C.LeaseContractType
HAVING SUM(#PayoffSummary.NonLeaseComponentAssetValuation) <> 0


---For GLConsolidated COGS
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
CASE WHEN C.LeaseContractType = 'Operating' THEN 'OperatingLeasePayoff' ELSE 'CapitalLeasePayoff' END,
#PayoffSummary.PayoffGLTemplateId,
'CostOfGoodsSold',
CASE WHEN S.IsSyndicationServiced=1 
THEN SUM(ROUND((#PayoffSummary.NonLeaseComponentAssetValuation + #PayoffSummary.LeaseComponentAssetValuation) * #PayoffSummary.LessorOwnedAssetValuationFactor,2))
ELSE SUM(#PayoffSummary.NonLeaseComponentAssetValuation + #PayoffSummary.LeaseComponentAssetValuation) END,
1
FROM #LeaseContracts C
JOIN #PayoffSummary ON C.ContractId = #PayoffSummary.ContractId AND #PayoffSummary.PayoffAssetStatus IN ('Purchase','ReturnToUpgrade')
AND IsGLConsolidated = 1
JOIN #ContractSyndicationServiced S ON C.ContractId = S.ContractId
GROUP BY C.ContractId,#PayoffSummary.PayoffId,#PayoffSummary.PayoffGLTemplateId,S.IsSyndicationServiced,C.LeaseContractType
HAVING SUM(#PayoffSummary.NonLeaseComponentAssetValuation + #PayoffSummary.LeaseComponentAssetValuation) <> 0

IF EXISTS(SELECT ContractId FROM #LeaseContracts WHERE LeaseContractType <> 'Operating' OR IsFASBChangesApplicable=1)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit,MatchingGLTemplateId)
SELECT
C.ContractId,
CASE WHEN C.LeaseContractType = 'Operating' THEN 'OperatingLeasePayoff' ELSE 'CapitalLeasePayoff' END GLTransactionType,
#PayoffSummary.PayoffGLTemplateId,
'ImpairmentatPayoff',
CASE WHEN S.IsSyndicationServiced=1 THEN SUM(ROUND(#PayoffSummary.ImpairmentAtPayoff * #PayoffSummary.LessorOwnedAssetValuationFactor,2)) ELSE SUM(#PayoffSummary.ImpairmentAtPayoff) END,
1,
#PayoffSummary.AssetBookValueAdjustmentGLTemplateId
FROM (SELECT * FROM #LeaseContracts WHERE LeaseContractType <> 'Operating' OR IsFASBChangesApplicable=1) C
JOIN #PayoffSummary ON C.ContractId = #PayoffSummary.ContractId 
AND #PayoffSummary.PayoffTerminationOption IS NOT NULL
AND #PayoffSummary.PayoffTerminationOption NOT IN('Repossession','Abandonment')
JOIN #ContractSyndicationServiced S ON C.ContractId = S.ContractId
GROUP BY C.ContractId,C.LeaseContractType,#PayoffSummary.PayoffId,#PayoffSummary.PayoffGLTemplateId,S.IsSyndicationServiced,#PayoffSummary.AssetBookValueAdjustmentGLTemplateId
HAVING SUM(#PayoffSummary.ImpairmentAtPayoff) <> 0
END
END
IF EXISTS(SELECT ContractId FROM #LeaseContracts WHERE IsNonAccrual=1)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
CASE WHEN C.LeaseContractType = 'Operating' THEN 'OperatingLeaseIncome' ELSE 'CapitalLeaseIncome' END,
LeaseFinanceDetails.LeaseIncomeGLTemplateId,
CASE WHEN C.LeaseContractType = 'Operating' THEN 'SuspendedRentalRevenue' ELSE 'SuspendedIncome' END,
CASE WHEN C.LeaseContractType = 'Operating' THEN SuspendedRentalRevenueBalance ELSE SuspendedIncomeBalance END,
0
FROM
(SELECT * FROM #LeaseContracts WHERE IsNonAccrual=1) C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId
WHERE (#AccruedIncomeBalanceSummary.SuspendedIncomeBalance <> 0 OR SuspendedRentalRevenueBalance <> 0)
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'CapitalLeaseIncome',
LeaseFinanceDetails.LeaseIncomeGLTemplateId,
'SuspendedUnguaranteedResidualIncome',
SuspendedUnguaranteedResidualIncomeBalance,
0
FROM
(SELECT * FROM #LeaseContracts WHERE IsNonAccrual=1 AND LeaseContractType <> 'Operating') C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId
WHERE #AccruedIncomeBalanceSummary.SuspendedUnguaranteedResidualIncomeBalance <> 0
IF EXISTS(SELECT ContractId FROM #LeaseContracts WHERE IsFASBChangesApplicable = 1)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
CASE WHEN C.LeaseContractType = 'Operating' THEN 'OperatingLeaseIncome' ELSE 'CapitalLeaseIncome' END,
LeaseFinanceDetails.LeaseIncomeGLTemplateId,
'FinancingSuspendedIncome',
FinancingSuspendedIncomeBalance,
0
FROM
(SELECT * FROM #LeaseContracts WHERE IsNonAccrual=1 AND IsFASBChangesApplicable = 1) C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId
WHERE FinancingSuspendedIncomeBalance <> 0
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
CASE WHEN C.LeaseContractType = 'Operating' THEN 'OperatingLeaseIncome' ELSE 'CapitalLeaseIncome' END,
LeaseFinanceDetails.LeaseIncomeGLTemplateId,
'FinancingSuspendedUnguaranteedResidualIncome',
FinancingSuspendedUnguaranteedResidualIncomeBalance,
0
FROM
(SELECT * FROM #LeaseContracts WHERE IsNonAccrual=1 AND IsFASBChangesApplicable = 1) C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId
WHERE #AccruedIncomeBalanceSummary.FinancingSuspendedUnguaranteedResidualIncomeBalance <> 0
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'CapitalLeaseIncome',
LeaseFinanceDetails.LeaseIncomeGLTemplateId,
'SuspendedSellingProfitIncome',
SuspendedSellingProfitIncome,
0
FROM
(SELECT * FROM #LeaseContracts WHERE IsNonAccrual=1 AND LeaseContractType = 'DirectFinance' AND IsFASBChangesApplicable = 1) C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId
WHERE SuspendedSellingProfitIncome <> 0
END
IF EXISTS(SELECT ContractId FROM #LeaseContracts WHERE IsNonAccrual=1 AND IsFloatRateLease=1)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'FloatIncome',
LeaseFinanceDetails.FloatIncomeGLTemplateId,
'FloatRateSuspendedIncome',
FloatRateSuspendedIncomeBalance,
0
FROM
(SELECT * FROM #LeaseContracts WHERE IsNonAccrual=1 AND IsFloatRateLease=1) C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId
WHERE FloatRateSuspendedIncomeBalance <> 0
END
IF EXISTS(SELECT ContractId FROM #LeaseContracts WHERE IsNonAccrual=1 AND IsOverTermLease=1)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'OTPIncome',
LeaseFinanceDetails.OTPIncomeGLTemplateId,
'SuspendedOTPIncome',
SuspendedOTPIncomeBalance,
0
FROM
(SELECT * FROM #LeaseContracts WHERE IsNonAccrual=1 AND IsOverTermLease=1) C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId
WHERE SuspendedOTPIncomeBalance <> 0
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'OTPIncome',
LeaseFinanceDetails.OTPIncomeGLTemplateId,
'SuspendedSupplementalIncome',
SuspendedOTPIncomeBalance,
0
FROM
(SELECT * FROM #LeaseContracts WHERE IsNonAccrual=1 AND IsOverTermLease=1) C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId
WHERE SuspendedSupplementalIncomeBalance <> 0
END
END
END
CREATE TABLE #LeveragedLeaseContracts(ContractId BIGINT,IncomeGLPostedTillDate DATE,CommencementDate DATE,LeveragedLeaseId BIGINT);
INSERT INTO #LeveragedLeaseContracts
SELECT ContractInfo.ContractId,IncomeGLPostedTillDate,LeveragedLeases.CommencementDate,LeveragedLeases.Id LeveragedLeaseId
FROM #ContractInfo ContractInfo
JOIN LeveragedLeases ON ContractInfo.ContractId = LeveragedLeases.ContractId AND LeveragedLeases.IsCurrent=1
WHERE ContractType = 'LeveragedLease' AND IsChargedOff = 0
IF EXISTS(SELECT ContractId FROM #LeveragedLeaseContracts)
BEGIN
CREATE TABLE #LeveragedLeaseInfo(ContractId BIGINT,LongTermLeveragedLeaseReceivableBalance DECIMAL(16,2) DEFAULT 0,ResidualValueBalance DECIMAL(16,2) DEFAULT 0,Equity DECIMAL(16,2) DEFAULT 0, UnearnedIncomeBalance DECIMAL(16,2) DEFAULT 0,GainOrLoss DECIMAL(16,2) DEFAULT 0);
CREATE TABLE #LeveragedLeasePayoffInfo(ContractId BIGINT,LeveragedLeasePayoffId BIGINT,LeveragedLeasePayoffTemplateId BIGINT);
IF(@MovePLBalance=1)
BEGIN
INSERT INTO #LeveragedLeasePayoffInfo
SELECT C.ContractId,MIN(LeveragedLeasePayoffs.Id),MIN(LeveragedLeasePayoffs.LeveragedLeasePayoffGLTemplateId)
FROM #LeveragedLeaseContracts C
JOIN LeveragedLeases ON C.ContractId = LeveragedLeases.ContractId
JOIN LeveragedLeasePayoffs ON LeveragedLeases.Id = LeveragedLeasePayoffs.LeveragedLeaseId AND LeveragedLeasePayoffs.Status = 'Approved'
WHERE LeveragedLeasePayoffs.PayoffDate >= @PLEffectiveDate AND LeveragedLeasePayoffs.PayoffDate < @EffectiveDate
GROUP BY C.ContractId
END
CREATE TABLE #LeveragedLeaseBalanceSummary(ContractId BIGINT,GLEntryItem NVARCHAR(100),TotalDebitAmount DECIMAL(16,2),TotalCreditAmount DECIMAL(16,2));
INSERT INTO #LeveragedLeaseBalanceSummary
SELECT C.ContractId,
GLEntryItems.Name,
SUM(CASE WHEN GLJournalDetails.IsDebit=1 THEN GLJournalDetails.Amount_Amount ELSE 0 END) AS TotalDebitAmount,
SUM(CASE WHEN GLJournalDetails.IsDebit=0 THEN GLJournalDetails.Amount_Amount ELSE 0 END) AS TotalCreditAmount
FROM #LeveragedLeaseContracts C
JOIN GLJournalDetails ON C.ContractId = GLJournalDetails.EntityId AND GLJournalDetails.EntityType = 'Contract' AND GLJournalDetails.IsActive=1
JOIN GLTemplateDetails ON GLJournalDetails.GLTemplateDetailId = GLTemplateDetails.Id AND GLTemplateDetails.IsActive=1
JOIN GLEntryItems ON GLTemplateDetails.EntryItemId = GLEntryItems.Id AND GLEntryItems.Name IN ('LongTermLeveragedLeaseReceivable','UnearnedIncome','ResidualValue','Equity','GainOrLoss')
JOIN GLTransactionTypes ON GLEntryItems.GLTransactionTypeId = GLTransactionTypes.Id AND GLTransactionTypes.Name IN('LeveragedLeaseBooking','LeveragedLeaseAR','LeveragedLeaseIncome','LeveragedLeasePayoff')
LEFT JOIN #LeveragedLeasePayoffInfo LP ON C.ContractId = LP.ContractId
WHERE (GLEntryItems.Name <> 'GainOrLoss' OR (LP.LeveragedLeasePayoffId IS NOT NULL AND LP.LeveragedLeasePayoffId = GLJournalDetails.SourceId))
GROUP BY C.ContractId,GLEntryItems.Name
INSERT INTO #LeveragedLeaseInfo(ContractId)
SELECT ContractId FROM #LeveragedLeaseContracts
UPDATE #LeveragedLeaseInfo
SET LongTermLeveragedLeaseReceivableBalance = L.TotalDebitAmount - L.TotalCreditAmount
FROM #LeveragedLeaseInfo
JOIN #LeveragedLeaseBalanceSummary L ON #LeveragedLeaseInfo.ContractId = L.ContractId AND L.GLEntryItem = 'LongTermLeveragedLeaseReceivable'
UPDATE #LeveragedLeaseInfo
SET ResidualValueBalance = L.TotalDebitAmount - L.TotalCreditAmount
FROM #LeveragedLeaseInfo
JOIN #LeveragedLeaseBalanceSummary L ON #LeveragedLeaseInfo.ContractId = L.ContractId AND L.GLEntryItem = 'ResidualValue'
UPDATE #LeveragedLeaseInfo
SET UnearnedIncomeBalance = L.TotalCreditAmount - L.TotalDebitAmount
FROM #LeveragedLeaseInfo
JOIN #LeveragedLeaseBalanceSummary L ON #LeveragedLeaseInfo.ContractId = L.ContractId AND L.GLEntryItem = 'UnearnedIncome'
UPDATE #LeveragedLeaseInfo
SET Equity = L.TotalCreditAmount - L.TotalDebitAmount
FROM #LeveragedLeaseInfo
JOIN #LeveragedLeaseBalanceSummary L ON #LeveragedLeaseInfo.ContractId = L.ContractId AND L.GLEntryItem = 'Equity'
UPDATE #LeveragedLeaseInfo
SET GainOrLoss = L.TotalDebitAmount - L.TotalCreditAmount
FROM #LeveragedLeaseInfo
JOIN #LeveragedLeaseBalanceSummary L ON #LeveragedLeaseInfo.ContractId = L.ContractId AND L.GLEntryItem = 'GainOrLoss'
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'LeveragedLeaseBooking',
LeveragedLeases.BookingGLTemplateId,
'LongTermLeveragedLeaseReceivable',
#LeveragedLeaseInfo.LongTermLeveragedLeaseReceivableBalance,
1
FROM #LeveragedLeaseContracts C
JOIN #LeveragedLeaseInfo ON C.ContractId = #LeveragedLeaseInfo.ContractId
JOIN LeveragedLeases ON C.LeveragedLeaseId = LeveragedLeases.Id
WHERE #LeveragedLeaseInfo.LongTermLeveragedLeaseReceivableBalance <> 0
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'LeveragedLeaseBooking',
LeveragedLeases.BookingGLTemplateId,
'ResidualValue',
#LeveragedLeaseInfo.ResidualValueBalance,
1
FROM #LeveragedLeaseContracts C
JOIN #LeveragedLeaseInfo ON C.ContractId = #LeveragedLeaseInfo.ContractId
JOIN LeveragedLeases ON C.LeveragedLeaseId = LeveragedLeases.Id
WHERE #LeveragedLeaseInfo.ResidualValueBalance <> 0
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'LeveragedLeaseBooking',
LeveragedLeases.BookingGLTemplateId,
'UnearnedIncome',
#LeveragedLeaseInfo.UnearnedIncomeBalance,
0
FROM #LeveragedLeaseContracts C
JOIN #LeveragedLeaseInfo ON C.ContractId = #LeveragedLeaseInfo.ContractId
JOIN LeveragedLeases ON C.LeveragedLeaseId = LeveragedLeases.Id
WHERE #LeveragedLeaseInfo.UnearnedIncomeBalance <> 0
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'LeveragedLeaseBooking',
LeveragedLeases.BookingGLTemplateId,
'Equity',
#LeveragedLeaseInfo.Equity,
0
FROM #LeveragedLeaseContracts C
JOIN #LeveragedLeaseInfo ON C.ContractId = #LeveragedLeaseInfo.ContractId
JOIN LeveragedLeases ON C.LeveragedLeaseId = LeveragedLeases.Id
WHERE #LeveragedLeaseInfo.Equity <> 0
DECLARE @LevLeaseContractIds ContractIdCollection;
INSERT INTO @TaxLeaseContractIds
SELECT ContractId FROM #LeveragedLeaseContracts
INSERT INTO #GLSummary
EXEC ProcessDeferredTaxLiabilitiesForGLTransfer @EffectiveDate = @EffectiveDate,@MovePLBalance = @MovePLBalance,@PLEffectiveDate = @PLEffectiveDate,@ContractType = 'LeveragedLease',@ContractIds = @LevLeaseContractIds
IF(@MovePLBalance=1)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'LeveragedLeaseIncome',
LeveragedLeases.IncomeGLTemplateId,
'LeveragedLeaseIncome',
SUM(LeveragedLeaseAmorts.PreTaxIncome_Amount),
0
FROM #LeveragedLeaseContracts C
JOIN LeveragedLeases ON C.ContractId = LeveragedLeases.ContractId
JOIN LeveragedLeaseAmorts ON LeveragedLeases.Id = LeveragedLeaseAmorts.LeveragedLeaseId AND LeveragedLeaseAmorts.IsAccounting=1 AND LeveragedLeaseAmorts.IsActive=1
AND LeveragedLeaseAmorts.IncomeDate >= @PLEffectiveDate AND LeveragedLeaseAmorts.IncomeDate < @EffectiveDate
GROUP BY C.ContractId,LeveragedLeases.IncomeGLTemplateId
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'LeveragedLeasePayoff',
Payoff.LeveragedLeasePayoffTemplateId,
'GainOrLoss',
#LeveragedLeaseInfo.GainOrLoss,
1
FROM #LeveragedLeaseContracts C
JOIN #LeveragedLeaseInfo ON C.ContractId = #LeveragedLeaseInfo.ContractId AND #LeveragedLeaseInfo.GainOrLoss <> 0
JOIN #LeveragedLeasePayoffInfo Payoff ON #LeveragedLeaseInfo.ContractId = Payoff.ContractId
END
END
IF EXISTS(SELECT ContractId FROM #ContractInfo ContractInfo WHERE ContractType IN('Lease','Loan') AND (IsChargedoff=0 OR @MovePLBalance=1))
BEGIN
SELECT Contracts.ContractId,
SecurityDeposits.Id SecurityDepositId,
SecurityDeposits.LegalEntityId,
SecurityDeposits.CustomerId,
SecurityDeposits.InstrumentTypeId,
SecurityDeposits.LineofBusinessId,
ReceivableCodes.GLTemplateId,
SecurityDeposits.CostCenterId,
SecurityDepositAllocations.Amount_Amount,
SecurityDepositAllocations.Id AS AllocationId,
SecurityDepositApplications.PostDate,
ISNULL(SecurityDepositApplications.TransferToIncome_Amount + SecurityDepositApplications.TransferToReceipt_Amount + SecurityDepositApplications.AssumedAmount_Amount,0) AS AppliedAmount,
ISNULL(SecurityDepositApplications.TransferToIncome_Amount,0) TransferToIncome,
ISNULL(SecurityDepositApplications.TransferToReceipt_Amount,0) TransferToReceipt
INTO #SecurityDepositInfo
FROM (SELECT * FROM #ContractInfo ContractInfo WHERE ContractType IN('Lease','Loan') AND (IsChargedoff=0 OR @MovePLBalance=1)) AS Contracts
JOIN SecurityDeposits ON Contracts.ContractId = SecurityDeposits.ContractId AND SecurityDeposits.IsActive=1
JOIN SecurityDepositAllocations ON SecurityDepositAllocations.SecurityDepositId = SecurityDeposits.Id AND SecurityDepositAllocations.IsActive=1
AND SecurityDepositAllocations.ContractId = Contracts.ContractId
LEFT JOIN SecurityDepositApplications ON SecurityDeposits.Id = SecurityDepositApplications.SecurityDepositId AND SecurityDepositApplications.ContractId = SecurityDepositAllocations.ContractId AND SecurityDepositApplications.IsActive=1
JOIN ReceivableCodes ON SecurityDeposits.ReceivableCodeId = ReceivableCodes.Id
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit,InstrumentTypeId,LineofBusinesssId,CostCenterId,LegalEntityId)
SELECT
Contracts.ContractId,
'SecurityDeposit',
GLTemplateId,
'SecurityDepositLiabilityContract',
Amount_Amount - SUM(AppliedAmount),
0,
InstrumentTypeId,
LineofBusinessId,
CostCenterId,
LegalEntityId
FROM (SELECT * FROM #ContractInfo ContractInfo WHERE ContractType IN('Lease','Loan') AND IsChargedoff=0) AS Contracts
JOIN #SecurityDepositInfo ON Contracts.ContractId = #SecurityDepositInfo.ContractId
GROUP BY Contracts.ContractId,SecurityDepositId,LegalEntityId,CustomerId,InstrumentTypeId,LineofBusinessId,GLTemplateId,CostCenterId,Amount_Amount,AllocationId
HAVING Amount_Amount - SUM(AppliedAmount) <> 0
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit,InstrumentTypeId,LineofBusinesssId,CostCenterId,LegalEntityId)
SELECT
Contracts.ContractId,
'SecurityDeposit',
GLTemplateId,
'TransferToReceipt',
SUM(TransferToReceipt),
0,
InstrumentTypeId,
LineofBusinessId,
CostCenterId,
LegalEntityId
FROM (SELECT * FROM #ContractInfo ContractInfo WHERE ContractType IN('Lease','Loan') AND IsChargedoff=0) AS Contracts
JOIN #SecurityDepositInfo ON Contracts.ContractId = #SecurityDepositInfo.ContractId
GROUP BY Contracts.ContractId,SecurityDepositId,LegalEntityId,CustomerId,InstrumentTypeId,LineofBusinessId,GLTemplateId,CostCenterId
HAVING SUM(TransferToReceipt) <> 0
IF(@MovePLBalance=1)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit,InstrumentTypeId,LineofBusinesssId,CostCenterId,LegalEntityId)
SELECT
Contracts.ContractId,
'SecurityDeposit',
GLTemplateId,
'TransferToIncome',
SUM(TransferToIncome),
0,
InstrumentTypeId,
LineofBusinessId,
CostCenterId,
LegalEntityId
FROM (SELECT * FROM #ContractInfo ContractInfo WHERE ContractType IN('Lease','Loan') AND (IsChargedoff=0 OR @MovePLBalance=1)) AS Contracts
JOIN #SecurityDepositInfo ON Contracts.ContractId = #SecurityDepositInfo.ContractId
GROUP BY Contracts.ContractId,SecurityDepositId,LegalEntityId,CustomerId,InstrumentTypeId,LineofBusinessId,GLTemplateId,CostCenterId
HAVING SUM(TransferToIncome) <> 0
END
END
IF EXISTS(SELECT ContractId FROM #ContractInfo ContractInfo WHERE ContractType IN('Lease','Loan') AND IsChargedoff=0)
BEGIN
SELECT
ContractInfo.ContractId,
WriteDowns.GLTemplateId,
WriteDowns.RecoveryGLTemplateId,
WriteDowns.WriteDownDate,
WriteDowns.WriteDownAmount_Amount,
WriteDowns.IsRecovery
INTO #WriteDownInfo
FROM #ContractInfo ContractInfo
JOIN WriteDowns ON ContractInfo.ContractId = WriteDowns.ContractId AND ContractInfo.ContractType IN('Lease','Loan')
AND ContractInfo.IsChargedoff=0 AND WriteDowns.Status = 'Approved'
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
ContractId,
'WriteDown',
GLTemplateId,
'WritedownAccount',
SUM(WriteDownAmount_Amount),
0
FROM #WriteDownInfo
GROUP BY ContractId,GLTemplateId
IF(@MovePLBalance=1)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
#WriteDownInfo.ContractId,
CASE WHEN IsRecovery=1 THEN 'WriteDownRecovery' ELSE 'WriteDown' END,
CASE WHEN IsRecovery=1 THEN RecoveryGLTemplateId ELSE GLTemplateId END,
CASE WHEN IsRecovery=1 THEN 'RecoveryIncome' ELSE 'NetChargeOff' END,
CASE WHEN IsRecovery=1 THEN SUM(WriteDownAmount_Amount) * (-1) ELSE SUM(WriteDownAmount_Amount) END,
CASE WHEN IsRecovery=1 THEN 0 ELSE 1 END
FROM #WriteDownInfo
WHERE WriteDownDate >= @PLEffectiveDate AND WriteDownDate < @EffectiveDate
GROUP BY ContractId,GLTemplateId,RecoveryGLTemplateId,IsRecovery
END
END
DECLARE @ContractIdsForPayables ContractIdCollection;
INSERT INTO @ContractIdsForPayables
SELECT ContractId FROM #ContractInfo WHERE ContractType <> 'LeveragedLease'
INSERT INTO #GLSummary
EXEC ProcessPayablesForGLTransfer @EffectiveDate = @EffectiveDate,@MovePLBalance = @MovePLBalance,@PLEffectiveDate = @PLEffectiveDate,@ContractInfo = @ContractIdsForPayables;
DECLARE @ContractIdsForSalesTaxReceiavbles ContractIdCollection;
INSERT INTO @ContractIdsForSalesTaxReceiavbles
SELECT ContractId FROM #ContractInfo
INSERT INTO #GLSummary
EXEC ProcessSalesTaxReceivablesForGLTransfer @EffectiveDate = @EffectiveDate,@MovePLBalance = @MovePLBalance,@PLEffectiveDate = @PLEffectiveDate,@ContractInfo = @ContractIdsForSalesTaxReceiavbles,@ExcludeSalesTaxPayableDuringGLTransfer = @ExcludeSalesTaxPayableDuringGLTransfer;
-- ProcessReceipts
-- ProcessReceivables
SELECT C.ContractId,
Receivables.Id AS ReceivableId,
Receivables.DueDate,
CASE WHEN Receivables.FunderId IS NULL THEN GLTransactionTypes.Name ELSE SyndicationGLTransactionType.Name END AS GLTransactionTypeName,
CASE WHEN Receivables.FunderId IS NULL THEN ReceivableCodes.GLTemplateId ELSE ReceivableCodes.SyndicationGLTemplateId END AS GLTemplateId,
Receivables.IsGLPosted,
Receivables.TotalAmount_Amount ReceivableAmount,
Receivables.TotalBalance_Amount ReceivableBalance, 
ReceivableCodes.AccountingTreatment,
Receivables.IncomeType,
CASE WHEN Receivables.InvoiceComment = @SyndicationActualProceeds THEN 1 ELSE 0 END AS IsSyndicationActualProceeds,
CASE WHEN Receivables.IsGLPosted=1 THEN Receivables.TotalBalance_Amount ELSE Receivables.TotalBalance_Amount - Receivables.TotalAmount_Amount END AS AmountToBeReclassed,
CAST(0 AS BIT) AS IsFinancingComponent
INTO #ReceivableInfo
FROM #ContractInfo C
JOIN Receivables ON C.ContractId = Receivables.EntityId AND Receivables.EntityType = 'CT' AND Receivables.IsActive=1
JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
JOIN GLTemplates ON ReceivableCodes.GLTemplateId = GLTemplates.Id
JOIN GLTransactionTypes ON GLTemplates.GLTransactionTypeId = GLTransactionTypes.Id AND (C.IsChargedoff = 0 OR GLTransactionTypes.Name IN ('PropertyTaxAR','PropertyTaxEscrow','AssetSaleAR','NonRentalAR'))
LEFT JOIN GLTemplates SyndicationGLTemplate ON ReceivableCodes.SyndicationGLTemplateId = SyndicationGLTemplate.Id
LEFT JOIN GLTransactionTypes SyndicationGLTransactionType ON SyndicationGLTemplate.GLTransactionTypeId = SyndicationGLTransactionType.Id
LEFT JOIN #FAS91ReceivableIds R ON R.ReceivableId = Receivables.Id
LEFT JOIN LeasePaymentSchedules ON Receivables.PaymentScheduleId = LeasePaymentSchedules.Id AND C.ContractType = 'Lease' AND Receivables.SourceTable <> 'CPUSchedule'
LEFT JOIN LoanPaymentSchedules ON Receivables.PaymentScheduleId = LoanPaymentSchedules.Id AND C.ContractType IN('Loan','ProgressLoan')
WHERE (ISNULL(ISNULL(LeasePaymentSchedules.EndDate,LoanPaymentSchedules.EndDate),Receivables.DueDate) < @EffectiveDate)
AND ReceivableTypes.Name NOT IN ('CapitalLeaseRental','OperatingLeaseRental','LeasePayOff','BuyOut')
AND (C.IsChargedoff = 0 OR R.ReceivableId IS NULL)
AND Receivables.IsDummy = 0
AND (Receivables.IsGLPosted=1 OR Receivables.TotalAmount_Amount <> Receivables.TotalBalance_Amount OR Receivables.InvoiceComment = @SyndicationActualProceeds)
 
 SELECT
C.ContractId,
Receivables.Id AS ReceivableId,
ReceivableCodes.GLTemplateId,
ReceivableCodes.SyndicationGLTemplateId,
ReceivableCodes.AccountingTreatment, 
SUM(ReceivableDetails.LeaseComponentAmount_Amount) ReceivableLeaseComponentAmount,
SUM(ReceivableDetails.LeaseComponentBalance_Amount) ReceivableLeaseComponentBalance,
SUM(ReceivableDetails.NonLeaseComponentAmount_Amount) ReceivableNonLeaseComponentAmount,
SUM(ReceivableDetails.NonLeaseComponentBalance_Amount) ReceivableNonLeaseComponentBalance 
INTO #ReceivableDetailInfo
FROM (SELECT * FROM #ContractInfo WHERE IsChargedoff = 0) C
JOIN Receivables ON C.ContractId = Receivables.EntityId AND Receivables.EntityType = 'CT' AND Receivables.IsActive=1
JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id AND ReceivableTypes.Name IN ('CapitalLeaseRental','OperatingLeaseRental')
JOIN ReceivableDetails ON Receivables.Id = ReceivableDetails.ReceivableId AND ReceivableDetails.IsActive=1
JOIN LeasePaymentSchedules ON Receivables.PaymentScheduleId = LeasePaymentSchedules.Id AND C.ContractType = 'Lease' AND Receivables.SourceTable <> 'CPUSchedule'
WHERE LeasePaymentSchedules.EndDate < @EffectiveDate
AND (Receivables.IsGLPosted=1 OR ReceivableDetails.Amount_Amount <> ReceivableDetails.Balance_Amount)
AND Receivables.IsDummy = 0
GROUP BY
C.ContractId,
Receivables.Id,
ReceivableCodes.GLTemplateId,
ReceivableCodes.SyndicationGLTemplateId, 
ReceivableCodes.AccountingTreatment

INSERT INTO #ReceivableDetailInfo
SELECT
C.ContractId,
Receivables.Id AS ReceivableId,
ReceivableCodes.GLTemplateId,
ReceivableCodes.SyndicationGLTemplateId,
ReceivableCodes.AccountingTreatment, 
SUM(ReceivableDetails.LeaseComponentAmount_Amount) ReceivableLeaseComponentAmount,
SUM(ReceivableDetails.LeaseComponentBalance_Amount) ReceivableLeaseComponentBalance,
SUM(ReceivableDetails.NonLeaseComponentAmount_Amount) ReceivableNonLeaseComponentAmount,
SUM(ReceivableDetails.NonLeaseComponentBalance_Amount) ReceivableNonLeaseComponentBalance 
FROM (SELECT * FROM #ContractInfo WHERE IsChargedoff = 0) C
JOIN Receivables ON C.ContractId = Receivables.EntityId AND Receivables.EntityType = 'CT' AND Receivables.IsActive=1
JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
AND ReceivableTypes.Name IN ('LeasePayOff','BuyOut')
JOIN GLTemplates ON ReceivableCodes.GLTemplateId = GLTemplates.Id
JOIN GLTransactionTypes ON GLTemplates.GLTransactionTypeId = GLTransactionTypes.Id AND C.IsChargedoff = 0
JOIN ReceivableDetails ON Receivables.Id = ReceivableDetails.ReceivableId AND ReceivableDetails.IsActive=1
LEFT JOIN GLTemplates SyndicationGLTemplate ON ReceivableCodes.SyndicationGLTemplateId = SyndicationGLTemplate.Id
LEFT JOIN GLTransactionTypes SyndicationGLTransactionType ON SyndicationGLTemplate.GLTransactionTypeId = SyndicationGLTransactionType.Id
WHERE Receivables.DueDate < @EffectiveDate
AND C.IsChargedoff = 0
AND Receivables.IsDummy = 0
AND (Receivables.IsGLPosted=1 OR Receivables.TotalAmount_Amount <> Receivables.TotalBalance_Amount 
OR Receivables.InvoiceComment = @SyndicationActualProceeds)
GROUP BY
C.ContractId,
Receivables.Id,
ReceivableCodes.GLTemplateId,
ReceivableCodes.SyndicationGLTemplateId, 
ReceivableCodes.AccountingTreatment


INSERT INTO #ReceivableInfo
SELECT ReceivableInfo.ContractId,
Receivables.Id AS ReceivableId,
Receivables.DueDate,
CASE WHEN Receivables.FunderId IS NULL THEN GLTransactionTypes.Name ELSE SyndicationGLTransactionType.Name END AS GLTransactionTypeName,
CASE WHEN Receivables.FunderId IS NULL THEN ReceivableInfo.GLTemplateId ELSE ReceivableInfo.SyndicationGLTemplateId END AS GLTemplateId,
Receivables.IsGLPosted, 
ReceivableInfo.ReceivableLeaseComponentAmount ReceivableAmount,
ReceivableInfo.ReceivableLeaseComponentBalance ReceivableBalance, 
ReceivableInfo.AccountingTreatment,
Receivables.IncomeType,
CAST(0 AS BIT) IsSyndicationActualProceeds,
CASE WHEN Receivables.IsGLPosted=1 THEN ReceivableInfo.ReceivableLeaseComponentBalance ELSE ReceivableInfo.ReceivableLeaseComponentBalance - ReceivableInfo.ReceivableLeaseComponentAmount END AS AmountToBeReclassed
,CAST(0 AS BIT) AS IsFinancingComponent
FROM  #ReceivableDetailInfo AS ReceivableInfo
JOIN Receivables ON ReceivableInfo.ReceivableId = Receivables.Id
JOIN GLTemplates ON ReceivableInfo.GLTemplateId = GLTemplates.Id
JOIN GLTransactionTypes ON GLTemplates.GLTransactionTypeId = GLTransactionTypes.Id
LEFT JOIN GLTemplates SyndicationGLTemplate ON ReceivableInfo.SyndicationGLTemplateId = SyndicationGLTemplate.Id
LEFT JOIN GLTransactionTypes SyndicationGLTransactionType ON SyndicationGLTemplate.GLTransactionTypeId = SyndicationGLTransactionType.Id

INSERT INTO #ReceivableInfo
SELECT ReceivableInfo.ContractId,
Receivables.Id AS ReceivableId,
Receivables.DueDate,
CASE WHEN Receivables.FunderId IS NULL THEN GLTransactionTypes.Name ELSE SyndicationGLTransactionType.Name END AS GLTransactionTypeName,
CASE WHEN Receivables.FunderId IS NULL THEN ReceivableInfo.GLTemplateId ELSE ReceivableInfo.SyndicationGLTemplateId END AS GLTemplateId,
Receivables.IsGLPosted, 
ReceivableInfo.ReceivableNonLeaseComponentAmount ReceivableAmount,
ReceivableInfo.ReceivableNonLeaseComponentBalance ReceivableBalance, 
ReceivableInfo.AccountingTreatment,
Receivables.IncomeType,
CAST(0 AS BIT) IsSyndicationActualProceeds,
CASE WHEN Receivables.IsGLPosted=1 THEN ReceivableInfo.ReceivableNonLeaseComponentBalance ELSE ReceivableInfo.ReceivableNonLeaseComponentBalance - ReceivableInfo.ReceivableNonLeaseComponentAmount END AS AmountToBeReclassed
,CAST(1 AS BIT) AS IsFinancingComponent
FROM  #ReceivableDetailInfo AS ReceivableInfo
JOIN Receivables ON ReceivableInfo.ReceivableId = Receivables.Id
JOIN GLTemplates ON ReceivableInfo.GLTemplateId = GLTemplates.Id
JOIN GLTransactionTypes ON GLTemplates.GLTransactionTypeId = GLTransactionTypes.Id
LEFT JOIN GLTemplates SyndicationGLTemplate ON ReceivableInfo.SyndicationGLTemplateId = SyndicationGLTemplate.Id
LEFT JOIN GLTransactionTypes SyndicationGLTransactionType ON SyndicationGLTemplate.GLTransactionTypeId = SyndicationGLTransactionType.Id

CREATE TABLE #ReceivableAmountPostedInfo(ReceivableId BIGINT, AmountPosted DECIMAL(16,2));
IF EXISTS(SELECT ContractId FROM #ReceivableInfo WHERE ReceivableAmount <> ReceivableBalance)
BEGIN
INSERT INTO #ReceivableAmountPostedInfo
SELECT ReceivableDetails.ReceivableId,SUM(ReceiptApplicationReceivableDetails.AmountApplied_Amount) AmountPosted
FROM
(SELECT ReceivableId FROM #ReceivableInfo WHERE ReceivableAmount <> ReceivableBalance GROUP BY ReceivableId) AS ReceivableIds
JOIN ReceivableDetails ON ReceivableIds.ReceivableId = ReceivableDetails.ReceivableId AND ReceivableDetails.IsActive=1
JOIN ReceiptApplicationReceivableDetails ON ReceivableDetails.Id = ReceiptApplicationReceivableDetails.ReceivableDetailId AND ReceiptApplicationReceivableDetails.IsActive=1
JOIN ReceiptApplications ON ReceiptApplicationReceivableDetails.ReceiptApplicationId = ReceiptApplications.Id
JOIN Receipts ON ReceiptApplications.ReceiptId = Receipts.Id AND Receipts.Status = 'Posted'
GROUP BY ReceivableDetails.ReceivableId
END
DECLARE @GLTransactionTypes TABLE(Name NVARCHAR(56));
INSERT INTO @GLTransactionTypes VALUES
('NonRentalAR'),('SecurityDeposit'),('LoanInterestAR'),('LoanPrincipalAR'),('LeaseInterimInterestAR'),('InterimRentAR'),('CapitalLeaseAR'),('OTPAR'),
('OperatingLeaseAR'),('PropertyTaxAR'),('PropertyTaxEscrow'),('FloatRateAR'),('AssetSaleAR'),('PayoffBuyoutAR'),('LeveragedLeaseAR'),('SyndicatedAR')
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
ContractId,
GLTransactionTypeName,
GLTemplateId,
CASE WHEN GLTransactionTypeName = 'NonRentalAR' THEN CASE WHEN IsGLPosted = 0 THEN 'PrePaidNonRentalReceivable' ELSE 'NonRentalReceivable' END
WHEN GLTransactionTypeName = 'SecurityDeposit' THEN 'SecurityDepositReceivable'
WHEN GLTransactionTypeName = 'LoanInterestAR' THEN CASE WHEN IsGLPosted = 0 THEN 'PrePaidInterestReceivable' ELSE 'InterestReceivable' END
WHEN GLTransactionTypeName = 'LoanPrincipalAR' THEN CASE WHEN IsGLPosted = 0 THEN 'PrePaidPrincipalReceivable' ELSE 'PrincipalReceivable' END
WHEN GLTransactionTypeName = 'LeaseInterimInterestAR' THEN CASE WHEN IsGLPosted = 0 THEN 'PrepaidLeaseInterimInterestReceivable' ELSE 'LeaseInterimInterestReceivable' END
WHEN GLTransactionTypeName = 'InterimRentAR' THEN CASE WHEN IsGLPosted = 0 THEN 'PrePaidInterimRentReceivable' ELSE 'InterimRentReceivable' END
WHEN GLTransactionTypeName IN('CapitalLeaseAR','OperatingLeaseAR') AND IsFinancingComponent = 1 THEN CASE WHEN IsGLPosted = 0 THEN 'FinancingPrePaidLeaseReceivable' ELSE 'FinancingShortTermLeaseReceivable' END
WHEN GLTransactionTypeName = 'CapitalLeaseAR' THEN CASE WHEN IsGLPosted = 0 THEN 'PrePaidCapitalLeaseReceivable' ELSE 'ShortTermLeaseReceivable' END
WHEN GLTransactionTypeName = 'OperatingLeaseAR' THEN CASE WHEN IsGLPosted = 0 THEN 'PrePaidOperatingLeaseReceivable' ELSE 'OperatingLeaseRentReceivable' END
WHEN GLTransactionTypeName = 'OTPAR' AND IncomeType = 'OTP' THEN CASE WHEN IsGLPosted = 0 THEN 'PrePaidOTPReceivable' ELSE 'OTPReceivable' END
WHEN GLTransactionTypeName = 'OTPAR' AND IncomeType = 'Supplemental' THEN CASE WHEN IsGLPosted = 0 THEN 'SupplementalPrepaidReceivable' ELSE 'SupplementalReceivable' END
WHEN GLTransactionTypeName = 'PropertyTaxAR' THEN CASE WHEN IsGLPosted = 0 THEN 'PrepaidPropertyTaxReceivable' ELSE 'PropertyTaxReceivable' END
WHEN GLTransactionTypeName = 'PropertyTaxEscrow' THEN CASE WHEN IsGLPosted = 0 THEN 'PrepaidPropertyTaxEscrowReceivable' ELSE 'PropertyTaxEscrowReceivable' END
WHEN GLTransactionTypeName = 'FloatRateAR' THEN CASE WHEN IsGLPosted = 0 THEN 'PrePaidFloatRateAR' ELSE 'FloatRateAR' END
WHEN GLTransactionTypeName = 'AssetSaleAR' THEN CASE WHEN IsGLPosted = 0 THEN 'PrepaidAssetSaleReceivable' ELSE 'AssetSaleReceivable' END
WHEN GLTransactionTypeName = 'PayoffBuyoutAR' THEN CASE WHEN IsGLPosted = 0 THEN 'PrepaidPayoffBuyoutReceivable' ELSE 'PayoffBuyoutReceivable' END
WHEN GLTransactionTypeName = 'LeveragedLeaseAR' THEN CASE WHEN IsGLPosted = 0 THEN 'PrepaidLeveragedLeaseReceivable' ELSE 'LeveragedLeaseReceivable' END
WHEN GLTransactionTypeName = 'SyndicatedAR' THEN CASE WHEN IsGLPosted = 0 THEN 'PrePaidDueToThirdPartyAR' ELSE 'DueToThirdPartyAR' END
END,
SUM(AmountToBeReclassed),
1
FROM #ReceivableInfo
JOIN @GLTransactionTypes G ON #ReceivableInfo.GLTransactionTypeName = G.Name
GROUP BY ContractId,GLTemplateId,GLTransactionTypeName,IsGLPosted,IncomeType,IsFinancingComponent
IF EXISTS(SELECT ContractId FROM #ReceivableInfo WHERE GLTransactionTypeName = 'NonRentalAR' AND AccountingTreatment IN('Memo','CashBased'))
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
ContractId,
'NonRentalAR',
GLTemplateId,
CASE WHEN AccountingTreatment = 'CashBased' THEN 'NonRentalIncomeCashBasisContra' ELSE 'NonRentalIncomeMemoBasisContra' END,
SUM(NonRentalContractAmount),
0
FROM
(SELECT GLTemplateId,
ContractId,
AccountingTreatment,
CASE WHEN IsGLPosted = 1
THEN ReceivableBalance
ELSE (ReceivableAmount - ReceivableBalance) * (-1)
END AS NonRentalContractAmount
FROM #ReceivableInfo WHERE GLTransactionTypeName = 'NonRentalAR' AND AccountingTreatment IN('Memo','CashBased')) AS Receivables
GROUP BY GLTemplateId,ContractId,AccountingTreatment
END
IF EXISTS(SELECT ContractId FROM #ReceivableInfo WHERE GLTransactionTypeName = 'PropertyTaxAR' AND IsGLPosted=1)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
ContractId,
'PropertyTaxAR',
GLTemplateId,
'UncollectedPropertyTaxPayable',
SUM(ReceivableAmount),
0
FROM
#ReceivableInfo
WHERE GLTransactionTypeName = 'PropertyTaxAR' AND IsGLPosted=1
GROUP BY GLTemplateId,ContractId
END
IF EXISTS(SELECT ContractId FROM #ReceivableInfo WHERE GLTransactionTypeName = 'PropertyTaxEscrow' AND AccountingTreatment='CashBased')
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
ContractId,
'PropertyTaxEscrow',
GLTemplateId,
'UncollectedPropertyTaxEscrowReceivable',
SUM(UnCollectedPropertyTaxEscrowReceivable),
0
FROM (SELECT ContractId,GLTemplateId,CASE WHEN IsGLPosted = 1 THEN SUM(ReceivableBalance) ELSE SUM(ReceivableAmount - ReceivableBalance) * (-1) END AS UnCollectedPropertyTaxEscrowReceivable
FROM #ReceivableInfo WHERE GLTransactionTypeName = 'PropertyTaxEscrow' AND AccountingTreatment='CashBased' GROUP BY ContractId,GLTemplateId,IsGLPosted)
AS ReceivableInfo
GROUP BY GLTemplateId,ContractId
END
IF EXISTS(SELECT ContractId FROM #ReceivableInfo WHERE GLTransactionTypeName = 'SyndicatedAR')
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
ContractId,
'SyndicatedAR',
GLTemplateId,
'UncollectedDueToInvestorAP',
SUM(UnCollectedRentDueToInvestorAPBalance),
0
FROM (SELECT ContractId,
GLTemplateId,
CASE WHEN IsGLPosted = 1 THEN SUM(ReceivableAmount) - SUM(ISNULL(TotalClearedReceivablePortion,0)) ELSE SUM(ISNULL(TotalClearedReceivablePortion,0)) * (-1) END AS UnCollectedRentDueToInvestorAPBalance
FROM (SELECT * FROM #ReceivableInfo WHERE GLTransactionTypeName='SyndicatedAR') AS Receivables
LEFT JOIN (SELECT Payables.SourceId ReceivableId,SUM(Payables.Amount_Amount - Payables.TaxPortion_Amount) TotalClearedReceivablePortion,SUM(Payables.TaxPortion_Amount) TotalClearedTaxPortion
FROM
(SELECT ReceivableId FROM #ReceivableInfo WHERE GLTransactionTypeName='SyndicatedAR' GROUP BY ReceivableId) AS SyndicatedReceivables
JOIN Payables ON SyndicatedReceivables.ReceivableId = Payables.SourceId AND Payables.SourceTable = 'SyndicatedAR' AND Payables.Status <> 'Inactive' AND Payables.IsGLPosted=1
JOIN Sundries ON Payables.Id = Sundries.PayableId AND Sundries.IsActive=1
GROUP BY Payables.SourceId)
AS PayableInfoForSyndicatedReceivables ON Receivables.ReceivableId = PayableInfoForSyndicatedReceivables.ReceivableId
GROUP BY ContractId,GLTemplateId,IsGLPosted)
AS ReceivableInfo
GROUP BY GLTemplateId,ContractId
END
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
ContractId,
'PropertyTaxEscrow',
GLTemplateId,
'PropertyTaxEscrow',
TotalCreditAmount - TotalDebitAmount,
0
FROM
(SELECT
C.ContractId,
CASE WHEN MatchingDetail.GLTemplateId IS NOT NULL THEN MatchingDetail.GLTemplateId ELSE GLTemplateDetails.GLTemplateId END GLTemplateId,
SUM(CASE WHEN GLJournalDetails.IsDebit=1 THEN GLJournalDetails.Amount_Amount ELSE 0 END) TotalDebitAmount,
SUM(CASE WHEN GLJournalDetails.IsDebit=0 THEN GLJournalDetails.Amount_Amount ELSE 0 END) TotalCreditAmount
FROM
#ContractInfo C
JOIN GLJournalDetails ON C.ContractId = GLJournalDetails.EntityId AND GLJournalDetails.IsActive=1
JOIN GLTemplateDetails ON GLJournalDetails.GLTemplateDetailId = GLTemplateDetails.Id AND GLTemplateDetails.IsActive=1
JOIN GLEntryItems ON GLTemplateDetails.EntryItemId = GLEntryItems.Id AND GLEntryItems.Name IN('PropertyTaxEscrow','PPTEscrow')
LEFT JOIN GLTemplateDetails MatchingDetail ON GLJournalDetails.MatchingGLTemplateDetailId = MatchingDetail.Id
GROUP BY C.ContractId,GLTemplateDetails.GLTemplateId,MatchingDetail.GLTemplateId) AS PropertyTaxEscrowSummary
IF(@MovePLBalance=1)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'PropertyTaxEscrow',
GLTemplateId,
CASE WHEN EscrowDisposistion = 'WriteOff' THEN 'Expense' ELSE 'Income' END,
EscrowProcessAmount_Amount,
CASE WHEN EscrowDisposistion = 'WriteOff' THEN 1 ELSE 0 END
FROM
#ContractInfo C
JOIN PPTEscrowAssessments ON C.ContractId = PPTEscrowAssessments.ContractId AND PPTEscrowAssessments.EscrowDisposistion IN ('DoNotRefund','WriteOff')
AND PPTEscrowAssessments.Status = 'Approved' AND PPTEscrowAssessments.PostDate >= @PLEffectiveDate AND PPTEscrowAssessments.PostDate < @EffectiveDate
JOIN (SELECT ContractId,MAX(GLTemplateId) GLTemplateId
FROM(SELECT C.ContractId,ReceivableCodes.GLTemplateId FROM #ContractInfo C
JOIN Sundries ON C.ContractId = Sundries.ContractId AND Sundries.Type = 'PPTEscrow' AND Sundries.IsActive=1
JOIN ReceivableCodes ON Sundries.ReceivableCodeId = ReceivableCodes.Id
UNION SELECT C.ContractId,ReceivableCodes.GLTemplateId FROM #ContractInfo C
JOIN SundryRecurrings ON C.ContractId = SundryRecurrings.ContractId AND SundryRecurrings.Type = 'PPTEscrow' AND SundryRecurrings.IsActive=1
JOIN ReceivableCodes ON SundryRecurrings.ReceivableCodeId = ReceivableCodes.Id) AS GLTemplate GROUP BY ContractId)
AS PropertyTaxEscrowGLTemplate ON C.ContractId = PropertyTaxEscrowGLTemplate.ContractId
WHERE EscrowProcessAmount_Amount <> 0
CREATE TABLE #ReceivablesForPLTransfer(ContractId BIGINT,ReceivableId BIGINT,GLTransactionTypeName NVARCHAR(56),GLTemplateId BIGINT,ReceivableAmount DECIMAL(16,2),ReceivableBalance DECIMAL(16,2),AccountingTreatment NVARCHAR(24),IsGLPosted BIT,IsSyndicationActualProceeds BIT,IsFinancingComponent BIT);
INSERT INTO #ReceivablesForPLTransfer
SELECT ContractId,ReceivableId,GLTransactionTypeName,GLTemplateId,ReceivableAmount,ReceivableBalance,AccountingTreatment,IsGLPosted,IsSyndicationActualProceeds,IsFinancingComponent
FROM #ReceivableInfo
WHERE GLTransactionTypeName IN('NonRentalAR','PayoffBuyoutAR','AssetSaleAR') AND DueDate >= @PLEffectiveDate AND DueDate < @EffectiveDate
IF EXISTS(SELECT ContractId FROM #ReceivablesForPLTransfer WHERE GLTransactionTypeName = 'NonRentalAR')
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
ContractId,
'NonRentalAR',
GLTemplateId,
'NonRentalIncome',
SUM(AmountToPostGL),
0
FROM
(SELECT Receivables.ContractId,
Receivables.GLTemplateId,
CASE WHEN Receivables.AccountingTreatment = 'AccrualBased'
THEN CASE WHEN IsGLPosted=1 THEN ReceivableAmount - ISNULL(S.DeferredServicingFee,0) ELSE 0 - ISNULL(S.DeferredServicingFee,0) END
ELSE ISNULL(C.AmountPosted,0) - ISNULL(S.DeferredServicingFee,0)
END AS AmountToPostGL
FROM
(SELECT R.* FROM
(SELECT * FROM #ReceivablesForPLTransfer WHERE GLTransactionTypeName IN('NonRentalAR')) AS R
LEFT JOIN Sundries ON R.ReceivableId = Sundries.ReceivableId
LEFT JOIN BlendedItemDetails ON Sundries.Id = BlendedItemDetails.SundryId
WHERE BlendedItemDetails.BlendedItemId IS NULL) AS Receivables
LEFT JOIN #ReceivableAmountPostedInfo C ON Receivables.ReceivableId = C.ReceivableId
LEFT JOIN #DeferredServicingFee S ON Receivables.IsSyndicationActualProceeds=1 AND Receivables.ContractId = S.ContractId)
AS ReceivableInfo
GROUP BY ContractId,GLTemplateId
END
IF EXISTS(SELECT ContractId FROM #ReceivablesForPLTransfer WHERE GLTransactionTypeName = 'PayoffBuyoutAR' AND IsGLPosted=1)
BEGIN
---For Consolidated Revenue
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
ContractId,
'PayoffBuyoutAR',
GLTemplateId,
'Revenue',
SUM(ReceivableAmount),
0
FROM
#ReceivablesForPLTransfer
JOIN Receivables ON #ReceivablesForPLTransfer.ReceivableId = Receivables.Id
JOIN Payoffs ON Receivables.SourceId = Payoffs.Id AND Receivables.SourceTable = 'LeasePayoff'
WHERE GLTransactionTypeName = 'PayoffBuyoutAR' AND #ReceivablesForPLTransfer.IsGLPosted=1 AND Payoffs.IsGLConsolidated = 1
GROUP BY ContractId,GLTemplateId

 --- For non-consolidated LeaseComponent
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
ContractId,
'PayoffBuyoutAR',
GLTemplateId,
'Revenue',
SUM(ReceivableAmount),
0
FROM
#ReceivablesForPLTransfer
JOIN Receivables ON #ReceivablesForPLTransfer.ReceivableId = Receivables.Id
JOIN Payoffs ON Receivables.SourceId = Payoffs.Id AND Receivables.SourceTable = 'LeasePayoff'
WHERE GLTransactionTypeName = 'PayoffBuyoutAR' AND #ReceivablesForPLTransfer.IsGLPosted=1 AND Payoffs.IsGLConsolidated = 0 
AND #ReceivablesForPLTransfer.IsFinancingComponent = 0
GROUP BY ContractId,GLTemplateId

--- For non-consolidated NonLeaseComponent
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
ContractId,
'PayoffBuyoutAR',
GLTemplateId,
'FinancingRevenue',
SUM(ReceivableAmount),
0
FROM
#ReceivablesForPLTransfer
JOIN Receivables ON #ReceivablesForPLTransfer.ReceivableId = Receivables.Id
JOIN Payoffs ON Receivables.SourceId = Payoffs.Id AND Receivables.SourceTable = 'LeasePayoff'
WHERE GLTransactionTypeName = 'PayoffBuyoutAR' AND #ReceivablesForPLTransfer.IsGLPosted=1 AND Payoffs.IsGLConsolidated = 0 
AND #ReceivablesForPLTransfer.IsFinancingComponent = 1
GROUP BY ContractId,GLTemplateId
END

IF EXISTS(SELECT ContractId FROM #ReceivablesForPLTransfer WHERE GLTransactionTypeName = 'AssetSaleAR' AND IsGLPosted=1 AND AccountingTreatment = 'AccrualBased')
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
ContractId,
'AssetSaleAR',
GLTemplateId,
'SaleProceeds',
SUM(ReceivableAmount),
0
FROM
#ReceivablesForPLTransfer
WHERE GLTransactionTypeName = 'AssetSaleAR' AND IsGLPosted=1 AND AccountingTreatment = 'AccrualBased'
GROUP BY ContractId,GLTemplateId
END
IF EXISTS(SELECT ContractId FROM #ReceivablesForPLTransfer WHERE GLTransactionTypeName = 'AssetSaleAR' AND AccountingTreatment = 'CashBased')
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
ContractId,
'AssetSaleAR',
GLTemplateId,
'IncomeCashBasisContra',
SUM(Amount),
0
FROM
(SELECT ContractId,GLTemplateId,CASE WHEN IsGLPosted=1 THEN ReceivableAmount - ISNULL(R.AmountPosted,0) ELSE ISNULL(R.AmountPosted,0) * (-1) END AS Amount
FROM
(SELECT * FROM #ReceivablesForPLTransfer WHERE GLTransactionTypeName = 'AssetSaleAR' AND AccountingTreatment = 'CashBased') AS Receivables
JOIN #ReceivableAmountPostedInfo R ON Receivables.ReceivableId = R.ReceivableId) AS ReceivableInfo
GROUP BY ContractId,GLTemplateId
END
END
IF(@MovePLBalance=1)
BEGIN
IF EXISTS(SELECT ContractId FROM #ContractInfo ContractInfo WHERE ContractType IN('Lease','Loan') AND IsChargedoff=0)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'ValuationAllowance',
ValuationAllowances.GLTemplateId,
'ValuationExpense',
SUM(ValuationAllowances.Allowance_Amount),
1
FROM
(SELECT * FROM #ContractInfo ContractInfo WHERE ContractType IN('Lease','Loan') AND IsChargedoff=0) C
JOIN ValuationAllowances ON C.ContractId = ValuationAllowances.ContractId AND ValuationAllowances.IsActive=1
AND ValuationAllowances.PostDate >= @EffectiveDate AND ValuationAllowances.PostDate < @EffectiveDate
GROUP BY C.ContractId,ValuationAllowances.GLTemplateId
END
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
ContractId,
'ReceiptNonCash',
ReceiptGLTemplateId,
'Expense',
(TotalDebitAmount - TotalCreditAmount),
1
FROM
(SELECT Receipts.Id,
C.ContractId,
Receipts.ReceiptGLTemplateId,
SUM(CASE WHEN GLJournalDetails.IsDebit=1 THEN GLJournalDetails.Amount_Amount ELSE 0 END) TotalDebitAmount,
SUM(CASE WHEN GLJournalDetails.IsDebit=0 THEN GLJournalDetails.Amount_Amount ELSE 0 END) TotalCreditAmount
FROM
(SELECT * FROM #ContractInfo ContractInfo WHERE ContractType IN('Lease','Loan') AND IsChargedoff=0) C
JOIN Receipts ON C.ContractId = Receipts.ContractId AND Receipts.ReceiptClassification IN ('NonCash','NonAccrualNonDSLNonCash') AND Receipts.Status = 'Completed'
AND Receipts.PostDate >= @PLEffectiveDate AND Receipts.PostDate < @EffectiveDate AND Receipts.ReceiptAmount_Amount > 0
JOIN ReceiptGLJournals ON Receipts.Id = ReceiptGLJournals.ReceiptId
JOIN GLJournalDetails ON ReceiptGLJournals.GLJournalId = GLJournalDetails.GLJournalId AND GLJournalDetails.IsActive=1
JOIN GLTemplateDetails ON GLJournalDetails.GLTemplateDetailId = GLTemplateDetails.Id AND GLTemplateDetails.IsActive=1
JOIN GLEntryItems ON GLTemplateDetails.EntryItemId = GLEntryItems.Id AND GLEntryItems.Name = 'Expense'
JOIN GLTransactionTypes ON GLEntryItems.GLTransactionTypeId = GLTransactionTypes.Id AND GLTransactionTypes.Name = 'ReceiptNonCash'
GROUP BY C.ContractId,Receipts.Id,Receipts.ReceiptGLTemplateId) AS NonCashReceiptInfo
END
--- Process TaxDepEntities
IF(@UseTaxBooks = 1)
BEGIN
CREATE TABLE #TaxLeases
(
ContractId BIGINT,
CurrencyId BIGINT,
TaxDepExpenseGLTemplateId BIGINT,
TaxAssetSetupGLTemplateId BIGINT,
SyndicationEffectiveDate DATE,
RetainedPercentage DECIMAL(18,8)
);
INSERT INTO #TaxLeases
SELECT C.ContractId,C.CurrencyId,LeaseFinanceDetails.TaxDepExpenseGLTemplateId,LeaseFinanceDetails.TaxAssetSetupGLTemplateId,RFT.EffectiveDate,ISNULL(RFT.RetainedPercentage,1)
FROM (SELECT * FROM #ContractInfo ContractInfo WHERE ContractType = 'Lease') AS C
JOIN LeaseFinances ON C.ContractId = LeaseFinances.ContractId AND LeaseFinances.IsCurrent=1
JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
LEFT JOIN #ReceivableForTransfers RFT on C.ContractId = RFT.ContractId
WHERE LeaseFinanceDetails.IsTaxLease=1
IF EXISTS(SELECT ContractId FROM #TaxLeases)
BEGIN
CREATE TABLE #TaxDepMaximumGLPostedInfo
(
ContractId BIGINT,
CurrencyId BIGINT,
AssetId BIGINT,
MaxGLPostedDepDate DATE
);
INSERT INTO #TaxDepMaximumGLPostedInfo
select
C.ContractId,
C.CurrencyId,
TDE.AssetId,
MAX(TDAD.DepreciationDate)
FROM #TaxLeases C
JOIN TaxDepEntities TDE ON C.ContractId = TDE.ContractId AND TDE.IsActive = 1
JOIN TaxDepAmortizations TDA ON TDE.Id = TDA.TaxDepEntityId AND TDA.IsActive = 1
JOIN TaxDepAmortizationDetails TDAD ON TDA.Id = TDAD.TaxDepAmortizationId AND TDAD.IsAccounting = 1
JOIN TaxDepTemplateDetails TDTD on TDAD.TaxDepreciationTemplateDetailId = TDTD.Id AND TDTD.TaxBook = 'Federal'
WHERE
TDE.AssetId IS NOT NULL
AND TDAD.IsGLPosted =1
AND TDAD.IsAdjustmentEntry = 0
AND TDAD.DepreciationDate < @EffectiveDate
GROUP BY C.ContractId,C.CurrencyId,TDE.AssetId
IF EXISTS(SELECT ContractId FROM #TaxDepMaximumGLPostedInfo)
BEGIN
CREATE TABLE #TaxDepreciationGLInfo
(
ContractId BIGINT,
DepreciationAmount DECIMAL(16,2),
DepreciationDate DATE
);
INSERT INTO #TaxDepreciationGLInfo
SELECT C.ContractId,
SUM(TDAD.DepreciationAmount_Amount) DepreciationAmount,
TDAD.DepreciationDate DepreciationDate
FROM #TaxDepMaximumGLPostedInfo C
JOIN TaxDepEntities TDE on C.ContractId = TDE.ContractId AND C.AssetId = TDE.AssetId AND TDE.IsActive = 1
JOIN TaxDepAmortizations TDA on TDE.Id = TDA.TaxDepEntityId AND TDA.IsActive = 1
JOIN TaxDepAmortizationDetails TDAD on TDA.Id = TDAD.TaxDepAmortizationId AND TDAD.IsSchedule =1 AND TDAD.CurrencyId = C.CurrencyId
JOIN TaxDepTemplateDetails TDTD on TDAD.TaxDepreciationTemplateDetailId = TDTD.Id AND TDTD.TaxBook = 'Federal'
WHERE TDAD.DepreciationDate < @EffectiveDate AND TDAD.DepreciationDate <= C.MaxGLPostedDepDate
AND (TDE.TerminationDate IS NULL OR TDE.IsComputationPending = 1)
GROUP BY C.ContractId, TDAD.DepreciationDate
IF EXISTS(SELECT ContractId FROM #TaxDepreciationGLInfo)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
TaxDepEntity.ContractId,
'TaxDepreciation',
Lease.TaxDepExpenseGLTemplateId,
'TaxAccumulatedDepreciation',
Sum(TaxDepEntity.DepreciationAmount),
0
FROM #TaxDepreciationGLInfo TaxDepEntity
JOIN #TaxLeases Lease ON TaxDepEntity.ContractId = Lease.ContractId
GROUP BY Lease.TaxDepExpenseGLTemplateId,TaxDepEntity.ContractId
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
TaxDepEntity.ContractId,
'TaxDepreciation',
Lease.TaxDepExpenseGLTemplateId,
'TaxAccumulatedDepreciationContra',
Sum(TaxDepEntity.DepreciationAmount),
1
FROM #TaxDepreciationGLInfo TaxDepEntity
JOIN #TaxLeases Lease ON TaxDepEntity.ContractId = Lease.ContractId
GROUP BY Lease.TaxDepExpenseGLTemplateId,TaxDepEntity.ContractId
IF(@MovePLBalance=1)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
TaxDepEntity.ContractId,
'TaxDepreciation',
Lease.TaxDepExpenseGLTemplateId,
'TaxDepreciationExpense',
Sum(TaxDepEntity.DepreciationAmount),
1
FROM #TaxDepreciationGLInfo TaxDepEntity
JOIN #TaxLeases Lease ON TaxDepEntity.ContractId = Lease.ContractId
WHERE TaxDepEntity.DepreciationDate >= @PLEffectiveDate
GROUP BY Lease.TaxDepExpenseGLTemplateId,TaxDepEntity.ContractId
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
TaxDepEntity.ContractId,
'TaxDepreciation',
Lease.TaxDepExpenseGLTemplateId,
'TaxDepreciationExpenseContra',
Sum(TaxDepEntity.DepreciationAmount),
0
FROM #TaxDepreciationGLInfo TaxDepEntity
JOIN #TaxLeases Lease ON TaxDepEntity.ContractId = Lease.ContractId
WHERE TaxDepEntity.DepreciationDate >= @PLEffectiveDate
GROUP BY Lease.TaxDepExpenseGLTemplateId,TaxDepEntity.ContractId
END
END
END
CREATE TABLE #TaxDepSetupGLInfo
(
ContractId BIGINT,
DepreciationAmount DECIMAL(16,2)
);
INSERT INTO #TaxDepSetupGLInfo
SELECT
C.ContractId,
CASE WHEN C.SyndicationEffectiveDate <= TDE.DepreciationBeginDate
THEN TDAD.BeginNetBookValue_Amount
ELSE ROUND((TDAD.BeginNetBookValue_Amount * C.RetainedPercentage),2)
END AS DepreciationAmount
FROM #TaxLeases C
JOIN TaxDepEntities TDE on C.ContractId = TDE.ContractId AND TDE.IsActive = 1
JOIN TaxDepAmortizations TDA on TDE.Id = TDA.TaxDepEntityId AND TDA.IsActive = 1
JOIN TaxDepAmortizationDetails TDAD on TDA.Id = TDAD.TaxDepAmortizationId AND TDAD.IsSchedule = 1 AND TDAD.CurrencyId = C.CurrencyId
JOIN TaxDepTemplateDetails TDTD on TDAD.TaxDepreciationTemplateDetailId = TDTD.Id AND TDTD.TaxBook = 'Federal'
WHERE TDE.IsGLPosted = 1
AND TDE.AssetId IS NOT NULL
AND (TDE.TerminationDate IS NULL OR TDE.IsComputationPending = 1)
AND TDE.DepreciationBeginDate < @EffectiveDate
AND TDAD.DepreciationDate = EOMONTH(TDE.DepreciationBeginDate)
AND TDAD.IsSchedule = 1
IF EXISTS(SELECT ContractId FROM #TaxDepSetupGLInfo)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
TaxDepEntity.ContractId,
'TaxAssetSetup',
Lease.TaxAssetSetupGLTemplateId,
'TaxFixedAsset',
Sum(TaxDepEntity.DepreciationAmount),
1
FROM #TaxDepSetupGLInfo TaxDepEntity
JOIN #TaxLeases Lease ON TaxDepEntity.ContractId = Lease.ContractId
GROUP BY Lease.TaxAssetSetupGLTemplateId,TaxDepEntity.ContractId
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
TaxDepEntity.ContractId,
'TaxAssetSetup',
Lease.TaxAssetSetupGLTemplateId,
'TaxFixedAssetOffset',
Sum(TaxDepEntity.DepreciationAmount),
0
FROM #TaxDepSetupGLInfo TaxDepEntity
JOIN #TaxLeases Lease ON TaxDepEntity.ContractId = Lease.ContractId
GROUP BY Lease.TaxAssetSetupGLTemplateId,TaxDepEntity.ContractId
END
END
END
IF(@IsGLTransferFromReAccrual = 1)
BEGIN
IF EXISTS(SELECT ContractId FROM #BlendedItemInfo)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit,MatchingGLTemplateId)
SELECT B.ContractId
, #ReAccrualBlendedItemGLInfo.IncomeGLTransactionType   GLTransactionType
, #ReAccrualBlendedItemGLInfo.IncomeGLTemplateId  GLTemplateId
, #ReAccrualBlendedItemGLInfo.CreditEntryItem  GLEntryItem
, BlendedItemDetails.Amount 
, 0 IsDebit
,NULL
FROM (SELECT * FROM #BlendedItemInfo WHERE BookRecognitionMode = 'RecognizeImmediately' AND Type='Income') as B
JOIN (SELECT B.BlendedItemId,SUM(BlendedItemDetails.Amount_Amount) Amount
FROM #BlendedItemInfo B
JOIN BlendedItemDetails ON B.BlendedItemId = BlendedItemDetails.BlendedItemId AND BlendedItemDetails.IsActive=1
JOIN (SELECT ContractId,MAX(NonAccrualDate) as NonAccrualDate from NonAccrualContracts GROUP BY ContractId) as NonAccrualDateInfo
on NonAccrualDateInfo.ContractId = B.ContractId
WHERE BlendedItemDetails.IsGLPosted = 1
AND BlendedItemDetails.DueDate > NonAccrualDateInfo.NonAccrualDate AND BlendedItemDetails.DueDate <= @EffectiveDate
GROUP BY B.BlendedItemId)
AS BlendedItemDetails ON B.BlendedItemId = BlendedItemDetails.BlendedItemId
JOIN #ReAccrualBlendedItemGLInfo ON B.BlendedItemId = #ReAccrualBlendedItemGLInfo.BlendedItemId
WHERE BlendedItemDetails.Amount <> 0

IF EXISTS(SELECT ContractId FROM #BlendedItemInfo WHERE BookRecognitionMode <> 'RecognizeImmediately' AND IsReamortizationRecoveryMethod = 0)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit,MatchingGLTemplateId)
SELECT B.ContractId
, CASE WHEN B.Type='Income'
  THEN 'BlendedIncomeRecognition'
  ELSE 'BlendedExpenseRecognition' END GLTransactionType
, B.RecognitionGLTemplateId GLTemplateId
, CASE WHEN B.Type='Income'
  THEN 'BlendedIncome'
  ELSE 'BlendedExpense' END GLEntryItem
, ReaccrualCatchUpInfo.CatchupAmount Amount
, CASE WHEN B.Type='Income' THEN 1 ELSE 0 END IsDebit
,NULL
FROM (SELECT * FROM #BlendedItemInfo WHERE BookRecognitionMode <> 'RecognizeImmediately' AND IsReamortizationRecoveryMethod = 0) as B
JOIN 
(SELECT #ReAccrualCatchupInfo.ContractId, BlendedItemId, SUM(CatchupAmount) CatchupAmount FROM #ReAccrualCatchupInfo
JOIN #ReAccrualDateInfo ON #ReAccrualCatchupInfo.ContractId = #ReAccrualDateInfo.ContractId 
WHERE IncomeDate <= @EffectiveDate 
AND #ReAccrualCatchupInfo.IncomeDate >= #ReAccrualDateInfo.NonAccrualDate
 GROUP BY #ReAccrualCatchupInfo.ContractId, BlendedItemId) AS ReaccrualCatchUpInfo
ON B.ContractId = ReaccrualCatchUpInfo.ContractId AND B.BlendedItemId = ReaccrualCatchUpInfo.BlendedItemId
END
END
IF EXISTS(SELECT ContractId FROM #LeaseContracts C WHERE IsFloatRateLease=1)
BEGIN
UPDATE #AccruedIncomeBalanceSummary
SET FloatInterestIncome = LeaseIncome.FloatRateIncome
FROM #AccruedIncomeBalanceSummary
JOIN #LeaseContracts C ON #AccruedIncomeBalanceSummary.ContractId = C.ContractId
JOIN(SELECT FloatRateIncomeInfo.ContractId,SUM(FloatRateIncome) FloatRateIncome
FROM #FloatRateIncomeInfoForGLTransfer	FloatRateIncomeInfo
JOIN(SELECT ContractId,MAX(NonAccrualDate) as NonAccrualDate from NonAccrualContracts GROUP BY ContractId) as NonAccrualDateInfo
on NonAccrualDateInfo.ContractId = FloatRateIncomeInfo.ContractId
WHERE IsNonAccrual=1 AND IncomeDate > NonAccrualDateInfo.NonAccrualDate AND IncomeDate <= @EffectiveDate
GROUP BY FloatRateIncomeInfo.ContractId)
AS LeaseIncome ON C.ContractId = LeaseIncome.ContractId
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
C.ContractId,
'FloatIncome',
LeaseFinanceDetails.FloatIncomeGLTemplateId,
'FloatInterestIncome',
#AccruedIncomeBalanceSummary.FloatInterestIncome,
0
FROM (SELECT * FROM #LeaseContracts  WHERE IsFloatRateLease=1) C
JOIN LeaseFinanceDetails ON C.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN #AccruedIncomeBalanceSummary ON C.ContractId = #AccruedIncomeBalanceSummary.ContractId
WHERE #AccruedIncomeBalanceSummary.FloatInterestIncome <> 0
END
END
IF(@MovePLBalance=1)
BEGIN
INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
AdditionalChargesEntity.ContractId,
'AdditionalCapitalizedCharges',
AdditionalChargesEntity.GLTemplateId,
'CapitalizedAdditionalFeeIncome',
AdditionalChargesEntity.Amount,
0
FROM   (SELECT ContractInfo.ContractId as ContractId,AdditionalCharges.GLTemplateId as GLTemplateId, AdditionalCharges.Amount_Amount as Amount
FROM #ContractInfo ContractInfo
JOIN #LeaseContracts LeaseContracts ON ContractInfo.ContractId=LeaseContracts.ContractId
JOIN LeaseFinanceAdditionalCharges ON LeaseContracts.LeaseFinanceId = LeaseFinanceAdditionalCharges.LeaseFinanceId
JOIN AdditionalCharges ON AdditionalCharges.Id = LeaseFinanceAdditionalCharges.AdditionalChargeId
WHERE LeaseContracts.CommencementDate = @PLEffectiveDate
AND AdditionalCharges.Amount_Amount <> 0
AND AdditionalCharges.Capitalize!=0
AND AdditionalCharges.IsActive = 1
GROUP BY ContractInfo.ContractId,AdditionalCharges.GLTemplateId,AdditionalCharges.Amount_Amount
UNION
SELECT ContractInfo.ContractId as ContractId,AdditionalCharges.GLTemplateId as GLTemplateId, AdditionalCharges.Amount_Amount as Amount
FROM #ContractInfo ContractInfo
JOIN #LoanContracts LoanContracts ON ContractInfo.ContractId = LoanContracts.ContractId
JOIN LoanFinanceAdditionalCharges ON LoanContracts.LoanFinanceId = LoanFinanceAdditionalCharges.LoanFinanceId
JOIN AdditionalCharges ON AdditionalCharges.Id = LoanFinanceAdditionalCharges.AdditionalChargeId
WHERE LoanContracts.CommencementDate =@PLEffectiveDate
AND AdditionalCharges.Amount_Amount <> 0
AND AdditionalCharges.Capitalize!=0
AND AdditionalCharges.IsActive=1
GROUP BY ContractInfo.ContractId,AdditionalCharges.GLTemplateId,AdditionalCharges.Amount_Amount
) as  AdditionalChargesEntity
END
IF(@MovePLBalance=1)
BEGIN
	CREATE TABLE #UpfrontLossOnLease (ContractId BIGINT, UpfrontLossOnLeaseAmount DECIMAL(16,2), LeaseBookingGLTemplateId BIGINT)

              INSERT INTO #UpfrontLossOnLease
			  --Considering only the lease booking finance objects
			  SELECT ContractId, UpfrontLossOnLease_Amount, LeaseBookingGLTemplateId 
			  FROM  (
			  SELECT LF.ContractId ,LA.UpfrontLossOnLease_Amount, LFD.LeaseBookingGLTemplateId,
			  ROW_NUMBER() over(partition by LF.ContractId order by LF.Id) as rownum 
			  from Contracts C 
			  INNER JOIN LeaseFinances LF ON C.Id = LF.ContractId
              INNER JOIN LeaseFinanceDetails LFD ON LFD.Id = LF.Id
			  INNER JOIN LeaseAssets LA ON LF.Id = LA.LeaseFinanceId
              WHERE @PLEffectiveDate >= LFD.CommencementDate 
			  AND @EffectiveDate >= LFD.CommencementDate 
			  AND @PLEffectiveDate < LFD.MaturityDate AND @EffectiveDate < LFD.MaturityDate 
              AND LA.UpfrontLossOnLease_Amount > 0 AND LFD.LeaseContractType in ('ConditionalSales','SalesType','DirectFinance') 
              AND C.ContractType ='Lease' AND C.AccountingStandard = 'ASC842' 			   
			  ) LeaseBooking where rownum = 1
			  UNION
			  --Considering only the lease amendments finance object(s)
			  SELECT LF.ContractId,SUM(LA.UpfrontLossOnLease_Amount), LFD.LeaseBookingGLTemplateId
              from Contracts C 
			  INNER JOIN LeaseFinances LF ON C.Id = LF.ContractId
              INNER JOIN LeaseFinanceDetails LFD ON LFD.Id = LF.Id
			  INNER JOIN LeaseAssets LA ON LF.Id = LA.LeaseFinanceId
              INNER JOIN LeaseAmendments LAM ON LF.Id = LAM.CurrentLeaseFinanceId
              WHERE (
			  (LAM.AmendmentType IN ( 'Rebook' , 'Renewal') AND @PLEffectiveDate >= LFD.CommencementDate 
			  AND @EffectiveDate >= LFD.CommencementDate AND @PLEffectiveDate < LFD.MaturityDate AND @EffectiveDate < LFD.MaturityDate)
              OR 
              (LAM.AmendmentType in ('Payoff','Restructure') AND LAM.AmendmentDate BETWEEN @PLEffectiveDate AND @EffectiveDate)
              )
              AND LA.UpfrontLossOnLease_Amount > 0 AND LFD.LeaseContractType in ('ConditionalSales','SalesType','DirectFinance') 
              AND C.ContractType ='Lease' AND C.AccountingStandard = 'ASC842' 
              GROUP BY LF.ContractId, LFD.LeaseBookingGLTemplateId              


			  IF EXISTS(SELECT ContractId FROM #UpfrontLossOnLease)
			  BEGIN
				INSERT INTO #GLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)  
				SELECT ContractId, 'CapitalLeaseBooking', LeaseBookingGLTemplateId, 'UpfrontLossOnLease', SUM(UpfrontLossOnLeaseAmount), 1  
				FROM  #UpfrontLossOnLease
				Group By ContractId, LeaseBookingGLTemplateId
			  END
END

SELECT
*
FROM #GLSummary
IF OBJECT_ID('tempdb..#GLSummary') IS NOT NULL
DROP TABLE #GLSummary
IF OBJECT_ID('tempdb..#ReceivableForTransfers') IS NOT NULL
DROP TABLE #ReceivableForTransfers
IF OBJECT_ID('tempdb..#ContractInfo') IS NOT NULL
DROP TABLE #ContractInfo
IF OBJECT_ID('tempdb..#DeferredServicingFee') IS NOT NULL
DROP TABLE #DeferredServicingFee
IF OBJECT_ID('tempdb..#FAS91ReceivableIds') IS NOT NULL
DROP TABLE #FAS91ReceivableIds
IF OBJECT_ID('tempdb..#BlendedItemInfo') IS NOT NULL
DROP TABLE #BlendedItemInfo
IF OBJECT_ID('tempdb..#ChargeOffInfo') IS NOT NULL
DROP TABLE #ChargeOffInfo
IF OBJECT_ID('tempdb..#ChargeoffRecoveryInfo') IS NOT NULL
DROP TABLE #ChargeoffRecoveryInfo
IF OBJECT_ID('tempdb..#TakeDownInfo') IS NOT NULL
DROP TABLE #TakeDownInfo
IF OBJECT_ID('tempdb..#PPCOtherCostIds') IS NOT NULL
DROP TABLE #PPCOtherCostIds
IF OBJECT_ID('tempdb..#ProgressLoanTakeDownInfo') IS NOT NULL
DROP TABLE #ProgressLoanTakeDownInfo
IF OBJECT_ID('tempdb..#RemainingBalanceInAccruedInterest') IS NOT NULL
DROP TABLE #RemainingBalanceInAccruedInterest
IF OBJECT_ID('tempdb..#GLPostedProgressLoanIncomeSchedules') IS NOT NULL
DROP TABLE #GLPostedProgressLoanIncomeSchedules
IF OBJECT_ID('tempdb..#ProgressLoanContracts') IS NOT NULL
DROP TABLE #ProgressLoanContracts
IF OBJECT_ID('tempdb..#GLPostedLoanIncomeSchedules') IS NOT NULL
DROP TABLE #GLPostedLoanIncomeSchedules
IF OBJECT_ID('tempdb..#DRPaidInfo') IS NOT NULL
DROP TABLE #DRPaidInfo
IF OBJECT_ID('tempdb..#LoanNoteReceivableSetupAmount') IS NOT NULL
DROP TABLE #LoanNoteReceivableSetupAmount
IF OBJECT_ID('tempdb..#OriginationFundingAmountInfo') IS NOT NULL
DROP TABLE #OriginationFundingAmountInfo
IF OBJECT_ID('tempdb..#AccruedInterestCapitalizedInfo') IS NOT NULL
DROP TABLE #AccruedInterestCapitalizedInfo
IF OBJECT_ID('tempdb..#NonGLPostedInvestmentPayables') IS NOT NULL
DROP TABLE #NonGLPostedInvestmentPayables
IF OBJECT_ID('tempdb..#ClearedAmounts') IS NOT NULL
DROP TABLE #ClearedAmounts
IF OBJECT_ID('tempdb..#GLPostedLoanReceivables') IS NOT NULL
DROP TABLE #GLPostedLoanReceivables
IF OBJECT_ID('tempdb..#RemainingBalanceInfo') IS NOT NULL
DROP TABLE #RemainingBalanceInfo
IF OBJECT_ID('tempdb..#LoanContracts') IS NOT NULL
DROP TABLE #LoanContracts
IF OBJECT_ID('tempdb..#PayoffSummary') IS NOT NULL
DROP TABLE #PayoffSummary
IF OBJECT_ID('tempdb..#ContractSyndicationServiced') IS NOT NULL
DROP TABLE #ContractSyndicationServiced
IF OBJECT_ID('tempdb..#LeaseInvestmentInfo') IS NOT NULL
DROP TABLE #LeaseInvestmentInfo
IF OBJECT_ID('tempdb..#AccruedIncomeBalanceSummary') IS NOT NULL
DROP TABLE #AccruedIncomeBalanceSummary
IF OBJECT_ID('tempdb..#LeaseRentalReceivables') IS NOT NULL
DROP TABLE #LeaseRentalReceivables
IF OBJECT_ID('tempdb..#LeaseIncomeScheduleInfoForGLTransfer') IS NOT NULL
DROP TABLE #LeaseIncomeScheduleInfoForGLTransfer
IF OBJECT_ID('tempdb..#FloatRateIncomeInfoForGLTransfer') IS NOT NULL
DROP TABLE #FloatRateIncomeInfoForGLTransfer
IF OBJECT_ID('tempdb..#CashPostedCashBasedReceivableInfo') IS NOT NULL
DROP TABLE #CashPostedCashBasedReceivableInfo
IF OBJECT_ID('tempdb..#AccumulatedDepreciationInfo') IS NOT NULL
DROP TABLE #AccumulatedDepreciationInfo
IF OBJECT_ID('tempdb..#AssetValueHistorySummary') IS NOT NULL
DROP TABLE #AssetValueHistorySummary
IF OBJECT_ID('tempdb..#LeaseContracts') IS NOT NULL
DROP TABLE #LeaseContracts
IF OBJECT_ID('tempdb..#LeveragedLeaseInfo') IS NOT NULL
DROP TABLE #LeveragedLeaseInfo
IF OBJECT_ID('tempdb..#LeveragedLeaseBalanceSummary') IS NOT NULL
DROP TABLE #LeveragedLeaseBalanceSummary
IF OBJECT_ID('tempdb..#LeveragedLeaseContracts') IS NOT NULL
DROP TABLE #LeveragedLeaseContracts
IF OBJECT_ID('tempdb..#SecurityDepositInfo') IS NOT NULL
DROP TABLE #SecurityDepositInfo
IF OBJECT_ID('tempdb..#WriteDownInfo') IS NOT NULL
DROP TABLE #WriteDownInfo
IF OBJECT_ID('tempdb..#ReceivablesForPLTransfer') IS NOT NULL
DROP TABLE #ReceivablesForPLTransfer
IF OBJECT_ID('tempdb..#ReceivableInfo') IS NOT NULL
DROP TABLE #ReceivableInfo
IF OBJECT_ID('tempdb..#ReceivableAmountPostedInfo') IS NOT NULL
DROP TABLE #ReceivableAmountPostedInfo
IF OBJECT_ID('tempdb..#BlendedItemSundryInfo') IS NOT NULL
DROP TABLE #BlendedItemSundryInfo
IF OBJECT_ID('tempdb..#BlendedIncomeSchedules') IS NOT NULL
DROP TABLE #BlendedIncomeSchedules
IF OBJECT_ID('tempdb..#BlendedItemAdjustmentInfo') IS NOT NULL
DROP TABLE #BlendedItemAdjustmentInfo
IF OBJECT_ID('tempdb..#BlendedItemGLInfo') IS NOT NULL
DROP TABLE #BlendedItemGLInfo
IF OBJECT_ID('tempdb..#ReAccrualBlendedItemGLInfo') IS NOT NULL
DROP TABLE #ReAccrualBlendedItemGLInfo
IF OBJECT_ID('tempdb..#BlendedItemInfo') IS NOT NULL
DROP TABLE #BlendedItemInfo
IF OBJECT_ID('tempdb..#ChargeOffBlendedItemInfo') IS NOT NULL
DROP TABLE #ChargeOffBlendedItemInfo
IF OBJECT_ID('temp..#TaxDepSetupGLInfo') IS NOT NULL
DROP TABLE #TaxDepSetupGLInfo
IF OBJECT_ID('temp..#TaxLeases') IS NOT NULL
DROP TABLE #TaxLeases
IF OBJECT_ID('temp..#TaxDepreciationGLInfo') IS NOT NULL
DROP TABLE #TaxDepreciationGLInfo
IF OBJECT_ID('temp..#TaxDepMaximumGLPostedInfo') IS NOT NULL
DROP TABLE #TaxDepMaximumGLPostedInfo
IF OBJECT_ID('temp..#ReAccrualDateInfo') IS NOT NULL
DROP TABLE #ReAccrualDateInfo
IF OBJECT_ID('temp..#ReAccrualCatchupInfo') IS NOT NULL
DROP TABLE #ReAccrualCatchupInfo
IF OBJECT_ID('tempdb..#LeaseAssetSKUInfo') IS NOT NULL
DROP TABLE #LeaseAssetSKUInfo
IF OBJECT_ID('tempdb..#ReceivableDetailInfo') IS NOT NULL
DROP TABLE #ReceivableDetailInfo
IF OBJECT_ID('tempdb..#LeaseAssetInfo') IS NOT NULL
DROP TABLE #LeaseAssetInfo
IF OBJECT_ID('tempdb..#CapitalizedLeaseAssetInfo') IS NOT NULL
DROP TABLE #CapitalizedLeaseAssetInfo
IF OBJECT_ID('temp..#BlendedItemHierarchy') IS NOT NULL
DROP TABLE #BlendedItemHierarchy
IF OBJECT_ID('temp..#ChargeOffBlendedIncomeInfo') IS NOT NULL
DROP TABLE #ChargeOffBlendedIncomeInfo
IF OBJECT_ID('temp..#UpfrontLossOnLease') IS NOT NULL  
DROP TABLE #UpfrontLossOnLease
SET NOCOUNT OFF;
END

GO

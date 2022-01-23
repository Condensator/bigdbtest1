SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ProcessBlendedItemsForGLTransfer]
(
@EffectiveDate DATE,
@MovePLBalance BIT,
@PLEffectiveDate DATE = NULL,
@BlendedItems BlendedItemInfoForGLTransfer READONLY
)
AS
BEGIN
SET NOCOUNT ON;
CREATE TABLE #BlendedItemGLSummary
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
EntityType NVARCHAR(11)
);
INSERT INTO #BlendedItemInfo
SELECT
B.ContractId,
B.BlendedItemId,
BlendedItem.BookRecognitionMode,
BlendedItem.BookingGLTemplateId,
BlendedItem.RecognitionGLTemplateId,
BlendedItem.AccumulateExpense,
BlendedItem.Type,
BlendedItem.GeneratePayableOrReceivable,
BlendedItem.Amount_Amount,
BlendedItem.SystemConfigType,
BlendedItem.IsFAS91,
Contracts.IsNonAccrual,
B.IsChargedOffContract,
Contracts.ContractType,
B.IncomeGLPostedTillDate,
BlendedItem.EntityType
FROM @BlendedItems B
JOIN BlendedItems BlendedItem ON B.BlendedItemId = BlendedItem.Id
JOIN Contracts ON B.ContractId = Contracts.Id
CREATE TABLE #ReAccrualBlendedItemGLInfo
(
BlendedItemId BIGINT,
ContractId BIGINT,
BookingGLTemplateId BIGINT,
IncomeGLTemplateId BIGINT,
ARGLTemplateId BIGINT,
GLTransactionType NVARCHAR(56),
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
IsNonAccrual BIT,
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
IF EXISTS(SELECT ContractId FROM #BlendedItemInfo WHERE ContractType = 'Lease')
BEGIN
INSERT INTO #ReAccrualBlendedItemGLInfo
SELECT
BlendedItems.BlendedItemId,
LeaseFinances.ContractId,
LeaseFinanceDetails.LeaseBookingGLTemplateId,
LeaseFinanceDetails.LeaseIncomeGLTemplateId,
ReceivableCodes.GLTemplateId ARGLTemplateId,
CASE WHEN LeaseContractType = 'Operating' THEN 'OperatingLeaseIncome' ELSE 'CapitalLeaseIncome' END AS GLTransactionType,
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
FROM (SELECT * FROM #BlendedItemInfo WHERE ContractType = 'Lease') BlendedItems
JOIN LeaseBlendedItems ON BlendedItems.BlendedItemId = LeaseBlendedItems.BlendedItemId
JOIN LeaseFinances ON LeaseBlendedItems.LeaseFinanceId = LeaseFinances.Id AND LeaseFinances.IsCurrent = 1
JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
JOIN ReceivableCodes ON LeaseFinanceDetails.FixedTermReceivableCodeId = ReceivableCodes.Id
WHERE BlendedItems.ContractType = 'Lease'
AND BlendedItems.SystemConfigType IN ('ReAccrualIncome','ReAccrualRentalIncome','ReAccrualResidualIncome',
'ReAccrualFinanceIncome','ReAccrualFinanceResidualIncome','ReAccrualDeferredSellingProfitIncome')
AND BlendedItems.ContractId = LeaseFinances.ContractId
INSERT INTO #BlendedItemAdjustmentInfo
SELECT B.ContractId
,B.BlendedItemId
,Payoffs.PayoffEffectiveDate
,CASE WHEN B.AccumulateExpense = 1 THEN PayoffBlendedItems.AccumulatedAdjustment_Amount ELSE PayoffBlendedItems.PayoffAdjustment_Amount END
,PayoffBlendedItems.PayoffAdjustment_Amount
FROM (SELECT * FROM #BlendedItemInfo WHERE ContractType = 'Lease') B
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
JOIN BlendedIncomeSchedules ON B.BlendedItemId = BlendedIncomeSchedules.BlendedItemId AND BlendedIncomeSchedules.IsAccounting=1 AND
BlendedIncomeSchedules.PostDate IS NOT NULL AND BlendedIncomeSchedules.IncomeDate <= B.IncomeGLPostedTillDate
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
LoanFinances.LoanBookingGLTemplateId,
LoanFinances.LoanIncomeRecognitionGLTemplateId,
NULL,
'LoanIncomeRecognition',
'AccruedInterest',
'InterestIncome',
'SuspendedIncome'
FROM (SELECT * FROM #BlendedItemInfo WHERE ContractType <> 'Lease') AS BlendedItems
JOIN LoanBlendedItems ON BlendedItems.BlendedItemId = LoanBlendedItems.BlendedItemId
JOIN LoanFinances ON LoanBlendedItems.LoanFinanceId = LoanFinances.Id AND LoanFinances.IsCurrent = 1
WHERE BlendedItems.ContractType <> 'Lease'
AND BlendedItems.SystemConfigType IN ('ReAccrualIncome')
AND BlendedItems.ContractId = LoanFinances.ContractId
INSERT INTO #BlendedItemAdjustmentInfo
SELECT B.ContractId
,B.BlendedItemId
,LoanPaydowns.PaydownDate
,CASE WHEN B.AccumulateExpense = 1 THEN LoanPaydownBlendedItems.AccumulatedAdjustment_Amount ELSE LoanPaydownBlendedItems.PaydownCostAdjustment_Amount END
,LoanPaydownBlendedItems.PaydownCostAdjustment_Amount
FROM (SELECT * FROM #BlendedItemInfo WHERE ContractType <> 'Lease') B
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
JOIN BlendedIncomeSchedules ON B.BlendedItemId = BlendedIncomeSchedules.BlendedItemId AND BlendedIncomeSchedules.IsAccounting=1 AND
BlendedIncomeSchedules.PostDate IS NOT NULL AND BlendedIncomeSchedules.IncomeDate <= B.IncomeGLPostedTillDate
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
IF EXISTS(SELECT ContractId FROM #BlendedItemInfo WHERE BookRecognitionMode <> 'RecognizeImmediately' AND (IsChargedOffContract = 0 OR IsFAS91=0))
BEGIN
INSERT INTO #BlendedItemGLInfo
SELECT BlendedItem.ContractId
,BlendedItem.BlendedItemId
,CASE WHEN BlendedItem.EntityType = 'Syndication'
THEN BlendedItem.Amount - ISNULL(BlendedIncome.IncomeRecognizedTillDate,0) - ISNULL(ClearedUnamortizedAmountInfo.AmountClearedFromUnAmortizedExpense,0)
ELSE ISNULL(GLPostedBlendedItemDetail.Amount,0) - ISNULL(BlendedIncome.IncomeRecognizedTillDate,0) - ISNULL(ClearedUnamortizedAmountInfo.AmountClearedFromUnAmortizedExpense,0)
END AS RemainingBalance
,CASE WHEN (BlendedItem.Type <> 'Income' AND BlendedItem.BookRecognitionMode = 'Amortize' AND BlendedItem.AccumulateExpense = 1)
THEN ISNULL(GLPostedBlendedItemDetail.Amount,0)-ISNULL(ClearedUnamortizedAmountInfo.AmountClearedFromUnAmortizedExpense,0)
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
END
INSERT INTO #BlendedItemGLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit,MatchingGLTemplateId)
SELECT BlendedItem.ContractId
,CASE WHEN BlendedItem.Type = 'Income'
THEN CASE WHEN #ReAccrualBlendedItemGLInfo.BlendedItemId IS NOT NULL THEN #ReAccrualBlendedItemGLInfo.GLTransactionType ELSE 'BlendedIncomeSetup' END
ELSE 'BlendedExpenseSetup' END GLTransactionType
,CASE WHEN #ReAccrualBlendedItemGLInfo.BlendedItemId IS NOT NULL
THEN #ReAccrualBlendedItemGLInfo.IncomeGLTemplateId
ELSE BlendedItem.BookingGLTemplateId END GLTemplateId
,CASE WHEN BlendedItem.Type = 'Income'
THEN CASE WHEN #ReAccrualBlendedItemGLInfo.BlendedItemId IS NOT NULL THEN #ReAccrualBlendedItemGLInfo.DebitEntryItem ELSE 'BlendedIncomeReceivable' END
ELSE 'BlendedExpensePayable' END GLEntryItem
,ISNULL(GLPostedBlendedItemDetail.Amount_Amount,0) - ISNULL(GLPostedSundryAmountInfo.TotalGLPostedAmount,0) Amount
,CASE WHEN BlendedItem.Type = 'Income' THEN 1 ELSE 0 END IsDebit
,CASE WHEN #ReAccrualBlendedItemGLInfo.BlendedItemId IS NOT NULL
THEN CASE WHEN BlendedItem.SystemConfigType = 'ReAccrualRentalIncome'
THEN #ReAccrualBlendedItemGLInfo.ARGLTemplateId
ELSE #ReAccrualBlendedItemGLInfo.BookingGLTemplateId END
ELSE NULL END MatchingGLTemplateId
FROM (SELECT * FROM #BlendedItemInfo WHERE IsChargedOffContract = 0 OR IsFAS91=0) BlendedItem
LEFT JOIN #BlendedItemSundryInfo GLPostedSundryAmountInfo ON BlendedItem.BlendedItemId = GLPostedSundryAmountInfo.BlendedItemId AND BlendedItem.ContractId = GLPostedSundryAmountInfo.ContractId
LEFT JOIN (SELECT B.BlendedItemId,SUM(BlendedItemDetails.Amount_Amount) Amount_Amount
FROM #BlendedItemInfo B JOIN BlendedItemDetails ON B.BlendedItemId = BlendedItemDetails.BlendedItemId
AND BlendedItemDetails.IsActive=1 AND BlendedItemDetails.IsGLPosted=1
GROUP BY B.BlendedItemId)
AS GLPostedBlendedItemDetail ON BlendedItem.BlendedItemId = GLPostedBlendedItemDetail.BlendedItemId
LEFT JOIN #ReAccrualBlendedItemGLInfo ON BlendedItem.BlendedItemId = #ReAccrualBlendedItemGLInfo.BlendedItemId
WHERE (BlendedItem.IsChargedOffContract = 0 OR BlendedItem.IsFAS91=0)
AND (ISNULL(GLPostedBlendedItemDetail.Amount_Amount,0) - ISNULL(GLPostedSundryAmountInfo.TotalGLPostedAmount,0)) <> 0
AND (#ReAccrualBlendedItemGLInfo.BlendedItemId IS NULL OR BlendedItem.BookRecognitionMode = 'RecognizeImmediately')
IF EXISTS(SELECT ContractId FROM #BlendedItemInfo WHERE BookRecognitionMode <> 'RecognizeImmediately' AND (IsChargedOffContract = 0 OR IsFAS91=0))
BEGIN
INSERT INTO #BlendedItemGLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit,MatchingGLTemplateId)
SELECT B.ContractId
,CASE WHEN #ReAccrualBlendedItemGLInfo.BlendedItemId IS NOT NULL THEN #ReAccrualBlendedItemGLInfo.GLTransactionType ELSE 'BlendedIncomeSetup' END
,CASE WHEN #ReAccrualBlendedItemGLInfo.BlendedItemId IS NOT NULL THEN #ReAccrualBlendedItemGLInfo.IncomeGLTemplateId ELSE BlendedItem.BookingGLTemplateId END
,CASE WHEN #ReAccrualBlendedItemGLInfo.BlendedItemId IS NOT NULL THEN #ReAccrualBlendedItemGLInfo.DebitEntryItem ELSE 'DeferredBlendedIncome' END
,B.RemainingBalance
,CASE WHEN #ReAccrualBlendedItemGLInfo.BlendedItemId IS NOT NULL THEN 1 ELSE 0 END
,CASE WHEN #ReAccrualBlendedItemGLInfo.BlendedItemId IS NOT NULL
THEN CASE WHEN BlendedItem.SystemConfigType = 'ReAccrualRentalIncome'
THEN #ReAccrualBlendedItemGLInfo.ARGLTemplateId
ELSE #ReAccrualBlendedItemGLInfo.BookingGLTemplateId END
ELSE NULL END MatchingGLTemplateId
FROM #BlendedItemGLInfo B
JOIN #BlendedItemInfo BlendedItem ON B.BlendedItemId = BlendedItem.BlendedItemId
LEFT JOIN #ReAccrualBlendedItemGLInfo ON B.BlendedItemId = #ReAccrualBlendedItemGLInfo.BlendedItemId
WHERE BlendedItem.Type = 'Income' AND BlendedItem.BookRecognitionMode <> 'RecognizeImmediately'
AND B.RemainingBalance <> 0
INSERT INTO #BlendedItemGLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit,MatchingGLTemplateId)
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
INSERT INTO #BlendedItemGLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit,MatchingGLTemplateId)
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
INSERT INTO #BlendedItemGLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit,MatchingGLTemplateId)
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
INSERT INTO #BlendedItemGLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT B.ContractId
,CASE WHEN BlendedItem.Type='Income'
THEN CASE WHEN #ReAccrualBlendedItemGLInfo.BlendedItemId IS NOT NULL THEN #ReAccrualBlendedItemGLInfo.GLTransactionType ELSE 'BlendedIncomeRecognition' END
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
BlendedItemId,
ContractId,
SUM(Income) IncomeRecognizedTillDate
FROM #BlendedIncomeSchedules
WHERE IsNonAccrual = 1
GROUP BY BlendedItemId,ContractId)
AS BlendedIncome ON B.BlendedItemId = BlendedIncome.BlendedItemId AND B.ContractId = BlendedIncome.ContractId
LEFT JOIN #ReAccrualBlendedItemGLInfo ON BlendedIncome.BlendedItemId = #ReAccrualBlendedItemGLInfo.BlendedItemId
END
END
IF(@MovePLBalance=1)
BEGIN
IF EXISTS(SELECT ContractId FROM #BlendedItemInfo)
BEGIN
INSERT INTO #BlendedItemGLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit,MatchingGLTemplateId)
SELECT B.ContractId
,CASE WHEN B.Type='Income'
THEN CASE WHEN #ReAccrualBlendedItemGLInfo.BlendedItemId IS NOT NULL THEN #ReAccrualBlendedItemGLInfo.GLTransactionType ELSE 'BlendedIncomeSetup' END
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
INSERT INTO #BlendedItemGLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit,MatchingGLTemplateId)
SELECT B.ContractId
,CASE WHEN B.Type='Income'
THEN CASE WHEN #ReAccrualBlendedItemGLInfo.BlendedItemId IS NOT NULL THEN #ReAccrualBlendedItemGLInfo.GLTransactionType ELSE 'BlendedIncomeRecognition' END
ELSE 'BlendedExpenseRecognition' END
,CASE WHEN #ReAccrualBlendedItemGLInfo.BlendedItemId IS NOT NULL
THEN #ReAccrualBlendedItemGLInfo.IncomeGLTemplateId
ELSE B.RecognitionGLTemplateId END GLTemplateId
,CASE WHEN B.Type='Income'
THEN CASE WHEN #ReAccrualBlendedItemGLInfo.BlendedItemId IS NOT NULL THEN #ReAccrualBlendedItemGLInfo.CreditEntryItem ELSE 'BlendedIncome' END
ELSE 'BlendedExpense' END
,CASE WHEN #ReAccrualBlendedItemGLInfo.BlendedItemId IS NOT NULL AND (B.IsNonAccrual = 0 OR B.IsFAS91=0)
THEN BlendedIncome.Income + ISNULL(AdjustmentInfo.AdjustmentAmount,0)
ELSE BlendedIncome.Income END
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
WHERE BlendedIncome.Income <> 0
OR (#ReAccrualBlendedItemGLInfo.BlendedItemId IS NOT NULL AND ISNULL(AdjustmentInfo.AdjustmentAmount,0) <> 0)
INSERT INTO #BlendedItemGLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit,MatchingGLTemplateId)
SELECT B.ContractId
,CASE WHEN B.Type='Income' THEN 'BlendedIncomeRecognition' ELSE 'BlendedExpenseRecognition' END
,B.RecognitionGLTemplateId
,'CostOfGoodsSold'
,SUM(BlendedItemSummary.AdjustmentAmount)
,CASE WHEN B.Type='Income' THEN 0 ELSE 1 END
,NULL
FROM (SELECT * FROM #BlendedItemInfo WHERE BookRecognitionMode <> 'RecognizeImmediately') B
JOIN #BlendedItemAdjustmentInfo BlendedItemSummary ON B.BlendedItemId = BlendedItemSummary.BlendedItemId AND BlendedItemSummary.ContractId = B.ContractId
LEFT JOIN #ReAccrualBlendedItemGLInfo ON B.BlendedItemId = #ReAccrualBlendedItemGLInfo.BlendedItemId
WHERE BlendedItemSummary.EffectiveDate >= @PLEffectiveDate AND BlendedItemSummary.EffectiveDate < @EffectiveDate
AND #ReAccrualBlendedItemGLInfo.BlendedItemId IS NULL
GROUP BY B.ContractId,B.BlendedItemId,B.Type,B.RecognitionGLTemplateId
HAVING SUM(BlendedItemSummary.AdjustmentAmount) <> 0
END
END
SELECT * FROM #BlendedItemGLSummary
IF OBJECT_ID('tempdb..#BlendedItemGLSummary') IS NOT NULL
DROP TABLE #BlendedItemGLSummary
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
END

GO

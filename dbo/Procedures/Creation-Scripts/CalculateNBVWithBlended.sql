SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[CalculateNBVWithBlended]
(
@NBVWithBlendedCalculatorInput NBVWithBlendedCalculatorInput READONLY
)
AS
BEGIN
CREATE TABLE #ContractNBVInfo
(
ContractId BIGINT,
ContractType NVARCHAR(14),
MaturityDate DATE,
NBV DECIMAL(16,2)
);
CREATE TABLE #BlendedItemSummary
(
ContractId BIGINT,
IncomeTypeBalance DECIMAL(16,2),
ExpenseTypeBalance DECIMAL(16,2)
);
IF EXISTS(SELECT ContractId FROM @NBVWithBlendedCalculatorInput WHERE ContractType = 'Lease')
BEGIN
SELECT
C.ContractId,
MIN(LeaseIncomeSchedules.Id) as LeaseIncomeScheduleId,
MIN(LeaseIncomeSchedules.IncomeDate) as IncomeDate
INTO #FirstIncomePostNonAccrual
FROM
LeaseIncomeSchedules
JOIN LeaseFinances ON LeaseIncomeSchedules.LeaseFinanceId = LeaseFinances.Id
JOIN @NBVWithBlendedCalculatorInput C ON LeaseFinances.ContractId = C.ContractId
WHERE
LeaseIncomeSchedules.IsSchedule = 1
AND LeaseIncomeSchedules.IsLessorOwned = 1
AND LeaseIncomeSchedules.IncomeDate >= C.AsofDate
GROUP BY C.ContractId
--  Insert into Contract NBV Info for Lease --
INSERT INTO #ContractNBVInfo
SELECT
C.ContractId,
C.ContractType,
LFD.MaturityDate,
CASE WHEN C.AsofDate > LFD.MaturityDate
THEN ISNULL(SUM(AVH.BeginBookValue_Amount),0)
ELSE CASE WHEN LFD.LeaseContractType = 'Operating'
THEN ISNULL(SUM(ISNULL(SyndicationAVH.EndBookValue_Amount,AVH.BeginBookValue_Amount)),0) + ISNULL(SUM(CASE WHEN LA.IsLeaseAsset = 0 THEN AIS.BeginNetBookValue_Amount ELSE 0.00 END),0)
ELSE ISNULL(SUM(AIS.BeginNetBookValue_Amount - (AIS.DeferredSellingProfitIncomeBalance_Amount + AIS.DeferredSellingProfitIncome_Amount)),0)
END
END NBV
FROM
AssetIncomeSchedules AIS
JOIN LeaseIncomeSchedules LIS ON AIS.LeaseIncomeScheduleId = LIS.Id AND AIS.IsActive = 1
JOIN LeaseFinances LF ON LIS.LeaseFinanceId = LF.Id
JOIN #FirstIncomePostNonAccrual ON LIS.Id = #FirstIncomePostNonAccrual.LeaseIncomeScheduleId AND LF.ContractId = #FirstIncomePostNonAccrual.ContractId
JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
JOIN @NBVWithBlendedCalculatorInput C ON LF.ContractId = C.ContractId AND C.ContractType = 'Lease'
JOIN LeaseAssets LA ON  LA.LeaseFinanceId = LF.Id AND AIS.AssetId = LA.AssetId AND LA.IsActive = 1
LEFT JOIN AssetValueHistories AVH ON LA.AssetId = AVH.AssetId
AND AVH.IncomeDate = #FirstIncomePostNonAccrual.IncomeDate
AND AVH.SourceModule IN ('Syndications','OTPDepreciation','FixedTermDepreciation','ResidualRecapture') AND AVH.IsSchedule = 1 AND AVH.IsLessorOwned = 1
LEFT JOIN AssetValueHistories SyndicationAVH ON LA.AssetId = SyndicationAVH.AssetId
AND SyndicationAVH.IncomeDate = #FirstIncomePostNonAccrual.IncomeDate
AND SyndicationAVH.SourceModule IN ('Syndications') AND SyndicationAVH.IsSchedule = 1 AND SyndicationAVH.IsLessorOwned = 1
WHERE (LFD.LeaseContractType <> 'Operating' OR LA.IsLeaseAsset=0)
GROUP BY C.ContractId,C.ContractType,#FirstIncomePostNonAccrual.IncomeDate,LFD.LeaseContractType,LFD.MaturityDate,C.AsofDate
-- Insert into Blended Item Summary for Lease --
INSERT INTO #BlendedItemSummary
SELECT
NABlendedSummary.ContractId,
ISNULL(SUM(IncomeTypeBalance),0) as IncomeTypeBalance,
ISNULL(SUM(ExpenseTypeBalance),0) as ExpenseTypeBalance
FROM
(SELECT
C.ContractId as ContractId,
CASE WHEN Type = 'Income'
THEN
CASE WHEN C.AsofDate <= LeaseFinanceDetails.CommencementDate
THEN SUM(BlendedItems.Amount_Amount)
ELSE
CASE WHEN BookRecognitionMode = 'Amortize'
THEN (CASE WHEN Occurrence = 'Recurring' THEN SUM(ISNULL(BlendedItemDetails.Amount_Amount,0.00)) ELSE SUM(BlendedItems.Amount_Amount) END) - SUM(BlendedIncomeSchedules.Income_Amount)
ELSE SUM(BlendedIncomeSchedules.Income_Amount) - SUM(ISNULL(BlendedItemDetails.Amount_Amount,0.00))
END
END
END as IncomeTypeBalance,
CASE WHEN Type <> 'Income'
THEN
CASE WHEN C.AsofDate <= LeaseFinanceDetails.CommencementDate
THEN SUM(BlendedItems.Amount_Amount)
ELSE
CASE WHEN BookRecognitionMode = 'Amortize'
THEN (CASE WHEN Occurrence = 'Recurring' THEN SUM(ISNULL(BlendedItemDetails.Amount_Amount,0.00)) ELSE SUM(BlendedItems.Amount_Amount) END) - SUM(BlendedIncomeSchedules.Income_Amount)
ELSE SUM(BlendedIncomeSchedules.Income_Amount) -  SUM(ISNULL(BlendedItemDetails.Amount_Amount,0.00))
END
END
END as ExpenseTypeBalance
FROM
BlendedIncomeSchedules
JOIN BlendedItems ON BlendedIncomeSchedules.BlendedItemId = BlendedItems.Id AND BlendedIncomeSchedules.IsSchedule = 1
JOIN LeaseBlendedItems ON BlendedItems.Id = LeaseBlendedItems.BlendedItemId AND BlendedItems.IsActive = 1 AND BlendedItems.IsFAS91 = 1
AND BlendedItems.BookRecognitionMode IN ('Amortize','Accrete') AND BlendedItems.Amount_Amount <> 0
JOIN LeaseFinances ON LeaseBlendedItems.LeaseFinanceId = LeaseFinances.Id AND LeaseFinances.IsCurrent = 1
JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
JOIN @NBVWithBlendedCalculatorInput C ON LeaseFinances.ContractId = C.ContractId AND C.ContractType = 'Lease'
LEFT JOIN BlendedItemDetails ON BlendedItems.Id = BlendedItemDetails.BlendedItemId AND BlendedItemDetails.IsActive=1
AND BlendedItemDetails.DueDate <= DATEADD(DAY,-1,C.AsofDate)
WHERE
((BlendedIncomeSchedules.IncomeDate = LeaseFinanceDetails.CommencementDate AND C.AsofDate <= LeaseFinanceDetails.CommencementDate)
OR (BlendedIncomeSchedules.IncomeDate = DATEADD(DAY,-1,C.AsofDate)))
GROUP BY C.ContractId,C.AsofDate,LeaseFinanceDetails.CommencementDate,Type,BlendedItems.BookRecognitionMode,Occurrence) AS NABlendedSummary
GROUP BY NABlendedSummary.ContractId
DROP TABLE #FirstIncomePostNonAccrual
END
IF EXISTS(SELECT ContractId FROM @NBVWithBlendedCalculatorInput WHERE ContractType <> 'Lease')
BEGIN
INSERT INTO #ContractNBVInfo
SELECT
C.ContractId,
C.ContractType,
LoanFinances.MaturityDate,
SUM(LoanIncomeSchedules.BeginNetBookValue_Amount + LoanIncomeSchedules.PrincipalAdded_Amount) as NBV
FROM
LoanIncomeSchedules
JOIN LoanFinances ON LoanIncomeSchedules.LoanFinanceId = LoanFinances.Id
JOIN @NBVWithBlendedCalculatorInput C ON LoanFinances.ContractId = C.ContractId AND C.ContractType = 'Loan'
WHERE
LoanIncomeSchedules.IsSchedule = 1
AND LoanIncomeSchedules.IsLessorOwned = 1
AND LoanIncomeSchedules.IncomeDate >= C.AsofDate
AND LoanIncomeSchedules.IncomeDate =
(SELECT
MIN(IncomeDate)
FROM
LoanIncomeSchedules
JOIN LoanFinances ON LoanIncomeSchedules.LoanFinanceId = LoanFinances.Id
WHERE
LoanIncomeSchedules.IsSchedule = 1
AND LoanIncomeSchedules.IsLessorOwned = 1
AND LoanIncomeSchedules.IncomeDate >= C.AsofDate
AND LoanFinances.ContractId = C.ContractId)
GROUP BY C.ContractId,C.ContractType,LoanFinances.MaturityDate
INSERT INTO #BlendedItemSummary
SELECT
NABlendedSummary.ContractId,
ISNULL(SUM(IncomeTypeBalance),0) as IncomeTypeBalance,
ISNULL(SUM(ExpenseTypeBalance),0) as ExpenseTypeBalance
FROM
(SELECT
C.ContractId as ContractId,
CASE WHEN Type = 'Income'
THEN
CASE WHEN C.AsofDate <= LoanFinances.CommencementDate
THEN SUM(BlendedItems.Amount_Amount)
ELSE
CASE WHEN BookRecognitionMode = 'Amortize'
THEN (CASE WHEN Occurrence = 'Recurring' THEN SUM(ISNULL(BlendedItemDetails.Amount_Amount,0.00)) ELSE SUM(BlendedItems.Amount_Amount) END) - SUM(BlendedIncomeSchedules.Income_Amount)
ELSE SUM(BlendedIncomeSchedules.Income_Amount) - SUM(ISNULL(BlendedItemDetails.Amount_Amount,0.00))
END
END
END as IncomeTypeBalance,
CASE WHEN Type <> 'Income'
THEN
CASE WHEN C.AsofDate <= LoanFinances.CommencementDate
THEN SUM(BlendedItems.Amount_Amount)
ELSE
CASE WHEN BookRecognitionMode = 'Amortize'
THEN (CASE WHEN Occurrence = 'Recurring' THEN SUM(ISNULL(BlendedItemDetails.Amount_Amount,0.00)) ELSE SUM(BlendedItems.Amount_Amount) END) - SUM(BlendedIncomeSchedules.Income_Amount)
ELSE SUM(BlendedIncomeSchedules.Income_Amount) -  SUM(ISNULL(BlendedItemDetails.Amount_Amount,0.00))
END
END
END as ExpenseTypeBalance
FROM
BlendedIncomeSchedules
JOIN BlendedItems ON BlendedIncomeSchedules.BlendedItemId = BlendedItems.Id AND BlendedIncomeSchedules.IsSchedule = 1
JOIN LoanBlendedItems ON BlendedItems.Id = LoanBlendedItems.BlendedItemId AND BlendedItems.IsActive = 1 AND BlendedItems.IsFAS91 = 1
AND BlendedItems.BookRecognitionMode IN ('Amortize','Accrete') AND BlendedItems.Amount_Amount <> 0
JOIN LoanFinances ON LoanBlendedItems.LoanFinanceId = LoanFinances.Id
JOIN @NBVWithBlendedCalculatorInput C ON LoanFinances.ContractId = C.ContractId AND C.ContractType = 'Loan'
LEFT JOIN BlendedItemDetails ON BlendedItems.Id = BlendedItemDetails.BlendedItemId AND BlendedItemDetails.IsActive=1
AND BlendedItemDetails.DueDate <= DATEADD(DAY,-1,C.AsofDate)
WHERE
((BlendedIncomeSchedules.IncomeDate = LoanFinances.CommencementDate AND C.AsofDate <= LoanFinances.CommencementDate)
OR (BlendedIncomeSchedules.IncomeDate = DATEADD(DAY,-1,C.AsofDate)))
GROUP BY C.ContractId,C.AsofDate,LoanFinances.CommencementDate,Type,BlendedItems.BookRecognitionMode,Occurrence) AS NABlendedSummary
GROUP BY NABlendedSummary.ContractId
END
UPDATE #ContractNBVInfo SET NBV = NBV + (#BlendedItemSummary.ExpenseTypeBalance - #BlendedItemSummary.IncomeTypeBalance)
FROM
#ContractNBVInfo
JOIN #BlendedItemSummary ON #ContractNBVInfo.ContractId = #BlendedItemSummary.ContractId
SELECT
C.ContractId,
SUM(CASE WHEN ((LeasePaymentSchedules.Id IS NOT NULL AND LeasePaymentSchedules.StartDate < C.AsofDate) OR
(LoanPaymentSchedules.Id IS NOT NULL AND LoanPaymentSchedules.StartDate < C.AsofDate))
THEN ReceivableDetails.EffectiveBalance_Amount
ELSE 0 END) as ReceivableBalance,
ISNULL(SUM(CASE WHEN ((LeasePaymentSchedules.Id IS NOT NULL AND LeasePaymentSchedules.StartDate >= C.AsofDate) OR
(LoanPaymentSchedules.Id IS NOT NULL AND LoanPaymentSchedules.StartDate >= C.AsofDate))
THEN ISNULL(ReceiptCashPostedInfo.CashPostedAmount,0)
ELSE 0 END),0) as CashPostedAmount
INTO #ReceivableHeaderInfo
FROM
Receivables
JOIN @NBVWithBlendedCalculatorInput C ON Receivables.EntityId = C.ContractId AND Receivables.EntityType = 'CT' AND Receivables.IsActive = 1
JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
JOIN ReceivableDetails ON Receivables.Id = ReceivableDetails.ReceivableId AND Receivables.IsActive = 1 AND ReceivableDetails.IsActive = 1 AND Receivables.FunderId IS NULL
LEFT JOIN LeasePaymentSchedules ON Receivables.PaymentScheduleId = LeasePaymentSchedules.Id AND LeasePaymentSchedules.IsActive = 1 AND LeasePaymentSchedules.PaymentType IN ('FixedTerm','DownPayment','MaturityPayment','CustomerGuaranteedResidual','ThirdPartyGuaranteedResidual') AND C.ContractType = 'Lease'
LEFT JOIN LoanPaymentSchedules ON Receivables.PaymentScheduleId = LoanPaymentSchedules.Id AND LoanPaymentSchedules.IsActive = 1 AND LoanPaymentSchedules.PaymentType IN ('FixedTerm','Downpayment') AND C.ContractType = 'Loan'
LEFT JOIN
(
SELECT
ReceivableDetailId,
SUM(ReceiptApplicationReceivableDetails.AmountApplied_Amount) as CashPostedAmount
FROM
ReceiptApplicationReceivableDetails
JOIN ReceiptApplications ON ReceiptApplicationReceivableDetails.ReceiptApplicationId = ReceiptApplications.Id
JOIN Receipts ON ReceiptApplications.ReceiptId = Receipts.Id
WHERE
ReceiptApplicationReceivableDetails.IsActive = 1
AND Receipts.ReceiptClassification NOT IN ('NonAccrualNonDSLNonCash','NonCash')
AND Receipts.Status NOT IN ('Reversed','Inactive')
GROUP BY ReceivableDetailId) AS ReceiptCashPostedInfo ON ReceivableDetails.Id = ReceiptCashPostedInfo.ReceivableDetailId
WHERE
LoanPaymentSchedules.Id IS NOT NULL OR LeasePaymentSchedules.Id IS NOT NULL
AND (ReceivableTypes.Name IN ('CapitalLeaseRental','LeaseFloatRateAdj','LoanInterest','LoanPrincipal')
OR (ReceivableTypes.Name = 'OperatingLeaseRental' AND ReceivableDetails.AssetComponentType = 'Finance'))
GROUP BY C.ContractId
SELECT
#ContractNBVInfo.ContractId,
#ContractNBVInfo.ContractType,
#ContractNBVInfo.NBV,
(#ContractNBVInfo.NBV + #ReceivableHeaderInfo.ReceivableBalance - #ReceivableHeaderInfo.CashPostedAmount) AS NBVWithBlended
FROM
@NBVWithBlendedCalculatorInput C
JOIN #ContractNBVInfo ON C.ContractId = #ContractNBVInfo.ContractId
JOIN #ReceivableHeaderInfo ON C.ContractId = #ReceivableHeaderInfo.ContractId
DROP TABLE #ContractNBVInfo
DROP TABLE #BlendedItemSummary
DROP TABLE #ReceivableHeaderInfo
END

GO

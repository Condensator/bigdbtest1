SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create PROCEDURE [dbo].[GetOTPDetailsForContractSummary]
(
@ContractId BigInt,
@AsOfDate DateTime
)
AS
BEGIN
SET NOCOUNT ON
DECLARE @LastIncomeDate DateTime
DECLARE @YearStartDate DateTime = DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0)
DECLARE @RenewalAccrued Decimal(18,2) = 0
DECLARE @AppliedToDepreciation Decimal(18,2) = 0
DECLARE @OTPAssetBalance Decimal(18,2) = 0
Select
ContractId, LeaseFinanceId, LeaseContractType, IncomeDate, Payment_Amount, Depreciation_Amount, RentalIncome_Amount,EndNetBookValue_Amount,
OperatingEndNetBookValue_Amount, IsSchedule, IsAccounting, IsGLPosted, IncomeType INTO #OTPDetails
from LeaseIncomeSchedules With (NoLock)
Join LeaseFinances With (NoLock) On LeaseIncomeSchedules.LeaseFinanceId = LeaseFinances.Id
Join LeaseFinanceDetails With (NoLock) On LeaseFinances.Id = LeaseFinanceDetails.Id
Where ContractId = @ContractId And IncomeDate <= @AsOfDate And  IncomeType In ('OverTerm', 'Supplemental') And IsSchedule = 1
order by ContractId, IncomeDate
Select @LastIncomeDate = Max(IncomeDate) from #OTPDetails
Create Table #OTP(Category Nvarchar(100), RenewalAccrued Decimal(18,2), AppliedToDepreciation Decimal(18,2))
Create Table #OTPResult (OTP Nvarchar(100), MonthToDateAmount Decimal(18,2), YearToDateAmount Decimal(18,2), LifeToDateAmount Decimal(18,2))
Insert Into #OTPResult (OTP) Values ('OTP/Supplemental Rent Amount');
Insert Into #OTPResult (OTP) Values ('Residual value Recapture Amount');
Insert Into #OTPResult (OTP) Values ('OTP Depreciation');
Insert Into #OTPResult (OTP) Values ('OTP/Supplemental Income');
Insert Into #OTPResult (OTP) Values ('OTP Asset Balance');
DECLARE @MTDRVRecapAmount Decimal(18,2) = 0
DECLARE @YTDRVRecapAmount Decimal(18,2) = 0
DECLARE @LTDRVRecapAmount Decimal(18,2) = 0
DECLARE @MTDOTPIncome Decimal(18,2) = 0
DECLARE @YTDOTPIncome Decimal(18,2) = 0
DECLARE @LTDOTPIncome Decimal(18,2) = 0
SELECT
ReceivableCodes.AccountingTreatment,
Receivables.IncomeType,
LeasePaymentSchedules.StartDate,
LeasePaymentSchedules.EndDate,
ReceivableDetails.AssetId,
Receivables.Id [ReceivableId],
Receivables.EntityId [ContractId],
ReceivableDetails.Id [ReceivableDetailId]
INTO #PaymentScheduleInfo
FROM Receivables
JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
JOIN ReceivableDetails ON Receivables.Id = ReceivableDetails.ReceivableId
JOIN LeasePaymentSchedules ON Receivables.PaymentScheduleId = LeasePaymentSchedules.Id
JOIN LeaseAssets ON  LeaseAssets.LeaseFinanceId = LeasePaymentSchedules.LeaseFinanceDetailId AND LeaseAssets.AssetId = ReceivableDetails.AssetId AND LeaseAssets.IsActive = 1
JOIN LeaseFinances ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id  AND LeaseFinances.IsCurrent = 1 AND LeaseFinances.ContractId = @ContractId
WHERE Receivables.EntityId = @ContractId
AND Receivables.EntityType = 'CT'
AND Receivables.SourceTable = '_'
AND Receivables.IsActive = 1
AND (Receivables.IncomeType = 'OTP' OR Receivables.IncomeType = 'Supplemental')
DECLARE @OverTermAccountingTreatment NVARCHAR(100) = (SELECT TOP 1 AccountingTreatment FROM #PaymentScheduleInfo WHERE #PaymentScheduleInfo.IncomeType = 'OTP')
IF(@OverTermAccountingTreatment IS NOT NULL AND @OverTermAccountingTreatment = 'CashBased')
BEGIN
;WITH CTE_AVHIds AS
(
SELECT DISTINCT(AssetValueHistories.Id)
FROM AssetValueHistories
JOIN #PaymentScheduleInfo ON AssetValueHistories.AssetId = #PaymentScheduleInfo.AssetId
WHERE AssetValueHistories.IsSchedule = 1
AND AssetValueHistories.IsLessorOwned = 1
AND AssetValueHistories.IncomeDate >= #PaymentScheduleInfo.StartDate
AND AssetValueHistories.IncomeDate <= #PaymentScheduleInfo.EndDate
AND #PaymentScheduleInfo.AccountingTreatment = 'CashBased'
AND #PaymentScheduleInfo.IncomeType = 'OTP'
)
SELECT
ISNULL(AssetValueHistoryDetails.AmountPosted_Amount,0) [AmountPosted],
CASE WHEN Receipts.ReceiptClassification <> 'NonCash' THEN Receipts.ReceivedDate ELSE Receipts.PostDate END 'ReceivedDate'
INTO #RVRecapAmountOTPTemp
FROM AssetValueHistoryDetails
JOIN CTE_AVHIds ON AssetValueHistoryDetails.AssetValueHistoryId = CTE_AVHIds.Id
JOIN ReceiptApplicationReceivableDetails ON AssetValueHistoryDetails.ReceiptApplicationReceivableDetailId = ReceiptApplicationReceivableDetails.Id
JOIN ReceiptApplications ON ReceiptApplicationReceivableDetails.ReceiptApplicationId = ReceiptApplications.Id
JOIN Receipts ON ReceiptApplications.ReceiptId = Receipts.Id
WHERE AssetValueHistoryDetails.GLJournalId IS NOT NULL
AND AssetValueHistoryDetails.IsActive = 1
AND ((Receipts.ReceiptClassification <> 'NonCash' AND Receipts.ReceivedDate <= @AsOfDate) OR (Receipts.ReceiptClassification = 'NonCash' AND Receipts.PostDate <= @AsOfDate))
SET @MTDRVRecapAmount = @MTDRVRecapAmount + ISNULL((SELECT SUM(AmountPosted) FROM #RVRecapAmountOTPTemp
WHERE MONTH(ReceivedDate) = MONTH(@AsOfDate)
AND YEAR(ReceivedDate) = YEAR(@AsOfDate)
AND DAY(ReceivedDate) <= DAY(@AsOfDate)),0)
SET @YTDRVRecapAmount = @YTDRVRecapAmount + ISNULL((SELECT SUM(AmountPosted) FROM #RVRecapAmountOTPTemp WHERE ReceivedDate BETWEEN @YearStartDate AND @AsOfDate),0)
SET @LTDRVRecapAmount = @LTDRVRecapAmount + ISNULL((SELECT SUM(AmountPosted) FROM #RVRecapAmountOTPTemp),0)
SELECT
ISNULL(ReceiptApplicationReceivableDetails.AmountApplied_Amount,0) [AmountApplied],
CASE WHEN Receipts.ReceiptClassification <> 'NonCash' THEN Receipts.ReceivedDate ELSE Receipts.PostDate END 'ReceivedDate'
INTO #IncomeOTPTemp
FROM ReceiptApplicationReceivableDetails
JOIN #PaymentScheduleInfo ON ReceiptApplicationReceivableDetails.ReceivableDetailId = #PaymentScheduleInfo.ReceivableDetailId
JOIN ReceiptApplications ON ReceiptApplicationReceivableDetails.ReceiptApplicationId = ReceiptApplications.Id
JOIN Receipts ON ReceiptApplications.ReceiptId = Receipts.Id
WHERE ((Receipts.ReceiptClassification <> 'NonCash' AND Receipts.Status = 'Posted') OR (Receipts.ReceiptClassification = 'NonCash' AND Receipts.Status = 'Completed'))
AND ReceiptApplicationReceivableDetails.IsActive = 1
AND #PaymentScheduleInfo.IncomeType = 'OTP'
AND ((Receipts.ReceiptClassification <> 'NonCash' AND Receipts.ReceivedDate <= @AsOfDate) OR (Receipts.ReceiptClassification = 'NonCash' AND Receipts.PostDate <= @AsOfDate))
SET @MTDOTPIncome = @MTDOTPIncome + ISNULL((SELECT SUM(AmountApplied) FROM #IncomeOTPTemp
WHERE MONTH(ReceivedDate) = MONTH(@AsOfDate)
AND YEAR(ReceivedDate) = YEAR(@AsOfDate)
AND DAY(ReceivedDate) <= DAY(@AsOfDate)),0)
SET @YTDOTPIncome = @YTDOTPIncome + ISNULL((SELECT SUM(AmountApplied) FROM #IncomeOTPTemp WHERE ReceivedDate BETWEEN @YearStartDate AND @AsOfDate),0)
SET @LTDOTPIncome = @LTDOTPIncome + ISNULL((SELECT SUM(AmountApplied) FROM #IncomeOTPTemp),0)
END
ELSE IF(@OverTermAccountingTreatment IS NOT NULL)
BEGIN
SELECT @MTDRVRecapAmount = @MTDRVRecapAmount + ISNULL(SUM(Depreciation_Amount),0) FROM #OTPDetails
WHERE MONTH(IncomeDate) = MONTH(@AsOfDate) AND YEAR(IncomeDate) = YEAR(@AsOfDate) AND DAY(IncomeDate) <= DAY(@AsOfDate) AND LeaseContractType <> 'Operating' AND IncomeType = 'OverTerm' AND IsGLPosted = 1
SELECT @MTDOTPIncome = @MTDOTPIncome + ISNULL(SUM(RentalIncome_Amount),0) FROM #OTPDetails
WHERE MONTH(IncomeDate) = MONTH(@AsOfDate) AND YEAR(IncomeDate) = YEAR(@AsOfDate) AND DAY(IncomeDate) <= DAY(@AsOfDate) AND IncomeType = 'OverTerm' AND IsGLPosted = 1
SELECT @YTDRVRecapAmount = @YTDRVRecapAmount + ISNULL(SUM(Depreciation_Amount),0) FROM #OTPDetails
WHERE IncomeDate BETWEEN @YearStartDate AND @AsOfDate AND LeaseContractType <> 'Operating' AND IncomeType = 'OverTerm' AND IsGLPosted = 1
SELECT @YTDOTPIncome = @YTDOTPIncome + ISNULL(SUM(RentalIncome_Amount),0) from #OTPDetails
WHERE IncomeDate BETWEEN @YearStartDate AND @AsOfDate AND IncomeType = 'OverTerm' AND IsGLPosted = 1
SELECT @LTDRVRecapAmount = @LTDRVRecapAmount + ISNULL(SUM(Depreciation_Amount),0) FROM #OTPDetails
WHERE LeaseContractType <> 'Operating' AND IncomeType = 'OverTerm' AND IsGLPosted = 1
SELECT @LTDOTPIncome = @LTDOTPIncome + ISNULL(SUM(RentalIncome_Amount),0) FROM #OTPDetails
WHERE IncomeType = 'OverTerm' AND IsGLPosted = 1
END
DECLARE @SupplementalAccountingTreatment NVARCHAR(100) = (SELECT TOP 1 AccountingTreatment FROM #PaymentScheduleInfo WHERE #PaymentScheduleInfo.IncomeType = 'Supplemental')
IF(@SupplementalAccountingTreatment IS NOT NULL AND @SupplementalAccountingTreatment = 'CashBased')
BEGIN
;WITH CTE_AVHIds AS
(
SELECT DISTINCT(AssetValueHistories.Id)
FROM AssetValueHistories
JOIN #PaymentScheduleInfo ON AssetValueHistories.AssetId = #PaymentScheduleInfo.AssetId
WHERE AssetValueHistories.IsSchedule = 1
AND AssetValueHistories.IsLessorOwned = 1
AND AssetValueHistories.IncomeDate >= #PaymentScheduleInfo.StartDate
AND AssetValueHistories.IncomeDate <= #PaymentScheduleInfo.EndDate
AND #PaymentScheduleInfo.AccountingTreatment = 'CashBased'
AND #PaymentScheduleInfo.IncomeType = 'Supplemental'
)
SELECT
ISNULL(AssetValueHistoryDetails.AmountPosted_Amount,0) [AmountPosted],
CASE WHEN Receipts.ReceiptClassification <> 'NonCash' THEN Receipts.ReceivedDate ELSE Receipts.PostDate END 'ReceivedDate'
INTO #RVRecapAmountSupplementTemp
FROM AssetValueHistoryDetails
JOIN CTE_AVHIds ON AssetValueHistoryDetails.AssetValueHistoryId = CTE_AVHIds.Id
JOIN ReceiptApplicationReceivableDetails ON AssetValueHistoryDetails.ReceiptApplicationReceivableDetailId = ReceiptApplicationReceivableDetails.Id
JOIN ReceiptApplications ON ReceiptApplicationReceivableDetails.ReceiptApplicationId = ReceiptApplications.Id
JOIN Receipts ON ReceiptApplications.ReceiptId = Receipts.Id
WHERE AssetValueHistoryDetails.GLJournalId IS NOT NULL
AND AssetValueHistoryDetails.IsActive = 1
AND ((Receipts.ReceiptClassification <> 'NonCash' AND Receipts.ReceivedDate <= @AsOfDate) OR (Receipts.ReceiptClassification = 'NonCash' AND Receipts.PostDate <= @AsOfDate))
SET @MTDRVRecapAmount = @MTDRVRecapAmount + ISNULL((SELECT SUM(AmountPosted) FROM #RVRecapAmountSupplementTemp
WHERE MONTH(ReceivedDate) = MONTH(@AsOfDate)
AND YEAR(ReceivedDate) = YEAR(@AsOfDate)
AND DAY(ReceivedDate) <= DAY(@AsOfDate)),0)
SET @YTDRVRecapAmount = @YTDRVRecapAmount + ISNULL((SELECT SUM(AmountPosted) FROM #RVRecapAmountSupplementTemp WHERE ReceivedDate BETWEEN @YearStartDate AND @AsOfDate),0)
SET @LTDRVRecapAmount = @LTDRVRecapAmount + ISNULL((SELECT SUM(AmountPosted) FROM #RVRecapAmountSupplementTemp),0)
SELECT
ISNULL(ReceiptApplicationReceivableDetails.AmountApplied_Amount,0) [AmountApplied],
CASE WHEN Receipts.ReceiptClassification <> 'NonCash' THEN Receipts.ReceivedDate ELSE Receipts.PostDate END 'ReceivedDate'
INTO #IncomeSupplementTemp
FROM ReceiptApplicationReceivableDetails
JOIN #PaymentScheduleInfo ON ReceiptApplicationReceivableDetails.ReceivableDetailId = #PaymentScheduleInfo.ReceivableDetailId
JOIN ReceiptApplications ON ReceiptApplicationReceivableDetails.ReceiptApplicationId = ReceiptApplications.Id
JOIN Receipts ON ReceiptApplications.ReceiptId = Receipts.Id
WHERE ((Receipts.ReceiptClassification <> 'NonCash' AND Receipts.Status = 'Posted') OR (Receipts.ReceiptClassification = 'NonCash' AND Receipts.Status = 'Completed'))
AND ReceiptApplicationReceivableDetails.IsActive = 1
AND #PaymentScheduleInfo.IncomeType = 'Supplemental'
AND ((Receipts.ReceiptClassification <> 'NonCash' AND Receipts.ReceivedDate <= @AsOfDate) OR (Receipts.ReceiptClassification = 'NonCash' AND Receipts.PostDate <= @AsOfDate))
SET @MTDOTPIncome = @MTDOTPIncome + ISNULL((SELECT SUM(AmountApplied) FROM #IncomeSupplementTemp
WHERE MONTH(ReceivedDate) = MONTH(@AsOfDate)
AND YEAR(ReceivedDate) = YEAR(@AsOfDate)
AND DAY(ReceivedDate) <= DAY(@AsOfDate)),0)
SET @YTDOTPIncome = @YTDOTPIncome + ISNULL((SELECT SUM(AmountApplied) FROM #IncomeSupplementTemp WHERE ReceivedDate BETWEEN @YearStartDate AND @AsOfDate),0)
SET @LTDOTPIncome = @LTDOTPIncome + ISNULL((SELECT SUM(AmountApplied) FROM #IncomeSupplementTemp),0)
END
ELSE IF(@SupplementalAccountingTreatment IS NOT NULL)
BEGIN
SELECT @MTDRVRecapAmount = @MTDRVRecapAmount + ISNULL(SUM(Depreciation_Amount),0) FROM #OTPDetails
WHERE Month(IncomeDate) = MONTH(@AsOfDate) AND YEAR(IncomeDate) = YEAR(@AsOfDate) AND DAY(IncomeDate) <= DAY(@AsOfDate) AND LeaseContractType <> 'Operating' AND IncomeType = 'Supplemental' AND IsGLPosted = 1
SELECT @MTDOTPIncome = @MTDOTPIncome + ISNULL(SUM(RentalIncome_Amount),0) FROM #OTPDetails
WHERE Month(IncomeDate) = MONTH(@AsOfDate) And YEAR(IncomeDate) = YEAR(@AsOfDate) AND DAY(IncomeDate) <= DAY(@AsOfDate) AND IncomeType = 'Supplemental' AND IsGLPosted = 1
SELECT @YTDRVRecapAmount = @YTDRVRecapAmount + ISNULL(SUM(Depreciation_Amount),0) from #OTPDetails
WHERE IncomeDate BETWEEN @YearStartDate AND @AsOfDate And LeaseContractType <> 'Operating' AND IncomeType = 'Supplemental' AND IsGLPosted = 1
SELECT @YTDOTPIncome = @YTDOTPIncome + ISNULL(SUM(RentalIncome_Amount),0) from #OTPDetails
WHERE IncomeDate BETWEEN @YearStartDate AND @AsOfDate AND IncomeType = 'Supplemental' AND IsGLPosted = 1
SELECT @LTDRVRecapAmount = @LTDRVRecapAmount + ISNULL(SUM(Depreciation_Amount),0) FROM #OTPDetails
WHERE LeaseContractType <> 'Operating' AND IncomeType = 'Supplemental' AND IsGLPosted = 1
SELECT @LTDOTPIncome = @LTDOTPIncome + ISNULL(SUM(RentalIncome_Amount),0) FROM #OTPDetails
WHERE IncomeType = 'Supplemental' AND IsGLPosted = 1
END
Insert Into #OTP Select 'MTD', IsNull(Sum(Payment_Amount),0), 0 from #OTPDetails
Where Month(IncomeDate) = Month(@AsOfDate) And Year(IncomeDate) = Year(@AsOfDate) AND DAY(IncomeDate) <= DAY(@AsOfDate) And  LeaseContractType <> 'Operating'
Insert Into #OTP Select 'MTD', IsNull(Sum(Payment_Amount),0), IsNull(Sum(Depreciation_Amount),0) from #OTPDetails
Where Month(IncomeDate) = Month(@AsOfDate) And Year(IncomeDate) = Year(@AsOfDate) AND DAY(IncomeDate) <= DAY(@AsOfDate) And  LeaseContractType = 'Operating'
Insert Into #OTP Select 'YTD', IsNull(Sum(Payment_Amount),0), 0 from #OTPDetails
Where IncomeDate Between @YearStartDate And @AsOfDate  And  LeaseContractType <> 'Operating'
Insert Into #OTP Select 'YTD', IsNull(Sum(Payment_Amount),0), IsNull(Sum(Depreciation_Amount),0) from #OTPDetails
Where IncomeDate Between @YearStartDate And @AsOfDate  And  LeaseContractType = 'Operating'
Insert Into #OTP Select 'LTD', IsNull(Sum(Payment_Amount),0), 0 from #OTPDetails
Where LeaseContractType <> 'Operating'
Insert Into #OTP Select 'LTD', IsNull(Sum(Payment_Amount),0), IsNull(Sum(Depreciation_Amount),0) from #OTPDetails
Where LeaseContractType = 'Operating'
Select Category, Sum(RenewalAccrued) RenewalAccrued , Sum(AppliedToDepreciation) AppliedToDepreciation, 0.00 OTPAssetBalance Into #T from #OTP Group By Category
Select @RenewalAccrued = RenewalAccrued, @AppliedToDepreciation = AppliedToDepreciation from  #T Where Category = 'MTD'
Update #OTPResult Set MonthToDateAmount = @RenewalAccrued Where OTP = 'OTP/Supplemental Rent Amount';
Update #OTPResult Set MonthToDateAmount = -1* @MTDRVRecapAmount Where OTP = 'Residual value Recapture Amount';
Update #OTPResult Set MonthToDateAmount = -1* @AppliedToDepreciation Where OTP = 'OTP Depreciation';
Update #OTPResult Set MonthToDateAmount = @MTDOTPIncome Where OTP = 'OTP/Supplemental Income';
Update #OTPResult Set MonthToDateAmount = 0 Where OTP = 'OTP Asset Balance';
Select @RenewalAccrued = RenewalAccrued, @AppliedToDepreciation = AppliedToDepreciation from  #T Where Category = 'YTD'
Update #OTPResult Set YearToDateAmount = @RenewalAccrued Where OTP = 'OTP/Supplemental Rent Amount';
Update #OTPResult Set YearToDateAmount = -1* @YTDRVRecapAmount Where OTP = 'Residual value Recapture Amount';
Update #OTPResult Set YearToDateAmount = -1* @AppliedToDepreciation Where OTP = 'OTP Depreciation';
Update #OTPResult Set YearToDateAmount = @YTDOTPIncome Where OTP = 'OTP/Supplemental Income';
Update #OTPResult Set YearToDateAmount = 0 Where OTP = 'OTP Asset Balance';
Select @RenewalAccrued = RenewalAccrued, @AppliedToDepreciation = AppliedToDepreciation from  #T Where Category = 'LTD'
Update #OTPResult Set LifeToDateAmount = @RenewalAccrued Where OTP = 'OTP/Supplemental Rent Amount';
Update #OTPResult Set LifeToDateAmount = -1* @LTDRVRecapAmount Where OTP = 'Residual value Recapture Amount';
Update #OTPResult Set LifeToDateAmount = -1* @AppliedToDepreciation Where OTP = 'OTP Depreciation';
Update #OTPResult Set LifeToDateAmount = @LTDOTPIncome Where OTP = 'OTP/Supplemental Income';
Select @OTPAssetBalance = Case When LeaseContractType = 'Operating' Then OperatingEndNetBookValue_Amount Else
((SELECT ISNULL(SUM(BookedResidual_Amount),0) FROM LeaseAssets
JOIN LeaseFinances ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id
WHERE LeaseAssets.IsActive = 1 AND LeaseFinances.IsCurrent = 1 AND LeaseFinances.ContractId = @ContractId
) - (-1 * @LTDRVRecapAmount))
End
from #OTPDetails Where IncomeDate = @LastIncomeDate
Update #OTPResult Set LifeToDateAmount = @OTPAssetBalance Where OTP = 'OTP Asset Balance';
Select * from #OTPResult
--Drop Table #OTPDetails
--Drop Table #OTP
--Drop Table #OTPResult
--Drop Table #T
--Drop Table #PaymentScheduleInfo
--Drop Table #RVRecapAmountOTPTemp
--Drop Table #IncomeOTPTemp
--Drop Table #RVRecapAmountSupplementTemp
--Drop Table #IncomeSupplementTemp
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[NonAccrualReportContractTypeLease]
(
@FromDate DATE = NULL,
@ToDate DATE = NULL,
@SequenceNumber NVARCHAR(MAX)
)
AS
BEGIN
SET NOCOUNT ON
CREATE TABLE #NonAccrualIncomeContractTypeLease
(
[IncomeDate] DATE NOT NULL,
[Payment] DECIMAL(16,2) NOT NULL ,
[LeaseAssetIncome] DECIMAL(16,2) NOT NULL,
[FinanceAssetIncome] DECIMAL(16,2) NOT NULL,
[DeferredSellingProfitIncome] DECIMAL(16,2) NOT NULL,
[FAS91Expense] DECIMAL(16,2) NOT NULL ,
[FAS91Income] DECIMAL(16,2) NOT NULL ,
[OtherBlendedExpense] DECIMAL(16,2) NOT NULL ,
[OtherBlendedIncome] DECIMAL(16,2) NOT NULL
)
DECLARE @ContractType NVARCHAR(MAX) = ''
DECLARE @ContractId BIGINT
SELECT @ContractType  = ContractType,
@ContractId = Id
FROM Contracts
WHERE SequenceNumber = @SequenceNumber
IF @ContractType = 'Lease'
BEGIN
SELECT
LeaseIncomeSchedules.IncomeDate,
[Payment] = LeaseIncomeSchedules.Payment_Amount + LeaseIncomeSchedules.FinancePayment_Amount,
[LeaseAssetIncome] = CASE WHEN LeaseFinanceDetails.LeaseContractType = 'Operating' THEN LeaseIncomeSchedules.RentalIncome_Amount ELSE LeaseIncomeSchedules.Income_Amount END,
[FinanceAssetIncome] = LeaseIncomeSchedules.FinanceIncome_Amount ,
[DeferredSellingProfitIncome] = LeaseIncomeSchedules.DeferredSellingProfitIncome_Amount
INTO #IncomeSchedules
FROM  LeaseFinances
INNER JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
INNER JOIN LeaseIncomeSchedules ON LeaseIncomeSchedules.LeaseFinanceId = LeaseFinances.Id
WHERE LeaseIncomeSchedules.IsAccounting = 1
AND LeaseIncomeSchedules.IsNonAccrual = 1
AND LeaseIncomeSchedules.IsGLPosted = 1
AND LeaseFinances.ContractId = @ContractId
AND (@FromDate IS NULL OR @FromDate <= LeaseIncomeSchedules.IncomeDate)
AND (@ToDate IS NULL OR @ToDate >= LeaseIncomeSchedules.IncomeDate)
SELECT
BlendedIncomeSchedules.IncomeDate,
CASE WHEN BlendedItems.Type = 'Income' AND BlendedItems.IsFAS91 = 1
THEN BlendedIncomeSchedules.Income_Amount ELSE 0.0 END [FAS91Income],
CASE WHEN (BlendedItems.Type = 'IDC' OR BlendedItems.Type = 'Expense') AND BlendedItems.IsFAS91 = 1
THEN BlendedIncomeSchedules.Income_Amount ELSE 0.0 END [FAS91Expense],
CASE WHEN BlendedItems.Type = 'Income' AND BlendedItems.IsFAS91 = 0
THEN BlendedIncomeSchedules.Income_Amount ELSE 0.0 END [OtherBlendedIncome],
CASE WHEN (BlendedItems.Type = 'IDC' OR BlendedItems.Type = 'Expense') AND BlendedItems.IsFAS91 = 0
THEN BlendedIncomeSchedules.Income_Amount ELSE 0.0 END [OtherBlendedExpense]
INTO #BlendedIncomeSchedules
FROM  LeaseFinances
LEFT JOIN LeaseBlendedItems ON LeaseFinances.Id = LeaseBlendedItems.LeaseFinanceId
LEFT JOIN BlendedItems ON LeaseBlendedItems.BlendedItemId = BlendedItems.Id
LEFT JOIN BlendedIncomeSchedules ON BlendedIncomeSchedules.BlendedItemId = BlendedItems.Id
WHERE BlendedIncomeSchedules.IsAccounting = 1
AND BlendedIncomeSchedules.IsNonAccrual = 1
AND BlendedIncomeSchedules.PostDate IS NOT NULL
AND BlendedIncomeSchedules.ReversalPostDate IS NULL
AND LeaseFinances.ContractId = @ContractId
AND (@FromDate IS NULL OR @FromDate <= BlendedIncomeSchedules.IncomeDate)
AND (@ToDate IS NULL OR @ToDate >= BlendedIncomeSchedules.IncomeDate)
INSERT INTO #NonAccrualIncomeContractTypeLease
(
[IncomeDate] ,
[Payment] ,
[LeaseAssetIncome],
[FinanceAssetIncome],
[DeferredSellingProfitIncome],
[FAS91Expense] ,
[FAS91Income] ,
[OtherBlendedExpense] ,
[OtherBlendedIncome]
)
SELECT #IncomeSchedules.IncomeDate,
#IncomeSchedules.Payment [Payment],
#IncomeSchedules.LeaseAssetIncome [LeaseAssetIncome],
#IncomeSchedules.FinanceAssetIncome [FinanceAssetIncome],
#IncomeSchedules.DeferredSellingProfitIncome [DeferredSellingProfitIncome],
ISNULL(T.[FAS91Expense],0.00),
ISNULL(T.[FAS91Income],0.00),
ISNULL(T.[OtherBlendedExpense],0.00),
ISNULL(T.[OtherBlendedIncome],0.00)
FROM #IncomeSchedules
LEFT JOIN
(SELECT
ISNULL(SUM(#BlendedIncomeSchedules.FAS91Expense),0.00) [FAS91Expense],
ISNULL(SUM(#BlendedIncomeSchedules.FAS91Income),0.00) [FAS91Income],
ISNULL(SUM(#BlendedIncomeSchedules.OtherBlendedExpense),0.00) [OtherBlendedExpense],
ISNULL(SUM(#BlendedIncomeSchedules.OtherBlendedIncome),0.00) [OtherBlendedIncome],
#BlendedIncomeSchedules.IncomeDate [IncomeDate]
FROM #IncomeSchedules
LEFT JOIN #BlendedIncomeSchedules ON #IncomeSchedules.IncomeDate = #BlendedIncomeSchedules.IncomeDate
GROUP BY #BlendedIncomeSchedules.IncomeDate
) T ON #IncomeSchedules.IncomeDate  = T.IncomeDate
END
SELECT
[IncomeDate] ,
[Payment] ,
[LeaseAssetIncome],
[FinanceAssetIncome],
[DeferredSellingProfitIncome],
[FAS91Expense] ,
[FAS91Income] ,
[OtherBlendedExpense] ,
[OtherBlendedIncome]
FROM #NonAccrualIncomeContractTypeLease
END

GO

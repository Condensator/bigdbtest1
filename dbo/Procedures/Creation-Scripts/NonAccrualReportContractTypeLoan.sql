SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[NonAccrualReportContractTypeLoan]
(
@FromDate DATE = NULL,
@ToDate DATE = NULL,
@SequenceNumber NVARCHAR(MAX)
)
AS
BEGIN
SET NOCOUNT ON
CREATE TABLE #NonAccrualIncomeContractTypeLoan
(
[IncomeDate] DATE NOT NULL,
[InterestAccrued] DECIMAL(16,2) NOT NULL ,
[Payment] DECIMAL(16,2) NOT NULL ,
[RentalIncome] DECIMAL(16,2) NOT NULL ,
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
IF @ContractType = 'Loan'
BEGIN
SELECT
LoanIncomeSchedules.IncomeDate,
LoanIncomeSchedules.Payment_Amount [Payment],
0.0 [RentalIncome],
LoanIncomeSchedules.InterestAccrued_Amount [InterestAccrued]
INTO #LoanIncomeSchedules
FROM  LoanFinances
INNER JOIN LoanIncomeSchedules ON LoanIncomeSchedules.LoanFinanceId = LoanFinances.Id
WHERE LoanIncomeSchedules.IsAccounting = 1
AND LoanFinances.IsCurrent = 1
AND LoanIncomeSchedules.IsGLPosted = 1
AND LoanIncomeSchedules.IsNonAccrual = 1
AND LoanFinances.ContractId = @ContractId
AND (@FromDate IS NULL OR @FromDate <= LoanIncomeSchedules.IncomeDate)
AND (@ToDate IS NULL OR @ToDate >= LoanIncomeSchedules.IncomeDate)
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
INTO #LoanBlendedIncomeSchedules
FROM  LoanFinances
LEFT JOIN LoanBlendedItems ON LoanFinances.Id = LoanBlendedItems.LoanFinanceId
LEFT JOIN BlendedItems ON LoanBlendedItems.BlendedItemId = BlendedItems.Id
LEFT JOIN BlendedIncomeSchedules ON BlendedIncomeSchedules.BlendedItemId = BlendedItems.Id
WHERE BlendedIncomeSchedules.IsAccounting = 1
AND BlendedIncomeSchedules.IsNonAccrual = 1
AND LoanFinances.IsCurrent = 1
AND LoanFinances.ContractId = @ContractId
AND BlendedIncomeSchedules.PostDate IS NOT NULL
AND BlendedIncomeSchedules.ReversalPostDate IS NULL
AND (@FromDate IS NULL OR @FromDate <= BlendedIncomeSchedules.IncomeDate)
AND (@ToDate IS NULL OR @ToDate >= BlendedIncomeSchedules.IncomeDate)
INSERT INTO #NonAccrualIncomeContractTypeLoan
(
[IncomeDate] ,
[InterestAccrued] ,
[Payment] ,
[RentalIncome] ,
[FAS91Expense] ,
[FAS91Income] ,
[OtherBlendedExpense] ,
[OtherBlendedIncome]
)
SELECT #LoanIncomeSchedules.IncomeDate,
#LoanIncomeSchedules.InterestAccrued  [InterestAccrued],
#LoanIncomeSchedules.Payment [Payment],
#LoanIncomeSchedules.RentalIncome [RentalIncome],
ISNULL(T.[FAS91Expense],0.00),
ISNULL(T.[FAS91Income],0.00),
ISNULL(T.[OtherBlendedExpense],0.00),
ISNULL(T.[OtherBlendedIncome],0.00)
FROM
#LoanIncomeSchedules
LEFT JOIN
(SELECT
ISNULL(SUM(#LoanBlendedIncomeSchedules.FAS91Expense),0.00) [FAS91Expense],
ISNULL(SUM(#LoanBlendedIncomeSchedules.FAS91Income),0.00) [FAS91Income],
ISNULL(SUM(#LoanBlendedIncomeSchedules.OtherBlendedExpense),0.00) [OtherBlendedExpense],
ISNULL(SUM(#LoanBlendedIncomeSchedules.OtherBlendedIncome),0.00) [OtherBlendedIncome],
#LoanBlendedIncomeSchedules.IncomeDate [IncomeDate]
FROM #LoanIncomeSchedules
LEFT JOIN #LoanBlendedIncomeSchedules ON #LoanIncomeSchedules.IncomeDate = #LoanBlendedIncomeSchedules.IncomeDate
GROUP BY #LoanBlendedIncomeSchedules.IncomeDate
) T ON #LoanIncomeSchedules.IncomeDate  = T.IncomeDate
END
SELECT
[IncomeDate] ,
[InterestAccrued] ,
[Payment] ,
[RentalIncome] ,
[FAS91Expense] ,
[FAS91Income] ,
[OtherBlendedExpense] ,
[OtherBlendedIncome]
FROM #NonAccrualIncomeContractTypeLoan
END

GO

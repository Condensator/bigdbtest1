SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateInterimAdjustmentDateFromDisbursementRequest]
(
@loanFinanceId LoanFinanceIds READONLY,
@paymentDate DATETIME,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET NOCOUNT ON;
BEGIN TRANSACTION;
BEGIN TRY
SELECT LF.Id, MAX(LIS.IncomeDate) 'IncomeDate', MAX(LF.InterimAdjustmentDate) 'InterimAdjDate'
INTO #TempTable
FROM Contracts C
JOIN LoanFinances LF ON C.Id = LF.ContractId
JOIN @loanFinanceId LI ON LF.Id = LI.LoanFinanceId
LEFT JOIN LoanIncomeSchedules LIS ON LF.Id = LIS.LoanFinanceId AND LIS.IsSchedule = 1
GROUP BY LF.Id;
UPDATE LoanFinances
SET InterimAdjustmentDate = (CASE
WHEN (TT.IncomeDate IS NULL) THEN (CASE
WHEN (TT.InterimAdjDate IS NULL OR TT.InterimAdjDate > @paymentDate) THEN @paymentDate
ELSE TT.InterimAdjDate
END)
WHEN (TT.InterimAdjDate IS NULL) THEN (CASE
WHEN (TT.IncomeDate > @paymentDate) THEN @paymentDate
ELSE TT.IncomeDate
END)
WHEN (TT.IncomeDate < TT.InterimAdjDate AND TT.IncomeDate < @paymentDate) THEN TT.IncomeDate
WHEN (TT.InterimAdjDate < @paymentDate) THEN TT.InterimAdjDate
ELSE @paymentDate
END),
FloatRateUpdateRunDate =(CASE
WHEN (TT.IncomeDate IS NULL) THEN (CASE
WHEN (TT.InterimAdjDate IS NULL OR TT.InterimAdjDate > @paymentDate) THEN @paymentDate
ELSE TT.InterimAdjDate
END)
WHEN (TT.InterimAdjDate IS NULL) THEN (CASE
WHEN (TT.IncomeDate > @paymentDate) THEN @paymentDate
ELSE TT.IncomeDate
END)
WHEN (TT.IncomeDate < TT.InterimAdjDate AND TT.IncomeDate < @paymentDate) THEN TT.IncomeDate
WHEN (TT.InterimAdjDate < @paymentDate) THEN TT.InterimAdjDate
ELSE @paymentDate
END),
UpdatedById = @UpdatedById,
UpdatedTime = @UpdatedTime
FROM LoanFinances LF
JOIN #TempTable TT ON LF.Id = TT.Id;
UPDATE LoanFinances
SET IsPricingParametersChanged = 1
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime
FROM LoanFinances
JOIN #TempTable ON LoanFinances.Id = #TempTable.Id
WHERE LoanFinances.InterimBillingType != '_' AND LoanFinances.FloatRateUpdateRunDate < LoanFinances.CommencementDate
DROP TABLE #TempTable;
END TRY
BEGIN CATCH
IF @@TRANCOUNT > 0
SELECT ERROR_MESSAGE() info,ERROR_LINE() linenumber
ROLLBACK TRANSACTION;
END CATCH;
IF @@TRANCOUNT > 0
COMMIT TRANSACTION;
END

GO

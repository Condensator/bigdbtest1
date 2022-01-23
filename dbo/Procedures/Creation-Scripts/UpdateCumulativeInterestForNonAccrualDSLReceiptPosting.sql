SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateCumulativeInterestForNonAccrualDSLReceiptPosting]
(
@ReceiptApplicationInfo ReceiptApplicationInfo	READONLY,
@ReceivableTypeValue_LoanInterest				NVARCHAR(12),
@UpdatedById									BIGINT,
@UpdatedTime									DATETIMEOFFSET,
@UniqueInstanceId								BIGINT,
@IsReversal										BIT
)
AS
BEGIN
SET NOCOUNT ON;
CREATE TABLE #ReceiptApplicationInfo
(
ReceiptId BIGINT,
ApplicationId BIGINT
);
CREATE TABLE #PaymentScheduleCumulativeInterestInfo
(
PaymentScheduleId					BIGINT,
CumulativeInterestAmountApplied		DECIMAL(16,2),
StartDate							DATE,
EndDate								DATE,
LoanFinanceId						BIGINT,
ContractId							BIGINT
);
INSERT INTO #ReceiptApplicationInfo(ReceiptId,ApplicationId)
SELECT ReceiptId,ApplicationId FROM @ReceiptApplicationInfo;
;WITH CTE_ContractPayments AS
(
SELECT RARD.ContractId, RARD.PaymentScheduleId, RARD.ReceivableId
FROM #ReceiptApplicationInfo ReceiptApplication
JOIN ReceiptReceivableDetails_Extract RARD ON ReceiptApplication.ReceiptId = RARD.ReceiptId
AND RARD.JobStepInstanceId = @UniqueInstanceId
WHERE RARD.FunderId IS NULL
AND RARD.ReceivableType = @ReceivableTypeValue_LoanInterest
GROUP BY ContractId,PaymentScheduleId,ReceivableId
)
SELECT
APR.ContractId,
R.PaymentScheduleId,
R.TotalBookBalance_Amount - R.TotalBalance_Amount AS InterestAmountApplied,
LPS.StartDate,
LPS.EndDate,
LPS.LoanFinanceId
INTO #ContractPaymentIdInfo
FROM CTE_ContractPayments APR
JOIN Receivables R ON APR.ReceivableId = R.Id
JOIN LoanPaymentSchedules LPS ON APR.PaymentScheduleId = LPS.Id
IF(@IsReversal = 0)
INSERT INTO #PaymentScheduleCumulativeInterestInfo
SELECT
PSI1.PaymentScheduleId,
SUM(PSI2.InterestAmountApplied) AS CumulativeInterestAmountApplied,
DATEADD(DAY, -1, PSI1.StartDate) AS StartDate,
DATEADD(DAY, -1, PSI1.EndDate) AS EndDate,
PSI1.LoanFinanceId	,
PSI1.ContractId
FROM #ContractPaymentIdInfo PSI1
JOIN #ContractPaymentIdInfo PSI2
ON
PSI1.ContractId = PSI2.ContractId
WHERE
PSI1.InterestAmountApplied != 0 AND
PSI1.StartDate >= PSI2.StartDate
GROUP BY
PSI1.PaymentScheduleId,
PSI1.StartDate,
PSI1.EndDate,
PSI1.LoanFinanceId,
PSI1.ContractId;
ELSE
INSERT INTO #PaymentScheduleCumulativeInterestInfo
SELECT
PSI1.PaymentScheduleId,
SUM(PSI2.InterestAmountApplied) AS CumulativeInterestAmountApplied,
DATEADD(DAY, -1, PSI1.StartDate) AS StartDate,
DATEADD(DAY, -1, PSI1.EndDate) AS EndDate,
PSI1.LoanFinanceId	,
PSI1.ContractId
FROM #ContractPaymentIdInfo PSI1
JOIN #ContractPaymentIdInfo PSI2
ON
PSI1.ContractId = PSI2.ContractId
WHERE
PSI1.StartDate >= PSI2.StartDate
GROUP BY
PSI1.PaymentScheduleId,
PSI1.StartDate,
PSI1.EndDate,
PSI1.LoanFinanceId,
PSI1.ContractId;
WITH CumulativeInterestAdvanceInfo AS
(
SELECT
PSCII.*,
LF.IsAdvance,
ROW_NUMBER() OVER(ORDER BY PSCII.StartDate) AS RowNumber
FROM #PaymentScheduleCumulativeInterestInfo PSCII
JOIN LoanFinances LF
ON PSCII.ContractId = LF.ContractId
WHERE LF.IsCurrent = 1
)
SELECT
CIAI1.*,
CASE
WHEN CIAI2.CumulativeInterestAmountApplied IS NULL THEN 0
ELSE CIAI2.CumulativeInterestAmountApplied
END AS PreviousCumulativeInterestAmountApplied
INTO #UpdationInfo
FROM CumulativeInterestAdvanceInfo CIAI1
LEFT JOIN CumulativeInterestAdvanceInfo CIAI2
ON CIAI1.RowNumber = CIAI2.RowNumber + 1
UPDATE LoanIncomeSchedules
SET CumulativeInterestAppliedToPrincipal_Amount =
(
CASE
WHEN UI.IsAdvance = 1 THEN UI.CumulativeInterestAmountApplied
ELSE UI.PreviousCumulativeInterestAmountApplied
END
)
FROM #UpdationInfo UI
JOIN LoanIncomeSchedules LIS ON UI.LoanFinanceId = LIS.LoanFinanceId
WHERE
(LIS.IncomeDate <= UI.EndDate AND LIS.IncomeDate >= UI.StartDate) AND
(LIS.IsAccounting = 1 OR LIS.IsSchedule = 1) AND LIS.IsLessorOwned = 1
;WITH RemainingUpdateInfo AS
(
SELECT
UI.LoanFinanceId,
MAX(UI.EndDate) AS MaxEndDate,
MAX(UI.CumulativeInterestAmountApplied) AS MaxCumulativeInterestAmountApplied
FROM #UpdationInfo UI
GROUP BY UI.LoanFinanceId
)
UPDATE LoanIncomeSchedules
SET CumulativeInterestAppliedToPrincipal_Amount = RUI.MaxCumulativeInterestAmountApplied
FROM RemainingUpdateInfo RUI
JOIN LoanIncomeSchedules LIS
ON RUI.LoanFinanceId = LIS.LoanFinanceId
WHERE LIS.IncomeDate > RUI.MaxEndDate
DROP TABLE #ReceiptApplicationInfo
DROP TABLE #ContractPaymentIdInfo
DROP TABLE #PaymentScheduleCumulativeInterestInfo
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetAccrualProcessorDataCacheInfo]
(
@AccrualDetailsInputInfo AccrualDetailsInputInfo READONLY
)
AS
BEGIN
SET NOCOUNT ON
SELECT DiscountingId,NonAccrualDate,ReAccrualDate INTO #SelectedDiscountings FROM @AccrualDetailsInputInfo
------DiscountingAmortizationSchedule Info
SELECT
DA.*,
SD.DiscountingId
INTO #DiscountingAmortTable
FROM DiscountingAmortizationSchedules DA
JOIN DiscountingFinances DF ON DA.DiscountingFinanceId = DF.Id
JOIN #SelectedDiscountings SD ON DF.DiscountingId = SD.DiscountingId
WHERE DF.ApprovalStatus = 'Approved'
AND DA.IsSchedule =1
------Discounting Repayment Schedule Info
SELECT
DR.*,
SD.DiscountingId
INTO #DiscountingRepaymentScheduleTable
FROM DiscountingRepaymentSchedules DR
JOIN DiscountingFinances DF ON DR.DiscountingFinanceId = DF.Id
JOIN #SelectedDiscountings SD ON DF.DiscountingId = SD.DiscountingId
WHERE IsCurrent=1
AND DR.IsActive = 1
------Discounting Payable Info
SELECT
SD.DiscountingId,
DR.DueDate,
TP.Balance_Amount
INTO #DiscountingPayableTable
FROM DiscountingRepaymentSchedules DR
JOIN DiscountingFinances DF ON DR.DiscountingFinanceId = DF.Id
JOIN #SelectedDiscountings SD ON DF.DiscountingId = SD.DiscountingId
JOIN DiscountingSundries DS ON DR.Id = DS.PaymentScheduleId
JOIN Sundries S ON DS.Id = S.Id
JOIN Payables P ON S.PayableId = P.Id
JOIN TreasuryPayableDetails TPD ON P.Id = TPD.PayableId
JOIN TreasuryPayables TP ON TPD.TreasuryPayableId = TP.Id
WHERE S.IsActive = 1
AND DF.IsCurrent = 1
AND P.Status <> 'InActive'
AND TP.Status <> 'InActive'
AND TPD.IsActive = 1
-------Suspense Income
SELECT
DA.*,
SD.DiscountingId
INTO #SuspendedIncomesForReAccrual
FROM DiscountingAmortizationSchedules DA
JOIN DiscountingFinances DF ON DA.DiscountingFinanceId = DF.Id
JOIN #SelectedDiscountings SD ON DF.DiscountingId = SD.DiscountingId
WHERE SD.ReAccrualDate IS NOT NULL
AND DA.ExpenseDate >= SD.NonAccrualDate
AND DA.ExpenseDate < SD.ReAccrualDate
AND IsSchedule =1
AND IsNonAccrual=1
------GLFinancialOpenPeriod For LegalEntities
SELECT
GLF.FromDate,
SD.DiscountingId
INTO #GLFinancialOpenPeriodForLegalEntities
FROM DiscountingFinances DF
JOIN  #SelectedDiscountings SD ON DF.DiscountingId = SD.DiscountingId
JOIN GLFinancialOpenPeriods GLF ON DF.LegalEntityId = GLF.LegalEntityId
WHERE GLF.IsCurrent =1
AND DF.IsCurrent =1
-------------------------------------------------------------------------------------------------------------------------------
SELECT * FROM #DiscountingAmortTable
SELECT * FROM #DiscountingRepaymentScheduleTable
SELECT * FROM #SuspendedIncomesForReAccrual
SELECT * FROM #DiscountingPayableTable
SELECT * FROM #GLFinancialOpenPeriodForLegalEntities
-----------------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#DiscountingAmortTable') IS NOT NULL
DROP TABLE #DiscountingAmortTable
IF OBJECT_ID('tempdb..#DiscountingRepaymentScheduleTable') IS NOT NULL
DROP TABLE #DiscountingRepaymentScheduleTable
IF OBJECT_ID('tempdb..#DiscountingPayableTable') IS NOT NULL
DROP TABLE #DiscountingPayableTable
IF OBJECT_ID('tempdb..#SuspendedIncomesForReAccrual') IS NOT NULL
DROP TABLE #SuspendedIncomesForReAccrual
IF OBJECT_ID('tempdb..#GLFinancialOpenPeriodForLegalEntities') IS NOT NULL
DROP TABLE #GLFinancialOpenPeriodForLegalEntities
END

GO

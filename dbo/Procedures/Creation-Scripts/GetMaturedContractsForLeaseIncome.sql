SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetMaturedContractsForLeaseIncome]
(
@JobStepInstanceId BIGINT
) AS
BEGIN

;WITH Leases_Without_OTP (LeaseFinanceId)
AS
(
SELECT le.LeaseFinanceId
FROM LeaseIncomeRecognitionJob_Extracts le
JOIN LeaseFinanceDetails lfd on le.LeaseFinanceId = lfd.Id
JOIN LeaseIncomeSchedules li on lfd.Id = li.LeaseFinanceId
WHERE JobStepInstanceId = @JobStepInstanceId
GROUP BY le.LeaseFinanceId, lfd.MaturityDate HAVING MAX(li.IncomeDate) <= lfd.MaturityDate
)
SELECT lf.ContractId
FROM LeaseIncomeRecognitionJob_Extracts le
JOIN LeaseFinances lf ON le.LeaseFinanceId = lf.Id
JOIN Leases_Without_OTP ON lf.Id = Leases_Without_OTP.LeaseFinanceId
JOIN LeaseIncomeSchedules li on Leases_Without_OTP.LeaseFinanceId = li.LeaseFinanceId
WHERE le.JobStepInstanceId = @JobStepInstanceId
AND lf.IsCurrent = 1 AND li.IsAccounting = 1
AND li.AdjustmentEntry = 0 AND li.AccountingTreatment <> 'CashBased'
GROUP BY lf.ContractId HAVING COUNT(li.IsGLPosted) = SUM(CAST(li.IsGLPosted as int))

END

GO

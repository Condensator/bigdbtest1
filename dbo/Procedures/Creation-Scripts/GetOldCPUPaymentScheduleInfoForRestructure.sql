SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetOldCPUPaymentScheduleInfoForRestructure]
(
@CPUFinanceId BIGINT
)
AS
BEGIN
SET NOCOUNT ON;
/*CPU Payment Schedule Info*/
SELECT
CPUSchedules.ScheduleNumber,
CPUPaymentSchedules.PaymentNumber,
CPUPaymentSchedules.StartDate,
CPUPaymentSchedules.EndDate,
CPUPaymentSchedules.DueDate,
CPUPaymentSchedules.Amount_Amount AS Amount,
CPUPaymentSchedules.Units,
CPUPaymentSchedules.PaymentType,
CPUPaymentSchedules.Id AS PaymentScheduleId
FROM CPUPaymentSchedules
JOIN CPUSchedules ON CPUPaymentSchedules.CPUBaseStructureId = CPUSchedules.Id
WHERE CPUPaymentSchedules.IsActive = 1
AND CPUSchedules.IsActive = 1
AND CPUSchedules.CPUFinanceId = @CPUFinanceId
SET NOCOUNT OFF;
END

GO

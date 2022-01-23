SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[FillFloatRateRequiredEntities](
@ContractDetails ContractDetail READONLY,
@AccrualApprovalStatusValues_Inactive NVARCHAR(10),
@AccrualApprovalStatusValues_Approved NVARCHAR(10),
@ReceivableEntityTypeValues_CT NVARCHAR(3)
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT DISTINCT LegalEntityId INTO #LegalEntityIds FROM @ContractDetails
--FloatRateNonAccrualDates
SELECT
ContractId = NonAccrualContracts.ContractId,
NonAccrualDate = MAX(NonAccrualContracts.NonAccrualDate)
FROM NonAccruals
JOIN NonAccrualContracts ON NonAccruals.Id = NonAccrualContracts.NonAccrualId
JOIN @ContractDetails AS contractDetail ON NonAccrualContracts.ContractId = contractDetail.ContractId
WHERE NonAccrualContracts.IsActive = 1
AND NonAccruals.[Status] != @AccrualApprovalStatusValues_Inactive
GROUP BY NonAccrualContracts.ContractId
--FloatRateReAccrualDates
SELECT ContractId = ReAccrualContracts.ContractId, ReAccrualDate = MAX(ReAccrualContracts.ReAccrualDate)
FROM ReAccruals
JOIN ReAccrualContracts ON ReAccruals.Id = ReAccrualContracts.ContractId
JOIN @ContractDetails AS contractDetail ON ReAccrualContracts.ContractId = contractDetail.ContractId
WHERE ReAccrualContracts.IsActive = 1
AND ReAccruals.[Status] = @AccrualApprovalStatusValues_Approved
GROUP BY ReAccrualContracts.ContractId
--FloatRateOpenPeriod
SELECT LegalEntityId = legalEntityId.LegalEntityId, OpenPeriodStartDate = GLFinancialOpenPeriods.FromDate, OpenPeriodEndDate = GLFinancialOpenPeriods.ToDate
FROM GLFinancialOpenPeriods
JOIN #LegalEntityIds AS legalEntityId ON GLFinancialOpenPeriods.LegalEntityId = legalEntityId.LegalEntityId
WHERE GLFinancialOpenPeriods.IsCurrent = 1
--LeaseFinanceFloatRateReceivables
SELECT ContractId = contractDetail.ContractId,
ReceivableId = Receivables.Id,
StartDate = LeasePaymentSchedules.StartDate,
FloatRateARReceivableCodeId = contractDetail.FloatRateReceivableCodeId
FROM Receivables
JOIN LeasePaymentSchedules ON Receivables.PaymentScheduleId = LeasePaymentSchedules.Id
JOIN @ContractDetails AS contractDetail
ON Receivables.EntityId = contractDetail.ContractId
AND Receivables.ReceivableCodeId = contractDetail.FloatRateReceivableCodeId
WHERE Receivables.EntityType = @ReceivableEntityTypeValues_CT
AND Receivables.IsActive = 1
AND LeasePaymentSchedules.IsActive = 1
END

GO

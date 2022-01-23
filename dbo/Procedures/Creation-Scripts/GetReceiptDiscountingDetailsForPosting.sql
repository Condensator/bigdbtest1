SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetReceiptDiscountingDetailsForPosting]
(
@ContractIds IdCollection	READONLY,
@JobStepInstanceId			BIGINT
)
AS
BEGIN
SET NOCOUNT ON;
SELECT DC.ContractId,
DC.DiscountingId,
DC.DiscountingFinanceId,
DC.SharedPercentage,
DC.BookedResidual,
DC.ResidualBalance,
DC.IncludeResidual,
DC.DiscountingContractId,
DC.PaymentAllocation,
DC.MaturityDate,
DC.FunderId,
DC.LegalEntityId,
DC.InstrumentTypeId,
DC.LineOfBusinessId,
DC.CostCenterId,
DC.BranchId,
DC.PayableRemitToId,
DC.CurrencyId,
DC.Currency,
DC.InterestPayableCodeId,
DC.PrincipalPayableCodeId,
DC.ResidualRepaymentId,
DC.ResidualAmountUtilized
FROM @ContractIds C
JOIN ReceiptDiscountingContracts_Extract DC ON DC.JobStepInstanceId = @JobStepInstanceId AND C.Id = DC.ContractId;
SELECT RS.ContractId,
RS.DiscountingId,
RS.DiscountingFinanceId,
RS.RepaymentScheduleId,
RS.StartDate,
RS.EndDate,
RS.DueDate,
RS.Principal,
RS.Interest,
RS.PrincipalProcessed,
RS.InterestProcessed,
RS.TiedContractPaymentDetailId,
RS.PaymentScheduleId,
RS.SharedAmount,
RS.Balance,
P.ReceivableBalance
FROM @ContractIds C
JOIN ReceiptDiscountingRepaymentSchedules_Extract RS ON RS.JobStepInstanceId = @JobStepInstanceId AND C.Id = RS.ContractId
LEFT JOIN ( SELECT RS.PaymentScheduleId, ContractId, SUM(R.TotalBalance_Amount) ReceivableBalance
FROM (SELECT PaymentScheduleId,ContractId
FROM ReceiptDiscountingRepaymentSchedules_Extract RS
GROUP BY PaymentScheduleId,ContractId) RS
JOIN Receivables R ON RS.PaymentScheduleId = R.PaymentScheduleId and R.EntityId = RS.ContractId
GROUP BY RS.PaymentScheduleId, ContractId
) P ON RS.PaymentScheduleId = P.PaymentScheduleId and RS.ContractId = P.ContractId
END

GO

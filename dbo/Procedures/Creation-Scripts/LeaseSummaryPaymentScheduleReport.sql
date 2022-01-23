SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[LeaseSummaryPaymentScheduleReport]
(
@SequenceNumber  NVARCHAR(40)
)
AS
BEGIN
SELECT
LeasePaymentSchedules.PaymentNumber,
LeasePaymentSchedules.DueDate,
LeasePaymentSchedules.StartDate,
LeasePaymentSchedules.EndDate,
LeasePaymentSchedules.Amount_Amount,
LeasePaymentSchedules.Amount_Currency,
LeasePaymentSchedules.PaymentType
FROM
Contracts
INNER JOIN
LeaseFinances ON Contracts.Id = LeaseFinances.ContractId AND LeaseFinances.IsCurrent = 1
INNER JOIN
LeaseFinanceDetails  ON LeaseFinances.Id = LeaseFinanceDetails.Id
INNER JOIN
LeasePaymentSchedules ON LeaseFinanceDetails.Id = LeasePaymentSchedules.LeaseFinanceDetailId AND LeasePaymentSchedules.IsActive=1
WHERE
Contracts.SequenceNumber=@SequenceNumber
AND (LeasePaymentSchedules.PaymentType <> 'ThirdPartyGuaranteedResidual' OR LeasePaymentSchedules.Amount_Amount<>0)
AND (LeasePaymentSchedules.PaymentType <> 'CustomerGuaranteedResidual' OR LeasePaymentSchedules.Amount_Amount<>0)
ORDER BY
LeasePaymentSchedules.StartDate,LeasePaymentSchedules.PaymentNumber
END

GO

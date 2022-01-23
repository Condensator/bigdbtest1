SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateTiedContractPaymentDetails]
(
@ContractId BIGINT,
@paymentScheduleUpdateTempTable PaymentScheduleUpdateTempTable READONLY
)
AS
BEGIN
SET NOCOUNT ON;
MERGE TiedContractPaymentDetails AS TCPD
USING @paymentScheduleUpdateTempTable AS PaymentScheduleDetail
ON (TCPD.PaymentScheduleId = PaymentScheduleDetail.OldPaymentScheduleId  AND TCPD.ContractId = @ContractId)
WHEN MATCHED THEN
UPDATE SET
TCPD.PaymentScheduleId = PaymentScheduleDetail.NewPaymentScheduleId,
TCPD.UpdatedById = PaymentScheduleDetail.UpdatedById,
TCPD.UpdatedTime = PaymentScheduleDetail.UpdatedTime;
END

GO

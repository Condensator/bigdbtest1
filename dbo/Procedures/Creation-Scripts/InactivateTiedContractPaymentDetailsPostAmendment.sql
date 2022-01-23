SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[InactivateTiedContractPaymentDetailsPostAmendment]
(
@PaymentSchedulesToInactivate PaymentSchedulesToInactivate READONLY,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
UPDATE [TCPD]
SET
[TCPD].[IsActive] = 0,
[TCPD].[UpdatedById] = @UpdatedById,
[TCPD].[UpdatedTime] = @UpdatedTime
FROM TiedContractPaymentDetails [TCPD]
JOIN @PaymentSchedulesToInactivate PS ON [TCPD].PaymentScheduleId = PS.PaymentScheduleId
WHERE [TCPD].IsActive = 1
AND [TCPD].ContractId = PS.ContractId
SET NOCOUNT OFF;
END

GO

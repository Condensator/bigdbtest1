SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateTiedContractPaymentDetailsPaymentSchedule]
(
@IsLease BIT,
@NewFinanceId BIGINT,
@ContractId BIGINT,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
IF(@IsLease = 1)
BEGIN
UPDATE [TCPD]
SET
[TCPD].[PaymentScheduleId] = [LP_NEW].[Id],
[TCPD].[UpdatedById] = @UpdatedById,
[TCPD].[UpdatedTime] = @UpdatedTime
FROM
TiedContractPaymentDetails [TCPD]
JOIN LeaseFinances [LF] ON [TCPD].ContractId=[LF].ContractId
JOIN [dbo].[LeasePaymentSchedules] [LP_OLD] ON [TCPD].[PaymentScheduleId] = [LP_OLD].[Id]
JOIN [dbo].[LeasePaymentSchedules] [LP_NEW] ON [LP_OLD].[StartDate] = [LP_NEW].[StartDate] AND [LP_OLD].[EndDate] = [LP_NEW].[EndDate]
AND [LP_OLD].[PaymentType] = [LP_NEW].[PaymentType] AND  [LP_NEW].LeaseFinanceDetailId=@NewFinanceId
JOIN DiscountingContracts [DC] ON [TCPD].ContractId=[DC].ContractId
JOIN DiscountingFinances [DF] ON [DC].DiscountingFinanceId=[DF].Id
WHERE [TCPD].IsActive=1 and [DF].Tied=1 and [LF].ContractId=@ContractId
AND [LP_NEW].[IsActive] = 1
AND [LP_NEW].[LeaseFinanceDetailId] = @NewFinanceId
AND [DF].ApprovalStatus='Approved'
END
ELSE
BEGIN
UPDATE [TCPD]
SET
[TCPD].[PaymentScheduleId] = [LP_NEW].[Id],
[TCPD].[UpdatedById] = @UpdatedById,
[TCPD].[UpdatedTime] = @UpdatedTime
FROM
TiedContractPaymentDetails [TCPD]
JOIN LoanFinances [LF] ON [TCPD].ContractId=[LF].ContractId
JOIN [dbo].[LoanPaymentSchedules] [LP_OLD] ON [TCPD].[PaymentScheduleId] = [LP_OLD].[Id]
JOIN [dbo].[LoanPaymentSchedules] [LP_NEW] ON [LP_OLD].[StartDate] = [LP_NEW].[StartDate] AND [LP_OLD].[EndDate] = [LP_NEW].[EndDate]
AND [LP_OLD].[PaymentType] = [LP_NEW].[PaymentType] AND  [LP_NEW].LoanFinanceId = @NewFinanceId
JOIN DiscountingContracts [DC] ON [TCPD].ContractId=[DC].ContractId
JOIN DiscountingFinances [DF] ON [DC].DiscountingFinanceId=[DF].Id
WHERE [TCPD].IsActive=1 and [DF].Tied=1 and [LF].ContractId=@ContractId
AND [LP_NEW].[IsActive] = 1
AND [LP_NEW].[LoanFinanceId] = @NewFinanceId
AND [DF].ApprovalStatus='Approved'
END
SET NOCOUNT OFF;
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdatePaymentScheduleIdForReversal] (
@EntityType NVARCHAR(50),
@EntityId BIGINT,
@OldLeaseFinanceDetailId BIGINT,
@PayoffLeaseFinanceDetailId BIGINT,
@TillDate DATETIME
)
AS
SET NOCOUNT ON
UPDATE [R] SET [R].[PaymentScheduleId] = [LP_OLD].Id
--SELECT [R].Id,[R].PaymentScheduleId,[LP_OLD].Id As OldPaymentScheduleId,[R].TotalAmount_Amount,[LP_OLD].[StartDate]
FROM
[dbo].[Receivables] [R]
JOIN [dbo].[ReceivableCodes] [RC] ON [R].[ReceivableCodeId] = [RC].[Id]
JOIN [dbo].[ReceivableTypes] [RT] ON [RC].[ReceivableTypeId] = [RT].[Id]
JOIN [dbo].[LeasePaymentSchedules] [LP_NEW] ON [R].[PaymentScheduleId] = [LP_NEW].[Id]
JOIN [dbo].[LeasePaymentSchedules] [LP_OLD] ON [LP_OLD].[StartDate] = [LP_NEW].[StartDate] AND [LP_OLD].[EndDate] = [LP_NEW].[EndDate] AND [LP_OLD].[PaymentType] = [LP_NEW].[PaymentType]
--JOIN [dbo].[LeasePaymentSchedules] [LP_OLD] ON [R].[PaymentScheduleId] = [LP_OLD].[Id]
--JOIN [dbo].[LeasePaymentSchedules] [LP_NEW] ON [LP_OLD].[StartDate] = [LP_NEW].[StartDate] AND [LP_OLD].[EndDate] = [LP_NEW].[EndDate] AND [LP_OLD].[PaymentType] = [LP_NEW].[PaymentType]
WHERE
[LP_NEW].[IsActive] = 1
--AND [R].[IsActive] = 1
AND [R].[EntityType] = @EntityType --'CT'
AND [R].[EntityId] = @EntityId --119964
AND [LP_NEW].[LeaseFinanceDetailId] = @PayoffLeaseFinanceDetailId --88836 -- Which is created in the Payoff
AND [LP_OLD].[LeaseFinanceDetailId] = @OldLeaseFinanceDetailId --88825 -- Which is going to be IsCurrent = True
AND [LP_OLD].[IsActive] = 1
--AND [LP_OLD].[StartDate] <= @TillDate --'2016-03-01'

GO

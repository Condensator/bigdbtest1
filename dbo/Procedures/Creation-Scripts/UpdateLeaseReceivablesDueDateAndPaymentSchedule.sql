SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateLeaseReceivablesDueDateAndPaymentSchedule]
(
@EntityType NVARCHAR(50),
@EntityId BIGINT,
@LeaseFinanceDetailId BIGINT,
@PaymentType NVARCHAR(50),
@TillDate DATETIME,
@IsServiced BIT,
@IsCollected BIT
)
AS
BEGIN
SET NOCOUNT ON
UPDATE [R]
SET
[R].[PaymentScheduleId] = [LP_NEW].[Id],
[R].[DueDate] = [LP_NEW].[DueDate],
[R].[IsServiced] = @IsServiced,
[R].[IsCollected] = @IsCollected
FROM
[dbo].[Receivables] [R]
JOIN [dbo].[LeasePaymentSchedules] [LP_OLD] ON [R].[PaymentScheduleId] = [LP_OLD].[Id]
JOIN [dbo].[LeasePaymentSchedules] [LP_NEW] ON [LP_OLD].[StartDate] = [LP_NEW].[StartDate] AND [LP_OLD].[EndDate] = [LP_NEW].[EndDate]
WHERE
[LP_OLD].[IsActive] = 0
AND [LP_NEW].[IsActive] = 1
AND [R].[IsActive] = 1
AND [LP_OLD].[PaymentType] = @PaymentType
AND [LP_NEW].[PaymentType] = @PaymentType
AND [LP_OLD].[LeaseFinanceDetailId] = @LeaseFinanceDetailId
AND [LP_NEW].[LeaseFinanceDetailId] = @LeaseFinanceDetailId
AND [LP_OLD].[StartDate] <= @TillDate
AND [R].[EntityType]=@EntityType
AND [R].[EntityId]=@EntityId
END

GO

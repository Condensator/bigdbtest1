SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateNewDiscountingFinanceDetails]
(
@OldDiscountingFinanceId BIGINT,
@NewDiscountingFinanceId BIGINT,
@UserId BIGINT,
@ModificationTime DATETIMEOFFSET
)
AS
BEGIN
UPDATE [DiscountingSundry]
SET [DiscountingSundry].[PaymentScheduleId] = [DRP_NEW].[Id],
[DiscountingSundry].[UpdatedById]=@UserId,
[DiscountingSundry].[UpdatedTime]= @ModificationTime
FROM [dbo].[DiscountingSundries] [DiscountingSundry]
JOIN Sundries [Sundry] ON [DiscountingSundry].Id = [Sundry].Id
JOIN [dbo].[DiscountingRepaymentSchedules] [DRP_OLD] ON [DiscountingSundry].[PaymentScheduleId] = [DRP_OLD].[Id]
JOIN [dbo].[DiscountingRepaymentSchedules] [DRP_NEW] ON [DRP_OLD].[PaymentNumber] = [DRP_NEW].[PaymentNumber] AND [DRP_OLD].[PaymentType] = [DRP_NEW].[PaymentType]
WHERE
[DRP_OLD].[DiscountingFinanceId] = @OldDiscountingFinanceId
AND [DRP_NEW].[DiscountingFinanceId] = @NewDiscountingFinanceId
AND [Sundry].[IsActive] = 1
AND [DRP_OLD].[IsActive] = 1
AND [DRP_NEW].[IsActive] = 1
END

GO

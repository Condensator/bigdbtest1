SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateDiscountingPayables]
(
@DiscountingFinanceId BIGINT,
@RemitToId BIGINT,
@UserId BIGINT,
@ModificationTime DATETIMEOFFSET
)
AS
BEGIN
CREATE TABLE #UpdatedPayables
(
PayableId BIGINT,
SundryId BIGINT
);
UPDATE Payables
SET RemitToId = @RemitToId,
UpdatedById = @UserId,
UpdatedTime = @ModificationTime
OUTPUT DELETED.Id AS PayableId,DELETED.SourceId AS SundryId INTO #UpdatedPayables
FROM Payables
JOIN Sundries ON Payables.Id = Sundries.PayableId
JOIN DiscountingSundries ON Sundries.Id = DiscountingSundries.Id
JOIN DiscountingRepaymentSchedules ON DiscountingSundries.PaymentScheduleId = DiscountingRepaymentSchedules.Id
WHERE DiscountingRepaymentSchedules.DiscountingFinanceId = @DiscountingFinanceId
AND DiscountingRepaymentSchedules.IsActive=1
AND Sundries.IsActive=1
AND Payables.Status = 'Pending'
UPDATE Sundries
SET PayableRemitToId = @RemitToId,
UpdatedById = @UserId,
UpdatedTime = @ModificationTime
FROM Sundries
JOIN #UpdatedPayables ON Sundries.Id = #UpdatedPayables.SundryId
WHERE IsActive=1
DROP TABLE #UpdatedPayables
END

GO

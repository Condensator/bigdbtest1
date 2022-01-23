SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateDiscountingAmortizationSchedules]
(
@DiscountingGLTransferDate DATE,
@DiscountingId BIGINT,
@FinanceId BIGINT,
@ExpenseDate DATETIME,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
UPDATE DAS SET DAS.DiscountingFinanceId = @FinanceId , DAS.UpdatedById = @UpdatedById, DAS.UpdatedTime = @UpdatedTime
FROM DiscountingAmortizationSchedules DAS
JOIN DiscountingFinances DF ON DAS.DiscountingFinanceId = DF.Id
WHERE DF.DiscountingId = @DiscountingId AND DAS.ExpenseDate > @ExpenseDate
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateRestructuredLeaseReceivablesPaymentScheduleId]
(
@EntityType NVARCHAR(50),
@EntityId BIGINT,
@OldLeaseFinanceDetailId BIGINT,
@NewLeaseFinanceDetailId BIGINT,
@PaymentTypes NVARCHAR(150),
@TillDate DATETIME,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
SELECT Item INTO #PaymentTypes FROM ConvertCSVToStringTable(@PaymentTypes, ',');
UPDATE R
SET R.PaymentScheduleId = LP_NEW.Id,
R.UpdatedById = @UpdatedById,
R.UpdatedTime = @UpdatedTime
FROM dbo.Receivables R
JOIN dbo.LeasePaymentSchedules LP_OLD ON R.PaymentScheduleId = LP_OLD.Id
JOIN dbo.LeasePaymentSchedules LP_NEW ON LP_OLD.StartDate = LP_NEW.StartDate AND LP_OLD.EndDate = LP_NEW.EndDate AND LP_OLD.PaymentNumber = LP_NEW.PaymentNumber
JOIN #PaymentTypes PaymentType ON LP_OLD.PaymentType = PaymentType.Item AND LP_NEW.PaymentType = PaymentType.Item
WHERE LP_OLD.IsActive = 1
AND LP_NEW.IsActive = 1
AND R.IsActive = 1
AND LP_OLD.LeaseFinanceDetailId = @OldLeaseFinanceDetailId
AND LP_NEW.LeaseFinanceDetailId = @NewLeaseFinanceDetailId
AND LP_OLD.StartDate <= @TillDate
AND R.EntityType = @EntityType
AND R.EntityId = @EntityId
;
SET NOCOUNT OFF
END

GO

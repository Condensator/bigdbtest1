SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdatePreviousAmortSchedulesFromAdjustment]
(
@AmortizationScheduleIds AmortizationSchedulesToUpdate READONLY,
@CapitalizedInterestIds CapitalizedInterestIdsToUpdate READONLY,
@KeepOldAmortActive BIT,
@OpenPeriodStartDate DATETIME = NULL,
@LoggedInUserId BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
IF @KeepOldAmortActive = 0
BEGIN
UPDATE DAS
SET DAS.IsSchedule = 0,
DAS.IsAccounting = CASE WHEN @OpenPeriodStartDate IS NULL OR DAS.ExpenseDate >= @OpenPeriodStartDate THEN 0 ELSE DAS.IsAccounting END,
UpdatedTime = @UpdatedTime,
UpdatedById = @LoggedInUserId
FROM DiscountingAmortizationSchedules DAS
JOIN @AmortizationScheduleIds ASId ON DAS.Id = ASId.Id
UPDATE DCI
SET DCI.IsActive = 0,
UpdatedTime = @UpdatedTime,
UpdatedById = @LoggedInUserId
FROM DiscountingCapitalizedInterests DCI
JOIN @CapitalizedInterestIds CapInterest ON DCI.Id = CapInterest.Id
END
ELSE
BEGIN
UPDATE DAS
SET DAS.IsSchedule = 0,
UpdatedTime = @UpdatedTime,
UpdatedById = @LoggedInUserId
FROM DiscountingAmortizationSchedules DAS
JOIN @AmortizationScheduleIds ASId ON DAS.Id = ASId.Id
WHERE (@OpenPeriodStartDate IS NOT NULL OR DAS.ExpenseDate < @OpenPeriodStartDate)
END
END

GO

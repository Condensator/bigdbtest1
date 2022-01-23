SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[InactivateLeaseIncomeSchedulesFromPayoffRev]
(
@LeaseIncomeScheduleIds LeaseIncomeScheduleRevType READONLY,
@KeepOldIncomeActive BIT,
@OpenPeriodStartDate DATETIME = NULL,
@LoggedInUserId BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
IF @KeepOldIncomeActive = 0
BEGIN
UPDATE LI SET LI.IsSchedule = 0, UpdatedTime = @UpdatedTime, UpdatedById = @LoggedInUserId
FROM LeaseIncomeSchedules LI
JOIN @LeaseIncomeScheduleIds SLI ON LI.Id = SLI.Id
UPDATE AI SET AI.IsActive = 0, UpdatedTime = @UpdatedTime, UpdatedById = @LoggedInUserId
FROM AssetIncomeSchedules AI
JOIN @LeaseIncomeScheduleIds SLI ON AI.LeaseIncomeScheduleId = SLI.Id
END
UPDATE LI SET LI.IsAccounting = 0, IsGLPosted = 0, PostDate = NULL,  UpdatedTime = @UpdatedTime, UpdatedById = @LoggedInUserId
FROM LeaseIncomeSchedules LI
JOIN @LeaseIncomeScheduleIds SLI ON LI.Id = SLI.Id
WHERE (@OpenPeriodStartDate IS NULL OR LI.IncomeDate >= @OpenPeriodStartDate)
END

GO

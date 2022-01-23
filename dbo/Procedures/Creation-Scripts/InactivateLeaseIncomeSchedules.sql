SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InactivateLeaseIncomeSchedules]
(
@LeaseIncomeScheduleIds LeaseIncomeScheduleType READONLY,
@KeepOldIncomeActive BIT,
@OpenPeriodStartDate DATETIME = NULL,
@LoggedInUserId BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON


CREATE TABLE #LeaseIncomeScheduleIds
(
Id BIGINT
)

CREATE CLUSTERED INDEX IX_LeaseIncomeScheduleIds ON #LeaseIncomeScheduleIds (Id)

INSERT INTO #LeaseIncomeScheduleIds(Id)
SELECT Id FROM @LeaseIncomeScheduleIds

IF @KeepOldIncomeActive = 0
BEGIN
	UPDATE LI SET LI.IsSchedule = 0, UpdatedTime = @UpdatedTime, UpdatedById = @LoggedInUserId
	FROM LeaseIncomeSchedules LI
	JOIN #LeaseIncomeScheduleIds SLI ON LI.Id = SLI.Id

	IF (@OpenPeriodStartDate IS NULL)
	BEGIN
		UPDATE AI SET AI.IsActive = 0, UpdatedTime = @UpdatedTime, UpdatedById = @LoggedInUserId
		FROM AssetIncomeSchedules AI
		JOIN #LeaseIncomeScheduleIds SLI ON AI.LeaseIncomeScheduleId = SLI.Id
	END
	ELSE
	BEGIN
		UPDATE AI SET AI.IsActive = 0, UpdatedTime = @UpdatedTime, UpdatedById = @LoggedInUserId
		FROM AssetIncomeSchedules AI
		JOIN #LeaseIncomeScheduleIds SLI ON AI.LeaseIncomeScheduleId = SLI.Id
		JOIN LeaseIncomeSchedules LIS ON SLI.Id = LIS.Id
		WHERE LIS.IncomeDate >= @OpenPeriodStartDate
	END 

END

	IF (@OpenPeriodStartDate IS NULL)
	BEGIN
		UPDATE LI SET LI.IsAccounting = 0, IsGLPosted = 0, PostDate = NULL,  UpdatedTime = @UpdatedTime, UpdatedById = @LoggedInUserId
		FROM LeaseIncomeSchedules LI
		JOIN #LeaseIncomeScheduleIds SLI ON LI.Id = SLI.Id

	END
	ELSE
	BEGIN
		UPDATE LI SET LI.IsAccounting = 0, IsGLPosted = 0, PostDate = NULL,  UpdatedTime = @UpdatedTime, UpdatedById = @LoggedInUserId
		FROM LeaseIncomeSchedules LI
		JOIN #LeaseIncomeScheduleIds SLI ON LI.Id = SLI.Id
		WHERE LI.IncomeDate >= @OpenPeriodStartDate
	END 
END

GO

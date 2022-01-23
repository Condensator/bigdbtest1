SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[InactivateIncomeRecordsForReaccrual]
(
@IncomeSchedules IncomeScheduleIds READONLY,
@IsInClosedPeriod bit,
@UserId BIGINT,
@Time DATETIMEOFFSET
)
AS
BEGIN
UPDATE LoanIncomeSchedules
SET
IsSchedule = 0,
IsGLPosted = Case When @IsInClosedPeriod  = 1 then IsGLPosted else 0 end,
IsAccounting = Case When @IsInClosedPeriod  = 1 then IsAccounting else 0 end,
UpdatedById = @UserId,
UpdatedTime = @Time
where LoanIncomeSchedules.Id in(select * from @IncomeSchedules)
END

GO

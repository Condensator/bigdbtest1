SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[InactivateIncomeRecords]
(
@IncomeSchedules IncomeScheduleIdCollection READONLY,
@IsAccounting bit,
@CanSetGLFlag bit,
@UserId BIGINT,
@Time DATETIMEOFFSET
)
AS
BEGIN
UPDATE LoanIncomeSchedules
SET
IsSchedule = 0,
IsGLPosted = Case When @CanSetGLFlag  = 1 then 0 else IsGLPosted end,
IsAccounting = @IsAccounting,
UpdatedById = @UserId,
UpdatedTime = @Time
where LoanIncomeSchedules.Id in(select * from @IncomeSchedules)
END

GO

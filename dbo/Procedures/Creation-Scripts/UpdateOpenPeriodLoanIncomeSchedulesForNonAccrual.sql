SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateOpenPeriodLoanIncomeSchedulesForNonAccrual]
(
@LoanIncomeScheduleIds LoanIncomeScheduleIdInfoForNA READONLY,
@UserId BIGINT,
@ModificationTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
UPDATE LI SET LI.IsGLPosted = 0, LI.IsNonAccrual = 1, UpdatedById = @UserId, UpdatedTime = @ModificationTime
FROM LoanIncomeSchedules LI
JOIN @LoanIncomeScheduleIds TLI ON  LI.Id = TLI.Id
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateOpenPeriodLeaseIncomeSchedulesForReAccrual]
(
@LeaseIncomeScheduleIds LeaseIncomeScheduleIdInfoForRA READONLY,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
UPDATE LI SET LI.IsGLPosted = 0, LI.PostDate = null, LI.IsNonAccrual = 0,
LI.UpdatedById = @UpdatedById,
LI.UpdatedTime = @UpdatedTime
FROM LeaseIncomeSchedules LI
JOIN @LeaseIncomeScheduleIds TLI ON LI.Id = TLI.Id
END

GO

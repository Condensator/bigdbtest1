SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateFixedTermLeaseIncomeSchedulesForReAccrual]
(
@LeaseIncomeScheduleDetail LeaseIncomeScheduleDetailForReAccrual READONLY,
@UserId BIGINT,
@ModificationTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
UPDATE LIS SET
LIS.IsGLPosted = CASE WHEN LD.IsOpenPeriod = 1 THEN  0 ELSE LIS.IsGLPosted END,
LIS.PostDate = CASE WHEN LD.IsOpenPeriod = 1 THEN NULL ELSE LIS.PostDate END,
LIS.IsAccounting = CASE WHEN LD.IsOpenPeriod = 1 THEN 0 ELSE LIS.IsAccounting END,
LIS.IsSchedule=0,
UpdatedById = @UserId,
UpdatedTime = @ModificationTime
FROM
LeaseIncomeSchedules LIS
JOIN @LeaseIncomeScheduleDetail LD ON LIS.Id = LD.LeaseIncomeScheduleId
END

GO

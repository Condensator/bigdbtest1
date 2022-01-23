SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateBlendedIncomeSchedulesForReAccrual]
(
@BlendedIncomeScheduleDetail BlendedIncomeScheduleDetailForReAccrual READONLY,
@UserId BIGINT,
@ModificationTime DATETIMEOFFSET,
@ReversalPostDate DATETIME
)
AS
BEGIN
SET NOCOUNT ON
UPDATE BIS SET
BIS.ReversalPostDate = CASE WHEN BD.IsOpenPeriod = 1 THEN @ReversalPostDate ELSE NULL END,
BIS.IsAccounting = CASE WHEN BD.IsOpenPeriod = 1 THEN 0 ELSE BIS.IsAccounting END,
BIS.IsSchedule=0,
UpdatedById = @UserId,
UpdatedTime = @ModificationTime
FROM
BlendedIncomeSchedules BIS
JOIN @BlendedIncomeScheduleDetail BD ON BIS.Id = BD.BlendedIncomeScheduleId
END

GO

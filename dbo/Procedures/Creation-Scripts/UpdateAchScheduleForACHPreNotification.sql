SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateAchScheduleForACHPreNotification]
(
@UserId BigInt,
@UpdatedTime DateTimeOffset,
@ReceivableIds ReceivableIdParams  READONLY
)
AS
--IF OBJECT_ID('tempdb..#ReceivableIds') IS NOT NULL DROP Table #ReceivableIds;
BEGIN
SET NOCOUNT ON;
--DECLARE @UpdatedTime DateTimeOffset;
--DECLARE @UserId BIGINT;
--Set @UpdatedTime = SYSDATETIMEOFFSET();
--Set @UserId = 40419
--Declare #ReceivableIds
UPDATE ACHSchedules SET IsPreACHNotificationCreated=1,UpdatedTime=@UpdatedTime,UpdatedById=@UserId
FROM ACHSchedules AchSchedule
INNER JOIN @ReceivableIds RIds ON RIds.ReceivableId = AchSchedule.ReceivableId
WHERE AchSchedule.IsActive=1 AND (AchSchedule.Status ='Pending' OR AchSchedule.Status ='ThresholdExceeded')
END

GO

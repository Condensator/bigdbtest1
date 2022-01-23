SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CreateProcessedReadingsHistory]
(
@InstanceId UNIQUEIDENTIFIER,
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
INSERT INTO EnmasseMeterReadingHistories
(CPINumber,AssetId,Alias,SerialNumber,MeterType,EndPeriodDate,ReadDate,BeginReading,EndReading,ServiceCredits,Source,IsEstimated,MeterResetType,InstanceId,RowId,EnmasseMeterReadingInstanceId,CreatedById,CreatedTime)
SELECT CPINumber,AssetId,Alias,SerialNumber,MeterType,EndPeriodDate,ReadDate,BeginReading,EndReading,ServiceCredits,
Source,IsEstimated,MeterResetType,InstanceId,RowId,Id,@CreatedById,@CreatedTime
FROM EnmasseMeterReadingInstances WHERE InstanceId =@InstanceId
INSERT INTO EnmasseMeterReadingHistoryLogs(EnmasseMeterReadingHistoryId,CreatedById,CreatedTime,Error)
SELECT EnmasseMeterReadingHistories.Id,@CreatedById,@CreatedTime,Error
FROM EnmasseMeterReadingLogs
INNER JOIN EnmasseMeterReadingHistories ON EnmasseMeterReadingLogs.EnmasseMeterReadingInstanceId	=EnmasseMeterReadingHistories.EnmasseMeterReadingInstanceId
WHERE EnmasseMeterReadingHistories.InstanceId =@InstanceId
SET NOCOUNT OFF
END

GO

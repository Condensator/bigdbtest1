SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateCPUAssetMeterReadingMigration]
(
@FailedMeterReadings FailedCPUAssetMeterReading NULL READONLY,
@UserId BIGINT,
@CreatedTime DATETIMEOFFSET  ,
@ModuleIterationStatusId BIGINT,
@ToolIdentifier BIGINT NULL
)
AS
BEGIN
SET NOCOUNT ON;
DECLARE @ErrorLogs ErrorMessageList;
/*Get the Staging Entity and Error message for Failed Meter Readings*/
SELECT
StgEntity.Id ,
FailedReading.FailureReason
INTO
#FailedStagingReadings
FROM
stgCPUAssetMeterReadingUploadRecord AS StgEntity
JOIN
@FailedMeterReadings FailedReading ON StgEntity.CPINumber = FailedReading.CPINumber
WHERE
StgEntity.Alias = FailedReading.Alias
AND StgEntity.MeterType = FailedReading.MeterType
AND StgEntity.EndPeriodDate = FailedReading.EndPeriodDate
AND StgEntity.ReadDate = FailedReading.ReadDate
AND StgEntity.EndReading = FailedReading.EndReading
AND StgEntity.ServiceCredits = FailedReading.ServiceCredits
AND StgEntity.Source = FailedReading.Source
AND StgEntity.IsEstimated = FailedReading.IsEstimated
AND REPLACE(StgEntity.MeterResetType,'_','') = FailedReading.MeterResetType
AND StgEntity.IsMigrated = 0
DECLARE @FailedRecordCount BIGINT
SET @FailedRecordCount = (SELECT COUNT(Id) FROM #FailedStagingReadings)
IF(@FailedRecordCount > 0)
BEGIN
/*Insert Error Log for Failed Records*/
INSERT
INTO
@ErrorLogs
(
StagingRootEntityId,
ModuleIterationStatusId,
Message
)
SELECT
Id,
@ModuleIterationStatusId,
FailureReason
FROM
#FailedStagingReadings
END
/*Insert Success Log for Migrated Records*/
INSERT
INTO
@ErrorLogs
(
StagingRootEntityId,
ModuleIterationStatusId,
Message,
Type
)
SELECT
Id,
@ModuleIterationStatusId,
'Success',
'Information'
FROM
stgCPUAssetMeterReadingUploadRecord
WHERE
Id NOT IN (SELECT Id FROM #FailedStagingReadings)
AND IsMigrated = 0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier) 
EXEC [dbo].[CreateProcessingLog] @ErrorLogs,@UserId,@CreatedTime
DELETE FROM @ErrorLogs
/*Update IsMigrated to 1 for Sucessful records*/
UPDATE
stgCPUAssetMeterReadingUploadRecord
SET
IsMigrated = 1
FROM
stgCPUAssetMeterReadingUploadRecord
WHERE
Id NOT IN (SELECT Id FROM #FailedStagingReadings)
AND IsMigrated = 0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier) 
IF OBJECT_ID('tempdb..#FailedStagingReadings') IS NOT NULL
DROP TABLE #FailedStagingReadings
SET NOCOUNT OFF;
END

GO

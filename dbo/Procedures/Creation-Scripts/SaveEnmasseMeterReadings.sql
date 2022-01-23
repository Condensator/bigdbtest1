SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[SaveEnmasseMeterReadings]
(
@val [dbo].CPUAssetMeterReadingInfoForBulkInsertion READONLY
)
AS
BEGIN
SET NOCOUNT ON;
CREATE TABLE #Output(
[Action] NVARCHAR(10) NOT NULL,
[Id] bigint NOT NULL,
RowId bigint NOT NULL,
[LinkedCPUAssetMeterReadingRowId] int  NULL
)
MERGE [dbo].[CPUAssetMeterReadings] AS T
USING (SELECT * FROM @val) AS S
ON ( T.Id = S.Id)
WHEN MATCHED THEN
UPDATE SET [BeginPeriodDate]=S.[BeginPeriodDate],[BeginReading]=S.[BeginReading],[CPUAssetId]=S.[CPUAssetId],[CPUOverageAssessmentId]=S.[CPUOverageAssessmentId],[EndPeriodDate]=S.[EndPeriodDate],[EndReading]=S.[EndReading],[IsActive]=S.[IsActive],[IsCorrection]=S.[IsCorrection],[IsEstimated]=S.[IsEstimated],[IsMeterReset]=S.[IsMeterReset],[LinkedCPUAssetMeterReadingId]=S.[LinkedCPUAssetMeterReadingId],[MeterResetType]=S.[MeterResetType],[ReadDate]=S.[ReadDate],[Reading]=S.[Reading],[ServiceCredits]=S.[ServiceCredits],[Source]=S.[Source],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[AssessmentEffectiveDate]=S.[AssessmentEffectiveDate]
WHEN NOT MATCHED THEN
INSERT ([BeginPeriodDate],[BeginReading],[CPUAssetId],[CPUAssetMeterReadingHeaderId],[CPUOverageAssessmentId],[CreatedById],[CreatedTime],[EndPeriodDate],[EndReading],[IsActive],[IsCorrection],[IsEstimated],[IsMeterReset],[LinkedCPUAssetMeterReadingId],[MeterResetType],[ReadDate],[Reading],[ServiceCredits],[Source],[AssessmentEffectiveDate])
VALUES (S.[BeginPeriodDate],S.[BeginReading],S.[CPUAssetId],S.[CPUAssetMeterReadingHeaderId],S.[CPUOverageAssessmentId],S.[CreatedById],S.[CreatedTime],S.[EndPeriodDate],S.[EndReading],S.[IsActive],S.[IsCorrection],S.[IsEstimated],S.[IsMeterReset],S.[LinkedCPUAssetMeterReadingId],S.[MeterResetType],S.[ReadDate],S.[Reading],S.[ServiceCredits],S.[Source],S.[AssessmentEffectiveDate])
OUTPUT $action, Inserted.Id,S.RowId, S.LinkedCPUAssetMeterReadingRowId
INTO #Output;
SELECT O.Id AS MeterReadingId ,P.Id AS LinkedMeterReadingId INTO #LinkedMeterReadingIdInfo  FROM #Output O
JOIN #Output P ON O.LinkedCPUAssetMeterReadingRowId = P.RowId
UPDATE CPUAssetMeterReadings
SET LinkedCPUAssetMeterReadingId = #LinkedMeterReadingIdInfo.LinkedMeterReadingId
FROM #LinkedMeterReadingIdInfo
JOIN CPUAssetMeterReadings ON #LinkedMeterReadingIdInfo.MeterReadingId = CPUAssetMeterReadings.Id
UPDATE CPUOverageAssessments
SET IsAdjustmentPending = 1,
AssessmentReason='Correction'
FROM #Output
INNER JOIN CPUAssetMeterReadings ON CPUAssetMeterReadings.LinkedCPUAssetMeterReadingId = #Output.Id
INNER JOIN CPUOverageAssessments ON CPUAssetMeterReadings.CPUOverageAssessmentId = CPUOverageAssessments.Id
WHERE CPUAssetMeterReadings.LinkedCPUAssetMeterReadingId IS NOT NULL AND AssessmentReason <> 'Inactivation'
UPDATE CPUOverageAssessments
SET IsAdjustmentPending = 1,
AssessmentReason='Replace'
FROM #Output
INNER JOIN CPUAssetMeterReadings ON CPUAssetMeterReadings.Id = #Output.Id
INNER JOIN CPUOverageAssessments ON CPUAssetMeterReadings.CPUOverageAssessmentId = CPUOverageAssessments.Id
WHERE CPUAssetMeterReadings.MeterResetType = 'Replace' AND CPUAssetMeterReadings.LinkedCPUAssetMeterReadingId IS NULL AND AssessmentReason <> 'Inactivation'
IF (OBJECT_ID('tempdb..#Output')) IS NOT NULL
DROP TABLE #Output
IF (OBJECT_ID('tempdb..#LinkedMeterReadingIdInfo')) IS NOT NULL
DROP TABLE #LinkedMeterReadingIdInfo
SET NOCOUNT OFF;
END

GO

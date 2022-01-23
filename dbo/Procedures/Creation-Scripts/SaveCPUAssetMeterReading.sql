SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCPUAssetMeterReading]
(
 @val [dbo].[CPUAssetMeterReading] READONLY
)
AS
SET NOCOUNT ON;
DECLARE @Output TABLE(
 [Action] NVARCHAR(10) NOT NULL,
 [Id] bigint NOT NULL,
 [Token] int NOT NULL,
 [RowVersion] BIGINT,
 [OldRowVersion] BIGINT
)
MERGE [dbo].[CPUAssetMeterReadings] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssessmentEffectiveDate]=S.[AssessmentEffectiveDate],[BeginPeriodDate]=S.[BeginPeriodDate],[BeginReading]=S.[BeginReading],[CPUAssetId]=S.[CPUAssetId],[CPUOverageAssessmentId]=S.[CPUOverageAssessmentId],[EndPeriodDate]=S.[EndPeriodDate],[EndReading]=S.[EndReading],[IsActive]=S.[IsActive],[IsCorrection]=S.[IsCorrection],[IsEstimated]=S.[IsEstimated],[IsMeterReset]=S.[IsMeterReset],[LinkedCPUAssetMeterReadingId]=S.[LinkedCPUAssetMeterReadingId],[MeterResetType]=S.[MeterResetType],[ReadDate]=S.[ReadDate],[Reading]=S.[Reading],[ServiceCredits]=S.[ServiceCredits],[Source]=S.[Source],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssessmentEffectiveDate],[BeginPeriodDate],[BeginReading],[CPUAssetId],[CPUAssetMeterReadingHeaderId],[CPUOverageAssessmentId],[CreatedById],[CreatedTime],[EndPeriodDate],[EndReading],[IsActive],[IsCorrection],[IsEstimated],[IsMeterReset],[LinkedCPUAssetMeterReadingId],[MeterResetType],[ReadDate],[Reading],[ServiceCredits],[Source])
    VALUES (S.[AssessmentEffectiveDate],S.[BeginPeriodDate],S.[BeginReading],S.[CPUAssetId],S.[CPUAssetMeterReadingHeaderId],S.[CPUOverageAssessmentId],S.[CreatedById],S.[CreatedTime],S.[EndPeriodDate],S.[EndReading],S.[IsActive],S.[IsCorrection],S.[IsEstimated],S.[IsMeterReset],S.[LinkedCPUAssetMeterReadingId],S.[MeterResetType],S.[ReadDate],S.[Reading],S.[ServiceCredits],S.[Source])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

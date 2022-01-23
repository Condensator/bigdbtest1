SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveEnmasseMeterReadingInstance]
(
 @val [dbo].[EnmasseMeterReadingInstance] READONLY
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
MERGE [dbo].[EnmasseMeterReadingInstances] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Alias]=S.[Alias],[AssetBeginDate]=S.[AssetBeginDate],[AssetId]=S.[AssetId],[AssetMeterTypeId]=S.[AssetMeterTypeId],[BeginPeriodDate]=S.[BeginPeriodDate],[BeginReading]=S.[BeginReading],[ContractSequenceNumber]=S.[ContractSequenceNumber],[CPINumber]=S.[CPINumber],[CPUAssetId]=S.[CPUAssetId],[CPUAssetMeterReadingHeaderId]=S.[CPUAssetMeterReadingHeaderId],[CPUContractId]=S.[CPUContractId],[CPUOverageAssessmentId]=S.[CPUOverageAssessmentId],[CPUScheduleId]=S.[CPUScheduleId],[EndPeriodDate]=S.[EndPeriodDate],[EndReading]=S.[EndReading],[InstanceId]=S.[InstanceId],[IsAggregate]=S.[IsAggregate],[IsCorrection]=S.[IsCorrection],[IsEstimated]=S.[IsEstimated],[IsFaulted]=S.[IsFaulted],[IsFirstReading]=S.[IsFirstReading],[IsFirstReadingCorrected]=S.[IsFirstReadingCorrected],[MatchedAssetId]=S.[MatchedAssetId],[MeterMaxReading]=S.[MeterMaxReading],[MeterResetType]=S.[MeterResetType],[MeterType]=S.[MeterType],[OriginalBeginReading]=S.[OriginalBeginReading],[OriginalSource]=S.[OriginalSource],[PortfolioId]=S.[PortfolioId],[ReadDate]=S.[ReadDate],[RowId]=S.[RowId],[ScheduleNumber]=S.[ScheduleNumber],[SerialNumber]=S.[SerialNumber],[ServiceCredits]=S.[ServiceCredits],[Source]=S.[Source],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Alias],[AssetBeginDate],[AssetId],[AssetMeterTypeId],[BeginPeriodDate],[BeginReading],[ContractSequenceNumber],[CPINumber],[CPUAssetId],[CPUAssetMeterReadingHeaderId],[CPUContractId],[CPUOverageAssessmentId],[CPUScheduleId],[CreatedById],[CreatedTime],[EndPeriodDate],[EndReading],[InstanceId],[IsAggregate],[IsCorrection],[IsEstimated],[IsFaulted],[IsFirstReading],[IsFirstReadingCorrected],[MatchedAssetId],[MeterMaxReading],[MeterResetType],[MeterType],[OriginalBeginReading],[OriginalSource],[PortfolioId],[ReadDate],[RowId],[ScheduleNumber],[SerialNumber],[ServiceCredits],[Source])
    VALUES (S.[Alias],S.[AssetBeginDate],S.[AssetId],S.[AssetMeterTypeId],S.[BeginPeriodDate],S.[BeginReading],S.[ContractSequenceNumber],S.[CPINumber],S.[CPUAssetId],S.[CPUAssetMeterReadingHeaderId],S.[CPUContractId],S.[CPUOverageAssessmentId],S.[CPUScheduleId],S.[CreatedById],S.[CreatedTime],S.[EndPeriodDate],S.[EndReading],S.[InstanceId],S.[IsAggregate],S.[IsCorrection],S.[IsEstimated],S.[IsFaulted],S.[IsFirstReading],S.[IsFirstReadingCorrected],S.[MatchedAssetId],S.[MeterMaxReading],S.[MeterResetType],S.[MeterType],S.[OriginalBeginReading],S.[OriginalSource],S.[PortfolioId],S.[ReadDate],S.[RowId],S.[ScheduleNumber],S.[SerialNumber],S.[ServiceCredits],S.[Source])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

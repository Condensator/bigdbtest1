SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveEnmasseMeterReadingHistory]
(
 @val [dbo].[EnmasseMeterReadingHistory] READONLY
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
MERGE [dbo].[EnmasseMeterReadingHistories] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Alias]=S.[Alias],[AssetId]=S.[AssetId],[BeginReading]=S.[BeginReading],[CPINumber]=S.[CPINumber],[EndPeriodDate]=S.[EndPeriodDate],[EndReading]=S.[EndReading],[EnmasseMeterReadingInstanceId]=S.[EnmasseMeterReadingInstanceId],[InstanceId]=S.[InstanceId],[IsEstimated]=S.[IsEstimated],[MeterResetType]=S.[MeterResetType],[MeterType]=S.[MeterType],[ReadDate]=S.[ReadDate],[RowId]=S.[RowId],[SerialNumber]=S.[SerialNumber],[ServiceCredits]=S.[ServiceCredits],[Source]=S.[Source],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Alias],[AssetId],[BeginReading],[CPINumber],[CreatedById],[CreatedTime],[EndPeriodDate],[EndReading],[EnmasseMeterReadingInstanceId],[InstanceId],[IsEstimated],[MeterResetType],[MeterType],[ReadDate],[RowId],[SerialNumber],[ServiceCredits],[Source])
    VALUES (S.[Alias],S.[AssetId],S.[BeginReading],S.[CPINumber],S.[CreatedById],S.[CreatedTime],S.[EndPeriodDate],S.[EndReading],S.[EnmasseMeterReadingInstanceId],S.[InstanceId],S.[IsEstimated],S.[MeterResetType],S.[MeterType],S.[ReadDate],S.[RowId],S.[SerialNumber],S.[ServiceCredits],S.[Source])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

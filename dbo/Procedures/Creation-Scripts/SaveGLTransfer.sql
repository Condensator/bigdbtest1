SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveGLTransfer]
(
 @val [dbo].[GLTransfer] READONLY
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
MERGE [dbo].[GLTransfers] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Alias]=S.[Alias],[BusinessUnitId]=S.[BusinessUnitId],[EffectiveDate]=S.[EffectiveDate],[GLTransferType]=S.[GLTransferType],[HoldingStatus]=S.[HoldingStatus],[IsFromUI]=S.[IsFromUI],[IsGLExportRequired]=S.[IsGLExportRequired],[JobStepInstanceId]=S.[JobStepInstanceId],[MovePLBalance]=S.[MovePLBalance],[NonDateSensitive]=S.[NonDateSensitive],[PLEffectiveDate]=S.[PLEffectiveDate],[PostDate]=S.[PostDate],[Status]=S.[Status],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Alias],[BusinessUnitId],[CreatedById],[CreatedTime],[EffectiveDate],[GLTransferType],[HoldingStatus],[IsFromUI],[IsGLExportRequired],[JobStepInstanceId],[MovePLBalance],[NonDateSensitive],[PLEffectiveDate],[PostDate],[Status])
    VALUES (S.[Alias],S.[BusinessUnitId],S.[CreatedById],S.[CreatedTime],S.[EffectiveDate],S.[GLTransferType],S.[HoldingStatus],S.[IsFromUI],S.[IsGLExportRequired],S.[JobStepInstanceId],S.[MovePLBalance],S.[NonDateSensitive],S.[PLEffectiveDate],S.[PostDate],S.[Status])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

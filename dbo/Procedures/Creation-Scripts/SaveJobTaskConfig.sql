SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveJobTaskConfig]
(
 @val [dbo].[JobTaskConfig] READONLY
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
MERGE [dbo].[JobTaskConfigs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ChunkServiceLimit]=S.[ChunkServiceLimit],[ChunkSize]=S.[ChunkSize],[IsActive]=S.[IsActive],[IsCancellable]=S.[IsCancellable],[IsExternalCall]=S.[IsExternalCall],[IsParallel]=S.[IsParallel],[IsSystemJob]=S.[IsSystemJob],[Name]=S.[Name],[PageSize]=S.[PageSize],[RetryFaultedBackgroundEventsBeforeRun]=S.[RetryFaultedBackgroundEventsBeforeRun],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UserFriendlyName]=S.[UserFriendlyName],[WaitForBackgroundEventsCompletionAfterRun]=S.[WaitForBackgroundEventsCompletionAfterRun]
WHEN NOT MATCHED THEN
	INSERT ([ChunkServiceLimit],[ChunkSize],[CreatedById],[CreatedTime],[IsActive],[IsCancellable],[IsExternalCall],[IsParallel],[IsSystemJob],[Name],[PageSize],[RetryFaultedBackgroundEventsBeforeRun],[UserFriendlyName],[WaitForBackgroundEventsCompletionAfterRun])
    VALUES (S.[ChunkServiceLimit],S.[ChunkSize],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[IsCancellable],S.[IsExternalCall],S.[IsParallel],S.[IsSystemJob],S.[Name],S.[PageSize],S.[RetryFaultedBackgroundEventsBeforeRun],S.[UserFriendlyName],S.[WaitForBackgroundEventsCompletionAfterRun])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

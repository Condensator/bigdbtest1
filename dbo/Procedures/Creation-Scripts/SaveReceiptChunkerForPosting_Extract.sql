SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceiptChunkerForPosting_Extract]
(
 @val [dbo].[ReceiptChunkerForPosting_Extract] READONLY
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
MERGE [dbo].[ReceiptChunkerForPosting_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [JobStepInstanceId]=S.[JobStepInstanceId],[PostingBatchStatus]=S.[PostingBatchStatus],[PostingEndTime]=S.[PostingEndTime],[PostingStartTime]=S.[PostingStartTime],[PostingTaskChunkServiceInstanceId]=S.[PostingTaskChunkServiceInstanceId],[PrePostingBatchStatus]=S.[PrePostingBatchStatus],[PrePostingEndTime]=S.[PrePostingEndTime],[PrePostingStartTime]=S.[PrePostingStartTime],[PrePostingTaskChunkServiceInstanceId]=S.[PrePostingTaskChunkServiceInstanceId],[SourceModule]=S.[SourceModule],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[JobStepInstanceId],[PostingBatchStatus],[PostingEndTime],[PostingStartTime],[PostingTaskChunkServiceInstanceId],[PrePostingBatchStatus],[PrePostingEndTime],[PrePostingStartTime],[PrePostingTaskChunkServiceInstanceId],[SourceModule])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[JobStepInstanceId],S.[PostingBatchStatus],S.[PostingEndTime],S.[PostingStartTime],S.[PostingTaskChunkServiceInstanceId],S.[PrePostingBatchStatus],S.[PrePostingEndTime],S.[PrePostingStartTime],S.[PrePostingTaskChunkServiceInstanceId],S.[SourceModule])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

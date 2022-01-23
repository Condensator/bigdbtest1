SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveESignEnvelope]
(
 @val [dbo].[ESignEnvelope] READONLY
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
MERGE [dbo].[ESignEnvelopes] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [CancellationReason]=S.[CancellationReason],[CompletedDate]=S.[CompletedDate],[EnvelopeId]=S.[EnvelopeId],[ErrorComment]=S.[ErrorComment],[ESignSystem]=S.[ESignSystem],[IsActive]=S.[IsActive],[Message]=S.[Message],[SentDate]=S.[SentDate],[Status]=S.[Status],[Subject]=S.[Subject],[TagViewURL]=S.[TagViewURL],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VaultEnabled]=S.[VaultEnabled],[XAPIUser]=S.[XAPIUser]
WHEN NOT MATCHED THEN
	INSERT ([CancellationReason],[CompletedDate],[CreatedById],[CreatedTime],[DocumentHeaderId],[EnvelopeId],[ErrorComment],[ESignSystem],[IsActive],[Message],[SentDate],[Status],[Subject],[TagViewURL],[VaultEnabled],[XAPIUser])
    VALUES (S.[CancellationReason],S.[CompletedDate],S.[CreatedById],S.[CreatedTime],S.[DocumentHeaderId],S.[EnvelopeId],S.[ErrorComment],S.[ESignSystem],S.[IsActive],S.[Message],S.[SentDate],S.[Status],S.[Subject],S.[TagViewURL],S.[VaultEnabled],S.[XAPIUser])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

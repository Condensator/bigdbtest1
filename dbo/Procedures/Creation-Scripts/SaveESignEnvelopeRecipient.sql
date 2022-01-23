SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveESignEnvelopeRecipient]
(
 @val [dbo].[ESignEnvelopeRecipient] READONLY
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
MERGE [dbo].[ESignEnvelopeRecipients] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [EmailId]=S.[EmailId],[ExternalId]=S.[ExternalId],[Hierarchy]=S.[Hierarchy],[IsActive]=S.[IsActive],[IsModified]=S.[IsModified],[Name]=S.[Name],[RecipientAction]=S.[RecipientAction],[Status]=S.[Status],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[EmailId],[ESignEnvelopeId],[ExternalId],[Hierarchy],[IsActive],[IsModified],[Name],[RecipientAction],[Status])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[EmailId],S.[ESignEnvelopeId],S.[ExternalId],S.[Hierarchy],S.[IsActive],S.[IsModified],S.[Name],S.[RecipientAction],S.[Status])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

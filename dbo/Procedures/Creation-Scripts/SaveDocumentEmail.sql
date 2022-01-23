SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDocumentEmail]
(
 @val [dbo].[DocumentEmail] READONLY
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
MERGE [dbo].[DocumentEmails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BccEmailId]=S.[BccEmailId],[CcEmailId]=S.[CcEmailId],[EmailTemplateId]=S.[EmailTemplateId],[FromEmailId]=S.[FromEmailId],[RowNumber]=S.[RowNumber],[SentByUserId]=S.[SentByUserId],[SentDate]=S.[SentDate],[Status]=S.[Status],[StatusComment]=S.[StatusComment],[ToEmailId]=S.[ToEmailId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BccEmailId],[CcEmailId],[CreatedById],[CreatedTime],[DocumentHeaderId],[EmailTemplateId],[FromEmailId],[RowNumber],[SentByUserId],[SentDate],[Status],[StatusComment],[ToEmailId])
    VALUES (S.[BccEmailId],S.[CcEmailId],S.[CreatedById],S.[CreatedTime],S.[DocumentHeaderId],S.[EmailTemplateId],S.[FromEmailId],S.[RowNumber],S.[SentByUserId],S.[SentDate],S.[Status],S.[StatusComment],S.[ToEmailId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

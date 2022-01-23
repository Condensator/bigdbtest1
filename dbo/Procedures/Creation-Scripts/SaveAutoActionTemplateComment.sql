SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAutoActionTemplateComment]
(
 @val [dbo].[AutoActionTemplateComment] READONLY
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
MERGE [dbo].[AutoActionTemplateComments] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AlertComment]=S.[AlertComment],[AuthorExpression]=S.[AuthorExpression],[AuthorId]=S.[AuthorId],[Body]=S.[Body],[CommentTypeId]=S.[CommentTypeId],[ConversationMode]=S.[ConversationMode],[IsActive]=S.[IsActive],[IsInternal]=S.[IsInternal],[Title]=S.[Title],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AlertComment],[AuthorExpression],[AuthorId],[Body],[CommentTypeId],[ConversationMode],[CreatedById],[CreatedTime],[Id],[IsActive],[IsInternal],[Title])
    VALUES (S.[AlertComment],S.[AuthorExpression],S.[AuthorId],S.[Body],S.[CommentTypeId],S.[ConversationMode],S.[CreatedById],S.[CreatedTime],S.[Id],S.[IsActive],S.[IsInternal],S.[Title])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

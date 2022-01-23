SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveComment]
(
 @val [dbo].[Comment] READONLY
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
MERGE [dbo].[Comments] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AuthorId]=S.[AuthorId],[Body]=S.[Body],[CommentTypeId]=S.[CommentTypeId],[ConversationMode]=S.[ConversationMode],[DefaultPermission]=S.[DefaultPermission],[EntityId]=S.[EntityId],[EntityTypeId]=S.[EntityTypeId],[FollowUpById]=S.[FollowUpById],[FollowUpDate]=S.[FollowUpDate],[Importance]=S.[Importance],[IsActive]=S.[IsActive],[IsInternal]=S.[IsInternal],[OriginalCreatedTime]=S.[OriginalCreatedTime],[Title]=S.[Title],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AuthorId],[Body],[CommentTypeId],[ConversationMode],[CreatedById],[CreatedTime],[DefaultPermission],[EntityId],[EntityTypeId],[FollowUpById],[FollowUpDate],[Importance],[IsActive],[IsInternal],[OriginalCreatedTime],[Title])
    VALUES (S.[AuthorId],S.[Body],S.[CommentTypeId],S.[ConversationMode],S.[CreatedById],S.[CreatedTime],S.[DefaultPermission],S.[EntityId],S.[EntityTypeId],S.[FollowUpById],S.[FollowUpDate],S.[Importance],S.[IsActive],S.[IsInternal],S.[OriginalCreatedTime],S.[Title])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

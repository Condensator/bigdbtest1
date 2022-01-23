SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCommentEntityTag]
(
 @val [dbo].[CommentEntityTag] READONLY
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
MERGE [dbo].[CommentEntityTags] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [CommentListId]=S.[CommentListId],[EntityId]=S.[EntityId],[EntityTypeId]=S.[EntityTypeId],[IsActive]=S.[IsActive],[IsChanged]=S.[IsChanged],[IsRootEntity]=S.[IsRootEntity],[Label]=S.[Label],[RelateAutomatically]=S.[RelateAutomatically],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CommentId],[CommentListId],[CreatedById],[CreatedTime],[EntityId],[EntityTypeId],[IsActive],[IsChanged],[IsRootEntity],[Label],[RelateAutomatically])
    VALUES (S.[CommentId],S.[CommentListId],S.[CreatedById],S.[CreatedTime],S.[EntityId],S.[EntityTypeId],S.[IsActive],S.[IsChanged],S.[IsRootEntity],S.[Label],S.[RelateAutomatically])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

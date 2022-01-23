SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCommentTypePermission]
(
 @val [dbo].[CommentTypePermission] READONLY
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
MERGE [dbo].[CommentTypePermissions] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssignmentType]=S.[AssignmentType],[Condition]=S.[Condition],[CreationAllowed]=S.[CreationAllowed],[IsActive]=S.[IsActive],[Permission]=S.[Permission],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UserSelectionId]=S.[UserSelectionId]
WHEN NOT MATCHED THEN
	INSERT ([AssignmentType],[CommentTypeId],[Condition],[CreatedById],[CreatedTime],[CreationAllowed],[IsActive],[Permission],[UserSelectionId])
    VALUES (S.[AssignmentType],S.[CommentTypeId],S.[Condition],S.[CreatedById],S.[CreatedTime],S.[CreationAllowed],S.[IsActive],S.[Permission],S.[UserSelectionId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

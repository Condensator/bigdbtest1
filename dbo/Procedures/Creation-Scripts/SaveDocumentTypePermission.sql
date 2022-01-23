SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDocumentTypePermission]
(
 @val [dbo].[DocumentTypePermission] READONLY
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
MERGE [dbo].[DocumentTypePermissions] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssignmentType]=S.[AssignmentType],[Condition]=S.[Condition],[ConditionFor]=S.[ConditionFor],[CreationAllowed]=S.[CreationAllowed],[IsActive]=S.[IsActive],[IsOverridable]=S.[IsOverridable],[IsReevaluate]=S.[IsReevaluate],[Permission]=S.[Permission],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UserSelectionId]=S.[UserSelectionId]
WHEN NOT MATCHED THEN
	INSERT ([AssignmentType],[Condition],[ConditionFor],[CreatedById],[CreatedTime],[CreationAllowed],[DocumentTypeId],[IsActive],[IsOverridable],[IsReevaluate],[Permission],[UserSelectionId])
    VALUES (S.[AssignmentType],S.[Condition],S.[ConditionFor],S.[CreatedById],S.[CreatedTime],S.[CreationAllowed],S.[DocumentTypeId],S.[IsActive],S.[IsOverridable],S.[IsReevaluate],S.[Permission],S.[UserSelectionId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

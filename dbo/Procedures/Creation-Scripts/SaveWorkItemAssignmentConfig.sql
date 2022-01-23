SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveWorkItemAssignmentConfig]
(
 @val [dbo].[WorkItemAssignmentConfig] READONLY
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
MERGE [dbo].[WorkItemAssignmentConfigs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssignmentType]=S.[AssignmentType],[Condition]=S.[Condition],[IsActive]=S.[IsActive],[IsMultipleUser]=S.[IsMultipleUser],[SequenceNumber]=S.[SequenceNumber],[SpecificWorkItemId]=S.[SpecificWorkItemId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UserExpression]=S.[UserExpression],[UserGroupExpression]=S.[UserGroupExpression],[UserGroupId]=S.[UserGroupId],[UserId]=S.[UserId]
WHEN NOT MATCHED THEN
	INSERT ([AssignmentType],[Condition],[CreatedById],[CreatedTime],[IsActive],[IsMultipleUser],[SequenceNumber],[SpecificWorkItemId],[UserExpression],[UserGroupExpression],[UserGroupId],[UserId],[WorkItemConfigId])
    VALUES (S.[AssignmentType],S.[Condition],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[IsMultipleUser],S.[SequenceNumber],S.[SpecificWorkItemId],S.[UserExpression],S.[UserGroupExpression],S.[UserGroupId],S.[UserId],S.[WorkItemConfigId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

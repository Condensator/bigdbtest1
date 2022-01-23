SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveTransactionInstance]
(
 @val [dbo].[TransactionInstance] READONLY
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
MERGE [dbo].[TransactionInstances] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccessScope]=S.[AccessScope],[AccessScopeId]=S.[AccessScopeId],[Comment]=S.[Comment],[EntityId]=S.[EntityId],[EntityName]=S.[EntityName],[EntitySummary]=S.[EntitySummary],[FallbackForm]=S.[FallbackForm],[FollowUpDate]=S.[FollowUpDate],[GUID]=S.[GUID],[IsFromAutoAction]=S.[IsFromAutoAction],[IsSuspendable]=S.[IsSuspendable],[Status]=S.[Status],[TransactionName]=S.[TransactionName],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[WorkflowInstanceData]=S.[WorkflowInstanceData],[WorkflowInstanceId]=S.[WorkflowInstanceId],[WorkflowSource]=S.[WorkflowSource]
WHEN NOT MATCHED THEN
	INSERT ([AccessScope],[AccessScopeId],[Comment],[CreatedById],[CreatedTime],[EntityId],[EntityName],[EntitySummary],[FallbackForm],[FollowUpDate],[GUID],[IsFromAutoAction],[IsSuspendable],[Status],[TransactionName],[WorkflowInstanceData],[WorkflowInstanceId],[WorkflowSource])
    VALUES (S.[AccessScope],S.[AccessScopeId],S.[Comment],S.[CreatedById],S.[CreatedTime],S.[EntityId],S.[EntityName],S.[EntitySummary],S.[FallbackForm],S.[FollowUpDate],S.[GUID],S.[IsFromAutoAction],S.[IsSuspendable],S.[Status],S.[TransactionName],S.[WorkflowInstanceData],S.[WorkflowInstanceId],S.[WorkflowSource])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

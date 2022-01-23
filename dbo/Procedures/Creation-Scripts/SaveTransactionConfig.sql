SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveTransactionConfig]
(
 @val [dbo].[TransactionConfig] READONLY
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
MERGE [dbo].[TransactionConfigs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AllowSubscription]=S.[AllowSubscription],[AllowWorkItemAssignment]=S.[AllowWorkItemAssignment],[Description]=S.[Description],[EntityName]=S.[EntityName],[EntitySummaryExpression]=S.[EntitySummaryExpression],[IsActive]=S.[IsActive],[IsCurrent]=S.[IsCurrent],[IsNotify]=S.[IsNotify],[IsSuspendable]=S.[IsSuspendable],[IsVisibleInUI]=S.[IsVisibleInUI],[Mode]=S.[Mode],[Name]=S.[Name],[PrimaryEntity]=S.[PrimaryEntity],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[WorkflowSource]=S.[WorkflowSource]
WHEN NOT MATCHED THEN
	INSERT ([AllowSubscription],[AllowWorkItemAssignment],[CreatedById],[CreatedTime],[Description],[EntityName],[EntitySummaryExpression],[IsActive],[IsCurrent],[IsNotify],[IsSuspendable],[IsVisibleInUI],[Mode],[Name],[PrimaryEntity],[WorkflowSource])
    VALUES (S.[AllowSubscription],S.[AllowWorkItemAssignment],S.[CreatedById],S.[CreatedTime],S.[Description],S.[EntityName],S.[EntitySummaryExpression],S.[IsActive],S.[IsCurrent],S.[IsNotify],S.[IsSuspendable],S.[IsVisibleInUI],S.[Mode],S.[Name],S.[PrimaryEntity],S.[WorkflowSource])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

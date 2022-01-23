SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveNotification]
(
 @val [dbo].[Notification] READONLY
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
MERGE [dbo].[Notifications] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AsOfDate]=S.[AsOfDate],[EntityId]=S.[EntityId],[EntityName]=S.[EntityName],[EvaluateContentAtRuntime]=S.[EvaluateContentAtRuntime],[NotificationRecipientConfigId]=S.[NotificationRecipientConfigId],[SourceId]=S.[SourceId],[SourceModule]=S.[SourceModule],[Status]=S.[Status],[TransactionInstanceId]=S.[TransactionInstanceId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[WorkItemId]=S.[WorkItemId]
WHEN NOT MATCHED THEN
	INSERT ([AsOfDate],[CreatedById],[CreatedTime],[EntityId],[EntityName],[EvaluateContentAtRuntime],[NotificationRecipientConfigId],[SourceId],[SourceModule],[Status],[TransactionInstanceId],[WorkItemId])
    VALUES (S.[AsOfDate],S.[CreatedById],S.[CreatedTime],S.[EntityId],S.[EntityName],S.[EvaluateContentAtRuntime],S.[NotificationRecipientConfigId],S.[SourceId],S.[SourceModule],S.[Status],S.[TransactionInstanceId],S.[WorkItemId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

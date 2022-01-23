SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveNotificationRecipientConfig]
(
 @val [dbo].[NotificationRecipientConfig] READONLY
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
MERGE [dbo].[NotificationRecipientConfigs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Condition]=S.[Condition],[EmailTemplateId]=S.[EmailTemplateId],[ExternalEmailSelectionSQL]=S.[ExternalEmailSelectionSQL],[FromEmail]=S.[FromEmail],[FromEmailExpression]=S.[FromEmailExpression],[IsActive]=S.[IsActive],[IsMultipleUser]=S.[IsMultipleUser],[NotifyTxnSubscribersOnly]=S.[NotifyTxnSubscribersOnly],[OverrideEmailNotification]=S.[OverrideEmailNotification],[RecipientType]=S.[RecipientType],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UserExpression]=S.[UserExpression],[UserGroupId]=S.[UserGroupId],[UserId]=S.[UserId]
WHEN NOT MATCHED THEN
	INSERT ([Condition],[CreatedById],[CreatedTime],[EmailTemplateId],[ExternalEmailSelectionSQL],[FromEmail],[FromEmailExpression],[IsActive],[IsMultipleUser],[NotificationConfigId],[NotifyTxnSubscribersOnly],[OverrideEmailNotification],[RecipientType],[UserExpression],[UserGroupId],[UserId])
    VALUES (S.[Condition],S.[CreatedById],S.[CreatedTime],S.[EmailTemplateId],S.[ExternalEmailSelectionSQL],S.[FromEmail],S.[FromEmailExpression],S.[IsActive],S.[IsMultipleUser],S.[NotificationConfigId],S.[NotifyTxnSubscribersOnly],S.[OverrideEmailNotification],S.[RecipientType],S.[UserExpression],S.[UserGroupId],S.[UserId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

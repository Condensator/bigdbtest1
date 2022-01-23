SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveNotificationRecipient]
(
 @val [dbo].[NotificationRecipient] READONLY
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
MERGE [dbo].[NotificationRecipients] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BccEmailId]=S.[BccEmailId],[CcEmailId]=S.[CcEmailId],[ExternalRecipientId]=S.[ExternalRecipientId],[IsFlaggedForSending]=S.[IsFlaggedForSending],[ToEmailId]=S.[ToEmailId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UserGroupId]=S.[UserGroupId],[UserId]=S.[UserId]
WHEN NOT MATCHED THEN
	INSERT ([BccEmailId],[CcEmailId],[CreatedById],[CreatedTime],[ExternalRecipientId],[IsFlaggedForSending],[NotificationId],[ToEmailId],[UserGroupId],[UserId])
    VALUES (S.[BccEmailId],S.[CcEmailId],S.[CreatedById],S.[CreatedTime],S.[ExternalRecipientId],S.[IsFlaggedForSending],S.[NotificationId],S.[ToEmailId],S.[UserGroupId],S.[UserId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

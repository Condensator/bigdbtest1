SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveMaturityMonitorLesseeNotification]
(
 @val [dbo].[MaturityMonitorLesseeNotification] READONLY
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
MERGE [dbo].[MaturityMonitorLesseeNotifications] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ContractOptionId]=S.[ContractOptionId],[ContractOptionSelected]=S.[ContractOptionSelected],[EffectiveMaturityDate]=S.[EffectiveMaturityDate],[IsActive]=S.[IsActive],[NoticeReceivedDate]=S.[NoticeReceivedDate],[NotificationNumber]=S.[NotificationNumber],[RenewalDetailId]=S.[RenewalDetailId],[Response]=S.[Response],[Status]=S.[Status],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ContractOptionId],[ContractOptionSelected],[CreatedById],[CreatedTime],[EffectiveMaturityDate],[IsActive],[MaturityMonitorId],[NoticeReceivedDate],[NotificationNumber],[RenewalDetailId],[Response],[Status])
    VALUES (S.[ContractOptionId],S.[ContractOptionSelected],S.[CreatedById],S.[CreatedTime],S.[EffectiveMaturityDate],S.[IsActive],S.[MaturityMonitorId],S.[NoticeReceivedDate],S.[NotificationNumber],S.[RenewalDetailId],S.[Response],S.[Status])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

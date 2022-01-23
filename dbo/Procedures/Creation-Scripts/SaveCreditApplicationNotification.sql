SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCreditApplicationNotification]
(
 @val [dbo].[CreditApplicationNotification] READONLY
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
MERGE [dbo].[CreditApplicationNotifications] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ActivationDate]=S.[ActivationDate],[CanNotifyOnApproval]=S.[CanNotifyOnApproval],[CanNotifyOnDecline]=S.[CanNotifyOnDecline],[DeactivationDate]=S.[DeactivationDate],[EntityId]=S.[EntityId],[EntityType]=S.[EntityType],[IsActive]=S.[IsActive],[IsCreditNotificationAllowed]=S.[IsCreditNotificationAllowed],[IsNewAddress]=S.[IsNewAddress],[IsNewContact]=S.[IsNewContact],[IsVendorDetailRequired]=S.[IsVendorDetailRequired],[PartyAddressId]=S.[PartyAddressId],[PartyContactId]=S.[PartyContactId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ActivationDate],[CanNotifyOnApproval],[CanNotifyOnDecline],[CreatedById],[CreatedTime],[CreditApplicationId],[DeactivationDate],[EntityId],[EntityType],[IsActive],[IsCreditNotificationAllowed],[IsNewAddress],[IsNewContact],[IsVendorDetailRequired],[PartyAddressId],[PartyContactId])
    VALUES (S.[ActivationDate],S.[CanNotifyOnApproval],S.[CanNotifyOnDecline],S.[CreatedById],S.[CreatedTime],S.[CreditApplicationId],S.[DeactivationDate],S.[EntityId],S.[EntityType],S.[IsActive],S.[IsCreditNotificationAllowed],S.[IsNewAddress],S.[IsNewContact],S.[IsVendorDetailRequired],S.[PartyAddressId],S.[PartyContactId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveContractBilling]
(
 @val [dbo].[ContractBilling] READONLY
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
MERGE [dbo].[ContractBillings] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ActaNumber]=S.[ActaNumber],[InvoiceComment]=S.[InvoiceComment],[InvoiceCommentBeginDate]=S.[InvoiceCommentBeginDate],[InvoiceCommentEndDate]=S.[InvoiceCommentEndDate],[InvoiceLeaddays]=S.[InvoiceLeaddays],[InvoiceTransitDays]=S.[InvoiceTransitDays],[IsActive]=S.[IsActive],[IsPostACHNotification]=S.[IsPostACHNotification],[IsPreACHNotification]=S.[IsPreACHNotification],[IsReturnACHNotification]=S.[IsReturnACHNotification],[NotaryDate]=S.[NotaryDate],[PostACHNotificationEmailTemplateId]=S.[PostACHNotificationEmailTemplateId],[PostACHNotificationEmailTo]=S.[PostACHNotificationEmailTo],[PreACHNotificationEmail]=S.[PreACHNotificationEmail],[PreACHNotificationEmailTemplateId]=S.[PreACHNotificationEmailTemplateId],[ReceiptLegalEntityId]=S.[ReceiptLegalEntityId],[ReturnACHNotificationEmailTemplateId]=S.[ReturnACHNotificationEmailTemplateId],[ReturnACHNotificationEmailTo]=S.[ReturnACHNotificationEmailTo],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ActaNumber],[CreatedById],[CreatedTime],[Id],[InvoiceComment],[InvoiceCommentBeginDate],[InvoiceCommentEndDate],[InvoiceLeaddays],[InvoiceTransitDays],[IsActive],[IsPostACHNotification],[IsPreACHNotification],[IsReturnACHNotification],[NotaryDate],[PostACHNotificationEmailTemplateId],[PostACHNotificationEmailTo],[PreACHNotificationEmail],[PreACHNotificationEmailTemplateId],[ReceiptLegalEntityId],[ReturnACHNotificationEmailTemplateId],[ReturnACHNotificationEmailTo])
    VALUES (S.[ActaNumber],S.[CreatedById],S.[CreatedTime],S.[Id],S.[InvoiceComment],S.[InvoiceCommentBeginDate],S.[InvoiceCommentEndDate],S.[InvoiceLeaddays],S.[InvoiceTransitDays],S.[IsActive],S.[IsPostACHNotification],S.[IsPreACHNotification],S.[IsReturnACHNotification],S.[NotaryDate],S.[PostACHNotificationEmailTemplateId],S.[PostACHNotificationEmailTo],S.[PreACHNotificationEmail],S.[PreACHNotificationEmailTemplateId],S.[ReceiptLegalEntityId],S.[ReturnACHNotificationEmailTemplateId],S.[ReturnACHNotificationEmailTo])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

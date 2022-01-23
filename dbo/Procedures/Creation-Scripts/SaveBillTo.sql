SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveBillTo]
(
 @val [dbo].[BillTo] READONLY
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
MERGE [dbo].[BillToes] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetGroupByOption]=S.[AssetGroupByOption],[BillingAddressId]=S.[BillingAddressId],[BillingContactPersonId]=S.[BillingContactPersonId],[BillToName]=S.[BillToName],[CustomerBillToName]=S.[CustomerBillToName],[CustomerId]=S.[CustomerId],[DeliverInvoiceViaEmail]=S.[DeliverInvoiceViaEmail],[DeliverInvoiceViaMail]=S.[DeliverInvoiceViaMail],[GenerateInvoiceAddendum]=S.[GenerateInvoiceAddendum],[GenerateStatementInvoice]=S.[GenerateStatementInvoice],[GenerateSummaryInvoice]=S.[GenerateSummaryInvoice],[InvoiceComment]=S.[InvoiceComment],[InvoiceCommentBeginDate]=S.[InvoiceCommentBeginDate],[InvoiceCommentEndDate]=S.[InvoiceCommentEndDate],[InvoiceDateLabel]=S.[InvoiceDateLabel],[InvoiceNumberLabel]=S.[InvoiceNumberLabel],[IsActive]=S.[IsActive],[IsPostACHNotification]=S.[IsPostACHNotification],[IsPreACHNotification]=S.[IsPreACHNotification],[IsPrimary]=S.[IsPrimary],[IsReturnACHNotification]=S.[IsReturnACHNotification],[JurisdictionDetailId]=S.[JurisdictionDetailId],[JurisdictionId]=S.[JurisdictionId],[LanguageConfigId]=S.[LanguageConfigId],[LocationId]=S.[LocationId],[Name]=S.[Name],[PostACHNotificationEmailTemplateId]=S.[PostACHNotificationEmailTemplateId],[PostACHNotificationEmailTo]=S.[PostACHNotificationEmailTo],[PreACHNotificationEmailTemplateId]=S.[PreACHNotificationEmailTemplateId],[PreACHNotificationEmailTo]=S.[PreACHNotificationEmailTo],[ReturnACHNotificationEmailTemplateId]=S.[ReturnACHNotificationEmailTemplateId],[ReturnACHNotificationEmailTo]=S.[ReturnACHNotificationEmailTo],[SendBccEmailNotificationTo]=S.[SendBccEmailNotificationTo],[SendCCEmailNotificationTo]=S.[SendCCEmailNotificationTo],[SendEmailNotificationTo]=S.[SendEmailNotificationTo],[SplitByReceivableAdjustments]=S.[SplitByReceivableAdjustments],[SplitCreditsByOriginalInvoice]=S.[SplitCreditsByOriginalInvoice],[SplitCustomerPurchaseOrderNumber]=S.[SplitCustomerPurchaseOrderNumber],[SplitLeaseRentalInvoiceByLocation]=S.[SplitLeaseRentalInvoiceByLocation],[SplitReceivableDueDate]=S.[SplitReceivableDueDate],[SplitRentalInvoiceByAsset]=S.[SplitRentalInvoiceByAsset],[SplitRentalInvoiceByContract]=S.[SplitRentalInvoiceByContract],[StatementDueDay]=S.[StatementDueDay],[StatementFrequency]=S.[StatementFrequency],[StatementInvoiceEmailTemplateId]=S.[StatementInvoiceEmailTemplateId],[StatementInvoiceFormatId]=S.[StatementInvoiceFormatId],[StatementInvoiceOutputFormat]=S.[StatementInvoiceOutputFormat],[TaxAreaId]=S.[TaxAreaId],[TaxAreaVerifiedTillDate]=S.[TaxAreaVerifiedTillDate],[TaxBasisType]=S.[TaxBasisType],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UpfrontTaxMode]=S.[UpfrontTaxMode],[UseDynamicContentForInvoiceAddendumBody]=S.[UseDynamicContentForInvoiceAddendumBody],[UseDynamicContentForInvoiceBody]=S.[UseDynamicContentForInvoiceBody],[UseLocationAddressForBilling]=S.[UseLocationAddressForBilling]
WHEN NOT MATCHED THEN
	INSERT ([AssetGroupByOption],[BillingAddressId],[BillingContactPersonId],[BillToName],[CreatedById],[CreatedTime],[CustomerBillToName],[CustomerId],[DeliverInvoiceViaEmail],[DeliverInvoiceViaMail],[GenerateInvoiceAddendum],[GenerateStatementInvoice],[GenerateSummaryInvoice],[InvoiceComment],[InvoiceCommentBeginDate],[InvoiceCommentEndDate],[InvoiceDateLabel],[InvoiceNumberLabel],[IsActive],[IsPostACHNotification],[IsPreACHNotification],[IsPrimary],[IsReturnACHNotification],[JurisdictionDetailId],[JurisdictionId],[LanguageConfigId],[LocationId],[Name],[PostACHNotificationEmailTemplateId],[PostACHNotificationEmailTo],[PreACHNotificationEmailTemplateId],[PreACHNotificationEmailTo],[ReturnACHNotificationEmailTemplateId],[ReturnACHNotificationEmailTo],[SendBccEmailNotificationTo],[SendCCEmailNotificationTo],[SendEmailNotificationTo],[SplitByReceivableAdjustments],[SplitCreditsByOriginalInvoice],[SplitCustomerPurchaseOrderNumber],[SplitLeaseRentalInvoiceByLocation],[SplitReceivableDueDate],[SplitRentalInvoiceByAsset],[SplitRentalInvoiceByContract],[StatementDueDay],[StatementFrequency],[StatementInvoiceEmailTemplateId],[StatementInvoiceFormatId],[StatementInvoiceOutputFormat],[TaxAreaId],[TaxAreaVerifiedTillDate],[TaxBasisType],[UpfrontTaxMode],[UseDynamicContentForInvoiceAddendumBody],[UseDynamicContentForInvoiceBody],[UseLocationAddressForBilling])
    VALUES (S.[AssetGroupByOption],S.[BillingAddressId],S.[BillingContactPersonId],S.[BillToName],S.[CreatedById],S.[CreatedTime],S.[CustomerBillToName],S.[CustomerId],S.[DeliverInvoiceViaEmail],S.[DeliverInvoiceViaMail],S.[GenerateInvoiceAddendum],S.[GenerateStatementInvoice],S.[GenerateSummaryInvoice],S.[InvoiceComment],S.[InvoiceCommentBeginDate],S.[InvoiceCommentEndDate],S.[InvoiceDateLabel],S.[InvoiceNumberLabel],S.[IsActive],S.[IsPostACHNotification],S.[IsPreACHNotification],S.[IsPrimary],S.[IsReturnACHNotification],S.[JurisdictionDetailId],S.[JurisdictionId],S.[LanguageConfigId],S.[LocationId],S.[Name],S.[PostACHNotificationEmailTemplateId],S.[PostACHNotificationEmailTo],S.[PreACHNotificationEmailTemplateId],S.[PreACHNotificationEmailTo],S.[ReturnACHNotificationEmailTemplateId],S.[ReturnACHNotificationEmailTo],S.[SendBccEmailNotificationTo],S.[SendCCEmailNotificationTo],S.[SendEmailNotificationTo],S.[SplitByReceivableAdjustments],S.[SplitCreditsByOriginalInvoice],S.[SplitCustomerPurchaseOrderNumber],S.[SplitLeaseRentalInvoiceByLocation],S.[SplitReceivableDueDate],S.[SplitRentalInvoiceByAsset],S.[SplitRentalInvoiceByContract],S.[StatementDueDay],S.[StatementFrequency],S.[StatementInvoiceEmailTemplateId],S.[StatementInvoiceFormatId],S.[StatementInvoiceOutputFormat],S.[TaxAreaId],S.[TaxAreaVerifiedTillDate],S.[TaxBasisType],S.[UpfrontTaxMode],S.[UseDynamicContentForInvoiceAddendumBody],S.[UseDynamicContentForInvoiceBody],S.[UseLocationAddressForBilling])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

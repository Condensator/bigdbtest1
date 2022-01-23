SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveInvoiceExtractCustomerDetail]
(
 @val [dbo].[InvoiceExtractCustomerDetail] READONLY
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
MERGE [dbo].[InvoiceExtractCustomerDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AttentionLine]=S.[AttentionLine],[AttributeName]=S.[AttributeName],[BillingAddressLine1]=S.[BillingAddressLine1],[BillingAddressLine2]=S.[BillingAddressLine2],[BillingCity]=S.[BillingCity],[BillingCountry]=S.[BillingCountry],[BillingState]=S.[BillingState],[BillingZip]=S.[BillingZip],[BillToId]=S.[BillToId],[CreditReason]=S.[CreditReason],[CustomerComments]=S.[CustomerComments],[CustomerInvoiceCommentBeginDate]=S.[CustomerInvoiceCommentBeginDate],[CustomerInvoiceCommentEndDate]=S.[CustomerInvoiceCommentEndDate],[CustomerMainAddressLine1]=S.[CustomerMainAddressLine1],[CustomerMainAddressLine2]=S.[CustomerMainAddressLine2],[CustomerMainCity]=S.[CustomerMainCity],[CustomerMainCountry]=S.[CustomerMainCountry],[CustomerMainState]=S.[CustomerMainState],[CustomerMainZip]=S.[CustomerMainZip],[CustomerName]=S.[CustomerName],[CustomerNumber]=S.[CustomerNumber],[CustomerTaxRegistrationNumber]=S.[CustomerTaxRegistrationNumber],[DeliverInvoiceViaEmail]=S.[DeliverInvoiceViaEmail],[DueDate]=S.[DueDate],[ExternalExtractBatchId]=S.[ExternalExtractBatchId],[GenerateInvoiceAddendum]=S.[GenerateInvoiceAddendum],[GroupAssets]=S.[GroupAssets],[GSTId]=S.[GSTId],[InvoiceId]=S.[InvoiceId],[InvoiceNumber]=S.[InvoiceNumber],[InvoiceNumberLabel]=S.[InvoiceNumberLabel],[InvoiceRunDate]=S.[InvoiceRunDate],[InvoiceRunDateLabel]=S.[InvoiceRunDateLabel],[InvoiceType]=S.[InvoiceType],[IsACH]=S.[IsACH],[JobStepInstanceId]=S.[JobStepInstanceId],[LegalEntityName]=S.[LegalEntityName],[LegalEntityNumber]=S.[LegalEntityNumber],[LessorAddressLine1]=S.[LessorAddressLine1],[LessorAddressLine2]=S.[LessorAddressLine2],[LessorCity]=S.[LessorCity],[LessorContactEmail]=S.[LessorContactEmail],[LessorContactPhone]=S.[LessorContactPhone],[LessorCountry]=S.[LessorCountry],[LessorState]=S.[LessorState],[LessorTaxRegistrationNumber]=S.[LessorTaxRegistrationNumber],[LessorWebAddress]=S.[LessorWebAddress],[LessorZip]=S.[LessorZip],[LogoId]=S.[LogoId],[OCRMCR]=S.[OCRMCR],[OriginalInvoiceNumber]=S.[OriginalInvoiceNumber],[RemitToAccountNumber]=S.[RemitToAccountNumber],[RemitToCode]=S.[RemitToCode],[RemitToIBAN]=S.[RemitToIBAN],[RemitToName]=S.[RemitToName],[RemitToSWIFTCode]=S.[RemitToSWIFTCode],[RemitToTransitCode]=S.[RemitToTransitCode],[ReportFormatName]=S.[ReportFormatName],[TotalReceivableAmount_Amount]=S.[TotalReceivableAmount_Amount],[TotalReceivableAmount_Currency]=S.[TotalReceivableAmount_Currency],[TotalTaxAmount_Amount]=S.[TotalTaxAmount_Amount],[TotalTaxAmount_Currency]=S.[TotalTaxAmount_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UseDynamicContentForInvoiceAddendumBody]=S.[UseDynamicContentForInvoiceAddendumBody]
WHEN NOT MATCHED THEN
	INSERT ([AttentionLine],[AttributeName],[BillingAddressLine1],[BillingAddressLine2],[BillingCity],[BillingCountry],[BillingState],[BillingZip],[BillToId],[CreatedById],[CreatedTime],[CreditReason],[CustomerComments],[CustomerInvoiceCommentBeginDate],[CustomerInvoiceCommentEndDate],[CustomerMainAddressLine1],[CustomerMainAddressLine2],[CustomerMainCity],[CustomerMainCountry],[CustomerMainState],[CustomerMainZip],[CustomerName],[CustomerNumber],[CustomerTaxRegistrationNumber],[DeliverInvoiceViaEmail],[DueDate],[ExternalExtractBatchId],[GenerateInvoiceAddendum],[GroupAssets],[GSTId],[InvoiceId],[InvoiceNumber],[InvoiceNumberLabel],[InvoiceRunDate],[InvoiceRunDateLabel],[InvoiceType],[IsACH],[JobStepInstanceId],[LegalEntityName],[LegalEntityNumber],[LessorAddressLine1],[LessorAddressLine2],[LessorCity],[LessorContactEmail],[LessorContactPhone],[LessorCountry],[LessorState],[LessorTaxRegistrationNumber],[LessorWebAddress],[LessorZip],[LogoId],[OCRMCR],[OriginalInvoiceNumber],[RemitToAccountNumber],[RemitToCode],[RemitToIBAN],[RemitToName],[RemitToSWIFTCode],[RemitToTransitCode],[ReportFormatName],[TotalReceivableAmount_Amount],[TotalReceivableAmount_Currency],[TotalTaxAmount_Amount],[TotalTaxAmount_Currency],[UseDynamicContentForInvoiceAddendumBody])
    VALUES (S.[AttentionLine],S.[AttributeName],S.[BillingAddressLine1],S.[BillingAddressLine2],S.[BillingCity],S.[BillingCountry],S.[BillingState],S.[BillingZip],S.[BillToId],S.[CreatedById],S.[CreatedTime],S.[CreditReason],S.[CustomerComments],S.[CustomerInvoiceCommentBeginDate],S.[CustomerInvoiceCommentEndDate],S.[CustomerMainAddressLine1],S.[CustomerMainAddressLine2],S.[CustomerMainCity],S.[CustomerMainCountry],S.[CustomerMainState],S.[CustomerMainZip],S.[CustomerName],S.[CustomerNumber],S.[CustomerTaxRegistrationNumber],S.[DeliverInvoiceViaEmail],S.[DueDate],S.[ExternalExtractBatchId],S.[GenerateInvoiceAddendum],S.[GroupAssets],S.[GSTId],S.[InvoiceId],S.[InvoiceNumber],S.[InvoiceNumberLabel],S.[InvoiceRunDate],S.[InvoiceRunDateLabel],S.[InvoiceType],S.[IsACH],S.[JobStepInstanceId],S.[LegalEntityName],S.[LegalEntityNumber],S.[LessorAddressLine1],S.[LessorAddressLine2],S.[LessorCity],S.[LessorContactEmail],S.[LessorContactPhone],S.[LessorCountry],S.[LessorState],S.[LessorTaxRegistrationNumber],S.[LessorWebAddress],S.[LessorZip],S.[LogoId],S.[OCRMCR],S.[OriginalInvoiceNumber],S.[RemitToAccountNumber],S.[RemitToCode],S.[RemitToIBAN],S.[RemitToName],S.[RemitToSWIFTCode],S.[RemitToTransitCode],S.[ReportFormatName],S.[TotalReceivableAmount_Amount],S.[TotalReceivableAmount_Currency],S.[TotalTaxAmount_Amount],S.[TotalTaxAmount_Currency],S.[UseDynamicContentForInvoiceAddendumBody])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveInvoiceExtractReceivableDetail]
(
 @val [dbo].[InvoiceExtractReceivableDetail] READONLY
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
MERGE [dbo].[InvoiceExtractReceivableDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AdditionalComments]=S.[AdditionalComments],[AdditionalInvoiceCommentBeginDate]=S.[AdditionalInvoiceCommentBeginDate],[AdditionalInvoiceCommentEndDate]=S.[AdditionalInvoiceCommentEndDate],[AlternateBillingCurrencyCodeId]=S.[AlternateBillingCurrencyCodeId],[AssetAddressLine1]=S.[AssetAddressLine1],[AssetAddressLine2]=S.[AssetAddressLine2],[AssetCity]=S.[AssetCity],[AssetCountry]=S.[AssetCountry],[AssetDescription]=S.[AssetDescription],[AssetDivision]=S.[AssetDivision],[AssetId]=S.[AssetId],[AssetPostalCode]=S.[AssetPostalCode],[AssetPurchaseOrderNumber]=S.[AssetPurchaseOrderNumber],[AssetSerialNumber]=S.[AssetSerialNumber],[AssetState]=S.[AssetState],[BlendNumber]=S.[BlendNumber],[ContractPurchaseOrderNumber]=S.[ContractPurchaseOrderNumber],[EntityId]=S.[EntityId],[EntityType]=S.[EntityType],[ExchangeRate]=S.[ExchangeRate],[InvoiceId]=S.[InvoiceId],[IsDownPaymentVATReceivable]=S.[IsDownPaymentVATReceivable],[MaturityDate]=S.[MaturityDate],[PeriodEndDate]=S.[PeriodEndDate],[PeriodStartDate]=S.[PeriodStartDate],[ReceivableAmount_Amount]=S.[ReceivableAmount_Amount],[ReceivableAmount_Currency]=S.[ReceivableAmount_Currency],[ReceivableCategoryId]=S.[ReceivableCategoryId],[ReceivableCodeId]=S.[ReceivableCodeId],[ReceivableDetailId]=S.[ReceivableDetailId],[ReceivableInvoiceDetailId]=S.[ReceivableInvoiceDetailId],[SequenceNumber]=S.[SequenceNumber],[TaxAmount_Amount]=S.[TaxAmount_Amount],[TaxAmount_Currency]=S.[TaxAmount_Currency],[u_CustomerReference1]=S.[u_CustomerReference1],[u_CustomerReference2]=S.[u_CustomerReference2],[u_CustomerReference3]=S.[u_CustomerReference3],[u_CustomerReference4]=S.[u_CustomerReference4],[u_CustomerReference5]=S.[u_CustomerReference5],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[WithHoldingTax_Amount]=S.[WithHoldingTax_Amount],[WithHoldingTax_Currency]=S.[WithHoldingTax_Currency]
WHEN NOT MATCHED THEN
	INSERT ([AdditionalComments],[AdditionalInvoiceCommentBeginDate],[AdditionalInvoiceCommentEndDate],[AlternateBillingCurrencyCodeId],[AssetAddressLine1],[AssetAddressLine2],[AssetCity],[AssetCountry],[AssetDescription],[AssetDivision],[AssetId],[AssetPostalCode],[AssetPurchaseOrderNumber],[AssetSerialNumber],[AssetState],[BlendNumber],[ContractPurchaseOrderNumber],[CreatedById],[CreatedTime],[EntityId],[EntityType],[ExchangeRate],[InvoiceId],[IsDownPaymentVATReceivable],[MaturityDate],[PeriodEndDate],[PeriodStartDate],[ReceivableAmount_Amount],[ReceivableAmount_Currency],[ReceivableCategoryId],[ReceivableCodeId],[ReceivableDetailId],[ReceivableInvoiceDetailId],[SequenceNumber],[TaxAmount_Amount],[TaxAmount_Currency],[u_CustomerReference1],[u_CustomerReference2],[u_CustomerReference3],[u_CustomerReference4],[u_CustomerReference5],[WithHoldingTax_Amount],[WithHoldingTax_Currency])
    VALUES (S.[AdditionalComments],S.[AdditionalInvoiceCommentBeginDate],S.[AdditionalInvoiceCommentEndDate],S.[AlternateBillingCurrencyCodeId],S.[AssetAddressLine1],S.[AssetAddressLine2],S.[AssetCity],S.[AssetCountry],S.[AssetDescription],S.[AssetDivision],S.[AssetId],S.[AssetPostalCode],S.[AssetPurchaseOrderNumber],S.[AssetSerialNumber],S.[AssetState],S.[BlendNumber],S.[ContractPurchaseOrderNumber],S.[CreatedById],S.[CreatedTime],S.[EntityId],S.[EntityType],S.[ExchangeRate],S.[InvoiceId],S.[IsDownPaymentVATReceivable],S.[MaturityDate],S.[PeriodEndDate],S.[PeriodStartDate],S.[ReceivableAmount_Amount],S.[ReceivableAmount_Currency],S.[ReceivableCategoryId],S.[ReceivableCodeId],S.[ReceivableDetailId],S.[ReceivableInvoiceDetailId],S.[SequenceNumber],S.[TaxAmount_Amount],S.[TaxAmount_Currency],S.[u_CustomerReference1],S.[u_CustomerReference2],S.[u_CustomerReference3],S.[u_CustomerReference4],S.[u_CustomerReference5],S.[WithHoldingTax_Amount],S.[WithHoldingTax_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceivableInvoiceDetail]
(
 @val [dbo].[ReceivableInvoiceDetail] READONLY
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
MERGE [dbo].[ReceivableInvoiceDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Balance_Amount]=S.[Balance_Amount],[Balance_Currency]=S.[Balance_Currency],[BlendNumber]=S.[BlendNumber],[EffectiveBalance_Amount]=S.[EffectiveBalance_Amount],[EffectiveBalance_Currency]=S.[EffectiveBalance_Currency],[EffectiveTaxBalance_Amount]=S.[EffectiveTaxBalance_Amount],[EffectiveTaxBalance_Currency]=S.[EffectiveTaxBalance_Currency],[EntityId]=S.[EntityId],[EntityType]=S.[EntityType],[ExchangeRate]=S.[ExchangeRate],[InvoiceAmount_Amount]=S.[InvoiceAmount_Amount],[InvoiceAmount_Currency]=S.[InvoiceAmount_Currency],[InvoiceTaxAmount_Amount]=S.[InvoiceTaxAmount_Amount],[InvoiceTaxAmount_Currency]=S.[InvoiceTaxAmount_Currency],[IsActive]=S.[IsActive],[PaymentType]=S.[PaymentType],[ReceivableAmount_Amount]=S.[ReceivableAmount_Amount],[ReceivableAmount_Currency]=S.[ReceivableAmount_Currency],[ReceivableCategoryId]=S.[ReceivableCategoryId],[ReceivableDetailId]=S.[ReceivableDetailId],[ReceivableId]=S.[ReceivableId],[ReceivableTypeId]=S.[ReceivableTypeId],[SequenceNumber]=S.[SequenceNumber],[TaxAmount_Amount]=S.[TaxAmount_Amount],[TaxAmount_Currency]=S.[TaxAmount_Currency],[TaxBalance_Amount]=S.[TaxBalance_Amount],[TaxBalance_Currency]=S.[TaxBalance_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Balance_Amount],[Balance_Currency],[BlendNumber],[CreatedById],[CreatedTime],[EffectiveBalance_Amount],[EffectiveBalance_Currency],[EffectiveTaxBalance_Amount],[EffectiveTaxBalance_Currency],[EntityId],[EntityType],[ExchangeRate],[InvoiceAmount_Amount],[InvoiceAmount_Currency],[InvoiceTaxAmount_Amount],[InvoiceTaxAmount_Currency],[IsActive],[PaymentType],[ReceivableAmount_Amount],[ReceivableAmount_Currency],[ReceivableCategoryId],[ReceivableDetailId],[ReceivableId],[ReceivableInvoiceId],[ReceivableTypeId],[SequenceNumber],[TaxAmount_Amount],[TaxAmount_Currency],[TaxBalance_Amount],[TaxBalance_Currency])
    VALUES (S.[Balance_Amount],S.[Balance_Currency],S.[BlendNumber],S.[CreatedById],S.[CreatedTime],S.[EffectiveBalance_Amount],S.[EffectiveBalance_Currency],S.[EffectiveTaxBalance_Amount],S.[EffectiveTaxBalance_Currency],S.[EntityId],S.[EntityType],S.[ExchangeRate],S.[InvoiceAmount_Amount],S.[InvoiceAmount_Currency],S.[InvoiceTaxAmount_Amount],S.[InvoiceTaxAmount_Currency],S.[IsActive],S.[PaymentType],S.[ReceivableAmount_Amount],S.[ReceivableAmount_Currency],S.[ReceivableCategoryId],S.[ReceivableDetailId],S.[ReceivableId],S.[ReceivableInvoiceId],S.[ReceivableTypeId],S.[SequenceNumber],S.[TaxAmount_Amount],S.[TaxAmount_Currency],S.[TaxBalance_Amount],S.[TaxBalance_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

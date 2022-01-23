SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveBillToInvoiceFormat]
(
 @val [dbo].[BillToInvoiceFormat] READONLY
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
MERGE [dbo].[BillToInvoiceFormats] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [InvoiceEmailTemplateId]=S.[InvoiceEmailTemplateId],[InvoiceFormatId]=S.[InvoiceFormatId],[InvoiceOutputFormat]=S.[InvoiceOutputFormat],[InvoiceTypeLabelId]=S.[InvoiceTypeLabelId],[IsActive]=S.[IsActive],[ReceivableCategory]=S.[ReceivableCategory],[ReceivableCategoryId]=S.[ReceivableCategoryId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VATInvoiceFormatId]=S.[VATInvoiceFormatId]
WHEN NOT MATCHED THEN
	INSERT ([BillToId],[CreatedById],[CreatedTime],[InvoiceEmailTemplateId],[InvoiceFormatId],[InvoiceOutputFormat],[InvoiceTypeLabelId],[IsActive],[ReceivableCategory],[ReceivableCategoryId],[VATInvoiceFormatId])
    VALUES (S.[BillToId],S.[CreatedById],S.[CreatedTime],S.[InvoiceEmailTemplateId],S.[InvoiceFormatId],S.[InvoiceOutputFormat],S.[InvoiceTypeLabelId],S.[IsActive],S.[ReceivableCategory],S.[ReceivableCategoryId],S.[VATInvoiceFormatId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

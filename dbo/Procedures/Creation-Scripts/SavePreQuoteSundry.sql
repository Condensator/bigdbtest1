SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePreQuoteSundry]
(
 @val [dbo].[PreQuoteSundry] READONLY
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
MERGE [dbo].[PreQuoteSundries] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[BillToId]=S.[BillToId],[ContractId]=S.[ContractId],[CustomerId]=S.[CustomerId],[IncludeInPayoffInvoice]=S.[IncludeInPayoffInvoice],[IsActive]=S.[IsActive],[IsSalesTaxAssessed]=S.[IsSalesTaxAssessed],[LocationId]=S.[LocationId],[PayableCodeId]=S.[PayableCodeId],[PayableRemitToId]=S.[PayableRemitToId],[PayableWithholdingTaxRate]=S.[PayableWithholdingTaxRate],[ReceivableCodeId]=S.[ReceivableCodeId],[ReceivableRemitToId]=S.[ReceivableRemitToId],[SalesTaxAmount_Amount]=S.[SalesTaxAmount_Amount],[SalesTaxAmount_Currency]=S.[SalesTaxAmount_Currency],[SundryType]=S.[SundryType],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VendorId]=S.[VendorId]
WHEN NOT MATCHED THEN
	INSERT ([Amount_Amount],[Amount_Currency],[BillToId],[ContractId],[CreatedById],[CreatedTime],[CustomerId],[IncludeInPayoffInvoice],[IsActive],[IsSalesTaxAssessed],[LocationId],[PayableCodeId],[PayableRemitToId],[PayableWithholdingTaxRate],[PreQuoteId],[ReceivableCodeId],[ReceivableRemitToId],[SalesTaxAmount_Amount],[SalesTaxAmount_Currency],[SundryType],[VendorId])
    VALUES (S.[Amount_Amount],S.[Amount_Currency],S.[BillToId],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[CustomerId],S.[IncludeInPayoffInvoice],S.[IsActive],S.[IsSalesTaxAssessed],S.[LocationId],S.[PayableCodeId],S.[PayableRemitToId],S.[PayableWithholdingTaxRate],S.[PreQuoteId],S.[ReceivableCodeId],S.[ReceivableRemitToId],S.[SalesTaxAmount_Amount],S.[SalesTaxAmount_Currency],S.[SundryType],S.[VendorId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

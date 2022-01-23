SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePayoffSundry]
(
 @val [dbo].[PayoffSundry] READONLY
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
MERGE [dbo].[PayoffSundries] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[BillToId]=S.[BillToId],[Comment]=S.[Comment],[CustomerId]=S.[CustomerId],[IncludeInPayoffInvoice]=S.[IncludeInPayoffInvoice],[IsActive]=S.[IsActive],[IsSystemGenerated]=S.[IsSystemGenerated],[LocationId]=S.[LocationId],[PayableCodeId]=S.[PayableCodeId],[PayableWithholdingTaxRate]=S.[PayableWithholdingTaxRate],[ReceivableCodeId]=S.[ReceivableCodeId],[ReferenceNumber]=S.[ReferenceNumber],[RemitToId]=S.[RemitToId],[SundryId]=S.[SundryId],[SundryType]=S.[SundryType],[SystemGeneratedType]=S.[SystemGeneratedType],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VATAmount_Amount]=S.[VATAmount_Amount],[VATAmount_Currency]=S.[VATAmount_Currency],[VendorId]=S.[VendorId]
WHEN NOT MATCHED THEN
	INSERT ([Amount_Amount],[Amount_Currency],[BillToId],[Comment],[CreatedById],[CreatedTime],[CustomerId],[IncludeInPayoffInvoice],[IsActive],[IsSystemGenerated],[LocationId],[PayableCodeId],[PayableWithholdingTaxRate],[PayoffId],[ReceivableCodeId],[ReferenceNumber],[RemitToId],[SundryId],[SundryType],[SystemGeneratedType],[VATAmount_Amount],[VATAmount_Currency],[VendorId])
    VALUES (S.[Amount_Amount],S.[Amount_Currency],S.[BillToId],S.[Comment],S.[CreatedById],S.[CreatedTime],S.[CustomerId],S.[IncludeInPayoffInvoice],S.[IsActive],S.[IsSystemGenerated],S.[LocationId],S.[PayableCodeId],S.[PayableWithholdingTaxRate],S.[PayoffId],S.[ReceivableCodeId],S.[ReferenceNumber],S.[RemitToId],S.[SundryId],S.[SundryType],S.[SystemGeneratedType],S.[VATAmount_Amount],S.[VATAmount_Currency],S.[VendorId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceivableInvoiceReceiptDetail]
(
 @val [dbo].[ReceivableInvoiceReceiptDetail] READONLY
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
MERGE [dbo].[ReceivableInvoiceReceiptDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AmountApplied_Amount]=S.[AmountApplied_Amount],[AmountApplied_Currency]=S.[AmountApplied_Currency],[IsActive]=S.[IsActive],[ReceiptId]=S.[ReceiptId],[ReceivedDate]=S.[ReceivedDate],[TaxApplied_Amount]=S.[TaxApplied_Amount],[TaxApplied_Currency]=S.[TaxApplied_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AmountApplied_Amount],[AmountApplied_Currency],[CreatedById],[CreatedTime],[IsActive],[ReceiptId],[ReceivableInvoiceId],[ReceivedDate],[TaxApplied_Amount],[TaxApplied_Currency])
    VALUES (S.[AmountApplied_Amount],S.[AmountApplied_Currency],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[ReceiptId],S.[ReceivableInvoiceId],S.[ReceivedDate],S.[TaxApplied_Amount],S.[TaxApplied_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

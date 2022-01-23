SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceiptApplicationInvoice]
(
 @val [dbo].[ReceiptApplicationInvoice] READONLY
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
MERGE [dbo].[ReceiptApplicationInvoices] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AdjustedWithHoldingTax_Amount]=S.[AdjustedWithHoldingTax_Amount],[AdjustedWithHoldingTax_Currency]=S.[AdjustedWithHoldingTax_Currency],[AmountApplied_Amount]=S.[AmountApplied_Amount],[AmountApplied_Currency]=S.[AmountApplied_Currency],[IsActive]=S.[IsActive],[IsReApplication]=S.[IsReApplication],[PreviousAdjustedWithHoldingTax_Amount]=S.[PreviousAdjustedWithHoldingTax_Amount],[PreviousAdjustedWithHoldingTax_Currency]=S.[PreviousAdjustedWithHoldingTax_Currency],[PreviousAmountApplied_Amount]=S.[PreviousAmountApplied_Amount],[PreviousAmountApplied_Currency]=S.[PreviousAmountApplied_Currency],[PreviousTaxApplied_Amount]=S.[PreviousTaxApplied_Amount],[PreviousTaxApplied_Currency]=S.[PreviousTaxApplied_Currency],[ReceivableInvoiceId]=S.[ReceivableInvoiceId],[ReceivedAmount_Amount]=S.[ReceivedAmount_Amount],[ReceivedAmount_Currency]=S.[ReceivedAmount_Currency],[TaxApplied_Amount]=S.[TaxApplied_Amount],[TaxApplied_Currency]=S.[TaxApplied_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AdjustedWithHoldingTax_Amount],[AdjustedWithHoldingTax_Currency],[AmountApplied_Amount],[AmountApplied_Currency],[CreatedById],[CreatedTime],[IsActive],[IsReApplication],[PreviousAdjustedWithHoldingTax_Amount],[PreviousAdjustedWithHoldingTax_Currency],[PreviousAmountApplied_Amount],[PreviousAmountApplied_Currency],[PreviousTaxApplied_Amount],[PreviousTaxApplied_Currency],[ReceiptApplicationId],[ReceivableInvoiceId],[ReceivedAmount_Amount],[ReceivedAmount_Currency],[TaxApplied_Amount],[TaxApplied_Currency])
    VALUES (S.[AdjustedWithHoldingTax_Amount],S.[AdjustedWithHoldingTax_Currency],S.[AmountApplied_Amount],S.[AmountApplied_Currency],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[IsReApplication],S.[PreviousAdjustedWithHoldingTax_Amount],S.[PreviousAdjustedWithHoldingTax_Currency],S.[PreviousAmountApplied_Amount],S.[PreviousAmountApplied_Currency],S.[PreviousTaxApplied_Amount],S.[PreviousTaxApplied_Currency],S.[ReceiptApplicationId],S.[ReceivableInvoiceId],S.[ReceivedAmount_Amount],S.[ReceivedAmount_Currency],S.[TaxApplied_Amount],S.[TaxApplied_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

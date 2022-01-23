SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceiptApplicationReceivableDetails_Extract]
(
 @val [dbo].[ReceiptApplicationReceivableDetails_Extract] READONLY
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
MERGE [dbo].[ReceiptApplicationReceivableDetails_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AdjustedWithHoldingTax]=S.[AdjustedWithHoldingTax],[AmountApplied]=S.[AmountApplied],[BookAmountApplied]=S.[BookAmountApplied],[ContractId]=S.[ContractId],[DiscountingId]=S.[DiscountingId],[DumpId]=S.[DumpId],[InvoiceId]=S.[InvoiceId],[IsReApplication]=S.[IsReApplication],[JobStepInstanceId]=S.[JobStepInstanceId],[LeaseComponentAmountApplied]=S.[LeaseComponentAmountApplied],[NonLeaseComponentAmountApplied]=S.[NonLeaseComponentAmountApplied],[PrevAdjustedWithHoldingTaxForReApplication]=S.[PrevAdjustedWithHoldingTaxForReApplication],[PrevAmountAppliedForReApplication]=S.[PrevAmountAppliedForReApplication],[PrevBookAmountAppliedForReApplication]=S.[PrevBookAmountAppliedForReApplication],[PrevLeaseComponentAmountAppliedForReApplication]=S.[PrevLeaseComponentAmountAppliedForReApplication],[PrevNonLeaseComponentAmountAppliedForReApplication]=S.[PrevNonLeaseComponentAmountAppliedForReApplication],[PrevPrePaidForReApplication]=S.[PrevPrePaidForReApplication],[PrevPrePaidLeaseComponentForReApplication]=S.[PrevPrePaidLeaseComponentForReApplication],[PrevPrePaidNonLeaseComponentForReApplication]=S.[PrevPrePaidNonLeaseComponentForReApplication],[PrevPrePaidTaxForReApplication]=S.[PrevPrePaidTaxForReApplication],[PrevTaxAppliedForReApplication]=S.[PrevTaxAppliedForReApplication],[ReceiptApplicationId]=S.[ReceiptApplicationId],[ReceiptApplicationReceivableDetailId]=S.[ReceiptApplicationReceivableDetailId],[ReceiptId]=S.[ReceiptId],[ReceivableDetailId]=S.[ReceivableDetailId],[ReceivableDetailIsActive]=S.[ReceivableDetailIsActive],[ReceivableId]=S.[ReceivableId],[ReceivedTowardsInterest]=S.[ReceivedTowardsInterest],[TaxApplied]=S.[TaxApplied],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[WithHoldingTaxBookAmountApplied]=S.[WithHoldingTaxBookAmountApplied]
WHEN NOT MATCHED THEN
	INSERT ([AdjustedWithHoldingTax],[AmountApplied],[BookAmountApplied],[ContractId],[CreatedById],[CreatedTime],[DiscountingId],[DumpId],[InvoiceId],[IsReApplication],[JobStepInstanceId],[LeaseComponentAmountApplied],[NonLeaseComponentAmountApplied],[PrevAdjustedWithHoldingTaxForReApplication],[PrevAmountAppliedForReApplication],[PrevBookAmountAppliedForReApplication],[PrevLeaseComponentAmountAppliedForReApplication],[PrevNonLeaseComponentAmountAppliedForReApplication],[PrevPrePaidForReApplication],[PrevPrePaidLeaseComponentForReApplication],[PrevPrePaidNonLeaseComponentForReApplication],[PrevPrePaidTaxForReApplication],[PrevTaxAppliedForReApplication],[ReceiptApplicationId],[ReceiptApplicationReceivableDetailId],[ReceiptId],[ReceivableDetailId],[ReceivableDetailIsActive],[ReceivableId],[ReceivedTowardsInterest],[TaxApplied],[WithHoldingTaxBookAmountApplied])
    VALUES (S.[AdjustedWithHoldingTax],S.[AmountApplied],S.[BookAmountApplied],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[DiscountingId],S.[DumpId],S.[InvoiceId],S.[IsReApplication],S.[JobStepInstanceId],S.[LeaseComponentAmountApplied],S.[NonLeaseComponentAmountApplied],S.[PrevAdjustedWithHoldingTaxForReApplication],S.[PrevAmountAppliedForReApplication],S.[PrevBookAmountAppliedForReApplication],S.[PrevLeaseComponentAmountAppliedForReApplication],S.[PrevNonLeaseComponentAmountAppliedForReApplication],S.[PrevPrePaidForReApplication],S.[PrevPrePaidLeaseComponentForReApplication],S.[PrevPrePaidNonLeaseComponentForReApplication],S.[PrevPrePaidTaxForReApplication],S.[PrevTaxAppliedForReApplication],S.[ReceiptApplicationId],S.[ReceiptApplicationReceivableDetailId],S.[ReceiptId],S.[ReceivableDetailId],S.[ReceivableDetailIsActive],S.[ReceivableId],S.[ReceivedTowardsInterest],S.[TaxApplied],S.[WithHoldingTaxBookAmountApplied])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceiptDetailsMigration_Extract]
(
 @val [dbo].[ReceiptDetailsMigration_Extract] READONLY
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
MERGE [dbo].[ReceiptDetailsMigration_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ContractId]=S.[ContractId],[DiscountingId]=S.[DiscountingId],[DumpId]=S.[DumpId],[EffectiveBalance_Amount]=S.[EffectiveBalance_Amount],[EffectiveBalance_Currency]=S.[EffectiveBalance_Currency],[EffectiveTaxBalance_Amount]=S.[EffectiveTaxBalance_Amount],[EffectiveTaxBalance_Currency]=S.[EffectiveTaxBalance_Currency],[InvoiceBalance_Amount_Amount]=S.[InvoiceBalance_Amount_Amount],[InvoiceBalance_Amount_Currency]=S.[InvoiceBalance_Amount_Currency],[InvoiceId]=S.[InvoiceId],[IsReApplication]=S.[IsReApplication],[JobStepInstanceId]=S.[JobStepInstanceId],[PrevAmountAppliedForReApplication_Amount]=S.[PrevAmountAppliedForReApplication_Amount],[PrevAmountAppliedForReApplication_Currency]=S.[PrevAmountAppliedForReApplication_Currency],[PrevBookAmountAppliedForReApplication_Amount]=S.[PrevBookAmountAppliedForReApplication_Amount],[PrevBookAmountAppliedForReApplication_Currency]=S.[PrevBookAmountAppliedForReApplication_Currency],[PrevTaxAppliedForReApplication_Amount]=S.[PrevTaxAppliedForReApplication_Amount],[PrevTaxAppliedForReApplication_Currency]=S.[PrevTaxAppliedForReApplication_Currency],[ReceiptApplicationReceivableDetailId]=S.[ReceiptApplicationReceivableDetailId],[ReceiptId]=S.[ReceiptId],[ReceivableDetailId]=S.[ReceivableDetailId],[ReceivableDetailIsActive]=S.[ReceivableDetailIsActive],[ReceivableId]=S.[ReceivableId],[ReceivableTaxDetailId]=S.[ReceivableTaxDetailId],[ReceivableTaxId]=S.[ReceivableTaxId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ContractId],[CreatedById],[CreatedTime],[DiscountingId],[DumpId],[EffectiveBalance_Amount],[EffectiveBalance_Currency],[EffectiveTaxBalance_Amount],[EffectiveTaxBalance_Currency],[InvoiceBalance_Amount_Amount],[InvoiceBalance_Amount_Currency],[InvoiceId],[IsReApplication],[JobStepInstanceId],[PrevAmountAppliedForReApplication_Amount],[PrevAmountAppliedForReApplication_Currency],[PrevBookAmountAppliedForReApplication_Amount],[PrevBookAmountAppliedForReApplication_Currency],[PrevTaxAppliedForReApplication_Amount],[PrevTaxAppliedForReApplication_Currency],[ReceiptApplicationReceivableDetailId],[ReceiptId],[ReceivableDetailId],[ReceivableDetailIsActive],[ReceivableId],[ReceivableTaxDetailId],[ReceivableTaxId])
    VALUES (S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[DiscountingId],S.[DumpId],S.[EffectiveBalance_Amount],S.[EffectiveBalance_Currency],S.[EffectiveTaxBalance_Amount],S.[EffectiveTaxBalance_Currency],S.[InvoiceBalance_Amount_Amount],S.[InvoiceBalance_Amount_Currency],S.[InvoiceId],S.[IsReApplication],S.[JobStepInstanceId],S.[PrevAmountAppliedForReApplication_Amount],S.[PrevAmountAppliedForReApplication_Currency],S.[PrevBookAmountAppliedForReApplication_Amount],S.[PrevBookAmountAppliedForReApplication_Currency],S.[PrevTaxAppliedForReApplication_Amount],S.[PrevTaxAppliedForReApplication_Currency],S.[ReceiptApplicationReceivableDetailId],S.[ReceiptId],S.[ReceivableDetailId],S.[ReceivableDetailIsActive],S.[ReceivableId],S.[ReceivableTaxDetailId],S.[ReceivableTaxId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

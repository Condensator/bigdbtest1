SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceipt]
(
 @val [dbo].[Receipt] READONLY
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
MERGE [dbo].[Receipts] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ApplyByReceivable]=S.[ApplyByReceivable],[Balance_Amount]=S.[Balance_Amount],[Balance_Currency]=S.[Balance_Currency],[BankAccountId]=S.[BankAccountId],[BankName]=S.[BankName],[BillToId]=S.[BillToId],[BranchId]=S.[BranchId],[CashTypeId]=S.[CashTypeId],[CheckDate]=S.[CheckDate],[CheckNumber]=S.[CheckNumber],[Comment]=S.[Comment],[ContractId]=S.[ContractId],[CostCenterId]=S.[CostCenterId],[CreateRefund]=S.[CreateRefund],[CurrencyId]=S.[CurrencyId],[CustomerId]=S.[CustomerId],[DealCountryId]=S.[DealCountryId],[DiscountingId]=S.[DiscountingId],[DueDate]=S.[DueDate],[EntityType]=S.[EntityType],[EscrowGLTemplateId]=S.[EscrowGLTemplateId],[InstrumentTypeId]=S.[InstrumentTypeId],[IsFromReceiptBatch]=S.[IsFromReceiptBatch],[IsReceiptCreatedFromLockBox]=S.[IsReceiptCreatedFromLockBox],[JobId]=S.[JobId],[JobStepInstanceId]=S.[JobStepInstanceId],[LegalEntityId]=S.[LegalEntityId],[LineofBusinessId]=S.[LineofBusinessId],[LocationId]=S.[LocationId],[NameOnCheck]=S.[NameOnCheck],[NonCashReason]=S.[NonCashReason],[Number]=S.[Number],[OriginalReceiptId]=S.[OriginalReceiptId],[PayableCodeId]=S.[PayableCodeId],[PayableDate]=S.[PayableDate],[PayableRemitToId]=S.[PayableRemitToId],[PayableWithholdingTaxRate]=S.[PayableWithholdingTaxRate],[PostDate]=S.[PostDate],[ReceiptAmount_Amount]=S.[ReceiptAmount_Amount],[ReceiptAmount_Currency]=S.[ReceiptAmount_Currency],[ReceiptBatchId]=S.[ReceiptBatchId],[ReceiptClassification]=S.[ReceiptClassification],[ReceiptGLTemplateId]=S.[ReceiptGLTemplateId],[ReceivableCodeId]=S.[ReceivableCodeId],[ReceivableInvoiceId]=S.[ReceivableInvoiceId],[ReceivableRemitToId]=S.[ReceivableRemitToId],[ReceivedDate]=S.[ReceivedDate],[ReversalAsOfDate]=S.[ReversalAsOfDate],[ReversalDate]=S.[ReversalDate],[ReversalPostDate]=S.[ReversalPostDate],[ReversalReasonId]=S.[ReversalReasonId],[SecurityDepositLiabilityAmount_Amount]=S.[SecurityDepositLiabilityAmount_Amount],[SecurityDepositLiabilityAmount_Currency]=S.[SecurityDepositLiabilityAmount_Currency],[SecurityDepositLiabilityContractAmount_Amount]=S.[SecurityDepositLiabilityContractAmount_Amount],[SecurityDepositLiabilityContractAmount_Currency]=S.[SecurityDepositLiabilityContractAmount_Currency],[Status]=S.[Status],[SundryId]=S.[SundryId],[TypeId]=S.[TypeId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VendorId]=S.[VendorId]
WHEN NOT MATCHED THEN
	INSERT ([ApplyByReceivable],[Balance_Amount],[Balance_Currency],[BankAccountId],[BankName],[BillToId],[BranchId],[CashTypeId],[CheckDate],[CheckNumber],[Comment],[ContractId],[CostCenterId],[CreatedById],[CreatedTime],[CreateRefund],[CurrencyId],[CustomerId],[DealCountryId],[DiscountingId],[DueDate],[EntityType],[EscrowGLTemplateId],[InstrumentTypeId],[IsFromReceiptBatch],[IsReceiptCreatedFromLockBox],[JobId],[JobStepInstanceId],[LegalEntityId],[LineofBusinessId],[LocationId],[NameOnCheck],[NonCashReason],[Number],[OriginalReceiptId],[PayableCodeId],[PayableDate],[PayableRemitToId],[PayableWithholdingTaxRate],[PostDate],[ReceiptAmount_Amount],[ReceiptAmount_Currency],[ReceiptBatchId],[ReceiptClassification],[ReceiptGLTemplateId],[ReceivableCodeId],[ReceivableInvoiceId],[ReceivableRemitToId],[ReceivedDate],[ReversalAsOfDate],[ReversalDate],[ReversalPostDate],[ReversalReasonId],[SecurityDepositLiabilityAmount_Amount],[SecurityDepositLiabilityAmount_Currency],[SecurityDepositLiabilityContractAmount_Amount],[SecurityDepositLiabilityContractAmount_Currency],[Status],[SundryId],[TypeId],[VendorId])
    VALUES (S.[ApplyByReceivable],S.[Balance_Amount],S.[Balance_Currency],S.[BankAccountId],S.[BankName],S.[BillToId],S.[BranchId],S.[CashTypeId],S.[CheckDate],S.[CheckNumber],S.[Comment],S.[ContractId],S.[CostCenterId],S.[CreatedById],S.[CreatedTime],S.[CreateRefund],S.[CurrencyId],S.[CustomerId],S.[DealCountryId],S.[DiscountingId],S.[DueDate],S.[EntityType],S.[EscrowGLTemplateId],S.[InstrumentTypeId],S.[IsFromReceiptBatch],S.[IsReceiptCreatedFromLockBox],S.[JobId],S.[JobStepInstanceId],S.[LegalEntityId],S.[LineofBusinessId],S.[LocationId],S.[NameOnCheck],S.[NonCashReason],S.[Number],S.[OriginalReceiptId],S.[PayableCodeId],S.[PayableDate],S.[PayableRemitToId],S.[PayableWithholdingTaxRate],S.[PostDate],S.[ReceiptAmount_Amount],S.[ReceiptAmount_Currency],S.[ReceiptBatchId],S.[ReceiptClassification],S.[ReceiptGLTemplateId],S.[ReceivableCodeId],S.[ReceivableInvoiceId],S.[ReceivableRemitToId],S.[ReceivedDate],S.[ReversalAsOfDate],S.[ReversalDate],S.[ReversalPostDate],S.[ReversalReasonId],S.[SecurityDepositLiabilityAmount_Amount],S.[SecurityDepositLiabilityAmount_Currency],S.[SecurityDepositLiabilityContractAmount_Amount],S.[SecurityDepositLiabilityContractAmount_Currency],S.[Status],S.[SundryId],S.[TypeId],S.[VendorId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

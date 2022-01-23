SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCommonExternalReceipt_Extract]
(
 @val [dbo].[CommonExternalReceipt_Extract] READONLY
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
MERGE [dbo].[CommonExternalReceipt_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ApplyByReceivable]=S.[ApplyByReceivable],[BankAccount]=S.[BankAccount],[BankAccountId]=S.[BankAccountId],[BankBranchName]=S.[BankBranchName],[BankName]=S.[BankName],[CashType]=S.[CashType],[CheckDate]=S.[CheckDate],[CheckNumber]=S.[CheckNumber],[Comment]=S.[Comment],[ContractLegalEntityId]=S.[ContractLegalEntityId],[CostCenter]=S.[CostCenter],[CostCenterId]=S.[CostCenterId],[CreateUnallocatedReceipt]=S.[CreateUnallocatedReceipt],[Currency]=S.[Currency],[CurrencyId]=S.[CurrencyId],[DumpId]=S.[DumpId],[EntityId]=S.[EntityId],[EntityType]=S.[EntityType],[GUID]=S.[GUID],[InstrumentType]=S.[InstrumentType],[InstrumentTypeId]=S.[InstrumentTypeId],[InvoiceNumber]=S.[InvoiceNumber],[IsApplyCredit]=S.[IsApplyCredit],[IsFullPosting]=S.[IsFullPosting],[IsValid]=S.[IsValid],[JobStepInstanceId]=S.[JobStepInstanceId],[LegalEntityId]=S.[LegalEntityId],[LegalEntityNumber]=S.[LegalEntityNumber],[LineOfBusiness]=S.[LineOfBusiness],[LineOfBusinessId]=S.[LineOfBusinessId],[NameOnCheck]=S.[NameOnCheck],[PartyNumber]=S.[PartyNumber],[PaymentMode]=S.[PaymentMode],[ReceiptAmount]=S.[ReceiptAmount],[ReceiptId]=S.[ReceiptId],[ReceiptType]=S.[ReceiptType],[ReceivableInvoiceId]=S.[ReceivableInvoiceId],[ReceivedDate]=S.[ReceivedDate],[Status]=S.[Status],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ApplyByReceivable],[BankAccount],[BankAccountId],[BankBranchName],[BankName],[CashType],[CheckDate],[CheckNumber],[Comment],[ContractLegalEntityId],[CostCenter],[CostCenterId],[CreatedById],[CreatedTime],[CreateUnallocatedReceipt],[Currency],[CurrencyId],[DumpId],[EntityId],[EntityType],[GUID],[InstrumentType],[InstrumentTypeId],[InvoiceNumber],[IsApplyCredit],[IsFullPosting],[IsValid],[JobStepInstanceId],[LegalEntityId],[LegalEntityNumber],[LineOfBusiness],[LineOfBusinessId],[NameOnCheck],[PartyNumber],[PaymentMode],[ReceiptAmount],[ReceiptId],[ReceiptType],[ReceivableInvoiceId],[ReceivedDate],[Status])
    VALUES (S.[ApplyByReceivable],S.[BankAccount],S.[BankAccountId],S.[BankBranchName],S.[BankName],S.[CashType],S.[CheckDate],S.[CheckNumber],S.[Comment],S.[ContractLegalEntityId],S.[CostCenter],S.[CostCenterId],S.[CreatedById],S.[CreatedTime],S.[CreateUnallocatedReceipt],S.[Currency],S.[CurrencyId],S.[DumpId],S.[EntityId],S.[EntityType],S.[GUID],S.[InstrumentType],S.[InstrumentTypeId],S.[InvoiceNumber],S.[IsApplyCredit],S.[IsFullPosting],S.[IsValid],S.[JobStepInstanceId],S.[LegalEntityId],S.[LegalEntityNumber],S.[LineOfBusiness],S.[LineOfBusinessId],S.[NameOnCheck],S.[PartyNumber],S.[PaymentMode],S.[ReceiptAmount],S.[ReceiptId],S.[ReceiptType],S.[ReceivableInvoiceId],S.[ReceivedDate],S.[Status])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

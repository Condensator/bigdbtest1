SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceiptPostByLockBox_Extract]
(
 @val [dbo].[ReceiptPostByLockBox_Extract] READONLY
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
MERGE [dbo].[ReceiptPostByLockBox_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BankAccountId]=S.[BankAccountId],[BankAccountNumber]=S.[BankAccountNumber],[BankAccountNumberEncrypted]=S.[BankAccountNumberEncrypted],[BankName]=S.[BankName],[CashTypeId]=S.[CashTypeId],[CheckNumber]=S.[CheckNumber],[Comment]=S.[Comment],[ContractId]=S.[ContractId],[ContractNumber]=S.[ContractNumber],[CostCenterId]=S.[CostCenterId],[CreateUnallocatedReceipt]=S.[CreateUnallocatedReceipt],[Currency]=S.[Currency],[CurrencyId]=S.[CurrencyId],[CustomerId]=S.[CustomerId],[CustomerNumber]=S.[CustomerNumber],[DiscountingId]=S.[DiscountingId],[EntityType]=S.[EntityType],[ErrorCode]=S.[ErrorCode],[ErrorMessage]=S.[ErrorMessage],[FileName]=S.[FileName],[GLTemplateId]=S.[GLTemplateId],[HasMandatoryFields]=S.[HasMandatoryFields],[HasMoreInvoice]=S.[HasMoreInvoice],[InstrumentTypeId]=S.[InstrumentTypeId],[InvoiceNumber]=S.[InvoiceNumber],[IsContractCustomerAssociated]=S.[IsContractCustomerAssociated],[IsContractLegalEntityAssociated]=S.[IsContractLegalEntityAssociated],[IsFullPosting]=S.[IsFullPosting],[IsInvoiceContractAssociated]=S.[IsInvoiceContractAssociated],[IsInvoiceCustomerAssociated]=S.[IsInvoiceCustomerAssociated],[IsInvoiceLegalEntityAssociated]=S.[IsInvoiceLegalEntityAssociated],[IsNonAccrualLoan]=S.[IsNonAccrualLoan],[IsStatementInvoice]=S.[IsStatementInvoice],[IsValid]=S.[IsValid],[IsValidBankAccountNumber]=S.[IsValidBankAccountNumber],[IsValidBankName]=S.[IsValidBankName],[IsValidContract]=S.[IsValidContract],[IsValidCustomer]=S.[IsValidCustomer],[IsValidInvoice]=S.[IsValidInvoice],[IsValidLegalEntity]=S.[IsValidLegalEntity],[JobStepInstanceId]=S.[JobStepInstanceId],[LegalEntityId]=S.[LegalEntityId],[LegalEntityNumber]=S.[LegalEntityNumber],[LineOfBusinessId]=S.[LineOfBusinessId],[LockBoxReceiptId]=S.[LockBoxReceiptId],[LockBoxString]=S.[LockBoxString],[MigratedUniqueIdentifier]=S.[MigratedUniqueIdentifier],[PayDownId]=S.[PayDownId],[PayOffId]=S.[PayOffId],[ReceiptBatchId]=S.[ReceiptBatchId],[ReceiptClassification]=S.[ReceiptClassification],[ReceiptTypeId]=S.[ReceiptTypeId],[ReceivableInvoiceId]=S.[ReceivableInvoiceId],[ReceivedAmount]=S.[ReceivedAmount],[ReceivedDate]=S.[ReceivedDate],[RowNumber]=S.[RowNumber],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BankAccountId],[BankAccountNumber],[BankAccountNumberEncrypted],[BankName],[CashTypeId],[CheckNumber],[Comment],[ContractId],[ContractNumber],[CostCenterId],[CreatedById],[CreatedTime],[CreateUnallocatedReceipt],[Currency],[CurrencyId],[CustomerId],[CustomerNumber],[DiscountingId],[EntityType],[ErrorCode],[ErrorMessage],[FileName],[GLTemplateId],[HasMandatoryFields],[HasMoreInvoice],[InstrumentTypeId],[InvoiceNumber],[IsContractCustomerAssociated],[IsContractLegalEntityAssociated],[IsFullPosting],[IsInvoiceContractAssociated],[IsInvoiceCustomerAssociated],[IsInvoiceLegalEntityAssociated],[IsNonAccrualLoan],[IsStatementInvoice],[IsValid],[IsValidBankAccountNumber],[IsValidBankName],[IsValidContract],[IsValidCustomer],[IsValidInvoice],[IsValidLegalEntity],[JobStepInstanceId],[LegalEntityId],[LegalEntityNumber],[LineOfBusinessId],[LockBoxReceiptId],[LockBoxString],[MigratedUniqueIdentifier],[PayDownId],[PayOffId],[ReceiptBatchId],[ReceiptClassification],[ReceiptTypeId],[ReceivableInvoiceId],[ReceivedAmount],[ReceivedDate],[RowNumber])
    VALUES (S.[BankAccountId],S.[BankAccountNumber],S.[BankAccountNumberEncrypted],S.[BankName],S.[CashTypeId],S.[CheckNumber],S.[Comment],S.[ContractId],S.[ContractNumber],S.[CostCenterId],S.[CreatedById],S.[CreatedTime],S.[CreateUnallocatedReceipt],S.[Currency],S.[CurrencyId],S.[CustomerId],S.[CustomerNumber],S.[DiscountingId],S.[EntityType],S.[ErrorCode],S.[ErrorMessage],S.[FileName],S.[GLTemplateId],S.[HasMandatoryFields],S.[HasMoreInvoice],S.[InstrumentTypeId],S.[InvoiceNumber],S.[IsContractCustomerAssociated],S.[IsContractLegalEntityAssociated],S.[IsFullPosting],S.[IsInvoiceContractAssociated],S.[IsInvoiceCustomerAssociated],S.[IsInvoiceLegalEntityAssociated],S.[IsNonAccrualLoan],S.[IsStatementInvoice],S.[IsValid],S.[IsValidBankAccountNumber],S.[IsValidBankName],S.[IsValidContract],S.[IsValidCustomer],S.[IsValidInvoice],S.[IsValidLegalEntity],S.[JobStepInstanceId],S.[LegalEntityId],S.[LegalEntityNumber],S.[LineOfBusinessId],S.[LockBoxReceiptId],S.[LockBoxString],S.[MigratedUniqueIdentifier],S.[PayDownId],S.[PayOffId],S.[ReceiptBatchId],S.[ReceiptClassification],S.[ReceiptTypeId],S.[ReceivableInvoiceId],S.[ReceivedAmount],S.[ReceivedDate],S.[RowNumber])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

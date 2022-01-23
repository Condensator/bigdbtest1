SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceiptPostByFileExcel_Extract]
(
 @val [dbo].[ReceiptPostByFileExcel_Extract] READONLY
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
MERGE [dbo].[ReceiptPostByFileExcel_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BankAccount]=S.[BankAccount],[BankBranchName]=S.[BankBranchName],[BankName]=S.[BankName],[CashType]=S.[CashType],[CheckDate]=S.[CheckDate],[CheckNumber]=S.[CheckNumber],[Comment]=S.[Comment],[ComputedBankAccountCurrencyId]=S.[ComputedBankAccountCurrencyId],[ComputedBankAccountId]=S.[ComputedBankAccountId],[ComputedCashTypeId]=S.[ComputedCashTypeId],[ComputedContractCurrencyId]=S.[ComputedContractCurrencyId],[ComputedContractId]=S.[ComputedContractId],[ComputedContractLegalEntityId]=S.[ComputedContractLegalEntityId],[ComputedCostCenterId]=S.[ComputedCostCenterId],[ComputedCurrencyCodeISO]=S.[ComputedCurrencyCodeISO],[ComputedCurrencyId]=S.[ComputedCurrencyId],[ComputedCustomerId]=S.[ComputedCustomerId],[ComputedDiscountingId]=S.[ComputedDiscountingId],[ComputedGLTemplateId]=S.[ComputedGLTemplateId],[ComputedInstrumentTypeId]=S.[ComputedInstrumentTypeId],[ComputedInvoiceCurrencyId]=S.[ComputedInvoiceCurrencyId],[ComputedInvoiceCustomerId]=S.[ComputedInvoiceCustomerId],[ComputedIsDSL]=S.[ComputedIsDSL],[ComputedIsFullPosting]=S.[ComputedIsFullPosting],[ComputedIsGrouped]=S.[ComputedIsGrouped],[ComputedLegalEntityId]=S.[ComputedLegalEntityId],[ComputedLineOfBusinessId]=S.[ComputedLineOfBusinessId],[ComputedPortfolioId]=S.[ComputedPortfolioId],[ComputedReceiptEntityType]=S.[ComputedReceiptEntityType],[ComputedReceiptTypeId]=S.[ComputedReceiptTypeId],[ComputedReceivableInvoiceId]=S.[ComputedReceivableInvoiceId],[CostCenter]=S.[CostCenter],[CreateUnallocatedReceipt]=S.[CreateUnallocatedReceipt],[Currency]=S.[Currency],[Entity]=S.[Entity],[EntityType]=S.[EntityType],[ErrorMessage]=S.[ErrorMessage],[FileReceiptNumber]=S.[FileReceiptNumber],[GroupNumber]=S.[GroupNumber],[GUID]=S.[GUID],[HasError]=S.[HasError],[InstrumentType]=S.[InstrumentType],[InvoiceNumber]=S.[InvoiceNumber],[IsApplyCredit]=S.[IsApplyCredit],[IsInvoiceInMultipleReceipts]=S.[IsInvoiceInMultipleReceipts],[IsStatementInvoice]=S.[IsStatementInvoice],[JobStepInstanceId]=S.[JobStepInstanceId],[LegalEntity]=S.[LegalEntity],[LineOfBusiness]=S.[LineOfBusiness],[NameOnCheck]=S.[NameOnCheck],[NonAccrualCategory]=S.[NonAccrualCategory],[PayDownId]=S.[PayDownId],[PayOffId]=S.[PayOffId],[ReceiptAmount]=S.[ReceiptAmount],[ReceiptId]=S.[ReceiptId],[ReceiptType]=S.[ReceiptType],[ReceivableTaxType]=S.[ReceivableTaxType],[ReceivedDate]=S.[ReceivedDate],[RowNumber]=S.[RowNumber],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BankAccount],[BankBranchName],[BankName],[CashType],[CheckDate],[CheckNumber],[Comment],[ComputedBankAccountCurrencyId],[ComputedBankAccountId],[ComputedCashTypeId],[ComputedContractCurrencyId],[ComputedContractId],[ComputedContractLegalEntityId],[ComputedCostCenterId],[ComputedCurrencyCodeISO],[ComputedCurrencyId],[ComputedCustomerId],[ComputedDiscountingId],[ComputedGLTemplateId],[ComputedInstrumentTypeId],[ComputedInvoiceCurrencyId],[ComputedInvoiceCustomerId],[ComputedIsDSL],[ComputedIsFullPosting],[ComputedIsGrouped],[ComputedLegalEntityId],[ComputedLineOfBusinessId],[ComputedPortfolioId],[ComputedReceiptEntityType],[ComputedReceiptTypeId],[ComputedReceivableInvoiceId],[CostCenter],[CreatedById],[CreatedTime],[CreateUnallocatedReceipt],[Currency],[Entity],[EntityType],[ErrorMessage],[FileReceiptNumber],[GroupNumber],[GUID],[HasError],[InstrumentType],[InvoiceNumber],[IsApplyCredit],[IsInvoiceInMultipleReceipts],[IsStatementInvoice],[JobStepInstanceId],[LegalEntity],[LineOfBusiness],[NameOnCheck],[NonAccrualCategory],[PayDownId],[PayOffId],[ReceiptAmount],[ReceiptId],[ReceiptType],[ReceivableTaxType],[ReceivedDate],[RowNumber])
    VALUES (S.[BankAccount],S.[BankBranchName],S.[BankName],S.[CashType],S.[CheckDate],S.[CheckNumber],S.[Comment],S.[ComputedBankAccountCurrencyId],S.[ComputedBankAccountId],S.[ComputedCashTypeId],S.[ComputedContractCurrencyId],S.[ComputedContractId],S.[ComputedContractLegalEntityId],S.[ComputedCostCenterId],S.[ComputedCurrencyCodeISO],S.[ComputedCurrencyId],S.[ComputedCustomerId],S.[ComputedDiscountingId],S.[ComputedGLTemplateId],S.[ComputedInstrumentTypeId],S.[ComputedInvoiceCurrencyId],S.[ComputedInvoiceCustomerId],S.[ComputedIsDSL],S.[ComputedIsFullPosting],S.[ComputedIsGrouped],S.[ComputedLegalEntityId],S.[ComputedLineOfBusinessId],S.[ComputedPortfolioId],S.[ComputedReceiptEntityType],S.[ComputedReceiptTypeId],S.[ComputedReceivableInvoiceId],S.[CostCenter],S.[CreatedById],S.[CreatedTime],S.[CreateUnallocatedReceipt],S.[Currency],S.[Entity],S.[EntityType],S.[ErrorMessage],S.[FileReceiptNumber],S.[GroupNumber],S.[GUID],S.[HasError],S.[InstrumentType],S.[InvoiceNumber],S.[IsApplyCredit],S.[IsInvoiceInMultipleReceipts],S.[IsStatementInvoice],S.[JobStepInstanceId],S.[LegalEntity],S.[LineOfBusiness],S.[NameOnCheck],S.[NonAccrualCategory],S.[PayDownId],S.[PayOffId],S.[ReceiptAmount],S.[ReceiptId],S.[ReceiptType],S.[ReceivableTaxType],S.[ReceivedDate],S.[RowNumber])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

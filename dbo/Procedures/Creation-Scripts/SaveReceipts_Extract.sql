SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceipts_Extract]
(
 @val [dbo].[Receipts_Extract] READONLY
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
MERGE [dbo].[Receipts_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ACHReceiptId]=S.[ACHReceiptId],[AcquisitionId]=S.[AcquisitionId],[BankAccountId]=S.[BankAccountId],[BankName]=S.[BankName],[BeforePostingReceiptId]=S.[BeforePostingReceiptId],[BranchId]=S.[BranchId],[CashTypeId]=S.[CashTypeId],[CheckNumber]=S.[CheckNumber],[Comment]=S.[Comment],[ContractHierarchyTemplateId]=S.[ContractHierarchyTemplateId],[ContractId]=S.[ContractId],[ContractLegalEntityHierarchyTemplateId]=S.[ContractLegalEntityHierarchyTemplateId],[ContractLegalEntityId]=S.[ContractLegalEntityId],[CostCenterId]=S.[CostCenterId],[Currency]=S.[Currency],[CurrencyId]=S.[CurrencyId],[CustomerHierarchyTemplateId]=S.[CustomerHierarchyTemplateId],[CustomerId]=S.[CustomerId],[DealProductTypeId]=S.[DealProductTypeId],[DiscountingId]=S.[DiscountingId],[DumpId]=S.[DumpId],[EntityType]=S.[EntityType],[InstrumentTypeId]=S.[InstrumentTypeId],[IsNewReceipt]=S.[IsNewReceipt],[IsReceiptHierarchyProcessed]=S.[IsReceiptHierarchyProcessed],[IsValid]=S.[IsValid],[JobStepInstanceId]=S.[JobStepInstanceId],[LegalEntityHierarchyTemplateId]=S.[LegalEntityHierarchyTemplateId],[LegalEntityId]=S.[LegalEntityId],[LineOfBusinessId]=S.[LineOfBusinessId],[MaxDueDate]=S.[MaxDueDate],[PayDownId]=S.[PayDownId],[PayOffId]=S.[PayOffId],[PostDate]=S.[PostDate],[PPTEscrowGLTemplateId]=S.[PPTEscrowGLTemplateId],[ReceiptAmount]=S.[ReceiptAmount],[ReceiptApplicationId]=S.[ReceiptApplicationId],[ReceiptBatchId]=S.[ReceiptBatchId],[ReceiptClassification]=S.[ReceiptClassification],[ReceiptGLTemplateId]=S.[ReceiptGLTemplateId],[ReceiptHierarchyTemplateId]=S.[ReceiptHierarchyTemplateId],[ReceiptId]=S.[ReceiptId],[ReceiptNumber]=S.[ReceiptNumber],[ReceiptType]=S.[ReceiptType],[ReceiptTypeId]=S.[ReceiptTypeId],[ReceivableTaxType]=S.[ReceivableTaxType],[ReceivedDate]=S.[ReceivedDate],[SecurityDepositGLTemplateId]=S.[SecurityDepositGLTemplateId],[SecurityDepositLiabilityAmount]=S.[SecurityDepositLiabilityAmount],[SecurityDepositLiabilityContractAmount]=S.[SecurityDepositLiabilityContractAmount],[SourceOfError]=S.[SourceOfError],[Status]=S.[Status],[UnallocatedDescription]=S.[UnallocatedDescription],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ACHReceiptId],[AcquisitionId],[BankAccountId],[BankName],[BeforePostingReceiptId],[BranchId],[CashTypeId],[CheckNumber],[Comment],[ContractHierarchyTemplateId],[ContractId],[ContractLegalEntityHierarchyTemplateId],[ContractLegalEntityId],[CostCenterId],[CreatedById],[CreatedTime],[Currency],[CurrencyId],[CustomerHierarchyTemplateId],[CustomerId],[DealProductTypeId],[DiscountingId],[DumpId],[EntityType],[InstrumentTypeId],[IsNewReceipt],[IsReceiptHierarchyProcessed],[IsValid],[JobStepInstanceId],[LegalEntityHierarchyTemplateId],[LegalEntityId],[LineOfBusinessId],[MaxDueDate],[PayDownId],[PayOffId],[PostDate],[PPTEscrowGLTemplateId],[ReceiptAmount],[ReceiptApplicationId],[ReceiptBatchId],[ReceiptClassification],[ReceiptGLTemplateId],[ReceiptHierarchyTemplateId],[ReceiptId],[ReceiptNumber],[ReceiptType],[ReceiptTypeId],[ReceivableTaxType],[ReceivedDate],[SecurityDepositGLTemplateId],[SecurityDepositLiabilityAmount],[SecurityDepositLiabilityContractAmount],[SourceOfError],[Status],[UnallocatedDescription])
    VALUES (S.[ACHReceiptId],S.[AcquisitionId],S.[BankAccountId],S.[BankName],S.[BeforePostingReceiptId],S.[BranchId],S.[CashTypeId],S.[CheckNumber],S.[Comment],S.[ContractHierarchyTemplateId],S.[ContractId],S.[ContractLegalEntityHierarchyTemplateId],S.[ContractLegalEntityId],S.[CostCenterId],S.[CreatedById],S.[CreatedTime],S.[Currency],S.[CurrencyId],S.[CustomerHierarchyTemplateId],S.[CustomerId],S.[DealProductTypeId],S.[DiscountingId],S.[DumpId],S.[EntityType],S.[InstrumentTypeId],S.[IsNewReceipt],S.[IsReceiptHierarchyProcessed],S.[IsValid],S.[JobStepInstanceId],S.[LegalEntityHierarchyTemplateId],S.[LegalEntityId],S.[LineOfBusinessId],S.[MaxDueDate],S.[PayDownId],S.[PayOffId],S.[PostDate],S.[PPTEscrowGLTemplateId],S.[ReceiptAmount],S.[ReceiptApplicationId],S.[ReceiptBatchId],S.[ReceiptClassification],S.[ReceiptGLTemplateId],S.[ReceiptHierarchyTemplateId],S.[ReceiptId],S.[ReceiptNumber],S.[ReceiptType],S.[ReceiptTypeId],S.[ReceivableTaxType],S.[ReceivedDate],S.[SecurityDepositGLTemplateId],S.[SecurityDepositLiabilityAmount],S.[SecurityDepositLiabilityContractAmount],S.[SourceOfError],S.[Status],S.[UnallocatedDescription])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

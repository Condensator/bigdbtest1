SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveACHReceipt]
(
 @val [dbo].[ACHReceipt] READONLY
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
MERGE [dbo].[ACHReceipts] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ACHEntryDetailId]=S.[ACHEntryDetailId],[BankAccountId]=S.[BankAccountId],[BranchId]=S.[BranchId],[CashTypeId]=S.[CashTypeId],[CheckNumber]=S.[CheckNumber],[ContractId]=S.[ContractId],[CostCenterId]=S.[CostCenterId],[Currency]=S.[Currency],[CurrencyId]=S.[CurrencyId],[CustomerId]=S.[CustomerId],[EntityType]=S.[EntityType],[ExtractReceiptId]=S.[ExtractReceiptId],[InActivateBankAccountId]=S.[InActivateBankAccountId],[InstrumentTypeId]=S.[InstrumentTypeId],[IsActive]=S.[IsActive],[IsOneTimeACH]=S.[IsOneTimeACH],[LegalEntityId]=S.[LegalEntityId],[LineOfBusinessId]=S.[LineOfBusinessId],[OneTimeACHId]=S.[OneTimeACHId],[ReceiptAmount]=S.[ReceiptAmount],[ReceiptApplicationId]=S.[ReceiptApplicationId],[ReceiptClassification]=S.[ReceiptClassification],[ReceiptGLTemplateId]=S.[ReceiptGLTemplateId],[ReceiptId]=S.[ReceiptId],[ReceiptType]=S.[ReceiptType],[ReceiptTypeId]=S.[ReceiptTypeId],[SettlementDate]=S.[SettlementDate],[Status]=S.[Status],[TraceNumber]=S.[TraceNumber],[UnallocatedAmount]=S.[UnallocatedAmount],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UpdateJobStepInstanceId]=S.[UpdateJobStepInstanceId]
WHEN NOT MATCHED THEN
	INSERT ([ACHEntryDetailId],[BankAccountId],[BranchId],[CashTypeId],[CheckNumber],[ContractId],[CostCenterId],[CreatedById],[CreatedTime],[Currency],[CurrencyId],[CustomerId],[EntityType],[ExtractReceiptId],[InActivateBankAccountId],[InstrumentTypeId],[IsActive],[IsOneTimeACH],[LegalEntityId],[LineOfBusinessId],[OneTimeACHId],[ReceiptAmount],[ReceiptApplicationId],[ReceiptClassification],[ReceiptGLTemplateId],[ReceiptId],[ReceiptType],[ReceiptTypeId],[SettlementDate],[Status],[TraceNumber],[UnallocatedAmount],[UpdateJobStepInstanceId])
    VALUES (S.[ACHEntryDetailId],S.[BankAccountId],S.[BranchId],S.[CashTypeId],S.[CheckNumber],S.[ContractId],S.[CostCenterId],S.[CreatedById],S.[CreatedTime],S.[Currency],S.[CurrencyId],S.[CustomerId],S.[EntityType],S.[ExtractReceiptId],S.[InActivateBankAccountId],S.[InstrumentTypeId],S.[IsActive],S.[IsOneTimeACH],S.[LegalEntityId],S.[LineOfBusinessId],S.[OneTimeACHId],S.[ReceiptAmount],S.[ReceiptApplicationId],S.[ReceiptClassification],S.[ReceiptGLTemplateId],S.[ReceiptId],S.[ReceiptType],S.[ReceiptTypeId],S.[SettlementDate],S.[Status],S.[TraceNumber],S.[UnallocatedAmount],S.[UpdateJobStepInstanceId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

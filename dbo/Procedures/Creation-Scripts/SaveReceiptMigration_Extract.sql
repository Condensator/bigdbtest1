SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceiptMigration_Extract]
(
 @val [dbo].[ReceiptMigration_Extract] READONLY
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
MERGE [dbo].[ReceiptMigration_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BankAccountBankName]=S.[BankAccountBankName],[BankAccountBranchName]=S.[BankAccountBranchName],[BankAccountNumber]=S.[BankAccountNumber],[BankName]=S.[BankName],[CashTypeName]=S.[CashTypeName],[CheckNumber]=S.[CheckNumber],[Comment]=S.[Comment],[ContractSequenceNumber]=S.[ContractSequenceNumber],[CurrencyCode]=S.[CurrencyCode],[ErrorMessage]=S.[ErrorMessage],[IsProcessed]=S.[IsProcessed],[IsPureUnallocatedCash]=S.[IsPureUnallocatedCash],[IsValid]=S.[IsValid],[JobStepInstanceId]=S.[JobStepInstanceId],[LegalEntityNumber]=S.[LegalEntityNumber],[PostDate]=S.[PostDate],[ReceiptAmount_Amount]=S.[ReceiptAmount_Amount],[ReceiptAmount_Currency]=S.[ReceiptAmount_Currency],[ReceiptGLTemplateName]=S.[ReceiptGLTemplateName],[ReceiptMigrationId]=S.[ReceiptMigrationId],[ReceiptTypeName]=S.[ReceiptTypeName],[ReceivedDate]=S.[ReceivedDate],[TotalAmountToApply_Amount]=S.[TotalAmountToApply_Amount],[TotalAmountToApply_Currency]=S.[TotalAmountToApply_Currency],[TotalTaxAmountToApply_Amount]=S.[TotalTaxAmountToApply_Amount],[TotalTaxAmountToApply_Currency]=S.[TotalTaxAmountToApply_Currency],[UniqueIdentifier]=S.[UniqueIdentifier],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BankAccountBankName],[BankAccountBranchName],[BankAccountNumber],[BankName],[CashTypeName],[CheckNumber],[Comment],[ContractSequenceNumber],[CreatedById],[CreatedTime],[CurrencyCode],[ErrorMessage],[IsProcessed],[IsPureUnallocatedCash],[IsValid],[JobStepInstanceId],[LegalEntityNumber],[PostDate],[ReceiptAmount_Amount],[ReceiptAmount_Currency],[ReceiptGLTemplateName],[ReceiptMigrationId],[ReceiptTypeName],[ReceivedDate],[TotalAmountToApply_Amount],[TotalAmountToApply_Currency],[TotalTaxAmountToApply_Amount],[TotalTaxAmountToApply_Currency],[UniqueIdentifier])
    VALUES (S.[BankAccountBankName],S.[BankAccountBranchName],S.[BankAccountNumber],S.[BankName],S.[CashTypeName],S.[CheckNumber],S.[Comment],S.[ContractSequenceNumber],S.[CreatedById],S.[CreatedTime],S.[CurrencyCode],S.[ErrorMessage],S.[IsProcessed],S.[IsPureUnallocatedCash],S.[IsValid],S.[JobStepInstanceId],S.[LegalEntityNumber],S.[PostDate],S.[ReceiptAmount_Amount],S.[ReceiptAmount_Currency],S.[ReceiptGLTemplateName],S.[ReceiptMigrationId],S.[ReceiptTypeName],S.[ReceivedDate],S.[TotalAmountToApply_Amount],S.[TotalAmountToApply_Currency],S.[TotalTaxAmountToApply_Amount],S.[TotalTaxAmountToApply_Currency],S.[UniqueIdentifier])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

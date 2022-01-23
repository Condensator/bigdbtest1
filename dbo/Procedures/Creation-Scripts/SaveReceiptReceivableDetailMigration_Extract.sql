SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceiptReceivableDetailMigration_Extract]
(
 @val [dbo].[ReceiptReceivableDetailMigration_Extract] READONLY
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
MERGE [dbo].[ReceiptReceivableDetailMigration_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AmountToApply_Amount]=S.[AmountToApply_Amount],[AmountToApply_Currency]=S.[AmountToApply_Currency],[DueDate]=S.[DueDate],[FunderPartyNumber]=S.[FunderPartyNumber],[JobStepInstanceId]=S.[JobStepInstanceId],[PaymentNumber]=S.[PaymentNumber],[PaymentType]=S.[PaymentType],[ReceiptMigrationId]=S.[ReceiptMigrationId],[ReceiptReceivableMigrationId]=S.[ReceiptReceivableMigrationId],[ReceivableType]=S.[ReceivableType],[TaxAmountToApply_Amount]=S.[TaxAmountToApply_Amount],[TaxAmountToApply_Currency]=S.[TaxAmountToApply_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AmountToApply_Amount],[AmountToApply_Currency],[CreatedById],[CreatedTime],[DueDate],[FunderPartyNumber],[JobStepInstanceId],[PaymentNumber],[PaymentType],[ReceiptMigrationId],[ReceiptReceivableMigrationId],[ReceivableType],[TaxAmountToApply_Amount],[TaxAmountToApply_Currency])
    VALUES (S.[AmountToApply_Amount],S.[AmountToApply_Currency],S.[CreatedById],S.[CreatedTime],S.[DueDate],S.[FunderPartyNumber],S.[JobStepInstanceId],S.[PaymentNumber],S.[PaymentType],S.[ReceiptMigrationId],S.[ReceiptReceivableMigrationId],S.[ReceivableType],S.[TaxAmountToApply_Amount],S.[TaxAmountToApply_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

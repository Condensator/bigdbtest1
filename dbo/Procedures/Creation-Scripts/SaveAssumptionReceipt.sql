SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAssumptionReceipt]
(
 @val [dbo].[AssumptionReceipt] READONLY
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
MERGE [dbo].[AssumptionReceipts] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BalanceWithOldCustomer_Amount]=S.[BalanceWithOldCustomer_Amount],[BalanceWithOldCustomer_Currency]=S.[BalanceWithOldCustomer_Currency],[CreditApplied_Amount]=S.[CreditApplied_Amount],[CreditApplied_Currency]=S.[CreditApplied_Currency],[IsActive]=S.[IsActive],[ReceiptAmount_Amount]=S.[ReceiptAmount_Amount],[ReceiptAmount_Currency]=S.[ReceiptAmount_Currency],[ReceiptBalance_Amount]=S.[ReceiptBalance_Amount],[ReceiptBalance_Currency]=S.[ReceiptBalance_Currency],[ReceiptId]=S.[ReceiptId],[TransferToNewCustomer_Amount]=S.[TransferToNewCustomer_Amount],[TransferToNewCustomer_Currency]=S.[TransferToNewCustomer_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssumptionId],[BalanceWithOldCustomer_Amount],[BalanceWithOldCustomer_Currency],[CreatedById],[CreatedTime],[CreditApplied_Amount],[CreditApplied_Currency],[IsActive],[ReceiptAmount_Amount],[ReceiptAmount_Currency],[ReceiptBalance_Amount],[ReceiptBalance_Currency],[ReceiptId],[TransferToNewCustomer_Amount],[TransferToNewCustomer_Currency])
    VALUES (S.[AssumptionId],S.[BalanceWithOldCustomer_Amount],S.[BalanceWithOldCustomer_Currency],S.[CreatedById],S.[CreatedTime],S.[CreditApplied_Amount],S.[CreditApplied_Currency],S.[IsActive],S.[ReceiptAmount_Amount],S.[ReceiptAmount_Currency],S.[ReceiptBalance_Amount],S.[ReceiptBalance_Currency],S.[ReceiptId],S.[TransferToNewCustomer_Amount],S.[TransferToNewCustomer_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

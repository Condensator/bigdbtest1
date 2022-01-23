SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveSecurityDepositApplication]
(
 @val [dbo].[SecurityDepositApplication] READONLY
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
MERGE [dbo].[SecurityDepositApplications] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssumedAmount_Amount]=S.[AssumedAmount_Amount],[AssumedAmount_Currency]=S.[AssumedAmount_Currency],[ContractId]=S.[ContractId],[EntityType]=S.[EntityType],[GlJournalId]=S.[GlJournalId],[IsActive]=S.[IsActive],[IsRefund]=S.[IsRefund],[PartyId]=S.[PartyId],[PayableCodeId]=S.[PayableCodeId],[PayableDate]=S.[PayableDate],[PayableRemitToId]=S.[PayableRemitToId],[PostDate]=S.[PostDate],[ReceiptId]=S.[ReceiptId],[TransferToIncome_Amount]=S.[TransferToIncome_Amount],[TransferToIncome_Currency]=S.[TransferToIncome_Currency],[TransferToReceipt_Amount]=S.[TransferToReceipt_Amount],[TransferToReceipt_Currency]=S.[TransferToReceipt_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[WithholdingTaxRate]=S.[WithholdingTaxRate]
WHEN NOT MATCHED THEN
	INSERT ([AssumedAmount_Amount],[AssumedAmount_Currency],[ContractId],[CreatedById],[CreatedTime],[EntityType],[GlJournalId],[IsActive],[IsRefund],[PartyId],[PayableCodeId],[PayableDate],[PayableRemitToId],[PostDate],[ReceiptId],[SecurityDepositId],[TransferToIncome_Amount],[TransferToIncome_Currency],[TransferToReceipt_Amount],[TransferToReceipt_Currency],[WithholdingTaxRate])
    VALUES (S.[AssumedAmount_Amount],S.[AssumedAmount_Currency],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[EntityType],S.[GlJournalId],S.[IsActive],S.[IsRefund],S.[PartyId],S.[PayableCodeId],S.[PayableDate],S.[PayableRemitToId],S.[PostDate],S.[ReceiptId],S.[SecurityDepositId],S.[TransferToIncome_Amount],S.[TransferToIncome_Currency],S.[TransferToReceipt_Amount],S.[TransferToReceipt_Currency],S.[WithholdingTaxRate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

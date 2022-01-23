SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveTreasuryPayable]
(
 @val [dbo].[TreasuryPayable] READONLY
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
MERGE [dbo].[TreasuryPayables] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[ApprovalComment]=S.[ApprovalComment],[Balance_Amount]=S.[Balance_Amount],[Balance_Currency]=S.[Balance_Currency],[Comment]=S.[Comment],[ContractSequenceNumber]=S.[ContractSequenceNumber],[CurrencyId]=S.[CurrencyId],[LegalEntityId]=S.[LegalEntityId],[MailingInstruction]=S.[MailingInstruction],[Memo]=S.[Memo],[PayableInvoiceNumber]=S.[PayableInvoiceNumber],[PayeeId]=S.[PayeeId],[PayFromAccountId]=S.[PayFromAccountId],[ReceiptType]=S.[ReceiptType],[RemitToId]=S.[RemitToId],[RequestedPaymentDate]=S.[RequestedPaymentDate],[Status]=S.[Status],[TransactionNumber]=S.[TransactionNumber],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[Urgency]=S.[Urgency]
WHEN NOT MATCHED THEN
	INSERT ([Amount_Amount],[Amount_Currency],[ApprovalComment],[Balance_Amount],[Balance_Currency],[Comment],[ContractSequenceNumber],[CreatedById],[CreatedTime],[CurrencyId],[LegalEntityId],[MailingInstruction],[Memo],[PayableInvoiceNumber],[PayeeId],[PayFromAccountId],[ReceiptType],[RemitToId],[RequestedPaymentDate],[Status],[TransactionNumber],[Urgency])
    VALUES (S.[Amount_Amount],S.[Amount_Currency],S.[ApprovalComment],S.[Balance_Amount],S.[Balance_Currency],S.[Comment],S.[ContractSequenceNumber],S.[CreatedById],S.[CreatedTime],S.[CurrencyId],S.[LegalEntityId],S.[MailingInstruction],S.[Memo],S.[PayableInvoiceNumber],S.[PayeeId],S.[PayFromAccountId],S.[ReceiptType],S.[RemitToId],S.[RequestedPaymentDate],S.[Status],S.[TransactionNumber],S.[Urgency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

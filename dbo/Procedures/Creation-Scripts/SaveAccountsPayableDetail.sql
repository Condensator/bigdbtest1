SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAccountsPayableDetail]
(
 @val [dbo].[AccountsPayableDetail] READONLY
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
MERGE [dbo].[AccountsPayableDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[ApprovalComment]=S.[ApprovalComment],[MailingInstruction]=S.[MailingInstruction],[Memo]=S.[Memo],[PayFromAccountId]=S.[PayFromAccountId],[ReceiptType]=S.[ReceiptType],[RemitToId]=S.[RemitToId],[RequestedPaymentDate]=S.[RequestedPaymentDate],[TreasuryPayableId]=S.[TreasuryPayableId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[Urgency]=S.[Urgency],[WithholdingTaxAmount_Amount]=S.[WithholdingTaxAmount_Amount],[WithholdingTaxAmount_Currency]=S.[WithholdingTaxAmount_Currency]
WHEN NOT MATCHED THEN
	INSERT ([AccountsPayableId],[Amount_Amount],[Amount_Currency],[ApprovalComment],[CreatedById],[CreatedTime],[MailingInstruction],[Memo],[PayFromAccountId],[ReceiptType],[RemitToId],[RequestedPaymentDate],[TreasuryPayableId],[Urgency],[WithholdingTaxAmount_Amount],[WithholdingTaxAmount_Currency])
    VALUES (S.[AccountsPayableId],S.[Amount_Amount],S.[Amount_Currency],S.[ApprovalComment],S.[CreatedById],S.[CreatedTime],S.[MailingInstruction],S.[Memo],S.[PayFromAccountId],S.[ReceiptType],S.[RemitToId],S.[RequestedPaymentDate],S.[TreasuryPayableId],S.[Urgency],S.[WithholdingTaxAmount_Amount],S.[WithholdingTaxAmount_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

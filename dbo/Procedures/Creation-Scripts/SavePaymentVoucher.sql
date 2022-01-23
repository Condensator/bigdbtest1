SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePaymentVoucher]
(
 @val [dbo].[PaymentVoucher] READONLY
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
MERGE [dbo].[PaymentVouchers] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[AmountInContractCurrency_Amount]=S.[AmountInContractCurrency_Amount],[AmountInContractCurrency_Currency]=S.[AmountInContractCurrency_Currency],[AssessmentDate]=S.[AssessmentDate],[BatchId]=S.[BatchId],[CheckDate]=S.[CheckDate],[CheckNumber]=S.[CheckNumber],[FederalReferenceNumber]=S.[FederalReferenceNumber],[IsIntercompany]=S.[IsIntercompany],[IsManual]=S.[IsManual],[LegalEntityId]=S.[LegalEntityId],[MailingInstruction]=S.[MailingInstruction],[Memo]=S.[Memo],[OFACReviewRequired]=S.[OFACReviewRequired],[OriginalVoucherId]=S.[OriginalVoucherId],[OverNightRequired]=S.[OverNightRequired],[PayFromAccountId]=S.[PayFromAccountId],[PaymentDate]=S.[PaymentDate],[PaymentVoucherInfoId]=S.[PaymentVoucherInfoId],[PostDate]=S.[PostDate],[ReceiptId]=S.[ReceiptId],[ReceiptType]=S.[ReceiptType],[RemitToId]=S.[RemitToId],[Status]=S.[Status],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[Urgency]=S.[Urgency],[VoucherNumber]=S.[VoucherNumber],[WireDate]=S.[WireDate],[WithholdingTaxAmount_Amount]=S.[WithholdingTaxAmount_Amount],[WithholdingTaxAmount_Currency]=S.[WithholdingTaxAmount_Currency]
WHEN NOT MATCHED THEN
	INSERT ([Amount_Amount],[Amount_Currency],[AmountInContractCurrency_Amount],[AmountInContractCurrency_Currency],[AssessmentDate],[BatchId],[CheckDate],[CheckNumber],[CreatedById],[CreatedTime],[FederalReferenceNumber],[IsIntercompany],[IsManual],[LegalEntityId],[MailingInstruction],[Memo],[OFACReviewRequired],[OriginalVoucherId],[OverNightRequired],[PayFromAccountId],[PaymentDate],[PaymentVoucherInfoId],[PostDate],[ReceiptId],[ReceiptType],[RemitToId],[Status],[Urgency],[VoucherNumber],[WireDate],[WithholdingTaxAmount_Amount],[WithholdingTaxAmount_Currency])
    VALUES (S.[Amount_Amount],S.[Amount_Currency],S.[AmountInContractCurrency_Amount],S.[AmountInContractCurrency_Currency],S.[AssessmentDate],S.[BatchId],S.[CheckDate],S.[CheckNumber],S.[CreatedById],S.[CreatedTime],S.[FederalReferenceNumber],S.[IsIntercompany],S.[IsManual],S.[LegalEntityId],S.[MailingInstruction],S.[Memo],S.[OFACReviewRequired],S.[OriginalVoucherId],S.[OverNightRequired],S.[PayFromAccountId],S.[PaymentDate],S.[PaymentVoucherInfoId],S.[PostDate],S.[ReceiptId],S.[ReceiptType],S.[RemitToId],S.[Status],S.[Urgency],S.[VoucherNumber],S.[WireDate],S.[WithholdingTaxAmount_Amount],S.[WithholdingTaxAmount_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

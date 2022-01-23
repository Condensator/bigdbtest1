SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDisbursementRequestPaymentDetail]
(
 @val [dbo].[DisbursementRequestPaymentDetail] READONLY
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
MERGE [dbo].[DisbursementRequestPaymentDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Comment]=S.[Comment],[ContactId]=S.[ContactId],[IsActive]=S.[IsActive],[MailingInstruction]=S.[MailingInstruction],[Memo]=S.[Memo],[PayeeId]=S.[PayeeId],[PayFromAccountId]=S.[PayFromAccountId],[RemittanceType]=S.[RemittanceType],[RemitToId]=S.[RemitToId],[RequestedPaymentDate]=S.[RequestedPaymentDate],[TotalAmountToPay_Amount]=S.[TotalAmountToPay_Amount],[TotalAmountToPay_Currency]=S.[TotalAmountToPay_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[Urgency]=S.[Urgency]
WHEN NOT MATCHED THEN
	INSERT ([Comment],[ContactId],[CreatedById],[CreatedTime],[DisbursementRequestId],[IsActive],[MailingInstruction],[Memo],[PayeeId],[PayFromAccountId],[RemittanceType],[RemitToId],[RequestedPaymentDate],[TotalAmountToPay_Amount],[TotalAmountToPay_Currency],[Urgency])
    VALUES (S.[Comment],S.[ContactId],S.[CreatedById],S.[CreatedTime],S.[DisbursementRequestId],S.[IsActive],S.[MailingInstruction],S.[Memo],S.[PayeeId],S.[PayFromAccountId],S.[RemittanceType],S.[RemitToId],S.[RequestedPaymentDate],S.[TotalAmountToPay_Amount],S.[TotalAmountToPay_Currency],S.[Urgency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

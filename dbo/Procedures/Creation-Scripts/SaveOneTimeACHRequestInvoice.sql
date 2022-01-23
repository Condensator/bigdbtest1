SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveOneTimeACHRequestInvoice]
(
 @val [dbo].[OneTimeACHRequestInvoice] READONLY
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
MERGE [dbo].[OneTimeACHRequestInvoices] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AmountToPay_Amount]=S.[AmountToPay_Amount],[AmountToPay_Currency]=S.[AmountToPay_Currency],[IsActive]=S.[IsActive],[IsStatementInvoice]=S.[IsStatementInvoice],[OneTimeACHId]=S.[OneTimeACHId],[PaymentDate]=S.[PaymentDate],[ReceivableInvoiceId]=S.[ReceivableInvoiceId],[Status]=S.[Status],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AmountToPay_Amount],[AmountToPay_Currency],[CreatedById],[CreatedTime],[IsActive],[IsStatementInvoice],[OneTimeACHId],[OneTimeACHRequestId],[PaymentDate],[ReceivableInvoiceId],[Status])
    VALUES (S.[AmountToPay_Amount],S.[AmountToPay_Currency],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[IsStatementInvoice],S.[OneTimeACHId],S.[OneTimeACHRequestId],S.[PaymentDate],S.[ReceivableInvoiceId],S.[Status])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

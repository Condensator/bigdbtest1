SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveOneTimeACHInvoice]
(
 @val [dbo].[OneTimeACHInvoice] READONLY
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
MERGE [dbo].[OneTimeACHInvoices] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AmountApplied_Amount]=S.[AmountApplied_Amount],[AmountApplied_Currency]=S.[AmountApplied_Currency],[IsActive]=S.[IsActive],[IsStatementInvoice]=S.[IsStatementInvoice],[ReceivableInvoiceId]=S.[ReceivableInvoiceId],[Status]=S.[Status],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AmountApplied_Amount],[AmountApplied_Currency],[CreatedById],[CreatedTime],[IsActive],[IsStatementInvoice],[OneTimeACHId],[ReceivableInvoiceId],[Status])
    VALUES (S.[AmountApplied_Amount],S.[AmountApplied_Currency],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[IsStatementInvoice],S.[OneTimeACHId],S.[ReceivableInvoiceId],S.[Status])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDSLReceiptHistory]
(
 @val [dbo].[DSLReceiptHistory] READONLY
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
MERGE [dbo].[DSLReceiptHistories] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AmountPosted_Amount]=S.[AmountPosted_Amount],[AmountPosted_Currency]=S.[AmountPosted_Currency],[InvoiceId]=S.[InvoiceId],[IsActive]=S.[IsActive],[ReceivableDetailId]=S.[ReceivableDetailId],[ReceivedDate]=S.[ReceivedDate],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AmountPosted_Amount],[AmountPosted_Currency],[CreatedById],[CreatedTime],[InvoiceId],[IsActive],[ReceiptId],[ReceivableDetailId],[ReceivedDate])
    VALUES (S.[AmountPosted_Amount],S.[AmountPosted_Currency],S.[CreatedById],S.[CreatedTime],S.[InvoiceId],S.[IsActive],S.[ReceiptId],S.[ReceivableDetailId],S.[ReceivedDate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceiptBatch]
(
 @val [dbo].[ReceiptBatch] READONLY
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
MERGE [dbo].[ReceiptBatches] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Comment]=S.[Comment],[CurrencyId]=S.[CurrencyId],[DepositAmount_Amount]=S.[DepositAmount_Amount],[DepositAmount_Currency]=S.[DepositAmount_Currency],[IsPartiallyPosted]=S.[IsPartiallyPosted],[LegalEntityId]=S.[LegalEntityId],[Name]=S.[Name],[PostDate]=S.[PostDate],[ReceiptAmountAlreadyPosted_Amount]=S.[ReceiptAmountAlreadyPosted_Amount],[ReceiptAmountAlreadyPosted_Currency]=S.[ReceiptAmountAlreadyPosted_Currency],[ReceiptBatchGLTemplateId]=S.[ReceiptBatchGLTemplateId],[ReceivedDate]=S.[ReceivedDate],[Status]=S.[Status],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Comment],[CreatedById],[CreatedTime],[CurrencyId],[DepositAmount_Amount],[DepositAmount_Currency],[IsPartiallyPosted],[LegalEntityId],[Name],[PostDate],[ReceiptAmountAlreadyPosted_Amount],[ReceiptAmountAlreadyPosted_Currency],[ReceiptBatchGLTemplateId],[ReceivedDate],[Status])
    VALUES (S.[Comment],S.[CreatedById],S.[CreatedTime],S.[CurrencyId],S.[DepositAmount_Amount],S.[DepositAmount_Currency],S.[IsPartiallyPosted],S.[LegalEntityId],S.[Name],S.[PostDate],S.[ReceiptAmountAlreadyPosted_Amount],S.[ReceiptAmountAlreadyPosted_Currency],S.[ReceiptBatchGLTemplateId],S.[ReceivedDate],S.[Status])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

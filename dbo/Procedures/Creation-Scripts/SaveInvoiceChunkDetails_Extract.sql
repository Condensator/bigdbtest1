SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveInvoiceChunkDetails_Extract]
(
 @val [dbo].[InvoiceChunkDetails_Extract] READONLY
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
MERGE [dbo].[InvoiceChunkDetails_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BillToId]=S.[BillToId],[ChunkNumber]=S.[ChunkNumber],[GenerateStatementInvoice]=S.[GenerateStatementInvoice],[JobStepInstanceId]=S.[JobStepInstanceId],[ReceivableDetailsCount]=S.[ReceivableDetailsCount],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BillToId],[ChunkNumber],[CreatedById],[CreatedTime],[GenerateStatementInvoice],[JobStepInstanceId],[ReceivableDetailsCount])
    VALUES (S.[BillToId],S.[ChunkNumber],S.[CreatedById],S.[CreatedTime],S.[GenerateStatementInvoice],S.[JobStepInstanceId],S.[ReceivableDetailsCount])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

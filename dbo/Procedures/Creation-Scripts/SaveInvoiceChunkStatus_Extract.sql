SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveInvoiceChunkStatus_Extract]
(
 @val [dbo].[InvoiceChunkStatus_Extract] READONLY
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
MERGE [dbo].[InvoiceChunkStatus_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ChunkNumber]=S.[ChunkNumber],[InvoicingStatus]=S.[InvoicingStatus],[IsExtractionProcessed]=S.[IsExtractionProcessed],[IsFileGenerated]=S.[IsFileGenerated],[IsReceivableInvoiceProcessed]=S.[IsReceivableInvoiceProcessed],[IsStatementInvoiceProcessed]=S.[IsStatementInvoiceProcessed],[RunJobStepInstanceId]=S.[RunJobStepInstanceId],[TaskChunkServiceInstanceId]=S.[TaskChunkServiceInstanceId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ChunkNumber],[CreatedById],[CreatedTime],[InvoicingStatus],[IsExtractionProcessed],[IsFileGenerated],[IsReceivableInvoiceProcessed],[IsStatementInvoiceProcessed],[RunJobStepInstanceId],[TaskChunkServiceInstanceId])
    VALUES (S.[ChunkNumber],S.[CreatedById],S.[CreatedTime],S.[InvoicingStatus],S.[IsExtractionProcessed],S.[IsFileGenerated],S.[IsReceivableInvoiceProcessed],S.[IsStatementInvoiceProcessed],S.[RunJobStepInstanceId],S.[TaskChunkServiceInstanceId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

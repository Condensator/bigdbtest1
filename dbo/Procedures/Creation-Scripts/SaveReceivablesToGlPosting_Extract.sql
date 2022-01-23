SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceivablesToGlPosting_Extract]
(
 @val [dbo].[ReceivablesToGlPosting_Extract] READONLY
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
MERGE [dbo].[ReceivablesToGlPosting_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [InvoiceRunDate]=S.[InvoiceRunDate],[IsGLProcessed]=S.[IsGLProcessed],[IsReceivableGLPosted]=S.[IsReceivableGLPosted],[IsTaxGLPosted]=S.[IsTaxGLPosted],[JobStepInstanceId]=S.[JobStepInstanceId],[ReceivableId]=S.[ReceivableId],[ReceivableTaxId]=S.[ReceivableTaxId],[ReceivableTaxType]=S.[ReceivableTaxType],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[InvoiceRunDate],[IsGLProcessed],[IsReceivableGLPosted],[IsTaxGLPosted],[JobStepInstanceId],[ReceivableId],[ReceivableTaxId],[ReceivableTaxType])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[InvoiceRunDate],S.[IsGLProcessed],S.[IsReceivableGLPosted],S.[IsTaxGLPosted],S.[JobStepInstanceId],S.[ReceivableId],S.[ReceivableTaxId],S.[ReceivableTaxType])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

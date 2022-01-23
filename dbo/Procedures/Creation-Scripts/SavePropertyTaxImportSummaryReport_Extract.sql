SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePropertyTaxImportSummaryReport_Extract]
(
 @val [dbo].[PropertyTaxImportSummaryReport_Extract] READONLY
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
MERGE [dbo].[PropertyTaxImportSummaryReport_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Currency]=S.[Currency],[FileName]=S.[FileName],[JobId]=S.[JobId],[JobStepInstanceId]=S.[JobStepInstanceId],[RecordsErroredOut]=S.[RecordsErroredOut],[RecordsSuccessfullyUploaded]=S.[RecordsSuccessfullyUploaded],[TotalTaxAmountErroredOut]=S.[TotalTaxAmountErroredOut],[TotalTaxAmountUploaded]=S.[TotalTaxAmountUploaded],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UploadedDate]=S.[UploadedDate]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[Currency],[FileName],[JobId],[JobStepInstanceId],[RecordsErroredOut],[RecordsSuccessfullyUploaded],[TotalTaxAmountErroredOut],[TotalTaxAmountUploaded],[UploadedDate])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[Currency],S.[FileName],S.[JobId],S.[JobStepInstanceId],S.[RecordsErroredOut],S.[RecordsSuccessfullyUploaded],S.[TotalTaxAmountErroredOut],S.[TotalTaxAmountUploaded],S.[UploadedDate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

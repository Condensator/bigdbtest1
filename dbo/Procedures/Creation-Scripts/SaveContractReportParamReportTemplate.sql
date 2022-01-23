SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveContractReportParamReportTemplate]
(
 @val [dbo].[ContractReportParamReportTemplate] READONLY
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
MERGE [dbo].[ContractReportParamReportTemplates] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [CommencementDate]=S.[CommencementDate],[CommencementRunDate]=S.[CommencementRunDate],[CommencementUpThrough]=S.[CommencementUpThrough],[ContractFilterOption]=S.[ContractFilterOption],[CustomerId]=S.[CustomerId],[DaysFromRunDate]=S.[DaysFromRunDate],[FromCommencement]=S.[FromCommencement],[FromDate]=S.[FromDate],[FromSequenceNumberId]=S.[FromSequenceNumberId],[MaturityDate]=S.[MaturityDate],[SortBy]=S.[SortBy],[Status]=S.[Status],[ToCommencement]=S.[ToCommencement],[ToDate]=S.[ToDate],[ToSequenceNumberId]=S.[ToSequenceNumberId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UpThroughDate]=S.[UpThroughDate]
WHEN NOT MATCHED THEN
	INSERT ([CommencementDate],[CommencementRunDate],[CommencementUpThrough],[ContractFilterOption],[CreatedById],[CreatedTime],[CustomerId],[DaysFromRunDate],[FromCommencement],[FromDate],[FromSequenceNumberId],[Id],[MaturityDate],[SortBy],[Status],[ToCommencement],[ToDate],[ToSequenceNumberId],[UpThroughDate])
    VALUES (S.[CommencementDate],S.[CommencementRunDate],S.[CommencementUpThrough],S.[ContractFilterOption],S.[CreatedById],S.[CreatedTime],S.[CustomerId],S.[DaysFromRunDate],S.[FromCommencement],S.[FromDate],S.[FromSequenceNumberId],S.[Id],S.[MaturityDate],S.[SortBy],S.[Status],S.[ToCommencement],S.[ToDate],S.[ToSequenceNumberId],S.[UpThroughDate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

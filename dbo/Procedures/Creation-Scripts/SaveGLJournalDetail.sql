SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveGLJournalDetail]
(
 @val [dbo].[GLJournalDetail] READONLY
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
MERGE [dbo].[GLJournalDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[Description]=S.[Description],[EntityId]=S.[EntityId],[EntityType]=S.[EntityType],[ExportJobId]=S.[ExportJobId],[GLAccountId]=S.[GLAccountId],[GLAccountNumber]=S.[GLAccountNumber],[GLTemplateDetailId]=S.[GLTemplateDetailId],[InstrumentTypeGLAccountId]=S.[InstrumentTypeGLAccountId],[IsActive]=S.[IsActive],[IsDebit]=S.[IsDebit],[LineofBusinessId]=S.[LineofBusinessId],[MatchingGLTemplateDetailId]=S.[MatchingGLTemplateDetailId],[SourceId]=S.[SourceId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Amount_Amount],[Amount_Currency],[CreatedById],[CreatedTime],[Description],[EntityId],[EntityType],[ExportJobId],[GLAccountId],[GLAccountNumber],[GLJournalId],[GLTemplateDetailId],[InstrumentTypeGLAccountId],[IsActive],[IsDebit],[LineofBusinessId],[MatchingGLTemplateDetailId],[SourceId])
    VALUES (S.[Amount_Amount],S.[Amount_Currency],S.[CreatedById],S.[CreatedTime],S.[Description],S.[EntityId],S.[EntityType],S.[ExportJobId],S.[GLAccountId],S.[GLAccountNumber],S.[GLJournalId],S.[GLTemplateDetailId],S.[InstrumentTypeGLAccountId],S.[IsActive],S.[IsDebit],S.[LineofBusinessId],S.[MatchingGLTemplateDetailId],S.[SourceId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

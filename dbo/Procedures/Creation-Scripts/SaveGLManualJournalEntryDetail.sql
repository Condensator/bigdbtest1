SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveGLManualJournalEntryDetail]
(
 @val [dbo].[GLManualJournalEntryDetail] READONLY
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
MERGE [dbo].[GLManualJournalEntryDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[Description]=S.[Description],[GLAccountId]=S.[GLAccountId],[GLAccountNumber]=S.[GLAccountNumber],[GLJournalDetailId]=S.[GLJournalDetailId],[IsActive]=S.[IsActive],[IsDebit]=S.[IsDebit],[ReversalGLJournalDetailId]=S.[ReversalGLJournalDetailId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Amount_Amount],[Amount_Currency],[CreatedById],[CreatedTime],[Description],[GLAccountId],[GLAccountNumber],[GLJournalDetailId],[GLManualJournalEntryId],[IsActive],[IsDebit],[ReversalGLJournalDetailId])
    VALUES (S.[Amount_Amount],S.[Amount_Currency],S.[CreatedById],S.[CreatedTime],S.[Description],S.[GLAccountId],S.[GLAccountNumber],S.[GLJournalDetailId],S.[GLManualJournalEntryId],S.[IsActive],S.[IsDebit],S.[ReversalGLJournalDetailId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

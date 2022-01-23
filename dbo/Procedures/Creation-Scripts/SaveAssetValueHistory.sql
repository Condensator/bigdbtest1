SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAssetValueHistory]
(
 @val [dbo].[AssetValueHistory] READONLY
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
MERGE [dbo].[AssetValueHistories] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AdjustmentEntry]=S.[AdjustmentEntry],[AssetId]=S.[AssetId],[BeginBookValue_Amount]=S.[BeginBookValue_Amount],[BeginBookValue_Currency]=S.[BeginBookValue_Currency],[Cost_Amount]=S.[Cost_Amount],[Cost_Currency]=S.[Cost_Currency],[EndBookValue_Amount]=S.[EndBookValue_Amount],[EndBookValue_Currency]=S.[EndBookValue_Currency],[FromDate]=S.[FromDate],[GLJournalId]=S.[GLJournalId],[IncomeDate]=S.[IncomeDate],[IsAccounted]=S.[IsAccounted],[IsCleared]=S.[IsCleared],[IsLeaseComponent]=S.[IsLeaseComponent],[IsLessorOwned]=S.[IsLessorOwned],[IsSchedule]=S.[IsSchedule],[NetValue_Amount]=S.[NetValue_Amount],[NetValue_Currency]=S.[NetValue_Currency],[PostDate]=S.[PostDate],[ReversalGLJournalId]=S.[ReversalGLJournalId],[ReversalPostDate]=S.[ReversalPostDate],[SourceModule]=S.[SourceModule],[SourceModuleId]=S.[SourceModuleId],[ToDate]=S.[ToDate],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[Value_Amount]=S.[Value_Amount],[Value_Currency]=S.[Value_Currency]
WHEN NOT MATCHED THEN
	INSERT ([AdjustmentEntry],[AssetId],[BeginBookValue_Amount],[BeginBookValue_Currency],[Cost_Amount],[Cost_Currency],[CreatedById],[CreatedTime],[EndBookValue_Amount],[EndBookValue_Currency],[FromDate],[GLJournalId],[IncomeDate],[IsAccounted],[IsCleared],[IsLeaseComponent],[IsLessorOwned],[IsSchedule],[NetValue_Amount],[NetValue_Currency],[PostDate],[ReversalGLJournalId],[ReversalPostDate],[SourceModule],[SourceModuleId],[ToDate],[Value_Amount],[Value_Currency])
    VALUES (S.[AdjustmentEntry],S.[AssetId],S.[BeginBookValue_Amount],S.[BeginBookValue_Currency],S.[Cost_Amount],S.[Cost_Currency],S.[CreatedById],S.[CreatedTime],S.[EndBookValue_Amount],S.[EndBookValue_Currency],S.[FromDate],S.[GLJournalId],S.[IncomeDate],S.[IsAccounted],S.[IsCleared],S.[IsLeaseComponent],S.[IsLessorOwned],S.[IsSchedule],S.[NetValue_Amount],S.[NetValue_Currency],S.[PostDate],S.[ReversalGLJournalId],S.[ReversalPostDate],S.[SourceModule],S.[SourceModuleId],S.[ToDate],S.[Value_Amount],S.[Value_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

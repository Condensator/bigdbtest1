SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAssetsValueStatusChangeDetail]
(
 @val [dbo].[AssetsValueStatusChangeDetail] READONLY
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
MERGE [dbo].[AssetsValueStatusChangeDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AdjustmentAmount_Amount]=S.[AdjustmentAmount_Amount],[AdjustmentAmount_Currency]=S.[AdjustmentAmount_Currency],[AssetId]=S.[AssetId],[BookDepreciationTemplateId]=S.[BookDepreciationTemplateId],[BranchId]=S.[BranchId],[CostCenterId]=S.[CostCenterId],[GLJournalId]=S.[GLJournalId],[GLTemplateId]=S.[GLTemplateId],[InstrumentTypeId]=S.[InstrumentTypeId],[LineofBusinessId]=S.[LineofBusinessId],[NewStatus]=S.[NewStatus],[ReversalGLJournalId]=S.[ReversalGLJournalId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AdjustmentAmount_Amount],[AdjustmentAmount_Currency],[AssetId],[AssetsValueStatusChangeId],[BookDepreciationTemplateId],[BranchId],[CostCenterId],[CreatedById],[CreatedTime],[GLJournalId],[GLTemplateId],[InstrumentTypeId],[LineofBusinessId],[NewStatus],[ReversalGLJournalId])
    VALUES (S.[AdjustmentAmount_Amount],S.[AdjustmentAmount_Currency],S.[AssetId],S.[AssetsValueStatusChangeId],S.[BookDepreciationTemplateId],S.[BranchId],S.[CostCenterId],S.[CreatedById],S.[CreatedTime],S.[GLJournalId],S.[GLTemplateId],S.[InstrumentTypeId],S.[LineofBusinessId],S.[NewStatus],S.[ReversalGLJournalId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

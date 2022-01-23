SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePayoffBlendedItem]
(
 @val [dbo].[PayoffBlendedItem] READONLY
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
MERGE [dbo].[PayoffBlendedItems] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccumulatedAdjustment_Amount]=S.[AccumulatedAdjustment_Amount],[AccumulatedAdjustment_Currency]=S.[AccumulatedAdjustment_Currency],[BilledAmount_Amount]=S.[BilledAmount_Amount],[BilledAmount_Currency]=S.[BilledAmount_Currency],[BlendedItemId]=S.[BlendedItemId],[Earned_Amount]=S.[Earned_Amount],[Earned_Currency]=S.[Earned_Currency],[GLJournalId]=S.[GLJournalId],[InactivatedInLease]=S.[InactivatedInLease],[IsActive]=S.[IsActive],[OriginalEndDate]=S.[OriginalEndDate],[PayoffAdjustment_Amount]=S.[PayoffAdjustment_Amount],[PayoffAdjustment_Currency]=S.[PayoffAdjustment_Currency],[UnbilledAmount_Amount]=S.[UnbilledAmount_Amount],[UnbilledAmount_Currency]=S.[UnbilledAmount_Currency],[Unearned_Amount]=S.[Unearned_Amount],[Unearned_Currency]=S.[Unearned_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AccumulatedAdjustment_Amount],[AccumulatedAdjustment_Currency],[BilledAmount_Amount],[BilledAmount_Currency],[BlendedItemId],[CreatedById],[CreatedTime],[Earned_Amount],[Earned_Currency],[GLJournalId],[InactivatedInLease],[IsActive],[OriginalEndDate],[PayoffAdjustment_Amount],[PayoffAdjustment_Currency],[PayoffId],[UnbilledAmount_Amount],[UnbilledAmount_Currency],[Unearned_Amount],[Unearned_Currency])
    VALUES (S.[AccumulatedAdjustment_Amount],S.[AccumulatedAdjustment_Currency],S.[BilledAmount_Amount],S.[BilledAmount_Currency],S.[BlendedItemId],S.[CreatedById],S.[CreatedTime],S.[Earned_Amount],S.[Earned_Currency],S.[GLJournalId],S.[InactivatedInLease],S.[IsActive],S.[OriginalEndDate],S.[PayoffAdjustment_Amount],S.[PayoffAdjustment_Currency],S.[PayoffId],S.[UnbilledAmount_Amount],S.[UnbilledAmount_Currency],S.[Unearned_Amount],S.[Unearned_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

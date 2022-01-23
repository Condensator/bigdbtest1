SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLoanPaydownBlendedItem]
(
 @val [dbo].[LoanPaydownBlendedItem] READONLY
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
MERGE [dbo].[LoanPaydownBlendedItems] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccumulatedAdjustment_Amount]=S.[AccumulatedAdjustment_Amount],[AccumulatedAdjustment_Currency]=S.[AccumulatedAdjustment_Currency],[AmountToBeBilled_Amount]=S.[AmountToBeBilled_Amount],[AmountToBeBilled_Currency]=S.[AmountToBeBilled_Currency],[Balance_Amount]=S.[Balance_Amount],[Balance_Currency]=S.[Balance_Currency],[BilledAmount_Amount]=S.[BilledAmount_Amount],[BilledAmount_Currency]=S.[BilledAmount_Currency],[BlendedItemId]=S.[BlendedItemId],[EarnedAmount_Amount]=S.[EarnedAmount_Amount],[EarnedAmount_Currency]=S.[EarnedAmount_Currency],[EffectiveInterest_Amount]=S.[EffectiveInterest_Amount],[EffectiveInterest_Currency]=S.[EffectiveInterest_Currency],[IsActive]=S.[IsActive],[OriginalBlendedItemEndDate]=S.[OriginalBlendedItemEndDate],[PaydownCostAdjustment_Amount]=S.[PaydownCostAdjustment_Amount],[PaydownCostAdjustment_Currency]=S.[PaydownCostAdjustment_Currency],[UnearnedAmount_Amount]=S.[UnearnedAmount_Amount],[UnearnedAmount_Currency]=S.[UnearnedAmount_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AccumulatedAdjustment_Amount],[AccumulatedAdjustment_Currency],[AmountToBeBilled_Amount],[AmountToBeBilled_Currency],[Balance_Amount],[Balance_Currency],[BilledAmount_Amount],[BilledAmount_Currency],[BlendedItemId],[CreatedById],[CreatedTime],[EarnedAmount_Amount],[EarnedAmount_Currency],[EffectiveInterest_Amount],[EffectiveInterest_Currency],[IsActive],[LoanPaydownId],[OriginalBlendedItemEndDate],[PaydownCostAdjustment_Amount],[PaydownCostAdjustment_Currency],[UnearnedAmount_Amount],[UnearnedAmount_Currency])
    VALUES (S.[AccumulatedAdjustment_Amount],S.[AccumulatedAdjustment_Currency],S.[AmountToBeBilled_Amount],S.[AmountToBeBilled_Currency],S.[Balance_Amount],S.[Balance_Currency],S.[BilledAmount_Amount],S.[BilledAmount_Currency],S.[BlendedItemId],S.[CreatedById],S.[CreatedTime],S.[EarnedAmount_Amount],S.[EarnedAmount_Currency],S.[EffectiveInterest_Amount],S.[EffectiveInterest_Currency],S.[IsActive],S.[LoanPaydownId],S.[OriginalBlendedItemEndDate],S.[PaydownCostAdjustment_Amount],S.[PaydownCostAdjustment_Currency],S.[UnearnedAmount_Amount],S.[UnearnedAmount_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

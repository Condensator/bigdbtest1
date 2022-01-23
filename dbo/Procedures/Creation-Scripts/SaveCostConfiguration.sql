SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCostConfiguration]
(
 @val [dbo].[CostConfiguration] READONLY
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
MERGE [dbo].[CostConfigurations] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AdjustmentAmount_Amount]=S.[AdjustmentAmount_Amount],[AdjustmentAmount_Currency]=S.[AdjustmentAmount_Currency],[AdjustmentFactor]=S.[AdjustmentFactor],[BreakdownAmount_Amount]=S.[BreakdownAmount_Amount],[BreakdownAmount_Currency]=S.[BreakdownAmount_Currency],[CostTypeId]=S.[CostTypeId],[IsActive]=S.[IsActive],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AdjustmentAmount_Amount],[AdjustmentAmount_Currency],[AdjustmentFactor],[BreakdownAmount_Amount],[BreakdownAmount_Currency],[CostTypeId],[CreatedById],[CreatedTime],[CreditDecisionId],[IsActive])
    VALUES (S.[AdjustmentAmount_Amount],S.[AdjustmentAmount_Currency],S.[AdjustmentFactor],S.[BreakdownAmount_Amount],S.[BreakdownAmount_Currency],S.[CostTypeId],S.[CreatedById],S.[CreatedTime],S.[CreditDecisionId],S.[IsActive])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

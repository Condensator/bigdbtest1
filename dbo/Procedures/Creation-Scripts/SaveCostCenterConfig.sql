SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCostCenterConfig]
(
 @val [dbo].[CostCenterConfig] READONLY
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
MERGE [dbo].[CostCenterConfigs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [CostCenter]=S.[CostCenter],[Description]=S.[Description],[IsActive]=S.[IsActive],[PortfolioId]=S.[PortfolioId],[RelatedToLessor]=S.[RelatedToLessor],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UsageCondition]=S.[UsageCondition]
WHEN NOT MATCHED THEN
	INSERT ([CostCenter],[CreatedById],[CreatedTime],[Description],[IsActive],[PortfolioId],[RelatedToLessor],[UsageCondition])
    VALUES (S.[CostCenter],S.[CreatedById],S.[CreatedTime],S.[Description],S.[IsActive],S.[PortfolioId],S.[RelatedToLessor],S.[UsageCondition])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveBookDepreciationEnMasseSetupDetail]
(
 @val [dbo].[BookDepreciationEnMasseSetupDetail] READONLY
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
MERGE [dbo].[BookDepreciationEnMasseSetupDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetId]=S.[AssetId],[BeginDate]=S.[BeginDate],[BookDepreciationTemplateId]=S.[BookDepreciationTemplateId],[CostBasis_Amount]=S.[CostBasis_Amount],[CostBasis_Currency]=S.[CostBasis_Currency],[EndDate]=S.[EndDate],[IsActive]=S.[IsActive],[RemainingLifeInMonths]=S.[RemainingLifeInMonths],[Salvage_Amount]=S.[Salvage_Amount],[Salvage_Currency]=S.[Salvage_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssetId],[BeginDate],[BookDepreciationEnMasseSetupId],[BookDepreciationTemplateId],[CostBasis_Amount],[CostBasis_Currency],[CreatedById],[CreatedTime],[EndDate],[IsActive],[RemainingLifeInMonths],[Salvage_Amount],[Salvage_Currency])
    VALUES (S.[AssetId],S.[BeginDate],S.[BookDepreciationEnMasseSetupId],S.[BookDepreciationTemplateId],S.[CostBasis_Amount],S.[CostBasis_Currency],S.[CreatedById],S.[CreatedTime],S.[EndDate],S.[IsActive],S.[RemainingLifeInMonths],S.[Salvage_Amount],S.[Salvage_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

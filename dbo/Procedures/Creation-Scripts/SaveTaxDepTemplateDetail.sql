SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveTaxDepTemplateDetail]
(
 @val [dbo].[TaxDepTemplateDetail] READONLY
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
MERGE [dbo].[TaxDepTemplateDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BonusDepreciationPercent]=S.[BonusDepreciationPercent],[DepreciationCostBasisPercent]=S.[DepreciationCostBasisPercent],[IsActive]=S.[IsActive],[TaxBook]=S.[TaxBook],[TaxDepRateId]=S.[TaxDepRateId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BonusDepreciationPercent],[CreatedById],[CreatedTime],[DepreciationCostBasisPercent],[IsActive],[TaxBook],[TaxDepRateId],[TaxDepTemplateId])
    VALUES (S.[BonusDepreciationPercent],S.[CreatedById],S.[CreatedTime],S.[DepreciationCostBasisPercent],S.[IsActive],S.[TaxBook],S.[TaxDepRateId],S.[TaxDepTemplateId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

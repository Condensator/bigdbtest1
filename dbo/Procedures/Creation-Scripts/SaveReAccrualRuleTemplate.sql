SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReAccrualRuleTemplate]
(
 @val [dbo].[ReAccrualRuleTemplate] READONLY
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
MERGE [dbo].[ReAccrualRuleTemplates] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Basis]=S.[Basis],[DaysPastDue]=S.[DaysPastDue],[Description]=S.[Description],[IsActive]=S.[IsActive],[MinimumPercentageofBasis]=S.[MinimumPercentageofBasis],[MinimumQualifyingAmount_Amount]=S.[MinimumQualifyingAmount_Amount],[MinimumQualifyingAmount_Currency]=S.[MinimumQualifyingAmount_Currency],[Name]=S.[Name],[PortfolioId]=S.[PortfolioId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Basis],[CreatedById],[CreatedTime],[DaysPastDue],[Description],[IsActive],[MinimumPercentageofBasis],[MinimumQualifyingAmount_Amount],[MinimumQualifyingAmount_Currency],[Name],[PortfolioId])
    VALUES (S.[Basis],S.[CreatedById],S.[CreatedTime],S.[DaysPastDue],S.[Description],S.[IsActive],S.[MinimumPercentageofBasis],S.[MinimumQualifyingAmount_Amount],S.[MinimumQualifyingAmount_Currency],S.[Name],S.[PortfolioId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

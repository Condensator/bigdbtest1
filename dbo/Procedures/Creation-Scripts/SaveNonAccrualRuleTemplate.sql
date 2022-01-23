SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveNonAccrualRuleTemplate]
(
 @val [dbo].[NonAccrualRuleTemplate] READONLY
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
MERGE [dbo].[NonAccrualRuleTemplates] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Basis]=S.[Basis],[BillingSuppressed]=S.[BillingSuppressed],[DaysPastDue]=S.[DaysPastDue],[Description]=S.[Description],[DoubtfulCollectability]=S.[DoubtfulCollectability],[IsActive]=S.[IsActive],[MinimumPercentageofBasis]=S.[MinimumPercentageofBasis],[MinimumQualifyingAmount_Amount]=S.[MinimumQualifyingAmount_Amount],[MinimumQualifyingAmount_Currency]=S.[MinimumQualifyingAmount_Currency],[Name]=S.[Name],[NonAccrualDateOption]=S.[NonAccrualDateOption],[PortfolioId]=S.[PortfolioId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Basis],[BillingSuppressed],[CreatedById],[CreatedTime],[DaysPastDue],[Description],[DoubtfulCollectability],[IsActive],[MinimumPercentageofBasis],[MinimumQualifyingAmount_Amount],[MinimumQualifyingAmount_Currency],[Name],[NonAccrualDateOption],[PortfolioId])
    VALUES (S.[Basis],S.[BillingSuppressed],S.[CreatedById],S.[CreatedTime],S.[DaysPastDue],S.[Description],S.[DoubtfulCollectability],S.[IsActive],S.[MinimumPercentageofBasis],S.[MinimumQualifyingAmount_Amount],S.[MinimumQualifyingAmount_Currency],S.[Name],S.[NonAccrualDateOption],S.[PortfolioId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

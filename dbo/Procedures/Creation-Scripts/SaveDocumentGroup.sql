SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDocumentGroup]
(
 @val [dbo].[DocumentGroup] READONLY
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
MERGE [dbo].[DocumentGroups] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AutoEmail]=S.[AutoEmail],[AutoImportForEntity]=S.[AutoImportForEntity],[Description]=S.[Description],[EntityTypeId]=S.[EntityTypeId],[IsActive]=S.[IsActive],[IsCreditDecision]=S.[IsCreditDecision],[IsReadyToUse]=S.[IsReadyToUse],[Name]=S.[Name],[PortfolioId]=S.[PortfolioId],[RuleExpression]=S.[RuleExpression],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AutoEmail],[AutoImportForEntity],[CreatedById],[CreatedTime],[Description],[EntityTypeId],[IsActive],[IsCreditDecision],[IsReadyToUse],[Name],[PortfolioId],[RuleExpression])
    VALUES (S.[AutoEmail],S.[AutoImportForEntity],S.[CreatedById],S.[CreatedTime],S.[Description],S.[EntityTypeId],S.[IsActive],S.[IsCreditDecision],S.[IsReadyToUse],S.[Name],S.[PortfolioId],S.[RuleExpression])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

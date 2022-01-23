SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveRACRuleConfig]
(
 @val [dbo].[RACRuleConfig] READONLY
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
MERGE [dbo].[RACRuleConfigs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BusinessDeclineReasonCodeConfigId]=S.[BusinessDeclineReasonCodeConfigId],[DataType]=S.[DataType],[DisplayText]=S.[DisplayText],[EntityName]=S.[EntityName],[IsActive]=S.[IsActive],[IsSystemControlled]=S.[IsSystemControlled],[Name]=S.[Name],[NullDefaultValue]=S.[NullDefaultValue],[ParameterLabel]=S.[ParameterLabel],[PortfolioId]=S.[PortfolioId],[RuleExpression]=S.[RuleExpression],[Type]=S.[Type],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BusinessDeclineReasonCodeConfigId],[CreatedById],[CreatedTime],[DataType],[DisplayText],[EntityName],[IsActive],[IsSystemControlled],[Name],[NullDefaultValue],[ParameterLabel],[PortfolioId],[RuleExpression],[Type])
    VALUES (S.[BusinessDeclineReasonCodeConfigId],S.[CreatedById],S.[CreatedTime],S.[DataType],S.[DisplayText],S.[EntityName],S.[IsActive],S.[IsSystemControlled],S.[Name],S.[NullDefaultValue],S.[ParameterLabel],S.[PortfolioId],S.[RuleExpression],S.[Type])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

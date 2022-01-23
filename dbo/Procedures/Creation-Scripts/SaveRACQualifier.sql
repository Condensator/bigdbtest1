SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveRACQualifier]
(
 @val [dbo].[RACQualifier] READONLY
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
MERGE [dbo].[RACQualifiers] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BondRatingId]=S.[BondRatingId],[Bool]=S.[Bool],[IsActive]=S.[IsActive],[Max]=S.[Max],[MaxDate]=S.[MaxDate],[MaxNumber]=S.[MaxNumber],[Min]=S.[Min],[MinDate]=S.[MinDate],[MinNumber]=S.[MinNumber],[Percentage]=S.[Percentage],[RACRuleConfigId]=S.[RACRuleConfigId],[RuleDisplayText]=S.[RuleDisplayText],[String]=S.[String],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BondRatingId],[Bool],[CreatedById],[CreatedTime],[IsActive],[Max],[MaxDate],[MaxNumber],[Min],[MinDate],[MinNumber],[Percentage],[RACId],[RACRuleConfigId],[RuleDisplayText],[String])
    VALUES (S.[BondRatingId],S.[Bool],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[Max],S.[MaxDate],S.[MaxNumber],S.[Min],S.[MinDate],S.[MinNumber],S.[Percentage],S.[RACId],S.[RACRuleConfigId],S.[RuleDisplayText],S.[String])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

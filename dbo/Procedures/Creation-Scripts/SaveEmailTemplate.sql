SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveEmailTemplate]
(
 @val [dbo].[EmailTemplate] READONLY
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
MERGE [dbo].[EmailTemplates] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BodyTemplate_Content]=S.[BodyTemplate_Content],[BodyTemplate_Source]=S.[BodyTemplate_Source],[BodyTemplate_Type]=S.[BodyTemplate_Type],[BodyText]=S.[BodyText],[EmailTemplateEntityConfigId]=S.[EmailTemplateEntityConfigId],[EmailTemplateTypeId]=S.[EmailTemplateTypeId],[IsActive]=S.[IsActive],[IsTagBased]=S.[IsTagBased],[Name]=S.[Name],[PortfolioId]=S.[PortfolioId],[Subject]=S.[Subject],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BodyTemplate_Content],[BodyTemplate_Source],[BodyTemplate_Type],[BodyText],[CreatedById],[CreatedTime],[EmailTemplateEntityConfigId],[EmailTemplateTypeId],[IsActive],[IsTagBased],[Name],[PortfolioId],[Subject])
    VALUES (S.[BodyTemplate_Content],S.[BodyTemplate_Source],S.[BodyTemplate_Type],S.[BodyText],S.[CreatedById],S.[CreatedTime],S.[EmailTemplateEntityConfigId],S.[EmailTemplateTypeId],S.[IsActive],S.[IsTagBased],S.[Name],S.[PortfolioId],S.[Subject])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

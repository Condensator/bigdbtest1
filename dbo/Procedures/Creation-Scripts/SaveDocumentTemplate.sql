SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDocumentTemplate]
(
 @val [dbo].[DocumentTemplate] READONLY
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
MERGE [dbo].[DocumentTemplates] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [EnabledForESignature]=S.[EnabledForESignature],[GeneratedTemplate_Content]=S.[GeneratedTemplate_Content],[GeneratedTemplate_Source]=S.[GeneratedTemplate_Source],[GeneratedTemplate_Type]=S.[GeneratedTemplate_Type],[IsActive]=S.[IsActive],[IsDefault]=S.[IsDefault],[IsExpressionBased]=S.[IsExpressionBased],[IsLanguageApplicable]=S.[IsLanguageApplicable],[Name]=S.[Name],[RelatedEntityId]=S.[RelatedEntityId],[ScriptId]=S.[ScriptId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[DocumentTypeId],[EnabledForESignature],[GeneratedTemplate_Content],[GeneratedTemplate_Source],[GeneratedTemplate_Type],[IsActive],[IsDefault],[IsExpressionBased],[IsLanguageApplicable],[Name],[RelatedEntityId],[ScriptId])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[DocumentTypeId],S.[EnabledForESignature],S.[GeneratedTemplate_Content],S.[GeneratedTemplate_Source],S.[GeneratedTemplate_Type],S.[IsActive],S.[IsDefault],S.[IsExpressionBased],S.[IsLanguageApplicable],S.[Name],S.[RelatedEntityId],S.[ScriptId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

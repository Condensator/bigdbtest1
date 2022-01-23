SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDocumentGroupDetail]
(
 @val [dbo].[DocumentGroupDetail] READONLY
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
MERGE [dbo].[DocumentGroupDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AttachmentRequired]=S.[AttachmentRequired],[AutoGenerate]=S.[AutoGenerate],[DefaultTemplateExpression]=S.[DefaultTemplateExpression],[DefaultTemplateId]=S.[DefaultTemplateId],[DocumentTypeId]=S.[DocumentTypeId],[ForceRegenerate]=S.[ForceRegenerate],[GenerationOrder]=S.[GenerationOrder],[IsActive]=S.[IsActive],[IsMandatory]=S.[IsMandatory],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AttachmentRequired],[AutoGenerate],[CreatedById],[CreatedTime],[DefaultTemplateExpression],[DefaultTemplateId],[DocumentGroupId],[DocumentTypeId],[ForceRegenerate],[GenerationOrder],[IsActive],[IsMandatory])
    VALUES (S.[AttachmentRequired],S.[AutoGenerate],S.[CreatedById],S.[CreatedTime],S.[DefaultTemplateExpression],S.[DefaultTemplateId],S.[DocumentGroupId],S.[DocumentTypeId],S.[ForceRegenerate],S.[GenerationOrder],S.[IsActive],S.[IsMandatory])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

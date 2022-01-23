SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDocumentList]
(
 @val [dbo].[DocumentList] READONLY
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
MERGE [dbo].[DocumentLists] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AttachmentRequired]=S.[AttachmentRequired],[DocumentGroupDetailId]=S.[DocumentGroupDetailId],[DocumentId]=S.[DocumentId],[DocumentSource]=S.[DocumentSource],[DocumentTypeId]=S.[DocumentTypeId],[EnabledForESignature]=S.[EnabledForESignature],[EntityId]=S.[EntityId],[ForceRegenerate]=S.[ForceRegenerate],[GenerationOrder]=S.[GenerationOrder],[IsActive]=S.[IsActive],[IsMandatory]=S.[IsMandatory],[IsManual]=S.[IsManual],[SpecificEntityId]=S.[SpecificEntityId],[SpecificEntityNaturalId]=S.[SpecificEntityNaturalId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AttachmentRequired],[CreatedById],[CreatedTime],[DocumentGroupDetailId],[DocumentHeaderId],[DocumentId],[DocumentSource],[DocumentTypeId],[EnabledForESignature],[EntityId],[ForceRegenerate],[GenerationOrder],[IsActive],[IsMandatory],[IsManual],[SpecificEntityId],[SpecificEntityNaturalId])
    VALUES (S.[AttachmentRequired],S.[CreatedById],S.[CreatedTime],S.[DocumentGroupDetailId],S.[DocumentHeaderId],S.[DocumentId],S.[DocumentSource],S.[DocumentTypeId],S.[EnabledForESignature],S.[EntityId],S.[ForceRegenerate],S.[GenerationOrder],S.[IsActive],S.[IsMandatory],S.[IsManual],S.[SpecificEntityId],S.[SpecificEntityNaturalId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDocumentInstance]
(
 @val [dbo].[DocumentInstance] READONLY
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
MERGE [dbo].[DocumentInstances] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AttachmentDetailId]=S.[AttachmentDetailId],[DefaultPermission]=S.[DefaultPermission],[DocumentTemplateDetailId]=S.[DocumentTemplateDetailId],[DocumentTemplateId]=S.[DocumentTemplateId],[DocumentTypeId]=S.[DocumentTypeId],[EffectiveDate]=S.[EffectiveDate],[EntityId]=S.[EntityId],[EntityNaturalId]=S.[EntityNaturalId],[ExceptionComment]=S.[ExceptionComment],[ExpiryDate]=S.[ExpiryDate],[IsActive]=S.[IsActive],[IsGenerationAllowed]=S.[IsGenerationAllowed],[IsModificationRequired]=S.[IsModificationRequired],[IsReadOnly]=S.[IsReadOnly],[IsRetention]=S.[IsRetention],[ModificationComment]=S.[ModificationComment],[ModificationReason]=S.[ModificationReason],[RelatedInstanceId]=S.[RelatedInstanceId],[StatusId]=S.[StatusId],[Title]=S.[Title],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AttachmentDetailId],[CreatedById],[CreatedTime],[DefaultPermission],[DocumentTemplateDetailId],[DocumentTemplateId],[DocumentTypeId],[EffectiveDate],[EntityId],[EntityNaturalId],[ExceptionComment],[ExpiryDate],[IsActive],[IsGenerationAllowed],[IsModificationRequired],[IsReadOnly],[IsRetention],[ModificationComment],[ModificationReason],[RelatedInstanceId],[StatusId],[Title])
    VALUES (S.[AttachmentDetailId],S.[CreatedById],S.[CreatedTime],S.[DefaultPermission],S.[DocumentTemplateDetailId],S.[DocumentTemplateId],S.[DocumentTypeId],S.[EffectiveDate],S.[EntityId],S.[EntityNaturalId],S.[ExceptionComment],S.[ExpiryDate],S.[IsActive],S.[IsGenerationAllowed],S.[IsModificationRequired],S.[IsReadOnly],S.[IsRetention],S.[ModificationComment],S.[ModificationReason],S.[RelatedInstanceId],S.[StatusId],S.[Title])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

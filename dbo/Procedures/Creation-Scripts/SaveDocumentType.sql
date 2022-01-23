SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDocumentType]
(
 @val [dbo].[DocumentType] READONLY
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
MERGE [dbo].[DocumentTypes] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AllowDuplicate]=S.[AllowDuplicate],[BusinessEntityId]=S.[BusinessEntityId],[Category]=S.[Category],[Classification]=S.[Classification],[CreationAllowed]=S.[CreationAllowed],[DefaultPermission]=S.[DefaultPermission],[DefaultTitle]=S.[DefaultTitle],[Description]=S.[Description],[DocumentDirection]=S.[DocumentDirection],[DocumentTitleRequired]=S.[DocumentTitleRequired],[EntityId]=S.[EntityId],[GenerationAllowedExpression]=S.[GenerationAllowedExpression],[IsActive]=S.[IsActive],[IsCoverLetter]=S.[IsCoverLetter],[IsReadyToUse]=S.[IsReadyToUse],[IsRetention]=S.[IsRetention],[ManualEntitySelectionNeeded]=S.[ManualEntitySelectionNeeded],[Name]=S.[Name],[PortfolioId]=S.[PortfolioId],[RelatedDocTypeId]=S.[RelatedDocTypeId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[ViewableAtRelatedEntities]=S.[ViewableAtRelatedEntities]
WHEN NOT MATCHED THEN
	INSERT ([AllowDuplicate],[BusinessEntityId],[Category],[Classification],[CreatedById],[CreatedTime],[CreationAllowed],[DefaultPermission],[DefaultTitle],[Description],[DocumentDirection],[DocumentTitleRequired],[EntityId],[GenerationAllowedExpression],[IsActive],[IsCoverLetter],[IsReadyToUse],[IsRetention],[ManualEntitySelectionNeeded],[Name],[PortfolioId],[RelatedDocTypeId],[ViewableAtRelatedEntities])
    VALUES (S.[AllowDuplicate],S.[BusinessEntityId],S.[Category],S.[Classification],S.[CreatedById],S.[CreatedTime],S.[CreationAllowed],S.[DefaultPermission],S.[DefaultTitle],S.[Description],S.[DocumentDirection],S.[DocumentTitleRequired],S.[EntityId],S.[GenerationAllowedExpression],S.[IsActive],S.[IsCoverLetter],S.[IsReadyToUse],S.[IsRetention],S.[ManualEntitySelectionNeeded],S.[Name],S.[PortfolioId],S.[RelatedDocTypeId],S.[ViewableAtRelatedEntities])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

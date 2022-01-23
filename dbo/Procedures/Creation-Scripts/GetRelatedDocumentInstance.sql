SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create PROCEDURE [dbo].[GetRelatedDocumentInstance]
  (
  @List as [RelatedEntityIdList] READONLY,
  @CurrentSiteId bigint 
)
AS
BEGIN
  SET NOCOUNT ON;
    select distinct DocumentInstances.Id 
  from @List as l
  join 
  DocumentInstances on l.EntityId = DocumentInstances.EntityId
  join DocumentLists on DocumentInstances.Id = DocumentLists.DocumentId
  join DocumentTypes on DocumentInstances.DocumentTypeId = DocumentTypes.Id and l.EntityTypeId = DocumentTypes.EntityId
  join DocumentTypeSubSystemDetails on DocumentTypes.Id = DocumentTypeSubSystemDetails.DocumentTypeId
  where 
  DocumentTypes.IsReadyToUse = 1
  and DocumentTypes.ViewableAtRelatedEntities = 1
  and DocumentInstances.IsActive = 1
  and DocumentTypeSubSystemDetails.Viewable = 1
  and DocumentTypeSubSystemDetails.SubSystemId = @CurrentSiteId

END

GO

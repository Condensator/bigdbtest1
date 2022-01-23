SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetDocumentTypes]
(
	@SubSystemCustomerPortal				NVARCHAR(14),
	@EntityTypeCustomer						NVARCHAR(100),
	@EntityTypeLeaseFinance					NVARCHAR(100),
	@EntityTypeLoanFinance					NVARCHAR(100),
	@DocumentDirectionIn					NVARCHAR(3),
	@DocumentTypeCreationAllowed            NVARCHAR(7)
)
AS
SET NOCOUNT ON
BEGIN

	CREATE TABLE #ViewableDocumentTypeIds
	(
		DocumentTypeId BIGINT NOT NULL
	)

	INSERT INTO #ViewableDocumentTypeIds
	SELECT 
		DISTINCT DocumentTypes.Id 
	FROM DocumentTypes
	INNER JOIN DocumentTypeSubSystemDetails 
		ON DocumentTypes.Id = DocumentTypeSubSystemDetails.DocumentTypeId
	INNER JOIN SubSystemConfigs
		ON DocumentTypeSubSystemDetails.SubSystemId = SubSystemConfigs.Id
	WHERE
        DocumentTypes.IsActive = 1
        AND DocumentTypeSubSystemDetails.Viewable = 1
        AND DocumentTypeSubSystemDetails.IsActive = 1
        AND SubSystemConfigs.Name = @SubSystemCustomerPortal
        AND DocumentTypes.CreationAllowed = @DocumentTypeCreationAllowed

	SELECT 
		DocumentTypes.Id DocumentTypeId,
		DocumentTypes.Name,
		EntityConfigs.Name EntityType,
		DocumentTypes.AllowDuplicate
	 FROM DocumentTypes
		INNER JOIN #ViewableDocumentTypeIds
			ON DocumentTypes.Id = #ViewableDocumentTypeIds.DocumentTypeId
		INNER JOIN DocumentEntityConfigs
			ON DocumentTypes.EntityId = DocumentEntityConfigs.Id
		INNER JOIN EntityConfigs
			ON DocumentEntityConfigs.Id = EntityConfigs.Id
	WHERE
		EntityConfigs.Name IN (@EntityTypeCustomer, @EntityTypeLeaseFinance, @EntityTypeLoanFinance)
		AND DocumentTypes.DocumentDirection = @DocumentDirectionIn 	

	DROP TABLE #ViewableDocumentTypeIds;

SET NOCOUNT OFF;
END

GO

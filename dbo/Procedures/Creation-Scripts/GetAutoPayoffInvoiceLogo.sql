SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetAutoPayoffInvoiceLogo]
(
	@RemitToId BIGINT
)
AS
BEGIN
SET NOCOUNT ON;

	SELECT LegalEntityLogoImageType  = 'image/'+ ISNULL(Logo.LogoImageFile_Type, 'png')
			,LegalEntityLogoImageContent = (CASE WHEN (Logo.LogoImageFile_Content IS NOT NULL AND Logo.LogoImageFile_Content <> 0x) 
														THEN (SELECT Content FROM FileStores WHERE Guid = dbo.GetContentGuid(Logo.LogoImageFile_Content)) 
														ELSE NULL END)
		FROM RemitToes RemitTo
			LEFT JOIN Logoes Logo ON RemitTo.LogoId = Logo.Id
		WHERE RemitTo.Id = @RemitToId;

END

GO

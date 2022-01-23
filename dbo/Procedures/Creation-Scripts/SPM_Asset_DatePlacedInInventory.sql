SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE   PROC [dbo].[SPM_Asset_DatePlacedInInventory]
AS
BEGIN
	UPDATE TGT
		SET TGT.DatePlacedInInventory = SRC.DatePlacedInInventory
	FROM ##AssetMeasures TGT
		INNER JOIN 
		(SELECT 
			EA.AssetId
			,AsofDate as [DatePlacedInInventory]
		FROM
			##Asset_EligibleAssets EA
		LEFT JOIN
			##Asset_DateInInventory DPII ON DPII.AssetId = EA.AssetId
		) SRC
		ON TGT.ID = SRC.AssetId
END

GO

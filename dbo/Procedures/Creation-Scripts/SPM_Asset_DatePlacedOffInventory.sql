SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Asset_DatePlacedOffInventory]
AS
BEGIN
	UPDATE TGT
		SET TGT.DatePlacedOffInventory = SRC.DatePlacedOffInventory
	FROM ##AssetMeasures TGT
		INNER JOIN 
		(SELECT 
			EA.AssetId
			,AsofDate as [DatePlacedOffInventory]
		FROM
			##Asset_EligibleAssets EA
		LEFT JOIN
			##Asset_DateOffInventory DPOI ON DPOI.AssetId = EA.AssetId
		) SRC
		ON TGT.ID = SRC.AssetId
END

GO

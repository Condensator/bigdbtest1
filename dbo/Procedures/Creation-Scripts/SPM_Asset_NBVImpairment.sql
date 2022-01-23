SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Asset_NBVImpairment]
AS
BEGIN
	UPDATE TGT
		SET TGT.NBVImpairment = SRC.NBVImpairment
	FROM ##AssetMeasures TGT
		INNER JOIN 
		(SELECT 
			EA.AssetId
			,ISNULL(NBVI.NBVImpairment,0.00) [NBVImpairment]
		FROM
			##Asset_EligibleAssets EA
		LEFT JOIN
			##Asset_NBVImpairments NBVI ON NBVI.AssetId = EA.AssetId
		) SRC
		ON TGT.ID = SRC.AssetId
END

GO

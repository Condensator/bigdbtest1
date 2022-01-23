SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Asset_RemainingEconomicLife]
AS
BEGIN
	UPDATE TGT
		SET TGT.RemainingEconomicLife = SRC.RemainingEconomicLife
	FROM
		##AssetMeasures TGT
	INNER JOIN 
		(SELECT 
	         EA.AssetId
			,RemainingEconomicLife
		FROM
			##Asset_EligibleAssets EA
		LEFT JOIN
			##Asset_RemainingEconomicLifeInfo REL ON REL.AssetId = EA.AssetId
		 ) SRC ON TGT.ID = SRC.AssetId
END

GO

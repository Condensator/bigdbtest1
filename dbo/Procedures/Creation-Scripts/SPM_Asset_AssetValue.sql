SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROC [dbo].[SPM_Asset_AssetValue]
AS
BEGIN
	UPDATE TGT
		SET TGT.AssetValue = SRC.AssetValue
	FROM
		##AssetMeasures TGT
	INNER JOIN 
		(SELECT 
	         EA.AssetId
			,ISNULL((CASE WHEN EA.AssetStatus NOT IN ('Leased','InvestorLeased')
				      THEN AVC.ActualValue ELSE 0.00 END),0.00) AS AssetValue
		FROM
			##Asset_EligibleAssets EA
		LEFT JOIN
			##Asset_ActualValueCalculation AVC ON AVC.AssetId = EA.AssetId
		 ) SRC ON TGT.ID = SRC.AssetId
END

GO

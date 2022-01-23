SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Asset_RemainingEconomicLifeInfo]
AS
BEGIN

SELECT
	ea.AssetId
	,ea.AssetStatus
	,ea.HoldingStatus
	,CASE 
		WHEN la.AssetId IS NOT NULL THEN ea.TotalEconomicLife - CAST (la.RemainingEconomicLife AS decimal)
		WHEN ea.AssetStatus NOT IN ('Leased','InvestorLeased') AND rbd.AssetId IS NOT NULL THEN rbd.RemainingLifeInMonths
		WHEN pai.AssetId IS NOT NULL THEN ea.TotalEconomicLife - CAST (pai.RemainingEconomicLife AS decimal)
		ELSE 0 
	END [RemainingEconomicLife] INTO ##Asset_RemainingEconomicLifeInfo
FROM ##Asset_EligibleAssets ea
LEFT JOIN ##Asset_LeaseAssetsInfo la ON ea.AssetId = la.AssetId
LEFT JOIN ##Asset_RELBookDepInfo rbd ON ea.AssetId = rbd.AssetId
LEFT JOIN ##Asset_PayoffInfo pai ON ea.AssetId = pai.AssetId;

CREATE NONCLUSTERED INDEX IX_RemainingEconomicLifeInfo_AssetId ON ##Asset_RemainingEconomicLifeInfo(AssetId);

UPDATE rel
SET rel.RemainingEconomicLife = 0
FROM ##Asset_RemainingEconomicLifeInfo rel
WHERE rel.AssetStatus IN ('Sold','Scrap') 
OR rel.HoldingStatus = 'HFS' OR rel.RemainingEconomicLife < 0;

END

GO

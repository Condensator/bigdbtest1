SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 


CREATE   PROC [dbo].[SPM_Asset_PayoffInfo]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	ea.AssetId
	,CASE
		WHEN pa.IsPartiallyOwned = 1
		THEN 'Yes'
		ELSE 'No'
	END [IsPartiallyOwned]
	,CASE
		WHEN p.PayoffEffectiveDate >= ea.AcquisitionDate
		THEN DATEDIFF(MONTH,ea.AcquisitionDate,p.PayoffEffectiveDate)
		ELSE 0
	END [RemainingEconomicLife]   INTO ##Asset_PayoffInfo
FROM 
	##Asset_EligibleAssets ea
INNER JOIN (
	SELECT ea.AssetId,MAX(pa.Id) AS PayoffAssetId
	FROM ##Asset_EligibleAssets ea
	INNER JOIN LeaseAssets la ON ea.AssetId = la.AssetId
	INNER JOIN PayoffAssets pa ON pa.LeaseAssetId = la.Id
	INNER JOIN Payoffs p ON pa.PayoffId = p.Id
	AND p.Status = 'Activated' AND pa.IsActive = 1
	GROUP BY ea.AssetId) AS T ON t.AssetId = ea.AssetId
INNER JOIN PayoffAssets pa ON t.PayoffAssetId = pa.Id
INNER JOIN Payoffs p ON pa.PayoffId = p.Id
WHERE p.Status = 'Activated' AND pa.IsActive = 1;

CREATE NONCLUSTERED INDEX IX_PayoffInfo_AssetId ON ##Asset_PayoffInfo(AssetId);

END

GO

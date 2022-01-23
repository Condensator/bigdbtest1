SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 

CREATE   PROC [dbo].[SPM_Asset_PayoffAssetInfo]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
SELECT 
	ea.AssetId
	,MAX(p.LeaseFinanceId) AS PayoffLeaseFinanceId
	,MAX(p.PayoffEffectiveDate) AS PayoffEffectiveDate  INTO ##Asset_PayoffAssetInfo
FROM
	##Asset_EligibleAssets ea
INNER JOIN
	LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN
	PayoffAssets pa ON pa.LeaseAssetId = la.Id
INNER JOIN
	Payoffs p ON pa.PayoffId = p.Id
	AND p.Status = 'Activated' AND pa.IsActive = 1
GROUP BY
	ea.AssetId;

CREATE NONCLUSTERED INDEX IX_PayoffAssetInfo_AssetId ON ##Asset_PayoffAssetInfo(AssetId);

END

GO

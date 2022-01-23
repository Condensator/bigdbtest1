SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Asset_AVHAssetsInfo]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
SELECT 
	DISTINCT
	ea.AssetId
	,la.IsLeaseAsset
	,la.IsFailedSaleLeaseback	 INTO ##Asset_AVHAssetsInfo
FROM 
	##Asset_EligibleAssets ea
INNER JOIN
	LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN
	LeaseFinances lf ON la.LeaseFinanceId = lf.Id
INNER JOIN
	LeaseFinanceDetails lfd ON lf.Id = lfd.Id
WHERE
	ea.PreviousSequenceNumber IS NULL

INSERT INTO ##Asset_AVHAssetsInfo
SELECT
	DISTINCT
	ea.AssetId
	,la.IsLeaseAsset
	,la.IsFailedSaleLeaseback
FROM
	##Asset_EligibleAssets ea
INNER JOIN 
	LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN
	(SELECT 
		DISTINCT
		ea.AssetId
		,Max(la.LeaseFinanceId) LeaseFinanceId
	FROM
		##Asset_EligibleAssets ea
	INNER JOIN 
		LeaseAssets la ON ea.AssetId = la.AssetId
	INNER JOIN
		LeaseFinances lf ON la.LeaseFinanceId = lf.Id
	INNER JOIN
		LeaseFinanceDetails lfd ON lf.Id = lfd.Id
	WHERE
		ea.PreviousSequenceNumber IS NOT NULL
	GROUP BY
		ea.AssetId) AS t ON t.AssetId = ea.AssetId AND t.LeaseFinanceId = la.LeaseFinanceId

CREATE NONCLUSTERED INDEX IX_AVHAssetsInfo_AssetId ON ##Asset_AVHAssetsInfo(AssetId);

END

GO

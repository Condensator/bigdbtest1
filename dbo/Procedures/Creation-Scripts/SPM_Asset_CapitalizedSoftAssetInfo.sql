SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Asset_CapitalizedSoftAssetInfo]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @AddCharge BIT = 0;

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'LeaseAssets' AND COLUMN_NAME = 'CapitalizedAdditionalCharge_Amount')
BEGIN
SET @AddCharge = 1;
END;

SELECT DISTINCT
	ea.AssetId
	,la.CapitalizationType
	,lai.AssetId [SoftAssetCapitalizedFor]  INTO ##Asset_CapitalizedSoftAssetInfo
FROM
	##Asset_EligibleAssets ea
INNER JOIN
	LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN
	LeaseFinances lf ON la.LeaseFinanceId = lf.Id
INNER JOIN
	LeaseAssets lai ON lai.Id = la.CapitalizedForId
WHERE
	la.CapitalizedForId IS NOT NULL

IF @AddCharge = 1
BEGIN
INSERT INTO ##Asset_CapitalizedSoftAssetInfo
SELECT DISTINCT 
	 ea.AssetId
	,CapitalizationType = 'AdditionalCharge'
	,la.CapitalizedForId [SoftAssetCapitalizedFor]
FROM 
	##Asset_EligibleAssets ea
INNER JOIN
	LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN
	LeaseFinances lf ON la.LeaseFinanceId = lf.Id
WHERE
	IsAdditionalChargeSoftAsset = 1
END

CREATE NONCLUSTERED INDEX IX_CapitalizedSoftAssetInfo_AssetId ON ##Asset_CapitalizedSoftAssetInfo(AssetId);

END

GO

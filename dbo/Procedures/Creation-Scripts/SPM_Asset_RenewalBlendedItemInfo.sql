SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Asset_RenewalBlendedItemInfo]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @IsSku BIT = 0;

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Assets' AND COLUMN_NAME = 'IsSku')
BEGIN
SET @IsSku = 1
END;

IF @IsSku = 1
BEGIN
SELECT
	DISTINCT ea.AssetId
	,SUM(CASE WHEN las.IsLeaseComponent = 1 AND la.IsFailedSaleLeaseback = 0 
	THEN las.ETCAdjustmentAmount_Amount ELSE 0.00 END) [ETCAmount_LeaseComponent]
	,SUM(CASE WHEN las.IsLeaseComponent = 0 OR la.IsFailedSaleLeaseback = 1
	THEN las.ETCAdjustmentAmount_Amount ELSE 0.00 END) [ETCAmount_FinanceComponent] INTO ##Asset_RenewalBlendedItemInfo
FROM
	##Asset_EligibleAssets ea
INNER JOIN
	LeaseAssets la ON la.AssetId = ea.AssetId
INNER JOIN
	LeaseAssetSKUs las ON las.LeaseAssetId = la.Id
INNER JOIN
	##Asset_LeaseAmendmentInfo lam ON lam.OriginalLeaseFinanceId = la.LeaseFinanceId
WHERE
	la.IsActive = 1 AND las.IsActive = 1 AND ea.IsSKU = 1
GROUP BY
	ea.AssetId
END

CREATE NONCLUSTERED INDEX IX_RenewalBlendedItemInfo_AssetId ON ##Asset_RenewalBlendedItemInfo(AssetId);

END

GO

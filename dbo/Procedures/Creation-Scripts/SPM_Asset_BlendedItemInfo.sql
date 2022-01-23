SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Asset_BlendedItemInfo]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @IsSku BIT = 0;

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Assets' AND COLUMN_NAME = 'IsSku')
BEGIN
SET @IsSku = 1
END;

SELECT 
	DISTINCT
	ea.AssetId
	,CASE WHEN la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0 THEN bia.TaxCredit_Amount ELSE 0.00 END [ETCAmount_LeaseComponent]
	,CASE WHEN la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1 THEN bia.TaxCredit_Amount ELSE 0.00 END [ETCAmount_FinanceComponent]  INTO ##Asset_BlendedItemInfo
FROM 
	##Asset_EligibleAssets ea
INNER JOIN
	LeaseAssets la ON la.AssetId = ea.AssetId
INNER JOIN
	BlendedItemAssets bia ON bia.LeaseAssetId = la.Id
INNER JOIN
	BlendedItems bi ON bia.BlendedItemId = bi.Id
INNER JOIN
	LeaseFinances lf ON lf.Id = la.LeaseFinanceId
INNER JOIN
	LeaseFinanceDetails lfd ON lf.Id = lfd.Id
WHERE
	(bia.IsActive = 1 and bi.IsActive = 1)
	AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate >= lfd.CommencementDate))
	AND lf.IsCurrent = 1 AND lf.ApprovalStatus IN ('Approved','InsuranceFollowup')
	AND bi.IsETC = 1 AND ea.IsSKU = 0

IF @IsSku = 1
BEGIN
INSERT INTO ##Asset_BlendedItemInfo
SELECT
	DISTINCT
	ea.AssetId
	,SUM(CASE WHEN las.IsLeaseComponent = 1 AND la.IsFailedSaleLeaseback = 0 
	THEN las.ETCAdjustmentAmount_Amount ELSE 0.00 END) [ETCAmount_LeaseComponent]
	,SUM(CASE WHEN las.IsLeaseComponent = 0 OR la.IsFailedSaleLeaseback = 1
	THEN las.ETCAdjustmentAmount_Amount ELSE 0.00 END) [ETCAmount_FinanceComponent]
FROM
	##Asset_EligibleAssets ea
INNER JOIN
	LeaseAssets la ON la.AssetId = ea.AssetId
INNER JOIN
	LeaseAssetSKUs las ON las.LeaseAssetId = la.Id
INNER JOIN
	LeaseFinances lf ON lf.Id = la.LeaseFinanceId
INNER JOIN
	LeaseFinanceDetails lfd ON lf.Id = lfd.Id
WHERE
	(la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate >= lfd.CommencementDate))
	AND lf.IsCurrent = 1 AND lf.ApprovalStatus IN ('Approved','InsuranceFollowup')
	AND las.IsActive = 1 AND ea.IsSKU = 1
GROUP BY
	ea.AssetId
END

CREATE NONCLUSTERED INDEX IX_BlendedItemInfo_AssetId ON ##Asset_BlendedItemInfo(AssetId);

MERGE ##Asset_BlendedItemInfo bi
USING
(SELECT 
	DISTINCT
	ea.AssetId
	,CASE WHEN la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0 THEN bia.TaxCredit_Amount ELSE 0.00 END [ETCAmount_LeaseComponent]
	,CASE WHEN la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1 THEN bia.TaxCredit_Amount ELSE 0.00 END [ETCAmount_FinanceComponent]
FROM
	##Asset_EligibleAssets ea
INNER JOIN
	LeaseAssets la ON la.AssetId = ea.AssetId
INNER JOIN
	BlendedItemAssets bia ON bia.LeaseAssetId = la.Id
INNER JOIN
	BlendedItems bi ON bia.BlendedItemId = bi.Id
INNER JOIN
	##Asset_LeaseAmendmentInfo lam ON lam.OriginalLeaseFinanceId = la.LeaseFinanceId
WHERE
	bia.IsActive = 1 and bi.IsActive = 1
	AND la.IsActive = 1 AND bi.IsETC = 1 AND ea.IsSKU = 0) AS t
	ON (bi.AssetId = t.AssetId)
WHEN MATCHED
THEN
UPDATE
	SET bi.ETCAmount_LeaseComponent += t.ETCAmount_LeaseComponent
	,bi.ETCAmount_FinanceComponent += t.ETCAmount_FinanceComponent
WHEN NOT MATCHED
	THEN INSERT (AssetId,ETCAmount_LeaseComponent,ETCAmount_FinanceComponent)
		VALUES (t.AssetId,t.ETCAmount_LeaseComponent,t.ETCAmount_FinanceComponent);

MERGE 
	##Asset_BlendedItemInfo bi
USING
	(SELECT * FROM ##Asset_RenewalBlendedItemInfo) AS t
	ON (bi.AssetId = t.AssetId)
WHEN MATCHED
THEN
UPDATE
	SET bi.ETCAmount_LeaseComponent += t.ETCAmount_LeaseComponent
		,bi.ETCAmount_FinanceComponent += t.ETCAmount_FinanceComponent
WHEN NOT MATCHED
THEN 
	INSERT (AssetId,ETCAmount_LeaseComponent,ETCAmount_FinanceComponent)
	VALUES (t.AssetId,t.ETCAmount_LeaseComponent,t.ETCAmount_FinanceComponent);

END

GO

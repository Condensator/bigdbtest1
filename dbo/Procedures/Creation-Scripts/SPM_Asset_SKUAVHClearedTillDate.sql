SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 

CREATE   PROC [dbo].[SPM_Asset_SKUAVHClearedTillDate]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @IsSku BIT = 0;

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Assets' AND COLUMN_NAME = 'IsSku')
BEGIN
SET @IsSku = 1
END;

IF @IsSKU = 1
BEGIN
SELECT 
	 ea.AssetId
	,avh.IsLeaseComponent
	,MAX(avh.IncomeDate) AVHClearedTillDate
	,MAX(avh.Id) AVHClearedId							INTO ##Asset_SKUAVHClearedTillDate
FROM
	##Asset_EligibleAssets ea
INNER JOIN
	AssetValueHistories avh ON ea.AssetId = avh.AssetId
WHERE
	avh.IsCleared = 1
	AND avh.IsAccounted = 1
	AND ea.IsSKU = 1
GROUP BY
	ea.AssetId,
	avh.IsLeaseComponent
END;

CREATE NONCLUSTERED INDEX IX_SKUAVHClearedTillDate_AssetId ON ##Asset_SKUAVHClearedTillDate(AssetId);

END

GO

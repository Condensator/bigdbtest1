SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Asset_AssetInventoryAVHInfo]
AS
BEGIN

DECLARE @IsSku BIT = 0;

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Assets' AND COLUMN_NAME = 'IsSku')
BEGIN
SET @IsSku = 1
END;

BEGIN
SELECT
	ea.AssetId
	,SUM(CASE
		WHEN ea.IsLeaseComponent = 1 AND avhc.AssetId IS NOT NULL AND avh.AdjustmentEntry = 0
		AND avh.IncomeDate <= avhc.AVHClearedTillDate
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedInventoryDepreciationAmount_LeaseComponent]
	,SUM(CASE
		WHEN ea.IsLeaseComponent = 0 AND avhc.AssetId IS NOT NULL AND avh.AdjustmentEntry = 0
		AND avh.IncomeDate <= avhc.AVHClearedTillDate
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedInventoryDepreciationAmount_FinanceComponent]
	,SUM(CASE
		WHEN ea.IsLeaseComponent = 1 AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedInventoryDepreciationAmount_LeaseComponent]
	,SUM(CASE
		WHEN ea.IsLeaseComponent = 0 AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedInventoryDepreciationAmount_FinanceComponent]  INTO ##Asset_AssetInventoryAVHInfo
FROM 
	##Asset_EligibleAssets ea
INNER JOIN
	AssetValueHistories avh ON avh.AssetId = ea.AssetId
LEFT JOIN
	##Asset_AVHClearedTillDate avhc ON avhc.AssetId = ea.AssetId
WHERE avh.IsAccounted = 1 AND avh.IsLessorOwned = 1 AND avh.SourceModule = 'InventoryBookDepreciation'
AND ea.IsSKU = 0
GROUP BY ea.AssetId
END;

IF @IsSku = 1
BEGIN
INSERT INTO ##Asset_AssetInventoryAVHInfo
SELECT
	ea.AssetId
	,SUM(CASE
		WHEN avh.IsLeaseComponent = 1 AND avhc.AssetId IS NOT NULL AND avh.AdjustmentEntry = 0
		AND avh.IncomeDate <= avhc.AVHClearedTillDate
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedInventoryDepreciationAmount_LeaseComponent]
	,SUM(CASE
		WHEN avh.IsLeaseComponent = 0 AND avhc.AssetId IS NOT NULL AND avh.AdjustmentEntry = 0
		AND avh.IncomeDate <= avhc.AVHClearedTillDate
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedInventoryDepreciationAmount_FinanceComponent]
	,SUM(CASE
		WHEN avh.IsLeaseComponent = 1 AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedInventoryDepreciationAmount_LeaseComponent]
	,SUM(CASE
		WHEN avh.IsLeaseComponent = 0 AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedInventoryDepreciationAmount_FinanceComponent]
FROM 
	##Asset_EligibleAssets ea
INNER JOIN 
	AssetValueHistories avh ON avh.AssetId = ea.AssetId
LEFT JOIN
	##Asset_AVHClearedTillDate avhc ON avhc.AssetId = ea.AssetId
WHERE avh.IsAccounted = 1 AND avh.IsLessorOwned = 1 AND avh.SourceModule = 'InventoryBookDepreciation'
AND ea.IsSKU = 1
GROUP BY ea.AssetId
END

CREATE NONCLUSTERED INDEX IX_AssetInventoryAVHInfo_AssetId ON ##Asset_AssetInventoryAVHInfo(AssetId);

UPDATE ai
SET ai.AccumulatedInventoryDepreciationAmount_LeaseComponent -= ai.ClearedInventoryDepreciationAmount_LeaseComponent
	,ai.AccumulatedInventoryDepreciationAmount_FinanceComponent -= ai.ClearedInventoryDepreciationAmount_FinanceComponent
FROM ##Asset_AssetInventoryAVHInfo ai
WHERE (ai.ClearedInventoryDepreciationAmount_LeaseComponent != 0.00 OR ai.ClearedInventoryDepreciationAmount_FinanceComponent != 0.00)

END

GO

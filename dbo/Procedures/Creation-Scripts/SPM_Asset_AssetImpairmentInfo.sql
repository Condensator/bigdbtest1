SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Asset_AssetImpairmentInfo]
AS
BEGIN

BEGIN
SELECT
	avscd.AssetId
	,SUM(CASE
		WHEN aiavh.IsLeaseComponent = 1 AND avhc.AssetId IS NOT NULL AND aiavh.AVHIncomeDate <= avhc.AVHClearedTillDate AND aiavh.AVHId <= avhc.AVHClearedId
		THEN avscd.AdjustmentAmount_Amount
		ELSE 0.00
		END) AS [ClearedAssetImpairmentAmount_LeaseComponent]
	,SUM(CASE
		WHEN aiavh.IsLeaseComponent = 0 AND avhc.AssetId IS NOT NULL AND aiavh.AVHIncomeDate <= avhc.AVHClearedTillDate AND aiavh.AVHId <= avhc.AVHClearedId
		THEN avscd.AdjustmentAmount_Amount
		ELSE 0.00
		END) AS [ClearedAssetImpairmentAmount_FinanceComponent]
	,SUM(CASE
		WHEN aiavh.IsLeaseComponent = 1 AND aiavh.GLJournalId IS NOT NULL AND aiavh.ReversalGLJournalId IS NULL
		THEN avscd.AdjustmentAmount_Amount
		ELSE 0.00
		END) AS [AccumulatedAssetImpairmentAmount_LeaseComponent]
	,SUM(CASE
		WHEN aiavh.IsLeaseComponent = 0 AND aiavh.GLJournalId IS NOT NULL AND aiavh.ReversalGLJournalId IS NULL
		THEN avscd.AdjustmentAmount_Amount
		ELSE 0.00
		END) AS [AccumulatedAssetImpairmentAmount_FinanceComponent]  INTO ##Asset_AssetImpairmentInfo
FROM AssetsValueStatusChanges avsc
INNER JOIN AssetsValueStatusChangeDetails avscd ON avsc.Id = avscd.AssetsValueStatusChangeId
INNER JOIN ##Asset_AssetImpairmentAVHInfo aiavh ON aiavh.AssetId = avscd.AssetId AND aiavh.SourceModuleId = avsc.Id
LEFT JOIN ##Asset_AVHClearedTillDate avhc ON avhc.AssetId = aiavh.AssetId
WHERE avsc.IsActive = 1 AND aiavh.AssetStatus NOT IN ('Leased','InvestorLeased') AND avsc.Reason = 'Impairment'
GROUP BY avscd.AssetId
END;

BEGIN
INSERT INTO ##Asset_AssetImpairmentInfo
SELECT 
	la.AssetId
	,SUM(CASE
		WHEN la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0
		AND avhc.AssetId IS NOT NULL AND aiavh.AVHIncomeDate <= avhc.AVHClearedTillDate AND aiavh.AVHId <= avhc.AVHClearedId
		THEN avscd.AdjustmentAmount_Amount
		ELSE 0.00
		END) AS [ClearedAssetImpairmentAmount_LeaseComponent]
	,SUM(CASE
		WHEN (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1) 
		AND avhc.AssetId IS NOT NULL AND aiavh.AVHIncomeDate <= avhc.AVHClearedTillDate AND aiavh.AVHId <= avhc.AVHClearedId
		THEN avscd.AdjustmentAmount_Amount
		ELSE 0.00
		END) AS [ClearedAssetImpairmentAmount_FinanceComponent]
	,SUM(CASE
		WHEN la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0
		AND aiavh.GLJournalId IS NOT NULL AND aiavh.ReversalGLJournalId IS NULL
		THEN avscd.AdjustmentAmount_Amount
		ELSE 0.00
		END) AS [AccumulatedAssetImpairmentAmount_LeaseComponent]
	,SUM(CASE
		WHEN (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1) 
		AND aiavh.GLJournalId IS NOT NULL AND aiavh.ReversalGLJournalId IS NULL
		THEN avscd.AdjustmentAmount_Amount
		ELSE 0.00
		END) AS [AccumulatedAssetImpairmentAmount_FinanceComponent]
FROM AssetsValueStatusChanges avsc
INNER JOIN AssetsValueStatusChangeDetails avscd ON avsc.Id = avscd.AssetsValueStatusChangeId
INNER JOIN ##Asset_LeaseAssetsInfo la ON avscd.AssetId = la.AssetId
INNER JOIN ##Asset_AssetImpairmentAVHInfo aiavh ON aiavh.AssetId = la.AssetId AND aiavh.SourceModuleId = avsc.Id
LEFT JOIN ##Asset_ContractInfo ci ON la.AssetId = ci.AssetId
LEFT JOIN ##Asset_ReceivableForTransfersInfo rft ON rft.ContractId = ci.ContractId
LEFT JOIN ##Asset_AVHClearedTillDate avhc ON avhc.AssetId = aiavh.AssetId
WHERE avsc.IsActive = 1 AND la.AssetStatus IN ('Leased','InvestorLeased') AND avsc.Reason = 'Impairment'
AND ((rft.ContractId IS NULL) 
		OR (rft.ContractId IS NOT NULL AND rft.ContractType = 'Lease' 
			AND avsc.PostDate <= rft.EffectiveDate))
GROUP BY la.AssetId
END;

CREATE NONCLUSTERED INDEX IX_AssetImpairmentInfo_AssetId ON ##Asset_AssetImpairmentInfo(AssetId);

UPDATE ai
SET ai.AccumulatedAssetImpairmentAmount_LeaseComponent -= ai.ClearedAssetImpairmentAmount_LeaseComponent
	,ai.AccumulatedAssetImpairmentAmount_FinanceComponent -= ai.ClearedAssetImpairmentAmount_FinanceComponent
FROM ##Asset_AssetImpairmentInfo ai
WHERE (ai.ClearedAssetImpairmentAmount_LeaseComponent != 0.00 OR ai.ClearedAssetImpairmentAmount_FinanceComponent != 0.00)

END

GO

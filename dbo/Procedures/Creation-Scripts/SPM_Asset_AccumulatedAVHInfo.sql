SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE   PROC [dbo].[SPM_Asset_AccumulatedAVHInfo]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @IsSku BIT = 0;

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Assets' AND COLUMN_NAME = 'IsSku')
BEGIN
SET @IsSku = 1
END;

CREATE TABLE #Temp_AccumulatedAVHInfo
	(AssetId                                                  BIGINT NOT NULL, 
	 ClearedFixedTermDepreciationAmount_LeaseComponent        DECIMAL(16, 2) NOT NULL, 
	 AccumulatedFixedTermDepreciationAmount_LeaseComponent    DECIMAL(16, 2) NOT NULL, 
	 AccumulatedFixedTermDepreciationAmount_PO_LeaseComponent DECIMAL(16, 2) NOT NULL, 
	 ClearedFixedTermDepreciationAmount_Adj_LeaseComponent    DECIMAL(16, 2) NOT NULL, 
	 ClearedOTPDepreciationAmount_LeaseComponent              DECIMAL(16, 2) NOT NULL, 
	 ClearedOTPDepreciationAmount_FinanceComponent            DECIMAL(16, 2) NOT NULL, 
	 AccumulatedOTPDepreciationAmount_LeaseComponent          DECIMAL(16, 2) NOT NULL, 
	 AccumulatedOTPDepreciationAmount_FinanceComponent        DECIMAL(16, 2) NOT NULL, 
	 AccumulatedOTPDepreciationAmount_PO_LeaseComponent       DECIMAL(16, 2) NOT NULL, 
	 AccumulatedOTPDepreciationAmount_PO_FinanceComponent     DECIMAL(16, 2) NOT NULL, 
	 ClearedOTPDepreciationAmount_Adj_LeaseComponent          DECIMAL(16, 2) NOT NULL, 
	 ClearedOTPDepreciationAmount_Adj_FinanceComponent        DECIMAL(16, 2) NOT NULL, 
	 ClearedNBVImpairmentAmount_LeaseComponent                DECIMAL(16, 2) NOT NULL, 
	 ClearedNBVImpairmentAmount_FinanceComponent              DECIMAL(16, 2) NOT NULL, 
	 AccumulatedNBVImpairmentAmount_LeaseComponent            DECIMAL(16, 2) NOT NULL, 
	 AccumulatedNBVImpairmentAmount_FinanceComponent          DECIMAL(16, 2) NOT NULL, 
	 AccumulatedNBVImpairmentAmount_PO_LeaseComponent         DECIMAL(16, 2) NOT NULL, 
	 AccumulatedNBVImpairmentAmount_PO_FinanceComponent       DECIMAL(16, 2) NOT NULL, 
	 ClearedNBVImpairmentAmount_Adj_LeaseComponent            DECIMAL(16, 2) NOT NULL, 
	 ClearedNBVImpairmentAmount_Adj_FinanceComponent          DECIMAL(16, 2) NOT NULL
);

BEGIN
INSERT INTO #Temp_AccumulatedAVHInfo
SELECT
	ea.AssetId
	,SUM(CASE 
		WHEN avh.SourceModule = 'FixedTermDepreciation' AND sa.AssetId IS NOT NULL AND poa.AssetId IS NULL 
			AND avhc.AssetId IS NOT NULL AND avh.IncomeDate < sa.EffectiveDate
			AND avh.AdjustmentEntry = 0 
			AND (ra.AssetId IS NULL OR (ra.AssetId IS NOT NULL AND avh.IncomeDate > ra.AmendmentDate))
			AND (co.AssetId IS NULL OR (co.AssetId IS NOT NULL AND sa.EffectiveDate > co.ChargeOffDate AND avh.IncomeDate > co.ChargeOffDate))
		THEN CAST((avh.Value_Amount * sa.ParticipatedPortion) AS decimal (16,2)) 
		WHEN avh.SourceModule = 'FixedTermDepreciation' AND sa.AssetId IS NOT NULL AND poa.AssetId IS NOT NULL 
			AND avhc.AssetId IS NOT NULL AND avh.IncomeDate < sa.EffectiveDate 
			AND avh.AdjustmentEntry = 0 
			AND (ra.AssetId IS NULL OR (ra.AssetId IS NOT NULL AND avh.IncomeDate > ra.AmendmentDate))
			AND (co.AssetId IS NULL OR (co.AssetId IS NOT NULL AND sa.EffectiveDate > co.ChargeOffDate AND avh.IncomeDate > co.ChargeOffDate))
		THEN CAST((avh.Value_Amount * sa.ParticipatedPortion) AS decimal (16,2))
		ELSE 0.00
		END)
	+ SUM(CASE 
		WHEN avh.SourceModule = 'FixedTermDepreciation' AND poa.AssetId IS NOT NULL AND sa.AssetId IS NULL
			AND avhc.AssetId IS NOT NULL AND avh.IncomeDate <= avhc.AVHClearedTillDate
			AND avh.AdjustmentEntry = 0 
			AND (ra.AssetId IS NULL OR (ra.AssetId IS NOT NULL AND avh.IncomeDate > ra.AmendmentDate))
			AND (co.AssetId IS NULL OR (co.AssetId IS NOT NULL AND sa.EffectiveDate > co.ChargeOffDate AND avh.IncomeDate > co.ChargeOffDate))
		THEN avh.Value_Amount
		WHEN avh.SourceModule = 'FixedTermDepreciation' AND poa.AssetId IS NOT NULL AND sa.AssetId IS NOT NULL
			AND avhc.AssetId IS NOT NULL AND avh.IncomeDate <= avhc.AVHClearedTillDate
			AND avh.IncomeDate >= sa.EffectiveDate
			AND avh.AdjustmentEntry = 0 
			AND (ra.AssetId IS NULL OR (ra.AssetId IS NOT NULL AND avh.IncomeDate > ra.AmendmentDate))
			AND (co.AssetId IS NULL OR (co.AssetId IS NOT NULL AND sa.EffectiveDate > co.ChargeOffDate AND avh.IncomeDate > co.ChargeOffDate))
		THEN avh.Value_Amount
		ELSE 0.00
		END)
	+ SUM(CASE 
		WHEN avh.SourceModule = 'FixedTermDepreciation' AND poa.AssetId IS NOT NULL AND sa.AssetId IS NOT NULL
			AND avhc.AssetId IS NOT NULL AND avhc.AVHClearedTillDate >= sa.EffectiveDate
			AND avh.IncomeDate < sa.EffectiveDate
			AND avh.AdjustmentEntry = 0 
			AND (ra.AssetId IS NULL OR (ra.AssetId IS NOT NULL AND avh.IncomeDate > ra.AmendmentDate))
			AND (co.AssetId IS NULL OR (co.AssetId IS NOT NULL AND sa.EffectiveDate > co.ChargeOffDate AND avh.IncomeDate > co.ChargeOffDate))
		THEN CAST((avh.Value_Amount * sa.RetainedPortion) AS decimal (16,2))
		ELSE 0.00
		END)
	+ SUM(CASE
		WHEN avh.SourceModule = 'FixedTermDepreciation'
			AND avhc.AssetId IS NOT NULL AND avh.IncomeDate <= cmc.ChargeOffMaxClearedIncomeDate
			AND avh.AdjustmentEntry = 0
			AND co.AssetId IS NOT NULL
		THEN avh.Value_Amount
		ELSE 0.00
	END)
	+ SUM(CASE
		WHEN avh.SourceModule = 'FixedTermDepreciation'
			AND avhc.AssetId IS NOT NULL AND avh.IncomeDate <= ra.AmendmentDate
			AND avh.AdjustmentEntry = 0
			AND ra.AssetId IS NOT NULL
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedFixedTermDepreciationAmount_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'FixedTermDepreciation'
			AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL 
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedFixedTermDepreciationAmount_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'FixedTermDepreciation' AND poa.AssetId IS NOT NULL
			AND avh.IncomeDate <= poa.PayoffEffectiveDate
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedFixedTermDepreciationAmount_PO_LeaseComponent]
	,SUM (CASE
		WHEN avh.SourceModule = 'FixedTermDepreciation'
			AND avh.IncomeDate > poa.PayoffEffectiveDate
			--AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END)
	+ SUM (CASE
		WHEN avh.SourceModule = 'FixedTermDepreciation'	And (avhcF.countfixedterm is not null and avhcF.countfixedterm > 0)
			AND ((poa.AssetId IS NOT NULL AND avh.IncomeDate <= poa.PayoffEffectiveDate AND avh.AdjustmentEntry = 1) 
				OR (poa.AssetId IS NULL AND avh.AdjustmentEntry = 1))
			AND avh.AdjustmentEntry = 1
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedFixedTermDepreciationAmount_Adj_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'OTPDepreciation' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0
			AND avhc.AssetId IS NOT NULL AND avh.IncomeDate <= avhc.AVHClearedTillDate
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedOTPDepreciationAmount_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'OTPDepreciation' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1)
			AND avhc.AssetId IS NOT NULL AND avh.IncomeDate <= avhc.AVHClearedTillDate
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedOTPDepreciationAmount_FinanceComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'OTPDepreciation' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0
			AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL 
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedOTPDepreciationAmount_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'OTPDepreciation' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1)
			AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL 
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedOTPDepreciationAmount_FinanceComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'OTPDepreciation' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0 
			AND poa.AssetId IS NOT NULL AND avh.IncomeDate <= poa.PayoffEffectiveDate
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedOTPDepreciationAmount_PO_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'OTPDepreciation' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1) 
			AND poa.AssetId IS NOT NULL AND avh.IncomeDate <= poa.PayoffEffectiveDate
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedOTPDepreciationAmount_PO_FinanceComponent]
	,SUM (CASE
		WHEN avh.SourceModule = 'OTPDepreciation' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0
			AND avh.IncomeDate > poa.PayoffEffectiveDate
			--AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END)
	+ SUM (CASE
		WHEN avh.SourceModule = 'OTPDepreciation' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0
			And (avhcOTP.CountOTP is not Null and avhcOTP.countOTP > 0)
			AND ((poa.AssetId IS NOT NULL AND avh.IncomeDate <= poa.PayoffEffectiveDate AND avh.AdjustmentEntry = 1) 
				OR (poa.AssetId IS NULL AND avh.AdjustmentEntry = 1))
			AND avh.AdjustmentEntry = 1
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedOTPDepreciationAmount_Adj_LeaseComponent]
	,SUM (CASE
		WHEN avh.SourceModule = 'OTPDepreciation' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1)
			AND avh.IncomeDate > poa.PayoffEffectiveDate
			--AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END)
	+ SUM (CASE
		WHEN avh.SourceModule = 'OTPDepreciation' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1)
			And (avhcOTP.CountOTP is not Null and avhcOTP.countOTP > 0)
			AND ((poa.AssetId IS NOT NULL AND avh.IncomeDate <= poa.PayoffEffectiveDate AND avh.AdjustmentEntry = 1) 
				OR (poa.AssetId IS NULL AND avh.AdjustmentEntry = 1))
			AND avh.AdjustmentEntry = 1
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedOTPDepreciationAmount_Adj_FinanceComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'NBVImpairments' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0
			AND avhc.AssetId IS NOT NULL AND avh.IncomeDate <= avhc.AVHClearedTillDate AND avh.Id <= avhc.AVHClearedId
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedNBVImpairmentAmount_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'NBVImpairments' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1)
			AND avhc.AssetId IS NOT NULL AND avh.IncomeDate <= avhc.AVHClearedTillDate AND avh.Id <= avhc.AVHClearedId
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedNBVImpairmentAmount_FinanceComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'NBVImpairments' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0
			AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL 
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedNBVImpairmentAmount_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'NBVImpairments' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1)
			AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL 
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedNBVImpairmentAmount_FinanceComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'NBVImpairments' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0 
			AND poa.AssetId IS NOT NULL AND avh.IncomeDate <= poa.PayoffEffectiveDate
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedNBVImpairmentAmount_PO_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'NBVImpairments' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1) 
			AND poa.AssetId IS NOT NULL AND avh.IncomeDate <= poa.PayoffEffectiveDate
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedNBVImpairmentAmount_PO_FinanceComponent]
	,SUM (CASE
		WHEN avh.SourceModule = 'NBVImpairments' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0
			AND avh.IncomeDate > poa.PayoffEffectiveDate
			--AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END)
	+ SUM (CASE
		WHEN avh.SourceModule = 'NBVImpairments' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0
			AND ((poa.AssetId IS NOT NULL AND avh.IncomeDate <= poa.PayoffEffectiveDate AND avh.AdjustmentEntry = 1) 
				OR (poa.AssetId IS NULL AND avh.AdjustmentEntry = 1))
			AND avh.AdjustmentEntry = 1
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedNBVImpairmentAmount_Adj_LeaseComponent]
	,SUM (CASE
		WHEN avh.SourceModule = 'NBVImpairments' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1)
			AND avh.IncomeDate > poa.PayoffEffectiveDate
			--AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END)
	+ SUM (CASE
		WHEN avh.SourceModule = 'NBVImpairments' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1)
			AND ((poa.AssetId IS NOT NULL AND avh.IncomeDate <= poa.PayoffEffectiveDate AND avh.AdjustmentEntry = 1) 
				OR (poa.AssetId IS NULL AND avh.AdjustmentEntry = 1))
			AND avh.AdjustmentEntry = 1
		THEN avh.Value_Amount
		ELSE 0.00
	END)  AS [ClearedNBVImpairmentAmount_Adj_FinanceComponent]
FROM 
	##Asset_EligibleAssets ea
INNER JOIN
	AssetValueHistories avh ON avh.AssetId = ea.AssetId
INNER JOIN
	##Asset_AVHAssetsInfo ai ON ai.AssetId = ea.AssetId
LEFT JOIN
	##Asset_AVHClearedTillDate avhc ON avhc.AssetId = ea.AssetId
LEFT JOIN
	##Asset_AVHClearedTillDateFixedTerm avhcF ON avhcF.AssetId = ea.AssetId
LEFT JOIN
	##Asset_AVHClearedTillDateOTP avhcOTP ON avhcOTP.AssetId = ea.AssetId 
LEFT JOIN
	##Asset_PayoffAssetInfo poa ON poa.AssetId = ea.AssetId
LEFT JOIN
	##Asset_SyndicatedAssets sa ON sa.AssetId = ea.AssetId
LEFT JOIN
	##Asset_ChargeOffAssetsInfo co ON co.AssetId = ea.AssetId
LEFT JOIN
	##Asset_ChargeOffMaxCleared cmc ON cmc.AssetId = ea.AssetId
LEFT JOIN
	##Asset_RenewedAssets ra ON ra.AssetId = ea.AssetId
WHERE 
	avh.IsAccounted = 1 AND avh.IsLessorOwned = 1 AND ea.IsSKU = 0
	AND avh.SourceModule IN ('NBVImpairments','FixedTermDepreciation','OTPDepreciation')
GROUP BY 
	ea.AssetId
END;


----------- FOR SKU=1 --------------


IF @IsSku = 1
BEGIN
INSERT INTO #Temp_AccumulatedAVHInfo
SELECT
	ea.AssetId
	,SUM(CASE
		WHEN avh.SourceModule = 'FixedTermDepreciation'
			AND avhc.AssetId IS NOT NULL AND avh.IncomeDate <= avhc.AVHClearedTillDate
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedFixedTermDepreciationAmount_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'FixedTermDepreciation'
			AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL 
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedFixedTermDepreciationAmount_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'FixedTermDepreciation' AND poa.AssetId IS NOT NULL
			AND avh.IncomeDate <= poa.PayoffEffectiveDate
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedFixedTermDepreciationAmount_PO_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'FixedTermDepreciation'
			AND avh.IncomeDate > poa.PayoffEffectiveDate
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END)
	+ SUM (CASE
		WHEN avh.SourceModule = 'FixedTermDepreciation' And (avhcF.countfixedterm is not null and avhcF.countfixedterm > 0)
			AND ((poa.AssetId IS NOT NULL AND avh.IncomeDate <= poa.PayoffEffectiveDate AND avh.AdjustmentEntry = 1) 
				OR (poa.AssetId IS NULL AND avh.AdjustmentEntry = 1))
			AND avh.AdjustmentEntry = 1
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedFixedTermDepreciationAmount_Adj_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'OTPDepreciation' AND avh.IsLeaseComponent = 1 AND ai.IsFailedSaleLeaseback = 0
			AND avhc.AssetId IS NOT NULL AND avh.IncomeDate <= avhc.AVHClearedTillDate AND avh.Id <= avhc.AVHClearedId
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedOTPDepreciationAmount_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'OTPDepreciation' AND (avh.IsLeaseComponent = 0 OR ai.IsFailedSaleLeaseback = 1)
			AND avhc.AssetId IS NOT NULL AND avh.IncomeDate <= avhc.AVHClearedTillDate AND avh.Id <= avhc.AVHClearedId
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedOTPDepreciationAmount_FinanceComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'OTPDepreciation' AND avh.IsLeaseComponent = 1 AND ai.IsFailedSaleLeaseback = 0
			AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL 
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedOTPDepreciationAmount_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'OTPDepreciation' AND (avh.IsLeaseComponent = 0 OR ai.IsFailedSaleLeaseback = 1)
			AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL 
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedOTPDepreciationAmount_FinanceComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'OTPDepreciation' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0 
			AND poa.AssetId IS NOT NULL AND avh.IncomeDate <= poa.PayoffEffectiveDate
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedOTPDepreciationAmount_PO_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'OTPDepreciation' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1) 
			AND poa.AssetId IS NOT NULL AND avh.IncomeDate <= poa.PayoffEffectiveDate
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedOTPDepreciationAmount_PO_FinanceComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'OTPDepreciation' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0
			AND avh.IncomeDate > poa.PayoffEffectiveDate
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END)
	+ SUM (CASE
		WHEN avh.SourceModule = 'OTPDepreciation' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0
			And (avhcOTP.CountOTP is not Null and avhcOTP.countOTP > 0)
			AND ((poa.AssetId IS NOT NULL AND avh.IncomeDate <= poa.PayoffEffectiveDate AND avh.AdjustmentEntry = 1) 
				OR (poa.AssetId IS NULL AND avh.AdjustmentEntry = 1))
			AND avh.AdjustmentEntry = 1
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedOTPDepreciationAmount_Adj_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'OTPDepreciation' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1)
			AND avh.IncomeDate > poa.PayoffEffectiveDate
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END)
	+ SUM (CASE
		WHEN avh.SourceModule = 'OTPDepreciation' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1)
			And (avhcOTP.CountOTP is not Null and avhcOTP.countOTP > 0)
			AND ((poa.AssetId IS NOT NULL AND avh.IncomeDate <= poa.PayoffEffectiveDate AND avh.AdjustmentEntry = 1) 
				OR (poa.AssetId IS NULL AND avh.AdjustmentEntry = 1))
			AND avh.AdjustmentEntry = 1
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedOTPDepreciationAmount_Adj_FinanceComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'NBVImpairments' AND avh.IsLeaseComponent = 1 AND ai.IsFailedSaleLeaseback = 0
			AND avhc.AssetId IS NOT NULL AND avh.IncomeDate <= avhc.AVHClearedTillDate AND avh.Id <= avhc.AVHClearedId
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedNBVImpairmentAmount_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'NBVImpairments' AND (avh.IsLeaseComponent = 0 OR ai.IsFailedSaleLeaseback = 1)
			AND avhc.AssetId IS NOT NULL AND avh.IncomeDate <= avhc.AVHClearedTillDate AND avh.Id <= avhc.AVHClearedId
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedNBVImpairmentAmount_FinanceComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'NBVImpairments' AND avh.IsLeaseComponent = 1 AND ai.IsFailedSaleLeaseback = 0
			AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL 
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedNBVImpairmentAmount_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'NBVImpairments' AND (avh.IsLeaseComponent = 0 OR ai.IsFailedSaleLeaseback = 1)
			AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL 
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedNBVImpairmentAmount_FinanceComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'NBVImpairments' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0 
			AND poa.AssetId IS NOT NULL AND avh.IncomeDate <= poa.PayoffEffectiveDate
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedNBVImpairmentAmount_PO_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'NBVImpairments' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1) 
			AND poa.AssetId IS NOT NULL AND avh.IncomeDate <= poa.PayoffEffectiveDate
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedNBVImpairmentAmount_PO_FinanceComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'NBVImpairments' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0
			AND avh.IncomeDate > poa.PayoffEffectiveDate
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END)
	+ SUM (CASE
		WHEN avh.SourceModule = 'NBVImpairments' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0
			AND ((poa.AssetId IS NOT NULL AND avh.IncomeDate <= poa.PayoffEffectiveDate AND avh.AdjustmentEntry = 1) 
				OR (poa.AssetId IS NULL AND avh.AdjustmentEntry = 1))
			AND avh.AdjustmentEntry = 1
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedNBVImpairmentAmount_Adj_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'NBVImpairments' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1)
			AND avh.IncomeDate > poa.PayoffEffectiveDate
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END)
	+ SUM (CASE
		WHEN avh.SourceModule = 'NBVImpairments' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1)
			AND ((poa.AssetId IS NOT NULL AND avh.IncomeDate <= poa.PayoffEffectiveDate AND avh.AdjustmentEntry = 1) 
				OR (poa.AssetId IS NULL AND avh.AdjustmentEntry = 1))
			AND avh.AdjustmentEntry = 1
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedNBVImpairmentAmount_Adj_FinanceComponent]
FROM 
	##Asset_EligibleAssets ea
INNER JOIN
	AssetValueHistories avh ON avh.AssetId = ea.AssetId
INNER JOIN 
	##Asset_AVHAssetsInfo ai ON ai.AssetId = ea.AssetId
LEFT JOIN
	##Asset_SKUAVHClearedTillDate avhc ON avhc.AssetId = ea.AssetId
	AND avhc.IsLeaseComponent = avh.IsLeaseComponent
LEFT JOIN
	##Asset_AVHClearedTillDateFixedTerm	avhcF ON avhcF.AssetId = ea.AssetId
LEFT JOIN
	##Asset_AVHClearedTillDateOTP avhcOTP ON avhcOTP.AssetId = ea.AssetId
LEFT JOIN
	##Asset_PayoffAssetInfo poa ON poa.AssetId = ea.AssetId
WHERE
	avh.IsAccounted = 1 AND avh.IsLessorOwned = 1 AND ea.IsSKU = 1
	AND avh.SourceModule IN ('NBVImpairments','FixedTermDepreciation','OTPDepreciation')
GROUP BY
	ea.AssetId
END;

UPDATE a
SET a.ClearedFixedTermDepreciationAmount_LeaseComponent += a.ClearedFixedTermDepreciationAmount_Adj_LeaseComponent
	,a.AccumulatedFixedTermDepreciationAmount_PO_LeaseComponent += a.ClearedFixedTermDepreciationAmount_Adj_LeaseComponent
	,a.ClearedOTPDepreciationAmount_LeaseComponent += a.ClearedOTPDepreciationAmount_Adj_LeaseComponent
	,a.ClearedOTPDepreciationAmount_FinanceComponent += a.ClearedOTPDepreciationAmount_Adj_FinanceComponent
	,a.AccumulatedOTPDepreciationAmount_PO_LeaseComponent += a.ClearedOTPDepreciationAmount_Adj_LeaseComponent
	,a.AccumulatedOTPDepreciationAmount_FinanceComponent += a.ClearedOTPDepreciationAmount_Adj_FinanceComponent
	,a.ClearedNBVImpairmentAmount_LeaseComponent += a.ClearedNBVImpairmentAmount_Adj_LeaseComponent
	,a.ClearedNBVImpairmentAmount_FinanceComponent += a.ClearedNBVImpairmentAmount_Adj_FinanceComponent
	,a.AccumulatedNBVImpairmentAmount_LeaseComponent += a.ClearedNBVImpairmentAmount_Adj_LeaseComponent
	,a.AccumulatedNBVImpairmentAmount_FinanceComponent += a.ClearedNBVImpairmentAmount_Adj_FinanceComponent
FROM
	#Temp_AccumulatedAVHInfo a

UPDATE a
SET a.AccumulatedFixedTermDepreciationAmount_LeaseComponent =
		CASE 
			WHEN poa.AssetId IS NOT NULL 
			THEN a.AccumulatedFixedTermDepreciationAmount_LeaseComponent - a.AccumulatedFixedTermDepreciationAmount_PO_LeaseComponent
			ELSE a.AccumulatedFixedTermDepreciationAmount_LeaseComponent - a.ClearedFixedTermDepreciationAmount_LeaseComponent
		END
	,a.AccumulatedOTPDepreciationAmount_LeaseComponent = 
		CASE
			WHEN poa.AssetId IS NOT NULL 
			THEN a.AccumulatedOTPDepreciationAmount_LeaseComponent - a.AccumulatedOTPDepreciationAmount_PO_LeaseComponent
			ELSE a.AccumulatedOTPDepreciationAmount_LeaseComponent - a.ClearedOTPDepreciationAmount_LeaseComponent
		END
	,a.AccumulatedOTPDepreciationAmount_FinanceComponent =  
		CASE
			WHEN poa.AssetId IS NOT NULL
			THEN a.AccumulatedOTPDepreciationAmount_FinanceComponent - a.AccumulatedOTPDepreciationAmount_PO_FinanceComponent
			ELSE a.AccumulatedOTPDepreciationAmount_FinanceComponent - a.ClearedOTPDepreciationAmount_FinanceComponent
		END
	,a.AccumulatedNBVImpairmentAmount_LeaseComponent =  
		CASE 
			WHEN poa.AssetId IS NOT NULL
			THEN a.AccumulatedNBVImpairmentAmount_LeaseComponent - a.AccumulatedNBVImpairmentAmount_PO_LeaseComponent
			ELSE a.AccumulatedNBVImpairmentAmount_LeaseComponent - a.ClearedNBVImpairmentAmount_LeaseComponent
		END
	,a.AccumulatedNBVImpairmentAmount_FinanceComponent =  
		CASE
			WHEN poa.AssetId IS NOT NULL
			THEN a.AccumulatedNBVImpairmentAmount_FinanceComponent - a.AccumulatedNBVImpairmentAmount_PO_FinanceComponent
			ELSE a.AccumulatedNBVImpairmentAmount_FinanceComponent - a.ClearedNBVImpairmentAmount_FinanceComponent
		END
FROM 
	#Temp_AccumulatedAVHInfo a
LEFT JOIN
	##Asset_PayoffAssetInfo poa on a.AssetId = poa.AssetId

UPDATE ai
	SET ai.AccumulatedFixedTermDepreciationAmount_LeaseComponent = 0.00
		,ai.AccumulatedOTPDepreciationAmount_LeaseComponent += ai.AccumulatedFixedTermDepreciationAmount_LeaseComponent
FROM 
	#Temp_AccumulatedAVHInfo ai
INNER JOIN
	LeaseAssets la ON ai.AssetId = la.AssetId
INNER JOIN
	LeaseFinances lf ON la.LeaseFinanceId = lf.Id
INNER JOIN
	LeaseFinanceDetails lfd ON lf.Id = lfd.Id
LEFT JOIN
	##Asset_OTPReclass otpr ON ai.AssetId = otpr.AssetId
WHERE 
	(otpr.AssetId IS NOT NULL 
	OR (otpr.AssetId IS NULL AND la.IsActive = 0 AND la.TerminationDate > lfd.MaturityDate AND lf.BookingStatus != 'InActive'))

UPDATE a
SET a.AccumulatedFixedTermDepreciationAmount_LeaseComponent = 0.00
	,a.AccumulatedOTPDepreciationAmount_LeaseComponent = 0.00
	,a.AccumulatedOTPDepreciationAmount_FinanceComponent = 0.00 
	,a.AccumulatedNBVImpairmentAmount_LeaseComponent = 0.00
	,a.AccumulatedNBVImpairmentAmount_FinanceComponent = 0.00
FROM
	#Temp_AccumulatedAVHInfo a
INNER JOIN
	##Asset_ChargeOffAssetsInfo co ON a.AssetId = co.AssetId

SELECT * INTO ##Asset_AccumulatedAVHInfo FROM #Temp_AccumulatedAVHInfo

CREATE NONCLUSTERED INDEX IX_AccumulatedAVHInfo_AssetId ON ##Asset_AccumulatedAVHInfo(AssetId);  

END

GO

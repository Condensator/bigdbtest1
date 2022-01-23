SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Asset_ActualValueCalculation]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @IsSku BIT = 0;

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Assets' AND COLUMN_NAME = 'IsSku')
BEGIN
SET @IsSku = 1
END;

BEGIN
SELECT 
	 ea.AssetId
	,ISNULL(avh.EndBookValue_Amount,0.00) AS ActualValue  INTO ##Asset_ActualValueCalculation
FROM 
	##Asset_EligibleAssets ea
INNER JOIN
	AssetValueHistories avh ON ea.AssetId = avh.AssetId
INNER JOIN
	##Asset_AVHClearedTillDate avhc ON ea.AssetId = avhc.AssetId
WHERE
	avh.IsAccounted = 1 AND avh.IsLessorOwned = 1 AND ea.IsSKU = 0
	AND avh.IncomeDate = avhc.AVHClearedTillDate AND avh.Id = avhc.AVHClearedId
END

If @IsSku = 1
BEGIN
INSERT INTO ##Asset_ActualValueCalculation
SELECT 
	 ea.AssetId
	,ISNULL(SUM(avh.EndBookValue_Amount),0.00) AS ActualValue
FROM 
	##Asset_EligibleAssets ea
INNER JOIN
	AssetValueHistories avh ON ea.AssetId = avh.AssetId
INNER JOIN
	##Asset_SKUAVHClearedTillDate savhc ON ea.AssetId = savhc.AssetId
WHERE
	avh.IsAccounted = 1 AND avh.IsLessorOwned = 1 AND ea.IsSKU = 1
	AND avh.IncomeDate = savhc.AVHClearedTillDate AND avh.Id = savhc.AVHClearedId
	AND avh.IsLeaseComponent = savhc.IsLeaseComponent
GROUP BY
	ea.AssetId
END

CREATE NONCLUSTERED INDEX IX_ActualValueCalculation_AssetId ON ##Asset_ActualValueCalculation(AssetId);

UPDATE avc
	SET avc.ActualValue += (syn.SyndicationValueAmount_LeaseComponent + syn.SyndicationValueAmount_FinanceComponent)
FROM
	##Asset_EligibleAssets ea
INNER JOIN
	##Asset_ActualValueCalculation avc ON avc.AssetId = ea.AssetId
INNER JOIN
	##Asset_SyndicationAmountInfo syn ON avc.AssetId = syn.AssetId
INNER JOIN
	LeaseAssets la ON avc.AssetId = la.AssetId
INNER JOIN
	LeaseFinances lf ON la.LeaseFinanceId = lf.Id
INNER JOIN
	LeaseFinanceDetails lfd ON lfd.Id = lf.Id
INNER JOIN
	##Asset_ReceivableForTransfersInfo rft ON rft.ContractId = lf.ContractId
WHERE
	lfd.LeaseContractType != 'Operating' AND lf.IsCurrent = 1
	AND ((rft.ReceivableForTransferType != 'FullSale'AND la.TerminationDate IS NULL) OR rft.ReceivableForTransferType = 'FullSale')
	AND ea.IsSKU = 0;


UPDATE avc
	SET avc.ActualValue += t.ResidualRecaptureAmount
FROM
	##Asset_ActualValueCalculation avc
INNER JOIN
	(
	SELECT 
		ea.AssetId,SUM(avh.Value_Amount) AS ResidualRecaptureAmount
	FROM
		##Asset_EligibleAssets ea
	INNER JOIN
		AssetValueHistories avh ON ea.AssetId = avh.AssetId
	INNER JOIN
		(SELECT 
			avh.AssetId,avh.SourceModuleId,avhc.AVHClearedId
		FROM
			AssetValueHistories avh
		INNER JOIN
			##Asset_AVHClearedTillDate avhc ON avh.AssetId = avhc.AssetId AND avh.Id = avhc.AVHClearedId
		WHERE
			(avh.SourceModule = 'ResidualReclass' OR avh.SourceModule = 'ResidualRecapture')) AS rmc ON avh.AssetId = rmc.AssetId
	WHERE 
		avh.SourceModule = 'ResidualRecapture'
		AND avh.Id > rmc.AVHClearedId AND avh.IsAccounted = 1
		AND avh.IsLessorOwned = 1 AND avh.SourceModuleId = rmc.SourceModuleId
		AND ea.AssetStatus NOT IN ('Leased','InvestorLeased') AND ea.IsSKU = 0
	GROUP BY
		ea.AssetId) AS t ON t.AssetId = avc.AssetId

IF @IsSKU = 1
BEGIN
UPDATE avc
	SET avc.ActualValue += t.ResidualRecaptureAmount
FROM
	##Asset_ActualValueCalculation avc
INNER JOIN
	(
	SELECT
		ea.AssetId,SUM(avh.Value_Amount) AS ResidualRecaptureAmount
	FROM
		##Asset_EligibleAssets ea
	INNER JOIN
		AssetValueHistories avh ON ea.AssetId = avh.AssetId
	INNER JOIN
		(SELECT
			avh.AssetId,avh.SourceModuleId,avhc.AVHClearedId,avh.IsLeaseComponent
		FROM
			AssetValueHistories avh
		INNER JOIN
			##Asset_SKUAVHClearedTillDate avhc ON avh.AssetId = avhc.AssetId 
			AND avh.Id = avhc.AVHClearedId AND avhc.IsLeaseComponent = avh.IsLeaseComponent
		WHERE
			(avh.SourceModule = 'ResidualReclass' OR avh.SourceModule = 'ResidualRecapture')) AS rmc ON avh.AssetId = rmc.AssetId
	WHERE
		avh.SourceModule = 'ResidualRecapture' AND avh.IsLeaseComponent = rmc.IsLeaseComponent
		AND avh.Id > rmc.AVHClearedId AND avh.IsAccounted = 1
		AND avh.IsLessorOwned = 1 AND avh.SourceModuleId = rmc.SourceModuleId
		AND ea.AssetStatus NOT IN ('Leased','InvestorLeased') AND ea.IsSKU = 1
	GROUP BY
		ea.AssetId) AS t ON t.AssetId = avc.AssetId
END

UPDATE avc
	SET avc.ActualValue = 0.00
FROM
	##Asset_EligibleAssets ea
INNER JOIN
	##Asset_ActualValueCalculation avc ON ea.AssetId = avc.AssetId
LEFT JOIN
	##Asset_CapitalizedSoftAssetInfo coa ON ea.AssetId = coa.AssetId
LEFT JOIN
	##Asset_EligibleAssets cea ON coa.SoftAssetCapitalizedFor = cea.AssetId
LEFT JOIN
	##Asset_PayoffAtInceptionSoftAssets pos ON pos.AssetId = ea.AssetId
WHERE
	ea.AssetStatus = 'Sold' OR (coa.AssetId IS NOT NULL AND ea.AssetStatus = 'Scrap' AND pos.AssetId IS NOT NULL)

----

UPDATE avc
	SET avc.ActualValue -= t.PayableInvoiceAmount
FROM
	##Asset_ActualValueCalculation avc
INNER JOIN 
	(SELECT
		 ea.AssetId
		,SUM(avh.Value_Amount) PayableInvoiceAmount
	FROM 
		##Asset_EligibleAssets ea
	INNER JOIN
		AssetValueHistories avh ON ea.AssetId = avh.AssetId
	INNER JOIN
		##Asset_NotGLPostedPIInfo ngl ON ngl.AssetId = avh.AssetId AND avh.SourceModuleId = ngl.EntityId
	WHERE
		avh.SourceModule = 'PayableInvoice' AND avh.IsAccounted = 1 AND avh.IsLessorOwned = 1
	GROUP BY
		ea.AssetId) AS t ON avc.AssetId = t.AssetId;

UPDATE avc
	SET avc.ActualValue += t.SyndicationAmount
FROM
	##Asset_ActualValueCalculation avc
INNER JOIN
	(SELECT
		ea.AssetId
		,SUM(avh.Value_Amount) SyndicationAmount
	FROM
		##Asset_EligibleAssets ea
	INNER JOIN
		AssetValueHistories avh ON ea.AssetId = avh.AssetId
	INNER JOIN
		##Asset_AVHClearedTillDate avhc ON avhc.AssetId = avh.AssetId
	WHERE
		avh.SourceModule = 'Syndications' AND avh.IsAccounted = 1 AND avh.IsLessorOwned = 1
		AND avh.IncomeDate >= avhc.AVHClearedTillDate AND avh.Id > avhc.AVHClearedId
	GROUP BY 
		ea.AssetId) AS t ON avc.AssetId = t.AssetId;

UPDATE avc
	SET avc.ActualValue += (rai.RenewalAmortizedAmount_LeaseComponent + rai.RenewalAmortizedAmount_FinanceComponent)
FROM
	##Asset_ActualValueCalculation avc
INNER JOIN
	##Asset_RenewalAmortizeInfo rai ON avc.AssetId = rai.AssetId
LEFT JOIN
	##Asset_PayoffAssetInfo pai ON avc.AssetId = pai.AssetId
WHERE
	pai.AssetId IS NULL;

UPDATE avc
	SET avc.ActualValue -= avh.Value_Amount
FROM
	##Asset_EligibleAssets ea
INNER JOIN
	##Asset_ActualValueCalculation avc ON ea.AssetId = avc.AssetId
INNER JOIN
	##Asset_AVHClearedTillDate avhc ON avhc.AssetId = avc.AssetId
INNER JOIN
	AssetValueHistories avh ON avh.Id = avhc.AVHClearedId
WHERE
	(avh.SourceModule = 'ResidualReclass' OR avh.SourceModule = 'ResidualRecapture')
	AND avh.GLJournalId IS NULL AND ea.IsSKU = 0
	AND ea.AssetStatus IN ('Leased','InvestorLeased');

IF @IsSKU = 1
BEGIN
UPDATE avc
	SET avc.ActualValue -= t.Value_Amount
FROM
	##Asset_EligibleAssets ea
INNER JOIN
	##Asset_ActualValueCalculation avc ON ea.AssetId = avc.AssetId
INNER JOIN
	(SELECT
		avhc.AssetId,
		SUM(avh.Value_Amount) AS Value_Amount
	FROM 
		##Asset_SKUAVHClearedTillDate avhc
	INNER JOIN
		AssetValueHistories avh ON avh.Id = avhc.AVHClearedId AND avhc.AssetId = avh.AssetId
	WHERE
		(avh.SourceModule = 'ResidualReclass' OR avh.SourceModule = 'ResidualRecapture')
		 AND avh.GLJournalId IS NULL AND avhc.IsLeaseComponent = avh.IsLeaseComponent
	GROUP BY
		avhc.AssetId) AS t ON t.AssetId = ea.AssetId
		AND ea.AssetStatus IN ('Leased','InvestorLeased') AND ea.IsSKU = 1
END

UPDATE avc
	SET avc.ActualValue -= t.RetainedAmount
FROM
	##Asset_ActualValueCalculation avc
INNER JOIN
	(SELECT
		ea.AssetId
		,SUM(CAST((avh.Value_Amount * sa.RetainedPortion) AS decimal (16,2))) RetainedAmount
	FROM
		##Asset_EligibleAssets ea
	INNER JOIN
		AssetValueHistories avh ON avh.AssetId = ea.AssetId
	INNER JOIN
		##Asset_SyndicatedAssets sa ON sa.AssetId = ea.AssetId
	LEFT JOIN
		##Asset_ChargeOffAssetsInfo co ON co.AssetId = ea.AssetId
	WHERE
		avh.IsAccounted = 1 AND avh.IsLessorOwned = 1 AND ea.IsSKU = 0
		AND avh.SourceModule IN ('FixedTermDepreciation') AND co.AssetId IS NULL
		AND avh.IncomeDate < sa.EffectiveDate AND avh.AdjustmentEntry = 0
	GROUP BY
		ea.AssetId) AS t ON avc.AssetId = t.AssetId

END

GO

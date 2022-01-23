SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[InsertManualTaxAssetLocationDetails]
(
	@TaxAssessmentAsset		NVARCHAR(50),
	@TaxAssessmentCustomer	NVARCHAR(50),
	@JobStepInstanceId		BIGINT,
	@ReceivableTaxTypeSalesTax	NVARCHAR(20)
)
AS
BEGIN
SET NOCOUNT ON

--To Find out the asset id which is tax assessed separtely

SELECT 
	RD.ReceivableDetailId,
	RD.ReceivableDueDate,
	RD.AssetId,
	RD.ContractId,
	RD.JobStepInstanceId,
	RD.AdjustmentBasisReceivableDetailId,
	RD.IsOriginalReceivableDetailTaxAssessed,
	RD.CustomerId
INTO #SalesTaxReceivableDetail_ExtractTemp
FROM SalesTaxReceivableDetailExtract RD
WHERE (RD.AdjustmentBasisReceivableDetailId IS NULL OR RD.IsOriginalReceivableDetailTaxAssessed = 0)
	AND RD.JobStepInstanceId = @JobStepInstanceId AND RD.ReceivableTaxType = @ReceivableTaxTypeSalesTax

SELECT 
	RD.ReceivableDetailId,
	RD.ReceivableDueDate,
	RD.AssetId,
	STA.CapitalizedOriginalAssetId,
	RD.ContractId,
	RD.JobStepInstanceId,
	RD.AdjustmentBasisReceivableDetailId,
	RD.IsOriginalReceivableDetailTaxAssessed,
	RD.CustomerId
INTO #SalesTaxReceivableDetail_ExtractTempWithoutCapitalizeAsset
FROM SalesTaxAssetDetailExtract STA
	INNER JOIN SalesTaxReceivableDetailExtract RD ON STA.AssetId = RD.AssetId  
		AND STA.JobStepInstanceId = RD.JobStepInstanceId AND RD.ReceivableTaxType = @ReceivableTaxTypeSalesTax
		AND STA.ContractId = RD.ContractId AND STA.JobStepInstanceId = RD.JobStepInstanceId AND STA.JobStepInstanceId = @JobStepInstanceId
	LEFT JOIN SalesTaxReceivableDetailExtract CRD ON STA.CapitalizedOriginalAssetId = CRD.AssetId 
		AND STA.ContractId = CRD.ContractId AND STA.JobStepInstanceId = CRD.JobStepInstanceId AND RD.ReceivableCodeId = CRD.ReceivableCodeId
WHERE CRD.AssetId IS NULL AND STA.JobStepInstanceId = @JobStepInstanceId
	AND (RD.AdjustmentBasisReceivableDetailId IS NULL OR RD.IsOriginalReceivableDetailTaxAssessed = 0);

--To find out the source captalize asset is already tax assessed.

SELECT 
	DISTINCT
	RD.ReceivableDetailId,
	RD.JobStepInstanceId,
	RD.AssetId,
	STA.CapitalizedOriginalAssetId,
	RTD.TaxBasisType
INTO #SalesTaxReceivableDetail_ExtractTempWithoutCapitalizeAssetFromReceivableTaxDetail
FROM SalesTaxAssetDetailExtract STA
	INNER JOIN SalesTaxReceivableDetailExtract RD ON STA.AssetId = RD.AssetId 
		AND STA.ContractId = RD.ContractId AND STA.JobStepInstanceId = RD.JobStepInstanceId AND STA.JobStepInstanceId = @JobStepInstanceId
	INNER JOIN ReceivableTaxDetails RTD ON STA.CapitalizedOriginalAssetId = RTD.AssetId AND RTD.IsActive = 1
	INNER JOIN ReceivableDetails RDS ON RDS.AssetId = STA.CapitalizedOriginalAssetId AND RTD.ReceivableDetailId = RDS.Id AND RDS.IsActive = 1
	INNER JOIN Receivables R ON RDS.ReceivableId = R.Id AND R.DueDate = RD.ReceivableDueDate AND R.ReceivableCodeId = RD.ReceivableCodeId
WHERE STA.JobStepInstanceId = @JobStepInstanceId AND RD.ReceivableTaxType = @ReceivableTaxTypeSalesTax;

-- populate #SalesTaxReceivableDetail_ExtractTemp

INSERT INTO #SalesTaxReceivableDetail_ExtractTemp
SELECT
	(-1) * STRWC.ReceivableDetailId ReceivableDetailId,
	STRWC.ReceivableDueDate,
	STRWC.CapitalizedOriginalAssetId AssetId,
	STRWC.ContractId,
	STRWC.JobStepInstanceId,
	STRWC.AdjustmentBasisReceivableDetailId,
	STRWC.IsOriginalReceivableDetailTaxAssessed,
	STRWC.CustomerId
FROM #SalesTaxReceivableDetail_ExtractTempWithoutCapitalizeAsset STRWC
	LEFT JOIN #SalesTaxReceivableDetail_ExtractTempWithoutCapitalizeAssetFromReceivableTaxDetail STRWCRT ON STRWC.ReceivableDetailId = STRWCRT.ReceivableDetailId AND STRWC.AssetId = STRWCRT.AssetId
WHERE STRWCRT.ReceivableDetailId IS NULL;

-- Contract Based Receivables with Tax Assessment Level as Asset
SELECT
	AL.AssetId,
	RD.ReceivableDetailId,
	RD.ReceivableDueDate AS DueDate,
	AL.EffectiveFromDate AS EffectiveFromDate,
	AL.Id AS AssetLocationId,
	AL.LocationId
INTO #AssetLocationHistory
FROM #SalesTaxReceivableDetail_ExtractTemp RD
	INNER JOIN Contracts C ON RD.ContractId = C.Id AND RD.JobStepInstanceId = @JobStepInstanceId
	INNER JOIN AssetLocations AL ON AL.AssetId = RD.AssetId AND AL.IsActive = 1
	INNER JOIN Locations L ON AL.LocationId = L.Id AND RD.CustomerId = L.CustomerId
WHERE C.TaxAssessmentLevel= @TaxAssessmentAsset
	AND (RD.AdjustmentBasisReceivableDetailId IS NULL OR RD.IsOriginalReceivableDetailTaxAssessed = 0);


INSERT INTO #AssetLocationHistory (AssetId,ReceivableDetailId, DueDate, EffectiveFromDate, AssetLocationId, LocationId)
SELECT
	AL.AssetId,
	RD.ReceivableDetailId,
	RD.ReceivableDueDate AS DueDate,
	AL.EffectiveFromDate AS EffectiveFromDate,
	AL.Id AS AssetLocationId,
	AL.LocationId
FROM #SalesTaxReceivableDetail_ExtractTemp RD
	INNER JOIN Contracts C ON RD.ContractId = C.Id AND RD.JobStepInstanceId = @JobStepInstanceId
	INNER JOIN AssetLocations AL ON AL.AssetId = RD.AssetId AND AL.IsActive = 1
	INNER JOIN Locations L ON AL.LocationId = L.Id AND L.CustomerId IS NULL
WHERE C.TaxAssessmentLevel=@TaxAssessmentAsset
	AND (RD.AdjustmentBasisReceivableDetailId IS NULL OR RD.IsOriginalReceivableDetailTaxAssessed = 0);

-- Customer Based Receivables
INSERT INTO #AssetLocationHistory (AssetId,ReceivableDetailId, DueDate, EffectiveFromDate, AssetLocationId, LocationId)
SELECT
	AL.AssetId,
	RD.ReceivableDetailId,
	RD.ReceivableDueDate AS DueDate,
	AL.EffectiveFromDate AS EffectiveFromDate,
	AL.Id AS AssetLocationId,
	AL.LocationId
FROM #SalesTaxReceivableDetail_ExtractTemp RD
	INNER JOIN AssetLocations AL ON AL.AssetId = RD.AssetId AND AL.IsActive = 1
	INNER JOIN Locations L ON AL.LocationId = L.Id AND RD.CustomerId = L.CustomerId
WHERE RD.ContractId IS NULL AND RD.JobStepInstanceId = @JobStepInstanceId
	AND (RD.AdjustmentBasisReceivableDetailId IS NULL OR RD.IsOriginalReceivableDetailTaxAssessed = 0);

INSERT INTO #AssetLocationHistory (AssetId,ReceivableDetailId, DueDate, EffectiveFromDate, AssetLocationId, LocationId)
SELECT
	AL.AssetId,
	RD.ReceivableDetailId,
	RD.ReceivableDueDate AS DueDate,
	AL.EffectiveFromDate AS EffectiveFromDate,
	AL.Id AS AssetLocationId,
	AL.LocationId
FROM #SalesTaxReceivableDetail_ExtractTemp RD
	INNER JOIN AssetLocations AL ON AL.AssetId = RD.AssetId AND AL.IsActive = 1
	INNER JOIN Locations L ON AL.LocationId = L.Id AND L.CustomerId IS NULL
WHERE RD.ContractId IS NULL AND RD.JobStepInstanceId = @JobStepInstanceId
	AND (RD.AdjustmentBasisReceivableDetailId IS NULL OR RD.IsOriginalReceivableDetailTaxAssessed = 0);

-- Neareset location effective from date in the past
SELECT
	AL.AssetId,
	AL.DueDate,
	MAX(AL.EffectiveFromDate) AS EffectiveFromDate,
	1 AS IsPastLocation
INTO #AssetNearestLocationEffectiveDate
FROM  #AssetLocationHistory AL
WHERE AL.EffectiveFromDate <= AL.DueDate
GROUP BY 
	AL.AssetId,
	AL.DueDate;

-- Neareset location effective from date in the future when no record found in past
INSERT INTO #AssetNearestLocationEffectiveDate
SELECT
	AL.AssetId,
	AL.DueDate,
	MIN(AL.EffectiveFromDate) AS EffectiveFromDate,
	0 AS IsPastLocation
FROM #AssetLocationHistory AL
LEFT JOIN #AssetNearestLocationEffectiveDate STLA ON AL.AssetId = STLA.AssetId AND AL.DueDate = STLA.DueDate
WHERE  STLA.AssetId IS NULL AND AL.EffectiveFromDate > AL.DueDate
GROUP BY 
	AL.AssetId,
	AL.DueDate;

-- Nearest location
SELECT
	ALE.AssetId,
	ALH.ReceivableDetailId,
	ALE.DueDate,
	ALE.EffectiveFromDate,
	MAX(ALH.AssetLocationId) AssetLocationId
INTO #AssetNearestLocation
FROM #AssetNearestLocationEffectiveDate AS ALE
	INNER JOIN #AssetLocationHistory ALH ON ALE.DueDate = ALH.DueDate AND ALE.AssetId = ALH.AssetId AND ALE.EffectiveFromDate = ALH.EffectiveFromDate
GROUP BY 
	ALE.AssetId,
	ALE.EffectiveFromDate,
	ALH.ReceivableDetailId,
	ALE.DueDate

--Previous Location Effective From Date
SELECT
	ALH.AssetId,
	ALH.ReceivableDetailId,
	ALH.DueDate,
	MAX(ALH.EffectiveFromDate) AS EffectiveFromDate
INTO #AssetPreviousLocationEffectiveDate
FROM #AssetLocationHistory ALH
	INNER JOIN #AssetNearestLocationEffectiveDate ANL ON ALH.AssetId = ANL.AssetId AND ALH.DueDate = ANL.DueDate
WHERE ANL.IsPastLocation = 1 AND ALH.EffectiveFromDate < ANL.EffectiveFromDate
GROUP BY
	ALH.AssetId,
	ALH.ReceivableDetailId,
	ALH.DueDate;

SELECT
	ALE.AssetId,
	ALE.DueDate,
	ALH.EffectiveFromDate,
	MAX(ALH.AssetLocationId) AssetLocationId,
	ALH.ReceivableDetailId
INTO #AssetPreviousLocation
FROM #AssetPreviousLocationEffectiveDate AS ALE
	INNER JOIN #AssetLocationHistory ALH ON ALE.DueDate = ALH.DueDate AND ALE.AssetId = ALH.AssetId
		AND ALE.EffectiveFromDate = ALH.EffectiveFromDate
GROUP BY
	ALE.AssetId,
	ALH.EffectiveFromDate,
	ALE.DueDate,
	ALH.ReceivableDetailId;

INSERT INTO SalesTaxAssetLocationDetailExtract (AssetId, ReceivableDetailId, LocationId, PreviousLocationId, ReciprocityAmount, LienCredit,
LocationEffectiveDate, LocationTaxBasisType, ReceivableDueDate, AssetLocationId,JobStepInstanceId,UpfrontTaxAssessedInLegacySystem)
SELECT
	ALT.AssetId,
	ALT.ReceivableDetailId,
	AL.LocationId,
	ALH.LocationId,
	AL.ReciprocityAmount_Amount,
	AL.LienCredit_Amount,
	AL.EffectiveFromDate,
	AL.TaxBasisType,
	ALT.DueDate,
	ALT.AssetLocationId,
	@JobStepInstanceId,
	AL.UpfrontTaxAssessedInLegacySystem
FROM #AssetNearestLocation ALT
	INNER JOIN SalesTaxReceivableDetailExtract STR ON ALT.ReceivableDetailId = STR.ReceivableDetailId AND STR.AssetId = ALT.AssetId 
		AND STR.JobStepInstanceId = @JobStepInstanceId AND STR.ReceivableTaxType = @ReceivableTaxTypeSalesTax
	INNER JOIN AssetLocations AL ON ALT.AssetLocationId= AL.Id
	LEFT JOIN #AssetPreviousLocation APL ON ALT.AssetId = APL.AssetId AND APL.ReceivableDetailId = ALT.ReceivableDetailId
	LEFT JOIN #AssetLocationHistory ALH ON APL.AssetLocationId = ALH.AssetLocationId
		AND ALH.AssetId = APL.AssetId AND APL.ReceivableDetailId = ALH.ReceivableDetailId;

--For adjusted receivables
SELECT 
	RD.AssetId,
	RD.ReceivableDetailId,
	RTD.LocationId,
	RTD.TaxBasisType,
	AL.ReciprocityAmount_Amount,
	AL.LienCredit_Amount,
	AL.EffectiveFromDate,
	RD.ReceivableDueDate,
	RTD.AssetLocationId,
	RD.CustomerLocationId
INTO #AdjustedReceivableDetailsFromOriginalReceivables
FROM SalesTaxReceivableDetailExtract RD
	JOIN ReceivableTaxDetails RTD ON RD.AdjustmentBasisReceivableDetailId = RTD.ReceivableDetailId AND RTD.IsActive = 1
		AND RD.JobStepInstanceId = @JobStepInstanceId 
		AND RD.AdjustmentBasisReceivableDetailId IS NOT NULL 
		AND RD.IsOriginalReceivableDetailTaxAssessed = 1
		AND RD.ReceivableTaxType = @ReceivableTaxTypeSalesTax
	JOIN AssetLocations AL ON RTD.AssetLocationId = AL.Id
	LEFT JOIN Contracts C ON RD.ContractId = C.Id AND C.TaxAssessmentLevel=@TaxAssessmentAsset

SELECT
	RD.AssetId,
	RD.ReceivableDetailId,
	RD.ReceivableDueDate,
	MAX(PreviousLocation.EffectiveFromDate) AS EffectiveFromDate
INTO #AssetPreviousLocationEffectiveFromDateForAdjsutedReceivables
FROM SalesTaxReceivableDetailExtract RD
	INNER JOIN ReceivableTaxDetails RTD ON RD.AdjustmentBasisReceivableDetailId = RTD.ReceivableDetailId AND RD.ReceivableTaxType = @ReceivableTaxTypeSalesTax
	INNER JOIN #AdjustedReceivableDetailsFromOriginalReceivables ARD ON ARD.ReceivableDetailId = RD.ReceivableDetailId AND ARD.AssetId = RD.AssetId
	LEFT JOIN AssetLocations PreviousLocation ON RTD.AssetId = PreviousLocation.AssetId AND PreviousLocation.EffectiveFromDate < ARD.EffectiveFromDate
GROUP BY
    RD.AssetId,
    RD.ReceivableDetailId,
    RD.ReceivableDueDate

SELECT 
	APL.AssetId,
	APL.ReceivableDetailId,
	MAX(AL.Id) AssetLocationId
INTO #AssetPreviousLocationDetailsForAdjsutedReceivables
FROM #AssetPreviousLocationEffectiveFromDateForAdjsutedReceivables APL
	JOIN AssetLocations AL ON APL.AssetId = AL.Id AND AL.EffectiveFromDate = APL.EffectiveFromDate
GROUP BY
	APL.AssetId,
	APL.ReceivableDetailId,
	APL.ReceivableDueDate,
	AL.EffectiveFromDate

INSERT INTO SalesTaxAssetLocationDetailExtract ([AssetId],[ReceivableDetailId],[LocationId],[PreviousLocationId],[LocationTaxBasisType],[ReciprocityAmount],
	[LienCredit],[LocationEffectiveDate],[ReceivableDueDate],[AssetlocationId],[CustomerLocationId],[JobStepInstanceId],[UpfrontTaxAssessedInLegacySystem])
SELECT
	ARD.AssetId,
	ARD.ReceivableDetailId,
	ARD.LocationId,
	APL.AssetLocationId PreviousLocationId,
	ARD.TaxBasisType,
	ARD.ReciprocityAmount_Amount,
	ARD.LienCredit_Amount,
	ARD.EffectiveFromDate,
	ARD.ReceivableDueDate,
	ARD.AssetLocationId,
	ARD.CustomerLocationId,
	@JobStepInstanceId,
	CAST(0 AS BIT)
FROM #AdjustedReceivableDetailsFromOriginalReceivables ARD
LEFT JOIN #AssetPreviousLocationDetailsForAdjsutedReceivables APL ON ARD.AssetId = APL.AssetId 
    AND ARD.ReceivableDetailId = APL.ReceivableDetailId 

-- Contract Based Receivables with Tax Assessment Level as 'Customer is processsed here.
-- Customer Based receivables are always assessed at Asset Level, processed in the above routine
SELECT
	RD.AssetId AS AssetId,
	RD.ReceivableDetailId,
	RD.ReceivableDueDate DueDate,
	CL.EffectiveFromDate AS EffectiveFromDate,
	CL.Id AS CustomerLocationId,
	CL.LocationId,
	RD.ContractId
INTO #CustomerLocationHistory
FROM #SalesTaxReceivableDetail_ExtractTemp RD
	INNER JOIN Contracts C ON RD.ContractId = C.Id AND RD.JobStepInstanceId = @JobStepInstanceId
	INNER JOIN CustomerLocations CL ON CL.CustomerId = RD.CustomerId AND CL.IsActive = 1
WHERE C.TaxAssessmentLevel = @TaxAssessmentCustomer AND RD.AssetId IS NOT NULL AND RD.ContractId IS NOT NULL;

-- RD with no Assets should not be picked up
SELECT
	CLH.AssetId,
	CLH.DueDate,
	MAX(CLH.EffectiveFromDate) AS EffectiveFromDate
INTO #CustomerLocationEffectiveDate
FROM  #CustomerLocationHistory CLH
WHERE CLH.EffectiveFromDate <= CLH.DueDate
GROUP BY
	CLH.AssetId,
	CLH.DueDate;

INSERT INTO #CustomerLocationEffectiveDate
SELECT
	CLH.AssetId,
	CLH.DueDate,
	MIN(CLH.EffectiveFromDate) AS EffectiveFromDate
FROM #CustomerLocationHistory CLH
	LEFT JOIN #CustomerLocationEffectiveDate STLC ON CLH.AssetId = STLC.AssetId AND CLH.DueDate = STLC.DueDate
WHERE CLH.EffectiveFromDate > CLH.DueDate AND STLC.AssetId IS NULL
GROUP BY
	CLH.AssetId,
	CLH.DueDate;

SELECT
	CLE.AssetId,
	CLH.ReceivableDetailId,
	MAX(CLH.CustomerLocationId) CustomerLocationId,
	CLE.DueDate,
	CLH.EffectiveFromDate,
	CLH.ContractId
INTO #CustomerLocation
FROM #CustomerLocationEffectiveDate AS CLE
	JOIN #CustomerLocationHistory CLH ON CLE.DueDate = CLH.DueDate
		AND CLE.AssetId = CLH.AssetId AND CLE.EffectiveFromDate = CLH.EffectiveFromDate
GROUP BY
	CLE.AssetId,
	CLH.ReceivableDetailId,
	CLH.EffectiveFromDate,
	CLE.DueDate,
	CLH.ContractId;

--PreviousAssetLocationId
SELECT
	AL.AssetId,
	AL.DueDate,
	MAX(AL.EffectiveFromDate) AS EffectiveFromDate
INTO #CustomerPreviousLocationEffectiveDate
FROM #CustomerLocationHistory AL
WHERE AL.EffectiveFromDate <= AL.DueDate
GROUP BY
	AL.AssetId,
	AL.DueDate;

SELECT
	ALE.AssetId,
	ALH.ReceivableDetailId,
	ALE.DueDate,
	ALH.EffectiveFromDate,
	MAX(ALH.CustomerLocationId) CustomerLocationId
INTO #CustomerPreviousLocation
FROM #CustomerPreviousLocationEffectiveDate AS ALE
	INNER JOIN #CustomerLocationHistory ALH ON ALE.DueDate = ALH.DueDate AND ALE.AssetId = ALH.AssetId AND ALE.EffectiveFromDate = ALH.EffectiveFromDate
GROUP BY
	ALE.AssetId,
	ALH.ReceivableDetailId,
	ALE.DueDate,
	ALH.EffectiveFromDate;

INSERT INTO SalesTaxAssetLocationDetailExtract (AssetId, ReceivableDetailId, LocationId, PreviousLocationId, ReciprocityAmount, LienCredit,
LocationEffectiveDate, LocationTaxBasisType, ReceivableDueDate, AssetLocationId,CustomerLocationId,JobStepInstanceId,UpfrontTaxAssessedInLegacySystem)
SELECT
	CLT.AssetId,
	CLT.ReceivableDetailId, 
	CL.LocationId, 
	CLH.LocationId, 
	0.00, 
	0.00, 
	CL.EffectiveFromDate,
	CASE WHEN CCL.TaxBasisType IS NULL THEN CL.TaxBasisType ELSE CCL.TaxBasisType END ,
	CLT.DueDate, 
	NULL, 
	CLT.CustomerLocationId,
	@JobStepInstanceId,
	ISNULL(CCL.UpfrontTaxAssessedInLegacySystem, CAST(0 AS BIT))
FROM #CustomerLocation CLT
	INNER JOIN CustomerLocations CL ON CLT.CustomerLocationId = CL.Id
	INNER JOIN SalesTaxReceivableDetailExtract STR ON CLT.ReceivableDetailId = STR.ReceivableDetailId AND STR.AssetId = CLT.AssetId 
		AND STR.JobStepInstanceId = @JobStepInstanceId AND STR.ReceivableTaxType = @ReceivableTaxTypeSalesTax
	LEFT JOIN ContractCustomerLocations CCL ON CLT.CustomerLocationId = CCL.CustomerLocationId AND CLT.ContractId = CCL.ContractId AND CCL.UpfrontTaxAssessedInLegacySystem = 1
	LEFT JOIN #CustomerPreviousLocation CPL ON CLT.AssetId = CPL.AssetId AND CPL.ReceivableDetailId = CLT.ReceivableDetailId
	LEFT JOIN #CustomerLocationHistory CLH ON CPL.CustomerLocationId = CLH.CustomerLocationId
		AND CLH.AssetId = CPL.AssetId AND CLH.ReceivableDetailId = CPL.ReceivableDetailId;

--Update taxbasistype,location for adjusted receivables
UPDATE SalesTaxAssetLocationDetailExtract
SET 
	LocationTaxBasisType = RTD.TaxBasisType,
	LocationId = RTD.LocationId
FROM #CustomerLocation CLT
	JOIN SalesTaxReceivableDetailExtract RD ON RD.ReceivableDetailId = CLT.ReceivableDetailId AND RD.AssetId = CLT.AssetId 
	    AND RD.AdjustmentBasisReceivableDetailId IS NOT NULL 
		AND RD.IsOriginalReceivableDetailTaxAssessed = 1
		AND RD.ReceivableTaxType = @ReceivableTaxTypeSalesTax
	JOIN ReceivableTaxDetails RTD ON RD.AdjustmentBasisReceivableDetailId = RTD.ReceivableDetailId AND CLT.AssetId = RTD.AssetId AND RTD.IsActive = 1;

--Update soft asset details if tax assessment happened already for original receivable

UPDATE SalesTaxAssetLocationDetailExtract
SET
	LocationTaxBasisType = STALC.TaxBasisType
FROM SalesTaxAssetLocationDetailExtract STAL
	JOIN #SalesTaxReceivableDetail_ExtractTempWithoutCapitalizeAssetFromReceivableTaxDetail STALC ON STAL.JobStepInstanceId = STALC.JobStepInstanceId AND STAL.AssetId = STALC.AssetId 
		AND STAL.ReceivableDetailId = STALC.ReceivableDetailId AND STAL.JobStepInstanceId = @JobStepInstanceId
WHERE STAL.LocationTaxBasisType <> STALC.TaxBasisType;

--Update soft asset details if tax assessment happening with original receivable

UPDATE SalesTaxAssetLocationDetailExtract
SET
	LocationTaxBasisType = STALC.LocationTaxBasisType
FROM SalesTaxAssetLocationDetailExtract STAL
JOIN (
		SELECT 
			DISTINCT CRD.ReceivableDetailId, STA.AssetId, STAL.LocationTaxBasisType, STA.JobStepInstanceId 
		FROM SalesTaxReceivableDetailExtract RD
		JOIN SalesTaxAssetLocationDetailExtract STAL ON RD.AssetId = STAL.AssetId AND RD.JobStepInstanceId = STAL.JobStepInstanceId
			AND RD.ReceivableDetailId = STAL.ReceivableDetailId AND (RD.AdjustmentBasisReceivableDetailId IS NULL OR RD.IsOriginalReceivableDetailTaxAssessed = 0)
		JOIN SalesTaxAssetDetailExtract STA ON STAL.JobStepInstanceId = STA.JobStepInstanceId AND STAL.AssetId = STA.CapitalizedOriginalAssetId
		JOIN SalesTaxReceivableDetailExtract CRD ON STA.AssetId = CRD.AssetId AND RD.ReceivableDueDate = CRD.ReceivableDueDate
			AND  RD.JobStepInstanceId = CRD.JobStepInstanceId AND RD.ContractId = CRD.ContractId AND RD.ReceivableCodeId = CRD.ReceivableCodeId
			AND (CRD.AdjustmentBasisReceivableDetailId IS NULL OR CRD.IsOriginalReceivableDetailTaxAssessed = 0)
) AS STALC
ON STAL.JobStepInstanceId = STALC.JobStepInstanceId 
	AND STAL.AssetId = STALC.AssetId AND STAL.ReceivableDetailId = STALC.ReceivableDetailId
WHERE STAL.JobStepInstanceId = @JobStepInstanceId
	AND STAL.LocationTaxBasisType <> STALC.LocationTaxBasisType;

--Update soft asset details if tax assessment not happening with original receivable

UPDATE SalesTaxAssetLocationDetailExtract
SET
	LocationTaxBasisType = STALC.LocationTaxBasisType
FROM SalesTaxAssetLocationDetailExtract STAL
JOIN (
		SELECT 
			RD.ReceivableDetailId, STA.AssetId, AL.TaxBasisType LocationTaxBasisType, STA.JobStepInstanceId 
		FROM SalesTaxReceivableDetailExtract RD
		JOIN SalesTaxAssetDetailExtract STA ON STA.JobStepInstanceId = @JobStepInstanceId AND RD.AssetId = STA.AssetId
		JOIN #AssetNearestLocation STAL ON STA.CapitalizedOriginalAssetId = STAL.AssetId AND RD.JobStepInstanceId = @JobStepInstanceId
			AND RD.ReceivableDetailId = (-1) * STAL.ReceivableDetailId AND (RD.AdjustmentBasisReceivableDetailId IS NULL OR RD.IsOriginalReceivableDetailTaxAssessed = 0)
		JOIN AssetLocations AL ON STAL.AssetLocationId= AL.Id
		WHERE STA.JobStepInstanceId = @JobStepInstanceId
		AND RD.ReceivableTaxType = @ReceivableTaxTypeSalesTax
) AS STALC
ON STAL.JobStepInstanceId = STALC.JobStepInstanceId 
	AND STAL.AssetId = STALC.AssetId AND STAL.ReceivableDetailId = STALC.ReceivableDetailId
WHERE STAL.JobStepInstanceId = @JobStepInstanceId
	AND STAL.LocationTaxBasisType = STALC.LocationTaxBasisType;

UPDATE
SalesTaxReceivableDetailExtract
SET
	CustomerLocationId = AL.CustomerLocationId, 
	AssetLocationId = AL.AssetLocationId,
	LocationId = AL.LocationId, 
	PreviousLocationId = AL.PreviousLocationId
FROM SalesTaxReceivableDetailExtract RD
	INNER JOIN SalesTaxAssetLocationDetailExtract AL ON RD.AssetId = AL.AssetId AND RD.ReceivableDueDate = AL.ReceivableDueDate 
		AND AL.JobStepInstanceId = RD.JobStepInstanceId 
		AND RD.JobStepInstanceId = @JobStepInstanceId
		AND RD.ReceivableTaxType = @ReceivableTaxTypeSalesTax

END

GO

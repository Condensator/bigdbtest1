SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InsertAssetLocationDetails]
(
	@TaxAssessmentAsset		NVARCHAR(50),
	@TaxAssessmentCustomer	NVARCHAR(50),
	@JobStepInstanceId		BIGINT,
	@ReceivableTaxTypeSalesTax	NVARCHAR(20)
)
AS
BEGIN
SET NOCOUNT ON

-- Contract Based Receivables with Tax Assessment Level as Asset
SELECT
AL.AssetId,
RD.ReceivableDetailId,
RD.ReceivableDueDate AS DueDate,
AL.EffectiveFromDate AS EffectiveFromDate,
AL.Id AS AssetLocationId,
AL.LocationId,
AL.ReciprocityAmount_Amount,
AL.LienCredit_Amount,
AL.TaxBasisType,
AL.UpfrontTaxAssessedInLegacySystem
INTO #AssetLocationHistory
FROM SalesTaxReceivableDetailExtract RD
INNER JOIN Contracts C ON RD.ContractId = C.Id AND RD.JobStepInstanceId = @JobStepInstanceId
INNER JOIN AssetLocations AL ON AL.AssetId = RD.AssetId AND AL.IsActive = 1
INNER JOIN Locations L ON AL.LocationId = L.Id AND RD.CustomerId = L.CustomerId
WHERE C.TaxAssessmentLevel=@TaxAssessmentAsset
AND (RD.AdjustmentBasisReceivableDetailId IS NULL OR RD.IsOriginalReceivableDetailTaxAssessed = 0)
AND RD.ReceivableTaxType = @ReceivableTaxTypeSalesTax;

INSERT INTO #AssetLocationHistory (AssetId,ReceivableDetailId, DueDate, EffectiveFromDate, AssetLocationId, LocationId, ReciprocityAmount_Amount, LienCredit_Amount, TaxBasisType, UpfrontTaxAssessedInLegacySystem)
SELECT
AL.AssetId,
RD.ReceivableDetailId,
RD.ReceivableDueDate AS DueDate,
AL.EffectiveFromDate AS EffectiveFromDate,
AL.Id AS AssetLocationId,
AL.LocationId,
AL.ReciprocityAmount_Amount,
AL.LienCredit_Amount,
AL.TaxBasisType,
AL.UpfrontTaxAssessedInLegacySystem
FROM SalesTaxReceivableDetailExtract RD
INNER JOIN Contracts C ON RD.ContractId = C.Id AND RD.JobStepInstanceId = @JobStepInstanceId
INNER JOIN AssetLocations AL ON AL.AssetId = RD.AssetId AND AL.IsActive = 1
INNER JOIN Locations L ON AL.LocationId = L.Id AND L.CustomerId IS NULL
WHERE C.TaxAssessmentLevel=@TaxAssessmentAsset
AND (RD.AdjustmentBasisReceivableDetailId IS NULL OR RD.IsOriginalReceivableDetailTaxAssessed = 0)
AND RD.ReceivableTaxType = @ReceivableTaxTypeSalesTax;

-- Customer Based Receivables
INSERT INTO #AssetLocationHistory (AssetId,ReceivableDetailId, DueDate, EffectiveFromDate, AssetLocationId, LocationId, ReciprocityAmount_Amount, LienCredit_Amount, TaxBasisType, UpfrontTaxAssessedInLegacySystem)
SELECT
AL.AssetId,
RD.ReceivableDetailId,
RD.ReceivableDueDate AS DueDate,
AL.EffectiveFromDate AS EffectiveFromDate,
AL.Id AS AssetLocationId,
AL.LocationId,
AL.ReciprocityAmount_Amount,
AL.LienCredit_Amount,
AL.TaxBasisType,
AL.UpfrontTaxAssessedInLegacySystem
FROM SalesTaxReceivableDetailExtract RD
INNER JOIN AssetLocations AL ON AL.AssetId = RD.AssetId AND AL.IsActive = 1
INNER JOIN Locations L ON AL.LocationId = L.Id AND RD.CustomerId = L.CustomerId
WHERE RD.ContractId IS NULL AND RD.JobStepInstanceId = @JobStepInstanceId
AND (RD.AdjustmentBasisReceivableDetailId IS NULL OR RD.IsOriginalReceivableDetailTaxAssessed = 0)
AND RD.ReceivableTaxType = @ReceivableTaxTypeSalesTax;

INSERT INTO #AssetLocationHistory (AssetId,ReceivableDetailId, DueDate, EffectiveFromDate, AssetLocationId, LocationId, ReciprocityAmount_Amount, LienCredit_Amount, TaxBasisType, UpfrontTaxAssessedInLegacySystem)
SELECT
AL.AssetId,
RD.ReceivableDetailId,
RD.ReceivableDueDate AS DueDate,
AL.EffectiveFromDate AS EffectiveFromDate,
AL.Id AS AssetLocationId,
AL.LocationId,
AL.ReciprocityAmount_Amount,
AL.LienCredit_Amount,
AL.TaxBasisType,
AL.UpfrontTaxAssessedInLegacySystem
FROM SalesTaxReceivableDetailExtract RD
INNER JOIN AssetLocations AL ON AL.AssetId = RD.AssetId AND AL.IsActive = 1
INNER JOIN Locations L ON AL.LocationId = L.Id AND L.CustomerId IS NULL
WHERE RD.ContractId IS NULL AND RD.JobStepInstanceId = @JobStepInstanceId
AND (RD.AdjustmentBasisReceivableDetailId IS NULL OR RD.IsOriginalReceivableDetailTaxAssessed = 0)
AND RD.ReceivableTaxType = @ReceivableTaxTypeSalesTax;

-- Neareset location effective from date in the past
SELECT
AL.AssetId
,AL.ReceivableDetailId
,AL.DueDate
,MAX(AL.EffectiveFromDate) AS EffectiveFromDate
,1 as IsPastLocation
INTO #AssetNearestLocation
FROM  #AssetLocationHistory AL
WHERE AL.EffectiveFromDate <= AL.DueDate
GROUP BY
AL.AssetId
,AL.ReceivableDetailId
,AL.DueDate;

-- Neareset location effective from date in the future when no record found in past
INSERT INTO #AssetNearestLocation
SELECT
AL.AssetId
,AL.ReceivableDetailId
,AL.DueDate
,MIN(AL.EffectiveFromDate) AS EffectiveFromDate
,0 as IsPastLocation
FROM #AssetLocationHistory AL
LEFT JOIN #AssetNearestLocation STLA ON AL.AssetId = STLA.AssetId
AND AL.DueDate = STLA.DueDate
WHERE  STLA.AssetId IS NULL AND AL.EffectiveFromDate > AL.DueDate
GROUP BY
AL.AssetId
,AL.ReceivableDetailId
,AL.DueDate;

--Previous Location Effective From Date
SELECT
ALH.AssetId
,ALH.ReceivableDetailId
,ALH.DueDate
,MAX(ALH.EffectiveFromDate) AS EffectiveFromDate
INTO #AssetPreviousLocation
FROM #AssetLocationHistory ALH
INNER JOIN #AssetNearestLocation ANL on ALH.AssetId = ANL.AssetId AND ALH.DueDate = ANL.DueDate
WHERE ANL.IsPastLocation = 1 and ALH.EffectiveFromDate < ANL.EffectiveFromDate
GROUP BY
ALH.AssetId
,ALH.ReceivableDetailId
,ALH.DueDate;

INSERT INTO SalesTaxAssetLocationDetailExtract (AssetId, ReceivableDetailId, LocationId, PreviousLocationId, ReciprocityAmount, LienCredit,
LocationEffectiveDate, LocationTaxBasisType, ReceivableDueDate, AssetLocationId, JobStepInstanceId, UpfrontTaxAssessedInLegacySystem)
SELECT
ALT.AssetId
,ALT.ReceivableDetailId
,AL.LocationId
,ALH.LocationId
,AL.ReciprocityAmount_Amount
,AL.LienCredit_Amount
,AL.EffectiveFromDate
,AL.TaxBasisType
,ALT.DueDate
,AL.AssetLocationId
,@JobStepInstanceId
,AL.UpfrontTaxAssessedInLegacySystem
FROM #AssetNearestLocation ALT
INNER JOIN #AssetLocationHistory AL ON AL.AssetId = ALT.AssetId AND AL.ReceivableDetailId = ALT.ReceivableDetailId AND AL.EffectiveFromDate = ALT.EffectiveFromDate 
LEFT JOIN #AssetPreviousLocation APL ON ALT.AssetId = APL.AssetId AND APL.ReceivableDetailId = ALT.ReceivableDetailId
LEFT JOIN #AssetLocationHistory ALH ON ALH.AssetId = APL.AssetId AND APL.ReceivableDetailId = ALH.ReceivableDetailId AND APL.EffectiveFromDate=ALH.EffectiveFromDate;

--For adjusted receivables
--Adjusted Receivable Current Location
SELECT 
	 RD.AssetId
	,RD.ReceivableDetailId
	,RTD.LocationId
	,RTD.TaxBasisType
	,AL.ReciprocityAmount_Amount
	,AL.LienCredit_Amount
	,AL.EffectiveFromDate
	,RD.ReceivableDueDate
	,RTD.AssetLocationId
	,RD.CustomerLocationId
	,AL.UpfrontTaxAssessedInLegacySystem
INTO #AdjustedReceivableDetailsFromOriginalReceivables
FROM SalesTaxReceivableDetailExtract RD
	JOIN ReceivableTaxDetails RTD ON RD.AdjustmentBasisReceivableDetailId = RTD.ReceivableDetailId AND RTD.IsActive = 1
		AND RD.JobStepInstanceId = @JobStepInstanceId 
		AND RD.AdjustmentBasisReceivableDetailId IS NOT NULL 
		AND RD.IsOriginalReceivableDetailTaxAssessed = 1
		AND RD.ReceivableTaxType = @ReceivableTaxTypeSalesTax
	JOIN AssetLocations AL ON RTD.AssetLocationId = AL.Id

--Adjusted Receivable Previous Location
SELECT
row_num= ROW_NUMBER() OVER(Partition BY RD.AssetId,RD.ReceivableDetailId,RD.ReceivableDueDate ORDER BY PreviousLocation.EffectiveFromDate DESC)
,RD.AssetId
,RD.ReceivableDetailId
,RD.ReceivableDueDate
,PreviousLocation.EffectiveFromDate AS EffectiveFromDate
,PreviousLocation.Id AssetLocationId
INTO #AssetPreviousLocationDetailsForAdjsutedReceivables
FROM SalesTaxReceivableDetailExtract RD
INNER JOIN ReceivableTaxDetails RTD ON RD.JobStepInstanceId=@JobStepInstanceId AND RD.AdjustmentBasisReceivableDetailId = RTD.ReceivableDetailId AND RD.ReceivableTaxType = @ReceivableTaxTypeSalesTax
INNER JOIN #AdjustedReceivableDetailsFromOriginalReceivables ARD ON ARD.ReceivableDetailId = RD.ReceivableDetailId AND ARD.AssetId = RD.AssetId
LEFT JOIN AssetLocations PreviousLocation ON RTD.AssetId = PreviousLocation.AssetId AND PreviousLocation.EffectiveFromDate < ARD.EffectiveFromDate AND PreviousLocation.IsActive=1

INSERT INTO SalesTaxAssetLocationDetailExtract ([AssetId],[ReceivableDetailId],[LocationId],[PreviousLocationId],[LocationTaxBasisType],[ReciprocityAmount],
	[LienCredit],[LocationEffectiveDate],[ReceivableDueDate],[AssetlocationId],[CustomerLocationId],[JobStepInstanceId],
	[UpfrontTaxAssessedInLegacySystem])
SELECT
 ARD.AssetId
,ARD.ReceivableDetailId
,ARD.LocationId
,APL.AssetLocationId PreviousLocationId
,ARD.TaxBasisType
,ARD.ReciprocityAmount_Amount
,ARD.LienCredit_Amount
,ARD.EffectiveFromDate
,ARD.ReceivableDueDate
,ARD.AssetLocationId
,ARD.CustomerLocationId
,@JobStepInstanceId
,ARD.UpfrontTaxAssessedInLegacySystem
FROM #AdjustedReceivableDetailsFromOriginalReceivables ARD
LEFT JOIN #AssetPreviousLocationDetailsForAdjsutedReceivables APL ON APL.row_num=1 AND ARD.AssetId = APL.AssetId 
    AND ARD.ReceivableDetailId = APL.ReceivableDetailId 

-- Contract Based Receivables with Tax Assessment Level as Customer is processsed here.
-- Customer Based receivables are always assessed at Asset Level, processed in the above routine
SELECT
RD.AssetId AS AssetId,
RD.CustomerId, 
RD.ReceivableDetailId,
RD.ReceivableDueDate DueDate,
CL.EffectiveFromDate AS EffectiveFromDate,
CL.Id AS CustomerLocationId,
CL.LocationId,
RD.ContractId,
CL.TaxBasisType
INTO #CustomerLocationHistory
FROM SalesTaxReceivableDetailExtract RD
INNER JOIN Contracts C ON RD.ContractId = C.Id AND RD.JobStepInstanceId = @JobStepInstanceId
INNER JOIN CustomerLocations CL ON CL.CustomerId = RD.CustomerId AND CL.IsActive = 1
WHERE C.TaxAssessmentLevel = @TaxAssessmentCustomer AND RD.AssetId IS NOT NULL AND RD.ContractId IS NOT NULL
AND (RD.AdjustmentBasisReceivableDetailId IS NULL OR RD.IsOriginalReceivableDetailTaxAssessed = 0)
AND RD.ReceivableTaxType = @ReceivableTaxTypeSalesTax;

-- RD with no Assets should not be picked up
SELECT
CLH.CustomerId
,CLH.AssetId
,CLH.ReceivableDetailId
,CLH.ContractId
,CLH.DueDate
,MAX(CLH.EffectiveFromDate) AS EffectiveFromDate
INTO #CustomerLocation
FROM  #CustomerLocationHistory CLH
WHERE CLH.EffectiveFromDate <= CLH.DueDate
GROUP BY
CLH.CustomerId
,CLH.AssetId
,CLH.ReceivableDetailId
,CLH.DueDate
,CLH.ContractId;

INSERT INTO #CustomerLocation
SELECT
CLH.CustomerId
,CLH.AssetId
,CLH.ReceivableDetailId
,CLH.ContractId
,CLH.DueDate
,MIN(CLH.EffectiveFromDate) AS EffectiveFromDate
FROM #CustomerLocationHistory CLH
LEFT JOIN #CustomerLocation STLC ON CLH.AssetId = STLC.AssetId
AND CLH.DueDate = STLC.DueDate
WHERE CLH.EffectiveFromDate > CLH.DueDate AND STLC.AssetId IS NULL
GROUP BY
CLH.CustomerId
,CLH.AssetId
,CLH.ReceivableDetailId
,CLH.DueDate
,CLH.ContractId;

--PreviousAssetLocationId
SELECT
AL.CustomerId
,AL.AssetId
,AL.ReceivableDetailId
,AL.DueDate
,MAX(AL.EffectiveFromDate) AS EffectiveFromDate
INTO #CustomerPreviousLocation
FROM #CustomerLocationHistory AL
WHERE AL.EffectiveFromDate <= AL.DueDate
GROUP BY
AL.CustomerId
,AL.AssetId
,AL.ReceivableDetailId
,AL.DueDate;

INSERT INTO SalesTaxAssetLocationDetailExtract (AssetId, ReceivableDetailId, LocationId, PreviousLocationId, ReciprocityAmount, LienCredit,
LocationEffectiveDate, LocationTaxBasisType, ReceivableDueDate, AssetLocationId, CustomerLocationId, JobStepInstanceId, UpfrontTaxAssessedInLegacySystem)
SELECT
	CLT.AssetId
	,CLT.ReceivableDetailId
	,CL.LocationId
	,CLH.LocationId
	,0.00
	,0.00
	,CL.EffectiveFromDate
	,CASE WHEN CCL.TaxBasisType IS NULL THEN CL.TaxBasisType ELSE CCL.TaxBasisType END
	,CLT.DueDate
	,NULL
	,CL.CustomerLocationId
	,@JobStepInstanceId
	,ISNULL(CCL.UpfrontTaxAssessedInLegacySystem, CAST(0 AS BIT))
FROM #CustomerLocation CLT
INNER JOIN #CustomerLocationHistory CL ON CL.CustomerId = CLT.CustomerId AND CLT.ReceivableDetailId = CL.ReceivableDetailId AND CL.EffectiveFromDate = CLT.EffectiveFromDate AND CLT.AssetId = CL.AssetId
LEFT JOIN ContractCustomerLocations CCL ON CL.CustomerLocationId = CCL.CustomerLocationId AND CLT.ContractId = CCL.ContractId 
LEFT JOIN #CustomerPreviousLocation CPL ON CLT.AssetId = CPL.AssetId AND CPL.ReceivableDetailId = CLT.ReceivableDetailId
LEFT JOIN #CustomerLocationHistory CLH ON  CLH.AssetId = CPL.AssetId AND CLH.ReceivableDetailId = CPL.ReceivableDetailId AND CPL.EffectiveFromDate = CLH.EffectiveFromDate;

--Update taxbasistype,location for adjusted receivables
UPDATE SalesTaxAssetLocationDetailExtract
SET 
 LocationTaxBasisType = RTD.TaxBasisType
,LocationId = RTD.LocationId
FROM #CustomerLocation CLT
JOIN SalesTaxReceivableDetailExtract RD ON RD.ReceivableDetailId = CLT.ReceivableDetailId AND RD.AssetId = CLT.AssetId 
    AND RD.AdjustmentBasisReceivableDetailId IS NOT NULL 
	AND RD.IsOriginalReceivableDetailTaxAssessed = 1
	AND RD.ReceivableTaxType = @ReceivableTaxTypeSalesTax
JOIN ReceivableTaxDetails RTD ON RD.AdjustmentBasisReceivableDetailId = RTD.ReceivableDetailId AND CLT.AssetId = RTD.AssetId AND RTD.IsActive = 1;

--Update Soft Asset TaxBasis from capitalized original asset Where Original Asset already tax assessed.
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
WHERE STA.JobStepInstanceId = @JobStepInstanceId 
	AND (RD.AdjustmentBasisReceivableDetailId IS NULL OR RD.IsOriginalReceivableDetailTaxAssessed = 0)
	AND RD.ReceivableTaxType = @ReceivableTaxTypeSalesTax;

UPDATE SalesTaxAssetLocationDetailExtract
SET
	LocationTaxBasisType = STALC.TaxBasisType
FROM SalesTaxAssetLocationDetailExtract STAL
JOIN #SalesTaxReceivableDetail_ExtractTempWithoutCapitalizeAssetFromReceivableTaxDetail STALC
	ON STAL.JobStepInstanceId = STALC.JobStepInstanceId AND STAL.AssetId = STALC.AssetId 
	AND STAL.ReceivableDetailId = STALC.ReceivableDetailId AND STAL.JobStepInstanceId = @JobStepInstanceId
	AND STAL.LocationTaxBasisType <> STALC.TaxBasisType;

--Update soft asset details
SELECT * INTO #BaseExtract FROM SalesTaxReceivableDetailExtract WHERE JobStepInstanceId = @JobStepInstanceId
AND (AdjustmentBasisReceivableDetailId IS NULL OR IsOriginalReceivableDetailTaxAssessed = 0)

SELECT 
    DISTINCT CRD.ReceivableDetailId, RD.AssetId, STAL.LocationTaxBasisType, RD.JobStepInstanceId 
INTO #SalesTaxAssetDetail_Extract_Temp
FROM 
    #BaseExtract AS RD
INNER JOIN SalesTaxAssetLocationDetailExtract AS STAL
    ON RD.JobStepInstanceId = STAL.JobStepInstanceId
    AND RD.AssetId = STAL.AssetId 
    AND RD.ReceivableDetailId = STAL.ReceivableDetailId 
INNER JOIN SalesTaxAssetDetailExtract STA  
    ON STAL.JobStepInstanceId = STA.JobStepInstanceId
    AND STAL.AssetId = STA.CapitalizedOriginalAssetId
INNER JOIN #BaseExtract AS CRD 
    ON RD.ContractId = CRD.ContractId
    AND RD.ReceivableCodeId = CRD.ReceivableCodeId 
    AND RD.ReceivableDueDate = CRD.ReceivableDueDate
    AND STA.AssetId = CRD.AssetId
			
UPDATE SalesTaxAssetLocationDetailExtract
SET
	LocationTaxBasisType = STALC.LocationTaxBasisType
FROM SalesTaxAssetLocationDetailExtract STAL
JOIN #SalesTaxAssetDetail_Extract_Temp STALC
ON STAL.JobStepInstanceId = STALC.JobStepInstanceId 
AND STAL.AssetId = STALC.AssetId AND STAL.ReceivableDetailId = STALC.ReceivableDetailId
WHERE STAL.JobStepInstanceId = @JobStepInstanceId
	AND STAL.LocationTaxBasisType <> STALC.LocationTaxBasisType;

UPDATE
SalesTaxReceivableDetailExtract
SET
CustomerLocationId = AL.CustomerLocationId, AssetLocationId = AL.AssetLocationId,
LocationId = AL.LocationId, PreviousLocationId = AL.PreviousLocationId
FROM
SalesTaxReceivableDetailExtract RD
INNER JOIN
SalesTaxAssetLocationDetailExtract AL
ON
RD.AssetId = AL.AssetId AND RD.ReceivableDueDate = AL.ReceivableDueDate AND AL.JobStepInstanceId = RD.JobStepInstanceId
AND RD.JobStepInstanceId = @JobStepInstanceId AND RD.ReceivableTaxType = @ReceivableTaxTypeSalesTax
DROP TABLE #BaseExtract
DROP TABLE #SalesTaxAssetDetail_Extract_Temp
END

GO

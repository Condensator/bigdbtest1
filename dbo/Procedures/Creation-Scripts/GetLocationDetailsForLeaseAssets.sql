SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetLocationDetailsForLeaseAssets]
(
@ContractId BIGINT,
@DueDate DATETIMEOFFSET,
@FinancialType NVARCHAR(500),
@ReceivableTypeId BIGINT,
@ReceivableCodeId BIGINT
)
AS
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN

DECLARE @TaxSourceTypeVertex NVARCHAR(10);
SET @TaxSourceTypeVertex = 'Vertex';

CREATE TABLE  #CTE_AllTaxAreaIdsForLocation
(
Row_Num INT,
TaxAreaEffectiveDate DATE,
TaxAreaId BIGINT,
AssetLocationId BIGINT,
AssetId BIGINT,
LocationEffectiveDate DATE,
CustomerCost DECIMAL,
LocationId BIGINT,
LeaseAssetId BIGINT
)
DECLARE @TaxAssessmentLevel NVARCHAR(20)
SELECT @TaxAssessmentLevel = TaxAssessmentLevel FROM Contracts WHERE Id  = @ContractId
IF @TaxAssessmentLevel <> 'Customer'
BEGIN
SELECT
AL.EffectiveFromDate AS EffectiveFromDate,
@DueDate DueDate,
AL.LocationId AS LocationId,
AL.AssetId AS AssetId,
AL.Id AS AssetLocationId
INTO #SalesTaxLeaseAssetLocations
FROM LeaseFinances LF
INNER JOIN LeaseAssets LA ON LA.LeaseFinanceId = LF.Id
INNER JOIN Assets A ON LA.AssetId = A.Id
INNER JOIN AssetTypes AT ON A.TypeId = AT.Id
LEFT JOIN AssetLocations AL ON A.Id = AL.AssetId AND AL.IsActive = 1
WHERE A.FinancialType IN (SELECT Item FROM ConvertCSVToStringTable(@FinancialType,','))
AND LA.IsActive = 1 AND LF.ContractId = @ContractId
;
SELECT
MAXAL.AssetId
,MAXAL.DueDate
,MAX(MAXAL.EffectiveFromDate) AS EffectiveFromDate
INTO #SalesTaxUniqueLeaseAssetLocations
FROM  #SalesTaxLeaseAssetLocations MAXAL
WHERE MAXAL.EffectiveFromDate <= MAXAL.DueDate
GROUP BY
MAXAL.AssetId
,MAXAL.DueDate
;
INSERT INTO #SalesTaxUniqueLeaseAssetLocations
SELECT
MINAL.AssetId
,MINAL.DueDate
,MIN(MINAL.EffectiveFromDate) AS EffectiveFromDate
FROM #SalesTaxLeaseAssetLocations MINAL
WHERE MINAL.EffectiveFromDate > MINAL.DueDate
AND MINAL.AssetId NOT IN(SELECT AssetId FROM #SalesTaxUniqueLeaseAssetLocations)
GROUP BY
MINAL.AssetId
,MINAL.DueDate
;
WITH CTE_AssetLocation AS
(
SELECT
GAL.AssetId
,GAL.EffectiveFromDate
,MAX(LAL.AssetLocationId) AssetLocationId
,LAL.DueDate
FROM #SalesTaxUniqueLeaseAssetLocations AS GAL
JOIN #SalesTaxLeaseAssetLocations LAL ON GAL.EffectiveFromDate = LAL.EffectiveFromDate
AND GAL.AssetId = LAL.AssetId
GROUP BY
GAL.AssetId
,GAL.EffectiveFromDate
,LAL.DueDate
)
INSERT #CTE_AllTaxAreaIdsForLocation
(
Row_Num,
TaxAreaEffectiveDate,
TaxAreaId,
AssetLocationId,
AssetId,
LocationEffectiveDate,
CustomerCost,
LocationId,
LeaseAssetId
)
SELECT
ROW_NUMBER() OVER (PARTITION BY AssetLoc.AssetLocationId ORDER BY
CASE WHEN DATEDIFF(DAY, @DueDate, p.TaxAreaEffectiveDate) = 0 THEN 0 ELSE 1 END,
CASE WHEN DATEDIFF(DAY, @DueDate, p.TaxAreaEffectiveDate) < 0 THEN TaxAreaEffectiveDate END DESC,
CASE WHEN DATEDIFF(DAY, @DueDate, p.TaxAreaEffectiveDate) > 0 THEN TaxAreaEffectiveDate END  ASC) Row_Num,
P.TaxAreaEffectiveDate,
P.TaxAreaId,
AssetLoc.AssetLocationId,
AssetLoc.AssetId,
AssetLoc.EffectiveFromDate LocationEffectiveDate,
LA.CustomerCost_Amount CustomerCost,
AL.LocationId,
LA.Id LeaseAssetId
FROM CTE_AssetLocation AssetLoc
INNER JOIN AssetLocations AL ON AL.Id = AssetLoc.AssetLocationId
INNER JOIN LeaseAssets LA ON LA.AssetId = AL.AssetId AND LA.IsActive = 1
INNER JOIN Assets A ON A.Id = AL.AssetId
LEFT JOIN LocationTaxAreaHistories p ON P.LocationId = AL.LocationId
END
ELSE
BEGIN
SELECT
AL.EffectiveFromDate AS EffectiveFromDate,
@DueDate DueDate,
AL.LocationId AS LocationId,
A.Id AS AssetId,
AL.Id AS AssetLocationId
INTO #SalesTaxLeaseCustomerLocations
FROM LeaseFinances LF
INNER JOIN LeaseAssets LA ON LA.LeaseFinanceId = LF.Id
INNER JOIN Assets A ON LA.AssetId = A.Id
INNER JOIN AssetTypes AT ON A.TypeId = AT.Id
LEFT JOIN CustomerLocations AL ON LF.CustomerId = AL.CustomerId AND AL.IsActive = 1
WHERE A.FinancialType IN (SELECT Item FROM ConvertCSVToStringTable(@FinancialType,','))
AND LA.IsActive = 1 AND LF.ContractId = @ContractId
;
SELECT
MAXAL.AssetId
,MAXAL.DueDate
,MAX(MAXAL.EffectiveFromDate) AS EffectiveFromDate
INTO #SalesTaxUniqueLeaseCustomerLocations
FROM  #SalesTaxLeaseCustomerLocations MAXAL
WHERE MAXAL.EffectiveFromDate <= MAXAL.DueDate
GROUP BY
MAXAL.AssetId
,MAXAL.DueDate
;
INSERT INTO #SalesTaxUniqueLeaseCustomerLocations
SELECT
MINAL.AssetId
,MINAL.DueDate
,MIN(MINAL.EffectiveFromDate) AS EffectiveFromDate
FROM #SalesTaxLeaseCustomerLocations MINAL
WHERE MINAL.EffectiveFromDate > MINAL.DueDate
AND MINAL.AssetId NOT IN(SELECT AssetId FROM #SalesTaxUniqueLeaseCustomerLocations)
GROUP BY
MINAL.AssetId
,MINAL.DueDate
;
WITH CTE_CustomerLocation AS
(
SELECT
GAL.AssetId
,GAL.EffectiveFromDate
,MAX(LAL.AssetLocationId) AssetLocationId
,LAL.DueDate
FROM #SalesTaxUniqueLeaseCustomerLocations AS GAL
JOIN #SalesTaxLeaseCustomerLocations LAL ON GAL.EffectiveFromDate = LAL.EffectiveFromDate
AND GAL.AssetId = LAL.AssetId
GROUP BY
GAL.AssetId
,GAL.EffectiveFromDate
,LAL.DueDate
)
INSERT #CTE_AllTaxAreaIdsForLocation
(
Row_Num,
TaxAreaEffectiveDate,
TaxAreaId,
AssetLocationId,
AssetId,
LocationEffectiveDate,
CustomerCost,
LocationId,
LeaseAssetId
)
SELECT
ROW_NUMBER() OVER (PARTITION BY AssetLoc.AssetLocationId ORDER BY
CASE WHEN DATEDIFF(DAY, @DueDate, p.TaxAreaEffectiveDate) = 0 THEN 0 ELSE 1 END,
CASE WHEN DATEDIFF(DAY, @DueDate, p.TaxAreaEffectiveDate) < 0 THEN TaxAreaEffectiveDate END DESC,
CASE WHEN DATEDIFF(DAY, @DueDate, p.TaxAreaEffectiveDate) > 0 THEN TaxAreaEffectiveDate END  ASC) Row_Num,
P.TaxAreaEffectiveDate,
P.TaxAreaId,
AssetLoc.AssetLocationId,
AssetLoc.AssetId,
AssetLoc.EffectiveFromDate LocationEffectiveDate,
LA.CustomerCost_Amount CustomerCost,
AL.LocationId,
LA.Id LeaseAssetId
FROM CTE_CustomerLocation AssetLoc
INNER JOIN CustomerLocations AL ON AL.Id = AssetLoc.AssetLocationId
INNER JOIN LeaseAssets LA ON LA.AssetId = AssetLoc.AssetId AND LA.IsActive = 1
INNER JOIN Assets A ON A.Id = AssetLoc.AssetId
LEFT JOIN LocationTaxAreaHistories p ON P.LocationId = AL.LocationId
END
SELECT * INTO #CTE_TaxAreaIdAsOfDueDate
FROM #CTE_AllTaxAreaIdsForLocation WHERE Row_Num =1;
SELECT
CTE.AssetId,
CTE.AssetLocationId,
CTE.LocationEffectiveDate,
L.Id LocationId,
L.Code LocationCode,
CTE.TaxAreaId,
CTE.TaxAreaEffectiveDate,
S.ShortName MainDivision,
L.City City,
C.ShortName Country,
L.ApprovalStatus LocationStatus,
L.IsActive IsLocationActive,
CTE.CustomerCost,
ACC.ClassCode AssetType,
A.CurrencyCode Currency,
A.IsTaxExempt IsTaxExempt,
TTC.TransferCode,
CTE.LeaseAssetId,
CAST(CASE WHEN C.TaxSourceType = @TaxSourceTypeVertex THEN 1 ELSE 0 END AS BIT) AS IsVertexSupportedLocation ,
L.JurisdictionId TaxJurisdictionId
,DTTFRT.TaxTypeId
,LA.StateTaxTypeId
,LA.CountyTaxTypeId
,LA.CityTaxTypeId
,S.Id StateId INTO #LocationDetail
FROM
#CTE_TaxAreaIdAsOfDueDate CTE
INNER JOIN Assets A ON CTE.AssetId = A.Id
INNER JOIN AssetTypes AT ON A.TypeId = AT.Id
LEFT JOIN Locations L ON CTE.LocationId = L.Id
LEFT JOIN States S ON L.StateId =S.Id
LEFT JOIN Countries C ON S.CountryId = C.Id
LEFT JOIN AssetClassCodes ACC ON AT.AssetClassCodeId = ACC.Id
LEFT JOIN TitleTransferCodes TTC ON A.TitleTransferCodeId = TTC.Id
LEFT JOIN LeaseAssets LA ON LA.AssetId = A.Id
LEFT JOIN dbo.DefaultTaxTypeForReceivableTypes DTTFRT ON DTTFRT.ReceivableTypeId=@ReceivableTypeId AND C.Id = DTTFRT.CountryId
SELECT DISTINCT
lm.*,
CAST(CASE WHEN IsNULL(TaxExemptRules.IsCountryTaxExempt,0) = 1 OR IsNULL(AssetRule.IsCountryTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsCountryTaxExempt,0) = 1  OR IsNULL(LocationRule.IsCountryTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT)CountryTaxExempt,
CAST(CASE WHEN IsNULL(TaxExemptRules.IsStateTaxExempt,0) = 1 OR IsNULL(AssetRule.IsStateTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsStateTaxExempt,0) = 1  OR IsNULL(LocationRule.IsStateTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT)StateTaxExempt,
CAST(CASE WHEN IsNULL(TaxExemptRules.IsCityTaxExempt,0) = 1 OR IsNULL(AssetRule.IsCityTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsCityTaxExempt,0) = 1  OR IsNULL(LocationRule.IsCityTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT)CityTaxExempt,
CAST(CASE WHEN IsNULL(TaxExemptRules.IsCountyTaxExempt,0) = 1 OR IsNULL(AssetRule.IsCountyTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsCountyTaxExempt,0) = 1  OR IsNULL(LocationRule.IsCountyTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT)CountyTaxExempt
INTO #LocationDetails
FROM
#LocationDetail lm
LEFT JOIN ReceivableCodeTaxExemptRules rct ON rct.ReceivableCodeId = @ReceivableCodeId AND lm.StateId = rct.StateId AND rct.IsActive = 1
LEFT JOIN TaxExemptRules ON rct.TaxExemptRuleId = TaxExemptRules.Id
LEFT JOIN Assets a ON a.Id = lm.AssetId
LEFT JOIN TaxExemptRules AssetRule ON a.TaxExemptRuleId = AssetRule.Id
LEFT JOIN LeaseFinances lf ON lf.ContractId = @ContractId AND lf.IsCurrent = 1
LEFT JOIN TaxExemptRules LeaseRule ON lf.TaxExemptRuleId = LeaseRule.Id
LEFT JOIN Locations l ON lm.LocationId = l.Id
LEFT JOIN TaxExemptRules LocationRule ON l.TaxExemptRuleId = LocationRule.Id;
SELECT * FROM #LocationDetails
END

GO

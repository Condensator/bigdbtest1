SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetTaxRatesForQuotationRequest](
@TaxLocationMapper TaxLocationMapper READONLY,
@IsCountryTaxExempt BIT ,
@IsStateTaxExempt BIT ,
@IsCountyTaxExempt BIT ,
@IsCityTaxExempt BIT,
@DealProductTypeId BIGINT)
AS
BEGIN
SET NOCOUNT ON
DECLARE @CapitalLeaseType NVARCHAR(100) = (SELECT CapitalLeaseType FROM DealProductTypes DPT
WHERE DPT.Id = @DealProductTypeId);
DECLARE @ReceivableTypeId BIGINT;
IF (@CapitalLeaseType = 'DirectFinance' OR @CapitalLeaseType = 'ConditionalSales')
SET @ReceivableTypeId = (SELECT Id FROM ReceivableTypes  WHERE Name = 'CapitalLeaseRental' AND IsActive = 1)
ELSE
SET @ReceivableTypeId = (SELECT Id FROM ReceivableTypes  WHERE Name = 'OperatingLeaseRental' AND IsActive = 1)
SELECT s.Id AS StateId,
c.Id AS CountryId,
city.Id AS CityId,
county.Id AS CountyId,
td.AssetId AS AssetId,
td.DueDate,
td.LocationId,
td.ContractId,
loc.TaxBasisType,
loc.UpfrontTaxMode,
td.StateTaxtypeId,
td.CityTaxTypeId,
td.CountyTaxTypeId,
c.ShortName
INTO #LocationMapping
FROM dbo.Jurisdictions AS l
INNER JOIN @TaxLocationMapper AS td ON l.Id = td.JurisdictionId
INNER JOIN dbo.Locations AS Loc ON td.LocationId = Loc.Id
INNER JOIN dbo.States AS s ON l.StateId = s.Id
INNER JOIN dbo.Countries AS c ON l.CountryId = c.Id
INNER JOIN dbo.Cities AS city ON l.CityId = city.Id
INNER JOIN dbo.Counties AS county ON l.CountyId = county.Id
;
SELECT DISTINCT
LM.AssetId,
CASE WHEN @IsCountryTaxExempt = 1 OR IsNULL(AssetRule.IsCountryTaxExempt,0) = 1  OR IsNULL(LocationRule.IsCountryTaxExempt,0) = 1 THEN 1 ELSE 0 END CountryTaxExempt,
CASE WHEN @IsStateTaxExempt =1 OR IsNULL(AssetRule.IsStateTaxExempt,0) = 1  OR IsNULL(LocationRule.IsStateTaxExempt,0) = 1 THEN 1 ELSE 0 END StateTaxExempt,
CASE WHEN @IsCountyTaxExempt =1 OR IsNULL(AssetRule.IsCountyTaxExempt,0) = 1  OR IsNULL(LocationRule.IsCountyTaxExempt,0) = 1 THEN 1 ELSE 0 END CountyTaxExempt,
CASE WHEN @IsCityTaxExempt =1 OR IsNULL(AssetRule.IsCityTaxExempt,0) = 1  OR IsNULL(LocationRule.IsCityTaxExempt,0) = 1 THEN 1 ELSE 0 END CityTaxExempt
INTO #Exempt
FROM #LocationMapping LM
LEFT JOIN Assets A ON A.Id = LM.AssetId
LEFT JOIN TaxExemptRules AssetRule ON A.TaxExemptRuleId = AssetRule.Id
LEFT JOIN LeaseFinances lf ON LM.ContractId = LF.ContractId AND LF.IsCurrent = 1
LEFT JOIN TaxExemptRules LeaseRule ON LF.TaxExemptRuleId = LeaseRule.Id
LEFT JOIN Locations L ON LM.LocationId = L.Id
LEFT JOIN TaxExemptRules LocationRule ON L.TaxExemptRuleId = LocationRule.Id
SELECT DISTINCT
tr.Id AS TaxRateId,
lm.DueDate,
tr.TaxImpositionTypeId,
j.Id JurisdictionId,
tit.TaxJurisdictionLevel JurisdictionLevel,
tit.Name ImpositionType,
tt.Name TaxType,
E.CountryTaxExempt,
E.CountyTaxExempt,
E.CityTaxExempt,
lm.AssetId,
E.StateTaxExempt,
lm.TaxBasisType,
lm.UpfrontTaxMode,
tt.Id TaxTypeId,
lm.StateTaxtypeId,
lm.CityTaxTypeId,
lm.CountyTaxTypeId,
lm.ShortName CountryShortName,
DTRT.TaxTypeId DefaultTaxTypeId,
tit.TaxTypeId ImpositionTaxTypeId
INTO #ConsolidatedTaxRates
FROM #LocationMapping AS lm
INNER JOIN dbo.TaxImpositionTypes AS tit ON lm.CountryId = tit.CountryId AND tit.IsActive = 1
INNER JOIN dbo.TaxTypes AS tt ON tit.TaxTypeId = tt.Id
INNER JOIN dbo.TaxRates AS tr ON tit.Id = tr.TaxImpositionTypeId AND tr.IsActive = 1
INNER JOIN dbo.DefaultTaxTypeForReceivableTypes DTRT ON DTRT.CountryId = lm.CountryId AND DTRT.ReceivableTypeId = @ReceivableTypeId
INNER JOIN
(SELECT DISTINCT Id ,JurisdictionId
FROM (SELECT
trh.JurisdictionId, trh.Id CityLevel,trh2.Id CountryLevel,trh3.Id StateLevel,trh4.Id CountyLevel
FROM	  (SELECT j.Id JurisdictionId, t.Id,t.CountryId,t.StateId,t.CityId,t.CountyId FROM dbo.Jurisdictions j
INNER JOIN  dbo.TaxRateHeaders AS t ON j.TaxRateHeaderId = t.Id WHERE t.IsActive = 1) trh
INNER JOIN dbo.TaxRateHeaders trh2 ON trh.CountryId = trh2.CountryId AND trh2.CityId IS NULL AND trh2.StateId IS NULL  AND trh2.CountyId IS NULL AND trh2.IsActive = 1
INNER JOIN dbo.TaxRateHeaders trh3 ON trh.StateId = trh3.StateId AND trh.CountryId = trh3.CountryId  AND trh3.CityId IS NULL  AND trh3.CountyId IS NULL AND trh3.IsActive = 1
INNER JOIN dbo.TaxRateHeaders trh4 ON trh.CountyId = trh4.CountyId AND trh4.CityId IS NULL AND trh.StateId = trh4.StateId AND trh4.CountryId = trh.CountryId AND  trh4.IsActive = 1
) AS T
UNPIVOT ( ID FOR Ids IN (CityLevel,CountryLevel,StateLevel,CountyLevel)) AS UP
) AS trh ON tr.TaxRateHeaderId = trh.Id
AND tr.Id = ANY (SELECT TaxRateId FROM TaxRateDetails
WHERE IsActive = 1 AND TaxRateId = tr.Id)
INNER JOIN dbo.Jurisdictions AS j ON trh.JurisdictionId = j.Id AND j.IsActive = 1
AND lm.CountryId = j.CountryId AND j.StateId = lm.StateId AND j.CityId = lm.CityId
AND j.CountyId = lm.CountyId AND tit.CountryId = lm.CountryId AND j.CountryId = lm.CountryId
LEFT JOIN #Exempt E ON lm.AssetId = E.AssetId;
;
SELECT
ctr.AssetId,
CASE WHEN (@IsCountryTaxExempt = 1 AND ctr.JurisdictionLevel = 'Country') OR (@IsStateTaxExempt  = 1 AND ctr.JurisdictionLevel = 'State')  OR
(@IsCountyTaxExempt  = 1 AND ctr.JurisdictionLevel = 'County') OR (@IsCityTaxExempt  = 1 AND ctr.JurisdictionLevel = 'City') OR
(CTR.JurisdictionLevel = 'Country' AND CTR.CountryTaxExempt = 1) OR (CTR.JurisdictionLevel = 'State' AND CTR.StateTaxExempt = 1) OR
(CTR.JurisdictionLevel LIKE '%City%' AND CTR.CityTaxExempt = 1) OR (CTR.JurisdictionLevel LIKE '%County%' AND CTR.CountyTaxExempt = 1)THEN
CAST(ISNULL(T.Rate,0) AS DECIMAL(12,10))
ELSE T.Rate END EffectiveRate,
ctr.TaxBasisType,
ctr.UpfrontTaxMode,
ctr.JurisdictionLevel
INTO #TaxRates
FROM #ConsolidatedTaxRates AS ctr
LEFT JOIN (select RANK() OVER ( PARTITION BY T.AssetId,T.JurisdictionLevel ORDER BY T.EffectiveDate ,T.Id DESC )filter,* from  (
SELECT RANK() OVER ( PARTITION BY ctrtemp.AssetId,ctrtemp.JurisdictionLevel ORDER BY trd.EffectiveDate DESC , trd.Id DESC )rank,
trd.*,ctrtemp.AssetId,ctrtemp.JurisdictionLevel, ctrtemp.impositiontype,
ctrtemp.TaxTypeId
FROM dbo.TaxRateDetails AS trd
INNER JOIN #ConsolidatedTaxRates ctrtemp ON trd.TaxRateId = ctrtemp.TaxRateId
AND trd.EffectiveDate <= ctrtemp.DueDate
AND trd.IsActive = 1
AND (((ctrtemp.JurisdictionLevel = 'County' AND ((ctrtemp.TaxTypeId = ctrtemp.CountyTaxTypeId) OR
(ctrtemp.CountyTaxTypeId IS NULL AND ctrtemp.ImpositionTaxTypeId = ctrtemp.DefaultTaxTypeId)))
OR ((ctrtemp.JurisdictionLevel = 'State' AND ((ctrtemp.TaxTypeId = ctrtemp.StateTaxtypeId) OR
ctrtemp.StateTaxtypeId IS NULL AND ctrtemp.ImpositionTaxTypeId = ctrtemp.DefaultTaxTypeId)))
OR ((ctrtemp.JurisdictionLevel = 'City' AND ((ctrtemp.TaxTypeId = ctrtemp.CityTaxTypeId) OR
ctrtemp.CityTaxTypeId IS NULL AND ctrtemp.ImpositionTaxTypeId = ctrtemp.DefaultTaxTypeId)))
)
OR ctrtemp.CountryShortName <> 'USA')
UNION
SELECT RANK() OVER ( PARTITION BY ctrtemp.AssetId,ctrtemp.JurisdictionLevel ORDER BY trd.EffectiveDate,trd.Id DESC )rank, trd.*,
ctrtemp.AssetId,ctrtemp.JurisdictionLevel, ctrtemp.impositiontype,ctrtemp.TaxTypeId
FROM dbo.TaxRateDetails AS trd
INNER JOIN #ConsolidatedTaxRates ctrtemp ON trd.TaxRateId = ctrtemp.TaxRateId
AND trd.EffectiveDate > ctrtemp.DueDate
AND trd.IsActive = 1
AND (((ctrtemp.JurisdictionLevel = 'County' AND ((ctrtemp.TaxTypeId = ctrtemp.CountyTaxTypeId) OR
(ctrtemp.CountyTaxTypeId IS NULL AND ctrtemp.ImpositionTaxTypeId = ctrtemp.DefaultTaxTypeId)))
OR ((ctrtemp.JurisdictionLevel = 'State' AND ((ctrtemp.TaxTypeId = ctrtemp.StateTaxtypeId) OR
ctrtemp.StateTaxtypeId IS NULL AND ctrtemp.ImpositionTaxTypeId = ctrtemp.DefaultTaxTypeId)))
OR ((ctrtemp.JurisdictionLevel = 'City' AND ((ctrtemp.TaxTypeId = ctrtemp.CityTaxTypeId) OR
ctrtemp.CityTaxTypeId IS NULL AND ctrtemp.ImpositionTaxTypeId = ctrtemp.DefaultTaxTypeId)))
)
OR ctrtemp.CountryShortName <> 'USA')
)T WHERE T.rank = 1
)
AS T ON ctr.TaxRateId = T.TaxRateId
AND T.AssetId = ctr.AssetId
AND T.filter = 1
AND ((ctr.JurisdictionLevel = 'Country' AND ctr.CountryTaxExempt = 0) OR
(ctr.JurisdictionLevel = 'State' AND ctr.StateTaxExempt = 0) OR
(ctr.JurisdictionLevel LIKE '%City%' AND ctr.CityTaxExempt = 0) OR
(ctr.JurisdictionLevel LIKE '%County%' AND ctr.CountyTaxExempt = 0) )
;
DELETE FROM #TaxRates WHERE EffectiveRate IS NULL
;
SELECT AssetId,
CAST(SUM(EffectiveRate) AS DECIMAL(12,10)) EffectiveRate,
TaxBasisType,
UpfrontTaxMode,
JurisdictionLevel
FROM #TaxRates
GROUP BY
AssetId, TaxBasisType, UpfrontTaxMode, JurisdictionLevel;
;
END

GO

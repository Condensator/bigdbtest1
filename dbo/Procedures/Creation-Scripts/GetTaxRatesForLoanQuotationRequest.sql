SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetTaxRatesForLoanQuotationRequest](
@TaxLocationMapper TaxLocationMapper READONLY,
@IsCountryTaxExempt BIT ,
@IsStateTaxExempt BIT ,
@IsCountyTaxExempt BIT ,
@IsCityTaxExempt BIT)
AS
BEGIN
SET NOCOUNT ON
SELECT s.Id AS StateId,
c.Id AS CountryId,
city.Id AS CityId,
county.Id AS CountyId,
td.ReceivableDetailId AS ReceivableDetailId,
td.DueDate,
td.LocationId,
td.ContractId
INTO #LocationMapping
FROM dbo.Jurisdictions AS l
INNER JOIN @TaxLocationMapper AS td ON l.Id = td.JurisdictionId
INNER JOIN dbo.States AS s ON l.StateId = s.Id
INNER JOIN dbo.Countries AS c ON l.CountryId = c.Id
INNER JOIN dbo.Cities AS city ON l.CityId = city.Id
INNER JOIN dbo.Counties AS county ON l.CountyId = county.Id;
SELECT DISTINCT
lm.ReceivableDetailId,
CASE WHEN @IsCountryTaxExempt = 1  OR IsNULL(LocationRule.IsCountryTaxExempt,0) = 1 THEN 1 ELSE 0 END CountryTaxExempt,
CASE WHEN @IsStateTaxExempt =1 OR IsNULL(LocationRule.IsStateTaxExempt,0) = 1 THEN 1 ELSE 0 END StateTaxExempt,
CASE WHEN @IsCountyTaxExempt =1 OR IsNULL(LocationRule.IsCountyTaxExempt,0) = 1 THEN 1 ELSE 0 END CountyTaxExempt,
CASE WHEN @IsCityTaxExempt =1 OR IsNULL(LocationRule.IsCityTaxExempt,0) = 1 THEN 1 ELSE 0 END CityTaxExempt
INTO #Exempt
FROM
#LocationMapping lm
LEFT JOIN Locations l ON lm.LocationId = l.Id
LEFT JOIN TaxExemptRules LocationRule ON l.TaxExemptRuleId = LocationRule.Id
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
lm.ReceivableDetailId,
E.StateTaxExempt
INTO #ConsolidatedTaxRates
FROM #LocationMapping AS lm
INNER JOIN dbo.TaxImpositionTypes AS tit ON lm.CountryId = tit.CountryId AND tit.IsActive = 1
INNER JOIN dbo.TaxTypes AS tt ON tit.TaxTypeId = tt.Id
INNER JOIN dbo.TaxRates AS tr ON tit.Id = tr.TaxImpositionTypeId AND tr.IsActive = 1
INNER JOIN (SELECT DISTINCT Id ,JurisdictionId FROM
(SELECT trh.JurisdictionId, trh.Id CityLevel,trh2.Id CountryLevel,trh3.Id StateLevel,trh4.Id CountyLevel
FROM	  (SELECT j.Id JurisdictionId, t.Id,t.CountryId,t.StateId,t.CityId,t.CountyId FROM dbo.Jurisdictions j
INNER JOIN  dbo.TaxRateHeaders AS t ON j.TaxRateHeaderId = t.Id WHERE t.IsActive = 1) trh
INNER JOIN dbo.TaxRateHeaders trh2 ON trh.CountryId = trh2.CountryId AND trh2.CityId IS NULL AND trh2.StateId IS NULL  AND trh2.CountyId IS NULL AND trh2.IsActive = 1
INNER JOIN dbo.TaxRateHeaders trh3 ON trh.StateId = trh3.StateId AND trh.CountryId = trh3.CountryId  AND trh3.CityId IS NULL  AND trh3.CountyId IS NULL AND trh3.IsActive = 1
INNER JOIN dbo.TaxRateHeaders trh4 ON trh.CountyId = trh4.CountyId AND trh4.CityId IS NULL AND trh.StateId = trh4.StateId AND trh4.CountryId = trh.CountryId AND  trh4.IsActive = 1
) AS T
UNPIVOT ( ID FOR Ids IN (CityLevel,CountryLevel,StateLevel,CountyLevel)) AS UP
) AS trh ON tr.TaxRateHeaderId = trh.Id
AND tr.Id = ANY (SELECT TaxRateId FROM TaxRateDetails
WHERE IsActive = 1
AND TaxRateId = tr.Id)
INNER JOIN dbo.Jurisdictions AS j ON trh.JurisdictionId = j.Id
AND lm.CountryId = j.CountryId
AND j.StateId = lm.StateId
AND j.CityId = lm.CityId
AND j.CountyId = lm.CountyId
AND tit.CountryId = lm.CountryId
AND j.CountryId = lm.CountryId
AND j.IsActive = 1
LEFT JOIN #Exempt E ON lm.ReceivableDetailId = E.ReceivableDetailId;
SELECT ctr.ReceivableDetailId,
SUM(ISNULL(T.Rate,0)) EffectiveRate
FROM #ConsolidatedTaxRates AS ctr
LEFT JOIN (select RANK() OVER ( PARTITION BY T.ReceivableDetailId,T.JurisdictionLevel ORDER BY T.EffectiveDate ,T.Id DESC )filter,* from  (
SELECT RANK() OVER ( PARTITION BY ctrtemp.ReceivableDetailId,ctrtemp.JurisdictionLevel ORDER BY trd.EffectiveDate DESC , trd.Id DESC )rank, trd.*,ctrtemp.ReceivableDetailId,ctrtemp.JurisdictionLevel
FROM dbo.TaxRateDetails AS trd
INNER JOIN #ConsolidatedTaxRates ctrtemp ON trd.TaxRateId = ctrtemp.TaxRateId
AND trd.EffectiveDate <= ctrtemp.DueDate
AND trd.IsActive = 1
UNION
SELECT RANK() OVER ( PARTITION BY ctrtemp.ReceivableDetailId,ctrtemp.JurisdictionLevel ORDER BY trd.EffectiveDate,trd.Id DESC )rank, trd.*,ctrtemp.ReceivableDetailId,ctrtemp.JurisdictionLevel
FROM dbo.TaxRateDetails AS trd
INNER JOIN #ConsolidatedTaxRates ctrtemp ON trd.TaxRateId = ctrtemp.TaxRateId
AND trd.EffectiveDate > ctrtemp.DueDate
AND trd.IsActive = 1
)T  WHERE T.rank = 1
)
AS T ON ctr.TaxRateId = T.TaxRateId
AND T.ReceivableDetailId = ctr.ReceivableDetailId
AND T.filter = 1
AND ((ctr.JurisdictionLevel = 'Country' AND ctr.CountryTaxExempt = 0) OR (ctr.JurisdictionLevel = 'State' AND ctr.StateTaxExempt = 0)
OR (ctr.JurisdictionLevel LIKE '%City%' AND ctr.CityTaxExempt = 0)  OR (ctr.JurisdictionLevel LIKE '%County%' AND ctr.CountyTaxExempt = 0))
GROUP BY
ctr.ReceivableDetailId;
END;

GO

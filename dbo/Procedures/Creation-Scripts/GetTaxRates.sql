SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetTaxRates](
@TaxLocationMapper TaxLocationMapper READONLY)
AS
BEGIN
SET NOCOUNT ON
SELECT s.Id AS StateId,
c.Id AS CountryId,
city.Id AS CityId,
county.Id AS CountyId,
l.TaxRateHeaderId,
l.Id JurisdictionId
INTO #LocationMapping
FROM dbo.Jurisdictions AS l
INNER JOIN @TaxLocationMapper AS td ON l.Id = td.JurisdictionId
INNER JOIN dbo.States AS s ON l.StateId = s.Id
INNER JOIN dbo.Countries AS c ON l.CountryId = c.Id
INNER JOIN dbo.Cities AS city ON l.CityId = city.Id
INNER JOIN dbo.Counties AS county ON l.CountyId = county.Id;
SELECT
trd.Rate EffectiveRate,
trd.EffectiveDate,
tit.TaxJurisdictionLevel JurisdictionLevel,
tt.Name TaxType,
tit.Name ImpositionType,
j.Id JurisdictionId,
tt.Id TaxTypeId,
trd.Id TaxRateDetailId
FROM #LocationMapping AS lm
INNER JOIN dbo.Jurisdictions AS j ON lm.JurisdictionId = j.Id AND j.IsActive = 1
INNER JOIN (SELECT DISTINCT Id ,JurisdictionId FROM
(SELECT trh.JurisdictionId, trh.Id CityLevel,trh2.Id CountryLevel,trh3.Id StateLevel,trh4.Id CountyLevel
FROM	  (SELECT j.Id JurisdictionId, t.Id,t.CountryId,t.StateId,t.CityId,t.CountyId FROM dbo.Jurisdictions j
INNER JOIN  dbo.TaxRateHeaders AS t ON j.TaxRateHeaderId = t.Id WHERE t.IsActive = 1) trh
INNER JOIN dbo.TaxRateHeaders trh2 ON trh.CountryId = trh2.CountryId AND trh2.CityId IS NULL AND trh2.StateId IS NULL  AND trh2.CountyId IS NULL AND trh2.IsActive = 1
INNER JOIN dbo.TaxRateHeaders trh3 ON trh.StateId = trh3.StateId AND trh.CountryId = trh3.CountryId  AND trh3.CityId IS NULL  AND trh3.CountyId IS NULL AND trh3.IsActive = 1
INNER JOIN dbo.TaxRateHeaders trh4 ON trh.CountyId = trh4.CountyId AND trh4.CityId IS NULL AND trh.StateId = trh4.StateId AND trh4.CountryId = trh.CountryId AND  trh4.IsActive = 1
) AS T
UNPIVOT ( ID FOR Ids IN (CityLevel,CountryLevel,StateLevel,CountyLevel)) AS UP
) AS trh ON j.Id = trh.JurisdictionId
AND lm.CountryId = j.CountryId
AND j.StateId = lm.StateId
AND j.CityId = lm.CityId
AND j.CountyId = lm.CountyId
AND j.CountryId = lm.CountryId
INNER JOIN dbo.TaxRates AS tr ON trh.Id = tr.TaxRateHeaderId AND tr.IsActive = 1
INNER JOIN dbo.TaxRateDetails trd ON trd.TaxRateId = tr.Id AND trd.IsActive = 1
INNER JOIN dbo.TaxImpositionTypes AS tit ON tr.TaxImpositionTypeId = tit.Id AND tit.IsActive = 1
INNER JOIN dbo.TaxTypes tt ON tt.Id = tit.TaxTypeId AND tt.IsActive = 1
AND tit.CountryId = lm.CountryId
END;

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InsertNonVertexTaxRateDetails]
(
@JobStepInstanceId BIGINT,
@USAShortName NVARCHAR(40),
@CountryJurisdictionLevel  NVARCHAR(40),
@StateJurisdictionLevel  NVARCHAR(40),
@CountyJurisdictionLevel  NVARCHAR(40),
@CityJurisdictionLevel  NVARCHAR(40)
)
AS
BEGIN
WITH CTE_DistinctJurisdictionIds AS
(
SELECT DISTINCT JurisdictionId,ReceivableDueDate,TaxTypeId,StateTaxTypeId,CountyTaxTypeId,CityTaxTypeId,CountryShortName FROM NonVertexReceivableDetailExtract WHERE JobStepInstanceId = @JobStepInstanceId
)
SELECT
J.CountryId AS CountryId
,J.StateId AS StateId
,J.CityId AS CityId
,J.CountyId AS CountyId
,DJ.ReceivableDueDate
,J.Id JurisdictionId
,CountryTaxTypeId = DJ.TaxTypeId
,StateTaxTypeId =  DJ.StateTaxTypeId
,CountyTaxTypeId = DJ.CountyTaxTypeId
,CityTaxTypeId = DJ.CityTaxTypeId
,CountryShortName
INTO #LocationMapping
FROM CTE_DistinctJurisdictionIds DJ
INNER JOIN Jurisdictions J  ON DJ.JurisdictionId = J.Id
WHERE J.IsActive = 1
SELECT
MAX(TRD.EffectiveDate) AS EffectiveDate
,TIT.TaxJurisdictionLevel JurisdictionLevel
,TT.Id TaxTypeId
,TT.Name TaxType
,TIT.Name ImpositionType
,LM.JurisdictionId
,TRD.Id TaxRateDetailId
,ReceivableDueDate
INTO #EffectiveDates
FROM #LocationMapping AS LM
INNER JOIN TaxRateHeaders TRH ON LM.CountryId = TRH.CountryId AND TRH.StateId IS NULL AND TRH.CountyId IS NULL AND TRH.CityId IS NULL  AND TRH.IsActive = 1
INNER JOIN TaxRates TR ON TRH.Id = TR.TaxRateHeaderId AND TR.IsActive = 1
INNER JOIN TaxRateDetails TRD ON TR.Id =TRD.TaxRateId AND TRD.IsActive = 1
INNER JOIN TaxImpositionTypes TIT ON TR.TaxImpositionTypeId = TIT.Id AND TIT.IsActive = 1
INNER JOIN TaxTypes TT ON  LM.CountryTaxTypeId =TT.Id AND TT.IsActive = 1 AND TIT.CountryId = LM.CountryId AND TIT.TaxTypeId  = TT.Id
WHERE CountryShortName <> @USAShortName  AND  TRD.EffectiveDate <= LM.ReceivableDueDate
GROUP BY TIT.TaxJurisdictionLevel,LM.JurisdictionId,TT.Id, TT.Name, TIT.Name,TRD.Id,TT.Name,ReceivableDueDate
INSERT INTO #EffectiveDates(EffectiveDate,JurisdictionLevel,TaxTypeId,TaxType,ImpositionType,JurisdictionId,TaxRateDetailId,ReceivableDueDate)
SELECT
MIN(TRD.EffectiveDate) AS EffectiveDate
,TIT.TaxJurisdictionLevel JurisdictionLevel
,TT.Id TaxTypeId
,TT.Name TaxType
,TIT.Name ImpositionType
,LM.JurisdictionId
,TRD.Id TaxRateDetailId
,LM.ReceivableDueDate
FROM #LocationMapping AS LM
INNER JOIN TaxRateHeaders TRH ON LM.CountryId = TRH.CountryId AND TRH.StateId IS NULL AND TRH.CountyId IS NULL AND TRH.CityId IS NULL  AND TRH.IsActive = 1
INNER JOIN TaxRates TR ON TRH.Id = TR.TaxRateHeaderId AND TR.IsActive = 1
INNER JOIN TaxRateDetails TRD ON TR.Id =TRD.TaxRateId AND TRD.IsActive = 1
INNER JOIN TaxImpositionTypes TIT ON TR.TaxImpositionTypeId = TIT.Id AND TIT.IsActive = 1
INNER JOIN TaxTypes TT ON  LM.CountryTaxTypeId =TT.Id AND TT.IsActive = 1 AND TIT.CountryId = LM.CountryId AND TIT.TaxTypeId  = TT.Id
LEFT JOIN #EffectiveDates ETR  ON LM.ReceivableDueDate = ETR.ReceivableDueDate	AND LM.JurisdictionId = ETR.JurisdictionId AND ETR.JurisdictionLevel = @CountryJurisdictionLevel
WHERE CountryShortName <> @USAShortName AND TRD.EffectiveDate > LM.ReceivableDueDate AND ETR.ReceivableDueDate IS NULL AND ETR.JurisdictionId IS NULL
GROUP BY TIT.TaxJurisdictionLevel,LM.JurisdictionId,TT.Id, TT.Name, TIT.Name,TRD.Id,TT.Name,LM.ReceivableDueDate
INSERT INTO #EffectiveDates(EffectiveDate,JurisdictionLevel,TaxTypeId,TaxType,ImpositionType,JurisdictionId,TaxRateDetailId,ReceivableDueDate)
SELECT
MAX(TRD.EffectiveDate) AS EffectiveDate
,TIT.TaxJurisdictionLevel JurisdictionLevel
,TT.Id TaxTypeId
,TT.Name TaxType
,TIT.Name ImpositionType
,LM.JurisdictionId
,TRD.Id TaxRateDetailId
,ReceivableDueDate
FROM #LocationMapping AS LM
INNER JOIN TaxRateHeaders TRH ON LM.CountryId = TRH.CountryId AND LM.StateId = TRH.StateId  AND TRH.CountyId IS NULL AND TRH.CityId IS NULL AND TRH.IsActive = 1
INNER JOIN TaxRates TR ON TRH.Id = TR.TaxRateHeaderId AND TR.IsActive = 1
INNER JOIN TaxRateDetails TRD ON TR.Id =TRD.TaxRateId AND TRD.IsActive = 1
INNER JOIN TaxImpositionTypes TIT ON tr.TaxImpositionTypeId = TIT.Id AND TIT.IsActive = 1
INNER JOIN TaxTypes TT ON  LM.StateTaxTypeId =TT.Id AND TT.IsActive = 1 AND TIT.CountryId = LM.CountryId AND TIT.TaxTypeId  = TT.Id
WHERE TRD.EffectiveDate <= LM.ReceivableDueDate
GROUP BY TIT.TaxJurisdictionLevel,LM.JurisdictionId,TT.Id, TT.Name, TIT.Name,TRD.Id,TT.Name,LM.ReceivableDueDate
INSERT INTO #EffectiveDates(EffectiveDate,JurisdictionLevel,TaxTypeId,TaxType,ImpositionType,JurisdictionId,TaxRateDetailId,ReceivableDueDate)
SELECT
MIN(TRD.EffectiveDate) AS EffectiveDate
,TIT.TaxJurisdictionLevel JurisdictionLevel
,TT.Id TaxTypeId
,TT.Name TaxType
,TIT.Name ImpositionType
,LM.JurisdictionId
,TRD.Id TaxRateDetailId
,LM.ReceivableDueDate
FROM #LocationMapping AS LM
INNER JOIN TaxRateHeaders TRH ON LM.CountryId = TRH.CountryId AND LM.StateId = TRH.StateId  AND TRH.CountyId IS NULL AND TRH.CityId IS NULL AND TRH.IsActive = 1
INNER JOIN TaxRates TR ON TRH.Id = TR.TaxRateHeaderId AND TR.IsActive = 1
INNER JOIN TaxRateDetails TRD ON TR.Id =TRD.TaxRateId AND TRD.IsActive = 1
INNER JOIN TaxImpositionTypes TIT ON tr.TaxImpositionTypeId = TIT.Id AND TIT.IsActive = 1
INNER JOIN TaxTypes TT ON  LM.StateTaxTypeId =TT.Id AND TT.IsActive = 1 AND TIT.CountryId = LM.CountryId AND TIT.TaxTypeId  = TT.Id
LEFT JOIN #EffectiveDates ETR  ON LM.ReceivableDueDate = ETR.ReceivableDueDate	AND LM.JurisdictionId = ETR.JurisdictionId AND ETR.JurisdictionLevel = @StateJurisdictionLevel
WHERE TRD.EffectiveDate > LM.ReceivableDueDate AND ETR.ReceivableDueDate IS NULL AND ETR.JurisdictionId IS NULL
GROUP BY TIT.TaxJurisdictionLevel,LM.JurisdictionId,TT.Id, TT.Name, TIT.Name,TRD.Id,TT.Name,LM.ReceivableDueDate
INSERT INTO #EffectiveDates(EffectiveDate,JurisdictionLevel,TaxTypeId,TaxType,ImpositionType,JurisdictionId,TaxRateDetailId,ReceivableDueDate)
SELECT
MAX(TRD.EffectiveDate) AS EffectiveDate
,TIT.TaxJurisdictionLevel JurisdictionLevel
,TT.Id TaxTypeId
,TT.Name TaxType
,TIT.Name ImpositionType
,LM.JurisdictionId
,TRD.Id TaxRateDetailId
,ReceivableDueDate
FROM #LocationMapping AS LM
INNER JOIN TaxRateHeaders TRH ON LM.CountryId = TRH.CountryId AND LM.StateId = TRH.StateId  AND LM.CountyId =TRH.CountyId  AND TRH.CityId IS NULL  AND TRH.IsActive = 1
INNER JOIN TaxRates TR ON TRH.Id = TR.TaxRateHeaderId AND TR.IsActive = 1
INNER JOIN TaxRateDetails TRD ON TR.Id =TRD.TaxRateId AND TRD.IsActive = 1
INNER JOIN TaxImpositionTypes TIT ON tr.TaxImpositionTypeId = TIT.Id AND TIT.IsActive = 1
INNER JOIN TaxTypes TT ON  LM.CountyTaxTypeId =TT.Id AND TT.IsActive = 1 AND TIT.CountryId = LM.CountryId AND TIT.TaxTypeId  = TT.Id
WHERE TRD.EffectiveDate <= LM.ReceivableDueDate
GROUP BY TIT.TaxJurisdictionLevel,LM.JurisdictionId,TT.Id, TT.Name, TIT.Name,TRD.Id,TT.Name,ReceivableDueDate
INSERT INTO #EffectiveDates(EffectiveDate,JurisdictionLevel,TaxTypeId,TaxType,ImpositionType,JurisdictionId,TaxRateDetailId,ReceivableDueDate)
SELECT
MIN(TRD.EffectiveDate) AS EffectiveDate
,TIT.TaxJurisdictionLevel JurisdictionLevel
,TT.Id TaxTypeId
,TT.Name TaxType
,TIT.Name ImpositionType
,LM.JurisdictionId
,TRD.Id TaxRateDetailId
,LM.ReceivableDueDate
FROM #LocationMapping AS LM
INNER JOIN TaxRateHeaders TRH ON LM.CountryId = TRH.CountryId AND LM.StateId = TRH.StateId  AND LM.CountyId =TRH.CountyId  AND TRH.CityId IS NULL  AND TRH.IsActive = 1
INNER JOIN TaxRates TR ON TRH.Id = TR.TaxRateHeaderId AND TR.IsActive = 1
INNER JOIN TaxRateDetails TRD ON TR.Id =TRD.TaxRateId AND TRD.IsActive = 1
INNER JOIN TaxImpositionTypes TIT ON tr.TaxImpositionTypeId = TIT.Id AND TIT.IsActive = 1
INNER JOIN TaxTypes TT ON  LM.CountyTaxTypeId =TT.Id AND TT.IsActive = 1 AND TIT.CountryId = LM.CountryId AND TIT.TaxTypeId  = TT.Id
LEFT JOIN #EffectiveDates ETR  ON LM.ReceivableDueDate = ETR.ReceivableDueDate	AND LM.JurisdictionId = ETR.JurisdictionId AND ETR.JurisdictionLevel = @CountyJurisdictionLevel
WHERE TRD.EffectiveDate > LM.ReceivableDueDate AND ETR.ReceivableDueDate IS NULL AND ETR.JurisdictionId IS NULL
GROUP BY TIT.TaxJurisdictionLevel,LM.JurisdictionId,TT.Id, TT.Name, TIT.Name,TRD.Id,TT.Name,LM.ReceivableDueDate
INSERT INTO #EffectiveDates(EffectiveDate,JurisdictionLevel,TaxTypeId,TaxType,ImpositionType,JurisdictionId,TaxRateDetailId,ReceivableDueDate)
SELECT
MAX(TRD.EffectiveDate) AS EffectiveDate
,TIT.TaxJurisdictionLevel JurisdictionLevel
,TT.Id TaxTypeId
,TT.Name TaxType
,TIT.Name ImpositionType
,LM.JurisdictionId
,TRD.Id TaxRateDetailId
,ReceivableDueDate
FROM #LocationMapping AS LM
INNER JOIN TaxRateHeaders TRH ON LM.CountryId = TRH.CountryId AND LM.StateId = TRH.StateId AND LM.CountyId =TRH.CountyId   AND LM.CityId = TRH.CityId  AND TRH.IsActive = 1
INNER JOIN TaxRates TR ON TRH.Id = TR.TaxRateHeaderId AND TR.IsActive = 1
INNER JOIN TaxRateDetails TRD ON TR.Id =TRD.TaxRateId AND TRD.IsActive = 1
INNER JOIN TaxImpositionTypes TIT ON tr.TaxImpositionTypeId = TIT.Id AND TIT.IsActive = 1
INNER JOIN TaxTypes TT ON  LM.CityTaxTypeId =TT.Id AND TT.IsActive = 1 AND TIT.CountryId = LM.CountryId AND TIT.TaxTypeId  = TT.Id
WHERE TRD.EffectiveDate <= LM.ReceivableDueDate
GROUP BY TIT.TaxJurisdictionLevel,LM.JurisdictionId,TT.Id, TT.Name, TIT.Name,TRD.Id,TT.Name,ReceivableDueDate
INSERT INTO #EffectiveDates(EffectiveDate,JurisdictionLevel,TaxTypeId,TaxType,ImpositionType,JurisdictionId,TaxRateDetailId,ReceivableDueDate)
SELECT
MIN(TRD.EffectiveDate) AS EffectiveDate
,TIT.TaxJurisdictionLevel JurisdictionLevel
,TT.Id TaxTypeId
,TT.Name TaxType
,TIT.Name ImpositionType
,LM.JurisdictionId
,TRD.Id TaxRateDetailId
,LM.ReceivableDueDate
FROM #LocationMapping AS LM
INNER JOIN TaxRateHeaders TRH ON LM.CountryId = TRH.CountryId AND LM.StateId = TRH.StateId AND LM.CountyId =TRH.CountyId   AND LM.CityId = TRH.CityId  AND TRH.IsActive = 1
INNER JOIN TaxRates TR ON TRH.Id = TR.TaxRateHeaderId AND TR.IsActive = 1
INNER JOIN TaxRateDetails TRD ON TR.Id =TRD.TaxRateId AND TRD.IsActive = 1
INNER JOIN TaxImpositionTypes TIT ON tr.TaxImpositionTypeId = TIT.Id AND TIT.IsActive = 1
INNER JOIN TaxTypes TT ON  LM.CityTaxTypeId =TT.Id AND TT.IsActive = 1 AND TIT.CountryId = LM.CountryId AND TIT.TaxTypeId  = TT.Id
LEFT JOIN #EffectiveDates ETR  ON LM.ReceivableDueDate = ETR.ReceivableDueDate	AND LM.JurisdictionId = ETR.JurisdictionId AND ETR.JurisdictionLevel = @CityJurisdictionLevel
WHERE TRD.EffectiveDate > LM.ReceivableDueDate AND ETR.ReceivableDueDate IS NULL AND ETR.JurisdictionId IS NULL
GROUP BY TIT.TaxJurisdictionLevel,LM.JurisdictionId,TT.Id, TT.Name, TIT.Name,TRD.Id,TT.Name,LM.ReceivableDueDate
SELECT
TRD.Rate
,JurisdictionLevel
,TR.TaxTypeId
,TIT.Name AS ImpostionType
,TaxType
,JurisdictionId
,TaxRateDetailId
,ReceivableDueDate
,TRD.EffectiveDate
INTO #EffectiveTaxRates
FROM
(SELECT
LM.JurisdictionId
,JurisdictionLevel
,ED.TaxTypeId
,TaxType
,ED.ReceivableDueDate
,TaxRateDetailId TaxRateDetailId,
ROW_NUMBER() Over (partition by JurisdictionLevel,ED.TaxTypeId, TaxType,LM.JurisdictionId,ED.ReceivableDueDate
order by EffectiveDate Desc,TaxRateDetailId DESC) as RowNumber
FROM #EffectiveDates ED
INNER JOIN #LocationMapping LM ON ED.JurisdictionId = LM.JurisdictionId
where EffectiveDate<= ED.ReceivableDueDate
) TR
INNER JOIN TaxRateDetails TRD ON TR.TaxRateDetailId = TRD.Id AND TRD.IsActive = 1
INNER JOIN TaxRates TRS ON TRD.TaxRateId = TRS.ID AND TRS.IsActive = 1
INNER JOIN TaxImpositionTypes TIT ON TRS.TaxImpositionTypeId = TIT.Id AND TIT.IsActive = 1
where RowNumber = 1
;
INSERT INTO #EffectiveTaxRates(Rate,JurisdictionLevel,TaxTypeId,ImpostionType,TaxType,JurisdictionId,TaxRateDetailId,ReceivableDueDate,EffectiveDate)
SELECT
TRD.Rate
,JurisdictionLevel
,TR.TaxTypeId
,TIT.Name AS ImpostionType
,TaxType
,JurisdictionId
,TaxRateDetailId
,ReceivableDueDate
,TRD.EffectiveDate
FROM
(SELECT
LM.JurisdictionId
,JurisdictionLevel
,ED.TaxTypeId
,TaxType
,ED.ReceivableDueDate
,TaxRateDetailId TaxRateDetailId,
ROW_NUMBER() Over (partition by JurisdictionLevel,ED.TaxTypeId, TaxType,LM.JurisdictionId,ED.ReceivableDueDate
order by EffectiveDate ASC,TaxRateDetailId DESC) as RowNumber
FROM #EffectiveDates ED
INNER JOIN #LocationMapping LM ON ED.JurisdictionId = LM.JurisdictionId
where EffectiveDate > ED.ReceivableDueDate
) TR
INNER JOIN TaxRateDetails TRD ON TR.TaxRateDetailId = TRD.Id AND TRD.IsActive = 1
INNER JOIN TaxRates TRS ON TRD.TaxRateId = TRS.ID AND TRS.IsActive = 1
INNER JOIN TaxImpositionTypes TIT ON TRS.TaxImpositionTypeId = TIT.Id AND TIT.IsActive = 1
where RowNumber = 1
;
WITH CTE_EffectiveTaxRateResults
AS
(SELECT ROW_NUMBER() OVER (partition by ETR.JurisdictionLevel,ETR.TaxTypeId, ETR.TaxType,ETR.JurisdictionId,ETR.ReceivableDueDate ORDER BY EffectiveDate DESC) AS RowNumber
,ETR.Rate
,ETR.JurisdictionLevel
,ETR.TaxTypeId
,ETR.ImpostionType
,TaxType
,JurisdictionId
,TaxRateDetailId
,ReceivableDueDate
FROM #EffectiveTaxRates ETR)
SELECT * INTO #EffectiveTaxRateResult
from CTE_EffectiveTaxRateResults res
WHERE res.RowNumber = 1
INSERT INTO NonVertexTaxRateDetailExtract([ReceivableDetailId],[AssetId],[ImpositionType],[JurisdictionLevel],
[TaxType],[EffectiveRate],[TaxTypeId],[JobStepInstanceId])
SELECT
RD.ReceivableDetailId
,RD.AssetId
,ET.ImpostionType
,JurisdictionLevel
,TaxType
,Rate
,RD.TaxTypeId
,@JobStepInstanceId
FROM #EffectiveTaxRateResult ET
INNER JOIN NonVertexReceivableDetailExtract RD ON RD.JobStepInstanceId = @JobStepInstanceId AND ET.ReceivableDueDate = RD.ReceivableDueDate  AND ET.TaxTypeId = RD.TaxTypeId
AND ET.JurisdictionId = RD.JurisdictionId AND  ET.JurisdictionLevel = @CountryJurisdictionLevel
INSERT INTO NonVertexTaxRateDetailExtract([ReceivableDetailId],[AssetId],[ImpositionType],[JurisdictionLevel],
[TaxType],[EffectiveRate],[TaxTypeId],[JobStepInstanceId])
SELECT
RD.ReceivableDetailId
,RD.AssetId
,ET.ImpostionType
,JurisdictionLevel
,TaxType
,Rate
,RD.StateTaxTypeId
,@JobStepInstanceId
FROM #EffectiveTaxRateResult ET
INNER JOIN NonVertexReceivableDetailExtract RD ON RD.JobStepInstanceId = @JobStepInstanceId AND ET.ReceivableDueDate = RD.ReceivableDueDate  AND  ET.TaxTypeId = RD.StateTaxTypeId
AND ET.JurisdictionId = RD.JurisdictionId AND ET.JurisdictionLevel = @StateJurisdictionLevel
INSERT INTO NonVertexTaxRateDetailExtract([ReceivableDetailId],[AssetId],[ImpositionType],[JurisdictionLevel],
[TaxType],[EffectiveRate],[TaxTypeId],[JobStepInstanceId])
SELECT
RD.ReceivableDetailId
,RD.AssetId
,ET.ImpostionType
,JurisdictionLevel
,TaxType
,Rate
,RD.CountyTaxTypeId
,@JobStepInstanceId
FROM #EffectiveTaxRateResult ET
INNER JOIN NonVertexReceivableDetailExtract RD ON ET.ReceivableDueDate = RD.ReceivableDueDate  AND  ET.TaxTypeId = RD.CountyTaxTypeId
AND ET.JurisdictionId = RD.JurisdictionId AND RD.JobStepInstanceId = @JobStepInstanceId AND ET.JurisdictionLevel = @CountyJurisdictionLevel
INSERT INTO NonVertexTaxRateDetailExtract([ReceivableDetailId],[AssetId],[ImpositionType],[JurisdictionLevel],
[TaxType],[EffectiveRate],[TaxTypeId],[JobStepInstanceId])
SELECT
RD.ReceivableDetailId
,RD.AssetId
,ET.ImpostionType
,JurisdictionLevel
,TaxType
,Rate
,RD.CityTaxTypeId
,@JobStepInstanceId
FROM #EffectiveTaxRateResult ET
INNER JOIN NonVertexReceivableDetailExtract RD ON ET.ReceivableDueDate = RD.ReceivableDueDate  AND ET.TaxTypeId = RD.CityTaxTypeId
AND ET.JurisdictionId = RD.JurisdictionId AND RD.JobStepInstanceId = @JobStepInstanceId AND ET.JurisdictionLevel = @CityJurisdictionLevel
END;

GO

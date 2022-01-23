SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InsertAssetLocationsForTaxBasisUpdate]
(
@BatchSize BIGINT,
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET,
@JobStepInstanceId BIGINT,
@BatchCount BIGINT OUTPUT
)
AS
BEGIN
CREATE TABLE #TaxAreaHistory
(
LocationId BIGINT,
TaxAreaId  BIGINT NULL,
TaxAreaEffectiveDate DATE,
LocationTaxAreaHistoryId BIGINT NULL
);
CREATE TABLE #LocationsToBeProcessed
(
CustomerId			BIGINT,
LegalEntityId		BIGINT,
EffectiveFromDate	DATE,
ContractId			BIGINT,
AssetId				BIGINT,
LineItemId			NVARCHAR(100),
LocationId			BIGINT,
ContractType		NVARCHAR(100),
AssetLocationsId	BIGINT
)


SELECT AL.Id AS AssetLocationsId,
AL.LocationId,
AL.EffectiveFromDate,
AL.AssetId
INTO #AssetLocations
FROM AssetLocations AL WHERE (AL.TaxBasisType = '_' OR AL.TaxBasisType IS NULL) AND AL.IsActive = 1

IF EXISTS (Select 1 FROM #AssetLocations)
BEGIN

SELECT AssetId INTO #AssetIds FROM #AssetLocations
GROUP BY AssetId;


SELECT
LF.ContractId,
LF.LegalEntityId,
LF.CustomerId,
LA.AssetId,
CASE
WHEN LA.IsTaxDepreciable = 1 THEN 'FMV'
ELSE 'CSC'
END AS ContractType
INTO #CTE_ContractDetails
FROM LeaseFinances LF
INNER JOIN LeaseAssets LA ON LA.LeaseFinanceId = LF.Id AND LA.IsActive = 1  AND LF.IsCurrent = 1
INNER JOIN #AssetIds AId ON AId.AssetId = LA.AssetId
WHERE (LA.IsActive = 1 OR LA.TerminationDate IS NULL)


INSERT INTO #LocationsToBeProcessed
(CustomerId, LegalEntityId, EffectiveFromDate, ContractId, AssetId, LineItemId, LocationId, ContractType, AssetLocationsId)
SELECT
CD.CustomerId,
CD.LegalEntityId,
AL.EffectiveFromDate,
CD.ContractId,
CD.AssetId,
CAST(AL.AssetLocationsId AS VARCHAR(50)) LineItemId,
AL.LocationId,
CD.ContractType,
AL.AssetLocationsId AS AssetLocationsId
FROM #AssetLocations AL
JOIN #CTE_ContractDetails CD ON AL.AssetId = CD.AssetId;

INSERT INTO #LocationsToBeProcessed
(CustomerId, LegalEntityId, EffectiveFromDate, ContractId, AssetId, LineItemId, LocationId, ContractType, AssetLocationsId)
SELECT
A.CustomerId,
A.LegalEntityId,
AL.EffectiveFromDate,
CAST(NULL AS BIGINT),
CAST(NULL AS BIGINT),
CAST(AL.AssetLocationsId AS VARCHAR(50)) LineItemId,
AL.LocationId,
CAST(NULL AS NVARCHAR),
AL.AssetLocationsId AS AssetLocationsId
FROM #AssetLocations AL
JOIN Assets A ON AL.AssetId = A.Id
LEFT JOIN #LocationsToBeProcessed LTP ON LTP.AssetLocationsId = AL.AssetLocationsId
WHERE LTP.AssetLocationsId IS NULL
AND A.CustomerId IS NOT NULL;


SELECT
LTBP.LocationId
INTO #CTE_DistinctLocation
FROM #LocationsToBeProcessed LTBP
GROUP BY LTBP.LocationId

INSERT INTO #TaxAreaHistory
(
LocationId
,TaxAreaId
,TaxAreaEffectiveDate
,LocationTaxAreaHistoryId
)
SELECT
L.LocationId
,LH.TaxAreaId
,LH.TaxAreaEffectiveDate
,LH.Id
FROM #CTE_DistinctLocation L
INNER JOIN LocationTaxAreaHistories LH ON L.LocationId = LH.LocationId
;
SELECT
L.LocationId
,L.EffectiveFromDate
,MAX(TA.TaxAreaEffectiveDate) AS TaxAreaEffectiveDate
INTO #LocationNearestTaxAreaEffectiveDate
FROM #TaxAreaHistory TA
INNER JOIN #LocationsToBeProcessed L on TA.LocationId = L.LocationId
WHERE TA.TaxAreaEffectiveDate <= L.EffectiveFromDate
GROUP BY
L.LocationId
,L.EffectiveFromDate
;
INSERT INTO #LocationNearestTaxAreaEffectiveDate
SELECT
L.LocationId
,L.EffectiveFromDate
,MIN(TA.TaxAreaEffectiveDate) AS TaxAreaEffectiveDate
FROM #TaxAreaHistory TA
INNER JOIN #LocationsToBeProcessed L on TA.LocationId = L.LocationId
LEFT JOIN #LocationNearestTaxAreaEffectiveDate LDT
ON L.LocationId = LDT.LocationId AND L.EffectiveFromDate = LDT.EffectiveFromDate
WHERE TA.TaxAreaEffectiveDate > L.EffectiveFromDate
AND LDT.LocationId IS NULL
GROUP BY
L.LocationId
,L.EffectiveFromDate
;
SELECT
LDE.LocationId
,LDE.EffectiveFromDate
,MAX(LDH.LocationTaxAreaHistoryId) LocationTaxAreaHistoryId
INTO #LocationTaxAreaDetails
FROM #LocationNearestTaxAreaEffectiveDate AS LDE
INNER JOIN #TaxAreaHistory LDH ON LDE.LocationId = LDH.LocationId
GROUP BY
LDE.LocationId
,LDE.EffectiveFromDate
INSERT INTO AssetLocationTaxBasisProcessingDetail_Extract
(
City,
Country,
DueDate,
LeaseType,
LeaseUniqueID,
ContractId,
Company,
LegalEntityName,
Currency,
ToState,
AssetId,
LineItemId,
LocationId,
ContractType,
CustomerNumber,
TaxAreaId,
AssetLocationId,
BatchId,
CreatedById,
CreatedTime,
JobStepInstanceId,
LocationCode
)
SELECT
L.City,
C.ShortName Country,
LTP.EffectiveFromDate DueDate,
DPT.LeaseType,
CT.SequenceNumber LeaseUniqueID,
CT.Id,
LE.TaxPayer Company,
LE.Name LegalEntityName,
CC.ISO Currency,
S.ShortName ToState,
LTP.AssetId,
LTP.LineItemId,
LTP.LocationId,
LTP.ContractType,
P.PartyNumber CustomerNumber,
TAH.TaxAreaId,
LTP.AssetLocationsId,
((ROW_NUMBER() OVER(ORDER BY (SELECT 0))) - 1) / @BatchSize + 1,
@CreatedById,
@CreatedTime,
@JobStepInstanceId,
L.Code
FROM #LocationsToBeProcessed LTP
JOIN #LocationTaxAreaDetails LTAD ON LTP.LocationId = LTAD.LocationId AND LTP.EffectiveFromDate = LTAD.EffectiveFromDate
JOIN #TaxAreaHistory TAH ON LTAD.LocationTaxAreaHistoryId = TAH.LocationTaxAreaHistoryId
JOIN Locations L ON L.Id = LTP.LocationId
JOIN States S ON S.Id = L.StateId
JOIN Countries C ON C.Id = S.CountryId
JOIN Parties P ON P.Id = LTP.CustomerId
JOIN LegalEntities LE ON LE.Id = LTP.LegalEntityId
LEFT JOIN Contracts CT ON LTP.ContractId = CT.Id
LEFT JOIN DealProductTypes DPT ON CT.DealProductTypeId = DPT.Id
LEFT JOIN Currencies CR ON CR.Id = CT.CurrencyId
LEFT JOIN CurrencyCodes CC ON CC.Id = CR.CurrencyCodeId
SET @BatchCount =
(
SELECT MAX(BatchId) AS BatchCount
FROM AssetLocationTaxBasisProcessingDetail_Extract
WHERE JobStepInstanceId = @JobStepInstanceId
)
END

IF @BatchCount IS NULL
SET @BatchCount = 0

END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[InsertCustomerLocationForTaxBasisUpdate]
(
@BatchSize BIGINT,
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET,
@JobStepInstanceId BIGINT,
@BatchCount BIGINT OUTPUT
)
AS
BEGIN

DECLARE @TaxSourceTypeVertex NVARCHAR(10);
SET @TaxSourceTypeVertex = 'Vertex';

CREATE TABLE #TaxAreaHistory
(
LocationId BIGINT,
TaxAreaId  BIGINT NULL,
TaxAreaEffectiveDate DATE,
LocationTaxAreaHistoryId BIGINT NULL
);
SELECT
CL.Id AS CustomerLocationId,
CL.LocationId,
CL.EffectiveFromDate,
CL.CustomerId,
C.Id ContractId,
LF.LegalEntityId
INTO #LocationsToBeProcessed
FROM CustomerLocations CL
INNER JOIN LeaseFinances LF ON CL.CustomerId = LF.CustomerId AND LF.IsCurrent = 1
INNER JOIN Contracts C ON LF.ContractId = C.Id
LEFT JOIN ContractCustomerLocations CCL ON C.Id = CCL.ContractId AND CL.Id = CCL.CustomerLocationId
WHERE CCL.ContractId IS NULL;
WITH CTE_DistinctLocations AS
(
SELECT DISTINCT LocationId
FROM #LocationsToBeProcessed
)
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
FROM CTE_DistinctLocations  L
INNER JOIN LocationTaxAreaHistories LH ON L.LocationId = LH.LocationId;
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
,L.EffectiveFromDate;
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
INNER JOIN #TaxAreaHistory LDH ON LDE.LocationId = LDH.LocationId AND LDE.TaxAreaEffectiveDate = LDH.TaxAreaEffectiveDate
GROUP BY
LDE.LocationId
,LDE.EffectiveFromDate;
INSERT INTO CustomerLocationTaxBasisProcessingDetail_Extract
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
LineItemId,
LocationId,
ContractType,
CustomerNumber,
TaxAreaId,
CustomerLocationId,
BatchId,
CreatedById,
CreatedTime,
JobStepInstanceId,
LocationCode
)
SELECT
L.City,
C.ShortName AS Country,
LTA.EffectiveFromDate,
DPT.LeaseType,
CT.SequenceNumber AS LeaseUniqueId,
LTP.ContractId,
LE.TaxPayer AS Company,
LE.Name AS LegalEntityName,
CC.ISO Currency,
S.ShortName AS State,
CONCAT(LTP.CustomerLocationId, '-', LTP.ContractId) AS LineItemId,
LTA.LocationId,
'FMV' AS ContractType,
P.PartyNumber AS CustomerNumber,
LTH.TaxAreaId,
LTP.CustomerLocationId,
(ROW_NUMBER() OVER(ORDER BY (SELECT(0))) - 1) / @BatchSize + 1,
@CreatedById,
@CreatedTime,
@JobStepInstanceId,
L.Code
FROM #LocationsToBeProcessed LTP
INNER JOIN #LocationTaxAreaDetails LTA ON LTP.LocationId = LTA.LocationId AND LTP.EffectiveFromDate = LTA.EffectiveFromDate
INNER JOIN #TaxAreaHistory LTH on LTA.LocationTaxAreaHistoryId = LTH.LocationTaxAreaHistoryId
INNER JOIN Locations L ON LTP.LocationId = L.Id
INNER JOIN States S ON L.StateId = S.Id
INNER JOIN Countries C ON S.CountryId = C.Id AND C.TaxSourceType = @TaxSourceTypeVertex
INNER JOIN Parties P ON LTP.CustomerId = P.Id
INNER JOIN Contracts CT ON LTP.ContractId = CT.Id
INNER JOIN LegalEntities LE ON LTP.LegalEntityId = LE.Id
INNER JOIN Currencies CR ON CT.CurrencyId = CR.Id
INNER JOIN CurrencyCodes CC ON CR.CurrencyCodeId = CC.Id
INNER JOIN DealProductTypes DPT ON CT.DealProductTypeId = DPT.Id
SET @BatchCount =
(
SELECT MAX(BatchId) AS BatchCount
FROM CustomerLocationTaxBasisProcessingDetail_Extract
WHERE JobStepInstanceId = @JobStepInstanceId
)
IF @BatchCount IS NULL
SET @BatchCount = 0
END

GO

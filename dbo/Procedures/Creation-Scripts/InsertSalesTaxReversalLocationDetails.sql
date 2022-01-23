SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[InsertSalesTaxReversalLocationDetails]
(
	@JobStepInstanceId BIGINT
)
AS
BEGIN
SET NOCOUNT ON;

DECLARE @TaxSourceTypeVertex NVARCHAR(10);
SET @TaxSourceTypeVertex = 'Vertex';

WITH CTE_DistinctLocations AS
(
SELECT DISTINCT LocationId FROM ReversalReceivableDetail_Extract WHERE ErrorCode IS NULL AND JobStepInstanceId = @JobStepInstanceId AND ReceivableTaxType = 'SalesTax'
)
INSERT INTO ReversalLocationDetail_Extract
(LocationId, Country, MainDivision, StateId, City, LocationCode, IsVertexSupportedLocation, CreatedById, CreatedTime, JobStepInstanceId,AcquisitionLocationTaxAreaId)
SELECT LocationId = LocationId,
Country = C.ShortName,
MainDivision = S.ShortName,
StateId = S.Id,
City = L.City,
LocationCode = L.Code,
IsVertexSupportedLocation = CAST(CASE WHEN C.TaxSourceType = @TaxSourceTypeVertex THEN 1 ELSE 0 END AS BIT),
CreatedById = 1,
CreatedTime = SYSDATETIMEOFFSET(),
@JobStepInstanceId,
AcquisitionLocationTaxAreaId = L.TaxAreaId
FROM CTE_DistinctLocations R
INNER JOIN Locations L ON R.LocationId = L.Id
INNER JOIN States S ON L.StateId = S.Id
INNER JOIN Countries C ON S.CountryId = C.Id
;WITH CTE_DistinctAcquisitionLocations AS
(
SELECT DISTINCT AcquisitionLocationId AS LocationId FROM ReversalReceivableDetail_Extract RD
LEFT JOIN ReversalLocationDetail_Extract RL ON RD.AcquisitionLocationId = RL.LocationId AND RL.JobStepInstanceId = @JobStepInstanceId
WHERE RD.ErrorCode IS NULL AND RD.JobStepInstanceId = @JobStepInstanceId AND RL.Id IS NULL AND RD.ReceivableTaxType = 'SalesTax'
)
INSERT INTO ReversalLocationDetail_Extract
(LocationId, Country, MainDivision, StateId, City, LocationCode, IsVertexSupportedLocation,AcquisitionLocationTaxAreaId, CreatedById, CreatedTime, JobStepInstanceId)
SELECT LocationId = LocationId,
Country = C.ShortName,
MainDivision = S.ShortName,
StateId = S.Id,
City = L.City,
LocationCode = L.Code,
IsVertexSupportedLocation = CAST(CASE WHEN C.TaxSourceType = @TaxSourceTypeVertex THEN 1 ELSE 0 END AS BIT),
AcquisitionLocationTaxAreaId = L.TaxAreaId,
CreatedById = 1,
CreatedTime = SYSDATETIMEOFFSET(),
@JobStepInstanceId
FROM CTE_DistinctAcquisitionLocations R
INNER JOIN Locations L ON R.LocationId = L.Id
INNER JOIN States S ON L.StateId = S.Id
INNER JOIN Countries C ON S.CountryId = C.Id
WHERE L.TaxAreaId IS NOT NULL AND L.JurisdictionId IS NULL
UPDATE ReversalReceivableDetail_Extract
SET IsVertexSupported = IsVertexSupportedLocation
FROM ReversalReceivableDetail_Extract RD
INNER JOIN ReversalLocationDetail_Extract LD ON RD.LocationId = LD.LocationId AND RD.JobStepInstanceId = LD.JobStepInstanceId
WHERE RD.ErrorCode IS NULL AND RD.JobStepInstanceId = @JobStepInstanceId
END

GO

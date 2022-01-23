SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[InsertLocationDetails]
(
@UALCode NVARCHAR(100),
@LocationStatusApproved NVARCHAR(100),
@LocationStatusReAssess NVARCHAR(100),
@IsTaxSourceVertex BIT,
@JobStepInstanceId BIGINT,
@TPNFCode NVARCHAR(100),
@GLNFCode NVARCHAR(100),
@ReceivableTaxTypeSalesTax	NVARCHAR(20)
)
AS
BEGIN
SET NOCOUNT ON

DECLARE @TaxSourceTypeVertex NVARCHAR(10);
SET @TaxSourceTypeVertex  = 'Vertex';

;WITH CTE_UniqueLocation AS (
SELECT
PreviousLocationId as LocationId
FROM
SalesTaxReceivableDetailExtract
WHERE JobStepInstanceId = @JobStepInstanceId
AND ReceivableTaxType = @ReceivableTaxTypeSalesTax
UNION
SELECT
LocationId
FROM
SalesTaxReceivableDetailExtract
WHERE JobStepInstanceId = @JobStepInstanceId
AND ReceivableTaxType = @ReceivableTaxTypeSalesTax
)
SELECT
LocationId
INTO #LocationDetails
FROM CTE_UniqueLocation;

INSERT INTO SalesTaxLocationDetailExtract
([LocationId],[LocationCode], [City], [StateShortName], [CountryShortName], [LocationStatus],
[IsVertexSupportedLocation], [StateId], [JobStepInstanceId],[AcquisitionLocationTaxAreaId])
SELECT
L.Id AS LocationId
,L.Code AS LocationCode
,L.City
,S.ShortName AS StateShortName
,C.ShortName AS CountryShortName
,L.ApprovalStatus AS LocationStatus
,CAST(CASE WHEN C.TaxSourceType = @TaxSourceTypeVertex THEN 1 ELSE 0 END AS BIT) AS IsVertexSupportedLocation
,S.Id AS StateId
,@JobStepInstanceId
,L.TaxAreaId
FROM #LocationDetails LD
INNER JOIN Locations L ON LD.LocationId = L.Id
INNER JOIN States S ON L.StateId = S.Id
INNER JOIN Countries C ON S.CountryId = C.Id
;WITH CTE_AcuqisitionLocationDetails
AS
(
SELECT DISTINCT AcquisitionLocationId AS LocationId FROM SalesTaxAssetDetailExtract AD
LEFT JOIN SalesTaxLocationDetailExtract LD ON AD.AcquisitionLocationId = LD.LocationId AND LD.JobStepInstanceId = @JobStepInstanceId
WHERE AD.JobStepInstanceId = @JobStepInstanceId AND LD.Id IS NULL
)
INSERT INTO SalesTaxLocationDetailExtract
([LocationId],[LocationCode], [City], [StateShortName], [CountryShortName], [LocationStatus],
[IsVertexSupportedLocation], [AcquisitionLocationTaxAreaId],[StateId],[JobStepInstanceId])
SELECT
L.Id AS LocationId
,L.Code AS LocationCode
,L.City
,S.ShortName AS StateShortName
,C.ShortName AS CountryShortName
,L.ApprovalStatus AS LocationStatus
,CASE WHEN C.TaxSourceType = @TaxSourceTypeVertex THEN 1 ELSE 0 END AS IsVertexSupportedLocation
,L.TaxAreaId AS AcquisitionLocationTaxAreaId
,S.Id AS StateId
,@JobStepInstanceId
FROM CTE_AcuqisitionLocationDetails LD
INNER JOIN Locations L ON LD.LocationId = L.Id
INNER JOIN States S ON L.StateId = S.Id
INNER JOIN Countries C ON S.CountryId = C.Id
WHERE L.TaxAreaId IS NOT NULL AND L.JurisdictionId IS NULL

UPDATE ST
SET IsVertexSupported = CASE WHEN @IsTaxSourceVertex = 0 THEN 0 ELSE  SL.IsVertexSupportedLocation END,
StateId = SL.StateId,
InvalidErrorCode = CASE WHEN SL.LocationStatus = @LocationStatusApproved OR SL.LocationStatus = @LocationStatusReAssess THEN InvalidErrorCode ELSE @UALCode END
FROM SalesTaxReceivableDetailExtract ST
INNER JOIN SalesTaxLocationDetailExtract SL ON ST.LocationId = SL.LocationId AND ST.JobStepInstanceId = SL.JobStepInstanceId
AND SL.JobStepInstanceId = @JobStepInstanceId;

UPDATE SalesTaxReceivableDetailExtract	SET InvalidErrorCode =  @GLNFCode
FROM SalesTaxReceivableDetailExtract
WHERE InvalidErrorCode IS NULL AND GLTemplateId IS NULL AND  JobStepInstanceId = @JobStepInstanceId

UPDATE SalesTaxReceivableDetailExtract	SET InvalidErrorCode =  @TPNFCode
FROM SalesTaxReceivableDetailExtract
WHERE InvalidErrorCode IS NULL AND TaxPayer IS NULL AND  JobStepInstanceId = @JobStepInstanceId
AND IsVertexSupported=1;

END

GO

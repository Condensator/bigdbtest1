SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InsertNonVertexLocationDetails]
(
@JobStepInstanceId BIGINT
)
AS
BEGIN
SET NOCOUNT ON
;WITH CTE_UniqueLocation AS (
SELECT
PreviousLocationId as LocationId
FROM
SalesTaxReceivableDetailExtract
WHERE IsVertexSupported =0  AND InvalidErrorCode IS NULL AND  JobStepInstanceId = @JobStepInstanceId
UNION
SELECT
LocationId
FROM
SalesTaxReceivableDetailExtract
WHERE IsVertexSupported =0  AND InvalidErrorCode IS NULL AND  JobStepInstanceId = @JobStepInstanceId
)
SELECT
LocationId
INTO #LocationDetails
FROM CTE_UniqueLocation;
INSERT INTO NonVertexLocationDetailExtract
([LocationId],[JurisdictionId],[TaxBasisType],[StateId],[StateShortName],[CountryId],[CountryShortName],
[UpfrontTaxMode],[IsCountryTaxExempt],[IsStateTaxExempt],[IsCountyTaxExempt],[IsCityTaxExempt],[JobStepInstanceId])
SELECT
L.Id AS LocationId
,L.JurisdictionId AS JurisdictionId
,L.TaxBasisType AS TaxBasisType
,S.Id AS StateId
,S.ShortName AS StateShortName
,C.Id As CountryId
,C.ShortName AS CountryShortName
,L.UpfrontTaxMode AS UpfrontTaxMode
,TE.IsCountryTaxExempt AS IsCountryTaxExempt
,TE.IsStateTaxExempt AS IsStateTaxExempt
,TE.IsCountyTaxExempt AS IsCountyExempt
,TE.IsCityTaxExempt AS IsCityTaxExempt
,@JobStepInstanceId
FROM #LocationDetails LD
INNER JOIN Locations L ON LD.LocationId = L.Id
INNER JOIN States S ON L.StateId = S.Id
INNER JOIN Countries C ON S.CountryId = C.Id
INNER JOIN TaxExemptRules TE ON L.TaxExemptRuleId = TE.Id
WHERE L.JurisdictionId IS NOT NULL 
;
END

GO

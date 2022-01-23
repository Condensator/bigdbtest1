SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InsertNonVertexAssetDetails]
(
@ContractEntityType  NVarChar(10),
@JobStepInstanceId BIGINT
)
AS
BEGIN
SET NOCOUNT ON;
WITH CTE_AssetDetails AS
(
SELECT DISTINCT	AssetId FROM SalesTaxReceivableDetailExtract
WHERE IsVertexSupported =0 AND InvalidErrorCode IS NULL AND JobStepInstanceId = @JobStepInstanceId
)
SELECT
CA.AssetId
,A.IsServiceOnly
,ISNULL(TE.IsCountryTaxExempt,0) AS IsCountryTaxExempt
,ISNULL(TE.IsStateTaxExempt,0) AS IsStateTaxExempt
,ISNULL(TE.IsCountyTaxExempt,0) AS IsCountyTaxExempt
,ISNULL(TE.IsCityTaxExempt,0) AS IsCityTaxExempt
INTO #NonVertexAssetDetails
FROM CTE_AssetDetails CA
INNER  JOIN Assets A  ON CA.AssetId = A.Id
INNER JOIN TaxExemptRules TE ON TE.Id = A.TaxExemptRuleId;
WITH CTE_AssetDetails AS
(
SELECT DISTINCT	AssetId,ContractId
FROM SalesTaxReceivableDetailExtract
WHERE IsVertexSupported =0 AND InvalidErrorCode IS NULL AND EntityType = @ContractEntityType AND JobStepInstanceId = @JobStepInstanceId
)
SELECT
LA.Id AS LeaseAssetId
,LA.AssetId
,CA.ContractId
,StateTaxTypeId
,CountyTaxTypeId
,CityTaxTypeId
,LA.SalesTaxRemittanceResponsibility
,CASE WHEN STRH.SalesTaxRemittanceResponsibility IS NULL THEN '_' ELSE  STRH.SalesTaxRemittanceResponsibility END AS PreviousSalesTaxRemittanceResponsibility
,STRH.EffectiveTillDate AS PreviousSalesTaxRemittanceResponsibilityEffectiveTillDate
INTO #NonVertexLeaseAssetDetails
FROM CTE_AssetDetails CA
INNER JOIN SalesTaxAssetDetailExtract SA ON CA.ContractId = SA.ContractId AND CA.AssetId = SA.AssetId AND JobStepInstanceId = @JobStepInstanceId
INNER JOIN LeaseFinances LF ON LF.ContractID = CA.ContractID AND LF.IsCurrent =1
INNER JOIN LeaseAssets LA ON LF.Id = LA.LeaseFinanceID AND SA.LeaseAssetId = LA.Id
LEFT JOIN ContractSalesTaxRemittanceResponsibilityHistories STRH ON STRH.AssetId = SA.AssetId AND LF.ContractId = STRH.ContractId
INSERT INTO NonVertexAssetDetailExtract([AssetId],[LeaseAssetId],[ContractId],[IsCountryTaxExempt],[IsStateTaxExempt],[IsCountyTaxExempt],
[IsCityTaxExempt],[StateTaxTypeId],[CountyTaxTypeId],[CityTaxTypeId],[JobStepInstanceId],[SalesTaxRemittanceResponsibility],[PreviousSalesTaxRemittanceResponsibility],[PreviousSalesTaxRemittanceResponsibilityEffectiveTillDate])
SELECT
A.AssetId
,LA.LeaseAssetId
,LA.ContractId
,A.IsCountryTaxExempt
,A.IsStateTaxExempt
,A.IsCountyTaxExempt
,A.IsCityTaxExempt
,LA.StateTaxTypeId
,LA.CountyTaxTypeId
,LA.CityTaxTypeId
,@JobStepInstanceId
,LA.SalesTaxRemittanceResponsibility
,LA.PreviousSalesTaxRemittanceResponsibility
,LA.PreviousSalesTaxRemittanceResponsibilityEffectiveTillDate
FROM #NonVertexAssetDetails A
LEFT JOIN #NonVertexLeaseAssetDetails LA on A.AssetId = LA.AssetID
END

GO

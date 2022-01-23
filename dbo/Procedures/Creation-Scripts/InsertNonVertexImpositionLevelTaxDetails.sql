SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InsertNonVertexImpositionLevelTaxDetails]
(
@CountryJurisdictionLevel NVarChar(7),
@StateJurisdictionLevel NVarChar(7),
@CountyJurisdictionLevel NVarChar(7),
@CityJurisdictionLevel NVarChar(7),
@Exempt NVarChar(7),
@UCTaxBasisTypeName NVarChar(5),
@URTaxBasisTypeName NVarChar(5),
@JobStepInstanceId BIGINT
)
AS
BEGIN
INSERT INTO NonVertexImpositionLevelTaxDetailExtract([ReceivableDetailId],[AssetId],[ImpositionType],
[JurisdictionLevel],[EffectiveRate],[IsTaxExempt],[TaxTypeId],[JobStepInstanceId])
SELECT
RD.ReceivableDetailId
,RD.AssetId
,TR.ImpositionType
,TR.JurisdictionLevel
,TR.EffectiveRate
,CASE WHEN 
 (RD.IsCapitalizedRealAsset =1 AND RD.IsCapitalizedFirstRealAsset = 0 AND (RD.TaxBasisType = @UCTaxBasisTypeName OR RD.TaxBasisType = @URTaxBasisTypeName))
OR RD.IsPrepaidUpfrontTax =1  AND (RD.TaxBasisType = @UCTaxBasisTypeName OR RD.TaxBasisType = @URTaxBasisTypeName)
OR RD.IsExemptAtAsset =1
OR RD.IsExemptAtReceivableCode =1
OR RD.IsExemptAtSundry =1
OR RD.ClassCode = @Exempt
OR RD.SalesTaxRemittanceResponsibility ='Customer'
OR STE.IsCountryTaxExempt =1
THEN 1 
ELSE 0 END  AS IsTaxExempt
,TR.TaxTypeId
,RD.JobStepInstanceId
FROM  NonVertexReceivableDetailExtract RD
INNER JOIN NonVertexTaxRateDetailExtract TR ON RD.ReceivableDetailId = TR.ReceivableDetailId AND (RD.AssetId = TR.AssetId OR RD.AssetId IS NULL) AND TR.JobStepInstanceId = @JobStepInstanceId
INNER JOIN NonVertexTaxExemptExtract  STE ON RD.ReceivableDetailId = STE.ReceivableDetailId AND (RD.AssetId = STE.AssetId OR RD.AssetId IS NULL) AND STE.JobStepInstanceId = @JobStepInstanceId
WHERE  TR.JurisdictionLevel = @CountryJurisdictionLevel AND TR.TaxTypeId = RD.TaxTypeId AND RD.JobStepInstanceId =@JobStepInstanceId
INSERT INTO NonVertexImpositionLevelTaxDetailExtract([ReceivableDetailId],[AssetId],[ImpositionType],
[JurisdictionLevel],[EffectiveRate],[IsTaxExempt],[TaxTypeId],[JobStepInstanceId])
SELECT
RD.ReceivableDetailId
,RD.AssetId
,TR.ImpositionType
,TR.JurisdictionLevel
,TR.EffectiveRate
,CASE WHEN 
 (RD.IsCapitalizedRealAsset =1 AND RD.IsCapitalizedFirstRealAsset = 0 AND (RD.TaxBasisType = @UCTaxBasisTypeName OR RD.TaxBasisType = @URTaxBasisTypeName))
OR RD.IsPrepaidUpfrontTax =1  AND (RD.TaxBasisType = @UCTaxBasisTypeName OR RD.TaxBasisType = @URTaxBasisTypeName)
OR RD.IsExemptAtAsset =1
OR RD.IsExemptAtReceivableCode =1
OR RD.IsExemptAtSundry =1
OR RD.ClassCode = @Exempt
OR RD.SalesTaxRemittanceResponsibility ='Customer'
OR STE.IsStateTaxExempt =1
THEN 1 
ELSE 0 END  AS IsTaxExempt
,TR.TaxTypeId
,RD.JobStepInstanceId
FROM  NonVertexReceivableDetailExtract RD
INNER JOIN NonVertexTaxRateDetailExtract TR ON RD.ReceivableDetailId = TR.ReceivableDetailId AND (RD.AssetId = TR.AssetId OR RD.AssetId IS NULL) AND TR.JobStepInstanceId = @JobStepInstanceId
INNER JOIN NonVertexTaxExemptExtract  STE ON RD.ReceivableDetailId = STE.ReceivableDetailId AND (RD.AssetId = STE.AssetId OR RD.AssetId IS NULL) AND STE.JobStepInstanceId = @JobStepInstanceId
WHERE  TR.JurisdictionLevel = @StateJurisdictionLevel AND (TR.TaxTypeId = RD.StateTaxTypeId OR TR.TaxTypeId = RD.TaxTypeId) AND RD.JobStepInstanceId =@JobStepInstanceId
INSERT INTO NonVertexImpositionLevelTaxDetailExtract([ReceivableDetailId],[AssetId],[ImpositionType],
[JurisdictionLevel],[EffectiveRate],[IsTaxExempt],[TaxTypeId],[JobStepInstanceId])
SELECT
RD.ReceivableDetailId
,RD.AssetId
,TR.ImpositionType
,TR.JurisdictionLevel
,TR.EffectiveRate
,CASE WHEN 
 (RD.IsCapitalizedRealAsset =1 AND RD.IsCapitalizedFirstRealAsset = 0 AND (RD.TaxBasisType = @UCTaxBasisTypeName OR RD.TaxBasisType = @URTaxBasisTypeName))
OR RD.IsPrepaidUpfrontTax =1  AND (RD.TaxBasisType = @UCTaxBasisTypeName OR RD.TaxBasisType = @URTaxBasisTypeName)
OR RD.IsExemptAtAsset =1
OR RD.IsExemptAtReceivableCode =1
OR RD.IsExemptAtSundry =1
OR RD.ClassCode = @Exempt
OR RD.SalesTaxRemittanceResponsibility ='Customer'
OR STE.IsCountyTaxExempt =1
THEN 1 
ELSE 0 END  AS IsTaxExempt
,TR.TaxTypeId
,RD.JobStepInstanceId
FROM  NonVertexReceivableDetailExtract RD
INNER JOIN NonVertexTaxRateDetailExtract TR ON RD.ReceivableDetailId = TR.ReceivableDetailId AND (RD.AssetId = TR.AssetId OR RD.AssetId IS NULL) AND TR.JobStepInstanceId = @JobStepInstanceId
INNER JOIN NonVertexTaxExemptExtract  STE ON RD.ReceivableDetailId = STE.ReceivableDetailId AND (RD.AssetId = STE.AssetId OR RD.AssetId IS NULL) AND STE.JobStepInstanceId = @JobStepInstanceId
WHERE  TR.JurisdictionLevel = @CountyJurisdictionLevel AND (TR.TaxTypeId = RD.CountyTaxTypeId OR TR.TaxTypeId = RD.TaxTypeId) AND RD.JobStepInstanceId =@JobStepInstanceId
INSERT INTO NonVertexImpositionLevelTaxDetailExtract([ReceivableDetailId],[AssetId],[ImpositionType],
[JurisdictionLevel],[EffectiveRate],[IsTaxExempt],[TaxTypeId],[JobStepInstanceId])
SELECT
RD.ReceivableDetailId
,RD.AssetId
,TR.ImpositionType
,TR.JurisdictionLevel
,TR.EffectiveRate
,CASE WHEN 
 (RD.IsCapitalizedRealAsset =1 AND RD.IsCapitalizedFirstRealAsset = 0 AND (RD.TaxBasisType = @UCTaxBasisTypeName OR RD.TaxBasisType = @URTaxBasisTypeName))
OR RD.IsPrepaidUpfrontTax =1  AND (RD.TaxBasisType = @UCTaxBasisTypeName OR RD.TaxBasisType = @URTaxBasisTypeName)
OR RD.IsExemptAtAsset =1
OR RD.IsExemptAtReceivableCode =1
OR RD.IsExemptAtSundry =1
OR RD.ClassCode = @Exempt
OR RD.SalesTaxRemittanceResponsibility ='Customer'
OR STE.IsCityTaxExempt =1
THEN 1 
ELSE 0 END  AS IsTaxExempt
,TR.TaxTypeId
,RD.JobStepInstanceId
FROM  NonVertexReceivableDetailExtract RD
INNER JOIN NonVertexTaxRateDetailExtract TR ON RD.ReceivableDetailId = TR.ReceivableDetailId AND (RD.AssetId = TR.AssetId OR RD.AssetId IS NULL) AND TR.JobStepInstanceId = @JobStepInstanceId
INNER JOIN NonVertexTaxExemptExtract  STE ON RD.ReceivableDetailId = STE.ReceivableDetailId AND (RD.AssetId = STE.AssetId OR RD.AssetId IS NULL) AND STE.JobStepInstanceId = @JobStepInstanceId
WHERE  TR.JurisdictionLevel = @CityJurisdictionLevel AND (TR.TaxTypeId = RD.CityTaxTypeId OR TR.TaxTypeId = RD.TaxTypeId) AND RD.JobStepInstanceId =@JobStepInstanceId

END

GO

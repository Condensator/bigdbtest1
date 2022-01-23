SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CalculateNonVertexTaxes]
(
@UCTaxBasisType NVarChar(5),
@URTaxBasisType NVarChar(5),
@UCDMVTaxBasisType NVarChar(5),
@URDMVTaxBasisType NVarChar(5),
@STTaxBasisType NVarChar(5),
@UpFrontTaxModeIsAll NVarChar(6),
@Taxable nvarchar(7),
@Exempt NVarChar(7) ,
@PrepaidUpfrontTaxExemptionType NVarChar(27),
@CapitalizedUpfrontTaxExemptionType NVarChar(27),
@UpfrontTaxExemptionType NVarChar(27),
@CustomerTaxExemptionType NVarChar(27),
@AssetTaxExemptionType NVarChar(27),
@UnknownTaxExemptionType NVarChar(27),
@SundryTaxExemptionType NVarChar(27),
@ReceivableCodeTaxExemptionType NVarChar(27),
@CountryJurisdictionLevel nvarchar(7),
@StateJurisdictionLevel nvarchar(7),
@CountyJurisdictionLevel nvarchar(7),
@CityJurisdictionLevel nvarchar(7),
@JobStepInstanceId BIGINT,
@CustomerDirectRemitTaxExemptionType NVARCHAR(27),
@CustomerSalesTaxReponsibility NVARCHAR(10)
)
AS
BEGIN
CREATE TABLE #NonVertexTaxes (
[ReceivableId] BigInt  NOT NULL,
[ReceivableDetailId] BigInt  NOT NULL,
[AssetId] BigInt  NULL,
[Currency] NVarChar(40)  NOT NULL,
[CalculatedTax] Decimal(16,2)  NOT NULL,
[TaxResult] NVarChar(40)  NOT NULL,
[EffectiveRate] Decimal(10,6) NOT NULL,
[JurisdictionId] BigInt  NOT NULL,
[JurisdictionLevel] NVarChar(40)  NOT NULL,
[ImpositionType] NVarChar(40)  NOT NULL,
[ExtendedPrice] Decimal(16,2)  NOT NULL,
[IsCapitalizedFirstRealAsset]	BIT NOT NULL,
[TaxTypeId] BIGINT NOT NULL,
[IsCashBased]		BIT NOT NULL
)
INSERT INTO #NonVertexTaxes([ReceivableId],[ReceivableDetailId],[AssetId],[Currency],[CalculatedTax],[TaxResult],
[EffectiveRate],[JurisdictionId],[JurisdictionLevel],[ImpositionType]
,[ExtendedPrice],[IsCapitalizedFirstRealAsset],[TaxTypeId],[IsCashBased] )
SELECT
ReceivableId
,RD.ReceivableDetailId
,RD.AssetId
,Currency
,CalculatedTax = dbo.RoundUpToMidPointEven((AssetCost * EffectiveRate), (CASE WHEN Currency='JPY' THEN 0 ELSE 2 END))
,TaxResult = @Taxable
,EffectiveRate = EffectiveRate
,RD.JurisdictionId
,JurisdictionLevel
,ImpositionType
,RD.ExtendedPrice
,RD.IsCapitalizedFirstRealAsset
,IL.TaxTypeId
,RD.IsCashBased
FROM NonVertexImpositionLevelTaxDetailExtract IL
INNER JOIN NonVertexReceivableDetailExtract RD ON IL.ReceivableDetailId = RD.ReceivableDetailId AND (IL.AssetId = RD.AssetId OR IL.AssetId IS NULL) AND RD.JobStepInstanceId = @JobStepInstanceId
WHERE IsTaxExempt = 0 AND IsUpFrontApplicable =1 AND (StateShortName != PreviousStateShortName OR PreviousStateShortName IS NULL) AND (RD.TaxBasisType = @UCTaxBasisType)
AND (UpfrontTaxMode = @UpFrontTaxModeIsAll OR UpfrontTaxMode = JurisdictionLevel) AND IL.JobStepInstanceId = @JobStepInstanceId;
INSERT INTO #NonVertexTaxes([ReceivableId],[ReceivableDetailId],[AssetId],[Currency],[CalculatedTax],[TaxResult],
[EffectiveRate],[JurisdictionId],[JurisdictionLevel],[ImpositionType],[ExtendedPrice],
[IsCapitalizedFirstRealAsset],[TaxTypeId],[IsCashBased] )
SELECT
ReceivableId
,RD.ReceivableDetailId
,RD.AssetId
,Currency
,CalculatedTax = dbo.RoundUpToMidPointEven((FairMarketValue  * EffectiveRate),(CASE WHEN Currency='JPY' THEN 0 ELSE 2 END))
,TaxResult = @Taxable
,EffectiveRate = EffectiveRate
,RD.JurisdictionId
,JurisdictionLevel
,ImpositionType
,RD.ExtendedPrice
,RD.IsCapitalizedFirstRealAsset
,IL.TaxTypeId
,RD.IsCashBased
FROM NonVertexImpositionLevelTaxDetailExtract IL
INNER JOIN NonVertexReceivableDetailExtract RD ON IL.ReceivableDetailId = RD.ReceivableDetailId AND (IL.AssetId = RD.AssetId OR IL.AssetId IS NULL) AND RD.JobStepInstanceId = @JobStepInstanceId
WHERE IsTaxExempt = 0 AND  IsUpFrontApplicable =1  AND (StateShortName != PreviousStateShortName OR PreviousStateShortName IS NULL) AND (RD.TaxBasisType = @URTaxBasisType)
AND (UpfrontTaxMode = @UpFrontTaxModeIsAll OR UpfrontTaxMode = JurisdictionLevel) AND IL.JobStepInstanceId = @JobStepInstanceId;
INSERT INTO #NonVertexTaxes([ReceivableId],[ReceivableDetailId],[AssetId],[Currency],[CalculatedTax],[TaxResult],
[EffectiveRate],[JurisdictionId],[JurisdictionLevel],[ImpositionType],[ExtendedPrice],
[IsCapitalizedFirstRealAsset],[TaxTypeId],[IsCashBased] )
SELECT
ReceivableId
,RD.ReceivableDetailId
,RD.AssetId
,Currency
,CalculatedTax = dbo.RoundUpToMidPointEven((ExtendedPrice  * EffectiveRate),(CASE WHEN Currency='JPY' THEN 0 ELSE 2 END))
,TaxResult = @Taxable
,EffectiveRate = EffectiveRate
,RD.JurisdictionId
,JurisdictionLevel
,ImpositionType
,RD.ExtendedPrice
,0
,IL.TaxTypeId
,RD.IsCashBased
FROM NonVertexImpositionLevelTaxDetailExtract IL
INNER JOIN NonVertexReceivableDetailExtract RD ON IL.ReceivableDetailId = RD.ReceivableDetailId AND (IL.AssetId = RD.AssetId OR IL.AssetId IS NULL) AND RD.JobStepInstanceId = @JobStepInstanceId
WHERE IsTaxExempt = 0  AND (RD.TaxBasisType = @STTaxBasisType OR (IsUpFrontApplicable =0 AND UpfrontTaxMode != @UpFrontTaxModeIsAll AND UpfrontTaxMode != JurisdictionLevel))  AND IL.JobStepInstanceId = @JobStepInstanceId;
INSERT INTO #NonVertexTaxes([ReceivableId],[ReceivableDetailId],[AssetId],[Currency],[CalculatedTax],[TaxResult],
[EffectiveRate],[JurisdictionId],[JurisdictionLevel],[ImpositionType],[ExtendedPrice],
[IsCapitalizedFirstRealAsset],[TaxTypeId],[IsCashBased] )
SELECT
ReceivableId
,RD.ReceivableDetailId
,RD.AssetId
,Currency
,CalculatedTax = dbo.RoundUpToMidPointEven((ExtendedPrice  * EffectiveRate),(CASE WHEN Currency='JPY' THEN 0 ELSE 2 END))
,TaxResult = @Taxable
,EffectiveRate = EffectiveRate
,RD.JurisdictionId
,JurisdictionLevel
,ImpositionType
,RD.ExtendedPrice
,0
,IL.TaxTypeId
,RD.IsCashBased
FROM NonVertexImpositionLevelTaxDetailExtract IL
INNER JOIN NonVertexReceivableDetailExtract RD ON IL.ReceivableDetailId = RD.ReceivableDetailId AND (IL.AssetId = RD.AssetId OR IL.AssetId IS NULL) AND RD.JobStepInstanceId = @JobStepInstanceId
WHERE IsTaxExempt = 0 AND IsUpFrontApplicable =1  AND (StateShortName != PreviousStateShortName OR PreviousStateShortName IS NULL) AND (UpfrontTaxMode != @UpFrontTaxModeIsAll AND UpfrontTaxMode != JurisdictionLevel) AND IL.JobStepInstanceId = @JobStepInstanceId;
INSERT INTO #NonVertexTaxes([ReceivableId],[ReceivableDetailId],[AssetId],[Currency],[CalculatedTax],[TaxResult],
[EffectiveRate],[JurisdictionId],[JurisdictionLevel],[ImpositionType],[ExtendedPrice],
[IsCapitalizedFirstRealAsset],[TaxTypeId],[IsCashBased] )
SELECT
RD.ReceivableId
,RD.ReceivableDetailId
,RD.AssetId
,RD.Currency
,CalculatedTax = dbo.RoundUpToMidPointEven(RD.ExtendedPrice  * IL.EffectiveRate,(CASE WHEN RD.Currency='JPY' THEN 0 ELSE 2 END))
,TaxResult = @Exempt
,EffectiveRate = IL.EffectiveRate
,RD.JurisdictionId
,IL.JurisdictionLevel
,IL.ImpositionType
,RD.ExtendedPrice
,0
,IL.TaxTypeId
,RD.IsCashBased
FROM NonVertexImpositionLevelTaxDetailExtract IL
INNER JOIN NonVertexReceivableDetailExtract RD ON IL.ReceivableDetailId = RD.ReceivableDetailId AND (IL.AssetId = RD.AssetId OR IL.AssetId IS NULL) AND RD.JobStepInstanceId = @JobStepInstanceId
LEFT JOIN #NonVertexTaxes TC ON  IL.ReceivableDetailId =TC.ReceivableDetailId AND (IL.AssetId = TC.AssetId OR IL.AssetId IS NULL) AND (IL.AssetId = TC.AssetId OR IL.AssetId IS NULL) AND IL.JurisdictionLevel = TC.JurisdictionLevel
WHERE  TC.ReceivableDetailId IS NULL AND IL.JobStepInstanceId = @JobStepInstanceId;
UPDATE #NonVertexTaxes
SET TaxResult = @Exempt, EffectiveRate = 0.0
WHERE CalculatedTax = 0.00 AND TaxResult = @Taxable
AND ExtendedPrice <> 0.00
UPDATE #NonVertexTaxes
SET CalculatedTax = 0.00
WHERE IsCapitalizedFirstRealAsset = 1
SELECT
RD.ReceivableId
,RD.ReceivableDetailId
,RD.AssetId
,RD.Currency
,T.CalculatedTax
,T.TaxResult
,T.EffectiveRate
,RD.JurisdictionId
,T.JurisdictionLevel
,T.ImpositionType
,RD.ExtendedPrice
,RD.FairMarketValue
,RD.AssetCost
,ExemptionType = CASE
WHEN RD.SalesTaxRemittanceResponsibility = @CustomerSalesTaxReponsibility AND Rd.IsUpfrontApplicable = 1
THEN @CustomerDirectRemitTaxExemptionType
WHEN RD.IsPrepaidUpfrontTax = 1 AND (RD.TaxBasisType = @UCTaxBasisType
OR RD.TaxBasisType = @URTaxBasisType)
THEN  @PrepaidUpfrontTaxExemptionType
WHEN (RD.IsCapitalizedSalesTaxAsset = 1
OR (RD.IsCapitalizedRealAsset = 1 AND RD.IsCapitalizedFirstRealAsset = 0)
AND (RD.TaxBasisType = @UCTaxBasisType OR RD.TaxBasisType = @URTaxBasisType))
THEN @CapitalizedUpfrontTaxExemptionType
WHEN  RD.TaxBasisType != @STTaxBasisType AND T.TaxResult != @Taxable
THEN  @UpfrontTaxExemptionType
WHEN RD.ClassCode = @Exempt
THEN  @CustomerTaxExemptionType
WHEN RD.IsExemptAtAsset = 1
THEN  @AssetTaxExemptionType
WHEN RD.IsExemptAtReceivableCode = 1
THEN  @ReceivableCodeTaxExemptionType
WHEN STE.IsCountryTaxExempt= 1 AND T.JurisdictionLevel = @CountryJurisdictionLevel
THEN  CountryTaxExemptRule
WHEN STE.IsStateTaxExempt = 1 AND T.JurisdictionLevel = @StateJurisdictionLevel
THEN  StateTaxExemptRule
WHEN STE.IsCountyTaxExempt = 1 AND T.JurisdictionLevel = @CountyJurisdictionLevel
THEN  CountyTaxExemptRule
WHEN STE.IsCityTaxExempt = 1 AND T.JurisdictionLevel = @CityJurisdictionLevel
THEN  CityTaxExemptRule
WHEN RD.IsExemptAtSundry = 1
THEN  @SundryTaxExemptionType
ELSE
@UnknownTaxExemptionType
END
INTO #NonVertexTaxWithExemptionType
FROM #NonVertexTaxes  T
INNER JOIN NonVertexTaxExemptExtract  STE ON T.ReceivableDetailId = STE.ReceivableDetailId AND (T.AssetId = STE.AssetId  OR T.AssetId IS NULL) AND STE.JobStepInstanceId = @JobStepInstanceId
INNER JOIN NonVertexReceivableDetailExtract RD ON T.ReceivableDetailId = RD.ReceivableDetailId AND (T.AssetId = RD.AssetId OR T.AssetId IS NULL) AND  RD.JobStepInstanceId = @JobStepInstanceId;
SELECT
T.ReceivableId
,T.ReceivableDetailId
,T.AssetId
,T.Currency
,CalculatedTax =CASE WHEN T.TaxResult = @Taxable THEN T.CalculatedTax
WHEN T.TaxResult = @Exempt THEN   0.0
END
,T.TaxResult
,EffectiveRate = CASE WHEN T.TaxResult = @Taxable THEN T.EffectiveRate
WHEN T.TaxResult = @Exempt  THEN   0.0
END
,T.JurisdictionId
,T.JurisdictionLevel
,T.ImpositionType
,ExemptionType
,ExemptionAmount =  CASE WHEN T.TaxResult = @Taxable THEN 0.0
WHEN T.TaxResult = @Exempt THEN
CASE WHEN TE.FairMarketValue <> 0.00 THEN TE.FairMarketValue
WHEN TE.AssetCost <> 0.00 THEN TE.AssetCost
ELSE TE.ExtendedPrice
END
END
,TaxTypeId = T.TaxTypeId
,T.IsCashBased
INTO #NonVertexTaxesWithExemptDetails
FROM #NonVertexTaxes T
INNER JOIN #NonVertexTaxWithExemptionType  TE ON T.ReceivableDetailId = TE.ReceivableDetailId AND (T.AssetId = TE.AssetId OR T.AssetId IS NULL)
AND T.JurisdictionLevel = TE.JurisdictionLevel AND T.ImpositionType = TE.ImpositionType
INSERT INTO NonVertexTaxExtract([ReceivableId],[ReceivableDetailId],[AssetId],[Currency],[CalculatedTax],[TaxResult],
[EffectiveRate],[JurisdictionId],[JurisdictionLevel],[ImpositionType],[ExemptionType],
[ExemptionAmount],[TaxTypeId],[JobStepInstanceId],[IsCashBased])
SELECT
ReceivableId
,ReceivableDetailId
,AssetId
,Currency
,CalculatedTax
,TaxResult
,EffectiveRate
,JurisdictionId
,JurisdictionLevel
,ImpositionType
,ExemptionType
,ExemptionAmount
,TaxTypeId
,@JobStepInstanceId
,IsCashBased
FROM #NonVertexTaxesWithExemptDetails
END

GO

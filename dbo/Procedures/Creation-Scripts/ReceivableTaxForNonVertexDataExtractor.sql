SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ReceivableTaxForNonVertexDataExtractor]
(
	@CreatedById BIGINT,
	@JobStepInstanceId BIGINT,
	@ErrorMessageType NVARCHAR(22),
	@UpFrontTaxModeIsAll NVARCHAR(20),
	@UCTaxBasisType NVARCHAR(5),
	@URTaxBasisType NVARCHAR(5)
)
AS
BEGIN

	With CTE_DistinctReceivableIds AS
	(
		SELECT DISTINCT ReceivableId, LegalEntityId, GLTemplateId FROM  NonVertexReceivableDetailExtract
		WHERE JobStepInstanceId = @JobStepInstanceId
	)

	SELECT
	R.ReceivableId,
	MAX(GLTemplateId) GLTemplateId
	INTO #SalesTaxGLTemplateDetail
	FROM CTE_DistinctReceivableIds R
	GROUP BY
	R.ReceivableId;

	SELECT
	T.ReceivableId
	,Currency
	,SUM(CalculatedTax) as Amount
	,IsCashBased
	INTO #ReceivableTaxAmount
	FROM NonVertexTaxExtract T
	WHERE JobStepInstanceId =@JobStepInstanceId
	Group By T.ReceivableId,Currency,IsCashBased

	SELECT
	T.ReceivableId
	,Currency
	,Amount
	,GL.GLTemplateId
	,IsCashBased
	FROM #ReceivableTaxAmount T
	LEFT JOIN  #SalesTaxGLTemplateDetail GL ON T.ReceivableId = GL.ReceivableId

	SELECT
	ReceivableId
	,ReceivableDetailId
	,AssetId
	,Currency
	,SUM(CalculatedTax) as Amount
	INTO #ReceivableTaxDetailsParameters
	FROM NonVertexTaxExtract
	WHERE JobStepInstanceId =@JobStepInstanceId
	Group By ReceivableId,ReceivableDetailId,AssetId,Currency;


	SELECT
	RD.UpfrontTaxMode,
	RD.TaxBasisType,
	RD.ExtendedPrice,
	RD.Currency NonVertexExtract_Currency,
	RD.FairMarketValue, 
	RD.AssetCost, 
	RD.AssetLocationId,
	RD.LocationId,
	RD.AssetId,
	TR.ReceivableDetailId,
	TR.Amount ,
	TR.Currency TaxDetail_Currency,
	TR.ReceivableId
	FROM #ReceivableTaxDetailsParameters TR
	INNER JOIN NonVertexReceivableDetailExtract RD ON TR.ReceivableDetailId = RD.ReceivableDetailId AND (TR.AssetId = RD.AssetId OR TR.AssetId IS NULL) AND RD.JobStepInstanceId = @JobStepInstanceId


	SELECT
	TC.ExemptionType,
	convert(decimal(10,6), 0) AS ExemptionRate,
	TC.ExemptionAmount AS ExemptionAmount_Amount,
	TC.Currency AS ExemptionAmount_Currency,
	CASE
	WHEN RD.IsUpFrontApplicable = 1 THEN
	CASE WHEN RD.UpfrontTaxMode = @UpFrontTaxModeIsAll OR RD.UpfrontTaxMode = TC.JurisdictionLevel  THEN
	CASE WHEN RD.FairMarketValue <> 0.00 THEN RD.FairMarketValue ELSE RD.AssetCost END
	ELSE
	RD.ExtendedPrice
	END
	ELSE RD.ExtendedPrice
	END
	AS TaxableBasisAmount_Amount,
	TC.Currency AS TaxableBasisAmount_Currency,
	TC.EffectiveRate AS AppliedTaxRate,
	TC.CalculatedTax AS Amount_Amount,
	TC.Currency AS Amount_Currency,
	TC.CalculatedTax AS Balance_Amount,
	TC.Currency AS Balance_Currency,
	TC.CalculatedTax AS EffectiveBalance_Amount,
	TC.Currency AS EffectiveBalance_Currency,
	TC.ImpositionType AS ExternalTaxImpositionType,
	@CreatedById AS CreatedById,
	SYSDATETIMEOFFSET() AS CreatedTime,
	TaxTypeId =TC.TaxTypeId,
	ExternalJurisdictionLevelId = (SELECT Id FROM TaxAuthorityConfigs WHERE UPPER(Description) =  UPPER(TC.JurisdictionLevel)),
	CAST(1 AS BIT) AS IsActive,
	RD.TaxBasisType,
	TC.ReceivableDetailId,
	TC.AssetId
	FROM NonVertexTaxExtract  TC
	INNER JOIN NonVertexReceivableDetailExtract RD ON TC.ReceivableDetailId = RD.ReceivableDetailId AND (TC.AssetId = RD.AssetId OR TC.AssetId IS NULL) AND TC.JobStepInstanceId = RD.JobStepInstanceId AND RD.JobStepInstanceId = @JobStepInstanceId
	WHERE RD.JobStepInstanceId = @JobStepInstanceId

	DROP TABLE #SalesTaxGLTemplateDetail;
	DROP TABLE #ReceivableTaxAmount;
	DROP TABLE #ReceivableTaxDetailsParameters;
END

GO

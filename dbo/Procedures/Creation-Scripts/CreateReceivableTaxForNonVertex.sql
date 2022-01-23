SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CreateReceivableTaxForNonVertex]
(
	@TempReceivableTaxesParameters TempReceivableTaxesParameters READONLY,
	@TempReceivableTaxDetailsParameters TempReceivableTaxDetailsParameters READONLY,
	@ReceivableTaxImpositionParameters ReceivableTaxImpositionParameters READONLY,
	@CreatedById BIGINT,
	@UCTaxBasisType NVARCHAR(5),
	@URTaxBasisType NVARCHAR(5)
)
AS  
     BEGIN  
	 SET NOCOUNT ON 

	 CREATE TABLE #InsertedReceivableTaxes
	(
		ReceivableTaxId BIGINT,
		ReceivableId    BIGINT
	);
	CREATE TABLE #InsertedReceivableTaxDetails
	(
		ReceivableTaxDetailId	BIGINT,
		ReceivableDetailId		BIGINT,
		ReceivableDetailAssetId BIGINT NULL,
		TaxBasisType            NVARCHAR (5) NOT NULL,
		FairMarketValue_Amount  DECIMAL (16, 2) NOT NULL,
		Cost_Amount             DECIMAL (16, 2) NOT NULL
	);


	 SELECT * INTO #TempReceivableTaxesParameters FROM @TempReceivableTaxesParameters
	 CREATE INDEX IX_1 ON #TempReceivableTaxesParameters(ReceivableId)
	 
	 SELECT * INTO #TempReceivableTaxDetailsParameters FROM @TempReceivableTaxDetailsParameters
	 CREATE INDEX IX_2 ON #TempReceivableTaxDetailsParameters(ReceivableId)

	 SELECT * INTO #ReceivableTaxImpositionParameters FROM @ReceivableTaxImpositionParameters
	 CREATE INDEX IX_3 ON #ReceivableTaxImpositionParameters(ReceivableDetailId) Include (AssetId)


	MERGE [ReceivableTaxes] AS TargetReceivableTax
	USING #TempReceivableTaxesParameters AS SourceReceivableTax
	ON (TargetReceivableTax.ReceivableId = SourceReceivableTax.ReceivableId AND TargetReceivableTax.IsActive = 1)
	WHEN NOT MATCHED THEN
	INSERT
	([CreatedById],
	[CreatedTime],
	[ReceivableId],
	[IsActive],
	[Amount_Amount],
	[Amount_Currency],
	[Balance_Amount],
	[Balance_Currency],
	[EffectiveBalance_Amount],
	[EffectiveBalance_Currency],
	[IsDummy]  ,
	[IsGLPosted],
	[GlTemplateId],
	[IsCashBased]
	)
	VALUES(@CreatedById,
	SYSDATETIMEOFFSET(),
	ReceivableId,
	1,
	Amount,
	Currency ,
	Amount,
	Currency,
	Amount,
	Currency,
	0,
	0,
	GLTemplateId,
	IsCashBased)
	WHEN MATCHED THEN
	UPDATE SET TargetReceivableTax.UpdatedById = 1, TargetReceivableTax.UpdatedTime = SYSDATETIMEOFFSET(),
	TargetReceivableTax.Amount_Amount = TargetReceivableTax.Amount_Amount + SourceReceivableTax.Amount,
	TargetReceivableTax.Balance_Amount = TargetReceivableTax.Balance_Amount + SourceReceivableTax.Amount,
	TargetReceivableTax.EffectiveBalance_Amount = TargetReceivableTax.EffectiveBalance_Amount + SourceReceivableTax.Amount
	OUTPUT INSERTED.Id AS ReceivableTaxId, INSERTED.ReceivableId AS ReceivableId INTO #InsertedReceivableTaxes;


	SELECT 
	TRTDP.UpfrontTaxMode,
	TRTDP.TaxBasisType,
	TRTDP.ExtendedPrice,
	TRTDP.NonVertexExtract_Currency,
	TRTDP.FairMarketValue, 
	TRTDP.AssetCost, 
	TRTDP.AssetLocationId,
	TRTDP.LocationId,
	TRTDP.AssetId,
	TRTDP.ReceivableDetailId,
	IRT.ReceivableTaxId, 
	TRTDP.Amount ,
	TRTDP.TaxDetail_Currency
	INTO #Temp_ReceivableTaxDetailsParameters
	FROM #TempReceivableTaxDetailsParameters TRTDP
	INNER JOIN #InsertedReceivableTaxes IRT ON TRTDP.ReceivableId = IRT.ReceivableId 


	MERGE [ReceivableTaxDetails] AS TargetReceivableTaxDetail
	USING (Select * FROM #Temp_ReceivableTaxDetailsParameters WHERE AssetId Is NOT NULL )AS SourceReceivableTaxDetail
	ON (TargetReceivableTaxDetail.ReceivableDetailId = SourceReceivableTaxDetail.ReceivableDetailId AND 
	TargetReceivableTaxDetail.AssetId = SourceReceivableTaxDetail.AssetId AND TargetReceivableTaxDetail.IsActive = 1 ) 
	WHEN NOT MATCHED THEN
	INSERT  
	([UpfrontTaxMode],
	[TaxBasisType],
	[Revenue_Amount],
	[Revenue_Currency],
	[FairMarketValue_Amount],
	[FairMarketValue_Currency],
	[Cost_Amount],
	[Cost_Currency],
	[TaxAreaId],
	[IsActive],
	[ManuallyAssessed],
	[CreatedById],
	[CreatedTime],
	[AssetLocationId],
	[LocationId],
	[AssetId],
	[ReceivableDetailId],
	[ReceivableTaxId],
	[IsGLPosted],
	[Amount_Amount],
	[Amount_Currency],
	[Balance_Amount],
	[Balance_Currency],
	[EffectiveBalance_Amount],
	[EffectiveBalance_Currency],
	[UpfrontPayableFactor]
	)
	VALUES
	(
	UpfrontTaxMode,
	TaxBasisType,
	ExtendedPrice,
	NonVertexExtract_Currency,
	FairMarketValue,
	NonVertexExtract_Currency,
	AssetCost,
	NonVertexExtract_Currency,
	NULL,
	1,
	0,
	@CreatedById,
	SYSDATETIMEOFFSET(),
	AssetLocationId,
	LocationId,
	AssetId,
	ReceivableDetailId,
	ReceivableTaxId,
	0,
	Amount,
	TaxDetail_Currency,
	Amount,
	TaxDetail_Currency,
	Amount,
	TaxDetail_Currency,
	CASE WHEN TAXBasisType<>'ST' AND TaxBasisType<>'_' THEN 1 ELSE 0 END
	)
	WHEN MATCHED THEN
	UPDATE SET TargetReceivableTaxDetail.UpdatedById = @CreatedById, TargetReceivableTaxDetail.UpdatedTime = SYSDATETIMEOFFSET(),
	TargetReceivableTaxDetail.Amount_Amount = TargetReceivableTaxDetail.Amount_Amount + SourceReceivableTaxDetail.Amount,
	TargetReceivableTaxDetail.Balance_Amount = TargetReceivableTaxDetail.Balance_Amount + SourceReceivableTaxDetail.Amount,
	TargetReceivableTaxDetail.EffectiveBalance_Amount = TargetReceivableTaxDetail.EffectiveBalance_Amount + SourceReceivableTaxDetail.Amount
	OUTPUT INSERTED.Id AS ReceivableTaxDetailId,
	INSERTED.ReceivableDetailId AS ReceivableDetailId,
	INSERTED.AssetId AS ReceivableDetailAssetId,
	INSERTED.TaxBasisType AS TaxBasisType,
	INSERTED.FairMarketValue_Amount AS FairMarketValue_Amount,
	INSERTED.Cost_Amount AS Cost_Amount
	INTO #InsertedReceivableTaxDetails ;

	MERGE [ReceivableTaxDetails] AS TargetReceivableTaxDetail
	USING (SELECT * FROM #Temp_ReceivableTaxDetailsParameters WHERE AssetId IS NULL) AS SourceReceivableTaxDetail
	ON (TargetReceivableTaxDetail.ReceivableDetailId = SourceReceivableTaxDetail.ReceivableDetailId AND 
	TargetReceivableTaxDetail.AssetId IS NULL  AND TargetReceivableTaxDetail.IsActive = 1 ) 
	WHEN NOT MATCHED THEN
	INSERT  
	([UpfrontTaxMode],
	[TaxBasisType],
	[Revenue_Amount],
	[Revenue_Currency],
	[FairMarketValue_Amount],
	[FairMarketValue_Currency],
	[Cost_Amount],
	[Cost_Currency],
	[TaxAreaId],
	[IsActive],
	[ManuallyAssessed],
	[CreatedById],
	[CreatedTime],
	[AssetLocationId],
	[LocationId],
	[AssetId],
	[ReceivableDetailId],
	[ReceivableTaxId],
	[IsGLPosted],
	[Amount_Amount],
	[Amount_Currency],
	[Balance_Amount],
	[Balance_Currency],
	[EffectiveBalance_Amount],
	[EffectiveBalance_Currency],
	[UpfrontPayableFactor]
	)
	VALUES
	(
	UpfrontTaxMode,
	TaxBasisType,
	ExtendedPrice,
	NonVertexExtract_Currency,
	FairMarketValue,
	NonVertexExtract_Currency,
	AssetCost,
	NonVertexExtract_Currency,
	NULL,
	1,
	0,
	@CreatedById,
	SYSDATETIMEOFFSET(),
	AssetLocationId,
	LocationId,
	AssetId,
	ReceivableDetailId,
	ReceivableTaxId,
	0,
	Amount,
	TaxDetail_Currency,
	Amount,
	TaxDetail_Currency,
	Amount,
	TaxDetail_Currency,
	CASE WHEN TAXBasisType<>'ST' AND TaxBasisType<>'_' THEN 1 ELSE 0 END
	)
	WHEN MATCHED THEN
	UPDATE SET TargetReceivableTaxDetail.UpdatedById = @CreatedById, TargetReceivableTaxDetail.UpdatedTime = SYSDATETIMEOFFSET(),
	TargetReceivableTaxDetail.Amount_Amount = TargetReceivableTaxDetail.Amount_Amount + SourceReceivableTaxDetail.Amount,
	TargetReceivableTaxDetail.Balance_Amount = TargetReceivableTaxDetail.Balance_Amount + SourceReceivableTaxDetail.Amount,
	TargetReceivableTaxDetail.EffectiveBalance_Amount = TargetReceivableTaxDetail.EffectiveBalance_Amount + SourceReceivableTaxDetail.Amount
	OUTPUT INSERTED.Id AS ReceivableTaxDetailId,
	INSERTED.ReceivableDetailId AS ReceivableDetailId,
	INSERTED.AssetId AS ReceivableDetailAssetId,
	INSERTED.TaxBasisType AS TaxBasisType,
	INSERTED.FairMarketValue_Amount AS FairMarketValue_Amount,
	INSERTED.Cost_Amount AS Cost_Amount
	INTO #InsertedReceivableTaxDetails ;
	

	INSERT INTO [dbo].[ReceivableTaxImpositions]
	([ExemptionType],
	[ExemptionRate],
	[ExemptionAmount_Amount],
	[ExemptionAmount_Currency],
	[TaxableBasisAmount_Amount],
	[TaxableBasisAmount_Currency],
	[AppliedTaxRate],
	[Amount_Amount],
	[Amount_Currency],
	[Balance_Amount],
	[Balance_Currency],
	[EffectiveBalance_Amount],
	[EffectiveBalance_Currency],
	[ExternalTaxImpositionType],
	[CreatedById],
	[CreatedTime],
	[TaxTypeId],
	[ExternalJurisdictionLevelId],
	[ReceivableTaxDetailId],
	[IsActive],
	[TaxBasisType]
	)
	SELECT
	RTIP.ExemptionType,
	RTIP.ExemptionRate,
	RTIP.ExemptionAmount_Amount,
	RTIP.ExemptionAmount_Currency,
	RTIP.TaxableBasisAmount_Amount,
	RTIP.TaxableBasisAmount_Currency,
	RTIP.AppliedTaxRate,
	RTIP.Amount_Amount,
	RTIP.Amount_Currency,
	RTIP.Balance_Amount,
	RTIP.Balance_Currency,
	RTIP.EffectiveBalance_Amount,
	RTIP.EffectiveBalance_Currency,
	RTIP.ExternalTaxImpositionType,
	RTIP.CreatedById,
	RTIP.CreatedTime,
	RTIP.TaxTypeId,
	RTIP.ExternalJurisdictionLevelId,
	IRTD.ReceivableTaxDetailId,
	RTIP.IsActive,
	RTIP.TaxBasisType
	FROM #ReceivableTaxImpositionParameters  RTIP
	INNER JOIN #InsertedReceivableTaxDetails IRTD ON RTIP.ReceivableDetailId = IRTD.ReceivableDetailId AND (RTIP.AssetId = IRTD.ReceivableDetailAssetId OR RTIP.AssetId IS NULL)
	WHERE IRTD.ReceivableDetailAssetId = RTIP.AssetId OR RTIP.AssetId IS NULL;


	UPDATE ReceivableDetails
	SET IsTaxAssessed = 1 , UpdatedById = 1, UpdatedTime = SYSDATETIMEOFFSET()
	FROM ReceivableDetails
	JOIN #InsertedReceivableTaxDetails TempInsertedReceivableTaxDetail
	ON ReceivableDetails.Id = TempInsertedReceivableTaxDetail.ReceivableDetailId
	

	SELECT DISTINCT ReceivableDetailId FROM #InsertedReceivableTaxDetails
	SELECT DISTINCT ReceivableDetailId FROM #InsertedReceivableTaxDetails RTD
		WHERE (RTD.TaxBasisType = @URTaxBasisType AND RTD.FairMarketValue_Amount <> 0.00) OR (RTD.TaxBasisType = @UCTaxBasisType AND RTD.Cost_Amount <> 0.00)

	
	DROP TABLE #TempReceivableTaxesParameters;
	DROP TABLE #TempReceivableTaxDetailsParameters;
	DROP TABLE #ReceivableTaxImpositionParameters;

	DROP TABLE #InsertedReceivableTaxDetails;
	DROP TABLE #InsertedReceivableTaxes;
END

GO

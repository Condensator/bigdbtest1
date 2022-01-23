SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[CloneReceivableTaxesForAdjustment]
(
	@ReceivableToClone	ReceivableTaxDetailsToAdjust READONLY,
	@CreatedById		BIGINT,
	@CreatedTime		DATETIMEOFFSET
)
AS
BEGIN
	SET NOCOUNT ON;
	CREATE TABLE #InsertedReceivableTaxes
	(
		InsertedReceivableTaxId BIGINT,
		ReceivableId			BIGINT
	)
	CREATE TABLE #InsertedReceivableTaxDetails
	(
		NewReceivableTaxDetailId	BIGINT,
		OldReceivableTaxDetailId	BIGINT,
		ReceivableDetailId			BIGINT,
		ReceivableDetailAssetId		BIGINT NULL
	);

	SELECT DISTINCT OldReceivableId,NewReceivableId, IsVATReceivable INTO #ReceivableValues FROM @ReceivableToClone

	/*ReceivableTaxes*/
	INSERT INTO dbo.ReceivableTaxes
	(
		IsActive,
		IsGLPosted,
		Amount_Amount,
		Amount_Currency,
		Balance_Amount,
		Balance_Currency,
		EffectiveBalance_Amount,
		EffectiveBalance_Currency,
		IsDummy,
		CreatedById,
		CreatedTime,
		ReceivableId,
		GLTemplateId,
		IsCashBased
	)
	OUTPUT INSERTED.Id,INSERTED.ReceivableId INTO #InsertedReceivableTaxes
	SELECT
		rt.IsActive,
		rd.IsVATReceivable,
		rt.Amount_Amount * -1,
		rt.Amount_Currency,
		rt.Amount_Amount * -1 AS Balance_Amount,
		rt.Balance_Currency,
		rt.Amount_Amount * -1 AS EffectiveBalance_Amount,
		rt.EffectiveBalance_Currency,
		rt.IsDummy,
		@CreatedById,
		@CreatedTime,
		rd.NewReceivableId,
		rt.GLTemplateId,
		IsCashBased
	FROM ReceivableTaxes rt
		JOIN #ReceivableValues rd ON rt.ReceivableId = rd.OldReceivableId
	WHERE rt.IsActive = 1
	
	/*ReceivableTaxDetails*/
	SELECT  
		rtd.UpfrontTaxMode,
		rtd.TaxBasisType,
		rtd.Revenue_Amount * -1 AS Revenue_Amount,
		rtd.Revenue_Currency,
		rtd.FairMarketValue_Amount * -1 AS FairMarketValue_Amount,
		rtd.FairMarketValue_Currency,
		rtd.Cost_Amount * -1 AS Cost_Amount,
		rtd.Cost_Currency,
		rtd.TaxAreaId,
		rtd.ManuallyAssessed,
		rtd.Amount_Amount * -1 AS Amount_Amount,
		rtd.Amount_Currency,
		rtd.Amount_Amount * -1 AS Balance_Amount,
		rtd.Balance_Currency,
		rtd.Amount_Amount * -1 AS EffectiveBalance_Amount,
		rtd.EffectiveBalance_Currency ,
		rtd.AssetLocationId,
		rtd.LocationId,
		rtd.AssetId,
		rd.NewReceivableDetailId,
		rd.IsVATReceivable AS IsGLPosted,
		IRT.InsertedReceivableTaxId,
		rtd.Id AS OldReceivableTaxDetailId,
		rtd.UpfrontPayablefactor
	INTO #ReceivableTaxDetailsToClone
	FROM dbo.ReceivableTaxDetails rtd
		JOIN dbo.ReceivableTaxes rt ON rtd.ReceivableTaxId = rt.Id
		JOIN @ReceivableToClone rd	ON rt.ReceivableId = rd.OldReceivableId AND rtd.ReceivableDetailId = rd.OldReceivableDetailid
		JOIN #InsertedReceivableTaxes IRT ON rd.NewReceivableId = IRT.ReceivableId
	WHERE rtd.IsActive = 1 AND rt.IsActive = 1
	
	MERGE ReceivableTaxDetails receivableTaxDetail
	USING #ReceivableTaxDetailsToClone newTaxDetails ON 1 != 1
	WHEN NOT MATCHED THEN
	INSERT
	(	
		UpfrontTaxMode,
		TaxBasisType,
		Revenue_Amount,
		Revenue_Currency,
		FairMarketValue_Amount,
		FairMarketValue_Currency,
		Cost_Amount,
		Cost_Currency,
		TaxAreaId,
		IsActive,
		ManuallyAssessed,
		IsGLPosted,
		Amount_Amount,
		Amount_Currency,
		Balance_Amount,
		Balance_Currency,
		EffectiveBalance_Amount,
		EffectiveBalance_Currency,
		CreatedById,
		CreatedTime,
		AssetLocationId,
		LocationId,
		AssetId,
		ReceivableDetailId,
		ReceivableTaxId,
		UpfrontPayablefactor
	)
	VALUES
	(	
		UpfrontTaxMode,
		TaxBasisType,
		Revenue_Amount,
		Revenue_Currency,
		FairMarketValue_Amount,
		FairMarketValue_Currency,
		Cost_Amount,
		Cost_Currency,
		TaxAreaId,
		1,
		ManuallyAssessed,
		IsGLPosted,
		Amount_Amount,
		Amount_Currency,
		Balance_Amount,
		Balance_Currency,
		EffectiveBalance_Amount,
		EffectiveBalance_Currency,
		@CreatedById,
		@CreatedTime,
		AssetLocationId,
		LocationId,
		AssetId,
		NewReceivableDetailId,
		InsertedReceivableTaxId,
		UpfrontPayablefactor
	)
	OUTPUT INSERTED.Id AS NewReceivableTaxDetailId,
		newTaxDetails.OldReceivableTaxDetailId AS OldReceivableTaxDetailId,
		INSERTED.ReceivableDetailId AS ReceivableDetailId,
		INSERTED.AssetId AS ReceivableDetailAssetId
	INTO #InsertedReceivableTaxDetails;
	
	/*ReceivableTaxImpositions*/
	INSERT INTO dbo.ReceivableTaxImpositions
	(
		ExemptionType,
		ExemptionRate,
		ExemptionAmount_Amount,
		ExemptionAmount_Currency,
		TaxableBasisAmount_Amount,
		TaxableBasisAmount_Currency,
		AppliedTaxRate,
		Amount_Amount,
		Amount_Currency,
		Balance_Amount,
		Balance_Currency,
		EffectiveBalance_Amount,
		EffectiveBalance_Currency,
		ExternalTaxImpositionType,
		IsActive,
		CreatedById,
		CreatedTime,
		TaxTypeId,
		ExternalJurisdictionLevelId,
		ReceivableTaxDetailId,
		TaxBasisType
	)
	SELECT
		rti.ExemptionType,
		rti.ExemptionRate,
		rti.ExemptionAmount_Amount * -1,
		rti.ExemptionAmount_Currency,
		rti.TaxableBasisAmount_Amount * -1,
		rti.TaxableBasisAmount_Currency,
		rti.AppliedTaxRate,
		rti.Amount_Amount * -1,
		rti.Amount_Currency,
		rti.Amount_Amount * -1 AS Balance_Amount,
		rti.Balance_Currency,
		rti.Amount_Amount * -1 AS EffectiveBalance_Amount,
		rti.EffectiveBalance_Currency,
		rti.ExternalTaxImpositionType,
		rti.IsActive,
		@CreatedById,
		@CreatedTime,
		rti.TaxTypeId,
		rti.ExternalJurisdictionLevelId,
		irtd.NewReceivableTaxDetailId,
		rti.TaxBasisType
	FROM @ReceivableToClone rtc
		JOIN dbo.ReceivableTaxDetails rtd ON rtc.OldReceivableDetailId = rtd.ReceivableDetailId
		JOIN dbo.ReceivableTaxImpositions rti ON rtd.Id = rti.ReceivableTaxDetailId
		JOIN #InsertedReceivableTaxDetails irtd ON rti.ReceivableTaxDetailId = irtd.OldReceivableTaxDetailId
	WHERE rti.IsActive = 1 AND rtd.IsActive = 1
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[PerformUpdateExecutionForTaxDepAmortJob]
(
	@TaxDepEntitiesToUpdate TaxDepEntityToUpdateForJob READONLY,
	@TaxDepAmortizationsToUpdate TaxDepAmortizationToUpdate READONLY,
	@LeaseAssetsToUpdate LeaseAssetToUpdate READONLY,
	@TaxDepAmortizationDetailsToUpdate TaxDepAmortizationDetailToUpdate READONLY,
	@TaxDepAmortizationDetailForecastsToUpdate TaxDepAmortizationDetailForecastToUpdate READONLY,
	@DeferredTaxesToUpdate DeferredTaxToUpdateForJob READONLY,
	@TaxDepAmortizationGLHeadersToUpdate TaxDepAmortizationGLHeadersToUpdateForJob READONLY,
	@UpdatedById BIGINT,
	@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
	SET NOCOUNT ON
	IF EXISTS (SELECT * FROM @TaxDepEntitiesToUpdate)
	BEGIN
		UPDATE TE 
		SET TE.IsComputationPending = TDE.IsComputationPending,
			TE.IsGLPosted = TDE.IsGLPosted,
			TE.FxTaxBasisAmount_Amount = TDE.FxTaxBasisAmount_Amount,
			TE.FxTaxBasisAmount_Currency = TDE.FxTaxBasisAmount_Currency,
			TE.UpdatedById = @UpdatedById,
			TE.UpdatedTime = @UpdatedTime,
			TE.PostDate = TDE.PostDate
		FROM TaxDepEntities TE JOIN @TaxDepEntitiesToUpdate TDE ON TE.Id = TDE.Id
	END

	IF EXISTS (SELECT * FROM @TaxDepAmortizationsToUpdate WHERE IsFromGeneration = 1)
	BEGIN
		UPDATE TD 
		SET TD.TaxBasisAmount_Amount = TDA.TaxBasisAmount_Amount, 
			TD.TaxBasisAmount_Currency = TDA.TaxBasisAmount_Currency, 
			TD.FxTaxBasisAmount_Amount = TDA.FxTaxBasisAmount_Amount, 
			TD.FxTaxBasisAmount_Currency = TDA.FxTaxBasisAmount_Currency, 
			TD.DepreciationBeginDate = TDA.DepreciationBeginDate, 
			TD.IsStraightLineMethodUsed = TDA.IsStraightLineMethodUsed,
			TD.IsTaxDepreciationTerminated = TDA.IsTaxDepreciationTerminated,
			TD.TerminationDate = TDA.TerminationDate,
			TD.IsConditionalSale = TDA.IsConditionalSale,
			TD.TaxDepreciationTemplateId = TDA.TaxDepreciationTemplateId,
			TD.UpdatedById = @UpdatedById,
			TD.UpdatedTime = @UpdatedTime
		FROM TaxDepAmortizations TD JOIN @TaxDepAmortizationsToUpdate TDA ON TD.Id = TDA.Id 
		WHERE TDA.IsFromGeneration = 1
	
		DECLARE @BatchSize BIGINT = 10000;
		DECLARE @Start BIGINT = (SELECT MIN(Id) FROM @TaxDepAmortizationsToUpdate);
		DECLARE @End BIGINT = (SELECT MAX(Id) FROM @TaxDepAmortizationsToUpdate);
		DECLARE @Increment BIGINT = @Start + @BatchSize - 1;
		WHILE @Start <= @End
		BEGIN
			UPDATE TDAD 
			SET TDAD.IsSchedule = 0, 
				TDAD.IsAccounting = 0,
				TDAD.UpdatedById = @UpdatedById,
				TDAD.UpdatedTime = @UpdatedTime
			FROM TaxDepAmortizationDetails TDAD
			JOIN @TaxDepAmortizationsToUpdate TD ON TDAD.TaxDepAmortizationId = TD.Id AND TDAD.IsSchedule = 1
			WHERE TD.Id >= @Start AND TD.Id <= @Increment AND TD.IsFromGeneration = 1

			SET @Start = @Start + @BatchSize;
			SET @Increment = @Start + @BatchSize - 1;
		END
		UPDATE TaxDepAmortizationDetailForecasts 
		SET IsActive = 0,
			UpdatedById = @UpdatedById,
			UpdatedTime = @UpdatedTime
		WHERE TaxDepAmortizationId in (SELECT Id FROM @TaxDepAmortizationsToUpdate WHERE IsFromGeneration = 1) AND IsActive = 1

		IF EXISTS (SELECT * FROM @LeaseAssetsToUpdate)
		BEGIN
			UPDATE LA
			SET LA.FxTaxBasisAmount_Amount = LEA.FxTaxBasisAmount_Amount,
				LA.FxTaxBasisAmount_Currency = LEA.FxTaxBasisAmount_Currency,
				LA.UpdatedById = @UpdatedById,
				LA.UpdatedTime = @UpdatedTime
			FROM LeaseAssets LA JOIN @LeaseAssetsToUpdate LEA ON LA.Id = LEA.Id
		END
	END

	IF EXISTS (SELECT * FROM @TaxDepAmortizationsToUpdate WHERE IsFromGeneration = 0)
	BEGIN
		UPDATE TD 
		SET TD.IsActive = TDA.IsActive, 
			TD.IsTaxDepreciationTerminated = TDA.IsTaxDepreciationTerminated,
			TD.TerminationDate = TDA.TerminationDate,
			TD.IsConditionalSale = TDA.IsConditionalSale,
			TD.UpdatedById = @UpdatedById,
			TD.UpdatedTime = @UpdatedTime
		FROM TaxDepAmortizations TD JOIN @TaxDepAmortizationsToUpdate TDA ON TD.Id = TDA.Id 
		WHERE TDA.IsFromGeneration = 0
	END

	IF EXISTS (SELECT * FROM @TaxDepAmortizationDetailsToUpdate WHERE IsFromGLComponent = 0)
	BEGIN
		UPDATE TD
		SET TD.IsSchedule = TDAD.IsSchedule,
			TD.IsAccounting = TDAD.IsAccounting,
			TD.UpdatedById = @UpdatedById,
			TD.UpdatedTime = @UpdatedTime
		FROM TaxDepAmortizationDetails TD 
		JOIN @TaxDepAmortizationDetailsToUpdate TDAD ON TD.Id = TDAD.Id
		WHERE TDAD.IsFromGLComponent = 0
	END

	IF EXISTS (SELECT * FROM @TaxDepAmortizationDetailForecastsToUpdate)
	BEGIN
		UPDATE TDF
		SET TDF.IsActive = TDADF.IsActive,
			TDF.UpdatedById = @UpdatedById,
			TDF.UpdatedTime = @UpdatedTime
		FROM TaxDepAmortizationDetailForecasts TDF
		JOIN @TaxDepAmortizationDetailForecastsToUpdate TDADF ON TDF.Id = TDADF.Id
	END

	IF EXISTS (SELECT * FROM @DeferredTaxesToUpdate)
	BEGIN
		UPDATE DF
		SET DF.IsReprocess = DT.ReprocessFlag,
			DF.UpdatedById = @UpdatedById,
			DF.UpdatedTime = @UpdatedTime
		FROM DeferredTaxes DF
		JOIN @DeferredTaxesToUpdate DT ON DF.Id = DT.Id
	END

	IF EXISTS (SELECT * FROM @TaxDepAmortizationDetailsToUpdate WHERE IsFromGLComponent = 1)
	BEGIN
		UPDATE TD
		SET TD.IsGLPosted = TDAD.IsGLPosted,
			TD.IsAccounting = TDAD.IsAccounting,
			TD.UpdatedById = @UpdatedById,
			TD.UpdatedTime = @UpdatedTime
		FROM TaxDepAmortizationDetails TD 
		JOIN @TaxDepAmortizationDetailsToUpdate TDAD ON TD.Id = TDAD.Id
		WHERE TDAD.IsFromGLComponent = 1
	END

	IF EXISTS (SELECT * FROM @TaxDepAmortizationGLHeadersToUpdate)
	BEGIN
		UPDATE TDAGLH
		SET TDAGLH.ReversalPostDate = TDA.ReversalPostDate,
			TDAGLH.UpdatedById = @UpdatedById,
			TDAGLH.UpdatedTime = @UpdatedTime
		FROM TaxDepAmortizationGLHeaders TDAGLH
		JOIN TaxDepAmortizationGLDetails TDAGLD ON TDAGLH.Id = TDAGLD.TaxDepAmortizationGLHeaderId
		JOIN @TaxDepAmortizationGLHeadersToUpdate TDA ON TDA.TaxDepAmortizationDetailId = TDAGLD.TaxDepAmortizationDetailId
	END
	

	SET NOCOUNT OFF
END

GO

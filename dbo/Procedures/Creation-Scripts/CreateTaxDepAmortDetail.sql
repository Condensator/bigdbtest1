SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[CreateTaxDepAmortDetail]
(
@TaxDepEntityId BIGINT
,@AssetId BIGINT
,@TaxDepAmortDetails TaxDepAmortDetail READONLY
,@TaxDepAmortDetailForecast TaxDepAmortForeCast READONLY
,@CanUpdateAssetWithFXBasisAmt BIT
,@FXTaxBasisAmount DECIMAL(18,2)
,@CreatedById INT
,@CreatedTime DATETIMEOFFSET
,@ExistingTaxDepAmortId BIGINT = NULL
,@PerformClosedPeriodAdjustment BIT = 0
,@GLPostedTaxBookId BIGINT = NULL
,@OpenPeriodFromDate DATE = NULL
)
AS
BEGIN
SET NOCOUNT ON
DECLARE @TaxDepAmortId BIGINT
CREATE TABLE #InsertedForeCastDetails
(
TaxDepAmortId BIGINT
,TaxDepreciationTemplateDetailId BIGINT
,CurrencyId BIGINT
,ForeCastId BIGINT NOT NULL
)
CREATE TABLE #InsertedTaxDepAmortDetails
(
TaxDepAmortId BIGINT
,TaxDepreciationTemplateDetailId BIGINT
,CurrencyId BIGINT
,TaxDepAmortDetailId BIGINT NOT NULL
)
CREATE NONCLUSTERED INDEX IX_ForeCastDetails ON #InsertedForeCastDetails (TaxDepAmortId, TaxDepreciationTemplateDetailId , CurrencyId )
CREATE NONCLUSTERED INDEX IX_TaxDepAmortDetail ON #InsertedTaxDepAmortDetails (TaxDepAmortId, TaxDepreciationTemplateDetailId , CurrencyId )
IF @ExistingTaxDepAmortId IS NULL
BEGIN
INSERT INTO TaxDepAmortizations
(
TaxBasisAmount_Amount
,TaxBasisAmount_Currency
,FXTaxBasisAmount_Amount
,FXTaxBasisAmount_Currency
,DepreciationBeginDate
,IsStraightLineMethodUsed
,IsTaxDepreciationTerminated
,TerminationDate
,IsConditionalSale
,IsActive
,CreatedById
,CreatedTime
,TaxDepreciationTemplateId
,TaxDepEntityId
)
SELECT
TaxBasisAmount_Amount
,TaxBasisAmount_Currency
,@FXTaxBasisAmount
,FXTaxBasisAmount_Currency
,DepreciationBeginDate
,IsStraightLineMethodUsed
,IsTaxDepreciationTerminated
,TerminationDate
,IsConditionalSale
,1
,@CreatedById
,@CreatedTime
,TaxDepTemplateId
,Id
FROM TaxDepEntities WHERE Id = @TaxDepEntityId
SET @TaxDepAmortId = SCOPE_IDENTITY()
END
ELSE
BEGIN
UPDATE TaxDepAmortizationDetails
SET
IsSchedule = 0,
IsAccounting = CASE WHEN (@PerformClosedPeriodAdjustment = 1 AND TaxDepAmortizationDetails.TaxDepreciationTemplateDetailId = @GLPostedTaxBookId AND TaxDepAmortizationDetails.IsGLPosted = 1 AND TaxDepAmortizationDetails.DepreciationDate < @OpenPeriodFromDate)
THEN 1 ELSE 0 END,
UpdatedById = @CreatedById,
UpdatedTime = @CreatedTime
WHERE TaxDepAmortizationId = @ExistingTaxDepAmortId AND IsSchedule = 1;
UPDATE TaxDepAmortizationDetailForecasts SET IsActive = 0,UpdatedById = @CreatedById ,UpdatedTime = @CreatedTime
WHERE TaxDepAmortizationId = @ExistingTaxDepAmortId AND IsActive = 1;
UPDATE TaxDepAmortizations
SET
TaxBasisAmount_Amount = TaxDepEntities.TaxBasisAmount_Amount
,TaxBasisAmount_Currency = TaxDepEntities.TaxBasisAmount_Currency
,FXTaxBasisAmount_Amount = @FXTaxBasisAmount
,FXTaxBasisAmount_Currency = TaxDepEntities.FXTaxBasisAmount_Currency
,DepreciationBeginDate = TaxDepEntities.DepreciationBeginDate
,IsStraightLineMethodUsed = TaxDepEntities.IsStraightLineMethodUsed
,IsTaxDepreciationTerminated = TaxDepEntities.IsTaxDepreciationTerminated
,TerminationDate = TaxDepEntities.TerminationDate
,IsConditionalSale = TaxDepEntities.IsConditionalSale
,IsActive = 1
,UpdatedById = @CreatedById
,UpdatedTime = @CreatedTime
,TaxDepreciationTemplateId = TaxDepEntities.TaxDepTemplateId
FROM TaxDepAmortizations
INNER JOIN TaxDepEntities ON TaxDepAmortizations.TaxDepEntityId = TaxDepEntities.Id
WHERE TaxDepEntityId = @TaxDepEntityId AND TaxDepAmortizations.Id = @ExistingTaxDepAmortId;
SET @TaxDepAmortId = @ExistingTaxDepAmortId
END
INSERT INTO TaxDepAmortizationDetails
(
DepreciationDate
,FiscalYear
,BeginNetBookValue_Amount
,BeginNetBookValue_Currency
,DepreciationAmount_Amount
,DepreciationAmount_Currency
,EndNetBookValue_Amount
,EndNetBookValue_Currency
--,IsActive
,CreatedById
,CreatedTime
,TaxDepreciationConventionId
,TaxDepreciationTemplateDetailId
,TaxDepAmortizationId
,TaxDepAmortizationDetailForecastId
,CurrencyId
,IsSchedule
,IsAccounting
,IsGLPosted
,IsAdjustmentEntry
)
OUTPUT INSERTED.TaxDepAmortizationId,INSERTED.TaxDepreciationTemplateDetailId,INSERTED.CurrencyId,INSERTED.Id INTO #InsertedTaxDepAmortDetails
SELECT
TDAD.DepreciationDate
,TDAD.FiscalYear
,TDAD.BeginNetBookValue_Amount
,TDAD.BeginNetBookValue_Currency
,TDAD.DepreciationAmount_Amount
,TDAD.DepreciationAmount_Currency
,TDAD.EndNetBookValue_Amount
,TDAD.EndNetBookValue_Currency
--,1
,@CreatedById
,@CreatedTime
,TDAD.TaxDepreciationConventionId
,TDAD.TaxDepreciationTemplateDetailId
,@TaxDepAmortId
,NULL
,TDAD.CurrencyId
,TDAD.IsSchedule
,TDAD.IsAccounting
,0
,0
FROM @TaxDepAmortDetails TDAD
INSERT INTO TaxDepAmortizationDetailForecasts
(
BonusDepreciationAmount_Amount
,BonusDepreciationAmount_Currency
,DepreciationEndDate
,FirstYearTaxDepreciationForecast_Amount
,FirstYearTaxDepreciationForecast_Currency
,LastYearTaxDepreciationForecast_Amount
,LastYearTaxDepreciationForecast_Currency
,IsActive
,CreatedById
,CreatedTime
,TaxDepAmortizationId
,TaxDepreciationTemplateDetailId
,CurrencyId
)
OUTPUT INSERTED.TaxDepAmortizationId,INSERTED.TaxDepreciationTemplateDetailId,INSERTED.CurrencyId,INSERTED.Id INTO #InsertedForeCastDetails
SELECT
TDAFD.BonusDepreciationAmount_Amount
,TDAFD.BonusDepreciationAmount_Currency
,TDAFD.DepreciationEndDate
,TDAFD.FirstYearTaxDepreciationForecast_Amount
,TDAFD.FirstYearTaxDepreciationForecast_Currency
,TDAFD.LastYearTaxDepreciationForecast_Amount
,TDAFD.LastYearTaxDepreciationForecast_Currency
,1
,@CreatedById
,@CreatedTime
,@TaxDepAmortId
,TDAFD.TaxDepreciationTemplateDetailId
,TDAFD.CurrencyId
FROM @TaxDepAmortDetailForecast TDAFD
UPDATE TDAD SET TDAD.TaxDepAmortizationDetailForecastId = FC.ForeCastId
FROM #InsertedForeCastDetails FC
JOIN TaxDepAmortizationDetails TDAD ON TDAD.TaxDepAmortizationId = FC.TaxDepAmortId
AND FC.TaxDepreciationTemplateDetailId=TDAD.TaxDepreciationTemplateDetailId AND FC.CurrencyId = TDAD.CurrencyId
JOIN #InsertedTaxDepAmortDetails ITDAD ON TDAD.TaxDepAmortizationId = ITDAD.TaxDepAmortId
AND ITDAD.TaxDepreciationTemplateDetailId=TDAD.TaxDepreciationTemplateDetailId AND ITDAD.CurrencyId = TDAD.CurrencyId
AND ITDAD.TaxDepAmortDetailId = TDAD.Id
WHERE ITDAD.TaxDepAmortId = @TaxDepAmortId
IF @CanUpdateAssetWithFXBasisAmt = 1 AND @AssetId <> 0
BEGIN
UPDATE LeaseAssets SET FXTaxBasisAmount_Amount = @FXTaxBasisAmount FROM LeaseAssets
JOIN LeaseFinances ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id AND IsCurrent=1 WHERE LeaseAssets.AssetId=@AssetId AND IsActive=1
END
DROP TABLE #InsertedTaxDepAmortDetails
DROP TABLE #InsertedForeCastDetails
END

GO

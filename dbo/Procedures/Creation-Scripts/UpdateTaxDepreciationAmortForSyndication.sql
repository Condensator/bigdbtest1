SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateTaxDepreciationAmortForSyndication]
(
@ContractId BIGINT,
@EffectiveDate DATETIME,
@RetainedPercentage DECIMAL(18,6),
@TaxDepAmortDetailId TaxDepAmortDetailsId READONLY,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET,
@OpenPeriodFromDate DATE
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT
TDAD.Id TaxDepAmortizationDetailId
,DepreciationDate
,FiscalYear
,BeginNetBookValue_Amount
,BeginNetBookValue_Currency
,DepreciationAmount_Amount
,DepreciationAmount_Currency
,EndNetBookValue_Amount
,EndNetBookValue_Currency
,TaxDepreciationConventionId
,TaxDepreciationTemplateDetailId
,TaxDepAmortizationId
,TaxDepAmortizationDetailForecastId
,CurrencyId
,IsSchedule
,IsAccounting
,IsGLPosted
,IsAdjustmentEntry
INTO #TaxDepAmortizationDetailsToProcess
FROM TaxDepAmortizationDetails TDAD
INNER JOIN @TaxDepAmortDetailId TDADI ON TDAD.Id = TDADI.Id
UPDATE #TaxDepAmortizationDetailsToProcess SET
BeginNetBookValue_Amount = ROUND((BeginNetBookValue_Amount * @RetainedPercentage), 2),
EndNetBookValue_Amount = ROUND((EndNetBookValue_Amount * @RetainedPercentage), 2),
DepreciationAmount_Amount = ROUND((DepreciationAmount_Amount * @RetainedPercentage), 2) ;
INSERT INTO TaxDepAmortizationDetails(
DepreciationDate
,FiscalYear
,BeginNetBookValue_Amount
,BeginNetBookValue_Currency
,DepreciationAmount_Amount
,DepreciationAmount_Currency
,EndNetBookValue_Amount
,EndNetBookValue_Currency
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
SELECT
TDAD.DepreciationDate
,TDAD.FiscalYear
,TDAD.BeginNetBookValue_Amount
,TDAD.BeginNetBookValue_Currency
,TDAD.DepreciationAmount_Amount
,TDAD.DepreciationAmount_Currency
,TDAD.EndNetBookValue_Amount
,TDAD.EndNetBookValue_Currency
,@UpdatedById
,@UpdatedTime
,TDAD.TaxDepreciationConventionId
,TDAD.TaxDepreciationTemplateDetailId
,TDAD.TaxDepAmortizationId
,TDAD.TaxDepAmortizationDetailForecastId
,TDAD.CurrencyId
,1
,CASE WHEN (TDAD.IsGLPosted = 1 AND TDAD.DepreciationDate < @OpenPeriodFromDate) THEN 0 ELSE 1 END
,CASE WHEN (TDAD.IsGLPosted = 1 AND TDAD.DepreciationDate < @OpenPeriodFromDate) THEN 1 ELSE 0 END
,0
FROM #TaxDepAmortizationDetailsToProcess TDAD;
UPDATE TaxDepAmortizationDetails SET IsSchedule = 0,
IsAccounting = CASE WHEN (TaxDepAmortizationDetails.IsGLPosted = 1 AND TaxDepAmortizationDetails.DepreciationDate < @OpenPeriodFromDate)
THEN 1 ELSE 0 END,
UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
WHERE Id IN (SELECT TaxDepAmortizationDetailId from #TaxDepAmortizationDetailsToProcess);
SELECT
TaxDepAmortizationDetailForecastId ,FiscalYear, SUM(DepreciationAmount_Amount) DepreciationAmount INTO #ForecastDetailsForAllYears
FROM TaxDepAmortizations
INNER JOIN TaxDepAmortizationDetails ON TaxDepAmortizations.Id = TaxDepAmortizationDetails.TaxDepAmortizationId AND TaxDepAmortizationDetails.IsSchedule = 1
INNER JOIN @TaxDepAmortDetailId TDADI ON TaxDepAmortizationDetails.Id = TDADI.Id
GROUP BY TaxDepAmortizationDetailForecastId,FiscalYear
ORDER BY TaxDepAmortizationDetailForecastId;
SELECT TaxDepAmortizationDetailForecastId,MIN(FiscalYear) MinFiscalYear,MAX(FiscalYear) MaxFiscalYear
INTO #MaxAndMinYearsInAmort FROM #ForecastDetailsForAllYears group by TaxDepAmortizationDetailForecastId;
UPDATE TaxDepAmortizationDetailForecasts
SET FirstYearTaxDepreciationForecast_Amount = #ForecastDetailsForAllYears.DepreciationAmount
,UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
FROM TaxDepAmortizationDetailForecasts
INNER JOIn #ForecastDetailsForAllYears ON TaxDepAmortizationDetailForecasts.Id = #ForecastDetailsForAllYears.TaxDepAmortizationDetailForecastId
INNER JOIN #MaxAndMinYearsInAmort ON #ForecastDetailsForAllYears.TaxDepAmortizationDetailForecastId = #MaxAndMinYearsInAmort.TaxDepAmortizationDetailForecastId
AND #ForecastDetailsForAllYears.FiscalYear = #MaxAndMinYearsInAmort.MinFiscalYear;
UPDATE TaxDepAmortizationDetailForecasts
SET LastYearTaxDepreciationForecast_Amount = #ForecastDetailsForAllYears.DepreciationAmount
,UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
FROM TaxDepAmortizationDetailForecasts
INNER JOIn #ForecastDetailsForAllYears ON TaxDepAmortizationDetailForecasts.Id = #ForecastDetailsForAllYears.TaxDepAmortizationDetailForecastId
INNER JOIN #MaxAndMinYearsInAmort ON #ForecastDetailsForAllYears.TaxDepAmortizationDetailForecastId = #MaxAndMinYearsInAmort.TaxDepAmortizationDetailForecastId
AND #ForecastDetailsForAllYears.FiscalYear = #MaxAndMinYearsInAmort.MaxFiscalYear;
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[CreateTaxDepAmortDetailForecasts]
(
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET
)AS
BEGIN
--DECLARE @CreatedBy INT = 1
SET NOCOUNT ON
CREATE TABLE #TaxDepAmortDetail
(
TaxDepAmortId BIGINT
,TaxDepreciationTemplateDetailId BIGINT
,CurrencyId BIGINT
,TaxBasisAmount_Amount DECIMAL(18,2)
,TaxBasisAmount_Currency NVARCHAR(3)
,FXTaxBasisAmount_Amount DECIMAL(18,2)
,FXTaxBasisAmount_Currency NVARCHAR(3)
,DepreciationDate DATETIME
,FiscalYear INT
,DepreciationAmount_Amount DECIMAL(18,2)
,DepreciationAmount_Currency NVARCHAR(3)
,TaxDepAmortDetailId BIGINT
,BonusPercentage DECIMAL(18,6)
)
CREATE TABLE #FirstAndLastYearForeCastDetails
(
TaxDepAmortId BIGINT
,TaxDepreciationTemplateDetailId BIGINT
,CurrencyId BIGINT
,FirstYearDepreciationAmount_Amount DECIMAL(18,2)
,LastYearDepreciationAmount_Amount DECIMAL(18,2)
,TaxBasisCurrencyCode NVARCHAR(3)
,DepreciationAmount_Currency NVARCHAR(3)
,TaxBasisAmount_Amount DECIMAL(18,2)
,FXTaxBasisAmount_Amount DECIMAL(18,2)
,TaxBasisAmount_Currency NVARCHAR(3)
,FXTaxBasisAmount_Currency NVARCHAR(3)
,BonusPercentage DECIMAL(18,6)
)
CREATE TABLE #BonusCalculation
(
TaxDepAmortId BIGINT
,TaxDepreciationTemplateDetailId BIGINT
,CurrencyId BIGINT
,BonusDepAmount DECIMAL(18,2)
)
CREATE TABLE #TaxDepEndDate
(
TaxDepAmortId BIGINT
,TaxDepreciationTemplateDetailId BIGINT
,CurrencyId BIGINT
,TaxDepEndDate DATETIME
)
CREATE TABLE #InsertedForeCastDetails
(
TaxDepAmortId BIGINT
,TaxDepreciationTemplateDetailId BIGINT
,CurrencyId BIGINT
,ForeCastId BIGINT
)
CREATE TABLE #MinAndMaxYear
(
TaxDepAmortId BIGINT
,TaxDepreciationTemplateDetailId BIGINT
,CurrencyId BIGINT
,MinYear INT
,MaxYear INT
,DepreciationAmount_Currency NVARCHAR(3)
,TaxBasisAmount_Amount DECIMAL(18,2)
,FXTaxBasisAmount_Amount DECIMAL(18,2)
,TaxBasisAmount_Currency NVARCHAR(3)
,FXTaxBasisAmount_Currency NVARCHAR(3)
,BonusPercentage DECIMAL(18,6)
)
CREATE NONCLUSTERED INDEX IX_TaxDepAmortDetail ON #TaxDepAmortDetail (TaxDepAmortId, TaxDepreciationTemplateDetailId , CurrencyId )
CREATE NONCLUSTERED INDEX IX_FirstAndLastYearForeCastDetails ON #FirstAndLastYearForeCastDetails (TaxDepAmortId, TaxDepreciationTemplateDetailId , CurrencyId )
CREATE NONCLUSTERED INDEX IX_BonusCalculation ON #BonusCalculation (TaxDepAmortId, TaxDepreciationTemplateDetailId , CurrencyId )
CREATE NONCLUSTERED INDEX IX_TaxDepEndDate ON #TaxDepEndDate (TaxDepAmortId, TaxDepreciationTemplateDetailId , CurrencyId )
CREATE NONCLUSTERED INDEX IX_InsertedForeCastDetails ON #InsertedForeCastDetails (TaxDepAmortId, TaxDepreciationTemplateDetailId , CurrencyId )
CREATE NONCLUSTERED INDEX IX_MinAndMaxYear ON #InsertedForeCastDetails (TaxDepAmortId, TaxDepreciationTemplateDetailId , CurrencyId )
--CREATE NONCLUSTERED INDEX IX_Bonus ON #InsertedForeCastDetails (TaxDepAmortId, TaxDepreciationTemplateDetailId , CurrencyId )
--CREATE NONCLUSTERED INDEX IX_BasisAmt ON #InsertedForeCastDetails (TaxDepAmortId, TaxDepreciationTemplateDetailId , CurrencyId )
INSERT INTO #TaxDepAmortDetail
SELECT
TDA.Id
,TDAD.TaxDepreciationTemplateDetailId
,TDAD.CurrencyId
,TDA.TaxBasisAmount_Amount
,TDA.TaxBasisAmount_Currency
,TDA.FXTaxBasisAmount_Amount
,TDA.FXTaxBasisAmount_Currency
,TDAD.DepreciationDate
,TDAD.FiscalYear
,TDAD.DepreciationAmount_Amount
,TDAD.DepreciationAmount_Currency
,TDAD.Id
,TDTD.BonusDepreciationPercent
FROM TaxDepEntities TDE
JOIN TaxDepAmortizations TDA ON TDE.Id = TDA.TaxDepEntityId
JOIN TaxDepAmortizationDetails TDAD ON TDA.Id = TDAD.TaxDepAmortizationId
JOIN TaxDepTemplateDetails TDTD ON TDTD.Id = TDAD.TaxDepreciationTemplateDetailId
WHERE TDA.IsActive = 1 AND
--TDAD.IsActive = 1
TDAD.IsSchedule = 1 AND TDAD.IsAccounting = 1
AND TDE.IsActive = 1
AND TDAD.TaxDepAmortizationDetailForecastId IS NULL
--AND TDA.TaxDepEntityId IN (1283)
--WHERE TDA.TaxDepEntityId IN (1285,1284,1283)
--SELECT * FROM #TaxDepAmortDetail
--SELECT  CurrencyId,TaxDepreciationTemplateDetailId,TaxDepAmortId,TaxBasisAmount_Amount,FXTaxBasisAmount_Amount,TaxBasisAmount_Currency,FXTaxBasisAmount_Currency FROM #TaxDepAmortDetail
--GROUP BY CurrencyId,TaxDepreciationTemplateDetailId,TaxDepAmortId,TaxBasisAmount_Amount,FXTaxBasisAmount_Amount,TaxBasisAmount_Currency,FXTaxBasisAmount_Currency
INSERT INTO #MinAndMaxYear
SELECT
TaxDepAmortId,TaxDepreciationTemplateDetailId,CurrencyId,MIN(FiscalYear) MinYear,MAX(FiscalYear) MaxYear, DepreciationAmount_Currency,TaxBasisAmount_Amount,FXTaxBasisAmount_Amount,TaxBasisAmount_Currency,FXTaxBasisAmount_Currency,BonusPercentage
FROM #TaxDepAmortDetail
GROUP BY TaxDepAmortId,TaxDepreciationTemplateDetailId,CurrencyId,DepreciationAmount_Currency,TaxBasisAmount_Amount,FXTaxBasisAmount_Amount,TaxBasisAmount_Currency,FXTaxBasisAmount_Currency,BonusPercentage
INSERT INTO #FirstAndLastYearForeCastDetails
SELECT
TaxDepAmortId,TaxDepreciationTemplateDetailId,CurrencyId,
(SELECT SUM(DepreciationAmount_Amount) FROM #TaxDepAmortDetail WHERE CurrencyId = CTE.CurrencyId AND TaxDepreciationTemplateDetailId = CTE.TaxDepreciationTemplateDetailId
AND TaxDepAmortId = CTE.TaxDepAmortId AND FiscalYear = CTE.MinYear AND DepreciationAmount_Currency = CTE.DepreciationAmount_Currency) FirstYear
,(SELECT SUM(DepreciationAmount_Amount) FROM #TaxDepAmortDetail WHERE CurrencyId = CTE.CurrencyId AND TaxDepreciationTemplateDetailId = CTE.TaxDepreciationTemplateDetailId
AND TaxDepAmortId = CTE.TaxDepAmortId AND FiscalYear = CTE.MaxYear AND DepreciationAmount_Currency = CTE.DepreciationAmount_Currency) LastYear
,TaxBasisAmount_Currency,DepreciationAmount_Currency,TaxBasisAmount_Amount,FXTaxBasisAmount_Amount,TaxBasisAmount_Currency,FXTaxBasisAmount_Currency,BonusPercentage
FROM #MinAndMaxYear CTE
--SELECT * FROM #FirstAndLastYearForeCastDetails
--Bonus
INSERT INTO #BonusCalculation
SELECT
FAL.TaxDepAmortId
,FAL.TaxDepreciationTemplateDetailId
,FAL.CurrencyId
,CASE WHEN
(SELECT CurrencyCodes.ISO FROM Currencies JOIN CurrencyCodes ON Currencies.CurrencyCodeId = CurrencyCodes.Id WHERE Currencies.Id = FAL.CurrencyId) = TaxBasisCurrencyCode
THEN Round(TaxBasisAmount_Amount * BonusPercentage/100,2)
ELSE Round(FXTaxBasisAmount_Amount * BonusPercentage/100,2)
END BonusDepAmount
--,TaxBasisAmount_Amount,FXTaxBasisAmount_Amount,TaxBasisAmount_Currency,FXTaxBasisAmount_Currency,BonusPercentage
FROM #FirstAndLastYearForeCastDetails FAL
--SELECT * FROM #TaxDepAmortDetail
--SELECT * FROM #FirstAndLastYearForeCastDetails
--SELECT * FROM #BonusCalculation
--SELECT * FROM #TaxDepEndDate
INSERT INTO #TaxDepEndDate
SELECT TDAD.TaxDepAmortId,TDAD.TaxDepreciationTemplateDetailId,TDAD.CurrencyId, MAX(DepreciationDate) FROM #TaxDepAmortDetail TDAD
JOIN #FirstAndLastYearForeCastDetails ON TDAD.CurrencyId = #FirstAndLastYearForeCastDetails.CurrencyId
AND TDAD.TaxDepreciationTemplateDetailId = #FirstAndLastYearForeCastDetails.TaxDepreciationTemplateDetailId
GROUP BY TDAD.TaxDepreciationTemplateDetailId,TDAD.CurrencyId,TDAD.TaxDepAmortId,TDAD.DepreciationAmount_Currency
INSERT INTO TaxDepAmortizationDetailForecasts
(
BonusDepreciationAmount_Amount
,BonusDepreciationAmount_Currency
,DepreciationEndDate
,FirstYearTaxDepreciationForecast_Amount
,FirstYearTaxDepreciationForecast_Currency
,LastYearTaxDepreciationForecast_Amount
,LastYearTaxDepreciationForecast_Currency
,CreatedById
,CreatedTime
,TaxDepAmortizationId
,TaxDepreciationTemplateDetailId
,CurrencyId
,IsActive
)
OUTPUT INSERTED.TaxDepAmortizationId,INSERTED.TaxDepreciationTemplateDetailId,INSERTED.CurrencyId,INSERTED.Id INTO #InsertedForeCastDetails
SELECT
BC.BonusDepAmount
,FL.DepreciationAmount_Currency
,TD.TaxDepEndDate
,FL.FirstYearDepreciationAmount_Amount
,FL.DepreciationAmount_Currency
,FL.LastYearDepreciationAmount_Amount
,FL.DepreciationAmount_Currency
,@CreatedById
,@CreatedTime
,BC.TaxDepAmortId
,BC.TaxDepreciationTemplateDetailId
,BC.CurrencyId
,1
FROM #FirstAndLastYearForeCastDetails FL
JOIN #BonusCalculation BC ON FL.CurrencyId = BC.CurrencyId AND BC.TaxDepreciationTemplateDetailId = fl.TaxDepreciationTemplateDetailId AND BC.TaxDepAmortId = fl.TaxDepAmortId
JOIN #TaxDepEndDate TD ON TD.CurrencyId = BC.CurrencyId AND BC.TaxDepreciationTemplateDetailId = TD.TaxDepreciationTemplateDetailId AND BC.TaxDepAmortId = TD.TaxDepAmortId
UPDATE TDAD SET TDAD.TaxDepAmortizationDetailForecastId = FC.ForeCastId
FROM #InsertedForeCastDetails FC
JOIN TaxDepAmortizationDetails TDAD ON TDAD.TaxDepAmortizationId = FC.TaxDepAmortId
AND FC.TaxDepreciationTemplateDetailId=TDAD.TaxDepreciationTemplateDetailId AND FC.CurrencyId = TDAD.CurrencyId
DROP TABLE #TaxDepAmortDetail
DROP TABLE #FirstAndLastYearForeCastDetails
DROP TABLE #TaxDepEndDate
DROP TABLE #BonusCalculation
DROP TABLE #InsertedForeCastDetails
DROP TABLE #MinAndMaxYear
END

GO

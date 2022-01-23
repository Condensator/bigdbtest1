SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROC [dbo].[SPHC_TaxDepAmortReconciliation_HealthCheck]
(
	@ResultOption NVARCHAR(20),
	@EntityType NVARCHAR(15),
	@ContractIds ReconciliationId READONLY
)
AS 
	BEGIN
	SET NOCOUNT ON
	SET ANSI_WARNINGS OFF
	
	--//*********RECONCILIATION QUERY DECLARATION BLOCK*********//
	IF OBJECT_ID('tempDB..#TaxDepAmortizations') IS NOT NULL  
		  DROP TABLE #TaxDepAmortizations  
	IF OBJECT_ID('tempDB..#TerminationYearDepreciationDetails') IS NOT NULL  
		  DROP TABLE #TerminationYearDepreciationDetails  
	IF OBJECT_ID('tempDB..#TerminationPeriodFractions') IS NOT NULL  
		  DROP TABLE #TerminationPeriodFractions  
	IF OBJECT_ID('tempDB..#TaxDepAmortReconciliationResults') IS NOT NULL  
		  DROP TABLE #TaxDepAmortReconciliationResults
	IF OBJECT_ID('tempDB..#OutageReasonPerTaxDepEntities') IS NOT NULL  
		  DROP TABLE #OutageReasonPerTaxDepEntities
	IF OBJECT_ID('tempDB..#TaxDepEntityReconciliationResults') IS NOT NULL  
		  DROP TABLE #TaxDepEntityReconciliationResults
	DECLARE @Both NVARCHAR(10) = 'Both'
	DECLARE @Asset NVARCHAR(10) = 'Asset'
	DECLARE @BlendedItem NVARCHAR(20) = 'BlendedItem'
	DECLARE @Passed NVARCHAR(10) = 'Passed'
	DECLARE @NotFound NVARCHAR(50) = 'Active TaxDepAmortizationDetails Not Found'
	DECLARE @TerminatedInSameYear NVARCHAR(100) = 'TaxDepEntity terminated in the Depreciation Begin fiscal year'
	DECLARE @Failed NVARCHAR(10) = 'Failed'
	DECLARE @FullYear NVARCHAR(20) = 'FullYear'
	DECLARE @HalfYear NVARCHAR(20) = 'HalfYear'
	DECLARE @MidQuarter NVARCHAR(20) = 'MidQuarter'
	DECLARE @MidMonth NVARCHAR(20) = 'MidMonth'
	DECLARE @DateFormatString NVARCHAR(10) = ' 1 2020'
	DECLARE @ParticipatedSale NVARCHAR(25) = 'ParticipatedSale'
	DECLARE @Approved NVARCHAR(25) = 'Approved'
	DECLARE @True BIT = 1
	DECLARE @False BIT = 0
	DECLARE @PassedEntities INT
	DECLARE @FailedEntities INT
	DECLARE @AmortNotFoundEntities INT
	DECLARE @TerminatedInSameYearEntities INT
	DECLARE @TotalEntities INT
	DECLARE @Conclusion NVARCHAR(100) = 'Please refer Results for details.'
	DECLARE @Messages StoredProcMessage
	CREATE TABLE #TerminationPeriodFractions
	(
		PeriodNumber INT,
		TerminationFraction DECIMAL(5,4),
		Convention NVARCHAR(20)
	)
	DECLARE @ContractCount BIGINT = ISNULL((SELECT COUNT(*) FROM @ContractIds), 0)

	--//*********FILL #TERMINATIONPERIODFRACTIONS*********//
	INSERT INTO #TerminationPeriodFractions VALUES(1,0.125,@MidQuarter)
	INSERT INTO #TerminationPeriodFractions VALUES(2,0.375,@MidQuarter)
	INSERT INTO #TerminationPeriodFractions VALUES(3,0.625,@MidQuarter)
	INSERT INTO #TerminationPeriodFractions VALUES(4,0.875,@MidQuarter)
	INSERT INTO #TerminationPeriodFractions VALUES(1,0.0417,@MidMonth)
	INSERT INTO #TerminationPeriodFractions VALUES(2,0.125,@MidMonth)
	INSERT INTO #TerminationPeriodFractions VALUES(3,0.2083,@MidMonth)
	INSERT INTO #TerminationPeriodFractions VALUES(4,0.2917,@MidMonth)
	INSERT INTO #TerminationPeriodFractions VALUES(5,0.375,@MidMonth)
	INSERT INTO #TerminationPeriodFractions VALUES(6,0.4583,@MidMonth)
	INSERT INTO #TerminationPeriodFractions VALUES(7,0.5417,@MidMonth)
	INSERT INTO #TerminationPeriodFractions VALUES(8,0.625,@MidMonth)
	INSERT INTO #TerminationPeriodFractions VALUES(9,0.7083,@MidMonth)
	INSERT INTO #TerminationPeriodFractions VALUES(10,0.7917,@MidMonth)
	INSERT INTO #TerminationPeriodFractions VALUES(11,0.875,@MidMonth)
	INSERT INTO #TerminationPeriodFractions VALUES(12,0.9583,@MidMonth)

	--//*********RECONCILIATION QUERY STARTS*********//
	--//*********PRIMARY QUERY WITH PRELIMINARY FILTERATION*********//
	;WITH CTE_TaxDepAmortPrimaryQuery AS
	(
		SELECT
		TDE.Id AS TaxDepEntityId, 
		TDA.Id AS TaxDepAmortizationId,
		TDE.EntityType,
		TDE.AssetId,
		TDE.BlendedItemId,
		TDE.ContractId,
		TDA.IsTaxDepreciationTerminated,
		CASE 
			WHEN TDE.ContractId IS NOT NULL
				THEN
					CASE 
						WHEN LF.LegalEntityId IS NOT NULL
							THEN LF.LegalEntityId
						ELSE
							LoF.LegalEntityId
					END
			ELSE
				A.LegalEntityId
		END AS LegalEntityId,
		TDA.DepreciationBeginDate,
		TDE.DepreciationEndDate,
		TDA.TerminationDate
		FROM TaxDepEntities TDE
		JOIN TaxDepAmortizations TDA ON TDE.Id = TDA.TaxDepEntityId
		LEFT JOIN Assets A ON TDE.AssetId = A.Id AND TDE.AssetId IS NOT NULL
		LEFT JOIN LeaseFinances LF ON TDE.ContractId = LF.ContractId AND LF.IsCurrent = @True AND TDE.ContractId IS NOT NULL
		LEFT JOIN LoanFinances LoF ON TDE.ContractId = LoF.ContractId AND LoF.IsCurrent = @True AND TDE.ContractId IS NOT NULL
		WHERE TDE.IsComputationPending = @False AND TDE.IsActive = @True
		AND (ISNULL(@EntityType,@Both) = @Both OR @EntityType = TDE.EntityType)
		AND @True = (CASE 
					 WHEN @ContractCount > 0 AND EXISTS (SELECT Id FROM @ContractIds WHERE Id = TDE.ContractId) AND TDE.ContractId IS NOT NULL THEN @True
					 WHEN @ContractCount = 0 THEN @True ELSE @False END)
	)
	SELECT 
	TDACTE.TaxDepEntityId,
	TDACTE.TaxDepAmortizationId,
	TDACTE.EntityType,
	TDACTE.AssetId,
	TDACTE.BlendedItemId,
	TDACTE.ContractId,
	TDACTE.IsTaxDepreciationTerminated,
	CASE 
		WHEN MONTH(CAST((LE.TaxFiscalYearBeginMonthNo + @DateFormatString) AS DATETIME)) != 1
		THEN
			CASE 
				WHEN MONTH(CAST((LE.TaxFiscalYearBeginMonthNo + @DateFormatString) AS DATETIME)) <= MONTH(EOMONTH(TDACTE.TerminationDate))
				THEN YEAR(EOMONTH(TDACTE.TerminationDate)) + 1
				ELSE YEAR(EOMONTH(TDACTE.TerminationDate))
			END
		ELSE YEAR(EOMONTH(TDACTE.TerminationDate))
	END AS TerminationFiscalYear,
	TDACTE.LegalEntityId,
	LE.TaxFiscalYearBeginMonthNo,
	TDACTE.DepreciationBeginDate,
	TDACTE.DepreciationEndDate,
	TDACTE.TerminationDate,
	CASE WHEN RFT.Id IS NOT NULL AND TDACTE.EntityType = @Asset THEN @True ELSE @False END AS IsParticipatedSold,
	RFT.EffectiveDate,
	CASE 
		WHEN MONTH(CAST((LE.TaxFiscalYearBeginMonthNo + @DateFormatString) AS DATETIME)) != 1
		THEN
			CASE 
				WHEN MONTH(CAST((LE.TaxFiscalYearBeginMonthNo + @DateFormatString) AS DATETIME)) <= MONTH(EOMONTH(RFT.EffectiveDate))
				THEN YEAR(EOMONTH(RFT.EffectiveDate)) + 1
				ELSE YEAR(EOMONTH(RFT.EffectiveDate))
			END
		ELSE YEAR(EOMONTH(RFT.EffectiveDate))
	END AS ParticipatedSaleFiscalYear,
	CASE WHEN MONTH(TDACTE.TerminationDate) - MONTH(CAST((LE.TaxFiscalYearBeginMonthNo + @DateFormatString) AS DATETIME)) < 0
		 THEN 12 + MONTH(TDACTE.TerminationDate) -  MONTH(CAST((LE.TaxFiscalYearBeginMonthNo + @DateFormatString) AS DATETIME)) + 1
		 ELSE MONTH(TDACTE.TerminationDate) -  MONTH(CAST((LE.TaxFiscalYearBeginMonthNo + @DateFormatString) AS DATETIME)) + 1
	END AS TerminationPeriod
	INTO #TaxDepAmortizations 
	FROM CTE_TaxDepAmortPrimaryQuery TDACTE
	JOIN LegalEntities LE ON TDACTE.LegalEntityId = LE.Id
	LEFT JOIN Contracts C ON TDACTE.ContractId = C.Id AND TDACTE.ContractId IS NOT NULL
	LEFT JOIN ReceivableForTransfers RFT ON C.Id = RFT.ContractId AND C.Id IS NOT NULL AND RFT.ReceivableForTransferType = @ParticipatedSale AND RFT.ApprovalStatus = @Approved
	GROUP BY
	TDACTE.TaxDepEntityId,
	TDACTE.TaxDepAmortizationId,
	TDACTE.EntityType,
	TDACTE.AssetId,
	TDACTE.BlendedItemId,
	TDACTE.ContractId,
	TDACTE.IsTaxDepreciationTerminated,
	LE.TaxFiscalYearBeginMonthNo,
	TDACTE.TerminationDate,
	TDACTE.LegalEntityId,
	TDACTE.DepreciationBeginDate,
	TDACTE.DepreciationEndDate,
	TDACTE.TerminationDate,
	RFT.Id,
	RFT.EffectiveDate

	--//*********QUERY FOR DEPRECIATION AMOUNT FOR TERMINATION FISCAL YEAR RECORDS*********//
	;WITH CTE_TaxDepTerminatedRecords AS
	(
		SELECT 
		TDAD.Id,
		TDAD.TaxDepAmortizationId,
		TDAD.TaxDepreciationTemplateDetailId,
		TDAD.TaxDepAmortizationDetailForecastId,
		TDAD.BeginNetBookValue_Currency,
		ROW_NUMBER() OVER (PARTITION BY TDAD.DepreciationDate,TDAD.TaxDepAmortizationId,TDAD.TaxDepreciationTemplateDetailId,TDAD.BeginNetBookValue_Currency,TDAD.FiscalYear ORDER BY TDAD.Id DESC) AS Row_Num,
		TDAD.FiscalYear,
		ISNULL(TDAD.DepreciationAmount_Amount,0.00) AS DepreciationAmount_Amount
		FROM TaxDepAmortizationDetails TDAD
		JOIN #TaxDepAmortizations TDA ON TDAD.TaxDepAmortizationId = TDA.TaxDepAmortizationId AND TDA.IsTaxDepreciationTerminated = @True
		WHERE TDAD.FiscalYear = TDA.TerminationFiscalYear AND TDAD.IsSchedule = @False
	)
	SELECT 
	TaxDepAmortizationId,
	TaxDepAmortizationDetailForecastId,
	TaxDepreciationTemplateDetailId,
	BeginNetBookValue_Currency,  
	FiscalYear,
	SUM(DepreciationAmount_Amount) AS DepreciationAmount_Amount
	INTO #TerminationYearDepreciationDetails
	FROM CTE_TaxDepTerminatedRecords WHERE Row_Num = 1 
	GROUP BY
	TaxDepAmortizationId,
	TaxDepreciationTemplateDetailId,
	BeginNetBookValue_Currency,  
	FiscalYear,
	TaxDepAmortizationDetailForecastId



	--//*********FINAL QUERY*********//
	;WITH CTE_TaxDepReconResults AS
	(
		SELECT 
		TDA.TaxDepEntityId,
		TDAD1.TaxDepAmortizationId,
		TDA.EntityType,
		TDA.AssetId,
		TDA.BlendedItemId,
		TDA.ContractId, 
		TDA.DepreciationBeginDate,
		TDA.DepreciationEndDate,
		TDA.TerminationDate,
		CASE WHEN (TDAD1.FiscalYear >= TDA.TerminationFiscalYear OR ((DATEADD(DAY,-1,(DATEADD(MONTH,12,TDA.DepreciationBeginDate))) > TDA.TerminationDate) AND TDA.EntityType != @BlendedItem)) AND TDA.IsTaxDepreciationTerminated = @True
			THEN @True
			ELSE @False
		END AS IsTaxDepreciationTerminated,
		CASE WHEN (DATEADD(DAY,-1,(DATEADD(MONTH,12,TDA.DepreciationBeginDate))) > TDA.TerminationDate) AND TDA.EntityType != @BlendedItem
			THEN TDA.TerminationFiscalYear
		ELSE
			TDAD1.FiscalYear
		END AS FiscalYear,
		TDTD.TaxBook,
		TDC.Name AS ConventionName,
		TDAD1.BeginNetBookValue_Currency AS TaxDepCurrency,
		CASE 
			WHEN (DATEADD(DAY,-1,(DATEADD(MONTH,12,TDA.DepreciationBeginDate))) > TDA.TerminationDate) AND TDA.EntityType != @BlendedItem
				THEN NULL
			ELSE
				MAX(CASE WHEN TDA.IsParticipatedSold = @False OR (TDAD1.DepreciationDate < TDA.EffectiveDate OR TDAD1.FiscalYear != TDA.ParticipatedSaleFiscalYear) THEN ISNULL(TDAD1.BeginNetBookValue_Amount,0.00) ELSE 0.00 END) 
		END
		AS BeginNetBookValue_Amount,
		CASE
			WHEN (DATEADD(DAY,-1,(DATEADD(MONTH,12,TDA.DepreciationBeginDate))) > TDA.TerminationDate) AND TDA.EntityType != @BlendedItem
				THEN NULL 
			WHEN TDA.IsParticipatedSold = @True
				THEN MAX(CASE WHEN TDAD1.DepreciationDate >= TDA.EffectiveDate AND TDAD1.FiscalYear = TDA.ParticipatedSaleFiscalYear 
								THEN TDAD1.BeginNetBookValue_Amount 
							ELSE 
								0.00 
						END)
			ELSE 0.00
		END AS BeginNetBookValueAfterPS_Amount,
		CASE 
			WHEN (DATEADD(DAY,-1,(DATEADD(MONTH,12,TDA.DepreciationBeginDate))) > TDA.TerminationDate) AND TDA.EntityType != @BlendedItem
				THEN NULL
			WHEN (DATEADD(DAY,-1,(DATEADD(MONTH,12,TDA.DepreciationBeginDate))) > TDA.TerminationDate) AND TDA.EntityType = @BlendedItem
				THEN SUM(ISNULL(TDAD1.DepreciationAmount_Amount,0.00))
			WHEN (TDA.IsTaxDepreciationTerminated = @True AND TDA.TerminationFiscalYear = TDAD1.FiscalYear) AND COUNT(TDAD2.TaxDepAmortizationId) != 0 AND TDA.EntityType = @Asset
				THEN 
					CASE 
						WHEN TDC.Name = @FullYear
							THEN ROUND(TDAD2.DepreciationAmount_Amount * 1, 2)
						WHEN TDC.Name = @HalfYear
							THEN ROUND(TDAD2.DepreciationAmount_Amount * 0.5, 2)
						ELSE
							ROUND(TDAD2.DepreciationAmount_Amount * (SELECT TerminationFraction FROM #TerminationPeriodFractions TPF WHERE TPF.PeriodNumber = CASE WHEN TDC.Name = 'MidQuarter'
																																								   THEN CEILING(TDA.TerminationPeriod / CAST(3 AS FLOAT))
																																								   ELSE TDA.TerminationPeriod
																																							  END AND TPF.Convention = TDC.Name), 2)
					END
			ELSE
				SUM(CASE WHEN TDA.IsParticipatedSold = @False OR (TDAD1.DepreciationDate < TDA.EffectiveDate OR TDAD1.FiscalYear != TDA.ParticipatedSaleFiscalYear) THEN ISNULL(TDAD1.DepreciationAmount_Amount,0.00) ELSE 0.00 END)
		END AS AllowableDepreciation_Amount,
		CASE 
			WHEN (DATEADD(DAY,-1,(DATEADD(MONTH,12,TDA.DepreciationBeginDate))) > TDA.TerminationDate) AND TDA.EntityType != @BlendedItem
				THEN NULL
			ELSE
				SUM(CASE WHEN TDA.IsParticipatedSold = @False OR (TDAD1.DepreciationDate < TDA.EffectiveDate OR TDAD1.FiscalYear != TDA.ParticipatedSaleFiscalYear) THEN ISNULL(TDAD1.DepreciationAmount_Amount,0.00) ELSE 0.00 END)
		END
		AS TotalDepreciation_Amount,
		CASE
			WHEN (DATEADD(DAY,-1,(DATEADD(MONTH,12,TDA.DepreciationBeginDate))) > TDA.TerminationDate) AND TDA.EntityType != @BlendedItem
				THEN NULL 
			WHEN TDA.IsParticipatedSold = @True
				THEN SUM(CASE WHEN TDAD1.DepreciationDate >= TDA.EffectiveDate AND TDAD1.FiscalYear = TDA.ParticipatedSaleFiscalYear 
								THEN TDAD1.DepreciationAmount_Amount 
							ELSE 
								0.00 
						END)
			ELSE 0.00
		END AS TotalDepreciationAfterPS_Amount,
		CASE 
			WHEN (DATEADD(DAY,-1,(DATEADD(MONTH,12,TDA.DepreciationBeginDate))) > TDA.TerminationDate) AND TDA.EntityType != @BlendedItem
				THEN NULL
			ELSE ISNULL(MIN(CASE WHEN TDA.IsParticipatedSold = @False OR (TDAD1.DepreciationDate < TDA.EffectiveDate OR TDAD1.FiscalYear != TDA.ParticipatedSaleFiscalYear) THEN ISNULL(TDAD1.EndNetBookValue_Amount,0.00) ELSE NULL END),0.00) 
		END AS EndNetBookValue_Amount,
		CASE 
			WHEN (DATEADD(DAY,-1,(DATEADD(MONTH,12,TDA.DepreciationBeginDate))) > TDA.TerminationDate) AND TDA.EntityType != @BlendedItem
				THEN NULL
			WHEN TDA.IsParticipatedSold = @True
				THEN ISNULL(MIN(CASE WHEN TDAD1.DepreciationDate >= TDA.EffectiveDate AND TDAD1.FiscalYear = TDA.ParticipatedSaleFiscalYear 
								THEN TDAD1.EndNetBookValue_Amount 
							ELSE 
								NULL 
						END),0.00)
			ELSE 0.00 
		END AS EndNetBookValueAfterPS_Amount,
		CASE 
			WHEN (DATEADD(DAY,-1,(DATEADD(MONTH,12,TDA.DepreciationBeginDate))) > TDA.TerminationDate) AND TDA.EntityType != @BlendedItem
			THEN @True 
			ELSE @False 
		END AS IsTerminatedInBeginYear,
		CASE WHEN TDAD1.TaxDepAmortizationId IS NULL THEN @True ELSE @False END AS IsNotGenerated,
		TDA.IsParticipatedSold,
		TDA.ParticipatedSaleFiscalYear,
		CASE 
			WHEN TDAD1.FiscalYear = TDA.TerminationFiscalYear AND TDA.IsTaxDepreciationTerminated = @True 
			THEN @True 
			ELSE @False 
		END AS IsTerminationFiscalYear
		FROM #TaxDepAmortizations TDA 
		LEFT JOIN TaxDepAmortizationDetails TDAD1 ON TDAD1.TaxDepAmortizationId = TDA.TaxDepAmortizationId 
			AND TDAD1.IsSchedule = @True
		LEFT JOIN TaxDepTemplateDetails TDTD ON TDAD1.TaxDepreciationTemplateDetailId = TDTD.Id
		LEFT JOIN TaxDepConventions TDC ON TDAD1.TaxDepreciationConventionId = TDC.Id
		LEFT JOIN #TerminationYearDepreciationDetails TDAD2 ON TDAD1.TaxDepAmortizationId = TDAD2.TaxDepAmortizationId 
			AND TDAD1.TaxDepreciationTemplateDetailId = TDAD2.TaxDepreciationTemplateDetailId 
			AND TDAD1.BeginNetBookValue_Currency = TDAD2.BeginNetBookValue_Currency
			AND TDAD1.FiscalYear = TDAD2.FiscalYear
			AND TDAD1.TaxDepAmortizationDetailForecastId = TDAD2.TaxDepAmortizationDetailForecastId
		GROUP BY 
		TDA.TaxDepEntityId,
		TDAD1.TaxDepAmortizationId,
		TDA.EntityType,
		TDA.AssetId,
		TDA.BlendedItemId,
		TDA.ContractId, 
		TDA.IsTaxDepreciationTerminated,
		TDAD1.TaxDepreciationTemplateDetailId, 
		TDAD1.BeginNetBookValue_Currency, 
		TDAD1.FiscalYear,
		TDTD.TaxBook,
		TDA.TerminationFiscalYear,
		TDC.Name,
		TDAD2.DepreciationAmount_Amount,
		TDA.TaxFiscalYearBeginMonthNo,
		TDA.DepreciationBeginDate,
		TDA.DepreciationEndDate,
		TDA.TerminationDate,
		TDA.IsParticipatedSold,
		TDA.ParticipatedSaleFiscalYear,
		TDA.TerminationPeriod
	)
	SELECT
	TaxDepEntityId,
	TaxDepAmortizationId,
	EntityType,
	AssetId,
	BlendedItemId,
	ContractId, 
	DepreciationBeginDate,
	DepreciationEndDate,
	TerminationDate,
	IsTaxDepreciationTerminated,
	IsParticipatedSold AS IsParticipated,
	FiscalYear,
	TaxBook,
	ConventionName,
	TaxDepCurrency,
	BeginNetBookValue_Amount,
	CASE 
		WHEN IsTaxDepreciationTerminated = @True 
		THEN AllowableDepreciation_Amount
		ELSE NULL
	END AS AllowableDepreciation_Amount,
	(TotalDepreciation_Amount + TotalDepreciationAfterPS_Amount) AS TotalDepreciation_Amount,
	CASE 
		WHEN IsParticipatedSold = @True AND ParticipatedSaleFiscalYear = FiscalYear 
			THEN EndNetBookValueAfterPS_Amount 
		ELSE EndNetBookValue_Amount 
	END AS EndNetBookValue_Amount,
	CASE
		WHEN IsTerminatedInBeginYear = @True
		THEN @TerminatedInSameYear
		WHEN IsNotGenerated = @True
		THEN @NotFound
		WHEN IsParticipatedSold = @False OR ParticipatedSaleFiscalYear != FiscalYear
		THEN 
			CASE 
				WHEN (BeginNetBookValue_Amount = TotalDepreciation_Amount + EndNetBookValue_Amount) AND AllowableDepreciation_Amount = TotalDepreciation_Amount
				THEN @Passed
				ELSE @Failed
			END
		WHEN IsParticipatedSold = @True AND ParticipatedSaleFiscalYear = FiscalYear
		THEN 
			CASE WHEN ((BeginNetBookValue_Amount = TotalDepreciation_Amount + EndNetBookValue_Amount) AND AllowableDepreciation_Amount = TotalDepreciation_Amount) AND (BeginNetBookValueAfterPS_Amount = TotalDepreciationAfterPS_Amount + EndNetBookValueAfterPS_Amount)
				THEN @Passed
				ELSE @Failed
			END
		ELSE @Failed
	END AS OutageReason
	INTO #TaxDepAmortReconciliationResults
	FROM CTE_TaxDepReconResults

	--//*********RECONCILIATION QUERY OUTPUT 1*********//
	SELECT 
	TaxDepEntityId,
	EntityType,
	AssetId,
	BlendedItemId,
	ContractId,
	DepreciationBeginDate,
	DepreciationEndDate,
	TerminationDate, 
	SUM(CASE WHEN OutageReason = @Passed THEN 1 ELSE 0 END) AS PassedCount, 
	SUM(CASE WHEN OutageReason = @Failed THEN 1 ELSE 0 END) AS FailedCount, 
	SUM(CASE WHEN OutageReason = @NotFound THEN 1 ELSE 0 END) AS NotFoundCount,
	SUM(CASE WHEN OutageReason = @TerminatedInSameYear THEN 1 ELSE 0 END) AS TerminatedInSameYearCount
	INTO #OutageReasonPerTaxDepEntities
	FROM #TaxDepAmortReconciliationResults 
	GROUP BY 
	TaxDepEntityId,
	EntityType,
	AssetId,
	BlendedItemId,
	ContractId,
	DepreciationBeginDate,
	DepreciationEndDate,
	TerminationDate

	SELECT 
	TaxDepEntityId,
	EntityType,
	AssetId,
	BlendedItemId,
	ContractId,
	DepreciationBeginDate,
	DepreciationEndDate,
	TerminationDate,
	CASE
		WHEN PassedCount > 0 AND FailedCount = 0 AND NotFoundCount = 0 AND TerminatedInSameYearCount = 0
		THEN @Passed
		WHEN FailedCount > 0
		THEN @Failed
		WHEN NotFoundCount > 0
		THEN @NotFound
		WHEN TerminatedInSameYearCount > 0 AND NotFoundCount = 0 AND PassedCount = 0 AND FailedCount = 0
		THEN @TerminatedInSameYear
		ELSE
			@Failed
	END AS OutageReason
	INTO #TaxDepEntityReconciliationResults
	FROM #OutageReasonPerTaxDepEntities

	IF (@ResultOption = 'All')
	BEGIN
	SELECT * FROM #TaxDepEntityReconciliationResults

	SELECT * FROM #TaxDepAmortReconciliationResults
	END

	IF (@ResultOption = 'Passed')
	BEGIN
	SELECT * FROM #TaxDepEntityReconciliationResults
	WHERE OutageReason = 'Passed'

	SELECT * FROM #TaxDepAmortReconciliationResults
	WHERE OutageReason = 'Passed'
	END

	IF (@ResultOption = 'Failed')
	BEGIN
	SELECT * FROM #TaxDepEntityReconciliationResults
	WHERE OutageReason != 'Passed'

	SELECT * FROM #TaxDepAmortReconciliationResults
	WHERE OutageReason != 'Passed'
	END


	--//*********RECONCILIATION QUERY MESSAGES*********//
	SET @PassedEntities = (SELECT COUNT(*) FROM #TaxDepEntityReconciliationResults WHERE OutageReason = @Passed)
	SET @FailedEntities = (SELECT COUNT(*) FROM #TaxDepEntityReconciliationResults WHERE OutageReason = @Failed)
	SET @AmortNotFoundEntities = (SELECT COUNT(*) FROM #TaxDepEntityReconciliationResults WHERE OutageReason = @NotFound)
	SET @TerminatedInSameYearEntities = (SELECT COUNT(*) FROM #TaxDepEntityReconciliationResults WHERE OutageReason = @TerminatedInSameYear)
	SET @TotalEntities = (SELECT COUNT(*) FROM #TaxDepEntityReconciliationResults)

	INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('TotalTaxDepEntities', (Select 'TotalEntities=' + CONVERT(nvarchar(40), @TotalEntities)))
	INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('TaxDepEntitiesSuccessful', (Select 'PassedEntities=' + CONVERT(nvarchar(40), @PassedEntities)))
	INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('TaxDepEntitiesIncorrect', (Select 'FailedEntities=' + CONVERT(nvarchar(40), @FailedEntities)))
	INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('TaxDepEntitiesNotFound', (Select 'AmortNotFoundEntities=' + CONVERT(nvarchar(40), @AmortNotFoundEntities)))
	INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('TaxDepEntitiesTerminatedInBeginYear', (Select 'TerminatedInSameYearEntities=' + CONVERT(nvarchar(40), @TerminatedInSameYearEntities)))
	INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('TaxDepEntitiesResult', (Select 'ResultOption=' + CONVERT(nvarchar(40), @ResultOption)))

	SELECT * FROM @Messages

--	--//*********DROP TEMP TABLES*********//
	IF OBJECT_ID('tempDB..#TaxDepAmortizations') IS NOT NULL  
		  DROP TABLE #TaxDepAmortizations  
	IF OBJECT_ID('tempDB..#TerminationYearDepreciationDetails') IS NOT NULL  
		  DROP TABLE #TerminationYearDepreciationDetails  
	IF OBJECT_ID('tempDB..#TerminationPeriodFractions') IS NOT NULL  
		  DROP TABLE #TerminationPeriodFractions  
	IF OBJECT_ID('tempDB..#TaxDepAmortReconciliationResults') IS NOT NULL  
		  DROP TABLE #TaxDepAmortReconciliationResults
	IF OBJECT_ID('tempDB..#OutageReasonPerTaxDepEntities') IS NOT NULL  
		  DROP TABLE #OutageReasonPerTaxDepEntities
	IF OBJECT_ID('tempDB..#TaxDepEntityReconciliationResults') IS NOT NULL  
		  DROP TABLE #TaxDepEntityReconciliationResults

	SET NOCOUNT OFF
	SET ANSI_WARNINGS ON 
END

GO

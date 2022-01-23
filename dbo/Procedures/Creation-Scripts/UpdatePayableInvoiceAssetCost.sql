SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[UpdatePayableInvoiceAssetCost]
(
	@PayableInvoiceId BIGINT,
	@UpdateMode BIT,
	@CreateNegativeAdjustment BIT,
	@GLJournalId BIGINT = NULL,
	@ReversalGLId BIGINT = NULL,
	@SourceModule NVARCHAR(40),
	@IncomeDate DATETIMEOFFSET,
	@CreatedById BIGINT,
	@CreatedTime DATETIMEOFFSET,
	@ExchangeRate DECIMAL(20,10),
	@AssetCurrency NVARCHAR(6),
	@IsReversal BIT,
	@NegativeDeposit NVARCHAR(40),
	@Real NVARCHAR(40),
	@NewlyCreatedPayableInvoiceId BIGINT,
	@IsMigrationCall BIT = 0
)
AS
BEGIN
SET NOCOUNT ON

	DECLARE @PreviousIncomeDate DATETIMEOFFSET;

	SELECT TOP 1 @PreviousIncomeDate = IncomeDate 
	FROM  AssetValueHistories 
	WHERE SourceModuleId = @PayableInvoiceId AND 
		  SourceModule = @SourceModule AND
		  IsAccounted = 1 AND 
		  IsSchedule = 1

	CREATE TABLE #AssetValues
	(
		Value_Amount decimal(16,2),
		AssetId bigint NOT NULL,
		IsLeaseComponent bit NOT NULL
	)

	CREATE TABLE #InsertedAssetValueHistories
	(
		AssetId BIGINT NOT NULL,
		AssetValueHistoryId BIGINT NOT NULL,
		IsLeaseComponent BIT NOT NULL
	)

	CREATE TABLE #AssetValueHistoriesToInactivate
	(
		AssetValueHistoryId BIGINT NOT NULL
	)

	--Get SKU level values
	SELECT 
		((pias.AcquisitionCost_Amount + pias.OtherCost_Amount) * @ExchangeRate) 'Cost'
		,pia.AssetId
		,pias.AssetSKUId
		,assetSKU.IsLeaseComponent
	INTO #AssetSKUValues
	FROM dbo.PayableInvoiceAssets pia
	INNER JOIN dbo.PayableInvoiceAssetSKUs pias ON pia.Id  = pias.PayableInvoiceAssetId
	INNER JOIN dbo.AssetSKUs assetSKU ON pia.AssetId = assetSKU.AssetId And pias.AssetSKUId = assetSKU.Id
	WHERE pia.PayableInvoiceId = @PayableInvoiceId AND pia.IsActive = 1 AND pias.IsActive = 1 

	INSERT INTO #AssetValues
	(
	    AssetId,IsLeaseComponent,Value_Amount
	)
	SELECT pia.AssetId, a.IsLeaseComponent,
	ROUND(((pia.AcquisitionCost_Amount + pia.OtherCost_Amount ) * @ExchangeRate),2) 'Cost'
	FROM dbo.PayableInvoiceAssets pia
	INNER JOIN dbo.Assets a ON pia.AssetId = a.Id
	WHERE pia.PayableInvoiceId = @PayableInvoiceId AND pia.IsActive = 1 AND a.IsSKU = 0 
	
	UNION 

	SELECT asv.AssetId, asv.IsLeaseComponent, SUM(asv.Cost)
	FROM #AssetSKUValues asv
	GROUP BY asv.AssetId, asv.IsLeaseComponent
	
	IF @UpdateMode = 1 
    BEGIN
		IF @CreateNegativeAdjustment = 1
		BEGIN
			SELECT 
				AssetValueHistories.Id,
				(0 - AssetValueHistories.Value_Amount) Value_Amount,
				AssetValueHistories.Value_Currency,
				AssetValueHistories.BeginBookValue_Amount,
				AssetValueHistories.AssetId,
				AssetValueHistories.IsLeaseComponent
			INTO #AVH1
			FROM AssetValueHistories
			INNER JOIN PayableInvoiceAssets
					ON AssetValueHistories.AssetId = PayableInvoiceAssets.AssetId AND
					   PayableInvoiceAssets.PayableInvoiceId = AssetValueHistories.SourceModuleId AND
					   PayableInvoiceAssets.PayableInvoiceId = @PayableInvoiceId AND
					   AssetValueHistories.IncomeDate = @PreviousIncomeDate AND
					   AssetValueHistories.IsAccounted = 1 AND
					   AssetValueHistories.IsSchedule  = 1
					   AND AssetValueHistories.IsLessorOwned = 1		

			INSERT INTO AssetValueHistories	([SourceModule]
           ,[SourceModuleId]
           ,[FromDate]
           ,[ToDate]
           ,[IncomeDate]
           ,[Value_Amount]
           ,[Value_Currency]
           ,[Cost_Amount]
           ,[Cost_Currency]
           ,[NetValue_Amount]
           ,[NetValue_Currency]
           ,[BeginBookValue_Amount]
           ,[BeginBookValue_Currency]
           ,[EndBookValue_Amount]
           ,[EndBookValue_Currency]
           ,[IsAccounted]
           ,[IsSchedule]
           ,[IsCleared]
           ,[PostDate]
           ,[ReversalPostDate]
           ,[CreatedById]
           ,[CreatedTime]
           ,[UpdatedById]
           ,[UpdatedTime]
           ,[AssetId]
           ,[GLJournalId]
           ,[ReversalGLJournalId]
		   ,[AdjustmentEntry]
		   ,[IsLessorOwned]
		   ,[IsLeaseComponent])
			SELECT 
				@SourceModule,
				@PayableInvoiceId,
				NULL,
				NULL,
				@IncomeDate,
				Value_Amount,
				Value_Currency,
				0,
				Value_Currency,
				0,
				Value_Currency,
				BeginBookValue_Amount,
				Value_Currency,
				0,
				Value_Currency,
				1,
				0,
				1,
				NULL,
				NULL,
				@CreatedById,
				@CreatedTime,
				NULL,
				NULL,
				AssetId,
				@GLJournalId,
				NULL,
				0,
				1,
				IsLeaseComponent
			FROM #AVH1
			
			INSERT INTO #AssetValueHistoriesToInactivate SELECT Id FROM #AVH1
		END
		ELSE
			BEGIN
			SELECT 
				AssetValueHistories.Id, AssetValueHistories.SourceModule, AssetValueHistories.SourceModuleId
			INTO #AVH2
			FROM AssetValueHistories
				INNER JOIN PayableInvoiceAssets
						ON AssetValueHistories.AssetId = PayableInvoiceAssets.AssetId AND
						   PayableInvoiceAssets.PayableInvoiceId = @PayableInvoiceId AND
						   AssetValueHistories.IncomeDate = @PreviousIncomeDate AND
						   AssetValueHistories.IsAccounted = 1 AND
						   AssetValueHistories.IsSchedule  = 1 AND
						   AssetValueHistories.IsLessorOwned = 1

			IF(@NewlyCreatedPayableInvoiceId != 0)
			BEGIN
				UPDATE AssetValueHistories SET SourceModuleId = @NewlyCreatedPayableInvoiceId,UpdatedById = @CreatedById,UpdatedTime = @CreatedTime
				FROM AssetValueHistories
				INNER JOIN #AVH2
						ON AssetValueHistories.Id = #AVH2.Id AND
					       #AVH2.SourceModule = 'PayableInvoice'
			END
			ELSE
			BEGIN
				INSERT INTO #AssetValueHistoriesToInactivate
				SELECT Id FROM #AVH2  where SourceModuleId = @PayableInvoiceId AND #AVH2.SourceModule = @SourceModule
			END
			END
	END

	UPDATE AssetValueHistories 
	SET 
		IsSchedule = 0
		,IsAccounted = CASE WHEN @CreateNegativeAdjustment = 0 THEN 0 ELSE IsAccounted END
		,UpdatedById = @CreatedById
		,UpdatedTime = @CreatedTime
		,ReversalGLJournalId = CASE WHEN @CreateNegativeAdjustment = 0 THEN @ReversalGLId ELSE ReversalGLJournalId END
	FROM #AssetValueHistoriesToInactivate
	INNER JOIN AssetValueHistories ON AssetValueHistories.Id = #AssetValueHistoriesToInactivate.AssetValueHistoryId

	UPDATE SKUValueProportions
	SET IsActive = 0
	FROM SKUValueProportions -- Discuss with Jeba about existing indexes
	INNER JOIN #AssetValueHistoriesToInactivate ON SKUValueProportions.AssetValueHistoryId = #AssetValueHistoriesToInactivate.AssetValueHistoryId 

	DECLARE @SQL NVARCHAR(MAX) = '';
	
	IF @IsReversal = 0 
	BEGIN
        SET @SQL = @SQL + N'
          INSERT INTO AssetValueHistories	
				([SourceModule]
			   ,[SourceModuleId]
			   ,[FromDate]
			   ,[ToDate]
			   ,[IncomeDate]
			   ,[Value_Amount]
			   ,[Value_Currency]
			   ,[Cost_Amount]
			   ,[Cost_Currency]
			   ,[NetValue_Amount]
			   ,[NetValue_Currency]
			   ,[BeginBookValue_Amount]
			   ,[BeginBookValue_Currency]
			   ,[EndBookValue_Amount]
			   ,[EndBookValue_Currency]
			   ,[IsAccounted]
			   ,[IsSchedule]
			   ,[IsCleared]
			   ,[PostDate]
			   ,[ReversalPostDate]
			   ,[CreatedById]
			   ,[CreatedTime]
			   ,[UpdatedById]
			   ,[UpdatedTime]
			   ,[AssetId]
			   ,[GLJournalId]
			   ,[ReversalGLJournalId]
			   ,[AdjustmentEntry]
			   ,[IsLessorOwned]
			   ,[IsLeaseComponent])
			   OUTPUT INSERTED.AssetId,INSERTED.Id,INSERTED.IsLeaseComponent INTO #InsertedAssetValueHistories
				SELECT 
				@SourceModule,
				@PayableInvoiceId,
				NULL,
				NULL,
				@IncomeDate,				
				av.Value_Amount,
				@AssetCurrency,
				av.Value_Amount,
				@AssetCurrency,
				av.Value_Amount,
				@AssetCurrency,
				av.Value_Amount,
				@AssetCurrency,
				av.Value_Amount,
				@AssetCurrency,
				1,
				1,
				1,
				NULL,
				NULL,
				@CreatedById, 
	            @CreatedTime,
				NULL,
				NULL,
				av.AssetId,
				@GLJournalId,
				NULL,
				0,
				1,
				av.IsLeaseComponent
			FROM 
				#AssetValues av

		INSERT INTO SKUValueProportions
		(Value_Amount
		,Value_Currency
		,CreatedById
		,CreatedTime
		,AssetSKUId
		,IsActive
		,AssetValueHistoryId)	
		SELECT 
		asv.Cost,
		@AssetCurrency,
		@CreatedById, 
	    @CreatedTime,
		asv.AssetSKUId
		,1
		,avh.AssetValueHistoryId
		FROM #AssetSKUValues asv
		JOIN #InsertedAssetValueHistories avh on asv.AssetId = avh.AssetId and asv.IsLeaseComponent = avh.IsLeaseComponent'

		IF (@IsMigrationCall = 1)
        BEGIN
           SET @SQL = @SQL + ' OPTION (LOOP JOIN)'
        END   
        EXEC SP_EXECUTESQL @SQL,
		N'
        @CreatedById BIGINT , 
        @CreatedTime DATETIMEOFFSET , 
        @AssetCurrency NVARCHAR(6),
		@SourceModule  NVARCHAR(40),
		@PayableInvoiceId BIGINT,
		@IncomeDate DATETIMEOFFSET,
		@GLJournalId BIGINT', 
        @CreatedById = @CreatedById,  
        @CreatedTime = @CreatedTime , 
        @AssetCurrency = @AssetCurrency,
		@SourceModule  = @SourceModule,
		@PayableInvoiceId = @PayableInvoiceId,
		@IncomeDate = @IncomeDate,
		@GLJournalId = @GLJournalId
	END

	UPDATE Assets SET 
	PropertyTaxCost_Amount = 
	CASE 
		WHEN (Assets.IsEligibleForPropertyTax = 1 AND Assets.PropertyTaxCost_Amount=0) THEN ROUND(PayableInvoiceAssets.AcquisitionCost_Amount * @ExchangeRate,2)
		ELSE Assets.PropertyTaxCost_Amount 
	END,
	PropertyTaxCost_Currency = @AssetCurrency,
	PropertyTaxDate=
	CASE 
		WHEN (Assets.IsEligibleForPropertyTax = 1 AND Assets.PropertyTaxDate IS NULL) THEN @IncomeDate
		ELSE Assets.PropertyTaxDate 
	END,
	UpdatedById = @CreatedById,
	UpdatedTime = @CreatedTime
	FROM Assets
	INNER JOIN PayableInvoiceAssets
			ON Assets.Id = PayableInvoiceAssets.AssetId AND
			   PayableInvoiceAssets.PayableInvoiceId = @PayableInvoiceId AND
			   Assets.FinancialType = @Real AND
			   Assets.IsEligibleForPropertyTax = 1 AND
			PayableInvoiceAssets.IsActive = 1 -- Added this condition RS
	INNER JOIN PayableInvoices
			ON PayableInvoiceAssets.PayableInvoiceId = PayableInvoices.Id AND
			   PayableInvoices.Id = @PayableInvoiceId AND
			   PayableInvoices.AllowCreateAssets = 0

	UPDATE Assets SET Salvage_Currency = @AssetCurrency, CurrencyCode = @AssetCurrency,UpdatedById = @CreatedById,UpdatedTime = @CreatedTime
	FROM Assets
	INNER JOIN PayableInvoiceAssets
			ON Assets.Id = PayableInvoiceAssets.AssetId AND
			PayableInvoiceAssets.PayableInvoiceId = @PayableInvoiceId AND
			PayableInvoiceAssets.IsActive = 1 -- Added this condition RS

IF OBJECT_ID('tempdb..#AssetValues') IS NOT NULL
	DROP TABLE #AssetValues;
IF OBJECT_ID('tempdb..#InsertedAssetValueHistories') IS NOT NULL
	DROP TABLE #InsertedAssetValueHistories;
IF OBJECT_ID('tempdb..#AssetValueHistoriesToInactivate') IS NOT NULL
	DROP TABLE #AssetValueHistoriesToInactivate;
IF OBJECT_ID('tempdb..#AssetSKUValues') IS NOT NULL
	DROP TABLE #AssetSKUValues;
IF OBJECT_ID('tempdb..#AVH1') IS NOT NULL
	DROP TABLE #AVH1;
IF OBJECT_ID('tempdb..#AVH2') IS NOT NULL
	DROP TABLE #AVH2;	
SET NOCOUNT OFF
END

GO

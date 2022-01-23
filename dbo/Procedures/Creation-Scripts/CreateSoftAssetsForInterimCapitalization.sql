SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[CreateSoftAssetsForInterimCapitalization]
(
	@ContractId BIGINT,
	@LeaseFinanceId BIGINT,
	@SequenceNumber NVARCHAR(30),
	@CommencementDate DATETIME,
	@AssetStatusLeased NVARCHAR(20),
	@AssetFinancialType NVARCHAR(20),
	@AssetMode NVARCHAR(50),
	@AssetHistoryReasonNew NVARCHAR(15),
	@SourceModule NVARCHAR(25),	
	@CapitalizedInterimInterest NVARCHAR(200),
	@CapitalizedInterimRent NVARCHAR(200),
	@CapitalizedSalesTax NVARCHAR(200),
	@CapitalizedProgressPayments NVARCHAR(200),	
	@CreatedById BIGINT,
	@CreatedTime DATETIMEOFFSET,
	@CollateralCodeForCapitalizedInterimSoftAsset NVARCHAR(100),
	@CapitalizedAdditionalChargeAssets CapitalizedAdditionalChargeAssets READONLY
)
AS
BEGIN
SET NOCOUNT ON

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	CREATE TABLE #CapitalizationAssetTypes
	(
		Id BIGINT,
		Name NVARCHAR(100),
		EnumName NVARCHAR(30)
	)
	INSERT INTO #CapitalizationAssetTypes
	SELECT Id,Name,'CapitalizedInterimInterest' 
		FROM AssetTypes WHERE IsActive = 1 AND Name =(@CapitalizedInterimInterest)
	INSERT INTO #CapitalizationAssetTypes
	SELECT Id,Name,'CapitalizedInterimRent' 
		FROM AssetTypes WHERE IsActive = 1 AND Name =(@CapitalizedInterimRent)
	INSERT INTO #CapitalizationAssetTypes
	SELECT Id,Name,'CapitalizedSalesTax' 
		FROM AssetTypes WHERE IsActive = 1 AND Name =(@CapitalizedSalesTax)
	INSERT INTO #CapitalizationAssetTypes
	SELECT Id,Name,'CapitalizedProgressPayment'
		FROM AssetTypes WHERE IsActive = 1 AND Name =(@CapitalizedProgressPayments)

    CREATE TABLE #CapitalizedAssetCollateralCode
    (
        AssetCatalogId BIGINT,
        CollateralCode NVARCHAR(100),
        ManufacturerId BIGINT,
        MakeId BIGINT,
        ModelId BIGINT,
        ProductId BIGINT,
        AssetCategoryId BIGINT,
        AssetClass2Id BIGINT,
        Class1 NVARCHAR(40),
        Class3 NVARCHAR(200)
    )    
    INSERT INTO #CapitalizedAssetCollateralCode
        SELECT TOP 1
            AssetCatalogs.Id AssetCatalogId,
            AssetCatalogs.CollateralCode,
            AssetCatalogs.ManufacturerId,
            AssetCatalogs.MakeId,
            AssetCatalogs.ModelId,
            AssetCatalogs.ProductId,
            AssetCatalogs.AssetCategoryId,
            AssetCatalogs.Class2Id [AssetClass2Id],
            Manufacturers.Class1,
            AssetCatalogs.Class3
        FROM AssetCatalogs 
        JOIN Manufacturers
        ON Manufacturers.Id = AssetCatalogs.ManufacturerId
		WHERE AssetCatalogs.CollateralCode IN (@CollateralCodeForCapitalizedInterimSoftAsset)
            AND AssetCatalogs.IsActive = 1
	CREATE TABLE #AssetDetails
	(
		Id BIGINT NOT NULL IDENTITY(1,1) PRIMARY KEY,
		RowNumber BIGINT,		
		SoftLeaseAssetId BIGINT,
		CapitalizedForId BIGINT,
		IsSoftLeaseAssetActive BIT,
		SoftAssetStatus NVARCHAR(25),
		CpitalizedForLeaseAssetId BIGINT,
		IsCapitalizedForLeaseAssetActive BIT,
		CapitalizedForAssetId BIGINT,
		CapitalizedForAssetStatus NVARCHAR(25),
		CapitalizedForAssetFinancialType NVARCHAR(25),
		CapitalizedForAssetAlias NVARCHAR(100),
		CapitalizedForAssetPartNumber NVARCHAR(100),
		CapitalizedForAssetLegalEntityId BIGINT,
		CapitalizedForAssetCustomerId BIGINT,
		--CapitalizedForAssetManufacturerId BIGINT,
		CapitalizedForAssetCurrencyCode NVARCHAR(6),
		AssetTypeId BIGINT,
		AssetTypeName NVARCHAR(500),
		SoftAssetId BIGINT,
		PropertyTaxCostCurrency NVARCHAR(3),
		UsageCondition NVARCHAR(15),
        IsTaxExempt BIT,
        IsManufacturerOverride BIT,

        AssetCatalogId BIGINT,
        ManufacturerId BIGINT,
        MakeId BIGINT,
        ModelId BIGINT,
        ProductId BIGINT,
        AssetCategoryId BIGINT,
        AssetClass2Id BIGINT,
        Class1 NVARCHAR(40),
        Class3 NVARCHAR(200),
		IsLeaseComponent BIT
	)

	CREATE TABLE #CreatedAssetDetails
	(
		Id BIGINT NOT NULL IDENTITY(1,1) PRIMARY KEY,
		AssetId BIGINT,
		LeaseAssetId BIGINT
	)

	CREATE TABLE #InsertedTaxExemptRuleIds
	   (
	   Id BIGINT,
	   RowNumber BIGINT
	   )
	   
INSERT INTO #AssetDetails
	SELECT
		 NULL 
		,SoftLeaseAsset.Id
		,SoftLeaseAsset.CapitalizedForId
		,SoftLeaseAsset.IsActive
		,Asset.Status
		,CapitalizedForLeaseAsset.Id
		,CapitalizedForLeaseAsset.IsActive
		,CASE WHEN CapitalizedForAsset.Id IS NOT NULL THEN CapitalizedForAsset.Id
			  WHEN CapitalizedForAdditionalChargeAsset.Id IS NOT NULL THEN CapitalizedForAdditionalChargeAsset.Id
			  ELSE CapitalizedSalesTaxForAsset.Id END
		,CASE WHEN CapitalizedForAsset.Id IS NOT NULL THEN CapitalizedForAsset.Status
			  WHEN CapitalizedForAdditionalChargeAsset.Id IS NOT NULL THEN CapitalizedForAdditionalChargeAsset.Status
			  ELSE CapitalizedSalesTaxForAsset.Status END
		,CASE WHEN CapitalizedForAsset.Id IS NOT NULL THEN CapitalizedForAsset.FinancialType
			  WHEN CapitalizedForAdditionalChargeAsset.Id IS NOT NULL THEN CapitalizedForAdditionalChargeAsset.FinancialType
			  ELSE CapitalizedSalesTaxForAsset.FinancialType END
		,CASE WHEN CapitalizedForAsset.Id IS NOT NULL THEN CapitalizedForAsset.Alias
			  WHEN CapitalizedForAdditionalChargeAsset.Id IS NOT NULL THEN CapitalizedForAdditionalChargeAsset.Alias
			  ELSE CapitalizedSalesTaxForAsset.Alias END
		,CASE WHEN CapitalizedForAsset.Id IS NOT NULL THEN CapitalizedForAsset.PartNumber
			  WHEN CapitalizedForAdditionalChargeAsset.Id IS NOT NULL THEN CapitalizedForAdditionalChargeAsset.PartNumber
			  ELSE CapitalizedSalesTaxForAsset.PartNumber END
		,CASE WHEN CapitalizedForAsset.Id IS NOT NULL THEN CapitalizedForAsset.LegalEntityId
			  WHEN CapitalizedForAdditionalChargeAsset.Id IS NOT NULL THEN CapitalizedForAdditionalChargeAsset.LegalEntityId
			  ELSE CapitalizedSalesTaxForAsset.LegalEntityId END
		,CASE WHEN CapitalizedForAsset.Id IS NOT NULL THEN CapitalizedForAsset.CustomerId
			  WHEN CapitalizedForAdditionalChargeAsset.Id IS NOT NULL THEN CapitalizedForAdditionalChargeAsset.CustomerId
			  ELSE CapitalizedSalesTaxForAsset.CustomerId END
		,CASE WHEN CapitalizedForAsset.Id IS NOT NULL THEN CapitalizedForAsset.CurrencyCode
			  WHEN CapitalizedForAdditionalChargeAsset.Id IS NOT NULL THEN CapitalizedForAdditionalChargeAsset.CurrencyCode
			  ELSE CapitalizedSalesTaxForAsset.CurrencyCode END
		,(SELECT TOP 1 Id FROM #CapitalizationAssetTypes WHERE EnumName = SoftLeaseAsset.CapitalizationType)
		,SoftLeaseAsset.CapitalizationType
		,Asset.Id
		,CASE WHEN CapitalizedForAsset.Id IS NOT NULL THEN CapitalizedForAsset.PropertyTaxCost_Currency
			  WHEN CapitalizedForAdditionalChargeAsset.Id IS NOT NULL THEN CapitalizedForAdditionalChargeAsset.PropertyTaxCost_Currency
			  ELSE CapitalizedSalesTaxForAsset.PropertyTaxCost_Currency END
		,CASE WHEN CapitalizedForAsset.Id IS NOT NULL THEN CapitalizedForAsset.UsageCondition
			  WHEN CapitalizedForAdditionalChargeAsset.Id IS NOT NULL THEN CapitalizedForAdditionalChargeAsset.UsageCondition
			  ELSE CapitalizedSalesTaxForAsset.UsageCondition END
        ,CASE WHEN CapitalizedForAsset.Id IS NOT NULL THEN CapitalizedForAsset.IsTaxExempt
			  WHEN CapitalizedForAdditionalChargeAsset.Id IS NOT NULL THEN CapitalizedForAdditionalChargeAsset.IsTaxExempt
			  ELSE CapitalizedSalesTaxForAsset.IsTaxExempt END
        ,Asset.IsManufacturerOverride
        
        ,(SELECT AssetCatalogId FROM #CapitalizedAssetCollateralCode)
        ,(SELECT ManufacturerId FROM #CapitalizedAssetCollateralCode)
        ,(SELECT MakeId FROM #CapitalizedAssetCollateralCode)
        ,(SELECT ModelId FROM #CapitalizedAssetCollateralCode)
        ,(SELECT ProductId FROM #CapitalizedAssetCollateralCode)
        ,(SELECT AssetCategoryId FROM #CapitalizedAssetCollateralCode)
        ,(SELECT AssetClass2Id FROM #CapitalizedAssetCollateralCode)
        ,(SELECT Class1 FROM #CapitalizedAssetCollateralCode)
        ,(SELECT Class3 FROM #CapitalizedAssetCollateralCode)
		,SoftLeaseAsset.IsLeaseAsset
	FROM LeaseFinances LeaseFinance
	INNER JOIN LeaseAssets SoftLeaseAsset ON LeaseFinance.Id = SoftLeaseAsset.LeaseFinanceId
	LEFT JOIN Assets Asset ON SoftLeaseAsset.AssetId = Asset.Id
	INNER JOIN LeaseAssets CapitalizedForLeaseAsset ON SoftLeaseAsset.CapitalizedForId = CapitalizedForLeaseAsset.Id
	LEFT JOIN Assets CapitalizedForAsset ON CapitalizedForLeaseAsset.IsAdditionalChargeSoftAsset = 0 AND CapitalizedForLeaseAsset.AssetId = CapitalizedForAsset.Id
	LEFT JOIN @CapitalizedAdditionalChargeAssets CapitalizedForAdditionalChargeLeaseAsset ON CapitalizedForLeaseAsset.IsAdditionalChargeSoftAsset = 1 AND CapitalizedForLeaseAsset.Id = CapitalizedForAdditionalChargeLeaseAsset.LeaseAssetId
	LEFT JOIN Assets CapitalizedForAdditionalChargeAsset ON CapitalizedForAdditionalChargeLeaseAsset.AssetId = CapitalizedForAdditionalChargeAsset.Id
    LEFT JOIN LeaseAssets CapitalizedLeaseAssetForSalesTax ON CapitalizedForLeaseAsset.CapitalizedForId = CapitalizedLeaseAssetForSalesTax.Id
    LEFT JOIN Assets CapitalizedSalesTaxForAsset ON CapitalizedLeaseAssetForSalesTax.AssetId = CapitalizedSalesTaxForAsset.Id
	WHERE LeaseFinance.Id = @LeaseFinanceId
    AND (CapitalizedForLeaseAsset.AssetId IS NOT NULL OR CapitalizedForAdditionalChargeLeaseAsset.AssetId IS NOT NULL OR CapitalizedLeaseAssetForSalesTax.AssetId IS NOT NULL)

	DECLARE @TotalRecords INT;
	DECLARE @RowNumber INT;
	DECLARE @Identity INT;
    DECLARE @SoftAssetCount INT;
    DECLARE @PropertyTaxResponsibility NVARCHAR(16);

    SET @PropertyTaxResponsibility = 'DoNotRemit';

	SELECT @TotalRecords = COUNT(Id) FROM #AssetDetails;

    SELECT @SoftAssetCount = (Count(DISTINCT(Assets.Id))) FROM Assets
    JOIN LeaseAssets ON Assets.Id = LeaseAssets.AssetId
    JOIN LeaseFinances ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id
    JOIN Contracts ON LeaseFinances.ContractId = Contracts.Id
    WHERE Contracts.Id = @ContractId AND LeaseAssets.CapitalizedForId IS NOT NULL
	
	SELECT @RowNumber = @SoftAssetCount;
	
	SET @Identity = 1;

	WHILE(@Identity <= @TotalRecords)
	BEGIN
		UPDATE #AssetDetails SET RowNumber = @RowNumber + 1 WHERE Id = @Identity AND SoftAssetId IS NULL AND IsSoftLeaseAssetActive = 1
		SET @Identity = @Identity + 1
		SET @RowNumber = @RowNumber + 1
	END




MERGE INTO TaxExemptRules
USING (SELECT * FROM  #AssetDetails WHERE SoftAssetId IS NULL AND IsSoftLeaseAssetActive = 1) AS AE
ON 1 = 0
WHEN NOT MATCHED THEN
   INSERT
	    ([EntityType]
	    ,[IsCountryTaxExempt]
	    ,[IsStateTaxExempt]
	    ,[CreatedById]
	    ,[CreatedTime]
	    ,[TaxExemptionReasonId]
		,IsCityTaxExempt
		,IsCountyTaxExempt
		,StateTaxExemptionReasonId)
    VALUES(
	    'Asset'
	    ,0
	    ,0
	   ,@CreatedById
	   ,@CreatedTime
	   ,(SELECT TOP 1 ID FROM TaxExemptionReasonConfigs WHERE EntityType = 'Asset' AND Reason = 'Dummy')	
	   ,0
	   ,0
	   ,(SELECT TOP 1 ID FROM TaxExemptionReasonConfigs WHERE EntityType = 'Asset' AND Reason = 'Dummy'))
	   Output inserted.Id, AE.RowNumber INTO #InsertedTaxExemptRuleIds;

	MERGE INTO Assets
	USING (SELECT #AssetDetails .*, Tax.Id AS TaxId FROM #AssetDetails 
		  INNER JOIN #InsertedTaxExemptRuleIds Tax ON #AssetDetails.RowNumber = Tax.RowNumber
		  WHERE IsSoftLeaseAssetActive = 1) AS AssetDetail
		ON Assets.Id = AssetDetail.SoftAssetId
	WHEN MATCHED THEN
	UPDATE SET
		 [Alias] = Assets.Alias
		,[AcquisitionDate] = @CommencementDate
		,[PartNumber] = AssetDetail.CapitalizedForAssetPartNumber
		,[UsageCondition] = AssetDetail.UsageCondition
		,[Description] = AssetDetail.AssetTypeName
		,[Quantity] = 1
		,[InServiceDate] = @CommencementDate
		,[IsEligibleForPropertyTax] = 0
		,[Status] = @AssetStatusLeased
		,[FinancialType] = @AssetFinancialType
		,[MoveChildAssets] = 0
		,[AssetMode] = @AssetMode
		,[PropertyTaxCost_Amount] = 0
		,[PropertyTaxCost_Currency] = AssetDetail.PropertyTaxCostCurrency
		,[PropertyTaxDate] = NULL
		,[ProspectiveContract] = NULL
		,[CurrencyCode] = AssetDetail.CapitalizedForAssetCurrencyCode
		,[IsTaxExempt] = AssetDetail.IsTaxExempt
		,[UpdatedById] = @CreatedById
		,[UpdatedTime] = @CreatedTime
		--,[ManufacturerId] = AssetDetail.CapitalizedForAssetManufacturerId
		,[TypeId] = AssetDetail.AssetTypeId
		,[LegalEntityId] = AssetDetail.CapitalizedForAssetLegalEntityId
		,[CustomerId] = AssetDetail.CapitalizedForAssetCustomerId
		,[ParentAssetId] = NULL
		,[FeatureSetId] = NULL
		,[ClearAccumulatedGLTemplateId] = NULL
		,[TitleTransferCodeId] = NULL
		,[AssetUsageId] = NULL
		,[ModelYear] = NULL
		,[CustomerPurchaseOrderNumber] = NULL
		,[OwnershipStatus] = '_'
		,[PropertyTaxReportCodeId] = NULL
        ,[IsSystemCreated] = 1
        ,[IsTakedownAsset] = 0
        ,[IsOnCommencedLease] = 1
        ,[SubStatus] = '_'
        ,[PropertyTaxResponsibility] = @PropertyTaxResponsibility
        ,[IsManufacturerOverride]=Assets.IsManufacturerOverride
        ,[IsReversed]=0
	WHEN NOT MATCHED THEN
	INSERT 
		([Alias]
		,[AcquisitionDate]
		,[PartNumber]
		,[UsageCondition]
		,[Description]
		,[Quantity]
		,[InServiceDate]
		,[IsEligibleForPropertyTax]
		,[Status]
		,[FinancialType]
		,[MoveChildAssets]
		,[AssetMode]
		,[PropertyTaxCost_Amount]
		,[PropertyTaxCost_Currency]
		,[PropertyTaxDate]
		,[ProspectiveContract]
		,[CurrencyCode]
		,[IsTaxExempt]
		,[CreatedById]
		,[CreatedTime]
		--,[ManufacturerId]
		,[TypeId]
		,[LegalEntityId]
		,[CustomerId]
		,[ParentAssetId]
		,[FeatureSetId]
		,[ClearAccumulatedGLTemplateId]
		,[TitleTransferCodeId]
		,[AssetUsageId]
		,[PropertyTaxResponsibility]
		,[ModelYear]
		,[CustomerPurchaseOrderNumber]
		,[OwnershipStatus]
		,[PropertyTaxReportCodeId]
        ,[GrossVehicleWeight]
        ,[WeightMeasure]
        ,[IsOffLease]
        ,[IsElectronicallyDelivered]
        ,[IsSaleLeaseback]
        ,[IsParent]
        ,[IsSystemCreated]
        ,[IsTakedownAsset]
        ,[IsOnCommencedLease]
        ,[SubStatus]
            	
		,IsManufacturerOverride
		,DMDPercentage
		,DealerCost_Currency
		,DealerCost_Amount            	
        ,AssetCatalogId
        ,ManufacturerId
        ,MakeId
        ,ModelId
        ,ProductId
        ,AssetCategoryId
        ,AssetClass2Id
        ,Class1
        ,Class3
		,TaxExemptRuleId
		,IsReversed
        ,IsSerializedAsset
        ,Residual_Amount
        ,Residual_Currency
        ,IsVehicle
		,IsLeaseComponent
		,IsServiceOnly
		,IsSKU
		,IsTaxParameterChangedForLeasedAsset
		,Salvage_Amount
		,Salvage_Currency
		)	
	VALUES
		(AssetDetail.CapitalizedForAssetAlias +' - '+ @SequenceNumber + ' - '+ CAST(AssetDetail.RowNumber AS NVARCHAR(MAX))
		,@CommencementDate
		,AssetDetail.CapitalizedForAssetPartNumber
		,AssetDetail.UsageCondition
		,AssetDetail.AssetTypeName
		,1
		,@CommencementDate
		,0
		,@AssetStatusLeased
		,@AssetFinancialType
		,0
		,@AssetMode
		,0
		,AssetDetail.PropertyTaxCostCurrency
		,NULL
		,NULL
		,AssetDetail.CapitalizedForAssetCurrencyCode
		,0
		,@CreatedById
		,@CreatedTime
		--,AssetDetail.CapitalizedForAssetManufacturerId
		,AssetDetail.AssetTypeId
		,AssetDetail.CapitalizedForAssetLegalEntityId
		,AssetDetail.CapitalizedForAssetCustomerId
		,NULL
		,NULL
		,NULL
		,NULL
		,NULL
		,@PropertyTaxResponsibility
		,NULL
		,NULL
		,'_'
		,NULL
        ,0
        ,'_'
        ,0
        ,0
        ,0
        ,0
        ,1
        ,0
        ,1
        ,'_'
		,0 --IsManufacturerOverride
		,0 --DMDPercentage
        ,AssetDetail.PropertyTaxCostCurrency
		,'0' --DealerCost_Amount

        ,AssetDetail.AssetCatalogId
        ,AssetDetail.ManufacturerId
        ,AssetDetail.MakeId
        ,AssetDetail.ModelId
        ,AssetDetail.ProductId
        ,AssetDetail.AssetCategoryId
        ,AssetDetail.AssetClass2Id
        ,AssetDetail.Class1
        ,AssetDetail.Class3
	    ,AssetDetail.TaxId
        ,0
        ,0
        ,0
        ,AssetDetail.CapitalizedForAssetCurrencyCode
        ,0
		,AssetDetail.IsLeaseComponent
		,0
		,0
		,0
		,0
		,AssetDetail.CapitalizedForAssetCurrencyCode)

	OUTPUT Inserted.Id, AssetDetail.SoftLeaseAssetId INTO #CreatedAssetDetails(AssetId, LeaseAssetId);	
	
    MERGE AssetGLDetails AGL
    USING #CreatedAssetDetails CreatedAsset
    ON CreatedAsset.AssetId = AGL.Id
    WHEN NOT MATCHED
    THEN
	    INSERT
	    (
		    Id
		    ,HoldingStatus
		    ,CostCenterId
		    ,CreatedById
		    ,CreatedTime
		    ,UpdatedById
		    ,UpdatedTime
		    ,AssetBookValueAdjustmentGLTemplateId
		    ,BookDepreciationGLTemplateId
		    ,InstrumentTypeId 
		    ,LineofBusinessId 
	    )
	    VALUES
	    (
		    CreatedAsset.AssetId
		    ,'HFI'
		    ,NULL
		    ,1
		    ,SYSDATETIMEOFFSET()
		    ,NULL
		    ,NULL
		    ,NULL
		    ,NULL
		    ,NULL
		    ,NULL
	    )
	    ;

	DROP TABLE #CapitalizationAssetTypes
	DROP TABLE #AssetDetails
    DROP TABLE #CapitalizedAssetCollateralCode

	SELECT 
		LeaseAssetId,
		AssetId
	FROM #CreatedAssetDetails

    DROP TABLE #CreatedAssetDetails

SET NOCOUNT OFF
END

GO

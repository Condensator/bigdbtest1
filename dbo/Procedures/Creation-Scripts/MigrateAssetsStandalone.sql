SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[MigrateAssetsStandalone]
(
	@CreatedTime DATETIMEOFFSET = NULL
)
AS
BEGIN

SET NOCOUNT ON

IF(@CreatedTime IS NULL)
SET @CreatedTime = SYSDATETIMEOFFSET();

DECLARE @Counter INT = 0
DECLARE	@UserId BIGINT = (SELECT TOP 1 ID FROM Users WHERE LoginName = 'System.User')
DECLARE @ModuleIterationStatusId BIGINT 


INSERT INTO stgModuleIterationStatus
           ([Status]
           ,[StartTime]
           ,[CreatedById]
           ,[CreatedTime]
           ,[ModuleId])
     VALUES
           ('Processing'
           ,@CreatedTime
           ,@UserId
           ,@CreatedTime
           ,(SELECT TOP 1 ID FROM stgModule WHERE StagingRootEntity = 'Asset'))

SET @ModuleIterationStatusId = SCOPE_IDENTITY()

DECLARE @TakeCount INT = 500

DECLARE @SkipCount INT = 0

DECLARE @FetchParentAsset BIT = 1

DECLARE @MaxAssetId INT = 0

DECLARE @ProcessedRecords BIGINT =0
DECLARE @FailedRecords BIGINT =0

WHILE @Counter <= 1
BEGIN
	
	DECLARE @TotalRecordsCount INT = (SELECT COUNT(Id) FROM stgAsset IntermediateAsset
										 WHERE	IsMigrated = 0 AND 
												((@FetchParentAsset = 1 AND IntermediateAsset.ParentAssetAlias IS NOT NULL) OR
												(@FetchParentAsset = 0 AND IntermediateAsset.ParentAssetAlias IS NULL)))
	SET @MaxAssetId = 0
	SET @SkipCount = 0
	WHILE @SkipCount <= @TotalRecordsCount
	 BEGIN
		CREATE TABLE #CreatedAssetIds (
							 [Action] NVARCHAR(10) NOT NULL,
							 [Id] bigint NOT NULL,
							 [Alias] NVARCHAR(20) NOT NULL,
							 [AssetId] bigint NOT NULL,
							 [IsLeaseComponent] bit NOT NULL)

       CREATE TABLE #CreatedAssetSerialNumbers (  
                                                [Id] bigint NOT NULL,  
                                                [SerialNumber] NVARCHAR(200) NOT NULL,  
                                                [AssetId] bigint NOT NULL)

		CREATE TABLE #CreatedAssetFeatureIds (
												[Id] bigint NOT NULL)

		CREATE TABLE #CreatedAssetHistories(  
                                                [Id] bigint NOT NULL,  
                                                [AssetId] bigint NOT NULL)

		CREATE TABLE #AllSerialNumbersWithinAsset (  
                                                [SerialNumber] NVARCHAR(200) NOT NULL,  
                                                [AssetId] bigint NOT NULL)

		CREATE TABLE #FailedProcessingLogs (
							 [Action] NVARCHAR(10) NOT NULL,
							 [Id] bigint NOT NULL,
							 [AssetId] bigint NOT NULL)
							 
		CREATE TABLE #CreatedProcessingLogs (
							 [Action] NVARCHAR(10) NOT NULL,
							 [Id] bigint NOT NULL)
		CREATE TABLE #ErrorLogs
		(
			Id BIGINT not null IDENTITY PRIMARY KEY,
			StagingRootEntityId BIGINT,
			Result NVARCHAR(10),
			Message NVARCHAR(MAX)
		)
		CREATE TABLE #InsertedTaxExemptRuleIds
		(
			Id BIGINT,
			AssetId BIGINT
		)
		SELECT 
			TOP(@TakeCount) * INTO #AssetSubset 
		FROM 
			stgAsset IntermediateAsset
		WHERE
			IsMigrated = 0 AND 
			(((@FetchParentAsset = 1 AND IntermediateAsset.ParentAssetAlias IS NOT NULL) OR
			(@FetchParentAsset = 0 AND IntermediateAsset.ParentAssetAlias IS NULL)) AND
			IntermediateAsset.Id > @MaxAssetId )
		ORDER BY 
			IntermediateAsset.Id
			

		SELECT TOP(@TakeCount)
		   IntermediateAsset.Id [AssetId]
		  ,IntermediateAsset.[Alias]
		 ,IntermediateAsset.[AcquisitionDate]
		  ,IntermediateAsset.[PartNumber]
		  ,IntermediateAsset.[UsageCondition]
		  ,IntermediateAsset.[Description]
		  ,IntermediateAsset.[Quantity]
		  ,IntermediateAsset.[IsEligibleForPropertyTax]
		  ,IntermediateAsset.[InServiceDate]
		  ,IntermediateAsset.[Status]
		  ,IntermediateAsset.[FinancialType]
		  ,IntermediateAsset.[PropertyTaxCost_Amount]
		  ,IntermediateAsset.[PropertyTaxCost_Currency]
		  ,IntermediateAsset.[PropertyTaxDate]
		  ,IntermediateAsset.[CurrencyCode]
		  ,IntermediateAsset.[Manufacturer]
		  ,IntermediateAsset.[AssetType]
		  ,IntermediateAsset.[AssetProduct]
		  ,IntermediateAsset.[AssetCategory]
		  ,IntermediateAsset.[LegalEntityNumber]
		  ,IntermediateAsset.[CustomerPartyNumber]
		  ,IntermediateAsset.[ParentAssetAlias]
		  ,IntermediateAsset.[AssetFeatureSetName]
		  ,IntermediateAsset.[AssetUsage]
		  ,IntermediateAsset.[TitleTransferCode]
		  ,IntermediateAsset.[ClearAccumulatedGLTemplate]
		  ,IntermediateAsset.[CreatedById]
		  ,IntermediateAsset.[CreatedTime]
		  ,IntermediateAsset.[UpdatedById]
		  ,IntermediateAsset.[UpdatedTime]
		  ,IntermediateAsset.[Cost_Amount]
		  ,IntermediateAsset.[Cost_Currency]
		  ,IntermediateAsset.[IsMigrated] 
		  ,IntermediateAsset.[PropertyTaxResponsibility]
		  ,IntermediateAsset.ModelYear
		  ,IntermediateAsset.AssetMode
		  ,IntermediateAsset.OwnershipStatus
		  ,IntermediateAsset.CustomerPurchaseOrderNumber
		  ,IntermediateAsset.PropertyTaxReportCode
		  ,IntermediateAsset.IsSaleLeaseback
		  ,IntermediateAsset.PurchaseOrderDate
		  ,IntermediateAsset.GrossVehicleWeight
		  ,IntermediateAsset.WeightMeasure
		  ,IntermediateAsset.IsElectronicallyDelivered		  
		  ,PropertyTaxReportCodeConfigs.Id [PropertyTaxReportCodeId]
		  ,LegalEntities.Id [LegalEntityId]
		  ,LegalEntities.Status [LegalEntityStatus]
		  ,AssetTypes.Id [AssetTypeId]
		  ,AssetTypes.IsActive [IsAssetTypeActive]
		  ,Products.Id [ProductId]
		  ,Parties.Id CustomerId
		  ,Customers.Status [CustomerStatus]
		  ,AssetCategories.Id [CategoryId]
		  ,Manufacturers.Id [ManufacturerId]
		  ,Manufacturers.IsActive  [ManufacturerStatus]
		  ,Assets.Id ParentAssetId 
		  ,AssetFeatureSets.Id AssetFeatureId 
		  ,AssetUsages.Id AssetUsageId 
		  ,TitleTransferCodes.Id TitleTransferCodeId 
		  ,GLTemplates.Id ClearAccumulatedGLTemplateId
		  ,States.Id [StateId]
		  ,SaleLeasebackCodeConfigs.Id [SaleLeasebackCodeId]
		  ,VendorAssetCategoryConfigs.Id [VendorAssetCategoryId]
		  ,SalesTaxExemptionLevelConfigs.Id [SalesTaxExemptionLevelId]
		  ,0 [IsOnCommencedLease]
		  ,0 [IsTakedownAsset]
		  ,0 [IsSystemCreated]
		  ,IntermediateAsset.IsTaxExempt [IsTaxExempt]
		  ,IntermediateAsset.StateShortName
		  ,IntermediateAsset.SaleLeasebackCode
		  ,IntermediateAsset.VendorAssetCategoryName
		  ,IntermediateAsset.SalesTaxExemptionLevelName
		  ,IntermediateAsset.SubStatus 
		  ,IntermediateAsset.IsManufacturerOverride
		  ,AssetCatalogs.Id [AssetCatalogId]
		  ,GLTemplates.Id [AssetBookValueAdjustmentGLTemplateId]
		  ,GLTemplates.Id [BookDepreciationGLTemplateId]
		  ,InstrumentTypes.Id [InstrumentTypeId]
		  ,LineofBusinesses.Id [LineofBusinessId]
		  ,CostCenterConfigs.Id [CostCenterId]
		  ,IntermediateAsset.HoldingStatus
		  ,IntermediateAsset.Make
		  ,Makes.Id [MakeId]
		  ,Makes.IsActive  [MakeStatus]
		  ,IntermediateAsset.Model
		  ,Models.Id [ModelId]
		  ,Models.IsActive  [ModelStatus]
		  INTO #AssetsMappedWithTarget
		FROM 
			#AssetSubset IntermediateAsset
		LEFT JOIN LegalEntities
			   ON IntermediateAsset.LegalEntityNumber = LegalEntities.LegalEntityNumber
		LEFT JOIN AssetTypes
			   ON IntermediateAsset.AssetType = AssetTypes.Name
		LEFT JOIN Products
			   ON IntermediateAsset.AssetProduct = Products.Name AND
				  AssetTypes.ProductId = Products.Id
		LEFT JOIN AssetCategories
			   ON Products.AssetCategoryId = AssetCategories.Id AND
				  IntermediateAsset.AssetCategory = AssetCategories.Name
		LEFT JOIN Parties
			   ON IntermediateAsset.CustomerPartyNumber = Parties.PartyNumber
		LEFT JOIN Customers
			   ON Parties.Id = Customers.Id 
		LEFT JOIN Manufacturers
			   ON IntermediateAsset.Manufacturer = Manufacturers.Name
		LEFT JOIN Assets
			   ON IntermediateAsset.ParentAssetAlias = Assets.Alias
		LEFT JOIN AssetFeatureSets
			   ON IntermediateAsset.AssetFeatureSetName = AssetFeatureSets.Name
		LEFT JOIN AssetUsages
			   ON IntermediateAsset.AssetUsage = AssetUsages.Usage
		LEFT JOIN TitleTransferCodes
			   ON IntermediateAsset.TitleTransferCode = TitleTransferCodes.TransferCode
		LEFT JOIN GLTemplates
			   ON IntermediateAsset.[ClearAccumulatedGLTemplate] = GLTemplates.Name AND
		          GLTemplates.GLConfigurationId = LegalEntities.GLConfigurationId
		LEFT JOIN PropertyTaxReportCodeConfigs
			   ON PropertyTaxReportCodeConfigs.Code = IntermediateAsset.PropertyTaxReportCode
	    LEFT JOIN SaleLeasebackCodeConfigs
			   ON SaleLeasebackCodeConfigs.Code = IntermediateAsset.SaleLeasebackCode
		LEFT JOIN VendorAssetCategoryConfigs
			   ON VendorAssetCategoryConfigs.Name = IntermediateAsset.VendorAssetCategoryName
		LEFT JOIN SalesTaxExemptionLevelConfigs
			   ON SalesTaxExemptionLevelConfigs.Name = IntermediateAsset.SalesTaxExemptionLevelName
		LEFT JOIN States
			   ON States.ShortName = IntermediateAsset.StateShortName
		LEFT JOIN CostCenterConfigs
			   ON CostCenterConfigs.CostCenter = IntermediateAsset.CostCenter
		LEFT JOIN InstrumentTypes
			   ON InstrumentTypes.Code = IntermediateAsset.InstrumentTypeName
		LEFT JOIN LineofBusinesses
			   ON LineofBusinesses.Name = IntermediateAsset.LineofBusinessName
		LEFT JOIN AssetCatalogs
			   ON AssetCatalogs.CollateralCode = IntermediateAsset.CollateralCode
		LEFT JOIN GLTemplates as AssetBookValueAdjustmentGLTemplate
			   ON AssetBookValueAdjustmentGLTemplate.Name = IntermediateAsset.AssetBookValueAdjustmentGLTemplateName
		LEFT JOIN GLTemplates as BookDepreciationGLTemplate
			   ON BookDepreciationGLTemplate.Name = IntermediateAsset.BookDepreciationGLTemplateName
		LEFT JOIN Makes
			   ON IntermediateAsset.Make = Makes.Name
		LEFT JOIN Models
			   ON IntermediateAsset.Model = Models.Name
		WHERE
			((@FetchParentAsset = 1 AND IntermediateAsset.ParentAssetAlias IS NOT NULL) OR
			(@FetchParentAsset = 0 AND IntermediateAsset.ParentAssetAlias IS NULL)) AND
			IntermediateAsset.Id > @MaxAssetId 
		ORDER BY 
			IntermediateAsset.Id

		SELECT @MaxAssetId = MAX(AssetId) FROM #AssetsMappedWithTarget;
		
		SELECT 
				IntermediateAssetLocation.AssetId,
				IntermediateAsset.Alias,
				IntermediateAssetLocation.EffectiveFromDate,
				IntermediateAssetLocation.TaxBasisType,
				IntermediateAssetLocation.UpfrontTaxMode,
				IntermediateAsset.CustomerId,
				IntermediateAssetLocation.LocationCode,
				IntermediateAssetLocation.IsFLStampTaxExempt,
				IntermediateAssetLocation.UpfrontTaxAssessedInLegacySystem
				INTO #AssetLocationSubset 
		FROM 
				stgAssetLocation IntermediateAssetLocation
		INNER JOIN #AssetsMappedWithTarget IntermediateAsset ON IntermediateAsset.AssetId = IntermediateAssetLocation.AssetId


		SELECT 
			 IntermediateAssetLocation.AssetId [AssetId]
			,IntermediateAssetLocation.Alias [Alias]
			,IntermediateAssetLocation.EffectiveFromDate [EffectiveFromDate]
			,IntermediateAssetLocation.TaxBasisType [TaxBasisType]
			,IntermediateAssetLocation.UpfrontTaxMode [UpfrontTaxMode]
			,IntermediateAssetLocation.CustomerId [AssetCustomerId]
			,IntermediateAssetLocation.IsFLStampTaxExempt [IsFLStampTaxExempt]
			,Location.Code [LocationCode]
			,Location.Id [LocationId]
			,Location.CustomerId [LocationCustomerId]
			,IntermediateAssetLocation.UpfrontTaxAssessedInLegacySystem
		INTO #AssetLocationsMappedWithTarget 
		FROM 
				#AssetLocationSubset IntermediateAssetLocation
		LEFT JOIN Locations Location
			ON IntermediateAssetLocation.LocationCode = Location.Code

		

		SELECT 
				IntermediateAssetFeature.AssetId,
				IntermediateAssetFeature.Alias,
				IntermediateAssetFeature.Description,
				IntermediateAssetFeature.SerialNumber,
				IntermediateAssetFeature.Quantity,
				IntermediateAssetFeature.Manufacturer,
				IntermediateAssetFeature.AssetType,
				IntermediateAssetFeature.AssetProduct,
				IntermediateAssetFeature.AssetCategory,
				IntermediateAsset.Status [AssetStatus],
				IntermediateAssetFeature.Id [AssetFeatureId]
				INTO #AssetFeatureSubset 
		FROM 
				stgAssetFeature IntermediateAssetFeature
		INNER JOIN #AssetsMappedWithTarget IntermediateAsset 
			ON IntermediateAsset.AssetId = IntermediateAssetFeature.AssetId

		SELECT 
				IntermediateAssetFeature.AssetId,
				IntermediateAssetFeature.Alias,
				IntermediateAssetFeature.Description,
				IntermediateAssetFeature.SerialNumber,
				IntermediateAssetFeature.Quantity,
				Manufacturers.Id [ManufacturerId],
				Manufacturers.IsActive  [ManufacturerStatus],
				AssetTypes.Id [AssetTypeId],
				IntermediateAssetFeature.AssetType,
				IntermediateAssetFeature.AssetProduct,
				IntermediateAssetFeature.AssetCategory,
				AssetTypes.IsActive [AssetTypeStatus],
				AssetCategories.Id [AssetCategoryId],
				Products.Id [AssetProductId],
				IntermediateAssetFeature.AssetStatus,
				IntermediateAssetFeature.AssetFeatureId
				INTO #AssetFeatureMappedWithTarget 
		FROM 
				#AssetFeatureSubset IntermediateAssetFeature 
		LEFT JOIN AssetTypes 
			ON IntermediateAssetFeature.AssetType = AssetTypes.Name
		LEFT JOIN Products 
			ON Products.Name = IntermediateAssetFeature.AssetProduct
		LEFT JOIN AssetCategories 
			ON IntermediateAssetFeature.AssetCategory = AssetCategories.Name
		LEFT JOIN Manufacturers	
			ON IntermediateAssetFeature.Manufacturer = Manufacturers.Name

		SELECT ASN.*   
        INTO #AssetSerialNumberSubset  
        FROM #AssetsMappedWithTarget  IntermediateAsset
        INNER JOIN stgAssetSerialNumber ASN
			ON IntermediateAsset.AssetId = ASN.AssetId 
		 WHERE ASN.SerialNumber IS NOT NULL;

		SELECT AFSN.*   
        INTO #AssetFeatureSerialNumberSubset  
        FROM #AssetFeatureMappedWithTarget  
        INNER JOIN stgAssetFeatureSerialNumber AFSN ON #AssetFeatureMappedWithTarget.AssetFeatureId = AFSN.AssetFeatureId
		WHERE AFSN.SerialNumber IS NOT NULL
		
		SELECT 
				IntermediateAssetMeter.AssetId,
				IntermediateAssetMeter.BeginBalance,
				IntermediateAssetMeter.MaximumReading,
				IntermediateAssetMeter.AssetMeterType
			INTO #AssetMeterSubset 
		FROM 
			stgAssetMeter IntermediateAssetMeter
		INNER JOIN #AssetsMappedWithTarget IntermediateAsset 
			ON IntermediateAsset.AssetId = IntermediateAssetMeter.AssetId

		SELECT 
				AssetMeterTypes.Id [AssetMeterTypeId],
				IntermediateAssetMeter.AssetId,
				IntermediateAssetMeter.BeginBalance,
				IntermediateAssetMeter.MaximumReading,
				IntermediateAssetMeter.AssetMeterType,
				AssetMeterTypes.IsActive  [AssetMeterTypeStatus]
			INTO #AssetMeterMappedWithTarget 
		FROM 
			#AssetMeterSubset IntermediateAssetMeter
		LEFT JOIN AssetMeterTypes 
			ON IntermediateAssetMeter.AssetMeterType = AssetMeterTypes.Name


		INSERT INTO #AllSerialNumbersWithinAsset
		SELECT SerialNumber, AssetId
		FROM #AssetSerialNumberSubset
			  
		INSERT INTO #AllSerialNumbersWithinAsset
		SELECT AFSN.SerialNumber, AF.AssetId
		FROM #AssetFeatureMappedWithTarget AF
		INNER JOIN  #AssetFeatureSerialNumberSubset AFSN ON AF.Id = AFSN.AssetFeatureId

		INSERT INTO #ErrorLogs
        SELECT
            ASNWA.AssetId
        ,'Error'
        ,('The serial# entered is not unique within Asset/SKU/Feature for the Asset : ' + CAST (ASNWA.AssetId AS nvarchar(max)) ) AS Message
        FROM
		#AllSerialNumbersWithinAsset ASNWA
		GROUP BY AssetId, SerialNumber
		HAVING COUNT(*) > 1

		INSERT INTO #ErrorLogs
		SELECT
		#AssetsMappedWithTarget.Id
        ,'Error'
        ,('The count of asset serial# must be less than or equal to asset quantity for the Asset :' + CAST (#AssetsMappedWithTarget.Id AS nvarchar(max)) ) AS Message
		FROM
		#AssetSerialNumberSubset ASN
		JOIN #AssetsMappedWithTarget on ASN.AssetId = #AssetsMappedWithTarget.Id
		GROUP BY #AssetsMappedWithTarget.Id, #AssetsMappedWithTarget.Quantity
		HAVING COUNT(*) > #AssetsMappedWithTarget.Quantity

		INSERT INTO #ErrorLogs
		SELECT
		#AssetFeatureMappedWithTarget.AssetId
        ,'Error'
        ,('The count of asset feature serial# must be less than or equal to asset feature '+ CAST (#AssetFeatureMappedWithTarget.Id AS nvarchar(max))  + ' quantity for the Asset :' + CAST (#AssetFeatureMappedWithTarget.AssetId AS nvarchar(max)) ) AS Message
		FROM
		#AssetFeatureSerialNumberSubset AFSN
		JOIN #AssetFeatureMappedWithTarget on AFSN.AssetFeatureId = #AssetFeatureMappedWithTarget.Id
		GROUP BY #AssetFeatureMappedWithTarget.AssetId, #AssetFeatureMappedWithTarget.Id, #AssetFeatureMappedWithTarget.Quantity
		HAVING COUNT(*) > #AssetFeatureMappedWithTarget.Quantity

		INSERT INTO #ErrorLogs
		SELECT
		   AssetId
		  ,'Error'
		  ,('Asset Alias Must be Unique, Alias : ' +  #AssetsMappedWithTarget.Alias +' already exist' ) AS Message
		FROM 
			#AssetsMappedWithTarget
		LEFT JOIN Assets ON #AssetsMappedWithTarget.Alias = Assets.Alias
		WHERE 
			Assets.Alias IS NOT NULL

		INSERT INTO #ErrorLogs
		SELECT
		   AssetId
		  ,'Error'
		  ,('Property Tax Report Code is not present for the asset'+ #AssetsMappedWithTarget.Alias  + ' with filter criteria ' +  #AssetsMappedWithTarget.PropertyTaxReportCode ) AS Message
		FROM 
			#AssetsMappedWithTarget
		WHERE 
			#AssetsMappedWithTarget.PropertyTaxReportCode IS NOT NULL AND #AssetsMappedWithTarget.PropertyTaxReportCodeId IS NULL

		INSERT INTO #ErrorLogs
		SELECT
		   AssetId
		  ,'Error'
		  ,('No Matching Legal Entity with Legal Entity Number : ' + #AssetsMappedWithTarget.[LegalEntityNumber]) AS Message
		FROM 
			#AssetsMappedWithTarget
		WHERE 
			LegalEntityId IS NULL
	

		INSERT INTO #ErrorLogs
		SELECT
		   AssetId
		  ,'Error'
		  ,('Legal Entity Status must be Active') AS Message
		FROM 
			#AssetsMappedWithTarget
		WHERE 
			LegalEntityId IS NOT NULL AND
			LegalEntityStatus <> 'Active'
	

		INSERT INTO #ErrorLogs
		SELECT
		   AssetId
		  ,'Error'
		  ,('Matching Asset Type not found for Asset Type :' + #AssetsMappedWithTarget.AssetType + ', Asset Product : ' + #AssetsMappedWithTarget.AssetProduct + ', Asset Category : ' + #AssetsMappedWithTarget.AssetCategory + ' Combination') AS Message
		FROM 
			#AssetsMappedWithTarget
		WHERE 
			AssetTypeId IS NULL OR
			ProductId IS NULL OR
			CategoryId IS NULL


		INSERT INTO #ErrorLogs
		SELECT
		   AssetId
		  ,'Error'
		  ,('Asset Type must be Active') AS Message
		FROM 
			#AssetsMappedWithTarget
		WHERE 
			AssetTypeId IS NOT NULL AND
			ProductId IS NOT NULL AND
			CategoryId IS NOT NULL AND
			IsAssetTypeActive = 0

		INSERT INTO #ErrorLogs
		SELECT
		   AssetId
		  ,'Error'
		  ,('Matching Customer not found for <CustomerPartyNumber =>' + #AssetsMappedWithTarget.CustomerPartyNumber +'>') AS Message
		FROM 
			#AssetsMappedWithTarget
		WHERE 
			#AssetsMappedWithTarget.CustomerPartyNumber IS NOT NULL AND CustomerId IS NULL

		INSERT INTO #ErrorLogs
		SELECT
		   AssetId
		  ,'Error'
		  ,('Customer must be Active') AS Message
		FROM 
			#AssetsMappedWithTarget
		WHERE 
			CustomerId IS NOT NULL AND CustomerStatus <> 'Active'

		INSERT INTO #ErrorLogs
		SELECT
		   AssetId
		  ,'Error'
		  ,('Customer is required for Deposit Asset') AS Message
		FROM 
			#AssetsMappedWithTarget
		WHERE 
			#AssetsMappedWithTarget.FinancialType = 'Deposit' AND CustomerId IS NULL;

		INSERT INTO #ErrorLogs
		SELECT
		   AssetId
		  ,'Error'
		  ,('Financial Type must be Real / Deposit / Dummy while creating Asset') AS Message
		FROM 
			#AssetsMappedWithTarget
		WHERE 
			#AssetsMappedWithTarget.FinancialType NOT IN ( 'Deposit' , 'Real' , 'Dummy');
		
		INSERT INTO #ErrorLogs
		SELECT
		   AssetId
		  ,'Error'
		  ,('Collateral Asset must have Financial Type as Real or Dummy') AS Message
		FROM 
			#AssetsMappedWithTarget
		WHERE 
			#AssetsMappedWithTarget.Status = 'Collateral' AND  #AssetsMappedWithTarget.FinancialType NOT IN ( 'Real' ,'Dummy') ;
		
		INSERT INTO #ErrorLogs
		SELECT
		   AssetId
		  ,'Error'
		  ,('Investor Asset must have Financial Type as Real or Deposit') AS Message
		FROM 
			#AssetsMappedWithTarget
		WHERE 
			#AssetsMappedWithTarget.Status = 'Investor' AND #AssetsMappedWithTarget.FinancialType NOT IN ('Deposit' ,'Real');
		
		INSERT INTO #ErrorLogs
		SELECT
		   AssetId
		  ,'Error'
		  ,('Parent-Child Relationship is not allowed for Assets with Financial Type other than Real') AS Message
		FROM 
			#AssetsMappedWithTarget
		WHERE 
			#AssetsMappedWithTarget.ParentAssetId IS NOT NULL AND #AssetsMappedWithTarget.FinancialType != 'Real';
		
		INSERT INTO #ErrorLogs
		SELECT
		   AssetId
		  ,'Error'
		  ,('Status must be Inventory / Investor / Collateral while creating Asset') AS Message
		FROM 
			#AssetsMappedWithTarget
		WHERE 
			#AssetsMappedWithTarget.Status NOT IN ('Inventory','Investor','Collateral');

		INSERT INTO #ErrorLogs
		SELECT
		   #AssetsMappedWithTarget.AssetId
		  ,'Error'
		  ,('Please select a different Parent Asset, the current Parent Asset selected is itself a Child Asset') AS Message
		FROM 
			#AssetsMappedWithTarget 
			INNER JOIN #AssetsMappedWithTarget ParentAssetsMappedWithTarget ON #AssetsMappedWithTarget.ParentAssetId = ParentAssetsMappedWithTarget.AssetId
		WHERE 
			ParentAssetsMappedWithTarget.ParentAssetId IS NOT NULL ;

		INSERT INTO #ErrorLogs
		SELECT
		   #AssetsMappedWithTarget.AssetId
		  ,'Error'
		  ,('Parent Asset must belong to the selected Legal Entity') AS Message
		FROM 
			#AssetsMappedWithTarget 
			INNER JOIN #AssetsMappedWithTarget ParentAssetsMappedWithTarget ON #AssetsMappedWithTarget.ParentAssetId = ParentAssetsMappedWithTarget.AssetId
		WHERE 
			ParentAssetsMappedWithTarget.LegalEntityId != #AssetsMappedWithTarget.LegalEntityId ;

		INSERT INTO #ErrorLogs
		SELECT
		   #AssetsMappedWithTarget.AssetId
		  ,'Error'
		  ,('Parent Asset must belong to the selected Customer') AS Message
		FROM	
			#AssetsMappedWithTarget 
			INNER JOIN #AssetsMappedWithTarget ParentAssetsMappedWithTarget ON #AssetsMappedWithTarget.ParentAssetId = ParentAssetsMappedWithTarget.AssetId
		WHERE 
			ParentAssetsMappedWithTarget.CustomerId != #AssetsMappedWithTarget.CustomerId ;

		INSERT INTO #ErrorLogs
		SELECT
		   #AssetsMappedWithTarget.AssetId
		  ,'Error'
		  ,('Parent Asset Financial Type must be Real') AS Message
		FROM 
			#AssetsMappedWithTarget 
			INNER JOIN #AssetsMappedWithTarget ParentAssetsMappedWithTarget ON #AssetsMappedWithTarget.ParentAssetId = ParentAssetsMappedWithTarget.AssetId
		WHERE 
			ParentAssetsMappedWithTarget.FinancialType != 'Real' ;

		INSERT INTO #ErrorLogs
		SELECT
		   #AssetsMappedWithTarget.AssetId
		  ,'Error'
		  ,('Parent Asset Status must be same as current Asset Status') AS Message
		FROM 
			#AssetsMappedWithTarget 
			INNER JOIN #AssetsMappedWithTarget ParentAssetsMappedWithTarget ON #AssetsMappedWithTarget.ParentAssetId = ParentAssetsMappedWithTarget.AssetId
		WHERE 
			ParentAssetsMappedWithTarget.Status <>  #AssetsMappedWithTarget.Status;

		INSERT INTO #ErrorLogs
		SELECT
		   AssetId
		  ,'Error'
		  ,('Manufacturer must be Active') AS Message
		FROM 
			#AssetsMappedWithTarget
		WHERE 
			#AssetsMappedWithTarget.ManufacturerId  IS NOT NULL AND #AssetsMappedWithTarget.ManufacturerStatus <> 1 ;

		INSERT INTO #ErrorLogs
		SELECT
		   AssetId
		  ,'Error'
		  ,('Make must be Active') AS Message
		FROM 
			#AssetsMappedWithTarget
		WHERE 
			#AssetsMappedWithTarget.MakeId  IS NOT NULL AND #AssetsMappedWithTarget.MakeStatus <> 1 ;

	    INSERT INTO #ErrorLogs
		SELECT
		   AssetId
		  ,'Error'
		  ,('Model must be Active') AS Message
		FROM 
			#AssetsMappedWithTarget
		WHERE 
			#AssetsMappedWithTarget.ModelId  IS NOT NULL AND #AssetsMappedWithTarget.ModelStatus <> 1 ;

		INSERT INTO #ErrorLogs
		SELECT
		   AssetId
		  ,'Error'
		  ,('Quantity must be greater than 0') AS Message
		FROM 
			#AssetsMappedWithTarget
		WHERE 
			#AssetsMappedWithTarget.Quantity = 0 ;

		INSERT INTO #ErrorLogs
		SELECT
		   AssetId
		  ,'Error'
		  ,('Only Real Assets are Eligible for Property Tax Management') AS Message
		FROM 
			#AssetsMappedWithTarget
		WHERE 
			#AssetsMappedWithTarget.FinancialType <> 'Real' AND #AssetsMappedWithTarget.IsEligibleForPropertyTax = 1 ;
		
	
		INSERT INTO #ErrorLogs
		SELECT
			AssetId
			,'Error'
			,('Effective From Date must be unique among Asset Locations for the asset:' + #AssetLocationsMappedWithTarget.Alias) AS Message
		FROM
			#AssetLocationsMappedWithTarget 
				WHERE AssetId in  ( SELECT AssetId FROM ( SELECT *, RANK() OVER ( PARTITION BY AssetId , EffectiveFromDate ORDER BY AssetId DESC) rank 
									FROM #AssetLocationsMappedWithTarget )T WHERE rank > 1 )
		
		INSERT INTO #ErrorLogs
		SELECT
		   AssetId
		  ,'Error'
		  ,('Asset Type must be Active For the Asset Feature : '+Alias ) AS Message
		FROM 
			#AssetFeatureMappedWithTarget
		WHERE 
			AssetTypeStatus = 0

		INSERT INTO #ErrorLogs
		SELECT
		   AssetId
		  ,'Error'
		  ,('Manufacturer must be Active For the Asset Feature : '+Alias ) AS Message
		FROM 
			#AssetFeatureMappedWithTarget
		WHERE 
			ManufacturerStatus = 0

		
		INSERT INTO #ErrorLogs
		SELECT
		   AssetId
		  ,'Error'
		  ,('Quantity must be greater than 0 For the Asset Feature : '+Alias ) AS Message
		FROM 
			#AssetFeatureMappedWithTarget
		WHERE 
			Quantity = 0

		INSERT INTO #ErrorLogs
		SELECT
		   AssetId
		  ,'Error'
		  ,('No matching Asset Type Found for Asset Feature : '+Alias+' with Asset Type : '+AssetType) AS Message
		FROM 
			#AssetFeatureMappedWithTarget
		WHERE 
			AssetTypeId IS NULL 

		INSERT INTO #ErrorLogs
		SELECT
		   AssetId
		  ,'Error'
		  ,('No matching Asset Type Found for Asset Feature : '+Alias+' with Asset Category : '+AssetCategory) AS Message
		FROM 
			#AssetFeatureMappedWithTarget
		WHERE 
			AssetCategoryId IS NULL 

		INSERT INTO #ErrorLogs
		SELECT
		   AssetId
		  ,'Error'
		  ,('No matching Asset Type Found for Asset Feature :'+Alias+' with Asset Product : '+AssetProduct) AS Message
		FROM 
			#AssetFeatureMappedWithTarget
		WHERE 
			AssetProductId IS NULL 

		INSERT INTO #ErrorLogs
		SELECT
		   AssetId
		  ,'Error'
		  ,('No Matching Asset Meter Type Found for the Asset Meter Type : ' + #AssetMeterMappedWithTarget.AssetMeterType) AS Message
		FROM 
			#AssetMeterMappedWithTarget
		WHERE 
			AssetMeterTypeId IS NULL

		INSERT INTO #ErrorLogs
		SELECT
		   AssetId
		  ,'Error'
		  ,('Asset Meter Type must be Active') AS Message
		FROM 
			#AssetMeterMappedWithTarget
		WHERE 
			AssetMeterTypeId IS NOT NULL AND AssetMeterTypeStatus <> 1

		INSERT INTO #ErrorLogs
		SELECT
		   AssetId
		  ,'Error'
		  ,('Begin Reading must be greater than or equal to 0 in the Asset Meter Type :' + #AssetMeterMappedWithTarget.AssetMeterType) AS Message
		FROM 
			#AssetMeterMappedWithTarget
		WHERE 
			BeginBalance < 0

		INSERT INTO #ErrorLogs
		SELECT
		   AssetId
		  ,'Error'
		  ,('Maximum Reading must be greater than 0 in the Asset Meter Type :' + #AssetMeterMappedWithTarget.AssetMeterType) AS Message
		FROM 
			#AssetMeterMappedWithTarget
		WHERE 
			MaximumReading <= 0

		INSERT INTO #ErrorLogs
		SELECT
		   AssetId
		  ,'Error'
		  ,('Maximum Reading must be greater than Begin Reading in the Asset Meter Type : ' + #AssetMeterMappedWithTarget.AssetMeterType) AS Message
		FROM 
			#AssetMeterMappedWithTarget
		WHERE 
			MaximumReading < BeginBalance


		MERGE INTO TaxExemptRules
		USING (SELECT * FROM  #AssetsMappedWithTarget LEFT JOIN #ErrorLogs
					  ON #AssetsMappedWithTarget.AssetId = #ErrorLogs.StagingRootEntityId WHERE [AssetId] IS NOT NULL ) AS AE
		ON 1=0
		WHEN NOT MATCHED  AND AE.StagingRootEntityId IS NULL
		THEN
		INSERT
			([EntityType]
			,[IsCountryTaxExempt]
			,[IsStateTaxExempt]
			,[IsCityTaxExempt]
			,[IsCountyTaxExempt]
			,[CreatedById]
			,[CreatedTime]
			,[TaxExemptionReasonId])
		VALUES(
			'Asset'
			,0
			,0
			,0
			,0
			,@UserId
			,@CreatedTime
			,(SELECT TOP 1 ID FROM TaxExemptionReasonConfigs WHERE EntityType = 'Asset' AND Reason = 'Dummy')
			)
			OUTPUT inserted.Id,AE.AssetId INTO #InsertedTaxExemptRuleIds;


		
		SET IDENTITY_INSERT Assets ON

		MERGE Assets AS Asset
		USING (SELECT
				#AssetsMappedWithTarget.* ,#ErrorLogs.StagingRootEntityId,Tax.Id AS TaxId
			   FROM
				#AssetsMappedWithTarget 
			   LEFT JOIN #ErrorLogs
					  ON #AssetsMappedWithTarget.AssetId = #ErrorLogs.StagingRootEntityId
			   LEFT JOIN #InsertedTaxExemptRuleIds Tax ON #AssetsMappedWithTarget.AssetId = Tax.AssetId) AS AssetsToMigrate
		ON (Asset.Alias = AssetsToMigrate.[Alias])
		WHEN MATCHED AND AssetsToMigrate.StagingRootEntityId IS NULL THEN
			UPDATE SET Alias = AssetsToMigrate.Alias
		WHEN NOT MATCHED  AND AssetsToMigrate.StagingRootEntityId IS NULL
		THEN
			INSERT
           ([Id]
		   ,[Alias]
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
		   ,[IsManufacturerOverride]
           ,[CurrencyCode]
           ,[CreatedTime]
           ,[UpdatedTime]
           ,[ManufacturerId]
           ,[TypeId]
           ,[LegalEntityId]
           ,[CustomerId]
           ,[ParentAssetId]
           ,[FeatureSetId]
           ,[AssetUsageId]
           ,[IsTaxExempt]
           ,[TitleTransferCodeId]
           ,[ClearAccumulatedGLTemplateId]
           ,[CreatedById]
           ,[UpdatedById]
		   ,[ModelYear]
		   ,[CustomerPurchaseOrderNumber]
		   ,[OwnershipStatus]
		   ,[PropertyTaxReportCodeId]
		   ,[PropertyTaxResponsibility]
		   ,[IsSaleLeaseback]
		   ,[PurchaseOrderDate]
		   ,[GrossVehicleWeight]
		   ,[WeightMeasure]
		   ,[IsElectronicallyDelivered]
		   ,[IsOffLease]
		   ,[IsParent]
		   ,[IsOnCommencedLease]
		   ,[IsTakedownAsset]
		   ,[IsSystemCreated]
		   ,[StateId]
		   ,[VendorAssetCategoryId]
		   ,[SaleLeasebackCodeId]
		   ,[SalesTaxExemptionLevelId]
		   ,[SubStatus]
		   ,[AssetCatalogId] 
		   ,[TaxExemptRuleId]
		   ,IsReversed
		   ,[MakeId]
		   ,[ModelId]
		   ,IsTaxParameterChangedForLeasedAsset
		   ,Salvage_Amount
		   ,Salvage_Currency)
     VALUES
		   ( AssetsToMigrate.Alias
		    ,AssetsToMigrate.Alias
		    ,AssetsToMigrate.[AcquisitionDate]
			,AssetsToMigrate.PartNumber
			,AssetsToMigrate.[UsageCondition]
            ,AssetsToMigrate.[Description]
            ,AssetsToMigrate.[Quantity]
            ,AssetsToMigrate.[InServiceDate]
            ,AssetsToMigrate.[IsEligibleForPropertyTax]
            ,AssetsToMigrate.[Status]
			,AssetsToMigrate.[FinancialType]
			,1
			,AssetsToMigrate.AssetMode
			,AssetsToMigrate.[PropertyTaxCost_Amount]
			,AssetsToMigrate.[PropertyTaxCost_Currency]
			,AssetsToMigrate.[PropertyTaxDate]
			,NULL
			,AssetsToMigrate.IsManufacturerOverride
			,AssetsToMigrate.CurrencyCode
			,@CreatedTime
			,NULL
			,AssetsToMigrate.ManufacturerId
			,AssetsToMigrate.[AssetTypeId]
			,AssetsToMigrate.LegalEntityId
			,AssetsToMigrate.CustomerId
			,AssetsToMigrate.ParentAssetId
			,AssetsToMigrate.AssetFeatureId
			,AssetsToMigrate.AssetUsageId
			,AssetsToMigrate.IsTaxExempt
			,AssetsToMigrate.TitleTransferCodeId
			,AssetsToMigrate.ClearAccumulatedGLTemplateId
			,@UserId
			,NULL
			,CASE WHEN AssetsToMigrate.ModelYear < 1000 THEN NULL ELSE AssetsToMigrate.ModelYear END
		    ,AssetsToMigrate.CustomerPurchaseOrderNumber
		    ,AssetsToMigrate.OwnershipStatus
		    ,AssetsToMigrate.PropertyTaxReportCodeId
			,AssetsToMigrate.PropertyTaxResponsibility
			,AssetsToMigrate.IsSaleLeaseback
			,AssetsToMigrate.PurchaseOrderDate
			,AssetsToMigrate.GrossVehicleWeight
			,AssetsToMigrate.WeightMeasure
			,AssetsToMigrate.IsElectronicallyDelivered
			,0	
			,0
			,0
			,0
			,0
			,AssetsToMigrate.StateId
			,AssetsToMigrate.VendorAssetCategoryId
			,AssetsToMigrate.SaleLeasebackCodeId
			,AssetsToMigrate.SalesTaxExemptionLevelId
			,AssetsToMigrate.SubStatus
			,AssetsToMigrate.AssetCatalogId 
			,AssetsToMigrate.TaxId 
			,0--IsReversed
			,AssetsToMigrate.MakeId
			,AssetsToMigrate.ModelId
			,0
			,AssetsToMigrate.Salvage_Amount
			,AssetsToMigrate.Salvage_Currency)
		OUTPUT $action, Inserted.Id,AssetsToMigrate.Alias, AssetsToMigrate.AssetId,AssetsToMigrate.IsLeaseComponent INTO #CreatedAssetIds;

		INSERT INTO AssetGLDetails
           ([Id]
		   ,[HoldingStatus]
           ,[CreatedById]
           ,[CreatedTime]
           ,[UpdatedById]
           ,[UpdatedTime]
           ,[AssetBookValueAdjustmentGLTemplateId]
           ,[BookDepreciationGLTemplateId]
           ,[InstrumentTypeId]
           ,[LineofBusinessId]
           ,[CostCenterId])
		Select 
		 #CreatedAssetIds.Id
		,#AssetsMappedWithTarget.HoldingStatus
		,@UserId
		,@CreatedTime
		,NUll
		,Null
		,#AssetsMappedWithTarget.AssetBookValueAdjustmentGLTemplateId
		,#AssetsMappedWithTarget.BookDepreciationGLTemplateId
		,#AssetsMappedWithTarget.InstrumentTypeId
		,#AssetsMappedWithTarget.LineofBusinessId
		,#AssetsMappedWithTarget.CostCenterId
			FROM #CreatedAssetIds 
			INNER JOIN #AssetsMappedWithTarget ON #AssetsMappedWithTarget.Alias = #CreatedAssetIds.Alias;

		SET IDENTITY_INSERT Assets OFF
		
		UPDATE  stgAsset SET IsMigrated = 1 
			WHERE Id in ( SELECT AssetId FROM #CreatedAssetIds);
		
		INSERT INTO AssetLocations
				(EffectiveFromDate
				,IsCurrent
				,UpfrontTaxMode
				,TaxBasisType
				,IsActive
				,IsFLStampTaxExempt
				,CreatedById
				,CreatedTime
				,UpdatedById
				,UpdatedTime
				,LocationId
				,AssetId
				,ReciprocityAmount_Amount
				,ReciprocityAmount_Currency
				,LienCredit_Amount
				,LienCredit_Currency
				,UpfrontTaxAssessedInLegacySystem)
		SELECT 
			#AssetLocationsMappedWithTarget.EffectiveFromDate,
			0,
			'_',
			#AssetLocationsMappedWithTarget.TaxBasisType,
			1,
			#AssetLocationsMappedWithTarget.IsFLStampTaxExempt,
			@UserId,
			@CreatedTime,
			NULL,
			NULL,
			#AssetLocationsMappedWithTarget.LocationId,
			#CreatedAssetIds.Id,
			0.0,
			#AssetsMappedWithTarget.CurrencyCode,
			0.0,
			#AssetsMappedWithTarget.CurrencyCode,
			#AssetLocationsMappedWithTarget.UpfrontTaxAssessedInLegacySystem
		FROM #AssetLocationsMappedWithTarget 
			INNER JOIN #CreatedAssetIds ON #CreatedAssetIds.AssetId = #AssetLocationsMappedWithTarget.AssetId
			INNER JOIN #AssetsMappedWithTarget ON #AssetsMappedWithTarget.AssetId = #CreatedAssetIds.AssetId;

		INSERT INTO AssetFeatures
					  (Alias
					  ,Description
					  ,IsActive
					  ,Quantity
					  ,CreatedTime
					  ,UpdatedTime
					  ,ManufacturerId
					  ,TypeId
					  ,AssetId
					  ,CreatedById
					  ,UpdatedById)
		OUTPUT Inserted.Id INTO #CreatedAssetFeatureIds
		SELECT 
			#AssetFeatureMappedWithTarget.Alias,
			#AssetFeatureMappedWithTarget.Description,
			1,
			#AssetFeatureMappedWithTarget.Quantity,
			@CreatedTime,
			NULL,
			#AssetFeatureMappedWithTarget.ManufacturerId,
			#AssetFeatureMappedWithTarget.AssetTypeId,
			#CreatedAssetIds.Id,
			@UserId,
			NULL
		FROM #AssetFeatureMappedWithTarget
			 INNER JOIN #CreatedAssetIds ON #CreatedAssetIds.AssetId = #AssetFeatureMappedWithTarget.AssetId;

		INSERT INTO AssetSerialNumbers
				(
					AssetId
					,SerialNumber
					,IsActive
					,CreatedTime
                    ,UpdatedTime
					,CreatedById  
                    ,UpdatedById
				)
			  OUTPUT Inserted.Id, Inserted.SerialNumber, Inserted.AssetId INTO #CreatedAssetSerialNumbers
				Select 
					#CreatedAssetIds.Id,
					ASN.SerialNumber,
					1,
					@CreatedTime,  
                    NULL,
					@UserId,  
                    NULL

				FROM #AssetSerialNumberSubset ASN
					INNER JOIN #CreatedAssetIds ON #CreatedAssetIds.AssetId = ASN.AssetId;

		INSERT INTO AssetFeatureSerialNumbers
				(
					 AssetFeatureId
					,SerialNumber
					,IsActive
					,CreatedTime
                    ,UpdatedTime
					,CreatedById  
                    ,UpdatedById
				)
				Select 
					#CreatedAssetFeatureIds.Id,
					AFSN.SerialNumber,
					1,
					@CreatedTime,  
                    NULL,
					@UserId,  
                    NULL

				FROM #AssetFeatureSerialNumberSubset AFSN
					INNER JOIN #CreatedAssetFeatureIds ON #CreatedAssetFeatureIds.Id = AFSN.AssetFeatureId;

		INSERT INTO AssetMeters
						(MaximumReading
						,IsActive
						,CreatedTime
						,UpdatedTime
						,AssetMeterTypeId
						,AssetId
						,CreatedById
						,UpdatedById
						,BeginReading)
		SELECT 
			#AssetMeterMappedWithTarget.MaximumReading,
			1,
			@CreatedTime,
			NULL,
			#AssetMeterMappedWithTarget.AssetMeterTypeId,
			#CreatedAssetIds.Id,
			@UserId,
			NULL,
			#AssetMeterMappedWithTarget.BeginBalance
		FROM #AssetMeterMappedWithTarget
		 INNER JOIN #CreatedAssetIds ON #CreatedAssetIds.AssetId = #AssetMeterMappedWithTarget.AssetId;

		Update parentAssets SET parentAssets.IsParent =  1
		FROM Assets parentAssets
		INNER JOIN Assets newAssets ON parentAssets.Id = newAssets.ParentAssetId
		INNER JOIN #CreatedAssetIds C ON newAssets.Id = C.Id

		UPDATE AssetLocations SET IsCurrent = 1 
			WHERE Id in (SELECT Id FROM AssetLocations INNER JOIN (SELECT AssetId, MAX(EffectiveFromDate) AS EffectiveFromDate FROM AssetLocations WHERE CreatedById = @UserId GROUP BY AssetId) T  
								ON AssetLocations.AssetId = T.AssetId  AND AssetLocations.EffectiveFromDate = T.EffectiveFromDate)
				 AND AssetId in (SELECT #CreatedAssetIds.Id FROM #CreatedAssetIds)
		INSERT INTO AssetValueHistories
						  (SourceModule
						  ,SourceModuleId
						  ,FromDate
						  ,ToDate
						  ,IncomeDate
						  ,Value_Amount
						  ,Value_Currency
						  ,Cost_Amount
						  ,Cost_Currency
						  ,NetValue_Amount
						  ,NetValue_Currency
						  ,BeginBookValue_Amount
						  ,BeginBookValue_Currency
						  ,EndBookValue_Amount
						  ,EndBookValue_Currency
						  ,IsAccounted
						  ,IsSchedule
						  ,IsCleared
						  ,PostDate
						  ,ReversalPostDate
						  ,CreatedTime
						  ,UpdatedTime
						  ,AssetId
						  ,GLJournalId
						  ,ReversalGLJournalId
						  ,CreatedById
						  ,UpdatedById
						  ,AdjustmentEntry
						  ,IsLeaseComponent)
		SELECT 
			'AssetProfile',
			#CreatedAssetIds.Id,
			NULL,
			NULL,
			#AssetsMappedWithTarget.AcquisitionDate,
			#AssetsMappedWithTarget.Cost_Amount,
			#AssetsMappedWithTarget.Cost_Currency,
			#AssetsMappedWithTarget.Cost_Amount,
			#AssetsMappedWithTarget.Cost_Currency,
			#AssetsMappedWithTarget.Cost_Amount,
			#AssetsMappedWithTarget.Cost_Currency,
			#AssetsMappedWithTarget.Cost_Amount,
			#AssetsMappedWithTarget.Cost_Currency,
			#AssetsMappedWithTarget.Cost_Amount,
			#AssetsMappedWithTarget.Cost_Currency,
			1,
			1,
			1,
			@CreatedTime,
			NULL,
			@CreatedTime,
			NULL,
			#CreatedAssetIds.Id,
			NULL,
			NULL,
			@UserId,
			NULL,
			0,
			#CreatedAssetIds.IsLeaseComponent
		FROM #CreatedAssetIds
		INNER JOIN #AssetsMappedWithTarget ON #AssetsMappedWithTarget.AssetId = #CreatedAssetIds.AssetId
		WHERE #AssetsMappedWithTarget.Cost_Amount <> 0

		INSERT INTO AssetHistories
						  (Reason
						  ,AsOfDate
						  ,AcquisitionDate
						 ,Status
						  ,FinancialType
						  ,SourceModule
						  ,SourceModuleId
						  ,CreatedTime
						  ,UpdatedTime
						  ,CustomerId
						  ,ParentAssetId
						  ,LegalEntityId
						  ,AssetId
						  ,CreatedById
						  ,UpdatedById
						  ,IsReversed)
		 OUTPUT Inserted.Id, Inserted.AssetId INTO #CreatedAssetHistories	    
		SELECT  
			#AssetsMappedWithTarget.UsageCondition,
			#AssetsMappedWithTarget.AcquisitionDate,
			#AssetsMappedWithTarget.AcquisitionDate,
			#AssetsMappedWithTarget.Status,
			#AssetsMappedWithTarget.FinancialType,
			'AssetProfile',
			#CreatedAssetIds.Id,
			@CreatedTime,
			NULL,
			#AssetsMappedWithTarget.CustomerId,
			NULL,
			#AssetsMappedWithTarget.LegalEntityId,
			#CreatedAssetIds.Id,
			@UserId,
			NULL,
			0
		FROM #CreatedAssetIds
		INNER JOIN #AssetsMappedWithTarget ON #AssetsMappedWithTarget.AssetId = #CreatedAssetIds.AssetId

		INSERT INTO AssetSerialNumberHistories
				(
					 AssetHistoryId
					,OldSerialNumber
					,NewSerialNumber
					,CreatedTime
                    ,UpdatedTime
					,CreatedById  
                    ,UpdatedById
				)
				Select 
					#CreatedAssetHistories.Id,
					null,
					ASN.SerialNumber,
					@CreatedTime,  
                    NULL,
					@UserId,  
                    NULL

				FROM #CreatedAssetSerialNumbers ASN
					INNER JOIN #CreatedAssetHistories ON #CreatedAssetHistories.AssetId = ASN.AssetId;


		MERGE stgProcessingLog AS ProcessingLog
		USING (SELECT
				AssetId
			   FROM
				#CreatedAssetIds
			  ) AS ProcessedAssets
		ON (ProcessingLog.StagingRootEntityId = ProcessedAssets.AssetId AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
		WHEN MATCHED THEN
			UPDATE SET UpdatedTime = @CreatedTime
		WHEN NOT MATCHED THEN
		INSERT
			(
				StagingRootEntityId
			   ,CreatedById
			   ,CreatedTime
			   ,ModuleIterationStatusId
			)
		VALUES
			(
				ProcessedAssets.AssetId
			   ,@UserId
			   ,@CreatedTime
			   ,@ModuleIterationStatusId
			)
		OUTPUT $action, Inserted.Id INTO #CreatedProcessingLogs;

		INSERT INTO 
			stgProcessingLogDetail
			(
				Message
			   ,Type
			   ,CreatedById
			   ,CreatedTime	
			   ,ProcessingLogId
			)
		SELECT
		    'Successful'
		   ,'Information'
		   ,@UserId
		   ,@CreatedTime
		   ,Id
		FROM
			#CreatedProcessingLogs

		MERGE stgProcessingLog AS ProcessingLog
		USING (SELECT
				DISTINCT StagingRootEntityId
			   FROM
				#ErrorLogs 
			  ) AS ErrorAssets
		ON (ProcessingLog.StagingRootEntityId = ErrorAssets.StagingRootEntityId AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
		WHEN MATCHED THEN
			UPDATE SET UpdatedTime = @CreatedTime
		WHEN NOT MATCHED THEN
		INSERT
			(
				StagingRootEntityId
			   ,CreatedById
			   ,CreatedTime
			   ,ModuleIterationStatusId
			)
		VALUES
			(
				ErrorAssets.StagingRootEntityId
			   ,@UserId
			   ,@CreatedTime
			   ,@ModuleIterationStatusId
			)
		OUTPUT $action, Inserted.Id,ErrorAssets.StagingRootEntityId INTO #FailedProcessingLogs;	
		
		DECLARE @TotalRecordsFailed INT = (SELECT  COUNT( DISTINCT Id) FROM #FailedProcessingLogs)

		INSERT INTO 
			stgProcessingLogDetail
			(
				Message
			   ,Type
			   ,CreatedById
			   ,CreatedTime	
			   ,ProcessingLogId
			)
		SELECT
		    #ErrorLogs.Message
		   ,#ErrorLogs.Result
		   ,@UserId
		   ,@CreatedTime
		   ,#FailedProcessingLogs.Id
		FROM
			#ErrorLogs
		INNER JOIN #FailedProcessingLogs
				ON #ErrorLogs.StagingRootEntityId = #FailedProcessingLogs.AssetId
	
	SET @FailedRecords =  @FailedRecords + @TotalRecordsFailed
	SET @SkipCount = @SkipCount + @TakeCount
	DROP TABLE #ErrorLogs
	DROP TABLE #AssetSubset
	DROP TABLE #AssetsMappedWithTarget
	DROP TABLE #AssetLocationSubset
	DROP TABLE #AssetLocationsMappedWithTarget 
	DROP TABLE #AssetFeatureSubset 
	DROP TABLE #AssetFeatureMappedWithTarget 
	DROP TABLE #AssetMeterSubset 
	DROP TABLE #AssetMeterMappedWithTarget 
	DROP TABLE #CreatedAssetIds
	DROP TABLE #FailedProcessingLogs
	DROP TABLE #CreatedProcessingLogs
	DROP TABLE #InsertedTaxExemptRuleIds
	DROP TABLE #CreatedAssetSerialNumbers
	DROP TABLE #CreatedAssetFeatureIds
	DROP TABLE #CreatedAssetHistories
	DROP TABLE #AllSerialNumbersWithinAsset
	DROP TABLE #AssetSerialNumberSubset
	DROP TABLE #AssetFeatureSerialNumberSubset

	END	 
	SET @Counter = @Counter + 1;

	SET @FetchParentAsset = 0

	SET @MaxAssetId = 0;
END
	SET @ProcessedRecords = @ProcessedRecords + @TotalRecordsCount
SELECT  @ProcessedRecords [ProcessedRecords] ,@FailedRecords [FailedRecords]

UPDATE stgModuleIterationStatus SET UpdatedById = @UserId , UpdatedTime = @CreatedTime , EndTime = SYSDATETIMEOFFSET() WHERE Id = @ModuleIterationStatusId
SET NOCOUNT OFF
END

GO

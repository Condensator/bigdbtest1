SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[MigrateAssets]  
(  
       @UserId BIGINT ,  
       @ModuleIterationStatusId BIGINT,  
       @CreatedTime DATETIMEOFFSET = NULL,  
       @ProcessedRecords BIGINT OUTPUT,  
       @FailedRecords BIGINT OUTPUT   
)  
AS  
--DECLARE @UserId BIGINT;  
--DECLARE @FailedRecords BIGINT;  
--DECLARE @ProcessedRecords BIGINT;  
--DECLARE @CreatedTime DATETIMEOFFSET;  
--DECLARE @ModuleIterationStatusId BIGINT;  
--SET @UserId = 1;  
--SET @CreatedTime = SYSDATETIMEOFFSET();   
--SET @ModuleIterationStatusId = 10463;  
--SELECT @ModuleIterationStatusId=IsNull(MAX(ModuleIterationStatusId),0) from stgProcessingLog;  
BEGIN  
SET NOCOUNT ON  
SET XACT_ABORT ON
IF(@CreatedTime IS NULL)  
SET @CreatedTime = SYSDATETIMEOFFSET();  
DECLARE @TakeCount BIGINT = 50000
DECLARE @SkipCount BIGINT = 0  
DECLARE @BatchCount INT = 0
DECLARE @TaxSourceTypeNonVertex NVARCHAR(10);
DECLARE @Module VARCHAR(50) = NULL
SET @Module = (SELECT StgModule.Name FROM StgModule INNER JOIN StgModuleIterationStatus ON StgModule.Id = StgModuleIterationStatus.ModuleId WHERE StgModuleIterationStatus.Id = @ModuleIterationStatusId)
EXEC ResetStagingTempFields @Module,NULL

DECLARE @IsSKUEnabled BIT= ISNULL(
(
    SELECT TOP 1(CASE
                     WHEN UPPER(Value) = 'TRUE'
                     THEN 1
                     ELSE 0
                 END)
    FROM GlobalParameters
    WHERE Category = 'Lease'
          AND Name = 'SKUEnabled'
), 0);
  
SET @TaxSourceTypeNonVertex = 'NonVertex';
SET @FailedRecords = 0  
SET @ProcessedRecords = 0  
              CREATE TABLE #ErrorLogs (  
                                        Id BIGINT not null IDENTITY PRIMARY KEY,  
                                        StagingRootEntityId BIGINT,  
                                        Result NVARCHAR(10),  
                                        Message NVARCHAR(MAX)
										)
             CREATE TABLE #FailedProcessingLogs (  
                                                [Action] NVARCHAR(10) NOT NULL,  
                                                [Id] bigint NOT NULL,  
                                                [AssetId] bigint NOT NULL
												)
       DECLARE @TotalRecordsCount BIGINT ;
	   SELECT @TotalRecordsCount=COUNT(Id) FROM stgAsset IntermediateAsset  
                                                                     WHERE IsMigrated = 0 
	   DECLARE @AssetCountExceptChildAsset INT
	   UPDATE stgAsset SET R_IsProcessed = 0 WHERE IsMigrated = 0

       SET @SkipCount = 0  
       WHILE @SkipCount < @TotalRecordsCount  
       BEGIN
	   SELECT @AssetCountExceptChildAsset=COUNT(Id) FROM stgAsset WHERE ParentAssetAlias IS NULL AND R_IsProcessed = 0 AND IsMigrated = 0
		
	   BEGIN TRY  
       BEGIN TRANSACTION	
              CREATE TABLE #CreatedAssetIds (  
                                                [Action] NVARCHAR(10) NOT NULL,  
                                                [Id] bigint NOT NULL,  
                                                [Alias] NVARCHAR(200) NOT NULL,  
                                                [AssetId] bigint NOT NULL,
												[IsLeaseComponent] BIT NOT NULL)												
			  CREATE TABLE #CreatedAssetSerialNumbers (  
                                                [Id] bigint NOT NULL,  
                                                [SerialNumber] NVARCHAR(200) NOT NULL,  
                                                [AssetId] bigint NOT NULL)
              CREATE TABLE #CreatedAssetSKUsIds (
                                                [Id] bigint NOT NULL,
                                                [TargetAssetId]  bigint NOT NULL,
                                                [Cost_Amount] Decimal(16,2) NOT NULL,
												[Cost_Currency] NVARCHAR(3) NOT NULL,
												[IsLeaseComponent] BIT NOT NULL)	
												
			  CREATE TABLE #CreatedAssetValueHistoryIds (
                                                [Id] bigint NOT NULL,
                                                [TargetAssetId]  bigint NOT NULL,
												[IsLeaseComponent] BIT NOT NULL)

			 CREATE TABLE #CreatedAssetFeatureIds (
												[Id] bigint NOT NULL)
  
              CREATE TABLE #InsertedTaxExemptRuleIds (  
                                                [Id] BIGINT,  
                                                [AssetId] BIGINT)  
              CREATE TABLE #CreatedProcessingLogs (  
                                                [Action] NVARCHAR(10) NOT NULL,  
                                                [Id] bigint NOT NULL)   
												
			  CREATE TABLE #CreatedAssetHistories(  
                                                [Id] bigint NOT NULL,  
                                                [AssetId] bigint NOT NULL)

			  CREATE TABLE #AllSerialNumbersWithinAsset (
												[SerialNumber] NVARCHAR(200) NOT NULL,
												[AssetId] bigint NOT NULL)

              CREATE TABLE #AssetCatalogValues  
              (  
                     AssetId BigInt,  
                     Description2 NVarChar(40) NULL,  
                     Class1 NVarChar(6)  NULL,  
                     Class3 NVarChar(200)  NULL,  
                     ExemptProperty NVarChar (4) NULL,  
                     AssetClass2Id BigInt  
              )  
              CREATE TABLE #AssetTypeAccountingComplianceDetails  
              (  
				  AssetTypeId BigInt,  
				  IsLeaseComponent BIT,  
				  AccountingStandard NVARCHAR(40)  
              )  
			CREATE TABLE #GLAccountNumbers 
			(  
				[Id] BIGINT NOT NULL IDENTITY PRIMARY KEY,
				[InstrumentTypeId] bigint,
				[GLTemplateDetailId] bigint,
				[LegalEntityId] bigint,
				[LineofBusinessId] bigint,
				[CostCenterId] bigint,
				[CurrencyId] bigint,
				[GLAccountId] bigint,
				[IsDebit] BIT NOT NULL,
				[IsProcessed] BIT NOT NULL,
				[GLAccountNumber] NVARCHAR(100) 
			)  
              SELECT      
                     TOP(@TakeCount) *, 0 AS IsSKU INTO #AssetSubset   
              FROM   
                     stgAsset IntermediateAsset  
              WHERE  
                     IsMigrated = 0 AND  
					 R_IsProcessed = 0 AND  
					 ISNULL(IntermediateAsset.ParentAssetAlias,'')= CASE WHEN @AssetCountExceptChildAsset > 0 THEN '' ELSE IntermediateAsset.ParentAssetAlias END

			  UPDATE stgAsset SET R_IsProcessed=1
			  FROM stgAsset INNER JOIN #AssetSubset 
			  ON stgAsset.Id = #AssetSubset.Id

			  SELECT @BatchCount = ISNULL(COUNT(Id),0) FROM #AssetSubset;

			  INSERT INTO #AssetTypeAccountingComplianceDetails (AssetTypeId, IsLeaseComponent, AccountingStandard)
              SELECT AssetTypeId,IsLeaseComponent, AccountingStandard FROM AssetTypeAccountingComplianceDetails WHERE Id IN (
              SELECT Max(Id) FROM AssetTypeAccountingComplianceDetails GROUP BY AccountingStandard,AssetTypeId)
  
              SELECT AFSD.* ,A.Id AS AssetId   
              INTO #AssetFeatureSetSubset  
              FROM stgAsset A  
              INNER JOIN AssetFeatureSets AFS ON A.AssetFeatureSetName = AFS.Name  
              INNER JOIN AssetFeatureSetDetails AFSD ON AFS.Id = AFSD.AssetFeatureSetId AND AFSD.IsActive = 1  
              WHERE A.AssetFeatureSetName IS NOT NULL AND A.IsMigrated=0  
              SELECT AF.*   
              INTO #AssetFeatureSubset  
              FROM #AssetSubset  
              INNER JOIN stgAssetFeature AF ON #AssetSubset.Id = AF.AssetId 
			  SELECT ASN.*   
              INTO #AssetSerialNumberSubset  
              FROM #AssetSubset  
              INNER JOIN stgAssetSerialNumber ASN ON #AssetSubset.Id = ASN.AssetId 
			  WHERE ASN.SerialNumber IS NOT NULL
			  SELECT AFSN.*   
              INTO #AssetFeatureSerialNumberSubset  
              FROM #AssetFeatureSubset  
              INNER JOIN stgAssetFeatureSerialNumber AFSN ON #AssetFeatureSubset.Id = AFSN.AssetFeatureId
			  WHERE AFSN.SerialNumber IS NOT NULL
              SELECT AVD.*   
              INTO #AssetVehicleSubset  
              FROM #AssetSubset  
              INNER JOIN stgAssetVehicleDetail AVD ON #AssetSubset.Id = AVD.Id  
              SELECT AL.*   
              INTO #AssetLocationSubset  
              FROM #AssetSubset  
              INNER JOIN stgAssetLocation AL ON #AssetSubset.Id = AL.AssetId  
			  SELECT ARL.*   
              INTO #AssetRepossessionLocationSubset  
              FROM #AssetSubset  
              INNER JOIN stgAssetRepossessionLocation ARL ON #AssetSubset.Id = ARL.AssetId  
              SELECT AM.*   
              INTO #AssetMeterSubset  
              FROM #AssetSubset  
              INNER JOIN stgAssetMeter AM ON #AssetSubset.Id = AM.AssetId  

			  SELECT [AS].* , 0 AS IsLeaseComponent
              INTO #AssetSKUSubset
              FROM #AssetSubset
              INNER JOIN stgAssetSKU [AS] ON #AssetSubset.Id = [AS].AssetId

			  UPDATE #AssetSubset SET R_CurrencyId = C.Id  
              FROM #AssetSubset Asset  
              INNER JOIN CurrencyCodes AS CC ON CC.ISO = Asset.CurrencyCode
			  INNER JOIN Currencies AS C ON CC.Id = C.CurrencyCodeId
			  WHERE C.IsActive = 1 AND CC.IsActive = 1
              UPDATE #AssetSubset SET R_CostCenterId = CostCenterConfigs.Id  
              FROM #AssetSubset Asset  
              INNER JOIN CostCenterConfigs ON CostCenterConfigs.CostCenter = Asset.CostCenter               
			  WHERE CostCenterConfigs.IsActive = 1
			  UPDATE #AssetSubset SET R_LegalEntityId = LegalEntities.Id  
              FROM #AssetSubset Asset  
              INNER JOIN LegalEntities ON LegalEntities.LegalEntityNumber = Asset.LegalEntityNumber  
              WHERE  
              LegalEntities.Status = 'Active'  
              UPDATE #AssetSubset SET R_AssetTypeId = AssetType.Id  
              FROM #AssetSubset Asset  
              INNER JOIN AssetTypes AssetType ON AssetType.Name = Asset.AssetType  
              WHERE  
              AssetType.IsActive = 1  

			  UPDATE #AssetSubset SET R_PricingGroupId = PricingGroups.Id
              FROM #AssetSubset Asset    
			  INNER JOIN PricingGroups  ON Asset.PricingGroup = PricingGroups.Name
			  WHERE PricingGroups.IsActive = 1  

              UPDATE #AssetSubset SET R_ProductId = Product.Id  
              FROM #AssetSubset Asset  
              INNER JOIN Products Product ON Product.Name = Asset.AssetProduct  
              WHERE  
              Product.IsActive = 1 AND Asset.AssetProduct IS NOT NULL AND R_ProductId IS NULL  
              UPDATE #AssetSubset SET R_CustomerId = Party.Id  
              FROM #AssetSubset Asset  
              INNER JOIN Parties Party ON Party.PartyNumber= Asset.CustomerPartyNumber  
              WHERE   
              Asset.CustomerPartyNumber IS NOT NULL AND R_CustomerId IS NULL  
              UPDATE #AssetSubset SET R_AssetCategoryId = Category.Id  
              FROM #AssetSubset Asset  
              INNER JOIN AssetCategories Category ON Category.Name= Asset.AssetCategory  
              WHERE   
              Asset.AssetCategory IS NOT NULL AND R_AssetCategoryId IS NULL AND Category.IsActive = 1  
              UPDATE #AssetSubset SET R_ManufacturerId = Manufacturer.Id  
              FROM #AssetSubset Asset  
              INNER JOIN Manufacturers Manufacturer ON Manufacturer.Name= Asset.Manufacturer  
              WHERE   
              Asset.Manufacturer IS NOT NULL AND R_ManufacturerId IS NULL AND Manufacturer.IsActive = 1  
              UPDATE #AssetSubset SET R_ParentAssetId = ParentAsset.Id  
              FROM #AssetSubset Asset  
              INNER JOIN Assets ParentAsset ON ParentAsset.Alias= Asset.ParentAssetAlias  
              WHERE   
              Asset.ParentAssetAlias IS NOT NULL AND R_ParentAssetId IS NULL   
              UPDATE #AssetSubset SET R_AssetFeatureId = AssetFeatureSet.Id  
              FROM #AssetSubset Asset  
              INNER JOIN AssetFeatureSets AssetFeatureSet ON AssetFeatureSet.Name= Asset.AssetFeatureSetName  
              WHERE   
              Asset.AssetFeatureSetName IS NOT NULL AND R_AssetFeatureId IS NULL AND AssetFeatureSet.IsActive = 1  
              UPDATE #AssetSubset SET R_AssetUsageId = AssetUsage.Id  
              FROM #AssetSubset Asset  
              INNER JOIN AssetUsages AssetUsage ON AssetUsage.Usage= Asset.AssetUsage  
              WHERE   
              Asset.AssetUsage IS NOT NULL AND R_AssetUsageId IS NULL AND AssetUsage.IsActive = 1  
              UPDATE #AssetSubset SET R_TitleTransferCodeId = TTC.Id  
              FROM #AssetSubset Asset  
              INNER JOIN TitleTransferCodes TTC ON TTC.TransferCode= Asset.TitleTransferCode  
              WHERE   
              Asset.TitleTransferCode IS NOT NULL AND R_TitleTransferCodeId IS NULL AND TTC.IsActive = 1  
              UPDATE #AssetSubset SET R_StateId = States.Id  
              FROM #AssetSubset Asset  
              INNER JOIN States ON States.ShortName = Asset.StateShortName  
              WHERE   
              Asset.StateShortName IS NOT NULL AND R_StateId IS NULL AND States.IsActive = 1  
              UPDATE #AssetSubset SET R_SaleLeasebackCodeId = SLCC.Id  
              FROM #AssetSubset Asset  
              INNER JOIN SaleLeasebackCodeConfigs SLCC ON SLCC.Code = Asset.SaleLeasebackCode  
              WHERE   
              Asset.SaleLeasebackCode IS NOT NULL AND R_SaleLeasebackCodeId IS NULL AND SLCC.IsActive = 1 AND Asset.IsSaleLeaseback = 1  
              UPDATE #AssetSubset SET R_VendorAssetCategoryId = VACC.Id  
              FROM #AssetSubset Asset  
              INNER JOIN VendorAssetCategoryConfigs VACC ON VACC.Name = Asset.VendorAssetCategoryName  
              WHERE   
              Asset.VendorAssetCategoryName IS NOT NULL AND R_VendorAssetCategoryId IS NULL AND VACC.IsActive = 1  
              UPDATE #AssetSubset SET R_SalesTaxExemptionLevelId = STELC.Id  
              FROM #AssetSubset Asset  
              INNER JOIN SalesTaxExemptionLevelConfigs STELC ON STELC.Name = Asset.SalesTaxExemptionLevelName  
              WHERE   
              Asset.SalesTaxExemptionLevelName IS NOT NULL AND R_SalesTaxExemptionLevelId IS NULL  
              UPDATE #AssetSubset SET R_AssetCatalogId = AC.Id  
              FROM #AssetSubset Asset  
              INNER JOIN AssetCatalogs AC ON AC.CollateralCode = Asset.AssetCatalog  
              WHERE   
              Asset.AssetCatalog IS NOT NULL AND R_AssetCatalogId IS NULL AND IsActive = 1  
              UPDATE #AssetSubset SET R_AssetBookValueAdjustmentGLTemplateId = GL.Id  
              FROM #AssetSubset Asset  
              INNER JOIN GLTemplates GL ON GL.Name = Asset.AssetBookValueAdjustmentGLTemplateName  
              WHERE   
              Asset.AssetBookValueAdjustmentGLTemplateName IS NOT NULL AND R_AssetBookValueAdjustmentGLTemplateId IS NULL  
              UPDATE #AssetSubset SET R_BookDepreciationGLTemplateId = GL.Id  
              FROM #AssetSubset Asset  
              INNER JOIN GLTemplates GL ON GL.Name = Asset.BookDepreciationGLTemplateName  
              WHERE   
              Asset.BookDepreciationGLTemplateName IS NOT NULL AND R_BookDepreciationGLTemplateId IS NULL  
              UPDATE #AssetSubset SET R_InstrumentTypeId = IT.Id  
              FROM #AssetSubset Asset  
              INNER JOIN InstrumentTypes IT ON IT.Code = Asset.InstrumentTypeName  
              WHERE   
              Asset.InstrumentTypeName IS NOT NULL AND R_InstrumentTypeId IS NULL AND IT.IsActive = 1  
              UPDATE #AssetSubset SET R_LineofBusinessId = LOB.Id  
              FROM #AssetSubset Asset  
              INNER JOIN LineofBusinesses LOB ON LOB.Name = Asset.LineofBusinessName  
              WHERE   
              Asset.LineofBusinessName IS NOT NULL AND R_LineofBusinessId IS NULL AND LOB.IsActive = 1  
              UPDATE #AssetSubset SET R_MakeId = Makes.Id  
              FROM #AssetSubset Asset  
              INNER JOIN Makes ON Asset.Make = Makes.Name  
              WHERE   
              Asset.Make IS NOT NULL AND R_MakeId IS NULL AND Makes.IsActive = 1  
              UPDATE #AssetSubset SET R_ModelId = Models.Id  
              FROM #AssetSubset Asset  
              INNER JOIN Models ON Asset.Model = Models.Name  
              WHERE   
              Asset.Model IS NOT NULL AND R_ModelId IS NULL AND Models.IsActive = 1  
              UPDATE #AssetSubset SET R_InventoryRemarketerId = Parties.Id  
              FROM #AssetSubset Asset  
              INNER JOIN Parties ON Parties.PartyName = Asset.InventoryRemarketer  
              WHERE   
              Asset.InventoryRemarketer IS NOT NULL AND R_InventoryRemarketerId IS NULL AND CurrentRole = 'Customer'  
              UPDATE #AssetSubset SET R_MaintenanceVendorId = Parties.Id  
              FROM #AssetSubset Asset  
              INNER JOIN Parties ON Parties.PartyNumber = Asset.MaintenanceVendorNumber  
              WHERE   
              Asset.MaintenanceVendorNumber IS NOT NULL AND R_MaintenanceVendorId IS NULL AND CurrentRole = 'Vendor'  
              UPDATE #AssetSubset SET R_PropertyTaxReportId = PropertyTaxReportCodeConfigs.Id  
              FROM #AssetSubset Asset  
              INNER JOIN PropertyTaxReportCodeConfigs ON PropertyTaxReportCodeConfigs.Code = Asset.PropertyTaxReportCode  
              WHERE   
              Asset.PropertyTaxReportCode IS NOT NULL AND R_PropertyTaxReportId IS NULL AND IsActive = 1  
              UPDATE #AssetSubset SET R_StateTaxExemptionReasonId = TERC.Id  
              FROM #AssetSubset Asset  
              INNER JOIN TaxExemptionReasonConfigs TERC ON TERC.Reason= Asset.StateTaxExemptionReason AND TERC.EntityType = 'Asset'  
              WHERE   
              Asset.StateTaxExemptionReason IS NOT NULL AND R_StateTaxExemptionReasonId IS NULL AND IsActive = 1  
              UPDATE #AssetSubset SET R_CountryTaxExemptionReasonId = TERC.Id  
              FROM #AssetSubset Asset  
			  INNER JOIN TaxExemptionReasonConfigs TERC ON TERC.Reason= Asset.CountryTaxExemptionReason AND TERC.EntityType = 'Asset'  
              WHERE   
              Asset.CountryTaxExemptionReason IS NOT NULL AND R_CountryTaxExemptionReasonId IS NULL AND IsActive = 1  

			  UPDATE #AssetSubset SET R_ManufacturerId  = Manufacturer.Id, R_MakeId= M.Id, R_ModelId = Model.Id, R_ProductId = P.Id, R_AssetTypeId  = CASE WHEN AssetFeatureType.Id IS NULL THEN AT.Id ELSE AssetFeatureType.Id END, R_AssetCategoryId = Category.Id  
              FROM  #AssetSubset AFS   
              LEFT JOIN AssetCatalogs AC ON AFS.R_AssetCatalogId  = AC.Id  
              LEFT JOIN Makes M ON M.Id = AC.MakeId  
              LEFT JOIN Models Model ON Model.Id = AC.ModelId  
              LEFT JOIN Manufacturers Manufacturer ON Manufacturer.Id = AC.ManufacturerId  
              LEFT JOIN Products P ON  P.Id = AC.ProductId  
              LEFT JOIN AssetTypes AT ON AT.Id = AC.AssetTypeId  
              LEFT JOIN AssetTypes AssetFeatureType ON AssetFeatureType.Id = AFS.R_AssetTypeId  
              LEFT JOIN AssetCategories Category ON Category.Id = AC.AssetCategoryId  
              WHERE AFS.R_AssetCatalogId IS NOT NULL
			        

			  UPDATE #AssetSubset SET IsSKU = 1
              FROM #AssetSubset Asset
			  WHERE Id IN (SELECT DISTINCT AssetId FROM #AssetSKUSubset)
              
			  UPDATE #AssetSubset SET R_VendorId = Vendor.Id
              FROM #AssetSubset Asset
			  JOIN Parties Vendor ON Asset.VendorNumber = Vendor.PartyNumber
			  JOIN LegalEntities Le ON Asset.LegalEntityNumber = Le.LegalEntityNumber 
			  JOIN VendorLegalEntities Vle ON Le.Id = Vle.LegalEntityId AND Vle.VendorId = Vendor.Id
			  WHERE Vendor.CurrentRole='Vendor'

              UPDATE #AssetFeatureSubset SET R_MakeId = Makes.Id  
              FROM #AssetFeatureSubset AF  
              INNER JOIN Makes ON AF.Make = Makes.Name  
              WHERE   
              AF.Make IS NOT NULL AND AF.R_MakeId IS NULL AND Makes.IsActive = 1  
              UPDATE #AssetFeatureSubset SET R_ModelId = Models.Id  
              FROM #AssetFeatureSubset AF  
              INNER JOIN Models ON AF.Model = Models.Name  
              WHERE   
              AF.Model IS NOT NULL AND AF.R_ModelId IS NULL AND Models.IsActive = 1  
              UPDATE #AssetFeatureSubset SET R_AssetCatalogId = AC.Id  
              FROM #AssetFeatureSubset   
              INNER JOIN AssetCatalogs AC ON AC.CollateralCode = #AssetFeatureSubset.AssetCatalog  
              WHERE   
              #AssetFeatureSubset.AssetCatalog IS NOT NULL AND #AssetFeatureSubset.R_AssetCatalogId IS NULL AND IsActive = 1  
              UPDATE #AssetFeatureSubset SET R_StateId = States.Id  
              FROM #AssetFeatureSubset AF  
              INNER JOIN States ON States.ShortName = AF.StateShortName  
              WHERE   
              AF.StateShortName IS NOT NULL AND AF.R_StateId IS NULL AND States.IsActive = 1  
              UPDATE #AssetFeatureSubset SET R_AssetTypeId = AssetTypes.Id  
              FROM #AssetFeatureSubset AF  
              INNER JOIN AssetTypes ON AssetTypes.Name = AF.AssetType  
              WHERE   
              AF.AssetType IS NOT NULL AND AF.R_AssetTypeId IS NULL AND AssetTypes.IsActive = 1  
              UPDATE #AssetFeatureSubset SET R_ProductId = Products.Id  
              FROM #AssetFeatureSubset AF  
              INNER JOIN Products ON Products.Name = AF.AssetProduct  
              WHERE   
              AF.AssetProduct IS NOT NULL AND AF.R_ProductId IS NULL AND Products.IsActive = 1  
              UPDATE #AssetFeatureSubset SET R_AssetCategoryId = AssetCategories.Id  
              FROM #AssetFeatureSubset AF   
              INNER JOIN AssetCategories ON AssetCategories.Name = AF.AssetCategory  
              WHERE   
              AF.AssetCategory IS NOT NULL AND AF.R_AssetCategoryId IS NULL AND AssetCategories.IsActive = 1  
              UPDATE #AssetFeatureSubset SET R_ManufacturerId = Manufacturers.Id  
              FROM #AssetFeatureSubset AF  
              INNER JOIN Manufacturers ON Manufacturers.Name = AF.Manufacturer  
              WHERE   
              AF.Manufacturer IS NOT NULL AND AF.R_ManufacturerId IS NULL AND Manufacturers.IsActive = 1      
              UPDATE #AssetFeatureSubset SET R_CurrencyId = Currencies.Id  
              FROM #AssetFeatureSubset AF  
              INNER JOIN CurrencyCodes ON  AF.Currency = CurrencyCodes.ISO  
              INNER JOIN Currencies ON CurrencyCodes.Id = Currencies.CurrencyCodeId  
              WHERE   
              AF.Currency IS NOT NULL AND AF.R_CurrencyId IS NULL AND Currencies.IsActive = 1     
              UPDATE #AssetVehicleSubset SET R_AssetClassConfigId = AssetClassConfigs.Id  
              FROM #AssetVehicleSubset AV  
              INNER JOIN AssetClassConfigs ON AssetClassConfigs.AssetClassCode = AV.AssetClass  
              WHERE   
              AV.AssetClass IS NOT NULL AND AV.R_AssetClassConfigId IS NULL  
              UPDATE #AssetVehicleSubset SET R_FuelTypeConfigId = FuelTypeConfigs.Id  
              FROM #AssetVehicleSubset AV  
              INNER JOIN FuelTypeConfigs ON FuelTypeConfigs.FuelTypeCode = AV.FuelType  
              WHERE   
              AV.FuelType IS NOT NULL AND AV.R_FuelTypeConfigId IS NULL AND IsActive = 1  
              UPDATE #AssetVehicleSubset SET R_DriveTrainConfigId = DriveTrainConfigs.Id  
              FROM #AssetVehicleSubset AV  
              INNER JOIN DriveTrainConfigs ON DriveTrainConfigs.DriveTrainCode = AV.DriveTrain  
              WHERE   
              AV.DriveTrain IS NOT NULL AND AV.R_DriveTrainConfigId IS NULL AND IsActive = 1  
              UPDATE #AssetVehicleSubset SET R_BodyTypeConfigId = BodyTypeConfigs.Id  
              FROM #AssetVehicleSubset AV  
              INNER JOIN BodyTypeConfigs ON BodyTypeConfigs.BodyTypeCode = AV.BodyType  
              WHERE   
              AV.BodyType IS NOT NULL AND AV.R_BodyTypeConfigId IS NULL AND IsActive = 1  
              UPDATE #AssetVehicleSubset SET R_StateId = States.Id  
              FROM #AssetVehicleSubset AV  
              INNER JOIN States ON States.ShortName = AV.TitleState  
              WHERE   
              AV.TitleState IS NOT NULL AND AV.R_StateId IS NULL AND IsActive = 1  
              UPDATE #AssetVehicleSubset SET R_TitleCodeConfigId = TitleCodeConfigs.Id  
              FROM #AssetVehicleSubset AV  
              INNER JOIN TitleCodeConfigs ON TitleCodeConfigs.TitleCode = AV.TitleCode  
              WHERE   
              AV.TitleCode IS NOT NULL AND AV.R_TitleCodeConfigId IS NULL AND IsActive = 1  

			  UPDATE #AssetVehicleSubset SET R_ColourId = ColourConfigs.Id  
              FROM #AssetVehicleSubset AV  
              INNER JOIN ColourConfigs ON ColourConfigs.Colour = AV.Colour  
              WHERE   
              AV.Colour IS NOT NULL AND AV.R_ColourId IS NULL AND ColourConfigs.IsActive = 1  

			  UPDATE #AssetVehicleSubset SET R_ColourTypeId = ColourTypeConfigs.Id  
              FROM #AssetVehicleSubset AV  
              INNER JOIN ColourTypeConfigs ON ColourTypeConfigs.ColourType = AV.ColourType  
              WHERE   
              AV.ColourType IS NOT NULL AND AV.R_ColourTypeId IS NULL AND ColourTypeConfigs.IsActive = 1  

			  UPDATE #AssetVehicleSubset SET R_SuspensionId = SuspensionConfigs.Id  
              FROM #AssetVehicleSubset AV  
              INNER JOIN SuspensionConfigs ON SuspensionConfigs.Suspension = AV.Suspension  
              WHERE   
              AV.Suspension IS NOT NULL AND AV.R_SuspensionId IS NULL AND SuspensionConfigs.IsActive = 1  

			  UPDATE #AssetVehicleSubset SET R_FrontTyreSizeId = TireSizeConfigs.Id  
              FROM #AssetVehicleSubset AV  
              INNER JOIN TireSizeConfigs ON TireSizeConfigs.TireSize = AV.FrontTyreSize  
              WHERE   
              AV.FrontTyreSize IS NOT NULL AND AV.R_FrontTyreSizeId IS NULL AND TireSizeConfigs.IsActive = 1  

			  UPDATE #AssetVehicleSubset SET R_RearTyreSizeId = TireSizeConfigs.Id  
              FROM #AssetVehicleSubset AV  
              INNER JOIN TireSizeConfigs ON TireSizeConfigs.TireSize = AV.RearTyreSize  
              WHERE 
			  AV.RearTyreSize IS NOT NULL AND AV.R_RearTyreSizeId IS NULL AND TireSizeConfigs.IsActive = 1  

			  UPDATE #AssetVehicleSubset SET R_WheelId = WheelConfigs.Id  
              FROM #AssetVehicleSubset AV  
              INNER JOIN WheelConfigs ON WheelConfigs.Wheel = AV.Wheel  
              WHERE 
			  AV.Wheel IS NOT NULL AND AV.R_WheelId IS NULL AND WheelConfigs.IsActive = 1 

              UPDATE #AssetLocationSubset SET R_LocationId = Locations.Id  
              FROM #AssetLocationSubset AL  
              INNER JOIN Locations ON Locations.Code = AL.LocationCode 
			  INNER JOIN #AssetSubset Asset ON AL.AssetId=Asset.Id
              WHERE   
              AL.LocationCode IS NOT NULL AND AL.R_LocationId IS NULL AND IsActive = 1  AND (Asset.R_CustomerId is null OR  Asset.R_CustomerId=Locations.CustomerId)

			  UPDATE #AssetRepossessionLocationSubset SET R_LocationId = Locations.Id  
              FROM #AssetRepossessionLocationSubset AL  
              INNER JOIN Locations ON Locations.Code = AL.LocationCode 
			  INNER JOIN #AssetSubset Asset ON AL.AssetId=Asset.Id
              WHERE   
              AL.LocationCode IS NOT NULL AND AL.R_LocationId IS NULL AND IsActive = 1  AND (Asset.R_CustomerId is null OR  Asset.R_CustomerId=Locations.CustomerId)

              UPDATE #AssetMeterSubset SET R_AssetMeterTypeId = AssetMeterTypes.Id  
              FROM #AssetMeterSubset AM  
              INNER JOIN AssetMeterTypes ON AssetMeterTypes.Name = AM.AssetMeterType  
              WHERE   
              AM.AssetMeterType IS NOT NULL AND AM.R_AssetMeterTypeId IS NULL AND IsActive = 1

			  UPDATE #AssetSKUSubset SET R_ManufacturerId = Manufacturers.Id
              FROM #AssetSKUSubset [AS]
              INNER JOIN Manufacturers ON Manufacturers.Name = [AS].Manufacturer
              WHERE 
              [AS].Manufacturer IS NOT NULL AND [AS].R_ManufacturerId IS NULL AND Manufacturers.IsActive = 1    
       
			  UPDATE #AssetSKUSubset SET R_MakeId = Makes.Id
              FROM #AssetSKUSubset [AS]
              INNER JOIN Makes ON [AS].Make = Makes.Name AND [AS].R_ManufacturerId = Makes.ManufacturerId
              WHERE 
              [AS].Make IS NOT NULL AND [AS].R_MakeId IS NULL AND Makes.IsActive = 1

              UPDATE #AssetSKUSubset SET R_ModelId = Models.Id
              FROM #AssetSKUSubset [AS]
              INNER JOIN Models ON [AS].Model = Models.Name AND [AS].R_MakeId = Models.MakeId
              WHERE 
              [AS].Model IS NOT NULL AND [AS].R_ModelId IS NULL AND Models.IsActive = 1
       
              UPDATE #AssetSKUSubset SET R_AssetCatalogId = AC.Id
              FROM #AssetSKUSubset [AS]
              INNER JOIN AssetCatalogs AC ON AC.CollateralCode = [AS].AssetCatalog
              WHERE 
              [AS].AssetCatalog IS NOT NULL AND [AS].R_AssetCatalogId IS NULL AND IsActive = 1

              UPDATE #AssetSKUSubset SET R_AssetTypeId = AssetTypes.Id
              FROM #AssetSKUSubset [AS]
              INNER JOIN AssetTypes ON AssetTypes.Name = [AS].AssetType
              WHERE 
              [AS].AssetType IS NOT NULL AND [AS].R_AssetTypeId IS NULL AND AssetTypes.IsActive = 1

			  UPDATE #AssetSKUSubset SET R_PricingGroupId = PricingGroups.Id 
              FROM #AssetSKUSubset     
			  INNER JOIN PricingGroups  ON #AssetSKUSubset.PricingGroup = PricingGroups.Name
			  WHERE PricingGroups.IsActive = 1  

			  UPDATE #AssetSKUSubset SET R_AssetCategoryId = AssetCategories.Id
              FROM #AssetSKUSubset [AS] 
              INNER JOIN AssetCategories ON AssetCategories.Name = [AS].AssetCategory
              WHERE 
              [AS].AssetCategory IS NOT NULL AND [AS].R_AssetCategoryId IS NULL AND AssetCategories.IsActive = 1

              UPDATE #AssetSKUSubset SET R_ProductId = Products.Id
              FROM #AssetSKUSubset [AS]
              INNER JOIN Products ON Products.Name = [AS].Product AND [AS].R_AssetCategoryId = Products.AssetCategoryId
              WHERE 
              [AS].Product IS NOT NULL AND [AS].R_ProductId IS NULL AND Products.IsActive = 1

			  UPDATE #AssetSKUSubset
				  SET 
				    R_ManufacturerId = AC.ManufacturerId
				  , R_MakeId = AC.MakeId
				  , R_ModelId = AC.ModelId
				  , R_ProductId = AC.ProductId
				  , R_AssetCategoryId = AC.AssetCategoryId
				  , R_AssetTypeId = CASE WHEN AC.AssetTypeId IS NULL THEN [AS].R_AssetTypeId ELSE AC.AssetTypeId END
			  FROM #AssetSKUSubset [AS]
			  INNER JOIN AssetCatalogs AC ON [AS].R_AssetCatalogId = AC.Id
			  WHERE [AS].R_AssetCatalogId IS NOT NULL;
				
			  UPDATE #AssetSKUSubset  SET IsLeaseComponent = ATACD.IsLeaseComponent
			  FROM #AssetSKUSubset [AS]
			  INNER JOIN #AssetSubset A ON [AS].AssetId = A.Id
			  INNER JOIN LegalEntities LE ON A.R_LegalEntityId = LE.Id
			  INNER JOIN #AssetTypeAccountingComplianceDetails ATACD ON LE.AccountingStandard = ATACD.AccountingStandard AND [AS].R_AssetTypeId = ATACD.AssetTypeId
         
              INSERT INTO #AssetCatalogValues   
                     (  
                           AssetId  
                           ,Description2  
                           ,Class1  
                           ,Class3  
                           ,ExemptProperty  
                           ,AssetClass2Id  
                     )  
              SELECT  
                           Asset.Id  
                           ,PST.Name  
                           ,M.Class1  
                           ,AC.Class3  
                           ,AT.ExemptProperty  
                           ,Class.Id  
              FROM #AssetSubset Asset   
              LEFT JOIN AssetCatalogs AC ON Asset.R_AssetCatalogId = AC.Id  
              LEFT JOIN ProductSubTypes PST ON PST.Id = AC.ProductSubTypeId  
              LEFT JOIN Manufacturers M ON AC.ManufacturerId = M.Id  
              LEFT JOIN AssetClass2 Class ON Class.Id = AC.Class2Id  
              LEFT JOIN AssetTypes AT ON AT.Id= Asset.R_AssetTypeId  
              WHERE R_AssetTypeId IS NOT NULL OR R_AssetCatalogId IS NOT NULL  
              UPDATE #AssetFeatureSubset SET R_ManufacturerId  = Manufacturer.Id, R_MakeId= M.Id, R_ModelId = Model.Id, R_ProductId = P.Id, R_AssetTypeId  = CASE WHEN AssetFeatureType.Id IS NULL THEN AT.Id ELSE AssetFeatureType.Id END, R_AssetCategoryId = Category.Id  
              FROM  #AssetFeatureSubset AFS   
              LEFT JOIN AssetCatalogs AC ON AFS.R_AssetCatalogId  = AC.Id  
              LEFT JOIN Makes M ON M.Id = AC.MakeId  
              LEFT JOIN Models Model ON Model.Id = AC.ModelId  
              LEFT JOIN Manufacturers Manufacturer ON Manufacturer.Id = AC.ManufacturerId  
              LEFT JOIN Products P ON  P.Id = AC.ProductId  
              LEFT JOIN AssetTypes AT ON AT.Id = AC.AssetTypeId  
              LEFT JOIN AssetTypes AssetFeatureType ON AssetFeatureType.Id = AFS.R_AssetTypeId  
              LEFT JOIN AssetCategories Category ON Category.Id = AC.AssetCategoryId  
              WHERE AFS.R_AssetCatalogId IS NOT NULL  
           UPDATE #AssetFeatureSubset SET R_CurrencyId = C.Id  
              FROM Currencies C   
              INNER JOIN #AssetFeatureSubset ON C.Name = #AssetFeatureSubset.Currency 

			  INSERT INTO #ErrorLogs  
              SELECT  
                 A.Id  
                ,'Error'  
                ,('Please Enter Vendor Number for the Asset : '+ CAST (A.Id AS nvarchar(max)) ) AS Message  
              FROM   
                     #AssetSubset A  
              WHERE   
                     A.R_VendorId IS NULL   

			 INSERT INTO #ErrorLogs  
              SELECT  
                 A.Id  
                ,'Error'  
                ,('Value (Excl VAT) should be Greater Than Zero for the Asset : '+ CAST (A.Id AS nvarchar(max)) ) AS Message  
              FROM   
                     #AssetSubset A  
              WHERE   
                     A.ValueExclVAT_Amount<0


			  INSERT INTO #ErrorLogs  
              SELECT  
                 A.Id  
                ,'Error'  
                ,('Please Enter Usage Condition for the Asset : '+ CAST (A.Id AS nvarchar(max)) ) AS Message  
              FROM   
                     #AssetSubset A  
              WHERE   
                     A.UsageCondition IS NULL 

			  INSERT INTO #ErrorLogs  
              SELECT  
                 A.Id  
                ,'Error'  
                ,('Please Enter Date Of Production for the Asset : '+ CAST (A.Id AS nvarchar(max)) ) AS Message  
              FROM   
                     #AssetSubset A  
              WHERE   
                     A.DateofProduction IS NULL
			  
			  INSERT INTO #AllSerialNumbersWithinAsset
			  SELECT SerialNumber, AssetId
			  FROM #AssetSerialNumberSubset
			  
			  INSERT INTO #AllSerialNumbersWithinAsset
			  SELECT AFSN.SerialNumber, AF.AssetId
			  FROM #AssetFeatureSubset AF
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
                 A.Id  
                ,'Error'  
                ,('Please Enter Acquired Date for the Asset : '+ CAST (A.Id AS nvarchar(max)) ) AS Message  
              FROM   
                     #AssetSubset A  
              WHERE   
                     A.AcquiredDate IS NULL
			  INSERT INTO #ErrorLogs
			  SELECT
				#AssetSubset.Id
                ,'Error'
                ,('The count of asset serial# must be less than or equal to asset quantity for the Asset :' + CAST (#AssetSubset.Id AS nvarchar(max)) ) AS Message
			  FROM
				#AssetSerialNumberSubset ASN
			  JOIN #AssetSubset on ASN.AssetId = #AssetSubset.Id
			  GROUP BY #AssetSubset.Id, #AssetSubset.Quantity
			  HAVING COUNT(*) > #AssetSubset.Quantity

			   INSERT INTO #ErrorLogs
			  SELECT
				#AssetSubset.Id
                ,'Error'
                ,('The serial# length cannont be greater than 17 for the (Vehicle) Asset :' + CAST (#AssetSubset.Id AS nvarchar(max)) ) AS Message
			  FROM
				#AssetSerialNumberSubset ASN
			  JOIN #AssetSubset on ASN.AssetId = #AssetSubset.Id
			  WHERE
			       ASN.SerialNumber IS NOT NULL AND #AssetSubset.IsVehicle = 1 AND #AssetSubset.Quantity =1 AND LEN(ASN.SerialNumber) >17

			  INSERT INTO #ErrorLogs
			  SELECT
				#AssetFeatureSubset.AssetId
                ,'Error'
                ,('The count of asset feature serial# must be less than or equal to asset feature '+ CAST (#AssetFeatureSubset.Id AS nvarchar(max))  + ' quantity for the Asset :' + CAST (#AssetFeatureSubset.AssetId AS nvarchar(max)) ) AS Message
			  FROM
				#AssetFeatureSerialNumberSubset AFSN
			  JOIN #AssetFeatureSubset on AFSN.AssetFeatureId = #AssetFeatureSubset.Id
			  GROUP BY #AssetFeatureSubset.AssetId, #AssetFeatureSubset.Id, #AssetFeatureSubset.Quantity
			  HAVING COUNT(*) > #AssetFeatureSubset.Quantity

			  INSERT INTO #ErrorLogs
              SELECT  
                 AF.AssetId  
                ,'Error'  
                ,('Currency is Invalid in Asset Feature for the Asset : '+ CAST (AF.AssetId AS nvarchar(max)) ) AS Message  
              FROM   
                     #AssetFeatureSubset AF  
              WHERE   
                     AF.R_CurrencyId IS NULL AND AF.Currency IS NOT NULL  
              INSERT INTO #ErrorLogs  
              SELECT  
                 AF.AssetId  
                ,'Error'  
                ,('State is Invalid in Asset Feature for the Asset Feature Alias: '+ISNULL(AF.Alias,'')) AS Message  
              FROM   
                     #AssetFeatureSubset AF  
              WHERE   
                     AF.R_StateId IS NULL AND AF.StateShortName IS NOT NULL  
          INSERT INTO #ErrorLogs  
              SELECT  
                 AF.AssetId  
                ,'Error'  
                ,('Currency is Invalid in Asset Feature for the Asset Feature Alias: '+ISNULL(AF.Alias,'')) AS Message  
              FROM   
                     #AssetFeatureSubset AF  
              WHERE   
                     AF.R_CurrencyId IS NULL AND AF.Currency IS NOT NULL  
              INSERT INTO #ErrorLogs  
              SELECT  
                 AL.AssetId  
                ,'Error'  
                ,('LocationCode is Invalid for asset: '+A.Alias) AS Message  
              FROM   
                     #AssetLocationSubset AL  
                     INNER JOIN #AssetSubset A ON AL.AssetId = A.Id  
              WHERE   
                     AL.R_LocationId IS NULL AND AL.LocationCode IS NOT NULL  
			  INSERT INTO #ErrorLogs  
              SELECT  
                 AL.AssetId  
                ,'Error'  
                ,('Repossession LocationCode is Invalid for asset: '+A.Alias) AS Message  
              FROM   
                     #AssetRepossessionLocationSubset AL  
                     INNER JOIN #AssetSubset A ON AL.AssetId = A.Id  
              WHERE   
                     AL.R_LocationId IS NULL AND AL.LocationCode IS NOT NULL  
			  INSERT INTO #ErrorLogs  
              SELECT  
                 A.Id  
                ,'Error'  
                ,('AssetVehicleDetail must be provided for asset type Vehicle: '+A.Alias) AS Message  
              FROM #AssetSubset  A
				LEFT JOIN stgAssetVehicleDetail AVD ON A.Id = AVD.Id  
              WHERE   
                     A.IsVehicle=1 AND AVD.Id IS NULL
			  		 
			  INSERT INTO #ErrorLogs  
              SELECT  
                 AL.AssetId  
                ,'Error'  
                ,('The Asset having Alias: '+A.Alias+' is not having location belonging to the <CustomerPartyNumber =>' + A.CustomerPartyNumber +'>') AS Message  
              FROM   
                     #AssetLocationSubset AL  
                     INNER JOIN #AssetSubset A ON AL.AssetId = A.Id  
              WHERE   
                     AL.R_LocationId IS NOT NULL AND A.R_CustomerId IS NOT NULL AND AL.R_LocationId NOT IN (select id from Locations L where L.CustomerId=A.R_CustomerId and L.IsActive=1) 

			   INSERT INTO #ErrorLogs  
              SELECT  
                 AL.AssetId  
                ,'Error'  
                ,('The Asset having Alias: '+A.Alias+' is not having Repossesion location belonging to the <CustomerPartyNumber =>' + A.CustomerPartyNumber +'>') AS Message  
              FROM   
                     #AssetRepossessionLocationSubset AL  
                     INNER JOIN #AssetSubset A ON AL.AssetId = A.Id  
              WHERE   
                     AL.R_LocationId IS NOT NULL AND A.R_CustomerId IS NOT NULL AND AL.R_LocationId NOT IN (select id from Locations L where L.CustomerId=A.R_CustomerId and L.IsActive=1) 


			  		 
			  INSERT INTO #ErrorLogs
		      SELECT
		          AL.AssetId
		         ,'Error'
		         ,('The UpFront Tax Mode: '+AL.UpfrontTaxMode+' ,is Invalid for the Following TaxBasisType: '+AL.TaxBasisType+' ,for the Asset :'+A.Alias) AS Message
		      FROM 
		      	     #AssetLocationSubset AL  
                     INNER JOIN #AssetSubset A ON AL.AssetId = A.Id 
			  WHERE
			       AL.TaxBasisType='ST' and AL.UpfrontTaxMode!='None'

	          INSERT INTO #ErrorLogs
		      SELECT
		          AL.AssetId
		         ,'Error'
		         ,('The UpFront Tax Mode: '+AL.UpfrontTaxMode+' ,is Invalid for the Following TaxBasisType: '+AL.TaxBasisType+' ,for the Asset :'+A.Alias) AS Message
		      FROM 			 
		      	     #AssetLocationSubset AL  
                     INNER JOIN #AssetSubset A ON AL.AssetId = A.Id 
			  WHERE
			         (AL.TaxBasisType='UC' OR AL.TaxBasisType='UR') and (AL.UpfrontTaxMode ='None' OR AL.UpfrontTaxMode='_')

			 INSERT INTO #ErrorLogs
		      SELECT
		          AL.AssetId
		         ,'Error'
		         ,('The Tax Basis Type: '+ISNULL(AL.TaxBasisType,' ')+' ,is Invalid for the Following Asset : '+A.Alias) AS Message
		      FROM 			 
		      	     #AssetLocationSubset AL  
                     INNER JOIN #AssetSubset A ON AL.AssetId = A.Id 
					 INNER JOIN Locations L ON AL.LocationCode = L.Code
					 INNER JOIN States S ON L.StateId = S.Id
					 INNER JOIN Countries C ON S.CountryId = C.Id
			  WHERE
			         C.TaxSourceType = @TaxSourceTypeNonVertex and (AL.TaxBasisType ='None' OR AL.TaxBasisType='_' OR AL.TaxBasisType IS NULL)
					 AND (Select name from GlobalParameters where name = 'IsTaxSourceVertex' AND value = 'False' AND Category = 'SalesTax') IS NOT NULL


              INSERT INTO #ErrorLogs  
              SELECT  
                 AF.AssetId  
                ,'Error'  
                ,('Asset Catalog is Invalid in Asset Feature for the Asset Feature Alias: '+ISNULL(AF.Alias,'')) AS Message  
              FROM   
                     #AssetFeatureSubset AF  
              WHERE   
                     AF.R_AssetCatalogId IS NULL AND AF.AssetCatalog IS NOT NULL  
              INSERT INTO #ErrorLogs  
              SELECT  
                 AF.AssetId  
                ,'Error'  
                ,('Make is Invalid in Asset Feature for the Asset Feature Alias: '+ISNULL(AF.Alias,'')) AS Message  
              FROM   
                     #AssetFeatureSubset AF   
              WHERE   
                     AF.R_MakeId IS NULL AND AF.Make IS NOT NULL AND R_AssetCatalogId IS NULL  
              INSERT INTO #ErrorLogs  
              SELECT  
                 AF.AssetId  
                ,'Error'  
                ,('Model is Invalid in Asset Feature for the Asset Feature Alias: '+ISNULL(AF.Alias,'')) AS Message  
              FROM   
                     #AssetFeatureSubset AF  
              WHERE   
                     AF.R_ModelId IS NULL AND AF.Model IS NOT NULL AND R_AssetCatalogId IS NULL  
              INSERT INTO #ErrorLogs  
              SELECT  
                 AF.AssetId  
                ,'Error'  
                ,('AssetType is Invalid in Asset Feature for the Asset Feature Alias: '+ISNULL(AF.Alias,'')) AS Message  
              FROM   
                     #AssetFeatureSubset AF  
              WHERE   
                     AF.R_AssetTypeId IS NULL AND AF.AssetType IS NOT NULL AND R_AssetCatalogId IS NULL  
              INSERT INTO #ErrorLogs  
              SELECT  
                 AF.AssetId  
                ,'Error'  
                ,('Product is Invalid in Asset Feature for the Asset Feature Alias: '+ISNULL(AF.Alias,'')) AS Message  
              FROM   
                     #AssetFeatureSubset AF  
              WHERE   
                     AF.R_ProductId IS NULL AND AF.AssetProduct IS NOT NULL AND R_AssetCatalogId IS NULL  
              INSERT INTO #ErrorLogs  
              SELECT  
                 AF.AssetId  
                ,'Error'  
                ,('Asset Category is Invalid in Asset Feature for the Asset Feature Alias: '+ISNULL(AF.Alias,'')) AS Message  
              FROM   
                     #AssetFeatureSubset AF  
              WHERE   
                     AF.R_AssetCategoryId IS NULL AND AF.AssetCategory IS NOT NULL AND R_AssetCatalogId IS NULL  
              INSERT INTO #ErrorLogs  
              SELECT  
                 AF.AssetId  
                ,'Error'  
                ,('Manufacturer is Invalid in Asset Feature for the Asset Feature Alias: '+ISNULL(AF.Alias,'')) AS Message  
              FROM   
                     #AssetFeatureSubset AF  
              WHERE   
                     AF.R_ManufacturerId IS NULL AND AF.Manufacturer IS NOT NULL AND R_AssetCatalogId IS NULL 
			  INSERT INTO #ErrorLogs  
              SELECT  
                 #AssetSubset.Id  
                ,'Error'  
                ,('Asset Alias Must be Unique, Alias : ' +  #AssetSubset.Alias +' already exist' ) AS Message  
              FROM   
                     #AssetSubset  
              LEFT JOIN Assets ON #AssetSubset.Alias = Assets.Alias  
              WHERE   
                     Assets.Alias IS NOT NULL  
              INSERT INTO #ErrorLogs  
              SELECT  
                 Id  
                ,'Error'  
                ,('Property Tax Report Code is not present for the asset'+ #AssetSubset.Alias  + ' with filter criteria ' +  #AssetSubset.PropertyTaxReportCode ) AS Message  
              FROM   
                     #AssetSubset  
              WHERE   
                     #AssetSubset.PropertyTaxReportCode IS NOT NULL AND #AssetSubset.R_PropertyTaxReportId IS NULL  
              INSERT INTO #ErrorLogs  
              SELECT  
                 Id  
                ,'Error'  
                ,('No Matching Legal Entity with Legal Entity Number : ' + ISNULL(#AssetSubset.[LegalEntityNumber],'NULL')) AS Message  
              FROM   
                     #AssetSubset  
              WHERE   
                     R_LegalEntityId IS NULL  
              INSERT INTO #ErrorLogs  
              SELECT  
                 Id  
                ,'Error'  
                ,('Matching Asset Type not found for Asset Type :' +ISNULL( #AssetSubset.AssetType,'NULL')) AS Message  
              FROM   
                     #AssetSubset  
              WHERE   
                     R_AssetTypeId IS NULL
					 
			  INSERT INTO #ErrorLogs    
              SELECT    
                 Id    
                ,'Error'    
                ,('Matching Pricing Group not found for Pricing Group :' + #AssetSubset.PricingGroup) AS Message    
              FROM     
                     #AssetSubset    
              WHERE     
                     R_PricingGroupId IS NULL AND PricingGroup IS NOT NULL 	 

              INSERT INTO #ErrorLogs  
              SELECT  
                 Id  
                ,'Error'  
                ,('Matching Asset Product not found for Asset Product :' +ISNULL( #AssetSubset.AssetProduct,'NULL')) AS Message  
              FROM   
                     #AssetSubset  
              WHERE   
                     R_ProductId IS NULL AND AssetProduct IS NOT NULL  
			  INSERT INTO #ErrorLogs  
              SELECT  
                 Id  
                ,'Error'  
                ,('Matching Currency Code not found for Currency Code:' +ISNULL( #AssetSubset.CurrencyCode,'NULL')) AS Message  
              FROM   
                     #AssetSubset  
              WHERE   
                     R_CurrencyId IS NULL AND CurrencyCode IS NOT NULL  
			  INSERT INTO #ErrorLogs  
              SELECT  
                 Id  
                ,'Error'  
                ,('Matching Cost Center not found for Cost Center:' +ISNULL( #AssetSubset.CostCenter,'NULL')) AS Message  
              FROM   
                     #AssetSubset  
              WHERE   
                     R_CostCenterId IS NULL AND (CostCenter IS NOT NULL OR #AssetSubset.Cost_Amount > 0)
              INSERT INTO #ErrorLogs  
              SELECT  
                 Id  
                ,'Error'  
                ,('Matching Asset Category not found for Asset Category :' +ISNULL( #AssetSubset.AssetCategory,'NULL')) AS Message  
              FROM   
                     #AssetSubset  
              WHERE   
                     R_AssetCategoryId IS NULL AND AssetCategory IS NOT NULL  
              INSERT INTO #ErrorLogs  
              SELECT  
                 Id  
                ,'Error'  
                ,('Matching Customer not found for <CustomerPartyNumber =>' + #AssetSubset.CustomerPartyNumber +'>') AS Message  
              FROM   
                     #AssetSubset  
              WHERE   
                     #AssetSubset.CustomerPartyNumber IS NOT NULL AND R_CustomerId IS NULL  
              INSERT INTO #ErrorLogs  
              SELECT  
                 Id  
                ,'Error'  
                ,('Matching MaintenanceVendor not found for <CustomerPartyNumber =>' + ISNULL(#AssetSubset.CustomerPartyNumber,'') +'>') AS Message  
              FROM   
                     #AssetSubset  
              WHERE   
                     #AssetSubset.MaintenanceVendorNumber IS NOT NULL AND R_MaintenanceVendorId IS NULL  
              INSERT INTO #ErrorLogs  
              SELECT  
                 Id  
                ,'Error'  
                ,('Matching Customer not found for <InventoryRemarketer =>' + CAST(#AssetSubset.InventoryRemarketer as nvarchar(max)) +'>') AS Message  
              FROM   
                     #AssetSubset  
              WHERE   
                     #AssetSubset.InventoryRemarketer IS NOT NULL AND #AssetSubset.R_InventoryRemarketerId IS NULL  
              INSERT INTO #ErrorLogs  
              SELECT  
                 Id  
                ,'Error'  
                ,('Customer is required for Deposit Asset') AS Message  
              FROM   
                     #AssetSubset  
              WHERE   
                     #AssetSubset.FinancialType = 'Deposit' AND R_CustomerId IS NULL;  
              INSERT INTO #ErrorLogs  
              SELECT  
                 Id  
                ,'Error'  
                ,('Financial Type must be Real / Deposit / Dummy while creating Asset') AS Message  
              FROM   
                     #AssetSubset  
              WHERE   
                     #AssetSubset.FinancialType NOT IN ( 'Deposit' , 'Real' , 'Dummy');  
              INSERT INTO #ErrorLogs  
              SELECT  
                 Id  
                ,'Error'  
                ,('Collateral Asset must have Financial Type as Real or Dummy') AS Message  
              FROM   
                     #AssetSubset  
              WHERE   
                     #AssetSubset.Status = 'Collateral' AND  #AssetSubset.FinancialType NOT IN ( 'Real' ,'Dummy') ;  
              INSERT INTO #ErrorLogs  
              SELECT  
                 Id  
                ,'Error'  
                ,('Please Enter ManufacturerOverride') AS Message  
              FROM   
                     #AssetSubset  
              WHERE   
                     #AssetSubset.IsManufacturerOverride = 1 AND #AssetSubset.ManufacturerOverride Is NULL  
              INSERT INTO #ErrorLogs  
              SELECT  
                 Id  
                ,'Error'  
                ,('Investor Asset must have Financial Type as Real or Deposit') AS Message  
              FROM   
                     #AssetSubset  
              WHERE   
                     #AssetSubset.Status = 'Investor' AND #AssetSubset.FinancialType NOT IN ('Deposit' ,'Real');  
              INSERT INTO #ErrorLogs  
              SELECT  
                 Id  
                ,'Error'  
                ,('Parent-Child Relationship is not allowed for Assets with Financial Type other than Real') AS Message  
              FROM   
                     #AssetSubset  
              WHERE   
                     #AssetSubset.R_ParentAssetId IS NOT NULL AND #AssetSubset.FinancialType != 'Real';  
              INSERT INTO #ErrorLogs  
              SELECT  
                 Id  
                ,'Error'  
                ,('Status must be Inventory / Investor / Collateral while creating Asset') AS Message  
              FROM   
                     #AssetSubset  
              WHERE   
                     #AssetSubset.Status NOT IN ('Inventory','Investor','Collateral');  
              INSERT INTO #ErrorLogs  
              SELECT  
                 #AssetSubset.Id  
                ,'Error'  
                ,('Please select a different Parent Asset, the current Parent Asset selected is itself a Child Asset') AS Message  
              FROM   
                     #AssetSubset   
                     INNER JOIN Assets ParentAsset ON #AssetSubset.R_ParentAssetId = ParentAsset.Id  
              WHERE   
                     ParentAsset.ParentAssetId IS NOT NULL ;  

			  INSERT INTO #ErrorLogs  
			  SELECT  
					Asset.Id  
   					,'Error'  
   					,('Could not find Asset for the filter ParentAssetAlias '+ Asset.ParentAssetAlias +' ' ) AS Message  
			  FROM   
   					#AssetSubset Asset  
			  WHERE 
					ParentAssetAlias IS NOT NULL AND
   					ParentAssetAlias NOT IN (select Alias from Assets)

              INSERT INTO #ErrorLogs  
              SELECT  
                 #AssetSubset.Id  
                ,'Error'  
                ,('Parent Asset must belong to the selected Legal Entity') AS Message  
              FROM   
                     #AssetSubset   
                     INNER JOIN Assets ParentAsset ON #AssetSubset.R_ParentAssetId = ParentAsset.Id  
              WHERE   
                     ParentAsset.LegalEntityId != #AssetSubset.R_LegalEntityId ;  
              INSERT INTO #ErrorLogs  
              SELECT  
                 #AssetSubset.Id  
                ,'Error'  
                ,('Parent Asset must belong to the selected Customer') AS Message  
              FROM     
                     #AssetSubset   
                     INNER JOIN Assets ParentAsset ON #AssetSubset.R_ParentAssetId = ParentAsset.Id  
              WHERE   
                     ParentAsset.CustomerId != #AssetSubset.R_CustomerId ;  
              INSERT INTO #ErrorLogs  
              SELECT  
                 #AssetSubset.Id  
                ,'Error'  
                ,('Parent Asset Financial Type must be Real') AS Message  
              FROM   
                     #AssetSubset   
                     INNER JOIN Assets ParentAsset ON #AssetSubset.R_ParentAssetId = ParentAsset.Id  
              WHERE   
                     ParentAsset.FinancialType != 'Real' ;  
              INSERT INTO #ErrorLogs  
              SELECT  
                 #AssetSubset.Id  
                ,'Error'  
                ,('Parent Asset Status must be same as current Asset Status') AS Message  
              FROM   
                     #AssetSubset   
                     INNER JOIN Assets ParentAsset ON #AssetSubset.R_ParentAssetId = ParentAsset.Id  
              WHERE   
                     ParentAsset.Status <>  #AssetSubset.Status;  
              INSERT INTO #ErrorLogs  
              SELECT  
                 Id  
                ,'Error'  
                ,('No Matching Manufacturer with Manufacturer Name : ' + #AssetSubset.[Manufacturer] ) AS Message  
              FROM   
                     #AssetSubset  
              WHERE   
                     #AssetSubset.R_ManufacturerId IS NULL AND  #AssetSubset.Manufacturer IS NOT NULL  
              INSERT INTO #ErrorLogs  
              SELECT  
                 Id  
                ,'Error'  
                ,('No Matching Make with Make Name : ' + #AssetSubset.[Make] ) AS Message  
              FROM   
                     #AssetSubset  
              WHERE   
                     #AssetSubset.R_MakeId IS NULL AND  #AssetSubset.Make IS NOT NULL  
              INSERT INTO #ErrorLogs  
              SELECT  
                 Id  
                ,'Error'  
                ,('No Matching Asset Feature with Asset Feature Name : ' + #AssetSubset.[AssetFeatureSetName]) AS Message  
              FROM   
                     #AssetSubset  
              WHERE   
                     #AssetSubset.R_AssetFeatureId IS NULL AND  #AssetSubset.AssetFeatureSetName IS NOT NULL  
              INSERT INTO #ErrorLogs  
              SELECT  
                 Id  
                ,'Error'  
                ,('No Matching Asset Usage with Asset Usage Name : ' + #AssetSubset.[AssetUsage] ) AS Message  
              FROM   
                     #AssetSubset  
              WHERE   
                     #AssetSubset.R_AssetUsageId IS NULL AND  #AssetSubset.AssetUsage IS NOT NULL  
              INSERT INTO #ErrorLogs  
              SELECT  
                 Id  
                ,'Error'  
                ,('No Matching Title Transfer Code with Title Transfer Code Name : ' + #AssetSubset.[TitleTransferCode]) AS Message  
              FROM   
                     #AssetSubset  
              WHERE   
                     #AssetSubset.R_TitleTransferCodeId IS NULL AND  #AssetSubset.TitleTransferCode IS NOT NULL  
              INSERT INTO #ErrorLogs  
              SELECT  
                 Id  
                ,'Error'  
                ,('No Matching Sale Leaseback Code with Sale Leaseback Code Name : ' + #AssetSubset.[SaleLeasebackCode]) AS Message  
              FROM   
                     #AssetSubset  
              WHERE   
                     #AssetSubset.R_SaleLeasebackCodeId IS NULL AND  #AssetSubset.SaleLeasebackCode IS NOT NULL  
              INSERT INTO #ErrorLogs  
              SELECT  
                 Id  
                ,'Error'  
                ,('No Matching Vendor Asset Category with Vendor Asset Category Name : ' + #AssetSubset.[VendorAssetCategoryName]) AS Message  
              FROM   
                     #AssetSubset  
              WHERE   
                     #AssetSubset.R_VendorAssetCategoryId IS NULL AND  #AssetSubset.VendorAssetCategoryName IS NOT NULL  
              INSERT INTO #ErrorLogs  
              SELECT  
                 Id  
                ,'Error'  
                ,('No Matching Sales Tax Exemption Level with Sales Tax Exemption Level Name : ' + #AssetSubset.[SalesTaxExemptionLevelName]) AS Message  
              FROM   
                     #AssetSubset  
              WHERE   
                     #AssetSubset.R_SalesTaxExemptionLevelId IS NULL AND  #AssetSubset.SalesTaxExemptionLevelName IS NOT NULL  
              INSERT INTO #ErrorLogs  
              SELECT  
                 Id  
                ,'Error'  
                ,
				CASE WHEN #AssetSubset.AssetBookValueAdjustmentGLTemplateName IS NOT NULL
					 THEN ('No Matching Asset Book Value Adjustment GLTemplate with Asset Book Value Adjustment GLTemplate Name : ' + ISNULL(#AssetSubset.[AssetBookValueAdjustmentGLTemplateName], 'NULL'))
					 ELSE ('AssetBookValueAdjustmentGLTemplateName must have a value as cost of Asset is not 0, Alias : ' +  #AssetSubset.Alias) END AS Message  
              FROM   
                     #AssetSubset  
              WHERE   
                     #AssetSubset.R_AssetBookValueAdjustmentGLTemplateId IS NULL AND (#AssetSubset.AssetBookValueAdjustmentGLTemplateName IS NOT NULL OR #AssetSubset.Cost_Amount <> 0)
              INSERT INTO #ErrorLogs  
              SELECT  
                 Id  
                ,'Error'  
                ,('No Matching Book Depreciation GLTemplate with Book Depreciation GLTemplate Name : ' + #AssetSubset.[BookDepreciationGLTemplateName]) AS Message  
              FROM   
                     #AssetSubset  
              WHERE   
                     #AssetSubset.R_BookDepreciationGLTemplateId IS NULL AND  #AssetSubset.BookDepreciationGLTemplateName IS NOT NULL  
              INSERT INTO #ErrorLogs  
              SELECT  
                 Id  
                ,'Error'  
                ,('No Matching Instrument Type with Instrument Type Name : ' + ISNULL(#AssetSubset.[InstrumentTypeName], 'NULL')) AS Message  
              FROM   
                     #AssetSubset  
              WHERE   
                     #AssetSubset.R_InstrumentTypeId IS NULL AND (#AssetSubset.InstrumentTypeName IS NOT NULL OR #AssetSubset.Cost_Amount > 0)
              INSERT INTO #ErrorLogs  
              SELECT  
                 Id  
                ,'Error'  
                ,('No Matching Line of Business with Line of Business Name : ' + ISNULL(#AssetSubset.[LineofBusinessName], 'NULL')) AS Message  
              FROM   
                     #AssetSubset  
              WHERE   
                     #AssetSubset.R_LineofBusinessId IS NULL AND (#AssetSubset.LineofBusinessName IS NOT NULL OR #AssetSubset.Cost_Amount > 0)
              INSERT INTO #ErrorLogs  
              SELECT  
                 Id  
                ,'Error'  
                ,('No Matching Model with Model Name : ' + #AssetSubset.[Model]) AS Message  
              FROM   
                     #AssetSubset  
              WHERE   
                     #AssetSubset.R_ModelId IS NULL AND  #AssetSubset.Model IS NOT NULL  
              INSERT INTO #ErrorLogs  
              SELECT  
                 Id  
                ,'Error'  
                ,('No Matching StateExemptionReason with StateExemptionReason Name : ' + ISNULL(#AssetSubset.[StateTaxExemptionReason],'NULL')) AS Message  
              FROM   
                     #AssetSubset  
              WHERE   
                     #AssetSubset.R_StateTaxExemptionReasonId IS NULL AND IsStateTaxExempt = 1  
              INSERT INTO #ErrorLogs  
              SELECT  
                 Id  
                ,'Error'  
                ,('No Matching CountryExemptionReason with CountryExemptionReason Name : ' + ISNULL(#AssetSubset.[CountryTaxExemptionReason],'NULL')) AS Message  
              FROM   
                     #AssetSubset  
              WHERE   
                     #AssetSubset.R_CountryTaxExemptionReasonId IS NULL AND IsCountryTaxExempt = 1  
              INSERT INTO #ErrorLogs  
              SELECT  
                 Id  
                ,'Error'  
                ,('Quantity must be greater than 0') AS Message  
              FROM   
                     #AssetSubset  
              WHERE   
                     #AssetSubset.Quantity = 0 ;  
              INSERT INTO #ErrorLogs  
              SELECT  
                 Id  
                ,'Error'  
                ,('Only Real Assets are Eligible for Property Tax Management') AS Message  
              FROM   
                     #AssetSubset  
              WHERE   
                     #AssetSubset.FinancialType <> 'Real' AND #AssetSubset.IsEligibleForPropertyTax = 1 ;  
              INSERT INTO #ErrorLogs  
              SELECT  
                 AV.Id  
                ,'Error'  
                ,('Vehicle Type must be Car/Truck/Equipment in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     AV.VehicleType NOT IN ('Car','Truck','Equipment','_')  
                     AND #AssetSubset.IsVehicle=1  
              INSERT INTO #ErrorLogs  
              SELECT  
                     AV.Id  
                     ,'Error'  
                     ,('Transmission Type must be Automatic/Manual in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     AV.TransmissionType NOT IN ('Automatic','Manual','_')  
                     AND #AssetSubset.IsVehicle=1  
              INSERT INTO #ErrorLogs  
              SELECT  
                     AV.Id  
                     ,'Error'  
                     ,('Please Enter Transmission Type  in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     AV.TransmissionType IS NULL 
                     AND #AssetSubset.IsVehicle=1

			  INSERT INTO #ErrorLogs  
              SELECT  
                     AV.Id  
                     ,'Error'  
                     ,('Please Enter Fuel Type  in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     AV.FuelType IS NULL 
                     AND #AssetSubset.IsVehicle=1

			  INSERT INTO #ErrorLogs  
              SELECT  
                     AV.Id  
                     ,'Error'  
                     ,('Please Enter Engine Number  in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     AV.EngineNumber IS NULL 
                     AND #AssetSubset.IsVehicle=1

			  INSERT INTO #ErrorLogs  
              SELECT  
                     AV.Id  
                     ,'Error'  
                     ,('Please Enter Vehicle Number of Doors  in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     AV.VehicleNumberOfDoors IS NULL 
                     AND #AssetSubset.IsVehicle=1

			  INSERT INTO #ErrorLogs  
              SELECT  
                     AV.Id  
                     ,'Error'  
                     ,('Please Enter Vehicle Number of Keys  in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     AV.VehicleNumberOfKeys IS NULL 
                     AND #AssetSubset.IsVehicle=1

			  
			  INSERT INTO #ErrorLogs  
              SELECT  
                     AV.Id  
                     ,'Error'  
                     ,('Please Enter Number of seats  in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     AV.NumberOfSeats IS NULL 
                     AND #AssetSubset.IsVehicle=1

			  INSERT INTO #ErrorLogs  
              SELECT  
                     AV.Id  
                     ,'Error'  
                     ,('Please Enter Colour  in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     AV.R_ColourId IS NULL 
                     AND #AssetSubset.IsVehicle=1

			 INSERT INTO #ErrorLogs  
              SELECT  
                     AV.Id  
                     ,'Error'  
                     ,('Please Enter Suspension  in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     AV.R_SuspensionId IS NULL 
                     AND #AssetSubset.IsVehicle=1

			 INSERT INTO #ErrorLogs  
              SELECT  
                     AV.Id  
                     ,'Error'  
                     ,('Please Enter ColourType  in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     AV.R_ColourTypeId IS NULL 
                     AND #AssetSubset.IsVehicle=1

			  INSERT INTO #ErrorLogs  
              SELECT  
                     AV.Id  
                     ,'Error'  
                     ,('Please Enter GVW(weight)  in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     AV.GVW IS NULL 
                     AND #AssetSubset.IsVehicle=1
              
			  INSERT INTO #ErrorLogs  
              SELECT  
                     AV.Id  
                     ,'Error'  
                     ,('Engine Size should be Greater than zero in Vehicle detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id
					 INNER JOIN AssetTypes on #AssetSubset.R_AssetTypeId = AssetTypes.Id
              WHERE   
                     AssetTypes.Istrailer=1 AND (AV.EngineSize IS NULL OR AV.EngineSize<0 )
                     AND #AssetSubset.IsVehicle=1

			  INSERT INTO #ErrorLogs  
              SELECT  
                     AV.Id  
                     ,'Error'  
                     ,('KW should be Greater than zero in Vehicle detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id
					 INNER JOIN AssetTypes on #AssetSubset.R_AssetTypeId = AssetTypes.Id
              WHERE   
                     AssetTypes.Istrailer=1 AND (AV.KW IS NULL OR AV.KW<0 )
                     AND #AssetSubset.IsVehicle=1

			 INSERT INTO #ErrorLogs  
              SELECT  
                     AV.Id  
                     ,'Error'  
                     ,('Mileage at Beginning should be Greater than zero in Vehicle detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id					 
              WHERE   
                     (AV.BeginningMileage IS NULL OR AV.BeginningMileage<0)
                     AND #AssetSubset.IsVehicle=1

			  INSERT INTO #ErrorLogs  
              SELECT  
                     AV.Id  
                     ,'Error'  
                     ,('Mileage at Termination should be Greater than zero in Vehicle detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id					 
              WHERE   
                     (AV.TerminationMileage IS NULL OR AV.TerminationMileage<0)
                     AND #AssetSubset.IsVehicle=1

			  INSERT INTO #ErrorLogs  
              SELECT  
                     AV.Id  
                     ,'Error'  
                     ,('Excess Mileage should be Greater than zero in Vehicle detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id					 
              WHERE   
                     (AV.ExcessMileage IS NULL OR AV.ExcessMileage<0)
                     AND #AssetSubset.IsVehicle=1

			  INSERT INTO #ErrorLogs  
              SELECT  
                     AV.Id  
                     ,'Error'  
                     ,('Vehicle Contract Mileage should be Greater than zero in Vehicle detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id					 
              WHERE   
                     (AV.VehicleContractMileage IS NULL OR AV.VehicleContractMileage<0)
                     AND #AssetSubset.IsVehicle=1

              INSERT INTO #ErrorLogs  
              SELECT  
                     AV.Id  
                     ,'Error'  
                     ,('Weight Unit must be LBs/Kgs/Tons/MetricTons in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     AV.WeightUnit NOT IN ('LBs','Kgs','Tons','MetricTons','_')  
                     AND #AssetSubset.IsVehicle=1  
              INSERT INTO #ErrorLogs  
              SELECT  
              AV.Id  
              ,'Error'  
              ,('Odometer Reading Unit must be Miles/KMs in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     AV.OdometerReadingUnit NOT IN ('Miles','KMs','_')  
                     AND #AssetSubset.IsVehicle=1  
              INSERT INTO #ErrorLogs  
              SELECT  
              AV.Id  
              ,'Error'  
              ,('Title Borrowed Reason must be ReRegistration/Amendment/TitleCorrection/InitialRegistration in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     AV.TitleBorrowedReason NOT IN ('ReRegistration','Amendment','TitleCorrection','InitialRegistration','_')  
                     AND #AssetSubset.IsVehicle=1  
              INSERT INTO #ErrorLogs  
              SELECT  
              AV.Id  
              ,'Error'  
              ,('Title Lien Holder must be Lessor/CollateralAgents in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on av.Id =#AssetSubset.Id  
              WHERE   
                     av.TitleLienHolder NOT IN ('Lessor','CollateralAgents','_')  
                     AND #AssetSubset.IsVehicle=1  
              INSERT INTO #ErrorLogs  
              SELECT  
              AV.Id  
              ,'Error'  
              ,('Asset Class is Invalid in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on av.Id =#AssetSubset.Id  
              WHERE   
                     AV.AssetClass IS NOT NULL AND AV.AssetClass!=''  
                     AND AV.R_AssetClassConfigId is null  
                     AND #AssetSubset.IsVehicle=1  
              INSERT INTO #ErrorLogs  
              SELECT  
              AV.Id  
              ,'Error'  
              ,('Please Enter Asset Class  in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on av.Id =#AssetSubset.Id  
              WHERE   
                     AV.R_AssetClassConfigId is null  
                     AND #AssetSubset.IsVehicle=1 

              INSERT INTO #ErrorLogs  
              SELECT  
              AV.Id  
              ,'Error'  
              ,('Fuel Type is Invalid in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     AV.FuelType IS NOT NULL AND AV.FuelType!=''  
                     AND AV.R_FuelTypeConfigId is null  
                     AND #AssetSubset.IsVehicle=1  
              INSERT INTO #ErrorLogs  
              SELECT  
              AV.Id  
              ,'Error'  
              ,('Drive Train is Invalid in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     AV.DriveTrain IS NOT NULL AND AV.DriveTrain!=''  
                     AND AV.R_DriveTrainConfigId is null  
                     AND #AssetSubset.IsVehicle=1  
              INSERT INTO #ErrorLogs  
              SELECT  
              AV.Id  
              ,'Error'  
              ,('Body Type is Invalid in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     AV.BodyType IS NOT NULL AND AV.BodyType!=''  
                     AND AV.R_BodyTypeConfigId IS NULL  
                     AND #AssetSubset.IsVehicle=1  
              INSERT INTO #ErrorLogs  
              SELECT  
              AV.Id  
              ,'Error'  
              ,('State is Invalid in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     AV.TitleState IS NOT NULL AND AV.TitleState!=''  
                     AND AV.R_StateId IS NULL  
                     AND #AssetSubset.IsVehicle=1  
              INSERT INTO #ErrorLogs  
              SELECT  
              AV.Id  
              ,'Error'  
              ,('Title Code is Invalid in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     AV.TitleCode IS NOT NULL AND AV.TitleCode!=''  
                     and AV.R_TitleCodeConfigId IS NULL  
                     and #AssetSubset.IsVehicle=1  
              INSERT INTO #ErrorLogs  
              SELECT  
              AV.Id  
              ,'Error'  
              ,('Please enter Weight Unit in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     (AV.GrossCurbCombinedWeight>0  or AV.VehicleRegisteredWeight>0  
                     or AV.VehicleCurbWeight>0)  
                     and AV.WeightUnit ='_'  
                     and #AssetSubset.IsVehicle=1  
              INSERT INTO #ErrorLogs  
              SELECT  
              AV.Id  
              ,'Error'  
              ,('Please enter Odometer Reading Unit in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     AV.OriginalOdometerReading>0  
                     and AV.WeightUnit ='_'  
                     and #AssetSubset.IsVehicle=1  
              INSERT INTO #ErrorLogs  
              SELECT  
              AV.Id  
              ,'Error'  
              ,('Title Received Date should be on or after Title Application Submission Date in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     AV.TitleReceivedDate IS NOT NULL AND   
                     (AV.TitleApplicationSubmissionDate IS NULL OR  
                     AV.TitleReceivedDate < AV.TitleApplicationSubmissionDate)  
                     AND #AssetSubset.IsVehicle=1  
              INSERT INTO #ErrorLogs  
              SELECT  
              AV.Id  
              ,'Error'  
              ,('Number of cylinders should be greater than or equal to zero in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     (AV.NumberOfCylinders IS NULL OR AV.NumberOfCylinders<0)  
                     AND #AssetSubset.IsVehicle=1  
              INSERT INTO #ErrorLogs  
              SELECT  
              AV.Id  
              ,'Error'  
              ,('Original odometer reading should be greater than or equal to zero in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     (AV.OriginalOdometerReading IS NULL OR AV.OriginalOdometerReading<0)  
                     AND #AssetSubset.IsVehicle=1  
              INSERT INTO #ErrorLogs  
              SELECT  
              AV.Id  
              ,'Error'  
              ,('Number of doors should be greater than or equal to zero in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     (AV.NumberOfDoors IS NULL OR AV.NumberOfDoors<0)  
                     AND #AssetSubset.IsVehicle=1  
              INSERT INTO #ErrorLogs  
              SELECT  
              AV.Id  
              ,'Error'  
              ,('Number of passengers should be greater than or equal to zero in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     (AV.NumberOfPassengers IS NULL OR AV.NumberOfPassengers<0)  
                     AND #AssetSubset.IsVehicle=1  
              INSERT INTO #ErrorLogs  
              SELECT  
              AV.Id  
              ,'Error'  
              ,('Number of seats should be greater than or equal to zero in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     (AV.NumberOfSeats IS NULL OR AV.NumberOfSeats<0)  
                     AND #AssetSubset.IsVehicle=1  
              INSERT INTO #ErrorLogs  
              SELECT  
              AV.Id  
              ,'Error'  
              ,('MPG should be greater than or equal to zero in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     (AV.MPG IS NULL OR AV.MPG<0)  
                     AND #AssetSubset.IsVehicle=1  
              INSERT INTO #ErrorLogs  
              SELECT  
              AV.Id  
              ,'Error'  
              ,('Number of keys should be greater than or equal to zero in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     (AV.NumberOfKeys IS NULL OR AV.NumberOfKeys<0)  
                     AND #AssetSubset.IsVehicle=1  
              INSERT INTO #ErrorLogs  
              SELECT  
              AV.Id  
              ,'Error'  
              ,('Number of remotes should be greater than or equal to zero in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     (AV.NumberOfRemotes IS NULL OR AV.NumberOfRemotes<0)  
                     AND #AssetSubset.IsVehicle=1  
              INSERT INTO #ErrorLogs  
              SELECT  
              AV.Id  
              ,'Error'  
              ,('Engine key code should be greater than or equal to zero in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     (AV.NumberOfRemotes IS NULL OR AV.NumberOfRemotes<0)  
                     AND #AssetSubset.IsVehicle=1  
              INSERT INTO #ErrorLogs  
              SELECT  
              AV.Id  
              ,'Error'  
              ,('Engine key code should be greater than or equal to zero in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     (AV.EngineKeyCode IS NULL OR AV.EngineKeyCode<0)  
                     AND #AssetSubset.IsVehicle=1  
              INSERT INTO #ErrorLogs  
              SELECT  
              AV.Id  
              ,'Error'  
              ,('CO2 should be greater than or equal to zero in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     (AV.CO2 is NULL OR AV.CO2<0)  
                     AND #AssetSubset.IsVehicle=1  
              INSERT INTO #ErrorLogs  
              SELECT  
              AV.Id  
              ,'Error'  
              ,('GVW should be greater than or equal to zero in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     (AV.GVW is NULL OR AV.GVW<0)  
                     AND #AssetSubset.IsVehicle=1  
              INSERT INTO #ErrorLogs  
              SELECT  
              AV.Id  
              ,'Error'  
              ,('Gross Curb Combined Weight should be greater than or equal to zero in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     (AV.GrossCurbCombinedWeight is NULL OR AV.GrossCurbCombinedWeight<0)  
                     AND #AssetSubset.IsVehicle=1  
              INSERT INTO #ErrorLogs  
           SELECT  
              AV.Id  
              ,'Error'  
              ,('Vehicle Registered Weight should be greater than or equal to zero in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     (AV.VehicleRegisteredWeight is NULL OR AV.VehicleRegisteredWeight<0)  
                     AND #AssetSubset.IsVehicle=1  
			  SELECT  
              AV.Id  
              ,'Error'  
              ,('Please Enter Last Date of Execution of Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     AV.VehicleRegisteredWeight is NULL  AND (AV.IsGPS=1 OR AV.IsGPSTracker=1 OR AV.IsImmobiliser=1)
                     AND #AssetSubset.IsVehicle=1  
              INSERT INTO #ErrorLogs  
              SELECT  
              AV.Id  
              ,'Error'  
              ,('Vehicle Curb Weight should be greater than or equal to zero in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
              WHERE   
                     (AV.VehicleCurbWeight is NULL OR AV.VehicleCurbWeight<0)  
                     AND #AssetSubset.IsVehicle=1  

			  INSERT INTO #ErrorLogs  
              SELECT  
              AV.Id  
              ,'Error'  
              ,('Vehicle Curb Weight should be greater than 0.00 for vehcile detail in the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
					 INNER JOIN AssetTypes on #AssetSubset.R_AssetTypeId = AssetTypes.Id
              WHERE   
                     (AssetTypes.IsPermissibleMassRange=1 AND (AV.VehicleCurbWeight = 0  OR AV.VehicleCurbWeight<0))  
                     AND #AssetSubset.IsVehicle=1  

			  INSERT INTO #ErrorLogs  
              SELECT  
              AV.Id  
              ,'Error'  
              ,('Load Capacity (Kg) should be greater than or equal to zero in Vehicle Detail for the Asset: '+#AssetSubset.Alias) AS Message  
              FROM   
                     #AssetVehicleSubset AV  
                     INNER JOIN #AssetSubset on AV.Id =#AssetSubset.Id  
					  INNER JOIN AssetTypes on #AssetSubset.R_AssetTypeId = AssetTypes.Id
              WHERE   
                     (AssetTypes.FlatFeeParameter='Load Capacity' AND (AV.LoadCapacity = 0  OR AV.LoadCapacity<0))  
                     AND #AssetSubset.IsVehicle=1  

              INSERT INTO #ErrorLogs  
              SELECT DISTINCT
                     AssetId  
                     ,'Error'  
                     ,('Effective From Date must be unique among Asset Locations for the asset:' + #AssetSubset.Alias) AS Message  
              FROM  
                     #AssetLocationSubset AL  
                     INNER JOIN #AssetSubset on AL.AssetId =#AssetSubset.Id   
                           WHERE AssetId in  ( SELECT AssetId FROM ( SELECT AssetId,EffectiveFromDate,count(Id) NoOfAssetLocationsWithSameEffectiveDate FROM #AssetLocationSubset GROUP BY AssetId,EffectiveFromDate having count(Id)>1) As T);

			  INSERT INTO #ErrorLogs  
              SELECT DISTINCT
                     AssetId  
                     ,'Error'  
                     ,('Effective From Date must be unique among Asset Locations for the asset:' + #AssetSubset.Alias) AS Message  
              FROM  
                     #AssetRepossessionLocationSubset AL  
                     INNER JOIN #AssetSubset on AL.AssetId =#AssetSubset.Id   
                           WHERE AssetId in  ( SELECT AssetId FROM ( SELECT AssetId,EffectiveFromDate,count(Id) NoOfAssetLocationsWithSameEffectiveDate FROM #AssetRepossessionLocationSubset GROUP BY AssetId,EffectiveFromDate having count(Id)>1) As T);

              INSERT INTO #ErrorLogs  
              SELECT  
                 AssetId  
                ,'Error'  
                ,('Quantity must be greater than 0 For the Asset Feature : '+ISNULL(AF.Alias,'') ) AS Message  
              FROM   
                     #AssetFeatureSubset AF  
                     INNER JOIN #AssetSubset on AF.AssetId = #AssetSubset.Id  
              WHERE   
                     AF.Quantity = 0  
              INSERT INTO #ErrorLogs  
              SELECT  
                 AssetId  
                ,'Error'  
                ,('No matching Asset Type Found for Asset Feature : '+ISNULL(AF.Alias,'')+' with Asset Type : '+AF.AssetType) AS Message  
              FROM   
                     #AssetFeatureSubset AF  
                     INNER JOIN #AssetSubset on AF.AssetId = #AssetSubset.Id  
              WHERE   
                     AF.R_AssetTypeId IS NULL AND AF.AssetType IS NOT NULL  
              INSERT INTO #ErrorLogs  
              SELECT  
                 AssetId  
                ,'Error'  
                ,('No matching Asset Category Found for Asset Feature : '+ISNULL(AF.Alias,'')+' Asset Category : '+AF.AssetCategory) AS Message  
              FROM   
                     #AssetFeatureSubset AF  
                     INNER JOIN #AssetSubset on AF.AssetId = #AssetSubset.Id  
              WHERE   
                     AF.R_AssetCategoryId IS NULL AND AF.AssetCategory IS NOT NULL  
              INSERT INTO #ErrorLogs  
              SELECT  
                 AssetId  
                ,'Error'  
                ,('No matching Asset Product Found for Asset Feature :'+ISNULL(AF.Alias,'')+' with Asset Product : '+AF.AssetProduct) AS Message  
              FROM   
                     #AssetFeatureSubset AF  
                     INNER JOIN #AssetSubset on AF.AssetId = #AssetSubset.Id  
              WHERE   
                     AF.R_ProductId IS NULL AND AF.AssetProduct IS NOT NULL  
              INSERT INTO #ErrorLogs  
              SELECT  
                 AssetId  
                ,'Error'  
                ,('No Matching Asset Meter Type Found for the Asset Meter Type : ' + AM.AssetMeterType) AS Message  
              FROM   
                     #AssetMeterSubset AM  
                     INNER JOIN #AssetSubset on AM.AssetId = #AssetSubset.Id  
              WHERE   
                     R_AssetMeterTypeId IS NULL  
              INSERT INTO #ErrorLogs  
              SELECT  
                 AssetId  
                ,'Error'  
                ,('Begin Reading must be greater than or equal to 0 in the Asset Meter Type :' + AM.AssetMeterType) AS Message  
              FROM   
                     #AssetMeterSubset AM  
                     INNER JOIN #AssetSubset on AM.AssetId = #AssetSubset.Id  
              WHERE   
                     BeginReading < 0  
              INSERT INTO #ErrorLogs  
              SELECT  
                 AssetId  
                ,'Error'  
                ,('Maximum Reading must be greater than 0 in the Asset Meter Type :' + AM.AssetMeterType) AS Message  
              FROM   
                     #AssetMeterSubset AM  
                     INNER JOIN #AssetSubset on AM.AssetId = #AssetSubset.Id  
              WHERE   
                     MaximumReading <= 0  
              INSERT INTO #ErrorLogs  
              SELECT  
                 AssetId  
                ,'Error'  
                ,('Maximum Reading must be greater than Begin Reading in the Asset Meter Type : ' + AM.AssetMeterType) AS Message  
              FROM   
                     #AssetMeterSubset AM  
                     INNER JOIN #AssetSubset on AM.AssetId = #AssetSubset.Id  
              WHERE   
                     MaximumReading < BeginReading  
  
			  INSERT INTO #ErrorLogs
              SELECT
                 Asset.Id
                ,'Error'
                ,('Asset SKU''s should not be present when global parameter "SKUEnabled" is false') AS Message
              FROM 
                     #AssetSubset Asset 
              WHERE 
                     @IsSKUEnabled = 0 AND Asset.Id IN (SELECT DISTINCT AssetId FROM #AssetSKUSubset)

              INSERT INTO #ErrorLogs
              SELECT
                 [AS].AssetId
                ,'Error'
                ,('Asset Catalog is Invalid in Asset SKU for the Asset SKU Alias: '+ISNULL([AS].Alias,'')) AS Message
              FROM 
                     #AssetSKUSubset [AS]
              WHERE 
                     [AS].R_AssetCatalogId IS NULL AND [AS].AssetCatalog IS NOT NULL
              
              INSERT INTO #ErrorLogs
              SELECT
                 [AS].AssetId
                ,'Error'
                ,('Make is Invalid in Asset SKU for the Asset SKU Alias: '+ISNULL([AS].Alias,'')) AS Message
              FROM 
                     #AssetSKUSubset [AS] 
              WHERE 
                     [AS].R_MakeId IS NULL AND [AS].Make IS NOT NULL AND R_AssetCatalogId IS NULL

              INSERT INTO #ErrorLogs
              SELECT
                 [AS].AssetId
                ,'Error'
                ,('Model is Invalid in Asset SKU for the Asset SKU Alias: '+ISNULL([AS].Alias,'')) AS Message
              FROM 
                     #AssetSKUSubset [AS]
              WHERE 
                     [AS].R_ModelId IS NULL AND [AS].Model IS NOT NULL AND R_AssetCatalogId IS NULL

              INSERT INTO #ErrorLogs
              SELECT
                 [AS].AssetId
                ,'Error'
                ,('AssetType is Invalid in Asset SKU for the Asset SKU Alias: '+ISNULL([AS].Alias,'')) AS Message
              FROM 
                     #AssetSKUSubset [AS]
              WHERE 
                     [AS].R_AssetTypeId IS NULL AND [AS].AssetType IS NOT NULL AND R_AssetCatalogId IS NULL

              INSERT INTO #ErrorLogs
              SELECT
                 [AS].AssetId
                ,'Error'
                ,('Product is Invalid in Asset SKU for the Asset SKU Alias: '+ISNULL([AS].Alias,'')) AS Message
              FROM 
                     #AssetSKUSubset [AS]
              WHERE 
                     [AS].R_ProductId IS NULL AND [AS].Product IS NOT NULL AND R_AssetCatalogId IS NULL

			  INSERT INTO #ErrorLogs  
              SELECT  
                 AssetId  
                ,'Error'  
                ,('Pricing Group is invalid in Asset SKU for the Asset SKU Alias: '+ISNULL(Alias,'')) AS Message  
              FROM   
                     #AssetSKUSubset 
              WHERE   
                     R_PricingGroupId IS NULL AND PricingGroup IS NOT NULL  

              INSERT INTO #ErrorLogs
              SELECT
                 [AS].AssetId
                ,'Error'
                ,('Asset Category is Invalid in Asset SKU for the Asset SKU Alias: '+ISNULL([AS].Alias,'')) AS Message
              FROM 
                     #AssetSKUSubset [AS]
              WHERE 
                     [AS].R_AssetCategoryId IS NULL AND [AS].AssetCategory IS NOT NULL AND R_AssetCatalogId IS NULL

              INSERT INTO #ErrorLogs
              SELECT
                 [AS].AssetId
                ,'Error'
                ,('Manufacturer is Invalid in Asset SKU for the Asset SKU Alias: '+ISNULL([AS].Alias,'')) AS Message
              FROM 
                     #AssetSKUSubset [AS]
              WHERE 
                     [AS].R_ManufacturerId IS NULL AND [AS].Manufacturer IS NOT NULL AND R_AssetCatalogId IS NULL

              INSERT INTO #ErrorLogs
              SELECT
                 [AS].AssetId
                ,'Error'
                ,('Quantity must be greater than 0 for the Asset SKU Alias: '+ISNULL([AS].Alias,'')) AS Message
              FROM 
                     #AssetSKUSubset [AS]
              WHERE 
                     [AS].Quantity <= 0

			  INSERT INTO #ErrorLogs
			  SELECT
				  A.Id
                  ,'Error'
                  ,('Asset Type should be soft for the Asset SKU Alias: '+ISNULL([AS].Alias,'')) AS Message
              FROM 
                    #AssetSubset A
					INNER JOIN AssetTypes [AT] ON A.R_AssetTypeId = [AT].Id
					INNER JOIN #AssetSKUSubset [AS] ON A.Id = [AS].AssetId
					INNER JOIN AssetTypes [SKUAT] ON [SKUAT].Id = [AS].R_AssetTypeId
              WHERE 
					[AT].IsSoft = 1 AND [SKUAT].IsSoft = 0
			  INSERT INTO #ErrorLogs
			 SELECT A.Id
					,'Error'
					,('Asset-StateShortName is required when the collateral tracking(AssetTypes.IsCollateralTracking) is true for Asset type :' + ISNULL(A.AssetType, 'NULL')) AS Message
			 FROM	#AssetSubset A
			 	JOIN AssetTypes AssetType ON AssetType.Id = A.R_AssetTypeID
			 WHERE	LTRIM(RTRIM(ISNULL(A.StateShortName,'')))=''  
					AND AssetType.IsCollateralTracking=1

			  INSERT INTO #ErrorLogs
			  SELECT DISTINCT
					A.Id
					,'Error'
					,('At lease one of the SKU''s should be of hard type for Asset Alias: ' + ISNULL(A.Alias, '')) AS Message
			  FROM 
					#AssetSubset A
					INNER JOIN AssetTypes [AT] ON A.R_AssetTypeId = [AT].Id
					INNER JOIN #AssetSKUSubset [AS] ON A.Id = [AS].AssetId
			  WHERE 
					[AT].IsSoft = 0
					AND A.Id NOT IN
					(
					SELECT [AS].AssetId
					FROM #AssetSKUSubset [AS]
					INNER JOIN AssetTypes [AT] ON [AS].R_AssetTypeId = [AT].Id
					WHERE [AT].IsSoft = 0
					GROUP BY [AS].AssetId
					HAVING COUNT(*) > 0
					);
                
              MERGE INTO TaxExemptRules  
              USING (SELECT #ErrorLogs.StagingRootEntityId,#AssetSubset.* FROM  #AssetSubset LEFT JOIN #ErrorLogs  
                                    ON #AssetSubset.Id = #ErrorLogs.StagingRootEntityId WHERE #AssetSubset.Id IS NOT NULL ) AS AE  
              ON 1=0  
              WHEN NOT MATCHED  AND AE.StagingRootEntityId IS NULL  
              THEN  
              INSERT  
                     ([EntityType]  
                     ,[IsCountryTaxExempt]  
                     ,[IsStateTaxExempt]  
                     ,[CreatedById]  
                     ,[CreatedTime]  
                     ,[TaxExemptionReasonId]  
                     ,[IsCityTaxExempt]  
                     ,[IsCountyTaxExempt]  
                     ,[StateTaxExemptionReasonId]  
                     ,[StateExemptionNumber]  
                     ,[CountryExemptionNumber])  
              VALUES(  
                     'Asset'  
                     ,IsCountryTaxExempt  
                     ,IsStateTaxExempt  
				     ,@UserId  
                     ,@CreatedTime  
                     ,R_CountryTaxExemptionReasonId  
                     ,IsCityTaxExempt  
                     ,IsCountyTaxExempt  
                     ,R_StateTaxExemptionReasonId  
                     ,StateExemptionNumber  
                     ,CountryExemptionNumber  
                     )  
                     OUTPUT inserted.Id,AE.Id INTO #InsertedTaxExemptRuleIds;  
              MERGE Assets AS Asset  
              USING (SELECT  
                           #AssetSubset.* ,#ErrorLogs.StagingRootEntityId,Tax.Id AS TaxId, ACV.Class1 AS UpdatedClass1, ACV.Class3 AS UpdatedClass3, ACV.Description2 AS UpdatedDescription2 , ACV.ExemptProperty AS UpdatedExemptProperty  
                           ,ACV.AssetClass2Id AS UpdatedAssetClass2Id, detail.IsLeaseComponent As IsLeaseComponent  
                           ,AssetTypes.IsElectronicallyDelivered 'ElectronicallyDelivered'  
                        FROM  
                           #AssetSubset   
                        INNER JOIN #AssetCatalogValues ACV ON #AssetSubset.Id =  ACV.AssetId  
                        INNER JOIN #InsertedTaxExemptRuleIds Tax ON #AssetSubset.Id = Tax.AssetId                          
                        INNER JOIN AssetTypes On #AssetSubset.R_AssetTypeId = AssetTypes.Id  
                        INNER JOIN LegalEntities On LegalEntities.Id = #AssetSubset.R_LegalEntityId  
                        INNER JOIN #AssetTypeAccountingComplianceDetails detail ON AssetTypes.Id = detail.AssetTypeId AND   
                        LegalEntities.AccountingStandard = detail.AccountingStandard  
                        LEFT JOIN #ErrorLogs ON #AssetSubset.Id = #ErrorLogs.StagingRootEntityId) AS AssetsToMigrate                 
              ON (Asset.Alias = AssetsToMigrate.[Alias])  
              WHEN MATCHED AND AssetsToMigrate.StagingRootEntityId IS NULL THEN  
                     UPDATE SET Alias = AssetsToMigrate.Alias  
              WHEN NOT MATCHED  AND AssetsToMigrate.StagingRootEntityId IS NULL  
              THEN  
                     INSERT  
                     (  
                        [Alias]  
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
						,[PricingGroupId]    
                        ,[LegalEntityId]  
                        ,[CustomerId]  
                        ,[ParentAssetId]  
                        ,[FeatureSetId]  
                        ,[AssetUsageId]  
                        ,[IsTaxExempt]  
                        ,[TitleTransferCodeId]  
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
                        ,[DealerCost_Amount]  
                        ,[DealerCost_Currency]  
                        ,[DMDPercentage]   
                        ,[AssetCatalogId]   
                        ,[TaxExemptRuleId]  
                        ,IsReversed  
                        ,[MakeId]  
                        ,[ModelId]  
                        ,[IsSerializedAsset]  
                        ,[Residual_Amount]  
                        ,[Residual_Currency]  
                        ,[IsVehicle]  
                        ,[InventoryRemarketerId]  
                        ,ManufacturerOverride  
                        ,Class1  
                        ,Class3  
                        ,CustomerAssetNumber  
                        ,Description2  
                        ,ExemptProperty  
                        ,PreviousSequenceNumber  
                        ,SpecifiedLeasingProperty  
                        ,VendorOrderNumber  
                        ,AssetClass2Id  
                        ,MaintenanceVendorId  
                        ,AssetCategoryId  
                        ,ProductId  
                        ,IsLeaseComponent  
                        ,IsServiceOnly
						,IsSKU  
						,IsTaxParameterChangedForLeasedAsset
						,Salvage_Amount
						,Salvage_Currency
						,ValueExclVAT_Amount
                        ,ValueExclVAT_Currency
                        ,ValueInclVAT_Amount
                        ,ValueInclVAT_Currency
                        ,IsVat
                        ,IsImport
                        ,IsPreLeased
                        ,DateofProduction
                        ,AgeofAsset
                        ,Modification
                        ,TrimLevel
                        ,AcquiredDate
                        ,DeliveredDate
                        ,SalePurchaseAgreementNumber
                        ,SalePurchaseAgreementDate
                        ,CreationStatus
                        ,RoadTaxType
                        ,IsServiced
                        ,IsFixedAsset
						,VendorId
						,IsFromCreditApp
                  )  
                  VALUES  
                  (  
                           AssetsToMigrate.Alias  
                           ,AssetsToMigrate.[AcquisitionDate]  
                           ,NULL  
                           ,AssetsToMigrate.[UsageCondition]  
                           ,AssetsToMigrate.[Description]  
                           ,AssetsToMigrate.[Quantity]  
                           ,AssetsToMigrate.[InServiceDate]  
                           ,AssetsToMigrate.[IsEligibleForPropertyTax]  
                           ,AssetsToMigrate.[Status]  
                           ,AssetsToMigrate.[FinancialType]  
                           ,AssetsToMigrate.[MoveChildAssets]
                           ,'FromUI'  
                           ,AssetsToMigrate.[PropertyTaxCost_Amount]  
                           ,AssetsToMigrate.[PropertyTaxCost_Currency]  
                           ,AssetsToMigrate.[PropertyTaxDate]  
                           ,AssetsToMigrate.ProspectiveContract  
                           ,AssetsToMigrate.IsManufacturerOverride  
                           ,AssetsToMigrate.CurrencyCode  
                           ,@CreatedTime  
                           ,NULL  
                           ,AssetsToMigrate.R_ManufacturerId  
                           ,AssetsToMigrate.[R_AssetTypeId] 
						   ,AssetsToMigrate.[R_PricingGroupId]  
                           ,AssetsToMigrate.R_LegalEntityId  
                           ,AssetsToMigrate.R_CustomerId  
                           ,AssetsToMigrate.R_ParentAssetId  
                           ,AssetsToMigrate.R_AssetFeatureId  
                           ,AssetsToMigrate.R_AssetUsageId  
                           ,AssetsToMigrate.IsTaxExempt  
                           ,AssetsToMigrate.R_TitleTransferCodeId  
                           ,@UserId  
                           ,NULL  
                           ,CASE WHEN AssetsToMigrate.ModelYear < 1000 THEN NULL ELSE AssetsToMigrate.ModelYear END  
                           ,AssetsToMigrate.CustomerPurchaseOrderNumber  
                           ,AssetsToMigrate.OwnershipStatus  
                           ,AssetsToMigrate.R_PropertyTaxReportId  
                           ,'DoNotRemit'  
                           ,AssetsToMigrate.IsSaleLeaseback  
                           ,AssetsToMigrate.PurchaseOrderDate  
                           ,AssetsToMigrate.GrossVehicleWeight  
						   ,AssetsToMigrate.WeightMeasure  
                           ,ISNULL(AssetsToMigrate.ElectronicallyDelivered,0)  
                           ,0       
                           ,0  
                           ,0  
                           ,0  
                           ,0  
                           ,AssetsToMigrate.R_StateId  
                           ,AssetsToMigrate.R_VendorAssetCategoryId  
                           ,AssetsToMigrate.R_SaleLeasebackCodeId  
                           ,AssetsToMigrate.R_SalesTaxExemptionLevelId  
                           ,AssetsToMigrate.SubStatus  
                           ,AssetsToMigrate.DealerCost_Amount  
                           ,AssetsToMigrate.DealerCost_Currency  
                           ,AssetsToMigrate.DMDPercentage  
                           ,AssetsToMigrate.R_AssetCatalogId    
                           ,AssetsToMigrate.TaxId  
                           ,0 --IsReversed  
                           ,AssetsToMigrate.R_MakeId  
                           ,AssetsToMigrate.R_ModelId  
                           ,AssetsToMigrate.IsSerializedAsset  
                           ,0.00 
                           ,AssetsToMigrate.[PropertyTaxCost_Currency]  
                           ,AssetsToMigrate.IsVehicle  
                           ,AssetsToMigrate.R_InventoryRemarketerId  
                           ,AssetsToMigrate.ManufacturerOverride  
                           ,AssetsToMigrate.UpdatedClass1  
                           ,AssetsToMigrate.UpdatedClass3  
                           ,AssetsToMigrate.CustomerAssetNumber  
                           ,AssetsToMigrate.UpdatedDescription2  
                           ,AssetsToMigrate.UpdatedExemptProperty  
                           ,AssetsToMigrate.PreviousSequenceNumber  
                           ,AssetsToMigrate.[SpecifiedLeasingProperty]
                           ,AssetsToMigrate.VendorOrderNumber  
                           ,AssetsToMigrate.UpdatedAssetClass2Id  
                           ,AssetsToMigrate.R_MaintenanceVendorId  
                           ,AssetsToMigrate.R_AssetCategoryId  
                           ,AssetsToMigrate.R_ProductId  
                           ,AssetsToMigrate.IsLeaseComponent  
                           ,AssetsToMigrate.IsServiceOnly
						   ,AssetsToMigrate.IsSKU  
						   ,0
						   ,AssetsToMigrate.Salvage_Amount
						   ,AssetsToMigrate.Salvage_Currency
						   ,AssetsToMigrate.ValueExclVAT_Amount
                           ,AssetsToMigrate.ValueExclVAT_Currency
                           ,AssetsToMigrate.ValueInclVAT_Amount
                           ,AssetsToMigrate.ValueInclVAT_Currency
                           ,AssetsToMigrate.IsVat
                           ,AssetsToMigrate.IsImport
                           ,AssetsToMigrate.IsPreLeased
                           ,AssetsToMigrate.DateofProduction
                           ,AssetsToMigrate.AgeofAsset
                           ,AssetsToMigrate.Modification
                           ,AssetsToMigrate.TrimLevel
                           ,AssetsToMigrate.AcquiredDate
                           ,AssetsToMigrate.DeliveredDate
                           ,AssetsToMigrate.SalePurchaseAgreementNumber
                           ,AssetsToMigrate.SalePurchaseAgreementDate
                           ,AssetsToMigrate.CreationStatus
                           ,AssetsToMigrate.RoadTaxType
                           ,AssetsToMigrate.IsServiced
						   ,AssetsToMigrate.IsFixedAsset
						   ,AssetsToMigrate.R_VendorId
						   ,0
                 )  
       OUTPUT $action, Inserted.Id,AssetsToMigrate.Alias, AssetsToMigrate.Id, AssetsToMigrate.IsLeaseComponent INTO #CreatedAssetIds;  
                
                 INSERT INTO AssetGLDetails  
           (  
                           [Id]  
                        ,[HoldingStatus]  
                        ,[CreatedById]  
                        ,[CreatedTime]  
                        ,[UpdatedById]  
                        ,[UpdatedTime]  
                        ,[AssetBookValueAdjustmentGLTemplateId]  
                        ,[BookDepreciationGLTemplateId]  
                        ,[InstrumentTypeId]  
                        ,[LineofBusinessId]  
                        ,[CostCenterId]  
                 )  
                 SELECT   
                        #CreatedAssetIds.Id  
                       ,'HFI'  
                       ,@UserId  
                       ,@CreatedTime  
                       ,NUll  
                       ,Null  
                       ,#AssetSubset.R_AssetBookValueAdjustmentGLTemplateId  
                       ,#AssetSubset.R_BookDepreciationGLTemplateId  
                       ,#AssetSubset.R_InstrumentTypeId  
                       ,#AssetSubset.R_LineofBusinessId  
                       ,#AssetSubset.R_CostCenterId  
                 FROM   
                        #CreatedAssetIds   
                        INNER JOIN #AssetSubset ON #AssetSubset.Alias = #CreatedAssetIds.Alias;  
              UPDATE stgAsset SET IsMigrated = 1   
                     WHERE Id in ( SELECT AssetId FROM #CreatedAssetIds);  
                 INSERT INTO VehicleDetails  
                 (  
                           Id,  
                           AssetClassConfigId ,  
                           VehicleType ,  
                           TransmissionType,  
                           TankCapacity,  
                           InteriorColor,  
                           NumberOfCylinders,  
                           PayloadCapacity ,  
                           FuelTypeConfigId,  
                           EngineSize,  
                           DriveTrainConfigId,  
                           WeightClass,  
                           CO2 ,  
                           ContractMileage,  
                           BodyDescription ,  
                           OriginalOdometerReading ,  
                           OdometerReadingUnit,  
                           NumberOfDoors ,  
                           BodyTypeConfigId,  
                           NumberOfPassengers,  
                           NumberOfSeats ,  
                           KeylessEntry ,  
                           MPG ,  
                           NumberOfKeys,  
                           DoorKeyCode ,  
                           NumberOfRemotes ,  
                           TireSize ,  
                           EngineKeyCode,  
                           ExteriorColor ,  
                           WeightUnit ,  
                           GVW ,  
                           GrossCurbCombinedWeight,  
                           VehicleRegisteredWeight ,  
                           VehicleCurbWeight,  
                           Titled ,  
                           TitleTrustOverride,  
                           TitleStateId ,  
                           TitleBorrowedReason ,  
                           TitleBorrowedDate,  
                           TitleLienHolder,  
                           TitleApplicationSubmissionDate ,  
                           TitleReceivedDate,  
                           TitleCodeConfigId ,  
                           CreatedById,  
                           CreatedTime
						  ,VehiclePlateNumber
                          ,RegistrationCertificateNumber
                          ,RegistrationDate
                          ,UserInRegistrationCertificate
                          ,EngineNumber
                          ,Horsepower
                          ,BeginningMileage
                          ,TerminationMileage
                          ,ExcessMileage
                          ,EngineCapacity
                          ,KW
                          ,VehicleContractMileage
                          ,Axles
                          ,VehicleNumberOfKeys
                          ,VehicleNumberOfDoors
                          ,ColourId
                          ,ColourTypeId
                          ,SuspensionId
                          ,FrontTyreSizeId
                          ,RearTyreSizeId
                          ,WheelId
						  ,LoadCapacity
						  ,IsGPS
						  ,IsGPSTracker
						  ,IsImmobiliser
						  ,LastDateOfExecution
						  ,NextDateOfExecution

                     )  
              SELECT   
                           #CreatedAssetIds.Id,  
                           AssetVehicleDetail.R_AssetClassConfigId ,  
                           AssetVehicleDetail.VehicleType ,  
                           AssetVehicleDetail.TransmissionType,  
                           AssetVehicleDetail.TankCapacity,  
                           AssetVehicleDetail.InteriorColor,  
                           AssetVehicleDetail.NumberOfCylinders,  
                           AssetVehicleDetail.PayloadCapacity ,  
                            AssetVehicleDetail.R_FuelTypeConfigId,  
                           AssetVehicleDetail.EngineSize,  
                           AssetVehicleDetail.R_DriveTrainConfigId,  
                           AssetVehicleDetail.WeightClass,  
                           AssetVehicleDetail.CO2 ,  
                           AssetVehicleDetail.ContractMileage,  
                           AssetVehicleDetail.BodyDescription ,  
                           AssetVehicleDetail.OriginalOdometerReading ,  
                           AssetVehicleDetail.OdometerReadingUnit,  
                           AssetVehicleDetail.NumberOfDoors ,  
                           AssetVehicleDetail.R_BodyTypeConfigId,  
                           AssetVehicleDetail.NumberOfPassengers,  
                           AssetVehicleDetail.NumberOfSeats ,  
                           AssetVehicleDetail.KeylessEntry ,  
                           AssetVehicleDetail.MPG ,  
                           AssetVehicleDetail.NumberOfKeys,  
                           AssetVehicleDetail.DoorKeyCode ,  
                           AssetVehicleDetail.NumberOfRemotes ,  
                           AssetVehicleDetail.TireSize ,  
                           AssetVehicleDetail.EngineKeyCode,  
                           AssetVehicleDetail.ExteriorColor ,  
                           AssetVehicleDetail.WeightUnit ,  
                           AssetVehicleDetail.GVW ,  
                           AssetVehicleDetail.GrossCurbCombinedWeight,  
						   AssetVehicleDetail.VehicleRegisteredWeight ,  
                           AssetVehicleDetail.VehicleCurbWeight,  
                           AssetVehicleDetail.Titled ,  
                           AssetVehicleDetail.TitleTrustOverride,  
                           AssetVehicleDetail.R_StateId ,  
                           AssetVehicleDetail.TitleBorrowedReason ,  
                           AssetVehicleDetail.TitleBorrowedDate,  
                           AssetVehicleDetail.TitleLienHolder,  
                           AssetVehicleDetail.TitleApplicationSubmissionDate ,  
                           AssetVehicleDetail.TitleReceivedDate,  
                           AssetVehicleDetail.R_TitleCodeConfigId ,  
                           @UserId,  
                           @CreatedTime  
						  ,AssetVehicleDetail.VehiclePlateNumber
                          ,AssetVehicleDetail.RegistrationCertificateNumber
                          ,AssetVehicleDetail.RegistrationDate
                          ,AssetVehicleDetail.UserInRegistrationCertificate
                          ,AssetVehicleDetail.EngineNumber
                          ,AssetVehicleDetail.Horsepower
                          ,AssetVehicleDetail.BeginningMileage
                          ,AssetVehicleDetail.TerminationMileage
                          ,AssetVehicleDetail.ExcessMileage
                          ,AssetVehicleDetail.EngineCapacity
                          ,AssetVehicleDetail.KW
                          ,AssetVehicleDetail.VehicleContractMileage
                          ,AssetVehicleDetail.Axles
                          ,AssetVehicleDetail.VehicleNumberOfKeys
                          ,AssetVehicleDetail.VehicleNumberOfDoors
                          ,AssetVehicleDetail.R_ColourId
                          ,AssetVehicleDetail.R_ColourTypeId
                          ,AssetVehicleDetail.R_SuspensionId
                          ,AssetVehicleDetail.R_FrontTyreSizeId
                          ,AssetVehicleDetail.R_RearTyreSizeId
                          ,AssetVehicleDetail.R_WheelId
						  ,AssetVehicleDetail.LoadCapacity
						  ,AssetVehicleDetail.IsGPS
						  ,AssetVehicleDetail.IsGPSTracker
						  ,AssetVehicleDetail.IsImmobiliser
						  ,AssetVehicleDetail.LastDateOfExecution
						  ,AssetVehicleDetail.NextDateOfExecution


              FROM   
                     #AssetVehicleSubset AssetVehicleDetail  
                     INNER JOIN #CreatedAssetIds ON #CreatedAssetIds.AssetId = AssetVehicleDetail.Id  
                     INNER JOIN #AssetSubset ON #AssetSubset.Id = #CreatedAssetIds.AssetId  
                     Where #AssetSubset.IsVehicle=1  
                     ;  
              INSERT INTO AssetLocations  
              (  
                           EffectiveFromDate  
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
						   ,UpfrontTaxAssessedInLegacySystem
              )  
              SELECT   
                           AssetLocation.EffectiveFromDate,  
                           0,  
                           AssetLocation.UpfrontTaxMode,  
                           Case When Countries.TaxSourceType = @TaxSourceTypeNonVertex AND 
						   ((Select name from GlobalParameters where name = 'IsTaxSourceVertex' AND value = 'False' AND Category = 'SalesTax') IS NOT NULL) THEN LOC.TaxBasisType 
						   ELSE AssetLocation.TaxBasisType END,  
                           1,  
                           AssetLocation.IsFLStampTaxExempt,  
                           @UserId,  
                           @CreatedTime,  
                           NULL,  
                           NULL,  
                           AssetLocation.R_LocationId,  
                           #CreatedAssetIds.Id,  
                           0.0,  
                           #AssetSubset.Cost_Currency,  
                           0.0,  
                           #AssetSubset.Cost_Currency,
						   UpfrontTaxAssessedInLegacySystem
              FROM   
                           #AssetLocationSubset AssetLocation  
                           INNER JOIN #CreatedAssetIds ON #CreatedAssetIds.AssetId = AssetLocation.AssetId  
                           INNER JOIN #AssetSubset ON #AssetSubset.Id = #CreatedAssetIds.AssetId  
                           INNER JOIN Locations LOC ON AssetLocation.R_LocationId = LOC.Id  
						   INNER JOIN States ON States.Id = LOC.StateId
						   INNER JOIN Countries ON Countries.Id = States.CountryId
                           ;  
				 INSERT INTO AssetRepossessionLocations  
                 (  
                            EffectiveFromDate  
						   ,EffectiveTillDate  
                           ,IsCurrent                             
                           ,IsActive                            
                           ,CreatedById  
                           ,CreatedTime  
                           ,UpdatedById  
                           ,UpdatedTime  
                           ,LocationId  
                           ,AssetId                            
               )  
               SELECT   
                           AssetLocation.EffectiveFromDate,  
						   AssetLocation.EffectiveTillDate,  
                           AssetLocation.IsCurrent,  
						   1,                         
                           @UserId,  
                           @CreatedTime,  
                           NULL,  
                           NULL,  
                           AssetLocation.R_LocationId,  
                           #CreatedAssetIds.Id                        						   
              FROM   
                           #AssetRepossessionLocationSubset AssetLocation  
                           INNER JOIN #CreatedAssetIds ON #CreatedAssetIds.AssetId = AssetLocation.AssetId  
                           INNER JOIN #AssetSubset ON #AssetSubset.Id = #CreatedAssetIds.AssetId  
                           INNER JOIN Locations LOC ON AssetLocation.R_LocationId = LOC.Id  
						   INNER JOIN States ON States.Id = LOC.StateId
						   INNER JOIN Countries ON Countries.Id = States.CountryId
                           ;  

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

              INSERT INTO AssetFeatures  
              (  
                           Alias  
                           ,Description  
                           ,IsActive  
                           ,Quantity  
                           ,Value_Amount  
                           ,Value_Currency  
                           ,CreatedTime  
                           ,UpdatedTime  
                           ,ManufacturerId  
                           ,TypeId  
                           ,AssetId  
                           ,CreatedById  
                           ,UpdatedById  
                           ,AssetCategoryId  
                           ,ProductId  
                           ,AssetCatalogId  
                           ,StateId  
                           ,MakeId  
                           ,ModelId  
                           ,CurrencyId  
              )  
			  OUTPUT Inserted.Id INTO #CreatedAssetFeatureIds
		SELECT   
                           AssetFeature.Alias,  
                           AssetFeature.Description,  
                           1,  
                           AssetFeature.Quantity,  
                           AssetFeature.Value_Amount,  
                           AssetFeature.Value_Currency,  
                           @CreatedTime,  
                           NULL,  
                           AssetFeature.R_ManufacturerId,  
                           AssetFeature.R_AssetTypeId,  
                           #CreatedAssetIds.Id,  
                           @UserId,  
                           NULL,  
                           AssetFeature.R_AssetCategoryId,  
                           AssetFeature.R_ProductId,  
                           AssetFeature.R_AssetCatalogId,  
                           AssetFeature.R_StateId,  
                           AssetFeature.R_MakeId,  
                           AssetFeature.R_ModelId,  
                           AssetFeature.R_CurrencyId  
              FROM   
                           #AssetFeatureSubset AssetFeature  
                           INNER JOIN #CreatedAssetIds ON #CreatedAssetIds.AssetId = AssetFeature.AssetId; 
						   
        INSERT INTO AssetFeatures  
              (  
                           Alias                          
                           ,Description  
                           ,IsActive  
                           ,Quantity  
                           ,Value_Amount  
                           ,Value_Currency  
                           ,CreatedTime  
                           ,UpdatedTime  
                           ,ManufacturerId  
                           ,TypeId  
                           ,AssetId  
                           ,CreatedById  
                           ,UpdatedById  
                           ,AssetCategoryId  
                           ,ProductId  
                           ,AssetCatalogId  
                           ,StateId  
                           ,MakeId  
                           ,ModelId  
                           ,CurrencyId  
              )  
              SELECT   
                           AssetFeatureSet.Name,  
                           AssetFeatureSet.Description,  
                           1,  
                           AssetFeatureSet.Quantity,  
                           AssetFeatureSet.Value_Amount,  
                           AssetFeatureSet.Value_Currency,  
                           @CreatedTime,  
                           NULL,  
                           AssetFeatureSet.ManufacturerId,  
                           AssetFeatureSet.TypeId,  
                           #CreatedAssetIds.Id,  
                           @UserId,  
                           NULL,  
                           AssetFeatureSet.AssetCategoryId,  
                           AssetFeatureSet.ProductId,  
                           AssetFeatureSet.AssetCatalogId,  
                           AssetFeatureSet.StateId,  
                           AssetFeatureSet.MakeId,  
                           AssetFeatureSet.ModelId,  
                           AssetFeatureSet.CurrencyId  
              FROM   
                           #AssetFeatureSetSubset AssetFeatureSet  
                           INNER JOIN #CreatedAssetIds ON #CreatedAssetIds.AssetId = AssetFeatureSet.AssetId;  

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
              (  
                           MaximumReading  
                           ,IsActive  
                           ,CreatedTime  
                           ,UpdatedTime  
                           ,AssetMeterTypeId  
                           ,AssetId  
                           ,CreatedById  
                           ,UpdatedById  
                           ,BeginReading  
              )  
              SELECT   
                           AssetMeter.MaximumReading,  
                           1,  
                           @CreatedTime,  
                           NULL,  
                           AssetMeter.R_AssetMeterTypeId,  
                           #CreatedAssetIds.Id,  
                           @UserId,  
                           NULL,  
                           AssetMeter.BeginReading  
              FROM   
                     #AssetMeterSubset AssetMeter  
                     INNER JOIN #CreatedAssetIds ON #CreatedAssetIds.AssetId = AssetMeter.AssetId;

			  MERGE AssetSKUs AS AssetSKU
			  USING (SELECT [AS].*, #CreatedAssetIds.Id AS TargetAssetId  
					 FROM #AssetSKUSubset [AS]
                     INNER JOIN #CreatedAssetIds ON #CreatedAssetIds.AssetId = [AS].AssetId) AS AssetSKUToMigrate
		      ON 1 = 0
			  WHEN NOT MATCHED THEN 
			  INSERT
              (
                           Alias                        
                           ,Description
                           ,IsActive
                           ,Quantity
                           ,CreatedTime
                           ,ManufacturerId
                           ,TypeId
						   ,PricingGroupId  
                           ,AssetId
                           ,CreatedById
                           ,AssetCategoryId
                           ,ProductId
                           ,AssetCatalogId
                           ,MakeId
                           ,ModelId
						   ,IsLeaseComponent
						   ,IsSalesTaxExempt
						   ,Name
						   ,SerialNumber
              )
              VALUES 
              ( 
			               AssetSKUToMigrate.Alias,
                           AssetSKUToMigrate.Description,
                           1,
                           AssetSKUToMigrate.Quantity,
                           @CreatedTime,
                           AssetSKUToMigrate.R_ManufacturerId,
                           AssetSKUToMigrate.R_AssetTypeId,
						   AssetSKUToMigrate.R_PricingGroupId,  
                           AssetSKUToMigrate.TargetAssetId,
                           @UserId,
                           AssetSKUToMigrate.R_AssetCategoryId,
                           AssetSKUToMigrate.R_ProductId,
                           AssetSKUToMigrate.R_AssetCatalogId,
                           AssetSKUToMigrate.R_MakeId,
                           AssetSKUToMigrate.R_ModelId,
						   AssetSKUToMigrate.IsLeaseComponent,
						   AssetSKUToMigrate.IsSalesTaxExempt,
						   AssetSKUToMigrate.Name,
						   AssetSKUToMigrate.SerialNumber
                )          
			OUTPUT Inserted.Id, AssetSKUToMigrate.TargetAssetId, AssetSKUToMigrate.Cost_Amount,AssetSKUToMigrate.Cost_Currency,AssetSKUToMigrate.IsLeaseComponent INTO #CreatedAssetSKUsIds;
  
  
              Update parentAssets SET parentAssets.IsParent =  1  
              FROM Assets parentAssets  
              INNER JOIN Assets newAssets ON parentAssets.Id = newAssets.ParentAssetId  
              INNER JOIN #CreatedAssetIds C ON newAssets.Id = C.Id  
              UPDATE AssetLocations SET IsCurrent = 1   
                     WHERE Id in (SELECT Id FROM AssetLocations INNER JOIN (SELECT AssetId, MAX(EffectiveFromDate) AS EffectiveFromDate FROM AssetLocations WHERE CreatedById = @UserId GROUP BY AssetId) T    
                                                       ON AssetLocations.AssetId = T.AssetId  AND AssetLocations.EffectiveFromDate = T.EffectiveFromDate)  
                           AND AssetId in (SELECT #CreatedAssetIds.Id FROM #CreatedAssetIds)  

			INSERT INTO AssetValueHistories  
              (  
                           SourceModule  
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
                           ,IsLessorOwned  
						   ,IsLeaseComponent
              )
			  OUTPUT Inserted.Id,Inserted.AssetId,Inserted.IsLeaseComponent  INTO #CreatedAssetValueHistoryIds
              SELECT   
                           'AssetProfile',  
                           #CreatedAssetIds.Id,  
                           NULL,  
                           NULL,  
                           #AssetSubset.AcquisitionDate,  
                            #AssetSubset.Cost_Amount,  
                           #AssetSubset.Cost_Currency,  
                           #AssetSubset.Cost_Amount,  
                           #AssetSubset.Cost_Currency,  
                           #AssetSubset.Cost_Amount,  
                           #AssetSubset.Cost_Currency,  
                           #AssetSubset.Cost_Amount,  
                           #AssetSubset.Cost_Currency,  
                           #AssetSubset.Cost_Amount,  
                           #AssetSubset.Cost_Currency,  
                           CASE WHEN #AssetSubset.Status='Investor' THEN 0 ELSE 1 END,  
                           1,  
                           1,  
                           #AssetSubset.PostDate,  
                           NULL,  
                           @CreatedTime,  
                           NULL,  
                           #CreatedAssetIds.Id,  
                           NULL,  
                           NULL,  
                           @UserId,  
                           NULL,  
                           0,  
                           CASE WHEN #AssetSubset.Status='Investor' THEN 0 ELSE 1 END,
						   #CreatedAssetIds.IsLeaseComponent  
              FROM   
                     #CreatedAssetIds  
                     INNER JOIN #AssetSubset ON #AssetSubset.Id = #CreatedAssetIds.AssetId  
              WHERE #AssetSubset.Cost_Amount <> 0 AND #AssetSubset.IsSKU = 0

            INSERT INTO AssetValueHistories  
              (  
                           SourceModule  
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
                           ,IsLessorOwned  
						   ,IsLeaseComponent
              )
			  OUTPUT Inserted.Id,Inserted.AssetId,Inserted.IsLeaseComponent  INTO #CreatedAssetValueHistoryIds
              SELECT   
                           'AssetProfile',  
                           #CreatedAssetIds.Id,  
                           NULL,  
                           NULL,  
                           #AssetSubset.AcquisitionDate,  
                           SUM(#CreatedAssetSKUsIds.Cost_Amount),  
                           #AssetSubset.Cost_Currency,  
                           SUM(#CreatedAssetSKUsIds.Cost_Amount),   
                           #AssetSubset.Cost_Currency,  
                           SUM(#CreatedAssetSKUsIds.Cost_Amount),  
                           #AssetSubset.Cost_Currency,  
                           SUM(#CreatedAssetSKUsIds.Cost_Amount),  
                           #AssetSubset.Cost_Currency,  
                           SUM(#CreatedAssetSKUsIds.Cost_Amount),   
                           #AssetSubset.Cost_Currency,  
                           CASE WHEN #AssetSubset.Status='Investor' THEN 0 ELSE 1 END,  
                           1,  
                           1,  
                           #AssetSubset.PostDate,  
                           NULL,  
                           @CreatedTime,  
                           NULL,  
                           #CreatedAssetIds.Id,  
                           NULL,  
                           NULL,  
                           @UserId,  
                           NULL,  
                           0,  
                           CASE WHEN #AssetSubset.Status='Investor' THEN 0 ELSE 1 END,
						   #CreatedAssetSKUsIds.IsLeaseComponent  
              FROM   
                     #CreatedAssetIds  
                     INNER JOIN #AssetSubset ON #AssetSubset.Id = #CreatedAssetIds.AssetId  AND
					 #AssetSubset.Cost_Amount <> 0 AND #AssetSubset.IsSKU = 1
					 INNER JOIN #CreatedAssetSKUsIds ON #CreatedAssetIds.Id = #CreatedAssetSKUsIds.TargetAssetId
                    GROUP BY #CreatedAssetIds.Id, #AssetSubset.AcquisitionDate, 
					#AssetSubset.PostDate,#AssetSubset.Cost_Currency,#AssetSubset.Status,#CreatedAssetSKUsIds.IsLeaseComponent

			  INSERT INTO SKUValueProportions
		      (
						   Value_Amount
						   ,Value_Currency
						   ,CreatedById
						   ,CreatedTime
					       ,IsActive
					       ,AssetSKUId
						   ,AssetValueHistoryId
			  )
			  SELECT
						   SKU.Cost_Amount
						   ,SKU.Cost_Currency
						   ,@UserId
						   ,@CreatedTime
						   ,1
						   ,SKU.Id
						   ,AVH.Id
			  FROM			   
                           #CreatedAssetSKUsIds SKU  
						   INNER JOIN #CreatedAssetValueHistoryIds AVH 
						   ON SKU.TargetAssetId = AVH.TargetAssetId AND SKU.IsLeaseComponent  = AVH.IsLeaseComponent 
  
              INSERT INTO AssetHistories  
              (  
                           Reason  
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
						   ,PropertyTaxReportCodeId
                           ,IsReversed  
              )  
			  OUTPUT Inserted.Id, Inserted.AssetId INTO #CreatedAssetHistories
              SELECT    
                           'New',  
                           #AssetSubset.AcquisitionDate,  
                           #AssetSubset.AcquisitionDate,  
                           #AssetSubset.Status,  
                           #AssetSubset.FinancialType,  
                           'AssetProfile',  
                           #CreatedAssetIds.Id,  
                           @CreatedTime,  
                           NULL,  
                           #AssetSubset.R_CustomerId,  
                           NULL,  
                           #AssetSubset.R_LegalEntityId,  
                           #CreatedAssetIds.Id,  
                           @UserId,  
                           NULL,  
						   #AssetSubset.R_PropertyTaxReportId,
                           0  
              FROM   
                     #CreatedAssetIds  
                     INNER JOIN #AssetSubset ON #AssetSubset.Id = #CreatedAssetIds.AssetId			 

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

			CREATE TABLE #InsertedValueIds  
			(  
				  AssetsValueStatusChangeId BigInt   
				 ,Alias Nvarchar(100)  
			)  
			SELECT     
				AssetsMapped.PostDate    
			   ,Assets.Alias Comment    
			   ,'ValueAdjustment' Reason    
			   ,0 IsZeroMode    
			   ,@UserId CreatedById    
			   ,SYSDATETIMEOFFSET() CreatedTime    
			   ,Assets.LegalEntityId    
			   --,NULL GLJournalId    
			   ,Currencies.Id CurrencyId    
			   ,1    IsActive
			   ,'_'    SourceModule
			   ,NULL     SourceModuleID
			INTO #AssetsValueStatusChanges
			FROM Assets    
			 INNER JOIN #AssetSubset AssetsMapped ON Assets.Alias=AssetsMapped.Alias    
			 INNER JOIN CurrencyCodes ON Assets.CurrencyCode = CurrencyCodes.ISO    
			 INNER JOIN Currencies ON CurrencyCodes.Id = Currencies.CurrencyCodeId    
			 INNER JOIN #CreatedAssetIds ON #CreatedAssetIds.Id = Assets.Id  
			WHERE AssetsMapped.Cost_Amount > 0 AND AssetsMapped.Status !='Collateral'
			INSERT INTO AssetsValueStatusChanges  
			(  
						  PostDate  
						 ,Comment  
						 ,Reason  
						 ,IsZeroMode  
						 ,CreatedById  
						 ,CreatedTime  
						 ,LegalEntityId  
						 --,GLJournalId  
						 ,CurrencyId  
						 ,IsActive  
						 ,SourceModule  
						 ,SourceModuleID  
			)  
			OUTPUT Inserted.Id AssetsValueStatusChangeId, inserted.Comment Alias Into #InsertedValueIds  
			SELECT     
				*
			FROM #AssetsValueStatusChanges  
			SELECT     
				-1*(AssetsMapped.Cost_Amount) AdjustmentAmount_Amount    
				,AssetsMapped.Cost_Currency AdjustmentAmount_Currency    
				,AssetsMapped.Status NewStatus
				,@UserId  CreatedById  
				,SYSDATETIMEOFFSET() CreatedTime
				,Assets.Id AssetId
				,#InsertedValueIds.AssetsValueStatusChangeId AssetsValueStatusChangeId
				,AssetsMapped.R_CostCenterId CostCenterId
				,AssetsMapped.R_AssetBookValueAdjustmentGLTemplateId GLTemplateId
				,AssetsMapped.R_InstrumentTypeId InstrumentTypeId
				,AssetsMapped.R_LineofBusinessId LineofBusinessId
			INTO  #AssetsValueStatusChangeDetails
			FROM 
				Assets    
				INNER JOIN #AssetSubset AssetsMapped ON Assets.Alias=AssetsMapped.Alias    
				INNER JOIN #InsertedValueIds ON Assets.Alias = #InsertedValueIds.Alias
				INNER JOIN #CreatedAssetIds ON #CreatedAssetIds.Id = Assets.Id  
			INSERT INTO AssetsValueStatusChangeDetails  
			(  
						  AdjustmentAmount_Amount  
						 ,AdjustmentAmount_Currency  
						 ,NewStatus  
						 ,CreatedById  
						 ,CreatedTime  
						 ,AssetId  
						 ,AssetsValueStatusChangeId  
						 ,CostCenterId  
						 ,GLTemplateId  
						 ,InstrumentTypeId  
						 ,LineofBusinessId  
			)  
			SELECT     
				*
			FROM #AssetsValueStatusChangeDetails     
			UPDATE AssetValueHistories  
			SET   
				SourceModule = 'AssetValueAdjustment',  
				SourceModuleId = #InsertedValueIds.AssetsValueStatusChangeId  
			FROM Assets  
			INNER JOIN AssetValueHistories ON Assets.Id = AssetValueHistories.AssetId  
			INNER JOIN #InsertedValueIds ON UPPER(Assets.Alias)  = UPPER( #InsertedValueIds.Alias)  
			CREATE TABLE #CreatedGLJournalId  
			(  
				 MergeAction nvarchar(20),  
				 GLJournalId bigint,  
				 AssetId BigInt  
			)  
			MERGE INTO GLJournals  
			USING   
			(  
					SELECT AssetValueHistories.*,AssetsMapped.R_LegalEntityId,AssetsMapped.PostDate AssetPostDate  
					FROM Assets  
					INNER JOIN AssetValueHistories ON Assets.Id = AssetValueHistories.AssetId  
					INNER JOIN #AssetSubset AssetsMapped ON Assets.Alias=AssetsMapped.Alias  
					WHERE AssetsMapped.Cost_Amount > 0 AND AssetsMapped.Status !='Collateral'  
			) AS assetValueHistories  
			ON assetValueHistories.GLJournalId = GLJournals.Id  
			WHEN MATCHED  
			THEN UPDATE SET UpdatedTime = @CreatedTime  
			WHEN NOT MATCHED  
			THEN  
			INSERT   
			(  
					 PostDate  
					 ,IsManualEntry  
					 ,IsReversalEntry  
					 ,CreatedById  
					 ,CreatedTime  
					 ,LegalEntityId  
			)  
			VALUES   
			(  
					 assetValueHistories.AssetPostDate,  
					 0,  
					 0,  
					 @UserId,  
					 @CreatedTime,  
					 assetValueHistories.R_LegalEntityId  
			)  
			OUTPUT $ACTION, INSERTED.Id,assetValueHistories.AssetId INTO #CreatedGLJournalId;  
			UPDATE AssetValueHistories  
			SET 
				GLJournalId=#CreatedGLJournalId.GLJournalId  
			FROM AssetValueHistories  
			INNER JOIN #CreatedGLJournalId ON #CreatedGLJournalId.AssetID = AssetValueHistories.AssetID  
			UPDATE AssetsValueStatusChangeDetails  
			SET 
				GLJournalId=#CreatedGLJournalId.GLJournalId  
			FROM AssetsValueStatusChangeDetails  
			INNER JOIN #CreatedGLJournalId ON #CreatedGLJournalId.AssetID = AssetsValueStatusChangeDetails.AssetID  
			INSERT INTO #GLAccountNumbers (InstrumentTypeId, GLTemplateDetailId, LegalEntityId, LineofBusinessId, CostCenterId, CurrencyId, GLAccountId, IsDebit, IsProcessed, GLAccountNumber)
			SELECT DISTINCT AssetsMapped.R_InstrumentTypeId,GLTemplateDetails.Id, AssetsMapped.R_LegalEntityId,AssetsMapped.R_LineofBusinessId,AssetsMapped.R_CostCenterId,AssetsMapped.R_CurrencyId, GLTemplateDetails.GLAccountId, GLEntryItems.IsDebit, 0, NULL
			FROM #AssetSubset AssetsMapped
			INNER JOIN GLTemplateDetails ON AssetsMapped.R_AssetBookValueAdjustmentGLTemplateId=GLTemplateDetails.GLTemplateId  
			INNER JOIN GLEntryItems ON GLTemplateDetails.EntryItemId=GLEntryItems.Id AND GLEntryItems.Name IN ('Expense', 'Inventory')
			INNER JOIN #CreatedAssetIds ON #CreatedAssetIds.Alias = AssetsMapped.Alias
			WHERE AssetsMapped.Cost_Amount > 0 AND AssetsMapped.Status !='Collateral'  
			WHILE (SELECT Count(*) From #GLAccountNumbers Where IsProcessed = 0) > 0  
			BEGIN
			DECLARE @Id BIGINT,
			@InstrumentTypeId bigint,
			@GLTemplateDetailId bigint,
			@LegalEntityId bigint,
			@LineofBusinessId bigint,
			@CostCenterId bigint,
			@CurrencyId bigint
			SELECT TOP 1 @Id = Id, @InstrumentTypeId = InstrumentTypeId, @GLTemplateDetailId = GLTemplateDetailId,
			@LegalEntityId = LegalEntityId, @LineofBusinessId = LineofBusinessId, @CostCenterId = CostCenterId, @CurrencyId = CurrencyId 
			FROM #GLAccountNumbers Where IsProcessed = 0
			DECLARE @GLAccountNumber NVARCHAR(100);
			EXEC @GLAccountNumber = dbo.[GetGLAccountNumber] @InstrumentTypeId, @GLTemplateDetailId,NULL,NULL, @LegalEntityId,@LineofBusinessId,'',@CostCenterId,@CurrencyId,0,''
			UPDATE #GLAccountNumbers SET GLAccountNumber = @GLAccountNumber, IsProcessed = 1
			WHERE Id = @Id
			END
			CREATE TABLE #AssetGLDetails  
			(  
				AssetId BIGINT,  
				IsDebit BIT,  
				GLAccountNumber NVARCHAR(100),  
				GLAccountId BIGINT,  
				GLTemplateDetailId BIGINT,  
				MatchingGLTemplateDetailId BIGINT  
			)  
			INSERT INTO #AssetGLDetails  
			(  
					   AssetId,  
					   IsDebit,  
					   GLAccountNumber,  
					   GLAccountId,  
					   GLTemplateDetailId,  
					   MatchingGLTemplateDetailId  
			)   
			SELECT  
						Assets.Id  
					   ,AccountNumber.IsDebit  
					   ,AccountNumber.GLAccountNumber
					   ,AccountNumber.GLAccountId [GLAccountId]  
					   ,AccountNumber.GLTemplateDetailId
					   ,NULL AS MatchingGLTemplateDetailId  
			  FROM Assets    
			  INNER JOIN #AssetSubset AssetsMapped ON Assets.Alias=AssetsMapped.Alias  
			  INNER JOIN #CreatedAssetIds ON #CreatedAssetIds.Id = Assets.Id  
			  INNER JOIN #GLAccountNumbers AccountNumber ON AssetsMapped.R_InstrumentTypeId = AccountNumber.InstrumentTypeId AND AssetsMapped.R_LegalEntityId = AccountNumber.LegalEntityId
			  AND AssetsMapped.R_LineofBusinessId = AccountNumber.LineofBusinessId AND AssetsMapped.R_CostCenterId = AccountNumber.CostCenterId AND AssetsMapped.R_CurrencyId = AccountNumber.CurrencyId 
			  SELECT    
					AssetsValueStatusChanges.Id    EntityId
					,'AssetValueAdjustment'    EntityType
					,AssetsMapped.Cost_Amount    Amount_Amount
					,AssetsMapped.Cost_Currency    Amount_Currency
					,CASE WHEN AssetsMapped.Cost_Amount>0 THEN ~#AssetGLDetails.IsDebit ELSE #AssetGLDetails.IsDebit END IsDebit  
					,#AssetGLDetails.GLAccountNumber GLAccountNumber   
					,'Asset Value Adjustment'    Description
					,AssetsValueStatusChanges.Id    SourceId
					,@UserId    CreatedById
					,@CreatedTime    CreatedTime
					,#AssetGLDetails.GLAccountId    GLAccountId
					,#AssetGLDetails.GLTemplateDetailId   GLTemplateDetailId 
					,#AssetGLDetails.MatchingGLTemplateDetailId  MatchingGLTemplateDetailId  
					,GLJournals.Id    GLJournalId
					,1     IsActive
					,AssetsMapped.R_LineofBusinessId LineofBusinessId
				INTO #GLJournalDetails	    
				FROM Assets    
					INNER JOIN AssetValueHistories ON Assets.Id = AssetValueHistories.AssetId    
					INNER JOIN #AssetSubset AssetsMapped ON Assets.Alias=AssetsMapped.Alias    
					INNER JOIN GLJournals ON AssetValueHistories.GLJournalId=GLJournals.Id    
					INNER JOIN AssetsValueStatusChangeDetails ON Assets.Id=AssetsValueStatusChangeDetails.AssetId    
					INNER JOIN AssetsValueStatusChanges ON AssetsValueStatusChangeDetails.AssetsValueStatusChangeId=AssetsValueStatusChanges.Id    
					INNER JOIN #AssetGLDetails ON Assets.Id=#AssetGLDetails.AssetId    
					INNER JOIN #CreatedAssetIds ON #CreatedAssetIds.Id = Assets.Id    
				WHERE AssetsMapped.Cost_Amount > 0 AND AssetsMapped.Status !='Collateral'    
			  INSERT INTO GLJournalDetails   
			  ( 
					   EntityId,  
					   EntityType,  
					   Amount_Amount,  
					   Amount_Currency,  
					   IsDebit,  
					   GLAccountNumber,  
					   Description,  
					   SourceId,   
					   CreatedById,  
					   CreatedTime,  
					   GLAccountId,  
					   GLTemplateDetailId,  
					   MatchingGLTemplateDetailId,  
					   GLJournalId,  
					   IsActive,  
					   LineofBusinessId  
			  )  
			 SELECT    
				   *
			 FROM #GLJournalDetails  
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
		SET @SkipCount = @SkipCount + @BatchCount; 
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
       SET @FailedRecords = @FailedRecords+(SELECT COUNT(DISTINCT StagingRootEntityId) FROM #ErrorLogs)
	   DELETE #FailedProcessingLogs
	   DELETE #ErrorLogs

	   DROP TABLE #AssetSubset  
       DROP TABLE #AssetFeatureSubset  
       DROP TABLE #AssetVehicleSubset  
       DROP TABLE #AssetLocationSubset  
       DROP TABLE #AssetMeterSubset  
       DROP TABLE #CreatedAssetIds  
       DROP TABLE #CreatedProcessingLogs  
       DROP TABLE #InsertedTaxExemptRuleIds  
       DROP TABLE #AssetCatalogValues  
       DROP TABLE #AssetFeatureSetSubset  
       DROP TABLE #AssetTypeAccountingComplianceDetails  
       DROP TABLE #InsertedValueIds  
       DROP TABLE #CreatedGLJournalId  
       DROP TABLE #AssetGLDetails
	   DROP TABLE #AssetsValueStatusChangeDetails
	   DROP TABLE #GLAccountNumbers  
	   DROP TABLE #GLJournalDetails
	   DROP TABLE #AssetsValueStatusChanges
	   DROP TABLE #AssetSKUSubset
	   DROP TABLE #CreatedAssetSKUsIds  
	   DROP TABLE #CreatedAssetValueHistoryIds
	   DROP TABLE #CreatedAssetSerialNumbers
	   DROP TABLE #CreatedAssetFeatureIds
	   DROP TABLE #CreatedAssetHistories
	   DROP TABLE #AllSerialNumbersWithinAsset
	   DROP TABLE #AssetSerialNumberSubset
	   DROP TABLE #AssetFeatureSerialNumberSubset

COMMIT TRANSACTION
END TRY
BEGIN CATCH
	SET @SkipCount = @SkipCount  + @BatchCount;
	DECLARE @ErrorMessage Nvarchar(max);
	DECLARE @ErrorLine Nvarchar(max);
	DECLARE @ErrorSeverity INT;
	DECLARE @ErrorState INT;
	DECLARE @ErrorLogs ErrorMessageList;
	DECLARE @ModuleName Nvarchar(max) = 'MigrateAssets'
	Insert into @ErrorLogs(StagingRootEntityId, ModuleIterationStatusId, Message,Type) VALUES (0,@ModuleIterationStatusId,ERROR_MESSAGE(),'Error')
	SELECT  @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE(),@ErrorLine=ERROR_LINE(),@ErrorMessage=ERROR_MESSAGE()
	IF (XACT_STATE()) = -1  
	BEGIN  
		ROLLBACK TRANSACTION;
		EXEC [dbo].[ExceptionLog] @ErrorLogs,@ErrorLine,@UserId,@CreatedTime,@ModuleName
		SET @FailedRecords = @FailedRecords+@BatchCount;
	END;  
	IF (XACT_STATE()) = 1  
	BEGIN
		COMMIT TRANSACTION;
		RAISERROR (@ErrorMessage,@ErrorSeverity, @ErrorState);     
	END;  

END CATCH  

END  
       SET @ProcessedRecords = @ProcessedRecords + @TotalRecordsCount; 	
	   DROP TABLE #FailedProcessingLogs  
	   DROP TABLE #ErrorLogs
SET NOCOUNT OFF  
SET XACT_ABORT OFF
END  

GO

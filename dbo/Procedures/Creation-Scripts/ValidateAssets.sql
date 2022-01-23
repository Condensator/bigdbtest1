SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[ValidateAssets]
(@UserId                  BIGINT,
@ModuleIterationStatusId BIGINT,
@CreatedTime             DATETIMEOFFSET,
@ProcessedRecords        BIGINT OUTPUT,
@FailedRecords           BIGINT OUTPUT
)
AS
BEGIN
CREATE TABLE #ErrorLogs
(Id                  BIGINT NOT NULL IDENTITY PRIMARY KEY,
StagingRootEntityId BIGINT,
Result              NVARCHAR(10),
Message             NVARCHAR(MAX)
);
CREATE TABLE #FailedProcessingLogs
([Id]      BIGINT NOT NULL,
[AssetId] BIGINT NOT NULL
);
CREATE TABLE #CreatedProcessingLogs([Id] BIGINT NOT NULL);
SET @ProcessedRecords =
(
SELECT ISNULL(COUNT(Id), 0)
FROM stgAsset
WHERE IsMigrated = 0
);
INSERT INTO #ErrorLogs
SELECT AF.AssetId
, 'Error'
, ('Currency is Invalid in Asset Feature for the Asset : ' + CAST(AF.AssetId AS NVARCHAR(MAX))) AS Message
FROM stgAssetFeature AF
INNER JOIN dbo.stgAsset A ON A.Id = AF.AssetId
LEFT JOIN CurrencyCodes ON AF.Currency = CurrencyCodes.ISO
LEFT JOIN Currencies ON CurrencyCodes.Id = Currencies.CurrencyCodeId
AND Currencies.IsActive = 1
WHERE Currencies.Id IS NULL
AND AF.Currency IS NOT NULL
AND A.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT A.Id
, 'Error'
, ('Asset-StateShortName is required when the collateral tracking(AssetTypes.IsCollateralTracking) is true for Asset type :' + ISNULL(A.AssetType, 'NULL')) AS Message
FROM stgAsset A
LEFT JOIN AssetTypes AssetType ON AssetType.Name = A.AssetType AND AssetType.IsActive = 1
WHERE A.IsMigrated = 0 
AND LTRIM(RTRIM(ISNULL(A.StateShortName,'')))='' 
AND LTRIM(RTRIM(ISNULL(A.AssetType,'')))<>'' 
AND AssetType.IsCollateralTracking=1;
INSERT INTO #ErrorLogs
SELECT AF.AssetId
, 'Error'
, ('State is Invalid in Asset Feature for the Asset Feature Alias: ' + ISNULL(AF.Alias, '')) AS Message
FROM stgAssetFeature AF
INNER JOIN dbo.stgAsset A ON A.Id = AF.AssetId
LEFT JOIN States ON AF.StateShortName = States.ShortName
AND States.IsActive = 1
WHERE States.Id IS NULL
AND AF.StateShortName IS NOT NULL
AND A.IsMigrated = 0;

INSERT INTO #ErrorLogs  
              SELECT  
                 A.Id  
                ,'Error'  
                ,('Value (Excl VAT) should be Greater Than Zero for the Asset : '+ CAST (A.Id AS nvarchar(max)) ) AS Message  
              FROM   
                     stgAsset A  
              WHERE   
                    A.IsMigrated=0 AND A.ValueExclVAT_Amount<0


			  INSERT INTO #ErrorLogs  
              SELECT  
                 A.Id  
                ,'Error'  
                ,('Please Enter Usage Condition for the Asset : '+ CAST (A.Id AS nvarchar(max)) ) AS Message  
              FROM   
                     stgAsset A  
              WHERE   
                     A.IsMigrated=0 AND A.UsageCondition IS NULL 

			  INSERT INTO #ErrorLogs  
              SELECT  
                 A.Id  
                ,'Error'  
                ,('Please Enter Date Of Production for the Asset : '+ CAST (A.Id AS nvarchar(max)) ) AS Message  
              FROM   
                     stgAsset A  
              WHERE   
                     A.IsMigrated=0 AND A.DateofProduction IS NULL

			 INSERT INTO #ErrorLogs  
              SELECT  
                 A.Id  
                ,'Error'  
                ,('Please Enter Acquired Date for the Asset : '+ CAST (A.Id AS nvarchar(max)) ) AS Message  
              FROM   
                     stgAsset A  
              WHERE   
                     A.IsMigrated=0 AND A.AcquiredDate IS NULL

			  INSERT INTO #ErrorLogs  
              SELECT  
                 A.Id  
                ,'Error'  
                ,('Please Choose Pre-Leased for the Asset : '+ CAST (A.Id AS nvarchar(max)) ) AS Message  
              FROM   
                     stgAsset A  
              WHERE   
                   A.IsMigrated=0 AND A.IsPreLeased IS NULL AND A.UsageCondition IS NOT NULL AND A.UsageCondition='Used'  

			  			  INSERT INTO #ErrorLogs  
              SELECT  
                 A.Id  
                ,'Error'  
                ,('Please Choose Is-Import for the Asset : '+ CAST (A.Id AS nvarchar(max)) ) AS Message  
              FROM   
                     stgAsset A  
              WHERE   
                   A.IsMigrated=0 AND  A.IsImport IS NULL AND A.UsageCondition IS NOT NULL AND A.UsageCondition='Used' 
			 
			  INSERT INTO #ErrorLogs  
              SELECT  
                     AV.Id  
                     ,'Error'  
                     ,('Please Enter Transmission Type  in Vehicle Detail for the Asset: '+stgAsset.Alias) AS Message  
              FROM   
                     stgAssetVehicleDetail AV  
                     INNER JOIN stgAsset on AV.Id =stgAsset.Id  
              WHERE   
                    stgAsset.IsMigrated=0 AND  AV.TransmissionType IS NULL 
                     AND stgAsset.IsVehicle=1

			  INSERT INTO #ErrorLogs  
              SELECT  
                     AV.Id  
                     ,'Error'  
                     ,('Please Enter Fuel Type  in Vehicle Detail for the Asset: '+stgAsset.Alias) AS Message  
              FROM   
                     stgAssetVehicleDetail AV  
                     INNER JOIN stgAsset on AV.Id =stgAsset.Id  
              WHERE   
                     stgAsset.IsMigrated=0 AND AV.FuelType IS NULL 
                     AND stgAsset.IsVehicle=1

			  INSERT INTO #ErrorLogs  
              SELECT  
                     AV.Id  
                     ,'Error'  
                     ,('Please Enter Engine Number  in Vehicle Detail for the Asset: '+stgAsset.Alias) AS Message  
              FROM   
                     stgAssetVehicleDetail AV  
                     INNER JOIN stgAsset on AV.Id =stgAsset.Id  
              WHERE   
                     stgAsset.IsMigrated=0 AND AV.EngineNumber IS NULL 
                     AND stgAsset.IsVehicle=1

			  INSERT INTO #ErrorLogs  
              SELECT  
                     AV.Id  
                     ,'Error'  
                     ,('Please Enter Vehicle Number of Doors  in Vehicle Detail for the Asset: '+stgAsset.Alias) AS Message  
              FROM   
                     stgAssetVehicleDetail AV  
                     INNER JOIN stgAsset on AV.Id =stgAsset.Id  
              WHERE   
                     stgAsset.IsMigrated=0 AND AV.VehicleNumberOfDoors IS NULL 
                     AND stgAsset.IsVehicle=1

			  INSERT INTO #ErrorLogs  
              SELECT  
                     AV.Id  
                     ,'Error'  
                     ,('Please Enter Vehicle Number of Keys  in Vehicle Detail for the Asset: '+stgAsset.Alias) AS Message  
              FROM   
                     stgAssetVehicleDetail AV  
                     INNER JOIN stgAsset on AV.Id =stgAsset.Id  
              WHERE   
                     stgAsset.IsMigrated=0 AND AV.VehicleNumberOfKeys IS NULL 
                     AND stgAsset.IsVehicle=1

			  
			  INSERT INTO #ErrorLogs  
              SELECT  
                     AV.Id  
                     ,'Error'  
                     ,('Please Enter Number of seats  in Vehicle Detail for the Asset: '+stgAsset.Alias) AS Message  
              FROM   
                     stgAssetVehicleDetail AV  
                     INNER JOIN stgAsset on AV.Id =stgAsset.Id  
              WHERE   
                     stgAsset.IsMigrated=0 AND AV.NumberOfSeats IS NULL 
                     AND stgAsset.IsVehicle=1


             INSERT INTO #ErrorLogs  
              SELECT  
                     AV.Id  
                     ,'Error'  
                     ,('Please Enter GVW(weight)  in Vehicle Detail for the Asset: '+stgAsset.Alias) AS Message  
              FROM   
                     stgAssetVehicleDetail AV  
                     INNER JOIN stgAsset on AV.Id =stgAsset.Id  
              WHERE   
                     stgAsset.IsMigrated=0 AND AV.GVW IS NULL 
                     AND stgAsset.IsVehicle=1
              
			  INSERT INTO #ErrorLogs  
              SELECT  
                     AV.Id  
                     ,'Error'  
                     ,('Engine Size should be Greater than zero in Vehicle detail for the Asset: '+stgAsset.Alias) AS Message  
              FROM   
                     stgAssetVehicleDetail AV  
                     INNER JOIN stgAsset on AV.Id =stgAsset.Id
					 INNER JOIN AssetTypes on stgAsset.R_AssetTypeId = AssetTypes.Id
              WHERE   
                     stgAsset.IsMigrated=0 AND  AssetTypes.Istrailer=1 AND (AV.EngineSize IS NULL OR AV.EngineSize<0 )
                     AND stgAsset.IsVehicle=1

INSERT INTO #ErrorLogs
SELECT AF.AssetId
, 'Error'
, ('Asset Catalog is Invalid in Asset Feature for the Asset Feature Alias: ' + ISNULL(AF.Alias, '')) AS Message
FROM stgAssetFeature AF
INNER JOIN dbo.stgAsset A ON A.Id = AF.AssetId
LEFT JOIN AssetCatalogs AC ON AC.CollateralCode = AF.AssetCatalog
AND AC.IsActive = 1
WHERE AC.Id IS NULL
AND AF.AssetCatalog IS NOT NULL
AND A.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT AF.AssetId
, 'Error'
, ('AssetType is Invalid in Asset Feature for the Asset Feature Alias: ' + ISNULL(AF.Alias, '')) AS Message
FROM stgAssetFeature AF
INNER JOIN dbo.stgAsset A ON A.Id = AF.AssetId
LEFT JOIN AssetTypes ON AssetTypes.Name = AF.AssetType
AND AssetTypes.IsActive = 1
WHERE AssetTypes.Id IS NULL
AND AF.AssetType IS NOT NULL
AND A.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT AF.AssetId
, 'Error'
, ('Product is Invalid in Asset Feature for the Asset Feature Alias: ' + ISNULL(AF.Alias, '')) AS Message
FROM stgAssetFeature AF
INNER JOIN dbo.stgAsset A ON A.Id = AF.AssetId
LEFT JOIN Products ON Products.Name = AF.AssetProduct
AND Products.IsActive = 1
WHERE Products.Id IS NULL
AND AF.AssetProduct IS NOT NULL
AND A.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT AF.AssetId
, 'Error'
, ('Asset Category is Invalid in Asset Feature for the Asset Feature Alias: ' + ISNULL(AF.Alias, '')) AS Message
FROM stgAssetFeature AF
INNER JOIN dbo.stgAsset A ON A.Id = AF.AssetId
LEFT JOIN AssetCategories ON AssetCategories.Name = AF.AssetCategory
AND AssetCategories.IsActive = 1
WHERE AssetCategories.Id IS NULL
AND AF.AssetCategory IS NOT NULL
AND A.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT AF.AssetId
, 'Error'
, ('Manufacturer is Invalid in Asset Feature for the Asset Feature Alias: ' + ISNULL(AF.Alias, '')) AS Message
FROM stgAssetFeature AF
INNER JOIN dbo.stgAsset A ON A.Id = AF.AssetId
LEFT JOIN Manufacturers ON Manufacturers.Name = AF.Manufacturer
AND Manufacturers.IsActive = 1
WHERE Manufacturers.Id IS NULL
AND AF.Manufacturer IS NOT NULL
AND A.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT stgAsset.Id
, 'Error'
, ('Asset Alias Must be Unique, Alias : ' + stgAsset.Alias + ' already exist') AS Message
FROM stgAsset
LEFT JOIN Assets ON stgAsset.Alias = Assets.Alias
WHERE Assets.Alias IS NOT NULL
AND stgAsset.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT A.Id
, 'Error'
, ('No Matching Legal Entity with Legal Entity Number : ' + ISNULL(A.[LegalEntityNumber], 'NULL')) AS Message
FROM stgAsset A
LEFT JOIN LegalEntities ON LegalEntities.LegalEntityNumber = A.LegalEntityNumber
AND LegalEntities.STATUS = 'Active'
WHERE LegalEntities.Id IS NULL
AND A.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT A.Id
, 'Error'
, ('Matching Asset Type not found for Asset Type :' + ISNULL(A.AssetType, 'NULL')) AS Message
FROM stgAsset A
LEFT JOIN AssetTypes AssetType ON AssetType.Name = A.AssetType AND AssetType.IsActive = 1
LEFT JOIN AssetCatalogs ON AssetCatalogs.CollateralCode = A.AssetCatalog
WHERE AssetType.Id IS NULL
AND A.IsMigrated = 0
AND A.AssetType IS NOT NULL AND AssetCatalogs.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT A.Id
, 'Error'
, ('Matching Asset Product not found for Asset Product :' + ISNULL(A.AssetProduct, 'NULL')) AS Message
FROM stgAsset A
LEFT JOIN Products Product ON Product.Name = A.AssetProduct
AND Product.IsActive = 1
WHERE Product.Id IS NULL
AND AssetProduct IS NOT NULL
AND A.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT A.Id
, 'Error'
, ('Matching Asset Category not found for Asset Category :' + ISNULL(A.AssetCategory, 'NULL')) AS Message
FROM stgAsset A
LEFT JOIN AssetCategories Category ON Category.Name = A.AssetCategory
AND Category.IsActive = 1
WHERE Category.Id IS NULL
AND AssetCategory IS NOT NULL
AND A.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT Id
, 'Error'
, ('Financial Type must be Real / Deposit / Dummy while creating Asset') AS Message
FROM stgAsset
WHERE stgAsset.FinancialType NOT IN('Deposit', 'Real', 'Dummy')
AND stgAsset.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT Id
, 'Error'
, ('Collateral Asset must have Financial Type as Real or Dummy') AS Message
FROM stgAsset
WHERE stgAsset.STATUS = 'Collateral'
AND stgAsset.FinancialType NOT IN('Real', 'Dummy')
AND stgAsset.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT Id
, 'Error'
, ('Please Enter ManufacturerOverride') AS Message
FROM stgAsset
WHERE stgAsset.IsManufacturerOverride = 1
AND stgAsset.ManufacturerOverride IS NULL
AND stgAsset.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT Id
, 'Error'
, ('Investor Asset must have Financial Type as Real or Deposit') AS Message
FROM stgAsset
WHERE stgAsset.STATUS = 'Investor'
AND stgAsset.FinancialType NOT IN('Deposit', 'Real')
AND stgAsset.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT Id
, 'Error'
, ('Status must be Inventory / Investor / Collateral while creating Asset') AS Message
FROM stgAsset
WHERE stgAsset.STATUS NOT IN('Inventory', 'Investor', 'Collateral')
AND stgAsset.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT A.Id
, 'Error'
, ('No Matching Manufacturer with Manufacturer Name : ' + A.[Manufacturer]) AS Message
FROM stgAsset A
LEFT JOIN Manufacturers Manufacturer ON Manufacturer.Name = A.Manufacturer
AND Manufacturer.IsActive = 1
WHERE Manufacturer.Id IS NULL
AND A.Manufacturer IS NOT NULL
AND A.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT A.Id
, 'Error'
, ('No Matching Make with Make Name : ' + A.[Make]) AS Message
FROM stgAsset A
LEFT JOIN Makes Make ON Make.Name = A.Make
AND Make.IsActive = 1
WHERE Make.Id IS NULL
AND A.Make IS NOT NULL
AND A.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT A.Id
, 'Error'
, ('No Matching Asset Feature with Asset Feature Name : ' + A.[AssetFeatureSetName]) AS Message
FROM stgAsset A
LEFT JOIN AssetFeatureSets AssetFeatureSet ON AssetFeatureSet.Name = A.AssetFeatureSetName
AND AssetFeatureSet.IsActive = 1
WHERE AssetFeatureSet.Id IS NULL
AND A.AssetFeatureSetName IS NOT NULL
AND A.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT A.Id
, 'Error'
, ('No Matching Asset Usage with Asset Usage Name : ' + A.[AssetUsage]) AS Message
FROM stgAsset A
LEFT JOIN AssetUsages AssetUsage ON AssetUsage.Usage = A.AssetUsage
AND AssetUsage.IsActive = 1
WHERE AssetUsage.Id IS NULL
AND A.AssetUsage IS NOT NULL
AND A.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT A.Id
, 'Error'
, ('No Matching Asset Book Value Adjustment GLTemplate with Asset Book Value Adjustment GLTemplate Name : ' + A.[AssetBookValueAdjustmentGLTemplateName]) AS Message
FROM stgAsset A
LEFT JOIN GLTemplates GL ON GL.Name = A.AssetBookValueAdjustmentGLTemplateName
AND GL.IsActive = 1
WHERE GL.Id IS NULL
AND A.AssetBookValueAdjustmentGLTemplateName IS NOT NULL
AND A.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT A.Id
, 'Error'
, ('No Matching Book Depreciation GLTemplate with Book Depreciation GLTemplate Name : ' + A.[BookDepreciationGLTemplateName]) AS Message
FROM stgAsset A
LEFT JOIN GLTemplates GL ON GL.Name = A.BookDepreciationGLTemplateName
AND GL.IsActive = 1
WHERE GL.Id IS NULL
AND A.BookDepreciationGLTemplateName IS NOT NULL
AND A.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT A.Id
, 'Error'
, ('No Matching Instrument Type with Instrument Type Name : ' + A.[InstrumentTypeName]) AS Message
FROM stgAsset A
LEFT JOIN InstrumentTypes IT ON IT.Code = A.InstrumentTypeName
AND IT.IsActive = 1
WHERE IT.Id IS NULL
AND A.InstrumentTypeName IS NOT NULL
AND A.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT A.Id
, 'Error'
, ('No Matching Line of Business with Line of Business Name : ' + A.[LineofBusinessName]) AS Message
FROM stgAsset A
LEFT JOIN LineofBusinesses LOB ON LOB.Name = A.LineofBusinessName
AND LOB.IsActive = 1
WHERE LOB.Id IS NULL
AND A.LineofBusinessName IS NOT NULL
AND A.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT Id
, 'Error'
, ('Quantity must be greater than 0') AS Message
FROM stgAsset
WHERE stgAsset.Quantity = 0
AND IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT stgAsset.Id
  ,'Error'
  ,('Invalid ParentAssetAlias <'+ ParentAssetAlias +'> for Asset Alias '+ Alias +' ') AS Message
FROM  stgAsset   
WHERE IsMigrated = 0 AND
      stgAsset.ParentAssetAlias IS NOT NULL AND stgAsset.ParentAssetAlias NOT IN (select Alias from Assets UNION select Alias from stgAsset);
INSERT INTO #ErrorLogs
SELECT AV.Id
, 'Error'
, ('State is Invalid in Vehicle Detail for the Asset: ' + stgAsset.Alias) AS Message
FROM stgAssetVehicleDetail AV
INNER JOIN stgAsset ON AV.Id = stgAsset.Id
LEFT JOIN States ON States.ShortName = AV.TitleState
AND States.IsActive = 1
WHERE AV.TitleState IS NOT NULL
AND AV.TitleState != ''
AND States.Id IS NULL
AND stgAsset.IsVehicle = 1
AND stgAsset.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT AV.Id
, 'Error'
, ('Weight Unit must be LBs/Kgs/Tons/MetricTons in Vehicle Detail for the Asset: ' + stgAsset.Alias) AS Message
FROM stgAssetVehicleDetail AV
INNER JOIN stgAsset ON AV.Id = stgAsset.Id
WHERE AV.WeightUnit NOT IN('LBs', 'Kgs', 'Tons', 'MetricTons', '_')
AND stgAsset.IsVehicle = 1
AND stgAsset.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT AV.Id
, 'Error'
, ('Odometer Reading Unit must be Miles/KMs in Vehicle Detail for the Asset: ' + stgAsset.Alias) AS Message
FROM stgAssetVehicleDetail AV
INNER JOIN stgAsset ON AV.Id = stgAsset.Id
WHERE AV.OdometerReadingUnit NOT IN('Miles', 'KMs', '_')
AND stgAsset.IsVehicle = 1
AND stgAsset.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT AV.Id
, 'Error'
, ('Asset Class is Invalid in Vehicle Detail for the Asset: ' + stgAsset.Alias) AS Message
FROM stgAssetVehicleDetail AV
INNER JOIN stgAsset ON av.Id = stgAsset.Id
LEFT JOIN AssetClassConfigs ON AssetClassConfigs.AssetClassCode = AV.AssetClass
AND AssetClassConfigs.IsActive = 1
WHERE AV.AssetClass IS NOT NULL
AND AV.AssetClass != ''
AND AssetClassConfigs.Id IS NULL
AND stgAsset.IsVehicle = 1
AND stgAsset.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT AV.Id
, 'Error'
, ('Fuel Type is Invalid in Vehicle Detail for the Asset: ' + stgAsset.Alias) AS Message
FROM stgAssetVehicleDetail AV
INNER JOIN stgAsset ON AV.Id = stgAsset.Id
LEFT JOIN FuelTypeConfigs ON FuelTypeConfigs.FuelTypeCode = AV.FuelType
AND FuelTypeConfigs.IsActive = 1
WHERE AV.FuelType IS NOT NULL
AND AV.FuelType != ''
AND FuelTypeConfigs.Id IS NULL
AND stgAsset.IsVehicle = 1
AND stgAsset.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT AV.Id
, 'Error'
, ('Body Type is Invalid in Vehicle Detail for the Asset: ' + stgAsset.Alias) AS Message
FROM stgAssetVehicleDetail AV
INNER JOIN stgAsset ON AV.Id = stgAsset.Id
LEFT JOIN BodyTypeConfigs ON BodyTypeConfigs.BodyTypeCode = AV.BodyType
AND BodyTypeConfigs.IsActive = 1
WHERE AV.BodyType IS NOT NULL
AND AV.BodyType != ''
AND BodyTypeConfigs.Id IS NULL
AND stgAsset.IsVehicle = 1
AND stgAsset.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT AV.Id
, 'Error'
, ('Original odometer reading should be greater than or equal to zero in Vehicle Detail for the Asset: ' + stgAsset.Alias) AS Message
FROM stgAssetVehicleDetail AV
INNER JOIN stgAsset ON AV.Id = stgAsset.Id
WHERE(AV.OriginalOdometerReading IS NULL
OR AV.OriginalOdometerReading < 0)
AND stgAsset.IsVehicle = 1
AND stgAsset.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT AV.Id
, 'Error'
, ('Number of doors should be greater than or equal to zero in Vehicle Detail for the Asset: ' + stgAsset.Alias) AS Message
FROM stgAssetVehicleDetail AV
INNER JOIN stgAsset ON AV.Id = stgAsset.Id
WHERE(AV.NumberOfDoors IS NULL
OR AV.NumberOfDoors < 0)
AND stgAsset.IsVehicle = 1
AND stgAsset.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT AV.Id
, 'Error'
, ('Number of passengers should be greater than or equal to zero in Vehicle Detail for the Asset: ' + stgAsset.Alias) AS Message
FROM stgAssetVehicleDetail AV
INNER JOIN stgAsset ON AV.Id = stgAsset.Id
WHERE(AV.NumberOfPassengers IS NULL
OR AV.NumberOfPassengers < 0)
AND stgAsset.IsVehicle = 1
AND stgAsset.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT AV.Id
, 'Error'
, ('Number of seats should be greater than or equal to zero in Vehicle Detail for the Asset: ' + stgAsset.Alias) AS Message
FROM stgAssetVehicleDetail AV
INNER JOIN stgAsset ON AV.Id = stgAsset.Id
WHERE(AV.NumberOfSeats IS NULL
OR AV.NumberOfSeats < 0)
AND stgAsset.IsVehicle = 1
AND stgAsset.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT AV.Id
, 'Error'
, ('MPG should be greater than or equal to zero in Vehicle Detail for the Asset: ' + stgAsset.Alias) AS Message
FROM stgAssetVehicleDetail AV
INNER JOIN stgAsset ON AV.Id = stgAsset.Id
WHERE(AV.MPG IS NULL
OR AV.MPG < 0)
AND stgAsset.IsVehicle = 1
AND stgAsset.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT AV.Id
, 'Error'
, ('Number of keys should be greater than or equal to zero in Vehicle Detail for the Asset: ' + stgAsset.Alias) AS Message
FROM stgAssetVehicleDetail AV
INNER JOIN stgAsset ON AV.Id = stgAsset.Id
WHERE(AV.NumberOfKeys IS NULL
OR AV.NumberOfKeys < 0)
AND stgAsset.IsVehicle = 1
AND stgAsset.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT AV.Id
, 'Error'
, ('Number of remotes should be greater than or equal to zero in Vehicle Detail for the Asset: ' + stgAsset.Alias) AS Message
FROM stgAssetVehicleDetail AV
INNER JOIN stgAsset ON AV.Id = stgAsset.Id
WHERE(AV.NumberOfRemotes IS NULL
OR AV.NumberOfRemotes < 0)
AND stgAsset.IsVehicle = 1
AND stgAsset.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT AV.Id
, 'Error'
, ('Engine key code should be greater than or equal to zero in Vehicle Detail for the Asset: ' + stgAsset.Alias) AS Message
FROM stgAssetVehicleDetail AV
INNER JOIN stgAsset ON AV.Id = stgAsset.Id
WHERE(AV.NumberOfRemotes IS NULL
OR AV.NumberOfRemotes < 0)
AND stgAsset.IsVehicle = 1
AND stgAsset.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT AssetId
, 'Error'
, ('No Matching Asset Meter Type Found for the Asset Meter Type : ' + AM.AssetMeterType) AS Message
FROM stgAssetMeter AM
INNER JOIN stgAsset ON AM.AssetId = stgAsset.Id
LEFT JOIN AssetMeterTypes ON AssetMeterTypes.Name = AM.AssetMeterType
AND AssetMeterTypes.IsActive = 1
WHERE AssetMeterTypes.Id IS NULL
AND stgAsset.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT AssetId
, 'Error'
, ('Begin Reading must be greater than or equal to 0 in the Asset Meter Type :' + AM.AssetMeterType) AS Message
FROM stgAssetMeter AM
INNER JOIN stgAsset ON AM.AssetId = stgAsset.Id
WHERE BeginReading < 0
AND stgAsset.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT AssetId
, 'Error'
, ('Maximum Reading must be greater than 0 in the Asset Meter Type :' + AM.AssetMeterType) AS Message
FROM stgAssetMeter AM
INNER JOIN stgAsset ON AM.AssetId = stgAsset.Id
WHERE MaximumReading <= 0
AND stgAsset.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT AssetId
, 'Error'
, ('Maximum Reading must be greater than Begin Reading in the Asset Meter Type : ' + AM.AssetMeterType) AS Message
FROM stgAssetMeter AM
INNER JOIN stgAsset ON AM.AssetId = stgAsset.Id
WHERE MaximumReading < BeginReading
AND stgAsset.IsMigrated = 0;
SET @FailedRecords =
(
SELECT ISNULL(COUNT(DISTINCT StagingRootEntityId), 0)
FROM #ErrorLogs
);
MERGE stgProcessingLog AS ProcessingLog
USING
(
SELECT Id
FROM stgAsset
WHERE IsMigrated = 0
AND Id NOT IN
(
SELECT StagingRootEntityId
FROM #ErrorLogs
)
) AS ProcessedAssets
ON(ProcessingLog.StagingRootEntityId = ProcessedAssets.Id
AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
WHEN MATCHED
THEN UPDATE SET
UpdatedTime = @CreatedTime
WHEN NOT MATCHED
THEN
INSERT(StagingRootEntityId
, CreatedById
, CreatedTime
, ModuleIterationStatusId)
VALUES
(ProcessedAssets.Id
, @UserId
, @CreatedTime
, @ModuleIterationStatusId
)
OUTPUT Inserted.Id
INTO #CreatedProcessingLogs;
INSERT INTO stgProcessingLogDetail
(Message
, Type
, CreatedById
, CreatedTime
, ProcessingLogId
)
SELECT 'Successful'
, 'Information'
, @UserId
, @CreatedTime
, Id
FROM #CreatedProcessingLogs;
MERGE stgProcessingLog AS ProcessingLog
USING
(
SELECT DISTINCT
StagingRootEntityId
FROM #ErrorLogs
) AS ErrorAssets
ON(ProcessingLog.StagingRootEntityId = ErrorAssets.StagingRootEntityId
AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
WHEN MATCHED
THEN UPDATE SET
UpdatedTime = @CreatedTime
, UpdatedById = @UserId
WHEN NOT MATCHED
THEN
INSERT(StagingRootEntityId
, CreatedById
, CreatedTime
, ModuleIterationStatusId)
VALUES
(ErrorAssets.StagingRootEntityId
, @UserId
, @CreatedTime
, @ModuleIterationStatusId
)
OUTPUT Inserted.Id
, ErrorAssets.StagingRootEntityId
INTO #FailedProcessingLogs;
INSERT INTO stgProcessingLogDetail
(Message
, Type
, CreatedById
, CreatedTime
, ProcessingLogId
)
SELECT #ErrorLogs.Message
, 'Error'
, @UserId
, @CreatedTime
, #FailedProcessingLogs.Id
FROM #ErrorLogs
JOIN #FailedProcessingLogs ON #ErrorLogs.StagingRootEntityId = #FailedProcessingLogs.AssetId;
DROP TABLE #ErrorLogs;
DROP TABLE #FailedProcessingLogs;
DROP TABLE #CreatedProcessingLogs;
END;

GO

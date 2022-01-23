SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


Create PROCEDURE [dbo].[CreateAssetsUploadEntries]
(
	 @AssetEntry AssetEntryType READONLY
	,@AssetValueHistory AssetValueHistoryType READONLY
	,@SKUEntry SKUEntryType READONLY
	,@CreatedById BIGINT
	,@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET NOCOUNT ON;

BEGIN TRANSACTION;  
BEGIN TRY  
	
CREATE TABLE #InsertedTaxExemptRuleIds
(
Id BIGINT,
AssetAlias nvarchar (100)
)
MERGE INTO TaxExemptRules
USING @AssetEntry AS AE
ON 1 = 0
WHEN NOT MATCHED THEN
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
,@CreatedById
,@CreatedTime
,(SELECT TOP 1 ID FROM TaxExemptionReasonConfigs WHERE EntityType = 'Asset' AND Reason = 'Dummy'))
Output inserted.Id, AE.Alias INTO #InsertedTaxExemptRuleIds;
CREATE TABLE #TmpAssets(Id BIGINT,Alias nvarchar (100),IsVehicle bit,VendorNumber Nvarchar(50),InvoiceNumber Nvarchar(50))

MERGE INTO Assets
USING(SELECT TOP 500
		 AE.Alias 
		,AE.AcquisitionDate
		,AE.PartNumber
		,AE.UsageCondition 
		,AE.AssetDescription
		,AE.Quantity 
		,AE.IsEligibleForPropertyTax 
		,AE.Status 
		,AE.FinancialType 
		,AE.MoveChildAssets 
		,AE.AssetMode 
		,AE.PropertyTaxCost_Amount 
		,UPPER(AE.PropertyTaxCost_Currency) as PropertyTaxCost_Currency
		,AE.PropertyTaxDate
		,AE.ProspectiveContract
		,UPPER(AE.CurrencyCode) as CurrencyCode
		,case when AE.AssetCatalogId is null then (case when AE.ManufacturerId > 0 then AE.ManufacturerId else null end)  else AssetCatalogs.ManufacturerId end as ManufacturerId
		,AE.TypeId
		,AE.PricingGroupId
		,AE.LegalEntityId 
		,case when AE.CustomerId > 0 then AE.CustomerId else null end as CustomerId
		,case when AE.AssetUsageId > 0 then AE.AssetUsageId else null end as AssetUsageId
		,Assets.Id as AssetId
		,AE.IsTaxExempt 
		,case when AE.ModelYear = 0 then null else AE.ModelYear end as ModelYear
		,AE.CustomerPurchaseOrderNumber
		,AE.InServiceDate
		,AE.PropertyTaxResponsibility
		,AE.GrossVehicleWeight
		,AE.WeightMeasure
		,AE.ElectronicallyDelivered
		,AE.PurchaseOrderDate
		,AE.OwnershipStatus
		,AE.VendorAssetCategoryId
		,AE.RegistrationStateId
		,AE.IsSaleLeaseback
		,AE.SalesTaxExemptionLevelId
		,AE.SubStatus
		,AE.IsManufacturerOverride
		,CASE WHEN AE.Description2 IS NOT NULL THEN AE.Description2 ELSE ProductSubTypes.Name END as [Description2]  
		,CASE WHEN AE.Class1 IS NOT NULL THEN AE.Class1 ELSE Manufacturers.Class1 END as [Class1]
		,CASE WHEN AE.Class3 IS NOT NULL THEN AE.Class3 ELSE dbo.AssetCatalogs.Class3 END as [Class3]
		,AE.ManufacturerOverride
		,AE.AssetCatalogId
		,case when AE.AssetCatalogId is null then (case when AE.ProductId > 0 then AE.ProductId else null end)  else AssetCatalogs.ProductId end as ProductId
		,CASE WHEN AE.AssetClass2Id IS NOT NULL THEN AE.AssetClass2Id ELSE AssetCatalogs.Class2Id END as AssetClass2Id
		,case when AE.AssetCatalogId is null then (case when AE.AssetCategoryId > 0 then AE.AssetCategoryId else null end)  else AssetCatalogs.AssetCategoryId end as AssetCategoryId
		,AE.VendorOrdernumber
		,Tax.Id as TaxId
		,case when AE.AssetCatalogId is null then AE.MakeId else AssetCatalogs.MakeId end as MakeId
		,case when AE.AssetCatalogId is null then AE.ModelId else AssetCatalogs.ModelId end as ModelId
		,case when AE.MaintenanceVendorId > 0 then AE.MaintenanceVendorId else null end as MaintenanceVendorId
		,AE.IsSerializedAsset
		,AE.Residual_Amount
		,UPPER(AE.Residual_Currency) as Residual_Currency
		,AE.IsVehicle
		,AE.InventoryRemarketerId
		,AE.InvoiceNumber
		,AE.VendorNumber
		,AE.IsLeaseComponent
		,AE.ServiceOnly
		,AE.IsSKU		
	FROM @AssetEntry AE 
	LEFT JOIN Assets ON UPPER(AE.ParentAssetAlias) = UPPER(Assets.Alias)
	LEFT JOIN #InsertedTaxExemptRuleIds Tax ON UPPER(AE.Alias) =  UPPER(Tax.AssetAlias)
	LEFT JOIN AssetCatalogs ON AE.AssetCatalogId = AssetCatalogs.Id 
	LEFT JOIN Manufacturers ON Manufacturers.Id = AssetCatalogs.ManufacturerId
	LEFT JOIN ProductSubTypes ON ProductSubTypes.Id = AssetCatalogs.ProductSubTypeId ORDER BY AE.RowNumber ASC )
	as AssetToInsert
ON 1=0
WHEN NOT MATCHED THEN
INSERT
	(
		 Alias 
		,AcquisitionDate
		,PartNumber
		,UsageCondition
		,Description
		,Quantity 
		,IsEligibleForPropertyTax 
		,Status 
		,FinancialType 
		,MoveChildAssets 
		,AssetMode 
		,PropertyTaxCost_Amount 
		,PropertyTaxCost_Currency 
		,PropertyTaxDate
		,ProspectiveContract
		,CurrencyCode
		,ManufacturerId
		,TypeId 
		,PricingGroupId
		,LegalEntityId 
		,CustomerId
		,AssetUsageId 
		,ParentAssetId
		,IsTaxExempt 
		,ModelYear
		,CustomerPurchaseOrderNumber
		,InServiceDate
		,CreatedTime
		,CreatedById
		,PropertyTaxResponsibility
		,GrossVehicleWeight
		,WeightMeasure
		,IsElectronicallyDelivered
		,PurchaseOrderDate
		,OwnershipStatus
		,VendorAssetCategoryId
		,StateId
		,IsParent
		,IsOffLease
		,IsSaleLeaseback
		,IsSystemCreated
		,IsTakedownAsset
		,IsOnCommencedLease
		,SalesTaxExemptionLevelId
		,SubStatus
		,DealerCost_Amount
		,DealerCost_Currency
		,DMDPercentage
		,[IsManufacturerOverride]
		,[Description2] 
		,[Class1]
		,[Class3] 
		,[ManufacturerOverride]
		,[AssetCatalogId] 
		,[ProductId]
		,[AssetClass2Id] 
		,[AssetCategoryId] 
		,VendorOrderNumber
		,TaxExemptRuleId
		,IsReversed
		,MakeId
		,ModelId
		,MaintenanceVendorId
		,IsSerializedAsset
		,Residual_Amount
		,Residual_Currency
		,IsVehicle
		,InventoryRemarketerId
		,IsLeaseComponent
		,IsServiceOnly
		,IsSKU
		,IsTaxParameterChangedForLeasedAsset
		,Salvage_Amount
		,Salvage_Currency
	)
	Values
	(
		 AssetToInsert.Alias 
		,AssetToInsert.AcquisitionDate
		,AssetToInsert.PartNumber
		,AssetToInsert.UsageCondition 
		,AssetToInsert.AssetDescription
		,AssetToInsert.Quantity 
		,AssetToInsert.IsEligibleForPropertyTax 
		,AssetToInsert.Status 
		,AssetToInsert.FinancialType 
		,AssetToInsert.MoveChildAssets 
		,AssetToInsert.AssetMode 
		,AssetToInsert.PropertyTaxCost_Amount 
		,AssetToInsert.PropertyTaxCost_Currency
		,AssetToInsert.PropertyTaxDate
		,AssetToInsert.ProspectiveContract
		,AssetToInsert.CurrencyCode
  ,AssetToInsert.ManufacturerId   
		,AssetToInsert.TypeId 
		,AssetToInsert.PricingGroupId
		,AssetToInsert.LegalEntityId 
		,AssetToInsert.CustomerId 
		,AssetToInsert.AssetUsageId 
		,AssetToInsert.AssetId
		,AssetToInsert.IsTaxExempt 
		,AssetToInsert.ModelYear
		,AssetToInsert.CustomerPurchaseOrderNumber
		,AssetToInsert.InServiceDate
		,@CreatedTime
		,@CreatedById
		,AssetToInsert.PropertyTaxResponsibility
		,AssetToInsert.GrossVehicleWeight
		,AssetToInsert.WeightMeasure
		,AssetToInsert.ElectronicallyDelivered
		,AssetToInsert.PurchaseOrderDate
		,AssetToInsert.OwnershipStatus
		,AssetToInsert.VendorAssetCategoryId
		,AssetToInsert.RegistrationStateId
		,0
		,0
		,AssetToInsert.IsSaleLeaseback
		,0
		,0
		,0
		,AssetToInsert.SalesTaxExemptionLevelId
		,AssetToInsert.SubStatus
		,0
		,AssetToInsert.PropertyTaxCost_Currency
		,0
		,AssetToInsert.IsManufacturerOverride
		,AssetToInsert.Description2
		,AssetToInsert.Class1
		,AssetToInsert.Class3 
		,AssetToInsert.ManufacturerOverride
		,AssetToInsert.AssetCatalogId
  ,AssetToInsert.ProductId  
		,AssetToInsert.AssetClass2Id
  ,AssetToInsert.AssetCategoryId   
		,AssetToInsert.VendorOrdernumber
		,AssetToInsert.TaxId
		,0 -- IsReversed
  ,AssetToInsert.MakeId  
  ,AssetToInsert.ModelId   
		,AssetToInsert.MaintenanceVendorId 
		,AssetToInsert.IsSerializedAsset
		,AssetToInsert.Residual_Amount
		,AssetToInsert.Residual_Currency
		,AssetToInsert.IsVehicle
		,AssetToInsert.InventoryRemarketerId
		,AssetToInsert.IsLeaseComponent
		,AssetToInsert.ServiceOnly
		,AssetToInsert.IsSKU
		,0
		,0
		,AssetToInsert.Residual_Currency
	)
	OUTPUT Inserted.Id,Inserted.Alias,Inserted.IsVehicle,AssetToInsert.VendorNumber,AssetToInsert.InvoiceNumber INTO #TmpAssets;
	
	Insert into VehicleDetails
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
	)
	Select Id,
	AssetClassId ,
	VehicleType ,
	TransmissionType,
	TankCapacity,
	InteriorColor,
	NumberOfCylinders,
	PayloadCapacity ,
	FuelTypeId ,
	EngineSize,
	DriveTrainId ,
	WeightClass,
	CO2 ,
	ContractMileage,
	BodyDescription ,
	OriginalOdometerReading ,
	OdometerReadingUnit,
	NumberOfDoors ,
	BodyTypeId ,
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
	TitleStateId  ,
	TitleBorrowedReason ,
	TitleBorrowedDate,
	TitleLienHolder,
	TitleApplicationSubmissionDate ,
	TitleReceivedDate,
	TitleCodeId  ,
	@CreatedById,
    @CreatedTime
	from  @AssetEntry AE 
	join #tmpAssets tmp on AE.Alias =tmp.Alias
	where AE.IsVehicle=1
	
	INSERT INTO AssetSKUs
	(
	  Name,
	  Alias,
	  Description,
	  CreatedById,
	  CreatedTime,
      SerialNumber,
      IsLeaseComponent,
      Quantity,
      IsActive,
      ManufacturerId,
      MakeId,
      ModelId,
      TypeId,
	  PricingGroupId,
      AssetCatalogId,
      AssetCategoryId,
      ProductId,
      AssetId,
	  IsSalesTaxExempt
	)
	SELECT
	  Name,
	  SE.Alias,
	  SE.Description,
	  @CreatedById,
	  @CreatedTime,
      SE.SerialNumber,
      SE.IsLeaseComponent,
      SE.Quantity,
      1,
      SE.ManufacturerId,
      SE.MakeId,
      SE.ModelId,
      SE.TypeId,
	  SE.PricingGroupId,
      SE.AssetCatalogId,
      SE.AssetCategoryId,
      SE.ProductId,
      A.Id,
	  SE.IsSalesTaxExempt
    FROM @SKUEntry SE
	INNER JOIN Assets AS A ON A.Alias = SE.AssetAlias
	WHERE A.IsSKU = 1
	;

	INSERT INTO AssetGLDetails
	(
		Id
	   ,AssetBookValueAdjustmentGLTemplateId
	   ,BookDepreciationGLTemplateId
	   ,HoldingStatus
	   ,CreatedById
	   ,CreatedTime
	)
	SELECT A.Id
		  ,AE.AssetBookValueAdjustmentGLTemplateId
		  ,AE.AssetBookDepreceiationGLTemplateId
		  ,'HFI'
		  ,@CreatedById
		  ,@CreatedTime
	FROM @AssetEntry AE
	INNER JOIN Assets AS A ON UPPER(A.Alias) = UPPER(AE.Alias)
	;

	INSERT INTO AssetLocations
	(
		 EffectiveFromDate
		,IsCurrent
		,TaxBasisType
		,UpfrontTaxMode
		,IsActive
		,CreatedTime
		,LocationId
		,AssetId
		,CreatedById
		,IsFLStampTaxExempt
		,ReciprocityAmount_Amount
		,ReciprocityAmount_Currency
		,LienCredit_Amount
		,LienCredit_Currency
		,UpfrontTaxAssessedInLegacySystem
	)
	SELECT 
		 AE.EffectiveFromDate
		,1
		,AE.TaxBasisType
		,AE.UpfrontTaxMode
		,1
		,@CreatedTime
		,ISNULL(locWithCustomer.Id,locWithoutCustomer.Id)
		,A.Id
		,@CreatedById
		,AE.IsFLStampTaxExempt
		,0.0
		,UPPER(AE.PropertyTaxCost_Currency)
		,0.0
		,UPPER(AE.PropertyTaxCost_Currency)
		,CAST(0 AS BIT)

	FROM @AssetEntry AE
	INNER JOIN Assets AS A ON UPPER(A.Alias) = UPPER(AE.Alias)
	LEFT JOIN Locations AS locWithCustomer ON UPPER(AE.LocationAlias) = UPPER(locWithCustomer.Code) AND locWithCustomer.CustomerId = A.CustomerId
	LEFT JOIN locations AS locWithoutCustomer ON UPPER(AE.LocationAlias) = UPPER(locWithoutCustomer.Code) AND locWithoutCustomer.CustomerId IS NULL

	WHERE AE.LocationAlias IS NOT NULL
	;

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
		,CustomerId
		,ParentAssetId
		,LegalEntityId
		,AssetId
		,CreatedById
		,IsReversed
		,PropertyTaxReportCodeId
	)
	Select 
		'New'
		,AsOfDate
		,AE.AcquisitionDate
		,AE.Status
		,AE.FinancialType
		,AE.HistorySourceModule
		,A.Id
		,@CreatedTime
		,case when AE.CustomerId > 0 then AE.CustomerId else null end
		,A.ParentAssetId
		,AE.LegalEntityId
		,A.Id
		,@CreatedById
		,0
		,A.PropertyTaxReportCodeId
	FROM @AssetEntry AE
	INNER JOIN Assets AS A ON UPPER(A.Alias) = UPPER(AE.Alias)

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
		,CreatedById
		,CreatedTime
		,UpdatedById
		,UpdatedTime
		,AssetId
		,GLJournalId
		,ReversalGLJournalId
		,AdjustmentEntry
		,IsLessorOwned
		,IsLeaseComponent
	)
	SELECT
		 AVH.ValueHistorySourceModule
		,A.Id
		,NULL
		,NULL
		,AVH.IncomeDate
		,AVH.AssetValue_Amount
		,UPPER(AVH.AssetValue_Currency)
		,AVH.AssetValue_Amount
		,UPPER(AVH.AssetValue_Currency)
		,AVH.AssetValue_Amount
		,UPPER(AVH.AssetValue_Currency)
		,AVH.AssetValue_Amount
		,UPPER(AVH.AssetValue_Currency)
		,AVH.AssetValue_Amount
		,UPPER(AVH.AssetValue_Currency)
		,1
		,1
		,1
		,NULL
		,NULL
		,@CreatedById
		,@CreatedTime
		,NULL
		,NULL
		,A.Id
		,NULL
		,NULL
		,0
		,1
		,A.IsLeaseComponent

	FROM @AssetValueHistory AVH
	INNER JOIN Assets AS A ON UPPER(A.Alias) = UPPER(AVH.Alias)
	;

	UPDATE Assets
	SET IsParent = 1
	   ,UpdatedById = @CreatedById
	   ,UpdatedTime = @CreatedTime
	WHERE IsParent = 0
	  AND UPPER(Alias) IN (SELECT UPPER(ParentAssetAlias) FROM @AssetEntry WHERE ParentAssetAlias IS NOT NULL AND ParentAssetAlias != '')
	;

	INSERT INTO CollateralTrackings
	(
		 EntityType
		,EntityId
		,Title
		,CompletingTitleWork
		,CollateralPosition
		,IsCollateralConfirmation
		,CollateralType
		,IsCrossCollateralized
		,CreatedById
		,CreatedTime
		,AssetId
		,CollateralTitleReleaseStatus           
		,CollateralStatus
		,IsActive
	)
	SELECT
		'_'
		,NULL
		,'_'
		,'_'
		,'_'
		,0
		,'_'
		,0
		,@CreatedById
		,@CreatedTime
		,A.Id
		,AE.CollateralTitleReleaseStatus
		,AE.CollateralStatus
		,1

	FROM @AssetEntry AE
	INNER JOIN Assets A ON UPPER(AE.Alias) = UPPER(A.Alias)

	WHERE AE.IsCollateralTracking = 1
	;
	COMMIT TRANSACTION; 
		Select Id,Alias,InvoiceNumber,VendorNumber from #TmpAssets WHERE InvoiceNumber!='' And VendorNumber!=''
		Select ASKU.Id,ASKU.Alias as SKUAlias,TT.Alias as AssetAlias from AssetSKUs ASKU
		INNER JOIN #TmpAssets TT on ASKU.AssetId = TT.Id
		Select TT.Id,AH.Id AS AssetHistoryId,TT.Alias from #TmpAssets TT
		LEFT JOIN AssetHistories AH on AH.AssetId = TT.Id
END TRY  

BEGIN CATCH  

    IF @@TRANCOUNT > 0
		SELECT ERROR_MESSAGE() info,ERROR_LINE() linenumber

    ROLLBACK TRANSACTION;  

END CATCH;  

  
END

GO

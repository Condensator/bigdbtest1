SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CreateAssetsForPlaceholderAssets]
(
@PlaceholderAssetInfo PlaceholderAssetInfo READONLY,
@PayoffId BIGINT,
@PayoffEffectiveDate DATETIME,
@ContractId BIGINT,
@SourceModule NVARCHAR(40),
@AssetHistoryReason NVARCHAR(40),
@AssetStatusInventory NVARCHAR(40),
@AssetStatusLeased NVARCHAR(40),
@UserId BIGINT,
@Currency NVARCHAR(3),
@FinancialTypeNegativeReturn NVARCHAR(40),
@FinancialTypePlaceholder NVARCHAR(40),
@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;

       CREATE TABLE #NewAssetInfo
       (
              OldAssetId BIGINT,
              NewAssetId BIGINT,
              Status NVARCHAR(40),
              IsLeaseComponent BIT
       )
       
       MERGE Assets Asset
       USING (SELECT * FROM Assets JOIN @PlaceholderAssetInfo PlaceholderInfo ON Assets.Id = PlaceholderInfo.AssetId) AS AssetInfo ON 1 != 1
       WHEN NOT MATCHED THEN
       INSERT (Alias
                      ,AcquisitionDate
                      ,PartNumber
                      ,UsageCondition
                      ,Description
                      ,Quantity
                      ,InServiceDate
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
                      ,IsTaxExempt
                      ,ModelYear
                      ,CustomerPurchaseOrderNumber
                      ,OwnershipStatus
                      ,PropertyTaxResponsibility
                      ,PurchaseOrderDate
                      ,GrossVehicleWeight
                      ,WeightMeasure
                      ,IsOffLease
                      ,IsElectronicallyDelivered
                      ,IsSaleLeaseback
                      ,IsParent
                      ,IsOnCommencedLease
                      ,IsTakedownAsset
                      ,IsSystemCreated
                      ,PreviousSequenceNumber
                      ,SubStatus
                      ,CreatedById
                      ,CreatedTime
                      ,ManufacturerId
                      ,TypeId
                      ,LegalEntityId
                      ,CustomerId
                      ,ParentAssetId
                      ,FeatureSetId
                      ,ClearAccumulatedGLTemplateId
                      ,TitleTransferCodeId
                      ,AssetUsageId
                      ,PropertyTaxReportCodeId
                      ,StateId
                      ,VendorAssetCategoryId
                      ,SaleLeasebackCodeId
                      ,RemarketingVendorId
                      ,PlaceholderAssetId
                      ,SalesTaxExemptionLevelId
                      ,DealerCost_Amount
                      ,DealerCost_Currency
                      ,DMDPercentage
                      ,CustomerAssetNumber
                      ,VendorOrderNumber
                      ,AssetCatalogId
                      ,ProductId
                      ,AssetClass2Id
                      ,IsManufacturerOverride
                      ,AssetCategoryId
                      ,Class1
                      ,Class3
                      ,Description2
                      ,ManufacturerOverride
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
                      ,SpecifiedLeasingProperty
                      ,IsLeaseComponent
                      ,IsServiceOnly
                      ,IsSKU
                      ,IsTaxParameterChangedForLeasedAsset
                      ,Salvage_Amount
                      ,Salvage_Currency)
       VALUES (CASE WHEN IsNegativeReturn = 1 THEN 'Negative Return for ' + Alias ELSE 'Placeholder for ' + Alias + '-' + PlaceHolderAssetCount END
                      ,AcquisitionDate
                      ,PartNumber
                      ,UsageCondition
                      ,Description
                      ,Quantity
                      ,InServiceDate
                      ,CASE WHEN IsNegativeReturn = 1 THEN IsEligibleForPropertyTax ELSE 0 END
                      ,CASE WHEN IsNegativeReturn = 1 THEN @AssetStatusInventory ELSE @AssetStatusLeased END
                      ,CASE WHEN IsNegativeReturn = 1 THEN @FinancialTypeNegativeReturn ELSE @FinancialTypePlaceholder END
                      ,MoveChildAssets
                      ,AssetMode
                      ,CASE WHEN IsNegativeReturn = 1 THEN PropertyTaxCost_Amount ELSE 0.0 END 
                      ,PropertyTaxCost_Currency
                      ,CASE WHEN IsNegativeReturn = 1 THEN PropertyTaxDate ELSE NULL END 
                      ,ProspectiveContract
                      ,CurrencyCode
                      ,IsTaxExempt
                      ,ModelYear
                      ,CustomerPurchaseOrderNumber
                      ,OwnershipStatus
                      ,PropertyTaxResponsibility
                      ,PurchaseOrderDate
                      ,GrossVehicleWeight
                      ,WeightMeasure
                      ,CASE WHEN IsNegativeReturn = 1 THEN 1 ELSE 0 END
                      ,IsElectronicallyDelivered
                      ,IsSaleLeaseback
                      ,IsParent
                      ,CASE WHEN IsNegativeReturn = 0 THEN 1 ELSE 1 END
                      ,IsTakedownAsset
                      ,IsSystemCreated
                      ,PreviousSequenceNumber
                      ,SubStatus
                      ,@UserId
                      ,@CreatedTime
                      ,ManufacturerId
                      ,TypeId
                      ,LegalEntityId
                      ,CustomerId
                      ,ParentAssetId
                      ,FeatureSetId
                      ,ClearAccumulatedGLTemplateId
                      ,TitleTransferCodeId
                      ,AssetUsageId
                      ,PropertyTaxReportCodeId
                      ,StateId
                      ,VendorAssetCategoryId
                      ,SaleLeasebackCodeId
                      ,RemarketingVendorId
                      ,PlaceholderAssetId
                      ,SalesTaxExemptionLevelId
                      ,DealerCost_Amount
                      ,DealerCost_Currency
                      ,DMDPercentage
                      ,CustomerAssetNumber
                      ,VendorOrderNumber
                      ,AssetCatalogId
                      ,ProductId
                      ,AssetClass2Id
                      ,IsManufacturerOverride
                      ,AssetCategoryId
                      ,Class1
                      ,Class3
                      ,Description2
                      ,ManufacturerOverride
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
                      ,SpecifiedLeasingProperty
                      ,IsLeaseAsset
                      ,0
                      ,IsSKU
                      ,0
                      ,Salvage_Amount
                      ,Salvage_Currency)
       OUTPUT AssetInfo.AssetId OldAssetId, Inserted.Id NewAssetId, Inserted.Status,Inserted.IsLeaseComponent  INTO #NewAssetInfo;

       MERGE AssetSKUs AssetSKU
       USING (SELECT AssetSKUs.*,AssetInfo.NewAssetId FROM AssetSKUs JOIN #NewAssetInfo AssetInfo ON AssetSKUs.AssetId = AssetInfo.OldAssetId WHERE AssetSKUs.IsActive = 1) AS AssetSKUInfo ON 1 != 1
       WHEN NOT MATCHED THEN
       INSERT(Alias
              ,Name
                 ,SerialNumber
                 ,Description
                 ,IsLeaseComponent
                 ,Quantity
                 ,IsActive
                 ,CreatedById
                 ,CreatedTime
                 ,IsSalesTaxExempt
                 ,ManufacturerId
                 ,MakeId
                 ,ModelId
                 ,TypeId
                 ,AssetCatalogId
                 ,AssetCategoryId
                 ,ProductId
                 ,AssetId
             )
       VALUES(
               Alias 
                      ,Name
                 ,SerialNumber
                 ,Description
                 ,IsLeaseComponent
                 ,Quantity
                 ,IsActive
                 ,@UserId
                 ,@CreatedTime
                 ,IsSalesTaxExempt
                 ,ManufacturerId
                 ,MakeId
                 ,ModelId
                 ,TypeId
                 ,AssetCatalogId
                 ,AssetCategoryId
                 ,ProductId
                 ,NewAssetId
             );

       MERGE AssetLocations AssetLocation
       USING (SELECT * FROM AssetLocations JOIN #NewAssetInfo AssetInfo ON AssetLocations.AssetId = AssetInfo.OldAssetId WHERE AssetLocations.IsActive = 1) AS AssetLocationInfo ON 1 != 1
       WHEN NOT MATCHED THEN
       INSERT (EffectiveFromDate
                      ,IsCurrent
                      ,UpfrontTaxMode
                      ,TaxBasisType
                      ,IsActive
                      ,CreatedById
                      ,CreatedTime
                      ,LocationId
                      ,AssetId
                      ,IsFLStampTaxExempt
                      ,ReciprocityAmount_Amount
                      ,ReciprocityAmount_Currency
                      ,LienCredit_Amount
                      ,LienCredit_Currency
                      ,UpfrontTaxAssessedInLegacySystem)
       VALUES (EffectiveFromDate
                      ,IsCurrent
                      ,UpfrontTaxMode
                      ,TaxBasisType
                      ,IsActive
                      ,@UserId
                      ,@CreatedTime
                      ,LocationId
                      ,NewAssetId
                      ,IsFLStampTaxExempt
                      ,ReciprocityAmount_Amount
                      ,ReciprocityAmount_Currency
                      ,LienCredit_Amount
                      ,LienCredit_Currency
                      ,CAST(0 AS BIT));

       MERGE AssetMeters AssetMeter
       USING (SELECT * FROM AssetMeters JOIN #NewAssetInfo AssetInfo ON AssetMeters.AssetId = AssetInfo.OldAssetId WHERE AssetMeters.IsActive = 1) AS AssetMeterInfo ON 1 != 1
       WHEN NOT MATCHED THEN
       INSERT (BeginReading
                      ,MaximumReading
                      ,IsActive
                      ,CreatedById
                      ,CreatedTime
                      ,AssetMeterTypeId
                      ,AssetId)
       VALUES  (BeginReading
                      ,MaximumReading
                      ,IsActive
                      ,@UserId
                      ,@CreatedTime
                      ,AssetMeterTypeId
                      ,NewAssetId);

       MERGE AssetFeatures AssetFeature
       USING (SELECT * FROM AssetFeatures JOIN #NewAssetInfo AssetInfo ON AssetFeatures.AssetId = AssetInfo.OldAssetId WHERE AssetFeatures.IsActive = 1) AS AssetFeatureInfo ON 1 != 1
       WHEN NOT MATCHED THEN
       INSERT (Alias                     
                      ,Description
                      ,IsActive
                      ,Quantity
                      ,CreatedById
                      ,CreatedTime
                      ,ManufacturerId
                      ,TypeId
                      ,AssetId
                      ,StateId
                      ,AssetCatalogID
                      ,AssetCategoryID
                      ,ProductID
                      ,MakeId
                      ,ModelId)
       VALUES  (Alias                      
                      ,Description
                      ,IsActive
                      ,Quantity
                      ,@UserId
                      ,@CreatedTime
                      ,ManufacturerId
                      ,TypeId
                      ,NewAssetId
                      ,StateId
                      ,AssetCatalogID
                      ,AssetCategoryID
                      ,ProductID
                      ,MakeId
                      ,ModelId);

       MERGE VehicleDetails VehicleDetail
       USING (SELECT * FROM VehicleDetails JOIN #NewAssetInfo AssetInfo ON VehicleDetails.Id = AssetInfo.OldAssetId) AS VehicleDetailInfo ON 1 != 1
       WHEN NOT MATCHED THEN
       INSERT (Id
                      ,VehicleType
                      ,TransmissionType
                      ,TankCapacity
                      ,InteriorColor
                      ,NumberOfCylinders
                      ,PayloadCapacity
                      ,EngineSize
                      ,WeightClass
                      ,CO2
                      ,ContractMileage
                      ,BodyDescription
                      ,OriginalOdometerReading
                      ,OdometerReadingUnit
                      ,NumberOfDoors
                      ,NumberOfPassengers
                      ,NumberOfSeats
                      ,KeylessEntry
                      ,MPG
                      ,NumberOfKeys
                      ,DoorKeyCode
                      ,NumberOfRemotes
                      ,TireSize
                      ,EngineKeyCode
                      ,ExteriorColor
                      ,WeightUnit
                      ,GVW
                      ,GrossCurbCombinedWeight
                      ,VehicleRegisteredWeight
                      ,VehicleCurbWeight
                      ,Titled
                      ,TitleTrustOverride
                      ,TitleBorrowedReason
                      ,TitleBorrowedDate
                      ,TitleLienHolder
                      ,TitleApplicationSubmissionDate
                      ,TitleReceivedDate
                      ,CreatedById
                      ,CreatedTime
                      ,AssetClassConfigId
                      ,FuelTypeConfigId
                      ,DriveTrainConfigId
                      ,BodyTypeConfigId
                      ,TitleStateId
                      ,TitleCodeConfigId)
       VALUES  (NewAssetId
                      ,VehicleType
                      ,TransmissionType
                      ,TankCapacity
                      ,InteriorColor
                      ,NumberOfCylinders
                      ,PayloadCapacity
                      ,EngineSize
                      ,WeightClass
                      ,CO2
                      ,ContractMileage
                      ,BodyDescription
                      ,OriginalOdometerReading
                      ,OdometerReadingUnit
                      ,NumberOfDoors
                      ,NumberOfPassengers
                      ,NumberOfSeats
                      ,KeylessEntry
                      ,MPG
                      ,NumberOfKeys
                      ,DoorKeyCode
                      ,NumberOfRemotes
                      ,TireSize
                      ,EngineKeyCode
                      ,ExteriorColor
                      ,WeightUnit
                      ,GVW
                      ,GrossCurbCombinedWeight
                      ,VehicleRegisteredWeight
                      ,VehicleCurbWeight
                      ,Titled
                      ,TitleTrustOverride
                      ,TitleBorrowedReason
                      ,TitleBorrowedDate
                      ,TitleLienHolder
                      ,TitleApplicationSubmissionDate
                      ,TitleReceivedDate
                      ,@UserId
                      ,@CreatedTime
                      ,AssetClassConfigId
                      ,FuelTypeConfigId
                      ,DriveTrainConfigId
                      ,BodyTypeConfigId
                      ,TitleStateId
                      ,TitleCodeConfigId);

       MERGE AssetMaintenances AssetMaintenance
	USING (SELECT * FROM AssetMaintenances JOIN #NewAssetInfo AssetInfo ON AssetMaintenances.AssetId = AssetInfo.OldAssetId) AS AssetMaintenanceInfo ON 1 != 1
	WHEN NOT MATCHED THEN
	INSERT (EffectiveFromDate
			,LocationId
			,AssetId
			,CreatedTime
			,EffectiveTillDate
			,IsCurrent
			,CreatedById)
	VALUES	(EffectiveFromDate
			,LocationId
			,NewAssetId
			,@CreatedTime
			,EffectiveTillDate
			,IsCurrent
			,@UserId);

	MERGE AssetGLDetails AssetGLDetail
	USING (SELECT * FROM AssetGLDetails JOIN #NewAssetInfo AssetInfo ON AssetGLDetails.Id = AssetInfo.OldAssetId) AS AssetGLDetailInfo ON 1 != 1
	WHEN NOT MATCHED THEN
	INSERT	(Id
			,HoldingStatus
			,CreatedById
			,CreatedTime
			,AssetBookValueAdjustmentGLTemplateId
			,BookDepreciationGLTemplateId
			,InstrumentTypeId
			,LineofBusinessId
			,OriginalInstrumentTypeId
			,OriginalLineofBusinessId
			,CostCenterId)
	VALUES	(NewAssetId
			,HoldingStatus
			,@UserId
			,@CreatedTime
			,AssetBookValueAdjustmentGLTemplateId
			,BookDepreciationGLTemplateId
			,InstrumentTypeId
			,LineofBusinessId
			,OriginalInstrumentTypeId
			,OriginalLineofBusinessId
			,CostCenterId);

	INSERT INTO AssetValueHistories
		(SourceModule
		,SourceModuleId
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
		,CreatedById
		,CreatedTime
		,AssetId
		,AdjustmentEntry
		,IsLessorOwned
		,IsLeaseComponent)
	SELECT
		@SourceModule
		,@PayoffId
		,@PayoffEffectiveDate
		,NBV
		,@Currency
		,NBV
		,@Currency
		,NBV
		,@Currency
		,NBV
		,@Currency
		,NBV
		,@Currency
		,1
		,1
		,1
		,@UserId
		,@CreatedTime
		,AssetInfo.NewAssetId
		,0
		,1
		,AssetInfo.IsLeaseComponent
	FROM @PlaceholderAssetInfo PlaceholderInfo
	JOIN #NewAssetInfo AssetInfo ON PlaceholderInfo.AssetId = AssetInfo.OldAssetId

	INSERT INTO AssetHistories
		(Reason
		,AsOfDate
		,AcquisitionDate
		,Status
		,FinancialType
		,SourceModule
		,SourceModuleId
		,CreatedById
		,CreatedTime
		,CustomerId
		,ParentAssetId
		,LegalEntityId
		,AssetId
		,ContractId
		,PropertyTaxReportCodeId
		,IsReversed)
	SELECT
		@AssetHistoryReason
		,@PayoffEffectiveDate
		,Assets.AcquisitionDate
		,Assets.Status
		,Assets.FinancialType
		,@SourceModule
		,@PayoffId
		,@UserId
		,@CreatedTime
		,Assets.CustomerId
		,Assets.ParentAssetId
		,Assets.LegalEntityId
		,Assets.Id
		,CASE WHEN AssetInfo.Status = @AssetStatusInventory THEN NULL ELSE @ContractId END
		,Assets.PropertyTaxReportCodeId
		,0
	FROM Assets
	JOIN #NewAssetInfo AssetInfo ON Assets.Id = AssetInfo.NewAssetId

SELECT OldAssetId,NewAssetId FROM #NewAssetInfo
SET NOCOUNT OFF;
END

GO

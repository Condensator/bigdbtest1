SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
 
  
CREATE PROCEDURE [dbo].[CreateSoftAssetsForAdditionalCharge] 
(  
 @ContractId BIGINT,  
 @LeaseFinanceId BIGINT,  
 @SequenceNumber NVARCHAR(30),  
 @CommencementDate DATETIME,  
 @AssetStatusLeased NVARCHAR(20),  
 @AssetFinancialType NVARCHAR(20),  
 @AssetMode NVARCHAR(50),        
 @CreatedById BIGINT,  
 @CreatedTime DATETIMEOFFSET
)  
AS  
BEGIN  
SET NOCOUNT ON  
   
 CREATE TABLE #AssetDetails  
 (  
  Id BIGINT NOT NULL IDENTITY(1,1) PRIMARY KEY,  
  RowNumber BIGINT, 
  SoftAssetId BIGINT,   
  SoftLeaseAssetId BIGINT,   
  IsSoftLeaseAssetActive BIT,     
  AssetStatus NVARCHAR(25),  
  AssetFinancialType NVARCHAR(25),   
  AssetLegalEntityId BIGINT,  
  AssetCustomerId BIGINT,   
  AssetCurrencyCode NVARCHAR(6),  
  AssetTypeId BIGINT,    
  PropertyTaxCostCurrency NVARCHAR(3),  
  UsageCondition NVARCHAR(15),    
  IsManufacturerOverride BIT,     
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
  ,Asset.Id  
  ,SoftLeaseAsset.Id   
  ,SoftLeaseAsset.IsActive  
  ,Asset.Status  
  ,'Real' AS AssetFinancialType 
  ,LeaseFinance.LegalEntityId  
  ,LeaseFinance.CustomerId  
  ,additionalCharge.Amount_Currency  
  ,additionalCharge.AssetTypeId   
  ,additionalCharge.Amount_Currency 
  ,'New' AS UsageCondition
  ,Asset.IsManufacturerOverride     
  ,SoftLeaseAsset.IsLeaseAsset
 FROM LeaseFinances LeaseFinance  
 INNER JOIN LeaseAssets SoftLeaseAsset ON LeaseFinance.Id = SoftLeaseAsset.LeaseFinanceId
 INNER JOIN LeaseFinanceAdditionalCharges LACs ON  LACs.LeaseAssetId = SoftLeaseAsset.Id
 INNER JOIN AdditionalCharges additionalCharge ON LACs.AdditionalChargeId = additionalCharge.Id  
 LEFT JOIN Assets Asset ON SoftLeaseAsset.AssetId = Asset.Id   
 WHERE LeaseFinance.Id = @LeaseFinanceId and additionalCharge.IsActive=1 and additionalCharge.CreateSoftAsset=1 and SoftLeaseAsset.IsAdditionalChargeSoftAsset=1 
  
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
	JOIN LeaseFinanceAdditionalCharges on LeaseFinanceAdditionalCharges.LeaseAssetId=LeaseAssets.Id  
    WHERE Contracts.Id = @ContractId AND LeaseFinanceAdditionalCharges.LeaseAssetId IS NOT NULL  
   
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
  ,[PartNumber] = null   
  ,[UsageCondition] = AssetDetail.UsageCondition  
  ,[Description] = Assets.Description  
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
  ,[CurrencyCode] = AssetDetail.AssetCurrencyCode  
  ,[IsTaxExempt] = 0  
  ,[UpdatedById] = @CreatedById  
  ,[UpdatedTime] = @CreatedTime  
  --,[ManufacturerId] = AssetDetail.CapitalizedForAssetManufacturerId  
  ,[TypeId] = AssetDetail.AssetTypeId  
  ,[LegalEntityId] = AssetDetail.AssetLegalEntityId  
  ,[CustomerId] = AssetDetail.AssetCustomerId  
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
  ('Soft Asset ' +' - '+ @SequenceNumber + ' - '+ CAST(AssetDetail.RowNumber AS NVARCHAR(MAX))  
  ,@CommencementDate  
  ,null  
  ,AssetDetail.UsageCondition  
  ,'Soft Asset ' +' - '+ @SequenceNumber + ' - '+ CAST(AssetDetail.RowNumber AS NVARCHAR(MAX))  
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
  ,AssetDetail.AssetCurrencyCode  
  ,0  
  ,@CreatedById  
  ,@CreatedTime  
  --,AssetDetail.CapitalizedForAssetManufacturerId  
  ,AssetDetail.AssetTypeId  
  ,AssetDetail.AssetLegalEntityId  
  ,AssetDetail.AssetCustomerId  
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
  
        ,null 
        ,null 
        ,null
        ,null
        ,null
        ,null  
        ,null
        ,null
        ,null
     ,AssetDetail.TaxId  
        ,0  
        ,0  
        ,0  
        ,AssetDetail.AssetCurrencyCode  
        ,0  
  ,AssetDetail.IsLeaseComponent  
  ,0
  ,0
  ,0
  ,0
  ,AssetDetail.PropertyTaxCostCurrency)  
  
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
	 
	 MERGE INTO AssetLocations
	 USING (SELECT @CommencementDate AS EffectiveFromDate,1 as IsCurrent,loc.UpfrontTaxMode,loc.TaxBasisType,0 as IsFLStampTaxExempt,0.0 AS ReciprocityAmount_Amount,additionalCharge.Amount_Currency AS ReciprocityAmount_Currency,0.0 AS LienCredit_Amount,Amount_Currency AS LienCredit_Currency, 1 AS IsActive, additionalCharge.AssetLocationId as LocationId, cad.AssetId as AssetId  
		FROM LeaseFinanceAdditionalCharges LACs 
		JOIN AdditionalCharges additionalCharge ON LACs.AdditionalChargeId= additionalCharge.Id 
		JOIN LeaseAssets leaseAsset on leaseAsset.id=LACs.LeaseAssetId
		JOIN #CreatedAssetDetails cad on cad.LeaseAssetId = leaseAsset.id
		JOIN locations loc on loc.id=additionalCharge.AssetLocationId ) AS LocationDetails
	 ON AssetLocations.LocationId = LocationDetails.LocationId and AssetLocations.AssetId = LocationDetails.AssetId
	 WHEN NOT MATCHED  
     THEN INSERT ([EffectiveFromDate]
           ,[IsCurrent]
           ,[UpfrontTaxMode]
           ,[TaxBasisType]
           ,[IsFLStampTaxExempt]
           ,[ReciprocityAmount_Amount]
           ,[ReciprocityAmount_Currency]
           ,[LienCredit_Amount]
           ,[LienCredit_Currency]
           ,[IsActive]
           ,[CreatedById]
           ,[CreatedTime]
           ,[LocationId]
           ,[AssetId]
		   ,[UpfrontTaxAssessedInLegacySystem])
	 VALUES 
		([EffectiveFromDate]
           ,LocationDetails.[IsCurrent]
           ,LocationDetails.[UpfrontTaxMode]
           ,LocationDetails.[TaxBasisType]
           ,LocationDetails.[IsFLStampTaxExempt]
           ,LocationDetails.[ReciprocityAmount_Amount]
           ,LocationDetails.[ReciprocityAmount_Currency]
           ,LocationDetails.[LienCredit_Amount]
           ,LocationDetails.[LienCredit_Currency]
           ,LocationDetails.[IsActive]
           ,@CreatedById
		   ,@CreatedTime
           ,LocationDetails.[LocationId]
           ,LocationDetails.[AssetId]
		   ,CAST(0 AS BIT));
 
 DROP TABLE #AssetDetails   


 INSERT INTO AssetHistories
		([Reason]
		,[AsOfDate]
		,[AcquisitionDate]
		,[Status]
		,[FinancialType]
		,[SourceModule]
		,[SourceModuleId]
		,[CreatedById]
		,[CreatedTime]
		,[UpdatedById]
		,[UpdatedTime]
		,[CustomerId]
		,[ParentAssetId]
		,[LegalEntityId]
		,[ContractId]
		,[AssetId]
		,[IsReversed]
		,[PropertyTaxReportCodeId])
	SELECT
		 'New'
		,@CommencementDate
		,@CommencementDate
		,Assets.Status
		,Assets.FinancialType
		,'LeaseBooking'
		,@ContractId
		,@CreatedById
		,@CreatedTime
		,NULL
		,NULL
		,Assets.CustomerId
		,Assets.ParentAssetId
		,Assets.LegalEntityId
		,@ContractId
		,Assets.Id
		,0
		,Assets.PropertyTaxReportCodeId
	FROM Assets
	INNER JOIN #CreatedAssetDetails ON Assets.Id = #CreatedAssetDetails.AssetId

 
 SELECT al.Id AS AssetLocationId, tbt.Name As TaxBasisType, ROW_NUMBER() OVER (PARTITION BY al.AssetId ORDER By al.EffectiveFromDate desc, al.Id desc ) as RowNumber 
	INTO #AssetLocationsToUpdate
	FROM dbo.AssetLocations al
	JOIN #CreatedAssetDetails ON al.AssetId = #CreatedAssetDetails.AssetId
	JOIN dbo.LeaseAssets la ON #CreatedAssetDetails.LeaseAssetId = la.Id
	JOIN LeaseTaxAssessmentDetails ltad ON la.LeaseTaxAssessmentDetailId = ltad.Id AND al.LocationId = ltad.LocationId
	JOIN TaxBasisTypes tbt ON ltad.TaxBasisTypeId = tbt.Id
	WHERE la.LeaseFinanceId = @LeaseFinanceId
	AND al.IsActive = 1
	AND la.IsActive = 1
	AND al.EffectiveFromDate <= @CommencementDate
	AND ltad.IsActive = 1;     

	UPDATE AssetLocations SET TaxBasisType = #AssetLocationsToUpdate.TaxBasisType, UpdatedById = @CreatedById, UpdatedTime = @CreatedTime
	FROM AssetLocations
	JOIN #AssetLocationsToUpdate ON AssetLocations.Id = #AssetLocationsToUpdate.AssetLocationId
	WHERE #AssetLocationsToUpdate.RowNumber = 1;

 
 SELECT  
  LeaseAssetId,  
  AssetId  
 FROM #CreatedAssetDetails  
  
    DROP TABLE #CreatedAssetDetails  
  
SET NOCOUNT OFF  
END

GO

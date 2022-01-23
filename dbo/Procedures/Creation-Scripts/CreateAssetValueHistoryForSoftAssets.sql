SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
   
CREATE PROCEDURE [dbo].[CreateAssetValueHistoryForSoftAssets]  
(  
	 @ContractId BIGINT,  
	 @LeaseFinanceId BIGINT,  
	 @CommencementDate DATETIME,  
	 @AssetHistoryReasonNew NVARCHAR(15),  
	 @SourceModule NVARCHAR(25),  
	 @IsRebook BIT,  
	 @IsAccounted BIT,  
	 @ETC BIT,  
	 @ETCSourceModule NVARCHAR(25),  
	 @CreatedById BIGINT,  
	 @CreatedTime DATETIMEOFFSET    
)  
AS  
BEGIN  
SET NOCOUNT ON  

SELECT 
		 AssetLocation.EffectiveFromDate
		,AssetLocation.IsCurrent
		,AssetLocation.UpfrontTaxMode
		,AssetLocation.TaxBasisType
		,AssetLocation.IsActive
		,AssetLocation.LocationId
		,SoftAsset.AssetId
		,SoftAsset.NBV_Currency
		,LeaseAsset.CapitalizedForId
	INTO #AssetLocationDetails
	FROM AssetLocations AssetLocation
	INNER JOIN LeaseAssets LeaseAsset ON AssetLocation.AssetId = LeaseAsset.AssetId
	INNER JOIN LeaseAssets SoftAsset ON LeaseAsset.Id = SoftAsset.CapitalizedForId
	WHERE LeaseAsset.LeaseFinanceId = @LeaseFinanceId AND SoftAsset.IsNewlyAdded = 1
			AND SoftAsset.IsActive = 1

  
 INSERT INTO AssetLocations  
  ([EffectiveFromDate]  
  ,[IsCurrent]  
  ,[UpfrontTaxMode]  
  ,[TaxBasisType]  
  ,[IsActive]  
  ,[CreatedById]  
  ,[CreatedTime]  
  ,[LocationId]  
  ,[IsFLStampTaxExempt]  
  ,[AssetId]  
  ,[ReciprocityAmount_Amount]  
  ,[ReciprocityAmount_Currency]  
  ,[LienCredit_Amount]  
  ,[LienCredit_Currency]
  ,[UpfrontTaxAssessedInLegacySystem])  
 SELECT   
   EffectiveFromDate  
  ,IsCurrent  
  ,UpfrontTaxMode  
  ,TaxBasisType  
  ,IsActive  
  ,@CreatedById  
  ,@CreatedTime  
  ,LocationId  
  ,0  
  ,AssetId  
  ,0.0  
  ,NBV_Currency  
  ,0.0  
  ,NBV_Currency
  ,CAST(0 AS BIT)
 FROM #AssetLocationDetails 
 WHERE CapitalizedForId IS NULL  
  
 INSERT INTO AssetLocations  
  ([EffectiveFromDate]  
  ,[IsCurrent]  
  ,[UpfrontTaxMode]  
  ,[TaxBasisType]  
  ,[IsActive]  
  ,[CreatedById]  
  ,[CreatedTime]  
  ,[LocationId]  
  ,[IsFLStampTaxExempt]  
  ,[AssetId]  
  ,[ReciprocityAmount_Amount]  
  ,[ReciprocityAmount_Currency]  
  ,[LienCredit_Amount]  
  ,[LienCredit_Currency]
  ,[UpfrontTaxAssessedInLegacySystem])  
 SELECT   
   EffectiveFromDate  
  ,IsCurrent  
  ,UpfrontTaxMode  
  ,TaxBasisType  
  ,IsActive  
  ,@CreatedById  
  ,@CreatedTime  
  ,LocationId  
  ,0  
  ,AssetId  
  ,0.0  
  ,NBV_Currency  
  ,0.0  
  ,NBV_Currency   
  ,CAST(0 AS BIT)
 FROM #AssetLocationDetails 
	WHERE CapitalizedForId IS NOT NULL 
  
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
  ,[IsReversed])  
 SELECT  
   @AssetHistoryReasonNew  
  ,@CommencementDate  
  ,Assets.AcquisitionDate  
  ,Assets.Status  
  ,Assets.FinancialType  
  ,@SourceModule  
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
 FROM Assets  
 INNER JOIN LeaseAssets SoftAsset ON Assets.Id = SoftAsset.AssetId  
 WHERE   
 SoftAsset.LeaseFinanceId = @LeaseFinanceId  
 AND SoftAsset.CapitalizedForId IS NOT NULL AND SoftAsset.IsNewlyAdded = 1  

CREATE TABLE #InsertedAssetValueHistories
(
	AssetId BIGINT NOT NULL,
	AssetValueHistoryId BIGINT NOT NULL,
	IsLeaseComponent BIT NOT NULL
)

CREATE TABLE #AssetValueDetails  
(  
  AssetId BIGINT 
 ,LeaseAssetId BIGINT 
 ,IsLeaseComponent BIT 
 ,Cost DECIMAL(16,2)  
 ,Currency NVARCHAR(3)  
);
 
INSERT INTO #AssetValueDetails  
  (
  AssetId
  ,LeaseAssetId
  ,IsLeaseComponent
  ,Cost  
  ,Currency)   
SELECT AssetValueHistories.AssetId 
,LeaseAssetId 
,AssetValueHistories.IsLeaseComponent
   ,AssetValueHistories.Cost_Amount  
   ,AssetValueHistories.Cost_Currency 	
FROM (SELECT  LeaseAssets.Id as LeaseAssetId,
   Assets.Id as AssetId ,AssetValueHistories.IsLeaseComponent
  ,MAX(AssetValueHistories.Id) MaxAVHId  
  FROM AssetValueHistories  
  JOIN Assets ON AssetValueHistories.AssetId = Assets.Id  
  JOIN LeaseAssets ON Assets.Id = LeaseAssets.AssetId  
  JOIN LeaseFinances ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id AND LeaseAssets.IsActive = 1 AND (LeaseAssets.ETCAdjustmentAmount_Amount <> 0.0 OR LeaseAssets.CapitalizedInterimRent_Amount <> 0.0 OR LeaseAssets.CapitalizedInterimInterest_Amount <> 0.0 OR LeaseAssets.CapitalizedProgressPayment_Amount <> 0 OR LeaseAssets.CapitalizedSalesTax_Amount <> 0 OR LeaseAssets.CapitalizedAdditionalCharge_Amount <> 0.0)  
  JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id  
  WHERE LeaseFinances.Id = @LeaseFinanceId AND AssetValueHistories.IncomeDate <= LeaseFinanceDetails.CommencementDate  
	 AND AssetValueHistories.IsSchedule=1  
	 AND AssetValueHistories.IsLessorOwned = 1  
  GROUP BY AssetValueHistories.IsLeaseComponent,Assets.Id,Leaseassets.Id) AS AVH  
	JOIN AssetValueHistories ON AVH.MaxAVHId = AssetValueHistories.Id  

CREATE TABLE #LeaseAssetTemp  
(  
  AssetId BIGINT
 ,LeaseAssetId BIGINT
 ,LeaseFinanceId BIGINT
 ,IsActive BIT
 ,IsLeaseComponent BIT
 ,IsNewlyAdded BIT
 ,CapitalizedInterimRent_Amount DECIMAL(16,2)    
 ,CapitalizedInterimInterest_Amount DECIMAL(16,2)  
 ,CapitalizedProgressPayment_Amount DECIMAL(16,2)  
 ,CapitalizedSalesTax_Amount DECIMAL(16,2)  
 ,CapitalizedAdditionalCharge_Amount DECIMAL(16,2)  
 ,ETCAdjustmentAmount_Amount  DECIMAL(16,2) 
 ,OriginalCapitalizedAmount_Amount DECIMAL(16,2) 
 ,PreviousCapitalizedAdditionalCharge_Amount DECIMAL(16,2) 
 ,NBV_Amount DECIMAL(16,2)  
 ,NBV_Currency NVARCHAR(3)  
); 

INSERT INTO #LeaseAssetTemp
(AssetId
,LeaseAssetId 
,LeaseFinanceId
,IsActive
,IsLeaseComponent
,IsNewlyAdded
,CapitalizedInterimRent_Amount 
,CapitalizedInterimInterest_Amount 
,CapitalizedProgressPayment_Amount 
,CapitalizedSalesTax_Amount
,CapitalizedAdditionalCharge_Amount 
,ETCAdjustmentAmount_Amount
,OriginalCapitalizedAmount_Amount
,PreviousCapitalizedAdditionalCharge_Amount 
,NBV_Amount 
,NBV_Currency 
)
SELECT LeaseAsset.AssetId,LeaseAssetSKU.LeaseAssetId,LeaseAsset.LeaseFinanceId,LeaseAsset.IsActive,
	AssetSKUs.IsLeaseComponent,Leaseasset.IsNewlyAdded,SUM(LeaseAssetSKU.CapitalizedInterimRent_Amount),
	SUM(LeaseAssetSKU.CapitalizedInterimInterest_Amount),SUM(LeaseAssetSKU.CapitalizedProgressPayment_Amount),
	SUM(LeaseAssetSKU.CapitalizedSalesTax_Amount),SUM(LeaseAssetSKU.CapitalizedAdditionalCharge_Amount),
	SUM(LeaseAssetSKU.ETCAdjustmentAmount_Amount),SUM(LeaseAssetSKU.OriginalCapitalizedAmount_Amount),
	LeaseAsset.PreviousCapitalizedAdditionalCharge_Amount,SUM(LeaseAssetSKU.NBV_Amount),LeaseAssetSKU.NBV_Currency
FROM LeaseAssets LeaseAsset  
 INNER JOIN LeaseAssetSKUs LeaseAssetSKU  on LeaseAsset.Id=LeaseAssetSKU.LeaseAssetId
 INNER JOIN AssetSKUs on LeaseAssetSKU.AssetSKUId = AssetSKUs.Id
WHERE LeaseAsset.LeaseFinanceId = @LeaseFinanceId AND LeaseAsset.IsActive = 1
GROUP BY AssetSKUs.IsLeaseComponent,LeaseAssetSKU.LeaseAssetId,
LeaseAssetSKU.NBV_Currency,LeaseAsset.AssetId,LeaseAsset.LeaseFinanceId,LeaseAsset.IsActive,IsNewlyAdded
,LeaseAsset.PreviousCapitalizedAdditionalCharge_Amount
Having	(SUM(LeaseAssetSKU.CapitalizedInterimRent_Amount) <> 0
		or SUM(LeaseAssetSKU.CapitalizedInterimInterest_Amount) <> 0
		or SUM(LeaseAssetSKU.CapitalizedProgressPayment_Amount) <> 0
		or SUM(LeaseAssetSKU.CapitalizedSalesTax_Amount) <> 0
		or SUM(LeaseAssetSKU.CapitalizedAdditionalCharge_Amount) <> 0
		or SUM(LeaseAssetSKU.ETCAdjustmentAmount_Amount) <> 0)

INSERT INTO #LeaseAssetTemp
	 (AssetId
	 ,LeaseAssetId 
	 ,IsLeaseComponent
	 ,LeaseFinanceId
	 ,IsActive
	 ,IsNewlyAdded
	 ,CapitalizedInterimRent_Amount 
	 ,CapitalizedInterimInterest_Amount 
	 ,CapitalizedProgressPayment_Amount 
	 ,CapitalizedSalesTax_Amount
	 ,CapitalizedAdditionalCharge_Amount 
	 ,ETCAdjustmentAmount_Amount 
	 ,OriginalCapitalizedAmount_Amount
	 ,PreviousCapitalizedAdditionalCharge_Amount
	 ,NBV_Amount 
	 ,NBV_Currency 
	 )
SELECT LeaseAsset.AssetId,LeaseAsset.Id,Asset.IsLeaseComponent,LeaseAsset.LeaseFinanceId,LeaseAsset.IsActive,LeaseAsset.IsNewlyAdded,CapitalizedInterimRent_Amount,CapitalizedInterimInterest_Amount,
		CapitalizedProgressPayment_Amount,CapitalizedSalesTax_Amount,
		CapitalizedAdditionalCharge_Amount,ETCAdjustmentAmount_Amount,
		OriginalCapitalizedAmount_Amount,PreviousCapitalizedAdditionalCharge_Amount,NBV_Amount,LeaseAsset.NBV_Currency
FROM LeaseAssets LeaseAsset
INNER JOIN Assets Asset on LeaseAsset.AssetId = Asset.Id
WHERE LeaseAsset.LeaseFinanceId = @LeaseFinanceId AND Asset.IsSKU = 0 AND LeaseAsset.IsActive = 1 AND LeaseAsset.IsAdditionalChargeSoftAsset = 0

IF(@ETC=1)  
 BEGIN  

CREATE TABLE #ETCAssetDetails  
(  
	AssetId BIGINT  
	,Amount DECIMAL(16,2)  
	,Currency NVARCHAR(3)  
	,SourceId BIGINT  
	,EffectiveDate DATE
	,IsLeaseComponent BIT  
) 

 IF(@IsRebook = 1)  
  BEGIN  
	INSERT INTO #ETCAssetDetails  
  SELECT   
	  LeaseAssets.AssetId  
	  ,-(SUM(LeaseAssetSKUs.ETCAdjustmentAmount_Amount))  
	  ,MAX(LeaseAssetSKUs.ETCAdjustmentAmount_Currency)
	  ,BlendedItems.Id  
	  ,CASE  WHEN LeaseFinanceDetails.InterimAssessmentMethod = '_' THEN @CommencementDate  
			 WHEN LeaseFinanceDetails.InterimAssessmentMethod IN('Interest','Both') AND LeaseAssets.InterimInterestStartDate IS NOT NULL THEN LeaseAssets.InterimInterestStartDate   
			 WHEN LeaseFinanceDetails.InterimAssessmentMethod IN('Rent','Both') AND LeaseAssets.InterimRentStartDate IS NOT NULL THEN LeaseAssets.InterimRentStartDate   
			 ELSE @CommencementDate END AS EffectiveDate 
	  ,AssetSKUs.IsLeaseComponent
  FROM LeaseFinances  
	  INNER JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id  
	  INNER JOIN LeaseBlendedItems ON  LeaseFinances.Id = LeaseBlendedItems.LeaseFinanceId  
	  INNER JOIN BlendedItems ON LeaseBlendedItems.BlendedItemId = BlendedItems.Id AND IsActive=1  
	  INNER JOIN BlendedItemAssets ON BlendedItems.Id = BlendedItemAssets.BlendedItemId AND BlendedItemAssets.IsActive=1  
	  INNER JOIN LeaseAssets ON BlendedItemAssets.LeaseAssetId = LeaseAssets.Id  
	  INNER JOIN LeaseAssetSKUs on LeaseAssets.Id = LeaseAssetSKUs.LeaseAssetId 
	  INNER JOIN AssetSKUs on LeaseAssetSKUs.AssetSKUId = AssetSKUs.Id
	  WHERE LeaseFinances.Id = @LeaseFinanceId AND (BlendedItems.IsNewlyAdded = 1 OR LeaseBlendedItems.Revise = 1)
	  AND LeaseAssets.ETCAdjustmentAmount_Amount <> 0  
		GROUP BY  
		   AssetSKUs.IsLeaseComponent 
		  ,LeaseAssets.AssetId 
		  ,BlendedItems.Id  
		  ,LeaseFinanceDetails.InterimAssessmentMethod  
		  ,LeaseAssets.InterimInterestStartDate  
		  ,LeaseAssets.InterimRentStartDate

	INSERT INTO #ETCAssetDetails  
  SELECT   
	  LeaseAssets.AssetId  
	  ,-(LeaseAssets.ETCAdjustmentAmount_Amount) 
	  ,LeaseAssets.ETCAdjustmentAmount_Currency  
	  ,BlendedItems.Id  
	  ,CASE  WHEN LeaseFinanceDetails.InterimAssessmentMethod = '_' THEN @CommencementDate  
			 WHEN LeaseFinanceDetails.InterimAssessmentMethod IN('Interest','Both') AND LeaseAssets.InterimInterestStartDate IS NOT NULL THEN LeaseAssets.InterimInterestStartDate   
			 WHEN LeaseFinanceDetails.InterimAssessmentMethod IN('Rent','Both') AND LeaseAssets.InterimRentStartDate IS NOT NULL THEN LeaseAssets.InterimRentStartDate   
			 ELSE @CommencementDate END AS EffectiveDate 
	  ,Assets.IsLeaseComponent
  FROM LeaseFinances  
	  INNER JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id  
	  INNER JOIN LeaseBlendedItems ON  LeaseFinances.Id = LeaseBlendedItems.LeaseFinanceId  
	  INNER JOIN BlendedItems ON LeaseBlendedItems.BlendedItemId = BlendedItems.Id AND IsActive=1  
	  INNER JOIN BlendedItemAssets ON BlendedItems.Id = BlendedItemAssets.BlendedItemId AND BlendedItemAssets.IsActive=1  
	  INNER JOIN LeaseAssets ON BlendedItemAssets.LeaseAssetId = LeaseAssets.Id  
	  INNER JOIN #AssetValueDetails ON #AssetValueDetails.LeaseAssetId = LeaseAssets.Id  
	  INNER JOIN Assets ON LeaseAssets.AssetId = Assets.Id 
	  WHERE LeaseFinances.Id = @LeaseFinanceId AND (BlendedItems.IsNewlyAdded = 1 OR LeaseBlendedItems.Revise = 1)
	  AND LeaseAssets.ETCAdjustmentAmount_Amount <> 0 AND Assets.IsSKU=0
		GROUP BY  
		   Assets.IsLeaseComponent 
		  ,LeaseAssets.AssetId 
		  ,BlendedItems.Id  
		  ,LeaseFinanceDetails.InterimAssessmentMethod  
		  ,LeaseAssets.InterimInterestStartDate  
		  ,LeaseAssets.InterimRentStartDate
		  ,LeaseAssets.ETCAdjustmentAmount_Amount  
		  ,LeaseAssets.ETCAdjustmentAmount_Currency
  END

 ELSE
  BEGIN
	INSERT INTO #ETCAssetDetails  
  SELECT   
	  LeaseAssets.AssetId  
	  ,-(SUM(LeaseAssetSKUs.ETCAdjustmentAmount_Amount))  
	  ,MAX(LeaseAssetSKUs.ETCAdjustmentAmount_Currency)
	  ,BlendedItems.Id  
	  ,CASE  WHEN LeaseFinanceDetails.InterimAssessmentMethod = '_' THEN @CommencementDate  
			 WHEN LeaseFinanceDetails.InterimAssessmentMethod IN('Interest','Both') AND LeaseAssets.InterimInterestStartDate IS NOT NULL THEN LeaseAssets.InterimInterestStartDate   
			 WHEN LeaseFinanceDetails.InterimAssessmentMethod IN('Rent','Both') AND LeaseAssets.InterimRentStartDate IS NOT NULL THEN LeaseAssets.InterimRentStartDate   
			 ELSE @CommencementDate END AS EffectiveDate 
	  ,AssetSKUs.IsLeaseComponent
  FROM LeaseFinances  
	  INNER JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id  
	  INNER JOIN LeaseBlendedItems ON  LeaseFinances.Id = LeaseBlendedItems.LeaseFinanceId  
	  INNER JOIN BlendedItems ON LeaseBlendedItems.BlendedItemId = BlendedItems.Id AND IsActive=1  
	  INNER JOIN BlendedItemAssets ON BlendedItems.Id = BlendedItemAssets.BlendedItemId AND BlendedItemAssets.IsActive=1  
	  INNER JOIN LeaseAssets ON BlendedItemAssets.LeaseAssetId = LeaseAssets.Id  
	  INNER JOIN LeaseAssetSKUs on LeaseAssets.Id = LeaseAssetSKUs.LeaseAssetId 
	  INNER JOIN AssetSKUs on LeaseAssetSKUs.AssetSKUId = AssetSKUs.Id 
	  WHERE LeaseFinances.Id = @LeaseFinanceId  
	  AND LeaseAssets.ETCAdjustmentAmount_Amount <> 0  
		GROUP BY  
		   AssetSKUs.IsLeaseComponent 
		  ,LeaseAssets.AssetId 
		  ,BlendedItems.Id  
		  ,LeaseFinanceDetails.InterimAssessmentMethod  
		  ,LeaseAssets.InterimInterestStartDate  
		  ,LeaseAssets.InterimRentStartDate

    INSERT INTO #ETCAssetDetails  
  SELECT   
	  LeaseAssets.AssetId  
	  ,-(LeaseAssets.ETCAdjustmentAmount_Amount) 
	  ,LeaseAssets.ETCAdjustmentAmount_Currency  
	  ,BlendedItems.Id  
	  ,CASE  WHEN LeaseFinanceDetails.InterimAssessmentMethod = '_' THEN @CommencementDate  
			 WHEN LeaseFinanceDetails.InterimAssessmentMethod IN('Interest','Both') AND LeaseAssets.InterimInterestStartDate IS NOT NULL THEN LeaseAssets.InterimInterestStartDate   
			 WHEN LeaseFinanceDetails.InterimAssessmentMethod IN('Rent','Both') AND LeaseAssets.InterimRentStartDate IS NOT NULL THEN LeaseAssets.InterimRentStartDate   
			 ELSE @CommencementDate END AS EffectiveDate 
	  ,Assets.IsLeaseComponent
  FROM LeaseFinances  
	  INNER JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id  
	  INNER JOIN LeaseBlendedItems ON  LeaseFinances.Id = LeaseBlendedItems.LeaseFinanceId  
	  INNER JOIN BlendedItems ON LeaseBlendedItems.BlendedItemId = BlendedItems.Id AND IsActive=1  
	  INNER JOIN BlendedItemAssets ON BlendedItems.Id = BlendedItemAssets.BlendedItemId AND BlendedItemAssets.IsActive=1  
	  INNER JOIN LeaseAssets ON BlendedItemAssets.LeaseAssetId = LeaseAssets.Id  
	  INNER JOIN #AssetValueDetails ON #AssetValueDetails.LeaseAssetId = LeaseAssets.Id  
	  INNER JOIN Assets ON LeaseAssets.AssetId = Assets.Id
	  WHERE LeaseFinances.Id = @LeaseFinanceId  
	  AND LeaseAssets.ETCAdjustmentAmount_Amount <> 0 AND Assets.IsSKU=0
		GROUP BY  
		   Assets.IsLeaseComponent 
		  ,LeaseAssets.AssetId 
		  ,BlendedItems.Id  
		  ,LeaseFinanceDetails.InterimAssessmentMethod  
		  ,LeaseAssets.InterimInterestStartDate  
		  ,LeaseAssets.InterimRentStartDate
		  ,LeaseAssets.ETCAdjustmentAmount_Amount  
		  ,LeaseAssets.ETCAdjustmentAmount_Currency

  END

INSERT INTO [dbo].[AssetValueHistories]  
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
           ,[CreatedById]  
           ,[CreatedTime]             
           ,[AssetId]  
		   ,[AdjustmentEntry]  
		   ,[IsLessorOwned]
		   ,[IsLeaseComponent])
	SELECT    
	  @ETCSourceModule 
	 ,#ETCAssetDetails.SourceId  
     ,#ETCAssetDetails.EffectiveDate  
     ,#ETCAssetDetails.EffectiveDate  
     ,#ETCAssetDetails.EffectiveDate  
     ,#ETCAssetDetails.Amount  
     ,#ETCAssetDetails.Currency  
     ,#AssetValueDetails.Cost   
     ,#AssetValueDetails.Currency   
     ,(LeaseAsset.NBV_Amount - LeaseAsset.CapitalizedInterimRent_Amount - LeaseAsset.CapitalizedInterimInterest_Amount - LeaseAsset.CapitalizedProgressPayment_Amount - LeaseAsset.CapitalizedSalesTax_Amount - LeaseAsset.CapitalizedAdditionalCharge_Amount) + #ETCAssetDetails.Amount  
     ,#ETCAssetDetails.Currency  
      ,(LeaseAsset.NBV_Amount - LeaseAsset.CapitalizedInterimRent_Amount - LeaseAsset.CapitalizedInterimInterest_Amount - LeaseAsset.CapitalizedProgressPayment_Amount - LeaseAsset.CapitalizedSalesTax_Amount - LeaseAsset.CapitalizedAdditionalCharge_Amount)  
     ,#ETCAssetDetails.Currency  
     ,(LeaseAsset.NBV_Amount - LeaseAsset.CapitalizedInterimRent_Amount - LeaseAsset.CapitalizedInterimInterest_Amount - LeaseAsset.CapitalizedProgressPayment_Amount - LeaseAsset.CapitalizedSalesTax_Amount - LeaseAsset.CapitalizedAdditionalCharge_Amount) + #ETCAssetDetails.Amount  
     ,#ETCAssetDetails.Currency  
     ,@IsAccounted  
     ,1  
     ,1  
     ,LeaseFinanceDetail.PostDate  
     ,@CreatedById  
     ,@CreatedTime  
     ,LeaseAsset.AssetId  
     ,0  
     ,1  
	 ,#AssetValueDetails.IsLeaseComponent
   FROM LeaseFinances LeaseFinance  
     INNER JOIN LeaseFinanceDetails LeaseFinanceDetail ON LeaseFinance.Id = LeaseFinanceDetail.Id  
     INNER JOIN #LeaseAssetTemp LeaseAsset ON LeaseFinance.Id = LeaseAsset.LeaseFinanceId AND LeaseAsset.IsActive = 1        
     INNER JOIN #ETCAssetDetails ON LeaseAsset.AssetId = #ETCAssetDetails.AssetId
	 AND #ETCAssetDetails.IsLeaseComponent = LeaseAsset.IsLeaseComponent     
	 INNER JOIN #AssetValueDetails ON #ETCAssetDetails.AssetId  = #AssetValueDetails.AssetId  
	 AND #ETCAssetDetails.IsLeaseComponent = #AssetValueDetails.IsLeaseComponent     
		WHERE LeaseFinance.Id = @LeaseFinanceId
		 
	IF OBJECT_ID('tempdb..#ETCAssetDetails') IS NOT NULL
		DROP TABLE #ETCAssetDetails
 END

INSERT INTO [dbo].[AssetValueHistories]  
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
    ,[CreatedById]  
    ,[CreatedTime]             
    ,[AssetId]  
    ,[AdjustmentEntry]  
    ,[IsLessorOwned]
	,[IsLeaseComponent])
	OUTPUT INSERTED.AssetId,INSERTED.Id,INSERTED.IsLeaseComponent INTO #InsertedAssetValueHistories
	SELECT   
	 @SourceModule  
     ,LeaseFinance.ContractId  
     ,LeaseFinanceDetail.CommencementDate  
     ,LeaseFinanceDetail.CommencementDate  
     ,LeaseFinanceDetail.CommencementDate  
     ,(LeaseAsset.CapitalizedInterimRent_Amount + LeaseAsset.CapitalizedInterimInterest_Amount + LeaseAsset.CapitalizedProgressPayment_Amount + LeaseAsset.CapitalizedSalesTax_Amount + LeaseAsset.CapitalizedAdditionalCharge_Amount)  
     ,LeaseAsset.NBV_Currency      
     ,#AssetValueDetails.Cost   
     ,#AssetValueDetails.Currency  
     ,LeaseAsset.NBV_Amount - LeaseAsset.ETCAdjustmentAmount_Amount  
     ,LeaseAsset.NBV_Currency  
     ,(LeaseAsset.NBV_Amount - LeaseAsset.ETCAdjustmentAmount_Amount - LeaseAsset.CapitalizedInterimRent_Amount - LeaseAsset.CapitalizedInterimInterest_Amount - LeaseAsset.CapitalizedProgressPayment_Amount - LeaseAsset.CapitalizedSalesTax_Amount - LeaseAsset.CapitalizedAdditionalCharge_Amount)  
     ,LeaseAsset.NBV_Currency  
     ,LeaseAsset.NBV_Amount - LeaseAsset.ETCAdjustmentAmount_Amount  
     ,LeaseAsset.NBV_Currency  
     ,@IsAccounted   
     ,1  
     ,1  
     ,LeaseFinanceDetail.PostDate  
     ,@CreatedById
     ,@CreatedTime  
     ,LeaseAsset.AssetId  
     ,0  
     ,1  
	 ,#AssetValueDetails.IsLeaseComponent
	 
	 FROM LeaseFinances LeaseFinance  
	 INNER JOIN #LeaseAssetTemp LeaseAsset ON LeaseFinance.Id = LeaseAsset.LeaseFinanceId AND LeaseAsset.IsActive = 1 
	 AND (LeaseAsset.CapitalizedInterimRent_Amount <> 0.0 OR LeaseAsset.CapitalizedInterimInterest_Amount <> 0.0 OR LeaseAsset.CapitalizedProgressPayment_Amount <> 0 OR LeaseAsset.CapitalizedSalesTax_Amount <> 0 OR LeaseAsset.CapitalizedAdditionalCharge_Amount <> 0)  
     INNER JOIN LeaseFinanceDetails LeaseFinanceDetail ON LeaseFinance.Id = LeaseFinanceDetail.Id 
	 INNER JOIN #AssetValueDetails ON #AssetValueDetails.LeaseAssetId = LeaseAsset.LeaseAssetId 
	 AND #AssetValueDetails.IsLeaseComponent = LeaseAsset.IsLeaseComponent 
     WHERE LeaseFinance.Id = @LeaseFinanceId AND LeaseAsset.IsNewlyAdded = 1

INSERT INTO [dbo].[SKUValueProportions]
	 ([Value_Amount]
	 ,[Value_Currency]
	 ,[CreatedById]
	 ,[CreatedTime]
	 ,[AssetSKUId]
	 ,[IsActive]
	 ,[AssetValueHistoryId]
	 )  
	SELECT 
	 LeaseAssetSKUs.NBV_Amount
	,LeaseAssetSKUs.NBV_Currency
	,@CreatedById
	,@CreatedTime
	,LeaseAssetSKUs.AssetSKUId
	,LeaseAssetSKUs.IsActive 	
	,avh.AssetValueHistoryId
	FROM LeaseFinances   
	INNER JOIN LeaseAssets ON LeaseFinances.Id = LeaseAssets.LeaseFinanceId
	INNER JOIN LeaseAssetSKUs ON LeaseAssets.Id = LeaseAssetSKUs.LeaseAssetId
	AND (LeaseAssetSKUs.CapitalizedInterimRent_Amount <> 0.0 OR LeaseAssetSKUs.CapitalizedInterimInterest_Amount <> 0.0 OR LeaseAssetSKUs.CapitalizedProgressPayment_Amount <> 0 OR LeaseAssetSKUs.CapitalizedSalesTax_Amount <> 0 OR LeaseAssetSKUs.CapitalizedAdditionalCharge_Amount <> 0)  
	INNER JOIN AssetSKUs asku ON LeaseAssetSKUs.AssetSKUId = asku.Id
	INNER JOIN #InsertedAssetValueHistories avh on LeaseAssets.AssetId = avh.AssetId AND asku.IsLeaseComponent = avh.IsLeaseComponent
	WHERE LeaseFinanceId = @LeaseFinanceId 
	AND LeaseAssets.IsNewlyAdded = 1

DELETE FROM #InsertedAssetValueHistories

SELECT		
			LeaseFinance.ContractId
		   ,LeaseFinanceDetail.CommencementDate
		   ,LeaseAsset.NBV_Amount
		   ,LeaseAsset.NBV_Currency
		   ,LeaseAsset.OriginalCapitalizedAmount_Amount
		   ,LeaseFinanceDetail.PostDate
		   ,LeaseAsset.AssetId
		   ,LeaseAsset.CapitalizedForId
		   ,LeaseAsset.IsNewlyAdded
		   INTO #AssetValueHistoryDetails
           FROM LeaseFinances LeaseFinance
		   INNER JOIN LeaseAssets LeaseAsset ON LeaseFinance.Id = LeaseAsset.LeaseFinanceId AND LeaseAsset.IsActive = 1 
		   INNER JOIN LeaseFinanceDetails LeaseFinanceDetail ON LeaseFinance.Id = LeaseFinanceDetail.Id
		   WHERE LeaseFinance.Id = @LeaseFinanceId AND LeaseAsset.CapitalizedForId IS NOT NULL

INSERT INTO [dbo].[AssetValueHistories]  
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
           ,[CreatedById]  
           ,[CreatedTime]             
           ,[AssetId]  
		  ,[AdjustmentEntry]  
		  ,[IsLessorOwned]
		  ,[IsLeaseComponent])
	SELECT    
	 @SourceModule 
     ,ContractId  
     ,CommencementDate  
     ,CommencementDate  
     ,CommencementDate  
     ,NBV_Amount  
     ,NBV_Currency       
     ,NBV_Amount  
     ,NBV_Currency  
     ,NBV_Amount  
     ,NBV_Currency  
     ,NBV_Amount  
     ,NBV_Currency  
     ,NBV_Amount  
     ,NBV_Currency  
     ,@IsAccounted  
     ,1  
     ,1  
     ,PostDate  
     ,@CreatedById 
     ,@CreatedTime  
     ,AssetId  
     ,0  
     ,1  
     ,Asset.IsLeaseComponent
     FROM #AssetValueHistoryDetails AVHDetails
	 INNER JOIN Assets Asset on AVHDetails.AssetId = Asset.Id
		 WHERE IsNewlyAdded=1 

IF(@IsRebook = 1)
 BEGIN

 --AVH and SKU Value Proportions Reversal For Previous Lease Finance
 CREATE TABLE #OldCapitalizationValues(
	AssetId BIGINT NOT NULL,
	AVHId BIGINT NOT NULL,
	SKUValueProportionsId BIGINT NULL,
	ETCAdjustmentAmount_Amount DECIMAL(16,2),
	CapitalizedInterimRent_Amount DECIMAL(16,2),
	CapitalizedInterimInterest_Amount DECIMAL(16,2),
	CapitalizedProgressPayment_Amount DECIMAL(16,2),
	CapitalizedSalesTax_Amount DECIMAL(16,2),
	CapitalizedAdditionalCharge_Amount DECIMAL(16,2)
 );

  CREATE TABLE #AssetSKUValueReversal(
	AVHId BIGINT NOT NULL,
	SKUValueProportionsId BIGINT NULL
 );

 DECLARE @OriginalLeaseFinanceId BIGINT = (SELECT OriginalLeaseFinanceId FROM LeaseAmendments WHERE CurrentLeaseFinanceId = @LeaseFinanceId);

 INSERT INTO #OldCapitalizationValues
 (
	AssetId,
	AVHId,
	SKUValueProportionsId,
	CapitalizedInterimRent_Amount,
	CapitalizedInterimInterest_Amount,
	CapitalizedProgressPayment_Amount,
	CapitalizedSalesTax_Amount,
	CapitalizedAdditionalCharge_Amount
 )
 SELECT
	LeaseAssets.AssetId,
	AssetValueHistories.Id,
	SKUValueProportions.Id,
	LeaseAssets.CapitalizedInterimRent_Amount,
	LeaseAssets.CapitalizedInterimInterest_Amount,
	LeaseAssets.CapitalizedProgressPayment_Amount,
	LeaseAssets.CapitalizedSalesTax_Amount,
	LeaseAssets.CapitalizedAdditionalCharge_Amount
 FROM LeaseAssets
 INNER JOIN LeaseAssetSKUs ON LeaseAssets.Id = LeaseAssetSKUs.LeaseAssetId AND LeaseAssets.IsActive = 1
 INNER JOIN AssetValueHistories ON LeaseAssets.AssetId = AssetValueHistories.AssetId
 INNER JOIN SKUValueProportions ON LeaseAssetSKUs.AssetSKUId = SKUValueProportions.AssetSKUId AND AssetValueHistories.Id = SKUValueProportions.AssetValueHistoryId
 WHERE LeaseAssets.LeaseFinanceId = @OriginalLeaseFinanceId
 AND AssetValueHistories.SourceModuleId = @ContractId AND AssetValueHistories.SourceModule = @SourceModule

 UNION

 SELECT
	LeaseAssets.AssetId,
	AssetValueHistories.Id,
	NULL,
	LeaseAssets.CapitalizedInterimRent_Amount,
	LeaseAssets.CapitalizedInterimInterest_Amount,
	LeaseAssets.CapitalizedProgressPayment_Amount,
	LeaseAssets.CapitalizedSalesTax_Amount,
	LeaseAssets.CapitalizedAdditionalCharge_Amount
 FROM LeaseAssets
 INNER JOIN AssetValueHistories ON LeaseAssets.AssetId = AssetValueHistories.AssetId AND LeaseAssets.IsActive = 1
 INNER JOIN Assets ON LeaseAssets.AssetId = Assets.Id
 WHERE LeaseAssets.LeaseFinanceId = @OriginalLeaseFinanceId
 AND AssetValueHistories.SourceModuleId = @ContractId AND AssetValueHistories.SourceModule = @SourceModule AND Assets.IsSKU = 0

 INSERT INTO #AssetSKUValueReversal
 (
	AVHId,
	SKUValueProportionsId
 )
 SELECT
	#OldCapitalizationValues.AVHId,
	#OldCapitalizationValues.SKUValueProportionsId
 FROM LeaseAssets 
 INNER JOIN #OldCapitalizationValues ON LeaseAssets.AssetId = #OldCapitalizationValues.AssetId 
 AND LeaseAssets.LeaseFinanceId = @LeaseFinanceId
 AND ((LeaseAssets.CapitalizedInterimInterest_Amount = 0 AND #OldCapitalizationValues.CapitalizedInterimInterest_Amount <> 0) OR
	  (LeaseAssets.CapitalizedInterimRent_Amount = 0 AND #OldCapitalizationValues.CapitalizedInterimRent_Amount <> 0) OR
	  (LeaseAssets.CapitalizedProgressPayment_Amount = 0 AND #OldCapitalizationValues.CapitalizedProgressPayment_Amount <> 0) OR
	  (LeaseAssets.CapitalizedSalesTax_Amount = 0 AND #OldCapitalizationValues.CapitalizedSalesTax_Amount <> 0) OR
	  (LeaseAssets.CapitalizedAdditionalCharge_Amount = 0 AND #OldCapitalizationValues.CapitalizedAdditionalCharge_Amount <> 0))

 UPDATE AssetValueHistories SET IsSchedule = 0 , IsAccounted = 0 , IsCleared = 0 FROM AssetValueHistories
 JOIN #AssetSKUValueReversal ON AssetValueHistories.Id = #AssetSKUValueReversal.AVHId

 UPDATE SKUValueProportions SET IsActive = 0  FROM SKUValueProportions
 JOIN #AssetSKUValueReversal ON SKUValueProportions.Id = #AssetSKUValueReversal.SKUValueProportionsId

 --AVH Entries for Capitalization Value changes

 SELECT DISTINCT AssetValueHistories.AssetId, AssetValueHistories.Id INTO #AVHRecordsToBeUpdated FROM AssetValueHistories
 JOIN #OldCapitalizationValues ON AssetValueHistories.Id = #OldCapitalizationValues.AVHId
 JOIN #LeaseAssetTemp ON AssetValueHistories.AssetId = #LeaseAssetTemp.AssetId
 WHERE AssetValueHistories.IsSchedule = 1
 AND (AssetValueHistories.EndBookValue_Amount - AssetValueHistories.BeginBookValue_Amount - #LeaseAssetTemp.CapitalizedInterimInterest_Amount - #LeaseAssetTemp.CapitalizedInterimRent_Amount - #LeaseAssetTemp.CapitalizedProgressPayment_Amount - #LeaseAssetTemp.CapitalizedSalesTax_Amount - #LeaseAssetTemp.ETCAdjustmentAmount_Amount - #LeaseAssetTemp.CapitalizedAdditionalCharge_Amount ) <> 0

SELECT DISTINCT LeaseAssetSKUs.AssetSKUId,SKUValueProportions.Id INTO #SVPRecordsToBeUpdated 
FROM  LeaseAssets 
JOIN LeaseAssetSKUs ON LeaseAssets.Id = LeaseAssetSKUs.LeaseAssetId
JOIN AssetValueHistories on LeaseAssets.AssetId = AssetValueHistories.AssetId
JOIN SKUValueProportions ON LeaseAssetSKUs.AssetSKUId = SKUValueProportions.AssetSKUId AND AssetValueHistories.Id = SKUValueProportions.AssetValueHistoryId
WHERE LeaseAssets.LeaseFinanceId = @LeaseFinanceId AND AssetValueHistories.SourceModule = 'LeaseBooking'
AND SKUValueProportions.IsActive = 1 AND LeaseAssetSKUs.NBV_Amount != SKUValueProportions.Value_Amount

UPDATE AssetValueHistories SET IsSchedule = 0 , IsAccounted = 0 , IsCleared = 0 
FROM AssetValueHistories
JOIN #AVHRecordsToBeUpdated avh ON AssetValueHistories.Id = avh.Id
 
UPDATE SKUValueProportions SET IsActive = 0  
FROM SKUValueProportions
JOIN #OldCapitalizationValues oldCapitalization ON SKUValueProportions.AssetValueHistoryId = oldCapitalization.AVHId
JOIN #SVPRecordsToBeUpdated ON SKUValueProportions.Id = #SVPRecordsToBeUpdated.Id

INSERT INTO [dbo].[AssetValueHistories]  
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
           ,[CreatedById]  
           ,[CreatedTime]             
           ,[AssetId]  
           ,[AdjustmentEntry]  
           ,[IsLessorOwned]
		   ,[IsLeaseComponent])
		   OUTPUT INSERTED.AssetId,INSERTED.Id,INSERTED.IsLeaseComponent INTO #InsertedAssetValueHistories
	SELECT   
	 @SourceModule  
     ,LeaseFinance.ContractId  
     ,LeaseFinanceDetail.CommencementDate  
     ,LeaseFinanceDetail.CommencementDate  
     ,LeaseFinanceDetail.CommencementDate  
     ,(LeaseAsset.CapitalizedInterimRent_Amount + LeaseAsset.CapitalizedInterimInterest_Amount + LeaseAsset.CapitalizedProgressPayment_Amount + LeaseAsset.CapitalizedSalesTax_Amount + LeaseAsset.CapitalizedAdditionalCharge_Amount)
	 - LeaseAsset.OriginalCapitalizedAmount_Amount - LeaseAsset.PreviousCapitalizedAdditionalCharge_Amount  
     ,LeaseAsset.NBV_Currency      
     ,#AssetValueDetails.Cost   
     ,#AssetValueDetails.Currency  
     ,LeaseAsset.NBV_Amount - LeaseAsset.ETCAdjustmentAmount_Amount  
     ,LeaseAsset.NBV_Currency  
     ,(LeaseAsset.NBV_Amount - LeaseAsset.ETCAdjustmentAmount_Amount - LeaseAsset.CapitalizedInterimRent_Amount - LeaseAsset.CapitalizedInterimInterest_Amount - LeaseAsset.CapitalizedProgressPayment_Amount - LeaseAsset.CapitalizedSalesTax_Amount - LeaseAsset.CapitalizedAdditionalCharge_Amount)  
     ,LeaseAsset.NBV_Currency  
     ,LeaseAsset.NBV_Amount - LeaseAsset.ETCAdjustmentAmount_Amount  
     ,LeaseAsset.NBV_Currency  
     ,@IsAccounted   
     ,1  
     ,1  
     ,LeaseFinanceDetail.PostDate  
     ,@CreatedById
     ,@CreatedTime  
     ,LeaseAsset.AssetId  
     ,0  
     ,1  
	 ,#AssetValueDetails.IsLeaseComponent
	FROM LeaseFinances LeaseFinance  
	INNER JOIN #LeaseAssetTemp LeaseAsset ON LeaseFinance.Id = LeaseAsset.LeaseFinanceId AND LeaseAsset.IsActive = 1 
	AND (((LeaseAsset.OriginalCapitalizedAmount_Amount + LeaseAsset.PreviousCapitalizedAdditionalCharge_Amount) - LeaseAsset.CapitalizedInterimRent_Amount - LeaseAsset.CapitalizedInterimInterest_Amount - LeaseAsset.CapitalizedProgressPayment_Amount - LeaseAsset.CapitalizedSalesTax_Amount) <> 0.0)
	INNER JOIN LeaseFinanceDetails LeaseFinanceDetail ON LeaseFinance.Id = LeaseFinanceDetail.Id 
	INNER JOIN #AssetValueDetails ON #AssetValueDetails.LeaseAssetId = LeaseAsset.LeaseAssetId 
	AND #AssetValueDetails.IsLeaseComponent = LeaseAsset.IsLeaseComponent 
	WHERE LeaseFinance.Id = @LeaseFinanceId AND LeaseAsset.IsNewlyAdded = 0

INSERT INTO [dbo].[SKUValueProportions]
	 ([Value_Amount]
	 ,[Value_Currency]
	 ,[CreatedById]
	 ,[CreatedTime]
	 ,[AssetSKUId]
	 ,[IsActive]
	 ,[AssetValueHistoryId]
	 )  
	SELECT 
	 LeaseAssetSKUs.NBV_Amount
	,LeaseAssetSKUs.NBV_Currency
	,@CreatedById
	,@CreatedTime
	,LeaseAssetSKUs.AssetSKUId
	,LeaseAssetSKUs.IsActive 	
	,avh.AssetValueHistoryId
	FROM LeaseFinances   
	INNER JOIN LeaseAssets ON LeaseFinances.Id = LeaseAssets.LeaseFinanceId
	INNER JOIN LeaseAssetSKUs ON LeaseAssets.Id = LeaseAssetSKUs.LeaseAssetId
	AND (LeaseAssetSKUs.CapitalizedInterimRent_Amount <> 0.0 OR LeaseAssetSKUs.CapitalizedInterimInterest_Amount <> 0.0 OR LeaseAssetSKUs.CapitalizedProgressPayment_Amount <> 0 OR LeaseAssetSKUs.CapitalizedSalesTax_Amount <> 0 OR LeaseAssetSKUs.CapitalizedAdditionalCharge_Amount <> 0)  
	INNER JOIN AssetSKUs asku ON LeaseAssetSKUs.AssetSKUId = asku.Id
	INNER JOIN #InsertedAssetValueHistories avh ON asku.AssetId = avh.AssetId AND asku.IsLeaseComponent = avh.IsLeaseComponent
	WHERE LeaseFinanceId = @LeaseFinanceId
	AND LeaseAssets.IsNewlyAdded = 0
	AND (LeaseAssetSKUs.OriginalCapitalizedAmount_Amount - LeaseAssetSKUs.CapitalizedInterimInterest_Amount - LeaseAssetSKUs.CapitalizedInterimRent_Amount - LeaseAssetSKUs.CapitalizedProgressPayment_Amount - LeaseAssetSKUs.CapitalizedSalesTax_Amount - LeaseAssetSKUs.ETCAdjustmentAmount_Amount - LeaseAssetSKUs.CapitalizedAdditionalCharge_Amount ) <> 0

INSERT INTO [dbo].[AssetValueHistories]  
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
           ,[CreatedById]  
           ,[CreatedTime]             
           ,[AssetId]  
		   ,[AdjustmentEntry]  
		   ,[IsLessorOwned]
		   ,[IsLeaseComponent])
	SELECT    
     @SourceModule 
     ,ContractId  
     ,CommencementDate  
     ,CommencementDate  
     ,CommencementDate  
     ,NBV_Amount - AVHDetails.OriginalCapitalizedAmount_Amount 
     ,NBV_Currency       
     ,NBV_Amount - AVHDetails.OriginalCapitalizedAmount_Amount
     ,NBV_Currency  
     ,NBV_Amount - AVHDetails.OriginalCapitalizedAmount_Amount 
     ,NBV_Currency  
     ,NBV_Amount - AVHDetails.OriginalCapitalizedAmount_Amount 
     ,NBV_Currency  
     ,NBV_Amount - AVHDetails.OriginalCapitalizedAmount_Amount 
     ,NBV_Currency  
     ,@IsAccounted  
     ,1  
     ,1  
     ,PostDate  
     ,@CreatedById 
     ,@CreatedTime  
     ,AVHDetails.AssetId  
     ,0  
     ,1  
     ,Asset.IsLeaseComponent
     FROM #AssetValueHistoryDetails AVHDetails
		   INNER JOIN Assets Asset ON AVHDetails.AssetId = Asset.Id
		   WHERE AVHDetails.IsNewlyAdded = 0 
		   AND (AVHDetails.OriginalCapitalizedAmount_Amount - AVHDetails.NBV_Amount <> 0.0)

 END

 IF OBJECT_ID('tempdb..#LeaseAssetTemp') IS NOT NULL
	DROP TABLE #LeaseAssetTemp;
 IF OBJECT_ID('tempdb..#AssetValueDetails') IS NOT NULL
	DROP TABLE #AssetValueDetails;
 IF OBJECT_ID('tempdb..#SKUValueDetails') IS NOT NULL
	DROP TABLE #SKUValueDetails;	
 IF OBJECT_ID('tempdb..#AssetSKUValueReversal') IS NOT NULL
	DROP TABLE #AssetSKUValueReversal;
 IF OBJECT_ID('tempdb..#OldCapitalizationValues') IS NOT NULL
	DROP TABLE #OldCapitalizationValues;
IF OBJECT_ID('tempdb..#InsertedAssetValueHistories') IS NOT NULL
	DROP TABLE #InsertedAssetValueHistories;
IF OBJECT_ID('tempdb..#AVHRecordsToBeUpdated') IS NOT NULL
	DROP TABLE #AVHRecordsToBeUpdated;
IF OBJECT_ID('tempdb..#SVPRecordsToBeUpdated') IS NOT NULL
	DROP TABLE #SVPRecordsToBeUpdated;
IF OBJECT_ID('tempdb..#AssetLocationDetails') IS NOT NULL
	DROP TABLE #AssetLocationDetails;
IF OBJECT_ID('tempdb..#AssetValueHistoryDetails') IS NOT NULL
	DROP TABLE #AssetValueHistoryDetails

SET NOCOUNT OFF
END

GO

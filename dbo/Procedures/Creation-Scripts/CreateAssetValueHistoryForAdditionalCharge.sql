SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


  
CREATE PROCEDURE [dbo].[CreateAssetValueHistoryForAdditionalCharge]  
(  
 @ContractId BIGINT,  
 @LeaseFinanceId BIGINT,  
 @CommencementDate DATETIME,  
 @SourceModule NVARCHAR(25),   
 @Rebook BIT,
 @CreatedById BIGINT,  
 @CreatedTime DATETIMEOFFSET  
   
)  
AS  
BEGIN  
SET NOCOUNT ON  
  
 CREATE TABLE #AssetValueDetails  
 (  
  AssetId BIGINT  
 ,Cost DECIMAL(16,2)  
 ,Currency NVARCHAR(3)  
 )  

 INSERT INTO #AssetValueDetails  
   (AssetId  
   ,Cost     
   ,Currency)  
 SELECT  
    Assets.Id  
   ,MAX(AssetValueHistories.Cost_Amount)  
   ,AssetValueHistories.Cost_Currency  
   FROM AssetValueHistories  
   JOIN Assets ON AssetValueHistories.AssetId = Assets.Id  
   JOIN LeaseAssets ON Assets.Id = LeaseAssets.AssetId  
   JOIN LeaseFinances ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id AND LeaseAssets.IsActive = 1 AND LeaseAssets.CapitalizedAdditionalCharge_Amount <> 0  
   JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id  
   WHERE   
   LeaseFinances.Id = @LeaseFinanceId   
   AND AssetValueHistories.IncomeDate <= LeaseFinanceDetails.CommencementDate  
   AND AssetValueHistories.IsSchedule=1  
   AND AssetValueHistories.IsLessorOwned = 1  
   GROUP BY Assets.Id, AssetValueHistories.Cost_Currency    
   
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
     ,LeaseFinance.ContractId  
     ,LeaseFinanceDetail.CommencementDate  
	 ,LeaseFinanceDetail.CommencementDate  
     ,LeaseFinanceDetail.CommencementDate  
     ,LeaseAsset.NBV_Amount  - LeaseAsset.PreviousCapitalizedAdditionalCharge_Amount
     ,LeaseAsset.NBV_Currency       
     ,LeaseAsset.NBV_Amount
     ,LeaseAsset.NBV_Currency  
     ,LeaseAsset.NBV_Amount
     ,LeaseAsset.NBV_Currency  
     ,LeaseAsset.PreviousCapitalizedAdditionalCharge_Amount  
     ,LeaseAsset.NBV_Currency  
     ,LeaseAsset.NBV_Amount  
     ,LeaseAsset.NBV_Currency  
     ,1  
     ,1  
     ,1  
     ,LeaseFinanceDetail.PostDate  
     ,@CreatedById  
     ,@CreatedTime  
     ,LeaseAsset.AssetId  
     ,0  
     ,1 
	 ,Asset.IsLeaseComponent
     FROM LeaseFinances LeaseFinance  
     INNER JOIN LeaseAssets LeaseAsset on LeaseFinance.Id = LeaseAsset.LeaseFinanceId AND LeaseAsset.IsActive = 1  
	 INNER JOIN Assets Asset on LeaseAsset.AssetId = Asset.Id
     INNER JOIN LeaseFinanceDetails LeaseFinanceDetail on LeaseFinance.Id = LeaseFinanceDetail.Id
	 INNER JOIN LeaseFinanceAdditionalCharges LAC on LAC.LeaseAssetId = LeaseAsset.Id	 	 
     WHERE LeaseFinance.Id = @LeaseFinanceId and LeaseAsset.IsActive=1 and LeaseAsset.IsAdditionalChargeSoftAsset=1 and LeaseAsset.NBV_Amount  - LeaseAsset.PreviousCapitalizedAdditionalCharge_Amount <> 0	

 IF @Rebook = 1
 BEGIN 

	 SELECT
		LeaseFinance.ContractId,
		LeaseAsset.Id LeaseAssetId,
		Assets.Id AssetId,
		LeaseAsset.NBV_Amount,
		LeaseAsset.NBV_Currency,
		LeaseAsset.PreviousCapitalizedAdditionalCharge_Amount,
		LeaseFinanceDetail.PostDate,
		LeaseFinanceDetail.CommencementDate,
		Assets.IsLeaseComponent
		INTO #InactiveAssets
	 FROM LeaseFinances LeaseFinance  
     INNER JOIN LeaseAssets LeaseAsset on LeaseFinance.Id = LeaseAsset.LeaseFinanceId AND LeaseAsset.IsActive = 0  
	 INNER JOIN Assets ON LeaseAsset.AssetId = Assets.Id
     INNER JOIN LeaseFinanceDetails LeaseFinanceDetail on LeaseFinance.Id = LeaseFinanceDetail.Id
	 INNER JOIN LeaseFinanceAdditionalCharges LAC on LAC.LeaseAssetId = LeaseAsset.Id	 
     WHERE LeaseFinance.Id = @LeaseFinanceId and LeaseAsset.IsActive=0 and LeaseAsset.IsAdditionalChargeSoftAsset=1 AND Assets.Status = 'Leased'


	 INSERT INTO AssetHistories
	 (
		 Reason
		,AsOfDate
		,AcquisitionDate
		,Status
		,FinancialType
		,SourceModule
		,SourceModuleId
		,CreatedById
		,CreatedTime
		,UpdatedById
		,UpdatedTime
		,CustomerId
		,ParentAssetId
		,LegalEntityId
		,ContractId
		,AssetId
		,PropertyTaxReportCodeId
		,IsReversed
	 )
	
	 SELECT 
		'StatusChange'
		,@CommencementDate
		,Assets.AcquisitionDate
		,'Scrap'
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
		,Assets.PropertyTaxReportCodeId
		,0
	 FROM 
	  #InactiveAssets
	  INNER JOIN Assets ON #InactiveAssets.AssetId = Assets.Id
	 UPDATE Assets
		SET Status = 'Scrap', UpdatedById = @CreatedById, UpdatedTime = @CreatedTime
			WHERE Id IN (SELECT AssetId FROM #InactiveAssets)

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
		 ,0 - NBV_Amount  
		 ,NBV_Currency       
		 ,0
		 ,NBV_Currency  
		 ,0
		 ,NBV_Currency  
		 ,NBV_Amount  
		 ,NBV_Currency  
		 ,0
		 ,NBV_Currency  
		 ,1  
		 ,1  
		 ,1  
		 ,PostDate  
		 ,@CreatedById  
		 ,@CreatedTime  
		 ,AssetId  
		 ,0  
		 ,1  
		 ,IsLeaseComponent
	 FROM 
	  #InactiveAssets

 END
 
SET NOCOUNT OFF  
END

GO

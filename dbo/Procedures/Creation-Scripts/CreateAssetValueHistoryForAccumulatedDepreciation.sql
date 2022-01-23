SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CreateAssetValueHistoryForAccumulatedDepreciation]
(
	@ContractId BIGINT,
	@LeaseFinanceId BIGINT,
	@CommencementDate DATETIME,
	@SourceModule NVARCHAR(25),	
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
			JOIN LeaseFinances ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id AND LeaseAssets.IsActive = 1 AND LeaseAssets.AccumulatedDepreciation_Amount <> 0
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
           ,LeaseFinance.Id
		   ,LeaseFinanceDetail.CommencementDate
		   ,LeaseFinanceDetail.CommencementDate
		   ,LeaseFinanceDetail.CommencementDate
		   ,LeaseAsset.AccumulatedDepreciation_Amount * (-1)
		   ,LeaseAsset.AccumulatedDepreciation_Currency	   
		   ,#AssetValueDetails.Cost 
		   ,#AssetValueDetails.Currency
		   ,(LeaseAsset.NBV_Amount - LeaseAsset.ETCAdjustmentAmount_Amount - LeaseAsset.AccumulatedDepreciation_Amount)
		   ,LeaseAsset.NBV_Currency
		    ,LeaseAsset.NBV_Amount - LeaseAsset.ETCAdjustmentAmount_Amount
		   ,LeaseAsset.NBV_Currency
		   ,(LeaseAsset.NBV_Amount - LeaseAsset.ETCAdjustmentAmount_Amount - LeaseAsset.AccumulatedDepreciation_Amount)
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
		   INNER JOIN LeaseAssets LeaseAsset ON LeaseFinance.Id = LeaseAsset.LeaseFinanceId AND LeaseAsset.IsActive = 1 AND LeaseAsset.AccumulatedDepreciation_Amount <> 0
		   INNER JOIN LeaseFinanceDetails LeaseFinanceDetail ON LeaseFinance.Id = LeaseFinanceDetail.Id
		   INNER JOIN Assets Asset ON LeaseAsset.AssetId = Asset.Id
		   INNER JOIN #AssetValueDetails ON Asset.Id = #AssetValueDetails.AssetId
		   WHERE LeaseFinance.Id = @LeaseFinanceId AND LeaseAsset.IsNewlyAdded = 1


	UPDATE dbo.AssetIncomeSchedules 

	SET 
		OperatingBeginNetBookValue_Amount = AVH.BeginBookValue_Amount,
		OperatingEndNetBookValue_Amount = AVH.EndBookValue_Amount,
		Depreciation_Amount = AVH.Value_Amount

	FROM  dbo.AssetIncomeSchedules AIS
		  INNER JOIN dbo.LeaseIncomeSchedules LISE ON AIS.LeaseIncomeScheduleId = LISE.Id
		  INNER JOIN dbo.AssetValueHistories AVH ON LISE.IncomeDate = AVH.IncomeDate 

	WHERE LISE.LeaseFinanceId = @LeaseFinanceId 
			AND AIS.IsActive = 1 
			AND AVH.SourceModuleId = @LeaseFinanceId
			AND AVH.AssetId = AIS.AssetId
			AND AVH.IsLessorOwned = 1
			AND AVH.SourceModule = @SourceModule
			AND LISE.AdjustmentEntry = 0
			AND LISE.IncomeDate = @CommencementDate
			

	UPDATE dbo.LeaseIncomeSchedules 

	SET 
		OperatingBeginNetBookValue_Amount = LIS.OperatingBeginNetBookValue_Amount,
		OperatingEndNetBookValue_Amount = LIS.OperatingEndNetBookValue_Amount,
		Depreciation_Amount = LIS.Depreciation_Amount

	FROM (
		SELECT 
		AIS.LeaseIncomeScheduleId,
		SUM(AIS.OperatingBeginNetBookValue_Amount) [OperatingBeginNetBookValue_Amount],
		SUM(AIS.OperatingEndNetBookValue_Amount) [OperatingEndNetBookValue_Amount] ,
		SUM(AIS.Depreciation_Amount) [Depreciation_Amount] 
		FROM dbo.AssetIncomeSchedules AIS
		   INNER JOIN dbo.LeaseIncomeSchedules LISE ON AIS.LeaseIncomeScheduleId = LISE.Id
		WHERE LISE.LeaseFinanceId = @LeaseFinanceId 
			AND AIS.IsActive = 1 
			AND LISE.AdjustmentEntry = 0
			AND LISE.IncomeDate = @CommencementDate
		GROUP BY AIS.LeaseIncomeScheduleId
		   ) AS LIS
	WHERE LeaseIncomeSchedules.Id = LIS.LeaseIncomeScheduleId
	AND LeaseIncomeSchedules.AdjustmentEntry = 0
	AND LeaseIncomeSchedules.IncomeDate = @CommencementDate

	
DROP TABLE #AssetValueDetails

SET NOCOUNT OFF
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[CreateFixedTermBookDepreciations]
(
	@LeaseFinanceId BIGINT ,
	@CreatedById BIGINT,
	@CreatedTime DATETIMEOFFSET,
	@NumberOfDays INT,
	@ParticipationPercentage DECIMAL(18,2),
	@BeginDate DATETIME,
	@NBVHolderForRestructure AssetNBVHolderForRestructure READONLY,
	@ETC BIT =0,
	@IsNonInceptionRestructure BIT= 0,
	@ShouldConsiderAccumulatedDepreciation BIT = 1,
	@IsFASBApplicable BIT,
	@IsLessorOwned BIT = 1,
	@IsSKUEnabled BIT
)
AS
BEGIN
SET NOCOUNT ON
	DECLARE @IsForSubsetOfAssets BIT = (SELECT CONVERT(BIT, (CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END)) FROM @NBVHolderForRestructure);

	SELECT  LeaseFinances.Id LeaseFinanceId,
			LeaseFinanceDetails.MaturityDate,
			LeaseFinanceDetails.LeaseBookingGLTemplateId,
			LeaseFinances.InstrumentTypeId,
			Contracts.LineofBusinessId,
			Contracts.CostCenterId,
			Contracts.Id ContractId
	INTO #ContractDetails
	FROM LeaseFinances
	INNER JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id AND LeaseFinances.Id = @LeaseFinanceId
	INNER JOIN Contracts ON LeaseFinances.ContractId = Contracts.Id
	
	CREATE CLUSTERED INDEX IX_LeaseFinanceId ON #ContractDetails(LeaseFinanceId);

	IF (@IsForSubsetOfAssets = 0)
	BEGIN

	CREATE TABLE #AssetInfo
	(
		LeaseAssetId BIGINT,
		LeaseFinanceId BIGINT,
		IsLeaseComponent BIT,
		IsLeaseAsset BIT,
		RemainingAmount decimal(16,2),
		AssetId BIGINT,
	    Currency NVARCHAR(5),
		NBV_Total decimal(16,2),
		Salvage_Amount decimal(16,2),
		Factor NVARCHAR(100)
	) 

	INSERT INTO #AssetInfo
	SELECT
	LeaseAssetSKUs.LeaseAssetId,
	LeaseAssets.LeaseFinanceId,
	CAST(1 as bit) IsLeaseComponent,
	LeaseAssets.IsLeaseAsset,
	(LeaseAssets.NBV_Amount - LeaseAssets.AccumulatedDepreciation_Amount) RemainingAmount,
	LeaseAssets.AssetId,
	LeaseAssets.NBV_Currency Currency,
	ROUND(SUM(LeaseAssetSKUs.NBV_Amount)-SUM(LeaseAssetSKUs.ETCAdjustmentAmount_Amount)- (CASE WHEN @ShouldConsiderAccumulatedDepreciation = 1 THEN SUM(LeaseAssetSKUs.AccumulatedDepreciation_Amount) ELSE 0.0 END) * @ParticipationPercentage,2) ,
	ROUND(SUM(LeaseAssetSKUs.BookedResidual_Amount) * @ParticipationPercentage,2),
	(ROUND((SUM(LeaseAssetSKUs.NBV_Amount) - SUM(LeaseAssetSKUs.ETCAdjustmentAmount_Amount) - (CASE WHEN @ShouldConsiderAccumulatedDepreciation = 1 THEN SUM(LeaseAssetSKUs.AccumulatedDepreciation_Amount) ELSE 0.0 END)) * @ParticipationPercentage,2) - ROUND(SUM(LeaseAssetSKUs.BookedResidual_Amount) * @ParticipationPercentage,2))/@NumberOfDays
	FROM		
	#ContractDetails
	JOIN LeaseAssets ON #ContractDetails.LeaseFinanceId = LeaseAssets.LeaseFinanceId AND LeaseAssets.IsActive = 1
	INNER JOIN LeaseAssetSKUs ON LeaseAssetSKUs.LeaseAssetId=LeaseAssets.Id
	 AND LeaseAssetSkus.IsActive=1 AND LeaseAssetSKUs.IsLeaseComponent=1
	GROUP BY LeaseAssetSKUs.LeaseAssetId, LeaseAssets.LeaseFinanceId, LeaseAssets.IsLeaseAsset, LeaseAssets.NBV_Amount, LeaseAssets.AccumulatedDepreciation_Amount, LeaseAssets.AssetId, LeaseAssets.NBV_Currency
	
	INSERT INTO #AssetInfo
	SELECT 
	LeaseAssets.Id,
	LeaseAssets.LeaseFinanceId,
	LeaseAssets.IsLeaseAsset IsLeaseComponent,
	LeaseAssets.IsLeaseAsset,
	(LeaseAssets.NBV_Amount - LeaseAssets.AccumulatedDepreciation_Amount) RemainingAmount,
	LeaseAssets.AssetId,
	LeaseAssets.NBV_Currency Currency,
	ROUND(LeaseAssets.NBV_Amount-LeaseAssets.ETCAdjustmentAmount_Amount- (CASE WHEN @ShouldConsiderAccumulatedDepreciation = 1 THEN LeaseAssets.AccumulatedDepreciation_Amount ELSE 0.0 END) * @ParticipationPercentage,2),
	ROUND(LeaseAssets.BookedResidual_Amount * @ParticipationPercentage,2),
	--Changing from TotalAmount to Factor field to match the regression values of 6 decimals and last 2 decimals as 0
	(ROUND((LeaseAssets.NBV_Amount - LeaseAssets.ETCAdjustmentAmount_Amount - (CASE WHEN @ShouldConsiderAccumulatedDepreciation = 1 THEN LeaseAssets.AccumulatedDepreciation_Amount ELSE 0.0 END)) * @ParticipationPercentage,2) - ROUND(LeaseAssets.BookedResidual_Amount * @ParticipationPercentage,2))/@NumberOfDays
	FROM LeaseAssets
	LEFT JOIN (SELECT LeaseAssetId FROM 
	#ContractDetails
	JOIN LeaseAssets ON #ContractDetails.LeaseFinanceId = LeaseAssets.LeaseFinanceId AND LeaseAssets.IsActive = 1
	INNER JOIN LeaseAssetSKUs ON LeaseAssetSKUs.LeaseAssetId=LeaseAssets.Id
	 AND LeaseAssetSkus.IsActive=1) LeaseAssetWithSKU ON LeaseAssets.Id = LeaseAssetWithSKU.LeaseAssetId
	Where LeaseAssets.IsActive = 1 AND
	LeaseAssets.LeaseFinanceId = @LeaseFinanceId AND LeaseAssetWithSKU.LeaseAssetId IS NULL


		INSERT INTO BookDepreciations
		(
			AssetId,
			CostBasis_Amount,
			CostBasis_Currency,
			Salvage_Amount,
			Salvage_Currency,
			BeginDate,
			EndDate,
			GLTemplateId,
			InstrumentTypeId,
			LineofBusinessId,
			CostCenterId,
			ContractId,
			IsActive,
			RemainingLifeInMonths,
			IsInOTP,
			PerDayDepreciationFactor,
			CreatedById,
			CreatedTime,
			IsLessorOwned,
			IsLeaseComponent
		)
		SELECT
			#AssetInfo.AssetId,
			#AssetInfo.NBV_Total,
			#AssetInfo.Currency,
			#AssetInfo.Salvage_Amount,
			#AssetInfo.Currency,
			@BeginDate,			
			#ContractDetails.MaturityDate,
			#ContractDetails.LeaseBookingGLTemplateId,
			#ContractDetails.InstrumentTypeId,
			#ContractDetails.LineofBusinessId,
			#ContractDetails.CostCenterId,
			#ContractDetails.ContractId,
			1,
			0,
			0,
			#AssetInfo.Factor,
			@CreatedById,
			@CreatedTime,
			@IsLessorOwned,
			#AssetInfo.IsLeaseComponent
		FROM		
		#AssetInfo 
		INNER JOIN #ContractDetails ON #AssetInfo.LeaseFinanceId = #ContractDetails.LeaseFinanceId 
		WHERE (@ShouldConsiderAccumulatedDepreciation = 0 OR (#AssetInfo.RemainingAmount) <> 0.0) AND (@IsFASBApplicable = 0 OR #AssetInfo.IsLeaseAsset = 1 OR @IsSKUEnabled = 1) AND #AssetInfo.IsLeaseComponent = 1
	END

	ELSE
	BEGIN
	CREATE TABLE #PerDayFactor
	(
		LeaseAssetId BIGINT,
		Factor NVARCHAR(100),
		CostBasisAmount decimal(16,2),
		AssetNBV_Amount decimal(19,2),
		BeginDate Date
	)
	CREATE TABLE #LeaseAssetDetails
	(
		LeaseAssetId BIGINT,
		AssetId BIGINT,
		LeaseFinanceId BIGINT,
		RemainingAmount decimal(16,2),
		AccumulatedDepreciation decimal(16,2),
		BookedResidual decimal(16,2),
		LeaseAssetBookedResidual decimal(16,2),
		IsLeaseComponent BIT,
		IsLeaseAsset BIT,
		IsNewlyAdded BIT,
		Currency NVARCHAR(5)
	)

	CREATE TABLE #AssetNBV
	(
		LeaseAssetId BIGINT,
		NBV_Total decimal(16,2)
	) 

	INSERT INTO #AssetNBV
	SELECT
	LeaseAssetSKUs.LeaseAssetId,
	ROUND(SUM(LeaseAssetSKUs.NBV_Amount)-SUM(LeaseAssetSKUs.ETCAdjustmentAmount_Amount)- (CASE WHEN @ShouldConsiderAccumulatedDepreciation = 1 THEN SUM(LeaseAssetSKUs.AccumulatedDepreciation_Amount) ELSE 0.0 END) * @ParticipationPercentage,2)
	FROM		
	#ContractDetails
	JOIN LeaseAssets ON #ContractDetails.LeaseFinanceId = LeaseAssets.LeaseFinanceId AND LeaseAssets.IsActive = 1 AND LeaseAssets.IsNewlyAdded=1
	INNER JOIN LeaseAssetSKUs ON LeaseAssetSKUs.LeaseAssetId=LeaseAssets.Id	AND
	LeaseAssetSkus.IsActive=1 AND LeaseAssetSKUs.IsLeaseComponent=1 
	GROUP BY LeaseAssetSKUs.LeaseAssetId
	
	INSERT INTO #AssetNBV
	SELECT 
	LeaseAssets.Id,
	ROUND(LeaseAssets.NBV_Amount-LeaseAssets.ETCAdjustmentAmount_Amount- (CASE WHEN @ShouldConsiderAccumulatedDepreciation = 1 THEN LeaseAssets.AccumulatedDepreciation_Amount ELSE 0.0 END) * @ParticipationPercentage,2)
	FROM LeaseAssets
	LEFT JOIN (SELECT LeaseAssetId FROM 
	#ContractDetails
	JOIN LeaseAssets ON #ContractDetails.LeaseFinanceId = LeaseAssets.LeaseFinanceId AND LeaseAssets.IsActive = 1
	INNER JOIN LeaseAssetSKUs ON LeaseAssetSKUs.LeaseAssetId=LeaseAssets.Id
	 AND LeaseAssetSkus.IsActive=1 AND LeaseAssets.IsNewlyAdded=1) LeaseAssetWithSKU ON LeaseAssets.Id = LeaseAssetWithSKU.LeaseAssetId
	Where LeaseAssets.IsActive = 1 AND LeaseAssets.IsNewlyAdded=1 AND
	LeaseAssets.LeaseFinanceId = @LeaseFinanceId AND LeaseAssetWithSKU.LeaseAssetId IS NULL	

	INSERT INTO #LeaseAssetDetails
	SELECT LeaseAssetSKUs.LeaseAssetId,
	LeaseAssets.AssetId,
	LeaseAssets.LeaseFinanceId,
	(LeaseAssets.NBV_Amount - LeaseAssets.AccumulatedDepreciation_Amount) RemainingAmount,
	SUM(LeaseAssetSKUs.AccumulatedDepreciation_Amount) AccumulatedDepreciation,
	SUM(LeaseAssetSKUs.BookedResidual_Amount) BookedResidual,
	LeaseAssets.BookedResidual_Amount LeaseAssetBookedResidual,
	LeaseAssetSKUs.IsLeaseComponent,
	LeaseAssets.IsLeaseAsset,
	LeaseAssets.IsNewlyAdded,
	LeaseAssets.NBV_Currency Currency
	FROM 
	#ContractDetails
	JOIN LeaseAssets ON #ContractDetails.LeaseFinanceId = LeaseAssets.LeaseFinanceId AND LeaseAssets.IsActive = 1
	INNER JOIN LeaseAssetSKUs ON LeaseAssets.Id = LeaseAssetSKUs.LeaseAssetId AND LeaseAssetSKUs.IsLeaseComponent=1
	GROUP BY LeaseAssetSKUs.LeaseAssetId,LeaseAssetSKUs.IsLeaseComponent, LeaseAssets.AssetId, LeaseAssets.IsNewlyAdded, LeaseAssets.IsLeaseAsset, LeaseAssets.NBV_Currency, LeaseAssets.LeaseFinanceId, LeaseAssets.NBV_Amount, LeaseAssets.AccumulatedDepreciation_Amount, LeaseAssets.BookedResidual_Amount
	
	INSERT INTO #LeaseAssetDetails 
	SELECT LeaseAssets.Id, 
	LeaseAssets.AssetId, 
	LeaseAssets.LeaseFinanceId,
	(LeaseAssets.NBV_Amount - LeaseAssets.AccumulatedDepreciation_Amount) RemainingAmount,
	LeaseAssets.AccumulatedDepreciation_Amount AccumulatedDepreciation, 
	LeaseAssets.BookedResidual_Amount BookedResidual, 
	LeaseAssets.BookedResidual_Amount LeaseAssetBookedResidual,
	LeaseAssets.IsLeaseAsset,
	LeaseAssets.IsLeaseAsset,
	LeaseAssets.IsNewlyAdded,
	LeaseAssets.NBV_Currency Currency
	FROM 
	#ContractDetails
	JOIN LeaseAssets ON #ContractDetails.LeaseFinanceId = LeaseAssets.LeaseFinanceId AND LeaseAssets.IsActive = 1 AND LeaseAssets.IsLeaseAsset=1
	INNER JOIN Assets ON LeaseAssets.AssetId = Assets.Id AND Assets.IsSKU=0

	
	INSERT INTO #PerDayFactor
	SELECT #LeaseAssetDetails.LeaseAssetId,
	CASE WHEN @IsNonInceptionRestructure =0 THEN (((ROUND(NBV_Total - (#LeaseAssetDetails.AccumulatedDepreciation * @ParticipationPercentage),2)) - (ROUND(#LeaseAssetDetails.BookedResidual * @ParticipationPercentage,2)))/NBVHolder.NumberOfDays)
			ELSE (((ROUND(NBV_Total,2)) - (ROUND(#LeaseAssetDetails.BookedResidual * @ParticipationPercentage,2)))/NBVHolder.NumberOfDays)END,
	CASE WHEN @IsNonInceptionRestructure =0 THEN ROUND(NBV_Total - (#LeaseAssetDetails.AccumulatedDepreciation * @ParticipationPercentage),2)
			ELSE ROUND(NBV_Total,2) END CostBasisAmount,
	NBVHolder.AssetNBV_Amount,
	NBVHolder.BeginDate
	FROM
	#LeaseAssetDetails
	INNER JOIN @NBVHolderForRestructure NBVHolder ON #LeaseAssetDetails.AssetId = NBVHolder.AssetId
	INNER JOIN #AssetNBV ON #LeaseAssetDetails.LeaseAssetId = #AssetNBV.LeaseAssetId

	INSERT INTO #PerDayFactor
	SELECT #LeaseAssetDetails.LeaseAssetId,
	CASE WHEN @IsNonInceptionRestructure =0 THEN (((ROUND(NBVHolder.AssetNBV_Amount - (#LeaseAssetDetails.AccumulatedDepreciation * @ParticipationPercentage),2)) - (ROUND(#LeaseAssetDetails.BookedResidual * @ParticipationPercentage,2)))/NBVHolder.NumberOfDays)
			ELSE (((ROUND(NBVHolder.AssetNBV_Amount,2)) - (ROUND(#LeaseAssetDetails.BookedResidual * @ParticipationPercentage,2)))/NBVHolder.NumberOfDays)END,
	CASE WHEN @IsNonInceptionRestructure =0 THEN ROUND(NBVHolder.AssetNBV_Amount - (#LeaseAssetDetails.AccumulatedDepreciation * @ParticipationPercentage),2)
			ELSE ROUND(NBVHolder.AssetNBV_Amount,2) END CostBasisAmount,
	NBVHolder.AssetNBV_Amount,
	NBVHolder.BeginDate
	FROM
	#LeaseAssetDetails
	INNER JOIN @NBVHolderForRestructure NBVHolder ON #LeaseAssetDetails.AssetId = NBVHolder.AssetId
	WHERE #LeaseAssetDetails.IsNewlyAdded = 0

		INSERT INTO BookDepreciations
		(
			AssetId,
			CostBasis_Amount,
			CostBasis_Currency,
			Salvage_Amount,
			Salvage_Currency,
			BeginDate,
			EndDate,
			GLTemplateId,
			InstrumentTypeId,
			LineofBusinessId,
			CostCenterId,
			ContractId,
			IsActive,
			RemainingLifeInMonths,
			IsInOTP,
			PerDayDepreciationFactor,
			CreatedById,
			CreatedTime,
			IsLessorOwned,
			IsLeaseComponent
		)
		SELECT
			#LeaseAssetDetails.AssetId,
			#PerDayFactor.CostBasisAmount,
			#LeaseAssetDetails.Currency,
			ROUND(#LeaseAssetDetails.BookedResidual * @ParticipationPercentage,2),
			#LeaseAssetDetails.Currency,
			#PerDayFactor.BeginDate,
			#ContractDetails.MaturityDate,
			#ContractDetails.LeaseBookingGLTemplateId,
			#ContractDetails.InstrumentTypeId,
			#ContractDetails.LineofBusinessId,
			#ContractDetails.CostCenterId,
			#ContractDetails.ContractId,
			1,
			0,
			0,
			#PerDayFactor.Factor,
			@CreatedById,
			@CreatedTime,
			@IsLessorOwned,
			#LeaseAssetDetails.IsLeaseComponent
		FROM #LeaseAssetDetails
		INNER JOIN #PerDayFactor ON #LeaseAssetDetails.LeaseAssetId = #PerDayFactor.LeaseAssetId
		INNER JOIN #ContractDetails ON #LeaseAssetDetails.LeaseFinanceId = #ContractDetails.LeaseFinanceId AND		   
				   (@IsFASBApplicable = 0 OR #LeaseAssetDetails.IsLeaseAsset = 1 OR @IsSKUEnabled = 1)
		WHERE (((@IsNonInceptionRestructure = 0 AND #LeaseAssetDetails.RemainingAmount <> 0.0) OR @IsNonInceptionRestructure = 1) AND #PerDayFactor.AssetNBV_Amount <> 0)
	END

	IF OBJECT_ID('tempdb..#AssetInfo') IS NOT NULL
		DROP TABLE #AssetInfo
	IF OBJECT_ID('tempdb..#AssetNBV') IS NOT NULL
		DROP TABLE #AssetNBV
	IF OBJECT_ID('tempdb..#LeaseAssetDetails') IS NOT NULL
		DROP TABLE #LeaseAssetDetails
	IF OBJECT_ID('tempdb..#PerDayFactor') IS NOT NULL
		DROP TABLE #PerDayFactor
	IF OBJECT_ID('tempdb..#ContractDetails') IS NOT NULL
		DROP TABLE #ContractDetails
END

GO

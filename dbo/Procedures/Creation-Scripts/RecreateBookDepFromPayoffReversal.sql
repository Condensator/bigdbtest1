SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[RecreateBookDepFromPayoffReversal]
(
	@LeaseFinanceId BIGINT,
	@CreatedById BIGINT,
	@CreatedTime DATETIMEOFFSET,
	@ParticipationPercentage DECIMAL(18,2),
	@AssetNBVHolder AssetNBVHolder READONLY,
	@IsPayOffAtInception BIT,
	@IsFASBApplicable BIT,
	@IsLessorOwned BIT = 1
)
AS

BEGIN
	
	SET NOCOUNT ON;

	CREATE TABLE #AssetInfo
	(
	    AssetId BIGINT,
		LeaseAssetId BIGINT,
		IsLeaseComponent BIT,
		CostBasis_Amount decimal(16,2),
		Salvage_Amount  decimal(16,2),
		PerDayDepreciationFactor decimal(18,8),
		Currency nvarchar(3),
		LeaseFinanceId BIGINT
	) 
	

	INSERT INTO #AssetInfo
	---For Assets with SKUs
	SELECT
	NBVHolder.AssetId,
	LeaseAssetSKUs.LeaseAssetId,
	LeaseAssetSKUs.IsLeaseComponent,
	CASE WHEN @IsPayOffAtInception = 1 THEN ROUND(NBVHolder.AssetNBV_Amount - 
	(SUM(LeaseAssetSKUs.AccumulatedDepreciation_Amount) * @ParticipationPercentage),2)
			 ELSE ROUND(NBVHolder.AssetNBV_Amount,2) END,

    ROUND(SUM(LeaseAssetSKUs.BookedResidual_Amount) * @ParticipationPercentage,2),

	CASE WHEN @IsPayOffAtInception =0 THEN 
		(((ROUND(NBVHolder.AssetNBV_Amount - (SUM(LeaseAssetSKUs.AccumulatedDepreciation_Amount) * @ParticipationPercentage),2)) 
		- (ROUND(SUM(LeaseAssetSKUs.BookedResidual_Amount) * @ParticipationPercentage,2)))/NBVHolder.NumberOfDays)
			 ELSE (((ROUND(NBVHolder.AssetNBV_Amount,2)) - 
			 (ROUND(SUM(LeaseAssetSKUs.BookedResidual_Amount) * @ParticipationPercentage,2)))/NBVHolder.NumberOfDays)
		END,
		LeaseAssets.NBV_Currency,
		@LeaseFinanceId

	FROM		
	LeaseAssets 
	INNER JOIN @AssetNBVHolder NBVHolder ON LeaseAssets.AssetId = NBVHolder.AssetId AND
	 (@IsFASBApplicable = 0 OR NBVHolder.IsLeaseComponent = 1)
	 INNER JOIN LeaseAssetSKUs ON LeaseAssets.Id = LeaseAssetSKUs.LeaseAssetId 
	 AND (LeaseAssetSKUs.IsLeaseComponent = 1 OR @IsFASBApplicable = 0)
	 WHERE NBVHolder.AssetNBV_Amount <> 0 
	 AND LeaseAssets.LeaseFinanceId = @LeaseFinanceId
	GROUP BY LeaseAssetSKUs.LeaseAssetId,NBVHolder.AssetNBV_Amount,NBVHolder.NumberOfDays,NBVHolder.AssetId,LeaseAssets.NBV_Currency,LeaseAssetSKUs.IsLeaseComponent

	UNION

	---For Assets without SKUs
	SELECT
	LeaseAssets.AssetId,
	LeaseAssets.Id,
	LeaseAssets.IsLeaseAsset,
	--LeaseAssets.AccumulatedDepreciation_Amount,
	--LeaseAssets.BookedResidual_Amount
	CASE WHEN @IsPayOffAtInception = 1 THEN ROUND(NBVHolder.AssetNBV_Amount - (LeaseAssets.AccumulatedDepreciation_Amount * @ParticipationPercentage),2)
			 ELSE ROUND(NBVHolder.AssetNBV_Amount,2) END,
   
   ROUND(LeaseAssets.BookedResidual_Amount * @ParticipationPercentage,2),

   CASE WHEN @IsPayOffAtInception =0 THEN 
		(((ROUND(NBVHolder.AssetNBV_Amount - (LeaseAssets.AccumulatedDepreciation_Amount * @ParticipationPercentage),2)) 
		- (ROUND(LeaseAssets.BookedResidual_Amount * @ParticipationPercentage,2)))/NBVHolder.NumberOfDays)
			 ELSE (((ROUND(NBVHolder.AssetNBV_Amount,2)) -
			 (ROUND(LeaseAssets.BookedResidual_Amount * @ParticipationPercentage,2)))/NBVHolder.NumberOfDays)
		END,
		LeaseAssets.NBV_Currency,
		@LeaseFinanceId

	FROM		
	LeaseAssets 
	INNER JOIN @AssetNBVHolder NBVHolder ON LeaseAssets.AssetId = NBVHolder.AssetId AND
	 (@IsFASBApplicable = 0 OR NBVHolder.IsLeaseComponent = 1)
	 INNER JOIN Assets ON LeaseAssets.AssetId = Assets.Id AND Assets.IsSKU = 0
	 WHERE NBVHolder.AssetNBV_Amount <> 0 
	 AND LeaseAssets.LeaseFinanceId = @LeaseFinanceId

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
		#AssetInfo.CostBasis_Amount,
		#AssetInfo.Currency,
		#AssetInfo.Salvage_Amount,
		#AssetInfo.Currency,
		NBVHolder.BeginDate,
		LeaseFinanceDetails.MaturityDate,
		LeaseFinanceDetails.LeaseBookingGLTemplateId,
		LeaseFinances.InstrumentTypeId,
		Contracts.LineofBusinessId,
		Contracts.CostCenterId,
		Contracts.Id,
		1,
		0,
		0,
		#AssetInfo.PerDayDepreciationFactor,
		@CreatedById,
		@CreatedTime,
		@IsLessorOwned,
	    NBVHolder.IsLeaseComponent
		FROM
     	LeaseFinances 
	 INNER JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
	 INNER JOIN Contracts ON LeaseFinances.ContractId = Contracts.Id
	 INNER JOIN #AssetInfo ON LeaseFinances.Id = #AssetInfo.LeaseFinanceId
	 INNER JOIN @AssetNBVHolder NBVHolder ON #AssetInfo.AssetId = NBVHolder.AssetId AND #AssetInfo.IsLeaseComponent = NBVHolder.IsLeaseComponent 

    IF OBJECT_ID('tempdb..#AssetInfo') IS NOT NULL
    DROP TABLE #AssetInfo
END

GO

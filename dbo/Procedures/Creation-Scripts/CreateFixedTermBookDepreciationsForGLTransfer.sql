SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CreateFixedTermBookDepreciationsForGLTransfer]
(
	@LeaseFinanceId BIGINT,
	@CreatedById BIGINT,
	@CreatedTime DATETIMEOFFSET,
	@NumberOfDays INT,
	@ParticipationPercentage DECIMAL(18,8),
	@BeginDate DATETIME,
	@IncomeDate DATETIME,
	@LineofBusinessId BIGINT,
	@CostCenterId BIGINT,
	@InstrumentTypeId BIGINT,
	@ETC BIT = 0
)
AS
BEGIN
SET NOCOUNT ON

	CREATE TABLE #AssetEndNBVDetails
	(
		AssetId BIGINT
	    ,Amount DECIMAL(16,2)
		,IsLessorOwned bit
	)

	CREATE TABLE #AVHSyndicationRecords
	(
		AssetId BIGINT
		,BeginBookValue DECIMAL(16,2)
	    ,EndBookValueAmount DECIMAL(16,2)
	)

	SELECT AVH.AssetId
	,AVH.EndBookValue_Amount
	,AVH.BeginBookValue_Amount
	,AVH.IsLessorOwned,
	AVH.SourceModule
	,ROW_NUMBER() OVER(PARTITION BY AVH.AssetId,AVH.IsLessorOwned  ORDER BY (AVH.IncomeDate) DESC, (AVH.Id) DESC) AS RowNumber 
	into #AssetValues
	FROM dbo.LeaseFinances LF
	INNER JOIN dbo.LeaseAssets LA ON LA.LeaseFinanceId = LF.Id AND LA.IsActive = 1 AND LA.NBV_Amount <> 0.0
	INNER JOIN dbo.AssetValueHistories AVH ON avh.AssetId = la.AssetId
	WHERE 
	LF.Id =@LeaseFinanceId 
	AND AVH.IsLeaseComponent = 1
	AND AVH.IsSchedule = 1 
	AND AVH.IncomeDate <= @IncomeDate  

	INSERT INTO #AssetEndNBVDetails
	SELECT 
		av.AssetId
		,av.EndBookValue_Amount
		,av.IsLessorOwned
	FROM 
		#AssetValues av
	WHERE 
		av.RowNumber = 1
		GROUP BY av.AssetId,av.IsLessorOwned,av.EndBookValue_Amount 

	INSERT INTO #AVHSyndicationRecords
	SELECT
	 AV.AssetId
	,AV.BeginBookValue_Amount
	,AV.EndBookValue_Amount
	FROM
	#AssetValues AV
	WHERE 
	AV.SourceModule = 'Syndications'

	SELECT 
	LeaseAssetSKUs.LeaseAssetId ,
	SUM(LeaseAssetSKUs.BookedResidual_Amount ) BookedResidual_Amount
	INTO #LeaseAssetSKUInfo
	FROM LeaseAssets
	JOIN LeaseAssetSKUs ON LeaseAssets.Id= LeaseAssetSKUs.LeaseAssetId
	AND LeaseAssets.LeaseFinanceId =@LeaseFinanceId 
	AND LeaseAssets.IsActive =1
	AND LeaseAssetSKUs.IsActive =1
	AND LeaseAssetSKUs.IsLeaseComponent =1
	GROUP BY LeaseAssetSKUs.LeaseAssetId 

	IF ((select Count(*) from #AssetEndNBVDetails where IsLessorOwned=0) = 0 and (select Count (*) from #AVHSyndicationRecords) <> 0)
	BEGIN	
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
		av.AssetId,
		av.BeginBookValue,
		LeaseAssets.NBV_Currency,
		CASE WHEN lsbr.LeaseAssetId is null THEN  LeaseAssets.BookedResidual_Amount ELSE lsbr.BookedResidual_Amount END,
		LeaseAssets.BookedResidual_Currency,
		@BeginDate,
		LeaseFinanceDetails.MaturityDate,
		LeaseFinanceDetails.LeaseBookingGLTemplateId,
		@InstrumentTypeId,
		@LineofBusinessId,
		@CostCenterId,
		LeaseFinances.ContractId,
		1,
		0,
		0,
		((av.BeginBookValue - (CASE WHEN lsbr.LeaseAssetId is null THEN LeaseAssets.BookedResidual_Amount ELSE lsbr.BookedResidual_Amount END))/@NumberOfDays),
		@CreatedById,
		@CreatedTime,
		0,
		Assets.IsLeaseComponent

	FROM LeaseAssets
	INNER JOIN Assets ON LeaseAssets.AssetId = Assets.Id
	INNER JOIN LeaseFinances ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id AND		   
				LeaseAssets.IsActive = 1 AND
				LeaseFinances.Id = @LeaseFinanceId AND
				LeaseAssets.NBV_Amount <> 0.0 AND
				LeaseAssets.IsLeaseAsset = 1
	INNER JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
	INNER JOIN #AVHSyndicationRecords av ON dbo.LeaseAssets.AssetId = av.AssetId
	LEFT JOIN #LeaseAssetSKUInfo lsbr ON LeaseAssets.Id = lsbr.LeaseAssetId
	WHERE av.BeginBookValue <> 0.0

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
		av.AssetId,
		av.EndBookValueAmount,
		LeaseAssets.NBV_Currency,
		ROUND((	CASE WHEN lsbr.LeaseAssetId is null THEN LeaseAssets.BookedResidual_Amount ELSE lsbr.BookedResidual_Amount END) * @ParticipationPercentage,2),
		LeaseAssets.BookedResidual_Currency,
		@BeginDate,
		LeaseFinanceDetails.MaturityDate,
		LeaseFinanceDetails.LeaseBookingGLTemplateId,
		@InstrumentTypeId,
		@LineofBusinessId,
		@CostCenterId,
		LeaseFinances.ContractId,
		1,
		0,
		0,
		((av.EndBookValueAmount - (ROUND((	CASE WHEN lsbr.LeaseAssetId is null THEN LeaseAssets.BookedResidual_Amount ELSE lsbr.BookedResidual_Amount END) * @ParticipationPercentage,2)))/@NumberOfDays),
		@CreatedById,
		@CreatedTime,
		1,
		Assets.IsLeaseComponent

	FROM LeaseAssets
	INNER JOIN Assets ON LeaseAssets.AssetId = Assets.Id
	INNER JOIN LeaseFinances ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id AND		   
				LeaseAssets.IsActive = 1 AND
				LeaseFinances.Id = @LeaseFinanceId AND
				LeaseAssets.NBV_Amount <> 0.0 AND 
				LeaseAssets.IsLeaseAsset = 1
	INNER JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
	INNER JOIN #AVHSyndicationRecords av ON dbo.LeaseAssets.AssetId = av.AssetId
	LEFT JOIN #LeaseAssetSKUInfo lsbr ON LeaseAssets.Id = lsbr.LeaseAssetId
	WHERE av.EndBookValueAmount <> 0.0
	END

	ELSE
	BEGIN
	CREATE TABLE #PerDayFactor
	(
		LeaseAssetId BIGINT,
		Amount Decimal(18,10)
	)
	
	INSERT INTO #PerDayFactor
	SELECT LeaseAssets.Id,CASE WHEN av.IsLessorOwned = 1 THEN av.Amount-(ROUND((CASE WHEN lsbr.LeaseAssetId is null THEN LeaseAssets.BookedResidual_Amount ELSE lsbr.BookedResidual_Amount END) * 1.0,2)) ELSE av.Amount - (ROUND((	CASE WHEN lsbr.LeaseAssetId is null THEN LeaseAssets.BookedResidual_Amount ELSE lsbr.BookedResidual_Amount END),2))  END
	FROM LeaseAssets
	INNER JOIN #AssetEndNBVDetails av ON dbo.LeaseAssets.AssetId = av.AssetId
	LEFT JOIN #LeaseAssetSKUInfo lsbr ON LeaseAssets.Id = lsbr.LeaseAssetId
	
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
		av.AssetId,
		av.Amount,
		LeaseAssets.NBV_Currency,
		CASE WHEN av.IsLessorOwned = 1 THEN ROUND((	CASE WHEN lsbr.LeaseAssetId is null THEN LeaseAssets.BookedResidual_Amount ELSE lsbr.BookedResidual_Amount END) * @ParticipationPercentage,2) ELSE (	CASE WHEN lsbr.LeaseAssetId is null THEN LeaseAssets.BookedResidual_Amount ELSE lsbr.BookedResidual_Amount END) END,
		LeaseAssets.BookedResidual_Currency,
		@BeginDate,
		LeaseFinanceDetails.MaturityDate,
		LeaseFinanceDetails.LeaseBookingGLTemplateId,
		@InstrumentTypeId,
		@LineofBusinessId,
		@CostCenterId,
		LeaseFinances.ContractId,
		1,
		0,
		0,
		#PerDayFactor.Amount/@NumberOfDays,
		@CreatedById,
		@CreatedTime,
		av.IsLessorOwned,
		Assets.IsLeaseComponent

	FROM LeaseAssets
	INNER JOIN Assets ON LeaseAssets.AssetId = Assets.Id
	INNER JOIN LeaseFinances ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id AND		   
				LeaseAssets.IsActive = 1 AND
				LeaseFinances.Id = @LeaseFinanceId AND
				LeaseAssets.NBV_Amount <> 0.0 AND 
				LeaseAssets.IsLeaseAsset = 1
	INNER JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
	INNER JOIN #AssetEndNBVDetails av ON dbo.LeaseAssets.AssetId = av.AssetId
	LEFT JOIN #LeaseAssetSKUInfo lsbr ON LeaseAssets.Id = lsbr.LeaseAssetId
	INNER JOIN #PerDayFactor ON LeaseAssets.Id = #PerDayFactor.LeaseAssetId
	WHERE av.Amount <> 0.0

	END

IF OBJECT_ID('tempdb..#AssetEndNBVDetails') IS NOT NULL
DROP TABLE #AssetEndNBVDetails

IF OBJECT_ID('tempdb..#AssetValues') IS NOT NULL
DROP TABLE #AssetValues

IF OBJECT_ID('tempdb..#AVHSyndicationRecords') IS NOT NULL
DROP TABLE #AVHSyndicationRecords

IF OBJECT_ID('tempdb..#LeaseAssetSKUInfo') IS NOT NULL
DROP TABLE #LeaseAssetSKUInfo

IF OBJECT_ID('tempdb..#PerDayFactor') IS NOT NULL
DROP TABLE #PerDayFactor

END

GO

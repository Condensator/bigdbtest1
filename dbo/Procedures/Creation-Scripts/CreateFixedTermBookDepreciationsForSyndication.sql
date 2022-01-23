SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[CreateFixedTermBookDepreciationsForSyndication]
(
	@LeaseFinanceId BIGINT,
	@CreatedById BIGINT,
	@CreatedTime DATETIMEOFFSET,
	@NumberOfDays INT,
	@RetainedPercentage DECIMAL(18,4),
	@BeginDate DATETIME,
	@CanCreateNonLessorOwnedBookDepreciation BIT,
	@IsSyndicationOncommencement BIT
)
AS
BEGIN
SET NOCOUNT ON
        CREATE TABLE #AssetNBVDetails
		(
			 AssetId BIGINT			
			,EndNBV DECIMAL(16,2)
		)
IF(@IsSyndicationOncommencement = 1)
BEGIN
		;WITH CTE_AssetValues AS
		(
			SELECT avh.AssetId			
			,avh.EndBookValue_Amount			 
			,ROW_NUMBER() OVER(PARTITION BY avh.AssetId ORDER BY (avh.IncomeDate) DESC) AS RowNumber
			FROM dbo.LeaseFinances lf
			INNER JOIN dbo.LeaseAssets la ON la.LeaseFinanceId = lf.Id AND la.IsActive = 1 AND la.NBV_Amount <> 0.0
			INNER JOIN dbo.AssetValueHistories avh ON avh.AssetId = la.AssetId
			WHERE lf.Id = @LeaseFinanceId AND avh.IsSchedule = 1 AND
			avh.IncomeDate <= @BeginDate  
		)

	    INSERT INTO #AssetNBVDetails
		SELECT 
			 cav.AssetId
			,cav.EndBookValue_Amount
		FROM CTE_AssetValues cav
			WHERE cav.RowNumber = 1
END

ELSE
BEGIN
		;WITH CTE_AssetValues AS
		(
			SELECT avh.AssetId			
			,avh.EndBookValue_Amount			 
			,ROW_NUMBER() OVER(PARTITION BY avh.AssetId ORDER BY (avh.IncomeDate) DESC) AS RowNumber
			FROM dbo.LeaseFinances lf
			INNER JOIN dbo.LeaseAssets la ON la.LeaseFinanceId = lf.Id AND la.IsActive = 1 AND la.NBV_Amount <> 0.0
			INNER JOIN dbo.AssetValueHistories avh ON avh.AssetId = la.AssetId
			WHERE lf.Id = @LeaseFinanceId AND avh.IsSchedule = 1 AND
			avh.IncomeDate < @BeginDate  
		)

	    INSERT INTO #AssetNBVDetails
		SELECT 
			 cav.AssetId
			,cav.EndBookValue_Amount
		FROM CTE_AssetValues cav
			WHERE cav.RowNumber = 1
END
 
IF(@RetainedPercentage <> 0)
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
			LeaseAssets.AssetId,
			ROUND(aen.EndNBV * @RetainedPercentage,2),
			LeaseAssets.NBV_Currency,
			ROUND(LeaseAssets.BookedResidual_Amount * @RetainedPercentage,2),
			LeaseAssets.BookedResidual_Currency,
			@BeginDate,
			LeaseFinanceDetails.MaturityDate,
			LeaseFinanceDetails.LeaseBookingGLTemplateId,
			LeaseFinances.InstrumentTypeId,
			Contracts.LineofBusinessId,
			Contracts.CostCenterId,
			Contracts.Id,
			1,
			0,
			0,
			(((ROUND(aen.EndNBV * @RetainedPercentage,2)) - (ROUND(LeaseAssets.BookedResidual_Amount * @RetainedPercentage,2)))/@NumberOfDays),
			@CreatedById,
			@CreatedTime,
			1,
		    Assets.IsLeaseComponent

	FROM LeaseAssets
	INNER JOIN Assets ON LeaseAssets.AssetId = Assets.Id
		INNER JOIN LeaseFinances
				ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id AND		   
				   LeaseAssets.IsActive = 1 AND LeaseAssets.IsLeaseAsset = 1 AND
				   LeaseFinances.Id = @LeaseFinanceId 
		INNER JOIN LeaseFinanceDetails
				ON LeaseFinances.Id = LeaseFinanceDetails.Id
		INNER JOIN Contracts
				ON LeaseFinances.ContractId = Contracts.Id
		INNER JOIN #AssetNBVDetails aen ON dbo.LeaseAssets.AssetId = aen.AssetId
		WHERE aen.EndNBV <> 0.0
		END

-- Non-Lessor Owned Book Depreciation

IF(@CanCreateNonLessorOwnedBookDepreciation = 1)
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
			LeaseAssets.AssetId,
			ROUND(aen.EndNBV,2),
			LeaseAssets.NBV_Currency,
			ROUND(LeaseAssets.BookedResidual_Amount ,2),
			LeaseAssets.BookedResidual_Currency,
			@BeginDate,
			LeaseFinanceDetails.MaturityDate,
			LeaseFinanceDetails.LeaseBookingGLTemplateId,
			LeaseFinances.InstrumentTypeId,
			Contracts.LineofBusinessId,
			Contracts.CostCenterId,
			Contracts.Id,
			1,
			0,
			0,
			(((ROUND(aen.EndNBV,2)) - (ROUND(LeaseAssets.BookedResidual_Amount ,2)))/@NumberOfDays),
			@CreatedById,
			@CreatedTime,
			0,
		Assets.IsLeaseComponent

		FROM LeaseAssets
		INNER JOIN Assets ON LeaseAssets.AssetId = Assets.Id
		INNER JOIN LeaseFinances
				ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id AND		   
				   LeaseAssets.IsActive = 1 AND LeaseAssets.IsLeaseAsset = 1 AND
				   LeaseFinances.Id = @LeaseFinanceId 
		INNER JOIN LeaseFinanceDetails
				ON LeaseFinances.Id = LeaseFinanceDetails.Id
		INNER JOIN Contracts
				ON LeaseFinances.ContractId = Contracts.Id
		INNER JOIN #AssetNBVDetails aen ON dbo.LeaseAssets.AssetId = aen.AssetId
		WHERE aen.EndNBV <> 0.0
END

IF OBJECT_ID('tempdb..#AssetNBVDetails') IS NOT NULL
DROP TABLE #AssetNBVDetails

END

GO

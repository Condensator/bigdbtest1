SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CreateAssetValueHistoriesForLeasedAssets]
(
@AssetValueHistories AssetValueHistoryForLeasedAssets READONLY,
@LeaseFinanceId  BIGINT,
@ContractId BIGINT,
@SourceModeule VARCHAR(100),
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET,
@IsBookDepFromSyndication BIT,
@isForOverTerm BIT
)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	Select * Into #AssetValueHistories from @AssetValueHistories
	CREATE NONCLUSTERED INDEX [IX_AssetId]  ON #AssetValueHistories ([AssetId])

	INSERT into AssetValueHistories
	(
		SourceModule ,
		SourceModuleId ,
		FromDate ,
		ToDate ,
		IncomeDate ,
		Value_Amount ,
		Value_Currency,
		NetValue_Amount,
		NetValue_Currency,
		Cost_Amount ,
		Cost_Currency,
		BeginBookValue_Amount ,
		BeginBookValue_Currency,
		EndBookValue_Amount ,
		EndBookValue_Currency,
		IsAccounted ,
		IsSchedule ,
		IsCleared ,
		PostDate ,
		AssetId ,
		CreatedById,
		CreatedTime,
		GLJournalId,
		AdjustmentEntry,
		IsLessorOwned,
		IsLeaseComponent
	)
	SELECT
		avh.SourceModule,
		avh.SourceModuleId,
		avh.FromDate,
		avh.ToDate ,
		avh.IncomeDate ,
		avh.ValueAmount,
		avh.Currency,
		avh.NetValueAmount,
		avh.Currency,
		avh.CostAmount,
		avh.Currency,
		avh.BeginBookValueAmount,
		avh.Currency,
		avh.EndBookValueAmount,
		avh.Currency,
		avh.IsAccounted ,
		avh.IsSchedule ,
		avh.IsCleared ,
		avh.PostDate ,
		avh.MatchingAssetId ,
		@CreatedById,
		@CreatedTime,
		avh.GLJournalId,
		avh.AdjustmentEntry,
		avh.IsLessorOwned,
		avh.IsLeaseComponent
	FROM #AssetValueHistories avh
	
	Create TABLE #BookDepUpdate(BookDepreciationId BIGINT)

	;WITH CTE_AssetInfo AS (
		SELECT 
			AssetId = avh.MatchingAssetId, avh.IsLeaseComponent
		FROM #AssetValueHistories avh
		GROUP BY avh.SourceModuleId,avh.MatchingAssetId, avh.IsLeaseComponent
	) INSERT INTO #BookDepUpdate
	  SELECT BookDepreciations.Id 
	  FROM BookDepreciations
	  JOIN CTE_AssetInfo AS assetInfo ON BookDepreciations.AssetId = assetInfo.AssetId
			AND BookDepreciations.ContractId = @ContractId
			AND BookDepreciations.IsLeaseComponent = assetInfo.IsLeaseComponent
	  WHERE BookDepreciations.LastAmortRunDate IS NULL -- Can we include it in Covered Field with Contract? RS
	

	-----Update book dep----
	UPDATE BookDepreciations SET BookDepreciations.LastAmortRunDate = BookDepreciations.EndDate
	FROM BookDepreciations join  #BookDepUpdate on BookDepreciations.Id = #BookDepUpdate.BookDepreciationId
	
END

GO

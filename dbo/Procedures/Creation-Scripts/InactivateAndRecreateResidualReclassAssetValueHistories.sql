SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[InactivateAndRecreateResidualReclassAssetValueHistories]
(
	@ShouldInactivateExistingRecords BIT,
	@OldLeaseFinanceId BIGINT = NULL,
	@IsInOpenPeriod BIT,
	@ResidualReclassSourceModule NVARCHAR(30),
	@CreateResidualRecords BIT,
	@NewLeaseFinanceId BIGINT = NULL,
	@RecreationIncomeDate DATE = NULL,
	@ResidualRetainedFactor DECIMAL,
	@CanCreateAccountableRecords BIT,
	@IncludeSoftAssets BIT,
	@Currency NVARCHAR(3),
	@UserId BIGINT,
	@ModificationTime DATETIMEOFFSET 
)
AS
BEGIN

	SELECT AVH.*
	INTO #OldResidualReclassRecords
	FROM AssetValueHistories AVH
	JOIN Assets A ON AVH.AssetId = A.Id
	JOIN LeaseAssets LA ON A.Id = LA.AssetId
	JOIN LeaseFinances LF ON LA.LeaseFinanceId = LF.Id
	JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
	WHERE LF.Id = @OldLeaseFinanceId
	AND AVH.IsAccounted = 1
	AND AVH.SourceModule = @ResidualReclassSourceModule
	AND AVH.AdjustmentEntry = 0
	AND (LA.IsActive = 1 OR (LA.TerminationDate IS NOT NULL AND LFD.MaturityDate IS NOT NULL AND LA.TerminationDate > LFD.MaturityDate));

	IF @ShouldInactivateExistingRecords = 1
	BEGIN

		UPDATE AVH 
		SET AVH.IsSchedule = 0, 
		AVH.IsAccounted = 0, 
		AVH.ReversalPostDate = NULL, 
		AVH.UpdatedById = @UserId,
		AVH.UpdatedTime = @ModificationTime
		FROM AssetValueHistories AVH
		JOIN #OldResidualReclassRecords AVHI ON AVH.Id = AVHI.Id;

	END

	IF @CreateResidualRecords = 1
	BEGIN

		SELECT AVH.AssetId, 
		AssetValueHistoryId = AVH.Id, 
		BookedResidual = ROUND((LA.BookedResidual_Amount * @ResidualRetainedFactor),2), 
		RowNumber = ROW_NUMBER() OVER (PARTITION BY AVH.AssetId ORDER BY AVH.IncomeDate DESC, AVH.Id DESC)
		INTO #AssetNBVDetailsForResidualReclass   
		FROM AssetValueHistories AVH
		JOIN Assets A ON AVH.AssetId = A.Id
		JOIN LeaseAssets LA ON A.Id = LA.AssetId
		JOIN AssetTypes AT ON A.TypeId = AT.Id
		WHERE LA.LeaseFinanceId = @NewLeaseFinanceId 
		AND (@IncludeSoftAssets = 1 OR AT.IsSoft = 0)
		AND LA.IsActive = 1
		AND AVH.IsSchedule = 1;

		SELECT AVH.AssetId, Cost = AVH.Cost_Amount, NetValue = AVH.EndBookValue_Amount, BeginNBV = AVH.EndBookValue_Amount, EndNBV = NBVD.BookedResidual,AVH.IsLeaseComponent 
		INTO #LatestAssetNBVDetailsForResidualReclass
		FROM #AssetNBVDetailsForResidualReclass NBVD
		JOIN AssetValueHistories AVH ON NBVD.AssetValueHistoryId = AVH.Id
		WHERE RowNumber = 1;

		INSERT INTO AssetValueHistories
		(
			SourceModule,
			SourceModuleId,
			IncomeDate,
			Value_Amount,
			Value_Currency,
			Cost_Amount,
			Cost_Currency,
			NetValue_Amount,
			NetValue_Currency,
			BeginBookValue_Amount,
			BeginBookValue_Currency,
			EndBookValue_Amount,
			EndBookValue_Currency,
			IsAccounted,
			IsSchedule,
			IsCleared,
			PostDate,
			GLJournalId,
			CreatedById,
			CreatedTime,
			AssetId,
			AdjustmentEntry,
			IsLeaseComponent
		)
		SELECT 
		SourceModule = @ResidualReclassSourceModule,
		SourceModuleId = @NewLeaseFinanceId,
		IncomeDate = @RecreationIncomeDate,
		Value_Amount = LNBV.EndNBV - LNBV.BeginNBV,
		Value_Currency = @Currency,
		Cost_Amount = LNBV.Cost,
		Cost_Currency = @Currency,
		NetValue_Amount = LNBV.NetValue,
		NetValue_Currency = @Currency,
		BeginBookValue_Amount = LNBV.BeginNBV,
		BeginBookValue_Currency = @Currency,
		EndBookValue_Amount = LNBV.EndNBV,
		EndBookValue_Currency = @Currency,
		IsAccounted = CASE WHEN @IsInOpenPeriod = 1 THEN @CanCreateAccountableRecords ELSE AVHI.IsAccounted END,
		IsSchedule = 1,
		IsCleared = 1,
		PostDate = CASE WHEN @IsInOpenPeriod = 1 THEN NULL ELSE AVHI.PostDate END,
		GLJournaldId = CASE WHEN @IsInOpenPeriod = 1 THEN NULL ELSE AVHI.GLJournalId END,
		CreatedById = @UserId,
		CreatedTime = @ModificationTime,
		AssetId = LNBV.AssetId,
		AdjustmentEntry = 0,
		IsLeaseComponent = LNBV.IsLeaseComponent
		FROM #LatestAssetNBVDetailsForResidualReclass LNBV
		LEFT JOIN #OldResidualReclassRecords AVHI ON LNBV.AssetId = AVHI.AssetId;
	END

	DROP TABLE #OldResidualReclassRecords;

END

GO

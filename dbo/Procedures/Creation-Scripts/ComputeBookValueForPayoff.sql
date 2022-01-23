SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[ComputeBookValueForPayoff] (
	@AssetIds IdCollection ReadOnly,
	@ContractId BIGINT,
	@ShouldReadFromAVH BIT = NULL,
	@ShouldConsiderLessorOwnedPortion BIT = NULL,
	@EffectiveDate DATE
)
AS
BEGIN
	SET NOCOUNT ON

	SELECT Id INTO #AssetIds FROM @AssetIds 
	
	IF( @ShouldReadFromAVH = 1)
	BEGIN
		WITH CTE_AvhInfo AS (
			SELECT 
			ROW_NUMBER() OVER ( PARTITION BY AVH.AssetId ORDER BY AVH.IncomeDate ASC, AVH.Id DESC) AVHRank,
			AVH.BeginBookValue_Amount
			FROM dbo.AssetValueHistories AVH
			JOIN #AssetIds ON AVH.AssetId = #AssetIds.Id
			WHERE AVH.IsSchedule = 1	
				AND (@ShouldConsiderLessorOwnedPortion IS NULL OR AVH.IsLessorOwned = @ShouldConsiderLessorOwnedPortion)
				AND AVH.IsLeaseComponent = 1 
				AND AVH.IncomeDate >= @EffectiveDate
		)
		SELECT BeginBookValue = ISNULL(SUM(BeginBookValue_Amount), 0.00), FinanceBeginNetBookValue = 0.00
		FROM CTE_AvhInfo
		WHERE AVHRank = 1
	END
	ELSE
	BEGIN
		DECLARE @LeaseIncomeScheduleId BIGINT;

		SET @LeaseIncomeScheduleId = (SELECT TOP 1 lis.Id FROM LeaseFinances lf
			JOIN LeaseIncomeSchedules lis ON lf.Id = lis.LeaseFinanceId
			WHERE lf.ContractId = @ContractId
			AND lis.IncomeDate >= @EffectiveDate
			AND lis.IsSchedule = 1
			AND (@ShouldConsiderLessorOwnedPortion IS NULL OR lis.IsLessorOwned = @ShouldConsiderLessorOwnedPortion)
			ORDER BY IncomeDate)

		SELECT BeginBookValue = ISNULL(SUM(ais.LeaseBeginNetBookValue_Amount), 0.00), FinanceBeginNetBookValue = ISNULL(SUM(ais.FinanceBeginNetBookValue_Amount), 0.00)
		FROM AssetIncomeSchedules ais
		JOIN #AssetIds ON ais.AssetId = #AssetIds.Id
		WHERE ais.LeaseIncomeScheduleId = @LeaseIncomeScheduleId
		AND ais.IsActive = 1
	END
END

GO

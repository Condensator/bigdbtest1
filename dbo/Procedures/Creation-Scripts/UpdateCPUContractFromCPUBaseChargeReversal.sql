SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[UpdateCPUContractFromCPUBaseChargeReversal]
(
	@CPUScheduleInfos CPUScheduleDetail READONLY,	
	@CurrentUserId BIGINT,
	@CurrentTime DATETIMEOFFSET(7)
)
AS
BEGIN
	SET NOCOUNT ON;



	DECLARE @ConsolidatedCPUAssetIds NVARCHAR(MAX) = ''
	
	SELECT
		@ConsolidatedCPUAssetIds += CONCAT(CPUAssetIds, ',')
	FROM
		@CPUScheduleInfos
	WHERE CPUAssetIds != ''

	SET @ConsolidatedCPUAssetIds = SUBSTRING(@ConsolidatedCPUAssetIds, 0, LEN(@ConsolidatedCPUAssetIds))
	


	SELECT
		CPUAssets.Id as CPUAssetId, 
		CPUAssets.CPUScheduleId,
		CSI.ReverseFromDate
	INTO
		#CPUAssetInfo
	FROM
		CPUAssets
		JOIN @CPUScheduleInfos CSI ON CSI.CPUScheduleId = CPUAssets.CPUScheduleId
	WHERE
		(CSI.CPUAssetIds = '' OR CSI.CPUAssetIds IS NULL)
		OR
		CPUAssets.Id IN (SELECT Id FROM ConvertCSVToBigIntTable(@ConsolidatedCPUAssetIds, ','))	
		


	UPDATE
		CPUAssets
	SET
		BaseReceivablesGeneratedTillDate = MaxDueDate,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM
		CPUAssets
		INNER JOIN #CPUAssetInfo CA on CPUAssets.CPUScheduleId = CA.CPUScheduleId AND CPUAssets.Id = CA.CPUAssetId
		LEFT JOIN
		(
			SELECT
				AssetId = CPUAssets.AssetId,
				MaxDueDate = Max(CPUPaymentSchedules.DueDate)
			FROM
				CPUAssets
				JOIN #CPUAssetInfo CAI on CPUAssets.CPUScheduleId = CAI.CPUScheduleId AND CPUAssets.Id = CAI.CPUAssetId
				JOIN CPUAssetPaymentSchedules ON CPUAssets.AssetId = CPUAssetPaymentSchedules.AssetId AND		CPUAssetPaymentSchedules.CPUBaseStructureId = CAI.CPUScheduleId
				JOIN CPUPaymentSchedules on CPUAssetPaymentSchedules.CPUPaymentScheduleId = CPUPaymentSchedules.Id
			WHERE
				CPUPaymentSchedules.DueDate < CAI.ReverseFromDate
				AND CPUPaymentSchedules.IsActive  = 1
				AND CPUAssetPaymentSchedules.IsActive = 1
			GROUP BY
				CAI.CPUScheduleId,
				CPUAssets.AssetId
		)
		GroupedPayments ON CPUAssets.AssetId = GroupedPayments.AssetId


	UPDATE
		CPUSchedules
	SET
		BaseJobRanForCompletion = ReceivablesGeneratedTillTerminationDate,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM
		CPUSchedules
		INNER JOIN @CPUScheduleInfos CSI on CPUSchedules.Id = CSI.CPUScheduleId
		INNER JOIN
		(
			SELECT
				CS.CPUScheduleId,
				ReceivablesGeneratedTillTerminationDate =
				CASE
					WHEN Sum (
						 		CASE
						 			WHEN CPUAssets.BaseReceivablesGeneratedTillDate >= CPUAssets.PayoffDate
						 			THEN 1
						 			ELSE 0
						 		END
							 ) = COUNT(CPUAssets.Id)
					THEN 1
					ELSE 0
				END
			FROM
				@CPUScheduleInfos CS
				JOIN CPUAssets ON CS.CPUScheduleId = CPUAssets.CPUScheduleId
			WHERE
				CPUAssets.IsActive=1
			GROUP BY
				CS.CPUScheduleId
		)
		Result ON Result.CPUScheduleId = CPUSchedules.Id


	SET NOCOUNT OFF;

END

GO

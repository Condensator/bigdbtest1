SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create PROCEDURE [dbo].[PopulateCPUOverageChargeReversalExtract]
(	
	@LegalEntityIds NVARCHAR(MAX),
	@ReverseFromDate DATETIMEOFFSET,
	@CPUCommencedStatus NVARCHAR(9),
	@CPUPaidoffStatus NVARCHAR(7),
	@CPUScheduleReceivableSource NVARCHAR(11),
	@EntityType NVARCHAR(11),
	@CustomerEntityType NVARCHAR(8),
	@CPUContractEntityType NVARCHAR(11),
	@FilterOption NVARCHAR(3),
	@AllFilterOption NVARCHAR(3),
	@OneFilterOption NVARCHAR(3),
	@CustomerId BIGINT,
	@CPUContractId BIGINT,
	@CreatedById BIGINT,
	@CreatedTime DATETIMEOFFSET,
	@JobStepInstanceId BIGINT,	
	@HaveCPUContractToProcess BIT OUT  
)
AS
BEGIN
	
	SET NOCOUNT ON;

	SET @HaveCPUContractToProcess = 0

	IF OBJECT_ID('tempdb..#LegalEntities') IS NOT NULL 
	DROP TABLE #LegalEntities 

	SELECT
		Id 
	INTO 
		#LegalEntities
	FROM 
		dbo.ConvertCSVToBigIntTable(@LegalEntityIds,',')	
	
	INSERT INTO CPUOverageChargeReversalJobExtracts
	(
		CPUContractId,
		CPUScheduleId,
		ReverseFromDate, 
		CreatedById, 
		CreatedTime, 
		JobStepInstanceId, 		
		IsSubmitted
	)
	SELECT 
		DISTINCT 
			CPUContracts.Id AS CPUContractId,
			CPUSchedules.Id AS CPUScheduleId,
			@ReverseFromDate,
			@CreatedById,
			@CreatedTime,
			@JobStepInstanceId,
			CAST(0 AS BIT)
	FROM
		CPUAssetMeterReadings
		JOIN CPUOverageAssessments		 ON CPUAssetMeterReadings.CPUOverageAssessmentId = CPUOverageAssessments.Id
		JOIN CPUOverageAssessmentDetails ON CPUOverageAssessments.Id = CPUOverageAssessmentDetails.CPUOverageAssessmentId
		JOIN Receivables				 ON CPUOverageAssessmentDetails.ReceivableId = Receivables.Id
		JOIN ReceivableDetails			 ON Receivables.Id = ReceivableDetails.ReceivableId
		JOIN CPUSchedules				 ON Receivables.SourceId = CPUSchedules.Id AND Receivables.SourceTable = @CPUScheduleReceivableSource
		JOIN CPUAssets					 ON CPUSchedules.Id = CPUAssets.CPUScheduleId
		JOIN CPUFinances				 ON CPUSchedules.CPUFinanceId = CPUFinances.Id
		JOIN CPUContracts				 ON CPUFinances.Id = CPUContracts.CPUFinanceId
		JOIN #LegalEntities				 ON CPUFinances.LegalEntityId = #LegalEntities.Id
                 
	WHERE
		CPUContracts.Status IN (@CPUCommencedStatus, @CPUPaidoffStatus)
		AND (
				CPUAssetMeterReadings.IsActive = 1
				OR CPUOverageAssessments.IsAdjustmentPending = 1
			)
        AND CPUSchedules.IsActive =1
        AND CPUAssets.IsActive =1
        AND Receivables.DueDate >= @ReverseFromDate
        AND Receivables.IsActive =1
        AND ReceivableDetails.AdjustmentBasisReceivableDetailId IS NULL
		AND (
				@FilterOption = @AllFilterOption OR
				(
					@FilterOption = @OneFilterOption 
					AND @EntityType = @CustomerEntityType 
					AND CPUFinances.CustomerId = @CustomerId
				) OR
				(
					@FilterOption = @OneFilterOption 
					AND @EntityType = @CPUContractEntityType 
					AND CPUContracts.Id = @CPUContractId
				)
			)

	SET @HaveCPUContractToProcess = 
	(
		SELECT 
			CASE
				WHEN 
					COUNT(Id) > 0	
				THEN 1
				ELSE 0
			END

		FROM 
			CPUOverageChargeReversalJobExtracts
		WHERE
			IsSubmitted = 0
			AND JobStepInstanceId = @JobStepInstanceId
	)
	SET NOCOUNT OFF;
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create PROCEDURE [dbo].[PopulateCPUBaseChargeReversalExtract]
(	
	@LegalEntityIds NVARCHAR(MAX),
	@ReverseFromDate DATETIMEOFFSET,
	@CPUCommencedStatus NVARCHAR(9),
	@CPUPaidoffStatus NVARCHAR(7),
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
	
	INSERT INTO CPUBaseChargeReversalJobExtracts
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
		CPUContracts
		JOIN CPUFinances		ON CPUContracts.CPUFinanceId = CPUFinances.Id
		JOIN #LegalEntities		ON CPUFinances.LegalEntityId = #LegalEntities.Id
		JOIN CPUSchedules		ON CPUFinances.Id = CPUSchedules.CPUFinanceId
		JOIN CPUBaseStructures	ON CPUSchedules.Id = CPUBaseStructures.Id
		JOIN CPUAssets			ON CPUSchedules.Id = CPUAssets.CPUScheduleId
	WHERE
		CPUContracts.Status IN (@CPUCommencedStatus, @CPUPaidoffStatus)
		AND CPUSchedules.IsActive = 1
		AND CPUAssets.IsActive = 1
		AND CPUAssets.BaseReceivablesGeneratedTillDate IS NOT NULL 
		AND CPUAssets.BaseReceivablesGeneratedTillDate >= @ReverseFromDate
		AND CPUBaseStructures.NumberofPayments > 0
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
			CPUBaseChargeReversalJobExtracts
		WHERE
			IsSubmitted = 0
			AND JobStepInstanceId = @JobStepInstanceId
	)
	SET NOCOUNT OFF;
END

GO

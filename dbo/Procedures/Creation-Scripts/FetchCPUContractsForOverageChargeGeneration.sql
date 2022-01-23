SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FetchCPUContractsForOverageChargeGeneration]
(
	@RunDateBasedProcessThroughDate DATE,
	@BusinessDateBasedProcessThroughDate DATE,
	@InvoiceSensitive BIT,
	@CPUContractId BIGINT = NULL,
	@CustomerId BIGINT = NULL,
	@LegalEntitiesInCSV NVARCHAR(MAX),
	@CommencedStatus NVARCHAR(9),
	@PaidOffStatus NVARCHAR(9),
	@JobStepInstanceId BIGINT,
	@CreatedById BIGINT,
	@CreatedTime DATETIMEOFFSET,
	@EntityType NVARCHAR(30),
	@FilterOption NVARCHAR(10),
	@AllFilterOption NVARCHAR(10),
	@OneFilterOption NVARCHAR(10),
	@CustomerEntityType NVARCHAR(15),
	@CPUContractEntityType NVARCHAR(15),
	@HaveCPUContractToProcess BIT OUT
)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @False BIT = 0
	DECLARE @True BIT = 1
	SET @HaveCPUContractToProcess = 0

	IF OBJECT_ID('tempdb..#LegalEntities') IS NOT NULL DROP TABLE #LegalEntities 

	SELECT ID INTO #LegalEntities FROM ConvertCSVToBigIntTable(@LegalEntitiesInCSV, ',')

	SELECT 
		CPUContracts.Id CPUContractId,
		CPUContracts.SequenceNumber CPUContractSequenceNumber,
		CPUSchedules.Id CPUScheduleId,
		CPUSchedules.ScheduleNumber CPUScheduleNumber,
		CASE 
			WHEN @InvoiceSensitive = 1 AND PortfolioParams.Value ='TRUE'  
				THEN
					DATEADD(Day,CPUScheduleBillings.InvoiceLeadDays, @BusinessDateBasedProcessThroughDate)
			WHEN @InvoiceSensitive = 1 AND PortfolioParams.Value ='FALSE'  
				THEN
					DATEADD(Day,CPUScheduleBillings.InvoiceLeadDays, @RunDateBasedProcessThroughDate)
			WHEN @InvoiceSensitive = 0 AND PortfolioParams.Value ='TRUE'  
					THEN @BusinessDateBasedProcessThroughDate
			WHEN @InvoiceSensitive = 0 AND PortfolioParams.Value ='FALSE'  
					THEN @RunDateBasedProcessThroughDate	
		END ComputedProcessThroughDate
	
	INTO #InitialContractList
	
	FROM 
		CPUContracts
		JOIN CPUFinances					ON CPUContracts.CPUFinanceId = CPUFinances.Id	
		JOIN LegalEntities					ON CPUFinances.LegalEntityId = LegalEntities.Id
		JOIN #LegalEntities					ON LegalEntities.Id = #LegalEntities.Id
		JOIN BusinessUnits					ON LegalEntities.BusinessUnitId = BusinessUnits.Id
		JOIN 
			(
				SELECT 	
					PortfolioParameters.PortfolioId,
					PortfolioParameters.Value
				FROM 
					PortfolioParameters
					JOIN PortFolioParameterConfigs	ON  PortfolioParameters.PortfolioParameterConfigId = PortfolioParameterConfigs.Id 
													AND PortFolioParameterConfigs.Name = 'IsBusinessDateApplicable' 
													AND PortFolioParameterConfigs.Category = 'BusinessUnit'
			) 
			AS PortfolioParams				ON BusinessUnits.Id = PortfolioParams.PortfolioId
		JOIN CPUSchedules					ON CPUFinances.Id = CPUSchedules.CPUFinanceId
		JOIN CPUScheduleBillings			ON CPUSchedules.Id = CPUScheduleBillings.Id
		JOIN Customers						ON CPUFinances.CustomerId = Customers.Id	
	
	WHERE
		(
			CPUContracts.Status = @CommencedStatus 
			OR CPUContracts.Status = @PaidOffStatus 
		)
		AND CPUSchedules.IsActive = 1 
		AND CPUSchedules.CommencementDate <= 
			(
				CASE 
					WHEN @InvoiceSensitive = 1 AND PortfolioParams.Value ='TRUE'  
					THEN
						DATEADD(Day,CPUScheduleBillings.InvoiceLeadDays, @BusinessDateBasedProcessThroughDate)
					WHEN @InvoiceSensitive = 1 AND PortfolioParams.Value ='FALSE'  
					THEN
						DATEADD(Day,CPUScheduleBillings.InvoiceLeadDays, @RunDateBasedProcessThroughDate)
					WHEN @InvoiceSensitive = 0 AND PortfolioParams.Value ='TRUE'  
					THEN
						@BusinessDateBasedProcessThroughDate
					WHEN @InvoiceSensitive = 0 AND PortfolioParams.Value ='FALSE'  
					THEN
						@RunDateBasedProcessThroughDate					
				END
			) 
		AND
		(
			@FilterOption = @AllFilterOption OR
			(@FilterOption = @OneFilterOption AND @EntityType = @CustomerEntityType AND CPUFinances.CustomerId = @CustomerId) OR
			(@FilterOption = @OneFilterOption AND @EntityType = @CPUContractEntityType AND CPUContracts.Id = @CPUContractId)
		)
		AND 
		(
			(
				SELECT 
					COUNT(CPUOverageTierSchedules.CPUOverageStructureId)
				FROM 
					CPUOverageTierSchedules
					JOIN CPUOverageTierScheduleDetails ON CPUOverageTierSchedules.Id =  CPUOverageTierScheduleDetails.CPUOverageTierScheduleId
				WHERE 
					CPUOverageTierSchedules.IsActive = 1 
					AND CPUOverageTierScheduleDetails.IsActive = 1
					AND CPUSchedules.Id = CPUOverageTierSchedules.CPUOverageStructureId
			)  > 0
		)
		

	SELECT
		#InitialContractList.CPUScheduleId,
		MIN(CPUAssets.BeginDate) MinBeginDate
	INTO #MinAssetBeginDate
	FROM
		CPUAssets
		JOIN #InitialContractList ON CPUAssets.CPUScheduleId = #InitialContractList.CPUScheduleId AND CPUAssets.IsActive = 1
	GROUP BY 
		#InitialContractList.CPUScheduleId

	INSERT INTO CPUOverageChargeJobExtracts
	(
		CPUContractId,
		CPUContractSequenceNumber,
		CPUScheduleId,
		CPUScheduleNumber, 
		ComputedProcessThroughDate, 
		JobStepInstanceId, 
		CreatedById, 
		CreatedTime, 
		IsSubmitted
	)

	SELECT 
		DISTINCT 
			#InitialContractList.CPUContractId,
			#InitialContractList.CPUContractSequenceNumber,
			#InitialContractList.CPUScheduleId,
			#InitialContractList.CPUScheduleNumber,
			#InitialContractList.ComputedProcessThroughDate,
			@JobStepInstanceId ,
			@CreatedById,
			@CreatedTime,
			0
	FROM 
		#InitialContractList 
		JOIN #MinAssetBeginDate ON #MinAssetBeginDate.CPUScheduleId = #InitialContractList.CPUScheduleId
	WHERE 
		#MinAssetBeginDate.MinBeginDate <= #InitialContractList.ComputedProcessThroughDate


	SET @HaveCPUContractToProcess = 
	(
		SELECT 
			CASE WHEN COUNT(Id) > 0	
					THEN 1
					ELSE 0
			END

		FROM 
			CPUOverageChargeJobExtracts
		WHERE
			IsSubmitted = 0
			AND JobStepInstanceId = @JobStepInstanceId
	)


	SET NOCOUNT OFF;

	IF OBJECT_ID('tempdb..#LegalEntities') IS NOT NULL DROP TABLE #LegalEntities 
	IF OBJECT_ID('tempdb..#InitialContractList') IS NOT NULL DROP TABLE #InitialContractList 
	IF OBJECT_ID('tempdb..#MinAssetBeginDate') IS NOT NULL DROP TABLE #MinAssetBeginDate 


END


GO

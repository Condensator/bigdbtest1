SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create PROCEDURE [dbo].[PopulateCPUBaseChargeExtract]
(
	@EntityType NVARCHAR(30),
	@CreatedById BIGINT,
	@CreatedTime DATETIMEOFFSET,
	@FilterOption NVARCHAR(10),
	@CustomerId BIGINT,
	@CPUContractId BIGINT,
	@BusinessDateBasedProcessThroughDate DATE,
	@RunDateBasedProcessThroughDate DATE,
	@InvoiceSensitive BIT,
	@LegalEntityIds NVARCHAR(MAX),
	@JobStepInstanceId BIGINT,
	@CommencedBookingStatus NVARCHAR(20),
	@PaidOffStatus NVARCHAR(20),
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

	SELECT
		Id 
	INTO #LegalEntities
	FROM 
		dbo.ConvertCSVToBigIntTable(@LegalEntityIds,',')



	SELECT 
		CPUSchedules.Id CPUScheduleId,
		MIN(CPUAssets.BeginDate) MinBeginDate,
	   /* Consider the ReceivablesGeneratedTillDate as NULL if any of the CPU Asset has BaseReceivablesGeneratedTillDate as NULL , else should take the minimum among BaseReceivablesGeneratedTillDate */
		CASE
			 WHEN MIN(CASE WHEN BaseReceivablesGeneratedTillDate IS NULL THEN 0 ELSE 1 END) = 0
				THEN NULL
			 ELSE 
				MIN(BaseReceivablesGeneratedTillDate)
		END AS MinReceivablesGeneratedTillDate,
		CASE
			 WHEN MAX(CASE WHEN BaseReceivablesGeneratedTillDate IS NULL THEN 0 ELSE 1 END) = 0
				THEN NULL
			 ELSE 
				MAX(BaseReceivablesGeneratedTillDate)
		END AS MaxReceivableGeneratedTillDate
	INTO #AssetInfo
	FROM
		CPUContracts
		JOIN CPUFinances	ON CPUContracts.CPUFinanceId = CPUFinances.Id
		JOIN #LegalEntities ON CPUFinances.LegalEntityId = #LegalEntities.Id
		JOIN LegalEntities	ON CPUFinances.LegalEntityId = LegalEntities.Id
		JOIN CPUSchedules	ON CPUFinances.Id = CPUSchedules.CPUFinanceId AND CPUSchedules.IsActive = @True
		JOIN CPUAssets		ON CPUSchedules.Id = CPUAssets.CPUScheduleId AND CPUAssets.IsActive = @True 
	WHERE
		CPUContracts.Status IN (@CommencedBookingStatus , @PaidOffStatus)
		AND (CPUAssets.PayoffDate IS NULL OR CPUAssets.BeginDate != CPUAssets.PayoffDate)
	GROUP BY 
		CPUSchedules.Id

	SELECT
		CPUBaseStructureId as CPUScheduleId,
		MAX(CPUPaymentSchedules.DueDate) MaxPaymentDueDate INTO #MaxPaymentDueDateInfo
	FROM
		CPUPaymentSchedules
	WHERE
		CPUBaseStructureId IN (SELECT CPUScheduleId FROM #AssetInfo)
		AND IsActive = 1
	GROUP BY
		CPUBaseStructureId

	SELECT
		CPUPaymentSchedules.CPUBaseStructureId as CPUScheduleId,
		MIN(CPUPaymentSchedules.DueDate) DueDate INTO #NextPossibleDueDateInfo
	FROM
		CPUPaymentSchedules
	INNER JOIN #AssetInfo
		ON #AssetInfo.CPUScheduleId = CPUPaymentSchedules.CPUBaseStructureId AND
			CPUPaymentSchedules.DueDate > #AssetInfo.MaxReceivableGeneratedTillDate AND
			CPUPaymentSchedules.IsActive = 1
	GROUP BY 
		CPUPaymentSchedules.CPUBaseStructureId

	SELECT 
		#MaxPaymentDueDateInfo.CPUScheduleId,
		#MaxPaymentDueDateInfo.MaxPaymentDueDate,
		#NextPossibleDueDateInfo.DueDate NextPossibleDueDate INTO #CPUSchedulePaymentInfo
	FROM
		#MaxPaymentDueDateInfo
	LEFT JOIN #NextPossibleDueDateInfo
		ON #MaxPaymentDueDateInfo.CPUScheduleId = #NextPossibleDueDateInfo.CPUScheduleId

	
	INSERT INTO CPUBaseChargeJobExtracts
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
		FilteredContracts.CPUContractId,
		FilteredContracts.CPUContractSequenceNumber,
		FilteredContracts.CPUScheduleId,
		FilteredContracts.CPUScheduleNumber,
		FilteredContracts.ComputedProcessThroughDate,
		@JobStepInstanceId,
		@CreatedById,
		@CreatedTime,
		0
		FROM
			(
				SELECT
					CPUContracts.Id CPUContractId,
					CPUContracts.SequenceNumber CPUContractSequenceNumber,
					CPUschedules.Id CPUScheduleId,
					CPUSchedules.ScheduleNumber CPUScheduleNumber,
					CASE 
						WHEN @InvoiceSensitive = 1 AND PortfolioParams.Value = 'True' 
							THEN DATEADD(DAY, CPUScheduleBillings.InvoiceLeadDays, @BusinessDateBasedProcessThroughDate) 
						WHEN @InvoiceSensitive = 1 AND PortfolioParams.Value ='FALSE'  
							THEN DATEADD(DAY, CPUScheduleBillings.InvoiceLeadDays, @RunDateBasedProcessThroughDate) 
						WHEN @InvoiceSensitive = 0 AND PortfolioParams.Value ='TRUE'  
							THEN @BusinessDateBasedProcessThroughDate
						WHEN @InvoiceSensitive = 0 AND PortfolioParams.Value ='FALSE'  
							THEN @RunDateBasedProcessThroughDate	
					END AS ComputedProcessThroughDate,
					CPUFinances.CustomerId,
					CPUFinances.IsAdvanceBilling,
					#AssetInfo.MinBeginDate,
					#AssetInfo.MinReceivablesGeneratedTillDate,
					CPUSchedules.BaseJobRanForCompletion,
					CPUSchedules.CommencementDate,
					#CPUSchedulePaymentInfo.NextPossibleDueDate,
					#CPUSchedulePaymentInfo.MaxPaymentDueDate,
					#AssetInfo.MaxReceivableGeneratedTillDate
				FROM
					CPUContracts
					JOIN CPUFinances			ON CPUContracts.CPUFinanceId = CPUFinances.Id
					JOIN #LegalEntities			ON CPUFinances.LegalEntityId = #LegalEntities.Id
					JOIN LegalEntities			ON CPUFinances.LegalEntityId = LegalEntities.Id
					JOIN BusinessUnits			ON LegalEntities.BusinessUnitId = BusinessUnits.Id
					JOIN CPUSchedules			ON CPUFinances.Id = CPUSchedules.CPUFinanceId AND CPUSchedules.IsActive = @True
					JOIN CPUScheduleBillings	ON CPUSchedules.Id = CPUScheduleBillings.Id
					JOIN CPUBaseStructures		ON CPUSchedules.Id = CPUBaseStructures.Id
					JOIN 
						(
							SELECT 
								PortfolioParameters.PortfolioId,
								PortfolioParameters.Value
							FROM
								PortfolioParameterConfigs
								JOIN PortfolioParameters ON PortfolioParameterConfigs.Id = PortfolioParameters.PortfolioParameterConfigId AND
									 PortfolioParameterConfigs.Name = 'IsBusinessDateApplicable' AND
									 PortfolioParameterConfigs.Category = 'BusinessUnit'
						) AS PortfolioParams
						ON BusinessUnits.PortfolioId = PortfolioParams.PortfolioId
					JOIN #AssetInfo ON CPUSchedules.Id = #AssetInfo.CPUScheduleId
					INNER JOIN #CPUSchedulePaymentInfo
						ON CPUSchedules.Id = #CPUSchedulePaymentInfo.CPUScheduleId
				WHERE
					CPUContracts.Status IN( @CommencedBookingStatus, @PaidOffStatus) AND
					CPUBaseStructures.NumberofPayments > 0 AND
					(
						@FilterOption = @AllFilterOption OR
						(@FilterOption = @OneFilterOption AND @EntityType = @CustomerEntityType AND CPUFinances.CustomerId = @CustomerId) OR
						(@FilterOption = @OneFilterOption AND @EntityType = @CPUContractEntityType AND CPUContracts.Id = @CPUContractId)
					)
			)
			AS FilteredContracts
		WHERE
			FilteredContracts.BaseJobRanForCompletion = @False AND
			FilteredContracts.CommencementDate <= FilteredContracts.ComputedProcessThroughDate AND
			(FilteredContracts.IsAdvanceBilling = @True OR FilteredContracts.MinBeginDate <= FilteredContracts.ComputedProcessThroughDate) AND
			(
				
				FilteredContracts.MinReceivablesGeneratedTillDate IS NULL 
				OR FilteredContracts.MaxReceivableGeneratedTillDate IS NULL
				OR 
					(
						COALESCE(FilteredContracts.MinReceivablesGeneratedTillDate, '') <> COALESCE(FilteredContracts.MaxReceivableGeneratedTillDate, '')
						AND FilteredContracts.ComputedProcessThroughDate > FilteredContracts.MinReceivablesGeneratedTillDate
					)
				OR 
					(
						FilteredContracts.NextPossibleDueDate IS NOT NULL 
						AND FilteredContracts.ComputedProcessThroughDate >= FilteredContracts.NextPossibleDueDate
					)
				OR 
					(
						FilteredContracts.ComputedProcessThroughDate > FilteredContracts.MaxPaymentDueDate
					)
			)

	SET @HaveCPUContractToProcess = 
	(
		SELECT 
			CASE WHEN COUNT(Id) > 0	
					THEN 1
					ELSE 0
			END

		FROM 
			CPUBaseChargeJobExtracts
		WHERE
			IsSubmitted = 0
			AND JobStepInstanceId = @JobStepInstanceId
	)
	SET NOCOUNT OFF;
END

GO

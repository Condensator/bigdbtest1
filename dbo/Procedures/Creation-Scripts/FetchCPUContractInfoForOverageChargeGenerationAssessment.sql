SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FetchCPUContractInfoForOverageChargeGenerationAssessment]
(
	@RunDateBasedProcessThroughDate DATE,
	@BusinessDateBasedProcessThroughDate DATE,
	@InvoiceSensitive BIT,
	@CPUContractId BIGINT = NULL,
	@CustomerId BIGINT = NULL,
	@LegalEntitiesInCSV NVARCHAR(MAX),
	@CommencedStatus NVARCHAR(9),
	@PaidOffStatus NVARCHAR(9)
)
AS
BEGIN

	SET NOCOUNT ON;

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
			ELSE 
				@RunDateBasedProcessThroughDate 
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
			AS PortfolioParams				ON BusinessUnits.PortfolioId = PortfolioParams.PortfolioId
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
												WHEN @InvoiceSensitive = 1 AND PortfolioParams.Value ='FASLE'  
												THEN
													DATEADD(Day,CPUScheduleBillings.InvoiceLeadDays, @RunDateBasedProcessThroughDate)
												ELSE 
													@RunDateBasedProcessThroughDate 
											END
										) 
		AND 
		(
			Customers.Id = @CustomerId 
			OR CPUContracts.Id = @CPUContractId 
			OR 
			(
				@CustomerId IS NULL 
				AND @CPUContractId IS NULL
			)
		) 
		AND EXISTS 
		(
			SELECT 
				DISTINCT 
				CPUOverageTiers.CPUOverageStructureId 
			FROM 
				CPUOverageTiers 
			WHERE 
				CPUOverageTiers.IsActive = 1 
				AND CPUSchedules.Id = CPUOverageTiers.CPUOverageStructureId
		)
		

	SELECT
		#InitialContractList.CPUScheduleId,
		MIN(CPUAssets.BeginDate) MinBeginDate
	INTO #MinAssetBeginDate
	FROM
		CPUAssets
		JOIN #InitialContractList ON 
				CPUAssets.CPUScheduleId = #InitialContractList.CPUScheduleId AND 
				CPUAssets.IsActive = 1 AND 
				(
					CPUAssets.PayoffDate IS NULL 
						OR 
					CPUAssets.BeginDate != CPUAssets.PayoffDate
				)
	GROUP BY 
		#InitialContractList.CPUScheduleId


	SELECT 
		DISTINCT 
			#InitialContractList.CPUContractId,
			#InitialContractList.CPUScheduleId,
			#InitialContractList.ComputedProcessThroughDate
	FROM 
		#InitialContractList 
		JOIN #MinAssetBeginDate ON #MinAssetBeginDate.CPUScheduleId = #InitialContractList.CPUScheduleId
	WHERE 
		#MinAssetBeginDate.MinBeginDate <= #InitialContractList.ComputedProcessThroughDate

	SET NOCOUNT OFF;

END


GO

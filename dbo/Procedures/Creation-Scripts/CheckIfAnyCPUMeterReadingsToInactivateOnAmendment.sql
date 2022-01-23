SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CheckIfAnyCPUMeterReadingsToInactivateOnAmendment]
(
	@MeterReadingInactivationInfo MeterReadingInactivationInfo READONLY, 
	@IsEstimatedInactivation BIT, 
	@MeterReadingCount BIGINT OUTPUT
) 
AS 
BEGIN 
	SET NOCOUNT ON; 

	SET @MeterReadingCount = 0; 

	IF( @IsEstimatedInactivation = 0 ) 
	BEGIN 

		SELECT 
			* 
			INTO #MeterReadingInfo 
		FROM 
			@MeterReadingInactivationInfo  
		WHERE 
			CPUAssetId IS NOT NULL

		INSERT INTO 
			#MeterReadingInfo
			SELECT 
				DISTINCT 
				MeterReadingInfo.ContractSequenceNumber,MeterReadingInfo.ScheduleNumber,CPUAssets.Id,MeterReadingInfo.EffectiveDate
			FROM 
				@MeterReadingInactivationInfo MeterReadingInfo
				INNER JOIN CPUContracts ON MeterReadingInfo.ContractSequenceNumber = CPUContracts.SequenceNumber
				INNER JOIN CPUFinances ON CPUContracts.CPUFinanceId = CPUFinances.Id
				INNER JOIN CPUSchedules ON CPUFinances.Id = CPUSchedules.CPUFinanceId AND MeterReadingInfo.ScheduleNumber = CPUSchedules.ScheduleNumber
				INNER JOIN CPUAssets ON CPUSchedules.Id = CPUAssets.CPUScheduleId
			WHERE 
				MeterReadingInfo.CPUAssetId IS NULL 
				AND CPUSchedules.IsActive = 1 
				AND CPUAssets.IsActive = 1

		SELECT 
			@MeterReadingCount = COUNT(CPUAssetMeterReadings.Id) 
		FROM 
			CPUAssetMeterReadings
			JOIN #MeterReadingInfo ON CPUAssetMeterReadings.CPUAssetId = #MeterReadingInfo.CPUAssetId
		WHERE 
			CPUAssetMeterReadings.IsActive =1 
			AND CPUAssetMeterReadings.EndPeriodDate > #MeterReadingInfo.EffectiveDate

	END 
	ELSE 
	BEGIN 

		SELECT 
			@MeterReadingCount = COUNT(CPUAssetMeterReadings.Id) 
		FROM   
			@MeterReadingInactivationInfo MeterReadingInactivationInfo                    
			JOIN CPUAssetMeterReadings ON MeterReadingInactivationInfo.CPUAssetId = CPUAssetMeterReadings.CPUAssetId 
		WHERE  
			CPUAssetMeterReadings.IsActive = 1                   
			AND CPUAssetMeterReadings.EndPeriodDate >=  MeterReadingInactivationInfo.EffectiveDate
	END 

	IF OBJECT_ID('tempdb..#MeterReadingInfo', 'U') IS NOT NULL
	DROP TABLE #MeterReadingInfo

	SELECT @MeterReadingCount 

	SET NOCOUNT OFF; 

END 


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[GetCPUMeterReadingProjectionInfo]
(
	@ProjectedMeterReadings [dbo].ProjectedMeterReadingInfo READONLY,
	@ExistingMeterReadings [dbo].ExistingMeterReadingInfo NULL READONLY
)
AS
BEGIN
SET NOCOUNT ON;

	SELECT   
		DISTINCT *  
	INTO #FinalMeterReadingCache  
	FROM   
	(
		SELECT 
			Id ,
			CPUScheduleId ,
			BeginPeriodDate ,
			EndPeriodDate ,
			EndReading ,
			Reading ,
			ServiceCredits ,
			CPUAssetId ,
			CPUOverageAssessmentId ,
			AssessmentEffectiveDate ,
			IsEstimated ,
			Source
		FROM
			@ProjectedMeterReadings
		WHERE 
			IsActive = 1
		
	UNION
		
		SELECT 
			* 
		FROM 
			@ExistingMeterReadings
		
		WHERE 
			Id NOT IN (SELECT Id FROM @ProjectedMeterReadings)
	) 
	AS DistinctMeterReading

SELECT * FROM #FinalMeterReadingCache

SELECT 
	CPUOverageAssessments.Id AS CPUOverageAssessmentId,
	CAST(1 AS BIT) AS IsAdjustmentPending,	
	P.CPUScheduleId,
	Receivables.Id AS ReceivableId,
	CPUOverageAssessmentDetails.MeterReadingId
INTO 
	#AssessmentInfo
FROM
	@ProjectedMeterReadings P 
	JOIN CPUOverageAssessments ON P.CPUOverageAssessmentId = CPUOverageAssessments.Id
	JOIN CPUOverageAssessmentDetails ON CPUOverageAssessmentDetails.CPUOverageAssessmentId = CPUOverageAssessments.Id  
	JOIN Receivables ON CPUOverageAssessmentDetails.ReceivableId = Receivables.Id
WHERE 
	CPUOverageAssessments.IsAdjustmentPending = 0 

SELECT DISTINCT
	CPUOverageAssessmentId AS Id,
	IsAdjustmentPending,
	CPUScheduleId
FROM
	#AssessmentInfo

SELECT DISTINCT
	ReceivableId,
	IsAdjustmentPending,
	MeterReadingId,
	CPUOverageAssessmentId
FROM
	#AssessmentInfo

SET NOCOUNT OFF;
END

GO

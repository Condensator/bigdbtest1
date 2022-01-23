SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetCPUSchMeterReadingReportReceivableInfo]
@CPUScheduleId BIGINT
AS
BEGIN

SET NOCOUNT ON;

	CREATE TABLE #OverageReceivableInvoiceInfo
	(
		ReceivableId								BIGINT NOT NULL,
		IsAdjustedReceivable						BIT NOT NULL,
		OverageReceivableInvoiceNumber				NVARCHAR(max) NOT NULL
	)

	CREATE TABLE #MeterReadingRecSuppInfo
	(
		ReceivableId								BIGINT NOT NULL,
		CPUOverageReceivableInfoeBeginPeriodDate	DATE NOT NULL,
		CPUAssetmeterreadingsBeginPeriodDate		DATE NOT NULL,
		CPUOverageReceivableInfoeEndPeriodDate		DATE NOT NULL,
		CPUAssetmeterreadingsEndPeriodDate			DATE NOT NULL,
		BeginReading								BIGINT NOT NULL,
		EndReading									BIGINT NOT NULL,
		ServiceCredits								BIGINT NOT NULL,
		BaseAllowance								BIGINT NOT NULL,
		OverageAllowance							BIGINT NOT NULL,
		OverageReceivableGroupInfoId				BIGINT NOT NULL,
		IsMeterReadingOnPayoffDate					BIT NOT NULL,
		IsMeterReadingOnAssetBeginDate				BIT NOT NULL
	);
	CREATE INDEX NonClustered_ReceivableId ON #MeterReadingRecSuppInfo(ReceivableId);


	CREATE TABLE #MeterReadingRecInfo
	(
		ReceivableId					BIGINT NOT NULL,
		OriginalReceivableId			BIGINT NULL,
		OverageReceivableInvoiceNumber	NVARCHAR(40),
		IsAdjustedReceivable			BIT NOT NULL
	);


	CREATE TABLE #MeterReadingRecDetailInfo
	(		
		ReceivableId		BIGINT NOT NULL,
		BeginPeriodDate		DATE NOT NULL,
		EndPeriodDate		DATE NOT NULL,
		BaseAllowance		BIGINT NOT NULL,
		OverageAllowance	BIGINT NOT NULL,
		TotalBeginReading	BIGINT NOT NULL,
		TotalEndReading		BIGINT NOT NULL,
		TotalServiceCredits BIGINT NOT NULL,
		OverageReceivableGroupInfoId			BIGINT NOT NULL
	);

	

	INSERT INTO 
		#MeterReadingRecInfo
	SELECT 
		DISTINCT 
			ReceivableDetails.ReceivableId			AS ReceivableId,
			ReceivableDetails.ReceivableId			AS OriginalReceivableId,
			ISNULL(ReceivableInvoices.Number, '')	AS OverageReceivableInvoiceNumber,
			0										AS IsAdjustedReceivable				
	FROM
		CPUBaseStructures
		JOIN CPUAssets							ON	CPUBaseStructures.Id = CPUAssets.CPUScheduleId 
													AND CPUBaseStructures.Id =  @CPUScheduleId 
													AND 1 = CPUAssets.IsActive
		JOIN CPUAssetMeterReadings				ON	CPUAssets.Id = CPUAssetMeterReadings.CPUAssetId
		JOIN CPUOverageAssessmentDetails		ON	CPUAssetMeterReadings.Id = CPUOverageAssessmentDetails.MeterReadingId
		JOIN ReceivableDetails 					ON	CPUOverageAssessmentDetails.ReceivableId = ReceivableDetails.ReceivableId
		LEFT JOIN ReceivableInvoiceDetails		ON	ReceivableDetails.Id = ReceivableInvoiceDetails.ReceivableDetailId AND ReceivableInvoiceDetails.IsActive = 1
		LEFT JOIN ReceivableInvoices			ON	ReceivableInvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id AND ReceivableInvoices.IsActive = 1	


	INSERT INTO 
		#MeterReadingRecInfo
	SELECT 
		DISTINCT 
			AdjRd.ReceivableId						AS ReceivablId, 
			Info.ReceivableId						AS OriginalReceivableId,
			ISNULL(ReceivableInvoices.Number, '')	AS OverageReceivableInvoiceNumber,
			1										AS IsAdjustedReceivable
	FROM
		#MeterReadingRecInfo Info
		JOIN ReceivableDetails RecDetail		ON  Info.ReceivableId = RecDetail.ReceivableId
		JOIN ReceivableDetails AdjRd			ON  RecDetail.Id = AdjRd.AdjustmentBasisReceivableDetailId
		LEFT JOIN ReceivableInvoiceDetails		ON	AdjRd.Id = ReceivableInvoiceDetails.ReceivableDetailId AND ReceivableInvoiceDetails.IsActive = 1
		LEFT JOIN ReceivableInvoices			ON	ReceivableInvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id AND ReceivableInvoices.IsActive = 1	
		


	INSERT INTO 
		#MeterReadingRecSuppInfo
	SELECT
		CPUOverageAssessmentDetails.ReceivableId,
		CPUOverageReceivableGroupInfoes.BeginPeriodDate AS CPUOverageReceivableInfoeBeginPeriodDate,
		CPUAssetmeterreadings.BeginPeriodDate AS CPUAssetmeterreadingsBeginPeriodDate,
		CPUOverageReceivableGroupInfoes.EndPeriodDate AS CPUOverageReceivableInfoeEndPeriodDate,
		CPUAssetmeterreadings.EndPeriodDate AS CPUAssetmeterreadingsEndPeriodDate,
		CPUAssetMeterReadings.BeginReading,
		CPUAssetMeterReadings.EndReading,
		ServiceCredits,
		CPUOverageReceivableGroupInfoes.BaseAllowance,
		CPUOverageReceivableGroupInfoes.OverageAllowance,
		CPUOverageReceivableGroupInfoes.Id,
		--TO DO : Below condition to be modified as 'WHEN CPUAssets.PayoffDate IS NOT NULL AND CPUAssets.PayoffDate = CPUAssetmeterreadings.EndPeriodDate THEN CAST(1 AS BIT)' once PROD-6536 is merged to Product code base
		CASE 
			WHEN 
				CPUAssets.PayoffDate IS NOT NULL 
				AND 
				(
					(
						CPUBaseStructures.IsAggregate = 0 AND 
						CPUAssets.PayoffDate = CPUAssetmeterreadings.EndPeriodDate
					)
					OR 
					(
						CPUBaseStructures.IsAggregate = 1 AND 
						CPUAssets.PayoffDate >= CPUAssetmeterreadings.BeginPeriodDate AND 
						CPUAssets.PayoffDate <= CPUAssetmeterreadings.EndPeriodDate
					)
				)
			THEN 
				CAST(1 AS BIT)
			ELSE 
				CAST(0 AS BIT)
		END 
			AS IsMeterReadingOnPayoffDate,

		CASE 
			WHEN 
				CPUAssets.BeginDate = CPUAssetmeterreadings.BeginPeriodDate
			THEN 
				CAST(1 AS BIT)
			ELSE 
				CAST(0 AS BIT)
		END AS 
			IsMeterReadingOnAssetBeginDate

	FROM
		CPUBaseStructures						
		INNER JOIN CPUAssets						ON	CPUBaseStructures.Id = CPUAssets.CPUScheduleId 
														AND CPUBaseStructures.Id  = @CPUScheduleId
														AND CPUAssets.IsActive = 1
		INNER JOIN CPUAssetmeterreadings			ON CPUAssets.Id = CPUAssetMeterReadings.CPUAssetId
		INNER JOIN CPUOverageAssessmentDetails		ON CPUAssetMeterReadings.Id = CPUOverageAssessmentDetails.MeterReadingId
		INNER JOIN CPUOverageReceivableInfoes		ON CPUOverageAssessmentDetails.ReceivableId = CPUOverageReceivableInfoes.ReceivableId 
		INNER JOIN CPUOverageReceivableGroupInfoes  ON CPUOverageReceivableInfoes.CPUOverageReceivableGroupInfoId = CPUOverageReceivableGroupInfoes.Id

	SELECT
		ReceivableId,
		SUM(BeginReading) As BeginReading 
	INTO 
		#BeginReadingTemp
	FROM
		#MeterReadingRecSuppInfo
	WHERE 
		CPUOverageReceivableInfoeBeginPeriodDate = CPUAssetmeterreadingsBeginPeriodDate
		OR IsMeterReadingOnAssetBeginDate = 1 
	GROUP BY 
		ReceivableId

	
	SELECT
		ReceivableId,
		SUM(EndReading) As EndReading
	INTO 
		#EndReadingTemp
	FROM
		#MeterReadingRecSuppInfo
	WHERE 
		CPUAssetmeterreadingsEndPeriodDate = CPUOverageReceivableInfoeEndPeriodDate
		OR
		IsMeterReadingOnPayoffDate = 1
	GROUP BY 
		ReceivableId

	SELECT
		ReceivableId,
		SUM(ServiceCredits) As ServiceCredits
	INTO 
		#ServiceCreditTemp
	FROM
		#MeterReadingRecSuppInfo			
	GROUP BY 
		ReceivableId


	INSERT INTO
		#MeterReadingRecDetailInfo
	SELECT DISTINCT
		#MeterReadingRecSuppInfo.ReceivableId,
		#MeterReadingRecSuppInfo.CPUOverageReceivableInfoeBeginPeriodDate,
		#MeterReadingRecSuppInfo.CPUOverageReceivableInfoeEndPeriodDate,
		#MeterReadingRecSuppInfo.BaseAllowance,
		#MeterReadingRecSuppInfo.OverageAllowance,
		#BeginReadingTemp.BeginReading,
		#EndReadingTemp.EndReading,
		#ServiceCreditTemp.ServiceCredits,
		#MeterReadingRecSuppInfo.OverageReceivableGroupInfoId
	From 
		#MeterReadingRecSuppInfo
		JOIN #BeginReadingTemp	ON #BeginReadingTemp.ReceivableId = #MeterReadingRecSuppInfo.ReceivableId
		JOIN #EndReadingTemp	ON #BeginReadingTemp.ReceivableId = #EndReadingTemp.ReceivableId
		JOIN #ServiceCreditTemp ON #EndReadingTemp.ReceivableId = #ServiceCreditTemp.ReceivableId


	SELECT  
		DISTINCT
			MAX(MRRecInfo.OriginalReceivableId) AS MaxReceivableId,
			MRRecDetailInfo.BeginPeriodDate,
			MRRecDetailInfo.EndPeriodDate,
			SUM(MRRecDetailInfo.TotalBeginReading) As TotalBeginReading,
			SUM(MRRecDetailInfo.TotalEndReading)  As TotalEndReading,
			SUM(MRRecDetailInfo.TotalServiceCredits) As TotalServiceCredits,
			MIN(MRRecDetailInfo.BaseAllowance) As BaseAllowance,
			MIN(MRRecDetailInfo.OverageAllowance) AS OverageAllowance,
			SUM(Receivables.TotalAmount_Amount)  AS OverageReceivableAmount_Amount,
			MIN(Receivables.TotalAmount_Currency) AS OverageReceivableAmount_Currency,
			CASE
				WHEN 
					(COUNT (MRRecInfo.OverageReceivableInvoiceNumber)>1) AND (DATALENGTH(MAX(MRRecInfo.OverageReceivableInvoiceNumber)) > 0 )
					THEN STRING_AGG(nullif(MRRecInfo.OverageReceivableInvoiceNumber,''),',') 
				ELSE
					MIN(MRRecInfo.OverageReceivableInvoiceNumber)
				END 
			As OverageReceivableInvoiceNumber,
			MRRecInfo.IsAdjustedReceivable,
			Receivables.IsActive
	INTO 
		#AggregateInfo
	FROM    
		#MeterReadingRecInfo MRRecInfo			           
		INNER JOIN Receivables							ON MRRecInfo.ReceivableId = Receivables.Id
		JOIN #MeterReadingRecDetailInfo	MRRecDetailInfo	ON MRRecInfo.OriginalReceivableId = MRRecDetailInfo.ReceivableId
	GROUP BY 
		MRRecDetailInfo.BeginPeriodDate,
		MRRecDetailInfo.EndPeriodDate,
		Receivables.IsActive,
		MRRecInfo.IsAdjustedReceivable,
		MRRecDetailInfo.OverageReceivableGroupInfoId;


	INSERT INTO 
		#OverageReceivableInvoiceInfo
		SELECT 
				overageReceivableInvoiceInfo.MaxReceivableId,
				overageReceivableInvoiceInfo.IsAdjustedReceivable,
				STRING_AGG(nullif(overageReceivableInvoiceInfo.OverageReceivableInvoiceNumber,''),',') WITHIN GROUP (ORDER BY overageReceivableInvoiceInfo.OverageReceivableInvoiceNumber ASC) AS OverageReceivableInvoiceNumber 
		FROM 
				(
					(SELECT DISTINCT 
								aggregateinfo.MaxReceivableId, 
								aggregateinfo.IsAdjustedReceivable,
								invoicenumber.value AS OverageReceivableInvoiceNumber
					  FROM 
						#AggregateInfo  AS aggregateinfo
						CROSS APPLY STRING_SPLIT(aggregateinfo.OverageReceivableInvoiceNumber,',') AS invoicenumber
					  WHERE OverageReceivableInvoiceNumber <> ''
					 ) 
				 ) AS overageReceivableInvoiceInfo 
		GROUP BY 
				overageReceivableInvoiceInfo.MaxReceivableId,
				overageReceivableInvoiceInfo.IsAdjustedReceivable


	UPDATE 
		aggregateinfo
		SET 
			aggregateinfo.OverageReceivableInvoiceNumber = overageReceivableInvoiceInfo.OverageReceivableInvoiceNumber 
		FROM 
			#AggregateInfo aggregateinfo
			JOIN #OverageReceivableInvoiceInfo overageReceivableInvoiceInfo
				ON aggregateinfo.MaxReceivableId = overageReceivableInvoiceInfo.ReceivableId AND aggregateinfo.IsAdjustedReceivable = overageReceivableInvoiceInfo.IsAdjustedReceivable

	SELECT 
		DISTINCT
			#AggregateInfo.MaxReceivableId AS ReceivableId,
			#AggregateInfo.BeginPeriodDate,
			#AggregateInfo.EndPeriodDate,
			TotalBeginReading,
			TotalEndReading,
			TotalServiceCredits,
			#AggregateInfo.BaseAllowance,
			#AggregateInfo.OverageAllowance,
			OverageReceivableAmount_Amount,
			OverageReceivableAmount_Currency,
			OverageReceivableInvoiceNumber,
			CASE 
				WHEN
					CPUOverageReceivableTierInfoes.Id IS NULL
					THEN ''
				WHEN
					COUNT(CPUOverageReceivableTierInfoes.Id) OVER (Partition by CPUOverageReceivableInfoes.Id,#AggregateInfo.MaxReceivableId,IsAdjustedReceivable) > 1
					THEN 'Various'
				
				ELSE
					CAST(CPUOverageReceivableTierInfoes.Rate AS NVARCHAR(40))
			END
			AS OverageTierRatesInfo,
			IsAdjustedReceivable,
			IsActive
	FROM
		#AggregateInfo
		JOIN CPUOverageReceivableInfoes					ON #AggregateInfo.MaxReceivableId = CPUOverageReceivableInfoes.ReceivableId
		LEFT JOIN CPUOverageReceivableTierInfoes		ON CPUOverageReceivableInfoes.Id = CPUOverageReceivableTierInfoes.CPUOverageReceivableInfoId



	---Dropping all Temp tables
	IF OBJECT_ID('tempdb..#MeterReadingRecInfo') IS NOT NULL						DROP TABLE #MeterReadingRecInfo;
	IF OBJECT_ID('tempdb..#MeterReadingRecDetailInfo') IS NOT NULL					DROP TABLE #MeterReadingRecDetailInfo;
	IF OBJECT_ID('tempdb..#MeterReadingRecSuppInfo') IS NOT NULL					DROP TABLE #MeterReadingRecSuppInfo;
	IF OBJECT_ID('tempdb..#BeginReadingTemp') IS NOT NULL							DROP TABLE #BeginReadingTemp;
	IF OBJECT_ID('tempdb..#EndReadingTemp') IS NOT NULL								DROP TABLE #EndReadingTemp;
	IF OBJECT_ID('tempdb..#ServiceCreditTemp') IS NOT NULL							DROP TABLE #ServiceCreditTemp;
	IF OBJECT_ID('tempdb..#AggregateInfo') IS NOT NULL								DROP TABLE #AggregateInfo;
	IF OBJECT_ID('tempdb..#OverageReceivableInvoiceInfo') IS NOT NULL				DROP TABLE #OverageReceivableInvoiceInfo

	SET NOCOUNT OFF;

END

GO

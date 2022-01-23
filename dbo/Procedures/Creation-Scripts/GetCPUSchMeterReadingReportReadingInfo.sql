SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetCPUSchMeterReadingReportReadingInfo]
@CPUScheduleId BIGINT,
@AssetMultipleSerialNumberType NVARCHAR(10)
AS
BEGIN

SET NOCOUNT ON;

	CREATE TABLE #MeterReadingRecDetailInfo
	(
		Id BIGINT Identity(1,1) PRIMARY KEY,
		ReceivableDetailId BIGINT NOT NULL,
		MeterReadingId BIGINT NOT NULL,
		CPUOverageReceivableInfoId BIGINT NOT NULL,
		IsReceivableAdjusted Bit NOT NULL
	);

	CREATE NONCLUSTERED INDEX IX_MeterReadingRecDetailInfo_MeterReadingId ON #MeterReadingRecDetailInfo (MeterReadingId);
	
	INSERT INTO 
		#MeterReadingRecDetailInfo
	SELECT 
		ReceivableDetails.Id as ReceivableDetailId, 
		CPUOverageAssessmentDetails.MeterReadingId, 
		CPUOverageReceivableInfoes.Id as CPUOverageReceivableInfoId,
		0  AS IsReceivableAdjusted
	FROM
		CPUBaseStructures
		JOIN CPUAssets						ON CPUBaseStructures.Id = CPUAssets.CPUScheduleId 
		JOIN CPUAssetMeterReadings			ON CPUAssets.Id = CPUAssetMeterReadings.CPUAssetId
		JOIN CPUOverageAssessmentDetails	ON CPUAssetMeterReadings.Id = CPUOverageAssessmentDetails.MeterReadingId
		JOIN CPUOverageReceivableInfoes		ON CPUOverageAssessmentDetails.ReceivableId = CPUOverageReceivableInfoes.ReceivableId
		JOIN ReceivableDetails 				ON CPUOverageAssessmentDetails.ReceivableId = ReceivableDetails.ReceivableId  AND ReceivableDetails.AssetId=CPUAssets.AssetId
	WHERE 
		CPUBaseStructures.Id = @CPUScheduleId 
		
		

	INSERT INTO 
		#MeterReadingRecDetailInfo
	SELECT 
		AdjRd.Id as ReceivableDetailId, 
		Info.MeterReadingId, 
		Info.CPUOverageReceivableInfoId,
		1 AS IsReceivableAdjusted
	FROM
		#MeterReadingRecDetailInfo Info
		JOIN ReceivableDetails AdjRd on Info.ReceivableDetailId = adjrd.AdjustmentBasisReceivableDetailId

    ;with CTE_AssetSerialNumberDetails AS(
		SELECT 
			ASN.AssetId,
			SerialNumber = CASE WHEN count(ASN.Id) > 1 THEN @AssetMultipleSerialNumberType ELSE MAX(ASN.SerialNumber) END  
		FROM (
			Select DISTINCT CPUAssets.AssetId from CPUBaseStructures				
			INNER JOIN CPUAssets ON [CPUBaseStructures].Id = [CPUAssets].[CPUScheduleId] AND [CPUBaseStructures].Id = @CPUScheduleId) A
		JOIN AssetSerialNumbers ASN on A.AssetId = ASN.AssetId AND ASN.IsActive=1
		GROUP BY ASN.AssetId
		)
	
	SELECT  DISTINCT
		[CPUAssets].[AssetId],
		[Assets].Alias,
		ASN.SerialNumber,
		[CPUAssetMeterReadings].BeginPeriodDate,
		[CPUAssetMeterReadings].EndPeriodDate,
		[CPUAssetMeterReadings].ReadDate,
		[CPUAssetMeterReadings].[Source],
		[CPUAssetMeterReadings].BeginReading,
		[CPUAssetMeterReadings].EndReading,
		[CPUAssetMeterReadings].Reading,
		[CPUAssetMeterReadings].ServiceCredits,
		CASE
			WHEN 
					(([CPUAssetMeterReadings].EndReading - [CPUAssetMeterReadings].BeginReading - [CPUAssetMeterReadings].ServiceCredits) < 0)
							THEN CAST (0 AS BIGINT) 
					ELSE 
							([CPUAssetMeterReadings].EndReading - [CPUAssetMeterReadings].BeginReading - [CPUAssetMeterReadings].ServiceCredits)
			END
		AS Usage,
		[CPUAssetMeterReadings].IsEstimated,
		[CPUAssetMeterReadings].MeterResetType,
		CASE  
			WHEN 
					(
						MAX([CPUAssetMeterReadings].EndPeriodDate) 
						OVER 
							(
								PARTITION BY [CPUAssets].Id, [CPUAssetMeterReadings].IsActive 
							)
					) = [CPUAssetMeterReadings].EndPeriodDate AND [CPUAssetMeterReadings].IsActive = 1
					THEN CAST(1 AS BIT)
				ELSE CAST(0 AS BIT)
			END			
		AS IsLatestMeterReading,
		CASE 
			WHEN 
				[CPUOverageReceivableInfoes].Id IS NULL OR [CPUBaseStructures].IsAggregate = 1
			THEN CAST (0 AS BIGINT)
			ELSE
				[CPUOverageReceivableGroupInfoes].BaseAllowance
			END
		AS BaseAllowance,
		CASE 
			WHEN 
				[CPUOverageReceivableInfoes].Id IS NULL OR [CPUBaseStructures].IsAggregate = 1
			THEN CAST (0 AS BIGINT)
			ELSE
				[CPUOverageReceivableGroupInfoes].OverageAllowance
			END
		AS OverageAllowance,
		CASE 
			WHEN 
				ReceivableDetails.Amount_Amount Is Null 
				OR 
				(
					--Below condition is used in case there is one receivable for more than one Meter Readings for one asset (for aggregate schedules) [Replace, as well as normal case]
					(
						MAX(CPUAssetMeterReadings.EndPeriodDate) 
						OVER 
						(
							PARTITION BY CPUAssets.Id, ReceivableDetails.Id
						)
					) != CPUAssetMeterReadings.EndPeriodDate 
					AND
					(
						MAX(CPUAssetMeterReadings.Id) 
						OVER 
						(
							PARTITION BY CPUAssets.Id, ReceivableDetails.Id
						)
					) != CPUAssetMeterReadings.Id 
				)
			THEN CAST (0 AS Decimal) 
			ELSE 
				ReceivableDetails.Amount_Amount 
			END 
		AS [OverageReceivableAmount_Amount],
		[CPUBaseStructures].[BaseAmount_Currency] AS [OverageReceivableAmount_Currency],
		ISNULL([ReceivableInvoices].Number, '') AS OverageReceivableInvoiceNumber,
		CASE 
			WHEN 
				[CPUOverageReceivableInfoes].Id IS NOT NULL AND CPUBaseStructures.IsAggregate=0
			THEN
				CASE WHEN
						COUNT([CPUOverageReceivableTierInfoes].Id) OVER (Partition by CPUOverageReceivableInfoes.Id, ReceivableDetails.Id) > 1 
					THEN 'Various'
					ELSE
						CASE 
							WHEN
								[CPUOverageReceivableTierInfoes].BeginUnit = -1  
							THEN ''
							ELSE
								CAST([CPUOverageReceivableTierInfoes].Rate AS NVARCHAR(40))
						END
			END
			ELSE
				''
		END
		AS OverageTierRatesInfo,
		[CPUAssetMeterReadings].IsCorrection,
		ISNULL(MRInfo.IsReceivableAdjusted, 0) AS [IsAdjustedReceivable],
		[CPUAssetMeterReadings].IsActive,
		ReceivableDetails.Id AS ReceivableDetailId,
		[CPUAssetMeterReadings].Id AS [AssetMeterReadingId],
		CASE 
			WHEN 
				Receivables.IsActive IS NULL 
				THEN CAST ('NotGenerated' AS NVARCHAR(15)) 
			WHEN 
				Receivables.IsActive = 1 
				THEN CAST ('Active' AS NVARCHAR(15)) 
			ELSE 
				CAST ('InActive' AS NVARCHAR(15)) 
		END 
		AS ReceivableStatus
	FROM    
		CPUBaseStructures				
		INNER JOIN CPUAssets							ON [CPUBaseStructures].Id = [CPUAssets].[CPUScheduleId] AND [CPUBaseStructures].Id = @CPUScheduleId 
		INNER JOIN Assets								ON [CPUAssets].[AssetId] = [Assets].[Id]
		INNER JOIN CPUAssetMeterReadings				ON [CPUAssets].Id = [CPUAssetMeterReadings].CPUAssetId
		LEFT JOIN #MeterReadingRecDetailInfo MRInfo		ON CPUAssetMeterReadings.Id = MRInfo.MeterReadingId
		LEFT JOIN ReceivableDetails						ON MRInfo.ReceivableDetailId = ReceivableDetails.Id
		LEFT JOIN Receivables							ON ReceivableDetails.ReceivableId = Receivables.Id 
		LEFT JOIN CPUOverageReceivableInfoes			ON MRInfo.CPUOverageReceivableInfoId = CPUOverageReceivableInfoes.Id
		LEFT JOIN CPUOverageReceivableGroupInfoes		ON CPUOverageReceivableInfoes.CPUOverageReceivableGroupInfoId = CPUOverageReceivableGroupInfoes.Id
		LEFT JOIN CPUOverageReceivableTierInfoes		ON CPUOverageReceivableTierInfoes.CPUOverageReceivableInfoId = MRInfo.CPUOverageReceivableInfoId
		LEFT JOIN ReceivableInvoiceDetails				ON [ReceivableDetails].[Id] = [ReceivableInvoiceDetails].[ReceivableDetailId] AND [ReceivableInvoiceDetails].[IsActive] = 1
		LEFT JOIN ReceivableInvoices					ON [ReceivableInvoiceDetails].[ReceivableInvoiceId] = [ReceivableInvoices].[Id]	AND [ReceivableInvoices].[IsActive] = 1
		LEFT JOIN CTE_AssetSerialNumberDetails ASN ON Assets.Id = ASN.AssetId

	---Dropping all Temp tables
	IF OBJECT_ID('tempdb..#MeterReadingRecDetailInfo') IS NOT NULL
	BEGIN
	DROP TABLE #MeterReadingRecDetailInfo;
	END

	SET NOCOUNT OFF;

END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[GetCPUContractDataCacheForBaseChargeReversalAssessment]
(
	@CPUContractInfo CPUContractDataCacheInputForBaseChargeReversalAssessment READONLY	
)
AS
BEGIN
	
	SET NOCOUNT ON;

	CREATE TABLE #Temp 
	(
	 PayableId BIGINT NULL, 
	 ReceivableId BIGINT NOT NULL, 
	 CPUScheduleId BIGINT NOT NULL, 
	 CurrencyCode NVARCHAR(3) NOT NULL, 
	 ReceivableEntityType NVARCHAR(2) NOT NULL, 
	 CPUContractSequenceNumber NVARCHAR(40) NOT NULL,
	 IsServiceOnlyAsset BIT NOT NULL,
	 IsPerfectPay BIT NOT NULL,
	 CPUAssetId BIGINT NOT NULL,
	)

	DECLARE @ConsolidatedCPUAssetIds NVARCHAR(MAX) = ''
	
	SELECT
		@ConsolidatedCPUAssetIds += CONCAT(CPUAssetIds, ',')
	FROM
		@CPUContractInfo
	WHERE 
		CPUAssetIds != ''

	SET @ConsolidatedCPUAssetIds = SUBSTRING(@ConsolidatedCPUAssetIds, 0, LEN(@ConsolidatedCPUAssetIds))

	SELECT
		CPUAssets.Id ,CPUAssets.CPUScheduleId, CPUAssets.ContractId , CPUAssets.RemitToId , CPUAssets.IsServiceOnly
	INTO
		#CPUAssetInfo
	FROM
		CPUAssets
		JOIN ConvertCSVToBigIntTable(@ConsolidatedCPUAssetIds, ',') ConsolidatedCPUAssetIds ON CPUAssets.Id = ConsolidatedCPUAssetIds.ID


	/*Include the Remaining CPUAssetIds for which the Base Receivable group is created.*/
	SELECT
		DISTINCT
		CPUAssets.Id,
		CPUAssets.CPUScheduleId AS CPUScheduleId
	INTO
		#CPUAssetIds
	FROM
		CPUAssets
		JOIN #CPUAssetInfo ON	CPUAssets.CPUScheduleId = #CPUAssetInfo.CPUScheduleId
								AND (COALESCE(CPUAssets.ContractId, '') = COALESCE(#CPUAssetInfo.ContractId, ''))
								AND CPUAssets.RemitToId = #CPUAssetInfo.RemitToId
								AND CPUAssets.IsServiceOnly = #CPUAssetInfo.IsServiceOnly


	SELECT CPUSchedules.Id AS CPUScheduleId, CPUAssets.Id AS CPUAssetId , IncludeAsset = IIF(#CPUAssetIds.Id IS NULL,0,1), IncludeAllAssets = IIF(COALESCE(CPUAssetIds, '') = '',1,0)
	INTO #EligibleAssets
	FROM @CPUContractInfo ContractInfo
	JOIN CPUSchedules ON CPUSchedules.Id = ContractInfo.CPUScheduleId
	JOIN CPUAssets ON CPUSchedules.Id = CPUAssets.CPUScheduleId 
	LEFT JOIN #CPUAssetIds ON #CPUAssetIds.Id = CPUAssets.Id

	CREATE CLUSTERED INDEX IX_CPUScheduleId ON #CPUAssetIds ([CPUScheduleId])

	INSERT INTO #Temp (ReceivableId, CPUScheduleId, CurrencyCode, ReceivableEntityType, CPUContractSequenceNumber, IsServiceOnlyAsset, IsPerfectPay, CPUAssetId)
	SELECT
		DISTINCT
			Receivables.Id AS ReceivableId,
			CPUSchedules.Id AS CPUScheduleId,
			CurrencyCodes.ISO AS CurrencyCode,
			Receivables.EntityType AS ReceivableEntityType,
			CPUContracts.SequenceNumber AS CPUContractSequenceNumber,
			CPUAssets.IsServiceOnly AS IsServiceOnlyAsset,
			CPUBillings.IsPerfectPay,
			CPUAssets.Id AS CPUAssetId
	FROM
		@CPUContractInfo CI
		JOIN CPUContracts						ON	CPUContracts.Id = CI.CPUContractId
		JOIN CPUSchedules						ON	CI.CPUScheduleId = CPUSchedules.Id
		JOIN CPUBaseStructures					ON	CPUBaseStructures.Id = CI.CPUScheduleId
		JOIN CPUAssets							ON  CPUSchedules.Id = CPUAssets.CPUScheduleId
		JOIN Receivables						ON	Receivables.SourceId = CPUSchedules.Id AND Receivables.SourceTable = 'CPUSchedule'
													AND Receivables.DueDate >= CI.ReverseFrom AND Receivables.PaymentScheduleId IS NOT NULL
		JOIN ReceivableDetails					ON	ReceivableDetails.ReceivableId = Receivables.Id AND ReceivableDetails.AdjustmentBasisReceivableDetailId IS NULL
													AND ReceivableDetails.AssetId = CPUAssets.AssetId
		JOIN CPUFinances						ON	CPUSchedules.CPUFinanceId = CPUFinances.Id
		JOIN CPUBillings						ON  CPUFinances.Id = CPUBillings.Id
		JOIN Currencies							ON	CPUFinances.CurrencyId = Currencies.Id
		JOIN CurrencyCodes						ON	Currencies.CurrencyCodeId = CurrencyCodes.Id
		JOIN #EligibleAssets					ON  CPUAssets.Id = #EligibleAssets.CPUAssetId
		LEFT JOIN ReceivableDetails AdjRec		ON	AdjRec.AdjustmentBasisReceivableDetailId = ReceivableDetails.Id
		
	WHERE
		CPUBaseStructures.NumberofPayments > 0
		AND Receivables.IsActive = 1
		AND	(#EligibleAssets.IncludeAllAssets = 1 OR #EligibleAssets.IncludeAsset = 1)
		AND AdjRec.Id IS NULL
	OPTION (MAXDOP 1)

	UPDATE #Temp SET PayableId = Payables.Id
	FROM #Temp
	LEFT JOIN Payables						ON	ReceivableId = Payables.SourceId
												AND Payables.SourceTable = 'Receivable'
												AND Payables.Status != 'Inactive'
												AND Payables.AdjustmentBasisPayableId IS NULL
	LEFT JOIN Payables AdjPay				ON  Payables.Id = AdjPay.AdjustmentBasisPayableId
	WHERE AdjPay.Id IS NULL

	SELECT #Temp.ReceivableId INTO #ACHReceivableToExclude FROM  #Temp 
    JOIN ACHSchedules ACHS ON #Temp.ReceivableId = ACHS.ReceivableId
	AND ACHS.IsACtive=1 AND ACHS.Status='FileGenerated'

	SELECT #Temp.ReceivableId INTO #OIReceivableToExclude FROM  #Temp 
	JOIN ReceivableDetails RD ON #Temp.ReceivableId = RD.ReceivableId AND Rd.IsActive=1
    JOIN OneTimeACHReceivableDetails OTACHRD ON RD.Id = OTACHRD.ReceivableDetailID AND OTACHRD.IsActive=1
	JOIN OneTimeACHSchedules OTACHS ON OTACHS.Id= OTACHRD.OneTimeACHScheduleId AND OTACHS.IsActive=1
	JOIN OneTimeACHInvoices OTI ON OTI.ReceivableInvoiceId = OTACHS.ReceivableInvoiceId
	AND OTI.IsACtive=1 AND OTI.Status='FileGenerated'

	SELECT #Temp.ReceivableId INTO #ORReceivableToExclude FROM  #Temp 
    JOIN ONeTImeACHReceivables OTR ON OTR.ReceivableId = #Temp.ReceivableId 
	AND OTR.IsACtive=1 AND OTR.Status='FileGenerated'

	SELECT #Temp.* FROM #Temp
	LEFT JOIN #ACHReceivableToExclude on #ACHReceivableToExclude.ReceivableId = #Temp.ReceivableId
	LEFT JOIN #OIReceivableToExclude on #OIReceivableToExclude.ReceivableId = #Temp.ReceivableId
	LEFT JOIN #ORReceivableToExclude on #ORReceivableToExclude.ReceivableId = #Temp.ReceivableId
	WHERE #ORReceivableToExclude.ReceivableId IS NULL AND #OIReceivableToExclude.ReceivableId IS NULL AND #ACHReceivableToExclude.ReceivableId IS NULL



	--Unique Identifier for CPI Receivable Adjustments - Sales Tax Reversal
	SELECT NEXT VALUE FOR SalesTaxJobStepInstanceIdentifier AS CPUUniqueIdentifierValue;


	IF OBJECT_ID('tempdb..#CPUAssetIds') IS NOT NULL DROP TABLE #CPUAssetIds 
	IF OBJECT_ID('tempdb..#CPUAssetInfo') IS NOT NULL DROP TABLE #CPUAssetInfo 
	IF OBJECT_ID('tempdb..#Temp') IS NOT NULL DROP TABLE #Temp 
	IF OBJECT_ID('tempdb..#EligibleAssets') IS NOT NULL DROP TABLE #EligibleAssets 

	SET NOCOUNT OFF;
END

GO

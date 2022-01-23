SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


  
CREATE PROCEDURE [dbo].[GetReceiptOTPReceivableDetailsForPosting]
(    
	@ReceiptIds ReceiptIdModel						READONLY,    
	@JobStepInstanceId								BIGINT,
	@LeaseContractTypeValues_Operating				NVARCHAR(10),
	@PaymentTypeValues_OTP							NVARCHAR(10),
	@PaymentTypeValues_Supplemental					NVARCHAR(20),
	@AccountingTreatmentValues_CashBased			NVARCHAR(20),
	@AssetValueSourceModuleValues_OTPDepreciation	NVARCHAR(20),
	@AssetValueSourceModuleValues_ResidualRecapture	NVARCHAR(20),
	@AssetValueSourceModuleValues_ResidualReclass	NVARCHAR(20),
	@IsFromReceiptApplication						BIT,
	@IsFromReceiptReversal							BIT
)    
AS    
BEGIN    
SET NOCOUNT ON;    
    
	SELECT Id INTO #ReceiptIds FROM @ReceiptIds; 
	SELECT         
		 [ReceivableDetailId]      
		,[AssetId]      
		,[AssetComponentType]     
		,[SequenceNumber]   
		,[Balance]      
		,[ReceiptApplicationReceivableDetailId]      
		,[AmountApplied]      
		,[ReceiptId]      
		,[ReceivableId]      
		,[ReceivableDueDate]     
		,[ReceivableIncomeType]   
		,[ReceivableBalance]      
		,[PaymentScheduleId]      
		,[LeaseFinanceId]      
		,[LegalEntityId]      
		,[InstrumentTypeId]      
		,[CostCenterId]    
		,[ContractId]  
		,[BranchId]      
		,[IsNonAccrual]      
		,[NonAccrualDate]      
		,[LineofBusinessId]      
		,[IncomeGLTemplateId]      
		,[TotalRentalAmount]      
		,[TotalDepreciationAmount] 
		,[AmountAppliedForDepreciation]
		,CAST(0 AS DECIMAL(16, 2)) AS PreviousDepreciationAmount
		,[IsReApplication] 
		,CAST(NULL AS BIGINT) AS AssetValueHistoryDetailId
		,[IsAdjustmentReceivableDetail]
	INTO #OtpReceivableDetails      
	FROM #ReceiptIds AS ReceiptIds          
	JOIN ReceiptOTPReceivables_Extract ON         
	ReceiptOTPReceivables_Extract.ReceiptId = ReceiptIds.Id AND       
	ReceiptOTPReceivables_Extract.JobStepInstanceId = @JobStepInstanceId    
    ;

	SELECT 
		LeaseFinances.Id as LeaseFinanceId,
		ContractId,
		CASE WHEN LeaseFinanceDetails.LeaseContractType = @LeaseContractTypeValues_Operating THEN 
			CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsOperating,
		LeaseFinanceDetails.Id as LeaseFinanceDetailId
	INTO #Contracts 
	FROM LeaseFinances 
	INNER JOIN 
		LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id AND LeaseFinances.IsCurrent = 1
	WHERE ContractId IN (SELECT ContractId FROM #OtpReceivableDetails)   
    ;

	SELECT 
		LeasePaymentSchedules.Id AS LeasePaymentScheduleId, 
		CashBasedLeaseIncome.LeaseIncomeScheduleId AS LeaseIncomeScheduleId,
		CashBasedLeaseIncome.IsGLPosted,
		#Contracts.ContractId AS ContractId,
		LeasePaymentSchedules.StartDate AS PaymentStartDate,
		LeasePaymentSchedules.EndDate AS PaymentEndDate,
		#Contracts.LeaseFinanceId,
		#Contracts.IsOperating
	INTO #ContractDetails
	FROM #Contracts 
	INNER JOIN LeasePaymentSchedules ON LeasePaymentSchedules.LeaseFinanceDetailId = #Contracts.LeaseFinanceDetailId        
		AND LeasePaymentSchedules.PaymentType IN (@PaymentTypeValues_OTP, @PaymentTypeValues_Supplemental)  
		AND LeasePaymentSchedules.IsActive=1   
	INNER JOIN 
		(SELECT #Contracts.ContractId,
				LeaseIncomeSchedules.Id LeaseIncomeScheduleId,
				LeaseIncomeSchedules.IncomeDate,
				LeaseIncomeSchedules.IsGLPosted
		FROM #Contracts
		INNER JOIN LeaseFinances ON #Contracts.ContractId = LeaseFinances.ContractId
		INNER JOIN LeaseIncomeSchedules ON LeaseFinances.Id = LeaseIncomeSchedules.LeaseFinanceId
		WHERE LeaseIncomeSchedules.IsSchedule=1 AND LeaseIncomeSchedules.IsAccounting = 1
		AND LeaseIncomeSchedules.AccountingTreatment = @AccountingTreatmentValues_CashBased
		) AS CashBasedLeaseIncome 
	ON #Contracts.ContractId = CashBasedLeaseIncome.ContractId  
	AND CashBasedLeaseIncome.IncomeDate BETWEEN LeasePaymentSchedules.StartDate 
	AND LeasePaymentSchedules.EndDate
	;

	WITH CTE_LeaseAssets AS
	(
		SELECT
			LeaseAssets.AssetId,
			#Contracts.LeaseFinanceId,
			#Contracts.IsOperating,
			LeaseAssets.IsFailedSaleLeaseback AS IsFailedSaleLeaseBackAsset
		FROM #Contracts
		INNER JOIN LeaseAssets 
		ON #Contracts.LeaseFinanceId = LeaseAssets.LeaseFinanceId
		AND (LeaseAssets.IsActive = 1 OR LeaseAssets.TerminationDate IS NOT NULL)

	)
	SELECT 
		 #ContractDetails.ContractId AS ContractId
		,LeaseAssets.AssetId AS AssetId
		,#ContractDetails.PaymentStartDate
		,#ContractDetails.PaymentEndDate
		,#ContractDetails.LeasePaymentScheduleId
		,A.GLJournalId
		,A.SourceModule,A.amountposted
		,A.ValueAmount
		,A.EndBookValue
		,A.BeginBookValue
		,A.Id AS AssetValueHistoryId
		,MAX(A.amountposted) AS RunningDepreciationAmount
		,SUM(A.ValueAmount) 
			OVER (
				PARTITION BY #ContractDetails.ContractId,LeaseAssets.AssetId,#ContractDetails.LeasePaymentScheduleId 
			) AS SumValueAmount
		,SUM(A.EndBookValue) 
			OVER (
				PARTITION BY #ContractDetails.ContractId,LeaseAssets.AssetId,#ContractDetails.LeasePaymentScheduleId
			) AS SumEndBookValue
		,MAX(A.Id) 
			OVER ( 
				PARTITION BY #ContractDetails.ContractId,LeaseAssets.AssetId,#ContractDetails.LeasePaymentScheduleId
			) AS MaxAssetValueHistoryId
	INTO #AssetValueHistoryDetails
	FROM #ContractDetails
	INNER JOIN CTE_LeaseAssets LeaseAssets ON #ContractDetails.LeaseFinanceId = LeaseAssets.LeaseFinanceId 
	INNER JOIN AssetIncomeSchedules   
		ON AssetIncomeSchedules.LeaseIncomeScheduleId = #ContractDetails.LeaseIncomeScheduleId  
		AND AssetIncomeSchedules.AssetId = LeaseAssets.AssetId and AssetIncomeSchedules.IsActive = 1  
	INNER JOIN (
		SELECT 
			AssetValueHistories.AssetId, AssetValueHistories.SourceModuleId,
			AssetValueHistories.Id, AssetValueHistories.SourceModule,
			AssetValueHistories.IncomeDate,
			AssetValueHistories.GLJournalId,
			ResidualReclass.EndBookValue_Amount AS BeginBookValue,
			AssetValueHistories.EndBookValue_Amount AS EndBookValue,
			AssetValueHistories.Value_Amount AS ValueAmount,
			SUM(AssetValueHistoryDetails.AmountPosted_Amount) AS AmountPosted
		FROM AssetValueHistories 
		INNER JOIN CTE_LeaseAssets LeaseAssets ON AssetValueHistories.AssetId = LeaseAssets.AssetId 
		LEFT JOIN AssetValueHistories ResidualReclass ON ResidualReclass.IsAccounted = 1 AND ResidualReclass.IsSchedule = 1   AND
			ResidualReclass.SourceModule IN (@AssetValueSourceModuleValues_ResidualReclass) AND ResidualReclass.AssetId = LeaseAssets.AssetId
			AND ResidualReclass.IsLeaseComponent = AssetValueHistories.IsLeaseComponent
		LEFT OUTER JOIN AssetValueHistoryDetails 
			ON AssetValueHistories.Id = AssetValueHistoryDetails.AssetValueHistoryId 
			AND AssetValueHistoryDetails.IsActive = 1
		WHERE AssetValueHistories.IsAccounted = 1 AND AssetValueHistories.IsSchedule = 1   
			AND AssetValueHistories.SourceModule IN (@AssetValueSourceModuleValues_OTPDepreciation, @AssetValueSourceModuleValues_ResidualRecapture)
			AND (LeaseAssets.IsOperating = 0 OR LeaseAssets.IsFailedSaleLeaseBackAsset = 1 OR AssetValueHistories.IsLeaseComponent = 0) 
		GROUP BY 
			AssetValueHistories.AssetId, AssetValueHistories.SourceModuleId,
			AssetValueHistories.IncomeDate, AssetValueHistories.GLJournalId, AssetValueHistories.Id, AssetValueHistories.SourceModule,
			ResidualReclass.EndBookValue_Amount, AssetValueHistories.EndBookValue_Amount, AssetValueHistories.Value_Amount
		) A
	ON AssetIncomeSchedules.AssetId = a.AssetId 
	AND a.IncomeDate BETWEEN #ContractDetails.PaymentStartDate and #ContractDetails.PaymentEndDate  
	where  a.Id IS NOT NULL 
	GROUP BY 
		#ContractDetails.ContractId,
		LeaseAssets.AssetId,
		#ContractDetails.PaymentStartDate,#ContractDetails.PaymentEndDate,#ContractDetails.LeasePaymentScheduleId,
		A.GLJournalId, A.SourceModule,A.amountposted,a.ValueAmount,a.EndBookValue,A.Id,A.BeginBookValue
	;

   ---SELECT--

	IF(@IsFromReceiptApplication = 1)
	BEGIN
		
		;WITH CTE_PreviousDepreciationAmount AS
		(
			SELECT 
				OTP.ReceivableDetailId
				,OTP.ReceiptApplicationReceivableDetailId
				,SUM(AVHD.AmountPosted_Amount) AS AmountPosted
			FROM #OtpReceivableDetails OTP 
			INNER JOIN ReceiptApplicationReceivableDetails RARD ON OTP.ReceivableDetailId = RARD.ReceivableDetailId AND RARD.IsActive = 1
			INNER JOIN ReceiptApplications RA ON RARD.ReceiptApplicationId = RA.Id AND OTP.ReceiptId = RA.ReceiptId
			INNER JOIN AssetValueHistoryDetails AVHD ON RARD.Id = AVHD.ReceiptApplicationReceivableDetailId AND AVHD.IsActive = 1
			WHERE OTP.ReceiptApplicationReceivableDetailId <> RARD.Id AND OTP.IsReApplication = 1
			GROUP BY
				OTP.ReceivableDetailId,
				OTP.ReceiptApplicationReceivableDetailId
		)
		UPDATE OTP
				SET OTP.PreviousDepreciationAmount = CTEPDA.AmountPosted
		FROM #OtpReceivableDetails OTP 
		JOIN CTE_PreviousDepreciationAmount CTEPDA ON OTP.ReceivableDetailId = CTEPDA.ReceivableDetailId
			AND OTP.ReceiptApplicationReceivableDetailId = CTEPDA.ReceiptApplicationReceivableDetailId
		;

	END

	IF(@IsFromReceiptReversal = 1)
	BEGIN
		UPDATE OTP
			SET OTP.PreviousDepreciationAmount = AVHD.AmountPosted_Amount,
			OTP.AssetValueHistoryDetailId = AVHD.Id
		FROM #OtpReceivableDetails OTP 
		INNER JOIN AssetValueHistoryDetails AVHD ON OTP.ReceiptApplicationReceivableDetailId = AVHD.ReceiptApplicationReceivableDetailId AND AVHD.IsActive = 1

	END

	SELECT * FROM #OtpReceivableDetails

   SELECT 
		LeasePaymentSchedules.LeaseFinanceDetailId as LeaseFinanceId,      
		LeasePaymentSchedules.StartDate,      
		LeasePaymentSchedules.EndDate,      
		LeasePaymentSchedules.Amount_Amount as Amount,      
		LeasePaymentSchedules.Id      
	FROM LeasePaymentSchedules 
	INNER JOIN #Contracts ON LeasePaymentSchedules.LeaseFinanceDetailId = #Contracts.LeaseFinanceId      
	WHERE LeasePaymentSchedules.PaymentType in (@PaymentTypeValues_OTP, @PaymentTypeValues_Supplemental);
	
	SELECT LeasePaymentScheduleId, LeaseIncomeScheduleId, IsGLPosted FROM #ContractDetails
	
	SELECT 
		ContractId, AssetId, PaymentStartDate, PaymentEndDate, SourceModule,
		MAX(RunningDepreciationAmount) AS RunningDepreciationAmount,
		MAX(MaxAssetValueHistoryId) AS AssetValueHistoryId
	FROM #AssetValueHistoryDetails
	GROUP BY 
		ContractId, AssetId, PaymentStartDate, PaymentEndDate, SourceModule

	SELECT 
		AssetValueHistoryId, MaxAssetValueHistoryId, EndBookValue AS EndBookValueAmount, 
		LeasePaymentScheduleId, BeginBookValue AS BeginBookValueAmount,
		CASE WHEN GLJournalId IS NOT NULL THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsGLPosted
	FROM #AssetValueHistoryDetails 
	WHERE GLJournalId IS NULL OR @IsFromReceiptReversal = 1 OR @IsFromReceiptApplication = 1
	     
  
	DROP TABLE #ReceiptIds    
	DROP TABLE #OtpReceivableDetails    
	DROP TABLE #Contracts    
	DROP TABLE #AssetValueHistoryDetails
 END

GO

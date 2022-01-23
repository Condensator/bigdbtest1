SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROC [dbo].[GetCPUContractDataCacheForOverageChargeGenerationAssessment]  
(  
	 @InputParam CPUContractDataCacheInputForOverageChargeGenerationAssessment READONLY, 
	 @CPIOverageReceivableType NVARCHAR(21),
	 @CommencedStatus NVARCHAR(10),
	 @PaidOffStatus NVARCHAR(10),
	 @InvoiceGenerationPayoffStatus NVARCHAR(25),
	 @SubmittedForFinalApprovalPayoffStatus NVARCHAR(25),
	 @PayoffTransactionType NVARCHAR(6)
)  
AS  
BEGIN  
  
	SET NOCOUNT ON;  

	--Preparing input Params
	SELECT 
		CPUContracts.Id AS CPUContractId,
		CPUContracts.SequenceNumber AS CPUContractSequenceNumber,
		CPUSchedules.Id AS CPUScheduleId,
		CPUSchedules.ScheduleNumber AS CPUScheduleNumber,
		CI.ComputedProcessThroughDate
	INTO #CPUContractInfo
	FROM 
		@InputParam CI
		JOIN CPUContracts ON CI.CPUContractId =  CPUContracts.Id
		JOIN CPUSchedules ON CPUContracts.CPUFinanceId = CPUSchedules.CPUFinanceId AND CPUSchedules.Id = CI.CPUScheduleId


	--CPU Contract Info  
	SELECT   
		DISTINCT  
			CPUContracts.Id,  
			CPUContracts.SequenceNumber AS CPUContractSequenceNumber,  
			CPUFinances.CustomerId,  
			CPUFinances.CurrencyId,  
			CurrencyCodes.ISO AS CurrencyCode,  
			CPUFinances.LegalEntityId,   
			CPUBillings.IsPerfectPay,  
			CPUFinances.DueDay,  
			CPUFinances.IsAdvanceBilling  
	FROM   
		#CPUContractInfo CI   
		JOIN CPUContracts	ON CI.CPUContractId = CPUContracts.ID AND CI.CPUContractSequenceNumber = CPUContracts.SequenceNumber  
		JOIN CPUFinances	ON CPUContracts.CPUFinanceId = CPUFinances.Id  
		JOIN CPUBillings	ON CPUFinances.Id = CPUBillings.Id  
		JOIN Currencies		ON CPUFinances.CurrencyId = Currencies.Id  
		JOIN CurrencyCodes  ON Currencies.CurrencyCodeId = CurrencyCodes.Id  
  
  
	--CPU Schedule Info  
	SELECT   
		DISTINCT
			CPUSchedules.Id,  
			CPUSchedules.ScheduleNumber,  
			CPUScheduleAccountings.OverageFeeReceivableCodeId,  
			CPUScheduleAccountings.OverageFeePayableCodeId,  
			CI.ComputedProcessThroughDate,  
			CPUBaseStructures.DistributionBasis AS OverageAmountDistributionBasis,  
			CPUOverageStructures.PaymentFrequency AS OveragePaymentFrequency,  
			CPUBaseStructures.IsAggregate,  
			CPUSchedules.CommencementDate,  
			CPUOverageStructures.FrequencyStartDate,  
			CPUOverageStructures.OverageTier,  
			ReceivableCodes.DefaultInvoiceReceivableGroupingOption,  
			CPUBaseStructures.NumberofPayments,  
			CI.CPUContractId,
			CPUSchedules.PayoffDate,
			CASE   
					WHEN CPUOverageTiers.Id IS NOT NULL   
					THEN   
						CAST(1 AS BIT)   
					ELSE   
						CAST(0 AS BIT)   
					END AS HasOverageTier  
	FROM   
		#CPUContractInfo CI  
		JOIN CPUSchedules			ON CI.CPUScheduleId = CPUSchedules.Id AND CI.CPUScheduleNumber = CPUSchedules.ScheduleNumber  
		JOIN CPUBaseStructures		ON CPUSchedules.Id = CPUBaseStructures.Id  
		JOIN CPUScheduleBillings	ON CPUSchedules.Id = CPUScheduleBillings.Id  
		JOIN CPUScheduleAccountings ON CPUSchedules.Id = CPUScheduleAccountings.Id  
		JOIN CPUOverageStructures	ON CPUSchedules.Id = CPUOverageStructures.Id  
		LEFT JOIN CPUOverageTiers	ON CPUSchedules.Id = CPUOverageTiers.CPUOverageStructureId AND CPUOverageTiers.IsActive = 1
		JOIN ReceivableCodes		ON CPUScheduleAccountings.OverageFeeReceivableCodeId = ReceivableCodes.Id  
  

	--CPU Overage Tier Schedule Information
  	SELECT   
		CPUOverageTierSchedules.Id,
		CPUOverageTierSchedules.StartDate,	
		CPUSchedules.Id		 AS CPUScheduleId
	INTO
		#CPUOverageTierSchedulesInfo
	FROM   
		#CPUContractInfo CI
		JOIN CPUContracts					ON  CI.CPUContractId = CPUContracts.Id 
		JOIN CPUSchedules					ON	CPUContracts.CPUFinanceId = CPUSchedules.CPUFinanceId 
											AND CI.CPUScheduleNumber = CPUSchedules.ScheduleNumber  
		JOIN CPUOverageTierSchedules	    ON	CPUSchedules.Id = CPUOverageTierSchedules.CPUOverageStructureId  
	WHERE   
		CPUContracts.[Status] IN (@CommencedStatus, @PaidOffStatus)
		AND CPUSchedules.IsActive = 1     
		AND CPUOverageTierSchedules.IsActive = 1 
	

	SELECT * FROM #CPUOverageTierSchedulesInfo
	
	--CPU Overage Tier Schedule Detail Information
  	SELECT   
		CPUOverageTierScheduleDetails.BeginOverageUnit AS BeginUnit,
		CPUOverageTierScheduleDetails.OverageRate	  AS Rate,
		CPUOverageTierScheduleDetails.CPUOverageTierScheduleId	
	FROM   
		#CPUOverageTierSchedulesInfo CI
		JOIN CPUOverageTierScheduleDetails	ON 	CI.Id = CPUOverageTierScheduleDetails.CPUOverageTierScheduleId 	
 
	WHERE   
		CPUOverageTierScheduleDetails.IsActive = 1

	--CPU Escalation Information
  	SELECT   
		CPUOverageTierEscalations.EffectiveDate			AS EffectiveDate,
		CPUOverageTierEscalations.StepPeriod			AS StepPeriod,  
		CPUOverageTierEscalations.EscalationMethod		AS EscalationMethod, 
		CPUOverageTierEscalations.[Percentage]			AS Percentage,
		CPUOverageTierEscalations.Rate					AS Rate,
		CPUOverageTierEscalations.OverageDecimalPlaces	AS OverageDecimalPlaces,
		CPUSchedules.Id									AS CPUScheduleId
	FROM   
		CPUContracts				
		JOIN CPUFinances				ON	CPUContracts.CPUFinanceId = CPUFinances.Id      
		JOIN CPUSchedules				ON	CPUFinances.Id = CPUSchedules.CPUFinanceId  
		JOIN #CPUContractInfo CI		ON	CI.[CPUContractId] = CPUContracts.Id 
											AND CPUSchedules.ScheduleNumber = CI.CPUScheduleNumber  
		JOIN CPUOverageTierEscalations	ON	CPUSchedules.Id = CPUOverageTierEscalations.CPUOverageStructureId  
	WHERE   
		CPUContracts.[Status] IN (@CommencedStatus, @PaidOffStatus)
		AND CPUSchedules.IsActive = 1     
		AND CPUOverageTierEscalations.IsActive = 1  
		AND CPUOverageTierEscalations.EffectiveDate < CI.ComputedProcessThroughDate


	SELECT   
		DISTINCT *  
	INTO #CPUAssetInfo  
	FROM   
	(  
		-- Assessing meter reading for first time
		SELECT  
			CPUAssets.Id AS 'CPUAssetId',  
			CPUAssetMeterReadings.Id AS 'MeterReadingId',  
			CPUAssetMeterReadings.CPUOverageAssessmentId,  
			CI.CPUScheduleId  ,
			CPUAssets.PayoffDate,
			CI.ComputedProcessThroughDate,
			CPUAssets.ContractId,
			CPUAssets.AssetId
		FROM  
			CPUAssets  
			JOIN #CPUContractInfo CI			ON CPUAssets.CPUScheduleId = CI.CPUScheduleId  
			JOIN CPUSchedules					ON CI.CPUScheduleId = CPUSchedules.Id  
			LEFT JOIN CPUAssetMeterReadings		ON CPUAssetMeterReadings.CPUAssetId = CPUAssets.Id AND CPUAssetMeterReadings.IsActive = 1 AND CPUAssets.IsActive = 1  
		WHERE  
			CPUAssets.BeginDate <= CI.ComputedProcessThroughDate   
			AND 
			(
				CPUAssets.PayoffDate IS NULL OR CPUAssets.BeginDate != CPUAssets.PayoffDate
			)
  
		UNION  
  
		-- Correction/Inactivation meter reading  
		SELECT  
			CPUAssets.Id AS 'CPUAssetId',  
			CPUAssetMeterReadings.Id AS 'MeterReadingId',  
			CPUAssetMeterReadings.CPUOverageAssessmentId,  
			CI.CPUScheduleId  ,
			CPUAssets.PayoffDate,
			CI.ComputedProcessThroughDate,
			CPUAssets.ContractId,
			CPUAssets.AssetId
		FROM  
			CPUOverageAssessments  
			JOIN CPUAssetMeterReadings	ON CPUOverageAssessments.Id = CPUAssetMeterReadings.CPUOverageAssessmentId  
			JOIN CPUAssets				ON CPUAssetMeterReadings.CPUAssetId = CPUAssets.Id AND CPUAssets.IsActive = 1  
			JOIN #CPUContractInfo CI	ON CPUAssets.CPUScheduleId = CI.CPUScheduleId   
		WHERE  
			CPUAssets.BeginDate <= CI.ComputedProcessThroughDate  
			AND 
			(
				CPUAssets.PayoffDate IS NULL OR CPUAssets.BeginDate != CPUAssets.PayoffDate
			)
			AND CPUOverageAssessments.IsAdjustmentPending = 1  
  
	)   
	AS DistinctCPUAsset  
  

  --CPUAsset OverageDistributionBasis Amount info from Multiple Finance objects
	SELECT   
		CPUAssets.AssetId as AssetId,
		CPUAssets.OverageDistributionBasisAmount_Amount as OverageDistributionBasisAmount,  
		CPUContracts.SequenceNumber AS CPUContractSequenceNumber,   
		CPUSchedules.ScheduleNumber AS CPUScheduleNumber,
		CPUTransactions.CPUContractId,
		CPUSchedules.Id AS CPUScheduleId
	FROM       
		CPUTransactions       
		JOIN CPUContracts				ON CPUContracts.Id = CPUTransactions.CPUContractId      
		JOIN CPUFinances				ON CPUTransactions.CPUFinanceId = CPUFinances.Id      
		JOIN CPUSchedules				ON CPUFinances.Id = CPUSchedules.CPUFinanceId  
		JOIN #CPUContractInfo CI		ON CI.[CPUContractId] = CPUContracts.Id AND CPUSchedules.ScheduleNumber = CI.CPUScheduleNumber  
		JOIN CPUAssets					ON CPUAssets.CPUScheduleId = CPUSchedules.Id
		JOIN #CPUAssetInfo CAI			ON CPUAssets.AssetId = CAI.AssetId
		  
	WHERE   
		CPUContracts.[Status] IN (@CommencedStatus, @PaidOffStatus)
		AND CPUSchedules.IsActive = 1    
		AND CPUTransactions.Date <= CI.ComputedProcessThroughDate  
		AND CPUTransactions.IsActive = 1  
		AND CPUTransactions.TransactionType != @PayoffTransactionType		
		AND CPUAssets.IsActive = 1

  
	--CPUAsset Info  
	SELECT 
		DISTINCT  
			CPUAssets.Id,  
			CPUAssets.AssetId,  
			CPUAssets.BillToId,      
			CPUAssets.RemitToId,    
			Contracts.SequenceNumber AS LeaseSequenceNumber,    
			CAI.CPUScheduleId,  
			CPUAssetMeterReadingHeaders.Id AS CPUAssetMeterReadingHeaderId,  
			CPUAssets.MaximumReading,  
			CPUAssets.BeginDate,  
			CPUAssets.IsServiceOnly,  
			CASE   
				WHEN LeaseFinances.Id IS NOT NULL   
				THEN   
					LeaseFinances.LegalEntityId   
				ELSE   
					CAST(0 AS BIGINT)   
				END AS LegalEntityId,  
			CASE   
				WHEN LeaseFinances.Id IS NOT NULL   
				THEN   
					LeaseFinances.Id   
				ELSE   
					NULL   
				END AS LeaseFinanceId,  
			CASE   
				WHEN Contracts.Id IS NOT NULL   
				THEN   
					Contracts.Id   
				ELSE   
					NULL   
				END  AS ContractId,  
			CASE   
				WHEN ContractACHAssignments.Id IS NOT NULL   
				THEN   
					CAST(1 AS BIT)   
				ELSE   
					CAST(0 AS BIT)   
				END AS CanCreateACHSchedule,  
			CASE   
				WHEN AssetMeters.Id IS NOT NULL   
				THEN   
					CAST(AssetMeters.BeginReading AS BIGINT)   
				ELSE   
					CAST(0 AS BIGINT)   
			END AS FirstBeginReading,
			CAI.PayoffDate
  
			FROM   
			#CPUAssetInfo CAI  
			JOIN CPUAssets						ON  CAI.CPUAssetId = CPUAssets.Id AND IsActive = 1  
			JOIN CPUAssetMeterReadingHeaders	ON  CPUAssets.Id = CPUAssetMeterReadingHeaders.CPUAssetId  
			JOIN CPUSchedules					ON  CPUSchedules.Id = CAI.CPUScheduleId  
			LEFT JOIN AssetMeters				ON  AssetMeters.AssetId = CPUAssets.AssetId   
													AND CPUSchedules.MeterTypeId = AssetMeters.AssetMeterTypeId AND AssetMeters.IsActive = 1  
			LEFT JOIN Contracts					ON  CPUAssets.ContractId = Contracts.Id  
			LEFT JOIN LeaseFinances				ON  Contracts.Id = LeaseFinances.ContractId AND LeaseFinances.IsCurrent = 1  
			LEFT JOIN ContractACHAssignments	ON  Contracts.Id = ContractACHAssignments.ContractBillingId   
													AND ContractACHAssignments.IsActive = 1   
													AND ContractACHAssignments.ReceivableTypeId IN (SELECT Id FROM ReceivableTypes WHERE NAME = @CPIOverageReceivableType)  
  
  
	--CPU Asset Meter Reading Info  
	SELECT   
		CPUAssetMeterReadings.Id,  
		CPUAssetMeterReadings.BeginPeriodDate,  
		CPUAssetMeterReadings.EndPeriodDate,  
		CPUAssetMeterReadings.EndReading,  
		CPUAssetMeterReadings.Reading,  
		CPUAssetMeterReadings.ServiceCredits,  
		CPUAssetMeterReadings.CPUAssetId,  
		CPUAssetMeterReadings.CPUOverageAssessmentId,  
		#CPUAssetInfo.CPUScheduleId,  
		CPUAssetMeterReadings.AssessmentEffectiveDate,  
		CPUAssetMeterReadings.IsEstimated,  
		CPUAssetMeterReadings.[Source]
	FROM   
		CPUAssetMeterReadings   
		JOIN #CPUAssetInfo	ON CPUAssetMeterReadings.Id = #CPUAssetInfo.MeterReadingId  
	WHERE   
		CPUAssetMeterReadings.IsActive = 1  
  
  
    
	--CPU Overage Assessment Detail Info  
	SELECT   
		DISTINCT
			CPUOverageAssessmentDetails.ReceivableId,  
			#CPUAssetInfo.MeterReadingId,  
			CPUOverageAssessmentDetails.CPUOverageAssessmentId,
			#CPUAssetInfo.CPUScheduleId,
			Receivables.EntityType AS ReceivableEntityType
	INTO 
		#CPUAssessmentDetailInfo  
	FROM   
		CPUOverageAssessmentDetails  
		JOIN CPUOverageAssessments	ON CPUOverageAssessmentDetails.CPUOverageAssessmentId = CPUOverageAssessments.Id  
		JOIN Receivables			ON CPUOverageAssessmentDetails.ReceivableId = Receivables.Id
		JOIN #CPUAssetInfo			ON CPUOverageAssessments.Id = #CPUAssetInfo.CPUOverageAssessmentId  
	WHERE   
		CPUOverageAssessments.IsAdjustmentPending = 1  
		AND Receivables.DueDate <= #CPUAssetInfo.ComputedProcessThroughDate
  
	--CPU Overage Assessment Info  
	SELECT   
		CPUOverageAssessments.Id,  
		CPUOverageAssessments.IsAdjustmentPending,
		#CPUAssessmentDetailInfo.CPUScheduleId
	FROM   
		CPUOverageAssessments   
		JOIN #CPUAssessmentDetailInfo ON CPUOverageAssessments.Id = #CPUAssessmentDetailInfo.CPUOverageAssessmentId
  

	SELECT ReceivableId, MeterReadingId, CPUOverageAssessmentId, ReceivableEntityType FROM #CPUAssessmentDetailInfo  
     
	--CPU Base Payment Schedule Information
	SELECT   
		CPUPaymentSchedules.Id,  
		CPUPaymentSchedules.StartDate ,  
		CPUPaymentSchedules.EndDate,  
		CPUPaymentSchedules.Units,  
		CI.CPUScheduleId  
	FROM   
		#CPUContractInfo CI  
		JOIN CPUBaseStructures		ON CI.CPUScheduleId = CPUBaseStructures.Id  
		JOIN CPUPaymentSchedules	ON CPUBaseStructures.Id = CPUPaymentSchedules.CPUBaseStructureId  
	WHERE   
		CPUPaymentSchedules.IsActive = 1 AND 
		CPUPaymentSchedules.StartDate <= CI.ComputedProcessThroughDate AND 
		CPUBaseStructures.IsAggregate = 1  
  
  
  
	--CPU Asset Base Payment Sch Info  
	SELECT   
		CPUAssetPaymentSchedules.AssetId,  
		CPUPaymentSchedules.StartDate,  
		CPUPaymentSchedules.EndDate,  
		CPUAssetPaymentSchedules.Units,  
		CI.CPUScheduleId  
	FROM   
		#CPUContractInfo CI  
		JOIN CPUBaseStructures			ON CI.CPUScheduleId = CPUBaseStructures.Id  
		JOIN CPUPaymentSchedules		ON CPUBaseStructures.Id = CPUPaymentSchedules.CPUBaseStructureId  
		JOIN CPUAssetPaymentSchedules	ON CPUPaymentSchedules.Id = CPUAssetPaymentSchedules.CPUPaymentScheduleId  
	WHERE   
		CPUPaymentSchedules.IsActive = 1   
		AND CPUAssetPaymentSchedules.IsActive = 1   
		AND CPUPaymentSchedules.StartDate <= CI.ComputedProcessThroughDate   
		AND CPUBaseStructures.IsAggregate = 0  
  
  

	--CPU Payable Info    
	SELECT     
		DISTINCT
			CAI.CPUScheduleId AS CPUScheduleId,    
			Payables.Id AS PayableId,    
			CAI.ReceivableId AS ReceivableId,
			ISNULL(PaymentVouchers.VoucherNumber, '') AS PaymentVoucherNumber,
			ISNULL(DisbursementRequests.Id, '') AS DisbursementRequestId,
			ISNULL(DisbursementRequests.[Status], '') AS DisbursementRequestStatus
	FROM     
		#CPUAssessmentDetailInfo CAI 
		JOIN Payables ON  Payables.SourceId = CAI.ReceivableId     
		LEFT JOIN Payables AdjPayables  ON Payables.Id = AdjPayables.AdjustmentBasisPayableId  
		LEFT JOIN DisbursementRequestPayables ON DisbursementRequestPayables.PayableId = Payables.Id AND DisbursementRequestPayables.IsActive = 1
		LEFT JOIN DisbursementRequests ON DisbursementRequests.Id = DisbursementRequestPayables.DisbursementRequestId AND DisbursementRequests.Status != 'Inactive' 
		LEFT JOIN TreasuryPayableDetails ON TreasuryPayableDetails.PayableId = Payables.Id AND TreasuryPayableDetails.IsActive = 1
		LEFT JOIN TreasuryPayables ON TreasuryPayables.Id = TreasuryPayableDetails.TreasuryPayableId
		LEFT JOIN PaymentVoucherDetails ON PaymentVoucherDetails.TreasuryPayableId = TreasuryPayables.Id
		LEFT JOIN PaymentVouchers ON PaymentVoucherDetails.PaymentVoucherId = PaymentVouchers.Id AND PaymentVouchers.Status != 'Inactive' AND PaymentVouchers.Status != 'Reversed'
	WHERE   
		Payables.SourceTable = 'Receivable'    
		AND Payables.Status != 'Inactive' 
		AND AdjPayables.Id IS NULL 



	--CPU Parameters across multiple finance objects  
	SELECT   
		CPUTransactions.CPUFinanceId,   
		CPUTransactions.CPUContractId,   
		CPUSchedules.Id AS ScheduleId,      
		CPUContracts.SequenceNumber AS CPUContractSequenceNumber,   
		CPUSchedules.ScheduleNumber AS CPUScheduleNumber,     
		CPUOverageStructures.PaymentFrequency AS PaymentFrequency,  
		CPUScheduleBillings.InvoiceComment,  
		CPUScheduleBillings.PassThroughRemitToId, 
		CPUScheduleBillings.VendorId AS PassThroughVendorId, 
		CPUScheduleBillings.OveragePassThroughPercent AS CPUOveragePassThroughPercent,  
		CPUFinances.ReadDay,  
		CASE   
			WHEN ([CPUSchedules].[CommencementDate] >= [CPUTransactions].[Date])
			THEN   
				CPUSchedules.[CommencementDate]   
			ELSE
				DATEADD(Day,1,CPUTransactions.Date) 
		END AS EffectiveFrom,  
		CASE   
			WHEN ([CPUSchedules].[CommencementDate] >= [CPUTransactions].[Date])
			THEN   
				CPUSchedules.[CommencementDate]   
			ELSE
				DATEADD(Day,1,CPUTransactions.Date) 
		END AS ScheduleEffectiveDate,   
		CASE   
			WHEN ([CPUSchedules].[CommencementDate] >= [CPUTransactions].[Date])
			THEN   
				CPUOverageStructures.FrequencyStartDate 
			ELSE
				NULL
		END AS FrequencyStartDate,
		CPUSchedules.EstimationMethod,
		CPUOverageStructures.NoOfPeriodsToAverage
	FROM       
		CPUTransactions       
		JOIN CPUContracts			ON CPUContracts.Id = CPUTransactions.CPUContractId      
		JOIN CPUFinances			ON CPUTransactions.CPUFinanceId = CPUFinances.Id      
		JOIN CPUSchedules			ON CPUFinances.Id = CPUSchedules.CPUFinanceId       
		JOIN CPUOverageStructures	ON CPUSchedules.Id = CPUOverageStructures.Id   
		JOIN CPUScheduleBillings	ON CPUSchedules.Id = CPUScheduleBillings.Id  
		JOIN #CPUContractInfo CI	ON CI.[CPUContractId] = CPUContracts.Id AND CPUSchedules.ScheduleNumber = CI.CPUScheduleNumber  
	WHERE   
		CPUContracts.[Status] IN (@CommencedStatus, @PaidOffStatus)
		AND CPUSchedules.IsActive = 1    
		AND CPUTransactions.Date <= CI.ComputedProcessThroughDate  
		AND CPUTransactions.IsActive = 1  
		AND CPUTransactions.TransactionType != @PayoffTransactionType		
	ORDER BY   
		CPUScheduleNumber, EffectiveFrom    
   


   --CPU Leased Asset 'StopInvoicingFutureRentals' related Information
	SELECT 
		CPUAssets.AssetId, 
		LeaseFinances.ContractId as LeaseContractId, 
		Min(Payoffs.PayoffEffectiveDate) as PayoffEffectiveDate
	FROM
		#CPUAssetInfo CAI
		JOIN CPUAssets		ON  CAI.CPUAssetId = CPUAssets.Id AND CPUAssets.IsActive = 1 AND CPUAssets.ContractId IS NOT NULL		
		JOIN LeaseAssets	ON  CPUAssets.AssetId = LeaseAssets.AssetId AND LeaseAssets.IsActive = 1
		JOIN LeaseFinances  ON  LeaseFinances.Id = LeaseAssets.LeaseFinanceId AND LeaseFinances.IsCurrent = 1
		JOIN Payoffs		ON  LeaseFinances.Id = Payoffs.LeaseFinanceId and Payoffs.[Status] IN ( @InvoiceGenerationPayoffStatus , @SubmittedForFinalApprovalPayoffStatus ) 
								AND Payoffs.StopInvoicingFutureRentals = 1
		JOIN PayoffAssets	ON	Payoffs.Id = PayoffAssets.PayoffId AND LeaseAssets.Id = PayoffAssets.LeaseAssetId AND PayoffAssets.IsActive = 1
								
	GROUP BY
		CPUAssets.AssetID, 
		LeaseFinances.ContractId	

	--Lease Contract Info
	SELECT 
		DISTINCT ContractId AS Id 
	INTO 
		#LeaseContractInfos 
	FROM 
		#CPUAssetInfo WHERE ContractId iS NOT NULL


	--Lease Contract ACH Assignment related Information
	SELECT 
		ContractACHAssignments.Id ContractACHAssignmentId,
		ContractACHAssignments.ContractBillingId ContractId,
		PaymentType, 
		RecurringPaymentMethod,
		DayoftheMonth,
		BankAccountId,
		BeginDate,
		EndDate,
		ReceivableTypeId 
	FROM 
		ContractACHAssignments	
		JOIN #LeaseContractInfos		ON ContractACHAssignments.ContractBillingId = #LeaseContractInfos.Id 
		JOIN ReceivableTypes	ON ContractACHAssignments.ReceivableTypeId = ReceivableTypes.Id
	WHERE 
		ReceivableTypes.IsActive = 1 AND 
		ReceivableTypes.Name = @CPIOverageReceivableType 
		AND ContractACHAssignments.IsActive = 1


	--Lease Contract Bank Account payment threshold related Information
	SELECT 
		ContractBankAccountPaymentThresholds.Id PaymentThresholdId,
		ContractBankAccountPaymentThresholds.ContractId,
		ContractBankAccountPaymentThresholds.BankAccountId 
	FROM 
		ContractBankAccountPaymentThresholds 
		JOIN #LeaseContractInfos ON ContractBankAccountPaymentThresholds.ContractId = #LeaseContractInfos.Id 
	WHERE 
		ContractBankAccountPaymentThresholds.IsActive = 1
	
	
	SELECT 
		LeaseFinances.ContractId,
		CASE 
			WHEN (ContractBillings.ReceiptLegalEntityId IS NOT NULL) 
			THEN ContractBillings.ReceiptLegalEntityId 
		ELSE 
			LeaseFinances.LegalEntityId 
		END AS LegalEntityId 
	INTO 
		#LeaseContractLegalEntityInfo 
	FROM 
		LeaseFinances 
		JOIN ContractBillings	ON LeaseFinances.ContractId = ContractBillings.Id
		JOIN #LeaseContractInfos		ON ContractBillings.Id = #LeaseContractInfos.Id 
	WHERE 
		ContractBillings.IsActive = 1 AND 
		LeaseFinances.IsCurrent = 1
	
  
	SELECT 
			* 
	INTO 
		#LeaseContractLegalEntityBranchInfo 
	FROM 
		(
			SELECT 
				#LeaseContractLegalEntityInfo.ContractId,
				BankAccounts.BankBranchId,
				ROW_NUMBER() 
					OVER
					(
						PARTITION BY #LeaseContractLegalEntityInfo.ContractId ORDER BY BankAccounts.IsPrimaryACH DESC, BankAccounts.Id
					) AS GroupRowNumber
			FROM 
				#LeaseContractLegalEntityInfo 
				JOIN LegalEntityBankAccounts	ON #LeaseContractLegalEntityInfo.LegalEntityId = LegalEntityBankAccounts.LegalEntityId 
				JOIN BankAccounts				ON LegalEntityBankAccounts.BankAccountId = BankAccounts.Id 
			WHERE 
				BankAccounts.IsActive = 1
		) 
		AS groupedBankBranch
	WHERE groupedBankBranch.GroupRowNumber = 1

	
	--Lease Contract Business Calendar related information
	SELECT 
		#LeaseContractLegalEntityBranchInfo.ContractId,
		CASE 
			WHEN 
				(BankBranches.BusinessCalendarId IS NOT NULL) 
			THEN BankBranches.BusinessCalendarId 
		ELSE 
			0 
		END AS BusinessCalendarId
	FROM 
		#LeaseContractLegalEntityBranchInfo 
		JOIN BankBranches ON #LeaseContractLegalEntityBranchInfo.BankBranchId = BankBranches.Id


	
	--CPI Overage ReceivableType Id
	DECLARE @OverageReceivableTypeId BIGINT = (SELECT Id FROM ReceivableTypes WHERE Name = @CPIOverageReceivableType AND IsActive = 1)
	SELECT @OverageReceivableTypeId AS CPUOverageReceivableTypeId;


	--Unique Identifier for CPI Receivable Adjustments - Sales Tax Reversal
	SELECT NEXT VALUE FOR SalesTaxJobStepInstanceIdentifier AS CPUUniqueIdentifierValue;


	IF OBJECT_ID('tempdb..#CPUContractInfo') IS NOT NULL DROP TABLE #CPUContractInfo 
	IF OBJECT_ID('tempdb..#CPUOverageTierSchedulesInfo') IS NOT NULL DROP TABLE #CPUOverageTierSchedulesInfo 
	IF OBJECT_ID('tempdb..#CPUAssetInfo') IS NOT NULL DROP TABLE #CPUAssetInfo 
	IF OBJECT_ID('tempdb..#CPUAssessmentDetailInfo') IS NOT NULL DROP TABLE #CPUAssessmentDetailInfo 
	IF OBJECT_ID('tempdb..#LeaseContractInfos') IS NOT NULL DROP TABLE #LeaseContractInfos 
	IF OBJECT_ID('tempdb..#LeaseContractLegalEntityInfo') IS NOT NULL DROP TABLE #LeaseContractLegalEntityInfo 
	IF OBJECT_ID('tempdb..#LeaseContractLegalEntityBranchInfo') IS NOT NULL DROP TABLE #LeaseContractLegalEntityBranchInfo 
	
	SET NOCOUNT OFF;  
  
END

GO

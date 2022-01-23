SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[GetCPUContractDataCacheForBaseChargeGenerationAssessment]
(
	@InputParam CPUContractDataCacheInputForBaseChargeGenerationAssessment READONLY,
	@CPIBaseReceivableType NVARCHAR(21),
	@InvoiceGenerationPayoffStatus NVARCHAR(25),
	@SubmittedForFinalApprovalPayoffStatus NVARCHAR(25),
	@PayoffTransactionType NVARCHAR(6)
)
AS
BEGIN
	
	SET NOCOUNT ON;
	
	DECLARE @BaseReceivableTypeId BIGINT = (SELECT Id FROM ReceivableTypes WHERE Name = @CPIBaseReceivableType AND IsActive = 1)
	
	
	-- CPI Base ReceivableType Id
	SELECT @BaseReceivableTypeId AS ReceivableTypeId;
	
	
	--Preparing input Params
	SELECT
		CPUContracts.Id AS CPUContractId,
		CPUContracts.SequenceNumber AS CPUContractSequenceNumber,
		CPUSchedules.Id AS CPUScheduleId,
		CPUSchedules.ScheduleNumber AS CPUScheduleNumber,
		CI.ComputedProcessThroughDate,
		CAST
		(
			(
				CASE
					WHEN CPUSchedules.PayoffDate IS NOT NULL
						THEN 1
					ELSE 0
				END
			)
			AS BIT
		) IsScheduleFullyPaidOff
	INTO
		#CPUContractInfo
	FROM
		@InputParam CI
		JOIN CPUContracts	ON	CI.CPUContractId =  CPUContracts.Id
		JOIN CPUSchedules	ON	CPUContracts.CPUFinanceId = CPUSchedules.CPUFinanceId 
								AND CPUSchedules.Id = CI.CPUScheduleId


	--CPU Finance Info
	SELECT Distinct
		CPUContracts.Id AS Id,
		CPUContracts.SequenceNumber AS CPUContractSequenceNumber,
		CPUFinances.CustomerId,
		CPUFinances.CurrencyId,
		CPUFinances.LegalEntityId,
		CPUFinances.DueDay,
		CPUFinances.IsAdvanceBilling,
		CurrencyCodes.ISO AS CurrencyCode,
		CPUBillings.IsPerfectPay
	FROM
		#CPUContractInfo ContractInfo
		JOIN CPUContracts	ON ContractInfo.CPUContractId = CPUContracts.Id
		JOIN CPUFinances	ON CPUContracts.CPUFinanceId = CPUFinances.Id
		JOIN CPUBillings	ON CPUFinances.Id = CPUBillings.Id
		JOIN Currencies		ON CPUFinances.CurrencyId = Currencies.Id
		JOIN CurrencyCodes	ON Currencies.CurrencyCodeId = CurrencyCodes.Id


	--CPU Schedule Info
	SELECT
		ContractInfo.CPUScheduleId AS Id,
		ContractInfo.CPUScheduleNumber AS ScheduleNumber,
		CPUSchedules.CommencementDate AS CommencementDate,
		CPUBaseStructures.FrequencyStartDate AS BaseFrequencyStartDate,
		CPUScheduleAccountings.BaseFeeReceivableCodeId,
		CPUScheduleAccountings.BaseFeePayableCodeId,
		ReceivableCodes.DefaultInvoiceReceivableGroupingOption,
		ContractInfo.ComputedProcessThroughDate As ComputedProcessThroughDate,
		CPUBaseStructures.DistributionBasis AS BaseAmountDistributionBasis,
		CPUBaseStructures.IsAggregate,
		ContractInfo.CPUContractId,
		ContractInfo.IsScheduleFullyPaidOff
	FROM
		#CPUContractInfo ContractInfo
		JOIN CPUSchedules			ON ContractInfo.CPUScheduleId = CPUSchedules.Id
		JOIN CPUBaseStructures		ON CPUSchedules.Id = CPUBaseStructures.Id
		JOIN CPUScheduleAccountings ON ContractInfo.CPUScheduleId = CPUScheduleAccountings.Id
		JOIN ReceivableCodes		ON CPUScheduleAccountings.BaseFeeReceivableCodeId = ReceivableCodes.Id


	--CPU Schedule Info for multiple transaction
	SELECT
		ContractInfo.CPUScheduleId AS CPUScheduleId,
		CPUScheduleBillings.InvoiceComment,
		CPUScheduleBillings.BasePassThroughPercent,
		CPUScheduleBillings.VendorId AS PassThroughVendorId,
		CPUScheduleBillings.PassThroughRemitToId,
		CPUFinances.BasePaymentFrequency,
		ContractInfo.CPUContractId,
		ContractInfo.CPUScheduleNumber,
		CASE
			WHEN ([CPUSchedules].[CommencementDate] >= [CPUTransactions].[Date])
				THEN CPUSchedules.[CommencementDate]
			ELSE DATEADD(Day,1,CPUTransactions.Date)
		END AS EffectiveFrom
	FROM 
		#CPUContractInfo ContractInfo
		JOIN CPUTransactions		ON	ContractInfo.CPUContractId = CPUTransactions.CPUContractId
		JOIN CPUFinances			ON	CPUTransactions.CPUFinanceId = CPUFinances.Id
		JOIN CPUSchedules			ON	CPUFinances.Id = CPUSchedules.CPUFinanceId 
										AND ContractInfo.CPUScheduleNumber = CPUSchedules.ScheduleNumber
		JOIN CPUScheduleBillings	ON	CPUSchedules.Id = CPUScheduleBillings.Id
	WHERE
		CPUTransactions.IsActive = 1 
		AND CPUTransactions.TransactionType != @PayoffTransactionType
		AND CPUTransactions.Date <= ContractInfo.ComputedProcessThroughDate
	ORDER BY
		ScheduleNumber, EffectiveFrom
	
	
	--CPU Assets
	SELECT
		CPUAssets.Id AS CPUAssetId,
		CPUAssets.AssetId,
		CPUAssets.BillToId,
		CPUAssets.RemitToId,
		Contracts.SequenceNumber AS LeaseSequenceNumber,
		CPUAssets.IsServiceOnly,
		CPUAssets.BaseAmount_Amount AS BaseAmount,
		CPUAssets.BaseUnits AS BaseUnit,
		CPUAssets.BaseDistributionBasisAmount_Amount AS BaseDistributionBasisAmount,
		CPUAssets.BeginDate,
		CPUAssets.PayoffDate,
		CPUAssets.BaseReceivablesGeneratedTillDate ,
		ContractInfo.CPUScheduleId AS CPUScheduleId,
		CASE
			WHEN LeaseFinances.Id IS NOT NULL
				THEN LeaseFinances.LegalEntityId
			ELSE 
				NULL
		END AS LegalEntityId,
		CASE
			WHEN Contracts.Id IS NOT NULL
				THEN Contracts.Id
			ELSE 
				NULL
		END  AS ContractId,
		CASE
			WHEN LeaseFinances.Id IS NOT NULL
				THEN LeaseFinances.Id
			ELSE 
				NULL
		END  AS LeaseFinanceId,
		CASE
			WHEN ContractACHAssignments.Id IS NOT NULL
				THEN CAST(1 AS BIT)
			ELSE 
				CAST(0 AS BIT)
		END AS CanCreateACHSchedule
	INTO
		#CPUAssetInfos
	FROM
		#CPUContractInfo ContractInfo
		JOIN CPUAssets						ON	ContractInfo.CPUScheduleId = CPUAssets.CPUScheduleId
		LEFT JOIN Contracts					ON	CPUAssets.ContractId = Contracts.Id
		LEFT JOIN LeaseFinances				ON	Contracts.Id = LeaseFinances.ContractId
												AND LeaseFinances.IsCurrent = 1
		LEFT JOIN ContractACHAssignments	ON	Contracts.Id = ContractACHAssignments.ContractBillingId
												AND ContractACHAssignments.IsActive = 1
												AND ContractACHAssignments.ReceivableTypeId = @BaseReceivableTypeId
	WHERE
		CPUAssets.IsActive = 1 
		AND
		(
			CPUAssets.BaseReceivablesGeneratedTillDate IS NULL 
			OR CPUAssets.BaseReceivablesGeneratedTillDate < ContractInfo.ComputedProcessThroughDate
		)


	SELECT
		*
	FROM
		#CPUAssetInfos
	
	
	SELECT
		CPUPaymentSchedules.CPUBaseStructureId,
		MAX(CPUPaymentSchedules.EndDate) LastPaymentDate
	INTO
		#LastPayments
	FROM
		CPUPaymentSchedules
	WHERE
		CPUPaymentSchedules.CPUBaseStructureId IN (Select CPUScheduleId from #CPUContractInfo) 
		AND CPUPaymentSchedules.IsActive = 1
	GROUP BY
		CPUPaymentSchedules.CPUBaseStructureId


	--CPU Asset Payment Schedules
	SELECT
	CPUAssetPaymentSchedules.Units AS Unit,
	CPUAssetPaymentSchedules.AssetId ,
	CPUAssetPaymentSchedules.Amount_Amount AS Amount,
	ContractInfo.CPUScheduleId AS CPUScheduleId,
	CPUPaymentSchedules.Id AS PaymentScheduleId,
	CPUPaymentSchedules.PaymentNumber,
	CPUPaymentSchedules.StartDate,
	CPUPaymentSchedules.EndDate,
	CPUPaymentSchedules.DueDate,
	CPUPaymentSchedules.Units AS HeaderPaymentUnit,
	CASE
		WHEN	
			CPUPaymentSchedules.EndDate = #LastPayments.LastPaymentDate
		THEN
			CAST(1 AS BIT)
		ELSE
			CAST(0 AS BIT)
	END AS IsLastPayment,
	CASE
		WHEN 
			#CPUAssetInfos.BaseReceivablesGeneratedTillDate IS NULL
		THEN
			CAST(0 AS BIT)
		WHEN 
			CPUPaymentSchedules.DueDate <= #CPUAssetInfos.BaseReceivablesGeneratedTillDate
		THEN
			CAST(1 AS BIT)
		ELSE
			CAST(0 AS BIT)
	END AS 'IsProcessed'
	FROM
		#CPUAssetInfos
		JOIN #CPUContractInfo ContractInfo	ON	ContractInfo.CPUScheduleId = #CPUAssetInfos.CPUScheduleId
		JOIN #LastPayments					ON	ContractInfo.CPUScheduleId = #LastPayments.CPUBaseStructureId
		JOIN CPUAssetPaymentSchedules		ON	#CPUAssetInfos.AssetId =  CPUAssetPaymentSchedules.AssetId 
												AND ContractInfo.CPUScheduleId = CPUAssetPaymentSchedules.CPUBaseStructureId
		JOIN CPUPaymentSchedules			ON	CPUPaymentSchedules.Id = CPUAssetPaymentSchedules.CPUPaymentScheduleId 
												AND CPUPaymentSchedules.CPUBaseStructureId = ContractInfo.CPUScheduleId
	WHERE
		CPUPaymentSchedules.IsActive = 1 
		AND CPUAssetPaymentSchedules.IsActive = 1 
		AND CPUPaymentSchedules.DueDate <= ContractInfo.ComputedProcessThroughDate 
		AND
		(
			#LastPayments.LastPaymentDate = CPUPaymentSchedules.EndDate 
			OR #CPUAssetInfos.BaseReceivablesGeneratedTillDate IS NULL 
			OR #CPUAssetInfos.BaseReceivablesGeneratedTillDate < CPUPaymentSchedules.DueDate
		)


	--CPU Base Payment Escalation Information
	SELECT
		EffectiveDate,
		StepPeriod,
		EscalationMethod,
		[Percentage],
		Amount_Amount AS Amount,
		CPUBaseStructureId AS CPUScheduleId
	FROM 
		#CPUContractInfo ContractInfo
		JOIN CPUBasePaymentEscalations	ON ContractInfo.CPUScheduleId = CPUBasePaymentEscalations.CPUBaseStructureId
	WHERE
		CPUBasePaymentEscalations.IsActive = 1
		AND CPUBasePaymentEscalations.EffectiveDate <= ContractInfo.ComputedProcessThroughDate



	SELECT
		DISTINCT ContractId AS Id
	INTO
		#ContractInfos
	FROM
		#CPUAssetInfos
	WHERE
		ContractId iS NOT NULL


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
		JOIN #ContractInfos		ON ContractACHAssignments.ContractBillingId = #ContractInfos.Id
		JOIN ReceivableTypes	ON ContractACHAssignments.ReceivableTypeId = ReceivableTypes.Id
	WHERE
		ReceivableTypes.IsActive = 1 
		AND ReceivableTypes.Name = @CPIBaseReceivableType
		AND ContractACHAssignments.IsActive = 1


	SELECT
		ContractBankAccountPaymentThresholds.Id PaymentThresholdId,
		ContractBankAccountPaymentThresholds.ContractId,
		ContractBankAccountPaymentThresholds.BankAccountId
	FROM
		ContractBankAccountPaymentThresholds
		JOIN #ContractInfos ON ContractBankAccountPaymentThresholds.ContractId = #ContractInfos.Id
	WHERE
		ContractBankAccountPaymentThresholds.IsActive = 1
	
	
	SELECT
		LeaseFinances.ContractId,
		CASE
			WHEN 
				(ContractBillings.ReceiptLegalEntityId IS NOT NULL)
			THEN 
				ContractBillings.ReceiptLegalEntityId
			ELSE
				LeaseFinances.LegalEntityId
		END AS LegalEntityId
	INTO 
		#ContractLegalEntityInfo
	FROM 
		LeaseFinances
		JOIN ContractBillings	ON LeaseFinances.ContractId = ContractBillings.Id
		JOIN #ContractInfos		ON ContractBillings.Id = #ContractInfos.Id
	WHERE
		ContractBillings.IsActive = 1 
		AND LeaseFinances.IsCurrent = 1
	
	
	SELECT
		*
	INTO
		#LegalEntityBrachInfo
	FROM
	(
		SELECT
			#ContractLegalEntityInfo.ContractId,
			BankAccounts.BankBranchId,
			ROW_NUMBER() OVER
			(
				PARTITION BY 
					#ContractLegalEntityInfo.ContractId 
				ORDER BY 
					BankAccounts.IsPrimaryACH DESC, BankAccounts.Id
			) AS GroupRowNumber
		FROM
			#ContractLegalEntityInfo
			JOIN LegalEntityBankAccounts	ON #ContractLegalEntityInfo.LegalEntityId = LegalEntityBankAccounts.LegalEntityId
			JOIN BankAccounts				ON LegalEntityBankAccounts.BankAccountId = BankAccounts.Id
		WHERE 
			BankAccounts.IsActive = 1
	)
	AS groupedBankBranch
	WHERE 
		groupedBankBranch.GroupRowNumber = 1


	SELECT
		#LegalEntityBrachInfo.ContractId,
		CASE
			WHEN
				(BankBranches.BusinessCalendarId IS NOT NULL)
			THEN 
				BankBranches.BusinessCalendarId
			ELSE
				0
		END AS BusinessCalendarId
	FROM
		#LegalEntityBrachInfo
		JOIN BankBranches ON #LegalEntityBrachInfo.BankBranchId = BankBranches.Id
	
	
	--CPU Leased Asset 'StopInvoicingFutureRentals' related Information
	SELECT
		CPUAssets.AssetId,
		LeaseFinances.ContractId AS LeaseContractId,
		Min(Payoffs.PayoffEffectiveDate) AS PayoffEffectiveDate,
		CPUAssets.CPUScheduleId AS CPUScheduleId
	FROM
		#CPUAssetInfos CAI
		JOIN CPUAssets		ON  CAI.CPUAssetId = CPUAssets.Id 
								AND CPUAssets.IsActive = 1 
								AND CPUAssets.ContractId IS NOT NULL
		JOIN LeaseAssets	ON  CPUAssets.AssetId = LeaseAssets.AssetId 
								AND LeaseAssets.IsActive = 1
		JOIN LeaseFinances  ON  LeaseFinances.Id = LeaseAssets.LeaseFinanceId 
								AND LeaseFinances.IsCurrent = 1
		JOIN Payoffs		ON  LeaseFinances.Id = Payoffs.LeaseFinanceId 
								AND Payoffs.[Status] IN ( @InvoiceGenerationPayoffStatus, @SubmittedForFinalApprovalPayoffStatus )
								AND Payoffs.StopInvoicingFutureRentals = 1
		JOIN PayoffAssets	ON	Payoffs.Id = PayoffAssets.PayoffId 
								AND LeaseAssets.Id = PayoffAssets.LeaseAssetId 
								AND PayoffAssets.IsActive = 1
	GROUP BY
		CPUAssets.AssetID,
		LeaseFinances.ContractId,
		CPUAssets.CPUScheduleId


	SET NOCOUNT OFF;
END

GO

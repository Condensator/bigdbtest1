SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetNonAccrualDetailsForIncomeReclass]
(
	@ReclassInput NonAccrualIncomeReclassInput READONLY,
	@SyndicationApprovalStatus NVARCHAR(25) NULL,
	@NonAccrualApprovalStatus NVARCHAR(18) NULL,
	@ChargeOffUnknownStatus NVARCHAR(10) NULL
)
AS
BEGIN
	CREATE TABLE #BasicContractInfo
	(
		Id BIGINT,
		NonAccrualDate DATE,
		DatePriorToNonAccrualDate DATE,
		SyndicationDate DATE,
		MoreThanOneNonAccrual BIT,
		PayoffDate DATE NULL,	
		ContractType NVARCHAR(16),
		MaturityDate DATE,
		FixedTermAccountingTreatment NVARCHAR(12),
		OTPAccountingTreatment NVARCHAR(12),
		SupplementalAccountingTreatment NVARCHAR(12),
		IsFloatRateLease BIT,
		PayoffLeaseFinanceId BIGINT,
		DoubtfulCollectability BIT,
		Currency NVARCHAR(12)
	)
	INSERT INTO #BasicContractInfo
	(
		Id,
		NonAccrualDate,
		DatePriorToNonAccrualDate,
		SyndicationDate,
		MoreThanOneNonAccrual,
		PayoffDate,
		ContractType,
		MaturityDate,
		FixedTermAccountingTreatment,
		OTPAccountingTreatment,
		SupplementalAccountingTreatment,
		IsFloatRateLease,
		PayoffLeaseFinanceId,
		Currency
	)
	SELECT 
		Contracts.Id,
		Contracts.NonAccrualDate,
		DATEADD(DAY,-1,Contracts.NonAccrualDate),
		LeasePaymentSchedules.StartDate,
		0,
		ReclassInput.PayoffEffectiveDate,
		LeaseFinanceDetails.LeaseContractType,
		LeaseFinanceDetails.MaturityDate,
		ISNULL(ReceivableCodes.AccountingTreatment,'_') FixedTermAccountingTreatment,
		ISNULL(OTPCode.AccountingTreatment,'_') OTPAccountingTreatment,
		ISNULL(SupplementalCode.AccountingTreatment,'_') SupplementalAccountingTreatment,
		LeaseFinanceDetails.IsFloatRateLease,
		ReclassInput.PayoffLeaseFinanceId,
		LegalEntities.CurrencyCode Currency
	FROM 
		Contracts 
	INNER JOIN @ReclassInput ReclassInput
		ON Contracts.Id = ReclassInput.ContractId
	INNER JOIN LeaseFinances
		ON Contracts.Id = LeaseFinances.ContractId AND 
		   LeaseFinances.IsCurrent = 1
	INNER JOIN LeaseFinanceDetails
		ON LeaseFinances.Id = LeaseFinanceDetails.Id
    INNER JOIN LegalEntities 
		ON LegalEntities.Id = LeaseFinances.LegalEntityId
	LEFT JOIN ReceivableCodes
		ON LeaseFinanceDetails.FixedTermReceivableCodeId = ReceivableCodes.Id
	LEFT JOIN ReceivableCodes OTPCode
		ON LeaseFinanceDetails.OTPReceivableCodeId = OTPCode.Id
	LEFT JOIN ReceivableCodes SupplementalCode
		ON LeaseFinanceDetails.SupplementalReceivableCodeId = SupplementalCode.Id
	LEFT JOIN ReceivableForTransfers
		ON Contracts.Id = ReceivableForTransfers.ContractId AND
		   ReceivableForTransfers.ApprovalStatus = @SyndicationApprovalStatus
	LEFT JOIN LeasePaymentSchedules
		ON ReceivableForTransfers.LeasePaymentId = LeasePaymentSchedules.Id
	WHERE
		Contracts.ChargeOffStatus = @ChargeOffUnknownStatus AND
		Contracts.IsNonAccrual = 1 AND
		(Contracts.NonAccrualDate <> LeaseFinanceDetails.CommencementDate OR
		ReclassInput.PayoffEffectiveDate <> LeaseFinanceDetails.CommencementDate)

	SELECT
		LeaseAssets.AssetId,
		LeaseAssets.IsLeaseAsset INTO #LeaseAssetInfo
	FROM
		#BasicContractInfo
	INNER JOIN LeaseAssets
		ON #BasicContractInfo.PayoffLeaseFinanceId = LeaseAssets.LeaseFinanceId AND
		   LeaseAssets.IsActive = 1


	SELECT 
		NonAccrualContracts.ContractId INTO #ContractsWithNonAccrualsOnSameday
	FROM
		NonAccrualContracts
	INNER JOIN #BasicContractInfo
		ON NonAccrualContracts.ContractId = #BasicContractInfo.Id AND
		   NonAccrualContracts.IsActive = 1 AND
		   NonAccrualContracts.NonAccrualDate = #BasicContractInfo.NonAccrualDate AND NonAccrualContracts.IsNonAccrualApproved = 1
	GROUP BY
		NonAccrualContracts.ContractId
	HAVING COUNT(*) > 1

	UPDATE #BasicContractInfo SET MoreThanOneNonAccrual = 1
		WHERE Id IN (SELECT ContractId FROM #ContractsWithNonAccrualsOnSameday)

	SELECT 
		Id ContractId,
		NonAccrualDate,
		SyndicationDate,
		MoreThanOneNonAccrual HasBeenOnNonAccrual,
		ContractType,	
		Currency
	FROM
		#BasicContractInfo

	SELECT 
		#BasicContractInfo.Id ContractId,
		AssetIncomeSchedules.AssetId,
		AssetIncomeSchedules.LeaseDeferredRentalIncome_Amount AS LeaseDeferredRentalIncome,
		AssetIncomeSchedules.FinanceDeferredRentalIncome_Amount AS FinanceDeferredRentalIncome,
		#LeaseAssetInfo.IsLeaseAsset
	FROM 
		#BasicContractInfo
	INNER JOIN LeaseFinances
		ON #BasicContractInfo.Id = LeaseFinances.ContractId
	INNER JOIN LeaseIncomeSchedules
		ON LeaseFinances.Id = LeaseIncomeSchedules.LeaseFinanceId AND
		    LeaseIncomeSchedules.IsSchedule = 1 AND
			LeaseIncomeSchedules.IncomeDate = #BasicContractInfo.DatePriorToNonAccrualDate AND
			LeaseIncomeSchedules.IsLessorOwned = 1 AND
			LeaseIncomeSchedules.AdjustmentEntry <> 1
	INNER JOIN AssetIncomeSchedules
		ON LeaseIncomeSchedules.Id = AssetIncomeSchedules.LeaseIncomeScheduleId AND
		   AssetIncomeSchedules.IsActive = 1 
		   AND AssetIncomeSchedules.DeferredRentalIncome_Amount <> 0.0
	INNER JOIN #LeaseAssetInfo
		ON AssetIncomeSchedules.AssetId = #LeaseAssetInfo.AssetId 
	
	SELECT 
		#BasicContractInfo.Id ContractId,
		#LeaseAssetInfo.AssetId,
		#LeaseAssetInfo.IsLeaseAsset,
		LeaseIncomeSchedules.IncomeType,
		--Lease Component
		SUM(AssetIncomeSchedules.LeaseIncome_Amount) LeaseIncome,
		SUM(AssetIncomeSchedules.LeaseRentalIncome_Amount) LeaseRentalIncome,
		SUM(AssetIncomeSchedules.LeasePayment_Amount) LeasePayment,
		SUM(AssetIncomeSchedules.LeaseResidualIncome_Amount) LeaseResidualIncome,
		--Finance Component
		SUM(AssetIncomeSchedules.FinanceIncome_Amount) FinanceIncome,
		SUM(AssetIncomeSchedules.FinanceRentalIncome_Amount) FinanceRentalIncome,
		SUM(AssetIncomeSchedules.FinancePayment_Amount) FinancePayment,
		SUM(AssetIncomeSchedules.FinanceResidualIncome_Amount) FinanceResidualIncome 
	FROM 
		#BasicContractInfo
	INNER JOIN LeaseFinances
		ON #BasicContractInfo.Id = LeaseFinances.ContractId
	INNER JOIN LeaseIncomeSchedules
		ON LeaseFinances.Id = LeaseIncomeSchedules.LeaseFinanceId
	INNER JOIN AssetIncomeSchedules
		ON LeaseIncomeSchedules.Id = AssetIncomeSchedules.LeaseIncomeScheduleId AND
		   AssetIncomeSchedules.IsActive = 1 		
	INNER JOIN #LeaseAssetInfo
		ON AssetIncomeSchedules.AssetId = #LeaseAssetInfo.AssetId 
	WHERE
		LeaseIncomeSchedules.IsSchedule = 1 AND
		LeaseIncomeSchedules.IsLessorOwned = 1 AND
		LeaseIncomeSchedules.IsNonAccrual = 1 AND
		LeaseIncomeSchedules.IncomeDate >= #BasicContractInfo.NonAccrualDate AND
		LeaseIncomeSchedules.IncomeDate <= #BasicContractInfo.PayoffDate AND
		LeaseIncomeSchedules.AdjustmentEntry <> 1
	GROUP BY 
		#LeaseAssetInfo.AssetId,
		#LeaseAssetInfo.IsLeaseAsset,
		#BasicContractInfo.Id,
		LeaseIncomeSchedules.IncomeType,
		#LeaseAssetInfo.IsLeaseAsset
		

	SELECT
		#BasicContractInfo.Id ContractId,
		AssetFloatRateIncomes.AssetId,
		SUM(AssetFloatRateIncomes.CustomerIncomeAmount_Amount) CustomerIncome,
		#LeaseAssetInfo.IsLeaseAsset
	FROM
		#BasicContractInfo
	INNER JOIN LeaseFinances
		ON #BasicContractInfo.Id = LeaseFinances.ContractId
	INNER JOIN LeaseFloatRateIncomes
		ON LeaseFinances.Id = LeaseFloatRateIncomes.LeaseFinanceId
	INNER JOIN AssetFloatRateIncomes
		ON LeaseFloatRateIncomes.Id = AssetFloatRateIncomes.LeaseFloatRateIncomeId
	INNER JOIN #LeaseAssetInfo
		ON AssetFloatRateIncomes.AssetId = #LeaseAssetInfo.AssetId 
	WHERE
		LeaseFloatRateIncomes.IncomeDate >= #BasicContractInfo.NonAccrualDate AND
		LeaseFloatRateIncomes.IncomeDate <= #BasicContractInfo.PayoffDate AND
		LeaseFloatRateIncomes.IsScheduled = 1 AND
		LeaseFloatRateIncomes.IsLessorOwned = 1 AND
		LeaseFloatRateIncomes.AdjustmentEntry <> 1 AND
		LeaseFloatRateIncomes.IsNonAccrual = 1
	GROUP BY
		AssetFloatRateIncomes.AssetId,
		#BasicContractInfo.Id,
		#LeaseAssetInfo.IsLeaseAsset

	SELECT
		#BasicContractInfo.Id ContractId,
		LeaseBlendedItems.BlendedItemId,
		SUM(BlendedIncomeSchedules.Income_Amount) Income
	FROM
		#BasicContractInfo
	INNER JOIN LeaseFinances
		ON LeaseFinances.ContractId = #BasicContractInfo.Id
	INNER JOIN LeaseBlendedItems
		ON LeaseFinances.Id = LeaseBlendedItems.LeaseFinanceId
	INNER JOIN BlendedItems
		ON LeaseBlendedItems.BlendedItemId = BlendedItems.Id
	INNER JOIN BlendedIncomeSchedules
		ON BlendedItems.Id = BlendedIncomeSchedules.BlendedItemId
	WHERE
		 BlendedIncomeSchedules.IncomeDate >= #BasicContractInfo.NonAccrualDate
         AND BlendedIncomeSchedules.IncomeDate <= #BasicContractInfo.PayoffDate
         AND BlendedIncomeSchedules.AdjustmentEntry <> 1
         AND BlendedIncomeSchedules.IsNonAccrual = 1 
         AND BlendedIncomeSchedules.IsSchedule = 1 
         AND BlendedItems.IsFAS91 = 1 
		 AND BlendedItems.IsActive = 1
		 AND LeaseFinances.IsCurrent = 1
	GROUP BY 
		#BasicContractInfo.Id,
		LeaseBlendedItems.BlendedItemId

END

GO

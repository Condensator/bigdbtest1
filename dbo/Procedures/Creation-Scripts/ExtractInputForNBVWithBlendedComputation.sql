SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ExtractInputForNBVWithBlendedComputation]
(
	@ContractInputs NetInvestmentWithBlended_ContractInput READONLY,
	@LeaseContractOperatingType NVARCHAR(50),
	@BlendedItemIncomeType NVARCHAR(50),
	@ReceivableEntityCTType NVARCHAR(50),
	@ReceiptStatusReversedValue NVARCHAR(50),
	@ReceiptStatusInactiveValue NVARCHAR(50),
	@ReceiptClassificationNonCashValue NVARCHAR(50),
	@ReceiptClassificationNonAccrualNonDSLNonCashValue NVARCHAR(50),
	@ReceivableTypeCapitalLeaseRentalValue NVARCHAR(50),
    @ReceivableTypeLeaseFloatRateAdjValue NVARCHAR(50),
	@LeasePaymentTypeFixedTermValue NVARCHAR(50),
    @LeasePaymentTypeDownPaymentValue NVARCHAR(50),
    @LeasePaymentTypeCustomerGuaranteedResidualValue NVARCHAR(50),
    @LeasePaymentTypeThirdPartyGuaranteedResidualValue NVARCHAR(50),
	@SyndicationIsFullSaleType NVARCHAR(50),
	@WriteDownApprovedStatus NVARCHAR(50),
	@BlendedItemBookRecognitionModeCapitalizeValue NVARCHAR(50)
)
AS
BEGIN
SET NOCOUNT ON;

	SELECT 
		ContractId = Header.ContractId,
		LeaseIncomeScheduleId = LIS.Id,
		AsOfDate = Header.AsOfDate,
		Row_Num = ROW_NUMBER() OVER (PARTITION BY Header.ContractId ORDER BY LIS.IncomeDate ASC)
	INTO #FirstIncomePostNonAccrual_Unfiltered 
	FROM @ContractInputs Header
	JOIN LeaseFinances LF ON Header.ContractId = LF.ContractId
	JOIN LeaseIncomeSchedules LIS ON LF.Id = LIS.LeaseFinanceId
	WHERE LIS.IsSchedule = 1
	AND LIS.IsLessorOwned = 1
	AND LIS.IncomeDate >= Header.AsOfDate;

	SELECT
		ContractId, 
		LeaseIncomeScheduleId,
		AsOfDate
	INTO #FirstIncomePostNonAccrual
	FROM #FirstIncomePostNonAccrual_Unfiltered 
	WHERE Row_Num = 1;

	SELECT 
		ContractId = FIA.ContractId,
		NBV = SUM(AIS.BeginNetBookValue_Amount)
	INTO #NBVInfo
	FROM #FirstIncomePostNonAccrual FIA 
	JOIN LeaseFinances LF ON FIA.ContractId = LF.ContractId AND LF.IsCurrent = 1
	JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
	JOIN LeaseAssets LA ON LF.Id = LA.LeaseFinanceId 
	JOIN AssetIncomeSchedules AIS ON LA.AssetId = AIS.AssetId AND FIA.LeaseIncomeScheduleId = AIS.LeaseIncomeScheduleId
	WHERE (LA.IsActive = 1 OR LA.TerminationDate >= FIA.AsOfDate)
	AND AIS.IsActive = 1
	AND (LFD.LeaseContractType <> @LeaseContractOperatingType 
	OR LA.IsLeaseAsset = 0)
	GROUP BY FIA.ContractId;

	SELECT 
		ContractId = Header.ContractId,
		BlendedItemId = BIS.BlendedItemId,
		IncomeBalance = BIS.IncomeBalance_Amount,
		Row_Num = ROW_NUMBER() OVER (PARTITION BY Header.ContractId, BIS.BlendedItemId ORDER BY BIS.Id DESC)
	INTO #BlendedIncomeSchedules_Unfiltered
	FROM @ContractInputs Header
	JOIN LeaseFinances LF ON Header.ContractId = LF.ContractId 
	JOIN BlendedIncomeSchedules BIS ON LF.Id = BIS.LeaseFinanceId
	WHERE BIS.IsSchedule = 1
	AND BIS.IncomeDate = DATEADD(DAY, -1, Header.AsOfDate);

	SELECT
		ContractId, 
		BlendedItemId,
		IncomeBalance
	INTO #BlendedIncomeSchedules
	FROM #BlendedIncomeSchedules_Unfiltered 
	WHERE Row_Num = 1;

	SELECT 
		ContractId = Header.ContractId,
		BlendedItemId = BI.Id,
		[Type] = BI.[Type],
		BookRecognitionMode = BI.BookRecognitionMode,
		BlendedItemAmount = BI.Amount_Amount
	INTO #BlendedItemInfo
	FROM @ContractInputs Header
	JOIN LeaseFinances LF ON Header.ContractId = LF.ContractId AND LF.IsCurrent = 1
	JOIN LeaseBlendedItems LBI ON LF.Id = LBI.LeaseFinanceId 
	JOIN BlendedItems BI ON  LBI.BlendedItemId = BI.Id
	WHERE BI.IsActive = 1
	AND BI.IsFAS91 = 1
	AND BI.BookRecognitionMode <> @BlendedItemBookRecognitionModeCapitalizeValue;

	SELECT 
		ContractId = Header.ContractId, 
		ReceivableDate = LPS.StartDate,
		CashPostedReceivable = CASE WHEN (RecApplicationsRD.Id IS NULL) THEN 0.0 ELSE					RecApplicationsRD.AmountApplied_Amount END,
		Balance = RecDetails.EffectiveBalance_Amount
	INTO #ReceivableInfo
	FROM @ContractInputs Header
	JOIN Contracts CON ON Header.ContractId = CON.Id
	JOIN LeaseFinances LF ON Header.ContractId = LF.ContractId AND LF.IsCurrent = 1
	JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
	JOIN LeaseAssets LA ON LFD.Id = LA.LeaseFinanceId
	JOIN Receivables Rec ON Rec.EntityId = CON.Id
	JOIN ReceivableCodes RC ON Rec.ReceivableCodeId = RC.Id
	JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id 
	AND (RT.[Name] IN (@ReceivableTypeCapitalLeaseRentalValue ,@ReceivableTypeLeaseFloatRateAdjValue))
	JOIN LeasePaymentSchedules LPS ON Rec.PaymentScheduleId = LPS.Id
	AND (LPS.PaymentType IN ( @LeasePaymentTypeCustomerGuaranteedResidualValue , 
							  @LeasePaymentTypeDownPaymentValue,
							  @LeasePaymentTypeFixedTermValue,
							  @LeasePaymentTypeThirdPartyGuaranteedResidualValue))
	JOIN ReceivableDetails RecDetails ON REC.Id = RecDetails.ReceivableId AND RecDetails.AssetId = LA.AssetId
	LEFT JOIN ReceiptApplicationReceivableDetails RecApplicationsRD ON RecDetails.Id =  RecApplicationsRD.ReceivableDetailId
	LEFT JOIN ReceiptApplications RecApplications ON RecApplicationsRD.ReceiptApplicationId = RecApplications.Id
	LEFT JOIN Receipts Receipt ON RecApplications.ReceiptId = Receipt.Id
	WHERE LPS.IsActive = 1
	AND Rec.EntityType = @ReceivableEntityCTType
	AND Rec.IsActive = 1
	AND Rec.FunderId IS NULL
	AND Rec.IsDummy = 0
	AND RecDetails.IsActive = 1
	AND (RecApplicationsRD.Id IS NULL OR RecApplicationsRD.IsActive = 1)
	AND (Receipt.Id IS NULL OR 
		(Receipt.[Status] NOT IN (@ReceiptStatusReversedValue , @ReceiptStatusInactiveValue)
		 AND Receipt.ReceiptClassification NOT IN (@ReceiptClassificationNonCashValue ,       @ReceiptClassificationNonAccrualNonDSLNonCashValue))
		)
	AND (LFD.LeaseContractType <> @LeaseContractOperatingType OR LA.IsLeaseAsset = 0);

	SELECT * FROM #NBVInfo

	SELECT * FROM #BlendedItemInfo

	SELECT * FROM #BlendedIncomeSchedules

	SELECT * FROM #ReceivableInfo

	DROP TABLE                                 
	#NBVInfo,
	#FirstIncomePostNonAccrual,
	#FirstIncomePostNonAccrual_Unfiltered,
	#BlendedIncomeSchedules_Unfiltered,
	#BlendedItemInfo,
	#BlendedIncomeSchedules,
	#ReceivableInfo

END

GO

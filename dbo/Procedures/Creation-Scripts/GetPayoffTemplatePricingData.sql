SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[GetPayoffTemplatePricingData]
(
@Payoffs PayoffInput_PayoffTemplateExtract READONLY,
@AssetTypes AssetTypeInput_PayoffTemplateExtract READONLY,
@SundryApprovedStatus NVARCHAR(16),
@SundryPayableType NVARCHAR(28),
@TradeUpFeeCalculateType NVARCHAR(20),
@ReceivableSource_SundryRecurring NVARCHAR(20),
@ReceivableEntityType_CT NVARCHAR(5),
@ReceivableType_CapitalLeaseRental NVARCHAR(25),
@ReceivableType_OperatingLeaseRental NVARCHAR(25),
@ReceivableType_LeaseFloatRateAdj NVARCHAR(25),
@ContractOptionTerms_FMV NVARCHAR(25),
@ContractOptionTerms_FMVCap NVARCHAR(25),
@ContractOptionTerms_FMVFloor NVARCHAR(25),
@ReceivableIncomeType_OTP NVARCHAR(25),
@ReceivableIncomeType_Supplemental NVARCHAR(25)
)
AS
BEGIN
SET NOCOUNT ON;
SELECT
Input.LeaseFinanceId,
Input.PayoffTemplateId,
TerminationParameterId = Parameter.Id,
Parameter.DiscountRate,
Parameter.Factor,
Parameter.NumberofTerms,
Parameter.SundryType,
Parameter.PayableCodeId,
Parameter.ReceivableCodeId,
Parameter.IsExcludeFeeApplicable,
Parameter.FeeExclusionExpression,
ParamConfig.Property,
ParamConfig.Parameter,
IsDiscountRateApplicable = ParamConfig.DiscountRateApplicable,
IsFactorApplicable = ParamConfig.FactorApplicable,
IsNumberofTermsApplicable = ParamConfig.NumberofTermsApplicable,
ParamConfig.OperatorSign,
ParamConfig.IsApplicableForFeeParameter,
PaymentNumber_BOPNoOfTermsParam = (Input.LeaseNumberOfPayments - Parameter.NumberofTerms) + 1
INTO #PayoffTemplateParameters
FROM @Payoffs Input
JOIN PayOffTemplateTerminationTypeParameters Parameter ON Input.TerminationTypeId = Parameter.PayOffTemplateTerminationTypeId
JOIN TerminationTypeParameterConfigs ParamConfig ON Parameter.TerminationTypeParameterConfigId = ParamConfig.Id
WHERE (ParamConfig.IsApplicableForPayoffAtMaturity = 1 OR ParamConfig.ApplicableForOTP = 1)
AND ((PayoffAtOTP = 0 AND (Parameter.ApplicableForFixedTerm = 1 OR ParamConfig.IsApplicableForFeeParameter = 1)) 
	OR (PayoffAtOTP = 1 AND (Parameter.ApplicableForFixedTerm = 0 OR ParamConfig.IsApplicableForFeeParameter = 1)))
AND ParamConfig.IsLease = 1
AND Parameter.IsActive = 1
AND ParamConfig.IsActive = 1;
SELECT DISTINCT(AssetType.AssetTypeId)
INTO #DistinctAssetTypeIds
FROM  @AssetTypes AssetType
JOIN #PayoffTemplateParameters Parameter ON AssetType.LeaseFinanceId = Parameter.LeaseFinanceId
WHERE Parameter.Property = 'e.FMVAsOfEffectiveDate';
SELECT
AssetType.AssetTypeId,
MatrixDetail.FromMonth,
MatrixDetail.ToMonth,
MatrixDetail.FMVFactor
INTO #AssetTypeFMVMetrices
FROM #DistinctAssetTypeIds Header
JOIN AssetTypeForFMVs AssetType ON Header.AssetTypeId = AssetType.AssetTypeId
JOIN AssetFMVMatrices Matrix ON AssetType.AssetFMVMatrixId = Matrix.Id
JOIN AssetFMVMatrixDetails MatrixDetail ON Matrix.Id = MatrixDetail.AssetFMVMatrixId
WHERE AssetType.IsActive = 1
AND Matrix.IsActive = 1;
SELECT DISTINCT Input.LeaseFinanceId, Input.PaymentScheduleNumber
INTO #DistinctLeaseInput_StipLossParam
FROM @Payoffs Input
JOIN #PayoffTemplateParameters Parameter ON Input.LeaseFinanceId = Parameter.LeaseFinanceId AND Input.PayoffTemplateId = Parameter.PayoffTemplateId
WHERE Parameter.Property = 'e.GetStipLoss';
SELECT LeaseFinanceId = Header.LeaseFinanceId,
StipLossFactor = StipLoss.Factor
INTO #StipLossDetails
FROM #DistinctLeaseInput_StipLossParam Header
JOIN LeaseStipLossDetails StipLoss ON Header.LeaseFinanceId = StipLoss.LeaseFinanceId
WHERE StipLoss.[Month] = Header.PaymentScheduleNumber
AND StipLoss.IsActive = 1;
SELECT DISTINCT Input.LeaseFinanceId,
Input.PayoffTemplateId,
Input.ContractId,
Input.IsAdvanceLease,
Input.PayoffEffectiveDate,
Parameter.TerminationParameterId
INTO #DistinctLeaseInput_RecurringSundryParam
FROM @Payoffs Input
JOIN #PayoffTemplateParameters Parameter ON Input.LeaseFinanceId = Parameter.LeaseFinanceId AND Input.PayoffTemplateId = Parameter.PayoffTemplateId
WHERE Parameter.Property IN ('e.GetRecurringSundriesBOP', 'e.GetPVofRecurringSundries_DiscountRate');
SELECT
Header.LeaseFinanceId,
Header.PayoffTemplateId,
SundryRecurringId = Sundry.Id,
PaymentSchedule.DueDate,
Amount = ISNULL(SUM(Receivables.TotalEffectiveBalance_Amount), PaymentSchedule.Amount_Amount)
INTO #RecurringSundries
FROM #DistinctLeaseInput_RecurringSundryParam Header
JOIN PayOffTemplateSundryCodes SundryCode ON Header.TerminationParameterId = SundryCode.PayOffTemplateTerminationTypeParameterId
JOIN SundryRecurrings Sundry ON SundryCode.SundryCodeId = Sundry.ReceivableCodeId AND Header.ContractId = Sundry.ContractId
JOIN SundryRecurringPaymentSchedules PaymentSchedule ON Sundry.Id = PaymentSchedule.SundryRecurringId
LEFT JOIN Receivables ON PaymentSchedule.Id = Receivables.SourceId AND Receivables.SourceTable = @ReceivableSource_SundryRecurring AND Receivables.IsActive = 1
WHERE
(
(Header.IsAdvanceLease = 1 AND PaymentSchedule.DueDate >= DATEADD(D, 1, Header.PayoffEffectiveDate))
OR
(Header.IsAdvanceLease = 0 AND PaymentSchedule.DueDate > DATEADD(D, 1, Header.PayoffEffectiveDate))
)
AND Sundry.IsActive = 1
AND Sundry.IsCollected = 1
AND Sundry.[Status] = @SundryApprovedStatus
AND Sundry.SundryType <> @SundryPayableType
AND SundryCode.IsActive = 1
AND PaymentSchedule.IsActive = 1
GROUP BY Header.LeaseFinanceId, Header.PayoffTemplateId, Sundry.Id, PaymentSchedule.DueDate, PaymentSchedule.Amount_Amount;
SELECT DISTINCT Input.LeaseFinanceId,
Input.TradeUpFeeId,
Input.TradeupFeeCalculationMethod
INTO #DistinctLeaseInput_TradeUpFee
FROM @Payoffs Input;
SELECT
Header.LeaseFinanceId,
TradeUpFeeDetail.RemainingNumberofMonths,
TradeUpFeeDetail.IsHeaderRecord,
TradeUpFeeDetail.Field1,
TradeUpFeeDetail.Field2,
TradeUpFeeDetail.Field3,
TradeUpFeeDetail.Field4,
TradeUpFeeDetail.Field5,
TradeUpFeeDetail.Field6,
TradeUpFeeDetail.Field7,
TradeUpFeeDetail.Field8,
TradeUpFeeDetail.Field9,
TradeUpFeeDetail.Field10
INTO #TradeUpFeeDetails
FROM #DistinctLeaseInput_TradeUpFee Header
JOIN PayoffTradeUpFees TradeUpFee ON Header.TradeUpFeeId = TradeUpFee.Id
JOIN PayoffTradeUpFeeDetails TradeUpFeeDetail ON Header.TradeUpFeeId = TradeUpFeeDetail.PayoffTradeUpFeeId
WHERE Header.TradeupFeeCalculationMethod = @TradeUpFeeCalculateType
AND TradeUpFee.IsActive = 1
AND TradeUpFeeDetail.IsActive = 1
AND (TradeUpFeeDetail.IsHeaderRecord = 1 OR TradeUpFeeDetail.RemainingNumberofMonths = 0);
SELECT DISTINCT Input.LeaseFinanceId,
Input.PayoffTemplateId,
Input.ContractId
INTO #DistinctLeaseInput_BOPNoOfTerms
FROM @Payoffs Input;
SELECT
LeaseFinanceId = Header.LeaseFinanceId,
PayoffTemplateId = Header.PayoffTemplateId,
ReceivableDetailAmount = SUM(ReceivableDetails.Amount_Amount)
INTO #BOPNoOfTermDetails
FROM #DistinctLeaseInput_BOPNoOfTerms Header
JOIN #PayoffTemplateParameters Parameter ON Header.LeaseFinanceId = Parameter.LeaseFinanceId AND Header.PayoffTemplateId = Parameter.PayoffTemplateId
JOIN Receivables ON Receivables.EntityId = Header.ContractId AND Receivables.IsActive = 1
JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
JOIN ReceivableDetails ON Receivables.Id = ReceivableDetails.ReceivableId AND ReceivableDetails.IsActive = 1
JOIN LeasePaymentSchedules ON Receivables.PaymentScheduleId = LeasePaymentSchedules.Id AND LeasePaymentSchedules.IsActive = 1
WHERE
Parameter.Property = 'e.GetBOP_NoOfTerms'
AND LeasePaymentSchedules.LeaseFinanceDetailId = Header.LeaseFinanceId
AND LeasePaymentSchedules.PaymentNumber >= Parameter.PaymentNumber_BOPNoOfTermsParam
AND Receivables.EntityType = @ReceivableEntityType_CT
AND Receivables.SourceTable = '_'
AND ReceivableTypes.Name IN (@ReceivableType_CapitalLeaseRental,
@ReceivableType_OperatingLeaseRental,
@ReceivableType_LeaseFloatRateAdj)
GROUP BY Header.LeaseFinanceId, Header.PayoffTemplateId;
SELECT DISTINCT Input.LeaseFinanceId,
Input.ContractId
INTO #DistinctLeaseInput_BuyoutAmountAtMaturity
FROM @Payoffs Input
JOIN LeaseContractOptions LCO ON Input.LeaseFinanceId = LCO.LeaseFinanceId AND LCO.IsActive = 1
JOIN #PayoffTemplateParameters Parameter ON Input.LeaseFinanceId = Parameter.LeaseFinanceId
WHERE (ContractOptionTerms = @ContractOptionTerms_FMV
OR ContractOptionTerms = @ContractOptionTerms_FMVCap
OR ContractOptionTerms = @ContractOptionTerms_FMVFloor)
AND LCO.IsEarly = 0
AND Parameter.Property = 'e.GetBuyoutAmountAtMaturity';
SELECT
Header.LeaseFinanceId,
LeaseAssetId = Asset.Id,
AssetFMVAtMaturity = MMAD.FMVMaturity_Amount
INTO #BuyoutAtMaturityDetails
FROM #DistinctLeaseInput_BuyoutAmountAtMaturity Header
JOIN LeaseAssets Asset ON Header.LeaseFinanceId = Asset.LeaseFinanceId 
JOIN MaturityMonitors MM ON MM.ContractId = Header.ContractId
JOIN MaturityMonitorFMVAssetDetails MMAD ON MM.Id = MMAD.MaturityMonitorId AND Asset.AssetId = MMAD.AssetId
WHERE Asset.IsActive = 1 AND MMAD.IsActive = 1;

SELECT DISTINCT Input.LeaseFinanceId,
Input.ContractId,
Input.PayoffEffectiveDate
INTO #DistinctLeaseInput_OverTermRent
FROM @Payoffs Input
JOIN #PayoffTemplateParameters Parameter ON Input.LeaseFinanceId = Parameter.LeaseFinanceId
WHERE Parameter.Property = 'e.GetOverTermRent';
SELECT Header.LeaseFinanceId,
LeaseAssetId = LA.Id,
ReceivableAmount = (RD.LeaseComponentAmount_Amount + RD.NonLeaseComponentAmount_Amount)
INTO #OverTermRent
FROM #DistinctLeaseInput_OverTermRent header
JOIN LeaseAssets LA ON header.LeaseFinanceId = LA.LeaseFinanceId 
JOIN ReceivableDetails RD ON LA.AssetId = RD.AssetId
JOIN Receivables R ON RD.ReceivableId = R.Id
JOIN LeasePaymentSchedules LPS ON R.PaymentScheduleId = LPS.Id
WHERE R.EntityType = @ReceivableEntityType_CT
AND R.SourceTable = '_'
AND R.EntityId = header.ContractId
AND R.IsActive = 1
AND RD.IsActive = 1
AND LPS.IsActive = 1
AND LA.IsActive = 1
AND LPS.LeaseFinanceDetailId = header.LeaseFinanceId
AND (R.IncomeType = @ReceivableIncomeType_OTP OR R.IncomeType = @ReceivableIncomeType_Supplemental)
AND LPS.StartDate <= header.PayoffEffectiveDate

SELECT * FROM #PayoffTemplateParameters;
SELECT * FROM #StipLossDetails;
SELECT * FROM #AssetTypeFMVMetrices;
SELECT * FROM #RecurringSundries;
SELECT * FROM #TradeUpFeeDetails;
SELECT * FROM #BOPNoOfTermDetails;
SELECT * FROM #BuyoutAtMaturityDetails;
SELECT * FROM #OverTermRent;
END

GO

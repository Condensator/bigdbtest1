SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[LeaseIncomeScheduleDataReport]
(
@SequenceNumber NVARCHAR(40),
@IsAccounting BIT
)
AS
BEGIN
SET NOCOUNT ON
-- Temporary Variables
DECLARE @LeaseFinanceId BIGINT
DECLARE @BookingStatus NVARCHAR(16)
DECLARE @CommencementDate DATE
DECLARE @MaturityDate DATE
DECLARE @CustomerGuaranteedResidual DECIMAL(16,2)=0.00
DECLARE @PaymentThirdPartyGuaranteedResidual DECIMAL(16,2)=0.00
DECLARE @PaymentCustomerGuaranteedResidual DECIMAL(16,2)=0.00
DECLARE @ThirdPartyGuaranteedResidual DECIMAL(16,2)=0.00
DECLARE @LeaseContractType NVARCHAR(16)
DECLARE @AdvanceOrArrear NVARCHAR(12)
DECLARE @IsNonAccrual BIT
DECLARE @IsRenewal BIT = 0
DECLARE @IsSyndicated BIT=0
DECLARE @DeferInterimRent NVARCHAR(5)
SELECT  @DeferInterimRent = ISNULL(VALUE,'FALSE') FROM GlobalParameters WHERE Name = 'DeferInterimRentIncomeRecognition';
DECLARE @DeferInterimRentForSingleInstallment NVARCHAR(5)
SELECT  @DeferInterimRentForSingleInstallment = ISNULL(VALUE,'FALSE') FROM GlobalParameters WHERE Name = 'DeferInterimRentIncomeRecognitionForSingleInstallment';

--For while loop
DECLARE @CurrentPaymentNumber INT = 0
DECLARE @LastPaymentNumber INT = 0
DECLARE @RowNo INT = 0
DECLARE @Count INT = 0

DECLARE @ContractId BigInt 

SELECT @ContractId = Id, @IsSyndicated = CASE WHEN Contracts.SyndicationType='None' THEN 0 ELSE 1 END FROM Contracts WHERE SequenceNumber = @SequenceNumber

CREATE TABLE #LeaseFloatRateIncomesTemp(
	ContractId BIGINT,
	LeaseIncomeScheduleId BIGINT,
	IsLeaseAsset BIT,
	FloatRateIncome DECIMAL(16,2),
	FloatRatePaymentAdjustment DECIMAL(16,2)
);

CREATE TABLE #LeaseAdjustmentFloatRateIncomesTemp(
	ContractId BIGINT,
	LeaseIncomeScheduleId BIGINT,
	IsLeaseAsset BIT,
	FloatRateIncome DECIMAL(16,2),
	FloatRatePaymentAdjustment DECIMAL(16,2)
);

CREATE TABLE #FinancingDepreciation(
	FinancingDepreciation DECIMAL(16,2),
	FinancingPaymentAmount DECIMAL(16,2),
	FinancingBeginNBV DECIMAL(16,2),
	FinancingEndNBV DECIMAL(16,2),
	FinancingIncome DECIMAL(16,2),
	FinancingIncomeBalance DECIMAL(16,2),
	FinancingOperatingBeginNBV DECIMAL(16,2),
	FinancingOperatingEndNBV DECIMAL(16,2),
	LeaseIncomeScheduleId BIGINT
);

SELECT
@LeaseFinanceId = LeaseFinances.Id,
@BookingStatus = LeaseFinances.BookingStatus,
@CustomerGuaranteedResidual = SUM(LeaseAssets.CustomerGuaranteedResidual_Amount),
@ThirdPartyGuaranteedResidual = SUM(LeaseAssets.ThirdPartyGuaranteedResidual_Amount),
@CommencementDate=LeaseFinanceDetails.CommencementDate,
@MaturityDate=LeaseFinanceDetails.MaturityDate,
@LeaseContractType=LeaseFinanceDetails.LeaseContractType,
@AdvanceOrArrear = CASE WHEN LeaseFinanceDetails.IsAdvance=1 THEN 'Advance' ELSE 'Arrear' END
FROM LeaseFinances 
INNER JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id  AND LeaseFinances.IsCurrent=1
LEFT JOIN LeaseAssets ON LeaseFinances.Id = LeaseAssets.LeaseFinanceId AND LeaseAssets.IsActive = 1
WHERE
LeaseFinances.ContractId = @ContractId
GROUP BY
LeaseFinances.Id,
LeaseFinances.BookingStatus,
LeaseFinanceDetails.CommencementDate,
LeaseFinanceDetails.MaturityDate,
LeaseFinanceDetails.LeaseContractType,
LeaseFinanceDetails.IsAdvance

SELECT
LeaseFinances.Id
,ROW_NUMBER()OVER (ORDER BY LeaseFinances.Id) OrderNumber
,LeaseAmendments.AmendmentType
,0 AS GroupedOrder
INTO #LeaseFinancesTemp
FROM LeaseFinances 
LEFT JOIN LeaseAmendments ON LeaseFinances.Id = LeaseAmendments.CurrentLeaseFinanceId
AND LeaseAmendments.CurrentLeaseFinanceId <> LeaseAmendments.OriginalLeaseFinanceId
AND LeaseAmendments.AmendmentType NOT IN ('NonAccrual','ReAccrual','Syndication','Assumption')
AND LeaseAmendments.LeaseAmendmentStatus = 'Approved'
WHERE LeaseFinances.ContractId = @ContractId
ORDER BY LeaseFinances.Id

SELECT
LeasePaymentSchedules.Amount_Amount AS DownPaymentAmount,
LeaseFinances.Id AS LeaseFinanceId,
LeaseFinanceDetails.CommencementDate
INTO #DownPaymentSummary
FROM
LeaseFinances 
INNER JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
INNER JOIN LeasePaymentSchedules ON LeaseFinanceDetails.Id = LeasePaymentSchedules.LeaseFinanceDetailId
WHERE LeaseFinances.ContractId = @ContractId
AND LeasePaymentSchedules.IsActive=1
AND LeasePaymentSchedules.PaymentType='DownPayment'
AND LeasePaymentSchedules.Amount_Amount <> 0

SELECT DISTINCT BlendedIncomeSchedules.*,BlendedItems.Name AS BlendedItemName, CASE WHEN BlendedItems.BookRecognitionMode = 'Amortize' THEN 1 ELSE 0 END AS IsAmortize,LeaseFinances.ContractId AS ContractId
INTO #BlendedIncomeSchedulesTemp
FROM LeaseFinances
INNER JOIN LeaseBlendedItems ON LeaseFinances.Id = LeaseBlendedItems.LeaseFinanceId
INNER JOIN BlendedItems ON LeaseBlendedItems.BlendedItemId = BlendedItems.Id
INNER JOIN BlendedIncomeSchedules ON BlendedItems.Id = BlendedIncomeSchedules.BlendedItemId and LeaseBlendedItems.LeaseFinanceid = BlendedIncomeSchedules.LeaseFinanceId
WHERE LeaseFinances.ContractId = @ContractId
AND ((@IsAccounting = 1 AND BlendedIncomeSchedules.IsAccounting=@IsAccounting)
OR (@IsAccounting = 0 AND BlendedIncomeSchedules.IsSchedule = 1))

SELECT	ROW_NUMBER() OVER (PARTITION BY LeaseIncomeSchedules.AdjustmentEntry ORDER BY IncomeDate) AS RowNumber
,LeaseIncomeSchedules.*
,LeaseFinances.ContractId
INTO #LeaseIncomeSchedulesTemp
FROM LeaseFinances
INNER JOIN LeaseIncomeSchedules ON LeaseFinances.Id = LeaseIncomeSchedules.LeaseFinanceId
WHERE LeaseFinances.ContractId = @ContractId
AND  ((@IsAccounting = 1 AND LeaseIncomeSchedules.IsAccounting = @IsAccounting)
OR (@IsAccounting = 0 AND @IsSyndicated=0 AND LeaseIncomeSchedules.IsSchedule = 1)
OR (@IsAccounting = 0 AND @IsSyndicated=1 AND LeaseIncomeSchedules.IsSchedule = 1 AND LeaseIncomeSchedules.IsLessorOwned = 0)
)

--Float Rate Incomes Temp
SELECT 
	LA.AssetId AssetId,
	LA.CustomerCost_Amount,
	LA.Id LeaseAssetId
INTO #LeaseAsset
FROM 
LeaseAssets LA
WHERE 
LA.LeaseFinanceId = @LeaseFinanceId
AND LA.IsActive = 1

;WITH CTE_SKURatio
AS
(
SELECT 
	#LeaseAsset.AssetId,
	Case when #LeaseAsset.CustomerCost_Amount=0.00 then 0.00 else LeaseAssetSKUs.CustomerCost_Amount/#LeaseAsset.CustomerCost_Amount end AS SKUFactor,
	LeaseAssetSKUs.IsLeaseComponent
FROM #LeaseAsset
JOIN LeaseAssetSKUs ON #LeaseAsset.LeaseAssetId = LeaseAssetSKUs.LeaseAssetId
)
SELECT AssetId, IsLeaseComponent, SUM(SKUFactor) SKUFactor
INTO #SKURatios
FROM CTE_SKURatio
GROUP BY AssetId, IsLeaseComponent

DROP TABLE #LeaseAsset

SELECT
	LeaseFinances.ContractId,
	LeaseFloatRateIncomes.LeaseFinanceId,
	#LeaseIncomeSchedulesTemp.Id LeaseIncomeScheduleId,
	A.Id AssetId,
	A.IsSKU IsSKU,
	FloatRateIncome = SUM(AFI.CustomerIncomeAmount_Amount),
	FloatRatePaymentAdjustment = SUM(AFI.CustomerReceivableAmount_Amount)
INTO #AssetFloatRates
FROM LeaseFinances 
INNER JOIN #LeaseIncomeSchedulesTemp ON LeaseFinances.ContractId = #LeaseIncomeSchedulesTemp.ContractId 
	AND AdjustmentEntry=0
INNER JOIN LeaseFloatRateIncomes ON LeaseFinances.Id = LeaseFloatRateIncomes.LeaseFinanceId 
	AND #LeaseIncomeSchedulesTemp.IncomeDate >= LeaseFloatRateIncomes.IncomeDate 
	AND LeaseFloatRateIncomes.AdjustmentEntry=0
INNER JOIN AssetFloatRateIncomes AFI ON LeaseFloatRateIncomes.Id = AFI.LeaseFloatRateIncomeId
INNER JOIN Assets A on AFI.AssetId = A.Id 
LEFT JOIN #LeaseIncomeSchedulesTemp AS PreviousLeaseIncomeSchedule ON PreviousLeaseIncomeSchedule.RowNumber = #LeaseIncomeSchedulesTemp.RowNumber - 1 
	AND PreviousLeaseIncomeSchedule.AdjustmentEntry=0
WHERE 
	LeaseFinances.ContractId = @ContractId
	AND (PreviousLeaseIncomeSchedule.IncomeDate = NULL OR PreviousLeaseIncomeSchedule.IncomeDate < LeaseFloatRateIncomes.IncomeDate)
	AND ((@IsAccounting = 1 AND LeaseFloatRateIncomes.IsAccounting = @IsAccounting) OR (@IsAccounting = 0 AND LeaseFloatRateIncomes.IsScheduled = 1))
GROUP BY 
	LeaseFinances.ContractId,
	LeaseFloatRateIncomes.LeaseFinanceId,
	#LeaseIncomeSchedulesTemp.Id, 
	A.Id,
	A.IsSKU

SELECT
#AssetFloatRates.ContractId,
#AssetFloatRates.AssetId,
#AssetFloatRates.IsSKU,
LA.IsLeaseAsset IsLeaseAsset,
#AssetFloatRates.LeaseIncomeScheduleId,
#AssetFloatRates.FloatRateIncome,
#AssetFloatRates.FloatRatePaymentAdjustment
INTO #AssetFloatRateSum
FROM #AssetFloatRates
JOIN LeaseAssets LA ON LA.LeaseFinanceId = #AssetFloatRates.LeaseFinanceId AND #AssetFloatRates.AssetId = LA.AssetId

SELECT * INTO #ComponentFloatRateincome FROM  (
SELECT
#AssetFloatRateSum.ContractId,
#AssetFloatRateSum.LeaseIncomeScheduleId,
#SKURatios.IsLeaseComponent IsLeaseAsset,
#AssetFloatRateSum.FloatRateIncome*#SKURatios.SKUFactor FloatRateIncome,
#AssetFloatRateSum.FloatRatePaymentAdjustment*#SKURatios.SKUFactor FloatRatePaymentAdjustment
FROM #AssetFloatRateSum
JOIN #SKURatios ON #AssetFloatRateSum.AssetId = #SKURatios.AssetId
WHERE #SKURatios.IsLeaseComponent=1 and #AssetFloatRateSum.IsSKU = 1
UNION
SELECT
#AssetFloatRateSum.ContractId,
#AssetFloatRateSum.LeaseIncomeScheduleId,
#SKURatios.IsLeaseComponent IsLeaseAsset,
#AssetFloatRateSum.FloatRateIncome*#SKURatios.SKUFactor FloatRateIncome,
#AssetFloatRateSum.FloatRatePaymentAdjustment*#SKURatios.SKUFactor FloatRatePaymentAdjustment
FROM #AssetFloatRateSum
join #SKURatios ON #AssetFloatRateSum.AssetId = #SKURatios.AssetId
WHERE #SKURatios.IsLeaseComponent=0 and #AssetFloatRateSum.IsSKU = 1
UNION 
SELECT
#AssetFloatRateSum.ContractId,
#AssetFloatRateSum.LeaseIncomeScheduleId,
#AssetFloatRateSum.IsLeaseAsset,
FloatRateIncome = #AssetFloatRateSum.FloatRateIncome,
FloatRatePaymentAdjustment = #AssetFloatRateSum.FloatRatePaymentAdjustment
FROM #AssetFloatRateSum
WHERE IsSKU=0) as ComponentFloatRateincome;

INSERT INTO #LeaseFloatRateIncomesTemp
SELECT componentFloatRateIncome.ContractId,componentFloatRateIncome.LeaseIncomeScheduleId,componentFloatRateIncome.IsLeaseAsset,FloatRateIncome = SUM(componentFloatRateIncome.FloatRateIncome),FloatRatePaymentAdjustment = SUM(componentFloatRateIncome.FloatRatePaymentAdjustment) FROM #ComponentFloatRateincome componentFloatRateIncome
GROUP BY componentFloatRateIncome.ContractId,componentFloatRateIncome.LeaseIncomeScheduleId,componentFloatRateIncome.IsLeaseAsset;

--Adjustment Float Rate Incomes Temp
SELECT
LeaseFinances.ContractId,
A.Id AssetId,
A.IsSKU IsSKU,
LA.IsLeaseAsset IsLeaseAsset,
#LeaseIncomeSchedulesTemp.Id LeaseIncomeScheduleId,
FloatRateIncome = SUM(AFI.CustomerIncomeAmount_Amount),
FloatRatePaymentAdjustment = SUM(AFI.CustomerReceivableAmount_Amount)
into #AssetFloatRateAdjustmentSum
FROM LeaseFinances
INNER JOIN #LeaseIncomeSchedulesTemp ON LeaseFinances.ContractId = #LeaseIncomeSchedulesTemp.ContractId AND AdjustmentEntry=1
LEFT JOIN #LeaseIncomeSchedulesTemp AS PreviousLeaseIncomeSchedule ON PreviousLeaseIncomeSchedule.RowNumber = #LeaseIncomeSchedulesTemp.RowNumber - 1 AND PreviousLeaseIncomeSchedule.AdjustmentEntry=0
INNER JOIN LeaseFloatRateIncomes ON LeaseFinances.Id = LeaseFloatRateIncomes.LeaseFinanceId AND #LeaseIncomeSchedulesTemp.IncomeDate >= LeaseFloatRateIncomes.IncomeDate AND LeaseFloatRateIncomes.AdjustmentEntry=0
AND (PreviousLeaseIncomeSchedule.IncomeDate = NULL OR PreviousLeaseIncomeSchedule.IncomeDate < LeaseFloatRateIncomes.IncomeDate)
AND ((@IsAccounting = 1 AND LeaseFloatRateIncomes.IsAccounting = @IsAccounting) OR (@IsAccounting = 0 AND LeaseFloatRateIncomes.IsScheduled = 1))
JOIN AssetFloatRateIncomes AFI ON LeaseFloatRateIncomes.Id = AFI.LeaseFloatRateIncomeId
JOIN LeaseAssets LA ON AFI.AssetId = LA.AssetId AND LA.LeaseFinanceId = LeaseFloatRateIncomes.LeaseFinanceId
join Assets A on LA.AssetId = A.Id 
WHERE LeaseFinances.ContractId = @ContractId
GROUP BY LeaseFinances.ContractId, #LeaseIncomeSchedulesTemp.Id,A.Id,A.IsSKU,LA.IsLeaseAsset

SELECT * INTO #ComponentAdjustmentFloatRateIncome FROM (
SELECT
#AssetFloatRateAdjustmentSum.ContractId,
#SKURatios.IsLeaseComponent,
#AssetFloatRateAdjustmentSum.LeaseIncomeScheduleId,
#AssetFloatRateAdjustmentSum.FloatRateIncome*#SKURatios.SKUFactor FloatRateIncome,
#AssetFloatRateAdjustmentSum.FloatRatePaymentAdjustment*#SKURatios.SKUFactor FloatRatePaymentAdjustment
FROM #AssetFloatRateAdjustmentSum
JOIN #SKURatios ON #AssetFloatRateAdjustmentSum.AssetId = #SKURatios.AssetId
WHERE #SKURatios.IsLeaseComponent=1 AND #AssetFloatRateAdjustmentSum.IsSKU = 1
UNION
SELECT
#AssetFloatRateAdjustmentSum.ContractId,
#SKURatios.IsLeaseComponent,
#AssetFloatRateAdjustmentSum.LeaseIncomeScheduleId,
#AssetFloatRateAdjustmentSum.FloatRateIncome*#SKURatios.SKUFactor FloatRateIncome,
#AssetFloatRateAdjustmentSum.FloatRatePaymentAdjustment*#SKURatios.SKUFactor FloatRatePaymentAdjustment
FROM #AssetFloatRateAdjustmentSum
JOIN #SKURatios on #AssetFloatRateAdjustmentSum.AssetId = #SKURatios.AssetId
WHERE #SKURatios.IsLeaseComponent=0 AND #AssetFloatRateAdjustmentSum.IsSKU = 1
UNION
SELECT
#AssetFloatRateAdjustmentSum.ContractId,
#AssetFloatRateAdjustmentSum.IsLeaseAsset,
#AssetFloatRateAdjustmentSum.LeaseIncomeScheduleId,
FloatRateIncome = #AssetFloatRateAdjustmentSum.FloatRateIncome,
FloatRatePaymentAdjustment = #AssetFloatRateAdjustmentSum.FloatRatePaymentAdjustment
FROM #AssetFloatRateAdjustmentSum
where IsSKU=0) as componentAdjustmentFloatRateIncome;

INSERT INTO #LeaseAdjustmentFloatRateIncomesTemp
SELECT componentAdjustmentFloatRateIncome.ContractId,componentAdjustmentFloatRateIncome.LeaseIncomeScheduleId,componentAdjustmentFloatRateIncome.IsLeaseComponent,FloatRateIncome = SUM(componentAdjustmentFloatRateIncome.FloatRateIncome),FloatRatePaymentAdjustment = SUM(componentAdjustmentFloatRateIncome.FloatRatePaymentAdjustment) FROM #ComponentAdjustmentFloatRateincome componentAdjustmentFloatRateIncome
GROUP BY componentAdjustmentFloatRateIncome.ContractId,componentAdjustmentFloatRateIncome.LeaseIncomeScheduleId,componentAdjustmentFloatRateIncome.IsLeaseComponent;


SELECT
CASE WHEN PaymentType='_' THEN 'FixedTerm' ELSE PaymentType END AS PaymentType
,LeasePaymentSchedules.Id
,LeasePaymentSchedules.PaymentNumber
,LeasePaymentSchedules.StartDate
,LeasePaymentSchedules.EndDate
,LeasePaymentSchedules.LeaseFinanceDetailId
,LeasePaymentSchedules.IsActive
,LeasePaymentSchedules.Amount_Amount
,LeasePaymentSchedules.Disbursement_Amount
,LeasePaymentSchedules.IsRenewal
,LeaseFinances.ContractId
INTO #LeasePaymentSchedulesTemp
FROM LeaseFinances 
INNER JOIN LeasePaymentSchedules ON LeaseFinances.Id = LeasePaymentSchedules.LeaseFinanceDetailId AND IsActive=1
WHERE LeaseFinances.ContractId = @ContractId

-- To set order for Renewal Begin
SET @Count = (SELECT COUNT(*) FROM #LeaseFinancesTemp)
SET @RowNo = 1
DECLARE @Order INT = 1
WHILE @RowNo <= @Count
BEGIN
IF EXISTS(SELECT * FROM #LeaseFinancesTemp WHERE AmendmentType='Renewal' AND OrderNumber=@RowNo)
BEGIN
	SET @Order = @Order+1
END
UPDATE #LeaseFinancesTemp SET GroupedOrder = @Order WHERE OrderNumber=@RowNo
	SET @RowNo = @RowNo +1
END
-- To set order for Renewal End
CREATE TABLE #LeaseIncomeSchedule
(
LeaseFinanceId BIGINT,
LeaseContractType NVARCHAR(16),
IsRenewal BIT,
PaymentNumber INT,
IsNonAccrual BIT,
IsGLPosted BIT,
PaymentType NVARCHAR(30),
StartDate DATE,
EndDate DATE,
PaymentAmount DECIMAL(16,2),
DisbursementAmount DECIMAL(16,2),
Type NVARCHAR(30),
IncomeDate DATE,
AccountingAmount DECIMAL(16,2),
AdvanceOrArrear NVARCHAR(12),
BeginNBV DECIMAL(16,2),
EndNBV DECIMAL(16,2),
Income DECIMAL(16,2),
IncomeBalance DECIMAL(16,2),
RentalIncome DECIMAL(16,2),
DeferredRentalIncome DECIMAL(16,2),
FinancingDeferredRentalIncome DECIMAL(16,2),
FinancingRentalIncome DECIMAL(16,2),
ResidualIncome DECIMAL(16,2),
ResidualIncomeBalance DECIMAL(16,2),
ActualIncomePeriod INT,
BlendedIncome DECIMAL(16,2),
BlendedIncomeBalance DECIMAL(16,2),
ActualBlendedIncomePeriod INT,
BlendedItemName NVARCHAR(MAX),
IsBlendedIncome INT,
OperatingBeginNBV DECIMAL(16,2),
OperatingEndNBV DECIMAL(16,2),
Depreciation DECIMAL(16,2),
OrderNumber INT,
RowNumber INT,
ModificationType NVARCHAR(25),
LeaseFloatRateIncome DECIMAL(16,2),
FinanceFloatRateIncome DECIMAL(16,2),
LeaseFloatRatePaymentAdjustment DECIMAL(16,2),
FinanceFloatRatePaymentAdjustment DECIMAL(16,2),
IsFloatRateLease BIT,
IsFutureFunding BIT,
PaymentGroupNumber BIGINT,
BlendedItemPaymentGroupNumber BIGINT,
BlendedItemId BIGINT,
IsPaymentEndDate BIT,
IsAmortize BIT,
FinancingPaymentAmount DECIMAL(16,2),
FinancingAccountingAmount DECIMAL(16,2)	,
FinancingBeginNBV DECIMAL(16,2)	,
FinancingIncome	DECIMAL(16,2),
FinancingIncomeBalance DECIMAL(16,2),
FinancingEndNBV DECIMAL(16,2)	,
FinancingResidualIncome	DECIMAL(16,2),
FinancingResidualIncomeBalance DECIMAL(16,2),
DeferredSellingProfitIncome DECIMAL(16,2),
DeferredSellingProfitBalance DECIMAL(16,2),
FinancingDepreciation DECIMAL(16,2),
LeaseIncomeScheduleId BIGINT,
BlendedIncomeScheduleId BIGINT
)
--- To show Income Schedules For Capitalize Interim Period Begin --
INSERT INTO #LeaseIncomeSchedule
(
LeaseFinanceId,
LeaseContractType,
IsRenewal,
ModificationType,
AdvanceOrArrear,
PaymentType,
Type,
IncomeDate,
IsGLPosted,
IsNonAccrual,
BeginNBV,
AccountingAmount,
PaymentAmount,
Income,
IncomeBalance,
EndNBV,
RentalIncome,
DeferredRentalIncome,
FinancingDeferredRentalIncome,
FinancingRentalIncome,
ResidualIncome,
ResidualIncomeBalance,
ActualIncomePeriod,
ActualBlendedIncomePeriod,
IsBlendedIncome,
OperatingBeginNBV,
OperatingEndNBV,
Depreciation,
RowNumber,
IsFutureFunding,
FinancingPaymentAmount,
FinancingAccountingAmount	,
FinancingBeginNBV	,
FinancingIncome,
FinancingIncomeBalance,
FinancingEndNBV,
FinancingResidualIncome,
FinancingResidualIncomeBalance,
DeferredSellingProfitIncome	,
DeferredSellingProfitBalance,
LeaseIncomeScheduleId,
FinancingDepreciation,
BlendedIncomeScheduleId
)
SELECT
LeaseFinances.Id,
LeaseFinanceDetails.LeaseContractType,
0,
LeaseIncomeSchedule.LeaseModificationType,
'Arrear',
LeaseIncomeSchedule.IncomeType,
LeaseIncomeSchedule.IncomeType,
LeaseIncomeSchedule.IncomeDate,
LeaseIncomeSchedule.IsGLPosted,
LeaseIncomeSchedule.IsNonAccrual,
LeaseIncomeSchedule.BeginNetBookValue_Amount,
LeaseIncomeSchedule.Payment_Amount,
LeaseIncomeSchedule.Payment_Amount,
LeaseIncomeSchedule.Income_Amount,
LeaseIncomeSchedule.IncomeBalance_Amount,
LeaseIncomeSchedule.EndNetBookValue_Amount,
LeaseIncomeSchedule.RentalIncome_Amount,
LeaseIncomeSchedule.DeferredRentalIncome_Amount,
LeaseIncomeSchedule.FinanceDeferredRentalIncome_Amount,
LeaseIncomeSchedule.FinanceRentalIncome_Amount,
LeaseIncomeSchedule.ResidualIncome_Amount,
LeaseIncomeSchedule.ResidualIncomeBalance_Amount,
CASE WHEN Payment_Amount <> 0 THEN 1 ELSE 0 END,
0,
0,
LeaseIncomeSchedule.OperatingBeginNetBookValue_Amount,
LeaseIncomeSchedule.OperatingEndNetBookValue_Amount,
LeaseIncomeSchedule.Depreciation_Amount,
ROW_NUMBER()OVER (PARTITION BY LeaseIncomeSchedule.IncomeType ORDER BY LeaseIncomeSchedule.IncomeDate),
LeaseFinances.IsFutureFunding,
LeaseIncomeSchedule.FinancePayment_Amount,
LeaseIncomeSchedule.FinancePayment_Amount,
LeaseIncomeSchedule.FinanceBeginNetBookValue_Amount,
LeaseIncomeSchedule.FinanceIncome_Amount,
LeaseIncomeSchedule.FinanceIncomeBalance_Amount,
LeaseIncomeSchedule.FinanceEndNetBookValue_Amount,
LeaseIncomeSchedule.FinanceResidualIncome_Amount,
LeaseIncomeSchedule.FinanceResidualIncomeBalance_Amount,
LeaseIncomeSchedule.DeferredSellingProfitIncome_Amount,
LeaseIncomeSchedule.DeferredSellingProfitIncomeBalance_Amount,
LeaseIncomeSchedule.Id,
0,
0
FROM LeaseFinances 
INNER JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
INNER JOIN #LeaseIncomeSchedulesTemp AS LeaseIncomeSchedule ON LeaseFinances.Id = LeaseIncomeSchedule.LeaseFinanceId
WHERE LeaseFinances.ContractId = @ContractId
AND ((LeaseFinanceDetails.InterimInterestBillingType='Capitalize' AND LeaseIncomeSchedule.IncomeType = 'InterimInterest')
OR (LeaseFinanceDetails.InterimRentBillingType='Capitalize' AND LeaseIncomeSchedule.IncomeType = 'InterimRent'))
ORDER BY LeaseIncomeSchedule.IncomeDate

SET @CurrentPaymentNumber = 0
SET @LastPaymentNumber = 0
SET @RowNo = 1
SET @Count = (SELECT COUNT(*) FROM #LeaseIncomeSchedule WHERE PaymentType = 'InterimInterest')
WHILE @RowNo <= @Count
BEGIN
	UPDATE #LeaseIncomeSchedule
	SET @LastPaymentNumber = CASE WHEN PaymentAmount <> 0 THEN @LastPaymentNumber + 1
	ELSE @LastPaymentNumber END,
	@CurrentPaymentNumber = @LastPaymentNumber,
	PaymentNumber = @CurrentPaymentNumber
	FROM #LeaseIncomeSchedule
	WHERE PaymentType = 'InterimInterest' AND RowNumber = @RowNo
	SET @RowNo = @RowNo + 1
END

SET @CurrentPaymentNumber = 0
SET @LastPaymentNumber = 0
SET @RowNo = 1
SET @Count = (SELECT COUNT(*) FROM #LeaseIncomeSchedule WHERE PaymentType = 'InterimRent')
WHILE @RowNo <= @Count
BEGIN
	UPDATE #LeaseIncomeSchedule
	SET @LastPaymentNumber = CASE WHEN PaymentAmount <> 0 THEN @LastPaymentNumber + 1
	ELSE @LastPaymentNumber END,
	@CurrentPaymentNumber = @LastPaymentNumber,
	PaymentNumber = @CurrentPaymentNumber
	FROM #LeaseIncomeSchedule
	WHERE PaymentType = 'InterimRent' AND RowNumber=@RowNo
	SET @RowNo = @RowNo + 1
END

--- To show Income Schedules For Capitalize Interim Period End --
-- Actual Income Schedules Begin
INSERT INTO #LeaseIncomeSchedule
(
LeaseFinanceId,
LeaseContractType,
IsRenewal,
ModificationType,
AdvanceOrArrear,
PaymentNumber,
PaymentType,
StartDate,
EndDate,
Type,
IncomeDate,
IsNonAccrual,
IsGLPosted,
BeginNBV,
AccountingAmount,
PaymentAmount,
DisbursementAmount,
Income,
IncomeBalance,
EndNBV,
RentalIncome,
DeferredRentalIncome,
FinancingDeferredRentalIncome,
FinancingRentalIncome,
ResidualIncome,
ResidualIncomeBalance,
ActualIncomePeriod,
ActualBlendedIncomePeriod,
BlendedIncome,
BlendedIncomeBalance,
BlendedItemName,
IsBlendedIncome,
OperatingBeginNBV,
OperatingEndNBV,
Depreciation,
LeaseFloatRateIncome,
FinanceFloatRateIncome,
LeaseFloatRatePaymentAdjustment,
FinanceFloatRatePaymentAdjustment,
IsFloatRateLease,
IsFutureFunding,
PaymentGroupNumber,
BlendedItemPaymentGroupNumber,
BlendedItemId,
IsPaymentEndDate,
IsAmortize,
RowNumber,
FinancingPaymentAmount,
FinancingAccountingAmount	,
FinancingBeginNBV	,
FinancingIncome,
FinancingIncomeBalance,
FinancingEndNBV,
FinancingResidualIncome,
FinancingResidualIncomeBalance,
DeferredSellingProfitIncome	,
DeferredSellingProfitBalance,
LeaseIncomeScheduleId,
FinancingDepreciation,
BlendedIncomeScheduleId
)
SELECT
LeaseFinances.Id,
LeaseFinanceDetails.LeaseContractType,
LeasePaymentSchedule.IsRenewal,
LeaseIncomeSchedule.LeaseModificationType,
CASE WHEN LeaseFinanceDetails.IsAdvance=1 THEN 'Advance'
ELSE 'Arrear'
END AS AdvanceOrArrear,
LeasePaymentSchedule.PaymentNumber,
LeasePaymentSchedule.PaymentType,
LeasePaymentSchedule.StartDate,
LeasePaymentSchedule.EndDate,
LeaseIncomeSchedule.IncomeType AS Type,
LeaseIncomeSchedule.IncomeDate,
LeaseIncomeSchedule.IsNonAccrual,
LeaseIncomeSchedule.IsGLPosted,
SUM(LeaseIncomeSchedule.BeginNetBookValue_Amount),
SUM(LeaseIncomeSchedule.Payment_Amount),
SUM(LeaseIncomeSchedule.Payment_Amount),
CASE WHEN LeaseFinances.IsFutureFunding=1 AND LeaseFinanceDetails.CommencementDate = LeaseIncomeSchedule.IncomeDate THEN SUM(LeaseIncomeSchedule.BeginNetBookValue_Amount) ELSE 0 END AS DisbursementAmount,
SUM(LeaseIncomeSchedule.Income_Amount),
SUM(LeaseIncomeSchedule.IncomeBalance_Amount),
SUM(LeaseIncomeSchedule.EndNetBookValue_Amount),
SUM(LeaseIncomeSchedule.RentalIncome_Amount),
SUM(LeaseIncomeSchedule.DeferredRentalIncome_Amount),
SUM(LeaseIncomeSchedule.FinanceDeferredRentalIncome_Amount),
SUM(LeaseIncomeSchedule.FinanceRentalIncome_Amount),
SUM(LeaseIncomeSchedule.ResidualIncome_Amount),
SUM(LeaseIncomeSchedule.ResidualIncomeBalance_Amount),
CASE WHEN LeasePaymentSchedule.PaymentType='InterimInterest'
THEN ROW_NUMBER() OVER ( PARTITION BY LeasePaymentSchedule.PaymentNumber,LeasePaymentSchedule.PaymentType,#LeaseFinancesTemp.GroupedOrder ORDER BY LeaseIncomeSchedule.IncomeDate DESC)
WHEN LeasePaymentSchedule.PaymentType='InterimRent'
THEN CASE WHEN LeaseFinanceDetails.IsInterimRentInAdvance=1
THEN ROW_NUMBER() OVER ( PARTITION BY LeasePaymentSchedule.PaymentNumber,LeasePaymentSchedule.PaymentType,#LeaseFinancesTemp.GroupedOrder ORDER BY LeaseIncomeSchedule.IncomeDate)
ELSE ROW_NUMBER() OVER ( PARTITION BY LeasePaymentSchedule.PaymentNumber,LeasePaymentSchedule.PaymentType,#LeaseFinancesTemp.GroupedOrder ORDER BY LeaseIncomeSchedule.IncomeDate DESC)
END
WHEN LeasePaymentSchedule.PaymentType='FixedTerm'
THEN CASE WHEN LeaseFinanceDetails.IsAdvance=1
THEN ROW_NUMBER() OVER ( PARTITION BY LeasePaymentSchedule.PaymentNumber,LeasePaymentSchedule.PaymentType,#LeaseFinancesTemp.GroupedOrder ORDER BY LeaseIncomeSchedule.IncomeDate)
ELSE ROW_NUMBER() OVER ( PARTITION BY LeasePaymentSchedule.PaymentNumber,LeasePaymentSchedule.PaymentType,#LeaseFinancesTemp.GroupedOrder ORDER BY LeaseIncomeSchedule.IncomeDate DESC)
END
WHEN LeasePaymentSchedule.PaymentType='OTP'
THEN CASE WHEN LeaseFinanceDetails.IsAdvance=1
THEN ROW_NUMBER() OVER ( PARTITION BY LeasePaymentSchedule.PaymentNumber,LeasePaymentSchedule.PaymentType,#LeaseFinancesTemp.GroupedOrder ORDER BY LeaseIncomeSchedule.IncomeDate)
ELSE ROW_NUMBER() OVER ( PARTITION BY LeasePaymentSchedule.PaymentNumber,LeasePaymentSchedule.PaymentType,#LeaseFinancesTemp.GroupedOrder ORDER BY LeaseIncomeSchedule.IncomeDate DESC)
END
WHEN LeasePaymentSchedule.PaymentType='Supplemental'
THEN CASE WHEN LeaseFinanceDetails.IsSupplementalAdvance=1
THEN ROW_NUMBER() OVER ( PARTITION BY LeasePaymentSchedule.PaymentNumber,LeasePaymentSchedule.PaymentType,#LeaseFinancesTemp.GroupedOrder ORDER BY LeaseIncomeSchedule.IncomeDate)
ELSE ROW_NUMBER() OVER ( PARTITION BY LeasePaymentSchedule.PaymentNumber,LeasePaymentSchedule.PaymentType,#LeaseFinancesTemp.GroupedOrder ORDER BY LeaseIncomeSchedule.IncomeDate DESC)
END
END AS ActualIncomePeriod,
ROW_NUMBER() OVER (PARTITION BY BlendedIncomeSchedule.IncomeDate,LeasePaymentSchedule.PaymentType,LeaseIncomeSchedule.Id ORDER BY LeaseIncomeSchedule.IncomeDate, LeasePaymentSchedule.PaymentType),
SUM(ISNULL(BlendedIncomeSchedule.Income_Amount,0)),
SUM(ISNULL(BlendedIncomeSchedule.IncomeBalance_Amount,0)),
BlendedIncomeSchedule.BlendedItemName,
CASE WHEN BlendedIncomeSchedule.Id IS NULL
THEN 0
ELSE 1
END AS IsBlendedIncome,
SUM(LeaseIncomeSchedule.OperatingBeginNetBookValue_Amount),
SUM(LeaseIncomeSchedule.OperatingEndNetBookValue_Amount),
SUM(LeaseIncomeSchedule.Depreciation_Amount),
SUM(ISNULL(LeaseFloatRateIncomeTemp.FloatRateIncome,0)) LeaseFloatRateIncome,
SUM(ISNULL(FinanceFloatRateIncomeTemp.FloatRateIncome,0)) FinanceFloatRateIncome,
SUM(ISNULL(LeaseFloatRateIncomeTemp.FloatRatePaymentAdjustment,0)) LeaseFloatRatePaymentAdjustment,
SUM(ISNULL(FinanceFloatRateIncomeTemp.FloatRatePaymentAdjustment,0)) FinanceFloatRatePaymentAdjustment,
LeaseFinanceDetails.IsFloatRateLease,
LeaseFinances.IsFutureFunding,
DENSE_RANK() OVER (ORDER BY LeasePaymentSchedule.StartDate,LeasePaymentSchedule.EndDate),
DENSE_RANK() OVER (ORDER BY LeasePaymentSchedule.StartDate,LeasePaymentSchedule.EndDate),
BlendedIncomeSchedule.BlendedItemId,
CASE WHEN LeaseIncomeSchedule.IncomeDate = LeasePaymentSchedule.EndDate THEN 1 ELSE 0 END,
BlendedIncomeSchedule.IsAmortize,
ROW_NUMBER() OVER (ORDER BY LeaseIncomeSchedule.IncomeDate),
SUM(LeaseIncomeSchedule.FinancePayment_Amount),
SUM(LeaseIncomeSchedule.FinancePayment_Amount),
SUM(LeaseIncomeSchedule.FinanceBeginNetBookValue_Amount),
SUM(LeaseIncomeSchedule.FinanceIncome_Amount),
SUM(LeaseIncomeSchedule.FinanceIncomeBalance_Amount),
SUM(LeaseIncomeSchedule.FinanceEndNetBookValue_Amount),
SUM(LeaseIncomeSchedule.FinanceResidualIncome_Amount),
SUM(LeaseIncomeSchedule.FinanceResidualIncomeBalance_Amount),
SUM(LeaseIncomeSchedule.DeferredSellingProfitIncome_Amount),
SUM(LeaseIncomeSchedule.DeferredSellingProfitIncomeBalance_Amount),
LeaseIncomeSchedule.Id,
0,
BlendedIncomeSchedule.Id
FROM LeaseFinances
INNER JOIN
LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
INNER JOIN
#LeaseIncomeSchedulesTemp AS LeaseIncomeSchedule ON LeaseFinances.Id = LeaseIncomeSchedule.LeaseFinanceId AND LeaseIncomeSchedule.AdjustmentEntry = 0
INNER JOIN
#LeasePaymentSchedulesTemp AS LeasePaymentSchedule ON LeaseFinanceDetails.Id = LeasePaymentSchedule.LeaseFinanceDetailId
AND LeaseIncomeSchedule.LeaseFinanceId = LeasePaymentSchedule.LeaseFinanceDetailId
AND LeaseIncomeSchedule.IncomeDate>=LeasePaymentSchedule.StartDate
AND LeaseIncomeSchedule.IncomeDate<=LeasePaymentSchedule.EndDate
AND (LeaseIncomeSchedule.IncomeType=LeasePaymentSchedule.PaymentType
OR (LeaseIncomeSchedule.IncomeType='OverTerm' AND LeasePaymentSchedule.PaymentType='OTP')
OR (LeaseIncomeSchedule.IncomeType='Supplemental' AND LeasePaymentSchedule.PaymentType='Supplemental'))
INNER JOIN
#LeaseFinancesTemp ON LeasePaymentSchedule.LeaseFinanceDetailId = #LeaseFinancesTemp.Id
LEFT JOIN #BlendedIncomeSchedulesTemp AS BlendedIncomeSchedule ON LeaseFinances.ContractId = BlendedIncomeSchedule.ContractId AND LeaseIncomeSchedule.IncomeDate = BlendedIncomeSchedule.IncomeDate AND BlendedIncomeSchedule.AdjustmentEntry=0
LEFT JOIN #LeaseFloatRateIncomesTemp LeaseFloatRateIncomeTemp ON LeaseIncomeSchedule.Id = LeaseFloatRateIncomeTemp.LeaseIncomeScheduleId AND LeaseFloatRateIncomeTemp.IsLeaseAsset = 1
LEFT JOIN #LeaseFloatRateIncomesTemp FinanceFloatRateIncomeTemp ON LeaseIncomeSchedule.Id = FinanceFloatRateIncomeTemp.LeaseIncomeScheduleId AND FinanceFloatRateIncomeTemp.IsLeaseAsset = 0
WHERE LeaseFinances.ContractId = @ContractId
GROUP BY
LeaseFinances.ContractId,
LeaseFinances.IsFutureFunding,
LeaseFinances.Id,
LeaseFinanceDetails.CommencementDate,
LeaseFinanceDetails.LeaseContractType,
LeaseFinanceDetails.IsAdvance,
LeaseFinanceDetails.IsFloatRateLease,
LeaseFinanceDetails.IsInterimRentInAdvance,
LeaseFinanceDetails.IsSupplementalAdvance,
LeasePaymentSchedule.LeaseFinanceDetailId,
LeasePaymentSchedule.PaymentNumber,
LeasePaymentSchedule.PaymentType,
LeasePaymentSchedule.StartDate,
LeasePaymentSchedule.EndDate,
LeasePaymentSchedule.IsRenewal,
LeaseIncomeSchedule.IncomeType,
LeaseIncomeSchedule.IncomeDate,
LeaseIncomeSchedule.IsNonAccrual,
LeaseIncomeSchedule.LeaseModificationType,
LeaseIncomeSchedule.IsGLPosted,
#LeaseFinancesTemp.GroupedOrder,
BlendedIncomeSchedule.Income_Amount,
BlendedIncomeSchedule.IncomeBalance_Amount,
BlendedIncomeSchedule.IncomeDate,
BlendedIncomeSchedule.Id,
BlendedIncomeSchedule.BlendedItemId,
BlendedIncomeSchedule.BlendedItemName,
BlendedIncomeSchedule.IsAmortize,
LeaseIncomeSchedule.Id
ORDER BY LeaseIncomeSchedule.IncomeDate,LeasePaymentSchedule.PaymentType

UPDATE #LeaseIncomeSchedule SET PaymentAmount=0.00 WHERE ActualIncomePeriod <> 1 AND IncomeDate <>(@CommencementDate) AND PaymentNumber <> 1
IF(@DeferInterimRent = 'TRUE' OR @DeferInterimRentForSingleInstallment = 'TRUE')
BEGIN
;WITH CTE_LeaseDownPaymentAmount
AS(
Select
	LeaseComponentDownPaymentAmount = Sum(RD.LeaseComponentAmount_Amount)
   ,NonLeaseComponentDownPaymentAmount = Sum(RD.NonLeaseComponentAmount_Amount)
   ,LeaseFinanceId = LFD.Id 
FROM LeaseFinances LF JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
JOIN LeasePaymentSchedules LPS ON LPS.LeaseFinanceDetailId = LFD.Id
JOIN Receivables R ON R.PaymentScheduleId = LPS.Id
JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId
WHERE LF.ContractId = @ContractId
AND LPS.IsActive=1
AND R.IsActive=1
AND RD.IsActive=1
AND LPS.PaymentType='DownPayment'
AND LPS.Amount_Amount <> 0
Group by LFD.Id
)
UPDATE #LeaseIncomeSchedule SET PaymentAmount = ISNULL(LDP.LeaseComponentDownPaymentAmount,0)
								,FinancingPaymentAmount = ISNULL(LDP.NonLeaseComponentDownPaymentAmount,0) 
FROM #LeaseIncomeSchedule LIS JOIN LeaseFinanceDetails LFD ON LIS.LeaseFinanceId = LFD.Id
LEFT JOIN CTE_LeaseDownPaymentAmount LDP on LFD.Id = LDP.LeaseFinanceId
WHERE IncomeDate = @CommencementDate 
	AND PaymentType = 'FixedTerm' 
END


UPDATE #LeaseIncomeSchedule
SET
AdvanceOrArrear=NULL,
PaymentNumber=NULL,
StartDate=NULL,
IsNonAccrual=NULL,
IsGLPosted=NULL,
EndDate=NULL,
BeginNBV=NULL,
AccountingAmount=NULL,
PaymentAmount=NULL,
DisbursementAmount=NULL,
Income=NULL,
IncomeBalance=NULL,
EndNBV=NULL,
RentalIncome=NULL,
DeferredRentalIncome=NULL,
FinancingDeferredRentalIncome=NULL,
FinancingRentalIncome=NULL,
LeaseFloatRateIncome = NULL,
FinanceFloatRateIncome = NULL,
LeaseFloatRatePaymentAdjustment = NULL,
FinanceFloatRatePaymentAdjustment = NULL,
ResidualIncome=NULL,
ResidualIncomeBalance=NULL,
OperatingBeginNBV=NULL,
OperatingEndNBV=NULL,
Depreciation=NULL,
PaymentGroupNumber = NULL,
FinancingPaymentAmount= NULL,
FinancingAccountingAmount= NULL	,
FinancingBeginNBV= NULL	,
FinancingIncome= NULL,
FinancingIncomeBalance= NULL,
FinancingEndNBV= NULL,
FinancingResidualIncome= NULL,
FinancingResidualIncomeBalance= NULL,
DeferredSellingProfitIncome	= NULL,
DeferredSellingProfitBalance= NULL
WHERE
(IsBlendedIncome=1 AND ActualBlendedIncomePeriod <> 1)

--Populate Income Balance columns Begin
;WITH CTE_LeaseIncome
AS(
SELECT #LeaseIncomeSchedule.RowNumber, SUM(PreviousIncomes.Income) Income, SUM(PreviousIncomes.ResidualIncome) ResidualIncome,
SUM(PreviousIncomes.FinancingIncome) FinanceIncome, SUM(PreviousIncomes.FinancingResidualIncome) FinanceResidualIncome
FROM #LeaseIncomeSchedule
INNER JOIN #LeaseIncomeSchedule AS PreviousIncomes
ON #LeaseIncomeSchedule.PaymentGroupNumber = PreviousIncomes.PaymentGroupNumber
AND PreviousIncomes.IsPaymentEndDate=0 AND #LeaseIncomeSchedule.IncomeDate >= PreviousIncomes.IncomeDate
WHERE #LeaseIncomeSchedule.IsPaymentEndDate=0 AND #LeaseIncomeSchedule.PaymentGroupNumber IS NOT NULL
GROUP BY #LeaseIncomeSchedule.IncomeDate,#LeaseIncomeSchedule.PaymentGroupNumber,#LeaseIncomeSchedule.RowNumber
)

UPDATE #LeaseIncomeSchedule
SET IncomeBalance = IncomeBalance - CTE_LeaseIncome.Income,
ResidualIncomeBalance = ResidualIncomeBalance + CTE_LeaseIncome.ResidualIncome,
FinancingIncomeBalance = FinancingIncomeBalance - CTE_LeaseIncome.FinanceIncome,
FinancingResidualIncomeBalance = FinancingResidualIncomeBalance + CTE_LeaseIncome.FinanceResidualIncome
FROM #LeaseIncomeSchedule
INNER JOIN CTE_LeaseIncome ON #LeaseIncomeSchedule.RowNumber = CTE_LeaseIncome.RowNumber
WHERE #LeaseIncomeSchedule.PaymentGroupNumber IS NOT NULL 
AND #LeaseIncomeSchedule.PaymentType not in ('InterimInterest','InterimRent')
AND #LeaseIncomeSchedule.IncomeDate = #LeaseIncomeSchedule.EndDate

IF EXISTS(SELECT 1 FROM #LeaseIncomeSchedule WHERE IsBlendedIncome = 1)
BEGIN
;WITH CTE_BlendedIncome
AS(
SELECT #LeaseIncomeSchedule.RowNumber,SUM(PreviousIncomes.BlendedIncome) BlendedIncome
FROM #LeaseIncomeSchedule
INNER JOIN #LeaseIncomeSchedule AS PreviousIncomes
ON #LeaseIncomeSchedule.BlendedItemPaymentGroupNumber = PreviousIncomes.BlendedItemPaymentGroupNumber
AND #LeaseIncomeSchedule.IsAmortize = PreviousIncomes.IsAmortize
AND PreviousIncomes.IsPaymentEndDate=0 AND #LeaseIncomeSchedule.IncomeDate >= PreviousIncomes.IncomeDate
AND #LeaseIncomeSchedule.BlendedItemId = PreviousIncomes.BlendedItemId
WHERE #LeaseIncomeSchedule.IsPaymentEndDate=0 AND #LeaseIncomeSchedule.IsBlendedIncome=1 AND PreviousIncomes.IsBlendedIncome=1
AND #LeaseIncomeSchedule.BlendedItemPaymentGroupNumber IS NOT NULL
GROUP BY #LeaseIncomeSchedule.IncomeDate,#LeaseIncomeSchedule.BlendedItemPaymentGroupNumber,#LeaseIncomeSchedule.IsAmortize,#LeaseIncomeSchedule.RowNumber,#LeaseIncomeSchedule.BlendedItemId
)

UPDATE #LeaseIncomeSchedule
SET BlendedIncomeBalance = CASE WHEN IsAmortize = 1 THEN BlendedIncomeBalance - CTE_BlendedIncome.BlendedIncome ELSE BlendedIncomeBalance + CTE_BlendedIncome.BlendedIncome END
FROM #LeaseIncomeSchedule
INNER JOIN CTE_BlendedIncome ON #LeaseIncomeSchedule.RowNumber = CTE_BlendedIncome.RowNumber
WHERE #LeaseIncomeSchedule.BlendedItemPaymentGroupNumber IS NOT NULL
END

--Populate Income Balance columns End
-- Actual Income Schedules End
-- To Add Payments for Non Accrual Period Begin
IF(@IsAccounting=0)
BEGIN
SELECT LeaseIncomeSchedules.IncomeDate,LeaseIncomeSchedules.Payment_Amount, LeaseIncomeSchedules.FinancePayment_Amount
INTO #NonAccrualIncomeSchedules
FROM LeaseFinances
INNER JOIN LeaseIncomeSchedules ON LeaseFinances.Id = LeaseIncomeSchedules.LeaseFinanceId
WHERE LeaseFinances.ContractId = @ContractId
AND LeaseIncomeSchedules.IsSchedule=0 AND LeaseIncomeSchedules.IsAccounting=1 AND LeaseIncomeSchedules.IsNonAccrual=1

;WITH CTE_ActualIncomeSchedules
AS
(
SELECT ROW_NUMBER() OVER (ORDER BY IncomeDate) AS RowNumber,IncomeDate FROM #LeaseIncomeSchedulesTemp WHERE AdjustmentEntry = 0
)

SELECT CTE_ActualIncomeSchedules.IncomeDate, SUM(#NonAccrualIncomeSchedules.Payment_Amount) AS PaymentAmount, SUM(#NonAccrualIncomeSchedules.FinancePayment_Amount) AS FinancePaymentAmount
INTO #NonAccrualAmountSummary
FROM
CTE_ActualIncomeSchedules
LEFT JOIN CTE_ActualIncomeSchedules AS PreviousIncomeSchedule ON CTE_ActualIncomeSchedules.RowNumber - 1 = PreviousIncomeSchedule.RowNumber
INNER JOIN #NonAccrualIncomeSchedules ON (PreviousIncomeSchedule.IncomeDate = NULL OR PreviousIncomeSchedule.IncomeDate <= #NonAccrualIncomeSchedules.IncomeDate) AND CTE_ActualIncomeSchedules.IncomeDate >= #NonAccrualIncomeSchedules.IncomeDate
GROUP BY CTE_ActualIncomeSchedules.IncomeDate

UPDATE #LeaseIncomeSchedule
SET PaymentAmount = #LeaseIncomeSchedule.PaymentAmount + #NonAccrualAmountSummary.PaymentAmount,
FinancingPaymentAmount = #LeaseIncomeSchedule.FinancingPaymentAmount + #NonAccrualAmountSummary.FinancePaymentAmount,
AccountingAmount = #LeaseIncomeSchedule.AccountingAmount + #NonAccrualAmountSummary.PaymentAmount,
FinancingAccountingAmount = #LeaseIncomeSchedule.FinancingAccountingAmount + #NonAccrualAmountSummary.FinancePaymentAmount
FROM #LeaseIncomeSchedule
JOIN #NonAccrualAmountSummary ON #LeaseIncomeSchedule.IncomeDate = #NonAccrualAmountSummary.IncomeDate
DROP TABLE #NonAccrualIncomeSchedules
DROP TABLE #NonAccrualAmountSummary
END

-- To Add Payments for Non Accrual Period End
---GracePeriod Income Schedules for Supplemental Begin
INSERT INTO #LeaseIncomeSchedule
(
LeaseFinanceId,
LeaseContractType,
IsRenewal,
ModificationType,
AdvanceOrArrear,
PaymentType,
Type,
IncomeDate,
IsGLPosted,
IsNonAccrual,
BeginNBV,
AccountingAmount,
PaymentAmount,
Income,
IncomeBalance,
EndNBV,
RentalIncome,
DeferredRentalIncome,
FinancingDeferredRentalIncome,
FinancingRentalIncome,
ResidualIncome,
ResidualIncomeBalance,
ActualIncomePeriod,
ActualBlendedIncomePeriod,
IsBlendedIncome,
OperatingBeginNBV,
OperatingEndNBV,
Depreciation,
IsFutureFunding,
PaymentGroupNumber,
BlendedItemPaymentGroupNumber,
BlendedItemId,
IsPaymentEndDate,
IsAmortize,
RowNumber,
FinancingPaymentAmount,
FinancingAccountingAmount,
FinancingBeginNBV,
FinancingIncome,
FinancingIncomeBalance,
FinancingEndNBV,
FinancingResidualIncome,
FinancingResidualIncomeBalance,
DeferredSellingProfitIncome	,
DeferredSellingProfitBalance,
LeaseIncomeScheduleId,
FinancingDepreciation,
BlendedIncomeScheduleId
)
SELECT
LeaseFinances.Id,
LeaseFinanceDetails.LeaseContractType,
0,
LeaseIncomeSchedule.LeaseModificationType,
'Arrear',
LeaseIncomeSchedule.IncomeType,
LeaseIncomeSchedule.IncomeType,
LeaseIncomeSchedule.IncomeDate,
LeaseIncomeSchedule.IsGLPosted,
LeaseIncomeSchedule.IsNonAccrual,
LeaseIncomeSchedule.BeginNetBookValue_Amount,
LeaseIncomeSchedule.Payment_Amount,
0.00,
LeaseIncomeSchedule.Income_Amount,
LeaseIncomeSchedule.IncomeBalance_Amount,
LeaseIncomeSchedule.EndNetBookValue_Amount,
LeaseIncomeSchedule.RentalIncome_Amount,
LeaseIncomeSchedule.DeferredRentalIncome_Amount,
LeaseIncomeSchedule.FinanceDeferredRentalIncome_Amount,
LeaseIncomeSchedule.FinanceRentalIncome_Amount,
LeaseIncomeSchedule.ResidualIncome_Amount,
LeaseIncomeSchedule.ResidualIncomeBalance_Amount,
0,
0,
0,
LeaseIncomeSchedule.OperatingBeginNetBookValue_Amount,
LeaseIncomeSchedule.OperatingEndNetBookValue_Amount,
LeaseIncomeSchedule.Depreciation_Amount,
LeaseFinances.IsFutureFunding,
0,
0,
0,
0,
0,
0,
0,
0,
0,
0,
0,
0,
0,
0,
0,
0,
LeaseIncomeSchedule.Id,
0,
0
FROM LeaseFinances
INNER JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
INNER JOIN #LeaseIncomeSchedulesTemp AS LeaseIncomeSchedule ON LeaseFinances.Id = LeaseIncomeSchedule.LeaseFinanceId
AND LeaseFinanceDetails.TerminationNoticeEffectiveDate IS NOT NULL
AND LeaseFinanceDetails.TerminationNoticeEffectiveDate < LeaseIncomeSchedule.IncomeDate
AND CAST(DATEADD(MM,LeaseFinanceDetails.SupplementalGracePeriod,LeaseFinanceDetails.TerminationNoticeEffectiveDate) AS DATE) >= LeaseIncomeSchedule.IncomeDate
WHERE LeaseFinances.ContractId = @ContractId
AND LeaseIncomeSchedule.IncomeType = 'Supplemental'
ORDER BY LeaseIncomeSchedule.IncomeDate

---GracePeriod Income Schedules for Supplemental End
---Adjustment Income Schedules Begin
INSERT INTO #LeaseIncomeSchedule
(
LeaseFinanceId,
LeaseContractType,
IsRenewal,
ModificationType,
AdvanceOrArrear,
PaymentType,
Type,
IncomeDate,
IsGLPosted,
IsNonAccrual,
BeginNBV,
AccountingAmount,
PaymentAmount,
Income,
IncomeBalance,
EndNBV,
RentalIncome,
DeferredRentalIncome,
FinancingDeferredRentalIncome,
FinancingRentalIncome,
ResidualIncome,
ResidualIncomeBalance,
ActualIncomePeriod,
OperatingBeginNBV,
OperatingEndNBV,
Depreciation,
ActualBlendedIncomePeriod,
BlendedIncome,
BlendedIncomeBalance,
BlendedItemName,
IsBlendedIncome,
LeaseFloatRateIncome,
FinanceFloatRateIncome,
LeaseFloatRatePaymentAdjustment,
FinanceFloatRatePaymentAdjustment,
IsFloatRateLease,
IsFutureFunding,
FinancingPaymentAmount,
FinancingAccountingAmount	,
FinancingBeginNBV	,
FinancingIncome,
FinancingIncomeBalance,
FinancingEndNBV,
FinancingResidualIncome,
FinancingResidualIncomeBalance,
DeferredSellingProfitIncome	,
DeferredSellingProfitBalance,
LeaseIncomeScheduleId,
FinancingDepreciation,
BlendedIncomeScheduleId
)
SELECT
LeaseFinances.Id,
LeaseFinanceDetails.LeaseContractType,
0,
LeaseIncomeSchedule.LeaseModificationType,
'Arrear',
LeaseIncomeSchedule.IncomeType,
LeaseIncomeSchedule.IncomeType,
LeaseIncomeSchedule.IncomeDate,
LeaseIncomeSchedule.IsGLPosted,
LeaseIncomeSchedule.IsNonAccrual,
LeaseIncomeSchedule.BeginNetBookValue_Amount,
LeaseIncomeSchedule.Payment_Amount,
0.00,
LeaseIncomeSchedule.Income_Amount,
LeaseIncomeSchedule.IncomeBalance_Amount,
LeaseIncomeSchedule.EndNetBookValue_Amount,
LeaseIncomeSchedule.RentalIncome_Amount,
LeaseIncomeSchedule.DeferredRentalIncome_Amount,
LeaseIncomeSchedule.FinanceDeferredRentalIncome_Amount,
LeaseIncomeSchedule.FinanceRentalIncome_Amount,
LeaseIncomeSchedule.ResidualIncome_Amount,
LeaseIncomeSchedule.ResidualIncomeBalance_Amount,
0,
LeaseIncomeSchedule.OperatingBeginNetBookValue_Amount,
LeaseIncomeSchedule.OperatingEndNetBookValue_Amount,
LeaseIncomeSchedule.Depreciation_Amount,
ROW_NUMBER() OVER (PARTITION BY BlendedIncomeSchedule.IncomeDate,LeaseIncomeSchedule.Id ORDER BY LeaseIncomeSchedule.IncomeDate),
BlendedIncomeSchedule.Income_Amount,
BlendedIncomeSchedule.IncomeBalance_Amount,
BlendedIncomeSchedule.BlendedItemName,
CASE WHEN BlendedIncomeSchedule.Id IS NULL
THEN 0
ELSE 1
END AS IsBlendedIncome,
LeaseAdjustmentFloatRateIncomeTemp.FloatRateIncome LeaseFloatRateIncome,
FinanceAdjustmentFloatRateIncomeTemp.FloatRateIncome FinanceFloatRateIncome,
LeaseAdjustmentFloatRateIncomeTemp.FloatRatePaymentAdjustment LeaseFloatRatePaymentAdjustment,
FinanceAdjustmentFloatRateIncomeTemp.FloatRatePaymentAdjustment FinanceFloatRatePaymentAdjustment,
LeaseFinanceDetails.IsFloatRateLease,
LeaseFinances.IsFutureFunding,
0,
LeaseIncomeSchedule.FinancePayment_Amount,
LeaseIncomeSchedule.FinanceBeginNetBookValue_Amount,
LeaseIncomeSchedule.FinanceIncome_Amount,
LeaseIncomeSchedule.FinanceIncomeBalance_Amount,
LeaseIncomeSchedule.FinanceEndNetBookValue_Amount,
LeaseIncomeSchedule.FinanceResidualIncome_Amount,
LeaseIncomeSchedule.FinanceResidualIncomeBalance_Amount,
LeaseIncomeSchedule.DeferredSellingProfitIncome_Amount,
LeaseIncomeSchedule.DeferredSellingProfitIncomeBalance_Amount,
LeaseIncomeSchedule.Id,
0,
BlendedIncomeSchedule.Id
FROM LeaseFinances
INNER JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
INNER JOIN #LeaseIncomeSchedulesTemp AS LeaseIncomeSchedule ON LeaseFinances.Id = LeaseIncomeSchedule.LeaseFinanceId AND LeaseIncomeSchedule.AdjustmentEntry=1
LEFT JOIN #BlendedIncomeSchedulesTemp AS BlendedIncomeSchedule ON LeaseFinances.ContractId = BlendedIncomeSchedule.ContractId AND LeaseIncomeSchedule.IncomeDate = BlendedIncomeSchedule.IncomeDate AND BlendedIncomeSchedule.AdjustmentEntry=1 AND LeaseIncomeSchedule.IsNonAccrual = BlendedIncomeSchedule.IsNonAccrual
LEFT JOIN #LeaseAdjustmentFloatRateIncomesTemp LeaseAdjustmentFloatRateIncomeTemp ON LeaseIncomeSchedule.Id = LeaseAdjustmentFloatRateIncomeTemp.LeaseIncomeScheduleId AND LeaseAdjustmentFloatRateIncomeTemp.IsLeaseAsset = 1
LEFT JOIN #LeaseAdjustmentFloatRateIncomesTemp FinanceAdjustmentFloatRateIncomeTemp ON LeaseIncomeSchedule.Id = FinanceAdjustmentFloatRateIncomeTemp.LeaseIncomeScheduleId AND FinanceAdjustmentFloatRateIncomeTemp.IsLeaseAsset = 0
WHERE LeaseFinances.ContractId = @ContractId
ORDER BY LeaseIncomeSchedule.IncomeDate

-- Blended Income Schedule Adjustment Entry Matching Non-Adjustment Entry Lease Income Schedule 
SELECT Id INTO #BISAdjustmentEntriesIds FROM #BlendedIncomeSchedulesTemp
LEFT JOIN #LeaseIncomeSchedule ON #BlendedIncomeSchedulesTemp.Id = #LeaseIncomeSchedule.BlendedIncomeScheduleId 
WHERE #LeaseIncomeSchedule.BlendedIncomeScheduleId IS NULL AND #BlendedIncomeSchedulesTemp.AdjustmentEntry = 1

IF EXISTS (SELECT Id FROM #BISAdjustmentEntriesIds)
BEGIN

INSERT INTO #LeaseIncomeSchedule
(
LeaseFinanceId,
LeaseContractType,
IsRenewal,
ModificationType,
AdvanceOrArrear,
PaymentType,
Type,
IncomeDate,
IsGLPosted,
IsNonAccrual,
BeginNBV,
AccountingAmount,
PaymentAmount,
Income,
IncomeBalance,
EndNBV,
RentalIncome,
DeferredRentalIncome,
FinancingDeferredRentalIncome,
FinancingRentalIncome,
ResidualIncome,
ResidualIncomeBalance,
ActualIncomePeriod,
OperatingBeginNBV,
OperatingEndNBV,
Depreciation,
ActualBlendedIncomePeriod,
BlendedIncome,
BlendedIncomeBalance,
BlendedItemName,
IsBlendedIncome,
IsFloatRateLease,
IsFutureFunding,
FinancingPaymentAmount,
FinancingAccountingAmount	,
FinancingBeginNBV	,
FinancingIncome,
FinancingIncomeBalance,
FinancingEndNBV,
FinancingResidualIncome,
FinancingResidualIncomeBalance,
DeferredSellingProfitIncome	,
DeferredSellingProfitBalance,
LeaseIncomeScheduleId,
FinancingDepreciation,
BlendedIncomeScheduleId
)
SELECT
LeaseFinances.Id,
LeaseFinanceDetails.LeaseContractType,
0,
LeaseIncomeSchedule.LeaseModificationType,
'Arrear',
LeaseIncomeSchedule.IncomeType,
LeaseIncomeSchedule.IncomeType,
LeaseIncomeSchedule.IncomeDate,
LeaseIncomeSchedule.IsGLPosted,
LeaseIncomeSchedule.IsNonAccrual,
LeaseIncomeSchedule.BeginNetBookValue_Amount,
LeaseIncomeSchedule.Payment_Amount,
0.00,
0.00,
LeaseIncomeSchedule.IncomeBalance_Amount,
LeaseIncomeSchedule.EndNetBookValue_Amount,
0.00,
0.00,
0.00,
0.00,
0.00,
LeaseIncomeSchedule.ResidualIncomeBalance_Amount,
0,
LeaseIncomeSchedule.OperatingBeginNetBookValue_Amount,
LeaseIncomeSchedule.OperatingEndNetBookValue_Amount,
0.00,
ROW_NUMBER() OVER (PARTITION BY BlendedIncomeSchedule.IncomeDate,LeaseIncomeSchedule.Id ORDER BY LeaseIncomeSchedule.IncomeDate),
BlendedIncomeSchedule.Income_Amount,
BlendedIncomeSchedule.IncomeBalance_Amount,
BlendedIncomeSchedule.BlendedItemName,
CASE WHEN BlendedIncomeSchedule.Id IS NULL THEN 0 ELSE 1 END AS IsBlendedIncome,
LeaseFinanceDetails.IsFloatRateLease,
LeaseFinances.IsFutureFunding,
0.00,
0.00,
LeaseIncomeSchedule.FinanceBeginNetBookValue_Amount,
0.00,
LeaseIncomeSchedule.FinanceIncomeBalance_Amount,
LeaseIncomeSchedule.FinanceEndNetBookValue_Amount,
0.00,
LeaseIncomeSchedule.FinanceResidualIncomeBalance_Amount,
0.00,
LeaseIncomeSchedule.DeferredSellingProfitIncomeBalance_Amount,
LeaseIncomeSchedule.Id,
0.00,
BlendedIncomeSchedule.Id
FROM LeaseFinances 
INNER JOIN LeaseFinanceDetails 
	ON LeaseFinances.Id = LeaseFinanceDetails.Id
INNER JOIN #LeaseIncomeSchedulesTemp AS LeaseIncomeSchedule 
	ON LeaseFinances.Id = LeaseIncomeSchedule.LeaseFinanceId AND LeaseIncomeSchedule.AdjustmentEntry=0 
	AND LeaseIncomeSchedule.IncomeType IN ('OverTerm', 'Supplemental', 'FixedTerm', 'InterimInterest', 'InterimRent')
INNER JOIN #BlendedIncomeSchedulesTemp AS BlendedIncomeSchedule 
	ON LeaseFinances.ContractId = BlendedIncomeSchedule.ContractId 
	AND LeaseIncomeSchedule.IncomeDate = BlendedIncomeSchedule.IncomeDate 
INNER JOIN #BISAdjustmentEntriesIds 
	ON #BISAdjustmentEntriesIds.Id = BlendedIncomeSchedule.Id
WHERE LeaseFinances.ContractId = @ContractId
ORDER BY LeaseIncomeSchedule.IncomeDate

END

-- End of Blended Income Schedule Adjustment Entry Matching Non-Adjustment Entry Lease Income Schedule 

UPDATE #LeaseIncomeSchedule
SET
AdvanceOrArrear=NULL,
PaymentNumber=NULL,
StartDate=NULL,
IsNonAccrual=NULL,
IsGLPosted=NULL,
EndDate=NULL,
BeginNBV=NULL,
AccountingAmount=NULL,
PaymentAmount=NULL,
DisbursementAmount=NULL,
Income=NULL,
IncomeBalance=NULL,
EndNBV=NULL,
RentalIncome=NULL,
DeferredRentalIncome=NULL,
FinancingDeferredRentalIncome=NULL,
FinancingRentalIncome=NULL,
LeaseFloatRateIncome = NULL,
FinanceFloatRateIncome = NULL,
LeaseFloatRatePaymentAdjustment = NULL,
FinanceFloatRatePaymentAdjustment = NULL,
ResidualIncome=NULL,
ResidualIncomeBalance=NULL,
OperatingBeginNBV=NULL,
OperatingEndNBV=NULL,
Depreciation=NULL,
FinancingPaymentAmount= NULL,
FinancingAccountingAmount= NULL	,
FinancingBeginNBV= NULL	,
FinancingIncome= NULL,
FinancingIncomeBalance= NULL,
FinancingEndNBV= NULL,
FinancingResidualIncome= NULL,
FinancingResidualIncomeBalance= NULL,
DeferredSellingProfitIncome	= NULL,
DeferredSellingProfitBalance= NULL
WHERE
(IsBlendedIncome=1 AND ActualBlendedIncomePeriod <> 1)
---Adjustment Income Schedules End
-- Down Payment Amount Begin
--UPDATE #LeaseIncomeSchedule
--SET PaymentAmount=PaymentAmount+#DownPaymentSummary.DownPaymentAmount
--FROM #LeaseIncomeSchedule
--INNER JOIN #DownPaymentSummary ON #LeaseIncomeSchedule.LeaseFinanceId = #DownPaymentSummary.LeaseFinanceId
--AND #LeaseIncomeSchedule.IncomeDate = #DownPaymentSummary.CommencementDate
-- Down Payment Amount End
-- Guaranteed Residuals Begin

SET @PaymentCustomerGuaranteedResidual = @CustomerGuaranteedResidual
SET @PaymentThirdPartyGuaranteedResidual = @ThirdPartyGuaranteedResidual

IF EXISTS(SELECT * FROM #LeaseFinancesTemp WHERE AmendmentType = 'Renewal' and Id = @LeaseFinanceId)
SET @IsRenewal = 1
ELSE
SET @IsRenewal = 0

IF EXISTS(SELECT * FROM #LeaseIncomeSchedule WHERE IncomeDate=@MaturityDate AND LeaseFinanceId = @LeaseFinanceId)
(SELECT TOP 1 @IsNonAccrual=IsNonAccrual FROM #LeaseIncomeSchedule WHERE IncomeDate=@MaturityDate AND LeaseFinanceId = @LeaseFinanceId)
ELSE
SET @IsNonAccrual = 0

IF(@LeaseContractType <> 'Operating' AND @BookingStatus = 'Commenced')
BEGIN
DECLARE @EndNBV DECIMAL(16,2)=0.00
IF(@IsSyndicated=1)
BEGIN
DECLARE @RetainedPercentage DECIMAL(16,2)
DECLARE @ReceivableForTransferType NVARCHAR(18)
SELECT
@RetainedPercentage = RetainedPercentage, @ReceivableForTransferType=ReceivableForTransfers.ReceivableForTransferType
FROM
ReceivableForTransfers
WHERE
LeaseFinanceId = @LeaseFinanceId AND ApprovalStatus='Approved'
IF(@RetainedPercentage IS NOT NULL)
BEGIN
IF(@ReceivableForTransferType = 'FullSale')
BEGIN
SET @CustomerGuaranteedResidual=0.00
SET @ThirdPartyGuaranteedResidual=0.00
END
IF(@ReceivableForTransferType = 'ParticipatedSale')
BEGIN
SET @CustomerGuaranteedResidual = @CustomerGuaranteedResidual*@RetainedPercentage/100
SET @ThirdPartyGuaranteedResidual = @ThirdPartyGuaranteedResidual*@RetainedPercentage/100
END
END
END
END

DECLARE @IsFloatRateLease BIT=0
DECLARE @ShowIncomeColumns BIT = 0
DECLARE @IsFutureFunding BIT=0
IF((SELECT COUNT(*) FROM #LeaseIncomeSchedule WHERE IsFloatRateLease=1)>0)
SET @IsFloatRateLease = 1
ELSE
SET @IsFloatRateLease = 0

IF((SELECT COUNT(*) FROM #LeaseIncomeSchedule WHERE LeaseContractType<>'Operating' OR TYPE IN ('OverTerm','Supplemental'))>0)
SET @ShowIncomeColumns = 1
ELSE
SET @ShowIncomeColumns = 0

UPDATE #LeaseIncomeSchedule SET OrderNumber = 1 WHERE Type = 'InterimInterest'
UPDATE #LeaseIncomeSchedule SET OrderNumber = 2 WHERE Type = 'InterimRent'
UPDATE #LeaseIncomeSchedule SET OrderNumber = 3 WHERE Type = 'FixedTerm'
UPDATE #LeaseIncomeSchedule SET OrderNumber = 4 WHERE Type = 'CustomerGuaranteedResidual'
UPDATE #LeaseIncomeSchedule SET OrderNumber = 5 WHERE Type = 'ThirdPartyGuaranteedResidual'
UPDATE #LeaseIncomeSchedule SET OrderNumber = 6 WHERE Type = 'OverTerm'
UPDATE #LeaseIncomeSchedule SET OrderNumber = 7 WHERE Type = 'Supplemental'

UPDATE #LeaseIncomeSchedule
SET RentalIncome =0.00, DeferredRentalIncome=0.00, FinancingRentalIncome = 0.00, FinancingDeferredRentalIncome = 0.00
WHERE (Type<>'OverTerm' AND Type<>'Supplemental')
AND (LeaseContractType<>'Operating' AND Type<>'InterimRent')

UPDATE #LeaseIncomeSchedule
SET Income = 0.00,ResidualIncome=0.00,IncomeBalance=0.00,ResidualIncomeBalance=0.00,BeginNBV=0.00,EndNBV=0.00
WHERE LeaseContractType='Operating'

UPDATE #LeaseIncomeSchedule
SET OperatingBeginNBV=0.00,OperatingEndNBV=0.00
WHERE LeaseContractType<>'Operating'

SELECT SUM(Value_Amount) AS Depreciation, AssetValueHistories.AssetId INTO #AVHTemp FROM AssetValueHistories
JOIN LeaseAssets LA ON AssetValueHistories.AssetId = LA.AssetId
JOIN LeaseAssetSKUs LAS ON LA.Id = LAS.LeaseAssetId
WHERE AssetValueHistories.IsLeaseComponent=0 and LA.LeaseFinanceId=@LeaseFinanceId
AND AssetValueHistories.SourceModule in ('OTPDepreciation','ResidualRecapture')
AND AssetValueHistories.IsSchedule=1
AND AssetValueHistories.IsLessorOwned=1
GROUP BY AssetValueHistories.AssetId

INSERT INTO #FinancingDepreciation
SELECT
SUM(#AVHTemp.Depreciation) FinancingDepreciation,
SUM(assetincomeschedule.FinancePayment_Amount) FinancingPaymentAmount,
SUM(assetincomeschedule.FinanceBeginNetBookValue_Amount) FinancingBeginNBV,
SUM(assetincomeschedule.FinanceEndNetBookValue_Amount) FinancingEndNBV,
SUM(assetincomeschedule.FinanceIncome_Amount) FinancingIncome,
SUM(assetincomeschedule.FinanceIncomeBalance_Amount) FinancingIncomeBalance,
SUM(assetincomeschedule.OperatingBeginNetBookValue_Amount) FinancingOperatingBeginNBV,
SUM(assetincomeschedule.OperatingEndNetBookValue_Amount) FinancingOperatingEndNBV,
assetincomeschedule.LeaseIncomeScheduleId LeaseIncomeScheduleId
FROM AssetIncomeSchedules assetincomeschedule
JOIN LeaseAssets leaseasset ON assetincomeschedule.AssetId = leaseasset.AssetId
JOIN Assets on leaseasset.AssetId = Assets.Id
JOIN #AVHTemp on leaseasset.AssetId = #AVHTemp.AssetId 
WHERE assetincomeschedule.IsActive = 1 and Assets.IsSKU=1 and leaseasset.LeaseFinanceId=@LeaseFinanceId
GROUP BY assetincomeschedule.LeaseIncomeScheduleId
UNION
SELECT
SUM(assetincomeschedule.depreciation_amount) FinancingDepreciation,
SUM(assetincomeschedule.Payment_Amount) FinancingPaymentAmount,
SUM(assetincomeschedule.BeginNetBookValue_Amount) FinancingBeginNBV,
SUM(assetincomeschedule.EndNetBookValue_Amount) FinancingEndNBV,
SUM(assetincomeschedule.Income_Amount) FinancingIncome,
SUM(assetincomeschedule.IncomeBalance_Amount) FinancingIncomeBalance,
SUM(assetincomeschedule.OperatingBeginNetBookValue_Amount) FinancingOperatingBeginNBV,
SUM(assetincomeschedule.OperatingEndNetBookValue_Amount) FinancingOperatingEndNBV,
assetincomeschedule.LeaseIncomeScheduleId LeaseIncomeScheduleId
FROM AssetIncomeSchedules assetincomeschedule
JOIN LeaseAssets leaseasset ON assetincomeschedule.AssetId = leaseasset.AssetId
JOIN Assets ON leaseasset.AssetId = Assets.Id
WHERE assetincomeschedule.IsActive = 1 and Assets.IsSKU=0 and leaseasset.IsLeaseAsset=0  and leaseasset.LeaseFinanceId=@LeaseFinanceId
GROUP BY assetincomeschedule.LeaseIncomeScheduleId

SELECT
SUM(FinancingDepreciation) FinancingDepreciation,
SUM(FinancingPaymentAmount) FinancingPaymentAmount,
SUM(FinancingBeginNBV) FinancingBeginNBV,
SUM(FinancingEndNBV) FinancingEndNBV,
SUM(FinancingIncome) FinancingIncome,
SUM(FinancingIncomeBalance) FinancingIncomeBalance,
SUM(FinancingOperatingBeginNBV) FinancingOperatingBeginNBV,
SUM(FinancingOperatingEndNBV) FinancingOperatingEndNBV,
LeaseIncomeScheduleId
INTO #FinancingDepreciationTemp
FROM #FinancingDepreciation
GROUP BY LeaseIncomeScheduleId

UPDATE #LeaseIncomeSchedule
SET FinancingDepreciation = financingdepreciationtemp.FinancingDepreciation
,FinancingPaymentAmount = financingdepreciationtemp.FinancingPaymentAmount
,FinancingBeginNBV = financingdepreciationtemp.FinancingBeginNBV
,FinancingEndNBV = financingdepreciationtemp.FinancingEndNBV
,FinancingIncome = financingdepreciationtemp.FinancingIncome
,FinancingAccountingAmount = financingdepreciationtemp.FinancingPaymentAmount
,Depreciation = leaseincomeschedule.Depreciation - financingdepreciationtemp.FinancingDepreciation
,PaymentAmount = leaseincomeschedule.PaymentAmount - financingdepreciationtemp.FinancingPaymentAmount
,BeginNBV =leaseincomeschedule.BeginNBV - financingdepreciationtemp.FinancingBeginNBV
,EndNBV = leaseincomeschedule.EndNBV - financingdepreciationtemp.FinancingEndNBV
,OperatingBeginNBV =leaseincomeschedule.OperatingBeginNBV - financingdepreciationtemp.FinancingOperatingBeginNBV
,OperatingEndNBV = leaseincomeschedule.OperatingEndNBV - financingdepreciationtemp.FinancingOperatingEndNBV
,Income = leaseincomeschedule.Income - financingdepreciationtemp.FinancingIncome
,IncomeBalance = leaseincomeschedule.IncomeBalance - financingdepreciationtemp.FinancingIncomeBalance
,AccountingAmount = leaseincomeschedule.FinancingPaymentAmount - financingdepreciationtemp.FinancingPaymentAmount
FROM #LeaseIncomeSchedule leaseincomeschedule
JOIN #FinancingDepreciationTemp financingdepreciationtemp
ON leaseincomeschedule.LeaseIncomeScheduleId = financingdepreciationtemp.LeaseIncomeScheduleId
WHERE [Type] IN ('OverTerm','Supplemental')

SELECT
LeaseContractType,
PaymentNumber,
PaymentType,
IsRenewal,
StartDate,
EndDate,
PaymentAmount,
DisbursementAmount,
Type,
IncomeDate,
IsNonAccrual,
IsGLPosted,
AccountingAmount,
AdvanceOrArrear,
BeginNBV,
EndNBV,
Income,
IncomeBalance,
CASE WHEN (@DeferInterimRent = 'TRUE' AND Type = 'InterimRent') THEN 0 ELSE RentalIncome END RentalIncome,
DeferredRentalIncome,
FinancingDeferredRentalIncome,
FinancingRentalIncome,
ResidualIncome,
ResidualIncomeBalance,
ActualIncomePeriod,
ActualBlendedIncomePeriod,
BlendedIncome,
BlendedIncomeBalance,
BlendedItemName,
IsBlendedIncome,
OperatingBeginNBV,
OperatingEndNBV,
Depreciation,
LeaseFloatRateIncome,
FinanceFloatRateIncome,
LeaseFloatRatePaymentAdjustment,
FinanceFloatRatePaymentAdjustment,
FinancingPaymentAmount,
FinancingAccountingAmount	,
FinancingBeginNBV	,
FinancingIncome,
FinancingIncomeBalance,
FinancingEndNBV,
FinancingResidualIncome,
FinancingResidualIncomeBalance,
DeferredSellingProfitIncome	,
DeferredSellingProfitBalance,
@IsFloatRateLease AS IsFloatRateLease,
@ShowIncomeColumns AS ShowIncomeColumns,
@IsFutureFunding AS IsFutureFunding,
FinancingDepreciation
FROM
#LeaseIncomeSchedule
ORDER BY
IncomeDate,OrderNumber
END

GO

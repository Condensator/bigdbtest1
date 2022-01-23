SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[LeaseIncomeScheduleDataForPreviewReport]
(
@SequenceNumber NVARCHAR(40),
@IsAccounting BIT,
@IncomeScheduleDetails IncomeScheduleDataTable READONLY,
@BlendedIncomeScheduleDetails BlendedIncomeScheduleDataTable READONLY,
@LeaseContractTypeValue NVARCHAR(40),
@PayoffId BIGINT
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
--For while loop
DECLARE @CurrentPaymentNumber INT = 0
DECLARE @LastPaymentNumber INT = 0
DECLARE @RowNo INT = 0
DECLARE @Count INT = 0
--For while loop
-- Temporary Variables
SELECT @IsSyndicated = CASE WHEN Contracts.SyndicationType='None' THEN 0 ELSE 1 END
FROM Contracts WHERE SequenceNumber = @SequenceNumber
SELECT
LeaseFinances.Id
,ROW_NUMBER()OVER (ORDER BY LeaseFinances.Id) OrderNumber
,LeaseAmendments.AmendmentType
,0 AS GroupedOrder
INTO #LeaseFinancesTemp
FROM Contracts
JOIN LeaseFinances ON Contracts.Id = LeaseFinances.ContractId
LEFT JOIN LeaseAmendments ON LeaseFinances.Id = LeaseAmendments.CurrentLeaseFinanceId
AND LeaseAmendments.CurrentLeaseFinanceId <> LeaseAmendments.OriginalLeaseFinanceId
AND LeaseAmendments.AmendmentType NOT IN ('NonAccrual','ReAccrual','Syndication','Assumption')
AND LeaseAmendments.LeaseAmendmentStatus = 'Approved'
WHERE Contracts.SequenceNumber = @SequenceNumber
ORDER BY LeaseFinances.Id
SELECT
LeaseInvestmentTrackings.InvestmentDate,
SUM(LeaseInvestmentTrackings.Investment) Investment,
LeaseInvestmentTrackings.LeaseFinanceId
INTO #InvestmentSummary
FROM
Contracts
INNER JOIN LeaseFinances ON Contracts.Id = LeaseFinances.ContractId
INNER JOIN LeaseInvestmentTrackings ON LeaseFinances.Id = LeaseInvestmentTrackings.LeaseFinanceId AND IsActive=1
WHERE Contracts.SequenceNumber = @SequenceNumber
GROUP BY
LeaseInvestmentTrackings.InvestmentDate,
LeaseInvestmentTrackings.LeaseFinanceId
SELECT
LeasePaymentSchedules.Amount_Amount AS DownPaymentAmount,
LeaseFinances.Id AS LeaseFinanceId,
LeaseFinanceDetails.CommencementDate
INTO #DownPaymentSummary
FROM
Contracts
INNER JOIN LeaseFinances ON Contracts.Id = LeaseFinances.ContractId
INNER JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
INNER JOIN LeasePaymentSchedules ON LeaseFinanceDetails.Id = LeasePaymentSchedules.LeaseFinanceDetailId
WHERE Contracts.SequenceNumber = @SequenceNumber
AND LeasePaymentSchedules.IsActive=1
AND LeasePaymentSchedules.PaymentType='DownPayment'
AND LeasePaymentSchedules.Amount_Amount <> 0
SELECT DISTINCT BlendedIncomeSchedules.*,BlendedItems.Name AS BlendedItemName, CASE WHEN BlendedItems.BookRecognitionMode = 'Amortize' THEN 1 ELSE 0 END AS IsAmortize,Contracts.Id AS ContractId
INTO #BlendedIncomeSchedulesTemp
FROM Contracts
INNER JOIN LeaseFinances ON Contracts.Id = LeaseFinances.ContractId
INNER JOIN LeaseBlendedItems ON LeaseFinances.Id = LeaseBlendedItems.LeaseFinanceId
INNER JOIN  BlendedItems ON LeaseBlendedItems.BlendedItemId = BlendedItems.Id
INNER JOIN @BlendedIncomeScheduleDetails BlendedIncomeSchedules ON BlendedItems.Id = BlendedIncomeSchedules.BlendedItemId
WHERE Contracts.SequenceNumber = @SequenceNumber
AND ((@IsAccounting = 1 AND BlendedIncomeSchedules.IsAccounting=@IsAccounting)
OR (@IsAccounting = 0 AND BlendedIncomeSchedules.IsSchedule = 1))
SELECT	ROW_NUMBER() OVER (PARTITION BY LeaseIncomeSchedules.AdjustmentEntry ORDER BY IncomeDate) AS RowNumber
,LeaseIncomeSchedules.*
,Contracts.Id AS ContractId
INTO #LeaseIncomeSchedulesTemp
FROM Contracts
INNER JOIN LeaseFinances ON Contracts.Id = LeaseFinances.ContractId
INNER JOIN @IncomeScheduleDetails LeaseIncomeSchedules ON LeaseFinances.Id = LeaseIncomeSchedules.LeaseFinanceId
WHERE Contracts.SequenceNumber = @SequenceNumber
AND  ((@IsAccounting = 1 AND LeaseIncomeSchedules.IsAccounting = @IsAccounting)
OR (@IsAccounting = 0 AND @IsSyndicated=0 AND LeaseIncomeSchedules.IsSchedule = 1)
OR (@IsAccounting = 0 AND @IsSyndicated=1 AND LeaseIncomeSchedules.IsSchedule = 1 AND LeaseIncomeSchedules.IsLessorOwned = 0)
)
--SELECT
--	SUM(LeaseFloatRateIncomes.CustomerIncomeAmount_Amount) CustomerIncomeAmount_Amount,
--	Contracts.Id AS ContractId,
--	#LeaseIncomeSchedulesTemp.Id LeaseIncomeScheduleId
--INTO #FloatRateIncomesTemp
--FROM Contracts
--INNER JOIN LeaseFinances ON Contracts.Id = LeaseFinances.ContractId
--INNER JOIN #LeaseIncomeSchedulesTemp ON Contracts.Id = #LeaseIncomeSchedulesTemp.ContractId AND AdjustmentEntry=0
--LEFT JOIN #LeaseIncomeSchedulesTemp AS PreviousLeaseIncomeSchedule ON PreviousLeaseIncomeSchedule.RowNumber = #LeaseIncomeSchedulesTemp.RowNumber - 1 AND PreviousLeaseIncomeSchedule.AdjustmentEntry=0
--INNER JOIN LeaseFloatRateIncomes ON LeaseFinances.Id = LeaseFloatRateIncomes.LeaseFinanceId AND #LeaseIncomeSchedulesTemp.IncomeDate >= LeaseFloatRateIncomes.IncomeDate AND LeaseFloatRateIncomes.AdjustmentEntry=0
--			AND (PreviousLeaseIncomeSchedule.IncomeDate = NULL OR PreviousLeaseIncomeSchedule.IncomeDate < LeaseFloatRateIncomes.IncomeDate)
--			AND ((@IsAccounting = 1 AND LeaseFloatRateIncomes.IsAccounting = @IsAccounting) OR (@IsAccounting = 0 AND LeaseFloatRateIncomes.IsScheduled = 1))
--WHERE Contracts.SequenceNumber = @SequenceNumber
--GROUP BY Contracts.Id,#LeaseIncomeSchedulesTemp.Id
--SELECT
--	SUM(LeaseFloatRateIncomes.CustomerIncomeAmount_Amount) CustomerIncomeAmount_Amount,
--	Contracts.Id AS ContractId,
--	#LeaseIncomeSchedulesTemp.Id LeaseIncomeScheduleId
--INTO #AdjustmentFloatRateIncomesTemp
--FROM Contracts
--INNER JOIN LeaseFinances ON Contracts.Id = LeaseFinances.ContractId
--INNER JOIN #LeaseIncomeSchedulesTemp ON Contracts.Id = #LeaseIncomeSchedulesTemp.ContractId AND AdjustmentEntry=1
--LEFT JOIN #LeaseIncomeSchedulesTemp AS PreviousLeaseIncomeSchedule ON PreviousLeaseIncomeSchedule.RowNumber = #LeaseIncomeSchedulesTemp.RowNumber - 1 AND PreviousLeaseIncomeSchedule.AdjustmentEntry=1
--INNER JOIN LeaseFloatRateIncomes ON LeaseFinances.Id = LeaseFloatRateIncomes.LeaseFinanceId AND #LeaseIncomeSchedulesTemp.IncomeDate >= LeaseFloatRateIncomes.IncomeDate AND LeaseFloatRateIncomes.AdjustmentEntry=1
--			AND (PreviousLeaseIncomeSchedule.IncomeDate = NULL OR PreviousLeaseIncomeSchedule.IncomeDate < LeaseFloatRateIncomes.IncomeDate)
--			AND ((@IsAccounting = 1 AND LeaseFloatRateIncomes.IsAccounting = @IsAccounting) OR (@IsAccounting = 0 AND LeaseFloatRateIncomes.IsScheduled = 1))
--WHERE Contracts.SequenceNumber = @SequenceNumber
--GROUP BY Contracts.Id,#LeaseIncomeSchedulesTemp.Id
SELECT
Payoffs.Id AS PayoffId,
LeaseFinances.Id AS LeaseFinanceId,
Payoffs.PayoffEffectiveDate AS PayoffDate,
SUM(LeaseAssets.Rent_Amount) AS Rent
INTO #PayoffTemp
FROM Payoffs
INNER JOIN LeaseFinances ON Payoffs.LeaseFinanceId = LeaseFinances.Id
INNER JOIN PayoffAssets ON Payoffs.Id = PayoffAssets.PayoffId
INNER JOIN LeaseAssets ON PayoffAssets.LeaseAssetId = LeaseAssets.Id
WHERE Payoffs.Id = @PayoffId
AND PayoffAssets.SubStatus <> 'Placeholder'
GROUP BY Payoffs.Id,LeaseFinances.Id,Payoffs.PayoffEffectiveDate
SELECT
Payoffs.Id AS PayoffId,
LeaseFinances.Id AS LeaseFinanceId,
SUM(LeaseAssets.CustomerGuaranteedResidual_Amount) AS CustomerGuaranteedResidual,
SUM(LeaseAssets.ThirdPartyGuaranteedResidual_Amount) AS ThirdPartyGuaranteedResidual
INTO #PayoffResidualsTemp
FROM Payoffs
INNER JOIN LeaseFinances ON Payoffs.LeaseFinanceId = LeaseFinances.Id
INNER JOIN PayoffAssets ON Payoffs.Id = PayoffAssets.PayoffId
INNER JOIN LeaseAssets ON PayoffAssets.LeaseAssetId = LeaseAssets.Id
WHERE Payoffs.Id = @PayoffId
GROUP BY Payoffs.Id,LeaseFinances.Id
SELECT
CASE WHEN PaymentType='_' THEN 'FixedTerm' ELSE PaymentType END AS PaymentType
,LeasePaymentSchedules.Id
,LeasePaymentSchedules.PaymentNumber
,LeasePaymentSchedules.StartDate
,LeasePaymentSchedules.EndDate
,LeasePaymentSchedules.LeaseFinanceDetailId
,LeasePaymentSchedules.IsActive
,LeasePaymentSchedules.Amount_Amount - (CASE WHEN LeasePaymentSchedules.EndDate > PayoffDetails.PayoffDate THEN PayoffDetails.Rent ELSE 0.00 END) AS Amount_Amount
,LeasePaymentSchedules.Disbursement_Amount
,LeasePaymentSchedules.IsRenewal
,Contracts.Id AS ContractId
INTO #LeasePaymentSchedulesTemp
FROM Contracts
INNER JOIN LeaseFinances ON Contracts.Id = LeaseFinances.ContractId
INNER JOIN LeasePaymentSchedules ON LeaseFinances.Id = LeasePaymentSchedules.LeaseFinanceDetailId AND IsActive=1
LEFT JOIN #PayoffTemp PayoffDetails on PayoffDetails.LeaseFinanceId = LeaseFinances.Id
WHERE Contracts.SequenceNumber = @SequenceNumber
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
FloatRateIncome DECIMAL(16,2),
IsFloatRateLease BIT,
IsFutureFunding BIT,
PaymentGroupNumber BIGINT,
BlendedItemPaymentGroupNumber BIGINT,
BlendedItemId BIGINT,
IsPaymentEndDate BIT,
IsAmortize BIT
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
ResidualIncome,
ResidualIncomeBalance,
ActualIncomePeriod,
ActualBlendedIncomePeriod,
IsBlendedIncome,
OperatingBeginNBV,
OperatingEndNBV,
Depreciation,
RowNumber,
IsFutureFunding
)
SELECT
LeaseFinances.Id,
LeaseIncomeSchedule.LeaseContractType,
0,
LeaseIncomeSchedule.LeaseModificationType,
'Arrear',
LeaseIncomeSchedule.IncomeType,
LeaseIncomeSchedule.IncomeType,
LeaseIncomeSchedule.IncomeDate,
LeaseIncomeSchedule.IsGLPosted,
LeaseIncomeSchedule.IsNonAccrual,
LeaseIncomeSchedule.BeginNBV,
LeaseIncomeSchedule.AccountingAmount,
LeaseIncomeSchedule.PaymentAmount,
LeaseIncomeSchedule.Income,
LeaseIncomeSchedule.IncomeBalance,
LeaseIncomeSchedule.EndNBV,
LeaseIncomeSchedule.RentalIncome,
LeaseIncomeSchedule.DeferredRentalIncome,
LeaseIncomeSchedule.ResidualIncome,
LeaseIncomeSchedule.ResidualIncomeBalance,
CASE WHEN PaymentAmount <> 0 THEN 1 ELSE 0 END,
0,
0,
LeaseIncomeSchedule.OperatingBeginNBV,
LeaseIncomeSchedule.OperatingEndNBV,
LeaseIncomeSchedule.Depreciation,
ROW_NUMBER()OVER (PARTITION BY LeaseIncomeSchedule.IncomeType ORDER BY LeaseIncomeSchedule.IncomeDate),
LeaseFinances.IsFutureFunding
FROM Contracts
INNER JOIN LeaseFinances ON Contracts.Id = LeaseFinances.ContractId
INNER JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
INNER JOIN #LeaseIncomeSchedulesTemp AS LeaseIncomeSchedule ON LeaseFinances.Id = LeaseIncomeSchedule.LeaseFinanceId
WHERE Contracts.SequenceNumber = @SequenceNumber
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
FloatRateIncome,
IsFloatRateLease,
IsFutureFunding,
PaymentGroupNumber,
BlendedItemPaymentGroupNumber,
BlendedItemId,
IsPaymentEndDate,
IsAmortize,
RowNumber
)
SELECT
LeaseFinances.Id,
LeaseIncomeSchedule.LeaseContractType,
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
SUM(LeaseIncomeSchedule.BeginNBV),
SUM(LeaseIncomeSchedule.AccountingAmount),
SUM(LeasePaymentSchedule.Amount_Amount),
CASE WHEN LeaseFinances.IsFutureFunding=1 AND LeaseFinanceDetails.CommencementDate = LeaseIncomeSchedule.IncomeDate THEN SUM(LeaseIncomeSchedule.BeginNBV) ELSE 0 END AS DisbursementAmount,
SUM(LeaseIncomeSchedule.Income),
SUM(LeaseIncomeSchedule.IncomeBalance),
SUM(LeaseIncomeSchedule.EndNBV),
SUM(LeaseIncomeSchedule.RentalIncome),
SUM(LeaseIncomeSchedule.DeferredRentalIncome),
SUM(LeaseIncomeSchedule.ResidualIncome),
SUM(LeaseIncomeSchedule.ResidualIncomeBalance),
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
ROW_NUMBER() OVER (PARTITION BY BlendedIncomeSchedule.IncomeDate,LeasePaymentSchedule.PaymentType,LeaseIncomeSchedule.IncomeDate ORDER BY LeaseIncomeSchedule.IncomeDate, LeasePaymentSchedule.PaymentType),
SUM(ISNULL(BlendedIncomeSchedule.Income,0)),
SUM(ISNULL(BlendedIncomeSchedule.IncomeBalance,0)),
BlendedIncomeSchedule.BlendedItemName,
CASE WHEN BlendedIncomeSchedule.IncomeDate IS NULL
THEN 0
ELSE 1
END AS IsBlendedIncome,
SUM(LeaseIncomeSchedule.OperatingBeginNBV),
SUM(LeaseIncomeSchedule.OperatingEndNBV),
SUM(LeaseIncomeSchedule.Depreciation),
--SUM(ISNULL(#FloatRateIncomesTemp.CustomerIncomeAmount_Amount,0)) FloatRateIncome,
0 FloatRateIncome,
LeaseFinanceDetails.IsFloatRateLease,
LeaseFinances.IsFutureFunding,
DENSE_RANK() OVER (ORDER BY LeasePaymentSchedule.StartDate,LeasePaymentSchedule.EndDate),
DENSE_RANK() OVER (ORDER BY LeasePaymentSchedule.StartDate,LeasePaymentSchedule.EndDate),
BlendedIncomeSchedule.BlendedItemId,
CASE WHEN LeaseIncomeSchedule.IncomeDate = LeasePaymentSchedule.EndDate THEN 1 ELSE 0 END,
BlendedIncomeSchedule.IsAmortize,
ROW_NUMBER() OVER (ORDER BY LeaseIncomeSchedule.IncomeDate)
FROM
Contracts AS Contract
INNER JOIN
LeaseFinances ON Contract.Id = LeaseFinances.ContractId
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
LEFT JOIN #BlendedIncomeSchedulesTemp AS BlendedIncomeSchedule ON Contract.Id = BlendedIncomeSchedule.ContractId AND LeaseIncomeSchedule.IncomeDate = BlendedIncomeSchedule.IncomeDate AND BlendedIncomeSchedule.AdjustmentEntry=0
--LEFT JOIN #FloatRateIncomesTemp ON LeaseIncomeSchedule.IncomeDate = #FloatRateIncomesTemp.LeaseIncomeScheduleId
WHERE
Contract.SequenceNumber=@SequenceNumber
GROUP BY
Contract.Id,
LeaseFinances.IsFutureFunding,
LeaseFinances.Id,
LeaseFinanceDetails.CommencementDate,
LeaseIncomeSchedule.LeaseContractType,
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
BlendedIncomeSchedule.Income,
BlendedIncomeSchedule.IncomeBalance,
BlendedIncomeSchedule.IncomeDate,
--BlendedIncomeSchedule.Id,
BlendedIncomeSchedule.BlendedItemId,
BlendedIncomeSchedule.BlendedItemName,
BlendedIncomeSchedule.IsAmortize,
LeaseIncomeSchedule.IncomeDate
ORDER BY LeaseIncomeSchedule.IncomeDate,LeasePaymentSchedule.PaymentType
UPDATE #LeaseIncomeSchedule
SET DisbursementAmount = #InvestmentSummary.Investment
FROM #LeaseIncomeSchedule
JOIN #InvestmentSummary ON #LeaseIncomeSchedule.LeaseFinanceId = #InvestmentSummary.LeaseFinanceId AND #LeaseIncomeSchedule.IncomeDate = #InvestmentSummary.InvestmentDate
UPDATE #LeaseIncomeSchedule SET PaymentAmount=0.00 WHERE ActualIncomePeriod <> 1
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
FloatRateIncome = NULL,
ResidualIncome=NULL,
ResidualIncomeBalance=NULL,
OperatingBeginNBV=NULL,
OperatingEndNBV=NULL,
Depreciation=NULL,
PaymentGroupNumber = NULL
WHERE
(IsBlendedIncome=1 AND ActualBlendedIncomePeriod <> 1)
--Populate Income Balance columns Begin
;WITH CTE_LeaseIncome
AS(
SELECT #LeaseIncomeSchedule.RowNumber,SUM(PreviousIncomes.Income)  Income,SUM(PreviousIncomes.ResidualIncome) ResidualIncome
FROM #LeaseIncomeSchedule
INNER JOIN #LeaseIncomeSchedule AS PreviousIncomes
ON #LeaseIncomeSchedule.PaymentGroupNumber = PreviousIncomes.PaymentGroupNumber
AND PreviousIncomes.IsPaymentEndDate=0 AND #LeaseIncomeSchedule.IncomeDate >= PreviousIncomes.IncomeDate
WHERE #LeaseIncomeSchedule.IsPaymentEndDate=0 AND #LeaseIncomeSchedule.PaymentGroupNumber IS NOT NULL
GROUP BY #LeaseIncomeSchedule.IncomeDate,#LeaseIncomeSchedule.PaymentGroupNumber,#LeaseIncomeSchedule.RowNumber
)
UPDATE #LeaseIncomeSchedule
SET IncomeBalance = IncomeBalance - CTE_LeaseIncome.Income,
ResidualIncomeBalance = ResidualIncomeBalance + CTE_LeaseIncome.ResidualIncome
FROM #LeaseIncomeSchedule
INNER JOIN CTE_LeaseIncome ON #LeaseIncomeSchedule.RowNumber = CTE_LeaseIncome.RowNumber
WHERE #LeaseIncomeSchedule.PaymentGroupNumber IS NOT NULL
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
SELECT LeaseIncomeSchedules.IncomeDate,LeaseIncomeSchedules.Payment_Amount
INTO #NonAccrualIncomeSchedules
FROM Contracts
INNER JOIN LeaseFinances ON Contracts.Id = LeaseFinances.ContractId
INNER JOIN LeaseIncomeSchedules ON LeaseFinances.Id = LeaseIncomeSchedules.LeaseFinanceId
WHERE Contracts.SequenceNumber = @SequenceNumber
AND LeaseIncomeSchedules.IsSchedule=0 AND LeaseIncomeSchedules.IsAccounting=1 AND LeaseIncomeSchedules.IsNonAccrual=1
;WITH CTE_ActualIncomeSchedules
AS
(
SELECT ROW_NUMBER() OVER (ORDER BY IncomeDate) AS RowNumber,IncomeDate FROM #LeaseIncomeSchedulesTemp WHERE AdjustmentEntry = 0
)
SELECT CTE_ActualIncomeSchedules.IncomeDate,SUM(#NonAccrualIncomeSchedules.Payment_Amount) AS PaymentAmount
INTO #NonAccrualAmountSummary
FROM
CTE_ActualIncomeSchedules
LEFT JOIN CTE_ActualIncomeSchedules AS PreviousIncomeSchedule ON CTE_ActualIncomeSchedules.RowNumber - 1 = PreviousIncomeSchedule.RowNumber
INNER JOIN #NonAccrualIncomeSchedules ON (PreviousIncomeSchedule.IncomeDate = NULL OR PreviousIncomeSchedule.IncomeDate <= #NonAccrualIncomeSchedules.IncomeDate) AND CTE_ActualIncomeSchedules.IncomeDate >= #NonAccrualIncomeSchedules.IncomeDate
GROUP BY CTE_ActualIncomeSchedules.IncomeDate
UPDATE #LeaseIncomeSchedule
SET PaymentAmount = #LeaseIncomeSchedule.PaymentAmount + #NonAccrualAmountSummary.PaymentAmount,
AccountingAmount = #LeaseIncomeSchedule.AccountingAmount + #NonAccrualAmountSummary.PaymentAmount
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
ResidualIncome,
ResidualIncomeBalance,
ActualIncomePeriod,
ActualBlendedIncomePeriod,
IsBlendedIncome,
OperatingBeginNBV,
OperatingEndNBV,
Depreciation,
IsFutureFunding
)
SELECT
LeaseFinances.Id,
LeaseIncomeSchedule.LeaseContractType,
0,
LeaseIncomeSchedule.LeaseModificationType,
'Arrear',
LeaseIncomeSchedule.IncomeType,
LeaseIncomeSchedule.IncomeType,
LeaseIncomeSchedule.IncomeDate,
LeaseIncomeSchedule.IsGLPosted,
LeaseIncomeSchedule.IsNonAccrual,
LeaseIncomeSchedule.BeginNBV,
LeaseIncomeSchedule.AccountingAmount,
0.00,
LeaseIncomeSchedule.Income,
LeaseIncomeSchedule.IncomeBalance,
LeaseIncomeSchedule.EndNBV,
LeaseIncomeSchedule.RentalIncome,
LeaseIncomeSchedule.DeferredRentalIncome,
LeaseIncomeSchedule.ResidualIncome,
LeaseIncomeSchedule.ResidualIncomeBalance,
0,
0,
0,
LeaseIncomeSchedule.OperatingBeginNBV,
LeaseIncomeSchedule.OperatingEndNBV,
LeaseIncomeSchedule.Depreciation,
LeaseFinances.IsFutureFunding
FROM Contracts
INNER JOIN LeaseFinances ON Contracts.Id = LeaseFinances.ContractId
INNER JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
INNER JOIN #LeaseIncomeSchedulesTemp AS LeaseIncomeSchedule ON LeaseFinances.Id = LeaseIncomeSchedule.LeaseFinanceId
AND LeaseFinanceDetails.TerminationNoticeEffectiveDate IS NOT NULL
AND LeaseFinanceDetails.TerminationNoticeEffectiveDate < LeaseIncomeSchedule.IncomeDate
AND CAST(DATEADD(MM,LeaseFinanceDetails.SupplementalGracePeriod,LeaseFinanceDetails.TerminationNoticeEffectiveDate) AS DATE) >= LeaseIncomeSchedule.IncomeDate
WHERE Contracts.SequenceNumber = @SequenceNumber
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
FloatRateIncome,
IsFloatRateLease,
IsFutureFunding
)
SELECT
LeaseFinances.Id,
LeaseIncomeSchedule.LeaseContractType,
0,
LeaseIncomeSchedule.LeaseModificationType,
'Arrear',
LeaseIncomeSchedule.IncomeType,
LeaseIncomeSchedule.IncomeType,
LeaseIncomeSchedule.IncomeDate,
LeaseIncomeSchedule.IsGLPosted,
LeaseIncomeSchedule.IsNonAccrual,
LeaseIncomeSchedule.BeginNBV,
LeaseIncomeSchedule.AccountingAmount,
0.00,
LeaseIncomeSchedule.Income,
LeaseIncomeSchedule.IncomeBalance,
LeaseIncomeSchedule.EndNBV,
LeaseIncomeSchedule.RentalIncome,
LeaseIncomeSchedule.DeferredRentalIncome,
LeaseIncomeSchedule.ResidualIncome,
LeaseIncomeSchedule.ResidualIncomeBalance,
0,
LeaseIncomeSchedule.OperatingBeginNBV,
LeaseIncomeSchedule.OperatingEndNBV,
LeaseIncomeSchedule.Depreciation,
ROW_NUMBER() OVER (PARTITION BY BlendedIncomeSchedule.IncomeDate,LeaseIncomeSchedule.IncomeDate ORDER BY LeaseIncomeSchedule.IncomeDate),
BlendedIncomeSchedule.Income,
BlendedIncomeSchedule.IncomeBalance,
BlendedIncomeSchedule.BlendedItemName,
CASE WHEN BlendedIncomeSchedule.IncomeDate IS NULL
THEN 0
ELSE 1
END AS IsBlendedIncome,
--#AdjustmentFloatRateIncomesTemp.CustomerIncomeAmount_Amount FloatRateIncome,
0 FloatRateIncome,
LeaseFinanceDetails.IsFloatRateLease,
LeaseFinances.IsFutureFunding
FROM Contracts
INNER JOIN LeaseFinances ON Contracts.Id = LeaseFinances.ContractId
INNER JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
INNER JOIN #LeaseIncomeSchedulesTemp AS LeaseIncomeSchedule ON LeaseFinances.Id = LeaseIncomeSchedule.LeaseFinanceId AND LeaseIncomeSchedule.AdjustmentEntry=1
LEFT JOIN #BlendedIncomeSchedulesTemp AS BlendedIncomeSchedule ON Contracts.Id = BlendedIncomeSchedule.ContractId AND LeaseIncomeSchedule.IncomeDate = BlendedIncomeSchedule.IncomeDate AND BlendedIncomeSchedule.AdjustmentEntry=1 AND LeaseIncomeSchedule.IsNonAccrual = BlendedIncomeSchedule.IsNonAccrual
--LEFT JOIN #AdjustmentFloatRateIncomesTemp ON LeaseIncomeSchedule.Id = #AdjustmentFloatRateIncomesTemp.LeaseIncomeScheduleId
WHERE Contracts.SequenceNumber = @SequenceNumber
ORDER BY LeaseIncomeSchedule.IncomeDate
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
FloatRateIncome = NULL,
ResidualIncome=NULL,
ResidualIncomeBalance=NULL,
OperatingBeginNBV=NULL,
OperatingEndNBV=NULL,
Depreciation=NULL
WHERE
(IsBlendedIncome=1 AND ActualBlendedIncomePeriod <> 1)
---Adjustment Income Schedules End
-- Down Payment Amount Begin
UPDATE #LeaseIncomeSchedule
SET PaymentAmount=PaymentAmount+#DownPaymentSummary.DownPaymentAmount
FROM #LeaseIncomeSchedule
INNER JOIN #DownPaymentSummary ON #LeaseIncomeSchedule.LeaseFinanceId = #DownPaymentSummary.LeaseFinanceId
AND #LeaseIncomeSchedule.IncomeDate = #DownPaymentSummary.CommencementDate
-- Down Payment Amount End
-- Guaranteed Residuals Begin
SELECT
@LeaseFinanceId = LeaseFinances.Id,
@BookingStatus = LeaseFinances.BookingStatus,
@CustomerGuaranteedResidual = SUM(LeaseAssets.CustomerGuaranteedResidual_Amount) - (PayoffDetails.CustomerGuaranteedResidual),
@ThirdPartyGuaranteedResidual = SUM(LeaseAssets.ThirdPartyGuaranteedResidual_Amount) - (PayoffDetails.ThirdPartyGuaranteedResidual),
@CommencementDate=LeaseFinanceDetails.CommencementDate,
@MaturityDate=LeaseFinanceDetails.MaturityDate,
@LeaseContractType= @LeaseContractTypeValue,
@AdvanceOrArrear = CASE WHEN LeaseFinanceDetails.IsAdvance=1 THEN 'Advance' ELSE 'Arrear' END
FROM
Contracts
INNER JOIN LeaseFinances ON Contracts.Id = LeaseFinances.ContractId AND LeaseFinances.IsCurrent=1
INNER JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
LEFT JOIN LeaseAssets ON LeaseFinances.Id = LeaseAssets.LeaseFinanceId AND LeaseAssets.IsActive = 1
LEFT JOIN #PayoffResidualsTemp PayoffDetails on PayoffDetails.LeaseFinanceId = LeaseFinanceDetails.Id
WHERE
Contracts.SequenceNumber = @SequenceNumber
GROUP BY
LeaseFinances.Id,
LeaseFinances.BookingStatus,
LeaseFinanceDetails.CommencementDate,
LeaseFinanceDetails.MaturityDate,
LeaseFinanceDetails.LeaseContractType,
LeaseFinanceDetails.IsAdvance,
PayoffDetails.CustomerGuaranteedResidual,
PayoffDetails.ThirdPartyGuaranteedResidual
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
IF(@LeaseContractType <> 'Operating')
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
SET @EndNBV = @CustomerGuaranteedResidual+@ThirdPartyGuaranteedResidual+(SELECT TOP 1 EndNBV FROM #LeaseIncomeSchedule
WHERE IncomeDate=@MaturityDate AND PaymentType='FixedTerm' AND LeaseContractType=@LeaseContractType AND LeaseFinanceId = @LeaseFinanceId)
IF(@CustomerGuaranteedResidual <> 0)
BEGIN
UPDATE #LeaseIncomeSchedule
SET AccountingAmount = AccountingAmount- @PaymentCustomerGuaranteedResidual,
EndNBV = EndNBV + @CustomerGuaranteedResidual
WHERE IncomeDate=@MaturityDate AND PaymentType='FixedTerm' AND LeaseContractType=@LeaseContractType AND LeaseFinanceId = @LeaseFinanceId
INSERT INTO #LeaseIncomeSchedule
(
LeaseContractType,
IsRenewal,
AdvanceOrArrear,
PaymentNumber,
PaymentType,
StartDate,
EndDate,
Type,
IncomeDate,
IsGLPosted,
IsNonAccrual,
AccountingAmount,
PaymentAmount,
ActualIncomePeriod,
ActualBlendedIncomePeriod,
IsBlendedIncome,
Income,
IncomeBalance,
BeginNBV,
EndNBV,
ResidualIncome,
ResidualIncomeBalance,
RentalIncome,
DeferredRentalIncome,
LeaseFinanceId
)
VALUES
(
@LeaseContractType,
@IsRenewal,
@AdvanceOrArrear,
1,
'CustomerGuaranteedResidual',
@MaturityDate,
@MaturityDate,
'CustomerGuaranteedResidual',
@MaturityDate,
0,
@IsNonAccrual,
@CustomerGuaranteedResidual,
@PaymentCustomerGuaranteedResidual,
1,
0,
0,
0.00,
0.00,
@EndNBV,
@EndNBV-@CustomerGuaranteedResidual,
0.00,
0.00,
0.00,
0.00,
@LeaseFinanceId
)
END
SET @EndNBV = @EndNBV - @CustomerGuaranteedResidual
IF(@ThirdPartyGuaranteedResidual <> 0)
BEGIN
UPDATE #LeaseIncomeSchedule
SET AccountingAmount = AccountingAmount- @PaymentThirdPartyGuaranteedResidual,
EndNBV = EndNBV + @ThirdPartyGuaranteedResidual
WHERE IncomeDate=@MaturityDate AND PaymentType='FixedTerm' AND LeaseContractType=@LeaseContractType AND LeaseFinanceId = @LeaseFinanceId
INSERT INTO #LeaseIncomeSchedule
(
LeaseContractType,
IsRenewal,
AdvanceOrArrear,
PaymentNumber,
PaymentType,
StartDate,
EndDate,
Type,
IncomeDate,
IsGLPosted,
IsNonAccrual,
AccountingAmount,
PaymentAmount,
ActualIncomePeriod,
ActualBlendedIncomePeriod,
IsBlendedIncome,
Income,
IncomeBalance,
BeginNBV,
EndNBV,
ResidualIncome,
ResidualIncomeBalance,
RentalIncome,
DeferredRentalIncome,
LeaseFinanceId
)
VALUES
(
@LeaseContractType,
@IsRenewal,
@AdvanceOrArrear,
1,
'ThirdPartyGuaranteedResidual',
@MaturityDate,
@MaturityDate,
'ThirdPartyGuaranteedResidual',
@MaturityDate,
0,
@IsNonAccrual,
@ThirdPartyGuaranteedResidual,
@PaymentThirdPartyGuaranteedResidual,
1,
0,
0,
0.00,
0.00,
@EndNBV,
@EndNBV-@ThirdPartyGuaranteedResidual,
0.00,
0.00,
0.00,
0.00,
@LeaseFinanceId
)
END
END
-- Guaranteed Residuals End
DECLARE @IsFloatRateLease INT=0
DECLARE @ShowIncomeColumns INT = 1
DECLARE @IsFutureFunding INT=0
IF((SELECT COUNT(*) FROM #LeaseIncomeSchedule WHERE IsFloatRateLease=1)>0)
SET @IsFloatRateLease = 1
ELSE
SET @IsFloatRateLease = 0
IF((SELECT COUNT(*) FROM #LeaseIncomeSchedule WHERE LeaseContractType<>'Operating')>0)
SET @ShowIncomeColumns = 1
ELSE
SET @ShowIncomeColumns = 0
IF((SELECT COUNT(*) FROM #LeaseIncomeSchedule WHERE IsFutureFunding=1)>0)
SET @IsFutureFunding = 1
ELSE
SET @IsFutureFunding = 0
UPDATE #LeaseIncomeSchedule SET OrderNumber = 1 WHERE Type = 'InterimInterest'
UPDATE #LeaseIncomeSchedule SET OrderNumber = 2 WHERE Type = 'InterimRent'
UPDATE #LeaseIncomeSchedule SET OrderNumber = 3 WHERE Type = 'FixedTerm'
UPDATE #LeaseIncomeSchedule SET OrderNumber = 4 WHERE Type = 'CustomerGuaranteedResidual'
UPDATE #LeaseIncomeSchedule SET OrderNumber = 5 WHERE Type = 'ThirdPartyGuaranteedResidual'
UPDATE #LeaseIncomeSchedule SET OrderNumber = 6 WHERE Type = 'OverTerm'
UPDATE #LeaseIncomeSchedule SET OrderNumber = 7 WHERE Type = 'Supplemental'
UPDATE #LeaseIncomeSchedule
SET RentalIncome=0.00,DeferredRentalIncome=0.00
WHERE (Type<>'OverTerm' AND Type<>'Supplemental')
AND (LeaseContractType<>'Operating' AND Type<>'InterimRent')
UPDATE #LeaseIncomeSchedule
SET Income = 0.00,ResidualIncome=0.00,IncomeBalance=0.00,ResidualIncomeBalance=0.00,BeginNBV=0.00,EndNBV=0.00
WHERE LeaseContractType='Operating'
UPDATE #LeaseIncomeSchedule
SET OperatingBeginNBV=0.00,OperatingEndNBV=0.00
WHERE LeaseContractType<>'Operating'
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
RentalIncome,
DeferredRentalIncome,
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
FloatRateIncome,
@IsFloatRateLease AS IsFloatRateLease,
@ShowIncomeColumns AS ShowIncomeColumns,
@IsFutureFunding AS IsFutureFunding
FROM
#LeaseIncomeSchedule
ORDER BY
IncomeDate,OrderNumber
DROP TABLE #InvestmentSummary
DROP TABLE #LeaseFinancesTemp
DROP TABLE #BlendedIncomeSchedulesTemp
DROP TABLE #LeaseIncomeSchedulesTemp
--DROP TABLE #FloatRateIncomesTemp
DROP TABLE #LeasePaymentSchedulesTemp
DROP TABLE #DownPaymentSummary
DROP TABLE #LeaseIncomeSchedule
--DROP TABLE #AdjustmentFloatRateIncomesTemp
DROP TABLE #PayoffTemp
DROP TABLe #PayoffResidualsTemp
END

GO

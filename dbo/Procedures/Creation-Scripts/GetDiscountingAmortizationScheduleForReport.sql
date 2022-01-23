SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetDiscountingAmortizationScheduleForReport]
(
@DiscountingId BIGINT,
@IsAccounting BIT
)
AS
-- DECLARE
--@DiscountingId BIGINT = 948,
--@IsAccounting BIT = 1
BEGIN
SET NOCOUNT ON
CREATE TABLE #DiscountingAmortizationSchedule
(
PaymentNumber BIGINT,
PaymentType NVARCHAR(40),
ExpenseDate DATE,
PaymentAmount  DECIMAL(18,2) DEFAULT 0,
InterestRate  DECIMAL(18,2) DEFAULT 0,
InterestAccrued  DECIMAL(18,2) DEFAULT 0,
InterestCapitalized DECIMAL(18,2) DEFAULT 0,
InterestPaymentAmount DECIMAL(18,2) DEFAULT 0,
PrincipalRepaidAmount  DECIMAL(18,2) DEFAULT 0,
PrincipalAddedAmount DECIMAL(18,2) DEFAULT 0,
EndBalance DECIMAL(18,2) DEFAULT 0,
IsGLPosted BIT,
GainOrLossAmount  DECIMAL(18,2) DEFAULT 0
);
SELECT
PaymentNumber,
PaymentType,
(CASE WHEN Advance = 1 THEN StartDate ELSE EndDate END) AS ExpenseDate,
DiscountingRepaymentSchedules.DiscountingFinanceId AS DiscountingFinanceId,
Discountings.Id AS DiscountingId,
Amount_Amount AS PaymentAmount,
Principal_Amount AS PrincipalRepaidAmount,
Interest_Amount AS InterestPaymentAmount,
GainLoss_Amount AS GainOrLossAmount
INTO #DiscountingPaydownRepaymentDetails
FROM Discountings
JOIN  DiscountingFinances ON Discountings.Id = DiscountingFinances.DiscountingId
JOIN DiscountingRepaymentSchedules ON DiscountingFinances.Id = DiscountingRepaymentSchedules.DiscountingFinanceId
WHERE Discountings.Id = @DiscountingId
AND (PaymentType='Paydown' OR PaymentType ='PaydownAtInception')
AND IsCurrent=1
SELECT
PaydownDate,
DiscountingPaydowns.DiscountingFinanceId ,
DiscountingFinances.DiscountingId
INTO #DiscountingPaydownFinanceDetails
FROM DiscountingPaydowns
JOIN DiscountingFinances ON DiscountingPaydowns.DiscountingFinanceId = DiscountingFinances.Id
WHERE DiscountingFinances.DiscountingId=@DiscountingId
select
#DiscountingPaydownRepaymentDetails.PaymentNumber,
#DiscountingPaydownRepaymentDetails.PaymentType,
#DiscountingPaydownRepaymentDetails.ExpenseDate,
#DiscountingPaydownRepaymentDetails.DiscountingId ,
#DiscountingPaydownFinanceDetails.DiscountingFinanceId ,
#DiscountingPaydownRepaymentDetails.PaymentAmount,
#DiscountingPaydownRepaymentDetails.InterestPaymentAmount,
#DiscountingPaydownRepaymentDetails.PrincipalRepaidAmount,
#DiscountingPaydownRepaymentDetails.GainOrLossAmount
INTO #PaydownTemp
FROM #DiscountingPaydownRepaymentDetails JOIN #DiscountingPaydownFinanceDetails
ON ( #DiscountingPaydownRepaymentDetails.DiscountingId = #DiscountingPaydownFinanceDetails.DiscountingId
AND #DiscountingPaydownRepaymentDetails.ExpenseDate = #DiscountingPaydownFinanceDetails.PaydownDate)
SELECT
DiscountingRepaymentSchedules.PaymentNumber,
DiscountingRepaymentSchedules.PaymentType,
(CASE WHEN Advance = 1 THEN StartDate ELSE EndDate END) AS ExpenseDate,
DiscountingRepaymentSchedules.DiscountingFinanceId AS DiscountingFinanceId,
AdjustmentEntry,
Discountings.Id AS DiscountingId,
Amount_Amount AS PaymentAmount,
Principal_Amount AS PrincipalRepaidAmount,
Interest_Amount AS InterestPaymentAmount,
GainLoss_Amount AS GainOrLossAmount
INTO #FixedTemp
FROM Discountings
JOIN  DiscountingFinances ON Discountings.Id = DiscountingFinances.DiscountingId
JOIN DiscountingRepaymentSchedules ON DiscountingFinances.Id = DiscountingRepaymentSchedules.DiscountingFinanceId
WHERE Discountings.Id = @DiscountingId AND DiscountingRepaymentSchedules.PaymentType='FixedTerm' AND IsCurrent=1
AND DiscountingRepaymentSchedules.DueDate IS NOT NULL
select EOMONTH(#FixedTemp.ExpenseDate) AS DateToBeExcluded,
Discountings.Id AS DiscountingId
INTO #DatesToBeExcluded
FROM Discountings
JOIN  DiscountingFinances ON Discountings.Id = DiscountingFinances.DiscountingId
JOIN DiscountingRepaymentSchedules ON DiscountingFinances.Id = DiscountingRepaymentSchedules.DiscountingFinanceId
JOIN #PaydownTemp ON (CASE WHEN Advance = 1 THEN DiscountingRepaymentSchedules.StartDate ELSE DiscountingRepaymentSchedules.EndDate END)= #PaydownTemp.ExpenseDate
JOIN #FixedTemp ON ( #PaydownTemp.ExpenseDate = EOMONTH(#FixedTemp.ExpenseDate) AND #PaydownTemp.ExpenseDate != #FixedTemp.ExpenseDate)
WHERE Discountings.Id = @DiscountingId
AND IsCurrent=1
SELECT
CommencementDate AS CommencementDate,
Discountings.Id AS DiscountingId
INTO #CommencementDateToBeIncluded
FROM Discountings
JOIN  DiscountingFinances ON Discountings.Id = DiscountingFinances.DiscountingId
WHERE Discountings.Id = @DiscountingId AND Advance=0
AND IsCurrent=1
;WITH CTE_DiscountingIncomeAmort AS
(SELECT
(CASE WHEN ((DiscountingAmortizationSchedules.expensedate = EOMONTH(#FixedTemp.ExpenseDate)
AND DiscountingAmortizationSchedules.expensedate !=#FixedTemp.ExpenseDate) OR #FixedTemp.AdjustmentEntry =1 )
THEN 0 ELSE #FixedTemp.PaymentNumber END) AS PaymentNumber,
#FixedTemp.PaymentType,
DiscountingAmortizationSchedules.ExpenseDate,
(CASE WHEN (DiscountingAmortizationSchedules.expensedate = #FixedTemp.ExpenseDate)
THEN #FixedTemp.PaymentAmount ELSE DiscountingAmortizationSchedules.PaymentAmount_Amount END) AS PaymentAmount,
InterestRate,
InterestAccrualBalance_Amount AS InterestAccrued,
CapitalizedInterest_Amount AS InterestCapitalized,
(CASE WHEN (DiscountingAmortizationSchedules.expensedate = #FixedTemp.ExpenseDate )
THEN #FixedTemp.InterestPaymentAmount ELSE DiscountingAmortizationSchedules.InterestPayment_Amount END) AS InterestPaymentAmount,
(CASE WHEN (DiscountingAmortizationSchedules.expensedate = #FixedTemp.ExpenseDate)
THEN #FixedTemp.PrincipalRepaidAmount ELSE DiscountingAmortizationSchedules.PrincipalRepaid_Amount END) AS PrincipalRepaidAmount,
PrincipalAdded_Amount AS PrincipalAddedAmount,
EndNetBookValue_Amount AS EndBalance,
IsGlPosted,
0 AS GainOrLossAmount
FROM Discountings
JOIN  DiscountingFinances ON Discountings.Id = DiscountingFinances.DiscountingId
JOIN DiscountingAmortizationSchedules ON DiscountingFinances.Id = DiscountingAmortizationSchedules.DiscountingFinanceId
JOIN #FixedTemp ON Discountings.id = #FixedTemp.DiscountingId
LEFT JOIN #DatesToBeExcluded ON DiscountingAmortizationSchedules.ExpenseDate= #DatesToBeExcluded.DateToBeExcluded
WHERE Discountings.Id = @DiscountingId
AND((@IsAccounting =1 AND IsAccounting = 1) OR (@IsAccounting = 0 AND IsSchedule=1))
AND #DatesToBeExcluded.DateToBeExcluded IS NULL AND
(DiscountingAmortizationSchedules.ExpenseDate = #FixedTemp.ExpenseDate OR
(DiscountingAmortizationSchedules.ExpenseDate = EOMONTH(#FixedTemp.ExpenseDate)
AND DiscountingAmortizationSchedules.EndNetBookValue_Amount != 0 ))
UNION
select
#PaydownTemp.PaymentNumber,
#PaydownTemp.PaymentType,
DiscountingAmortizationSchedules.ExpenseDate,
#PaydownTemp.PaymentAmount AS PaymentAmount,
InterestRate,
InterestAccrualBalance_Amount AS InterestAccrued,
CapitalizedInterest_Amount AS InterestCapitalized,
#PaydownTemp.InterestPaymentAmount AS InterestPaymentAmount,
#PaydownTemp.PrincipalRepaidAmount  AS PrincipalRepaidAmount,
PrincipalAdded_Amount AS PrincipalAddedAmount,
EndNetBookValue_Amount AS EndBalance,
IsGlPosted,
#PaydownTemp.GainOrLossAmount
FROM Discountings
JOIN  DiscountingFinances ON Discountings.Id = DiscountingFinances.DiscountingId
JOIN DiscountingAmortizationSchedules ON DiscountingFinances.Id = DiscountingAmortizationSchedules.DiscountingFinanceId
JOIN #PaydownTemp ON DiscountingFinances.Id =  #PaydownTemp.DiscountingFinanceId
WHERE Discountings.Id = @DiscountingId
AND ((@IsAccounting =1 AND IsAccounting = 1) OR (@IsAccounting = 0 AND IsSchedule=1))
AND DiscountingAmortizationSchedules.ExpenseDate = #PaydownTemp.ExpenseDate
UNION
SELECT
0,
'FixedTerm',
DiscountingAmortizationSchedules.ExpenseDate,
PaymentAmount_Amount AS PaymentAmount,
InterestRate,
InterestAccrualBalance_Amount AS InterestAccrued,
CapitalizedInterest_Amount AS InterestCapitalized,
DiscountingAmortizationSchedules.InterestPayment_Amount AS InterestPaymentAmount,
DiscountingAmortizationSchedules.PrincipalRepaid_Amount  AS PrincipalRepaidAmount,
PrincipalAdded_Amount AS PrincipalAddedAmount,
EndNetBookValue_Amount AS EndBalance,
IsGlPosted,
0
FROM Discountings
JOIN  DiscountingFinances ON Discountings.Id = DiscountingFinances.DiscountingId
JOIN DiscountingAmortizationSchedules ON DiscountingFinances.Id = DiscountingAmortizationSchedules.DiscountingFinanceId
JOIN #CommencementDateToBeIncluded ON Discountings.Id =  #CommencementDateToBeIncluded.DiscountingId
WHERE Discountings.Id = @DiscountingId
AND ((@IsAccounting =1 AND IsAccounting = 1) OR (@IsAccounting = 0 AND IsSchedule=1))
AND DiscountingAmortizationSchedules.ExpenseDate = #CommencementDateToBeIncluded.CommencementDate
)
INSERT INTO #DiscountingAmortizationSchedule
SELECT * FROM CTE_DiscountingIncomeAmort
SELECT * FROM #DiscountingAmortizationSchedule  ORDER BY ExpenseDate,PaymentNumber
IF OBJECT_ID('tempdb..#FixedTemp') IS NOT NULL
DROP TABLE #FixedTemp
IF OBJECT_ID('tempdb..#PaydownTemp') IS NOT NULL
DROP TABLE #PaydownTemp
IF OBJECT_ID('tempdb..#DiscountingPaydownFinanceDetails') IS NOT NULL
DROP TABLE #DiscountingPaydownFinanceDetails
IF OBJECT_ID('tempdb..#DiscountingPaydownRepaymentDetails') IS NOT NULL
DROP TABLE #DiscountingPaydownRepaymentDetails
IF OBJECT_ID('tempdb..#DatesToBeExcluded') IS NOT NULL
DROP TABLE #DatesToBeExcluded
IF OBJECT_ID('tempdb..#CommencementDateToBeIncluded') IS NOT NULL
DROP TABLE  #CommencementDateToBeIncluded
DROP TABLE #DiscountingAmortizationSchedule
END

GO

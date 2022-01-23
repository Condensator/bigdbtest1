SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[CreateLoanIncomeSchedulesFromNonAccrual]
(
@IncomeSchedules LoanIncomesToCreate READONLY,
@UserId BIGINT,
@CurrencyCode NVARCHAR(3),
@ModificationTime DateTimeOffset
)
AS
BEGIN
CREATE TABLE #IncomeScheduleTemp
(
IncomeScheduleId BIGINT,
UniqueId BIGINT,
MakeGLEntry BIT,
NonAccrualPostDate DATE
)
MERGE INTO LoanIncomeSchedules
USING(Select
IncomeDate,
PaymentAmount,
BeginNetBookValueAmount,
EndNetBookValueAmount,
PrincipalRepaymentAmount,
PrincipalAddedAmount,
InterestPaymentAmount,
UnroundedInterestAccrued,
InterestAccruedAmount,
InterestAccrualBalanceAmount,
CapitalizedInterestAmount,
CumulativeInterestBalanceAmount,
CompoundDate,
IsSchedule,
IsAccounting,
IsSyndicated,
IsGLPosted,
IsNonAccrual,
IsLessorOwned,
CumulativeInterestAppliedToPrincipalAmount,
AdjustmentEntry,
InterestRate,
TV5InterestAccrualBalanceAmount,
DisbursementId,
FloatRateIndexDetailId,
LoanFinanceId,
UniqueId,
NonAccrualPostDate,
MakeGLEntry FROM @IncomeSchedules)
AS NonAccrualIncomes ON 1=0
WHEN NOT MATCHED THEN
INSERT
(IncomeDate
,Payment_Amount
,Payment_Currency
,BeginNetBookValue_Amount
,BeginNetBookValue_Currency
,EndNetBookValue_Amount
,EndNetBookValue_Currency
,PrincipalRepayment_Amount
,PrincipalRepayment_Currency
,PrincipalAdded_Amount
,PrincipalAdded_Currency
,InterestPayment_Amount
,InterestPayment_Currency
,UnroundedInterestAccrued
,InterestAccrued_Amount
,InterestAccrued_Currency
,InterestAccrualBalance_Amount
,InterestAccrualBalance_Currency
,CapitalizedInterest_Amount
,CapitalizedInterest_Currency
,CumulativeInterestBalance_Amount
,CumulativeInterestBalance_Currency
,CompoundDate
,IsSchedule
,IsAccounting
,IsSyndicated
,IsGLPosted
,IsNonAccrual
,IsLessorOwned
,CreatedById
,CreatedTime
,DisbursementId
,FloatRateIndexDetailId
,LoanFinanceId
,CumulativeInterestAppliedToPrincipal_Amount
,CumulativeInterestAppliedToPrincipal_Currency
,AdjustmentEntry
,InterestRate
,TV5InterestAccrualBalance_Amount
,TV5InterestAccrualBalance_Currency)
VALUES
(IncomeDate
,PaymentAmount
,@CurrencyCode
,BeginNetBookValueAmount
,@CurrencyCode
,EndNetBookValueAmount
,@CurrencyCode
,PrincipalRepaymentAmount
,@CurrencyCode
,PrincipalAddedAmount
,@CurrencyCode
,InterestPaymentAmount
,@CurrencyCode
,UnroundedInterestAccrued
,InterestAccruedAmount
,@CurrencyCode
,InterestAccrualBalanceAmount
,@CurrencyCode
,CapitalizedInterestAmount
,@CurrencyCode
,CumulativeInterestBalanceAmount
,@CurrencyCode
,CompoundDate
,IsSchedule
,IsAccounting
,IsSyndicated
,IsGLPosted
,IsNonAccrual
,IsLessorOwned
,@UserId
,@ModificationTime
,DisbursementId
,FloatRateIndexDetailId
,LoanFinanceId
,CumulativeInterestAppliedToPrincipalAmount
,@CurrencyCode
,AdjustmentEntry
,InterestRate
,TV5InterestAccrualBalanceAmount
,@CurrencyCode)
OUTPUT INSERTED.Id,NonAccrualIncomes.UniqueId,NonAccrualIncomes.MakeGLEntry,NonAccrualIncomes.NonAccrualPostDate INTO #IncomeScheduleTemp;
SELECT IncomeScheduleId = IncomeScheduleId,
UniqueId = UniqueId,
PostDate = NonAccrualPostDate
FROM #IncomeScheduleTemp
WHERE MakeGLEntry=1
DROP TABLE #IncomeScheduleTemp;
END

GO

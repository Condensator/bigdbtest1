SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[CreateCopyForClosedPeriodLoanIncomes]
(
@IncomeSchedules LoanIncomesToClone READONLY,
@UserId BIGINT,
@Time DATETIMEOFFSET,
@IsNonAccrual BIT
)
AS
BEGIN
SET NOCOUNT ON
INSERT INTO LoanIncomeSchedules
(
IncomeDate
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
,CumulativeInterestAppliedToPrincipal_Amount
,CumulativeInterestAppliedToPrincipal_Currency
,AdjustmentEntry
,InterestRate
,CreatedById
,CreatedTime
,DisbursementId
,FloatRateIndexDetailId
,LoanFinanceId
,TV5InterestAccrualBalance_Amount
,TV5InterestAccrualBalance_Currency
)
SELECT
IncomeDate
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
,0
,@IsNonAccrual
,IsLessorOwned
,CumulativeInterestAppliedToPrincipal_Amount
,CumulativeInterestAppliedToPrincipal_Currency
,0
,InterestRate
,@UserId
,@Time
,DisbursementId
,FloatRateIndexDetailId
,LoanFinanceId
,TV5InterestAccrualBalance_Amount
,TV5InterestAccrualBalance_Currency
FROM LoanIncomeSchedules LIS
JOIN @IncomeSchedules Insch ON LIS.Id = Insch.Id;
UPDATE LIS SET IsSchedule = 0, UpdatedById = @UserId, UpdatedTime = @Time
FROM LoanIncomeSchedules LIS
JOIN @IncomeSchedules Insch ON LIS.Id = Insch.Id;
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ManipulateLoanIncomeSchedules]
(
@IncomeSchedules LoanIncomeSchedulesForManipulation READONLY,
@LoanFinanceId BIGINT,
@UserId BIGINT,
@Time DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
MERGE dbo.LoanIncomeSchedules AS PersistedLoanIncome
USING @IncomeSchedules AS Income
ON (PersistedLoanIncome.Id = Income.Id)
WHEN MATCHED THEN
UPDATE SET AdjustmentEntry = Income.AdjustmentEntry
,BeginNetBookValue_Amount = Income.BeginNetBookValue
,BeginNetBookValue_Currency = Income.Currency
,CapitalizedInterest_Amount = Income.CapitalizedInterest
,CapitalizedInterest_Currency = Income.Currency
,CompoundDate = Income.CompoundDate
,CumulativeInterestAppliedToPrincipal_Amount = Income.CumulativeInterestAppliedToPrincipal
,CumulativeInterestAppliedToPrincipal_Currency = Income.Currency
,CumulativeInterestBalance_Amount = Income.CumulativeInterestBalance
,CumulativeInterestBalance_Currency = Income.Currency
,DisbursementId = Income.DisbursementId
,EndNetBookValue_Amount = Income.EndNetBookValue
,EndNetBookValue_Currency = Income.Currency
,FloatRateIndexDetailId = Income.FloatRateIndexDetailId
,IncomeDate = Income.IncomeDate
,InterestAccrualBalance_Amount = Income.InterestAccrualBalance
,InterestAccrualBalance_Currency = Income.Currency
,InterestAccrued_Amount = Income.InterestAccrued
,InterestAccrued_Currency = Income.Currency
,InterestPayment_Amount = Income.InterestPayment
,InterestPayment_Currency = Income.Currency
,InterestRate = Income.InterestRate
,IsAccounting = Income.IsAccounting
,IsGLPosted = Income.IsGLPosted
,IsLessorOwned = Income.IsLessorOwned
,IsNonAccrual = Income.IsNonAccrual
,IsSchedule = Income.IsSchedule
,IsSyndicated = Income.IsSyndicated
,Payment_Amount = Income.Payment
,Payment_Currency = Income.Currency
,PrincipalAdded_Amount = Income.PrincipalAdded
,PrincipalAdded_Currency = Income.Currency
,PrincipalRepayment_Amount = Income.PrincipalRepayment
,PrincipalRepayment_Currency = Income.Currency
,TV5InterestAccrualBalance_Currency = Income.Currency
,TV5InterestAccrualBalance_Amount = Income.TV5InterestAccrualBalance
,UpdatedById = @UserId
,UpdatedTime = @Time
WHEN NOT MATCHED THEN
INSERT (AdjustmentEntry
,BeginNetBookValue_Amount
,BeginNetBookValue_Currency
,CapitalizedInterest_Amount
,CapitalizedInterest_Currency
,CompoundDate
,CreatedById
,CreatedTime
,CumulativeInterestAppliedToPrincipal_Amount
,CumulativeInterestAppliedToPrincipal_Currency
,CumulativeInterestBalance_Amount
,CumulativeInterestBalance_Currency
,DisbursementId
,EndNetBookValue_Amount
,EndNetBookValue_Currency
,FloatRateIndexDetailId
,IncomeDate
,InterestAccrualBalance_Amount
,InterestAccrualBalance_Currency
,InterestAccrued_Amount
,InterestAccrued_Currency
,InterestPayment_Amount
,InterestPayment_Currency
,InterestRate
,IsAccounting
,IsGLPosted
,IsLessorOwned
,IsNonAccrual
,IsSchedule
,IsSyndicated
,LoanFinanceId
,Payment_Amount
,Payment_Currency
,PrincipalAdded_Amount
,PrincipalAdded_Currency
,PrincipalRepayment_Amount
,PrincipalRepayment_Currency
,UnroundedInterestAccrued
,TV5InterestAccrualBalance_Amount
,TV5InterestAccrualBalance_Currency)
VALUES (Income.AdjustmentEntry
,Income.BeginNetBookValue
,Income.Currency
,Income.CapitalizedInterest
,Income.Currency
,Income.CompoundDate
,@UserId
,@Time
,Income.CumulativeInterestAppliedToPrincipal
,Income.Currency
,Income.CumulativeInterestBalance
,Income.Currency
,Income.DisbursementId
,Income.EndNetBookValue
,Income.Currency
,Income.FloatRateIndexDetailId
,Income.IncomeDate
,Income.InterestAccrualBalance
,Income.Currency
,Income.InterestAccrued
,Income.Currency
,Income.InterestPayment
,Income.Currency
,Income.InterestRate
,Income.IsAccounting
,Income.IsGLPosted
,Income.IsLessorOwned
,Income.IsNonAccrual
,Income.IsSchedule
,Income.IsSyndicated
,@LoanFinanceId
,Income.Payment
,Income.Currency
,Income.PrincipalAdded
,Income.Currency
,Income.PrincipalRepayment
,Income.Currency
,0.0
,Income.TV5InterestAccrualBalance
,Income.Currency)
;
END

GO

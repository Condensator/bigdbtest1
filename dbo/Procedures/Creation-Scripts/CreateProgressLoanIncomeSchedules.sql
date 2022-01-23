SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[CreateProgressLoanIncomeSchedules]
(
	@IncomeSchedules ProgressLoanIncomeSchedulesForManipulation READONLY,
	@UserId BIGINT,
	@Time DATETIMEOFFSET
)
AS
BEGIN


INSERT INTO dbo.LoanIncomeSchedules
				(AdjustmentEntry
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
		Select Income.AdjustmentEntry
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
			   ,Income.LoanFinanceId
			   ,Income.Payment
			   ,Income.Currency
			   ,Income.PrincipalAdded
			   ,Income.Currency
			   ,Income.PrincipalRepayment
			   ,Income.Currency
			   ,Income.UnroundedInterestAccrued
			   ,Income.TV5InterestAccrualBalance
			   ,Income.Currency
			   FROM @IncomeSchedules AS Income
END

GO

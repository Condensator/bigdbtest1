SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLoanIncomeSchedule]
(
 @val [dbo].[LoanIncomeSchedule] READONLY
)
AS
SET NOCOUNT ON;
DECLARE @Output TABLE(
 [Action] NVARCHAR(10) NOT NULL,
 [Id] bigint NOT NULL,
 [Token] int NOT NULL,
 [RowVersion] BIGINT,
 [OldRowVersion] BIGINT
)
MERGE [dbo].[LoanIncomeSchedules] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AdjustmentEntry]=S.[AdjustmentEntry],[BeginNetBookValue_Amount]=S.[BeginNetBookValue_Amount],[BeginNetBookValue_Currency]=S.[BeginNetBookValue_Currency],[CapitalizedInterest_Amount]=S.[CapitalizedInterest_Amount],[CapitalizedInterest_Currency]=S.[CapitalizedInterest_Currency],[CompoundDate]=S.[CompoundDate],[CumulativeInterestAppliedToPrincipal_Amount]=S.[CumulativeInterestAppliedToPrincipal_Amount],[CumulativeInterestAppliedToPrincipal_Currency]=S.[CumulativeInterestAppliedToPrincipal_Currency],[CumulativeInterestBalance_Amount]=S.[CumulativeInterestBalance_Amount],[CumulativeInterestBalance_Currency]=S.[CumulativeInterestBalance_Currency],[DisbursementId]=S.[DisbursementId],[EndNetBookValue_Amount]=S.[EndNetBookValue_Amount],[EndNetBookValue_Currency]=S.[EndNetBookValue_Currency],[FloatRateIndexDetailId]=S.[FloatRateIndexDetailId],[IncomeDate]=S.[IncomeDate],[InterestAccrualBalance_Amount]=S.[InterestAccrualBalance_Amount],[InterestAccrualBalance_Currency]=S.[InterestAccrualBalance_Currency],[InterestAccrued_Amount]=S.[InterestAccrued_Amount],[InterestAccrued_Currency]=S.[InterestAccrued_Currency],[InterestPayment_Amount]=S.[InterestPayment_Amount],[InterestPayment_Currency]=S.[InterestPayment_Currency],[InterestRate]=S.[InterestRate],[IsAccounting]=S.[IsAccounting],[IsGLPosted]=S.[IsGLPosted],[IsLessorOwned]=S.[IsLessorOwned],[IsNonAccrual]=S.[IsNonAccrual],[IsSchedule]=S.[IsSchedule],[IsSyndicated]=S.[IsSyndicated],[LoanFinanceId]=S.[LoanFinanceId],[Payment_Amount]=S.[Payment_Amount],[Payment_Currency]=S.[Payment_Currency],[PrincipalAdded_Amount]=S.[PrincipalAdded_Amount],[PrincipalAdded_Currency]=S.[PrincipalAdded_Currency],[PrincipalRepayment_Amount]=S.[PrincipalRepayment_Amount],[PrincipalRepayment_Currency]=S.[PrincipalRepayment_Currency],[TV5InterestAccrualBalance_Amount]=S.[TV5InterestAccrualBalance_Amount],[TV5InterestAccrualBalance_Currency]=S.[TV5InterestAccrualBalance_Currency],[UnroundedInterestAccrued]=S.[UnroundedInterestAccrued],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AdjustmentEntry],[BeginNetBookValue_Amount],[BeginNetBookValue_Currency],[CapitalizedInterest_Amount],[CapitalizedInterest_Currency],[CompoundDate],[CreatedById],[CreatedTime],[CumulativeInterestAppliedToPrincipal_Amount],[CumulativeInterestAppliedToPrincipal_Currency],[CumulativeInterestBalance_Amount],[CumulativeInterestBalance_Currency],[DisbursementId],[EndNetBookValue_Amount],[EndNetBookValue_Currency],[FloatRateIndexDetailId],[IncomeDate],[InterestAccrualBalance_Amount],[InterestAccrualBalance_Currency],[InterestAccrued_Amount],[InterestAccrued_Currency],[InterestPayment_Amount],[InterestPayment_Currency],[InterestRate],[IsAccounting],[IsGLPosted],[IsLessorOwned],[IsNonAccrual],[IsSchedule],[IsSyndicated],[LoanFinanceId],[Payment_Amount],[Payment_Currency],[PrincipalAdded_Amount],[PrincipalAdded_Currency],[PrincipalRepayment_Amount],[PrincipalRepayment_Currency],[TV5InterestAccrualBalance_Amount],[TV5InterestAccrualBalance_Currency],[UnroundedInterestAccrued])
    VALUES (S.[AdjustmentEntry],S.[BeginNetBookValue_Amount],S.[BeginNetBookValue_Currency],S.[CapitalizedInterest_Amount],S.[CapitalizedInterest_Currency],S.[CompoundDate],S.[CreatedById],S.[CreatedTime],S.[CumulativeInterestAppliedToPrincipal_Amount],S.[CumulativeInterestAppliedToPrincipal_Currency],S.[CumulativeInterestBalance_Amount],S.[CumulativeInterestBalance_Currency],S.[DisbursementId],S.[EndNetBookValue_Amount],S.[EndNetBookValue_Currency],S.[FloatRateIndexDetailId],S.[IncomeDate],S.[InterestAccrualBalance_Amount],S.[InterestAccrualBalance_Currency],S.[InterestAccrued_Amount],S.[InterestAccrued_Currency],S.[InterestPayment_Amount],S.[InterestPayment_Currency],S.[InterestRate],S.[IsAccounting],S.[IsGLPosted],S.[IsLessorOwned],S.[IsNonAccrual],S.[IsSchedule],S.[IsSyndicated],S.[LoanFinanceId],S.[Payment_Amount],S.[Payment_Currency],S.[PrincipalAdded_Amount],S.[PrincipalAdded_Currency],S.[PrincipalRepayment_Amount],S.[PrincipalRepayment_Currency],S.[TV5InterestAccrualBalance_Amount],S.[TV5InterestAccrualBalance_Currency],S.[UnroundedInterestAccrued])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

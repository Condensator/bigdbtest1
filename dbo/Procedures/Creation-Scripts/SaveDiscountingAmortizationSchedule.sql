SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDiscountingAmortizationSchedule]
(
 @val [dbo].[DiscountingAmortizationSchedule] READONLY
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
MERGE [dbo].[DiscountingAmortizationSchedules] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AdjustmentEntry]=S.[AdjustmentEntry],[BeginNetBookValue_Amount]=S.[BeginNetBookValue_Amount],[BeginNetBookValue_Currency]=S.[BeginNetBookValue_Currency],[CapitalizedInterest_Amount]=S.[CapitalizedInterest_Amount],[CapitalizedInterest_Currency]=S.[CapitalizedInterest_Currency],[DiscountingFinanceId]=S.[DiscountingFinanceId],[EndNetBookValue_Amount]=S.[EndNetBookValue_Amount],[EndNetBookValue_Currency]=S.[EndNetBookValue_Currency],[ExpenseDate]=S.[ExpenseDate],[InterestAccrualBalance_Amount]=S.[InterestAccrualBalance_Amount],[InterestAccrualBalance_Currency]=S.[InterestAccrualBalance_Currency],[InterestAccrued_Amount]=S.[InterestAccrued_Amount],[InterestAccrued_Currency]=S.[InterestAccrued_Currency],[InterestGainLoss_Amount]=S.[InterestGainLoss_Amount],[InterestGainLoss_Currency]=S.[InterestGainLoss_Currency],[InterestPayment_Amount]=S.[InterestPayment_Amount],[InterestPayment_Currency]=S.[InterestPayment_Currency],[InterestRate]=S.[InterestRate],[IsAccounting]=S.[IsAccounting],[IsGLPosted]=S.[IsGLPosted],[IsNonAccrual]=S.[IsNonAccrual],[IsSchedule]=S.[IsSchedule],[ModificationID]=S.[ModificationID],[ModificationType]=S.[ModificationType],[PaymentAmount_Amount]=S.[PaymentAmount_Amount],[PaymentAmount_Currency]=S.[PaymentAmount_Currency],[PrincipalAdded_Amount]=S.[PrincipalAdded_Amount],[PrincipalAdded_Currency]=S.[PrincipalAdded_Currency],[PrincipalGainLoss_Amount]=S.[PrincipalGainLoss_Amount],[PrincipalGainLoss_Currency]=S.[PrincipalGainLoss_Currency],[PrincipalRepaid_Amount]=S.[PrincipalRepaid_Amount],[PrincipalRepaid_Currency]=S.[PrincipalRepaid_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AdjustmentEntry],[BeginNetBookValue_Amount],[BeginNetBookValue_Currency],[CapitalizedInterest_Amount],[CapitalizedInterest_Currency],[CreatedById],[CreatedTime],[DiscountingFinanceId],[EndNetBookValue_Amount],[EndNetBookValue_Currency],[ExpenseDate],[InterestAccrualBalance_Amount],[InterestAccrualBalance_Currency],[InterestAccrued_Amount],[InterestAccrued_Currency],[InterestGainLoss_Amount],[InterestGainLoss_Currency],[InterestPayment_Amount],[InterestPayment_Currency],[InterestRate],[IsAccounting],[IsGLPosted],[IsNonAccrual],[IsSchedule],[ModificationID],[ModificationType],[PaymentAmount_Amount],[PaymentAmount_Currency],[PrincipalAdded_Amount],[PrincipalAdded_Currency],[PrincipalGainLoss_Amount],[PrincipalGainLoss_Currency],[PrincipalRepaid_Amount],[PrincipalRepaid_Currency])
    VALUES (S.[AdjustmentEntry],S.[BeginNetBookValue_Amount],S.[BeginNetBookValue_Currency],S.[CapitalizedInterest_Amount],S.[CapitalizedInterest_Currency],S.[CreatedById],S.[CreatedTime],S.[DiscountingFinanceId],S.[EndNetBookValue_Amount],S.[EndNetBookValue_Currency],S.[ExpenseDate],S.[InterestAccrualBalance_Amount],S.[InterestAccrualBalance_Currency],S.[InterestAccrued_Amount],S.[InterestAccrued_Currency],S.[InterestGainLoss_Amount],S.[InterestGainLoss_Currency],S.[InterestPayment_Amount],S.[InterestPayment_Currency],S.[InterestRate],S.[IsAccounting],S.[IsGLPosted],S.[IsNonAccrual],S.[IsSchedule],S.[ModificationID],S.[ModificationType],S.[PaymentAmount_Amount],S.[PaymentAmount_Currency],S.[PrincipalAdded_Amount],S.[PrincipalAdded_Currency],S.[PrincipalGainLoss_Amount],S.[PrincipalGainLoss_Currency],S.[PrincipalRepaid_Amount],S.[PrincipalRepaid_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

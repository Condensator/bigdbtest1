SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAcceleratedBalanceDetailForLoan]
(
 @val [dbo].[AcceleratedBalanceDetailForLoan] READONLY
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
MERGE [dbo].[AcceleratedBalanceDetailForLoans] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccruedInterest_Amount]=S.[AccruedInterest_Amount],[AccruedInterest_Currency]=S.[AccruedInterest_Currency],[AccruedInterestPriortoDefault_Amount]=S.[AccruedInterestPriortoDefault_Amount],[AccruedInterestPriortoDefault_Currency]=S.[AccruedInterestPriortoDefault_Currency],[Credits_Amount]=S.[Credits_Amount],[Credits_Currency]=S.[Credits_Currency],[DateInterestAccruedFrom]=S.[DateInterestAccruedFrom],[DayCountConvention]=S.[DayCountConvention],[ExpenseAndFees_Waivers_Amount]=S.[ExpenseAndFees_Waivers_Amount],[ExpenseAndFees_Waivers_Currency]=S.[ExpenseAndFees_Waivers_Currency],[ExpensesAndFees_Amount]=S.[ExpensesAndFees_Amount],[ExpensesAndFees_Currency]=S.[ExpensesAndFees_Currency],[InterestRate]=S.[InterestRate],[PrincipalAmount_Amount]=S.[PrincipalAmount_Amount],[PrincipalAmount_Currency]=S.[PrincipalAmount_Currency],[PrincipalBalance_Amount]=S.[PrincipalBalance_Amount],[PrincipalBalance_Currency]=S.[PrincipalBalance_Currency],[TotalAcceleratedBalance_Amount]=S.[TotalAcceleratedBalance_Amount],[TotalAcceleratedBalance_Currency]=S.[TotalAcceleratedBalance_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AccruedInterest_Amount],[AccruedInterest_Currency],[AccruedInterestPriortoDefault_Amount],[AccruedInterestPriortoDefault_Currency],[CreatedById],[CreatedTime],[Credits_Amount],[Credits_Currency],[DateInterestAccruedFrom],[DayCountConvention],[ExpenseAndFees_Waivers_Amount],[ExpenseAndFees_Waivers_Currency],[ExpensesAndFees_Amount],[ExpensesAndFees_Currency],[Id],[InterestRate],[PrincipalAmount_Amount],[PrincipalAmount_Currency],[PrincipalBalance_Amount],[PrincipalBalance_Currency],[TotalAcceleratedBalance_Amount],[TotalAcceleratedBalance_Currency])
    VALUES (S.[AccruedInterest_Amount],S.[AccruedInterest_Currency],S.[AccruedInterestPriortoDefault_Amount],S.[AccruedInterestPriortoDefault_Currency],S.[CreatedById],S.[CreatedTime],S.[Credits_Amount],S.[Credits_Currency],S.[DateInterestAccruedFrom],S.[DayCountConvention],S.[ExpenseAndFees_Waivers_Amount],S.[ExpenseAndFees_Waivers_Currency],S.[ExpensesAndFees_Amount],S.[ExpensesAndFees_Currency],S.[Id],S.[InterestRate],S.[PrincipalAmount_Amount],S.[PrincipalAmount_Currency],S.[PrincipalBalance_Amount],S.[PrincipalBalance_Currency],S.[TotalAcceleratedBalance_Amount],S.[TotalAcceleratedBalance_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

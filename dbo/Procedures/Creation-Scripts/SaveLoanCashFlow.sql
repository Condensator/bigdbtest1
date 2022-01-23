SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLoanCashFlow]
(
 @val [dbo].[LoanCashFlow] READONLY
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
MERGE [dbo].[LoanCashFlows] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [CumulativePostTaxCashFlow_Amount]=S.[CumulativePostTaxCashFlow_Amount],[CumulativePostTaxCashFlow_Currency]=S.[CumulativePostTaxCashFlow_Currency],[Date]=S.[Date],[Equity_Amount]=S.[Equity_Amount],[Equity_Currency]=S.[Equity_Currency],[FederalTaxPaid_Amount]=S.[FederalTaxPaid_Amount],[FederalTaxPaid_Currency]=S.[FederalTaxPaid_Currency],[Fees_Amount]=S.[Fees_Amount],[Fees_Currency]=S.[Fees_Currency],[IsActive]=S.[IsActive],[LendingLoanTakedown_Amount]=S.[LendingLoanTakedown_Amount],[LendingLoanTakedown_Currency]=S.[LendingLoanTakedown_Currency],[PeriodicExpense_Amount]=S.[PeriodicExpense_Amount],[PeriodicExpense_Currency]=S.[PeriodicExpense_Currency],[PeriodicIncome_Amount]=S.[PeriodicIncome_Amount],[PeriodicIncome_Currency]=S.[PeriodicIncome_Currency],[PostTaxCashFlow_Amount]=S.[PostTaxCashFlow_Amount],[PostTaxCashFlow_Currency]=S.[PostTaxCashFlow_Currency],[PreTaxCashFlow_Amount]=S.[PreTaxCashFlow_Amount],[PreTaxCashFlow_Currency]=S.[PreTaxCashFlow_Currency],[Rent_Amount]=S.[Rent_Amount],[Rent_Currency]=S.[Rent_Currency],[Residual_Amount]=S.[Residual_Amount],[Residual_Currency]=S.[Residual_Currency],[SecurityDepositAmount_Amount]=S.[SecurityDepositAmount_Amount],[SecurityDepositAmount_Currency]=S.[SecurityDepositAmount_Currency],[StateTaxPaid_Amount]=S.[StateTaxPaid_Amount],[StateTaxPaid_Currency]=S.[StateTaxPaid_Currency],[Taxpaid_Amount]=S.[Taxpaid_Amount],[Taxpaid_Currency]=S.[Taxpaid_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[CumulativePostTaxCashFlow_Amount],[CumulativePostTaxCashFlow_Currency],[Date],[Equity_Amount],[Equity_Currency],[FederalTaxPaid_Amount],[FederalTaxPaid_Currency],[Fees_Amount],[Fees_Currency],[IsActive],[LendingLoanTakedown_Amount],[LendingLoanTakedown_Currency],[LoanFinanceId],[PeriodicExpense_Amount],[PeriodicExpense_Currency],[PeriodicIncome_Amount],[PeriodicIncome_Currency],[PostTaxCashFlow_Amount],[PostTaxCashFlow_Currency],[PreTaxCashFlow_Amount],[PreTaxCashFlow_Currency],[Rent_Amount],[Rent_Currency],[Residual_Amount],[Residual_Currency],[SecurityDepositAmount_Amount],[SecurityDepositAmount_Currency],[StateTaxPaid_Amount],[StateTaxPaid_Currency],[Taxpaid_Amount],[Taxpaid_Currency])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[CumulativePostTaxCashFlow_Amount],S.[CumulativePostTaxCashFlow_Currency],S.[Date],S.[Equity_Amount],S.[Equity_Currency],S.[FederalTaxPaid_Amount],S.[FederalTaxPaid_Currency],S.[Fees_Amount],S.[Fees_Currency],S.[IsActive],S.[LendingLoanTakedown_Amount],S.[LendingLoanTakedown_Currency],S.[LoanFinanceId],S.[PeriodicExpense_Amount],S.[PeriodicExpense_Currency],S.[PeriodicIncome_Amount],S.[PeriodicIncome_Currency],S.[PostTaxCashFlow_Amount],S.[PostTaxCashFlow_Currency],S.[PreTaxCashFlow_Amount],S.[PreTaxCashFlow_Currency],S.[Rent_Amount],S.[Rent_Currency],S.[Residual_Amount],S.[Residual_Currency],S.[SecurityDepositAmount_Amount],S.[SecurityDepositAmount_Currency],S.[StateTaxPaid_Amount],S.[StateTaxPaid_Currency],S.[Taxpaid_Amount],S.[Taxpaid_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

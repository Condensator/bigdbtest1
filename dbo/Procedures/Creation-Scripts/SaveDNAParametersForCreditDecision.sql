SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDNAParametersForCreditDecision]
(
 @val [dbo].[DNAParametersForCreditDecision] READONLY
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
MERGE [dbo].[DNAParametersForCreditDecisions] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BankLoans]=S.[BankLoans],[DaysOverdue]=S.[DaysOverdue],[DaysOverdueRange]=S.[DaysOverdueRange],[LoansFromFinancialInstitutions]=S.[LoansFromFinancialInstitutions],[MonthlyIncomeNSSI_Amount]=S.[MonthlyIncomeNSSI_Amount],[MonthlyIncomeNSSI_Currency]=S.[MonthlyIncomeNSSI_Currency],[MonthlyLeasePayment]=S.[MonthlyLeasePayment],[MonthsWithEmployment]=S.[MonthsWithEmployment],[NetDisposableIncome_Amount]=S.[NetDisposableIncome_Amount],[NetDisposableIncome_Currency]=S.[NetDisposableIncome_Currency],[PartyId]=S.[PartyId],[Property]=S.[Property],[RelationshipType]=S.[RelationshipType],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BankLoans],[CreatedById],[CreatedTime],[CreditDecisionForCreditApplicationId],[DaysOverdue],[DaysOverdueRange],[LoansFromFinancialInstitutions],[MonthlyIncomeNSSI_Amount],[MonthlyIncomeNSSI_Currency],[MonthlyLeasePayment],[MonthsWithEmployment],[NetDisposableIncome_Amount],[NetDisposableIncome_Currency],[PartyId],[Property],[RelationshipType])
    VALUES (S.[BankLoans],S.[CreatedById],S.[CreatedTime],S.[CreditDecisionForCreditApplicationId],S.[DaysOverdue],S.[DaysOverdueRange],S.[LoansFromFinancialInstitutions],S.[MonthlyIncomeNSSI_Amount],S.[MonthlyIncomeNSSI_Currency],S.[MonthlyLeasePayment],S.[MonthsWithEmployment],S.[NetDisposableIncome_Amount],S.[NetDisposableIncome_Currency],S.[PartyId],S.[Property],S.[RelationshipType])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

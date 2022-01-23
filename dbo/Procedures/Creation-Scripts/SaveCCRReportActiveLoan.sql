SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCCRReportActiveLoan]
(
 @val [dbo].[CCRReportActiveLoan] READONLY
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
MERGE [dbo].[CCRReportActiveLoans] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BalanceSheetExp_Amount]=S.[BalanceSheetExp_Amount],[BalanceSheetExp_Currency]=S.[BalanceSheetExp_Currency],[ContingentLiabilities_Amount]=S.[ContingentLiabilities_Amount],[ContingentLiabilities_Currency]=S.[ContingentLiabilities_Currency],[ContractualAmount_Amount]=S.[ContractualAmount_Amount],[ContractualAmount_Currency]=S.[ContractualAmount_Currency],[ContractualTerm]=S.[ContractualTerm],[Date]=S.[Date],[FinancialInstitution]=S.[FinancialInstitution],[MonthlyInstalment_Amount]=S.[MonthlyInstalment_Amount],[MonthlyInstalment_Currency]=S.[MonthlyInstalment_Currency],[NonPerformingReceivables_Amount]=S.[NonPerformingReceivables_Amount],[NonPerformingReceivables_Currency]=S.[NonPerformingReceivables_Currency],[OffBalanceExp_Amount]=S.[OffBalanceExp_Amount],[OffBalanceExp_Currency]=S.[OffBalanceExp_Currency],[OverduePrincipalOutstanding_Amount]=S.[OverduePrincipalOutstanding_Amount],[OverduePrincipalOutstanding_Currency]=S.[OverduePrincipalOutstanding_Currency],[PeriodofDelinquency]=S.[PeriodofDelinquency],[PrincipalOutstanding_Amount]=S.[PrincipalOutstanding_Amount],[PrincipalOutstanding_Currency]=S.[PrincipalOutstanding_Currency],[RemainingPeriodMaturity]=S.[RemainingPeriodMaturity],[TypeofCredit]=S.[TypeofCredit],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UtilizedAmount_Amount]=S.[UtilizedAmount_Amount],[UtilizedAmount_Currency]=S.[UtilizedAmount_Currency]
WHEN NOT MATCHED THEN
	INSERT ([BalanceSheetExp_Amount],[BalanceSheetExp_Currency],[ContingentLiabilities_Amount],[ContingentLiabilities_Currency],[ContractualAmount_Amount],[ContractualAmount_Currency],[ContractualTerm],[CreatedById],[CreatedTime],[Date],[DNAParametersForCreditDecisionId],[FinancialInstitution],[MonthlyInstalment_Amount],[MonthlyInstalment_Currency],[NonPerformingReceivables_Amount],[NonPerformingReceivables_Currency],[OffBalanceExp_Amount],[OffBalanceExp_Currency],[OverduePrincipalOutstanding_Amount],[OverduePrincipalOutstanding_Currency],[PeriodofDelinquency],[PrincipalOutstanding_Amount],[PrincipalOutstanding_Currency],[RemainingPeriodMaturity],[TypeofCredit],[UtilizedAmount_Amount],[UtilizedAmount_Currency])
    VALUES (S.[BalanceSheetExp_Amount],S.[BalanceSheetExp_Currency],S.[ContingentLiabilities_Amount],S.[ContingentLiabilities_Currency],S.[ContractualAmount_Amount],S.[ContractualAmount_Currency],S.[ContractualTerm],S.[CreatedById],S.[CreatedTime],S.[Date],S.[DNAParametersForCreditDecisionId],S.[FinancialInstitution],S.[MonthlyInstalment_Amount],S.[MonthlyInstalment_Currency],S.[NonPerformingReceivables_Amount],S.[NonPerformingReceivables_Currency],S.[OffBalanceExp_Amount],S.[OffBalanceExp_Currency],S.[OverduePrincipalOutstanding_Amount],S.[OverduePrincipalOutstanding_Currency],S.[PeriodofDelinquency],S.[PrincipalOutstanding_Amount],S.[PrincipalOutstanding_Currency],S.[RemainingPeriodMaturity],S.[TypeofCredit],S.[UtilizedAmount_Amount],S.[UtilizedAmount_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

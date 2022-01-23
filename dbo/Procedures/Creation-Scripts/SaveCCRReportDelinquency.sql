SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCCRReportDelinquency]
(
 @val [dbo].[CCRReportDelinquency] READONLY
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
MERGE [dbo].[CCRReportDelinquencies] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [CategoryofDelinquency]=S.[CategoryofDelinquency],[DateofCorrection]=S.[DateofCorrection],[FinancialInstitution]=S.[FinancialInstitution],[LoanType]=S.[LoanType],[NumberofAccountingPeriods]=S.[NumberofAccountingPeriods],[NumberofLoans]=S.[NumberofLoans],[OverdueInterestAndOtherReceivables_Amount]=S.[OverdueInterestAndOtherReceivables_Amount],[OverdueInterestAndOtherReceivables_Currency]=S.[OverdueInterestAndOtherReceivables_Currency],[OverduePrincipalOutstanding_Amount]=S.[OverduePrincipalOutstanding_Amount],[OverduePrincipalOutstanding_Currency]=S.[OverduePrincipalOutstanding_Currency],[TotalOffBalanceExp_Amount]=S.[TotalOffBalanceExp_Amount],[TotalOffBalanceExp_Currency]=S.[TotalOffBalanceExp_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[Year]=S.[Year]
WHEN NOT MATCHED THEN
	INSERT ([CategoryofDelinquency],[CreatedById],[CreatedTime],[DateofCorrection],[DNAParametersForCreditDecisionId],[FinancialInstitution],[LoanType],[NumberofAccountingPeriods],[NumberofLoans],[OverdueInterestAndOtherReceivables_Amount],[OverdueInterestAndOtherReceivables_Currency],[OverduePrincipalOutstanding_Amount],[OverduePrincipalOutstanding_Currency],[TotalOffBalanceExp_Amount],[TotalOffBalanceExp_Currency],[Year])
    VALUES (S.[CategoryofDelinquency],S.[CreatedById],S.[CreatedTime],S.[DateofCorrection],S.[DNAParametersForCreditDecisionId],S.[FinancialInstitution],S.[LoanType],S.[NumberofAccountingPeriods],S.[NumberofLoans],S.[OverdueInterestAndOtherReceivables_Amount],S.[OverdueInterestAndOtherReceivables_Currency],S.[OverduePrincipalOutstanding_Amount],S.[OverduePrincipalOutstanding_Currency],S.[TotalOffBalanceExp_Amount],S.[TotalOffBalanceExp_Currency],S.[Year])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

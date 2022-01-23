SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCCRReportCreditSet]
(
 @val [dbo].[CCRReportCreditSet] READONLY
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
MERGE [dbo].[CCRReportCreditSets] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BalanceSheetExp_Amount]=S.[BalanceSheetExp_Amount],[BalanceSheetExp_Currency]=S.[BalanceSheetExp_Currency],[ContractualAmount_Amount]=S.[ContractualAmount_Amount],[ContractualAmount_Currency]=S.[ContractualAmount_Currency],[DateofLastReport]=S.[DateofLastReport],[FinancialInstitution]=S.[FinancialInstitution],[NumberofLoans]=S.[NumberofLoans],[PeriodofDelinquency]=S.[PeriodofDelinquency],[Role]=S.[Role],[TotalOffBalanceExp_Amount]=S.[TotalOffBalanceExp_Amount],[TotalOffBalanceExp_Currency]=S.[TotalOffBalanceExp_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BalanceSheetExp_Amount],[BalanceSheetExp_Currency],[ContractualAmount_Amount],[ContractualAmount_Currency],[CreatedById],[CreatedTime],[DateofLastReport],[DNAParametersForCreditDecisionId],[FinancialInstitution],[NumberofLoans],[PeriodofDelinquency],[Role],[TotalOffBalanceExp_Amount],[TotalOffBalanceExp_Currency])
    VALUES (S.[BalanceSheetExp_Amount],S.[BalanceSheetExp_Currency],S.[ContractualAmount_Amount],S.[ContractualAmount_Currency],S.[CreatedById],S.[CreatedTime],S.[DateofLastReport],S.[DNAParametersForCreditDecisionId],S.[FinancialInstitution],S.[NumberofLoans],S.[PeriodofDelinquency],S.[Role],S.[TotalOffBalanceExp_Amount],S.[TotalOffBalanceExp_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

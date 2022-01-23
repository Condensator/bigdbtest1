SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCCRReportNewCredit]
(
 @val [dbo].[CCRReportNewCredit] READONLY
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
MERGE [dbo].[CCRReportNewCredits] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ContractualAmount_Amount]=S.[ContractualAmount_Amount],[ContractualAmount_Currency]=S.[ContractualAmount_Currency],[FinancialInstitution]=S.[FinancialInstitution],[TypeofLoan]=S.[TypeofLoan],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ContractualAmount_Amount],[ContractualAmount_Currency],[CreatedById],[CreatedTime],[DNAParametersForCreditDecisionId],[FinancialInstitution],[TypeofLoan])
    VALUES (S.[ContractualAmount_Amount],S.[ContractualAmount_Currency],S.[CreatedById],S.[CreatedTime],S.[DNAParametersForCreditDecisionId],S.[FinancialInstitution],S.[TypeofLoan])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

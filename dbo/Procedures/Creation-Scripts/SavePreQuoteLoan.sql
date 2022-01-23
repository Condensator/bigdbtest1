SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePreQuoteLoan]
(
 @val [dbo].[PreQuoteLoan] READONLY
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
MERGE [dbo].[PreQuoteLoans] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AmortProcessThroughDate]=S.[AmortProcessThroughDate],[AsOfDate]=S.[AsOfDate],[HasPrepaymentPenalty]=S.[HasPrepaymentPenalty],[InterestBalance_Amount]=S.[InterestBalance_Amount],[InterestBalance_Currency]=S.[InterestBalance_Currency],[IsActive]=S.[IsActive],[LoanAmount_Amount]=S.[LoanAmount_Amount],[LoanAmount_Currency]=S.[LoanAmount_Currency],[LoanFinanceId]=S.[LoanFinanceId],[LoanPaydownId]=S.[LoanPaydownId],[ManagementYield]=S.[ManagementYield],[OutstandingLoanRental_Amount]=S.[OutstandingLoanRental_Amount],[OutstandingLoanRental_Currency]=S.[OutstandingLoanRental_Currency],[PreQuoteContractId]=S.[PreQuoteContractId],[PrincipalBalance_Amount]=S.[PrincipalBalance_Amount],[PrincipalBalance_Currency]=S.[PrincipalBalance_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AmortProcessThroughDate],[AsOfDate],[CreatedById],[CreatedTime],[HasPrepaymentPenalty],[InterestBalance_Amount],[InterestBalance_Currency],[IsActive],[LoanAmount_Amount],[LoanAmount_Currency],[LoanFinanceId],[LoanPaydownId],[ManagementYield],[OutstandingLoanRental_Amount],[OutstandingLoanRental_Currency],[PreQuoteContractId],[PreQuoteId],[PrincipalBalance_Amount],[PrincipalBalance_Currency])
    VALUES (S.[AmortProcessThroughDate],S.[AsOfDate],S.[CreatedById],S.[CreatedTime],S.[HasPrepaymentPenalty],S.[InterestBalance_Amount],S.[InterestBalance_Currency],S.[IsActive],S.[LoanAmount_Amount],S.[LoanAmount_Currency],S.[LoanFinanceId],S.[LoanPaydownId],S.[ManagementYield],S.[OutstandingLoanRental_Amount],S.[OutstandingLoanRental_Currency],S.[PreQuoteContractId],S.[PreQuoteId],S.[PrincipalBalance_Amount],S.[PrincipalBalance_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

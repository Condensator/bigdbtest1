SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveFinancialStatementParameter]
(
 @val [dbo].[FinancialStatementParameter] READONLY
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
MERGE [dbo].[FinancialStatementParameters] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BankLoans]=S.[BankLoans],[Comment]=S.[Comment],[Currency]=S.[Currency],[Date]=S.[Date],[EBIT]=S.[EBIT],[Equity]=S.[Equity],[IsActive]=S.[IsActive],[LTLiabilities]=S.[LTLiabilities],[NetIncome]=S.[NetIncome],[PPE]=S.[PPE],[ReportingPeriod]=S.[ReportingPeriod],[Revenue]=S.[Revenue],[STLiabilities]=S.[STLiabilities],[STReceivables]=S.[STReceivables],[TotalAssets]=S.[TotalAssets],[TotalLiabilities]=S.[TotalLiabilities],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BankLoans],[Comment],[CreatedById],[CreatedTime],[CreditDecisionForCreditApplicationId],[Currency],[Date],[EBIT],[Equity],[IsActive],[LTLiabilities],[NetIncome],[PPE],[ReportingPeriod],[Revenue],[STLiabilities],[STReceivables],[TotalAssets],[TotalLiabilities])
    VALUES (S.[BankLoans],S.[Comment],S.[CreatedById],S.[CreatedTime],S.[CreditDecisionForCreditApplicationId],S.[Currency],S.[Date],S.[EBIT],S.[Equity],S.[IsActive],S.[LTLiabilities],S.[NetIncome],S.[PPE],S.[ReportingPeriod],S.[Revenue],S.[STLiabilities],S.[STReceivables],S.[TotalAssets],S.[TotalLiabilities])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLoanPaydownPricingCalculationParameter]
(
 @val [dbo].[LoanPaydownPricingCalculationParameter] READONLY
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
MERGE [dbo].[LoanPaydownPricingCalculationParameters] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[DailyFinanceAsOfDate]=S.[DailyFinanceAsOfDate],[DiscountRate]=S.[DiscountRate],[Factor]=S.[Factor],[InterestPenaltyAmount_Amount]=S.[InterestPenaltyAmount_Amount],[InterestPenaltyAmount_Currency]=S.[InterestPenaltyAmount_Currency],[NumberofTerms]=S.[NumberofTerms],[PaydownTemplateCalculationParameterId]=S.[PaydownTemplateCalculationParameterId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Amount_Amount],[Amount_Currency],[CreatedById],[CreatedTime],[DailyFinanceAsOfDate],[DiscountRate],[Factor],[InterestPenaltyAmount_Amount],[InterestPenaltyAmount_Currency],[LoanPaydownPricingDetailId],[NumberofTerms],[PaydownTemplateCalculationParameterId])
    VALUES (S.[Amount_Amount],S.[Amount_Currency],S.[CreatedById],S.[CreatedTime],S.[DailyFinanceAsOfDate],S.[DiscountRate],S.[Factor],S.[InterestPenaltyAmount_Amount],S.[InterestPenaltyAmount_Currency],S.[LoanPaydownPricingDetailId],S.[NumberofTerms],S.[PaydownTemplateCalculationParameterId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

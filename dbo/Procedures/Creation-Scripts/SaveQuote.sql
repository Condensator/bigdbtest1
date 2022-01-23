SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveQuote]
(
 @val [dbo].[Quote] READONLY
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
MERGE [dbo].[Quotes] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [CalculatedPaymentAmount_Amount]=S.[CalculatedPaymentAmount_Amount],[CalculatedPaymentAmount_Currency]=S.[CalculatedPaymentAmount_Currency],[CanUsePricingEngine]=S.[CanUsePricingEngine],[CurrencyId]=S.[CurrencyId],[DayCountConvention]=S.[DayCountConvention],[EstimatedBalloonAmount_Amount]=S.[EstimatedBalloonAmount_Amount],[EstimatedBalloonAmount_Currency]=S.[EstimatedBalloonAmount_Currency],[EstimatedFinancialAmount_Amount]=S.[EstimatedFinancialAmount_Amount],[EstimatedFinancialAmount_Currency]=S.[EstimatedFinancialAmount_Currency],[IsActive]=S.[IsActive],[IsAdvance]=S.[IsAdvance],[IsQuoteRequested]=S.[IsQuoteRequested],[IsStepPayment]=S.[IsStepPayment],[Number]=S.[Number],[PortfolioId]=S.[PortfolioId],[ProgramAssetTypeEOTOptionId]=S.[ProgramAssetTypeEOTOptionId],[ProgramAssetTypeFrequencyId]=S.[ProgramAssetTypeFrequencyId],[ProgramAssetTypeId]=S.[ProgramAssetTypeId],[ProgramAssetTypeTermId]=S.[ProgramAssetTypeTermId],[ProgramRateCardRate]=S.[ProgramRateCardRate],[ProgramRateCardYield]=S.[ProgramRateCardYield],[QuoteExpirationDate]=S.[QuoteExpirationDate],[QuotePaymentAmount_Amount]=S.[QuotePaymentAmount_Amount],[QuotePaymentAmount_Currency]=S.[QuotePaymentAmount_Currency],[RequestedPromotionId]=S.[RequestedPromotionId],[ResidualAmount_Amount]=S.[ResidualAmount_Amount],[ResidualAmount_Currency]=S.[ResidualAmount_Currency],[ResidualPercentage]=S.[ResidualPercentage],[StepPaymentStartDate]=S.[StepPaymentStartDate],[StepPercentage]=S.[StepPercentage],[StepPeriod]=S.[StepPeriod],[StubAdjustment]=S.[StubAdjustment],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CalculatedPaymentAmount_Amount],[CalculatedPaymentAmount_Currency],[CanUsePricingEngine],[CreatedById],[CreatedTime],[CurrencyId],[DayCountConvention],[EstimatedBalloonAmount_Amount],[EstimatedBalloonAmount_Currency],[EstimatedFinancialAmount_Amount],[EstimatedFinancialAmount_Currency],[IsActive],[IsAdvance],[IsQuoteRequested],[IsStepPayment],[Number],[PortfolioId],[ProgramAssetTypeEOTOptionId],[ProgramAssetTypeFrequencyId],[ProgramAssetTypeId],[ProgramAssetTypeTermId],[ProgramRateCardRate],[ProgramRateCardYield],[QuoteExpirationDate],[QuotePaymentAmount_Amount],[QuotePaymentAmount_Currency],[QuoteRequestId],[RequestedPromotionId],[ResidualAmount_Amount],[ResidualAmount_Currency],[ResidualPercentage],[StepPaymentStartDate],[StepPercentage],[StepPeriod],[StubAdjustment])
    VALUES (S.[CalculatedPaymentAmount_Amount],S.[CalculatedPaymentAmount_Currency],S.[CanUsePricingEngine],S.[CreatedById],S.[CreatedTime],S.[CurrencyId],S.[DayCountConvention],S.[EstimatedBalloonAmount_Amount],S.[EstimatedBalloonAmount_Currency],S.[EstimatedFinancialAmount_Amount],S.[EstimatedFinancialAmount_Currency],S.[IsActive],S.[IsAdvance],S.[IsQuoteRequested],S.[IsStepPayment],S.[Number],S.[PortfolioId],S.[ProgramAssetTypeEOTOptionId],S.[ProgramAssetTypeFrequencyId],S.[ProgramAssetTypeId],S.[ProgramAssetTypeTermId],S.[ProgramRateCardRate],S.[ProgramRateCardYield],S.[QuoteExpirationDate],S.[QuotePaymentAmount_Amount],S.[QuotePaymentAmount_Currency],S.[QuoteRequestId],S.[RequestedPromotionId],S.[ResidualAmount_Amount],S.[ResidualAmount_Currency],S.[ResidualPercentage],S.[StepPaymentStartDate],S.[StepPercentage],S.[StepPeriod],S.[StubAdjustment])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

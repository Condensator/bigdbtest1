SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveTaxDepAmortizationDetailForecast]
(
 @val [dbo].[TaxDepAmortizationDetailForecast] READONLY
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
MERGE [dbo].[TaxDepAmortizationDetailForecasts] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BonusDepreciationAmount_Amount]=S.[BonusDepreciationAmount_Amount],[BonusDepreciationAmount_Currency]=S.[BonusDepreciationAmount_Currency],[CurrencyId]=S.[CurrencyId],[DepreciationEndDate]=S.[DepreciationEndDate],[FirstYearTaxDepreciationForecast_Amount]=S.[FirstYearTaxDepreciationForecast_Amount],[FirstYearTaxDepreciationForecast_Currency]=S.[FirstYearTaxDepreciationForecast_Currency],[IsActive]=S.[IsActive],[LastYearTaxDepreciationForecast_Amount]=S.[LastYearTaxDepreciationForecast_Amount],[LastYearTaxDepreciationForecast_Currency]=S.[LastYearTaxDepreciationForecast_Currency],[TaxDepAmortizationId]=S.[TaxDepAmortizationId],[TaxDepreciationTemplateDetailId]=S.[TaxDepreciationTemplateDetailId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BonusDepreciationAmount_Amount],[BonusDepreciationAmount_Currency],[CreatedById],[CreatedTime],[CurrencyId],[DepreciationEndDate],[FirstYearTaxDepreciationForecast_Amount],[FirstYearTaxDepreciationForecast_Currency],[IsActive],[LastYearTaxDepreciationForecast_Amount],[LastYearTaxDepreciationForecast_Currency],[TaxDepAmortizationId],[TaxDepreciationTemplateDetailId])
    VALUES (S.[BonusDepreciationAmount_Amount],S.[BonusDepreciationAmount_Currency],S.[CreatedById],S.[CreatedTime],S.[CurrencyId],S.[DepreciationEndDate],S.[FirstYearTaxDepreciationForecast_Amount],S.[FirstYearTaxDepreciationForecast_Currency],S.[IsActive],S.[LastYearTaxDepreciationForecast_Amount],S.[LastYearTaxDepreciationForecast_Currency],S.[TaxDepAmortizationId],S.[TaxDepreciationTemplateDetailId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveTaxDepAmortizationDetail]
(
 @val [dbo].[TaxDepAmortizationDetail] READONLY
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
MERGE [dbo].[TaxDepAmortizationDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BeginNetBookValue_Amount]=S.[BeginNetBookValue_Amount],[BeginNetBookValue_Currency]=S.[BeginNetBookValue_Currency],[CurrencyId]=S.[CurrencyId],[DepreciationAmount_Amount]=S.[DepreciationAmount_Amount],[DepreciationAmount_Currency]=S.[DepreciationAmount_Currency],[DepreciationDate]=S.[DepreciationDate],[EndNetBookValue_Amount]=S.[EndNetBookValue_Amount],[EndNetBookValue_Currency]=S.[EndNetBookValue_Currency],[FiscalYear]=S.[FiscalYear],[IsAccounting]=S.[IsAccounting],[IsAdjustmentEntry]=S.[IsAdjustmentEntry],[IsGLPosted]=S.[IsGLPosted],[IsSchedule]=S.[IsSchedule],[TaxDepAmortizationDetailForecastId]=S.[TaxDepAmortizationDetailForecastId],[TaxDepreciationConventionId]=S.[TaxDepreciationConventionId],[TaxDepreciationTemplateDetailId]=S.[TaxDepreciationTemplateDetailId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BeginNetBookValue_Amount],[BeginNetBookValue_Currency],[CreatedById],[CreatedTime],[CurrencyId],[DepreciationAmount_Amount],[DepreciationAmount_Currency],[DepreciationDate],[EndNetBookValue_Amount],[EndNetBookValue_Currency],[FiscalYear],[IsAccounting],[IsAdjustmentEntry],[IsGLPosted],[IsSchedule],[TaxDepAmortizationDetailForecastId],[TaxDepAmortizationId],[TaxDepreciationConventionId],[TaxDepreciationTemplateDetailId])
    VALUES (S.[BeginNetBookValue_Amount],S.[BeginNetBookValue_Currency],S.[CreatedById],S.[CreatedTime],S.[CurrencyId],S.[DepreciationAmount_Amount],S.[DepreciationAmount_Currency],S.[DepreciationDate],S.[EndNetBookValue_Amount],S.[EndNetBookValue_Currency],S.[FiscalYear],S.[IsAccounting],S.[IsAdjustmentEntry],S.[IsGLPosted],S.[IsSchedule],S.[TaxDepAmortizationDetailForecastId],S.[TaxDepAmortizationId],S.[TaxDepreciationConventionId],S.[TaxDepreciationTemplateDetailId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

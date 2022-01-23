SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDeferredTax]
(
 @val [dbo].[DeferredTax] READONLY
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
MERGE [dbo].[DeferredTaxes] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccumDefTaxLiabBalance_Amount]=S.[AccumDefTaxLiabBalance_Amount],[AccumDefTaxLiabBalance_Currency]=S.[AccumDefTaxLiabBalance_Currency],[BookDepreciation_Amount]=S.[BookDepreciation_Amount],[BookDepreciation_Currency]=S.[BookDepreciation_Currency],[BookIncome_Amount]=S.[BookIncome_Amount],[BookIncome_Currency]=S.[BookIncome_Currency],[ContractId]=S.[ContractId],[Date]=S.[Date],[DefTaxLiabBalance_Amount]=S.[DefTaxLiabBalance_Amount],[DefTaxLiabBalance_Currency]=S.[DefTaxLiabBalance_Currency],[FiscalYear]=S.[FiscalYear],[GLTemplateId]=S.[GLTemplateId],[IncomeTaxExpense_Amount]=S.[IncomeTaxExpense_Amount],[IncomeTaxExpense_Currency]=S.[IncomeTaxExpense_Currency],[IncomeTaxPayable_Amount]=S.[IncomeTaxPayable_Amount],[IncomeTaxPayable_Currency]=S.[IncomeTaxPayable_Currency],[IsAccounting]=S.[IsAccounting],[IsGLPosted]=S.[IsGLPosted],[IsReprocess]=S.[IsReprocess],[IsScheduled]=S.[IsScheduled],[MTDDeferredTax_Amount]=S.[MTDDeferredTax_Amount],[MTDDeferredTax_Currency]=S.[MTDDeferredTax_Currency],[TaxableIncomeBook_Amount]=S.[TaxableIncomeBook_Amount],[TaxableIncomeBook_Currency]=S.[TaxableIncomeBook_Currency],[TaxableIncomeTax_Amount]=S.[TaxableIncomeTax_Amount],[TaxableIncomeTax_Currency]=S.[TaxableIncomeTax_Currency],[TaxBookName]=S.[TaxBookName],[TaxDepreciation_Amount]=S.[TaxDepreciation_Amount],[TaxDepreciation_Currency]=S.[TaxDepreciation_Currency],[TaxDepreciationSystem]=S.[TaxDepreciationSystem],[TaxIncome_Amount]=S.[TaxIncome_Amount],[TaxIncome_Currency]=S.[TaxIncome_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[YTDDeferredTax_Amount]=S.[YTDDeferredTax_Amount],[YTDDeferredTax_Currency]=S.[YTDDeferredTax_Currency]
WHEN NOT MATCHED THEN
	INSERT ([AccumDefTaxLiabBalance_Amount],[AccumDefTaxLiabBalance_Currency],[BookDepreciation_Amount],[BookDepreciation_Currency],[BookIncome_Amount],[BookIncome_Currency],[ContractId],[CreatedById],[CreatedTime],[Date],[DefTaxLiabBalance_Amount],[DefTaxLiabBalance_Currency],[FiscalYear],[GLTemplateId],[IncomeTaxExpense_Amount],[IncomeTaxExpense_Currency],[IncomeTaxPayable_Amount],[IncomeTaxPayable_Currency],[IsAccounting],[IsGLPosted],[IsReprocess],[IsScheduled],[MTDDeferredTax_Amount],[MTDDeferredTax_Currency],[TaxableIncomeBook_Amount],[TaxableIncomeBook_Currency],[TaxableIncomeTax_Amount],[TaxableIncomeTax_Currency],[TaxBookName],[TaxDepreciation_Amount],[TaxDepreciation_Currency],[TaxDepreciationSystem],[TaxIncome_Amount],[TaxIncome_Currency],[YTDDeferredTax_Amount],[YTDDeferredTax_Currency])
    VALUES (S.[AccumDefTaxLiabBalance_Amount],S.[AccumDefTaxLiabBalance_Currency],S.[BookDepreciation_Amount],S.[BookDepreciation_Currency],S.[BookIncome_Amount],S.[BookIncome_Currency],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[Date],S.[DefTaxLiabBalance_Amount],S.[DefTaxLiabBalance_Currency],S.[FiscalYear],S.[GLTemplateId],S.[IncomeTaxExpense_Amount],S.[IncomeTaxExpense_Currency],S.[IncomeTaxPayable_Amount],S.[IncomeTaxPayable_Currency],S.[IsAccounting],S.[IsGLPosted],S.[IsReprocess],S.[IsScheduled],S.[MTDDeferredTax_Amount],S.[MTDDeferredTax_Currency],S.[TaxableIncomeBook_Amount],S.[TaxableIncomeBook_Currency],S.[TaxableIncomeTax_Amount],S.[TaxableIncomeTax_Currency],S.[TaxBookName],S.[TaxDepreciation_Amount],S.[TaxDepreciation_Currency],S.[TaxDepreciationSystem],S.[TaxIncome_Amount],S.[TaxIncome_Currency],S.[YTDDeferredTax_Amount],S.[YTDDeferredTax_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAssetSale]
(
 @val [dbo].[AssetSale] READONLY
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
MERGE [dbo].[AssetSales] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[AssetSaleGLTemplateId]=S.[AssetSaleGLTemplateId],[AssetSaleReceivableCodeId]=S.[AssetSaleReceivableCodeId],[AssetSaleTaxGLTemplateId]=S.[AssetSaleTaxGLTemplateId],[BillToId]=S.[BillToId],[BookGainLossAmount_Amount]=S.[BookGainLossAmount_Amount],[BookGainLossAmount_Currency]=S.[BookGainLossAmount_Currency],[BranchId]=S.[BranchId],[BuyerId]=S.[BuyerId],[CashBasedAssetSaleReceivableCodeId]=S.[CashBasedAssetSaleReceivableCodeId],[Comment]=S.[Comment],[CostCenterId]=S.[CostCenterId],[CountryId]=S.[CountryId],[CurrencyId]=S.[CurrencyId],[CustomerPurchaseOrderNumber]=S.[CustomerPurchaseOrderNumber],[Discounts_Amount]=S.[Discounts_Amount],[Discounts_Currency]=S.[Discounts_Currency],[DueDate]=S.[DueDate],[GLConfigurationId]=S.[GLConfigurationId],[InstrumentTypeId]=S.[InstrumentTypeId],[InvoiceComment]=S.[InvoiceComment],[InvoiceFile_Content]=S.[InvoiceFile_Content],[InvoiceFile_Source]=S.[InvoiceFile_Source],[InvoiceFile_Type]=S.[InvoiceFile_Type],[InvoiceNumber]=S.[InvoiceNumber],[InvoicePreference]=S.[InvoicePreference],[InvoiceReceivableGroupingOption]=S.[InvoiceReceivableGroupingOption],[IsAllowTradeIn]=S.[IsAllowTradeIn],[IsAssignAtAssetLevel]=S.[IsAssignAtAssetLevel],[IsCompletePayableInvoice]=S.[IsCompletePayableInvoice],[IsGenerateInstallmentPerformed]=S.[IsGenerateInstallmentPerformed],[IsInstallmentQuote]=S.[IsInstallmentQuote],[IsPayableNetoff]=S.[IsPayableNetoff],[IsTaxAssessed]=S.[IsTaxAssessed],[LegalEntityId]=S.[LegalEntityId],[LineofBusinessId]=S.[LineofBusinessId],[NetSaleAmount_Amount]=S.[NetSaleAmount_Amount],[NetSaleAmount_Currency]=S.[NetSaleAmount_Currency],[NumberofInstallment]=S.[NumberofInstallment],[PayableCodeId]=S.[PayableCodeId],[PayableInvoiceId]=S.[PayableInvoiceId],[PayableWithholdingTaxRate]=S.[PayableWithholdingTaxRate],[PostDate]=S.[PostDate],[RemitToId]=S.[RemitToId],[RetainedDiscounts_Amount]=S.[RetainedDiscounts_Amount],[RetainedDiscounts_Currency]=S.[RetainedDiscounts_Currency],[SaleGLJournalId]=S.[SaleGLJournalId],[SaleOfInvestorAsset]=S.[SaleOfInvestorAsset],[Status]=S.[Status],[TaxAmount_Amount]=S.[TaxAmount_Amount],[TaxAmount_Currency]=S.[TaxAmount_Currency],[TaxDepDisposalTemplateId]=S.[TaxDepDisposalTemplateId],[TaxGainLossAmount_Amount]=S.[TaxGainLossAmount_Amount],[TaxGainLossAmount_Currency]=S.[TaxGainLossAmount_Currency],[TaxLocationId]=S.[TaxLocationId],[TransactionDate]=S.[TransactionDate],[TransactionNumber]=S.[TransactionNumber],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Amount_Amount],[Amount_Currency],[AssetSaleGLTemplateId],[AssetSaleReceivableCodeId],[AssetSaleTaxGLTemplateId],[BillToId],[BookGainLossAmount_Amount],[BookGainLossAmount_Currency],[BranchId],[BuyerId],[CashBasedAssetSaleReceivableCodeId],[Comment],[CostCenterId],[CountryId],[CreatedById],[CreatedTime],[CurrencyId],[CustomerPurchaseOrderNumber],[Discounts_Amount],[Discounts_Currency],[DueDate],[GLConfigurationId],[InstrumentTypeId],[InvoiceComment],[InvoiceFile_Content],[InvoiceFile_Source],[InvoiceFile_Type],[InvoiceNumber],[InvoicePreference],[InvoiceReceivableGroupingOption],[IsAllowTradeIn],[IsAssignAtAssetLevel],[IsCompletePayableInvoice],[IsGenerateInstallmentPerformed],[IsInstallmentQuote],[IsPayableNetoff],[IsTaxAssessed],[LegalEntityId],[LineofBusinessId],[NetSaleAmount_Amount],[NetSaleAmount_Currency],[NumberofInstallment],[PayableCodeId],[PayableInvoiceId],[PayableWithholdingTaxRate],[PostDate],[RemitToId],[RetainedDiscounts_Amount],[RetainedDiscounts_Currency],[SaleGLJournalId],[SaleOfInvestorAsset],[Status],[TaxAmount_Amount],[TaxAmount_Currency],[TaxDepDisposalTemplateId],[TaxGainLossAmount_Amount],[TaxGainLossAmount_Currency],[TaxLocationId],[TransactionDate],[TransactionNumber])
    VALUES (S.[Amount_Amount],S.[Amount_Currency],S.[AssetSaleGLTemplateId],S.[AssetSaleReceivableCodeId],S.[AssetSaleTaxGLTemplateId],S.[BillToId],S.[BookGainLossAmount_Amount],S.[BookGainLossAmount_Currency],S.[BranchId],S.[BuyerId],S.[CashBasedAssetSaleReceivableCodeId],S.[Comment],S.[CostCenterId],S.[CountryId],S.[CreatedById],S.[CreatedTime],S.[CurrencyId],S.[CustomerPurchaseOrderNumber],S.[Discounts_Amount],S.[Discounts_Currency],S.[DueDate],S.[GLConfigurationId],S.[InstrumentTypeId],S.[InvoiceComment],S.[InvoiceFile_Content],S.[InvoiceFile_Source],S.[InvoiceFile_Type],S.[InvoiceNumber],S.[InvoicePreference],S.[InvoiceReceivableGroupingOption],S.[IsAllowTradeIn],S.[IsAssignAtAssetLevel],S.[IsCompletePayableInvoice],S.[IsGenerateInstallmentPerformed],S.[IsInstallmentQuote],S.[IsPayableNetoff],S.[IsTaxAssessed],S.[LegalEntityId],S.[LineofBusinessId],S.[NetSaleAmount_Amount],S.[NetSaleAmount_Currency],S.[NumberofInstallment],S.[PayableCodeId],S.[PayableInvoiceId],S.[PayableWithholdingTaxRate],S.[PostDate],S.[RemitToId],S.[RetainedDiscounts_Amount],S.[RetainedDiscounts_Currency],S.[SaleGLJournalId],S.[SaleOfInvestorAsset],S.[Status],S.[TaxAmount_Amount],S.[TaxAmount_Currency],S.[TaxDepDisposalTemplateId],S.[TaxGainLossAmount_Amount],S.[TaxGainLossAmount_Currency],S.[TaxLocationId],S.[TransactionDate],S.[TransactionNumber])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

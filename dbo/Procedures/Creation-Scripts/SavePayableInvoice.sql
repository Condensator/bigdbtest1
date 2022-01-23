SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePayableInvoice]
(
 @val [dbo].[PayableInvoice] READONLY
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
MERGE [dbo].[PayableInvoices] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Alias]=S.[Alias],[AllowCreateAssets]=S.[AllowCreateAssets],[AssetCostPayableCodeId]=S.[AssetCostPayableCodeId],[AssetCostWithholdingTaxRate]=S.[AssetCostWithholdingTaxRate],[Balance_Amount]=S.[Balance_Amount],[Balance_Currency]=S.[Balance_Currency],[BranchId]=S.[BranchId],[Comment]=S.[Comment],[ContractCurrencyId]=S.[ContractCurrencyId],[ContractId]=S.[ContractId],[ContractType]=S.[ContractType],[CostCenterId]=S.[CostCenterId],[CountryId]=S.[CountryId],[CurrencyId]=S.[CurrencyId],[CustomerId]=S.[CustomerId],[CustomerNumber]=S.[CustomerNumber],[DisbursementWithholdingTaxRate]=S.[DisbursementWithholdingTaxRate],[DueDate]=S.[DueDate],[GLJournalId]=S.[GLJournalId],[InitialExchangeRate]=S.[InitialExchangeRate],[InstrumentTypeId]=S.[InstrumentTypeId],[InvoiceDate]=S.[InvoiceDate],[InvoiceNumber]=S.[InvoiceNumber],[InvoiceTotal_Amount]=S.[InvoiceTotal_Amount],[InvoiceTotal_Currency]=S.[InvoiceTotal_Currency],[IsAttachedInTransaction]=S.[IsAttachedInTransaction],[IsForeignCurrency]=S.[IsForeignCurrency],[IsInvalidPayableInvoice]=S.[IsInvalidPayableInvoice],[IsOriginalInvoice]=S.[IsOriginalInvoice],[IsOtherCostDistributionRequired]=S.[IsOtherCostDistributionRequired],[IsSalesLeaseBack]=S.[IsSalesLeaseBack],[IsSystemGenerated]=S.[IsSystemGenerated],[LegalEntityId]=S.[LegalEntityId],[LineofBusinessId]=S.[LineofBusinessId],[NumberOfAssets]=S.[NumberOfAssets],[OriginalExchangeRate]=S.[OriginalExchangeRate],[OriginalInvoiceDate]=S.[OriginalInvoiceDate],[OriginalInvoiceNumber]=S.[OriginalInvoiceNumber],[ParentPayableInvoiceId]=S.[ParentPayableInvoiceId],[PayableInvoiceDocumentInstance_Content]=S.[PayableInvoiceDocumentInstance_Content],[PayableInvoiceDocumentInstance_Source]=S.[PayableInvoiceDocumentInstance_Source],[PayableInvoiceDocumentInstance_Type]=S.[PayableInvoiceDocumentInstance_Type],[PostDate]=S.[PostDate],[RemitToId]=S.[RemitToId],[ReversalGLJournalId]=S.[ReversalGLJournalId],[Revise]=S.[Revise],[SourceTransaction]=S.[SourceTransaction],[Status]=S.[Status],[TotalAssetCost_Amount]=S.[TotalAssetCost_Amount],[TotalAssetCost_Currency]=S.[TotalAssetCost_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VendorId]=S.[VendorId],[VendorNumber]=S.[VendorNumber]
WHEN NOT MATCHED THEN
	INSERT ([Alias],[AllowCreateAssets],[AssetCostPayableCodeId],[AssetCostWithholdingTaxRate],[Balance_Amount],[Balance_Currency],[BranchId],[Comment],[ContractCurrencyId],[ContractId],[ContractType],[CostCenterId],[CountryId],[CreatedById],[CreatedTime],[CurrencyId],[CustomerId],[CustomerNumber],[DisbursementWithholdingTaxRate],[DueDate],[GLJournalId],[InitialExchangeRate],[InstrumentTypeId],[InvoiceDate],[InvoiceNumber],[InvoiceTotal_Amount],[InvoiceTotal_Currency],[IsAttachedInTransaction],[IsForeignCurrency],[IsInvalidPayableInvoice],[IsOriginalInvoice],[IsOtherCostDistributionRequired],[IsSalesLeaseBack],[IsSystemGenerated],[LegalEntityId],[LineofBusinessId],[NumberOfAssets],[OriginalExchangeRate],[OriginalInvoiceDate],[OriginalInvoiceNumber],[ParentPayableInvoiceId],[PayableInvoiceDocumentInstance_Content],[PayableInvoiceDocumentInstance_Source],[PayableInvoiceDocumentInstance_Type],[PostDate],[RemitToId],[ReversalGLJournalId],[Revise],[SourceTransaction],[Status],[TotalAssetCost_Amount],[TotalAssetCost_Currency],[VendorId],[VendorNumber])
    VALUES (S.[Alias],S.[AllowCreateAssets],S.[AssetCostPayableCodeId],S.[AssetCostWithholdingTaxRate],S.[Balance_Amount],S.[Balance_Currency],S.[BranchId],S.[Comment],S.[ContractCurrencyId],S.[ContractId],S.[ContractType],S.[CostCenterId],S.[CountryId],S.[CreatedById],S.[CreatedTime],S.[CurrencyId],S.[CustomerId],S.[CustomerNumber],S.[DisbursementWithholdingTaxRate],S.[DueDate],S.[GLJournalId],S.[InitialExchangeRate],S.[InstrumentTypeId],S.[InvoiceDate],S.[InvoiceNumber],S.[InvoiceTotal_Amount],S.[InvoiceTotal_Currency],S.[IsAttachedInTransaction],S.[IsForeignCurrency],S.[IsInvalidPayableInvoice],S.[IsOriginalInvoice],S.[IsOtherCostDistributionRequired],S.[IsSalesLeaseBack],S.[IsSystemGenerated],S.[LegalEntityId],S.[LineofBusinessId],S.[NumberOfAssets],S.[OriginalExchangeRate],S.[OriginalInvoiceDate],S.[OriginalInvoiceNumber],S.[ParentPayableInvoiceId],S.[PayableInvoiceDocumentInstance_Content],S.[PayableInvoiceDocumentInstance_Source],S.[PayableInvoiceDocumentInstance_Type],S.[PostDate],S.[RemitToId],S.[ReversalGLJournalId],S.[Revise],S.[SourceTransaction],S.[Status],S.[TotalAssetCost_Amount],S.[TotalAssetCost_Currency],S.[VendorId],S.[VendorNumber])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

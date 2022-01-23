SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReversalReceivableDetail_Extract]
(
 @val [dbo].[ReversalReceivableDetail_Extract] READONLY
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
MERGE [dbo].[ReversalReceivableDetail_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AcquisitionLocationId]=S.[AcquisitionLocationId],[AmountBilledToDate]=S.[AmountBilledToDate],[AssetId]=S.[AssetId],[AssetLocationId]=S.[AssetLocationId],[AssetLocationRowVersion]=S.[AssetLocationRowVersion],[AssetType]=S.[AssetType],[BusCode]=S.[BusCode],[Company]=S.[Company],[ContractId]=S.[ContractId],[ContractType]=S.[ContractType],[ContractTypeValue]=S.[ContractTypeValue],[Cost]=S.[Cost],[Currency]=S.[Currency],[CustomerId]=S.[CustomerId],[CustomerName]=S.[CustomerName],[DiscountingId]=S.[DiscountingId],[DueDate]=S.[DueDate],[EntityType]=S.[EntityType],[ErrorCode]=S.[ErrorCode],[ExtendedPrice]=S.[ExtendedPrice],[FairMarketValue]=S.[FairMarketValue],[FromState]=S.[FromState],[GLFinancialOpenPeriodFromDate]=S.[GLFinancialOpenPeriodFromDate],[GLFinancialOpenPeriodToDate]=S.[GLFinancialOpenPeriodToDate],[IsAssessSalesTaxAtSKULevel]=S.[IsAssessSalesTaxAtSKULevel],[IsCashPosted]=S.[IsCashPosted],[IsExemptAtAsset]=S.[IsExemptAtAsset],[IsExemptAtLease]=S.[IsExemptAtLease],[IsExemptAtReceivableCode]=S.[IsExemptAtReceivableCode],[IsExemptAtSundry]=S.[IsExemptAtSundry],[IsInvoiced]=S.[IsInvoiced],[IsRental]=S.[IsRental],[IsVertexSupported]=S.[IsVertexSupported],[JobStepInstanceId]=S.[JobStepInstanceId],[LeaseTerm]=S.[LeaseTerm],[LeaseType]=S.[LeaseType],[LeaseUniqueId]=S.[LeaseUniqueId],[LegalEntityId]=S.[LegalEntityId],[LegalEntityName]=S.[LegalEntityName],[LocationId]=S.[LocationId],[PaymentScheduleId]=S.[PaymentScheduleId],[Product]=S.[Product],[ReceivableCodeId]=S.[ReceivableCodeId],[ReceivableDetailId]=S.[ReceivableDetailId],[ReceivableDetailRowVersion]=S.[ReceivableDetailRowVersion],[ReceivableId]=S.[ReceivableId],[ReceivableTaxDetailId]=S.[ReceivableTaxDetailId],[ReceivableTaxDetailRowVersion]=S.[ReceivableTaxDetailRowVersion],[ReceivableTaxId]=S.[ReceivableTaxId],[ReceivableTaxRowVersion]=S.[ReceivableTaxRowVersion],[ReceivableTaxType]=S.[ReceivableTaxType],[ReceivableType]=S.[ReceivableType],[SalesTaxRemittanceResponsibility]=S.[SalesTaxRemittanceResponsibility],[SundryReceivableCode]=S.[SundryReceivableCode],[TaxAreaId]=S.[TaxAreaId],[TaxBasisType]=S.[TaxBasisType],[TitleTransferCode]=S.[TitleTransferCode],[ToState]=S.[ToState],[TransactionCode]=S.[TransactionCode],[TransactionType]=S.[TransactionType],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UpfrontTaxAssessedInLegacySystem]=S.[UpfrontTaxAssessedInLegacySystem],[UpfrontTaxSundryId]=S.[UpfrontTaxSundryId],[VoucherNumbers]=S.[VoucherNumbers]
WHEN NOT MATCHED THEN
	INSERT ([AcquisitionLocationId],[AmountBilledToDate],[AssetId],[AssetLocationId],[AssetLocationRowVersion],[AssetType],[BusCode],[Company],[ContractId],[ContractType],[ContractTypeValue],[Cost],[CreatedById],[CreatedTime],[Currency],[CustomerId],[CustomerName],[DiscountingId],[DueDate],[EntityType],[ErrorCode],[ExtendedPrice],[FairMarketValue],[FromState],[GLFinancialOpenPeriodFromDate],[GLFinancialOpenPeriodToDate],[IsAssessSalesTaxAtSKULevel],[IsCashPosted],[IsExemptAtAsset],[IsExemptAtLease],[IsExemptAtReceivableCode],[IsExemptAtSundry],[IsInvoiced],[IsRental],[IsVertexSupported],[JobStepInstanceId],[LeaseTerm],[LeaseType],[LeaseUniqueId],[LegalEntityId],[LegalEntityName],[LocationId],[PaymentScheduleId],[Product],[ReceivableCodeId],[ReceivableDetailId],[ReceivableDetailRowVersion],[ReceivableId],[ReceivableTaxDetailId],[ReceivableTaxDetailRowVersion],[ReceivableTaxId],[ReceivableTaxRowVersion],[ReceivableTaxType],[ReceivableType],[SalesTaxRemittanceResponsibility],[SundryReceivableCode],[TaxAreaId],[TaxBasisType],[TitleTransferCode],[ToState],[TransactionCode],[TransactionType],[UpfrontTaxAssessedInLegacySystem],[UpfrontTaxSundryId],[VoucherNumbers])
    VALUES (S.[AcquisitionLocationId],S.[AmountBilledToDate],S.[AssetId],S.[AssetLocationId],S.[AssetLocationRowVersion],S.[AssetType],S.[BusCode],S.[Company],S.[ContractId],S.[ContractType],S.[ContractTypeValue],S.[Cost],S.[CreatedById],S.[CreatedTime],S.[Currency],S.[CustomerId],S.[CustomerName],S.[DiscountingId],S.[DueDate],S.[EntityType],S.[ErrorCode],S.[ExtendedPrice],S.[FairMarketValue],S.[FromState],S.[GLFinancialOpenPeriodFromDate],S.[GLFinancialOpenPeriodToDate],S.[IsAssessSalesTaxAtSKULevel],S.[IsCashPosted],S.[IsExemptAtAsset],S.[IsExemptAtLease],S.[IsExemptAtReceivableCode],S.[IsExemptAtSundry],S.[IsInvoiced],S.[IsRental],S.[IsVertexSupported],S.[JobStepInstanceId],S.[LeaseTerm],S.[LeaseType],S.[LeaseUniqueId],S.[LegalEntityId],S.[LegalEntityName],S.[LocationId],S.[PaymentScheduleId],S.[Product],S.[ReceivableCodeId],S.[ReceivableDetailId],S.[ReceivableDetailRowVersion],S.[ReceivableId],S.[ReceivableTaxDetailId],S.[ReceivableTaxDetailRowVersion],S.[ReceivableTaxId],S.[ReceivableTaxRowVersion],S.[ReceivableTaxType],S.[ReceivableType],S.[SalesTaxRemittanceResponsibility],S.[SundryReceivableCode],S.[TaxAreaId],S.[TaxBasisType],S.[TitleTransferCode],S.[ToState],S.[TransactionCode],S.[TransactionType],S.[UpfrontTaxAssessedInLegacySystem],S.[UpfrontTaxSundryId],S.[VoucherNumbers])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

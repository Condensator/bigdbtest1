SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveSalesTaxReceivableDetail_Extract]
(
 @val [dbo].[SalesTaxReceivableDetail_Extract] READONLY
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
MERGE [dbo].[SalesTaxReceivableDetail_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AdjustmentBasisReceivableDetailId]=S.[AdjustmentBasisReceivableDetailId],[AmountBilledToDate]=S.[AmountBilledToDate],[AssetId]=S.[AssetId],[AssetLocationId]=S.[AssetLocationId],[ContractId]=S.[ContractId],[Currency]=S.[Currency],[CustomerId]=S.[CustomerId],[CustomerLocationId]=S.[CustomerLocationId],[DiscountingId]=S.[DiscountingId],[EntityType]=S.[EntityType],[ExtendedPrice]=S.[ExtendedPrice],[GLTemplateId]=S.[GLTemplateId],[InvalidErrorCode]=S.[InvalidErrorCode],[IsAssessSalesTaxAtSKULevel]=S.[IsAssessSalesTaxAtSKULevel],[IsExemptAtSundry]=S.[IsExemptAtSundry],[IsOriginalReceivableDetailTaxAssessed]=S.[IsOriginalReceivableDetailTaxAssessed],[IsRenewal]=S.[IsRenewal],[IsVertexSupported]=S.[IsVertexSupported],[JobStepInstanceId]=S.[JobStepInstanceId],[LeaseAssetId]=S.[LeaseAssetId],[LegalEntityId]=S.[LegalEntityId],[LegalEntityName]=S.[LegalEntityName],[LegalEntityTaxRemittancePreference]=S.[LegalEntityTaxRemittancePreference],[LocationId]=S.[LocationId],[PaymentScheduleId]=S.[PaymentScheduleId],[PreviousLocationId]=S.[PreviousLocationId],[ReceivableCodeId]=S.[ReceivableCodeId],[ReceivableDetailId]=S.[ReceivableDetailId],[ReceivableDueDate]=S.[ReceivableDueDate],[ReceivableId]=S.[ReceivableId],[ReceivableTaxType]=S.[ReceivableTaxType],[SourceId]=S.[SourceId],[SourceTable]=S.[SourceTable],[StateId]=S.[StateId],[TaxPayer]=S.[TaxPayer],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AdjustmentBasisReceivableDetailId],[AmountBilledToDate],[AssetId],[AssetLocationId],[ContractId],[CreatedById],[CreatedTime],[Currency],[CustomerId],[CustomerLocationId],[DiscountingId],[EntityType],[ExtendedPrice],[GLTemplateId],[InvalidErrorCode],[IsAssessSalesTaxAtSKULevel],[IsExemptAtSundry],[IsOriginalReceivableDetailTaxAssessed],[IsRenewal],[IsVertexSupported],[JobStepInstanceId],[LeaseAssetId],[LegalEntityId],[LegalEntityName],[LegalEntityTaxRemittancePreference],[LocationId],[PaymentScheduleId],[PreviousLocationId],[ReceivableCodeId],[ReceivableDetailId],[ReceivableDueDate],[ReceivableId],[ReceivableTaxType],[SourceId],[SourceTable],[StateId],[TaxPayer])
    VALUES (S.[AdjustmentBasisReceivableDetailId],S.[AmountBilledToDate],S.[AssetId],S.[AssetLocationId],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[Currency],S.[CustomerId],S.[CustomerLocationId],S.[DiscountingId],S.[EntityType],S.[ExtendedPrice],S.[GLTemplateId],S.[InvalidErrorCode],S.[IsAssessSalesTaxAtSKULevel],S.[IsExemptAtSundry],S.[IsOriginalReceivableDetailTaxAssessed],S.[IsRenewal],S.[IsVertexSupported],S.[JobStepInstanceId],S.[LeaseAssetId],S.[LegalEntityId],S.[LegalEntityName],S.[LegalEntityTaxRemittancePreference],S.[LocationId],S.[PaymentScheduleId],S.[PreviousLocationId],S.[ReceivableCodeId],S.[ReceivableDetailId],S.[ReceivableDueDate],S.[ReceivableId],S.[ReceivableTaxType],S.[SourceId],S.[SourceTable],S.[StateId],S.[TaxPayer])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

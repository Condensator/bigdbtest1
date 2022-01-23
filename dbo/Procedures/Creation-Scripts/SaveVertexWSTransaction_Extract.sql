SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveVertexWSTransaction_Extract]
(
 @val [dbo].[VertexWSTransaction_Extract] READONLY
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
MERGE [dbo].[VertexWSTransaction_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AcquisitionLocationCity]=S.[AcquisitionLocationCity],[AcquisitionLocationCountry]=S.[AcquisitionLocationCountry],[AcquisitionLocationMainDivision]=S.[AcquisitionLocationMainDivision],[AcquisitionLocationTaxAreaId]=S.[AcquisitionLocationTaxAreaId],[AmountBilledToDate]=S.[AmountBilledToDate],[AssetCatalogNumber]=S.[AssetCatalogNumber],[AssetId]=S.[AssetId],[AssetLocationId]=S.[AssetLocationId],[AssetSerialOrVIN]=S.[AssetSerialOrVIN],[AssetSKUId]=S.[AssetSKUId],[AssetType]=S.[AssetType],[AssetUsageCondition]=S.[AssetUsageCondition],[BatchStatus]=S.[BatchStatus],[BusCode]=S.[BusCode],[City]=S.[City],[CommencementDate]=S.[CommencementDate],[CompanyCode]=S.[CompanyCode],[ContractTypeName]=S.[ContractTypeName],[Cost]=S.[Cost],[Country]=S.[Country],[CurrencyCode]=S.[CurrencyCode],[CustomerClass]=S.[CustomerClass],[CustomerCode]=S.[CustomerCode],[DueDate]=S.[DueDate],[ExtendedPrice]=S.[ExtendedPrice],[FairMarketValue]=S.[FairMarketValue],[FromState]=S.[FromState],[GLTemplateId]=S.[GLTemplateId],[GrossVehicleWeight]=S.[GrossVehicleWeight],[HorsePower]=S.[HorsePower],[IsCapitalizedFirstRealAsset]=S.[IsCapitalizedFirstRealAsset],[IsCapitalizedRealAsset]=S.[IsCapitalizedRealAsset],[IsCapitalizedSalesTaxAsset]=S.[IsCapitalizedSalesTaxAsset],[IsElectronicallyDelivered]=S.[IsElectronicallyDelivered],[IsExemptAtAsset]=S.[IsExemptAtAsset],[IsExemptAtAssetSKU]=S.[IsExemptAtAssetSKU],[IsExemptAtReceivableCode]=S.[IsExemptAtReceivableCode],[IsExemptAtSundry]=S.[IsExemptAtSundry],[IsPrepaidUpfrontTax]=S.[IsPrepaidUpfrontTax],[IsSKU]=S.[IsSKU],[IsSyndicated]=S.[IsSyndicated],[IsTaxExempt]=S.[IsTaxExempt],[JobStepInstanceId]=S.[JobStepInstanceId],[LeaseUniqueID]=S.[LeaseUniqueID],[LegalEntityId]=S.[LegalEntityId],[LienCredit]=S.[LienCredit],[LineItemNumber]=S.[LineItemNumber],[LocationCode]=S.[LocationCode],[LocationEffectiveDate]=S.[LocationEffectiveDate],[LocationId]=S.[LocationId],[LocationStatus]=S.[LocationStatus],[MainDivision]=S.[MainDivision],[MaturityDate]=S.[MaturityDate],[Product]=S.[Product],[ReceivableDetailId]=S.[ReceivableDetailId],[ReceivableId]=S.[ReceivableId],[ReceivableSKUId]=S.[ReceivableSKUId],[ReciprocityAmount]=S.[ReciprocityAmount],[SaleLeasebackCode]=S.[SaleLeasebackCode],[SalesTaxExemptionLevel]=S.[SalesTaxExemptionLevel],[SalesTaxRemittanceResponsibility]=S.[SalesTaxRemittanceResponsibility],[ShortLeaseType]=S.[ShortLeaseType],[SundryReceivableCode]=S.[SundryReceivableCode],[TaskChunkServiceInstanceId]=S.[TaskChunkServiceInstanceId],[TaxAreaId]=S.[TaxAreaId],[TaxBasis]=S.[TaxBasis],[TaxExemptReason]=S.[TaxExemptReason],[TaxReceivableName]=S.[TaxReceivableName],[TaxRemittanceType]=S.[TaxRemittanceType],[Term]=S.[Term],[TitleTransferCode]=S.[TitleTransferCode],[ToState]=S.[ToState],[TransactionType]=S.[TransactionType],[TransCode]=S.[TransCode],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UpfrontTaxAssessedInLegacySystem]=S.[UpfrontTaxAssessedInLegacySystem],[Usage]=S.[Usage]
WHEN NOT MATCHED THEN
	INSERT ([AcquisitionLocationCity],[AcquisitionLocationCountry],[AcquisitionLocationMainDivision],[AcquisitionLocationTaxAreaId],[AmountBilledToDate],[AssetCatalogNumber],[AssetId],[AssetLocationId],[AssetSerialOrVIN],[AssetSKUId],[AssetType],[AssetUsageCondition],[BatchStatus],[BusCode],[City],[CommencementDate],[CompanyCode],[ContractTypeName],[Cost],[Country],[CreatedById],[CreatedTime],[CurrencyCode],[CustomerClass],[CustomerCode],[DueDate],[ExtendedPrice],[FairMarketValue],[FromState],[GLTemplateId],[GrossVehicleWeight],[HorsePower],[IsCapitalizedFirstRealAsset],[IsCapitalizedRealAsset],[IsCapitalizedSalesTaxAsset],[IsElectronicallyDelivered],[IsExemptAtAsset],[IsExemptAtAssetSKU],[IsExemptAtReceivableCode],[IsExemptAtSundry],[IsPrepaidUpfrontTax],[IsSKU],[IsSyndicated],[IsTaxExempt],[JobStepInstanceId],[LeaseUniqueID],[LegalEntityId],[LienCredit],[LineItemNumber],[LocationCode],[LocationEffectiveDate],[LocationId],[LocationStatus],[MainDivision],[MaturityDate],[Product],[ReceivableDetailId],[ReceivableId],[ReceivableSKUId],[ReciprocityAmount],[SaleLeasebackCode],[SalesTaxExemptionLevel],[SalesTaxRemittanceResponsibility],[ShortLeaseType],[SundryReceivableCode],[TaskChunkServiceInstanceId],[TaxAreaId],[TaxBasis],[TaxExemptReason],[TaxReceivableName],[TaxRemittanceType],[Term],[TitleTransferCode],[ToState],[TransactionType],[TransCode],[UpfrontTaxAssessedInLegacySystem],[Usage])
    VALUES (S.[AcquisitionLocationCity],S.[AcquisitionLocationCountry],S.[AcquisitionLocationMainDivision],S.[AcquisitionLocationTaxAreaId],S.[AmountBilledToDate],S.[AssetCatalogNumber],S.[AssetId],S.[AssetLocationId],S.[AssetSerialOrVIN],S.[AssetSKUId],S.[AssetType],S.[AssetUsageCondition],S.[BatchStatus],S.[BusCode],S.[City],S.[CommencementDate],S.[CompanyCode],S.[ContractTypeName],S.[Cost],S.[Country],S.[CreatedById],S.[CreatedTime],S.[CurrencyCode],S.[CustomerClass],S.[CustomerCode],S.[DueDate],S.[ExtendedPrice],S.[FairMarketValue],S.[FromState],S.[GLTemplateId],S.[GrossVehicleWeight],S.[HorsePower],S.[IsCapitalizedFirstRealAsset],S.[IsCapitalizedRealAsset],S.[IsCapitalizedSalesTaxAsset],S.[IsElectronicallyDelivered],S.[IsExemptAtAsset],S.[IsExemptAtAssetSKU],S.[IsExemptAtReceivableCode],S.[IsExemptAtSundry],S.[IsPrepaidUpfrontTax],S.[IsSKU],S.[IsSyndicated],S.[IsTaxExempt],S.[JobStepInstanceId],S.[LeaseUniqueID],S.[LegalEntityId],S.[LienCredit],S.[LineItemNumber],S.[LocationCode],S.[LocationEffectiveDate],S.[LocationId],S.[LocationStatus],S.[MainDivision],S.[MaturityDate],S.[Product],S.[ReceivableDetailId],S.[ReceivableId],S.[ReceivableSKUId],S.[ReciprocityAmount],S.[SaleLeasebackCode],S.[SalesTaxExemptionLevel],S.[SalesTaxRemittanceResponsibility],S.[ShortLeaseType],S.[SundryReceivableCode],S.[TaskChunkServiceInstanceId],S.[TaxAreaId],S.[TaxBasis],S.[TaxExemptReason],S.[TaxReceivableName],S.[TaxRemittanceType],S.[Term],S.[TitleTransferCode],S.[ToState],S.[TransactionType],S.[TransCode],S.[UpfrontTaxAssessedInLegacySystem],S.[Usage])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

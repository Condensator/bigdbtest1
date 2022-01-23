SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveNonVertexReceivableDetail_Extract]
(
 @val [dbo].[NonVertexReceivableDetail_Extract] READONLY
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
MERGE [dbo].[NonVertexReceivableDetail_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetCost]=S.[AssetCost],[AssetId]=S.[AssetId],[AssetLocationId]=S.[AssetLocationId],[CityTaxTypeId]=S.[CityTaxTypeId],[ClassCode]=S.[ClassCode],[CommencementDate]=S.[CommencementDate],[CountryShortName]=S.[CountryShortName],[CountyTaxTypeId]=S.[CountyTaxTypeId],[Currency]=S.[Currency],[ExtendedPrice]=S.[ExtendedPrice],[FairMarketValue]=S.[FairMarketValue],[GLTemplateId]=S.[GLTemplateId],[IsCapitalizedFirstRealAsset]=S.[IsCapitalizedFirstRealAsset],[IsCapitalizedRealAsset]=S.[IsCapitalizedRealAsset],[IsCapitalizedSalesTaxAsset]=S.[IsCapitalizedSalesTaxAsset],[IsCashBased]=S.[IsCashBased],[IsExemptAtAsset]=S.[IsExemptAtAsset],[IsExemptAtReceivableCode]=S.[IsExemptAtReceivableCode],[IsExemptAtSundry]=S.[IsExemptAtSundry],[IsPrepaidUpfrontTax]=S.[IsPrepaidUpfrontTax],[IsUpFrontApplicable]=S.[IsUpFrontApplicable],[JobStepInstanceId]=S.[JobStepInstanceId],[JurisdictionId]=S.[JurisdictionId],[LegalEntityId]=S.[LegalEntityId],[LocationId]=S.[LocationId],[PreviousStateShortName]=S.[PreviousStateShortName],[ReceivableDetailId]=S.[ReceivableDetailId],[ReceivableDueDate]=S.[ReceivableDueDate],[ReceivableId]=S.[ReceivableId],[SalesTaxRemittanceResponsibility]=S.[SalesTaxRemittanceResponsibility],[StateShortName]=S.[StateShortName],[StateTaxTypeId]=S.[StateTaxTypeId],[TaxBasisType]=S.[TaxBasisType],[TaxTypeId]=S.[TaxTypeId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UpfrontTaxMode]=S.[UpfrontTaxMode]
WHEN NOT MATCHED THEN
	INSERT ([AssetCost],[AssetId],[AssetLocationId],[CityTaxTypeId],[ClassCode],[CommencementDate],[CountryShortName],[CountyTaxTypeId],[CreatedById],[CreatedTime],[Currency],[ExtendedPrice],[FairMarketValue],[GLTemplateId],[IsCapitalizedFirstRealAsset],[IsCapitalizedRealAsset],[IsCapitalizedSalesTaxAsset],[IsCashBased],[IsExemptAtAsset],[IsExemptAtReceivableCode],[IsExemptAtSundry],[IsPrepaidUpfrontTax],[IsUpFrontApplicable],[JobStepInstanceId],[JurisdictionId],[LegalEntityId],[LocationId],[PreviousStateShortName],[ReceivableDetailId],[ReceivableDueDate],[ReceivableId],[SalesTaxRemittanceResponsibility],[StateShortName],[StateTaxTypeId],[TaxBasisType],[TaxTypeId],[UpfrontTaxMode])
    VALUES (S.[AssetCost],S.[AssetId],S.[AssetLocationId],S.[CityTaxTypeId],S.[ClassCode],S.[CommencementDate],S.[CountryShortName],S.[CountyTaxTypeId],S.[CreatedById],S.[CreatedTime],S.[Currency],S.[ExtendedPrice],S.[FairMarketValue],S.[GLTemplateId],S.[IsCapitalizedFirstRealAsset],S.[IsCapitalizedRealAsset],S.[IsCapitalizedSalesTaxAsset],S.[IsCashBased],S.[IsExemptAtAsset],S.[IsExemptAtReceivableCode],S.[IsExemptAtSundry],S.[IsPrepaidUpfrontTax],S.[IsUpFrontApplicable],S.[JobStepInstanceId],S.[JurisdictionId],S.[LegalEntityId],S.[LocationId],S.[PreviousStateShortName],S.[ReceivableDetailId],S.[ReceivableDueDate],S.[ReceivableId],S.[SalesTaxRemittanceResponsibility],S.[StateShortName],S.[StateTaxTypeId],S.[TaxBasisType],S.[TaxTypeId],S.[UpfrontTaxMode])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

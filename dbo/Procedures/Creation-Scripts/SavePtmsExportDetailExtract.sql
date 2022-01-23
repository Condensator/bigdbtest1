SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePtmsExportDetailExtract]
(
 @val [dbo].[PtmsExportDetailExtract] READONLY
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
MERGE [dbo].[PtmsExportDetailExtracts] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AddressCodeForAsset]=S.[AddressCodeForAsset],[AddressLine1]=S.[AddressLine1],[AddressLine2]=S.[AddressLine2],[AddressLine3]=S.[AddressLine3],[AsOfDate]=S.[AsOfDate],[AssetAlias]=S.[AssetAlias],[AssetClassCode]=S.[AssetClassCode],[AssetInServiceDate]=S.[AssetInServiceDate],[AssetLocationId]=S.[AssetLocationId],[AssetNumber]=S.[AssetNumber],[AssetPaymentAmount]=S.[AssetPaymentAmount],[AssetStatus]=S.[AssetStatus],[AssetUsageCondition]=S.[AssetUsageCondition],[BillToAddress1]=S.[BillToAddress1],[BillToAddress2]=S.[BillToAddress2],[BillToCityName]=S.[BillToCityName],[BillToName]=S.[BillToName],[BillToState]=S.[BillToState],[BillToZip]=S.[BillToZip],[BusinessCode]=S.[BusinessCode],[CityName]=S.[CityName],[CollateralCode]=S.[CollateralCode],[CombinedSalesTaxRate]=S.[CombinedSalesTaxRate],[CountyName]=S.[CountyName],[Description]=S.[Description],[DisposalNote]=S.[DisposalNote],[DisposedDate]=S.[DisposedDate],[DispositionCode]=S.[DispositionCode],[ExclusionCode]=S.[ExclusionCode],[FileName]=S.[FileName],[InstrumentType]=S.[InstrumentType],[InventoryDate]=S.[InventoryDate],[IsDisposedAssetReported]=S.[IsDisposedAssetReported],[IsIncluded]=S.[IsIncluded],[IsTransferAsset]=S.[IsTransferAsset],[JobStepInstanceId]=S.[JobStepInstanceId],[LeaseCommencementDate]=S.[LeaseCommencementDate],[LeaseEndDate]=S.[LeaseEndDate],[LeaseNumber]=S.[LeaseNumber],[LegalEntityId]=S.[LegalEntityId],[LEGLSegmentValue]=S.[LEGLSegmentValue],[LesseeContactNumber]=S.[LesseeContactNumber],[LesseeName]=S.[LesseeName],[LesseeNumber]=S.[LesseeNumber],[LienDate]=S.[LienDate],[LocationEffectiveFromDate]=S.[LocationEffectiveFromDate],[ManufacturerIndicator]=S.[ManufacturerIndicator],[Model]=S.[Model],[OECCostInString]=S.[OECCostInString],[PreviousLeaseNumber]=S.[PreviousLeaseNumber],[ProductCode]=S.[ProductCode],[ProductType]=S.[ProductType],[PropertyTaxCost_Amount]=S.[PropertyTaxCost_Amount],[PropertyTaxCost_Currency]=S.[PropertyTaxCost_Currency],[PropertyTaxCostInString]=S.[PropertyTaxCostInString],[PropertyTaxReportCode]=S.[PropertyTaxReportCode],[Quantity]=S.[Quantity],[RejectReason]=S.[RejectReason],[SalesTaxExemptionCode]=S.[SalesTaxExemptionCode],[SerialNumber]=S.[SerialNumber],[SICCode]=S.[SICCode],[StateCode]=S.[StateCode],[StateId]=S.[StateId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[ZipCode]=S.[ZipCode]
WHEN NOT MATCHED THEN
	INSERT ([AddressCodeForAsset],[AddressLine1],[AddressLine2],[AddressLine3],[AsOfDate],[AssetAlias],[AssetClassCode],[AssetInServiceDate],[AssetLocationId],[AssetNumber],[AssetPaymentAmount],[AssetStatus],[AssetUsageCondition],[BillToAddress1],[BillToAddress2],[BillToCityName],[BillToName],[BillToState],[BillToZip],[BusinessCode],[CityName],[CollateralCode],[CombinedSalesTaxRate],[CountyName],[CreatedById],[CreatedTime],[Description],[DisposalNote],[DisposedDate],[DispositionCode],[ExclusionCode],[FileName],[InstrumentType],[InventoryDate],[IsDisposedAssetReported],[IsIncluded],[IsTransferAsset],[JobStepInstanceId],[LeaseCommencementDate],[LeaseEndDate],[LeaseNumber],[LegalEntityId],[LEGLSegmentValue],[LesseeContactNumber],[LesseeName],[LesseeNumber],[LienDate],[LocationEffectiveFromDate],[ManufacturerIndicator],[Model],[OECCostInString],[PreviousLeaseNumber],[ProductCode],[ProductType],[PropertyTaxCost_Amount],[PropertyTaxCost_Currency],[PropertyTaxCostInString],[PropertyTaxReportCode],[Quantity],[RejectReason],[SalesTaxExemptionCode],[SerialNumber],[SICCode],[StateCode],[StateId],[ZipCode])
    VALUES (S.[AddressCodeForAsset],S.[AddressLine1],S.[AddressLine2],S.[AddressLine3],S.[AsOfDate],S.[AssetAlias],S.[AssetClassCode],S.[AssetInServiceDate],S.[AssetLocationId],S.[AssetNumber],S.[AssetPaymentAmount],S.[AssetStatus],S.[AssetUsageCondition],S.[BillToAddress1],S.[BillToAddress2],S.[BillToCityName],S.[BillToName],S.[BillToState],S.[BillToZip],S.[BusinessCode],S.[CityName],S.[CollateralCode],S.[CombinedSalesTaxRate],S.[CountyName],S.[CreatedById],S.[CreatedTime],S.[Description],S.[DisposalNote],S.[DisposedDate],S.[DispositionCode],S.[ExclusionCode],S.[FileName],S.[InstrumentType],S.[InventoryDate],S.[IsDisposedAssetReported],S.[IsIncluded],S.[IsTransferAsset],S.[JobStepInstanceId],S.[LeaseCommencementDate],S.[LeaseEndDate],S.[LeaseNumber],S.[LegalEntityId],S.[LEGLSegmentValue],S.[LesseeContactNumber],S.[LesseeName],S.[LesseeNumber],S.[LienDate],S.[LocationEffectiveFromDate],S.[ManufacturerIndicator],S.[Model],S.[OECCostInString],S.[PreviousLeaseNumber],S.[ProductCode],S.[ProductType],S.[PropertyTaxCost_Amount],S.[PropertyTaxCost_Currency],S.[PropertyTaxCostInString],S.[PropertyTaxReportCode],S.[Quantity],S.[RejectReason],S.[SalesTaxExemptionCode],S.[SerialNumber],S.[SICCode],S.[StateCode],S.[StateId],S.[ZipCode])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

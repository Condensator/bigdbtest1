SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAssetEnMasseUpdateDetail]
(
 @val [dbo].[AssetEnMasseUpdateDetail] READONLY
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
MERGE [dbo].[AssetEnMasseUpdateDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AcquisitionDate]=S.[AcquisitionDate],[Alias]=S.[Alias],[AssetBookValueAdjustmentGLTemplateId]=S.[AssetBookValueAdjustmentGLTemplateId],[AssetCatalogId]=S.[AssetCatalogId],[AssetId]=S.[AssetId],[BookDepreciationGLTemplateId]=S.[BookDepreciationGLTemplateId],[CustomerId]=S.[CustomerId],[Description]=S.[Description],[InServiceDate]=S.[InServiceDate],[InventoryRemarketerId]=S.[InventoryRemarketerId],[IsElectronicallyDelivered]=S.[IsElectronicallyDelivered],[IsEligibleForPropertyTax]=S.[IsEligibleForPropertyTax],[IsSaleLeaseback]=S.[IsSaleLeaseback],[MakeId]=S.[MakeId],[ManufacturerId]=S.[ManufacturerId],[ModelId]=S.[ModelId],[ModelYear]=S.[ModelYear],[OwnershipStatus]=S.[OwnershipStatus],[PartNumber]=S.[PartNumber],[PropertyTaxCost_Amount]=S.[PropertyTaxCost_Amount],[PropertyTaxCost_Currency]=S.[PropertyTaxCost_Currency],[PropertyTaxDate]=S.[PropertyTaxDate],[PropertyTaxReportCodeId]=S.[PropertyTaxReportCodeId],[ProspectiveContract]=S.[ProspectiveContract],[PurchaseOrderDate]=S.[PurchaseOrderDate],[Quantity]=S.[Quantity],[SaleLeasebackCodeId]=S.[SaleLeasebackCodeId],[StateId]=S.[StateId],[TypeId]=S.[TypeId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UsageCondition]=S.[UsageCondition],[VendorAssetCategoryId]=S.[VendorAssetCategoryId],[VendorOrderNumber]=S.[VendorOrderNumber]
WHEN NOT MATCHED THEN
	INSERT ([AcquisitionDate],[Alias],[AssetBookValueAdjustmentGLTemplateId],[AssetCatalogId],[AssetEnMasseUpdateId],[AssetId],[BookDepreciationGLTemplateId],[CreatedById],[CreatedTime],[CustomerId],[Description],[InServiceDate],[InventoryRemarketerId],[IsElectronicallyDelivered],[IsEligibleForPropertyTax],[IsSaleLeaseback],[MakeId],[ManufacturerId],[ModelId],[ModelYear],[OwnershipStatus],[PartNumber],[PropertyTaxCost_Amount],[PropertyTaxCost_Currency],[PropertyTaxDate],[PropertyTaxReportCodeId],[ProspectiveContract],[PurchaseOrderDate],[Quantity],[SaleLeasebackCodeId],[StateId],[TypeId],[UsageCondition],[VendorAssetCategoryId],[VendorOrderNumber])
    VALUES (S.[AcquisitionDate],S.[Alias],S.[AssetBookValueAdjustmentGLTemplateId],S.[AssetCatalogId],S.[AssetEnMasseUpdateId],S.[AssetId],S.[BookDepreciationGLTemplateId],S.[CreatedById],S.[CreatedTime],S.[CustomerId],S.[Description],S.[InServiceDate],S.[InventoryRemarketerId],S.[IsElectronicallyDelivered],S.[IsEligibleForPropertyTax],S.[IsSaleLeaseback],S.[MakeId],S.[ManufacturerId],S.[ModelId],S.[ModelYear],S.[OwnershipStatus],S.[PartNumber],S.[PropertyTaxCost_Amount],S.[PropertyTaxCost_Currency],S.[PropertyTaxDate],S.[PropertyTaxReportCodeId],S.[ProspectiveContract],S.[PurchaseOrderDate],S.[Quantity],S.[SaleLeasebackCodeId],S.[StateId],S.[TypeId],S.[UsageCondition],S.[VendorAssetCategoryId],S.[VendorOrderNumber])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

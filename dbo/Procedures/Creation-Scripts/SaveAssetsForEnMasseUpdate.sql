SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[SaveAssetsForEnMasseUpdate]
(
@enMasseUpdateDetails EnMasseAssetInfo READONLY,
@childAssetCustomer EnMasseChildAssetInfo READONLY
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
MERGE Assets AS Asset
USING @enMasseUpdateDetails AS AssetTmp
ON (Asset.Id = AssetTmp.AssetId)
WHEN MATCHED THEN
UPDATE SET
AcquisitionDate = AssetTmp.AcquisitionDate,
AssetMode = AssetTmp.AssetMode,
PartNumber = AssetTmp.PartNumber,
UsageCondition = AssetTmp.UsageCondition,
Description = AssetTmp.Description,
Quantity = AssetTmp.Quantity,
InServiceDate = AssetTmp.InServiceDate,
IsEligibleForPropertyTax = AssetTmp.IsEligibleForPropertyTax,
PropertyTaxCost_Amount = AssetTmp.PropertyTaxCost_Amount,
PropertyTaxCost_Currency = AssetTmp.PropertyTaxCost_Currency,
PropertyTaxDate = AssetTmp.PropertyTaxDate,
PropertyTaxReportCodeId = AssetTmp.PropertyTaxReportCodeId,
ProspectiveContract = AssetTmp.ProspectiveContract,
ManufacturerId = AssetTmp.ManufacturerId,
TypeId = AssetTmp.TypeId,
CustomerId = AssetTmp.CustomerId,
UpdatedById = AssetTmp.UpdatedById,
UpdatedTime = AssetTmp.UpdatedTime,
OwnershipStatus = AssetTmp.OwnershipStatus,
PurchaseOrderDate = AssetTmp.PurchaseOrderDate,
VendorAssetCategoryId = AssetTmp.VendorAssetCategoryId,
StateId = AssetTmp.RegistrationStateId,
SaleLeasebackCodeId = AssetTmp.SaleLeasebackCodeId,
ModelYear= AssetTmp.ModelYear,
VendorOrderNumber = AssetTmp.VendorOrderNumber,
IsSaleLeaseback=AssetTmp.IsSaleLeaseback,
AssetCatalogId=AssetTmp.AssetCatalogId,
IsElectronicallyDelivered=AssetTmp.IsElectronicallyDelivered,
InventoryRemarketerId=AssetTmp.InventoryRemarketerId,
MakeId=AssetTmp.MakeId,
ModelId=AssetTmp.ModelId
;
WITH Asset_CTE
AS
(
SELECT EnMasseUpdateDetails.AssetId AssetId
,AssetCatalogs.Id AssetCatalogId
,Products.Id ProductId
,Manufacturers.Class1 Class1
,AssetCatalogs.Class3 Class3
,ProductSubTypes.Name Description2
,AssetCatalogs.AssetCategoryId AssetCategoryId
FROM @enMasseUpdateDetails EnMasseUpdateDetails
JOIN AssetCatalogs
ON EnMasseUpdateDetails.AssetCatalogId = AssetCatalogs.Id
JOIN Manufacturers
ON AssetCatalogs.ManufacturerId = Manufacturers.Id
JOIN Products
ON AssetCatalogs.ProductId = Products.Id
JOIN ProductSubTypes
ON 	AssetCatalogs.ProductSubTypeId = ProductSubTypes.Id
)
UPDATE Assets
SET
ProductId = Asset_CTE.ProductId,
AssetCategoryId = Asset_CTE.AssetCategoryId,
Description2 = Asset_CTE.Description2,
Class1 = Asset_CTE.Class1,
Class3 = Asset_CTE.Class3
FROM Asset_CTE
JOIN Assets
ON Asset_CTE.AssetId = Assets.Id
;
UPDATE AssetGLD
SET
AssetBookValueAdjustmentGLTemplateId = EnMasseUpdateDetails.AssetBookValueAdjustmentGLTemplateId,
BookDepreciationGLTemplateId = EnMasseUpdateDetails.BookDepreciationGLTemplateId,
UpdatedById = EnMasseUpdateDetails.UpdatedById,
UpdatedTime = EnMasseUpdateDetails.UpdatedTime
FROM AssetGLDetails AssetGLD
JOIN @enMasseUpdateDetails EnMasseUpdateDetails
ON AssetGLD.Id = EnMasseUpdateDetails.AssetId
;
MERGE Assets AS Asset
USING @childAssetCustomer AS ChildAssetTmp
ON (Asset.Id = ChildAssetTmp.ChildAssetId)
WHEN MATCHED THEN
UPDATE SET
CustomerId = ChildAssetTmp.CustomerId,
UpdatedById = ChildAssetTmp.UpdatedById,
UpdatedTime = ChildAssetTmp.UpdatedTime
;

INSERT INTO AssetHistories
(
Reason,
AsOfDate,
AcquisitionDate,
Status,
FinancialType,
SourceModule,
SourceModuleId,
CustomerId,
ParentAssetId,
LegalEntityId,
AssetId,
ContractId,
CreatedById,
CreatedTime,
PropertyTaxReportCodeId,
IsReversed
)
SELECT
param.HistoryReason,
param.AsOfDate,
param.AcquisitionDate,
param.AssetStatus,
param.AssetFinancialType,
param.SourceModule,
param.AssetId,
param.CustomerId,
param.ParentAssetId,
param.LegalEntityId,
param.AssetId,
param.ContractId,
param.UpdatedById,
param.UpdatedTime,
param.PropertyTaxReportCodeId,
0
FROM @enMasseUpdateDetails param
WHERE param.UpdateAssetHistory = 1
;
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CreateNegativeDepositAssets]
(
@PayableInvoiceId BIGINT = NULL,
@CurrencyExchangeRate DECIMAL(10,6) = NULL,
@AssetCurrencyCode NVARCHAR(6) = NULL,
@FinancialType NVARCHAR(100) = NULL,
@AssetMode NVARCHAR(40) = NULL,
@Reason NVARCHAR(100)= NULL,
@SourceModule NVARCHAR(50) = NULL,
@InvoiceDate DATETIMEOFFSET = NULL,
@CreatedById bigint = NULL,
@CreatedTime DATETIMEOFFSET = NULL
)
AS
BEGIN
SET NOCOUNT ON
CREATE TABLE #DepositAssetAlias
(
[DepositAssetId] bigint NOT NULL,
AssetCount INT NOT NULL
);
CREATE TABLE #CreatedNegativeDepositAssets
(
[Action] NVARCHAR(10) NOT NULL,
[AssetId] bigint NOT NULL,
PayableInvoiceNegativeDepositAssetId BIGINT,
DepositAssetId BIGINT
);
INSERT INTO #DepositAssetAlias
(
DepositAssetId,
AssetCount
)
SELECT
DepositAssets.Id,
COUNT(NegativeDepositAssets.Id)
FROM PayableInvoiceDepositTakeDownAssets
JOIN PayableInvoiceDepositAssets ON PayableInvoiceDepositTakeDownAssets.PayableInvoiceDepositAssetId= PayableInvoiceDepositAssets.Id
LEFT JOIN PayableInvoiceAssets as PINegativeDepositAssets ON PayableInvoiceDepositTakeDownAssets.NegativeDepositAssetId = PINegativeDepositAssets.Id
LEFT JOIN Assets as NegativeDepositAssets ON PINegativeDepositAssets.AssetId = NegativeDepositAssets.Id AND NegativeDepositAssets.Id is not null
JOIN PayableInvoiceAssets as PIDepositAssets ON PayableInvoiceDepositAssets.DepositAssetId = PIDepositAssets.Id
JOIN Assets as DepositAssets ON PIDepositAssets.AssetId = DepositAssets.Id
GROUP BY DepositAssets.Id;
SELECT
PayableInvoiceAssets.Id as PayableInvoiceAssetId,
PayableInvoiceAssets.AssetId,
PayableInvoices.PostDate,
Assets.Alias as Alias,
NegativeAssets.Alias as NegativeDepositAlias,
@CreatedTime CreatedTime,
Assets.CustomerId,
Assets.Description,
PayableInvoices.InvoiceDate,
Assets.IsEligibleForPropertyTax,
Assets.LegalEntityId,
Assets.ManufacturerId,
ROUND((PayableInvoiceAssets.AcquisitionCost_Amount * @CurrencyExchangeRate),2) NetValue,
Assets.ParentAssetId,
Assets.PartNumber,
ROUND((Assets.PropertyTaxCost_Amount * @CurrencyExchangeRate),2) PropertyTaxAmount,
Assets.PropertyTaxDate,
Assets.ProspectiveContract,
Assets.Quantity,
Assets.Status,
Assets.TypeId,
PayableInvoiceAssets.Id AS NegativeDepositAssetId,
RealAssets.AcquisitionDate,
RealAssets.InServiceDate,
Assets.UsageCondition,
Assets.Id as DepositAssetId,
Assets.PropertyTaxResponsibility as PropertyTaxResponsibility,
Assets.StateId as RegistrationStateId,
Assets.DealerCost_Amount,
Assets.DealerCost_Currency,
Assets.DMDPercentage,
Assets.[IsManufacturerOverride],
Assets.[Description2] ,
Assets.[Class1],
Assets.[Class3],
Assets.[ManufacturerOverride],
Assets.[AssetCatalogId],
Assets.[ProductId],
Assets.[AssetClass2Id] ,
Assets.[AssetCategoryId],
Assets.VendorOrderNumber,
Assets.CustomerAssetNumber,
Assets.TaxExemptRuleId,
Assets.IsReversed,
Assets.IsSerializedAsset,
Assets.Residual_Amount,
Assets.Residual_Currency,
Assets.IsVehicle,
Assets.IsLeaseComponent,
Assets.IsServiceOnly
INTO #AssetTemp
FROM PayableInvoiceDepositTakeDownAssets
INNER JOIN PayableInvoiceDepositAssets ON PayableInvoiceDepositTakeDownAssets.PayableInvoiceDepositAssetId = PayableInvoiceDepositAssets.Id AND PayableInvoiceDepositTakeDownAssets.IsActive = 1 AND PayableInvoiceDepositAssets.IsActive = 1
INNER JOIN PayableInvoices ON PayableInvoiceDepositAssets.PayableInvoiceId = PayableInvoices.Id AND PayableInvoices.Id = @PayableInvoiceId
LEFT JOIN PayableInvoiceAssets ON PayableInvoiceAssets.Id = PayableInvoiceDepositTakeDownAssets.NegativeDepositAssetId AND PayableInvoiceAssets.IsActive  = 1
LEFT JOIN Assets as NegativeAssets ON PayableInvoiceAssets.AssetId = NegativeAssets.Id
INNER JOIN PayableInvoiceAssets PIDepositAsset ON PayableInvoiceDepositAssets.DepositAssetId = PIDepositAsset.Id AND PIDepositAsset.IsActive = 1
INNER JOIN Assets ON PIDepositAsset.AssetId = Assets.Id
INNER JOIN PayableInvoiceAssets as PIRealAssets ON PayableInvoiceDepositTakeDownAssets.TakeDownAssetId=PIRealAssets.Id AND PIRealAssets.IsActive = 1
INNER JOIN Assets as RealAssets ON PIRealAssets.AssetId = RealAssets.Id
ORDER BY PayableInvoiceDepositTakeDownAssets.Id;
SELECT
AssetTemp.*
INTO #AssetInfoTemp
FROM #AssetTemp as AssetTemp
LEFT JOIN Assets as Asset ON AssetTemp.AssetId = Asset.Id
WHERE Asset.Id IS NULL;
MERGE Assets AS Asset
USING #AssetTemp AS AssetTemp
ON (Asset.Id = AssetTemp.AssetId)
WHEN MATCHED THEN
UPDATE SET
AcquisitionDate = AssetTemp.AcquisitionDate,
Alias = AssetTemp.NegativeDepositAlias,
CurrencyCode = @AssetCurrencyCode,
CustomerId = AssetTemp.CustomerId,
Description = AssetTemp.Description,
InServiceDate = AssetTemp.InServiceDate,
IsEligibleForPropertyTax = AssetTemp.IsEligibleForPropertyTax,
LegalEntityId = AssetTemp.LegalEntityId,
ManufacturerId = AssetTemp.ManufacturerId,
ParentAssetId = AssetTemp.ParentAssetId,
PartNumber = AssetTemp.PartNumber,
PropertyTaxCost_Amount = AssetTemp.PropertyTaxAmount,
PropertyTaxCost_Currency = @AssetCurrencyCode,
PropertyTaxDate = AssetTemp.PropertyTaxDate,
ProspectiveContract = AssetTemp.ProspectiveContract,
Quantity = AssetTemp.Quantity,
Status = AssetTemp.Status,
TypeId = AssetTemp.TypeId,
UpdatedById = @CreatedById,
UpdatedTime = @CreatedTime,
UsageCondition = AssetTemp.UsageCondition,
PropertyTaxResponsibility = AssetTemp.PropertyTaxResponsibility,
MoveChildAssets = 0,
ModelYear = null,
IsSystemCreated  = 1,
StateId = AssetTemp.RegistrationStateId,
DealerCost_Amount = AssetTemp.DealerCost_Amount,
DealerCost_Currency = AssetTemp.DealerCost_Currency,
DMDPercentage = AssetTemp.DMDPercentage,
[IsManufacturerOverride] = AssetTemp.[IsManufacturerOverride],
[Description2] = AssetTemp.[Description2] ,
[Class1] = AssetTemp.[Class1],
[Class3] = AssetTemp.[Class3],
[ManufacturerOverride] = AssetTemp.[ManufacturerOverride],
[AssetCatalogId] = AssetTemp.[AssetCatalogId],
[ProductId] = AssetTemp.[ProductId],
[AssetClass2Id] = AssetTemp.[AssetClass2Id] ,
[AssetCategoryId] = AssetTemp.[AssetCategoryId],
VendorOrderNumber = AssetTemp.VendorOrderNumber,
CustomerAssetNumber = AssetTemp.CustomerAssetNumber
WHEN NOT MATCHED THEN
INSERT (
AcquisitionDate,
Alias,
AssetMode,
CreatedById,
CreatedTime,
CurrencyCode,
CustomerId,
Description,
FinancialType,
InServiceDate,
IsEligibleForPropertyTax,
LegalEntityId,
ManufacturerId,
ParentAssetId,
PartNumber,
PropertyTaxCost_Amount,
PropertyTaxCost_Currency,
PropertyTaxDate,
ProspectiveContract,
Quantity,
Status,
TypeId,
UsageCondition,
MoveChildAssets,
IsTaxExempt,
ModelYear,
PropertyTaxResponsibility,
GrossVehicleWeight,
WeightMeasure,
IsOffLease,
IsElectronicallyDelivered,
IsSaleLeaseback,
IsParent,
IsSystemCreated,
IsOnCommencedLease,
IsTakedownAsset,
StateId,
DealerCost_Amount,
DealerCost_Currency,
DMDPercentage,
[IsManufacturerOverride],
[Description2] ,
[Class1],
[Class3],
[ManufacturerOverride],
[AssetCatalogId],
[ProductId],
[AssetClass2Id] ,
[AssetCategoryId],
VendorOrderNumber,
CustomerAssetNumber,
TaxExemptRuleId,
IsReversed,
IsSerializedAsset,
Residual_Amount,
Residual_Currency,
IsVehicle,
IsLeaseComponent,
IsServiceOnly,
IsTaxParameterChangedForLeasedAsset,
Salvage_Amount,
Salvage_Currency
)
VALUES(
AssetTemp.AcquisitionDate,
AssetTemp.Alias + '-' + CAST((Select AssetCount from #DepositAssetAlias where DepositAssetId = AssetTemp.DepositAssetId)
+ (Select Count(*) from #AssetInfoTemp where DepositAssetId=AssetTemp.DepositAssetId and #AssetInfoTemp.PayableInvoiceAssetId < AssetTemp.PayableInvoiceAssetId)
+ 1 as nvarchar),
@AssetMode,
@CreatedById,
@CreatedTime,
@AssetCurrencyCode,
AssetTemp.CustomerId,
AssetTemp.Description,
@FinancialType,
AssetTemp.InServiceDate,
AssetTemp.IsEligibleForPropertyTax,
AssetTemp.LegalEntityId,
AssetTemp.ManufacturerId,
AssetTemp.ParentAssetId,
AssetTemp.PartNumber,
AssetTemp.PropertyTaxAmount,
@AssetCurrencyCode,
AssetTemp.PropertyTaxDate,
AssetTemp.ProspectiveContract,
AssetTemp.Quantity,
AssetTemp.Status,
AssetTemp.TypeId,
AssetTemp.UsageCondition,
0,
1,
null,
AssetTemp.PropertyTaxResponsibility,
0,
'_',
0,
0,
0,
0,
1,
0,
0,
AssetTemp.RegistrationStateId						,
AssetTemp.DealerCost_Amount,
AssetTemp.DealerCost_Currency,
AssetTemp.DMDPercentage,
AssetTemp.[IsManufacturerOverride],
AssetTemp.[Description2] ,
AssetTemp.[Class1],
AssetTemp.[Class3],
AssetTemp.[ManufacturerOverride],
AssetTemp.[AssetCatalogId],
AssetTemp.[ProductId],
AssetTemp.[AssetClass2Id] ,
AssetTemp.[AssetCategoryId],
AssetTemp.VendorOrderNumber,
AssetTemp.CustomerAssetNumber,
AssetTemp.TaxExemptRuleId,
AssetTemp.IsReversed,
AssetTemp.IsSerializedAsset,
AssetTemp.Residual_Amount,
AssetTemp.Residual_Currency,
AssetTemp.IsVehicle,
AssetTemp.IsLeaseComponent,
AssetTemp.IsServiceOnly,
0,
0,
AssetTemp.Residual_Currency
)
OUTPUT $action, Inserted.Id, AssetTemp.NegativeDepositAssetId,AssetTemp.DepositAssetId INTO #CreatedNegativeDepositAssets
;
INSERT INTO AssetLocations
(
[CreatedById],
[CreatedTime],
[EffectiveFromDate],
[IsActive],
[IsCurrent],
[LocationId],
[TaxBasisType],
[UpfrontTaxMode],
[AssetId],
[IsFLStampTaxExempt],
[ReciprocityAmount_Amount],
[ReciprocityAmount_Currency],
[LienCredit_Amount],
[LienCredit_Currency],
[UpfrontTaxAssessedInLegacySystem]
)
SELECT
@CreatedById,
@CreatedTime,
AssetLocations.EffectiveFromDate,
AssetLocations.IsActive,
AssetLocations.IsCurrent,
AssetLocations.LocationId,
AssetLocations.TaxBasisType,
AssetLocations.UpfrontTaxMode,
#CreatedNegativeDepositAssets.AssetId,
0,
0.0,
@AssetCurrencyCode,
0.0,
@AssetCurrencyCode,
CAST(0 AS BIT)
FROM AssetLocations
INNER JOIN #CreatedNegativeDepositAssets ON AssetLocations.AssetId = #CreatedNegativeDepositAssets.DepositAssetId
WHERE #CreatedNegativeDepositAssets.Action ='INSERT' and AssetLocations.IsActive = 1;
INSERT INTO AssetGLDetails
(
[Id]
,[HoldingStatus]
,[CostCenterId]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[AssetBookValueAdjustmentGLTemplateId]
,[BookDepreciationGLTemplateId]
,[InstrumentTypeId]
,[LineofBusinessId]
,[OriginalInstrumentTypeId]
,[OriginalLineofBusinessId]
)
SELECT
CreatedAsset.AssetId
,AssetGLDetail.HoldingStatus
,AssetGLDetail.CostCenterId
,@CreatedById
,@CreatedTime
,NULL
,NULL
,AssetGLDetail.AssetBookValueAdjustmentGLTemplateId
,AssetGLDetail.BookDepreciationGLTemplateId
,AssetGLDetail.InstrumentTypeId
,AssetGLDetail.LineofBusinessId
,AssetGLDetail.InstrumentTypeId
,AssetGLDetail.LineofBusinessId
FROM AssetGLDetails AssetGLDetail
INNER JOIN #CreatedNegativeDepositAssets CreatedAsset ON AssetGLDetail.Id = CreatedAsset.DepositAssetId
WHERE CreatedAsset.Action ='INSERT'
;
UPDATE PayableInvoiceAssets SET AssetId = #CreatedNegativeDepositAssets.[AssetId]
FROM PayableInvoiceAssets PIAsset
INNER JOIN #CreatedNegativeDepositAssets ON PIAsset.Id = #CreatedNegativeDepositAssets.PayableInvoiceNegativeDepositAssetId;
INSERT INTO AssetHistories
(
[Reason]
,[AsOfDate]
,[AcquisitionDate]
,[Status]
,[FinancialType]
,[SourceModule]
,[SourceModuleId]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[CustomerId]
,[ParentAssetId]
,[LegalEntityId]
--,[ContractId]
,[AssetId]
,[IsReversed]
,[PropertyTaxReportCodeId])
SELECT
@Reason,
@InvoiceDate,
Assets.AcquisitionDate,
Assets.Status,
Assets.FinancialType,
@SourceModule,
@PayableInvoiceId,
@CreatedById,
@CreatedTime,
NULL,
NULL,
Assets.CustomerId,
Assets.ParentAssetId,
Assets.LegalEntityId,
--NULL,
Assets.Id,
0,
Assets.PropertyTaxReportCodeId
FROM Assets
INNER JOIN #CreatedNegativeDepositAssets ON Assets.Id = #CreatedNegativeDepositAssets.AssetId
WHERE #CreatedNegativeDepositAssets.Action = 'INSERT';
END

GO

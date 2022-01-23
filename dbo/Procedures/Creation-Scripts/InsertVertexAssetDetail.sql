SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--SP to fetch asset flex field details to call vertex
CREATE PROCEDURE [dbo].[InsertVertexAssetDetail]
(
@CUEntityType NVARCHAR(10),
@CTEntityType NVARCHAR(10),
@JobStepInstanceId BIGINT,
@AssetMultipleSerialNumberType NVARCHAR(10)
)
AS
BEGIN
CREATE TABLE #InsertedVertexAssetDetails
(
	Id Bigint,
	AssetId Bigint
)
--Service only Assets Info
;WITH CTE_DistinctAssetIds AS
(
SELECT DISTINCT AssetId, ContractId, IsAssessSalesTaxAtSKULevel FROM SalesTaxReceivableDetailExtract
WHERE EntityType = @CTEntityType AND IsVertexSupported = 1 AND JobStepInstanceId = @JobStepInstanceId
AND InvalidErrorCode IS NULL
)
INSERT INTO VertexAssetDetailExtract
(AssetId, TitleTransferCode, AssetType, SaleLeasebackCode, IsElectronicallyDelivered,GrossVehicleWeight,
 SalesTaxExemptionLevel, AssetCatalogNumber,ContractTypeName, JobStepInstanceId,
 Usage, ContractId,SalesTaxRemittanceResponsibility,PreviousSalesTaxRemittanceResponsibility,AssetUsageCondition,IsSKU)
OUTPUT inserted.Id,inserted.AssetId into #InsertedVertexAssetDetails
SELECT
     AssetId = A.Id,
     TitleTransferCode = TTC.TransferCode,
     AssetType = ACC.ClassCode,
	 SaleLeasebackCode = SLBCC.Code,
	 IsElectronicallyDelivered = A.IsElectronicallyDelivered,
	 GrossVehicleWeight =  A.GrossVehicleWeight,
	 SalesTaxExemptionLevel = STELC.Name,
	 AssetCatalogNumber = AC.CollateralCode,
	 ContractTypeName = NULL ,
	 JobStepInstanceId = @JobStepInstanceId,
	 AU.Usage,
	 Asset.ContractId,
	 '_' AS SalesTaxRemittanceResponsibility,
	 '_' AS PreviousSalesTaxRemittanceResponsibility,
	 A.UsageCondition,
	 CASE WHEN Asset.IsAssessSalesTaxAtSKULevel = 1 THEN A.IsSKU ELSE 0 END
FROM
CTE_DistinctAssetIds Asset
INNER JOIN Assets A ON A.Id = Asset.AssetId
INNER JOIN AssetTypes ATS ON A.TypeId = ATS.Id
LEFT JOIN AssetUsages AU ON AU.Id = A.AssetUsageId
LEFT JOIN AssetCatalogs AC ON A.AssetCatalogId = AC.Id
LEFT JOIN SaleLeasebackCodeConfigs SLBCC ON A.SaleLeasebackCodeId = SLBCC.Id
LEFT JOIN TitleTransferCodes TTC ON A.TitleTransferCodeId = TTC.Id
LEFT JOIN AssetClassCodes ACC ON ATS.AssetClassCodeId = ACC.Id
LEFT JOIN SalesTaxExemptionLevelConfigs STELC ON A.SalesTaxExemptionLevelId = STELC.Id
WHERE A.IsServiceOnly=1;
--Contract Based Assets Info
WITH CTE_DistinctAssetIds AS
(
SELECT DISTINCT AssetId, ContractID, IsAssessSalesTaxAtSKULevel FROM SalesTaxReceivableDetailExtract
WHERE EntityType = @CTEntityType AND IsVertexSupported = 1 AND InvalidErrorCode IS NULL AND JobStepInstanceId = @JobStepInstanceId
)
INSERT INTO VertexAssetDetailExtract
(AssetId, TitleTransferCode, AssetType, SaleLeasebackCode, IsElectronicallyDelivered,GrossVehicleWeight,
 SalesTaxExemptionLevel, AssetCatalogNumber,ContractTypeName,JobStepInstanceId,
 Usage, ContractId,SalesTaxRemittanceResponsibility,PreviousSalesTaxRemittanceResponsibility,PreviousSalesTaxRemittanceResponsibilityEffectiveTillDate
 ,AssetUsageCondition,IsSKU)
OUTPUT inserted.Id,inserted.AssetId into #InsertedVertexAssetDetails
SELECT [AssetId], [TitleTransferCode], [AssetType], [SaleLeasebackCode], [IsElectronicallyDelivered],[GrossVehicleWeight],
 [SalesTaxExemptionLevel], [AssetCatalogNumber],[ContractTypeName], [JobStepInstanceId],
 [Usage], [ContractId],[SalesTaxRemittanceResponsibility],[PreviousSalesTaxRemittanceResponsibility],[PreviousSalesTaxRemittanceResponsibilityEffectiveTillDate],[AssetUsageCondition],[IsSKU] FROM
(
SELECT 
     AssetId = A.Id,
     TitleTransferCode = TTC.TransferCode,
     AssetType = ACC.ClassCode,
	 SaleLeasebackCode = SLBCC.Code,
	 IsElectronicallyDelivered = A.IsElectronicallyDelivered,
	 GrossVehicleWeight =  A.GrossVehicleWeight,
	 SalesTaxExemptionLevel = STELC.Name,
	 AssetCatalogNumber = AC.CollateralCode,
	 ContractTypeName = CASE WHEN LA.IsTaxDepreciable = 1 THEN 'FMV' ELSE 'CSC' END ,
	 JobStepInstanceId = @JobStepInstanceId
	 ,AU.Usage
	 ,LF.ContractId
	 ,LA.SalesTaxRemittanceResponsibility
	 ,STRH.SalesTaxRemittanceResponsibility PreviousSalesTaxRemittanceResponsibility
	 ,STRH.EffectiveTillDate PreviousSalesTaxRemittanceResponsibilityEffectiveTillDate
	 ,A.UsageCondition AssetUsageCondition
	 ,CASE WHEN Asset.IsAssessSalesTaxAtSKULevel = 1 THEN A.IsSKU ELSE 0 END AS IsSKU
	 ,ROW_NUMBER() OVER (PARTITION BY LF.ContractId,A.Id ORDER BY LF.Id DESC) RowNumber
FROM
CTE_DistinctAssetIds Asset
INNER JOIN Assets A ON A.Id = Asset.AssetId
INNER JOIN LeaseFinances LF ON Asset.ContractId = LF.ContractId
INNER JOIN LeaseAssets LA ON  A.Id  = LA.AssetId AND LF.Id = LA.LeaseFinanceId
AND (LA.IsActive = 1 OR LA.TerminationDate IS NOT NULL)
INNER JOIN AssetTypes ATS ON A.TypeId = ATS.Id
LEFT JOIN AssetCatalogs AC ON A.AssetCatalogId = AC.Id
LEFT JOIN AssetUsages AU ON AU.Id = A.AssetUsageId
LEFT JOIN SaleLeasebackCodeConfigs SLBCC ON A.SaleLeasebackCodeId = SLBCC.Id
LEFT JOIN TitleTransferCodes TTC ON A.TitleTransferCodeId = TTC.Id
LEFT JOIN AssetClassCodes ACC ON ATS.AssetClassCodeId = ACC.Id
LEFT JOIN ContractSalesTaxRemittanceResponsibilityHistories STRH ON STRH.ContractId = LF.ContractId AND A.Id = STRH.AssetId
LEFT JOIN SalesTaxExemptionLevelConfigs STELC ON A.SalesTaxExemptionLevelId = STELC.Id
WHERE (LF.IsCurrent = 1 OR ATS.IsSoft= 1)OR(LF.IsCurrent=0 AND LA.IsActive=1 AND LA.TerminationDate IS NULL)) AS VertexAssetDetails
WHERE VertexAssetDetails.RowNumber = 1;
--customer based
;WITH CTE_DistinctAssetIds AS
(
SELECT
DISTINCT CustomerBased.AssetId,IsAssessSalesTaxAtSKULevel FROM SalesTaxReceivableDetailExtract CustomerBased
LEFT JOIN
#InsertedVertexAssetDetails ContractBasedAssetIds
ON
ContractBasedAssetIds.AssetId = CustomerBased.AssetId
WHERE
EntityType = @CUEntityType AND IsVertexSupported = 1
AND CustomerBased.JobStepInstanceId = @JobStepInstanceId
AND InvalidErrorCode IS NULL AND ContractBasedAssetIds.AssetId IS NULL
)
INSERT INTO VertexAssetDetailExtract
(AssetId, TitleTransferCode, AssetType, SaleLeasebackCode, IsElectronicallyDelivered, GrossVehicleWeight,
SalesTaxExemptionLevel, AssetCatalogNumber, ContractTypeName, JobStepInstanceId,
Usage,ContractId,SalesTaxRemittanceResponsibility,PreviousSalesTaxRemittanceResponsibility,PreviousSalesTaxRemittanceResponsibilityEffectiveTillDate,AssetUsageCondition,IsSKU)
OUTPUT inserted.Id,inserted.AssetId into #InsertedVertexAssetDetails
SELECT
     AssetId = A.Id,
     TitleTransferCode = TTC.TransferCode,
     AssetType = ACC.ClassCode,
	 SaleLeasebackCode = SLBCC.Code,
	 IsElectronicallyDelivered = A.IsElectronicallyDelivered,
	 GrossVehicleWeight =  A.GrossVehicleWeight,
	 SalesTaxExemptionLevel = STELC.Name,
	 AssetCatalogNumber = AC.CollateralCode,
	 ContractTypeName = NULL ,
	 JobStepInstanceId = @JobStepInstanceId
	 ,AU.Usage
	 ,Contractid = NULL
	 ,'_' AS SalesTaxRemittanceResponsibility
	 ,'_' AS PreviousSalesTaxRemittanceResponsibility
	 ,PreviousSalesTaxRemittanceResponsibilityEffectiveTillDate = NULL
	 ,A.UsageCondition
	 ,CASE WHEN Asset.IsAssessSalesTaxAtSKULevel = 1 THEN A.IsSKU ELSE 0 END
FROM CTE_DistinctAssetIds Asset
INNER JOIN Assets A ON A.Id = Asset.AssetId
INNER JOIN AssetTypes ATS ON A.TypeId = ATS.Id
LEFT JOIN AssetCatalogs AC ON A.AssetCatalogId = AC.Id
LEFT JOIN AssetUsages AU ON AU.Id = A.AssetUsageId
LEFT JOIN SaleLeasebackCodeConfigs SLBCC ON A.SaleLeasebackCodeId = SLBCC.Id
LEFT JOIN TitleTransferCodes TTC ON A.TitleTransferCodeId = TTC.Id
LEFT JOIN AssetClassCodes ACC ON ATS.AssetClassCodeId = ACC.Id
LEFT JOIN SalesTaxExemptionLevelConfigs STELC ON A.SalesTaxExemptionLevelId = STELC.Id;

;WITH CTE_AssetSerialNumberDetails AS(
SELECT 
	ASN.AssetId,
	SerialNumber = CASE WHEN COUNT(ASN.Id) > 1 THEN @AssetMultipleSerialNumberType ELSE MAX(ASN.SerialNumber) END
FROM #InsertedVertexAssetDetails A
JOIN AssetSerialNumbers ASN on A.AssetId = ASN.AssetId AND ASN.IsActive=1
GROUP BY ASN.AssetId
)

UPDATE VADE 
Set VADE.AssetSerialOrVIN = ASN.SerialNumber
from VertexAssetDetailExtract VADE 
JOIN #InsertedVertexAssetDetails A on A.Id = VADE.Id
LEFT JOIN CTE_AssetSerialNumberDetails ASN on ASN.AssetId = VADE.AssetId

END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InsertSalesTaxReversalAssetFlexFieldDetails]  
(  
@JobStepInstanceId BIGINT,
@AssetMultipleSerialNumberType NVARCHAR(10)
)  
AS  
BEGIN  
SET NOCOUNT ON;  
  
SELECT AssetId,IsRental,cast (null as nvarchar(max)) as SerialNumber   
INTO #DistinctAssetInfo   
FROM ReversalReceivableDetail_Extract   
WHERE ErrorCode IS NULL AND IsVertexSupported = 1 AND JobStepInstanceId = @JobStepInstanceId   
GROUP BY AssetId,IsRental  

UPDATE AD
	SET AD.SerialNumber=ASN.SerialNumber  
FROM #DistinctAssetInfo AD
JOIN (SELECT
		ASN.AssetId,
		SerialNumber = CASE WHEN count(ASN.Id) > 1 THEN @AssetMultipleSerialNumberType ELSE MAX(ASN.SerialNumber) END  
		FROM (Select Distinct AssetId from #DistinctAssetInfo) A 
		JOIN AssetSerialNumbers ASN on A.AssetId = ASN.AssetId AND ASN.IsActive=1
		GROUP BY ASN.AssetId ) ASN
ON ASN.AssetId = AD.AssetId  

;WITH cte_DistinctNonSKUAssetId  
as  
(  
Select AssetId,SerialNumber from #DistinctAssetInfo  
JOIN Assets ON #DistinctAssetInfo.AssetId = Assets.Id  
JOIN LegalEntities L ON Assets.LegalEntityId = L.Id  
WHERE Assets.IsSKU = 0 OR #DistinctAssetInfo.IsRental = 0 OR L.IsAssessSalesTaxAtSKULevel = 0
GROUP BY #DistinctAssetInfo.AssetId,#DistinctAssetInfo.SerialNumber   
) 

INSERT INTO ReversalFlexFieldDetail_Extract  
 (AssetId, GrossVehicleWeight, SaleLeasebackCode, IsElectronicallyDelivered, SalesTaxExemptionLevel,   
 AssetCatalogNumber, AssetTypeId, CreatedById, CreatedTime, JobStepInstanceId,Usage,AssetUsageCondition,AssetSerialOrVIN,IsSKU,AssetSKUId)  
SELECT AssetId = AI.AssetId,   
    GrossVehicleWeight = ISNULL(A.GrossVehicleWeight ,0),  
    SaleLeasebackCode = SLBCC.Code,  
    IsElectronicallyDelivered = ISNULL(A.IsElectronicallyDelivered,CONVERT(BIT,0)),  
    SalesTaxExemptionLevel = CAST(STELC.Name AS NVARCHAR),  
    AssetCatalogNumber = AC.CollateralCode,  
    AssetTypeId = A.TypeId,  
    CreatedById = 1,  
    CreatedTime = SYSDATETIMEOFFSET(),  
    JobStepInstanceId = @JobStepInstanceId,  
    AU.Usage,  
    A.UsageCondition AS AssetUsageCondition,  
    AI.SerialNumber AS AssetSerialOrVIN,  
    0,  
    NULL  
FROM cte_DistinctNonSKUAssetId AI  
INNER JOIN Assets A ON AI.AssetId = A.Id  
INNER JOIN LegalEntities L ON A.LegalEntityId = L.Id  
LEFT JOIN AssetUsages AU ON A.AssetUsageId = AU.Id  
LEFT JOIN AssetCatalogs AC ON A.AssetCatalogId = AC.Id  
LEFT JOIN SaleLeasebackCodeConfigs SLBCC ON A.SaleLeasebackCodeId = SLBCC.Id  
LEFT JOIN SalesTaxExemptionLevelConfigs STELC ON A.SalesTaxExemptionLevelId = STELC.Id  
 
  
  
INSERT INTO ReversalFlexFieldDetail_Extract  
 (AssetId, GrossVehicleWeight, SaleLeasebackCode, IsElectronicallyDelivered, SalesTaxExemptionLevel,   
 AssetCatalogNumber, AssetTypeId, CreatedById, CreatedTime, JobStepInstanceId,Usage,AssetUsageCondition,AssetSerialOrVIN,IsSKU,AssetSKUId)  
  
SELECT AssetId = AI.AssetId,   
    GrossVehicleWeight = ISNULL(A.GrossVehicleWeight ,0),  
    SaleLeasebackCode = SLBCC.Code,  
    IsElectronicallyDelivered = ISNULL(A.IsElectronicallyDelivered,CONVERT(BIT,0)),  
    SalesTaxExemptionLevel = CAST(STELC.Name AS NVARCHAR),  
    AssetCatalogNumber = AC.CollateralCode,  
    AssetTypeId = A.TypeId,  
    CreatedById = 1,  
    CreatedTime = SYSDATETIMEOFFSET(),  
    JobStepInstanceId = @JobStepInstanceId,  
    AU.Usage,  
    A.UsageCondition AS AssetUsageCondition,  
    AI.SerialNumber AS AssetSerialOrVIN,  
    A.IsSKU,  
    ASKU.Id  
FROM #DistinctAssetInfo AI  
INNER JOIN Assets A ON AI.AssetId = A.Id  
INNER JOIN LegalEntities L ON A.LegalEntityId = L.Id  
INNER JOIN AssetSKUs ASKU ON A.id = ASKU.AssetId  
LEFT JOIN AssetUsages AU ON A.AssetUsageId = AU.Id  
LEFT JOIN AssetCatalogs AC ON ASKU.AssetCatalogId = AC.Id  
LEFT JOIN SaleLeasebackCodeConfigs SLBCC ON A.SaleLeasebackCodeId = SLBCC.Id  
LEFT JOIN SalesTaxExemptionLevelConfigs STELC ON A.SalesTaxExemptionLevelId = STELC.Id  
WHERE IsRental = 1 AND L.IsAssessSalesTaxAtSKULevel = 1  
  
  
END

GO

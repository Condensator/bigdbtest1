SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[InsertAssetSKUDetails]
(
	@CTEntityType		NVARCHAR(10),
	@JobStepInstanceId	BIGINT
)
AS
BEGIN

--Service only Assets Info

CREATE TABLE #CTE_DistinctAssetIds
(
	AssetId BIGINT,
	ContractId BIGINT
)

INSERT INTO #CTE_DistinctAssetIds
SELECT AssetId,ContractId  
FROM SalesTaxReceivableDetailExtract
WHERE EntityType = @CTEntityType 
	  AND JobStepInstanceId = @JobStepInstanceId 
	  AND IsAssessSalesTaxAtSKULevel = 1
GROUP BY AssetId, ContractId

CREATE INDEX IX_AssetId On #CTE_DistinctAssetIds(AssetId)

INSERT INTO SalesTaxAssetSKUDetailExtract
(AssetSKUId,AssetId,IsExemptAtAssetSKU,LeaseFinanceId,NBVAmount,JobStepInstanceId)
SELECT
     AssetSKUId = AK.id,
     AssetId = A.Id,    
	 IsExemptAtSKU = AK.IsSalesTaxExempt,
	 LeaseFinanceId= LeaseFinances.Id,
	 NBVAmount  = 0,
	 @JobStepInstanceId
FROM
#CTE_DistinctAssetIds Asset
INNER JOIN Assets A ON A.Id = Asset.AssetId
INNER JOIN AssetSKUs AK  ON A.id = AK.AssetId 
INNER JOIN LeaseFinances  on LeaseFinances.ContractID = Asset.ContractID AND IsCurrent =1
WHERE A.IsServiceOnly=1;

INSERT INTO SalesTaxAssetSKUDetailExtract
(AssetSKUId,AssetId,ContractId,IsExemptAtAssetSKU,LeaseAssetId,LeaseAssetSKUId, 
LeaseFinanceId,NBVAmount,JobStepInstanceId)
SELECT
     AssetSKUId = AK.id,
     AssetId = A.Id,
	 ContractId = Asset.ContractId,
	 IsExemptAtSKU = AK.IsSalesTaxExempt,
	 LeaseAssetId = LA.Id,
	 LeaseAssetSKUId = LASK.Id,
	 LeaseFinanceId = LA.LeaseFinanceId,
	 NBVAmount  = LASK.NBV_Amount - LASK.CapitalizedSalesTax_Amount,
	 @JobStepInstanceId
FROM #CTE_DistinctAssetIds Asset
INNER JOIN Assets A ON A.Id = Asset.AssetId
INNER JOIN AssetSKUs AK  ON A.id = AK.AssetId 
INNER JOIN LeaseFinances LF on LF.ContractID = Asset.ContractID AND LF.IsCurrent =1
INNER JOIN LeaseAssets LA ON LA.LeaseFinanceID = LF.Id and LA.AssetId = A.id 
	AND (LA.IsActive = 1 OR (LA.IsActive = 0 AND LA.TerminationDate IS NOT NULL))
INNER JOIN LeaseAssetSKUs LASK on LA.id = LASK.LeaseAssetId AND  AK.id = LASK.AssetSKUId AND LASK.IsActive = 1;

UPDATE SalesTaxReceivableSKUDetailExtract
	SET LeaseAssetSKUId = SASK.LeaseAssetSKUId
FROM 
	SalesTaxReceivableSKUDetailExtract RDSK 
INNER JOIN 
	SalesTaxAssetSKUDetailExtract SASK 
ON 
	RDSK.AssetSKUId = SASK.AssetSKUId AND RDSK.ContractId = SASK.ContractId
	AND RDSK.JobStepInstanceId = @JobStepInstanceId
	AND SASK.JobStepInstanceId = @JobStepInstanceId;

END

GO

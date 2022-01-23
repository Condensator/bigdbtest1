SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[InsertAssetDetails]
(
	@CapitalizedSalesTaxAssetType	NVARCHAR(200),
	@CTEntityType					NVARCHAR(10),
	@CUEntityType					NVARCHAR(10),
	@JobStepInstanceId				BIGINT
)
AS
BEGIN

-- Customer Based Assets

WITH CTE_DistinctAssetIds AS
(
	SELECT DISTINCT AssetId,IsAssessSalesTaxAtSKULevel FROM SalesTaxReceivableDetailExtract
	WHERE EntityType = @CUEntityType AND JobStepInstanceId = @JobStepInstanceId
)
INSERT INTO SalesTaxAssetDetailExtract
(AssetId, IsExemptAtAsset, IsCapitalizedSalesTaxAsset, IsPrepaidUpfrontTax,
 LeaseFinanceId,NBVAmount,JobStepInstanceId,IsSKU,IsAssetFromOldFinance)
SELECT
     AssetId = A.Id,    
	 IsExemptAtAsset = A.IsTaxExempt,
	 IsCapitalizedSalesTaxAsset =  0,
	 IsPrepaidUpfrontTax =  0,
	 LeaseFinanceId= null,
	 NBVAmount  = 0,
	 @JobStepInstanceId,
	 IsSKU = CASE WHEN Asset.IsAssessSalesTaxAtSKULevel = 1 THEN A.IsSKU ELSE 0 END,
	 0 IsAssetFromOldFinance
FROM
CTE_DistinctAssetIds Asset
INNER JOIN Assets A ON A.Id = Asset.AssetId;

--Service only Assets Info

WITH CTE_DistinctAssetIds AS
(
	SELECT DISTINCT AssetId,ContractId,IsAssessSalesTaxAtSKULevel FROM SalesTaxReceivableDetailExtract
	WHERE EntityType = @CTEntityType AND JobStepInstanceId = @JobStepInstanceId
)
INSERT INTO SalesTaxAssetDetailExtract
(AssetId, ContractId,IsExemptAtAsset, IsCapitalizedSalesTaxAsset, IsPrepaidUpfrontTax,
LeaseFinanceId,NBVAmount,JobStepInstanceId,IsSKU,IsAssetFromOldFinance)
SELECT
     AssetId = A.Id,    
	 Asset.ContractId, 
	 IsExemptAtAsset = A.IsTaxExempt,
	 IsCapitalizedSalesTaxAsset =  0,
	 IsPrepaidUpfrontTax =  0,
	 LeaseFinanceId= LeaseFinances.Id,
	 NBVAmount  = 0,
	 @JobStepInstanceId,
	 IsSKU = CASE WHEN Asset.IsAssessSalesTaxAtSKULevel = 1 THEN A.IsSKU ELSE 0 END
	 ,0 IsAssetFromOldFinance
FROM
CTE_DistinctAssetIds Asset
INNER JOIN Assets A ON A.Id = Asset.AssetId
INNER JOIN LeaseFinances  on LeaseFinances.ContractID = Asset.ContractID AND IsCurrent =1
WHERE A.IsServiceOnly=1;

-- Contract Based Assets Info

WITH CTE_DistinctAssetIds AS
(
	SELECT DISTINCT AssetId, ContractID,IsAssessSalesTaxAtSKULevel FROM SalesTaxReceivableDetailExtract
	WHERE EntityType = @CTEntityType AND JobStepInstanceId = @JobStepInstanceId
)

INSERT INTO SalesTaxAssetDetailExtract
(AssetId,ContractId,IsExemptAtAsset,LeaseAssetId, IsCapitalizedSalesTaxAsset,IsPrepaidUpfrontTax,
LeaseFinanceId,NBVAmount,JobStepInstanceId, OriginalTaxBasisType,AcquisitionLocationId,IsSKU,CapitalizedOriginalAssetId,IsAssetFromOldFinance)

SELECT [AssetId],[ContractId],[IsExemptAtAsset],[LeaseAssetId], [IsCapitalizedSalesTaxAsset],[IsPrepaidUpfrontTax],
		[LeaseFinanceId],[NBVAmount],[JobStepInstanceId], [OriginalTaxBasisType],[AcquisitionLocationId],[IsSKU],[CapitalizedOriginalAssetId],[IsAssetFromOldFinance] FROM
(
SELECT
     AssetId = A.Id,
	 ContractId = Asset.ContractId,
	 IsExemptAtAsset = A.IsTaxExempt,
	 LeaseAssetId = LA.Id,
	 IsCapitalizedSalesTaxAsset =  CASE WHEN ATS.Name = @CapitalizedSalesTaxAssetType THEN 1 ELSE 0 END ,
	 IsPrepaidUpfrontTax =  LA.IsPrepaidUpfrontTax,
	 LeaseFinanceId = LA.LeaseFinanceId,
	 NBVAmount  = LA.NBV_Amount - LA.CapitalizedSalesTax_Amount,
	 @JobStepInstanceId JobStepInstanceId,
	 TB.Name OriginalTaxBasisType,
	 LA.AcquisitionLocationId,
	 IsSKU = CASE WHEN Asset.IsAssessSalesTaxAtSKULevel = 1 THEN A.IsSKU ELSE 0 END,
	 ROW_NUMBER() OVER (PARTITION BY LF.ContractId,A.Id ORDER BY LF.Id DESC) RowNumber,
	 CASE WHEN ATS.Name = @CapitalizedSalesTaxAssetType THEN CLA.AssetId ELSE CAST(NULL AS BIGINT) END CapitalizedOriginalAssetId,
	 CASE WHEN (LF.IsCurrent=0 AND LA.IsActive=1 AND LA.TerminationDate IS NULL) AND ATS.IsSoft = 0 THEN CAST(1 AS BIT)  ELSE CAST(0 AS BIT) END AS IsAssetFromOldFinance
FROM CTE_DistinctAssetIds Asset
INNER JOIN Assets A ON A.Id = Asset.AssetId
INNER JOIN LeaseFinances LF on LF.ContractID = Asset.ContractID
INNER JOIN LeaseAssets LA ON LA.LeaseFinanceID = LF.Id and LA.AssetId = A.Id
AND (LA.IsActive = 1 OR (LA.IsActive = 0 AND LA.TerminationDate IS NOT NULL))
INNER JOIN AssetTypes ATS ON A.TypeId = ATS.Id
LEFT JOIN LeaseTaxAssessmentDetails LTA ON LF.Id = LTA.LeaseFinanceId AND LTA.IsActive = 1
AND LA.LeaseTaxAssessmentDetailId = LTA.Id
LEFT JOIN LeaseTaxAssessmentTaxBasisTypes LTATB ON LTA.Id = LTATB.LeaseTaxAssessmentDetailId
AND LTATB.IsOtherBasisType = 0
LEFT JOIN TaxBasisTypes TB ON LTATB.TaxBasisTypeId = TB.Id
LEFT JOIN LeaseAssets CLA ON LA.LeaseFinanceID = LF.Id AND LA.CapitalizedForId = CLA.Id
WHERE (LF.IsCurrent =1 OR (ATS.IsSoft = 1 AND LF.BookingStatus<>'Inactive')) OR(LF.IsCurrent=0 AND LA.IsActive=1 AND LA.TerminationDate IS NULL AND LF.BookingStatus = 'Commenced')) AS SalesTaxAssetDetails
WHERE SalesTaxAssetDetails.RowNumber = 1;

UPDATE SalesTaxReceivableDetailExtract
	SET LeaseAssetId = SA.LeaseAssetId
FROM 
	SalesTaxReceivableDetailExtract RD 
INNER JOIN 
	SalesTaxAssetDetailExtract SA 
ON 
	RD.AssetId = SA.AssetId AND RD.ContractId = SA.ContractId
	AND RD.JobStepInstanceId = @JobStepInstanceId
END

GO

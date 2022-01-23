SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--SP to fetch asset SKU flex field details to call vertex

CREATE PROCEDURE [dbo].[InsertVertexAssetSKUDetail]
(
	@JobStepInstanceId BIGINT
)
AS
BEGIN

INSERT INTO VertexAssetSKUDetailExtract
(AssetSKUId,AssetId,  AssetType, JobStepInstanceId , ContractId)

SELECT
     AssetSKUId = ASK.Id,
     AssetId = A.AssetId,
     AssetType = ACC.ClassCode,
	 JobStepInstanceId = @JobStepInstanceId,
	 A.ContractId
FROM VertexAssetDetailExtract A 
INNER JOIN AssetSKUs ASK ON A.AssetId = ASK.AssetId  
INNER JOIN AssetTypes ATS ON ASK.TypeId = ATS.Id
LEFT JOIN AssetClassCodes ACC ON ATS.AssetClassCodeId = ACC.Id
WHERE A.JobStepInstanceId = @JobStepInstanceId AND A.IsSKU = 1

END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InsertSalesTaxReversalAssetLocationDetails]
(
@JobStepInstanceId BIGINT
)
AS
BEGIN
WITH CTE_DistinctAssetLocationIds AS
(
SELECT DISTINCT AssetLocationId FROM ReversalReceivableDetail_Extract WHERE ErrorCode IS NULL AND IsVertexSupported = 1 AND JobStepInstanceId = @JobStepInstanceId
)
INSERT INTO ReversalAssetLocationDetail_Extract
(AssetLocationId, LocationEffectiveDate, LienCredit, ReciprocityAmount, CreatedById, CreatedTime, JobStepInstanceId)
SELECT 
	AssetLocationId = AL.Id,
	LocationEffectiveDate = AL.EffectiveFromDate,
	LienCredit = ISNULL(AL.LienCredit_Amount, 0.00),
	ReciprocityAmount = ISNULL(AL.ReciprocityAmount_Amount, 0.00),
	CreatedById = 1,
	CreatedTime = SYSDATETIMEOFFSET(),
	JobStepInstanceId = @JobStepInstanceId
FROM CTE_DistinctAssetLocationIds DAL
INNER JOIN AssetLocations AL ON DAL.AssetLocationId = AL.Id
;
END

GO

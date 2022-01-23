SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetAssetLocationTaxBasisProcessingDetail]
(
@BatchId BIGINT,
@JobStepInstanceId BIGINT
)
AS
BEGIN
SELECT
CustomerNumber,
City,
Country,
ContractType,
LeaseType,
LeaseUniqueId,
ContractId,
Company,
Currency,
ToState,
AssetId,
LineItemId,
AssetLocationId AS CustomerAssetLocationId,
LocationId,
DueDate,
TaxAreaId,
LocationCode
FROM AssetLocationTaxBasisProcessingDetail_Extract
WHERE BatchId = @BatchId AND JobStepInstanceId = @JobStepInstanceId AND Company IS NOT NULL
END

GO

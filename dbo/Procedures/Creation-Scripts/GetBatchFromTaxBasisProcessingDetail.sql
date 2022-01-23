SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetBatchFromTaxBasisProcessingDetail] (@BatchId BIGINT)
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
CustomerAssetLocationId,
LocationId,
DueDate
FROM TaxBasisProcessingDetail_Extract
WHERE @BatchId = BatchId
END

GO

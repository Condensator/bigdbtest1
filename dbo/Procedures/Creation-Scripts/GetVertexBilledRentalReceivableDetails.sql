SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




-- SP to insert billed rental details
CREATE PROCEDURE [dbo].[GetVertexBilledRentalReceivableDetails]
(
@ReceivableDetailIds IDs Readonly,
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET,
@JobStepInstanceId BIGINT
)
AS
BEGIN
SET NOCOUNT ON;

CREATE TABLE #ExtractedVertexBilledRentalReceivableDetails
(
	RevenueBilledToDate_Amount decimal(16, 2) NOT NULL,
	RevenueBilledToDate_Currency nvarchar(3) NOT NULL,
	CumulativeAmount_Amount decimal(16, 2) NOT NULL,
	CumulativeAmount_Currency nvarchar(3) NOT NULL,
	ContractId bigint NOT NULL,
	ReceivableDetailId bigint NULL,
	AssetId bigint NULL,
	StateId bigint NULL,
	AssetSKUId bigint NULL
)

INSERT INTO #ExtractedVertexBilledRentalReceivableDetails
(RevenueBilledToDate_Amount, RevenueBilledToDate_Currency, CumulativeAmount_Amount, CumulativeAmount_Currency, 
 ContractId, ReceivableDetailId, AssetId, StateId,AssetSKUId)
SELECT
	 R.ExtendedPrice 
	,R.Currency
	,R.AmountBilledToDate 
	,R.Currency
	,R.ContractId
	,R.ReceivableDetailId
	,R.AssetId
	,R.StateId
	,NULL as AssetSKUId
FROM SalesTaxReceivableDetailExtract R 
JOIN VertexReceivableCodeDetailExtract RC ON R.ReceivableCodeId = RC.ReceivableCodeId AND RC.IsRental = 1 AND R.JobStepInstanceId = RC.JobStepInstanceId
JOIN @ReceivableDetailIds RD ON R.ReceivableDetailId = RD.Id AND R.ContractId IS NOT NULL AND R.JobStepInstanceId = @JobStepInstanceId
INNER JOIN SalesTaxAssetDetailExtract SA ON  R.AssetId = SA.AssetId AND R.JobStepInstanceId = SA.JobStepInstanceId
AND SA.IsSKU = 0

INSERT INTO #ExtractedVertexBilledRentalReceivableDetails
(RevenueBilledToDate_Amount, RevenueBilledToDate_Currency, CumulativeAmount_Amount, CumulativeAmount_Currency, 
  ContractId, ReceivableDetailId, AssetId, StateId,AssetSKUId)
SELECT
	 RS.ExtendedPrice 
	,R.Currency
	,RS.AmountBilledToDate 
	,R.Currency
	,R.ContractId
	,R.ReceivableDetailId
	,R.AssetId
	,R.StateId
	,RS.AssetSKUId
FROM SalesTaxReceivableDetailExtract R 
JOIN VertexReceivableCodeDetailExtract RC ON R.ReceivableCodeId = RC.ReceivableCodeId AND RC.IsRental = 1 AND R.JobStepInstanceId = RC.JobStepInstanceId
JOIN @ReceivableDetailIds RD ON R.ReceivableDetailId = RD.Id AND R.ContractId IS NOT NULL AND R.JobStepInstanceId = @JobStepInstanceId
INNER JOIN SalesTaxAssetDetailExtract SA ON  R.AssetId = SA.AssetId AND R.JobStepInstanceId = SA.JobStepInstanceId
AND SA.IsSKU = 1
--Added For SKU   
INNER JOIN VertexAssetSKUDetailExtract AV ON R.AssetId = AV.AssetId AND R.JobStepInstanceId = AV.JobStepInstanceId
AND R.ContractId = AV.ContractId
INNER JOIN SalesTaxReceivableSKUDetailExtract RS ON R.ReceivableDetailId = RS.ReceivableDetailId
AND R.AssetId = R.AssetId AND AV.AssetSKUId = RS.AssetSKUId AND R.JobStepInstanceId = RS.JobStepInstanceId

SELECT 
	RevenueBilledToDate_Amount,
	RevenueBilledToDate_Currency,
	CumulativeAmount_Amount,
	CumulativeAmount_Currency, 
	ContractId,
	ReceivableDetailId,
	AssetId,
	StateId,
	AssetSKUId
FROM #ExtractedVertexBilledRentalReceivableDetails

END
DROP TABLE #ExtractedVertexBilledRentalReceivableDetails

GO

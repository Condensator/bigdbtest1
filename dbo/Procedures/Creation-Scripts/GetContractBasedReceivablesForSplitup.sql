SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetContractBasedReceivablesForSplitup]
(
@BatchSplitCountSize BIGINT,
@JobStepInstanceId BIGINT
)
AS
BEGIN
SET NOCOUNT ON;

CREATE TABLE #DistinctReceivableDetails
(
	ReceivableDetailId	BIGINT,
	ExtendedPrice		DECIMAL (16, 2)
)


CREATE INDEX IX_DistinctReceivableDetails
ON #DistinctReceivableDetails (ReceivableDetailId);

SELECT 
	 DISTINCT TOP 
	 (@BatchSplitCountSize)
	 STC.ReceivableDetailId
	,STC.AssetId
	,STC.CustomerCost
	,STC.ExtendedPrice
INTO #ReceivableAssetDetails
FROM
SalesTaxContractBasedSplitupReceivableDetailExtract STC
WHERE IsProcessed = 0 AND STC.JobStepInstanceId = @JobStepInstanceId

INSERT INTO #DistinctReceivableDetails
SELECT
	ReceivableDetailId
	,ExtendedPrice
FROM #ReceivableAssetDetails
GROUP BY
	ReceivableDetailId
	,ExtendedPrice
;

SELECT * FROM #DistinctReceivableDetails

SELECT 
	STC.ReceivableDetailId
	,STC.AssetId
	,STC.CustomerCost
	,STC.ExtendedPrice
FROM #DistinctReceivableDetails RAD
JOIN SalesTaxContractBasedSplitupReceivableDetailExtract STC 
ON RAD.ReceivableDetailId = STC.ReceivableDetailId
WHERE @JobStepInstanceId = STC.JobStepInstanceId

END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--cumulate Rental Receivable extended price

CREATE PROCEDURE [dbo].[PrepareBilledRentalReceivableDetail]
(
	@JobStepInstanceId BIGINT
)
AS
BEGIN

SET NOCOUNT ON;

CREATE TABLE #VertexBilledRentalReceivableDetails
(
	AssetId BIGINT , 
	AssetSKUId BIGINT,
	ReceivableId BIGINT,
	StateId BIGINT,
	ExtendedPrice DECIMAL(16,2),
	Currency NVARCHAR(3),
	ContractId BIGINT,
	ReceivableDetailId BIGINT,
	CumulativeAmount DECIMAL(16,2),
	CreatedById BIGINT,
	CreatedTime DATETIMEOFFSET,
	ReceivableDueDate DATE,
	RowNumber BIGINT,
	JobStepInstanceId BIGINT,
	IsSKU BIT
)

CREATE INDEX IX_AssetId On #VertexBilledRentalReceivableDetails(AssetId)
CREATE INDEX IX_ReceivableDetailId On #VertexBilledRentalReceivableDetails(ReceivableDetailId)

INSERT INTO #VertexBilledRentalReceivableDetails
SELECT 
	 AssetId = R.AssetId
    ,AssetSKUId = NULL
	,ReceivableId = R.ReceivableId
	,StateId = L.StateId
	,ExtendedPrice =  R.ExtendedPrice 
	,Currency = R.Currency
	,ContractId = R.ContractId
	,ReceivableDetailId = R.ReceivableDetailId
	,CumulativeAmount = CAST(0.00 AS DECIMAL(16,2))	
	,CreatedById = 1
    ,CreatedTime = SYSDATETIMEOFFSET()
	,ReceivableDueDate
	,ROW_NUMBER() OVER (PARTITION BY R.AssetId, R.ContractId, L.StateId ORDER BY ReceivableDueDate) AS RowNumber 
	,@JobStepInstanceId AS JobStepInstanceId
	,CAST(0 as bit) as IsSKU
FROM SalesTaxReceivableDetailExtract R 
INNER JOIN SalesTaxLocationDetailExtract L ON R.LocationId = L.LocationId AND R.JobStepInstanceId = L.JobStepInstanceId
INNER JOIN VertexReceivableCodeDetailExtract RT ON R.ReceivableCodeId = RT.ReceivableCodeId 
	AND RT.IsRental = 1 AND R.JobStepInstanceId = RT.JobStepInstanceId
INNER JOIN VertexAssetDetailExtract AV ON R.AssetId = AV.AssetId AND R.JobStepInstanceId = AV.JobStepInstanceId
AND R.ContractId = AV.ContractId AND AV.IsSKU = 0
WHERE R.IsVertexSupported = 1 AND R.InvalidErrorCode IS NULL 
AND R.ContractId IS NOT NULL AND R.AssetId IS NOT NULL
AND R.JobStepInstanceId = @JobStepInstanceId
;

INSERT INTO #VertexBilledRentalReceivableDetails
SELECT 
	 AssetId = R.AssetId
    ,AssetSKUId = RS.AssetSKUId
	,ReceivableId = R.ReceivableId
	,StateId = L.StateId
	,ExtendedPrice =  RS.ExtendedPrice 
	,Currency = R.Currency
	,ContractId = R.ContractId
	,ReceivableDetailId = R.ReceivableDetailId
	,CumulativeAmount = CAST(0.00 AS DECIMAL(16,2))	
	,CreatedById = 1
    ,CreatedTime = SYSDATETIMEOFFSET()
	,ReceivableDueDate
	,ROW_NUMBER() OVER (PARTITION BY R.AssetId, RS.AssetSKUId, R.ContractId, L.StateId ORDER BY ReceivableDueDate) AS RowNumber 
	,@JobStepInstanceId AS JobStepInstanceId
	,CAST(1 as bit) as IsSKU
FROM SalesTaxReceivableDetailExtract R 
INNER JOIN SalesTaxLocationDetailExtract L ON R.LocationId = L.LocationId AND R.JobStepInstanceId = L.JobStepInstanceId
INNER JOIN VertexReceivableCodeDetailExtract RT ON R.ReceivableCodeId = RT.ReceivableCodeId 
	AND RT.IsRental = 1 AND R.JobStepInstanceId = RT.JobStepInstanceId
INNER JOIN VertexAssetDetailExtract AV ON R.AssetId = AV.AssetId AND R.JobStepInstanceId = AV.JobStepInstanceId
AND R.ContractId = AV.ContractId
INNER JOIN SalesTaxReceivableSKUDetailExtract RS ON R.ReceivableDetailId = RS.ReceivableDetailId AND R.AssetId = RS.AssetId
AND R.JobStepInstanceId = RS.JobStepInstanceId
WHERE R.IsVertexSupported = 1 AND R.InvalidErrorCode IS NULL 
AND R.ContractId IS NOT NULL AND R.AssetId IS NOT NULL
AND R.JobStepInstanceId = @JobStepInstanceId
AND RT.JobStepInstanceId = @JobStepInstanceId
;

--Only the current receivable detail amount will be cumulated
UPDATE BR
	SET CumulativeAmount = BRSUM.Cumulative
FROM #VertexBilledRentalReceivableDetails BR
JOIN ((SELECT BR1.ReceivableDetailId, SUM(BR2.ExtendedPrice) as Cumulative
		FROM #VertexBilledRentalReceivableDetails BR1
		INNER JOIN #VertexBilledRentalReceivableDetails BR2 
		ON BR1.AssetId = BR2.AssetId AND BR1.AssetSKUId = BR2.AssetSKUId AND BR1.ContractId = BR2.ContractId AND BR1.StateId = BR2.StateId
		AND BR1.RowNumber >= BR2.RowNumber 
		GROUP BY BR1.ReceivableDetailId)
	  UNION
	  (SELECT
		BR1.ReceivableDetailId, SUM(BR2.ExtendedPrice) as Cumulative
		FROM #VertexBilledRentalReceivableDetails BR1
		INNER JOIN #VertexBilledRentalReceivableDetails BR2
		ON BR1.AssetId = BR2.AssetId AND BR1.ContractId = BR2.ContractId AND BR1.StateId = BR2.StateId
		AND BR1.RowNumber >= BR2.RowNumber
		where BR1.IsSKU=0
		GROUP BY BR1.ReceivableDetailId)) AS BRSUM
ON BR.ReceivableDetailId = BRSUM.ReceivableDetailId;

;WITH cte_TryReduceIndexScan
AS
(
SELECT AssetId FROM #VertexBilledRentalReceivableDetails GROUP BY AssetId
)
SELECT 
	--BRR.CumulativeAmount_Amount
	--,BRR.AssetId
	--,BRR.AssetSKUId
	--,BRR.ContractId
	--,BRR.StateId
	--,BRR.ReceivableDetailId
	BRR.Id
INTO #BilledRentalIds
FROM VertexBilledRentalReceivables BRR --WITH (FORCESEEK, INDEX(IX_Asset))
INNER JOIN cte_TryReduceIndexScan VBRD 
ON BRR.AssetId = VBRD.AssetId
WHERE BRR.IsActive = 1

Select CumulativeAmount_Amount
	,AssetId
	,AssetSKUId
	,ContractId
	,StateId
	,ReceivableDetailId
into  #BasicFilteredBilledRentals
from VertexBilledRentalReceivables
join #BilledRentalIds on VertexBilledRentalReceivables.Id = #BilledRentalIds.Id

--To cumulate with the latest stored data
;WITH CTE_CumulativeAmount 
AS
(
	SELECT 
		BRR.CumulativeAmount_Amount
		,BRR.AssetId
		,BRR.AssetSKUId
		,BRR.ContractId
		,BRR.StateId
		,ROW_NUMBER() OVER(PARTITION BY BRR.ContractId, BRR.AssetId,BRR.AssetSKUId, BRR.StateId ORDER BY R.DueDate DESC) AS RowNumber 
	FROM #BasicFilteredBilledRentals BRR 
	JOIN ReceivableDetails RD ON BRR.ReceivableDetailId = RD.Id
	JOIN Receivables R ON RD.ReceivableId = R.Id
	JOIN #VertexBilledRentalReceivableDetails VBRD ON VBRD.AssetId = BRR.AssetId AND (VBRD.AssetSKUId IS NULL OR BRR.AssetSKUId = VBRD.AssetSKUId)
	AND VBRD.StateId = BRR.StateId AND BRR.ContractId = VBRD.ContractId	
)
UPDATE BR
	SET CumulativeAmount = ISNULL(CA.CumulativeAmount_Amount,0.00) + CumulativeAmount
FROM #VertexBilledRentalReceivableDetails BR
JOIN CTE_CumulativeAmount CA ON BR.ContractId = CA.ContractId AND BR.AssetId = CA.AssetId AND  (BR.AssetSKUId IS NULL OR BR.AssetSKUId = CA.AssetSKUId) 
AND BR.StateId = CA.StateId AND CA.RowNumber = 1;

UPDATE STR
	SET STR.AmountBilledToDate = BR.CumulativeAmount
FROM SalesTaxReceivableDetailExtract STR
JOIN #VertexBilledRentalReceivableDetails BR ON STR.ReceivableDetailId = BR.ReceivableDetailId
AND STR.JobStepInstanceId = BR.JobStepInstanceId;

DROP TABLE #VertexBilledRentalReceivableDetails
END

GO

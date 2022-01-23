SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InsertNonVertexUpfrontRentalDetail]
(
	@URTaxBasisTypeName					NVARCHAR(100),
	@CapitalLeaseRentalReceivableType	NVARCHAR(100),
	@OperatingLeaseRentalReceivableType NVARCHAR(100),
	@CTEntityType						NVARCHAR(100),
	@JobStepInstanceId					BIGINT
)
AS
BEGIN
SET NOCOUNT ON;
WITH CTE_DistinctReceivableCode AS
(
SELECT
DISTINCT TaxReceivableName, ReceivableCodeId
FROM NonVertexReceivableCodeDetailExtract
WHERE IsRental = 1 AND JobStepInstanceId = @JobStepInstanceId
)
SELECT
R.AssetId
,R.ContractId
,R.ReceivableDetailId
,CAST(0 AS BIT) IsUpfrontTaxApplicable
,CAST(0 AS DECIMAL(16,2)) FairMarketValue
,LocationEffectiveDate
,R.ReceivableDueDate
,R.ReceivableCodeId
,R.ExtendedPrice
,R.ReceivableId
INTO #SalesTaxUpfrontRentalDetails
FROM SalesTaxReceivableDetailExtract R
INNER JOIN SalesTaxAssetLocationDetailExtract STA ON R.AssetId = STA.AssetId AND R.ReceivableDueDate = STA.ReceivableDueDate
AND R.ReceivableDetailId = STA.ReceivableDetailId  AND R.JobStepInstanceId = STA.JobStepInstanceId
INNER JOIN NonVertexLocationDetailExtract STL ON STA.LocationId = STL.LocationId AND STL.JobStepInstanceId = @JobStepInstanceId
INNER JOIN CTE_DistinctReceivableCode STRT ON R.ReceivableCodeId = STRT.ReceivableCodeId
INNER JOIN NonVertexLeaseDetailExtract STLA ON R.ContractId = STLA.ContractId AND STLA.JobStepInstanceId = @JobStepInstanceId
WHERE STA.LocationTaxBasisType IN (@URTaxBasisTypeName) AND R.ContractId IS NOT NULL
AND STRT.TaxReceivableName IN (@CapitalLeaseRentalReceivableType, @OperatingLeaseRentalReceivableType)
AND R.ReceivableDueDate >= STLA.CommencementDate AND IsVertexSupported = 0 AND InvalidErrorCode IS NULL
AND R.JobStepInstanceId = @JobStepInstanceId
AND R.IsRenewal = 0
;
SELECT
RD.AdjustmentBasisReceivableDetailId AdjustmentId
,RD.Id
,RD.ReceivableId
INTO #AdjustmentDetail
FROM ReceivableDetails RD
JOIN #SalesTaxUpfrontRentalDetails UR ON RD.Id = UR.ReceivableDetailId
AND RD.AdjustmentBasisReceivableDetailId IS NOT NULL
;
SELECT
AD.Id ReceivableDetailId, STA.AssetId, STA.ReceivableDueDate, AD.AdjustmentId, AD.ReceivableId
INTO #AdjustmentUpfrontRentalDetails
FROM #SalesTaxUpfrontRentalDetails STA
INNER JOIN #AdjustmentDetail AD ON STA.ReceivableDetailId = AD.Id
;
SELECT
AD.AdjustmentId ReceivableDetailId, STA.AssetId, STA.ReceivableDueDate, CAST(NULL AS BIGINT) AdjustmentId, STA.ReceivableId
INTO #OriginalUpfrontRentalDetails
FROM #SalesTaxUpfrontRentalDetails STA
INNER JOIN #AdjustmentDetail AD ON STA.ReceivableDetailId = AD.AdjustmentId
;
DELETE STA FROM #SalesTaxUpfrontRentalDetails STA
JOIN #AdjustmentDetail AD ON STA.ReceivableDetailId = AD.Id
;
DELETE STA FROM #SalesTaxUpfrontRentalDetails STA
JOIN #AdjustmentDetail AD ON STA.ReceivableDetailId = AD.AdjustmentId
;
SELECT
ContractId, AssetId, MIN(LocationEffectiveDate) LocationEffectiveDate
INTO #UpfrontMinLocationEffectiveReceivables
FROM #SalesTaxUpfrontRentalDetails
GROUP BY ContractId, AssetId;
;
SELECT
R.Duedate ReceivableDueDate,
RD.AssetId,
RD.Id ReceivableDetailId,
UR.ContractId,
CASE WHEN RD.PreCapitalizationRent_Amount <> 0.00 THEN RD.PreCapitalizationRent_Amount ELSE RD.Amount_Amount END AS Amount,
R.Id ReceivableId,
RD.AdjustmentBasisReceivableDetailId
INTO #AllContractUpfrontDetails
FROM Receivables R
JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId
JOIN #UpfrontMinLocationEffectiveReceivables UR ON R.EntityId = UR.ContractId AND RD.AssetId = UR.AssetId
JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
WHERE R.EntityType = @CTEntityType AND RT.IsRental = 1 AND R.IsActive = 1
AND (RT.Name = @CapitalLeaseRentalReceivableType OR RT.Name = @OperatingLeaseRentalReceivableType);

SELECT
RD.AdjustmentBasisReceivableDetailId AdjustmentId
,RD.ReceivableDetailId
,RD.ReceivableId
INTO #AllAdjustmentDetail
FROM #AllContractUpfrontDetails RD
WHERE RD.AdjustmentBasisReceivableDetailId IS NOT NULL
;
DELETE STA FROM #AllContractUpfrontDetails STA
INNER JOIN #AllAdjustmentDetail AD ON STA.ReceivableDetailId = AD.ReceivableDetailId
;
DELETE STA FROM #AllContractUpfrontDetails STA
INNER JOIN #AllAdjustmentDetail AD ON STA.ReceivableDetailId = AD.AdjustmentId
;
WITH CTE_UpfrontMinDueReceivables  AS
(
SELECT
AssetId, LocationEffectiveDate, MIN(ReceivableDueDate) ReceivableDueDate, ContractId
FROM #SalesTaxUpfrontRentalDetails
GROUP BY AssetId, LocationEffectiveDate, ContractId
)
,CTE_ContractUpfrontDetails AS
(
SELECT
R.ReceivableDueDate,
R.AssetId,
R.ReceivableDetailId,
R.ContractId,
R.Amount,
R.ReceivableId
FROM #AllContractUpfrontDetails R
JOIN #UpfrontMinLocationEffectiveReceivables UR
ON R.ContractId = UR.ContractId AND R.AssetId = UR.AssetId
WHERE R.ReceivableDueDate >= UR.LocationEffectiveDate
)
SELECT
CurrentRental.AssetId
,CurrentRental.LocationEffectiveDate
,ContractRental.ReceivableDetailId
,ContractRental.ContractId
,ROW_NUMBER() OVER (PARTITION BY ContractRental.ContractId, CurrentRental.AssetId,
CurrentRental.LocationEffectiveDate ORDER BY ContractRental.ReceivableDueDate, ContractRental.ReceivableId) RowNumber
INTO #UpfrontReceivables
FROM CTE_UpfrontMinDueReceivables CurrentRental
INNER JOIN CTE_ContractUpfrontDetails ContractRental
ON CurrentRental.ContractId = ContractRental.ContractId
AND CurrentRental.AssetId = ContractRental.AssetId
WHERE ContractRental.ReceivableDueDate >= CurrentRental.LocationEffectiveDate
;
UPDATE #SalesTaxUpfrontRentalDetails
SET IsUpfrontTaxApplicable = 1
FROM #SalesTaxUpfrontRentalDetails UR
JOIN #UpfrontReceivables URDetails
ON UR.ReceivableDetailId = URDetails.ReceivableDetailId AND URDetails.RowNumber = 1
;
UPDATE #SalesTaxUpfrontRentalDetails
SET FairMarketValue = SumAmount
FROM #SalesTaxUpfrontRentalDetails CR
JOIN (SELECT
CUD.ContractId, CUD.AssetId, CRD.ReceivableDueDate, SUM(Amount) SumAmount
FROM #AllContractUpfrontDetails CUD
JOIN #SalesTaxUpfrontRentalDetails CRD ON CUD.AssetId = CRD.AssetId
AND CUD.ContractId = CRD.ContractId AND IsUpfrontTaxApplicable = 1
AND CUD.ReceivableDueDate >= CRD.ReceivableDueDate
GROUP BY CUD.ContractId, CUD.AssetId, CRD.ReceivableDueDate) FMVDetail
ON CR.ContractId = FMVDetail.ContractId AND CR.AssetId = FMVDetail.AssetId
AND CR.ReceivableDueDate = FMVDetail.ReceivableDueDate
WHERE IsUpfrontTaxApplicable = 1
;
SELECT
AD.AssetId, AD.ReceivableDetailId, (-1) * RD.FairMarketValue_Amount FairMarketValue,
1 AS CreatedById, SYSDATETIMEOFFSET() AS CreatedTime, @JobStepInstanceId AS JobStepInstanceId
INTO #AdjustmentUpfrontRentalAmountDetails
FROM #AdjustmentUpfrontRentalDetails AD
JOIN ReceivableTaxDetails RD ON AD.AdjustmentId = RD.ReceivableDetailId
AND RD.IsActive = 1 AND RD.FairMarketValue_Amount <> 0.00
;

INSERT INTO NonVertexUpfrontRentalDetailExtract
([AssetId], [ReceivableDetailId], [FairMarketValue],[JobStepInstanceId])
SELECT
[AssetId], [ReceivableDetailId], [FairMarketValue],@JobStepInstanceId
FROM #SalesTaxUpfrontRentalDetails
WHERE IsUpfrontTaxApplicable = 1
UNION ALL
SELECT
[AssetId], [ReceivableDetailId], FairMarketValue, @JobStepInstanceId
FROM #AdjustmentUpfrontRentalAmountDetails
UNION ALL
SELECT
[AssetId], [ReceivableDetailId], [FairMarketValue], [JobStepInstanceId] FROM
(
SELECT
OU.AssetId, OU.ReceivableDetailId, ST.FairMarketValue, @JobStepInstanceId AS JobStepInstanceId
,ROW_NUMBER() OVER (PARTITION BY OU.AssetId,  OU.ReceivableDueDate ORDER BY OU.ReceivableId) RowNumber
FROM #OriginalUpfrontRentalDetails OU
JOIN #SalesTaxUpfrontRentalDetails ST ON OU.AssetId = ST.AssetId
AND OU.ReceivableDueDate = ST.ReceivableDueDate
WHERE ST.IsUpfrontTaxApplicable = 1
) AS OriginalUpfrontCostDetails
WHERE OriginalUpfrontCostDetails.RowNumber = 1
UNION ALL
SELECT
[AssetId], [ReceivableDetailId], [FairMarketValue], [JobStepInstanceId] FROM
(
SELECT
AU.AssetId, AU.ReceivableDetailId,(-1) * ST.FairMarketValue AS FairMarketValue, @JobStepInstanceId AS JobStepInstanceId
,ROW_NUMBER() OVER (PARTITION BY AU.AssetId,  AU.ReceivableDueDate ORDER BY AU.ReceivableId) RowNumber
FROM #AdjustmentUpfrontRentalDetails AU
JOIN #SalesTaxUpfrontRentalDetails ST ON AU.AssetId = ST.AssetId
AND AU.ReceivableDueDate = ST.ReceivableDueDate
LEFT JOIN #AdjustmentUpfrontRentalAmountDetails AUC ON AU.AssetId = AUC.AssetId
AND AU.ReceivableDetailId = AUC.ReceivableDetailId
WHERE ST.IsUpfrontTaxApplicable = 1
AND AUC.ReceivableDetailId IS NULL
) AS AdjustmentUpfrontCostDetails
WHERE AdjustmentUpfrontCostDetails.RowNumber = 1
;
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InsertNonVertexUpFrontCostDetail]
(
	@UCTaxBasisTypeName					NVARCHAR(100),
	@InterimRentalReceivableType		NVARCHAR(100),
	@LeaseInterimInterestReceivableType NVARCHAR(100),
	@CPIBaseRentalReceivableType		NVARCHAR(100),
	@OperatingContractType				NVARCHAR(100),
	@JobStepInstanceId					BIGINT
)
AS
BEGIN
SET NOCOUNT ON;
WITH CTE_DistinctReceivableCode AS
(
SELECT
DISTINCT TaxReceivableName, ReceivableCodeId, JobStepInstanceId
FROM NonVertexReceivableCodeDetailExtract
WHERE IsRental = 1 AND JobStepInstanceId = @JobStepInstanceId
)
SELECT
R.AssetId
,R.ContractId
,R.ReceivableDetailId
,CAST(0 AS BIT) IsUpfrontTaxApplicable
,CAST(0 AS DECIMAL(16,2)) AssetCost
,R.ReceivableId
,R.PaymentScheduleId AS PaymentScheduleId
,LocationEffectiveDate
,R.ReceivableDueDate
,R.ReceivableCodeId
,STRT.TaxReceivableName ReceivableTypeName
INTO #SalesTaxUpfrontCostDetails
FROM SalesTaxReceivableDetailExtract R
INNER JOIN SalesTaxAssetLocationDetailExtract STA ON R.AssetId = STA.AssetId AND R.ReceivableDueDate = STA.ReceivableDueDate
AND R.ReceivableDetailId = STA.ReceivableDetailId AND R.JobStepInstanceId = STA.JobStepInstanceId
INNER JOIN NonVertexLocationDetailExtract STL ON STA.LocationId = STL.LocationId AND R.JobStepInstanceId = STL.JobStepInstanceId
INNER JOIN CTE_DistinctReceivableCode STRT ON R.ReceivableCodeId = STRT.ReceivableCodeId AND R.JobStepInstanceId = STRT.JobStepInstanceId
WHERE STA.LocationTaxBasisType IN (@UCTaxBasisTypeName) AND R.ContractId IS NOT NULL
AND R.PaymentScheduleId IS NOT NULL AND IsVertexSupported = 0 AND InvalidErrorCode IS NULL
AND STRT.TaxReceivableName <> @LeaseInterimInterestReceivableType AND STRT.TaxReceivableName <> @CPIBaseRentalReceivableType 
AND R.JobStepInstanceId = @JobStepInstanceId
;
SELECT
RD.AdjustmentBasisReceivableDetailId AdjustmentId
,RD.Id
,RD.ReceivableId
INTO #AdjustmentDetail
FROM ReceivableDetails RD
INNER JOIN #SalesTaxUpfrontCostDetails UR ON RD.Id = UR.ReceivableDetailId
AND RD.AdjustmentBasisReceivableDetailId IS NOT NULL
;
SELECT
AD.Id ReceivableDetailId, STA.AssetId, STA.ReceivableDueDate, AD.AdjustmentId, AD.ReceivableId
INTO #AdjustmentUpfrontCostDetails
FROM #SalesTaxUpfrontCostDetails STA
INNER JOIN #AdjustmentDetail AD ON STA.ReceivableDetailId = AD.Id
;
SELECT
AD.AdjustmentId ReceivableDetailId, STA.AssetId, STA.ReceivableDueDate, CAST(NULL AS BIGINT) AdjustmentId, STA.ReceivableId
INTO #OriginalUpfrontCostDetails
FROM #SalesTaxUpfrontCostDetails STA
INNER JOIN #AdjustmentDetail AD ON STA.ReceivableDetailId = AD.AdjustmentId
;
DELETE STA FROM #SalesTaxUpfrontCostDetails STA
INNER JOIN #AdjustmentDetail AD ON STA.ReceivableDetailId = AD.Id
;
DELETE STA FROM #SalesTaxUpfrontCostDetails STA
INNER JOIN #AdjustmentDetail AD ON STA.ReceivableDetailId = AD.AdjustmentId
;
SELECT
AssetId, MIN(LocationEffectiveDate) LocationEffectiveDate
INTO #UpfrontMinLocationEffectiveDateReceivables
FROM #SalesTaxUpfrontCostDetails GROUP BY AssetId, LocationEffectiveDate
;
SELECT
C.Id ContractId,
R.DueDate ReceivableDueDate,
RD.ReceivableId,
RD.Id ReceivableDetailId,
RD.AssetId,
RD.AdjustmentBasisReceivableDetailId
INTO #AllContractDetails
FROM Receivables R
INNER JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId
INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
INNER JOIN #UpfrontMinLocationEffectiveDateReceivables UC ON RD.AssetId = UC.AssetId
INNER JOIN Contracts C ON R.EntityId = C.Id
WHERE RT.Name <> @LeaseInterimInterestReceivableType AND RT.IsRental = 1
AND RT.Name <> @CPIBaseRentalReceivableType AND R.IsActive =1
;
SELECT
RD.AdjustmentBasisReceivableDetailId AdjustmentId
,RD.ReceivableDetailId
,RD.ReceivableId
INTO #AllAdjustmentDetail
FROM #AllContractDetails RD
WHERE RD.AdjustmentBasisReceivableDetailId IS NOT NULL
;
DELETE STA FROM #AllContractDetails STA
INNER JOIN #AllAdjustmentDetail AD ON STA.ReceivableDetailId = AD.ReceivableDetailId
;
DELETE STA FROM #AllContractDetails STA
INNER JOIN #AllAdjustmentDetail AD ON STA.ReceivableDetailId = AD.AdjustmentId
;
SELECT
RAT.ContractId,
LA.AssetId,
LA.NBVAmount,
ClassificationContractType,
LA.LeaseFinanceId AS LeaseFinanceId,
RAT.ReceivableDueDate,
RAT.ReceivableId,
RAT.ReceivableDetailId
INTO #ContractDetails
FROM #SalesTaxUpfrontCostDetails RAT
INNER JOIN NonVertexLeaseDetailExtract CT ON RAT.ContractId = CT.ContractId
INNER JOIN SalesTaxAssetDetailExtract LA ON CT.LeaseFinanceId = LA.LeaseFinanceId AND RAT.AssetId = LA.AssetId AND CT.JobStepInstanceId = LA.JobStepInstanceId
INNER JOIN LeasePaymentSchedules LPS ON RAT.PaymentScheduleId = LPS.Id AND CT.LeaseFinanceId = LPS.LeaseFinanceDetailId
INNER JOIN LeaseIncomeSchedules LIS ON CT.LeaseFinanceId = LIS.LeaseFinanceId
AND LIS.IncomeDate = LPS.EndDate
INNER JOIN NonVertexReceivableCodeDetailExtract STRT ON RAT.ReceivableCodeId = STRT.ReceivableCodeId AND STRT.JobStepInstanceId = @JobStepInstanceId
AND STRT.TaxReceivableName <> @LeaseInterimInterestReceivableType AND STRT.TaxReceivableName <> @CPIBaseRentalReceivableType 
AND STRT.IsRental = 1 AND CT.JobStepInstanceId = @JobStepInstanceId;

SELECT 	
	UC.AssetId,
	C.ClassificationContractType,
	UC.ReceivableDueDate,
	UC.ReceivableDetailId,
	R.JobStepInstanceId,
	MIN(LIS.IncomeDate) IncomeDate,
	MAX(LPS.LeaseFinanceDetailId) AS LeaseFinanceId,
	MAX(C.ContractId) AS ContractId
INTO #LeaseIncomeDetails
FROM #SalesTaxUpfrontCostDetails UC
	JOIN SalesTaxReceivableDetailExtract R ON UC.ReceivableDetailId = R.ReceivableDetailId
	JOIN NonVertexLeaseDetailExtract C ON R.ContractId = C.ContractId AND R.JobStepInstanceId = C.JobStepInstanceId
	JOIN LeasePaymentSchedules LPS ON LPS.Id = R.PaymentScheduleId AND LPS.IsActive = 1
	JOIN LeaseFinances LF ON C.ContractId = LF.ContractId
	JOIN LeaseIncomeSchedules LIS ON LIS.LeaseFinanceId = LF.Id AND LIS.IncomeDate BETWEEN LPS.StartDate AND LPS.EndDate AND LIS.IsSchedule = 1
WHERE R.JobStepInstanceId = @JobStepInstanceId
GROUP BY
	UC.AssetId,
	C.ClassificationContractType,
	UC.ReceivableDueDate,
	UC.ReceivableDetailId,
	R.JobStepInstanceId

SELECT
	LID.ClassificationContractType,    
	LID.ReceivableDueDate,    
	LID.ReceivableDetailId,    
	LID.AssetId,   
	MIN(LIS.Id) AS LeaseIncomeScheduleId,  
	LID.JobStepInstanceId,
	MAX(LID.LeaseFinanceId) AS LeaseFinanceId
INTO #UpfrontIncomeDetails 
FROM #LeaseIncomeDetails LID
	JOIN LeaseFinances LF ON LID.ContractId = LF.ContractId
	JOIN LeaseIncomeSchedules LIS ON LIS.LeaseFinanceId = LF.Id AND LID.IncomeDate = LIS.IncomeDate AND LID.JobStepInstanceId = @JobStepInstanceId AND LIS.IsSchedule = 1
GROUP BY    
	LID.ClassificationContractType,    
	LID.ReceivableDueDate,    
	LID.ReceivableDetailId,    
	LID.AssetId,    
	LID.JobStepInstanceId

SELECT
IncomeDetail.AssetId,
IncomeDetail.ClassificationContractType,
IncomeDetail.ReceivableDueDate,
IncomeDetail.ReceivableDetailId,
CASE WHEN IncomeDetail.ClassificationContractType = @OperatingContractType THEN AIS.OperatingBeginNetBookValue_Amount - LA.CapitalizedSalesTax_Amount 
	ELSE AIS.BeginNetBookValue_Amount - LA.CapitalizedSalesTax_Amount END AS NBV_Amount
INTO #AssetNBVDetails
FROM #UpfrontIncomeDetails IncomeDetail
JOIN AssetIncomeSchedules AIS ON IncomeDetail.LeaseIncomeScheduleId = AIS.LeaseIncomeScheduleId AND IncomeDetail.AssetId = AIS.AssetId
JOIN LeaseAssets LA ON AIS.AssetId = LA.AssetId AND LA.LeaseFinanceId = IncomeDetail.LeaseFinanceId
	AND (LA.IsActive = 1 OR (LA.IsActive = 0 AND LA.TerminationDate IS NOT NULL))
WHERE IncomeDetail.JobStepInstanceId = @JobStepInstanceId;
WITH CTE_UpfrontMinDueReceivables AS
(
SELECT
AssetId, LocationEffectiveDate, MIN(ReceivableDueDate) ReceivableDueDate
FROM #SalesTaxUpfrontCostDetails
GROUP BY AssetId, LocationEffectiveDate
)
,CTE_ContractUpfrontDetails AS
(
SELECT
R.ReceivableDueDate,
R.AssetId,
R.ReceivableDetailId,
R.ReceivableId
FROM #AllContractDetails R
INNER JOIN #UpfrontMinLocationEffectiveDateReceivables UC
ON R.AssetId = UC.AssetId
WHERE R.ReceivableDueDate >= UC.LocationEffectiveDate
)
SELECT
CurrentRental.AssetId
,CurrentRental.LocationEffectiveDate
,ContractRental.ReceivableDetailId
,ROW_NUMBER() OVER (PARTITION BY CurrentRental.AssetId, CurrentRental.LocationEffectiveDate
ORDER BY ContractRental.ReceivableDueDate, ContractRental.ReceivableId) RowNumber
INTO #UpfrontReceivables
FROM CTE_UpfrontMinDueReceivables CurrentRental
INNER JOIN CTE_ContractUpfrontDetails ContractRental
ON CurrentRental.AssetId = ContractRental.AssetId
WHERE ContractRental.ReceivableDueDate >= CurrentRental.LocationEffectiveDate
;
UPDATE #SalesTaxUpfrontCostDetails
SET IsUpfrontTaxApplicable = 1
FROM #SalesTaxUpfrontCostDetails UR
JOIN #UpfrontReceivables URDetails
ON UR.ReceivableDetailId = URDetails.ReceivableDetailId AND URDetails.RowNumber = 1
;
UPDATE #SalesTaxUpfrontCostDetails
SET AssetCost = NBV_Amount
FROM #SalesTaxUpfrontCostDetails CR
JOIN
(
SELECT DISTINCT AssetId, NBVAmount NBV_Amount FROM #ContractDetails
) AB ON CR.AssetId = AB.AssetId
AND CR.IsUpfrontTaxApplicable = 1 AND ReceivableTypeName = @InterimRentalReceivableType
;
UPDATE #SalesTaxUpfrontCostDetails
SET AssetCost = NBV_Amount
FROM #SalesTaxUpfrontCostDetails CR
JOIN #AssetNBVDetails AB ON CR.AssetId = AB.AssetId AND CR.ReceivableDetailId = AB.ReceivableDetailId
AND CR.IsUpfrontTaxApplicable = 1 AND ReceivableTypeName <> @InterimRentalReceivableType
;
SELECT
AD.AssetId, AD.ReceivableDetailId, (-1) * RD.Cost_Amount AssetCost,
1 AS CreatedById, SYSDATETIMEOFFSET() AS CreatedTime, @JobStepInstanceId AS JobStepInstanceId
INTO #AdjustmentUpfrontCostAmountDetails
FROM #AdjustmentUpfrontCostDetails AD
JOIN ReceivableTaxDetails RD ON AD.AdjustmentId = RD.ReceivableDetailId
AND RD.IsActive = 1 AND RD.Cost_Amount <> 0.00
;
INSERT INTO NonVertexUpfrontCostDetailExtract
([AssetId], [ReceivableDetailId], [AssetCost],[JobStepInstanceId])
SELECT
[AssetId], [ReceivableDetailId], [AssetCost], @JobStepInstanceId
FROM #SalesTaxUpfrontCostDetails
WHERE IsUpfrontTaxApplicable = 1
UNION ALL
SELECT
[AssetId], [ReceivableDetailId], [AssetCost], @JobStepInstanceId
FROM #AdjustmentUpfrontCostAmountDetails
UNION ALL
SELECT AssetId, ReceivableDetailId, AssetCost, JobStepInstanceId  FROM
(
SELECT
OU.AssetId, OU.ReceivableDetailId, ST.AssetCost,@JobStepInstanceId AS JobStepInstanceId
,ROW_NUMBER() OVER (PARTITION BY OU.AssetId,  OU.ReceivableDueDate ORDER BY OU.ReceivableId) RowNumber
FROM #OriginalUpfrontCostDetails OU
JOIN #SalesTaxUpfrontCostDetails ST ON OU.AssetId = ST.AssetId
AND OU.ReceivableDueDate = ST.ReceivableDueDate
WHERE ST.IsUpfrontTaxApplicable = 1
) AS OriginalUpfrontCostDetails
WHERE OriginalUpfrontCostDetails.RowNumber = 1
UNION ALL
SELECT AssetId, ReceivableDetailId, AssetCost, JobStepInstanceId FROM
(
SELECT
AU.AssetId, AU.ReceivableDetailId,(-1) * ST.AssetCost AS AssetCost, @JobStepInstanceId AS JobStepInstanceId
,ROW_NUMBER() OVER (PARTITION BY AU.AssetId,  AU.ReceivableDueDate ORDER BY AU.ReceivableId) RowNumber
FROM #AdjustmentUpfrontCostDetails AU
JOIN #SalesTaxUpfrontCostDetails ST ON AU.AssetId = ST.AssetId
AND AU.ReceivableDueDate = ST.ReceivableDueDate
LEFT JOIN #AdjustmentUpfrontCostAmountDetails AUC ON AU.AssetId = AUC.AssetId
AND AU.ReceivableDetailId = AUC.ReceivableDetailId
WHERE ST.IsUpfrontTaxApplicable = 1
AND AUC.ReceivableDetailId IS NULL
)  AS AdjustmentUpfrontCostDetails
WHERE AdjustmentUpfrontCostDetails.RowNumber = 1
;
END

GO

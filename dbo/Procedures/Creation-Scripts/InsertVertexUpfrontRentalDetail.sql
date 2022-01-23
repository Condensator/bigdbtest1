SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 
CREATE PROCEDURE [dbo].[InsertVertexUpfrontRentalDetail]  
(  
	@URTaxBasisTypeName					NVARCHAR(100),  
	@URDMVTaxBasisTypeName				NVARCHAR(100),  
	@CapitalLeaseRentalReceivableType	NVARCHAR(100),  
	@OperatingLeaseRentalReceivableType NVARCHAR(100),  
	@CTEntityType						NVARCHAR(100),  
	@AssumptionApprovedStatus			NVARCHAR(30),
	@JobStepInstanceId					BIGINT  
)  
AS  
BEGIN  
   
SET NOCOUNT ON  
  
SELECT * INTO #SalesTaxUpfrontRentalDetails
FROM
(
SELECT  
  R.AssetId  
 ,NULL as AssetSKUId  
 ,R.ContractId  
 ,R.ReceivableDetailId  
 ,CAST(0 AS BIT) IsUpfrontTaxApplicable  
 ,CAST(0 AS DECIMAL(16,2)) FairMarketValue  
 ,LocationEffectiveDate  
 ,R.ReceivableDueDate  
 ,R.ReceivableCodeId  
 ,R.ExtendedPrice  
 ,R.ReceivableId
 ,R.AdjustmentBasisReceivableDetailId
 ,ROW_NUMBER() OVER(PARTITION BY R.AssetId,R.ReceivableDetailId ORDER BY R.ReceivableDetailId,R.AssetId) RowNumber
FROM SalesTaxReceivableDetailExtract R  
INNER JOIN SalesTaxAssetDetailExtract SA ON  R.AssetId = SA.AssetId AND R.JobStepInstanceId = SA.JobStepInstanceId  
AND SA.IsSKU = 0 
INNER JOIN SalesTaxAssetLocationDetailExtract STA   
 ON R.AssetId = STA.AssetId AND R.ReceivableDueDate = STA.[ReceivableDueDate] AND R.JobStepInstanceId = STA.JobStepInstanceId  
 AND R.ReceivableDetailId = STA.ReceivableDetailId   
INNER JOIN SalesTaxLocationDetailExtract STL ON STA.LocationId = STL.LocationId AND R.JobStepInstanceId = STL.JobStepInstanceId   
INNER JOIN VertexReceivableCodeDetailExtract STRT ON R.ReceivableCodeId = STRT.ReceivableCodeId AND R.JobStepInstanceId = STRT.JobStepInstanceId  
INNER JOIN VertexContractDetailExtract STLA ON R.ContractId = STLA.ContractId AND R.JobStepInstanceId = STLA.JobStepInstanceId  
WHERE STA.LocationTaxBasisType IN (@URTaxBasisTypeName, @URDMVTaxBasisTypeName) AND R.ContractId IS NOT NULL AND STRT.IsRental = 1   
AND STRT.TaxReceivableName IN (@CapitalLeaseRentalReceivableType, @OperatingLeaseRentalReceivableType)  
AND R.ReceivableDueDate >= STLA.CommencementDate AND IsVertexSupported = 1 AND R.InvalidErrorCode IS NULL  
AND R.JobStepInstanceId = @JobStepInstanceId) AS VertexUpforntRentalDetails
WHERE VertexUpforntRentalDetails.RowNumber = 1; 

INSERT INTO #SalesTaxUpfrontRentalDetails 
SELECT * FROM (
SELECT  
  R.AssetId  
 ,RS.AssetSKUId  
 ,R.ContractId  
 ,R.ReceivableDetailId  
 ,CAST(0 AS BIT) IsUpfrontTaxApplicable  
 ,CAST(0 AS DECIMAL(16,2)) FairMarketValue  
 ,LocationEffectiveDate  
 ,R.ReceivableDueDate  
 ,R.ReceivableCodeId  
 ,RS.ExtendedPrice  
 ,R.ReceivableId
 ,R.AdjustmentBasisReceivableDetailId
 ,ROW_NUMBER() OVER(PARTITION BY RS.ReceivableSKUId,R.ReceivableDetailId,RS.AssetSKUId,R.AssetId ORDER BY RS.ReceivableSKUId,R.ReceivableDetailId,RS.AssetSKUId,R.AssetId) RowNumber
FROM SalesTaxReceivableDetailExtract R  
INNER JOIN SalesTaxAssetDetailExtract SA ON  R.AssetId = SA.AssetId AND R.JobStepInstanceId = SA.JobStepInstanceId  
AND SA.IsSKU = 1
INNER JOIN SalesTaxAssetLocationDetailExtract STA   
 ON R.AssetId = STA.AssetId AND R.ReceivableDueDate = STA.[ReceivableDueDate] AND R.JobStepInstanceId = STA.JobStepInstanceId  
 AND R.ReceivableDetailId = STA.ReceivableDetailId   
INNER JOIN SalesTaxLocationDetailExtract STL ON STA.LocationId = STL.LocationId AND R.JobStepInstanceId = STL.JobStepInstanceId   
INNER JOIN VertexReceivableCodeDetailExtract STRT ON R.ReceivableCodeId = STRT.ReceivableCodeId AND R.JobStepInstanceId = STRT.JobStepInstanceId  
INNER JOIN VertexContractDetailExtract STLA ON R.ContractId = STLA.ContractId AND R.JobStepInstanceId = STLA.JobStepInstanceId  
INNER JOIN SalesTaxReceivableSKUDetailExtract RS ON R.ReceivableDetailId = RS.ReceivableDetailId AND R.AssetId = RS.AssetId  
AND RS.AssetSKUId IS NOT NULL
AND R.JobStepInstanceId = RS.JobStepInstanceId  
WHERE STA.LocationTaxBasisType IN (@URTaxBasisTypeName, @URDMVTaxBasisTypeName) AND R.ContractId IS NOT NULL AND STRT.IsRental = 1
AND R.IsRenewal = 0
AND STRT.TaxReceivableName IN (@CapitalLeaseRentalReceivableType, @OperatingLeaseRentalReceivableType)  
AND R.ReceivableDueDate >= STLA.CommencementDate AND IsVertexSupported = 1 AND R.InvalidErrorCode IS NULL  
AND R.JobStepInstanceId = @JobStepInstanceId) AS VertexUpforntRentalDetails
WHERE VertexUpforntRentalDetails.RowNumber = 1;   
  
SELECT   
 RD.AdjustmentBasisReceivableDetailId AdjustmentId  
 ,RD.ReceivableDetailId  as Id
 ,RD.ReceivableId 
 ,RD.AssetSKUId as AssetSKUId
INTO #AdjustmentDetail  
FROM #SalesTaxUpfrontRentalDetails RD WHERE RD.AdjustmentBasisReceivableDetailId IS NOT NULL
;  

SELECT   
 AD.Id ReceivableDetailId, STA.AssetId,STA.AssetSKUId, STA.ReceivableDueDate, AD.AdjustmentId, AD.ReceivableId 
INTO #AdjustmentUpfrontRentalDetails   
FROM #SalesTaxUpfrontRentalDetails STA  
INNER JOIN #AdjustmentDetail AD ON STA.ReceivableDetailId = AD.Id AND STA.AssetSKUId IS NULL 
;  

INSERT INTO #AdjustmentUpfrontRentalDetails  
SELECT   
 AD.Id ReceivableDetailId, STA.AssetId,STA.AssetSKUId, STA.ReceivableDueDate, AD.AdjustmentId, AD.ReceivableId   
FROM #SalesTaxUpfrontRentalDetails STA  
INNER JOIN #AdjustmentDetail AD ON STA.ReceivableDetailId = AD.Id AND STA.AssetSKUId = AD.AssetSKUId AND STA.AssetSKUId IS NOT NULL 
;  

SELECT   
 AD.AdjustmentId ReceivableDetailId, STA.AssetId,STA.AssetSKUId, STA.ReceivableDueDate, CAST(NULL AS BIGINT) AdjustmentId, STA.ReceivableId   
INTO #OriginalUpfrontRentalDetails   
FROM #SalesTaxUpfrontRentalDetails STA  
INNER JOIN #AdjustmentDetail AD ON STA.ReceivableDetailId = AD.AdjustmentId  AND STA.AssetSKUId IS NULL 
;  

INSERT INTO #OriginalUpfrontRentalDetails  
SELECT   
 AD.AdjustmentId ReceivableDetailId, STA.AssetId,STA.AssetSKUId, STA.ReceivableDueDate, CAST(NULL AS BIGINT) AdjustmentId, STA.ReceivableId   
FROM #SalesTaxUpfrontRentalDetails STA  
INNER JOIN #AdjustmentDetail AD ON STA.ReceivableDetailId = AD.AdjustmentId AND STA.AssetSKUId = AD.AssetSKUId  AND STA.AssetSKUId IS NOT NULL 
; 
  
DELETE STA FROM #SalesTaxUpfrontRentalDetails STA  
JOIN #AdjustmentDetail AD ON STA.ReceivableDetailId = AD.Id  
;  
DELETE STA FROM #SalesTaxUpfrontRentalDetails STA  
JOIN #AdjustmentDetail AD ON STA.ReceivableDetailId = AD.AdjustmentId  
;  
  
SELECT   
 ContractId, AssetId,AssetSKUId,MIN(LocationEffectiveDate) LocationEffectiveDate  
INTO #UpfrontMinLocationEffectiveReceivables  
FROM #SalesTaxUpfrontRentalDetails  
GROUP BY ContractId, AssetId,AssetSKUId;  

SELECT DISTINCT 
 ContractId=c.Id ,LFD.IsAdvance 
 INTO #UpfrontRentContractDetails 
 FROM  #UpfrontMinLocationEffectiveReceivables t
 INNER JOIN Contracts C on t.ContractId = C.Id
 INNER JOIN LeaseFinances LF ON C.Id = LF.ContractId AND LF.IsCurrent = 1
 INNER JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id

SELECT
 R.Duedate ReceivableDueDate,
 RD.AssetId,
 NULL as AssetSKUId,
 RD.Id ReceivableDetailId,
 UR.ContractId,
 CASE WHEN RD.PreCapitalizationRent_Amount <> 0.00 THEN RD.PreCapitalizationRent_Amount ELSE RD.Amount_Amount END AS Amount,
 RD.ReceivableId,
 RD.AdjustmentBasisReceivableDetailId,
 CD.IsAdvance,
 LPS.EndDate,
 CAST(0 AS BIT) IsAssumedArrearLease,
 UR.LocationEffectiveDate
INTO #AllContractUpfrontDetails  
FROM Receivables R  
INNER JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId  
INNER JOIN #UpfrontMinLocationEffectiveReceivables UR ON R.EntityId = UR.ContractId AND RD.AssetId = UR.AssetId AND UR.AssetSKUId IS NULL 
INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id  
INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id  
INNER JOIN Contracts C ON R.EntityId = C.Id AND R.EntityType = @CTEntityType
INNER JOIN LeaseFinances LF ON C.Id = LF.ContractId 
INNER JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
INNER JOIN LeasePaymentSchedules LPS ON LFD.Id = LPS.LeaseFinanceDetailId AND  R.PaymentScheduleId = LPS.Id
INNER JOIN #UpfrontRentContractDetails CD ON CD.ContractId = C.Id 
WHERE R.EntityType = @CTEntityType AND RT.IsRental = 1 AND R.IsActive = 1   
AND (RT.Name = @CapitalLeaseRentalReceivableType OR RT.Name = @OperatingLeaseRentalReceivableType);

INSERT INTO #AllContractUpfrontDetails
SELECT
 R.Duedate ReceivableDueDate,
 RD.AssetId,
 RS.AssetSKUId,
 RD.Id ReceivableDetailId,
 UR.ContractId,
 CASE WHEN RS.PreCapitalizationRent_Amount = 0.00 THEN RS.Amount_Amount ELSE RS.PreCapitalizationRent_Amount END Amount,
 RD.ReceivableId,
 RD.AdjustmentBasisReceivableDetailId,
 CD.IsAdvance,
 LPS.EndDate,
 CAST(0 AS BIT) IsAssumedArrearLease,
  UR.LocationEffectiveDate
FROM Receivables R  
INNER JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId  
INNER JOIN #UpfrontMinLocationEffectiveReceivables UR ON R.EntityId = UR.ContractId AND RD.AssetId = UR.AssetId AND UR.AssetSKUId IS NOT NULL
INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id  
INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id  
INNER JOIN ReceivableSKUs RS ON RD.Id = RS.ReceivableDetailId AND UR.AssetSKUId = RS.AssetSKUId  
INNER JOIN Contracts C ON R.EntityId = C.Id AND R.EntityType = @CTEntityType   
INNER JOIN LeaseFinances LF ON C.Id = LF.ContractId 
INNER JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id   
INNER JOIN LeasePaymentSchedules LPS ON  LFD.Id = LPS.LeaseFinanceDetailId AND R.PaymentScheduleId = LPS.Id
INNER JOIN #UpfrontRentContractDetails CD on CD.ContractId = C.Id 
WHERE R.EntityType = @CTEntityType AND RT.IsRental = 1 AND R.IsActive = 1   
AND (RT.Name = @CapitalLeaseRentalReceivableType OR RT.Name = @OperatingLeaseRentalReceivableType);

SELECT
 RD.AdjustmentBasisReceivableDetailId AdjustmentId,
 RD.ReceivableDetailId,
 RD.ReceivableId  
INTO #AllAdjustmentDetail  
FROM #AllContractUpfrontDetails RD  
WHERE RD.AdjustmentBasisReceivableDetailId IS NOT NULL;  
  
DELETE STA FROM #AllContractUpfrontDetails STA  
INNER JOIN #AllAdjustmentDetail AD ON STA.ReceivableDetailId = AD.ReceivableDetailId  
;  
DELETE STA FROM #AllContractUpfrontDetails STA  
INNER JOIN #AllAdjustmentDetail AD ON STA.ReceivableDetailId = AD.AdjustmentId  
;  

UPDATE #AllContractUpfrontDetails
	SET IsAssumedArrearLease = 1
FROM #AllContractUpfrontDetails CD 
JOIN Assumptions A ON CD.ContractId = A.ContractId
WHERE A.Status = @AssumptionApprovedStatus AND IsAdvance = 0
;

SELECT   
	AssetId,AssetSKUId, LocationEffectiveDate, MIN(ReceivableDueDate) ReceivableDueDate, ContractId  
INTO #CTEUpfrontMinDueReceivables
FROM #SalesTaxUpfrontRentalDetails   
GROUP BY AssetId,AssetSKUId, LocationEffectiveDate, ContractId;

SELECT   
	R.AssetId,R.AssetSKUId, MIN(R.ReceivableDueDate) ReceivableDueDate, R.ContractId  
INTO #CTEUpfrontMinDueReceivables1
FROM #SalesTaxUpfrontRentalDetails R
JOIN #UpfrontMinLocationEffectiveReceivables UR
ON R.ContractId = UR.ContractId 
AND R.AssetId = UR.AssetId AND ISNULL(R.AssetSKUId,0) = ISNULL(UR.AssetSKUId,0)
AND R.LocationEffectiveDate <> UR.LocationEffectiveDate
GROUP BY R.AssetId,R.AssetSKUId, R.ContractId,R.LocationEffectiveDate 
;

SELECT R.AssetId,R.AssetSKUId, R.ContractId ,MIN(ReceivableId) ReceivableId 
INTO #ReceivableUpfront
from #SalesTaxUpfrontRentalDetails R
JOIN #CTEUpfrontMinDueReceivables1 UR ON R.ContractId = UR.ContractId 
AND R.AssetId = UR.AssetId AND ISNULL(R.AssetSKUId,0) = ISNULL(UR.AssetSKUId,0)
AND R.ReceivableDueDate = UR.ReceivableDueDate
GROUP BY R.AssetId,R.AssetSKUId, R.ContractId ,R.LocationEffectiveDate  
;
  
UPDATE #SalesTaxUpfrontRentalDetails  
 SET IsUpfrontTaxApplicable = 1   
FROM #SalesTaxUpfrontRentalDetails UR  
JOIN #ReceivableUpfront URDetails   
ON UR.ReceivableId = URDetails.ReceivableId  AND UR.AssetId = URDetails.AssetId
AND ISNULL(UR.AssetSkuId,0) = ISNULL(URDetails.AssetSKUId,0)
AND Ur.ContractId = URDetails.ContractId
;  

SELECT  
  R.ReceivableDueDate,  
  R.AssetId,  
  R.AssetSKUId,  
  R.ReceivableDetailId,  
  R.ContractId,  
  R.Amount,  
  R.ReceivableId,
  R.LocationEffectiveDate
INTO #CTEContractUpfrontDetails
FROM #AllContractUpfrontDetails R  
JOIN #UpfrontMinLocationEffectiveReceivables UR   
ON R.ContractId = UR.ContractId AND R.AssetId = UR.AssetId   
WHERE R.ReceivableDueDate >= UR.LocationEffectiveDate  
AND R.IsAssumedArrearLease = 0
  
INSERT INTO #CTEContractUpfrontDetails
SELECT  
  R.ReceivableDueDate,  
  R.AssetId,  
  R.AssetSKUId,  
  R.ReceivableDetailId,  
  R.ContractId,  
  R.Amount,  
  R.ReceivableId,
  R.LocationEffectiveDate
 FROM #AllContractUpfrontDetails R  
 JOIN #UpfrontMinLocationEffectiveReceivables UR   
 ON R.ContractId = UR.ContractId AND R.AssetId = UR.AssetId   
 WHERE R.EndDate >= UR.LocationEffectiveDate  
 AND R.IsAssumedArrearLease = 1
;

SELECT CR.ContractId, CR.AssetId,CR.LocationEffectiveDate,MIN(ReceivableDueDate) AS ReceivableDueDate,CR.AssetSKUId
INTO #UpfrontReceivableDueDatesForMinLocation
FROM #CTEContractUpfrontDetails CR
WHERE CR.ReceivableDueDate >= CR.LocationEffectiveDate
GROUP BY CR.ContractId, CR.AssetId,CR.AssetSKUId,CR.LocationEffectiveDate
 
 SELECT R.AssetId,R.AssetSKUId, R.ContractId,  MIN(ReceivableId) ReceivableId 
INTO #UpfrontReceivables
from #CTEContractUpfrontDetails R
JOIN #UpfrontReceivableDueDatesForMinLocation UR ON R.ContractId = UR.ContractId 
AND R.AssetId = UR.AssetId AND ISNULL(R.AssetSKUId,0) = ISNULL(UR.AssetSKUId,0)
AND R.ReceivableDueDate = UR.ReceivableDueDate
GROUP BY R.AssetId,R.AssetSKUId, R.ContractId ,R.LocationEffectiveDate  
;

UPDATE #SalesTaxUpfrontRentalDetails  
 SET IsUpfrontTaxApplicable = 1   
FROM #SalesTaxUpfrontRentalDetails UR  
JOIN #UpfrontReceivables URDetails   
ON UR.ReceivableId = URDetails.ReceivableId  AND UR.AssetId = URDetails.AssetId
AND ISNULL(UR.AssetSkuId,0) = ISNULL(URDetails.AssetSKUId,0)
AND Ur.ContractId = URDetails.ContractId
;  
  
 /* Update non sku Based receivables */  
UPDATE #SalesTaxUpfrontRentalDetails  
 SET FairMarketValue = SumAmount  
FROM #SalesTaxUpfrontRentalDetails CR  
JOIN (  
SELECT   
  CUD.ContractId, CUD.AssetId,CUD.AssetSKUId, CRD.ReceivableDueDate, SUM(Amount) SumAmount  
   FROM #AllContractUpfrontDetails CUD  
   JOIN #SalesTaxUpfrontRentalDetails CRD ON CUD.AssetId = CRD.AssetId  
   AND CUD.ContractId = CRD.ContractId AND IsUpfrontTaxApplicable = 1  
   AND CUD.ReceivableDueDate >= CRD.ReceivableDueDate  
   WHERE CRD.AssetSKUId IS NULL  
   GROUP BY CUD.ContractId, CUD.AssetId,CUD.AssetSKUId, CRD.ReceivableDueDate  
   ) FMVDetail  
ON CR.ContractId = FMVDetail.ContractId AND CR.AssetId = FMVDetail.AssetId 
 AND CR.ReceivableDueDate = FMVDetail.ReceivableDueDate  
WHERE IsUpfrontTaxApplicable = 1 AND CR.AssetSKUId IS NULL  
;  
  
 /* Update  sku Based receivables */  
UPDATE #SalesTaxUpfrontRentalDetails  
 SET FairMarketValue = SumAmount  
FROM #SalesTaxUpfrontRentalDetails CR  
JOIN (  
SELECT   
  CUD.ContractId, CUD.AssetId,CUD.AssetSKUId, CRD.ReceivableDueDate, SUM(Amount) SumAmount  
   FROM #AllContractUpfrontDetails CUD  
   JOIN #SalesTaxUpfrontRentalDetails CRD ON CUD.AssetId = CRD.AssetId AND CUD.AssetSKUId = CRD.AssetSKUId  
   AND CUD.ContractId = CRD.ContractId AND IsUpfrontTaxApplicable = 1  
   AND CUD.ReceivableDueDate >= CRD.ReceivableDueDate  
   WHERE CRD.AssetSKUId IS NOT NULL  
   GROUP BY CUD.ContractId, CUD.AssetId,CUD.AssetSKUId, CRD.ReceivableDueDate  
   ) FMVDetail  
ON CR.ContractId = FMVDetail.ContractId AND CR.AssetId = FMVDetail.AssetId AND CR.AssetSKUId = FMVDetail.AssetSKUId  
 AND CR.ReceivableDueDate = FMVDetail.ReceivableDueDate  
WHERE IsUpfrontTaxApplicable = 1 AND CR.AssetSKUId IS NOT NULL  
;  
    
SELECT  
 AD.AssetId, AD.AssetSKUId, AD.ReceivableDetailId, (-1) * RD.FairMarketValue_Amount FairMarketValue,   
 1 AS CreatedById, SYSDATETIMEOFFSET() AS CreatedTime, @JobStepInstanceId AS JobStepInstanceId  
INTO #AdjustmentUpfrontRentalAmountDetails  
FROM #AdjustmentUpfrontRentalDetails AD   
JOIN ReceivableTaxDetails RD ON AD.AdjustmentId = RD.ReceivableDetailId   
AND RD.IsActive = 1 AND RD.FairMarketValue_Amount <> 0.00 
;  


INSERT INTO VertexUpfrontRentalDetailExtract  
([AssetId],[AssetSKUId], [ReceivableDetailId], [FairMarketValue], [JobStepInstanceId])  
SELECT  
 [AssetId],[AssetSKUId], [ReceivableDetailId], [FairMarketValue],@JobStepInstanceId  
FROM #SalesTaxUpfrontRentalDetails  
WHERE IsUpfrontTaxApplicable = 1  
UNION ALL  
SELECT  
 [AssetId],[AssetSKUId], [ReceivableDetailId], [FairMarketValue],@JobStepInstanceId  
FROM #AdjustmentUpfrontRentalAmountDetails   
UNION ALL  
SELECT  
 [AssetId],[AssetSKUId], [ReceivableDetailId], [FairMarketValue], [JobStepInstanceId] FROM  
(  
 SELECT   
  OU.AssetId,OU.AssetSKUId, OU.ReceivableDetailId, ST.FairMarketValue, @JobStepInstanceId AS JobStepInstanceId  
  ,ROW_NUMBER() OVER (PARTITION BY OU.AssetId,  OU.ReceivableDueDate ORDER BY OU.ReceivableId) RowNumber  
 FROM #OriginalUpfrontRentalDetails OU  
 JOIN #SalesTaxUpfrontRentalDetails ST ON OU.AssetId = ST.AssetId  
 AND OU.ReceivableDueDate = ST.ReceivableDueDate  
 WHERE ST.IsUpfrontTaxApplicable = 1  
) AS OriginalUpfrontCostDetails  
WHERE OriginalUpfrontCostDetails.RowNumber = 1  
UNION ALL  
SELECT  
 [AssetId],[AssetSKUId], [ReceivableDetailId], [FairMarketValue],[JobStepInstanceId] FROM  
(  
 SELECT   
   AU.AssetId,AU.AssetSKUId, AU.ReceivableDetailId,(-1) * ST.FairMarketValue AS FairMarketValue, @JobStepInstanceId AS JobStepInstanceId  
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
  
/*
SELECT * From   #SalesTaxUpfrontRentalDetails 

--DROP TABLE #SalesTaxUpfrontRentalDetails  
--DROP TABLE #AdjustmentUpfrontRentalAmountDetails  
--DROP TABLE #OriginalUpfrontRentalDetails  
--DROP TABLE #AdjustmentUpfrontRentalDetails  
--DROP TABLE #AdjustmentDetail  
--DROP TABLE #UpfrontMinLocationEffectiveReceivables  
--DROP TABLE #AllContractUpfrontDetails  
--DROP TABLE #AllAdjustmentDetail  
--DROP TABLE #UpfrontReceivables 

*/

END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[InsertVertexUpfrontCostDetail]  
(  
	@UCTaxBasisTypeName						NVARCHAR(100),  
	@UCDMVTaxBasisTypeName					NVARCHAR(100),  
	@InterimRentalReceivableType			NVARCHAR(100),  
	@LeaseInterimInterestReceivableType		NVARCHAR(100),  
	@CPIBaseRentalReceivableType			NVARCHAR(100),
	@OperatingContractType					NVARCHAR(100),  
	@CTEntityType							NVARCHAR(100),
	@AssumptionApprovedStatus				NVARCHAR(30),
	@JobStepInstanceId						BIGINT  
)  
AS  
BEGIN  
  
SET NOCOUNT ON    
;    
SELECT * INTO #SalesTaxUpfrontCostDetails 
FROM
(
SELECT
  R.AssetId    
 ,NULL as AssetSKUId    
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
 ,R.JobStepInstanceId   
 ,SA.IsSKU
 ,R.AdjustmentBasisReceivableDetailId
 ,ROW_NUMBER() OVER(PARTITION BY R.ReceivableDetailId,R.AssetId ORDER BY R.ReceivableDetailId,R.AssetId) RowNumber    
FROM SalesTaxReceivableDetailExtract R    
INNER JOIN SalesTaxAssetLocationDetailExtract STA ON R.AssetId = STA.AssetId AND R.ReceivableDueDate = STA.ReceivableDueDate     
AND R.ReceivableDetailId = STA.ReceivableDetailId AND R.JobStepInstanceId = STA.JobStepInstanceId    
INNER JOIN SalesTaxAssetDetailExtract SA ON  R.AssetId = SA.AssetId AND R.JobStepInstanceId = SA.JobStepInstanceId    
AND SA.IsSKU = 0    
INNER JOIN SalesTaxLocationDetailExtract STL ON STA.LocationId = STL.LocationId AND R.JobStepInstanceId = STL.JobStepInstanceId    
INNER JOIN VertexReceivableCodeDetailExtract STRT ON R.ReceivableCodeId = STRT.ReceivableCodeId AND R.JobStepInstanceId = STRT.JobStepInstanceId    
WHERE STA.LocationTaxBasisType IN (@UCTaxBasisTypeName, @UCDMVTaxBasisTypeName) AND R.ContractId IS NOT NULL AND STRT.IsRental = 1    
AND R.PaymentScheduleId IS NOT NULL AND IsVertexSupported = 1 AND R.InvalidErrorCode IS NULL    
AND STRT.TaxReceivableName <> @LeaseInterimInterestReceivableType AND STRT.TaxReceivableName <> @CPIBaseRentalReceivableType 
AND R.JobStepInstanceId = @JobStepInstanceId) AS VertexUpfrontCostDetails    
WHERE VertexUpfrontCostDetails.RowNumber = 1;    
    
INSERT INTO #SalesTaxUpfrontCostDetails   
SELECT * FROM ( 
SELECT    
   R.AssetId    
 ,RS.AssetSKUId    
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
 ,R.JobStepInstanceId   
 ,SA.IsSKU  
 ,R.AdjustmentBasisReceivableDetailId
  ,ROW_NUMBER() OVER(PARTITION BY RS.ReceivableSKUId,R.ReceivableDetailId,RS.AssetSKUId,R.AssetId ORDER BY RS.ReceivableSKUId,R.ReceivableDetailId,RS.AssetSKUId,R.AssetId) RowNumber
FROM SalesTaxReceivableDetailExtract R    
INNER JOIN SalesTaxAssetLocationDetailExtract STA ON R.AssetId = STA.AssetId AND R.ReceivableDueDate = STA.ReceivableDueDate     
AND R.ReceivableDetailId = STA.ReceivableDetailId AND R.JobStepInstanceId = STA.JobStepInstanceId    
INNER JOIN SalesTaxAssetDetailExtract SA ON  R.AssetId = SA.AssetId AND R.JobStepInstanceId = SA.JobStepInstanceId    
AND SA.IsSKU = 1    
INNER JOIN SalesTaxLocationDetailExtract STL ON STA.LocationId = STL.LocationId AND R.JobStepInstanceId = STL.JobStepInstanceId    
INNER JOIN VertexReceivableCodeDetailExtract STRT ON R.ReceivableCodeId = STRT.ReceivableCodeId AND R.JobStepInstanceId = STRT.JobStepInstanceId    
INNER JOIN SalesTaxReceivableSKUDetailExtract RS ON R.ReceivableDetailId = RS.ReceivableDetailId AND R.AssetId = RS.AssetId    
AND R.JobStepInstanceId = RS.JobStepInstanceId    
WHERE STA.LocationTaxBasisType IN (@UCTaxBasisTypeName, @UCDMVTaxBasisTypeName) AND R.ContractId IS NOT NULL AND STRT.IsRental = 1    
AND R.PaymentScheduleId IS NOT NULL AND IsVertexSupported = 1 AND R.InvalidErrorCode IS NULL    
AND STRT.TaxReceivableName <> @LeaseInterimInterestReceivableType AND STRT.TaxReceivableName <> @CPIBaseRentalReceivableType 
AND R.JobStepInstanceId = @JobStepInstanceId    ) AS VertexUpfrontCostDetails    
WHERE VertexUpfrontCostDetails.RowNumber = 1;        
    
SELECT   
 RD.AdjustmentBasisReceivableDetailId AdjustmentId  
 ,RD.ReceivableDetailId  as Id
 ,RD.ReceivableId 
 ,RD.AssetSKUId as AssetSKUId
INTO #AdjustmentDetail  
FROM #SalesTaxUpfrontCostDetails RD WHERE RD.AdjustmentBasisReceivableDetailId IS NOT NULL
; 

SELECT       
 AD.Id ReceivableDetailId, STA.AssetId,STA.AssetSKUId, STA.ReceivableDueDate, AD.AdjustmentId, AD.ReceivableId     
INTO #AdjustmentUpfrontCostDetails       
FROM #SalesTaxUpfrontCostDetails STA      
INNER JOIN #AdjustmentDetail AD ON STA.ReceivableDetailId = AD.Id AND STA.AssetSKUId IS NULL     
;      
    
INSERT INTO #AdjustmentUpfrontCostDetails      
SELECT       
 AD.Id ReceivableDetailId, STA.AssetId,STA.AssetSKUId, STA.ReceivableDueDate, AD.AdjustmentId, AD.ReceivableId       
FROM #SalesTaxUpfrontCostDetails STA      
INNER JOIN #AdjustmentDetail AD ON STA.ReceivableDetailId = AD.Id AND STA.AssetSKUId = AD.AssetSKUId AND STA.AssetSKUId IS NOT NULL     
;      
    
SELECT       
 AD.AdjustmentId ReceivableDetailId, STA.AssetId,STA.AssetSKUId, STA.ReceivableDueDate, CAST(NULL AS BIGINT) AdjustmentId, STA.ReceivableId       
INTO #OriginalUpfrontCostDetails       
FROM #SalesTaxUpfrontCostDetails STA      
INNER JOIN #AdjustmentDetail AD ON STA.ReceivableDetailId = AD.AdjustmentId  AND STA.AssetSKUId IS NULL     
;      
    
INSERT INTO #OriginalUpfrontCostDetails      
SELECT       
 AD.AdjustmentId ReceivableDetailId, STA.AssetId,STA.AssetSKUId, STA.ReceivableDueDate, CAST(NULL AS BIGINT) AdjustmentId, STA.ReceivableId       
FROM #SalesTaxUpfrontCostDetails STA      
INNER JOIN #AdjustmentDetail AD ON STA.ReceivableDetailId = AD.AdjustmentId AND STA.AssetSKUId = AD.AssetSKUId  AND STA.AssetSKUId IS NOT NULL     
;     
    
DELETE STA FROM #SalesTaxUpfrontCostDetails STA    
INNER JOIN #AdjustmentDetail AD ON STA.ReceivableDetailId = AD.Id    
;    
DELETE STA FROM #SalesTaxUpfrontCostDetails STA    
INNER JOIN #AdjustmentDetail AD ON STA.ReceivableDetailId = AD.AdjustmentId    
;    
    
SELECT     
  ContractId,AssetId,AssetSKUId, MIN(LocationEffectiveDate) LocationEffectiveDate    
INTO #UpfrontMinLocationEffectiveDateReceivables     
FROM #SalesTaxUpfrontCostDetails GROUP BY ContractId,AssetId,AssetSKUId, LocationEffectiveDate    

SELECT DISTINCT 
 ContractId=c.Id ,LFD.IsAdvance 
 INTO #UpfrontCostContractDetails 
 FROM  #UpfrontMinLocationEffectiveDateReceivables t
 INNER JOIN Contracts C on t.ContractId = C.Id
 INNER JOIN LeaseFinances LF ON C.Id = LF.ContractId AND LF.IsCurrent = 1
 INNER JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id

SELECT    
 C.Id ContractId,    
 R.DueDate ReceivableDueDate,    
 RD.ReceivableId,    
 RD.Id ReceivableDetailId,    
 RD.AssetId,    
 NULL as AssetSKUId,    
 RD.AdjustmentBasisReceivableDetailId,
 CD.IsAdvance,
 LPS.EndDate,
 CAST(0 AS BIT) IsAssumedArrearLease ,
UC.LocationEffectiveDate
INTO #AllContractDetails    
FROM Receivables R     
INNER JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId    
INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id    
INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id    
INNER JOIN #UpfrontMinLocationEffectiveDateReceivables UC ON RD.AssetId = UC.AssetId    
AND UC.AssetSKUId is NULL    
INNER JOIN Contracts C ON R.EntityId = C.Id AND R.EntityType = @CTEntityType
INNER JOIN LeaseFinances LF ON C.Id = LF.ContractId
INNER JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
INNER JOIN LeasePaymentSchedules LPS ON LFD.Id = LPS.LeaseFinanceDetailId AND R.PaymentScheduleId = LPS.Id
INNER JOIN #UpfrontCostContractDetails CD on CD.ContractId = C.Id
WHERE RT.Name <> @LeaseInterimInterestReceivableType AND RT.Name <> @CPIBaseRentalReceivableType  AND RT.IsRental = 1     
AND R.IsActive =1    
;    
    
INSERT INTO #AllContractDetails    
SELECT    
 C.Id ContractId,    
 R.DueDate ReceivableDueDate,    
 RD.ReceivableId,    
 RD.Id ReceivableDetailId,    
 RD.AssetId,    
 RS.AssetSKUId,    
 RD.AdjustmentBasisReceivableDetailId,
 CD.IsAdvance,
 LPS.EndDate,
 CAST(0 AS BIT) IsAssumedArrearLease ,
UC.LocationEffectiveDate
FROM Receivables R     
INNER JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId    
INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id    
INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id    
INNER JOIN #UpfrontMinLocationEffectiveDateReceivables UC ON RD.AssetId = UC.AssetId    
AND UC.AssetSKUId is NOT NULL    
INNER JOIN Contracts C ON R.EntityId = C.Id AND R.EntityType = @CTEntityType   
INNER JOIN ReceivableSKUs RS ON RD.Id = RS.ReceivableDetailId AND UC.AssetSKUId = RS.AssetSKUId 
INNER JOIN LeaseFinances LF ON C.Id = LF.ContractId
INNER JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id   
INNER JOIN LeasePaymentSchedules LPS ON LFD.Id = LPS.LeaseFinanceDetailId AND R.PaymentScheduleId = LPS.Id
INNER JOIN #UpfrontCostContractDetails CD on CD.ContractId = C.Id
WHERE RT.Name <> @LeaseInterimInterestReceivableType AND RT.Name <> @CPIBaseRentalReceivableType  AND RT.IsRental = 1     
AND R.IsActive =1    
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

UPDATE #AllContractDetails
	SET IsAssumedArrearLease = 1
FROM #AllContractDetails CD 
JOIN Assumptions A ON CD.ContractId = A.ContractId
AND A.Status = @AssumptionApprovedStatus AND CD.IsAdvance = 0
;

SELECT      
 RAT.ContractId,    
 LA.AssetId,     
 NULL as AssetSKUId,    
 LA.NBVAmount,    
 LA.NBVAmount AS AssetNBV,    
 ClassificationContractType,    
 LA.LeaseFinanceId AS LeaseFinanceId,    
 RAT.ReceivableDueDate,    
 RAT.ReceivableId,    
 RAT.ReceivableDetailId,    
 TaxReceivableName    
INTO #ContractDetails    
FROM #SalesTaxUpfrontCostDetails RAT    
INNER JOIN VertexContractDetailExtract CT ON RAT.ContractId = CT.ContractId AND RAT.JobStepInstanceId = CT.JobStepInstanceId    
INNER JOIN SalesTaxAssetDetailExtract LA ON CT.LeaseFinanceId = LA.LeaseFinanceId     
 AND RAT.AssetId = LA.AssetId AND RAT.JobStepInstanceId = LA.JobStepInstanceId AND LA.IsSKU = 0    
INNER JOIN LeasePaymentSchedules LPS ON RAT.PaymentScheduleId = LPS.Id     
 AND CT.LeaseFinanceId = LPS.LeaseFinanceDetailId     
INNER JOIN LeaseIncomeSchedules LIS ON CT.LeaseFinanceId = LIS.LeaseFinanceId AND LIS.IncomeDate = LPS.EndDate    
INNER JOIN VertexReceivableCodeDetailExtract STRT ON RAT.ReceivableCodeId = STRT.ReceivableCodeId    
AND STRT.TaxReceivableName <> @LeaseInterimInterestReceivableType AND STRT.TaxReceivableName <> @CPIBaseRentalReceivableType 
AND STRT.IsRental = 1  AND RAT.JobStepInstanceId = STRT.JobStepInstanceId;        
    
INSERT INTO #ContractDetails    
SELECT      
 RAT.ContractId,    
 LA.AssetId,     
 LASK.AssetSKUId,    
 LASK.NBVAmount  NBVAmount,    
 LA.NBVAmount AS AssetNBV,    
 ClassificationContractType,    
 LA.LeaseFinanceId AS LeaseFinanceId,    
 RAT.ReceivableDueDate,    
 RAT.ReceivableId,    
 RAT.ReceivableDetailId,    
 TaxReceivableName    
FROM #SalesTaxUpfrontCostDetails RAT    
INNER JOIN VertexContractDetailExtract CT ON RAT.ContractId = CT.ContractId AND RAT.JobStepInstanceId = CT.JobStepInstanceId    
INNER JOIN SalesTaxAssetDetailExtract LA ON CT.LeaseFinanceId = LA.LeaseFinanceId     
 AND RAT.AssetId = LA.AssetId AND RAT.JobStepInstanceId = LA.JobStepInstanceId AND LA.IsSKU = 1    
INNER JOIN LeasePaymentSchedules LPS ON RAT.PaymentScheduleId = LPS.Id     
 AND CT.LeaseFinanceId = LPS.LeaseFinanceDetailId     
INNER JOIN LeaseIncomeSchedules LIS ON CT.LeaseFinanceId = LIS.LeaseFinanceId AND LIS.IncomeDate = LPS.EndDate    
INNER JOIN VertexReceivableCodeDetailExtract STRT ON RAT.ReceivableCodeId = STRT.ReceivableCodeId    
AND STRT.TaxReceivableName <> @LeaseInterimInterestReceivableType AND STRT.TaxReceivableName <> @CPIBaseRentalReceivableType 
AND STRT.IsRental = 1 AND RAT.JobStepInstanceId = STRT.JobStepInstanceId    
INNER JOIN SalesTaxAssetSKUDetailExtract LASK ON  LA.AssetId = LASK.AssetId AND RAT.AssetSKUId = LASK.AssetSKUId     
AND LA.JobStepInstanceId = LASK.JobStepInstanceId    
WHERE LASK.JobStepInstanceId = @JobStepInstanceId
;    
    
SELECT    
C.ClassificationContractType,    
UC.ReceivableDueDate,    
UC.ReceivableDetailId,    
UC.AssetId,  
--UC.AssetSKUId,   
R.JobStepInstanceId    
INTO #UpfrontIncomeDetailsForSKU  
FROM #SalesTaxUpfrontCostDetails UC    
JOIN SalesTaxReceivableDetailExtract R ON UC.ReceivableDetailId = R.ReceivableDetailId    
AND R.JobStepInstanceId = @JobStepInstanceId    
JOIN VertexContractDetailExtract C ON R.ContractId = C.ContractId AND UC.JobStepInstanceId = C.JobStepInstanceId    
WHERE R.JObStepInstanceId = @JobstepInstanceId  AND UC.IsSKU = 1  
GROUP BY    
C.ClassificationContractType,    
UC.ReceivableDueDate,    
UC.ReceivableDetailId,    
UC.AssetId,   
--UC.AssetSKUId,  
R.JobStepInstanceId   

SELECT 
	C.ClassificationContractType,    
	UC.ReceivableDueDate,    
	UC.ReceivableDetailId,    
	UC.AssetId,    
	R.JobStepInstanceId,
	MIN(LIS.IncomeDate) IncomeDate,
	MAX(LPS.LeaseFinanceDetailId) AS LeaseFinanceId,
	MAX(C.ContractId) AS ContractId
INTO #UpfrontLeaseIncomeDetails
FROM #SalesTaxUpfrontCostDetails UC    
JOIN SalesTaxReceivableDetailExtract R ON UC.ReceivableDetailId = R.ReceivableDetailId    
AND R.JobStepInstanceId = @JobStepInstanceId    
JOIN VertexContractDetailExtract C ON R.ContractId = C.ContractId AND UC.JobStepInstanceId = C.JobStepInstanceId    
JOIN LeasePaymentSchedules LPS ON LPS.Id = R.PaymentScheduleId AND LPS.IsActive = 1    
JOIN LeaseIncomeSchedules LIS ON LIS.LeaseFinanceId = C.LeaseFinanceId AND LIS.IncomeDate BETWEEN LPS.StartDate AND LPS.EndDate AND LIS.IsSchedule = 1    
WHERE R.JObStepInstanceId = @JobstepInstanceId  AND UC.IsSKU = 0  
GROUP BY    
	C.ClassificationContractType,    
	UC.ReceivableDueDate,    
	UC.ReceivableDetailId,    
	UC.AssetId,    
	R.JobStepInstanceId
  
SELECT
	ULID.ClassificationContractType,    
	ULID.ReceivableDueDate,    
	ULID.ReceivableDetailId,    
	ULID.AssetId,   
	MIN(LIS.Id) AS LeaseIncomeScheduleId,  
	ULID.JobStepInstanceId,
	MAX(ULID.LeaseFinanceId) AS LeaseFinanceId
INTO #UpfrontIncomeDetailsForNonSKU  
FROM #UpfrontLeaseIncomeDetails ULID
	JOIN LeaseFinances LF ON ULID.ContractId = LF.ContractId
	JOIN LeaseIncomeSchedules LIS ON LIS.LeaseFinanceId = LF.Id AND ULID.IncomeDate = LIS.IncomeDate AND ULID.JobStepInstanceId = @JobStepInstanceId AND LIS.IsSchedule = 1 
GROUP BY    
	ULID.ClassificationContractType,    
	ULID.ReceivableDueDate,    
	ULID.ReceivableDetailId,    
	ULID.AssetId,    
	ULID.JobStepInstanceId
    
SELECT     
AIS.AssetId,    
NULL AS AssetSKUId,    
	CASE WHEN IncomeDetail.ClassificationContractType = @OperatingContractType THEN AIS.OperatingBeginNetBookValue_Amount - LA.CapitalizedSalesTax_Amount 
	ELSE  AIS.BeginNetBookValue_Amount - LA.CapitalizedSalesTax_Amount END AS NBV_Amount,    
IncomeDetail.ClassificationContractType,    
IncomeDetail.ReceivableDueDate,    
IncomeDetail.ReceivableDetailId    
INTO #AssetNBVDetails    
FROM #UpfrontIncomeDetailsForNonSKU IncomeDetail    
JOIN AssetIncomeSchedules AIS ON IncomeDetail.LeaseIncomeScheduleId = AIS.LeaseIncomeScheduleId AND IncomeDetail.AssetId = AIS.AssetId    
JOIN LeaseAssets LA ON AIS.AssetId = LA.AssetId AND LA.LeaseFinanceId = IncomeDetail.LeaseFinanceId
	AND (LA.IsActive = 1 OR (LA.IsActive = 0 AND LA.TerminationDate IS NOT NULL))
WHERE  IncomeDetail.JobStepInstanceId = @JobStepInstanceId;    
    
    
INSERT INTO #AssetNBVDetails    
SELECT     
 CN.AssetId,    
 CN.AssetSKUId,    
 CN.NBVAmount AS NBV_Amount,    
 IncomeDetail.ClassificationContractType,    
 IncomeDetail.ReceivableDueDate,    
 IncomeDetail.ReceivableDetailId    
FROM #UpfrontIncomeDetailsForSKU IncomeDetail    
JOIN #ContractDetails CN ON IncomeDetail.ReceivableDetailId = CN.ReceivableDetailId AND IncomeDetail.AssetID = CN.AssetId  
WHERE CN.AssetSKUId IS NOT NULL AND IncomeDetail.JobStepInstanceId = @JobStepInstanceId;   
    
    
SELECT      
  AssetId,AssetSKUId, LocationEffectiveDate, MIN(ReceivableDueDate) ReceivableDueDate    
INTO #UpfrontMinDueReceivables    
FROM #SalesTaxUpfrontCostDetails     
 GROUP BY AssetId,AssetSKUId, LocationEffectiveDate    
     
    
SELECT     
 R.ReceivableDueDate,    
 R.AssetId,    
 R.AssetSKUId,    
 R.ReceivableDetailId,    
 R.ReceivableId  ,
R.LocationEffectiveDate
 
INTO #ContractUpfrontDetails    
FROM #AllContractDetails R    
INNER JOIN #UpfrontMinLocationEffectiveDateReceivables UC     
ON R.AssetId = UC.AssetId    
WHERE  R.EndDate >= UC.LocationEffectiveDate  
	AND R.IsAssumedArrearLease = 1;  
 
INSERT INTO #ContractUpfrontDetails   
SELECT     
 R.ReceivableDueDate,    
 R.AssetId,    
 R.AssetSKUId,    
 R.ReceivableDetailId,    
 R.ReceivableId ,
R.LocationEffectiveDate
FROM #AllContractDetails R    
INNER JOIN #UpfrontMinLocationEffectiveDateReceivables UC     
ON R.AssetId = UC.AssetId    
WHERE  R.ReceivableDueDate >= UC.LocationEffectiveDate  
	AND IsAssumedArrearLease = 0
;    
    SELECT   
	R.AssetId,R.AssetSKUId, MIN(R.ReceivableDueDate) ReceivableDueDate 
INTO #CTEUpfrontMinDueReceivables1
FROM #SalesTaxUpfrontCostDetails R
JOIN #UpfrontMinLocationEffectiveDateReceivables UR
ON  R.AssetId = UR.AssetId AND ISNULL(R.AssetSKUId,0) = ISNULL(UR.AssetSKUId,0)
AND R.LocationEffectiveDate <> UR.LocationEffectiveDate
GROUP BY R.AssetId,R.AssetSKUId,R.LocationEffectiveDate 
;

SELECT R.AssetId,R.AssetSKUId,MIN(ReceivableId) ReceivableId 
INTO #ReceivableUpfront
from #SalesTaxUpfrontCostDetails R
JOIN #CTEUpfrontMinDueReceivables1 UR ON  R.AssetId = UR.AssetId AND ISNULL(R.AssetSKUId,0) = ISNULL(UR.AssetSKUId,0)
AND R.ReceivableDueDate = UR.ReceivableDueDate
GROUP BY R.AssetId,R.AssetSKUId,R.LocationEffectiveDate  
;
  
UPDATE #SalesTaxUpfrontCostDetails  
 SET IsUpfrontTaxApplicable = 1   
FROM #SalesTaxUpfrontCostDetails UR  
JOIN #ReceivableUpfront URDetails   
ON UR.ReceivableId = URDetails.ReceivableId  AND UR.AssetId = URDetails.AssetId
AND ISNULL(UR.AssetSkuId,0) = ISNULL(URDetails.AssetSKUId,0)
; 

    
    SELECT  CR.AssetId,CR.LocationEffectiveDate,MIN(ReceivableDueDate) AS ReceivableDueDate,CR.AssetSKUId
INTO #UpfrontReceivableDueDatesForMinLocation
FROM #ContractUpfrontDetails CR
WHERE CR.ReceivableDueDate >= CR.LocationEffectiveDate
GROUP BY  CR.AssetId,CR.AssetSKUId,CR.LocationEffectiveDate
 
 SELECT R.AssetId,R.AssetSKUId,MIN(ReceivableId) ReceivableId 
INTO #UpfrontReceivables
from #ContractUpfrontDetails R
JOIN #UpfrontReceivableDueDatesForMinLocation UR ON R.AssetId = UR.AssetId AND ISNULL(R.AssetSKUId,0) = ISNULL(UR.AssetSKUId,0)
AND R.ReceivableDueDate = UR.ReceivableDueDate
GROUP BY R.AssetId,R.AssetSKUId,R.LocationEffectiveDate  
;

UPDATE #SalesTaxUpfrontCostDetails  
 SET IsUpfrontTaxApplicable = 1   
FROM #SalesTaxUpfrontCostDetails UR  
JOIN #UpfrontReceivables URDetails   
ON UR.ReceivableId = URDetails.ReceivableId  AND UR.AssetId = URDetails.AssetId
AND ISNULL(UR.AssetSkuId,0) = ISNULL(URDetails.AssetSKUId,0)
; 

  
/*for non sku*/  
UPDATE #SalesTaxUpfrontCostDetails  
 SET AssetCost = NBV_Amount  
FROM #SalesTaxUpfrontCostDetails CR  
JOIN   
 (  
  SELECT DISTINCT AssetId, NBVAmount NBV_Amount FROM #ContractDetails  
 ) AB ON CR.AssetId = AB.AssetId AND CR.AssetSKUId IS NULL  
AND CR.IsUpfrontTaxApplicable = 1 AND ReceivableTypeName = @InterimRentalReceivableType   
;  
    
/* for SKU assets */    
UPDATE #SalesTaxUpfrontCostDetails    
 SET AssetCost = NBV_Amount    
FROM #SalesTaxUpfrontCostDetails CR    
JOIN     
 (    
  SELECT DISTINCT AssetId, AssetSKUId, NBVAmount NBV_Amount FROM #ContractDetails      
 ) AB ON CR.AssetId = AB.AssetId AND CR.AssetSKUId = AB.AssetSKUId    
AND CR.IsUpfrontTaxApplicable = 1 AND ReceivableTypeName = @InterimRentalReceivableType     
;    
    
/* for non SKU assets */    
UPDATE #SalesTaxUpfrontCostDetails    
 SET AssetCost = NBV_Amount    
FROM #SalesTaxUpfrontCostDetails CR    
JOIN #AssetNBVDetails AB ON CR.AssetId = AB.AssetId AND CR.AssetSKUId Is NULL    
 AND CR.ReceivableDetailId = AB.ReceivableDetailId    
AND CR.IsUpfrontTaxApplicable = 1 AND ReceivableTypeName <> @InterimRentalReceivableType    
;    
    
/* for SKU assets */    
UPDATE #SalesTaxUpfrontCostDetails    
 SET AssetCost = NBV_Amount    
FROM #SalesTaxUpfrontCostDetails CR    
JOIN #AssetNBVDetails AB ON CR.AssetId = AB.AssetId AND CR.AssetSKUId = AB.AssetSKUId    
 AND CR.ReceivableDetailId = AB.ReceivableDetailId    
AND CR.IsUpfrontTaxApplicable = 1 AND ReceivableTypeName <> @InterimRentalReceivableType    
;    
    
SELECT    
 AD.AssetId,AD.AssetSKUId, AD.ReceivableDetailId, (-1) * RD.Cost_Amount AssetCost,     
 1 AS CreatedById, SYSDATETIMEOFFSET() AS CreatedTime, @JobStepInstanceId AS JobStepInstanceId    
INTO #AdjustmentUpfrontCostAmountDetails    
FROM #AdjustmentUpfrontCostDetails AD     
JOIN ReceivableTaxDetails RD ON AD.AdjustmentId = RD.ReceivableDetailId     
AND RD.IsActive = 1 AND RD.Cost_Amount <> 0.00    
;    
    
    
INSERT INTO VertexUpfrontCostDetailExtract    
 ([AssetId],[AssetSKUId], [ReceivableDetailId], [AssetCost],[JobStepInstanceId])    
SELECT    
 [AssetId],[AssetSKUId], [ReceivableDetailId], [AssetCost],@JobStepInstanceId    
FROM #SalesTaxUpfrontCostDetails    
WHERE IsUpfrontTaxApplicable = 1    
UNION ALL    
SELECT    
 [AssetId],[AssetSKUId], [ReceivableDetailId], [AssetCost],@JobStepInstanceId    
FROM #AdjustmentUpfrontCostAmountDetails    
UNION ALL    
SELECT AssetId,AssetSKUId, ReceivableDetailId, AssetCost, JobStepInstanceId  FROM     
(    
 SELECT     
  OU.AssetId,OU.AssetSKUId, OU.ReceivableDetailId, ST.AssetCost, @JobStepInstanceId AS JobStepInstanceId    
  ,ROW_NUMBER() OVER (PARTITION BY OU.AssetId,  OU.ReceivableDueDate ORDER BY OU.ReceivableId) RowNumber    
 FROM #OriginalUpfrontCostDetails OU    
 JOIN #SalesTaxUpfrontCostDetails ST ON OU.AssetId = ST.AssetId    
 AND OU.ReceivableDueDate = ST.ReceivableDueDate    
 WHERE ST.IsUpfrontTaxApplicable = 1    
) AS OriginalUpfrontCostDetails    
WHERE OriginalUpfrontCostDetails.RowNumber = 1    
UNION ALL    
SELECT AssetId,AssetSKUId, ReceivableDetailId, AssetCost, JobStepInstanceId  FROM     
(    
 SELECT     
   AU.AssetId,AU.AssetSKUId, AU.ReceivableDetailId,(-1) * ST.AssetCost AS AssetCost, @JobStepInstanceId AS JobStepInstanceId    
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
  
/*  
  
Select * From #SalesTaxUpfrontCostDetails  
  
DROP TABLE #SalesTaxUpfrontCostDetails  
DROP TABLE #OriginalUpfrontCostDetails  
DROP TABLE #AdjustmentUpfrontCostDetails  
DROP TABLE #AdjustmentDetail  
DROP TABLE #UpfrontMinLocationEffectiveDateReceivables  
DROP TABLE #AllContractDetails  
DROP TABLE #AllAdjustmentDetail  
DROP TABLE #ContractDetails  
DROP TABLE #AssetNBVDetails  
DROP TABLE #UpfrontReceivables  
DROP TABLE #ContractUpfrontDetails  
DROP TABLE #UpfrontMinDueReceivables  
DROP TABLE #AdjustmentUpfrontCostAmountDetails  
  
*/  
END

GO

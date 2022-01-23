SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[GetReceivablesToAdjustFromPayoff]    
(    
	@ContractId BIGINT,    
	@EntityType NVARCHAR(40),    
	@PayoffEffectiveDate DATETIME,    
	@IsSyndicationServiced BIT,    
	@ReceivableTypes NVARCHAR(MAX),
	@IsVATApplicable BIT        
)    
AS    
BEGIN    
SET NOCOUNT ON;    
CREATE TABLE #ReceivableTypesTemp    
(    
	 ReceivableTypeId BigInt, ConsiderAssetComponentType BIT 
)    
CREATE TABLE #ReceivablesToExclude    
(    
	 ReceivableId BIGINT
)    

CREATE CLUSTERED INDEX IDX_ReceivablesToExclude ON #ReceivablesToExclude(ReceivableId)

INSERT INTO #ReceivableTypesTemp  
Select RT.Id, 
	CASE WHEN RT.Name IN ('CapitalLeaseRental','OperatingLeaseRental') 
	THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) 
	END AS ConsiderAssetComponentType
from ReceivableTypes RT  
Join  ConvertCSVToStringTable(@ReceivableTypes, ',') CSVRT On RT.Name = CSVRT.Item  
   
INSERT INTO #ReceivablesToExclude (ReceivableId)   
SELECT   
 receivableDetail.ReceivableId   
FROM Receivables receivable 
JOIN ReceivableDetails receivableDetail ON receivableDetail.ReceivableId = receivable.Id 
	AND receivable.EntityId = @ContractId AND receivable.EntityType = 'CT'
JOIN ReceivableDetails adjustmentReceivableDetail ON receivableDetail.Id = adjustmentReceivableDetail.AdjustmentBasisReceivableDetailId OPTION (LOOP JOIN)

INSERT INTO #ReceivablesToExclude (ReceivableId)   
SELECT   
 receivableDetail.ReceivableId   
FROM Receivables receivable
JOIN ReceivableDetails receivableDetail ON receivableDetail.ReceivableId = receivable.Id
AND receivable.EntityId = @ContractId AND receivable.EntityType = 'CT'
AND receivableDetail.IsActive = 1 AND receivable.IsActive = 1        
AND receivableDetail.AdjustmentBasisReceivableDetailId IS NOT NULL
  
SELECT    
Receivables.Id [ReceivableId]    
,Receivables.CustomerId    
,Receivables.DueDate    
,Receivables.EntityId    
,Receivables.FunderId    
,Receivables.IncomeType    
,Receivables.InvoiceComment    
,Receivables.InvoiceReceivableGroupingOption    
,Receivables.IsCollected    
,Receivables.IsServiced    
,Receivables.IsPrivateLabel
,Receivables.LegalEntityId    
,Receivables.LocationId    
,Receivables.PaymentScheduleId    
,Receivables.ReceivableCodeId    
,Receivables.RemitToId    
,Receivables.SourceTable    
,LeasePaymentSchedules.PaymentNumber    
,LeasePaymentSchedules.PaymentType    
,Receivables.AlternateBillingCurrencyId    
,Receivables.ExchangeRate    
,RecTypeTemp.ConsiderAssetComponentType
,RentSharingDetails.Percentage
,IsNull(RentSharingDetails.SourceType,'_') AS SourceType
,RentSharingDetails.VendorId
,RentSharingDetails.PayableCodeId
,RentSharingDetails.RemitToId AS RentSharingRemitToId
,Receivables.ReceivableTaxType
INTO #ReceivableInfo
FROM Receivables   
JOIN ReceivableCodes ON Receivables.EntityId = @ContractId AND Receivables.ReceivableCodeId = ReceivableCodes.Id AND Receivables.SourceTable = '_'  
AND Receivables.IsActive = 1   
JOIN #ReceivableTypesTemp RecTypeTemp ON ReceivableCodes.ReceivableTypeId = RecTypeTemp.ReceivableTypeId    
JOIN LeasePaymentSchedules ON Receivables.PaymentScheduleId = LeasePaymentSchedules.Id AND LeasePaymentSchedules.IsActive = 1    
LEFT JOIN #ReceivablesToExclude receivablesToExclude ON Receivables.Id = receivablesToExclude.ReceivableId    
LEFT JOIN RentSharingDetails ON  Receivables.Id = RentSharingDetails.ReceivableId AND RentSharingDetails.IsActive = 1
WHERE Receivables.EntityType = @EntityType 
AND LeasePaymentSchedules.StartDate >= @PayoffEffectiveDate  
AND (@IsSyndicationServiced = 1 OR Receivables.FunderId IS NULL)    
AND receivablesToExclude.ReceivableId is NULL    
AND (@IsVATApplicable = 0 OR (@IsVATApplicable = 1 AND RecTypeTemp.ConsiderAssetComponentType = 1))

SELECT * FROM #ReceivableInfo

SELECT    
ReceivableDetails.Id [ReceivableDetailId]  
,Receivables.ReceivableId [ReceivableId]     
,ReceivableDetails.AssetId    
,ReceivableDetails.BillToId 
,ReceivableDetails.Amount_Amount [Amount]    
,CASE WHEN Receivables.ConsiderAssetComponentType = 1 THEN ReceivableDetails.AssetComponentType ELSE '_' END [AssetComponentType] 
,ReceivableDetails.LeaseComponentAmount_Amount [LeaseComponentAmount]
,ReceivableDetails.NonLeaseComponentAmount_Amount [NonLeaseComponentAmount]
,Receivables.ReceivableTaxType
FROM #ReceivableInfo Receivables     
JOIN ReceivableDetails ON Receivables.ReceivableId = ReceivableDetails.ReceivableId AND ReceivableDetails.IsActive = 1 

SET NOCOUNT OFF;    
END

GO

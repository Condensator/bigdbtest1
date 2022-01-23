SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 
--Query To Fetch ReceivableDetails To process as a batch  
  
CREATE PROCEDURE [dbo].[GetVertexReceivableDetailForProcessing]  
(  
 @BatchCount BigInt,  
 @NewBatchStatus NVARCHAR(10),   
 @ProcessingBatchStatus NVARCHAR(50),  
 @TaskChunkServiceInstanceId BIGINT NULL,  
 @JobStepInstanceId BIGINT,  
 @UnknownTaxBasis NVARCHAR(10)  
)  
AS  
BEGIN    
        
CREATE TABLE #Updated (Id BIGINT)    
  
BEGIN   
	UPDATE TOP (1) VertexWSTransactionChunksExtract SET 
		BatchStatus = @ProcessingBatchStatus,    
		TaskChunkServiceInstanceId = @TaskChunkServiceInstanceId    
	 OUTPUT DELETED.Id INTO #Updated  
	 FROM VertexWSTransactionChunksExtract VTE  
	 WHERE VTE.JobStepInstanceId = @JobStepInstanceId AND BatchStatus = @NewBatchStatus

END  
    
SELECT     
  ROW_NUMBER() OVER (ORDER BY WS.Id) as LineItemNumber,ReceivableId, ReceivableDetailId, AmountBilledToDate, City, CustomerCode, CurrencyCode AS Currency, Cost,    
  CompanyCode AS Company, DueDate, MainDivision, Country, ExtendedPrice, FairMarketValue, LocationCode, Product, TaxAreaId, TransactionType,    
  CustomerClass AS ClassCode,Term AS LeaseTerm, GrossVehicleWeight, ReciprocityAmount, LienCredit, LocationEffectiveDate, TransCode AS TransactionCode, ContractTypeName AS ContractType,    
  ShortLeaseType AS LeaseType, TaxBasis AS TaxBasisType, LeaseUniqueID AS LeaseUniqueId, TitleTransferCode, SundryReceivableCode, AssetType, SaleLeasebackCode,    
  IsElectronicallyDelivered, TaxRemittanceType, FromState, ToState, AssetId, SalesTaxExemptionLevel, TaxReceivableName AS ReceivableType,    
  IsSyndicated, BusCode, HorsePower, AssetCatalogNumber, IsTaxExempt, TaxExemptReason,IsPrepaidUpfrontTax , IsCapitalizedRealAsset,    
  IsCapitalizedSalesTaxAsset, IsExemptAtAsset, IsExemptAtReceivableCode, IsExemptAtSundry, LocationId, LocationStatus, LegalEntityId,    
  CASE WHEN AssetId IS NOT NULL 
	  THEN  CASE WHEN WS.IsSKU = 1 AND AssetSKUId IS NOT NULL 
				THEN CAST(CAST(ReceivableDetailId AS NVARCHAR(50)) + '-' + CAST(AssetId AS NVARCHAR(50)) + '-' + CAST(AssetSKUId AS NVARCHAR(50))  AS NVARCHAR(100))  
				ELSE CAST(CAST(ReceivableDetailId AS NVARCHAR(50)) + '-' + CAST(AssetId AS NVARCHAR(50)) AS NVARCHAR(100)) 
			END    
	  ELSE     
	  CAST(ReceivableDetailId AS NVARCHAR(100))     
  END AS LineItemId,    
  WS.Usage,    
  WS.AssetLocationId,    
  WS.GLTemplateId,    
  WS.IsCapitalizedFirstRealAsset,  
  WS.SalesTaxRemittanceResponsibility,  
  WS.AcquisitionLocationTaxAreaId,  
  WS.AcquisitionLocationCity,  
  WS.AcquisitionLocationMainDivision,  
  WS.AcquisitionLocationCountry,  
  WS.AssetUsageCondition,  
  WS.AssetSerialOrVIN,  
  WS.MaturityDate AS MaturityDate ,  
  WS.CommencementDate AS CommencementDate,  
  WS.AssetSKUId,  
  WS.IsExemptAtAssetSKU,  
  WS.ReceivableSKUId,
  WS.UpfrontTaxAssessedInLegacySystem
FROM VertexWSTransactionExtract WS    
INNER JOIN VertexWSTransactionChunkDetailsExtract VTCDE ON WS.Id = VTCDE.VertexWSTransactionId AND VTCDE.JobStepInstanceId = @JobStepInstanceId
WHERE VTCDE.VertexWSTransactionChunks_ExtractId = (select Id from #Updated) 
    
END

GO

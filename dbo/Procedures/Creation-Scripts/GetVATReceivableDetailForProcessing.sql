SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 
--Query To Fetch ReceivableDetails To process as a batch  
  
CREATE PROCEDURE [dbo].[GetVATReceivableDetailForProcessing]  
(  
 @BatchCount BigInt,  
 @NewBatchStatus NVARCHAR(10),   
 @ProcessingBatchStatus NVARCHAR(50),  
 @TaskChunkServiceInstanceId BIGINT NULL,  
 @JobStepInstanceId BIGINT
)  
AS  
BEGIN    
    
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE    
    
CREATE TABLE #Updated (Id BIGINT)    
  
BEGIN   

	UPDATE TOP (@BatchCount) VATReceivableDetailChunkExtract SET 
		BatchStatus = @ProcessingBatchStatus,    
		TaskChunkServiceInstanceId = @TaskChunkServiceInstanceId    
	 OUTPUT DELETED.Id INTO #Updated  
	 FROM VATReceivableDetailChunkExtract VTE  
	 WHERE VTE.JobStepInstanceId = @JobStepInstanceId AND BatchStatus = @NewBatchStatus

END  
    
SELECT     
  ROW_NUMBER() OVER (ORDER BY WS.Id) as UniqueDetailId
  ,[ReceivableId]
  ,[ReceivableDetailId]
  ,[ReceivableDueDate]
  ,[AssetId]
  ,[ReceivableDetailAmount]
  ,[Currency]
  ,[GLTemplateId]
  ,@JobStepInstanceId AS JobStepInstanceId
  ,[TaxLevel]
  ,[BuyerLocationId]
  ,[SellerLocationId]
  ,[TaxReceivableTypeId]
  ,[PayableTypeId]
  ,[TaxAssetTypeId]
  ,[IsCashBased]
  ,[BuyerLocation]
  ,[SellerLocation] 
  ,[TaxReceivableType] 
  ,[TaxAssetType]
  ,[IsCapitalizedUpfront]
  ,[IsReceivableCodeTaxExempt]
  ,[BuyerTaxRegistrationId]
  ,[SellerTaxRegistrationId]
  ,[TaxRemittanceType]
FROM VATReceivableDetailExtract WS    
INNER JOIN VATReceivableDetailChunkDetailsExtract VTCDE 
	ON WS.Id = VTCDE.VATReceivableDetail_ExtractId 
	AND VTCDE.JobStepInstanceId = @JobStepInstanceId
WHERE VTCDE.VATReceivableDetailChunk_ExtractId = (select Id from #Updated) 
    
END

GO

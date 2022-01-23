SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InsertSalesTaxReversalReceivableSKUDetails]
(
  @JobStepInstanceId BIGINT
)
AS
BEGIN

INSERT INTO [dbo].[ReversalReceivableSKUDetail_Extract]    
           (  
            [ReceivableSKUId]  
           ,[ReceivableTaxDetailId]    
           ,[Currency]    
           ,[Cost]    
           ,[ExtendedPrice]    
           ,[FairMarketValue]    
           ,[AssetSKUId]    
           ,[IsExemptAtAssetSKU]    
           ,[AmountBilledToDate]    
           ,[JobStepInstanceId]    
           ,[CreatedById]    
           ,[CreatedTime]    
)    
Select     
    RST.ReceivableSKUId,     
    RDT.ReceivableTaxDetailId,    
    RST.Cost_Currency,    
    RST.Cost_Amount*(-1) AS Cost,    
    RST.Amount_Amount*(-1) AS ExtendedPrice,    
    RST.FairMarketValue_Amount*(-1) AS FairMarketValue,    
    RST.AssetSKUId,    
    RST.IsExemptAtAssetSKU,    
    RST.AmountBilledToDate_Amount,    
    RDT.JobStepInstanceId,    
    CreatedById = 1,    
    CreatedTime = SYSDATETIMEOFFSET()    
From ReversalReceivableDetail_Extract RDT    
INNER JOIN ReceivableSKUTaxReversalDetails RST ON RDT.ReceivableTaxDetailId = RST.ReceivableTaxDetailId    
INNER JOIN ReceivableSKUs RS ON RST.ReceivableSKUId = RS.Id    
WHere RDT.JobStepInstanceId  =  @JobStepInstanceId  AND  RDT.IsAssessSalesTaxAtSKULevel = 1

END

GO

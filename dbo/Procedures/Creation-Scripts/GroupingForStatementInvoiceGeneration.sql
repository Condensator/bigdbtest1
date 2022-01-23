SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GroupingForStatementInvoiceGeneration] (    
 @JobStepInstanceId BIGINT,    
 @ChunkNumber BIGINT    
 )    
AS    
BEGIN    
 SET NOCOUNT ON;    
    
 DECLARE @TotalRows BIGINT    
    
 CREATE TABLE #StatementInvoiceSplitReceivableDetails(    
       ReceivableDetailId BIGINT NOT NULL,    
    ReceivableInvoiceId BIGINT NOT NULL,    
          GroupNumber INT,    
          SplitNumber INT,    
          ContractId BIGINT,    
          LocationId BIGINT,    
          AssetId BIGINT,    
          AdjustmentBasisReceivableDetailId BIGINT NULL,    
          IsAdjustmentReceivable BIT NOT NULL,    
    IsReceivableTypeRental BIT NOT NULL,    
          SplitRentalInvoiceByAsset BIT NOT NULL,    
          SplitCreditsByOriginalInvoice BIT NOT NULL,    
          SplitByReceivableAdjustments BIT NOT NULL,    
          SplitRentalInvoiceByContract BIT NOT NULL,    
          SplitLeaseRentalInvoiceByLocation BIT NOT NULL,    
          SplitReceivableDueDate BIT NOT NULL,    
          SplitCustomerPurchaseOrderNumber BIT NOT NULL,    
          AssetPurchaseOrderNumber NVARCHAR(40),    
          ReceivableDueDate DATE    
       )    
           
    CREATE NONCLUSTERED INDEX IX_DetailInvoice ON #StatementInvoiceSplitReceivableDetails(ReceivableDetailId, ReceivableInvoiceId)  
  
    INSERT INTO #StatementInvoiceSplitReceivableDetails(    
       ReceivableDetailId,    
    ReceivableInvoiceId,    
          GroupNumber,    
          SplitNumber,    
          ContractId,    
          LocationId,    
          AssetId,    
          AdjustmentBasisReceivableDetailId,    
          IsAdjustmentReceivable,    
      IsReceivableTypeRental,    
          SplitRentalInvoiceByAsset,    
          SplitCreditsByOriginalInvoice,    
          SplitByReceivableAdjustments,    
          SplitRentalInvoiceByContract,    
          SplitLeaseRentalInvoiceByLocation,    
          SplitReceivableDueDate,    
          SplitCustomerPurchaseOrderNumber,    
          AssetPurchaseOrderNumber,    
          ReceivableDueDate    
    )    
    SELECT    
    SIRD.ReceivableDetailId,    
    SIRD.ReceivableInvoiceId,    
            Rank() OVER (    
                        ORDER BY SIRD.LegalEntityId        
                                ,SIRD.CustomerID    
                                ,SIRD.RemitToId    
                                ,SIRD.BillToID    
                                ,SIRD.CurrencyId         
                                ,SIRD.AlternateBillingCurrencyId    
                                ,SIRD.IsDSL    
                                ,SIRD.IsPrivateLabel    
                                ,SIRD.RI_StatementInvoicePreference    
                            ) AS InvoiceGroupNumber    
            ,CAST(0 AS INT) AS SplitNumber    
            ,SIRD.ContractId    
            ,SIRD.LocationId    
            ,SIRD.AssetId    
            ,SIRD.AdjustmentBasisReceivableDetailId    
            ,CASE WHEN SIRD.AdjustmentBasisReceivableDetailId IS NOT NULL THEN 1 ELSE  0 END AS IsAdjustmentReceivable    
   ,SIRD.IsReceivableTypeRental    
            ,SIRD.SplitRentalInvoiceByAsset    
            ,SIRD.SplitCreditsByOriginalInvoice    
            ,SIRD.SplitByReceivableAdjustments    
            ,SIRD.SplitRentalInvoiceByContract    
            ,SIRD.SplitLeaseRentalInvoiceByLocation    
            ,SIRD.SplitReceivableDueDate    
            ,SIRD.SplitCustomerPurchaseOrderNumber    
            ,SIRD.AssetPurchaseOrderNumber    
            ,SIRD.ReceivableDueDate    
    FROM StatementInvoiceReceivableDetails_Extract SIRD    
    JOIN InvoiceChunkDetails_Extract ICD ON SIRD.BillToId = ICD.BillToId     
            AND SIRD.JobStepInstanceId = ICD.JobStepInstanceId AND ICD.ChunkNumber=@ChunkNumber    
    WHERE SIRD.JobStepInstanceId = @JobStepInstanceId --AND SIRD.IsActive=1     
    ;    
    
    SET @TotalRows = @@ROWCOUNT

    UPDATE #StatementInvoiceSplitReceivableDetails
    SET GroupNumber = SP.UpdatedGroupNumber
    FROM #StatementInvoiceSplitReceivableDetails SI
    JOIN (
		  SELECT ReceivableDetailId, ReceivableInvoiceId,
				RANK() OVER ( 
						  ORDER BY GroupNumber
						  ,SplitRentalInvoiceByAsset    
						  ,SplitCreditsByOriginalInvoice    
						  ,SplitByReceivableAdjustments    
						  ,SplitRentalInvoiceByContract    
						  ,SplitLeaseRentalInvoiceByLocation    
						  ,SplitReceivableDueDate    
						  ,SplitCustomerPurchaseOrderNumber 
						  ) AS UpdatedGroupNumber
		  FROM #StatementInvoiceSplitReceivableDetails 
    ) SP ON SI.ReceivableDetailId=SP.ReceivableDetailId  AND SI.ReceivableInvoiceId=SP.ReceivableInvoiceId  
    
    UPDATE #StatementInvoiceSplitReceivableDetails    
    SET SplitNumber = SP.SplitContract    
    FROM #StatementInvoiceSplitReceivableDetails SI    
   JOIN (    
    SELECT ReceivableDetailId, ReceivableInvoiceId,    
    CASE     
    WHEN SplitRentalInvoiceByContract = 1    
        THEN Rank() OVER (ORDER BY GroupNumber, ContractId)    
    ELSE SplitNumber --Change To SplitNumber    
    END AS SplitContract    
    FROM #StatementInvoiceSplitReceivableDetails    
    ) SP    
   ON SI.ReceivableDetailId=SP.ReceivableDetailId  AND SI.ReceivableInvoiceId=SP.ReceivableInvoiceId  
    
   UPDATE #StatementInvoiceSplitReceivableDetails    
       SET SplitNumber = SP.SplitLocation    
       FROM #StatementInvoiceSplitReceivableDetails SI    
   JOIN (    
    SELECT ReceivableDetailId,  ReceivableInvoiceId,  
    CASE     
    WHEN IsReceivableTypeRental =1 AND SplitLeaseRentalInvoiceByLocation = 1    
        THEN Rank() OVER (ORDER BY SplitNumber, LocationId)    
    ELSE SplitNumber    
    END  AS SplitLocation    
    FROM #StatementInvoiceSplitReceivableDetails    
    ) SP    
   ON SI.ReceivableDetailId=SP.ReceivableDetailId AND SI.ReceivableInvoiceId=SP.ReceivableInvoiceId  
    
   UPDATE #StatementInvoiceSplitReceivableDetails    
       SET SplitNumber = SP.SplitAsset    
       FROM #StatementInvoiceSplitReceivableDetails SI    
   JOIN (    
    SELECT ReceivableDetailId, ReceivableInvoiceId,   
    CASE     
    WHEN IsReceivableTypeRental=1 AND SplitRentalInvoiceByAsset = 1    
        THEN Rank() OVER (ORDER BY SplitNumber, AssetId)    
    ELSE SplitNumber    
    END AS SplitAsset    
    FROM #StatementInvoiceSplitReceivableDetails    
    ) SP    
   ON SI.ReceivableDetailId=SP.ReceivableDetailId  AND SI.ReceivableInvoiceId = SP.ReceivableInvoiceId  
    
   UPDATE #StatementInvoiceSplitReceivableDetails    
       SET SplitNumber = SP.SplitAdj    
       FROM #StatementInvoiceSplitReceivableDetails SI    
   JOIN (    
    SELECT ReceivableDetailId,  ReceivableInvoiceId,  
    CASE     
    WHEN SplitByReceivableAdjustments = 1    
        THEN Rank() OVER (ORDER BY SplitNumber, IsAdjustmentReceivable)    
    ELSE SplitNumber    
    END AS SplitAdj    
    FROM #StatementInvoiceSplitReceivableDetails    
    ) SP    
   ON SI.ReceivableDetailId=SP.ReceivableDetailId AND SI.ReceivableInvoiceId=SP.ReceivableInvoiceId  
    
    
   UPDATE #StatementInvoiceSplitReceivableDetails    
       SET SplitNumber = SP.SplitDueDate    
       FROM #StatementInvoiceSplitReceivableDetails SI    
   JOIN (    
    SELECT ReceivableDetailId,  ReceivableInvoiceId,  
    CASE     
    WHEN SplitReceivableDueDate = 1    
        THEN Rank() OVER (ORDER BY SplitNumber, ReceivableDueDate)    
    ELSE SplitNumber    
    END AS SplitDueDate    
    FROM #StatementInvoiceSplitReceivableDetails    
    ) SP    
    ON SI.ReceivableDetailId=SP.ReceivableDetailId  AND SI.ReceivableInvoiceId=SP.ReceivableInvoiceId  
    
   UPDATE #StatementInvoiceSplitReceivableDetails    
       SET SplitNumber = SP.SplitPurchaseOrderNumber    
       FROM #StatementInvoiceSplitReceivableDetails SI    
   JOIN (    
    SELECT ReceivableDetailId,  ReceivableInvoiceId,  
    CASE     
    WHEN SplitCustomerPurchaseOrderNumber = 1    
        THEN Rank() OVER (ORDER BY SplitNumber, AssetPurchaseOrderNumber)    
    ELSE SplitNumber    
    END AS SplitPurchaseOrderNumber    
    FROM #StatementInvoiceSplitReceivableDetails    
    ) SP    
   ON SI.ReceivableDetailId=SP.ReceivableDetailId  AND SI.ReceivableInvoiceId=SP.ReceivableInvoiceId  
    
   UPDATE #StatementInvoiceSplitReceivableDetails    
       SET SplitNumber = CASE WHEN SI.SplitCreditsByOriginalInvoice = 1 
							  THEN @TotalRows + SI.SplitNumber + SP.SplitCred    
							  ELSE SI.SplitNumber
						 END
       FROM #StatementInvoiceSplitReceivableDetails SI    
   JOIN (    
    SELECT #StatementInvoiceSplitReceivableDetails.ReceivableDetailId,  #StatementInvoiceSplitReceivableDetails.ReceivableInvoiceId,  
    CASE     
    WHEN #StatementInvoiceSplitReceivableDetails.SplitCreditsByOriginalInvoice = 1    
        THEN Rank() OVER (ORDER BY SplitNumber, RI.Id)    
    ELSE SplitNumber    
    END AS SplitCred    
    FROM #StatementInvoiceSplitReceivableDetails     
    INNER JOIN ReceivableInvoiceDetails RID ON RID.ReceivableDetailId = #StatementInvoiceSplitReceivableDetails.AdjustmentBasisReceivableDetailId AND RID.IsActive = 1    
    INNER JOIN ReceivableInvoices RI ON RI.Id = RID.ReceivableInvoiceId AND RI.IsActive = 1    
    ) SP    
   ON SI.ReceivableDetailId=SP.ReceivableDetailId  AND SI.ReceivableInvoiceId=SP.ReceivableInvoiceId  
    
    
   CREATE TABLE #InvoiceUpdates(    
    InvoiceId BIGINT PRIMARY KEY,    
    UniqueNumber BIGINT     
   )    
    
   INSERT INTO #InvoiceUpdates(UniqueNumber, InvoiceId)    
   SELECT (DENSE_RANK() OVER (    
                             ORDER BY     
         T.GroupNumber,    
         T.SplitNumber    
                             ))     
              ,ReceivableInvoiceId    
       FROM #StatementInvoiceSplitReceivableDetails AS T    
       GROUP BY T.GroupNumber    
                ,T.SplitNumber    
                ,T.ReceivableInvoiceId    
                          
    UPDATE StatementInvoiceReceivableDetails_Extract     
       SET GroupNumber = SIG.UniqueNumber    
    FROM InvoiceChunkDetails_Extract ICDE    
    JOIN StatementInvoiceReceivableDetails_Extract SIRD     
    ON ICDE.JobStepInstanceId=@JobStepInstanceId AND SIRD.BillToId= ICDE.BillToId AND ICDE.ChunkNumber = @ChunkNumber    
    JOIN #InvoiceUpdates SIG ON SIRD.ReceivableInvoiceId = SIG.InvoiceId    
    AND SIRD.JobStepInstanceId = @JobStepInstanceId    
    
    DROP TABLE #InvoiceUpdates    
    DROP TABLE #StatementInvoiceSplitReceivableDetails   
END

GO

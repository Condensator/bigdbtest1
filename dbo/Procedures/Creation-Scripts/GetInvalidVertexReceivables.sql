SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
--Query To Fetch ReceivableDetails with invalid taxbasis and invalid location to throw error  
    
CREATE PROCEDURE [dbo].[GetInvalidVertexReceivables]   
(    
  @UnknownTaxBasis NVARCHAR(10),  
  @JobStepInstanceId BIGINT,  
  @UALCode NVARCHAR(100)  
)    
AS    
BEGIN    
	SELECT  
		ReceivableId,  
		ReceivableDetailId,  
		DueDate,  
		LeaseUniqueID,  
		AssetId  
	FROM VertexWSTransactionExtract  
	WHERE TaxBasis IS NULL OR TaxBasis = '' OR TaxBasis = @UnknownTaxBasis  
		AND VertexWSTransactionExtract.JobStepInstanceId =@JobStepInstanceId   
  
	SELECT  
		STR.ReceivableId,  
		STR.ReceivableDetailId,  
		STR.ReceivableDueDate,  
		STR.AssetId,  
		STR.InValidErrorCode,  
		ISNULL(C.SequenceNumber,'')   
	FROM SalesTaxReceivableDetailExtract STR  
		LEFT JOIN Contracts C on C.Id = STR.ContractId  
	WHERE InvalidErrorCode = @UALCode AND STR.IsVertexSupported = 1  
		AND STR.JobStepInstanceId =@JobStepInstanceId;  
END

GO

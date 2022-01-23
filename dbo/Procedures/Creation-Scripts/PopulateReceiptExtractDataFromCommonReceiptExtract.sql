SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[PopulateReceiptExtractDataFromCommonReceiptExtract]   
(  
 @ReceiptBatchId      BIGINT = NULL,   
 @PostDate       DATETIME,   
 @JobStepInstanceId     BIGINT,   
 @UserId        BIGINT, 
 @GLTemplateId BIGINT
)  
AS  
BEGIN  
  
SET NOCOUNT ON;  

 INSERT INTO Receipts_Extract (  
  ReceiptId,     
  Currency,   
  ReceivedDate,   
  ReceiptClassification,   
  EntityType,    
  CustomerId,
  ReceiptAmount,     
  LegalEntityId,   
  InstrumentTypeId,   
  CostCenterId,   
  CurrencyId,    
  LineOfBusinessId,   
  BankAccountId,  
  DumpId,   
  IsValid,   
  IsNewReceipt,   
  ReceiptBatchId,   
  PostDate,   
  JobStepInstanceId,   
  CreatedById,   
  CreatedTime,    
  Comment,  
  CheckNumber
  ,ReceiptGLTemplateId
  ,ReceiptType
  ,ReceiptTypeId
  ,IsReceiptHierarchyProcessed
  ,CashTypeId
  ,SecurityDepositLiabilityAmount
  ,SecurityDepositLiabilityContractAmount
)  
 SELECT   
  CEX.Id,   
  CEX.Currency,   
  CEX.ReceivedDate,  
  'Cash',  
  CEX.EntityType,    
  CASE WHEN CEX.EntityType = 'Customer' THEN CEX.EntityId ELSE NULL END,
  CEX.ReceiptAmount,  
  CEX.LegalEntityId,   
  CEX.InstrumentTypeId,   
  CEX.CostCenterId,   
  CEX.CurrencyId,    
  CEX.LineOfBusinessId,   
  CEX.BankAccountId,  
  CEX.Id,   
  1,   
  1,   
  @ReceiptBatchId,   
  @PostDate,   
  @JobStepInstanceId,   
  @UserId,   
  GETDATE(),    
  CEX.Comment,  
  CEX.CheckNumber
  ,@GLTemplateId
  ,RT.ReceiptTypeName
  ,CASE WHEN CEX.ReceiptType IS NOT NULL THEN RT.Id  ELSE NULL END
  ,0
  ,CT.Id
  ,0.00
  ,0.00

 FROM CommonExternalReceipt_Extract AS CEX
 LEFT JOIN ReceiptTypes RT ON RT.ReceiptTypeName = 'BankStatement'
 LEFT JOIN CashTypes CT ON CT.Type = CEX.CashType
 WHERE CEX.JobStepInstanceId = @JobStepInstanceId  
 AND CEX.IsValid = 1 
 
 END

GO

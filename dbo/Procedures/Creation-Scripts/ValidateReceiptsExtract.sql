SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


  
CREATE PROC [dbo].[ValidateReceiptsExtract]   
(   
 @JobStepInstanceId     BIGINT,   
 @UserId        BIGINT 
)  
AS  
BEGIN  
  
SELECT distinct RE.ReceiptId , CEX.LegalEntityNumber , RE.LegalEntityId
INTO #ReceiptIds
FROM Receipts_Extract RE
JOIN CommonExternalReceipt_Extract CEX ON CEX.Id = RE.ReceiptId
AND CEX.IsValid=1 AND RE.IsValid=1
AND CEX.JobStepInstanceId = @JobStepInstanceId
AND CEX.CreateUnallocatedReceipt = 0



SELECT DISTINCT
		LBC.LegalEntityId
INTO #LBC  
FROM LockBoxDefaultParameterConfigs LBC   
JOIN #ReceiptIds R ON R.LegalEntityId = LBC.LegalEntityId   
AND LBC.IsActive=1
WHERE LBC.CashTypeId IS NOT NULL   



UPDATE Receipts_Extract
SET
IsValid = 0,
Comment = CONCAT(Comment,' - Please define CashType for the legal entity ',R.LegalEntityNumber,' in the LockboxDefaultParameterConfigs table')
FROM Receipts_Extract RE
JOIN #ReceiptIds R ON RE.ReceiptId = R.ReceiptId 
LEFT JOIN #LBC  ON #LBC.LegalEntityId = R.LegalEntityId 
LEFT JOIN ReceiptApplicationReceivableDetails_Extract RARD
ON RARD.ReceiptId = R.ReceiptId 
WHERE  RARD.Id IS NULL AND  #LBC.LegalEntityId IS NULL

INSERT INTO ReceiptFileHandlerErrorMessages(RowId,ErrorMessage,SourceTable,SourceId,JobStepInstanceId,CreatedById,CreatedTime)
SELECT
1 
,CONCAT('Please define CashType for the legal entity ',R.LegalEntityNumber,' in the LockboxDefaultParameterConfigs table') 
,'Receipts_Extract'
,RE.Id 
,@JobStepInstanceId 
,1 
,GETDATE() 
FROM Receipts_Extract RE
JOIN #ReceiptIds R ON RE.ReceiptId = R.ReceiptId 
LEFT JOIN #LBC  ON #LBC.LegalEntityId = R.LegalEntityId 
LEFT JOIN ReceiptApplicationReceivableDetails_Extract RARD
ON RARD.ReceiptId = R.ReceiptId 
WHERE RARD.Id IS NULL AND  #LBC.LegalEntityId IS NULL

			
DROP TABLE #ReceiptIds
DROP TABLE #LBC


END

GO

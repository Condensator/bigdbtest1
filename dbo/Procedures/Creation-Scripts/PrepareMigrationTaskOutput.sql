SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[PrepareMigrationTaskOutput]  
(  
 @JobStepInstanceId  BIGINT   
)
AS  

BEGIN

UPDATE ReceiptMigration_Extract SET IsValid = RE.IsValid,
ErrorMessage = CASE
			       WHEN RE.IsValid = 0
			       THEN ISNULL(RME.ErrorMessage, 'Please check the job logs for error messages')
			       ELSE NULL
			   END
FROM ReceiptMigration_Extract rme
INNER JOIN Receipts_Extract re ON rme.ReceiptMigrationId = re.DumpId
AND rme.JobStepInstanceId = re.JobStepInstanceId
WHERE 
rme.JobStepInstanceId = @JobStepInstanceId


UPDATE stgReceipt
  SET 
      IsMigrated = ISNULL(RME.IsValid, 0)
    , ErrorMessage = RME.ErrorMessage
FROM stgReceipt sRN
     INNER JOIN ReceiptMigration_Extract RME ON sRN.UniqueIdentifier = RME.UniqueIdentifier
WHERE RME.JobStepInstanceId = @JobStepInstanceId;

UPDATE stgReceipt
  SET 
      IsMigrated = ISNULL(RE.IsValid, 0)
    , ErrorMessage = CASE
                         WHEN RE.IsValid = 0
                         THEN ISNULL(RME.ErrorMessage, 'Please check the job logs for error messages')
                         ELSE NULL
                     END
FROM stgReceipt sRN
     INNER JOIN ReceiptMigration_Extract RME ON sRN.UniqueIdentifier = RME.UniqueIdentifier
     INNER JOIN Receipts_Extract RE ON RE.DumpId = RME.ReceiptMigrationId
                                       AND RE.JobStepInstanceId = RME.JobStepInstanceId
WHERE RME.JobStepInstanceId = @JobStepInstanceId;
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ExcludeFileGeneratedReceivableDetails]
(
@TotalProcessingCount BIGINT = 0 OUTPUT,
@JobStepInstanceId BIGINT,
@FileGeneratedStatus NVARCHAR(50),
@FileGeneratedReceivable NVARCHAR(80)
)
AS
BEGIN

;With CTE_ReceivableId
 AS
 (
 SELECT  ReceivableId
 FROM ReversalReceivableDetail_Extract
 WHERE  JobStepInstanceId = @JobStepInstanceId AND (ErrorCode IS NULL OR ErrorCode = '_')
 GROUP BY  ReceivableId
 ),
 CTE_FileGeneratedReceivables 
 As
 (
  SELECT ACH.ReceivableId FROM ACHSchedules ACH
  JOIN  CTE_ReceivableId RId ON ACH.ReceivableId = RId.ReceivableId
  WHERE ACh.IsActive = 1 AND ACH.Status = @FileGeneratedStatus
  AND ACH.PaymentType <>'ReceivableOnly'
 )
 UPDATE RD SET ErrorCode = @FileGeneratedReceivable
 FROM ReversalReceivableDetail_Extract RD 
 JOIN CTE_FileGeneratedReceivables ACHR ON Rd.ReceivableId = ACHR.ReceivableId
 WHERE JobStepInstanceId = @JobStepInstanceId
 AND (ErrorCode IS NULL OR ErrorCode ='_' )


 
;With CTE_ReceivableDetailId
 AS
 (
 SELECT  ReceivableDetailId
 FROM ReversalReceivableDetail_Extract
 WHERE  JobStepInstanceId = @JobStepInstanceId AND (ErrorCode IS NULL OR ErrorCode = '_')
 GROUP BY  ReceivableDetailId
 ),
 CTE_FileGeneratedReceivableDetail
  As
 (
  SELECT OTACHRD.ReceivableDetailId FROM OneTimeACHReceivableDetails OTACHRD
  JOIN  CTE_ReceivableDetailId RDId ON OTACHRD.ReceivableDetailId = RDId.ReceivableDetailId
  JOIN  OneTimeACHSchedules OTS ON OTS.Id = OTACHRD.OneTimeACHScheduleId AND OTS.IsActive = 1
  LEFT JOIN OneTimeACHReceivables OTR ON OTR.ReceivableId = OTS.ReceivableId
  LEFT JOIN OneTimeACHInvoices OTI ON OTI.ReceivableInvoiceId = OTS.ReceivableInvoiceId
  WHERE OTACHRD.IsActive = 1 
  AND (OTR.Status = @FileGeneratedStatus OR OTI.Status = @FileGeneratedStatus)
  AND (OTI.IsActive = 1 OR OTR.IsActive = 1)  
  GROUP BY OTACHRD.ReceivableDetailId
 )
 UPDATE RD SET ErrorCode = @FileGeneratedReceivable
 FROM ReversalReceivableDetail_Extract RD 
 JOIN CTE_FileGeneratedReceivableDetail ACHR ON Rd.ReceivableDetailId = ACHR.ReceivableDetailId
 WHERE JobStepInstanceId = @JobStepInstanceId
 AND (ErrorCode IS NULL OR ErrorCode ='_' )

 IF NOT EXISTS (SELECT 1 FROM ReversalReceivableDetail_Extract WHERE JobStepInstanceId = @JobStepInstanceId AND (ErrorCode IS NULL OR ErrorCode ='_'))
 BEGIN
 SET @TotalProcessingCount = 0
 END
 ELSE 
 BEGIN
 SELECT @TotalProcessingCount = COUNT(DISTINCT ReceivableId) FROM ReversalReceivableDetail_Extract WHERE JobStepInstanceId = @JobStepInstanceId AND (ErrorCode IS NULL OR ErrorCode ='_')
 END

END

GO

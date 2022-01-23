SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[ACHUpdateValidateSettlementDateWithReceivedDateForDSL]
(
 @JobStepInstanceId BIGINT
,@ErrorCode NVARCHAR(4)
,@DSLReceiptClassificationType NVARCHAR(20)
,@PostedStatus NVARCHAR(20)
)
AS
BEGIN

SELECT R.ContractId , MAX(ReceivedDate) ReceivedDate INTO #ReceiptInfoes
FROM Receipts R 
INNER JOIN ACHSchedule_Extract ACHS ON R.ContractId = ACHS.ContractId
WHERE R.Status = @PostedStatus
AND R.ReceiptClassification = @DSLReceiptClassificationType
AND ACHS.JobStepInstanceId = @JobStepInstanceId
AND ACHS.ErrorCode = '_'
GROUP BY R.ContractId

UPDATE ACHS SET ErrorCode = @ErrorCode
FROM ACHSchedule_Extract ACHS
INNER JOIN #ReceiptInfoes R ON ACHS.ContractId = R.ContractId
AND ACHS.JobStepInstanceId = @JobStepInstanceId
AND ACHS.SettlementDate < R.ReceivedDate
AND ACHS.ReceiptClassificationType = @DSLReceiptClassificationType
AND ACHS.ErrorCode = '_'

END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[LockboxFailedRecordFetcher]
(
@JobStepInstanceId BIGINT,
@ReceiptPostingErrorSourceValues_PrePosting NVARCHAR(20),
@ReceiptPostingErrorSourceValues_Posting NVARCHAR(20),
@ReceiptPostingErrorSourceValues_LateFee NVARCHAR(20),
@ReceiptLockBoxErrorCodeValues_LB601 NVARCHAR(50),
@ReceiptLockBoxErrorMessage_LB601 NVARCHAR(4000),
@ReceiptLockBoxErrorCodeValues_LB602 NVARCHAR(50),
@ReceiptLockBoxErrorMessage_LB602 NVARCHAR(4000)
)
AS
BEGIN

SELECT DumpId, SourceOfError
INTO #InvalidFileReceiptInfo
FROM Receipts_Extract
WHERE JobStepInstanceId=@JobStepInstanceId
AND IsValid=0 AND ReceiptBatchId IS NULL
AND IsNewReceipt=1  

INSERT INTO #InvalidFileReceiptInfo
SELECT DumpId, SourceOfError
FROM Receipts_Extract
WHERE JobStepInstanceId=@JobStepInstanceId
AND IsValid=0 AND ReceiptBatchId IS NOT NULL AND SourceOfError IN (@ReceiptPostingErrorSourceValues_PrePosting, @ReceiptPostingErrorSourceValues_LateFee)
AND IsNewReceipt=1 

--Preposting, Posting errors
UPDATE LKBX
SET ErrorCode = @ReceiptLockBoxErrorCodeValues_LB601,
ErrorMessage = @ReceiptLockBoxErrorMessage_LB601,
IsValid = 0
FROM #InvalidFileReceiptInfo RE
JOIN ReceiptPostByLockBox_Extract LKBX ON RE.DumpId = LKBX.Id
WHERE LKBX.IsValid = 1 AND SourceOfError IN (@ReceiptPostingErrorSourceValues_PrePosting, @ReceiptPostingErrorSourceValues_Posting)

--Late fee errors
UPDATE LKBX
SET ErrorCode = @ReceiptLockBoxErrorCodeValues_LB602,
ErrorMessage = @ReceiptLockBoxErrorMessage_LB602,
IsValid = 0
FROM #InvalidFileReceiptInfo RE
JOIN ReceiptPostByLockBox_Extract LKBX ON RE.DumpId = LKBX.Id
WHERE LKBX.IsValid = 1 AND SourceOfError = @ReceiptPostingErrorSourceValues_LateFee

SELECT
LockBoxString AS LockboxLine,
ErrorMessage AS ErrorMessages,
FileName
FROM ReceiptPostByLockBox_Extract
WHERE
JobStepInstanceId = @JobStepInstanceId AND
IsValid = 0
END

GO

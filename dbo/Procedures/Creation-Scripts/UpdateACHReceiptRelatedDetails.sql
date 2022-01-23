SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[UpdateACHReceiptRelatedDetails]
(@PendingReceiptStatus             NVARCHAR(10),
 @PostedReceiptStatus              NVARCHAR(10),
 @CompletedACHScheduleStatus       NVARCHAR(20),
 @UpdatedById                      BIGINT,
 @UpdatedTime                      DATETIMEOFFSET,
 @JobStepInstanceId                BIGINT
)
AS
  BEGIN
    SET NOCOUNT ON;

    SELECT R.Status,
           R.ReceiptId,
           R.ReceiptApplicationId,
           AR.InActivateBankAccountId,
           AR.IsOneTimeACH,
           AR.Id AS ACHReceiptId,
		   AR.OneTimeACHId
    INTO #ReceiptDetails
    FROM dbo.Receipts_Extract AS R
    INNER JOIN dbo.ACHReceipts AS AR ON R.ACHReceiptId = AR.Id
    WHERE R.JobStepInstanceId = @JobStepInstanceId
          AND R.IsValid = 1 AND R.ReceiptId > 0;

    UPDATE dbo.ACHReceipts
      SET
          ACHReceipts.ReceiptId = R.ReceiptId,
          ACHReceipts.ReceiptApplicationId = R.ReceiptApplicationId,
          UpdatedById = @UpdatedById,
          UpdatedTime = @UpdatedTime,
          Status = R.Status
    FROM #ReceiptDetails R
    INNER JOIN dbo.ACHReceipts AR ON R.ACHReceiptId = AR.Id;


	SELECT R.ReceiptId,ARD.Id INTO #ACHRunUpdates
	FROM #ReceiptDetails R
    INNER JOIN dbo.ACHRunDetails ARD ON R.ACHReceiptId = ARD.EntityId
	AND ARD.IsPending = 1;

    UPDATE dbo.ACHRunDetails
      SET
          ACHRunDetails.EntityId = ReceiptId,
          ACHRunDetails.IsPending = CAST(0 AS BIT),
          UpdatedById = @UpdatedById,
          UpdatedTime = @UpdatedTime
    FROM #ACHRunUpdates
	WHERE ACHRunDetails.Id = #ACHRunUpdates.Id;

    UPDATE dbo.BankAccounts
      SET
          IsActive = 0,
          UpdatedById = @UpdatedById,
          UpdatedTime = @UpdatedTime
    FROM #ReceiptDetails R
    INNER JOIN dbo.BankAccounts B ON B.Id = R.InActivateBankAccountId
    WHERE R.Status = @PostedReceiptStatus;

    SELECT R.IsOneTimeACH,
           RARD.ScheduleId,
           @CompletedACHScheduleStatus AS ScheduleStatus,
		   CASE WHEN RARD.ACHReceiptId IS NULL AND OneTimeACHId IS NOT NULL THEN OneTimeACHId ELSE NULL END AS OneTimeACHId
    FROM #ReceiptDetails AS R
    LEFT JOIN dbo.ACHReceiptApplicationReceivableDetails AS RARD ON R.ACHReceiptId = RARD.ACHReceiptId
    WHERE R.Status = @PostedReceiptStatus
	GROUP BY R.IsOneTimeACH,RARD.ScheduleId,OneTimeACHId,RARD.ACHReceiptId;
	END;

GO

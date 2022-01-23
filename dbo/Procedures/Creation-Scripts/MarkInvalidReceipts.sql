SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[MarkInvalidReceipts]
(
@JobStepInstanceId		BIGINT,
@ReceiptIds IdCollection READONLY,
@CurrentUserId			BIGINT,
@CurrentTime			DATETIMEOFFSET,
@ReceiptPostingErrorSource NVARCHAR(20)
)
AS
BEGIN
SET NOCOUNT ON;
UPDATE Receipts_Extract
SET Receipts_Extract.IsValid = 0,
Receipts_Extract.SourceOfError = @ReceiptPostingErrorSource,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
FROM Receipts_Extract
JOIN @ReceiptIds RIds on Receipts_Extract.ReceiptId = RIds.Id
WHERE JobStepInstanceId = @JobStepInstanceId
END

GO

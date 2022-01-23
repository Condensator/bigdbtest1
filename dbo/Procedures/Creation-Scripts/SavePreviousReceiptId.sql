SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[SavePreviousReceiptId]
(
@JobStepInstanceId		BIGINT,
@CurrentUserId			BIGINT,
@CurrentTime			DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
UPDATE Receipts_Extract SET
BeforePostingReceiptId = ReceiptId,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime  where
jobstepinstanceid = @JobStepInstanceId
END

GO

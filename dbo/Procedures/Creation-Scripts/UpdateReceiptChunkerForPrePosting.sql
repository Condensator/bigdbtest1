SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateReceiptChunkerForPrePosting]
(
@RangeChunkerId		BIGINT,
@JobStepInstanceId	BIGINT,
@BatchStatus		NVARCHAR(20),
@EndTime			DATETIMEOFFSET,
@CurrentUserId		BIGINT,
@CurrentTime		DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
UPDATE ReceiptChunkerForPosting_Extract
SET
PrePostingBatchStatus = @BatchStatus,
PrePostingEndTime = @EndTime,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
WHERE Id = @RangeChunkerId
END

GO

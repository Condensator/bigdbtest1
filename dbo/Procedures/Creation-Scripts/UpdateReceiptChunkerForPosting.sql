SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateReceiptChunkerForPosting]
(
@DataChunkerId		BIGINT,
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
PostingBatchStatus = @BatchStatus,
PostingEndTime = @EndTime,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
WHERE Id = @DataChunkerId
END

GO

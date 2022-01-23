SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[UpdateChunkInfoForNonAccrual]
(
	@CurrentUserId					BIGINT,
	@CurrentTime					DATETIMEOFFSET,
	@ChunkStatus					NVARCHAR(50),
	@FailedContractIds				IdCollection READONLY,
	@ChunkId						BIGINT
)
AS 
BEGIN
	SET NOCOUNT ON;

	UPDATE NonAccrualChunks_Extract
	SET ChunkStatus = @ChunkStatus,
		EndTime = @CurrentTime,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	WHERE Id = @ChunkId;

	SELECT Id INTO #FailedIds
	FROM @FailedContractIds;

	UPDATE N
	SET IsFailed = 1
	FROM NonAccrualContractDetails_Extract N
	INNER JOIN #FailedIds F ON N.ContractId = F.Id
	WHERE N.ChunkId = @ChunkId

END

GO

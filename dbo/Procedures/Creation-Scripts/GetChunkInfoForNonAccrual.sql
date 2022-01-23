SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[GetChunkInfoForNonAccrual]
(
	@JobStepInstanceId				BIGINT,
	@TaskChunkServiceInstanceId		BIGINT = NULL,
	@CurrentUserId					BIGINT,
	@CurrentTime					DATETIMEOFFSET,
	@ChunkStatus_Processing			NVARCHAR(50),
	@ChunkStatus_New				NVARCHAR(50),
	@ChunkId						BIGINT OUTPUT,
	@ChunkNumber					BIGINT OUTPUT
)
AS 
BEGIN
	SET NOCOUNT ON;

	UPDATE TOP(1) NonAccrualChunks_Extract
	SET ChunkStatus = @ChunkStatus_Processing,
		TaskChunkServiceInstanceId = @TaskChunkServiceInstanceId,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime,
		StartTime = @CurrentTime,
		@ChunkId = Id,
		@ChunkNumber = ChunkNumber
	WHERE JobStepInstanceId = @JobStepInstanceId AND ChunkStatus = @ChunkStatus_New;
END

GO

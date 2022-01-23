SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[GetChunkInfoForInvoiceGeneration]
(
	@JobStepInstanceId				BIGINT,
	@SourceJobStepInstanceId		BIGINT = NULL,
	@TaskChunkServiceInstanceId		BIGINT = NULL,
	@CurrentUserId					BIGINT,
	@CurrentTime					DATETIMEOFFSET,
	@InvoiceChunkStatus_Processing	NVARCHAR(50),
	@InvoiceChunkStatus_New			NVARCHAR(50)
)
AS 
BEGIN
	SET NOCOUNT ON;

	DECLARE @ChunkId BIGINT 

	UPDATE TOP(1) InvoiceChunkStatus_Extract
	SET InvoicingStatus = @InvoiceChunkStatus_Processing,
		TaskChunkServiceInstanceId = @TaskChunkServiceInstanceId,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime,
		@ChunkId = Id
	WHERE RunJobStepInstanceId = @JobStepInstanceId AND InvoicingStatus = @InvoiceChunkStatus_New;

	SELECT 
		Id, 
		RunJobStepInstanceId AS JobStepInstanceId, 
		ISNULL(@SourceJobStepInstanceId, @JobStepInstanceId) AS SourceJobStepInstanceId,
		TaskChunkServiceInstanceId, 
		ChunkNumber, 
		@CurrentUserId AS UserId, 
		InvoicingStatus, 
		IsReceivableInvoiceProcessed, 
		IsStatementInvoiceProcessed, 
		IsExtractionProcessed, 
		IsFileGenerated
	FROM InvoiceChunkStatus_Extract WHERE Id = @ChunkId
END

GO

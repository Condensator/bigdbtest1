SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[ExtractInvoiceDetailForGLPostingProcessor] 
(
	@JobStepInstanceId BIGINT,
	@ChunkNumber BIGINT,
	@CreatedById BIGINT,
	@CreatedTime DATETIMEOFFSET,
	@RunDate DATE
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @False AS BIT = CONVERT(BIT, 0)

	INSERT INTO ReceivablesToGlPosting_Extract
	([ReceivableId],[IsReceivableGLPosted],[ReceivableTaxId],[IsTaxGLPosted],[InvoiceRunDate],[ReceivableTaxType],[JobStepInstanceId],[IsGLProcessed],[CreatedById],[CreatedTime])
	SELECT 
		ReceivableId = IRD.ReceivableId,
		IsReceivableGLPosted = R.IsGLPosted,
		ReceivableTaxId = RT.Id, 
		IsTaxGLPosted = RT.IsGLPosted,
		InvoiceRunDate = @RunDate,
		ReceivableTaxType = IRD.ReceivableTaxType,
		JobStepInstanceId = IRD.JobStepInstanceId,
		IsGLProcessed = @False,
		@CreatedById,
		@CreatedTime
	FROM InvoiceChunkDetails_Extract ICD 
	JOIN InvoiceReceivableDetails_Extract IRD ON ICD.BillToId = IRD.BillToId
	JOIN Receivables R ON IRD.ReceivableId = R.Id
	JOIN ReceivableTaxes RT ON R.Id = RT.ReceivableId
	WHERE IRD.IsActive = 1
	AND (R.IsGLPosted != 1 OR RT.IsGLPosted != 1)
	AND IRD.JobStepInstanceId = @JobStepInstanceId 
	AND ChunkNumber= @ChunkNumber
	GROUP BY IRD.ReceivableId, RT.Id, R.IsGLPosted, RT.IsGLPosted, IRD.InvoiceDueDate, IRD.ReceivableTaxType, IRD.JobStepInstanceId
END

GO

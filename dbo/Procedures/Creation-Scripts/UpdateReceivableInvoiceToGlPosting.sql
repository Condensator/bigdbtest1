SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[UpdateReceivableInvoiceToGlPosting]
(
	@ReceivableIds ReceivableIdTemp READONLY,
	@UpdatedId BIGINT,
	@UpdatedTime DATETIMEOFFSET,
	@PostReceivable BIT,
	@PostReceivableTax BIT,
	@IsPostGLForReceivableAndReceivableTax BIT
)
AS
BEGIN
SET NOCOUNT ON;

DECLARE @True BIT = 1
DECLARE @False BIT = 0

IF(@IsPostGLForReceivableAndReceivableTax = 1)
BEGIN
	UPDATE ReceivablesToGlPosting_Extract
	SET IsGLProcessed =  @True, IsReceivableGLPosted = @True, IsTaxGLPosted = @True, UpdatedById = @UpdatedId, UpdatedTime = @UpdatedTime
	FROM ReceivablesToGlPosting_Extract
	JOIN @ReceivableIds ReceivableDetail ON ReceivablesToGlPosting_Extract.ReceivableId = ReceivableDetail.Id
END

IF(@PostReceivableTax = 1 AND @PostReceivable = 0)
BEGIN
	UPDATE ReceivablesToGlPosting_Extract
	SET IsTaxGLPosted = @True, UpdatedById = @UpdatedId, UpdatedTime = @UpdatedTime
	FROM ReceivablesToGlPosting_Extract
	JOIN @ReceivableIds ReceivableDetail ON ReceivablesToGlPosting_Extract.ReceivableId = ReceivableDetail.Id

	UPDATE ReceivablesToGlPosting_Extract
	SET IsGLProcessed =  @True
	FROM ReceivablesToGlPosting_Extract
	JOIN @ReceivableIds ReceivableDetail ON ReceivablesToGlPosting_Extract.ReceivableId = ReceivableDetail.Id
	WHERE ReceivablesToGlPosting_Extract.IsReceivableGLPosted = 1 

END

IF(@PostReceivable = 1 AND @PostReceivableTax = 0)
BEGIN
	UPDATE ReceivablesToGlPosting_Extract
	SET IsReceivableGLPosted = @True, UpdatedById = @UpdatedId, UpdatedTime = @UpdatedTime
	FROM ReceivablesToGlPosting_Extract
	JOIN @ReceivableIds ReceivableDetail ON ReceivablesToGlPosting_Extract.ReceivableId = ReceivableDetail.Id

	UPDATE ReceivablesToGlPosting_Extract
	SET IsGLProcessed =  @True
	FROM ReceivablesToGlPosting_Extract
	JOIN @ReceivableIds ReceivableDetail ON ReceivablesToGlPosting_Extract.ReceivableId = ReceivableDetail.Id
	WHERE ReceivablesToGlPosting_Extract.IsTaxGLPosted = 1 

END

SET NOCOUNT OFF;
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateReceivableTaxGLForAdjustment]
(	
	@ReceivableTaxIds ReceivableTaxIdInput READONLY,
	@UpdatedById BIGINT,
	@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;

	UPDATE ReceivableTaxes
	SET IsGLPosted=0, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
	FROM ReceivableTaxes RecTaxes
	JOIN @ReceivableTaxIds RecTaxId ON RecTaxes.Id = RecTaxId.ReceivableTaxId
	
	UPDATE ReceivableTaxDetails
	SET IsGLPosted=0, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
	FROM ReceivableTaxDetails RecTaxDetails
	JOIN @ReceivableTaxIds RecTaxId ON RecTaxDetails.ReceivableTaxId = RecTaxId.ReceivableTaxId
END

GO

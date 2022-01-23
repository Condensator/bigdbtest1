SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[InactivateReceivablesForAdjustment]
(
	@ReceivableIds ReceivableIdInput READONLY,
	@UpdatedById BIGINT,
	@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;

	UPDATE Receivables
			SET IsActive =0, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime, IsGLPosted = 0
		FROM Receivables Rec
			JOIN @ReceivableIds RecId ON Rec.Id = RecId.ReceivableId

	UPDATE ReceivableDetails
			SET IsActive=0, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
		FROM ReceivableDetails RecDetails
			JOIN @ReceivableIds RecId ON RecDetails.ReceivableId = RecId.ReceivableId


	UPDATE ReceivableWithholdingTaxDetails
			SET IsActive=0, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
		FROM ReceivableWithholdingTaxDetails WHTDetail
			JOIN @ReceivableIds RecId ON WHTDetail.ReceivableId = RecId.ReceivableId

	UPDATE ReceivableDetailsWithholdingTaxDetails
			SET IsActive=0, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
		FROM ReceivableDetailsWithholdingTaxDetails RecDetailWHT
			JOIN ReceivableWithholdingTaxDetails WHTDetail ON RecDetailWHT.ReceivableWithholdingTaxDetailId = WHTDetail.Id
			JOIN @ReceivableIds RecId ON WHTDetail.ReceivableId = RecId.ReceivableId

END

GO

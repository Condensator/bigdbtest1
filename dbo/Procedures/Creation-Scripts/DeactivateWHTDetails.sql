SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[DeactivateWHTDetails]
(
@ReceivableIds WHTReceivableIds READONLY,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;

UPDATE ReceivableWithholdingTaxDetails
SET IsActive =0, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
FROM ReceivableWithholdingTaxDetails
JOIN @ReceivableIds RID  ON ReceivableWithholdingTaxDetails.ReceivableId = RID.ReceivableId
SET NOCOUNT OFF;

UPDATE ReceivableDetailsWithholdingTaxDetails
SET IsActive =0, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
FROM ReceivableDetailsWithholdingTaxDetails
JOIN ReceivableDetails ON ReceivableDetailsWithholdingTaxDetails.ReceivableDetailId = ReceivableDetails.Id
JOIN @ReceivableIds RID ON ReceivableDetails.ReceivableId = RID.ReceivableId
SET NOCOUNT OFF;
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetReceiptRentSharingDetailsForPosting]
(
@JobStepInstanceId   BIGINT,
@ReceiptIds IdCollection READONLY
)
AS
BEGIN
SET NOCOUNT ON;
SELECT R.Id ReceiptId,
RIR.ReceivableId,
RIR.RentSharingPercentage,
RIR.VendorId,
RIR.RemitToId,
RIR.PayableCodeId,
RIR.WithHoldingTaxRate,
RIR.SourceType,
RIR.PaidPayableAmount
FROM @ReceiptIds R
INNER JOIN ReceiptRentSharingDetails_Extract RIR ON R.Id = RIR.ReceiptId
WHERE RIR.JobStepInstanceId = @JobStepInstanceId
END

GO

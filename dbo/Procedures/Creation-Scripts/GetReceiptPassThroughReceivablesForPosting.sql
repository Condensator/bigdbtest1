SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetReceiptPassThroughReceivablesForPosting](
@ReceiptIds ReceiptIdModel READONLY,
@JobStepInstanceId	BIGINT
)
AS
BEGIN
SET NOCOUNT ON;
SELECT Id INTO #ReceiptIds FROM @ReceiptIds
SELECT
RPR.[ReceivableId],
RPR.[PassThroughPayableDueDate],
RPR.[TotalPayableAmount],
RPR.[PaidPayableAmount],
RPR.[VendorId],
RPR.[PayableRemitToId],
RPR.[PayableCodeId],
RPR.[SourceId],
RPR.[SourceTable],
RPR.[PassThroughPercent],
RPR.WithholdingTaxRate
FROM (SELECT
RARD.ReceivableId [Id]
FROM #ReceiptIds ReceiptIds
JOIN ReceiptReceivableDetails_Extract RARD ON RARD.JobStepInstanceId = @JobStepInstanceId AND ReceiptIds.Id = RARD.ReceiptId
GROUP BY RARD.ReceivableId)
AS ReceivableIds
JOIN ReceiptPassThroughReceivables_Extract RPR ON RPR.JobStepInstanceId = @JobStepInstanceId AND RPR.ReceivableId = ReceivableIds.Id
DROP TABLE #ReceiptIds
END

GO

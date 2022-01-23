SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetReceiptSyndicatedReceivablesForPosting](
@ReceiptIds ReceiptIdModel READONLY,
@JobStepInstanceId	BIGINT
)
AS
BEGIN
SET NOCOUNT ON;
SELECT Id INTO #ReceiptIds FROM @ReceiptIds
SELECT
RSD.[ReceivableId]
,RSD.[UtilizedScrapeAmount]
,RSD.[ReceivableRemitToId]
,RSD.[ScrapeFactor]
,RSD.[ScrapeReceivableCodeId]
,RSD.[RentalProceedsPayableCodeId]
,RSD.[RentalProceedsPayableCodeName]
,RSD.[FunderBillToId]
,RSD.[FunderLocationId]
,RSD.[FunderRemitToId]
,RSD.[TaxRemitFunderId]
,RSD.[TaxRemitToId]
,ISNULL(RSD.[InvoiceReceivableGroupingOption],'_') [InvoiceReceivableGroupingOption]
,RSD.WithholdingTaxRate
FROM (SELECT
RARD.ReceivableId [Id]
FROM #ReceiptIds ReceiptIds
JOIN ReceiptReceivableDetails_Extract RARD ON RARD.JobStepInstanceId = @JobStepInstanceId AND ReceiptIds.Id = RARD.ReceiptId
GROUP BY RARD.ReceivableId)
AS ReceivableIds
JOIN ReceiptSyndicatedReceivables_Extract RSD ON RSD.JobStepInstanceId = @JobStepInstanceId AND ReceivableIds.Id = RSD.ReceivableId
DROP TABLE #ReceiptIds
END

GO

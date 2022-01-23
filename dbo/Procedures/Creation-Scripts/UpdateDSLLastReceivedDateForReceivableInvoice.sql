SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateDSLLastReceivedDateForReceivableInvoice]
(
@ReceiptId BIGINT,
@CurrentUserId BIGINT,
@IsReversal BIT,
@CurrentTime DATETIMEOFFSET,
@ReceivedDate DATE
)
AS
BEGIN
SET NOCOUNT ON
SELECT InvoiceId AS ReceivableInvoiceId
INTO #TempReceivableInvoice
FROM
DSLReceiptHistories
WHERE
DSLReceiptHistories.ReceiptId = @ReceiptId
AND DSLReceiptHistories.InvoiceId IS NOT NULL
IF(@IsReversal=1)
BEGIN
UPDATE
ReceivableInvoices
SET
LastReceivedDate = NULL, UpdatedById = @CurrentUserId, UpdatedTime = @CurrentTime
FROM ReceivableInvoices
JOIN #TempReceivableInvoice ON #TempReceivableInvoice.ReceivableInvoiceId = ReceivableInvoices.Id
END
UPDATE
ReceivableInvoices
SET
LastReceivedDate = LastReceivedDateDetails.LastReceivedDate, UpdatedById = @CurrentUserId, UpdatedTime = @CurrentTime
FROM ReceivableInvoices
JOIN
(SELECT DSLReceiptHistories.InvoiceId AS ReceivableInvoiceId,
MAX(DSLReceiptHistories.ReceivedDate) AS LastReceivedDate
FROM DSLReceiptHistories
JOIN #TempReceivableInvoice ON #TempReceivableInvoice.ReceivableInvoiceId = DSLReceiptHistories.InvoiceId
WHERE DSLReceiptHistories.IsActive = 1
AND DSLReceiptHistories.AmountPosted_Amount != 0
GROUP BY DSLReceiptHistories.InvoiceId
) AS LastReceivedDateDetails ON LastReceivedDateDetails.ReceivableInvoiceId = ReceivableInvoices.Id
DROP TABLE #TempReceivableInvoice
END

GO

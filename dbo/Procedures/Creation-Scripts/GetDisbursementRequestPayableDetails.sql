SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetDisbursementRequestPayableDetails]
(
@PayableInvoiceIds NVARCHAR(MAX),
@PayableInvoiceEntityType NVARCHAR(40),
@PayableApprovedStatus NVARCHAR(40),
@PayablePartiallyApprovedStatus NVARCHAR(40),
@DRCompletedStatus NVARCHAR(40),
@LeaseFinanceId BIGINT,
@PayableSourceTablePayableInvoiceAsset NVARCHAR(40)
)
AS
BEGIN
SET NOCOUNT ON
SELECT PayableInvoiceId = ID
INTO #SelectedPayableInvoices
FROM ConvertCSVToBigIntTable(@PayableInvoiceIds, ',')
CREATE INDEX IX_PayableInvoiceId ON #SelectedPayableInvoices (PayableInvoiceId);
SELECT
P.EntityId AS EntityId,
P.SourceTable AS SourceTable,
P.SourceId AS SourceId,
SUM(DRPayees.PaidAmount_Amount) AS PaidAmount
FROM
Payables P
JOIN #SelectedPayableInvoices SP ON P.EntityId = SP.PayableInvoiceId
JOIN DisbursementRequestPayables DRP ON P.Id = DRP.PayableId
JOIN DisbursementRequests DR ON DRP.DisbursementRequestId = DR.Id
JOIN DisbursementRequestPayees DRPayees ON DRP.Id = DRPayees.DisbursementRequestPayableId
WHERE
P.EntityType = @PayableInvoiceEntityType
AND P.Status in (@PayableApprovedStatus,@PayablePartiallyApprovedStatus)
AND DRP.IsActive = 1
AND DRPayees.IsActive = 1
AND DR.Status = @DRCompletedStatus
GROUP BY DRP.PayableId,
P.EntityId,
P.SourceTable,
P.SourceId
END

GO

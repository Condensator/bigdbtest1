SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[UpdateOriginalInvoiceNumberForVATReassessment]
(
	@JobStepInstanceId BIGINT
)
AS
BEGIN
SET NOCOUNT ON;

SELECT RI.Id, ARI.Number 
INTO #InvoicesToUpdate 
FROM ReceivableInvoices RI
JOIN ReceivableInvoiceDetails RID ON RI.Id = RID.ReceivableInvoiceId
JOIN ReceivableDetails RD ON RID.ReceivableDetailId = RD.Id
JOIN ReceivableInvoiceDetails ARD ON RD.AdjustmentBasisReceivableDetailId = ARD.ReceivableDetailId
JOIN Receivableinvoices ARI ON ARI.Id = ARD.ReceivableInvoiceId
WHERE RI.JobStepInstanceId = @JobStepInstanceId AND RI.IsActive = 1 AND ARI.IsActive = 1 AND RI.IsDummy = 0 AND ARI.IsDummy = 0
GROUP BY RI.Id, ARI.Number

UPDATE RI SET OriginalInvoiceNumber = Inv.Number FROM ReceivableInvoices RI JOIN #InvoicesToUpdate Inv ON RI.Id = Inv.Id

END

GO

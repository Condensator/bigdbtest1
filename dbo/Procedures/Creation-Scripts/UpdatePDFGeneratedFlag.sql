SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdatePDFGeneratedFlag]
(
@InvoiceIds NVARCHAR(MAX),
@FailedInvoices NVARCHAR(MAX),
@JobStepInstanceId BIGINT,
@UpdatedById BIGINT,
@UpdatedByTime DATETIMEOFFSET
) WITH RECOMPILE
AS
BEGIN
SET NOCOUNT ON;
CREATE TABLE #ReceivableInvoiceIds
(
InvoiceIds BIGINT
);
INSERT INTO #ReceivableInvoiceIds(InvoiceIds)
SELECT Id FROM dbo.ConvertCSVToBigIntTable(@InvoiceIds,',');
IF @JobStepInstanceId != 0
BEGIN
UPDATE ReceivableInvoices
SET IsPdfGenerated = 1,
UpdatedTime = @UpdatedByTime,
UpdatedById = @UpdatedById
Where JobStepInstanceId = @JobStepInstanceId
AND IsPdfGenerated = 0
AND IsActive = 1 AND ((InvoiceAmount_Amount + InvoiceTaxAmount_Amount) > 0 OR (Balance_Amount + TaxBalance_Amount) > 0)
AND Id IN (SELECT InvoiceIds FROM #ReceivableInvoiceIds)
AND InvoicePreference != 'SuppressGeneration'
END
ELSE
BEGIN
UPDATE ReceivableInvoices
SET IsPdfGenerated = 1,
UpdatedTime = @UpdatedByTime,
UpdatedById = @UpdatedById
Where IsPdfGenerated = 0
AND IsActive = 1 AND ((InvoiceAmount_Amount + InvoiceTaxAmount_Amount) > 0 OR (Balance_Amount + TaxBalance_Amount) > 0)
AND Id IN (SELECT InvoiceIds FROM #ReceivableInvoiceIds)
AND InvoicePreference != 'SuppressGeneration'
END
DROP TABLE #ReceivableInvoiceIds
END

GO

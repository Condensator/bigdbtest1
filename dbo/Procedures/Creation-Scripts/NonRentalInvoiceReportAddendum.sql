SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[NonRentalInvoiceReportAddendum]
(
@InvoiceId BIGINT
) WITH RECOMPILE
AS
BEGIN
SET NOCOUNT ON;
--DECLARE @InvoiceId bigint = 747378
DECLARE @ReceivableCategory NVARCHAR(20);
SELECT @ReceivableCategory = Name FROM ReceivableInvoices
JOIN ReceivableCategories ON ReceivableInvoices.ReceivableCategoryId = ReceivableCategories.Id
WHERE ReceivableInvoices.Id = @InvoiceId
CREATE TABLE #AssetDetails(InvoiceId BIGINT,AssetId BIGINT,AssetReceivableAmount DECIMAL(16,2),AssetAddressLine1 NVARCHAR(50)
,AssetAddressLine2 NVARCHAR(50),AssetCity NVARCHAR(40),AssetDivision NVARCHAR(40),AssetState NVARCHAR(5),AssetPostalCode NVARCHAR(12)
,AssetCountry NVARCHAR(5), PropertyTaxDescription NVARCHAR(200))
CREATE TABLE #LateFeeDetails(InvoiceId BIGINT,ReceivableDetailId BIGINT,OriginalInvoiceNumber NVARCHAR(40),OriginalInvoiceDueDate DATE)
INSERT INTO #AssetDetails
SELECT DISTINCT
InvoiceExtractCustomerDetails.InvoiceId,
InvoiceExtractReceivableDetails.AssetId,
ReceivableAmount_Amount,
AssetAddressLine1 'AssetAddressLine1',
AssetAddressLine2 'AssetAddressLine2',
AssetCity 'AssetCity',
AssetDivision 'AssetDivision',
AssetState 'AssetState',
AssetPostalCode 'AssetPostalCode',
AssetCountry,
PropertyTaxes.TaxDistrict + ' Tax Year:' + CONVERT(NVARCHAR(MAX),PropertyTaxes.ReportingYear)
+ ' ' + ISNULL(ReceivableCodes.DefaultInvoiceComment,'') [PropertyTaxDescription]
FROM InvoiceExtractCustomerDetails
JOIN InvoiceExtractReceivableDetails ON
InvoiceExtractCustomerDetails.InvoiceId = InvoiceExtractReceivableDetails.InvoiceId
AND InvoiceExtractCustomerDetails.InvoiceId = @InvoiceId
JOIN ReceivableDetails ON
InvoiceExtractReceivableDetails.ReceivableDetailId = ReceivableDetails.id
JOIN Receivables ON
ReceivableDetails.ReceivableId = Receivables.Id
JOIN ReceivableCodes ON
ReceivableCodes.Id = InvoiceExtractReceivableDetails.ReceivableCodeId
LEFT JOIN PropertyTaxes ON
PropertyTaxes.PropTaxReceivableId = Receivables.Id
INSERT INTO #LateFeeDetails
SELECT
receivable.InvoiceId
,receivable.ReceivableDetailId
,OriginalInvoice.Number [OriginalInvoiceNumber]
,OriginalInvoice.DueDate [OriginalInvoiceDueDate]
--,OriginalInvoice.InvoiceRunDate [OriginalInvoiceDate]
--,receivable.ContractPurchaseOrderNumber
--,receivable.AdditionalComments
--,receivable.AdditionalInvoiceCommentBeginDate
--,receivable.AdditionalInvoiceCommentEndDate
--,receivable.SequenceNumber
FROM InvoiceExtractReceivableDetails receivable
INNER JOIN dbo.ReceivableDetails rd ON receivable.ReceivableDetailId = rd.Id
INNER JOIN dbo.Receivables r ON rd.ReceivableId = r.Id
INNER JOIN dbo.LateFeeReceivables ON r.SourceId = LateFeeReceivables.Id AND r.SourceTable = 'LateFee'
LEFT JOIN dbo.ReceivableInvoices [OriginalInvoice] ON LateFeeReceivables.ReceivableInvoiceId = OriginalInvoice.Id
WHERE receivable.InvoiceId = @InvoiceId
AND receivable.ReceivableAmount_Amount > 0
SELECT
--DISTINCT
InvoiceNumber,
InvoiceType,
InvoiceNumberLabel,
InvoiceRunDateLabel,
InvoiceRunDate,
DueDate,
SequenceNumber,
CustomerNumber,
InvoiceExtractReceivableDetails.AssetId,
AssetSerialNumber,
AssetDescription,
AssetPurchaseOrderNumber 'CustomerPurchaseOrderNumber',
ISNULL(InvoiceExtractReceivableDetails.ReceivableAmount_Amount * InvoiceExtractReceivableDetails.ExchangeRate,0) 'Rent',
ISNULL(InvoiceExtractReceivableDetails.TaxAmount_Amount * InvoiceExtractReceivableDetails.ExchangeRate,0) 'SalesTax',
ISNULL(InvoiceExtractReceivableDetails.ReceivableAmount_Amount * InvoiceExtractReceivableDetails.ExchangeRate,0)
+ ISNULL(InvoiceExtractReceivableDetails.TaxAmount_Amount * InvoiceExtractReceivableDetails.ExchangeRate,0) 'AssetTotal',
'SequenceNumber' AssetGroupByOption,
dbo.GetAddressFormat(id.AssetAddressLine1, id.AssetAddressLine2, id.AssetCity, id.AssetState, NULL) + ' ' + ISNULL(id.AssetPostalCode,'') 'Code',
#LateFeeDetails.OriginalInvoiceNumber OriginalInvoiceNumber,
#LateFeeDetails.OriginalInvoiceDueDate OriginalInvoiceDueDate,
id.PropertyTaxDescription PropertyTaxDescription,
CASE WHEN @ReceivableCategory = 'PropertyTax' THEN 'PT'
WHEN @ReceivableCategory = 'LateCharge' THEN 'LC'
ELSE 'NT'
END ReceivableCategory
FROM InvoiceExtractCustomerDetails iec
JOIN InvoiceExtractReceivableDetails ON
iec.InvoiceId = InvoiceExtractReceivableDetails.InvoiceId
LEFT JOIN #AssetDetails id ON
InvoiceExtractReceivableDetails.InvoiceId = id.InvoiceId
AND InvoiceExtractReceivableDetails.AssetId = id.AssetId
LEFT JOIN #LateFeeDetails ON
InvoiceExtractReceivableDetails.InvoiceId = #LateFeeDetails.InvoiceId
AND InvoiceExtractReceivableDetails.ReceivableDetailId = #LateFeeDetails.ReceivableDetailId
WHERE iec.InvoiceId = @InvoiceId
DROP TABLE #AssetDetails
DROP TABLE #LateFeeDetails
END

GO

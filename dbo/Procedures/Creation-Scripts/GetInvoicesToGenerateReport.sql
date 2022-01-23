SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetInvoicesToGenerateReport]
(
@JobStepInstanceId BIGINT,
@IsBillNegativeandZeroReceivables BIT
)
AS
SET NOCOUNT ON;
BEGIN
;WITH CTE_IsCAD AS
(
SELECT ri.Id [InvoiceId]
,CASE WHEN MIN(c.LongName) = 'Canada' THEN CAST(1 AS BIT)
ELSE CAST(0 AS BIT)
END [IsCanada]
FROM
ReceivableInvoices ri
JOIN ReceivableInvoiceDetails rid ON ri.Id = rid.ReceivableInvoiceId
AND rid.IsActive = 1
JOIN ReceivableTaxDetails rtd ON rtd.ReceivableDetailId = rid.ReceivableDetailId
AND rtd.IsActive = 1
JOIN Locations l ON l.Id = rtd.LocationId
JOIN States s ON l.StateId = s.Id
JOIN Countries c ON s.CountryId = c.Id
WHERE (ri.JobStepInstanceId = @JobStepInstanceId Or @JobStepInstanceId = 0)
AND ri.IsActive = 1 AND ri.IsPdfGenerated = 0
AND ri.InvoicePreference IN ('GenerateAndDeliver','SuppressDelivery')
AND ((@IsBillNegativeandZeroReceivables = 0 AND ((ri.InvoiceAmount_Amount + ri.InvoiceTaxAmount_Amount) > 0 OR (ri.Balance_Amount + ri.TaxBalance_Amount) > 0))
OR @IsBillNegativeandZeroReceivables = 1)
GROUP BY ri.Id
)
SELECT DISTINCT
ri.Id [InvoiceId],
ri.Number [InvoiceNumber],
bt.Id [BillToId],
ri.CustomerId [CustomerId],
ri.RemitToId [RemitId],
ri.DueDate [DueDate],
ri.IsPrivateLabel [IsPrivateLabel],
ri.ReceivableCategoryId [ReceivableCategoryId],
ri.ReportFormatId [ReportFormatId],
ri.IsACH [IsACH],
cur.Id [CurrencyId],
ri.LegalEntityId [LegalEntityId],
ISNULL(btif.InvoiceOutputFormat,'PDF') [InvoiceOutputFormat],
ift.ReportName,
ri.InvoicePreference [InvoicePreference],
bt.GenerateInvoiceAddendum [GenerateInvoiceAddendum],
bt.UseDynamicContentForInvoiceBody,
bt.UseDynamicContentForInvoiceAddendumBody,
ri.GenerateSummaryInvoice,
rc.Name [CategoryName],
bt.SplitRentalInvoiceByContract [SplitByContract],
ISNULL(CTE_IsCAD.IsCanada,0) [IsCanada],
COUNT(DISTINCT ierd.BlendNumber) [DetailsCount],
bt.DeliverInvoiceViaMail,
CONVERT(bit,0) IsSummaryReport,
CONVERT(bit,0) IsSpillOverApplicable,
invoiceExtractCustomerDetails.LogoId LogoId,
it.Name InvoiceTypeName
INTO #Result
FROM
dbo.ReceivableInvoices ri
JOIN dbo.BillToes bt ON ri.BillToId = bt.Id AND ri.IsStatementInvoice = 0
JOIN dbo.InvoiceFormats ift ON ri.ReportFormatId = ift.Id
JOIN dbo.InvoiceTypes it ON ift.InvoiceTypeId = it.Id
JOIN dbo.ReceivableCategories rc ON ri.ReceivableCategoryId = rc.Id
JOIN dbo.InvoiceExtractReceivableDetails ierd ON ri.Id = ierd.InvoiceId
JOIN dbo.CurrencyCodes cc ON cc.ISO = ri.CurrencyISO
JOIN dbo.Currencies cur ON cur.CurrencyCodeId = cc.Id
JOIN dbo.InvoiceExtractCustomerDetails invoiceExtractCustomerDetails ON ierd.InvoiceId = invoiceExtractCustomerDetails.InvoiceId
LEFT JOIN CTE_IsCAD ON ri.Id = CTE_IsCAD.InvoiceId
LEFT JOIN dbo.BillToInvoiceFormats btif ON bt.Id = btif.BillToId AND btif.IsActive = 1 AND btif.InvoiceFormatId = ri.ReportFormatId AND btif.ReceivableCategory = rc.Name
WHERE (ri.JobStepInstanceId = @JobStepInstanceId Or @JobStepInstanceId = 0)
AND ri.IsActive = 1 AND ri.IsPdfGenerated = 0
AND ri.InvoicePreference IN ('GenerateAndDeliver','SuppressDelivery')
AND ((@IsBillNegativeandZeroReceivables = 0 AND (ri.InvoiceAmount_Amount + ri.InvoiceTaxAmount_Amount) > 0)
OR @IsBillNegativeandZeroReceivables = 1)
GROUP BY ri.Id,
ri.Number,
bt.Id,
ri.CustomerId,
ri.RemitToId,
ri.DueDate,
ri.IsPrivateLabel,
ri.ReceivableCategoryId,
ri.ReportFormatId,
ri.IsACH,
cur.Id,
ri.LegalEntityId,
btif.InvoiceOutputFormat,
ift.ReportName,
ri.InvoicePreference,
bt.GenerateInvoiceAddendum,
bt.UseDynamicContentForInvoiceBody,
bt.UseDynamicContentForInvoiceAddendumBody,
ri.GenerateSummaryInvoice,
rc.Name,
bt.SplitRentalInvoiceByContract,
CTE_IsCAD.IsCanada,
bt.DeliverInvoiceViaMail,
invoiceExtractCustomerDetails.LogoId,
it.Name

;WITH CTE_IsCAD AS
(
SELECT ri.Id [InvoiceId]
,CASE WHEN MIN(c.LongName) = 'Canada' THEN CAST(1 AS BIT)
ELSE CAST(0 AS BIT)
END [IsCanada]
FROM
ReceivableInvoices ri
JOIN ReceivableInvoiceStatementAssociations SI ON SI.StatementInvoiceId = ri.Id 
JOIN ReceivableInvoiceDetails rid ON SI.ReceivableInvoiceId = rid.ReceivableInvoiceId
AND rid.IsActive = 1
JOIN ReceivableTaxDetails rtd ON rtd.ReceivableDetailId = rid.ReceivableDetailId
AND rtd.IsActive = 1
JOIN Locations l ON l.Id = rtd.LocationId
JOIN States s ON l.StateId = s.Id
JOIN Countries c ON s.CountryId = c.Id
WHERE (ri.JobStepInstanceId = @JobStepInstanceId Or @JobStepInstanceId = 0)
AND ri.IsActive = 1 AND ri.IsPdfGenerated = 0
AND ri.InvoicePreference IN ('GenerateAndDeliver','SuppressDelivery')
AND ((@IsBillNegativeandZeroReceivables = 0 AND ((ri.InvoiceAmount_Amount + ri.InvoiceTaxAmount_Amount) > 0 OR (ri.Balance_Amount + ri.TaxBalance_Amount) > 0))
OR @IsBillNegativeandZeroReceivables = 1)
GROUP BY ri.Id
)
INSERT INTO #Result
SELECT ri.Id,
ri.Number [InvoiceNumber],
bt.Id [BillToId],
ri.CustomerId [CustomerId],
ri.RemitToId [RemitId],
ri.DueDate [DueDate],
ri.IsPrivateLabel [IsPrivateLabel],
ri.ReceivableCategoryId [ReceivableCategoryId],
ri.ReportFormatId [ReportFormatId],
ri.IsACH [IsACH],
cur.Id [CurrencyId],
ri.LegalEntityId [LegalEntityId],
ISNULL(bt.StatementInvoiceOutputFormat,'PDF') [InvoiceOutputFormat],
ift.ReportName,
ri.InvoicePreference [InvoicePreference],
bt.GenerateInvoiceAddendum [GenerateInvoiceAddendum],
bt.UseDynamicContentForInvoiceBody,
bt.UseDynamicContentForInvoiceAddendumBody,
ri.GenerateSummaryInvoice,
rc.Name [CategoryName],
bt.SplitRentalInvoiceByContract [SplitByContract],
ISNULL(CTE_IsCAD.IsCanada,0) [IsCanada],
CAST(0 AS int) [DetailsCount],
bt.DeliverInvoiceViaMail,
CONVERT(bit,0) IsSummaryReport,
CONVERT(bit,0) IsSpillOverApplicable,
invoiceExtractCustomerDetails.LogoId LogoId,
it.Name InvoiceTypeName
FROM dbo.ReceivableInvoices ri
JOIN dbo.BillToes bt ON ri.BillToId = bt.Id AND ri.IsStatementInvoice = 1
JOIN dbo.InvoiceFormats ift ON ri.ReportFormatId = ift.Id
JOIN dbo.InvoiceTypes it ON ift.InvoiceTypeId = it.Id
JOIN dbo.ReceivableCategories rc ON ri.ReceivableCategoryId = rc.Id
JOIN dbo.CurrencyCodes cc ON cc.ISO = ri.CurrencyISO
JOIN dbo.Currencies cur ON cur.CurrencyCodeId = cc.Id
JOIN dbo.InvoiceExtractCustomerDetails invoiceExtractCustomerDetails ON ri.Id = invoiceExtractCustomerDetails.InvoiceId
LEFT JOIN CTE_IsCAD ON ri.Id = CTE_IsCAD.InvoiceId
WHERE (ri.JobStepInstanceId = @JobStepInstanceId Or @JobStepInstanceId = 0)
AND ri.IsActive = 1 AND ri.IsPdfGenerated = 0
AND ri.InvoicePreference IN ('GenerateAndDeliver','SuppressDelivery')
AND ((@IsBillNegativeandZeroReceivables = 0 AND (ri.InvoiceAmount_Amount + ri.InvoiceTaxAmount_Amount) > 0)
OR @IsBillNegativeandZeroReceivables = 1)
GROUP BY ri.Id,
ri.Number,
bt.Id,
ri.CustomerId,
ri.RemitToId,
ri.DueDate,
ri.IsPrivateLabel,
ri.ReceivableCategoryId,
ri.ReportFormatId,
ri.IsACH,
cur.Id,
ri.LegalEntityId,
ift.ReportName,
ri.InvoicePreference,
bt.GenerateInvoiceAddendum,
bt.UseDynamicContentForInvoiceBody,
bt.UseDynamicContentForInvoiceAddendumBody,
ri.GenerateSummaryInvoice,
rc.Name,
bt.SplitRentalInvoiceByContract,
bt.DeliverInvoiceViaMail,
invoiceExtractCustomerDetails.LogoId,
bt.StatementInvoiceOutputFormat,
CTE_IsCAD.IsCanada,
it.Name 
SELECT * FROM #Result
DROP TABLE #Result
END

GO

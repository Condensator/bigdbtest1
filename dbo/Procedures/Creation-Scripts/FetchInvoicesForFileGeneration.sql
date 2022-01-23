SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[FetchInvoicesForFileGeneration]
(
@JobStepInstanceId	BIGINT,
@SourceJobStepInstanceId	BIGINT,
@ChunkNumber		INT,
@BillNegativeandZeroReceivables BIT
)
AS
BEGIN

SELECT 
RI.Id InvoiceId,
ri.Number [InvoiceNumber],
ri.CustomerId [CustomerId],
ri.RemitToId [RemitId],
ri.DueDate [DueDate],
ri.IsPrivateLabel [IsPrivateLabel],
ri.ReceivableCategoryId [ReceivableCategoryId],
ri.ReportFormatId [ReportFormatId],
ri.IsACH [IsACH],
RI.LegalEntityId,
ri.InvoicePreference [InvoicePreference],
ri.GenerateSummaryInvoice,
ri.IsStatementInvoice,
bt.Id [BillToId],
bt.GenerateInvoiceAddendum,
bt.UseDynamicContentForInvoiceBody,
bt.UseDynamicContentForInvoiceAddendumBody,
bt.SplitRentalInvoiceByContract [SplitByContract],
bt.DeliverInvoiceViaMail,
ift.ReportName,
rc.Name [CategoryName],
cur.Id CurrencyId,
invoiceExtractCustomerDetails.LogoId LogoId,
bt.StatementInvoiceOutputFormat
INTO #ChunkInvoices
FROM ReceivableInvoices RI 
INNER JOIN InvoiceChunkDetails_Extract ICD ON RI.BillToId = ICD.BillToId AND RI.JobStepInstanceId=@SourceJobStepInstanceId AND 
	ICD.JobStepInstanceId=@JobStepInstanceId AND ICD.ChunkNumber=@ChunkNumber
INNER JOIN BillToes bt ON ri.BillToId = bt.Id
INNER JOIN InvoiceFormats ift ON ri.ReportFormatId = ift.Id
INNER JOIN ReceivableCategories rc ON ri.ReceivableCategoryId = rc.Id
INNER JOIN Currencies cur ON cur.Id = ri.CurrencyId
INNER JOIN InvoiceExtractCustomerDetails invoiceExtractCustomerDetails ON ri.Id = invoiceExtractCustomerDetails.InvoiceId
WHERE RI.IsActive = 1 AND RI.IsPdfGenerated = 0
AND RI.InvoicePreference IN ('GenerateAndDeliver','SuppressDelivery')
AND (
	(@BillNegativeandZeroReceivables = 0 AND ((RI.InvoiceAmount_Amount + RI.InvoiceTaxAmount_Amount) > 0 OR (RI.Balance_Amount + RI.TaxBalance_Amount) > 0))
	OR @BillNegativeandZeroReceivables = 1
)

;WITH CTE_IsCAD AS
(
SELECT ri.InvoiceId [InvoiceId]
,CASE WHEN MIN(c.LongName) = 'Canada' THEN CAST(1 AS BIT)
ELSE CAST(0 AS BIT)
END [IsCanada]
FROM
#ChunkInvoices ri
JOIN ReceivableInvoiceDetails rid ON ri.InvoiceId = rid.ReceivableInvoiceId
AND rid.IsActive = 1
JOIN ReceivableTaxDetails rtd ON rtd.ReceivableDetailId = rid.ReceivableDetailId
AND rtd.IsActive = 1
JOIN Locations l ON l.Id = rtd.LocationId
JOIN States s ON l.StateId = s.Id
JOIN Countries c ON s.CountryId = c.Id
GROUP BY ri.InvoiceId
)
SELECT DISTINCT
ri.[InvoiceId],
ri.[InvoiceNumber],
ri.[BillToId],
ri.CustomerId [CustomerId],
ri.[RemitId],
ri.DueDate [DueDate],
ri.IsPrivateLabel [IsPrivateLabel],
ri.ReceivableCategoryId [ReceivableCategoryId],
ri.ReportFormatId [ReportFormatId],
ri.IsACH [IsACH],
ri.[CurrencyId],
ri.LegalEntityId [LegalEntityId],
ISNULL(btif.InvoiceOutputFormat,'PDF') [InvoiceOutputFormat],
ri.ReportName,
ri.InvoicePreference [InvoicePreference],
ri.GenerateInvoiceAddendum [GenerateInvoiceAddendum],
ri.UseDynamicContentForInvoiceBody,
ri.UseDynamicContentForInvoiceAddendumBody,
ri.GenerateSummaryInvoice,
ri.[CategoryName],
ri.[SplitByContract],
ISNULL(CTE_IsCAD.IsCanada,0) [IsCanada],
COUNT(DISTINCT ierd.BlendNumber) [DetailsCount],
ri.DeliverInvoiceViaMail,
CONVERT(bit,0) IsSummaryReport,
CONVERT(bit,0) IsSpillOverApplicable,
ri.LogoId LogoId
INTO #Result
FROM
#ChunkInvoices ri
JOIN dbo.InvoiceExtractReceivableDetails ierd ON ri.InvoiceId = ierd.InvoiceId AND ri.IsStatementInvoice=0
LEFT JOIN CTE_IsCAD ON ri.InvoiceId = CTE_IsCAD.InvoiceId
LEFT JOIN dbo.BillToInvoiceFormats btif ON ri.BillToId = btif.BillToId AND btif.IsActive = 1 AND btif.InvoiceFormatId = ri.ReportFormatId AND btif.ReceivableCategory = ri.CategoryName
GROUP BY ri.InvoiceId,
ri.InvoiceNumber,
ri.BillToId,
ri.CustomerId,
ri.RemitId,
ri.DueDate,
ri.IsPrivateLabel,
ri.ReceivableCategoryId,
ri.ReportFormatId,
ri.IsACH,
Ri.CurrencyId,
ri.LegalEntityId,
btif.InvoiceOutputFormat,
ri.ReportName,
ri.InvoicePreference,
ri.GenerateInvoiceAddendum,
ri.UseDynamicContentForInvoiceBody,
ri.UseDynamicContentForInvoiceAddendumBody,
ri.GenerateSummaryInvoice,
ri.CategoryName,
ri.SplitByContract,
CTE_IsCAD.IsCanada,
ri.DeliverInvoiceViaMail,
ri.LogoId

;WITH CTE_IsCAD AS
(
SELECT ri.InvoiceId [InvoiceId]
,CASE WHEN MIN(c.LongName) = 'Canada' THEN CAST(1 AS BIT)
ELSE CAST(0 AS BIT)
END [IsCanada]
FROM
#ChunkInvoices ri
JOIN ReceivableInvoiceStatementAssociations SI ON SI.StatementInvoiceId = ri.InvoiceId 
JOIN ReceivableInvoiceDetails rid ON SI.ReceivableInvoiceId = rid.ReceivableInvoiceId
AND rid.IsActive = 1
JOIN ReceivableTaxDetails rtd ON rtd.ReceivableDetailId = rid.ReceivableDetailId
AND rtd.IsActive = 1
JOIN Locations l ON l.Id = rtd.LocationId
JOIN States s ON l.StateId = s.Id
JOIN Countries c ON s.CountryId = c.Id
GROUP BY ri.InvoiceId
)
INSERT INTO #Result
SELECT ri.InvoiceId,
ri.[InvoiceNumber],
ri.[BillToId],
ri.CustomerId [CustomerId],
ri.[RemitId],
ri.DueDate [DueDate],
ri.IsPrivateLabel [IsPrivateLabel],
ri.ReceivableCategoryId [ReceivableCategoryId],
ri.ReportFormatId [ReportFormatId],
ri.IsACH [IsACH],
ri.[CurrencyId],
ri.LegalEntityId [LegalEntityId],
ISNULL(ri.StatementInvoiceOutputFormat,'PDF') [InvoiceOutputFormat],
ri.ReportName,
ri.InvoicePreference [InvoicePreference],
ri.GenerateInvoiceAddendum [GenerateInvoiceAddendum],
ri.UseDynamicContentForInvoiceBody,
ri.UseDynamicContentForInvoiceAddendumBody,
ri.GenerateSummaryInvoice,
ri.CategoryName,
ri.[SplitByContract],
ISNULL(CTE_IsCAD.IsCanada,0) [IsCanada],
CAST(0 AS int) [DetailsCount],
ri.DeliverInvoiceViaMail,
CONVERT(bit,0) IsSummaryReport,
CONVERT(bit,0) IsSpillOverApplicable,
ri.LogoId LogoId
FROM #ChunkInvoices ri
LEFT JOIN CTE_IsCAD ON ri.InvoiceId = CTE_IsCAD.InvoiceId
WHERE ri.IsStatementInvoice=1
GROUP BY ri.InvoiceId,
ri.InvoiceNumber,
ri.BillToId,
ri.CustomerId,
ri.RemitId,
ri.DueDate,
ri.IsPrivateLabel,
ri.ReceivableCategoryId,
ri.ReportFormatId,
ri.IsACH,
Ri.CurrencyId,
ri.LegalEntityId,
ri.ReportName,
ri.InvoicePreference,
ri.GenerateInvoiceAddendum,
ri.UseDynamicContentForInvoiceBody,
ri.UseDynamicContentForInvoiceAddendumBody,
ri.GenerateSummaryInvoice,
ri.CategoryName,
ri.SplitByContract,
ri.DeliverInvoiceViaMail,
ri.LogoId,
ri.StatementInvoiceOutputFormat,
CTE_IsCAD.IsCanada

SELECT 
InvoiceId,[InvoiceNumber],[BillToId],CustomerId,[RemitId],DueDate,IsPrivateLabel,
ReceivableCategoryId,ReportFormatId,IsACH,[CurrencyId],LegalEntityId,[InvoiceOutputFormat],
ReportName,InvoicePreference,GenerateInvoiceAddendum,UseDynamicContentForInvoiceBody,
UseDynamicContentForInvoiceAddendumBody,GenerateSummaryInvoice,CategoryName,
[SplitByContract],[IsCanada],[DetailsCount],DeliverInvoiceViaMail,IsSummaryReport,IsSpillOverApplicable,LogoId
FROM #Result

IF OBJECT_ID('tempDB..#Result') IS NOT NULL
	DROP TABLE #Result		
IF OBJECT_ID('tempDB..#ChunkInvoices') IS NOT NULL
	DROP TABLE #ChunkInvoices
END

GO

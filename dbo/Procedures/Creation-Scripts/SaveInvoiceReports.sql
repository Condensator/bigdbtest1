SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SaveInvoiceReports]
(
@InvoiceList InvoiceReportDetails READONLY
)
AS
BEGIN
UPDATE ReceivableInvoices SET
InvoiceFileName  = list.InvoiceFileName
,InvoiceFile_Source= list.InvoiceFileSource
,InvoiceFile_Type= list.InvoiceFileType
,InvoiceFile_Content= list.InvoiceFileContent
FROM ReceivableInvoices ri
JOIN @InvoiceList list ON ri.Id = list.InvoiceId
END

GO

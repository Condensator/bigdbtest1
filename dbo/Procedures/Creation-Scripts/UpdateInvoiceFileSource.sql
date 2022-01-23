SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateInvoiceFileSource]
(
@JobStepInstanceId BIGINT
) WITH RECOMPILE
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
UPDATE dbo.ReceivableInvoices
SET
dbo.ReceivableInvoices.InvoiceFile_Source = dbo.ReceivableInvoices.InvoiceFileName + '.'+ dbo.ReceivableInvoices.InvoiceFile_Type
WHERE dbo.ReceivableInvoices.JobStepInstanceId = @JobStepInstanceId AND dbo.ReceivableInvoices.InvoiceFile_Content IS NOT NULL
END

GO

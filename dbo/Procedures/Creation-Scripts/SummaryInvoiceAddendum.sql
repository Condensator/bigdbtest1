SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SummaryInvoiceAddendum]
(
@InvoiceId nvarchar(max)
) WITH RECOMPILE
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
--DECLARE @InvoiceID NVARCHAR(MAX) = '17748'
CREATE TABLE #InvoiceIdList
(
Id BIGINT
)
INSERT INTO #InvoiceIdList (Id) SELECT Id FROM ConvertCSVToBigIntTable(@InvoiceId,',');
SELECT
customer.InvoiceNumber
,customer.InvoiceId
,customer.InvoiceType
,customer.DueDate
,customer.InvoiceRunDateLabel
,customer.InvoiceRunDate
,customer.TotalReceivableAmount_Amount Rent
,TotalTaxAmount_Amount SalesTax
,TotalReceivableAmount_Amount + TotalTaxAmount_Amount [Total]
,customer.CustomerNumber
FROM InvoiceExtractCustomerDetails customer
JOIN #InvoiceIdList ON #InvoiceIdList.Id = customer.InvoiceId
DROP TABLE #InvoiceIdList
END

GO

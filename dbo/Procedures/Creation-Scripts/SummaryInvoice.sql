SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SummaryInvoice]
(
@InvoiceId NVARCHAR(MAX),
@AddendumPagesCount INT
) WITH RECOMPILE
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
--DECLARE @InvoiceID NVARCHAR(MAX) = '747181'
--DECLARE @AddendumPagesCount INT = 0
CREATE TABLE #InvoiceIdList
(
Id BIGINT
)
INSERT INTO #InvoiceIdList (Id) SELECT Id FROM ConvertCSVToBigIntTable(@InvoiceId,',');
DECLARE @TopInvoiceId BIGINT = (SELECT TOP(1)Id FROM #InvoiceIdList);
DECLARE @PST decimal(16,2),@QST decimal(16,2),@HSTGST decimal(16,2),@SalesTax decimal(16,2);
DECLARE @GenericInvoiceComment nvarchar(200), @DueDate Date;
SELECT @DueDate = DueDate from dbo.ReceivableInvoices ri WHERE ri.Id = @TopInvoiceId
SELECT @GenericInvoiceComment = comment FROM GenericInvoiceComments WHERE IsCurrent=1 AND @DueDate >= StartDate AND @DueDate <= EndDate;
CREATE TABLE #TaxHeader(InvoiceId BIGINT,ReceivableTaxDetailId BIGINT,AssetId BIGINT,ReceivableCodeId BIGINT);
CREATE TABLE #ImpositionDetails(InvoiceId BIGINT,TaxTypeId BIGINT,ReceivableTaxDetailId BIGINT,AssetId BIGINT,Rent DECIMAL(16,2),Amount DECIMAL(16,2),ExternalJurisdictionId INT,ImpositionType NVARCHAR(MAX),ReceivableCodeId BIGINT);
INSERT INTO #TaxHeader
SELECT DISTINCT customer.InvoiceId,tax.ReceivableTaxDetailId,tax.AssetId,tax.ReceivableCodeId
FROM InvoiceExtractCustomerDetails customer
INNER JOIN InvoiceExtractReceivableTaxDetails tax
ON customer.InvoiceID = tax.InvoiceID
INNER JOIN #InvoiceIdList ON tax.InvoiceId = #InvoiceIdList.Id
--WHERE customer.InvoiceId = @InvoiceId
INSERT INTO #ImpositionDetails
SELECT DISTINCT th.InvoiceId,tax.TaxTypeId,th.ReceivableTaxDetailId,th.AssetId,
tax.Rent_Amount * rid.ExchangeRate Rent_Amount,tax.TaxAmount_Amount * rid.ExchangeRate TaxAmount_Amount
,tax.ExternalJurisdictionId,tax.ImpositionType,th.ReceivableCodeId
FROM #TaxHeader th
INNER JOIN InvoiceExtractReceivableTaxDetails tax
ON th.InvoiceID = tax.InvoiceID
AND th.AssetID = tax.AssetID AND th.ReceivableTaxDetailId = tax.ReceivableTaxDetailId
INNER JOIN ReceivableInvoiceDetails rid
ON rid.ReceivableDetailId = tax.ReceivableDetailId
AND rid.IsActive = 1
;WITH CTE_Final AS
(
SELECT *, ROW_NUMBER() OVER(PARTITION BY ReceivableTaxDetailId,ExternalJurisdictionId,TaxTypeId,ImpositionType ORDER BY ExternalJurisdictionId) [RowNumber]
FROM #ImpositionDetails
)
SELECT * INTO #TempResult FROM CTE_Final WHERE RowNumber = 1;
SELECT @HSTGST = SUM(Amount) FROM #TempResult WHERE ImpositionType IN('GST/HST','GST')
GROUP BY InvoiceID
SELECT @QST = SUM(Amount) FROM #TempResult WHERE ImpositionType IN ('Quebec Sales Tax (VAT)','QST')
GROUP BY InvoiceID
SELECT @PST = SUM(Amount) FROM #TempResult WHERE ImpositionType IN ('Provincial Sales Tax (PST)','PST')
GROUP BY InvoiceID
SELECT @SalesTax = SUM(Amount)  FROM #TempResult
WHERE ImpositionType NOT IN ('Provincial Sales Tax (PST)','PST','Quebec Sales Tax (VAT)','QST','GST/HST','GST')
;WITH CTE_TotalAmounts AS
(
SELECT
SUM(customer.TotalReceivableAmount_Amount) [ReceivableAmount],
SUM(customer.TotalTaxAmount_Amount) [TaxAmount],
1 [Id]
FROM InvoiceExtractCustomerDetails customer
INNER JOIN #InvoiceIdList itp ON customer.InvoiceId = itp.Id
)
SELECT
customer.InvoiceNumber
,Totals.ReceivableAmount
,@HSTGST [HSTGST]
,@QST [QST]
,@PST [PST]
,@SalesTax [SalesTax]
,customer.GSTId
--,Totals.TaxAmount
,Totals.ReceivableAmount + Totals.TaxAmount [TotalAmountDue]
,customer.InvoiceId
,customer.LegalEntityName
,customer.RemitToName
,customer.InvoiceType
,customer.DueDate
,customer.InvoiceRunDate
,customer.InvoiceRunDateLabel
,customer.CustomerName
,customer.DeliverInvoiceViaEmail [IsDeliveredViaEmail]
,customer.CustomerNumber
,customer.AttentionLine
,customer.BillingAddressLine1
,customer.BillingAddressLine2
,customer.BillingCity
,customer.BillingState
,customer.BillingCountry
,customer.BillingZip
,@GenericInvoiceComment 'GenericInvoiceComment'
,customer.GenerateInvoiceAddendum
,customer.LessorContactPhone
,customer.LessorContactEmail
,customer.CustomerComments
,customer.CustomerInvoiceCommentBeginDate
,customer.CustomerInvoiceCommentEndDate
,customer.LessorAddressLine1
,customer.LessorAddressLine2
,customer.LessorCity
,customer.LessorState
,customer.LessorCountry
,customer.LessorZip
,customer.RemitToCode
,customer.TotalReceivableAmount_Currency [Currency]
,CASE WHEN (customer.TotalReceivableAmount_Currency = 'USD' OR customer.TotalReceivableAmount_Currency = 'CAD')  THEN '$' ELSE '£' END [CurrencySymbol]
,customer.IsACH
,customer.LessorWebAddress
,CASE WHEN Logoes.LogoImageFile_Content IS NOT NULL AND Logoes.LogoImageFile_Content <> 0x THEN
(SELECT fs.Content FROM FileStores fs WHERE fs.Guid = dbo.GetContentGuid(Logoes.LogoImageFile_Content))
ELSE NULL END 'LogoImageFile_Content'
,'image/' + Logoes.LogoImageFile_Type [LogoImageFile_Type]
FROM InvoiceExtractCustomerDetails customer
INNER JOIN CTE_TotalAmounts Totals
ON 1 = Totals.Id
LEFT JOIN Logoes
ON customer.LogoId = Logoes.Id
WHERE customer.InvoiceID = @TopInvoiceId
DROP TABLE #InvoiceIdList
DROP TABLE #TaxHeader
DROP TABLE #ImpositionDetails
DROP TABLE #TempResult
END

GO

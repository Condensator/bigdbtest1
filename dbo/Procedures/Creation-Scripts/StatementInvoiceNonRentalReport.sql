SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[StatementInvoiceNonRentalReport]
(
@InvoiceId BIGINT,
@AddendumPagesCount INT
) WITH RECOMPILE
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
DECLARE @BillToId BIGINT,@TotalAmount decimal(16,2),@GenericInvoiceComment nvarchar(200), @DueDate Date;
Select @BillToId=ri.BillToId,@TotalAmount=Balance_Amount+TaxBalance_Amount, @DueDate = DueDate from dbo.ReceivableInvoices ri WHERE ri.Id = @InvoiceId
SELECT @GenericInvoiceComment = comment FROM GenericInvoiceComments WHERE IsCurrent=1 AND @DueDate >= StartDate AND @DueDate <= EndDate;
CREATE TABLE #TaxHeader(InvoiceId BIGINT,ReceivableTaxDetailId BIGINT,AssetId BIGINT,ReceivableCodeId BIGINT);
CREATE TABLE #ImpositionDetails(InvoiceId BIGINT,TaxTypeId BIGINT,ReceivableTaxDetailId BIGINT,AssetId BIGINT,Rent DECIMAL(16,2),Amount DECIMAL(16,2),ExternalJurisdictionId INT,ImpositionType NVARCHAR(MAX),ReceivableCodeId BIGINT);
INSERT INTO #TaxHeader
SELECT DISTINCT customer.InvoiceId,tax.ReceivableTaxDetailId,tax.AssetId,tax.ReceivableCodeId
FROM InvoiceExtractCustomerDetails customer
INNER JOIN InvoiceExtractReceivableTaxDetails tax
ON customer.InvoiceID = tax.InvoiceID
WHERE customer.InvoiceId = @InvoiceId
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
;WITH CTE_GST AS
(
SELECT InvoiceId,SUM(Amount) [GSTHST] FROM #TempResult WHERE ImpositionType IN('GST/HST','GST')
GROUP BY InvoiceID
),
CTE_QST AS
(
SELECT InvoiceId,SUM(Amount) [QST] FROM #TempResult WHERE ImpositionType IN ('Quebec Sales Tax (VAT)','QST')
GROUP BY InvoiceID
),
CTE_PST AS
(
SELECT InvoiceId,SUM(Amount) [PST] FROM #TempResult WHERE ImpositionType IN ('Provincial Sales Tax (PST)','PST')
GROUP BY InvoiceID
),
CTE_SalesTax AS
(
SELECT InvoiceId,SUM(Amount) [SalesTax] FROM #TempResult
WHERE ImpositionType NOT IN ('Provincial Sales Tax (PST)','PST','Quebec Sales Tax (VAT)','QST','GST/HST','GST')
GROUP BY InvoiceID
),
CTE_Final AS(
SELECT lang.InvoiceLabel [CodeName]
,receivable.InvoiceId
,SUM(receivable.ReceivableAmount_Amount * receivable.ExchangeRate) [ReceivableAmount]
,receivable.PeriodStartDate
,receivable.PeriodEndDate
,MIN(receivable.AlternateBillingCurrencyCodeId) AlternateBillingCurrencyCodeId
,MIN(receivable.ExchangeRate) ExchangeRate
,MIN(receivable.ReceivableInvoiceDetailId) ReceivableInvoiceDetailId
FROM
InvoiceExtractReceivableDetails receivable
INNER JOIN dbo.ReceivableDetails rd ON rd.Id = receivable.ReceivableDetailId
AND receivable.InvoiceID = @InvoiceID
INNER JOIN dbo.Receivables r ON r.Id = rd.ReceivableId
INNER JOIN dbo.ReceivableCodes rc ON rc.Id = r.ReceivableCodeId
INNER JOIN dbo.InvoiceGroupingParameters igp ON rc.ReceivableCategoryId = igp.ReceivableCategoryId
AND rc.ReceivableTypeId = igp.ReceivableTypeId
AND igp.IsActive = 1
INNER JOIN BillToes ON BillToes.Id = @BillToId
AND BillToes.IsActive = 1
INNER JOIN dbo.BillToInvoiceParameters bp ON igp.Id = bp.InvoiceGroupingParameterId
AND bp.BillToId = @BillToId
LEFT JOIN dbo.ReceivableTypeLabelConfigs rtl ON bp.ReceivableTypeLabelId = rtl.Id
AND rtl.IsActive = 1
LEFT JOIN dbo.ReceivableTypeLanguageLabels lang ON rtl.Id = lang.ReceivableTypeLabelConfigId
AND lang.IsActive = 1
AND lang.LanguageConfigId = BillToes.LanguageConfigId
GROUP BY lang.InvoiceLabel
,receivable.InvoiceId
,receivable.PeriodStartDate
,receivable.PeriodEndDate
)
SELECT
ROW_NUMBER() OVER(ORDER BY receivable.ReceivableInvoiceDetailId) AS RowNo
,customer.RemitToName
,customer.LegalEntityName
,customer.InvoiceType
,customer.InvoiceNumber
,customer.InvoiceNumberLabel
,customer.InvoiceRunDateLabel
,customer.InvoiceRunDate
,customer.DueDate
,customer.CustomerName
,customer.DeliverInvoiceViaEmail
,customer.AttentionLine
,customer.BillingAddressLine1
,customer.BillingAddressLine2
,customer.BillingCity
,customer.BillingState
,customer.BillingCountry
,customer.BillingZip
,customer.LessorContactPhone
,customer.LessorContactEmail
,customer.CustomerComments
,customer.CustomerInvoiceCommentBeginDate
,customer.CustomerInvoiceCommentEndDate
,receivable.PeriodStartDate
,receivable.PeriodEndDate
,receivable.ReceivableInvoiceDetailid DetailId
,customer.CustomerNumber
,customer.LessorWebAddress
,CASE WHEN Logoes.LogoImageFile_Content IS NOT NULL AND Logoes.LogoImageFile_Content <> 0x THEN
(SELECT fs.Content FROM FileStores fs WHERE fs.Guid = dbo.GetContentGuid(Logoes.LogoImageFile_Content))
ELSE NULL END 'LogoImageFile_Content'
,'image/' + Logoes.LogoImageFile_Type [LogoImageFile_Type]
,customer.LessorAddressLine1
,customer.LessorAddressLine2
,customer.LessorCity
,customer.LessorState
,customer.LessorZip
,customer.LessorCountry
,customer.RemitToCode
,receivable.ReceivableAmount [ReceivableAmount]
,CTE_SalesTax.SalesTax	[TaxAmount]
,@TotalAmount * receivable.ExchangeRate [TotalAmountDue]
,CurrencyCodes.ISO [Currency]
,ISNULL(CurrencyCodes.Symbol,'') 'CurrencySymbol'
,customer.IsACH
,@GenericInvoiceComment 'GenericInvoiceComment'
,customer.GenerateInvoiceAddendum
,customer.UseDynamicContentForInvoiceAddendumBody
,ISNULL(receivable.CodeName,'') CodeName
,CTE_GST.GSTHST
,CTE_QST.QST
,CTE_PST.PST
,customer.GSTId
FROM InvoiceExtractCustomerDetails customer
INNER JOIN CTE_Final receivable
ON customer.InvoiceID = receivable.InvoiceID
LEFT JOIN Logoes
ON customer.LogoId = Logoes.Id
LEFT JOIN CurrencyCodes ON
CurrencyCodes.Id = receivable.AlternateBillingCurrencyCodeId
LEFT JOIN CTE_GST ON customer.InvoiceID = CTE_GST.InvoiceID
LEFT JOIN CTE_PST ON customer.InvoiceID = CTE_PST.InvoiceID
LEFT JOIN CTE_QST ON customer.InvoiceID = CTE_QST.InvoiceID
LEFT JOIN CTE_SalesTax ON customer.InvoiceID = CTE_SalesTax.InvoiceID
WHERE customer.InvoiceID = @InvoiceID
DROP TABLE #TaxHeader
DROP TABLE #ImpositionDetails
DROP TABLE #TempResult
END

GO

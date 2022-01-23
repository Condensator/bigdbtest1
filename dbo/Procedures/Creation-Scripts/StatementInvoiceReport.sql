SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[StatementInvoiceReport]
(
@InvoiceId BIGINT
) WITH RECOMPILE
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
DECLARE @BillToId BIGINT,@TotalAmount decimal(16,2),@CurrentDueAmount decimal(16, 2),@PastDueAmount decimal(16,2),@GenericInvoiceComment nvarchar(200), @DueDate Date;
Select @BillToId=ri.BillToId, @DueDate = DueDate from dbo.ReceivableInvoices ri WHERE ri.Id = @InvoiceId
SELECT @GenericInvoiceComment = comment FROM GenericInvoiceComments WHERE IsCurrent=1 AND @DueDate >= StartDate AND @DueDate <= EndDate;

CREATE TABLE #TaxHeader(InvoiceId BIGINT,IsCurrentInvoice BIT,ReceivableTaxDetailId BIGINT,AssetId BIGINT,ReceivableCodeId BIGINT,StatementInvoiceId BIGINT);

CREATE TABLE #ImpositionDetails(InvoiceId BIGINT,IsCurrentInvoice BIT,TaxTypeId BIGINT,ReceivableTaxDetailId BIGINT,AssetId BIGINT,Rent DECIMAL(16,2),Amount DECIMAL(16,2),ExternalJurisdictionId INT,ImpositionType NVARCHAR(MAX),ReceivableCodeId BIGINT,StatementInvoiceId BIGINT);

CREATE TABLE #InvoiceAssociations(ReceivableInvoiceId BIGINT,StatementInvoiceId BIGINT,IsCurrentInvoice BIT)

INSERT INTO #InvoiceAssociations
SELECT DISTINCT ReceivableInvoiceId,StatementInvoiceId,IsCurrentInvoice
FROM ReceivableInvoiceStatementAssociations WHERE StatementInvoiceId = @InvoiceId

SELECT @CurrentDueAmount = ISNULL(SUM(RD.ReceivableAmount_Amount + RD.TaxAmount_Amount), 0) FROM #InvoiceAssociations I JOIN InvoiceExtractReceivableDetails RD ON I.ReceivableInvoiceId = RD.InvoiceId AND I.IsCurrentInvoice = 1

SELECT @PastDueAmount =  ISNULL(SUM(Balance_Amount + TaxBalance_Amount), 0) FROM #InvoiceAssociations I JOIN ReceivableInvoices R
ON I.ReceivableInvoiceId = R.Id WHERE I.IsCurrentInvoice = 0

SELECT @TotalAmount = @CurrentDueAmount + @PastDueAmount

INSERT INTO #TaxHeader
SELECT DISTINCT SI.ReceivableInvoiceId,SI.IsCurrentInvoice,tax.ReceivableTaxDetailId,tax.AssetId,tax.ReceivableCodeId, SI.StatementInvoiceId
FROM InvoiceExtractCustomerDetails customer
INNER JOIN #InvoiceAssociations SI 
ON customer.InvoiceID = SI.StatementInvoiceId  
INNER JOIN InvoiceExtractReceivableTaxDetails tax
ON SI.ReceivableInvoiceId = tax.InvoiceID
WHERE customer.InvoiceId = @InvoiceId

INSERT INTO #ImpositionDetails
SELECT DISTINCT th.InvoiceId,th.IsCurrentInvoice,tax.TaxTypeId,th.ReceivableTaxDetailId,th.AssetId,
tax.Rent_Amount * rid.ExchangeRate Rent_Amount,tax.TaxAmount_Amount * rid.ExchangeRate TaxAmount_Amount
,tax.ExternalJurisdictionId,tax.ImpositionType,th.ReceivableCodeId, th.StatementInvoiceId
FROM #TaxHeader th
INNER JOIN InvoiceExtractReceivableTaxDetails tax
ON th.InvoiceId = tax.InvoiceID
AND (th.AssetID = tax.AssetID OR th.AssetId is null) AND th.ReceivableTaxDetailId = tax.ReceivableTaxDetailId
INNER JOIN ReceivableInvoiceDetails rid
ON rid.ReceivableDetailId = tax.ReceivableDetailId
AND rid.IsActive = 1


;WITH CTE_Final AS
(
SELECT *, ROW_NUMBER() OVER(PARTITION BY ReceivableTaxDetailId,ExternalJurisdictionId,TaxTypeId,ImpositionType ORDER BY ExternalJurisdictionId) [RowNumber]
FROM #ImpositionDetails
)
SELECT * INTO #TempResult FROM CTE_Final WHERE RowNumber = 1 AND IsCurrentInvoice = 1;

;WITH CTE_GST AS
(
SELECT StatementInvoiceId,SUM(Amount) [GSTHST] FROM #TempResult WHERE ImpositionType IN('GST/HST','GST')
GROUP BY StatementInvoiceId
),
CTE_QST AS
(
SELECT StatementInvoiceId,SUM(Amount) [QST] FROM #TempResult WHERE ImpositionType IN ('Quebec Sales Tax (VAT)','QST')
GROUP BY StatementInvoiceId
),
CTE_PST AS
(
SELECT StatementInvoiceId,SUM(Amount) [PST] FROM #TempResult WHERE ImpositionType IN ('Provincial Sales Tax (PST)','PST')
GROUP BY StatementInvoiceId
),
CTE_SalesTax AS
(
SELECT StatementInvoiceId,SUM(Amount) [SalesTax] FROM #TempResult
WHERE ImpositionType NOT IN ('Provincial Sales Tax (PST)','PST','Quebec Sales Tax (VAT)','QST','GST/HST','GST')
GROUP BY StatementInvoiceId
),
CTE_Final AS
(
SELECT CASE WHEN (rt.Name IN ('Sundry','SundrySeparate') AND RCLL.InvoiceLabel IS NOT NULL )
		  THEN RCLL.InvoiceLabel
		  ELSE ISNULL(lang.InvoiceLabel,'')
	END [CodeName]
,si.StatementInvoiceId
,si.IsCurrentInvoice
,SUM(receivable.ReceivableAmount_Amount * receivable.ExchangeRate) [ReceivableAmount]
,receivable.PeriodStartDate
,receivable.PeriodEndDate
,MIN(receivable.AlternateBillingCurrencyCodeId) AlternateBillingCurrencyCodeId
,MIN(receivable.ExchangeRate) ExchangeRate
,MIN(receivable.ReceivableInvoiceDetailId) ReceivableInvoiceDetailId
,receivable.SequenceNumber
,si.ReceivableInvoiceId
FROM
InvoiceExtractReceivableDetails receivable
INNER JOIN #InvoiceAssociations SI ON SI.StatementInvoiceId = @InvoiceId
INNER JOIN dbo.ReceivableDetails rd ON rd.Id = receivable.ReceivableDetailId
AND receivable.InvoiceID = SI.ReceivableInvoiceId
INNER JOIN dbo.Receivables r ON r.Id = rd.ReceivableId
INNER JOIN dbo.ReceivableCodes rc ON rc.Id = r.ReceivableCodeId
INNER JOIN dbo.ReceivableTypes rt ON rc.receivableTypeId = rt.Id
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
LEFT JOIN dbo.ReceivableCodeLanguageLabels RCLL ON rc.Id = RCLL.ReceivableCodeId 
AND RCLL.IsActive=1
AND RCLL.LanguageConfigId = BillToes.LanguageConfigId
GROUP BY lang.InvoiceLabel
,RCLL.InvoiceLabel
,rt.Name
,SI.StatementInvoiceId
,si.IsCurrentInvoice
,receivable.PeriodStartDate
,receivable.PeriodEndDate
,receivable.SequenceNumber
,SI.ReceivableInvoiceId
)
SELECT
customer.RemitToName
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
,@PastDueAmount * receivable.ExchangeRate[PastDueAmount]
,receivable.SequenceNumber
,receivable.IsCurrentInvoice
,CAST(1 AS BIT) as IsAnyCurrentInvoice
,receivable.ReceivableInvoiceDetailId
INTO #StatementInvoiceDetails
FROM InvoiceExtractCustomerDetails customer
INNER JOIN CTE_Final receivable
ON customer.InvoiceID = receivable.StatementInvoiceId
LEFT JOIN Logoes
ON customer.LogoId = Logoes.Id
LEFT JOIN CurrencyCodes ON
CurrencyCodes.Id = receivable.AlternateBillingCurrencyCodeId
LEFT JOIN CTE_GST ON receivable.StatementInvoiceId = CTE_GST.StatementInvoiceId
LEFT JOIN CTE_PST ON receivable.StatementInvoiceId = CTE_PST.StatementInvoiceId
LEFT JOIN CTE_QST ON receivable.StatementInvoiceId = CTE_QST.StatementInvoiceId
LEFT JOIN CTE_SalesTax ON receivable.StatementInvoiceId = CTE_SalesTax.StatementInvoiceId
WHERE customer.InvoiceID = @InvoiceId 


IF NOT EXISTS(SELECT IsCurrentInvoice FROM #StatementInvoiceDetails WHERE IsCurrentInvoice = 1)
BEGIN
UPDATE #StatementInvoiceDetails SET IsAnyCurrentInvoice = 0
SELECT TOP 1  ROW_NUMBER() OVER(ORDER BY ReceivableInvoiceDetailId) as RowNo, * FROM #StatementInvoiceDetails 
END

IF EXISTS(SELECT IsCurrentInvoice FROM #StatementInvoiceDetails WHERE IsCurrentInvoice = 1)
BEGIN
SELECT ROW_NUMBER() OVER(ORDER BY ReceivableInvoiceDetailId) as RowNo,* FROM #StatementInvoiceDetails WHERE IsCurrentInvoice = 1
END

DROP TABLE #TaxHeader
DROP TABLE #ImpositionDetails
DROP TABLE #TempResult
END

GO

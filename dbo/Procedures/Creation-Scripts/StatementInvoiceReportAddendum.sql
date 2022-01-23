SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[StatementInvoiceReportAddendum]
(
@InvoiceId BIGINT
) WITH RECOMPILE
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
DECLARE @AmountGrandTotal decimal(16,2),@BillToId BIGINT, @TaxGrandTotal decimal(16,2),@TotalGrandTotal decimal(16,2);
SELECT @BillToId=ri.BillToId from dbo.ReceivableInvoices ri WHERE ri.Id = @InvoiceId

SELECT
C.InvoiceId,
RD.ReceivableDetailId,
RD.ReceivableAmount_Amount,
SI.ReceivableInvoiceId,
C.InvoiceNumber,
C.DueDate,
InvoiceType,
C.InvoiceNumberLabel,
InvoiceRunDateLabel,
InvoiceRunDate,
RD.SequenceNumber,
CustomerNumber,
CASE WHEN SI.IsCurrentInvoice = 0 
     THEN ISNULL(R.Balance_Amount * RD.ExchangeRate,0) 
	 ELSE ISNULL(RD.ReceivableAmount_Amount * RD.ExchangeRate,0) END 'AmountBalance',
CASE WHEN SI.IsCurrentInvoice = 0 
     THEN ISNULL(R.TaxBalance_Amount * RD.ExchangeRate,0) 
	 ELSE ISNULL(RD.TaxAmount_Amount * RD.ExchangeRate,0) END 'TaxBalance',
CASE WHEN SI.IsCurrentInvoice = 0 
     THEN ISNULL(R.Balance_Amount * RD.ExchangeRate,0) + ISNULL(R.TaxBalance_Amount * RD.ExchangeRate,0)
	 ELSE ISNULL(RD.ReceivableAmount_Amount * RD.ExchangeRate,0) + ISNULL(RD.TaxAmount_Amount * RD.ExchangeRate,0) 
	 END 'TotalBalance',
lang.InvoiceLabel AS CodeName
INTO #StatementInvoiceDetails
FROM InvoiceExtractCustomerDetails C
JOIN ReceivableInvoiceStatementAssociations SI ON C.InvoiceId = SI.StatementInvoiceId
JOIN InvoiceExtractReceivableDetails RD ON
SI.ReceivableInvoiceId = RD.InvoiceId
JOIN ReceivableInvoiceDetails R ON RD.ReceivableDetailId = R.ReceivableDetailId
INNER JOIN dbo.ReceivableCodes rc ON rc.Id = RD.ReceivableCodeId
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
WHERE C.InvoiceId = @InvoiceId

SELECT @AmountGrandTotal = SUM(AmountBalance) FROM #StatementInvoiceDetails
GROUP BY InvoiceNumber

SELECT @TaxGrandTotal = SUM(TaxBalance) FROM #StatementInvoiceDetails
GROUP BY InvoiceNumber

SELECT @TotalGrandTotal = SUM(TotalBalance) FROM #StatementInvoiceDetails
GROUP BY InvoiceNumber

;WITH CTE_ReceivableInvoiceInfo AS
(
SELECT S.InvoiceId AS StatementInvoiceId,S.ReceivableInvoiceId, C.InvoiceNumber AS ReceivableInvoiceNumber, C.DueDate AS ReceivableInvoiceDueDate FROM #StatementInvoiceDetails S 
INNER JOIN InvoiceExtractCustomerDetails C ON S.ReceivableInvoiceId = C.InvoiceId
)
SELECT SI.InvoiceId AS StatementInvoiceId,
       RI.ReceivableInvoiceId,
       CurrentInvoiceNumber = ISNULL(CD.InvoiceNumber, RI.ReceivableInvoiceNumber) ,
	   CurrentDueDate = ISNULL(CD.DueDate,RI.ReceivableInvoiceDueDate)
INTO #ReceivableInvoicesCurrentInvoice 
FROM #StatementInvoiceDetails SI
INNER JOIN CTE_ReceivableInvoiceInfo RI ON SI.InvoiceId = RI.StatementInvoiceId AND SI.ReceivableInvoiceId = RI.ReceivableInvoiceId
LEFT JOIN ReceivableInvoiceStatementAssociations S ON SI.ReceivableInvoiceId = S.ReceivableInvoiceId AND IsCurrentInvoice =1
LEFT JOIN InvoiceExtractCustomerDetails CD ON S.StatementInvoiceId = cd.InvoiceId


SELECT
DISTINCT
InvoiceId,
ReceivableDetailId,
ReceivableAmount_Amount,
SI.ReceivableInvoiceId,
InvoiceNumber,
DueDate,
InvoiceType,
InvoiceNumberLabel,
InvoiceRunDateLabel,
InvoiceRunDate,
SequenceNumber,
CustomerNumber,
AmountBalance,
TaxBalance,
TotalBalance,
@AmountGrandTotal AS AmountGrandTotal,
@TaxGrandTotal AS TaxGrandTotal,
@TotalGrandTotal As TotalGrandTotal,
CurrentInvoiceNumber,
CurrentDueDate,
CodeName
FROM #StatementInvoiceDetails SI
JOIN #ReceivableInvoicesCurrentInvoice RI ON SI.InvoiceId = RI.StatementInvoiceId AND SI.ReceivableInvoiceId = RI.ReceivableInvoiceId
END

GO

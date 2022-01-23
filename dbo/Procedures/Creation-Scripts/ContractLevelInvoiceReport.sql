SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ContractLevelInvoiceReport]
(
@InvoiceId BIGINT,
@ShowPOAndComments BIT,
@ShowPeriodAndComments BIT,
@ShowDefault BIT,
@ShowComments BIT,
@ShowPeriodCovered BIT,
@ShowPO BIT,
@ShowPOAndPeriod BIT,
@ShowAmount BIT,
@AddendumPagesCount INT
) WITH RECOMPILE
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
--DECLARE @InvoiceId BIGINT = 752789;
DECLARE @BillToId BIGINT,@GenericInvoiceComment nvarchar(200), @DueDate Date;
Select @BillToId=ri.BillToId, @DueDate = DueDate from dbo.ReceivableInvoices ri WHERE ri.Id = @InvoiceId
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
	SELECT
		th.InvoiceId,tax.TaxTypeId,th.ReceivableTaxDetailId,th.AssetId,
		SUM(tax.Rent_Amount) * rid.ExchangeRate Rent_Amount,SUM(tax.TaxAmount_Amount) * rid.ExchangeRate TaxAmount_Amount,
		tax.ExternalJurisdictionId,tax.ImpositionType,th.ReceivableCodeId
	FROM #TaxHeader th
		INNER JOIN InvoiceExtractReceivableTaxDetails tax ON th.InvoiceID = tax.InvoiceID
			AND (tax.AssetID IS NULL OR th.AssetID = tax.AssetID)
			AND th.ReceivableTaxDetailId = tax.ReceivableTaxDetailId
		INNER JOIN ReceivableInvoiceDetails rid ON rid.ReceivableDetailId = tax.ReceivableDetailId AND rid.IsActive = 1
	GROUP BY Tax.ReceivableTaxDetailId, tax.ExternalJurisdictionId,tax.TaxTypeId,tax.ImpositionType,
		th.InvoiceId,th.ReceivableCodeId,th.ReceivableTaxDetailId,th.AssetId,rid.ExchangeRate

SELECT 
	InvoiceID,
	CodeName,
	BlendRentalAmount,
	BlendNumber,
	DetailId  
INTO #BlendDetails
from GetBlendDetails(@InvoiceID,@BillToId)

SELECT 
	InvoiceId, 
	SUM(BlendRentalAmount) TotalAmountDue
INTO #TotalAmountDetails
FROM #BlendDetails
	GROUP BY InvoiceID;

/*To check this part*/
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
)

SELECT
ROW_NUMBER() OVER(ORDER BY blend.DetailId) AS RowNo
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
,receivable.ReceivableInvoiceDetailid
,COALESCE(receivable.ContractPurchaseOrderNumber,'_') [PO#]
,receivable.AdditionalComments
,receivable.AdditionalInvoiceCommentBeginDate
,receivable.AdditionalInvoiceCommentEndDate
,receivable.SequenceNumber
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
,receivable.ReceivableAmount_Amount * receivable.ExchangeRate [ReceivableAmount]
,CTE_SalesTax.SalesTax	[TaxAmount]
,(TA.TotalAmountDue * receivable.ExchangeRate) + ISNULL(CTE_SalesTax.SalesTax,0.00) + ISNULL(CTE_GST.GSTHST,0.00) + ISNULL(CTE_QST.QST,0.00) + ISNULL(CTE_PST.PST,0.00) [TotalAmountDue]
,CurrencyCodes.ISO [Currency]
,ISNULL(CurrencyCodes.Symbol,'') 'CurrencySymbol'
,customer.IsACH
,@GenericInvoiceComment 'GenericInvoiceComment'
,customer.GenerateInvoiceAddendum
,customer.UseDynamicContentForInvoiceAddendumBody
,blend.CodeName
,blend.BlendRentalAmount * receivable.ExchangeRate [BlendRentalAmount]
,blend.BlendNumber
,blend.DetailId
,CTE_GST.GSTHST
,CTE_QST.QST
,CTE_PST.PST
,customer.GSTId
--INTO #Result
FROM InvoiceExtractCustomerDetails customer
INNER JOIN InvoiceExtractReceivableDetails receivable
ON customer.InvoiceID = receivable.InvoiceID
INNER JOIN #BlendDetails blend
ON customer.InvoiceID = blend.InvoiceID
INNER JOIN #TotalAmountDetails TA ON receivable.InvoiceID = TA.InvoiceId
AND blend.DetailId = receivable.ReceivableInvoiceDetailId
LEFT JOIN CurrencyCodes ON
CurrencyCodes.Id = receivable.AlternateBillingCurrencyCodeId
LEFT JOIN Logoes
ON customer.LogoId = Logoes.Id
LEFT JOIN CTE_GST ON customer.InvoiceID = CTE_GST.InvoiceID
LEFT JOIN CTE_PST ON customer.InvoiceID = CTE_PST.InvoiceID
LEFT JOIN CTE_QST ON customer.InvoiceID = CTE_QST.InvoiceID
LEFT JOIN CTE_SalesTax ON customer.InvoiceID = CTE_SalesTax.InvoiceID
WHERE customer.InvoiceID = @InvoiceID
--DROP TABLE #Result
DROP TABLE #TaxHeader
DROP TABLE #ImpositionDetails
DROP TABLE #TempResult
END

GO

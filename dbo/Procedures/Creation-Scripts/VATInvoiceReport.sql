SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[VATInvoiceReport]
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
DECLARE @BillToId BIGINT,@GenericInvoiceComment nvarchar(200), @DueDate Date;
Select @BillToId=ri.BillToId, @DueDate = DueDate from dbo.ReceivableInvoices ri WHERE ri.Id = @InvoiceId
SELECT @GenericInvoiceComment = comment FROM GenericInvoiceComments WHERE IsCurrent=1 AND @DueDate >= StartDate AND @DueDate <= EndDate;

CREATE TABLE #TaxRateInfo
(
BlendNumber INT,
TaxRate NVARCHAR(20),
TaxTreatment NVARCHAR(50),
TaxAmount DECIMAL(16,2),
)

CREATE TABLE #UniqueTaxRateDetails (
BlendNumber INT,
TaxRate NVARCHAR (20),
TaxTreatment NVARCHAR (50),
TaxAmount DECIMAL (16,2))

INSERT INTO #TaxRateInfo
SELECT rd.BlendNumber
,CAST(CAST(ROUND(MAX(TaxRate),2) AS NUMERIC(16,2)) AS NVARCHAR(100)) TaxRate
,MAX(TaxTreatment) TaxTreatment
,SUM(rtd.TaxAmount_Amount) TaxAmount_Amount
FROM InvoiceExtractReceivableTaxDetails rtd
JOIN InvoiceExtractReceivableDetails rd ON rtd.InvoiceId = rd.InvoiceId AND rtd.ReceivableDetailId = rd.ReceivableDetailId
WHERE rtd.InvoiceId = @InvoiceId
GROUP BY 
rd.BlendNumber
,rtd.TaxRate
,rd.InvoiceId

SELECT 
rd.BlendNumber
INTO #InvalidBlendNumbers
FROM #TaxRateInfo rd
GROUP BY rd.BlendNumber
HAVING COUNT(*)>1

UPDATE #TaxRateInfo
SET TaxRate = 'Combined'
FROM #TaxRateInfo tr
JOIN #InvalidBlendNumbers ibn ON tr.BlendNumber = ibn.BlendNumber

INSERT INTO #UniqueTaxRateDetails
SELECT BlendNumber
,MAX(TaxRate) TaxRate
,MAX(TaxTreatment) TaxTreatment
,SUM(TaxAmount) TaxAmount_Amount
FROM #TaxRateInfo
GROUP BY BlendNumber

;WITH CTE_Blend AS(
SELECT InvoiceID ,
CodeName ,
BlendRentalAmount ,
BlendTaxAmount,
BlendNumber ,
DetailId  from GetBlendDetailsForVATInvoiceFormat(@InvoiceID,@BillToId) AS blenddetails
)
SELECT
ROW_NUMBER() OVER(ORDER BY receivableTaxDetails.TaxRate) AS RowNo,
customer.RemitToName [RemitTo]
,customer.LegalEntityName [LegalEntityName]
,UPPER(customer.InvoiceType) [InvoiceType]
,customer.InvoiceNumber [InvoiceNumber]
,customer.InvoiceNumberLabel
,customer.InvoiceRunDateLabel
,customer.DueDate
,customer.CustomerName
,customer.DeliverInvoiceViaEmail
,customer.AttentionLine
,customer.LessorContactPhone
,customer.LessorContactEmail
,bt.InvoiceComment [AdditionalComments]
,customer.CustomerNumber
,customer.LessorWebAddress
,customer.LessorAddressLine1 [LessorMainAddressLine1]
,customer.LessorAddressLine2 [LessorMainAddressLine2]
,customer.LessorCity [LessorMainAddressCity]
,customer.LessorState [LessorMainAddressState]
,customer.LessorZip [LessorMainAddressZip]
,customer.LessorCountry [LessorMainAddressCountry]
,customer.LessorTaxRegistrationNumber [LessorTaxRegistrationNumber]
,customer.CustomerMainAddressLine1 [LesseeMainAddressLine1]
,customer.CustomerMainAddressLine2 [LesseeMainAddressLine2]
,customer.CustomerMainCity [LesseeMainAddressCity]
,customer.CustomerMainState [LesseeMainAddressState]
,customer.CustomerMainCountry [LesseeMainAddressCountry]
,customer.CustomerMainZip [LesseeMainAddressZip]
,customer.CustomerTaxRegistrationNumber [LesseeTaxRegistrationNumber]
,bt.Name [BillTo]
,customer.BillingAddressLine1 [BillToBillingAddressLine1]
,customer.BillingAddressLine2 [BillToBillingAddressLine2]
,customer.BillingCity		  [BillToBillingAddressCity]
,customer.BillingState		  [BillToBillingAddressState]
,customer.BillingCountry	  [BillToBillingAddressCountry]
,customer.BillingZip		  [BillToBillingAddressZip]
,customer.OriginalInvoiceNumber [OriginalInvoiceNumber]
,CASE WHEN customer.OriginalInvoiceNumber IS NULL 
	  THEN 1
	  ELSE 0 
END	  [IsCredit]
,customer.RemitToAccountNumber [BankAccountNumber]
,customer.RemitToTransitCode [SORTCode]
,customer.RemitToSWIFTCode [SWIFTCode]
,customer.RemitToIBAN [IBANCode]
,FORMAT (customer.InvoiceRunDate, 'MM/dd/yyyy ') [DateOfSupply]
,receivableTaxDetails.TaxTreatment [VATTreatment]
,customer.CreditReason [CreditReason]
,CASE WHEN Logoes.LogoImageFile_Content IS NOT NULL AND Logoes.LogoImageFile_Content <> 0x THEN
(SELECT fs.Content FROM FileStores fs WHERE fs.Guid = dbo.GetContentGuid(Logoes.LogoImageFile_Content))
ELSE NULL END 'LogoImageFile_Content'
,'image/' + Logoes.LogoImageFile_Type [LogoImageFile_Type]
,blend.CodeName [Description]
,receivableTaxDetails.TaxRate [VATRate] 
,blend.BlendRentalAmount [AmountDue]
,blend.BlendTaxAmount [VATAmountDue]
,(blend.BlendRentalAmount + blend.BlendTaxAmount) [TotalAmountDue]
,receivable.AssetPurchaseOrderNumber [PO#]
,COALESCE(CONVERT(nvarchar, receivable.PeriodStartDate,101),'-' ,CONVERT(nvarchar, receivable.PeriodEndDate,101)) [PeriodCovered]
,CurrencyCodes.ISO [Currency]
,ISNULL(CurrencyCodes.Symbol,'') 'CurrencySymbol'
,customer.IsACH [IsACH]
,@GenericInvoiceComment 'GenericInvoiceComment'
,customer.GenerateInvoiceAddendum
,customer.UseDynamicContentForInvoiceAddendumBody
FROM InvoiceExtractCustomerDetails customer
INNER JOIN InvoiceExtractReceivableDetails receivable
ON customer.InvoiceID = receivable.InvoiceID
INNER JOIN CTE_Blend blend
ON customer.InvoiceID = blend.InvoiceID
AND blend.DetailId = receivable.ReceivableInvoiceDetailId
INNER JOIN ReceivableCodes rc 
ON receivable.ReceivableCodeId = rc.Id
INNER JOIN BillToes bt 
ON customer.BillToId = bt.Id
INNER JOIN #UniqueTaxRateDetails receivableTaxDetails
ON receivable.BlendNumber = receivableTaxDetails.BlendNumber
LEFT JOIN CurrencyCodes ON
CurrencyCodes.Id = receivable.AlternateBillingCurrencyCodeId
LEFT JOIN Logoes
ON customer.LogoId = Logoes.Id
WHERE customer.InvoiceID = @InvoiceID


DROP TABLE IF EXISTS #UniqueTaxRateDetails
DROP TABLE IF EXISTS #TaxRateInfo
DROP TABLE IF EXISTS #InvalidBlendNumbers
END

GO

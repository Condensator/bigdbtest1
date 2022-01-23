SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--EXEC [VATInvoiceDataSet] @InvoiceId = 54982, @ShowPOAndComments = 0, @ShowPeriodAndComments = 0, @ShowDefault = 0, @ShowComments = 0, @ShowPeriodCovered = 0 ,@ShowPO = 0, @ShowPOAndPeriod = 0, @ShowAmount= 0,@AddendumPagesCount = 1 
CREATE PROCEDURE [dbo].[VATInvoiceDataSet]  
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
 CREATE TABLE #TaxRateInfo ( BlendNumber INT, TaxRate NVARCHAR(20), TaxTreatment NVARCHAR(50), TaxAmount DECIMAL(16,2), )   
CREATE TABLE #UniqueTaxRateDetails (  
BlendNumber INT,  
TaxRate NVARCHAR (20),  
TaxTreatment NVARCHAR (50),  
TaxAmount DECIMAL (16,2))  
 INSERT INTO #TaxRateInfo SELECT rd.BlendNumber  
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
  
DECLARE @IsClosedEndLease BIT = 0, @ContractId BIGINT, @IsLeaseVAT BIT
SELECT TOP 1 @ContractId = Entityid FROM InvoiceExtractReceivableDetails --Assuming all are CT related receivables as per BA

SELECT TOP 1  @IsClosedEndLease = QL.IsCloseEndLease, @IsLeaseVAT = LF.IsVAT
	FROM InvoiceExtractReceivableDetails A 
	JOIN ReceivableInvoiceDetails RID ON RID.ReceivableInvoiceId = A.InvoiceId AND RID.ReceivableDetailId = A.ReceivableDetailId
	JOIN LeaseFinances LF ON LF.ContractId = A.EntityId AND LF.IsCurrent = 1
	JOIN QuoteLeaseTypes QL ON QL.Id = LF.QuoteLeaseTypeId 	
	WHERE A.Invoiceid = @invoiceid

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
DetailId,
ContractCurrency,
AlternateBillingCurrency,
[BlendRentalAmountInAlternateCurrency],
[BlendTaxAmountInAlternateCurrency],
[ExchangeRate],
NBVDownPaymentAmountInAlternateCurrency,
ActualDownPaymentAmountInAlternateCurrency
from GetBlendDetailsForVATInvoiceFormatEOL(@InvoiceID,@BillToId) AS blenddetails  
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
,receivableTaxDetails.TaxTreatment [VATTreatment]  
,blend.CodeName [Description]  
,receivableTaxDetails.TaxRate [VATRate]   
,blend.BlendRentalAmount [AmountDue]  
,@GenericInvoiceComment 'GenericInvoiceComment'  
,customer.GenerateInvoiceAddendum  
,blend.ContractCurrency,
blend.AlternateBillingCurrency,
blend.[BlendRentalAmountInAlternateCurrency] [BlendRentalAmountInAlternateCurrency],
blend.[BlendTaxAmountInAlternateCurrency] [BlendTaxAmountInAlternateCurrency]
,(CASE 
	WHEN @IsClosedEndLease = 1 
		THEN (blend.[BlendRentalAmountInAlternateCurrency] - blend.NBVDownPaymentAmountInAlternateCurrency + blend.ActualDownPaymentAmountInAlternateCurrency)
	ELSE blend.[BlendRentalAmountInAlternateCurrency] END) + blend.[BlendTaxAmountInAlternateCurrency] [TotalBlendAmountInAlternateCurrency],
blend.NBVDownPaymentAmountInAlternateCurrency as NBVDownPaymentAmountInAlternateCurrency,
blend.[ExchangeRate]
, CAST(@IsClosedEndLease as BIT) as IsClosedEndLease
, CAST(@IsLeaseVAT as BIT) as IsLeaseVAT
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

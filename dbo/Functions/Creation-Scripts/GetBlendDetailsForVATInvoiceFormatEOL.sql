SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--select * from [GetBlendDetailsForVATInvoiceFormatEOL] (54920,10447)
CREATE FUNCTION [dbo].[GetBlendDetailsForVATInvoiceFormatEOL](@invoiceid BIGINT,@BillToId BIGINT)
RETURNS  @rtnTable TABLE
(
InvoiceID BIGINT,
CodeName NVARCHAR(255),
BlendRentalAmount DECIMAL(16,2),
BlendTaxAmount DECIMAL(16,2),
BlendNumber INT,
DetailId BIGINT,
ContractCurrency NVARCHAR(100),
AlternateBillingCurrency NVARCHAR(100),
[BlendRentalAmountInAlternateCurrency] DECIMAL(16,2),
[BlendTaxAmountInAlternateCurrency] DECIMAL(16,2),
[ExchangeRate] DECIMAL(16,6),
NBVDownPaymentAmountInAlternateCurrency DECIMAL(16,2),
ActualDownPaymentAmountInAlternateCurrency DECIMAL(16,2)
)
AS
BEGIN

DECLARE @SundryRT NVARCHAR(15) = 'Sundry'
DECLARE @SundrySeparateRT NVARCHAR(15) = 'SundrySeparate'
DECLARE @TaxTypeVAT NVARCHAR(15) = 'VAT'
DECLARE @IsDownPaymentBlendingApplicable BIT = (SELECT CASE WHEN [ApplicableForBlending] = 'Yes' THEN 1 ELSE 0 END FROM PayableTypeInvoiceConfigs WHERE PaymentType='DownPayment')
--DECLARE @DownPaymentInvoiceLabel NVARCHAR(100) = (SELECT InvoiceLanguageLabel FROM PayableTypeInvoiceConfigs WHERE PaymentType='DownPayment')

DECLARE @DownPaymentInvoiceLabel NVARCHAR(200) = N'Договор за финансов лизинг: {leaseNumber} Първоначална вноска: {downpaymentPercentage}'
DECLARE @IsClosedEndLease BIT = 0, @ContractId BIGINT

SELECT TOP 1 @ContractId = Entityid FROM InvoiceExtractReceivableDetails WHERE invoiceId = @invoiceid

DECLARE @CTE_LeaseDetails TABLE
(
	IsLeaseVAT BIT, InvoiceId BIGINT, ReceivableDetailId BIGINT, IsCloseEndLease BIT, DownPaymentPercentage BIGINT, SequenceNumber NVARCHAR(200), CalculatedDownPaymentAmount DECIMAL(16,2),ActualDownPaymentAmount DECIMAL(16,2), ExchangeRate DECIMAL(10,6), AlternameBillingCurrency NVARCHAR(100), PaymentType NVARCHAR(100), IsDownPaymentVATReceivable BIT 
)

INSERT INTO @CTE_LeaseDetails
SELECT LF.IsVAT, A.InvoiceId, A.ReceivableDetailId, QL.IsCloseEndLease, QD.DownPaymentPercentage, A.SequenceNumber
	, 
	CASE 
		WHEN PaymentType = 'DownPayment' THEN 
		 CASE WHEN QL.IsCloseEndLease = 0 THEN	A.ReceivableAmount_Amount ELSE 
		 (
			SELECT SUM(LA.NBV_Amount) ReceivableAmount_Amount
			FROM LeaseFinances LF 
			JOIN LeaseAssets LA ON LA.LeaseFinanceId = LF.Id AND LA.IsActive = 1
			WHERE LF.IsCurrent = 1 AND LF.ContractId = @ContractId
			GROUP BY LF.Id
		 ) END
		ELSE A.ReceivableAmount_Amount END AS CalculatedDownPaymentAmount
		,A.ReceivableAmount_Amount ActualDownPaymentAmount
	,  A.ExchangeRate, CC.ISO AlternameBillingCurrency, RID.PaymentType, A.IsDownPaymentVATReceivable
	FROM InvoiceExtractReceivableDetails A 
	JOIN InvoiceExtractReceivableTaxDetails B ON A.InvoiceId = B.InvoiceId AND A.ReceivableDetailId = B.ReceivableDetailId
	JOIN ReceivableInvoiceDetails RID ON RID.ReceivableInvoiceId = A.InvoiceId AND RID.ReceivableDetailId = A.ReceivableDetailId
	JOIN LeaseFinances LF ON LF.ContractId = A.EntityId AND LF.IsCurrent = 1
	JOIN QuoteLeaseTypes QL ON QL.Id = LF.QuoteLeaseTypeId 
	JOIN LeaseFinanceDetails LFD ON LFD.Id = LF.Id
	JOIN QuoteDownPayments QD ON QD.Id = LFD.DownPaymentPercentageId
	JOIN CurrencyCodes CC ON CC.Id = A.AlternateBillingCurrencyCodeId
	WHERE A.Invoiceid = @invoiceid AND PaymentType = 'DownPayment'

SELECT @DownPaymentInvoiceLabel = 
CASE 
WHEN A.IsCloseEndLease = 0 
THEN REPLACE(REPLACE(N'Договор за финансов лизинг: {leaseNumber} Първоначална вноска: {downpaymentPercentage}%','{leaseNumber}',A.SequenceNumber),'{downpaymentPercentage}',A.DownPaymentPercentage)
ELSE REPLACE(REPLACE(REPLACE(N'1. Доставка по договор за финансов лизинг: {leaseNumber} Първоначална вноска: {downpaymentPercentage} % (в размер на {amountAndCurrency})','{leaseNumber}',A.SequenceNumber),'{downpaymentPercentage}',A.DownPaymentPercentage),'{amountAndCurrency}',CONCAT(A.ActualDownPaymentAmount,' ',A.AlternameBillingCurrency)) END
FROM
@CTE_LeaseDetails A

;WITH CTE_BlendDetails AS
(
SELECT InvoiceExtractReceivableDetails.InvoiceId
,SUM(t2.BlendRentalAmount) [BlendRentalAmount]
,SUM(t2.BlendTaxAmount) [BlendTaxAmount]
,t2.BlendNumber [BlendNumber] 
,t2.DetailId [DetailId]
,t2.BlendCategory [BlendCategory]
,t2.CodeName [CodeName]
,rc.Id [ReceivableCodeId]
FROM InvoiceExtractReceivableDetails
JOIN
(
SELECT
	SUM(taxDetails.Rent_Amount) [BlendRentalAmount]
	,SUM(taxDetails.TaxAmount_Amount) [BlendTaxAmount]
	,InvoiceExtractReceivableDetails.BlendNumber[BlendNumber]
	,InvoiceExtractReceivableDetails.ReceivableInvoiceDetailId [DetailId]
	,BlendCategory.Id [BlendCategory]
	,CASE WHEN (rt.Name IN (@SundryRT,@SundrySeparateRT) AND RCLL.InvoiceLabel IS NOT NULL )
			THEN RCLL.InvoiceLabel
		  WHEN (InvoiceExtractReceivableDetails.IsDownPaymentVATReceivable = 1 AND @IsDownPaymentBlendingApplicable = 0) 
			THEN @DownPaymentInvoiceLabel
		  ELSE ISNULL(lang.InvoiceLabel,'')
	END [CodeName]
FROM dbo.InvoiceExtractReceivableDetails
INNER JOIN InvoiceExtractReceivableTaxDetails taxDetails ON InvoiceExtractReceivableDetails.ReceivableDetailId = taxDetails.ReceivableDetailId
AND InvoiceExtractReceivableDetails.InvoiceId = taxDetails.InvoiceId
INNER JOIN TaxTypes ON taxDetails.TaxTypeId = TaxTypes.Id
INNER JOIN dbo.ReceivableCodes rc ON rc.Id = InvoiceExtractReceivableDetails.ReceivableCodeId
INNER JOIN dbo.ReceivableTypes rt ON rc.receivableTypeId = rt.Id
INNER JOIN InvoiceGroupingParameters ON  InvoiceGroupingParameters.ReceivableCategoryId = rc.ReceivableCategoryId
	AND InvoiceGroupingParameters.receivableTypeId = rt.Id
	AND InvoiceGroupingParameters.IsActive = 1
INNER JOIN BillToes ON BillToes.Id = @BillToId
	AND BillToes.IsActive = 1
INNER JOIN dbo.BillToInvoiceParameters ON InvoiceGroupingParameters.Id = BillToInvoiceParameters.InvoiceGroupingParameterId
	AND BillToInvoiceParameters.BillToId = @BillToId
LEFT JOIN dbo.ReceivableTypeLabelConfigs rtl ON BillToInvoiceParameters.ReceivableTypeLabelId = rtl.Id
	AND rtl.IsActive = 1
LEFT JOIN dbo.ReceivableTypeLanguageLabels lang ON rtl.Id = lang.ReceivableTypeLabelConfigId
	AND lang.IsActive = 1
	AND lang.LanguageConfigId = BillToes.LanguageConfigId
LEFT JOIN dbo.ReceivableCodeLanguageLabels RCLL ON RC.Id = RCLL.ReceivableCodeId 
	AND RCLL.IsActive=1
	 AND RCLL.LanguageConfigId = BillToes.LanguageConfigId
LEFT JOIN ReceivableTypes BlendCategory ON BlendCategory.Id = BillToInvoiceParameters.BlendWithReceivableTypeId
WHERE InvoiceExtractReceivableDetails.InvoiceId = @invoiceid
GROUP BY 
InvoiceExtractReceivableDetails.BlendNumber,InvoiceExtractReceivableDetails.ReceivableInvoiceDetailId,BlendCategory.Id,lang.InvoiceLabel,RCLL.InvoiceLabel,RT.Name
,InvoiceExtractReceivableDetails.IsDownPaymentVATReceivable
)t2
ON InvoiceExtractReceivableDetails.ReceivableInvoiceDetailId = t2.DetailId
INNER JOIN dbo.ReceivableCodes rc ON rc.Id = InvoiceExtractReceivableDetails.ReceivableCodeId
INNER JOIN dbo.ReceivableTypes rt ON rc.receivableTypeId = rt.Id
GROUP BY InvoiceExtractReceivableDetails.InvoiceId
,t2.BlendNumber, t2.DetailId, t2.BlendCategory, t2.CodeName, rc.Id
)
,CTE_ReceivableCodeName AS
(
SELECT DISTINCT 
	CTE_BlendDetails.InvoiceId
	,MIN(CTE_BlendDetails.DetailId) DetailId 
	,CTE_BlendDetails.BlendNumber
	,rc.Id [ReceivableCodeId]
	,CTE_BlendDetails.CodeName
FROM CTE_BlendDetails
INNER JOIN InvoiceExtractReceivableDetails ON InvoiceExtractReceivableDetails.ReceivableInvoiceDetailId = CTE_BlendDetails.DetailId
INNER JOIN dbo.ReceivableCodes rc ON rc.Id = InvoiceExtractReceivableDetails.ReceivableCodeId
INNER JOIN dbo.ReceivableTypes rt ON rc.receivableTypeId = rt.Id
WHERE CTE_BlendDetails.BlendCategory IS NULL
GROUP BY CTE_BlendDetails.InvoiceId,CTE_BlendDetails.BlendNumber,rc.Id,CTE_BlendDetails.CodeName
)
,CTE_HeaderBlendInfo AS
(
SELECT bd.InvoiceId
,bd.BlendRentalAmount
,bd.BlendTaxAmount
,bd.BlendNumber
,bd.DetailId
,CTE_BlendDetails.ReceivableCodeId
,CTE_BlendDetails.CodeName
FROM
(SELECT CTE_BlendDetails.InvoiceId
,SUM(BlendRentalAmount) [BlendRentalAmount]
,SUM(BlendTaxAmount) [BlendTaxAmount]
,CTE_BlendDetails.BlendNumber [BlendNumber]
,MAX(CTE_BlendDetails.DetailId) [DetailId]
FROM CTE_BlendDetails
GROUP BY CTE_BlendDetails.InvoiceId,CTE_BlendDetails.BlendNumber) bd
INNER JOIN CTE_BlendDetails ON bd.DetailId = CTE_BlendDetails.DetailId
)
,CTE_CodeNameForBlendedItems AS
(
SELECT CTE_HeaderBlendInfo.InvoiceId
,ISNULL(CTE_ReceivableCodeName.CodeName,CTE_HeaderBlendInfo.CodeName) [CodeName]
,SUM(BlendRentalAmount) [BlendRentalAmount]
,SUM(BlendTaxAmount) [BlendTaxAmount]
,MIN(CTE_HeaderBlendInfo.BlendNumber) [BlendNumber]
,ISNULL(MIN(CTE_ReceivableCodeName.DetailId),CTE_HeaderBlendInfo.DetailId) [DetailId]
FROM CTE_HeaderBlendInfo
LEFT JOIN CTE_ReceivableCodeName ON CTE_HeaderBlendInfo.InvoiceId = CTE_ReceivableCodeName.InvoiceId
AND CTE_HeaderBlendInfo.BlendNumber = CTE_ReceivableCodeName.BlendNumber
GROUP BY CTE_HeaderBlendInfo.InvoiceId,CTE_ReceivableCodeName.ReceivableCodeId,CTE_HeaderBlendInfo.ReceivableCodeId
,CTE_ReceivableCodeName.CodeName,CTE_HeaderBlendInfo.CodeName,CTE_HeaderBlendInfo.DetailId
)
,CTE_UniqueBlendDetails AS
(
SELECT ROW_NUMBER()OVER(PARTITION BY CTE_CodeNameForBlendedItems.InvoiceId,BlendNumber ORDER BY DetailId DESC)
[RowNumber], InvoiceId,CodeName,BlendRentalAmount,BlendTaxAmount,BlendNumber,DetailId
FROM CTE_CodeNameForBlendedItems
)
INSERT INTO @rtnTable
SELECT A.InvoiceId,CodeName,
CASE WHEN LD.ReceivableDetailId IS NULL THEN BlendRentalAmount ELSE LD.CalculatedDownPaymentAmount END as BlendRentalAmount
--BlendRentalAmount
,BlendTaxAmount,A.BlendNumber,DetailId 
,B.ReceivableAmount_Currency ContractCurrency
,CC.ISO AlternateBillingCurrency
,CASE WHEN LD.ReceivableDetailId IS NULL THEN BlendRentalAmount ELSE LD.CalculatedDownPaymentAmount END * B.ExchangeRate as [BlendRentalAmountInAlternateCurrency]
,BlendTaxAmount * B.ExchangeRate as [BlendTaxAmountInAlternateCurrency] 
,B.ExchangeRate ExchangeRate
, CASE WHEN LD.ReceivableDetailId IS NULL THEN 0 ELSE LD.CalculatedDownPaymentAmount END * B.ExchangeRate as [NBVDownPaymentAmountInAlternateCurrency]
, CASE WHEN LD.ReceivableDetailId IS NULL THEN 0 ELSE LD.ActualDownPaymentAmount END * B.ExchangeRate as [ActualDownPaymentAmountInAlternateCurrency]
FROM CTE_UniqueBlendDetails A
JOIN InvoiceExtractReceivableDetails B on A.DetailId = B.ReceivableInvoiceDetailId
LEFT JOIN CurrencyCodes CC ON CC.Id = B.AlternateBillingCurrencyCodeId
LEFT JOIN @CTE_LeaseDetails LD ON LD.ReceivableDetailId  = B.ReceivableDetailId AND LD.PaymentType = 'DownPayment'
WHERE RowNumber = 1
RETURN

END

GO

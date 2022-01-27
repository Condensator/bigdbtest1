SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetAssetSaleBlendDetailsForVATInvoiceFormat](@InvoiceId BIGINT,@BillToId BIGINT)
RETURNS  @rtnTable TABLE
(
InvoiceID BIGINT,
CodeName NVARCHAR(255),
BlendRentalAmount DECIMAL(16,2),
BlendTaxAmount DECIMAL(16,2),
BlendNumber INT,
DetailId BIGINT
)
AS
BEGIN

DECLARE @SundryRT NVARCHAR(15) = 'Sundry'
DECLARE @SundrySeparateRT NVARCHAR(15) = 'SundrySeparate'
DECLARE @TaxTypeVAT NVARCHAR(15) = 'VAT'
DECLARE @IsDownPaymentBlendingApplicable BIT = (SELECT CASE WHEN [ApplicableForBlending] = 'Yes' THEN 1 ELSE 0 END FROM PayableTypeInvoiceConfigs WHERE PaymentType='DownPayment')
DECLARE @DownPaymentInvoiceLabel NVARCHAR(100) = (SELECT InvoiceLanguageLabel FROM PayableTypeInvoiceConfigs WHERE PaymentType='DownPayment')

;WITH CTE_BlendDetails AS
(

SELECT
	rid.ReceivableInvoiceId [InvoiceId]
	,SUM(rti.TaxableBasisAmount_Amount) [BlendRentalAmount]
	,SUM(rti.Amount_Amount) [BlendTaxAmount]
	,BlendNumber[BlendNumber]
	,rid.Id [DetailId]
	,BlendCategory.Id [BlendCategory]
	,CASE WHEN (rts.Name IN (@SundryRT,@SundrySeparateRT) AND RCLL.InvoiceLabel IS NOT NULL )
			THEN RCLL.InvoiceLabel
		  ELSE ISNULL(lang.InvoiceLabel,'')
	END [CodeName]
	,rc.Id [ReceivableCodeId]
FROM ReceivableDetails rd
INNER JOIN ReceivableInvoiceDetails rid ON  rd.Id = rid.ReceivableDetailId
INNER JOIN ReceivableTaxes rt ON rt.ReceivableId = rid.ReceivableId AND rt.IsActive = 1
INNER JOIN dbo.ReceivableTaxDetails rtd ON rtd.ReceivableDetailId = rd.Id AND rtd.IsActive = 1 -- If Tax is there active, then child details should also be active
		AND rtd.ReceivableTaxId = rt.Id
INNER JOIN ReceivableTaxImpositions rti ON rtd.Id = rti.ReceivableTaxDetailId AND rti.IsActive = 1
INNER JOIN TaxTypes ON rti.TaxTypeId = TaxTypes.Id
INNER JOIN Receivables R ON rid.ReceivableId = R.Id
INNER JOIN dbo.ReceivableCodes rc ON rc.Id = r.ReceivableCodeId
INNER JOIN dbo.ReceivableTypes rts ON rc.receivableTypeId = rts.Id
INNER JOIN InvoiceGroupingParameters ON  InvoiceGroupingParameters.ReceivableCategoryId = rc.ReceivableCategoryId
	AND InvoiceGroupingParameters.receivableTypeId = rts.Id
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
WHERE rid.ReceivableInvoiceId = @InvoiceId
GROUP BY 
BlendNumber,rid.Id,BlendCategory.Id,lang.InvoiceLabel,RCLL.InvoiceLabel,rts.Name,rc.Id,rid.ReceivableInvoiceId
)
,CTE_ReceivableCodeName AS
(
SELECT DISTINCT 
	CTE_BlendDetails.InvoiceId
	,MIN(CTE_BlendDetails.DetailId) DetailId
	,CTE_BlendDetails.BlendNumber
	,CTE_BlendDetails.ReceivableCodeId
	,CTE_BlendDetails.CodeName
FROM CTE_BlendDetails
WHERE CTE_BlendDetails.BlendCategory IS NULL
GROUP BY CTE_BlendDetails.InvoiceId,CTE_BlendDetails.BlendNumber,CTE_BlendDetails.ReceivableCodeId,CTE_BlendDetails.CodeName
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
SELECT InvoiceId,CodeName,BlendRentalAmount,BlendTaxAmount,BlendNumber,DetailId FROM CTE_UniqueBlendDetails WHERE RowNumber = 1
RETURN

END

GO

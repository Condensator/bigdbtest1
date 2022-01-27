SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetBlendDetails](@invoiceid BIGINT,@BillToId BIGINT)
RETURNS  @rtnTable TABLE
(
InvoiceID BIGINT,
CodeName NVARCHAR(255),
BlendRentalAmount DECIMAL(16,2),
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
SELECT InvoiceExtractReceivableDetails.InvoiceId
,SUM(t2.BlendRentalAmount) [BlendRentalAmount]
,t2.BlendNumber [BlendNumber] 
,t2.DetailId [DetailId]
,t2.BlendCategory [BlendCategory]
,t2.CodeName [CodeName]
,rc.Id [ReceivableCodeId]
FROM InvoiceExtractReceivableDetails
JOIN
(
SELECT
	SUM(InvoiceExtractReceivableDetails.ReceivableAmount_Amount) [BlendRentalAmount]
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
,bd.BlendNumber
,bd.DetailId
,CTE_BlendDetails.ReceivableCodeId
,CTE_BlendDetails.CodeName
FROM
(SELECT CTE_BlendDetails.InvoiceId
,SUM(BlendRentalAmount) [BlendRentalAmount]
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
[RowNumber], InvoiceId,CodeName,BlendRentalAmount,BlendNumber,DetailId
FROM CTE_CodeNameForBlendedItems
)
INSERT INTO @rtnTable
SELECT InvoiceId,CodeName,BlendRentalAmount,BlendNumber,DetailId FROM CTE_UniqueBlendDetails WHERE RowNumber = 1
RETURN
END

GO

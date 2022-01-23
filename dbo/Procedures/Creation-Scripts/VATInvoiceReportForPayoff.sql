SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[VATInvoiceReportForPayoff]
(
@InvoiceId BIGINT,
@BankAccountNumber NVARCHAR(max),  
@IBAN NVARCHAR(max),  
@SWIFTCode NVARCHAR(max),  
@TransitCode NVARCHAR(max) 
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
SELECT rid.BlendNumber
,CONCAT(CAST(MAX(rti.AppliedTaxRate) * 100 AS NVARCHAR(100)), ' %') TaxRate
,MAX(tc.TaxTreatment) TaxTreatment
,SUM(rid.TaxAmount_Amount) TaxAmount_Amount
FROM ReceivableDetails rd
JOIN ReceivableInvoiceDetails rid ON  rd.Id = rid.ReceivableDetailId
	INNER JOIN ReceivableTaxes rt ON rt.ReceivableId = rid.ReceivableId
		AND rt.IsActive = 1
	INNER JOIN dbo.ReceivableTaxDetails rtd ON rtd.ReceivableDetailId = rd.Id
		AND rtd.IsActive = 1 -- If Tax is there active, then child details should also be active
		AND rtd.ReceivableTaxId = rt.Id
	INNER JOIN ReceivableTaxImpositions rti ON rtd.Id = rti.ReceivableTaxDetailId
		AND rti.IsActive = 1
		LEFT JOIN TaxCodes tc ON rtd.TaxCodeId = tc.Id
WHERE rid.ReceivableInvoiceId = @InvoiceId
GROUP BY 
rid.BlendNumber
,rti.AppliedTaxRate
,rid.ReceivableInvoiceId

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
---------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @ReceivableCustomerList AS ReceivableCustomerCollection
DECLARE @ReceivableLEList AS ReceivableLECollection

	SELECT DISTINCT RI.Id InvoiceId,R.Id ReceivableId,R.DueDate,R.CustomerId,TSD.BuyerLocationId,TSD.TaxLevel
	INTO #RIReceivableCustomerCollection
	FROM ReceivableInvoices RI 
	JOIN ReceivableInvoiceDetails RID ON RI.Id=RID.ReceivableInvoiceId
	JOIN Receivables R ON RID.ReceivableId = R.Id
	JOIN TaxSourceDetails TSD ON R.TaxSourceDetailId = TSD.Id
	WHERE RI.Id=@InvoiceID
	
	INSERT INTO @ReceivableCustomerList 
	(ReceivableId, DueDate, CustomerId, LocationId, TaxLevel)
	SELECT ReceivableId,DueDate,CustomerId,BuyerLocationId,TaxLevel FROM #RIReceivableCustomerCollection

	SELECT InvoiceId,BuyerTax.CustomerId,TaxRegId,Row_Number() OVER(PARTITION BY InvoiceId,BuyerTax.CustomerId,TaxRegId ORDER BY InvoiceId) BTRowNumber
	INTO #CustomerTaxRegNo
	FROM GetCustomerTaxRegistrationNumber(@ReceivableCustomerList,@DueDate) BuyerTax
	JOIN #RIReceivableCustomerCollection customers ON BuyerTax.CustomerId = customers.CustomerId 
	AND customers.DueDate = BuyerTax.DueDate AND customers.BuyerLocationId = BuyerTax.LocationId
	
	;WITH cte_CustomerTaxRegNo AS
	(
	SELECT InvoiceId,CustomerId FROM #CustomerTaxRegNo
	WHERE BTRowNumber = 1
	GROUP BY InvoiceId,CustomerId
	HAVING Count(InvoiceId)>1
	)
	UPDATE #CustomerTaxRegNo
	SET TaxRegId = NULL
	FROM #CustomerTaxRegNo customerTax 
	JOIN cte_CustomerTaxRegNo cte ON customerTax.InvoiceId = cte.InvoiceId AND customerTax.CustomerId = cte.CustomerId


	SELECT DISTINCT RI.Id InvoiceId,R.Id ReceivableId,R.DueDate,R.LegalEntityId,TSD.SellerLocationId,TSD.TaxLevel 
	INTO #RIReceivableLECollection
	FROM ReceivableInvoices RI
	JOIN ReceivableInvoiceDetails RID ON RI.Id=RID.ReceivableInvoiceId
	JOIN Receivables R ON RID.ReceivableId = R.Id
	JOIN TaxSourceDetails TSD ON R.TaxSourceDetailId = TSD.Id
	WHERE RI.Id=@InvoiceID

	INSERT INTO @ReceivableLEList 
	(ReceivableId, DueDate, LegalEntityId, LocationId, TaxLevel)
	SELECT ReceivableId,DueDate,LegalEntityId,SellerLocationId,TaxLevel FROM #RIReceivableLECollection	;

SELECT InvoiceId,SellerTax.LegalEntityId,TaxRegId,Row_Number() OVER(PARTITION BY InvoiceId,SellerTax.LegalEntityId,TaxRegId ORDER BY InvoiceId) STRowNumber
	INTO #LETaxRegNo
	FROM GetLegalEntityTaxRegistrationNumber(@ReceivableLEList,@DueDate) SellerTax
	JOIN #RIReceivableLECollection les ON SellerTax.LegalEntityId = les.LegalEntityId 
	AND les.DueDate = SellerTax.DueDate AND les.SellerLocationId = SellerTax.LocationId
	
	;WITH cte_LETaxRegNo AS
	(
	SELECT InvoiceId,LegalEntityId FROM #LETaxRegNo
	WHERE STRowNumber = 1
	GROUP BY InvoiceId,LegalEntityId
	HAVING Count(InvoiceId)>1
	)
	UPDATE #LETaxRegNo
	SET TaxRegId = NULL
	FROM #LETaxRegNo leTax 
	JOIN cte_LETaxRegNo cte ON leTax.InvoiceId = cte.InvoiceId AND leTax.LegalEntityId = cte.LegalEntityId
----------------------------------------------------------------------------------------------------------------------------------------------
;WITH CTE_Blend AS(
SELECT InvoiceID ,
CodeName ,
BlendRentalAmount ,
BlendTaxAmount,
BlendNumber ,
DetailId  from GetPayoffBlendDetailsForVATInvoiceFormat(@InvoiceID,@BillToId) AS blenddetails
)
SELECT
RID.Id,
ROW_NUMBER() OVER(ORDER BY receivableTaxDetails.TaxRate) AS RowNo,
RT.Name [RemitTo]
,LE.Name [LegalEntityName]
,CASE WHEN RI.IsStatementInvoice = 0 THEN UPPER(ITL.Name) ELSE NULL END AS InvoiceType
,RI.Number [InvoiceNumber]
	,CASE 
			WHEN BT.InvoiceNumberLabel = 'InvoiceNumber'
				THEN 'Invoice Number'
			WHEN BT.InvoiceNumberLabel = 'PaymentAdviceNumber'
				THEN 'Payment Advice Number'
			WHEN BT.InvoiceNumberLabel = 'NoticeNumber'
				THEN 'Notice Number'
			WHEN BT.InvoiceNumberLabel = 'BillNumber'
				THEN 'Bill Number'
			ELSE BT.InvoiceNumberLabel
		END AS InvoiceNumberLabel					
		,CASE 
			WHEN BT.InvoiceDateLabel = 'InvoiceDate'
				THEN 'Invoice Date'
			WHEN BT.InvoiceDateLabel = 'PaymentAdviceDate'
				THEN 'Payment Advice Date'
			WHEN BT.InvoiceDateLabel = 'NoticeDate'
				THEN 'Notice Date'
			WHEN BT.InvoiceDateLabel = 'BillDate'
				THEN 'Bill Date'
			ELSE BT.InvoiceDateLabel
		END AS InvoiceDateLabel
,RI.DueDate
,BT.CustomerBillToName
,BT.DeliverInvoiceViaEmail
,CASE WHEN PC.Id IS NULL THEN '' ELSE 'ATTN: ' + PC.FullName END AS AttentionLine
,REPLACE(REPLACE(ISNULL(LeContact.PhoneNumber1, PC.PhoneNumber1), '-', ''), ' ', '') AS LessorContactPhone
,ISNULL(LeContact.EMailId, PC.EMailId) AS LessorContactEmail
,bt.InvoiceComment [AdditionalComments]
,p.PartyNumber as CustomerNumber
,p.PartyName as CustomerName
,LE.LessorWebAddress
,ISNULL(LeAddress.AddressLine1, RemitToAddress.AddressLine1) AS [LessorMainAddressLine1]
,ISNULL(LeAddress.AddressLine2, RemitToAddress.AddressLine2) AS [LessorMainAddressLine2] 
,ISNULL(LeAddress.City, RemitToAddress.City) AS [LessorMainAddressCity]
,ISNULL(LeState.ShortName, RemitToState.ShortName) [LessorMainAddressState]
,ISNULL(LeAddress.PostalCode, RemitToAddress.PostalCode) [LessorMainAddressZip]
,ISNULL(LeCountry.ShortName, RemitToCountry.ShortName) [LessorMainAddressCountry]
,letrn.TaxRegId [LessorTaxRegistrationNumber]
,CustomerMainAddress.AddressLine1 [LesseeMainAddressLine1]
,CustomerMainAddress.AddressLine2 [LesseeMainAddressLine2]
,CustomerMainAddress.City [LesseeMainAddressCity]
,CustomerMainAddressState.ShortName [LesseeMainAddressState]
,CustomerMainAddressCountry.ShortName [LesseeMainAddressCountry]
,CustomerMainAddress.PostalCode [LesseeMainAddressZip]
,ctrn.TaxRegId [LesseeTaxRegistrationNumber]
,bt.Name [BillTo]
,PA.AddressLine1 [BillToBillingAddressLine1]
,PA.AddressLine2 [BillToBillingAddressLine2]
,PA.City		  [BillToBillingAddressCity]
,ISNULL(billingState.ShortName, billingHomeState.ShortName) AS 		  [BillToBillingAddressState]
,ISNULL(billingCountry.ShortName, billingHomeCountry.ShortName) AS	  [BillToBillingAddressCountry]
,PA.PostalCode		  [BillToBillingAddressZip]
,RI.OriginalInvoiceNumber [OriginalInvoiceNumber]
,CASE WHEN RI.OriginalInvoiceNumber IS NULL 
	  THEN 1
	  ELSE 0 
END	  [IsCredit]
,@BankAccountNumber [BankAccountNumber]  
,@TransitCode  [SORTCode]  
,@SWIFTCode [SWIFTCode]  
,@IBAN  [IBANCode]  
,FORMAT (RI.InvoiceRunDate, 'MM/dd/yyyy ') [DateOfSupply]
,receivableTaxDetails.TaxTreatment [VATTreatment]
,null AS  [CreditReason]
,CASE WHEN Logoes.LogoImageFile_Content IS NOT NULL AND Logoes.LogoImageFile_Content <> 0x THEN
(SELECT fs.Content FROM FileStores fs WHERE fs.Guid = dbo.GetContentGuid(Logoes.LogoImageFile_Content))
ELSE NULL END 'LogoImageFile_Content'
,'image/' + Logoes.LogoImageFile_Type [LogoImageFile_Type]
,blend.CodeName [Description]
,receivableTaxDetails.TaxRate [VATRate] 
,blend.BlendRentalAmount [AmountDue]
,blend.BlendTaxAmount [VATAmountDue]
,(blend.BlendRentalAmount + blend.BlendTaxAmount) [TotalAmountDue]
,A.CustomerPurchaseOrderNumber [PO#]
,null [PeriodCovered] -- has issue
,CurrencyCodes.ISO [Currency]
,ISNULL(CurrencyCodes.Symbol,'') 'CurrencySymbol'
,RI.IsACH AS IsACH
,@GenericInvoiceComment 'GenericInvoiceComment'
,BT.GenerateInvoiceAddendum
,BT.UseDynamicContentForInvoiceAddendumBody
FROM ReceivableInvoices RI
	INNER JOIN ReceivableInvoiceDetails RID ON  RI.Id = RID.ReceivableInvoiceId
	INNER JOIN ReceivableDetails RD ON RID.ReceivableDetailId = RD.Id
	INNER JOIN Receivables R ON RID.ReceivableId = R.Id
	INNER JOIN BillToes BT ON RI.BillToId = BT.Id 
	INNER JOIN Customers CU ON BT.CustomerId = CU.Id
	INNER JOIN Parties P ON CU.Id = P.Id
	INNER JOIN PartyAddresses PA ON BT.BillingAddressId = PA.Id
	INNER JOIN RemitToes RT ON RI.RemitToId = RT.Id AND RT.IsActive = 1
	INNER JOIN LegalEntities LE ON RI.LegalEntityId = LE.Id
	INNER JOIN InvoiceFormats ON RI.ReportFormatId = InvoiceFormats.Id
	INNER JOIN CTE_Blend blend ON RID.ReceivableInvoiceId = blend.InvoiceID AND blend.DetailId = RID.Id
	INNER JOIN ReceivableCodes rc ON R.ReceivableCodeId = rc.Id
	INNER JOIN #UniqueTaxRateDetails receivableTaxDetails ON RID.BlendNumber = receivableTaxDetails.BlendNumber
	LEFT JOIN Assets A ON RD.AssetId = A.Id
	LEFT JOIN BillToInvoiceFormats BIF ON RI.BillToId = bif.BillToId AND RI.ReceivableCategoryId=BIF.ReceivableCategoryId
	LEFT JOIN InvoiceTypeLabelConfigs ITL ON bif.InvoiceTypeLabelId = itl.Id
	LEFT JOIN InvoiceTypes IT ON itl.InvoiceTypeId = it.Id AND InvoiceFormats.InvoiceTypeId = it.Id
	LEFT JOIN LegalEntityAddresses LeAddress ON RT.LegalEntityAddressId = LeAddress.Id
	LEFT JOIN States LeState ON LeAddress.StateId = LeState.Id
	LEFT JOIN Countries LeCountry ON LeState.CountryId = LeCountry.Id
	LEFT JOIN LegalEntityContacts LeContact ON RT.LegalEntityContactId = LeContact.Id
	LEFT JOIN PartyAddresses RemitToAddress ON RT.PartyAddressId = RemitToAddress.Id
	LEFT JOIN PartyAddresses CustomerMainAddress ON CU.Id = CustomerMainAddress.PartyId AND CustomerMainAddress.IsMain = 1
	LEFT JOIN States RemitToState ON RemitToAddress.StateId = RemitToState.Id
	LEFT JOIN Countries RemitToCountry ON RemitToState.CountryId = RemitToCountry.Id
	LEFT JOIN PartyContacts PC ON RT.PartyContactId = PC.Id
	LEFT JOIN Currencies ON Currencies.Id = RI.AlternateBillingCurrencyId
	LEFT JOIN CurrencyCodes ON CurrencyCodes.Id = Currencies.CurrencyCodeId AND CurrencyCodes.IsActive = 1
	LEFT JOIN Logoes ON RT.LogoId = Logoes.Id
	LEFT JOIN States CustomerMainAddressState ON CustomerMainAddress.StateId = CustomerMainAddressState.Id
	LEFT JOIN Countries CustomerMainAddressCountry ON CustomerMainAddressState.CountryId = CustomerMainAddressCountry.Id
	LEFT JOIN States billingState ON PA.StateId = billingState.Id
	LEFT JOIN Countries billingCountry ON billingState.CountryId = billingCountry.Id
	LEFT JOIN States billingHomeState ON PA.HomeStateId = billingHomeState.Id
	LEFT JOIN Countries billingHomeCountry ON billingHomeState.CountryId = billingHomeCountry.Id
	LEFT JOIN #CustomerTaxRegNo ctrn ON ctrn.InvoiceId = RI.Id AND ctrn.BTRowNumber = 1 AND ctrn.TaxRegId IS NOT NULL
	LEFT JOIN #LETaxRegNo letrn ON letrn.InvoiceId = RI.Id AND letrn.STRowNumber = 1 AND letrn.TaxRegId IS NOT NULL
	LEFT JOIN RemitToWireDetails RTWD ON RT.Id = RTWD.RemitToId AND RTWD.IsActive = 1
	LEFT JOIN BankAccounts BA ON RTWD.BankAccountId = BA.Id
	LEFT JOIN BankBranches BB ON BA.BankBranchId =  BB.Id
	
WHERE RI.Id = @InvoiceID


DROP TABLE IF EXISTS #UniqueTaxRateDetails
DROP TABLE IF EXISTS #TaxRateInfo
DROP TABLE IF EXISTS #InvalidBlendNumbers
END

GO

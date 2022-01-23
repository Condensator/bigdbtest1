SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PopulateInvoiceExtractCustomerDetails] (
	@JobStepInstanceId			BIGINT,
	@SourceJobStepInstanceId	BIGINT,
	@ChunkNumber				INT,
	@CreatedById				BIGINT, 
	@CreatedTime				DATETIMEOFFSET,
	@BillNegativeandZeroReceivables BIT,
	@InvoicePreference_SuppressDelivery NVARCHAR(100),
	@InvoicePreference_SuppressGeneration NVARCHAR(100),
	@InvoicePreference_GenerateAndDeliver NVARCHAR(100),
	@RemitToBankDetails RemitToBankDetail READONLY ,
	@RunDate DATETIME
)
AS
BEGIN

	CREATE TABLE #InvoiceBillToDetails_Extract (
		[BillToId]									BIGINT NOT NULL, 
		[BillingAddressId]							BIGINT, 
		[BillingContactPersonId]					BIGINT, 
		[DeliverInvoiceViaEmail]					BIT NOT NULL, 
		[AssetGroupByOption]						BIT NOT NULL, 
		[AssetGroupByOptionAttributeName]			NVARCHAR(200), 
		[UseDynamicContentForInvoiceAddendumBody]	BIT NOT NULL, 
		[GenerateInvoiceAddendum]					BIT NOT NULL, 
		[InvoiceNumberLabel]						NVARCHAR(38), 
		[InvoiceDateLabel]							NVARCHAR(34), 
		[CustomerBillToName]						NVARCHAR(500), 
		[CustomerNumber]							NVARCHAR(100),
		[CustomerComments]							NVARCHAR(200),
		[CustomerInvoiceCommentBeginDate]			DATE,
		[CustomerInvoiceCommentEndDate]				DATE,
		[PartyAttentionLine]						NVARCHAR(200),
		[BillingAddressLine1]						NVARCHAR(100),
		[BillingAddressLine2]						NVARCHAR(100),
		[BillingCity]								NVARCHAR(80),
		[BillingState]								NVARCHAR(200),
		[BillingZip]								NVARCHAR(24),
		[BillingCountry]							NVARCHAR(10),
		[CustomerMainAddressLine1]					NVARCHAR(100),
		[CustomerMainAddressLine2]					NVARCHAR(100),
		[CustomerMainCity]							NVARCHAR(80),
		[CustomerMainState]							NVARCHAR(200),
		[CustomerMainZip]							NVARCHAR(24),
		[CustomerMainCountry]						NVARCHAR(10),
	)

	CREATE NONCLUSTERED INDEX IX_BillToExtract ON #InvoiceBillToDetails_Extract(BillToId)
	
	SELECT * INTO #RemitToBankDetails FROM @RemitToBankDetails

	INSERT INTO #InvoiceBillToDetails_Extract (
		BillToId,									 
		BillingAddressId,							
		BillingContactPersonId,					
		DeliverInvoiceViaEmail,					
		AssetGroupByOption,						
		AssetGroupByOptionAttributeName,
		UseDynamicContentForInvoiceAddendumBody,
		GenerateInvoiceAddendum,					
		InvoiceNumberLabel,						
		InvoiceDateLabel,					
		CustomerBillToName,						
		CustomerNumber,							
		CustomerComments,							
		CustomerInvoiceCommentBeginDate,			
		CustomerInvoiceCommentEndDate,				
		PartyAttentionLine,						
		BillingAddressLine1,						
		BillingAddressLine2,						
		BillingCity,								
		BillingState,								
		BillingZip,								
		BillingCountry,
		CustomerMainAddressLine1,						
		CustomerMainAddressLine2,						
		CustomerMainCity,								
		CustomerMainState,								
		CustomerMainZip,								
		CustomerMainCountry
	)
	SELECT 
		BT.Id AS BillToId,			
		BT.BillingAddressId,	
		BT.BillingContactPersonId,
		BT.DeliverInvoiceViaEmail,
		BT.AssetGroupByOption,						
		agbo.AttributeName AS AssetGroupByOptionAttributeName,			
		BT.UseDynamicContentForInvoiceAddendumBody,
		BT.GenerateInvoiceAddendum,					
		CASE 
			WHEN BT.InvoiceNumberLabel = 'InvoiceNumber'
				THEN 'Invoice Number'
			WHEN BT.InvoiceNumberLabel = 'PaymentAdviceNumber'
				THEN 'Payment Advice Number'
			WHEN BT.InvoiceNumberLabel = 'NoticeNumber'
				THEN 'Notice Number'
			WHEN BT.InvoiceNumberLabel = 'BillNumber'
				THEN 'Bill Number'
			ELSE BT.InvoiceNumberLabel
		END AS InvoiceNumberLabel,						
		CASE 
			WHEN BT.InvoiceDateLabel = 'InvoiceDate'
				THEN 'Invoice Date'
			WHEN BT.InvoiceDateLabel = 'PaymentAdviceDate'
				THEN 'Payment Advice Date'
			WHEN BT.InvoiceDateLabel = 'NoticeDate'
				THEN 'Notice Date'
			WHEN BT.InvoiceDateLabel = 'BillDate'
				THEN 'Bill Date'
			ELSE BT.InvoiceDateLabel
		END AS InvoiceDateLabel,				
		BT.CustomerBillToName,	
		P.PartyNumber AS CustomerNumber,	
		CU.InvoiceComment AS CustomerComments,
		CU.InvoiceCommentBeginDate AS CustomerInvoiceCommentBeginDate,
		CU.InvoiceCommentEndDate AS CustomerInvoiceCommentEndDate,
		CASE WHEN PC.Id IS NULL THEN '' ELSE 'ATTN: ' + PC.FullName END AS PartyAttentionLine,
		PA.AddressLine1 AS BillingAddressLine1,
		PA.AddressLine2 AS BillingAddressLine2,
		PA.City AS BillingCity,
		ISNULL(billingState.ShortName, billingHomeState.ShortName) AS BillingState,		
		PA.PostalCode AS BillingZip,			
		ISNULL(billingCountry.ShortName, billingHomeCountry.ShortName) AS BillingCountry,
		CustomerMainAddress.AddressLine1 AS CustomerMainAddressLine1,
		CustomerMainAddress.AddressLine2 AS CustomerMainAddressLine2,
		CustomerMainAddress.City AS CustomerMainCity,
		CustomerMainAddressState.ShortName AS CustomerMainState,		
		CustomerMainAddress.PostalCode AS CustomerMainZip,			
		CustomerMainAddressCountry.ShortName AS CustomerMainCountry
	FROM InvoiceChunkDetails_Extract ICD
	INNER JOIN BillToes BT ON ICD.BillToId = BT.Id AND ICD.JobStepInstanceId = @JobStepInstanceId AND ICD.ChunkNumber = @ChunkNumber
	INNER JOIN Customers CU ON BT.CustomerId = CU.Id
	INNER JOIN Parties P ON CU.Id = P.Id
	INNER JOIN PartyAddresses PA ON BT.BillingAddressId = PA.Id
	LEFT JOIN States billingState ON PA.StateId = billingState.Id
	LEFT JOIN Countries billingCountry ON billingState.CountryId = billingCountry.Id
	LEFT JOIN States billingHomeState ON PA.HomeStateId = billingHomeState.Id
	LEFT JOIN Countries billingHomeCountry ON billingHomeState.CountryId = billingHomeCountry.Id
	LEFT JOIN PartyContacts PC ON BT.BillingContactPersonId = PC.Id
	LEFT JOIN BillToAssetGroupByOptions btagbo ON bt.Id = btagbo.BillToId AND btagbo.IsActive = 1 AND btagbo.IncludeInInvoice = 1
	LEFT JOIN AssetGroupByOptions agbo ON btagbo.AssetGroupByOptionId = agbo.Id
	LEFT JOIN PartyAddresses CustomerMainAddress ON CU.Id = CustomerMainAddress.PartyId AND CustomerMainAddress.IsMain = 1
	LEFT JOIN States CustomerMainAddressState ON CustomerMainAddress.StateId = CustomerMainAddressState.Id
	LEFT JOIN Countries CustomerMainAddressCountry ON CustomerMainAddressState.CountryId = CustomerMainAddressCountry.Id
	
	DECLARE @ReceivableCustomerList AS ReceivableCustomerCollection
	DECLARE @ReceivableLEList AS ReceivableLECollection

	SELECT DISTINCT RI.Id InvoiceId,R.Id ReceivableId,R.DueDate,R.CustomerId,TSD.BuyerLocationId,TSD.TaxLevel
	INTO #RIReceivableCustomerCollection
	FROM #InvoiceBillToDetails_Extract IBDE
	JOIN ReceivableInvoices RI ON IBDE.BillToId = RI.BillToId AND RI.IsActive=1
	JOIN ReceivableInvoiceDetails RID ON RI.Id=RID.ReceivableInvoiceId
	JOIN Receivables R ON RID.ReceivableId = R.Id
	JOIN TaxSourceDetails TSD ON R.TaxSourceDetailId = TSD.Id
	WHERE RI.JobStepInstanceId=@SourceJobStepInstanceId
	
	INSERT INTO @ReceivableCustomerList 
	(ReceivableId, DueDate, CustomerId, LocationId, TaxLevel)
	SELECT ReceivableId,DueDate,CustomerId,BuyerLocationId,TaxLevel FROM #RIReceivableCustomerCollection

	SELECT InvoiceId,BuyerTax.CustomerId,TaxRegId,Row_Number() OVER(PARTITION BY InvoiceId,BuyerTax.CustomerId,TaxRegId ORDER BY InvoiceId) BTRowNumber
	INTO #CustomerTaxRegNo
	FROM GetCustomerTaxRegistrationNumber(@ReceivableCustomerList,@RunDate) BuyerTax
	JOIN #RIReceivableCustomerCollection customers ON BuyerTax.CustomerId = customers.CustomerId 
	AND customers.DueDate = BuyerTax.DueDate AND customers.BuyerLocationId = BuyerTax.LocationId
	
	;WITH cte_CustomerTaxRegNo AS
	(
	SELECT InvoiceId,CustomerId FROM #CustomerTaxRegNo
	GROUP BY InvoiceId,CustomerId
	HAVING Count(InvoiceId)>1
	)
	UPDATE #CustomerTaxRegNo
	SET TaxRegId = NULL
	FROM #CustomerTaxRegNo customerTax 
	JOIN cte_CustomerTaxRegNo cte ON customerTax.InvoiceId = cte.InvoiceId AND customerTax.CustomerId = cte.CustomerId

	SELECT DISTINCT RI.Id InvoiceId,R.Id ReceivableId,R.DueDate,R.LegalEntityId,TSD.SellerLocationId,TSD.TaxLevel 
	INTO #RIReceivableLECollection
	FROM #InvoiceBillToDetails_Extract IBDE
	JOIN ReceivableInvoices RI ON IBDE.BillToId = RI.BillToId AND RI.IsActive=1
	JOIN ReceivableInvoiceDetails RID ON RI.Id=RID.ReceivableInvoiceId
	JOIN Receivables R ON RID.ReceivableId = R.Id
	JOIN TaxSourceDetails TSD ON R.TaxSourceDetailId = TSD.Id
	WHERE RI.JobStepInstanceId=@SourceJobStepInstanceId

	INSERT INTO @ReceivableLEList 
	(ReceivableId, DueDate, LegalEntityId, LocationId, TaxLevel)
	SELECT ReceivableId,DueDate,LegalEntityId,SellerLocationId,TaxLevel FROM #RIReceivableLECollection	;
	
	SELECT InvoiceId,SellerTax.LegalEntityId,TaxRegId,Row_Number() OVER(PARTITION BY InvoiceId,SellerTax.LegalEntityId,TaxRegId ORDER BY InvoiceId) STRowNumber
	INTO #LETaxRegNo
	FROM GetLegalEntityTaxRegistrationNumber(@ReceivableLEList,@RunDate) SellerTax
	JOIN #RIReceivableLECollection les ON SellerTax.LegalEntityId = les.LegalEntityId 
	AND les.DueDate = SellerTax.DueDate AND les.SellerLocationId = SellerTax.LocationId
	
	;WITH cte_LETaxRegNo AS
	(
	SELECT InvoiceId,LegalEntityId FROM #LETaxRegNo
	GROUP BY InvoiceId,LegalEntityId
	HAVING Count(InvoiceId)>1
	)
	UPDATE #LETaxRegNo
	SET TaxRegId = NULL
	FROM #LETaxRegNo leTax 
	JOIN cte_LETaxRegNo cte ON leTax.InvoiceId = cte.InvoiceId AND leTax.LegalEntityId = cte.LegalEntityId

	INSERT INTO InvoiceExtractCustomerDetails (
		InvoiceId,
		InvoiceType,
		InvoiceNumber,
		InvoiceRunDate,
		DueDate,
		BillToId,
		CustomerName,
		CustomerNumber,
		AttentionLine,
		TotalReceivableAmount_Amount,
		TotalReceivableAmount_Currency,
		TotalTaxAmount_Amount,
		TotalTaxAmount_Currency,
		RemitToName,
		LegalEntityNumber,
		LegalEntityName,
		IsACH,
		RemitToCode,
		InvoiceNumberLabel,
		InvoiceRunDateLabel,
		BillingAddressLine1,
		BillingAddressLine2,
		BillingCity,
		BillingState,
		BillingZip,
		BillingCountry,
		ReportFormatName,
		GSTId,
		LogoId,
		LessorAddressLine1,
		LessorAddressLine2,
		LessorCity,
		LessorState,
		LessorZip,
		LessorCountry,
		LessorContactPhone,
		LessorContactEmail,
		LessorWebAddress,
		CustomerComments,
		CustomerInvoiceCommentBeginDate,
		CustomerInvoiceCommentEndDate,
		GenerateInvoiceAddendum,
		AttributeName,
		UseDynamicContentForInvoiceAddendumBody,
		GroupAssets,
		DeliverInvoiceViaEmail,
		OCRMCR,
		CreatedById,
		CreatedTime,
		JobStepInstanceId,
		RemitToAccountNumber,
		RemitToIBAN,
		RemitToSWIFTCode,
		RemitToTransitCode,
		CustomerMainAddressLine1,						
		CustomerMainAddressLine2,						
		CustomerMainCity,								
		CustomerMainState,								
		CustomerMainZip,								
		CustomerMainCountry,
		LessorTaxRegistrationNumber,
		CustomerTaxRegistrationNumber,
		OriginalInvoiceNumber
		)
	SELECT 
		RI.Id AS InvoiceId,
		CASE WHEN RI.IsStatementInvoice = 0 THEN ITL.Name ELSE NULL END AS InvoiceType,
		RI.Number AS InvoiceNumber,
		RI.InvoiceRunDate AS InvoiceRunDate, 
		RI.DueDate AS DueDate, 
		IBD.BillToId AS BillToId, 
		IBD.CustomerBillToName AS [CustomerName], 
		IBD.CustomerNumber AS [CustomerNumber], 
		IBD.PartyAttentionLine AS [AttentionLine], 
		RI.InvoiceAmount_Amount AS TotalReceivableAmount_Amount, 
		RI.InvoiceAmount_Currency AS TotalReceivableAmount_Currency, 
		RI.InvoiceTaxAmount_Amount AS TotalTaxAmount_Amount, 
		RI.InvoiceTaxAmount_Currency AS TotalTaxAmount_Currency, 
		RT.Name AS RemitToName, 
		LE.LegalEntityNumber AS LegalEntityNumber, 
		LE.Name AS LegalEntityName, 
		RI.IsACH AS IsACH, 
		RT.Code AS RemitToCode, 
		IBD.InvoiceNumberLabel AS InvoiceNumberLabel,
		IBD.InvoiceDateLabel AS InvoiceRunDateLabel, 
		IBD.BillingAddressLine1 AS BillingAddressLine1, 
		IBD.BillingAddressLine2 AS BillingAddressLine2, 
		IBD.BillingCity AS BillingCity, 
		IBD.BillingState AS BillingState, 
		IBD.BillingZip AS BillingZip, 
		IBD.BillingCountry AS BillingCountry, 
		CASE WHEN RI.ReceivableTaxType = 'VAT' THEN 'VATInvoice' ELSE InvoiceFormats.ReportName END AS ReportFormatName, 
		LE.GSTId AS GSTId, 
		RT.LogoId AS LogoId, 
		ISNULL(LeAddress.AddressLine1, RemitToAddress.AddressLine1) AS LessorAddressLine1, 
		ISNULL(LeAddress.AddressLine2, RemitToAddress.AddressLine2) AS LessorAddressLine2, 
		ISNULL(LeAddress.City, RemitToAddress.City) AS LessorCity, 
		ISNULL(LeState.ShortName, RemitToState.ShortName) AS LessorState, 
		ISNULL(LeAddress.PostalCode, RemitToAddress.PostalCode) AS LessorZip, 
		ISNULL(LeCountry.ShortName, RemitToCountry.ShortName) LessorCountry, 
		REPLACE(REPLACE(ISNULL(LeContact.PhoneNumber1, RemitToContact.PhoneNumber1), '-', ''), ' ', '') AS LessorContactPhone, 
		ISNULL(LeContact.EMailId, RemitToContact.EMailId) AS LessorContactEmail, 
		LE.LessorWebAddress AS LessorWebAddress, 
		SUBSTRING(IBD.CustomerComments, 1, 500) AS CustomerComments, 
		IBD.CustomerInvoiceCommentBeginDate AS CustomerInvoiceCommentBeginDate, 
		IBD.CustomerInvoiceCommentEndDate AS CustomerInvoiceCommentEndDate, 
		IBD.GenerateInvoiceAddendum AS GenerateInvoiceAddendum, 
		IBD.AssetGroupByOptionAttributeName AS AttributeName, 
		IBD.UseDynamicContentForInvoiceAddendumBody AS UseDynamicContentForInvoiceAddendumBody, 
		IBD.AssetGroupByOption AS AssetGroupByOption, 
		IBD.DeliverInvoiceViaEmail AS DeliverInvoiceViaEmail,
		NULL AS OCRMCR,
		@CreatedById, 
		@CreatedTime, 
		@SourceJobStepInstanceId,
		RBD.BankAccountNumber AS RemitToAccountNumber,
		RBD.IBAN AS RemitToIBAN,
		RBD.SWIFTCode AS RemitToSWIFTCode,
		RBD.TransitCode AS RemitToTransitCode,
		IBD.CustomerMainAddressLine1,						
		IBD.CustomerMainAddressLine2,						
		IBD.CustomerMainCity,								
		IBD.CustomerMainState,								
		IBD.CustomerMainZip,								
		IBD.CustomerMainCountry,
		letrn.TaxRegId,
		ctrn.TaxRegId,
		RI.OriginalInvoiceNumber
	FROM ReceivableInvoices RI
	INNER JOIN #InvoiceBillToDetails_Extract IBD ON RI.BillToId = IBD.BillToId AND RI.IsActive=1
	INNER JOIN RemitToes RT ON RI.RemitToId = RT.Id AND RT.IsActive = 1
	INNER JOIN LegalEntities LE ON RI.LegalEntityId = LE.Id
	INNER JOIN InvoiceFormats ON RI.ReportFormatId = InvoiceFormats.Id
	LEFT JOIN BillToInvoiceFormats BIF ON IBD.BillToId = bif.BillToId AND RI.ReceivableCategoryId=BIF.ReceivableCategoryId
	LEFT JOIN InvoiceTypeLabelConfigs ITL ON bif.InvoiceTypeLabelId = itl.Id
	LEFT JOIN InvoiceTypes IT ON itl.InvoiceTypeId = it.Id AND InvoiceFormats.InvoiceTypeId = it.Id
	LEFT JOIN LegalEntityAddresses LeAddress ON RT.LegalEntityAddressId = LeAddress.Id
	LEFT JOIN States LeState ON LeAddress.StateId = LeState.Id
	LEFT JOIN Countries LeCountry ON LeState.CountryId = LeCountry.Id
	LEFT JOIN LegalEntityContacts LeContact ON RT.LegalEntityContactId = LeContact.Id
	LEFT JOIN PartyAddresses RemitToAddress ON RT.PartyAddressId = RemitToAddress.Id
	LEFT JOIN States RemitToState ON RemitToAddress.StateId = RemitToState.Id
	LEFT JOIN Countries RemitToCountry ON RemitToState.CountryId = RemitToCountry.Id
	LEFT JOIN PartyContacts RemitToContact ON RT.PartyContactId = RemitToContact.Id
	LEFT JOIN #RemitToBankDetails RBD ON RBD.RemitToId = RT.Id
	LEFT JOIN #CustomerTaxRegNo ctrn ON ctrn.InvoiceId = RI.Id AND ctrn.BTRowNumber = 1 AND ctrn.TaxRegId IS NOT NULL
	LEFT JOIN #LETaxRegNo letrn ON letrn.InvoiceId = RI.Id AND letrn.STRowNumber = 1 AND letrn.TaxRegId IS NOT NULL
	WHERE
	(RI.IsStatementInvoice = 1 OR (RI.IsStatementInvoice=0 AND IT.Id IS NOT NULL))
	AND StatementInvoicePreference IN (@InvoicePreference_GenerateAndDeliver,@InvoicePreference_SuppressDelivery)
	AND ((@BillNegativeandZeroReceivables = 0 AND (InvoiceAmount_Amount > 0 OR InvoiceTaxAmount_Amount > 0 OR Balance_Amount > 0 OR TaxBalance_Amount > 0))
	OR @BillNegativeandZeroReceivables = 1) AND RI.JobStepInstanceId=@SourceJobStepInstanceId
	
	DROP TABLE IF EXISTS #RIReceivableCustomerCollection
	DROP TABLE IF EXISTS #RIReceivableLECollection
	DROP TABLE IF EXISTS #CustomerTaxRegNo
	DROP TABLE IF EXISTS #LETaxRegNo
	DROP TABLE IF EXISTS #RemitToBankDetails
	DROP TABLE IF EXISTS #InvoiceBillToDetails_Extract
END

GO

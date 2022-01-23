SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[ExtractDataForInvoiceGenerationForExternalModules_Contract] (
	@JobStepInstanceId BIGINT,
	@LegalEntityIds IdCollection READONLY,
	@ReceivableDetailIds IdCollection READONLY,
	@CreatedById BIGINT,
	@CreatedTime DATETIMEOFFSET,
	@ContractFilterEntityType_Lease NVARCHAR(100),
	@ContractFilterEntityType_Loan NVARCHAR(100),
	@ReceivableType_LeasePayOff NVARCHAR(100),
	@ReceivableType_BuyOut NVARCHAR(100),
	@SyndicationType_None NVARCHAR(100),
	@SyndicationType_Unknown NVARCHAR(100),
	@ReceivableEntityType_CT NVARCHAR(100)
	)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @True AS BIT = CONVERT(BIT, 1)
	DECLARE @False AS BIT = CONVERT(BIT, 0)
	DECLARE @PaymentType_DownPayment NVARCHAR(11) = 'DownPayment'
	DECLARE @ReceivableTaxType_VAT NVARCHAR(3) = 'VAT'

	SELECT * INTO #LegalEntityIds FROM @LegalEntityIds
	SELECT * INTO #ReceivableDetailIds FROM @ReceivableDetailIds

	SELECT Id, [Name], IsRental
	INTO #AllowedReceivableTypes
	FROM ReceivableTypes
	WHERE [Name] NOT IN ( @ReceivableType_LeasePayOff, @ReceivableType_BuyOut) 

	INSERT INTO InvoiceReceivableDetails_Extract (
		ReceivableId,
		EntityType,
		ContractId,
		DiscountingId,
		IsSyndicated,
		CustomerId,
		ReceivableDueDate,
		RemitToId,
		TaxRemitToId,
		LegalEntityId,
		IsPrivateLabel,
		IsDSL,
		ExchangeRate,
		AlternateBillingCurrencyId,
		ReceivableDetailId,
		BillToId,
		ReceivableDetailAmount,
		ReceivableDetailBalance,
		ReceivableDetailEffectiveBalance,
		AssetId,
		AdjustmentBasisReceivableDetailId,
		CapSoftAssetId,
		AdjustmentReceivableInvoiceId,
		IsWithHoldingTaxAssessed,
		WithHoldingTaxBalance,
		LocationId,
		ReceivableCategoryId,
		ReceivableCategoryName,
		ReceivableTypeId,
		ReceivableTypeName,
		IsReceivableTypeRental,
		ReceivableCodeId,
		DefaultInvoiceReceivableGroupingOption,
		InvoiceDueDateCalculation,
		CurrencyId,
		CurrencyISO,
		ACHScheduleId,
		IsACH,
		ContractType,
		InvoiceComment,
		CT_InvoiceLeadDays,
		CT_InvoiceTransitDays,
		CU_InvoiceLeadDays,
		CU_InvoiceTransitDays,
		SplitByReceivableAdjustments,
		SplitCreditsByOriginalInvoice,
		SplitLeaseRentalInvoiceByLocation,
		SplitRentalInvoiceByAsset,
		SplitRentalInvoiceByContract,
		SplitReceivableDueDate,
		SplitCustomerPurchaseOrderNumber,
		GenerateSummaryInvoice,
		GenerateStatementInvoice,
		InvoiceDueDate,
		OriginalTaxBalance,
		OriginalEffectiveTaxBalance,
		ReceivableAmount,
		TaxAmount,
		LegalEntityNumber,
		CustomerNumber,
		CustomerName,
		SequenceNumber,
		RemitToName,
		AlternateBillingCurrencyISO,
		JobStepInstanceId,
		CreatedById,
		CreatedTime,
		GroupNumber,
		SplitNumber,
		BlendNumber,
		InvoiceFormatId,
		IsFunderOwnedReceivable,
		IsDiscountingProceeds,
		AssetPurchaseOrderNumber,
		IsActive,
		ReceivableTaxType,
		DealCountryId,
		PaymentScheduleId,
		PaymentType,
		IsDownPaymentVATReceivable
		)
	SELECT R.Id AS ReceivableId,
		R.EntityType,
		C.Id AS ContractId,
		NULL AS DiscountingId,
		CASE WHEN ( C.SyndicationType = @SyndicationType_None OR C.SyndicationType = @SyndicationType_Unknown ) THEN @False ELSE @True END AS IsSyndicated,
		CU.Id AS CustomerId,
		R.DueDate AS ReceivableDueDate,
		RTO.Id AS RemitToId,
		R.TaxRemitToId,
		LE.Id AS LegalEntityId,
		R.IsPrivateLabel,
		R.IsDSL,
		R.ExchangeRate,
		R.AlternateBillingCurrencyId,
		RD.Id AS ReceivableDetailId,
		B.Id AS BillToId,
		RD.Amount_Amount AS ReceivableDetailAmount,
		RD.Balance_Amount AS ReceivableDetailBalance,
		RD.EffectiveBalance_Amount AS ReceivableDetailEffectiveBalance,
		RD.AssetId AS AssetId,
		RD.AdjustmentBasisReceivableDetailId,
		NULL AS CapSoftAssetId, --Remove Column
		AdjustmentReceivableInvoiceId = CAST(NULL AS BIGINT),
		@False AS IsWithHoldingTaxAssessed, --Remove Column
		0.00 AS WithHoldingTaxBalance,
		NULL AS LocationId,
		RCTG.Id AS ReceivableCategoryId,
		RCTG.[Name] AS ReceivableCategoryName,
		RT.Id AS ReceivableTypeId,
		RT.[Name] AS ReceivableTypeName,
		RT.IsRental AS IsReceivableTypeRental,
		RC.Id AS ReceivableCodeId,
		RC.DefaultInvoiceReceivableGroupingOption,
		LE.InvoiceDueDateCalculation,
		Currencies.Id AS CurrencyId,
		CCC.ISO AS CurrencyISO,
		NULL AS ACHScheduleId,
		@False AS IsACH,
		C.ContractType,
		C.InvoiceComment AS ContractInvoiceComment,
		CB.InvoiceLeaddays AS CT_InvoiceLeadDays,
		CB.InvoiceTransitDays AS CT_InvoiceTransitDays,
		CU.InvoiceLeadDays AS CU_InvoiceLeadDays,
		CU.InvoiceTransitDays AS CU_InvoiceTransitDays,
		B.SplitByReceivableAdjustments,
		B.SplitCreditsByOriginalInvoice,
		B.SplitLeaseRentalInvoiceByLocation,
		B.SplitRentalInvoiceByAsset,
		B.SplitRentalInvoiceByContract,
		B.SplitReceivableDueDate,
		B.SplitCustomerPurchaseOrderNumber,
		B.GenerateSummaryInvoice,
		B.GenerateStatementInvoice,
		NULL AS InvoiceDueDate,
		0.00 AS OriginalTaxBalance,
		0.00 AS OriginalTaxEffectiveBalance,
		RD.Amount_Amount AS ReceivableAmount,
		0.00,
		LE.LegalEntityNumber,
		Party.PartyNumber AS CustomerNumber,
		Party.PartyName AS CustomerName,
		C.SequenceNumber,
		RTO.Name AS RemitToName,
		NULL AS AlternateBillingCurrencyISO,
		@JobStepInstanceId AS JobStepInstanceId,
		@CreatedById,
		@CreatedTime,
		0,
		0,
		0,
		0,
		CASE WHEN R.IsServiced = 1 AND R.IsCollected = 0 AND (R.FunderId IS NOT NULL
				OR (R.ReceivableTaxType = 'VAT' AND R.CreationSourceTable = 'ReceiptApplication' 
					AND R.CreationSourceId IS NOT NULL AND R.SourceTable = 'Sundry'))
			THEN 
				@True 
			ELSE 
				@False 
		END AS IsFunderOwnedReceivable,
		CASE WHEN R.CreationSourceTable <> 'ReceiptApplication' AND
				R.IsServiced = 1 AND R.IsCollected = 0 AND R.FunderId IS NULL THEN @True ELSE @False END AS IsDiscountingProceeds,
		NULL AS AssetPurchaseOrderNumber,
		@False,
		R.ReceivableTaxType,
		R.DealCountryId,
		R.PaymentScheduleId,
		NULL AS PaymentType,
		0 AS IsDownPaymentVATReceivable
	FROM ReceivableDetails RD
	INNER JOIN #ReceivableDetailIds RDE ON RD.Id = RDE.Id
	INNER JOIN Receivables R ON R.Id = RD.ReceivableId
		AND RD.IsActive = 1
	INNER JOIN LegalEntities LE ON R.LegalEntityId = LE.Id
		AND R.IsActive = 1
	INNER JOIN #LegalEntityIds LEI ON LE.Id = LEI.Id
	INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
	INNER JOIN ReceivableCategories RCTG ON RC.ReceivableCategoryId = RCTG.Id
	INNER JOIN #AllowedReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
	INNER JOIN Customers CU ON CU.Id = R.CustomerId
	INNER JOIN Parties Party ON CU.Id = Party.Id
	INNER JOIN BillToes B ON RD.BillToId = B.Id
	INNER JOIN BillToInvoiceParameters BTIP ON B.Id = BTIP.BillToId
		AND BTIP.IsActive = 1
	INNER JOIN InvoiceGroupingParameters IGP ON BTIP.InvoiceGroupingParameterId = IGP.Id 
		AND RT.Id = IGP.ReceivableTypeId
		AND RCTG.Id = IGP.ReceivableCategoryId
		AND IGP.IsActive=1
	INNER JOIN CurrencyCodes CCC ON CCC.ISO = RD.Amount_Currency
		AND CCC.IsActive = 1
	INNER JOIN Currencies ON CCC.Id = Currencies.CurrencyCodeId
		AND Currencies.IsActive = 1
	INNER JOIN RemitToes RTO ON R.RemitToId = RTO.Id
	INNER JOIN Contracts C ON R.EntityId = C.Id
		AND R.EntityType = @ReceivableEntityType_CT
	INNER JOIN ContractBillings CB ON C.Id = CB.Id
		AND CB.IsActive = 1

	CREATE TABLE #DownPaymentReceivableIds
	(
	ReceivableId BIGINT,
	PaymentType NVARCHAR(40)
	)

	INSERT INTO #DownPaymentReceivableIds
	SELECT IRDE.ReceivableId,LSPS.PaymentType
	FROM InvoiceReceivableDetails_Extract IRDE
	JOIN LeasePaymentSchedules LSPS
		ON IRDE.PaymentScheduleId = LSPS.Id AND IRDE.ContractType = @ContractFilterEntityType_Lease
	WHERE LSPS.PaymentType=@PaymentType_DownPayment AND IRDE.ReceivableTaxType=@ReceivableTaxType_VAT AND IRDE.JobStepInstanceId = @JobStepInstanceId
	
	INSERT INTO #DownPaymentReceivableIds
	SELECT IRDE.ReceivableId,LNPS.PaymentType
	FROM InvoiceReceivableDetails_Extract IRDE
	JOIN LoanPaymentSchedules LNPS
		ON IRDE.PaymentScheduleId = LNPS.Id AND IRDE.ContractType=@ContractFilterEntityType_Loan
	WHERE LNPS.PaymentType=@PaymentType_DownPayment AND IRDE.ReceivableTaxType=@ReceivableTaxType_VAT AND IRDE.JobStepInstanceId = @JobStepInstanceId

	UPDATE InvoiceReceivableDetails_Extract
	SET IsDownPaymentVATReceivable = CASE WHEN #DownPaymentReceivableIds.PaymentType = @PaymentType_DownPayment THEN 1 ELSE 0 END
	,PaymentType = #DownPaymentReceivableIds.PaymentType
	FROM InvoiceReceivableDetails_Extract
	JOIN #DownPaymentReceivableIds ON #DownPaymentReceivableIds.ReceivableId=InvoiceReceivableDetails_Extract.ReceivableId
	
	DROP TABLE #DownPaymentReceivableIds
	DROP TABLE #LegalEntityIds
	DROP TABLE #ReceivableDetailIds
	DROP TABLE #AllowedReceivableTypes
END

GO

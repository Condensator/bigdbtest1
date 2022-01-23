SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetDataForAutoPayoffCreation]
(
	 @AutoPayoffInputs AutoPayoffInput READONLY,
	 @FixedTermPaymentType NVARCHAR(9), 
	 @OTPPaymentType NVARCHAR(9),
	 @SupplementPaymentType NVARCHAR(9),
	 @SyndicationUnknownType NVARCHAR(30),
	 @SyndicationNoneType NVARCHAR(30),
	 @ReceivableForTransferApprovalStatusType NVARCHAR(30),
	 @OperatingContractType NVARCHAR(30),
	 @ChargeOffUnknownStatus NVARCHAR(30),
	 @SyndicationIsSaleOfPaymentsType NVARCHAR(30),
	 @PayoffTemplateTerminationBuyoutType NVARCHAR(30),
	 @PayoffTemplateTerminationTradeUpType NVARCHAR(30),
	 @PayoffAssetStatusPurchaseType NVARCHAR(30),
	 @PayoffAssetStatusReturnToUpgradeType NVARCHAR(30),
	 @PayoffAssetStatusReturnType NVARCHAR(30),
	 @GLTransactionOperatingLeasePayoffType NVARCHAR(30),
	 @GLTransactionCapitalLeasePayoffType NVARCHAR(30),
	 @GLTransactionBookDepreciationType NVARCHAR(30),
	 @GLTransactionTaxDepDisposalType NVARCHAR(30),
	 @LeaseContractOperatingType NVARCHAR(30),
	 @SyndicationApprovedStatus NVARCHAR(30),
	 @ReceivableType_LeasePayoff NVARCHAR(30),
	 @ReceivableType_Buyout NVARCHAR(30),
	 @ReceivableType_Sundry NVARCHAR(30),
	 @ReceivableType_SundrySeperate NVARCHAR(30),
	 @GLTransType_PayoffBuyoutAR  NVARCHAR(30),
	 @GLTransType_NonRentalAR  NVARCHAR(30),
	 @RecCategory_Payoff NVARCHAR(30),
	 @RecCategory_Misc NVARCHAR(30),
	 @RecCategory_Recovery NVARCHAR(30),
	 @WriteDownApprovedStatus NVARCHAR(30),
	 @AccountingTreatmentCashBasedType NVARCHAR(30),
	 @LocationApprovedStatus NVARCHAR(20),
	 @WriteDownSourceModule NVARCHAR(22),
	 @ReceivableCategory_Payoff NVARCHAR(30)
)
AS
BEGIN
SET NOCOUNT ON;
SELECT  LeaseFinanceId = LF.Id,
		ContractId = LF.ContractId,
		SequenceNumber = CON.SequenceNumber,
		PortfolioId = PP.PortfolioId,
		LeaseCustomerId = LF.CustomerId,
		LeaseCustomerNumber = Party.PartyNumber,
		LegalEntityId = LE.Id,
		LegalEntityNumber = LE.LegalEntityNumber,
		LegalEntityName = LE.Name,
		LegalEntitySalesTaxRemittanceMethod = LE.TaxRemittancePreference,
		DueDate = DATEADD(DAY, 1, API.PayoffEffectiveDate),
		CommencementDate = LFD.CommencementDate,
		MaturityDate = LFD.MaturityDate,
		PayoffEffectiveDate = API.PayoffEffectiveDate,
		CurrencyId = Currency.Id,
		CurrencyISO = CurrencyCode.ISO,
		LineofBusinessId = LF.LineofBusinessId,
		InstrumentTypeId = LF.InstrumentTypeId,
		CostCenterId = LF.CostCenterId,
		InvoiceFormatId = BillToFormat.InvoiceFormatId,
		InvoiceOutputFormat = BillToFormat.InvoiceOutputFormat,
		BranchId = LF.BranchId,
		DealProductTypeId = DPT.Id,
		DealProductType = DPT.[Name],
		LeaseContractType = LFD.LeaseContractType,
		LeasePaymentFrequency = LFD.PaymentFrequency,
		LeaseNumberOfPayments = LFD.NumberOfPayments,
		LeaseDayCountConvention = LFD.DayCountConvention,
		IsAdvanceLease = LFD.IsAdvance,
		LeaseBookingGLTemplateId = LFD.LeaseBookingGLTemplateId,
		LeaseIncomeGLTemplateId = LFD.LeaseIncomeGLTemplateId,		
		LastPaymentScheduleId = CASE 
									WHEN API.PayoffEffectiveDate > LFD.CommencementDate
									THEN LPS.Id 
									ELSE NULL 
								END,
		PaymentScheduleNumber = LPS.PaymentNumber,
		CustomerFacingYield = LFD.CustomerFacingYield,
		TermInMonths = LFD.TermInMonths,
		LastExtensionARUpdateRunDate = LFD.LastExtensionARUpdateRunDate,
		LastSupplementalARUpdateRunDate = LFD.LastSupplementalARUpdateRunDate,
		OriginatorID = CASE WHEN OST.IsDirect = 0 THEN CO.OriginationSourceId END, 
		OriginationSourceType = OST.[Name],
		CO.OriginationScrapeFactor,
		CO.OriginatorPayableRemitToId,
		OriginationScrapePayableCodeId = CO.ScrapePayableCodeId,
		BillToId = CON.BillToId,
		RemitToId = CON.RemitToId,
		IsOperatingLease = CAST(CASE WHEN [LeaseContractType] = @OperatingContractType THEN 1 ELSE 0 END AS BIT),
		IsChargedOffLease = CAST(CASE WHEN CON.ChargeOffStatus <> @ChargeOffUnknownStatus THEN 1 ELSE 0 END AS BIT),
		IsTiedDiscountingExists = CAST(CASE WHEN (ISNULL(CON.DiscountingSharedPercentage, 0.00) <> 0.00) THEN 1 ELSE 0 END AS BIT),
		ContractSalesTaxRemittanceMethod = CON.SalesTaxRemittanceMethod,
		SyndicationType = CON.SyndicationType,
		SyndicationQuoteName = ReceivableForTransfers.[Name],
		SyndicationEffectiveDate = ReceivableForTransfers.EffectiveDate,
		SyndicationScrapeRemitToId = ISNULL(LRemitTo.RemitToId,CON.RemitToId), 
		SyndicationRentalProceedsPayableCodeId = PayableCodes.Id,
		SyndicationRentalProceedsPayableCodeName = PayableCodes.[Name],
		SyndicationScrapeReceivableCodeId = ReceivableForTransfers.ScrapeReceivableCodeId,
		PurchaseOption = LFD.PurchaseOption,
		TotalEconomicLifeInMonths = LFD.TotalEconomicLifeInMonths,
		RemainingEconomicLifeInMonths = LFD.RemainingEconomicLifeInMonths,
        IsBargainPurchaseOption = LFD.IsBargainPurchaseOption,
        IsTransferOfOwnership = LFD.IsTransferOfOwnership,
        IsSpecializedUseAssets = LFD.IsSpecializedUseAssets,		
        TotalEconomicLifeTestResult = LFD.TotalEconomicLifeTestResult,
        NinetyPercentTestPresentValue = LFD.NinetyPercentTestPresentValue_Amount,
        NinetyPercentTestResult = LFD.NinetyPercentTestResult,
        NinetyPercentTestResultPassed = LFD.NinetyPercentTestResultPassed,
        NinetyPercentTestPresentValue5A = LFD.NinetyPercentTestPresentValue5A_Amount,
        NinetyPercentTestPresentValue5B = LFD.NinetyPercentTestPresentValue5B_Amount,
        NinetyPercent5ATestResultPassed = LFD.NinetyPercent5ATestResultPassed,
        NinetyPercent5BTestResultPassed = LFD.NinetyPercent5BTestResultPassed,
        NinetyPercent5ATestResult = LFD.NinetyPercent5ATestResult,
        NinetyPercent5BTestResult = LFD.NinetyPercent5BTestResult,
        ClassificationContractType = LFD.ClassificationContractType,
        LessorYield = LFD.LessorYield,
        LessorYieldLeaseAsset = LFD.LessorYieldLeaseAsset,
        LessorYieldFinanceAsset = LFD.LessorYieldFinanceAsset,
        ClassificationYield = LFD.ClassificationYield,
        ClassificationYield5A = LFD.ClassificationYield5A,
        ClassificationYield5B = LFD.ClassificationYield5B,
		IsTaxLease = LFD.IsTaxLease,
		BillToLocationId = BillTo.LocationId,
		ReceivableAmendmentType = CON.ReceivableAmendmentType,
		PayoffAssetStatus = CASE WHEN PTC.Name = @PayoffTemplateTerminationBuyoutType THEN @PayoffAssetStatusPurchaseType
								WHEN PTC.Name = @PayoffTemplateTerminationTradeUpType THEN   @PayoffAssetStatusReturnToUpgradeType
								ELSE @PayoffAssetStatusReturnType END,
		GlFinancialPeriodFromDate = GLOP.FromDate,
		IsBusinessDateApplicable = CAST(CASE WHEN PP.[Value] = 'true' THEN 1 ELSE 0 END AS BIT),
		CurrentBusinessDate = BU.CurrentBusinessDate,	
		AutoPayoffTemplateId = APT.Id,
		AutoPayoffTemplateName = CAST(APT.[Name] AS NVARCHAR(100)),
		PayoffTemplateId = APT.PayoffTemplateId,
		PayOffTemplateTerminationTypeId = PTT.Id,
		PT.TemplateName,
		TerminationTypeName = PTC.[Name],
		LOBDiscountRate = LOB.DiscountRate,
		IsTradeupFeeApplicable = PT.TradeupFeeApplicable,
		TradeupFlatFeeAmount = PT.TradeupFeeAmount,
		PT.PayoffTradeUpFeeId,
		TradeUpFeeReceivableCodeId = PT.ReceivableCodeId,
		PT.TradeupFeeCalculationMethod,
		PT.TemplateType,
		PTC.RelatedOption,
		IsConditionalCalculation = PTT.ConditionalCalculation,
		ExpressionQuery = Expression.Query,
		GLConfigurationId = LE.GLConfigurationId,		
		IsBillInAlternateCurrency = LF.IsBillInAlternateCurrency,		
		OperatingLeasePayoffGLTemplateId = APTLE.OperatingLeasePayoffGLTemplateId,
		CapitalLeasePayoffGLTemplateId = APTLE.CapitalLeasePayoffGLTemplateId,
		InventoryBookDepGLTemplateId = APTLE.InventoryBookDepGLTemplateId,
		TaxDepDisposalTemplateId = APTLE.TaxDepDisposalGLTemplateId,		
		FixedTermReceivableCodeGLTemplateId = FTR.GLTemplateId,
		OTPReceivableCodeGLTemplateId = OTPR.GLTemplateId,
		SupplementalReceivableCodeGLTemplateId = SR.GLTemplateId,
		OTPIncomeGLTemplateId = LFD.OTPIncomeGLTemplateId,
		FloatRateARReceivableGLTemplateId = FLR.GLTemplateId,
		FloatIncomeGLTemplateId = LFD.FloatIncomeGLTemplateId,
		PayoffReceivableCodeId = APTLE.PayoffReceivableCodeId,
		BuyoutReceivableCodeId = APTLE.BuyoutReceivableCodeId,
		SundryReceivableCodeId = APTLE.SundryReceivableCodeId,
		OTPAccountingTreatment = OTPR.AccountingTreatment,
		SupplementalAccountingTreatment = SR.AccountingTreatment,
		NonAccuralDate = CON.NonAccrualDate,
		TaxAssessmentLevel = CON.TaxAssessmentLevel,
		PayoffAtFixedTerm = API.PayoffAtFixedTerm,
		ActivatePayoffQuote = API.ActivatePayoffQuote
	INTO #LeaseDetails
	FROM @AutoPayoffInputs API 
	     JOIN LeaseFinances LF ON API.LeaseFinanceId = LF.Id AND LF.IsCurrent = 1
		 JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
		 JOIN Contracts CON ON LF.ContractId = CON.Id
		 JOIN Parties Party ON LF.CustomerId = Party.Id
		 JOIN Currencies Currency ON CON.CurrencyId = Currency.Id
		 JOIN CurrencyCodes CurrencyCode ON Currency.CurrencyCodeId = CurrencyCode.Id
		 LEFT JOIN BillToes BillTo ON CON.BillToId = BillTo.Id
		 JOIN LegalEntities LE ON LF.LegalEntityId = LE.Id
		 JOIN GLFinancialOpenPeriods GLOP ON LE.Id = GLOP.LegalEntityId AND GLOP.IsCurrent = 1
		 JOIN LeasePaymentSchedules LPS  ON LFD.Id = LPS.LeaseFinanceDetailId
		 JOIN ContractOriginations CO ON LF.ContractOriginationId = CO.Id
		 JOIN OriginationSourceTypes OST ON CO.OriginationSourceTypeId = OST.Id
		 JOIN DealProductTypes DPT ON CON.DealProductTypeId = DPT.Id
		 JOIN AutoPayoffTemplates APT ON APT.Id = API.AutoPayoffTemplateId
		 LEFT JOIN AutoPayoffTemplateLegalEntities APTLE ON APTLE.AutoPayoffTemplateId = APT.Id AND APTLE.LegalEntityId = LE.Id
		 JOIN PayOffTemplates PT ON APT.PayoffTemplateId = PT.Id
		 JOIN PayoffTemplateTerminationTypeConfigs PTC ON APT.PayoffTemplateTerminationTypeConfigId = PTC.Id
		 JOIN PayOffTemplateTerminationTypes PTT ON PT.Id = PTT.PayoffTemplateId AND PTC.Id = PTT.PayoffTemplateTerminationTypeConfigId
		 LEFT JOIN PayOffTemplateLOBs LOB ON PT.Id = LOB.PayoffTemplateId AND LOB.LineofBusinessId = LF.LineofBusinessId AND LOB.IsActive = 1
		 JOIN BusinessUnits BU ON LE.BusinessUnitId = BU.Id
		 JOIN Portfolios P ON BU.PortfolioId = P.Id
		 JOIN PortfolioParameters PP ON P.Id = PP.PortfolioId
		 JOIN PortfolioParameterConfigs PPC ON PP.PortfolioParameterConfigId = PPC.Id AND PPC.[Name] = 'IsBusinessDateApplicable' AND PPC.Category = 'BusinessUnit'
		 LEFT JOIN ReceivableCodes FTR ON LFD.FixedTermReceivableCodeId = FTR.Id
		 LEFT JOIN ReceivableCodes OTPR ON LFD.OTPReceivableCodeId = OTPR.Id
		 LEFT JOIN ReceivableCodes SR ON LFD.SupplementalReceivableCodeId = SR.Id
		 LEFT JOIN ReceivableCodes FLR ON LFD.FloatRateARReceivableCodeId = FLR.Id
		 LEFT JOIN LegalEntityRemitToes LRemitTo ON LE.Id = LRemitTo.LegalEntityId AND LRemitTo.IsDefault = 1 AND LRemitTo.IsActive = 1
		 LEFT JOIN PayoffTerminationExpressions Expression ON  PTT.PayoffTerminationExpressionId = Expression.Id
		 LEFT JOIN ReceivableForTransfers ON CON.Id = ReceivableForTransfers.ContractId AND ReceivableForTransfers.ApprovalStatus = @ReceivableForTransferApprovalStatusType
		 LEFT JOIN PayableCodes ON ReceivableForTransfers.RentalProceedsPayableCodeId = PayableCodes.Id
		 LEFT JOIN BillToInvoiceFormats BillToFormat ON CON.BillToId = BillToFormat.BillToId AND BillToFormat.ReceivableCategory = @ReceivableCategory_Payoff AND BillToFormat.IsActive = 1
 	WHERE LPS.PaymentType IN ( @FixedTermPaymentType , @OTPPaymentType , @SupplementPaymentType)
		  AND (LPS.EndDate = API.PayoffEffectiveDate OR (LPS.StartDate = API.PayoffEffectiveDate AND LPS.PaymentNumber = 1))
		  AND LPS.IsActive = 1;

	SELECT
		LeaseFinanceId = Header.LeaseFinanceId,
		BillToId = LA.BillToId,
		BillToLocationId = BillTo.LocationId,
		InvoiceFormatId = BillToFormat.InvoiceFormatId,
		InvoiceOutputFormat = BillToFormat.InvoiceOutputFormat,
		Row_Num = ROW_NUMBER() OVER (PARTITION BY LA.LeaseFinanceId ORDER BY LA.CustomerCost_Amount DESC, LA.Id ASC)
	INTO #LeaseBillToDetailInfo
	FROM #LeaseDetails Header
	JOIN LeaseAssets LA ON Header.LeaseFinanceId = LA.LeaseFinanceId AND LA.IsActive = 1
	JOIN BillToes BillTo ON LA.BillToId = BillTo.Id
	LEFT JOIN BillToInvoiceFormats BillToFormat ON LA.BillToId = BillToFormat.BillToId AND BillToFormat.ReceivableCategory = @ReceivableCategory_Payoff AND BillToFormat.IsActive = 1

	SELECT
		LeaseFinanceId,
		BillToId,
		BillToLocationId,
		InvoiceFormatId,
		InvoiceOutputFormat
	INTO #LeaseBillToDetails
	FROM #LeaseBillToDetailInfo
 	WHERE Row_Num = 1

    SELECT 
		 LeaseFinanceId = Header.LeaseFinanceId,
		 IsSyndicationServiced = RTS.IsServiced,
		 IsSyndicationCollected = RTS.IsCollected,
		 IsSyndicationPrivateLabel = RTS.IsPrivateLabel,
		 IsSyndicationPerfectPay = RTS.IsPerfectPay,
		 Row_Num = ROW_NUMBER() OVER (PARTITION BY Header.LeaseFinanceId ORDER BY RTS.EffectiveDate DESC)
	INTO #SyndicationServicingDetailInfo
	FROM #LeaseDetails Header
	JOIN ReceivableForTransfers RT ON Header.ContractId = RT.ContractId 
	JOIN ReceivableForTransferServicings RTS ON RT.Id = RTS.ReceivableForTransferId
	WHERE Header.SyndicationType NOT IN (@SyndicationNoneType, @SyndicationUnknownType) 
	AND RT.ApprovalStatus = @ReceivableForTransferApprovalStatusType
	AND RTS.EffectiveDate <= Header.PayoffEffectiveDate
	AND RTS.IsActive = 1;

	SELECT  
		LeaseFinanceId,
		IsSyndicationServiced,
		IsSyndicationCollected,
		IsSyndicationPrivateLabel,
		IsSyndicationPerfectPay
	INTO #SyndicationServicingDetails
	FROM #SyndicationServicingDetailInfo 
	WHERE Row_Num = 1;

	SELECT 
		LeaseFinanceId = Header.LeaseFinanceId,
		IsOriginationServiced = SD.IsServiced,
		IsOriginationCollected = SD.IsCollected,
		IsOriginationPrivateLabel = SD.IsPrivateLabel,
		IsOriginationPerfectPay = SD.IsPerfectPay,
		Row_Num = ROW_NUMBER() OVER (PARTITION BY Header.LeaseFinanceId ORDER BY SD.EffectiveDate DESC)
	 INTO #OriginationServicingDetailInfo
	 FROM #LeaseDetails Header
	 JOIN LeaseFinances LF ON Header.LeaseFinanceId = LF.Id
	 JOIN ContractOriginations CO ON LF.ContractOriginationId = CO.Id
	 JOIN OriginationSourceTypes OST ON CO.OriginationSourceTypeId = OST.Id
	 JOIN ContractOriginationServicingDetails COD ON  CO.Id = COD.ContractOriginationId
	 JOIN ServicingDetails SD ON COD.ServicingDetailId = SD.Id AND SD.IsActive = 1
	 WHERE SD.IsActive = 1
	  AND SD.EffectiveDate <= Header.PayoffEffectiveDate;

	 SELECT  
		LeaseFinanceId,
		IsOriginationServiced,
		IsOriginationCollected,
		IsOriginationPrivateLabel,
		IsOriginationPerfectPay
	INTO #OriginationServicingDetails
	FROM #OriginationServicingDetailInfo
	WHERE Row_Num = 1;

	SELECT 
		LeaseFinanceId = Header.LeaseFinanceId,
		BillingCurrencyId = LFC.BillingCurrencyId,
		BillingCurrencyISO = BCC.ISO,
		BillingExchangeRate = LFC.BillingExchangeRate,
		Row_Num = ROW_NUMBER() OVER (PARTITION BY Header.LeaseFinanceId ORDER BY LFC.EffectiveDate DESC)
	INTO #AlternateBillingDetailInfo
	FROM #LeaseDetails Header
	JOIN LeaseFinanceAlternateCurrencyDetails LFC ON Header.LeaseFinanceId = LFC.LeaseFinanceId
	JOIN Currencies BC ON LFC.BillingCurrencyId = BC.Id
	JOIN CurrencyCodes BCC ON BC.CurrencyCodeId = BCC.Id
	WHERE Header.DueDate > LFC.EffectiveDate 
	AND Header.IsBillInAlternateCurrency = 1
	AND LFC.IsActive = 1;

	SELECT  
		LeaseFinanceId,
		BillingCurrencyId,
		BillingCurrencyISO,
		BillingExchangeRate
	INTO #AlternateBillingDetails
	FROM #AlternateBillingDetailInfo
	WHERE Row_Num = 1;

	SELECT DISTINCT PortfolioId, GLConfigurationId 
	INTO #DistinctPortfolioAndGLConfigurations
	FROM #LeaseDetails;

	SELECT 
		PortfolioAndGLConfig.PortfolioId, 
		PortfolioAndGLConfig.GLConfigurationId,
		ReceivableType = RT.[Name],
		ReceivableCodeId = MIN(RC.Id),
		IsWriteDown = CASE WHEN RCT.[Name] = @RecCategory_Recovery THEN 1 ELSE 0 END
	INTO #ReceivableCodes_Ungrouped
	FROM ReceivableCodes RC
	JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
	JOIN ReceivableCategories RCT ON RC.ReceivableCategoryId = RCT.Id
	JOIN GLTemplates ON RC.GLTemplateId = GLTemplates.Id
	JOIN GLTransactionTypes GTransType ON RT.GLTransactionTypeId = GTransType.Id
	JOIN #DistinctPortfolioAndGLConfigurations PortfolioAndGLConfig 
	ON RC.PortfolioId = PortfolioAndGLConfig.PortfolioId AND GLTemplates.GLConfigurationId = PortfolioAndGLConfig.GLConfigurationId
	WHERE RC.IsActive = 1
	AND
	(
		(GTransType.[Name] = @GLTransType_PayoffBuyoutAR AND RCT.[Name] = @RecCategory_Payoff AND RT.[Name] IN (@ReceivableType_LeasePayoff, @ReceivableType_Buyout))
			OR
		(RT.[Name] IN (@ReceivableType_Sundry, @ReceivableType_SundrySeperate))
			OR
		(RCT.[Name] = @RecCategory_Recovery AND ((RT.[Name] = @ReceivableType_Sundry AND RC.AccountingTreatment = @AccountingTreatmentCashBasedType) OR RT.[Name] = @ReceivableType_SundrySeperate))
	)
	GROUP BY PortfolioAndGLConfig.PortfolioId, PortfolioAndGLConfig.GLConfigurationId, GTransType.[Name], RT.[Name], RCT.[Name];


	SELECT 
		PortfolioId,   
		GLConfigurationId,  
		ReceivableType,  
		IsWriteDown,
		ReceivableCodeId = MIN(ReceivableCodeId)			
	INTO #ReceivableCodes 
	FROM #ReceivableCodes_Ungrouped
	GROUP BY PortfolioId, GLConfigurationId, ReceivableType, IsWriteDown;


	SELECT 
		GLConfigurationId = PortfolioAndGLConfig.GLConfigurationId,
		ForOperatingLease = CASE WHEN GTT.[Name] = @GLTransactionOperatingLeasePayoffType THEN 1 ELSE 0 END,
	 	GLTemplateId = MIN(GT.Id),
		GLTransactionTypeName = GTT.[Name]
	INTO #GLTemplates
	FROM  GLTemplates GT 
	JOIN GLTransactionTypes GTT ON GT.GLTransactionTypeId = GTT.Id 
	JOIN #DistinctPortfolioAndGLConfigurations PortfolioAndGLConfig ON  GT.GLConfigurationId = PortfolioAndGLConfig.GLConfigurationId 
	WHERE GT.IsActive = 1
	AND GTT.Name IN (@GLTransactionOperatingLeasePayoffType,@GLTransactionCapitalLeasePayoffType,@GLTransactionBookDepreciationType, @GLTransactionTaxDepDisposalType) 
	GROUP BY PortfolioAndGLConfig.GLConfigurationId, GTT.[Name];

	SELECT 
		LeaseFinanceId = API.LeaseFinanceId,
		InvoicePreference = CBP.InvoicePreference,
		IsPayoffInvoicePreference = CASE WHEN RT.[Name] = @ReceivableType_LeasePayoff THEN 1 ELSE 0 END,
		Row_Num = ROW_NUMBER() OVER (PARTITION BY [CBP].ReceivableTypeId ORDER BY CBP.Id ASC)
	INTO #InvoicePreferences_UnFlitered
	FROM @AutoPayoffInputs API
	JOIN LeaseFinances LF ON API.LeaseFinanceId = LF.Id
	JOIN Contracts CON ON LF.ContractId = CON.Id 
	JOIN ContractBillingPreferences CBP ON CON.Id = CBP.ContractBillingId
	JOIN ReceivableTypes RT ON CBP.ReceivableTypeId = RT.Id
	WHERE CBP.IsActive = 1
	AND RT.[Name] IN (@ReceivableType_LeasePayoff, @ReceivableType_Buyout);
	
	SELECT 
		LeaseFinanceId,
		InvoicePreference,
		IsPayoffInvoicePreference
	INTO #InvoicePreferences
	FROM #InvoicePreferences_UnFlitered
	WHERE Row_Num = 1;

	SELECT DISTINCT(LeaseCustomerId) 
	INTO #DistinctCustomers 
	FROM #LeaseDetails;

	SELECT 
	CustomerId = C.LeaseCustomerId, 
	LocationId = MIN(L.Id)
	INTO #CustomerLocations
	FROM Locations L
	JOIN #DistinctCustomers C ON L.CustomerId = C.LeaseCustomerId
	WHERE L.ApprovalStatus = @LocationApprovedStatus AND L.IsActive=1
	GROUP BY C.LeaseCustomerId;


	SELECT DISTINCT Lease.LeaseFinanceId, Lease.ContractId
	INTO #DistinctLeaseDetails 
	FROM #LeaseDetails Lease;

	SELECT ChargeOffs.ContractId, 
			ChargeOffs.IsRecovery, 
			ChargeOffAmount = SUM(ChargeOffs.ChargeOffAmount_Amount)
		INTO #ChargeOffDetails
		FROM #DistinctLeaseDetails Lease
			INNER JOIN ChargeOffs ON Lease.ContractId = ChargeOffs.ContractId AND ChargeOffs.[Status] = @WriteDownApprovedStatus
		Where ChargeOffs.IsActive = 1
		GROUP BY ChargeOffs.ContractId, ChargeOffs.IsRecovery;

	SELECT  
		ContractId = CON.Id,
		GLTemplateId = WD.GLTemplateId,
		RecoveryGLTemplateId = WD.RecoveryGLTemplateId,
		RecoveryReceivableCodeId = WD.RecoveryReceivableCodeId,
		Row_Num = ROW_NUMBER() OVER (PARTITION BY [CON].Id ORDER BY WD.Id ASC)
	INTO #ContractWritedowns_Unfiltered
	FROM @AutoPayoffInputs Header
	JOIN LeaseFinances LF ON Header.LeaseFinanceId = LF.Id
	JOIN Contracts CON ON LF.ContractId = CON.Id
	JOIN WriteDowns WD ON CON.Id = WD.ContractId
	WHERE CON.IsNonAccrual = 1 
	AND WD.IsActive = 1
	AND WD.[Status] = @WriteDownApprovedStatus;

	SELECT 
		ContractId,
		GLTemplateId,
		RecoveryGLTemplateId,
		RecoveryReceivableCodeId
	INTO #ContractWritedowns
	FROM #ContractWritedowns_Unfiltered
	WHERE Row_Num = 1;

	SELECT WriteDown.ContractId,
		   WriteDown.IsRecovery, 
		   WriteDownAmount = SUM(WriteDownDetail.WriteDownAmount_Amount)
		INTO #WriteDownDetails
		FROM #ContractWritedowns [Contract]
			JOIN WriteDowns WriteDown ON [Contract].ContractId = WriteDown.ContractId AND WriteDown.[Status] = @WriteDownApprovedStatus
			JOIN WriteDownAssetDetails WriteDownDetail ON WriteDown.Id = WriteDownDetail.WriteDownId
		WHERE WriteDown.IsActive = 1
			AND WriteDownDetail.IsActive = 1
		GROUP BY WriteDown.ContractId, WriteDown.IsRecovery;

	SELECT 
		LeaseFinanceId = Header.LeaseFinanceId,
		ContractId = Header.ContractId,
		SequenceNumber = Header.SequenceNumber,
		PortfolioId = Header.PortfolioId,
		LeaseCustomerId = Header.LeaseCustomerId,
		LeaseCustomerNumber = Header.LeaseCustomerNumber,
		LegalEntityId = Header.LegalEntityId,
		LegalEntityNumber = Header.LegalEntityNumber,
		LegalEntityName = Header.LegalEntityName,
		LegalEntitySalesTaxRemittanceMethod = Header.LegalEntitySalesTaxRemittanceMethod,
		CommencementDate = Header.CommencementDate,
		MaturityDate = Header.MaturityDate,
		PayoffEffectiveDate = Header.PayoffEffectiveDate,
		CurrencyId = Header.CurrencyId,
		CurrencyISO = Header.CurrencyISO,
		LineofBusinessId = Header.LineofBusinessId,
		InstrumentTypeId = Header.InstrumentTypeId,
		InvoiceFormatId = ISNULL(Header.InvoiceFormatId, BillTo.InvoiceFormatId),
		InvoiceOutputFormat = ISNULL(Header.InvoiceOutputFormat, BillTo.InvoiceOutputFormat),
		CostCenterId = Header.CostCenterId,
		BranchId = Header.BranchId,
		BillingCurrencyId = ISNULL(ABI.BillingCurrencyId,Header.CurrencyId),
		BillingCurrencyISO = ISNULL(ABI.BillingCurrencyISO,Header.CurrencyISO),
		BillingExchangeRate = ISNULL(ABI.BillingExchangeRate, 1),
		DealProductTypeId = Header.DealProductTypeId,
		DealProductType = Header.DealProductType,
		LeaseContractType = Header.LeaseContractType,
		LeasePaymentFrequency = Header.LeasePaymentFrequency,
		LeaseNumberOfPayments = Header.LeaseNumberOfPayments,
		LeaseDayCountConvention = Header.LeaseDayCountConvention,
		IsAdvanceLease = Header.IsAdvanceLease,
		LeaseBookingGLTemplateId = Header.LeaseBookingGLTemplateId,
		LeaseIncomeGLTemplateId = Header.LeaseIncomeGLTemplateId,		
		LastPaymentScheduleId = Header.LastPaymentScheduleId,
		PaymentScheduleNumber = Header.PaymentScheduleNumber,
		CustomerFacingYield = Header.CustomerFacingYield,
		TermInMonths = Header.TermInMonths,
		LastExtensionARUpdateRunDate = Header.LastExtensionARUpdateRunDate,
		LastSupplementalARUpdateRunDate = Header.LastSupplementalARUpdateRunDate,
		OriginatorId = OriginatorID,
		OriginationSourceType = OriginationSourceType, 
		OriginationScrapeFactor = OriginationScrapeFactor,
		OriginatorPayableRemitToId = OriginatorPayableRemitToId,
		OriginationScrapePayableCodeId = OriginationScrapePayableCodeId,
		IsOriginationServiced = OSD.IsOriginationServiced,
		IsOriginationCollected = OSD.IsOriginationCollected,
		IsOriginationPrivateLabel = OSD.IsOriginationPrivateLabel,
		IsOriginationPerfectPay = OSD.IsOriginationPerfectPay,
		LeaseBillToId = ISNULL(Header.BillToId, BillTo.BillToId),
		LeaseRemitToId = Header.RemitToId,
		IsOperatingLease = Header.IsOperatingLease,
		IsChargedOffLease = Header.IsChargedOffLease,
		IsTiedDiscountingExists = Header.IsTiedDiscountingExists,
		ContractSalesTaxRemittanceMethod = Header.ContractSalesTaxRemittanceMethod,
		SyndicationType = Header.SyndicationType,
		SyndicationQuoteName = Header.SyndicationQuoteName,
		SyndicationEffectiveDate = Header.SyndicationEffectiveDate,
		SyndicationScrapeRemitToId = Header.SyndicationScrapeRemitToId,
		IsSyndicationServiced = SD.IsSyndicationServiced,
		IsSyndicationCollected = SD.IsSyndicationCollected,
		IsSyndicationPerfectPay = SD.IsSyndicationPerfectPay,
		IsSyndicationPrivateLabel = SD.IsSyndicationPrivateLabel,
		SyndicationRentalProceedsPayableCodeId = Header.SyndicationRentalProceedsPayableCodeId,
		SyndicationRentalProceedsPayableCodeName = Header.SyndicationRentalProceedsPayableCodeName,
		SyndicationScrapeReceivableCodeId = Header.SyndicationScrapeReceivableCodeId,
		PurchaseOption = Header.PurchaseOption,
		TotalEconomicLifeInMonths = Header.TotalEconomicLifeInMonths,
		RemainingEconomicLifeInMonths = Header.RemainingEconomicLifeInMonths,
        IsBargainPurchaseOption = Header.IsBargainPurchaseOption,
        IsTransferOfOwnership = Header.IsTransferOfOwnership,
        IsSpecializedUseAssets = Header.IsSpecializedUseAssets,
        TotalEconomicLifeTestResult = Header.TotalEconomicLifeTestResult,
        NinetyPercentTestPresentValue = Header.NinetyPercentTestPresentValue,
        NinetyPercentTestResult = Header.NinetyPercentTestResult,
        NinetyPercentTestResultPassed = Header.NinetyPercentTestResultPassed,
        NinetyPercentTestPresentValue5A = Header.NinetyPercentTestPresentValue5A,
        NinetyPercentTestPresentValue5B = Header.NinetyPercentTestPresentValue5B,
        NinetyPercent5ATestResultPassed = Header.NinetyPercent5ATestResultPassed,
        NinetyPercent5BTestResultPassed = Header.NinetyPercent5BTestResultPassed,
        NinetyPercent5ATestResult = Header.NinetyPercent5ATestResult,
        NinetyPercent5BTestResult = Header.NinetyPercent5BTestResult,
        ClassificationContractType = Header.ClassificationContractType,
        LessorYield = Header.LessorYield,
        LessorYieldLeaseAsset = Header.LessorYieldLeaseAsset,
        LessorYieldFinanceAsset = Header.LessorYieldFinanceAsset,
        ClassificationYield = Header.ClassificationYield,
        ClassificationYield5A = Header.ClassificationYield5A,
        ClassificationYield5B = Header.ClassificationYield5B,
		IsTaxLease = Header.IsTaxLease,
		BillToLocationId = ISNULL(Header.BillToLocationId, BillTo.BillToLocationId),
		CustomerLocationId = CL.LocationId,
		ReceivableAmendmentType = Header.ReceivableAmendmentType,
		PayoffAssetStatus = Header.PayoffAssetStatus,
		PayoffInvoicePreference = ISNULL(payoffInvoicePreference.InvoicePreference,'_'),
		BuyoutInvoicePreference = ISNULL(buyoutInvoicePreference.InvoicePreference,'_'),	
		GlFinancialPeriodFromDate = Header.GlFinancialPeriodFromDate,
		IsBusinessDateApplicable = Header.IsBusinessDateApplicable,
		CurrentBusinessDate = Header.CurrentBusinessDate,
		PayoffGLTemplateId = CASE
								WHEN Header.IsOperatingLease = 1 AND Header.OperatingLeasePayoffGLTemplateId IS NOT NULL
								THEN Header.OperatingLeasePayoffGLTemplateId
								WHEN Header.IsOperatingLease = 0 AND Header.CapitalLeasePayoffGLTemplateId IS NOT NULL
								THEN Header.CapitalLeasePayoffGLTemplateId
								ELSE PayoffGLTemplate.GLTemplateId
							 END,
		InventoryBookDepGLTemplateId = ISNULL(Header.InventoryBookDepGLTemplateId ,InvGLTemplate.GLTemplateId),
		TaxDepDisposalTemplateId = ISNULL(Header.TaxDepDisposalTemplateId ,TaxDepDisposalGLTemplate.GLTemplateId),
		FixedTermReceivableCodeGLTemplateId = Header.FixedTermReceivableCodeGLTemplateId,
		OTPReceivableCodeGLTemplateId = Header.OTPReceivableCodeGLTemplateId,
		SupplementalReceivableCodeGLTemplateId = Header.SupplementalReceivableCodeGLTemplateId,
		OTPIncomeGLTemplateId = Header.OTPIncomeGLTemplateId,
		FloatRateARReceivableGLTemplateId = Header.FloatRateARReceivableGLTemplateId,
		FloatIncomeGLTemplateId = Header.FloatIncomeGLTemplateId,
		PayoffReceivableCodeId = ISNULL(Header.PayoffReceivableCodeId ,PayoffRecCode.ReceivableCodeId),
		BuyoutReceivableCodeId = ISNULL(Header.BuyoutReceivableCodeId ,BuyoutRecCode.ReceivableCodeId),
		SundryReceivableCodeId = ISNULL(Header.SundryReceivableCodeId ,CASE 
																			 WHEN SundryRecCode.ReceivableCodeId IS NOT NULL 
																			 	  AND SundrySeperateRecCode.ReceivableCodeId IS NOT NULL 
																			 	  AND SundryRecCode.ReceivableCodeId < SundrySeperateRecCode.ReceivableCodeId 
																			 THEN SundryRecCode.ReceivableCodeId
																			 WHEN SundryRecCode.ReceivableCodeId IS NOT NULL 
																			 THEN SundryRecCode.ReceivableCodeId
																			 ELSE SundrySeperateRecCode.ReceivableCodeId END),
		
		
		AutoPayoffTemplateId = Header.AutoPayoffTemplateId,
		AutoPayoffTemplateName = Header.AutoPayoffTemplateName,
		PayoffTemplateId = Header.PayoffTemplateId,
		PayOffTemplateTerminationTypeId = Header.PayOffTemplateTerminationTypeId,
		TemplateName = Header.TemplateName,
		TerminationTypeName = Header.TerminationTypeName,
		LOBDiscountRate = Header.LOBDiscountRate,
		IsTradeupFeeApplicable = Header.IsTradeupFeeApplicable,
		TradeupFeeCalculationMethod = Header.TradeupFeeCalculationMethod,
		TemplateType = Header.TemplateType,
		TradeupFlatFeeAmount = Header.TradeupFlatFeeAmount,
		PayoffTradeUpFeeId = Header.PayoffTradeUpFeeId,
		TradeUpFeeReceivableCodeId = Header.TradeUpFeeReceivableCodeId,
		RelatedOption = Header.RelatedOption,
		IsConditionalCalculation = Header.IsConditionalCalculation,
		ExpressionQuery = Header.ExpressionQuery,
		ChargeOffAmount = ISNULL(ChargeOffOriginal.ChargeOffAmount, 0.0),		
		ChargeOffBalance = ISNULL(ChargeOffOriginal.ChargeOffAmount, 0.0) + ISNULL(ChargeOffBalance.ChargeOffAmount, 0.0),
		GrossWriteDown = ISNULL(WriteDownNONRecovery.WriteDownAmount, 0.0),
		NetWriteDown = ISNULL((ISNULL(WriteDownRecovery.WriteDownAmount, 0.0) + ISNULL(WriteDownNONRecovery.WriteDownAmount, 0.0)), 0.0),
		OTPAccountingTreatment = Header.OTPAccountingTreatment,
		SupplementalAccountingTreatment = Header.SupplementalAccountingTreatment,
		NonAccuralDate = Header.NonAccuralDate,
		IsEligibleForWriteDown =  CAST(CASE WHEN(WriteDown.ContractId IS NULL) THEN 0 ELSE 1 END AS BIT),
		WriteDownGLTemplateId = WriteDown.GLTemplateId,
		WriteDownCashBasedRecoveryReceivableCodeId = CASE WHEN WriteDown.ContractId IS NULL THEN NULL 
								WHEN WriteDownRecCode_Sundry.ReceivableCodeId IS NOT NULL 
									 AND WriteDownRecCode_SundrySeperate.ReceivableCodeId IS NOT NULL 
									 AND WriteDownRecCode_Sundry.ReceivableCodeId < WriteDownRecCode_SundrySeperate.ReceivableCodeId THEN WriteDownRecCode_Sundry.ReceivableCodeId
								 WHEN WriteDownRecCode_Sundry.ReceivableCodeId IS NOT NULL THEN WriteDownRecCode_Sundry.ReceivableCodeId
								 ELSE WriteDownRecCode_SundrySeperate.ReceivableCodeId END,
		WriteDownRecoveryGLTemplateId = WriteDown.RecoveryGLTemplateId,
		WriteDownRecoveryReceivableCodeId = WriteDown.RecoveryReceivableCodeId,
		TaxAssessmentLevel = Header.TaxAssessmentLevel,
		PayoffAtFixedTerm,
		ActivatePayoffQuote,
		PayoffAtInception = CASE WHEN Header.PayoffEffectiveDate = Header.CommencementDate
							THEN CAST(1 AS BIT)
							ELSE CAST(0 AS BIT)
							END,
		PayoffAtOTP = CASE WHEN Header.PayoffEffectiveDate > Header.MaturityDate
					  THEN CAST(1 AS BIT)
					  ELSE CAST(0 AS BIT)
					  END
	FROM #LeaseDetails Header
	LEFT JOIN #InvoicePreferences payoffInvoicePreference
	ON Header.LeaseFinanceId = payoffInvoicePreference.LeaseFinanceId AND payoffInvoicePreference.IsPayoffInvoicePreference = 1
	LEFT JOIN #InvoicePreferences buyoutInvoicePreference
	ON Header.LeaseFinanceId = buyoutInvoicePreference.LeaseFinanceId AND buyoutInvoicePreference.IsPayoffInvoicePreference = 0
	LEFT JOIN #GLTemplates PayoffGLTemplate 
	ON Header.GLConfigurationId = PayoffGLTemplate.GLConfigurationId AND PayoffGLTemplate.GLTransactionTypeName IN (@GLTransactionOperatingLeasePayoffType, @GLTransactionCapitalLeasePayoffType) AND PayoffGLTemplate.ForOperatingLease = Header.IsOperatingLease 
	LEFT JOIN #GLTemplates InvGLTemplate 
	ON Header.GLConfigurationId = InvGLTemplate.GLConfigurationId AND InvGLTemplate.GLTransactionTypeName = @GLTransactionBookDepreciationType
	LEFT JOIN #GLTemplates TaxDepDisposalGLTemplate 
	ON Header.GLConfigurationId = TaxDepDisposalGLTemplate.GLConfigurationId AND TaxDepDisposalGLTemplate.GLTransactionTypeName = @GLTransactionTaxDepDisposalType 
	LEFT JOIN #ReceivableCodes PayoffRecCode 
	ON Header.PortFolioId = PayoffRecCode.PortfolioId AND Header.GLconfigurationid = PayoffRecCode.GLConfigurationId AND PayoffRecCode.ReceivableType = @ReceivableType_LeasePayoff AND PayoffRecCode.IsWriteDown = 0
	LEFT JOIN #ReceivableCodes BuyoutRecCode 
	ON Header.PortFolioId = BuyoutRecCode.PortfolioId AND Header.GLconfigurationid = BuyoutRecCode.GLConfigurationId AND BuyoutRecCode.ReceivableType = @ReceivableType_Buyout AND BuyoutRecCode.IsWriteDown = 0
	LEFT JOIN #ReceivableCodes SundryRecCode 
	ON Header.PortFolioId = SundryRecCode.PortfolioId AND Header.GLconfigurationid = SundryRecCode.GLConfigurationId AND SundryRecCode.ReceivableType = @ReceivableType_Sundry AND SundryRecCode.IsWriteDown = 0
	LEFT JOIN #ReceivableCodes SundrySeperateRecCode 
	ON Header.PortFolioId = SundrySeperateRecCode.PortfolioId AND Header.GLconfigurationid = SundrySeperateRecCode.GLConfigurationId AND SundryRecCode.ReceivableType = @ReceivableType_SundrySeperate AND SundrySeperateRecCode.IsWriteDown = 0
	LEFT JOIN #ReceivableCodes WriteDownRecCode_Sundry
	ON Header.PortFolioId = WriteDownRecCode_Sundry.PortfolioId AND Header.GLconfigurationid = WriteDownRecCode_Sundry.GLConfigurationId AND WriteDownRecCode_Sundry.ReceivableType = @ReceivableType_Sundry  AND WriteDownRecCode_Sundry.IsWriteDown = 1
	LEFT JOIN #ReceivableCodes WriteDownRecCode_SundrySeperate
	ON Header.PortFolioId = WriteDownRecCode_SundrySeperate.PortfolioId AND Header.GLconfigurationid = WriteDownRecCode_SundrySeperate.GLConfigurationId AND WriteDownRecCode_SundrySeperate.ReceivableType = @ReceivableType_SundrySeperate  AND WriteDownRecCode_SundrySeperate.IsWriteDown = 1
	LEFT JOIN #CustomerLocations CL ON Header.LeaseCustomerId = CL.CustomerId
	LEFT JOIN #SyndicationServicingDetails SD ON Header.LeaseFinanceId = SD.LeaseFinanceId
	LEFT JOIN #OriginationServicingDetails OSD ON Header.LeaseFinanceId = OSD.LeaseFinanceId
	LEFT JOIN #AlternateBillingDetails ABI ON Header.LeaseFinanceId = ABI.LeaseFinanceId
	LEFT JOIN #ChargeOffDetails ChargeOffOriginal ON Header.ContractId = ChargeOffOriginal.ContractId AND ChargeOffOriginal.IsRecovery = 0
	LEFT JOIN #ChargeOffDetails ChargeOffBalance ON Header.ContractId = ChargeOffBalance.ContractId AND ChargeOffBalance.IsRecovery = 1
	LEFT JOIN #WriteDownDetails WriteDownNONRecovery ON Header.ContractId = WriteDownNONRecovery.ContractId AND WriteDownNONRecovery.IsRecovery = 0
	LEFT JOIN #WriteDownDetails WriteDownRecovery ON Header.ContractId = WriteDownRecovery.ContractId AND WriteDownRecovery.IsRecovery = 1
	LEFT JOIN #ContractWritedowns WriteDown ON Header.ContractId = WriteDown.ContractId
	LEFT JOIN #LeaseBillToDetails BillTo ON Header.LeaseFinanceId = BillTo.LeaseFinanceId;

	SELECT 
		LeaseFinanceId = Header.LeaseFinanceId,
		ParticipationPercentage = RTF.ParticipationPercentage,
		FunderId = RTF.FunderId,
		ScrapeFactor = RTF.ScrapeFactor,
		FunderBillToId = RTF.FunderBillToId,
		FunderLocationId = RTF.FunderLocationId,
		FunderRemitToId = RTF.FunderRemitToId,
		SalesTaxResponsibility = RTF.SalesTaxResponsibility
	FROM #DistinctLeaseDetails Header
	JOIN ReceivableForTransfers RT ON Header.ContractId = RT.ContractId
	JOIN ReceivableForTransferFundingSources RTF ON RT.Id = RTF.ReceivableForTransferId
	WHERE RT.ApprovalStatus = @SyndicationApprovedStatus
	AND RTF.IsActive = 1;

DROP TABLE 
#LeaseDetails,
#InvoicePreferences,
#GLTemplates,
#ReceivableCodes_Ungrouped,
#ReceivableCodes,
#DistinctPortfolioAndGLConfigurations,
#SyndicationServicingDetailInfo,
#SyndicationServicingDetails,
#OriginationServicingDetails,
#AlternateBillingDetails,
#CustomerLocations,
#DistinctCustomers,
#OriginationServicingDetailInfo,
#AlternateBillingDetailInfo,
#DistinctLeaseDetails,
#ChargeOffDetails,
#WriteDownDetails,
#ContractWritedowns_Unfiltered,
#ContractWritedowns,
#LeaseBillToDetailInfo,
#LeaseBillToDetails,
#InvoicePreferences_UnFlitered

END

GO

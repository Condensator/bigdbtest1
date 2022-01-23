SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[ExtractDataForInvoiceGeneration_NonContract] (
	@JobStepInstanceId BIGINT,
	@ProcessThroughDate DATE,
	@SystemDate DATE,
	@ExcludeBackgroundProcessingPendingContracts BIT = NULL,
	@ContractId BIGINT = NULL,
	@DiscountingId BIGINT = NULL,
	@CustomerId BIGINT = NULL,
	@IsFilterOptionAll BIT = 0,
	@InvoiceType NVARCHAR(100) = NULL,
	@IsInvoiceSensitive BIT = 0,
	@EntityType NVARCHAR(100),
	@LegalEntityIds IdCollection READONLY,
	@CreatedById BIGINT,
	@CreatedTime DATETIMEOFFSET,
	@SourceJobStepInstanceId BIGINT = NULL,
	@ContractFilterEntityType_Lease NVARCHAR(100),
	@ContractFilterEntityType_Loan NVARCHAR(100),
	@ContractFilterEntityType_LeveragedLease NVARCHAR(100),
	@ContractFilterEntityType_Discounting NVARCHAR(100),
	@InvoiceType_Unknown NVARCHAR(100),
	@InvoiceGenerationAction_ReceivableInvoiceGeneration NVARCHAR(100),
	@ReceivableType_LeasePayOff NVARCHAR(100),
	@ReceivableType_BuyOut NVARCHAR(100),
	@SyndicationType_None NVARCHAR(100),
	@SyndicationType_Unknown NVARCHAR(100),
	@ReceivableEntityType_CT NVARCHAR(100),
	@ReceivableEntityType_DT NVARCHAR(100),
	@ReceivableEntityType_CU NVARCHAR(100),
	@ReceivableSourceTable_CPUSchedule NVARCHAR(100),
	@BilledStatus_NotInvoiced NVARCHAR(100),
	@ContractStatusTerminated NVARCHAR(100),
	@JobPaginationCount BIGINT
	)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @InvoiceTypeId BIGINT
	DECLARE @IsAllDiscounting BIT = 0
	DECLARE @True AS BIT = CONVERT(BIT, 1)
	DECLARE @False AS BIT = CONVERT(BIT, 0)
	DECLARE @IsReRun BIT = 0
	DECLARE @MaxReceivableDetailId BIGINT = 0  

	IF @IsFilterOptionAll = 1
	BEGIN
		IF @EntityType = @ContractFilterEntityType_Discounting
			SET @IsAllDiscounting = @True
	END

	SET @InvoiceTypeId = (
			SELECT Id
			FROM InvoiceTypes
			WHERE [Name] = @InvoiceType
				AND @InvoiceType != @InvoiceType_Unknown
			)

	CREATE TABLE #PreviousJobBillToIds(
		BillToId BIGINT NOT NULL
	)

	IF @SourceJobStepInstanceId IS NOT NULL
	BEGIN
		SET @IsReRun = @True;
		INSERT INTO #PreviousJobBillToIds
		SELECT BillToId FROM InvoiceJobErrorSummaries 
		WHERE SourceJobStepInstanceId=@SourceJobStepInstanceId AND NextAction=@InvoiceGenerationAction_ReceivableInvoiceGeneration AND IsActive=1
	END

	SELECT * INTO #LegalEntityIds FROM @LegalEntityIds

	SELECT Id, [Name], IsRental
	INTO #AllowedReceivableTypes
	FROM ReceivableTypes
	WHERE [Name] NOT IN ( @ReceivableType_LeasePayOff, 'LoanPayDown', @ReceivableType_BuyOut)

	 While 1=1  
 Begin  
	 SELECT TOP (@JobPaginationCount) R.Id RId, RD.Id RDId, rd.BillToId,ISNULL(CPUB.InvoiceLeaddays,CU.InvoiceLeaddays) As InvoiceLeadDays,  
	 ISNULL(CPUB.InvoiceTransitDays, CU.InvoiceTransitDays) AS InvoiceTransitDays   
	 Into #Receivables 
	FROM Receivables AS R WITH (FORCESEEK) 
	INNER JOIN ReceivableDetails RD WITH (FORCESEEK)  ON R.Id = RD.ReceivableId
		AND RD.IsActive = 1
		AND R.IsActive = 1
	INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
	INNER JOIN ReceivableCategories RCTG ON RC.ReceivableCategoryId = RCTG.Id
	INNER JOIN #AllowedReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
	INNER JOIN Customers CU ON CU.Id = R.CustomerId
	INNER JOIN Parties Party ON CU.Id = Party.Id
	LEFT JOIN CPUSchedules CPUS ON R.SourceId = CPUS.Id AND R.SourceTable = @ReceivableSourceTable_CPUSchedule
	LEFT JOIN CPUBillings CPUB ON CPUS.CPUFinanceId = CPUB.Id
	LEFT JOIN #PreviousJobBillToIds P ON RD.BillToId=P.BillToId
	WHERE RD.ID > @MaxReceivableDetailId AND (R.EntityType = @ReceivableEntityType_CU OR R.EntityType = @ReceivableEntityType_DT)
		AND R.DueDate <= CASE WHEN @IsInvoiceSensitive = 1
							THEN DATEADD(DD, ISNULL(CPUB.InvoiceLeaddays, CU.InvoiceLeadDays), @ProcessThroughDate)
							ELSE @ProcessThroughDate END
		AND R.IsServiced = 1
		AND R.ReceivableTaxType <> 'None'
		AND RD.BilledStatus = @BilledStatus_NotInvoiced
		AND RD.IsTaxAssessed = 1
		AND RD.StopInvoicing = 0
		AND R.IsDummy = 0
		AND (
			@DiscountingId IS NULL
			OR (R.EntityId = @DiscountingId AND R.EntityType = @ReceivableEntityType_DT)
			)
		AND (
			@CustomerId IS NULL	OR R.CustomerId = @CustomerId
			)
		AND (
			@InvoiceType = '_' OR RCTG.InvoiceTypeId = @InvoiceTypeId
			)
		AND (
			@IsReRun = 0 OR P.BillToId IS NOT NULL --Previous Job Bill To Filters
			)
		ORDER BY RD.Id ; 
  
	 IF NOT EXISTS(Select 1 FROM #Receivables)  
	 BREAK;  
	 ELSE  
	 SELECT  @MaxReceivableDetailId = MAX(RDId) FROM #Receivables  
  
   Create Clustered Index IX_RDId On #Receivables (RDId)  
   Create NonClustered Index IX_RId On #Receivables (RId)  

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
		IsDownPaymentVATReceivable
		)
	SELECT R.Id AS ReceivableId,
		R.EntityType,
		NULL AS ContractId,
		CASE WHEN R.EntityType = @ReceivableEntityType_DT THEN R.EntityId ELSE NULL END AS DiscountingId,
		@False AS IsSyndicated,
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
		NULL AS CapSoftAssetId,
		AdjustmentReceivableInvoiceId = CAST(NULL AS BIGINT),
		@False AS IsWithHoldingTaxAssessed ,
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
		NULL AS ContractType,
		NULL AS ContractInvoiceComment,
		NULL AS CT_InvoiceLeadDays,
		NULL AS CT_InvoiceTransitDays,
		RR.InvoiceLeadDays,
		RR.InvoiceTransitDays,
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
		NULL AS SequenceNumber,
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
		0
	FROM #Receivables AS RR
	INNER JOIN ReceivableDetails RD With (ForceSeek)  ON RR.RDId = RD.Id
		AND RD.IsActive = 1
	INNER JOIN Receivables R ON RR.RId = R.Id
	INNER JOIN LegalEntities LE ON R.LegalEntityId = LE.Id
	INNER JOIN #LegalEntityIds LEI ON LE.Id = LEI.Id
	INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
	INNER JOIN ReceivableCategories RCTG ON RC.ReceivableCategoryId = RCTG.Id
	INNER JOIN #AllowedReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
	INNER JOIN Customers CU ON CU.Id = R.CustomerId
	INNER JOIN Parties Party ON CU.Id = Party.Id
	INNER JOIN BillToes B ON RR.BillToId = B.Id
	INNER JOIN BillToInvoiceParameters BTIP With (ForceSeek)  ON B.Id = BTIP.BillToId
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
	 DROP TABLE #Receivables  
 END 
	Drop Table IF Exists #Receivables
 	DROP TABLE #AllowedReceivableTypes
	DROP TABLE #LegalEntityIds
	DROP TABLE #PreviousJobBillToIds
END

GO

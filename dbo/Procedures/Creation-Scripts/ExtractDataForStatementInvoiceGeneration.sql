SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[ExtractDataForStatementInvoiceGeneration] (
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
	@WithHoldingTaxApplicable BIT = 0,
	@EntityType NVARCHAR(100),
	@LegalEntityIds IdCollection READONLY,
	@CreatedById BIGINT,
	@CreatedTime DATETIMEOFFSET ,
	@SourceJobStepInstanceId BIGINT = NULL,
	@ReceivableEntityType_CT NVARCHAR(100),
	@ReceivableEntityType_DT NVARCHAR(100),
	@ReceivableEntityType_CU NVARCHAR(100),
	@ReceivableSourceTable_CPUSchedule NVARCHAR(100),
	@ContractFilterEntityType_Lease NVARCHAR(100),
	@ContractFilterEntityType_Loan NVARCHAR(100),
	@ContractFilterEntityType_LeveragedLease NVARCHAR(100),
	@ContractFilterEntityType_Discounting NVARCHAR(100),
	@ReceivableType_LeasePayOff NVARCHAR(100),
	@ReceivableType_BuyOut NVARCHAR(100),
	@InvoiceGenerationAction_StatementInvoiceGeneration NVARCHAR(100),
	@BilledStatus_Invoiced NVARCHAR(100)
	)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @IsAllLease BIT = 0
	DECLARE @IsAllLoan BIT = 0
	DECLARE @IsAllLeveragedLease BIT = 0
	DECLARE @IsAllDiscounting BIT = 0
	DECLARE @True AS BIT = CONVERT(BIT, 1)
	DECLARE @False AS BIT = CONVERT(BIT, 0)
	DECLARE @IsReRun BIT = 0

	IF @IsFilterOptionAll = 1
	BEGIN
		IF @EntityType = @ContractFilterEntityType_Lease
			SET @IsAllLease = @True
		ELSE IF @EntityType = @ContractFilterEntityType_Loan
			SET @IsAllLoan = @True
		ELSE IF @EntityType = @ContractFilterEntityType_LeveragedLease
			SET @IsAllLeveragedLease = @True
		ELSE IF @EntityType = @ContractFilterEntityType_Discounting
			SET @IsAllDiscounting = @True
	END
	
	CREATE TABLE #PreviousJobBillToIds(
		BillToId BIGINT NOT NULL
	)

	IF @SourceJobStepInstanceId IS NOT NULL
	BEGIN
		SET @IsReRun = @True;
		INSERT INTO #PreviousJobBillToIds
		SELECT BillToId FROM InvoiceJobErrorSummaries 
		WHERE SourceJobStepInstanceId=@SourceJobStepInstanceId AND NextAction=@InvoiceGenerationAction_StatementInvoiceGeneration AND IsActive=1
	END

	CREATE TABLE #LegalEntityIds(
		LegalEntityId BIGINT PRIMARY KEY
	)

	INSERT INTO #LegalEntityIds(LegalEntityId)
	SELECT L.Id FROM @LegalEntityIds L

	INSERT INTO StatementInvoiceReceivableDetails_Extract (
			[ReceivableInvoiceId]
           ,[ReceivableDetailId]
           ,[ReceivableId]
           ,[JobStepInstanceId]
		   ,[JobProcessThroughDate]
		   ,[IsInvoiceSensitive]
           ,[EntityType]
		   ,[EntityId]
           ,[LegalEntityId]
           ,[ContractType]
           ,[ContractId]
           ,[DiscountingId]
           ,[BillToId]
           ,[RemitToId]
           ,[CustomerId]
           ,[InvoiceDueDate]
           ,[ReceivableDueDate]
		   ,[LastStatementGeneratedDueDate]
           ,[IsPrivateLabel]
           ,[IsDSL]
           ,[IsACH]
           ,[CT_InvoiceTransitDays]
           ,[CT_InvoiceLeadDays]
           ,[CU_InvoiceTransitDays]
           ,[CU_InvoiceLeadDays]
           ,[AssetId]
           ,[RI_StatementInvoicePreference]
           ,[SplitRentalInvoiceByAsset]
           ,[SplitCreditsByOriginalInvoice]
           ,[SplitByReceivableAdjustments]
           ,[SplitRentalInvoiceByContract]
           ,[SplitLeaseRentalInvoiceByLocation]
		   ,[SplitReceivableDueDate]
		   ,[SplitCustomerPurchaseOrderNumber]
           ,[GenerateSummaryInvoice]
		   ,[StatementInvoiceFormatId]
           ,[ReceivableCategoryId]
           ,[ReceivableCategoryName]
           ,[InvoiceAmount]
           ,[InvoiceBalance]
           ,[InvoiceEffectiveBalance]
           ,[InvoiceCurrency]
           ,[CurrencyId]
		   ,[AlternateBillingCurrencyId]
           ,[ReceivableDetailAmount]
           ,[ReceivableDetailBalance]
           ,[ReceivableDetailEffectiveBalance]
		   ,[OriginalTaxBalance]
		   ,[OriginalTaxEffectiveBalance]
           ,[LocationId]
           ,[IsReceivableTypeRental]
           ,[WithHoldingTaxAmount]
           ,[WithHoldingTaxBalance]
           ,[ReceivableTypeId]
           ,[ReceivableTypeName]
           ,[ReceivableCodeId]
		   ,[IsCurrentInstance]
           ,[CreatedById]
           ,[CreatedTime]
           ,[UpdatedById]
           ,[UpdatedTime]
		   ,[GroupNumber]
		   ,[DefaultInvoiceReceivableGroupingOption]
		   ,[IsReceivableAdjustment]
		   ,[AdjustmentBasisReceivableDetailId]
		   ,[ReportFormatId]
		   ,[InvoiceTaxAmount]
		   ,[InvoiceTaxBalance]
		   ,[InvoiceTaxEffectiveBalance]
		   ,[ExchangeRate]
		   ,[IsOffPeriod]
		   ,[IsActive]
		   ,[AssetPurchaseOrderNumber]
		   ,[CustomerNumber]
		   ,[CurrencyISO]
		   ,[CustomerName]
		   ,[RemitToName]
		   ,[AlternateBillingCurrencyISO]
		   ,[LegalEntityNumber]
		)
	SELECT 
		RI.Id AS ReceivableInvoiceId,
		RD.Id AS ReceivableDetailId,
		R.Id AS ReceivableId,
		@JobStepInstanceId AS JobStepInstanceId,
		CASE 
					WHEN @IsInvoiceSensitive = 1
					THEN CASE 
							WHEN R.SourceTable =@ReceivableSourceTable_CPUSchedule 
								THEN DATEADD(DD, CPUB.InvoiceLeaddays, @ProcessThroughDate)
							WHEN R.EntityType = @ReceivableEntityType_CU
								OR R.EntityType = @ReceivableEntityType_DT
								THEN DATEADD(DD, CU.InvoiceLeadDays, @ProcessThroughDate)
							ELSE DATEADD(DD, CASE WHEN B.SplitRentalInvoiceByContract = 1 THEN CB.InvoiceLeaddays ELSE CU.InvoiceLeadDays END, @ProcessThroughDate)
							END
					ELSE @ProcessThroughDate
		END AS JobProcessThroughDate,
		@IsInvoiceSensitive AS IsInvoiceSensitive,
		R.EntityType AS EntityType,
		R.EntityId AS EntityId,
		LE.Id AS LegalEntityId,
		C.ContractType,
		ContractId = CASE 
			WHEN R.EntityType = @ReceivableEntityType_CT
				THEN R.EntityId
			END,
		DiscountingId = CASE 
			WHEN R.EntityType = @ReceivableEntityType_DT
				THEN R.EntityId
			END,
		B.Id AS BillToId,
		R.RemitToId AS RemitToId,
		CU.Id AS CustomerId,
		RI.DueDate AS InvoiceDueDate,
		R.DueDate AS ReceivableDueDate,
		RI.LastStatementGeneratedDueDate AS LastStatementGeneratedDueDate,
		R.IsPrivateLabel,
		R.IsDSL,
		@False ISACH,
		CASE WHEN R.SourceTable = @ReceivableSourceTable_CPUSchedule AND R.EntityType = @ReceivableEntityType_CT THEN CPUB.InvoiceTransitDays ELSE CB.InvoiceTransitDays END AS CT_InvoiceTransitDays,
		CASE WHEN R.SourceTable = @ReceivableSourceTable_CPUSchedule AND R.EntityType = @ReceivableEntityType_CT THEN CPUB.InvoiceLeadDays ELSE CB.InvoiceLeaddays END AS CT_InvoiceLeadDays,
		CASE WHEN R.SourceTable = @ReceivableSourceTable_CPUSchedule AND R.EntityType = @ReceivableEntityType_CU THEN CPUB.InvoiceTransitDays ELSE CU.InvoiceTransitDays END AS CU_InvoiceTransitDays,
		CASE WHEN R.SourceTable = @ReceivableSourceTable_CPUSchedule AND R.EntityType = @ReceivableEntityType_CU THEN CPUB.InvoiceLeadDays ELSE CU.InvoiceLeadDays END AS CU_InvoiceLeadDays,
		RD.AssetId AS AssetId,
		RI.StatementInvoicePreference AS RI_StatementInvoicePreference,
		RI.SplitByAsset,
		RI.SplitCreditsByOriginalInvoice,
		RI.SplitByReceivableAdj,
		RI.SplitByContract,
		RI.SplitByLocation,
		RI.SplitReceivableDueDate,
		RI.SplitCustomerPurchaseOrderNumber,
		B.GenerateSummaryInvoice,
		B.StatementInvoiceFormatId,
		RCTG.Id AS ReceivableCategoryId,
		RCTG.[Name] AS ReceivableCategoryName,
		RI.InvoiceAmount_Amount AS InvoiceAmount,
		RI.Balance_Amount AS InvoiceBalance,
		RI.EffectiveBalance_Amount AS InvoiceEffectiveBalance,
		RI.InvoiceAmount_Currency AS InvoiceCurrency,
		Currencies.Id AS CurrencyId,
		R.AlternateBillingCurrencyId AS AlternateBillingCurrencyId,
		RD.Amount_Amount AS ReceivableDetailAmount,
		RD.Balance_Amount AS ReceivableDetailBalance,
		RD.EffectiveBalance_Amount AS ReceivableDetailEffectiveBalance,
		0.00 AS OriginalTaxBalance, --Remove
		0.00 AS OriginalTaxEffectiveBalance, --Remove
		NULL AS LocationId,
		RT.IsRental IsReceivableTypeRental,
		ISNULL(RDWHT.Balance_Amount, 0.00) AS WithHoldingTaxAmount,
		ISNULL(RDWHT.Balance_Amount, 0.00) AS WithHoldingTaxBalance,
		RT.Id AS ReceivableTypeId,
		RT.[Name] AS ReceivableTypeName,
		RC.Id AS ReceivableCodeId,
		CASE WHEN RI.LastStatementGeneratedDueDate IS NULL THEN @True ELSE @False END AS IsCurrentInstance,
		@CreatedById,
		@CreatedTime,
		NULL AS UpdatedById,
		NULL AS UpdatedTime,
		NULL AS GroupNumber,
		RC.DefaultInvoiceReceivableGroupingOption,
		CASE WHEN RD.AdjustmentBasisReceivableDetailId IS NOT NULL THEN 1 ELSE 0 END,
		RD.AdjustmentBasisReceivableDetailId AS AdjustmentBasisReceivableDetailId,
		RI.ReportFormatId,
		RI.InvoiceTaxAmount_Amount,
		RI.TaxBalance_Amount,
		RI.EffectiveTaxBalance_Amount,
		R.ExchangeRate,
		CASE WHEN RI.LastStatementGeneratedDueDate IS NULL THEN @False ELSE @True END AS IsOffPeriod,
		@True AS IsActive, --Remove Column
		NULL AS CustomerPurchaseOrderNumber,
		P.PartyNumber,
		CCC.ISO,
		P.PartyName,
		RTO.[Name],
		NULL [AlternateBillingCurrencyISO],
		LE.LegalEntityNumber
	FROM Receivables AS R
	INNER JOIN LegalEntities LE ON R.LegalEntityId = LE.Id
		AND R.IsActive = 1
	INNER JOIN #LegalEntityIds LEI ON LE.Id = LEI.LegalEntityId
	INNER JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId
		AND RD.IsActive = 1
	INNER JOIN ReceivableInvoiceDetails RID ON RD.Id = RID.ReceivableDetailId AND RID.IsActive = 1
	INNER JOIN ReceivableInvoices RI ON RID.ReceivableInvoiceId = RI.Id AND RI.IsActive = 1
	INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
	INNER JOIN ReceivableCategories RCTG ON RC.ReceivableCategoryId = RCTG.Id
	INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
	INNER JOIN Customers CU ON CU.Id = R.CustomerId   
	INNER JOIN Parties P ON CU.Id = P.Id
	INNER JOIN BillToes B ON RD.BillToId = B.Id
	INNER JOIN RemitToes RTO ON R.RemitToId = RTO.Id
	INNER JOIN CurrencyCodes CCC ON CCC.ISO = RD.Amount_Currency
		AND CCC.IsActive = 1
	INNER JOIN Currencies ON CCC.Id = Currencies.CurrencyCodeId
		AND Currencies.IsActive = 1
	LEFT JOIN Contracts C ON R.EntityId = C.Id
		AND R.EntityType = @ReceivableEntityType_CT
		AND (@ExcludeBackgroundProcessingPendingContracts = 0 OR C.BackgroundProcessingPending = 0)
	LEFT JOIN ContractBillings CB ON C.Id = CB.Id
		AND CB.IsActive = 1 --TODO: Check if CB.IsActive can be removed since 1-1 JOIN
	LEFT JOIN ReceivableWithholdingTaxDetails RWHT ON R.Id = RWHT.ReceivableId --TODO: Check if WithHoldingTaxes is a Filter Criteria for Off PEriod SI
		AND RWHT.IsActive = 1
	LEFT JOIN ReceivableDetailsWithholdingTaxDetails RDWHT ON RD.Id = RDWHT.ReceivableDetailId
		AND RDWHT.IsActive = 1
	LEFT JOIN #PreviousJobBillToIds PJ ON B.Id=PJ.BillToId
	LEFT JOIN CPUSchedules CPUS ON R.SourceId = CPUS.Id AND R.SourceTable = @ReceivableSourceTable_CPUSchedule
	LEFT JOIN CPUBillings CPUB ON CPUS.CPUFinanceId = CPUB.Id
	WHERE 
		R.IsServiced = 1
		AND RI.IsStatementInvoice = 0
		AND RD.BilledStatus = @BilledStatus_Invoiced
		AND RD.IsTaxAssessed = 1
		AND RD.StopInvoicing = 0
		AND RT.[Name] NOT IN (
			@ReceivableType_LeasePayOff,
			@ReceivableType_BuyOut
			)
		AND (
			(
				R.IsDummy = 1
				AND R.IsDSL = 1
				)
			OR R.IsDummy = 0
			)
		AND (
			@WithHoldingTaxApplicable = 0
			OR RWHT.Id IS NOT NULL
			)
		AND (
			@DiscountingId IS NULL
			OR (
				R.EntityId = @DiscountingId
				AND R.EntityType = @ReceivableEntityType_DT
				)
			)
		AND (
			@ContractId IS NULL
			OR (
				R.EntityId = @ContractId
				AND R.EntityType = @ReceivableEntityType_CT
				)
			)
		AND (
			@CustomerId IS NULL
			OR (R.CustomerId = @CustomerId)
			)
		AND (
			@IsAllLease = 0
			OR (C.ContractType = @ContractFilterEntityType_Lease)
			)
		AND (
			@IsAllLoan = 0
			OR (C.ContractType = @ContractFilterEntityType_Loan)
			)
		AND (
			@IsAllLeveragedLease = 0
			OR (C.ContractType = @ContractFilterEntityType_LeveragedLease)
			)
		AND
			(B.GenerateStatementInvoice = 1)
		AND 
			(
			RI.DueDate <= CASE 
					WHEN @IsInvoiceSensitive = 1
					THEN CASE 
							WHEN R.SourceTable =@ReceivableSourceTable_CPUSchedule 
								THEN DATEADD(DD, CPUB.InvoiceLeaddays, @ProcessThroughDate)
							WHEN R.EntityType = @ReceivableEntityType_CU
								OR R.EntityType = @ReceivableEntityType_DT
								THEN DATEADD(DD, CU.InvoiceLeadDays, @ProcessThroughDate)
							ELSE DATEADD(DD, CASE WHEN B.SplitRentalInvoiceByContract = 1 THEN CB.InvoiceLeaddays ELSE CU.InvoiceLeadDays END, @ProcessThroughDate)
							END
					ELSE @ProcessThroughDate
				END
			)
		AND (
			@IsReRun = 0 OR PJ.BillToId IS NOT NULL
			)
		AND (RD.EffectiveBalance_Amount + RID.EffectiveTaxBalance_Amount) != 0
	
END

GO

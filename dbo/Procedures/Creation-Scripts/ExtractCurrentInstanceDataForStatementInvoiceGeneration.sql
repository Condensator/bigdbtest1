SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


 
CREATE PROCEDURE [dbo].[ExtractCurrentInstanceDataForStatementInvoiceGeneration] (
	@JobStepInstanceId BIGINT,
	@ChunkNumber BIGINT,
	@CreatedById BIGINT,
	@CreatedTime DATETIMEOFFSET,
	@ProcessThroughDate DATETIME,
	@SourceJobStepInstanceId BIGINT,
	@ReceivableEntityType_CT NVARCHAR(100),
	@ReceivableEntityType_CU NVARCHAR(100),
	@ReceivableEntityType_DT NVARCHAR(100),
	@ReceivableSourceTable_CPUSchedule NVARCHAR(100),
	@OneTimeACHStatus_Reversed NVARCHAR(100)
	)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @True AS BIT = CONVERT(BIT, 1)
	DECLARE @False AS BIT = CONVERT(BIT, 0)

	CREATE TABLE #ChunkBillToes(
		BillToId BIGINT PRIMARY KEY
	)

	INSERT INTO #ChunkBillToes(BillToId)
	SELECT BillToId FROM InvoiceChunkDetails_Extract 
	WHERE JobStepInstanceId=@JobStepInstanceId AND ChunkNumber=@ChunkNumber

	INSERT INTO [dbo].[StatementInvoiceReceivableDetails_Extract]
           ([ReceivableInvoiceId]
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
		   ,[IsOffPeriod]
		   ,[IsReceivableAdjustment]
		   ,[AdjustmentBasisReceivableDetailId]
		   ,[ReportFormatId]
		   ,[InvoiceTaxAmount]
		   ,[InvoiceTaxBalance]
		   ,[InvoiceTaxEffectiveBalance]
		   ,[ExchangeRate]
		   ,[IsActive]
		   ,[AssetPurchaseOrderNumber]
		   ,[CustomerNumber]
		   ,[CurrencyISO]
		   ,[CustomerName]
		   ,[RemitToName]
		   ,[AlternateBillingCurrencyISO]
		   ,[LegalEntityNumber])
	SELECT 
		RI.Id AS ReceivableInvoiceId,
		RD.Id AS ReceivableDetailId,
		R.Id AS ReceivableId,
		@JobStepInstanceId AS JobStepInstanceId,
		@ProcessThroughDate AS JobProcessThroughDate,
		@False AS IsInvoiceSensitive,
		R.EntityType AS EntityType,
		R.EntityId AS EntityId,
		R.LegalEntityId AS LegalEntityId,
		C.ContractType,
		ContractId = CASE 
			WHEN R.EntityType = @ReceivableEntityType_CT
				THEN R.EntityId
			ELSE NULL
			END,
		DiscountingId = CASE 
			WHEN R.EntityType = @ReceivableEntityType_DT
				THEN R.EntityId
			ELSE NULL
			END,
		B.Id AS BillToId,
		R.RemitToId AS RemitToId,
		CU.Id AS CustomerId,
		RI.DueDate AS InvoiceDueDate,
		R.DueDate AS ReceivableDueDate,
		RI.LastStatementGeneratedDueDate AS LastStatementGeneratedDueDate,
		R.IsPrivateLabel,
		R.IsDSL,
		IsACH = @False,
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
		0.00 AS OriginalTaxBalance, --Remove Column in cleanup
		0.00 AS OriginalTaxEffectiveBalance, --Remove Column in cleanup
		NULL AS LocationId,
		RT.IsRental IsReceivableTypeRental,
		ISNULL(RDWHT.Balance_Amount, 0.00) AS WithHoldingTaxAmount,
		ISNULL(RDWHT.Balance_Amount, 0.00) AS WithHoldingTaxBalance,
		RT.Id AS ReceivableTypeId,
		RT.[Name] AS ReceivableTypeName,
		RC.Id AS ReceivableCodeId,
		@True AS IsCurrentInstance,  --Always True
		@CreatedById,
		@CreatedTime,
		NULL AS UpdatedById,
		NULL AS UpdatedTime,
		NULL AS GroupNumber,
		RC.DefaultInvoiceReceivableGroupingOption,
		@False AS IsOffPeriod,
		CASE WHEN RD.AdjustmentBasisReceivableDetailId IS NOT NULL THEN 1 ELSE 0 END,
		RD.AdjustmentBasisReceivableDetailId AS AdjustmentBasisReceivableDetailId,
		RI.ReportFormatId,
		RI.InvoiceTaxAmount_Amount,
		RI.TaxBalance_Amount,
		RI.EffectiveTaxBalance_Amount,
		R.ExchangeRate,
		IsActive = @True, --Remove
		NULL AS CustomerPurchaseOrderNumber,
		P.PartyNumber,
		CCC.ISO,
		P.PartyName,
		RTO.[Name],
		NULL [AlternateBillingCurrencyISO],
		LE.LegalEntityNumber
	FROM #ChunkBillToes ICDE
	INNER JOIN ReceivableInvoices RI ON ICDE.BillToId = RI.BillToId 
	INNER JOIN ReceivableInvoiceDetails RID ON RI.Id = RID.ReceivableInvoiceId AND RI.JobStepInstanceId = @SourceJobStepInstanceId --SourceJobStepInstanceIdn will be the same as JobStepInstanceId if fresh run
	INNER JOIN ReceivableDetails RD ON RID.ReceivableDetailId = RD.Id
	INNER JOIN Receivables R ON RD.ReceivableId = R.Id
	INNER JOIN LegalEntities LE ON R.LegalEntityId = LE.Id
	INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
	INNER JOIN ReceivableCategories RCTG ON RC.ReceivableCategoryId = RCTG.Id
	INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
	INNER JOIN Customers CU ON CU.Id = R.CustomerId   
	INNER JOIN Parties P ON CU.Id = P.Id
	INNER JOIN BillToes B ON RD.BillToId = B.Id AND B.GenerateStatementInvoice = 1
	INNER JOIN RemitToes RTO ON R.RemitToId = RTO.Id 
	INNER JOIN CurrencyCodes CCC ON CCC.ISO = RD.Amount_Currency
	INNER JOIN Currencies ON CCC.Id = Currencies.CurrencyCodeId
	LEFT JOIN Contracts C ON R.EntityId = C.Id
		AND R.EntityType = @ReceivableEntityType_CT
	LEFT JOIN ContractBillings CB ON C.Id = CB.Id
		AND CB.IsActive = 1 --TODO: Check if IsActive can be removed for ContractBillings 
	LEFT JOIN ReceivableDetailsWithholdingTaxDetails RDWHT ON RD.Id = RDWHT.ReceivableDetailId
		AND RDWHT.IsActive = 1
	LEFT JOIN CPUSchedules CPUS ON R.SourceId = CPUS.Id AND R.SourceTable = @ReceivableSourceTable_CPUSchedule
	LEFT JOIN CPUBillings CPUB ON CPUS.CPUFinanceId = CPUB.Id
	WHERE (RD.EffectiveBalance_Amount + RID.EffectiveTaxBalance_Amount) != 0

	UPDATE SIRD
	SET AssetPurchaseOrderNumber = A.CustomerPurchaseOrderNumber
	FROM StatementInvoiceReceivableDetails_Extract SIRD
	INNER JOIN #ChunkBillToes C ON SIRD.BillToId=C.BillToId
	INNER JOIN Assets A ON SIRD.AssetId=A.Id
	WHERE SIRD.SplitCustomerPurchaseOrderNumber = 1 AND SIRD.JobStepInstanceId=@JobStepInstanceId -- Remove SIRD.IsActive 

	UPDATE SIRD
	SET LocationId = A.LocationId
	FROM StatementInvoiceReceivableDetails_Extract SIRD
	INNER JOIN #ChunkBillToes C ON SIRD.BillToId=C.BillToId
	INNER JOIN AssetLocations A ON A.AssetId = SIRD.AssetId
		AND A.IsActive = 1
		AND A.IsCurrent = 1
	WHERE SIRD.SplitLeaseRentalInvoiceByLocation = 1 AND SIRD.JobStepInstanceId=@JobStepInstanceId -- Remove SIRD.IsActive

	UPDATE SIRD
	SET IsACH = CASE 
			WHEN ACHS.Id IS NULL
				THEN 0
			ELSE 1
		END
	FROM StatementInvoiceReceivableDetails_Extract SIRD
	INNER JOIN #ChunkBillToes C ON SIRD.BillToId=C.BillToId
	INNER JOIN ACHSchedules ACHS ON SIRD.ReceivableId = ACHS.ReceivableId
	AND ACHS.IsActive = 1 AND ACHS.[Status] != @OneTimeACHStatus_Reversed AND SIRD.JobStepInstanceId=@JobStepInstanceId -- Remove SIRD.IsActive 

	UPDATE SIRD
	SET AlternateBillingCurrencyISO = CCOD.ISO
	FROM StatementInvoiceReceivableDetails_Extract SIRD
	INNER JOIN #ChunkBillToes C ON SIRD.BillToId=C.BillToId
	INNER JOIN Currencies CC ON SIRD.AlternateBillingCurrencyId = CC.Id
	INNER JOIN CurrencyCodes CCOD on CC.CurrencyCodeId = CCOD.Id
	WHERE SIRD.JobStepInstanceId=@JobStepInstanceId   -- Remove SIRD.IsActive 

END

GO

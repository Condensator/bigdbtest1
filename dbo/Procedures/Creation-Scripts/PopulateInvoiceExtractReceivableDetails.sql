SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[PopulateInvoiceExtractReceivableDetails] (
	@JobStepInstanceId BIGINT,
	@SourceJobStepInstanceId BIGINT,
	@ChunkNumber INT,
	@CreatedById BIGINT,
	@CreatedTime DATETIMEOFFSET,
	@BillNegativeandZeroReceivables BIT,
	@InvoicePreference_SuppressDelivery NVARCHAR(100),
	@InvoicePreference_SuppressGeneration NVARCHAR(100),
	@InvoicePreference_GenerateAndDeliver NVARCHAR(100),
	@ContractFilterEntityType_Lease NVARCHAR(100),
	@ContractFilterEntityType_Loan NVARCHAR(100),
	@ContractFilterEntityType_ProgressLoan NVARCHAR(100),
	@ReceivableEntityType_CT NVARCHAR(100),
	@ReceivableEntityType_DT NVARCHAR(100),
	@ReceivableSourceTable_Unknown NVARCHAR(100),
	@ReceivableSourceTable_CPUSchedule NVARCHAR(100),
	@AssetMultipleSerialNumberType NVARCHAR(10)
)
AS
BEGIN

	DECLARE @PaymentType_DownPayment NVARCHAR(11) = 'DownPayment'
	DECLARE @ReceivableTaxType_VAT NVARCHAR(3) = 'VAT'

	CREATE TABLE #ReceivableAsset (
		ReceivableInvoiceDetailId BIGINT,
		ReceivableDetailID BIGINT,
		AssetId BIGINT,
		AssetAddressLine1 NVARCHAR(50),
		AssetAddressLine2 NVARCHAR(50),
		AssetCity NVARCHAR(40),
		AssetState NVARCHAR(5),
		AssetDivision NVARCHAR(40),
		AssetCountry NVARCHAR(5),
		AssetPostalCode NVARCHAR(12),
		AssetPurchaseOrderNumber NVARCHAR(40),
		AssetDescription NVARCHAR(500),
		u_CustomerReference1 NVARCHAR(100),
		u_CustomerReference2 NVARCHAR(100),
		u_CustomerReference3 NVARCHAR(100),
		u_CustomerReference4 NVARCHAR(100),
		u_CustomerReference5 NVARCHAR(100)
	);

	CREATE NONCLUSTERED INDEX [IX_ReceivableAsset_InvoiceId_RecDetailId] ON [#ReceivableAsset] 
	(
		[ReceivableInvoiceDetailId],
		[ReceivableDetailID]
	) 

	CREATE TABLE #ReceivableInvoices(
		Id BIGINT NOT NULL PRIMARY KEY,
		BillToId BIGINT NOT NULL,
		CustomerId BIGINT NOT NULL,
		AlternateBillingCurrencyId BIGINT NULL
	)

	INSERT INTO #ReceivableInvoices(Id, BillToId, CustomerId, AlternateBillingCurrencyId)
	SELECT RI.Id, RI.BillToId, RI.CustomerId, RI.AlternateBillingCurrencyId FROM
	ReceivableInvoices RI 
	INNER JOIN InvoiceChunkDetails_Extract ICD ON ICD.JobStepInstanceId = @JobStepInstanceId 
		AND ICD.ChunkNumber = @ChunkNumber 
		AND RI.JobStepInstanceId = @SourceJobStepInstanceId
		AND ICD.BillToId = RI.BillToId
		AND RI.IsActive=1 
	WHERE RI.StatementInvoicePreference IN(@InvoicePreference_GenerateAndDeliver,@InvoicePreference_SuppressDelivery) AND 
	((@BillNegativeandZeroReceivables = 0 AND (RI.InvoiceAmount_Amount > 0 OR RI.InvoiceTaxAmount_Amount > 0 OR RI.Balance_Amount > 0 OR RI.TaxBalance_Amount > 0))
	OR @BillNegativeandZeroReceivables = 1)

	CREATE TABLE #ReceivableInfo(
	    [ReceivableId] BIGINT PRIMARY KEY,
		EntityType NVARCHAR(2),
		EntityId BIGINT,
		ReceivableCodeId BIGINT,
		ReceivableDueDate DATE,
		ExchangeRate DECIMAL(20, 10),
		SourceTable NVARCHAR(20),
		PaymentScheduleId BIGINT
	)

	CREATE NONCLUSTERED INDEX IX_EntityIdType ON #ReceivableInfo(EntityId) --, EntityType)

	CREATE TABLE #ReceivableDetailInfo(
		InvoiceId BIGINT,
		[ReceivableInvoiceDetailId] BIGINT,
		[ReceivableDetailId] BIGINT,
		[ReceivableId] BIGINT,
		BlendNumber INT,
		InvoiceAmount DECIMAL(16, 2),
		InvoiceAmountCurrency NVARCHAR(3),
		InvoiceTaxAmount DECIMAL(16, 2),
		AlternateBillingCurrencyId BIGINT,
		AssetId BIGINT NULL,
		PaymentType NVARCHAR(40)
	)

	CREATE NONCLUSTERED INDEX IX_ReceivableDetailId ON #ReceivableDetailInfo([ReceivableDetailId]) 
	
	INSERT INTO #ReceivableDetailInfo(
		InvoiceId ,
		[ReceivableInvoiceDetailId],
		[ReceivableDetailId],
		ReceivableId,
		BlendNumber ,
		InvoiceAmount,
		InvoiceAmountCurrency,
		InvoiceTaxAmount,
		AlternateBillingCurrencyId, --ri
		AssetId,
		PaymentType
	)
	SELECT
		ri.Id [InvoiceID],
		rid.Id [ReceivableInvoiceDetailId],
		rd.Id [ReceivableDetailId],
		rd.ReceivableId,
		rid.BlendNumber,
		rid.InvoiceAmount_Amount,
		rid.InvoiceAmount_Currency, 
		rid.InvoiceTaxAmount_Amount, 
		ri.AlternateBillingCurrencyId,
		rd.AssetId,
		rid.PaymentType
	FROM #ReceivableInvoices ri
	INNER JOIN ReceivableInvoiceDetails rid ON ri.Id = rid.ReceivableInvoiceId AND rid.IsActive = 1
	INNER JOIN ReceivableDetails rd ON rid.ReceivableDetailId = rd.Id

	;WITH DistinctReceivables AS (
	   SELECT ReceivableId FROM #ReceivableDetailInfo GROUP BY ReceivableId
	)
	INSERT INTO #ReceivableInfo(
		ReceivableId,
		EntityType,
		EntityId,
		ReceivableCodeId,
		ReceivableDueDate,
		ExchangeRate,
		SourceTable ,
		PaymentScheduleId 
	)
	SELECT
	    r.Id,
		r.EntityType,
		r.EntityId,
		r.ReceivableCodeId, 
		r.DueDate, 
		r.ExchangeRate, 
		r.SourceTable, 
		r.PaymentScheduleId 
	FROM DistinctReceivables d
	INNER JOIN Receivables r ON d.ReceivableId = r.Id
		
	CREATE TABLE #DownPaymentReceivableIds
	(
	ReceivableDetailId BIGINT
	)
		
	INSERT INTO #ReceivableAsset (
		ReceivableInvoiceDetailId,
		ReceivableDetailID,
		AssetId,
		AssetAddressLine1,
		AssetAddressLine2,
		AssetCity,
		AssetState,
		AssetDivision,
		AssetCountry,
		AssetPostalCode,
		AssetPurchaseOrderNumber,
		AssetDescription
	)
	SELECT 
		D.[ReceivableInvoiceDetailId],
		D.[ReceivableDetailId],
		assets.Id [AssetId],
		Locations.AddressLine1 [AssetAddressLine1],
		Locations.AddressLine2 [AssetAddressLine2],
		Locations.City [AssetCity],
		States.ShortName [AssetState],
		Locations.Division [AssetDivision],
		Countries.ShortName [AssetCountry],
		Locations.PostalCode [AssetPostalCode],
		assets.CustomerPurchaseOrderNumber [AssetPurchaseOrderNumber],
		assets.Description [AssetDescription]
	FROM #ReceivableDetailInfo D
	INNER JOIN Assets assets ON D.AssetId = assets.Id
	INNER JOIN ReceivableTaxDetails rtd ON D.ReceivableDetailId = rtd.ReceivableDetailId
		AND rtd.AssetId = D.AssetId
		AND rtd.IsActive = 1
	LEFT JOIN Locations ON rtd.LocationId = Locations.Id
	LEFT JOIN States ON Locations.StateId = States.Id
	LEFT JOIN Countries ON States.CountryId = Countries.Id
	
	INSERT INTO #ReceivableAsset (
		ReceivableInvoiceDetailId,
		ReceivableDetailID,
		AssetAddressLine1,
		AssetAddressLine2,
		AssetCity,
		AssetState,
		AssetDivision,
		AssetCountry,
		AssetPostalCode
	)
	SELECT 
		D.[ReceivableInvoiceDetailId],
		D.[ReceivableDetailId],
		Locations.AddressLine1 [AssetAddressLine1],
		Locations.AddressLine2 [AssetAddressLine2],
		Locations.City [AssetCity],
		States.ShortName [AssetState],
		Locations.Division [AssetDivision],
		Countries.ShortName [AssetCountry],
		Locations.PostalCode [AssetPostalCode]
	FROM #ReceivableDetailInfo D
	INNER JOIN #ReceivableInfo R ON D.ReceivableId=R.ReceivableId
	INNER JOIN Contracts ON R.EntityId = Contracts.Id AND Contracts.ContractType = @ContractFilterEntityType_Loan AND R.EntityType=@ReceivableEntityType_CT
	INNER JOIN ReceivableTaxDetails rtd ON D.ReceivableDetailId = rtd.ReceivableDetailId
		AND rtd.IsActive = 1
	LEFT JOIN Locations ON rtd.LocationId = Locations.Id
	LEFT JOIN States ON Locations.StateId = States.Id
	LEFT JOIN Countries ON States.CountryId = Countries.Id

     --Assumptions Rare case
	SELECT 
	   D.ReceivableId,
	   conhis.SequenceNumber [SequenceNumber],
	   ROW_NUMBER() OVER (PARTITION BY RD.InvoiceId ORDER BY conhis.Id) RowNumber
     INTO #AssumedContractDetails
     FROM #ReceivableInfo D
	INNER JOIN #ReceivableDetailInfo RD ON D.ReceivableId=RD.ReceivableId
     INNER JOIN Contracts con ON con.Id = D.EntityId
	   AND D.EntityType = @ReceivableEntityType_CT
     INNER JOIN ContractAssumptionHistories conhis ON conhis.ContractId = con.Id
	   AND conhis.IsActive = 1
     INNER JOIN Assumptions ON conhis.AssumptionId = Assumptions.Id
     LEFT JOIN LeasePaymentSchedules ON Assumptions.LeasePaymentId = LeasePaymentSchedules.Id
     LEFT JOIN LoanPaymentSchedules ON Assumptions.LoanPaymentId = LoanPaymentSchedules.Id
     WHERE (
		  LeasePaymentSchedules.Id IS NOT NULL
		  AND D.ReceivableDueDate < LeasePaymentSchedules.DueDate
		  )
	   OR D.ReceivableDueDate < LoanPaymentSchedules.DueDate

	CREATE TABLE #ContractDetails(
		[ReceivableId] BIGINT NOT NULL,
		[EntityType] NVARCHAR(2) NOT NULL,
		[SequenceNumber] NVARCHAR(40) NULL,
		[EntityId] BIGINT NOT NULL,
		[MaturityDate] DATE NULL,
		[ContractPurchaseOrderNumber] NVARCHAR(40) NULL,
		[AdditionalComments] NVARCHAR(200) NULL,
		[AdditionalInvoiceCommentBeginDate] DATE NULL,
		[AdditionalInvoiceCommentEndDate] DATE NULL,
		[ContractType] NVARCHAR(14) NULL
	)

	CREATE NONCLUSTERED INDEX IX_InvoiceEntity ON #ContractDetails([ReceivableId], EntityType, EntityId)

	INSERT INTO #ContractDetails(
		[ReceivableId], EntityType, EntityId
	)
	SELECT 
		R.ReceivableId, R.EntityType, R.EntityId
	FROM #ReceivableInfo R
	WHERE R.EntityType='CU'

	CREATE TABLE #FinancesContractDetails(
		[ReceivableId] BIGINT,
		[EntityType] NVARCHAR(2),
		[ContractType] NVARCHAR(14),
		[SequenceNumber] NVARCHAR(40) NULL,
		[ContractId] BIGINT,
		[AdditionalComments] NVARCHAR(200),
		[AdditionalInvoiceCommentBeginDate] DATE NULL,
		[AdditionalInvoiceCommentEndDate] DATE NULL
	)

	INSERT INTO #FinancesContractDetails([ReceivableId], EntityType, ContractType, SequenceNumber, [ContractId], [AdditionalComments], [AdditionalInvoiceCommentBeginDate], [AdditionalInvoiceCommentEndDate])
	SELECT 
		R.[ReceivableId], r.EntityType, c.ContractType, ISNULL(Assumption.SequenceNumber, c.SequenceNumber), c.Id, 
		SUBSTRING(cb.InvoiceComment, 1, 200)   [AdditionalComments],
		cb.InvoiceCommentBeginDate	[AdditionalInvoiceCommentBeginDate],
		cb.InvoiceCommentEndDate	[AdditionalInvoiceCommentEndDate]
	FROM #ReceivableInfo r 
	INNER JOIN Contracts c ON r.EntityId = c.Id  AND r.EntityType = @ReceivableEntityType_CT
	INNER JOIN ContractBillings CB ON C.Id=CB.Id AND CB.IsActive=1
	LEFT JOIN #AssumedContractDetails Assumption ON Assumption.ReceivableId = r.ReceivableId AND Assumption.RowNumber = 1

	--For Loans
	INSERT INTO #ContractDetails(
		[ReceivableId],
		[EntityType],
		[SequenceNumber],
		[EntityId],
		[MaturityDate],
		[ContractPurchaseOrderNumber],
		[AdditionalComments],
		[AdditionalInvoiceCommentBeginDate],
		[AdditionalInvoiceCommentEndDate],
		[ContractType]
	)
	SELECT 
		F.[ReceivableId], F.EntityType, F.SequenceNumber, F.ContractId, L.MaturityDate, L.ContractPurchaseOrderNumber,
		F.[AdditionalComments],
		F.[AdditionalInvoiceCommentBeginDate],
		F.[AdditionalInvoiceCommentEndDate], F.ContractType
	FROM #FinancesContractDetails F 
	INNER JOIN LoanFinances L ON L.ContractId = F.[ContractId]
		AND L.IsCurrent = 1
	WHERE F.ContractType IN (@ContractFilterEntityType_Loan,@ContractFilterEntityType_ProgressLoan)

	--For Leases
	INSERT INTO #ContractDetails(
		[ReceivableId],
		[EntityType],
		[SequenceNumber],
		[EntityId],
		[MaturityDate],
		[ContractPurchaseOrderNumber],
		[AdditionalComments],
		[AdditionalInvoiceCommentBeginDate],
		[AdditionalInvoiceCommentEndDate],
		[ContractType]
	)
	SELECT 
		F.[ReceivableId], @ReceivableEntityType_CT, F.SequenceNumber, F.ContractId, LD.MaturityDate, L.PurchaseOrderNumber,
		F.[AdditionalComments],
		F.[AdditionalInvoiceCommentBeginDate],
		F.[AdditionalInvoiceCommentEndDate], @ContractFilterEntityType_Lease
	FROM #FinancesContractDetails F 
	INNER JOIN LeaseFinances L ON L.ContractId = F.ContractId
		AND L.IsCurrent = 1
	INNER JOIN LeaseFinanceDetails LD ON L.Id = LD.Id
	WHERE F.ContractType IN (@ContractFilterEntityType_Lease)
	GROUP BY F.[ReceivableId], F.SequenceNumber, F.ContractId, LD.MaturityDate, L.PurchaseOrderNumber, F.[AdditionalComments],
		F.[AdditionalInvoiceCommentBeginDate],
		F.[AdditionalInvoiceCommentEndDate]

	--For Discountings
	INSERT INTO #ContractDetails(
		[ReceivableId],
		[EntityType],
		[SequenceNumber],
		[EntityId],
		[MaturityDate]
	)
	SELECT 
		r.[ReceivableId], @ReceivableEntityType_DT, D.SequenceNumber, D.Id, DF.MaturityDate
	FROM #ReceivableInfo r
	INNER JOIN Discountings D ON r.EntityId = D.Id
		AND r.EntityType = @ReceivableEntityType_DT
	INNER JOIN DiscountingFinances DF ON DF.DiscountingId = D.Id
		AND DF.IsCurrent = 1
	GROUP BY r.[ReceivableId], D.SequenceNumber, D.Id, DF.MaturityDate
	
	CREATE TABLE #PaymentSchedules(
		Id BIGINT,
		StartDate DATE,
		EndDate DATE
	)

INSERT INTO #PaymentSchedules(Id, StartDate, EndDate)
	SELECT DISTINCT lps.Id, lps.StartDate, lps.EndDate
	FROM #ReceivableInfo D 
	INNER JOIN LeasePaymentSchedules lps ON D.PaymentScheduleId = lps.Id		
		AND D.SourceTable = @ReceivableSourceTable_Unknown
	INNER JOIN Contracts C ON C.Id = D.EntityId AND D.EntityType = @ReceivableEntityType_CT AND C.ContractType = @ContractFilterEntityType_Lease

	INSERT INTO #PaymentSchedules(Id, StartDate, EndDate)
	SELECT DISTINCT lps.Id, lps.StartDate, lps.EndDate
	FROM #ReceivableInfo D 
	INNER JOIN LoanPaymentSchedules lps ON D.PaymentScheduleId = lps.Id	
		AND D.SourceTable = @ReceivableSourceTable_Unknown
	INNER JOIN Contracts C ON C.Id = D.EntityId AND D.EntityType = @ReceivableEntityType_CT AND (C.ContractType = @ContractFilterEntityType_Loan OR C.ContractType = @ContractFilterEntityType_ProgressLoan)

	INSERT INTO #PaymentSchedules(Id, StartDate, EndDate)
	SELECT DISTINCT lps.Id, lps.StartDate, lps.EndDate
	FROM #ReceivableInfo D 
	INNER JOIN CPUPaymentSchedules lps ON D.PaymentScheduleId = lps.Id		
		AND D.SourceTable = @ReceivableSourceTable_CPUSchedule

;WITH CTE_CTE_DistinctAssetIds AS(
	SELECT DISTINCT AssetId FROM #ReceivableAsset WHERE AssetId IS NOT NULL
),
CTE_AssetSerialNumberDetails AS(
SELECT 
	ASN.AssetId,
	SerialNumber = CASE WHEN count(ASN.Id) > 1 THEN @AssetMultipleSerialNumberType ELSE MAX(ASN.SerialNumber) END  
FROM CTE_CTE_DistinctAssetIds A
join AssetSerialNumbers ASN on A.AssetId = ASN.AssetId AND ASN.IsActive=1
GROUP BY ASN.AssetId
)	
	INSERT INTO InvoiceExtractReceivableDetails (
		InvoiceID,
		ReceivableInvoiceDetailId,
		ReceivableDetailID,
		BlendNumber,
		ReceivableAmount_Amount,
		ReceivableAmount_Currency,
		TaxAmount_Amount,
		TaxAmount_Currency,
		PeriodStartDate,
		PeriodEndDate,
		ReceivableCategoryId,
		ReceivableCodeId,
		AssetId,
		AssetAddressLine1,
		AssetAddressLine2,
		AssetCity,
		AssetState,
		AssetDivision,
		AssetCountry,
		AssetPostalCode,
		AssetPurchaseOrderNumber,
		AssetSerialNumber,
		AssetDescription,
		u_CustomerReference1,
		u_CustomerReference2,
		u_CustomerReference3,
		u_CustomerReference4,
		u_CustomerReference5,
		CreatedById,
		CreatedTime,
		EntityType,
		SequenceNumber,
		EntityId,
		MaturityDate,
		ContractPurchaseOrderNumber,
		AdditionalComments,
		AdditionalInvoiceCommentBeginDate,
		AdditionalInvoiceCommentEndDate,
		ExchangeRate,
		AlternateBillingCurrencyCodeId,
		WithHoldingTax_Amount,
		WithHoldingTax_Currency,
		IsDownPaymentVATReceivable
		)
	SELECT D.[InvoiceID],
		D.[ReceivableInvoiceDetailId],
		D.[ReceivableDetailId],
		D.BlendNumber,
		D.InvoiceAmount,
		D.InvoiceAmountCurrency,
		D.InvoiceTaxAmount,
		D.InvoiceAmountCurrency,
		CASE 
			WHEN (R.SourceTable = @ReceivableSourceTable_CPUSchedule)
				THEN LPS.StartDate
			WHEN (cd.ContractType = @ContractFilterEntityType_Lease)
				THEN LPS.StartDate
			WHEN cd.ContractType = @ContractFilterEntityType_Loan
				THEN LPS.StartDate
			ELSE NULL
	     END [PeriodStartDate],
		CASE 
			WHEN R.SourceTable = @ReceivableSourceTable_CPUSchedule
				THEN LPS.EndDate
			WHEN (cd.ContractType = @ContractFilterEntityType_Lease)
				THEN LPS.EndDate
			WHEN cd.ContractType = @ContractFilterEntityType_Loan
				THEN LPS.EndDate
			ELSE NULL
		END [PeriodEndDate],
		rcode.ReceivableCategoryId [ReceivableCategoryId],
		rcode.Id [ReceivableCodeId],
		ra.AssetId,
		AssetAddressLine1,
		AssetAddressLine2,
		AssetCity,
		AssetState,
		AssetDivision,
		AssetCountry,
		AssetPostalCode,
		AssetPurchaseOrderNumber,
		ASN.SerialNumber,
		AssetDescription,
		u_CustomerReference1,
		u_CustomerReference2,
		u_CustomerReference3,
		u_CustomerReference4,
		u_CustomerReference5,
		@CreatedById,
		@CreatedTime,
		cd.EntityType EntityType,
		cd.SequenceNumber,
		cd.EntityId,
		MaturityDate,
		ContractPurchaseOrderNumber,
		cd.[AdditionalComments],
		cd.[AdditionalInvoiceCommentBeginDate],
		cd.[AdditionalInvoiceCommentEndDate],
		R.ExchangeRate [ExchangeRate],
		CurrencyCodes.Id [AlternateBillingCurrencyCodeId],
		ISNULL(rdwtd.Tax_Amount, 0),
		ISNULL(rdwtd.Tax_Currency, D.InvoiceAmountCurrency),
		CASE WHEN D.PaymentType = @PaymentType_DownPayment THEN 1 ELSE 0 END
	FROM #ReceivableDetailInfo D
	INNER JOIN #ReceivableInfo R ON D.ReceivableId=R.ReceivableId
	INNER JOIN ReceivableCodes rcode ON R.ReceivableCodeId=rcode.Id
	INNER JOIN #ContractDetails cd ON R.ReceivableId = cd.ReceivableId
		AND R.EntityType = cd.EntityType
		AND R.EntityId = cd.EntityId
	INNER JOIN Currencies ON Currencies.Id = D.AlternateBillingCurrencyId
	INNER JOIN CurrencyCodes ON CurrencyCodes.Id = Currencies.CurrencyCodeId
		AND CurrencyCodes.IsActive = 1
	LEFT JOIN #PaymentSchedules LPS ON R.PaymentScheduleId=LPS.Id
	LEFT JOIN #ReceivableAsset ra ON ra.ReceivableInvoiceDetailId = D.ReceivableInvoiceDetailId
		AND ra.ReceivableDetailId = D.ReceivableDetailId
	LEFT JOIN CTE_AssetSerialNumberDetails ASN ON ra.AssetId = ASN.AssetId
	LEFT JOIN ReceivableDetailsWithholdingTaxDetails rdwtd ON rdwtd.ReceivableDetailId = D.ReceivableDetailId
		AND rdwtd.IsActive = 1

	INSERT INTO dbo.InvoiceExtractReceivableTaxDetails (
		InvoiceID,
		TaxTypeId,
		ReceivableDetailId,
		ReceivableTaxDetailId,
		AssetId,
		Rent_Amount,
		Rent_Currency,
		TaxAmount_Amount,
		TaxAmount_Currency,
		ExternalJurisdictionId,
		ImpositionType,
		ReceivableCodeId,
		CreatedById,
		CreatedTime,
		TaxCodeId,
		TaxRate,
		TaxTreatment
		)
	SELECT rd.[InvoiceId],
		rti.TaxTypeId [TaxTypeId],
		rd.[ReceivableDetailId],
		rtd.Id [ReceivableTaxDetailId],
		rtd.AssetId [AssetId],
		rti.TaxableBasisAmount_Amount [Rent_Amount],
		rti.TaxableBasisAmount_Currency,
		rti.Amount_Amount [TaxAmount],
		rti.Amount_Currency,
		rti.ExternalJurisdictionLevelId [ExternalJurisdictionId],
		rti.ExternalTaxImpositionType [ImpositionType],
		r.ReceivableCodeId [ReceivableCodeId],
		@CreatedById,
		@CreatedTime,
		rtd.TaxCodeId,
		rti.AppliedTaxRate * 100,
		tc.TaxTreatment
	FROM #ReceivableDetailInfo rd
	INNER JOIN #ReceivableInfo r on rd.ReceivableId=r.ReceivableId
	INNER JOIN ReceivableTaxes rt ON rt.ReceivableId = rd.ReceivableId
		AND rt.IsActive = 1
	INNER JOIN dbo.ReceivableTaxDetails rtd ON rtd.ReceivableDetailId = rd.ReceivableDetailId
		AND rtd.IsActive = 1 -- If Tax is there active, then child details should also be active
		AND rtd.ReceivableTaxId = rt.Id
	INNER JOIN ReceivableTaxImpositions rti ON rtd.Id = rti.ReceivableTaxDetailId
		AND rti.IsActive = 1
	LEFT JOIN TaxCodes tc ON rtd.TaxCodeId = tc.Id
	 
	DROP TABLE #ContractDetails
	DROP TABLE #AssumedContractDetails
	DROP TABLE #ReceivableAsset
		
	DROP TABLE #ReceivableInvoices
	DROP TABLE #ReceivableInfo
	DROP TABLE #ReceivableDetailInfo
	DROP TABLE #FinancesContractDetails
	DROP TABLE #PaymentSchedules
	DROP TABLE #DownPaymentReceivableIds

END

GO

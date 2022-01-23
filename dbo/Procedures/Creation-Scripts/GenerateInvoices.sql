SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GenerateInvoices]
(
@ProcessThroughDate DATETIME
,@ContractID BIGINT = NULL
,@DiscountingID BIGINT = NULL
,@RunTimeComment NVARCHAR(MAX) = NULL
,@IsAllDiscounting BIT = 0
,@IsAllLease BIT = 0
,@IsAllLoan BIT = 0
,@IsAllLeveragedLease BIT = 0
,@InvoiceType NVARCHAR(100) = NULL
,@JobStepInstanceId BIGINT
,@CreatedBy BIGINT
,@CreatedTime DATETIMEOFFSET
,@IsInvoiceSensitive BIT = 0
,@InvoicePreference NVARCHAR(MAX)
,@CustomerDetails CustomerDetails READONLY
,@IsPastDueCalculationRequired NVARCHAR(5)
,@BillNegativeandZeroReceivables NVARCHAR(5)
,@ApplicableCurrentDate DATETIME
,@IsWHTApplicable BIT = 0
)
AS
SET NOCOUNT ON;
SET XACT_ABORT ON
BEGIN TRANSACTION InvoiceGeneration
BEGIN TRY
	DECLARE @ReceivableCount BIGINT
	DECLARE @InvoicedBilledStatus NVARCHAR(20) = 'Invoiced'
	DECLARE @NotInvoicedBilledStatus NVARCHAR(20) = 'NotInvoiced'
	DECLARE @SuppressGenerationInvoicePreferance NVARCHAR(20) = 'SuppressGeneration'
	DECLARE @ComputedProcessThroughDate ComputedProcessThroughDate
	DECLARE @CreatedDate DATE = @ApplicableCurrentDate;
	DECLARE @InvoiceTypeId BIGINT

	SET @InvoiceTypeId = (SELECT Id FROM InvoiceTypes WHERE Name = @InvoiceType AND @InvoiceType != '_')
				 
	CREATE TABLE #InsertedInvoice 
	(
	 	Id BIGINT NOT NULL
		,InvoiceNumber NVARCHAR(100)
		,CurrencyISO NVARCHAR(80)
		,CustomerId BIGINT
		,LegalEntityId BIGINT
	)

	SELECT Id INTO #ReceivableTypeIds FROM ReceivableTypes WHERE Name NOT IN ('LeasePayOff','LoanPayDown','BuyOut')

	SELECT * INTO #CustomerDetails FROM (SELECT * FROM @CustomerDetails CustomerDetails) AS cusdet

	/*Table holds receivable details*/
	CREATE TABLE #ReceivableDetailsToProcess(
		 ReceivableID BIGINT
		,ReceivableDetailId BIGINT
		,BillToID BIGINT
		,DefaultInvoiceReceivableGroupingOption NVARCHAR(50)
		,DefaultInvoiceComment NVARCHAR(max)
		,EntityType NVARCHAR(50)
		,ContractId BIGINT
		,ContractType NVARCHAR(14)
		,Syndicated BIT
		,DiscountingId BIGINT
		,CustomerId BIGINT
		,Amount_Amount DECIMAL(18, 2)
		,InvoicePreferenceAllowed BIT
		,ReceivableTypeID BIGINT
		,DueDate DATETIME
		,InvoiceDueDate DATETIME
		,InvoicePreferenceValue NVARCHAR(50)
		,RemitToId BIGINT
		,TaxRemitToId BIGINT
		,IsRental BIT
		,ReceivableCategoryId BIGINT
		,ReceivableCodeId BIGINT
		,LegalEntityId BIGINT
		,CurrenciesId BIGINT
		,RDAmount DECIMAL(18, 2)
		,Balance_Amount DECIMAL(18, 2)
		,EffectiveBalance_Amount DECIMAL(18, 2)
		,Amount_Currency NVARCHAR(80)
		,AssetID BIGINT
		,LocationID BIGINT
		,CapSoftAssetID BIGINT
		,IsPrivateLabel BIT
		,IsDSL BIT
		,IsACH BIT
		,ReceivableTypeName NVARCHAR(50)
		,ExchangeRate DECIMAL(20,10)
		,AlternateBillingCurrencyId BIGINT
		,AdjustmentBasisReceivableDetailId BIGINT
		,WithHoldingTaxAmount DECIMAL(18, 2)
		,WithHoldingTaxBalance DECIMAL(18, 2)
		)

	 CREATE NONCLUSTERED INDEX [IX_ReceivableDetailsToProcess_CustomerId_ReceivableTypeId_DueDate]  
		ON [dbo].[#ReceivableDetailsToProcess] ([CustomerId],[ReceivableTypeID],[DueDate]) 
		INCLUDE ([ReceivableID])  
  
	 CREATE NONCLUSTERED INDEX [IX_ReceivableDetailsToProcess_ContractId]  
		 ON [dbo].[#ReceivableDetailsToProcess] ([ContractId]) 
		 INCLUDE ([ReceivableID],[ReceivableTypeID],[DueDate])  

	 CREATE NONCLUSTERED INDEX [IX_ReceivableId] ON [dbo].[#ReceivableDetailsToProcess] ([ReceivableID]) 
 
	 CREATE NONCLUSTERED INDEX [IX_ReceivableDetailId] ON [dbo].[#ReceivableDetailsToProcess] ([ReceivableDetailID])  

	UPDATE #CustomerDetails
	SET #CustomerDetails.InvoiceTransitDays = customer.InvoiceTransitDays
	FROM Customers customer
	JOIN #CustomerDetails ON customer.Id = #CustomerDetails.CustomerId

	CREATE NONCLUSTERED INDEX [IX_CustomerId]  ON [dbo].[#CustomerDetails] ([CustomerId])  

	/* Table holds receivable details records preference and category */
	CREATE TABLE #ReceivableDetailTableWithPreference  (
		ReceivableID BIGINT
		,ReceivableDetailId BIGINT
		,BillToID BIGINT
		,DefInvoiceReceivableGrpOptn NVARCHAR(50)
		,DefInvoiceReceivableGrpOptnSplit BIGINT
		,DefInvComment NVARCHAR(max)
		,EntityType NVARCHAR(50)
		,ContractId BIGINT
		,DiscountingId BIGINT
		,CustomerId BIGINT
		,RecDetailAmount DECIMAL(18, 2)
		,InvoicePreferenceAllow BIT
		,ReceivableTypeID BIGINT
		,ReceivableDueDate DATETIME
		,InvoicePreferenceValue NVARCHAR(50)
		,RemitToId BIGINT
		,TaxRemitToId BIGINT
		,Pk BIGINT Identity(1, 1)
		,IsRental BIT
		,ReceivableCategoryId BIGINT
		,LegalEntityId BIGINT
		,CurrencyId BIGINT
		,Amount DECIMAL(18, 2)
		,Balance DECIMAL(18, 2)
		,EffectiveBalance DECIMAL(18, 2)
		,CurrencyISO NVARCHAR(80)
		,AssetID BIGINT
		,LocationID BIGINT
		,BlendReceivableDetailId BIGINT
		,DueDate DATETIME
		,IsPrivateLabel BIT
		,OriginationSource NVARCHAR(50)
		,OriginationSourceId BIGINT
		,IsDSL BIT
		,IsACH BIT
		,ReceivableTypeName NVARCHAR(50)
		,ExchangeRate DECIMAL(20,10)
		,AlternateBillingCurrencyId BIGINT
		,AdjustmentBasisReceivableDetailId BIGINT
		,IsAdjustmentReceivable BIT
		,WithHoldingTaxAmount DECIMAL(18, 2)
		,WithHoldingTaxBalance DECIMAL(18, 2)
		)

	CREATE NONCLUSTERED INDEX [IX_ReceivableDetailTableWithPreference_InvoicePreference]  ON [dbo].[#ReceivableDetailTableWithPreference] ([ReceivableDetailId]) 
	CREATE NONCLUSTERED INDEX [IX_ReceivableDetailTableWithPreference_BillTo]  ON [dbo].[#ReceivableDetailTableWithPreference] ([BillToID])  

	/*Table used for determining contract Preference */
	CREATE TABLE #ContractPreferenceToUse  (
		ReceivableId BIGINT
		,ContractId BIGINT
		,ContractInvoicePreference NVARCHAR(50)
		)
	/*Table used for determining Customer Preference */
	CREATE TABLE #CustomerPreferenceToUse  (
		ReceivableId BIGINT
		,CustomerID BIGINT
		,CustomerInvoicePreference NVARCHAR(50)
		)
	/*Table used for determining Bill to Invoice Parameter details */
	CREATE TABLE #BillDetails  (
		ReceivableTypeId BIGINT
		,ReceivableSubTypeId BIGINT
		,BlendReceivableSubTypeId BIGINT
		,BillToName NVARCHAR(200)
		,CustomerBillToName NVARCHAR(500)
		,InvoiceComment NVARCHAR(1000)
		,BillingContactPersonId BIGINT
		,BillingAddressId BIGINT
		,DeliverInvoiceViaEmail BIT
		,DeliverInvoiceViaMail BIT
		,SendCCEmailNotificationTo NVARCHAR(500)
		,SendEmailNotificationTo NVARCHAR(500)
		,SplitByReceivableAdjustments BIT
		,SplitCreditsByOriginalInvoice BIT
		,SplitLeaseRentalinvoiceByLocation BIT
		,SplitRentalInvoiceByAsset BIT
		,SplitRentalInvoiceByContract BIT
		,UseLocationAddressForBilling BIT
		,GenerateSummaryInvoice BIT
		,BillToId BIGINT
		,AllowBlend BIT
		)

	CREATE NONCLUSTERED INDEX [IX_BillToId]  ON [dbo].[#BillDetails] ([BillToId])

	/*Table holds resultant receivable details to be invoiced */
	CREATE TABLE #ReceivableInvoice (
		Number NVARCHAR(100)
		,DueDate DATETIME
		,SplitByContract BIT
		,SplitByLocation BIT
		,SplitByAsset BIT
		,SplitCreditsByOriginalInvoice BIT
		,SplitByReceivableAdj BIT
		,GenerateSummaryInvoice BIT
		,CustomerId BIGINT
		,BillTo BIGINT
		,RemitToId BIGINT
		,LegalEntityId BIGINT
		,ReceivableCategoryId BIGINT
		,ReportFormatId BIGINT
		,CurrencyId BIGINT
		,ReceivableId BIGINT
		,ReceivableDetailId BIGINT
		,OriginalTaxBalance DECIMAL(18, 2)
		,OriginalEffectiveTaxBalance DECIMAL(18, 2)
		,OriginalTaxAmount DECIMAL(18, 2)
		,ReceivableDetailAmount DECIMAL(18, 2)
		,ReceivableDetailBalance DECIMAL(18, 2)
		,ReceivableDetailEffectiveBalance DECIMAL(18, 2)
		,CurrencyISO NVARCHAR(80)
		,InvoicePreference NVARCHAR(80)
		,BlendNumber BIGINT
		,EntityType NVARCHAR(MAX)
		,EntityId BIGINT
		,IsPrivateLabel BIT
		,OriginationSource NVARCHAR(50)
		,OriginationSourceId BIGINT
		,IsDSL BIT
		,IsACH BIT
		,IsRental BIT
		,ReceivableTypeName NVARCHAR(50)
		,ExchangeRate DECIMAL(20,10)
		,AlternateBillingCurrencyId BIGINT
		,WithHoldingTaxAmount DECIMAL(18, 2)
		,WithHoldingTaxBalance DECIMAL(18, 2)
		)

		CREATE NONCLUSTERED INDEX [IX_Number]  ON [dbo].[#ReceivableInvoice] ([Number])

		/*To implement Contract level Lead Days and Due Day*/
		CREATE TABLE #ProcessThroughDate(
		EntityId BIGINT
		,EntityType NVARCHAR(2)
		,CustomerId BIGINT
		,LeadDays INT
		,DueDay INT
		,UpdateThroughDate DATETIME
		)

		CREATE NONCLUSTERED INDEX [IX_EntityId]  ON [dbo].[#ProcessThroughDate] ([EntityId]) INCLUDE (EntityType, CustomerId)

		Create Table #InvoiceNumberGenerator
		(
			SequenceGeneratedInvoiceNumber NVARCHAR(100),
			InvoiceRankValue NVARCHAR(100)
		)

		INSERT INTO #ProcessThroughDate (EntityId,EntityType,CustomerId,LeadDays,DueDay,UpdateThroughDate)
			SELECT DISTINCT #CustomerDetails.CustomerId,'CU',#CustomerDetails.CustomerId,#CustomerDetails.InvoiceLeadDays,0,@ProcessThroughDate 
			FROM #CustomerDetails
			WHERE @IsAllDiscounting = 0

		;WITH CTELeadDays AS
		(
			SELECT DISTINCT
				R.EntityId ContractId, 
				#CustomerDetails.CustomerId,
				#CustomerDetails.InvoiceLeadDays
			FROM Receivables R
			JOIN #CustomerDetails 
				ON r.CustomerId  = #CustomerDetails.CustomerId 
				AND r.IsActive = 1
				AND r.EntityType = 'CT'
		)
		SELECT DISTINCT 
			C.Id, 
			Customer.CustomerId, 
			CB.InvoiceLeadDays ContractInvoiceLeadDays, 
			Customer.InvoiceLeadDays CustomerInvoiceLeadDays, 
			C.ContractType, C.Status
		INTO #LeadDays
		FROM CTELeadDays Customer
		JOIN Contracts C 
			ON Customer.ContractId = C.Id 
		JOIN ContractBillings CB 
			ON CB.Id = C.Id 
			AND CB.IsActive = 1

		CREATE NONCLUSTERED INDEX [IX_Id]  ON [dbo].[#LeadDays] ([Id]) INCLUDE (CustomerId, CustomerInvoiceLeadDays, ContractInvoiceLeadDays, ContractType, Status)

		INSERT INTO #ProcessThroughDate (EntityId,EntityType,CustomerId,LeadDays,DueDay,UpdateThroughDate)
		SELECT DISTINCT lf.ContractId,'CT',C.CustomerId, 
			CASE WHEN C.ContractInvoiceLeadDays = 0 THEN C.CustomerInvoiceLeadDays ELSE C.ContractInvoiceLeadDays END,lfd.DueDay, @ProcessThroughDate 
		FROM #LeadDays C
		JOIN LeaseFinances lf ON c.Id = lf.ContractId
		JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
		WHERE lf.IsCurrent = 1
		AND (@ContractID IS NULL OR lf.ContractId = @ContractID) 
		AND (@IsAllLease = 0 OR C.ContractType = 'Lease')
		AND @IsAllDiscounting = 0
		AND NOT ((c.Status = 'Pending' OR c.Status = 'InstallingAssets' OR c.Status = 'UnCommenced') AND lfd.CreateInvoiceForAdvanceRental = 1)

		INSERT INTO #ProcessThroughDate (EntityId,EntityType,CustomerId,LeadDays,DueDay,UpdateThroughDate)
		SELECT DISTINCT lf.ContractId,'CT',C.CustomerId, 
			CASE WHEN C.ContractInvoiceLeadDays = 0 THEN C.CustomerInvoiceLeadDays ELSE C.ContractInvoiceLeadDays END,lf.DueDay,	@ProcessThroughDate 
		FROM #LeadDays C
		JOIN LoanFinances lf ON C.Id = lf.ContractId
		WHERE lf.IsCurrent = 1
		AND (@ContractID IS NULL OR lf.ContractId = @ContractID)
		AND (@IsAllLoan = 0 OR C.ContractType = 'Loan')
		AND @IsAllDiscounting = 0
		AND NOT ((C.Status = 'Pending' OR C.Status = 'InstallingAssets' OR C.Status = 'UnCommenced') AND lf.CreateInvoiceForAdvanceRental = 1)

		INSERT INTO #ProcessThroughDate (EntityId,EntityType,CustomerId,LeadDays,DueDay,UpdateThroughDate)
		SELECT DISTINCT lf.ContractId, 'CT', C.CustomerId, 
			CASE WHEN C.ContractInvoiceLeadDays = 0 THEN C.CustomerInvoiceLeadDays ELSE C.ContractInvoiceLeadDays END,0,	@ProcessThroughDate 
		FROM #LeadDays C
		JOIN LeveragedLeases lf ON C.Id = lf.ContractId
		WHERE lf.IsCurrent = 1
		AND (@ContractID IS NULL OR lf.ContractId = @ContractID)
		AND @IsAllDiscounting = 0
		AND (@IsAllLeveragedLease = 0 OR C.ContractType = 'LeveragedLease')

		INSERT INTO #ProcessThroughDate (EntityId,EntityType,CustomerId,LeadDays,DueDay,UpdateThroughDate)
		SELECT DISTINCT Discounting.Id,'DT',#CustomerDetails.CustomerId, #CustomerDetails.InvoiceLeadDays,0,@ProcessThroughDate FROM Discountings Discounting
		JOIN Receivables ON Receivables.EntityId = Discounting.Id
		JOIN #CustomerDetails ON #CustomerDetails.CustomerId = Receivables.CustomerId
		WHERE Receivables.IsActive = 1
		AND Receivables.EntityType = 'DT'
		AND (@DiscountingID IS NULL OR Discounting.Id = @DiscountingID)

		IF @IsInvoiceSensitive = 1
		BEGIN
			UPDATE #ProcessThroughDate SET UpdateThroughDate = DATEADD(DD,LeadDays,UpdateThroughDate)
		END

		INSERT INTO @ComputedProcessThroughDate(EntityId,EntityType,CustomerId,LeadDays,DueDay,ComputedProcessThroughDate)
		SELECT * FROM #ProcessThroughDate
		/*To implement Contract level Lead Days and Due Day*/

		Select RD.ReceivableId, RD.Id ReceivableDetailId 
		INTO #ReceivableDetails
		FROM Receivables AS R
		INNER JOIN #CustomerDetails ON #CustomerDetails.CustomerId = R.CustomerId
			AND #CustomerDetails.LegalEntityId = R.LegalEntityId
		INNER JOIN ReceivableDetails AS RD ON R.Id = RD.ReceivableId
			AND R.IsActive = 1
			AND RD.IsActive = 1
			AND RD.BilledStatus = @NotInvoicedBilledStatus
			AND RD.IsTaxAssessed = 1
			AND RD.StopInvoicing = 0
		WHERE R.IsServiced = 1
			AND ((R.IsDummy = 1 AND R.IsDSL = 1) OR R.IsDummy = 0)

		INSERT INTO #ReceivableDetailsToProcess
		(
		ReceivableID 
		,ReceivableDetailId 
		,BillToID 
		,DefaultInvoiceReceivableGroupingOption
		,DefaultInvoiceComment
		,EntityType 
		,ContractId 
		,ContractType 
		,Syndicated 
		,DiscountingId
		,CustomerId 
		,Amount_Amount
		,InvoicePreferenceAllowed 
		,ReceivableTypeID 
		,DueDate 
		,InvoiceDueDate 
		,InvoicePreferenceValue
		,RemitToId 
		,TaxRemitToId 
		,IsRental 
		,ReceivableCategoryId 
		,ReceivableCodeId
		,LegalEntityId 
		,CurrenciesId 
		,RDAmount 
		,Balance_Amount 
		,EffectiveBalance_Amount
		,Amount_Currency 
		,AssetID 
		,LocationID 
		,CapSoftAssetID 
		,IsPrivateLabel 
		,IsDSL 
		,IsACH 
		,ReceivableTypeName
		,ExchangeRate 
		,AlternateBillingCurrencyId 
		,AdjustmentBasisReceivableDetailId 
		,WithHoldingTaxAmount
		,WithHoldingTaxBalance
		)
		SELECT R.Id ReceivableID
			,RD.ID ReceivableDetailId
			,RD.BillToId
			,RC.DefaultInvoiceReceivableGroupingOption
			--,Contracts.InvoiceComment
			,RC.DefaultInvoiceComment
			,R.EntityType
			,CASE 
				WHEN R.EntityType = 'CT'
					THEN R.EntityId
				ELSE NULL
				END 'ContractId'
				,CASE 
				WHEN R.EntityType = 'CT'
					THEN C.ContractType
				ELSE NULL
				END 'ContractType'
			, CASE 
				WHEN (C.SyndicationType = '_' OR C.SyndicationType = 'None')
					THEN CONVERT(BIT,0)
				ELSE CONVERT(BIT,1)
				END 'Syndicated'
			,CASE
				WHEN R.EntityType = 'DT' 
					THEN R.EntityId
				ELSE NULL
				END 'DiscountingId'
			,R.CustomerId
			,RD.Amount_Amount
			,RT.InvoicePreferenceAllowed
			,RT.Id ReceivableTypeID
			,R.DueDate
			,CASE
			WHEN (LE.InvoiceDueDateCalculation = 'OnReceivableDueDate' )
				THEN CASE
						WHEN (@CreatedDate > (DATEADD(DAY, #CustomerDetails.InvoiceTransitDays, R.DueDate)))
							THEN R.DueDate
						ELSE (DATEADD(DAY, #CustomerDetails.InvoiceTransitDays, R.DueDate))
					 END
			ELSE
				CASE
					WHEN (R.DueDate <= DATEADD(DAY,#CustomerDetails.InvoiceTransitDays,@CreatedDate))
						THEN DATEADD(DAY,#CustomerDetails.InvoiceTransitDays,@CreatedDate)
					ELSE	R.DueDate
				END
			END InvoiceDueDate
			,@InvoicePreference InvoicePreferenceValue
			,R.RemitToId
			,R.TaxRemitToId
			,RT.IsRental
			,ReceivableCategories.Id ReceivableCategoryId
			,R.ReceivableCodeId
			,R.LegalEntityId
			,Currencies.Id CurrenciesId
			,RD.Amount_Amount RDAmount
			,RD.Balance_Amount
			,RD.EffectiveBalance_Amount
			,RD.Amount_Currency
			,RD.AssetID
			,AssetLocations.LocationId
			,CapitalizeLA.AssetID CapSoftAssetID
			,R.IsPrivateLabel IsPrivateLabel
			,R.IsDSL
			,CASE WHEN a.Id IS NULL THEN Convert(BIT,0) ELSE Convert(BIT,1) END IsACH
			,RT.Name 'ReceivableTypeName'
			,R.ExchangeRate
			,R.AlternateBillingCurrencyId
			,RD.AdjustmentBasisReceivableDetailId
			,ISNULL(RDWHT.Tax_Amount, 0)
			,ISNULL(RDWHT.Balance_Amount, 0)
		FROM Receivables AS R
		INNER JOIN #ReceivableDetails ON  R.Id = #ReceivableDetails.ReceivableId
		INNER JOIN #CustomerDetails ON #CustomerDetails.CustomerId = R.CustomerId
			AND #CustomerDetails.LegalEntityId = R.LegalEntityId
		INNER JOIN LegalEntities AS LE ON #CustomerDetails.LegalEntityId=LE.Id
		INNER JOIN ReceivableDetails AS RD ON RD.Id = #ReceivableDetails.ReceivableDetailId
		INNER JOIN ReceivableCodes AS RC ON R.ReceivableCodeId = RC.Id
		INNER JOIN ReceivableCategories ON ReceivableCategories.Id = RC.ReceivableCategoryId
		INNER JOIN ReceivableTypes AS RT ON RC.ReceivableTypeId = RT.Id
		INNER JOIN Customers ON Customers.ID = R.CustomerId
		INNER JOIN #ProcessThroughDate ProcessThroughDate ON R.EntityId = ProcessThroughDate.EntityId 
			AND R.DueDate <= ProcessThroughDate.UpdateThroughDate
			AND R.EntityType = ProcessThroughDate.EntityType
			AND R.CustomerId = ProcessThroughDate.CustomerId
		INNER JOIN CurrencyCodes ON CurrencyCodes.ISO = RD.Amount_Currency
			AND CurrencyCodes.IsActive = 1
		INNER JOIN Currencies ON CurrencyCodes.Id = Currencies.CurrencyCodeId
			AND Currencies.IsActive = 1
		INNER JOIN #ReceivableTypeIds ON #ReceivableTypeIds.Id = RT.Id
		LEFT JOIN Contracts C ON R.EntityId = C.Id
			AND R.EntityType = 'CT'
		LEFT JOIN LeaseFinances ON LeaseFinances.ContractId = C.Id
			AND LeaseFinances.IsCurrent = 1
		LEFT JOIN LeaseAssets ON leaseassets.leasefinanceid = leasefinances.id
			AND leaseassets.AssetId = RD.AssetId
			AND LeaseAssets.CapitalizedForId IS NOT NULL
		LEFT JOIN LeaseAssets AS CapitalizeLA ON CapitalizeLA.id = leaseassets.CapitalizedForId
		LEFT JOIN AssetLocations ON AssetLocations.AssetId = RD.AssetId
			AND AssetLocations.IsActive = 1
			AND AssetLocations.IsCurrent = 1
		LEFT JOIN dbo.ACHSchedules a ON R.Id = a.ReceivableId AND a.IsActive = 1 AND a.Status != 'Reversed'
		LEFT JOIN ReceivableWithholdingTaxDetails RWHT ON R.Id = RWHT.ReceivableId AND RWHT.IsActive = 1
		LEFT JOIN ReceivableDetailsWithholdingTaxDetails RDWHT ON RD.Id = RDWHT.ReceivableDetailId AND RDWHT.IsActive = 1
		WHERE (@DiscountingID IS NULL OR R.EntityId = @DiscountingID AND R.EntityType = 'DT')
			AND (@ContractID IS NULL OR R.EntityId = @ContractID AND R.EntityType = 'CT')
			AND (@IsAllLease = 0 OR C.ContractType = 'Lease' )
			AND (@IsAllLoan = 0 OR C.ContractType = 'Loan' )
			AND (@IsAllLeveragedLease = 0 OR C.ContractType = 'LeveragedLease')
			AND (@InvoiceType = '_' OR  ReceivableCategories.InvoiceTypeId = @InvoiceTypeId )
			AND (@IsWHTApplicable = 0 OR RWHT.Id IS NOT NULL)
			
		SELECT DISTINCT(rdtp.BillToId) INTO #BillToesUsed FROM #ReceivableDetailsToProcess rdtp
		
		SELECT 
			CASE WHEN rdtp.DefaultInvoiceReceivableGroupingOption = 'Separate' 
			THEN ROW_NUMBER() OVER(Partition by rdtp.DefaultInvoiceReceivableGroupingOption ORDER BY rdtp.DefaultInvoiceReceivableGroupingOption)
			ELSE RANK() OVER(ORDER BY 
				CASE WHEN rdtp.DefaultInvoiceReceivableGroupingOption = 'Separate' THEN 0 ELSE 1 END,
				CASE WHEN rdtp.DefaultInvoiceReceivableGroupingOption != 'Separate' THEN rdtp.DefaultInvoiceReceivableGroupingOption END ASC) 
			END AS DefaultInvoiceReceivableGroupingOptionSplit,
			Id AS ReceivableCodeId,
			rdtp.ReceivableDetailId  
			INTO #ReceivableCodeSplitDetails
		FROM ReceivableCodes rc
		JOIN #ReceivableDetailsToProcess rdtp ON rc.Id = rdtp.ReceivableCodeId

		INSERT INTO #BillDetails (
		ReceivableTypeId
		,ReceivableSubTypeId
		,BlendReceivableSubTypeId
		,BillToName
		,CustomerBillToName
		,InvoiceComment
		,BillingContactPersonId
		,BillingAddressId
		,DeliverInvoiceViaEmail
		,DeliverInvoiceViaMail
		,SendCCEmailNotificationTo
		,SendEmailNotificationTo
		,SplitByReceivableAdjustments
		,SplitCreditsByOriginalInvoice
		,SplitLeaseRentalinvoiceByLocation
		,SplitRentalInvoiceByAsset
		,SplitRentalInvoiceByContract
		,UseLocationAddressForBilling
		,GenerateSummaryInvoice
		,BillToId
		,AllowBlend
		)
	SELECT InvoiceGroupingParameters.ReceivableTypeId
		,InvoiceGroupingParameters.ReceivableCategoryId
		,BillToInvoiceParameters.BlendReceivableCategoryId --ISNULL(InvoiceGroupingParameters.BlendReceivableSubTypeId, InvoiceGroupingParameters.ReceivableTypeId)
		,BillToes.NAME
		,BillToes.CustomerBillToName
		,BillToes.InvoiceComment
		,BillToes.BillingContactPersonId
		,BillToes.BillingAddressId
		,BillToes.DeliverInvoiceViaEmail
		,BillToes.DeliverInvoiceViaMail
		,BillToes.SendCCEmailNotificationTo
		,BillToes.SendEmailNotificationTo
		,BillToes.SplitByReceivableAdjustments
		,BillToes.SplitCreditsByOriginalInvoice
		,BillToes.SplitLeaseRentalinvoiceByLocation
		,BillToes.SplitRentalInvoiceByAsset
		,BillToes.SplitRentalInvoiceByContract
		,BillToes.UseLocationAddressForBilling
		,BillToes.GenerateSummaryInvoice
		,BillToes.Id
		,InvoiceGroupingParameters.AllowBlending
	FROM BillToes
	INNER JOIN BillToInvoiceParameters ON BillToes.Id = BillToInvoiceParameters.BillToId
	INNER JOIN InvoiceGroupingParameters ON InvoiceGroupingParameters.Id = BillToInvoiceParameters.InvoiceGroupingParameterId
		AND InvoiceGroupingParameters.IsActive= 1
	INNER JOIN #BillToesUsed btu ON dbo.BillToes.Id = btu.BillToId
		
	SELECT RD.ContractId
		,RD.ReceivableID
		,RD.DueDate
		,RD.ReceivableTypeID
	INTO #ReceivableContracts
	FROM #ReceivableDetailsToProcess AS RD
	WHERE RD.ContractId IS NOT NULL
	GROUP BY RD.ContractId
		,RD.ReceivableID
		,RD.DueDate
		,RD.ReceivableTypeID

	SELECT RecContract.ContractID
		,RecContract.ReceivableID
		,RecContract.ReceivableTypeID
		,MAX(CBP.EffectiveFromDate) EffectiveDate
	INTO #EffectiveDateForPreference
	FROM #ReceivableContracts AS RecContract
	INNER JOIN ContractBillings AS CB ON RecContract.ContractId = CB.Id
	INNER JOIN COntractBillingPreferences AS CBP ON CB.Id = CBP.ContractBillingId
		AND CBP.IsActive = 1
		AND CBP.ReceivableTypeId = RecContract.ReceivableTypeID
		AND CBP.EffectiveFromDate <= RecContract.DueDate
	GROUP BY RecContract.ContractID
		,RecContract.ReceivableID
		,RecContract.ReceivableTypeID
		
	/* Getting Contract Preference */
	INSERT INTO #ContractPreferenceToUse (
		ReceivableId
		,ContractId
		,ContractInvoicePreference
		)
	SELECT EDP.ReceivableID
		,EDP.Contractid
		,CBP.InvoicePreference
	FROM #EffectiveDateForPreference AS EDP
	INNER JOIN ContractBillings AS CB ON EDP.ContractId = CB.Id
	INNER JOIN COntractBillingPreferences AS CBP ON CB.Id = CBP.ContractBillingId
		AND CBP.ReceivableTypeId = EDP.ReceivableTypeID
		AND CBP.EffectiveFromDate = EDP.EffectiveDate
		AND CBP.IsActive =  1
		/*Querying to find customer preference with effective date*/

	CREATE NONCLUSTERED INDEX [IX_ReceivableId] ON [dbo].[#ContractPreferenceToUse] ([ReceivableId])

	SELECT RD.CustomerId
		,RD.ReceivableID
		,RD.DueDate
		,RD.ReceivableTypeID
	INTO #ReceivableCustomer
	FROM #ReceivableDetailsToProcess AS RD
	GROUP BY RD.CustomerId
		,RD.ReceivableID
		,RD.DueDate
		,RD.ReceivableTypeID

	SELECT RecCust.CustomerId
		,RecCust.ReceivableID
		,RecCust.ReceivableTypeID
		,MAX(CBP.EffectiveFromDate) EffectiveDate
	INTO #CustomerEffectiveDateForPreference
	FROM #ReceivableCustomer AS RecCust
	INNER JOIN CustomerBillingPreferences AS CBP ON RecCust.CustomerId = CBP.CustomerID
		AND CBP.IsActive = 1
		AND CBP.ReceivableTypeId = RecCust.ReceivableTypeID
		AND CBP.EffectiveFromDate <= RecCust.DueDate
	GROUP BY RecCust.CustomerId
		,RecCust.ReceivableID
		,RecCust.ReceivableTypeID

	/* Getting Contract Preference */
	INSERT INTO #CustomerPreferenceToUse (
		ReceivableId
		,CustomerID
		,CustomerInvoicePreference
		)
	SELECT EDP.ReceivableID
		,EDP.CustomerId
		,CBP.InvoicePreference
	FROM #CustomerEffectiveDateForPreference AS EDP
	INNER JOIN CustomerBillingPreferences AS CBP ON EDP.CustomerId = CBP.CustomerID
		AND CBP.ReceivableTypeId = EDP.ReceivableTypeID
		AND CBP.EffectiveFromDate = EDP.EffectiveDate
	GROUP BY EDP.ReceivableID
		,EDP.CustomerId
		,CBP.InvoicePreference

		CREATE NONCLUSTERED INDEX [IX_ReceivableId] ON [dbo].[#CustomerPreferenceToUse] ([ReceivableId])

	Select 
		ReceivableDetails.ReceivableId,
		ReceivableDetails.AssetId,
		ReceivableDetails.Id
	INTO #CapSoftReceivables
	From #ReceivableDetailsToProcess rdtp
	JOIN ReceivableDetails ON ReceivableDetails.ReceivableId = rdtp.ReceivableId AND ReceivableDetails.AssetId = rdtp.CapSoftAssetID

		;WITH CTE_ContractsInUse As
		(
			SELECT DISTINCT ContractId FROM #ReceivableDetailsToProcess  WHERE ContractType <> 'LeveragedLease'
		)		
		,CTE_ContractOriginationDetails AS
		(
			SELECT 

			Con.ContractId
			,CASE WHEN LOST.Name IS NULL 
					   THEN LoanOST.Name 
			ELSE LOST.Name END 'OriginationSource'
			,CASE WHEN LCO.OriginationSourceId IS NULL 
					   THEN LoanCO.OriginationSourceId
			ELSE LCO.OriginationSourceId END 'OriginationSourceId'
			,CASE WHEN LF.ContractOriginationId IS NOT NULL 
					   THEN LF.ContractOriginationId
			ELSE LoanF.ContractOriginationId END 'ContractOriginationId'

			FROM 
			Contracts C 
			INNER JOIN CTE_ContractsInUse Con ON C.Id = Con.ContractId

			LEFT JOIN LeaseFinances LF ON LF.ContractId = C.Id AND LF.IsCurrent = 1
			LEFT JOIN ContractOriginations LCO ON LF.ContractOriginationId = LCO.Id
			LEFT JOIN OriginationSourceTypes LOST ON LCO.OriginationSourceTypeId = LOST.Id

			LEFT JOIN LoanFinances LoanF ON LoanF.ContractId = C.Id AND LoanF.IsCurrent = 1
			LEFT JOIN ContractOriginations LoanCO ON LoanF.ContractOriginationId = LoanCO.Id
			LEFT JOIN OriginationSourceTypes LoanOST ON LoanCO.OriginationSourceTypeId = LoanOST.Id
		)
		,CTE_UpdatedContractOriginationDetails
		AS
		(
			SELECT 
			ROW_NUMBER() OVER (PARTITION BY COD.ContractOriginationId ORDER BY SD.Id) AS 'OriginationServicings'
			,COD.*
			,SD.IsPrivateLabel
			,SD.IsCobrand

			FROM 
			CTE_ContractOriginationDetails COD 
			LEFT JOIN ContractOriginationServicingDetails COSD ON COD.ContractOriginationId = COSD.ContractOriginationId
			LEFT JOIN ServicingDetails SD ON COSD.ServicingDetailId = SD.Id and SD.IsActive = 1
		)
		,CTE_ContractSyndicationDetails AS
		(
			SELECT 

			Con.ContractId
			,ROW_NUMBER() OVER (PARTITION BY RFT.Id ORDER BY RFTFS.Id) AS 'SyndicatedFunders'
			,'Indirect' AS 'OriginationSource'
			,RFTFS.FunderId 
			,RFT.Id 'ReceivableForTransferId'

			FROM 
			Contracts C 
			INNER JOIN CTE_ContractsInUse Con ON C.Id = Con.ContractId
			INNER JOIN ReceivableForTransfers RFT ON C.Id = RFT.ContractId AND RFT.ApprovalStatus = 'Approved'
			INNER JOIN ReceivableForTransferFundingSources RFTFS ON RFT.Id = RFTFS.ReceivableForTransferId AND RFTFS.IsActive = 1

			WHERE C.SyndicationType <> '_' AND C.SyndicationType <> 'None'
		)
		,CTE_UpdateContractSyndicationDetails
		AS
		(
			SELECT 
			ROW_NUMBER() OVER (PARTITION BY CSD.ReceivableForTransferId ORDER BY RFTS.Id) AS 'SyndicationServicings'
			,CSD.*
			,RFTS.IsPrivateLabel
			,RFTS.IsCobrand

			FROM 
			CTE_ContractSyndicationDetails CSD 
			INNER JOIN ReceivableForTransferServicings RFTS ON CSD.ReceivableForTransferId = RFTS.ReceivableForTransferId AND RFTS.IsActive = 1
			WHERE CSD.SyndicatedFunders = 1
		)

	INSERT INTO #ReceivableDetailTableWithPreference (
		ReceivableID
		,ReceivableDetailId
		,BillToID
		,DefInvoiceReceivableGrpOptn
		,DefInvoiceReceivableGrpOptnSplit
		,DefInvComment
		,EntityType
		,ContractId
		,DiscountingId
		,CustomerId
		,RecDetailAmount
		,InvoicePreferenceAllow
		,ReceivableTypeID
		,ReceivableDueDate
		,InvoicePreferenceValue
		,RemitToId
		,TaxRemitToId
		,IsRental
		,ReceivableCategoryId
		,CurrencyId
		,Amount
		,Balance
		,EffectiveBalance
		,LegalEntityId
		,CurrencyISO
		,AssetID
		,LocationID
		,BlendReceivableDetailId
		,DueDate
		,IsPrivateLabel
		,OriginationSource 
		,OriginationSourceId 
		,IsDSL
		,IsACH
		,ReceivableTypeName
		,ExchangeRate
		,AlternateBillingCurrencyId
		,AdjustmentBasisReceivableDetailId
		,IsAdjustmentReceivable
		,WithHoldingTaxAmount
		,WithHoldingTaxBalance
		)
	SELECT rdtp.ReceivableID
		,rdtp.ReceivableDetailId
		,rdtp.BillToId
		,rdtp.DefaultInvoiceReceivableGroupingOption
		,rcd.DefaultInvoiceReceivableGroupingOptionSplit 
		,rdtp.DefaultInvoiceComment
		,rdtp.EntityType
		,rdtp.ContractId
		,rdtp.DiscountingId
		,rdtp.CustomerId
		,rdtp.Amount_Amount
		,rdtp.InvoicePreferenceAllowed
		,rdtp.ReceivableTypeID
		,rdtp.InvoiceDueDate
		,CASE 
			WHEN ContractPreference.ContractInvoicePreference != '_'
				THEN ContractPreference.ContractInvoicePreference
			WHEN CustomerPreference.CustomerInvoicePreference != '_'
				THEN CustomerPreference.CustomerInvoicePreference
			ELSE rdtp.InvoicePreferenceValue
			END AS InvoicePreferenceValue
		,rdtp.RemitToId
		,rdtp.TaxRemitToId
		,rdtp.IsRental
		,rdtp.ReceivableCategoryId
		,rdtp.CurrenciesId
		,rdtp.Balance_Amount
		,rdtp.Balance_Amount
		,rdtp.EffectiveBalance_Amount
		,rdtp.LegalEntityId
		,rdtp.Amount_Currency
		,rdtp.AssetID
		,rdtp.LocationID
		,ISNULL(ReceivableDetails.Id, rdtp.ReceivableDetailId) BlendingReceivableDetailId
		,rdtp.DueDate
		,rdtp.IsPrivateLabel
		,CASE 
			WHEN (COD.OriginationSource = 'Vendor' OR COD.OriginationSource = 'Indirect') AND rdtp.Syndicated = 0 AND (COD.IsPrivateLabel = 1 OR COD.IsCobrand = 1) THEN COD.OriginationSource
			--WHEN (COD.OriginationSource = 'Vendor' OR COD.OriginationSource = 'Indirect') AND RDP.Syndicated = 0 AND COD.IsPrivateLabel = 0 THEN COD.OriginationSource direct
			WHEN (COD.OriginationSource = 'Vendor' OR COD.OriginationSource = 'Indirect') AND rdtp.Syndicated = 1 AND COD.IsPrivateLabel = 1 AND CSD.IsPrivateLabel = 1 THEN COD.OriginationSource
			--WHEN (COD.OriginationSource = 'Vendor' OR COD.OriginationSource = 'Indirect') AND RDP.Syndicated = 1 AND COD.IsPrivateLabel = 0 AND CSD.IsPrivateLabel = 1 THEN COD.OriginationSource
			WHEN (COD.OriginationSource = 'Vendor' OR COD.OriginationSource = 'Indirect') AND rdtp.Syndicated = 1 AND COD.IsPrivateLabel = 0 AND CSD.IsPrivateLabel = 0 THEN 'Indirect'
			WHEN (COD.OriginationSource = 'Direct') AND rdtp.Syndicated = 1 AND CSD.IsPrivateLabel = 0 THEN 'Indirect'
			ELSE 'Direct' 
		END 'OriginationSource'

		,CASE 
			WHEN (COD.OriginationSource = 'Vendor' OR COD.OriginationSource = 'Indirect') AND rdtp.Syndicated = 0 AND (COD.IsPrivateLabel = 1 OR COD.IsCobrand = 1) THEN COD.OriginationSourceId
			--WHEN (COD.OriginationSource = 'Vendor' OR COD.OriginationSource = 'Indirect') AND RDP.Syndicated = 0 AND COD.IsPrivateLabel = 0 THEN COD.OriginationSource direct
			WHEN (COD.OriginationSource = 'Vendor' OR COD.OriginationSource = 'Indirect') AND rdtp.Syndicated = 1 AND COD.IsPrivateLabel = 1 AND CSD.IsPrivateLabel = 1 THEN COD.OriginationSourceId
			--WHEN (COD.OriginationSource = 'Vendor' OR COD.OriginationSource = 'Indirect') AND RDP.Syndicated = 1 AND COD.IsPrivateLabel = 0 AND CSD.IsPrivateLabel = 1 THEN COD.OriginationSource
			WHEN (COD.OriginationSource = 'Vendor' OR COD.OriginationSource = 'Indirect') AND rdtp.Syndicated = 1 AND COD.IsPrivateLabel = 0 AND CSD.IsPrivateLabel = 0 THEN CSD.FunderId
			WHEN (COD.OriginationSource = 'Direct') AND rdtp.Syndicated = 1 AND CSD.IsPrivateLabel = 0 THEN CSD.FunderId
			ELSE rdtp.LegalEntityId 
		END 'OriginationSourceId'
		,rdtp.IsDSL
		,rdtp.IsACH
		,rdtp.ReceivableTypeName
		,rdtp.ExchangeRate
		,rdtp.AlternateBillingCurrencyId
		,rdtp.AdjustmentBasisReceivableDetailId
		,CASE WHEN rdtp.AdjustmentBasisReceivableDetailId IS NOT NULL THEN 1 ELSE 0 END
		,rdtp.WithHoldingTaxAmount
		,rdtp.WithHoldingTaxBalance

	FROM #ReceivableDetailsToProcess rdtp
	JOIN #ReceivableCodeSplitDetails rcd on rdtp.ReceivableDetailId = rcd.ReceivableDetailId
	LEFT JOIN #ContractPreferenceToUse AS ContractPreference ON rdtp.ReceivableID = ContractPreference.ReceivableId
	LEFT JOIN #CustomerPreferenceToUse AS CustomerPreference ON rdtp.ReceivableID = CustomerPreference.ReceivableId

	LEFT JOIN #CapSoftReceivables ReceivableDetails ON ReceivableDetails.ReceivableId = rdtp.ReceivableId AND ReceivableDetails.AssetId = rdtp.CapSoftAssetID
	LEFT JOIN CTE_UpdatedContractOriginationDetails COD ON rdtp.ContractId = COD.ContractId AND COD.OriginationServicings = 1
	LEFT JOIN CTE_UpdateContractSyndicationDetails CSD ON rdtp.ContractId = CSD.ContractId AND CSD.SyndicationServicings = 1


	;WITH CTE_ContractsInUse As  
	(  
	SELECT DISTINCT ContractId FROM #ReceivableDetailTableWithPreference  
	) 
	SELECT 
		C.Id ContractId,
		C.ContractType,
		LeaseFinanceDetails.MaturityDate,
		LeaseFinanceDetails.CommencementDate,
		LeaseFinancedetails.LeaseContractType
	INTO #LFDetails
	FROM CTE_ContractsInUse
	JOIN Contracts C
		ON CTE_ContractsInUse.ContractId = C.Id
	JOIN LeaseFinances 
		ON Leasefinances.ContractId = CTE_ContractsInUse.ContractId  
		AND Leasefinances.IsCurrent = 1  
	JOIN LeaseFinancedetails 
		ON leasefinances.Id = LeaseFinanceDetails.Id  

	;WITH CTE_InvoiceGroupingWRTDueDateRemitTOBillTo
	AS (
		SELECT Rank() OVER (
				ORDER BY RDT.CustomerID
					,RDT.ReceivableDueDate
					,RDT.RemitToId
					,RDT.BillToID
					,RDT.DefInvoiceReceivableGrpOptn
					,RDT.DefInvoiceReceivableGrpOptnSplit
					,RDT.CurrencyId	
					,RDT.AlternateBillingCurrencyId
					,RDT.LegalEntityId ASC	
					,RDT.IsDSL
					,RDT.IsACH
					,RDT.IsPrivateLabel
					,RDT.InvoicePreferenceValue
				) AS InvoiceGroupNumber
			,RDT.*
			,rt.Name 'ReceivableType'
		FROM #ReceivableDetailTableWithPreference AS RDT
		INNER JOIN BillToes AS B ON B.Id = RDT.BillToID
		INNER JOIN dbo.ReceivableTypes rt ON RDT.ReceivableTypeID = rt.Id
		--WHERE RDT.InvoicePreferenceValue != 'SuppressGeneration'
		)
		,CTE_GroupByCategory
	AS (
		/* if blended is no then group invoice by Receivable category and receivable type which are of def option group as Group by subtype */
			SELECT DISTINCT Rank() OVER (
							ORDER BY GrupDueDateRemitToBillTo.InvoiceGroupNumber
							,CASE WHEN GrupDueDateRemitToBillTo.DefInvoiceReceivableGrpOptn = 'Other' 
							THEN 1 ELSE GrupDueDateRemitToBillTo.ReceivableCategoryId END
							) newGrouping

			,GrupDueDateRemitToBillTo.*
			,B.ReceivableSubTypeId
			,B.BlendReceivableSubTypeId
			,B.BillToName
			,B.CustomerBillToName
			,B.InvoiceComment
			,B.BillingContactPersonId
			,B.BillingAddressId
			,B.DeliverInvoiceViaEmail
			,B.DeliverInvoiceViaMail
			,B.SendCCEmailNotificationTo
			,B.SendEmailNotificationTo
			,B.SplitByReceivableAdjustments
			,B.SplitCreditsByOriginalInvoice
			,B.SplitLeaseRentalinvoiceByLocation
			,B.SplitRentalInvoiceByAsset
			,B.SplitRentalInvoiceByContract
			,B.UseLocationAddressForBilling
			,B.GenerateSummaryInvoice
		FROM CTE_InvoiceGroupingWRTDueDateRemitTOBillTo AS GrupDueDateRemitToBillTo
		INNER JOIN #BillDetails AS B ON B.BillToId = GrupDueDateRemitToBillTo.BillToID
			AND B.ReceivableTypeId = GrupDueDateRemitToBillTo.ReceivableTypeID
			AND GrupDueDateRemitToBillTo.ReceivableCategoryId = B.ReceivableSubTypeId
		)
		,CTE_ContractTypeRelationForBlend
	AS (
			 SELECT 
			  CASE   
				WHEN C.ContractType = 'Lease'  
				 THEN CASE   
				   WHEN GroupByCategoryDetails.ReceivableType = 'OverTermRental' OR  ( GroupByCategoryDetails.DueDate > C.MaturityDate)  
				   THEN 'OverTermRental'     
				   WHEN GroupByCategoryDetails.ReceivableType = 'InterimRental'  OR (GroupByCategoryDetails.DueDate < C.CommencementDate)  
				   THEN 'InterimRental'         
				   WHEN C.LeaseContractType = 'Operating' THEN 'OperatingLeaseRental'        
				   ELSE 'CapitalLeaseRental'  
				   END  
				WHEN C.ContractType = 'Loan' THEN 'LoanPrincipal'  
				WHEN C.ContractType = 'LeveragedLease' THEN 'LeveragedLease'  
				END BlendContractTypes  
			   ,
			   GroupByCategoryDetails.*  
			   ,C.ContractType  
			  FROM CTE_GroupByCategory AS GroupByCategoryDetails  
			  LEFT JOIN #LFDetails C ON GroupByCategoryDetails.ContractID = C.ContractId
		)
		,CTE_UpdatedBlendingInfo
	AS (
		SELECT isnull(configTable.BlendWithReceivableTypeId, ContractTypeRelationForBlend.ReceivableTypeId) TypeId
			,ContractTypeRelationForBlend.*
		FROM CTE_ContractTypeRelationForBlend AS ContractTypeRelationForBlend
		LEFT JOIN ReceivableTypeBlendingConfigTables AS configTable ON configTable.EntityType = ContractTypeRelationForBlend.ContractType
			AND configTable.receivableTypeID = ContractTypeRelationForBlend.ReceivableTypeID
			AND configTable.BlendReceivableSubTypeId = ContractTypeRelationForBlend.BlendReceivableSubTypeId
			AND configTable.BlendContractTypes = ContractTypeRelationForBlend.BlendContractTypes
			AND ContractTypeRelationForBlend.BlendReceivableSubTypeId IS NOT NULL
		)
		,CTE_GroupingCategoryWithBlendNumber
	AS (
		SELECT DENSE_RANK() OVER (
				ORDER BY ContractTypeRelationForBlend.newGrouping
					,ContractTypeRelationForBlend.TypeId
					,ContractTypeRelationForBlend.DueDate ASC
				) BlendNumber
			,ContractTypeRelationForBlend.*
		FROM CTE_UpdatedBlendingInfo AS ContractTypeRelationForBlend
		)
		,CTE_SplitByContract
	AS (
		SELECT CASE 
				WHEN ReceivableDetailsSplitByContract.SplitRentalInvoiceByContract = 1
					THEN RANK() OVER (
							ORDER BY ReceivableDetailsSplitByContract.newGrouping
								,ReceivableDetailsSplitByContract.ContractID
							)
				ELSE ReceivableDetailsSplitByContract.newGrouping
				END SplitByContractGrouping
			,ReceivableDetailsSplitByContract.*
		FROM CTE_GroupingCategoryWithBlendNumber AS ReceivableDetailsSplitByContract
		)
		,CTE_SplitByLocation
	AS (
		SELECT CASE 
				WHEN SplitByContract.IsRental = 1
					AND SplitByContract.SplitLeaseRentalinvoiceByLocation = 1
					THEN Rank() OVER (
							ORDER BY SplitByContract.SplitByContractGrouping
								,SplitByContract.LocationID
							)
				ELSE SplitByContract.SplitByContractGrouping
				END SplitByLocationGrouping
			,SplitByContract.*
		FROM CTE_SplitByContract AS SplitByContract
		)
		,CTE_SplitByAssets
	AS (
		SELECT CASE 
				WHEN SplitByLocation.IsRental = 1
					AND SplitByLocation.SplitRentalInvoiceByAsset = 1
					THEN Rank() OVER (
							ORDER BY SplitByLocation.SplitByLocationGrouping
								,SplitByLocation.AssetID
							)
				ELSE SplitByLocation.SplitByLocationGrouping
				END SplitByGrouping
			,SplitByLocation.*
		FROM CTE_SplitByLocation AS SplitByLocation
		)		
		,CTE_SplitByReceivableAdjustments
	AS (
		SELECT CASE
				WHEN SplitByAssets.SplitByReceivableAdjustments = 1
					THEN RANK() OVER (
							ORDER BY SplitByAssets.SplitByGrouping
								,SplitByAssets.IsAdjustmentReceivable
								)
				ELSE SplitByAssets.SplitByGrouping
				END SplitByAdjustmentGrouping
			,SplitByAssets.*
		FROM CTE_SplitByAssets AS SplitByAssets		
		)
		,CTE_SplitCreditsByOriginalInvoice
	AS (
		SELECT CASE
		   	   WHEN SplitByAdjustments.SplitCreditsByOriginalInvoice = 1
					THEN RANK() OVER (
							ORDER BY SplitByAdjustments.SplitByAdjustmentGrouping
								,RI.Id
								)
				ELSE SplitByAdjustments.SplitByAdjustmentGrouping
				END SplitCreditsByOriginalInvoiceGrouping
			,SplitByAdjustments.*
		FROM CTE_SplitByReceivableAdjustments AS SplitByAdjustments
		LEFT JOIN ReceivableDetails RDS ON RDS.Id = SplitByAdjustments.AdjustmentBasisReceivableDetailId AND RDS.IsActive=1
		LEFT JOIN ReceivableInvoiceDetails RIDS ON RIDS.ReceivableDetailId = RDS.Id AND RIDS.IsActive=1
		LEFT JOIN ReceivableInvoices RI ON RI.Id = RIDS.ReceivableInvoiceId AND RI.IsActive=1
		)

	SELECT 
		*
	INTO #SplitCreditsByOriginalInvoice	
	FROM CTE_SplitCreditsByOriginalInvoice
 
	SELECT 
		 SUM(RTI.Balance_Amount) OriginalTaxAmount  
		,SUM(RTI.Balance_Amount) OriginalTaxBalance /*Balance*/  
		,SUM(RTI.EffectiveBalance_Amount) OriginalEffectiveTaxBalance  
		,RTS.ReceivableDetailId  
	INTO #ReceivableTaxImpositionDetail
	FROM #SplitCreditsByOriginalInvoice AS A  
	INNER JOIN ReceivableTaxDetails AS RTS ON RTS.ReceivableDetailId = A.ReceivableDetailId  
	AND RTS.IsActive = 1  
	INNER JOIN ReceivableTaxImpositions AS RTI ON RTI.ReceivableTaxDetailId = RTS.Id  
	GROUP BY RTS.ReceivableDetailId  
		
	INSERT INTO #ReceivableInvoice (
		Number
		,DueDate
		,SplitByContract
		,SplitByLocation
		,SplitByAsset
		,SplitCreditsByOriginalInvoice
		,SplitByReceivableAdj
		,GenerateSummaryInvoice
		,CustomerId
		,BillTo
		,RemitToId
		,LegalEntityId
		,ReceivableCategoryId
		,ReportFormatId
		,CurrencyId
		,ReceivableId
		,ReceivableDetailId
		,OriginalTaxBalance
		,OriginalEffectiveTaxBalance
		,OriginalTaxAmount
		,ReceivableDetailAmount
		,ReceivableDetailBalance
		,ReceivableDetailEffectiveBalance
		,CurrencyISO
		,InvoicePreference
		,BlendNumber
		,EntityType
		,EntityId
		,IsPrivateLabel
		,OriginationSource
		,OriginationSourceId
		,IsDSL
		,IsACH
		,IsRental
		,ReceivableTypeName
		,ExchangeRate
		,AlternateBillingCurrencyId
		,WithHoldingTaxAmount 
		,WithHoldingTaxBalance 
		)
	SELECT (DENSE_RANK() OVER (
				ORDER BY T.SplitCreditsByOriginalInvoiceGrouping
					,T.InvoicePreferenceValue ASC
					,T.IsPrivateLabel
					,T.IsDSL
				)) ReceivableInvoiceNumber
		,T.ReceivableDueDate
		,T.SplitRentalInvoiceByContract
		,T.SplitLeaseRentalinvoiceByLocation
		,T.SplitRentalInvoiceByAsset
		,T.SplitCreditsByOriginalInvoice
		,T.SplitByReceivableAdjustments
		,T.GenerateSummaryInvoice
		,T.CustomerId
		,T.BillToID
		,T.RemitToId
		,T.LegalEntityId
		,T.ReceivableCategoryId
		,BIF.InvoiceFormatId
		,T.CurrencyId
		,T.ReceivableID
		,T.ReceivableDetailId
		,ISNULL(RTD.OriginalTaxBalance, 0) OriginalTaxBalance
		,ISNULL(RTD.OriginalEffectiveTaxBalance, 0) OriginalEffectiveTaxBalance
		,ISNULL(RTD.OriginalTaxAmount, 0) OriginalTaxAmount
		,T.Amount ReceivableDetailAmount
		,T.Balance ReceivableBalance
		,T.EffectiveBalance ReceivableEffectiveBalance
		,T.CurrencyISO
		,CAST(T.InvoicePreferenceValue AS NVARCHAR(80))
		,T.BlendNumber
		,T.EntityType
		,CASE 
			WHEN T.EntityType = 'CT'
				THEN T.ContractId
			WHEN T.EntityType = 'DT'
				THEN T.DiscountingId
			ELSE T.CustomerId
			END
		,T.IsPrivateLabel
		,T.OriginationSource
		,T.OriginationSourceId
		,T.IsDSL
		,T.IsACH
		,T.IsRental
		,T.ReceivableTypeName
		,T.ExchangeRate
		,T.AlternateBillingCurrencyId 
		,T.WithHoldingTaxAmount WithHoldingTaxAmount
		,T.WithHoldingTaxBalance WithHoldingTaxBalance
	FROM #SplitCreditsByOriginalInvoice AS T
	INNER JOIN BillToInvoiceFormats AS BIF ON BIF.BillToId = T.BillToID AND BIF.IsActive = 1
	INNER JOIN ReceivableCategories ON ReceivableCategories.NAME = BIF.ReceivableCategory AND T.ReceivableCategoryId = ReceivableCategories.Id
	LEFT JOIN #ReceivableTaxImpositionDetail AS RTD ON RTD.ReceivableDetailId = T.ReceivableDetailId

	/*Sequence generator*/
	INSERT INTO #InvoiceNumberGenerator 
	SELECT DISTINCT NULL,Number FROM #ReceivableInvoice

	UPDATE #InvoiceNumberGenerator SET SequenceGeneratedInvoiceNumber = CAST(NEXT VALUE FOR InvoiceNumberGenerator AS NVARCHAR(100))

	UPDATE #ReceivableInvoice SET Number = SequenceGeneratedInvoiceNumber
	FROM #ReceivableInvoice
	JOIN #InvoiceNumberGenerator ON #ReceivableInvoice.Number = #InvoiceNumberGenerator.InvoiceRankValue

	/*Insertion of Receivable Invoices*/
	INSERT INTO ReceivableInvoices (
		Number
		,DueDate
		,IsDummy
		,IsNumberSystemCreated
		,InvoiceRunDate
		,IsActive
		,IsInvoiceCleared
		,SplitByContract
		,SplitByLocation
		,SplitByAsset
		,SplitCreditsByOriginalInvoice
		,SplitByReceivableAdj
		,GenerateSummaryInvoice
		,IsEmailSent
		,CustomerId
		,BillToId
		,RemitToId
		,LegalEntityId
		,ReceivableCategoryId
		,ReportFormatId
		,JobStepInstanceId
		,CurrencyId
		,InvoiceAmount_Amount
		,Balance_Amount
		,EffectiveBalance_Amount
		,InvoiceTaxAmount_Amount
		,TaxBalance_Amount
		,EffectiveTaxBalance_Amount
		,InvoiceAmount_Currency
		,Balance_Currency
		,EffectiveBalance_Currency
		,InvoiceTaxAmount_Currency
		,TaxBalance_Currency
		,EffectiveTaxBalance_Currency
		,CreatedById
		,CreatedTime
		,InvoicePreference
		,StatementInvoicePreference
		,RunTimeComment
		,IsPrivateLabel
		,OriginationSource
		,OriginationSourceId
		,IsACH
		,InvoiceFileName
		,AlternateBillingCurrencyId
		,IsPdfGenerated
		,DaysLateCount
		,InvoiceFile_Source
		,InvoiceFile_Type
		,IsStatementInvoice
		,WithHoldingTaxAmount_Amount
		,WithHoldingTaxBalance_Amount
		,WithHoldingTaxAmount_Currency
		,WithHoldingTaxBalance_Currency
		)
	OUTPUT Inserted.Id
		,Inserted.Number
		,Inserted.InvoiceAmount_Currency
		,Inserted.CustomerId
		,Inserted.LegalEntityId
	INTO #InsertedInvoice
	SELECT RecInv.Number
		,RecInv.DueDate
		,0
		,1
		,GetDate()
		,1
		,0
		,RecInv.SplitByContract
		,RecInv.SplitByLocation
		,RecInv.SplitByAsset
		,RecInv.SplitCreditsByOriginalInvoice
		,RecInv.SplitByReceivableAdj
		,RecInv.GenerateSummaryInvoice
		,0
		,RecInv.CustomerId
		,RecInv.BillTo
		,RecInv.RemitToId
		,RecInv.LegalEntityId
		,MIN(RecInv.ReceivableCategoryId) ReceivableCategoryId
		,RecInv.ReportFormatId
		,@JobStepInstanceId
		,RecInv.CurrencyId
		,SUM(RecInv.ReceivableDetailBalance) OriginalBalance
		,SUM(RecInv.ReceivableDetailBalance)
		,SUM(RecInv.ReceivableDetailEffectiveBalance)/*effective balance*/
		,SUM(RecInv.OriginalTaxBalance) OriginalTaxBalance
		,SUM(RecInv.OriginalTaxBalance)
		,SUM(RecInv.OriginalEffectiveTaxBalance)/*effective tax balance*/
		,RecInv.CurrencyISO
		,RecInv.CurrencyISO
		,RecInv.CurrencyISO
		,RecInv.CurrencyISO
		,RecInv.CurrencyISO
		,RecInv.CurrencyISO
		,@CreatedBy
		,@CreatedTime
		,RecInv.InvoicePreference
		,RecInv.InvoicePreference
		,@RunTimeComment
		,RecInv.IsPrivateLabel
		,'_'
		,NULL
		,RecInv.IsACH
		,RecInv.Number
		,RecInv.AlternateBillingCurrencyId
		,0
		,0
		,''
		,''
		,0
		,SUM(RecInv.WithHoldingTaxBalance) WithHoldingTaxAmount
		,SUM(RecInv.WithHoldingTaxBalance) WithHoldingTaxAmount
		,RecInv.CurrencyISO 
		,RecInv.CurrencyISO
	FROM #ReceivableInvoice AS RecInv
	GROUP BY RecInv.Number
		,RecInv.DueDate
		,RecInv.SplitByContract
		,RecInv.SplitByLocation
		,RecInv.SplitByAsset
		,RecInv.SplitCreditsByOriginalInvoice
		,RecInv.SplitByReceivableAdj
		,RecInv.GenerateSummaryInvoice
		,RecInv.CustomerId
		,RecInv.BillTo
		,RecInv.RemitToId
		,RecInv.LegalEntityId
		--,RecInv.ReceivableCategoryId
		,RecInv.ReportFormatId
		,RecInv.CurrencyId
		,RecInv.AlternateBillingCurrencyId
		,RecInv.CurrencyISO
		,RecInv.InvoicePreference
		,RecInv.IsPrivateLabel
		,RecInv.IsDSL
		,RecInv.IsACH
	/*Insertion of Receivable Invoices Details */
	INSERT INTO ReceivableInvoiceDetails (
		Balance_Amount
		,Balance_Currency
		,TaxBalance_Amount
		,TaxBalance_Currency
		,InvoiceAmount_Amount
		,InvoiceAmount_Currency
		,InvoiceTaxAmount_Amount
		,InvoiceTaxAmount_Currency
		,EffectiveBalance_Amount
		,EffectiveBalance_Currency
		,EffectiveTaxBalance_Amount
		,EffectiveTaxBalance_Currency
		,ReceivableDetailId
		,ReceivableInvoiceId
		,CreatedById
		,CreatedTime
		,BlendNumber
		,EntityType
		,EntityId
		,IsActive
		,ExchangeRate
		,ReceivableCategoryId
		)
	SELECT RID.ReceivableDetailBalance
		,InsertedInvoice.CurrencyISO
		,RID.OriginalTaxBalance
		,InsertedInvoice.CurrencyISO
		,RID.ReceivableDetailAmount
		,InsertedInvoice.CurrencyISO
		,RID.OriginalTaxAmount
		,InsertedInvoice.CurrencyISO
		,RID.ReceivableDetailEffectiveBalance
		,InsertedInvoice.CurrencyISO
		,RID.OriginalEffectiveTaxBalance
		,InsertedInvoice.CurrencyISO
		,RID.ReceivableDetailId
		,InsertedInvoice.Id
		,@CreatedBy
		,@CreatedTime
		,RID.BlendNumber
		,RID.EntityType
		,RID.EntityId
		,1
		,RID.ExchangeRate
		,RID.ReceivableCategoryId
	FROM #InsertedInvoice AS InsertedInvoice
	INNER JOIN #ReceivableInvoice AS RID ON InsertedInvoice.InvoiceNumber = RID.Number
	ORDER BY RID.IsRental DESC,RID.ReceivableDetailId,RID.ReceivableTypeName

	IF @IsPastDueCalculationRequired = 'True'
	BEGIN
		/*Past Due Calculation Starts*/
		;WITH CTE_InvoiceEntity AS
		(
		SELECT DISTINCT #ReceivableInvoice.EntityId
		,#ReceivableInvoice.EntityType
		,#ReceivableInvoice.CurrencyISO
		,#ReceivableInvoice.DueDate [InvoiceDueDate]
		,#InsertedInvoice.Id InvoiceId
		FROM #ReceivableInvoice
		INNER JOIN #InsertedInvoice ON #InsertedInvoice.InvoiceNumber = #ReceivableInvoice.Number
		),
		PastDueDetails AS
		(
		SELECT CTE_InvoiceEntity.EntityId
		,CTE_InvoiceEntity.EntityType
		,CTE_InvoiceEntity.CurrencyISO
		,CTE_InvoiceEntity.InvoiceId
		,SUM(ReceivableAllTaxView.Balance) PastDueBalance
		,SUM(ReceivableAllTaxView.TaxBalance) PastDueTaxBalance
		FROM CTE_InvoiceEntity
		INNER JOIN ReceivableAllTaxView ON CTE_InvoiceEntity.EntityId = ReceivableAllTaxView.EntityId
		AND CTE_InvoiceEntity.EntityType = ReceivableAllTaxView.EntityType
		AND ReceivableAllTaxView.DueDate < CTE_InvoiceEntity.InvoiceDueDate
		AND ReceivableAllTaxView.InvoiceId IS NOT NULL
		GROUP BY CTE_InvoiceEntity.EntityId, CTE_InvoiceEntity.EntityType, CTE_InvoiceEntity.CurrencyISO, CTE_InvoiceEntity.InvoiceId
		)
		INSERT INTO ReceivableInvoicePastDueDetails(
			 EntityId
			,EntityType
			,PastDueBalance_Amount
			,PastDueBalance_Currency
			,PastDueTaxBalance_Amount
			,PastDueTaxBalance_Currency
			,CreatedById
			,CreatedTime
			,ReceivableInvoiceId
			)
		SELECT 
			 EntityId
			,EntityType
			,PastDueBalance
			,CurrencyISO
			,PastDueTaxBalance
			,CurrencyISO
			,@CreatedBy
			,@CreatedTime
			,InvoiceId
		FROM PastDueDetails
		WHERE (PastDueBalance != 0 OR PastDueTaxBalance != 0)
		/*Past Due Calculation Ends*/
	END
		
	UPDATE ReceivableDetails
	SET ReceivableDetails.BilledStatus = @InvoicedBilledStatus
	,UpdatedById = @CreatedBy
	,UpdatedTime = @CreatedTime
	FROM ReceivableDetails
	INNER JOIN #ReceivableDetailTableWithPreference AS RDTP ON ReceivableDetails.Id = RDTP.ReceivableDetailID
	INNER JOIN ReceivableInvoiceDetails ON ReceivableInvoiceDetails.ReceivableDetailId = ReceivableDetails.Id
	INNER JOIN #InsertedInvoice AS InsertInvoice ON InsertInvoice.Id = ReceivableInvoiceDetails.ReceivableInvoiceID

	/* Gives details of Invoice Generated  invoiceID and Invoice Number */
	Select
		RID.ReceivableInvoiceId,
		RID.Id ReceivableInvoiceDetailId,
		R.Id ReceivablesId,
		RD.Id ReceivableDetailId,
		RTD.ReceivableTaxId,
		RTD.Id ReceivableTaxDetailId,
		RTI.Id ReceivableTaxImpositionId
	INTO #FunderReceivables
	FROM #InsertedInvoice AS II
	INNER JOIN ReceivableInvoiceDetails RID ON II.Id = RID.ReceivableInvoiceId
	INNER JOIN ReceivableDetails RD ON RID.ReceivableDetailId = RD.Id
	INNER JOIN Receivables R ON RD.ReceivableId = R.Id
	INNER JOIN ReceivableTaxDetails RTD ON RD.Id = RTD.ReceivableDetailId
	INNER JOIN ReceivableTaxImpositions RTI ON RTD.Id = RTI.ReceivableTaxDetailId
	WHERE R.IsServiced = 1
		AND R.IsCollected = 0
		AND R.FunderId IS NOT NULL

	IF EXISTS (Select Top 1 * from #FunderReceivables)
	BEGIN
		UPDATE Receivables
		SET TotalBalance_Amount = 0
			,TotalEffectiveBalance_Amount = 0
			,UpdatedById = @CreatedBy
			,UpdatedTime = @CreatedTime
		FROM Receivables 
		JOIN #FunderReceivables FR ON Receivables.Id = FR.ReceivablesId

		UPDATE ReceivableWithholdingTaxDetails
		SET Balance_Amount = 0
			,EffectiveBalance_Amount = 0
			,UpdatedById = @CreatedBy
			,UpdatedTime = @CreatedTime
		FROM ReceivableWithholdingTaxDetails 
		JOIN #FunderReceivables FR ON ReceivableWithholdingTaxDetails.ReceivableId = FR.ReceivablesId AND ReceivableWithholdingTaxDetails.IsActive=1

		UPDATE RD
		SET Balance_Amount = 0
			,EffectiveBalance_Amount = 0
			,UpdatedById = @CreatedBy
			,UpdatedTime = @CreatedTime
			,LeaseComponentBalance_Amount = 0
			,NonLeaseComponentBalance_Amount = 0
		FROM ReceivableDetails RD
		JOIN #FunderReceivables FR ON RD.Id = FR.ReceivableDetailId

		UPDATE RDWD
		SET Balance_Amount = 0
			,EffectiveBalance_Amount = 0
			,UpdatedById = @CreatedBy
			,UpdatedTime = @CreatedTime
		FROM ReceivableDetailsWithholdingTaxDetails RDWD
		JOIN #FunderReceivables FR ON RDWD.ReceivableDetailId = FR.ReceivableDetailId AND RDWD.IsActive=1

		UPDATE RT
		SET Balance_Amount = 0
			,EffectiveBalance_Amount = 0
			,UpdatedById = @CreatedBy
			,UpdatedTime = @CreatedTime
		FROM ReceivableTaxes RT 
		JOIN #FunderReceivables FR ON RT.Id = FR.ReceivableTaxId

		UPDATE RTD
		SET Balance_Amount = 0
			,EffectiveBalance_Amount = 0
			,UpdatedById = @CreatedBy
			,UpdatedTime = @CreatedTime
		FROM ReceivableTaxDetails RTD 
		JOIN #FunderReceivables FR ON RTD.Id = FR.ReceivableTaxDetailId

		UPDATE RTI
		SET Balance_Amount = 0
			,EffectiveBalance_Amount = 0
			,UpdatedById = @CreatedBy
			,UpdatedTime = @CreatedTime
		FROM ReceivableTaxImpositions RTI 
		JOIN #FunderReceivables FR ON RTI.Id = FR.ReceivableTaxImpositionId

		UPDATE RI
		SET Balance_Amount = 0
			,TaxBalance_Amount = 0
			,EffectiveBalance_Amount = 0
			,EffectiveTaxBalance_Amount = 0
			,WithHoldingTaxBalance_Amount = 0
			,UpdatedById = @CreatedBy
			,UpdatedTime = @CreatedTime
		FROM ReceivableInvoices RI 
		JOIN #FunderReceivables FR ON RI.Id = FR.ReceivableInvoiceId		

		UPDATE RID
		SET Balance_Amount = 0
			,TaxBalance_Amount = 0
			,EffectiveBalance_Amount = 0
			,EffectiveTaxBalance_Amount = 0
			,UpdatedById = @CreatedBy
			,UpdatedTime = @CreatedTime
		FROM ReceivableInvoiceDetails RID 
		JOIN #FunderReceivables FR ON RID.Id = FR.ReceivableInvoiceDetailId
	END
	Select
	RID.ReceivableInvoiceId,
	RID.Id ReceivableInvoiceDetailId,
	RTD.ReceivableTaxId,
	RTD.Id ReceivableTaxDetailId,
	RTI.Id ReceivableTaxImpositionId,
	R.Id ReceivableId,
	RD.Id ReceivableDetailId
	INTO #DiscountingTaxReceivables
	FROM #InsertedInvoice AS II
	INNER JOIN ReceivableInvoiceDetails RID ON II.Id = RID.ReceivableInvoiceId AND RID.IsActive=1
	INNER JOIN ReceivableDetails RD ON RID.ReceivableDetailId = RD.Id AND RD.IsActive=1
	INNER JOIN Receivables R ON RD.ReceivableId = R.Id AND R.IsActive=1
	INNER JOIN ReceivableTaxDetails RTD ON RD.Id = RTD.ReceivableDetailId AND RTD.IsActive=1
	INNER JOIN ReceivableTaxImpositions RTI ON RTD.Id = RTI.ReceivableTaxDetailId AND RTI.IsActive=1
	INNER JOIN TiedContractPaymentDetails TPD on R.PaymentScheduleId=TPD.PaymentScheduleId AND TPD.ContractId=R.EntityId AND TPD.IsActive=1
	LEFT JOIN LeasePaymentSchedules LeasePaymentSchedule on R.PaymentScheduleId=LeasePaymentSchedule.Id
	LEFT JOIN LoanPaymentSchedules LoanPaymentSchedule on R.PaymentScheduleId=LoanPaymentSchedule.Id
	WHERE R.IsServiced = 1
	AND R.IsCollected = 0
	AND R.FunderId IS NULL
	AND (LeasePaymentSchedule.Id IS NOT NULL OR LoanPaymentSchedule.Id IS NOT null)
	

	IF Exists(Select Top(1)* from #DiscountingTaxReceivables)
	BEGIN
		UPDATE RT
		SET Balance_Amount = 0
			,EffectiveBalance_Amount = 0
			,UpdatedById = @CreatedBy
			,UpdatedTime = @CreatedTime
		FROM ReceivableTaxes RT 
		JOIN #DiscountingTaxReceivables DR ON RT.Id = DR.ReceivableTaxId

		UPDATE RTD
		SET Balance_Amount = 0
			,EffectiveBalance_Amount = 0
			,UpdatedById = @CreatedBy
			,UpdatedTime = @CreatedTime
		FROM ReceivableTaxDetails RTD 
		JOIN #DiscountingTaxReceivables DR ON RTD.Id = DR.ReceivableTaxDetailId

		UPDATE RTI
		SET Balance_Amount = 0
			,EffectiveBalance_Amount = 0
			,UpdatedById = @CreatedBy
			,UpdatedTime = @CreatedTime
		FROM ReceivableTaxImpositions RTI 
		JOIN #DiscountingTaxReceivables DR ON RTI.Id = DR.ReceivableTaxImpositionId

		
		UPDATE RI
		SET
			TaxBalance_Amount = 0
			,EffectiveTaxBalance_Amount = 0
			,UpdatedById = @CreatedBy
			,UpdatedTime = @CreatedTime
		FROM ReceivableInvoices RI 
		JOIN #DiscountingTaxReceivables DR ON RI.Id = DR.ReceivableInvoiceId
		

		UPDATE RID
		SET TaxBalance_Amount = 0
			,EffectiveTaxBalance_Amount = 0
			,UpdatedById = @CreatedBy
			,UpdatedTime = @CreatedTime
		FROM ReceivableInvoiceDetails RID 
		JOIN #DiscountingTaxReceivables DR ON RID.Id = DR.ReceivableInvoiceDetailId

		UPDATE ReceivableWithholdingTaxDetails
		SET Balance_Amount = 0
			,EffectiveBalance_Amount = 0
			,UpdatedById = @CreatedBy
			,UpdatedTime = @CreatedTime
		FROM ReceivableWithholdingTaxDetails 
		JOIN #DiscountingTaxReceivables DR ON ReceivableWithholdingTaxDetails.ReceivableId = DR.ReceivableId 
		AND ReceivableWithholdingTaxDetails.IsActive=1

		UPDATE RDWD
		SET Balance_Amount = 0
			,EffectiveBalance_Amount = 0
			,UpdatedById = @CreatedBy
			,UpdatedTime = @CreatedTime
		FROM ReceivableDetailsWithholdingTaxDetails RDWD
		JOIN #DiscountingTaxReceivables DR ON RDWD.ReceivableDetailId = DR.ReceivableDetailId AND RDWD.IsActive=1
	END

	SELECT inv.Id, MAX(rid.BlendNumber) MaxBlendNumber INTO #MaxBlendNumber FROM #InsertedInvoice inv
	JOIN  ReceivableInvoiceDetails rid ON inv.Id =rid.ReceivableInvoiceId
	JOIN ReceivableDetails rd ON rid.ReceivableDetailId = rd.Id
	JOIN Receivables rcv ON rd.ReceivableId = rcv.Id
	JOIN ReceivableCodes rc ON rcv.ReceivableCodeId = rc.Id
	JOIN ReceivableTypes rt ON rc.ReceivableTypeId = rt.Id
	WHERE (rt.Name = 'InsurancePremium')
	GROUP BY inv.Id
	IF EXISTS (Select Top 1 * From #MaxBlendNumber)
	BEGIN
		UPDATE ReceivableInvoiceDetails SET BlendNumber = cte.MaxBlendNumber
		,UpdatedById = @CreatedBy
		,UpdatedTime = @CreatedTime
		FROM #MaxBlendNumber cte 
		JOIN ReceivableInvoiceDetails rid ON cte.Id = rid.ReceivableInvoiceId
		JOIN ReceivableDetails rd ON rid.ReceivableDetailId = rd.Id
		JOIN Receivables rcv ON rd.ReceivableId = rcv.Id
		JOIN ReceivableCodes rc ON rcv.ReceivableCodeId = rc.Id
		JOIN ReceivableTypes rt ON rc.ReceivableTypeId = rt.Id
		WHERE (rt.Name = 'InsurancePremiumAdmin')
	END 

DECLARE @Count INT;
IF EXISTS (SELECT TOP(1)* FROM #CustomerDetails CustomerDetails
			JOIN BillToes ON BillToes.CustomerId = CustomerDetails.CustomerId
			WHERE GenerateStatementInvoice = 1)
BEGIN
	EXEC GenerateStatementInvoices @ProcessThroughDate
	,@ContractID
	,@DiscountingID 
	,@RunTimeComment
	,@IsAllDiscounting 
	,@IsAllLease 
	,@IsAllLoan
	,@IsAllLeveragedLease
	,@InvoiceType
	,@JobStepInstanceId 
	,@CreatedBy 
	,@CreatedTime
	,@IsInvoiceSensitive
	,@InvoicePreference 
	,@CustomerDetails 
	,@ComputedProcessThroughDate
	,@StatementInvoiceCount = @Count OUTPUT
END

	IF EXISTS (SELECT Id,InvoiceNumber,CustomerId,LegalEntityId FROM #InsertedInvoice WHERE Id != 0) OR @Count > 0
	BEGIN
		EXEC ExtractInvoices @JobStepInstanceId, @CreatedBy, @CustomerDetails, @CreatedTime, @BillNegativeandZeroReceivables
	END 
	
	SELECT Id,InvoiceNumber,CustomerId,LegalEntityId FROM #InsertedInvoice WHERE Id != 0 

	DROP TABLE #SplitCreditsByOriginalInvoice
	DROP TABLE #ReceivableTaxImpositionDetail
	DROP TABLE #LFDetails
	DROP TABLE #InsertedInvoice
	DROP TABLE #ReceivableDetailTableWithPreference
	DROP TABLE #FunderReceivables
	DROP TABLE #ContractPreferenceToUse
	DROP TABLE #CustomerPreferenceToUse
	DROP TABLE #BillDetails
	DROP TABLE #ReceivableInvoice
	DROP TABLE #ReceivableDetailsToProcess
	DROP TABLE #BillToesUsed
	DROP TABLE #CustomerDetails
	DROP TABLE #ProcessThroughDate	
	DROP TABLE #ReceivableCodeSplitDetails
	DROP TABLE #InvoiceNumberGenerator
	DROP TABLE #LeadDays
	DROP TABLE #CapSoftReceivables
	DROP TABLE #MaxBlendNumber
	DROP TABLE #ReceivableDetails
	DROP TABLE #ReceivableTypeIds
	DROP TABLE #ReceivableContracts
	DROP TABLE #EffectiveDateForPreference
	DROP TABLE #CustomerEffectiveDateForPreference
	DROP TABLE #ReceivableCustomer

	IF @@TRANCOUNT > 0
		COMMIT TRANSACTION InvoiceGeneration
END TRY  
BEGIN CATCH
ROLLBACK TRANSACTION InvoiceGeneration;
THROW;
END CATCH

GO

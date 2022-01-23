SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[PersistenceForStatementInvoiceGeneration] (
	@JobStepInstanceId BIGINT
	,@CreatedById BIGINT
	,@CreatedTime DATETIMEOFFSET
	,@ChunkNumber BIGINT
	,@SourceJobStepInstanceId BIGINT
	,@ReceivableEntityType_CT NVARCHAR(100)
	,@InvoicePreference_SuppressGeneration NVARCHAR(100)
	,@InvoicePreference_Unknown NVARCHAR(100)
	
	)
AS
BEGIN

	SET NOCOUNT ON;

	CREATE TABLE #InsertedStatementInvoice(
		Id BIGINT PRIMARY KEY,
		InvoiceNumber NVARCHAR(40)
	)

	CREATE TABLE #ChunkBillToes(
		BillToId BIGINT PRIMARY KEY
	)

	INSERT INTO #ChunkBillToes(BillToId)
	SELECT BillToId FROM InvoiceChunkDetails_Extract 
	WHERE JobStepInstanceId=@JobStepInstanceId AND ChunkNumber=@ChunkNumber
	
	CREATE TABLE #CurrentInstanceDueDates(
		GroupNumber BIGINT PRIMARY KEY,
		ComputedDueDate DATE
	)

	INSERT INTO #CurrentInstanceDueDates(GroupNumber, ComputedDueDate)
	SELECT SIRD.GroupNumber
		   ,MAX(SIRD.ComputedSIDueDate) ComputedDueDate
	FROM #ChunkBillToes ICDE
		JOIN StatementInvoiceReceivableDetails_Extract SIRD 
		ON SIRD.BillToId= ICDE.BillToId --Remove SIRD.IsActive Column
	WHERE SIRD.JobStepInstanceId=@JobStepInstanceId AND IsCurrentInstance=1
	GROUP BY GroupNumber
	
	UPDATE StatementInvoiceReceivableDetails_Extract 
		SET ComputedSIDueDate = CIDD.ComputedDueDate
	FROM #ChunkBillToes ICDE
		JOIN StatementInvoiceReceivableDetails_Extract SIRD 
		ON SIRD.BillToId= ICDE.BillToId --Remove SIRD.IsActive Column
	JOIN #CurrentInstanceDueDates CIDD ON SIRD.GroupNumber = CIDD.GroupNumber AND SIRD.JobStepInstanceId=@JobStepInstanceId
	WHERE SIRD.IsCurrentInstance = 0 
	AND (DATEADD(DAY,CASE WHEN SIRD.EntityType = @ReceivableEntityType_CT THEN -(SIRD.CT_InvoiceTransitDays) ELSE -(SIRD.CU_InvoiceTransitDays) END,CIDD.ComputedDueDate) >= SIRD.LastStatementGeneratedDueDate)

	CREATE TABLE #GroupInvoiceInfo(
			GroupNumber INT PRIMARY KEY,
			StatementInvoiceDueDate DATE,
			SequenceGeneratedInvoiceNumber NVARCHAR(40) NULL,
	)

	CREATE NONCLUSTERED INDEX IX_Number ON #GroupInvoiceInfo(SequenceGeneratedInvoiceNumber)

	INSERT INTO #GroupInvoiceInfo(GroupNumber, StatementInvoiceDueDate, SequenceGeneratedInvoiceNumber)
	SELECT SIRD.GroupNumber, MAX(SIRD.ComputedSIDueDate), NULL
	FROM #ChunkBillToes ICDE
	JOIN StatementInvoiceReceivableDetails_Extract SIRD 
	ON SIRD.BillToId= ICDE.BillToId --Remove SIRD.IsActive Column 
	AND SIRD.JobStepInstanceId=@JobStepInstanceId
	GROUP BY SIRD.GroupNumber
	
	CREATE TABLE #ValidSIDate_ActiveIds(
		ExtractId BIGINT PRIMARY KEY 
	)

	INSERT INTO #ValidSIDate_ActiveIds(ExtractId)
	SELECT SIRD.Id  --TODO: Change condition for SIDataPrepLT
	FROM #GroupInvoiceInfo G
	INNER JOIN StatementInvoiceReceivableDetails_Extract SIRD
	INNER JOIN #ChunkBillToes ICDE ON SIRD.BillToId= ICDE.BillToId 
	ON SIRD.GroupNumber = G.GroupNumber AND SIRD.JobStepInstanceId = @JobStepInstanceId --Remove SIRD.IsActive 
	WHERE SIRD.InvoiceDueDate <= G.StatementInvoiceDueDate
	AND (LastStatementGeneratedDueDate IS NULL OR (SIRD.ComputedSIDueDate > LastStatementGeneratedDueDate AND LastStatementGeneratedDueDate <= JobProcessThroughDate))
	AND (
		SIRD.IsCurrentInstance = 1 
			OR (SIRD.JobProcessThroughDate IS NULL OR DATEADD(DAY, CASE WHEN SIRD.EntityType = @ReceivableEntityType_CT THEN -(SIRD.CT_InvoiceTransitDays) ELSE -(SIRD.CU_InvoiceTransitDays) END, SIRD.ComputedSIDueDate) <= SIRD.JobProcessThroughDate)		
		)

	UPDATE #GroupInvoiceInfo SET SequenceGeneratedInvoiceNumber = CAST(NEXT VALUE FOR InvoiceNumberGenerator AS NVARCHAR(100))
	
	CREATE TABLE #ReceivableInvoiceInfo(
		InvoiceId BIGINT PRIMARY KEY,
		GroupNumber BIGINT,
		InvoiceAmount DECIMAL(16,2),
		InvoiceBalance DECIMAL(16,2),
		InvoiceEffectiveBalance DECIMAL(16,2),
		InvoiceTaxAmount DECIMAL(16,2),
		InvoiceTaxBalance DECIMAL(16,2),
		InvoiceTaxEffectiveBalance DECIMAL(16,2),
	)

	INSERT INTO #ReceivableInvoiceInfo(InvoiceId, GroupNumber, InvoiceAmount, InvoiceBalance, InvoiceEffectiveBalance, InvoiceTaxAmount, InvoiceTaxBalance, InvoiceTaxEffectiveBalance)
	SELECT 
		SIRD.ReceivableInvoiceId, SIRD.GroupNumber, MAX(InvoiceAmount), MAX(InvoiceBalance), MAX(InvoiceEffectiveBalance), MAX(InvoiceTaxAmount), MAX(InvoiceTaxBalance), MAX(InvoiceTaxEffectiveBalance)
	FROM #ChunkBillToes ICDE
	INNER JOIN StatementInvoiceReceivableDetails_Extract SIRD 
	INNER JOIN #GroupInvoiceInfo G ON SIRD.GroupNumber = G.GroupNumber 
	INNER JOIN #ValidSIDate_ActiveIds NRSI ON SIRD.Id = NRSI.ExtractId
	ON SIRD.BillToId= ICDE.BillToId --Remove SIRD.IsActive
	WHERE SIRD.JobStepInstanceId = @JobStepInstanceId  
	GROUP BY SIRD.ReceivableInvoiceId, SIRD.GroupNumber

	/*Insertion of Statement Invoices*/
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
			,SplitReceivableDueDate
			,SplitCustomerPurchaseOrderNumber
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
			,LastStatementGeneratedDueDate
			,WithHoldingTaxAmount_Amount
			,WithHoldingTaxBalance_Amount
			,WithHoldingTaxAmount_Currency
			,WithHoldingTaxBalance_Currency
			,ReceivableAmount_Amount
			,ReceivableAmount_Currency
			,TaxAmount_Currency
			,TaxAmount_Amount
			,CustomerNumber
			,CustomerName
			,RemitToName
			,AlternateBillingCurrencyISO
			,LegalEntityNumber
			,CurrencyISO
			,ReceivableTaxType
			)
		OUTPUT Inserted.Id
			,Inserted.Number
		INTO #InsertedStatementInvoice
		SELECT G.SequenceGeneratedInvoiceNumber
			,MAX(SIRD.ComputedSIDueDate)
			,0 AS IsDummy
			,1 AS IsNumberSystemCreated 
			,@CreatedTime AS RunDate 
			,1 AS IsActive
			,0 AS IsInvoiceCleared
			,SIRD.SplitRentalInvoiceByContract
			,SIRD.SplitLeaseRentalInvoiceByLocation
			,SIRD.SplitRentalInvoiceByAsset
			,SIRD.SplitCreditsByOriginalInvoice
			,SIRD.SplitByReceivableAdjustments
			,SIRD.SplitReceivableDueDate
			,SIRD.SplitCustomerPurchaseOrderNumber
			,SIRD.GenerateSummaryInvoice
			,0 AS IsEmailSent
			,SIRD.CustomerId
			,SIRD.BillToId
			,SIRD.RemitToId
			,SIRD.LegalEntityId
			,MIN(SIRD.ReceivableCategoryId) ReceivableCategoryId
			,SIRD.StatementInvoiceFormatId -- SIDataPrepLT
			,@SourceJobStepInstanceId
			,SIRD.CurrencyId
			,0.00 InvoiceAmount
			,0.00 InvoiceBalance
			,0.00 InvoiceEffectiveBalance
			,0.00 InvoiceTaxAmount
			,0.00 InvoiceTaxBalance
			,0.00 InvoiceTaxEffectiveBalance
			,SIRD.InvoiceCurrency
			,SIRD.InvoiceCurrency
			,SIRD.InvoiceCurrency
			,SIRD.InvoiceCurrency
			,SIRD.InvoiceCurrency
			,SIRD.InvoiceCurrency
			,@CreatedById AS CreatedById
			,@CreatedTime AS CreatedTime
			,SIRD.RI_StatementInvoicePreference
			,SIRD.RI_StatementInvoicePreference
			,'StatementInvoice'
			,SIRD.IsPrivateLabel
			,@InvoicePreference_Unknown
			,NULL
			,MAX(CONVERT(INT,SIRD.IsACH)) --Even if one of the associated RI has IsACH as true then the SI will also have it as true 
			,G.SequenceGeneratedInvoiceNumber AS InvoiceFileName
			,SIRD.AlternateBillingCurrencyId
			,0
			,0
			,''
			,'' 
			,1 --IsStatementInvoice
			,NULL --LastStatementGeneratedDueDate
			,ISNULL(SUM(WithHoldingTaxAmount),0.00)
			,ISNULL(SUM(WithHoldingTaxBalance),0.00)
			,SIRD.InvoiceCurrency
			,SIRD.InvoiceCurrency
			,0.00 ReceivableAmount
			,SIRD.InvoiceCurrency
			,SIRD.InvoiceCurrency
			,0.00 TaxAmount
			,SIRD.CustomerNumber
			,SIRD.CustomerName
			,SIRD.RemitToName
			,SIRD.AlternateBillingCurrencyISO
			,SIRD.LegalEntityNumber
			,SIRD.CurrencyISO
			,'SalesTax'
		FROM #ChunkBillToes ICDE
		INNER JOIN StatementInvoiceReceivableDetails_Extract SIRD ON SIRD.BillToId = ICDE.BillToId AND SIRD.JobStepInstanceId=@JobStepInstanceId --Remove SIRD.IsActive=1
		INNER JOIN #GroupInvoiceInfo G ON SIRD.GroupNumber = G.GroupNumber 
		INNER JOIN #ValidSIDate_ActiveIds NRSI ON SIRD.Id = NRSI.ExtractId
		GROUP BY G.SequenceGeneratedInvoiceNumber
			,SIRD.SplitRentalInvoiceByContract
			,SIRD.SplitLeaseRentalInvoiceByLocation
			,SIRD.SplitRentalInvoiceByAsset
			,SIRD.SplitCreditsByOriginalInvoice
			,SIRD.SplitByReceivableAdjustments
			,SIRD.SplitReceivableDueDate
			,SIRD.SplitCustomerPurchaseOrderNumber
			,SIRD.GenerateSummaryInvoice
			,SIRD.CustomerId
			,SIRD.BillToId
			,SIRD.RemitToId
			,SIRD.LegalEntityId
			,SIRD.StatementInvoiceFormatId
			,SIRD.CurrencyId
			,SIRD.AlternateBillingCurrencyId
			,SIRD.InvoiceCurrency
			,SIRD.RI_StatementInvoicePreference
			,SIRD.IsPrivateLabel
			,SIRD.IsDSL
			,SIRD.CustomerNumber
			,SIRD.CustomerName
			,SIRD.RemitToName
			,SIRD.AlternateBillingCurrencyISO
			,SIRD.LegalEntityNumber
			,SIRD.CurrencyISO

	CREATE TABLE #StatementInvoiceAmounts(
		StatementInvoiceId BIGINT PRIMARY KEY,
		InvoiceAmount DECIMAL(16,2),
		InvoiceBalance DECIMAL(16,2),
		InvoiceEffectiveBalance DECIMAL(16,2),
		InvoiceTaxAmount DECIMAL(16,2),
		InvoiceTaxBalance DECIMAL(16,2),
		InvoiceTaxEffectiveBalance DECIMAL(16,2)
	)

	INSERT INTO #StatementInvoiceAmounts(StatementInvoiceId, InvoiceAmount, InvoiceBalance, InvoiceEffectiveBalance, InvoiceTaxAmount, InvoiceTaxBalance, InvoiceTaxEffectiveBalance)
	SELECT I.Id, SUM(RI.InvoiceAmount), SUM(RI.InvoiceBalance), SUM(RI.InvoiceEffectiveBalance), SUM(RI.InvoiceTaxAmount), SUM(RI.InvoiceTaxBalance), SUM(RI.InvoiceTaxEffectiveBalance)
	FROM #InsertedStatementInvoice I
	INNER JOIN #GroupInvoiceInfo G ON I.InvoiceNumber=G.SequenceGeneratedInvoiceNumber
	INNER JOIN #ReceivableInvoiceInfo RI ON G.GroupNumber=RI.GroupNumber
	GROUP BY I.Id
		
	UPDATE SI SET
	InvoiceAmount_Amount = InvoiceAmount, 
	Balance_Amount = InvoiceBalance, 
	EffectiveBalance_Amount = InvoiceEffectiveBalance, 
	InvoiceTaxAmount_Amount = InvoiceTaxAmount,
	TaxBalance_Amount = InvoiceTaxBalance,
	EffectiveTaxBalance_Amount = InvoiceTaxEffectiveBalance,
	ReceivableAmount_Amount = InvoiceAmount,
	TaxAmount_Amount = InvoiceTaxAmount
	FROM ReceivableInvoices SI 
	INNER JOIN #StatementInvoiceAmounts ON SI.Id = #StatementInvoiceAmounts.StatementInvoiceId

	INSERT INTO ReceivableInvoiceStatementAssociations (
			StatementInvoiceID,
			ReceivableInvoiceID,
			IsCurrentInvoice,
			CreatedById,
			CreatedTime
			)
	SELECT 
			II.Id,
			SI.InvoiceId,
			CASE 
				WHEN RISA.StatementInvoiceId IS NULL THEN 1
				ELSE 0
			END,
			@CreatedById,
			@CreatedTime
	FROM #InsertedStatementInvoice II
	INNER JOIN #GroupInvoiceInfo G ON II.InvoiceNumber=G.SequenceGeneratedInvoiceNumber
	INNER JOIN #ReceivableInvoiceInfo SI ON G.GroupNumber=SI.GroupNumber
	LEFT JOIN ReceivableInvoiceStatementAssociations RISA ON SI.InvoiceId=RISA.ReceivableInvoiceId
		AND RISA.IsCurrentInvoice=1
	
	UPDATE RI 
	SET InvoicePreference = @InvoicePreference_SuppressGeneration
		,RI.UpdatedById = @CreatedById
		,RI.UpdatedTime = @CreatedTime
	FROM ReceivableInvoices RI
	INNER JOIN #ReceivableInvoiceInfo RIO ON RI.Id=RIO.InvoiceId

	SELECT RI.Id,MAX(RIS.DueDate) AS MaxSIDueDate
	INTO #StatementInvoiceRIDueDates
	FROM ReceivableInvoices RIS 
	JOIN #InsertedStatementInvoice I ON RIS.Id = I.Id
	JOIN ReceivableInvoiceStatementAssociations RISA ON RISA.StatementInvoiceId = I.Id
	JOIN ReceivableInvoices RI ON RISA.ReceivableInvoiceId = RI.Id
	GROUP BY RI.Id

	UPDATE ReceivableInvoices 
		SET ReceivableInvoices.LastStatementGeneratedDueDate = SI.MaxSIDueDate
		,ReceivableInvoices.UpdatedById = @CreatedById
		,ReceivableInvoices.UpdatedTime = @CreatedTime
		FROM ReceivableInvoices RI
		JOIN #StatementInvoiceRIDueDates SI ON RI.Id = SI.Id
		WHERE RI.DueDate <= SI.MaxSIDueDate
	 
	DROP TABLE #CurrentInstanceDueDates
	DROP TABLE #GroupInvoiceInfo
	DROP TABLE #InsertedStatementInvoice
	DROP TABLE #StatementInvoiceRIDueDates
	DROP TABLE #ValidSIDate_ActiveIds
	DROP TABLE #ChunkBillToes
	DROP TABLE #StatementInvoiceAmounts
	DROP TABLE #ReceivableInvoiceInfo

END

GO

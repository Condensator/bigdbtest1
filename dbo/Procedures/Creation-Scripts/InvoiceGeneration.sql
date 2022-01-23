SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InvoiceGeneration]
(	
    @UserId BIGINT,
	@ModuleIterationStatusId BIGINT, 
	@CreatedTime DATETIMEOFFSET = NULL,
	@ProcessedRecords BIGINT OUT,
	@FailedRecords BIGINT OUT,
	@ToolIdentifier INT
)
AS
BEGIN
--DECLARE @UserId BIGINT;
--DECLARE @FailedRecords BIGINT;
--DECLARE @ProcessedRecords BIGINT;
--DECLARE @CreatedTime DATETIMEOFFSET;
--DECLARE @ModuleIterationStatusId BIGINT;
--SET @UserId = 1;
--SET @CreatedTime = SYSDATETIMEOFFSET();	
--SELECT @ModuleIterationStatusId= MAX(Id) FROM dbo.stgModuleIterationStatus
SET NOCOUNT ON
SET XACT_ABORT ON
IF(@CreatedTime IS NULL)
SET @CreatedTime = SYSDATETIMEOFFSET();
SET @FailedRecords = 0
SET @ProcessedRecords = 0
DECLARE @TakeCount INT = 500
DECLARE @SkipCount INT = 0
DECLARE @MaxInvoiceGenerationId INT = 0
DECLARE @BatchCount INT = 0
DECLARE @Number INT = 0
DECLARE @TotalRecordsCount INT = (SELECT COUNT(Id) FROM stgInvoiceGeneration WHERE IsMigrated = 0 AND (@ToolIdentifier = ToolIdentifier OR @ToolIdentifier IS NULL ))
DECLARE @SQL Nvarchar(max) =''		
DECLARE @IsCloneDone BIT = ISNULL(@ToolIdentifier,0)
DECLARE @Module VARCHAR(50) = NULL
SET @Module = (SELECT StgModule.Name FROM StgModule INNER JOIN StgModuleIterationStatus ON StgModule.Id = StgModuleIterationStatus.ModuleId WHERE StgModuleIterationStatus.Id = @ModuleIterationStatusId)
EXEC ResetStagingTempFields @Module , @ToolIdentifier
CREATE TABLE #ErrorLogs
(
    Id BIGINT NOT NULL IDENTITY PRIMARY KEY,
	StagingRootEntityId BIGINT,
	Result NVARCHAR(10),
	Message NVARCHAR(MAX)
)
CREATE TABLE #FailedProcessingLogs
	(
		MergeAction NVARCHAR(20),
		InsertedId BIGINT,
		ErrorId BIGINT
	)

UPDATE stgInvoiceGeneration SET R_ContractId = Contracts.Id
FROM 
	stgInvoiceGeneration
	INNER JOIN Contracts 
		ON stgInvoiceGeneration.SequenceNumber = Contracts.SequenceNumber
WHERE 
	stgInvoiceGeneration.IsMigrated = 0 AND EntityType = 'CT'
	AND R_ContractId IS NULL AND stgInvoiceGeneration.SequenceNumber IS NOT NULL AND (@ToolIdentifier = ToolIdentifier OR @ToolIdentifier IS NULL )
UPDATE stgInvoiceGeneration SET R_CustomerId = Customers.Id
FROM 
	stgInvoiceGeneration
	INNER JOIN Parties 
		ON stgInvoiceGeneration.CustomerPartyNumber = Parties.PartyNumber
	INNER JOIN Customers 
		ON Parties.Id = Customers.Id
WHERE 
	stgInvoiceGeneration.IsMigrated = 0 AND EntityType = 'CU'
	AND R_CustomerId IS NULL AND stgInvoiceGeneration.CustomerPartyNumber IS NOT NULL AND (@ToolIdentifier = ToolIdentifier OR @ToolIdentifier IS NULL )
INSERT INTO #ErrorLogs
SELECT 
stgInvoiceGeneration.Id
,'Error'
,('Invalid SequenceNumber {'+ISNULL(stgInvoiceGeneration.SequenceNumber,'NULL')+'} for InvoiceGeneration Id { '+ CONVERT(VARCHAR,stgInvoiceGeneration.Id) +' }'  )
FROM stgInvoiceGeneration
WHERE stgInvoiceGeneration.IsMigrated = 0 AND R_ContractId IS NULL AND SequenceNumber IS NOT NULL AND EntityType = 'CT' AND (@ToolIdentifier = ToolIdentifier OR @ToolIdentifier IS NULL )
INSERT INTO #ErrorLogs
SELECT 
stgInvoiceGeneration.Id
,'Error'
,('Invalid Customer Number {'+ISNULL(stgInvoiceGeneration.CustomerPartyNumber,'NULL')+'} for InvoiceGeneration Id { '+ CONVERT(VARCHAR,stgInvoiceGeneration.Id) +' }'  )
FROM stgInvoiceGeneration
WHERE stgInvoiceGeneration.IsMigrated = 0 AND R_CustomerId IS NULL AND stgInvoiceGeneration.CustomerPartyNumber IS NOT NULL AND EntityType = 'CU' AND (@ToolIdentifier = ToolIdentifier OR @ToolIdentifier IS NULL )
SELECT * INTO #ErrorLogDetails FROM #ErrorLogs ORDER BY StagingRootEntityId
WHILE @SkipCount < @TotalRecordsCount
BEGIN
BEGIN TRY  
BEGIN TRANSACTION
	CREATE TABLE #CreatedProcessingLogs
	(
		MergeAction NVARCHAR(20),
		InsertedId BIGINT,
		InvoiceId BIGINT
	)
	CREATE TABLE #CreatedReceivableInvoice
	(
		 [Id] BIGINT NOT NULL
		,[EntityId] BIGINT NOT NULL
		,[EntityType] Nvarchar(2) NOT NULL
		,[DueDate] DateTime NOT NULL
		,[CustomerId] BigInt NOT NULL
		,[RemitToId] BIGINT NOT NULL
		,[CurrencyId] BIGINT NOT NULL
		,[BillToId] BIGINT NOT NULL
		,[ReceivableCategoryId] BIGINT NOT NULL
		,[Number] NVARCHAR(MAX) NOT NULL
	);
	CREATE TABLE #InvoiceNumberByCountry 
	(
		CountryId BIGINT,
		CountryCode NVARCHAR(5),
		TotalCount INT,
		SequenceNumber BIGINT
	)

	SELECT 
		TOP (@TakeCount) * 
		INTO #InvoiceSubset
	FROM 
		stgInvoiceGeneration IG
	WHERE 
		IsMigrated = 0 AND (@ToolIdentifier = ToolIdentifier OR @ToolIdentifier IS NULL ) AND ID > @MaxInvoiceGenerationId
		AND	NOT EXISTS (SELECT * FROM #ErrorLogDetails WHERE StagingRootEntityId = IG.Id)
	SELECT @MaxInvoiceGenerationId = MAX(Id) FROM #invoicesubset;		
	SELECT @Number = ISNULL(MAX(CONVERT(bigint,Number)),0) FROM ReceivableInvoices WHERE ReceivableTaxType != 'VAT'
	SELECT @BatchCount = ISNULL(COUNT(Id),0) FROM #invoicesubset; 
	SET @Number=@Number+1
	IF(@IsCloneDone = 0)
	BEGIN
	SET @SQL = 'ALTER SEQUENCE InvoiceNumberGenerator RESTART WITH ' + CONVERT(NVARCHAR(20),@Number)
	EXEC sp_executesql @sql
	END	

	SELECT Contracts.Id ContractId, Receivables.Id ReceivableId, ReceivableDetails.Id ReceivableDetailId
	INTO #Receivables
	FROM #InvoiceSubset InvoiceSubset  
	INNER JOIN Contracts  
		ON InvoiceSubset.R_ContractId = Contracts.Id AND InvoiceSubset.EntityType = 'CT'  
	INNER JOIN Receivables 
		ON Receivables.EntityID = Contracts.Id  And Receivables.IsActive = 1
		AND Receivables.EntityType = 'CT' AND Receivables.DueDate <= InvoiceSubset.ProcessThroughDate   
	INNER JOIN ReceivableDetails
		ON ReceivableDetails.ReceivableId = Receivables.Id   
		AND ReceivableDetails.IsActive = 1 AND ReceivableDetails.BilledStatus != 'Invoiced'  
		AND ReceivableDetails.IsTaxAssessed = 1  

	SELECT ReceivableTaxDetails.ReceivableDetailId, ReceivableTaxDetails.Amount_Amount
	INTO #ReceivableTaxDetails
	FROM #Receivables
	JOIN ReceivableTaxes   
		ON ReceivableTaxes.ReceivableId = #Receivables.ReceivableId  
		AND ReceivableTaxes.IsActive = 1   
	JOIN ReceivableTaxDetails  
		ON ReceivableTaxes.Id = ReceivableTaxDetails.ReceivableTaxId  
		AND ReceivableTaxDetails.ReceivableDetailId = #Receivables.ReceivableDetailId
		AND ReceivableTaxDetails.IsActive = 1

SELECT 
	  ReceivableDetails.Id ReceivableDetailId
	 ,ReceivableDetails.Amount_Amount  
	 ,ReceivableDetails.Amount_Currency
	 ,ReceivableDetails.Balance_Amount 
	 ,ReceivableDetails.EffectiveBalance_Amount
	 ,Receivables.Id AS ReceivableId
	 ,Receivables.DueDate
	 ,#ReceivableTaxDetails.Amount_Amount TaxAmount_Amount
	 ,Receivables.EntityId
	 ,Receivables.EntityType
 	 ,ReceivableDetails.BillToId
	 ,Receivables.RemitToId
	 ,RemitToes.Name AS RemitToName
	 ,Receivables.LegalEntityId
	 ,Receivables.IsPrivateLabel
	 ,LegalEntities.LegalEntityNumber
	 ,Receivables.CustomerId
	 ,Parties.PartyName AS CustomerName
	 ,Parties.PartyNumber AS CustomerNumber
	 ,Receivables.ExchangeRate
	 ,Receivables.AlternateBillingCurrencyId
	 ,AlternateBillingCurrencyCodes.ISO AS AlternateBillingCurrencyISO
	 ,GlobalParameters.Value AS Value
	 ,ReceivableCategories.Id AS ReceivableCategoryId
	 ,ReceivableCodes.ReceivableTypeId
	 ,BillToInvoiceFormats.InvoiceFormatId AS InvoiceFormatId
	 ,Currencies.Id AS CurrencyId
	 ,CurrencyCodes.ISO AS CurrencyISO
	 ,InvoiceSubset.Id StagingInvoiceId
	 ,InvoiceSubset.SequenceNumber StagingSequenceNumber
	 ,InvoiceSubset.ProcessThroughDate StagingDueDate
	 ,Receivables.DealCountryId
	 ,Receivables.ReceivableTaxType
INTO #ReceivableDetails				
FROM 
	#InvoiceSubset InvoiceSubset
	INNER JOIN #Receivables  
		ON InvoiceSubset.R_ContractId = #Receivables.ContractId AND InvoiceSubset.EntityType = 'CT'  
	INNER JOIN Receivables  
		ON #Receivables.ReceivableId = Receivables.Id
	INNER JOIN Parties 
		ON Receivables.CustomerId = Parties.Id
	INNER JOIN LegalEntities 
		ON Receivables.LegalEntityId = LegalEntities.Id
	INNER JOIN RemitToes
		ON Receivables.RemitToId = RemitToes.Id
	INNER JOIN ReceivableDetails 
		ON ReceivableDetails.Id = #Receivables.ReceivableDetailId  
	INNER JOIN BillToes
		ON ReceivableDetails.BillToId = BillToes.Id
	LEFT JOIN #ReceivableTaxDetails
		ON ReceivableDetails.Id = #ReceivableTaxDetails.ReceivableDetailId  
	INNER JOIN GlobalParameters 
		ON Category='Invoicing' AND GlobalParameters.Name='DefaultInvoicePreference'
	INNER JOIN ReceivableCodes 
		ON Receivables.ReceivableCodeId = ReceivableCodes.Id
	INNER JOIN ReceivableCategories 
		ON ReceivableCodes.ReceivableCategoryId = ReceivableCategories.Id
	INNER JOIN BillToInvoiceFormats 
		ON ReceivableCategory = ReceivableCategories.Name AND BillToInvoiceFormats.BillToId = ReceivableDetails.BillToId
	INNER JOIN CurrencyCodes 
		ON CurrencyCodes.ISO = Receivables.TotalAmount_Currency AND CurrencyCodes.IsActive = 1
	INNER JOIN Currencies 
		ON Currencies.CurrencyCodeId= CurrencyCodes.Id AND CurrencyCodes.IsActive = 1
	LEFT JOIN Currencies AlternateBillingCurrencies
		ON AlternateBillingCurrencies.Id= Receivables.AlternateBillingCurrencyId AND AlternateBillingCurrencies.IsActive = 1
	LEFT JOIN CurrencyCodes AlternateBillingCurrencyCodes
		ON AlternateBillingCurrencyCodes.Id = AlternateBillingCurrencies.CurrencyCodeId AND AlternateBillingCurrencyCodes.IsActive = 1

INSERT INTO #ReceivableDetails
SELECT 
	  ReceivableDetails.Id ReceivableDetailId
	 ,ReceivableDetails.Amount_Amount  
	 ,ReceivableDetails.Amount_Currency
	 ,ReceivableDetails.Balance_Amount 
	 ,ReceivableDetails.EffectiveBalance_Amount
	 ,Receivables.Id AS ReceivableId
	 ,Receivables.DueDate
	 ,ReceivableTaxDetails.Amount_Amount TaxAmount_Amount
	 ,Receivables.EntityId
	 ,Receivables.EntityType
 	 ,ReceivableDetails.BillToId
	 ,Receivables.RemitToId
	 ,RemitToes.Name AS RemitToName
	 ,Receivables.LegalEntityId
	 ,Receivables.IsPrivateLabel
	 ,LegalEntities.LegalEntityNumber
	 ,Receivables.CustomerId
	 ,Parties.PartyName AS CustomerName
	 ,Parties.PartyNumber AS CustomerNumber
	 ,Receivables.ExchangeRate
	 ,Receivables.AlternateBillingCurrencyId
	 ,AlternateBillingCurrencyCodes.ISO AS AlternateBillingCurrencyISO
	 ,GlobalParameters.Value AS Value
	 ,ReceivableCategories.Id AS ReceivableCategoryId
	 ,ReceivableCodes.ReceivableTypeId
	 ,BillToInvoiceFormats.InvoiceFormatId AS InvoiceFormatId
	 ,Currencies.Id AS CurrencyId
	 ,CurrencyCodes.ISO AS CurrencyISO
	 ,InvoiceSubset.Id StagingInvoiceId
	 ,InvoiceSubset.SequenceNumber StagingSequenceNumber
	 ,InvoiceSubset.ProcessThroughDate StagingDueDate 
	 ,Receivables.DealCountryId
	 ,Receivables.ReceivableTaxType
FROM 
	#InvoiceSubset InvoiceSubset
	INNER JOIN Customers
		ON InvoiceSubset.R_CustomerId = Customers.Id AND InvoiceSubset.EntityType = 'CU'
	INNER JOIN Receivables 
		ON Receivables.EntityID = Customers.Id
		AND Receivables.EntityType = 'CU' AND Receivables.DueDate <= InvoiceSubset.ProcessThroughDate
	INNER JOIN Parties 
		ON Receivables.CustomerId = Parties.Id
	INNER JOIN LegalEntities 
		ON Receivables.LegalEntityId = LegalEntities.Id
	INNER JOIN RemitToes
		ON Receivables.RemitToId = RemitToes.Id
	LEFT JOIN ReceivableTaxes 
		ON ReceivableTaxes.ReceivableId = Receivables.Id
		AND Receivables.IsActive = 1 
	INNER JOIN ReceivableDetails 
		ON ReceivableDetails.ReceivableId = Receivables.Id 
		AND ReceivableDetails.IsActive = 1 AND ReceivableDetails.BilledStatus != 'Invoiced'
		AND ReceivableDetails.IsTaxAssessed = 1
	INNER JOIN BillToes
		ON ReceivableDetails.BillToId = BillToes.Id
	LEFT JOIN ReceivableTaxDetails
		ON ReceivableTaxes.Id = ReceivableTaxDetails.ReceivableTaxId
		AND ReceivableTaxDetails.ReceivableDetailId = ReceivableDetails.Id
	INNER JOIN GlobalParameters 
		ON Category='Invoicing' AND GlobalParameters.Name='DefaultInvoicePreference'
	INNER JOIN ReceivableCodes 
		ON Receivables.ReceivableCodeId = ReceivableCodes.Id
	INNER JOIN ReceivableCategories 
		ON ReceivableCodes.ReceivableCategoryId = ReceivableCategories.Id
	INNER JOIN BillToInvoiceFormats 
		ON ReceivableCategory = ReceivableCategories.Name AND BillToInvoiceFormats.BillToId = ReceivableDetails.BillToId
	INNER JOIN CurrencyCodes 
		ON CurrencyCodes.ISO = Receivables.TotalAmount_Currency AND CurrencyCodes.IsActive = 1
	INNER JOIN Currencies 
		ON Currencies.CurrencyCodeId= CurrencyCodes.Id AND CurrencyCodes.IsActive = 1
	LEFT JOIN Currencies AlternateBillingCurrencies
		ON AlternateBillingCurrencies.Id= Receivables.AlternateBillingCurrencyId AND AlternateBillingCurrencies.IsActive = 1
	LEFT JOIN CurrencyCodes AlternateBillingCurrencyCodes
		ON AlternateBillingCurrencyCodes.Id = AlternateBillingCurrencies.CurrencyCodeId AND AlternateBillingCurrencyCodes.IsActive = 1
--select * from #ReceivableDetails
SELECT 
	  SUM(ReceivableDetails.Amount_Amount)  TotalAmount_Amount
	 ,ReceivableDetails.Amount_Currency 
	 ,SUM(ReceivableDetails.Balance_Amount) TotalBalance_Amount
	 ,SUM(ReceivableDetails.EffectiveBalance_Amount) TotalEffectiveBalance_Amount
	 ,ReceivableDetails.DueDate
	 ,SUM(ReceivableDetails.TaxAmount_Amount) TaxAmount_Amount
	 ,ReceivableDetails.EntityId
	 ,ReceivableDetails.EntityType
 	 ,ReceivableDetails.BillToId
	 ,ReceivableDetails.RemitToId
	 ,ReceivableDetails.RemitToName
	 ,ReceivableDetails.LegalEntityId
	 ,ReceivableDetails.IsPrivateLabel
	 ,ReceivableDetails.LegalEntityNumber
	 ,ReceivableDetails.CustomerId
	 ,ReceivableDetails.CustomerName
	 ,ReceivableDetails.CustomerNumber
	 ,ReceivableDetails.AlternateBillingCurrencyId
	 ,ReceivableDetails.AlternateBillingCurrencyISO
	 ,ReceivableDetails.Value
	 ,ReceivableDetails.ReceivableCategoryId
	 ,ReceivableDetails.InvoiceFormatId
	 ,ReceivableDetails.CurrencyId
	 ,ReceivableDetails.CurrencyISO
	 ,ReceivableDetails.StagingInvoiceId
	 ,ReceivableDetails.StagingSequenceNumber
	 ,ReceivableDetails.StagingDueDate 
	 ,ReceivableDetails.DealCountryId
	 ,ReceivableDetails.ReceivableTaxType
	 ,@Number AS Number
	 ,CONVERT(NVARCHAR(MAX), '') AS InvoiceNumber
INTO #ReceivableInvoices				
FROM 
	#ReceivableDetails ReceivableDetails
GROUP BY 
	  ReceivableDetails.Amount_Currency
	 ,ReceivableDetails.DueDate
	 ,ReceivableDetails.EntityId
	 ,ReceivableDetails.EntityType
 	 ,ReceivableDetails.BillToId
	 ,ReceivableDetails.RemitToId
	 ,ReceivableDetails.RemitToName
	 ,ReceivableDetails.LegalEntityId
	 ,ReceivableDetails.IsPrivateLabel
	 ,ReceivableDetails.LegalEntityNumber
	 ,ReceivableDetails.AlternateBillingCurrencyId
	 ,ReceivableDetails.AlternateBillingCurrencyISO
	 ,ReceivableDetails.Value
	 ,ReceivableDetails.ReceivableCategoryId
	 ,ReceivableDetails.InvoiceFormatId
	 ,ReceivableDetails.CurrencyId
	 ,ReceivableDetails.CurrencyISO
	 ,ReceivableDetails.BillToId
	 ,ReceivableDetails.StagingInvoiceId 
	 ,ReceivableDetails.StagingSequenceNumber
	 ,ReceivableDetails.StagingDueDate
	 ,ReceivableDetails.CustomerId
	 ,ReceivableDetails.CustomerName
	 ,ReceivableDetails.CustomerNumber
	 ,ReceivableDetails.DealCountryId
	 ,ReceivableDetails.ReceivableTaxType
	 
    UPDATE #ReceivableInvoices SET Number = @Number,InvoiceNumber = @Number, @Number = NEXT VALUE FOR InvoiceNumberGenerator

	IF((SELECT COUNT(*) FROM #ReceivableInvoices WHERE ReceivableTaxType='VAT')>0)
	BEGIN
	DECLARE InvoiceNumber_Cursor CURSOR FOR 

	SELECT ISNULL(DealCountryId, 0) AS CountryId, COUNT(DISTINCT Number) AS TotalCount 
	FROM #ReceivableInvoices GROUP BY DealCountryId

	OPEN InvoiceNumber_Cursor;
		DECLARE @CountryId BIGINT
		DECLARE @TotalCount INT

		FETCH NEXT FROM InvoiceNumber_Cursor INTO @CountryId, @TotalCount;
		
		WHILE @@FETCH_STATUS = 0  
		BEGIN
			DECLARE @NextVal AS BIGINT
			DECLARE @CountryCode NVARCHAR(5)
			DECLARE @SequenceName NVARCHAR(100) = 'InvoiceNumberGenerator'
			DECLARE @FirstVal AS BIGINT

			SELECT @SequenceName = @SequenceName + '_' + ShortName, @CountryCode = ShortName 
			FROM Countries WHERE Id = @CountryId AND IsVATApplicable = 1
			
			EXECUTE GetNextSqlSequence @SequenceName, @IncrementBy=@TotalCount, @NextValue=@NextVal OUTPUT, @FirstValue=@FirstVal OUTPUT
			
			INSERT INTO #InvoiceNumberByCountry VALUES (@CountryId, @CountryCode, @TotalCount, @NextVal)

			FETCH NEXT FROM InvoiceNumber_Cursor INTO @CountryId, @TotalCount;
		END;

	CLOSE InvoiceNumber_Cursor;
	DEALLOCATE InvoiceNumber_Cursor;
   
	;WITH CTE (Number, SequenceNumber)
	AS 
	(
		SELECT RI.Number, 
			ISNULL(InvNum.CountryCode + '-', '') + CAST(InvNum.SequenceNumber - InvNum.TotalCount 
				+ DENSE_RANK() OVER (PARTITION BY DealCountryId ORDER BY Number) AS NVARCHAR(MAX)) AS SequenceNumber
		FROM #ReceivableInvoices RI 
		INNER JOIN #InvoiceNumberByCountry InvNum ON RI.DealCountryId = InvNum.CountryId
	)
	UPDATE #ReceivableInvoices 
	SET InvoiceNumber = CTE.SequenceNumber
	FROM #ReceivableInvoices RI 
	INNER JOIN CTE ON CTE.Number = RI.Number
	END

	MERGE ReceivableInvoices AS ReceivableInvoice
	USING (SELECT * FROM #ReceivableInvoices
			) AS ReceivablesToMigrate
	ON (0 = 1)
	WHEN NOT MATCHED THEN 
	INSERT
        ([Number]
        ,[DueDate]
        ,[IsDummy]
        ,[IsNumberSystemCreated]
        ,[CancellationDate]
        ,[InvoiceAmount_Amount]
        ,[InvoiceAmount_Currency]
        ,[InvoiceTaxAmount_Amount]
        ,[InvoiceTaxAmount_Currency]
        ,[Balance_Amount]
        ,[Balance_Currency]
        ,[TaxBalance_Amount]
        ,[TaxBalance_Currency]
        ,[EffectiveBalance_Amount]
        ,[EffectiveBalance_Currency]
        ,[EffectiveTaxBalance_Amount]
        ,[EffectiveTaxBalance_Currency]
        ,[InvoiceRunDate]
        ,[IsActive]
        ,[IsInvoiceCleared]
        ,[SplitByContract]
        ,[SplitByLocation]
        ,[SplitByAsset]
        ,[SplitCreditsByOriginalInvoice]
        ,[SplitByReceivableAdj]
        ,[GenerateSummaryInvoice]
        ,[InvoiceFile_Source]
        ,[InvoiceFile_Type]
        ,[InvoiceFile_Content]
        ,[IsEmailSent]
        ,[IsPrivateLabel]
        ,[IsACH]
        ,[InvoiceFileName]
        ,[InvoicePreference]
		,[StatementInvoicePreference]
        ,[RunTimeComment]
        ,[OriginationSource]
        ,[OriginationSourceId]
        ,[CreatedById]
        ,[CreatedTime]
        ,[UpdatedById]
        ,[UpdatedTime]
        ,[CustomerId]
        ,[BillToId]
        ,[RemitToId]
        ,[CancelledById]
        ,[LegalEntityId]
        ,[ReceivableCategoryId]
        ,[ReportFormatId]
        ,[JobStepInstanceId]
        ,[CurrencyId]
        ,[LastReceivedDate]
        ,[IsPdfGenerated]
        ,[DeliveryDate]
        ,[DeliveryMethod]
        ,[DeliveryJobStepInstanceId]
        ,[EmailNotificationId]
        ,[AlternateBillingCurrencyId]
		,[IsStatementInvoice]
		,[WithHoldingTaxAmount_Amount]
		,[WithHoldingTaxAmount_Currency]
		,[WithHoldingTaxBalance_Amount]
		,[WithHoldingTaxBalance_Currency]
		,[CurrencyISO]
		,[ReceivableAmount_Amount]
		,[ReceivableAmount_Currency]
		,[TaxAmount_Amount]
		,[TaxAmount_Currency]
		,[CustomerNumber]
		,[CustomerName]
		,[RemitToName]
		,[AlternateBillingCurrencyISO]
		,[LegalEntityNumber]
		,[SplitReceivableDueDate]
		,[SplitCustomerPurchaseOrderNumber]
		,[DealCountryId]
		,[ReceivableTaxType]
		)
	VALUES
	    (CASE ReceivablesToMigrate.ReceivableTaxType WHEN 'VAT' THEN CONVERT(NVARCHAR(MAX),ReceivablesToMigrate.InvoiceNumber) ELSE CONVERT(NVARCHAR(MAX),ReceivablesToMigrate.Number) END
		,ReceivablesToMigrate.DueDate
		,0
		,1
		,NULL
		,ReceivablesToMigrate.TotalAmount_Amount
		,ReceivablesToMigrate.Amount_Currency
		,ISNULL(ReceivablesToMigrate.TaxAmount_Amount,0.00)
		,ReceivablesToMigrate.Amount_Currency
		,ReceivablesToMigrate.TotalBalance_Amount
		,ReceivablesToMigrate.Amount_Currency
		,ISNULL(ReceivablesToMigrate.TaxAmount_Amount,0.00)
		,ReceivablesToMigrate.Amount_Currency
		,ReceivablesToMigrate.TotalEffectiveBalance_Amount
		,ReceivablesToMigrate.Amount_Currency
		,ISNULL(ReceivablesToMigrate.TaxAmount_Amount,0.00)
		,ReceivablesToMigrate.Amount_Currency
		,CONVERT(DATE,@CreatedTime)
		,1
		,0
		,0
		,0
		,0
		,0
		,0
		,0
		,NULL
		,NULL
		,NULL
		,0
		,0
		,0
		,CONVERT(NVARCHAR(MAX),ReceivablesToMigrate.InvoiceNumber)
		,ReceivablesToMigrate.Value
		,ReceivablesToMigrate.Value
		,NULL
		,'_'
		,0
		,@UserId
		,@CreatedTime
		,NULL
		,NULL
		,ReceivablesToMigrate.CustomerId
		,ReceivablesToMigrate.BillToId
		,ReceivablesToMigrate.RemitToId
		,NULL
		,ReceivablesToMigrate.LegalEntityId
		,ReceivablesToMigrate.ReceivableCategoryId
		,ReceivablesToMigrate.InvoiceFormatId
		,NULL
		,ReceivablesToMigrate.CurrencyId
		,NULL
		,0
		,NULL
		,'_'
		,NULL
		,NULL
		,ReceivablesToMigrate.AlternateBillingCurrencyId
		,0
		,0.00
		,ReceivablesToMigrate.Amount_Currency
		,0.00
		,ReceivablesToMigrate.Amount_Currency
		,ReceivablesToMigrate.CurrencyISO
		,ReceivablesToMigrate.TotalAmount_Amount
		,ReceivablesToMigrate.Amount_Currency
		,ISNULL(ReceivablesToMigrate.TaxAmount_Amount,0.00)
		,ReceivablesToMigrate.Amount_Currency
		,ReceivablesToMigrate.CustomerNumber
		,ReceivablesToMigrate.CustomerName
		,ReceivablesToMigrate.RemitToName
		,ReceivablesToMigrate.AlternateBillingCurrencyISO
		,ReceivablesToMigrate.LegalEntityNumber
		,0
		,0
		,ReceivablesToMigrate.DealCountryId
		,ReceivablesToMigrate.ReceivableTaxType
		)
	OUTPUT Inserted.Id, ReceivablesToMigrate.EntityId, ReceivablesToMigrate.EntityType, ReceivablesToMigrate.DueDate, ReceivablesToMigrate.CustomerId, ReceivablesToMigrate.[RemitToId],
	ReceivablesToMigrate.[CurrencyId],ReceivablesToMigrate.[BillToId],ReceivablesToMigrate.[ReceivableCategoryId],ReceivablesToMigrate.InvoiceNumber  INTO #CreatedReceivableInvoice;
					--select *  from #CreatedReceivableInvoice																																						
INSERT INTO [dbo].[ReceivableInvoiceDetails]																														
	([EntityType]
	,[EntityId]
	,[InvoiceAmount_Amount]
	,[InvoiceAmount_Currency]
	,[InvoiceTaxAmount_Amount]
	,[InvoiceTaxAmount_Currency]
	,[Balance_Amount]
	,[Balance_Currency]
	,[TaxBalance_Amount]
	,[TaxBalance_Currency]
	,[EffectiveBalance_Amount]
	,[EffectiveBalance_Currency]
	,[EffectiveTaxBalance_Amount]
	,[EffectiveTaxBalance_Currency]
	,[BlendNumber]
	,[IsActive]
	,[CreatedById]
	,[CreatedTime]
	,[UpdatedById]
	,[UpdatedTime]
	,[ReceivableDetailId]
	,[ReceivableInvoiceId]
	,[ExchangeRate]
	,[ReceivableCategoryId]
	,[ReceivableAmount_Amount]
	,[ReceivableAmount_Currency]
	,[TaxAmount_Amount]
	,[TaxAmount_Currency]
	,[ReceivableId]
	,[ReceivableTypeId]
	,[SequenceNumber]
	,[PaymentType]
	)
SELECT
	 ReceivableInvoices.EntityType
	,ReceivableInvoices.EntityId
	,ReceivableDetails.Amount_Amount
	,ReceivableDetails.Amount_Currency
	,ISNULL(ReceivableDetails.TaxAmount_Amount,0.00)
	,ReceivableDetails.Amount_Currency
	,ReceivableDetails.Balance_Amount
	,ReceivableDetails.Amount_Currency
	,ISNULL(ReceivableDetails.TaxAmount_Amount,0.00)
	,ReceivableDetails.Amount_Currency
	,ReceivableDetails.Balance_Amount
	,ReceivableDetails.Amount_Currency
	,ISNULL(ReceivableDetails.TaxAmount_Amount,0.00)
	,ReceivableDetails.Amount_Currency
	,1
	,1
	,@UserId
	,@CreatedTime
	,NULL
	,NULL
	,ReceivableDetails.ReceivableDetailId
	,CreatedReceivableInvoice.Id
	,ReceivableDetails.ExchangeRate
	,ReceivableDetails.ReceivableCategoryId 
	,ReceivableDetails.Amount_Amount
	,ReceivableDetails.Amount_Currency
	,ISNULL(ReceivableDetails.TaxAmount_Amount,0.00)
	,ReceivableDetails.Amount_Currency
	,ReceivableDetails.ReceivableId
	,ReceivableDetails.ReceivableTypeId
	,ReceivableDetails.StagingSequenceNumber
	,NULL AS PaymentType
FROM  
	#ReceivableInvoices ReceivableInvoices
	INNER JOIN #ReceivableDetails ReceivableDetails
		ON ReceivableDetails.EntityId = ReceivableInvoices.EntityId
		AND ReceivableDetails.EntityType = ReceivableInvoices.EntityType
		AND ReceivableDetails.DueDate = ReceivableInvoices.DueDate
		AND ReceivableDetails.BillToId = ReceivableInvoices.BillToId
		AND ReceivableDetails.RemitToId = ReceivableInvoices.RemitToId
		AND ReceivableDetails.CurrencyId = ReceivableInvoices.CurrencyId
		AND ReceivableDetails.ReceivableCategoryId = ReceivableInvoices.ReceivableCategoryId
		AND ReceivableDetails.IsPrivateLabel=ReceivableInvoices.IsPrivateLabel
		AND ReceivableDetails.ReceivableTaxType=ReceivableInvoices.ReceivableTaxType
	INNER JOIN #CreatedReceivableInvoice CreatedReceivableInvoice 
		ON CreatedReceivableInvoice.Number = ReceivableInvoices.InvoiceNumber
	
	CREATE TABLE #ReceivablePaymentType
	(
	ReceivableId BIGINT,
	PaymentType NVARCHAR(40)
	)
	INSERT INTO #ReceivablePaymentType
	SELECT RID.ReceivableId,LSPS.PaymentType
	FROM #CreatedReceivableInvoice IRI
	JOIN ReceivableInvoices RI ON IRI.Number = RI.Number
	JOIN ReceivableInvoiceDetails RID ON RI.Id = RID.ReceivableInvoiceId
	JOIN Receivables R ON R.Id=RID.ReceivableId
	JOIN Contracts C ON C.Id = R.EntityId AND R.EntityType = 'CT' 
	JOIN LeasePaymentSchedules LSPS
		ON R.PaymentScheduleId = LSPS.Id AND C.ContractType ='Lease'
	INSERT INTO #ReceivablePaymentType
	SELECT RID.ReceivableId,LNPS.PaymentType
	FROM #CreatedReceivableInvoice IRI
	JOIN ReceivableInvoices RI ON IRI.Number = RI.Number
	JOIN ReceivableInvoiceDetails RID ON RI.Id = RID.ReceivableInvoiceId
	JOIN Receivables R ON R.Id=RID.ReceivableId
	JOIN Contracts C ON C.Id = R.EntityId AND R.EntityType = 'CT' 
	JOIN LoanPaymentSchedules LNPS
		ON R.PaymentScheduleId = LNPS.Id AND C.ContractType ='Loan'
	UPDATE ReceivableInvoiceDetails
	SET PaymentType = #ReceivablePaymentType.PaymentType
	FROM ReceivableInvoiceDetails
	JOIN #ReceivablePaymentType ON #ReceivablePaymentType.ReceivableId=ReceivableInvoiceDetails.ReceivableId
	

	UPDATE ReceivableDetails SET BilledStatus = 'Invoiced',UpdatedById = @UserId, UpdatedTime = SYSDATETIMEOFFSET() 
	FROM  #ReceivableDetails  
    INNER JOIN ReceivableDetails ON #ReceivableDetails.ReceivableDetailId = ReceivableDetails.Id 
	UPDATE stgInvoiceGeneration SET IsMigrated = 1 WHERE Id IN (SELECT StagingInvoiceId FROM #ReceivableInvoices)
	MERGE stgProcessingLog AS ProcessingLog
	USING (SELECT
			Id
			FROM
			#invoicesubset 
			) AS Processed
	ON (ProcessingLog.StagingRootEntityId = Processed.Id AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
	WHEN MATCHED THEN
	UPDATE SET UpdatedTime = @CreatedTime
	WHEN NOT MATCHED THEN
	INSERT
		(
			StagingRootEntityId
			,CreatedById
			,CreatedTime
			,ModuleIterationStatusId
		)
	VALUES
		(
			Processed.Id
			,@UserId
			,@CreatedTime
			,@ModuleIterationStatusId
		)
	OUTPUT $action, Inserted.Id, Processed.Id INTO #CreatedProcessingLogs;
	INSERT INTO stgProcessingLogDetail
		(Message
		,Type
		,CreatedById
		,CreatedTime	
		,ProcessingLogId)
	SELECT
		'Invoice(s) generated till ' + Convert(nvarchar(50),ISNULL(DueDate,@CreatedTime)) + ', Total '+ Convert(nvarchar(50),ISNULL(TotalReceivablesProcessed,0)) +' Receivable(s) processed' + ' for Entity: ' + Entity + ' Entity Type: ' + EntityType 
		,'Information'
		,@UserId
		,@CreatedTime
		,InsertedId
	FROM
	#CreatedProcessingLogs CreatedProcessingLogs
	INNER JOIN 
	(
		SELECT StagingInvoiceId AS InvoiceId, COUNT(*) TotalReceivablesProcessed, StagingDueDate AS DueDate
			   ,ISNULL(stgInvoiceGeneration.SequenceNumber,stgInvoiceGeneration.CustomerPartyNumber) AS Entity
			   ,stgInvoiceGeneration.EntityType
        FROM #ReceivableInvoices ReceivableInvoices
		INNER JOIN stgInvoiceGeneration ON  ReceivableInvoices.StagingInvoiceId = stgInvoiceGeneration.Id
		WHERE IsMigrated = 1
		GROUP BY StagingInvoiceId, StagingDueDate, stgInvoiceGeneration.SequenceNumber,stgInvoiceGeneration.CustomerPartyNumber,stgInvoiceGeneration.EntityType
	)AS ReceivablesProcessed
	ON CreatedProcessingLogs.InvoiceId = ReceivablesProcessed.InvoiceId
	DELETE FROM #CreatedProcessingLogs;
	MERGE stgProcessingLog AS ProcessingLog
	USING (SELECT Id FROM stgInvoiceGeneration WHERE IsMigrated = 0 AND Id IN (select Id from #InvoiceSubset)) AS Processed
	ON (ProcessingLog.StagingRootEntityId = Processed.Id AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
	WHEN MATCHED THEN
	UPDATE SET UpdatedTime = @CreatedTime
	WHEN NOT MATCHED THEN
	INSERT
		(StagingRootEntityId
		,CreatedById
		,CreatedTime
		,ModuleIterationStatusId)
	VALUES
		(Processed.Id
		,@UserId
		,@CreatedTime
		,@ModuleIterationStatusId)
	OUTPUT $action, Inserted.Id, Processed.Id INTO #CreatedProcessingLogs;
	INSERT INTO stgProcessingLogDetail
		(Message
		,Type
		,CreatedById
		,CreatedTime	
		,ProcessingLogId)
	SELECT
		'No receivable(s) found as of ' + Convert(nvarchar(50),ISNULL(ProcessThroughDate,@CreatedTime)) + ' for Entity: ' + ISNULL(SequenceNumber,CustomerPartyNumber) + ' Entity Type: ' +  EntityType
		,'Warning'
		,@UserId
		,@CreatedTime
		,InsertedId
	FROM
	#CreatedProcessingLogs CreatedProcessingLogs
	INNER JOIN stgInvoiceGeneration InvoiceGeneration ON CreatedProcessingLogs.InvoiceId = InvoiceGeneration.Id
	WHERE
	InvoiceGeneration.IsMigrated = 0 AND (@ToolIdentifier = ToolIdentifier OR @ToolIdentifier IS NULL )
	UPDATE stgInvoiceGeneration SET IsMigrated = 1
	WHERE  IsMigrated = 0 AND Id IN (select Id from #InvoiceSubset)
	DROP TABLE #CreatedProcessingLogs
	DROP TABLE #invoicesubset
	DROP TABLE #CreatedReceivableInvoice
	DROP TABLE #ReceivableInvoices
	DROP TABLE IF EXISTS #ReceivableDetails
    DROP TABLE IF EXISTS #Receivables
	DROP TABLE IF EXISTS #ReceivableTaxDetails
	DROP TABLE IF EXISTS #ReceivablePaymentType
	DROP TABLE #InvoiceNumberByCountry
	SET @SkipCount = @SkipCount + @TakeCount;
COMMIT TRANSACTION
END TRY
BEGIN CATCH
	SET @SkipCount = @SkipCount  + @TakeCount;
	DECLARE @ErrorMessage Nvarchar(max);
	DECLARE @ErrorLine Nvarchar(max);
	DECLARE @ErrorSeverity INT;
	DECLARE @ErrorState INT;
	DECLARE @ErrorLogs ErrorMessageList;
	DECLARE @ModuleName Nvarchar(max) = 'InvoiceGeneration'
	Insert into @ErrorLogs(StagingRootEntityId, ModuleIterationStatusId, Message,Type) VALUES (0,@ModuleIterationStatusId,ERROR_MESSAGE(),'Error')
	SELECT  @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE(),@ErrorLine=ERROR_LINE(),@ErrorMessage=ERROR_MESSAGE()
	IF (XACT_STATE()) = -1  
	BEGIN  
		ROLLBACK TRANSACTION;
		EXEC [dbo].[ExceptionLog] @ErrorLogs,@ErrorLine,@UserId,@CreatedTime,@ModuleName
		SET @FailedRecords = @FailedRecords+@BatchCount;
	END;  
	ELSE IF (XACT_STATE()) = 1  
	BEGIN
		COMMIT TRANSACTION;
		RAISERROR (@ErrorMessage,@ErrorSeverity, @ErrorState);     
	END;
	ELSE
	BEGIN
		EXEC [dbo].[ExceptionLog] @ErrorLogs,@ErrorLine,@UserId,@CreatedTime,@ModuleName
        SET @FailedRecords = @FailedRecords+@BatchCount;
	END;
END CATCH
	END
	MERGE stgProcessingLog AS ProcessingLog
	USING (SELECT DISTINCT StagingRootEntityId
		   FROM #ErrorLogs 
			) AS ErrorComments
	ON (ProcessingLog.StagingRootEntityId = ErrorComments.StagingRootEntityId AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
	WHEN MATCHED THEN
		UPDATE SET UpdatedTime = @CreatedTime
	WHEN NOT MATCHED THEN
	INSERT
		(
			StagingRootEntityId
			,CreatedById
			,CreatedTime
			,ModuleIterationStatusId
		)
	VALUES
		(
			ErrorComments.StagingRootEntityId
			,@UserId
			,@CreatedTime
			,@ModuleIterationStatusId
		)
	OUTPUT $action, Inserted.Id,ErrorComments.StagingRootEntityId INTO #FailedProcessingLogs;	
	DECLARE @TotalRecordsFailed INT = (SELECT  COUNT( DISTINCT InsertedId) FROM #FailedProcessingLogs)
	INSERT INTO 
		stgProcessingLogDetail
		(
			Message
			,Type
			,CreatedById
			,CreatedTime	
			,ProcessingLogId
		)
	SELECT
		#ErrorLogs.Message
		,#ErrorLogs.Result
		,@UserId
		,@CreatedTime
		,#FailedProcessingLogs.InsertedId
	FROM
		#ErrorLogs
	INNER JOIN #FailedProcessingLogs
			ON #ErrorLogs.StagingRootEntityId = #FailedProcessingLogs.ErrorId
	SET @FailedRecords = @FailedRecords+(SELECT COUNT(DISTINCT StagingRootEntityId) FROM #ErrorLogDetails)
	SET @ProcessedRecords =  @ProcessedRecords + @TotalRecordsCount
	DROP TABLE #ErrorLogs
	DROP TABLE #ErrorLogDetails
	DROP TABLE #FailedProcessingLogs
	SET NOCOUNT OFF
	SET XACT_ABORT OFF;
END

GO

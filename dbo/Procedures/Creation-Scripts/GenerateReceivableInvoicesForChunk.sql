SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[GenerateReceivableInvoicesForChunk]  
(  
 @JobStepInstanceId    BIGINT,  
 @SourceJobStepInstanceId  BIGINT,  
 @ChunkNumber     BIGINT,  
 @CreatedById     BIGINT,  
 @CreatedTime     DATETIMEOFFSET,  
 @RunTimeComment     NVARCHAR(200) = NULL  ,
 @BilledStatus_Invoiced NVARCHAR(100)
)  
AS   
BEGIN  
 SET NOCOUNT ON;  
   
	CREATE TABLE #InsertedInvoice   
	(  
		Id BIGINT NOT NULL  
		,InvoiceNumber NVARCHAR(100)  
		,CurrencyISO NVARCHAR(80)  
	)  

	CREATE TABLE #ReceivableInvoice(  
		ReceivableInvoiceNumber BIGINT,  
		SequenceGeneratedNumber NVARCHAR(100),  
		InvoiceDueDate DATE,  
		CustomerId BIGINT,  
		BillToID BIGINT,  
		RemitToId BIGINT,  
		LegalEntityId BIGINT,  
		ReceivableCategoryId BIGINT,  
		CurrencyId BIGINT,  
		ReceivableID BIGINT,  
		ReceivableDetailId BIGINT PRIMARY KEY,  
		OriginalTaxBalance DECIMAL(16,2),  
		OriginalEffectiveTaxBalance DECIMAL(16,2),  
		OriginalTaxAmount DECIMAL(16,2),  
		ReceivableDetailAmount  DECIMAL(16,2),  
		ReceivableDetailBalance  DECIMAL(16,2),  
		ReceivableDetailEffectiveBalance  DECIMAL(16,2),  
		CurrencyISO NVARCHAR(3),  
		BlendNumber INT,  
		EntityType NVARCHAR(20),  
		EntityId BIGINT,  
		IsPrivateLabel BIT,  
		OriginationSource NVARCHAR(20),  
		OriginationSourceId BIGINT,  
		IsDSL BIT,  
		IsACH BIT,  
		IsReceivableTypeRental BIT,  
		ReceivableTypeName NVARCHAR(21),  
		ExchangeRate DECIMAL(20,10),  
		AlternateBillingCurrencyId BIGINT,  
		WithHoldingTaxBalance DECIMAL(16,2),  
		SplitByReceivableAdjustments BIT,  
		SplitCreditsByOriginalInvoice BIT,  
		SplitLeaseRentalInvoiceByLocation BIT,  
		SplitRentalInvoiceByAsset BIT,  
		SplitRentalInvoiceByContract BIT, 
		SplitReceivableDueDate BIT,
		SplitCustomerPurchaseOrderNumber BIT, 
		GenerateSummaryInvoice BIT,  
		InvoicePreference NVARCHAR(20),  
		InvoiceComment NVARCHAR(500),  
		InvoiceFormatId BIGINT,  
		IsFunderOwnedReceivable BIT,  
		IsDiscountingProceeds BIT,  
		ReceivableAmount DECIMAL(16,2),  
		TaxAmount DECIMAL(16,2),  
		LegalEntityNumber NVARCHAR(20),  
		CustomerNumber NVARCHAR(40),  
		CustomerName NVARCHAR(250),  
		SequenceNumber NVARCHAR(40),  
		RemitToName NVARCHAR(40),  
		AlternateBillingCurrencyISO NVARCHAR(3),  
		ReceivableTypeId BIGINT,  
		ReceivableTaxType NVARCHAR(8),
		DealCountryId BIGINT, 
		InvoiceNumberCountryId BIGINT ,
		OriginalInvoiceNumber NVARCHAR(40),
		PaymentType NVARCHAR(40)
	)  
  
	CREATE NONCLUSTERED INDEX IX_Number ON #ReceivableInvoice([ReceivableInvoiceNumber])  
	CREATE NONCLUSTERED INDEX IX_SequenceNumber ON #ReceivableInvoice([SequenceGeneratedNumber])  

	INSERT INTO #ReceivableInvoice(  
		ReceivableInvoiceNumber,   
		SequenceGeneratedNumber,   
		InvoiceDueDate,   
		CustomerId,   
		BillToID,   
		RemitToId,   
		LegalEntityId,   
		ReceivableCategoryId,   
		CurrencyId,   
		ReceivableID,   
		ReceivableDetailId,   
		OriginalTaxBalance,   
		OriginalEffectiveTaxBalance,   
		OriginalTaxAmount,   
		ReceivableDetailAmount ,   
		ReceivableDetailBalance ,   
		ReceivableDetailEffectiveBalance ,   
		CurrencyISO,   
		BlendNumber,   
		EntityType,   
		EntityId,   
		IsPrivateLabel,   
		OriginationSource,  
		OriginationSourceId,  
		IsDSL,   
		IsACH,   
		IsReceivableTypeRental,   
		ReceivableTypeName,  
		ExchangeRate,  
		AlternateBillingCurrencyId,  
		WithHoldingTaxBalance,  
		SplitByReceivableAdjustments,  
		SplitCreditsByOriginalInvoice,  
		SplitLeaseRentalInvoiceByLocation,  
		SplitRentalInvoiceByAsset,  
		SplitRentalInvoiceByContract,  
		SplitReceivableDueDate,
		SplitCustomerPurchaseOrderNumber, 
		GenerateSummaryInvoice,  
		InvoicePreference,  
		InvoiceComment,  
		InvoiceFormatId,  
		IsFunderOwnedReceivable,  
		IsDiscountingProceeds,  
		ReceivableAmount,  
		TaxAmount,  
		LegalEntityNumber,  
		CustomerNumber,  
		CustomerName,  
		SequenceNumber,  
		RemitToName,  
		AlternateBillingCurrencyISO,  
		ReceivableTypeId,
		ReceivableTaxType,
		DealCountryId,
		InvoiceNumberCountryId,
		OriginalInvoiceNumber,
		PaymentType
	)  
	SELECT (DENSE_RANK() OVER (  
	ORDER BY T.GroupNumber, T.SplitNumber  
	)) ReceivableInvoiceNumber  
	,CAST(NULL AS NVARCHAR(100)) SequenceGeneratedNumber  
	,T.InvoiceDueDate  
	,T.CustomerId  
	,T.BillToID  
	,T.RemitToId  
	,T.LegalEntityId  
	,T.ReceivableCategoryId  
	,T.CurrencyId  
	,T.ReceivableID  
	,T.ReceivableDetailId  
	,T.OriginalTaxBalance  
	,T.OriginalEffectiveTaxBalance  
	,T.OriginalTaxBalance OriginalTaxAmount  
	,T.ReceivableDetailAmount  
	,T.ReceivableDetailBalance  
	,T.ReceivableDetailEffectiveBalance  
	,T.CurrencyISO  
	,T.BlendNumber  
	,T.EntityType  
	,CASE   
	WHEN T.EntityType = 'CT'  
	THEN T.ContractId  
	WHEN T.EntityType = 'DT'  
	THEN T.DiscountingId  
	ELSE T.CustomerId  
	END EntityId  
	,T.IsPrivateLabel  
	,ISNULL(IOS.OriginationSource, 'Direct') AS OriginationSource  
	,ISNULL(IOS.OriginationSourceId, T.LegalEntityId) AS OriginationSourceId  
	,T.IsDSL  
	,T.IsACH  
	,T.IsReceivableTypeRental  
	,T.ReceivableTypeName  
	,T.ExchangeRate  
	,T.AlternateBillingCurrencyId   
	,T.WithHoldingTaxBalance WithHoldingTaxBalance  
	,T.SplitByReceivableAdjustments  
	,T.SplitCreditsByOriginalInvoice  
	,T.SplitLeaseRentalInvoiceByLocation  
	,T.SplitRentalInvoiceByAsset  
	,T.SplitRentalInvoiceByContract  
	,T.SplitReceivableDueDate
	,T.SplitCustomerPurchaseOrderNumber
	,T.GenerateSummaryInvoice  
	,T.InvoicePreference  
	,T.InvoiceComment  
	,T.InvoiceFormatId  
	,T.IsFunderOwnedReceivable  
	,T.IsDiscountingProceeds  
	,T.ReceivableAmount  
	,T.TaxAmount  
	,T.LegalEntityNumber  
	,T.CustomerNumber  
	,T.CustomerName  
	,T.SequenceNumber  
	,T.RemitToName  
	,T.AlternateBillingCurrencyISO  
	,T.ReceivableTypeId  
	,T.ReceivableTaxType
	,T.DealCountryId
	,ISNULL(CASE WHEN (T.TaxAmount <> 0) THEN T.DealCountryId ELSE 0 END, 0) AS InvoiceNumberCountryId
	,T.OriginalInvoiceNumber
	,T.PaymentType
	FROM InvoiceReceivableDetails_Extract T  
	INNER JOIN InvoiceChunkDetails_Extract ICD ON T.BillToId=ICD.BillToId AND ICD.JobStepInstanceId=@JobStepInstanceId  
	LEFT JOIN InvoiceOriginationSource_Extract IOS ON IOS.JobStepInstanceId = @JobStepInstanceId  
	AND T.ContractId = IOS.ContractId  
	WHERE T.JobStepInstanceId = @JobStepInstanceId 
	AND T.IsActive=1 
	AND ICD.ChunkNumber=@ChunkNumber  

	CREATE TABLE #InvoiceNumberByCountry 
	(
		CountryId BIGINT,
		CountryCode NVARCHAR(5),
		TotalCount INT,
		SequenceNumber BIGINT
	)

	DECLARE InvoiceNumber_Cursor CURSOR FOR 

	SELECT ISNULL(InvoiceNumberCountryId, 0) AS CountryId, COUNT(DISTINCT ReceivableInvoiceNumber) AS TotalCount 
	FROM #ReceivableInvoice GROUP BY InvoiceNumberCountryId

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

	;WITH CTE (ReceivableInvoiceNumber, SequenceNumber)
	AS 
	(
		SELECT RI.ReceivableInvoiceNumber, 
			ISNULL(InvNum.CountryCode + '-', '') + CAST(InvNum.SequenceNumber - InvNum.TotalCount 
				+ DENSE_RANK() OVER (PARTITION BY InvoiceNumberCountryId ORDER BY ReceivableInvoiceNumber) AS nvarchar(30)) AS SequenceNumber
		FROM #ReceivableInvoice RI 
		INNER JOIN #InvoiceNumberByCountry InvNum ON RI.InvoiceNumberCountryId = InvNum.CountryId
	)
	UPDATE #ReceivableInvoice 
	SET SequenceGeneratedNumber = CTE.SequenceNumber
	FROM #ReceivableInvoice RI 
	INNER JOIN CTE ON CTE.ReceivableInvoiceNumber = RI.ReceivableInvoiceNumber

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
	,WithHoldingTaxAmount_Amount  
	,WithHoldingTaxBalance_Amount  
	,WithHoldingTaxAmount_Currency  
	,WithHoldingTaxBalance_Currency  
	,ReceivableAmount_Amount  
	,ReceivableAmount_Currency  
	,TaxAmount_Amount  
	,TaxAmount_Currency  
	,LegalEntityNumber  
	,CustomerNumber  
	,CustomerName   
	,RemitToName  
	,CurrencyISO  
	,AlternateBillingCurrencyISO  
	,ReceivableTaxType
	,DealCountryId
	,OriginalInvoiceNumber
	)  
	OUTPUT Inserted.Id  
	,Inserted.Number  
	,Inserted.InvoiceAmount_Currency  
	INTO #InsertedInvoice  
	SELECT RecInv.SequenceGeneratedNumber  
	,ISNULL(RecInv.InvoiceDueDate, GETDATE())  
	,0  
	,1  
	,GetDate()  
	,1  
	,0  
	,RecInv.SplitRentalInvoiceByContract  
	,RecInv.SplitLeaseRentalInvoiceByLocation  
	,RecInv.SplitRentalInvoiceByAsset  
	,RecInv.SplitCreditsByOriginalInvoice  
	,RecInv.SplitByReceivableAdjustments 
	,RecInv.SplitReceivableDueDate
	,RecInv.SplitCustomerPurchaseOrderNumber 
	,RecInv.GenerateSummaryInvoice  
	,0  
	,RecInv.CustomerId  
	,RecInv.BillToId  
	,RecInv.RemitToId  
	,RecInv.LegalEntityId  
	,MIN(RecInv.ReceivableCategoryId) ReceivableCategoryId  
	,RecInv.InvoiceFormatId AS ReportFormatId  
	,@SourceJobStepInstanceId --Stamp the SourceJobStepInstanceId For Checkpoint continuation (For Initial Run, SourceJobStepInstanceId=JobStepInstanceId)  
	,RecInv.CurrencyId  
	,SUM(RecInv.ReceivableDetailBalance) OriginalBalance  
	,SUM(CASE WHEN RecInv.IsFunderOwnedReceivable = 1 THEN 0.00 ELSE RecInv.ReceivableDetailBalance END)  
	,SUM(CASE WHEN RecInv.IsFunderOwnedReceivable = 1 THEN 0.00 ELSE RecInv.ReceivableDetailEffectiveBalance END) /*effective balance*/  
	,SUM(RecInv.OriginalTaxBalance) OriginalTaxBalance  
	,SUM(CASE WHEN RecInv.IsFunderOwnedReceivable = 1 OR RecInv.IsDiscountingProceeds = 1 THEN 0.00 ELSE RecInv.OriginalTaxBalance END)  
	,SUM(CASE WHEN RecInv.IsFunderOwnedReceivable = 1 OR RecInv.IsDiscountingProceeds = 1 THEN 0.00 ELSE RecInv.OriginalEffectiveTaxBalance END) /*effective tax balance*/  
	,RecInv.CurrencyISO  
	,RecInv.CurrencyISO  
	,RecInv.CurrencyISO  
	,RecInv.CurrencyISO  
	,RecInv.CurrencyISO  
	,RecInv.CurrencyISO  
	,@CreatedById  
	,@CreatedTime  
	,RecInv.InvoicePreference  
	,RecInv.InvoicePreference  
	,@RunTimeComment  
	,RecInv.IsPrivateLabel  
	,RecInv.OriginationSource  
	,RecInv.OriginationSourceId  
	,RecInv.IsACH  
	,RecInv.SequenceGeneratedNumber  
	,RecInv.AlternateBillingCurrencyId  
	,0  
	,0  
	,''  
	,''  
	,0  
	,ISNULL(SUM(RecInv.WithHoldingTaxBalance), 0) WithHoldingTaxAmount  
	,SUM(CASE WHEN RecInv.IsFunderOwnedReceivable = 1 THEN 0.00 ELSE ISNULL(RecInv.WithHoldingTaxBalance, 0) END) AS WithHoldingTaxAmount  
	,RecInv.CurrencyISO   
	,RecInv.CurrencyISO  
	,SUM(RecInv.ReceivableAmount)  
	,RecInv.CurrencyISO  
	,SUM(RecInv.TaxAmount)  
	,RecInv.CurrencyISO  
	,RecInv.LegalEntityNumber  
	,RecInv.CustomerNumber  
	,RecInv.CustomerName  
	,RecInv.RemitToName  
	,RecInv.CurrencyISO   
	,RecInv.AlternateBillingCurrencyISO  
	,RecInv.ReceivableTaxType
	,MAX(RecInv.DealCountryId)
	,CASE WHEN RecInv.ReceivableTaxType='VAT' OR RecInv.SplitCreditsByOriginalInvoice = 1 THEN RecInv.OriginalInvoiceNumber ELSE NULL END
	FROM #ReceivableInvoice AS RecInv  
	GROUP BY RecInv.SequenceGeneratedNumber  
	,RecInv.InvoiceDueDate  
	,RecInv.SplitRentalInvoiceByContract  
	,RecInv.SplitLeaseRentalInvoiceByLocation  
	,RecInv.SplitRentalInvoiceByAsset  
	,RecInv.SplitCreditsByOriginalInvoice  
	,RecInv.SplitByReceivableAdjustments 
	,RecInv.SplitReceivableDueDate
	,RecInv.SplitCustomerPurchaseOrderNumber 
	,RecInv.GenerateSummaryInvoice  
	,RecInv.CustomerId  
	,RecInv.BillToId  
	,RecInv.RemitToId  
	,RecInv.LegalEntityId  
	,RecInv.InvoiceFormatId  
	,RecInv.CurrencyId  
	,RecInv.AlternateBillingCurrencyId  
	,RecInv.CurrencyISO  
	,RecInv.InvoicePreference  
	,RecInv.IsPrivateLabel  
	,RecInv.OriginationSource  
	,RecInv.OriginationSourceId  
	,RecInv.IsDSL  
	,RecInv.IsACH  
	,RecInv.LegalEntityNumber  
	,RecInv.CustomerNumber  
	,RecInv.CustomerName  
	,RecInv.RemitToName  
	,RecInv.AlternateBillingCurrencyISO  
	,RecInv.ReceivableTaxType
	,CASE WHEN RecInv.ReceivableTaxType='VAT' OR RecInv.SplitCreditsByOriginalInvoice = 1 THEN RecInv.OriginalInvoiceNumber END
  
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
	,ReceivableAmount_Amount  
	,ReceivableAmount_Currency  
	,TaxAmount_Amount  
	,TaxAmount_Currency  
	,ReceivableId  
	,ReceivableTypeId  
	,SequenceNumber 
	,PaymentType
	)  
	SELECT   
		CASE WHEN RID.IsFunderOwnedReceivable = 1 THEN 0.00 ELSE RID.ReceivableDetailBalance END  
		,InsertedInvoice.CurrencyISO  
		,CASE WHEN RID.IsFunderOwnedReceivable = 1 OR RID.IsDiscountingProceeds = 1 THEN 0.00 ELSE RID.OriginalTaxBalance END  
		,InsertedInvoice.CurrencyISO  
		,RID.ReceivableDetailBalance  
		,InsertedInvoice.CurrencyISO  
		,RID.OriginalTaxAmount  
		,InsertedInvoice.CurrencyISO  
		,CASE WHEN RID.IsFunderOwnedReceivable = 1 THEN 0.00 ELSE RID.ReceivableDetailEffectiveBalance END  
		,InsertedInvoice.CurrencyISO  
		,CASE WHEN RID.IsFunderOwnedReceivable = 1 OR RID.IsDiscountingProceeds = 1  THEN 0.00 ELSE RID.OriginalEffectiveTaxBalance END  
		,InsertedInvoice.CurrencyISO  
		,RID.ReceivableDetailId  
		,InsertedInvoice.Id  
		,@CreatedById  
		,@CreatedTime  
		,RID.BlendNumber  
		,RID.EntityType  
		,RID.EntityId  
		,1  
		,RID.ExchangeRate  
		,RID.ReceivableCategoryId  
		,RID.ReceivableAmount  
		,InsertedInvoice.CurrencyISO  
		,RID.TaxAmount  
		,InsertedInvoice.CurrencyISO  
		,RID.ReceivableId  
		,RID.ReceivableTypeId  
		,RID.SequenceNumber  
		,RID.PaymentType
	FROM #InsertedInvoice AS InsertedInvoice  
	INNER JOIN #ReceivableInvoice AS RID ON InsertedInvoice.InvoiceNumber = RID.SequenceGeneratedNumber  
	
 	UPDATE ReceivableDetails  
	SET ReceivableDetails.BilledStatus = @BilledStatus_Invoiced  
	,UpdatedById = @CreatedById  
	,UpdatedTime = @CreatedTime  
	FROM ReceivableDetails   
	INNER JOIN #ReceivableInvoice ON ReceivableDetails.Id=#ReceivableInvoice.ReceivableDetailId  
	
	DROP TABLE IF EXISTS #ReceivableInvoice
	DROP TABLE IF EXISTS #InvoiceNumberByCountry
	DROP TABLE IF EXISTS #InsertedInvoice
END

GO

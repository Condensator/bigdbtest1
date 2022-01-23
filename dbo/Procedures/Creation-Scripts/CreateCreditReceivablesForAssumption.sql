SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CreateCreditReceivablesForAssumption]
(
@OriginalReceivableIds NVARCHAR(MAX),
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET,
@NewCustomerId BIGINT,
@IsTaxAssessed BIT,
@NewLocationId BIGINT = NULL,
@NewBillToId BIGINT = NULL,
@MigratedReceivableIds NVARCHAR(MAX)
)
AS
BEGIN
SET NOCOUNT ON
DECLARE @BillToLocationId BIGINT
SELECT ID INTO #OriginalIds FROM ConvertCSVToBigIntTable(@OriginalReceivableIds, ',')
SELECT ID INTO #MigratedIds FROM ConvertCSVToBigIntTable(@MigratedReceivableIds, ',')
DECLARE @IsSalesTaxRequiredForLoan BIT = CAST(0 AS BIT)
SELECT  @IsSalesTaxRequiredForLoan = CASE WHEN UPPER(Value) = 'TRUE' THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END
FROM dbo.GlobalParameters gp WHERE gp.Name = 'IsSalesTaxRequiredForLoan' AND gp.Category = 'SalesTax'

	CREATE TABLE #InsertedReceivables
	(
		NewReceivableId BIGINT,
		OldReceivableId BIGINT
	)

	CREATE TABLE #InsertedReceivableDetails
	(
		NewReceivableDetailId BIGINT,
		OldReceivableDetailId BIGINT
	)

	CREATE TABLE #InsertedNewReceivables
	(
		NewReceivableId BIGINT,
		OldReceivableId BIGINT
	)
	CREATE TABLE #InsertedNewReceivableDetails
	(
		NewReceivableDetailId BIGINT,
		OldReceivableDetailId BIGINT
	)

	CREATE TABLE #ReceivableDetailsComponent
	(
	    LeaseComponentAmount     DECIMAL(16, 2), 
	    NonLeaseComponentAmount  DECIMAL(16, 2), 
	    ReceivableDetailId       BIGINT
	)
	CREATE Table #InsertedReceivableSKUs
	(
		Id					BIGINT,
		ReceivableDetailId	BIGINT,
		AssetSKUId			BIGINT
	)
	CREATE Table #InsertedNewReceivableSKUs
	(
		Id					BIGINT,
		ReceivableDetailId	BIGINT,
		AssetSKUId			BIGINT
	);

	SELECT @BillToLocationId = LocationId 
	FROM Billtoes WHERE Id = @NewBillToId

	SELECT
		* INTO #OldReceivables
	FROM 
		Receivables
	WHERE 
		Id IN (SELECT Id FROM #OriginalIds)

	MERGE Receivables R
	USING #OldReceivables OLDR ON (R.Id = 0)
	WHEN NOT MATCHED THEN
		INSERT 
		   ([EntityType]
           ,[EntityId]
           ,[DueDate]
           ,[IsDSL]
           ,[IsActive]
           ,[InvoiceComment]
           ,[InvoiceReceivableGroupingOption]
           ,[IsGLPosted]
           ,[IncomeType]
           ,[PaymentScheduleId]
           ,[IsCollected]
           ,[IsServiced]
           ,[CreatedById]
           ,[CreatedTime]
           ,[ReceivableCodeId]
           ,[CustomerId]
           ,[FunderId]
           ,[RemitToId]
           ,[TaxRemitToId]
           ,[LocationId]
           ,[LegalEntityId]
           ,[IsDummy]
           ,[IsPrivateLabel]
           ,[SourceId]
           ,[SourceTable]
		   ,[TotalAmount_Currency]
		   ,[TotalAmount_Amount]
		   ,[TotalBalance_Currency]
		   ,[TotalBalance_Amount]
		   ,[TotalEffectiveBalance_Currency]
		   ,[TotalEffectiveBalance_Amount]
		   ,[TotalBookBalance_Currency]
		   ,[TotalBookBalance_Amount]
		   ,[ExchangeRate]
		   ,[AlternateBillingCurrencyId]
		   ,[ReceivableTaxType]
		   ,[DealCountryId]
		   ,[TaxSourceDetailId])
		VALUES
			([EntityType]
           ,[EntityId]
           ,[DueDate]
           ,[IsDSL]
           ,[IsActive]
           ,[InvoiceComment]
           ,[InvoiceReceivableGroupingOption]
           ,[IsGLPosted]
           ,[IncomeType]
           ,[PaymentScheduleId]
           ,[IsCollected]
           ,[IsServiced]
           ,@CreatedById
           ,@CreatedTime
           ,[ReceivableCodeId]
           ,[CustomerId]
           ,[FunderId]
           ,[RemitToId]
           ,[TaxRemitToId]
           ,[LocationId]
           ,[LegalEntityId]
           ,[IsDummy]
           ,[IsPrivateLabel]
           ,[SourceId]
           ,[SourceTable]
		   ,[TotalAmount_Currency]
		   ,0.0
		   ,[TotalBalance_Currency]
		   ,0.0
		   ,[TotalEffectiveBalance_Currency]
		   ,0.0
		   ,[TotalBookBalance_Currency]
		   ,0.0
		   ,[ExchangeRate]
		   ,[AlternateBillingCurrencyId]
		   ,[ReceivableTaxType]
		   ,[DealCountryId]
		   ,[TaxSourceDetailId])
	OUTPUT Inserted.Id, OLDR.Id INTO #InsertedReceivables;

	SELECT
		* INTO #OldReceivableDetails
	FROM ReceivableDetails RD
	INNER JOIN #InsertedReceivables R
		ON RD.ReceivableId = R.OldReceivableId

	MERGE ReceivableDetails RD
	USING #OldReceivableDetails OLDRD ON ( RD.Id =  0)
	WHEN  NOT MATCHED THEN
	INSERT
	(
		 [Amount_Amount]
        ,[Amount_Currency]
        ,[Balance_Amount]
        ,[Balance_Currency]
        ,[EffectiveBalance_Amount]
        ,[EffectiveBalance_Currency]
        ,[IsActive]
        ,[BilledStatus]
        ,[IsTaxAssessed]
        ,[CreatedById]
        ,[CreatedTime]
        ,[AssetId]
        ,[BillToId]
        ,[AdjustmentBasisReceivableDetailId]
        ,[ReceivableId]
		,[StopInvoicing]
		,[EffectiveBookBalance_Amount]
        ,[EffectiveBookBalance_Currency]
		,[AssetComponentType]
        ,[LeaseComponentAmount_Amount]
        ,[LeaseComponentAmount_Currency]
        ,[NonLeaseComponentAmount_Amount]
        ,[NonLeaseComponentAmount_Currency]
        ,[LeaseComponentBalance_Amount]
        ,[LeaseComponentBalance_Currency]
        ,[NonLeaseComponentBalance_Amount]
        ,[NonLeaseComponentBalance_Currency]
		,[PreCapitalizationRent_Amount]
		,[PreCapitalizationRent_Currency]
	)
	Values
	(
	    0 - [Amount_Amount]
        ,[Amount_Currency]
        ,0 - [Amount_Amount]
        ,[Balance_Currency]
        ,0 -[Amount_Amount]
        ,[EffectiveBalance_Currency]
        ,[IsActive]
        ,'NotInvoiced'
        ,@IsTaxAssessed
        ,@CreatedById
        ,@CreatedTime
        ,[AssetId]
        ,[BillToId]
        ,Id
        ,[NewReceivableId]
		,0
		,0
		,EffectiveBookBalance_Currency
		,AssetComponentType
		,0.00
		,[Amount_Currency]
		,0
		,[Amount_Currency]
		,0.00
		,[Amount_Currency]
		,0.00
		,[Amount_Currency]
		,0 - [PreCapitalizationRent_Amount]
		,[PreCapitalizationRent_Currency]
	)
	OUTPUT Inserted.Id, OLDRD.Id INTO #InsertedReceivableDetails;

	Insert INTO ReceivableSKUs
	(
		[Amount_Amount],
		[Amount_Currency],
		[CreatedById],
		[CreatedTime],
		[AssetSKUId],
		[ReceivableDetailId],
		[PreCapitalizationRent_Amount],
		[PreCapitalizationRent_Currency]
	)
	SELECT 
		 0 - RS.[Amount_Amount]
		,RS.[Amount_Currency]
		,@CreatedById
		,@CreatedTime
		,RS.[AssetSKUId]
		,IRD.NewReceivableDetailId
		,0 - RS.PreCapitalizationRent_Amount
		,RS.PreCapitalizationRent_Currency 
	FROM ReceivableSKUs RS
		INNER JOIN #InsertedReceivableDetails IRD ON RS.ReceivableDetailId = IRD.OldReceivableDetailId
	
	UPDATE R SET [TotalAmount_Currency] = CASE WHEN (SELECT TOP(1) Amount_Currency FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id) IS NOT NULL THEN (SELECT TOP(1) Amount_Currency FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id) ELSE 'USD' END,
				[TotalBalance_Currency] = CASE WHEN (SELECT TOP(1) Balance_Currency FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id) IS NOT NULL THEN (SELECT TOP(1) Balance_Currency FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id) ELSE 'USD'END,
				[TotalEffectiveBalance_Currency] = CASE WHEN (SELECT TOP(1) EffectiveBalance_Currency FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id) IS NOT NULL THEN  (SELECT TOP(1) EffectiveBalance_Currency FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id) ELSE 'USD' END,
				[TotalBookBalance_Currency] = CASE WHEN (SELECT TOP(1) EffectiveBookBalance_Currency FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id) IS NOT NULL THEN  (SELECT TOP(1) EffectiveBookBalance_Currency FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id) ELSE 'USD' END,
				[TotalAmount_Amount] =  CASE WHEN (SELECT SUM(Amount_Amount) FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id ) IS NOT NULL THEN (SELECT SUM(Amount_Amount) FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id ) ELSE 0.0 END,
				[TotalBalance_Amount] =CASE WHEN (SELECT SUM(Balance_Amount) FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id ) IS NOT NULL THEN (SELECT SUM(Balance_Amount) FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id ) ELSE 0.0 END,
				[TotalEffectiveBalance_Amount] = CASE WHEN (SELECT SUM(EffectiveBalance_Amount) FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id ) IS NOT NULL THEN (SELECT SUM(EffectiveBalance_Amount) FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id ) ELSE 0.0 END,
				[TotalBookBalance_Amount] =CASE WHEN (SELECT SUM(EffectiveBookBalance_Amount) FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id ) IS NOT NULL THEN (SELECT SUM(EffectiveBookBalance_Amount) FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id ) ELSE 0.0 END,
				UpdatedById = @CreatedById,
				UpdatedTime = @CreatedTime
	FROM [Receivables] R
	JOIN #InsertedReceivables I
	ON R.Id  = I.NewReceivableId
	
INSERT INTO #ReceivableDetailsComponent
SELECT *
FROM
(
    SELECT CASE
               WHEN la.IsLeaseAsset = 1 THEN rd.Amount_Amount
               ELSE 0.00
           END AS LeaseComponentAmount
         , CASE
               WHEN la.IsLeaseAsset = 0 THEN rd.Amount_Amount
               ELSE 0.00
           END AS NonLeaseComponentAmount
         , rd.Id AS ReceivableDetailId
    FROM Receivables r WITH(NOLOCK) 
		 INNER JOIN #InsertedReceivables I ON R.Id  = I.NewReceivableId
         INNER JOIN ReceivableDetails rd WITH(NOLOCK) ON rd.ReceivableId = r.Id
         INNER JOIN LeaseAssets la ON la.AssetId =  rd.AssetId
		 INNER JOIN LeaseFinances lf ON lf.Id = la.LeaseFinanceId and lf.IsCurrent=1 
		 INNER JOIN Assets a ON a.Id = la.AssetId		  
    WHERE a.IsSKU = 0  
		  
    UNION
       SELECT CASE
               WHEN la.IsLeaseAsset = 1 THEN rd.Amount_Amount
               ELSE 0.00
           END AS LeaseComponentAmount
         , CASE
               WHEN la.IsLeaseAsset = 0 THEN rd.Amount_Amount
               ELSE 0.00
           END AS NonLeaseComponentAmount
         , rd.Id AS ReceivableDetailId
    FROM Receivables r WITH(NOLOCK) 
            INNER JOIN ReceivableCodes rc on r.ReceivableCodeId = rc.Id
              INNER JOIN ReceivableTypes rt on rc.ReceivableTypeId = rt.Id
              INNER JOIN #InsertedReceivables I ON R.Id  = I.NewReceivableId
         INNER JOIN ReceivableDetails rd WITH(NOLOCK) ON rd.ReceivableId = r.Id
         INNER JOIN LeaseAssets la ON la.AssetId =  rd.AssetId
              INNER JOIN LeaseFinances lf ON lf.Id = la.LeaseFinanceId and lf.IsCurrent=1 
               INNER JOIN Assets a ON a.Id = la.AssetId         
    WHERE a.IsSKU = 1 AND rt.Name = 'LeaseFloatRateAdj'

    UNION
    SELECT SUM(CASE WHEN las.IsLeaseComponent = 1 THEN rs.Amount_Amount
                    ELSE 0.00
               END) AS LeaseComponentAmount
         , SUM(CASE
                   WHEN las.IsLeaseComponent = 0 THEN rs.Amount_Amount
                   ELSE 0.00
               END) AS  NonLeaseComponentAmount
         , rd.Id AS ReceivableDetailId
    FROM Receivables r WITH(NOLOCK) 
		 INNER JOIN #InsertedReceivables I ON R.Id  = I.NewReceivableId
         INNER JOIN ReceivableDetails rd WITH(NOLOCK) ON rd.ReceivableId = r.Id
         INNER JOIN LeaseAssets la ON rd.AssetId = la.AssetId AND (la.IsActive = 1 or la.TerminationDate is not null)
		 INNER JOIN LeaseFinances lf ON lf.Id = la.LeaseFinanceId and lf.IsCurrent =1 
         INNER JOIN LeaseAssetSKUs las ON la.Id = las.LeaseAssetId 
         INNER JOIN ReceivableSKUs rs WITH(NOLOCK) ON las.AssetSKUId = rs.AssetSKUId AND rd.Id = rs.ReceivableDetailId
    GROUP BY rd.Id
           , rd.AssetId
) AS Temp;

UPDATE ReceivableDetails
  SET 
      LeaseComponentAmount_Amount = rdc.LeaseComponentAmount
    , NonLeaseComponentAmount_Amount = rdc.NonLeaseComponentAmount
    , LeaseComponentBalance_Amount = rdc.LeaseComponentAmount
    , NonLeaseComponentBalance_Amount = rdc.NonLeaseComponentAmount
FROM ReceivableDetails rd WITH(NOLOCK)
     INNER JOIN #ReceivableDetailsComponent rdc ON rd.Id = rdc.ReceivableDetailId;

DELETE FROM #ReceivableDetailsComponent


MERGE Receivables R
	USING #OldReceivables OLDR ON (R.Id = 0)
	WHEN NOT MATCHED THEN
		INSERT 
		   ([EntityType]
           ,[EntityId]
           ,[DueDate]
           ,[IsDSL]
           ,[IsActive]
           ,[InvoiceComment]
           ,[InvoiceReceivableGroupingOption]
           ,[IsGLPosted]
           ,[IncomeType]
           ,[PaymentScheduleId]
           ,[IsCollected]
           ,[IsServiced]
           ,[CreatedById]
           ,[CreatedTime]
           ,[ReceivableCodeId]
           ,[CustomerId]
           ,[FunderId]
           ,[RemitToId]
           ,[TaxRemitToId]
           ,[LocationId]
           ,[LegalEntityId]
           ,[IsDummy]
           ,[IsPrivateLabel]
           ,[SourceId]
           ,[SourceTable] 
		   ,[TotalAmount_Currency]
		   ,[TotalAmount_Amount]
		   ,[TotalBalance_Currency]
		   ,[TotalBalance_Amount]
		   ,[TotalEffectiveBalance_Currency]
		   ,[TotalEffectiveBalance_Amount]
		   ,[TotalBookBalance_Currency]
		   ,[TotalBookBalance_Amount]
		   ,[ExchangeRate]
		   ,[AlternateBillingCurrencyId]
		   ,[ReceivableTaxType]
		   ,[DealCountryId]
		   ,[TaxSourceDetailId])
		VALUES
			([EntityType]
           ,[EntityId]
           ,[DueDate]
           ,[IsDSL]
           ,[IsActive]
           ,[InvoiceComment]
           ,[InvoiceReceivableGroupingOption]
           ,[IsGLPosted]
           ,[IncomeType]
           ,[PaymentScheduleId]
           ,[IsCollected]
           ,[IsServiced]
           ,@CreatedById
           ,@CreatedTime
           ,[ReceivableCodeId]
           ,@NewCustomerId
           ,[FunderId]
           ,[RemitToId]
           ,[TaxRemitToId]
           ,[LocationId]
           ,[LegalEntityId]
           ,[IsDummy]
           ,[IsPrivateLabel]
           ,[SourceId]
           ,[SourceTable] 
		   ,[TotalAmount_Currency]
		   ,0.0
		   ,[TotalBalance_Currency]
		   ,0.0
		   ,[TotalEffectiveBalance_Currency]
		   ,0.0
		   ,[TotalBookBalance_Currency]
		   ,0.0
		   ,[ExchangeRate]
		   ,[AlternateBillingCurrencyId]
		   ,[ReceivableTaxType]
		   ,[DealCountryId]
		   ,[TaxSourceDetailId])
	OUTPUT Inserted.Id, OLDR.Id INTO #InsertedNewReceivables;

	
	SELECT * INTO #ReceivableDetails 
	FROM ReceivableDetails RD
	INNER JOIN #InsertedNewReceivables R
		ON RD.ReceivableId = R.OldReceivableId

		MERGE ReceivableDetails RD
	USING #ReceivableDetails OLDRD ON ( RD.Id =  0)
	WHEN  NOT MATCHED THEN
	INSERT
	(
		 [Amount_Amount]
        ,[Amount_Currency]
        ,[Balance_Amount]
        ,[Balance_Currency]
        ,[EffectiveBalance_Amount]
        ,[EffectiveBalance_Currency]
        ,[IsActive]
        ,[BilledStatus]
        ,[IsTaxAssessed]
        ,[CreatedById]
        ,[CreatedTime]
        ,[AssetId]
        ,[BillToId]
        ,[AdjustmentBasisReceivableDetailId]
        ,[ReceivableId]
		,[StopInvoicing]
		,EffectiveBookBalance_Amount
		,EffectiveBookBalance_Currency
		,[AssetComponentType]
        ,[LeaseComponentAmount_Amount]
        ,[LeaseComponentAmount_Currency]
        ,[NonLeaseComponentAmount_Amount]
        ,[NonLeaseComponentAmount_Currency]
        ,[LeaseComponentBalance_Amount]
        ,[LeaseComponentBalance_Currency]
        ,[NonLeaseComponentBalance_Amount]
        ,[NonLeaseComponentBalance_Currency]
		,[PreCapitalizationRent_Amount]
		,[PreCapitalizationRent_Currency]
	)
	Values
	(
	     [Amount_Amount]
        ,[Amount_Currency]
        ,[Amount_Amount]
        ,[Balance_Currency]
        ,[Amount_Amount]
        ,[EffectiveBalance_Currency]
        ,[IsActive]
        ,'NotInvoiced'
        ,@IsTaxAssessed
        ,@CreatedById
        ,@CreatedTime
        ,[AssetId]
        ,@NewBillToId
        ,NULL
        ,NewReceivableId
		,0
		,EffectiveBookBalance_Amount
		,EffectiveBalance_Currency
		,AssetComponentType
		,0.00
		,[Amount_Currency]
		,0.00
		,[Amount_Currency]
		,0.00
		,[Amount_Currency]
		,0.00
		,[Amount_Currency]
		,[PreCapitalizationRent_Amount]
		,[PreCapitalizationRent_Currency]
	)
	OUTPUT Inserted.Id, OLDRD.Id INTO #InsertedNewReceivableDetails;

	Insert INTO ReceivableSKUs
	(
		[Amount_Amount],
		[Amount_Currency],
		[CreatedById],
		[CreatedTime],
		[AssetSKUId],
		[ReceivableDetailId],
		[PreCapitalizationRent_Amount],
		[PreCapitalizationRent_Currency]
	)
	OUTPUT inserted.Id,inserted.ReceivableDetailId,inserted.AssetSKUId INTO #InsertedNewReceivableSKUs
	SELECT 
		 RS.[Amount_Amount]
		,RS.[Amount_Currency]
		,@CreatedById
		,@CreatedTime
		,RS.[AssetSKUId]
		,IRD.NewReceivableDetailId
		,RS.PreCapitalizationRent_Amount 
		,RS.PreCapitalizationRent_Currency 
	FROM ReceivableSKUs RS
	INNER JOIN #InsertedNewReceivableDetails IRD ON RS.ReceivableDetailId = IRD.OldReceivableDetailId

	UPDATE R SET [TotalAmount_Currency] = CASE WHEN (SELECT TOP(1) Amount_Currency FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id) IS NOT NULL THEN (SELECT TOP(1) Amount_Currency FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id) ELSE 'USD' END,
				[TotalBalance_Currency] = CASE WHEN (SELECT TOP(1) Balance_Currency FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id) IS NOT NULL THEN (SELECT TOP(1) Balance_Currency FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id) ELSE 'USD'END,
				[TotalEffectiveBalance_Currency] = CASE WHEN (SELECT TOP(1) EffectiveBalance_Currency FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id) IS NOT NULL THEN  (SELECT TOP(1) EffectiveBalance_Currency FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id) ELSE 'USD' END,
				[TotalBookBalance_Currency] = CASE WHEN (SELECT TOP(1) EffectiveBookBalance_Currency FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id) IS NOT NULL THEN  (SELECT TOP(1) EffectiveBookBalance_Currency FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id) ELSE 'USD' END,
				[TotalAmount_Amount] =  CASE WHEN (SELECT SUM(Amount_Amount) FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id ) IS NOT NULL THEN (SELECT SUM(Amount_Amount) FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id ) ELSE 0.0 END,
				[TotalBalance_Amount] =CASE WHEN (SELECT SUM(Balance_Amount) FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id ) IS NOT NULL THEN (SELECT SUM(Balance_Amount) FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id ) ELSE 0.0 END,
				[TotalBookBalance_Amount] =CASE WHEN (SELECT SUM(EffectiveBookBalance_Amount) FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id ) IS NOT NULL THEN (SELECT SUM(EffectiveBookBalance_Amount) FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id ) ELSE 0.0 END,
				[TotalEffectiveBalance_Amount] = CASE WHEN (SELECT SUM(EffectiveBalance_Amount) FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id ) IS NOT NULL THEN (SELECT SUM(EffectiveBalance_Amount) FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id ) ELSE 0.0 END,
				UpdatedById = @CreatedById,
				UpdatedTime = @CreatedTime
	FROM [Receivables] R	
	JOIN #InsertedReceivables I
	ON R.Id  = I.NewReceivableId


	UPDATE R SET [TotalAmount_Currency] = CASE WHEN (SELECT TOP(1) Amount_Currency FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id) IS NOT NULL THEN (SELECT TOP(1) Amount_Currency FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id) ELSE 'USD' END,
				[TotalBalance_Currency] = CASE WHEN (SELECT TOP(1) Balance_Currency FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id) IS NOT NULL THEN (SELECT TOP(1) Balance_Currency FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id) ELSE 'USD'END,
				[TotalEffectiveBalance_Currency] = CASE WHEN (SELECT TOP(1) EffectiveBalance_Currency FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id) IS NOT NULL THEN  (SELECT TOP(1) EffectiveBalance_Currency FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id) ELSE 'USD' END,
				[TotalBookBalance_Currency] = CASE WHEN (SELECT TOP(1) EffectiveBookBalance_Currency FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id) IS NOT NULL THEN  (SELECT TOP(1) EffectiveBookBalance_Currency FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id) ELSE 'USD' END,
				[TotalAmount_Amount] =  CASE WHEN (SELECT SUM(Amount_Amount) FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id ) IS NOT NULL THEN (SELECT SUM(Amount_Amount) FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id ) ELSE 0.0 END,
				[TotalBalance_Amount] =CASE WHEN (SELECT SUM(Balance_Amount) FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id ) IS NOT NULL THEN (SELECT SUM(Balance_Amount) FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id ) ELSE 0.0 END,
				[TotalBookBalance_Amount] =CASE WHEN (SELECT SUM(EffectiveBookBalance_Amount) FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id ) IS NOT NULL THEN (SELECT SUM(EffectiveBookBalance_Amount) FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id ) ELSE 0.0 END,
				[TotalEffectiveBalance_Amount] = CASE WHEN (SELECT SUM(EffectiveBalance_Amount) FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id ) IS NOT NULL THEN (SELECT SUM(EffectiveBalance_Amount) FROM [ReceivableDetails] WHERE IsActive = 1 AND ReceivableId = R.Id ) ELSE 0.0 END,
				UpdatedById = @CreatedById,
				UpdatedTime = @CreatedTime
	FROM [Receivables] R	
	JOIN #InsertedNewReceivables I
	ON R.Id  = I.NewReceivableId


INSERT INTO #ReceivableDetailsComponent
SELECT *
FROM
(
    SELECT CASE
               WHEN la.IsLeaseAsset = 1 THEN rd.Amount_Amount
               ELSE 0.00
           END AS LeaseComponentAmount
         , CASE
               WHEN la.IsLeaseAsset = 0 THEN rd.Amount_Amount
               ELSE 0.00
           END AS NonLeaseComponentAmount
         , rd.Id AS ReceivableDetailId
    FROM Receivables r WITH(NOLOCK) 
		 INNER JOIN #InsertedNewReceivables I ON R.Id  = I.NewReceivableId
         INNER JOIN ReceivableDetails rd WITH(NOLOCK) ON rd.ReceivableId = r.Id
         INNER JOIN LeaseAssets la ON la.AssetId =  rd.AssetId
		 INNER JOIN LeaseFinances lf ON lf.Id = la.LeaseFinanceId and lf.IsCurrent=1 
		 INNER JOIN Assets a ON la.AssetId = a.Id		  
    WHERE a.IsSKU = 0 		
	
	UNION
      SELECT CASE
               WHEN la.IsLeaseAsset = 1 THEN rd.Amount_Amount
               ELSE 0.00
           END AS LeaseComponentAmount
         , CASE
               WHEN la.IsLeaseAsset = 0 THEN rd.Amount_Amount
               ELSE 0.00
           END AS NonLeaseComponentAmount
         , rd.Id AS ReceivableDetailId
    FROM Receivables r WITH(NOLOCK) 
	     INNER JOIN ReceivableCodes rc on r.ReceivableCodeId = rc.Id
         INNER JOIN ReceivableTypes rt on rc.ReceivableTypeId = rt.Id
		 INNER JOIN #InsertedNewReceivables I ON R.Id  = I.NewReceivableId
         INNER JOIN ReceivableDetails rd WITH(NOLOCK) ON rd.ReceivableId = r.Id
         INNER JOIN LeaseAssets la ON la.AssetId =  rd.AssetId
		 INNER JOIN LeaseFinances lf ON lf.Id = la.LeaseFinanceId and lf.IsCurrent=1 
		 INNER JOIN Assets a ON la.AssetId = a.Id		  
    WHERE a.IsSKU = 1 AND rt.Name = 'LeaseFloatRateAdj' 	

    UNION
    SELECT SUM(CASE WHEN las.IsLeaseComponent = 1 THEN rs.Amount_Amount
                    ELSE 0.00
               END) AS LeaseComponentAmount
         , SUM(CASE
                   WHEN las.IsLeaseComponent = 0 THEN rs.Amount_Amount
                   ELSE 0.00
               END) AS  NonLeaseComponentAmount
         , rd.Id AS ReceivableDetailId
    FROM Receivables r WITH(NOLOCK) 
		 INNER JOIN #InsertedNewReceivables I ON R.Id  = I.NewReceivableId
         INNER JOIN ReceivableDetails rd WITH(NOLOCK) ON rd.ReceivableId = r.Id
         INNER JOIN LeaseAssets la ON rd.AssetId = la.AssetId AND (la.IsActive = 1 or la.TerminationDate is not null)
		 INNER JOIN LeaseFinances lf ON lf.Id = la.LeaseFinanceId and lf.IsCurrent =1 
         INNER JOIN LeaseAssetSKUs las ON la.Id = las.LeaseAssetId 
         INNER JOIN ReceivableSKUs rs WITH(NOLOCK) ON las.AssetSKUId = rs.AssetSKUId AND rd.Id = rs.ReceivableDetailId
    GROUP BY rd.Id
           , rd.AssetId
) AS Temp;


UPDATE ReceivableDetails
  SET 
      LeaseComponentAmount_Amount = rdc.LeaseComponentAmount
    , NonLeaseComponentAmount_Amount = rdc.NonLeaseComponentAmount
    , LeaseComponentBalance_Amount = rdc.LeaseComponentAmount
    , NonLeaseComponentBalance_Amount = rdc.NonLeaseComponentAmount
FROM ReceivableDetails rd WITH(NOLOCK)
     INNER JOIN #ReceivableDetailsComponent rdc ON rd.Id = rdc.ReceivableDetailId;


IF @IsSalesTaxRequiredForLoan = 1
BEGIN
SELECT r.Id
INTO #LoanInterestBasedReceivables
FROM dbo.Receivables r
INNER JOIN dbo.ReceivableCodes rc ON r.ReceivableCodeId = rc.Id
INNER JOIN dbo.ReceivableTypes rt ON rc.ReceivableTypeId = rt.Id
INNER JOIN dbo.Contracts c ON r.EntityId = c.Id
WHERE (rt.Name = 'LoanInterest' OR r.SourceTable IN ('SundryRecurring','Sundry'))
AND (c.ContractType = 'Loan')
AND (r.Id IN (SELECT NewReceivableId FROM #InsertedNewReceivables) OR r.Id IN (SELECT NewReceivableId FROM #InsertedReceivables))
UPDATE Receivables SET LocationId = @BilltoLocationId , UpdatedById= @CreatedById,UpdatedTime = @CreatedTime
FROM Receivables
JOIN #LoanInterestBasedReceivables ON Receivables.Id = #LoanInterestBasedReceivables.Id
JOIN #InsertedNewReceivables ON #LoanInterestBasedReceivables.Id = #InsertedNewReceivables.NewReceivableId
--WHERE Receivables.Id IN (SELECT NewReceivableId FROM #InsertedNewReceivables) --(SELECT Id FROM #LoanInterestBasedReceivables)
UPDATE ReceivableDetails SET IsTaxAssessed = 0 , UpdatedById = @CreatedById,UpdatedTime = @CreatedTime WHERE ReceivableId IN (SELECT Id FROM #LoanInterestBasedReceivables)
END
UPDATE Payables SET SourceId = NewReceivableId , UpdatedById = @CreatedById,
				UpdatedTime = @CreatedTime
 FROM #InsertedNewReceivables R JOIN Payables ON R.OldReceivableId = Payables.SourceId AND Payables.SourceTable in ('SyndicatedAR', 'IndirectAR', 'PrincipalDueToInvestor', 'InterestDueToInvestor')

UPDATE RTD 
SET UpfrontTaxSundryId = NULL,
UpdatedById = @CreatedById,
UpdatedTime = @CreatedTime
FROM ReceivableTaxDetails RTD
JOIN ReceivableTaxes RT ON RT.Id = RTD.ReceivableTaxId
JOIN #OldReceivables R on R.Id = RT.ReceivableId
WHERE R.IsActive = 1
AND RT.IsActive = 1
AND RTD.IsActive = 1
AND RTD.UpfrontTaxSundryId IS NOT NULL

UPDATE RD 
SET RD.IsTaxAssessed = 1
FROM 
#MigratedIds MD 
INNER JOIN #InsertedReceivables IR on MD.Id = IR.OldReceivableId
INNER JOIN ReceivableDetails RD on RD.ReceivableId = IR.NewReceivableId

SELECT NewReceivableId,OldReceivableId FROM #InsertedReceivables

SELECT NewReceivableId,OldReceivableId FROM #InsertedNewReceivables 


IF OBJECT_ID('tempdb..#InsertedReceivables') IS NOT NULL 
	DROP TABLE #InsertedReceivables;

IF OBJECT_ID('tempdb..#InsertedNewReceivables') IS NOT NULL 
	DROP TABLE #InsertedNewReceivables;  

IF OBJECT_ID('tempdb..#ReceivableDetailsComponent') IS NOT NULL 
	DROP TABLE #ReceivableDetailsComponent;  

IF OBJECT_ID('tempdb..#InsertedReceivableSKUs') IS NOT NULL 
	DROP TABLE #InsertedReceivableSKUs;  

IF OBJECT_ID('tempdb..#InsertedNewReceivableSKUs') IS NOT NULL 
	DROP TABLE #InsertedNewReceivableSKUs;  
END

GO

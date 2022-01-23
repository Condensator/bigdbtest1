SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROC [dbo].[CreateReceivablesAndReceivableDetailsForAssetSale]
(
  @ReceivablesForAssetSale CreateReceivablesForAssetSaleParam READONLY,
  @ReceivableDetailsForAssetSale CreateReceivableDetailsForAssetSaleParam READONLY,
  @Currency NVARCHAR(3),
  @CreatedById BIGINT,
  @CreatedTime DATETIMEOFFSET
 
)
AS
BEGIN 
SET NOCOUNT ON

  SELECT * INTO #ReceivablesForCreation
  FROM  @ReceivablesForAssetSale

    SELECT * INTO #ReceivableDetailsForCreation
  FROM  @ReceivableDetailsForAssetSale

  CREATE TABLE #InsertedReceivables
  (
   NewReceivableId BIGINT,
   ReceivableTempId BIGINT,
   FunderId BIGINT
  )

MERGE Receivables R
USING @ReceivablesForAssetSale RFC ON 1 = 0
WHEN NOT MATCHED THEN
INSERT
(           [EntityType]
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
           ,[IsDummy]
           ,[IsPrivateLabel]
           ,[SourceTable]
           ,[SourceId]
		   ,[TotalAmount_Amount]
           ,[TotalAmount_Currency]
           ,[TotalBalance_Amount]
           ,[TotalBalance_Currency]
           ,[TotalEffectiveBalance_Amount]
           ,[TotalEffectiveBalance_Currency]
           ,[TotalBookBalance_Amount]
           ,[TotalBookBalance_Currency]
           ,[CreatedById]
           ,[CreatedTime]
           ,[ReceivableCodeId]
           ,[CustomerId]
           ,[FunderId]
           ,[RemitToId]
           ,[TaxRemitToId]
           ,[LocationId]
           ,[LegalEntityId]
           ,[ExchangeRate]
           ,[AlternateBillingCurrencyId]
           ,[CalculatedDueDate])

		   VALUES ( RFC.[EntityType]
           ,RFC.[EntityId]
           ,RFC.[DueDate]
           ,0
           ,1
           ,RFC.[InvoiceComment]
           ,RFC.[InvoiceReceivableGroupingOption]
           ,0
           ,'_'
           ,NULL
           ,RFC.[IsCollected]
           ,RFC.[IsServiced]
           ,RFC.[IsDummy]
           ,0
           ,RFC.[SourceTable]
           ,RFC.[SourceId]
		   ,RFC.[TotalAmount]
		   ,@Currency
		   ,RFC.[TotalBalance]
		   ,@Currency
		   ,RFC.[TotalBalance]
		   ,@Currency
		   ,RFC.[TotalBookBalance]
		   ,@Currency
           ,@CreatedById
           ,@CreatedTime
           ,RFC.[ReceivableCodeId]
           ,RFC.[CustomerId]
           ,RFC.[FunderId]
           ,RFC.[RemitToId]
           ,RFC.[TaxRemitToId]
           ,RFC.[LocationId]
           ,RFC.[LegalEntityId]
           ,RFC.[ExchangeRate]
           ,RFC.[AlternateBillingCurrencyId]
           ,NULL
		   ) 
		   OUTPUT Inserted.Id, RFC.ReceivableTempId, RFC.FunderId INTO #InsertedReceivables;


	  INSERT INTO ReceivableDetails
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
	SELECT 
		 RDFC.Amount
        ,@Currency
        ,RDFC.[Balance]
        ,@Currency
        ,RDFC.EffectiveBalance
        ,@Currency
        ,1
        ,'NotInvoiced'
        ,RDFC.IsTaxAssessed
        ,@CreatedById
        ,@CreatedTime
        ,RDFC.[AssetId]
        ,RDFC.[BillToId]
        ,NULL
        ,I.NewReceivableId
		,0
		,RDFC.EffectiveBookBalance
		,@Currency
		,'_'
		,RDFC.Amount
		,@Currency
		,0.00
		,@Currency
		,RDFC.[Balance]
		,@Currency
		,0.00
		,@Currency
		,0.00
		,@Currency
	FROM 
		 #ReceivableDetailsForCreation RDFC
	INNER JOIN #InsertedReceivables I
		ON RDFC.ReceivableTempId = I.ReceivableTempId
		
	
	UPDATE RFC
	SET RFC.AssetSaleReceivableId = I.NewReceivableId
	FROM  #ReceivablesForCreation RFC
	JOIN #InsertedReceivables I ON RFC.ReceivableTempId = I.ReceivableTempId
	

   SELECT  AssetSaleReceivableId ReceivableId,
   SourceId,
   FunderId,
   EntityId,
   DueDate,
   TotalAmount,
   ReceivableTempId
     FROM #ReceivablesForCreation

	
	END

GO

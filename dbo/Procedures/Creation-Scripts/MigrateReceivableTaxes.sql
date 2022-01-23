SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create procedure [dbo].[MigrateReceivableTaxes]
(	
    @userid bigint ,
	@moduleiterationstatusid bigint , 
	@createdtime datetimeoffset = null,
	@processedrecords bigint out,
	@failedrecords bigint out,
	@toolidentifier int
)
as
BEGIN	
SET XACT_ABORT ON
SET NOCOUNT ON
SET ANSI_WARNINGS ON

--DECLARE @UserId BIGINT;  
--DECLARE @FailedRecords BIGINT;  
--DECLARE @ProcessedRecords BIGINT;  
--DECLARE @CreatedTime DATETIMEOFFSET;  
--DECLARE @ModuleIterationStatusId BIGINT;  
--SET @UserId = 1;  
--SET @CreatedTime = SYSDATETIMEOFFSET();   
--SELECT @ModuleIterationStatusId=IsNull(MAX(ModuleIterationStatusId),0) from stgProcessingLog;  
--DECLARE @toolidentifier int = NULL

IF(@CreatedTime IS NULL)
SET @CreatedTime = SYSDATETIMEOFFSET();

SET @FailedRecords = 0
SET @ProcessedRecords = 0

DECLARE @TotalRecordsCount INT;
DECLARE @BatchCount INT;
DECLARE @MaxSalesTaxId INT = 0;
Declare @TakeCount INT = 100000;
Select @TotalRecordsCount = ISNULL(COUNT(Id), 0) FROM stgSalesTaxReceivableTax WHERE IsMigrated = 0 AND (@ToolIdentifier = ToolIdentifier OR @ToolIdentifier IS NULL)
DECLARE @Module VARCHAR(50) = NULL
SET @Module =
(
    SELECT StgModule.Name
    FROM StgModule
         INNER JOIN StgModuleIterationStatus ON StgModule.Id = StgModuleIterationStatus.ModuleId
    WHERE StgModuleIterationStatus.Id = @ModuleIterationStatusId
);

DECLARE @ExcludeValidate BIT = 0;
SELECT @ExcludeValidate = COUNT(*) FROM StgModule WHERE Name = @Module AND WhereClause LIKE '%IsValidationRequired%=%false%'

EXEC ResetStagingTempFields @Module,@ToolIdentifier

CREATE TABLE #ErrorLogs
([Msg]      NVARCHAR(MAX), 
 [EntityId] BIGINT
);

CREATE TABLE #FailedProcessingLogs
([Id]         BIGINT NOT NULL, 
 [SalesTaxId] BIGINT NOT NULL
);


DECLARE @SkipCount INT = 0
IF(@TotalRecordsCount > 0)
BEGIN
	WHILE(@SkipCount < @TotalRecordsCount)
	BEGIN	
	BEGIN TRY
	BEGIN TRANSACTION

		DROP TABLE IF EXISTS #SalesTaxReceivableTaxSubset
		CREATE TABLE [dbo].#SalesTaxReceivableTaxSubset(
			[Id] [bigint] NOT NULL,
			[SequenceNumber] [nvarchar](40) NULL,
			[CustomerPartyNumber] [nvarchar](40) NULL,
			[EntityType] [nvarchar](2) NOT NULL,
			[ReceivableType] [nvarchar](21) NOT NULL,
			[DueDate] [date] NOT NULL,
			[ReceivableUniqueIdentifier] [nvarchar](30) NULL,
			[GLTemplateName] [nvarchar](40) NULL,
			[TaxAmount_Amount] [decimal](16, 2) NOT NULL,
			[TaxAmount_Currency] [nvarchar](3) NOT NULL,
			[R_PartyId] [bigint] NULL,
			[R_ReceivableId] [bigint] NULL,
			[R_ReceivableTypeId] [bigint] NULL,
			[R_ContractId] [bigint] NULL,
			[R_GLTemplateId] [bigint] NULL
		)

		DROP TABLE IF EXISTS #SalesTaxReceivableTaxDetailSubset
		CREATE TABLE [dbo].#SalesTaxReceivableTaxDetailSubset(
			[Id] [bigint] NOT NULL,
			[AssetAlias] [nvarchar](100) NULL,
			[AssetLocationCode] [nvarchar](100) NULL,
			[LocationCode] [nvarchar](100) NULL,
			[UpfrontTaxMode] [nvarchar](6) NULL,
			[TaxBasisType] [nvarchar](2) NOT NULL,
			[Revenue_Amount] [decimal](16, 2) NOT NULL,
			[Revenue_Currency] [nvarchar](3) NOT NULL,
			[FairMarketValue_Amount] [decimal](16, 2) NOT NULL,
			[FairMarketValue_Currency] [nvarchar](3) NOT NULL,
			[Cost_Amount] [decimal](16, 2) NOT NULL,
			[Cost_Currency] [nvarchar](3) NOT NULL,
			[TaxAreaId] [bigint] NULL,
			[ManuallyAssessed] [bit] NOT NULL,
			[TaxCode] [nvarchar](40) NULL,
			[UpfrontPayableFactor] [decimal](10, 6) NOT NULL,
			[R_AssetLocationId] [bigint] NULL,
			[R_AssetLocation_LocationId] [bigint] NULL,
			[R_LocationId] [bigint] NULL,
			[R_AssetId] [bigint] NULL,
			[R_ReceivableDetailId] [bigint] NULL,
			[R_Amount_Amount] [decimal](16, 2) NOT NULL,
			[R_Amount_Currency] [nvarchar](3) NOT NULL,
			[SalesTaxReceivableTaxId] [bigint] NOT NULL,
			[EntityType] [nvarchar](2) NOT NULL
		)

		DROP TABLE IF EXISTS #SalesTaxReceivableTaxImpositionSubset
		CREATE TABLE [dbo].#SalesTaxReceivableTaxImpositionSubset(
			[Id] [bigint] NOT NULL,
			[ExternalJurisdictionLevel] [nvarchar](200) NULL,
			[ExternalTaxImpositionType] [nvarchar](100) NULL,
			[TaxType] [nvarchar](40) NULL,
			[TaxBasisType] [nvarchar](2) NOT NULL,
			[ExemptionType] [nvarchar](21) NULL,
			[ExemptionRate] [decimal](10, 6) NOT NULL,
			[ExemptionAmount_Amount] [decimal](16, 2) NOT NULL,
			[ExemptionAmount_Currency] [nvarchar](3) NOT NULL,
			[TaxableBasisAmount_Amount] [decimal](16, 2) NOT NULL,
			[TaxableBasisAmount_Currency] [nvarchar](3) NOT NULL,
			[AppliedTaxRate] [decimal](10, 6) NOT NULL,
			[TaxAmount_Amount] [decimal](16, 2) NOT NULL,
			[TaxAmount_Currency] [nvarchar](3) NOT NULL,
			[R_TaxTypeId] [bigint] NULL,
			[R_ExternalJurisdictionLevelId] [bigint] NULL,
			[SalesTaxReceivableTaxDetailId] [bigint] NOT NULL
		)

		INSERT INTO #SalesTaxReceivableTaxSubset(Id,SequenceNumber,CustomerPartyNumber,EntityType,ReceivableType,DueDate,ReceivableUniqueIdentifier,GLTemplateName,TaxAmount_Amount,TaxAmount_Currency) 
		SELECT TOP (@TakeCount) Id,SequenceNumber,CustomerPartyNumber,EntityType,ReceivableType,DueDate,ReceivableUniqueIdentifier,GLTemplateName,TaxAmount_Amount,TaxAmount_Currency
		FROM stgSalesTaxReceivableTax WITH(NOLOCK)
		WHERE IsMigrated = 0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier)
			  AND stgSalesTaxReceivableTax.Id > @MaxSalesTaxId;

		INSERT INTO #SalesTaxReceivableTaxDetailSubset(Id,AssetAlias,AssetLocationCode,LocationCode,UpfrontTaxMode,TaxBasisType,Revenue_Amount,Revenue_Currency,FairMarketValue_Amount,FairMarketValue_Currency,Cost_Amount,Cost_Currency,TaxAreaId,ManuallyAssessed,TaxCode,UpfrontPayableFactor ,SalesTaxReceivableTaxId,EntityType,R_Amount_Amount,R_Amount_Currency)
		select stgSalesTaxReceivableTaxDetail.Id,AssetAlias,AssetLocationCode,LocationCode,UpfrontTaxMode,TaxBasisType,Revenue_Amount,Revenue_Currency,FairMarketValue_Amount,FairMarketValue_Currency,Cost_Amount,Cost_Currency,TaxAreaId,ManuallyAssessed,TaxCode,UpfrontPayableFactor ,SalesTaxReceivableTaxId,EntityType,0.00,Revenue_Currency
		from #SalesTaxReceivableTaxSubset 
		inner join stgSalesTaxReceivableTaxDetail WITH(NOLOCK) on stgSalesTaxReceivableTaxDetail.SalesTaxReceivableTaxId = #SalesTaxReceivableTaxSubset.Id

		INSERT INTO #SalesTaxReceivableTaxImpositionSubset(Id,ExternalJurisdictionLevel,ExternalTaxImpositionType,TaxType,TaxBasisType,ExemptionType,ExemptionRate,ExemptionAmount_Amount,ExemptionAmount_Currency,TaxableBasisAmount_Amount,TaxableBasisAmount_Currency,AppliedTaxRate,TaxAmount_Amount,TaxAmount_Currency,SalesTaxReceivableTaxDetailId)
		select stgSalesTaxReceivableTaxImposition.Id,ExternalJurisdictionLevel,ExternalTaxImpositionType,TaxType,stgSalesTaxReceivableTaxImposition.TaxBasisType,ExemptionType,ExemptionRate,ExemptionAmount_Amount,ExemptionAmount_Currency,TaxableBasisAmount_Amount,TaxableBasisAmount_Currency,AppliedTaxRate,TaxAmount_Amount,TaxAmount_Currency,SalesTaxReceivableTaxDetailId
		from #SalesTaxReceivableTaxDetailSubset 
		inner join stgSalesTaxReceivableTaxImposition WITH(NOLOCK) on stgSalesTaxReceivableTaxImposition.SalesTaxReceivableTaxDetailId = #SalesTaxReceivableTaxDetailSubset.Id
		
		CREATE NONCLUSTERED INDEX IX_SalesTaxReceivableTaxId ON #SalesTaxReceivableTaxSubset(Id);
		CREATE NONCLUSTERED INDEX IX_SalesTaxReceivableTaxDetailId ON #SalesTaxReceivableTaxDetailSubset(Id);
		CREATE NONCLUSTERED INDEX IX_SalesTaxReceivableTaxImpositionId ON #SalesTaxReceivableTaxImpositionSubset(Id);

		SELECT @MaxSalesTaxId = ISNULL(MAX(Id), 0)
		FROM #SalesTaxReceivableTaxSubset;
		SELECT @BatchCount = COUNT(*) FROM #SalesTaxReceivableTaxSubset;
		SELECT @SkipCount = @SkipCount + @TakeCount

--========================================Validations==========================================================	
		UPDATE #SalesTaxReceivableTaxSubset SET R_ContractId = Contracts.Id
		FROM 
			#SalesTaxReceivableTaxSubset salesTax WITH(NOLOCK) 
			INNER JOIN Contracts WITH (NOLOCK) ON salesTax.SequenceNumber = Contracts.SequenceNumber
		WHERE salesTax.EntityType = 'CT'

		UPDATE #SalesTaxReceivableTaxSubset SET R_PartyId = Parties.Id
		FROM 
			#SalesTaxReceivableTaxSubset salesTax WITH(NOLOCK) 
			INNER JOIN Parties WITH (NOLOCK) ON salesTax.CustomerPartyNumber = Parties.PartyNumber
		WHERE salesTax.CustomerPartyNumber IS NOT NULL

		INSERT INTO #ErrorLogs
		SELECT 
		'Invalid SequenceNumber {'+ISNULL(salesTax.SequenceNumber,'NULL')+'} for SalesTaxReceivableTax Id { '+ CONVERT(VARCHAR,salesTax.Id) +' }'
		,salesTax.Id 
		FROM #SalesTaxReceivableTaxSubset salesTax WITH (NOLOCK) 
		WHERE salesTax.R_ContractId IS NULL AND salesTax.EntityType = 'CT'

		INSERT INTO #ErrorLogs
		SELECT
		'SequenceNumber should not be provided if Entity type of the receivable is Customer for SalesTaxReceivableTax Id { '+ CONVERT(VARCHAR,salesTax.Id) +' }'
		,salesTax.Id 
		FROM #SalesTaxReceivableTaxSubset salesTax WITH (NOLOCK) 
		WHERE salesTax.SequenceNumber IS NOT NULL AND salesTax.EntityType = 'CU'

		INSERT INTO #ErrorLogs
		SELECT 
		'Invalid CustomerPartyNumber {'+ISNULL(salesTax.CustomerPartyNumber,'NULL')+'} for SalesTaxReceivableTax Id { '+ CONVERT(VARCHAR,salesTax.Id) +' }'
		,salesTax.Id 
		FROM #SalesTaxReceivableTaxSubset salesTax WITH (NOLOCK) 
		WHERE salesTax.R_PartyId IS NULL AND (salesTax.EntityType = 'CU' OR salesTax.CustomerPartyNumber IS NOT NULL)

		SELECT r.EntityId, MAX(r.LegalEntityId) AS LegalEntityId
		INTO #ReceivableTemp
		FROM #SalesTaxReceivableTaxSubset salesTax WITH (NOLOCK) 
		INNER JOIN Receivables r WITH(NOLOCK) ON r.EntityId = salesTax.R_ContractId AND r.EntityType = 'CT'
		WHERE salesTax.EntityType = 'CT'
		GROUP BY r.EntityId

		UPDATE #SalesTaxReceivableTaxSubset SET R_GLTemplateId = GLT.Id
		FROM #SalesTaxReceivableTaxSubset salesTax WITH(NOLOCK)
			 INNER JOIN #ReceivableTemp R WITH(NOLOCK) ON R.EntityId = salesTax.R_ContractId
														  AND salesTax.EntityType = 'CT'
			 INNER JOIN LegalEntities LE WITH(NOLOCK) ON LE.Id = R.LegalEntityId
														 AND LE.Status = 'Active'
			 INNER JOIN GLConfigurations GLC WITH(NOLOCK) ON GLC.Id = LE.GLConfigurationId
			 INNER JOIN GLTemplates GLT WITH(NOLOCK) ON GLC.Id = GLT.GLConfigurationId
														AND GLT.IsActive = 1
			 INNER JOIN GLTransactionTypes GTT WITH(NOLOCK) ON GLT.GLTransactionTypeId = GTT.Id
															   AND GTT.IsActive = 1
															   AND GTT.Name = 'salesTax'
		WHERE salesTax.GLTemplateName IS NULL;

		UPDATE #SalesTaxReceivableTaxSubset SET  R_GLTemplateId = GLT.Id
		FROM #SalesTaxReceivableTaxSubset salesTax WITH(NOLOCK)
			 INNER JOIN #ReceivableTemp R WITH(NOLOCK) ON R.EntityId = salesTax.R_ContractId AND salesTax.EntityType = 'CT' 
			 INNER JOIN LegalEntities LE WITH(NOLOCK) ON LE.Id = R.LegalEntityId
														 AND LE.Status = 'Active'
			 INNER JOIN GLConfigurations GLC WITH(NOLOCK) ON GLC.Id = LE.GLConfigurationId
			 INNER JOIN GLTemplates GLT WITH(NOLOCK) ON GLC.Id = GLT.GLConfigurationId
														AND GLT.IsActive = 1
														AND GLT.Name = salesTax.GLTemplateName
			 INNER JOIN GLTransactionTypes GTT WITH(NOLOCK) ON GLT.GLTransactionTypeId = GTT.Id
															   AND GTT.IsActive = 1
		WHERE salesTax.GLTemplateName IS NOT NULL;

		INSERT INTO #ErrorLogs
		SELECT 
		'Invalid GL Template Name for SalesTaxReceivableTax Id { '+ CONVERT(VARCHAR,salesTax.Id) +' }' 
		,salesTax.Id
		FROM #SalesTaxReceivableTaxSubset salesTax WITH (NOLOCK) 
		WHERE salesTax.R_GLTemplateId IS NULL AND salesTax.GLTemplateName IS NOT NULL AND salesTax.EntityType = 'CT'

		UPDATE #SalesTaxReceivableTaxSubset SET R_ReceivableTypeId = rt.Id
		FROM 
			#SalesTaxReceivableTaxSubset salesTax WITH(NOLOCK) 
			INNER JOIN ReceivableTypes rt WITH (NOLOCK) ON salesTax.ReceivableType = rt.Name
		WHERE rt.IsActive = 1

		SELECT Id
		INTO #MultipleReceivables
		FROM
		(
			SELECT salesTax.Id
			FROM #SalesTaxReceivableTaxSubset salesTax
				 INNER JOIN Receivables r ON salesTax.DueDate = r.DueDate
											 AND r.EntityId = CASE
																  WHEN salesTax.EntityType = 'CU'
																  THEN R_PartyId
																  ELSE R_ContractId
															  END
				 INNER JOIN ReceivableCodes ON ReceivableCodes.Id = r.ReceivableCodeId
				 INNER JOIN ReceivableTypes rt ON rt.Id = ReceivableCodes.ReceivableTypeId
			WHERE rt.IsRental = 0
				  AND (R_PartyId IS NOT NULL OR R_ContractID IS NOT NULL)
			GROUP BY salesTax.Id
			HAVING COUNT(*) > 1
		) AS temp;

		SELECT Id
		INTO #EligibleReceivableDetails FROM
		(SELECT r.Id
		FROM #SalesTaxReceivableTaxSubset salesTax WITH(NOLOCK)
			 INNER JOIN Receivables r ON r.EntityId = salesTax.R_ContractId 
										 AND r.EntityType = 'CT'
			 INNER JOIN ReceivableDetails rd WITH(NOLOCK) ON r.Id = rd.ReceivableId
		WHERE rd.IsTaxAssessed = 0 and r.IsActive = 1 
		UNION
		SELECT r.Id
		FROM #SalesTaxReceivableTaxSubset salesTax WITH(NOLOCK)
			 INNER JOIN Receivables r ON r.EntityId = salesTax.R_PartyId
										 AND r.EntityType = 'CU'
			 INNER JOIN ReceivableDetails rd WITH(NOLOCK) ON r.Id = rd.ReceivableId
		WHERE rd.IsTaxAssessed = 0 AND r.IsActive = 1 ) as t

		INSERT INTO #ErrorLogs
		SELECT 
		'Multiple Receivables found for Sales Tax Id { '+ CONVERT(VARCHAR,salesTax.Id) +' }. Please provide ReceivableUniqueIdentifier.' 
		,salesTax.Id
		FROM #SalesTaxReceivableTaxSubset salesTax 
		INNER JOIN #MultipleReceivables on salesTax.Id = #MultipleReceivables.Id
		where salesTax.ReceivableUniqueIdentifier IS NULL

		UPDATE salesTax SET R_ReceivableId = r.Id
		FROM #SalesTaxReceivableTaxSubset salesTax WITH(NOLOCK)
		INNER JOIN #MultipleReceivables on salesTax.Id = #MultipleReceivables.Id
		INNER JOIN Receivables r WITH(NOLOCK) on salesTax.ReceivableUniqueIdentifier = r.UniqueIdentifier
		INNER JOIN ReceivableCodes rc WITH(NOLOCK) on rc.Id = r.ReceivableCodeId AND salesTax.R_ReceivableTypeId = rc.ReceivableTypeId
				
		UPDATE salesTax SET R_ReceivableId = r.Id
		FROM #SalesTaxReceivableTaxSubset salesTax WITH(NOLOCK)
			 INNER JOIN Receivables r WITH(NOLOCK) ON r.EntityId = salesTax.R_ContractId
													  AND r.EntityType = 'CT'
			 INNER JOIN #EligibleReceivableDetails erd WITH(NOLOCK) ON r.Id = erd.Id
			 INNER JOIN ReceivableCodes rc WITH(NOLOCK) ON r.ReceivableCodeId = rc.Id
			 LEFT JOIN #MultipleReceivables multipleReceivables WITH(NOLOCK) ON salesTax.Id = multipleReceivables.Id
		WHERE salesTax.EntityType = 'CT'
			  AND salesTax.DueDate = r.DueDate
			  AND salesTax.R_ReceivableTypeId = rc.ReceivableTypeId
			  AND multipleReceivables.Id IS NULL

		UPDATE salesTax SET R_ReceivableId = r.Id
		FROM #SalesTaxReceivableTaxSubset salesTax WITH(NOLOCK)
		INNER JOIN Receivables r WITH(NOLOCK) ON r.EntityId = R_PartyId
		INNER JOIN #EligibleReceivableDetails erd WITH(NOLOCK) ON r.Id = erd.Id
		INNER JOIN ReceivableCodes rc WITH(NOLOCK) ON r.ReceivableCodeId = rc.Id
		inner join ReceivableTypes rt on rt.Id =  rc.ReceivableTypeId
		LEFT JOIN #MultipleReceivables multipleReceivables WITH(NOLOCK) ON salesTax.Id = multipleReceivables.Id
		WHERE salesTax.EntityType = 'CU'
			  AND salesTax.DueDate = r.DueDate
			  AND salesTax.R_ReceivableTypeId = rc.ReceivableTypeId
			  AND rt.IsRental = 0
			  AND multipleReceivables.Id IS NULL
		
		UPDATE #SalesTaxReceivableTaxSubset SET R_GLTemplateId = GLT.Id
		FROM #SalesTaxReceivableTaxSubset salesTax WITH(NOLOCK)
		INNER JOIN Receivables R WITH(NOLOCK) ON R.Id = salesTax.R_ReceivableId
		INNER JOIN LegalEntities LE WITH(NOLOCK) ON LE.Id = R.LegalEntityId
														 AND LE.Status = 'Active'
			 INNER JOIN GLConfigurations GLC WITH(NOLOCK) ON GLC.Id = LE.GLConfigurationId
			 INNER JOIN GLTemplates GLT WITH(NOLOCK) ON GLC.Id = GLT.GLConfigurationId
														AND GLT.IsActive = 1
														AND GLT.Name = salesTax.GLTemplateName
			 INNER JOIN GLTransactionTypes GTT WITH(NOLOCK) ON GLT.GLTransactionTypeId = GTT.Id
															   AND GTT.IsActive = 1
		WHERE salesTax.GLTemplateName IS NOT NULL AND salesTax.EntityType = 'CU';
		
		INSERT INTO #ErrorLogs
		SELECT 
		'Invalid GL Template Name for SalesTaxReceivableTax Id { '+ CONVERT(VARCHAR,salesTax.Id) +' }' 
		,salesTax.Id
		FROM #SalesTaxReceivableTaxSubset salesTax WITH (NOLOCK) 
		WHERE salesTax.R_GLTemplateId IS NULL AND salesTax.EntityType = 'CU'

		INSERT INTO #ErrorLogs
		SELECT 
		'GL Template of Sales Tax does not exist for SalesTaxReceivableTax Id { '+ CONVERT(VARCHAR,salesTax.Id) +' }' 
		,salesTax.Id
		FROM #SalesTaxReceivableTaxSubset salesTax WITH (NOLOCK) 
		WHERE salesTax.R_GLTemplateId IS NULL AND salesTax.GLTemplateName IS NULL AND R_ReceivableId IS NULL

		INSERT INTO #ErrorLogs
		SELECT 'No receivable found as of ' + CONVERT(NVARCHAR(50), ISNULL(DueDate, @CreatedTime)) + ' for Entity: ' + ISNULL(SequenceNumber, CustomerPartyNumber) + ' Entity Type: ' + salesTax.EntityType
			 , salesTax.Id
		FROM #SalesTaxReceivableTaxSubset salesTax WITH(NOLOCK)
		LEFT JOIN #MultipleReceivables multipleReceivables WITH(NOLOCK) ON salesTax.Id = multipleReceivables.Id
		WHERE salesTax.R_ReceivableId IS NULL 
			AND multipleReceivables.Id IS NULL 
			AND (salesTax.SequenceNumber IS NOT NULL OR salesTax.CustomerPartyNumber IS NOT NULL)

		UPDATE salesTaxDetail SET R_AssetId = a.Id
		FROM 
			#SalesTaxReceivableTaxDetailSubset salesTaxDetail WITH(NOLOCK)
			INNER JOIN Assets a WITH (NOLOCK) ON a.Alias = salesTaxDetail.AssetAlias
		WHERE salesTaxDetail.AssetAlias IS NOT NULL

		INSERT INTO #ErrorLogs
		SELECT 'Invalid AssetAlias {'+ISNULL(salesTaxDetail.AssetAlias,'NULL')+'} for SalesTaxReceivableTaxDetail Id { '+ CONVERT(VARCHAR,salesTaxDetail.Id) +' }'
			 , salesTaxDetail.SalesTaxReceivableTaxId
		FROM #SalesTaxReceivableTaxDetailSubset salesTaxDetail WITH(NOLOCK) 
		WHERE salesTaxDetail.R_AssetId IS NULL AND salesTaxDetail.AssetAlias IS NOT NULL;

		UPDATE salesTaxDetail SET R_LocationId = l.Id
		FROM 
			#SalesTaxReceivableTaxDetailSubset salesTaxDetail WITH(NOLOCK)
			INNER JOIN Locations l WITH (NOLOCK) ON l.Code = salesTaxDetail.LocationCode
		WHERE salesTaxDetail.LocationCode IS NOT NULL

		INSERT INTO #ErrorLogs
		SELECT 'Invalid LocationCode {'+ISNULL(salesTaxDetail.LocationCode,'NULL')+'} for SalesTaxReceivableTaxDetail Id { '+ CONVERT(VARCHAR,salesTaxDetail.Id) +' }'
			 , salesTaxDetail.SalesTaxReceivableTaxId
		FROM #SalesTaxReceivableTaxDetailSubset salesTaxDetail WITH(NOLOCK) 
		WHERE salesTaxDetail.R_LocationId IS NULL AND salesTaxDetail.LocationCode IS NOT NULL;

		UPDATE salesTaxDetail SET R_ReceivableDetailId = r.Id, R_Amount_Amount = r.Amount_Amount
		FROM #SalesTaxReceivableTaxSubset salesTax WITH(NOLOCK)
			 INNER JOIN #SalesTaxReceivableTaxDetailSubset salesTaxDetail WITH(NOLOCK) ON salesTaxDetail.SalesTaxReceivableTaxId = salesTax.Id
			 INNER JOIN ReceivableDetails r WITH(NOLOCK) ON r.ReceivableId = salesTax.R_ReceivableId
															AND R.AssetId = salesTaxDetail.R_AssetId
		WHERE R_AssetId IS NOT NULL
			  AND r.IsTaxAssessed = 0
			  AND r.IsActive = 1;
		
		UPDATE salesTaxDetail SET R_ReceivableDetailId = rd.Id, R_Amount_Amount = rd.Amount_Amount
		FROM #SalesTaxReceivableTaxSubset salesTax WITH(NOLOCK)
			 INNER JOIN #SalesTaxReceivableTaxDetailSubset salesTaxDetail WITH(NOLOCK) ON salesTaxDetail.SalesTaxReceivableTaxId = salesTax.Id
			 inner join LeaseAssets la on la.AssetId = salesTaxDetail.R_AssetId
		 	 inner join LeaseFinances lf on la.LeaseFinanceId = lf.Id 
			 inner join Contracts c on lf.ContractId = c.Id AND salesTax.R_ContractId = c.Id
			 INNER JOIN ReceivableDetails rd WITH(NOLOCK) ON rd.ReceivableId = salesTax.R_ReceivableId
		WHERE R_AssetId IS NOT NULL AND rd.AssetId IS NULL AND R_ReceivableDetailId IS NULL
			  AND rd.IsTaxAssessed = 0
			  AND rd.IsActive = 1
			  AND lf.IsCurrent = 1
		
		IF(@ExcludeValidate=0)
		BEGIN

		SELECT salesTax.Id INTO #SundrySalesTax 
		FROM #SalesTaxReceivableTaxSubset salesTax 
		INNER JOIN Receivables r WITH(NOLOCK) ON r.Id = salesTax.R_ReceivableId
		INNER JOIN Sundries s WITH(NOLOCK) ON s.Id = r.SourceId
		INNER JOIN ReceivableDetails rd WITH(NOLOCK) ON rd.ReceivableId = salesTax.R_ReceivableId
		WHERE salesTax.EntityType = 'CT'
			  AND rd.AssetId IS NULL
			  AND r.SourceTable = 'Sundry'
			  AND s.IsAssetBased = 0
			  AND rd.IsTaxAssessed = 0
			  AND rd.IsActive = 1

		select salesTax.Id,COUNT(la.Id) as NumberofAssets INTO #LeaseAssetCount
		from #SalesTaxReceivableTaxSubset salesTax 
		inner join #SundrySalesTax on salesTax.Id = #SundrySalesTax.Id
		inner join Contracts c on salesTax.R_ContractId = c.Id
		inner join  LeaseFinances lf ON lf.ContractId = c.Id
		inner join  LeaseAssets la on la.LeaseFinanceId = lf.Id 
		WHERE  lf.IsCurrent = 1
		GROUP BY salesTax.Id

		SELECT salesTax.Id,COUNT(salesTaxDetail.Id) as NumberofSalesTaxDetail INTO #salesTaxDetailCount
		FROM #SalesTaxReceivableTaxSubset salesTax WITH(NOLOCK)
			 INNER JOIN #SalesTaxReceivableTaxDetailSubset salesTaxDetail WITH(NOLOCK) ON salesTaxDetail.SalesTaxReceivableTaxId = salesTax.Id
			 INNER JOIN #LeaseAssetCount ON #LeaseAssetCount.Id = salesTax.Id
		WHERE R_AssetId IS NOT NULL 
		GROUP BY salesTax.Id

		INSERT INTO #ErrorLogs
		SELECT 'Number of Assets in the Contracts is not matching with number of SalesTaxDetail for SalesTaxReceivableTaxDetail Id { '+ CONVERT(VARCHAR,temp.Id) +' }'
		,temp.Id FROM
		(SELECT t1.Id, NumberofSalesTaxDetail,NumberofAssets 
		FROM #salesTaxDetailCount as t1
			INNER JOIN #LeaseAssetCount as t2 ON t1.Id = t2.Id
		WHERE (NumberofAssets != 0 AND NumberofSalesTaxDetail = 1) OR ( NumberofAssets != NumberofSalesTaxDetail)
		) as temp

		END

		UPDATE salesTaxDetail SET R_ReceivableDetailId = r.Id, R_Amount_Amount = r.Amount_Amount
		FROM #SalesTaxReceivableTaxSubset salesTax WITH(NOLOCK)
			 INNER JOIN #SalesTaxReceivableTaxDetailSubset salesTaxDetail WITH(NOLOCK) ON salesTaxDetail.SalesTaxReceivableTaxId = salesTax.Id
			 INNER JOIN ReceivableDetails r WITH(NOLOCK) ON r.ReceivableId = salesTax.R_ReceivableId
		WHERE AssetAlias IS NULL AND r.AssetId IS NULL AND R_ReceivableDetailId IS NULL
			  AND r.IsTaxAssessed = 0
			  AND r.IsActive = 1

		IF(@ExcludeValidate=0)
		BEGIN

			SELECT salesTax.Id, COUNT(rd.Id) NumberofReceivableDetails INTO #ReceivableDetailsCount
			FROM #SalesTaxReceivableTaxSubset salesTax WITH(NOLOCK)
				INNER JOIN ReceivableDetails rd WITH(NOLOCK) ON rd.ReceivableId = salesTax.R_ReceivableId
				WHERE rd.AssetId IS NOT NULL -- AND salesTax.EntityType = CU
			GROUP BY salesTax.Id

			SELECT salesTax.Id,COUNT(salesTaxDetail.Id) as NumberofSalesTaxDetail INTO #salesTaxDetail_CU_Count
			FROM #SalesTaxReceivableTaxSubset salesTax WITH(NOLOCK)
				 INNER JOIN #SalesTaxReceivableTaxDetailSubset salesTaxDetail WITH(NOLOCK) ON salesTaxDetail.SalesTaxReceivableTaxId = salesTax.Id
				 INNER JOIN #ReceivableDetailsCount ON #ReceivableDetailsCount.Id = salesTax.Id
			GROUP BY salesTax.Id

			INSERT INTO #ErrorLogs
			SELECT 'Number of ReceivableDetail is not matching with number of SalesTaxDetail for SalesTaxReceivableTaxDetail Id { '+ CONVERT(VARCHAR,temp.Id) +' }'
			,temp.Id FROM
			(SELECT t1.Id, NumberofSalesTaxDetail,NumberofReceivableDetails 
			FROM #salesTaxDetail_CU_Count as t1
				INNER JOIN #ReceivableDetailsCount as t2 ON t1.Id = t2.Id
			WHERE NumberofSalesTaxDetail != NumberofReceivableDetails
			) as temp

		END

		INSERT INTO #ErrorLogs
		SELECT 'No ReceivableDetail found for SalesTaxReceivableTaxDetail Id { '+ CONVERT(VARCHAR,salesTaxDetail.Id) +' }'
			 	 , salesTaxDetail.SalesTaxReceivableTaxId
		FROM #SalesTaxReceivableTaxDetailSubset salesTaxDetail WITH(NOLOCK)
		WHERE salesTaxDetail.R_ReceivableDetailId IS NULL;

		INSERT INTO #ErrorLogs
		SELECT 
		'TaxBasisType should be of type {ST} for SalesTaxReceivableTax Id { '+ CONVERT(VARCHAR,salesTax.Id) +' }' 
		,salesTax.Id
		FROM #SalesTaxReceivableTaxSubset salesTax WITH (NOLOCK) 
		INNER JOIN #SalesTaxReceivableTaxDetailSubset salesTaxDetail ON salesTaxDetail.SalesTaxReceivableTaxId = salesTax.Id
		INNER JOIN #SalesTaxReceivableTaxImpositionSubset taxImposition WITH(NOLOCK) ON salesTaxDetail.Id = taxImposition.SalesTaxReceivableTaxDetailId
		INNER JOIN ReceivableTypes rt WITH (NOLOCK) ON salesTax.R_ReceivableTypeId = rt.Id
		WHERE rt.IsRental = 0 AND salesTaxDetail.TaxBasisType != 'ST' AND taxImposition.TaxBasisType != 'ST'

		INSERT INTO #ErrorLogs
		SELECT 
		'Please provide UpfrontTaxMode for SalesTaxReceivableTax Id { '+ CONVERT(VARCHAR,salesTax.Id) +' }' 
		,salesTax.Id
		FROM #SalesTaxReceivableTaxSubset salesTax WITH (NOLOCK) 
		INNER JOIN #SalesTaxReceivableTaxDetailSubset salesTaxDetail ON salesTaxDetail.SalesTaxReceivableTaxId = salesTax.Id
		INNER JOIN ReceivableTypes rt WITH (NOLOCK) ON salesTax.R_ReceivableTypeId = rt.Id
		WHERE salesTaxDetail.TaxBasisType IN ('UC', 'UR' ) AND salesTaxDetail.UpfrontTaxMode IS NULL

		INSERT INTO #ErrorLogs
		SELECT 'CustomerPartyNumber ' + salesTax.CustomerPartyNumber + ' is not associated with SequenceNumber ' + salesTax.SequenceNumber + ' SalesTaxReceivableTax Id { '+ CONVERT(VARCHAR,salesTax.Id) +' }'
			 , salesTax.Id
		FROM #SalesTaxReceivableTaxSubset salesTax WITH(NOLOCK)
		INNER JOIN Receivables r ON salesTax.R_ReceivableId = r.Id
		WHERE salesTax.R_PartyId IS NOT NULL AND salesTax.R_PartyId != r.CustomerId

		UPDATE salesTaxDetail SET R_AssetLocationId = al.Id, R_AssetLocation_LocationId = al.LocationId
		FROM 
			#SalesTaxReceivableTaxDetailSubset salesTaxDetail WITH(NOLOCK)
			INNER JOIN Locations l WITH(NOLOCK) ON l.Code = salesTaxDetail.AssetLocationCode
			INNER JOIN Assets a WITH (NOLOCK) ON a.Alias = salesTaxDetail.AssetAlias
			INNER JOIN AssetLocations al WITH(NOLOCK) ON al.AssetId = a.Id
											AND al.LocationId = l.Id
		WHERE salesTaxDetail.EntityType IN ('CT', 'CU') AND salesTaxDetail.AssetLocationCode IS NOT NULL
			  AND al.IsActive = 1 AND al.IsCurrent =1

		INSERT INTO #ErrorLogs
		SELECT 'AssetLocation {'+ISNULL(salesTaxDetail.AssetLocationCode,'NULL')+'} is not associated to the asset {' + ISNULL(salesTaxDetail.AssetAlias,'NULL') + '} for SalesTaxReceivableTaxDetail Id { '+ CONVERT(VARCHAR,salesTaxDetail.Id) +' }'
			 , salesTaxDetail.SalesTaxReceivableTaxId
		FROM #SalesTaxReceivableTaxDetailSubset salesTaxDetail WITH(NOLOCK) 
		WHERE salesTaxDetail.R_AssetLocationId IS NULL AND salesTaxDetail.AssetLocationCode IS NOT NULL;
		  
		UPDATE #SalesTaxReceivableTaxSubset SET R_PartyId = CustomerId
		FROM #SalesTaxReceivableTaxSubset salesTax WITH(NOLOCK) 
			INNER JOIN LeaseFinances lf WITH (NOLOCK) ON salesTax.R_ContractId = lf.ContractId
		WHERE salesTax.R_PartyId IS NULL

		UPDATE #SalesTaxReceivableTaxSubset SET R_PartyId = CustomerId
		FROM #SalesTaxReceivableTaxSubset salesTax WITH(NOLOCK) 
			INNER JOIN LoanFinances lf WITH (NOLOCK) ON salesTax.R_ContractId = lf.ContractId
		WHERE salesTax.R_PartyId IS NULL

		INSERT INTO #ErrorLogs
		SELECT 'Location {'+ISNULL(salesTaxDetail.LocationCode,'NULL')+'} is associated with different Customer for SalesTaxReceivableTaxDetail Id { '+ CONVERT(VARCHAR,salesTaxDetail.Id) +' }'
			 , salesTaxDetail.SalesTaxReceivableTaxId
		FROM #SalesTaxReceivableTaxSubset salesTax WITH(NOLOCK)
		INNER JOIN #SalesTaxReceivableTaxDetailSubset salesTaxDetail ON salesTaxDetail.SalesTaxReceivableTaxId = salesTax.Id
		INNER JOIN Locations l WITH(NOLOCK) ON l.Id = salesTaxDetail.R_LocationId
		WHERE l.CustomerId IS NOT NULL 
			AND salesTax.R_PartyId IS NOT NULL
			AND salesTax.R_PartyId != l.CustomerId

		UPDATE taxImposition SET R_TaxTypeId = tt.Id
		FROM 
			#SalesTaxReceivableTaxImpositionSubset taxImposition WITH(NOLOCK)
			INNER JOIN TaxTypes tt ON tt.Name = taxImposition.TaxType
		WHERE taxImposition.TaxType IS NOT NULL
			  AND tt.IsActive = 1

		INSERT INTO #ErrorLogs
		SELECT 'Invalid TaxType {'+ISNULL(taxImposition.TaxType,'NULL')+'} for SalesTaxReceivableTaxImposition Id { '+ CONVERT(VARCHAR,taxImposition.Id) +' }'
			 , salesTaxDetail.SalesTaxReceivableTaxId
		FROM #SalesTaxReceivableTaxDetailSubset salesTaxDetail WITH(NOLOCK) 
			 INNER JOIN #SalesTaxReceivableTaxImpositionSubset taxImposition WITH(NOLOCK) ON salesTaxDetail.Id = taxImposition.SalesTaxReceivableTaxDetailId
		WHERE taxImposition.R_TaxTypeId IS NULL AND taxImposition.TaxType IS NOT NULL;

		UPDATE taxImposition SET R_ExternalJurisdictionLevelId = tac.Id
		FROM 
			#SalesTaxReceivableTaxImpositionSubset taxImposition WITH(NOLOCK)
			INNER JOIN TaxAuthorityConfigs tac ON tac.Description = taxImposition.ExternalJurisdictionLevel
		WHERE taxImposition.ExternalJurisdictionLevel IS NOT NULL
 
		INSERT INTO #ErrorLogs
		SELECT 'Invalid ExternalJurisdictionLevel {'+ISNULL(taxImposition.ExternalJurisdictionLevel,'NULL')+'} for SalesTaxReceivableTaxImposition Id { '+ CONVERT(VARCHAR,taxImposition.Id) +' }'
			 , salesTaxDetail.SalesTaxReceivableTaxId
		FROM #SalesTaxReceivableTaxDetailSubset salesTaxDetail WITH(NOLOCK) 
			 INNER JOIN #SalesTaxReceivableTaxImpositionSubset taxImposition WITH(NOLOCK) ON salesTaxDetail.Id = taxImposition.SalesTaxReceivableTaxDetailId
		WHERE taxImposition.R_ExternalJurisdictionLevelId IS NULL AND taxImposition.ExternalJurisdictionLevel IS NOT NULL;

		INSERT INTO #ErrorLogs
        SELECT 'Please provide either AppliedTaxRate or TaxAmount for SalesTaxReceivableTaxImposition Id { '+ CONVERT(VARCHAR,taxImposition.Id) +' }'
             , salesTaxDetail.SalesTaxReceivableTaxId
        FROM #SalesTaxReceivableTaxDetailSubset salesTaxDetail WITH(NOLOCK) 
             INNER JOIN #SalesTaxReceivableTaxImpositionSubset taxImposition WITH(NOLOCK) ON salesTaxDetail.Id = taxImposition.SalesTaxReceivableTaxDetailId
        WHERE taxImposition.AppliedTaxRate != 0.00 AND taxImposition.TaxAmount_Amount != 0.00;

        INSERT INTO #ErrorLogs
        SELECT 'AppliedTaxRate cannot be greater than 1 for SalesTaxReceivableTaxImposition Id { '+ CONVERT(VARCHAR,taxImposition.Id) +' }'
             , salesTaxDetail.SalesTaxReceivableTaxId
        FROM #SalesTaxReceivableTaxDetailSubset salesTaxDetail WITH(NOLOCK)
             INNER JOIN #SalesTaxReceivableTaxImpositionSubset taxImposition WITH(NOLOCK) ON salesTaxDetail.Id = taxImposition.SalesTaxReceivableTaxDetailId
        WHERE taxImposition.AppliedTaxRate > 1;

		UPDATE taxImposition SET TaxAmount_Amount = ROUND(taxImposition.AppliedTaxRate * taxImposition.TaxableBasisAmount_Amount, 2)
		FROM #SalesTaxReceivableTaxImpositionSubset taxImposition  WITH(NOLOCK)
		WHERE TaxAmount_Amount = 0.00 AND taxImposition.AppliedTaxRate != 0.00

		UPDATE taxImposition SET AppliedTaxRate = ROUND(taxImposition.TaxAmount_Amount / taxImposition.TaxableBasisAmount_Amount, 2)
		FROM #SalesTaxReceivableTaxImpositionSubset taxImposition  WITH(NOLOCK)
		WHERE TaxAmount_Amount != 0.00 AND taxImposition.AppliedTaxRate = 0.00  AND taxImposition.TaxableBasisAmount_Amount != 0.00

		INSERT INTO #ErrorLogs
		SELECT 'Sum of Tax Imposition Amount does not match Tax Amount in SalesTaxReceivableTax for SalesTaxReceivableTax Id { '+ CONVERT(VARCHAR,salesTax.Id) +' }'
			 , salesTax.Id
		FROM #SalesTaxReceivableTaxSubset salesTax WITH(NOLOCK)
			 LEFT JOIN (SELECT salesTaxDetail.SalesTaxReceivableTaxId, SUM(TaxAmount_Amount) AS TaxAmount
						 FROM #SalesTaxReceivableTaxDetailSubset salesTaxDetail WITH(NOLOCK)
							  INNER JOIN #SalesTaxReceivableTaxImpositionSubset taxImposition  WITH(NOLOCK) ON salesTaxDetail.Id = taxImposition.SalesTaxReceivableTaxDetailId
						 GROUP BY salesTaxDetail.SalesTaxReceivableTaxId)AS t ON salesTax.Id = t.SalesTaxReceivableTaxId
		WHERE t.TaxAmount != salesTax.TaxAmount_Amount OR t.TaxAmount IS NULL;


--========================================End Validations=====================================================

		

			CREATE TABLE #CreatedProcessingLogs
			([MergeAction] NVARCHAR(20), 
			 [InsertedId]  BIGINT, 
			 [SalesTaxId]  BIGINT
			);

			CREATE TABLE #CreatedSalesTax
			([Action]             NVARCHAR(10) NOT NULL, 
			 [Id]                 BIGINT NOT NULL, 
			 [ReceivableId]       BIGINT NOT NULL, 
			 [SalesTaxId]         BIGINT NOT NULL, 
			 [ProcessthroughDate] DATE NOT NULL, 
			 [SequenceNumber]     NVARCHAR(100) NULL
			);

			CREATE TABLE #CreatedSalesTaxDetail
			([Action]                        NVARCHAR(10) NOT NULL, 
			 [Id]                            BIGINT NOT NULL, 
			 [ReceivableDetailId]            BIGINT NOT NULL, 
			 [SalesTaxReceivableTaxDetailId] BIGINT NOT NULL
			);
			
			CREATE TABLE #CreatedSalesTaxImposition
			([Action]                            NVARCHAR(10) NOT NULL, 
			 [Id]                                BIGINT NOT NULL, 
			 [SalesTaxReceivableTaxDetailId]     BIGINT NOT NULL, 
			 [SalesTaxReceivableTaxImpositionId] BIGINT NOT NULL,
			 [Amount]							 DECIMAL(16, 2) NOT NULL
			);

			SELECT salesTax.Id AS Id
				 , salesTax.R_GLTemplateId AS GLTemplateId
				 , CurrencyCodes.ISO AS CurrencyCode
				 , r.Id AS ReceivableId
				 , r.PaymentScheduleId AS PaymentScheduleId
				 , r.EntityId as EntityId
				 , r.LegalEntityId as LegalEntityId  
				 , salesTax.DueDate
				 , salesTax.SequenceNumber
				 , salesTax.EntityType
				 , salesTax.TaxAmount_Amount AS Amount
				 , IIF((salesTax.R_ContractId IS NOT NULL AND c.SalesTaxRemittanceMethod = 'CashBased'), 1, 0) as IsCashBased
			INTO #Receivables
			FROM #SalesTaxReceivableTaxSubset salesTax WITH(NOLOCK) 
				 LEFT JOIN Contracts c WITH(NOLOCK) ON salesTax.R_ContractId = c.Id
				 INNER JOIN Receivables r WITH(NOLOCK) ON r.Id = salesTax.R_ReceivableId
				 INNER JOIN Currencies WITH(NOLOCK) ON r.TotalAmount_Currency = Currencies.Name
													   AND Currencies.IsActive = 1
				 INNER JOIN CurrencyCodes WITH(NOLOCK) ON Currencies.CurrencyCodeId = CurrencyCodes.Id
														  AND CurrencyCodes.IsActive = 1
			WHERE NOT EXISTS(SELECT [EntityId] FROM #ErrorLogs WITH(NOLOCK) WHERE #ErrorLogs.[EntityId] = salesTax.Id);

			UPDATE #Receivables SET IsCashBased = 1
			FROM #Receivables 
			INNER JOIN LegalEntities WITH(NOLOCK) ON #Receivables.LegalEntityId = LegalEntities.Id
			WHERE LegalEntities.TaxRemittancePreference = 'CashBased'

			MERGE ReceivableTaxes AS ReceivableTax
			USING(SELECT * FROM #Receivables) AS ReceivablesToMigrate
			ON(0 = 1)
				WHEN NOT MATCHED
				THEN
				  INSERT([IsActive]
					   , [IsGLPosted]
					   , [Amount_Amount]
					   , [Amount_Currency]
					   , [Balance_Amount]
					   , [Balance_Currency]
					   , [EffectiveBalance_Amount]
					   , [EffectiveBalance_Currency]
					   , [IsDummy]
					   , [CreatedById]
					   , [CreatedTime]
					   , [UpdatedById]
					   , [UpdatedTime]
					   , [ReceivableId]
					   , [GLTemplateId]
					   , IsCashBased)
				  VALUES
					    (1
					   , 0
					   , Amount
					   , CurrencyCode
					   , Amount
					   , CurrencyCode
					   , Amount
					   , CurrencyCode
					   , 0
					   , @UserId
					   , @CreatedTime
					   , NULL
					   , NULL
					   , ReceivableId
					   , GLTemplateId
					   , IsCashBased)
			OUTPUT $action, Inserted.Id, ReceivablesToMigrate.ReceivableId, ReceivablesToMigrate.Id, ReceivablesToMigrate.DueDate, ReceivablesToMigrate.SequenceNumber
				   INTO #CreatedSalesTax;

			SELECT
				CreatedSalesTax.Id  AS ReceivableTaxId
				,CreatedSalesTax.ReceivableId AS ReceivableId
				,salesTaxDetail.*
			INTO #ReceivableTaxDetail
			FROM 
				#CreatedSalesTax CreatedSalesTax
				INNER JOIN #SalesTaxReceivableTaxDetailSubset salesTaxDetail WITH(NOLOCK) ON salesTaxDetail.SalesTaxReceivableTaxId = CreatedSalesTax.SalesTaxId

			MERGE ReceivableTaxDetails AS ReceivableTaxDetails
			USING (SELECT * FROM #ReceivableTaxDetail)AS ReceivablesToMigrate
			ON(1=0)
			WHEN NOT MATCHED THEN
			INSERT 
					([UpfrontTaxMode]
					,[TaxBasisType]
					,[Revenue_Amount]
					,[Revenue_Currency]
					,[FairMarketValue_Amount]
					,[FairMarketValue_Currency]
					,[Cost_Amount]
					,[Cost_Currency]
					,[TaxAreaId]
					,[IsActive]
					,[ManuallyAssessed]
					,[IsGLPosted]
					,[Amount_Amount]
					,[Amount_Currency]
					,[Balance_Amount]
					,[Balance_Currency]
					,[EffectiveBalance_Amount]
					,[EffectiveBalance_Currency]
					,[CreatedById]
					,[CreatedTime]
					,[UpdatedById]
					,[UpdatedTime]
					,[AssetLocationId]
					,[LocationId]
					,[AssetId]
					,[ReceivableDetailId]
					,[ReceivableTaxId]
					,[UpfrontPayableFactor])
			VALUES
					(UpfrontTaxMode
					,TaxBasisType
					,Revenue_Amount
					,R_Amount_Currency
					,FairMarketValue_Amount
					,R_Amount_Currency
					,Cost_Amount
					,R_Amount_Currency
					,TaxAreaId
					,1
					,[ManuallyAssessed]
					,0
					,0.00
					,R_Amount_Currency
					,0.00
					,R_Amount_Currency
					,0.00
					,R_Amount_Currency
					,@UserId
					,@CreatedTime
					,NULL
					,NULL
					,R_AssetLocationId
					,R_LocationId
					,R_AssetId
					,R_ReceivableDetailId
					,ReceivableTaxId
					,UpfrontPayableFactor)
			OUTPUT $action, Inserted.Id, ReceivablesToMigrate.R_ReceivableDetailId as ReceivableDetailId,ReceivablesToMigrate.Id  INTO #CreatedSalesTaxDetail;

			MERGE [ReceivableTaxImpositions] AS [ReceivableTaxImpositions]
			USING (SELECT taxImposition.*, salesTaxDetail.Id AS InsertedId, salesTaxDetail.ReceivableDetailId  AS ReceivableDetailId
				   FROM #CreatedSalesTaxDetail salesTaxDetail
				   INNER JOIN #SalesTaxReceivableTaxImpositionSubset taxImposition WITH(NOLOCK) ON salesTaxDetail.SalesTaxReceivableTaxDetailId = taxImposition.SalesTaxReceivableTaxDetailId) AS impositionToMigrate
			ON (1 = 0)
			WHEN NOT MATCHED THEN
			INSERT
				([ExemptionType]
				,[ExemptionRate]
				,[ExemptionAmount_Amount]
				,[ExemptionAmount_Currency]
				,[TaxableBasisAmount_Amount]
				,[TaxableBasisAmount_Currency]
				,[AppliedTaxRate]
				,[Amount_Amount]
				,[Amount_Currency]
				,[Balance_Amount]
				,[Balance_Currency]
				,[EffectiveBalance_Amount]
				,[EffectiveBalance_Currency]
				,[ExternalTaxImpositionType]
				,[IsActive]
				,[CreatedById]
				,[CreatedTime]
				,[UpdatedById]
				,[UpdatedTime]
				,[TaxTypeId]
				,[ExternalJurisdictionLevelId]
				,[ReceivableTaxDetailId]
				,[TaxBasisType])
			VALUES
				(ExemptionType
				,ExemptionRate
				,ExemptionAmount_Amount
				,ExemptionAmount_Currency
				,TaxableBasisAmount_Amount
				,TaxableBasisAmount_Currency
				,[AppliedTaxRate]
				,TaxAmount_Amount
				,TaxAmount_Currency
				,TaxAmount_Amount
				,TaxAmount_Currency
				,TaxAmount_Amount
				,TaxAmount_Currency
				,ExternalTaxImpositionType
				,1
				,@UserId
				,@CreatedTime
				,NULL
				,NULL
				,R_TaxTypeId
				,R_ExternalJurisdictionLevelId
				,InsertedId
				,TaxBasisType)
		   OUTPUT $action, Inserted.Id, impositionToMigrate.SalesTaxReceivableTaxDetailId,impositionToMigrate.Id, impositionToMigrate.TaxAmount_Amount INTO #CreatedSalesTaxImposition;

			UPDATE ReceivableTaxDetails SET 
											Amount_Amount = t.Amount
										  , Balance_Amount = t.Amount
										  , EffectiveBalance_Amount = t.Amount
			FROM ReceivableTaxDetails rtd
				 INNER JOIN(SELECT taxDetail.Id ReceivableDetailId
								 , SUM(imposition.Amount) AS Amount
							FROM #CreatedSalesTaxDetail taxDetail
								 INNER JOIN #CreatedSalesTaxImposition imposition ON imposition.SalesTaxReceivableTaxDetailId = taxDetail.SalesTaxReceivableTaxDetailId
							GROUP BY taxDetail.Id) AS t ON rtd.Id = t.ReceivableDetailId;
			
			INSERT INTO [dbo].[ReceivableTaxReversalDetails]
			([Id]
			, [IsExemptAtAsset]
			, [IsExemptAtLease]
			, [IsExemptAtSundry]
			, [Company]
			, [Product]
			, [ContractType]
			, [AssetType]
			, [LeaseType]
			, [LeaseTerm]
			, [TitleTransferCode]
			, [TransactionCode]
			, [AmountBilledToDate]
			, [CreatedById]
			, [CreatedTime]
			, [AssetId]
			, [AssetLocationId]
			, [ToStateName]
			, [FromStateName]
			, [IsCapitalizeUpfrontSalesTax]
			, [UpfrontTaxAssessedInLegacySystem]
			)
			SELECT ReceivableTaxDetails.Id ReceivableTaxDetailId
				 , ISNULL(Assets.IsTaxExempt, 0) [IsExemptAtAsset]
				 , ISNULL(LeaseFinances.IsSalesTaxExempt, 0) [IsExemptAtLease]
				 , ISNULL(Sundries.IsTaxExempt, ISNULL(SundryRecurrings.IsTaxExempt, CONVERT(BIT, 0))) AS IsExemptAtSundry
				 , LegalEntities.TaxPayer [Company]
				 , CASE
					   WHEN(ReceivableTypes.IsRental = 1)
					   THEN AssetTypes.Name
					   ELSE ReceivableTypes.Name
				   END [Product]
				 , CASE
					   WHEN ReceivableTypes.IsRental = 1
					   THEN 'FMV'
					   ELSE ''
				   END AS ContractType
				 , AssetTypes.Name [AssetType]
				 , DealProductTypes.[LeaseType]
				 , CAST((DATEDIFF(day, LeaseFinanceDetails.CommencementDate, LeaseFinanceDetails.MaturityDate) + 1) AS DECIMAL(10, 2)) AS LeaseTerm
				 , TitleTransferCodes.TransferCode [TitleTransferCode]
				 , 'INV' [TransactionCode]
				 , 0.00 [AmountBilledToDate]
				 , @UserId
				 , @CreatedTime
				 , Assets.Id [AssetId]
				 , AssetLocations.Id [AssetLocationId]
				 , States.ShortName [ToStateName]
				 , NULL [FromStateName]
				 , ISNULL(LeaseFinanceDetails.CapitalizeUpfrontSalesTax, 0)
				 , ISNULL(AssetLocations.UpfrontTaxAssessedInLegacySystem, 0)
			FROM #Receivables
				 INNER JOIN #ReceivableTaxDetail ReceivableDetails ON #Receivables.ReceivableId = ReceivableDetails.ReceivableId
				 INNER JOIN LegalEntities ON #Receivables.LegalEntityId = LegalEntities.Id
				 INNER JOIN #CreatedSalesTax ReceivableTaxes ON ReceivableTaxes.ReceivableId = #Receivables.ReceivableId
				 INNER JOIN #CreatedSalesTaxDetail ReceivableTaxDetails ON ReceivableDetails.Id = ReceivableTaxDetails.SalesTaxReceivableTaxDetailId
				 INNER JOIN #SalesTaxReceivableTaxSubset salesTax ON ReceivableTaxes.SalesTaxId = salesTax.Id
				 INNER JOIN ReceivableTypes ON salesTax.R_ReceivableTypeId = ReceivableTypes.Id
				 LEFT JOIN Assets ON ReceivableDetails.R_AssetId = Assets.Id
				 LEFT JOIN TitleTransferCodes ON Assets.TitleTransferCodeId = TitleTransferCodes.Id
				 LEFT JOIN AssetTypes ON Assets.TypeId = AssetTypes.Id
				 LEFT JOIN AssetLocations AssetLocations ON AssetLocations.AssetId = Assets.Id
															AND AssetLocations.IsCurrent = 1
				 LEFT JOIN Locations Locations ON Locations.Id = AssetLocations.LocationId
				 LEFT JOIN States ON Locations.StateId = States.Id
				 LEFT JOIN Contracts ON #Receivables.EntityId = Contracts.Id
										AND #Receivables.EntityType = 'CT'
				 LEFT JOIN LeaseFinances ON LeaseFinances.ContractId = Contracts.Id AND #Receivables.EntityType = 'CT' 
											AND LeaseFinances.IsCurrent = 1
				 LEFT JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
				 LEFT JOIN Sundries ON #Receivables.ReceivableId = Sundries.ReceivableId
									   AND Sundries.IsActive = 1
				 LEFT JOIN SundryRecurringPaymentSchedules ON #Receivables.ReceivableId = SundryRecurringPaymentSchedules.ReceivableId
				 LEFT JOIN DealProductTypes ON Contracts.DealProductTypeId = DealProductTypes.Id
				 LEFT JOIN SundryRecurrings ON SundryRecurrings.Id = SundryRecurringPaymentSchedules.SundryRecurringId
											   AND SundryRecurrings.IsActive = 1;

			UPDATE ReceivableDetails SET IsTaxAssessed = 1
			FROM ReceivableDetails
			JOIN #Receivables ReceivableIds ON ReceivableIds.ReceivableId = ReceivableDetails.ReceivableId;
			
			SELECT ROW_NUMBER() OVER(PARTITION BY Receivables.EntityId, ReceivableDetails.R_AssetId ORDER BY Receivables.DueDate, LeasePaymentSchedules.Id) RowNumber
				 , ReceivableDetails.R_ReceivableDetailId [ReceivableDetailId]
				 , Receivables.EntityId
				 , CASE
					   WHEN LeasePaymentSchedules.PaymentType NOT IN('DownPayment')
					   THEN ReceivableDetails.R_Amount_Amount
					   ELSE 0.00
				   END [Amount_Amount]
				 , ReceivableDetails.R_Amount_Currency
				 , ReceivableDetails.R_AssetId
				 , LeasePaymentSchedules.PaymentType
				 , LeasePaymentSchedules.PaymentNumber
				 , Locations.StateId
			INTO #ReceivableDetails_Temp
			FROM #Receivables Receivables
				 INNER JOIN #ReceivableTaxDetail ReceivableDetails ON Receivables.ReceivableId = ReceivableDetails.ReceivableId
				 INNER JOIN Contracts ON Contracts.Id = Receivables.EntityId
				 INNER JOIN LeaseFinances ON LeaseFinances.ContractId = Contracts.Id
											 AND LeaseFinances.IsCurrent = 1
				 INNER JOIN LeasePaymentSchedules ON LeasePaymentSchedules.Id = Receivables.PaymentScheduleId
				 INNER JOIN #SalesTaxReceivableTaxDetailSubset salesTaxDetail ON salesTaxDetail.R_ReceivableDetailId = ReceivableDetails.R_ReceivableDetailId
				 INNER JOIN Locations ON Locations.Id = salesTaxDetail.R_AssetLocation_LocationId
				 INNER JOIN States ON States.Id = Locations.StateId
			WHERE States.IsMaxTaxApplicable = 1
			ORDER BY Receivables.EntityId
				   , Receivables.DueDate
				   , Receivables.PaymentScheduleId
				   , Receivables.Id
				   , ReceivableDetails.R_ReceivableDetailId;

			SELECT RD.Amount_Amount AS RevenueBilledToDate_Amount
				 , RD.R_Amount_Currency AS RevenueBilledToDate_Currency
				 , CASE
					   WHEN((RD.RowNumber = 1 AND RD.PaymentNumber = 1) OR (RD.PaymentType = 'DownPayment'))
					   THEN 0.00
					   ELSE ISNULL((SELECT SUM(CRD.Amount_Amount)
									FROM #ReceivableDetails_Temp CRD
									WHERE RD.R_AssetId = CRD.R_AssetId
											AND RD.StateId = CRD.StateId
											AND CRD.RowNumber < RD.RowNumber), 0.00)
				   END CumulativeAmount_Amount
				 , RD.R_Amount_Currency AS CumulativeAmount_Currency
				 , RD.EntityId AS ContractId
				 , RD.ReceivableDetailId
				 , RD.R_AssetId
				 , RD.StateId
			INTO #AmountBilledRentalReceivableDetail
			FROM #ReceivableDetails_Temp RD;

			INSERT INTO VertexBilledRentalReceivables
			(RevenueBilledToDate_Amount
			, RevenueBilledToDate_Currency
			, CumulativeAmount_Amount
			, CumulativeAmount_Currency
			, IsActive
			, CreatedById
			, CreatedTime
			, ContractId
			, ReceivableDetailId
			, AssetId
			, StateId
			)
			SELECT RevenueBilledToDate_Amount
				 , RevenueBilledToDate_Currency
				 , CumulativeAmount_Amount
				 , CumulativeAmount_Currency
				 , 1 AS [IsActive]
				 , 1 AS [CreatedById]
				 , SYSDATETIMEOFFSET() AS [CreatedTime]
				 , ContractId
				 , ReceivableDetailId
				 , R_AssetId
				 , StateId
			FROM #AmountBilledRentalReceivableDetail;
			
			MERGE stgProcessingLog AS ProcessingLog
			USING (SELECT DISTINCT SalesTaxId AS Id FROM #CreatedSalesTax) AS Processed
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
				'Successful'
				,'Information'
				,@UserId
				,@CreatedTime
				,InsertedId
			FROM
			#CreatedProcessingLogs CreatedProcessingLogs

			UPDATE salesTax SET IsMigrated = 1
			FROM stgSalesTaxReceivableTax salesTax WITH(NOLOCK) 
				 INNER JOIN #CreatedSalesTax WITH(NOLOCK) ON salesTax.Id = #CreatedSalesTax.SalesTaxId

	COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
	SET @SkipCount = @SkipCount+@TakeCount;
	DECLARE @ErrorMessage Nvarchar(max);
	DECLARE @ErrorLine Nvarchar(max);
	DECLARE @ErrorSeverity INT;
	DECLARE @ErrorState INT;
	DECLARE @ErrorLogs ErrorMessageList;
	DECLARE @ModuleName Nvarchar(max) = 'ReceivableTaxes'
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
	DROP TABLE IF EXISTS #CreatedProcessingLogs
	DROP TABLE IF EXISTS #Receivables
	DROP TABLE IF EXISTS #CreatedSalesTax
	DROP TABLE IF EXISTS #CreatedSalesTaxDetail
	DROP TABLE IF EXISTS #CreatedSalesTaxImposition
	DROP TABLE IF EXISTS #ReceivableTaxDetail
	DROP TABLE IF EXISTS #ReceivableDetails_Temp
	DROP TABLE IF EXISTS #AmountBilledRentalReceivableDetail
	DROP TABLE IF EXISTS #ReceivableTemp
	DROP TABLE IF EXISTS #MultipleReceivables
	DROP TABLE IF EXISTS #EligibleReceivableDetails
	DROP TABLE IF EXISTS #salesTaxDetail_CU_Count
	DROP TABLE IF EXISTS #ReceivableDetailsCount
	DROP TABLE IF EXISTS #salesTaxDetailCount
	DROP TABLE IF EXISTS #LeaseAssetCount
	DROP TABLE IF EXISTS #SundrySalesTax
END
SET @FailedRecords = @FailedRecords + ISNULL((SELECT COUNT(DISTINCT EntityId) FROM #ErrorLogs),0);
SET @ProcessedRecords = @ProcessedRecords + @TotalRecordsCount;
END
--========================================Log Errors==========================================================	
		MERGE stgProcessingLog As ProcessingLog
		USING (SELECT DISTINCT EntityId StagingRootEntityId FROM #ErrorLogs WITH (NOLOCK)) As ErrorsalesTax
		ON (ProcessingLog.StagingRootEntityId = ErrorsalesTax.StagingRootEntityId AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
		WHEN MATCHED Then
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
				ErrorsalesTax.StagingRootEntityId
				,@UserId
				,@CreatedTime
				,@ModuleIterationStatusId
			)
		OUTPUT Inserted.Id,ErrorsalesTax.StagingRootEntityId INTO #FailedProcessingLogs;	

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
			#ErrorLogs.Msg
			,'Error'
			,@UserId
			,@CreatedTime
			,#FailedProcessingLogs.Id
		FROM #ErrorLogs
		INNER JOIN #FailedProcessingLogs WITH (NOLOCK) ON #ErrorLogs.EntityId = #FailedProcessingLogs.SalesTaxId;	
	 	
--========================================End ErrorLogs==========================================================

DROP TABLE #ErrorLogs
DROP TABLE #FailedProcessingLogs
SET NOCOUNT OFF
SET XACT_ABORT OFF
SET ANSI_WARNINGS OFF
END

GO

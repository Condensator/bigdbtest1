SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[MigrateReceivableInvoice]
(@UserId                  BIGINT, 
 @ModuleIterationStatusId BIGINT, 
 @CreatedTime             DATETIMEOFFSET = NULL, 
 @ProcessedRecords        BIGINT OUT, 
 @FailedRecords           BIGINT OUT, 
 @ToolIdentifier          INT
)
AS
   BEGIN
		IF(@CreatedTime IS NULL)  
		SET @CreatedTime = SYSDATETIMEOFFSET();  

		SET XACT_ABORT ON;
		SET NOCOUNT ON;
		SET ANSI_WARNINGS ON;
		IF(@CreatedTime IS NULL)
			SET @CreatedTime = SYSDATETIMEOFFSET();

		SET @FailedRecords = 0;
		SET @ProcessedRecords = 0;

		DECLARE @TotalRecordsCount INT;
		DECLARE @BatchCount INT;
		DECLARE @MaxReceivableInvoiceId INT= 0;
		DECLARE @TakeCount INT= 100000;
		DECLARE @StorageSystem NVARCHAR(200);
		DECLARE @FilePath NVARCHAR(max);

		SELECT @TotalRecordsCount = ISNULL(COUNT(Id), 0) FROM stgReceivableInvoice WHERE IsMigrated = 0 AND (@ToolIdentifier = ToolIdentifier OR @ToolIdentifier IS NULL);

		SELECT TOP 1 @StorageSystem = detail.StorageSystem, @FilePath = detail.Path
		FROM FileStoreEntityConfigs entity
			 INNER JOIN FileStoreEntityDetailConfigs detail ON entity.Id = detail.FileStoreEntityConfigId
		WHERE entity.IsActive = 1
			  AND detail.IsActive = 1
			  AND entity.EntityName = 'ReceivableInvoice';
			   
		SET @ProcessedRecords = @TotalRecordsCount

		DECLARE @SkipCount INT = 0
		IF(@TotalRecordsCount > 0)
		BEGIN
			WHILE(@SkipCount < @TotalRecordsCount)
			BEGIN	
				BEGIN TRY
					BEGIN TRANSACTION

					CREATE TABLE #ErrorLogs
					(Id                  BIGINT NOT NULL IDENTITY PRIMARY KEY, 
					 Message             NVARCHAR(MAX),
					  StagingRootEntityId BIGINT
					);

					CREATE TABLE #FailedProcessingLogs
					([Id]         BIGINT NOT NULL, 
					 [ReceivableInvoiceId] BIGINT NOT NULL
					);

					SELECT TOP (@TakeCount) *
						 , NULL AS R_CustomerId
						 , NULL AS R_BillToId
						 , NULL AS R_RemitToId
						 , NULL AS R_LegalEntityId
						 , NULL AS R_CurrencyId
						 , NULL AS R_AlternateBillingCurrencyId
						 , CAST(NULL AS Nvarchar(100)) AS CustomerName
						 , CAST(NULL AS Nvarchar(100)) AS RemitToName
						 , CAST(0 AS BIT) SplitRentalInvoiceByAsset
						 , CAST(0 AS BIT) SplitCreditsByOriginalInvoice
						 , CAST(0 AS BIT) GenerateSummaryInvoice
						 , CAST(0 AS BIT) SplitByReceivableAdjustments
						 , CAST(0 AS BIT) SplitRentalInvoiceByContract
						 , CAST(0 AS BIT) SplitLeaseRentalInvoiceByLocation
						 , CAST(0 AS BIT) SplitReceivableDueDate
						 , CAST(0 AS BIT) SplitCustomerPurchaseOrderNumber
					INTO #ReceivableInvoiceSubset
					FROM stgReceivableInvoice WITH(NOLOCK)
					WHERE IsMigrated = 0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier) AND stgReceivableInvoice.Id > @MaxReceivableInvoiceId;

					CREATE NONCLUSTERED INDEX IX_ReceivableInvoiceId ON #ReceivableInvoiceSubset(Id);

					SELECT @BatchCount = COUNT(*) FROM #ReceivableInvoiceSubset;
					SET @SkipCount = @SkipCount + @TakeCount;
					SELECT @MaxReceivableInvoiceId = ISNULL(MAX(Id), 0) FROM #ReceivableInvoiceSubset

					SELECT stgReceivableInvoiceDetail.*
						 , NULL AS R_ReceivableTypeId
						 , NULL AS R_AssetId
						 , NULL AS R_ReceivableDetailId
						 , CAST(0.00 AS DECIMAL(16,2)) AS ReceivableAmount
						 , CAST(NULL AS Nvarchar(6)) AS ReceivableCurrency
						 , CAST(0.00 AS DECIMAL(16,2)) AS ReceivableTaxAmount 
					INTO #ReceivableInvoiceDetailSubset
					FROM #ReceivableInvoiceSubset WITH(NOLOCK)
					INNER JOIN stgReceivableInvoiceDetail WITH(NOLOCK) ON #ReceivableInvoiceSubset.Id = stgReceivableInvoiceDetail.ReceivableInvoiceId

					CREATE NONCLUSTERED INDEX IX_ReceivableInvoiceDetail ON #ReceivableInvoiceDetailSubset(Id);

					INSERT INTO #ErrorLogs
					SELECT 'Sum of receivable invoice detail amount does not match amount in Receivable Invoice for ReceivableInvoice Id { ' + CONVERT(VARCHAR, invoice.Id) + ' }'
						 , invoice.Id
					FROM #ReceivableInvoiceSubset invoice WITH(NOLOCK)
						  LEFT JOIN (SELECT ReceivableInvoiceId, SUM(InvoiceAmount_Amount) AS InvoiceAmount FROM #ReceivableInvoiceDetailSubset
									 GROUP BY ReceivableInvoiceId) AS t ON t.ReceivableInvoiceId = invoice.Id
						  WHERE invoice.InvoiceAmount_Amount != ISNULL(t.InvoiceAmount, 0.00)

					INSERT INTO #ErrorLogs
					SELECT 'Sum of receivable invoice detail tax amount does not match amount in Receivable Invoice for ReceivableInvoice Id { ' + CONVERT(VARCHAR, invoice.Id) + ' }'
						 , invoice.Id
					FROM #ReceivableInvoiceSubset invoice WITH(NOLOCK)
						  LEFT JOIN (SELECT ReceivableInvoiceId, SUM(InvoiceTaxAmount_Amount) AS InvoiceTaxAmount FROM #ReceivableInvoiceDetailSubset
									 GROUP BY ReceivableInvoiceId) AS t ON t.ReceivableInvoiceId = invoice.Id
						  WHERE invoice.InvoiceTaxAmount_Amount != ISNULL(t.InvoiceTaxAmount, 0.00)
						  
					UPDATE invoice SET R_CustomerId = c.Id, CustomerName = p.PartyName
					FROM #ReceivableInvoiceSubset invoice 
						 INNER JOIN Parties p ON p.PartyNumber =  invoice.CustomerNumber
						 INNER JOIN Customers c ON c.Id = p.Id
					WHERE c.Status != 'Inactive'

					INSERT INTO #ErrorLogs
					SELECT 'Invalid CustomerPartyNumber {' + ISNULL(invoice.CustomerNumber, 'NULL') + '} for ReceivableInvoice Id { ' + CONVERT(VARCHAR, invoice.Id) + ' }'
						 , invoice.Id
					FROM #ReceivableInvoiceSubset invoice WITH(NOLOCK)
					WHERE invoice.R_CustomerId IS NULL
						  AND invoice.CustomerNumber IS NOT NULL;

					UPDATE invoice SET 
									   R_BillToId = b.Id
									 , SplitRentalInvoiceByAsset = b.SplitRentalInvoiceByAsset
									 , SplitCreditsByOriginalInvoice = b.SplitCreditsByOriginalInvoice
									 , GenerateSummaryInvoice = b.GenerateSummaryInvoice
									 , SplitByReceivableAdjustments = b.SplitByReceivableAdjustments
									 , SplitRentalInvoiceByContract = b.SplitRentalInvoiceByContract
									 , SplitLeaseRentalInvoiceByLocation = b.SplitLeaseRentalInvoiceByLocation
									 , SplitReceivableDueDate = b.SplitReceivableDueDate
									 , SplitCustomerPurchaseOrderNumber = b.SplitCustomerPurchaseOrderNumber
					FROM #ReceivableInvoiceSubset invoice
						 INNER JOIN Billtoes b ON b.Name = invoice.BillToName
					WHERE b.CustomerId = invoice.R_CustomerId
						  AND b.IsActive = 1;

					INSERT INTO #ErrorLogs
					SELECT 'Invalid BillToName {' + ISNULL(invoice.BillToName, 'NULL') + '} for ReceivableInvoice Id { ' + CONVERT(VARCHAR, invoice.Id) + ' }'
						 , invoice.Id
					FROM #ReceivableInvoiceSubset invoice WITH(NOLOCK)
					WHERE invoice.R_BillToId IS NULL
						  AND invoice.BillToName IS NOT NULL;

					UPDATE invoice SET R_RemitToId = r.Id, RemitToName = r.[Name]
					FROM #ReceivableInvoiceSubset invoice
						 INNER JOIN RemitToes r ON r.[UniqueIdentifier] = invoice.RemitToUniqueIdentifier
					WHERE r.IsActive = 1

					INSERT INTO #ErrorLogs
					SELECT 'Invalid RemitToUniqueIdentifier {' + ISNULL(invoice.RemitToUniqueIdentifier, 'NULL') + '} for ReceivableInvoice Id { ' + CONVERT(VARCHAR, invoice.Id) + ' }'
						 , invoice.Id
					FROM #ReceivableInvoiceSubset invoice WITH(NOLOCK)
					WHERE invoice.R_RemitToId IS NULL
						  AND invoice.RemitToUniqueIdentifier IS NOT NULL;

					UPDATE invoice SET R_LegalEntityId = le.Id
					FROM #ReceivableInvoiceSubset invoice
						 INNER JOIN LegalEntities le ON le.LegalEntityNumber = invoice.LegalEntityNumber
					WHERE le.Status = 'Active'

					INSERT INTO #ErrorLogs
					SELECT 'Invalid LegalEntity {' + ISNULL(invoice.LegalEntityNumber, 'NULL') + '} for ReceivableInvoice Id { ' + CONVERT(VARCHAR, invoice.Id) + ' }'
						 , invoice.Id
					FROM #ReceivableInvoiceSubset invoice WITH(NOLOCK)
					WHERE invoice.R_LegalEntityId IS NULL
						  AND invoice.LegalEntityNumber IS NOT NULL;

					UPDATE invoice SET R_CurrencyId = c.Id, R_AlternateBillingCurrencyId = IIF(CurrencyISO = AlternateBillingCurrencyISO OR AlternateBillingCurrencyISO IS NULL, c.Id, NULL)
					FROM #ReceivableInvoiceSubset invoice 
						 INNER JOIN CurrencyCodes AS cc WITH (NOLOCK) ON cc.ISO = invoice.CurrencyISO  
						 INNER JOIN Currencies AS c WITH (NOLOCK) ON cc.Id = c.CurrencyCodeId
					WHERE c.IsActive = 1
						  AND cc.IsActive = 1
					
					INSERT INTO #ErrorLogs
					SELECT 'Invalid CurrencyISO {' + ISNULL(invoice.CurrencyISO, 'NULL') + '} for ReceivableInvoice Id { ' + CONVERT(VARCHAR, invoice.Id) + ' }'
						 , invoice.Id
					FROM #ReceivableInvoiceSubset invoice WITH(NOLOCK)
					WHERE invoice.R_CurrencyId IS NULL
						  AND invoice.CurrencyISO IS NOT NULL;

					UPDATE invoice SET R_AlternateBillingCurrencyId = c.Id
					FROM #ReceivableInvoiceSubset invoice 
						 INNER JOIN CurrencyCodes AS cc WITH (NOLOCK) ON cc.ISO = invoice.AlternateBillingCurrencyISO  
						 INNER JOIN Currencies AS c WITH (NOLOCK) ON cc.Id = c.CurrencyCodeId  
					WHERE invoice.AlternateBillingCurrencyISO IS NOT NULL
						  AND c.IsActive = 1
						  AND cc.IsActive = 1
						  AND R_AlternateBillingCurrencyId IS NULL

					INSERT INTO #ErrorLogs
					SELECT 'Invalid AlternateBillingCurrencyISO {' + ISNULL(invoice.AlternateBillingCurrencyISO, 'NULL') + '} for ReceivableInvoice Id { ' + CONVERT(VARCHAR, invoice.Id) + ' }'
						 , invoice.Id
					FROM #ReceivableInvoiceSubset invoice WITH(NOLOCK)
					WHERE invoice.R_AlternateBillingCurrencyId IS NULL
						  AND invoice.AlternateBillingCurrencyISO IS NOT NULL;
		
					UPDATE invoice SET 
									   R_ReceivableTypeId = rt.Id
					FROM #ReceivableInvoiceDetailSubset invoice WITH(NOLOCK)
						 INNER JOIN ReceivableTypes rt WITH(NOLOCK) ON invoice.ReceivableType = rt.Name
					WHERE rt.IsActive = 1;

					INSERT INTO #ErrorLogs
					SELECT 'Invalid Receivable Type {' + ISNULL(invoice.ReceivableType, 'NULL') + '} for Receivable Invoice Detail Id { ' + CONVERT(VARCHAR, invoice.Id) + ' }'
						 , invoice.ReceivableInvoiceId
					FROM #ReceivableInvoiceDetailSubset invoice WITH(NOLOCK)
					WHERE invoice.R_ReceivableTypeId IS NULL
						  AND invoice.ReceivableType IS NOT NULL;

					SELECT DISTINCT 
						   SequenceNumber
						 , EntityType
						 , ReceivableDueDate
						 , R_ReceivableTypeId
						 , ReceivableUniqueIdentifier
						 , 0  AS IsMultipleReceivables
						 , NULL AS R_ReceivableId
						 , ReceivableInvoiceId
						 , NULL AS R_ReceivableCategoryId  
						 , CAST('' AS Nvarchar(20)) AS ReceivableTaxType  
						 , NULL AS DealCountryId  
						 , NULL AS InvoiceFormatId
						 , CAST(0.00 AS DECIMAL(16,2)) AS ReceivableAmount  
					     , CAST(NULL AS Nvarchar(6)) AS ReceivableCurrency  
					     , CAST(0.00 AS DECIMAL(16,2)) AS ReceivableTaxAmount
						 , NULL AS R_EntityId
					INTO #ReceivableSubset
					FROM #ReceivableInvoiceDetailSubset;

					UPDATE receivable SET 
										  R_EntityId = c.Id
					FROM #ReceivableSubset receivable
						 INNER JOIN Contracts c ON c.SequenceNumber = receivable.SequenceNumber
					WHERE receivable.EntityType = 'CT';

					UPDATE receivable SET 
										  R_EntityId = d.Id
					FROM #ReceivableSubset receivable
						 INNER JOIN Discountings d ON d.SequenceNumber = receivable.SequenceNumber
					WHERE receivable.EntityType = 'DT';

					INSERT INTO #ErrorLogs
					SELECT DISTINCT 'Invalid Discounting SequenceNumber {' + ISNULL(receivable.SequenceNumber, 'NULL') + '} for Receivable Invoice Detail Id { ' + CONVERT(VARCHAR, invoice.Id) + ' }'
						 , receivable.ReceivableInvoiceId
					FROM #ReceivableSubset receivable WITH(NOLOCK)
					INNER JOIN #ReceivableInvoiceDetailSubset invoice WITH(NOLOCK) ON invoice.ReceivableInvoiceId = receivable.ReceivableInvoiceId
					WHERE receivable.R_EntityId IS NULL
						  AND receivable.SequenceNumber = invoice.SequenceNumber
						  AND receivable.EntityType = 'DT';

					 INSERT INTO #ErrorLogs
					 SELECT DISTINCT 'Invalid SequenceNumber {' + ISNULL(receivable.SequenceNumber, 'NULL') + '} for Receivable Invoice Detail Id { ' + CONVERT(VARCHAR, invoice.Id) + ' }'
						 , receivable.ReceivableInvoiceId
					FROM #ReceivableSubset receivable WITH(NOLOCK)
					INNER JOIN #ReceivableInvoiceDetailSubset invoice WITH(NOLOCK) ON invoice.ReceivableInvoiceId = receivable.ReceivableInvoiceId
					WHERE receivable.R_EntityId IS NULL
						  AND receivable.SequenceNumber = invoice.SequenceNumber
						  AND receivable.EntityType = 'CT';

					UPDATE receivable SET 
										  R_EntityId = R_CustomerId
					FROM #ReceivableSubset receivable
						 INNER JOIN #ReceivableInvoiceSubset ris ON ris.Id = receivable.ReceivableInvoiceId
					WHERE receivable.EntityType = 'CU';

					UPDATE invoice SET 
									   R_ReceivableId = r.Id
									 , R_ReceivableCategoryId = rc.ReceivableCategoryId
									 , ReceivableTaxType = r.ReceivableTaxType
									 , DealCountryId = r.DealCountryId
									 , ReceivableAmount = r.TotalAmount_Amount
									 , ReceivableCurrency = r.TotalAmount_Currency
					FROM #ReceivableSubset invoice WITH(NOLOCK)
						 INNER JOIN Receivables r WITH(NOLOCK) ON r.EntityId = invoice.R_EntityId
						 INNER JOIN ReceivableCodes rc WITH(NOLOCK) ON r.ReceivableCodeId = rc.Id
					WHERE invoice.EntityType = r.EntityType
						  AND invoice.ReceivableDueDate = r.DueDate
						  AND invoice.R_ReceivableTypeId = rc.ReceivableTypeId
						  AND (invoice.ReceivableUniqueIdentifier = r.UniqueIdentifier OR (ISNULL(invoice.ReceivableUniqueIdentifier, r.UniqueIdentifier) IS NULL))
						   

					INSERT INTO #ErrorLogs
					SELECT 'No receivable found as of ' + CONVERT(NVARCHAR(50), ReceivableDueDate) + ' for Receivable Invoice  Id { ' + CONVERT(NVARCHAR (50), receivable.ReceivableInvoiceId) + ' }'
						 , receivable.ReceivableInvoiceId
					FROM #ReceivableSubset receivable WITH(NOLOCK)
					WHERE receivable.R_ReceivableId IS NULL;

					INSERT INTO #ErrorLogs
					SELECT DISTINCT 'Customer Number does not match Receivable''s Customer Number for ' + CONVERT(NVARCHAR(50), invoice.CustomerNumber) + ' for Receivable Invoice Detail Id { ' + CONVERT(NVARCHAR (50), detail.Id) + ' }'
						 , receivable.ReceivableInvoiceId
					FROM #ReceivableSubset receivable WITH(NOLOCK)
						 INNER JOIN Receivables r ON r.Id = receivable.R_ReceivableId
						 INNER JOIN #ReceivableInvoiceSubset invoice ON invoice.Id = receivable.ReceivableInvoiceId
						 INNER JOIN #ReceivableInvoiceDetailSubset detail ON detail.ReceivableInvoiceId = invoice.Id
					WHERE receivable.R_ReceivableId IS NOT NULL
						  AND invoice.R_CustomerId != r.CustomerId;


					INSERT INTO #ErrorLogs
					SELECT 'RemitTo does not match Receivable''s RemitTo for {' + ISNULL(invoice.RemitToUniqueIdentifier,'NULL') + '} for Receivable Invoice  Id { ' + CONVERT(NVARCHAR(50), receivable.ReceivableInvoiceId) + ' }'
						 , receivable.ReceivableInvoiceId
					FROM #ReceivableSubset receivable WITH(NOLOCK)
						 INNER JOIN Receivables r ON r.Id = receivable.R_ReceivableId
						 INNER JOIN #ReceivableInvoiceSubset invoice ON invoice.Id = receivable.ReceivableInvoiceId
					WHERE receivable.R_ReceivableId IS NOT NULL
						  AND invoice.R_RemitToId != r.RemitToId;

					INSERT INTO #ErrorLogs
					SELECT 'Receivable is not tax assessed for {' +CONVERT(NVARCHAR(50), ReceivableDueDate) + '} for Receivable Invoice  Id { ' + CONVERT(NVARCHAR(50), receivable.ReceivableInvoiceId) + ' }'
						 , receivable.ReceivableInvoiceId
					FROM #ReceivableSubset receivable WITH(NOLOCK)
					WHERE receivable.R_ReceivableId IS NOT NULL
						  AND EXISTS (SELECT 1 FROM ReceivableDetails WHERE IsTaxAssessed = 0 AND ReceivableId = receivable.R_ReceivableId);


					INSERT INTO #ErrorLogs
					SELECT 'Receivable found is already invoiced for {' +CONVERT(NVARCHAR(50), ReceivableDueDate) + '} for Receivable Invoice  Id { ' + CONVERT(NVARCHAR(50), receivable.ReceivableInvoiceId) + ' }'
						 , receivable.ReceivableInvoiceId
					FROM #ReceivableSubset receivable WITH(NOLOCK)
					WHERE receivable.R_ReceivableId IS NOT NULL
						  AND EXISTS (SELECT 1 FROM ReceivableDetails WHERE BilledStatus = 'Invoiced' AND ReceivableId = receivable.R_ReceivableId);

					UPDATE invoice SET ReceivableTaxAmount = rt.Amount_Amount
					FROM #ReceivableSubset invoice WITH(NOLOCK)
						 INNER JOIN ReceivableTaxes rt ON rt.ReceivableId = invoice.R_ReceivableId
					WHERE rt.IsActive = 1;

					UPDATE invoice SET 
									   R_AssetId = a.Id
					FROM #ReceivableInvoiceDetailSubset invoice WITH(NOLOCK)
						 INNER JOIN Assets a WITH(NOLOCK) ON a.Alias = invoice.AssetAlias
					WHERE invoice.AssetAlias IS NOT NULL;

					INSERT INTO #ErrorLogs
					SELECT DISTINCT 'Invalid AssetAlias {' + ISNULL(invoice.AssetAlias, 'NULL') + '} for ReceivableInvoice Detail Id { ' + CONVERT(VARCHAR, invoice.Id) + ' }'
						 , ReceivableInvoiceId
					FROM #ReceivableInvoiceDetailSubset invoice WITH(NOLOCK)
					WHERE R_AssetId IS NULL
						  AND AssetAlias IS NOT NULL;

					UPDATE invoiceDetail SET InvoiceFormatId = bif.InvoiceFormatId
					FROM #ReceivableSubset invoiceDetail
						 INNER JOIN #ReceivableInvoiceSubset invoice ON invoiceDetail.ReceivableInvoiceId = invoice.Id
						 INNER JOIN ReceivableCategories rc ON rc.Id = invoiceDetail.R_ReceivableCategoryId
						 INNER JOIN BillToInvoiceFormats bif ON bif.BillToId = invoice.R_BillToId
																AND bif.ReceivableCategory = rc.Name

					INSERT INTO #ErrorLogs
					SELECT 'InvoiceFormatId cannot be null for BillToName {' + ISNULL(receivable.BillToName, 'NULL') +'} for ReceivableInvoice Id { ' + CONVERT(VARCHAR, ReceivableInvoiceId) + ' }'
						 , ReceivableInvoiceId
					FROM #ReceivableSubset invoice WITH(NOLOCK)
						  INNER JOIN #ReceivableInvoiceSubset receivable ON invoice.ReceivableInvoiceId = receivable.Id
					WHERE InvoiceFormatId IS NULL
						  AND BillToName IS NOT NULL;

					UPDATE invoice SET 
									   R_ReceivableDetailId = rd.Id
									 , ReceivableAmount = rd.Amount_Amount
									 , ReceivableCurrency = rd.Amount_Currency
					FROM #ReceivableInvoiceDetailSubset invoice WITH(NOLOCK)
						 INNER JOIN #ReceivableSubset receivable WITH(NOLOCK) ON receivable.ReceivableInvoiceId = invoice.ReceivableInvoiceId
						 INNER JOIN ReceivableDetails rd WITH(NOLOCK) ON rd.ReceivableId = receivable.R_ReceivableId
																				  AND (invoice.AssetAlias IS NULL OR rd.AssetId = invoice.R_AssetId)
					WHERE rd.BilledStatus = 'NotInvoiced'
						  AND rd.IsActive = 1

					SELECT invoice.Id
					INTO #SundrySalesTax
					FROM #ReceivableInvoiceDetailSubset invoice
						 INNER JOIN #ReceivableSubset receivable WITH(NOLOCK) ON receivable.ReceivableInvoiceId = invoice.ReceivableInvoiceId
						 INNER JOIN Receivables r WITH(NOLOCK) ON r.Id = receivable.R_ReceivableId
						 INNER JOIN Sundries s WITH(NOLOCK) ON s.Id = r.SourceId
					WHERE invoice.EntityType = 'CT'
						  AND r.SourceTable = 'Sundry'
						  AND s.IsAssetBased = 0;

					UPDATE invoice SET 
									   R_ReceivableDetailId = rd.Id
									 , ReceivableAmount = rd.Amount_Amount
									 , ReceivableCurrency = rd.Amount_Currency
					FROM #ReceivableInvoiceDetailSubset invoice WITH(NOLOCK)
						 INNER JOIN #ReceivableSubset receivable WITH(NOLOCK) ON receivable.ReceivableInvoiceId = invoice.ReceivableInvoiceId
						 INNER JOIN LeaseAssets la ON la.AssetId = invoice.R_AssetId
						 INNER JOIN LeaseFinances lf ON la.LeaseFinanceId = lf.Id
						 INNER JOIN Contracts c ON lf.ContractId = c.Id
												   AND receivable.R_EntityId = c.Id
						 INNER JOIN ReceivableDetails rd WITH(NOLOCK) ON rd.ReceivableId = receivable.R_ReceivableId
						 INNER JOIN #SundrySalesTax sundry WITH(NOLOCK) ON sundry.Id = invoice.Id
					WHERE R_AssetId IS NOT NULL
						  AND rd.AssetId IS NULL
						  AND invoice.EntityType = 'CT'
						  AND R_ReceivableDetailId IS NULL
						  AND rd.BilledStatus = 'NotInvoiced'
						  AND lf.IsCurrent = 1
						  AND rd.IsActive = 1;

					INSERT INTO #ErrorLogs
					SELECT DISTINCT 'No receivable detail found as of ' + CONVERT(NVARCHAR(50), ReceivableDueDate) + ' for Receivable Invoice Id { ' + CONVERT(VARCHAR, ReceivableInvoiceId) + ' }'
						 , ReceivableInvoiceId
					FROM #ReceivableInvoiceDetailSubset
					WHERE R_ReceivableDetailId IS NULL;
 
					INSERT INTO #ErrorLogs
					SELECT 'Receivable Invoice number must be unique, Number ' + CONVERT(NVARCHAR(50), invoice.Number) + ' already exists for Receivable Invoice Id { ' + CONVERT(VARCHAR, invoice.Id) + ' }'
						 , invoice.Id
					FROM #ReceivableInvoiceSubset invoice
					INNER JOIN ReceivableInvoices ri ON invoice.Number = ri.Number;

					UPDATE invoice SET 
									   ReceivableTaxAmount = t.Amount
					FROM #ReceivableInvoiceDetailSubset invoice
						 INNER JOIN
						(
							SELECT invoice.Id
								 , SUM(rtd.Amount_Amount) AS Amount
							FROM #ReceivableInvoiceDetailSubset invoice
								 INNER JOIN ReceivableTaxDetails rtd ON rtd.ReceivableDetailId = R_ReceivableDetailId
																		AND (invoice.AssetAlias IS NULL OR rtd.AssetId = invoice.R_AssetId)
							WHERE rtd.IsActive = 1
							GROUP BY invoice.Id
						) AS t ON t.Id = invoice.Id;
						 

						INSERT INTO #ErrorLogs
						SELECT 'Duplicate receivable invoice details were found for Receivable Invoice Id { ' + CONVERT(VARCHAR, invoice.Id) + ' }'
							 , invoice.Id
						FROM #ReceivableInvoiceSubset invoice
							 INNER JOIN
							(
								SELECT ReceivableInvoiceId
								FROM #ReceivableInvoiceDetailSubset
								WHERE R_ReceivableDetailId IS NOT NULL
								GROUP BY ReceivableInvoiceId
									   , R_ReceivableDetailId
								HAVING COUNT(*) > 1
							) AS t ON t.ReceivableInvoiceId = invoice.Id;
									

					INSERT INTO #ErrorLogs
					SELECT 'Invoice Tax Amount cannot be greater than receivable tax detail amount for Receivable Invoice Detail Id { ' + CONVERT(VARCHAR, invoice.Id) + ' }'
						  , invoice.ReceivableInvoiceId
					FROM #ReceivableInvoiceDetailSubset invoice
					WHERE InvoiceTaxAmount_Amount > ReceivableTaxAmount

					INSERT INTO #ErrorLogs
					SELECT 'Invoice Receivable Amount cannot be greater than receivable detail amount for Receivable Invoice Detail Id { ' + CONVERT(VARCHAR, invoice.Id) + ' }'
						  , invoice.ReceivableInvoiceId
					FROM #ReceivableInvoiceDetailSubset invoice
					WHERE InvoiceAmount_Amount > ReceivableAmount
					 
					SELECT invoice.ReceivableInvoiceId
						 , COUNT(rd.Id) NumberofReceivableDetails
					INTO #ReceivableDetailsCount
					FROM #ReceivableSubset invoice WITH(NOLOCK)
						 INNER JOIN ReceivableDetails rd WITH(NOLOCK) ON rd.ReceivableId = invoice.R_ReceivableId
					WHERE rd.IsActive = 1
						  AND rd.BilledStatus = 'NotInvoiced'
					GROUP BY invoice.ReceivableInvoiceId;

					SELECT ReceivableInvoiceId
						 , COUNT(Id) AS NumberofReceivableInvoiceDetail
					INTO #ReceivableInvoiceDetailCount
					FROM #ReceivableInvoiceDetailSubset
					GROUP BY ReceivableInvoiceId;

					INSERT INTO #ErrorLogs
					SELECT 'Number of ReceivableDetail is not matching with number of ReceivableInvoiceDetails for Receivable Invoice Id { ' + CONVERT(VARCHAR, invoice.Id) + ' }', invoice.Id
					FROM #ReceivableInvoiceSubset invoice
						 LEFT JOIN #ReceivableInvoiceDetailCount detail ON invoice.Id = detail.ReceivableInvoiceId
						 LEFT JOIN #ReceivableDetailsCount receivableDetailCount ON receivableDetailCount.ReceivableInvoiceId = invoice.Id
					WHERE ISNULL(detail.NumberofReceivableInvoiceDetail, 0) != ISNULL(receivableDetailCount.NumberofReceivableDetails, 0);
					

					CREATE TABLE #CreatedReceivableInvoice
					([Id]                  BIGINT NOT NULL, 
					 [ReceivableInvoiceId] BIGINT NOT NULL
					);
					
					CREATE TABLE #CreatedReceivableInvoiceDetailId([ReceivableDetailId] BIGINT NOT NULL);
					CREATE TABLE #CreatedProcessingLogs ([Id] bigint NOT NULL);

					MERGE ReceivableInvoices AS ReceivableInvoice
					USING
					(
						SELECT invoice.*, r.ReceivableAmount, r.ReceivableCurrency, r.R_ReceivableCategoryId, r.ReceivableTaxAmount, ISNULL(r.ReceivableTaxType, '') AS ReceivableTaxType, r.InvoiceFormatId, r.DealCountryId
						FROM #ReceivableInvoiceSubset invoice
							 INNER JOIN
							(
								SELECT ReceivableInvoiceId, SUM(ReceivableAmount) AS ReceivableAmount, MAX(ReceivableCurrency) AS ReceivableCurrency, MIN(R_ReceivableCategoryId) AS R_ReceivableCategoryId, SUM(ReceivableTaxAmount) AS ReceivableTaxAmount, MAX(ReceivableTaxType) AS ReceivableTaxType, MAX(InvoiceFormatId) AS InvoiceFormatId, MAX(DealCountryId) AS DealCountryId
								FROM #ReceivableSubset
								GROUP BY ReceivableInvoiceId
							) AS r ON r.ReceivableInvoiceId = invoice.Id
							LEFT JOIN #ErrorLogs el ON el.StagingRootEntityId = invoice.Id
						WHERE el.StagingRootEntityId IS NULL
					) AS ReceivablesToMigrate
					ON(0 = 1)
						WHEN NOT MATCHED
						THEN
						  INSERT(Number
							   , DueDate
							   , IsDummy
							   , IsNumberSystemCreated
							   , InvoiceAmount_Amount
							   , InvoiceAmount_Currency
							   , InvoiceTaxAmount_Amount
							   , InvoiceTaxAmount_Currency
							   , Balance_Amount
							   , Balance_Currency
							   , TaxBalance_Amount
							   , TaxBalance_Currency
							   , EffectiveBalance_Amount
							   , EffectiveBalance_Currency
							   , EffectiveTaxBalance_Amount
							   , EffectiveTaxBalance_Currency
							   , InvoiceRunDate
							   , IsActive
							   , IsInvoiceCleared
							   , SplitByContract
							   , SplitByLocation
							   , SplitByAsset
							   , SplitCreditsByOriginalInvoice
							   , SplitByReceivableAdj
							   , GenerateSummaryInvoice
							   , IsEmailSent
							   , IsPrivateLabel
							   , IsACH
							   , InvoiceFileName
							   , InvoicePreference
							   , OriginationSource
							   , OriginationSourceId
							   , CreatedById
							   , CreatedTime
							   , CustomerId
							   , BillToId
							   , RemitToId
							   , LegalEntityId
							   , ReceivableCategoryId
							   , ReportFormatId
							   , CurrencyId
							   , IsPdfGenerated
							   , AlternateBillingCurrencyId
							   , DaysLateCount
							   , IsStatementInvoice
							   , StatementInvoicePreference
							   , WithHoldingTaxAmount_Amount
							   , WithHoldingTaxAmount_Currency
							   , WithHoldingTaxBalance_Amount
							   , WithHoldingTaxBalance_Currency
							   , SplitReceivableDueDate
							   , SplitCustomerPurchaseOrderNumber
							   , CurrencyISO
							   , ReceivableAmount_Amount
							   , ReceivableAmount_Currency
							   , TaxAmount_Amount
							   , TaxAmount_Currency
							   , LegalEntityNumber
							   , CustomerNumber
							   , CustomerName
							   , RemitToName
							   , AlternateBillingCurrencyISO
							   , ReceivableTaxType
							   , DealCountryId)
						  VALUES
								(Number
								, DueDate
								, 0
								, 1
								, InvoiceAmount_Amount
								, InvoiceAmount_Currency
								, InvoiceTaxAmount_Amount
								, InvoiceTaxAmount_Currency
								, InvoiceAmount_Amount
								, InvoiceAmount_Currency
								, InvoiceTaxAmount_Amount
								, InvoiceTaxAmount_Currency
								, InvoiceAmount_Amount
								, InvoiceAmount_Currency
								, InvoiceTaxAmount_Amount
								, InvoiceTaxAmount_Currency
								, InvoiceRunDate
								, 1
								, 0
								, SplitRentalInvoiceByContract
								, SplitLeaseRentalInvoiceByLocation
								, SplitRentalInvoiceByAsset
								, SplitCreditsByOriginalInvoice
								, SplitByReceivableAdjustments
								, GenerateSummaryInvoice
								, IsEmailSent
								, 0
								, IsACH
								, ISNULL(InvoiceFileName, Number)
								, 'GenerateAndDeliver'
								, OriginationSource
								, OriginationSourceId
								, @UserId
								, @CreatedTime
								, R_CustomerId
								, R_BillToId
								, R_RemitToId
								, R_LegalEntityId
								, R_ReceivableCategoryId
								, InvoiceFormatId
								, R_CurrencyId
								, IsPdfGenerated
								, R_AlternateBillingCurrencyId
								, 0
								, 0
								, 'GenerateAndDeliver'
								, WithHoldingTaxAmount_Amount
								, WithHoldingTaxAmount_Currency
								, WithHoldingTaxAmount_Amount
								, WithHoldingTaxAmount_Currency
								, SplitReceivableDueDate
								, SplitCustomerPurchaseOrderNumber
								, CurrencyISO
								, ReceivableAmount
								, ReceivableCurrency
								, ReceivableTaxAmount
								, ReceivableCurrency
								, LegalEntityNumber
								, CustomerNumber
								, CustomerName
								, RemitToName
								, AlternateBillingCurrencyISO
								, ReceivableTaxType
								, DealCountryId)
					OUTPUT Inserted.Id, ReceivablesToMigrate.Id INTO #CreatedReceivableInvoice;
					
					INSERT INTO ReceivableInvoiceDetails
					(EntityType
					, EntityId
					, InvoiceAmount_Amount
					, InvoiceAmount_Currency
					, InvoiceTaxAmount_Amount
					, InvoiceTaxAmount_Currency
					, Balance_Amount
					, Balance_Currency
					, TaxBalance_Amount
					, TaxBalance_Currency
					, EffectiveBalance_Amount
					, EffectiveBalance_Currency
					, EffectiveTaxBalance_Amount
					, EffectiveTaxBalance_Currency
					, IsActive
					, CreatedById
					, CreatedTime
					, ReceivableDetailId
					, ReceivableInvoiceId
					, ExchangeRate
					, ReceivableCategoryId
					, ReceivableAmount_Amount
					, ReceivableAmount_Currency
					, TaxAmount_Amount
					, TaxAmount_Currency
					, ReceivableId
					, ReceivableTypeId
					, SequenceNumber
					, PaymentType
					, BlendNumber
					)
					OUTPUT Inserted.ReceivableDetailId INTO #CreatedReceivableInvoiceDetailId
					SELECT detail.EntityType
						 , rs.R_EntityId
						 , InvoiceAmount_Amount
						 , InvoiceAmount_Currency
						 , InvoiceTaxAmount_Amount
						 , InvoiceTaxAmount_Currency
						 , InvoiceAmount_Amount
						 , InvoiceAmount_Currency
						 , InvoiceTaxAmount_Amount
						 , InvoiceTaxAmount_Currency
						 , InvoiceAmount_Amount
						 , InvoiceAmount_Currency
						 , InvoiceTaxAmount_Amount
						 , InvoiceTaxAmount_Currency
						 , 1
						 , @UserId
						 , @CreatedTime
						 , R_ReceivableDetailId
						 , invoice.Id
						 , ExchangeRate
						 , R_ReceivableCategoryId
						 , detail.ReceivableAmount
						 , detail.ReceivableCurrency
						 , detail.ReceivableTaxAmount
						 , detail.ReceivableCurrency
						 , R_ReceivableId
						 , rs.R_ReceivableTypeId
						 , detail.SequenceNumber
						 , PaymentType
						 , 0
					FROM #ReceivableInvoiceDetailSubset detail
						 INNER JOIN #CreatedReceivableInvoice invoice ON detail.ReceivableInvoiceId = invoice.ReceivableInvoiceId
						 INNER JOIN #ReceivableSubset rs ON rs.ReceivableInvoiceId = invoice.ReceivableInvoiceId;
 
					UPDATE rd SET BilledStatus = 'Invoiced'
					FROM ReceivableDetails rd
					INNER JOIN #CreatedReceivableInvoiceDetailId invoice ON rd.Id = invoice.ReceivableDetailId

					UPDATE stgReceivableInvoice SET IsMigrated = 1
					WHERE Id IN (SELECT ReceivableInvoiceId FROM #CreatedReceivableInvoice)
				 
					MERGE INTO StgReceivableInvoiceFile AS [Target]
					USING (SELECT invoice.Number, invoice.InvoiceFileName 
					 FROM 
					#CreatedReceivableInvoice created
						 INNER JOIN #ReceivableInvoiceSubset invoice ON invoice.Id = created.ReceivableInvoiceId
					WHERE InvoiceFileName IS NOT NULL) AS staging
					ON ([Target].Number = staging.Number)
					WHEN NOT MATCHED THEN
					INSERT (Number, FileName, IsMigrated, ToolIdentifier, CreatedById, CreatedTime)
					VALUES (Number, InvoiceFileName, 0, @ToolIdentifier, @UserId, @CreatedTime);
 
					MERGE stgProcessingLog AS ProcessingLog
					USING
					(
						SELECT ReceivableInvoiceId
						FROM #CreatedReceivableInvoice
					) AS ProcessedReceivableInvoice
					ON(ProcessingLog.StagingRootEntityId = ProcessedReceivableInvoice.ReceivableInvoiceId
					   AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
					WHEN NOT MATCHED
					THEN
					INSERT
						(
							  StagingRootEntityId
							, CreatedById
							, CreatedTime
							, ModuleIterationStatusId
						)
					VALUES
						(
							  ProcessedReceivableInvoice.ReceivableInvoiceId
							, @UserId
							, @CreatedTime
							, @ModuleIterationStatusId
						)
					OUTPUT Inserted.Id INTO #CreatedProcessingLogs;

					INSERT INTO stgProcessingLogDetail
					(
						Message
					   ,Type
					   ,CreatedById
					   ,CreatedTime	
					   ,ProcessingLogId
					)
					SELECT
						'Successful'
					   ,'Information'
					   ,@UserId
					   ,@CreatedTime
					   ,Id
					FROM
						#CreatedProcessingLogs

					MERGE stgProcessingLog As ProcessingLog
					USING (SELECT DISTINCT StagingRootEntityId FROM #ErrorLogs WITH (NOLOCK)) As ErrorsalesTax
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
						#ErrorLogs.Message
						,'Error'
						,@UserId
						,@CreatedTime
						,#FailedProcessingLogs.Id
					FROM #ErrorLogs
					INNER JOIN #FailedProcessingLogs WITH (NOLOCK) ON #ErrorLogs.StagingRootEntityId = #FailedProcessingLogs.ReceivableInvoiceId;

					SET @FailedRecords = @FailedRecords+(SELECT COUNT(DISTINCT StagingRootEntityId) FROM #ErrorLogs)

					DROP TABLE #ErrorLogs
					DROP TABLE #FailedProcessingLogs
					DROP TABLE #ReceivableSubset
					DROP TABLE #CreatedReceivableInvoice
					DROP TABLE #ReceivableInvoiceDetailSubset
					DROP TABLE #CreatedReceivableInvoiceDetailId
					DROP TABLE #ReceivableInvoiceSubset
					DROP TABLE #SundrySalesTax
					DROP TABLE #CreatedProcessingLogs
					DROP TABLE #ReceivableInvoiceDetailCount
					DROP TABLE #ReceivableDetailsCount
					--DROP TABLE #MultipleReceivables

					COMMIT TRANSACTION
				END TRY
				BEGIN CATCH
					SET @SkipCount = @SkipCount+@TakeCount;
					DECLARE @ErrorMessage Nvarchar(max);
					DECLARE @ErrorLine Nvarchar(max);
					DECLARE @ErrorSeverity INT;
					DECLARE @ErrorState INT;
					DECLARE @ErrorLogs ErrorMessageList;
					DECLARE @ModuleName Nvarchar(max) = 'ReceivableInvoice'
					INSERT INTO @ErrorLogs(StagingRootEntityId, ModuleIterationStatusId, Message,Type) VALUES (0,@ModuleIterationStatusId,ERROR_MESSAGE(),'Error')
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
		END
END

GO

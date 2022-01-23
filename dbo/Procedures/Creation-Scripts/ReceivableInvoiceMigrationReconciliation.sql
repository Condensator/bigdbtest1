SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[ReceivableInvoiceMigrationReconciliation]
(
	@IsSummary BIT = NULL
)
AS
BEGIN
        DECLARE @NumberOfIntermediateRecords BIGINT = 0;
        DECLARE @IntermediateAmount DECIMAL(16, 2) = 0;
		DECLARE @IntermediateTaxAmount DECIMAL(16, 2) = 0;

        SELECT Number
             , InvoiceAmount_Amount
             , InvoiceTaxAmount_Amount
             , BillToName
             , CurrencyISO
             , AlternateBillingCurrencyISO
             , CustomerNumber
             , LegalEntityNumber
             , RemitToUniqueIdentifier
             , CancellationDate
             , InvoiceFileName
             , OriginationSource
             , OriginationSourceId
             , IsPdfGenerated
             , WithHoldingTaxAmount_Amount
             , InvoiceRunDate
             , IsEmailSent
             , IsACH
        INTO #StagingReceivableInvoice
        FROM stgReceivableInvoice
        WHERE IsMigrated = 1;

        SELECT @NumberOfIntermediateRecords = COUNT(*)
             , @IntermediateAmount = SUM(InvoiceAmount_Amount)
			 , @IntermediateTaxAmount = SUM(InvoiceTaxAmount_Amount)
        FROM #StagingReceivableInvoice;

        SELECT invoice.Number
             , invoice.InvoiceAmount_Amount
             , invoice.InvoiceTaxAmount_Amount
             , bt.Name AS BillToName
             , cc.ISO AS CurrencyISO
             , alternateCurrencyCode.ISO AS AlternateBillingCurrencyISO
             , p.PartyNumber AS CustomerNumber
             , le.LegalEntityNumber AS LegalEntityNumber
             , rt.[UniqueIdentifier] AS RemitToUniqueIdentifier
             , invoice.CancellationDate
             , invoice.InvoiceFileName
             , invoice.OriginationSource
             , invoice.OriginationSourceId
             , invoice.WithHoldingTaxAmount_Amount
             , invoice.InvoiceRunDate
             , invoice.IsEmailSent
             , invoice.IsACH
        INTO #TargetReceivableInvoice
        FROM ReceivableInvoices invoice
             INNER JOIN #StagingReceivableInvoice staging ON invoice.Number = staging.Number
             LEFT JOIN BillToes bt ON bt.Id = invoice.BillToId
             LEFT JOIN Currencies c ON c.Id = invoice.CurrencyId
             LEFT JOIN CurrencyCodes cc ON cc.Id = c.CurrencyCodeId
             LEFT JOIN Currencies alternateCurrency ON alternateCurrency.Id = invoice.AlternateBillingCurrencyId
             LEFT JOIN CurrencyCodes alternateCurrencyCode ON alternateCurrencyCode.Id = alternateCurrency.CurrencyCodeId
             LEFT JOIN Parties p ON p.Id = invoice.CustomerId
             LEFT JOIN LegalEntities le ON le.Id = invoice.LegalEntityId
             LEFT JOIN RemitToes rt ON rt.Id = invoice.RemitToId;

        SELECT CAST ('Failed' AS Nvarchar(25)) AS [Status]
			 , [target].Number AS Number_Target
			 , staging.Number AS Number_Intermediate
             , [target].InvoiceAmount_Amount AS InvoiceAmount_Amount_Target
             , staging.InvoiceAmount_Amount AS InvoiceAmount_Amount_Intermediate
             , ISNULL([target].InvoiceAmount_Amount, 0.00) - staging.InvoiceAmount_Amount AS InvoiceAmount_Amount_Difference
             , [target].InvoiceTaxAmount_Amount AS InvoiceTaxAmount_Amount_Target
             , staging.InvoiceTaxAmount_Amount AS InvoiceTaxAmount_Amount_Intermediate
             , ISNULL([target].InvoiceTaxAmount_Amount, 0.00) - staging.InvoiceTaxAmount_Amount AS InvoiceTaxAmount_Amount_Difference
             , [target].BillToName AS BillToName_Target
             , staging.BillToName AS BillToName_Intermediate
             , [target].CurrencyISO AS CurrencyISO_Target
             , staging.CurrencyISO AS CurrencyISO_Intermediate
             , [target].AlternateBillingCurrencyISO AS AlternateBillingCurrencyISO_Target
             , staging.AlternateBillingCurrencyISO AS AlternateBillingCurrencyISO_Intermediate
             , [target].CustomerNumber AS CustomerNumber_Target
             , staging.CustomerNumber AS CustomerNumber_Intermediate
             , [target].LegalEntityNumber AS LegalEntityNumber_Target
             , staging.LegalEntityNumber AS LegalEntityNumber_Intermediate
             , [target].RemitToUniqueIdentifier AS RemitToUniqueIdentifier_Target
             , staging.RemitToUniqueIdentifier AS RemitToUniqueIdentifier_Intermediate
             , CAST([target].CancellationDate AS nvarchar(20)) AS CancellationDate_Target
             , CAST(staging.CancellationDate AS nvarchar(20)) AS CancellationDate_Intermediate
             , [target].InvoiceFileName AS InvoiceFileName_Target
             , staging.InvoiceFileName AS InvoiceFileName_Intermediate
             , [target].OriginationSource AS OriginationSource_Target
             , staging.OriginationSource AS OriginationSource_Intermediate
             , [target].OriginationSourceId AS OriginationSourceId_Target
             , staging.OriginationSourceId AS OriginationSourceId_Intermediate
             , [target].WithHoldingTaxAmount_Amount AS WithHoldingTaxAmount_Amount_Target
             , staging.WithHoldingTaxAmount_Amount AS WithHoldingTaxAmount_Amount_Intermediate
             , ISNULL([target].WithHoldingTaxAmount_Amount, 0.00) - staging.WithHoldingTaxAmount_Amount AS WithHoldingTaxAmount_Amount_Difference
             , CAST([target].InvoiceRunDate AS nvarchar(20)) AS InvoiceRunDate_Target
             , CAST(staging.InvoiceRunDate AS nvarchar(20)) AS InvoiceRunDate_Intermediate
             , [target].IsEmailSent AS IsEmailSent_Target
             , staging.IsEmailSent AS IsEmailSent_Intermediate
             , [target].IsACH AS IsACH_Target
             , staging.IsACH AS IsACH_Intermediate
        INTO #FailedRecords
        FROM #StagingReceivableInvoice staging
             LEFT JOIN #TargetReceivableInvoice [target] ON staging.Number = [target].Number
        WHERE [target].Number IS NULL
              OR ISNULL([target].InvoiceAmount_Amount, 0.00) - staging.InvoiceAmount_Amount != 0.00
              OR ISNULL([target].InvoiceTaxAmount_Amount, 0.00) - staging.InvoiceTaxAmount_Amount != 0.00
              OR ISNULL([target].BillToName, '') != staging.BillToName
              OR ISNULL([target].CurrencyISO, '') != staging.CurrencyISO
              OR ISNULL([target].AlternateBillingCurrencyISO, '') != ISNULL(staging.AlternateBillingCurrencyISO, '')  
              OR ISNULL([target].CustomerNumber, '') != staging.CustomerNumber
              OR ISNULL([target].LegalEntityNumber, '') != staging.LegalEntityNumber
              OR ISNULL([target].RemitToUniqueIdentifier, '') != staging.RemitToUniqueIdentifier
              OR ISNULL([target].WithHoldingTaxAmount_Amount, 0.00) - staging.WithHoldingTaxAmount_Amount != 0.00
              OR ISNULL([target].IsEmailSent, '') != staging.IsEmailSent
              OR ISNULL([target].IsACH, '') != staging.IsACH
              OR ISNULL([target].CancellationDate, '') != ISNULL(staging.CancellationDate, '')
              OR ISNULL([target].OriginationSource, '') != ISNULL(staging.OriginationSource, '')  
              OR [target].InvoiceFileName != IIF(staging.InvoiceFileName IS NOT NULL, staging.InvoiceFileName, staging.Number)
              OR ISNULL([target].InvoiceRunDate, '') != ISNULL(staging.InvoiceRunDate, '')

		UPDATE #FailedRecords SET Status = 'Unable to Reconcile'
		WHERE Number_Target IS NULL

        IF(@IsSummary = 1)
        BEGIN

                CREATE TABLE #Report
                (Intermediate_TotalNumberofRecords BIGINT, 
                 Intermediate_InvoiceAmount        DECIMAL(16, 2),
				 Intermediate_InvoiceTaxAmount	   DECIMAL(16, 2),
                 [Status]                          NVARCHAR(20), 
                 Target_TotalNumberofRecords       BIGINT, 
                 Target_InvoiceAmount              DECIMAL(16, 2),
				 Target_InvoiceTaxAmount		   DECIMAL(16, 2)
                );

                INSERT INTO #Report
                (Intermediate_TotalNumberofRecords
               , Intermediate_InvoiceAmount
			   , Intermediate_InvoiceTaxAmount
               , [Status]
               , Target_TotalNumberofRecords
               , Target_InvoiceAmount
			   , Target_InvoiceTaxAmount
                )
                SELECT @NumberOfIntermediateRecords
                     , @IntermediateAmount
					 , @IntermediateTaxAmount
					 , 'Success'
                     , COUNT([target].Number)
                     , SUM([target].InvoiceAmount_Amount)
					 , SUM([target].InvoiceTaxAmount_Amount)
                FROM #TargetReceivableInvoice [target]
                WHERE NOT EXISTS
                (
                    SELECT 1
                    FROM #FailedRecords failed
                    WHERE failed.Number_Intermediate = [target].Number
                );

                INSERT INTO #Report
                ([Status]
               , Target_TotalNumberofRecords
               , Target_InvoiceAmount
                )
                SELECT 'Failed'
                     , COUNT(failed.Number_Target)
                     , SUM(ISNULL(failed.InvoiceAmount_Amount_Target, 0.00))
                FROM #FailedRecords failed
                WHERE failed.Number_Target IS NOT NULL;

                INSERT INTO #Report
                ([Status]
               , Target_TotalNumberofRecords
               , Target_InvoiceAmount
                )
                SELECT 'Unable to Reconcile'
                     , COUNT(*)
                     , SUM(ISNULL(failed.InvoiceAmount_Amount_Target, 0.00))
                FROM #FailedRecords failed
                WHERE failed.Number_Target IS NULL;

                SELECT *
                FROM #Report;
        END;
        ELSE
        BEGIN
            SELECT *
            FROM #FailedRecords;
		END;

        DROP TABLE IF EXISTS #Report;
        DROP TABLE IF EXISTS #StagingReceivableInvoice;
        DROP TABLE IF EXISTS #TargetReceivableInvoice;
		DROP TABLE IF EXISTS #FailedRecords;
END;

GO

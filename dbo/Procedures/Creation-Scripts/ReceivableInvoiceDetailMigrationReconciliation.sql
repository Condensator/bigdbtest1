SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[ReceivableInvoiceDetailMigrationReconciliation]
(
	@IsSummary BIT = NULL
)
AS 
BEGIN
        DECLARE @NumberOfIntermediateRecords BIGINT = 0;
        DECLARE @IntermediateAmount DECIMAL(16, 2) = 0;
		DECLARE @IntermediateTaxAmount DECIMAL(16, 2) = 0;

        SELECT Number
             , Id
        INTO #StagingReceivableInvoice
        FROM stgReceivableInvoice invoice
        WHERE IsMigrated = 1;

        SELECT invoice.Number
             , rid.AssetAlias
             , rid.EntityType
             , rid.ReceivableUniqueIdentifier
             , rid.InvoiceAmount_Amount
             , rid.InvoiceTaxAmount_Amount
             , rid.SequenceNumber
             , rid.ReceivableType
             , rid.ReceivableDueDate
             , rid.PaymentType
			 , rid.Id AS StagingReceivableInvoiceDetailId
        INTO #StagingReceivableInvoiceDetail
        FROM stgReceivableInvoice invoice
             INNER JOIN stgReceivableInvoiceDetail rid ON invoice.Id = rid.ReceivableInvoiceId;
		
		SELECT @NumberOfIntermediateRecords = COUNT(*)
             , @IntermediateAmount = SUM(InvoiceAmount_Amount)
			 , @IntermediateTaxAmount = SUM(InvoiceTaxAmount_Amount)
        FROM #StagingReceivableInvoiceDetail;

        SELECT ri.Id
             , invoice.Number
        INTO #TargetReceivableInvoice
        FROM #StagingReceivableInvoice invoice
             LEFT JOIN ReceivableInvoices ri ON ri.Number = invoice.Number;

        SELECT a.Alias AS AssetAlias
             , invoice.Number
             , rid.InvoiceAmount_Amount
             , rid.InvoiceTaxAmount_Amount
             , rt.Name AS ReceivableType
             , r.DueDate AS ReceivableDueDate
             , CASE
                   WHEN r.EntityType = 'CT'
                   THEN c.SequenceNumber
                   WHEN r.EntityType = 'DT'
                   THEN d.SequenceNumber
               END AS SequenceNumber
             , p.PartyNumber
             , r.EntityType
             , rid.PaymentType
             , r.UniqueIdentifier AS ReceivableUniqueIdentifier
			 , rid.Id AS TargetReceivableInvoiceDetailId
        INTO #targetReceivableInvoiceDetail
        FROM #TargetReceivableInvoice invoice
             INNER JOIN ReceivableInvoiceDetails rid ON rid.ReceivableInvoiceId = invoice.Id
             INNER JOIN ReceivableDetails rd ON rd.Id = rid.ReceivableDetailId
             LEFT JOIN Assets a ON a.Id = rd.AssetId
             LEFT JOIN ReceivableTypes rt ON rt.Id = rid.ReceivableTypeId
             LEFT JOIN Receivables r ON rid.ReceivableId = r.Id
             LEFT JOIN Contracts c ON c.Id = r.EntityId
                                      AND r.EntityType = 'CT'
             LEFT JOIN Parties p ON p.Id = r.CustomerId
             LEFT JOIN Discountings d ON d.Id = r.EntityId
                                         AND r.EntityType = 'DT';

        SELECT CAST ('Failed' AS Nvarchar(25)) AS [Status]
			 , targetInvoiceDetail.Number AS Number_Target
             , stagingInvoiceDetail.Number AS Number_Intermediate
             , targetInvoiceDetail.EntityType AS EntityType_Target
             , stagingInvoiceDetail.EntityType AS EntityType_Intermediate
             , targetInvoiceDetail.InvoiceAmount_Amount AS InvoiceAmount_Amount_Target
             , stagingInvoiceDetail.InvoiceAmount_Amount AS InvoiceAmount_Amount_Intermediate
             , ISNULL(targetInvoiceDetail.InvoiceAmount_Amount, 0.00) - stagingInvoiceDetail.InvoiceAmount_Amount AS InvoiceAmount_Amount_Difference
             , targetInvoiceDetail.InvoiceTaxAmount_Amount AS InvoiceTaxAmount_Amount_Target
             , stagingInvoiceDetail.InvoiceTaxAmount_Amount AS InvoiceTaxAmount_Amount_Intermediate
             , ISNULL(targetInvoiceDetail.InvoiceTaxAmount_Amount, 0.00) - stagingInvoiceDetail.InvoiceTaxAmount_Amount AS InvoiceTaxAmount_Amount_Difference
             , targetInvoiceDetail.SequenceNumber AS SequenceNumberTarget
             , stagingInvoiceDetail.SequenceNumber AS SequenceNumber_Target
             , targetInvoiceDetail.PaymentType AS PaymentType_Target
             , stagingInvoiceDetail.PaymentType AS PaymentType_Intermediate
             , targetInvoiceDetail.ReceivableType AS ReceivableType_Target
             , stagingInvoiceDetail.ReceivableType AS ReceivableType_Intermediate
             , CAST(targetInvoiceDetail.ReceivableDueDate AS nvarchar(20)) AS ReceivableDueDate_Target
             , CAST(stagingInvoiceDetail.ReceivableDueDate AS nvarchar(20)) AS ReceivableDueDate_Intermediate
             , targetInvoiceDetail.AssetAlias AS AssetAlias_Target
             , stagingInvoiceDetail.AssetAlias AS AssetAlias_Intermediate
             , targetInvoiceDetail.ReceivableUniqueIdentifier AS ReceivableUniqueIdentifier_Target
             , stagingInvoiceDetail.ReceivableUniqueIdentifier AS ReceivableUniqueIdentifier_Intermediate
			 , stagingInvoiceDetail.StagingReceivableInvoiceDetailId
			 , targetInvoiceDetail.TargetReceivableInvoiceDetailId
        INTO #FailedRecords
        FROM #StagingReceivableInvoiceDetail stagingInvoiceDetail
             LEFT JOIN #targetReceivableInvoiceDetail targetInvoiceDetail ON stagingInvoiceDetail.Number = targetInvoiceDetail.Number
                                                                             AND ((stagingInvoiceDetail.AssetAlias = targetInvoiceDetail.AssetAlias)
                                                                                  OR (ISNULL(stagingInvoiceDetail.AssetAlias, targetInvoiceDetail.AssetAlias) IS NULL))
        WHERE targetInvoiceDetail.Number IS NULL
              OR ISNULL(targetInvoiceDetail.InvoiceAmount_Amount, 0.00) - stagingInvoiceDetail.InvoiceAmount_Amount != 0.00
              OR ISNULL(targetInvoiceDetail.InvoiceTaxAmount_Amount, 0.00) - stagingInvoiceDetail.InvoiceTaxAmount_Amount != 0.00
              OR ISNULL(targetInvoiceDetail.EntityType, '') != ISNULL(stagingInvoiceDetail.EntityType, '')
              OR ISNULL(targetInvoiceDetail.SequenceNumber, '') != ISNULL(stagingInvoiceDetail.SequenceNumber, '')
              OR ISNULL(targetInvoiceDetail.PaymentType, '') != ISNULL(stagingInvoiceDetail.PaymentType, '')
              OR ISNULL(targetInvoiceDetail.ReceivableType, '') != ISNULL(stagingInvoiceDetail.ReceivableType, '')
              OR ISNULL(targetInvoiceDetail.ReceivableDueDate, '') != ISNULL(stagingInvoiceDetail.ReceivableDueDate, '')
              OR ISNULL(targetInvoiceDetail.AssetAlias, '') != ISNULL(stagingInvoiceDetail.AssetAlias, '')
              OR ISNULL(targetInvoiceDetail.ReceivableUniqueIdentifier, '') != ISNULL(stagingInvoiceDetail.ReceivableUniqueIdentifier, '');

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
			   , intermediate_InvoiceTaxAmount
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
                FROM #targetReceivableInvoiceDetail [target]
                WHERE NOT EXISTS
                (
                    SELECT 1
                    FROM #FailedRecords failed
                    WHERE failed.TargetReceivableInvoiceDetailId = [target].TargetReceivableInvoiceDetailId
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
			SELECT [Status]
				 , StagingReceivableInvoiceDetailId AS ReceivableInvoiceDetailId_Intermediate
				 , Number_Target
				 , Number_Intermediate
				 , EntityType_Target
				 , EntityType_Intermediate
				 , InvoiceAmount_Amount_Target
				 , InvoiceAmount_Amount_Intermediate
				 , InvoiceAmount_Amount_Difference
				 , InvoiceTaxAmount_Amount_Target
				 , InvoiceTaxAmount_Amount_Intermediate
				 , InvoiceTaxAmount_Amount_Difference
				 , SequenceNumberTarget
				 , SequenceNumber_Target
				 , PaymentType_Target
				 , PaymentType_Intermediate
				 , ReceivableType_Target
				 , ReceivableType_Intermediate
				 , ReceivableDueDate_Target
				 , ReceivableDueDate_Intermediate
				 , AssetAlias_Target
				 , AssetAlias_Intermediate
				 , ReceivableUniqueIdentifier_Target
				 , ReceivableUniqueIdentifier_Intermediate
			FROM #FailedRecords;
		END;

        DROP TABLE IF EXISTS #Report;
        DROP TABLE IF EXISTS #StagingReceivableInvoice;
        DROP TABLE IF EXISTS #TargetReceivableInvoice;
		DROP TABLE IF EXISTS #FailedRecords;
		DROP TABLE IF EXISTS #StagingReceivableInvoiceDetail;
		DROP TABLE IF EXISTS #targetReceivableInvoiceDetail;

END;

GO

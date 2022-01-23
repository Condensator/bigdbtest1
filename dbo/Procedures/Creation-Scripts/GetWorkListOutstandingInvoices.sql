SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 

CREATE PROCEDURE [dbo].[GetWorkListOutstandingInvoices]
(
	@CollectionWorkListId				BIGINT,
	@EntityTypeCT						NVARCHAR(2),
	@ReceiptPostedStatus				NVARCHAR(15),
	@ReceiptPendingStatus				NVARCHAR(15),
	@ReceiptSubmittedStatus				NVARCHAR(15),
	@ReceiptReadyForPostingStatus		NVARCHAR(15),
	@Keyword							NVARCHAR(MAX),
	@ToOutstandingBalanceFilter			DECIMAL(16, 2),
	@FromOutstandingBalanceFilter		DECIMAL(16, 2),
	@FromDueDateFilter					DATETIME,           
	@ToDueDateFilter					DATETIME,	
	@InvoiceNumberFilter				NVARCHAR(MAX),
	@SequenceNumberFilter				NVARCHAR(MAX),
	@AgingBucketFilter					NVARCHAR(MAX),
	@StartingRowNumber					INT,
	@EndingRowNumber					INT,
	@OrderBy							NVARCHAR(6),
	@OrderColumn						NVARCHAR(MAX)
)
AS 
BEGIN 


	SELECT DISTINCT
			ReceivableInvoices.Id AS ReceivableInvoiceId
			,ReceivableDetails.Id AS ReceivableDetailId
			,ReceivableInvoices.DaysLateCount AS DaysPastDue
		INTO #DelinquentReceivables
		FROM 
			CollectionWorkLists
			INNER JOIN CollectionWorkListContractDetails ON CollectionWorkLists.Id = CollectionWorkListContractDetails.CollectionWorkListId
			INNER JOIN ReceivableInvoiceDetails ON CollectionWorkListContractDetails.ContractId = ReceivableInvoiceDetails.EntityId 
				AND ReceivableInvoiceDetails.EntityType = @EntityTypeCT
				AND ReceivableInvoiceDetails.IsActive = 1 
			INNER JOIN ReceivableInvoices ON ReceivableInvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id 
				AND ReceivableInvoices.CustomerId = CollectionWorkLists.CustomerId
				AND ReceivableInvoices.IsActive = 1				
			INNER JOIN ReceivableInvoiceDeliquencyDetails ON ReceivableInvoices.Id = ReceivableInvoiceDeliquencyDetails.ReceivableInvoiceId	
			INNER JOIN ReceivableDetails ON ReceivableInvoiceDetails.ReceivableDetailId = ReceivableDetails.Id
				AND ReceivableDetails.IsActive = 1  -- ??
			INNER JOIN Receivables ON ReceivableDetails.ReceivableId = Receivables.Id
				AND Receivables.IsActive = 1
			INNER JOIN Contracts ON CollectionWorkListContractDetails.ContractId = Contracts.Id
		WHERE 
			CollectionWorkLists.Id = @CollectionWorkListId
			AND CollectionWorkListContractDetails.IsWorkCompleted = 0
			AND 
			(
				-- To fetch records belonging to worklist remit to
				(CollectionWorkLists.RemitToId IS NOT NULL AND CollectionWorkLists.RemitToId = ReceivableInvoices.RemitToId AND ReceivableInvoices.IsPrivateLabel = 1)
				OR (CollectionWorkLists.RemitToId IS NULL AND ReceivableInvoices.IsPrivateLabel = 0)
			) 
			AND (ReceivableInvoiceDetails.Balance_Amount > 0.00 OR ReceivableInvoiceDetails.TaxBalance_Amount > 0.00)
			AND (@FromDueDateFilter IS NULL OR ReceivableInvoices.DueDate >= @FromDueDateFilter)  
			AND (@ToDueDateFilter IS NULL OR ReceivableInvoices.DueDate <= @ToDueDateFilter)
			AND (@InvoiceNumberFilter IS NULL OR ReceivableInvoices.Number LIKE '%' + @InvoiceNumberFilter + '%')
			AND (@SequenceNumberFilter IS NULL OR Contracts.SequenceNumber LIKE '%' + @SequenceNumberFilter + '%')


	SELECT DISTINCT
			#DelinquentReceivables.ReceivableInvoiceId
			,#DelinquentReceivables.DaysPastDue 
		INTO #DistinctReceivableInvoices
		FROM #DelinquentReceivables


	SELECT * INTO #DelinquentInvoices FROM
		(
			SELECT
				ReceivableInvoices.Number AS InvoiceNumber,
				ReceivableInvoices.Id AS ReceivableInvoiceId
				,ReceivableInvoices.InvoiceFile_Source
				,ReceivableInvoices.InvoiceFile_Type
				,ReceivableInvoices.InvoiceFile_Content
				,ReceivableInvoices.DueDate
				,ReceivableInvoices.InvoiceAmount_Currency AS Currency
				,ReceivableInvoices.InvoiceAmount_Amount AS ChargeAmount_Amount			-- InvoiceAmount for all the contracts in the receivable invoice, may be only 1 contract is part of deliquency.
				,ReceivableInvoices.InvoiceTaxAmount_Amount AS TaxAmount_Amount
				,(ReceivableInvoices.Balance_Amount + ReceivableInvoices.TaxBalance_Amount) AS OutstandingBalance_Amount
				,#DistinctReceivableInvoices.DaysPastDue	
				,(CASE WHEN #DistinctReceivableInvoices.DaysPastDue BETWEEN 1 AND 30 THEN '1-30'
				  WHEN #DistinctReceivableInvoices.DaysPastDue BETWEEN 31 AND 60 THEN '31-60'
				  WHEN #DistinctReceivableInvoices.DaysPastDue BETWEEN 61 AND 90 THEN '61-90'
				  WHEN #DistinctReceivableInvoices.DaysPastDue BETWEEN 91 AND 120 THEN '91-120'
				  WHEN #DistinctReceivableInvoices.DaysPastDue > 120 THEN '120+'
				  ELSE ' '
				END) + ' Days (' + CAST(DaysPastDue as nvarchar(8)) + ')'  AS Bucket	
			FROM 
				#DistinctReceivableInvoices
				INNER JOIN ReceivableInvoices ON #DistinctReceivableInvoices.ReceivableInvoiceId = ReceivableInvoices.Id
		)
		AS DelinquentInvoice
		WHERE 
			(@FromOutstandingBalanceFilter IS NULL OR (DelinquentInvoice.OutstandingBalance_Amount) >= @FromOutstandingBalanceFilter)
			AND (@ToOutstandingBalanceFilter IS NULL OR (DelinquentInvoice.OutstandingBalance_Amount) <= @ToOutstandingBalanceFilter)
			AND (@AgingBucketFilter IS NULL OR (DelinquentInvoice.Bucket) LIKE '%'+ @AgingBucketFilter + '%')
			

		SELECT 
				#DelinquentReceivables.ReceivableInvoiceId
				,SUM(CASE WHEN Receipts.Status = @ReceiptPostedStatus THEN (ReceiptApplicationReceivableDetails.AmountApplied_Amount + ReceiptApplicationReceivableDetails.TaxApplied_Amount) ELSE 0.00 END) AS AmountReceived_Amount
				,SUM(CASE WHEN (Receipts.Status IN (@ReceiptPendingStatus, @ReceiptSubmittedStatus, @ReceiptReadyForPostingStatus)) THEN (ReceiptApplicationReceivableDetails.AmountApplied_Amount + ReceiptApplicationReceivableDetails.TaxApplied_Amount) ELSE 0.00 END) AS PendingAmount_Amount
			INTO #DelinquentInvoicesReceipts
			FROM
				#DelinquentReceivables
				INNER JOIN ReceiptApplicationReceivableDetails ON #DelinquentReceivables.ReceivableDetailId = ReceiptApplicationReceivableDetails.ReceivableDetailId
					AND ReceiptApplicationReceivableDetails.IsActive = 1
				INNER JOIN ReceiptApplications ON ReceiptApplicationReceivableDetails.ReceiptApplicationId = ReceiptApplications.Id
				INNER JOIN Receipts ON ReceiptApplications.ReceiptId = Receipts.Id
			GROUP BY #DelinquentReceivables.ReceivableInvoiceId;


	------------- DYNAMIC QUERY -------------
	DECLARE @SkipCount BIGINT;
	DECLARE @TakeCount BIGINT;
	DECLARE @OrderStatement NVARCHAR(MAX);
	DECLARE @WhereClause NVARCHAR(MAX) = '';

	SET @SkipCount = @StartingRowNumber - 1;

	SET @TakeCount = @EndingRowNumber - @StartingRowNumber + 1;


	IF (@OrderColumn IS NOT NULL AND @OrderColumn != '')
	BEGIN
		SET @OrderStatement = 
			CASE 
				WHEN @OrderColumn='DueDate' THEN 'DueDate'
				WHEN @OrderColumn='ChargeAmount.Amount' THEN 'ChargeAmount_Amount'
				WHEN @OrderColumn='TaxAmount.Amount' THEN 'TaxAmount_Amount'
				WHEN @OrderColumn='InvoiceAmount.Amount' THEN 'InvoiceAmount_Amount'
				WHEN @OrderColumn='AmountReceived.Amount' THEN 'AmountReceived_Amount'
				WHEN @OrderColumn='OutstandingBalance.Amount' THEN 'OutstandingBalance_Amount'
				WHEN @OrderColumn='PendingAmount.Amount' THEN 'PendingAmount_Amount'
				WHEN @OrderColumn='Bucket' THEN 'DaysPastDue'
				WHEN @OrderColumn='InvoiceNumber' THEN 'InvoiceNumber'
			END
	END

	SET  @OrderStatement = 
		CASE 
			WHEN (@OrderStatement IS NOT NULL AND @OrderStatement != '') THEN @OrderStatement + ' ' + @OrderBy
		ELSE
			' DueDate asc '
		END


	--------- KEYWORD SEARCH -----------
	IF(@Keyword IS NOT NULL)
	BEGIN
		SET @WhereClause = @WhereClause + ' (#DelinquentInvoices.InvoiceFile_Source LIKE ''%' + @Keyword + '%'') AND '		
	END

	DECLARE @SelectQuery NVARCHAR(Max) = CAST('' AS NVARCHAR(MAX)) + N' 
	
	SELECT  
	        ReceivableInvoiceId 
	INTO #AllReceivableInvoiceIds
	FROM #DelinquentInvoices
	   WHERE ' + @WhereClause + ' 1 = 1 ;

	------ First Result-Set for all Ids -----------
	SELECT ReceivableInvoiceId AS EntityId
		FROM #AllReceivableInvoiceIds;

	---- Output Result Query -----
	SELECT #DelinquentInvoices.ReceivableInvoiceId
			,#DelinquentInvoices.ReceivableInvoiceId AS Id
			,#DelinquentInvoices.InvoiceNumber as InvoiceNumber
			,#DelinquentInvoices.InvoiceFile_Source
			,#DelinquentInvoices.InvoiceFile_Type
			,#DelinquentInvoices.InvoiceFile_Content
			,#DelinquentInvoices.DueDate
			,#DelinquentInvoices.Bucket
			,#DelinquentInvoices.ChargeAmount_Amount
			,#DelinquentInvoices.Currency AS ChargeAmount_Currency
			,#DelinquentInvoices.TaxAmount_Amount
			,#DelinquentInvoices.Currency AS TaxAmount_Currency
			,(#DelinquentInvoices.ChargeAmount_Amount + #DelinquentInvoices.TaxAmount_Amount) InvoiceAmount_Amount
			,#DelinquentInvoices.Currency AS InvoiceAmount_Currency
			,#DelinquentInvoices.OutstandingBalance_Amount
			,#DelinquentInvoices.Currency AS OutstandingBalance_Currency
			,ISNULL(#DelinquentInvoicesReceipts.AmountReceived_Amount, 0.00) AS AmountReceived_Amount
			,#DelinquentInvoices.Currency AS AmountReceived_Currency
			,ISNULL(#DelinquentInvoicesReceipts.PendingAmount_Amount, 0.00) AS PendingAmount_Amount
			,#DelinquentInvoices.Currency AS PendingAmount_Currency
		FROM #DelinquentInvoices
			LEFT JOIN #DelinquentInvoicesReceipts ON #DelinquentInvoices.ReceivableInvoiceId = #DelinquentInvoicesReceipts.ReceivableInvoiceId
	WHERE '+ @WhereClause + '  1 = 1
	ORDER BY '+ @OrderStatement + 
	CASE WHEN @EndingRowNumber > 0
	     THEN
	        ' OFFSET @SkipCount ROWS FETCH NEXT @TakeCount ROWS ONLY ;' 
         ELSE 
		    ';'  
	END

			
	EXEC sp_executesql @SelectQuery,
								N'
								@TakeCount BIGINT,
								@SkipCount BIGINT',
								@TakeCount,
								@SkipCount;

	DROP TABLE #DelinquentReceivables;
	DROP TABLE #DelinquentInvoices;
	DROP TABLE #DelinquentInvoicesReceipts;

END

GO

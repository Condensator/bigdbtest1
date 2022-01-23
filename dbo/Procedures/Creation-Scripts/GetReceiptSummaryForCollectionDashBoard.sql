SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetReceiptSummaryForCollectionDashBoard]
(
	@CollectionWorkListId		  BIGINT,
	@IsWaiver					  BIT,
	@IsPendingPayments			  BIT,
	@IsReceiptsKeywordSearch	  BIT,
	@ReceivableEntityTypeCT		  NVARCHAR(2),
	@ReceiptEntityTypeLease       NVARCHAR(20),
	@ReceiptEntityTypeLoan		  NVARCHAR(20),
	@ReceiptClassificationNonCash NVARCHAR(23),
	@ReceiptClassificationNonAccrualNonDSLNonCash NVARCHAR(23),
	@ReceiptStatusPending				NVARCHAR(15),
	@ReceiptStatusSubmitted				NVARCHAR(15),
	@ReceiptStatusReadyForPosting		NVARCHAR(15),
	@ReceiptStatusInactive				NVARCHAR(15),
	@ReceiptTypeValuesCSV				NVARCHAR(MAX),
	@ReceiptStatusValuesCSV				NVARCHAR(MAX),
	@NonCashReasonValuesCSV				NVARCHAR(MAX),
	@Keyword							NVARCHAR(MAX),
	@FromCheckAmountFilter   			DECIMAL(16, 2), 
	@ToCheckAmountFilter   				DECIMAL(16, 2),     
	@FromUnallocatedCashAmountFilter	DECIMAL(16, 2),
	@ToUnallocatedCashAmountFilter		DECIMAL(16, 2),
	@ReceiptTypeNameFilter				NVARCHAR(30),       
	@ReceiptStatusFilter				NVARCHAR(15),
	@NonCashReasonFilter				NVARCHAR(28),
	@FromReceivedDateFilter				DATETIME,           
	@ToReceivedDateFilter				DATETIME,
	@FromPostDateFilter					DATETIME,
	@ToPostDateFilter					DATETIME,
	@ReceiptNumberFilter				NVARCHAR(MAX),
	@CheckNumberFilter					NVARCHAR(MAX),	
	@InvoiceNumberFilter				NVARCHAR(MAX),
	@SequenceNumberFilter				NVARCHAR(MAX),
	@ReceivableTypeNameFilter			NVARCHAR(MAX),
	@ReceivableCodeNameFilter			NVARCHAR(MAX),
	@CommentFilter						NVARCHAR(MAX),
	@UserNameFilter						NVARCHAR(MAX),	  
	@StartingRowNumber					INT,
	@EndingRowNumber					INT,
	@OrderBy							NVARCHAR(6),
	@OrderColumn						NVARCHAR(MAX)
)
AS

BEGIN
	SET NOCOUNT ON

	CREATE TABLE #EligibleReceipts
	(
		ReceiptId BIGINT NOT NULL,
		AmountAppliedToCharges DECIMAL(16, 2) NOT NULL,
		AmountAppliedToTaxes DECIMAL(16, 2) NOT NULL,
		CheckAmount DECIMAL(16, 2) NOT NULL
	)

	SELECT DISTINCT
			CollectionWorkListContractDetails.ContractId,
			CollectionWorkLists.CustomerId,
			CollectionWorkLists.RemitToId
			
		INTO #WorkListContracts
		FROM CollectionWorkLists
			INNER JOIN CollectionWorkListContractDetails 
				ON CollectionWorkLists.Id = CollectionWorkListContractDetails.CollectionWorkListId
			INNER JOIN Contracts
				ON CollectionWorkListContractDetails.ContractId = Contracts.Id
		WHERE CollectionWorkLists.Id = @CollectionWorkListId
			  AND CollectionWorkListContractDetails.IsWorkCompleted = 0
			  AND (@SequenceNumberFilter IS NULL OR Contracts.SequenceNumber LIKE '%'+@SequenceNumberFilter+'%')


	INSERT INTO #EligibleReceipts
		SELECT
			Receipts.Id,
			SUM(ReceiptApplicationReceivableDetails.AmountApplied_Amount) AS AmountAppliedToCharges,
			SUM(ReceiptApplicationReceivableDetails.TaxApplied_Amount) AS AmountAppliedToTaxes,
			SUM(ReceiptApplicationReceivableDetails.AmountApplied_Amount + ReceiptApplicationReceivableDetails.TaxApplied_Amount) CheckAmount
		FROM ReceivableDetails(nolock)
		INNER JOIN ReceiptApplicationReceivableDetails(nolock)
			ON ReceiptApplicationReceivableDetails.ReceivableDetailId = ReceivableDetails.Id AND
			ReceiptApplicationReceivableDetails.IsActive = 1 AND
			ReceivableDetails.IsActive = 1
			INNER JOIN ReceiptApplications (nolock)
				ON ReceiptApplicationReceivableDetails.ReceiptApplicationId = ReceiptApplications.Id
			INNER JOIN Receipts(nolock)
				ON Receipts.Id = ReceiptApplications.ReceiptId	
			INNER JOIN Receivables (nolock)
				ON ReceivableDetails.ReceivableId = Receivables.Id
				AND Receivables.EntityType = @ReceivableEntityTypeCT
				AND Receivables.IsActive = 1
		    INNER JOIN ReceivableCodes 
				ON Receivables.ReceivableCodeId = ReceivableCodes.Id
			INNER JOIN ReceivableTypes 
				ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
			INNER JOIN #WorkListContracts (nolock)
				ON Receivables.EntityId = #WorkListContracts.ContractId
				AND Receivables.CustomerId = #WorkListContracts.CustomerId
			LEFT JOIN ReceivableInvoiceDetails(nolock)
				ON ReceivableInvoiceDetails.ReceivableDetailId = ReceivableDetails.Id AND
				   ReceivableInvoiceDetails.IsActive = 1
			LEFT JOIN ReceivableInvoices(nolock)
				ON ReceivableInvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id AND
				   ReceivableInvoices.IsActive = 1
		WHERE  
			Receipts.Status != @ReceiptStatusInactive
			AND 
			(
				-- To fetch records belonging to worklist remit to
				(#WorkListContracts.RemitToId IS NOT NULL AND #WorkListContracts.RemitToId = Receivables.RemitToId AND Receivables.IsPrivateLabel = 1)
				OR (#WorkListContracts.RemitToId IS NULL AND Receivables.IsPrivateLabel = 0)
			)
			AND
				(
					--Waiver Widget & Waive History
					   (@IsWaiver = 1 AND Receipts.ReceiptClassification IN (@ReceiptClassificationNonCash, @ReceiptClassificationNonAccrualNonDSLNonCash))	
					--Receipt Widget & Receipt History
					OR (@IsWaiver = 0 AND Receipts.ReceiptClassification NOT IN (@ReceiptClassificationNonCash, @ReceiptClassificationNonAccrualNonDSLNonCash))
				)
			AND (@IsPendingPayments = 0 OR Receipts.Status IN (@ReceiptStatusPending, @ReceiptStatusReadyForPosting, @ReceiptStatusSubmitted))		
			AND (@FromUnallocatedCashAmountFilter IS NULL OR Receipts.Balance_Amount >= @FromUnallocatedCashAmountFilter)
			AND (@ToUnallocatedCashAmountFilter IS NULL OR Receipts.Balance_Amount <= @ToUnallocatedCashAmountFilter)
			AND (@ReceiptStatusFilter IS NULL OR Receipts.Status = @ReceiptStatusFilter)
			AND (@FromReceivedDateFilter IS NULL OR Receipts.ReceivedDate >= @FromReceivedDateFilter)  
			AND (@ToReceivedDateFilter IS NULL OR Receipts.ReceivedDate <= @ToReceivedDateFilter)
			AND (@FromPostDateFilter IS NULL OR Receipts.PostDate >= @FromPostDateFilter)  
			AND (@ToPostDateFilter IS NULL OR Receipts.PostDate <= @ToPostDateFilter)
			AND (@NonCashReasonFilter IS NULL OR Receipts.NonCashReason = @NonCashReasonFilter)
			AND (@ReceiptNumberFilter IS NULL OR Receipts.Number LIKE '%' + @ReceiptNumberFilter + '%' )
			AND (@CheckNumberFilter IS NULL OR Receipts.CheckNumber LIKE '%' + @CheckNumberFilter + '%')
			AND (@CommentFilter IS NULL OR Receipts.Comment LIKE '%' + @CommentFilter + '%')
			AND (@InvoiceNumberFilter IS NULL OR ReceivableInvoices.Number LIKE '%'+@InvoiceNumberFilter+'%')
			AND (@ReceivableTypeNameFilter IS NULL OR ReceivableTypes.Name = @ReceivableTypeNameFilter)
			AND (@ReceivableCodeNameFilter IS NULL OR ReceivableCodes.Name LIKE '%' + @ReceivableCodeNameFilter + '%')
			GROUP BY
			Receipts.Id				


	INSERT INTO #EligibleReceipts
		SELECT 
			Receipts.Id, 
			Receipts.ReceiptAmount_Amount AS AmountAppliedToCharges,
			0.00 AS AmountAppliedToTaxes,
			Receipts.ReceiptAmount_Amount CheckAmount
		FROM Receipts(nolock)
			INNER JOIN #WorkListContracts ON Receipts.ContractId = #WorkListContracts.ContractId
				AND Receipts.EntityType IN (@ReceiptEntityTypeLease, @ReceiptEntityTypeLoan)
			INNER JOIN ReceiptApplications (nolock)
				ON Receipts.Id = ReceiptApplications.ReceiptId
			INNER JOIN ReceiptApplicationDetails (NOLOCK)
				ON ReceiptApplications.Id = ReceiptApplicationDetails.ReceiptApplicationId
			LEFT JOIN ReceiptApplicationReceivableDetails (nolock)
				ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId
				AND ReceiptApplicationReceivableDetails.IsActive = 1
			LEFT JOIN #EligibleReceipts
				on Receipts.Id = #EligibleReceipts.ReceiptId
		WHERE 
			 ReceiptApplicationReceivableDetails.ReceiptApplicationId is NULL 
			AND #EligibleReceipts.ReceiptId IS NULL
			AND Receipts.Status != @ReceiptStatusInactive
			AND	
				(
					--Waiver Widget & Waive History
						(@IsWaiver = 1 AND Receipts.ReceiptClassification IN (@ReceiptClassificationNonCash, @ReceiptClassificationNonAccrualNonDSLNonCash))	
					--Receipt Widget & Receipt History
					OR (@IsWaiver = 0 AND Receipts.ReceiptClassification NOT IN (@ReceiptClassificationNonCash, @ReceiptClassificationNonAccrualNonDSLNonCash))
				)
			AND (@IsPendingPayments = 0 OR Receipts.Status IN (@ReceiptStatusPending, @ReceiptStatusReadyForPosting, @ReceiptStatusSubmitted))		
			AND (@FromUnallocatedCashAmountFilter IS NULL OR Receipts.Balance_Amount >= @FromUnallocatedCashAmountFilter)
			AND (@ToUnallocatedCashAmountFilter IS NULL OR Receipts.Balance_Amount <= @ToUnallocatedCashAmountFilter)
			AND (@ReceiptStatusFilter IS NULL OR Receipts.Status = @ReceiptStatusFilter)
			AND (@NonCashReasonFilter IS NULL OR Receipts.NonCashReason = @NonCashReasonFilter)
			AND (@FromReceivedDateFilter IS NULL OR Receipts.ReceivedDate >= @FromReceivedDateFilter)  
			AND (@ToReceivedDateFilter IS NULL OR Receipts.ReceivedDate <= @ToReceivedDateFilter)
			AND (@FromPostDateFilter IS NULL OR Receipts.PostDate >= @FromPostDateFilter)  
			AND (@ToPostDateFilter IS NULL OR Receipts.PostDate <= @ToPostDateFilter)
			AND (@ReceiptNumberFilter IS NULL OR Receipts.Number LIKE '%'+ @ReceiptNumberFilter + '%' )
			AND (@CheckNumberFilter IS NULL OR Receipts.CheckNumber LIKE '%' + @CheckNumberFilter  + '%')
			AND (@CommentFilter IS NULL OR Receipts.Comment LIKE '%' + @CommentFilter + '%')


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
				WHEN @OrderColumn='ReceiptNumber' THEN 'ReceiptNumber'
				WHEN @OrderColumn='PostDate' THEN 'PostDate'
				WHEN @OrderColumn='NonCashReason.Value' THEN 'NonCashReason'
				WHEN @OrderColumn='Comment' THEN 'Comment'
				WHEN @OrderColumn='ReceivedDate' THEN 'ReceivedDate'
				WHEN @OrderColumn='AmountAppliedToCharges.Amount' THEN 'AmountAppliedToCharges_Amount'
				WHEN @OrderColumn='AmountAppliedToTaxes.Amount' THEN 'AmountAppliedToTaxes_Amount'
				WHEN @OrderColumn='CheckAmount.Amount' THEN 'CheckAmount_Amount'
				WHEN @OrderColumn='ReceiptTypeName.Value' THEN 'ReceiptTypeName'
				WHEN @OrderColumn='CheckNumber' THEN 'CheckNumber'
				WHEN @OrderColumn='UnallocatedCashAmount.Amount' THEN 'UnallocatedCashAmount_Amount'
				WHEN @OrderColumn='Status.Value' THEN 'Status'
			END
	END


	SET  @OrderStatement = 
		CASE 
			WHEN (@OrderStatement IS NOT NULL AND @OrderStatement != '') THEN @OrderStatement + ' ' + @OrderBy
		ELSE
		CASE 
			WHEN @IsWaiver = 1 THEN 'PostDate desc, ReceiptId desc'		-- Default Ordering for Waiver
		ELSE
			'ReceivedDate desc, ReceiptId desc'							-- Default Ordering for non Waiver
		END
	END

	SET @ReceiptTypeValuesCSV = '''' + REPLACE(@ReceiptTypeValuesCSV, ',', ''',''') + '''';	
	SET @ReceiptStatusValuesCSV = '''' + REPLACE(@ReceiptStatusValuesCSV, ',', ''',''') + '''';
	SET @NonCashReasonValuesCSV = '''' + REPLACE(@NonCashReasonValuesCSV, ',', ''',''') + '''';

	--------- KEYWORD SEARCH -----------
	IF(@Keyword IS NOT NULL)
	BEGIN
		SET @WhereClause = @WhereClause +
		CASE
			WHEN @IsReceiptsKeywordSearch = 1
			THEN ' (Receipts.Number LIKE ''%' + @Keyword + '%''' + 
				 ' OR Receipts.CheckNumber LIKE ''%' + @Keyword + '%''' +
				 ' OR ReceiptTypes.ReceiptTypeName IN (' + @ReceiptTypeValuesCSV + ')) AND '
			WHEN @IsWaiver = 1
			THEN ' (Receipts.Status IN (' + @ReceiptStatusValuesCSV + ')  ' +
				 ' OR Receipts.NonCashReason IN (' + @NonCashReasonValuesCSV + ')  ' +
				 ' OR ReceiptTypes.ReceiptTypeName IN (' + @ReceiptTypeValuesCSV + ')) AND '
			WHEN @IsPendingPayments = 1
			THEN ' (Receipts.Number LIKE ''%' + @Keyword + '%''' + 
				 ' OR Receipts.CheckNumber LIKE ''%' + @Keyword + '%''' +
				 ' OR ReceiptTypes.ReceiptTypeName IN (' + @ReceiptTypeValuesCSV + ')) AND '
		ELSE '' END
	END


	--------  Custom Search , Attributes which are not used in above filtering ---------------------
	SET @WhereClause = @WhereClause + 
		CASE WHEN (@FromCheckAmountFilter IS NOT NULL) THEN ' #EligibleReceipts.CheckAmount >= @FromCheckAmountFilter AND ' ELSE '' END + 
		CASE WHEN (@ToCheckAmountFilter IS NOT NULL) THEN ' #EligibleReceipts.CheckAmount <= @ToCheckAmountFilter AND ' ELSE '' END + 
		CASE WHEN (@ReceiptTypeNameFilter IS NOT NULL) THEN ' ReceiptTypes.ReceiptTypeName = @ReceiptTypeNameFilter AND ' ELSE '' END + 
		CASE WHEN (@UserNameFilter IS NOT NULL) THEN ' Users.FullName LIKE ''%' + @UserNameFilter + '%'' AND ' ELSE '' END


	DECLARE @SelectQuery NVARCHAR(Max) = CAST('' AS NVARCHAR(MAX)) + ' 
	
	------ First Result-Set for all Ids -----------

	SELECT  
	        ReceiptId AS EntityId
	FROM #EligibleReceipts
		INNER JOIN Receipts 
			ON #EligibleReceipts.ReceiptId = Receipts.Id
		INNER JOIN ReceiptTypes
			ON Receipts.TypeId = ReceiptTypes.Id	
		INNER JOIN Users 
			ON Receipts.CreatedById = Users.Id
	WHERE '+ @WhereClause + '  1 = 1;


	---- Output Result Query -----
	SELECT
		Receipts.Id AS ReceiptId,	
		Receipts.Id AS Id,
		Receipts.ReceiptAmount_Currency AS Currency,
		Receipts.Number AS ReceiptNumber,
		Receipts.ReceivedDate,
		#EligibleReceipts.AmountAppliedToCharges AS AmountAppliedToCharges_Amount,
		Receipts.ReceiptAmount_Currency AS AmountAppliedToCharges_Currency,
		#EligibleReceipts.AmountAppliedToTaxes AS AmountAppliedToTaxes_Amount,
		Receipts.ReceiptAmount_Currency AS AmountAppliedToTaxes_Currency,
		#EligibleReceipts.CheckAmount AS CheckAmount_Amount,
		Receipts.ReceiptAmount_Currency AS CheckAmount_Currency,
		Receipts.CheckNumber,
		Receipts.Balance_Amount AS UnallocatedCashAmount_Amount,
		Receipts.ReceiptAmount_Currency AS UnallocatedCashAmount_Currency,
		Receipts.Status,
		ReceiptTypes.ReceiptTypeName,
		Receipts.Comment,
		ISNULL(UpdatedByUsers.FullName,Users.FullName) AS UserName,
		Receipts.NonCashReason,
		Receipts.PostDate
	FROM #EligibleReceipts
		INNER JOIN Receipts 
			ON #EligibleReceipts.ReceiptId = Receipts.Id
		INNER JOIN ReceiptTypes
			ON Receipts.TypeId = ReceiptTypes.Id	
		INNER JOIN Users 
			ON Receipts.CreatedById = Users.Id
		LEFT JOIN Users UpdatedByUsers
			ON Receipts.UpdatedById= UpdatedByUsers.Id
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
								@SkipCount BIGINT,
								@FromCheckAmountFilter DECIMAL(16, 2),
								@ToCheckAmountFilter DECIMAL(16, 2),
								@ReceiptTypeNameFilter NVARCHAR(30)',
								@TakeCount,
								@SkipCount,
								@FromCheckAmountFilter,
								@ToCheckAmountFilter,
								@ReceiptTypeNameFilter;


	DROP TABLE #WorkListContracts
	DROP TABLE #EligibleReceipts

END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetWorkListUnAppliedReceipts]
(
	@CollectionWorkListId				BIGINT,
	@ReceiptClassificationNonCash		NVARCHAR(23),
	@ReceiptClassificationNonAccrualNonDSLNonCash NVARCHAR(23),
	@ReceiptStatusPosted				NVARCHAR(15),
	@Keyword							NVARCHAR(MAX),
	@ReceiptTypeValuesCSV				NVARCHAR(MAX),
	@FromUnallocatedCashAmountFilter	DECIMAL(16, 2),
	@ToUnallocatedCashAmountFilter		DECIMAL(16, 2),
	@FromReceivedDateFilter				DATETIME,           
	@ToReceivedDateFilter				DATETIME,
	@ReceiptTypeNameFilter				NVARCHAR(30), 
	@ReceiptNumberFilter				NVARCHAR(MAX),
	@CheckNumberFilter					NVARCHAR(MAX),	
	@SequenceNumberFilter				NVARCHAR(MAX),
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
		ReceiptId BIGINT NOT NULL
	);

	SELECT Value AS ReceiptTypeName INTO #ReceiptTypeCSVValues FROM STRING_SPLIT(@ReceiptTypeValuesCSV, ',');

	IF(@SequenceNumberFilter IS NULL)
	BEGIN

		INSERT INTO #EligibleReceipts
			SELECT DISTINCT
				Receipts.Id AS ReceiptId
			FROM Receipts
				INNER JOIN CollectionWorkLists ON Receipts.CustomerId = CollectionWorkLists.CustomerId
					AND Receipts.CurrencyId = CollectionWorkLists.CurrencyId
				INNER JOIN ReceiptTypes ON Receipts.TypeId = ReceiptTypes.Id
				LEFT JOIN #ReceiptTypeCSVValues ON ReceiptTypes.ReceiptTypeName = #ReceiptTypeCSVValues.ReceiptTypeName
			WHERE CollectionWorkLists.Id = @CollectionWorkListId
				AND Receipts.Balance_Amount > 0.00
				AND Receipts.ReceiptClassification NOT IN (@ReceiptClassificationNonCash, @ReceiptClassificationNonAccrualNonDSLNonCash)
				AND Receipts.Status = @ReceiptStatusPosted 
				AND (@ReceiptTypeNameFilter IS NULL OR ReceiptTypes.ReceiptTypeName = @ReceiptTypeNameFilter)
				AND (@FromUnallocatedCashAmountFilter IS NULL OR Receipts.Balance_Amount >= @FromUnallocatedCashAmountFilter)
				AND (@ToUnallocatedCashAmountFilter IS NULL OR Receipts.Balance_Amount <= @ToUnallocatedCashAmountFilter)
				AND (@FromReceivedDateFilter IS NULL OR Receipts.ReceivedDate >= @FromReceivedDateFilter) 
				AND (@ToReceivedDateFilter IS NULL OR Receipts.ReceivedDate <= @ToReceivedDateFilter)
				AND (@ReceiptNumberFilter IS NULL OR Receipts.Number LIKE '%' + @ReceiptNumberFilter + '%' )
				AND (@CheckNumberFilter IS NULL OR Receipts.CheckNumber LIKE '%' + @CheckNumberFilter + '%')
				AND (@Keyword IS NULL OR (Receipts.Number LIKE '%' + @Keyword + '%' OR Receipts.CheckNumber LIKE '%' + @Keyword + '%' OR #ReceiptTypeCSVValues.ReceiptTypeName IS NOT NULL))
	
	END



	INSERT INTO #EligibleReceipts
		SELECT DISTINCT
			Receipts.Id AS ReceiptId
		FROM CollectionWorkLists 
				INNER JOIN CollectionWorkListContractDetails ON CollectionWorkLists.Id = CollectionWorkListContractDetails.CollectionWorkListId
				INNER JOIN Receipts ON CollectionWorkListContractDetails.ContractId = Receipts.ContractId
					AND CollectionWorkLists.CurrencyId = Receipts.CurrencyId
				INNER JOIN Contracts ON CollectionWorkListContractDetails.ContractId = Contracts.Id
				INNER JOIN ReceiptTypes ON Receipts.TypeId = ReceiptTypes.Id
				LEFT JOIN #ReceiptTypeCSVValues ON ReceiptTypes.ReceiptTypeName = #ReceiptTypeCSVValues.ReceiptTypeName
				LEFT JOIN #EligibleReceipts ON Receipts.Id = #EligibleReceipts.ReceiptId
			WHERE 
				CollectionWorkLists.Id = @CollectionWorkListId
				AND #EligibleReceipts.ReceiptId IS NULL
				AND CollectionWorkListContractDetails.IsWorkCompleted = 0
				AND Receipts.Balance_Amount > 0.00
				AND Receipts.ReceiptClassification NOT IN (@ReceiptClassificationNonCash, @ReceiptClassificationNonAccrualNonDSLNonCash)
				AND Receipts.Status = @ReceiptStatusPosted
				AND (@ReceiptTypeNameFilter IS NULL OR ReceiptTypes.ReceiptTypeName = @ReceiptTypeNameFilter)
				AND (@FromUnallocatedCashAmountFilter IS NULL OR Receipts.Balance_Amount >= @FromUnallocatedCashAmountFilter)
				AND (@ToUnallocatedCashAmountFilter IS NULL OR Receipts.Balance_Amount <= @ToUnallocatedCashAmountFilter)
				AND (@FromReceivedDateFilter IS NULL OR Receipts.ReceivedDate >= @FromReceivedDateFilter) 
				AND (@ToReceivedDateFilter IS NULL OR Receipts.ReceivedDate <= @ToReceivedDateFilter)
				AND (@SequenceNumberFilter IS NULL OR Contracts.SequenceNumber LIKE '%'+@SequenceNumberFilter+'%')
				AND (@ReceiptNumberFilter IS NULL OR Receipts.Number LIKE '%' + @ReceiptNumberFilter + '%' )
				AND (@CheckNumberFilter IS NULL OR Receipts.CheckNumber LIKE '%' + @CheckNumberFilter + '%')
				AND (@Keyword IS NULL OR (Receipts.Number LIKE '%' + @Keyword + '%' OR Receipts.CheckNumber LIKE '%' + @Keyword + '%' OR #ReceiptTypeCSVValues.ReceiptTypeName IS NOT NULL))


	------------- DYNAMIC QUERY -------------
	DECLARE @SkipCount BIGINT;
	DECLARE @TakeCount BIGINT;
	DECLARE @OrderStatement NVARCHAR(MAX);

	SET @SkipCount = @StartingRowNumber - 1;

	SET @TakeCount = @EndingRowNumber - @StartingRowNumber + 1;
	

	IF (@OrderColumn IS NOT NULL AND @OrderColumn != '')
	BEGIN
		SET @OrderStatement =   
			CASE 
				WHEN @OrderColumn='ReceiptNumber' THEN 'ReceiptNumber'
				WHEN @OrderColumn='ReceivedDate' THEN 'ReceivedDate'
				WHEN @OrderColumn='AmountAppliedToCharges.Amount' THEN 'AmountAppliedToCharges_Amount'
				WHEN @OrderColumn='AmountAppliedToTaxes.Amount' THEN 'AmountAppliedToTaxes_Amount'
				WHEN @OrderColumn='CheckAmount.Amount' THEN 'CheckAmount_Amount'
				WHEN @OrderColumn='ReceiptTypeName.Value' THEN 'ReceiptTypeName'
				WHEN @OrderColumn='CheckNumber' THEN 'CheckNumber'
				WHEN @OrderColumn='UnallocatedCashAmount.Amount' THEN 'UnallocatedCashAmount_Amount'
				WHEN @OrderColumn='Status.Value' THEN 'Status'
			END;
	END


	SET  @OrderStatement = 
		CASE 
			WHEN (@OrderStatement IS NOT NULL AND @OrderStatement != '') THEN @OrderStatement + ' ' + @OrderBy
		ELSE
			'ReceivedDate desc, ReceiptId desc'							
		END;


	DECLARE @SelectQuery NVARCHAR(Max) = CAST('' AS NVARCHAR(MAX)) + ' 
	
	------ First Result-Set for all Ids -----------

	SELECT  
	        ReceiptId AS EntityId
	FROM #EligibleReceipts
		INNER JOIN Receipts 
			ON #EligibleReceipts.ReceiptId = Receipts.Id
		INNER JOIN ReceiptTypes 
			ON Receipts.TypeId = ReceiptTypes.Id;


	---- Output Result Query -----
	SELECT
		Receipts.Id AS Id,
		Receipts.Id AS ReceiptId,
		Receipts.Number AS ReceiptNumber,	
		Receipts.ReceiptAmount_Currency AS Currency,
		Receipts.ReceivedDate,
		Receipts.CheckNumber,		
		Receipts.Status,
		ReceiptTypes.ReceiptTypeName,
		Receipts.ReceiptAmount_Amount AS ReceiptAmount_Amount,
		Receipts.ReceiptAmount_Currency AS ReceiptAmount_Currency,
		Receipts.Balance_Amount AS UnallocatedCashAmount_Amount,
		Receipts.Balance_Currency AS UnallocatedCashAmount_Currency
	FROM #EligibleReceipts
		INNER JOIN Receipts
			ON #EligibleReceipts.ReceiptId = Receipts.Id
		INNER JOIN ReceiptTypes 
			ON Receipts.TypeId = ReceiptTypes.Id
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
								@ReceiptTypeNameFilter NVARCHAR(30)',
								@TakeCount,
								@SkipCount,
								@ReceiptTypeNameFilter;


	DROP TABLE #EligibleReceipts;

END

GO

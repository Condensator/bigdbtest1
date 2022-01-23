SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetFollowupCollectionWorkLists] (
    @FollowupUserId					BIGINT,  
	@CurrentBusinessDate			DATETIME,
	@ReceivableEntityTypeCT			NVARCHAR(2),
	@ReceiptEntityTypeLease			NVARCHAR(20),
	@ReceiptEntityTypeLoan			NVARCHAR(20),
	@ReceiptClassificationNonCash	NVARCHAR(23),
	@ReceiptClassificationNonAccrualNonDSLNonCash NVARCHAR(23),
	@ReceiptStatusPosted			NVARCHAR(15),
	@ReceiptStatusInactive			NVARCHAR(20),
	@ReceiptStatusReversed			NVARCHAR(20),
	@SystemDateTimeOffset			DATETIMEOFFSET,
	@YesValue    					NVARCHAR(10),
	@NoValue						NVARCHAR(10),
	@PartyContactTypePreference		FollowUpWorkListPartyContactTypePreference READONLY,
	@FilteredCollectionWorkList		FilteredFollowUpCollectionWorkList READONLY,
	@StartingRowNumber				INT,
	@EndingRowNumber				INT,
	@Keyword						NVARCHAR(MAX) = NULL,
	@SubActivityTypeValuesCSV		NVARCHAR(MAX) = NULL,
	@ActivityOutcome				NVARCHAR(34) = NULL,
	@FromFollowUpDate				DATETIMEOFFSET = NULL,
	@ToFollowUpDate					DATETIMEOFFSET = NULL,
	@FromPastDueAmount				DECIMAL(16, 2) = NULL,
	@ToPastDueAmount				DECIMAL(16, 2) = NULL,
	@OrderBy						NVARCHAR(6) = NULL,
	@OrderColumn					NVARCHAR(MAX) = NULL
)
AS 
BEGIN 

SET NOCOUNT ON;

    CREATE TABLE #ElligibleCollectionWorkList  
	(
      CollectionWorkListId	 BIGINT,
      CustomerId              BIGINT,
	  CurrencyId              BIGINT,
	  RemitToId               BIGINT NULL
	);

   CREATE CLUSTERED INDEX #Elligible_CollectionWorkLisId_ID ON #ElligibleCollectionWorkList(CollectionWorkListId);
   CREATE INDEX #Elligible_CollectionWorkLisId_CustomerId ON #ElligibleCollectionWorkList(CustomerId);

	CREATE TABLE #InvoiceDetails
    (
        CollectionWorkListId  BIGINT, 
    	TotalPastDueAmount    Decimal(18,2) NULL 
    );
    CREATE TABLE #ReceiptAllocationDetails
    (
        CollectionWorkListId			  BIGINT, 
    	TotalUnAllocatedBalance_Amount    Decimal(18,2) NULL
    );

	CREATE TABLE #UnAppliedReceipts
	(
		CollectionWorkListId BIGINT,
		ReceiptId BIGINT,
		Balance_Amount DECIMAL(18, 2)
	);

	
   DECLARE @HasFilteredRecords BIT = 0;
   
   IF EXISTS(Select top 1 * from  @FilteredCollectionWorkList)
		SET @HasFilteredRecords = 1; 


	INSERT INTO #ElligibleCollectionWorkList
	SELECT 
		DISTINCT 
		Activities.EntityId CollectionWorkListId,
		CollectionWorkLists.CustomerId,
		CollectionWorkLists.CurrencyId,
		CollectionWorkLists.RemitToId
	FROM Activities
	INNER JOIN ActivityForCollectionWorkLists
	    ON Activities.Id = ActivityForCollectionWorkLists.Id 
	INNER JOIN CollectionWorkLists
		ON ActivityForCollectionWorkLists.CollectionWorkListId = CollectionWorkLists.Id
	LEFT JOIN @FilteredCollectionWorkList FilteredList ON CollectionWorkLists.Id = FilteredList.CollectionWorkListId 
    WHERE 
		(@HasFilteredRecords = 0 OR FilteredList.CollectionWorkListId IS NOT NULL)
		  AND Activities.OwnerId = @FollowupUserId 
	      AND Activities.IsActive = 1
	      AND Activities.CloseFollowUp = 0
		  AND Activities.IsFollowUpRequired = 1
		  AND (@ActivityOutcome IS NULL OR (ActivityForCollectionWorkLists.SubActivityType LIKE '%' + @ActivityOutcome + '%'))
		  AND (@FromFollowUpDate IS NULL OR (Activities.FollowUpDate >= @FromFollowUpDate))
		  AND (@ToFollowUpDate IS NULL OR (Activities.FollowUpDate <= @ToFollowUpDate))

	INSERT INTO #InvoiceDetails
	SELECT CollectionWorkListId, TotalPastDueAmount FROM
		(
			SELECT 
				 CollectionWorkListContractDetails.CollectionWorkListId 
				,Sum(ReceivableInvoiceDetails.Balance_Amount + ReceivableInvoiceDetails.TaxBalance_Amount) TotalPastDueAmount
			 FROM 
				#ElligibleCollectionWorkList
			 INNER JOIN CollectionWorkListContractDetails   
				ON CollectionWorkListContractDetails.CollectionWorkListId = #ElligibleCollectionWorkList.CollectionWorkListId
			 INNER JOIN ReceivableInvoiceDetails   
				ON CollectionWorkListContractDetails.ContractId = ReceivableInvoiceDetails.EntityId AND 
				   ReceivableInvoiceDetails.EntityType = @ReceivableEntityTypeCT
			 INNER JOIN ReceivableInvoices   
				ON ReceivableInvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id AND
				   #ElligibleCollectionWorkList.CustomerId = ReceivableInvoices.CustomerId AND
				   ReceivableInvoiceDetails.IsActive = 1 AND 
				   ReceivableInvoices.IsActive = 1
			 INNER JOIN ReceivableInvoiceDeliquencyDetails 
				ON ReceivableInvoices.Id = ReceivableInvoiceDeliquencyDetails.ReceivableInvoiceId	
			 WHERE 
				CollectionWorkListContractDetails.IsWorkCompleted = 0
				AND 
				(
					-- To fetch records belonging to worklist remit to
					(#ElligibleCollectionWorkList.RemitToId IS NOT NULL AND #ElligibleCollectionWorkList.RemitToId = ReceivableInvoices.RemitToId AND ReceivableInvoices.IsPrivateLabel = 1)
					OR (#ElligibleCollectionWorkList.RemitToId IS NULL AND ReceivableInvoices.IsPrivateLabel = 0)
				) 
			 GROUP BY 
				CollectionWorkListContractDetails.CollectionWorkListId
			)
			AS InvoiceInfo
			WHERE (@FromPastDueAmount IS NULL OR InvoiceInfo.TotalPastDueAmount >= @FromPastDueAmount)
				AND (@ToPastDueAmount IS NULL OR InvoiceInfo.TotalPastDueAmount <= @ToPastDueAmount);
	

	--Customer level unapplied
	INSERT INTO #UnAppliedReceipts
		SELECT  DISTINCT
			#ElligibleCollectionWorkList.CollectionWorkListId,
			Receipts.Id AS ReceiptId,
			Receipts.Balance_Amount
		FROM Receipts
			INNER JOIN #ElligibleCollectionWorkList ON Receipts.CustomerId = #ElligibleCollectionWorkList.CustomerId
				AND Receipts.CurrencyId = #ElligibleCollectionWorkList.CurrencyId
		WHERE Receipts.Balance_Amount > 0.00
			AND Receipts.ReceiptClassification NOT IN (@ReceiptClassificationNonCash, @ReceiptClassificationNonAccrualNonDSLNonCash)
			AND Receipts.Status = @ReceiptStatusPosted; 

	--Contract level unapplied
	INSERT INTO #UnAppliedReceipts
		SELECT DISTINCT
				#ElligibleCollectionWorkList.CollectionWorkListId,
				Receipts.Id AS ReceiptId,
				Receipts.Balance_Amount
			FROM #ElligibleCollectionWorkList 
				INNER JOIN CollectionWorkListContractDetails ON #ElligibleCollectionWorkList.CollectionWorkListId = CollectionWorkListContractDetails.CollectionWorkListId
				INNER JOIN Receipts ON CollectionWorkListContractDetails.ContractId = Receipts.ContractId
					AND Receipts.CurrencyId = #ElligibleCollectionWorkList.CurrencyId
			WHERE 
				 CollectionWorkListContractDetails.IsWorkCompleted = 0
				AND Receipts.Balance_Amount > 0.00
				AND Receipts.ReceiptClassification NOT IN (@ReceiptClassificationNonCash, @ReceiptClassificationNonAccrualNonDSLNonCash)
				AND Receipts.Status = @ReceiptStatusPosted;


	INSERT INTO #ReceiptAllocationDetails
		SELECT 
			 CollectionWorkListId
			,SUM(Balance_Amount) AS TotalUnAllocatedBalance_Amount
		FROM 
			#UnAppliedReceipts
		GROUP BY CollectionWorkListId;



	SELECT ROW_NUMBER() OVER(PARTITION BY PartyId ORDER BY PartyContactType.Id DESC, PartyContacts.CreatedTime) Row_Num,
		   PartyId, FullName, 
		   @SystemDateTimeOffset AT TIME ZONE TimeZones.Name PartyContactLocalTime,
		   TimeZones.Abbreviation PartyContactTimeZoneAbbreviation,		   
		   @SystemDateTimeOffset AT TIME ZONE BusinessUnitTimeZones.Name BusinessUnitLocalTime,
		   BusinessUnitTimeZones.Abbreviation BusinessUnitTimeZoneAbbreviation,
		   CASE WHEN 
			(PartyContacts.TimeZoneId IS NULL OR (PartyContacts.BusinessStartTimeInHours = 0 AND PartyContacts.BusinessStartTimeInMinutes = 0 AND
			PartyContacts.BusinessEndTimeInHours = 0 AND PartyContacts.BusinessEndTimeInMinutes = 0 ))
			THEN 1 ELSE 0 END ConsiderBusinessUnitTimeZone
	INTO #PartyContactDetails
	FROM CollectionWorkLists 
		 INNER JOIN #ElligibleCollectionWorkList 
			ON CollectionWorkLists.Id = #ElligibleCollectionWorkList.CollectionWorkListId
		 INNER JOIN BusinessUnits 
			ON CollectionWorkLists.BusinessUnitId = BusinessUnits.Id
		 INNER JOIN TimeZones BusinessUnitTimeZones
		 	ON BusinessUnits.StandardTimeZoneId = BusinessUnitTimeZones.Id
		 INNER JOIN PartyContacts
			ON CollectionWorkLists.CustomerId = PartyContacts.PartyId
		 LEFT JOIN PartyContactTypes
		 	ON PartyContacts.Id = PartyContactTypes.PartyContactId
		 LEFT JOIN @PartyContactTypePreference PartyContactType
		 	ON PartyContactTypes.ContactType = PartyContactType.ContactType
		 LEFT JOIN TimeZones
		 	ON PartyContacts.TimeZoneId = TimeZones.Id
	WHERE PartyContacts.IsActive = 1 AND PartyContactTypes.IsActive = 1

	ALTER table #PartyContactDetails ADD LocalTime DateTimeOffset
	ALTER table #PartyContactDetails ADD TimeZoneAbbreviation NVARCHAR(10)

	UPDATE #PartyContactDetails 
	SET LocalTime = (CASE WHEN ConsiderBusinessUnitTimeZone = 1 THEN BusinessUnitLocalTime ELSE PartyContactLocalTime END),	   
		TimeZoneAbbreviation = (CASE WHEN ConsiderBusinessUnitTimeZone = 1 THEN BusinessUnitTimeZoneAbbreviation ELSE PartyContactTimeZoneAbbreviation END)

      ------------- DYNAMIC QUERY ----------	
   DECLARE @SkipCount BIGINT;
   DECLARE @TakeCount BIGINT;
   DECLARE @WhereStatement NVARCHAR(MAX) = '';
   SET @SubActivityTypeValuesCSV = '''' + REPLACE(@SubActivityTypeValuesCSV, ',', ''',''') + '''';
   
   SET @SkipCount = @StartingRowNumber - 1;

   SET @TakeCount = @EndingRowNumber - @StartingRowNumber + 1;

    IF(@FromPastDueAmount IS NOT NULL OR @ToPastDueAmount IS NOT NULL)
	BEGIN
		SET @WhereStatement = @WhereStatement + ' (#InvoiceDetails.CollectionWorkListId IS NOT NULL) AND '
	END

	IF(@ActivityOutcome IS NOT NULL)
	BEGIN
		SET @WhereStatement = @WhereStatement + ' (ActivityForCollectionWorkLists.SubActivityType = ''' + @ActivityOutcome + ''') AND ';
	END

	IF(@Keyword IS NOT NULL)
	BEGIN
		SET @WhereStatement = @WhereStatement + '(' + 
													'(Parties.PartyName LIKE ''%' +  @Keyword + '%'')' +
													' OR (PartyContact.FullName LIKE ''%' +  @Keyword + '%'') ' +
													' OR (CollectionStatus.Name LIKE ''%' +  @Keyword + '%'') ' +
													' OR (CollectionQueues.Name LIKE ''%' +  @Keyword + '%'') ' +
													' OR (ActivityForCollectionWorkLists.SubActivityType IN (' + @SubActivityTypeValuesCSV + '))' +
												') AND ';
	END


  DECLARE @OrderStatement NVARCHAR(MAX) =  
  CASE 
	WHEN @OrderColumn='PartyName' THEN 'PartyName' + ' ' + @OrderBy
	WHEN @OrderColumn='CollectionQueueName' THEN 'CollectionQueueName'  + ' ' + @OrderBy
	WHEN @OrderColumn='PrimaryContact' THEN 'PrimaryContact'  + ' ' + @OrderBy
	WHEN @OrderColumn='CollectionStatusName' THEN 'CollectionStatusName'  + ' ' + @OrderBy
	WHEN @OrderColumn='LastCollectionActivityOutcome.Value' THEN 'LastCollectionActivityOutcome'  + ' ' + @OrderBy 
	WHEN @OrderColumn='PastDueAmount.Amount' THEN 'PastDueAmount_Amount'  + ' ' + @OrderBy
	WHEN @OrderColumn='PastDueAmount.Currency' THEN 'PastDueAmount_Amount'  + ' ' + @OrderBy
	WHEN @OrderColumn='UnallocatedBalance.Amount' THEN 'UnallocatedBalance_Amount' + ' ' + @OrderBy
	WHEN @OrderColumn='UnallocatedBalance.Currency' THEN 'UnallocatedBalance_Amount' + ' ' + @OrderBy
	WHEN @OrderColumn='FollowupComments' THEN 'FollowupComments' + ' ' + @OrderBy
	WHEN @OrderColumn='FollowupDateAndTime' THEN 'FollowupDateAndTime' + ' ' + @OrderBy
	WHEN @OrderColumn='LocalTime' THEN 'CONVERT(NVARCHAR(5), ISNULL(PartyContact.LocalTime, @SystemDateTimeOffset AT TIME ZONE  TimeZones.Name), 8)'  + ' ' + @OrderBy
	WHEN @OrderColumn='PrivateLabel' THEN 'IsPrivateLabel ' + ' ' + @OrderBy + ' '+ ',PrivateLabel ' + ' '+ @OrderBy
  ELSE 'Activities.FollowUpDate ASC,Activities.CreatedTime DESC'  END

  DECLARE @JoinStatement Nvarchar(MAX) =  
	'Activities
	INNER JOIN CollectionWorkLists
	    ON Activities.EntityId = CollectionWorkLists.Id
	INNER JOIN #ElligibleCollectionWorkList
		ON #ElligibleCollectionWorkList.CollectionWorkListId = CollectionWorkLists.Id
	INNER JOIN BusinessUnits
		ON CollectionWorkLists.BusinessUnitId = BusinessUnits.Id
	INNER JOIN TimeZones
		ON BusinessUnits.StandardTimeZoneId = TimeZones.Id
	INNER JOIN ActivityForCollectionWorkLists 
	    ON Activities.Id = ActivityForCollectionWorkLists.Id
    INNER JOIN CollectionQueues 
	    ON CollectionWorkLists.CollectionQueueId = CollectionQueues.Id 
    INNER JOIN Customers 
	    ON CollectionWorkLists.CustomerId = Customers.Id
    INNER JOIN Parties
	    ON Customers.Id = Parties.Id
    INNER JOIN Currencies 
	    ON CollectionWorkLists.CurrencyId = Currencies.Id
    INNER JOIN CurrencyCodes 
	    ON Currencies.CurrencyCodeId = CurrencyCodes.Id 
	LEFT JOIN RemitToes
		ON #ElligibleCollectionWorkList.RemitToId=RemitToes.Id
	LEFT JOIN #PartyContactDetails PartyContact
		ON PartyContact.PartyId = Parties.Id AND PartyContact.Row_Num = 1
    LEFT JOIN Comments 
	    ON ActivityForCollectionWorkLists.CommentId = Comments.Id
	LEFT JOIN CollectionStatus  
	    ON Customers.CollectionStatusId = CollectionStatus.Id
    LEFT JOIN #InvoiceDetails 
	    ON CollectionWorkLists.Id = #InvoiceDetails.CollectionWorkListId
    LEFT JOIN #ReceiptAllocationDetails 
	    ON CollectionWorkLists.Id = #ReceiptAllocationDetails.CollectionWorkListId ';

  SET @WhereStatement = @WhereStatement +
    ' Activities.CloseFollowUp = 0 
	  AND Activities.IsActive = 1
      AND Activities.IsFollowUpRequired = 1
	  AND OwnerId = '+  Convert(NVARCHAR,@FollowupUserId);

  DECLARE @SelectQuery NVARCHAR(Max) = CAST('' AS NVARCHAR(MAX)) + ' 
	
  DECLARE @Count BIGINT = (	
    SELECT  
         COUNT(CollectionWorkLists.Id)
    FROM ' 
	+ @JoinStatement +
	'
    WHERE '+ @WhereStatement + '
	) ;
	
    SELECT
	    CollectionWorkLists.Id CollectionWorkListId 
	   ,FORMAT(ISNULL(PartyContact.LocalTime, @SystemDateTimeOffset AT TIME ZONE TimeZones.Name), ''hh:mm tt'') + '' '' + ISNULL(PartyContact.TimeZoneAbbreviation, TimeZones.Abbreviation) LocalTime
       ,Parties.PartyName                        
	   ,PartyContact.FullName PrimaryContact                  
	   ,CollectionStatus.Name CollectionStatusName 
       ,CollectionQueues.Name CollectionQueueName
	   ,Activities.FollowUpDate FollowupDateAndTime
	   ,[dbo].[GetTextFromHtml](Comments.Body) FollowupComments
	   ,SubActivityType LastCollectionActivityOutcome
	   ,#ReceiptAllocationDetails.TotalUnAllocatedBalance_Amount    UnallocatedBalance_Amount
	   ,CurrencyCodes.ISO   UnallocatedBalance_Currency
	   ,#InvoiceDetails.TotalPastDueAmount         PastDueAmount_Amount 
	   ,CurrencyCodes.ISO       PastDueAmount_Currency
	   ,@Count TotalWorkLists
	   ,CASE WHEN RemitToes.Name IS NULL THEN @NoValue ELSE @YesValue END AS IsPrivateLabel
	   ,CASE WHEN RemitToes.Name IS NULL THEN @NoValue ELSE @YesValue + ''('' + RemitToes.Name + '')'' END as PrivateLabel 
    FROM 
	    ' 
	+ @JoinStatement +
	'
	WHERE  '+ @WhereStatement + '
	ORDER BY '+ @OrderStatement + 
	CASE WHEN @EndingRowNumber > 0
	     THEN
	        ' OFFSET @SkipCount ROWS FETCH NEXT @TakeCount ROWS ONLY ;' 
         ELSE 
		    ';'  
	END

EXEC sp_executesql @SelectQuery,N'@TakeCount BIGINT,@SkipCount BIGINT,@SystemDateTimeOffset DATETIMEOFFSET,@YesValue NVARCHAR(10),@NoValue NVARCHAR(10)',
				   @TakeCount,@SkipCount,@SystemDateTimeOffset,@YesValue,@NoValue

    DROP TABLE #InvoiceDetails
	DROP TABLE #ReceiptAllocationDetails
	DROP TABLE #ElligibleCollectionWorkList
	DROP TABLE #PartyContactDetails
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[GetCollectionWorkLists]
(
    @CollectorId					BIGINT,
	@PortfolioId					BIGINT,
	@ShowAllAccounts				BIT,
	@ShowUnAssignedAccounts			BIT,
	@ShowMyWorkedAccounts			BIT,
	@ShowMyAccounts					BIT,
	@CurrentBusinessDate			DATETIME,
	@CalculatedWorkDate				DATETIME,
	@WorkedAccountsFilter			NVARCHAR(20),
	@CollectionWorklistStatusOpen	NVARCHAR(20),
	@CollectionWorklistStatusHibernation NVARCHAR(20),
	@ReceivableEntityTypeCT			NVARCHAR(2),
	@ReceiptEntityTypeLease			NVARCHAR(20),
	@ReceiptEntityTypeLoan			NVARCHAR(20),
	@ReceiptClassificationNonCash	NVARCHAR(23),
	@ReceiptClassificationNonAccrualNonDSLNonCash NVARCHAR(23),
	@ReceiptStatusPosted			NVARCHAR(15),
	@ReceiptStatusInactive			NVARCHAR(20),
	@ReceiptStatusReversed			NVARCHAR(20),
	@MyWorkedAccountsFilterToday	NVARCHAR(20),
	@MyWorkedAccountsFilterYesterday NVARCHAR(20),
	@MyWorkedAccountsFilterLast7Days NVARCHAR(20),
	@SystemDateTimeOffset			DATETIMEOFFSET,
	@YesValue                       NVARCHAR(10),
	@NoValue						NVARCHAR(10),
	@PartyContactTypePreference		PartyContactTypePreference READONLY,
	@FilteredCollectionWorkList		FilteredCollectionWorkList READONLY,
	@StartingRowNumber				INT,
	@EndingRowNumber				INT,
	@Keyword						NVARCHAR(MAX) = NULL,
	@SubActivityTypeValuesCSV		NVARCHAR(MAX) = NULL,
	@ActivityOutcome				NVARCHAR(34) = NULL,
	@MyActivityOutcome				NVARCHAR(34) = NULL,
	@FromActivityDate				DATETIMEOFFSET = NULL,
	@ToActivityDate					DATETIMEOFFSET = NULL,
	@FromMyActivityDate				DATETIMEOFFSET = NULL,
	@ToMyActivityDate				DATETIMEOFFSET = NULL,
	@FromInvoiceDueDate				DATETIME = NULL,
	@ToInvoiceDueDate				DATETIME = NULL,
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

   CREATE CLUSTERED INDEX #CollectionWorkLisId_ID ON #ElligibleCollectionWorkList(CollectionWorkListId)
   CREATE INDEX #CollectionWorkLisId_CustomerId ON #ElligibleCollectionWorkList(CustomerId)

   DECLARE @HasFilteredRecords BIT = 0;
   
   IF EXISTS(Select top 1 * from  @FilteredCollectionWorkList)
		SET @HasFilteredRecords = 1;  


   INSERT INTO #ElligibleCollectionWorkList
   SELECT 
     CollectionWorkLists.Id CollectionWorkListId,
	 CustomerId,
	 CurrencyId,
	 RemitToId
   FROM 
     CollectionWorkLists
	 LEFT JOIN @FilteredCollectionWorkList FilteredList ON CollectionWorkLists.Id = FilteredList.CollectionWorkListId
   WHERE 
	 (@HasFilteredRecords = 0 OR FilteredList.CollectionWorkListId IS NOT NULL)
	 AND  PortfolioId = @PortfolioId 
	 AND 
	 ( (@ShowAllAccounts = 1 AND Status IN (@CollectionWorklistStatusOpen,@CollectionWorklistStatusHibernation))
	   OR (@ShowUnAssignedAccounts = 1 AND PrimaryCollectorId IS NULL AND Status = @CollectionWorklistStatusOpen)
	   OR (@ShowMyWorkedAccounts = 1 AND Status = @CollectionWorklistStatusHibernation AND PrimaryCollectorId = @CollectorId 
		  AND ((@WorkedAccountsFilter = @MyWorkedAccountsFilterToday AND CAST(FlagAsWorkedOn AS DATE) = CAST(@CalculatedWorkDate AS DATE))
			  OR (@WorkedAccountsFilter = @MyWorkedAccountsFilterYesterday AND CAST(FlagAsWorkedOn AS DATE) < CAST(@CurrentBusinessDate AS DATE) AND CAST(FlagAsWorkedOn AS DATE) >= CAST(@CalculatedWorkDate AS DATE))
			  OR (@WorkedAccountsFilter = @MyWorkedAccountsFilterLast7Days AND CAST(FlagAsWorkedOn AS DATE) <= CAST(@CurrentBusinessDate AS DATE) AND CAST(FlagAsWorkedOn AS DATE) > CAST(@CalculatedWorkDate AS DATE))
			  )
		  )
	   OR (@ShowMyAccounts = 1 AND PrimaryCollectorId = @CollectorId AND Status = @CollectionWorklistStatusOpen)
	 )
  
  CREATE TABLE #InvoiceDetails
  (
     CollectionWorkListId  BIGINT,
	 CustomerId            BIGINT,
	 TotalPastDueAmount    Decimal(18,2) NULL,
	 OldestDueDate         DATETIME NULL,
	 OverAllDPD            BIGINT
  );

	INSERT INTO #InvoiceDetails
	SELECT * FROM
	(
	SELECT 
		 CollectionWorkListContractDetails.CollectionWorkListId
		,#ElligibleCollectionWorkList.CustomerId
		,SUM(ReceivableInvoiceDetails.Balance_Amount + ReceivableInvoiceDetails.TaxBalance_Amount) TotalPastDueAmount
		,Min(CASE WHEN ReceivableInvoiceDetails.Balance_Amount > 0.00 OR ReceivableInvoiceDetails.TaxBalance_Amount > 0.00 THEN ReceivableInvoices.DueDate ELSE NULL END) OldestDueDate
		,MAX(CASE WHEN ReceivableInvoiceDetails.Balance_Amount > 0.00 OR ReceivableInvoiceDetails.TaxBalance_Amount > 0.00 THEN ReceivableInvoices.DaysLateCount ELSE 0 END) MaxOverAllDPD
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
		   ReceivableInvoiceDetails.IsActive=1 AND 
		   ReceivableInvoices.IsActive=1
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
		CollectionWorkListContractDetails.CollectionWorkListId, #ElligibleCollectionWorkList.CustomerId
	)
	AS InvoiceInfo
	WHERE (@FromPastDueAmount IS NULL OR TotalPastDueAmount >= @FromPastDueAmount)
		AND (@ToPastDueAmount IS NULL OR TotalPastDueAmount <= @ToPastDueAmount)
		AND (@FromInvoiceDueDate IS NULL OR OldestDueDate >= @FromInvoiceDueDate)
		AND (@ToInvoiceDueDate IS NULL OR OldestDueDate <= @ToInvoiceDueDate)
		

    CREATE TABLE #ReceiptAllocationDetails
	(
       CollectionWorkListId			  BIGINT,
	   TotalUnAllocatedBalance_Amount Decimal(18,2) NULL
    );
	

	CREATE TABLE #UnAppliedReceipts
	(
		CollectionWorkListId BIGINT,
		ReceiptId BIGINT,
		Balance_Amount DECIMAL(18, 2)
	);

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
			,SUM(Balance_Amount) TotalUnAllocatedBalance
		FROM 
			#UnAppliedReceipts
		GROUP BY CollectionWorkListId;


    CREATE TABLE #CustomerLevelDetails
	( 
	  CustomerId				BIGINT,
	  TotalPastDueAmount_Amount Decimal(18,2) NULL,
	  OverAllDPD				BIGINT
    );
	
	INSERT INTO #CustomerLevelDetails
	SELECT 
	     #InvoiceDetails.CustomerId
		,SUM(TotalPastDueAmount) TotalPastDueAmount
		,Max(OverAllDPD) OverAllDPD
    FROM 
	    #InvoiceDetails 
    GROUP BY #InvoiceDetails.CustomerId 

	CREATE TABLE #CollectionWorkListActivities  
	(   
	   Id BIGINT IDENTITY(1,1) NOT NULL,
	   CollectionWorkListId  BIGINT NOT NULL, 
	   ActivityOutcome NVARCHAR(17) NOT NULL,  
	   ActivityUserId BIGINT NOT NULL,  
	   ActivityTime DATETIMEOFFSET NOT NULL
	); 

	CREATE TABLE #LastCollectionWorkListActivities  
	(   
	   CollectionWorkListId  BIGINT NOT NULL, 
	   LastCollectionActivityOutcome NVARCHAR(17) NOT NULL,
	   LastCollectionActivityDate DATETIMEOFFSET NOT NULL,  
	   MyLastCollectionActivityDate DATETIMEOFFSET NULL,
	   MyLastCollectionActivityOutcome NVARCHAR(17) NULL
	);  

	INSERT INTO #CollectionWorkListActivities
	SELECT 
		ActivityForCollectionWorkLists.CollectionWorkListId, 
		ActivityForCollectionWorkLists.SubActivityType AS ActivityOutcome,
		ISNULL(Activities.UpdatedById,Activities.CreatedById) AS ActivityUserId, 
		ISNULL(Activities.UpdatedTime,Activities.CreatedTime) AS ActivityTime
    FROM Activities
	INNER JOIN ActivityForCollectionWorkLists
		 ON Activities.Id = ActivityForCollectionWorkLists.Id 
	INNER JOIN #ElligibleCollectionWorkList 
	    ON ActivityForCollectionWorkLists.CollectionWorkListId = #ElligibleCollectionWorkList.CollectionWorkListId
	WHERE 
		Activities.IsActive = 1
	ORDER BY ActivityTime ASC

	INSERT INTO #LastCollectionWorkListActivities
	SELECT 
		#CollectionWorkListActivities.CollectionWorkListId,
		#CollectionWorkListActivities.ActivityOutcome AS LastCollectionActivityOutcome,
		#CollectionWorkListActivities.ActivityTime AS LastCollectionActivityDate,
		NULL,
		NULL 
	FROM #CollectionWorkListActivities
	INNER JOIN (
			SELECT CollectionWorkListId, MAX(Id) AS Id FROM #CollectionWorkListActivities
			GROUP BY CollectionWorkListId
		) AS LatestActivity
	ON #CollectionWorkListActivities.Id = LatestActivity.Id
	WHERE (@ActivityOutcome IS NULL OR (#CollectionWorkListActivities.ActivityOutcome LIKE '%' + @ActivityOutcome + '%'))
		AND (@FromActivityDate IS NULL OR #CollectionWorkListActivities.ActivityTime >= @FromActivityDate)
		AND (@ToActivityDate IS NULL OR #CollectionWorkListActivities.ActivityTime <= @ToActivityDate)

	
	
	IF(@ShowMyWorkedAccounts = 1)
	BEGIN 

		UPDATE #LastCollectionWorkListActivities
			SET 
				MyLastCollectionActivityDate = #CollectionWorkListActivities.ActivityTime,
				MyLastCollectionActivityOutcome = #CollectionWorkListActivities.ActivityOutcome
			FROM #LastCollectionWorkListActivities
			INNER JOIN 
			(
				SELECT CollectionWorkListId, 
						MAX(Id) AS Id 
					FROM #CollectionWorkListActivities
				WHERE ActivityUserId = @CollectorId
				GROUP BY CollectionWorkListId
			) AS MyLatestActivity
				ON #LastCollectionWorkListActivities.CollectionWorkListId = MyLatestActivity.CollectionWorkListId
			INNER JOIN #CollectionWorkListActivities
				ON MyLatestActivity.Id = #CollectionWorkListActivities.Id
			WHERE (@MyActivityOutcome IS NULL OR (#CollectionWorkListActivities.ActivityOutcome LIKE '%' + @MyActivityOutcome + '%'))
				AND (@FromMyActivityDate IS NULL OR #CollectionWorkListActivities.ActivityTime >= @FromMyActivityDate)
				AND (@ToMyActivityDate IS NULL OR #CollectionWorkListActivities.ActivityTime <= @ToMyActivityDate)

	END
	

	
	SELECT ROW_NUMBER() OVER(PARTITION BY PartyId ORDER BY PartyContactType.Id DESC, PartyContacts.CreatedTime) Row_Num,
		   PartyId, FullName, 
		   @SystemDateTimeOffset AT TIME ZONE TimeZones.Name PartyContactLocalTime,
		   TimeZones.Abbreviation PartyContactTimeZoneAbbreviation,
		   FORMAT(PartyContacts.BusinessStartTimeInHours, '00') + ':' + FORMAT(PartyContacts.BusinessStartTimeInMinutes, '00') + ':00' AS PartyContactBusinessStartTime,
		   FORMAT(PartyContacts.BusinessEndTimeInHours, '00') + ':' + FORMAT(PartyContacts.BusinessEndTimeInMinutes, '00') + ':00' AS PartyContactBusinessEndTime,
		   @SystemDateTimeOffset AT TIME ZONE BusinessUnitTimeZones.Name BusinessUnitLocalTime,
		   BusinessUnitTimeZones.Abbreviation BusinessUnitTimeZoneAbbreviation,
		   FORMAT(BusinessUnits.BusinessStartTimeInHours, '00') + ':' + FORMAT(BusinessUnits.BusinessStartTimeInMinutes, '00') + ':00' AS BusinessUnitBusinessStartTime,
		   FORMAT(BusinessUnits.BusinessEndTimeInHours, '00') + ':' + FORMAT(BusinessUnits.BusinessEndTimeInMinutes, '00') + ':00' AS BusinessUnitBusinessEndTime,
		   CASE WHEN 
			(PartyContacts.TimeZoneId IS NULL OR (PartyContacts.BusinessStartTimeInHours = 0 AND PartyContacts.BusinessStartTimeInMinutes = 0 AND
			PartyContacts.BusinessEndTimeInHours = 0 AND PartyContacts.BusinessEndTimeInMinutes = 0 ))
			THEN 1 ELSE 0 END ConsiderBusinessUnitTimeZone,
		   CAST(0 AS BIT) SortOrder,
		   CAST(0 AS BIT) IsDND
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
	WHERE PartyContacts.IsActive = 1
   AND ( PartyContactTypes.Id IS NULL OR  PartyContactTypes.IsActive=1)

	ALTER TABLE #PartyContactDetails add LocalTime DateTimeOffset
	ALTER TABLE #PartyContactDetails add TimeZoneAbbreviation NVARCHAR(10)
	ALTER TABLE #PartyContactDetails add BusinessStartTime NVARCHAR(100)
	ALTER TABLE #PartyContactDetails add BusinessEndTime NVARCHAR(100)


	UPDATE #PartyContactDetails 
	SET LocalTime = (CASE WHEN ConsiderBusinessUnitTimeZone = 1 THEN BusinessUnitLocalTime ELSE PartyContactLocalTime END),
		TimeZoneAbbreviation = (CASE WHEN ConsiderBusinessUnitTimeZone = 1 THEN BusinessUnitTimeZoneAbbreviation ELSE PartyContactTimeZoneAbbreviation END),
	    BusinessStartTime = (CASE WHEN ConsiderBusinessUnitTimeZone = 1 THEN BusinessUnitBusinessStartTime ELSE PartyContactBusinessStartTime END),
        BusinessEndTime = (CASE WHEN ConsiderBusinessUnitTimeZone = 1 THEN BusinessUnitBusinessEndTime ELSE PartyContactBusinessEndTime END)

	UPDATE #PartyContactDetails 
	SET SortOrder = CASE WHEN CONVERT(NVARCHAR(5), LocalTime, 8) BETWEEN '00:00' AND BusinessEndTime THEN 0 ELSE 1 END,
		IsDND = CASE WHEN CONVERT(NVARCHAR(5), LocalTime, 8) BETWEEN BusinessStartTime AND BusinessEndTime THEN 0 ELSE 1 END


      ------------- DYNAMIC QUERY ----------	
   DECLARE @SkipCount BIGINT
   DECLARE @TakeCount BIGINT
   DECLARE @WhereClause NVARCHAR(MAX) = '';

   SET @SubActivityTypeValuesCSV = '''' + REPLACE(@SubActivityTypeValuesCSV, ',', ''',''') + '''';	

   SET @SkipCount = @StartingRowNumber - 1;

   SET @TakeCount = @EndingRowNumber - @StartingRowNumber + 1;
    

	IF(@Keyword IS NOT NULL)
	BEGIN
		SET @WhereClause = @WhereClause + '(' + 
											'(Parties.PartyName LIKE ''%' +  @Keyword + '%'')' +
											' OR (PartyContact.FullName LIKE ''%' +  @Keyword + '%'') ' +
											' OR (CollectionStatus.Name LIKE ''%' +  @Keyword + '%'') ' +
											' OR (CollectionQueues.Name LIKE ''%' +  @Keyword + '%'') ';

		SET @WhereClause = @WhereClause + CASE WHEN (@ShowAllAccounts = 1) THEN ' OR (Users.LoginName LIKE ''%' +  @Keyword + '%'')' 
											   WHEN (@ShowMyWorkedAccounts = 1) THEN ' OR (#LastCollectionWorkListActivities.LastCollectionActivityOutcome IN (' + @SubActivityTypeValuesCSV + '))'
											   ELSE '' END;

		SET @WhereClause = @WhereClause + ') AND ';

	END


	DECLARE @HasInvoiceSearchData BIT = CASE WHEN (@FromPastDueAmount IS NOT NULL OR @ToPastDueAmount IS NOT NULL OR @FromInvoiceDueDate IS NOT NULL AND @ToInvoiceDueDate IS NOT NULL) THEN 1 ELSE 0 END;
	DECLARE @HasActivitySearchData BIT = CASE WHEN (@ActivityOutcome IS NOT NULL OR @FromActivityDate IS NOT NULL OR @ToActivityDate IS NOT NULL) THEN 1 ELSE 0 END;
	DECLARE @HasMyLastActivitySearchData BIT = CASE WHEN (@FromMyActivityDate IS NOT NULL OR @ToMyActivityDate IS NOT NULL) THEN 1 ELSE 0 END;
	DECLARE @HasMyLastActivityOutComeSearchData BIT = CASE WHEN(@MyActivityOutcome IS NOT NULL) THEN 1 ELSE 0 END;

	IF(@HasInvoiceSearchData = 1)
	BEGIN
		SET @WhereClause = @WhereClause + ' (#InvoiceDetails.CollectionWorkListId IS NOT NULL) AND '
	END 

	IF(@HasActivitySearchData = 1)
	BEGIN
		SET @WhereClause = @WhereClause + ' (#LastCollectionWorkListActivities.CollectionWorkListId IS NOT NULL) AND '
	END

	IF(@HasMyLastActivitySearchData = 1)
	BEGIN
		SET @WhereClause = @WhereClause + ' (#LastCollectionWorkListActivities.CollectionWorkListId IS NOT NULL AND #LastCollectionWorkListActivities.MyLastCollectionActivityDate IS NOT NULL) AND '
	END

	IF(@HasMyLastActivityOutComeSearchData = 1)
	BEGIN
		SET @WhereClause = @WhereClause + ' (#LastCollectionWorkListActivities.CollectionWorkListId IS NOT NULL AND #LastCollectionWorkListActivities.MyLastCollectionActivityOutcome IS NOT NULL) AND '
	END

  DECLARE @OrderStatement NVARCHAR(MAX) =  
  CASE 
	WHEN @OrderColumn='PartyName' THEN 'PartyName' + ' ' + @OrderBy
	WHEN @OrderColumn='CollectionQueueName' THEN 'CollectionQueueName'  + ' ' + @OrderBy
	WHEN @OrderColumn='PrimaryContact' THEN 'PrimaryContact'  + ' ' + @OrderBy
	WHEN @OrderColumn='PrimaryCollectionOfficer' THEN 'PrimaryCollectionOfficer'  + ' ' + @OrderBy
	WHEN @OrderColumn='CollectionStatusName' THEN 'CollectionStatusName'  + ' ' + @OrderBy
	WHEN @OrderColumn='LastCollectionActivityOutcome.Value' THEN 'LastCollectionActivityOutcome'  + ' ' + @OrderBy
	WHEN @OrderColumn='LastCollectionActivityDate' THEN 'LastCollectionActivityDate'  + ' ' + @OrderBy
	WHEN @OrderColumn='MyLastCollectionActivityDate' THEN 'MyLastCollectionActivityDate'  + ' ' + @OrderBy
	WHEN @OrderColumn='InvoiceDueDate' THEN 'InvoiceDueDate'  + ' ' + @OrderBy
	WHEN @OrderColumn='PastDueAmount.Amount' THEN 'PastDueAmount_Amount'  + ' ' + @OrderBy
	WHEN @OrderColumn='PastDueAmount.Currency' THEN 'PastDueAmount_Amount'  + ' ' + @OrderBy
	WHEN @OrderColumn='UnallocatedBalance.Amount' THEN 'UnallocatedBalance_Amount' + ' ' + @OrderBy
	WHEN @OrderColumn='UnallocatedBalance.Currency' THEN 'UnallocatedBalance_Amount' + ' ' + @OrderBy
	WHEN @OrderColumn='LocalTime' THEN 'CONVERT(NVARCHAR(5), ISNULL(PartyContact.LocalTime, @SystemDateTimeOffset), 8)'  + ' ' + @OrderBy
	WHEN @OrderColumn='DaysPastDue' THEN 'CustomerOverallDPD DESC,PartyName ASC,#InvoiceDetails.OverAllDPD DESC' 
	WHEN @OrderColumn='OverdueAmount' THEN 'CustomerTotalPastDueAmount DESC,PartyName ASC,#InvoiceDetails.TotalPastDueAmount DESC'
	WHEN @OrderColumn='TimeZone' THEN 'CASE WHEN PartyContact.SortOrder IS NOT NULL

									   THEN  
											PartyContact.SortOrder
									   ELSE 
											CASE WHEN (CONVERT(NVARCHAR(5), @SystemDateTimeOffset AT TIME ZONE TimeZones.Name, 8) BETWEEN 
											''00:00'' AND
												 FORMAT(BusinessUnits.BusinessEndTimeInHours, ''00'') + '':'' + FORMAT(BusinessUnits.BusinessEndTimeInMinutes, ''00''))
												 THEN 0 ELSE 1 END
									   END, 
									   CONVERT(NVARCHAR(5), ISNULL(PartyContact.LocalTime, @SystemDateTimeOffset AT TIME ZONE TimeZones.Name), 8) DESC,
									   CustomerTotalPastDueAmount DESC, PartyName ASC, #InvoiceDetails.TotalPastDueAmount DESC'
	WHEN @OrderColumn='PrivateLabel' THEN 'IsPrivateLabel ' + ' ' + @OrderBy + ' '+ ',PrivateLabel ' + ' '+ @OrderBy
  ELSE @OrderColumn  END

  DECLARE @CollectionWorkListsJoinStatement Nvarchar(MAX) =  
	'CollectionWorkLists 
	INNER JOIN #ElligibleCollectionWorkList 
	    ON CollectionWorkLists.Id = #ElligibleCollectionWorkList.CollectionWorkListId
    INNER JOIN CollectionQueues 
	    ON CollectionWorkLists.CollectionQueueId = CollectionQueues.Id ' 
	+
	 CASE WHEN @ShowUnAssignedAccounts=1
		 THEN 'INNER JOIN UserGroups 
	             ON CollectionQueues.PrimaryCollectionGroupId = UserGroups.Id
               INNER JOIN UsersInUserGroups 
	             ON UserGroups.Id = UsersInUserGroups.UserGroupId AND UsersInUserGroups.IsActive = 1 AND  UsersInUserGroups.UserId = '+  Convert(NVARCHAR,@CollectorId)
	     ELSE '' END
    +
   'INNER JOIN Customers 
	    ON CollectionWorkLists.CustomerId = Customers.Id
    INNER JOIN Parties
	    ON Customers.Id = Parties.Id
    INNER JOIN Currencies 
	    ON CollectionWorkLists.CurrencyId = Currencies.Id
    INNER JOIN CurrencyCodes 
	    ON Currencies.CurrencyCodeId = CurrencyCodes.Id
	INNER JOIN BusinessUnits
		ON CollectionWorkLists.BusinessUnitId = BusinessUnits.Id
	INNER JOIN TimeZones
		ON BusinessUnits.StandardTimeZoneId = TimeZones.Id
	LEFT JOIN RemitToes
		ON #ElligibleCollectionWorkList.RemitToId=RemitToes.Id
	LEFT JOIN #PartyContactDetails PartyContact
		ON PartyContact.PartyId = Parties.Id AND PartyContact.Row_Num = 1
  	LEFT JOIN Users 
	    ON CollectionWorkLists.PrimaryCollectorId = Users.Id 
    LEFT JOIN CollectionStatus  
	    ON Customers.CollectionStatusId = CollectionStatus.Id
    LEFT JOIN #InvoiceDetails 
	    ON CollectionWorkLists.Id = #InvoiceDetails.CollectionWorkListId
    LEFT JOIN #ReceiptAllocationDetails 
	    ON CollectionWorkLists.Id = #ReceiptAllocationDetails.CollectionWorkListId
    LEFT JOIN #CustomerLevelDetails 
	    ON CollectionWorkLists.CustomerId = #CustomerLevelDetails.CustomerId  
	LEFT JOIN #LastCollectionWorkListActivities	
		ON CollectionWorkLists.Id = #LastCollectionWorkListActivities.CollectionWorkListId ';

  DECLARE @SelectQuery NVARCHAR(Max) = CAST('' AS NVARCHAR(MAX)) + ' 
	
  DECLARE @Count BIGINT = (	
    SELECT  
         COUNT(CollectionWorkLists.Id)
    FROM ' 
	+ @CollectionWorkListsJoinStatement +
	'
    WHERE '+ @WhereClause + ' 1 = 1
	) ;
	
    SELECT
	    CollectionWorkLists.Id 
	   ,CollectionWorkLists.Id CollectionWorkListId 
	   ,CollectionWorkLists.CustomerId 
	   ,CollectionWorkLists.CollectionQueueId 
       ,Parties.PartyName                        
	   ,PartyContact.FullName PrimaryContact                   
	   ,CollectionStatus.Name CollectionStatusName 
       ,CollectionQueues.Name CollectionQueueName
	   ,Users.LoginName PrimaryCollectionOfficer
       ,FORMAT(ISNULL(PartyContact.LocalTime, @SystemDateTimeOffset AT TIME ZONE TimeZones.Name), ''hh:mm tt'') + '' '' + ISNULL(PartyContact.TimeZoneAbbreviation, TimeZones.Abbreviation) LocalTime
       ,#InvoiceDetails.OldestDueDate InvoiceDueDate
       ,#LastCollectionWorkListActivities.LastCollectionActivityDate 
	   ,#LastCollectionWorkListActivities.MyLastCollectionActivityDate
	   , #LastCollectionWorkListActivities.LastCollectionActivityOutcome   
	   ,#ReceiptAllocationDetails.TotalUnAllocatedBalance_Amount    UnallocatedBalance_Amount
	   ,CurrencyCodes.ISO   UnallocatedBalance_Currency
	   ,#InvoiceDetails.TotalPastDueAmount         PastDueAmount_Amount 
	   ,CurrencyCodes.ISO       PastDueAmount_Currency
	   ,#CustomerLevelDetails.OverallDPD CustomerOverallDPD               
	   ,#CustomerLevelDetails.TotalPastDueAmount_Amount CustomerTotalPastDueAmount  
	   ,@Count TotalWorkLists
	   ,CONVERT(BIT, CASE WHEN PartyContact.IsDND IS NOT NULL
			THEN  PartyContact.IsDND
			ELSE  CASE WHEN (CONVERT(NVARCHAR(5), @SystemDateTimeOffset AT TIME ZONE TimeZones.Name, 8) BETWEEN 
				 FORMAT(BusinessUnits.BusinessStartTimeInHours, ''00'') + '':'' + FORMAT(BusinessUnits.BusinessStartTimeInMinutes, ''00'') AND
				 FORMAT(BusinessUnits.BusinessEndTimeInHours, ''00'') + '':'' + FORMAT(BusinessUnits.BusinessEndTimeInMinutes, ''00''))
				 THEN 0 ELSE 1 END
			END) DoNotDisturb

	   ,CONVERT(BIT, CASE WHEN PartyContact.ConsiderBusinessUnitTimeZone = 0 THEN 1 ELSE 0 END) HasTimeZone
	   ,CAST(CASE WHEN RemitToes.Name IS NULL THEN 0 ELSE 1 END as bit) AS IsPrivateLabel
	   ,CASE WHEN RemitToes.Name IS NULL THEN @NoValue ELSE @YesValue + ''('' + RemitToes.Name + '')'' END as PrivateLabel
    FROM 
	    ' 
	+ @CollectionWorkListsJoinStatement +
	'
	WHERE '+ @WhereClause + ' 1 = 1 
	ORDER BY '+ @OrderStatement + 
	CASE WHEN @EndingRowNumber > 0
	     THEN
	        ' OFFSET @SkipCount ROWS FETCH NEXT @TakeCount ROWS ONLY ;' 
         ELSE 
		    ';'  
	END


	EXEC sp_executesql @SelectQuery,N'@TakeCount BIGINT,
						@SkipCount BIGINT,
						@SystemDateTimeOffset DATETIMEOFFSET,
						@YesValue NVARCHAR(10),
						@NoValue NVARCHAR(10)',
					   @TakeCount, 
					   @SkipCount, 
					   @SystemDateTimeOffset, 
					   @YesValue, 
					   @NoValue;
				     

	DROP TABLE #InvoiceDetails
	DROP TABLE #ReceiptAllocationDetails
	DROP TABLE #CustomerLevelDetails
	DROP TABLE #ElligibleCollectionWorkList 
	DROP TABLE #PartyContactDetails
END

GO

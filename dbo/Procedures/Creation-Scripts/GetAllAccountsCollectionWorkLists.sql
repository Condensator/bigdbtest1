SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[GetAllAccountsCollectionWorkLists]
(
    @CollectorId					BIGINT,
	@PortfolioId					BIGINT,
	@ShowAllAccounts				BIT,
	@CurrentBusinessDate			DATETIME,
	@CalculatedWorkDate				DATETIME,
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
	@SystemDateTimeOffset			DATETIMEOFFSET,
	@YesValue                       NVARCHAR(10),
	@NoValue						NVARCHAR(10),
	@AllAccountsPartyContactTypePreference		AllAccountsPartyContactTypePreference READONLY,
	@AllAccountsFilteredCollectionWorkList		AllAccountsFilteredCollectionWorkList READONLY,
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
   
   IF EXISTS(Select top 1 * from  @AllAccountsFilteredCollectionWorkList)
		SET @HasFilteredRecords = 1;  


   INSERT INTO #ElligibleCollectionWorkList
   SELECT 
     CollectionWorkLists.Id CollectionWorkListId,
	 CustomerId,
	 CurrencyId,
	 RemitToId
   FROM 
     CollectionWorkLists
	 LEFT JOIN @AllAccountsFilteredCollectionWorkList FilteredList ON CollectionWorkLists.Id = FilteredList.CollectionWorkListId
   WHERE 
	 (@HasFilteredRecords = 0 OR FilteredList.CollectionWorkListId IS NOT NULL)
	 AND  PortfolioId = @PortfolioId 
	 AND 
	 ( (@ShowAllAccounts = 1 AND Status IN (@CollectionWorklistStatusOpen,@CollectionWorklistStatusHibernation)))
  

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
		 LEFT JOIN @AllAccountsPartyContactTypePreference PartyContactType
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
											   ELSE '' END;

		SET @WhereClause = @WhereClause + ') AND ';

	END

	DECLARE @HasActivitySearchData BIT = CASE WHEN (@ActivityOutcome IS NOT NULL OR @FromActivityDate IS NOT NULL OR @ToActivityDate IS NOT NULL) THEN 1 ELSE 0 END;
	DECLARE @HasMyLastActivitySearchData BIT = CASE WHEN (@FromMyActivityDate IS NOT NULL OR @ToMyActivityDate IS NOT NULL) THEN 1 ELSE 0 END;
	DECLARE @HasMyLastActivityOutComeSearchData BIT = CASE WHEN(@MyActivityOutcome IS NOT NULL) THEN 1 ELSE 0 END;


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
	WHEN @OrderColumn='LocalTime' THEN 'CONVERT(NVARCHAR(5), ISNULL(PartyContact.LocalTime, @SystemDateTimeOffset), 8)'  + ' ' + @OrderBy
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
									   PartyName ASC'
	WHEN @OrderColumn='PrivateLabel' THEN 'IsPrivateLabel ' + ' ' + @OrderBy + ' '+ ',PrivateLabel ' + ' '+ @OrderBy
  ELSE '#ElligibleCollectionWorkList.CollectionWorkListId DESC'  END

  DECLARE @CollectionWorkListsJoinStatement Nvarchar(MAX) =  
	'CollectionWorkLists 
	INNER JOIN #ElligibleCollectionWorkList 
	    ON CollectionWorkLists.Id = #ElligibleCollectionWorkList.CollectionWorkListId
    INNER JOIN CollectionQueues 
	    ON CollectionWorkLists.CollectionQueueId = CollectionQueues.Id ' 
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
  
       ,#LastCollectionWorkListActivities.LastCollectionActivityDate 
	   ,#LastCollectionWorkListActivities.MyLastCollectionActivityDate
	   , #LastCollectionWorkListActivities.LastCollectionActivityOutcome   
	  
	   
	  
	  
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

				     
	DROP TABLE #ElligibleCollectionWorkList 
	DROP TABLE #PartyContactDetails
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetEntityActivitiesForDashBoard] 
(  
	@EntityNaturalId NVARCHAR(500),
	@EntitySummary NVARCHAR(1000),
	@EntityTypeId BIGINT,
	@loggedInUserId BIGINT,
	@currentSiteName NVARCHAR(50),
	@EntityActivitiesDashboardType NVARCHAR(50),
	@MyActivityType NVARCHAR(50),
	@UnassignedActivityType NVARCHAR(50),
	@PortfolioId bigint,
	@ADVWHERECLAUSE NVARCHAR(2000),
	@ORDERBYCLAUSE NVARCHAR(2000),
	@Start int,
	@End int
	)  
AS   
BEGIN
	SET NOCOUNT ON;

	CREATE TABLE #AccessibleActivities
	(
		Id BIGINT PRIMARY KEY,
		StatusId INT,
		OwnerId BIGINT,
		EntityActivitiesFilterType NVARCHAR(30)
	)

	CREATE TABLE #InAccessibleActivities
	(
		Id BIGINT PRIMARY KEY
	)

 	INSERT INTO #InAccessibleActivities
	SELECT DISTINCT Activities.Id
	FROM Activities
	INNER JOIN ActivityPermissions  on Activities.Id = ActivityPermissions.ActivityId
	LEFT JOIN ActivityTypes on Activities.ActivityTypeId = ActivityTypes.Id
	LEFT JOIN ActivityTypeSubSystemDetails on ActivityTypes.Id = ActivityTypeSubSystemDetails.ActivityTypeId
	LEFT JOIN SubSystemConfigs on ActivityTypeSubSystemDetails.SubSystemId = SubSystemConfigs.Id
	WHERE Activities.PortfolioId = @PortfolioId
	AND	(ActivityTypes.Id IS NULL OR (ActivityTypes.IsActive = 1 AND ActivityTypeSubSystemDetails.Viewable = 1 AND ActivityTypeSubSystemDetails.IsActive = 1 AND SubSystemConfigs.Name = @currentSiteName)) --Viewable Activities
	AND (ActivityPermissions.IsActive =1 AND ActivityPermissions.UserId = @loggedInUserId AND ActivityPermissions.Permission ='N')
 
	INSERT INTO #AccessibleActivities
	Select DISTINCT Activities.Id , Activities.StatusId, Activities.OwnerId, IIF(Activities.OwnerId = @loggedInUserId,@MyActivityType,@UnassignedActivityType)
	FROM Activities
	LEFT JOIN #InAccessibleActivities InAccessibleActivities on Activities.Id = InAccessibleActivities.Id
	LEFT JOIN ActivityTypes on Activities.ActivityTypeId = ActivityTypes.Id
	LEFT JOIN ActivityTypeSubSystemDetails on ActivityTypes.Id = ActivityTypeSubSystemDetails.ActivityTypeId
	LEFT JOIN SubSystemConfigs on ActivityTypeSubSystemDetails.SubSystemId = SubSystemConfigs.Id
	LEFT JOIN ActivityTransactionConfigs on ActivityTypes.TransactionTobeInitiatedId = ActivityTransactionConfigs.Id
	LEFT JOIN ActivityPermissions  on Activities.Id = ActivityPermissions.ActivityId
	WHERE InAccessibleActivities.Id IS NULL
	AND Activities.PortfolioId = @PortfolioId
    AND Activities.IsActive=1
	AND (ActivityTypes.Id IS NULL OR (ActivityTypes.IsActive = 1 and ActivityTypeSubSystemDetails.Viewable = 1 and ActivityTypeSubSystemDetails.IsActive = 1 and SubSystemConfigs.Name = @currentSiteName)) --Viewable Activities
	AND ((ActivityPermissions.IsActive=1 AND (ActivityPermissions.UserId = @loggedInUserId) AND ActivityPermissions.Permission !='N') OR (Activities.DefaultPermission!='N'))
	AND (ActivityTransactionConfigs.AutoCompleteActivity IS NULL OR ActivityTransactionConfigs.AutoCompleteActivity = 0 OR ActivityTransactionConfigs.AutoCompleteActivity = 1)--Includes Type 2,Type 4,,Type 3 (for which status can be changed manually)
	  
    SELECT 
		EntityHeaderId,
		EntityTypeName,
		TransactionOwnerName,
		CreatedDate,
		ActivityId,
		OwnerId,
		EntityActivitiesFilterType,
		EntityNaturalId,
		EntitySummary
   INTO #EntityActivityHeaders
   FROM 
   (
		SELECT 
			ROW_NUMBER()OVER(PARTITION BY e.Id,t.Id ORDER BY ti.Id) RowNumber,
			e.Id as EntityHeaderId, ec.UserFriendlyName as EntityTypeName, 
			u.FullName  as TransactionOwnerName, 
			CAST(ti.CreatedTime AS datetime) CreatedDate, 
			t.Id as ActivityId, 
			t.OwnerId,
			t.EntityActivitiesFilterType,
			e.EntityNaturalId,
			e.EntitySummary
		FROM EntityHeaders e 
		JOIN ActivityHeaders h on h.Id = e.Id
		JOIN ActivityLists l on h.Id = l.ActivityHeaderId
		JOIN #AccessibleActivities t on l.ActivityId = t.Id
		JOIN ActivityStatusConfigs ascfg on ascfg.Id = t.StatusId
		JOIN EntityConfigs ec on e.EntityTypeId = ec.Id
		LEFT JOIN TransactionInstances ti on e.EntityId = ti.EntityId AND ec.Name = ti.EntityName
		LEFT JOIN Users u on ti.CreatedById = u.Id
		WHERE (ascfg.IsEnd <> 1)
		AND (@EntityNaturalId IS NULL OR e.EntityNaturalId LIKE @EntityNaturalId)
		AND (@EntitySummary IS NULL OR e.EntitySummary LIKE @EntitySummary)
		AND (@EntityTypeId=0 OR e.EntityTypeId = @EntityTypeId)
		) AS T
	WHERE RowNumber=1 
	AND (EntityActivitiesFilterType=@EntityActivitiesDashboardType OR @EntityActivitiesDashboardType='_')
	  
  DECLARE @SQLStatement NVARCHAR(MAX)=N'
	  DECLARE @TotalRecordCount bigint;
	  ;WITH CTE_MyOpenActivityCount AS
	  (
	  SELECT 
	    MyOpenActivityCount=count(EntityActivityHeaders.ActivityId),
		EntityActivityHeaders.EntityHeaderId
	  FROM #EntityActivityHeaders EntityActivityHeaders 
	  WHERE EntityActivityHeaders.OwnerId=@loggedInUserId
	  GROUP BY EntityActivityHeaders.EntityHeaderId
	  )
	  ,CTE_UnassignedOpenActivityCount AS
	  (
	   SELECT 
			UnassignedOpenActivityCount=count(EntityActivityHeaders.ActivityId),
			EntityActivityHeaders.EntityHeaderId
	   FROM #EntityActivityHeaders EntityActivityHeaders 
	   WHERE EntityActivityHeaders.OwnerId IS NULL
	   GROUP BY EntityActivityHeaders.EntityHeaderId
	  ),
	  CTE_IsUnRead AS
	  (
		SELECT DISTINCT e.EntityHeaderId 
		FROM #EntityActivityHeaders e
		JOIN ActivityHeaders h on h.Id = e.EntityHeaderId
		JOIN ActivityLists l on h.Id = l.ActivityHeaderId 
		JOIN #AccessibleActivities t on l.ActivityId = t.Id
		JOIN ActivityUserPreferences U ON t.Id = U.ActivityId 
			AND U.UserId = @loggedInUserId
			AND U.IsRead = 0
		WHERE t.OwnerId = @loggedInUserId
	  )		   
	  SELECT *,	ROW_NUMBER() OVER(ORDER BY ORDERBYCLAUSE) RowNumber INTO #EntityHeaderDetails 
	  FROM 
		  (SELECT
			  DISTINCT
				#EntityActivityHeaders.EntityHeaderId as Id
			  , #EntityActivityHeaders.EntityHeaderId as EntityHeaderId
			  , #EntityActivityHeaders.EntityTypeName
			  , #EntityActivityHeaders.TransactionOwnerName
			  , #EntityActivityHeaders.CreatedDate
			  , #EntityActivityHeaders.EntityNaturalId
			  , #EntityActivityHeaders.EntitySummary
			  , ISNULL(CTE_MyOpenActivityCount.MyOpenActivityCount,0) MyOpenActivityCount
			  , ISNULL(CTE_UnassignedOpenActivityCount.UnassignedOpenActivityCount,0) UnassignedOpenActivityCount
			  , CASE WHEN CTE_IsUnRead.EntityHeaderId IS NOT NULL THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT)  END IsUnreadActivity
		  FROM 
		   #EntityActivityHeaders
		   LEFT JOIN CTE_IsUnRead ON #EntityActivityHeaders.EntityHeaderId = CTE_IsUnRead.EntityHeaderId
		   LEFT JOIN CTE_MyOpenActivityCount ON #EntityActivityHeaders.EntityHeaderId=  CTE_MyOpenActivityCount.EntityHeaderId
		   LEFT JOIN CTE_UnassignedOpenActivityCount ON #EntityActivityHeaders.EntityHeaderId=  CTE_UnassignedOpenActivityCount.EntityHeaderId) AS T
	WHERE ADVWHERECLAUSE 1=1;

	SELECT @TotalRecordCount = COUNT(1) FROM #EntityHeaderDetails

	SELECT *, @TotalRecordCount as TotalRecordCount
	FROM  #EntityHeaderDetails WHERE Rownumber BETWEEN @Start AND @End 
	ORDER BY RowNumber;';

SET @SQLStatement = REPLACE(@SQLStatement,'ORDERBYCLAUSE',@ORDERBYCLAUSE) 
SET @SQLStatement = REPLACE(@SQLStatement,'ADVWHERECLAUSE',@ADVWHERECLAUSE) 

EXEC sp_executesql @SQLStatement, N'
	  @Start int  
	, @End int
	, @loggedInUserId BIGINT'
	, @Start  
	, @End
	, @loggedInUserId 
END

GO

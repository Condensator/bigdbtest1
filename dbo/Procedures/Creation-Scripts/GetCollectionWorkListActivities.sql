SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetCollectionWorkListActivities]
(
	@CollectionWorkListId					BIGINT,	
	@CustomerId								BIGINT,
	@LoggedInUserId							BIGINT, 
    @CurrentPortfolioId						BIGINT,
	@IsActivityWidget						BIT,
	@IsFromFollowUpWorkList					BIT,
    @CurrentSite							NVARCHAR(14),
	@NoAccessPermission						NVARCHAR(2),
	@StartingRowNumber						INT,
	@EndingRowNumber						INT,
	@OrderBy								NVARCHAR(6),
	@OrderColumn							NVARCHAR(MAX),
	@Keyword								NVARCHAR(MAX) = NULL,
	@ActivityTypeName						NVARCHAR(250) = NULL,
	@SubActivityType						NVARCHAR(17) = NULL,
	@CreatedByUser							NVARCHAR(250) = NULL,
	@SubActivityTypeValueCSV				NVARCHAR(MAX),
	@CommentBody							NVARCHAR(250) = NULL,
	@IsFollowUpClosed						BIT = NULL,
	@PersonContacted						NVARCHAR(250) = NULL,
	@FollowUpUser							NVARCHAR(250) = NULL,
	@FromFollowUpDate						DATE = NULL,
	@ToFollowUpDate							DATE = NULL
)
AS
SET NOCOUNT ON
BEGIN

		CREATE TABLE #CollectionWorkListActivities
		(
			ActivityId BIGINT NOT NULL,
			SubActivityType NVARCHAR(17) NOT NULL,
			CommentId BIGINT NULL,
			PersonContactedId BIGINT NULL,
			IsCurrentWorkList BIT NOT NULL		
		);

		INSERT INTO #CollectionWorkListActivities
		SELECT 
			DISTINCT
			Activities.Id ActivityId,
			ActivityForCollectionWorkLists.SubActivityType,
			ActivityForCollectionWorkLists.CommentId,
			ActivityForCollectionWorkLists.PersonContactedId,
			CASE WHEN 
					CollectionWorkLists.Id = @CollectionWorkListId 
						THEN CAST(1 AS BIT)
						ELSE CAST(0 AS BIT) END AS IsCurrentWorkList
		FROM Activities
		INNER JOIN ActivityForCollectionWorkLists
			ON ActivityForCollectionWorkLists.Id = Activities.Id
		INNER JOIN CollectionWorkLists
			ON CollectionWorkLists.Id = ActivityForCollectionWorkLists.CollectionWorkListId
		LEFT JOIN ActivityPermissions
			ON ActivityPermissions.ActivityId = Activities.Id
			AND ActivityPermissions.IsActive = 1
			AND ActivityPermissions.UserId = @LoggedInUserId
		WHERE
			 Activities.PortfolioId = @CurrentPortfolioId      
			 AND CollectionWorkLists.CustomerId = @CustomerId
			 AND (Activities.DefaultPermission !=  @NoAccessPermission 
				OR ActivityPermissions.Permission !=  @NoAccessPermission)
			 AND (@IsActivityWidget = 0 OR @IsFromFollowUpWorkList = 0
			 OR (Activities.IsFollowUpRequired = 1 AND Activities.OwnerId = @LoggedInUserId 
			    AND Activities.CloseFollowUp = 0 ))

		CREATE TABLE #ViewableActivityTypeIds (Id BIGINT NOT NULL PRIMARY KEY);

		INSERT INTO #ViewableActivityTypeIds
		SELECT 
			DISTINCT ActivityTypes.Id
		FROM ActivityTypes
		JOIN ActivityTypeSubSystemDetails 
			ON ActivityTypes.Id = ActivityTypeSubSystemDetails.ActivityTypeId
		JOIN SubSystemConfigs 
			ON ActivityTypeSubSystemDetails.SubSystemId = SubSystemConfigs.Id
		WHERE
			(ActivityTypes.PortfolioId IS NULL OR ActivityTypes.PortfolioId = @CurrentPortfolioId)
			AND SubSystemConfigs.Name = @CurrentSite
			AND ActivityTypeSubSystemDetails.Viewable = 1;			  
			
--------DYNAMIC QUERY------------------

	DECLARE @SkipCount BIGINT;
    DECLARE @TakeCount BIGINT;
	DECLARE @DefaultOrderColumn NVARCHAR(MAX);

	SET @SubActivityTypeValueCSV = '''' + REPLACE(@SubActivityTypeValueCSV, ',', ''',''') + '''';	


	SET @DefaultOrderColumn = 
			CASE WHEN @IsActivityWidget = 1 AND @IsFromFollowUpWorkList = 0  THEN 'IsActive desc,IsCurrentWorkList desc,CreatedTime desc'
                 WHEN @IsActivityWidget = 1 AND @IsFromFollowUpWorkList = 1  THEN 'IsActive desc,IsCurrentWorkList desc,FollowUpDate asc,CreatedTime desc'
				 WHEN @IsActivityWidget = 0  THEN 'IsActive desc,CreatedTime desc'
			END


  DECLARE @ActivityJoinStatement Nvarchar(MAX) =  
	'	Activities
		JOIN #CollectionWorkListActivities
			ON Activities.Id = #CollectionWorkListActivities.ActivityId
		JOIN #ViewableActivityTypeIds
			ON Activities.ActivityTypeId = #ViewableActivityTypeIds.Id
		JOIN ActivityTypes
			ON Activities.ActivityTypeId = ActivityTypes.Id
		JOIN Users
			ON Activities.CreatedById = Users.Id
		LEFT JOIN Comments
			ON #CollectionWorkListActivities.CommentId = Comments.Id
		LEFT JOIN PartyContacts
			ON #CollectionWorkListActivities.PersonContactedId = PartyContacts.Id
		LEFT JOIN Users FollowUpUser
			ON Activities.OwnerId = FollowUpUser.Id
			AND Activities.IsFollowUpRequired = 1 ' 

	 DECLARE @WhereClause NVARCHAR(MAX)=''
	 SET @WhereClause = @WhereClause + CASE
                 WHEN @Keyword IS NOT NULL 
					 THEN ' (ActivityTypes.Name LIKE ''%' + @Keyword + '%''' + 
						  ' OR Users.FullName LIKE ''%' + @Keyword + '%''' +
						  ' OR Comments.Body LIKE ''%' + @Keyword + '%''' +
						  ' OR #CollectionWorkListActivities.SubActivityType IN ('+ @SubActivityTypeValueCSV + ')) AND '
					  ELSE '' END +

		CASE WHEN @FromFollowUpDate IS NOT NULL THEN ' CAST(Activities.FollowUpDate AS DATE) >= ''' + CAST(@FromFollowUpDate AS NVARCHAR(30)) + ''' AND ' ELSE '' END +
		CASE WHEN @ToFollowUpDate IS NOT NULL THEN ' CAST(Activities.FollowUpDate AS DATE) <= ''' + CAST(@ToFollowUpDate AS NVARCHAR(30)) + ''' AND ' ELSE '' END +
		CASE WHEN @CommentBody IS NOT NULL THEN ' Comments.Body LIKE ''%' + @CommentBody + '%'' AND ' ELSE '' END +
		CASE WHEN @CreatedByUser IS NOT NULL THEN ' Users.FullName LIKE ''%'+ @CreatedByUser + '%'' AND ' ELSE '' END +
		CASE WHEN @ActivityTypeName IS NOT NULL THEN ' ActivityTypes.Name LIKE ''%'+ @ActivityTypeName + '%'' AND ' ELSE '' END +
		CASE WHEN @SubActivityType IS NOT NULL THEN ' #CollectionWorkListActivities.SubActivityType LIKE ''%' + @SubActivityType + '%'' AND ' ELSE '' END +
		CASE WHEN @IsFollowUpClosed IS NOT NULL AND @IsFollowUpClosed = 1
			 THEN 'Activities.CloseFollowUp = 1 AND ' ELSE '' END +	
		CASE WHEN @IsFollowUpClosed IS NOT NULL AND @IsFollowUpClosed = 0
			 THEN 'Activities.CloseFollowUp = 0 AND ' ELSE '' END +	
		CASE WHEN @PersonContacted IS NOT NULL THEN ' PartyContacts.FullName LIKE ''%'+ @PersonContacted + '%'' AND ' ELSE '' END +		 
		CASE WHEN @FollowUpUser IS NOT NULL THEN ' FollowUpUser.FullName LIKE ''%'+ @FollowUpUser + '%'' AND ' ELSE '' END 	 	 
		

	SET @SkipCount = @StartingRowNumber - 1;

	SET @TakeCount = @EndingRowNumber - @StartingRowNumber + 1;

	DECLARE @OrderStatement NVARCHAR(MAX) =  
	CASE
		WHEN @OrderColumn='CreatedTime' THEN 'Activities.CreatedTime'+ ' ' + @OrderBy
		WHEN @OrderColumn='CreatedByName' THEN 'Users.FullName'  + ' ' + @OrderBy
		WHEN @OrderColumn='ActivityTypeName' THEN 'ActivityTypes.Name'  + ' ' + @OrderBy
		WHEN @OrderColumn='SubActivityTypeName.Value' THEN '#CollectionWorkListActivities.SubActivityType' + ' ' + @OrderBy
		WHEN @OrderColumn='FollowUpDate' THEN 'Activities.FollowUpDate'  + ' ' + @OrderBy
		WHEN @OrderColumn='FollowUpClosureDate' THEN 'Activities.CompletionDate ' + ' '+ @OrderBy
		WHEN @OrderColumn='Comment' THEN 'Comments.Body' + ' '+ @OrderBy
		WHEN @OrderColumn='IsCurrentWorkList' THEN '#CollectionWorkListActivities.IsCurrentWorkList ' + ' '+ @OrderBy
	ELSE @DefaultOrderColumn END



	
	DECLARE @SelectQuery NVARCHAR(Max) = CAST('' AS NVARCHAR(MAX)) + '


	DECLARE @Count BIGINT = (	
    SELECT 
         COUNT(Activities.Id)
    FROM ' + @ActivityJoinStatement + 
	' WHERE '+ @WHEREClause + ' 1 = 1
	) ;

	SELECT 
		 Activities.Id as ActivityId
		,Activities.CreatedTime
		,Activities.FollowUpDate	
		,Activities.IsActive
		,ActivityTypes.Name ActivityTypeName
		,#CollectionWorkListActivities.SubActivityType as SubActivityTypeName
		,Users.FullName CreatedByName
		,[dbo].[GetTextFromHtml](Comments.Body) AS Comment
		,#CollectionWorkListActivities.IsCurrentWorkList
		,CASE WHEN Activities.CloseFollowUp = 1 
						THEN Activities.CompletionDate
						ELSE NULL END AS FollowUpClosureDate
		,@Count TotalActivities
	FROM '
	+ @ActivityJoinStatement +
	' WHERE '+ @WHEREClause + ' 1 = 1 
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
						@SkipCount BIGINT'
						,@TakeCount,
						@SkipCount;



	DROP TABLE #CollectionWorkListActivities
	DROP TABLE #ViewableActivityTypeIds

END

GO

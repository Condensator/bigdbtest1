SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetCollectionWorkListComments]
(
	@CollectionWorkListId         BIGINT,	
	@CustomerId                   BIGINT,	
	@IsFromCommentsWidget         BIT,
    @CollectionWorkListEntityType NVARCHAR(50),
	@CommentTypePrefix            NVARCHAR(10),
	@NoAccessPermission           NVARCHAR(2),
	@LoggedInUserId               BIGINT,

	@StartingRowNumber			  INT,
	@EndingRowNumber              INT,
	@OrderBy                      NVARCHAR(6) = NULL,
	@OrderColumn                  NVARCHAR(MAX) = '',

	@Keyword                      NVARCHAR(MAX) = NULL,
	@CommentType                  NVARCHAR(200) = NULL,
	@CommentTitle                 NVARCHAR(250) = NULL,
	@CommentBody                  NVARCHAR(250) = NULL,
	@CreatedByUser                NVARCHAR(250) = NULL,
	@CommentTag                   NVARCHAR(250) = NULL,
	@HasAttachment                BIT = NULL,
	@FromCreatedDate              DATE = NULL,
	@ToCreatedDate                DATE = NULL,
	@FromLastUpdatedDate          DATE = NULL,
	@ToLastUpdatedDate            DATE = NULL
)
AS
SET NOCOUNT ON
BEGIN

	CREATE TABLE #CollectionWorkListComments
	( 
		Comment NVARCHAR(MAX) NULL,
		CommentCreatedDate  DATETIMEOFFSET NOT NULL,
		LastUpdatedDate DATETIMEOFFSET NOT NULL,
		Originator NVARCHAR(250) NOT NULL,
		CommentType NVARCHAR(100) NOT NULL,
		CommentTitle NVARCHAR(250) NOT NULL,
		CommentId BIGINT NOT NULL,
		IsActive BIT NOT NULL,
		ResponseOne NVARCHAR(MAX) NULL,
		ResponseOneDateTime DATETIMEOFFSET NULL,
		ResponseOneUser NVARCHAR(250) NULL,
		ResponseTwo NVARCHAR(MAX) NULL,
		ResponseTwoDateTime DATETIMEOFFSET NULL,
		ResponseTwoUser NVARCHAR(250) NULL,
		IsCurrentWorkList BIT NOT NULL,
		CommentUpdatedDate DATETIMEOFFSET NOT NULL
	)

	
	SELECT 
		Comments.Id,
		CASE WHEN CommentPermissions.Id IS NOT NULL 
			THEN CommentPermissions.Permission
			ELSE Comments.DefaultPermission END Permission,
		CASE WHEN 
			CollectionWorkLists.Id = @CollectionWorkListId 
				THEN CAST(1 AS BIT)
				ELSE CAST(0 AS BIT) END AS IsCurrentWorkList
	INTO #CollectionWorkListCommentIds
	FROM CommentHeaders
	INNER JOIN EntityHeaders 
		ON CommentHeaders.Id = EntityHeaders.Id
	INNER JOIN EntityConfigs 
		ON EntityHeaders.EntityTypeId = EntityConfigs.Id
	INNER JOIN CommentLists  
		ON CommentHeaders.Id = CommentLists.CommentHeaderId
	INNER JOIN Comments 
		ON CommentLists.CommentId = Comments.Id	
	INNER JOIN CollectionWorkLists 
		ON EntityHeaders.EntityId = CollectionWorkLists.Id	
	LEFT JOIN CommentPermissions 
		ON Comments.Id = CommentPermissions.CommentId
		AND CommentPermissions.IsActive = 1
		AND CommentPermissions.UserId = @LoggedInUserId
	LEFT JOIN CommentUserPreferences 
		ON Comments.Id = CommentUserPreferences.CommentId
		AND CommentUserPreferences.UserId = @LoggedInUserId
	WHERE 
		EntityConfigs.Name = @CollectionWorkListEntityType
		AND CollectionWorkLists.CustomerId = @CustomerId
		AND (CommentUserPreferences.Id IS NULL OR CommentUserPreferences.Hidden = 0)

	SELECT 
		DISTINCT Id,
		IsCurrentWorkList
	INTO #AccessibleCommentIds
	FROM #CollectionWorkListCommentIds
		WHERE Id NOT IN
			(SELECT Id FROM #CollectionWorkListCommentIds
			 WHERE Permission = @NoAccessPermission)

	INSERT INTO #CollectionWorkListComments
	(Comment,CommentCreatedDate, LastUpdatedDate, Originator, CommentType, CommentTitle, CommentId, IsActive, IsCurrentWorkList, CommentUpdatedDate)
	SELECT
		[dbo].[GetTextFromHtml](Comments.Body) AS Comment,
		Comments.OriginalCreatedTime as CommentCreatedDate,
		CASE WHEN 
			(LatestResponses.LatestResponseTime IS NOT NULL 
			AND LatestResponses.LatestResponseTime > ISNULL(Comments.UpdatedTime, Comments.OriginalCreatedTime))
				THEN LatestResponses.LatestResponseTime
				ELSE ISNULL(Comments.UpdatedTime, Comments.OriginalCreatedTime) 
			END LastUpdatedDate,
		Users.FullName AS Originator,
		CommentTypes.Name CommentType,
		Comments.Title AS CommentTitle,
		Comments.Id AS CommentId,
		Comments.IsActive,
		IsCurrentWorkList,
		ISNULL(Comments.UpdatedTime, Comments.OriginalCreatedTime) 
	FROM Comments
	INNER JOIN #AccessibleCommentIds
		ON #AccessibleCommentIds.Id  = Comments.Id
	INNER JOIN CommentTypes 
		ON Comments.CommentTypeId = CommentTypes.Id
	INNER JOIN Users 
		ON Comments.AuthorId = Users.Id
	LEFT JOIN 
			(SELECT 
				CommentId, 
				MAX(OriginalCreatedTime) AS LatestResponseTime  
			FROM CommentResponses 
			WHERE IsActive = 1
			GROUP BY CommentId) LatestResponses
		ON Comments.Id = LatestResponses.CommentId


	SELECT *
	INTO #CommentResponses
	FROM
	(
		SELECT 
			ROW_NUMBER() OVER (PARTITION by Comments.id ORDER BY CommentResponses.Id asc) AS RowNumber,
			Comments.Id AS CommentId,
			[dbo].[GetTextFromHtml](CommentResponses.Body) AS CommentResponse,
			CommentResponses.OriginalCreatedTime AS CommentResponseDateTime,
			Users.FullName AS CommentResponseUser
		FROM Comments
		INNER JOIN CommentResponses on Comments.Id = CommentResponses.CommentId
		INNER JOIN #CollectionWorkListComments ON Comments.Id = #CollectionWorkListComments.CommentId 
		INNER JOIN Users ON CommentResponses.CreatedById = Users.Id
		WHERE CommentResponses.IsActive = 1
	)
	AS CommentResponses
	where RowNumber <= 2

	UPDATE #CollectionWorkListComments 
	SET 
		 ResponseOne = ResponseOne.CommentResponse,
		 ResponseOneDateTime = ResponseOne.CommentResponseDateTime,
		 ResponseOneUser = ResponseOne.CommentResponseUser
	FROM #CollectionWorkListComments
	JOIN 
		(SELECT * FROM #CommentResponses WHERE RowNumber = 1) 
	AS ResponseOne
	ON #CollectionWorkListComments.CommentId = ResponseOne.CommentId

	UPDATE #CollectionWorkListComments 
	SET 
		 ResponseTwo = ResponseTwo.CommentResponse,
		 ResponseTwoDateTime = ResponseTwo.CommentResponseDateTime,
		 ResponseTwoUser = ResponseTwo.CommentResponseUser
	FROM #CollectionWorkListComments
	JOIN 
		(SELECT * FROM #CommentResponses WHERE RowNumber = 2) 
	AS ResponseTwo
	ON #CollectionWorkListComments.CommentId = ResponseTwo.CommentId

	CREATE TABLE #CommentWithAttachments
	( 
		CommentId BIGINT NOT NULL
	)

	IF(@HasAttachment IS NOT NULL)
	BEGIN
		INSERT INTO #CommentWithAttachments
        SELECT DISTINCT
            #CollectionWorkListComments.CommentId
        FROM #CollectionWorkListComments
        INNER JOIN CommentAttachments
            ON CommentAttachments.CommentId = #CollectionWorkListComments.CommentId
         WHERE
            CommentAttachments.IsActive = 1
           
        UNION   
       
        SELECT DISTINCT
            #CollectionWorkListComments.CommentId
        FROM #CollectionWorkListComments       
        INNER JOIN CommentResponses
            ON #CollectionWorkListComments.CommentId = CommentResponses.CommentId
        INNER JOIN CommentResponseAttachments
            ON CommentResponseAttachments.CommentResponseId = CommentResponses.Id
        WHERE
            CommentResponseAttachments.IsActive=1

	END

	CREATE TABLE #CommentWithTags
	( 
		CommentId BIGINT NOT NULL
	)

	IF(@CommentTag IS NOT NULL)
	BEGIN

		
		DECLARE @DynamicTagsQuery NVARCHAR(max) = ''
		SET @DynamicTagsQuery= 
		'
		-- *manual tags*
		
		INSERT INTO #CommentWithTags
		SELECT DISTINCT
			#CollectionWorkListComments.CommentId
		FROM #CollectionWorkListComments
		INNER JOIN CommentTags
			ON  #CollectionWorkListComments.CommentId = CommentTags.CommentId
		INNER JOIN CommentTagValuesConfigs 
			ON CommentTags.TagId = CommentTagValuesConfigs.Id
		INNER JOIN CommentTagConfigs 
			ON CommentTagValuesConfigs.CommentTagConfigId = CommentTagConfigs.Id
		WHERE CommentTagConfigs.IsActive = 1
			AND CommentTagValuesConfigs.IsActive = 1
			AND CommentTags.IsActive = 1
			AND CommentTagValuesConfigs.Value LIKE ''%' + @CommentTag + '%''

		UNION 

		-- *Entity Tags*

		SELECT 
			DISTINCT CommentLists.CommentId
		FROM 
			#CollectionWorkListComments
		JOIN CommentLists 
			ON #CollectionWorkListComments.CommentId = CommentLists.CommentId
		JOIN CommentHeaders 
			ON CommentLists.CommentHeaderId = CommentHeaders.Id
		JOIN EntityHeaders 
			ON CommentHeaders.Id = EntityHeaders.Id
		WHERE CommentLists.IsActive = 1		
			AND EntityHeaders.EntityNaturalId LIKE ''%' + @CommentTag + '%'''

	exec(@DynamicTagsQuery)

		END
	
		
--------DYNAMIC QUERY------------------

	DECLARE @SkipCount BIGINT
    DECLARE @TakeCount BIGINT
	DECLARE @DefaultOrderColumn NVARCHAR(MAX)

	SET @DefaultOrderColumn = 
			CASE WHEN @IsFromCommentsWidget = 1 
              THEN 'IsActive DESC,IsCurrentWorkList DESC,LastUpdatedDate DESC'
              ELSE 'IsActive DESC,LastUpdatedDate DESC' END

	 DECLARE @WhereClause NVARCHAR(MAX)=''
	 SET @WhereClause = CASE
                 WHEN @Keyword IS NOT NULL 
                 THEN ' (CommentType LIKE ''%' + @Keyword + '%''' + 
					  ' OR CommentTitle LIKE ''%' + @Keyword + '%''' +
                      ' OR Comment LIKE ''%' + @Keyword + '%'') AND '
       ELSE '' END +

	CASE WHEN @CommentType IS NOT NULL THEN ' CommentType LIKE ''%' + @CommentType + '%'' AND ' ELSE '' END +	
	CASE WHEN @CommentTitle IS NOT NULL THEN ' CommentTitle LIKE ''%' + @CommentTitle + '%'' AND ' ELSE '' END +
	CASE WHEN @CommentBody IS NOT NULL THEN ' Comment LIKE ''%' + @CommentBody + '%'' AND ' ELSE '' END +
	CASE WHEN @CreatedByUser IS NOT NULL THEN ' Originator LIKE ''%'+ @CreatedByUser + '%'' AND ' ELSE '' END +	
	CASE WHEN @HasAttachment IS NOT NULL AND @HasAttachment = 1
		THEN ' #CommentWithAttachments.CommentId IS NOT NULL' + ' AND ' ELSE '' END +
	CASE WHEN @HasAttachment IS NOT NULL AND @HasAttachment = 0
		THEN ' #CommentWithAttachments.CommentId IS NULL' + ' AND ' ELSE '' END +

	CASE WHEN @FromCreatedDate IS NOT NULL THEN ' CAST(CommentCreatedDate AS DATE) >= ''' + CAST(@FromCreatedDate AS NVARCHAR(30)) + ''' AND ' ELSE '' END +
	CASE WHEN @ToCreatedDate IS NOT NULL THEN ' CAST(CommentCreatedDate AS DATE) <= ''' +  CAST(@ToCreatedDate AS NVARCHAR(30)) + ''' AND ' ELSE '' END +

	CASE WHEN @FromLastUpdatedDate IS NOT NULL THEN ' CAST(LastUpdatedDate AS DATE) >= ''' + CAST(@FromLastUpdatedDate AS NVARCHAR(30)) + ''' AND ' ELSE '' END +
	CASE WHEN @ToLastUpdatedDate IS NOT NULL THEN ' CAST(LastUpdatedDate AS DATE) <= ''' + CAST(@ToLastUpdatedDate AS NVARCHAR(30)) + ''' AND ' ELSE '' END 


	SET @SkipCount = @StartingRowNumber - 1;

	SET @TakeCount = @EndingRowNumber - @StartingRowNumber + 1;

	DECLARE @OrderStatement NVARCHAR(MAX) =  
	  CASE
		WHEN @OrderColumn='LastUpdatedDate' THEN 'LastUpdatedDate'+ ' ' + @OrderBy
		WHEN @OrderColumn='Originator' THEN 'Originator'  + ' ' + @OrderBy
		WHEN @OrderColumn='CommentType' THEN 'CommentType'  + ' ' + @OrderBy
		WHEN @OrderColumn='CommentTitle' THEN 'CommentTitle' + ' ' + @OrderBy
		WHEN @OrderColumn='Comment' THEN 'Comment'  + ' ' + @OrderBy
		WHEN @OrderColumn='IsCurrentWorkList' THEN 'IsCurrentWorkList' + @OrderBy
		ELSE @DefaultOrderColumn END

	
  DECLARE @CommentJoinStatement Nvarchar(MAX) =  
	' #CollectionWorkListComments '
	+
	 CASE WHEN @CommentTag IS NOT NULL
		 THEN ' INNER JOIN #CommentWithTags 
			ON #CommentWithTags.CommentId = #CollectionWorkListComments.CommentId '
	     ELSE '' END
    +

	' LEFT JOIN #CommentWithAttachments
		ON #CollectionWorkListComments.CommentId = #CommentWithAttachments.CommentId ' 

	
	DECLARE @SelectQuery NVARCHAR(Max) = CAST('' AS NVARCHAR(MAX)) + '


	DECLARE @Count BIGINT = (	
    SELECT  
         COUNT(#CollectionWorkListComments.CommentId)
    FROM ' + @CommentJoinStatement + 
	' WHERE '+ @WHEREClause + ' 1 = 1
	) ;

	SELECT 
		 #CollectionWorkListComments.CommentId AS Id
		,Comment
		,CommentCreatedDate		
		,LastUpdatedDate				
		,Originator					
		,Concat('''+@CommentTypePrefix+''',CommentType) as CommentType		
		,CommentTitle
		,IsActive 
		,ResponseOne 
		,ResponseOneDateTime 
		,ResponseOneUser 
		,ResponseTwo 
		,ResponseTwoDateTime 
		,ResponseTwoUser 
		,IsCurrentWorkList
		,CommentUpdatedDate
		,@Count TotalComments
	FROM '
	+ @CommentJoinStatement +
	' WHERE '+ @WHEREClause + ' 1 = 1 
	ORDER BY '+ @OrderStatement + 
	CASE WHEN @EndingRowNumber > 0
	     THEN
	        ' OFFSET @SkipCount ROWS FETCH NEXT @TakeCount ROWS ONLY ;' 
         ELSE 
		    ';'  
	END

	EXEC sp_executesql @SelectQuery,N'@TakeCount BIGINT,@SkipCount BIGINT',@TakeCount,@SkipCount

	DROP TABLE #CollectionWorkListComments
	DROP TABLE #CollectionWorkListCommentIds
	DROP TABLE #AccessibleCommentIds
	DROP TABLE #CommentResponses
	DROP TABLE #CommentWithAttachments
	DROP TABLE #CommentWithTags

END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetCustomerDocumentPacks]
(
	 @CurrentSiteId                     BIGINT,
	 @AccessibleDocumentPackIds         AccessibleDocumentPackIdCollection READONLY,
	 @StartingRowNumber					INT,
	 @EndingRowNumber					INT,
	 @OrderBy							NVARCHAR(6),
	 @OrderColumn						NVARCHAR(MAX)
)
AS
BEGIN

	CREATE TABLE #CustomerAccessibleDocumentPackIds
	(
		DocumentPackId BIGINT NOT NULL
	);

	INSERT INTO #CustomerAccessibleDocumentPackIds
	SELECT DocumentPackId 
	FROM @AccessibleDocumentPackIds

	SELECT 
		DocumentPackAttachments.DocumentPackId, 
		MAX(DocumentPackAttachments.Id) DocumentPackAttachmentId,
		COUNT(DocumentPackAttachments.Id) DocumentPackAttachmentCount
	INTO #DocumentPackAttachmentInfo
	FROM DocumentPackAttachments
	INNER JOIN #CustomerAccessibleDocumentPackIds ON DocumentPackAttachments.DocumentPackId = #CustomerAccessibleDocumentPackIds.DocumentPackId
	WHERE DocumentPackAttachments.IsActive = 1
	GROUP BY DocumentPackAttachments.DocumentPackId


	SELECT 
		DISTINCT DocumentPackDetails.DocumentPackId, DocumentTypes.Name DocumentTypeName
	INTO #DocPackDetails
	FROM DocumentPackDetails
	INNER JOIN #CustomerAccessibleDocumentPackIds ON DocumentPackDetails.DocumentPackId = #CustomerAccessibleDocumentPackIds.DocumentPackId
	INNER JOIN DocumentAttachments ON DocumentPackDetails.AttachmentId = DocumentAttachments.Id
	INNER JOIN DocumentInstances ON DocumentAttachments.DocumentInstanceId = DocumentInstances.Id
	INNER JOIN DocumentTypes ON DocumentInstances.DocumentTypeId = DocumentTypes.Id
	WHERE DocumentAttachments.IsActive = 1 AND DocumentInstances.IsActive = 1

	SELECT DocumentPackId, DocumentTypeName = 
		STUFF((SELECT ', ' + DocumentTypeName
			   FROM #DocPackDetails b 
			   WHERE b.DocumentPackId = a.DocumentPackId 
			  FOR XML PATH('')), 1, 2, '')
	INTO #DocumentPackDocumentTypes
	FROM #DocPackDetails a
	GROUP BY DocumentPackId

	SELECT 
		DocumentPacks.Id DocumentPackId,
		DocumentPacks.Name,
		DocumentPacks.StatusDate,
		DocumentStatusSubSystemConfigs.Status,
		Attachments.File_Content Attachment_Content,
		Attachments.File_Source Attachment_Source,
		Attachments.File_Type Attachment_Type,
		Attachments.Description AttachmentDescription,
		Attachments.Id AttachmentId,
		#DocumentPackDocumentTypes.DocumentTypeName,
		#DocumentPackAttachmentInfo.DocumentPackAttachmentCount AttachmentCount
	INTO #CustomerDocumentPacks
	FROM DocumentPacks
	INNER JOIN #CustomerAccessibleDocumentPackIds ON DocumentPacks.Id = #CustomerAccessibleDocumentPackIds.DocumentPackId
	INNER JOIN DocumentStatusConfigs ON DocumentPacks.StatusId = DocumentStatusConfigs.Id
	INNER JOIN #DocumentPackAttachmentInfo ON DocumentPacks.Id = #DocumentPackAttachmentInfo.DocumentPackId
	INNER JOIN DocumentPackAttachments ON #DocumentPackAttachmentInfo.DocumentPackAttachmentId = DocumentPackAttachments.Id
	INNER JOIN AttachmentForDocs ON DocumentPackAttachments.AttachmentId = AttachmentForDocs.Id
	INNER JOIN Attachments ON AttachmentForDocs.AttachmentId = Attachments.Id
	INNER JOIN #DocumentPackDocumentTypes ON DocumentPacks.Id = #DocumentPackDocumentTypes.DocumentPackId
	LEFT JOIN DocumentStatusSubSystemConfigs ON DocumentStatusConfigs.Id = DocumentStatusSubSystemConfigs.DocumentStatusConfigId
	AND DocumentStatusSubSystemConfigs.SubSystemId = @CurrentSiteId


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
				WHEN @OrderColumn='DocumentPackId' THEN 'DocumentPackId'
				WHEN @OrderColumn='Name' THEN 'Name'
				WHEN @OrderColumn='DocumentTypeName' THEN 'DocumentTypeName'
				WHEN @OrderColumn='Status' THEN 'Status'
				WHEN @OrderColumn='StatusDate' THEN 'StatusDate'
				WHEN @OrderColumn='AttachmentDescription' THEN 'AttachmentDescription'
				WHEN @OrderColumn='AttachmentCount' THEN 'AttachmentCount'
			END
	END

	SET  @OrderStatement = 
		CASE 
			WHEN (@OrderStatement IS NOT NULL AND @OrderStatement != '') THEN @OrderStatement + ' ' + @OrderBy
		ELSE
			' DocumentPackId desc '
		END

		---- Output Result Query -----

	DECLARE @SelectQuery NVARCHAR(Max) = CAST('' AS NVARCHAR(MAX)) + N' 

	SELECT *
	FROM #CustomerDocumentPacks
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

DROP TABLE #CustomerAccessibleDocumentPackIds
DROP TABLE #DocumentPackAttachmentInfo
DROP TABLE #DocPackDetails
DROP TABLE #DocumentPackDocumentTypes
DROP TABLE #CustomerDocumentPacks

END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 

CREATE PROCEDURE [dbo].[GetCollectionWorkListEmails]
(
	@CollectionWorklistId BIGINT,
	@CollectionWorkListEntityType NVARCHAR(200),
	@ReceivableInvoiceEntityTypeCT NVARCHAR(200),
	@NotificationSourceModuleCollectionWorkList NVARCHAR(200),
	@NotificationSourceModuleEmailInvoice NVARCHAR(200),
	@NotificationsEntityNameReceivableInvoice NVARCHAR(200),

	@StartingRowNumber			  INT,
	@EndingRowNumber              INT,
	@OrderBy                      NVARCHAR(6) = NULL,
	@OrderColumn                  NVARCHAR(MAX) = '',

	@Keyword                      NVARCHAR(MAX) = NULL,
	@EmailSubject				  NVARCHAR(1000) NULL,
	@EmailFromDate				  DATETIME NULL,
	@EmailToDate				  DATETIME NULL,
	@EmailTo					  NVARCHAR(140) NULL,
	@HasAttachments			      BIT NULL
	
)
AS
BEGIN

	SELECT 
		DISTINCT ReceivableInvoiceEmails.Id INTO #ApplicableReceivableInvoices
	FROM
		CollectionWorkLists
	INNER JOIN CollectionWorkListContractDetails
		ON CollectionWorkLists.Id = CollectionWorkListContractDetails.CollectionWorkListId
	INNER JOIN ReceivableInvoiceDetails
		ON CollectionWorkListContractDetails.ContractId = ReceivableInvoiceDetails.EntityId AND
		   ReceivableInvoiceDetails.EntityType = @ReceivableInvoiceEntityTypeCT
	INNER JOIN ReceivableInvoices
		ON ReceivableInvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id
		AND ReceivableInvoices.CustomerId = CollectionWorkLists.CustomerId
	INNER JOIN ReceivableInvoiceEmails
		ON ReceivableInvoices.EmailNotificationId = ReceivableInvoiceEmails.Id
	WHERE
		ReceivableInvoices.IsActive = 1 AND
		ReceivableInvoiceDetails.IsActive = 1 AND
		CollectionWorkLists.Id = @CollectionWorklistId 
		AND 
		(
			-- To fetch records belonging to worklist remit to
			(CollectionWorkLists.RemitToId IS NOT NULL AND CollectionWorkLists.RemitToId = ReceivableInvoices.RemitToId)
			OR (CollectionWorkLists.RemitToId IS NULL AND ReceivableInvoices.IsPrivateLabel = 0)
		) 
	
	SELECT 
		DISTINCT EmailNotifications.Id,
		[dbo].[GetTextFromHtml](EmailNotifications.Subject) AS SUBJECT,
		CASE WHEN NotificationAttachments.Id IS NOT NULL THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsAttachmentPresent
	INTO #ApplicableEmailNotifications
	FROM 
		EmailNotifications
	INNER JOIN Notifications
		ON EmailNotifications.Id = Notifications.Id
	INNER JOIN NotificationRecipients
		ON EmailNotifications.Id = NotificationRecipients.NotificationId
	LEFT JOIN #ApplicableReceivableInvoices
		ON Notifications.SourceId = #ApplicableReceivableInvoices.Id AND
		   Notifications.SourceModule = @NotificationSourceModuleEmailInvoice
	LEFT JOIN NotificationAttachments
		ON NotificationAttachments.NotificationId = Notifications.Id
	WHERE
		((Notifications.SourceModule = @NotificationSourceModuleCollectionWorkList AND SourceId = @CollectionWorklistId) 
		OR (#ApplicableReceivableInvoices.Id IS NOT NULL AND Notifications.EntityName = @NotificationsEntityNameReceivableInvoice)) AND
		(@EmailFromDate IS NULL OR (CAST(Notifications.AsOfDate AS DATE) >= @EmailFromDate )) AND
		(@EmailToDate IS NULL OR (CAST(Notifications.AsOfDate AS DATE) <= @EmailToDate )) AND
		(@EmailSubject IS NULL OR EmailNotifications.Subject LIKE '%'+@EmailSubject+'%' ) AND
		(@EmailTo IS NULL OR NotificationRecipients.ToEmailId LIKE '%'+@EmailTo+'%' ) AND
		(@HasAttachments IS NULL OR (@HasAttachments = 1 AND NotificationAttachments.Id IS NOT NULL) OR (@HasAttachments = 0 AND NotificationAttachments.Id IS NULL))

	
	--------DYNAMIC QUERY------------------

	DECLARE @SkipCount BIGINT
    DECLARE @TakeCount BIGINT
	DECLARE @DefaultOrderColumn NVARCHAR(MAX)

	SET @DefaultOrderColumn = 'AsOfDate DESC'

	 DECLARE @WhereClause NVARCHAR(MAX)=''
	 SET @WhereClause = CASE
                 WHEN @Keyword IS NOT NULL 
                 THEN ' (#ApplicableEmailNotifications.Subject LIKE ''%' + @Keyword + '%''' + 
                      ' OR ToEmailId LIKE ''%' + @Keyword + '%'') AND '
       ELSE '' END +

	   CASE WHEN @EmailSubject IS NOT NULL THEN ' #ApplicableEmailNotifications.Subject LIKE ''%' + @EmailSubject + '%'' AND ' ELSE '' END 	

	SET @SkipCount = @StartingRowNumber - 1;

	SET @TakeCount = @EndingRowNumber - @StartingRowNumber + 1;

	DECLARE @OrderStatement NVARCHAR(MAX) =  
	  CASE
		WHEN @OrderColumn='AsOfDate' THEN 'AsOfDate'+ ' ' + @OrderBy
		WHEN @OrderColumn='#ApplicableEmailNotifications.Subject' THEN 'Subject'  + ' ' + @OrderBy
		WHEN @OrderColumn='Body' THEN 'Body'  + ' ' + @OrderBy
		WHEN @OrderColumn='FromEmailId' THEN 'FromEmailId' + ' ' + @OrderBy
		WHEN @OrderColumn='ToEmailId' THEN 'ToEmailId'  + ' ' + @OrderBy
		WHEN @OrderColumn='Type' THEN 'Type' + @OrderBy
		ELSE @DefaultOrderColumn END

	
  DECLARE @NotificationJoinStatement Nvarchar(MAX) =  
	' EmailNotifications
	INNER JOIN Notifications
		ON EmailNotifications.Id = Notifications.Id
	INNER JOIN NotificationRecipients
		ON EmailNotifications.Id = NotificationRecipients.NotificationId
	INNER JOIN #ApplicableEmailNotifications
		ON Notifications.Id = #ApplicableEmailNotifications.Id  ' 

	
	DECLARE @SelectQuery NVARCHAR(Max) = CAST('' AS NVARCHAR(MAX)) + '


    SELECT EmailNotifications.Id as EmailNotificationId
	INTO #AllEmailNotifications
    FROM ' + @NotificationJoinStatement + 
	' WHERE '+ @WHEREClause + ' 1 = 1;

	------ First Result-Set for all Ids -----------

	SELECT EmailNotificationId AS EntityId
		FROM #AllEmailNotifications;

	---- Output Result Query -----

	SELECT
			Notifications.Id AS Id,
			Notifications.Id AS NotificationId,
			CAST(Notifications.AsOfDate as Date) AS Date,
			#ApplicableEmailNotifications.Subject,
			[dbo].[GetTextFromHtml](EmailNotifications.Body) AS Body,
			EmailNotifications.FromEmailId AS FromEmailId,
			NotificationRecipients.ToEmailId AS ToEmailId,
			Notifications.Status,
			#ApplicableEmailNotifications.IsAttachmentPresent
	FROM  '
	+ @NotificationJoinStatement +
	' WHERE '+ @WHEREClause + ' 1 = 1 
	ORDER BY '+ @OrderStatement + 
	CASE WHEN @EndingRowNumber > 0
	     THEN
	        ' OFFSET @SkipCount ROWS FETCH NEXT @TakeCount ROWS ONLY ;' 
         ELSE 
		    ';'  
	END

	EXEC sp_executesql @SelectQuery,N'@TakeCount BIGINT,@SkipCount BIGINT',@TakeCount,@SkipCount

	DROP TABLE #ApplicableEmailNotifications
	DROP TABLE #ApplicableReceivableInvoices
	
END

GO

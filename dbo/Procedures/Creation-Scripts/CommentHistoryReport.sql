SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CommentHistoryReport]
	@FromDate AS DATE ,
	@ToDate AS DATE ,
	@IncludeSuspendedLeases BIT ,
	@EntityId BIGINT = NULL ,
	@EntityType NVARCHAR(100) = NULL
AS

BEGIN

SELECT 
	CONVERT(SMALLDATETIME,Comments.CreatedTime) [CommentDate],
	Comments.CreatedById [CreatedBy],
	CommentTags.EntityId ,
	Comments.Id [CommentId],
	CommentTags.EntityType,
	Comments.AuthorId,
	CommentConfigs.Name [CommentType],
	Comments.ConversationMode ,
	CASE WHEN ConversationMode = 'Closed' THEN CONVERT(SMALLDATETIME,Comments.UpdatedTime) ELSE NULL END [CompletionDate],
	Comments.Body [Comment],
	CONVERT(SMALLDATETIME, CommentResponses.CreatedTime) [RespondedDate],
	CommentResponses.CreatedById [RespondedId],
	CommentResponses.Body [Response]
FROM Comments
	INNER JOIN CommentConfigs ON Comments.CommentConfigId = CommentConfigs.Id
	LEFT JOIN CommentTags ON Comments.Id = CommentTags.CommentId
	LEFT JOIN CommentResponses ON Comments.Id = CommentResponses.CommentId
	WHERE 1=1
		AND (@EntityId IS NULL OR CommentTags.EntityId = @EntityId) 
		AND (@FromDate IS NULL OR CAST(Comments.CreatedTime AS DATE) >= CAST(@FromDate AS DATE))          
		AND (@ToDate IS NULL OR CAST(Comments.CreatedTime AS DATE) <= CAST(@ToDate AS DATE))     
		AND (@EntityType IS NULL OR CommentTags.EntityType = @EntityType) 
END

GO

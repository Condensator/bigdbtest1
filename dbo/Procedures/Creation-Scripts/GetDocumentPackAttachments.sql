SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetDocumentPackAttachments]
(
@DocumentPackId						BIGINT,
@StartingRowNumber						INT,
@EndingRowNumber						INT,
@OrderBy								NVARCHAR(6),
@OrderColumn							NVARCHAR(MAX)
)
AS
SET NOCOUNT ON
BEGIN


DECLARE @JoinStatement Nvarchar(MAX)=
'FROM 
DocumentPackAttachments 
INNER JOIN DocumentPacks ON DocumentPackAttachments.DocumentPackId=DocumentPacks.Id
INNER JOIN AttachmentForDocs ON DocumentPackAttachments.AttachmentId=AttachmentForDocs.Id
INNER JOIN Attachments ON AttachmentForDocs.AttachmentId=Attachments.Id
INNER JOIN SubSystemConfigs ON Attachments.SourceId=SubSystemConfigs.Id
where DocumentPackAttachments.DocumentPackId = @DocumentPackId AND
DocumentPackAttachments.IsActive = 1 AND
DocumentPacks.IsActive = 1 AND
'

DECLARE @SkipCount BIGINT;
DECLARE @TakeCount BIGINT;

SET @SkipCount = @StartingRowNumber - 1;

SET @TakeCount = @EndingRowNumber - @StartingRowNumber + 1;

DECLARE @DefaultOrderColumn NVARCHAR(MAX) = ' Attachments.AttachedDate desc ';

	DECLARE @OrderStatement NVARCHAR(MAX) =  
	CASE
		WHEN @OrderColumn='PortalSource' THEN 'SubSystemConfigs.Name'+ ' ' + @OrderBy
	    WHEN @OrderColumn='AttachedDate' THEN 'Attachments.AttachedDate'  + ' ' + @OrderBy
	    WHEN @OrderColumn='Comment' THEN 'Attachments.Description'  + ' ' + @OrderBy
	ELSE @DefaultOrderColumn  END


DECLARE @SelectQuery NVARCHAR(Max) = CAST('' AS NVARCHAR(MAX)) + '
SELECT 
         Attachments.Id AS EntityId
    ' + @JoinStatement + 
	' 1 = 1

SELECT 
Attachments.Id as EntityId,
Attachments.File_Source as Attachment_Source,
Attachments.File_Type as Attachment_Type,
Attachments.File_Content as Attachment_Content,
Attachments.Description as Comment,
SubSystemConfigs.Name as [PortalSource],
Attachments.AttachedDate
'
+ @JoinStatement +	
	' 1 = 1
	ORDER BY '+ @OrderStatement + 
	CASE WHEN @EndingRowNumber > 0
	     THEN
	        ' OFFSET @SkipCount ROWS FETCH NEXT @TakeCount ROWS ONLY ;' 
         ELSE 
		    ';'  
	END	

EXEC sp_executesql @SelectQuery,
						N'
						@DocumentPackId BIGINT,
						@TakeCount BIGINT,
						@SkipCount BIGINT'
					   ,@DocumentPackId
					   ,@TakeCount
					   ,@SkipCount;


SET NOCOUNT OFF;
END

GO

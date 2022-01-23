SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[ExceptionLog]
(
@ErrorMessageList ErrorMessageList READONLY
,@ErrorLine NVARCHAR(100)
,@CreatedById bigint
,@CreatedTime DateTimeOffset
,@ModuleName Nvarchar(200)
)
AS
Begin
SET NOCOUNT On;
CREATE TABLE #ExceptionProcessing
(
[Id] BIGINT NOT NULL
);
Declare @Message Nvarchar(max)
Declare @IterationStatusId BigInt
select @Message=List.Message,@IterationStatusId=ModuleIterationStatusId  from @ErrorMessageList List
Declare @CompleteErrorMessage Nvarchar(max)
Set @CompleteErrorMessage = 'Error reading from stored procedure '+  @ModuleName  + ISNULL(@Message,'') + CASE WHEN @ErrorLine IS NOT NULL THEN 'At Line Number ' + @ErrorLine END
INSERT into stgProcessingLog
(
StagingRootEntityId
,CreatedById
,CreatedTime
,ModuleIterationStatusId
)
OUTPUT  Inserted.Id into #ExceptionProcessing
Select StagingRootEntityId
,@CreatedById
,@CreatedTime
,@IterationStatusId from @ErrorMessageList
Insert into stgProcessingLogDetail(Message,Type,CreatedById,CreatedTime,ProcessingLogId)
select @CompleteErrorMessage,'Error',@CreatedById,@CreatedTime,FL.Id from #ExceptionProcessing FL
DROP table #ExceptionProcessing
END

GO

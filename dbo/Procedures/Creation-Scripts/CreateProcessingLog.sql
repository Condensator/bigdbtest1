SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[CreateProcessingLog]
(
@ErrorMessageList ErrorMessageList READONLY
,@CreatedById bigint
,@CreatedTime DateTimeOffset
)
AS
Begin
Declare @ModuleId bigint
Select @ModuleId= ModuleId from stgModuleIterationStatus where Id = (Select distinct ModuleIterationStatusId From @ErrorMessageList)
Insert into stgProcessingLog(StagingRootEntityId,CreatedById,CreatedTime,ModuleIterationStatusId)
Select distinct StagingRootEntityId,@CreatedById,@CreatedTime,ModuleIterationStatusId From @ErrorMessageList
Insert into stgProcessingLogDetail([Message],[Type],[CreatedById],[CreatedTime],[ProcessingLogId])
Select COALESCE ([Validation].Message,[List].Message),[List].[Type],@CreatedById,@CreatedTime,stgProcessingLog.Id From @ErrorMessageList [List]
Join stgProcessingLog
on stgProcessingLog.StagingRootEntityId = [List].StagingRootEntityId
And stgProcessingLog.ModuleIterationStatusId = [List].ModuleIterationStatusId
Left Join stgValidationMessage [Validation]
On [Validation].[Key] = [List].Message
And [Validation].ModuleId = @ModuleId
And [Validation].Culture = 'en-US'
End

GO

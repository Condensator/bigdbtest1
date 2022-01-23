SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateGLExport]
(
	@UserId BIGINT,
	@ModuleIterationStatusId BIGINT,
	@CreatedTime DATETIMEOFFSET = NULL,
	@ProcessedRecords BIGINT OUT,
	@FailedRecords BIGINT OUT
)
AS

--DECLARE @UserId BIGINT;  
--DECLARE @FailedRecords BIGINT;  
--DECLARE @ProcessedRecords BIGINT;  
--DECLARE @CreatedTime DATETIMEOFFSET;  
--DECLARE @ModuleIterationStatusId BIGINT;  
--Set @UserId = 1;  
--Set @CreatedTime = SYSDATETIMEOFFSET();   
--Select @ModuleIterationStatusId = MAX(ModuleIterationStatusId) FROM stgProcessingLog;  

BEGIN

CREATE TABLE #CreatedProcessingLogs([Id] bigint NOT NULL); 

DECLARE @Id BIGINT = 0;

SELECT @Id = (select min(JobStepInstances.Id) from JobStepInstances
join jobsteps on JobStepInstances.JobStepId=jobsteps.Id 
join JobTaskConfigs on jobsteps.TaskId=JobTaskConfigs.Id and JobTaskConfigs.Name='GLExport')

IF (@Id IS NOT NULL)
BEGIN
UPDATE GLJOURNALDETAILS SET EXPORTJOBID=@ID, UPDATEDBYID=1, UPDATEDTIME = SYSDATETIMEOFFSET() WHERE EXPORTJOBID IS NULL

   
INSERT  INTO stgProcessingLog
(  
    StagingRootEntityId  
    ,CreatedById  
    ,CreatedTime  
    ,ModuleIterationStatusId  
)  
OUTPUT Inserted.Id INTO #CreatedProcessingLogs
VALUES  
(  
     @UserId  
    ,@UserId  
    ,@CreatedTime  
    ,@ModuleIterationStatusId  
)  
INSERT INTO stgProcessingLogDetail  
(  
     Message  
    ,Type  
    ,CreatedById  
    ,CreatedTime   
    ,ProcessingLogId  
)  
SELECT  
     'Successful'  
    ,'Information'  
    ,@UserId  
    ,@CreatedTime  
    ,Id  
FROM  
#CreatedProcessingLogs 

SET @ProcessedRecords =  1;
SET @FailedRecords = 0;
END

ELSE
BEGIN
INSERT  INTO stgProcessingLog
(  
    StagingRootEntityId  
    ,CreatedById  
    ,CreatedTime  
    ,ModuleIterationStatusId  
)  
OUTPUT Inserted.Id INTO #CreatedProcessingLogs
VALUES  
(  
     @UserId  
    ,@UserId  
    ,@CreatedTime  
    ,@ModuleIterationStatusId  
)  
INSERT INTO stgProcessingLogDetail  
(  
     Message  
    ,Type  
    ,CreatedById  
    ,CreatedTime   
    ,ProcessingLogId  
)  
SELECT  
     'There is no Job found for GLExport, please add one and try again'  
    ,'Error'  
    ,@UserId  
    ,@CreatedTime  
    ,Id  
FROM  
#CreatedProcessingLogs  


SET @ProcessedRecords =  1;
SET @FailedRecords = 1;

END

DROP TABLE #CreatedProcessingLogs

END

GO

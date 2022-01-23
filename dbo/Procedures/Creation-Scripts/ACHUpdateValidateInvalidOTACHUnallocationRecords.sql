SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[ACHUpdateValidateInvalidOTACHUnallocationRecords]
(
 @JobStepInstanceId BIGINT
,@ErrorCode NVARCHAR(4)
)
AS
BEGIN

SELECT OneTimeACHId INTO #InvalidOneTimeACH FROM ACHSchedule_Extract WHERE IsOneTimeACH = 1 AND @JobStepInstanceId = JobStepInstanceId AND ErrorCode <> '_' GROUP BY OneTimeACHId

UPDATE ACHS SET ErrorCode = @ErrorCode 
FROM ACHSchedule_Extract  ACHS 
JOIN #InvalidOneTimeACH OTACH ON OTACH.OneTimeACHId = ACHS.OneTimeACHId
WHERE ACHS.UnAllocatedAmount <> 0.00 
AND ACHS.OneTimeACHScheduleId IS NULL
AND @JobStepInstanceId = JobStepInstanceId 
AND ErrorCode ='_'


END

GO

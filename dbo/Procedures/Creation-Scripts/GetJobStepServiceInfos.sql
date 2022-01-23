SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROCEDURE [dbo].[GetJobStepServiceInfos]
(
	@JobServiceId BIGINT,
	@NotStartedStatus NVARCHAR(50),
	@RunningStatus NVARCHAR(50)
)
AS
CREATE TABLE #JobStepInstanceIds
(
	Id BIGINT NOT NULL
)

UPDATE JobStepInstances SET Status = @RunningStatus
OUTPUT DELETED.Id INTO #JobStepInstanceIds
WHERE JobServiceId = @JobServiceId AND Status = 'NotStarted'

SELECT Id [JobStepInstanceId] FROM #JobStepInstanceIds

GO

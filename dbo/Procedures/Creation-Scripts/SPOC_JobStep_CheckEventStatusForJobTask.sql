SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SPOC_JobStep_CheckEventStatusForJobTask]
(
    @JobTaskConfigId BigInt,
	@JobStepId BigInt,
	@JobId BigInt
)
AS
SET NOCOUNT ON;
DECLARE @Messages StoredProcMessage

DELETE ejm
FROM EventInstanceJobTaskMappings ejm
	 JOIN EventInstances ei ON ejm.Id = ei.Id 
		AND ejm.JobTaskConfigId = @JobTaskConfigId
		AND ejm.JobStepId = @JobStepId
		AND ejm.JobId = @JobId
		AND ei.Status in ('Completed', 'Skipped');

SELECT 
  CAST(COUNT(CASE WHEN (ei.Status IN ('Pending', 'Processing', 'Retry')) THEN 1 ELSE NULL END) AS BIT) as HasIncompleteEvents,
  CAST(COUNT(CASE WHEN Status='Faulted' THEN 1 ELSE NULL END) AS BIT) as HasFailedEvents
FROM EventInstanceJobTaskMappings ejm
	 JOIN EventInstances ei ON ejm.Id = ei.Id 
		AND ejm.JobTaskConfigId = @JobTaskConfigId
		AND ejm.JobStepId = @JobStepId
		AND ejm.JobId = @JobId;

--Messages should always be the last SELECT (below are the possible message details)
SELECT Name, ParameterValuesCsv FROM @Messages;

GO

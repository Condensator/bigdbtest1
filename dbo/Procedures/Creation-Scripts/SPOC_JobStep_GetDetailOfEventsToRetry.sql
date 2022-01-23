SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SPOC_JobStep_GetDetailOfEventsToRetry]
(
    @JobTaskConfigId BigInt,
	@JobStepId BigInt,
	@JobId BigInt
)
AS
SET NOCOUNT ON;
DECLARE @Messages StoredProcMessage

SELECT ei.Id as Id, NULL as JobServiceId, 'Retry' as Status
FROM EventInstanceJobTaskMappings ejm
	 JOIN EventInstances ei ON ejm.Id = ei.Id 
		AND ejm.JobTaskConfigId = @JobTaskConfigId
		AND ejm.JobStepId = @JobStepId
		AND ejm.JobId = @JobId
		AND ei.Status = 'Faulted';

SELECT ehi.Id as Id, 'Retry' as Status
FROM EventInstanceJobTaskMappings ejm
	 JOIN EventInstances ei ON ejm.Id = ei.Id 
		AND ejm.JobTaskConfigId = @JobTaskConfigId
		AND ejm.JobStepId = @JobStepId
		AND ejm.JobId = @JobId
		AND ei.Status = 'Faulted'
	 JOIN EventHandlerInstances ehi ON ei.Id = ehi.EventInstanceId 
		AND ehi.Status = 'Faulted';

--Messages should always be the last SELECT (below are the possible message details)
SELECT Name, ParameterValuesCsv FROM @Messages;

GO

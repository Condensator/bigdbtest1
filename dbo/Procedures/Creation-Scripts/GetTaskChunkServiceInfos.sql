SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROCEDURE [dbo].[GetTaskChunkServiceInfos]
(
	@JobServiceId BIGINT,
	@NotStartedStatus NVARCHAR(50),
	@RunningStatus NVARCHAR(50)
)
AS
CREATE TABLE #TaskChunkServiceInstanceIds
(
	Id BIGINT NOT NULL
)

UPDATE TaskChunkServiceInstances
	   SET Status = @RunningStatus
OUTPUT DELETED.Id INTO #TaskChunkServiceInstanceIds
WHERE JobServiceId = @JobServiceId  AND Status = 'NotStarted'

SELECT Id [TaskChunkServiceInstanceId] FROM #TaskChunkServiceInstanceIds

GO

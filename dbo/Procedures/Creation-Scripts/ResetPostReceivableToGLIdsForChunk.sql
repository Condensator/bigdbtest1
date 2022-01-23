SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ResetPostReceivableToGLIdsForChunk]
(
@TaskChunkServiceInstanceId BIGINT = NULL,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET,
@JobStepInstanceId BIGINT
)AS
BEGIN
UPDATE PostReceivableToGLJob_Extracts
SET TaskChunkServiceInstanceId = NULL,
IsSubmitted = 0
WHERE IsSubmitted = 1
AND TaskChunkServiceInstanceId = @TaskChunkServiceInstanceId
AND JobStepInstanceId = @JobStepInstanceId
END

GO

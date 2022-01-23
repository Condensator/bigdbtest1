SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetPostReceivableToGLExtractDataChunk]
(
@BatchSize INT,
@UpdatedById BIGINT,
@TaskChunkServiceInstanceId BIGINT = NULL,
@UpdatedTime DATETIMEOFFSET,
@JobStepInstanceId BIGINT
) AS
BEGIN
UPDATE TOP (@BatchSize) PostReceivableToGLJob_Extracts
SET TaskChunkServiceInstanceId = @TaskChunkServiceInstanceId,
IsSubmitted = 1
OUTPUT Deleted.*
WHERE JobStepInstanceId = @JobStepInstanceId AND IsSubmitted = 0
END

GO

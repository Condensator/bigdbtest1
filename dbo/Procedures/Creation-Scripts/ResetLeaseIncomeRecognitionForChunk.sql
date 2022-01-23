SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ResetLeaseIncomeRecognitionForChunk]
(
@TaskChunkServiceInstanceId BIGINT = NULL,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET,
@JobStepInstanceId BIGINT
)AS
BEGIN
UPDATE LeaseIncomeRecognitionJob_Extracts
SET TaskChunkServiceInstanceId = NULL,
IsSubmitted = 0
WHERE IsSubmitted = 1
AND TaskChunkServiceInstanceId = @TaskChunkServiceInstanceId
AND JobStepInstanceId = @JobStepInstanceId
END

GO

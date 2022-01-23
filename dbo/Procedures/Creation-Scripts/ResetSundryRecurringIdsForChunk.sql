SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ResetSundryRecurringIdsForChunk]
(
@TaskChunkServiceInstanceId BIGINT = NULL,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET,
@JobStepInstanceId BIGINT
)AS
BEGIN
UPDATE SundryRecurringJobExtracts
SET TaskChunkServiceInstanceId = NULL,
UpdatedById = @UpdatedById,
UpdatedTime = @UpdatedTime,
IsSubmitted = 0
WHERE IsSubmitted = 1
AND TaskChunkServiceInstanceId = @TaskChunkServiceInstanceId
AND JobStepInstanceId = @JobStepInstanceId
END

GO

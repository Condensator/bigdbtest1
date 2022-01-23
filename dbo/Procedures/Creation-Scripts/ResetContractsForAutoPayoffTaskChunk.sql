SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ResetContractsForAutoPayoffTaskChunk]
(
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET,
@TaskChunkServiceInstanceId BIGINT = NULL,
@JobStepInstanceId BIGINT
)
AS
BEGIN
UPDATE AutoPayoffContracts
SET
UpdatedById = @UpdatedById,
UpdatedTime = @UpdatedTime,
TaskChunkServiceInstanceId = NULL,
IsProcessed = 0
WHERE
TaskChunkServiceInstanceId = @TaskChunkServiceInstanceId AND
JobStepInstanceId = @JobStepInstanceId AND
IsProcessed = 1 AND
IsActive = 1
END

GO

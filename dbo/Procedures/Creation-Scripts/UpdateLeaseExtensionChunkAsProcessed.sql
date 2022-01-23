SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateLeaseExtensionChunkAsProcessed]
(
@ProcessedStatus NVARCHAR(9),
@InProcessStatus NVARCHAR(9),
@TaskChunkServiceInstanceId BIGINT = NULL,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET,
@JobStepInstanceId BIGINT
)AS
BEGIN
UPDATE LeaseExtensions
SET TaskChunkServiceInstanceId = NULL,
UpdatedById = @UpdatedById,
UpdatedTime = @UpdatedTime,
Status = @ProcessedStatus
WHERE Status = @InProcessStatus
AND ( @TaskChunkServiceInstanceId IS NOT NULL AND TaskChunkServiceInstanceId = @TaskChunkServiceInstanceId
OR  (@TaskChunkServiceInstanceId IS NULL AND TaskChunkServiceInstanceId IS NULL))
AND JobStepInstanceId = @JobStepInstanceId
END

GO

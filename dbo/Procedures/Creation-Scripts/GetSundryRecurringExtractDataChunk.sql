SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetSundryRecurringExtractDataChunk]
(
@BatchSize INT,
@UpdatedById BIGINT,
@TaskChunkServiceInstanceId BIGINT = NULL,
@UpdatedTime DATETIMEOFFSET,
@JobStepInstanceId BIGINT
) AS
BEGIN
UPDATE TOP (@BatchSize) SundryRecurringJobExtracts
SET TaskChunkServiceInstanceId = @TaskChunkServiceInstanceId,
UpdatedById = @UpdatedById,
UpdatedTime = @UpdatedTime,
IsSubmitted = 1
OUTPUT Deleted.SundryRecurringId, deleted.FunderId,deleted.IsAdvance,deleted.IsSyndicated,deleted.ComputedProcessThroughDate,
deleted.LastExtensionARUpdateRunDate, deleted.EntityType,deleted.ContractId
WHERE TaskChunkServiceInstanceId IS NULL AND IsSubmitted = 0
AND JobStepInstanceId = @JobStepInstanceId
END

GO

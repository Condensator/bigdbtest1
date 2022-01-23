SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetCPUContractInfoForBaseChargeTaskChunk]
(
	@BatchSize INT,
	@UpdatedById BIGINT,
	@TaskChunkServiceInstanceId BIGINT = NULL,
	@UpdatedTime DATETIMEOFFSET,
	@JobStepInstanceId BIGINT
)
AS
BEGIN
	SET NOCOUNT ON;
	
	UPDATE
		TOP (@BatchSize) CPUBaseChargeJobExtracts
	SET
		TaskChunkServiceInstanceId = @TaskChunkServiceInstanceId,
		UpdatedById = @UpdatedById,
		UpdatedTime = @UpdatedTime,
		IsSubmitted = 1
	OUTPUT
		Deleted.CPUContractId,
		Deleted.CPUScheduleId,
		Deleted.ComputedProcessThroughDate
	WHERE
		TaskChunkServiceInstanceId IS NULL AND
		IsSubmitted = 0 AND
		JobStepInstanceId = @JobStepInstanceId

	SET NOCOUNT OFF;
END

GO

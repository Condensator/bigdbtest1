SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetDraftEntityDetailsToChunk]
(
	@Status NVARCHAR(17),
	@MasterConfigSetDetailId BIGINT,
	@BatchSize INT,
	@TaskChunkServiceInstanceId BIGINT = NULL,
	@JobCorrelationId NVARCHAR(36),
	@UpdatedById BIGINT,
	@UpdatedTime DATETIMEOFFSET
)
AS

BEGIN

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE 

UPDATE TOP (@BatchSize) ded
	   SET ded.TaskChunkServiceInstanceId = @TaskChunkServiceInstanceId,
		   ded.UpdatedById = @UpdatedById,
		   ded.UpdatedTime = @UpdatedTime
OUTPUT INSERTED.*
	   FROM MasterConfigSetDetails mcsd
	   JOIN DraftEntityBatches deb ON mcsd.DraftEntityBatchId = deb.Id
	   JOIN DraftEntityDetails ded ON ded.DraftEntityBatchId = deb.Id
	   JOIN MasterConfigDetails mcd ON deb.MasterConfigDetailId = mcd.Id
	   WHERE mcsd.Id = @MasterConfigSetDetailId and ded.JobCorrelationId = @JobCorrelationId and ded.Status = @Status and ded.TaskChunkServiceInstanceId IS NULL
END

GO

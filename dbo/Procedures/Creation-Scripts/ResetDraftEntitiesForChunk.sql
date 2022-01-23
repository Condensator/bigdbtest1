SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[ResetDraftEntitiesForChunk]
(
	@Status NVARCHAR(17),
	@TaskChunkServiceInstanceId BIGINT = NULL,
	@UpdatedById BIGINT,
	@UpdatedTime DATETIMEOFFSET
)
AS

BEGIN

UPDATE DraftEntityDetails
	   SET TaskChunkServiceInstanceId = NULL,
		   UpdatedById = @UpdatedById,
		   UpdatedTime = @UpdatedTime
WHERE Status = @Status
  AND TaskChunkServiceInstanceId = @TaskChunkServiceInstanceId

END

GO

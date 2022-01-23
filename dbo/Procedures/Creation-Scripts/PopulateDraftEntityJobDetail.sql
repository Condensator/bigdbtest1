SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


Create PROCEDURE [dbo].[PopulateDraftEntityJobDetail]
(
	@JobInstanceId BIGINT,
	@IsCompleted BIT,
	@ProcessingSetId BIGINT,
	@CreatedById BIGINT,
	@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
	INSERT INTO DraftEntityJobDetails(JobInstanceId, Completed, ProcessingSetId, CreatedById, CreatedTime)
	VALUES(@JobInstanceId, @IsCompleted, @ProcessingSetId, @CreatedById, @CreatedTime)
END

GO

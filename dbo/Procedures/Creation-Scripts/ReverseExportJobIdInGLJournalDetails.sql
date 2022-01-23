SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create PROCEDURE [dbo].[ReverseExportJobIdInGLJournalDetails]
(
@JobStepInstanceId BigInt,
@CurrentUserId Bigint,
@CurrentTime DATETIMEOFFSET
)
AS
BEGIN
UPDATE
GLJournalDetails
SET
ExportJobId = null
,UpdatedById = @CurrentUserId
,UpdatedTime= @CurrentTime
WHERE
ExportJobId = @JobStepInstanceId
END

GO

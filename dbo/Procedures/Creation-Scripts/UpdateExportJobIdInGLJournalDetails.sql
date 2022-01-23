SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateExportJobIdInGLJournalDetails]
(
@JobStepInstanceId bigint,
@CurrentUserId bigint,
@GLExportJournal GLExportJournal READONLY,
@CurrentTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
UPDATE
GLJournalDetails
SET
ExportJobId = @JobStepInstanceId
,UpdatedById = @CurrentUserId
,UpdatedTime = @CurrentTime
FROM
GLJournalDetails
INNER JOIN @GLExportJournal gljournaldetail
ON GLJournalDetails.Id = gljournaldetail.JournalDetailId
END

GO

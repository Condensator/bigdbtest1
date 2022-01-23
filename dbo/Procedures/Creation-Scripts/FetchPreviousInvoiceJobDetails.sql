SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[FetchPreviousInvoiceJobDetails]
(
	@JobStepInstanceId		BIGINT,
	@SourceJobStepInstanceId BIGINT NULL OUTPUT,
	@JobInvocationReason_RunAgain NVARCHAR(8),
	@JobInvocationReason_Resumed NVARCHAR(7)
)
AS 
BEGIN
	SET NOCOUNT ON;

	DECLARE @JobStepId BIGINT = NULL
	SET @SourceJobStepInstanceId = NULL

	--Check if the JobStepInstanceId is of a RunAgain/Resumed Job and get the JobStepId
	SET @JobStepId = (
		SELECT JSI.JobStepId FROM JobStepInstances JSI
		INNER JOIN JobInstances JI ON JSI.JobInstanceId=JI.Id
		WHERE JI.InvocationReason IN (@JobInvocationReason_RunAgain, @JobInvocationReason_Resumed) AND JSI.Id=@JobStepInstanceId
	)

	IF @JobStepId IS NOT NULL --Send back the SourceJobStepInstanceId indicating any and all Previous Runs, and use it to stamp newly generated entities
		SET @SourceJobStepInstanceId = (
			SELECT MAX(SourceJobStepInstanceId) FROM InvoiceJobErrorSummaries
			WHERE JobStepId=@JobStepId AND IsActive=1 GROUP BY JobStepId
		)
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateReceiptLockBoxDumpTable]
(
@JobStepInstanceId		BIGINT,
@GUID					UNIQUEIDENTIFIER,
@GLTemplateId			BIGINT
)
AS
BEGIN
UPDATE ReceiptPostByLockBox_Extract
SET GLTemplateId = @GLTemplateId, JobStepInstanceId = @JobStepInstanceId
WHERE MigratedUniqueIdentifier = @GUID
END

GO

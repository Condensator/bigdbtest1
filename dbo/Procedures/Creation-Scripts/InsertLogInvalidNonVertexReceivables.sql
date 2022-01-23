SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InsertLogInvalidNonVertexReceivables]
(
	@ExtractedInvalidNonVertexReceivable ExtractedInvalidNonVertexReceivable READONLY,
	@TaxRateNotFoundErrorMessage NVARCHAR(2000),
	@ErrorMessageType nvarchar(22),
	@CreatedById bigint,
	@CreatedTime DateTimeOffset,
	@JobStepInstanceId BIGINT,
	@LocationCode NVARCHAR(MAX)
)
AS
BEGIN
INSERT INTO JobStepInstanceLogs
(Message, MessageType, CreatedById, CreatedTime, JobStepInstanceId)
SELECT
 Message
,MessageType
,CreatedById
,CreatedTime
,JobStepInstanceId
FROM
@ExtractedInvalidNonVertexReceivable

IF(@LocationCode IS NOT NULL)
BEGIN
INSERT INTO JobStepInstanceLogs
(Message, MessageType, CreatedById, CreatedTime, JobStepInstanceId)
VALUES
(REPLACE(@TaxRateNotFoundErrorMessage,'@Locations', @LocationCode)
,@ErrorMessageType
,@CreatedById
,@CreatedTime
,@JobStepInstanceId)
END;
END

GO

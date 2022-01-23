SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ReceiptPostByLockBoxLogger]
(
@JobStepInstanceId				BIGINT,
@CreatedById					BIGINT,
@CreatedTime					DATETIMEOFFSET,
@MessageTypeValues_Error		NVARCHAR(5),
@MessageTypeValues_Information	NVARCHAR(15),
@InvalidDataMessages DataTypeErrorMessage READONLY
)
AS
BEGIN
	INSERT INTO JobStepInstanceLogs
	(Message, MessageType, CreatedById, CreatedTime, JobStepInstanceId)
	SELECT
	CONCAT('In File :','"', FileName, '"', ' at RowNumber :', CONVERT(NVARCHAR(10), RowNumber), '. ',CASE WHEN Comment IS NOT NULL AND IsValid=1 THEN Comment ELSE ErrorMessage END)
	,CASE WHEN Comment IS NOT NULL AND IsValid=1 THEN @MessageTypeValues_Information ELSE @MessageTypeValues_Error END
	,@CreatedById
	,@CreatedTime
	,@JobStepInstanceId
	FROM
	ReceiptPostByLockBox_Extract
	WHERE JobStepInstanceId = @JobStepInstanceId
	AND (ErrorMessage IS NOT NULL OR (Comment IS NOT NULL AND IsValid=1))
	UNION
	SELECT
	ErrorMessage
	,@MessageTypeValues_Error
	,@CreatedById
	,@CreatedTime
	,@JobStepInstanceId
	FROM @InvalidDataMessages
END

GO

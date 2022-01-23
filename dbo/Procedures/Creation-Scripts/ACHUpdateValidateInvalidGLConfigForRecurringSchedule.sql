SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[ACHUpdateValidateInvalidGLConfigForRecurringSchedule]
(
 @JobStepInstanceId BIGINT
,@ReceiptGLConfigurationId BIGINT
,@ErrorCode NVARCHAR(4)
)
AS
BEGIN

Update ACHDetail SET ErrorCode = @ErrorCode
FROM ACHSchedule_Extract ACHDetail
WHERE JobStepInstanceId = @JobStepInstanceId
AND GLConfigurationId <> @ReceiptGLConfigurationId
AND IsOneTimeACH = 0
AND ErrorCode ='_'

END

GO

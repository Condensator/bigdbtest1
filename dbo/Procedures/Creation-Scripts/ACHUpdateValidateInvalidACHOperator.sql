SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[ACHUpdateValidateInvalidACHOperator]
(
 @JobStepInstanceId BIGINT
,@ErrorCode NVARCHAR(4)
)
AS
BEGIN

Update ACHDetail SET ErrorCode = @ErrorCode 
FROM ACHSchedule_Extract ACHDetail
WHERE JobStepInstanceId = @JobStepInstanceId
AND ReceiptBankAccountACHOperatorConfigId IS NULL
AND ErrorCode ='_'

END

GO

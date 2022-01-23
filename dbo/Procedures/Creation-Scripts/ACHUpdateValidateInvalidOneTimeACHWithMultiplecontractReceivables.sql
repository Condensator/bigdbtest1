SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[ACHUpdateValidateInvalidOneTimeACHWithMultiplecontractReceivables]
(
 @JobStepInstanceId BIGINT
,@ErrorCode NVARCHAR(4)
)
AS
BEGIN

Update ACHDetail SET ErrorCode = @ErrorCode
FROM ACHSchedule_Extract ACHDetail
WHERE JobStepInstanceId = @JobStepInstanceId
AND IsOneTimeACH = 1
AND HasMultipleContractReceivables = 1
AND ErrorCode ='_'

END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[ACHUpdateValidateCustomerBankAccountOnHold]
(
 @JobStepInstanceId BIGINT
,@ErrorCode NVARCHAR(4)
,@OTACHErrorCode NVARCHAR(4)
)
AS
BEGIN

UPDATE ACHS SET ErrorCode = @ErrorCode
FROM ACHSchedule_Extract ACHS
WHERE ACHS.JobStepInstanceId = @JobStepInstanceId
AND ACHS.ErrorCode = '_'
AND ACHS.BankAccountIsOnHold = 1
AND ACHS.IsOneTimeACH = 0

UPDATE ACHS SET ErrorCode = @OTACHErrorCode
FROM ACHSchedule_Extract ACHS
WHERE ACHS.JobStepInstanceId = @JobStepInstanceId
AND ACHS.ErrorCode = '_'
AND ACHS.BankAccountIsOnHold = 1
AND ACHS.IsOneTimeACH = 1

END

GO

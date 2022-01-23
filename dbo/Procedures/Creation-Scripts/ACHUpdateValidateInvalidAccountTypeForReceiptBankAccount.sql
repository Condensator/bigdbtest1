SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[ACHUpdateValidateInvalidAccountTypeForReceiptBankAccount]
(
 @JobStepInstanceId BIGINT
,@AccountTypeBoth NVARCHAR(9)
,@AccountTypeReceiving NVARCHAR(9)
,@ErrorCode NVARCHAR(4)
)
AS
BEGIN

Update ACHDetail SET ErrorCode = @ErrorCode
FROM ACHSchedule_Extract ACHDetail
WHERE JobStepInstanceId = @JobStepInstanceId
AND ReceiptBankAccountType NOT IN (@AccountTypeBoth,@AccountTypeReceiving)
AND ErrorCode ='_'

END

GO

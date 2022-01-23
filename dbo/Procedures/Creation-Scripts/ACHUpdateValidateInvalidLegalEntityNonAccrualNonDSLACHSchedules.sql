SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[ACHUpdateValidateInvalidLegalEntityNonAccrualNonDSLACHSchedules]
(
 @JobStepInstanceId BIGINT
,@ReceiptClassificationType NVARCHAR(19)
,@ErrorCode NVARCHAR(4) 
)
AS
BEGIN

Update ACHDetail SET ErrorCode = @ErrorCode
FROM ACHSchedule_Extract ACHDetail
WHERE JobStepInstanceId = @JobStepInstanceId
AND IsOneTimeACH = 0
AND ReceiptLegalEntityId <> ReceivableLegalEntityId
AND IsNonAccrual = 1
AND ReceiptClassificationType = @ReceiptClassificationType
AND ErrorCode ='_'
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[ACHUpdateValidateInvalidGLOrStructureConfig]
(
 @JobStepInstanceId BIGINT
,@ErrorCode NVARCHAR(4)
)
AS
BEGIN

UPDATE ACHS SET ErrorCode = @ErrorCode 
FROM ACHSchedule_Extract ACHS
LEFT JOIN GLOrgStructureConfigs GLO ON GLO.LegalEntityId = ACHS.ReceiptLegalEntityId  
										AND GLO.LineofBusinessId =ACHS.LineofBusinessId 
										AND ACHS.CostCenterId = GLO.CostCenterId 
										AND GLO.IsActive = 1
WHERE GLO.Id IS NULL
AND ACHS.ErrorCode = '_'
AND ACHS.JobStepInstanceId = @JobStepInstanceId

END

GO

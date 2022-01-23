SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[ACHUpdateValidateNotTaxAssessedACHSchedule]
(
 @JobStepInstanceId BIGINT
,@FullPaymentType NVARCHAR(14)
,@TaxOnlyPaymentType NVARCHAR(14)
,@ErrorCode NVARCHAR(4)
)
AS
BEGIN

SELECT ACHScheduleId INTO #InvalidACHScheduleId FROM ACHSchedule_Extract   
WHERE JobStepInstanceId = @JobStepInstanceId
AND IsOneTimeACH = 0
AND ACHSchedulePaymentType IN (@FullPaymentType,@TaxOnlyPaymentType)
AND IsTaxAssessed = 0
AND ErrorCode ='_'
GROUP  BY ACHScheduleId

Update ACHDetail SET ErrorCode = @ErrorCode
FROM ACHSchedule_Extract ACHDetail
JOIN #InvalidACHScheduleId ON #InvalidACHScheduleId.ACHScheduleId = ACHDetail.ACHScheduleId
WHERE JobStepInstanceId = @JobStepInstanceId
AND ErrorCode ='_'

END

GO

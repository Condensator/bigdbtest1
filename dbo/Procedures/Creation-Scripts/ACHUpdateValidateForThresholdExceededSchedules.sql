SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[ACHUpdateValidateForThresholdExceededSchedules]
(
@HasThresholdExceeded BIT OUT,
@JobStepInstanceId BIGINT,
@ErrorCode NVARCHAR(4)
)
AS
BEGIN

SET @HasThresholdExceeded =0;


SELECT STRING_AGG(CAST (achSchedule.Id AS NVARCHAR(MAX)),',')InvalidId --2017 Feature
INTO #InvalidIds
FROM ACHSchedule_Extract achSchedule
WHERE achSchedule.JobstepInstanceId = @JobStepInstanceId
AND achSchedule.IsOneTimeACH = 0
AND achSchedule.PaymentThreshold = 1
AND achSchedule.ErrorCode ='_'
GROUP BY     achSchedule.SettlementDate,
				achSchedule.ContractId,
				achSchedule.SequenceNumber,
				achSchedule.ACHPaymentThresholdDetailId,
				achSchedule.PaymentThresholdAmount
HAVING achSchedule.PaymentThresholdAmount < SUM(achSchedule.ACHAmount)

UPDATE achSchedule SET ErrorCode = @ErrorCode
FROM
ACHSchedule_Extract achSchedule
JOIN ConvertCSVToBigIntTable((SELECT STRING_AGG(CAST (InvalidId AS NVARCHAR(MAX)),',') FROM #InvalidIds),',') AS Invalid ON achSchedule.Id = Invalid.Id
WHERE JobStepInstanceId = @JobStepInstanceId
AND ErrorCode ='_'


IF EXISTS (SELECT 1 FROM ACHSchedule_Extract WHERE ErrorCode = @ErrorCode)
SET @HasThresholdExceeded = 1

END

GO

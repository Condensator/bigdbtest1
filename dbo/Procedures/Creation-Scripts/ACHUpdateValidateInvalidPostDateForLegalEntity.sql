SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[ACHUpdateValidateInvalidPostDateForLegalEntity]
(
 @JobStepInstanceId BIGINT
,@PostDate Date
,@InvalidOpenPeriodErrorCode NVARCHAR(4)
,@InvalidPostDateErrorCode NVARCHAR(4)
)
AS
BEGIN
SELECT  LegalEntityId LegalEntityId 
INTO #LegalEntityIds 
FROM
(
SELECT ReceiptLegalEntityId AS LegalEntityId
FROM ACHSchedule_Extract
WHERE @JobStepInstanceId = JObStepInstanceId
	AND ErrorCode ='_'
GROUP BY ReceiptLegalEntityId
UNION
SELECT ReceivableLegalEntityId AS LegalEntityId
FROM ACHSchedule_Extract
WHERE @JobStepInstanceId =  JObStepInstanceId
	AND ReceivableLegalEntityId IS NOT NULL
	AND ErrorCode ='_'
GROUP BY ReceivableLegalEntityId
) AS T

SELECT
       FromDate = GLO.FromDate,
       ToDate = GLO.ToDate,
       LegalEntityId = LE.Id,
       LegalEntityName = LE.Name,
       HasGLPeriod = CASE WHEN GLO.Id IS NOT NULL THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END ,
       IsPostDateValid =  CAST(0 AS BIT)
INTO #LegalEntityOpenPeriodInfo
FROM #LegalEntityIds LEId
JOIN LegalEntities LE ON LE.Id = LEId.LegalEntityId
LEFT JOIN GLFinancialOpenPeriods GLO ON GLO.LegalEntityId = LE.Id AND GLO.IsCurrent = 1
WHERE (GLO.Id IS NULL OR  @PostDate NOT BETWEEN GLO.FromDate AND GLO.ToDate)


Update ACHDetail SET ErrorCode = CASE WHEN InvalidReceiptLEId.HasGLPeriod = 0 THEN @InvalidOpenPeriodErrorCode ELSE @InvalidPostDateErrorCode END,
InvalidOpenPeriodFromDate = InvalidReceiptLEId.FromDate,
InvalidOpenPerionToDate = InvalidReceiptLEId.TODate
FROM ACHSchedule_Extract ACHDetail
INNER JOIN #LegalEntityOpenPeriodInfo InvalidReceiptLEId ON ACHDetail.ReceiptLegalEntityId = InvalidReceiptLEId.LegalEntityId
WHERE JobStepInstanceId = @JobStepInstanceId AND ErrorCode ='_'

Update ACHDetail SET ErrorCode = CASE WHEN InvalidReceiptLEId.HasGLPeriod = 0 THEN @InvalidOpenPeriodErrorCode ELSE @InvalidPostDateErrorCode END,
InvalidOpenPeriodFromDate = InvalidReceiptLEId.FromDate,
InvalidOpenPerionToDate = InvalidReceiptLEId.TODate
FROM ACHSchedule_Extract ACHDetail
INNER JOIN #LegalEntityOpenPeriodInfo InvalidReceiptLEId ON ACHDetail.ReceivableLegalEntityId = InvalidReceiptLEId.LegalEntityId
WHERE JobStepInstanceId = @JobStepInstanceId AND ErrorCode ='_'
END

GO

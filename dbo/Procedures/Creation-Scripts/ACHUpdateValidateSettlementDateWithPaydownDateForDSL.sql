SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[ACHUpdateValidateSettlementDateWithPaydownDateForDSL]
(
 @JobStepInstanceId BIGINT
,@ErrorCode NVARCHAR(4)
,@DSLReceiptClassificationType NVARCHAR(20)
,@ActivePaydownStatus NVARCHAR(20)
)
AS
BEGIN

;WITH CTE_DSLMAXPaydownDate
AS
(
SELECT ACHS.Id, MAX(LP.PaydownDate) AS MaxPayDownDate,ACHS.SettlementDate
FROM ACHSchedule_Extract ACHS
JOIN LoanFinances LF ON LF.ContractId = ACHS.ContractId 
JOIN LoanPaydowns LP ON LP.LoanFinanceId = LF.Id and lp.Status = @ActivePaydownStatus
WHERE ACHS.JobStepInstanceId = @JobStepInstanceId
AND ACHS.ErrorCode = '_'
AND ACHS.ReceiptClassificationType = @DSLReceiptClassificationType
GROUP BY ACHS.Id,ACHS.ContractId,ACHS.SettlementDate
HAVING ACHS.SettlementDate < MAX(LP.PaydownDate)
)
UPDATE ACHS SET ErrorCode = @ErrorCode 
FROM ACHSchedule_Extract ACHS
JOIN CTE_DSLMAXPaydownDate CTE ON CTE.Id = ACHS.Id  

END

GO

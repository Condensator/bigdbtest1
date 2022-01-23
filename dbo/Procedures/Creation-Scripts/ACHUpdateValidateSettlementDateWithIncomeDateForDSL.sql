SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[ACHUpdateValidateSettlementDateWithIncomeDateForDSL]
(
 @JobStepInstanceId BIGINT
,@ErrorCode NVARCHAR(4)
,@DSLReceiptClassificationType NVARCHAR(20)
)
AS
BEGIN

;WITH CTE_DSLMAXIncomeDate
AS
(
SELECT ACHS.Id, MAX(LIS.IncomeDate) AS MaxDueDate,ACHS.SettlementDate
FROM ACHSchedule_Extract ACHS
JOIN LoanFinances LF ON LF.ContractId = ACHS.ContractId AND Lf.IsCurrent = 1 
JOIN LoanIncomeSchedules LIS ON LIS.LoanFinanceId = LF.Id
WHERE ACHS.JobStepInstanceId = @JobStepInstanceId
AND ACHS.ErrorCode = '_'
AND ACHS.ReceiptClassificationType = @DSLReceiptClassificationType
GROUP BY ACHS.Id,ACHS.ContractId,ACHS.SettlementDate
HAVING ACHS.SettlementDate > MAX(LIS.IncomeDate)
)
UPDATE ACHS SET ErrorCode = @ErrorCode 
FROM ACHSchedule_Extract ACHS
JOIN CTE_DSLMAXIncomeDate CTE ON CTE.Id = ACHS.Id  

END

GO

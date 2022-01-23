SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[ACHUpdateValidateMultipleNonAccrualReceiptsForContract]
(
@JobStepInstanceId BIGINT,
@ErrorCode NVARCHAR(4),
@NANDSLType NVARCHAR(50)
)
AS
BEGIN
;WITH CTE_NonAccrualDetails
 AS(
 SELECT Id,
 ContractId,
 SettlementDate,
 CustomerBankAccountId,
 IsOneTimeACH,
 OneTimeACHId
 FROM ACHSchedule_Extract
 WHERE JobStepInstanceId = @JobStepInstanceId
 AND ErrorCode = '_'
 AND ReceiptClassificationType = @NANDSLType
 ),
 CTE_NonAccrualDetailWithRank
 AS
 (
  SELECT Id,
 DENSE_RANK() OVER (PARTITION BY ContractId ORDER BY SettlementDate,CustomerBankAccountId,IsOneTimeACH DESC, OneTimeACHId) AS Rank_Number
 FROM CTE_NonAccrualDetails
 )
 UPDATE ACHS SET ErrorCode = @ErrorCode
 FROM ACHSchedule_Extract ACHS 
 JOIN CTE_NonAccrualDetailWithRank NonAccrualDetail on ACHS.Id = NonAccrualDetail.Id
 WHERE NonAccrualDetail.Rank_Number <> 1

 END; 

GO

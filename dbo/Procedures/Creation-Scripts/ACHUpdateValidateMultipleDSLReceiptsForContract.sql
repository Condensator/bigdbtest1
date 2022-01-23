SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[ACHUpdateValidateMultipleDSLReceiptsForContract]
(
@JobStepInstanceId BIGINT,
@DSLType NVARCHAR(50),
@ErrorCode NVARCHAR(4),
@ProcessThroughDate DATE
)
AS
BEGIN
 ;WITH CTE_DSLDetails
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
 AND ReceiptClassificationType = @DSLType
 AND @ProcessThroughDate  < SettlementDate
 ),
 CTE_DSLDetailsWithRank
 AS
 (
  SELECT Id,
 DENSE_RANK() OVER (PARTITION BY ContractId ORDER BY SettlementDate,CustomerBankAccountId,IsOneTimeACH DESC, OneTimeACHId) AS Rank_Number
 FROM CTE_DSLDetails
 )
 UPDATE ACHS SET ErrorCode = @ErrorCode
 FROM ACHSchedule_Extract ACHS 
 JOIN CTE_DSLDetailsWithRank DSLDetail on ACHS.Id = DSLDetail.Id
 WHERE DSLDetail.Rank_Number <> 1

 END ;

GO

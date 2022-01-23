SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[ACHUpdateValidateSettlementDateWithCommencementDateForDSL]
(
 @JobStepInstanceId BIGINT
,@ErrorCode NVARCHAR(4)
,@DSLReceiptClassificationType NVARCHAR(20)
)
AS
BEGIN

UPDATE ACHS SET ErrorCode = @ErrorCode 
FROM ACHSchedule_Extract ACHS
JOIN LoanFinances LF ON LF.ContractId = ACHS.ContractId AND Lf.IsCurrent = 1 
WHERE ACHS.JobStepInstanceId = @JobStepInstanceId
AND ACHS.ErrorCode = '_'
AND ACHS.ReceiptClassificationType = @DSLReceiptClassificationType
AND ACHS.SettlementDate < LF.CommencementDate
END

GO

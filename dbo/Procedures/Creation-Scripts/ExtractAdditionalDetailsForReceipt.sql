SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[ExtractAdditionalDetailsForReceipt]
(
@CreatedById										BIGINT,
@CreatedTime										DATETIMEOFFSET,
@JobStepInstanceId									BIGINT,
@ReceivableTypeValues_LoanInterest					NVARCHAR(40),
@ReceivableTypeValues_LoanPrincipal					NVARCHAR(40),
@ReceiptClassificationValues_NonAccrualNonDSL		NVARCHAR(30),
@ReceivableEntityTypeValues_CT						NVARCHAR(10)
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON;
SELECT DISTINCT ContractId [Id]
INTO #ReceiptContracts
FROM Receipts_Extract
WHERE JobStepInstanceId = @JobStepInstanceId AND ContractId IS NOT NULL
SELECT DISTINCT DiscountingId [Id]
INTO #ReceiptDiscountings
FROM Receipts_Extract
WHERE JobStepInstanceId = @JobStepInstanceId AND DiscountingId IS NOT NULL
;WITH CTE_ReceiptContractGLInfo (ContractId,DealProductTypeId,AcquisitionID,LegalEntityId) AS
(
SELECT Contract.Id ContractId,Contract.DealProductTypeId, LeaseFinances.AcquisitionID, LeaseFinances.LegalEntityId
FROM #ReceiptContracts AS ReceiptContract
JOIN Contracts Contract ON ReceiptContract.Id = Contract.Id
JOIN LeaseFinances ON Contract.Id = LeaseFinances.ContractId AND LeaseFinances.IsCurrent=1
UNION ALL
SELECT Contract.Id ContractId,Contract.DealProductTypeId, LoanFinances.AcquisitionID, LoanFinances.LegalEntityId
FROM #ReceiptContracts AS ReceiptContract
JOIN Contracts Contract ON ReceiptContract.Id = Contract.Id
JOIN LoanFinances ON Contract.Id = LoanFinances.ContractId AND LoanFinances.IsCurrent=1
UNION ALL
SELECT Contract.Id ContractId,Contract.DealProductTypeId, LeveragedLeases.AcquisitionID, LeveragedLeases.LegalEntityId
FROM #ReceiptContracts AS ReceiptContract
JOIN Contracts Contract ON ReceiptContract.Id = Contract.Id
JOIN LeveragedLeases ON Contract.Id = LeveragedLeases.ContractId AND LeveragedLeases.IsCurrent=1
),
CTE_ReceiptDiscountingGLInfo (DiscountingId,LegalEntityId) AS
(
SELECT Discounting.Id DiscountingId, DiscountingFinances.LegalEntityId
FROM #ReceiptDiscountings AS Discounting
JOIN DiscountingFinances ON Discounting.Id = DiscountingFinances.DiscountingId AND DiscountingFinances.IsCurrent = 1
),
CTE_NonAccrualContractMaxDueDate (ContractId, MaxDueDate) AS
(
SELECT
RE.ContractId,
MAX(R.DueDate) MaxDueDate
FROM (SELECT DISTINCT ContractId
FROM Receipts_Extract
WHERE JobStepInstanceId = @JobStepInstanceId
AND ReceiptClassification = @ReceiptClassificationValues_NonAccrualNonDSL) RE
INNER JOIN Receivables R ON RE.ContractId = R.EntityId AND R.EntityType = @ReceivableEntityTypeValues_CT
AND (R.TotalBookBalance_Amount > 0 OR R.TotalBalance_Amount > 0) AND R.IsActive = 1 AND R.IsDummy = 0
INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
WHERE (RT.Name = @ReceivableTypeValues_LoanInterest OR RT.Name = @ReceivableTypeValues_LoanPrincipal)
GROUP BY RE.ContractId
)
SELECT 
ExtractId = R.Id,
MaxDueDate = NAC.MaxDueDate,
ContractLegalEntityId = ISNULL(RC.LegalEntityId,RD.LegalEntityId),
AcquisitionId = RC.AcquisitionId,
DealProductTypeId = RC.DealProductTypeId
INTO #AdditionalInfosToUpdate
FROM Receipts_Extract R
LEFT JOIN CTE_ReceiptContractGLInfo RC ON R.ContractId = RC.ContractId
LEFT JOIN CTE_ReceiptDiscountingGLInfo RD ON R.DiscountingId = RD.DiscountingId
LEFT JOIN CTE_NonAccrualContractMaxDueDate NAC ON R.ContractId = NAC.ContractId
WHERE R.JobStepInstanceId = @JobStepInstanceId
AND (R.ContractId IS NOT NULL OR R.DiscountingId IS NOT NULL);

UPDATE Receipts_extract SET 
MaxDueDate = additionalInfo.MaxDueDate,
ContractLegalEntityId = additionalInfo.ContractLegalEntityId,
AcquisitionId = additionalInfo.AcquisitionId,
DealProductTypeId = additionalInfo.DealProductTypeId
from #AdditionalInfosToUpdate additionalInfo WHERE Id = ExtractId

DROP TABLE #ReceiptContracts
DROP TABLE #ReceiptDiscountings
DROP TABLE #AdditionalInfosToUpdate
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[InsertSalesTaxReversalContractDetails]
(
@NoneSyndicationType NVARCHAR(20),
@JobStepInstanceId BIGINT
)
AS
BEGIN
WITH CTE_DistinctContractIds AS
(
SELECT DISTINCT ContractId FROM ReversalReceivableDetail_Extract WHERE ErrorCode IS NULL AND JobStepInstanceId = @JobStepInstanceId
)
INSERT INTO ReversalContractDetail_Extract
	        (ContractId, LeaseUniqueId, ContractTypeValue, TaxRemittanceType, IsSyndicated, CreatedById, CreatedTime, JobStepInstanceId,CommencementDate,MaturityDate)
SELECT ContractId = R.ContractId, 
	   LeaseUniqueId = C.SequenceNumber, 
	   ContractTypeValue = C.ContractType,
	   TaxRemittanceType = REPLACE(C.SalesTaxRemittanceMethod, 'Based',''),
	   IsSyndicated = CASE WHEN C.SyndicationType = @NoneSyndicationType 
							  THEN CONVERT(BIT,0) 
						   ELSE CONVERT(BIT,1) 
					  END,
	   CreatedById = 1,
	   CreatedTime = SYSDATETIMEOFFSET(),
	   @JobStepInstanceId,
	   ISNULL(LFD.CommencementDate,LoF.CommencementDate) AS CommencementDate,
	   ISNULL(LFD.MaturityDate,LoF.MaturityDate) AS MaturityDate
FROM CTE_DistinctContractIds R
INNER JOIN Contracts C ON R.ContractId = C.Id
LEFT JOIN LeaseFinances LF on LF.ContractId = C.Id AND LF.IsCurrent=1
LEFT JOIN LeaseFinanceDetails LFD ON LFD.Id= LF.Id
LEFT JOIN LoanFinances LoF ON LoF.ContractID = C.Id	AND LoF.IsCurrent=1


UPDATE ReversalReceivableDetail_Extract
SET ContractTypeValue = CD.ContractTypeValue , LeaseUniqueId = CD.LeaseUniqueId
FROM ReversalReceivableDetail_Extract RD
INNER JOIN ReversalContractDetail_Extract CD ON RD.ContractId = CD.ContractId AND RD.JobStepInstanceId = CD.JobStepInstanceId
WHERE RD.ErrorCode IS NULL AND RD.JobStepInstanceId = @JobStepInstanceId
END

GO

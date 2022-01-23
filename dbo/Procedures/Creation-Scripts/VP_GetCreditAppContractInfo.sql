SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[VP_GetCreditAppContractInfo]
(
@OpportunityNumber NVARCHAR(40)=NULL
)
AS
BEGIN
WITH CTE_Contract
AS
(
SELECT
C.Id AS ContractId
,C.SequenceNumber
,C.ContractType
FROM Opportunities O
JOIN CreditProfiles CP on O.Id = CP.OpportunityId
JOIN CreditApprovedStructures CA on CP.Id = CA.CreditProfileId
JOIN Contracts C on CA.Id = C.CreditApprovedStructureId
WHERE O.Number = @opportunityNumber
),
CTE_LeaseFinance
AS
(
SELECT
C.ContractId
,C.SequenceNumber
,C.ContractType
,L.ApprovalStatus
,CAST(COALESCE(L.UpdatedTime,NULL) AS DATE) AS StatusDate
FROM CTE_Contract C
JOIN LeaseFinances L ON C.ContractId = L.ContractId
WHERE L.ApprovalStatus <> 'Inactive'
AND L.IsCurrent = 1
),
CTE_LoanFinance
AS
(
SELECT
C.ContractId
,C.SequenceNumber
,C.ContractType
,L.ApprovalStatus ApprovalStatus
,CAST(COALESCE(L.UpdatedTime,NULL) AS DATE) AS StatusDate
FROM CTE_Contract C
JOIN LoanFinances L ON C.ContractId = L.ContractId
WHERE L.ApprovalStatus <> 'Rejected'
AND L.IsCurrent = 1
)
SELECT * FROM CTE_LeaseFinance
UNION
SELECT * FROM CTE_LoanFinance
END

GO

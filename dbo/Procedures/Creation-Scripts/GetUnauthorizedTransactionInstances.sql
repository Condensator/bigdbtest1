SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetUnauthorizedTransactionInstances]
(
@CurrentUserId INT
)
AS
BEGIN
SET NOCOUNT ON
CREATE TABLE #UnauthorizedConfidentialEntityDetails
(
EntityName NVARCHAR(50) NOT NULL,
EntityId BIGINT NOT NULL
);
INSERT INTO #UnauthorizedConfidentialEntityDetails
SELECT 'LeaseFinance', LF.Id FROM Contracts C
JOIN LeaseFinances LF ON C.Id = LF.ContractId AND LF.IsCurrent = 1
LEFT JOIN EmployeesAssignedToContracts EMP ON C.Id = EMP.ContractId AND EMP.IsActive = 1
LEFT JOIN EmployeesAssignedToParties EMPC ON EMP.EmployeeAssignedToPartyId = EMPC.Id AND EMPC.EmployeeId = @CurrentUserId
WHERE C.IsConfidential = 1
GROUP BY LF.Id HAVING SUM(ISNULL(EMPC.EmployeeId,0)) = 0;
INSERT INTO #UnauthorizedConfidentialEntityDetails
SELECT 'LoanFinance', LF.Id FROM Contracts C
JOIN LoanFinances LF ON C.Id = LF.ContractId AND LF.IsCurrent = 1
LEFT JOIN EmployeesAssignedToContracts EMP ON C.Id = EMP.ContractId AND EMP.IsActive = 1
LEFT JOIN EmployeesAssignedToParties EMPC ON EMP.EmployeeAssignedToPartyId = EMPC.Id AND EMPC.EmployeeId = @CurrentUserId
WHERE C.IsConfidential = 1
GROUP BY LF.Id HAVING SUM(ISNULL(EMPC.EmployeeId,0)) = 0;
INSERT INTO #UnauthorizedConfidentialEntityDetails
SELECT 'Opportunity', O.Id FROM Opportunities O
JOIN Proposals P ON O.Id = P.Id
LEFT JOIN EmployeesAssignedToProposals EMP ON P.Id = EMP.ProposalId AND EMP.IsActive = 1
LEFT JOIN EmployeesAssignedToParties EMPC ON EMP.EmployeeAssignedToPartyId = EMPC.Id AND EMPC.EmployeeId = @CurrentUserId
WHERE O.Confidential = 1
GROUP BY O.Id HAVING SUM(ISNULL(EMPC.EmployeeId,0)) = 0;
INSERT INTO #UnauthorizedConfidentialEntityDetails
SELECT 'Opportunity', O.Id FROM Opportunities O
JOIN CreditApplications C ON O.Id = C.Id
LEFT JOIN EmployeesAssignedToCreditApplications EMP ON C.Id = EMP.CreditApplicationId AND EMP.IsActive = 1
LEFT JOIN EmployeesAssignedToParties EMPC ON EMP.EmployeeAssignedToPartyId = EMPC.Id AND EMPC.EmployeeId = @CurrentUserId
WHERE O.Confidential = 1
GROUP BY O.Id HAVING SUM(ISNULL(EMPC.EmployeeId,0)) = 0;
INSERT INTO #UnauthorizedConfidentialEntityDetails
SELECT 'CreditProfile', C.Id FROM CreditProfiles C
LEFT JOIN EmployeesAssignedToLOCs EMP ON C.Id = EMP.CreditProfileId
LEFT JOIN EmployeesAssignedToParties EMPC ON EMP.EmployeeAssignedToPartyId = EMPC.Id AND EMPC.EmployeeId = @CurrentUserId
WHERE C.IsConfidential = 1
GROUP BY C.Id HAVING SUM(ISNULL(EMPC.EmployeeId,0)) = 0;
SELECT DISTINCT TransactionInstanceId = TI.Id
FROM TransactionInstances TI
JOIN #UnauthorizedConfidentialEntityDetails UCE ON TI.EntityName = UCE.EntityName AND TI.EntityId = UCE.EntityId;
END

GO

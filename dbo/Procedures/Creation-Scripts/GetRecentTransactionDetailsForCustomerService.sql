SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetRecentTransactionDetailsForCustomerService]
(
@CustomerNumber nvarchar(50),
@UserId BIGINT,
@AccessibleLegalEntityIds AccessibleLegalEntityIdCollection READONLY,
@RecentTransactionFetchCount INT = 0
)
AS
BEGIN
DECLARE @Count INT = @RecentTransactionFetchCount
IF @RecentTransactionFetchCount = 0
SET @Count = 20
DECLARE @CustomerId BIGINT = (SELECT Id FROM Parties WHERE PartyNumber = @CustomerNumber)
;WITH
CTE_ContractList
AS
(
SELECT
Contracts.Id AS ContractId,
Contracts.IsConfidential,
LeaseFinances.Id ContractDetailId
FROM
Contracts
INNER JOIN LeaseFinances
ON LeaseFinances.ContractId = Contracts.Id
AND LeaseFinances.CustomerId = @CustomerId
AND LeaseFinances.IsCurrent = 1
INNER JOIN @AccessibleLegalEntityIds ALE
ON LeaseFinances.LegalEntityId = ALE.LegalEntityId
UNION
SELECT
Contracts.Id AS ContractId,
Contracts.IsConfidential,
LoanFinances.Id ContractDetailId
FROM
Contracts
INNER JOIN LoanFinances
ON LoanFinances.ContractId = Contracts.Id
AND LoanFinances.CustomerId = @CustomerId
AND LoanFinances.IsCurrent = 1
INNER JOIN @AccessibleLegalEntityIds ALE
ON LoanFinances.LegalEntityId = ALE.LegalEntityId
),
CTE_FinalContractList
AS
(
SELECT ContractList.ContractId,ContractDetailId FROM CTE_ContractList ContractList
INNER JOIN EmployeesAssignedToContracts
ON ContractList.ContractId = EmployeesAssignedToContracts.ContractId
AND ContractList.IsConfidential = 1
INNER JOIN EmployeesAssignedToParties
ON EmployeesAssignedToContracts.EmployeeAssignedToPartyId = EmployeesAssignedToParties.Id
AND EmployeesAssignedToParties.EmployeeId = @UserId
UNION
SELECT ContractList.ContractId,ContractDetailId FROM CTE_ContractList ContractList WHERE IsConfidential = 0
),
CTE_RecentTransactionDetails
AS
(
SELECT DISTINCT
CASE
WHEN (EntityType = 'AgencyLegalPlacement' OR EntityType = 'Judgment' OR EntityType = 'LegalRelief') THEN
RecentTransactions.Description
ELSE
RecentTransactions.TransactionName
END [TransactionName],
CONVERT(datetime, RecentTransactions.CreatedTime) [TransactionDate],
Users.FullName [TransactionUser],
RecentTransactions.ReferenceNumber,
RecentTransactions.EntityId,
RecentTransactions.EntityType,
RecentTransactions.[Transaction]
FROM
RecentTransactions
INNER JOIN Users
ON Users.Id = RecentTransactions.CreatedById
INNER JOIN CTE_FinalContractList FinalContractList
ON (RecentTransactions.CustomerId = @CustomerId AND RecentTransactions.ContractId IS NULL)

UNION

SELECT DISTINCT
CASE
WHEN (EntityType = 'AgencyLegalPlacement' OR EntityType = 'Judgment' OR EntityType = 'LegalRelief') THEN
RecentTransactions.Description
ELSE
RecentTransactions.TransactionName
END [TransactionName],
CONVERT(datetime, RecentTransactions.CreatedTime) [TransactionDate],
Users.FullName [TransactionUser],
RecentTransactions.ReferenceNumber,
RecentTransactions.EntityId,
RecentTransactions.EntityType,
RecentTransactions.[Transaction]
FROM
RecentTransactions
INNER JOIN Users
ON Users.Id = RecentTransactions.CreatedById
INNER JOIN CTE_FinalContractList FinalContractList
ON (RecentTransactions.ContractId = FinalContractList.ContractId
AND RecentTransactions.EntityId = ( CASE WHEN RecentTransactions.EntityType IN ('LeaseFinance','LoanFinance')
THEN FinalContractList.ContractDetailId
ELSE RecentTransactions.EntityId END))
)

SELECT TOP(@Count)
RecentTransactionDetails.TransactionName AS TransactionType,
RecentTransactionDetails.TransactionDate,
RecentTransactionDetails.TransactionUser,
RecentTransactionDetails.ReferenceNumber,
RecentTransactionDetails.EntityId AS RelevantId,
RecentTransactionDetails.EntityId,
RecentTransactionDetails.EntityType AS EntityName,
RecentTransactionDetails.[Transaction] AS TransactionName
FROM
CTE_RecentTransactionDetails RecentTransactionDetails
ORDER BY
RecentTransactionDetails.TransactionDate DESC
END

GO

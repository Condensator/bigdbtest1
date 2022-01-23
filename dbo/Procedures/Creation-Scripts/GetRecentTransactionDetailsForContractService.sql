SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetRecentTransactionDetailsForContractService]
(
@ContractSequenceNumber nvarchar(80),
@FilterCustomerId BIGINT = NULL,
@AccessibleLegalEntityIds AccessibleLegalEntityIdCollection READONLY,
@RecentTransactionFetchCount INT = 0
)
AS
BEGIN
SET NOCOUNT ON
DECLARE @Count INT = @RecentTransactionFetchCount
IF @RecentTransactionFetchCount = 0 SET @Count = 20
DECLARE @ContractId BIGINT = (SELECT TOP 1 ID FROM dbo.Contracts WHERE SequenceNumber = @ContractSequenceNumber)
SELECT
DISTINCT TOP (@Count)
CASE WHEN EntityType = 'AgencyLegalPlacement' OR EntityType = 'LegalRelief' THEN Description ELSE TransactionName END AS TransactionType,
CAST (RecentTransactions.CreatedTime AS DATETIME) AS TransactionDate,
Users.FullName AS TransactionUser,
ReferenceNumber AS ReferenceNumber,
EntityId AS RelevantId,
EntityId AS EntityId,
EntityType AS EntityName,
[Transaction] AS TransactionName,
Parties.PartyNumber [CustomerNumber]
FROM dbo.RecentTransactions
INNER JOIN Users ON Users.Id = RecentTransactions.CreatedById
INNER JOIN Contracts ON RecentTransactions.ContractId = Contracts.Id
LEFT JOIN LeaseFinances ON Contracts.Id = LeaseFinances.ContractId
LEFT JOIN LoanFinances ON Contracts.Id = LoanFinances.ContractId
LEFT JOIN dbo.LeveragedLeases ON Contracts.Id = LeveragedLeases.ContractId
INNER JOIN @AccessibleLegalEntityIds ALE ON ALE.LegalEntityId =
(CASE WHEN LeaseFinances.Id IS NOT NULL THEN LeaseFinances.LegalEntityId
WHEN LoanFinances.Id IS NOT NULL THEN LoanFinances.LegalEntityId
WHEN LeveragedLeases.Id IS NOT NULL THEN LeveragedLeases.LegalEntityId
ELSE NULL END)
LEFT JOIN Parties ON RecentTransactions.CustomerId = Parties.Id
WHERE RecentTransactions.ContractID = @ContractId
AND (@FilterCustomerId IS NULL OR RecentTransactions.CustomerId = @FilterCustomerId )
AND ISNULL(LeaseFinances.IsCurrent,LoanFinances.IsCurrent) = 1
ORDER BY TransactionDate DESC
END

GO
